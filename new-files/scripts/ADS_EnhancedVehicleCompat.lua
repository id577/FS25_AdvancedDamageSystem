--[[
    ADS_EnhancedVehicleCompat.lua
    -------------------------------------------------------------------
    Optional compatibility bridge between Advanced Damage System (ADS)
    and Majo76's Enhanced Vehicle mod (FS25_EnhancedVehicle).

    If, and only if, Enhanced Vehicle is installed AND actually active in
    the current session, this file registers one additional ADS
    breakdown: FOUR_WHEEL_DRIVE_FAILURE, filed under the existing
    TRANSMISSION system. It behaves exactly like every other ADS
    breakdown - it accrues from transmission stress/condition, shows a
    dashboard warning, gets logged in the maintenance log, and is
    cleared by a normal ADS service/repair - the only difference is
    what its final stage actually *does*: it forces the vehicle back to
    2WD and releases both diff locks, and keeps doing so every effect
    tick for as long as the breakdown stays active, so the player can't
    just re-toggle 4WD back on via Enhanced Vehicle's own key bind.

    If Enhanced Vehicle is not installed/active, this breakdown is never
    applicable and will never be selected for any vehicle - ADS behaves
    exactly as it did before.

    HOW THIS WORKS WITHOUT TOUCHING ADS's OWN FILES:
    ADS_Breakdowns.BreakdownRegistry and ADS_Breakdowns.EffectApplicators
    are plain Lua tables that ADS itself iterates generically (by key, at
    runtime) rather than referencing specific breakdown/effect names in
    code. As long as this file is source()'d *after* ADS_Breakdowns.lua
    (see the one added line in ADS_Main.lua), we can just add new
    entries to those same tables and ADS's existing engine will pick
    them up automatically - same as if id577/Squallqt had shipped them.
--]]

-- ===========================================================
--                  ENHANCED VEHICLE DETECTION
-- ===========================================================

-- The exact key Enhanced Vehicle is registered under is its mod
-- folder/zip name. If you renamed the EnhancedVehicle zip to something
-- other than "FS25_EnhancedVehicle", update this string to match.
local ENHANCED_VEHICLE_MOD_NAME = "FS25_EnhancedVehicle"

-- Returns true only once Enhanced Vehicle has actually finished loading
-- and initializing for this session (not just "is present in the mod
-- list but disabled/broken").
local function isEnhancedVehicleActive()
    local modIsLoaded = g_modIsLoaded ~= nil and g_modIsLoaded[ENHANCED_VEHICLE_MOD_NAME] == true
    -- g_EnhancedVehicle is published globally by Enhanced Vehicle itself
    -- once its mission-load hook has run (see FS25_EnhancedVehicle_Loader.lua).
    local instanceExists = rawget(_G, "g_EnhancedVehicle") ~= nil or g_EnhancedVehicle ~= nil
    return modIsLoaded and instanceExists
end

-- Returns true only if this specific vehicle instance actually has
-- Enhanced Vehicle's per-vehicle state attached (EV only attaches to
-- vehicle types it applies to; some vehicles may not have it even when
-- the mod is active).
local function vehicleHasEnhancedVehicleState(vehicle)
    return vehicle ~= nil and vehicle.vData ~= nil and vehicle.vData.want ~= nil
end

ADS_Breakdowns.isEnhancedVehicleActive = isEnhancedVehicleActive
ADS_Breakdowns.vehicleHasEnhancedVehicleState = vehicleHasEnhancedVehicleState

-- ===========================================================
--                       NEW PART ENTRY
-- ===========================================================

ADS_Breakdowns.PARTS.FOUR_WHEEL_DRIVE_SYSTEM = "ads_breakdowns_part_four_wheel_drive_system"

-- ===========================================================
--                    NEW EFFECT APPLICATOR
-- ===========================================================
-- FOUR_WHEEL_DRIVE_DISABLE_EFFECT: while active, forces Enhanced
-- Vehicle's drive-mode back to 2WD and releases both diff locks every
-- time ADS recalculates active effects. This mirrors exactly what
-- Enhanced Vehicle's own front/rear/BD/DM key handlers do to
-- self.vData.want[1..3] - we're not reaching into EV's internals, just
-- writing to the same small state array EV's own per-frame
-- want-vs-is reconciliation loop already watches, so EV applies the
-- actual differential physics change itself, the normal way.
ADS_Breakdowns.EffectApplicators.FOUR_WHEEL_DRIVE_DISABLE_EFFECT = {
    getEffectName = function() return "FOUR_WHEEL_DRIVE_DISABLE_EFFECT" end,

    apply = function(vehicle, effectData, handler)
        if not vehicleHasEnhancedVehicleState(vehicle) then
            return
        end

        local want = vehicle.vData.want

        -- 0 = 2WD in Enhanced Vehicle's drive-mode enum (see
        -- FS25_EnhancedVehicle.lua's "wheel drive mode" handling).
        want[3] = 0
        -- Release front/rear diff locks too, front=index1, rear=index2.
        want[1] = false
        want[2] = false
    end,

    remove = function(vehicle, handler)
        -- Nothing to actively restore: once the breakdown is repaired,
        -- the player's next Enhanced Vehicle key press re-engages
        -- 4WD/diff-lock through Enhanced Vehicle's own normal code path.
    end
}

-- ===========================================================
--                    NEW BREAKDOWN DEFINITION
-- ===========================================================

-- IMPORTANT: AdvancedDamageSystem.SYSTEMS is defined inside
-- ADS_Specialization.lua, which is only loaded later (via
-- g_specializationManager:addSpecialization, triggered from
-- ADS_Main.initSpec() near the bottom of ADS_Main.lua) - i.e. AFTER this
-- file has already been source()'d. AdvancedDamageSystem is nil right
-- now. We use the exact same defensive fallback table ADS_Breakdowns.lua
-- itself uses for this reason (see its own "local systems = ..." line)
-- so systems.TRANSMISSION always resolves correctly regardless of load
-- order.
local systems = (AdvancedDamageSystem ~= nil and AdvancedDamageSystem.SYSTEMS) or {
    ENGINE = "ads_spec_system_engine",
    TRANSMISSION = "ads_spec_system_transmission",
    HYDRAULICS = "ads_spec_system_hydraulics",
    COOLING = "ads_spec_system_cooling",
    ELECTRICAL = "ads_spec_system_electrical",
    CHASSIS = "ads_spec_system_chassis",
    WORKPROCESS = "ads_spec_system_workprocess",
    MATERIALFLOW = "ads_spec_system_materialflow",
    FUEL = "ads_spec_system_fuel"
}
local parts = ADS_Breakdowns.PARTS
local db = ADS_Breakdowns.DASHBOARD
local color = ADS_Breakdowns.COLORS

-- Tune these two if the breakdown feels too rare/common or too cheap/
-- expensive relative to ADS's own transmission breakdowns.
local FWD_BASE_WEIGHT = 6.0          -- ambient weight even at perfect condition
local FWD_STRESS_WEIGHT = 35.0       -- added weight scaled by transmission stress (0-1)
local FWD_CONDITION_WEIGHT = 25.0    -- added weight scaled by (1 - transmission condition)

ADS_Breakdowns.BreakdownRegistry.FOUR_WHEEL_DRIVE_FAILURE = {
    isSelectable = true,
    system = systems.TRANSMISSION,
    part = parts.FOUR_WHEEL_DRIVE_SYSTEM,

    isApplicable = function(vehicle)
        -- Only ever selectable if Enhanced Vehicle is installed, active,
        -- and this vehicle actually has EV's drive-mode/diff-lock state.
        return isEnhancedVehicleActive() and vehicleHasEnhancedVehicleState(vehicle)
    end,

    probability = function(vehicle)
        local stress = 0
        local condition = 1
        if vehicle.getSystemStressLevel ~= nil then
            stress = tonumber(vehicle:getSystemStressLevel(systems.TRANSMISSION)) or 0
        end
        if vehicle.getSystemConditionLevel ~= nil then
            condition = tonumber(vehicle:getSystemConditionLevel(systems.TRANSMISSION)) or 1
        end
        stress = math.max(0, math.min(stress, 1))
        condition = math.max(0, math.min(condition, 1))

        return FWD_BASE_WEIGHT + (stress * FWD_STRESS_WEIGHT) + ((1 - condition) * FWD_CONDITION_WEIGHT)
    end,

    isCanProgress = function(vehicle)
        return vehicle:getLastSpeed() > 0.01
    end,

    stages = {
        -- Stage 1: early warning. Dashboard light comes on, no
        -- functional loss yet, cheap to fix while it's still minor.
        {
            severity = "ads_breakdowns_severity_minor",
            description = "ads_breakdowns_4wd_stage1_description",
            detectionChance = 1.0,
            progressMultiplier = 1.0,
            repairPrice = 1.5,
            effects = {},
            indicators = {
                { id = db.TRANSMISSION, color = color.WARNING, switchOn = true, switchOff = false }
            }
        },
        -- Stage 2: full failure. 4WD/diff-lock is forced off and can't
        -- be re-engaged until this is repaired at a workshop.
        {
            severity = "ads_breakdowns_severity_major",
            description = "ads_breakdowns_4wd_stage2_description",
            detectionChance = 1.0,
            progressMultiplier = 0,
            repairPrice = 5.0,
            effects = {
                {
                    id = "FOUR_WHEEL_DRIVE_DISABLE_EFFECT",
                    value = 1.0,
                    aggregation = "max",
                    extraData = { message = "ads_breakdowns_4wd_stage2_message" }
                }
            },
            indicators = {
                { id = db.TRANSMISSION, color = color.CRITICAL, switchOn = true, switchOff = false }
            }
        }
    }
}
