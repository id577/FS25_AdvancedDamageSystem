ADS_Breakdowns = {}

local function log_dbg(...)
    if ADS_Config and ADS_Config.DEBUG then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i])
        end
        print("[ADS_BREAKDOWNS] " .. table.concat(args, " "))
    end
end


ADS_Breakdowns.DASHBOARD = {
    ENGINE = "engine",
    WARNING = "warning",
    TRANSMISSION = "transmission",
    BRAKES = "brakes",
    BATTERY = "battery",
    COOLANT = "coolant",
    SERVICE = "service",
    OIL = "oil"
}

ADS_Breakdowns.COLORS = {
    DEFAULT = {1, 1, 1, 0.03},
    COOL = { 0.0097, 0.4287, 0.6445, 1 },
    WARNING  = { 1, 0.4287, 0.0006, 1 },
    CRITICAL = {0.8069, 0.0097, 0.0097, 1}
}

local color = ADS_Breakdowns.COLORS
local db = ADS_Breakdowns.DASHBOARD

ADS_Breakdowns.COLOR_PRIORITY = {
    [color.CRITICAL] = 3,
    [color.WARNING]  = 2,
    [color.COOL]     = 1,
    [color.DEFAULT]  = 0
}

-- ==========================================================
--                    BREAKDOWN REGISTRY
-- ==========================================================

local function getIsElectricVehicle(vehicle)
    for _, consumer in pairs(vehicle.spec_motorized.consumers) do
        if consumer.fillType == FillType.ELECTRICCHARGE then
            return true
        end
    end
end

local function hasCVTAddon(vehicle)
    local spec_CVTaddon = vehicle.spec_CVTaddon
    local cvtAddonConfig = spec_CVTaddon ~= nil and (tonumber(spec_CVTaddon.CVTconfig) or 0) or 0
    local hasActiveCVTAddon = spec_CVTaddon ~= nil
        and spec_CVTaddon.CVTcfgExists
        and cvtAddonConfig ~= 0
        and cvtAddonConfig ~= 8
    return hasActiveCVTAddon
end

local function hasPtoCapability(vehicle)
    if vehicle == nil then
        return false
    end

    local ptoSpec = vehicle.spec_powerTakeOffs
    if ptoSpec ~= nil then
        local outputCount = ptoSpec.outputPowerTakeOffs ~= nil and #ptoSpec.outputPowerTakeOffs or 0
        local inputCount = ptoSpec.inputPowerTakeOffs ~= nil and #ptoSpec.inputPowerTakeOffs or 0
        local localCount = ptoSpec.localPowerTakeOffs ~= nil and #ptoSpec.localPowerTakeOffs or 0
        if outputCount > 0 or inputCount > 0 or localCount > 0 then
            return true
        end
    end

    if vehicle.getOutputPowerTakeOffs ~= nil then
        local outputs = vehicle:getOutputPowerTakeOffs()
        if outputs ~= nil and next(outputs) ~= nil then
            return true
        end
    end

    if vehicle.getInputPowerTakeOffs ~= nil then
        local inputs = vehicle:getInputPowerTakeOffs()
        if inputs ~= nil and next(inputs) ~= nil then
            return true
        end
    end

    return false
end

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

ADS_Breakdowns.PARTS = {
    VEHICLE = "ads_breakdowns_part_vehicle",
    CONSUMABLES = "ads_breakdowns_part_consumables",
    ENGINE = "ads_breakdowns_part_engine",
    BATTERY = "ads_breakdowns_part_battery",
    ECU = "ads_breakdowns_part_ecu",
    WIRING = "ads_breakdowns_part_wiring",
    ALTERNATOR_REGULATOR = "ads_breakdowns_part_alternator_regulator",
    TURBOCHARGER = "ads_breakdowns_part_turbocharger",
    OIL_PUMP = "ads_breakdowns_part_oil_pump",
    VALVE_TRAIN = "ads_breakdowns_part_valve_train",
    CLUTCH = "ads_breakdowns_part_clutch",
    SYNCHRONIZER = "ads_breakdowns_part_synchronizer",
    POWERSHIFT_HYDRAULIC_PUMP = "ads_breakdowns_part_powershift_hydraulic_pump",
    CVT_CHAIN = "ads_breakdowns_part_cvt_chain",
    CVT_HYDRAULIC_CONTROL_VALVE = "ads_breakdowns_part_cvt_hydraulic_control_valve",
    CVT = "ads_breakdowns_part_cvt",
    HYDRAULIC_PUMP = "ads_breakdowns_part_hydraulic_pump",
    HYDRAULIC_CYLINDER = "ads_breakdowns_part_hydraulic_cylinder",
    PTO_CLUTCH = "ads_breakdowns_part_pto_clutch",
    BRAKE_SYSTEM = "ads_breakdowns_part_brake_system",
    WHEEL_BEARING = "ads_breakdowns_part_wheel_bearing",
    STEERING_LINKAGE = "ads_breakdowns_part_steering_linkage",
    TRACK_TENSIONER = "ads_breakdowns_part_track_tensioner",
    THERMOSTAT = "ads_breakdowns_part_thermostat",
    COOLING_SYSTEM = "ads_breakdowns_part_cooling_system",
    FAN_CLUTCH = "ads_breakdowns_part_fan_clutch",
    FUEL_PUMP = "ads_breakdowns_part_fuel_pump",
    FUEL_INJECTORS = "ads_breakdowns_part_fuel_injectors",
    FUEL_FILTER = "ads_breakdowns_part_fuel_filter",
    FUEL_LINE = "ads_breakdowns_part_fuel_line",
    HARVEST_PROCESSING_SYSTEM = "ads_breakdowns_part_harvest_processing_system",
    UNLOADING_AUGER = "ads_breakdowns_part_unloading_auger",
    GLOW_PLUGS = "ads_breakdowns_part_glow_plugs",
    HEAD_GASKET = "ads_breakdowns_part_head_gasket",
    DPF = "ads_breakdowns_part_dpf",
    DEF_SYSTEM = "ads_breakdowns_part_def_system",
    WATER_SEPARATOR = "ads_breakdowns_part_water_separator",
    SERPENTINE_BELT = "ads_breakdowns_part_serpentine_belt",
    DIFF_LOCK_ACTUATOR = "ads_breakdowns_part_diff_lock_actuator",
    TRANSMISSION_SOLENOID = "ads_breakdowns_part_transmission_solenoid",
    POWER_STEERING_PUMP = "ads_breakdowns_part_power_steering_pump",
    DASH_SENSORS = "ads_breakdowns_part_dash_sensors",
    WIRING_HARNESS = "ads_breakdowns_part_wiring_harness",
    TIRE = "ads_breakdowns_part_tire",
    TRAILER_AIR_BRAKES = "ads_breakdowns_part_trailer_air_brakes",
    CHIPPER_KNIVES = "ads_breakdowns_part_chipper_knives"
}

local parts = ADS_Breakdowns.PARTS

local breakdownPriceMultipliers = {
    ECU_MALFUNCTION = 0.60,
    CORRODED_WIRING = 0.45,
    BATTERY_SULFATION = 0.50,
    ALTERNATOR_REGULATOR_FAILURE = 0.75,
    TURBOCHARGER_MALFUNCTION = 1.00, -- 1% price
    OIL_PUMP_MALFUNCTION = 1.50,
    VALVE_TRAIN_MALFUNCTION = 1.60,
    MANUAL_TRANSMISSION_CLUTCH_WEAR = 1.30,
    MANUAL_TRANSMISSION_SYNCHRONIZER_MALFUNCTION = 1.10,
    POWERSHIFT_HYDRAULIC_PUMP_MALFUNCTION = 2.40,
    CVT_CHAIN_WEAR = 2.60,
    CVT_HYDRAULIC_CONTROL_VALVE_MALFUNCTION = 2.80,
    CVT_ADDON_MALFUNCTION = 3.0,
    HYDRAULIC_PUMP_MALFUNCTION = 0.90,
    HYDRAULIC_CYLINDER_INTERNAL_LEAK = 1.0,
    PTO_CLUTCH_SLIP = 1.25,
    BRAKE_MALFUNCTION = 0.35,
    BEARING_WEAR = 0.55,
    STEERING_LINKAGE_WEAR = 0.45,
    TRACK_TENSIONER_MALFUNCTION = 0.80,
    THERMOSTAT_MALFUNCTION = 0.50,
    COOLANT_LEAK = 0.80,
    FAN_CLUTCH_FAILURE = 0.65,
    FUEL_PUMP_MALFUNCTION = 0.55,
    FUEL_INJECTOR_MALFUNCTION = 0.80,
    FUEL_FILTER_CLOGGING = 0.35,
    FUEL_LINE_AIR_LEAK = 0.45,
    HARVEST_PROCESSING_SYSTEM_WEAR = 0.85,
    UNLOADING_AUGER_MALFUNCTION = 0.40,
    GLOW_PLUG_FAILURE = 0.30,
    HEAD_GASKET_FAILURE = 1.40,
    DPF_CLOGGING = 0.90,
    DEF_SYSTEM_FAULT = 0.70,
    WATER_IN_FUEL = 0.25,
    SERPENTINE_BELT_FAILURE = 0.25,
    DIFF_LOCK_ACTUATOR_STUCK = 0.60,
    TRANSMISSION_SOLENOID_FAULT = 1.00,
    POWER_STEERING_PUMP_FAILURE = 0.50,
    DASH_SENSOR_FAULT = 0.25,
    RODENT_DAMAGED_WIRING = 0.40,
    SLOW_PUNCTURE = 0.15,
    TRAILER_AIR_BRAKE_LEAK = 0.40,
    FLAT_TIRE = 0.12,
}

local breakdownProgressMultipliers = {
    ECU_MALFUNCTION = 1.00, -- 3.5 hours
    CORRODED_WIRING = 0.9,
    BATTERY_SULFATION = 1.4,
    ALTERNATOR_REGULATOR_FAILURE = 1.1,
    TURBOCHARGER_MALFUNCTION = 1.1,
    OIL_PUMP_MALFUNCTION = 1.3,
    VALVE_TRAIN_MALFUNCTION = 1.4,
    MANUAL_TRANSMISSION_CLUTCH_WEAR = 1.00,
    MANUAL_TRANSMISSION_SYNCHRONIZER_MALFUNCTION = 1.3,
    POWERSHIFT_HYDRAULIC_PUMP_MALFUNCTION = 1.1,
    CVT_CHAIN_WEAR = 1.2,
    CVT_HYDRAULIC_CONTROL_VALVE_MALFUNCTION = 1.1,
    CVT_ADDON_MALFUNCTION = 1.4,
    HYDRAULIC_PUMP_MALFUNCTION = 1.1,
    HYDRAULIC_CYLINDER_INTERNAL_LEAK = 0.6,
    PTO_CLUTCH_SLIP = 0.75,
    BRAKE_MALFUNCTION = 0.9,
    BEARING_WEAR = 1.2,
    STEERING_LINKAGE_WEAR = 1.2,
    TRACK_TENSIONER_MALFUNCTION = 1.3,
    THERMOSTAT_MALFUNCTION = 1.4,
    COOLANT_LEAK = 0.6,
    FAN_CLUTCH_FAILURE = 0.9,
    FUEL_PUMP_MALFUNCTION = 1.1,
    FUEL_INJECTOR_MALFUNCTION = 1.1,
    FUEL_FILTER_CLOGGING = 1.2,
    FUEL_LINE_AIR_LEAK = 0.8,
    HARVEST_PROCESSING_SYSTEM_WEAR = 1.35,
    UNLOADING_AUGER_MALFUNCTION = 1.2,
    GLOW_PLUG_FAILURE = 1.2,
    HEAD_GASKET_FAILURE = 1.0,
    DPF_CLOGGING = 1.1,
    DEF_SYSTEM_FAULT = 0.9,
    WATER_IN_FUEL = 0.8,
    SERPENTINE_BELT_FAILURE = 0.8,
    DIFF_LOCK_ACTUATOR_STUCK = 1.0,
    TRANSMISSION_SOLENOID_FAULT = 1.1,
    POWER_STEERING_PUMP_FAILURE = 1.0,
    DASH_SENSOR_FAULT = 1.2,
    RODENT_DAMAGED_WIRING = 0.9,
    SLOW_PUNCTURE = 0.7,
    TRAILER_AIR_BRAKE_LEAK = 0.9
}

-- ==========================================================
--          HELPERS FOR THE EXTENDED BREAKDOWN SET
-- ==========================================================

local function isCarLikeVehicle(vehicle)
    local vtype = vehicle ~= nil and vehicle.type ~= nil and vehicle.type.name or ""
    return vtype == "car" or vtype == "carFillable" or vtype == "motorbike"
end

local function hasCombustionEngine(vehicle)
    return vehicle ~= nil and vehicle.spec_motorized ~= nil and not getIsElectricVehicle(vehicle)
end

local function getVehicleYear(vehicle)
    local spec = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    return spec ~= nil and (tonumber(spec.year) or 0) or 0
end

local function hasWheelsWithoutTracks(vehicle)
    if vehicle == nil or vehicle.spec_wheels == nil or vehicle.spec_wheels.wheels == nil or #vehicle.spec_wheels.wheels == 0 then
        return false
    end
    if vehicle.spec_crawlers ~= nil and vehicle.spec_crawlers.crawlers ~= nil and #vehicle.spec_crawlers.crawlers > 0 then
        return false
    end
    return true
end

local function hasGearedTransmission(vehicle)
    if hasCVTAddon(vehicle) then return false end
    local motor = vehicle.getMotor ~= nil and vehicle:getMotor() or nil
    if motor == nil then return false end
    return motor.minForwardGearRatio == nil
end

local function canTowTrailers(vehicle)
    if vehicle == nil or isCarLikeVehicle(vehicle) then
        return false
    end
    local spec_aj = vehicle.spec_attacherJoints
    return spec_aj ~= nil and spec_aj.attacherJoints ~= nil and #spec_aj.attacherJoints > 0
end

-- True when the vehicle is pulling at least one wheeled implement/trailer whose
-- wheels can brake (i.e. something that would be on the tractor's trailer air line).
local function isTowingBrakedImplement(vehicle)
    if vehicle == nil or vehicle.getAttachedImplements == nil then
        return false
    end

    local visited = {}
    local function hasBrakedWheels(object)
        local spec_wheels = object.spec_wheels
        if spec_wheels == nil or spec_wheels.wheels == nil or #spec_wheels.wheels == 0 then
            return false
        end
        if object.spec_trailer ~= nil then
            return true
        end
        for _, wheel in ipairs(spec_wheels.wheels) do
            local runtime = wheel.physics or wheel
            local brakeFactor = tonumber(runtime.brakeFactor) or tonumber(wheel.brakeFactor) or 0
            if brakeFactor > 0 then
                return true
            end
        end
        return false
    end

    local function walk(object)
        if object == nil or visited[object] then
            return false
        end
        visited[object] = true
        local implements = object.getAttachedImplements ~= nil and object:getAttachedImplements() or nil
        if implements == nil then
            return false
        end
        for _, implement in pairs(implements) do
            local child = implement ~= nil and implement.object or nil
            if child ~= nil then
                if child.spec_motorized == nil and hasBrakedWheels(child) then
                    return true
                end
                if walk(child) then
                    return true
                end
            end
        end
        return false
    end

    return walk(vehicle)
end

ADS_Breakdowns.isTowingBrakedImplement = isTowingBrakedImplement

-- Phantom dashboard warning used by DASH_SENSOR_FAULT. Fires a short pulse roughly
-- once per `periodMs`; the HUD latches it on until the engine is switched off,
-- just like a real intermittent sensor fault. switchOff stays false so a phantom
-- light can never hide a genuine warning on the same lamp.
local function phantomIndicator(periodMs, offsetMs)
    return function(vehicle)
        if vehicle == nil or vehicle.getIsMotorStarted == nil or not vehicle:getIsMotorStarted() then
            return false
        end
        local t = (tonumber(g_time) or 0) + (offsetMs or 0)
        return (t % periodMs) < 250
    end
end

local function engineIsColdForGlowPlugs(vehicle)
    local spec = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    if spec == nil then return false end
    local engTemp = tonumber(spec.rawEngineTemperature or spec.engineTemperature) or 20
    return engTemp < 20
end

local function engineIsWarmForGlowPlugs(vehicle)
    local spec = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    if spec == nil then return true end
    local engTemp = tonumber(spec.rawEngineTemperature or spec.engineTemperature) or 20
    return engTemp >= 40
end

-- DEF (AdBlue) tank on the vehicle, as used by FS25's native DEF consumer and by
-- the JSM "Diesel Exhaust Fluid System" mod (which refills and displays that same
-- fill unit). Returns fillLevel, capacity - or nil if the machine has no DEF tank.
local function getDefTankState(vehicle)
    if vehicle == nil or vehicle.spec_motorized == nil or FillType == nil or FillType.DEF == nil then
        return nil
    end

    local fillUnitIndex = nil
    if vehicle.getConsumerFillUnitIndex ~= nil then
        fillUnitIndex = vehicle:getConsumerFillUnitIndex(FillType.DEF)
    end
    if fillUnitIndex == nil then
        local byType = vehicle.spec_motorized.consumersByFillType
        local consumer = byType ~= nil and byType[FillType.DEF] or nil
        if consumer == nil and vehicle.spec_motorized.consumers ~= nil then
            for _, entry in ipairs(vehicle.spec_motorized.consumers) do
                if entry.fillType == FillType.DEF then
                    consumer = entry
                    break
                end
            end
        end
        fillUnitIndex = consumer ~= nil and consumer.fillUnitIndex or nil
    end

    if fillUnitIndex == nil or vehicle.getFillUnitCapacity == nil or vehicle.getFillUnitFillLevel == nil then
        return nil
    end

    local capacity = tonumber(vehicle:getFillUnitCapacity(fillUnitIndex)) or 0
    if capacity <= 0 then
        return nil
    end

    return tonumber(vehicle:getFillUnitFillLevel(fillUnitIndex)) or 0, capacity
end

ADS_Breakdowns.getDefTankState = getDefTankState

-- Sudden flat tire (nail, stubble, stone). One entry per side so the pull
-- direction is saved with the breakdown and identical for every MP client.
-- Never chosen by wear/stress: AdvancedDamageSystem:updateRandomFlatTire() rolls for it.
-- side: 1 = left (pulls left), -1 = right (pulls right)
local function buildFlatTireBreakdown(side)
    local sideKey = side > 0 and "left" or "right"
    return {
        isSelectable = true,
        system = systems.CHASSIS,
        part = parts.TIRE,
        isApplicable = function(vehicle)
            return hasWheelsWithoutTracks(vehicle)
        end,
        probability = function(vehicle)
            return 0.0
        end,
        isCanProgress = function(vehicle)
            return false
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_flat_tire_" .. sideKey .. "_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 1.0 * breakdownPriceMultipliers.FLAT_TIRE,
                effects = {
                    -- "sum" so a right-side (negative) pull is not swallowed by other left-pull effects
                    { id = "STEERING_STATIC_BIAS_EFFECT", value = 0.06 * side, aggregation = "sum" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.65, aggregation = "max", extraData = { message = "ads_breakdowns_flat_tire_" .. sideKey .. "_message", disableAi = true } },
                    { id = "VIBRATION_NOISE_EFFECT", value = 2.0, aggregation = "max" },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.10, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.15, aggregation = "sum" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_flat_tire_" .. sideKey },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    }
end

local function getBreakdownFactorWeightPercent(vehicle, systemName, ...)
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        return 0
    end

    local factorStats = vehicle.spec_AdvancedDamageSystem.factorStats
    if type(factorStats) ~= "table" then
        return 0
    end

    local targetSystem = systemName
    if type(targetSystem) == "string" and systems[targetSystem] ~= nil then
        targetSystem = systems[targetSystem]
    end

    local systemKey = ADS_Utils ~= nil and ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, targetSystem) or nil
    if systemKey == nil or systemKey == "" then
        systemKey = string.lower(tostring(targetSystem or ""))
    end

    local systemStats = factorStats[systemKey]
    if type(systemStats) ~= "table" then
        return 0
    end

    local requestedAliases = {}
    local rawArgs = {...}
    for _, arg in ipairs(rawArgs) do
        if type(arg) == "table" then
            for _, alias in ipairs(arg) do
                if alias ~= nil then
                    table.insert(requestedAliases, tostring(alias))
                end
            end
        elseif arg ~= nil then
            table.insert(requestedAliases, tostring(arg))
        end
    end

    if #requestedAliases == 0 then
        return 0
    end

    local numerator = 0
    local denominator = 0
    for statKey, statValue in pairs(systemStats) do
        local numericValue = math.max(tonumber(statValue) or 0, 0)
        if statKey ~= "total" and statKey ~= "stress" then
            denominator = denominator + numericValue
            for _, alias in ipairs(requestedAliases) do
                if statKey == alias then
                    numerator = numerator + numericValue
                    break
                end
            end
        end
    end

    if denominator <= 0 or numerator <= 0 then
        return 0
    end

    return math.max((numerator / denominator) * 100, 0)
end

local BREAKDOWN_SECONDARY_FACTOR_WEIGHT = 0.35
local BREAKDOWN_FALLBACK_WEIGHT = 1.0

local function getBreakdownProbabilityWeightPercent(vehicle, systemName, primaryAliases, secondaryAliases, fallbackWeight, secondaryWeight)
    local resolvedFallbackWeight = math.max(tonumber(fallbackWeight) or BREAKDOWN_FALLBACK_WEIGHT, 0)
    local resolvedSecondaryWeight = math.max(tonumber(secondaryWeight) or BREAKDOWN_SECONDARY_FACTOR_WEIGHT, 0)

    local primaryWeight = getBreakdownFactorWeightPercent(vehicle, systemName, primaryAliases)
    local secondaryWeightPercent = getBreakdownFactorWeightPercent(vehicle, systemName, secondaryAliases)
    local weightedPercent = primaryWeight + secondaryWeightPercent * resolvedSecondaryWeight

    if weightedPercent <= 0 then
        return resolvedFallbackWeight
    end

    return math.max(weightedPercent, resolvedFallbackWeight)
end

ADS_Breakdowns.BreakdownRegistry = {

--------------------- NOT SELECTEBLE BREAKDOWNS (does not happen by chance, but is the result of various conditions) ---------------------

    GENERAL_WEAR = {
        isSelectable = false,
        part = parts.VEHICLE,
        isApplicable = function(vehicle)
            return true
        end,
        probability = function(vehicle)
            return 0.0
        end,
        isCanProgress = function(vehicle)
            return false
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_permanent",
                description = "ads_breakdowns_general_wear_stage1_description",
                detectionChance = 0.0,
                progressMultiplier = 0.0,
                repairPrice = 0.0,
                effects = {},
                indicators = {}
            }
        }
    },

    COLD_ENGINE = {
        system = systems.ENGINE,
        part = parts.ENGINE,
        isSelectable = false,
        isApplicable = function(vehicle)
            return true
        end,
        probability = function(vehicle)
            return 0.0
        end,
        isCanProgress = function(vehicle)
            return false
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_permanent",
                description = "",
                detectionChance = 0.0,
                progressMultiplier = 0.0,
                repairPrice = 0.0,
                effects = {
                    {
                        id = "ENGINE_HARD_START_MODIFIER",
                        value = 0,
                        aggregation = "max",
                        extraData = {timer = 0, status = 'IDLE'}
                    }
                },
                indicators = {}
            }
        }
    },

    DEAD_BATTERY = {
        system = systems.ELECTRICAL,
        part = parts.BATTERY,
        isSelectable = false,
        isApplicable = function(vehicle)
            return true
        end,
        probability = function(vehicle)
            return 0.0
        end,
        isCanProgress = function(vehicle)
            return false
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_permanent",
                description = "",
                detectionChance = 0.0,
                progressMultiplier = 0.0,
                repairPrice = 0.0,
                effects = {
                    { id = "ENGINE_FAILURE", value = 1.0, extraData = {starter = false, message = "ads_breakdowns_dead_battery_message", reason = "BREAKDOWN", disableAi = true}, aggregation = "boolean_or"},
                    { id = "LIGHTS_FAILURE", value = 1.0, aggregation = "boolean_or" }
                },
                indicators = {
                    { id = db.BATTERY, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    VOLTAGE_SAG = {
        system = systems.ELECTRICAL,
        part = parts.VEHICLE,
        isSelectable = false,
        isApplicable = function(vehicle)
            return true
        end,
        probability = function(vehicle)
            return 0.0
        end,
        isCanProgress = function(vehicle)
            return false
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_permanent",
                description = "",
                detectionChance = 0.0,
                progressMultiplier = 0.0,
                repairPrice = 0.0,
                effects = {
                    { id = "LIGHTS_FLICKER_CHANCE", value = 0.1, extraData = {timer = 0, status = 'IDLE', duration = 200, maskBackup = 0}, aggregation = "min"},
                    { id = "PTO_AUTO_DISENGAGE_CHANCE", value = 1, aggregation = "min", extraData = {status = 'IDLE'} },
                    { id = "ENGINE_STALLS_CHANCE", value = 10.0, aggregation = "min" },
                    { id = "ENGINE_HARD_START_MODIFIER", value = 3, extraData = { timer = 0, status = 'IDLE', message = "ads_breakdowns_voltage_sag_message"}},
                },
                indicators = {
                    { id = db.BATTERY, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    AIRINTAKE_CLOGGING = {
        system = systems.ENGINE,
        part = parts.VEHICLE,
        isSelectable = false,
        isApplicable = function(vehicle)
            local spec = vehicle.spec_AdvancedDamageSystem
            if spec == nil then return end
            if spec.isVEhicleNeedBlowOut then
                return true
            end
            return false
        end,
        probability = function(vehicle)
            return 0.0
        end,
        isCanProgress = function(vehicle)
            return false
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "",
                detectionChance = 0.0,
                progressMultiplier = 0.0,
                repairPrice = 0.0,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.03, aggregation = "sum"},
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.06, aggregation = "sum" },

                },
                indicators = {
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "",
                detectionChance = 0.0,
                progressMultiplier = 0.0,
                repairPrice = 0.0,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.06, aggregation = "sum"},
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.12, aggregation = "sum" },

                },
                indicators = {
                }
            },
                        {
                severity = "ads_breakdowns_severity_major",
                description = "",
                detectionChance = 0.0,
                progressMultiplier = 0.0,
                repairPrice = 0.0,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.10, aggregation = "sum"},
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.18, aggregation = "sum" },
                    { id = "ENGINE_HEAT_MODIFIER", value = 0.05, aggregation = "sum" }
                },
                indicators = {
                }
            }
        }
    },

    STRESS_OVERLOAD = {
        part = parts.VEHICLE,
        isSelectable = false,
        isApplicable = function(vehicle)
            return true
        end,
        probability = function(vehicle)
            return 0.0
        end,
        isCanProgress = function(vehicle)
            return false
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "",
                detectionChance = 0.0,
                progressMultiplier = 0.0,
                repairPrice = 0.0,
                effects = {},
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "",
                detectionChance = 0.0,
                progressMultiplier = 0.0,
                repairPrice = 0.0,
                effects = {
                    { id = "EMPTY_EFFECT", value = 1.0, aggregation = "boolean_or",  extraData = {message = "ads_breakdowns_overload_breakdown_stage2_message", reason = "BREAKDOWN", disableAi = true}}
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
        }
    },

    MAINTENANCE_WITH_POOR_QUALITY_CONSUMABLES = {
        isSelectable = false,
        part = parts.CONSUMABLES,
        isApplicable = function(vehicle)
            return true
        end,
        probability = function(vehicle)
            return 1.0   
        end,
        isCanProgress = function(vehicle)
            return true
        end,
        stages = {
            {
                severity = "",
                description = "",
                detectionChance = 0.0,
                progressMultiplier = 5.0,
                repairPrice = 0.0,
                effects = {
                    { id = "CONDITION_WEAR_MODIFIER", value = 0.33, aggregation = 'sum' },
                    { id = "SERVICE_WEAR_MODIFIER", value = 0.33, aggregation = 'sum' }
                }
            },
            {
                severity = "",
                description = "",
                detectionChance = 0.0,
                progressMultiplier = 0.0,
                repairPrice = 0.0,
                effects = {
                    { id = "SELF_DISAPPEARING_BREAKDOWN_EFFECT", value = 1.0, aggregation = 'boolean_or', extraData = {breakdownId = "MAINTENANCE_WITH_POOR_QUALITY_CONSUMABLES"} }
                }
            },   
        },
    },

    OVERHEAT_PROTECTION = {
        isSelectable = false,
        system = systems.ENGINE,
        part = parts.VEHICLE,
        isApplicable = function(vehicle)
            return true
        end,
        probability = function(vehicle)
            return 1.0   
        end,
        isCanProgress = function(vehicle)
            return false
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_reduce_power",
                description = "ads_breakdowns_overheat_protection_stage1_description",
                detectionChance = 0.0,
                progressMultiplier = 0.0,
                repairPrice = 0.0,
                effects = {
                    { id = "ENGINE_LIMP_EFFECT", value = -0.2, aggregation = "min", extraData = {reason = "OVERHEAT", message = "ads_breakdowns_overheat_protection_stage1_message", disableAi = true } },
                },
                indicators = {
                    {  
                        id = db.WARNING,
                        color = color.CRITICAL,
                        switchOn = true,
                        switchOff = false
                    }
                }
            },            
            {
                severity = "ads_breakdowns_severity_reduce_power",
                description = "ads_breakdowns_overheat_protection_stage2_description",
                detectionChance = 0.0,
                progressMultiplier = 0.0,
                repairPrice = 0.0,
                effects = {
                    { id = "ENGINE_LIMP_EFFECT", value = -0.5, aggregation = "min", extraData = {reason = "OVERHEAT", message = "ads_breakdowns_overheat_protection_stage2_message", disableAi = true }  },
                },
                indicators = {
                    {  
                        id = db.WARNING,
                        color = color.CRITICAL,
                        switchOn = true,
                        switchOff = false
                    }
                }
            },
            {
                severity = "ads_breakdowns_severity_reduce_power",
                description = "ads_breakdowns_overheat_protection_stage3_description",
                detectionChance = 0.0,
                progressMultiplier = 0.0,
                repairPrice = 0.0,
                effects = {
                    { id = "ENGINE_LIMP_EFFECT", value = -0.8, aggregation = "min", extraData = {reason = "OVERHEAT", message = "ads_breakdowns_overheat_protection_stage3_message", disableAi = true } },
                },
                indicators = {
                    {  
                        id = db.WARNING,
                        color = color.CRITICAL,
                        switchOn = true,
                        switchOff = false
                    }
                }
            },
            {
                severity = "ads_breakdowns_severity_shutdown",
                description = "ads_breakdowns_overheat_protection_stage4_description",
                detectionChance = 0.0,
                progressMultiplier = 0.0,
                repairPrice = 0.0,
                effects = {
                     { id = "ENGINE_FAILURE", value = 1.0, aggregation = "boolean_or", extraData = {starter = false, message = "ads_breakdowns_overheat_protection_stage4_message", reason = "OVERHEAT", disableAi = true } },
                },
                indicators = {
                    {  
                        id = db.WARNING,
                        color = color.CRITICAL,
                        switchOn = true,
                        switchOff = false
                    }
                }
            }
        }
    },

    ENGINE_JAM = {
        isSelectable = false,
        system = systems.ENGINE,
        part = parts.ENGINE,
        isApplicable = function(vehicle)
            return true
        end,
        probability = function(vehicle)
            return 1.0   
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_engine_jam_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 0.0,
                repairPrice = 20.0,
                effects = {
                    { id = "ENGINE_FAILURE", value = 1.0, aggregation = "boolean_or", extraData = {starter = false, message = "ads_breakdowns_engine_jam_stage1_message", reason = "OVERHEAT", disableAi = true} },
                },
                indicators = {
                    {  
                        id = db.ENGINE,
                        color = color.CRITICAL,
                        switchOn = true,
                        switchOff = false
                    }
                }
            }
        }
    },
    

-------------------------------------------- SELECTABLE -----------------------------------------

    -- electrical
    ECU_MALFUNCTION = {
        isSelectable = true,
        system = systems.ELECTRICAL,
        part = parts.ECU,
        isApplicable = function(vehicle)
            local spec = vehicle.spec_AdvancedDamageSystem
            if spec.year >= 2000 and not getIsElectricVehicle(vehicle) then
                return true
            end
            return false
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.ELECTRICAL, {"ohf"}, {"crf", "idfg", "sf"})
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_ecu_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.ECU_MALFUNCTION,
                repairPrice = 1.0 * breakdownPriceMultipliers.ECU_MALFUNCTION,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.10, aggregation = "sum"},
                    { id = "DARK_EXHAUST_EFFECT", value = 0.40, aggregation = "max" },
                },
                indicators = {
                    {  
                        id = db.ENGINE,
                        color = color.WARNING,
                        switchOn = function(vehicle)
                            if vehicle.spec_motorized and vehicle:getIsMotorStarted() and vehicle:getMotorLoadPercentage() > 0.95 then
                                return true
                            end
                            return false
                        end,
                        switchOff = function(vehicle)
                            if vehicle.spec_motorized and vehicle:getIsMotorStarted() and vehicle:getMotorLoadPercentage() <= 0.50 then
                                return true
                            end
                            return false
                        end,
                    }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_ecu_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.ECU_MALFUNCTION,
                repairPrice = 2.0 * breakdownPriceMultipliers.ECU_MALFUNCTION,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.20, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.2, aggregation = "sum" },
                    { id = "DARK_EXHAUST_EFFECT", value = 0.50, aggregation = "max" }
                },
                indicators = {
                    { id = db.ENGINE, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_ecu_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.ECU_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.ECU_MALFUNCTION,
                effects = { 
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.35, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.5, aggregation = "sum" },
                    { id = "ENGINE_STALLS_CHANCE", value = 10.0, aggregation = "min" },
                    { id = "ENGINE_HARD_START_MODIFIER", value = 2, aggregation = "max", extraData = { timer = 0, status = 'IDLE'}},
                    { id = "DARK_EXHAUST_EFFECT", value = 1.0, aggregation = "max" }
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_ecu_malfunction_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.ECU_MALFUNCTION,
                effects = { 
                    { id = "ENGINE_FAILURE", value = 1.0, aggregation = "boolean_or",  extraData = {starter = true, message = "ads_breakdowns_ecu_malfunction_stage4_message", reason = "BREAKDOWN", disableAi = true}} 
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    CORRODED_WIRING = {
        isSelectable = true,
        system = systems.ELECTRICAL,
        part = parts.WIRING,
        isApplicable = function(vehicle)
            local spec = vehicle.spec_AdvancedDamageSystem
            return spec.year >= 2000 and vehicle.spec_lights ~= nil
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.ELECTRICAL, {"wef"}, {"sf", "ltf"})
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_corroded_wiring_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.CORRODED_WIRING,
                repairPrice = 1.0 * breakdownPriceMultipliers.CORRODED_WIRING,
                effects = {
                    { id = "LIGHTS_FLICKER_CHANCE", value = 1.0, extraData = {timer = 0, status = 'IDLE', duration = 200, maskBackup = 0}, aggregation = "min"},
                    { id = "ENGINE_HARD_START_MODIFIER", value = 3, extraData = { timer = 0, status = 'IDLE'}, aggregation = "max"},
                    { id = "ELECTRICAL_CONTACT_RESISTANCE_EFFECT", value = 1.0, extraData = { timer = 0, status = 'IDLE'}, aggregation = "min"}
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate", 
                description = "ads_breakdowns_corroded_wiring_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.CORRODED_WIRING,
                repairPrice = 2.0 * breakdownPriceMultipliers.CORRODED_WIRING,
                effects = {
                    { id = "LIGHTS_FLICKER_CHANCE", value = 0.33, extraData = {timer = 0, status = 'IDLE', duration = 300, maskBackup = 0}, aggregation = "min" },
                    { id = "ENGINE_STALLS_CHANCE", value = 30.0, aggregation = "min" },
                    { id = "ENGINE_HARD_START_MODIFIER", value = 5, extraData = { timer = 0, status = 'IDLE'}, aggregation = "max"},
                    { id = "ELECTRICAL_CONTACT_RESISTANCE_EFFECT", value = 0.33, extraData = { timer = 0, status = 'IDLE'}, aggregation = "min"}
                },
                inspection = {
                    { additional = "ads_inspection_hint_corroded_wiring_stage2" },
                },
                indicators = {
                    { id = db.BATTERY, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_corroded_wiring_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.CORRODED_WIRING,
                repairPrice = 4.0 * breakdownPriceMultipliers.CORRODED_WIRING,
                effects = { 
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.10, aggregation = "sum"},
                    { id = "LIGHTS_FAILURE", value = 1.0, aggregation = "boolean_or" },
                    { id = "ENGINE_STALLS_CHANCE", value = 20.0, aggregation = "min" },
                    { id = "ENGINE_HARD_START_MODIFIER", value = 8, extraData = { timer = 0, status = 'IDLE'}, aggregation = "max"},
                    { id = "ELECTRICAL_CONTACT_RESISTANCE_EFFECT", value = 0.1, extraData = { timer = 0, status = 'IDLE'}, aggregation = "min"}
                },
                inspection = {
                    { additional = "ads_inspection_hint_corroded_wiring_stage3" },
                },
                indicators = {
                    { id = db.BATTERY, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_corroded_wiring_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.CORRODED_WIRING,
                effects = { 
                    { id = "LIGHTS_FAILURE", value = 1.0, aggregation = "boolean_or" },
                    { id = "ENGINE_FAILURE", value = 1.0, extraData = {starter = false, message = "ads_breakdowns_corroded_wiring_stage4_message", reason = "BREAKDOWN", disableAi = true}, aggregation = "boolean_or"} 
                },
                inspection = {
                    { additional = "ads_inspection_hint_corroded_wiring_stage4" },
                },
                indicators = {
                    { id = db.BATTERY, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    BATTERY_SULFATION = {
        isSelectable = true,
        system = systems.ELECTRICAL,
        part = parts.BATTERY,
        isApplicable = function(vehicle)
            return true
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.ELECTRICAL, {"crf", "idfg"}, {"sf"})
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_battery_sulfation_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.BATTERY_SULFATION,
                repairPrice = 1.0 * breakdownPriceMultipliers.BATTERY_SULFATION,
                effects = {
                    { id = "BATTERY_HEALTH_MODIFIER", value = -0.3, aggregation = "min"},

                },
                inspection = {
                    { additional = "ads_inspection_hint_battery_sulfation_stage1" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate", 
                description = "ads_breakdowns_battery_sulfation_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.BATTERY_SULFATION,
                repairPrice = 2.0 * breakdownPriceMultipliers.BATTERY_SULFATION,
                effects = {
                    { id = "BATTERY_HEALTH_MODIFIER", value = -0.6, aggregation = "min"},
                    { id = "ENGINE_HARD_START_MODIFIER", value = 3, extraData = { timer = 0, status = 'IDLE'}, aggregation = "max"},
                },
                inspection = {
                    { additional = "ads_inspection_hint_battery_sulfation_stage2" },
                },
                indicators = {
                    { id = db.BATTERY, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_battery_sulfation_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.BATTERY_SULFATION,
                repairPrice = 4.0 * breakdownPriceMultipliers.BATTERY_SULFATION,
                effects = { 
                    { id = "BATTERY_HEALTH_MODIFIER", value = -0.9, aggregation = "min"},
                    { id = "ENGINE_HARD_START_MODIFIER", value = 6, extraData = { timer = 0, status = 'IDLE'}, aggregation = "max"},
                },
                inspection = {
                    { additional = "ads_inspection_hint_battery_sulfation_stage3" },
                },
                indicators = {
                    { id = db.BATTERY, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_battery_sulfation_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.BATTERY_SULFATION,
                effects = { 
                    { id = "BATTERY_HEALTH_MODIFIER", value = -1.0, aggregation = "min"},
                    { id = "ENGINE_HARD_START_MODIFIER", value = 9, extraData = { timer = 0, status = 'IDLE'}, aggregation = "max"},
                },
                inspection = {
                    { additional = "ads_inspection_hint_battery_sulfation_stage4" },
                },
                indicators = {
                    { id = db.BATTERY, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    ALTERNATOR_REGULATOR_FAILURE = {
        isSelectable = true,
        system = systems.ELECTRICAL,
        part = parts.ALTERNATOR_REGULATOR,
        isApplicable = function(vehicle)
            return true
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.ELECTRICAL, {"ohf", "crf", "idfg"}, {"ltf", "sf"})
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_alternator_regulator_failure_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.ALTERNATOR_REGULATOR_FAILURE,
                repairPrice = 1.0 * breakdownPriceMultipliers.ALTERNATOR_REGULATOR_FAILURE,
                effects = {
                    { id = "ALTERNATOR_HEALTH_MODIFIER", value = -0.2, aggregation = "min" }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_alternator_regulator_failure_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.ALTERNATOR_REGULATOR_FAILURE,
                repairPrice = 2.0 * breakdownPriceMultipliers.ALTERNATOR_REGULATOR_FAILURE,
                effects = {
                    { id = "ALTERNATOR_HEALTH_MODIFIER", value = -0.5, aggregation = "min" },
                    { id = "ELECTRICAL_CONTACT_RESISTANCE_EFFECT", value = 2.0, extraData = { timer = 0, status = 'IDLE'}, aggregation = "min"}
                },
                indicators = {
                    { id = db.BATTERY, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_alternator_regulator_failure_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.ALTERNATOR_REGULATOR_FAILURE,
                repairPrice = 4.0 * breakdownPriceMultipliers.ALTERNATOR_REGULATOR_FAILURE,
                effects = {
                    { id = "ALTERNATOR_HEALTH_MODIFIER", value = -0.7, aggregation = "min" },
                    { id = "ELECTRICAL_CONTACT_RESISTANCE_EFFECT", value = 1.0, extraData = { timer = 0, status = 'IDLE'}, aggregation = "min"}
                },
                inspection = {
                    { additional = "ads_inspection_hint_alternator_regulator_failure_stage3" },
                },
                indicators = {
                    { id = db.BATTERY, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_alternator_regulator_failure_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.ALTERNATOR_REGULATOR_FAILURE,
                effects = {
                    { id = "ALTERNATOR_HEALTH_MODIFIER", value = -1.0, aggregation = "min" },
                    { id = "ELECTRICAL_CONTACT_RESISTANCE_EFFECT", value = 0.3, extraData = { timer = 0, status = 'IDLE'}, aggregation = "min"}
                },
                inspection = {
                    { additional = "ads_inspection_hint_alternator_regulator_failure_stage4" },
                },
                indicators = {
                    { id = db.BATTERY, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- engine
    TURBOCHARGER_MALFUNCTION = {
        isSelectable = true,
        system = systems.ENGINE,
        part = parts.TURBOCHARGER,
        isApplicable = function(vehicle)
            local name = vehicle:getFullName()
            if name == "Fiat 160-90 DT" then return true end
            -- Turbocharged diesels became standard on farm machinery from the mid-80s on.
            return hasCombustionEngine(vehicle) and not isCarLikeVehicle(vehicle) and getVehicleYear(vehicle) >= 1985
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.ENGINE, {"hmf", "mlf"}, {"aicf", "sf"})
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_turbocharger_wear_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.TURBOCHARGER_MALFUNCTION,
                repairPrice = 1.0 * breakdownPriceMultipliers.TURBOCHARGER_MALFUNCTION,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.10, aggregation = "sum" },
                    { id = "TURBO_WHISTLE_NOISE_EFFECT", value = 0.25, aggregation = "max" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_turbocharger_wear_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.TURBOCHARGER_MALFUNCTION,
                repairPrice = 2.0 * breakdownPriceMultipliers.TURBOCHARGER_MALFUNCTION,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.25, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.20, aggregation = "sum" },
                    { id = "TURBO_WHISTLE_NOISE_EFFECT", value = 0.35, aggregation = "max" },
                },
                indicators = {
                    { id = db.ENGINE, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_turbocharger_wear_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.TURBOCHARGER_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.TURBOCHARGER_MALFUNCTION,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.35, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.40, aggregation = "sum" },
                    { id = "ENGINE_STALLS_CHANCE", value = 10.0, aggregation = "min" },
                    { id = "TURBO_WHISTLE_NOISE_EFFECT", value = 0.6, aggregation = "max" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_turbocharger_malfunction_stage3" },
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_turbocharger_wear_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.TURBOCHARGER_MALFUNCTION,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.50, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.60, aggregation = "sum" },
                    { id = "ENGINE_STALLS_CHANCE", value = 10.0, aggregation = "min" },
                    { id = "DARK_EXHAUST_EFFECT", value = 0.6, aggregation = "max" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_turbocharger_malfunction_stage4" },
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false },
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    OIL_PUMP_MALFUNCTION = {
        isSelectable = true,
        system = systems.ENGINE,
        part = parts.OIL_PUMP,
        isApplicable = function(vehicle)
            return not getIsElectricVehicle(vehicle)
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.ENGINE, {"sf"}, {"hmf", "cmf"})
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_oil_pump_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.OIL_PUMP_MALFUNCTION,
                repairPrice = 1.0 * breakdownPriceMultipliers.OIL_PUMP_MALFUNCTION,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.05, aggregation = "sum" },
                    { id = "ENGINE_KNOCKING_NOISE_EFFECT", value = 0.30, aggregation = "max" },
                    { id = "ENGINE_HEAT_MODIFIER", value = 0.05, aggregation = "sum" },
                    
                },
                inspection = {
                    { target = "engineOil", status = "ads_inspection_status_slightly_darkened", additional = "ads_inspection_hint_oil_pump_malfunction_stage1" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_oil_pump_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.OIL_PUMP_MALFUNCTION,
                repairPrice = 2.0 * breakdownPriceMultipliers.OIL_PUMP_MALFUNCTION,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.25, aggregation = "sum" },
                    { id = "ENGINE_KNOCKING_NOISE_EFFECT", value = 0.5, aggregation = "max" },
                    { id = "ENGINE_HEAT_MODIFIER", value = 0.15, aggregation = "sum" },
                },
                inspection = {
                    { target = "engineOil", status = "ads_inspection_status_darkened", additional = "ads_inspection_hint_oil_pump_malfunction_stage2" },
                },
                indicators = {
                    { id = db.ENGINE, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_oil_pump_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.OIL_PUMP_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.OIL_PUMP_MALFUNCTION,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.45, aggregation = "sum" },
                    { id = "ENGINE_STALLS_CHANCE", value = 10.0, aggregation = "min" },
                    { id = "ENGINE_KNOCKING_NOISE_EFFECT", value = 0.8, aggregation = "max" },
                    { id = "ENGINE_HEAT_MODIFIER", value = 0.35, aggregation = "sum" },
                },
                inspection = {
                    { target = "engineOil", status = "ads_inspection_status_contaminated", additional = "ads_inspection_hint_oil_pump_malfunction_stage3" },
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_oil_pump_malfunction_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.OIL_PUMP_MALFUNCTION,
                effects = {
                    { id = "ENGINE_FAILURE", value = 1.0, aggregation = "boolean_or", extraData = {starter = true, message = "ads_breakdowns_oil_pump_malfunction_stage4_message", reason = "BREAKDOWN", disableAi = true} },
                },
                inspection = {
                    { target = "engineOil", status = "ads_inspection_status_critical_condition", additional = "ads_inspection_hint_oil_pump_malfunction_stage4" },
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                
                }
            }
        }
    },

    VALVE_TRAIN_MALFUNCTION = {
        isSelectable = true,
        system = systems.ENGINE,
        part = parts.VALVE_TRAIN,
        isApplicable = function(vehicle)
            return not getIsElectricVehicle(vehicle)
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.ENGINE, {"sf", "cmf"}, {"hmf", "mlf"})
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_valve_train_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.VALVE_TRAIN_MALFUNCTION,
                repairPrice = 1.0 * breakdownPriceMultipliers.VALVE_TRAIN_MALFUNCTION,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.04, aggregation = "sum" },
                    { id = "VALVE_TRAIN_NOISE_EFFECT", value = 0.5, aggregation = "max" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.05, aggregation = "sum" },
                    
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_valve_train_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.VALVE_TRAIN_MALFUNCTION,
                repairPrice = 2.0 * breakdownPriceMultipliers.VALVE_TRAIN_MALFUNCTION,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.12, aggregation = "sum" },
                    { id = "VALVE_TRAIN_NOISE_EFFECT", value = 0.7, aggregation = "max" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.10, aggregation = "sum" },
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.3, aggregation = "max", extraData = {timer = 0, duration = 300, status = 'IDLE', amplitude = 0.6, motorLoad = 0.8, cruiseState = 0} }
                },
                indicators = {
                    { id = db.ENGINE, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_valve_train_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.VALVE_TRAIN_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.VALVE_TRAIN_MALFUNCTION,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.25, aggregation = "sum" },
                    { id = "ENGINE_STALLS_CHANCE", value = 10.0, aggregation = "min" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.20, aggregation = "sum" },
                    { id = "VALVE_TRAIN_NOISE_EFFECT", value = 1.0, aggregation = "max" },
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.15, extraData = {timer = 0, duration = 500, status = 'IDLE', amplitude = 1.0, motorLoad = 0.5, cruiseState = 0}, aggregation = "max" }
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_valve_train_malfunction_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.VALVE_TRAIN_MALFUNCTION,
                effects = {
                    { id = "ENGINE_FAILURE", value = 1.0, aggregation = "boolean_or", extraData = {starter = true, message = "ads_breakdowns_valve_train_malfunction_stage4_message", reason = "BREAKDOWN", disableAi = true} },
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }         
                }
            }
        }
    },

    -- transmission system
    MANUAL_TRANSMISSION_CLUTCH_WEAR = {
        isSelectable = true,
        system = systems.TRANSMISSION,
        part = parts.CLUTCH,
        isApplicable = function(vehicle)
            if hasCVTAddon(vehicle) then return false end
            local motor = vehicle:getMotor()
            if not motor then return false end
            return motor.minForwardGearRatio == nil
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.TRANSMISSION, {"wsf", "lf"}, {"pof", "sf"})
        end,
        isCanProgress = function(vehicle)
            return vehicle:getLastSpeed() > 0.01
        end,

        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_transmission_slip_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.MANUAL_TRANSMISSION_CLUTCH_WEAR,
                repairPrice = 1.0 * breakdownPriceMultipliers.MANUAL_TRANSMISSION_CLUTCH_WEAR,
                effects = {
                    { id = "TRANSMISSION_SLIP_EFFECT", value = 0.20, extraData = {accumulatedMod = 0.0}, aggregation = "max" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_transmission_slip_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.MANUAL_TRANSMISSION_CLUTCH_WEAR,
                repairPrice = 2.0 * breakdownPriceMultipliers.MANUAL_TRANSMISSION_CLUTCH_WEAR,
                effects = {
                     { id = "TRANSMISSION_SLIP_EFFECT", value = 0.40, extraData = {accumulatedMod = 0.0}, aggregation = "max" },
                     { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.20, aggregation = "sum" }
                },
                indicators = {
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_transmission_slip_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.MANUAL_TRANSMISSION_CLUTCH_WEAR,
                repairPrice = 4.0 * breakdownPriceMultipliers.MANUAL_TRANSMISSION_CLUTCH_WEAR,
                effects = { 
                     { id = "TRANSMISSION_SLIP_EFFECT", value = 0.60, extraData = {accumulatedMod = 0.0}, aggregation = "max"},
                     { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.50, aggregation = "sum" }
                },
                indicators = {
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_transmission_slip_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.MANUAL_TRANSMISSION_CLUTCH_WEAR,
                effects = { 
                     { id = "TRANSMISSION_SLIP_EFFECT", value = 1.0, extraData = {accumulatedMod = 0.0, message = "ads_breakdowns_transmission_slip_stage4_message", disableAi = true}, aggregation = "max" }
                },
                indicators = {
                }
            }
        }
    },

    MANUAL_TRANSMISSION_SYNCHRONIZER_MALFUNCTION = {
        isSelectable = true,
        system = systems.TRANSMISSION,
        part = parts.SYNCHRONIZER,
        isApplicable = function(vehicle)
            if hasCVTAddon(vehicle) then return false end
            local motor = vehicle:getMotor()
            if not motor then return false end
            return motor.minForwardGearRatio == nil and motor.gearType ~= VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.TRANSMISSION, {"lf", "pof"}, {"sf"})
        end,
        isCanProgress = function(vehicle)
            return vehicle:getLastSpeed() > 0.01
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_transmission_synchronizer_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.MANUAL_TRANSMISSION_SYNCHRONIZER_MALFUNCTION,
                repairPrice = 1.0 * breakdownPriceMultipliers.MANUAL_TRANSMISSION_SYNCHRONIZER_MALFUNCTION,
                effects = {
                    { id = "GEAR_SHIFT_FAILURE_CHANCE", value = 0.10, extraData = {timer = 0, status = 'IDLE', duration = 1500}, aggregation = "max"},
                    { id = "GEAR_REJECTION_CHANCE", value = 20.0, extraData = {timer = 0, status = 'IDLE', duration = 2000 }, aggregation = "min"}
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_transmission_synchronizer_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.MANUAL_TRANSMISSION_SYNCHRONIZER_MALFUNCTION,
                repairPrice = 2.0 * breakdownPriceMultipliers.MANUAL_TRANSMISSION_SYNCHRONIZER_MALFUNCTION,
                effects = {
                     { id = "GEAR_SHIFT_FAILURE_CHANCE", value = 0.20, extraData = {timer = 0, status = 'IDLE', duration = 1800}, aggregation = "max"},
                     { id = "GEAR_REJECTION_CHANCE", value = 10.0, extraData = {timer = 0, status = 'IDLE', duration = 2000 }, aggregation = "min"}
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_transmission_synchronizer_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.MANUAL_TRANSMISSION_SYNCHRONIZER_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.MANUAL_TRANSMISSION_SYNCHRONIZER_MALFUNCTION,
                effects = { 
                     { id = "GEAR_SHIFT_FAILURE_CHANCE", value = 0.50, extraData = {timer = 0, status = 'IDLE', duration = 2200}, aggregation = "max"},
                     { id = "GEAR_REJECTION_CHANCE", value = 3.0, extraData = {timer = 0, status = 'IDLE', duration = 2000 }, aggregation = "min"}
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_transmission_synchronizer_malfunction_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.MANUAL_TRANSMISSION_SYNCHRONIZER_MALFUNCTION,
                effects = { 
                     { id = "GEAR_SHIFT_FAILURE_CHANCE", value = 1.00, extraData = {timer = 0, status = 'IDLE', duration = 2200, message = "ads_breakdowns_transmission_synchronizer_malfunction_stage4_message", disableAi = true}, aggregation = "max"}
                }
            }
        }
    },

    POWERSHIFT_HYDRAULIC_PUMP_MALFUNCTION = {
        isSelectable = true,
        system = systems.TRANSMISSION,
        part = parts.POWERSHIFT_HYDRAULIC_PUMP,
        isApplicable = function(vehicle)
            if hasCVTAddon(vehicle) then return false end
            local motor = vehicle:getMotor()
            if not motor then return false end
            return motor.gearType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.TRANSMISSION, {"hotf"}, {"pof", "sf"})
        end,
        isCanProgress = function(vehicle)
            return vehicle:getLastSpeed() > 0.01
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_powershift_hydraulic_pump_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.POWERSHIFT_HYDRAULIC_PUMP_MALFUNCTION,
                repairPrice = 1.0 * breakdownPriceMultipliers.POWERSHIFT_HYDRAULIC_PUMP_MALFUNCTION,
                effects = {
                    { id = "POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT", value = 0.2, extraData = {timer = 0, status = "IDLE", duration = 700, backup = 0}, aggregation = "max"}
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_powershift_hydraulic_pump_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.POWERSHIFT_HYDRAULIC_PUMP_MALFUNCTION,
                repairPrice = 2.0 * breakdownPriceMultipliers.POWERSHIFT_HYDRAULIC_PUMP_MALFUNCTION,
                effects = {
                     { id = "POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT", value = 0.5, extraData = {timer = 0, status = "IDLE", duration = 1000, backup = 0}, aggregation = "max"}
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_powershift_hydraulic_pump_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.POWERSHIFT_HYDRAULIC_PUMP_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.POWERSHIFT_HYDRAULIC_PUMP_MALFUNCTION,
                effects = { 
                     { id = "POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT", value = 0.99, extraData = {timer = 0, status = "IDLE", duration = 1500, backup = 0}, aggregation = "max"}
                },
                inspection = {
                    { additional = "ads_inspection_hint_powershift_hydraulic_pump_malfunction_stage3" },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_powershift_hydraulic_pump_malfunction_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.POWERSHIFT_HYDRAULIC_PUMP_MALFUNCTION,
                effects = { 
                     { id = "POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT", value = 1.0, extraData = {timer = 0, status = "IDLE", duration = 0, disableAi = true}, aggregation = "max"}
                },
                inspection = {
                    { additional = "ads_inspection_hint_powershift_hydraulic_pump_malfunction_stage4" },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    CVT_CHAIN_WEAR = {
        isSelectable = true,
        system = systems.TRANSMISSION,
        part = parts.CVT_CHAIN,
        isApplicable = function(vehicle)
            if hasCVTAddon(vehicle) then return false end
            local motor = vehicle:getMotor()
            if not motor then return false end
            if motor.minForwardGearRatio == nil then return false end
            return true
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.TRANSMISSION, {"wsf", "lf"}, {"hotf", "pof"})
        end,
        isCanProgress = function(vehicle)
            return vehicle:getLastSpeed() > 0.01
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_cvt_chain_wear_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.CVT_CHAIN_WEAR,
                repairPrice = 1.0 * breakdownPriceMultipliers.CVT_CHAIN_WEAR,
                effects = {
                    { id = "CVT_SLIP_EFFECT", value = 0.1, extraData = {accumulatedMod = 0.0}, aggregation = "max" },
                    { id = "TRANASMISSION_HEAT_MODIFIER", value = 0.05, aggregation = "sum" }  
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_cvt_chain_wear_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.CVT_CHAIN_WEAR,
                repairPrice = 2.0 * breakdownPriceMultipliers.CVT_CHAIN_WEAR,
                effects = {
                     { id = "CVT_SLIP_EFFECT", value = 0.2, extraData = {accumulatedMod = 0.0}, aggregation = "max" },
                     { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.20, aggregation = "sum" },
                     { id = "TRANASMISSION_HEAT_MODIFIER", value = 0.1, aggregation = "sum" }
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_cvt_chain_wear_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.CVT_CHAIN_WEAR,
                repairPrice = 4.0 * breakdownPriceMultipliers.CVT_CHAIN_WEAR,
                effects = { 
                     { id = "CVT_SLIP_EFFECT", value = 0.5, extraData = {accumulatedMod = 0.0}, aggregation = "max" },
                     { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.25, aggregation = "sum" },
                     { id = "TRANASMISSION_HEAT_MODIFIER", value = 0.15, aggregation = "sum" }
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_cvt_chain_wear_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.CVT_CHAIN_WEAR,
                effects = { 
                     { id = "CVT_SLIP_EFFECT", value = 1.0, extraData = {accumulatedMod = 0.0, message = "ads_breakdowns_cvt_chain_wear_stage4_message", disableAi = true}, aggregation = "max" }
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    CVT_HYDRAULIC_CONTROL_VALVE_MALFUNCTION = {
        isSelectable = true,
        system = systems.TRANSMISSION,
        part = parts.CVT_HYDRAULIC_CONTROL_VALVE,
        isApplicable = function(vehicle)
            if hasCVTAddon(vehicle) then return false end
            local motor = vehicle:getMotor()
            if not motor then return false end
            if motor.minForwardGearRatio == nil then return false end
            return true
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.TRANSMISSION, {"hotf"}, {"ctf", "sf"})
        end,
        isCanProgress = function(vehicle)
            return vehicle:getLastSpeed() > 0.01
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_hydraulic_control_valve_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.CVT_HYDRAULIC_CONTROL_VALVE_MALFUNCTION,
                repairPrice = 1.0 * breakdownPriceMultipliers.CVT_HYDRAULIC_CONTROL_VALVE_MALFUNCTION,
                effects = {
                    { id = "CVT_PRESSURE_DROP_CHANCE", value = 2.0, aggregation = "max", extraData = {timer = 0, duration = 200, status = 'IDLE'}},
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.05, aggregation = "sum" },
                    { id = "CVT_MAX_RATIO_MODIFIER", value = 0.3, aggregation = "max" },
                },
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_hydraulic_control_valve_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.CVT_HYDRAULIC_CONTROL_VALVE_MALFUNCTION,
                repairPrice = 2.0 * breakdownPriceMultipliers.CVT_HYDRAULIC_CONTROL_VALVE_MALFUNCTION,
                effects = {
                    { id = "CVT_PRESSURE_DROP_CHANCE", value = 1.0, aggregation = "max", extraData = {timer = 0, duration = 250, status = 'IDLE'}},
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.1, aggregation = "sum" },
                    { id = "TRANASMISSION_HEAT_MODIFIER", value = 0.05, aggregation = "sum" },
                    { id = "CVT_MAX_RATIO_MODIFIER", value = 0.4, aggregation = "max" },
                    
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_hydraulic_control_valve_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.CVT_HYDRAULIC_CONTROL_VALVE_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.CVT_HYDRAULIC_CONTROL_VALVE_MALFUNCTION,
                effects = { 
                    { id = "CVT_PRESSURE_DROP_CHANCE", value = 0.5, aggregation = "max", extraData = {timer = 0, duration = 300, status = 'IDLE'}},
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.2, aggregation = "sum" },
                    { id = "TRANASMISSION_HEAT_MODIFIER", value = 0.1, aggregation = "sum" },
                    { id = "CVT_MAX_RATIO_MODIFIER", value = 0.5, aggregation = "max" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_cvt_hydraulic_control_valve_malfunction_stage3" },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_hydraulic_control_valve_malfunction_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.CVT_HYDRAULIC_CONTROL_VALVE_MALFUNCTION,
                effects = { 
                     { id = "CVT_MAX_RATIO_MODIFIER", value = 0.8, aggregation = "max" },
                     { id = "TRANASMISSION_HEAT_MODIFIER", value = 0.15, aggregation = "sum" },
                     { id = "ENGINE_TORQUE_MODIFIER", value = -0.3, aggregation = "sum" },
                     { id = "CVT_PRESSURE_DROP_CHANCE", value = 0.1, aggregation = "max", extraData = {timer = 0, duration = 300, status = 'IDLE'}},
                     { id = "ENGINE_LIMP_EFFECT", value = -0.2, aggregation = "min", extraData = {reason = "BREAKDOWN", message = "ads_breakdowns_hydraulic_control_valve_malfunction_stage4_message", disableAi = true } },
                },
                inspection = {
                    { additional = "ads_inspection_hint_cvt_hydraulic_control_valve_malfunction_stage4" },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    CVT_ADDON_MALFUNCTION = {
        isSelectable = true,
        system = systems.TRANSMISSION,
        part = parts.CVT,
        isApplicable = function(vehicle)
            if hasCVTAddon(vehicle) then return true end
            return false
        end,
        probability = function(vehicle)
            return 1.0
        end,
        isCanProgress = function(vehicle)
            return false
        end,
        stages = {
            { 
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_cvt_addon_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 3.0 * breakdownProgressMultipliers.CVT_ADDON_MALFUNCTION,
                repairPrice = 1.0 * breakdownPriceMultipliers.CVT_ADDON_MALFUNCTION,
                effects = { 
                },
                indicators = {
            
                }
            },
            { 
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_cvt_addon_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.5 * breakdownProgressMultipliers.CVT_ADDON_MALFUNCTION,
                repairPrice = 2.0 * breakdownPriceMultipliers.CVT_ADDON_MALFUNCTION,
                effects = { 
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_cvt_addon_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.CVT_ADDON_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.CVT_ADDON_MALFUNCTION,
                effects = { 
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_cvt_addon_malfunction_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.CVT_ADDON_MALFUNCTION,
                effects = { 
                    { id = "CVT_SLIP_EFFECT", value = 1.0, extraData = {accumulatedMod = 0.0, message = "ads_breakdowns_cvt_addon_malfunction_stage4_message", disableAi = true}, aggregation = "max" }
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- hydraulic system
    HYDRAULIC_PUMP_MALFUNCTION = {
        isSelectable = true,
        system = systems.HYDRAULICS,
        part = parts.HYDRAULIC_PUMP,
        isApplicable = function(vehicle)
            local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
            if storeItem.categoryName == "TRUCKS" then return false end
            local vtype = vehicle.type.name
            local spec = vehicle.spec_AdvancedDamageSystem
            return vtype ~= "car" and vtype ~= "carFillable" and vtype ~= "motorbike" and spec.year >= 1960
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.HYDRAULICS, {"hlf", "of"}, {"cof", "sf"})
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_hydraulic_pump_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.HYDRAULIC_PUMP_MALFUNCTION,
                repairPrice = 1.0 * breakdownPriceMultipliers.HYDRAULIC_PUMP_MALFUNCTION,
                effects = {
                    { id = "HYDRAULIC_SPEED_MODIFIER", value = -0.20, aggregation = "min" }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_hydraulic_pump_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.HYDRAULIC_PUMP_MALFUNCTION,
                repairPrice = 2.0 * breakdownPriceMultipliers.HYDRAULIC_PUMP_MALFUNCTION,
                effects = {
                    { id = "HYDRAULIC_SPEED_MODIFIER", value = -0.40, aggregation = "min" }
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_hydraulic_pump_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.HYDRAULIC_PUMP_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.HYDRAULIC_PUMP_MALFUNCTION,
                effects = { 
                    { id = "HYDRAULIC_SPEED_MODIFIER", value = -0.75, aggregation = "min" }
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_hydraulic_pump_malfunction_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.HYDRAULIC_PUMP_MALFUNCTION,
                effects = { 
                    { id = "HYDRAULIC_SPEED_MODIFIER", value = -1.0, extraData = {message = 'ads_breakdowns_hydraulic_pump_malfunction_stage4_message', disableAi = true}, aggregation = "min" }
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },
    
    HYDRAULIC_CYLINDER_INTERNAL_LEAK  = {
        isSelectable = true,
        system = systems.HYDRAULICS,
        part = parts.HYDRAULIC_CYLINDER,
        isApplicable = function(vehicle)
            local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
            if storeItem.categoryName == "TRUCKS" then return false end
            local vtype = vehicle.type.name
            local spec = vehicle.spec_AdvancedDamageSystem
            return vtype ~= "car" and vtype ~= "carFillable" and vtype ~= "motorbike" and spec.year >= 1960
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.HYDRAULICS, {"hlf", "of"}, {"sf"})
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_hydraulic_cylinder_internal_leak_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.HYDRAULIC_CYLINDER_INTERNAL_LEAK,
                repairPrice = 1.0 * breakdownPriceMultipliers.HYDRAULIC_CYLINDER_INTERNAL_LEAK,
                effects = {
                    { id = "HYDRAULIC_SPEED_MODIFIER", value = -0.10, aggregation = "min" },
                    { id = "HYDRAULIC_HOLD_DRIFT_EFFECT", value = 0.01, aggregation = "max", extraData = {status = 'IDLE', timer = 0, massRatio = 0.5} }
                },
                inspection = {
                    { target = "hydraulicFluid", status = "ads_inspection_status_slight_moisture", additional = "ads_inspection_hint_hydraulic_cylinder_internal_leak_stage1" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_hydraulic_cylinder_internal_leak_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.HYDRAULIC_CYLINDER_INTERNAL_LEAK,
                repairPrice = 2.0 * breakdownPriceMultipliers.HYDRAULIC_CYLINDER_INTERNAL_LEAK,
                effects = {
                    { id = "HYDRAULIC_SPEED_MODIFIER", value = -0.30, aggregation = "min" },
                    { id = "HYDRAULIC_HOLD_DRIFT_EFFECT", value = 0.03, aggregation = "max", extraData = {status = 'IDLE', timer = 0, massRatio = 0.4}}
                },
                inspection = {
                    { target = "hydraulicFluid", status = "ads_inspection_status_seepage", additional = "ads_inspection_hint_hydraulic_cylinder_internal_leak_stage2" },
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_hydraulic_cylinder_internal_leak_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.HYDRAULIC_CYLINDER_INTERNAL_LEAK,
                repairPrice = 4.0 * breakdownPriceMultipliers.HYDRAULIC_CYLINDER_INTERNAL_LEAK,
                effects = { 
                    { id = "HYDRAULIC_SPEED_MODIFIER", value = -0.55, aggregation = "min" },
                    { id = "HYDRAULIC_HOLD_DRIFT_EFFECT", value = 0.05, aggregation = "max", extraData = {status = 'IDLE', timer = 0, massRatio = 0.2} }
                },
                inspection = {
                    { target = "hydraulicFluid", status = "ads_inspection_status_active_leak", additional = "ads_inspection_hint_hydraulic_cylinder_internal_leak_stage3" },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_hydraulic_cylinder_internal_leak_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.HYDRAULIC_CYLINDER_INTERNAL_LEAK,
                effects = { 
                    { id = "HYDRAULIC_SPEED_MODIFIER", value = -7.0, extraData = {message = 'ads_breakdowns_hydraulic_cylinder_internal_leak_stage4_message', disableAi = true}, aggregation = "min" },
                    { id = "HYDRAULIC_HOLD_DRIFT_EFFECT", value = 1.0, aggregation = "max", extraData = {status = 'IDLE', timer = 0, massRatio = 0.0} }
                },
                inspection = {
                    { target = "hydraulicFluid", status = "ads_inspection_status_severe_leak", additional = "ads_inspection_hint_hydraulic_cylinder_internal_leak_stage4" },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    PTO_CLUTCH_SLIP   = {
        isSelectable = true,
        system = systems.HYDRAULICS,
        part = parts.PTO_CLUTCH,
        isApplicable = function(vehicle)
            return hasPtoCapability(vehicle)
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.HYDRAULICS, {"saf"}, {"of", "sf"})
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_pto_clutch_slip_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.PTO_CLUTCH_SLIP,
                repairPrice = 1.0 * breakdownPriceMultipliers.PTO_CLUTCH_SLIP,
                effects = {
                    { id = "PTO_TORQUE_TRANSFER_MODIFIER", value = 0.2, aggregation = "max" },
                    { id = "PTO_AUTO_DISENGAGE_CHANCE", value = 24, aggregation = "min", extraData = {status = 'IDLE'} }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_pto_clutch_slip_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.PTO_CLUTCH_SLIP,
                repairPrice = 2.0 * breakdownPriceMultipliers.PTO_CLUTCH_SLIP,
                effects = {
                    { id = "PTO_TORQUE_TRANSFER_MODIFIER", value = 0.4, aggregation = "max" },
                    { id = "PTO_AUTO_DISENGAGE_CHANCE", value = 12, aggregation = "min", extraData = {status = 'IDLE'}}
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_pto_clutch_slip_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.PTO_CLUTCH_SLIP,
                repairPrice = 4.0 * breakdownPriceMultipliers.PTO_CLUTCH_SLIP,
                effects = { 
                    { id = "PTO_TORQUE_TRANSFER_MODIFIER", value = 0.6, aggregation = "max" },
                    { id = "PTO_AUTO_DISENGAGE_CHANCE", value = 6.0, aggregation = "min", extraData = {status = 'IDLE'} }
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_pto_clutch_slip_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.PTO_CLUTCH_SLIP,
                effects = {
                    { id = "PTO_FAILURE", value = 1.0, aggregation = "max", extraData = {message = "ads_breakdowns_pto_clutch_slip_stage4_message", reason = "BREAKDOWN", disableAi = true}},
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                
                }
            }
        }
    },
    
    -- chassis system
    BRAKE_MALFUNCTION = {
        isSelectable = true,
        system = systems.CHASSIS,
        part = parts.BRAKE_SYSTEM,
        isApplicable = function(vehicle)
            if vehicle.spec_crawlers ~= nil then
                return #vehicle.spec_crawlers.crawlers == 0
            else
                return true
            end
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.CHASSIS, {"bmf"}, {"sf"})
        end,
        isCanProgress = function(vehicle)
            return true
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_brake_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.BRAKE_MALFUNCTION,
                repairPrice = 1.0 * breakdownPriceMultipliers.BRAKE_MALFUNCTION,
                effects = {
                    { id = "BRAKE_FORCE_MODIFIER", value = -0.30, aggregation = "min",  extraData = {timer = 0, soundPlayed = false} }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_brake_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.BRAKE_MALFUNCTION,
                repairPrice = 2.0 * breakdownPriceMultipliers.BRAKE_MALFUNCTION,
                effects = {
                    { id = "BRAKE_FORCE_MODIFIER", value = -0.45, aggregation = "min",  extraData = {timer = 0, soundPlayed = false} }
                },
                indicators = {
                    { id = db.BRAKES, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_brake_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.BRAKE_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.BRAKE_MALFUNCTION,
                effects = { 
                    { id = "BRAKE_FORCE_MODIFIER", value = -0.70, aggregation = "min",  extraData = {timer = 0, soundPlayed = false} }
                },
                indicators = {
                    { id = db.BRAKES, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_brake_malfunction_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.BRAKE_MALFUNCTION,
                effects = { 
                    { id = "BRAKE_FORCE_MODIFIER", value = -1.0, aggregation = "min", extraData = {message = "ads_breakdowns_brake_malfunction_stage4_message", disableAi = true, timer = 0, soundPlayed = false} }
                },
                indicators = {
                    { id = db.BRAKES, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    BEARING_WEAR = {
        isSelectable = true,
        system = systems.CHASSIS,
        part = parts.WHEEL_BEARING,
        isApplicable = function(vehicle)
            if vehicle.spec_crawlers ~= nil then
                return #vehicle.spec_crawlers.crawlers == 0
            else
                return true
            end
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.CHASSIS, {"vf"}, {"bmf", "sf"})
        end,
        isCanProgress = function(vehicle)
            return vehicle:getLastSpeed() > 0.01
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_bearing_wear_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.BEARING_WEAR,
                repairPrice = 1.0 * breakdownPriceMultipliers.BEARING_WEAR,
                effects = {
                    { id = "WHEEL_HUB_BEARING_NOISE_EFFECT", value = 1.0, aggregation = "max" },
                    { id = "VIBRATION_NOISE_EFFECT", value = 1.0, aggregation = "max" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.05, aggregation = "max" },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.03, aggregation = "sum" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_bearing_wear_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.BEARING_WEAR,
                repairPrice = 2.0 * breakdownPriceMultipliers.BEARING_WEAR,
                effects = {
                    { id = "WHEEL_HUB_BEARING_NOISE_EFFECT", value = 1.5, aggregation = "max" },
                    { id = "VIBRATION_NOISE_EFFECT", value = 1.5, aggregation = "max" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.10, aggregation = "max" },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.05, aggregation = "sum" },
                },
                indicators = {

                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_bearing_wear_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.BEARING_WEAR,
                repairPrice = 4.0 * breakdownPriceMultipliers.BEARING_WEAR,
                effects = { 
                    { id = "WHEEL_HUB_BEARING_NOISE_EFFECT", value = 2.0, aggregation = "max" },
                    { id = "VIBRATION_NOISE_EFFECT", value = 2.0, aggregation = "max" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.20, aggregation = "max" },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.07, aggregation = "sum" },
                    { id = "WHEEL_SEIZURE_GRIND_NOISE_EFFECT", value = 0.3, aggregation = "max" }
                },
                indicators = {

                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_bearing_wear_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.BEARING_WEAR,
                effects = { 
                    { id = "WHEEL_SEIZURE_GRIND_NOISE_EFFECT", value = 2.5, aggregation = "max" },
                    { id = "WHEEL_SEIZURE_EFFECT", value = 1.0, aggregation = "max", extraData = {message = "ads_breakdowns_bearing_wear_stage4_message", disableAi = true}},
                },
                indicators = {
                    { id = db.BRAKES, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    STEERING_LINKAGE_WEAR = {
        isSelectable = true,
        system = systems.CHASSIS,
        part = parts.STEERING_LINKAGE,
        isApplicable = function(vehicle)
            if vehicle.spec_wheels == nil or vehicle.spec_wheels.wheels == nil or #vehicle.spec_wheels.wheels == 0 then
                return false
            end
            if vehicle.spec_crawlers ~= nil and #vehicle.spec_crawlers.crawlers > 0 then
                return false
            end
            return true
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.CHASSIS, {"slf"}, {"vf", "sf"})
        end,
        isCanProgress = function(vehicle)
            return vehicle:getLastSpeed() > 0.01
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_steering_linkage_wear_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.STEERING_LINKAGE_WEAR,
                repairPrice = 1.0 * breakdownPriceMultipliers.STEERING_LINKAGE_WEAR,
                effects = {
                    { id = "STEERING_STATIC_BIAS_EFFECT", value = 0.003, aggregation = "max" },
                    { id = "STEERING_SENSITIVITY_MODIFIER", value = 0.10, aggregation = "max" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_steering_linkage_wear_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.STEERING_LINKAGE_WEAR,
                repairPrice = 2.0 * breakdownPriceMultipliers.STEERING_LINKAGE_WEAR,
                effects = {
                    { id = "STEERING_STATIC_BIAS_EFFECT", value = 0.01, aggregation = "max" },
                    { id = "STEERING_SENSITIVITY_MODIFIER", value = 0.25, aggregation = "max" },
                },
                indicators = {
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_steering_linkage_wear_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.STEERING_LINKAGE_WEAR,
                repairPrice = 4.0 * breakdownPriceMultipliers.STEERING_LINKAGE_WEAR,
                effects = {
                    { id = "STEERING_STATIC_BIAS_EFFECT", value = 0.03, aggregation = "max" },
                    { id = "STEERING_SENSITIVITY_MODIFIER", value = 0.45, aggregation = "max" },
                },
                indicators = {
                    { id = db.BRAKES, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_steering_linkage_wear_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.STEERING_LINKAGE_WEAR,
                effects = {
                    { id = "STEERING_SENSITIVITY_MODIFIER", value = 0.99, aggregation = "max", extraData = {message="ads_breakdowns_steering_linkage_wear_stage4_message", disableAi=true} },
                },
                indicators = {
                    { id = db.BRAKES, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    TRACK_TENSIONER_MALFUNCTION = {
        isSelectable = true,
        system = systems.CHASSIS,
        part = parts.TRACK_TENSIONER,
        isApplicable = function(vehicle)
            if vehicle.spec_crawlers ~= nil and #vehicle.spec_crawlers.crawlers > 0 then
                return true
            end
            return false
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.CHASSIS, {"vf"}, {"slf"})
        end,
        isCanProgress = function(vehicle)
            return vehicle:getLastSpeed() > 0.01
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_track_tensioner_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.TRACK_TENSIONER_MALFUNCTION,
                repairPrice = 1.0 * breakdownPriceMultipliers.TRACK_TENSIONER_MALFUNCTION,
                effects = {
                    { id = "STEERING_STATIC_BIAS_EFFECT", value = 0.003, aggregation = "max" },
                    { id = "VIBRATION_NOISE_EFFECT", value = 1.0, aggregation = "max" },
                    { id = "WHEEL_SEIZURE_GRIND_NOISE_EFFECT", value = 0.5, aggregation = "max" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.03, aggregation = "max" },

                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_track_tensioner_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.TRACK_TENSIONER_MALFUNCTION,
                repairPrice = 2.0 * breakdownPriceMultipliers.TRACK_TENSIONER_MALFUNCTION,
                effects = {
                    { id = "STEERING_STATIC_BIAS_EFFECT", value = 0.01, aggregation = "max" },
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.3, aggregation = "max", extraData = {timer = 0, duration = 400, status = 'IDLE', amplitude = 0.6, motorLoad = 0.2, cruiseState = 0}},
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.05, aggregation = "sum" },
                    { id = "VIBRATION_NOISE_EFFECT", value = 1.5, aggregation = "max" },
                    { id = "WHEEL_SEIZURE_GRIND_NOISE_EFFECT", value = 1.0, aggregation = "max" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.06, aggregation = "max" },

                },
                inspection = {
                    { additional = "ads_inspection_hint_track_tensioner_malfunction_stage2" },
                },
                indicators = {
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_track_tensioner_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.TRACK_TENSIONER_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.TRACK_TENSIONER_MALFUNCTION,
                effects = {
                    { id = "STEERING_STATIC_BIAS_EFFECT", value = 0.05, aggregation = "max" },
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.1, aggregation = "max", extraData = {timer = 0, duration = 500, status = 'IDLE', amplitude = 0.6, motorLoad = 0.2, cruiseState = 0}},
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.1, aggregation = "sum" },
                    { id = "VIBRATION_NOISE_EFFECT", value = 2.0, aggregation = "max" },
                    { id = "WHEEL_SEIZURE_GRIND_NOISE_EFFECT", value = 2.0, aggregation = "max" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.15, aggregation = "max" },

                },
                inspection = {
                    { additional = "ads_inspection_hint_track_tensioner_malfunction_stage3" },
                },
                indicators = {
                    { id = db.BRAKES, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_track_tensioner_malfunction_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.TRACK_TENSIONER_MALFUNCTION,
                effects = {
                    { id = "WHEEL_SEIZURE_GRIND_NOISE_EFFECT", value = 2.5, aggregation = "max" },
                    { id = "WHEEL_SEIZURE_EFFECT", value = 1.0, aggregation = "max", extraData = {message = "ads_breakdowns_track_tensioner_malfunction_stage4_message", disableAi = true}},
                },
                inspection = {
                    { additional = "ads_inspection_hint_track_tensioner_malfunction_stage4" },
                },
                indicators = {
                    { id = db.BRAKES, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- cooling system
    THERMOSTAT_MALFUNCTION = {
        isSelectable = true,
        system = systems.COOLING,
        part = parts.THERMOSTAT,
        isApplicable = function(vehicle)
            return not getIsElectricVehicle(vehicle)
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.COOLING, {"hcf"}, {"csf", "sf"})
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_thermostat_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.THERMOSTAT_MALFUNCTION,
                repairPrice = 1.0 * breakdownPriceMultipliers.THERMOSTAT_MALFUNCTION,
                effects = {
                    { id = "THERMOSTAT_HEALTH_MODIFIER", value = -0.3, aggregation = "min"}
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_thermostat_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.THERMOSTAT_MALFUNCTION,
                repairPrice = 2.0 * breakdownPriceMultipliers.THERMOSTAT_MALFUNCTION,
                effects = {
                    { id = "THERMOSTAT_HEALTH_MODIFIER", value = -0.6, aggregation = "min"}
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_thermostat_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.THERMOSTAT_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.THERMOSTAT_MALFUNCTION,
                effects = {
                    { id = "THERMOSTAT_HEALTH_MODIFIER", value = -0.8, aggregation = "min"}
                },
                indicators = {
                    { id = db.COOLANT, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_thermostat_malfunction_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.THERMOSTAT_MALFUNCTION,
                effects = {
                    { id = "THERMOSTAT_STUCK_EFFECT", value = -1.0, aggregation = "min"}
                },
                indicators = {
                    { id = db.COOLANT, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    COOLANT_LEAK = {
        isSelectable = true,
        system = systems.COOLING,
        part = parts.COOLING_SYSTEM,
        isApplicable = function(vehicle)
            return not getIsElectricVehicle(vehicle)
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.COOLING, {"ohf"}, {"csf"})
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_coolant_leak_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.COOLANT_LEAK,
                repairPrice = 1.0 * breakdownPriceMultipliers.COOLANT_LEAK,
                effects = {
                    { id = "RADIATOR_HEALTH_MODIFIER", value = -0.1, aggregation = "min"}
                },
                inspection = {
                    { target = "coolant", status = "ads_inspection_status_slightly_low", additional = "ads_inspection_hint_coolant_leak_stage1" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_coolant_leak_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.COOLANT_LEAK,
                repairPrice = 2.0 * breakdownPriceMultipliers.COOLANT_LEAK,
                effects = {
                    { id = "RADIATOR_HEALTH_MODIFIER", value = -0.2, aggregation = "min"}
                },
                inspection = {
                    { target = "coolant", status = "ads_inspection_status_low", additional = "ads_inspection_hint_coolant_leak_stage2" },
                },
                indicators = {

                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_coolant_leak_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.COOLANT_LEAK,
                repairPrice = 4.0 * breakdownPriceMultipliers.COOLANT_LEAK,
                effects = {
                    { id = "RADIATOR_HEALTH_MODIFIER", value = -0.4, aggregation = "min"}
                },
                inspection = {
                    { target = "coolant", status = "ads_inspection_status_very_low", additional = "ads_inspection_hint_coolant_leak_stage3" },
                },
                indicators = {
                    { id = db.COOLANT, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_coolant_leak_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.COOLANT_LEAK,
                effects = {
                    { id = "RADIATOR_HEALTH_MODIFIER", value = -0.6, aggregation = "min"}
                },
                inspection = {
                    { target = "coolant", status = "ads_inspection_status_critically_low", additional = "ads_inspection_hint_coolant_leak_stage4" },
                },
                indicators = {
                    { id = db.COOLANT, color = color.CRITICAL, switchOn = true, switchOff = false },
                }
            }
        }
    },

    FAN_CLUTCH_FAILURE = {
        isSelectable = true,
        system = systems.COOLING,
        part = parts.FAN_CLUTCH,
        isApplicable = function(vehicle)
            return not getIsElectricVehicle(vehicle)
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.COOLING, {"hcf"}, {"ohf", "sf"})
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_fun_clutch_failure_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.FAN_CLUTCH_FAILURE,
                repairPrice = 1.0 * breakdownPriceMultipliers.FAN_CLUTCH_FAILURE,
                effects = {
                    { id = "FAN_CLUTCH_MODIFIER", value = -0.1, aggregation = "min"},
                    { id = "FAN_CLUTCH_NOISE_EFFECT", value = 0.6, aggregation = "max" }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_fun_clutch_failure_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.FAN_CLUTCH_FAILURE,
                repairPrice = 2.0 * breakdownPriceMultipliers.FAN_CLUTCH_FAILURE,
                effects = {
                    { id = "FAN_CLUTCH_MODIFIER", value = -0.2, aggregation = "min"},
                    { id = "FAN_CLUTCH_NOISE_EFFECT", value = 0.8, aggregation = "max" }
                },
                indicators = {
                    { id = db.COOLANT, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_fun_clutch_failure_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.FAN_CLUTCH_FAILURE,
                repairPrice = 4.0 * breakdownPriceMultipliers.FAN_CLUTCH_FAILURE,
                effects = {
                    { id = "FAN_CLUTCH_MODIFIER", value = -0.3, aggregation = "min"},
                    { id = "FAN_CLUTCH_NOISE_EFFECT", value = 1.0, aggregation = "max" }
                },
                indicators = {
                    { id = db.COOLANT, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_fun_clutch_failure_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.FAN_CLUTCH_FAILURE,
                effects = {
                    { id = "FAN_CLUTCH_MODIFIER", value = -0.5, aggregation = "min"},
                },
                indicators = {
                    { id = db.COOLANT, color = color.CRITICAL, switchOn = true, switchOff = false },
                }
            }
        }
    },

    -- fuel system
    FUEL_PUMP_MALFUNCTION = {
        isSelectable = true,
        system = systems.FUEL,
        part = parts.FUEL_PUMP,
        isApplicable = function(vehicle)
            return not getIsElectricVehicle(vehicle)
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.FUEL, {"lff"}, {"hpf", "idf", "sf"})
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_fuel_pump_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.FUEL_PUMP_MALFUNCTION,
                repairPrice = 1.0 * breakdownPriceMultipliers.FUEL_PUMP_MALFUNCTION,
                effects = {
                    { id = "IDLE_HUNTING_EFFECT", value = 0.05, aggregation = "max", extraData = { timer = 0, period = 1800, rpmBackup = 0} },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.05, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.15, aggregation = "sum" },
                    { id = "ENGINE_HARD_START_MODIFIER", value = 2, aggregation = "max", extraData = { timer = 0, status = 'IDLE'}},
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.3, aggregation = "max", extraData = {timer = 0, duration = 300, status = 'IDLE', amplitude = 0.6, motorLoad = 0.8, cruiseState = 0} }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_fuel_pump_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.FUEL_PUMP_MALFUNCTION,
                repairPrice = 2.0 * breakdownPriceMultipliers.FUEL_PUMP_MALFUNCTION,
                effects = {
                    { id = "IDLE_HUNTING_EFFECT", value = 0.08, aggregation = "max", extraData = { timer = 0, period = 1600, rpmBackup = 0} },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.12, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.4, aggregation = "sum" },
                    { id = "ENGINE_STALLS_CHANCE", value = 20.0, aggregation = "min" },
                    { id = "ENGINE_HARD_START_MODIFIER", value = 4, aggregation = "max", extraData = { timer = 0, status = 'IDLE'}},
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.2, aggregation = "max", extraData = {timer = 0, duration = 400, status = 'IDLE', amplitude = 1.0, motorLoad = 0.7, cruiseState = 0} }
                },
                indicators = {
                    {  
                        id = db.ENGINE,
                        color = color.WARNING,
                        switchOn = function(vehicle)
                            if vehicle.spec_motorized and vehicle:getIsMotorStarted() and vehicle:getMotorLoadPercentage() > 0.95 then
                                return true
                            end
                            return false
                        end,
                        switchOff = false
                    }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_fuel_pump_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.FUEL_PUMP_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.FUEL_PUMP_MALFUNCTION,
                effects = {
                    { id = "IDLE_HUNTING_EFFECT", value = 0.10, aggregation = "max", extraData = { timer = 0, period = 1500, rpmBackup = 0} }, 
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.25, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 1.0, aggregation = "sum" },
                    { id = "ENGINE_STALLS_CHANCE", value = 10.0, aggregation = "min" },
                    { id = "ENGINE_HARD_START_MODIFIER", value = 6, aggregation = "max", extraData = { timer = 0, status = 'IDLE'}},
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.15, aggregation = "max", extraData = {timer = 0, duration = 500, status = 'IDLE', amplitude = 1.0, motorLoad = 0.5, cruiseState = 0} }
                },
                indicators = {
                    { id = db.ENGINE, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_fuel_pump_malfunction_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.FUEL_PUMP_MALFUNCTION,
                effects = { 
                    { id = "ENGINE_FAILURE", value = 1.0, aggregation = "boolean_or", extraData = {starter = true, message = "ads_breakdowns_fuel_pump_malfunction_stage4_message", reason = "BREAKDOWN", disableAi = true} } 
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    FUEL_INJECTOR_MALFUNCTION = {
        isSelectable = true,
        system = systems.FUEL,
        part = parts.FUEL_INJECTORS,
        isApplicable = function(vehicle)
            return not getIsElectricVehicle(vehicle)
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.FUEL, {"idf", "hpf"}, {"cff"})
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_fuel_injector_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.FUEL_INJECTOR_MALFUNCTION,
                repairPrice = 1.0 * breakdownPriceMultipliers.FUEL_INJECTOR_MALFUNCTION,
                effects = {
                    { id = "IDLE_HUNTING_EFFECT", value = 0.05, aggregation = "max", extraData = { timer = 0, period = 1800, rpmBackup = 0} },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.08, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.10, aggregation = "sum" },
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.4, aggregation = "max", extraData = {timer = 0, duration = 300, status = 'IDLE', amplitude = 0.6, motorLoad = 0.9, cruiseState = 0} }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_fuel_injector_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.FUEL_INJECTOR_MALFUNCTION,
                repairPrice = 2.0 * breakdownPriceMultipliers.FUEL_INJECTOR_MALFUNCTION,
                effects = {
                    { id = "IDLE_HUNTING_EFFECT", value = 0.08, aggregation = "max", extraData = { timer = 0, period = 1500, rpmBackup = 0} },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.20, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.25, aggregation = "sum" },
                    { id = "ENGINE_STALLS_CHANCE", value = 30.0, aggregation = "min" },
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.3, aggregation = "max", extraData = {timer = 0, duration = 400, status = 'IDLE', amplitude = 0.8, motorLoad = 0.8, cruiseState = 0} }
                },
                indicators = {
                    { id = db.ENGINE, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_fuel_injector_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.FUEL_INJECTOR_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.FUEL_INJECTOR_MALFUNCTION,
                effects = {
                    { id = "IDLE_HUNTING_EFFECT", value = 0.10, aggregation = "max", extraData = { timer = 0, period = 1800, rpmBackup = 0} },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.35, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.50, aggregation = "sum" },
                    { id = "ENGINE_HARD_START_MODIFIER", value = 6, aggregation = "max", extraData = { timer = 0, status = 'IDLE'}},
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.2, aggregation = "max", extraData = {timer = 0, duration = 500, status = 'IDLE', amplitude = 1.0, motorLoad = 0.7, cruiseState = 0} }
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_fuel_injector_malfunction_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.FUEL_INJECTOR_MALFUNCTION,
                effects = {
                    { id = "ENGINE_FAILURE", value = 1.0, aggregation = "boolean_or", extraData = {starter = true, message = "ads_breakdowns_fuel_injector_malfunction_stage4_message", reason = "BREAKDOWN", disableAi = true} }
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    FUEL_FILTER_CLOGGING = {
        isSelectable = true,
        system = systems.FUEL,
        part = parts.FUEL_FILTER,
        isApplicable = function(vehicle)
            return not getIsElectricVehicle(vehicle)
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.FUEL, {"idf"}, {"cff", "sf"})
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_fuel_filter_clogging_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.FUEL_FILTER_CLOGGING,
                repairPrice = 1.0 * breakdownPriceMultipliers.FUEL_FILTER_CLOGGING,
                effects = {
                     { id = "ENGINE_HESITATION_CHANCE", value = 0.4, aggregation = "max", extraData = {timer = 0, duration = 300, status = 'IDLE', amplitude = 0.6, motorLoad = 0.9, cruiseState = 0} },
                     { id = "ENGINE_TORQUE_MODIFIER", value = -0.03, aggregation = "sum" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_fuel_filter_clogging_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.FUEL_FILTER_CLOGGING,
                repairPrice = 2.0 * breakdownPriceMultipliers.FUEL_FILTER_CLOGGING,
                effects = {
                     { id = "ENGINE_HESITATION_CHANCE", value = 0.3, aggregation = "max", extraData = {timer = 0, duration = 400, status = 'IDLE', amplitude = 0.7, motorLoad = 0.9, cruiseState = 0} },
                     { id = "ENGINE_TORQUE_MODIFIER", value = -0.06, aggregation = "sum" },
                     { id = "ENGINE_STALLS_CHANCE", value = 30.0, aggregation = "min" },
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_fuel_filter_clogging_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.FUEL_FILTER_CLOGGING,
                repairPrice = 4.0 * breakdownPriceMultipliers.FUEL_FILTER_CLOGGING,
                effects = { 
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.2, aggregation = "max", extraData = {timer = 0, duration = 500, status = 'IDLE', amplitude = 0.7, motorLoad = 0.9, cruiseState = 0} },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.1, aggregation = "sum" },
                    { id = "ENGINE_STALLS_CHANCE", value = 20.0, aggregation = "min" },
                } 
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_fuel_filter_clogging_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.FUEL_FILTER_CLOGGING,
                effects = {
                    { id = "ENGINE_FAILURE", value = 1.0, aggregation = "boolean_or", extraData = {starter = true, message = "ads_breakdowns_fuel_filter_clogging_stage4_message", reason = "BREAKDOWN", disableAi = true} }
                }
            }
        }
    },

    FUEL_LINE_AIR_LEAK = {
        isSelectable = true,
        system = systems.FUEL,
        part = parts.FUEL_LINE,
        isApplicable = function(vehicle)
            return not getIsElectricVehicle(vehicle)
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.FUEL, {"lff"}, {"sf"})
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_fuel_line_air_leak_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.FUEL_LINE_AIR_LEAK,
                repairPrice = 1.0 * breakdownPriceMultipliers.FUEL_LINE_AIR_LEAK,
                effects = {
                    { id = "ENGINE_HARD_START_MODIFIER", value = 1, aggregation = "max", extraData = { timer = 0, status = 'IDLE', count = 0}}
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_fuel_line_air_leak_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.FUEL_LINE_AIR_LEAK,
                repairPrice = 2.0 * breakdownPriceMultipliers.FUEL_LINE_AIR_LEAK,
                effects = {
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.3, aggregation = "max", extraData = {timer = 0, duration = 300, status = 'IDLE', amplitude = 0.6, motorLoad = 0.5, cruiseState = 0} },
                    { id = "ENGINE_HARD_START_MODIFIER", value = 2, aggregation = "max", extraData = { timer = 0, status = 'IDLE', count = 0}},
                    { id = "ENGINE_STALLS_CHANCE", value = 20.0, aggregation = "min" },
                    
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_fuel_line_air_leak_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.FUEL_LINE_AIR_LEAK,
                repairPrice = 4.0 * breakdownPriceMultipliers.FUEL_LINE_AIR_LEAK,
                effects = {
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.2, aggregation = "max", extraData = {timer = 0, duration = 500, status = 'IDLE', amplitude = 0.7, motorLoad = 0.5, cruiseState = 0} },
                    { id = "ENGINE_HARD_START_MODIFIER", value = 3, aggregation = "max", extraData = {timer = 0, status = 'IDLE'}},
                    { id = "ENGINE_STALLS_CHANCE", value = 10.0, aggregation = "min" },
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_fuel_line_air_leak_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.FUEL_LINE_AIR_LEAK,
                effects = {
                    { id = "ENGINE_FAILURE", value = 1.0, aggregation = "boolean_or", extraData = {starter = true, message = "ads_breakdowns_fuel_line_air_leak_stage4_message", reason = "BREAKDOWN", disableAi = true}}
                }
            }
        }
    },

    -- workprocess system
    HARVEST_PROCESSING_SYSTEM_WEAR  = {
        isSelectable = true,
        system = systems.WORKPROCESS,
        part = parts.HARVEST_PROCESSING_SYSTEM,
        isApplicable = function(vehicle)
            local vtype = vehicle.type.name
            if  vtype == 'combineDrivable' or
                vtype == 'combineCutter' or
                vtype == 'combineCutterFruitPreparer' or
                vtype == 'cottonHarvester' or
                vtype == 'riceHarvester' or
                vtype == 'vineHarvester' then
                    return true
            end
            return false
        end,
        probability = function(vehicle)
            local weight = getBreakdownProbabilityWeightPercent(vehicle, systems.WORKPROCESS, {"lhf", "lubf"}, {"wcf", "sf"})
            if vehicle.getIsTurnedOn ~= nil and vehicle:getIsTurnedOn() then
                return weight * 1.5
            end
            return weight
        end,
        isCanProgress = function(vehicle)
            if vehicle.getIsTurnedOn ~= nil and vehicle:getIsTurnedOn() then
                return true
            else
                return false
            end
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_harvest_processing_system_wear_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.HARVEST_PROCESSING_SYSTEM_WEAR,
                repairPrice = 1.0 * breakdownPriceMultipliers.HARVEST_PROCESSING_SYSTEM_WEAR,
                effects = {
                    { id = "YIELD_REDUCTION_MODIFIER", value = -0.05, aggregation = "sum" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_harvest_processing_system_wear_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.HARVEST_PROCESSING_SYSTEM_WEAR,
                repairPrice = 2.0 * breakdownPriceMultipliers.HARVEST_PROCESSING_SYSTEM_WEAR,
                effects = {
                    { id = "YIELD_REDUCTION_MODIFIER", value = -0.1, aggregation = "sum" },
                },
                indicators = {
                    {  id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_harvest_processing_system_wear_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.HARVEST_PROCESSING_SYSTEM_WEAR,
                repairPrice = 4.0 * breakdownPriceMultipliers.HARVEST_PROCESSING_SYSTEM_WEAR,
                effects = { 
                    { id = "YIELD_REDUCTION_MODIFIER", value = -0.2, aggregation = "sum" },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_harvest_processing_system_wear_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.HARVEST_PROCESSING_SYSTEM_WEAR,
                effects = { 
                    { id = "YIELD_REDUCTION_MODIFIER", value = -0.4, aggregation = "sum", extraData = {message = 'ads_breakdowns_harvest_processing_system_wear_stage4_message', disableAi = true} },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    UNLOADING_AUGER_MALFUNCTION = {
        isSelectable = true,
        system = systems.WORKPROCESS,
        part = parts.UNLOADING_AUGER,
        isApplicable = function(vehicle)
            local vtype = vehicle.type.name
            return (vtype == 'combineDrivable' or vtype == 'combineCutter') and vehicle.spec_pipe ~= nil
        end,
        probability = function(vehicle)
            local weight = getBreakdownProbabilityWeightPercent(vehicle, systems.WORKPROCESS, {"lhf"}, {"lubf", "wcf", "sf"})
            if vehicle.getIsTurnedOn ~= nil and vehicle:getIsTurnedOn() then
                if vehicle.spec_dischargeable.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF then
                    return weight * 2.0
                end
                return weight * 1.25
            end
            return weight
        end,
        isCanProgress = function(vehicle)
            if vehicle.getIsTurnedOn ~= nil and vehicle:getIsTurnedOn() then
                return true
            else
                return false
            end
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_unloading_auger_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.UNLOADING_AUGER_MALFUNCTION,
                repairPrice = 1.0 * breakdownPriceMultipliers.UNLOADING_AUGER_MALFUNCTION,
                effects = {
                    { id = "UNLOADING_SPEED_MODIFIER", value = -0.50, aggregation = "min" }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_unloading_auger_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.UNLOADING_AUGER_MALFUNCTION,
                repairPrice = 2.0 * breakdownPriceMultipliers.UNLOADING_AUGER_MALFUNCTION,
                effects = {
                    { id = "UNLOADING_SPEED_MODIFIER", value = -0.75, aggregation = "min" }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_unloading_auger_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.UNLOADING_AUGER_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.UNLOADING_AUGER_MALFUNCTION,
                effects = { 
                    { id = "UNLOADING_SPEED_MODIFIER", value = -0.90, aggregation = "min" }
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_unloading_auger_malfunction_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.UNLOADING_AUGER_MALFUNCTION,
                effects = { 
                     { id = "UNLOADING_AUGER_FAILURE", value = 1.0, aggregation = "boolean_or", extraData = {message = "ads_breakdowns_unloading_auger_malfunction_stage4_message"} }
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false },
                }
            }
        }
    },

    -- ======================================================================
    --                      EXTENDED BREAKDOWN SET
    -- ======================================================================

    -- engine: glow plugs (filed under electrical - they are a 12V heater circuit)
    GLOW_PLUG_FAILURE = {
        isSelectable = true,
        system = systems.ELECTRICAL,
        part = parts.GLOW_PLUGS,
        isApplicable = function(vehicle)
            return hasCombustionEngine(vehicle)
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.ELECTRICAL, {"crf"}, {"wef", "sf"})
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_glow_plug_failure_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.GLOW_PLUG_FAILURE,
                repairPrice = 1.0 * breakdownPriceMultipliers.GLOW_PLUG_FAILURE,
                effects = {
                    { id = "ENGINE_HARD_START_MODIFIER", value = 1, aggregation = "max", extraData = { timer = 0, status = 'IDLE'} },
                    { id = "GLOW_PLUG_COLD_START_EFFECT", value = 4, aggregation = "max" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_glow_plug_failure_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.GLOW_PLUG_FAILURE,
                repairPrice = 2.0 * breakdownPriceMultipliers.GLOW_PLUG_FAILURE,
                effects = {
                    { id = "ENGINE_HARD_START_MODIFIER", value = 1, aggregation = "max", extraData = { timer = 0, status = 'IDLE'} },
                    { id = "GLOW_PLUG_COLD_START_EFFECT", value = 10, aggregation = "max" },
                },
                indicators = {
                    { id = db.ENGINE, color = color.WARNING, switchOn = engineIsColdForGlowPlugs, switchOff = engineIsWarmForGlowPlugs }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_glow_plug_failure_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.GLOW_PLUG_FAILURE,
                repairPrice = 4.0 * breakdownPriceMultipliers.GLOW_PLUG_FAILURE,
                effects = {
                    { id = "ENGINE_HARD_START_MODIFIER", value = 2, aggregation = "max", extraData = { timer = 0, status = 'IDLE'} },
                    { id = "GLOW_PLUG_COLD_START_EFFECT", value = 25, aggregation = "max" },
                    { id = "IDLE_HUNTING_EFFECT", value = 0.04, aggregation = "max", extraData = { timer = 0, period = 1800, rpmBackup = 0} },
                },
                inspection = {
                    { additional = "ads_inspection_hint_glow_plug_failure_stage3" },
                },
                indicators = {
                    { id = db.ENGINE, color = color.WARNING, switchOn = engineIsColdForGlowPlugs, switchOff = engineIsWarmForGlowPlugs }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_glow_plug_failure_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.GLOW_PLUG_FAILURE,
                effects = {
                    { id = "ENGINE_HARD_START_MODIFIER", value = 3, aggregation = "max", extraData = { timer = 0, status = 'IDLE'} },
                    { id = "GLOW_PLUG_COLD_START_EFFECT", value = 60, aggregation = "max", extraData = { message = "ads_breakdowns_glow_plug_failure_stage4_message" } },
                    { id = "IDLE_HUNTING_EFFECT", value = 0.06, aggregation = "max", extraData = { timer = 0, period = 1600, rpmBackup = 0} },
                },
                inspection = {
                    { additional = "ads_inspection_hint_glow_plug_failure_stage4" },
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = engineIsColdForGlowPlugs, switchOff = engineIsWarmForGlowPlugs }
                }
            }
        }
    },

    -- engine: head gasket
    HEAD_GASKET_FAILURE = {
        isSelectable = true,
        system = systems.ENGINE,
        part = parts.HEAD_GASKET,
        isApplicable = function(vehicle)
            return hasCombustionEngine(vehicle)
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.ENGINE, {"hmf"}, {"cmf", "sf"})
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_head_gasket_failure_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.HEAD_GASKET_FAILURE,
                repairPrice = 1.0 * breakdownPriceMultipliers.HEAD_GASKET_FAILURE,
                effects = {
                    { id = "ENGINE_HEAT_MODIFIER", value = 0.05, aggregation = "sum" },
                    { id = "RADIATOR_HEALTH_MODIFIER", value = -0.05, aggregation = "min" },
                },
                inspection = {
                    { target = "coolant", status = "ads_inspection_status_slightly_low", additional = "ads_inspection_hint_head_gasket_failure_stage1" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_head_gasket_failure_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.HEAD_GASKET_FAILURE,
                repairPrice = 2.0 * breakdownPriceMultipliers.HEAD_GASKET_FAILURE,
                effects = {
                    { id = "ENGINE_HEAT_MODIFIER", value = 0.12, aggregation = "sum" },
                    { id = "RADIATOR_HEALTH_MODIFIER", value = -0.15, aggregation = "min" },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.05, aggregation = "sum" },
                    { id = "IDLE_HUNTING_EFFECT", value = 0.04, aggregation = "max", extraData = { timer = 0, period = 1800, rpmBackup = 0} },
                },
                inspection = {
                    { target = "coolant", status = "ads_inspection_status_low", additional = "ads_inspection_hint_head_gasket_failure_stage2" },
                    { target = "engineOil", status = "ads_inspection_status_slightly_darkened" },
                },
                indicators = {
                    { id = db.COOLANT, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_head_gasket_failure_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.HEAD_GASKET_FAILURE,
                repairPrice = 4.0 * breakdownPriceMultipliers.HEAD_GASKET_FAILURE,
                effects = {
                    { id = "ENGINE_HEAT_MODIFIER", value = 0.25, aggregation = "sum" },
                    { id = "RADIATOR_HEALTH_MODIFIER", value = -0.30, aggregation = "min" },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.15, aggregation = "sum" },
                    { id = "ENGINE_STALLS_CHANCE", value = 20.0, aggregation = "min" },
                    { id = "ENGINE_HARD_START_MODIFIER", value = 3, aggregation = "max", extraData = { timer = 0, status = 'IDLE'} },
                },
                inspection = {
                    { target = "coolant", status = "ads_inspection_status_very_low", additional = "ads_inspection_hint_head_gasket_failure_stage3" },
                    { target = "engineOil", status = "ads_inspection_status_contaminated" },
                },
                indicators = {
                    { id = db.COOLANT, color = color.CRITICAL, switchOn = true, switchOff = false },
                    { id = db.ENGINE, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_head_gasket_failure_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.HEAD_GASKET_FAILURE,
                effects = {
                    { id = "ENGINE_FAILURE", value = 1.0, aggregation = "boolean_or", extraData = {starter = true, message = "ads_breakdowns_head_gasket_failure_stage4_message", reason = "BREAKDOWN", disableAi = true} },
                },
                inspection = {
                    { target = "coolant", status = "ads_inspection_status_critically_low", additional = "ads_inspection_hint_head_gasket_failure_stage4" },
                    { target = "engineOil", status = "ads_inspection_status_critical_condition" },
                },
                indicators = {
                    { id = db.COOLANT, color = color.CRITICAL, switchOn = true, switchOff = false },
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- engine: diesel particulate filter
    DPF_CLOGGING = {
        isSelectable = true,
        system = systems.ENGINE,
        part = parts.DPF,
        isApplicable = function(vehicle)
            return hasCombustionEngine(vehicle) and getVehicleYear(vehicle) >= 2011
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.ENGINE, {"cmf"}, {"sf", "mlf"})
        end,
        isCanProgress = function(vehicle)
            return vehicle:getIsMotorStarted()
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_dpf_clogging_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.DPF_CLOGGING,
                repairPrice = 1.0 * breakdownPriceMultipliers.DPF_CLOGGING,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.04, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.05, aggregation = "sum" },
                    { id = "DPF_PASSIVE_REGEN_EFFECT", value = 1.0, aggregation = "max", extraData = { breakdownId = "DPF_CLOGGING", regenMs = 600000, minLoad = 0.55 } },
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_dpf_clogging_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.DPF_CLOGGING,
                repairPrice = 2.0 * breakdownPriceMultipliers.DPF_CLOGGING,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.10, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.10, aggregation = "sum" },
                    { id = "DARK_EXHAUST_EFFECT", value = 0.30, aggregation = "max" },
                    { id = "DPF_PASSIVE_REGEN_EFFECT", value = 1.0, aggregation = "max", extraData = { breakdownId = "DPF_CLOGGING", regenMs = 1200000, minLoad = 0.60 } },
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_dpf_clogging_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.DPF_CLOGGING,
                repairPrice = 4.0 * breakdownPriceMultipliers.DPF_CLOGGING,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.15, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.15, aggregation = "sum" },
                    { id = "DARK_EXHAUST_EFFECT", value = 0.50, aggregation = "max" },
                    { id = "ENGINE_LIMP_EFFECT", value = -0.25, aggregation = "min", extraData = { reason = "BREAKDOWN", message = "ads_breakdowns_dpf_clogging_stage3_message" } },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false },
                    { id = db.ENGINE, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_dpf_clogging_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.DPF_CLOGGING,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.30, aggregation = "sum" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.50, aggregation = "max" },
                    { id = "DARK_EXHAUST_EFFECT", value = 0.80, aggregation = "max" },
                    { id = "ENGINE_LIMP_EFFECT", value = -0.50, aggregation = "min", extraData = { reason = "BREAKDOWN", message = "ads_breakdowns_dpf_clogging_stage4_message", disableAi = true } },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false },
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- fuel: DEF / AdBlue (SCR) system
    DEF_SYSTEM_FAULT = {
        isSelectable = true,
        system = systems.FUEL,
        part = parts.DEF_SYSTEM,
        isApplicable = function(vehicle)
            -- only machines that actually carry a DEF tank have an SCR system that can fail
            return hasCombustionEngine(vehicle) and getDefTankState(vehicle) ~= nil
        end,
        probability = function(vehicle)
            local weight = getBreakdownProbabilityWeightPercent(vehicle, systems.FUEL, {"cff"}, {"idf", "sf"})
            -- running the DEF tank dry is hard on the dosing pump
            local spec = vehicle.spec_AdvancedDamageSystem
            local dryRunHours = spec ~= nil and (tonumber(spec.defDryRunTotalMs) or 0) / 3600000 or 0
            return weight * (1 + math.min(dryRunHours, 1) * 2)
        end,
        isCanProgress = function(vehicle)
            return vehicle:getIsMotorStarted()
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_def_system_fault_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.DEF_SYSTEM_FAULT,
                repairPrice = 1.0 * breakdownPriceMultipliers.DEF_SYSTEM_FAULT,
                effects = {
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.03, aggregation = "sum" },
                },
                indicators = {
                    { id = db.ENGINE, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_def_system_fault_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.DEF_SYSTEM_FAULT,
                repairPrice = 2.0 * breakdownPriceMultipliers.DEF_SYSTEM_FAULT,
                effects = {
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.05, aggregation = "sum" },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.10, aggregation = "sum" },
                },
                indicators = {
                    { id = db.ENGINE, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_def_system_fault_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.DEF_SYSTEM_FAULT,
                repairPrice = 4.0 * breakdownPriceMultipliers.DEF_SYSTEM_FAULT,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.25, aggregation = "sum" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.25, aggregation = "max" },
                    { id = "ENGINE_LIMP_EFFECT", value = -0.25, aggregation = "min", extraData = { reason = "BREAKDOWN", message = "ads_breakdowns_def_system_fault_stage3_message" } },
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_def_system_fault_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.DEF_SYSTEM_FAULT,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.50, aggregation = "sum" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.60, aggregation = "max" },
                    { id = "ENGINE_LIMP_EFFECT", value = -0.50, aggregation = "min", extraData = { reason = "BREAKDOWN", message = "ads_breakdowns_def_system_fault_stage4_message", disableAi = true } },
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false },
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- fuel: DEF tank run dry. Not a part failure and not repairable in the workshop:
    -- managed by syncDefTankEmpty() in ADS_Specialization.lua and cleared by refilling DEF.
    DEF_TANK_EMPTY = {
        isSelectable = false,
        system = systems.FUEL,
        part = parts.DEF_SYSTEM,
        isApplicable = function(vehicle)
            return getDefTankState(vehicle) ~= nil
        end,
        probability = function(vehicle)
            return 0.0
        end,
        isCanProgress = function(vehicle)
            return false
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_def_tank_empty_stage1_description",
                detectionChance = 0.0,
                progressMultiplier = 0.0,
                repairPrice = 0.0,
                effects = {
                    { id = "EMPTY_EFFECT", value = 1.0, aggregation = "boolean_or", extraData = { message = "ads_breakdowns_def_tank_empty_stage1_message" } },
                },
                indicators = {
                    { id = db.ENGINE, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_reduce_power",
                description = "ads_breakdowns_def_tank_empty_stage2_description",
                detectionChance = 0.0,
                progressMultiplier = 0.0,
                repairPrice = 0.0,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.25, aggregation = "sum" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.25, aggregation = "max" },
                    { id = "ENGINE_LIMP_EFFECT", value = -0.25, aggregation = "min", extraData = { reason = "BREAKDOWN", message = "ads_breakdowns_def_tank_empty_stage2_message" } },
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_reduce_power",
                description = "ads_breakdowns_def_tank_empty_stage3_description",
                detectionChance = 0.0,
                progressMultiplier = 0.0,
                repairPrice = 0.0,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.50, aggregation = "sum" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.60, aggregation = "max" },
                    { id = "ENGINE_LIMP_EFFECT", value = -0.50, aggregation = "min", extraData = { reason = "BREAKDOWN", message = "ads_breakdowns_def_tank_empty_stage3_message", disableAi = true } },
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false },
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- workprocess: chipper knives. Not random: driven by chipped volume in
    -- syncChipperKnifeWear() (ADS_Specialization.lua). Repairing it = changing the knives,
    -- which resets the knife counter. Critical stage locks the chipper out.
    CHIPPER_KNIFE_WEAR = {
        isSelectable = true,
        system = systems.WORKPROCESS,
        part = parts.CHIPPER_KNIVES,
        isApplicable = function(vehicle)
            return vehicle.spec_woodCrusher ~= nil
        end,
        probability = function(vehicle)
            return 0.0
        end,
        isCanProgress = function(vehicle)
            return false
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_chipper_knife_wear_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 0.0,
                repairPrice = 0.4,
                effects = {
                    { id = "CHIPPER_KNIFE_DULL_EFFECT", value = 0.10, aggregation = "max" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.05, aggregation = "sum" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_chipper_knife_wear_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 0.0,
                repairPrice = 0.5,
                effects = {
                    { id = "CHIPPER_KNIFE_DULL_EFFECT", value = 0.25, aggregation = "max" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.10, aggregation = "sum" },
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_chipper_knife_wear_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.0,
                repairPrice = 0.6,
                effects = {
                    { id = "CHIPPER_KNIFE_DULL_EFFECT", value = 0.45, aggregation = "max", extraData = { message = "ads_breakdowns_chipper_knife_wear_stage3_message" } },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.20, aggregation = "sum" },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_chipper_knife_wear_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0.0,
                repairPrice = 0.8,
                effects = {
                    { id = "CHIPPER_KNIFE_DULL_EFFECT", value = 1.0, aggregation = "max", extraData = { message = "ads_breakdowns_chipper_knife_wear_stage4_message", disableAi = true } },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- fuel: water in fuel / saturated water separator
    WATER_IN_FUEL = {
        isSelectable = true,
        system = systems.FUEL,
        part = parts.WATER_SEPARATOR,
        isApplicable = function(vehicle)
            return hasCombustionEngine(vehicle)
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.FUEL, {"cff", "lff"}, {"sf"})
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_water_in_fuel_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.WATER_IN_FUEL,
                repairPrice = 1.0 * breakdownPriceMultipliers.WATER_IN_FUEL,
                effects = {
                    { id = "IDLE_HUNTING_EFFECT", value = 0.04, aggregation = "max", extraData = { timer = 0, period = 1800, rpmBackup = 0} },
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.5, aggregation = "max", extraData = {timer = 0, duration = 250, status = 'IDLE', amplitude = 0.5, motorLoad = 0.6, cruiseState = 0} },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_water_in_fuel_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.WATER_IN_FUEL,
                repairPrice = 2.0 * breakdownPriceMultipliers.WATER_IN_FUEL,
                effects = {
                    { id = "IDLE_HUNTING_EFFECT", value = 0.07, aggregation = "max", extraData = { timer = 0, period = 1600, rpmBackup = 0} },
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.3, aggregation = "max", extraData = {timer = 0, duration = 350, status = 'IDLE', amplitude = 0.7, motorLoad = 0.5, cruiseState = 0} },
                    { id = "ENGINE_STALLS_CHANCE", value = 30.0, aggregation = "min" },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.05, aggregation = "sum" },
                    { id = "ENGINE_HARD_START_MODIFIER", value = 2, aggregation = "max", extraData = { timer = 0, status = 'IDLE'} },
                },
                inspection = {
                    { additional = "ads_inspection_hint_water_in_fuel_stage2" },
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_water_in_fuel_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.WATER_IN_FUEL,
                repairPrice = 4.0 * breakdownPriceMultipliers.WATER_IN_FUEL,
                effects = {
                    { id = "IDLE_HUNTING_EFFECT", value = 0.10, aggregation = "max", extraData = { timer = 0, period = 1500, rpmBackup = 0} },
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.2, aggregation = "max", extraData = {timer = 0, duration = 500, status = 'IDLE', amplitude = 1.0, motorLoad = 0.4, cruiseState = 0} },
                    { id = "ENGINE_STALLS_CHANCE", value = 15.0, aggregation = "min" },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.12, aggregation = "sum" },
                    { id = "ENGINE_HARD_START_MODIFIER", value = 4, aggregation = "max", extraData = { timer = 0, status = 'IDLE'} },
                },
                inspection = {
                    { additional = "ads_inspection_hint_water_in_fuel_stage3" },
                },
                indicators = {
                    { id = db.ENGINE, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_water_in_fuel_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.WATER_IN_FUEL,
                effects = {
                    { id = "ENGINE_FAILURE", value = 1.0, aggregation = "boolean_or", extraData = {starter = true, message = "ads_breakdowns_water_in_fuel_stage4_message", reason = "BREAKDOWN", disableAi = true} },
                },
                inspection = {
                    { additional = "ads_inspection_hint_water_in_fuel_stage4" },
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- cooling: serpentine / fan belt (drives fan, water pump and alternator)
    SERPENTINE_BELT_FAILURE = {
        isSelectable = true,
        system = systems.COOLING,
        part = parts.SERPENTINE_BELT,
        isApplicable = function(vehicle)
            return hasCombustionEngine(vehicle)
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.COOLING, {"hcf"}, {"csf", "sf"})
        end,
        isCanProgress = function(vehicle)
            return vehicle:getIsMotorStarted()
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_serpentine_belt_failure_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.SERPENTINE_BELT_FAILURE,
                repairPrice = 1.0 * breakdownPriceMultipliers.SERPENTINE_BELT_FAILURE,
                effects = {
                    { id = "FAN_CLUTCH_NOISE_EFFECT", value = 0.4, aggregation = "max" },
                    { id = "ALTERNATOR_HEALTH_MODIFIER", value = -0.10, aggregation = "min" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_serpentine_belt_failure_stage1" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_serpentine_belt_failure_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.SERPENTINE_BELT_FAILURE,
                repairPrice = 2.0 * breakdownPriceMultipliers.SERPENTINE_BELT_FAILURE,
                effects = {
                    { id = "FAN_CLUTCH_NOISE_EFFECT", value = 0.7, aggregation = "max" },
                    { id = "FAN_CLUTCH_MODIFIER", value = -0.10, aggregation = "min" },
                    { id = "ALTERNATOR_HEALTH_MODIFIER", value = -0.30, aggregation = "min" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_serpentine_belt_failure_stage2" },
                },
                indicators = {
                    { id = db.BATTERY, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_serpentine_belt_failure_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.SERPENTINE_BELT_FAILURE,
                repairPrice = 4.0 * breakdownPriceMultipliers.SERPENTINE_BELT_FAILURE,
                effects = {
                    { id = "FAN_CLUTCH_NOISE_EFFECT", value = 1.0, aggregation = "max" },
                    { id = "FAN_CLUTCH_MODIFIER", value = -0.25, aggregation = "min" },
                    { id = "ALTERNATOR_HEALTH_MODIFIER", value = -0.60, aggregation = "min" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_serpentine_belt_failure_stage3" },
                },
                indicators = {
                    { id = db.BATTERY, color = color.CRITICAL, switchOn = true, switchOff = false },
                    { id = db.COOLANT, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_serpentine_belt_failure_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.SERPENTINE_BELT_FAILURE,
                effects = {
                    { id = "FAN_CLUTCH_MODIFIER", value = -0.60, aggregation = "min", extraData = { message = "ads_breakdowns_serpentine_belt_failure_stage4_message" } },
                    { id = "ALTERNATOR_HEALTH_MODIFIER", value = -1.0, aggregation = "min" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_serpentine_belt_failure_stage4" },
                },
                indicators = {
                    { id = db.BATTERY, color = color.CRITICAL, switchOn = true, switchOff = false },
                    { id = db.COOLANT, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- transmission: diff-lock actuator stuck engaged
    DIFF_LOCK_ACTUATOR_STUCK = {
        isSelectable = true,
        system = systems.TRANSMISSION,
        part = parts.DIFF_LOCK_ACTUATOR,
        isApplicable = function(vehicle)
            return hasWheelsWithoutTracks(vehicle) and not isCarLikeVehicle(vehicle) and vehicle.getMotor ~= nil and vehicle:getMotor() ~= nil
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.TRANSMISSION, {"wsf"}, {"pof", "sf"})
        end,
        isCanProgress = function(vehicle)
            return vehicle:getLastSpeed() > 0.01
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_diff_lock_actuator_stuck_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.DIFF_LOCK_ACTUATOR_STUCK,
                repairPrice = 1.0 * breakdownPriceMultipliers.DIFF_LOCK_ACTUATOR_STUCK,
                effects = {
                    { id = "STEERING_SENSITIVITY_MODIFIER", value = 0.08, aggregation = "max" },
                    { id = "VIBRATION_NOISE_EFFECT", value = 0.5, aggregation = "max" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_diff_lock_actuator_stuck_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.DIFF_LOCK_ACTUATOR_STUCK,
                repairPrice = 2.0 * breakdownPriceMultipliers.DIFF_LOCK_ACTUATOR_STUCK,
                effects = {
                    { id = "STEERING_SENSITIVITY_MODIFIER", value = 0.18, aggregation = "max" },
                    { id = "VIBRATION_NOISE_EFFECT", value = 1.0, aggregation = "max" },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.03, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.05, aggregation = "sum" },
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_diff_lock_actuator_stuck_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.DIFF_LOCK_ACTUATOR_STUCK,
                repairPrice = 4.0 * breakdownPriceMultipliers.DIFF_LOCK_ACTUATOR_STUCK,
                effects = {
                    { id = "STEERING_SENSITIVITY_MODIFIER", value = 0.30, aggregation = "max" },
                    { id = "VIBRATION_NOISE_EFFECT", value = 1.5, aggregation = "max" },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.06, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.10, aggregation = "sum" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.10, aggregation = "max" },
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_diff_lock_actuator_stuck_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.DIFF_LOCK_ACTUATOR_STUCK,
                effects = {
                    { id = "STEERING_SENSITIVITY_MODIFIER", value = 0.45, aggregation = "max", extraData = { message = "ads_breakdowns_diff_lock_actuator_stuck_stage4_message" } },
                    { id = "VIBRATION_NOISE_EFFECT", value = 2.0, aggregation = "max" },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.10, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.15, aggregation = "sum" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.30, aggregation = "max" },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- transmission: shift solenoid / range valve fault (geared transmissions only)
    TRANSMISSION_SOLENOID_FAULT = {
        isSelectable = true,
        system = systems.TRANSMISSION,
        part = parts.TRANSMISSION_SOLENOID,
        isApplicable = function(vehicle)
            return hasGearedTransmission(vehicle) and getVehicleYear(vehicle) >= 1990
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.TRANSMISSION, {"hotf"}, {"lf", "sf"})
        end,
        isCanProgress = function(vehicle)
            return vehicle:getLastSpeed() > 0.01
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_transmission_solenoid_fault_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.TRANSMISSION_SOLENOID_FAULT,
                repairPrice = 1.0 * breakdownPriceMultipliers.TRANSMISSION_SOLENOID_FAULT,
                effects = {
                    { id = "GEAR_REJECTION_CHANCE", value = 25.0, extraData = {timer = 0, status = 'IDLE', duration = 1500 }, aggregation = "min" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_transmission_solenoid_fault_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.TRANSMISSION_SOLENOID_FAULT,
                repairPrice = 2.0 * breakdownPriceMultipliers.TRANSMISSION_SOLENOID_FAULT,
                effects = {
                    { id = "GEAR_REJECTION_CHANCE", value = 12.0, extraData = {timer = 0, status = 'IDLE', duration = 1800 }, aggregation = "min" },
                    { id = "GEAR_SHIFT_FAILURE_CHANCE", value = 0.10, extraData = {timer = 0, status = 'IDLE', duration = 1500}, aggregation = "max" },
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_transmission_solenoid_fault_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.TRANSMISSION_SOLENOID_FAULT,
                repairPrice = 4.0 * breakdownPriceMultipliers.TRANSMISSION_SOLENOID_FAULT,
                effects = {
                    { id = "GEAR_REJECTION_CHANCE", value = 5.0, extraData = {timer = 0, status = 'IDLE', duration = 2000 }, aggregation = "min" },
                    { id = "GEAR_SHIFT_FAILURE_CHANCE", value = 0.30, extraData = {timer = 0, status = 'IDLE', duration = 2000}, aggregation = "max" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.15, aggregation = "max" },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_transmission_solenoid_fault_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.TRANSMISSION_SOLENOID_FAULT,
                effects = {
                    { id = "MAX_SPEED_MODIFIER", value = 0.60, aggregation = "max", extraData = { message = "ads_breakdowns_transmission_solenoid_fault_stage4_message" } },
                    { id = "GEAR_REJECTION_CHANCE", value = 2.0, extraData = {timer = 0, status = 'IDLE', duration = 2000 }, aggregation = "min" },
                    { id = "GEAR_SHIFT_FAILURE_CHANCE", value = 0.60, extraData = {timer = 0, status = 'IDLE', duration = 2200}, aggregation = "max" },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- hydraulics: power steering pump
    POWER_STEERING_PUMP_FAILURE = {
        isSelectable = true,
        system = systems.HYDRAULICS,
        part = parts.POWER_STEERING_PUMP,
        isApplicable = function(vehicle)
            local vtype = vehicle.type ~= nil and vehicle.type.name or ""
            return hasWheelsWithoutTracks(vehicle) and vtype ~= "motorbike" and getVehicleYear(vehicle) >= 1960
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.HYDRAULICS, {"of"}, {"cof", "sf"})
        end,
        isCanProgress = function(vehicle)
            return vehicle:getIsMotorStarted()
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_power_steering_pump_failure_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.POWER_STEERING_PUMP_FAILURE,
                repairPrice = 1.0 * breakdownPriceMultipliers.POWER_STEERING_PUMP_FAILURE,
                effects = {
                    { id = "STEERING_SENSITIVITY_MODIFIER", value = 0.10, aggregation = "max" },
                },
                inspection = {
                    { target = "hydraulicFluid", status = "ads_inspection_status_slightly_darkened" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_power_steering_pump_failure_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.POWER_STEERING_PUMP_FAILURE,
                repairPrice = 2.0 * breakdownPriceMultipliers.POWER_STEERING_PUMP_FAILURE,
                effects = {
                    { id = "STEERING_SENSITIVITY_MODIFIER", value = 0.25, aggregation = "max" },
                },
                inspection = {
                    { target = "hydraulicFluid", status = "ads_inspection_status_darkened", additional = "ads_inspection_hint_power_steering_pump_failure_stage2" },
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_power_steering_pump_failure_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.POWER_STEERING_PUMP_FAILURE,
                repairPrice = 4.0 * breakdownPriceMultipliers.POWER_STEERING_PUMP_FAILURE,
                effects = {
                    { id = "STEERING_SENSITIVITY_MODIFIER", value = 0.45, aggregation = "max" },
                },
                inspection = {
                    { target = "hydraulicFluid", status = "ads_inspection_status_contaminated", additional = "ads_inspection_hint_power_steering_pump_failure_stage3" },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_power_steering_pump_failure_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.POWER_STEERING_PUMP_FAILURE,
                effects = {
                    { id = "STEERING_SENSITIVITY_MODIFIER", value = 0.75, aggregation = "max", extraData = { message = "ads_breakdowns_power_steering_pump_failure_stage4_message", disableAi = true } },
                },
                inspection = {
                    { target = "hydraulicFluid", status = "ads_inspection_status_critical_condition", additional = "ads_inspection_hint_power_steering_pump_failure_stage4" },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- electrical: faulty dashboard sensors (phantom warnings, wandering temperature gauge)
    DASH_SENSOR_FAULT = {
        isSelectable = true,
        system = systems.ELECTRICAL,
        part = parts.DASH_SENSORS,
        isApplicable = function(vehicle)
            return getVehicleYear(vehicle) >= 1990
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.ELECTRICAL, {"wef"}, {"crf", "sf"})
        end,
        isCanProgress = function(vehicle)
            return vehicle:getIsMotorStarted()
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_dash_sensor_fault_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.DASH_SENSOR_FAULT,
                repairPrice = 1.0 * breakdownPriceMultipliers.DASH_SENSOR_FAULT,
                effects = {
                    { id = "TEMP_SENSOR_FAULT_EFFECT", value = 3, aggregation = "max" },
                    { id = "GAUGE_GLITCH_EFFECT", value = 600, aggregation = "min" },
                },
                indicators = {
                    { id = db.COOLANT, color = color.WARNING, switchOn = phantomIndicator(420000, 0), switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_dash_sensor_fault_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.DASH_SENSOR_FAULT,
                repairPrice = 2.0 * breakdownPriceMultipliers.DASH_SENSOR_FAULT,
                effects = {
                    { id = "TEMP_SENSOR_FAULT_EFFECT", value = 8, aggregation = "max" },
                    { id = "GAUGE_GLITCH_EFFECT", value = 240, aggregation = "min" },
                },
                indicators = {
                    { id = db.COOLANT, color = color.WARNING, switchOn = phantomIndicator(240000, 0), switchOff = false },
                    { id = db.ENGINE, color = color.WARNING, switchOn = phantomIndicator(300000, 97000), switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_dash_sensor_fault_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.DASH_SENSOR_FAULT,
                repairPrice = 4.0 * breakdownPriceMultipliers.DASH_SENSOR_FAULT,
                effects = {
                    { id = "TEMP_SENSOR_FAULT_EFFECT", value = 20, aggregation = "max" },
                    { id = "GAUGE_GLITCH_EFFECT", value = 120, aggregation = "min" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_dash_sensor_fault_stage3" },
                },
                indicators = {
                    { id = db.COOLANT, color = color.CRITICAL, switchOn = phantomIndicator(150000, 0), switchOff = false },
                    { id = db.ENGINE, color = color.WARNING, switchOn = phantomIndicator(180000, 61000), switchOff = false },
                    { id = db.BATTERY, color = color.WARNING, switchOn = phantomIndicator(210000, 133000), switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_dash_sensor_fault_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.DASH_SENSOR_FAULT,
                effects = {
                    { id = "TEMP_SENSOR_FAULT_EFFECT", value = 40, aggregation = "max" },
                    { id = "GAUGE_GLITCH_EFFECT", value = 60, aggregation = "min" },
                    { id = "ENGINE_LIMP_EFFECT", value = -0.20, aggregation = "min", extraData = { reason = "BREAKDOWN", message = "ads_breakdowns_dash_sensor_fault_stage4_message" } },
                },
                inspection = {
                    { additional = "ads_inspection_hint_dash_sensor_fault_stage4" },
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false },
                    { id = db.COOLANT, color = color.CRITICAL, switchOn = phantomIndicator(90000, 0), switchOff = false },
                    { id = db.BATTERY, color = color.WARNING, switchOn = phantomIndicator(120000, 41000), switchOff = false }
                }
            }
        }
    },

    -- electrical: rodent-chewed wiring. Never picked by wear/stress - it is added by
    -- AdvancedDamageSystem:updateIdleRodentRisk() when a machine has sat unused for days.
    RODENT_DAMAGED_WIRING = {
        isSelectable = true,
        system = systems.ELECTRICAL,
        part = parts.WIRING_HARNESS,
        isApplicable = function(vehicle)
            return vehicle.spec_motorized ~= nil and not isCarLikeVehicle(vehicle)
        end,
        probability = function(vehicle)
            return 0.0
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_rodent_damaged_wiring_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.RODENT_DAMAGED_WIRING,
                repairPrice = 1.0 * breakdownPriceMultipliers.RODENT_DAMAGED_WIRING,
                effects = {
                    { id = "LIGHTS_FLICKER_CHANCE", value = 1.0, extraData = {timer = 0, status = 'IDLE', duration = 200, maskBackup = 0}, aggregation = "min" },
                    { id = "ELECTRICAL_CONTACT_RESISTANCE_EFFECT", value = 1.0, extraData = { timer = 0, status = 'IDLE'}, aggregation = "min" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_rodent_damaged_wiring_stage1" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_rodent_damaged_wiring_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.RODENT_DAMAGED_WIRING,
                repairPrice = 2.0 * breakdownPriceMultipliers.RODENT_DAMAGED_WIRING,
                effects = {
                    { id = "LIGHTS_FLICKER_CHANCE", value = 0.33, extraData = {timer = 0, status = 'IDLE', duration = 300, maskBackup = 0}, aggregation = "min" },
                    { id = "ENGINE_HARD_START_MODIFIER", value = 4, extraData = { timer = 0, status = 'IDLE'}, aggregation = "max" },
                    { id = "ELECTRICAL_CONTACT_RESISTANCE_EFFECT", value = 0.5, extraData = { timer = 0, status = 'IDLE'}, aggregation = "min" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_rodent_damaged_wiring_stage2" },
                },
                indicators = {
                    { id = db.BATTERY, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_rodent_damaged_wiring_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.RODENT_DAMAGED_WIRING,
                repairPrice = 4.0 * breakdownPriceMultipliers.RODENT_DAMAGED_WIRING,
                effects = {
                    { id = "LIGHTS_FAILURE", value = 1.0, aggregation = "boolean_or" },
                    { id = "ENGINE_STALLS_CHANCE", value = 20.0, aggregation = "min" },
                    { id = "ENGINE_HARD_START_MODIFIER", value = 8, extraData = { timer = 0, status = 'IDLE'}, aggregation = "max" },
                    { id = "ELECTRICAL_CONTACT_RESISTANCE_EFFECT", value = 0.2, extraData = { timer = 0, status = 'IDLE'}, aggregation = "min" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_rodent_damaged_wiring_stage3" },
                },
                indicators = {
                    { id = db.BATTERY, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_rodent_damaged_wiring_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.RODENT_DAMAGED_WIRING,
                effects = {
                    { id = "LIGHTS_FAILURE", value = 1.0, aggregation = "boolean_or" },
                    { id = "ENGINE_FAILURE", value = 1.0, aggregation = "boolean_or", extraData = {starter = false, message = "ads_breakdowns_rodent_damaged_wiring_stage4_message", reason = "BREAKDOWN", disableAi = true} },
                },
                inspection = {
                    { additional = "ads_inspection_hint_rodent_damaged_wiring_stage4" },
                },
                indicators = {
                    { id = db.BATTERY, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- chassis: slow puncture / leaking valve stem
    SLOW_PUNCTURE = {
        isSelectable = true,
        system = systems.CHASSIS,
        part = parts.TIRE,
        isApplicable = function(vehicle)
            return hasWheelsWithoutTracks(vehicle)
        end,
        probability = function(vehicle)
            return getBreakdownProbabilityWeightPercent(vehicle, systems.CHASSIS, {"vf"}, {"slf", "sf"})
        end,
        isCanProgress = function(vehicle)
            return vehicle:getLastSpeed() > 0.01
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_slow_puncture_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.SLOW_PUNCTURE,
                repairPrice = 1.0 * breakdownPriceMultipliers.SLOW_PUNCTURE,
                effects = {
                    { id = "STEERING_STATIC_BIAS_EFFECT", value = 0.004, aggregation = "max" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.03, aggregation = "sum" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_slow_puncture_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.SLOW_PUNCTURE,
                repairPrice = 2.0 * breakdownPriceMultipliers.SLOW_PUNCTURE,
                effects = {
                    { id = "STEERING_STATIC_BIAS_EFFECT", value = 0.012, aggregation = "max" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.06, aggregation = "sum" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.05, aggregation = "max" },
                    { id = "VIBRATION_NOISE_EFFECT", value = 0.5, aggregation = "max" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_slow_puncture_stage2" },
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_slow_puncture_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.SLOW_PUNCTURE,
                repairPrice = 4.0 * breakdownPriceMultipliers.SLOW_PUNCTURE,
                effects = {
                    { id = "STEERING_STATIC_BIAS_EFFECT", value = 0.03, aggregation = "max" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.10, aggregation = "sum" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.20, aggregation = "max" },
                    { id = "VIBRATION_NOISE_EFFECT", value = 1.2, aggregation = "max" },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.03, aggregation = "sum" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_slow_puncture_stage3" },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_slow_puncture_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.SLOW_PUNCTURE,
                effects = {
                    { id = "STEERING_STATIC_BIAS_EFFECT", value = 0.06, aggregation = "max" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.60, aggregation = "max", extraData = { message = "ads_breakdowns_slow_puncture_stage4_message", disableAi = true } },
                    { id = "VIBRATION_NOISE_EFFECT", value = 2.0, aggregation = "max" },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.10, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.15, aggregation = "sum" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_slow_puncture_stage4" },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- chassis: trailer air brake supply leak (only bites while towing a braked trailer)
    TRAILER_AIR_BRAKE_LEAK = {
        isSelectable = true,
        system = systems.CHASSIS,
        part = parts.TRAILER_AIR_BRAKES,
        isApplicable = function(vehicle)
            return canTowTrailers(vehicle) and getVehicleYear(vehicle) >= 1970
        end,
        probability = function(vehicle)
            local weight = getBreakdownProbabilityWeightPercent(vehicle, systems.CHASSIS, {"bmf"}, {"vf", "sf"})
            if isTowingBrakedImplement(vehicle) then
                return weight * 1.5
            end
            return weight * 0.5
        end,
        isCanProgress = function(vehicle)
            return vehicle:getLastSpeed() > 0.01
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_trailer_air_brake_leak_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.TRAILER_AIR_BRAKE_LEAK,
                repairPrice = 1.0 * breakdownPriceMultipliers.TRAILER_AIR_BRAKE_LEAK,
                effects = {
                    { id = "TRAILER_BRAKE_DRAG_EFFECT", value = 0.0, aggregation = "max", extraData = { buildUpMs = 15000 } },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_trailer_air_brake_leak_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.TRAILER_AIR_BRAKE_LEAK,
                repairPrice = 2.0 * breakdownPriceMultipliers.TRAILER_AIR_BRAKE_LEAK,
                effects = {
                    { id = "TRAILER_BRAKE_DRAG_EFFECT", value = 0.15, aggregation = "max", extraData = { buildUpMs = 30000 } },
                },
                inspection = {
                    { additional = "ads_inspection_hint_trailer_air_brake_leak_stage2" },
                },
                indicators = {
                    { id = db.BRAKES, color = color.WARNING, switchOn = isTowingBrakedImplement, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_trailer_air_brake_leak_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.TRAILER_AIR_BRAKE_LEAK,
                repairPrice = 4.0 * breakdownPriceMultipliers.TRAILER_AIR_BRAKE_LEAK,
                effects = {
                    { id = "TRAILER_BRAKE_DRAG_EFFECT", value = 0.35, aggregation = "max", extraData = { buildUpMs = 60000 } },
                },
                inspection = {
                    { additional = "ads_inspection_hint_trailer_air_brake_leak_stage3" },
                },
                indicators = {
                    { id = db.BRAKES, color = color.CRITICAL, switchOn = isTowingBrakedImplement, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_trailer_air_brake_leak_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.TRAILER_AIR_BRAKE_LEAK,
                effects = {
                    { id = "TRAILER_BRAKE_DRAG_EFFECT", value = 1.0, aggregation = "max", extraData = { buildUpMs = 0, message = "ads_breakdowns_trailer_air_brake_leak_stage4_message", disableAi = true } },
                },
                inspection = {
                    { additional = "ads_inspection_hint_trailer_air_brake_leak_stage4" },
                },
                indicators = {
                    { id = db.BRAKES, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- chassis: random sudden flat tire
    FLAT_TIRE_LEFT = buildFlatTireBreakdown(1),
    FLAT_TIRE_RIGHT = buildFlatTireBreakdown(-1),

    -- TO-DO: WORKPROCESS_POWER_DEMAND_MODIFIER
    -- TO-DO: ROLLING_RESISTANCE_MODIFIER
    
}

local function wrapBreakdownApplicabilityByEnabledSystem()
    for _, entry in pairs(ADS_Breakdowns.BreakdownRegistry or {}) do
        if type(entry) == "table" and entry.system ~= nil and type(entry.isApplicable) == "function" then
            local originalIsApplicable = entry.isApplicable

            entry.isApplicable = function(vehicle)
                if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
                    return false
                end

                local spec = vehicle.spec_AdvancedDamageSystem
                local systemKey = nil

                if ADS_Utils ~= nil and AdvancedDamageSystem ~= nil and AdvancedDamageSystem.SYSTEMS ~= nil then
                    systemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, entry.system)
                end

                if (systemKey == nil or systemKey == "") and type(entry.system) == "string" then
                    systemKey = string.lower(entry.system)
                end

                if systemKey ~= nil and systemKey ~= "" then
                    local systemData = spec.systems ~= nil and spec.systems[systemKey] or nil
                    if type(systemData) == "table" and systemData.enabled == false then
                        return false
                    end
                end

                return originalIsApplicable(vehicle) == true
            end
        end
    end
end

wrapBreakdownApplicabilityByEnabledSystem()

-- ==========================================================
--                     BREAKDOWN EFFECTS
-- ==========================================================

ADS_Breakdowns.EffectApplicators = {}

local function addFuncToActive(v, effectName, func)
    if v.spec_AdvancedDamageSystem.activeFunctions[effectName] == nil then
        v.spec_AdvancedDamageSystem.activeFunctions[effectName] = func
    end
end

local function removeFuncFromActive(v, effectName)
    if v.spec_AdvancedDamageSystem.activeFunctions[effectName] ~= nil then
        v.spec_AdvancedDamageSystem.activeFunctions[effectName] = nil
    end
end

local function getStarterCrankingPitchOffset(preCrankVoltageV)
    local resolvedVoltage = preCrankVoltageV or 12.2
    local t = math.clamp((12.2 - resolvedVoltage) / 0.5, 0, 1)
    return -0.25 * (t * t)
end

local function getActiveStarterCrankingEffect(spec)
    if spec == nil or spec.activeEffects == nil then
        return nil
    end

    local engineFailure = spec.activeEffects.ENGINE_FAILURE
    if engineFailure ~= nil and engineFailure.extraData ~= nil and engineFailure.extraData.status == "CRANKING" then
        return engineFailure
    end

    local engineHardStart = spec.activeEffects.ENGINE_HARD_START_MODIFIER
    if engineHardStart ~= nil and engineHardStart.extraData ~= nil and engineHardStart.extraData.status == "CRANKING" then
        return engineHardStart
    end

    return nil
end

local function syncStarterCrankingSample(vehicle)
    if vehicle == nil or not vehicle.isClient then
        return
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    local starterCrankingSample = spec ~= nil and spec.samples ~= nil and spec.samples.starterCranking or nil
    if starterCrankingSample == nil then
        return
    end

    local activeEffect = getActiveStarterCrankingEffect(spec)
    local shouldPlay = activeEffect ~= nil and spec.startButtonHeld == true and not vehicle:getIsMotorStarted()

    if shouldPlay then
        local pitchOffset = getStarterCrankingPitchOffset(activeEffect.extraData.preCrankVoltageV)
        g_soundManager:setSamplePitchOffset(starterCrankingSample, pitchOffset)
        if not g_soundManager:getIsSamplePlaying(starterCrankingSample) then
            g_soundManager:playSample(starterCrankingSample)
        end
    else
        if g_soundManager:getIsSamplePlaying(starterCrankingSample) then
            g_soundManager:stopSample(starterCrankingSample, 0, 0)
        end
        g_soundManager:setSamplePitchOffset(starterCrankingSample, 0)
    end
end

local function playStarterCrankingEndSample(spec, pitchOffset)
    local starterCrankingEndSample = spec ~= nil and spec.samples ~= nil and spec.samples.starterCrankingEnd or nil
    if starterCrankingEndSample == nil then
        return
    end

    g_soundManager:setSampleVolumeOffset(starterCrankingEndSample, 0)
    if not g_soundManager:getIsSamplePlaying(starterCrankingEndSample) then
        g_soundManager:setSamplePitchOffset(starterCrankingEndSample, pitchOffset or 0)
        g_soundManager:playSample(starterCrankingEndSample)
    end
end

-- ==========================================================
-- SELF_DISAPPEARING_BREAKDOWN_EFFECT
ADS_Breakdowns.EffectApplicators.SELF_DISAPPEARING_BREAKDOWN_EFFECT = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying SELF_DISAPPEARING_BREAKDOWN_EFFECT")
        vehicle:removeBreakdown(effectData.extraData.breakdownId)
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing SELF_DISAPPEARING_BREAKDOWN_EFFECT effect.")
    end
}

-- ==========================================================
-- ENGINE_FAILURE
ADS_Breakdowns.EffectApplicators.ENGINE_FAILURE = {
    getEffectName = function()
        return "ENGINE_FAILURE"
    end,
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying ENGINE_FAILURE effect.")
        local effectName = handler.getEffectName()
        local spec = vehicle.spec_AdvancedDamageSystem
        local activeFunc = function(v, dt)
            local currentEffect = v.spec_AdvancedDamageSystem.activeEffects ~= nil and v.spec_AdvancedDamageSystem.activeEffects[effectName] or nil
            if currentEffect == nil or currentEffect.extraData == nil then
                return
            end

            if currentEffect.extraData.status ~= nil and currentEffect.extraData.status == 'CRANKING' then
                if currentEffect.extraData.preCrankVoltageV == nil then
                    currentEffect.extraData.preCrankVoltageV = spec.batteryTerminalVoltageV or spec.batteryOpenCircuitVoltageV or 12.2
                end
            end

            if v:getIsMotorStarted() then
                v.adsStopCause = "ADS engine failure"
                v:stopMotor()
            end
            if currentEffect.extraData.status ~= nil and currentEffect.extraData.status == 'CRANKING' then
                if not spec.startButtonHeld then
                    currentEffect.extraData.status = 'IDLE'
                    currentEffect.extraData.preCrankVoltageV = nil
                    ADS_EffectSyncEvent.send(v, effectName, "IDLE", 0, 0, 0)
                end
            end

            syncStarterCrankingSample(v)
        end
        addFuncToActive(vehicle, effectName, activeFunc)
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing ENGINE_FAILURE effect.")
        syncStarterCrankingSample(vehicle)
        removeFuncFromActive(vehicle, handler.getEffectName())
    end,
}

-- ==========================================================
-- LIGHTS_FAILURE
ADS_Breakdowns.EffectApplicators.LIGHTS_FAILURE = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying LIGHTS_FAILURE effect")
        local currentLightMask = vehicle:getLightsTypesMask()
        if currentLightMask ~= 0 then
            vehicle:setLightsTypesMask(0, true, true)
        end
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing LIGHTS_FAILURE effect")
    end
}

function ADS_Breakdowns.setLightsTypesMask(self, superFunc, lightsTypesMask, force, noEventSend)
    local rootVehicle = self:getRootVehicle()
    local lightsFailure = rootVehicle.spec_AdvancedDamageSystem and rootVehicle.spec_AdvancedDamageSystem.activeEffects.LIGHTS_FAILURE
    if lightsFailure == nil then
        superFunc(self, lightsTypesMask, force, noEventSend)
    else
        local currentLightMask = self:getLightsTypesMask()
        if currentLightMask ~= 0 then 
            superFunc(self, 0, force, noEventSend)
        end  
        return
    end
end

-- ==========================================================
-- UNLOADING_AUGER_FAILURE
ADS_Breakdowns.EffectApplicators.UNLOADING_AUGER_FAILURE = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying UNLOADING_AUGER_FAILURE:", effectData.value)
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing UNLOADING_AUGER_FAILURE effect.")
    end
}

function ADS_Breakdowns.getIsDischargeNodeActiveOverwrite(vehicle, superFunc, dischargeNode, ...)
    local spec_ads = vehicle.spec_AdvancedDamageSystem
    if spec_ads ~= nil and spec_ads.activeEffects ~= nil then
        local effect = spec_ads.activeEffects.UNLOADING_AUGER_FAILURE
        if effect ~= nil then
            return false
        end
    end
    return superFunc(vehicle, dischargeNode, ...)
end

-- ==========================================================
-- PTO_FAILURE
ADS_Breakdowns.EffectApplicators.PTO_FAILURE = {
    getEffectName = function() return "PTO_FAILURE" end,
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying PTO_FAILURE effect.")
        local effectName = handler.getEffectName()

        local function forceDisablePtoConsumers(rootVehicle)
            local turnedOff = false
            local visited = {}

            local function walk(vehicleObj)
                if vehicleObj == nil or visited[vehicleObj] then
                    return
                end
                visited[vehicleObj] = true

                local ptoCapable = vehicleObj.getDoConsumePtoPower ~= nil
                    or vehicleObj.getIsPowerTakeOffActive ~= nil
                    or vehicleObj.getPtoRpm ~= nil

                local isTurnedOn = vehicleObj.getIsTurnedOn ~= nil and vehicleObj:getIsTurnedOn() or false
                if ptoCapable and isTurnedOn and vehicleObj.setIsTurnedOn ~= nil then
                    vehicleObj:setIsTurnedOn(false)
                    turnedOff = true
                end

                if vehicleObj.getAttachedImplements ~= nil then
                    local implements = vehicleObj:getAttachedImplements() or {}
                    for _, implement in pairs(implements) do
                        if implement ~= nil and implement.object ~= nil then
                            walk(implement.object)
                        end
                    end
                end
            end

            walk(rootVehicle)
            return turnedOff
        end

        local activeFunc = function(v, dt)
            local effect = v.spec_AdvancedDamageSystem.activeEffects[effectName]
            if effect == nil or (tonumber(effect.value) or 0) <= 0 then
                return
            end
            effect.extraData = effect.extraData or {}
            forceDisablePtoConsumers(v)
        end

        addFuncToActive(vehicle, effectName, activeFunc)
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing PTO_FAILURE effect.")
        removeFuncFromActive(vehicle, handler.getEffectName())
    end
}
                 
-- ==========================================================
local function getWheelSeizureTargetWheel(vehicle)
    local spec_ads = vehicle.spec_AdvancedDamageSystem
    local spec_wheels = vehicle.spec_wheels
    if spec_ads == nil or spec_wheels == nil or spec_wheels.wheels == nil then
        return nil
    end

    local wheels = spec_wheels.wheels

    local function resolveWheelRuntime(wheel)
        local runtimeWheel = (wheel ~= nil and wheel.physics ~= nil) and wheel.physics or wheel
        if runtimeWheel == nil then
            return nil
        end

        local data = {
            wheel = wheel,
            runtime = runtimeWheel
        }

        data.node = runtimeWheel.node or (wheel and wheel.node) or nil
        data.wheelShape = runtimeWheel.wheelShape or (wheel and wheel.wheelShape) or nil
        data.wheelShapeCreated = (runtimeWheel.wheelShapeCreated == true) or (wheel and wheel.wheelShapeCreated == true) or false
        data.isLeft = runtimeWheel.isLeft
        if data.isLeft == nil and wheel ~= nil then
            data.isLeft = wheel.isLeft
        end
        data.brakeFactor = tonumber(runtimeWheel.brakeFactor) or tonumber(wheel and wheel.brakeFactor) or 0
        data.driveNode = runtimeWheel.driveNode or (wheel and wheel.driveNode) or data.node
        data.positionX = tonumber(runtimeWheel.positionX) or tonumber(wheel and wheel.positionX) or 0
        data.positionZ = tonumber(runtimeWheel.positionZ) or tonumber(wheel and wheel.positionZ) or 0
        data.steeringAngle = tonumber(runtimeWheel.steeringAngle) or tonumber(wheel and wheel.steeringAngle) or 0
        data.rotationDamping = tonumber(runtimeWheel.rotationDamping) or tonumber(wheel and wheel.rotationDamping) or 0
        data.torqueTarget = runtimeWheel

        return data
    end

    local function isValidWheelData(wd)
        return wd ~= nil
            and wd.node ~= nil and wd.node ~= 0
            and wd.wheelShape ~= nil and wd.wheelShape ~= 0
    end
    local cachedIndex = spec_ads.wheelSeizureTargetIndex
    if cachedIndex ~= nil then
        local cachedWheel = wheels[cachedIndex]
        local cachedData = resolveWheelRuntime(cachedWheel)
        if isValidWheelData(cachedData) then
            return cachedData
        end
    end

    local rootNode = vehicle.components and vehicle.components[1] and vehicle.components[1].node
    local function getWheelLocalPos(wheelData)
        if rootNode ~= nil and wheelData ~= nil then
            local sampleNode = wheelData.driveNode or wheelData.node
            if sampleNode ~= nil then
                local x, _, z = localToLocal(sampleNode, rootNode, 0, 0, 0)
                return x or 0, z or 0
            end
        end
        return wheelData and wheelData.positionX or 0, wheelData and wheelData.positionZ or 0
    end

    local function pickBest(predicate)
        local bestIndex = nil
        local bestZ = -math.huge
        for i, wheel in ipairs(wheels) do
            local wheelData = resolveWheelRuntime(wheel)
            if isValidWheelData(wheelData) and predicate(wheelData) then
                local _, z = getWheelLocalPos(wheelData)
                if bestIndex == nil or z > bestZ then
                    bestIndex = i
                    bestZ = z
                end
            end
        end
        return bestIndex
    end

    local bestIndex = pickBest(function(wheelData)
        local x = getWheelLocalPos(wheelData)
        return (wheelData.isLeft == false or x > 0) and wheelData.brakeFactor > 0
    end)

    if bestIndex == nil then
        bestIndex = pickBest(function(wheelData)
            local x = getWheelLocalPos(wheelData)
            return (wheelData.isLeft == false or x > 0)
        end)
    end

    if bestIndex == nil then
        bestIndex = pickBest(function(wheelData)
            return wheelData.brakeFactor > 0
        end)
    end

    if bestIndex == nil then
        bestIndex = pickBest(function(_)
            return true
        end)
    end

    spec_ads.wheelSeizureTargetIndex = bestIndex
    if bestIndex ~= nil then
        return resolveWheelRuntime(wheels[bestIndex])
    end
    return nil
end

-- ENGINE_LIMP_EFFECT
ADS_Breakdowns.EffectApplicators.ENGINE_LIMP_EFFECT = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying ENGINE_LIMP_EFFECT:", effectData.value)
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing ENGINE_LIMP_EFFECT effect.")
    end
}

-- BRAKE_FORCE_MODIFIER
ADS_Breakdowns.EffectApplicators.BRAKE_FORCE_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying BRAKE_FORCE_MODIFIER:", effectData.value)
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing BRAKE_FORCE_MODIFIER effect.")
    end
}

-- STEERING_STATIC_BIAS_EFFECT
ADS_Breakdowns.EffectApplicators.STEERING_STATIC_BIAS_EFFECT = {
    apply = function(vehicle, effectData, handler)
    end,
    remove = function(vehicle, handler)
    end
}

-- STEERING_SENSITIVITY_MODIFIER
ADS_Breakdowns.EffectApplicators.STEERING_SENSITIVITY_MODIFIER = {
    apply = function(vehicle, effectData, handler)
    end,
    remove = function(vehicle, handler)
    end
}

-- WHEEL_SEIZURE_EFFECT
ADS_Breakdowns.EffectApplicators.WHEEL_SEIZURE_EFFECT = {
    apply = function(vehicle, effectData, handler)
    end,
    remove = function(vehicle, handler)
        if vehicle.spec_AdvancedDamageSystem ~= nil then
            vehicle.spec_AdvancedDamageSystem.wheelSeizureTargetIndex = nil
        end
    end
}

-- ENGINE_HESITATION_CHANCE
ADS_Breakdowns.EffectApplicators.ENGINE_HESITATION_CHANCE = {
    getEffectName = function() return "ENGINE_HESITATION_CHANCE" end,

    apply = function(vehicle, effectData, handler)
        log_dbg("Applying ENGINE_HESITATION_CHANCE effect")

        local effectName = handler.getEffectName()
        local activeFunc = function(v, dt)
            local extra = effectData.extraData

            if extra.status == "CHOKING" then
                extra.timer = extra.timer + dt
                if extra.timer > extra.duration then
                    if extra.cruiseState ~= 0 then
                        vehicle:setCruiseControlState(extra.cruiseState, true)
                    end
                    extra.status = "IDLE"
                    extra.timer = 0
                end
            elseif vehicle:getMotorLoadPercentage() > extra.motorLoad then
                if vehicle.isServer and effectData.value > 0 and math.random() < ADS_Utils.getChancePerFrameFromMeanTime(dt, effectData.value) and extra.status == "IDLE" then
                    
                    local cruiseState = vehicle:getCruiseControlState()
                    if cruiseState ~= 0 then
                        extra.cruiseState = cruiseState
                        vehicle:setCruiseControlState(0, true)
                    end
                    extra.status = "CHOKING"
                    ADS_EffectSyncEvent.send(vehicle, "ENGINE_HESITATION_CHANCE", "CHOKING", 0)

                end
            end
        end
        addFuncToActive(vehicle, effectName, activeFunc)
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing ENGINE_HESITATION_CHANCE")
        removeFuncFromActive(vehicle, handler.getEffectName())
    end
}

function ADS_Breakdowns.updateVehiclePhysics(vehicle, superFunc, axisForward, axisSide, doHandbrake, dt)
    local spec_ads = vehicle.spec_AdvancedDamageSystem
    local brakeEffect = spec_ads and spec_ads.activeEffects.BRAKE_FORCE_MODIFIER
    local limpEffect = spec_ads and spec_ads.activeEffects.ENGINE_LIMP_EFFECT
    local hesitationEffect = spec_ads and spec_ads.activeEffects.ENGINE_HESITATION_CHANCE
    local steeringStaticBiasEffect = spec_ads and spec_ads.activeEffects.STEERING_STATIC_BIAS_EFFECT
    local steeringSensitivityEffect = spec_ads and spec_ads.activeEffects.STEERING_SENSITIVITY_MODIFIER
    local wheelSeizureEffect = spec_ads and spec_ads.activeEffects.WHEEL_SEIZURE_EFFECT
    local isBraking = false
    local drivingMode = vehicle:getDirectionChangeMode()

    if hesitationEffect and hesitationEffect.extraData and hesitationEffect.extraData.status == "CHOKING" then
        axisForward = axisForward * math.max(1 - hesitationEffect.extraData.amplitude, 0)
    end

    -- Steering sensitivity modifier: reduces driver steering input effect.
    if steeringSensitivityEffect ~= nil and steeringSensitivityEffect.value ~= nil then
        local value = math.max(tonumber(steeringSensitivityEffect.value) or 0, 0)
        local sensitivity = math.clamp(1 - value, 0.05, 1.0)
        axisSide = axisSide * sensitivity
    end

    -- Static steering bias: positive value drifts left (all stock breakdowns), negative
    -- value drifts right (e.g. a flat on the right side). Magnitude = offset intensity.
    if steeringStaticBiasEffect ~= nil and steeringStaticBiasEffect.value ~= nil then
        local value = tonumber(steeringStaticBiasEffect.value) or 0
        local leftBias = -math.clamp(value, -1.0, 1.0)
        local x = math.clamp(axisSide, -1.0, 1.0)

        -- Keep full steering range while shifting neutral point to the left.
        -- Endpoints remain: f(-1) = -1, f(1) = 1, with f(0) = leftBias.
        if x < 0 then
            axisSide = (1 + leftBias) * x + leftBias
        else
            axisSide = (1 - leftBias) * x + leftBias
        end
        axisSide = math.clamp(axisSide, -1.0, 1.0)
    end

    if limpEffect and limpEffect.value then
        local maxAllowedAcceleration = math.max(1 + limpEffect.value, 0.2)
        if math.abs(axisForward) > maxAllowedAcceleration then
            if drivingMode == 2 then
                if axisForward > maxAllowedAcceleration then
                    axisForward = maxAllowedAcceleration
                end
            else
                if math.sign(vehicle.movingDirection) == math.sign(axisForward) then
                    if axisForward > 0 then
                        axisForward = maxAllowedAcceleration
                    else
                        axisForward = -1 * maxAllowedAcceleration
                    end
                end   
            end
        end
    end

    -- Leaking trailer air brakes: trailer brakes held (spring brakes / no pressure yet)
    -- or dragging while towing.
    local trailerBrakesHeld, trailerBrakeDrag = ADS_Breakdowns.getTrailerBrakeState(vehicle)
    if trailerBrakesHeld then
        axisForward = 0
        doHandbrake = true
    elseif trailerBrakeDrag > 0 and axisForward ~= 0 then
        local isAccelerating
        if drivingMode == 2 then
            isAccelerating = axisForward > 0
        else
            isAccelerating = vehicle.movingDirection == 0 or math.sign(vehicle.movingDirection) == math.sign(axisForward)
        end
        if isAccelerating then
            axisForward = axisForward * (1 - trailerBrakeDrag)
        end
    end

    if brakeEffect and brakeEffect.value ~= 0 then
        if drivingMode == 2 then
            isBraking = axisForward < -0.01
        else
            isBraking = vehicle.movingDirection ~= 0 and axisForward ~= 0 and math.sign(vehicle.movingDirection) ~= math.sign(axisForward)
        end
        
        if isBraking then
            local modifier = math.max(0.01, 1 + brakeEffect.value) 
            local origAxisForward = axisForward
            axisForward = axisForward * modifier
            if brakeEffect.extraData ~= nil and vehicle:getLastSpeed() < 15 then
                if not brakeEffect.extraData.soundPlayed and math.abs(origAxisForward) > 0.999 then
                    if math.random() < brakeEffect.value then
                        g_soundManager:playSample(spec_ads.samples['brakes' .. math.random(3)])
                    end
                    brakeEffect.extraData.soundPlayed = true
                    brakeEffect.extraData.timer = 1500
                end
            end
        end

        if brakeEffect.extraData ~= nil and brakeEffect.extraData.timer > 0 then
            brakeEffect.extraData.timer = brakeEffect.extraData.timer - dt
        elseif brakeEffect.extraData ~= nil and brakeEffect.extraData.soundPlayed == true then
            brakeEffect.extraData.soundPlayed = false
            brakeEffect.extraData.timer = 0
        end
    end

    local result = superFunc(vehicle, axisForward, axisSide, doHandbrake, dt)

    if wheelSeizureEffect ~= nil and (tonumber(wheelSeizureEffect.value) or 0) > 0 and vehicle.isAddedToPhysics then
        local wheelData = getWheelSeizureTargetWheel(vehicle)
        if wheelData ~= nil and wheelData.node ~= nil and wheelData.node ~= 0 and wheelData.wheelShape ~= nil and wheelData.wheelShape ~= 0 then
            local intensity = math.clamp(tonumber(wheelSeizureEffect.value) or 1.0, 0, 1.0)
            local baseBrakeForce = 0
            if vehicle.getBrakeForce ~= nil then
                baseBrakeForce = tonumber(vehicle:getBrakeForce()) or 0
            end
            if baseBrakeForce <= 0 and vehicle.spec_motorized ~= nil and vehicle.spec_motorized.motor ~= nil and vehicle.spec_motorized.motor.getBrakeForce ~= nil then
                baseBrakeForce = tonumber(vehicle.spec_motorized.motor:getBrakeForce()) or 0
            end
            baseBrakeForce = math.max(baseBrakeForce, 100)

            -- Seized wheel: heavy drag without fully anchoring vehicle in place.
            local lockBrakeForce = math.max(baseBrakeForce * intensity, 100)
            local lockDamping = math.max((tonumber(wheelData.rotationDamping) or 0) * (3 + 4 * intensity), 5)

            if wheelData.torqueTarget ~= nil then
                wheelData.torqueTarget.torque = 0
            end
            if wheelData.wheel ~= nil and wheelData.wheel ~= wheelData.torqueTarget then
                wheelData.wheel.torque = 0
            end
            setWheelShapeProps(
                wheelData.node,
                wheelData.wheelShape,
                0,
                lockBrakeForce,
                wheelData.steeringAngle or 0,
                lockDamping
            )
        end
    end

    return result
end
                  
-- ==========================================================
-- ENGINE_TORQUE_MODIFIER
ADS_Breakdowns.EffectApplicators.ENGINE_TORQUE_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying ENGINE_TORQUE_MODIFIER:", effectData.value)
        vehicle:updateMotorProperties()
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing ENGINE_TORQUE_MODIFIER effect.")
        vehicle:updateMotorProperties()
    end
}

if VehicleMotor ~= nil and VehicleMotor.getTorqueCurveValue ~= nil then
    VehicleMotor.getTorqueCurveValue = Utils.overwrittenFunction(VehicleMotor.getTorqueCurveValue, function(self, superFunc, rpm)
        local torque = superFunc(self, rpm)
        local vehicle = self.vehicle
        if vehicle ~= nil then
            local spec_ads = vehicle.spec_AdvancedDamageSystem
            if spec_ads ~= nil and spec_ads.activeEffects ~= nil then
                local effect = spec_ads.activeEffects.ENGINE_TORQUE_MODIFIER
                if effect ~= nil and effect.value ~= nil then
                    torque = torque * math.max((1 + effect.value), 0.2)
                end
            end
        end
        return torque
    end)
end
                  
-- ==========================================================
-- PTO_TORQUE_TRANSFER_MODIFIER
ADS_Breakdowns.EffectApplicators.PTO_TORQUE_TRANSFER_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying PTO_TORQUE_TRANSFER_MODIFIER:", effectData.value)
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing PTO_TORQUE_TRANSFER_MODIFIER effect.")
    end
}

if PowerConsumer ~= nil and PowerConsumer.getTotalConsumedPtoTorque ~= nil then
    local adsPtoCallDepth = 0
    PowerConsumer.getTotalConsumedPtoTorque = Utils.overwrittenFunction(PowerConsumer.getTotalConsumedPtoTorque, function(self, superFunc, excludeVehicle, expected, ignoreTurnOnPeak)
        adsPtoCallDepth = adsPtoCallDepth + 1
        local callDepth = adsPtoCallDepth

        local ok, torque, virtualMultiplicator = pcall(superFunc, self, excludeVehicle, expected, ignoreTurnOnPeak)
        if not ok then
            adsPtoCallDepth = math.max(adsPtoCallDepth - 1, 0)
            log_dbg("ERROR in PowerConsumer.getTotalConsumedPtoTorque hook:", tostring(torque))
            return 0, 1
        end

        if callDepth == 1 then
            local rootVehicle = self
            if rootVehicle ~= nil and rootVehicle.getRootVehicle ~= nil then
                rootVehicle = rootVehicle:getRootVehicle()
            end

            local spec = rootVehicle ~= nil and rootVehicle.spec_AdvancedDamageSystem or nil
            local effect = spec ~= nil and spec.activeEffects ~= nil and spec.activeEffects.PTO_TORQUE_TRANSFER_MODIFIER or nil
            if effect ~= nil then
                local effectValue = tonumber(effect.value) or 0
                local transferScale = math.max(0, 1 + effectValue)
                local modifiedTorque = torque * transferScale

                torque = modifiedTorque
            end
        end

        adsPtoCallDepth = math.max(adsPtoCallDepth - 1, 0)
        return torque, virtualMultiplicator
    end)
end
                  
-- ==========================================================
-- FUEL_CONSUMPTION_MODIFIER
ADS_Breakdowns.EffectApplicators.FUEL_CONSUMPTION_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying FUEL_CONSUMPTION_MODIFIER:", effectData.value)
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing FUEL_CONSUMPTION_MODIFIER effect.")
    end
}

function ADS_Breakdowns.updateConsumers(vehicle, dt, accInput)
	local spec = vehicle.spec_motorized
	local idleFactor = 0.5
	local rpmPercentage = (spec.motor.lastMotorRpm - spec.motor.minRpm) / (spec.motor.maxRpm - spec.motor.minRpm)
	local rpmFactor = idleFactor + rpmPercentage * (1 - idleFactor)
	local loadFactor = math.max(spec.smoothedLoadPercentage * rpmPercentage, 0)
	local motorFactor = 0.5 * (0.2 * rpmFactor + 1.8 * loadFactor)
    local timeScale = 1

    if g_modIsLoaded ~= nil and g_modIsLoaded["FS25_ingameTimeOperatingHours"] then
        local missionInfo = g_currentMission ~= nil and g_currentMission.missionInfo or nil
        timeScale = (missionInfo and missionInfo.timeScale) or 1
        if timeScale <= 0 then
            timeScale = 1
        end
    end

    local fuelUsageFactors = {
        [1] = 1.0,
        [2] = 1.5,
        [3] = 2.5
    }
    
    local fuelSetting = g_currentMission.missionInfo.fuelUsage
    
    local usageFactor = fuelUsageFactors[fuelSetting] or 1.5

	local damage = vehicle:getVehicleDamage()

	if damage > 0 then
		usageFactor = usageFactor * (1 + damage * Motorized.DAMAGED_USAGE_INCREASE)
	end

    if vehicle.spec_AdvancedDamageSystem ~= nil then
        local fuelEffect = vehicle.spec_AdvancedDamageSystem.activeEffects.FUEL_CONSUMPTION_MODIFIER
        local adsFuelModifier = (fuelEffect and fuelEffect.value) or 0
        usageFactor = usageFactor * (1 + adsFuelModifier)
    end

	for _, consumer in pairs(spec.consumers) do
		if consumer.permanentConsumption and consumer.usage > 0 then
			local used = usageFactor * motorFactor * consumer.usage * dt * timeScale

			if used ~= 0 then
				consumer.fillLevelToChange = consumer.fillLevelToChange + used

				if math.abs(consumer.fillLevelToChange) > 1 then
					used = consumer.fillLevelToChange
					consumer.fillLevelToChange = 0
					local fillType = vehicle:getFillUnitLastValidFillType(consumer.fillUnitIndex)
					local stats = g_currentMission:farmStats(vehicle:getOwnerFarmId())

					stats:updateStats("fuelUsage", used)

					if vehicle:getIsAIActive() and (fillType == FillType.DIESEL or fillType == FillType.DEF) and g_currentMission.missionInfo.helperBuyFuel then
						if fillType == FillType.DIESEL then
							local price = used * g_currentMission.economyManager:getCostPerLiter(fillType) * 1.5

							stats:updateStats("expenses", price)
							g_currentMission:addMoney(-price, vehicle:getOwnerFarmId(), MoneyType.PURCHASE_FUEL, true)
						end

						used = 0
					end

					if fillType == consumer.fillType then
						vehicle:addFillUnitFillLevel(vehicle:getOwnerFarmId(), consumer.fillUnitIndex, -used, fillType, ToolType.UNDEFINED)
					end
				end

				local usage = used / dt * 1000 * 60 * 60
                if timeScale ~= 0 then
                    usage = usage / timeScale
                end

				if consumer.fillType == FillType.DIESEL or consumer.fillType == FillType.ELECTRICCHARGE or consumer.fillType == FillType.METHANE then
					spec.lastFuelUsage = usage
				elseif consumer.fillType == FillType.DEF then
					spec.lastDefUsage = usage
				end
			end
		end
	end

	if spec.consumersByFillTypeName.AIR ~= nil then
		local consumer = spec.consumersByFillTypeName.AIR
		local fillType = vehicle:getFillUnitLastValidFillType(consumer.fillUnitIndex)

		if fillType == consumer.fillType then
			local usage = 0
			local direction = vehicle.movingDirection * vehicle:getReverserDirection()
			local forwardBrake = direction > 0 and accInput < 0
			local backwardBrake = direction < 0 and accInput > 0
			local brakeIsPressed = vehicle:getLastSpeed() > 1 and (forwardBrake or backwardBrake)

			if brakeIsPressed then
				local delta = math.abs(accInput) * dt * vehicle:getAirConsumerUsage() / 1000

				vehicle:addFillUnitFillLevel(vehicle:getOwnerFarmId(), consumer.fillUnitIndex, -delta, consumer.fillType, ToolType.UNDEFINED)

				usage = delta / dt * 1000
			end

			local fillLevelPercentage = vehicle:getFillUnitFillLevelPercentage(consumer.fillUnitIndex)

			if fillLevelPercentage < consumer.refillCapacityPercentage then
				consumer.doRefill = true
			elseif fillLevelPercentage == 1 then
				consumer.doRefill = false
			end

			if consumer.doRefill then
				local delta = consumer.refillLitersPerSecond / 1000 * dt

				vehicle:addFillUnitFillLevel(vehicle:getOwnerFarmId(), consumer.fillUnitIndex, delta, consumer.fillType, ToolType.UNDEFINED)

				usage = -delta / dt * 1000
			end

			spec.lastAirUsage = usage
		end
	end
end

function ADS_Breakdowns.updateConsumersOverwrite(vehicle, superFunc, dt, accInput)
    local spec_ads = vehicle.spec_AdvancedDamageSystem
    if spec_ads ~= nil and spec_ads.activeEffects ~= nil then
        local effect = spec_ads.activeEffects.FUEL_CONSUMPTION_MODIFIER
        if effect ~= nil and effect.value ~= nil then
            return ADS_Breakdowns.updateConsumers(vehicle, dt, accInput)
        end
    end
    return superFunc(vehicle, dt, accInput)
end

-- ==========================================================
-- TRANSMISSION_SLIP_EFFECT
ADS_Breakdowns.EffectApplicators.TRANSMISSION_SLIP_EFFECT = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying TRANSMISSION_SLIP_EFFECT:", effectData.value)
        local motor = vehicle:getMotor()
        if motor == nil then return end

        local spec_ads = vehicle.spec_AdvancedDamageSystem
        if spec_ads._origClutchSlippingTime == nil then
            spec_ads._origClutchSlippingTime = motor.clutchSlippingTime
        end
        motor.clutchSlippingTime = spec_ads._origClutchSlippingTime * (1 + effectData.value) ^ 3
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing TRANSMISSION_SLIP_EFFECT effect.")
        local motor = vehicle:getMotor()
        if motor == nil then return end

        local spec_ads = vehicle.spec_AdvancedDamageSystem
        if spec_ads._origClutchSlippingTime ~= nil then
            motor.clutchSlippingTime = spec_ads._origClutchSlippingTime
            spec_ads._origClutchSlippingTime = nil
        end
    end
}

-- CVT_SLIP_EFFECT
ADS_Breakdowns.EffectApplicators.CVT_SLIP_EFFECT = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying CVT_SLIP_EFFECT:", effectData.value)
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing CVT_SLIP_EFFECT effect.")
        local motor = vehicle:getMotor()
        if motor ~= nil then
            motor:setExternalTorqueVirtualMultiplicator(1)
        end
    end
}

-- CVT_MAX_RATIO_MODIFIER
ADS_Breakdowns.EffectApplicators.CVT_MAX_RATIO_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying CVT_MAX_RATIO_MODIFIER:", effectData.value)
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing CVT_MAX_RATIO_MODIFIER effect.")
    end
}

if VehicleMotor ~= nil and VehicleMotor.getMinMaxGearRatio ~= nil then
    VehicleMotor.getMinMaxGearRatio = Utils.overwrittenFunction(VehicleMotor.getMinMaxGearRatio, function(self, superFunc)
        local minRatio, maxRatio = superFunc(self)
        local vehicle = self.vehicle
        if vehicle == nil then return minRatio, maxRatio end

        local spec_ads = vehicle.spec_AdvancedDamageSystem
        if spec_ads == nil or spec_ads.activeEffects == nil then return minRatio, maxRatio end

        -- TRANSMISSION_SLIP_EFFECT
        local slipEffect = spec_ads.activeEffects.TRANSMISSION_SLIP_EFFECT
        if slipEffect ~= nil and slipEffect.value ~= nil then
            local modifier = tonumber(slipEffect.value) or 0

            if modifier >= 1 then
                return minRatio * 100, maxRatio * 100
            end

            local speedFactor = math.min(self.vehicle:getLastSpeed() / (self:getMaximumForwardSpeed() * 3.6), 1.0)

            if modifier > 0 and minRatio ~= 0 and speedFactor > 0.5 then
                local motorAccel = self.motorRotAccelerationSmoothed
                local accelerationFactor = math.min(math.max(0, motorAccel / self.motorRotationAccelerationLimit * 5), 1.0)

                slipEffect.extraData = slipEffect.extraData or {}
                slipEffect.extraData.accumulatedMod = slipEffect.extraData.accumulatedMod or 0
                if slipEffect.extraData.accumulatedMod < accelerationFactor then
                    slipEffect.extraData.accumulatedMod = math.min(slipEffect.extraData.accumulatedMod + 0.01 * (1 - math.min(speedFactor, 0.9)), 1.0)
                else
                    slipEffect.extraData.accumulatedMod = math.max(slipEffect.extraData.accumulatedMod - 0.01 * (1 - math.min(speedFactor, 0.9)), 0.0)
                end

                local dynamicModifier = modifier * slipEffect.extraData.accumulatedMod
                minRatio = minRatio * (1 + dynamicModifier)
                maxRatio = maxRatio * (1 + dynamicModifier)
            end
        end

        -- CVT_SLIP_EFFECT
        local cvtSlipEffect = spec_ads.activeEffects.CVT_SLIP_EFFECT
        local isSliping = false
        if cvtSlipEffect ~= nil and cvtSlipEffect.value ~= nil and self.minForwardGearRatio ~= nil then
            local modifier = tonumber(cvtSlipEffect.value) or 0

            if modifier >= 1 then
                return minRatio * 100, maxRatio * 100
            end

            cvtSlipEffect.extraData = cvtSlipEffect.extraData or {}
            local nowMs = (g_currentMission and g_currentMission.time) or 0
            local lastUpdateMs = tonumber(cvtSlipEffect.extraData.lastUpdateMs) or nowMs
            local dtSec = math.max((nowMs - lastUpdateMs) / 1000, 0)
            if dtSec > 1 then dtSec = 1 end
            cvtSlipEffect.extraData.lastUpdateMs = nowMs

            local lastAccelerationFactor = tonumber(cvtSlipEffect.extraData.lastAccelerationFactor) or 0
            local speedFactor = math.min(self.vehicle:getLastSpeed() / (self:getMaximumForwardSpeed() * 3.6 / 2), 1.0)
            local loadFactor = vehicle:getMotorLoadPercentage() + 0.2
            local massFactor = vehicle:getTotalMass() / vehicle:getTotalMass(true)

            if modifier > 0 and minRatio ~= 0 and maxRatio ~= 0 and speedFactor < 0.5 then
                local decatPerSecond = 0.01 / modifier * math.max(speedFactor, 0.1) * 1 / loadFactor * 1 / massFactor
                local motorAccel = self.motorRotAccelerationSmoothed
                local accelLimit = math.max(tonumber(self.motorRotationAccelerationLimit) or 0, 0.000001)
                local accelerationFactor = math.clamp(motorAccel / accelLimit, 0, 1)
                if accelerationFactor < lastAccelerationFactor then
                    accelerationFactor = math.clamp(lastAccelerationFactor - decatPerSecond * dtSec, 0, 1)
                end
                cvtSlipEffect.extraData.lastAccelerationFactor = accelerationFactor
                isSliping = accelerationFactor >= 0.98 and speedFactor < 0.8

                local clampMin = math.min(minRatio, minRatio * 10)
                local clampMax = math.max(minRatio, minRatio * 10)
                minRatio = math.clamp(self.gearRatio * accelerationFactor, clampMin, clampMax)
            end
        end

        -- CVT_MAX_RATIO_MODIFIER
        local cvtMaxEffect = spec_ads.activeEffects.CVT_MAX_RATIO_MODIFIER
        local speedFactor = math.min(self.vehicle:getLastSpeed() / (self:getMaximumForwardSpeed() * 3.6 / 2), 1.0)
        if cvtMaxEffect ~= nil and cvtMaxEffect.value ~= nil and self.minForwardGearRatio ~= nil and not isSliping and speedFactor > 0.5 then
            local value = tonumber(cvtMaxEffect.value) or 0
            minRatio = minRatio + minRatio * value * speedFactor
        end

        -- CVT_PRESSURE_DROP_CHANCE
        local pressureDropEffect = spec_ads.activeEffects.CVT_PRESSURE_DROP_CHANCE
        if pressureDropEffect ~= nil and pressureDropEffect.extraData ~= nil 
            and pressureDropEffect.extraData.status == "PROGRESS"
            and (pressureDropEffect.extraData.timer or 0) > 0 then
            minRatio = minRatio * 1.5
        end

        return minRatio, maxRatio
    end)
end

-- =========================================================
-- POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT
ADS_Breakdowns.EffectApplicators.POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT = {
    getEffectName = function()
        return "POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT" 
    end,

    apply = function(vehicle, effectData, handler)
        log_dbg("Applying POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT:", effectData.value)

        local effectName = handler.getEffectName()

        if vehicle.spec_AdvancedDamageSystem.activeFunctions[effectName] == nil then
            vehicle.spec_AdvancedDamageSystem.activeFunctions[effectName] = function(v, dt)
                
                if v:getIsMotorStarted() then
                    local spec = v.spec_AdvancedDamageSystem
                    local effect = spec.activeEffects.POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT
                    if effect and effect.value > 0 and effect.extraData.status ~= "IDLE" then
                        local motor = v:getMotor()
                        effect.extraData.timer = effect.extraData.timer + dt

                        if effect.extraData.timer > effect.value * 1000 and effect.extraData.status == "DELAYED" then
                            effect.extraData.timer = 0
                            effect.extraData.status = "PASSED"
                            if effect.extraData.backup then
                                effect.extraData.backup = motor.minGearRatio
                                motor.minGearRatio = 999.9
                            end
                            motor:applyTargetGear()
                        elseif effect.extraData.timer > effect.extraData.duration and effect.extraData.status == "PASSED" then
                            if effect.extraData.backup then
                                motor.minGearRatio = effect.extraData.backup
                            end
                            effect.extraData.status = "IDLE"
                        end
                    end
                end
            end
        end
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT effect.")

        local effectName = handler.getEffectName()
        if vehicle.spec_AdvancedDamageSystem.activeFunctions[effectName] ~= nil then
            vehicle.spec_AdvancedDamageSystem.activeFunctions[effectName] = nil
        end
    end
}

if VehicleMotor ~= nil and VehicleMotor.applyTargetGear ~= nil then
    VehicleMotor.applyTargetGear = Utils.overwrittenFunction(VehicleMotor.applyTargetGear, function(self, superFunc)
        local vehicle = self.vehicle
        if vehicle ~= nil then
            local spec_ads = vehicle.spec_AdvancedDamageSystem
            if spec_ads ~= nil and spec_ads.activeEffects ~= nil then
                local effect = spec_ads.activeEffects.POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT
                if effect ~= nil and effect.value ~= nil and effect.extraData.status == "IDLE" then
                    if effect.value >= 1.0 then
                        self.targetGear = self.previousGear
                        return superFunc(self)
                    end
                    effect.extraData.status = "DELAYED"
                    effect.extraData.timer = 0
                    return
                end
            end
        end
        return superFunc(self)
    end)
end

-- =========================================================

local function isHydraulicHoldDriftBlockedByFold(implement)
    if implement == nil then
        return false
    end

    if implement.getIsUnfolded ~= nil then
        local isUnfolded = implement:getIsUnfolded()
        if isUnfolded ~= nil then
            return not isUnfolded
        end
    end

    if implement.getFoldAnimTime ~= nil then
        local foldAnimTime = implement:getFoldAnimTime()
        if foldAnimTime ~= nil then
            return foldAnimTime < 0.99
        end
    end

    return false
end

local function setHydraulicHoldDriftSpeedLimitBypass(implement, enabled)
    if implement == nil or implement.doCheckSpeedLimit == nil then
        return
    end

    if implement.ads_holdDriftOrigDoCheckSpeedLimit == nil then
        implement.ads_holdDriftOrigDoCheckSpeedLimit = implement.doCheckSpeedLimit
        implement.doCheckSpeedLimit = function(obj, ...)
            if obj.ads_holdDriftBypassSpeedLimit == true then
                local attacherVehicle = obj.getAttacherVehicle ~= nil and obj:getAttacherVehicle() or nil
                if attacherVehicle ~= nil then
                    return false
                end
                obj.ads_holdDriftBypassSpeedLimit = false
            end

            local origFunc = obj.ads_holdDriftOrigDoCheckSpeedLimit
            if origFunc ~= nil then
                return origFunc(obj, ...)
            end

            return false
        end
    end

    implement.ads_holdDriftBypassSpeedLimit = enabled == true
end

local function restoreHydraulicHoldDriftSpeedLimitBypass(implement)
    if implement == nil then
        return
    end

    if implement.ads_holdDriftOrigDoCheckSpeedLimit ~= nil then
        implement.doCheckSpeedLimit = implement.ads_holdDriftOrigDoCheckSpeedLimit
        implement.ads_holdDriftOrigDoCheckSpeedLimit = nil
    end

    implement.ads_holdDriftBypassSpeedLimit = nil
end

-- HYDRAULIC_SPEED_MODIFIER
ADS_Breakdowns.EffectApplicators.HYDRAULIC_SPEED_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying HYDRAULIC_SPEED_MODIFIER effect")
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing HYDRAULIC_SPEED_MODIFIER effect.")
    end
}

-- HYDRAULIC_HOLD_DRIFT_EFFEC
ADS_Breakdowns.EffectApplicators.HYDRAULIC_HOLD_DRIFT_EFFECT = {
    getEffectName = function()
        return "HYDRAULIC_HOLD_DRIFT_EFFECT"
    end,

    apply = function(vehicle, effectData, handler)
        log_dbg("Applying HYDRAULIC_HOLD_DRIFT_EFFECT:", effectData.value)
        local activeFunc = function(v, dt) 
            if v.spec_attacherJoints and v.spec_attacherJoints.attachedImplements and next(v.spec_attacherJoints.attachedImplements) ~= nil then
                for _, implementData in pairs(v.spec_attacherJoints.attachedImplements) do
                    if implementData.object ~= nil then
                        local implement = implementData.object
                        local jointDescIndex = implementData.jointDescIndex
                        local jointDesc = v.spec_attacherJoints.attacherJoints[jointDescIndex]
                        local jointTypeId = jointDesc ~= nil and jointDesc.jointType or nil
                        if jointDesc ~= nil then
                            local driftBlockedByFold = isHydraulicHoldDriftBlockedByFold(implement)
                            local isLowered = implement:getIsLowered()
                            -- Clear auto-drift marker when movement has finished in lowered state
                            -- or user switched direction to raising / implement is folded.
                            if jointDesc.ads_holdDriftForced == true then
                                if driftBlockedByFold or (isLowered and not jointDesc.isMoving) or jointDesc.moveDown == false then
                                    jointDesc.ads_holdDriftForced = false
                                end
                            end

                            -- Force slow auto-drop only from raised idle state.
                            if not driftBlockedByFold and not isLowered and not jointDesc.isMoving and jointDesc.moveDown == false and jointTypeId == 1 then
                                jointDesc.ads_holdDriftForced = true
                                v:setJointMoveDown(jointDescIndex, true, false)
                            end

                            local bypassWorkSpeedLimit = jointDesc.ads_holdDriftForced == true and jointDesc.moveDown == true and jointDesc.isMoving == true and not driftBlockedByFold
                            if bypassWorkSpeedLimit then
                                setHydraulicHoldDriftSpeedLimitBypass(implement, true)
                            else
                                restoreHydraulicHoldDriftSpeedLimitBypass(implement)
                            end
                        end
                    end
                end
            end
        end
        addFuncToActive(vehicle, handler.getEffectName(), activeFunc)
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing HYDRAULIC_HOLD_DRIFT_EFFECT effect.")
        if vehicle.spec_attacherJoints ~= nil and vehicle.spec_attacherJoints.attachedImplements ~= nil then
            for _, implementData in pairs(vehicle.spec_attacherJoints.attachedImplements) do
                if implementData.object ~= nil then
                    restoreHydraulicHoldDriftSpeedLimitBypass(implementData.object)
                end

                local jointDesc = vehicle.spec_attacherJoints.attacherJoints[implementData.jointDescIndex]
                if jointDesc ~= nil then
                    jointDesc.ads_holdDriftForced = false
                end
            end
        end

        removeFuncFromActive(vehicle, handler.getEffectName())
    end
}

function ADS_Breakdowns.applyHydraulicDamageToAttacher(self, superFunc, dt, ...)
    local rootVehicle = self:getRootVehicle()
    local spec = self.spec_attacherJoints

    local hydraulicEffect = rootVehicle.spec_AdvancedDamageSystem and rootVehicle.spec_AdvancedDamageSystem.activeEffects.HYDRAULIC_SPEED_MODIFIER
    local hydraulicHoldEffect = rootVehicle.spec_AdvancedDamageSystem and rootVehicle.spec_AdvancedDamageSystem.activeEffects.HYDRAULIC_HOLD_DRIFT_EFFECT
    local hydraulicModifier = (hydraulicEffect and hydraulicEffect.value) or 0
    local hydraulicHoldModifier = (hydraulicHoldEffect and hydraulicHoldEffect.value) or 0
    
    if hydraulicModifier == 0 and hydraulicHoldModifier == 0 then
        return superFunc(self, dt, ...)
    end

    local raisePerformance = math.max(0.05, 1.0 + hydraulicModifier)
    local holdDriftPerformance = math.max(tonumber(hydraulicHoldModifier) or 0, 0.01)

    for _, implement in ipairs(spec.attachedImplements) do
        if implement.object ~= nil then
            local jointDesc = spec.attacherJoints[implement.jointDescIndex]
            
            if jointDesc.ads_originalMoveDefaultTime == nil then
                jointDesc.ads_originalMoveDefaultTime = jointDesc.moveDefaultTime
            end

            -- Player requested raising: immediately disable forced hold-drift path
            -- in this same tick, so upward movement uses raise/default speed.
            if jointDesc.ads_holdDriftForced == true and jointDesc.moveDown == false then
                jointDesc.ads_holdDriftForced = false
            end

            if jointDesc.moveDown == false and hydraulicModifier ~= 0 then
                -- HYDRAULIC_SPEED_MODIFIER: slow down raising only.
                jointDesc.moveDefaultTime = jointDesc.ads_originalMoveDefaultTime / raisePerformance
            elseif jointDesc.moveDown == true and jointDesc.ads_holdDriftForced == true and hydraulicHoldModifier > 0 then
                -- HYDRAULIC_HOLD_DRIFT_EFFECT: slow down only forced auto-drop.
                jointDesc.moveDefaultTime = jointDesc.ads_originalMoveDefaultTime / holdDriftPerformance
            else
                -- Manual lowering and any neutral state should stay at normal speed.
                jointDesc.moveDefaultTime = jointDesc.ads_originalMoveDefaultTime
            end
        end
    end

    local success, result = pcall(superFunc, self, dt, ...)

    for _, implement in ipairs(spec.attachedImplements) do
        if implement.object ~= nil then
            local jointDesc = spec.attacherJoints[implement.jointDescIndex]
            
            if jointDesc.ads_originalMoveDefaultTime ~= nil then
                jointDesc.moveDefaultTime = jointDesc.ads_originalMoveDefaultTime
            end
        end
    end

    if not success then
        print("ERROR in original AttacherJoints.onUpdateTick: " .. tostring(result))
    end

    return result
end


function ADS_Breakdowns.applyHydraulicDamageToCylindered(self, superFunc, dt, ...)
    local rootVehicle = self:getRootVehicle()
    local spec = self.spec_cylindered

    local hydraulicEffect = rootVehicle.spec_AdvancedDamageSystem and rootVehicle.spec_AdvancedDamageSystem.activeEffects.HYDRAULIC_SPEED_MODIFIER
    local hydraulicModifier = (hydraulicEffect and hydraulicEffect.value) or 0
    if hydraulicModifier == 0 then
        return superFunc(self, dt, ...)
    end

    local performance = math.max(0.05, 1.0 + hydraulicModifier)

    for _, tool in ipairs(spec.movingTools) do
        if tool.ads_originalSpeeds == nil then
            tool.ads_originalSpeeds = {
                rotSpeed = tool.rotSpeed,
                transSpeed = tool.transSpeed,
                animSpeed = tool.animSpeed
            }
        end
        
        if tool.rotSpeed ~= nil then
            tool.rotSpeed = tool.ads_originalSpeeds.rotSpeed * performance
        end
        if tool.transSpeed ~= nil then
            tool.transSpeed = tool.ads_originalSpeeds.transSpeed * performance
        end
        if tool.animSpeed ~= nil then
            tool.animSpeed = tool.ads_originalSpeeds.animSpeed * performance
        end
    end

    local success, result = pcall(superFunc, self, dt, ...)

    for _, tool in ipairs(spec.movingTools) do
        if tool.ads_originalSpeeds ~= nil then
            if tool.rotSpeed ~= nil then
                tool.rotSpeed = tool.ads_originalSpeeds.rotSpeed
            end
            if tool.transSpeed ~= nil then
                tool.transSpeed = tool.ads_originalSpeeds.transSpeed
            end
            if tool.animSpeed ~= nil then
                tool.animSpeed = tool.ads_originalSpeeds.animSpeed
            end
        end
    end

    if not success then
        log_dbg("ERROR in original Cylindered.onUpdate: " .. tostring(result))
    end

    return result
end


function ADS_Breakdowns.applyHydraulicDamageToFoldable(self, superFunc, direction, moveToMiddle, noEventSend)
    local rootVehicle = self:getRootVehicle()
    local spec = self.spec_foldable

    local hydraulicEffect = rootVehicle.spec_AdvancedDamageSystem and rootVehicle.spec_AdvancedDamageSystem.activeEffects.HYDRAULIC_SPEED_MODIFIER
    local hydraulicModifier = (hydraulicEffect and hydraulicEffect.value) or 0
    if hydraulicModifier == 0 then
        return superFunc(self, direction, moveToMiddle, noEventSend)
    end

    local performance = math.max(0.05, 1.0 + hydraulicModifier)

    for _, foldingPart in ipairs(spec.foldingParts) do
        if foldingPart.ads_originalSpeedScale == nil then
            foldingPart.ads_originalSpeedScale = foldingPart.speedScale
        end

        foldingPart.speedScale = foldingPart.ads_originalSpeedScale * performance
    end


    local success, result = pcall(superFunc, self, direction, moveToMiddle, noEventSend)

    for _, foldingPart in ipairs(spec.foldingParts) do
        if foldingPart.ads_originalSpeedScale ~= nil then
            foldingPart.speedScale = foldingPart.ads_originalSpeedScale
        end
    end

    if not success then
        log_dbg("ERROR in original Foldable.setFoldState: " .. tostring(result))
    end

    return result
end


function ADS_Breakdowns.applyHydraulicDamageToPlowRotation(self, superFunc, rotationMax, noEventSend, turnAnimationTime)
    local rootVehicle = self:getRootVehicle()
    local hydraulicEffect = rootVehicle.spec_AdvancedDamageSystem and rootVehicle.spec_AdvancedDamageSystem.activeEffects.HYDRAULIC_SPEED_MODIFIER
    local hydraulicModifier = (hydraulicEffect and hydraulicEffect.value) or 0
    
    if hydraulicModifier == 0 then
        return superFunc(self, rotationMax, noEventSend, turnAnimationTime)
    end

    local performance = math.max(0.05, 1.0 + hydraulicModifier)

    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(PlowRotationEvent.new(self, rotationMax), nil, self)
        else
            g_client:getServerConnection():sendEvent(PlowRotationEvent.new(self, rotationMax))
        end
    end

    local spec = self.spec_plow
    spec.rotationMax = rotationMax

    if spec.rotationPart.turnAnimation ~= nil then
        if turnAnimationTime == nil then
            local animTime = self:getAnimationTime(spec.rotationPart.turnAnimation)
            
            if spec.rotationMax then
                self:playAnimation(spec.rotationPart.turnAnimation, 1 * performance, animTime, true)
            else
                self:playAnimation(spec.rotationPart.turnAnimation, -1 * performance, animTime, true)
            end
        else
            self:setAnimationTime(spec.rotationPart.turnAnimation, turnAnimationTime, true)
        end
    end
end


function ADS_Breakdowns.applyHydraulicDamageToPlowCenterRotation(self, superFunc)
    local rootVehicle = self:getRootVehicle()
    local hydraulicEffect = rootVehicle.spec_AdvancedDamageSystem and rootVehicle.spec_AdvancedDamageSystem.activeEffects.HYDRAULIC_SPEED_MODIFIER
    local hydraulicModifier = (hydraulicEffect and hydraulicEffect.value) or 0
    
    if hydraulicModifier == 0 then
        return superFunc(self)
    end

    local performance = math.max(0.05, 1.0 + hydraulicModifier)

    local spec = self.spec_plow

    if spec.rotationPart.turnAnimation ~= nil then
        self:setAnimationStopTime(spec.rotationPart.turnAnimation, spec.ai.centerPosition)

        local animTime = self:getAnimationTime(spec.rotationPart.turnAnimation)

        if animTime < spec.ai.centerPosition then
            self:playAnimation(spec.rotationPart.turnAnimation, 1 * performance, animTime, true)
        elseif spec.ai.centerPosition < animTime then
            self:playAnimation(spec.rotationPart.turnAnimation, -1 * performance, animTime, true)
        end
    end
end

do
    if not ADS_Breakdowns._hydraulicSpeedHooksInstalled then
        local hydraulicSpeedHookDefs = {
            { objectName = "Plow", field = "setRotationMax", wrapperName = "applyHydraulicDamageToPlowRotation" },
            { objectName = "Plow", field = "setRotationCenter", wrapperName = "applyHydraulicDamageToPlowCenterRotation" },
            { objectName = "AttacherJoints", field = "onUpdateTick", wrapperName = "applyHydraulicDamageToAttacher" },
            { objectName = "Cylindered", field = "onUpdate", wrapperName = "applyHydraulicDamageToCylindered" },
            { objectName = "Foldable", field = "setFoldState", wrapperName = "applyHydraulicDamageToFoldable" }
        }

        for _, def in ipairs(hydraulicSpeedHookDefs) do
            local targetObject = _G[def.objectName]
            local wrapperFunc = ADS_Breakdowns[def.wrapperName]
            if targetObject ~= nil and targetObject[def.field] ~= nil and wrapperFunc ~= nil then
                targetObject[def.field] = Utils.overwrittenFunction(targetObject[def.field], wrapperFunc)
                log_dbg("HYDRAULIC hook installed:", string.format("%s.%s", def.objectName, def.field))
            else
                log_dbg("HYDRAULIC hook skipped:", string.format("%s.%s", def.objectName, def.field))
            end
        end

        ADS_Breakdowns._hydraulicSpeedHooksInstalled = true
    end
end

-- =========================================================
-- MAX_SPEED_MODIFIER
ADS_Breakdowns.EffectApplicators.MAX_SPEED_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying MAX_SPEED_MODIFIER effect")
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing MAX_SPEED_MODIFIER effect.")
    end
}

function ADS_Breakdowns.getSpeedLimitOverwrite(vehicle, superFunc, onlyIfWorking)
    local speedLimit, doCheckSpeedLimit = superFunc(vehicle, onlyIfWorking)

    local spec_ads = vehicle.spec_AdvancedDamageSystem
    if spec_ads == nil or spec_ads.activeEffects == nil then
        return speedLimit, doCheckSpeedLimit
    end

    local effect = spec_ads.activeEffects.MAX_SPEED_MODIFIER
    local reduction = 0
    if effect ~= nil and effect.value ~= nil then
        reduction = math.clamp(tonumber(effect.value) or 0, 0, 0.99)
    end

    -- dragging trailer brakes also pull the top speed down while towing
    local _, trailerBrakeDrag = ADS_Breakdowns.getTrailerBrakeState(vehicle)
    if trailerBrakeDrag > 0 then
        reduction = math.max(reduction, math.clamp(trailerBrakeDrag * 0.5, 0, 0.99))
    end

    if reduction <= 0 then
        return speedLimit, doCheckSpeedLimit
    end

    local motor = vehicle:getMotor()

    if speedLimit == nil or speedLimit >= math.huge then
        local baseMaxMps = nil
        if motor ~= nil then
            baseMaxMps = tonumber(motor.maxForwardSpeedOrigin)
                or tonumber(motor.maxForwardSpeed)
                or (motor.getMaximumForwardSpeed ~= nil and tonumber(motor:getMaximumForwardSpeed()) or nil)
        end
        if baseMaxMps ~= nil then
            speedLimit = baseMaxMps * 3.6
        end
    end

    if speedLimit ~= nil and speedLimit < math.huge then
        speedLimit = speedLimit - speedLimit * reduction
    end

    return speedLimit or math.huge, doCheckSpeedLimit
end

-- =========================================================
-- YIELD_REDUCTION_MODIFIER
ADS_Breakdowns.EffectApplicators.YIELD_REDUCTION_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying YIELD_REDUCTION_MODIFIER effect")
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing YIELD_REDUCTION_MODIFIER effect.")
    end
}

function ADS_Breakdowns.addCutterAreaOverwrite(vehicle, superFunc, area, realArea, ...)
    local spec_ads = vehicle.spec_AdvancedDamageSystem
    local workprocessDbg = spec_ads ~= nil and spec_ads.debugData ~= nil and spec_ads.debugData.workprocess or nil
    if workprocessDbg ~= nil then
        workprocessDbg.currentHarvestRatio = 1.0
        workprocessDbg.currentHarvestPercent = 100.0
    end

    if spec_ads ~= nil and spec_ads.activeEffects ~= nil then
        local effect = spec_ads.activeEffects.YIELD_REDUCTION_MODIFIER
        if effect ~= nil and effect.value ~= nil then
            local spec_combine = vehicle.spec_combine
            if spec_combine ~= nil then
                local originalScale = spec_combine.threshingScale
                local currentHarvestRatio = math.max(1 + effect.value, 0)
                if workprocessDbg ~= nil then
                    workprocessDbg.currentHarvestRatio = currentHarvestRatio
                    workprocessDbg.currentHarvestPercent = currentHarvestRatio * 100
                end
                spec_combine.threshingScale = math.max(originalScale * currentHarvestRatio, 0)
                local result = superFunc(vehicle, area, realArea, ...)
                spec_combine.threshingScale = originalScale
                return result
            end
        end
    end
    return superFunc(vehicle, area, realArea, ...)
end

-- =========================================================
-- UNLOADING_SPEED_MODIFIER
ADS_Breakdowns.EffectApplicators.UNLOADING_SPEED_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying UNLOADING_SPEED_MODIFIER effect")
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing UNLOADING_SPEED_MODIFIER effect.")
    end
}

function ADS_Breakdowns.getDischargeNodeEmptyFactorOverwrite(vehicle, superFunc, dischargeNode, ...)
    local originalFactor = superFunc(vehicle, dischargeNode, ...)
    local spec_ads = vehicle.spec_AdvancedDamageSystem
    local workprocessDbg = spec_ads ~= nil and spec_ads.debugData ~= nil and spec_ads.debugData.workprocess or nil
    local currentFactor = originalFactor

    if spec_ads ~= nil and spec_ads.activeEffects ~= nil then
        local effect = spec_ads.activeEffects.UNLOADING_SPEED_MODIFIER
        if effect ~= nil and effect.value ~= nil then
            currentFactor = originalFactor * (1 + effect.value)
        end
    end

    if workprocessDbg ~= nil then
        workprocessDbg.lastUnloadOriginalFactor = originalFactor
        workprocessDbg.lastUnloadFactor = currentFactor
        workprocessDbg.lastUnloadPercent = originalFactor > 0 and (currentFactor / originalFactor) * 100 or 100
    end

    return currentFactor
end

-- ==========================================================
-- CONDITION_WEAR_MODIFIER
ADS_Breakdowns.EffectApplicators.CONDITION_WEAR_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying CONDITION_WEAR_MODIFIER:", effectData.value)
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.extraConditionWear = effectData.value
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing CONDITION_WEAR_MODIFIER effect.")
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.extraConditionWear = 0
    end
}

-- SERVICE_WEAR_MODIFIER
ADS_Breakdowns.EffectApplicators.SERVICE_WEAR_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying SERVICE_WEAR_MODIFIER:", effectData.value)
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.extraServiceWear = effectData.value
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing SERVICE_WEAR_MODIFIER effect.")
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.extraServiceWear = 0
    end
}

-- BREAKDOWN_PROBABILITIES_MODIFIER
ADS_Breakdowns.EffectApplicators.BREAKDOWN_PROBABILITIES_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying BREAKDOWN_PROBABILITIES_MODIFIER:", effectData.value)
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.extraBreakdownProbability = effectData.value
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing BREAKDOWN_PROBABILITIES_MODIFIER effect.")
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.extraBreakdownProbability = 0
    end
}

-- ENGINE_HEAT_MODIFIER 
ADS_Breakdowns.EffectApplicators.ENGINE_HEAT_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying ENGINE_HEAT_MODIFIER:", effectData.value)
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.extraEngineHeat = effectData.value
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing ENGINE_HEAT_MODIFIER effect.")
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.extraEngineHeat = 0
    end
}

-- TRANASMISSION_HEAT_MODIFIER
ADS_Breakdowns.EffectApplicators.TRANASMISSION_HEAT_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying TRANASMISSION_HEAT_MODIFIER:", effectData.value)
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.extraTransmissionHeat = effectData.value
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing TRANASMISSION_HEAT_MODIFIER effect.")
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.extraTransmissionHeat = 0
    end
}

-- THERMOSTAT_HEALTH_MODIFIER
ADS_Breakdowns.EffectApplicators.THERMOSTAT_HEALTH_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying THERMOSTAT_HEALTH_MODIFIER:", effectData.value)
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.thermostatHealth = math.max(1.0 + effectData.value, 0.1)
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing THERMOSTAT_HEALTH_MODIFIER effect.")
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.thermostatHealth = 1.0
    end
}

-- RADIATOR_HEALTH_MODIFIER
ADS_Breakdowns.EffectApplicators.RADIATOR_HEALTH_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying RADIATOR_HEALTH_MODIFIER:", effectData.value)
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.radiatorHealth = math.max(1.0 + effectData.value, 0.1)
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing RADIATOR_HEALTH_MODIFIER effect.")
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.radiatorHealth = 1.0
    end
}

-- BATTERY_HEALTH_MODIFIER
ADS_Breakdowns.EffectApplicators.BATTERY_HEALTH_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying BATTERY_HEALTH_MODIFIER:", effectData.value)
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.batteryHealth = math.max(1.0 + effectData.value, 0.0001)
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing BATTERY_HEALTH_MODIFIER effect.")
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.batteryHealth = 1.0
    end
}

-- ALTERNATOR_HEALTH_MODIFIER
ADS_Breakdowns.EffectApplicators.ALTERNATOR_HEALTH_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying ALTERNATOR_HEALTH_MODIFIER:", effectData.value)
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.alternatorHealth = math.max(1.0 + effectData.value, 0.0001)
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing ALTERNATOR_HEALTH_MODIFIER effect.")
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.alternatorHealth = 1.0
    end
}

-- FAN_CLUTCH_MODIFIER
ADS_Breakdowns.EffectApplicators.FAN_CLUTCH_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying FAN_CLUTCH_MODIFIER:", effectData.value)
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.fanClutchHealth = math.max(1.0 + effectData.value, 0.1)
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing FAN_CLUTCH_MODIFIER effect.")
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.fanClutchHealth = 1.0
    end
}

-- THERMOSTAT_STUCK_EFFECT
ADS_Breakdowns.EffectApplicators.THERMOSTAT_STUCK_EFFECT = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying THERMOSTAT_STUCK_EFFECT")
        local spec = vehicle.spec_AdvancedDamageSystem


        if spec.thermostatStuckedPosition == nil or spec.thermostatStuckedPosition < 0 then
            spec.thermostatStuckedPosition = spec.thermostatState
        end
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing THERMOSTAT_STUCK_EFFECT")
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.thermostatStuckedPosition = nil
    end
}

-- ==========================================================
-- IDLE_HUNTING_EFFECT
ADS_Breakdowns.EffectApplicators.IDLE_HUNTING_EFFECT = {
    getEffectName = function()
        return "IDLE_HUNTING_EFFECT" 
    end,

    apply = function(vehicle, effectData, handler)
        log_dbg("Applying IDLE_HUNTING_EFFECT effect")

        local effectName = handler.getEffectName()
        local motor = vehicle:getMotor()
        effectData.extraData.rpmBackup = motor.minRpm

        local activeFunc = function(v, dt)
            if v:getIsMotorStarted() and v:getLastSpeed() < 0.01 then
                if effectData.extraData.rpmBackup == 0 then
                    effectData.extraData.rpmBackup = motor.minRpm
                end
                effectData.extraData.timer = effectData.extraData.timer + dt
                motor.minRpm = effectData.extraData.rpmBackup * (1 + effectData.value * math.sin(2 * math.pi * effectData.extraData.timer / effectData.extraData.period))
            else
                if effectData.extraData.rpmBackup ~= 0 and  effectData.extraData.rpmBackup ~= motor.minRpm then
                    motor.minRpm = effectData.extraData.rpmBackup
                    effectData.extraData.timer = 0
                end
            end
        end
        addFuncToActive(vehicle, effectName, activeFunc)
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing IDLE_HUNTING_EFFECT effect")
        removeFuncFromActive(vehicle, handler.getEffectName())
    end
}

-- ==========================================================
-- DARK_EXHAUST_EFFECT
ADS_Breakdowns.EffectApplicators.DARK_EXHAUST_EFFECT = {    
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying DARK_EXHAUST_EFFECT effect")
        local originalMinRpmColorName = "exhaustEffectsMinRpmColor"
        local originalMaxRpmColorName = "exhaustEffectsMaxRpmColor"
        local effect = vehicle.spec_motorized.exhaustEffects[#vehicle.spec_motorized.exhaustEffects]

        if effect == nil or effect.minRpmColor == nil or effect.maxRpmColor == nil then
            return
        end
        
        if vehicle.spec_AdvancedDamageSystem.originalFunctions[originalMinRpmColorName] == nil then
            vehicle.spec_AdvancedDamageSystem.originalFunctions[originalMinRpmColorName] = { 
                effect.minRpmColor[1],
                effect.minRpmColor[2],
                effect.minRpmColor[3],
                effect.minRpmColor[4]
            }
        end
        if vehicle.spec_AdvancedDamageSystem.originalFunctions[originalMaxRpmColorName] == nil then
            vehicle.spec_AdvancedDamageSystem.originalFunctions[originalMaxRpmColorName] = {
                effect.maxRpmColor[1],
                effect.maxRpmColor[2],
                effect.maxRpmColor[3],
                effect.maxRpmColor[4]
            }
        end

        local originalMinRpmColorValue = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalMinRpmColorName]
        local originalMaxRpmColorValue = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalMaxRpmColorName]
        
	    if effect ~= nil then
		    effect.minRpmColor = {0.015, 0.015, 0.02, originalMinRpmColorValue[4] * effectData.value * 6}
		    effect.maxRpmColor = {0.015, 0.015, 0.02, originalMaxRpmColorValue[4] * effectData.value * 12}
	    end

    end,

    remove = function(vehicle, handler)
        log_dbg("Removing DARK_EXHAUST_EFFECT effect")
        local originalMinRpmColorName = "exhaustEffectsMinRpmColor"
        local originalMaxRpmColorName = "exhaustEffectsMaxRpmColor"
        local originalMinRpmColorValue = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalMinRpmColorName]
        local originalMaxRpmColorValue = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalMaxRpmColorName]
        local effect = vehicle.spec_motorized.exhaustEffects[#vehicle.spec_motorized.exhaustEffects]
        if originalMinRpmColorValue ~= nil then
            effect.minRpmColor[1] = originalMinRpmColorValue[1]
            effect.minRpmColor[2] = originalMinRpmColorValue[2]
            effect.minRpmColor[3] = originalMinRpmColorValue[3]
            effect.minRpmColor[4] = originalMinRpmColorValue[4]
            vehicle.spec_AdvancedDamageSystem.originalFunctions[originalMinRpmColorName] = nil
        end
        if originalMaxRpmColorValue ~= nil then
            effect.maxRpmColor[1] = originalMaxRpmColorValue[1]
            effect.maxRpmColor[2] = originalMaxRpmColorValue[2]
            effect.maxRpmColor[3] = originalMaxRpmColorValue[3]
            effect.maxRpmColor[4] = originalMaxRpmColorValue[4]
            vehicle.spec_AdvancedDamageSystem.originalFunctions[originalMaxRpmColorName] = nil
        end
    end
}

-- ==========================================================
-- ELECTRICAL_CONTACT_RESISTANCE_EFFECT
ADS_Breakdowns.EffectApplicators.ELECTRICAL_CONTACT_RESISTANCE_EFFECT = {
    getEffectName = function()
        return "ELECTRICAL_CONTACT_RESISTANCE_EFFECT" 
    end,

    apply = function(vehicle, effectData, handler)
        log_dbg("Applying ELECTRICAL_CONTACT_RESISTANCE_EFFECT effect")

        local effectName = handler.getEffectName()

        local activeFunc = function(v, dt)
                local spec = v.spec_AdvancedDamageSystem
                local effect = spec.activeEffects.ELECTRICAL_CONTACT_RESISTANCE_EFFECT
                if v.isServer and v:getIsMotorStarted() then
                    if effect and effect.value > 0 then
                        if effect.extraData.status == "IDLE" then
                            local chance = ADS_Utils.getChancePerFrameFromMeanTime(dt, effect.value)
                            if math.random() < chance then
                                effect.extraData.status = "SHORTC"
                                effect.extraData.timer = 1000
                                spec.extraCurrentPeak = 1000
                            end
                        elseif effect.extraData.status == "SHORTC" then
                            effect.extraData.timer = math.max(effect.extraData.timer - dt, 0)
                            if effect.extraData.timer <= 0 then
                                effect.extraData.status = "IDLE"
                                effect.extraData.timer = 0
                                spec.extraCurrentPeak = 0
                            end
                        end
                    end
                else
                    spec.extraCurrentPeak = 0
                end
            end
        addFuncToActive(vehicle, effectName, activeFunc)
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing ELECTRICAL_CONTACT_RESISTANCE_EFFECT effect")
        removeFuncFromActive(vehicle, handler.getEffectName())
    end
}



-- ==========================================================
-- SOUND_EFFECTS

local function adsStopAndResetNoiseSample(sample)
    if sample == nil then return end
    if g_soundManager:getIsSamplePlaying(sample) then
        g_soundManager:stopSample(sample, 0, 0)
    end
    g_soundManager:setSampleVolumeOffset(sample, 0)
    g_soundManager:setSamplePitchOffset(sample, 0)
    if sample.adsOriginalLoops ~= nil then
        sample.loops = sample.adsOriginalLoops
    end
    if sample.adsOriginalVolumeScale ~= nil then
        sample.volumeScale = sample.adsOriginalVolumeScale
    end
end

local function adsUpdateNoiseGate(spec, effectName, targetGate, dt)
    spec.__adsNoiseGates = spec.__adsNoiseGates or {}
    local previousGate = math.clamp(tonumber(spec.__adsNoiseGates[effectName]) or 0, 0, 1)
    local attackMs = 220
    local releaseMs = 520
    local responseMs = targetGate > previousGate and attackMs or releaseMs
    local alpha = math.min((tonumber(dt) or 0) / math.max(responseMs, 1), 1)
    local gate = previousGate + (targetGate - previousGate) * alpha
    gate = math.clamp(gate, 0, 1)
    spec.__adsNoiseGates[effectName] = gate
    return gate
end

local function createEngineNoiseEffectApplicator(effectName, sampleName, gateMode)
    return {
        getEffectName = function()
            return effectName
        end,

        apply = function(vehicle, effectData, handler)
            log_dbg(string.format("Applying %s effect", effectName))
            local activeFunc = function(v, dt)
                local spec_ads = v.spec_AdvancedDamageSystem
                if spec_ads == nil or spec_ads.samples == nil then return end
                local motor = v:getMotor()
                if motor == nil then return end

                local sample = spec_ads.samples[sampleName]
                if sample == nil then return end

                local currentEffect = spec_ads.activeEffects and spec_ads.activeEffects[effectName]
                local baseVolumeScale = math.clamp(tonumber(currentEffect and currentEffect.value) or tonumber(effectData.value) or 1, 0, 2)

                if not v:getIsMotorStarted() then
                    adsStopAndResetNoiseSample(sample)
                    if spec_ads.__adsNoiseGates ~= nil then
                        spec_ads.__adsNoiseGates[effectName] = nil
                    end
                    return
                end

                local minRpm = tonumber(motor.minRpm) or 800
                local maxRpm = math.max(tonumber(motor.maxRpm) or (minRpm + 1), minRpm + 1)
                local lastRpm = (motor.getLastModulatedMotorRpm ~= nil and tonumber(motor:getLastModulatedMotorRpm())) or tonumber(motor.lastMotorRpm) or minRpm
                local rpmN = math.clamp((lastRpm - minRpm) / (maxRpm - minRpm), 0, 1)
                local loadN = math.clamp(tonumber(v:getMotorLoadPercentage()) or 0, 0, 1)
                local accelN = math.clamp(math.abs(tonumber(motor.lastAcceleratorPedal) or 0), 0, 1)
                local hotN = math.clamp(((tonumber(spec_ads.engineTemperature) or 0) - 70) / 40, 0, 1)
                local speedMps = tonumber(v:getLastSpeed()) or 0

                local dynamicIntensity =
                    (0.30 + 0.70 * rpmN)
                    * (0.65 + 0.35 * loadN)
                    * (0.70 + 0.30 * hotN)
                dynamicIntensity = math.clamp(dynamicIntensity, 0, 1.6)

                local gate = 1
                if gateMode == "accel" then
                    local accelThreshold = 0.02
                    local targetGate = math.clamp((accelN - accelThreshold) / (1 - accelThreshold), 0, 1)
                    gate = adsUpdateNoiseGate(spec_ads, effectName, targetGate, dt)
                    baseVolumeScale = baseVolumeScale * gate
                elseif gateMode == "speed" then
                    local speedThresholdMps = 0.20
                    local fullSpeedMps = 2.00
                    local targetGate = math.clamp((speedMps - speedThresholdMps) / (fullSpeedMps - speedThresholdMps), 0, 1)
                    gate = adsUpdateNoiseGate(spec_ads, effectName, targetGate, dt)
                    baseVolumeScale = baseVolumeScale * gate
                end

                if baseVolumeScale <= 0.02 then
                    if (gateMode == "accel" or gateMode == "speed") and gate > 0.001 then
                        baseVolumeScale = 0.02
                    else
                        adsStopAndResetNoiseSample(sample)
                        if spec_ads.__adsNoiseGates ~= nil then
                            spec_ads.__adsNoiseGates[effectName] = nil
                        end
                        return
                    end
                end

                if sample.adsOriginalLoops == nil then
                    sample.adsOriginalLoops = sample.loops
                end
                if sample.adsOriginalVolumeScale == nil then
                    sample.adsOriginalVolumeScale = sample.volumeScale
                end
                sample.loops = 0
                sample.volumeScale = sample.adsOriginalVolumeScale * baseVolumeScale

                if not g_soundManager:getIsSamplePlaying(sample) then
                    g_soundManager:playSample(sample)
                end

                g_soundManager:setSampleVolumeOffset(sample, 0)
                local pitchOffset
                if sampleName == "turboWhistle" then
                    local accelThreshold = 0.02
                    local accelGate = math.clamp((accelN - accelThreshold) / (1 - accelThreshold), 0, 1)
                    pitchOffset = (0.20 * accelGate + 0.16 * (rpmN ^ 1.20) * accelGate + 0.03 * loadN * accelGate) * gate
                elseif sampleName == "fanNoice" then
                    pitchOffset = 0
                elseif sampleName == "wheelHubBearingNoise" then
                    local speedN = math.clamp(speedMps / 15.0, 0, 1)
                    pitchOffset = (0.12 * (speedN ^ 1.10) + 0.03 * loadN * speedN) * gate
                elseif sampleName == "wheelSeizureGrind" then
                    local speedN = math.clamp(speedMps / 12.0, 0, 1)
                    pitchOffset = (0.06 * (speedN ^ 1.05) + 0.05 * loadN * speedN) * gate
                elseif sampleName == "vibrationNoice" then
                    local speedN = math.clamp(speedMps / 15.0, 0, 1)
                    pitchOffset = (0.08 * (speedN ^ 1.05) + 0.02 * loadN * speedN) * gate
                else
                    pitchOffset = 0.24 * (rpmN ^ 1.35) + 0.04 * dynamicIntensity * rpmN
                end
                g_soundManager:setSamplePitchOffset(sample, pitchOffset)
            end

            addFuncToActive(vehicle, effectName, activeFunc)
        end,

        remove = function(vehicle, handler)
            log_dbg(string.format("Removing %s effect", effectName))
            local spec_ads = vehicle.spec_AdvancedDamageSystem
            if spec_ads ~= nil and spec_ads.samples ~= nil then
                adsStopAndResetNoiseSample(spec_ads.samples[sampleName])
                if spec_ads.__adsNoiseGates ~= nil then
                    spec_ads.__adsNoiseGates[effectName] = nil
                end
            end
            removeFuncFromActive(vehicle, handler.getEffectName())
        end
    }
end

ADS_Breakdowns.EffectApplicators.ENGINE_KNOCKING_NOISE_EFFECT = createEngineNoiseEffectApplicator("ENGINE_KNOCKING_NOISE_EFFECT", "engineKnocking", nil)
ADS_Breakdowns.EffectApplicators.VALVE_TRAIN_NOISE_EFFECT = createEngineNoiseEffectApplicator("VALVE_TRAIN_NOISE_EFFECT", "valveTrainNoise", nil)
ADS_Breakdowns.EffectApplicators.TURBO_WHISTLE_NOISE_EFFECT = createEngineNoiseEffectApplicator("TURBO_WHISTLE_NOISE_EFFECT", "turboWhistle", "accel")
ADS_Breakdowns.EffectApplicators.FAN_CLUTCH_NOISE_EFFECT = createEngineNoiseEffectApplicator("FAN_CLUTCH_NOISE_EFFECT", "fanNoice", nil)
ADS_Breakdowns.EffectApplicators.VIBRATION_NOISE_EFFECT = createEngineNoiseEffectApplicator("VIBRATION_NOISE_EFFECT", "vibrationNoice", "speed")
ADS_Breakdowns.EffectApplicators.WHEEL_HUB_BEARING_NOISE_EFFECT = createEngineNoiseEffectApplicator("WHEEL_HUB_BEARING_NOISE_EFFECT", "wheelHubBearingNoise", "speed")
ADS_Breakdowns.EffectApplicators.WHEEL_SEIZURE_GRIND_NOISE_EFFECT = createEngineNoiseEffectApplicator("WHEEL_SEIZURE_GRIND_NOISE_EFFECT", "wheelSeizureGrind", "speed")


-- ==========================================================
-- CVT_PRESSURE_DROP_CHANCE
ADS_Breakdowns.EffectApplicators.CVT_PRESSURE_DROP_CHANCE = {
    getEffectName = function()
        return "CVT_PRESSURE_DROP_CHANCE"
    end,

    apply = function(vehicle, effectData, handler)
        log_dbg("Applying CVT_PRESSURE_DROP_CHANCE:", effectData.value)
        local motor = vehicle:getMotor()
        if motor == nil then return end
        if motor.minForwardGearRatio == nil then return end
        local effectName = handler.getEffectName()

        local activeFunc = function(v, dt)

            if v:getIsMotorStarted() and v:getLastSpeed() > 1 then
                local effect = v.spec_AdvancedDamageSystem.activeEffects.CVT_PRESSURE_DROP_CHANCE
                if effect == nil then
                    return
                end
                effect.extraData = effect.extraData or {}
                effect.extraData.status = tostring(effect.extraData.status or "IDLE")
                effect.extraData.timer = tonumber(effect.extraData.timer) or 0
                effect.extraData.duration = tonumber(effect.extraData.duration) or 200

                if v.isServer and effect.extraData.status == 'IDLE' and math.random() < ADS_Utils.getChancePerFrameFromMeanTime(dt, effect.value) then
                    effect.extraData.status = 'DROP'
                    effect.extraData.timer = effect.extraData.duration

                    ADS_EffectSyncEvent.send(v, handler.getEffectName(), "DROP", effect.extraData.timer, 0, 0)
                end
                if effect.extraData.status == 'DROP' and effect.extraData.timer > 0 then
                    effect.extraData.status = 'PROGRESS'
                end
                if effect.extraData.status == 'PROGRESS' then
                    effect.extraData.timer = effect.extraData.timer - dt
                end
                if effect.extraData.timer <= 0 then
                    effect.extraData.timer = 0
                    effect.extraData.status = 'IDLE'
                end
            end
        end
        addFuncToActive(vehicle, effectName, activeFunc)
    end,

    remove = function(vehicle, handler)
        removeFuncFromActive(vehicle, handler.getEffectName())
    end
}

-- ==========================================================
-- ENGINE_STALLS_CHANCE
ADS_Breakdowns.EffectApplicators.ENGINE_STALLS_CHANCE = {
    getEffectName = function() return "ENGINE_STALLS_CHANCE" end,
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying ENGINE_STALLS_CHANCE effect.")
        local effectName = handler.getEffectName()
        local activeFunc = function(v, dt)

            if not v.isServer then return end

            if v:getIsMotorStarted() then
                local effect = v.spec_AdvancedDamageSystem.activeEffects.ENGINE_STALLS_CHANCE
                if effect and effect.value > 0 then
                    if math.random() < ADS_Utils.getChancePerFrameFromMeanTime(dt, effect.value) then
                        if v.stopMotor then
                            -- tell the stall logger (ADS_FluidSystem) which fault did it;
                            -- the "engine stalled" message below already covers the screen
                            local causeText = "ADS fault stalled the engine"
                            if ADS_FluidSystem ~= nil and ADS_FluidSystem.getStallBreakdowns ~= nil then
                                local names = {}
                                for _, f in ipairs(ADS_FluidSystem.getStallBreakdowns(v)) do
                                    table.insert(names, f.visible and string.format("%s stage %d", f.name, f.stage) or "undiagnosed fault - run an inspection")
                                end
                                if #names > 0 then causeText = causeText .. ": " .. table.concat(names, ", ") end
                            end
                            v.adsStopCause = causeText
                            v:stopMotor()

                            ADS_EffectSyncEvent.send(v, "ENGINE_STALLS_CHANCE", "STALLED")

                            if v:getIsActiveForInput(true) then
                                g_currentMission:showBlinkingWarning(g_i18n:getText("ads_breakdowns_engine_stalled_message"), 5000) 
                            end
                        end
                    end
                end
            end
        end
        addFuncToActive(vehicle, effectName, activeFunc)
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing ENGINE_STALLS_CHANCE effect.")
        removeFuncFromActive(vehicle, handler.getEffectName())
    end,
}

-- ==========================================================
-- PTO_AUTO_DISENGAGE_CHANCE
ADS_Breakdowns.EffectApplicators.PTO_AUTO_DISENGAGE_CHANCE = {
    getEffectName = function() return "PTO_AUTO_DISENGAGE_CHANCE" end,
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying PTO_AUTO_DISENGAGE_CHANCE effect.")
        local effectName = handler.getEffectName()

        local function hasActivePtoLoad(rootVehicle)
            if rootVehicle == nil then
                return false
            end

            local ptoActive = rootVehicle.getIsPowerTakeOffActive ~= nil and rootVehicle:getIsPowerTakeOffActive() or false
            local ptoConsuming = rootVehicle.getDoConsumePtoPower ~= nil and rootVehicle:getDoConsumePtoPower() or false
            local ptoRpm = rootVehicle.getPtoRpm ~= nil and (tonumber(rootVehicle:getPtoRpm()) or 0) or 0
            local ptoTorque = 0

            if PowerConsumer ~= nil and PowerConsumer.getTotalConsumedPtoTorque ~= nil then
                local ok, torqueValue = pcall(PowerConsumer.getTotalConsumedPtoTorque, rootVehicle, nil, nil, true)
                if ok then
                    ptoTorque = tonumber(torqueValue) or 0
                end
            end

            return ptoActive or ptoConsuming or ptoRpm > 10 or ptoTorque > 0.001
        end

        local function disengagePtoConsumers(rootVehicle)
            local turnedOff = false
            local visited = {}

            local function walk(vehicleObj)
                if vehicleObj == nil or visited[vehicleObj] then
                    return
                end
                visited[vehicleObj] = true

                local isTurnedOn = vehicleObj.getIsTurnedOn ~= nil and vehicleObj:getIsTurnedOn() or false
                if isTurnedOn and vehicleObj.setIsTurnedOn ~= nil then
                    vehicleObj:setIsTurnedOn(false)
                    turnedOff = true
                end

                if vehicleObj.getAttachedImplements ~= nil then
                    local implements = vehicleObj:getAttachedImplements() or {}
                    for _, implement in pairs(implements) do
                        if implement ~= nil and implement.object ~= nil then
                            walk(implement.object)
                        end
                    end
                end
            end

            walk(rootVehicle)
            return turnedOff
        end

        local activeFunc = function(v, dt)

            local effect = v.spec_AdvancedDamageSystem.activeEffects[effectName]
            if effect == nil or (tonumber(effect.value) or 0) <= 0 then
                return
            end

            effect.extraData = effect.extraData or {}
            if effect.extraData.status == nil then
                effect.extraData.status = "IDLE"
            end

            if effect.extraData.status == "DISENGAGED" then
                if disengagePtoConsumers(v) then
                    if v:getIsActiveForInput(true) then
                        g_currentMission:showBlinkingWarning(g_i18n:getText("ads_breakdowns_pto_auto_disengage_message"), 4000)
                    end
                end
                effect.extraData.status = "IDLE"
                return
            end

            if not v.isServer then
                return
            end

            if not hasActivePtoLoad(v) then
                return
            end

            if effect.extraData.status == "IDLE" and math.random() < ADS_Utils.getChancePerFrameFromMeanTime(dt, effect.value) then
                effect.extraData.status = "DISENGAGED"
                ADS_EffectSyncEvent.send(v, effectName, "DISENGAGED", 0, 0, 0)
            end
        end

        addFuncToActive(vehicle, effectName, activeFunc)
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing PTO_AUTO_DISENGAGE_CHANCE effect.")
        removeFuncFromActive(vehicle, handler.getEffectName())
    end
}

-- ==========================================================
-- ENGINE_HARD_START_MODIFIER

local function tryStartMotor(dt, value, engTemp, batV, glowPlugPenalty)
    local tempFactor = 0
    local batFactor = 1
    local modValue = value
    -- failing glow plugs: extra cranking time that grows as the engine gets colder
    if glowPlugPenalty ~= nil and glowPlugPenalty > 0 then
        local coldness = math.clamp((20 - engTemp) / 30, 0, 1)
        modValue = modValue + glowPlugPenalty * coldness
    end
    if engTemp <= -10 then
        tempFactor = math.max((-10 - engTemp) / 2, 0)
        modValue = modValue + tempFactor
    elseif engTemp >= 30 then
        local hotT = math.clamp((engTemp - 30) / 60, 0, 1)
        local hotFactor = 1.0 - 0.3 * hotT
        modValue = modValue * hotFactor
    end

    if batV ~= nil then
        local t = math.clamp((12.2 - batV) / 0.5, 0, 1)
        batFactor = 1 + (t * t)
        modValue = modValue * batFactor
    end
    local mtbfInMinutes = modValue / 60
    local chance = ADS_Utils.getChancePerFrameFromMeanTime(dt, mtbfInMinutes)
    local random = math.random()
    if random < chance then return true end
    return false
end

ADS_Breakdowns.EffectApplicators.ENGINE_HARD_START_MODIFIER = {
    getEffectName = function() return "ENGINE_HARD_START_MODIFIER" end,
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying ENGINE_HARD_START_MODIFIER effect")
        local effectName = handler.getEffectName()

        local activeFunc = function(v, dt)
            local spec = v.spec_AdvancedDamageSystem
            if spec == nil then return end
            local effect = spec.activeEffects ~= nil and spec.activeEffects[effectName] or nil
            if effect == nil or effect.extraData == nil then
                return
            end
            
            local motorStartDelay = 1500
            local startFadeMs = 0
            local endFadeMs = -1500
            local crankingPitchOffset = 0

            if effect.extraData.status == 'CRANKING' then
                if effect.extraData.preCrankVoltageV == nil then
                    effect.extraData.preCrankVoltageV = spec.batteryTerminalVoltageV or spec.batteryOpenCircuitVoltageV or 12.2
                end

                crankingPitchOffset = getStarterCrankingPitchOffset(effect.extraData.preCrankVoltageV)
            elseif effect.extraData.preCrankVoltageV ~= nil then
                crankingPitchOffset = getStarterCrankingPitchOffset(effect.extraData.preCrankVoltageV)
            end

            effect.extraData.timer = math.max((effect.extraData.timer or 0) - dt, endFadeMs)

            if v.isClient and effect.extraData.status == 'PASSED' then
                playStarterCrankingEndSample(spec, crankingPitchOffset)
            end

            -- starterCrankingEnd fade
            if effect.extraData.timer <= startFadeMs and effect.extraData.timer >= endFadeMs then
                local baseVolume = spec.samples.starterCrankingEnd.current.volume or 2.0
                local t = math.clamp(math.abs(effect.extraData.timer / endFadeMs), 0, 1)
                local easedT = t * t
                local offset = math.max(-(baseVolume * easedT), -0.65)

                if g_soundManager:getIsSamplePlaying(spec.samples.starterCrankingEnd) then
                    g_soundManager:setSampleVolumeOffset(spec.samples.starterCrankingEnd, offset)
                end
            end

            -- start motor after motorStartDelay
            if effect.extraData.timer <= 0 and effect.extraData.status == 'PASSED' then
                v:startMotor(false, true)
                effect.extraData.status = 'IDLE'
                effect.extraData.preCrankVoltageV = nil
            end

            if not v:getIsMotorStarted() and spec.startButtonHeld and effect.extraData.status == 'CRANKING' then
                local rawEngineTemp = spec.rawEngineTemperature or spec.engineTemperature or -99
                local glowPlugEffect = spec.activeEffects ~= nil and spec.activeEffects.GLOW_PLUG_COLD_START_EFFECT or nil
                local glowPlugPenalty = glowPlugEffect ~= nil and (tonumber(glowPlugEffect.value) or 0) or 0
                if v.isServer and tryStartMotor(dt, effect.value, rawEngineTemp, effect.extraData.preCrankVoltageV, glowPlugPenalty) then
                    effect.extraData.timer = motorStartDelay
                    effect.extraData.status = 'PASSED'
                    if v.isClient then
                        playStarterCrankingEndSample(spec, crankingPitchOffset)
                    end
                    ADS_EffectSyncEvent.send(vehicle, handler.getEffectName(), "PASSED", motorStartDelay, 0, 0)
                end

            elseif not spec.startButtonHeld and effect.extraData.status == 'CRANKING' then
                if effect.extraData.status == 'CRANKING' then 
                    effect.extraData.status = 'IDLE'
                    effect.extraData.preCrankVoltageV = nil
                end
            end

            syncStarterCrankingSample(v)
        end
        addFuncToActive(vehicle, effectName, activeFunc)
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing ENGINE_HARD_START_MODIFIER effect.")
        local effect = vehicle.spec_AdvancedDamageSystem
            and vehicle.spec_AdvancedDamageSystem.activeEffects
            and vehicle.spec_AdvancedDamageSystem.activeEffects.ENGINE_HARD_START_MODIFIER
            or nil
        local starterSample = (vehicle.spec_AdvancedDamageSystem
            and vehicle.spec_AdvancedDamageSystem.samples
            and vehicle.spec_AdvancedDamageSystem.samples.starter)
            or nil

        if effect ~= nil and effect.extraData ~= nil then
            local extra = effect.extraData
            if starterSample ~= nil and extra.soundPlaying == true then
                g_soundManager:stopSample(starterSample, 0, 0)
            end
            if starterSample ~= nil and extra.originalLoops ~= nil then
                starterSample.loops = extra.originalLoops
            end
            extra.soundPlaying = false
            extra.status = "IDLE"
            extra.timer = 0
            extra.preCrankVoltageV = nil
        end
        syncStarterCrankingSample(vehicle)
        removeFuncFromActive(vehicle, handler.getEffectName())
    end
}

function ADS_Breakdowns.onStartButtonAction(self, actionName, inputValue, callbackState, isAnalog, isMouse, deviceCategory, binding)
    local spec = self ~= nil and self.spec_AdvancedDamageSystem or nil
    if spec == nil then
        return
    end

    local value = tonumber(inputValue) or 0
    local isPressed = binding ~= nil and binding.isPressed == true
    local currentlyHeld = isPressed or value > 0.5
    local wasHeld = spec.startButtonHeld == true

    local _prevStartButtonDown = spec.startButtonDown
    local _prevStartButtonUp = spec.startButtonUp
    local _prevStartButtonHeld = spec.startButtonHeld

    spec.startButtonDown = currentlyHeld and not wasHeld
    spec.startButtonUp = not currentlyHeld and wasHeld
    spec.startButtonHeld = currentlyHeld

    if _prevStartButtonDown ~= spec.startButtonDown or _prevStartButtonUp ~= spec.startButtonUp or _prevStartButtonHeld ~= spec.startButtonHeld then
        ADS_StartButtonEvent.send(self, spec.startButtonDown, spec.startButtonHeld, spec.startButtonUp)
    end
end

function ADS_Breakdowns.startMotor(self, superFunc, noEventSend, passed)
    local spec = self.spec_AdvancedDamageSystem
    local engineFailure = spec and spec.activeEffects.ENGINE_FAILURE
    local engineHardStart = spec and spec.activeEffects.ENGINE_HARD_START_MODIFIER
    local automaticMotorStartEnabled = g_currentMission ~= nil
        and g_currentMission.missionInfo ~= nil
        and g_currentMission.missionInfo.automaticMotorStartEnabled == true
    local hasManualStartInput = spec ~= nil and (spec.startButtonHeld == true or spec.startButtonDown == true)
    local isAutomaticStartAttempt = automaticMotorStartEnabled and not hasManualStartInput


    if self.spec_AdvancedDamageSystem == nil or (engineFailure == nil and engineHardStart == nil) or passed then
        superFunc(self, noEventSend)
        return
    end

    if self:getIsAIActive() and not engineFailure then
        superFunc(self, noEventSend)
        return
    end

    if engineFailure then
        if engineFailure.extraData.starter then
            if isAutomaticStartAttempt then
                return
            end
            engineFailure.extraData.status = 'CRANKING'
            ADS_EffectSyncEvent.send(self, 'ENGINE_FAILURE', "CRANKING", 0, 0, 0)
        end
        return
    end

    if engineHardStart and engineHardStart.extraData.status == 'IDLE' then
        if isAutomaticStartAttempt then
            return
        end
        engineHardStart.extraData.status = 'CRANKING'
        ADS_EffectSyncEvent.send(self, 'ENGINE_HARD_START_MODIFIER', "CRANKING", 0, 0, 0)
        return
    end
end


-- ==========================================================
-- GEAR_SHIFT_FAILURE_CHANCE
ADS_Breakdowns.EffectApplicators.GEAR_SHIFT_FAILURE_CHANCE = {
    getEffectName = function()
        return "GEAR_SHIFT_FAILURE_CHANCE" 
    end,

    apply = function(vehicle, effectData, handler)
        log_dbg("Applying GEAR_SHIFT_FAILURE_CHANCE:", effectData.value)

        local effectName = handler.getEffectName()

        if vehicle.spec_AdvancedDamageSystem.activeFunctions[effectName] == nil then
            vehicle.spec_AdvancedDamageSystem.activeFunctions[effectName] = function(v, dt)
                
                if v:getIsMotorStarted() then
                    local spec = v.spec_AdvancedDamageSystem           
                    local effect = spec.activeEffects.GEAR_SHIFT_FAILURE_CHANCE
                    if effect and effect.value > 0 and effect.extraData.status == "FAILED" then
                        effect.extraData.timer = effect.extraData.timer + dt
                        if effect.extraData.timer > effect.extraData.duration then
                            effect.extraData.timer = 0
                            effect.extraData.status = "IDLE"
                        end
                    end
                end
            end
        end
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing GEAR_SHIFT_FAILURE_CHANCE effect.")

        local effectName = handler.getEffectName()
        if vehicle.spec_AdvancedDamageSystem.activeFunctions[effectName] ~= nil then
            vehicle.spec_AdvancedDamageSystem.activeFunctions[effectName] = nil
        end
    end
}

if VehicleMotor ~= nil and VehicleMotor.shiftGear ~= nil then
    VehicleMotor.shiftGear = Utils.overwrittenFunction(VehicleMotor.shiftGear, function(self, superFunc, up)
        local vehicle = self.vehicle
        if vehicle ~= nil then
            local spec_ads = vehicle.spec_AdvancedDamageSystem
            if spec_ads ~= nil and spec_ads.activeEffects ~= nil then
                local effect = spec_ads.activeEffects.GEAR_SHIFT_FAILURE_CHANCE
                if effect ~= nil and effect.value ~= nil then
                    if effect.extraData.status == "FAILED" then return end
                    if vehicle.isServer and math.random() < effect.value then
                        effect.extraData.status = "FAILED"
                        ADS_EffectSyncEvent.send(vehicle, "GEAR_SHIFT_FAILURE_CHANCE", "FAILED", 0, 0, 0)
                        if spec_ads and effect.value < 1.0 then
                            g_soundManager:playSample(spec_ads.samples['transmissionShiftFailed' .. math.random(3)])
                        end
                        return
                    end
                end
            end
        end
        return superFunc(self, up)
    end)
end

if VehicleMotor ~= nil and VehicleMotor.selectGear ~= nil then
    VehicleMotor.selectGear = Utils.overwrittenFunction(VehicleMotor.selectGear, function(self, superFunc, gearIndex, activation)
        local vehicle = self.vehicle
        if vehicle ~= nil then
            local spec_ads = vehicle.spec_AdvancedDamageSystem
            if spec_ads ~= nil and spec_ads.activeEffects ~= nil then
                local effect = spec_ads.activeEffects.GEAR_SHIFT_FAILURE_CHANCE
                if effect ~= nil and effect.value ~= nil then
                    if effect.extraData.status == "FAILED" then return end
                    if activation then
                        if vehicle.isServer and math.random() < effect.value then
                            effect.extraData.status = "FAILED"
                            ADS_EffectSyncEvent.send(vehicle, "GEAR_SHIFT_FAILURE_CHANCE", "FAILED", 0, 0, 0)
                            if spec_ads and effect.value < 1.0 then
                                g_soundManager:playSample(spec_ads.samples['transmissionShiftFailed' .. math.random(3)])
                            end
                            return
                        end
                    end
                end
            end
        end
        return superFunc(self, gearIndex, activation)
    end)
end

if VehicleMotor ~= nil and VehicleMotor.updateGear ~= nil then
    VehicleMotor.updateGear = Utils.overwrittenFunction(VehicleMotor.updateGear, function(self, superFunc, acceleratorPedal, brakePedal, dt)
        local vehicle = self.vehicle
        local wasShifting = (self.gear == 0 and self.gearChangeTimer > 0)
        local adjAcceleratorPedal, adjBrakePedal = superFunc(self, acceleratorPedal, brakePedal, dt)
        local isShifting = (self.gear == 0 and self.gearChangeTimer > 0)

        if vehicle ~= nil and isShifting and not wasShifting then
            local spec_ads = vehicle.spec_AdvancedDamageSystem
            if spec_ads ~= nil and spec_ads.activeEffects ~= nil then
                local effect = spec_ads.activeEffects.GEAR_SHIFT_FAILURE_CHANCE
                if effect ~= nil and effect.value ~= nil then
                    if vehicle.isServer and math.random() < effect.value then
                        effect.extraData.status = "FAILED"
                        effect.extraData.timer = 0

                        self.gearChangeTimer = effect.extraData.duration
                        self.autoGearChangeTimer = effect.extraData.duration

                        ADS_EffectSyncEvent.send(vehicle, "GEAR_SHIFT_FAILURE_CHANCE", "FAILED", 0, 0, effect.extraData.duration)

                        if spec_ads and effect.value < 1.0 then
                            g_soundManager:playSample(spec_ads.samples['transmissionShiftFailed' .. math.random(3)])
                        end
                    end
                    if effect.value >= 1.0 then
                        self.targetGear = self.previousGear
                    end
                end
            end
        end

        return adjAcceleratorPedal, adjBrakePedal
    end)
end

-- ==========================================================
-- GEAR_REJECTION_CHANCE
ADS_Breakdowns.EffectApplicators.GEAR_REJECTION_CHANCE = {
    getEffectName = function() return "GEAR_REJECTION_CHANCE" end,
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying GEAR_REJECTION_CHANCE effect")
        local effectName = handler.getEffectName()
        local activeFunc = function(v, dt)
            if v:getIsMotorStarted() then
                local effect = v.spec_AdvancedDamageSystem.activeEffects.GEAR_REJECTION_CHANCE
                if effect and effect.value > 0 then
                    local motor = v:getMotor()
                    if effect.extraData.status == 'REJECTED' then
                        motor.targetGear = 0
                        effect.extraData.timer = effect.extraData.timer + dt
                        if effect.extraData.timer >= effect.extraData.duration then
                            effect.extraData.status = 'IDLE'
                            g_soundManager:playSample(vehicle.spec_AdvancedDamageSystem.samples['transmissionShiftFailed' .. math.random(3)])
                        end

                    elseif v.isServer and v:getMotorLoadPercentage() > 0.8 and effect.extraData.status == 'IDLE' then
                        if math.random() < ADS_Utils.getChancePerFrameFromMeanTime(dt, effect.value) then
                            effect.extraData.status = 'REJECTED'
                            effect.extraData.timer = 0
                            if motor and motor.setGear then
                                motor:setGear(0, false)

                                ADS_EffectSyncEvent.send(v, "GEAR_REJECTION_CHANCE", "REJECTED", 0)
                                
                                g_soundManager:playSample(v.spec_AdvancedDamageSystem.samples.gearDisengage1)
                                if v:getIsActiveForInput(true) then
                                    g_currentMission:showBlinkingWarning(g_i18n:getText("ads_breakdowns_gear_disengage_message", 3000)) 
                                end
                            end
                        end
                    end
                end
            end
        end
        addFuncToActive(vehicle, effectName, activeFunc)
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing GEAR_REJECTION_CHANCE effect")
        removeFuncFromActive(vehicle, handler.getEffectName())
    end
}

-- ==========================================================
-- LIGHTS_FLICKER_CHANCE
ADS_Breakdowns.EffectApplicators.LIGHTS_FLICKER_CHANCE = {
    getEffectName = function()
        return "LIGHTS_FLICKER_CHANCE" 
    end,

    apply = function(vehicle, effectData, handler)
        log_dbg("Applying LIGHTS_FLICKER_CHANCE effect")

        local effectName = handler.getEffectName()

        local activeFunc = function(v, dt)
                if v:getIsMotorStarted() then
                    local spec = v.spec_AdvancedDamageSystem
                    local effect = spec.activeEffects.LIGHTS_FLICKER_CHANCE
                    if effect and effect.value > 0 then
                        if v.spec_lights == nil then return end

                        if effect.extraData.status == 'FLICKING' and effect.extraData.timer < effect.extraData.duration then
                            effect.extraData.timer = effect.extraData.timer + dt
                            local maxMask = v.spec_lights.maxLightStateMask
                            local randomMask = math.random(0, maxMask)
                            v:setLightsTypesMask(randomMask, true, true)

                        elseif effect.extraData.status == 'FLICKING' and effect.extraData.timer > effect.extraData.duration then
                            effect.extraData.status = 'IDLE'
                            effect.extraData.timer = 0
                            v:setLightsTypesMask(effect.extraData.maskBackup, true, true)

                        elseif v.isServer and effect.extraData.status == 'IDLE' then
                            if math.random() < ADS_Utils.getChancePerFrameFromMeanTime(dt, effect.value) then
                                effect.extraData.maskBackup = v:getLightsTypesMask()
                                if effect.extraData.maskBackup == 0 then return end
                                effect.extraData.status = 'FLICKING'

                                ADS_EffectSyncEvent.send(v, "LIGHTS_FLICKER_CHANCE", "FLICKING", 0, effect.extraData.maskBackup)

                            end
                        end
                    end
                end
            end
        addFuncToActive(vehicle, effectName, activeFunc)
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing LIGHTS_FLICKER_CHANCE effect")
        removeFuncFromActive(vehicle, handler.getEffectName())
    end
}

-- =========================================================
-- EMPTY_EFFECT
-- =========================================================
-- CHIPPER_KNIFE_DULL_EFFECT
-- value = share of feed-roller speed/pull lost to dull knives (1.0 = knives done,
-- chipper locked out until they are changed).
local function adsSetChipperFeedFactor(vehicle, factor)
    local wc = vehicle.spec_woodCrusher
    if wc == nil then return end
    if wc.adsOrigMoveVelocityZ == nil and type(wc.moveVelocityZ) == "number" then
        wc.adsOrigMoveVelocityZ = wc.moveVelocityZ
    end
    if wc.adsOrigMoveMaxForce == nil and type(wc.moveMaxForce) == "number" then
        wc.adsOrigMoveMaxForce = wc.moveMaxForce
    end
    factor = math.max(math.min(factor, 1.0), 0.0)
    if wc.adsOrigMoveVelocityZ ~= nil then
        wc.moveVelocityZ = wc.adsOrigMoveVelocityZ * factor
        if vehicle.isServer and vehicle.getIsTurnedOn ~= nil and vehicle:getIsTurnedOn() and type(wc.moveColNodes) == "table" then
            for _, node in pairs(wc.moveColNodes) do
                if type(node) == "number" and node ~= 0 then
                    pcall(setFrictionVelocity, node, wc.moveVelocityZ)
                end
            end
        end
    end
    if wc.adsOrigMoveMaxForce ~= nil then
        wc.moveMaxForce = wc.adsOrigMoveMaxForce * factor
    end
end

ADS_Breakdowns.EffectApplicators.CHIPPER_KNIFE_DULL_EFFECT = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying CHIPPER_KNIFE_DULL_EFFECT:", effectData.value)
        adsSetChipperFeedFactor(vehicle, 1.0 - (tonumber(effectData.value) or 0))
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing CHIPPER_KNIFE_DULL_EFFECT effect.")
        adsSetChipperFeedFactor(vehicle, 1.0)
    end
}

function ADS_Breakdowns.getIsChipperKnivesLocked(vehicle)
    if vehicle.spec_woodCrusher == nil or vehicle.spec_AdvancedDamageSystem == nil then
        return false
    end
    local active = vehicle.spec_AdvancedDamageSystem.activeBreakdowns
    local bd = active ~= nil and active.CHIPPER_KNIFE_WEAR or nil
    local entry = ADS_Breakdowns.BreakdownRegistry.CHIPPER_KNIFE_WEAR
    if bd == nil or entry == nil or bd.isActive == false then
        return false
    end
    return (tonumber(bd.stage) or 1) >= #entry.stages
end

-- counts every log the chipper eats (server only; the counter lives in the ADS spec)
function ADS_Breakdowns.onCrushedSplitShapeOverwrite(vehicle, superFunc, splitType, volume, ...)
    local spec = vehicle.spec_AdvancedDamageSystem
    local C = ADS_Config.CHIPPER_KNIVES
    if vehicle.isServer and spec ~= nil and C ~= nil and C.ENABLED ~= false and type(volume) == "number" and volume > 0 then
        local amount = volume
        if C.COUNT_CHIP_OUTPUT and type(splitType) == "table" and type(splitType.woodChipsPerLiter) == "number" then
            amount = volume * splitType.woodChipsPerLiter
        end
        spec.chipperKnifeVolume = (spec.chipperKnifeVolume or 0) + amount
    end
    return superFunc(vehicle, splitType, volume, ...)
end

function ADS_Breakdowns.getCanBeTurnedOnChipperOverwrite(vehicle, superFunc, ...)
    if ADS_Breakdowns.getIsChipperKnivesLocked(vehicle) then
        return false
    end
    return superFunc(vehicle, ...)
end

function ADS_Breakdowns.getTurnedOnNotAllowedWarningChipperOverwrite(vehicle, superFunc, ...)
    if ADS_Breakdowns.getIsChipperKnivesLocked(vehicle) then
        return g_i18n:getText("ads_breakdowns_chipper_knife_wear_locked_warning")
    end
    return superFunc(vehicle, ...)
end

ADS_Breakdowns.EffectApplicators.EMPTY_EFFECT = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying EMPTY_EFFECT effect")
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing EMPTY_EFFECT effect.")
    end
}

-- =========================================================
-- GLOW_PLUG_COLD_START_EFFECT
-- Passive: read by tryStartMotor(). value = extra mean cranking time in seconds
-- that is added in full at -10 C and fades out completely by +20 C.
ADS_Breakdowns.EffectApplicators.GLOW_PLUG_COLD_START_EFFECT = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying GLOW_PLUG_COLD_START_EFFECT:", effectData.value)
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing GLOW_PLUG_COLD_START_EFFECT effect.")
    end
}

-- =========================================================
-- TEMP_SENSOR_FAULT_EFFECT
-- Passive: read by ADS_Hud. value = max deviation (C) of the displayed engine
-- temperature from the real one. Physics and wear always use the real value.
ADS_Breakdowns.EffectApplicators.TEMP_SENSOR_FAULT_EFFECT = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying TEMP_SENSOR_FAULT_EFFECT:", effectData.value)
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing TEMP_SENSOR_FAULT_EFFECT effect.")
    end
}

function ADS_Breakdowns.getDisplayedEngineTemperature(vehicle)
    local spec = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    if spec == nil then
        return 0
    end
    local realTemp = tonumber(spec.engineTemperature) or 0
    local effect = spec.activeEffects ~= nil and spec.activeEffects.TEMP_SENSOR_FAULT_EFFECT or nil
    if effect == nil then
        return realTemp
    end
    local amplitude = math.max(tonumber(effect.value) or 0, 0)
    local t = tonumber(g_time) or 0
    -- two slow, unrelated waves so the needle wanders instead of pulsing
    local wave = math.sin(t / 9000) * 0.6 + math.sin(t / 2300 + 1.3) * 0.4
    return realTemp + amplitude * wave
end

-- =========================================================
-- GAUGE_GLITCH_EFFECT
-- Passive: read by the HUD through ADS_Breakdowns.getGaugeReading(). value = mean
-- seconds between glitches. A glitch picks one random gauge and one random
-- failure mode for a few seconds. Display only - every system keeps using the
-- real values. Runs locally on each client, so nothing needs syncing.
ADS_Breakdowns.EffectApplicators.GAUGE_GLITCH_EFFECT = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying GAUGE_GLITCH_EFFECT:", effectData.value)
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing GAUGE_GLITCH_EFFECT effect.")
        if vehicle.spec_AdvancedDamageSystem ~= nil then
            vehicle.spec_AdvancedDamageSystem.gaugeGlitch = nil
        end
    end
}

ADS_Breakdowns.GAUGE_GLITCH_GAUGES = { "engineTemp", "transTemp", "voltage", "motorLoad", "fuel" }
ADS_Breakdowns.GAUGE_GLITCH_MODES = { "frozen", "low", "high", "erratic" }

local function getRandomGlitchDelayMs(meanSeconds)
    local u = math.min(math.random(), 0.999)
    return -math.log(1 - u) * math.max(meanSeconds, 1) * 1000
end

-- Returns what the dashboard should show for `gauge` instead of `realValue`.
-- lowValue/highValue are what the gauge reads when it drops out or pegs.
function ADS_Breakdowns.getGaugeReading(vehicle, gauge, realValue, lowValue, highValue)
    local spec = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    if spec == nil or spec.activeEffects == nil or realValue == nil then
        return realValue
    end

    local effect = spec.activeEffects.GAUGE_GLITCH_EFFECT
    if effect == nil then
        spec.gaugeGlitch = nil
        return realValue
    end

    local meanSeconds = tonumber(effect.value) or 300
    local now = tonumber(g_time) or 0
    local state = spec.gaugeGlitch
    if state == nil then
        state = { nextAt = now + getRandomGlitchDelayMs(meanSeconds), active = nil }
        spec.gaugeGlitch = state
    end

    if state.active ~= nil and now >= state.active.endsAt then
        state.active = nil
        state.nextAt = now + getRandomGlitchDelayMs(meanSeconds)
    end

    -- only start glitches while the engine runs (cluster is powered and being looked at)
    if state.active == nil and now >= state.nextAt and vehicle.getIsMotorStarted ~= nil and vehicle:getIsMotorStarted() then
        local gauges = ADS_Breakdowns.GAUGE_GLITCH_GAUGES
        local modes = ADS_Breakdowns.GAUGE_GLITCH_MODES
        state.active = {
            gauge = gauges[math.random(#gauges)],
            mode = modes[math.random(#modes)],
            endsAt = now + math.random(4000, 25000),
            frozenValue = nil
        }
    end

    local glitch = state.active
    if glitch == nil or glitch.gauge ~= gauge then
        return realValue
    end

    if glitch.mode == "frozen" then
        if glitch.frozenValue == nil then
            glitch.frozenValue = realValue
        end
        return glitch.frozenValue
    elseif glitch.mode == "low" then
        return lowValue
    elseif glitch.mode == "high" then
        return highValue
    end

    -- erratic: needle bounces around the whole scale
    local t = 0.5 + 0.5 * math.sin(now / 170) * math.sin(now / 530 + 0.7)
    return lowValue + (highValue - lowValue) * math.clamp(t, 0, 1)
end

-- Stock fuel gauge: misreads while GAUGE_GLITCH_EFFECT is active. Installed lazily
-- from the ADS HUD in case SpeedMeterDisplay is not available yet at source time.
function ADS_Breakdowns.installGaugeHooks()
    if ADS_Breakdowns.gaugeHooksInstalled then
        return
    end
    if SpeedMeterDisplay == nil or SpeedMeterDisplay.getVehicleFuelLevelAndCapacity == nil or Utils == nil or Utils.overwrittenFunction == nil then
        return
    end

    SpeedMeterDisplay.getVehicleFuelLevelAndCapacity = Utils.overwrittenFunction(SpeedMeterDisplay.getVehicleFuelLevelAndCapacity, function(vehicle, superFunc, ...)
        local fuelLevel, fuelCapacity, fuelType = superFunc(vehicle, ...)
        if vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil and fuelLevel ~= nil and fuelCapacity ~= nil and fuelCapacity > 0 then
            fuelLevel = ADS_Breakdowns.getGaugeReading(vehicle, "fuel", fuelLevel, 0, fuelCapacity)
        end
        return fuelLevel, fuelCapacity, fuelType
    end)
    ADS_Breakdowns.gaugeHooksInstalled = true
end

ADS_Breakdowns.installGaugeHooks()

-- =========================================================
-- DPF_PASSIVE_REGEN_EFFECT
-- Early DPF clogging clears itself if the machine is worked hard for long
-- enough (soot burns off under sustained load), like a real passive regen.
ADS_Breakdowns.EffectApplicators.DPF_PASSIVE_REGEN_EFFECT = {
    getEffectName = function() return "DPF_PASSIVE_REGEN_EFFECT" end,
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying DPF_PASSIVE_REGEN_EFFECT")
        local effectName = handler.getEffectName()

        local activeFunc = function(v, dt)
            if not v.isServer then
                return
            end
            local spec = v.spec_AdvancedDamageSystem
            if spec == nil then return end
            local effect = spec.activeEffects ~= nil and spec.activeEffects[effectName] or nil
            if effect == nil or effect.extraData == nil then
                return
            end

            local extra = effect.extraData
            if not v:getIsMotorStarted() then
                return
            end

            local load = tonumber(v:getMotorLoadPercentage()) or 0
            if load >= (tonumber(extra.minLoad) or 0.55) then
                spec.dpfRegenProgressMs = (spec.dpfRegenProgressMs or 0) + dt
            end

            if (spec.dpfRegenProgressMs or 0) >= (tonumber(extra.regenMs) or 600000) then
                spec.dpfRegenProgressMs = 0
                local breakdownId = extra.breakdownId or "DPF_CLOGGING"
                if v:hasBreakdown(breakdownId) then
                    v:removeBreakdown(breakdownId)
                    if v.getIsEntered ~= nil and v:getIsEntered() and g_currentMission ~= nil then
                        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, g_i18n:getText("ads_breakdowns_dpf_regen_complete_message"))
                    end
                end
            end
        end
        addFuncToActive(vehicle, effectName, activeFunc)
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing DPF_PASSIVE_REGEN_EFFECT effect.")
        if vehicle.spec_AdvancedDamageSystem ~= nil then
            vehicle.spec_AdvancedDamageSystem.dpfRegenProgressMs = 0
        end
        removeFuncFromActive(vehicle, handler.getEffectName())
    end
}

-- =========================================================
-- TRAILER_BRAKE_DRAG_EFFECT
-- value 0..0.9 = trailer brakes dragging while towing (less pull, lower top speed)
-- value >= 1.0 = spring brakes applied, the trailer will not roll
-- extraData.buildUpMs = after every engine start, trailer brakes stay applied
--                       until the leaking system has built enough air pressure
-- Only has any effect while a braked trailer/implement is attached.
ADS_Breakdowns.EffectApplicators.TRAILER_BRAKE_DRAG_EFFECT = {
    getEffectName = function() return "TRAILER_BRAKE_DRAG_EFFECT" end,
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying TRAILER_BRAKE_DRAG_EFFECT:", effectData.value)
        local effectName = handler.getEffectName()
        local spec = vehicle.spec_AdvancedDamageSystem
        if spec ~= nil and spec.trailerAirWasMotorOn == nil then
            spec.trailerAirWasMotorOn = vehicle:getIsMotorStarted()
        end

        local activeFunc = function(v, dt)
            local s = v.spec_AdvancedDamageSystem
            if s == nil then return end
            local effect = s.activeEffects ~= nil and s.activeEffects[effectName] or nil
            if effect == nil then return end

            local isOn = v:getIsMotorStarted()
            if isOn and not s.trailerAirWasMotorOn then
                local buildUp = effect.extraData ~= nil and (tonumber(effect.extraData.buildUpMs) or 0) or 0
                s.trailerAirPressureTimer = buildUp
                if buildUp > 0 and isTowingBrakedImplement(v) and v.getIsActiveForInput ~= nil and v:getIsActiveForInput(true) then
                    g_currentMission:showBlinkingWarning(g_i18n:getText("ads_breakdowns_trailer_air_pressure_building_message"), math.min(buildUp, 5000))
                end
            elseif isOn and (s.trailerAirPressureTimer or 0) > 0 then
                s.trailerAirPressureTimer = math.max(s.trailerAirPressureTimer - dt, 0)
            end
            s.trailerAirWasMotorOn = isOn
        end
        addFuncToActive(vehicle, effectName, activeFunc)
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing TRAILER_BRAKE_DRAG_EFFECT effect.")
        local spec = vehicle.spec_AdvancedDamageSystem
        if spec ~= nil then
            spec.trailerAirPressureTimer = nil
            spec.trailerAirWasMotorOn = nil
        end
        removeFuncFromActive(vehicle, handler.getEffectName())
    end
}

local function getTrailerBrakeState(vehicle)
    local spec_ads = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    local effect = spec_ads ~= nil and spec_ads.activeEffects ~= nil and spec_ads.activeEffects.TRAILER_BRAKE_DRAG_EFFECT or nil
    if effect == nil or not isTowingBrakedImplement(vehicle) then
        return false, 0
    end
    local value = tonumber(effect.value) or 0
    local isHeld = value >= 1.0 or (spec_ads.trailerAirPressureTimer or 0) > 0
    return isHeld, math.clamp(value, 0, 0.9)
end

ADS_Breakdowns.getTrailerBrakeState = getTrailerBrakeState

-- ==========================================================
function ADS_Breakdowns.getCanMotorRun(self, superFunc)
    local spec = self.spec_AdvancedDamageSystem
    if (spec and spec.activeEffects.ENGINE_FAILURE) then
        if spec.activeEffects.ENGINE_FAILURE.extraData.starter  then
            return superFunc(self)
        else
            return false
        end
    elseif self:isUnderService() then
        if self:getIsActiveForInput(true) then
            g_currentMission:showBlinkingWarning(g_i18n:getText(self:getCurrentStatus()) .. " " .. g_i18n:getText("ads_breakdown_at_progress_message", 100)) 
        end
        return false
    end
    return superFunc(self)
end





