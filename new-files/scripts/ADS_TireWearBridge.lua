-- ============================================================
-- ADS_TireWearBridge.lua
--
-- Links the bundled Real Tire Wear (RTW) tires to ADS's tire breakdowns so
-- there is ONE puncture system instead of two that ignore each other:
--
--   * ADS rolls the punctures for its own (motorized) vehicles. The roll now
--     also looks at each wheel's RTW tread wear, and the flat lands on a real
--     wheel: it hisses, visibly deflates and caps speed like an RTW flat.
--   * RTW's own puncture roll is switched off on ADS vehicles. On trailers and
--     implements (which ADS doesn't cover) it now uses the ADS puncture rate,
--     so a trailer tire is as likely to pick up a nail as a tractor tire.
--   * SLOW_PUNCTURE stages visibly let the air out of one left tire; at the
--     last stage that tire goes fully flat.
--   * Repairing the flat in the ADS workshop re-inflates the RTW tire, and
--     replacing the tire in the RTW tire service clears the ADS breakdown.
--
-- The RTW scripts themselves are left untouched; this file only wraps them.
-- Server decides, clients follow through the normal ADS / RTW sync.
-- ============================================================

ADS_TireWearBridge = {}

local B = ADS_TireWearBridge

B.RECONCILE_INTERVAL_MS = 500
B.SLOW_LEAK_LEVELS = { 0.10, 0.25, 0.50 } -- visual air loss for slow puncture stages 1-3

local function tireCfg()
    return ADS_Config ~= nil and ADS_Config.TIRES or {}
end

function B.isActive()
    return TireWear ~= nil and TireWear.__realTireWearCoreLoaded == true and TireReplaceEvent ~= nil
end

local function hasAds(vehicle)
    local spec = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    return spec ~= nil and not spec.isExcludedVehicle
end

local function getRtwWheels(vehicle)
    local spec = vehicle ~= nil and vehicle.spec_tireWear or nil
    if spec == nil or spec.excluded or spec.enabled ~= true or spec.wheels == nil then
        return nil
    end
    return spec.wheels
end

-- pneumatic tire that can go flat (no crawler tracks, has a tire visual)
local function isPunctureWheel(tire)
    return tire ~= nil
        and tire.wheel ~= nil
        and TireWear.isServiceableWheel(tire)
        and not TireReplaceEvent.isCrawlerWheel(tire)
end

-- 1 = left, -1 = right (vehicle +X is left in GIANTS space)
function B.getWheelSide(vehicle, tire)
    local wheel = tire.wheel
    if wheel.isLeft ~= nil then
        return wheel.isLeft and 1 or -1
    end

    local node = wheel.repr
    if node == nil or node == 0 then node = wheel.driveNode end
    if node ~= nil and node ~= 0 and vehicle.rootNode ~= nil then
        local wx, wy, wz = getWorldTranslation(node)
        local lx = worldToLocal(vehicle.rootNode, wx, wy, wz)
        return lx >= 0 and 1 or -1
    end
    return 1
end

-- RTW's own wear curve for puncture risk: a bald tire is up to 8x likelier
local function getTreadWeight(tire)
    local wear = math.max(0, math.min(tonumber(tire.wear) or 0, 1))
    local mult = tonumber(tireCfg().TREAD_WEAR_MULTIPLIER) or 7.0
    return 1 + mult * wear * wear
end

-- The tire that the ADS slow puncture lives in. ADS's slow puncture always
-- pulls left, so it is the first left tire. Deterministic, so every MP
-- client picks the same one without extra sync.
function B.getSlowLeakWheelIndex(vehicle)
    local wheels = getRtwWheels(vehicle)
    if wheels == nil then return nil end
    for index, tire in ipairs(wheels) do
        if isPunctureWheel(tire) and B.getWheelSide(vehicle, tire) > 0 then
            return index
        end
    end
    return nil
end

-- Average tread weight across all tires (multiplies the ADS roll) and a
-- weighted random pick of the tire that actually gets the nail.
-- side: optional 1/-1 to restrict the pick to one side.
function B.pickPunctureWheel(vehicle, side)
    local wheels = getRtwWheels(vehicle)
    if wheels == nil then return nil, 1 end

    local total, count = 0, 0
    local candidates = {}
    for index, tire in ipairs(wheels) do
        if isPunctureWheel(tire) and not tire.damaged then
            local tireSide = B.getWheelSide(vehicle, tire)
            if side == nil or tireSide == side then
                local weight = getTreadWeight(tire)
                total = total + weight
                count = count + 1
                candidates[#candidates + 1] = { index = index, weight = weight, side = tireSide }
            end
        end
    end

    if count == 0 then return nil, 1 end

    local roll = math.random() * total
    for _, c in ipairs(candidates) do
        roll = roll - c.weight
        if roll <= 0 then
            return c.index, total / count, c.side
        end
    end
    local last = candidates[#candidates]
    return last.index, total / count, last.side
end

-- ------------------------------------------------------------
-- RTW tire state helpers (server)
-- ------------------------------------------------------------

function B.setTireFlat(vehicle, index, flat, silent)
    local wheels = getRtwWheels(vehicle)
    local tire = wheels ~= nil and wheels[index] or nil
    if tire == nil or (tire.damaged == true) == (flat == true) then
        return
    end
    TireWear.setAirDamage(vehicle, tire, flat == true, silent == true)
    TireWear.applyAirVisual(tire)
    TireWear.syncTireWearState(vehicle, index, true)
end

local function countFlatsOnSide(vehicle, side)
    local wheels = getRtwWheels(vehicle)
    if wheels == nil then return 0 end
    local count = 0
    for _, tire in ipairs(wheels) do
        if isPunctureWheel(tire) and tire.damaged and B.getWheelSide(vehicle, tire) == side then
            count = count + 1
        end
    end
    return count
end

local function clearFlatsOnSide(vehicle, side)
    local wheels = getRtwWheels(vehicle)
    if wheels == nil then return end
    for index, tire in ipairs(wheels) do
        if isPunctureWheel(tire) and tire.damaged and B.getWheelSide(vehicle, tire) == side then
            B.setTireFlat(vehicle, index, false, true)
        end
    end
end

-- ------------------------------------------------------------
-- ADS breakdown state helpers
-- ------------------------------------------------------------

local getSlowPunctureStage, getSlowPunctureMaxStage

local function getBreakdown(vehicle, id)
    local spec = vehicle.spec_AdvancedDamageSystem
    local bd = spec ~= nil and spec.activeBreakdowns ~= nil and spec.activeBreakdowns[id] or nil
    if bd == nil or bd.isActive == false then
        return nil
    end
    return bd
end

getSlowPunctureStage = function(vehicle)
    local bd = getBreakdown(vehicle, "SLOW_PUNCTURE")
    return bd ~= nil and (tonumber(bd.stage) or 1) or 0
end

getSlowPunctureMaxStage = function()
    local entry = ADS_Breakdowns ~= nil and ADS_Breakdowns.BreakdownRegistry.SLOW_PUNCTURE or nil
    return entry ~= nil and entry.stages ~= nil and #entry.stages or 4
end

-- Does ADS currently say this side has a flat?
local function adsSideIsFlat(vehicle, side)
    if side > 0 then
        return getBreakdown(vehicle, "FLAT_TIRE_LEFT") ~= nil
            or getSlowPunctureStage(vehicle) >= getSlowPunctureMaxStage()
    end
    return getBreakdown(vehicle, "FLAT_TIRE_RIGHT") ~= nil
end

-- Add an ADS flat even when the vehicle is at its concurrent breakdown cap:
-- the tire is physically flat, so ADS must know about it.
local function forceAddFlat(vehicle, side)
    local id = side > 0 and "FLAT_TIRE_LEFT" or "FLAT_TIRE_RIGHT"
    if vehicle:hasBreakdown(id) then
        -- present but suspended by a quick fix: the tire is flat again
        local spec = vehicle.spec_AdvancedDamageSystem
        local bd = spec.activeBreakdowns[id]
        if bd ~= nil and bd.isActive == false then
            bd.isActive = true
            bd.resumeTimer = 0
            vehicle:recalculateAndApplyEffects()
            if vehicle.isServer and spec.adsDirtyFlag_breakdowns ~= nil then
                vehicle:raiseDirtyFlags(spec.adsDirtyFlag_breakdowns)
            end
        end
        return
    end

    local core = ADS_Config.CORE
    local limit = core.CONCURRENT_BREAKDOWN_LIMIT_PER_VEHICLE
    core.CONCURRENT_BREAKDOWN_LIMIT_PER_VEHICLE = math.huge
    local ok, err = pcall(vehicle.addBreakdown, vehicle, id, { stage = 1, isActive = true, isVisible = true })
    core.CONCURRENT_BREAKDOWN_LIMIT_PER_VEHICLE = limit
    if not ok then
        Logging.warning("[ADS] Could not add %s for RTW flat: %s", id, tostring(err))
    end
end

local function clearAdsSide(vehicle, side)
    if side > 0 then
        vehicle:removeBreakdown("FLAT_TIRE_LEFT")
        -- a slow leak that already went fully flat was that tire; earlier
        -- stages live in a tire that is still on the vehicle
        if getSlowPunctureStage(vehicle) >= getSlowPunctureMaxStage() then
            vehicle:removeBreakdown("SLOW_PUNCTURE")
        end
    else
        vehicle:removeBreakdown("FLAT_TIRE_RIGHT")
    end
end

-- ------------------------------------------------------------
-- Server: keep ADS breakdowns and RTW tires in step
-- ------------------------------------------------------------

local function reconcileSide(vehicle, state, side)
    local key = side > 0 and "L" or "R"
    local ads = adsSideIsFlat(vehicle, side)
    local rtw = countFlatsOnSide(vehicle, side) > 0
    local prevAds = state["ads" .. key]
    local prevRtw = state["rtw" .. key]

    if prevAds ~= nil and ads ~= prevAds then
        -- ADS changed (new puncture, slow leak hit last stage, workshop repair,
        -- quick fix, or a quick fix wearing off): tires follow ADS
        if ads and not rtw then
            local index
            if side > 0 and getBreakdown(vehicle, "FLAT_TIRE_LEFT") == nil then
                index = B.getSlowLeakWheelIndex(vehicle)
            end
            if index == nil then
                index = B.pickPunctureWheel(vehicle, side)
            end
            if index ~= nil then
                B.setTireFlat(vehicle, index, true, false)
            end
        elseif not ads and rtw then
            clearFlatsOnSide(vehicle, side)
        end
    elseif prevRtw ~= nil and rtw ~= prevRtw then
        -- RTW changed (tire replaced in the RTW tire service, or a flat came
        -- from somewhere else): ADS follows the tires
        if rtw and not ads then
            forceAddFlat(vehicle, side)
        elseif not rtw and ads then
            clearAdsSide(vehicle, side)
        end
    elseif ads ~= rtw then
        -- first check after loading (or an old RTW-only save): if either one
        -- says flat, the tire is flat
        if rtw then
            forceAddFlat(vehicle, side)
        else
            local index
            if side > 0 and getBreakdown(vehicle, "FLAT_TIRE_LEFT") == nil then
                index = B.getSlowLeakWheelIndex(vehicle)
            end
            index = index or B.pickPunctureWheel(vehicle, side)
            if index ~= nil then
                B.setTireFlat(vehicle, index, true, true)
            end
        end
    end

    state["ads" .. key] = adsSideIsFlat(vehicle, side)
    state["rtw" .. key] = countFlatsOnSide(vehicle, side) > 0
end

-- Called (server) right after ADS removes or quick-fixes breakdowns, so a
-- workshop repair re-inflates the tire at once instead of on the next tick
-- (a save in between would otherwise bring the flat back).
-- removedIds: list of breakdown ids, or nil when ADS cleared everything.
function B.applyAdsToTires(vehicle, removedIds)
    if not B.isActive() or not hasAds(vehicle) or not vehicle.isServer then return end
    if getRtwWheels(vehicle) == nil then return end

    local touchLeft, touchRight = removedIds == nil, removedIds == nil
    for _, id in ipairs(removedIds or {}) do
        if id == "FLAT_TIRE_LEFT" or id == "SLOW_PUNCTURE" then touchLeft = true end
        if id == "FLAT_TIRE_RIGHT" then touchRight = true end
    end

    if touchLeft and not adsSideIsFlat(vehicle, 1) then
        clearFlatsOnSide(vehicle, 1)
    end
    if touchRight and not adsSideIsFlat(vehicle, -1) then
        clearFlatsOnSide(vehicle, -1)
    end

    local state = vehicle.spec_AdvancedDamageSystem.rtwBridge
    if state == nil then
        state = { timer = 0 }
        vehicle.spec_AdvancedDamageSystem.rtwBridge = state
    end
    state.adsL = adsSideIsFlat(vehicle, 1)
    state.rtwL = countFlatsOnSide(vehicle, 1) > 0
    state.adsR = adsSideIsFlat(vehicle, -1)
    state.rtwR = countFlatsOnSide(vehicle, -1) > 0
end

-- Called from AdvancedDamageSystem:onUpdate on server and clients.
function B.update(vehicle, dt)
    if not B.isActive() or not hasAds(vehicle) then return end
    local wheels = getRtwWheels(vehicle)
    if wheels == nil then return end

    local adsSpec = vehicle.spec_AdvancedDamageSystem

    -- every machine: slow puncture visual on the leaking tire
    local leakIndex = B.getSlowLeakWheelIndex(vehicle)
    local stage = getSlowPunctureStage(vehicle)
    for index, tire in ipairs(wheels) do
        local level = 0
        if index == leakIndex and stage > 0 then
            level = B.SLOW_LEAK_LEVELS[stage] or 1
        end
        if tire.adsLeakLevel ~= level then
            tire.adsLeakLevel = level
            TireWear.applyAirVisual(tire)
        end
    end

    if not vehicle.isServer then return end

    adsSpec.rtwBridge = adsSpec.rtwBridge or { timer = 0 }
    local state = adsSpec.rtwBridge
    state.timer = state.timer + (dt or 0)
    if state.timer < B.RECONCILE_INTERVAL_MS then return end
    state.timer = 0

    reconcileSide(vehicle, state, 1)
    reconcileSide(vehicle, state, -1)
end

-- Called by AdvancedDamageSystem:updateRandomFlatTire.
-- Returns the tread-wear multiplier for the roll and a function that puts the
-- flat on the chosen tire once ADS has accepted the breakdown.
function B.preparePunctureRoll(vehicle)
    if not B.isActive() or getRtwWheels(vehicle) == nil then
        return 1, nil, nil
    end
    local index, treadMult, side = B.pickPunctureWheel(vehicle)
    if index == nil then
        return 1, nil, nil
    end
    return treadMult, side, function()
        B.setTireFlat(vehicle, index, true, false)
        local state = vehicle.spec_AdvancedDamageSystem.rtwBridge
        if state ~= nil then
            local key = side > 0 and "L" or "R"
            state["ads" .. key] = true
            state["rtw" .. key] = true
        end
    end
end

-- Puncture coming from another mod (Mud System Physics road debris, its
-- console test). Puts it into the same system as an ADS puncture: the ADS
-- flat breakdown on the right side plus the real tire going down. Server only.
function B.punctureWheel(vehicle, index)
    if not B.isActive() or vehicle == nil or not vehicle.isServer then return false end
    local wheels = getRtwWheels(vehicle)
    local tire = wheels ~= nil and wheels[index] or nil
    if tire == nil or not isPunctureWheel(tire) or tire.damaged then return false end

    local side = B.getWheelSide(vehicle, tire)
    if hasAds(vehicle) then
        forceAddFlat(vehicle, side)
    end
    B.setTireFlat(vehicle, index, true, false)

    local state = hasAds(vehicle) and vehicle.spec_AdvancedDamageSystem.rtwBridge or nil
    if state ~= nil then
        local key = side > 0 and "L" or "R"
        state["ads" .. key] = adsSideIsFlat(vehicle, side)
        state["rtw" .. key] = true
    end
    return true
end

-- Does the bundled Real Tire Wear look after this vehicle's tires?
function B.ownsTires(vehicle)
    return B.isActive() and getRtwWheels(vehicle) ~= nil
end

-- ------------------------------------------------------------
-- Wrappers around RTW (scripts stay unmodified)
-- ------------------------------------------------------------

-- Grip: RTW used to push its own friction straight into the physics
-- (setWheelShapeTireFriction) every tick. That wiped out every other mod that
-- changes grip the standard way - Mud System Physics' mud, rain, snow, tire
-- pressure and puncture grip - and those mods' changes wiped RTW's in turn.
-- Now RTW's tread grip joins the same chain: it multiplies frictionScale while
-- the game rebuilds the tire friction, like the other mods do.
local function findRtwTire(wheelPhysics)
    local cached = wheelPhysics.__rtwTire
    if cached ~= nil then return cached end
    local vehicle = wheelPhysics.vehicle
    local wheels = getRtwWheels(vehicle)
    if wheels == nil then return nil end
    for _, tire in ipairs(wheels) do
        if tire.wheel ~= nil and tire.wheel == wheelPhysics.wheel then
            wheelPhysics.__rtwTire = tire
            return tire
        end
    end
    return nil
end

function B.installGripChain()
    if B.gripChainInstalled or WheelPhysics == nil or WheelPhysics.updateTireFriction == nil then return end
    B.gripChainInstalled = true
    WheelPhysics.updateTireFriction = Utils.overwrittenFunction(WheelPhysics.updateTireFriction,
        function(wheelPhysics, superFunc, ...)
            local tire = wheelPhysics ~= nil and findRtwTire(wheelPhysics) or nil
            local grip = tire ~= nil and tonumber(tire.grip) or nil
            local old = wheelPhysics ~= nil and wheelPhysics.frictionScale or nil
            local applied = false
            if grip ~= nil and math.abs(grip - 1) > 0.001 then
                wheelPhysics.frictionScale = (old or 1) * math.max(0.05, math.min(grip, 1))
                applied = true
            end
            if tire ~= nil then tire.physicsGripApplied = grip or 1 end
            if superFunc ~= nil then superFunc(wheelPhysics, ...) end
            if applied then wheelPhysics.frictionScale = old end
        end)
end

function B.install()
    if not B.isActive() or B.installed then return end
    B.installed = true

    -- Every mod runs in its own environment, so publish the bridge on a table
    -- the game owns (same trick the shared realism HUD column uses). Mud System
    -- Physics looks for it here to hand its punctures over.
    if type(Utils) == "table" then
        Utils.adsTireBridge = B
    end

    -- 1) Puncture roll: ADS vehicles are handled by ADS; everything else
    --    (trailers, implements) uses the ADS puncture rate per tire.
    TireWear.tryPuncture = function(vehicle, tire, index, dt)
        if not vehicle.isServer or tire.damaged or dt == nil or dt <= 0 then return end
        if hasAds(vehicle) then return end
        if vehicle.spec_tireWear == nil or vehicle.spec_tireWear.enabled ~= true then return end
        if not isPunctureWheel(tire) then return end

        local C = tireCfg()
        if C.TRAILER_PUNCTURES == false then return end
        local baseRate = tonumber(C.FLAT_TIRE_CHANCE_PER_HOUR) or 0
        if baseRate <= 0 then return end

        local speed = TireWear.getVehicleSpeedKmh(vehicle)
        if speed < (C.FLAT_TIRE_MIN_SPEED or 2) then return end
        if not TireWear.hasWheelGroundContact(tire) then return end

        local tireCount = 0
        for _, t in ipairs(vehicle.spec_tireWear.wheels) do
            if isPunctureWheel(t) then tireCount = tireCount + 1 end
        end
        if tireCount == 0 then return end

        local rate = baseRate / tireCount
        if vehicle.getIsOnField ~= nil and vehicle:getIsOnField() then
            rate = rate * (C.FLAT_TIRE_FIELD_MULTIPLIER or 1)
        end
        local fastSpeed = C.FLAT_TIRE_FAST_SPEED or 30
        if speed > fastSpeed then
            rate = rate * (1 + (speed - fastSpeed) / fastSpeed)
        end
        rate = rate * getTreadWeight(tire)

        if math.random() < rate * dt / 3600000 then
            TireWear.setAirDamage(vehicle, tire, true, false)
            TireWear.syncTireWearState(vehicle, index, true)
        end
    end

    -- 2) Air visual: also show the partial deflation of an ADS slow puncture.
    TireWear.applyAirVisual = function(tire)
        if not TireWear.isServiceableWheel(tire) then return end
        local wheel = tire.wheel
        if wheel == nil or wheel.visualWheels == nil then return end

        local loss = tire.damaged and (tire.airLoss or 1) or 0
        loss = math.max(loss, tonumber(tire.adsLeakLevel) or 0)

        local radius = TireWear.getOriginalPhysicsRadius(tire) or 0.5
        local extra = math.min(radius * TireWear.AIR_LOSS_RADIUS_RATIO, 0.14) * loss
        for _, visual in ipairs(wheel.visualWheels) do
            for _, part in ipairs(visual.visualParts or {}) do
                if part.isa ~= nil and WheelVisualPartTire ~= nil and part:isa(WheelVisualPartTire) then
                    if part.rtwOriginalInitial == nil then
                        part.rtwOriginalInitial = part.initialDeformation or 0
                        part.rtwOriginalMax = part.maxDeformation or 0
                    end
                    part.initialDeformation = part.rtwOriginalInitial + extra
                    part.maxDeformation = part.rtwOriginalMax + extra
                end
            end
        end
    end

    -- 3) Radius: RTW put the physics radius back to factory size every tick,
    --    undoing mud sinking, low tire pressure and puncture deflation from Mud
    --    System Physics. RTW's own target WAS the factory radius (it never
    --    shrinks the physics tire), so leaving the radius alone changes nothing
    --    for RTW and stops the tug-of-war.
    TireWear.updatePhysicalRadius = function(vehicle, tire)
        if tire ~= nil then
            tire.currentPhysicsRadius = tire.wheel ~= nil and tire.wheel.physics ~= nil
                and tonumber(tire.wheel.physics.radius) or tire.currentPhysicsRadius
        end
    end

    -- 4) Grip goes through the friction chain (see installGripChain): RTW only
    --    flags the wheel for a friction rebuild when its tread grip changes.
    B.installGripChain()
    TireWear.updatePhysicalWear = function(vehicle, index)
        if vehicle == nil or not vehicle.isServer or vehicle.isAddedToPhysics == false then return end
        local wheels = vehicle.spec_tireWear ~= nil and vehicle.spec_tireWear.wheels or nil
        local tire = wheels ~= nil and wheels[index] or nil
        if tire == nil or tire.wheel == nil or tire.wheel.physics == nil then return end
        local grip = tonumber(tire.grip) or 1
        if tire.physicsGripApplied == nil or math.abs(grip - tire.physicsGripApplied) > 0.002 then
            tire.wheel.physics.isFrictionDirty = true
        end
    end

    -- 5) RTW tire service: a replaced tire clears the matching ADS breakdown
    --    right away (the reconcile would also catch it, this is just instant).
    local origResetWheel = TireReplaceEvent.resetWheel
    TireReplaceEvent.resetWheel = function(vehicle, index, preserveWear)
        local wheels = getRtwWheels(vehicle)
        local tire = wheels ~= nil and wheels[index] or nil
        local side = (tire ~= nil and isPunctureWheel(tire)) and B.getWheelSide(vehicle, tire) or nil
        local isLeakWheel = side ~= nil and index == B.getSlowLeakWheelIndex(vehicle)

        origResetWheel(vehicle, index, preserveWear)

        if side == nil or not vehicle.isServer or not hasAds(vehicle) then return end

        if countFlatsOnSide(vehicle, side) == 0 then
            vehicle:removeBreakdown(side > 0 and "FLAT_TIRE_LEFT" or "FLAT_TIRE_RIGHT")
        end
        if isLeakWheel then
            vehicle:removeBreakdown("SLOW_PUNCTURE")
        end

        local state = vehicle.spec_AdvancedDamageSystem.rtwBridge
        if state ~= nil then
            local key = side > 0 and "L" or "R"
            state["ads" .. key] = adsSideIsFlat(vehicle, side)
            state["rtw" .. key] = countFlatsOnSide(vehicle, side) > 0
        end
    end
end
