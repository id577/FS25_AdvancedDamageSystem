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

local breakdownPriceMultipliers = {
    ECU_MALFUNCTION = 0.60,
    ELECTRICAL_SYSTEM_MALFUNCTION = 0.45,
    TURBOCHARGER_MALFUNCTION = 1.00, -- 1% price
    OIL_PUMP_MALFUNCTION = 1.50,
    VALVE_TRAIN_MALFUNCTION = 1.60,
    MANUAL_TRANSMISSION_CLUTCH_WEAR = 1.30,
    MANUAL_TRANSMISSION_SYNCHRONIZER_MALFUNCTION = 1.10,
    POWERSHIFT_HYDRAULIC_PUMP_MALFUNCTION = 2.40,
    CVT_CHAIN_WEAR = 2.60,
    CVT_HYDRAULIC_CONTROL_VALVE_MALFUNCTION = 2.80,
    HYDRAULIC_PUMP_MALFUNCTION = 0.90,
    HYDRAULIC_CYLINDER_INTERNAL_LEAK = 1.0,
    PTO_CLUTCH_SLIP = 1.25,
    BRAKE_MALFUNCTION = 0.35,
    BEARING_WEAR = 0.55,
    STEERING_LINKAGE_WEAR = 0.45,
    TRACK_TENSIONER_MALFUNCTION = 0.80,
    CVT_THERMOSTAT_MALFUNCTION = 0.50,
    THERMOSTAT_MALFUNCTION = 0.50,
    COOLANT_LEAK = 0.80,
    FAN_CLUTCH_FAILURE = 0.65,
    FUEL_PUMP_MALFUNCTION = 0.55,
    FUEL_INJECTOR_MALFUNCTION = 0.80,
    CARBURETOR_CLOGGING = 0.25,
    YIELD_SENSOR_MALFUNCTION = 0.30,
    MATERIAL_FLOW_SYSTEM_WEAR = 0.35,
    UNLOADING_AUGER_MALFUNCTION = 0.40,
}

local breakdownProgressMultipliers = {
    ECU_MALFUNCTION = 1.00, -- 3.5 hours
    ELECTRICAL_SYSTEM_MALFUNCTION = 0.9,
    TURBOCHARGER_MALFUNCTION = 1.1,
    OIL_PUMP_MALFUNCTION = 1.3,
    VALVE_TRAIN_MALFUNCTION = 1.4,
    MANUAL_TRANSMISSION_CLUTCH_WEAR = 1.00,
    MANUAL_TRANSMISSION_SYNCHRONIZER_MALFUNCTION = 1.3,
    POWERSHIFT_HYDRAULIC_PUMP_MALFUNCTION = 1.1,
    CVT_CHAIN_WEAR = 1.2,
    CVT_HYDRAULIC_CONTROL_VALVE_MALFUNCTION = 1.1,
    HYDRAULIC_PUMP_MALFUNCTION = 1.1,
    HYDRAULIC_CYLINDER_INTERNAL_LEAK = 0.6,
    PTO_CLUTCH_SLIP = 0.75,
    BRAKE_MALFUNCTION = 0.9,
    BEARING_WEAR = 1.2,
    STEERING_LINKAGE_WEAR = 1.2,
    TRACK_TENSIONER_MALFUNCTION = 1.3,
    CVT_THERMOSTAT_MALFUNCTION = 1.4,
    THERMOSTAT_MALFUNCTION = 1.4,
    COOLANT_LEAK = 0.6,
    FAN_CLUTCH_FAILURE = 0.9,
    FUEL_PUMP_MALFUNCTION = 1.1,
    FUEL_INJECTOR_MALFUNCTION = 1.1,
    CARBURETOR_CLOGGING = 0.9,
    YIELD_SENSOR_MALFUNCTION = 1.1,
    MATERIAL_FLOW_SYSTEM_WEAR = 1.0,
    UNLOADING_AUGER_MALFUNCTION = 1.2
}

ADS_Breakdowns.BreakdownRegistry = {

--------------------- NOT SELECTEBLE BREAKDOWNS (does not happen by chance, but is the result of various conditions) ---------------------

-- additional debuffs for aging equipment, in addition to the standard ones (torque for motorized, fillDelta for combine)
    ENGINE_WEAR = {
        system = systems.ENGINE,
        isSelectable = false,
        part = "ads_breakdowns_part_vehicle",
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
                effects = {
                    {
                        id = "ENGINE_TORQUE_MODIFIER",
                        value = function(vehicle)
                            local baseEffect = -0.30
                            local condition = vehicle:getConditionLevel()
                            local multiplier = (1 - condition) ^ 3
                            return baseEffect * multiplier
                        end,
                        aggregation = "sum"
                    }
                },
                indicators = {}
            }
        }
    },

    TRANSMISSION_WEAR = {
        system = systems.TRANSMISSION,
        isSelectable = false,
        part = "ads_breakdowns_part_vehicle",
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

    HYDRAULICS_WEAR = {
        system = systems.HYDRAULICS,
        isSelectable = false,
        part = "ads_breakdowns_part_vehicle",
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

    COOLING_WEAR = {
        system = systems.COOLING,
        isSelectable = false,
        part = "ads_breakdowns_part_vehicle",
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
                effects = {
                    {
                        id = "THERMOSTAT_HEALTH_MODIFIER",
                        value = function(vehicle)
                            local baseEffect = -0.30
                            local condition = vehicle:getConditionLevel()
                            local multiplier = (1 - condition) ^ 3
                            return baseEffect * multiplier
                        end,
                        aggregation = "min"
                    }
                },
                indicators = {}
            }
        }
    },

    ELECTRICAL_WEAR = {
        system = systems.ELECTRICAL,
        isSelectable = false,
        part = "ads_breakdowns_part_vehicle",
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
                effects = {
                    {
                        id = "ENGINE_START_FAILURE_CHANCE",
                        value = function(vehicle)
                            local baseEffect = 0.66
                            local condition = vehicle:getConditionLevel()
                            local multiplier = (1 - condition) ^ 3
                            return baseEffect * multiplier
                        end,
                        aggregation = "max",
                        extraData = {timer = 0, status = 'IDLE', count = 0}
                    }
                },
                indicators = {}
            }
        }
    },

    CHASSIS_WEAR = {
        system = systems.CHASSIS,
        isSelectable = false,
        part = "ads_breakdowns_part_vehicle",
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
                effects = {
                    {
                        id = "BRAKE_FORCE_MODIFIER",
                        value = function(vehicle)
                            local baseEffect = -0.3
                            local condition = vehicle:getConditionLevel()
                            local multiplier = (1 - condition) ^ 3
                            return baseEffect * multiplier
                        end,
                        aggregation = "min"
                    }
                },
                indicators = {}
            }
        }
    },

    WORKPROCESS_WEAR = {
        system = systems.WORKPROCESS,
        isSelectable = false,
        part = "ads_breakdowns_part_vehicle",
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
                effects = {
                    {
                        id = "YIELD_REDUCTION_MODIFIER",
                        value = function(vehicle)
                            local baseEffect = -0.30
                            local condition = vehicle:getConditionLevel()
                            local multiplier = (1 - condition) ^ 3
                            return baseEffect * multiplier
                        end,
                        aggregation = "sum",
                        extraData = {timer = 0, status = 'IDLE'}
                    }
                },
                indicators = {}
            }
        }
    },

    FUEL_WEAR = {
        system = systems.FUEL,
        isSelectable = false,
        part = "ads_breakdowns_part_vehicle",
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

    MAINTENANCE_WITH_POOR_QUALITY_CONSUMABLES = {
        isSelectable = false,
        system = "ads_breakdowns_part_vehicle",
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
        system = "ads_breakdowns_part_engine",
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
        system = "ads_breakdowns_part_engine",
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
        isApplicable = function(vehicle)
            local spec = vehicle.spec_AdvancedDamageSystem
            if spec.year >= 2000 and not getIsElectricVehicle(vehicle) then
                return true
            end
            return false
        end,
        probability = function(vehicle)
            return 1.0 
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
                    { id = "ENGINE_START_FAILURE_CHANCE", value = 0.33, aggregation = "max", extraData = { timer = 0, status = 'IDLE', count = 0}},
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

    ELECTRICAL_SYSTEM_MALFUNCTION = {
        isSelectable = true,
        system = systems.ELECTRICAL,
        isApplicable = function(vehicle)
            local spec = vehicle.spec_AdvancedDamageSystem
            return spec.year >= 2000 and vehicle.spec_lights ~= nil
        end,
        probability = function(vehicle)
            return 1.0   
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_electrical_system_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.ELECTRICAL_SYSTEM_MALFUNCTION,
                repairPrice = 1.0 * breakdownPriceMultipliers.ELECTRICAL_SYSTEM_MALFUNCTION,
                effects = {
                    { id = "LIGHTS_FLICKER_CHANCE", value = 1.0, extraData = {timer = 0, status = 'IDLE', duration = 200, maskBackup = 0}, aggregation = "min"},
                    { id = "ENGINE_START_FAILURE_CHANCE", value = 0.33, extraData = { timer = 0, status = 'IDLE', count = 0}, aggregation = "max"}

                }
            },
            {
                severity = "ads_breakdowns_severity_moderate", 
                description = "ads_breakdowns_electrical_system_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.ELECTRICAL_SYSTEM_MALFUNCTION,
                repairPrice = 2.0 * breakdownPriceMultipliers.ELECTRICAL_SYSTEM_MALFUNCTION,
                effects = {
                    { id = "LIGHTS_FLICKER_CHANCE", value = 0.33, extraData = {timer = 0, status = 'IDLE', duration = 300, maskBackup = 0}, aggregation = "min" },
                    { id = "ENGINE_STALLS_CHANCE", value = 20.0, aggregation = "min" },
                    { id = "ENGINE_START_FAILURE_CHANCE", value = 0.66, extraData = { timer = 0, status = 'IDLE'}, aggregation = "max"},
                    { id = "CVT_THERMOSTAT_HEALTH_MODIFIER", value = -0.1, aggregation = "min"},
                    { id = "THERMOSTAT_HEALTH_MODIFIER", value = -0.2, aggregation = "min"}
                },
                indicators = {
                    { id = db.BATTERY, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_electrical_system_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.ELECTRICAL_SYSTEM_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.ELECTRICAL_SYSTEM_MALFUNCTION,
                effects = { 
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.10, aggregation = "sum"},
                    { id = "LIGHTS_FAILURE", value = 1.0, extraData = {message = "ads_breakdowns_electrical_system_malfunction_stage3_message"}, aggregation = "boolean_or" },
                    { id = "ENGINE_STALLS_CHANCE", value = 10.0, aggregation = "min" },
                    { id = "ENGINE_START_FAILURE_CHANCE", value = 0.99, extraData = { timer = 0, status = 'IDLE', count = 0}, aggregation = "max"},
                    { id = "CVT_THERMOSTAT_HEALTH_MODIFIER", value = -0.2, aggregation = "min"},
                    { id = "THERMOSTAT_HEALTH_MODIFIER", value = -0.4, aggregation = "min"}
                },
                indicators = {
                    { id = db.BATTERY, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_electrical_system_malfunction_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.ELECTRICAL_SYSTEM_MALFUNCTION,
                effects = { 
                    { id = "LIGHTS_FAILURE", value = 1.0, aggregation = "boolean_or" },
                    { id = "ENGINE_FAILURE", value = 1.0, extraData = {starter = false, message = "ads_breakdowns_electrical_system_malfunction_stage4_message", reason = "BREAKDOWN", disableAi = true}, aggregation = "boolean_or"} 
                },
                indicators = {
                    { id = db.BATTERY, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- engine
    TURBOCHARGER_MALFUNCTION = { -- TO-DO: add names
        isSelectable = true,
        system = systems.ENGINE,
        isApplicable = function(vehicle)
            local name = vehicle:getFullName()
            if name == "Fiat 160-90 DT" then return true end
            return false
        end,
        probability = function(vehicle)
            return 1.0   
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
                    { id = "ENGINE_STALLS_CHANCE", value = 10.0, aggregation = "min" }, },
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false },
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
    },
    

    -- Oil Pump Malfunction
    -- Reduced oil pressure and unstable lubrication. 
    -- Engine knocking appears, power drops, overheating risk increases, 
    -- and in advanced stages the engine may stall or fail.

    OIL_PUMP_MALFUNCTION = { -- TO-DO: $l10n
        isSelectable = true,
        system = systems.ENGINE,
        isApplicable = function(vehicle)
            return not getIsElectricVehicle(vehicle)
        end,
        probability = function(vehicle)
            return 1.0   
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
                indicators = {
                    { id = db.ENGINE, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_oil_pump_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.OIL_PUMP_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.OIL_PUMP_MALFUNCTION,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.45, aggregation = "sum" },
                    { id = "ENGINE_STALLS_CHANCE", value = 10.0, aggregation = "min" },
                    { id = "ENGINE_KNOCKING_NOISE_EFFECT", value = 0.8, aggregation = "max" },
                    { id = "ENGINE_HEAT_MODIFIER", value = 0.35, aggregation = "sum" },
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
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                
                }
            }
        }
    },

    -- Valve Train Failure
    -- Progressive wear of camshaft/rocker/valve components. 
    -- Causes metallic ticking, rough running, loss of power at higher RPM, 
    -- misfires under load, and eventual engine shutdown.

    VALVE_TRAIN_MALFUNCTION = { -- TO-DO: $l10n
        isSelectable = false,
        system = systems.ENGINE,
        isApplicable = function(vehicle)
            return not getIsElectricVehicle(vehicle)
        end,
        probability = function(vehicle)
            local spec = vehicle.spec_AdvancedDamageSystem
            if spec.service < ADS_Config.CORE.SERVICE_EXPIRED_THRESHOLD then
                return 3.0
            end
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
                description = "ads_breakdowns_valve_train_malfunction_stage4_description",
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
        isApplicable = function(vehicle)
            local motor = vehicle:getMotor()
            if not motor then return false end
            return motor.minForwardGearRatio == nil
        end,
        probability = function(vehicle)
            return 1.0   
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
                    { id = db.TRANSMISSION, color = color.WARNING, switchOn = true, switchOff = false }
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
                    { id = db.TRANSMISSION, color = color.CRITICAL, switchOn = true, switchOff = false }
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
                    { id = db.TRANSMISSION, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    MANUAL_TRANSMISSION_SYNCHRONIZER_MALFUNCTION = {
        isSelectable = true,
        system = systems.TRANSMISSION,
        isApplicable = function(vehicle)
            local motor = vehicle:getMotor()
            if not motor then return false end
            return motor.minForwardGearRatio == nil and motor.gearType ~= VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT
        end,
        probability = function(vehicle)
            return 1.0   
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
        isApplicable = function(vehicle)
            local motor = vehicle:getMotor()
            if not motor then return false end
            return motor.gearType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT
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
                    { id = db.TRANSMISSION, color = color.WARNING, switchOn = true, switchOff = false }
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
                indicators = {
                    { id = db.TRANSMISSION, color = color.CRITICAL, switchOn = true, switchOff = false }
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
                indicators = {
                    { id = db.TRANSMISSION, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- CVT Chain/Belt Wear
    -- Progressive wear of CVT chain/belt contact surfaces and pulleys.
    -- Causes ratio response lag and slip under load, increases heat generation,
    -- and in advanced stages leads to severe pull loss and drivability issues.

    CVT_CHAIN_WEAR = { -- TO-DO: $l10n
        isSelectable = true,
        system = systems.TRANSMISSION,
        isApplicable = function(vehicle)
            local motor = vehicle:getMotor()
            if not motor then return false end
            if motor.minForwardGearRatio == nil then return false end
            local spec = vehicle.spec_AdvancedDamageSystem
            local activeBreakdowns = spec and spec.activeBreakdowns
            if activeBreakdowns ~= nil and activeBreakdowns.CVT_HYDRAULIC_CONTROL_VALVE_MALFUNCTION ~= nil then
                return false
            end
            return true
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
                    { id = "CVT_SLIP_EFFECT", value = 0.2, extraData = {accumulatedMod = 0.0}, aggregation = "max" },
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
                     { id = "CVT_SLIP_EFFECT", value = 0.4, extraData = {accumulatedMod = 0.0}, aggregation = "max" },
                     { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.20, aggregation = "sum" },
                     { id = "TRANASMISSION_HEAT_MODIFIER", value = 0.1, aggregation = "sum" }
                },
                indicators = {
                    { id = db.TRANSMISSION, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_cvt_chain_wear_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.CVT_CHAIN_WEAR,
                repairPrice = 4.0 * breakdownPriceMultipliers.CVT_CHAIN_WEAR,
                effects = { 
                     { id = "CVT_SLIP_EFFECT", value = 0.6, extraData = {accumulatedMod = 0.0}, aggregation = "max" },
                     { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.25, aggregation = "sum" },
                     { id = "TRANASMISSION_HEAT_MODIFIER", value = 0.15, aggregation = "sum" }
                },
                indicators = {
                    { id = db.TRANSMISSION, color = color.CRITICAL, switchOn = true, switchOff = false }
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
                    { id = db.TRANSMISSION, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- CVT Hydraulic Control Valve Malfunction
    -- Pressure control instability in the CVT hydraulic block.
    -- Causes intermittent pressure drops, torque interruptions and jerky behavior,
    -- with worsening response and potential limp-home operation at critical stage.

    CVT_HYDRAULIC_CONTROL_VALVE_MALFUNCTION = { -- TO-DO: $l10n
        isSelectable = true,
        system = systems.TRANSMISSION,
        isApplicable = function(vehicle)
            local motor = vehicle:getMotor()
            if not motor then return false end
            if motor.minForwardGearRatio == nil then return false end
            local spec = vehicle.spec_AdvancedDamageSystem
            local activeBreakdowns = spec and spec.activeBreakdowns
            if activeBreakdowns ~= nil and activeBreakdowns.CVT_CHAIN_WEAR ~= nil then
                return false
            end
            return true
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
                    { id = "CVT_PRESSURE_DROP_CHANCE", value = 0.5, aggregation = "max", extraData = {timer = 0, duration = 200, status = 'IDLE'}},
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
                    { id = "CVT_PRESSURE_DROP_CHANCE", value = 0.25, aggregation = "max", extraData = {timer = 0, duration = 250, status = 'IDLE'}},
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.1, aggregation = "sum" },
                    { id = "TRANASMISSION_HEAT_MODIFIER", value = 0.05, aggregation = "sum" },
                    { id = "CVT_MAX_RATIO_MODIFIER", value = 0.4, aggregation = "max" },
                    
                },
                indicators = {
                    { id = db.TRANSMISSION, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_hydraulic_control_valve_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.CVT_HYDRAULIC_CONTROL_VALVE_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.CVT_HYDRAULIC_CONTROL_VALVE_MALFUNCTION,
                effects = { 
                    { id = "CVT_PRESSURE_DROP_CHANCE", value = 0.1, aggregation = "max", extraData = {timer = 0, duration = 300, status = 'IDLE'}},
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.2, aggregation = "sum" },
                    { id = "TRANASMISSION_HEAT_MODIFIER", value = 0.1, aggregation = "sum" },
                    { id = "CVT_MAX_RATIO_MODIFIER", value = 0.5, aggregation = "max" },
                },
                indicators = {
                    { id = db.TRANSMISSION, color = color.CRITICAL, switchOn = true, switchOff = false }
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
                     { id = "CVT_PRESSURE_DROP_CHANCE", value = 0.05, aggregation = "max", extraData = {timer = 0, duration = 300, status = 'IDLE'}},
                     { id = "ENGINE_LIMP_EFFECT", value = -0.2, aggregation = "min", extraData = {reason = "BREAKDOWN", message = "ads_breakdowns_hydraulic_control_valve_malfunction_stage4_message", disableAi = true } },
                },
                indicators = {
                    { id = db.TRANSMISSION, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- hydraulic system
    HYDRAULIC_PUMP_MALFUNCTION = {
        isSelectable = true,
        system = systems.HYDRAULICS,
        isApplicable = function(vehicle)
            local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
            if storeItem.categoryName == "TRUCKS" then return false end
            local vtype = vehicle.type.name
            local spec = vehicle.spec_AdvancedDamageSystem
            return vtype ~= "car" and vtype ~= "carFillable" and vtype ~= "motorbike" and spec.year >= 1960
        end,
        probability = function(vehicle)
            return 1.0   
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

    HYDRAULIC_CYLINDER_INTERNAL_LEAK  = { -- TO-DO: $l10n
        isSelectable = true,
        system = systems.HYDRAULICS,
        isApplicable = function(vehicle)
            local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
            if storeItem.categoryName == "TRUCKS" then return false end
            local vtype = vehicle.type.name
            local spec = vehicle.spec_AdvancedDamageSystem
            return vtype ~= "car" and vtype ~= "carFillable" and vtype ~= "motorbike" and spec.year >= 1960
        end,
        probability = function(vehicle)
            return 1.0   
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_hydraulic_cylinder_internal_leak_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.HYDRAULIC_CYLINDER_INTERNAL_LEAK,
                repairPrice = 1.0 * breakdownPriceMultipliers.HYDRAULIC_CYLINDER_INTERNAL_LEAK,
                effects = {
                    { id = "HYDRAULIC_SPEED_MODIFIER", value = -0.20, aggregation = "min" },
                    { id = "HYDRAULIC_HOLD_DRIFT_EFFECT", value = 0.05, aggregation = "max", extraData = {status = 'IDLE', timer = 0, massRatio = 0.5} }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_hydraulic_cylinder_internal_leak_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.HYDRAULIC_CYLINDER_INTERNAL_LEAK,
                repairPrice = 2.0 * breakdownPriceMultipliers.HYDRAULIC_CYLINDER_INTERNAL_LEAK,
                effects = {
                    { id = "HYDRAULIC_SPEED_MODIFIER", value = -0.40, aggregation = "min" },
                    { id = "HYDRAULIC_HOLD_DRIFT_EFFECT", value = 0.1, aggregation = "max", extraData = {status = 'IDLE', timer = 0, massRatio = 0.4}}
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
                    { id = "HYDRAULIC_SPEED_MODIFIER", value = -0.75, aggregation = "min" },
                    { id = "HYDRAULIC_HOLD_DRIFT_EFFECT", value = 0.2, aggregation = "max", extraData = {status = 'IDLE', timer = 0, massRatio = 0.2} }
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
                    { id = "HYDRAULIC_SPEED_MODIFIER", value = -1.0, extraData = {message = 'ads_breakdowns_hydraulic_cylinder_internal_leak_stage4_message', disableAi = true}, aggregation = "min" },
                    { id = "HYDRAULIC_HOLD_DRIFT_EFFECT", value = 1.0, aggregation = "max", extraData = {status = 'IDLE', timer = 0, massRatio = 0.0} }
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
        isApplicable = function(vehicle)
            if vehicle.spec_crawlers ~= nil then
                return #vehicle.spec_crawlers.crawlers == 0
            else
                return true
            end
        end,
        probability = function(vehicle)
            return 1.0   
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

    -- Wheel Hub Bearing Wear
    -- Progressive wear of wheel hub bearings and adjacent running components.
    -- Creates speed-dependent humming and chassis vibration, increases drag and
    -- rolling losses, and at critical stage can lead to wheel seizure.

    BEARING_WEAR = { -- TO-DO: $l10n
        isSelectable = true,
        system = systems.CHASSIS,
        isApplicable = function(vehicle)
            if vehicle.spec_crawlers ~= nil then
                return #vehicle.spec_crawlers.crawlers == 0
            else
                return true
            end
        end,
        probability = function(vehicle)
            return 1.0   
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

    -- Steering Linkage Wear
    -- Progressive wear in tie rods, joints and steering linkage geometry.
    -- Causes constant pull to one side and reduced steering responsiveness,
    -- degrading handling precision and controllability at higher stages.

    STEERING_LINKAGE_WEAR = { -- TO-DO: $l10n
        isSelectable = true,
        system = systems.CHASSIS,
        part = "ads_breakdowns_part_vehicle",
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
            return 1.0
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

    -- Track Tensioner Malfunction
    -- Progressive wear/failure of track tensioning mechanism and guide alignment.
    -- Causes drag, vibration and directional instability under load, with growing
    -- risk of track seizure behavior and severe drivability loss at critical stage.

    TRACK_TENSIONER_MALFUNCTION = { -- TO-DO: $l10n
        isSelectable = true,
        system = systems.CHASSIS,
        part = "ads_breakdowns_part_vehicle",
        isApplicable = function(vehicle)
            if vehicle.spec_crawlers ~= nil and #vehicle.spec_crawlers.crawlers > 0 then
                return true
            end
            return false
        end,
        probability = function(vehicle)
            return 1.0
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
                indicators = {
                    { id = db.BRAKES, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- cooling system
    CVT_THERMOSTAT_MALFUNCTION = {
        isSelectable = true,
        system = systems.COOLING,
        isApplicable = function(vehicle)
            local motor = vehicle:getMotor()
            local spec = vehicle.spec_AdvancedDamageSystem
            if not motor or getIsElectricVehicle(vehicle) then return false end
            if spec.isElectricVehicle then return false end
            return motor.minForwardGearRatio ~= nil and spec.year >= 2000
        end,
        probability = function(vehicle)
            return 1.0   
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_cvt_thermostat_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.CVT_THERMOSTAT_MALFUNCTION,
                repairPrice = 1.0 * breakdownPriceMultipliers.CVT_THERMOSTAT_MALFUNCTION,
                effects = {
                    { id = "CVT_THERMOSTAT_HEALTH_MODIFIER", value = -0.3, aggregation = "min"}
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_cvt_thermostat_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.CVT_THERMOSTAT_MALFUNCTION,
                repairPrice = 2.0 * breakdownPriceMultipliers.CVT_THERMOSTAT_MALFUNCTION,
                effects = {
                    { id = "CVT_THERMOSTAT_HEALTH_MODIFIER", value = -0.6, aggregation = "min"}
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_cvt_thermostat_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.CVT_THERMOSTAT_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.CVT_THERMOSTAT_MALFUNCTION,
                effects = {
                    { id = "CVT_THERMOSTAT_HEALTH_MODIFIER", value = -0.8, aggregation = "min"}
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_cvt_thermostat_malfunction_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.CVT_THERMOSTAT_MALFUNCTION,
                effects = {
                    { id = "CVT_THERMOSTAT_STUCK_EFFECT", value = -1, aggregation = "min"}
                },
                indicators = {
                    { id = db.TRANSMISSION, color = color.CRITICAL, switchOn = true, switchOff = false },
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    THERMOSTAT_MALFUNCTION = {
        isSelectable = true,
        system = systems.COOLING,
        isApplicable = function(vehicle)
            return not getIsElectricVehicle(vehicle)
        end,
        probability = function(vehicle)
            return 1.0   
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

    COOLANT_LEAK = { -- TO-DO: $l10n
        isSelectable = true,
        system = systems.COOLING,
        isApplicable = function(vehicle)
            return not getIsElectricVehicle(vehicle)
        end,
        probability = function(vehicle)
            return 1.0   
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
                indicators = {
                    { id = db.COOLANT, color = color.CRITICAL, switchOn = true, switchOff = false },
                }
            }
        }
    },

    FAN_CLUTCH_FAILURE = { -- TO-DO: $l10n
        isSelectable = true,
        system = systems.COOLING,
        isApplicable = function(vehicle)
            return not getIsElectricVehicle(vehicle)
        end,
        probability = function(vehicle)
            return 1.0   
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_fun_clutch_failure_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.FAN_CLUTCH_FAILURE,
                repairPrice = 1.0 * breakdownPriceMultipliers.FAN_CLUTCH_FAILURE,
                effects = {
                    { id = "FUN_CLUTCH_MODIFIER", value = -0.1, aggregation = "min"},
                    { id = "FAN_CLUTCH_NOISE_EFFECT", value = 0.4, aggregation = "max" }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_fun_clutch_failure_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.FAN_CLUTCH_FAILURE,
                repairPrice = 2.0 * breakdownPriceMultipliers.FAN_CLUTCH_FAILURE,
                effects = {
                    { id = "FUN_CLUTCH_MODIFIER", value = -0.2, aggregation = "min"},
                    { id = "FAN_CLUTCH_NOISE_EFFECT", value = 0.7, aggregation = "max" }
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
                    { id = "FUN_CLUTCH_MODIFIER", value = -0.3, aggregation = "min"},
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
                    { id = "FUN_CLUTCH_MODIFIER", value = -0.5, aggregation = "min"},
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
        part = "ads_breakdowns_part_fuel_pump",
        isApplicable = function(vehicle)
            return not getIsElectricVehicle(vehicle)
        end,
        probability = function(vehicle)
            return 1.0   
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
                    { id = "ENGINE_START_FAILURE_CHANCE", value = 0.33, aggregation = "max", extraData = { timer = 0, status = 'IDLE'}},
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
                    { id = "ENGINE_START_FAILURE_CHANCE", value = 0.5, aggregation = "max", extraData = { timer = 0, status = 'IDLE'}},
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
                    { id = "ENGINE_START_FAILURE_CHANCE", value = 0.66, aggregation = "max", extraData = { timer = 0, status = 'IDLE'}},
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
        part = "ads_breakdowns_part_fuel_injectors",
        isApplicable = function(vehicle)
            return not getIsElectricVehicle(vehicle)
        end,
        probability = function(vehicle)
            return 1.0   
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
                    { id = "ENGINE_START_FAILURE_CHANCE", value = 0.66, aggregation = "max", extraData = { timer = 0, status = 'IDLE'}},
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

    CARBURETOR_CLOGGING = {
        isSelectable = true,
        part = "ads_breakdowns_part_carburetor",
        isApplicable = function(vehicle)
            local spec = vehicle.spec_AdvancedDamageSystem
            return spec.year < 1980 and not getIsElectricVehicle(vehicle)
        end,
        probability = function(vehicle)
            return 1.0   
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_carburetor_clogging_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.CARBURETOR_CLOGGING,
                repairPrice = 1.0 * breakdownPriceMultipliers.CARBURETOR_CLOGGING,
                effects = {
                    { id = "IDLE_HUNTING_EFFECT", value = 0.05, aggregation = "max", extraData = { timer = 0, period = 1800, rpmBackup = 0} },
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.4, extraData = {timer = 0, duration = 200, status = 'IDLE', amplitude = 0.5, motorLoad = 0.8, cruiseState = 0}, aggregation = "max" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_carburetor_clogging_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.CARBURETOR_CLOGGING,
                repairPrice = 2.0 * breakdownPriceMultipliers.CARBURETOR_CLOGGING,
                effects = {
                    { id = "IDLE_HUNTING_EFFECT", value = 0.08, aggregation = "max", extraData = { timer = 0, period = 1600, rpmBackup = 0} },
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.25, extraData = {timer = 0, duration = 300, status = 'IDLE', amplitude = 0.8, motorLoad = 0.6, cruiseState = 0}, aggregation = "max" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.15, aggregation = "sum" }
                },
                indicators = {
                    { id = db.ENGINE, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_carburetor_clogging_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.CARBURETOR_CLOGGING,
                repairPrice = 4.0 * breakdownPriceMultipliers.CARBURETOR_CLOGGING,
                effects = { 
                    { id = "IDLE_HUNTING_EFFECT", value = 0.10, aggregation = "max", extraData = { timer = 0, period = 1500, rpmBackup = 0} },
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.15, extraData = {timer = 0, duration = 500, status = 'IDLE', amplitude = 1.0, motorLoad = 0.5, cruiseState = 0}, aggregation = "max" },
                    { id = "ENGINE_STALLS_CHANCE", value = 8.0, aggregation = "min" },
                    { id = "ENGINE_START_FAILURE_CHANCE", value = 0.4, extraData = { timer = 0, status = 'IDLE'}, aggregation = "max"}
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_carburetor_clogging_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.CARBURETOR_CLOGGING,
                effects = { 
                    { id = "ENGINE_FAILURE", value = 1.0, extraData = {starter = true, message = "ads_breakdowns_carburetor_clogging_stage4_message", reason = "BREAKDOWN", disableAi = true}, aggregation = "boolean_or"} 
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    -- workprocess system
    YIELD_SENSOR_MALFUNCTION = {
        isSelectable = true,
        system = systems.WORKPROCESS,
        isApplicable = function(vehicle)
            local spec = vehicle.spec_AdvancedDamageSystem
            local vtype = vehicle.type.name
            return spec.year > 2000 and (vtype == 'combineDrivable' or vtype == 'combineCutter')
        end,
        probability = function(vehicle)
            if vehicle.getIsTurnedOn ~= nil and vehicle:getIsTurnedOn() then
                return 100.0
            else
                return 1.0
            end
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
                description = "ads_breakdowns_yield_sensor_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.YIELD_SENSOR_MALFUNCTION,
                repairPrice = 1.0 * breakdownPriceMultipliers.YIELD_SENSOR_MALFUNCTION,
                effects = {
                    { id = "YIELD_REDUCTION_MODIFIER", value = -0.05, aggregation = "sum" }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_yield_sensor_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.YIELD_SENSOR_MALFUNCTION,
                repairPrice = 2.0 * breakdownPriceMultipliers.YIELD_SENSOR_MALFUNCTION,
                effects = {
                    { id = "YIELD_REDUCTION_MODIFIER", value = -0.1, aggregation = "sum" },
                },
                indicators = {
                    {  id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_yield_sensor_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.YIELD_SENSOR_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.YIELD_SENSOR_MALFUNCTION,
                effects = { 
                    { id = "YIELD_REDUCTION_MODIFIER", value = -0.2, aggregation = "sum" },
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_yield_sensor_malfunction_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.YIELD_SENSOR_MALFUNCTION,
                effects = { 
                    { id = "YIELD_REDUCTION_MODIFIER", value = -0.4, aggregation = "sum", extraData = {message = 'ads_breakdowns_yield_sensor_malfunction_stage4_message', disableAi = true} },
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },
    
    MATERIAL_FLOW_SYSTEM_WEAR = {
        isSelectable = true,
        system = systems.MATERIALFLOW,
        isApplicable = function(vehicle)
            local vtype = vehicle.type.name
            return (vtype == 'combineDrivable' or vtype == 'combineCutter')
        end,
        probability = function(vehicle)
            if vehicle.getIsTurnedOn ~= nil and vehicle:getIsTurnedOn() then
                return 100.0
            else
                return 1.0
            end
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
                description = "ads_breakdowns_material_flow_system_wear_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0 * breakdownProgressMultipliers.MATERIAL_FLOW_SYSTEM_WEAR,
                repairPrice = 1.0 * breakdownPriceMultipliers.MATERIAL_FLOW_SYSTEM_WEAR,
                effects = {
                    { id = "YIELD_REDUCTION_MODIFIER", value = -0.02, aggregation = "sum" }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_material_flow_system_wear_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.MATERIAL_FLOW_SYSTEM_WEAR,
                repairPrice = 2.0 * breakdownPriceMultipliers.MATERIAL_FLOW_SYSTEM_WEAR,
                effects = {
                    { id = "YIELD_REDUCTION_MODIFIER", value = -0.05, aggregation = "sum" },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.05, aggregation = "sum"}
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_material_flow_system_wear_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.MATERIAL_FLOW_SYSTEM_WEAR,
                repairPrice = 4.0 * breakdownPriceMultipliers.MATERIAL_FLOW_SYSTEM_WEAR,
                effects = { 
                    { id = "YIELD_REDUCTION_MODIFIER", value = -0.10, aggregation = "sum" },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.10, aggregation = "sum"},
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_material_flow_system_wear_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 8.0 * breakdownPriceMultipliers.MATERIAL_FLOW_SYSTEM_WEAR,
                effects = { 
                    { id = "YIELD_REDUCTION_MODIFIER", value = -0.80, aggregation = "sum", extraData = {message = "ads_breakdowns_material_flow_system_wear_stage4_message", disableAi = true}},
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.30, aggregation = "sum"},
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false },
                    { id = db.ENGINE, color = color.WARNING, switchOn = true, switchOff = false }
                }
            }
        }
    },

    UNLOADING_AUGER_MALFUNCTION = {
        isSelectable = true,
        system = systems.MATERIALFLOW,
        isApplicable = function(vehicle)
            local vtype = vehicle.type.name
            return (vtype == 'combineDrivable' or vtype == 'combineCutter') and vehicle.spec_pipe ~= nil
        end,
        probability = function(vehicle)
            if vehicle.getIsTurnedOn ~= nil and vehicle:getIsTurnedOn() then
                if vehicle.spec_dischargeable.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF then
                    return 200.0
                else
                    return 50.0
                end
            else
                return 1.0
            end
        end,
        isCanProgress = function(vehicle)
            if vehicle.getIsTurnedOn ~= nil and vehicle:getIsTurnedOn() then
                if vehicle.spec_dischargeable.currentDischargeState ~= Dischargeable.DISCHARGE_STATE_OFF then
                    return true
                end
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
                    { id = "UNLOADING_SPEED_MODIFIER", value = -0.20, aggregation = "min" }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_unloading_auger_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0 * breakdownProgressMultipliers.UNLOADING_AUGER_MALFUNCTION,
                repairPrice = 2.0 * breakdownPriceMultipliers.UNLOADING_AUGER_MALFUNCTION,
                effects = {
                    { id = "UNLOADING_SPEED_MODIFIER", value = -0.40, aggregation = "min" }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_unloading_auger_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 0.5 * breakdownProgressMultipliers.UNLOADING_AUGER_MALFUNCTION,
                repairPrice = 4.0 * breakdownPriceMultipliers.UNLOADING_AUGER_MALFUNCTION,
                effects = { 
                    { id = "UNLOADING_SPEED_MODIFIER", value = -0.60, aggregation = "min" }
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
    
}
-- ==========================================================
--                     BREAKDOWN EFFECTS
-- ==========================================================

ADS_Breakdowns.EffectApplicators = {}

local function isOrigFuncStillUsed(v, funcName)
    if v == nil or funcName == nil then
        return false
    end
    local spec = v.spec_AdvancedDamageSystem
    if spec == nil or spec.activeEffects == nil then
        return false
    end

    for effectId, _ in pairs(spec.activeEffects) do
        local applicator = ADS_Breakdowns.EffectApplicators[effectId]
        if applicator ~= nil and applicator.getOriginalFunctionName ~= nil then
            local usedName = applicator.getOriginalFunctionName()
            if usedName == funcName then
                return true
            end
        end
    end

    return false
end

local function saveOrigFunc(v, funcName, targetObject, targetField)
    if v == nil or funcName == nil or funcName == "" then
        return
    end
    local spec = v.spec_AdvancedDamageSystem
    if spec == nil or spec.originalFunctions == nil then
        return
    end
    if spec.originalFunctions[funcName] ~= nil then
        return
    end

    local sourceObject = targetObject or v
    local sourceField = targetField or funcName
    if sourceObject == nil or sourceField == nil then
        return
    end

    spec.originalFunctions[funcName] = sourceObject[sourceField]
end

local function restoreOrigFunc(v, funcName, targetObject, targetField, forceRestore)
    if v == nil or funcName == nil or funcName == "" then
        return false
    end
    local spec = v.spec_AdvancedDamageSystem
    if spec == nil or spec.originalFunctions == nil then
        return false
    end

    if not forceRestore and isOrigFuncStillUsed(v, funcName) then
        return false
    end

    local originalFunc = spec.originalFunctions[funcName]
    if originalFunc == nil then
        return false
    end

    local destinationObject = targetObject or v
    local destinationField = targetField or funcName
    if destinationObject ~= nil and destinationField ~= nil then
        destinationObject[destinationField] = originalFunc
    end

    spec.originalFunctions[funcName] = nil
    return true
end

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

--- SELF_DISAPPEARING_BREAKDOWN_EFFECT
ADS_Breakdowns.EffectApplicators.SELF_DISAPPEARING_BREAKDOWN_EFFECT = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying SELF_DISAPPEARING_BREAKDOWN_EFFECT")
        vehicle:removeBreakdown(effectData.extraData.breakdownId)
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing SELF_DISAPPEARING_BREAKDOWN_EFFECT effect.")
    end
}

--- ENGINE_FAILURE
ADS_Breakdowns.EffectApplicators.ENGINE_FAILURE = {
    getEffectName = function()
        return "ENGINE_FAILURE"
    end,
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying ENGINE_FAILURE effect.")
        local effectName = handler.getEffectName()
        local activeFunc = function(v, dt)
            if v:getIsMotorStarted() then
                v:stopMotor()
            end
        end
        addFuncToActive(vehicle, effectName, activeFunc)
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing ENGINE_FAILURE effect.")
        removeFuncFromActive(vehicle, handler.getEffectName())
    end,
}

--- LIGHTS_FAILURE
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

--- UNLOADING_AUGER_FAILURE
ADS_Breakdowns.EffectApplicators.UNLOADING_AUGER_FAILURE = {
    getOriginalFunctionName = function() return "getIsDischargeNodeActive" end,
    apply = function(vehicle, effectData, handler)

        log_dbg("Applying UNLOADING_AUGER_FAILURE:", effectData.value)
        local originalFuncName = handler.getOriginalFunctionName()
        saveOrigFunc(vehicle, originalFuncName)
 
        vehicle.getIsDischargeNodeActive = function(v, dischargeNode, ...)
            return false
        end
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing UNLOADING_AUGER_FAILURE effect.")
        local originalFuncName = handler.getOriginalFunctionName()
        restoreOrigFunc(vehicle, originalFuncName)
    end
}

-- ==========================================================
--                  EFFECTS WITH MODIFIERS
-- ==========================================================

--------------------- ENGINE_LIMP_EFFECT --------------------
ADS_Breakdowns.EffectApplicators.ENGINE_LIMP_EFFECT = {
    getOriginalFunctionName = function() return "updateVehiclePhysics" end,
    apply = function(vehicle, effectData, handler)

        log_dbg("Applying ENGINE_LIMP_EFFECT:", effectData.value)
        local originalFuncName = handler.getOriginalFunctionName()
        saveOrigFunc(vehicle, originalFuncName)
 
        vehicle.updateVehiclePhysics = function(v, axisForward, axisSide, doHandbrake, dt)
            local originalFunc = v.spec_AdvancedDamageSystem.originalFunctions[originalFuncName]
            return ADS_Breakdowns.updateVehiclePhysics(v, originalFunc, axisForward, axisSide, doHandbrake, dt)
        end
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing ENGINE_LIMP_EFFECT effect.")
        local originalFuncName = handler.getOriginalFunctionName()
        restoreOrigFunc(vehicle, originalFuncName)
    end
}

-------------------- ENGINE_TORQUE_MODIFIER -------------------
ADS_Breakdowns.EffectApplicators.ENGINE_TORQUE_MODIFIER = {
    getOriginalFunctionName = function()
        return "getTorqueCurveValue"
    end,

    apply = function(vehicle, effectData, handler)
        log_dbg("Applying ENGINE_TORQUE_MODIFIER:", effectData.value)
        local motor = vehicle.spec_motorized and vehicle.spec_motorized.motor
        if motor == nil then return end

        local originalFuncName = handler.getOriginalFunctionName()
        saveOrigFunc(vehicle, originalFuncName, motor, originalFuncName)

        motor.getTorqueCurveValue = function(m, rpm)
            local originalFunc = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalFuncName]
            local originalTorque = originalFunc(m, rpm)
            local modifiedTorque = originalTorque * math.max((1 + effectData.value), 0.2)
            return modifiedTorque
        end
        vehicle:updateMotorProperties()
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing ENGINE_TORQUE_MODIFIER effect.")
        local motor = vehicle.spec_motorized and vehicle.spec_motorized.motor
        if motor == nil then return end

        local originalFuncName = handler.getOriginalFunctionName()
        local restored = restoreOrigFunc(vehicle, originalFuncName, motor, originalFuncName)
        if restored then
            log_dbg("Restoring original function:", originalFuncName)
        end
        vehicle:updateMotorProperties()
    end
}

-------------------- BRAKE_FORCE_MODIFIER -------------------
ADS_Breakdowns.EffectApplicators.BRAKE_FORCE_MODIFIER = {
    getOriginalFunctionName = function() return "updateVehiclePhysics" end,
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying BRAKE_FORCE_MODIFIER:", effectData.value)
        if vehicle.spec_drivable == nil then return end

        local originalFuncName = handler.getOriginalFunctionName()
        saveOrigFunc(vehicle, originalFuncName)

        vehicle.updateVehiclePhysics = function(v, axisForward, axisSide, doHandbrake, dt)
            local originalFunc = v.spec_AdvancedDamageSystem.originalFunctions[originalFuncName]
            return ADS_Breakdowns.updateVehiclePhysics(v, originalFunc, axisForward, axisSide, doHandbrake, dt)
        end
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing BRAKE_FORCE_MODIFIER effect.")
        if vehicle.spec_drivable == nil then return end
        local originalFuncName = handler.getOriginalFunctionName()
        restoreOrigFunc(vehicle, originalFuncName)
    end
}

-------------------- STEERING_STATIC_BIAS_EFFECT -------------------
ADS_Breakdowns.EffectApplicators.STEERING_STATIC_BIAS_EFFECT = {
    getOriginalFunctionName = function() return "updateVehiclePhysics" end,
    apply = function(vehicle, effectData, handler)
        if vehicle.spec_drivable == nil then return end
        local originalFuncName = handler.getOriginalFunctionName()
        saveOrigFunc(vehicle, originalFuncName)

        vehicle.updateVehiclePhysics = function(v, axisForward, axisSide, doHandbrake, dt)
            local originalFunc = v.spec_AdvancedDamageSystem.originalFunctions[originalFuncName]
            return ADS_Breakdowns.updateVehiclePhysics(v, originalFunc, axisForward, axisSide, doHandbrake, dt)
        end
    end,
    remove = function(vehicle, handler)
        if vehicle.spec_drivable == nil then return end
        local originalFuncName = handler.getOriginalFunctionName()

        local spec_ads = vehicle.spec_AdvancedDamageSystem
        if spec_ads ~= nil and spec_ads.activeEffects ~= nil and spec_ads.activeEffects.STEERING_SENSITIVITY_MODIFIER ~= nil then
            return
        end

        restoreOrigFunc(vehicle, originalFuncName)
    end
}

-------------------- STEERING_SENSITIVITY_MODIFIER -------------------
ADS_Breakdowns.EffectApplicators.STEERING_SENSITIVITY_MODIFIER = {
    getOriginalFunctionName = function() return "updateVehiclePhysics" end,
    apply = function(vehicle, effectData, handler)
        if vehicle.spec_drivable == nil then return end
        local originalFuncName = handler.getOriginalFunctionName()
        saveOrigFunc(vehicle, originalFuncName)

        vehicle.updateVehiclePhysics = function(v, axisForward, axisSide, doHandbrake, dt)
            local originalFunc = v.spec_AdvancedDamageSystem.originalFunctions[originalFuncName]
            return ADS_Breakdowns.updateVehiclePhysics(v, originalFunc, axisForward, axisSide, doHandbrake, dt)
        end
    end,
    remove = function(vehicle, handler)
        if vehicle.spec_drivable == nil then return end
        local originalFuncName = handler.getOriginalFunctionName()

        -- Do not restore updateVehiclePhysics while static steering bias is still active:
        -- both effects share the same hook.
        local spec_ads = vehicle.spec_AdvancedDamageSystem
        if spec_ads ~= nil and spec_ads.activeEffects ~= nil and spec_ads.activeEffects.STEERING_STATIC_BIAS_EFFECT ~= nil then
            return
        end

        restoreOrigFunc(vehicle, originalFuncName)
    end
}

-------------------- WHEEL_SEIZURE_EFFECT -------------------
ADS_Breakdowns.EffectApplicators.WHEEL_SEIZURE_EFFECT = {
    getOriginalFunctionName = function() return "updateVehiclePhysics" end,
    apply = function(vehicle, effectData, handler)
        if vehicle.spec_drivable == nil or vehicle.spec_wheels == nil then return end

        local originalFuncName = handler.getOriginalFunctionName()
        saveOrigFunc(vehicle, originalFuncName)

        vehicle.updateVehiclePhysics = function(v, axisForward, axisSide, doHandbrake, dt)
            local originalFunc = v.spec_AdvancedDamageSystem.originalFunctions[originalFuncName]
            return ADS_Breakdowns.updateVehiclePhysics(v, originalFunc, axisForward, axisSide, doHandbrake, dt)
        end
    end,
    remove = function(vehicle, handler)
        if vehicle.spec_AdvancedDamageSystem ~= nil then
            vehicle.spec_AdvancedDamageSystem.wheelSeizureTargetIndex = nil
        end
        if vehicle.spec_drivable == nil then return end
        local originalFuncName = handler.getOriginalFunctionName()
        restoreOrigFunc(vehicle, originalFuncName)
    end
}

------------------ FUEL_CONSUMPTION_MODIFIER -----------------
ADS_Breakdowns.EffectApplicators.FUEL_CONSUMPTION_MODIFIER = {
    getOriginalFunctionName = function() return "updateConsumers" end,
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying FUEL_CONSUMPTION_MODIFIER:", effectData.value)
        if vehicle.spec_motorized == nil then return end

        local originalFuncName = handler.getOriginalFunctionName()
        saveOrigFunc(vehicle, originalFuncName)

        vehicle.updateConsumers = function(v, dt, accInput)
            ADS_Breakdowns.updateConsumers(v, dt, accInput)
        end
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing FUEL_CONSUMPTION_MODIFIER effect.")
        if vehicle.spec_motorized == nil then return end
        local originalFuncName = handler.getOriginalFunctionName()
        restoreOrigFunc(vehicle, originalFuncName)
    end
}

------------------ TRANSMISSION_SLIP_EFFECT -----------------
ADS_Breakdowns.EffectApplicators.TRANSMISSION_SLIP_EFFECT = {
    getOriginalFunctionName = function()
        return "getMinMaxGearRatio"
    end,

    apply = function(vehicle, effectData, handler)
        log_dbg("Applying TRANSMISSION_SLIP_EFFECT:", effectData.value)
        local motor = vehicle:getMotor()
        if motor == nil then return end

        local originalFuncName = handler.getOriginalFunctionName()
        local originalValueName = "__TRANSMISSION_SLIP_clutchSlippingTime"

        saveOrigFunc(vehicle, originalFuncName, motor, originalFuncName)
        saveOrigFunc(vehicle, originalValueName, motor, "clutchSlippingTime")

        motor.clutchSlippingTime = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalValueName] * (1 + effectData.value) ^ 3

        motor.getMinMaxGearRatio = function(m)
            
            local originalFunc = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalFuncName]
            local origMinRatio, origMaxRatio = originalFunc(m)
            
            local slipEffect = vehicle.spec_AdvancedDamageSystem and vehicle.spec_AdvancedDamageSystem.activeEffects.TRANSMISSION_SLIP_EFFECT
            local modifier = (slipEffect and slipEffect.value) or 0

            local minRatio = origMinRatio
            local maxRatio = origMaxRatio

            if modifier >= 1 then
                return minRatio * 10, maxRatio * 10
            end

            local speedFactor = math.min(m.vehicle:getLastSpeed() / (m:getMaximumForwardSpeed() * 3.6), 1.0)

            if modifier > 0 and minRatio ~= 0 and speedFactor > 0.5 then
                local motorAccel = m.motorRotAccelerationSmoothed
                local accelerationFactor = math.min(math.max(0, motorAccel / m.motorRotationAccelerationLimit * 5), 1.0)
                
                if slipEffect.extraData.accumulatedMod < accelerationFactor then
                    slipEffect.extraData.accumulatedMod = math.min(slipEffect.extraData.accumulatedMod + 0.01 * (1 - math.min(speedFactor, 0.9)), 1.0)
                else
                    slipEffect.extraData.accumulatedMod = math.max(slipEffect.extraData.accumulatedMod - 0.01 * (1 - math.min(speedFactor, 0.9)), 0.0)
                end
                
                local dynamicModifier = modifier * slipEffect.extraData.accumulatedMod
                minRatio = minRatio * (1 + dynamicModifier)
                maxRatio = maxRatio * (1 + dynamicModifier)
            end
            return minRatio, maxRatio
        end
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing TRANSMISSION_SLIP_EFFECT effect.")
        local motor = vehicle:getMotor()
        if motor == nil then return end

        local originalFuncName = handler.getOriginalFunctionName()
        restoreOrigFunc(vehicle, originalFuncName, motor, originalFuncName)

        local originalValueName = "__TRANSMISSION_SLIP_clutchSlippingTime"
        restoreOrigFunc(vehicle, originalValueName, motor, "clutchSlippingTime", true)
    end
}

------------------ CVT_SLIP_EFFECT -----------------
ADS_Breakdowns.EffectApplicators.CVT_SLIP_EFFECT = {
    getOriginalFunctionName = function()
        return "getMinMaxGearRatio"
    end,

    apply = function(vehicle, effectData, handler)
        log_dbg("Applying CVT_SLIP_EFFECT:", effectData.value)
        local motor = vehicle:getMotor()
        if motor == nil then return end
        if motor.minForwardGearRatio == nil then return end

        local originalFuncName = handler.getOriginalFunctionName()
        saveOrigFunc(vehicle, originalFuncName, motor, originalFuncName)

        motor.getMinMaxGearRatio = function(m)
            local originalFunc = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalFuncName]
            local origMinRatio, origMaxRatio = originalFunc(m)
            local minRatio, maxRatio = origMinRatio, origMaxRatio

            local spec_ads = vehicle.spec_AdvancedDamageSystem
            local slipEffect = spec_ads and spec_ads.activeEffects and spec_ads.activeEffects.CVT_SLIP_EFFECT
            local modifier = (slipEffect and slipEffect.value) or 0

            slipEffect.extraData = slipEffect.extraData or {}
            local nowMs = (g_currentMission and g_currentMission.time) or 0
            local lastUpdateMs = tonumber(slipEffect.extraData.lastUpdateMs) or nowMs
            local dtSec = math.max((nowMs - lastUpdateMs) / 1000, 0)
            if dtSec > 1 then dtSec = 1 end
            slipEffect.extraData.lastUpdateMs = nowMs

            local lastAccelerationFactor = tonumber(slipEffect.extraData.lastAccelerationFactor) or 0
            local speedFactor = math.min(m.vehicle:getLastSpeed() / (m:getMaximumForwardSpeed() * 3.6 / 2), 1.0)
            local loadFactor = vehicle:getMotorLoadPercentage() + 0.2
            local massFactor = vehicle:getTotalMass() / vehicle:getTotalMass(true)

            if modifier > 0 and origMinRatio ~= 0 and origMaxRatio ~= 0 then
                local decatPerSecond = 0.01 / modifier * math.max(speedFactor, 0.1) * 1 / loadFactor * 1 / massFactor
                local motorAccel = m.motorRotAccelerationSmoothed
                local accelLimit = math.max(tonumber(m.motorRotationAccelerationLimit) or 0, 0.000001)
                local accelerationFactor = math.clamp(motorAccel / accelLimit, 0, 1)
                if accelerationFactor < lastAccelerationFactor then
                    accelerationFactor = math.clamp(lastAccelerationFactor - decatPerSecond * dtSec, 0, 1)
                end
                slipEffect.extraData.lastAccelerationFactor = accelerationFactor

                local clampMin = math.min(origMinRatio, origMinRatio * 10)
                local clampMax = math.max(origMinRatio, origMinRatio * 10)
                minRatio = math.clamp(m.gearRatio * accelerationFactor, clampMin, clampMax)
                local lastDebugMs = tonumber(slipEffect.extraData.lastDebugMs) or 0
            end
            return minRatio, maxRatio
        end
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing CVT_SLIP_EFFECT effect.")
        local motor = vehicle:getMotor()
        if motor == nil then return end

        local originalFuncName = handler.getOriginalFunctionName()
        restoreOrigFunc(vehicle, originalFuncName, motor, originalFuncName)

        motor:setExternalTorqueVirtualMultiplicator(1)
    end
}

------------------ CVT_MAX_RATIO_MODIFIER ---------------
ADS_Breakdowns.EffectApplicators.CVT_MAX_RATIO_MODIFIER = {
    getOriginalFunctionName = function()
        return "getMinMaxGearRatio"
    end,

    apply = function(vehicle, effectData, handler)
        log_dbg("Applying CVT_MAX_RATIO_MODIFIER:", effectData.value)
        local motor = vehicle:getMotor()
        if motor == nil then return end
        if motor.minForwardGearRatio == nil then return end

        local originalFuncName = "__CVT_MAX_RATIO_PREV_getMinMaxGearRatio"
        saveOrigFunc(vehicle, originalFuncName, motor, "getMinMaxGearRatio")

        motor.getMinMaxGearRatio = function(m)
            local originalFunc = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalFuncName]
            local origMinRatio, origMaxRatio = originalFunc(m)
            local minRatio, maxRatio = origMinRatio, origMaxRatio
            local effect = vehicle.spec_AdvancedDamageSystem.activeEffects and vehicle.spec_AdvancedDamageSystem.activeEffects.CVT_MAX_RATIO_MODIFIER
            local value = (effect and tonumber(effect.value)) or 0
            minRatio = minRatio + minRatio * value
            return minRatio, maxRatio
        end
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing CVT_MAX_RATIO_MODIFIER effect.")
        local motor = vehicle:getMotor()
        if motor == nil then return end

        local originalFuncName = "__CVT_MAX_RATIO_PREV_getMinMaxGearRatio"
        restoreOrigFunc(vehicle, originalFuncName, motor, "getMinMaxGearRatio", true)

    end
}

----------------- CVT_THERMOSTAT_HEALTH_MODIFIER ----------------
ADS_Breakdowns.EffectApplicators.CVT_THERMOSTAT_HEALTH_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying CVT_THERMOSTAT_HEALTH_MODIFIER:", effectData.value)
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.transmissionThermostatHealth = math.max(1.0 + effectData.value, 0.1)
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing CVT_THERMOSTAT_HEALTH_MODIFIER effect.")
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.transmissionThermostatHealth = 1.0
    end
}

----------------- CVT_THERMOSTAT_STUCK_EFFECT --------------------
ADS_Breakdowns.EffectApplicators.CVT_THERMOSTAT_STUCK_EFFECT = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying CVT_THERMOSTAT_STUCK_EFFECT")
        local spec = vehicle.spec_AdvancedDamageSystem

        if spec.transmissionThermostatStuckedPosition == nil or spec.transmissionThermostatStuckedPosition < 0 then
            spec.transmissionThermostatStuckedPosition = spec.transmissionThermostatState
        end
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing CVT_THERMOSTAT_STUCK_EFFECT")
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.transmissionThermostatStuckedPosition = nil
    end
}

----------------- THERMOSTAT_HEALTH_MODIFIER -----------------
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

----------------- RADIATOR_HEALTH_MODIFIER -----------------
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

----------------- FAN_CLUTCH_MODIFIER -----------------
ADS_Breakdowns.EffectApplicators.FAN_CLUTCH_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying FUN_CLUTCH_MODIFIER:", effectData.value)
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.fanClutchHealth = math.max(1.0 + effectData.value, 0.1)
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing FAN_CLUTCH_MODIFIER effect.")
        local spec = vehicle.spec_AdvancedDamageSystem
        spec.fanClutchHealth = 1.0
    end
}

----------------- THERMOSTAT_STUCK_EFFECT --------------------
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

-------- POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT ----------
ADS_Breakdowns.EffectApplicators.POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT = {
    getEffectName = function()
        return "POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT" 
    end,
    getOriginalFunctionName = function()
        return "applyTargetGear"
    end,

    apply = function(vehicle, effectData, handler)
        log_dbg("Applying POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT:", effectData.value)
        local motor = vehicle:getMotor()
        if motor == nil then return end

        local originalApplyFuncName = handler.getOriginalFunctionName()
        saveOrigFunc(vehicle, originalApplyFuncName, motor, originalApplyFuncName)

        motor.applyTargetGear = function(m)
            local originalFunc = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalApplyFuncName]
            if effectData.extraData.status == "IDLE" then
                    if effectData.value >= 1.0 then
                        m.targetGear = m.previousGear
                        originalFunc(m)
                        return
                    end
                    effectData.extraData.status = "DELAYED"
                    effectData.extraData.timer = 0            
                    return
            else
                originalFunc(m)
            end
        end

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
        local motor = vehicle:getMotor()
        if motor == nil then return end

        local originalApplyFuncName = handler.getOriginalFunctionName()
        local restored = restoreOrigFunc(vehicle, originalApplyFuncName, motor, originalApplyFuncName)
        if restored then
            log_dbg("Restoring original function:", originalApplyFuncName)
        end

        local effectName = handler.getEffectName()
        if vehicle.spec_AdvancedDamageSystem.activeFunctions[effectName] ~= nil then
            vehicle.spec_AdvancedDamageSystem.activeFunctions[effectName] = nil
        end
    end
}

---------------- HYDRAULIC_SPEED_MODIFIER -------------------
local hydraulicSpeedHookDefs = {
    { objectName = "Plow", field = "setRotationMax", wrapperName = "applyHydraulicDamageToPlowRotation" },
    { objectName = "Plow", field = "setRotationCenter", wrapperName = "applyHydraulicDamageToPlowCenterRotation" },
    { objectName = "AttacherJoints", field = "onUpdateTick", wrapperName = "applyHydraulicDamageToAttacher" },
    { objectName = "Cylindered", field = "onUpdate", wrapperName = "applyHydraulicDamageToCylindered" },
    { objectName = "Foldable", field = "setFoldState", wrapperName = "applyHydraulicDamageToFoldable" }
}

local hydraulicSpeedHookState = {
    installed = false,
    users = setmetatable({}, { __mode = "k" }),
    originals = {}
}

local function getHydraulicSpeedHookKey(def)
    return string.format("%s.%s", def.objectName, def.field)
end

local function getHydraulicSpeedHookUsersCount()
    local count = 0
    for _ in pairs(hydraulicSpeedHookState.users) do
        count = count + 1
    end
    return count
end

local function installHydraulicSpeedHooks()
    if hydraulicSpeedHookState.installed then
        return
    end

    for _, def in ipairs(hydraulicSpeedHookDefs) do
        local targetObject = _G[def.objectName]
        local wrapperFunc = ADS_Breakdowns[def.wrapperName]
        local key = getHydraulicSpeedHookKey(def)

        if targetObject ~= nil and targetObject[def.field] ~= nil and wrapperFunc ~= nil then
            hydraulicSpeedHookState.originals[key] = targetObject[def.field]
            targetObject[def.field] = Utils.overwrittenFunction(targetObject[def.field], wrapperFunc)
            log_dbg("HYDRAULIC_SPEED_MODIFIER hook installed:", key)
        else
            log_dbg("HYDRAULIC_SPEED_MODIFIER hook skipped:", key)
        end
    end

    hydraulicSpeedHookState.installed = true
end

local function uninstallHydraulicSpeedHooks()
    if not hydraulicSpeedHookState.installed then
        return
    end

    for _, def in ipairs(hydraulicSpeedHookDefs) do
        local targetObject = _G[def.objectName]
        local key = getHydraulicSpeedHookKey(def)
        local originalFunc = hydraulicSpeedHookState.originals[key]

        if targetObject ~= nil and originalFunc ~= nil then
            targetObject[def.field] = originalFunc
            log_dbg("HYDRAULIC_SPEED_MODIFIER hook restored:", key)
        end

        hydraulicSpeedHookState.originals[key] = nil
    end

    hydraulicSpeedHookState.installed = false
end

local function enableHydraulicSpeedHooksForVehicle(vehicle)
    if vehicle == nil then
        return
    end

    if hydraulicSpeedHookState.users[vehicle] then
        return
    end

    hydraulicSpeedHookState.users[vehicle] = true
    if getHydraulicSpeedHookUsersCount() == 1 then
        installHydraulicSpeedHooks()
    end
end

local function disableHydraulicSpeedHooksForVehicle(vehicle)
    if vehicle == nil then
        return
    end

    if not hydraulicSpeedHookState.users[vehicle] then
        return
    end

    hydraulicSpeedHookState.users[vehicle] = nil
    if getHydraulicSpeedHookUsersCount() == 0 then
        uninstallHydraulicSpeedHooks()
    end
end

ADS_Breakdowns.EffectApplicators.HYDRAULIC_SPEED_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying HYDRAULIC_SPEED_MODIFIER effect")
        enableHydraulicSpeedHooksForVehicle(vehicle)
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing HYDRAULIC_SPEED_MODIFIER effect.")
        disableHydraulicSpeedHooksForVehicle(vehicle)
    end
}

---------------- HYDRAULIC_HOLD_DRIFT_EFFECT -------------------
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
                        if jointDesc ~= nil and not implement:getIsLowered() and not jointDesc.isMoving then
                            local originalMoveDefaultTime = jointDesc.ads_originalMoveDefaultTime or jointDesc.moveDefaultTime
                            jointDesc.moveDefaultTime = originalMoveDefaultTime / effectData.value
                            v:setJointMoveDown(jointDescIndex, true, false)
                        end
                    end
                end
            end
        end
        addFuncToActive(vehicle, handler.getEffectName(), activeFunc)
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing HYDRAULIC_HOLD_DRIFT_EFFECT effect.")
        removeFuncFromActive(vehicle, handler.getEffectName())
    end
}

---------------- MAX_SPEED_MODIFIER -------------------
ADS_Breakdowns.EffectApplicators.MAX_SPEED_MODIFIER = {
    getOriginalFunctionName = function()
        return "getSpeedLimit"
    end,
    getEffectName = function()
        return "MAX_SPEED_MODIFIER"
    end,
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying MAX_SPEED_MODIFIER effect")
        local originalFuncName = handler.getOriginalFunctionName()
        local effectName = handler.getEffectName()
        saveOrigFunc(vehicle, originalFuncName)

        vehicle.getSpeedLimit = function(v, onlyIfWorking)
            local origFunc = v.spec_AdvancedDamageSystem.originalFunctions[originalFuncName]
            if origFunc == nil then
                return math.huge, v:doCheckSpeedLimit()
            end

            local speedLimit, doCheckSpeedLimit = origFunc(v, onlyIfWorking)
            local currentEffect = v.spec_AdvancedDamageSystem.activeEffects and v.spec_AdvancedDamageSystem.activeEffects[effectName]
            local reduction = math.clamp(tonumber((currentEffect and currentEffect.value) or effectData.value) or 0, 0, 0.99)
            local motor = v:getMotor()

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

            if speedLimit ~= nil and speedLimit < math.huge and reduction > 0 then
                speedLimit = speedLimit - speedLimit * reduction
            end

            return speedLimit or math.huge, doCheckSpeedLimit
        end
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing MAX_SPEED_MODIFIER effect.")
        local originalFuncName = handler.getOriginalFunctionName()
        restoreOrigFunc(vehicle, originalFuncName)
    end
}

---------------- YIELD_REDUCTION_MODIFIER -------------------
ADS_Breakdowns.EffectApplicators.YIELD_REDUCTION_MODIFIER = {
    getOriginalFunctionName = function()
        return "addCutterArea"
    end,
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying YIELD_REDUCTION_MODIFIER effect")
        local originalFuncName = handler.getOriginalFunctionName()
        saveOrigFunc(vehicle, originalFuncName)

        vehicle.addCutterArea = function(v, area, realArea, ...)
            local origFunc = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalFuncName]
            
            local spec_combine = v.spec_combine
            local originalScale = spec_combine.threshingScale
            
            local modifiedScale = originalScale * (1 + effectData.value)
            spec_combine.threshingScale = math.max(modifiedScale, 0)
            
            local result = origFunc(v, area, realArea, ...)
            spec_combine.threshingScale = originalScale
            
            return result
        end

    end,

    remove = function(vehicle, handler)
        log_dbg("Removing YIELD_REDUCTION_MODIFIER effect.")
        local originalFuncName = handler.getOriginalFunctionName()
        restoreOrigFunc(vehicle, originalFuncName)
    end
}

---------------- UNLOADING_SPEED_MODIFIER -------------------
ADS_Breakdowns.EffectApplicators.UNLOADING_SPEED_MODIFIER = {
    getOriginalFunctionName = function()
        return "getDischargeNodeEmptyFactor"
    end,
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying UNLOADING_SPEED_MODIFIER effect")
        local originalFuncName = handler.getOriginalFunctionName()
        saveOrigFunc(vehicle, originalFuncName)

        vehicle.getDischargeNodeEmptyFactor = function(v, dischargeNode, ...)
            local origFunc = v.spec_AdvancedDamageSystem.originalFunctions[originalFuncName]
            local originalFactor = origFunc(v, dischargeNode, ...)
            local modifiedFactor = originalFactor * (1 + effectData.value)
            return modifiedFactor
        end

    end,

    remove = function(vehicle, handler)
        log_dbg("Removing UNLOADING_SPEED_MODIFIER effect.")
        local originalFuncName = handler.getOriginalFunctionName()
        restoreOrigFunc(vehicle, originalFuncName)
    end
}


----------------- CONDITION_WEAR_MODIFIER -----------------
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

----------------- SERVICE_WEAR_MODIFIER -----------------
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


----------------- BREAKDOWN_PROBABILITIES_MODIFIER -----------------
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

----------------- ENGINE_HEAT_MODIFIER -----------------
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

----------------- TRANASMISSION_HEAT_MODIFIER -----------------
ADS_Breakdowns.EffectApplicators.ENGINE_HEAT_MODIFIER = {
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


-- ==========================================================
--                VISUAL AND SOUND EFFECTS
-- ==========================================================

----------------- IDLE_HUNTING_EFFECT -----------------
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
        log_dbg("Removing LIGHTS_FLICKER_CHANCE effect")
        removeFuncFromActive(vehicle, handler.getEffectName())
    end
}

----------------- DARK_EXHAUST_EFFECT -----------------
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
--                 EFFECTS WITH PROBABILITY
-- ==========================================================


------------------- CVT_PRESSURE_DROP_CHANCE -----------------
ADS_Breakdowns.EffectApplicators.CVT_PRESSURE_DROP_CHANCE = {
    getOriginalFunctionName = function()
        return "getMinMaxGearRatio"
    end,
    getEffectName = function()
        return "CVT_PRESSURE_DROP_CHANCE"
    end,

    apply = function(vehicle, effectData, handler)
        log_dbg("Applying CVT_PRESSURE_DROP_CHANCE:", effectData.value)
        local motor = vehicle:getMotor()
        if motor == nil then return end
        if motor.minForwardGearRatio == nil then return end
        local effectName = handler.getEffectName()
        local pressureDropFuncKey = "__CVT_PRESSURE_DROP_PREV_getMinMaxGearRatio"

        local activeFunc = function(v, dt)

            if v:getIsMotorStarted() and v:getLastSpeed() > 1 then
                local originalFuncName = handler.getOriginalFunctionName()
                local effect = v.spec_AdvancedDamageSystem.activeEffects.CVT_PRESSURE_DROP_CHANCE
                if effect == nil then
                    return
                end
                effect.extraData = effect.extraData or {}
                effect.extraData.status = tostring(effect.extraData.status or "IDLE")
                effect.extraData.timer = tonumber(effect.extraData.timer) or 0
                effect.extraData.duration = tonumber(effect.extraData.duration) or 200

                -- TO-DO MP: server check
                if effect.extraData.status == 'IDLE' and math.random() < ADS_Utils.getChancePerFrameFromMeanTime(dt, effect.value) then
                    effect.extraData.status = 'DROP'
                    effect.extraData.timer = effect.extraData.duration

                    --TO-DO MP: send event (effect.extraData.status = 'DROP', effect.extraData.timer = effect.extraData.duration)
                
                end
                if effect.extraData.status == 'DROP' and effect.extraData.timer > 0 then
                    if v.spec_AdvancedDamageSystem.originalFunctions[pressureDropFuncKey] == nil then
                        v.spec_AdvancedDamageSystem.originalFunctions[pressureDropFuncKey] = motor.getMinMaxGearRatio
                    end

                    effect.extraData.status = 'PROGRESS'
                    motor.getMinMaxGearRatio = function(m)
                        local originalFunc = vehicle.spec_AdvancedDamageSystem.originalFunctions[pressureDropFuncKey]
                        if originalFunc == nil then
                            return m.minForwardGearRatio or 0, m.maxForwardGearRatio or 0
                        end
                        local origMinRatio, origMaxRatio = originalFunc(m)
                        local minRatio, maxRatio = origMinRatio, origMaxRatio
                        local currentEffect = vehicle.spec_AdvancedDamageSystem.activeEffects and vehicle.spec_AdvancedDamageSystem.activeEffects.CVT_PRESSURE_DROP_CHANCE
                        if currentEffect ~= nil and currentEffect.extraData ~= nil and currentEffect.extraData.status == "PROGRESS" and (currentEffect.extraData.timer or 0) > 0 then
                            return minRatio * 3, maxRatio
                        end
                        return minRatio, maxRatio
                    end
                    
                end
                if effect.extraData.status == 'PROGRESS' then
                    effect.extraData.timer = effect.extraData.timer - dt
                end
                if effect.extraData.timer <= 0 then
                    effect.extraData.timer = 0
                    local originalFunc = v.spec_AdvancedDamageSystem.originalFunctions[pressureDropFuncKey]
                    if originalFunc ~= nil then
                        motor.getMinMaxGearRatio = originalFunc
                        v.spec_AdvancedDamageSystem.originalFunctions[pressureDropFuncKey] = nil
                    else
                        local hasHydraulicValveBreakdown = v.spec_AdvancedDamageSystem.activeBreakdowns and v.spec_AdvancedDamageSystem.activeBreakdowns.CVT_HYDRAULIC_CONTROL_VALVE_MALFUNCTION ~= nil
                        local sharedOriginalFunc = v.spec_AdvancedDamageSystem.originalFunctions[originalFuncName]
                        if sharedOriginalFunc ~= nil and not hasHydraulicValveBreakdown then
                            motor.getMinMaxGearRatio = sharedOriginalFunc
                            v.spec_AdvancedDamageSystem.originalFunctions[originalFuncName] = nil
                        end
                    end
                    effect.extraData.status = 'IDLE'
                end
            end
        end
        addFuncToActive(vehicle, effectName, activeFunc)
    end,

    remove = function(vehicle, handler)
        local motor = vehicle:getMotor()
        if motor ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil then
            local spec = vehicle.spec_AdvancedDamageSystem
            local pressureDropFuncKey = "__CVT_PRESSURE_DROP_PREV_getMinMaxGearRatio"
            local originalFuncName = handler.getOriginalFunctionName()
            local originalFunc = spec.originalFunctions and spec.originalFunctions[pressureDropFuncKey]

            if originalFunc ~= nil then
                motor.getMinMaxGearRatio = originalFunc
                spec.originalFunctions[pressureDropFuncKey] = nil
            else
                local hasHydraulicValveBreakdown = spec.activeBreakdowns and spec.activeBreakdowns.CVT_HYDRAULIC_CONTROL_VALVE_MALFUNCTION ~= nil
                local sharedOriginalFunc = spec.originalFunctions and spec.originalFunctions[originalFuncName]
                if sharedOriginalFunc ~= nil and not hasHydraulicValveBreakdown then
                    motor.getMinMaxGearRatio = sharedOriginalFunc
                    spec.originalFunctions[originalFuncName] = nil
                end
            end
        end
        removeFuncFromActive(vehicle, handler.getEffectName())
    end
}

------------------- ENGINE_STALLS_CHANCE --------------------
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
                            v:stopMotor()

                            ADS_EffectSyncEvent.send(v, "ENGINE_STALLS_CHANCE", "STALLED")

                            if v.getIsControlled ~= nil and v:getIsControlled() then
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

------------------- ENGINE_START_FAILURE_CHANCE ------------------
ADS_Breakdowns.EffectApplicators.ENGINE_START_FAILURE_CHANCE = {
    getEffectName = function() return "ENGINE_START_FAILURE_CHANCE" end,
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying ENGINE_START_FAILURE_CHANCE effect")
        local effectName = handler.getEffectName()
        local function initStartFailureState(effect)
            if effect == nil then
                return
            end

            local extra = effect.extraData or {}
            effect.extraData = extra

            extra.status = tostring(extra.status or "IDLE")
            extra.timer = tonumber(extra.timer) or 0
            extra.duration = tonumber(extra.duration) or 2000
            extra.soundPlaying = extra.soundPlaying == true

            if extra.currentCount == nil then
                extra.currentCount = 0
            end

            extra.currentCount = math.max(math.floor(tonumber(extra.currentCount) or 0), 0)
        end

        local activeFunc = function(v, dt)
            local effect = v.spec_AdvancedDamageSystem.activeEffects.ENGINE_START_FAILURE_CHANCE
            if effect == nil or effect.value <= 0 then
                return
            end

            initStartFailureState(effect)
            local extra = effect.extraData

            local starterSample = (v.spec_AdvancedDamageSystem.samples and v.spec_AdvancedDamageSystem.samples.starter) or nil

            if v:getIsMotorStarted() then
                if starterSample ~= nil and extra.soundPlaying then
                    g_soundManager:stopSample(starterSample, 0, 0)
                    if extra.originalLoops ~= nil then
                        starterSample.loops = extra.originalLoops
                    end
                end
                extra.soundPlaying = false
                extra.status = "IDLE"
                extra.timer = 0
                extra.currentCount = 0
                return
            end

            if extra.status == "CRANKING" then
                if starterSample ~= nil and not extra.soundPlaying then
                    if extra.originalLoops == nil then
                        extra.originalLoops = starterSample.loops
                    end
                    starterSample.loops = 0
                    if not g_soundManager:getIsSamplePlaying(starterSample) then
                        g_soundManager:playSample(starterSample)
                    end
                    extra.soundPlaying = true
                end

                extra.timer = extra.timer + dt
                if extra.timer >= extra.duration then
                    if starterSample ~= nil and extra.soundPlaying then
                        g_soundManager:stopSample(starterSample, 0, 0)
                        if extra.originalLoops ~= nil then
                            starterSample.loops = extra.originalLoops
                        end
                    end

                    extra.status = "IDLE"
                    extra.timer = 0
                    extra.soundPlaying = false
                end
            end
        end
        addFuncToActive(vehicle, effectName, activeFunc)
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing ENGINE_START_FAILURE_CHANCE effect.")
        local effect = vehicle.spec_AdvancedDamageSystem
            and vehicle.spec_AdvancedDamageSystem.activeEffects
            and vehicle.spec_AdvancedDamageSystem.activeEffects.ENGINE_START_FAILURE_CHANCE
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
        end
        removeFuncFromActive(vehicle, handler.getEffectName())
    end
}


------------------- GEAR_SHIFT_FAILURE_CHANCE ------------------
ADS_Breakdowns.EffectApplicators.GEAR_SHIFT_FAILURE_CHANCE = {
    getEffectName = function()
        return "GEAR_SHIFT_FAILURE_CHANCE" 
    end,

    apply = function(vehicle, effectData, handler)
        log_dbg("Applying GEAR_SHIFT_FAILURE_CHANCE:", effectData.value)
        local motor = vehicle:getMotor()
        if motor == nil then return end


        local originalShiftFuncName = "shiftGear"
        saveOrigFunc(vehicle, originalShiftFuncName, motor, originalShiftFuncName)

        -- Server-only: random roll for shift failure, broadcast result to clients.

        motor.shiftGear = function(m, up)
            if effectData.extraData.status == "FAILED" then return end
            if m.vehicle and m.vehicle.isServer and math.random() < effectData.value then
                effectData.extraData.status = "FAILED"
                ADS_EffectSyncEvent.send(vehicle, "GEAR_SHIFT_FAILURE_CHANCE", "FAILED", 0, 0, 0)
                if m.vehicle.spec_AdvancedDamageSystem and effectData.value < 1.0 then
                    g_soundManager:playSample(vehicle.spec_AdvancedDamageSystem.samples['transmissionShiftFailed' .. math.random(3)])
                end
                return
            end
            
            local originalFunc = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalShiftFuncName]
            return originalFunc(m, up)
        end
        
        local originalSelectFuncName = "selectGear"
        saveOrigFunc(vehicle, originalSelectFuncName, motor, originalSelectFuncName)

        motor.selectGear = function(m, gearIndex, activation)
            if effectData.extraData.status == "FAILED" then return end
            if activation then
                if m.vehicle and m.vehicle.isServer and math.random() < effectData.value then
                    effectData.extraData.status = "FAILED"
                    ADS_EffectSyncEvent.send(vehicle, "GEAR_SHIFT_FAILURE_CHANCE", "FAILED", 0, 0, 0)
                    if m.vehicle.spec_AdvancedDamageSystem and effectData.value < 1.0 then
                       g_soundManager:playSample(vehicle.spec_AdvancedDamageSystem.samples['transmissionShiftFailed' .. math.random(3)])
                    end
                    return
                end
            end

            local originalFunc = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalSelectFuncName]
            return originalFunc(m, gearIndex, activation)
        end
        
        local originalUpdateFuncName = "updateGear"
        saveOrigFunc(vehicle, originalUpdateFuncName, motor, originalUpdateFuncName)

        motor.updateGear = function(m, acceleratorPedal, brakePedal, dt)
            local wasShifting = (m.gear == 0 and m.gearChangeTimer > 0)
            local originalFunc = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalUpdateFuncName]
            local adjAcceleratorPedal, adjBrakePedal = originalFunc(m, acceleratorPedal, brakePedal, dt)
            local isShifting = (m.gear == 0 and m.gearChangeTimer > 0)
            
            if isShifting and not wasShifting then
                if m.vehicle and m.vehicle.isServer and math.random() < effectData.value then
                
                    effectData.extraData.status = "FAILED"
                    effectData.extraData.timer = 0            

                    m.gearChangeTimer = effectData.extraData.duration
                    m.autoGearChangeTimer = effectData.extraData.duration
                    
                    ADS_EffectSyncEvent.send(vehicle, "GEAR_SHIFT_FAILURE_CHANCE", "FAILED", 0, 0, effectData.extraData.duration)

                    if m.vehicle.spec_AdvancedDamageSystem and effectData.value < 1.0 then
                        g_soundManager:playSample(vehicle.spec_AdvancedDamageSystem.samples['transmissionShiftFailed' .. math.random(3)])
                    end
                end
                if effectData.value >= 1.0 then
                    m.targetGear = m.previousGear
                end
            end

            return adjAcceleratorPedal, adjBrakePedal
        end

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
        local motor = vehicle:getMotor()
        if motor == nil then return end

        local originalShiftFuncName = "shiftGear"
        local restoredShift = restoreOrigFunc(vehicle, originalShiftFuncName, motor, originalShiftFuncName, true)
        if restoredShift then
            log_dbg("Restoring original function:", originalShiftFuncName)
        end
        
        local originalSelectFuncName = "selectGear"
        local restoredSelect = restoreOrigFunc(vehicle, originalSelectFuncName, motor, originalSelectFuncName, true)
        if restoredSelect then
            log_dbg("Restoring original function:", originalSelectFuncName)
        end

        local originalUpdateFuncName = "updateGear"
        local restoredUpdate = restoreOrigFunc(vehicle, originalUpdateFuncName, motor, originalUpdateFuncName, true)
        if restoredUpdate then
            log_dbg("Restoring original function:", originalUpdateFuncName)
        end

        local effectName = handler.getEffectName()
        if vehicle.spec_AdvancedDamageSystem.activeFunctions[effectName] ~= nil then
            vehicle.spec_AdvancedDamageSystem.activeFunctions[effectName] = nil
        end
    end
}


------------------- GEAR_REJECTION_CHANCE ------------------
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
                                
                                if v.getIsControlled ~= nil and v:getIsControlled() then
                                    g_soundManager:playSample(v.spec_AdvancedDamageSystem.samples.gearDisengage1)
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


------------------- LIGHTS_FLICKER_CHANCE ------------------

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


------------------- ENGINE_HESITATION_CHANCE ------------------

ADS_Breakdowns.EffectApplicators.ENGINE_HESITATION_CHANCE = {
    getEffectName = function() return "ENGINE_HESITATION_CHANCE" end,
    getOriginalFunctionName = function() return "updateVehiclePhysics" end,

    apply = function(vehicle, effectData, handler)
        log_dbg("Applying ENGINE_HESITATION_CHANCE effect")

        local originalFuncName = handler.getOriginalFunctionName()
        saveOrigFunc(vehicle, originalFuncName)

        vehicle.updateVehiclePhysics = function(v, axisForward, axisSide, doHandbrake, dt)
            local originalFunc = v.spec_AdvancedDamageSystem.originalFunctions[originalFuncName]
            return ADS_Breakdowns.updateVehiclePhysics(v, originalFunc, axisForward, axisSide, doHandbrake, dt)
        end

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
        restoreOrigFunc(vehicle, handler.getOriginalFunctionName())
    end
}


-- ==========================================================
--                   OVERWRITTEN FUNCTIONS
-- ==========================================================

function ADS_Breakdowns.updateDamageAmount(wearable, superFunc, dt)
	if wearable.spec_AdvancedDamageSystem ~= nil then
		return 0
	else
		return superFunc(wearable, dt)
	end
end


function ADS_Breakdowns.getCanMotorRun(self, superFunc)
    local spec = self.spec_AdvancedDamageSystem
    if (spec and spec.activeEffects.ENGINE_FAILURE) then
        if spec.activeEffects.ENGINE_FAILURE.extraData.starter  then
            return true
        else
            return false
        end
    elseif self:isUnderService() then
        if self.getIsControlled ~= nil and self:getIsControlled() then
            g_currentMission:showBlinkingWarning(g_i18n:getText(self:getCurrentStatus()) .. " " .. g_i18n:getText("ads_breakdown_at_progress_message", 100)) 
        end
        return false
    end
    return superFunc(self)
end


local function setMotorStartedFlagForStarterDamage(vehicle)
    local spec = vehicle.spec_AdvancedDamageSystem
    local systemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, spec.systems.electrical.name)
    local systemData = spec.systems[systemKey]
    systemData.isMotorStarted = true
end

function ADS_Breakdowns.startMotor(self, superFunc, noEventSend)

    if self.spec_AdvancedDamageSystem and self.spec_AdvancedDamageSystem.activeEffects then
        local spec = self.spec_AdvancedDamageSystem

        if self.spec_AdvancedDamageSystem.activeEffects.ENGINE_FAILURE then
            local engineFailureEffect = spec.activeEffects.ENGINE_FAILURE
            if (engineFailureEffect and engineFailureEffect.value >= 1.0) then
                local starterSample = (spec.samples and spec.samples.starter) or nil
                if starterSample ~= nil and not g_soundManager:getIsSamplePlaying(starterSample) then
                    g_soundManager:playSample(starterSample)
                end 
                setMotorStartedFlagForStarterDamage(self)
                return
            end
        end

        if self.spec_AdvancedDamageSystem.activeEffects.ENGINE_START_FAILURE_CHANCE then
            local startFailureEffect = spec.activeEffects.ENGINE_START_FAILURE_CHANCE
            if startFailureEffect ~= nil and startFailureEffect.extraData == nil then
                startFailureEffect.extraData = {}
            end
            local extra = startFailureEffect and startFailureEffect.extraData or nil
            if startFailureEffect and extra ~= nil then
                if extra.currentCount == nil then
                    extra.currentCount = 0
                end
                extra.currentCount = math.max(math.floor(tonumber(extra.currentCount) or 0), 0)
                extra.status = tostring(extra.status or "IDLE")
            end

            local START_FAIL_RETRY_MULTIPLIER = 0.66
            local START_FAIL_TEMP_REFERENCE = 25
            local START_FAIL_TEMP_PER_DEGREE = 0.01

            if startFailureEffect and extra ~= nil and extra.status ~= "IDLE" then
                log_dbg(string.format("[ADS][START_FAIL] blocked: status=%s timer=%.0f", tostring(extra.status), tonumber(extra.timer) or 0))
                return
            end

            if startFailureEffect and startFailureEffect.value > 0 then
                local failedAttempts = (extra and extra.currentCount) or 0
                local baseFailChance = math.max(tonumber(startFailureEffect.value) or 0, 0)
                local attemptMultiplier = math.pow(START_FAIL_RETRY_MULTIPLIER, failedAttempts)
                local temperature = tonumber(spec.engineTemperature) or 0
                local coldDegrees = math.max(START_FAIL_TEMP_REFERENCE - temperature, 0)
                local tempPenalty = coldDegrees * START_FAIL_TEMP_PER_DEGREE
                local failChance = math.clamp(baseFailChance * attemptMultiplier + tempPenalty, 0, 1)
                local roll = math.random()
                local isFailedStart = roll < failChance

                if self.isServer and isFailedStart then

                    extra.status = "CRANKING"
                    extra.timer = 0
                    extra.currentCount = failedAttempts + 1
                    setMotorStartedFlagForStarterDamage(self)

                    ADS_EffectSyncEvent.send(self, "ENGINE_START_FAILURE_CHANCE", "CRANKING", 0, failedAttempts + 1)
                    return
                end

                extra.currentCount = 0
                superFunc(self, noEventSend)
                setMotorStartedFlagForStarterDamage(self)
                return
            else
                superFunc(self, noEventSend)
                setMotorStartedFlagForStarterDamage(self)
                return
            end
        end
    end
    superFunc(self, noEventSend)
    setMotorStartedFlagForStarterDamage(self)
end


-- FUEL CONSUMTION
function ADS_Breakdowns.updateConsumers(vehicle, dt, accInput)
	local spec = vehicle.spec_motorized
	local idleFactor = 0.5
	local rpmPercentage = (spec.motor.lastMotorRpm - spec.motor.minRpm) / (spec.motor.maxRpm - spec.motor.minRpm)
	local rpmFactor = idleFactor + rpmPercentage * (1 - idleFactor)
	local loadFactor = math.max(spec.smoothedLoadPercentage * rpmPercentage, 0)
	local motorFactor = 0.5 * (0.2 * rpmFactor + 1.8 * loadFactor)

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
			local used = usageFactor * motorFactor * consumer.usage * dt

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

				if consumer.fillType == FillType.DIESEL or consumer.fillType == FillType.ELECTRICCHARGE or consumer.fillType == FillType.METHANE then
					spec.lastFuelUsage = used / dt * 1000 * 60 * 60
				elseif consumer.fillType == FillType.DEF then
					spec.lastDefUsage = used / dt * 1000 * 60 * 60
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


-- VEHICLE PHYSICS (BRAKES)
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

    -- Static steering bias: always drifts left, value controls offset angle/intensity.
    if steeringStaticBiasEffect ~= nil and steeringStaticBiasEffect.value ~= nil then
        local value = math.abs(tonumber(steeringStaticBiasEffect.value) or 0)
        local leftBias = -math.clamp(value, 0, 1.0)
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


-- CYLINDRED, FOLDABLE, ATTACHERJOINT, PLOW (HYDRAULIC)
function ADS_Breakdowns.applyHydraulicDamageToAttacher(self, superFunc, dt, ...)
    local rootVehicle = self:getRootVehicle()
    local spec = self.spec_attacherJoints

    local hydraulicEffect = rootVehicle.spec_AdvancedDamageSystem and rootVehicle.spec_AdvancedDamageSystem.activeEffects.HYDRAULIC_SPEED_MODIFIER
    local hydraulicModifier = (hydraulicEffect and hydraulicEffect.value) or 0
    if hydraulicModifier == 0 then
        return superFunc(self, dt, ...)
    end

    local performance = math.max(0.05, 1.0 + hydraulicModifier)

    for _, implement in ipairs(spec.attachedImplements) do
        if implement.object ~= nil then
            local jointDesc = spec.attacherJoints[implement.jointDescIndex]
            
            if jointDesc.ads_originalMoveDefaultTime == nil then
                jointDesc.ads_originalMoveDefaultTime = jointDesc.moveDefaultTime
            end

            if jointDesc.moveDown == true and jointDesc.isMoving == true then
                jointDesc.moveDefaultTime = jointDesc.ads_originalMoveDefaultTime
            else
                jointDesc.moveDefaultTime = jointDesc.ads_originalMoveDefaultTime / performance
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


