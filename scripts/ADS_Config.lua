ADS_Config = {
    -- Enables or disables extensive debug logging in the console.
    -- When true, the mod will print detailed information about its calculations,
    -- such as wear rates, breakdown checks, and temperature changes.
    -- Set to false for normal gameplay to avoid performance impact and console spam.
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
    CORE_UPDATE_DELAY = 1000, -- (1000ms = 1 time per second)

    -- How often non-critical, background tasks are updated, in milliseconds.
    -- This is for very infrequent checks, like the chance of permanent wear appearing.
    META_UPDATE_DELAY = 60000, -- (60000ms = 1 time per minute)

    -- ====================================================================================
    -- CORE SIMULATION PARAMETERS
    -- This section controls the fundamental mechanics of wear, tear, and breakdowns.
    -- ====================================================================================
    CORE = {
        -- The base amount of 'Service' level decrease per real hour of engine operation.
        -- 'Service' represents consumables like oil and filters. Higher value means faster service wear.
        BASE_SERVICE_WEAR = 0.1, -- (0.1 = 10% wear per hour at base rate)

        -- The base amount of 'Condition' level decrease per real hour of engine operation.
        -- 'Condition' represents the physical health of the vehicle's components.
        -- Higher value means faster condition degradation.
        BASE_CONDITION_WEAR = 0.01, -- (0.01 = 1% wear per hour at base rate)

        DOWNTIME_MULTIPLIER = 0.05,

        MOTOR_IDLING_MULTIPLIER = 0.5,
        MOTOR_IDLING_THRESHOLD = 0.3,
        -- --- Wear Multipliers (these add to the base wear rate) ---

        -- The maximum penalty applied to CONDITION wear when the Service level is very low (e.g., 0%).
        -- A value of 4.0 means condition can degrade up to 4x faster if service is neglected.
        SERVICE_EXPIRED_MAX_MULTIPLIER = 4.0,
        -- The Service level (from 1.0 to 0.0) below which the 'SERVICE_EXPIRED' penalty starts to apply.
        SERVICE_EXPIRED_THRESHOLD = 0.66, -- (Penalty starts when service is below 66%)

        -- The maximum penalty applied to CONDITION wear when the motor is under heavy load.
        MOTOR_OVERLOADED_MAX_MULTIPLIER = 1.0, -- (up to 1x extra wear)
        -- The engine load percentage (from 0.0 to 1.0) above which the 'MOTOR_OVERLOADED' penalty applies.
        MOTOR_OVERLOADED_THRESHOLD = 0.8, -- (Penalty starts when engine load is above 80%)

        -- The maximum penalty for operating the engine under load while it's cold.
        COLD_MOTOR_MAX_MULTIPLIER = 10.0, -- (up to 10x extra wear)
        -- The engine temperature in Celsius below which it is considered "cold" and the penalty applies.
        COLD_MOTOR_THRESHOLD = 70,

        -- The maximum penalty for operating the engine while it's overheating.
        OVERHEAT_MOTOR_MAX_MULTIPLIER = 30.0, -- (up to 30x extra wear)
        -- The engine temperature in Celsius above which the 'OVERHEAT_MOTOR' penalty applies.
        OVERHEAT_MOTOR_THRESHOLD = 95,

        -- The maximum penalty for operating the transmission while it's overheating.
        OVERHEAT_TRANSMISSION_MAX_MULTIPLIER = 30, -- (up to 30x extra wear)
        -- The transmission temperature in Celsius above which the 'OVERHEAT_TRANSMISSION' penalty applies.
        OVERHEAT_TRANSMISSION_THRESHOLD = 95,

        -- --- Breakdown Mechanics ---

        -- The base time in milliseconds it takes for a breakdown to progress from one stage to the next.
        -- This can be modified by individual breakdown definitions. 3,600,000ms = 1 hour.
        BASE_BREAKDOWN_PROGRESS_TIME = 3600000,

        CONCURRENT_BREAKDOWN_LIMIT_PER_VEHICLE = 8,

        -- Defines the probability of a new breakdown occurring.
        BREAKDOWN_PROBABILITY = {
            -- The min MTBF in minutes at 0% condition.
            MIN_MTBF = 60,
            -- The max MTBF in minutes at 100% condition
            MAX_MTBF = 600,

            DEGREE = 2.5,

            -- When a breakdown occurs, this defines the chance it will be "critical" (worst stage).
            -- Minimum chance of a critical outcome (at high vehicle condition).
            CRITICAL_MIN = 0.05, -- (5% chance)
            -- Maximum chance of a critical outcome (at 0% vehicle condition).
            CRITICAL_MAX = 0.33, -- (33% chance)
            -- Controls the curve of the critical chance. Higher value means low condition
            -- is much more likely to result in an immediate critical failure.
            CRITICAL_DEGREE = 5
        },
    },


    -- ====================================================================================
    -- WORKSHOP PARAMETERS
    -- Controls workshop operating hours, which affects maintenance/repair completion times.
    -- ====================================================================================
    WORKSHOP = {
        -- The hour of the day (0-23) when the workshop opens. Repairs will not progress before this time.
        OPEN_HOUR = 8,  -- (8 AM)
        -- The hour of the day (0-23) when the workshop closes. Repairs will pause at this time.
        CLOSE_HOUR = 19, -- (7 PM)
    },


    -- ====================================================================================
    -- MAINTENANCE & REPAIR PARAMETERS
    -- Controls the time and cost of all service types.
    -- ====================================================================================
    MAINTENANCE = {
        -- The base time in milliseconds required to perform an Inspection.
        INSPECTION_TIME = 3600000, -- (1 GAME hour)
        -- The base time in milliseconds required to perform a full Maintenance (Service).
        MAINTENANCE_TIME = 14400000, -- (4 GAME hours)
        -- The base time in milliseconds required to repair a SINGLE breakdown. This is multiplied by the number of selected breakdowns.
        REPAIR_TIME = 14400000, -- (4 GAME hours per breakdown)
        -- The base time in milliseconds required to perform a complete Overhaul.
        OVERHAUL_TIME = 43200000, -- (12 GAME hours)

        OVERHAUL_MIN_CONDITION_RESTORE = 0.5,
        OVERHAUL_MAX_CONDITION_RESTORE = 0.8,

        AFTERMARKETS_PARTS_BREAKDOWN_CHANCE = 0.33,
        AFTERMARKETS_PARTS_BREAKDOWN_DURATION = 18000000,
        -- These are global price multipliers. 1.0 is default. 2.0 would double the price of that service.
        -- The final price is calculated based on vehicle price, age, and brand maintainability.
        MAINTENANCE_PRICE_MULTIPLIER = 1.0,
        MAINTENANCE_DURATION_MULTIPLIER = 1.0
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
        MAX_DIRT_INFLUENCE = 0.25,
        
        -- The time constant for the low-pass filter on the temperature gauge.
        -- Higher value means the needle on the dashboard will move more slowly and smoothly,
        -- filtering out rapid temperature fluctuations.
        TAU = 5000,

        -- --- Engine-Specific Thermal ---

        -- The rate of heat generated by the engine at maximum load.
        ENGINE_MAX_HEAT = 1.1,
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
        PID_KP = 0.4,
        -- Integral gain: Corrects for small, persistent errors over time to reach the target temperature.
        PID_KI = 0.02,
        -- Derivative gain: Dampens the reaction to prevent overshooting the target temperature.
        PID_KD = 1.8,
        -- A safety limit to prevent the Integral term from growing too large ("integral windup").
        PID_MAX_INTEGRAL = 200
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
        -- Parameter 1: Reliability Multiplier
        --  - This value affects the rate of Condition wear.
        --  - > 1.0: The vehicle is more reliable. Wear rate is DIVIDED by this number, causing slower degradation.
        --           Example: 1.20 means the vehicle is more robust and wears 16.7% slower than standard.
        --  - < 1.0: The vehicle is less reliable. Wear rate is DIVIDED by this number, causing faster degradation.
        --           Example: 0.90 means the vehicle is less robust and wears 11.1% faster than standard.
        --
        -- Parameter 2: Maintainability Multiplier (Repair Cost Factor)
        --  - This value affects the final cost of all maintenance, repair, and overhaul actions.
        --  - > 1.0: The vehicle is easier/cheaper to maintain. Final costs are DIVIDED by this number, making them LOWER.
        --           Example: 1.30 (for Zetor) means repairs are significantly cheaper.
        --  - < 1.0: The vehicle is more complex or has expensive parts. Final costs are DIVIDED by this number, making them HIGHER.
        --           Example: 0.85 (for Fendt) means repairs are more expensive.

        -- Premium, highly reliable, but expensive to repair brands
        FENDT           = {1.20, 0.85},
        JOHNDEERE       = {1.20, 0.90},
        VOLVO           = {1.20, 0.95},
        KOMATSU         = {1.20, 1.00},
        PONSSE          = {1.20, 0.95},
        ROTTNE          = {1.20, 0.95},
        CATERPILLAR     = {1.20, 0.85},
        KENWORTH        = {1.15, 0.90},
        PETERBILT       = {1.15, 0.90},
        SCHLUETER       = {1.15, 0.95}, 

        -- High-quality, reliable brands with varying repair costs
        CLAAS           = {1.15, 0.95},
        ROPA            = {1.15, 0.90},
        HOLMER          = {1.15, 0.90},
        MACK            = {1.15, 1.05},
        KRONE           = {1.10, 1.00},
        KUBOTA          = {1.10, 1.00},
        MAN             = {1.10, 0.95},
        CHALLENGER      = {1.10, 0.90},
        AGCO            = {1.10, 0.90},
        MERCEDES        = {1.10, 0.90},
        KRAMER          = {1.10, 0.95},
        
        -- Standard, baseline brands representing the industry average
        LINDNER         = {1.05, 1.00},
        VALTRA          = {1.05, 1.10},
        GMC             = {1.05, 1.05},
        CASEIH          = {1.00, 1.00},
        NEWHOLLAND      = {1.00, 1.00},
        SDF             = {1.00, 1.00},
        MASSEYFERGUSON  = {1.00, 1.05},
        JCB             = {1.00, 0.95},
        DEUTZFAHR       = {1.00, 1.00},
        STEYR           = {1.00, 0.95},
        VERSATILE       = {1.00, 1.15},
        INTERNATIONAL   = {1.00, 1.15},
        FORD            = {1.00, 1.10},
        RENAULT         = {1.00, 1.05},
        INTERNATIONALHARVESTER   = {1.00, 1.15},
        LANDROVER       = {0.95, 0.95},
        
        -- Budget or older brands; less reliable but generally cheaper to maintain
        ZETOR           = {0.90, 1.30},
        FIAT            = {0.90, 1.00},
        LANDINI         = {0.90, 1.00},
        SAME            = {0.90, 1.00},
        MCCORMICK       = {0.90, 1.00},
        ARMATRAC        = {0.90, 1.05},
        MAHINDRA        = {0.90, 1.10},
        PTZKIROWEC      = {0.90, 1.20},
        MTZ             = {0.85, 1.40},
        STARA           = {0.85, 0.95},
        SKODA           = {0.85, 1.00},
        GAZ             = {0.85, 1.30},
        MAZ             = {0.85, 1.25},
        BUEHRER         = {0.80, 1.25},
        PORSCHEDIESEL   = {0.75, 1.20},
        LTZ             = {0.80, 1.35},
        OLIVER          = {0.85, 1.20}, 
        ALLISCHALMERS   = {0.85, 1.20},
        
        -- Generic / Mod brands        
        LIZARD          = {0.90, 1.00},
        GIANTS          = {1.00, 1.00},
        NONE            = {1.00, 1.00}
    }      
}

ADS_Config.savegameFile = "advancedDamageSystem.xml"

function ADS_Config.saveToXMLFile()
    if g_currentMission.missionInfo == nil or g_currentMission.missionInfo.savegameDirectory == nil then
        return false
    end

    local xmlFileName = g_currentMission.missionInfo.savegameDirectory .. "/".. ADS_Config.savegameFile
    local xmlFile = createXMLFile("advancedDamageSystem", xmlFileName, "advancedDamageSystem")

    if xmlFile == nil then
        return false     
    end

    setXMLFloat(xmlFile, "advancedDamageSystem.baseServiceWear", ADS_Config.CORE.BASE_SERVICE_WEAR);
    setXMLFloat(xmlFile, "advancedDamageSystem.baseCondtitionWear", ADS_Config.CORE.BASE_CONDITION_WEAR);
    setXMLFloat(xmlFile, "advancedDamageSystem.breakdownProbabolityMin", ADS_Config.CORE.BREAKDOWN_PROBABILITY.MAX_MTBF);
    setXMLFloat(xmlFile, "advancedDamageSystem.maintenancePriceMultiplier", ADS_Config.MAINTENANCE.MAINTENANCE_PRICE_MULTIPLIER);
    setXMLFloat(xmlFile, "advancedDamageSystem.maintenanceDurationMultiplier", ADS_Config.MAINTENANCE.MAINTENANCE_DURATION_MULTIPLIER);
    setXMLFloat(xmlFile, "advancedDamageSystem.workshopOpenHour", ADS_Config.WORKSHOP.OPEN_HOUR);
    setXMLFloat(xmlFile, "advancedDamageSystem.workshopCloseHour", ADS_Config.WORKSHOP.CLOSE_HOUR);

	saveXMLFile(xmlFile);
	delete(xmlFile);
end

function ADS_Config.loadFromXMLFile(mission)
    if mission == nil or mission.missionInfo == nil or mission.missionInfo.savegameDirectory == nil then
        return
    end

    local xmlFileName = mission.missionInfo.savegameDirectory .. "/" .. ADS_Config.savegameFile

    if not fileExists(xmlFileName) then
        print("ADS_Config: No config file found. Using default settings.")
        return
    end

    local xmlFile = loadXMLFile('advancedDamageSystem', xmlFileName);
    
    if xmlFile == nil then
        print("ADS_Config: Failed to load config file.")
        return
    end

    print("ADS_Config: Loading settings from " .. xmlFileName)

    
    local serviceWear = getXMLFloat(xmlFile, "advancedDamageSystem.baseServiceWear")
    if serviceWear ~= nil then ADS_Config.CORE.BASE_SERVICE_WEAR = serviceWear end

    local conditionWear = getXMLFloat(xmlFile, "advancedDamageSystem.baseCondtitionWear")
    if conditionWear ~= nil then ADS_Config.CORE.BASE_CONDITION_WEAR = conditionWear end

    local breakdownProb = getXMLFloat(xmlFile, "advancedDamageSystem.breakdownProbabolityMin")
    if breakdownProb ~= nil then ADS_Config.CORE.BREAKDOWN_PROBABILITY.MAX_MTBF = breakdownProb end

    local priceMult = getXMLFloat(xmlFile, "advancedDamageSystem.maintenancePriceMultiplier")
    if priceMult ~= nil then ADS_Config.MAINTENANCE.MAINTENANCE_PRICE_MULTIPLIER = priceMult end

    local durationMult = getXMLFloat(xmlFile, "advancedDamageSystem.maintenanceDurationMultiplier")
    if durationMult ~= nil then ADS_Config.MAINTENANCE.MAINTENANCE_DURATION_MULTIPLIER = durationMult end

    local openHour = getXMLFloat(xmlFile, "advancedDamageSystem.workshopOpenHour")
    if openHour ~= nil then ADS_Config.WORKSHOP.OPEN_HOUR = openHour end

    local closeHour = getXMLFloat(xmlFile, "advancedDamageSystem.workshopCloseHour")
    if closeHour ~= nil then ADS_Config.WORKSHOP.CLOSE_HOUR = closeHour end
    
    delete(xmlFile)
end


Mission00.loadMission00Finished = Utils.appendedFunction(
    Mission00.loadMission00Finished, ADS_Config.loadFromXMLFile)

FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(
    FSCareerMissionInfo.saveToXMLFile, ADS_Config.saveToXMLFile)