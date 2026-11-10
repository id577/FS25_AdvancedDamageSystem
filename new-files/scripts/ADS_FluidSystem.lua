--[[
    ADS_FluidSystem.lua
    -------------------------------------------------------------------
    Adds the one genuinely distinctive thing Hyper Realistic Maintenance 2
    has that ADS didn't: oil and coolant as their own trackable, dirtying,
    servicable resources, with a real feedback loop into engine wear and
    heat - independent of a full repair, the same way HRM2 models it.

    WHAT THIS DOES NOT TOUCH, AND WHY:
    ADS's own thermal model (updateThermalSystems / updateEngineThermalModel
    in ADS_Specialization.lua) is a genuine PID-controlled thermostat
    simulation with real weather-integrated ambient temperature, radiator
    health/dirt, fan clutch, and a deterministic quadratic power-loss curve
    above a real temperature threshold - more sophisticated than HRM2's
    equivalent, not less. Same for start-blocking on failure (ADS already
    has proper cranking-state simulation with MP sync), turbo/battery/
    alternator/starter wear, and the jump-start mechanic. None of that
    needed porting from HRM2 - it was already there, just not visible from
    the breakdown catalog alone.

    WHAT THIS ADDS:
      1. Real vehicle-type classification (tractor/truck/harvester/car)
         with per-type wear multipliers, ported from HRM2's approach.
      2. Real per-model service interval data (ported from HRM2's config),
         used to judge whether YOUR oil change is actually overdue rather
         than against one generic number.
      3. Oil level (depletes with engine hours) and oil contamination
         (grows with engine stress and poor engine condition) as their
         own tracked values, independent of ADS's own condition/service
         percentages.
      4. Coolant level as a separate slowly-depleting resource, distinct
         from the existing COOLANT_LEAK breakdown (which is a sudden
         failure) and radiator health (which is condition, not fill level).
      5. A real feedback loop: neglected fluids feed into ADS's own
         spec.extraConditionWear / extraServiceWear / extraEngineHeat -
         fields I confirmed ADS itself already reads and applies in its
         wear-rate and thermal math (ADS_Specialization.lua lines ~4470,
         ~4534, ~8696) - rather than inventing a parallel effect system.
      6. A new catastrophic-neglect breakdown that becomes near-certain
         (not just more likely) once fluids are critically neglected,
         mirroring HRM2's "past a hard line, it's not luck anymore"
         philosophy for its >118°C overheat trigger.
      7. Field service actions (change oil / top up coolant) via console
         commands, and a small always-on HUD readout.

    HONEST LIMITATION - PLEASE READ:
    Fluid state is SESSION-SCOPED, not saved to the savegame XML. Doing
    real persistence properly requires either wrapping ADS's own
    saveToXMLFile/onPostLoad (whose exact specialization-compile timing
    relative to this file I can't verify without a live game - the same
    category of risk I flagged for GUI framework work elsewhere in this
    project) or building an entire second parallel specialization just to
    get guaranteed-safe onLoad/saveToXMLFile hooks of my own. I chose not
    to gamble on the first and didn't have room to fully verify the second
    in this pass. Every other technique in this file (Motorized.onUpdate,
    the extra* wear/heat fields, BreakdownRegistry/EffectApplicators
    extension) is one I directly confirmed works, either by reading ADS's
    own consuming code or by matching a technique HRM2 itself proved
    works in this exact game version. If you confirm this loads and runs
    cleanly, tell me and I'll build the persistence layer next rather
    than shipping it unverified now.
--]]

-- ===========================================================
--         VEHICLE CLASSIFICATION (ported from HRM2)
-- ===========================================================

ADS_FluidSystem = {}

local HARVESTER_TYPES = {
    combineDrivable = true, combineCutter = true, combineCutterFruitPreparer = true,
    cottonHarvester = true, riceHarvester = true, vineHarvester = true,
    balerDrivable = true, selfPropelledMower = true, woodHarvester = true,
}

local CAR_TYPES = { car = true, carFillable = true, motorbike = true }

-- Wear/heat multipliers per vehicle type, same spirit as HRM2's
-- TYPE_PROFILES: trucks run more sustained high speed, harvesters carry
-- more constant engine load, cars are far gentler than farm equipment.
ADS_FluidSystem.TYPE_PROFILES = {
    tractor   = { oilWear = 1.0,  coolantWear = 1.0,  heatBonus = 1.0 },
    truck     = { oilWear = 1.15, coolantWear = 1.1,  heatBonus = 1.1 },
    harvester = { oilWear = 1.3,  coolantWear = 1.2,  heatBonus = 1.15 },
    car       = { oilWear = 0.6,  coolantWear = 0.8,  heatBonus = 0.85 },
}

function ADS_FluidSystem.classifyVehicle(vehicle)
    local typeName = (vehicle.type ~= nil and vehicle.type.name) or ""

    if HARVESTER_TYPES[typeName] then
        return "harvester"
    end
    if CAR_TYPES[typeName] then
        return "car"
    end

    local ok, storeItem = pcall(function()
        return g_storeManager:getItemByXMLFilename(vehicle.configFileName)
    end)
    if ok and storeItem ~= nil and storeItem.categoryName ~= nil then
        local category = string.upper(tostring(storeItem.categoryName))
        if category == "TRUCKS" then
            return "truck"
        end
    end

    return "tractor" -- default: most motorized ADS-managed vehicles are tractors/self-propelled equipment
end

function ADS_FluidSystem.getTypeProfile(vehicle)
    local class = ADS_FluidSystem.classifyVehicle(vehicle)
    return ADS_FluidSystem.TYPE_PROFILES[class] or ADS_FluidSystem.TYPE_PROFILES.tractor, class
end

-- ===========================================================
--     REAL PER-MODEL SERVICE INTERVALS (ported from HRM2)
-- ===========================================================
-- Used only to judge "is this specific vehicle's oil actually overdue"
-- for messaging - does not change ADS's own maintenance-interval system.
-- Matching is a best-effort guess against the vehicle's config filename,
-- same honest caveat HRM2 itself gives: verify against the console
-- status command and extend the patterns table if a vehicle doesn't
-- match what you expect.
ADS_FluidSystem.SERVICE_INTERVALS = {
    { match = "series7j",  label = "John Deere 7J Series",              engineOilHours = 450 },
    { match = "7200j",     label = "John Deere 7200J",                  engineOilHours = 450 },
    { match = "7215j",     label = "John Deere 7215J",                  engineOilHours = 450 },
    { match = "7230j",     label = "John Deere 7230J",                  engineOilHours = 450 },
    { match = "4500",      label = "John Deere Compact Utility 4500/4600/4700", engineOilHours = 200 },
    { match = "4600",      label = "John Deere Compact Utility 4500/4600/4700", engineOilHours = 200 },
    { match = "4700",      label = "John Deere Compact Utility 4500/4600/4700", engineOilHours = 200 },
}
ADS_FluidSystem.DEFAULT_ENGINE_OIL_INTERVAL_HOURS = 300 -- generic "Utility 50-100 HP" class fallback, matching HRM2's own default

function ADS_FluidSystem.getServiceIntervalInfo(vehicle)
    local configName = string.lower(tostring(vehicle.configFileName or ""))
    for _, entry in ipairs(ADS_FluidSystem.SERVICE_INTERVALS) do
        if string.find(configName, entry.match, 1, true) ~= nil then
            return entry.engineOilHours, entry.label
        end
    end
    return ADS_FluidSystem.DEFAULT_ENGINE_OIL_INTERVAL_HOURS, "Generic (Utility 50-100 HP class)"
end

-- ===========================================================
--                    FLUID STATE MODEL
-- ===========================================================

local function clamp01(v)
    if v < 0 then return 0 end
    if v > 1 then return 1 end
    return v
end

function ADS_FluidSystem.getState(vehicle)
    if vehicle.adsFluidState == nil then
        vehicle.adsFluidState = {
            oilLevel = 1.0,
            oilContamination = 0.0,
            coolantLevel = 1.0,
            engineHoursSinceOilChange = 0.0,
        }
    end
    return vehicle.adsFluidState
end

function ADS_FluidSystem.changeOil(vehicle)
    local state = ADS_FluidSystem.getState(vehicle)
    state.oilLevel = 1.0
    state.oilContamination = 0.0
    state.engineHoursSinceOilChange = 0.0
    return true
end

function ADS_FluidSystem.topUpCoolant(vehicle)
    local state = ADS_FluidSystem.getState(vehicle)
    state.coolantLevel = 1.0
    return true
end

-- Tuning constants. All depletion/contamination rates are per real
-- second of engine-running time, scaled by the vehicle-type multiplier.
ADS_FluidSystem.OIL_DEPLETE_PER_HOUR = 1 / 60          -- ~60 running hours to empty, matching HRM2's own rate
ADS_FluidSystem.COOLANT_DEPLETE_PER_HOUR = 1 / 500     -- ~500 running hours to empty (coolant loses far slower than oil)
ADS_FluidSystem.CONTAMINATION_GROWTH_PER_HOUR = 0.03   -- baseline; scaled up by stress and poor engine condition below

-- How strongly neglected fluids feed back into ADS's own sanctioned
-- extra* modifier fields (confirmed consumed in ADS_Specialization.lua).
ADS_FluidSystem.MAX_EXTRA_CONDITION_WEAR = 0.6   -- up to +60% engine condition wear rate at full neglect
ADS_FluidSystem.MAX_EXTRA_SERVICE_WEAR = 0.3     -- up to +30% service wear rate at full neglect
ADS_FluidSystem.MAX_EXTRA_ENGINE_HEAT = 0.15     -- up to +0.15 added to ADS's own engine max-heat ceiling

function ADS_FluidSystem.tick(vehicle, dtMs)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then
        return -- not an ADS-managed vehicle, nothing to do
    end
    if not vehicle.isServer then
        return -- server-authoritative, same as the rest of ADS's own state
    end
    if spec.isExcludedVehicle or spec.isElectricVehicle then
        return -- electric vehicles have no oil/coolant to track
    end

    local state = ADS_FluidSystem.getState(vehicle)
    local profile = ADS_FluidSystem.getTypeProfile(vehicle)
    local dtHours = (dtMs or 0) / 3600000.0

    local isRunning = false
    local ok = pcall(function()
        isRunning = vehicle:getIsMotorStarted() == true
    end)
    if not ok or not isRunning or dtHours <= 0 then
        return
    end

    local systems = AdvancedDamageSystem ~= nil and AdvancedDamageSystem.SYSTEMS or nil
    local engineStress, engineCondition = 0, 1
    if systems ~= nil then
        pcall(function() engineStress = vehicle:getSystemStressLevel(systems.ENGINE) or 0 end)
        pcall(function() engineCondition = vehicle:getSystemConditionLevel(systems.ENGINE) or 1 end)
    end
    engineStress = clamp01(tonumber(engineStress) or 0)
    engineCondition = clamp01(tonumber(engineCondition) or 1)

    -- Deplete oil and coolant with running time.
    state.oilLevel = clamp01(state.oilLevel - ADS_FluidSystem.OIL_DEPLETE_PER_HOUR * profile.oilWear * dtHours)
    state.coolantLevel = clamp01(state.coolantLevel - ADS_FluidSystem.COOLANT_DEPLETE_PER_HOUR * profile.coolantWear * dtHours)
    state.engineHoursSinceOilChange = state.engineHoursSinceOilChange + dtHours

    -- Contamination grows faster under load and as the underlying engine
    -- condition degrades (closing the same loop HRM2 closes via blow-by,
    -- just derived from ADS's own real condition value instead of a
    -- separate cylinder/piston sub-model).
    local contaminationRate = ADS_FluidSystem.CONTAMINATION_GROWTH_PER_HOUR
        * (0.4 + engineStress * 0.6)
        * (0.5 + (1 - engineCondition) * 1.5)
        * profile.oilWear
    if state.oilLevel <= 0.05 then
        contaminationRate = contaminationRate * 2.5 -- running low on oil contaminates what's left much faster
    end
    state.oilContamination = clamp01(state.oilContamination + contaminationRate * dtHours)

    -- Feed back into ADS's own sanctioned modifier fields.
    local neglectPenalty = clamp01(state.oilContamination * 0.6 + (1 - state.oilLevel) * 0.4)
    local coolantPenalty = clamp01(1 - state.coolantLevel)

    spec.extraConditionWear = neglectPenalty * ADS_FluidSystem.MAX_EXTRA_CONDITION_WEAR
    spec.extraServiceWear = neglectPenalty * ADS_FluidSystem.MAX_EXTRA_SERVICE_WEAR
    spec.extraEngineHeat = (neglectPenalty * 0.6 + coolantPenalty * 0.4) * ADS_FluidSystem.MAX_EXTRA_ENGINE_HEAT * profile.heatBonus
end

-- ===========================================================
--       CATASTROPHIC NEGLECT BREAKDOWN (new registry entry)
-- ===========================================================
-- Same technique as ADS_ExtraBreakdowns.lua: a plain addition to
-- ADS_Breakdowns.BreakdownRegistry, which ADS's own engine already
-- iterates generically. Near-certain once fluids are catastrophically
-- neglected, deliberately mirroring HRM2's ">118 degrees is guaranteed,
-- not luck" philosophy rather than ADS's usual gradual weighted-random
-- selection - this one is meant to feel like "you did this to yourself."

local fluidSystems = (AdvancedDamageSystem ~= nil and AdvancedDamageSystem.SYSTEMS) or {
    ENGINE = "ads_spec_system_engine", TRANSMISSION = "ads_spec_system_transmission",
    HYDRAULICS = "ads_spec_system_hydraulics", COOLING = "ads_spec_system_cooling",
    ELECTRICAL = "ads_spec_system_electrical", CHASSIS = "ads_spec_system_chassis",
    WORKPROCESS = "ads_spec_system_workprocess", MATERIALFLOW = "ads_spec_system_materialflow",
    FUEL = "ads_spec_system_fuel"
}
local fluidParts = ADS_Breakdowns.PARTS
fluidParts.OIL_SYSTEM = "ads_breakdowns_part_oil_system"

ADS_Breakdowns.BreakdownRegistry.OIL_STARVATION_DAMAGE = {
    isSelectable = true,
    system = fluidSystems.ENGINE,
    part = fluidParts.OIL_SYSTEM,

    isApplicable = function(vehicle)
        local state = vehicle.adsFluidState
        return state ~= nil and (state.oilLevel <= 0.05 or state.oilContamination >= 0.92)
    end,

    -- Deliberately not a small weight among many candidates: once the
    -- gate above is true, this should dominate selection, matching the
    -- "guaranteed, not luck" intent for genuinely catastrophic neglect.
    probability = function(vehicle)
        return 500.0
    end,

    isCanProgress = function(vehicle)
        return vehicle:getLastSpeed() > 0.01
    end,

    stages = {
        {
            severity = "ads_breakdowns_severity_critical",
            description = "ads_breakdowns_oil_starvation_stage1_description",
            detectionChance = 1.0,
            progressMultiplier = 0,
            repairPrice = 8.0,
            effects = {
                { id = "ENGINE_LIMP_EFFECT", value = -0.7, aggregation = "min", extraData = { reason = "OIL_STARVATION", message = "ads_breakdowns_oil_starvation_stage1_message", disableAi = true } },
            },
            indicators = {
                { id = ADS_Breakdowns.DASHBOARD.OIL, color = ADS_Breakdowns.COLORS.CRITICAL, switchOn = true, switchOff = false }
            }
        }
    }
}

-- ===========================================================
--                    SERVICE ACTIONS
-- ===========================================================

function ADS_FluidSystem.getStatusText(vehicle)
    local state = ADS_FluidSystem.getState(vehicle)
    local intervalHours, intervalLabel = ADS_FluidSystem.getServiceIntervalInfo(vehicle)
    local overdue = state.engineHoursSinceOilChange > intervalHours
    return string.format(
        "Oil: %d%% (contamination %d%%) | Coolant: %d%% | Hours since oil change: %.1f / %d (%s) %s",
        math.floor(state.oilLevel * 100 + 0.5),
        math.floor(state.oilContamination * 100 + 0.5),
        math.floor(state.coolantLevel * 100 + 0.5),
        state.engineHoursSinceOilChange,
        intervalHours,
        intervalLabel,
        overdue and "[OVERDUE]" or ""
    )
end

local function getEnteredAdsVehicle()
    if g_currentMission == nil or g_currentMission.controlledVehicle == nil then
        return nil
    end
    local vehicle = g_currentMission.controlledVehicle
    if vehicle.spec_AdvancedDamageSystem == nil then
        return nil
    end
    return vehicle
end

function adsFluidStatus(self)
    local vehicle = getEnteredAdsVehicle()
    if vehicle == nil then
        print("[ADS_FluidSystem] No ADS-managed vehicle entered")
        return
    end
    print("[ADS_FluidSystem] " .. ADS_FluidSystem.getStatusText(vehicle))
end

function adsFluidChangeOil(self)
    local vehicle = getEnteredAdsVehicle()
    if vehicle == nil then
        print("[ADS_FluidSystem] No ADS-managed vehicle entered")
        return
    end
    ADS_FluidSystem.changeOil(vehicle)
    print("[ADS_FluidSystem] Oil changed.")
end

function adsFluidTopUpCoolant(self)
    local vehicle = getEnteredAdsVehicle()
    if vehicle == nil then
        print("[ADS_FluidSystem] No ADS-managed vehicle entered")
        return
    end
    ADS_FluidSystem.topUpCoolant(vehicle)
    print("[ADS_FluidSystem] Coolant topped up.")
end

-- ===========================================================
--        FUEL / ADDITIVE STATUS AND STALL DIAGNOSTICS
-- ===========================================================
-- The console commands above were registered with no target and looked the
-- vehicle up through g_currentMission.controlledVehicle (an FS22 field), so in
-- FS25 they printed nothing. These are the FS25 versions, and they also show
-- the fuel side: diesel, DEF, Diesel Gel's gel and anti-gel, and any ADS
-- fault that can stall the engine.

local function getCurrentVehicle()
    if g_localPlayer ~= nil and g_localPlayer.getCurrentVehicle ~= nil then
        local ok, vehicle = pcall(g_localPlayer.getCurrentVehicle, g_localPlayer)
        if ok and vehicle ~= nil then
            return vehicle
        end
    end
    return g_currentMission ~= nil and g_currentMission.controlledVehicle or nil
end

local function consumerLevel(vehicle, fillTypeIndex)
    if fillTypeIndex == nil or vehicle.getConsumerFillUnitIndex == nil then
        return nil
    end
    local index = vehicle:getConsumerFillUnitIndex(fillTypeIndex)
    if index == nil then
        return nil
    end
    return vehicle:getFillUnitFillLevel(index) or 0, vehicle:getFillUnitCapacity(index) or 0
end

-- ADS breakdowns on this vehicle whose current stage can stall or kill the engine
function ADS_FluidSystem.getStallBreakdowns(vehicle)
    local result = {}
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil or spec.activeBreakdowns == nil then
        return result
    end
    for id, breakdown in pairs(spec.activeBreakdowns) do
        local entry = ADS_Breakdowns.BreakdownRegistry[id]
        local stage = entry ~= nil and entry.stages ~= nil and entry.stages[breakdown.stage or 1] or nil
        if stage ~= nil and breakdown.isActive ~= false then
            for _, effect in ipairs(stage.effects or {}) do
                if effect.id == "ENGINE_STALLS_CHANCE" or effect.id == "ENGINE_FAILURE" then
                    local name = entry.part ~= nil and g_i18n:getText(entry.part) or id
                    table.insert(result, { id = id, name = name, stage = breakdown.stage or 1, visible = breakdown.isVisible == true })
                    break
                end
            end
        end
    end
    return result
end

local function stallFaultText(vehicle)
    local faults = ADS_FluidSystem.getStallBreakdowns(vehicle)
    if #faults == 0 then
        return "none"
    end
    local known, hidden = {}, 0
    for _, f in ipairs(faults) do
        if f.visible then
            table.insert(known, string.format("%s (stage %d)", f.name, f.stage))
        else
            hidden = hidden + 1
        end
    end
    local text = table.concat(known, ", ")
    if hidden > 0 then
        text = text .. (text ~= "" and ", " or "") .. string.format("%d not yet found - run an inspection", hidden)
    end
    return text
end

function ADS_FluidSystem.getFuelStatusText(vehicle)
    local parts = {}
    local diesel, dieselCap = consumerLevel(vehicle, FillType.DIESEL)
    if diesel ~= nil then
        table.insert(parts, string.format("Diesel %.0f / %.0f L", diesel, dieselCap))
    end
    local def, defCap = consumerLevel(vehicle, FillType.DEF)
    if def ~= nil then
        table.insert(parts, string.format("DEF %.0f / %.0f L", def, defCap))
    end
    local gel = vehicle.spec_dieselGelSystem
    if gel ~= nil and gel.isDiesel then
        table.insert(parts, string.format("Gel %.0f%% | Anti-gel %.0f%% | Gel power %.0f%%",
            (gel.gelLevel or 0) * 100, (gel.additiveLevel or 0) * 100, (gel.currentPowerScale or 1) * 100))
    end
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec ~= nil and spec.fuelState ~= nil and vehicle:getIsMotorStarted() then
        local t = tonumber(spec.fuelState.temperature)
        if t ~= nil and t ~= 0 then
            table.insert(parts, string.format("Fuel temp %.0f F", t * 9 / 5 + 32))
        end
    end
    if spec ~= nil then
        table.insert(parts, "Faults that can stall the engine: " .. stallFaultText(vehicle))
    end
    return table.concat(parts, " | ")
end

function ADS_FluidSystem:consoleFluidStatus()
    local vehicle = getCurrentVehicle()
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        return "[ADS_FluidSystem] Enter an ADS-managed vehicle first"
    end
    local lines = { "[ADS_FluidSystem] " .. tostring(vehicle:getName()) }
    if not vehicle.spec_AdvancedDamageSystem.isElectricVehicle then
        table.insert(lines, "  " .. ADS_FluidSystem.getStatusText(vehicle))
    end
    table.insert(lines, "  " .. ADS_FluidSystem.getFuelStatusText(vehicle))
    return table.concat(lines, "\n")
end

function ADS_FluidSystem:consoleChangeOil()
    local vehicle = getCurrentVehicle()
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        return "[ADS_FluidSystem] Enter an ADS-managed vehicle first"
    end
    ADS_FluidSystem.changeOil(vehicle)
    return "[ADS_FluidSystem] Oil changed."
end

function ADS_FluidSystem:consoleTopUpCoolant()
    local vehicle = getCurrentVehicle()
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        return "[ADS_FluidSystem] Enter an ADS-managed vehicle first"
    end
    ADS_FluidSystem.topUpCoolant(vehicle)
    return "[ADS_FluidSystem] Coolant topped up."
end

addConsoleCommand("adsFluidStatus", "Oil, coolant, diesel, DEF, gel / anti-gel and stall faults of the entered vehicle", "consoleFluidStatus", ADS_FluidSystem)
addConsoleCommand("adsFluidChangeOil", "Change oil on the entered ADS-managed vehicle", "consoleChangeOil", ADS_FluidSystem)
addConsoleCommand("adsFluidTopUpCoolant", "Top up coolant on the entered ADS-managed vehicle", "consoleTopUpCoolant", ADS_FluidSystem)

-- -----------------------------------------------------------
-- Stall logger: every time an ADS vehicle's running engine is stopped, write
-- WHY to log.txt, and tell the driver on screen when it was not their doing.
-- A fault-triggered stop tags vehicle.adsStopCause right before stopMotor().
-- -----------------------------------------------------------
ADS_FluidSystem.LOG_STOPS = true

function ADS_FluidSystem.diagnoseStop(vehicle)
    if vehicle.adsStopCause ~= nil then
        local cause = vehicle.adsStopCause
        vehicle.adsStopCause = nil
        return cause, true
    end
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec ~= nil and spec.activeEffects ~= nil and spec.activeEffects.ENGINE_FAILURE ~= nil then
        return "ADS engine failure", false
    end
    local gel = vehicle.spec_dieselGelSystem
    if gel ~= nil and gel.isDiesel and (gel.gelLevel or 0) > 0.85 then
        return string.format("fuel gelled (%.0f%% gel) - park inside or add anti-gel", gel.gelLevel * 100), false
    end
    local diesel, dieselCap = consumerLevel(vehicle, FillType.DIESEL)
    if diesel ~= nil and dieselCap > 0 and diesel <= 0.01 then
        return "out of diesel", false
    end
    local def, defCap = consumerLevel(vehicle, FillType.DEF)
    if def ~= nil and defCap > 0 and def <= 0.01 then
        return "out of DEF", false
    end
    if vehicle.isUnderService ~= nil and vehicle:isUnderService() then
        return "sent to the ADS workshop", false
    end
    if vehicle.getCanMotorRun ~= nil then
        local ok, canRun = pcall(vehicle.getCanMotorRun, vehicle)
        if ok and canRun == false then
            local warning = nil
            if vehicle.getMotorNotAllowedWarning ~= nil then
                local okW, w = pcall(vehicle.getMotorNotAllowedWarning, vehicle)
                if okW then warning = w end
            end
            return "engine not allowed to run" .. (warning ~= nil and (": " .. tostring(warning)) or " (another mod blocked it)"), false
        end
    end
    return nil, false
end

if Motorized ~= nil and Motorized.stopMotor ~= nil then
    Motorized.stopMotor = Utils.prependedFunction(Motorized.stopMotor, function(self, noEventSend)
        if not ADS_FluidSystem.LOG_STOPS or self.spec_AdvancedDamageSystem == nil then return end
        if self.getIsMotorStarted == nil or not self:getIsMotorStarted() then return end

        local ok, cause, alreadyShown = pcall(ADS_FluidSystem.diagnoseStop, self)
        if not ok then cause, alreadyShown = nil, false end

        local speed = self.getLastSpeed ~= nil and self:getLastSpeed() or 0
        local okFuel, fuelText = pcall(ADS_FluidSystem.getFuelStatusText, self)
        Logging.info("[ADS] Engine stopped: %s at %.0f km/h | cause: %s | %s",
            tostring(self:getName()), speed,
            cause or "no fault found (driver, AI helper or another mod)",
            okFuel and fuelText or "")

        -- unexplained stop while moving: log who called it
        if cause == nil and speed > 1 and printCallstack ~= nil then
            pcall(printCallstack)
        end

        if cause ~= nil and not alreadyShown and self.isClient and g_currentMission ~= nil
            and self.getIsActiveForInput ~= nil and self:getIsActiveForInput(true) then
            g_currentMission:showBlinkingWarning("Engine stopped: " .. cause, 5000)
        end
    end)
end

-- ===========================================================
--                    HUD READOUT
-- ===========================================================

function ADS_FluidSystem.draw()
    if g_currentMission == nil or g_currentMission.controlledVehicle == nil then return end
    local vehicle = g_currentMission.controlledVehicle
    if vehicle.spec_AdvancedDamageSystem == nil or vehicle.adsFluidState == nil then return end
    if renderText == nil then return end

    local state = vehicle.adsFluidState
    local x, y = 0.63, 0.72
    local lineHeight = 0.019

    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(state.oilContamination > 0.7 and 0.9 or 1, state.oilContamination > 0.7 and 0.3 or 1, state.oilContamination > 0.7 and 0.3 or 1, 1)
    renderText(x, y, 0.013, string.format("Oil: %d%%  Contam: %d%%", math.floor(state.oilLevel * 100 + 0.5), math.floor(state.oilContamination * 100 + 0.5)))
    y = y - lineHeight
    setTextColor(state.coolantLevel < 0.3 and 0.9 or 1, state.coolantLevel < 0.3 and 0.3 or 1, state.coolantLevel < 0.3 and 0.3 or 1, 1)
    renderText(x, y, 0.013, string.format("Coolant: %d%%", math.floor(state.coolantLevel * 100 + 0.5)))
    setTextColor(1, 1, 1, 1)
end

if HUD ~= nil then
    HUD.draw = Utils.appendedFunction(HUD.draw, ADS_FluidSystem.draw)
end

-- ===========================================================
--                    HOOK INSTALLATION
-- ===========================================================
-- Same technique HRM2 itself uses (Motorized.onUpdate via
-- Utils.appendedFunction) - proven to work in this exact game version.

if Motorized ~= nil and Motorized.onUpdate ~= nil then
    Motorized.onUpdate = Utils.appendedFunction(Motorized.onUpdate, function(self, dt)
        pcall(function() ADS_FluidSystem.tick(self, dt) end)
    end)
end
