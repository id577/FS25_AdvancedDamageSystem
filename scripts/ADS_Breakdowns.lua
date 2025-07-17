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

ADS_Breakdowns.BreakdownRegistry = {

--------------------- NOT SELECTEBLE BREAKDOWNS (does not happen by chance, but is the result of various conditions) ---------------------


-- additional debuffs for aging equipment, in addition to the standard ones (torque for motorized, fillDelta for combine)
    GENERAL_WEAR_AND_TEAR = {
        isSelectable = false,
        part = "ads_breakdowns_part_vehicle",
        isApplicable = function(vehicle)
            return true
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_permanent",
                description = "ads_breakdowns_general_wear_and_tear_stage1_description",
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
                    },
                    { 
                        id = "BRAKE_FORCE_MODIFIER", 
                        value = function(vehicle)
                            local baseEffect = -0.40
                            local condition = vehicle:getConditionLevel()
                            local multiplier = (1 - condition) ^ 3
                            return baseEffect * multiplier
                        end,
                        aggregation = "min"
                    },
                    { 
                        id = "ENGINE_START_FAILURE_CHANCE", 
                        value = function(vehicle)
                            local baseEffect = 0.80
                            local condition = vehicle:getConditionLevel()
                            local multiplier = (1 - condition) ^ 3
                            return baseEffect * multiplier
                        end,
                        aggregation = "max",
                        extraData = {timer = 0, status = 'IDLE'}
                    },
                    { 
                        id = "YIELD_REDUCTION_MODIFIER", 
                        value = function(vehicle)
                            local baseEffect = -0.20
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

    OVERHEAT_PROTECTION = {
        isSelectable = false,
        part = "ads_breakdowns_part_engine",
        isApplicable = function(vehicle)
            return true
        end,

        stages = {
            {
                severity = "ads_breakdowns_severity_reduce_power",
                description = "ads_breakdowns_overheat_protection_stage1_description",
                detectionChance = 0.0,
                progressMultiplier = 0.0,
                repairPrice = 0.0,
                effects = {
                    { id = "ENGINE_LIMP_EFFECT", value = -0.2, aggregation = "min", extraData = {reason = "OVERHEAT", message = "ads_breakdowns_overheat_protection_stage1_message"} },
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
                    { id = "ENGINE_LIMP_EFFECT", value = -0.5, aggregation = "min", extraData = {reason = "OVERHEAT", message = "ads_breakdowns_overheat_protection_stage2_message"}  },
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
                    { id = "ENGINE_LIMP_EFFECT", value = -0.8, aggregation = "min", extraData = {reason = "OVERHEAT", message = "ads_breakdowns_overheat_protection_stage3_message"} },
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
                     { id = "ENGINE_FAILURE", value = 1.0, aggregation = "boolean_or", extraData = {starter = false, message = "ads_breakdowns_overheat_protection_stage4_message", reason = "OVERHEAT"} },
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
        part = "ads_breakdowns_part_engine",
        isApplicable = function(vehicle)
            return true
        end,

        stages = {
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_engine_jam_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 0.0,
                repairPrice = 20.0,
                effects = {
                    { id = "ENGINE_FAILURE", value = 1.0, aggregation = "boolean_or", extraData = {starter = false, message = "ads_breakdowns_engine_jam_stage1_message", reason = "OVERHEAT"} },
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

    ECU_MALFUNCTION = {
        isSelectable = true,
        part = "ads_breakdowns_part_engine",
        isApplicable = function(vehicle)
            local spec = vehicle.spec_AdvancedDamageSystem
            if spec.year >= 2000 and not getIsElectricVehicle(vehicle) then
                return true
            end
            return false
        end,

        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_ecu_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.5,
                repairPrice = 0.5,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.10, aggregation = "sum"},
                },
                indicators = {
                    {  
                        id = db.ENGINE,
                        color = color.WARNING,
                        switchOn = function(vehicle)
                            if vehicle.spec_motorized and vehicle:getIsMotorStarted() and vehicle:getMotorLoadPercentage() > 0.99 then
                                return true
                            end
                            return false
                        end,
                        switchOff = false
                    }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_ecu_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0,
                repairPrice = 1.0,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.20, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.2, aggregation = "sum" },
                },
                indicators = {
                    { id = db.ENGINE, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_ecu_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0,
                repairPrice = 2.0, 
                effects = { 
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.35, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.5, aggregation = "sum" },
                    { id = "ENGINE_STALLS_CHANCE", value = 10.0, aggregation = "min",  extraData = {message = "ads_breakdowns_engine_stalled_message"} },
                    { id = "ENGINE_START_FAILURE_CHANCE", value = 0.4, aggregation = "max", extraData = { timer = 0, status = 'IDLE'}}
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
                repairPrice = 4.0, 
                effects = { 
                    { id = "ENGINE_FAILURE", value = 1.0, aggregation = "boolean_or",  extraData = {starter = true, message = "ads_breakdowns_ecu_malfunction_stage4_message", reason = "BREAKDOWN"}} 
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    TURBOCHARGER_WEAR = { -- x4.0
        isSelectable = false,
        part = "ads_breakdowns_part_turbocharger",
        isApplicable = function(vehicle)
            local motor = vehicle:getMotor()
            local power = motor.peakMotorPower * 1.36
            local spec = vehicle.spec_AdvancedDamageSystem
            local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
            if power >= 150 
            and (storeItem.categoryName == "TRACTORSL" or storeItem.categoryName == "TRACTORSM") 
            and spec.year >= 2005 then
                return true
            else
                return false
            end
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_turbocharger_wear_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 3.0,
                repairPrice = 0.8,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.10, aggregation = "sum" }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_turbocharger_wear_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0,
                repairPrice = 1.6,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.25, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.20, aggregation = "sum" }
                },
                indicators = {
                    { id = db.ENGINE, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_turbocharger_wear_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0,
                repairPrice = 3.2,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.45, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.40, aggregation = "sum" },
                    { id = "ENGINE_STALLS_CHANCE", value = 10.0, aggregation = "min", extraData = {message = "ads_breakdowns_engine_stalled_message"}}
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
                repairPrice = 6.4,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.50, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.40, aggregation = "sum" },
                    { id = "ENGINE_LIMP_EFFECT", value = -0.5, aggregation = "min", extraData = {reason = "TURBO_FAIL"}}
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false },
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    FUEL_PUMP_MALFUNCTION = { -- x2.0
        isSelectable = true,
        part = "ads_breakdowns_part_fuel_pump",
        isApplicable = function(vehicle)
            return not getIsElectricVehicle(vehicle)
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_fuel_pump_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 3.0,
                repairPrice = 0.4,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.05, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.15, aggregation = "sum" },
                    { id = "ENGINE_START_FAILURE_CHANCE", value = 0.33, aggregation = "max", extraData = { timer = 0, status = 'IDLE'}},
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.3, aggregation = "max", extraData = {timer = 0, duration = 300, status = 'IDLE', amplitude = 0.6, motorLoad = 0.8} }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_fuel_pump_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0,
                repairPrice = 0.8,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.12, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.4, aggregation = "sum" },
                    { id = "ENGINE_STALLS_CHANCE", value = 20.0, aggregation = "min", extraData = {message = "ads_breakdowns_engine_stalled_message"}},
                    { id = "ENGINE_START_FAILURE_CHANCE", value = 0.5, aggregation = "max", extraData = { timer = 0, status = 'IDLE'}},
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.2, aggregation = "max", extraData = {timer = 0, duration = 400, status = 'IDLE', amplitude = 1.0, motorLoad = 0.8} }
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
                progressMultiplier = 1.2,
                repairPrice = 1.6, 
                effects = { 
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.25, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 1.0, aggregation = "sum" },
                    { id = "ENGINE_STALLS_CHANCE", value = 10.0, aggregation = "min", extraData = {message = "ads_breakdowns_engine_stalled_message"}},
                    { id = "ENGINE_START_FAILURE_CHANCE", value = 0.66, aggregation = "max", extraData = { timer = 0, status = 'IDLE'}},
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.2, aggregation = "max", extraData = {timer = 0, duration = 300, status = 'IDLE', amplitude = 1.0, motorLoad = 0.6} }
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
                repairPrice = 3.2, 
                effects = { 
                    { id = "ENGINE_FAILURE", value = 1.0, aggregation = "boolean_or", extraData = {starter = true, message = "ads_breakdowns_fuel_pump_malfunction_stage4_message", reason = "BREAKDOWN"} } 
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    FUEL_INJECTOR_MALFUNCTION = { -- x3.0
        isSelectable = true,
        part = "ads_breakdowns_part_fuel_injectors",
        isApplicable = function(vehicle)
            return not getIsElectricVehicle(vehicle)
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_fuel_injector_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 3.5,
                repairPrice = 0.6,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.08, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.10, aggregation = "sum" },
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.4, aggregation = "max", extraData = {timer = 0, duration = 300, status = 'IDLE', amplitude = 0.6, motorLoad = 0.8} }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_fuel_injector_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 2.5,
                repairPrice = 1.2,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.20, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.25, aggregation = "sum" },
                    { id = "ENGINE_STALLS_CHANCE", value = 30.0, aggregation = "min", extraData = {message = "ads_breakdowns_engine_stalled_message"}},
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.3, aggregation = "max", extraData = {timer = 0, duration = 300, status = 'IDLE', amplitude = 0.8, motorLoad = 0.8} }
                },
                indicators = {
                    { id = db.ENGINE, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_fuel_injector_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 1.2,
                repairPrice = 2.4,
                effects = {
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.35, aggregation = "sum" },
                    { id = "FUEL_CONSUMPTION_MODIFIER", value = 0.50, aggregation = "sum" },
                    { id = "ENGINE_START_FAILURE_CHANCE", value = 0.66, aggregation = "max", extraData = { timer = 0, status = 'IDLE'}},
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.2, aggregation = "max", extraData = {timer = 0, duration = 400, status = 'IDLE', amplitude = 1.0, motorLoad = 0.8} }
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
                repairPrice = 4.8,
                effects = {
                    { id = "ENGINE_FAILURE", value = 1.0, aggregation = "boolean_or", extraData = {starter = true, message = "ads_breakdowns_fuel_injector_malfunction_stage4_message", reason = "BREAKDOWN"} }
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    BRAKE_MALFUNCTION = { -- x1.5
        isSelectable = true,
        part = "ads_breakdowns_part_brake_system",
        isApplicable = function(vehicle)
            if vehicle.spec_crawlers ~= nil then
                return #vehicle.spec_crawlers.crawlers == 0
            else
                return true
            end
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_brake_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 3.5,
                repairPrice = 0.3,
                effects = {
                    { id = "BRAKE_FORCE_MODIFIER", value = -0.20, aggregation = "min" }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_brake_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0,
                repairPrice = 0.6,
                effects = {
                    { id = "BRAKE_FORCE_MODIFIER", value = -0.45, aggregation = "min" }
                },
                indicators = {
                    { id = db.BRAKES, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_brake_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0,
                repairPrice = 1.2, 
                effects = { 
                    { id = "BRAKE_FORCE_MODIFIER", value = -0.70, aggregation = "min" }
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
                repairPrice = 2.4, 
                effects = { 
                    { id = "BRAKE_FORCE_MODIFIER", value = -1.0, aggregation = "min", extraData = {message = "ads_breakdowns_brake_malfunction_stage4_message"} }
                },
                indicators = {
                    { id = db.BRAKES, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    TRANSMISSION_SLIP = { -- x7.0
        isSelectable = true,
        part = "ads_breakdowns_part_transmission",
        isApplicable = function(vehicle)
            local motor = vehicle:getMotor()
            if not motor then return false end
            return motor.minForwardGearRatio == nil
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_transmission_slip_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 4.0,
                repairPrice = 1.4,
                effects = {
                    { id = "TRANSMISSION_SLIP_EFFECT", value = 0.20, extraData = {accumulatedMod = 0.0}, aggregation = "max" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_transmission_slip_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 2.5,
                repairPrice = 2.8,
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
                progressMultiplier = 1.0,
                repairPrice = 5.6, 
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
                repairPrice = 11.2, 
                effects = { 
                     { id = "TRANSMISSION_SLIP_EFFECT", value = 1.0, extraData = {accumulatedMod = 0.0}, aggregation = "max" }
                },
                indicators = {
                    { id = db.TRANSMISSION, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    TRANSMISSION_SYNCHRONIZER_MALFUNCTION = { -- x6.0
        isSelectable = true,
        part = "ads_breakdowns_part_transmission",
        isApplicable = function(vehicle)
            local motor = vehicle:getMotor()
            if not motor then return false end
            return motor.minForwardGearRatio == nil and motor.gearType ~= VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_transmission_synchronizer_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 4.0,
                repairPrice = 1.2,
                effects = {
                    { id = "GEAR_SHIFT_FAILURE_CHANCE", value = 0.10, extraData = {timer = 0, status = 'IDLE', duration = 1500}, aggregation = "max"},
                    { id = "GEAR_REJECTION_CHANCE", value = 10.0, extraData = {timer = 0, status = 'IDLE', duration = 2000, message = 'ads_breakdowns_gear_disengage_message'}, aggregation = "min"}
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_transmission_synchronizer_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 2.5,
                repairPrice = 2.4,
                effects = {
                     { id = "GEAR_SHIFT_FAILURE_CHANCE", value = 0.20, extraData = {timer = 0, status = 'IDLE', duration = 1800}, aggregation = "max"},
                     { id = "GEAR_REJECTION_CHANCE", value = 5.0, extraData = {timer = 0, status = 'IDLE', duration = 2000, message = 'ads_breakdowns_gear_disengage_message'}, aggregation = "min"}
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_transmission_synchronizer_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 1.2,
                repairPrice = 4.8, 
                effects = { 
                     { id = "GEAR_SHIFT_FAILURE_CHANCE", value = 0.50, extraData = {timer = 0, status = 'IDLE', duration = 2200}, aggregation = "max"},
                     { id = "GEAR_REJECTION_CHANCE", value = 1.0, extraData = {timer = 0, status = 'IDLE', duration = 2000, message = 'ads_breakdowns_gear_disengage_message'}, aggregation = "min"}
                }
            },
            { 
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_transmission_synchronizer_malfunction_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 9.6, 
                effects = { 
                     { id = "GEAR_SHIFT_FAILURE_CHANCE", value = 1.00, extraData = {timer = 0, status = 'IDLE', duration = 2200, message = "ads_breakdowns_transmission_synchronizer_malfunction_stage4_message"}, aggregation = "max"}
                }
            }
        }
    },

    POWERSHIFT_HYDRAULIC_PUMP_MALFUNCTION = { -- x10.0
        isSelectable = true,
        part = "ads_breakdowns_part_transmission",
        isApplicable = function(vehicle)
            local motor = vehicle:getMotor()
            if not motor then return false end
            return motor.gearType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_powershift_hydraulic_pump_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 3.5,
                repairPrice = 2.0,
                effects = {
                    { id = "POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT", value = 0.2, extraData = {timer = 0, status = "IDLE", duration = 500, backup = 0}, aggregation = "max"}
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_powershift_hydraulic_pump_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 2.5,
                repairPrice = 4.0,
                effects = {
                     { id = "POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT", value = 0.5, extraData = {timer = 0, status = "IDLE", duration = 700, backup = 0}, aggregation = "max"}
                },
                indicators = {
                    { id = db.TRANSMISSION, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_powershift_hydraulic_pump_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 1.5,
                repairPrice = 8.0, 
                effects = { 
                     { id = "POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT", value = 0.99, extraData = {timer = 0, status = "IDLE", duration = 1000, backup = 0}, aggregation = "max"}
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
                repairPrice = 16.0, 
                effects = { 
                     { id = "POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT", value = 1.0, extraData = {timer = 0, status = "IDLE", duration = 0}, aggregation = "max"}
                },
                indicators = {
                    { id = db.TRANSMISSION, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    CVT_THERMOSTAT_MALFUNCTION = { -- x2.2
        isSelectable = true,
        part = "ads_breakdowns_part_cvt_cooling_system",
        isApplicable = function(vehicle)
            local motor = vehicle:getMotor()
            local spec = vehicle.spec_AdvancedDamageSystem
            if not motor or getIsElectricVehicle(vehicle) then return false end
            return motor.minForwardGearRatio ~= nil and spec.year >= 2000
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_cvt_thermostat_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 3.0,
                repairPrice = 0.44,
                effects = {
                    { id = "CVT_THERMOSTAT_HEALTH_MODIFIER", value = -0.1, aggregation = "min"}
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_cvt_thermostat_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 2.5,
                repairPrice = 0.88,
                effects = {
                    { id = "CVT_THERMOSTAT_HEALTH_MODIFIER", value = -0.2, aggregation = "min"}
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_cvt_thermostat_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 1.5,
                repairPrice = 1.76,
                effects = {
                    { id = "CVT_THERMOSTAT_HEALTH_MODIFIER", value = -0.4, aggregation = "min"}
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
                repairPrice = 3.52,
                effects = {
                    { id = "CVT_THERMOSTAT_HEALTH_MODIFIER", value = -0.6, aggregation = "min"}
                },
                indicators = {
                    { id = db.TRANSMISSION, color = color.CRITICAL, switchOn = true, switchOff = false },
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    THERMOSTAT_MALFUNCTION = { -- x2.2
        isSelectable = true,
        part = "ads_breakdowns_part_cooling_system",
        isApplicable = function(vehicle)
            return not getIsElectricVehicle(vehicle)
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_thermostat_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 3.0,
                repairPrice = 0.44,
                effects = {
                    { id = "THERMOSTAT_HEALTH_MODIFIER", value = -0.1, aggregation = "min"}
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_thermostat_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 2.5,
                repairPrice = 0.88,
                effects = {
                    { id = "THERMOSTAT_HEALTH_MODIFIER", value = -0.2, aggregation = "min"}
                },
                indicators = {
                    { id = db.WARNING, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_thermostat_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 1.5,
                repairPrice = 1.76,
                effects = {
                    { id = "THERMOSTAT_HEALTH_MODIFIER", value = -0.4, aggregation = "min"}
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            },
            {
                severity = "ads_breakdowns_severity_critical",
                description = "ads_breakdowns_thermostat_malfunction_stage4_description",
                detectionChance = 1.0,
                progressMultiplier = 0,
                repairPrice = 3.52,
                effects = {
                    { id = "THERMOSTAT_HEALTH_MODIFIER", value = -0.6, aggregation = "min"}
                },
                indicators = {
                    { id = db.ENGINE, color = color.WARNING, switchOn = true, switchOff = false },
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    HYDRAULIC_PUMP_MALFUNCTION = { -- x3.5
        isSelectable = true,
        part = "ads_breakdowns_part_hydraulic_lift_system",
        isApplicable = function(vehicle)
            local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
            if storeItem.categoryName == "TRUCKS" then return false end
            local vtype = vehicle.type.name
            local spec = vehicle.spec_AdvancedDamageSystem
            return vtype ~= "car" and vtype ~= "carFillable" and vtype ~= "motorbike" and spec.year >= 1960
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_hydraulic_pump_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 2.5,
                repairPrice = 0.7,
                effects = {
                    { id = "HYDRAULIC_SPEED_MODIFIER", value = -0.20, aggregation = "min" }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_hydraulic_pump_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 1.8,
                repairPrice = 1.4,
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
                progressMultiplier = 1.0,
                repairPrice = 2.8, 
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
                repairPrice = 5.6, 
                effects = { 
                    { id = "HYDRAULIC_SPEED_MODIFIER", value = -1.0, extraData = {message = 'Hydraulic failure'}, aggregation = "min" }
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    ELECTRICAL_SYSTEM_MALFUNCTION = { -- x1.8
        isSelectable = true,
        part = "ads_breakdowns_part_electrical_system",
        isApplicable = function(vehicle)
            local spec = vehicle.spec_AdvancedDamageSystem
            return spec.year >= 2000 and vehicle.spec_lights ~= nil
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_electrical_system_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 3.0,
                repairPrice = 0.36,
                effects = {
                    { id = "LIGHTS_FLICKER_CHANCE", value = 1.0, extraData = {timer = 0, status = 'IDLE', duration = 200, maskBackup = 0}, aggregation = "min"},
                    { id = "ENGINE_START_FAILURE_CHANCE", value = 0.1, extraData = { timer = 0, status = 'IDLE'}, aggregation = "max"}

                }
            },
            {
                severity = "ads_breakdowns_severity_moderate", 
                description = "ads_breakdowns_electrical_system_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0,
                repairPrice = 0.72,
                effects = {
                    { id = "LIGHTS_FLICKER_CHANCE", value = 0.33, extraData = {timer = 0, status = 'IDLE', duration = 300, maskBackup = 0}, aggregation = "min" },
                    { id = "ENGINE_STALLS_CHANCE", value = 20.0, extraData = {message = "ads_breakdowns_engine_stalled_message"}, aggregation = "min"},
                    { id = "ENGINE_START_FAILURE_CHANCE", value = 0.33, extraData = { timer = 0, status = 'IDLE'}, aggregation = "max"},
                    { id = "CVT_THERMOSTAT_HEALTH_MODIFIER", value = -0.2, aggregation = "min"}
                },
                indicators = {
                    { id = db.BATTERY, color = color.WARNING, switchOn = true, switchOff = false }
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_electrical_system_malfunction_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0,
                repairPrice = 1.44, 
                effects = { 
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.10, aggregation = "sum"},
                    { id = "LIGHTS_FAILURE", value = 1.0, extraData = {message = "ads_breakdowns_electrical_system_malfunction_stage3_message"}, aggregation = "boolean_or" },
                    { id = "ENGINE_STALLS_CHANCE", value = 10.0, extraData = {message = "ads_breakdowns_engine_stalled_message"}, aggregation = "min"},
                    { id = "ENGINE_START_FAILURE_CHANCE", value = 0.66, extraData = { timer = 0, status = 'IDLE'}, aggregation = "max"},
                    { id = "CVT_THERMOSTAT_HEALTH_MODIFIER", value = -0.3, aggregation = "min"}
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
                repairPrice = 2.88, 
                effects = { 
                    { id = "LIGHTS_FAILURE", value = 1.0, aggregation = "boolean_or" },
                    { id = "ENGINE_FAILURE", value = 1.0, extraData = {starter = false, message = "ads_breakdowns_electrical_system_malfunction_stage4_message", reason = "BREAKDOWN"}, aggregation = "boolean_or"} 
                },
                indicators = {
                    { id = db.BATTERY, color = color.CRITICAL, switchOn = true, switchOff = false }
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
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_carburetor_clogging_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 3.0,
                repairPrice = 0.2,
                effects = {
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.4, extraData = {timer = 0, duration = 200, status = 'IDLE', amplitude = 0.5, motorLoad = 0.8}, aggregation = "max" },
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_carburetor_clogging_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0,
                repairPrice = 0.4,
                effects = {
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.25, extraData = {timer = 0, duration = 300, status = 'IDLE', amplitude = 0.8, motorLoad = 0.8}, aggregation = "max" },
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
                progressMultiplier = 1.0,
                repairPrice = 0.8, 
                effects = { 
                    { id = "ENGINE_HESITATION_CHANCE", value = 0.15, extraData = {timer = 0, duration = 400, status = 'IDLE', amplitude = 1.0, motorLoad = 0.8}, aggregation = "max" },
                    { id = "ENGINE_STALLS_CHANCE", value = 8.0, extraData = {message = "ads_breakdowns_engine_stalled_message"}, aggregation = "min"},
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
                repairPrice = 1.6, 
                effects = { 
                    { id = "ENGINE_FAILURE", value = 1.0, extraData = {starter = true, message = "ads_breakdowns_carburetor_clogging_stage4_message", reason = "BREAKDOWN"}, aggregation = "boolean_or"} 
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    YIELD_SENSOR_MALFUNCTION = {
        isSelectable = true,
        part = "",
        isApplicable = function(vehicle)
            local spec = vehicle.spec_AdvancedDamageSystem
            local vtype = vehicle.type.name
            return spec.year > 2000 and (vtype == 'combineDrivable' or vtype == 'combineCutter')
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_yield_sensor_malfunction_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 4.0,
                repairPrice = 0.24,
                effects = {
                    { id = "YIELD_REDUCTION_MODIFIER", value = -0.05, aggregation = "sum" }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_yield_sensor_malfunction_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0,
                repairPrice = 0.48,
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
                progressMultiplier = 1.0,
                repairPrice = 0.96, 
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
                repairPrice = 1.92, 
                effects = { 
                    { id = "YIELD_REDUCTION_MODIFIER", value = -0.4, aggregation = "sum", extraData = {message = 'ads_breakdowns_yield_sensor_malfunction_stage4_message'} },
                },
                indicators = {
                    { id = db.ENGINE, color = color.CRITICAL, switchOn = true, switchOff = false }
                }
            }
        }
    },

    MATERIAL_FLOW_SYSTEM_WEAR = {
        isSelectable = true,
        part = "",
        isApplicable = function(vehicle)
            local spec = vehicle.spec_AdvancedDamageSystem
            local vtype = vehicle.type.name
            return (vtype == 'combineDrivable' or vtype == 'combineCutter')
        end,
        stages = {
            {
                severity = "ads_breakdowns_severity_minor",
                description = "ads_breakdowns_material_flow_system_wear_stage1_description",
                detectionChance = 1.0,
                progressMultiplier = 4.0,
                repairPrice = 0.24,
                effects = {
                    { id = "YIELD_REDUCTION_MODIFIER", value = -0.02, aggregation = "sum" }
                }
            },
            {
                severity = "ads_breakdowns_severity_moderate",
                description = "ads_breakdowns_material_flow_system_wear_stage2_description",
                detectionChance = 1.0,
                progressMultiplier = 2.0,
                repairPrice = 0.48,
                effects = {
                    { id = "YIELD_REDUCTION_MODIFIER", value = -0.05, aggregation = "sum" },
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.05, aggregation = "sum"}
                }
            },
            { 
                severity = "ads_breakdowns_severity_major",
                description = "ads_breakdowns_material_flow_system_wear_stage3_description",
                detectionChance = 1.0,
                progressMultiplier = 1.0,
                repairPrice = 0.96, 
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
                repairPrice = 1.92, 
                effects = { 
                    { id = "YIELD_REDUCTION_MODIFIER", value = -0.80, aggregation = "sum", extraData = {message = "ads_breakdowns_material_flow_system_wear_stage4_message"}},
                    { id = "ENGINE_TORQUE_MODIFIER", value = -0.30, aggregation = "sum"},
                },
                indicators = {
                    { id = db.WARNING, color = color.CRITICAL, switchOn = true, switchOff = false },
                    { id = db.ENGINE, color = color.WARNING, switchOn = true, switchOff = false }
                }
            }
        }
    },
}

-- ==========================================================
--                     BREAKDOWN EFFECTS
-- ==========================================================

ADS_Breakdowns.EffectApplicators = {}

local function saveOrigFunc(v, funcName)
    if v.spec_AdvancedDamageSystem.originalFunctions[funcName] == nil then
        v.spec_AdvancedDamageSystem.originalFunctions[funcName] = v[funcName]
    end
end

local function restoreOrigFunc(v, funcName)
    local originalFunc = v.spec_AdvancedDamageSystem.originalFunctions[funcName]
    if originalFunc ~= nil then
        v[funcName] = originalFunc
        v.spec_AdvancedDamageSystem.originalFunctions[funcName] = nil
    end
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

local function showMessage(v, effectData)
    if effectData ~= nil and effectData.extraData ~= nil and effectData.extraData.message ~= nil then
        if v.getIsControlled ~= nil and v:getIsControlled() then
            g_currentMission:showBlinkingWarning(g_i18n:getText(effectData.extraData.message), 10000)
        end 
    end
end

--- ENGINE_FAILURE
ADS_Breakdowns.EffectApplicators.ENGINE_FAILURE = {
    getOriginalFunctionName = function()
        return "ENGINE_FAILURE"
    end,
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying ENGINE_FAILURE effect.")
        if vehicle:getIsMotorStarted() then
            vehicle:stopMotor()
        end
    end,
    remove = function(vehicle)
        log_dbg("Removing ENGINE_FAILURE effect.")
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
        showMessage(vehicle, effectData)
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing LIGHTS_FAILURE effect")
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

        if vehicle.spec_AdvancedDamageSystem.originalFunctions[originalFuncName] == nil then
            vehicle.spec_AdvancedDamageSystem.originalFunctions[originalFuncName] = motor.getTorqueCurveValue
        end

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
        local originalFunc = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalFuncName]

        if originalFunc ~= nil then
            log_dbg("Restoring original function:", originalFuncName)
            motor.getTorqueCurveValue = originalFunc
            vehicle.spec_AdvancedDamageSystem.originalFunctions[originalFuncName] = nil
            vehicle:updateMotorProperties()
        end
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
        showMessage(vehicle, effectData)

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
        local originalValueName = "clutchSlippingTime"

        if vehicle.spec_AdvancedDamageSystem.originalFunctions[originalFuncName] == nil then
            vehicle.spec_AdvancedDamageSystem.originalFunctions[originalFuncName] = motor.getMinMaxGearRatio
        end

        if vehicle.spec_AdvancedDamageSystem.originalFunctions[originalValueName] == nil then
            vehicle.spec_AdvancedDamageSystem.originalFunctions[originalValueName] = motor.clutchSlippingTime
        end

        motor.clutchSlippingTime = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalValueName] * (1 + effectData.value) ^ 3

        showMessage(vehicle, effectData)

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
        local originalFunc = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalFuncName]

        if originalFunc ~= nil then
            motor.getMinMaxGearRatio = originalFunc
            vehicle.spec_AdvancedDamageSystem.originalFunctions[originalFuncName] = nil
        end

        local originalValueName = "clutchSlippingTime"
        local originalValue = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalValueName]

        motor.clutchSlippingTime = originalValue
        vehicle.spec_AdvancedDamageSystem.originalFunctions[originalValueName] = nil

        if originalValue ~= nil then
            motor.clutchSlippingTime = originalValue
            vehicle.spec_AdvancedDamageSystem.originalFunctions[originalValueName] = nil
        end
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


-------- POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT ----------
ADS_Breakdowns.EffectApplicators.POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT = {
    getEffectName = function()
        return "POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT" 
    end,

    apply = function(vehicle, effectData, handler)
        log_dbg("Applying POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT:", effectData.value)
        local motor = vehicle:getMotor()
        if motor == nil then return end

        showMessage(vehicle, effectData)

        local originalApplyFuncName = "applyTargetGear"
        if vehicle.spec_AdvancedDamageSystem.originalFunctions[originalApplyFuncName] == nil then
            vehicle.spec_AdvancedDamageSystem.originalFunctions[originalApplyFuncName] = motor.applyTargetGear
        end

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

        local originalApplyFuncName = "applyTargetGear"
        local originalApplyFunc = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalApplyFuncName]
        if originalApplyFunc ~= nil then
            log_dbg("Restoring original function:", originalApplyFuncName)
            motor.applyTargetGear = originalApplyFunc
            vehicle.spec_AdvancedDamageSystem.originalFunctions[originalApplyFuncName] = nil
        end

        local effectName = handler.getEffectName()
        if vehicle.spec_AdvancedDamageSystem.activeFunctions[effectName] ~= nil then
            vehicle.spec_AdvancedDamageSystem.activeFunctions[effectName] = nil
        end
    end
}


---------------- HYDRAULIC_SPEED_MODIFIER -------------------
ADS_Breakdowns.EffectApplicators.HYDRAULIC_SPEED_MODIFIER = {
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying HYDRAULIC_SPEED_MODIFIER effect")
        showMessage(vehicle, effectData)
    end,

    remove = function(vehicle, handler)
        log_dbg("Removing HYDRAULIC_SPEED_MODIFIER effect.")
    end
}


---------------- YIELD_REDUCTION_MODIFIER -------------------
ADS_Breakdowns.EffectApplicators.YIELD_REDUCTION_MODIFIER = {
    getOriginalFunctionName = function()
        return "addCutterArea"
    end,
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying YIELD_REDUCTION_MODIFIER effect")
        showMessage(vehicle, effectData)
        local originalFuncName = handler.getOriginalFunctionName()
        saveOrigFunc(vehicle, originalFuncName)

        vehicle.addCutterArea = function(v, area, realArea, ...)
            local origFunc = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalFuncName]
            local modifiedRealArea = realArea * math.max(1 + effectData.value, 0.2)
            return origFunc(v, area, modifiedRealArea, ...)
        end

    end,

    remove = function(vehicle, handler)
        log_dbg("Removing YIELD_REDUCTION_MODIFIER effect.")
        local originalFuncName = handler.getOriginalFunctionName()
        restoreOrigFunc(vehicle, originalFuncName)
    end
}


-- ==========================================================
--                 EFFECTS WITH PROBABILITY
-- ==========================================================

------------------- ENGINE_STALLS_CHANCE --------------------
ADS_Breakdowns.EffectApplicators.ENGINE_STALLS_CHANCE = {
    getEffectName = function() return "ENGINE_STALLS_CHANCE" end,
    apply = function(vehicle, effectData, handler)
        log_dbg("Applying ENGINE_STALLS_CHANCE effect.")
        local effectName = handler.getEffectName()
        local activeFunc = function(v, dt)
            if v:getIsMotorStarted() then
                local effect = v.spec_AdvancedDamageSystem.activeEffects.ENGINE_STALLS_CHANCE
                if effect and effect.value > 0 then
                    if math.random() < ADS_Utils.getChancePerFrameFromMeanTime(dt, effect.value) then
                        if v.stopMotor then
                            v:stopMotor()
                            showMessage(vehicle, effectData)
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
        local activeFunc = function(v, dt)
            if not v:getIsMotorStarted() then
                local effect = v.spec_AdvancedDamageSystem.activeEffects.ENGINE_START_FAILURE_CHANCE
                if effect and effect.value > 0 then
                    if effect.extraData.status == "CRANKING" then
                        g_soundManager:playSample(v.spec_AdvancedDamageSystem.samples.starter)
                        effect.extraData.status = "PASSED"
                    end
                    if effect.extraData.status == "PASSED" then
                        effect.extraData.timer = effect.extraData.timer + dt
                    end
                    if effect.extraData.timer >= 2000 and effect.extraData.status == "PASSED" then
                        effect.extraData.status = "IDLE"
                        effect.extraData.timer = 0
                    end
                end
            end
        end
        addFuncToActive(vehicle, effectName, activeFunc)
    end,
    remove = function(vehicle, handler)
        log_dbg("Removing ENGINE_START_FAILURE_CHANCE effect.")
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

        showMessage(vehicle, effectData)

        local function playRandomSample()
            local x = math.random()
            if x < 0.333 then 
                g_soundManager:playSample(vehicle.spec_AdvancedDamageSystem.samples.transmissionShiftFailed1)
            elseif x < 0.666 then
                g_soundManager:playSample(vehicle.spec_AdvancedDamageSystem.samples.transmissionShiftFailed2)
            else
                g_soundManager:playSample(vehicle.spec_AdvancedDamageSystem.samples.transmissionShiftFailed3)
            end
        end

        local originalShiftFuncName = "shiftGear"
        if vehicle.spec_AdvancedDamageSystem.originalFunctions[originalShiftFuncName] == nil then
            vehicle.spec_AdvancedDamageSystem.originalFunctions[originalShiftFuncName] = motor.shiftGear
        end

        motor.shiftGear = function(m, up)
            if effectData.extraData.status == "FAILED" then return end
            if math.random() < effectData.value then
                log_dbg("GEAR SHIFT FAILED! (shiftGear)")
                effectData.extraData.status = "FAILED"
                if m.vehicle and m.vehicle.spec_AdvancedDamageSystem and effectData.value < 1.0 then
                    playRandomSample()
                end
                return
            end
            
            local originalFunc = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalShiftFuncName]
            return originalFunc(m, up)
        end
        
        local originalSelectFuncName = "selectGear"
        if vehicle.spec_AdvancedDamageSystem.originalFunctions[originalSelectFuncName] == nil then
            vehicle.spec_AdvancedDamageSystem.originalFunctions[originalSelectFuncName] = motor.selectGear
        end

        motor.selectGear = function(m, gearIndex, activation)
            if effectData.extraData.status == "FAILED" then return end
            if activation then
                if math.random() < effectData.value then
                    effectData.extraData.status = "FAILED"
                    log_dbg("GEAR SHIFT FAILED! (selectGear)")
                    if m.vehicle and m.vehicle.spec_AdvancedDamageSystem and effectData.value < 1.0 then
                       playRandomSample()
                    end
                    return
                end
            end

            local originalFunc = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalSelectFuncName]
            return originalFunc(m, gearIndex, activation)
        end
        
        local originalUpdateFuncName = "updateGear"
        if vehicle.spec_AdvancedDamageSystem.originalFunctions[originalUpdateFuncName] == nil then
            vehicle.spec_AdvancedDamageSystem.originalFunctions[originalUpdateFuncName] = motor.updateGear
        end

        motor.updateGear = function(m, acceleratorPedal, brakePedal, dt)
            local wasShifting = (m.gear == 0 and m.gearChangeTimer > 0)
            local originalFunc = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalUpdateFuncName]
            local adjAcceleratorPedal, adjBrakePedal = originalFunc(m, acceleratorPedal, brakePedal, dt)
            local isShifting = (m.gear == 0 and m.gearChangeTimer > 0)
            
            if isShifting and not wasShifting then
                if math.random() < effectData.value then
                    log_dbg("GEAR SHIFT FAILED! (updateGear)")
                    effectData.extraData.status = "FAILED"
                    effectData.extraData.timer = 0            

                    m.gearChangeTimer = effectData.extraData.duration
                    m.autoGearChangeTimer = effectData.extraData.duration
                    
                    if m.vehicle and m.vehicle.spec_AdvancedDamageSystem and effectData.value < 1.0 then
                        playRandomSample()
                    end
                    
                    if effectData.value >= 1.0 then
                        m.targetGear = m.previousGear
                    end
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
        local originalShiftFunc = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalShiftFuncName]
        if originalShiftFunc ~= nil then
            log_dbg("Restoring original function:", originalShiftFuncName)
            motor.shiftGear = originalShiftFunc
            vehicle.spec_AdvancedDamageSystem.originalFunctions[originalShiftFuncName] = nil
        end
        
        local originalSelectFuncName = "selectGear"
        local originalSelectFunc = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalSelectFuncName]
        if originalSelectFunc ~= nil then
            log_dbg("Restoring original function:", originalSelectFuncName)
            motor.selectGear = originalSelectFunc
            vehicle.spec_AdvancedDamageSystem.originalFunctions[originalSelectFuncName] = nil
        end

        local originalUpdateFuncName = "updateGear"
        local originalUpdateFunc = vehicle.spec_AdvancedDamageSystem.originalFunctions[originalUpdateFuncName]
        if originalUpdateFunc ~= nil then
            log_dbg("Restoring original function:", originalUpdateFuncName)
            motor.updateGear = originalUpdateFunc
            vehicle.spec_AdvancedDamageSystem.originalFunctions[originalUpdateFuncName] = nil
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
                        end
                    elseif v:getMotorLoadPercentage() > 0.8 and effect.extraData.status == 'IDLE' then
                        if math.random() < ADS_Utils.getChancePerFrameFromMeanTime(dt, effect.value) then
                            effect.extraData.status = 'REJECTED'
                            effect.extraData.timer = 0
                            if motor and motor.setGear then
                                motor:setGear(0, false)
                                showMessage(vehicle, effectData)
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

                        elseif effect.extraData.status == 'IDLE' then
                            if math.random() < ADS_Utils.getChancePerFrameFromMeanTime(dt, effect.value) then
                                effect.extraData.maskBackup = v:getLightsTypesMask()
                                if effect.extraData.maskBackup == 0 then return end
                                effect.extraData.status = 'FLICKING'
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
            local spec_ads = v.spec_AdvancedDamageSystem
            local extra = effectData.extraData

            if extra.status == "CHOKING" then
                extra.timer = extra.timer + dt
                if extra.timer > extra.duration then
                    extra.status = "IDLE"
                    extra.timer = 0
                end
            elseif vehicle:getMotorLoadPercentage() > extra.motorLoad then
                if effectData.value > 0 and math.random() < ADS_Utils.getChancePerFrameFromMeanTime(dt, effectData.value) and extra.status == "IDLE" then
                    extra.status = "CHOKING"
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
        if spec.activeEffects.ENGINE_FAILURE.extraData.message then
            g_currentMission:showBlinkingWarning(g_i18n:getText(spec.activeEffects.ENGINE_FAILURE.extraData.message), 100)
        end
        if spec.activeEffects.ENGINE_FAILURE.extraData.starter  then
            return true
        else
            return false
        end
    elseif self:isUnderMaintenance() then
        if self.getIsControlled ~= nil and self:getIsControlled() then
            g_currentMission:showBlinkingWarning(g_i18n:getText(self:getCurrentStatus()) .. " " .. g_i18n:getText("ads_breakdown_at_progress_message", 100)) 
        end
        return false
    end
    return superFunc(self)
end


function ADS_Breakdowns.startMotor(self, superFunc, noEventSend)

    if self.spec_AdvancedDamageSystem and self.spec_AdvancedDamageSystem.activeEffects then
        local spec = self.spec_AdvancedDamageSystem

        if self.spec_AdvancedDamageSystem.activeEffects.ENGINE_FAILURE then
            local engineFailureEffect = spec.activeEffects.ENGINE_FAILURE
            if (engineFailureEffect and engineFailureEffect.value >= 1.0) then
                g_soundManager:playSample(spec.samples.starter)
                return
            end
        end

        if self.spec_AdvancedDamageSystem.activeEffects.ENGINE_START_FAILURE_CHANCE then
            local startFailureEffect = spec.activeEffects.ENGINE_START_FAILURE_CHANCE
            
            if startFailureEffect and startFailureEffect.extraData.status ~= "IDLE" then
                return
            end


            if startFailureEffect and startFailureEffect.value > 0 then
                local tempModifier = math.clamp(spec.engineTemperature / 90, 0.5, 1.0)
                local chance = math.min(startFailureEffect.value / tempModifier , 0.8)
                if math.random() < chance then
                    spec.activeEffects.ENGINE_START_FAILURE_CHANCE.extraData.status = "CRANKING"
                    spec.activeEffects.ENGINE_START_FAILURE_CHANCE.extraData.timer = 0
                    return
                end
            else
                superFunc(self, noEventSend)
            end
            
        end
    end
    superFunc(self, noEventSend)
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
function ADS_Breakdowns.updateVehiclePhysics(vehicle, superFunc, axisForward, axisSide, doHandbrake, dt)
    local spec_drivable = vehicle.spec_drivable
    local acceleration = 0
    
    if vehicle:getIsMotorStarted() and vehicle:getMotorStartTime() <= g_currentMission.time then
        acceleration = axisForward
        
        if math.abs(acceleration) > 0 then
            vehicle:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
        end
        
        if spec_drivable.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF then
            acceleration = 1
        end
    end
    
    if not vehicle:getCanMotorRun() then
        acceleration = 0
        if vehicle:getIsMotorStarted() then
            vehicle:stopMotor()
        end
    end

    local spec_ads = vehicle.spec_AdvancedDamageSystem
    local brakeEffect = spec_ads and spec_ads.activeEffects.BRAKE_FORCE_MODIFIER
    local limpEffect = spec_ads and spec_ads.activeEffects.ENGINE_LIMP_EFFECT
    local hesitationEffect = spec_ads and spec_ads.activeEffects.ENGINE_HESITATION_CHANCE
    local isBraking = false
    local drivingMode = vehicle:getDirectionChangeMode()

    if hesitationEffect and hesitationEffect.extraData and hesitationEffect.extraData.status == "CHOKING" then
        acceleration = acceleration * math.max(1 - hesitationEffect.extraData.amplitude, 0)
    end

    if limpEffect and limpEffect.value then
        local maxAllowedAcceleration = math.max(1 + limpEffect.value, 0.2)
        if math.abs(acceleration) > maxAllowedAcceleration then
            if drivingMode == 2 then
                if acceleration > maxAllowedAcceleration then
                    acceleration = maxAllowedAcceleration
                end
            else
                if math.sign(vehicle.movingDirection) == math.sign(acceleration) then
                    if acceleration > 0 then
                        acceleration = maxAllowedAcceleration
                    else
                        acceleration = -1 * maxAllowedAcceleration
                    end
                end   
            end
        end
    end

    if brakeEffect and brakeEffect.value ~= 0 then
        if drivingMode == 2 then
            isBraking = acceleration < -0.01
        else
            isBraking = vehicle.movingDirection ~= 0 and acceleration ~= 0 and math.sign(vehicle.movingDirection) ~= math.sign(acceleration)
        end
        
        if isBraking then
            local modifier = math.max(0.01, 1 + brakeEffect.value) 
            acceleration = acceleration * modifier
        end
    end

    if vehicle.getIsControlled ~= nil and vehicle:getIsControlled() then
        local targetRotatedTime = 0
        if vehicle.maxRotTime ~= nil and vehicle.minRotTime ~= nil then
            if axisSide < 0 then
                targetRotatedTime = math.min(-vehicle.maxRotTime * axisSide, vehicle.maxRotTime)
            else
                targetRotatedTime = math.max(vehicle.minRotTime * axisSide, vehicle.minRotTime)
            end
        end
        vehicle.rotatedTime = targetRotatedTime
    end

    if vehicle.finishedFirstUpdate and vehicle.spec_wheels ~= nil and #vehicle.spec_wheels.wheels > 0 then
        WheelsUtil.updateWheelsPhysics(vehicle, dt, vehicle.lastSpeedReal * vehicle.movingDirection, acceleration, doHandbrake, g_currentMission.missionInfo.stopAndGoBraking)
    end
    
    return acceleration
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
            
            jointDesc.moveDefaultTime = jointDesc.ads_originalMoveDefaultTime / performance
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


Plow.setRotationMax = Utils.overwrittenFunction(Plow.setRotationMax, ADS_Breakdowns.applyHydraulicDamageToPlowRotation)
Plow.setRotationCenter = Utils.overwrittenFunction(Plow.setRotationCenter, ADS_Breakdowns.applyHydraulicDamageToPlowCenterRotation)
AttacherJoints.onUpdateTick = Utils.overwrittenFunction(AttacherJoints.onUpdateTick, ADS_Breakdowns.applyHydraulicDamageToAttacher)
Cylindered.onUpdate = Utils.overwrittenFunction(Cylindered.onUpdate, ADS_Breakdowns.applyHydraulicDamageToCylindered)
Foldable.setFoldState = Utils.overwrittenFunction(Foldable.setFoldState, ADS_Breakdowns.applyHydraulicDamageToFoldable)
