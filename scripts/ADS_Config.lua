
ADS_Config = {
    -- Enables or disables extensive debug logging in the console.
    -- When true, the mod will print detailed information about its calculations,
    -- such as wear rates, breakdown checks, and temperature changes.
    -- Set to false for normal gameplay to avoid performance impact and console spam.
    VER = 50,

    DEBUG = false,

    -- How often quick, interactive effects are updated, in milliseconds.
    -- This controls things that need to be very responsive, like flickering lights,
    -- engine stalls, or gear shift failures. A lower value provides a smoother
    -- and more immediate experience for these effects.
    --
    -- WARNING: It is strongly recommended to keep this value low (e.g., under 200ms).
    -- High values can cause visual glitches (like lights staying off for too long)
    -- or make gameplay effects feel unresponsive and delayed.
    EFFECTS_UPDATE_DELAY = 100, -- (100ms = 10 times per second)
    
    -- How often the main simulation logic (wear, temperature, etc.) updates, in milliseconds.
    -- This handles the slow-burning processes. A higher value is better for performance
    -- as these calculations do not need to run every frame.
    CORE_UPDATE_DELAY = 500,
    META_UPDATE_DELAY = 30000,

    -- ====================================================================================
    -- CORE SIMULATION PARAMETERS
    -- This section controls the fundamental mechanics of wear, tear, and breakdowns.
    -- ====================================================================================
    CORE = {
        BASE_SERVICE_WEAR = 0.1,
        BASE_SYSTEMS_WEAR = 0.01,
        DOWNTIME_MULTIPLIER = 0.05,
        UNDER_ROOF_DOWNTIME_MULTIPLIER = 0.01,
        RAIN_FACTOR = 1.1,
        HALL_FACTOR = 1.3,
        SNOW_FACTOR = 1.1,

        SERVICE_EXPIRED_THRESHOLD = 0.5,

        SYSTEM_WEIGHTS = {
            engine=0.22, 
            transmission=0.16, 
            hydraulics=0.12, 
            cooling=0.12, 
            electrical=0.08, 
            chassis=0.10, 
            workProcess=0.08, 
            materialFlow=0.06, 
            fuel=0.06
        },

        SYSTEM_STRESS_ACCUMULATION_MULTIPLIERS = {
            engine=10.0, 
            transmission=10.0, 
            hydraulics=10.0, 
            cooling=10.0, 
            electrical=10.0, 
            chassis=10.0, 
            workProcess=10.0, 
            materialFlow=10.0, 
            fuel=10.0
        },

        ENGINE_FACTOR_DATA = {
            MOTOR_IDLING_MULTIPLIER = 0.5,
            SERVICE_EXPIRED_MULTIPLIER = 10.0,
            MOTOR_IDLING_THRESHOLD = 0.3,
            MOTOR_OVERLOADED_MULTIPLIER = 1.0,
            MOTOR_OVERLOADED_THRESHOLD = 0.95,
            COLD_MOTOR_THRESHOLD = 50,
            COLD_MOTOR_MULTIPLIER = 50.0,
            OVERHEAT_MOTOR_MULTIPLIER = 50.0,
            OVERHEAT_MOTOR_THRESHOLD = 95,
        },

        TRANSMISSION_FACTOR_DATA = {
            TRANSMISSION_IDLING_MULTIPLIER = 0.2,
            SERVICE_EXPIRED_MULTIPLIER = 6.0,
            PULL_OVERLOAD_MULTIPLIER = 2.0,
            PULL_OVERLOAD_THRESHOLD = 0.82,
            PULL_OVERLOAD_TIMER_THRESHOLD = 30,
            LUGGING_MULTIPLIER = 5.0,
            LUGGING_RPM_THRESHOLD = 0.8,
            LUGGING_MOTORLOAD_THRESHOLD = 0.80,
            HEAVY_TRAILER_MULTIPLIER = 3.0,
            HEAVY_TRAILER_THRESHOLD = 1.2,
            HEAVY_TRAILER_MOTORLOAD_THRESHOLD = 0.5,
            WHEEL_SLIP_MULTIPLIER = 10.0,
            WHEEL_SLIP_THRESHOLD = 0.3,
            COLD_TRANSMISSION_MULTIPLIER = 20.0,
            COLD_TRANSMISSION_THRESHOLD = 50,
            OVERHEAT_TRANSMISSION_MAX_MULTIPLIER = 50.0,
            OVERHEAT_TRANSMISSION_THRESHOLD = 95,
        },

        HYDRAULICS_FACTOR_DATA = {
            HYDRAULICS_IDLING_MULTIPLIER = 0.2,
            SERVICE_EXPIRED_MULTIPLIER = 4.0,
            HEAVY_LIFT_FACTOR_MULTIPLIER = 5.0,
            HEAVY_LIFT_FACTOR_THRESHOLD = 0.3,
            OPERATING_FACTOR_MULTIPLIER = 5.0,
            COLD_OIL_MULTIPLIER = 100,
            COLD_OIL_THRESHOLD = 30,
            PTO_OPERATING_FACTOR = 0.5,
            PTO_SHARP_ANGLE_FACTOR_MULTIPLIER = 10.0,
            PTO_SHARP_ANGLE_FACTOR_THRESHOLD = 20.0
        },

        COOLING_FACTOR_DATA = {
            COOLING_IDLING_MULTIPLIER = 0.2,
            SERVICE_EXPIRED_MULTIPLIER = 6.0,
            HIGH_COOLING_FACTOR_MULTIPLIER = 3.0,
            HIGH_COOLING_FACTOR_THRESHOLD = 0.8,
            OVERHEAT_FACTOR_MULTIPLIER = 20.0,
            OVERHEAT_FACTOR_THRESHOLD = 95,
            COLD_SHOCK_FACTOR_MULTIPLIER = 20.0,
            COLD_SHOCK_FACTOR_THRESHOLD = 50
        },

        ELECTRICAL_FACTOR_DATA = {
            SERVICE_EXPIRED_MULTIPLIER = 2.0,
            CRANKING_STRESS_DAMAGE = 0.0001,
            CRANKING_STRESS_THRESHOLD = 5,
            RAIN_FACTOR_MULTIPLIER = 0.5,
            SNOW_FACTOR_MULTIPLIER = 0.3,
            HALL_FACTOR_MULTIPLIER = 1.0,
            OVERHEAT_FACTOR_MULTIPLIER = 20.0,
            OVERHEAT_FACTOR_THRESHOLD = 95,
            LIGHTS_FACTOR_MULTIPLIER = 0.2
        },

        CHASSIS_FACTOR_DATA = {
            SERVICE_EXPIRED_MULTIPLIER = 6.0,
        },

        WORKPROCESS_FACTOR_DATA = {
            SERVICE_EXPIRED_MULTIPLIER = 2.0,
        },

        MATERIALFLOW_FACTOR_DATA = {
            SERVICE_EXPIRED_MULTIPLIER = 2.0,
        },

        FUEL_FACTOR_DATA = {
            SERVICE_EXPIRED_MULTIPLIER = 4.0,
        },


        STRESS_COOLDOWN = 0.5,
        CVT_SHIFT_SPEED_THRESHOLD = 1.0,
        CVT_SHOCK_MULTIPLIER = 100.0,

        CONCURRENT_BREAKDOWN_LIMIT_PER_VEHICLE = 5,
        AI_OVERLOAD_AND_OVERHEAT_CONTROL = true,
        AI_WORKER_PID = {
            MIN_SPEED = 3.0,
            MAX_REDUCTION = 16.0,
            TARGET_STRESS = 0.30,
            DEADBAND = 0.03,
            LOAD_START = 0.8,
            LOAD_FULL = 0.95,
            ENGINE_TEMP_START = 92.0,
            ENGINE_TEMP_FULL = 99.0,
            TRANS_TEMP_START = 92.0,
            TRANS_TEMP_FULL = 99.0,
            WEIGHT_LOAD = 0.50,
            WEIGHT_ENGINE_TEMP = 0.25,
            WEIGHT_TRANS_TEMP = 0.25,
            FILTER_TAU = 0.7,
            KP = 4.5,
            KI = 0.8,
            KD = 0.45,
            MAX_INTEGRAL = 3.0,
            REDUCTION_RATE_DOWN = 8.0,
            RECOVERY_RATE_UP = 2.5,
            APPLY_INTERVAL_MS = 180,
            MIN_APPLY_DELTA = 0.2,
            BASE_SYNC_DOWN_RATE = 1.8,
            EMERGENCY_ENGINE_TEMP = 105.0,
            EMERGENCY_TRANS_TEMP = 105.0
        },
        GENERAL_WEAR_THRESHOLD = 0.5,

        RELIABILITY_YEAR_FACTOR = 0.01,
        RELIABILITY_YEAR_FACTOR_THRESHOLD = 2000,

        BASE_BREAKDOWN_PROGRESS_TIME = 3600000,
        BREAKDOWN_PROBABILITIES = {
            STRESS_THRESHOLD = 0.1,
            MIN_MTBF = 60,
            MAX_MTBF = 3200,
            DEGREE = 3.0,
            CRITICAL_MIN = 0.05,
            CRITICAL_MAX = 0.33,
            CRITICAL_DEGREE = 5
        },
    },


    -- ====================================================================================
    -- WORKSHOP PARAMETERS
    -- Controls workshop operating hours, which affects maintenance/repair completion times.
    -- ====================================================================================
    WORKSHOP = {
        ALWAYS_AVAILABLE = false,
        -- The hour of the day (0-23) when the workshop opens. Repairs will not progress before this time.
        OPEN_HOUR = 8,  -- (8 AM)
        -- The hour of the day (0-23) when the workshop closes. Repairs will pause at this time.
        CLOSE_HOUR = 19, -- (7 PM)
        PRICE_MULTIPLIERS = {
            [1] = 1.0, DEALER = 1.0,
            [2] = 1.2, MOBILE = 1.2,
            [3] = 0.8, OWN = 0.8,
        },
    },


    -- ====================================================================================
    -- MAINTENANCE & REPAIR PARAMETERS
    -- Controls the time and cost of all service types.
    -- ====================================================================================
    MAINTENANCE = {
        PARK_VEHICLE = true,
        INSTANT_INSPECTION = false,
        WARRANTY_ENABLED = true,
        WARRANTY_MAX_OPERATING_HOURS = 20,
        WARRANTY_MAX_AGE_MONTHS = 12,

        GLOBAL_SERVICE_PRICE_MULTIPLIER = 1.0,
        GLOBAL_SERVICE_TIME_MULTIPLIER = 1.0,

        INSPECTION_TIME = 3600000,
        INSPECTION_TIME_MULTIPLIERS = {
            [1] = 1.0,  STANDARD = 1.0,
            [2] = 0.1,  VISUAL   = 0.1,
            [3] = 4.0,  COMPLETE = 4.0,
        },
        MAINTENANCE_TIME = 21600000,
        MAINTENANCE_TIME_MULTIPLIERS = {
            [1] = 1.0,  STANDARD = 1.0,
            [2] = 0.25, MINIMAL  = 0.25,
            [3] = 1.5,  EXTENDED = 1.5,
        },
        REPAIR_TIME = 14400000,
        REPAIR_TIME_MULTIPLIERS = {
            [1] = 1.0, MEDIUM = 1.0,
            [2] = 1.5, LOW   = 1.5,
            [3] = 0.5, HIGH    = 0.5,
        },
        OVERHAUL_TIME = 86400000,
        OVERHAUL_TIME_MULTIPLIERS = {
            [1] = 1.0, STANDARD = 1.0,
            [2] = 0.5, PARTIAL  = 0.5,
            [3] = 2.0, FULL     = 2.0,
        },

        MAINTENANCE_SERVICE_RESTORE_MULTIPLIERS = {
            [1] = 1.0,  STANDARD = 1.0,
            [2] = 0.75, MINIMAL  = 0.75,
            [3] = 1.2,  EXTENDED = 1.2,
        },
        OVERHAUL_MIN_CONDITION_RESTORE_MULTIPLIERS = {
            [1] = 0.61, STANDARD = 0.61,
            [2] = 0.41, PARTIAL  = 0.41,
            [3] = 0.81, FULL     = 0.81,
        },
        OVERHAUL_MAX_CONDITION_RESTORE_MULTIPLIERS = {
            [1] = 0.79, STANDARD = 0.79,
            [2] = 0.59, PARTIAL  = 0.59,
            [3] = 0.99, FULL     = 0.99,
        },

        RE_OVERHAUL_FACTOR = 0.1,

        PARTS_BREAKDOWN_CHANCES = {
            [1] = 0.1,  OEM         = 0.1,
            [2] = 0.5,  USED        = 0.5,
            [3] = 0.33, AFTERMARKET = 0.33,
            [4] = 0.0,  PREMIUM     = 0.0,
        },
        PARTS_BREAKDOWN_TIME = 18000000,

        PARTS_PRICE_MULTIPLIERS = {
            [1] = 1.0,  OEM         = 1.0,
            [2] = 0.33, USED        = 0.33,
            [3] = 0.66, AFTERMARKET = 0.66,
            [4] = 1.20, PREMIUM     = 1.20,
        },
        MAINTENANCE_PRICE_MULTIPLIERS = {
            [1] = 1.0,  STANDARD = 1.0,
            [2] = 0.65, MINIMAL  = 0.65,
            [3] = 1.25, EXTENDED = 1.25,
        },
        REPAIR_PRICE_MULTIPLIERS = {
            [1] = 1.0, MEDIUM = 1.0,
            [2] = 0.8, LOW    = 0.8,
            [3] = 1.2, HIGH   = 1.2,
        },
        OVERHAUL_PRICE_MULTIPLIERS = {
            [1] = 0.5, STANDARD = 0.5,
            [2] = 0.3, PARTIAL  = 0.3,
            [3] = 0.8, FULL     = 0.8,
        },
        INSPECTION_PRICE_MULTIPLIERS = {
            [1] = 1.0, STANDARD = 1.0,
            [2] = 0.1, VISUAL   = 0.1,
            [3] = 4.0, COMPLETE = 4.0,
        },
        AGE_FACTOR_PRICE_FACTOR = 0.01,
        OWN_WORKSHOP_PRICE_MULTIPLIER = 0.8,
    },

    -- ====================================================================================
    -- THERMAL DYNAMICS PARAMETERS
    -- Controls engine and transmission temperature simulation.
    -- ====================================================================================
    THERMAL = {
        -- --- General Thermal Physics ---

        -- A global multiplier for how quickly temperatures change (both heating and cooling).
        -- Higher value means more volatile temperatures.
        TEMPERATURE_CHANGE_SPEED = 1.8,

        -- The vehicle speed (kph) at which cooling from airflow starts to take effect.
        SPEED_COOLING_MIN_SPEED = 15,
        -- The vehicle speed (kph) at which cooling from airflow reaches its maximum effect.
        SPEED_COOLING_MAX_SPEED = 50,
        -- The maximum cooling factor provided by airflow at max speed.
        SPEED_COOLING_MAX_EFFECT = 0.3,

        -- Controls how quickly the vehicle loses heat to the environment when stationary (convection).
        CONVECTION_FACTOR = 0.0005,
        -- An exponent for convection and radiator. A value > 1 means the hotter the vehicle is compared to the
        -- environment, the disproportionately faster it will cool.
        DELTATEMP_FACTOR_DEGREE = 1.25,

        -- The maximum reduction in radiator effectiveness due to dirt.
        -- 0.2 means a fully dirty vehicle's radiator is 20% less effective.
        MAX_DIRT_INFLUENCE = 0.15,
        
        -- The time constant for the low-pass filter on the temperature gauge.
        -- Higher value means the needle on the dashboard will move more slowly and smoothly,
        -- filtering out rapid temperature fluctuations.
        TAU = 5000,

        -- --- Engine-Specific Thermal ---

        -- The rate of heat generated by the engine at maximum load.
        ENGINE_MAX_HEAT = 1.05,
        -- The rate of heat generated by the engine when idling (0% load).
        ENGINE_MIN_HEAT = 0.4,
        -- The temperature (in Celsius) at which the engine's thermostat begins to open.
        ENGINE_THERMOSTAT_MIN_TEMP = 80,
        -- The base cooling rate from the radiator when the thermostat is fully closed.
        ENGINE_RADIATOR_MIN_COOLING = 0.0005,
        -- The maximum cooling rate from the radiator when the thermostat is fully open.
        ENGINE_RADIATOR_MAX_COOLING = 0.005,

        -- --- Transmission-Specific Thermal (for CVT/hydrostatic) ---

        -- The rate of heat generated by the transmission at maximum load/slip.
        TRANS_MAX_HEAT = 1.05,
        -- The rate of heat generated by the transmission at minimum load/slip.
        TRANS_MIN_HEAT = 0.25,
        -- The temperature (in Celsius) at which the transmission's thermostat begins to open.
        TRANS_THERMOSTAT_MIN_TEMP = 80,
        -- The base cooling rate from the transmission's radiator when its thermostat is closed.
        TRANS_RADIATOR_MIN_COOLING = 0.0005,
        -- The maximum cooling rate from the transmission's radiator when its thermostat is open.
        TRANS_RADIATOR_MAX_COOLING = 0.005,

        -- --- PID Controller for Thermostat ---
        -- These values control how intelligently the thermostat opens and closes to maintain a stable temperature.
        -- Tweak these only if you are familiar with PID controllers.

        -- The ideal operating temperature (in Celsius) the system tries to maintain.
        PID_TARGET_TEMP = 90,
        -- Proportional gain: How strongly the thermostat reacts to the *current* temperature error.
        PID_KP_MAX = 0.4,
        PID_KP_MIN = 0.1,
        -- Integral gain: Corrects for small, persistent errors over time to reach the target temperature.
        PID_KI = 0.02,
        -- Derivative gain: Dampens the reaction to prevent overshooting the target temperature.
        PID_KD = 1.8,
        -- A safety limit to prevent the Integral term from growing too large ("integral windup").
        PID_MAX_INTEGRAL = 200,

        COOLING_SLOWDOWN_THRESHOLD = 90,
        COOLING_SLOWDOWN_POWER = 8,

        THERMOSTAT_TYPE_YEAR_DIVIDER = 2000,
        MECHANIC_THERMOSTAT_MIN_YEAR = 1950,
        ELECTRONIC_THERMOSTAT_MAX_YEAR = 2025,

        MECHANIC_THERMOSTAT_MIN_WAX_SPEED = 0.025,
        MECHANIC_THERMOSTAT_MAX_WAX_SPEED = 0.05,
        MECHANIC_THERMOSTAT_MIN_STICTION = 0.02,
        MECHANIC_THERMOSTAT_MAX_STICTION = 0.1,

        ELECTRONIC_THERMOSTAT_MIN_WAX_SPEED = 0.05,
        ELECTRONIC_THERMOSTAT_MAX_WAX_SPEED = 0.10,
        ELECTRONIC_THERMOSTAT_MIN_STICTION = 0.01,
        ELECTRONIC_THERMOSTAT_MAX_STICTION = 0.05
    },


    -- ====================================================================================
    -- BRAND CHARACTERISTICS
    -- This section defines unique characteristics for different vehicle brands,
    -- affecting their reliability and repair costs. This allows for creating a more
    -- diverse and realistic experience where brand choice matters.
    --
    -- Format: BRAND_NAME = { Reliability, Maintainability }
    --
    -- If a brand is not listed here, it will use the default values {1.0, 1.0}.
    -- The BRAND_NAME must match the exact name used in the game's brand definitions.
    -- ====================================================================================
    BRANDS = {

            FENDT           = {1.25, 0.80}, 
            JOHNDEERE       = {1.25, 0.85},
            VOLVO           = {1.25, 0.90},
            KOMATSU         = {1.25, 0.95},
            PONSSE          = {1.20, 0.90}, 
            ROTTNE          = {1.20, 0.90},
            CATERPILLAR     = {1.25, 0.80},
            KENWORTH        = {1.20, 0.90},
            PETERBILT       = {1.20, 0.90},
            SCHLUETER       = {1.20, 0.95},

            CLAAS           = {1.15, 0.95},
            ROPA            = {1.15, 0.85},
            HOLMER          = {1.15, 0.85},
            MACK            = {1.15, 1.00},
            KRONE           = {1.10, 1.00},
            KUBOTA          = {1.15, 1.10},
            MAN             = {1.10, 0.95},
            CHALLENGER      = {1.10, 0.90},
            AGCO            = {1.10, 0.90},
            MERCEDES        = {1.10, 0.90},
            MERCEDESBENZ    = {1.10, 0.90},
            MERCEDESBENZTRUCKS    = {1.10, 0.90},
            KRAMER          = {1.10, 0.95},

            VALTRA          = {1.10, 1.05},
            LINDNER         = {1.05, 1.00},
            GMC             = {1.05, 1.05},
            CASEIH          = {1.00, 1.00},
            NEWHOLLAND      = {1.00, 1.00},
            SDF             = {1.00, 1.00},
            MASSEYFERGUSON  = {1.00, 1.05},
            JCB             = {1.00, 0.90},
            DEUTZFAHR       = {1.00, 1.00},
            STEYR           = {1.00, 0.95},
            VERSATILE       = {1.00, 1.15}, 
            INTERNATIONAL   = {1.00, 1.15},
            FORD            = {1.00, 1.10},
            RENAULT         = {1.00, 1.05},
            INTERNATIONALHARVESTER = {1.00, 1.15},
            LANDROVER       = {0.90, 0.90}, 
            NEXAT           = {0.95, 0.65},

            ZETOR           = {0.85, 1.35},
            FIAT            = {0.90, 1.20},
            LANDINI         = {0.90, 1.15},
            SAME            = {0.90, 1.15},
            MCCORMICK       = {0.90, 1.10},
            ARMATRAC        = {0.85, 1.20},
            MAHINDRA        = {0.85, 1.25},
            STARA           = {0.85, 1.15},
            
            PTZKIROWEC      = {0.85, 1.30},
            MTZ             = {0.80, 1.50},
            SKODA           = {0.85, 1.20},
            GAZ             = {0.80, 1.40},
            MAZ             = {0.80, 1.35},
            BUEHRER         = {0.80, 1.30},
            LTZ             = {0.75, 1.55},
            PORSCHEDIESEL   = {0.70, 1.30},
            OLIVER          = {0.85, 1.25}, 
            ALLISCHALMERS   = {0.85, 1.25},


            LIZARD          = {1.00, 1.00},
            GIANTS          = {1.00, 1.00},
            NONE            = {1.00, 1.00}
    }      
}

ADS_Config.savegameFile = "advancedDamageSystem.xml"

local function log_dbg(...)
    if ADS_Config and ADS_Config.DEBUG then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i])
        end
        print("[ADS_CONFIG] " .. table.concat(args, " "))
    end
end

local function isArray(tbl)
    if type(tbl) ~= "table" then return false end
    local count = 0
    local maxIndex = 0

    for k in pairs(tbl) do
        if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then
            return false
        end
        count = count + 1
        if k > maxIndex then
            maxIndex = k
        end
    end

    if count == 0 then return false end
    return maxIndex == count
end

-- ============================================================
-- SAVE
-- ============================================================
function ADS_Config.saveToXMLFile()
    if g_currentMission == nil or g_currentMission.missionInfo == nil
       or g_currentMission.missionInfo.savegameDirectory == nil then
        log_dbg("SAVE - mission or savegame directory is nil, skipping.")
        return false
    end

    local xmlFileName = g_currentMission.missionInfo.savegameDirectory
                        .. "/" .. ADS_Config.savegameFile
    local xmlFile = createXMLFile("advancedDamageSystem", xmlFileName,
                                  "advancedDamageSystem")
    if xmlFile == nil or xmlFile == 0 then
        print("[ADS_CONFIG] SAVE ERROR - could not create XML file (handle=" .. tostring(xmlFile) .. ").")
        return false
    end

    log_dbg("Saving ADS_Config to " .. xmlFileName)

    -- --------------------------------------------------------
    local function saveNode(tbl, path)
        for k, v in pairs(tbl) do
            if type(k) == "string" and type(v) ~= "function" and k ~= "savegameFile" then
                local currentPath = path .. "." .. tostring(k)

                if type(v) == "table" then
                    if k == "BRANDS" then
                        -- brands
                        local sorted = {}
                        for name in pairs(v) do
                            table.insert(sorted, name)
                        end
                        table.sort(sorted)
                        for i, name in ipairs(sorted) do
                            local bp = currentPath .. ".brand(" .. (i - 1) .. ")"
                            setXMLString(xmlFile, bp .. "#name",            name)
                            setXMLFloat (xmlFile, bp .. "#reliability",     v[name][1])
                            setXMLFloat (xmlFile, bp .. "#maintainability", v[name][2])
                        end

                    elseif isArray(v) then
                        -- array
                        for i, val in ipairs(v) do
                            local ip = currentPath .. ".item(" .. (i - 1) .. ")"
                            if type(val) == "number" then
                                setXMLFloat(xmlFile, ip .. "#value", val)
                            elseif type(val) == "boolean" then
                                setXMLBool(xmlFile, ip .. "#value", val)
                            elseif type(val) == "string" then
                                setXMLString(xmlFile, ip .. "#value", val)
                            end
                        end

                    else
                        -- nested table
                        saveNode(v, currentPath)
                    end

                elseif type(v) == "number" then
                    setXMLFloat(xmlFile, currentPath, v)
                elseif type(v) == "boolean" then
                    setXMLBool(xmlFile, currentPath, v)
                elseif type(v) == "string" then
                    setXMLString(xmlFile, currentPath, v)
                end
            end
        end
    end
    -- --------------------------------------------------------

    saveNode(ADS_Config, "advancedDamageSystem")
    saveXMLFile(xmlFile)
    delete(xmlFile)
    log_dbg("ADS_Config: Settings saved successfully to " .. xmlFileName)
    return true
end

-- ============================================================
-- LOAD
-- ============================================================
function ADS_Config.loadFromXMLFile(mission)
    log_dbg("loadFromXMLFile called with mission: " .. tostring(mission))

    local m = mission
    if m == nil or m.missionInfo == nil or m.missionInfo.savegameDirectory == nil then
        m = g_currentMission
    end

    if m == nil then
        log_dbg("LOAD - mission is nil, using defaults.")
        return
    end
    if m.missionInfo == nil then
        log_dbg("LOAD - missionInfo is nil, using defaults.")
        return
    end
    if m.missionInfo.savegameDirectory == nil then
        log_dbg("LOAD - savegameDirectory is nil (new career?), using defaults.")
        return
    end

    local xmlFileName = m.missionInfo.savegameDirectory
                        .. "/" .. ADS_Config.savegameFile

    log_dbg("LOAD - looking for config file at: " .. xmlFileName)

    if not fileExists(xmlFileName) then
        log_dbg("LOAD - config file does not exist, using defaults.")
        return
    end

    local xmlFile = loadXMLFile("advancedDamageSystem", xmlFileName)

    if xmlFile == nil or xmlFile == 0 then
        print("[ADS_CONFIG] ERROR - failed to parse XML (handle="
              .. tostring(xmlFile) .. "). File may contain invalid XML.")
        return
    end

    log_dbg("XML loaded successfully, handle=" .. tostring(xmlFile))

    local savedVersion = getXMLFloat(xmlFile, "advancedDamageSystem.VER")
    log_dbg("Saved version: " .. tostring(savedVersion) .. ", Current version: " .. tostring(ADS_Config.VER))

    if savedVersion == nil or savedVersion ~= ADS_Config.VER then
        log_dbg("Version mismatch or missing. Expected " .. tostring(ADS_Config.VER)
                .. " but found " .. tostring(savedVersion) .. ".")
        delete(xmlFile)
        return
    end

    -- --------------------------------------------------------
    local function loadNode(targetTbl, path)
        for k, v in pairs(targetTbl) do
            if type(k) == "string" and type(v) ~= "function" and k ~= "savegameFile" and k ~= "VER" then
                local currentPath = path .. "." .. tostring(k)

                if type(v) == "table" then
                    if k == "BRANDS" then
                        -- brands
                        local loaded = {}
                        local i = 0
                        while true do
                            local bp = currentPath .. ".brand(" .. i .. ")"
                            if not hasXMLProperty(xmlFile, bp .. "#name") then
                                break
                            end
                            local name = getXMLString(xmlFile, bp .. "#name")
                            local rel  = getXMLFloat (xmlFile, bp .. "#reliability")
                            local mnt  = getXMLFloat (xmlFile, bp .. "#maintainability")
                            if name and rel and mnt then
                                loaded[name] = { rel, mnt }
                            end
                            i = i + 1
                        end
                        if next(loaded) then
                            for n, vals in pairs(loaded) do
                                targetTbl[k][n] = vals
                            end
                            print("ADS_Config:   Loaded " .. i .. " brand(s).")
                        end

                    elseif isArray(v) then
                        -- massive
                        local arr = {}
                        local i = 0
                        while true do
                            local ip = currentPath .. ".item(" .. i .. ")"
                            if not hasXMLProperty(xmlFile, ip .. "#value") then
                                break
                            end
                            local val
                            if type(v[1]) == "number" then
                                val = getXMLFloat(xmlFile, ip .. "#value")
                            elseif type(v[1]) == "boolean" then
                                val = getXMLBool(xmlFile, ip .. "#value")
                            elseif type(v[1]) == "string" then
                                val = getXMLString(xmlFile, ip .. "#value")
                            end
                            if val ~= nil then
                                table.insert(arr, val)
                            end
                            i = i + 1
                        end
                        if #arr > 0 then
                            targetTbl[k] = arr
                            log_dbg(currentPath
                                  .. " = [" .. table.concat(
                                      (function()
                                          local s = {}
                                          for _, a in ipairs(arr) do
                                              table.insert(s, tostring(a))
                                          end
                                          return s
                                      end)(), ", ") .. "]")
                        end

                    else
                        -- nested table
                        loadNode(v, currentPath)
                    end
                else
                    local loadedValue
                    if type(v) == "number" then
                        loadedValue = getXMLFloat(xmlFile, currentPath)
                    elseif type(v) == "boolean" then
                        loadedValue = getXMLBool(xmlFile, currentPath)
                    elseif type(v) == "string" then
                        loadedValue = getXMLString(xmlFile, currentPath)
                    end

                    if loadedValue ~= nil then
                        targetTbl[k] = loadedValue
                    end
                end
            end
        end
    end
    -- --------------------------------------------------------

    loadNode(ADS_Config, "advancedDamageSystem")
    delete(xmlFile)
    log_dbg("Advanced Damage System settings loaded successfully.")
end

Mission00.loadMission00Finished = Utils.appendedFunction(
    Mission00.loadMission00Finished, ADS_Config.loadFromXMLFile)

FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(
    FSCareerMissionInfo.saveToXMLFile, ADS_Config.saveToXMLFile)
