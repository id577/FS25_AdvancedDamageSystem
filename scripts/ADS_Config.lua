
ADS_Config = {
    -- Enables or disables extensive debug logging in the console.
    -- When true, the mod will print detailed information about its calculations,
    -- such as wear rates, breakdown checks, and temperature changes.
    -- Set to false for normal gameplay to avoid performance impact and console spam.
    VER = 123,

    DEBUG = false,

    -- How often quick, interactive effects are updated, in milliseconds.
    -- This controls things that need to be very responsive, like flickering lights,
    -- engine stalls, or gear shift failures. A lower value provides a smoother
    -- and more immediate experience for these effects.
    --
    -- WARNING: It is strongly recommended to keep this value low (e.g., under 200ms).
    -- High values can cause visual glitches (like lights staying off for too long)
    -- or make gameplay effects feel unresponsive and delayed.
    ON_UPDATE_DELAY = 100, -- (100ms = 10 times per second)

    UPDATE_VEHICLE_STATE_DELAY_ONE = 50,
    UPDATE_VEHICLE_STATE_DELAY_TWO = 200,
    UPDATE_VEHICLE_STATE_DELAY_THREE = 500,
    
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
        DEFAULT_SERVICE_WEAR = 0.1,
        DEFAULT_SYSTEM_WEAR = 0.01,
        BASE_SERVICE_WEAR = 0.1,
        BASE_SYSTEMS_WEAR = 0.01,

        DOWNTIME_MULTIPLIER = 0.05,
        UNDER_ROOF_DOWNTIME_MULTIPLIER = 0.0,
        RAIN_FACTOR = 1.1,
        HALL_FACTOR = 1.3,
        SNOW_FACTOR = 1.1,
        BREAKDOWN_PRESENCE_FACTOR = 1.0,

        SERVICE_EXPIRED_THRESHOLD = 0.5,

        SYSTEM_WEIGHTS = {
            engine=0.22, 
            transmission=0.16, 
            hydraulics=0.12, 
            cooling=0.12, 
            electrical=0.10, 
            chassis=0.10, 
            workProcess=0.10,
            fuel=0.08
        },

        PERSISTENT_WEAR_RATE_LIMIT = 10.0,
        IMPULSE_WEAR_RATE_LIMIT = 500.0,
        AVG_STRESS_WARNING_THRESHOLD = 0.2,
        AVG_STRESS_CRITICAL_THRESHOLD = 0.4,

        SYSTEM_STRESS_GLOBAL_MULTIPLIER = 1.0,
        SYSTEM_STRESS_ACCUMULATION_MULTIPLIERS = {
            engine=10.0, 
            transmission=10.0, 
            hydraulics=10.0, 
            cooling=10.0, 
            electrical=10.0, 
            chassis=10.0, 
            workProcess=20.0, 
            fuel=10.0
        },

        ENGINE_FACTOR_DATA = {
            MOTOR_IDLING_MULTIPLIER = 0.5,
            SERVICE_EXPIRED_MULTIPLIER = 16.0,
            MOTOR_IDLING_THRESHOLD = 0.3,
            MOTOR_OVERLOADED_MULTIPLIER = 8.0, 
            MOTOR_OVERLOADED_THRESHOLD = 0.90,
            COLD_MOTOR_RPM_THRESHOLD = 0.5,
            COLD_MOTOR_TEMP_THRESHOLD = 50,         
            COLD_MOTOR_MULTIPLIER = 180.0,
            OVERHEAT_MOTOR_MULTIPLIER = 360.0, 
            OVERHEAT_MOTOR_THRESHOLD = 95,
            AIR_INTAKE_CLOGGING_MULTIPLIER = 1.0,
            AIR_INTAKE_CLOGGING_THRESHOLD = 0.5
        },

        TRANSMISSION_FACTOR_DATA = {
            TRANSMISSION_IDLING_MULTIPLIER = 0.2,
            SERVICE_EXPIRED_MULTIPLIER = 9.0,
            PULL_OVERLOAD_MULTIPLIER = 8.0,    
            PULL_OVERLOAD_THRESHOLD = 0.85,
            PULL_OVERLOAD_TIMER_THRESHOLD = 60,
            LUGGING_MULTIPLIER = 32.0,       
            LUGGING_RPM_THRESHOLD = 0.8,
            LUGGING_MOTORLOAD_THRESHOLD = 0.80,
            WHEEL_SLIP_MULTIPLIER = 20.0,        
            WHEEL_SLIP_THRESHOLD = 0.1,
            HEAVY_TRAILER_MULTIPLIER = 12.0,
            HEAVY_TRAILER_THRESHOLD = 2.2,
            COLD_TRANSMISSION_MULTIPLIER = 180.0,
            COLD_TRANSMISSION_THRESHOLD = 45,
            OVERHEAT_TRANSMISSION_MAX_MULTIPLIER = 360.0,
            OVERHEAT_TRANSMISSION_THRESHOLD = 95,
        },

        HYDRAULICS_FACTOR_DATA = {
            HYDRAULICS_IDLING_MULTIPLIER = 0.2,
            SERVICE_EXPIRED_MULTIPLIER = 6.0,
            HEAVY_LIFT_FACTOR_MULTIPLIER = 18.0,
            HEAVY_LIFT_FACTOR_THRESHOLD = 0.3,
            OPERATING_FACTOR_MULTIPLIER = 4.0,
            COLD_OIL_MULTIPLIER = 180.0,
            COLD_OIL_THRESHOLD = 30,
            PTO_OPERATING_FACTOR = 0.0,
            PTO_SHARP_ANGLE_FACTOR_MULTIPLIER = 80.0,
            PTO_SHARP_ANGLE_FACTOR_THRESHOLD = 20.0
        },

        COOLING_FACTOR_DATA = {
            COOLING_IDLING_MULTIPLIER = 0.2,
            SERVICE_EXPIRED_MULTIPLIER = 9.0,
            HIGH_COOLING_FACTOR_MULTIPLIER = 4.0,
            HIGH_COOLING_FACTOR_THRESHOLD = 0.9,
            OVERHEAT_FACTOR_MULTIPLIER = 120.0,
            OVERHEAT_FACTOR_THRESHOLD = 95,
            COLD_SHOCK_FACTOR_MULTIPLIER = 120.0,
            COLD_SHOCK_FACTOR_THRESHOLD = 50
        },

        ELECTRICAL_FACTOR_DATA = {
            SERVICE_EXPIRED_MULTIPLIER = 4.0,
            CRANKING_STRESS_MULTIPLIER = 12.0,
            RAIN_FACTOR_MULTIPLIER = 1.5,
            SNOW_FACTOR_MULTIPLIER = 1.0,
            HALL_FACTOR_MULTIPLIER = 2.0,
            OVERHEAT_FACTOR_MULTIPLIER = 120.0,
            OVERHEAT_FACTOR_THRESHOLD = 95,
            LIGHTS_FACTOR_MULTIPLIER = 0.4
        },

        CHASSIS_FACTOR_DATA = {
            SERVICE_EXPIRED_MULTIPLIER = 9.0,
            CHASSIS_IDLING_MULTIPLIER = 0.2,
            VIB_FACTOR_THRESHOLD = 0.08,
            VIB_FACTOR_MAX_SIGNAL = 0.36,
            VIB_FACTOR_MULTIPLIER = 48.0,
            VIB_FIELD_MULTIPLIER = 2.0,
            STEER_LOAD_FACTOR_MULTIPLIER = 32.0,
            STEER_LOAD_SPEED_THRESHOLD = 3.0,
            STEER_LOAD_STEER_THRESHOLD = 0.2,
            STEER_LOAD_CHANGE_THRESHOLD = 0.08,
            BRAKE_MASS_FACTOR_MULTIPLIER = 48.0,
            BRAKE_MASS_RATIO_THRESHOLD = 1.0,
            BRAKE_MASS_RATIO_MAX = 5.0,
            BRAKE_MASS_SPEED_THRESHOLD = 2.0,
            BRAKE_PEDAL_THRESHOLD = 0.15,
        },

        WORKPROCESS_FACTOR_DATA = {
            SERVICE_EXPIRED_MULTIPLIER = 3.0,
            WORKPROCESSS_IDLING_MULTIPLIER = 0.2,
            WET_CROP_FACTOR_MULTIPLIER = 4.0,
            LUBRICATION_FACTOR_MULTIPLIER = 32.0
        },

        FUEL_FACTOR_DATA = {
            SERVICE_EXPIRED_MULTIPLIER = 4.0,
            LOW_FUEL_FACTOR_MULTIPLIER = 18.0,
            LOW_FUEL_THRESHOLD = 0.2,
            COLD_FUEL_THRESHOLD = 20.0,
            COLD_FUEL_FACTOR_MULTIPLIER = 120,
            IDLE_DEPOSIT_FACTOR_MULTIPLIER = 2.0,
            IDLE_DEPOSIT_FACTOR_TIMER_THRESHOLD = 60,
            IDLE_DEPOSIT_FACTOR_MAX_TIMER = 600,
            HIGH_PRESSURE_FACTOR_MULTIPLIER = 12.0,
            HIGH_PRESSURE_FACTOR_THRESHOLD = 0.8,
        },

        STRESS_COOLDOWN = 0.5,
        CONDITION_EFFECTIVE_FLOOR = 0.10,
        REPEAT_BREAKDOWN_TIME = 1.3 * 3600000,
        USED_VEHICLE_BREAKDOWN_PRESENCE_CHANGE_MUL = 0.33,
        USED_VEHICLE_BREAKDOWN_PRESENCE_CHANGE_MAX = 0.66,

        CONCURRENT_BREAKDOWN_LIMIT_PER_VEHICLE = 15,
        ENABLE_WARNING_MESSAGES = true,
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
        GENERAL_WEAR_ENABLED = true,
        GENERAL_WEAR_EARLY_STAGE_THRESHOLD = 0.66,
        GENERAL_WEAR_LATE_STAGE_THRESHOLD = 0.33,

        RELIABILITY_YEAR_FACTOR = 0.01,
        RELIABILITY_YEAR_FACTOR_THRESHOLD = 2000,

        BASE_BREAKDOWN_PROGRESS_TIME = 1 * 3600000,
        BREAKDOWN_PROBABILITIES = {
            STRESS_THRESHOLD = 0.5,
            MIN_MTBF = 30,
            MAX_MTBF = 5200,
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

        MOBILE_WORKSHOP_RESTRICTIONS_ENABLED = true,
        MOBILE_WORKSHOP_SERVICES_BY_MAINTAINABILITY = {
            INSPECTION = {
                [1] = 0.0,  STANDARD = 0.0,
                [2] = 0.0,  VISUAL   = 0.0,
                [3] = 99.0, COMPLETE = 99.0,
            },

            MAINTENANCE = {
                [1] = 1.0,  STANDARD = 1.1,
                [2] = 0.9,  MINIMAL  = 0.9,
                [3] = 1.2,  EXTENDED = 1.2,
                [4] = 1.4,  PREVENTIVE = 1.4,
            },

            REPAIR = {
                [1] = 0.0,  LOW    = 0.0,
                [2] = 1.1,  MEDIUM = 1.1,
                [3] = 99.0, HIGH   = 99.0,
            },

            OVERHAUL = {
                [1] = 99.0,  STANDARD = 99.0,
                [2] = 99.0,  PARTIAL  = 99.0,
                [3] = 99.0,  FULL     = 99.0,
            },
        }
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

        INSPECTION_TIME = 1 * 3600000,
        INSPECTION_TIME_MULTIPLIERS = {
            [1] = 1.0,  STANDARD = 1.0,
            [2] = 0.1,  VISUAL   = 0.1,
            [3] = 4.0,  COMPLETE = 4.0,
        },
        MAINTENANCE_TIME = 6 * 3600000,
        MAINTENANCE_TIME_MULTIPLIERS = {
            [1] = 1.0,  STANDARD = 1.0,
            [2] = 0.25, MINIMAL  = 0.25,
            [3] = 1.5,  EXTENDED = 1.5,
            [4] = 2.0,  PREVENTIVE = 2.0,
        },
        REPAIR_TIME = 4 * 3600000,
        REPAIR_TIME_MULTIPLIERS = {
            [1] = 0.2, LOW    = 0.2,
            [2] = 1.0, MEDIUM = 1.0,
            [3] = 2.0, HIGH = 2.0,
        },
        OVERHAUL_TIME = 24 * 3600000,
        OVERHAUL_TIME_MULTIPLIERS = {
            [1] = 1.0, STANDARD = 1.0,
            [2] = 1.2, PARTIAL  = 1.2,
            [3] = 2.0, FULL     = 2.0,
        },

        REPAINT_TIME = 8 * 3600000,

        INSPECTION_DETECTION_CHANCE_MULTIPLIERS = {
            [1] = 1.0,  STANDARD = 1.0,
            [2] = 0.8,  VISUAL   = 0.8,
            [3] = 1.0,  COMPLETE = 1.0,
        },

        MAINTENANCE_SERVICE_RESTORE_MULTIPLIERS = {
            [1] = 1.0,  STANDARD = 1.0,
            [2] = 0.75, MINIMAL  = 0.75,
            [3] = 1.2,  EXTENDED = 1.2,
            [4] = 1.0,  PREVENTIVE = 1.0,
        },

        MAINTENANCE_PREVENTIVE_STRESS_REMOVE_MULTIPLIER = 0.6,
        MAINTENANCE_PREVENTIVE_SYSTEMS_COUNT = 3,

        REPAIR_REMAINING_STRESS_RATIO = {
            [2] = 0.5,  MEDIUM = 0.5,
            [3] = 0.0,  HIGH = 0.0,
        },

        OVERHAUL_MIN_CONDITION_RESTORE_MULTIPLIERS = {
            [1] = 0.61, STANDARD = 0.61,
            [2] = 0.61, PARTIAL  = 0.61,
            [3] = 0.81, FULL     = 0.81,
        },
        OVERHAUL_MAX_CONDITION_RESTORE_MULTIPLIERS = {
            [1] = 0.79, STANDARD = 0.79,
            [2] = 0.79, PARTIAL  = 0.79,
            [3] = 0.99, FULL     = 0.99,
        },

        RE_OVERHAUL_FACTOR = 0.1,

        PARTS_BREAKDOWN_CHANCES = {
            [1] = 0.1,  OEM         = 0.1,
            [2] = 0.5,  USED        = 0.5,
            [3] = 0.33, AFTERMARKET = 0.33,
            [4] = 0.0,  PREMIUM     = 0.0,
        },


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
            [4] = 4.0,  PREVENTIVE = 4.0,
        },

        REPAIR_PRICE_MULTIPLIERS = {
            [1] = 0.2, LOW    = 0.2,
            [2] = 1.0, MEDIUM = 1.0,
            [3] = 2.0,  HIGH = 2.0,
        },
        OVERHAUL_PRICE_MULTIPLIERS = {
            [1] = 0.5, STANDARD = 0.5,
            [2] = 0.6, PARTIAL  = 0.6,
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
        -- 0.20 means a fully dirty vehicle's radiator is 20% less effective.
        MAX_DIRT_INFLUENCE = 0.20,
        
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
        TRANS_THERMOSTAT_MIN_TEMP = 65,
        -- The base cooling rate from the transmission's radiator when its thermostat is closed.
        TRANS_RADIATOR_MIN_COOLING = 0.0005,
        -- The maximum cooling rate from the transmission's radiator when its thermostat is open.
        TRANS_RADIATOR_MAX_COOLING = 0.005,

        -- --- PID Controller for Thermostat ---
        -- These values control how intelligently the thermostat opens and closes to maintain a stable temperature.
        -- Tweak these only if you are familiar with PID controllers.
        TRANS_PID_TARGET_TEMP  = 75,
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

    FIELD_CARE = {
        CLOGGING_SPEED = 1.0,
        CLEANING_SPEED = 0.05,
        AIR_INTAKE_BREAKDOWN_THRESHOLD = 0.5,
        FIELD_INSPECTION_DURATION = 6000,
        LUBRICATION_REDUCE_PER_DAY = 0.2,
        RAYCAST_DISTANCE = 2.0,
        JUMPER_CABLES_MAX_CONNECTION_DISTANCE = 12.0,
    },

    ELECTRICAL = {
        BATTERY_NOMINAL_CAPACITY = 150,
        BATTERY_USABLE_CAPACITY_FACTOR = 0.1,
        AMBIENT_DEFAULT_C = 15,
        BATTERY_THERMAL_TAU_S = 600,
        BATTERY_THERMAL_CAPACITY_J_PER_K = 2400,
        ENGINE_BAY_COUPLING = 0.30,
        RINT_REF_OHM = 0.005,
        BATTERY_HEALTH_RINT_MAX_MULT = 3.0,
        OCV_EMPTY_V = 11.7,
        OCV_FULL_V = 12.7,
        BATTERY_LOAD_DROP_MIN_V = 12.2,
        BATTERY_CRANK_CURRENT_A = 250,
        BATTERY_CHARGE_RISE_PER_20A_V = 0.18,
        BATTERY_CHARGE_RISE_MAX_V = 1.6,
        BATTERY_CHARGE_TARGET_MAX_V = 14.4,
        BATTERY_CHARGE_IR_SCALE = 0.0,
        BATTERY_TERMINAL_MIN_V = 8.5,
        BATTERY_TERMINAL_MAX_V = 14.8,
        CHARGE_ACCEPT_TEMP_MIN_C = -15,
        CHARGE_ACCEPT_TEMP_MAX_C = 25,
        CHARGE_TAPER_SOC_START = 0.80,
        CHARGE_TAPER_SOC_END = 0.98,
        BATTERY_HEALTH_ACCEPTANCE_MIN = 0.35,
        ALT_MAX_OUTPUT = 100,
        ALT_IDLE_FACTOR = 0.30,
        ALT_RPM_CURVE = {
            {0.00, 0.30},
            {0.25, 0.55},
            {0.50, 0.80},
            {0.75, 0.95},
            {1.00, 1.00}
        },
        ALTERNATOR_REGULATED_VOLTAGE = 14.1, 
        ALTERNATOR_MIN_REGULATED_VOLTAGE = 13.6,
        SYSTEM_VOLTAGE_TAU_MS = 250,          
        BATTERY_VOLTAGE_TAU_MS = 300,      
        ALT_DEFICIT_SAG_PER_AMP = 0.045,
        ALT_HEALTH_REGULATION_THRESHOLD = 0.15,
        ALT_LOW_HEALTH_DEFICIT_MULT = 1.8,
        ALT_BATTERY_SUPPORT_GAIN = 0.45,
        ALT_SURPLUS_CHARGE_HEADROOM_V = 0.3,  
        MAX_SYSTEM_VOLTAGE = 14.4,
        MIN_SYSTEM_VOLTAGE = 9.0,
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
    if ADS_Config.DEBUG then
        local args = {...}
        for i = 1, #args do args[i] = tostring(args[i]) end
        print("[ADS_CFG] " .. table.concat(args, " "))
    end
end

-- ============================================================
-- SAVE
-- ============================================================
function ADS_Config.saveToXMLFile()
    if g_currentMission == nil or not g_currentMission:getIsServer() then
        return false
    end

    if g_currentMission.missionInfo == nil then
        log_dbg("SAVE ABORT - missionInfo is nil")
        return false
    end

    local savegameFolderPath = g_currentMission.missionInfo.savegameDirectory
    if savegameFolderPath == nil then
        savegameFolderPath = ('%ssavegame%d'):format(getUserProfileAppPath(), g_currentMission.missionInfo.savegameIndex)
    end

    local xmlFileName = savegameFolderPath .. "/" .. ADS_Config.savegameFile
    log_dbg("SAVE to:", xmlFileName)

    local xmlFile = createXMLFile("advancedDamageSystem", xmlFileName, "advancedDamageSystem")
    if xmlFile == nil or xmlFile == 0 then
        log_dbg("SAVE ERROR - createXMLFile returned", tostring(xmlFile))
        return false
    end

    local root = "advancedDamageSystem"

    -- Version
    setXMLFloat(xmlFile, root .. ".VER", ADS_Config.VER)

    -- CORE
    setXMLFloat(xmlFile, root .. ".BASE_SERVICE_WEAR",      ADS_Config.CORE.BASE_SERVICE_WEAR)
    setXMLFloat(xmlFile, root .. ".BASE_SYSTEMS_WEAR",      ADS_Config.CORE.BASE_SYSTEMS_WEAR)
    setXMLFloat(xmlFile, root .. ".DOWNTIME_MULTIPLIER",    ADS_Config.CORE.DOWNTIME_MULTIPLIER)
    setXMLFloat(xmlFile, root .. ".SYSTEM_STRESS_GLOBAL_MULTIPLIER", ADS_Config.CORE.SYSTEM_STRESS_GLOBAL_MULTIPLIER)
    setXMLBool (xmlFile, root .. ".GENERAL_WEAR_ENABLED",   ADS_Config.CORE.GENERAL_WEAR_ENABLED)
    setXMLBool (xmlFile, root .. ".ENABLE_WARNING_MESSAGES", ADS_Config.CORE.ENABLE_WARNING_MESSAGES)
    setXMLBool (xmlFile, root .. ".AI_OVERLOAD_CONTROL",    ADS_Config.CORE.AI_OVERLOAD_AND_OVERHEAT_CONTROL)

    -- MAINTENANCE
    setXMLBool (xmlFile, root .. ".INSTANT_INSPECTION",     ADS_Config.MAINTENANCE.INSTANT_INSPECTION)
    setXMLBool (xmlFile, root .. ".PARK_VEHICLE",           ADS_Config.MAINTENANCE.PARK_VEHICLE)
    setXMLBool (xmlFile, root .. ".WARRANTY_ENABLED",       ADS_Config.MAINTENANCE.WARRANTY_ENABLED)
    setXMLFloat(xmlFile, root .. ".PRICE_MULTIPLIER",       ADS_Config.MAINTENANCE.GLOBAL_SERVICE_PRICE_MULTIPLIER)
    setXMLFloat(xmlFile, root .. ".TIME_MULTIPLIER",        ADS_Config.MAINTENANCE.GLOBAL_SERVICE_TIME_MULTIPLIER)

    -- WORKSHOP
    setXMLBool (xmlFile, root .. ".ALWAYS_AVAILABLE",       ADS_Config.WORKSHOP.ALWAYS_AVAILABLE)
    setXMLBool (xmlFile, root .. ".MOBILE_WORKSHOP_RESTRICTIONS_ENABLED", ADS_Config.WORKSHOP.MOBILE_WORKSHOP_RESTRICTIONS_ENABLED)
    setXMLFloat(xmlFile, root .. ".OPEN_HOUR",              ADS_Config.WORKSHOP.OPEN_HOUR)
    setXMLFloat(xmlFile, root .. ".CLOSE_HOUR",             ADS_Config.WORKSHOP.CLOSE_HOUR)

    -- THERMAL
    setXMLFloat(xmlFile, root .. ".ENGINE_MAX_HEAT",        ADS_Config.THERMAL.ENGINE_MAX_HEAT)
    setXMLFloat(xmlFile, root .. ".TRANS_MAX_HEAT",         ADS_Config.THERMAL.TRANS_MAX_HEAT)
    setXMLFloat(xmlFile, root .. ".MAX_DIRT_INFLUENCE",     ADS_Config.THERMAL.MAX_DIRT_INFLUENCE)

    -- ELECTRICAL
    setXMLFloat(xmlFile, root .. ".BATTERY_USABLE_CAPACITY_FACTOR", ADS_Config.ELECTRICAL.BATTERY_USABLE_CAPACITY_FACTOR)

    -- FIELD CARE
    setXMLFloat(xmlFile, root .. ".CLOGGING_SPEED",         ADS_Config.FIELD_CARE.CLOGGING_SPEED)
    setXMLFloat(xmlFile, root .. ".RAYCAST_DISTANCE",        ADS_Config.FIELD_CARE.RAYCAST_DISTANCE)
    setXMLFloat(xmlFile, root .. ".JUMPER_CABLES_MAX_CONNECTION_DISTANCE", ADS_Config.FIELD_CARE.JUMPER_CABLES_MAX_CONNECTION_DISTANCE)

    -- DEBUG
    setXMLBool (xmlFile, root .. ".DEBUG_MODE",             ADS_Config.DEBUG)

    saveXMLFile(xmlFile)
    delete(xmlFile)
    log_dbg("SAVE OK - BASE_SERVICE_WEAR=", tostring(ADS_Config.CORE.BASE_SERVICE_WEAR))
    return true
end

-- ============================================================
-- LOAD
-- ============================================================
function ADS_Config.loadFromXMLFile()
    if ADS_Config._loaded then
        log_dbg("LOAD SKIP - already loaded")
        return
    end

    log_dbg("LOAD - loadFromXMLFile() called")

    if g_currentMission == nil then
        log_dbg("LOAD SKIP - g_currentMission is nil")
        return
    end

    if g_currentMission.missionInfo == nil then
        log_dbg("LOAD SKIP - missionInfo is nil")
        return
    end

    local savegameFolderPath = g_currentMission.missionInfo.savegameDirectory
    if savegameFolderPath == nil then
        savegameFolderPath = ('%ssavegame%d'):format(getUserProfileAppPath(), g_currentMission.missionInfo.savegameIndex)
    end

    local xmlFileName = savegameFolderPath .. "/" .. ADS_Config.savegameFile
    log_dbg("LOAD from:", xmlFileName)

    if not fileExists(xmlFileName) then
        log_dbg("LOAD - file not found, using defaults")
        return
    end

    local xmlFile = loadXMLFile("advancedDamageSystem", xmlFileName)
    if xmlFile == nil or xmlFile == 0 then
        log_dbg("LOAD ERROR - loadXMLFile returned", tostring(xmlFile))
        return
    end

    local root = "advancedDamageSystem"
    local v

    local savedVersion = getXMLFloat(xmlFile, root .. ".VER")
    if savedVersion == nil then
        log_dbg("LOAD - no VER in file, using defaults")
        delete(xmlFile)
        return
    end
    log_dbg("LOAD - saved VER=", tostring(savedVersion), "current VER=", tostring(ADS_Config.VER))

    -- CORE
    v = getXMLFloat(xmlFile, root .. ".BASE_SERVICE_WEAR")
    if v ~= nil then ADS_Config.CORE.BASE_SERVICE_WEAR = v end

    v = getXMLFloat(xmlFile, root .. ".BASE_SYSTEMS_WEAR")
    if v ~= nil then ADS_Config.CORE.BASE_SYSTEMS_WEAR = v end

    v = getXMLFloat(xmlFile, root .. ".DOWNTIME_MULTIPLIER")
    if v ~= nil then ADS_Config.CORE.DOWNTIME_MULTIPLIER = v end

    v = getXMLFloat(xmlFile, root .. ".SYSTEM_STRESS_GLOBAL_MULTIPLIER")
    if v ~= nil then ADS_Config.CORE.SYSTEM_STRESS_GLOBAL_MULTIPLIER = v end

    v = getXMLBool(xmlFile, root .. ".GENERAL_WEAR_ENABLED")
    if v ~= nil then ADS_Config.CORE.GENERAL_WEAR_ENABLED = v end

    v = getXMLBool(xmlFile, root .. ".ENABLE_WARNING_MESSAGES")
    if v ~= nil then ADS_Config.CORE.ENABLE_WARNING_MESSAGES = v end

    v = getXMLBool(xmlFile, root .. ".AI_OVERLOAD_CONTROL")
    if v ~= nil then ADS_Config.CORE.AI_OVERLOAD_AND_OVERHEAT_CONTROL = v end

    -- MAINTENANCE
    v = getXMLBool(xmlFile, root .. ".INSTANT_INSPECTION")
    if v ~= nil then ADS_Config.MAINTENANCE.INSTANT_INSPECTION = v end

    v = getXMLBool(xmlFile, root .. ".PARK_VEHICLE")
    if v ~= nil then ADS_Config.MAINTENANCE.PARK_VEHICLE = v end

    v = getXMLBool(xmlFile, root .. ".WARRANTY_ENABLED")
    if v ~= nil then ADS_Config.MAINTENANCE.WARRANTY_ENABLED = v end

    v = getXMLFloat(xmlFile, root .. ".PRICE_MULTIPLIER")
    if v ~= nil then ADS_Config.MAINTENANCE.GLOBAL_SERVICE_PRICE_MULTIPLIER = v end

    v = getXMLFloat(xmlFile, root .. ".TIME_MULTIPLIER")
    if v ~= nil then ADS_Config.MAINTENANCE.GLOBAL_SERVICE_TIME_MULTIPLIER = v end

    -- WORKSHOP
    v = getXMLBool(xmlFile, root .. ".ALWAYS_AVAILABLE")
    if v ~= nil then ADS_Config.WORKSHOP.ALWAYS_AVAILABLE = v end

    v = getXMLBool(xmlFile, root .. ".MOBILE_WORKSHOP_RESTRICTIONS_ENABLED")
    if v ~= nil then ADS_Config.WORKSHOP.MOBILE_WORKSHOP_RESTRICTIONS_ENABLED = v end

    v = getXMLFloat(xmlFile, root .. ".OPEN_HOUR")
    if v ~= nil then ADS_Config.WORKSHOP.OPEN_HOUR = v end

    v = getXMLFloat(xmlFile, root .. ".CLOSE_HOUR")
    if v ~= nil then ADS_Config.WORKSHOP.CLOSE_HOUR = v end

    -- THERMAL
    v = getXMLFloat(xmlFile, root .. ".ENGINE_MAX_HEAT")
    if v ~= nil then ADS_Config.THERMAL.ENGINE_MAX_HEAT = v end

    v = getXMLFloat(xmlFile, root .. ".TRANS_MAX_HEAT")
    if v ~= nil then ADS_Config.THERMAL.TRANS_MAX_HEAT = v end

    v = getXMLFloat(xmlFile, root .. ".MAX_DIRT_INFLUENCE")
    if v ~= nil then ADS_Config.THERMAL.MAX_DIRT_INFLUENCE = v end

    -- ELECTRICAL
    v = getXMLFloat(xmlFile, root .. ".BATTERY_USABLE_CAPACITY_FACTOR")
    if v ~= nil then ADS_Config.ELECTRICAL.BATTERY_USABLE_CAPACITY_FACTOR = v end

    -- FIELD CARE
    v = getXMLFloat(xmlFile, root .. ".CLOGGING_SPEED")
    if v ~= nil then ADS_Config.FIELD_CARE.CLOGGING_SPEED = v end

    v = getXMLFloat(xmlFile, root .. ".RAYCAST_DISTANCE")
    if v ~= nil then
        ADS_Config.FIELD_CARE.RAYCAST_DISTANCE = v
    else
        v = getXMLFloat(xmlFile, root .. ".JUMPER_CABLES_RAYCAST_DISTANCE")
        if v ~= nil then ADS_Config.FIELD_CARE.RAYCAST_DISTANCE = v end
    end

    v = getXMLFloat(xmlFile, root .. ".JUMPER_CABLES_MAX_CONNECTION_DISTANCE")
    if v ~= nil then ADS_Config.FIELD_CARE.JUMPER_CABLES_MAX_CONNECTION_DISTANCE = v end

    -- DEBUG
    v = getXMLBool(xmlFile, root .. ".DEBUG_MODE")
    if v ~= nil then ADS_Config.DEBUG = v end

    delete(xmlFile)
    ADS_Config._loaded = true
    log_dbg("LOAD OK - BASE_SERVICE_WEAR=", tostring(ADS_Config.CORE.BASE_SERVICE_WEAR))
end
