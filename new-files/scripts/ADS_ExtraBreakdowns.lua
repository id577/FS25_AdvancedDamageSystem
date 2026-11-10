--[[
    ADS_ExtraBreakdowns.lua
    -------------------------------------------------------------------
    12 additional breakdowns spread across all seven ADS systems
    (engine, transmission, hydraulics, cooling, electrical, chassis,
    fuel). Same plugin technique as ADS_EnhancedVehicleCompat.lua: these
    are just new entries appended to ADS_Breakdowns.BreakdownRegistry and
    ADS_Breakdowns.PARTS, which ADS's own engine already iterates
    generically - no core ADS files are touched.

    Repair prices follow ADS's own scale exactly: each stage's
    repairPrice is a small multiplier (1.0 / 2.0 / 4.0 / 8.0 for
    minor/moderate/major/critical, matching every stock ADS breakdown),
    which ADS's getBreakdownRepairPrice() turns into real money via:

        price * GLOBAL_SERVICE_PRICE_MULTIPLIER * (vehiclePrice / 100)
              * ageFactor * workshopDiscount / maintainability

    So actual repair cost scales with the vehicle's price and age and
    your maintenance settings, exactly like every other ADS breakdown -
    a cheap ATV and an expensive combine will pay very different amounts
    for "the same" repairPrice = 4.0.

    All effect ids used below (VIBRATION_NOISE_EFFECT, GEAR_SHIFT_FAILURE_CHANCE,
    HYDRAULIC_SPEED_MODIFIER, etc.) are ADS's own existing, already-wired
    effect handlers - nothing new was invented here, only new
    combinations/severities of effects ADS already knows how to apply.
--]]

-- ===========================================================
--                    LOCAL HELPERS
-- ===========================================================

-- Same defensive fallback ADS_Breakdowns.lua and
-- ADS_EnhancedVehicleCompat.lua use: AdvancedDamageSystem.SYSTEMS is not
-- defined yet at the point this file loads.
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

-- Equivalent of ADS_Breakdowns.lua's own local getIsElectricVehicle(),
-- reproduced here since that one is file-local and not reachable from
-- this file.
function adsExtraIsElectricVehicle(vehicle)
    if vehicle == nil or vehicle.spec_motorized == nil or vehicle.spec_motorized.consumers == nil then
        return false
    end
    for _, consumer in pairs(vehicle.spec_motorized.consumers) do
        if consumer.fillType == FillType.ELECTRICCHARGE then
            return true
        end
    end
    return false
end

-- Simple, self-contained probability WEIGHT function (this is a relative
-- weight used in ADS's own weighted-random breakdown selection, not an
-- absolute 0-1 chance - see AdvancedDamageSystem:getRandomBreakdown()).
-- We can't reach ADS's private getBreakdownProbabilityWeightPercent()
-- (file-local to ADS_Breakdowns.lua), so this uses the same public
-- getSystemStressLevel/getSystemConditionLevel API every ADS breakdown
-- ultimately feeds from, just combined more simply. Tune the three
-- constants below if these breakdowns feel too common/rare relative to
-- ADS's own stock breakdowns for the same system.
local EXTRA_BASE_WEIGHT = 5.0
local EXTRA_STRESS_WEIGHT = 30.0
local EXTRA_CONDITION_WEIGHT = 20.0

function adsExtraGetProbabilityWeight(vehicle, system)
    local stress = 0
    local condition = 1
    if vehicle.getSystemStressLevel ~= nil then
        stress = tonumber(vehicle:getSystemStressLevel(system)) or 0
    end
    if vehicle.getSystemConditionLevel ~= nil then
        condition = tonumber(vehicle:getSystemConditionLevel(system)) or 1
    end
    stress = math.max(0, math.min(stress, 1))
    condition = math.max(0, math.min(condition, 1))
    return EXTRA_BASE_WEIGHT + (stress * EXTRA_STRESS_WEIGHT) + ((1 - condition) * EXTRA_CONDITION_WEIGHT)
end

-- ===========================================================
--                  NEW PARTS (auto-generated)
-- ===========================================================

ADS_Breakdowns.PARTS.ENGINE_MOUNT = "ads_breakdowns_part_engine_mount"
ADS_Breakdowns.PARTS.GEARBOX_LINKAGE = "ads_breakdowns_part_gearbox_linkage"
ADS_Breakdowns.PARTS.DRIVELINE_JOINT = "ads_breakdowns_part_driveline_joint"
ADS_Breakdowns.PARTS.HYDRAULIC_FLUID = "ads_breakdowns_part_hydraulic_fluid"
ADS_Breakdowns.PARTS.HYDRAULIC_HOSE = "ads_breakdowns_part_hydraulic_hose"
ADS_Breakdowns.PARTS.PRESSURE_RELIEF_VALVE = "ads_breakdowns_part_pressure_relief_valve"
ADS_Breakdowns.PARTS.WATER_PUMP = "ads_breakdowns_part_water_pump"
ADS_Breakdowns.PARTS.STARTER_MOTOR = "ads_breakdowns_part_starter_motor"
ADS_Breakdowns.PARTS.LIGHTING_CIRCUIT = "ads_breakdowns_part_lighting_circuit"
ADS_Breakdowns.PARTS.SUSPENSION_BUSHING = "ads_breakdowns_part_suspension_bushing"
ADS_Breakdowns.PARTS.FUEL_TANK = "ads_breakdowns_part_fuel_tank"

-- ===========================================================
--            NEW BREAKDOWN DEFINITIONS (auto-generated)
-- ===========================================================

ADS_Breakdowns.BreakdownRegistry.ENGINE_MOUNT_DETERIORATION = {
    isSelectable = true,
    system = systems.ENGINE,
    part = parts.ENGINE_MOUNT,
    probability = function(vehicle)
        return adsExtraGetProbabilityWeight(vehicle, systems.ENGINE)
    end,
    isCanProgress = function(vehicle)
        return vehicle:getLastSpeed() > 0.01
    end,
    stages = {
        {
            severity = "ads_breakdowns_severity_minor",
            description = "ads_breakdowns_engine_mount_deterioration_stage1_description",
            detectionChance = 1.0,
            progressMultiplier = 2.0,
            repairPrice = 1.0,
            effects = {
                { id = "VIBRATION_NOISE_EFFECT", value = 0.5, aggregation = "max" }
            }
        },
        {
            severity = "ads_breakdowns_severity_moderate",
            description = "ads_breakdowns_engine_mount_deterioration_stage2_description",
            detectionChance = 1.0,
            progressMultiplier = 1.0,
            repairPrice = 2.0,
            effects = {
                { id = "VIBRATION_NOISE_EFFECT", value = 1.0, aggregation = "max" },
                { id = "MAX_SPEED_MODIFIER", value = 0.02, aggregation = "max" }
            }
        },
        {
            severity = "ads_breakdowns_severity_major",
            description = "ads_breakdowns_engine_mount_deterioration_stage3_description",
            detectionChance = 1.0,
            progressMultiplier = 0.5,
            repairPrice = 4.0,
            effects = {
                { id = "VIBRATION_NOISE_EFFECT", value = 1.5, aggregation = "max" },
                { id = "MAX_SPEED_MODIFIER", value = 0.05, aggregation = "max" }
            }
        },
        {
            severity = "ads_breakdowns_severity_critical",
            description = "ads_breakdowns_engine_mount_deterioration_stage4_description",
            detectionChance = 1.0,
            progressMultiplier = 0.0,
            repairPrice = 8.0,
            effects = {
                { id = "VIBRATION_NOISE_EFFECT", value = 2.0, aggregation = "max" },
                { id = "MAX_SPEED_MODIFIER", value = 0.1, aggregation = "max", extraData = {
    message = "ads_breakdowns_engine_mount_deterioration_stage4_message",
    disableAi = true
} }
            }
        }
    }
}

ADS_Breakdowns.BreakdownRegistry.GEARBOX_LINKAGE_WEAR = {
    isSelectable = true,
    system = systems.TRANSMISSION,
    part = parts.GEARBOX_LINKAGE,
    isApplicable = function(vehicle)
        return not adsExtraIsElectricVehicle(vehicle)
    end,
    probability = function(vehicle)
        return adsExtraGetProbabilityWeight(vehicle, systems.TRANSMISSION)
    end,
    isCanProgress = function(vehicle)
        return vehicle:getLastSpeed() > 0.01
    end,
    stages = {
        {
            severity = "ads_breakdowns_severity_minor",
            description = "ads_breakdowns_gearbox_linkage_wear_stage1_description",
            detectionChance = 1.0,
            progressMultiplier = 2.0,
            repairPrice = 1.0,
            effects = {
                { id = "GEAR_SHIFT_FAILURE_CHANCE", value = 0.08, aggregation = "max", extraData = {
    timer = 0,
    status = "IDLE",
    duration = 1500
} },
                { id = "GEAR_REJECTION_CHANCE", value = 25.0, aggregation = "min", extraData = {
    timer = 0,
    status = "IDLE",
    duration = 1500
} }
            }
        },
        {
            severity = "ads_breakdowns_severity_moderate",
            description = "ads_breakdowns_gearbox_linkage_wear_stage2_description",
            detectionChance = 1.0,
            progressMultiplier = 1.0,
            repairPrice = 2.0,
            effects = {
                { id = "GEAR_SHIFT_FAILURE_CHANCE", value = 0.18, aggregation = "max", extraData = {
    timer = 0,
    status = "IDLE",
    duration = 1800
} },
                { id = "GEAR_REJECTION_CHANCE", value = 12.0, aggregation = "min", extraData = {
    timer = 0,
    status = "IDLE",
    duration = 1800
} }
            }
        },
        {
            severity = "ads_breakdowns_severity_major",
            description = "ads_breakdowns_gearbox_linkage_wear_stage3_description",
            detectionChance = 1.0,
            progressMultiplier = 0.5,
            repairPrice = 4.0,
            effects = {
                { id = "GEAR_SHIFT_FAILURE_CHANCE", value = 0.4, aggregation = "max", extraData = {
    timer = 0,
    status = "IDLE",
    duration = 2200
} },
                { id = "GEAR_REJECTION_CHANCE", value = 5.0, aggregation = "min", extraData = {
    timer = 0,
    status = "IDLE",
    duration = 2200
} }
            }
        },
        {
            severity = "ads_breakdowns_severity_critical",
            description = "ads_breakdowns_gearbox_linkage_wear_stage4_description",
            detectionChance = 1.0,
            progressMultiplier = 0.0,
            repairPrice = 8.0,
            effects = {
                { id = "GEAR_SHIFT_FAILURE_CHANCE", value = 0.9, aggregation = "max", extraData = {
    timer = 0,
    status = "IDLE",
    duration = 2200,
    message = "ads_breakdowns_gearbox_linkage_wear_stage4_message",
    disableAi = true
} },
                { id = "GEAR_REJECTION_CHANCE", value = 2.0, aggregation = "min", extraData = {
    timer = 0,
    status = "IDLE",
    duration = 2200
} }
            }
        }
    }
}

ADS_Breakdowns.BreakdownRegistry.DRIVELINE_JOINT_WEAR = {
    isSelectable = true,
    system = systems.TRANSMISSION,
    part = parts.DRIVELINE_JOINT,
    probability = function(vehicle)
        return adsExtraGetProbabilityWeight(vehicle, systems.TRANSMISSION)
    end,
    isCanProgress = function(vehicle)
        return vehicle:getLastSpeed() > 0.01
    end,
    stages = {
        {
            severity = "ads_breakdowns_severity_minor",
            description = "ads_breakdowns_driveline_joint_wear_stage1_description",
            detectionChance = 1.0,
            progressMultiplier = 2.0,
            repairPrice = 1.0,
            effects = {
                { id = "VIBRATION_NOISE_EFFECT", value = 0.4, aggregation = "max" }
            }
        },
        {
            severity = "ads_breakdowns_severity_moderate",
            description = "ads_breakdowns_driveline_joint_wear_stage2_description",
            detectionChance = 1.0,
            progressMultiplier = 1.0,
            repairPrice = 2.0,
            effects = {
                { id = "VIBRATION_NOISE_EFFECT", value = 0.9, aggregation = "max" },
                { id = "MAX_SPEED_MODIFIER", value = 0.02, aggregation = "max" }
            }
        },
        {
            severity = "ads_breakdowns_severity_major",
            description = "ads_breakdowns_driveline_joint_wear_stage3_description",
            detectionChance = 1.0,
            progressMultiplier = 0.5,
            repairPrice = 4.0,
            effects = {
                { id = "VIBRATION_NOISE_EFFECT", value = 1.4, aggregation = "max" },
                { id = "MAX_SPEED_MODIFIER", value = 0.05, aggregation = "max" }
            }
        },
        {
            severity = "ads_breakdowns_severity_critical",
            description = "ads_breakdowns_driveline_joint_wear_stage4_description",
            detectionChance = 1.0,
            progressMultiplier = 0.0,
            repairPrice = 8.0,
            effects = {
                { id = "VIBRATION_NOISE_EFFECT", value = 2.0, aggregation = "max" },
                { id = "MAX_SPEED_MODIFIER", value = 0.1, aggregation = "max", extraData = {
    message = "ads_breakdowns_driveline_joint_wear_stage4_message",
    disableAi = true
} }
            }
        }
    }
}

ADS_Breakdowns.BreakdownRegistry.HYDRAULIC_FLUID_CONTAMINATION = {
    isSelectable = true,
    system = systems.HYDRAULICS,
    part = parts.HYDRAULIC_FLUID,
    probability = function(vehicle)
        return adsExtraGetProbabilityWeight(vehicle, systems.HYDRAULICS)
    end,
    isCanProgress = function(vehicle)
        return vehicle:getLastSpeed() > 0.01
    end,
    stages = {
        {
            severity = "ads_breakdowns_severity_minor",
            description = "ads_breakdowns_hydraulic_fluid_contamination_stage1_description",
            detectionChance = 1.0,
            progressMultiplier = 2.0,
            repairPrice = 1.0,
            effects = {
                { id = "HYDRAULIC_SPEED_MODIFIER", value = -0.1, aggregation = "min" },
                { id = "UNLOADING_SPEED_MODIFIER", value = -0.15, aggregation = "min" }
            }
        },
        {
            severity = "ads_breakdowns_severity_moderate",
            description = "ads_breakdowns_hydraulic_fluid_contamination_stage2_description",
            detectionChance = 1.0,
            progressMultiplier = 1.0,
            repairPrice = 2.0,
            effects = {
                { id = "HYDRAULIC_SPEED_MODIFIER", value = -0.25, aggregation = "min" },
                { id = "UNLOADING_SPEED_MODIFIER", value = -0.35, aggregation = "min" }
            }
        },
        {
            severity = "ads_breakdowns_severity_major",
            description = "ads_breakdowns_hydraulic_fluid_contamination_stage3_description",
            detectionChance = 1.0,
            progressMultiplier = 0.5,
            repairPrice = 4.0,
            effects = {
                { id = "HYDRAULIC_SPEED_MODIFIER", value = -0.5, aggregation = "min" },
                { id = "UNLOADING_SPEED_MODIFIER", value = -0.6, aggregation = "min" }
            }
        },
        {
            severity = "ads_breakdowns_severity_critical",
            description = "ads_breakdowns_hydraulic_fluid_contamination_stage4_description",
            detectionChance = 1.0,
            progressMultiplier = 0.0,
            repairPrice = 8.0,
            effects = {
                { id = "HYDRAULIC_SPEED_MODIFIER", value = -0.85, aggregation = "min", extraData = {
    message = "ads_breakdowns_hydraulic_fluid_contamination_stage4_message",
    disableAi = true
} },
                { id = "UNLOADING_SPEED_MODIFIER", value = -0.9, aggregation = "min" }
            }
        }
    }
}

ADS_Breakdowns.BreakdownRegistry.HYDRAULIC_HOSE_WEAR = {
    isSelectable = true,
    system = systems.HYDRAULICS,
    part = parts.HYDRAULIC_HOSE,
    probability = function(vehicle)
        return adsExtraGetProbabilityWeight(vehicle, systems.HYDRAULICS)
    end,
    isCanProgress = function(vehicle)
        return vehicle:getLastSpeed() > 0.01
    end,
    stages = {
        {
            severity = "ads_breakdowns_severity_minor",
            description = "ads_breakdowns_hydraulic_hose_wear_stage1_description",
            detectionChance = 1.0,
            progressMultiplier = 2.0,
            repairPrice = 1.0,
            effects = {
                { id = "HYDRAULIC_HOLD_DRIFT_EFFECT", value = 0.02, aggregation = "max" },
                { id = "HYDRAULIC_SPEED_MODIFIER", value = -0.05, aggregation = "min" }
            }
        },
        {
            severity = "ads_breakdowns_severity_moderate",
            description = "ads_breakdowns_hydraulic_hose_wear_stage2_description",
            detectionChance = 1.0,
            progressMultiplier = 1.0,
            repairPrice = 2.0,
            effects = {
                { id = "HYDRAULIC_HOLD_DRIFT_EFFECT", value = 0.04, aggregation = "max" },
                { id = "HYDRAULIC_SPEED_MODIFIER", value = -0.15, aggregation = "min" }
            }
        },
        {
            severity = "ads_breakdowns_severity_major",
            description = "ads_breakdowns_hydraulic_hose_wear_stage3_description",
            detectionChance = 1.0,
            progressMultiplier = 0.5,
            repairPrice = 4.0,
            effects = {
                { id = "HYDRAULIC_HOLD_DRIFT_EFFECT", value = 0.07, aggregation = "max" },
                { id = "HYDRAULIC_SPEED_MODIFIER", value = -0.3, aggregation = "min" }
            }
        },
        {
            severity = "ads_breakdowns_severity_critical",
            description = "ads_breakdowns_hydraulic_hose_wear_stage4_description",
            detectionChance = 1.0,
            progressMultiplier = 0.0,
            repairPrice = 8.0,
            effects = {
                { id = "HYDRAULIC_HOLD_DRIFT_EFFECT", value = 1.0, aggregation = "max", extraData = {
    message = "ads_breakdowns_hydraulic_hose_wear_stage4_message",
    disableAi = true
} },
                { id = "HYDRAULIC_SPEED_MODIFIER", value = -0.5, aggregation = "min" }
            }
        }
    }
}

ADS_Breakdowns.BreakdownRegistry.PRESSURE_RELIEF_VALVE_STICKING = {
    isSelectable = true,
    system = systems.HYDRAULICS,
    part = parts.PRESSURE_RELIEF_VALVE,
    probability = function(vehicle)
        return adsExtraGetProbabilityWeight(vehicle, systems.HYDRAULICS)
    end,
    isCanProgress = function(vehicle)
        return vehicle:getLastSpeed() > 0.01
    end,
    stages = {
        {
            severity = "ads_breakdowns_severity_minor",
            description = "ads_breakdowns_pressure_relief_valve_sticking_stage1_description",
            detectionChance = 1.0,
            progressMultiplier = 2.0,
            repairPrice = 1.0,
            effects = {
                { id = "HYDRAULIC_HOLD_DRIFT_EFFECT", value = 0.01, aggregation = "max" },
                { id = "VIBRATION_NOISE_EFFECT", value = 0.3, aggregation = "max" }
            }
        },
        {
            severity = "ads_breakdowns_severity_moderate",
            description = "ads_breakdowns_pressure_relief_valve_sticking_stage2_description",
            detectionChance = 1.0,
            progressMultiplier = 1.0,
            repairPrice = 2.0,
            effects = {
                { id = "HYDRAULIC_HOLD_DRIFT_EFFECT", value = 0.03, aggregation = "max" },
                { id = "VIBRATION_NOISE_EFFECT", value = 0.7, aggregation = "max" }
            }
        },
        {
            severity = "ads_breakdowns_severity_major",
            description = "ads_breakdowns_pressure_relief_valve_sticking_stage3_description",
            detectionChance = 1.0,
            progressMultiplier = 0.5,
            repairPrice = 4.0,
            effects = {
                { id = "HYDRAULIC_HOLD_DRIFT_EFFECT", value = 0.06, aggregation = "max" },
                { id = "VIBRATION_NOISE_EFFECT", value = 1.2, aggregation = "max" }
            }
        },
        {
            severity = "ads_breakdowns_severity_critical",
            description = "ads_breakdowns_pressure_relief_valve_sticking_stage4_description",
            detectionChance = 1.0,
            progressMultiplier = 0.0,
            repairPrice = 8.0,
            effects = {
                { id = "HYDRAULIC_HOLD_DRIFT_EFFECT", value = 1.0, aggregation = "max", extraData = {
    message = "ads_breakdowns_pressure_relief_valve_sticking_stage4_message",
    disableAi = true
} },
                { id = "VIBRATION_NOISE_EFFECT", value = 1.8, aggregation = "max" }
            }
        }
    }
}

ADS_Breakdowns.BreakdownRegistry.RADIATOR_CLOGGING = {
    isSelectable = true,
    system = systems.COOLING,
    part = parts.COOLING_SYSTEM,
    isApplicable = function(vehicle)
        return not adsExtraIsElectricVehicle(vehicle)
    end,
    probability = function(vehicle)
        return adsExtraGetProbabilityWeight(vehicle, systems.COOLING)
    end,
    isCanProgress = function(vehicle)
        return vehicle:getLastSpeed() > 0.01
    end,
    stages = {
        {
            severity = "ads_breakdowns_severity_minor",
            description = "ads_breakdowns_radiator_clogging_stage1_description",
            detectionChance = 1.0,
            progressMultiplier = 2.0,
            repairPrice = 1.0,
            effects = {
                { id = "RADIATOR_HEALTH_MODIFIER", value = -0.05, aggregation = "min" },
                { id = "ENGINE_HEAT_MODIFIER", value = 0.03, aggregation = "sum" }
            }
        },
        {
            severity = "ads_breakdowns_severity_moderate",
            description = "ads_breakdowns_radiator_clogging_stage2_description",
            detectionChance = 1.0,
            progressMultiplier = 1.0,
            repairPrice = 2.0,
            effects = {
                { id = "RADIATOR_HEALTH_MODIFIER", value = -0.15, aggregation = "min" },
                { id = "ENGINE_HEAT_MODIFIER", value = 0.08, aggregation = "sum" }
            }
        },
        {
            severity = "ads_breakdowns_severity_major",
            description = "ads_breakdowns_radiator_clogging_stage3_description",
            detectionChance = 1.0,
            progressMultiplier = 0.5,
            repairPrice = 4.0,
            effects = {
                { id = "RADIATOR_HEALTH_MODIFIER", value = -0.3, aggregation = "min" },
                { id = "ENGINE_HEAT_MODIFIER", value = 0.2, aggregation = "sum" }
            }
        },
        {
            severity = "ads_breakdowns_severity_critical",
            description = "ads_breakdowns_radiator_clogging_stage4_description",
            detectionChance = 1.0,
            progressMultiplier = 0.0,
            repairPrice = 8.0,
            effects = {
                { id = "RADIATOR_HEALTH_MODIFIER", value = -0.5, aggregation = "min", extraData = {
    message = "ads_breakdowns_radiator_clogging_stage4_message",
    disableAi = true
} },
                { id = "ENGINE_HEAT_MODIFIER", value = 0.4, aggregation = "sum" }
            }
        }
    }
}

ADS_Breakdowns.BreakdownRegistry.WATER_PUMP_WEAR = {
    isSelectable = true,
    system = systems.COOLING,
    part = parts.WATER_PUMP,
    isApplicable = function(vehicle)
        return not adsExtraIsElectricVehicle(vehicle)
    end,
    probability = function(vehicle)
        return adsExtraGetProbabilityWeight(vehicle, systems.COOLING)
    end,
    isCanProgress = function(vehicle)
        return vehicle:getLastSpeed() > 0.01
    end,
    stages = {
        {
            severity = "ads_breakdowns_severity_minor",
            description = "ads_breakdowns_water_pump_wear_stage1_description",
            detectionChance = 1.0,
            progressMultiplier = 2.0,
            repairPrice = 1.0,
            effects = {
                { id = "ENGINE_HEAT_MODIFIER", value = 0.04, aggregation = "sum" },
                { id = "FAN_CLUTCH_MODIFIER", value = -0.05, aggregation = "min" }
            }
        },
        {
            severity = "ads_breakdowns_severity_moderate",
            description = "ads_breakdowns_water_pump_wear_stage2_description",
            detectionChance = 1.0,
            progressMultiplier = 1.0,
            repairPrice = 2.0,
            effects = {
                { id = "ENGINE_HEAT_MODIFIER", value = 0.1, aggregation = "sum" },
                { id = "FAN_CLUTCH_MODIFIER", value = -0.15, aggregation = "min" }
            }
        },
        {
            severity = "ads_breakdowns_severity_major",
            description = "ads_breakdowns_water_pump_wear_stage3_description",
            detectionChance = 1.0,
            progressMultiplier = 0.5,
            repairPrice = 4.0,
            effects = {
                { id = "ENGINE_HEAT_MODIFIER", value = 0.22, aggregation = "sum" },
                { id = "FAN_CLUTCH_MODIFIER", value = -0.3, aggregation = "min" }
            }
        },
        {
            severity = "ads_breakdowns_severity_critical",
            description = "ads_breakdowns_water_pump_wear_stage4_description",
            detectionChance = 1.0,
            progressMultiplier = 0.0,
            repairPrice = 8.0,
            effects = {
                { id = "ENGINE_HEAT_MODIFIER", value = 0.45, aggregation = "sum", extraData = {
    message = "ads_breakdowns_water_pump_wear_stage4_message",
    disableAi = true
} },
                { id = "FAN_CLUTCH_MODIFIER", value = -0.5, aggregation = "min" }
            }
        }
    }
}

ADS_Breakdowns.BreakdownRegistry.STARTER_MOTOR_WEAR = {
    isSelectable = true,
    system = systems.ELECTRICAL,
    part = parts.STARTER_MOTOR,
    isApplicable = function(vehicle)
        return not adsExtraIsElectricVehicle(vehicle)
    end,
    probability = function(vehicle)
        return adsExtraGetProbabilityWeight(vehicle, systems.ELECTRICAL)
    end,
    isCanProgress = function(vehicle)
        return vehicle:getLastSpeed() > 0.01
    end,
    stages = {
        {
            severity = "ads_breakdowns_severity_minor",
            description = "ads_breakdowns_starter_motor_wear_stage1_description",
            detectionChance = 1.0,
            progressMultiplier = 2.0,
            repairPrice = 1.0,
            effects = {
                { id = "ENGINE_HARD_START_MODIFIER", value = 1, aggregation = "max", extraData = {
    timer = 0,
    status = "IDLE"
} },
                { id = "ENGINE_STALLS_CHANCE", value = 40.0, aggregation = "min" }
            }
        },
        {
            severity = "ads_breakdowns_severity_moderate",
            description = "ads_breakdowns_starter_motor_wear_stage2_description",
            detectionChance = 1.0,
            progressMultiplier = 1.0,
            repairPrice = 2.0,
            effects = {
                { id = "ENGINE_HARD_START_MODIFIER", value = 2, aggregation = "max", extraData = {
    timer = 0,
    status = "IDLE"
} },
                { id = "ENGINE_STALLS_CHANCE", value = 25.0, aggregation = "min" }
            }
        },
        {
            severity = "ads_breakdowns_severity_major",
            description = "ads_breakdowns_starter_motor_wear_stage3_description",
            detectionChance = 1.0,
            progressMultiplier = 0.5,
            repairPrice = 4.0,
            effects = {
                { id = "ENGINE_HARD_START_MODIFIER", value = 3, aggregation = "max", extraData = {
    timer = 0,
    status = "IDLE"
} },
                { id = "ENGINE_STALLS_CHANCE", value = 15.0, aggregation = "min" }
            }
        },
        {
            severity = "ads_breakdowns_severity_critical",
            description = "ads_breakdowns_starter_motor_wear_stage4_description",
            detectionChance = 1.0,
            progressMultiplier = 0.0,
            repairPrice = 8.0,
            effects = {
                { id = "ENGINE_HARD_START_MODIFIER", value = 5, aggregation = "max", extraData = {
    timer = 0,
    status = "IDLE",
    message = "ads_breakdowns_starter_motor_wear_stage4_message",
    disableAi = true
} },
                { id = "ENGINE_STALLS_CHANCE", value = 8.0, aggregation = "min" }
            }
        }
    }
}

ADS_Breakdowns.BreakdownRegistry.LIGHTING_CIRCUIT_FAULT = {
    isSelectable = true,
    system = systems.ELECTRICAL,
    part = parts.LIGHTING_CIRCUIT,
    probability = function(vehicle)
        return adsExtraGetProbabilityWeight(vehicle, systems.ELECTRICAL)
    end,
    isCanProgress = function(vehicle)
        return vehicle:getLastSpeed() > 0.01
    end,
    stages = {
        {
            severity = "ads_breakdowns_severity_minor",
            description = "ads_breakdowns_lighting_circuit_fault_stage1_description",
            detectionChance = 1.0,
            progressMultiplier = 2.0,
            repairPrice = 1.0,
            effects = {
                { id = "LIGHTS_FLICKER_CHANCE", value = 0.4, aggregation = "min", extraData = {
    timer = 0,
    status = "IDLE",
    duration = 200,
    maskBackup = 0
} },
                { id = "ELECTRICAL_CONTACT_RESISTANCE_EFFECT", value = 0.8, aggregation = "min", extraData = {
    timer = 0,
    status = "IDLE"
} }
            }
        },
        {
            severity = "ads_breakdowns_severity_moderate",
            description = "ads_breakdowns_lighting_circuit_fault_stage2_description",
            detectionChance = 1.0,
            progressMultiplier = 1.0,
            repairPrice = 2.0,
            effects = {
                { id = "LIGHTS_FLICKER_CHANCE", value = 0.25, aggregation = "min", extraData = {
    timer = 0,
    status = "IDLE",
    duration = 250,
    maskBackup = 0
} },
                { id = "ELECTRICAL_CONTACT_RESISTANCE_EFFECT", value = 0.5, aggregation = "min", extraData = {
    timer = 0,
    status = "IDLE"
} }
            }
        },
        {
            severity = "ads_breakdowns_severity_major",
            description = "ads_breakdowns_lighting_circuit_fault_stage3_description",
            detectionChance = 1.0,
            progressMultiplier = 0.5,
            repairPrice = 4.0,
            effects = {
                { id = "LIGHTS_FLICKER_CHANCE", value = 0.15, aggregation = "min", extraData = {
    timer = 0,
    status = "IDLE",
    duration = 300,
    maskBackup = 0
} },
                { id = "ELECTRICAL_CONTACT_RESISTANCE_EFFECT", value = 0.25, aggregation = "min", extraData = {
    timer = 0,
    status = "IDLE"
} }
            }
        },
        {
            severity = "ads_breakdowns_severity_critical",
            description = "ads_breakdowns_lighting_circuit_fault_stage4_description",
            detectionChance = 1.0,
            progressMultiplier = 0.0,
            repairPrice = 8.0,
            effects = {
                { id = "LIGHTS_FLICKER_CHANCE", value = 0.05, aggregation = "min", extraData = {
    timer = 0,
    status = "IDLE",
    duration = 350,
    maskBackup = 0,
    message = "ads_breakdowns_lighting_circuit_fault_stage4_message",
    disableAi = true
} },
                { id = "ELECTRICAL_CONTACT_RESISTANCE_EFFECT", value = 0.05, aggregation = "min", extraData = {
    timer = 0,
    status = "IDLE"
} }
            }
        }
    }
}

ADS_Breakdowns.BreakdownRegistry.SUSPENSION_BUSHING_WEAR = {
    isSelectable = true,
    system = systems.CHASSIS,
    part = parts.SUSPENSION_BUSHING,
    probability = function(vehicle)
        return adsExtraGetProbabilityWeight(vehicle, systems.CHASSIS)
    end,
    isCanProgress = function(vehicle)
        return vehicle:getLastSpeed() > 0.01
    end,
    stages = {
        {
            severity = "ads_breakdowns_severity_minor",
            description = "ads_breakdowns_suspension_bushing_wear_stage1_description",
            detectionChance = 1.0,
            progressMultiplier = 2.0,
            repairPrice = 1.0,
            effects = {
                { id = "STEERING_SENSITIVITY_MODIFIER", value = 0.08, aggregation = "max" },
                { id = "VIBRATION_NOISE_EFFECT", value = 0.4, aggregation = "max" }
            }
        },
        {
            severity = "ads_breakdowns_severity_moderate",
            description = "ads_breakdowns_suspension_bushing_wear_stage2_description",
            detectionChance = 1.0,
            progressMultiplier = 1.0,
            repairPrice = 2.0,
            effects = {
                { id = "STEERING_SENSITIVITY_MODIFIER", value = 0.2, aggregation = "max" },
                { id = "VIBRATION_NOISE_EFFECT", value = 0.9, aggregation = "max" }
            }
        },
        {
            severity = "ads_breakdowns_severity_major",
            description = "ads_breakdowns_suspension_bushing_wear_stage3_description",
            detectionChance = 1.0,
            progressMultiplier = 0.5,
            repairPrice = 4.0,
            effects = {
                { id = "STEERING_SENSITIVITY_MODIFIER", value = 0.35, aggregation = "max" },
                { id = "VIBRATION_NOISE_EFFECT", value = 1.4, aggregation = "max" }
            }
        },
        {
            severity = "ads_breakdowns_severity_critical",
            description = "ads_breakdowns_suspension_bushing_wear_stage4_description",
            detectionChance = 1.0,
            progressMultiplier = 0.0,
            repairPrice = 8.0,
            effects = {
                { id = "STEERING_SENSITIVITY_MODIFIER", value = 0.6, aggregation = "max", extraData = {
    message = "ads_breakdowns_suspension_bushing_wear_stage4_message",
    disableAi = true
} },
                { id = "VIBRATION_NOISE_EFFECT", value = 2.0, aggregation = "max" }
            }
        }
    }
}

ADS_Breakdowns.BreakdownRegistry.FUEL_TANK_CONTAMINATION = {
    isSelectable = true,
    system = systems.FUEL,
    part = parts.FUEL_TANK,
    probability = function(vehicle)
        return adsExtraGetProbabilityWeight(vehicle, systems.FUEL)
    end,
    isCanProgress = function(vehicle)
        return vehicle:getLastSpeed() > 0.01
    end,
    stages = {
        {
            severity = "ads_breakdowns_severity_minor",
            description = "ads_breakdowns_fuel_tank_contamination_stage1_description",
            detectionChance = 1.0,
            progressMultiplier = 2.0,
            repairPrice = 1.0,
            effects = {
                { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.1, aggregation = "sum" },
                { id = "ENGINE_HESITATION_CHANCE", value = 0.15, aggregation = "max", extraData = {
    timer = 0,
    duration = 300,
    status = "IDLE",
    amplitude = 0.5,
    motorLoad = 0.8,
    cruiseState = 0
} }
            }
        },
        {
            severity = "ads_breakdowns_severity_moderate",
            description = "ads_breakdowns_fuel_tank_contamination_stage2_description",
            detectionChance = 1.0,
            progressMultiplier = 1.0,
            repairPrice = 2.0,
            effects = {
                { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.25, aggregation = "sum" },
                { id = "ENGINE_HESITATION_CHANCE", value = 0.3, aggregation = "max", extraData = {
    timer = 0,
    duration = 400,
    status = "IDLE",
    amplitude = 0.7,
    motorLoad = 0.7,
    cruiseState = 0
} }
            }
        },
        {
            severity = "ads_breakdowns_severity_major",
            description = "ads_breakdowns_fuel_tank_contamination_stage3_description",
            detectionChance = 1.0,
            progressMultiplier = 0.5,
            repairPrice = 4.0,
            effects = {
                { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.45, aggregation = "sum" },
                { id = "ENGINE_HESITATION_CHANCE", value = 0.5, aggregation = "max", extraData = {
    timer = 0,
    duration = 500,
    status = "IDLE",
    amplitude = 0.9,
    motorLoad = 0.6,
    cruiseState = 0
} }
            }
        },
        {
            severity = "ads_breakdowns_severity_critical",
            description = "ads_breakdowns_fuel_tank_contamination_stage4_description",
            detectionChance = 1.0,
            progressMultiplier = 0.0,
            repairPrice = 8.0,
            effects = {
                { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.7, aggregation = "sum" },
                { id = "ENGINE_HESITATION_CHANCE", value = 0.8, aggregation = "max", extraData = {
    timer = 0,
    duration = 600,
    status = "IDLE",
    amplitude = 1.0,
    motorLoad = 0.5,
    cruiseState = 0,
    message = "ads_breakdowns_fuel_tank_contamination_stage4_message",
    disableAi = true
} }
            }
        }
    }
}


-- ===========================================================
--     HYDRAULIC SUSPENSION SYSTEM (Zasty Chalk) INTEGRATION
-- ===========================================================
-- Three front-axle suspension faults that only appear on tractors where
-- FS25_HydraulicSuspensionSystem is active. ADS only decides WHEN they
-- happen and how bad they are; the suspension mod reads the HSS_* effects
-- below from vehicle.spec_AdvancedDamageSystem.activeEffects and changes
-- the actual suspension (spring, damping, levelling, ride height, lock).
--
--   HSS_SPRING_MODIFIER        sum   +0.5 = 50 % stiffer front spring
--   HSS_DAMP_MODIFIER          sum   -0.3 = 30 % less damping (bouncy)
--   HSS_LEVEL_RATE_MODIFIER    min   -1.0 = auto-levelling can't move the cylinders
--   HSS_SAG_EFFECT             max   front sits lower (fraction of axle travel)
--   HSS_SENSOR_FAULT_EFFECT    max   levelling hunts up/down (fraction of travel)
--   HSS_FAILSAFE_LOCK_EFFECT   max   controller locks the suspension, can't be switched

do
    local hssColor = ADS_Breakdowns.COLORS
    local hssDb = ADS_Breakdowns.DASHBOARD

    ADS_Breakdowns.PARTS.FRONT_AXLE_ACCUMULATOR = "ads_breakdowns_part_front_axle_accumulator"
    ADS_Breakdowns.PARTS.FRONT_SUSPENSION_CYLINDER = "ads_breakdowns_part_front_suspension_cylinder"
    ADS_Breakdowns.PARTS.SUSPENSION_HEIGHT_SENSOR = "ads_breakdowns_part_suspension_height_sensor"

    -- the suspension mod is installed and actually runs on this tractor
    function adsHasHydraulicSuspension(vehicle)
        local hss = vehicle ~= nil and vehicle.spec_hydraulicSuspension or nil
        return hss ~= nil and hss.enabled == true
    end

    local function isMoving(vehicle)
        return vehicle:getLastSpeed() > 0.01
    end

    local function isRunning(vehicle)
        return vehicle.getIsMotorStarted ~= nil and vehicle:getIsMotorStarted()
    end

    -- Nitrogen charge leaking out of the axle accumulator: the gas spring
    -- gets hard and the axle starts to bounce. Likelier with a front loader
    -- (heavy, swinging load) and on fast road work.
    ADS_Breakdowns.BreakdownRegistry.FRONT_AXLE_ACCUMULATOR_FAILURE = {
        isSelectable = true,
        system = systems.CHASSIS,
        part = ADS_Breakdowns.PARTS.FRONT_AXLE_ACCUMULATOR,
        isApplicable = adsHasHydraulicSuspension,
        probability = function(vehicle)
            local weight = adsExtraGetProbabilityWeight(vehicle, systems.CHASSIS)
            local hss = vehicle.spec_hydraulicSuspension
            if hss ~= nil and hss.hasLoader then
                weight = weight * 1.4
            end
            return weight
        end,
        isCanProgress = isMoving,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_front_axle_accumulator_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0,
                repairPrice = 1.0 * 0.60,
                effects = {
                    { id = "HSS_SPRING_MODIFIER", value = 0.15, aggregation = "sum" },
                    { id = "HSS_DAMP_MODIFIER", value = -0.10, aggregation = "sum" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_front_axle_accumulator_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0,
                repairPrice = 2.0 * 0.60,
                effects = {
                    { id = "HSS_SPRING_MODIFIER", value = 0.40, aggregation = "sum" },
                    { id = "HSS_DAMP_MODIFIER", value = -0.25, aggregation = "sum" },
                    { id = "VIBRATION_NOISE_EFFECT", value = 0.5, aggregation = "max" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_front_axle_accumulator_stage2" },
                },
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_front_axle_accumulator_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5,
                repairPrice = 4.0 * 0.60,
                effects = {
                    { id = "HSS_SPRING_MODIFIER", value = 0.80, aggregation = "sum" },
                    { id = "HSS_DAMP_MODIFIER", value = -0.40, aggregation = "sum" },
                    { id = "VIBRATION_NOISE_EFFECT", value = 1.0, aggregation = "max" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.10, aggregation = "max" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_front_axle_accumulator_stage3" },
                },
                indicators = {
                    { id = hssDb.WARNING, color = hssColor.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_front_axle_accumulator_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * 0.60,
                effects = {
                    { id = "HSS_SPRING_MODIFIER", value = 1.50, aggregation = "sum" },
                    { id = "HSS_DAMP_MODIFIER", value = -0.55, aggregation = "sum" },
                    { id = "VIBRATION_NOISE_EFFECT", value = 1.6, aggregation = "max" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.25, aggregation = "max", extraData = { message = "ads_breakdowns_front_axle_accumulator_stage4_message" } },
                },
                inspection = {
                    { additional = "ads_inspection_hint_front_axle_accumulator_stage4" },
                },
                indicators = {
                    { id = hssDb.WARNING, color = hssColor.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    }

    -- Worn seals in the front suspension cylinders: oil bypasses, the front
    -- sinks and the levelling pump has to keep topping it up. At the end
    -- it can't hold the axle and it sits down on the bump stops.
    ADS_Breakdowns.BreakdownRegistry.FRONT_SUSPENSION_CYLINDER_LEAK = {
        isSelectable = true,
        system = systems.HYDRAULICS,
        part = ADS_Breakdowns.PARTS.FRONT_SUSPENSION_CYLINDER,
        isApplicable = adsHasHydraulicSuspension,
        probability = function(vehicle)
            return adsExtraGetProbabilityWeight(vehicle, systems.HYDRAULICS)
        end,
        isCanProgress = isMoving,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_front_suspension_cylinder_leak_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0,
                repairPrice = 1.0 * 0.80,
                effects = {
                    { id = "HSS_SAG_EFFECT", value = 0.10, aggregation = "max" },
                    { id = "HSS_LEVEL_RATE_MODIFIER", value = -0.10, aggregation = "min" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_front_suspension_cylinder_leak_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0,
                repairPrice = 2.0 * 0.80,
                effects = {
                    { id = "HSS_SAG_EFFECT", value = 0.25, aggregation = "max" },
                    { id = "HSS_LEVEL_RATE_MODIFIER", value = -0.30, aggregation = "min" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_front_suspension_cylinder_leak_stage2" },
                },
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_front_suspension_cylinder_leak_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5,
                repairPrice = 4.0 * 0.80,
                effects = {
                    { id = "HSS_SAG_EFFECT", value = 0.45, aggregation = "max" },
                    { id = "HSS_LEVEL_RATE_MODIFIER", value = -0.55, aggregation = "min" },
                    { id = "HYDRAULIC_SPEED_MODIFIER", value = -0.05, aggregation = "min" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_front_suspension_cylinder_leak_stage3" },
                },
                indicators = {
                    { id = hssDb.WARNING, color = hssColor.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_front_suspension_cylinder_leak_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * 0.80,
                effects = {
                    { id = "HSS_SAG_EFFECT", value = 0.70, aggregation = "max" },
                    { id = "HSS_LEVEL_RATE_MODIFIER", value = -1.0, aggregation = "min" },
                    { id = "HSS_SPRING_MODIFIER", value = 1.0, aggregation = "sum" },
                    { id = "HYDRAULIC_SPEED_MODIFIER", value = -0.10, aggregation = "min" },
                    { id = "VIBRATION_NOISE_EFFECT", value = 1.5, aggregation = "max" },
                    { id = "MAX_SPEED_MODIFIER", value = 0.30, aggregation = "max", extraData = { message = "ads_breakdowns_front_suspension_cylinder_leak_stage4_message" } },
                },
                inspection = {
                    { additional = "ads_inspection_hint_front_suspension_cylinder_leak_stage4" },
                },
                indicators = {
                    { id = hssDb.WARNING, color = hssColor.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    }

    -- Axle height sensor going bad: the controller gets a wrong ride height,
    -- so the levelling keeps hunting up and down. At the last stage the
    -- controller gives up and locks the suspension (fail-safe), like the
    -- real systems do.
    ADS_Breakdowns.BreakdownRegistry.SUSPENSION_HEIGHT_SENSOR_FAULT = {
        isSelectable = true,
        system = systems.ELECTRICAL,
        part = ADS_Breakdowns.PARTS.SUSPENSION_HEIGHT_SENSOR,
        isApplicable = adsHasHydraulicSuspension,
        probability = function(vehicle)
            return adsExtraGetProbabilityWeight(vehicle, systems.ELECTRICAL)
        end,
        isCanProgress = isRunning,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_suspension_height_sensor_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0,
                repairPrice = 1.0 * 0.30,
                effects = {
                    { id = "HSS_SENSOR_FAULT_EFFECT", value = 0.08, aggregation = "max" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_suspension_height_sensor_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0,
                repairPrice = 2.0 * 0.30,
                effects = {
                    { id = "HSS_SENSOR_FAULT_EFFECT", value = 0.15, aggregation = "max" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_suspension_height_sensor_stage2" },
                },
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_suspension_height_sensor_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5,
                repairPrice = 4.0 * 0.30,
                effects = {
                    { id = "HSS_SENSOR_FAULT_EFFECT", value = 0.25, aggregation = "max" },
                },
                inspection = {
                    { additional = "ads_inspection_hint_suspension_height_sensor_stage3" },
                },
                indicators = {
                    { id = hssDb.WARNING, color = hssColor.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_suspension_height_sensor_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * 0.30,
                effects = {
                    { id = "HSS_FAILSAFE_LOCK_EFFECT", value = 1.0, aggregation = "max", extraData = { message = "ads_breakdowns_suspension_height_sensor_stage4_message" } },
                },
                inspection = {
                    { additional = "ads_inspection_hint_suspension_height_sensor_stage4" },
                },
                indicators = {
                    { id = hssDb.WARNING, color = hssColor.WARNING, switchOn = true, switchOff = false }
                }
            }
        }
    }

    -- The suspension mod does the actual work; these only exist so ADS knows
    -- the effect ids.
    for _, effectId in ipairs({ "HSS_SPRING_MODIFIER", "HSS_DAMP_MODIFIER", "HSS_LEVEL_RATE_MODIFIER",
        "HSS_SAG_EFFECT", "HSS_SENSOR_FAULT_EFFECT", "HSS_FAILSAFE_LOCK_EFFECT" }) do
        if ADS_Breakdowns.EffectApplicators[effectId] == nil then
            ADS_Breakdowns.EffectApplicators[effectId] = {
                apply = function(vehicle, effectData, handler) end,
                remove = function(vehicle, handler) end
            }
        end
    end
end
