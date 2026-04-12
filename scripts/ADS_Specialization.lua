-- ==========================================================
--                  ADVANCED DAMAGE SYSTEM
-- ==========================================================

AdvancedDamageSystem = {
    STATUS = {
        READY = 'ads_spec_state_ready',
        INSPECTION = 'ads_spec_state_inspection',
        MAINTENANCE = 'ads_spec_state_maintenance',
        REPAIR = 'ads_spec_state_repair',
        OVERHAUL = 'ads_spec_state_overhaul',
        BROKEN = 'ads_spec_state_broken'
    },

    STATES = {
        EXCELLENT = 'ads_spec_state_excellent',
        GOOD = 'ads_spec_state_good',
        NORMAL = 'ads_spec_state_normal',
        BAD = 'ads_spec_state_bad',
        TERRIBLE = 'ads_spec_state_terrible',
        UNKNOWN = 'ads_spec_state_unknown',
        OPTIMAL = "ads_spec_state_optimal",
        RECOMMENDED = "ads_spec_state_recommended",
        REQUIRED = "ads_spec_state_required",
        OVERDUE = "ads_spec_state_overdue",
        LEGENDARY = "ads_spec_state_legendary",
        PREMIUM = "ads_spec_state_premium",
        STANDART = "ads_spec_state_standart",
        BUDGET = "ads_spec_state_budget",
        LOW = "ads_spec_state_low",
        AVERAGE = "ads_spec_state_average",
        HIGH = "ads_spec_state_high",
        WORKHORSE = "ads_spec_state_workhorse"
    },

    SYSTEMS = {
        ENGINE = "ads_spec_system_engine",
        TRANSMISSION = "ads_spec_system_transmission",
        HYDRAULICS = "ads_spec_system_hydraulics",
        COOLING = "ads_spec_system_cooling",
        ELECTRICAL = "ads_spec_system_electrical",
        CHASSIS = "ads_spec_system_chassis",
        WORKPROCESS = "ads_spec_system_workprocess",
        FUEL = "ads_spec_system_fuel",
        [1] = "ads_spec_system_engine",
        [2] = "ads_spec_system_transmission",
        [3] = "ads_spec_system_hydraulics",
        [4] = "ads_spec_system_cooling",
        [5] = "ads_spec_system_electrical",
        [6] = "ads_spec_system_chassis",
        [7] = "ads_spec_system_workprocess",
        [8] = "ads_spec_system_fuel"
    },

    BREAKDOWN_SOURCES = {
        RANDOM = 1,
        POOR_PARTS = 2,
        QUICK_FIX = 3
    },

    WORKSHOP = {
    DEALER  = "ads_spec_workshop_dealer",
    MOBILE  = "ads_spec_workshop_mobile",
    OWN     = "ads_spec_workshop_own",
    [1] = "ads_spec_workshop_dealer",
    [2] = "ads_spec_workshop_mobile",
    [3] = "ads_spec_workshop_own",
    },

    PART_TYPES = {
    OEM         = "ads_spec_part_types_oem",
    USED        = "ads_spec_part_types_used",
    AFTERMARKET = "ads_spec_part_types_aftermarket",
    PREMIUM     = "ads_spec_part_types_premium",
    [1] = "ads_spec_part_types_oem",
    [2] = "ads_spec_part_types_used",
    [3] = "ads_spec_part_types_aftermarket",
    [4] = "ads_spec_part_types_premium",
    },

    INSPECTION_TYPES = {
    STANDARD = "ads_spec_inspection_standard",
    VISUAL   = "ads_spec_inspection_visual",
    COMPLETE = "ads_spec_inspection_complete",
    [1] = "ads_spec_inspection_standard",
    [2] = "ads_spec_inspection_visual",
    [3] = "ads_spec_inspection_complete",
    },

    MAINTENANCE_TYPES = {
    STANDARD = "ads_spec_maintenance_standard",
    MINIMAL  = "ads_spec_maintenance_minimal",
    EXTENDED = "ads_spec_maintenance_extended",
    PREVENTIVE = "ads_spec_maintenance_preventive",
    [1] = "ads_spec_maintenance_standard",
    [2] = "ads_spec_maintenance_minimal",
    [3] = "ads_spec_maintenance_extended",
    [4] = "ads_spec_maintenance_preventive",
    },

    REPAIR_TYPES = {
    LOW    = "ads_spec_repair_type_fix",
    MEDIUM = "ads_spec_repair_type_replacement",
    HIGH = "ads_spec_repair_type_advanced",
    [1] = "ads_spec_repair_type_fix",
    [2] = "ads_spec_repair_type_replacement",
    [3] = "ads_spec_repair_type_advanced",
    },

    OVERHAUL_TYPES = {
    STANDARD = "ads_spec_overhaul_standard",
    PARTIAL  = "ads_spec_overhaul_partial",
    FULL     = "ads_spec_overhaul_full",
    [1] = "ads_spec_overhaul_standard",
    [2] = "ads_spec_overhaul_partial",
    [3] = "ads_spec_overhaul_full",
    },
}

AdvancedDamageSystem.modDirectory = g_currentModDirectory

AdvancedDamageSystem.FACTOR_STATS_ALIASES = {
    expiredServiceFactor = "sf",
    breakdownPresenceFactor = "bpf",
    -- engine
    motorLoadFactor = "mlf",
    airIntakeCloggingFactor = "aicf",
    coldMotorFactor = "cmf",
    hotMotorFactor = "hmf",
    -- transmission
    pullOverloadFactor = "pof",
    heavyTrailerFactor = "htf",
    luggingFactor = "lf",
    wheelSlipFactor = "wsf",
    coldTransFactor = "ctf",
    hotTransFactor = "hotf",
    -- hydraulic
    heavyLiftFactor = "hlf",
    operatingFactor = "of",
    coldOilFactor = "cof",
    ptoOperatingFactor = "ptof",
    sharpAngleFactor = "saf",
    -- cooling
    highCoolingFactor = "hcf",
    overheatFactor = "ohf",
    coldShockFactor = "csf",

    -- electrical
    weatherExposureFactor = "wef",
    lightsFactor = "ltf",
    crankingStressFactor = "crf",

    -- chassis
    vibFactor = "vf",
    steerLoadFactor = "slf",
    brakeMassFactor = "bmf",

    --fuel
    lowFuelStarvationFactor = "lff",
    coldFuelFactor = "cff",
    idleDepositFactor = "idf",
    highPressureFactor = "hpf",
    wetCropFactor = "wcf",
    lubricationFactor = "lubf",
    instantDamageFactor = "idfg"
}

-- ==========================================================
--                          HELPER FUNCTIONS
-- ==========================================================

local function log_dbg(...)
    if ADS_Config and ADS_Config.DEBUG then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i])
        end
        print("[ADS_SPEC] " .. table.concat(args, " "))
    end
end

local function createEmptyFactorStats(systems)
    local result = {}
    if type(systems) ~= "table" then
        return result
    end

    for systemKey, _ in pairs(systems) do
        result[systemKey] = {
            total = 0,
            stress = 0,
            operatingHours = -1
        }
    end

    return result
end

local function getVehicleOperatingHours(vehicle)
    if vehicle == nil then
        return 0
    end

    if vehicle.getOperatingTime ~= nil then
        local operatingTime = tonumber(vehicle:getOperatingTime())
        if operatingTime ~= nil then
            return operatingTime / (60 * 60 * 1000)
        end
    end

    if vehicle.getFormattedOperatingTime ~= nil then
        return tonumber(vehicle:getFormattedOperatingTime()) or 0
    end

    return 0
end

local function flattenFactorStats(factorStats)
    local flat = {}
    if type(factorStats) ~= "table" then
        return flat
    end

    for systemKey, stats in pairs(factorStats) do
        if type(stats) == "table" then
            for statKey, statValue in pairs(stats) do
                local numericValue = tonumber(statValue)
                if numericValue ~= nil then
                    flat[string.format("%s.%s", tostring(systemKey), tostring(statKey))] = numericValue
                end
            end
        end
    end

    return flat
end

local function applyFlattenedFactorStats(spec, flattenedMap)
    if spec == nil then
        return
    end

    if type(spec.factorStats) ~= "table" then
        spec.factorStats = {}
    end

    if type(flattenedMap) ~= "table" then
        return
    end

    for flatKey, value in pairs(flattenedMap) do
        local systemKey, statKey = string.match(tostring(flatKey), "([^%.]+)%.(.+)")
        local numericValue = tonumber(value)
        if systemKey ~= nil and statKey ~= nil and numericValue ~= nil then
            if type(spec.factorStats[systemKey]) ~= "table" then
                spec.factorStats[systemKey] = {}
            end
            spec.factorStats[systemKey][statKey] = numericValue
        end
    end
end

local function ensureFactorStats(spec, vehicle)
    if spec == nil then
        return {}
    end

    if type(spec.factorStats) ~= "table" then
        spec.factorStats = {}
    end

    for systemKey, _ in pairs(spec.systems or {}) do
        if type(spec.factorStats[systemKey]) ~= "table" then
            spec.factorStats[systemKey] = {}
        end

        local stats = spec.factorStats[systemKey]
        stats.total = tonumber(stats.total) or 0
        stats.stress = tonumber(stats.stress) or 0
        stats.operatingHours = tonumber(stats.operatingHours)
        if stats.operatingHours == nil then
            stats.operatingHours = -1
        end
    end

    return spec.factorStats
end

local function hasCVTTransmission(vehicle)
    local motor = vehicle:getMotor()
    return motor ~= nil and motor.minForwardGearRatio ~= nil
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

local function getIsElectricVehicle(vehicle)
    if vehicle.spec_motorized and vehicle.spec_motorized.consumers then
        for _, consumer in pairs(vehicle.spec_motorized.consumers) do
            if consumer.fillType == FillType.ELECTRICCHARGE then
                return true
            end
        end
    end
    return false
end

local function getIsExcludedFromADS(vehicle)
    local vehicleName = vehicle:getFullName()
    if getIsElectricVehicle(vehicle) or
            vehicleName == 'Lizard Old Bike' or
            vehicleName == 'Lizard Mountain Bike' or
            vehicleName == 'Lizard Motorized Bike' then
        return true
    end
    return false
end

local function getIsVehicleNeedLubticate(vehicle)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then
        return false
    end

    local workProcessSystem = spec.systems ~= nil and spec.systems.workprocess or nil
    if type(workProcessSystem) ~= "table" then
        return false
    end

    return workProcessSystem.enabled ~= false
end

local function getIsVehicleNeedBlowOut(vehicle)
    local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
    local categoryName = storeItem ~= nil and storeItem.categoryName or ""
    local vtype = vehicle.type ~= nil and vehicle.type.name or ""

    if categoryName == "TRUCKS" or vtype == "car" or vtype == "carFillable" or vtype == "motorbike" then
        return false
    end

    return true
end

local function computeSystemSyncHash(vehicle)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then
        return 0
    end

    local systemHash = 0

    local sortedKeys = {}
    for sysKey, _ in pairs(spec.systems) do
        table.insert(sortedKeys, sysKey)
    end
    table.sort(sortedKeys)
    for i, sysKey in ipairs(sortedKeys) do
        local sysData = spec.systems[sysKey]
            local c = sysData.condition or 0
            local s = sysData.stress    or 0
            local e = sysData.enabled ~= false and 1 or 0
            systemHash = systemHash + (c + s * 0.001 + e * 0.0001) * i
    end
    return systemHash
end

-- ==========================================================
--                         DIRTY FLAGS HELPERS
-- ==========================================================

local function canRaiseDirtyFlag(vehicle, spec, flag)
    return vehicle ~= nil and vehicle.isServer and spec ~= nil and flag ~= nil
end

local function getSyncOperatingTime(vehicle)
    if vehicle == nil then
        return 0
    end

    if vehicle.getOperatingTime ~= nil then
        return tonumber(vehicle:getOperatingTime()) or 0
    end

    return tonumber(vehicle.operatingTime) or 0
end

local function getSyncMotorLoad(vehicle)
    if vehicle == nil or vehicle.getMotorLoadPercentage == nil then
        return 0
    end

    return tonumber(vehicle:getMotorLoadPercentage()) or 0
end

local function syncFloatChanged(a, b, epsilon)
    return math.abs((tonumber(a) or 0) - (tonumber(b) or 0)) > (epsilon or 0)
end

local function markStateDirty(vehicle, spec)
    if not canRaiseDirtyFlag(vehicle, spec, spec.adsDirtyFlag_state) then
        return false
    end

    if spec._lastSyncState_currentState ~= spec.currentState or
       spec._lastSyncState_plannedState ~= spec.plannedState or
       syncFloatChanged(spec._lastSyncState_maintenanceTimer, spec.maintenanceTimer, 1.0) then
            vehicle:raiseDirtyFlags(spec.adsDirtyFlag_state)
            spec._lastSyncState_currentState = spec.currentState
            spec._lastSyncState_plannedState = spec.plannedState
            spec._lastSyncState_maintenanceTimer = spec.maintenanceTimer
            return true
    end

    return false
end

local function markServiceContextDirty(vehicle, spec)
    if not canRaiseDirtyFlag(vehicle, spec, spec.adsDirtyFlag_serviceContext) then
        return false
    end

    if spec._lastSyncServiceContext_optionOne ~= spec.serviceOptionOne or
       spec._lastSyncServiceContext_optionTwo ~= spec.serviceOptionTwo or
       spec._lastSyncServiceContext_optionThree ~= spec.serviceOptionThree or
       spec._lastSyncServiceContext_workshopType ~= spec.workshopType then
            vehicle:raiseDirtyFlags(spec.adsDirtyFlag_serviceContext)
            spec._lastSyncServiceContext_optionOne = spec.serviceOptionOne
            spec._lastSyncServiceContext_optionTwo = spec.serviceOptionTwo
            spec._lastSyncServiceContext_optionThree = spec.serviceOptionThree
            spec._lastSyncServiceContext_workshopType = spec.workshopType
            return true
    end

    return false
end

local function markTelemetryDirty(vehicle, spec)
    if not canRaiseDirtyFlag(vehicle, spec, spec.adsDirtyFlag_telemetry) then
        return false
    end

    local operatingTime = getSyncOperatingTime(vehicle)
    local motorLoad = getSyncMotorLoad(vehicle)

    if syncFloatChanged(spec._lastSyncTelemetry_operatingTime, operatingTime, 1.0) or
       syncFloatChanged(spec._lastSyncTelemetry_fuelUsageRaw, spec._fuelUsageRaw, 0.3) or
       syncFloatChanged(spec._lastSyncTelemetry_motorLoad, motorLoad, 0.01) then
            vehicle:raiseDirtyFlags(spec.adsDirtyFlag_telemetry)
            spec._lastSyncTelemetry_operatingTime = operatingTime
            spec._lastSyncTelemetry_fuelUsageRaw = spec._fuelUsageRaw
            spec._lastSyncTelemetry_motorLoad = motorLoad
            return true
    end

    return false
end

local function markThermalDirty(vehicle, spec)
    if not canRaiseDirtyFlag(vehicle, spec, spec.adsDirtyFlag_thermal) then
        return false
    end

    if syncFloatChanged(spec._lastSyncThermal_rawEngineTemperature, spec.rawEngineTemperature, 0.05) or
       syncFloatChanged(spec._lastSyncThermal_rawTransmissionTemperature, spec.rawTransmissionTemperature, 0.05) or
       syncFloatChanged(spec._lastSyncThermal_thermostatState, spec.thermostatState, 0.05) or
       syncFloatChanged(spec._lastSyncThermal_transmissionThermostatState, spec.transmissionThermostatState, 0.05) then
            vehicle:raiseDirtyFlags(spec.adsDirtyFlag_thermal)
            spec._lastSyncThermal_rawEngineTemperature = spec.rawEngineTemperature
            spec._lastSyncThermal_rawTransmissionTemperature = spec.rawTransmissionTemperature
            spec._lastSyncThermal_thermostatState = spec.thermostatState
            spec._lastSyncThermal_transmissionThermostatState = spec.transmissionThermostatState
            return true
    end

    return false
end

local function markElectricalDirty(vehicle, spec)
    if not canRaiseDirtyFlag(vehicle, spec, spec.adsDirtyFlag_electrical) then
        return false
    end

    if syncFloatChanged(spec._lastSyncElectrical_batterySoc, spec.batterySoc, 0.01) or
       syncFloatChanged(spec._lastSyncElectrical_batteryChargeAh, spec.batteryChargeAh, 0.01) or
       syncFloatChanged(spec._lastSyncElectrical_batteryTerminalVoltage, spec.batteryTerminalVoltageV, 0.01) or
       syncFloatChanged(spec._lastSyncElectrical_systemVoltage, spec.systemVoltageV, 0.01) then
            vehicle:raiseDirtyFlags(spec.adsDirtyFlag_electrical)
            spec._lastSyncElectrical_batterySoc = spec.batterySoc
            spec._lastSyncElectrical_batteryChargeAh = spec.batteryChargeAh
            spec._lastSyncElectrical_batteryTerminalVoltage = spec.batteryTerminalVoltageV
            spec._lastSyncElectrical_systemVoltage = spec.systemVoltageV
            return true
    end

    return false
end

local function markFieldcareDirty(vehicle, spec)
    if not canRaiseDirtyFlag(vehicle, spec, spec.adsDirtyFlag_fieldcare) then
        return false
    end

    if syncFloatChanged(spec._lastSyncFieldcare_radiatorClogging, spec.radiatorClogging, 0.005) or
       syncFloatChanged(spec._lastSyncFieldcare_airIntakeClogging, spec.airIntakeClogging, 0.005) or
       syncFloatChanged(spec._lastSyncFieldcare_lubricationLevel, spec.lubricationLevel, 0.005) then
            vehicle:raiseDirtyFlags(spec.adsDirtyFlag_fieldcare)
            spec._lastSyncFieldcare_radiatorClogging = spec.radiatorClogging
            spec._lastSyncFieldcare_airIntakeClogging = spec.airIntakeClogging
            spec._lastSyncFieldcare_lubricationLevel = spec.lubricationLevel
            return true
    end

    return false
end

local function markWearDirty(vehicle, spec)
    if not canRaiseDirtyFlag(vehicle, spec, spec.adsDirtyFlag_wear) then
        return false
    end

    local systemsHash = computeSystemSyncHash(vehicle)

    if syncFloatChanged(spec._lastSyncWear_serviceLevel, spec.serviceLevel, 0.001) or
       syncFloatChanged(spec._lastSyncWear_conditionLevel, spec.conditionLevel, 0.001) or
       spec._lastSyncWear_systemsHash ~= systemsHash then
            vehicle:raiseDirtyFlags(spec.adsDirtyFlag_wear)
            spec._lastSyncWear_serviceLevel = spec.serviceLevel
            spec._lastSyncWear_conditionLevel = spec.conditionLevel
            spec._lastSyncWear_systemsHash = systemsHash
            return true
    end

    return false
end

local function markBreakdownsDirty(vehicle, spec)
    if not canRaiseDirtyFlag(vehicle, spec, spec.adsDirtyFlag_breakdowns) then
        return false
    end

    local serializedBreakdowns = ADS_Utils.serializeBreakdowns(spec.activeBreakdowns or {})
    if spec._lastSyncBreakdowns_serialized ~= serializedBreakdowns then
            vehicle:raiseDirtyFlags(spec.adsDirtyFlag_breakdowns)
            spec._lastSyncBreakdowns_serialized = serializedBreakdowns
            return true
    end

    return false
end

local function markServiceProgressDirty(vehicle, spec)
    if not canRaiseDirtyFlag(vehicle, spec, spec.adsDirtyFlag_serviceProgress) then
        return false
    end

    if syncFloatChanged(spec._lastSyncServiceProgress_elapsed, spec.pendingProgressElapsedTime,500.0) or
       spec._lastSyncServiceProgress_step ~= spec.pendingProgressStepIndex or
       syncFloatChanged(spec._lastSyncServiceProgress_total, spec.pendingProgressTotalTime, 500.0) then
            vehicle:raiseDirtyFlags(spec.adsDirtyFlag_serviceProgress)
            spec._lastSyncServiceProgress_elapsed = spec.pendingProgressElapsedTime
            spec._lastSyncServiceProgress_step = spec.pendingProgressStepIndex
            spec._lastSyncServiceProgress_total = spec.pendingProgressTotalTime
            return true
    end

    return false
end

function AdvancedDamageSystem.raiseServiceLifecycleDirtyFlags(vehicle)
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        return false
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    local raised = false

    if markStateDirty(vehicle, spec) then
        raised = true
    end
    if markServiceContextDirty(vehicle, spec) then
        raised = true
    end
    if markWearDirty(vehicle, spec) then
        raised = true
    end
    if markBreakdownsDirty(vehicle, spec) then
        raised = true
    end
    if markServiceProgressDirty(vehicle, spec) then
        raised = true
    end

    return raised
end

function AdvancedDamageSystem.forceFinishService(vehicle)
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil or not vehicle.isServer then
        return false
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    if spec.currentState == AdvancedDamageSystem.STATUS.READY then
        return false
    end

    local remainingMs = math.max(spec.maintenanceTimer or 0, 0)
    local missionInfo = g_currentMission and g_currentMission.missionInfo or nil
    local timeScale = (missionInfo and missionInfo.timeScale) or 1
    if timeScale <= 0 then
        timeScale = 1
    end

    local forceDt = math.max(math.ceil(remainingMs / timeScale) + 1, 1)

    local previousWorkshopOpen = nil
    if ADS_Main ~= nil then
        previousWorkshopOpen = ADS_Main.isWorkshopOpen
        ADS_Main.isWorkshopOpen = true
    end

    local ok, err = pcall(function()
        vehicle:processService(forceDt)
    end)

    if ADS_Main ~= nil and previousWorkshopOpen ~= nil then
        ADS_Main.isWorkshopOpen = previousWorkshopOpen
    end

    if not ok then
        log_dbg(string.format("Failed to force-finish service for '%s': %s", vehicle:getFullName(), tostring(err)))
        return false
    end

    if spec.currentState ~= AdvancedDamageSystem.STATUS.READY then
        spec.pendingProgressElapsedTime = spec.pendingProgressTotalTime or 0
        spec.maintenanceTimer = 0
        vehicle:completeService()
    end

    return true
end

-- ==========================================================
--                          REGISTRATION
-- ==========================================================


function AdvancedDamageSystem.initSpecialization()
    log_dbg("initSpecialization called.")
    local schema = Vehicle.xmlSchema
    local schemaSavegame = Vehicle.xmlSchemaSavegame

    schema:setXMLSpecializationType("AdvancedDamageSystem")

    local baseKey = "vehicles.vehicle(?).AdvancedDamageSystem"
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#service", "Service Level")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#condition", "Condition Level")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#breakdowns", "Active Breakdowns")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#state", "Current State")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#plannedState", "Planned State")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#maintenanceTimer", "Maintenance Timer")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#engineTemperature", "Engine Temperature")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#transmissionTemperature", "Transmission Temperature")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#batterySoc", "Battery State Of Charge")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#batteryChargeAh", "Battery Absolute Charge")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#batteryTempC", "Battery Temperature")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#radiatorClogging", "Radiator clogging level")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#airIntakeClogging", "Air intake clogging level")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#lubricationLevel", "Lubrication level")
    schemaSavegame:register(XMLValueType.INT,    baseKey .. "#lastLubricationProcessedDay", "Last lubrication processed day")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#thermostatState", "Engine Thermostat Position")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#transmissionThermostatState", "Transmission Thermostat Position")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#lastInspPwr", "Last Inspected Power")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#lastInspBrk", "Last Inspected Brake")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#lastInspYld", "Last Inspected Yield Reduction")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#serviceOptionOne", "Current Service Option One")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#serviceOptionTwo", "Current Service Option Two")
    schemaSavegame:register(XMLValueType.BOOL,   baseKey .. "#serviceOptionThree", "Current Service Option Three")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#workshopType", "Workshop Type")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#pendingSelectedBreakdowns", "Pending Selected Breakdowns")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#pendingServicePrice", "Pending Service Price")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#pendingInspectionQueue", "Pending Inspection Queue")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#pendingRepairQueue", "Pending Repair Queue")
    schemaSavegame:register(XMLValueType.INT,    baseKey .. "#pendingProgressStepIndex", "Pending Progress Step Index")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#pendingProgressTotalTime", "Pending Progress Total Time")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#pendingProgressElapsedTime", "Pending Progress Elapsed Time")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#pendingMaintenanceServiceStart", "Pending Maintenance Service Start")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#pendingMaintenanceServiceTarget", "Pending Maintenance Service Target")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#pendingPreventiveSystemStressStart", "Pending preventive per-system stress start values")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#pendingPreventiveSystemStressTarget", "Pending preventive per-system stress target values")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#systemsState", "Systems state snapshot")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#factorStats", "Per-system accumulated factor stats")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#pendingOverhaulSystemStart", "Pending overhaul per-system start values")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#pendingOverhaulSystemTarget", "Pending overhaul per-system target values")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#pendingOverhaulSystemStressStart", "Pending overhaul per-system stress start values")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#pendingOverhaulSystemStressTarget", "Pending overhaul per-system stress target values")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#pendingRepairSystemStressStart", "Pending repair per-system stress start values")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#pendingRepairSystemStressTarget", "Pending repair per-system stress target values")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#pendingRepairSystemStressStartRatio", "Pending repair per-system stress start ratios")

    local logKey = baseKey .. ".maintenanceLog.entry(?)"
    schemaSavegame:register(XMLValueType.INT,    logKey .. "#id", "Entry ID")
    schemaSavegame:register(XMLValueType.STRING, logKey .. "#type", "Maintenance Type")
    schemaSavegame:register(XMLValueType.FLOAT,  logKey .. "#price", "Price")
    schemaSavegame:register(XMLValueType.STRING, logKey .. "#date", "Date")
    
    schemaSavegame:register(XMLValueType.FLOAT,  logKey .. "#hours", "Operating Hours (OLD)")
    schemaSavegame:register(XMLValueType.BOOL,   logKey .. "#aftermarket", "Is Aftermarket Parts (OLD)")
    schemaSavegame:register(XMLValueType.STRING, logKey .. "#breakdowns", "Selected Breakdowns List (OLD)")
    schemaSavegame:register(XMLValueType.STRING, logKey .. "#info", "Additional Info (OLD)")
    schemaSavegame:register(XMLValueType.STRING, logKey .. "#location", "Workshop Location")
    schemaSavegame:register(XMLValueType.STRING, logKey .. "#optionOne", "Option One")
    schemaSavegame:register(XMLValueType.STRING, logKey .. "#optionTwo", "Option Two")
    schemaSavegame:register(XMLValueType.BOOL,   logKey .. "#optionThree", "Option Three")
    schemaSavegame:register(XMLValueType.STRING, logKey .. "#isVisible", "is Visible in Log")
    schemaSavegame:register(XMLValueType.BOOL,   logKey .. "#isCompleted", "Is Completed")
    schemaSavegame:register(XMLValueType.BOOL,   logKey .. "#isLegacyEntry", "Legacy Migrated Entry Flag")
    local condKey = logKey .. ".conditionData"
    schemaSavegame:register(XMLValueType.INT,    condKey .. "#year", "Vehicle Year")
    schemaSavegame:register(XMLValueType.FLOAT,  condKey .. "#operatingHours", "Operating Hours")
    schemaSavegame:register(XMLValueType.FLOAT,  condKey .. "#age", "Vehicle Age")
    schemaSavegame:register(XMLValueType.FLOAT,  condKey .. "#condition", "Condition Level")
    schemaSavegame:register(XMLValueType.FLOAT,  condKey .. "#service", "Service Level")
    schemaSavegame:register(XMLValueType.STRING, condKey .. "#activeBreakdowns", "Active Breakdowns")
    schemaSavegame:register(XMLValueType.STRING, condKey .. "#selectedBreakdowns", "Selected Breakdowns")
    schemaSavegame:register(XMLValueType.STRING, condKey .. "#activeEffects", "Active Effects")
    schemaSavegame:register(XMLValueType.STRING, condKey .. "#activeIndicators", "Active Indicators")
    schemaSavegame:register(XMLValueType.FLOAT,  condKey .. "#reliability", "Reliability")
    schemaSavegame:register(XMLValueType.FLOAT,  condKey .. "#maintainability", "Maintainability")
    schemaSavegame:register(XMLValueType.STRING, condKey .. "#systems", "Per-system snapshot")
    schemaSavegame:register(XMLValueType.FLOAT,  condKey .. "#batterySoc", "Battery State Of Charge")
    
    schema:setXMLSpecializationType()
end

function AdvancedDamageSystem.registerEventListeners(vehicleType)
    log_dbg("registerEventListeners called for vehicleType:", vehicleType.name)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AdvancedDamageSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AdvancedDamageSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", AdvancedDamageSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AdvancedDamageSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AdvancedDamageSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AdvancedDamageSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", AdvancedDamageSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", AdvancedDamageSystem)
    SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", AdvancedDamageSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AdvancedDamageSystem)
end

function AdvancedDamageSystem.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanMotorRun", ADS_Breakdowns.getCanMotorRun)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "startMotor", ADS_Breakdowns.startMotor)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateDamageAmount", AdvancedDamageSystem.updateDamageAmount)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setLightsTypesMask", ADS_Breakdowns.setLightsTypesMask)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSpeedLimit", ADS_Breakdowns.getSpeedLimitOverwrite)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateVehiclePhysics", ADS_Breakdowns.updateVehiclePhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDischargeNodeActive", ADS_Breakdowns.getIsDischargeNodeActiveOverwrite)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateConsumers", ADS_Breakdowns.updateConsumersOverwrite)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addCutterArea", ADS_Breakdowns.addCutterAreaOverwrite)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeNodeEmptyFactor", ADS_Breakdowns.getDischargeNodeEmptyFactorOverwrite)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSellPrice", AdvancedDamageSystem.getSellPrice)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateMotorTemperature", AdvancedDamageSystem.updateMotorTemperature)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setOperatingTime", AdvancedDamageSystem.setOperatingTime)

    
end

function AdvancedDamageSystem.registerFunctions(vehicleType)
    log_dbg("registerFunctions called for vehicleType:", vehicleType.name)
    SpecializationUtil.registerFunction(vehicleType, "adsUpdate", AdvancedDamageSystem.adsUpdate)

    SpecializationUtil.registerFunction(vehicleType, "recalculateAndApplyEffects", AdvancedDamageSystem.recalculateAndApplyEffects)
    SpecializationUtil.registerFunction(vehicleType, "recalculateAndApplyIndicators", AdvancedDamageSystem.recalculateAndApplyIndicators)
    
    SpecializationUtil.registerFunction(vehicleType, "tryTriggerBreakdown", AdvancedDamageSystem.tryTriggerBreakdown)
    SpecializationUtil.registerFunction(vehicleType, "getRandomBreakdownBySystem", AdvancedDamageSystem.getRandomBreakdownBySystem)
    SpecializationUtil.registerFunction(vehicleType, "getRandomBreakdown", AdvancedDamageSystem.getRandomBreakdown)
    SpecializationUtil.registerFunction(vehicleType, "addBreakdown", AdvancedDamageSystem.addBreakdown)
    SpecializationUtil.registerFunction(vehicleType, "suspendBreakdown", AdvancedDamageSystem.suspendBreakdown)
    SpecializationUtil.registerFunction(vehicleType, "removeBreakdown", AdvancedDamageSystem.removeBreakdown)
    SpecializationUtil.registerFunction(vehicleType, "hasBreakdown", AdvancedDamageSystem.hasBreakdown)
    SpecializationUtil.registerFunction(vehicleType, "hasSystemBreakdowns", AdvancedDamageSystem.hasSystemBreakdowns)
    SpecializationUtil.registerFunction(vehicleType, "processBreakdowns", AdvancedDamageSystem.processBreakdowns)
    SpecializationUtil.registerFunction(vehicleType, "changeBreakdownStage", AdvancedDamageSystem.changeBreakdownStage)
    SpecializationUtil.registerFunction(vehicleType, "getActiveBreakdowns", AdvancedDamageSystem.getActiveBreakdowns)
    SpecializationUtil.registerFunction(vehicleType, "processGeneralWearBreakdown", AdvancedDamageSystem.processGeneralWearBreakdown)
    
    SpecializationUtil.registerFunction(vehicleType, "initService", AdvancedDamageSystem.initService)
    SpecializationUtil.registerFunction(vehicleType, "processService", AdvancedDamageSystem.processService)
    SpecializationUtil.registerFunction(vehicleType, "completeService", AdvancedDamageSystem.completeService)
    SpecializationUtil.registerFunction(vehicleType, "cancelService", AdvancedDamageSystem.cancelService)

    SpecializationUtil.registerFunction(vehicleType, "getServiceLevel", AdvancedDamageSystem.getServiceLevel)
    SpecializationUtil.registerFunction(vehicleType, "getConditionLevel", AdvancedDamageSystem.getConditionLevel)
    SpecializationUtil.registerFunction(vehicleType, "getSystemConditionLevel", AdvancedDamageSystem.getSystemConditionLevel)
    SpecializationUtil.registerFunction(vehicleType, "getSystemStressLevel", AdvancedDamageSystem.getSystemStressLevel)
    SpecializationUtil.registerFunction(vehicleType, "updateServiceLevel", AdvancedDamageSystem.updateServiceLevel)
    SpecializationUtil.registerFunction(vehicleType, "updateConditionLevel", AdvancedDamageSystem.updateConditionLevel)

    SpecializationUtil.registerFunction(vehicleType, "updateSystemConditionAndStress", AdvancedDamageSystem.updateSystemConditionAndStress)
    SpecializationUtil.registerFunction(vehicleType, "updateEngineSystem", AdvancedDamageSystem.updateEngineSystem)
    SpecializationUtil.registerFunction(vehicleType, "updateTransmissionSystem", AdvancedDamageSystem.updateTransmissionSystem)
    SpecializationUtil.registerFunction(vehicleType, "updateHydraulicsSystem", AdvancedDamageSystem.updateHydraulicsSystem)
    SpecializationUtil.registerFunction(vehicleType, "updateCoolingSystem", AdvancedDamageSystem.updateCoolingSystem)
    SpecializationUtil.registerFunction(vehicleType, "updateElectricalSystem", AdvancedDamageSystem.updateElectricalSystem)
    SpecializationUtil.registerFunction(vehicleType, "updateChassisSystem", AdvancedDamageSystem.updateChassisSystem)
    SpecializationUtil.registerFunction(vehicleType, "updateFuelSystem", AdvancedDamageSystem.updateFuelSystem)
    SpecializationUtil.registerFunction(vehicleType, "updateWorkProcessSystem", AdvancedDamageSystem.updateWorkProcessSystem)
    SpecializationUtil.registerFunction(vehicleType, "applyInstantDamageToSystem", AdvancedDamageSystem.applyInstantDamageToSystem)
    
    SpecializationUtil.registerFunction(vehicleType, "isUnderService", AdvancedDamageSystem.isUnderService)
    SpecializationUtil.registerFunction(vehicleType, "isUnderRoof", AdvancedDamageSystem.isUnderRoof)
    SpecializationUtil.registerFunction(vehicleType, "getCurrentStatus", AdvancedDamageSystem.getCurrentStatus)
    
    SpecializationUtil.registerFunction(vehicleType, "updateThermalSystems", AdvancedDamageSystem.updateThermalSystems)
    SpecializationUtil.registerFunction(vehicleType, "updateEngineThermalModel", AdvancedDamageSystem.updateEngineThermalModel)
    SpecializationUtil.registerFunction(vehicleType, "updateTransmissionThermalModel", AdvancedDamageSystem.updateTransmissionThermalModel)
    SpecializationUtil.registerFunction(vehicleType, "getSmoothedTemperature", AdvancedDamageSystem.getSmoothedTemperature)
     
    SpecializationUtil.registerFunction(vehicleType, "updateBatteryChargingModel", AdvancedDamageSystem.updateBatteryChargingModel)
    SpecializationUtil.registerFunction(vehicleType, "establishExternalPowerConnection", AdvancedDamageSystem.establishExternalPowerConnection)
    SpecializationUtil.registerFunction(vehicleType, "clearExternalPowerConnection", AdvancedDamageSystem.clearExternalPowerConnection)
    
    SpecializationUtil.registerFunction(vehicleType, "updateRadiatorClogging", AdvancedDamageSystem.updateRadiatorClogging)
    SpecializationUtil.registerFunction(vehicleType, "updateAirIntakeClogging", AdvancedDamageSystem.updateAirIntakeClogging)
    SpecializationUtil.registerFunction(vehicleType, "cleanRadiatorAndAirIntake", AdvancedDamageSystem.cleanRadiatorAndAirIntake)
    SpecializationUtil.registerFunction(vehicleType, "updateLubricationLevel", AdvancedDamageSystem.updateLubricationLevel)
    SpecializationUtil.registerFunction(vehicleType, "lubricateVehicle", AdvancedDamageSystem.lubricateVehicle)
    SpecializationUtil.registerFunction(vehicleType, "startFieldVisualInspectionProcess", AdvancedDamageSystem.startFieldVisualInspectionProcess)

    SpecializationUtil.registerFunction(vehicleType, "resetAiWorkerCruiseControlState", AdvancedDamageSystem.resetAiWorkerCruiseControlState)
    SpecializationUtil.registerFunction(vehicleType, "getAiWorkerImplementSpeedLimit", AdvancedDamageSystem.getAiWorkerImplementSpeedLimit)
    SpecializationUtil.registerFunction(vehicleType, "updateAiWorkerCruiseControl", AdvancedDamageSystem.updateAiWorkerCruiseControl)
    SpecializationUtil.registerFunction(vehicleType, "isWarrantyRepairCovered", AdvancedDamageSystem.isWarrantyRepairCovered)

    SpecializationUtil.registerFunction(vehicleType, "getServicePrice", AdvancedDamageSystem.getServicePrice)
    SpecializationUtil.registerFunction(vehicleType, "getServiceDuration", AdvancedDamageSystem.getServiceDuration)
    SpecializationUtil.registerFunction(vehicleType, "getServiceFinishTime", AdvancedDamageSystem.getServiceFinishTime)
    SpecializationUtil.registerFunction(vehicleType, "getBreakdownRepairPrice", AdvancedDamageSystem.getBreakdownRepairPrice)
    
    SpecializationUtil.registerFunction(vehicleType, "addEntryToMaintenanceLog", AdvancedDamageSystem.addEntryToMaintenanceLog)
    SpecializationUtil.registerFunction(vehicleType, "getLastInspectedCondition", AdvancedDamageSystem.getLastInspectedCondition)
    SpecializationUtil.registerFunction(vehicleType, "getLastInspectedService", AdvancedDamageSystem.getLastInspectedService)
    SpecializationUtil.registerFunction(vehicleType, "getLastInspectionDate", AdvancedDamageSystem.getLastInspectionDate)
    SpecializationUtil.registerFunction(vehicleType, "getLastMaintenanceDate", AdvancedDamageSystem.getLastMaintenanceDate)
    SpecializationUtil.registerFunction(vehicleType, "getMaintenanceInterval", AdvancedDamageSystem.getMaintenanceInterval)
    SpecializationUtil.registerFunction(vehicleType, "getHoursSinceLastMaintenance", AdvancedDamageSystem.getHoursSinceLastMaintenance)
    SpecializationUtil.registerFunction(vehicleType, "getLastServiceOptions", AdvancedDamageSystem.getLastServiceOptions)
    SpecializationUtil.registerFunction(vehicleType, "getOverhaulPerformedCount", AdvancedDamageSystem.getOverhaulPerformedCount)
    
end

-- ============================================================
--                         NETWORK STREAMS
-- ============================================================

function AdvancedDamageSystem:onWriteStream(streamId, connection)
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil or spec.isExcludedVehicle then return end

    -- [Group 1] State
    streamWriteString(streamId, spec.currentState or "")
    streamWriteString(streamId, spec.plannedState or "")
    streamWriteFloat32(streamId, spec.maintenanceTimer or 0)

    -- [Group 2] Service context
    streamWriteString(streamId, spec.serviceOptionOne or "")
    streamWriteString(streamId, spec.serviceOptionTwo or "")
    streamWriteBool(streamId, spec.serviceOptionThree or false)
    streamWriteString(streamId, spec.workshopType or "")

    -- [Group 3] Telemetry
    streamWriteFloat32(streamId, getSyncOperatingTime(self))
    streamWriteFloat32(streamId, spec._fuelUsageRaw or 0)
    streamWriteFloat32(streamId, self:getMotorLoadPercentage() or 0)

    -- [Group 4] Thermal
    streamWriteFloat32(streamId, spec.rawEngineTemperature or -99)
    streamWriteFloat32(streamId, spec.rawTransmissionTemperature or -99)
    streamWriteFloat32(streamId, spec.thermostatState or 0)
    streamWriteFloat32(streamId, spec.transmissionThermostatState or 0)

    -- [Group 5] Electrical
    streamWriteFloat32(streamId, spec.batterySoc or 1.0)
    streamWriteFloat32(streamId, spec.batteryChargeAh or 0)
    streamWriteFloat32(streamId, spec.batteryTerminalVoltageV or 0)
    streamWriteFloat32(streamId, spec.systemVoltageV or 0)

    -- [Group 6] Field care
    streamWriteFloat32(streamId, math.max(spec.radiatorClogging or 0, 0))
    streamWriteFloat32(streamId, math.max(spec.airIntakeClogging or 0, 0))
    streamWriteFloat32(streamId, math.clamp(spec.lubricationLevel or 1.0, 0.0, 1.0))

    -- [Group 7] Wear
    streamWriteFloat32(streamId, spec.serviceLevel or 1.0)
    streamWriteFloat32(streamId, spec.conditionLevel or 1.0)
    streamWriteString(streamId, ADS_Utils.serializeSystemsState(spec.systems))

    -- [Group 8] Breakdowns
    streamWriteString(streamId, ADS_Utils.serializeBreakdowns(spec.activeBreakdowns or {}))

    -- [Group 9] Service progress
    streamWriteInt32(streamId, spec.pendingProgressStepIndex or 0)
    streamWriteFloat32(streamId, spec.pendingProgressTotalTime or 0)
    streamWriteFloat32(streamId, spec.pendingProgressElapsedTime or 0)

    -- [Group 10] Maintenance log (variable-length: count + entries)
    local logCount = spec.maintenanceLog and #spec.maintenanceLog or 0
    streamWriteUInt16(streamId, logCount)
    for i = 1, logCount do
        local entry = spec.maintenanceLog[i]
        streamWriteString(streamId, ADS_Utils.serializeMaintenanceLogEntry(entry))
    end
end

function AdvancedDamageSystem:onReadStream(streamId, connection)
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil or spec.isExcludedVehicle then return end

    -- [Group 1] State
    spec.currentState = streamReadString(streamId)
    spec.plannedState = streamReadString(streamId)
    spec.maintenanceTimer = streamReadFloat32(streamId)

    -- [Group 2] Service context
    spec.serviceOptionOne = streamReadString(streamId)
    spec.serviceOptionTwo = streamReadString(streamId)
    spec.serviceOptionThree = streamReadBool(streamId)
    spec.workshopType = streamReadString(streamId)
    if spec.serviceOptionOne == "" then spec.serviceOptionOne = nil end
    if spec.serviceOptionTwo == "" then spec.serviceOptionTwo = nil end
    if spec.workshopType == "" then spec.workshopType = nil end

    -- [Group 3] Telemetry
    self:setOperatingTime(streamReadFloat32(streamId), true)
    local syncFuelRaw = streamReadFloat32(streamId)
    spec._fuelUsageRaw = syncFuelRaw
    spec.fuelUsage = syncFuelRaw
    spec._netMotorLoad = streamReadFloat32(streamId)
    if not self.isServer and self.spec_motorized ~= nil then
        self.spec_motorized.lastFuelUsage = syncFuelRaw
    end

    -- [Group 4] Thermal
    local syncRawEngTemp = streamReadFloat32(streamId)
    local syncRawTransTemp = streamReadFloat32(streamId)
    spec.rawEngineTemperature = syncRawEngTemp
    spec.rawTransmissionTemperature = syncRawTransTemp
    spec._netTargetEngineTemp = syncRawEngTemp
    spec._netTargetTransmissionTemp = syncRawTransTemp
    spec.engineTemperature = syncRawEngTemp
    spec.transmissionTemperature = syncRawTransTemp
    spec.thermostatState = streamReadFloat32(streamId)
    if spec.engTermPID ~= nil then
        spec.engTermPID.mechPos = spec.thermostatState
    end
    spec.transmissionThermostatState = streamReadFloat32(streamId)
    if spec.transTermPID ~= nil then
        spec.transTermPID.mechPos = spec.transmissionThermostatState
    end

    -- [Group 5] Electrical
    spec.batterySoc = streamReadFloat32(streamId)
    spec.batteryChargeAh = streamReadFloat32(streamId)
    spec.batteryTerminalVoltageV = streamReadFloat32(streamId)
    spec.rawBatteryTerminalVoltageV = spec.batteryTerminalVoltageV
    spec.systemVoltageV = streamReadFloat32(streamId)
    spec.rawSystemVoltageV = spec.systemVoltageV

    -- [Group 6] Field care
    spec.radiatorClogging = math.max(streamReadFloat32(streamId), 0)
    spec.airIntakeClogging = math.max(streamReadFloat32(streamId), 0)
    spec.lubricationLevel = math.clamp(streamReadFloat32(streamId), 0.0, 1.0)

    -- [Group 7] Wear
    spec.serviceLevel = streamReadFloat32(streamId)
    spec.conditionLevel = streamReadFloat32(streamId)
    local loadedSystems = ADS_Utils.deserializeSystemsState(streamReadString(streamId))
    for sysKey, sysData in pairs(loadedSystems) do
        if spec.systems[sysKey] ~= nil then
            spec.systems[sysKey].condition = sysData.condition
            spec.systems[sysKey].stress = sysData.stress
            spec.systems[sysKey].enabled = sysData.enabled
        end
    end

    -- [Group 8] Breakdowns
    spec.activeBreakdowns = ADS_Utils.deserializeBreakdowns(streamReadString(streamId))

    -- [Group 9] Service progress
    spec.pendingProgressStepIndex = streamReadInt32(streamId)
    spec.pendingProgressTotalTime = streamReadFloat32(streamId)
    spec.pendingProgressElapsedTime = streamReadFloat32(streamId)

    -- [Group 10] Maintenance log (variable-length)
    local logCount = streamReadUInt16(streamId)
    spec.maintenanceLog = {}
    for i = 1, logCount do
        local entry = ADS_Utils.deserializeMaintenanceLogEntry(streamReadString(streamId))
        if entry ~= nil then
            table.insert(spec.maintenanceLog, entry)
        end
    end

    self:recalculateAndApplyEffects()
    self:recalculateAndApplyIndicators()
end

function AdvancedDamageSystem:onWriteUpdateStream(streamId, connection, dirtyMask)
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil or spec.isExcludedVehicle then return end

    if not connection:getIsServer() then
        -- [1] State
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.adsDirtyFlag_state) ~= 0) then
            streamWriteString(streamId, spec.currentState or "")
            streamWriteString(streamId, spec.plannedState or "")
            streamWriteFloat32(streamId, spec.maintenanceTimer or 0)
        end

        -- [2] Service context
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.adsDirtyFlag_serviceContext) ~= 0) then
            streamWriteString(streamId, spec.serviceOptionOne or "")
            streamWriteString(streamId, spec.serviceOptionTwo or "")
            streamWriteBool(streamId, spec.serviceOptionThree or false)
            streamWriteString(streamId, spec.workshopType or "")
        end

        -- [3] Telemetry
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.adsDirtyFlag_telemetry) ~= 0) then
            streamWriteFloat32(streamId, getSyncOperatingTime(self))
            streamWriteFloat32(streamId, spec._fuelUsageRaw or 0)
            streamWriteFloat32(streamId, self:getMotorLoadPercentage() or 0)
        end

        -- [4] Thermal
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.adsDirtyFlag_thermal) ~= 0) then
            streamWriteFloat32(streamId, spec.rawEngineTemperature or -99)
            streamWriteFloat32(streamId, spec.rawTransmissionTemperature or -99)
            streamWriteFloat32(streamId, spec.thermostatState or 0)
            streamWriteFloat32(streamId, spec.transmissionThermostatState or 0)
        end

        -- [5] Electrical
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.adsDirtyFlag_electrical) ~= 0) then
            streamWriteFloat32(streamId, spec.batterySoc or 1.0)
            streamWriteFloat32(streamId, spec.batteryChargeAh or 0)
            streamWriteFloat32(streamId, spec.batteryTerminalVoltageV or 0)
            streamWriteFloat32(streamId, spec.systemVoltageV or 0)
        end

        -- [6] Field care
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.adsDirtyFlag_fieldcare) ~= 0) then
            streamWriteFloat32(streamId, math.max(spec.radiatorClogging or 0, 0))
            streamWriteFloat32(streamId, math.max(spec.airIntakeClogging or 0, 0))
            streamWriteFloat32(streamId, math.clamp(spec.lubricationLevel or 1.0, 0.0, 1.0))
        end

        -- [7] Wear
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.adsDirtyFlag_wear) ~= 0) then
            streamWriteFloat32(streamId, spec.serviceLevel or 1.0)
            streamWriteFloat32(streamId, spec.conditionLevel or 1.0)
            streamWriteString(streamId, ADS_Utils.serializeSystemsState(spec.systems))
        end

        -- [8] Breakdowns
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.adsDirtyFlag_breakdowns) ~= 0) then
            streamWriteString(streamId, ADS_Utils.serializeBreakdowns(spec.activeBreakdowns or {}))
        end

        -- [9] Service progress
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.adsDirtyFlag_serviceProgress) ~= 0) then
            streamWriteInt32(streamId, spec.pendingProgressStepIndex or 0)
            streamWriteFloat32(streamId, spec.pendingProgressTotalTime or 0)
            streamWriteFloat32(streamId, spec.pendingProgressElapsedTime or 0)
        end
    end
end

function AdvancedDamageSystem:onReadUpdateStream(streamId, timestamp, connection)
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil or spec.isExcludedVehicle then return end

    if connection:getIsServer() then
        -- [1] State
        if streamReadBool(streamId) then
            spec.currentState = streamReadString(streamId)
            spec.plannedState = streamReadString(streamId)
            spec.maintenanceTimer = streamReadFloat32(streamId)
        end

        -- [2] Service context
        if streamReadBool(streamId) then
            spec.serviceOptionOne = streamReadString(streamId)
            spec.serviceOptionTwo = streamReadString(streamId)
            spec.serviceOptionThree = streamReadBool(streamId)
            spec.workshopType = streamReadString(streamId)
            if spec.serviceOptionOne == "" then spec.serviceOptionOne = nil end
            if spec.serviceOptionTwo == "" then spec.serviceOptionTwo = nil end
            if spec.workshopType == "" then spec.workshopType = nil end
        end

        -- [3] Telemetry
        if streamReadBool(streamId) then
            self:setOperatingTime(streamReadFloat32(streamId), true)
            spec._fuelUsageRaw = streamReadFloat32(streamId)
            spec._netMotorLoad = streamReadFloat32(streamId)
        end

        -- [4] Thermal
        if streamReadBool(streamId) then
            local syncRawEngTemp = streamReadFloat32(streamId)
            local syncRawTransTemp = streamReadFloat32(streamId)
            spec.rawEngineTemperature = syncRawEngTemp
            spec.rawTransmissionTemperature = syncRawTransTemp
            spec._netTargetEngineTemp = syncRawEngTemp
            spec._netTargetTransmissionTemp = syncRawTransTemp
            spec.thermostatState = streamReadFloat32(streamId)
            if spec.engTermPID ~= nil then
                spec.engTermPID.mechPos = spec.thermostatState
            end
            spec.transmissionThermostatState = streamReadFloat32(streamId)
            if spec.transTermPID ~= nil then
                spec.transTermPID.mechPos = spec.transmissionThermostatState
            end
        end

        -- [5] Electrical
        if streamReadBool(streamId) then
            spec.batterySoc = streamReadFloat32(streamId)
            spec.batteryChargeAh = streamReadFloat32(streamId)
            spec.batteryTerminalVoltageV = streamReadFloat32(streamId)
            spec.rawBatteryTerminalVoltageV = spec.batteryTerminalVoltageV
            spec.systemVoltageV = streamReadFloat32(streamId)
            spec.rawSystemVoltageV = spec.systemVoltageV
        end

        -- [6] Field care
        if streamReadBool(streamId) then
            spec.radiatorClogging = math.max(streamReadFloat32(streamId), 0)
            spec.airIntakeClogging = math.max(streamReadFloat32(streamId), 0)
            spec.lubricationLevel = math.clamp(streamReadFloat32(streamId), 0.0, 1.0)
        end

        -- [7] Wear
        if streamReadBool(streamId) then
            spec.serviceLevel = streamReadFloat32(streamId)
            spec.conditionLevel = streamReadFloat32(streamId)
            local loadedSystems = ADS_Utils.deserializeSystemsState(streamReadString(streamId))
            for sysKey, sysData in pairs(loadedSystems) do
                if spec.systems[sysKey] ~= nil then
                    spec.systems[sysKey].condition = sysData.condition
                    spec.systems[sysKey].stress = sysData.stress
                    spec.systems[sysKey].enabled = sysData.enabled
                end
            end
        end

        -- [8] Breakdowns
        if streamReadBool(streamId) then
            spec.activeBreakdowns = ADS_Utils.deserializeBreakdowns(streamReadString(streamId))
            self:recalculateAndApplyEffects()
            self:recalculateAndApplyIndicators()
        end

        -- [9] Service progress
        if streamReadBool(streamId) then
            spec.pendingProgressStepIndex = streamReadInt32(streamId)
            spec.pendingProgressTotalTime = streamReadFloat32(streamId)
            spec.pendingProgressElapsedTime = streamReadFloat32(streamId)
        end
    end
end
-- ============================================================
--                       SAVE & LOAD
-- ============================================================

function AdvancedDamageSystem:saveToXMLFile(xmlFile, key, usedModNames)
    log_dbg("saveToXMLFile called for vehicle:", self:getFullName(), "with key:", key)
    local spec = self.spec_AdvancedDamageSystem
    if spec ~= nil and not spec.isExcludedVehicle then
        xmlFile:setValue(key .. "#service", spec.serviceLevel or 1.0)
        xmlFile:setValue(key .. "#condition", spec.conditionLevel or 1.0)
        
        local breakdownString = ADS_Utils.serializeBreakdowns(spec.activeBreakdowns)
        xmlFile:setValue(key .. "#breakdowns", breakdownString)
        xmlFile:setValue(key .. "#state", spec.currentState or AdvancedDamageSystem.STATUS.READY)
        xmlFile:setValue(key .. "#plannedState", spec.plannedState or AdvancedDamageSystem.STATUS.READY)
        xmlFile:setValue(key .. "#maintenanceTimer", spec.maintenanceTimer or 0)
        xmlFile:setValue(key .. "#engineTemperature", spec.engineTemperature or -99)
        xmlFile:setValue(key .. "#transmissionTemperature", spec.transmissionTemperature or -99)
        xmlFile:setValue(key .. "#batterySoc", spec.batterySoc or 1.0)
        xmlFile:setValue(key .. "#batteryChargeAh", spec.batteryChargeAh or 0)
        xmlFile:setValue(key .. "#batteryTempC", spec.batteryTempC or 0)
        xmlFile:setValue(key .. "#radiatorClogging", math.max(spec.radiatorClogging or 0, 0))
        xmlFile:setValue(key .. "#airIntakeClogging", math.max(spec.airIntakeClogging or 0, 0))
        xmlFile:setValue(key .. "#lubricationLevel", math.clamp(spec.lubricationLevel or 1.0, 0.0, 1.0))
        xmlFile:setValue(key .. "#lastLubricationProcessedDay", spec.lastLubricationProcessedDay or 0)
        xmlFile:setValue(key .. "#thermostatState", math.clamp(spec.thermostatState or 0.0, 0.0, 1.0))
        xmlFile:setValue(key .. "#transmissionThermostatState", math.clamp(spec.transmissionThermostatState or 0.0, 0.0, 1.0))
        xmlFile:setValue(key .. "#lastInspPwr", spec.lastInspectedPower or 1)
        xmlFile:setValue(key .. "#lastInspBrk", spec.lastInspectedBrake or 1)
        xmlFile:setValue(key .. "#lastInspYld", spec.lastInspectedYieldReduction or 1)
        xmlFile:setValue(key .. "#serviceOptionOne", spec.serviceOptionOne or "")
        xmlFile:setValue(key .. "#serviceOptionTwo", spec.serviceOptionTwo or "")
        xmlFile:setValue(key .. "#serviceOptionThree", spec.serviceOptionThree or false)
        xmlFile:setValue(key .. "#workshopType", spec.workshopType or "")
        xmlFile:setValue(key .. "#pendingSelectedBreakdowns", table.concat(spec.pendingSelectedBreakdowns or {}, ","))
        xmlFile:setValue(key .. "#pendingServicePrice", ADS_Utils.encodeOptionalFloat(spec.pendingServicePrice))
        xmlFile:setValue(key .. "#pendingInspectionQueue", table.concat(spec.pendingInspectionQueue or {}, ","))
        xmlFile:setValue(key .. "#pendingRepairQueue", table.concat(spec.pendingRepairQueue or {}, ","))
        xmlFile:setValue(key .. "#pendingProgressStepIndex", spec.pendingProgressStepIndex or 0)
        xmlFile:setValue(key .. "#pendingProgressTotalTime", spec.pendingProgressTotalTime or 0)
        xmlFile:setValue(key .. "#pendingProgressElapsedTime", spec.pendingProgressElapsedTime or 0)
        xmlFile:setValue(key .. "#pendingMaintenanceServiceStart", ADS_Utils.encodeOptionalFloat(spec.pendingMaintenanceServiceStart))
        xmlFile:setValue(key .. "#pendingMaintenanceServiceTarget", ADS_Utils.encodeOptionalFloat(spec.pendingMaintenanceServiceTarget))
        xmlFile:setValue(key .. "#pendingPreventiveSystemStressStart", ADS_Utils.serializeNumericMap(spec.pendingPreventiveSystemStressStart))
        xmlFile:setValue(key .. "#pendingPreventiveSystemStressTarget", ADS_Utils.serializeNumericMap(spec.pendingPreventiveSystemStressTarget))
        xmlFile:setValue(key .. "#systemsState", ADS_Utils.serializeSystemsState(spec.systems))
        xmlFile:setValue(key .. "#factorStats", ADS_Utils.serializeNumericMap(flattenFactorStats(spec.factorStats)))
        xmlFile:setValue(key .. "#pendingOverhaulSystemStart", ADS_Utils.serializeNumericMap(spec.pendingOverhaulSystemStart))
        xmlFile:setValue(key .. "#pendingOverhaulSystemTarget", ADS_Utils.serializeNumericMap(spec.pendingOverhaulSystemTarget))
        xmlFile:setValue(key .. "#pendingOverhaulSystemStressStart", ADS_Utils.serializeNumericMap(spec.pendingOverhaulSystemStressStart))
        xmlFile:setValue(key .. "#pendingOverhaulSystemStressTarget", ADS_Utils.serializeNumericMap(spec.pendingOverhaulSystemStressTarget))
        xmlFile:setValue(key .. "#pendingRepairSystemStressStart", ADS_Utils.serializeNumericMap(spec.pendingRepairSystemStressStart))
        xmlFile:setValue(key .. "#pendingRepairSystemStressTarget", ADS_Utils.serializeNumericMap(spec.pendingRepairSystemStressTarget))
        xmlFile:setValue(key .. "#pendingRepairSystemStressStartRatio", ADS_Utils.serializeNumericMap(spec.pendingRepairSystemStressStartRatio))

        if spec.maintenanceLog and #spec.maintenanceLog > 0 then
            for i, entry in ipairs(spec.maintenanceLog) do
                local entryKey = string.format("%s.maintenanceLog.entry(%d)", key, i - 1)
                
                xmlFile:setValue(entryKey .. "#id", entry.id or 0)
                xmlFile:setValue(entryKey .. "#type", entry.type or "")
                xmlFile:setValue(entryKey .. "#price", entry.price or 0)
                xmlFile:setValue(entryKey .. "#date", ADS_Utils.serializeDate(entry.date)) 
                xmlFile:setValue(entryKey .. "#location", entry.location or "UNKNOWN")
                xmlFile:setValue(entryKey .. "#optionOne", entry.optionOne or "NONE")
                xmlFile:setValue(entryKey .. "#optionTwo", entry.optionTwo or "NONE")
                xmlFile:setValue(entryKey .. "#optionThree", entry.optionThree or false)
                xmlFile:setValue(entryKey .. "#isVisible", tostring(ADS_Utils.normalizeBoolValue(entry.isVisible, true)))
                xmlFile:setValue(entryKey .. "#isCompleted", ADS_Utils.normalizeBoolValue(entry.isCompleted, true))
                xmlFile:setValue(entryKey .. "#isLegacyEntry", ADS_Utils.normalizeBoolValue(entry.isLegacyEntry, false))

                if entry.conditionData then
                    local condKey = entryKey .. ".conditionData"
                    xmlFile:setValue(condKey .. "#year", entry.conditionData.year or 0)
                    xmlFile:setValue(condKey .. "#operatingHours", entry.conditionData.operatingHours or 0)
                    xmlFile:setValue(condKey .. "#age", entry.conditionData.age or 0)
                    xmlFile:setValue(condKey .. "#condition", entry.conditionData.condition or 1)
                    xmlFile:setValue(condKey .. "#service", entry.conditionData.service or 1)
                    xmlFile:setValue(condKey .. "#reliability", entry.conditionData.reliability or 1)
                    xmlFile:setValue(condKey .. "#maintainability", entry.conditionData.maintainability or 1)
                    xmlFile:setValue(condKey .. "#systems", ADS_Utils.serializeSystemsState(ADS_Utils.createSystemsSnapshot(entry.conditionData.systems)))
                    xmlFile:setValue(condKey .. "#batterySoc", entry.conditionData.batterySoc or 1)

                    if entry.conditionData.activeBreakdowns then
                        xmlFile:setValue(condKey .. "#activeBreakdowns", ADS_Utils.serializeBreakdowns(entry.conditionData.activeBreakdowns))
                    end
                    
                    if entry.conditionData.selectedBreakdowns and #entry.conditionData.selectedBreakdowns > 0 then
                        xmlFile:setValue(condKey .. "#selectedBreakdowns", table.concat(entry.conditionData.selectedBreakdowns, ","))
                    end
                    
                    if entry.conditionData.activeEffects then
                        xmlFile:setValue(condKey .. "#activeEffects", ADS_Utils.serializeEffectSnapshot(entry.conditionData.activeEffects))
                    end
                    
                    if entry.conditionData.activeIndicators then
                        local indKeys = {}
                        for indId, _ in pairs(entry.conditionData.activeIndicators) do 
                            table.insert(indKeys, tostring(indId)) 
                        end
                        xmlFile:setValue(condKey .. "#activeIndicators", table.concat(indKeys, ","))
                    end
                end
            end
        end
        
        log_dbg("Saved service:", spec.serviceLevel, "condition:", spec.conditionLevel)
        log_dbg("Saved breakdowns string:", breakdownString)
    end
end

function AdvancedDamageSystem:onLoad(savegame)
    log_dbg("onLoad called for vehicle:", self:getFullName())
    self.spec_AdvancedDamageSystem.isExcludedVehicle = false
    self.spec_AdvancedDamageSystem.isElectricVehicle = false
    self.spec_AdvancedDamageSystem.isVehicleNeedLubricate = false
    self.spec_AdvancedDamageSystem.isVehicleNeedBlowOut = false

    self.spec_AdvancedDamageSystem.baseServiceLevel = 1.0
    self.spec_AdvancedDamageSystem.baseConditionLevel = 1.0
    self.spec_AdvancedDamageSystem.serviceLevel = self.spec_AdvancedDamageSystem.baseServiceLevel
    self.spec_AdvancedDamageSystem.conditionLevel = self.spec_AdvancedDamageSystem.baseConditionLevel
    self.spec_AdvancedDamageSystem._prevConditionLevel = 0
    self.spec_AdvancedDamageSystem._allowAdsOperatingTimeWrite = false

    self.spec_AdvancedDamageSystem.systems = {
        engine = { name = AdvancedDamageSystem.SYSTEMS.ENGINE, condition = 1.0, stress = 0.0, enabled = true },
        transmission = { name = AdvancedDamageSystem.SYSTEMS.TRANSMISSION, condition = 1.0, stress = 0.0, enabled = true },
        hydraulics = { name = AdvancedDamageSystem.SYSTEMS.HYDRAULICS, condition = 1.0, stress = 0.0, enabled = true },
        cooling = { name = AdvancedDamageSystem.SYSTEMS.COOLING, condition = 1.0, stress = 0.0, enabled = true },
        electrical = { name = AdvancedDamageSystem.SYSTEMS.ELECTRICAL, condition = 1.0, stress = 0.0, enabled = true },
        chassis = { name = AdvancedDamageSystem.SYSTEMS.CHASSIS, condition = 1.0, stress = 0.0, enabled = true },
        workprocess = { name = AdvancedDamageSystem.SYSTEMS.WORKPROCESS, condition = 1.0, stress = 0.0, enabled = true },
        fuel = { name = AdvancedDamageSystem.SYSTEMS.FUEL, condition = 1.0, stress = 0.0, enabled = true }
    }
    self.spec_AdvancedDamageSystem.factorStats = createEmptyFactorStats(self.spec_AdvancedDamageSystem.systems)
    ensureFactorStats(self.spec_AdvancedDamageSystem, self)

    self.spec_AdvancedDamageSystem.extraConditionWear = 0
    self.spec_AdvancedDamageSystem.extraServiceWear = 0
    self.spec_AdvancedDamageSystem.extraBreakdownProbability = 0
    self.spec_AdvancedDamageSystem.extraEngineHeat = 0
    self.spec_AdvancedDamageSystem.extraTransmissionHeat = 0
    self.spec_AdvancedDamageSystem.extraCurrentPeak = 0
    
    self.spec_AdvancedDamageSystem.reliability = 1.0
    self.spec_AdvancedDamageSystem.maintainability = 1.0
    self.spec_AdvancedDamageSystem.year = 2000

    self.spec_AdvancedDamageSystem.activeBreakdowns = {}
    self.spec_AdvancedDamageSystem.activeEffects = {}
    self.spec_AdvancedDamageSystem.activeIndicators = {}
    self.spec_AdvancedDamageSystem.activeFunctions = {}
    self.spec_AdvancedDamageSystem.originalFunctions = {}
    self.spec_AdvancedDamageSystem.dynamicBreakdowns = {}

    self.spec_AdvancedDamageSystem.maintenanceLog = {}
    self.spec_AdvancedDamageSystem.lastInspectedPower = 1
    self.spec_AdvancedDamageSystem.lastInspectedBrake = 1
    self.spec_AdvancedDamageSystem.lastInspectedYieldReduction = 1
    
    self.spec_AdvancedDamageSystem.fuelUsage    = 0
    self.spec_AdvancedDamageSystem._fuelUsageRaw  = 0

    self.spec_AdvancedDamageSystem.startButtonActionEvents = {}
    self.spec_AdvancedDamageSystem.startButtonDown = false
    self.spec_AdvancedDamageSystem.startButtonHeld = false
    self.spec_AdvancedDamageSystem.startButtonUp = false

    self.spec_AdvancedDamageSystem.radiatorClogging = 0.0
    self.spec_AdvancedDamageSystem.airIntakeClogging = 0.0
    self.spec_AdvancedDamageSystem.lubricationLevel = 1.0
    self.spec_AdvancedDamageSystem.lastLubricationDay = nil
    self.spec_AdvancedDamageSystem.lastLubricationProcessedDay = g_currentMission ~= nil
        and g_currentMission.environment ~= nil
        and g_currentMission.environment.currentDay
        or 6

    self.spec_AdvancedDamageSystem.batterySoc = 1.0
    self.spec_AdvancedDamageSystem.batteryChargeAh = nil
    self.spec_AdvancedDamageSystem.batteryHealth = 1.0
    self.spec_AdvancedDamageSystem.batteryCapacityAh = ADS_Config.ELECTRICAL.BATTERY_NOMINAL_CAPACITY
    self.spec_AdvancedDamageSystem.batteryTempC = 0
    self.spec_AdvancedDamageSystem.batteryOpenCircuitVoltageV = 12.7
    self.spec_AdvancedDamageSystem.rawBatteryTerminalVoltageV = 12.7
    self.spec_AdvancedDamageSystem.batteryTerminalVoltageV = 12.7
    self.spec_AdvancedDamageSystem.rawSystemVoltageV = 12.7
    self.spec_AdvancedDamageSystem.systemVoltageV = 12.7
    self.spec_AdvancedDamageSystem.alternatorHealth = 1.0
    self.spec_AdvancedDamageSystem.iAltAvail = 0
    self.spec_AdvancedDamageSystem.iLoads = 0
    self.spec_AdvancedDamageSystem.externalPowerConnection = nil

    self.spec_AdvancedDamageSystem.engineTemperature = -99
    self.spec_AdvancedDamageSystem.rawEngineTemperature = -99
    self.spec_AdvancedDamageSystem._netTargetEngineTemp = nil
    self.spec_AdvancedDamageSystem._smoothedMotorLoad = 0
    self.spec_AdvancedDamageSystem._netMotorLoad = 0
    self.spec_AdvancedDamageSystem.radiatorHealth = 1.0
    self.spec_AdvancedDamageSystem.fanClutchHealth = 1.0
    self.spec_AdvancedDamageSystem.thermostatState = 0.0
    self.spec_AdvancedDamageSystem.thermostatHealth = 1.0
    self.spec_AdvancedDamageSystem.thermostatStuckedPosition = nil
    self.spec_AdvancedDamageSystem.engTermPID = {
        integral = 0,
        lastError = 0
    }

    self.spec_AdvancedDamageSystem.transmissionTemperature = -99
    self.spec_AdvancedDamageSystem.rawTransmissionTemperature = -99
    self.spec_AdvancedDamageSystem._netTargetTransmissionTemp = nil
    self.spec_AdvancedDamageSystem.transmissionThermostatState = 0.0
    self.spec_AdvancedDamageSystem.transmissionThermostatHealth = 1.0
    self.spec_AdvancedDamageSystem.transmissionThermostatStuckedPosition = nil
    self.spec_AdvancedDamageSystem.transTermPID = {
        integral = 0,
        lastError = 0
    }
    self.spec_AdvancedDamageSystem.aiWorkerPid = {
        integral = 0,
        lastError = 0,
        filteredStress = 0,
        currentReduction = 0,
        baseCruiseSpeed = nil,
        applyTimer = 0,
        lastAppliedSpeed = nil
    }

    self.spec_AdvancedDamageSystem.debugData = {
        service = {
            totalWearRate = 0
        },
        condition = 0,
        airIntake = {
            fieldFactor = 1.0,
            dustFactor = 0.0,
            debrisFactor = 0.0,
            wetness = 0,
            wetnessFactor = 1.0,
            baseWetnessFactor = 1.0,
            isOnField = false,
            hasDust = false,
            hasDebris = false,
            totalMultiplier = 0.0
        },
        externalPower = {
            isValidConnection = false,
            distance = 0
        },

        engine = {
            condition = 0,
            stress = 0,
            totalWearRate = 0, 
            expiredServiceFactor = 0,
            breakdownInSystemFactor = 0, 
            motorLoadFactor = 0, 
            coldMotorFactor = 0, 
            hotMotorFactor = 0,
            breakdownProbability = 0,
            critBreakdownProbability = 0
        },

        transmission = {
            condition = 0,
            stress = 0,
            totalWearRate = 0, 
            expiredServiceFactor = 0,
            breakdownInSystemFactor = 0,
            pullOverloadFactor = 0,
            heavyTrailerFactor = 0,
            heavyTrailerMassRatio = 0,
            upHillLoadFactor = 0,
            wheelSlipFactor = 0,
            wheelSlipIntensity = 0,
            luggingFactor = 0,
            coldMotorFactor = 0,
            breakdownProbability = 0,
            critBreakdownProbability = 0,
            pullOverloadTimer = 0
        },

        hydraulics = {
            condition = 0,
            stress = 0,
            totalWearRate = 0,
            expiredServiceFactor = 0,
            heavyLiftFactor = 0,
            heavyLiftMassRatio = 0,
            operatingFactor = 0,
            coldOilFactor = 0,
            ptoOperatingFactor = 0,
            sharpAngleFactor = 0,
            ptoSharpAngleDeg = 0,
            breakdownInSystemFactor = 0, 
            breakdownProbability = 0,
            critBreakdownProbability = 0
        },

        cooling = {
            condition = 0,
            stress = 0,
            totalWearRate = 0,
            expiredServiceFactor = 0,
            highCoolingFactor = 0,
            overheatFactor = 0,
            coldShockFactor = 0,
            breakdownInSystemFactor = 0, 
            breakdownProbability = 0,
            critBreakdownProbability = 0
        },

        electrical = {
            condition = 0,
            stress = 0,
            totalWearRate = 0,
            expiredServiceFactor = 0,
            lightsFactor = 0,
            crankingStressFactor = 0,
            overheatFactor = 0,
            breakdownInSystemFactor = 0, 
            breakdownProbability = 0,
            critBreakdownProbability = 0
        },

        chassis = {
            condition = 0,
            stress = 0,
            totalWearRate = 0,
            expiredServiceFactor = 0,
            vibFactor = 0,
            vibSignal = 0,
            vibRaw = 0,
            vibWheelCount = 0,
            vibSpeedFactor = 0,
            vibSpeedKmh = 0,
            vibAvgDensityType = 0,
            vibFieldMultiplier = 1,
            steerLoadFactor = 0,
            steerInputAbs = 0,
            steerDeltaRate = 0,
            steerLowSpeedFactor = 0,
            steerAngleFactor = 0,
            steerChangeFactor = 0,
            steerGroundContact = 0,
            brakeMassFactor = 0,
            brakeMassRatio = 0,
            brakePedal = 0,
            parkingBrakeFactor = 0,
            parkingBrakeActive = 0,
            breakdownInSystemFactor = 0, 
            breakdownProbability = 0,
            critBreakdownProbability = 0
        },

        workprocess = {
            condition = 0,
            stress = 0,
            totalWearRate = 0,
            expiredServiceFactor = 0,
            wetCropFactor = 0,
            currentHarvestRatio = 1.0,
            currentHarvestPercent = 100.0,
            lastUnloadOriginalFactor = 1.0,
            lastUnloadFactor = 1.0,
            lastUnloadPercent = 100.0,
            breakdownInSystemFactor = 0, 
            breakdownProbability = 0,
            critBreakdownProbability = 0
        },

        fuel = {
            condition = 0,
            stress = 0,
            totalWearRate = 0,
            expiredServiceFactor = 0,
            lowFuelStarvationFactor = 0,
            coldFuelFactor = 0,
            idleDepositFactor = 0,
            highPressureFactor = 0,
            idleTimer = 0,
            fuelLevel = 0,
            fuelTemperature = 0,
            breakdownInSystemFactor = 0, 
            breakdownProbability = 0,
            critBreakdownProbability = 0
        },

        battery = {
            soc = 1.0,
            iAltAvail = 0,
            iLoads = 0,
            baseLoadA = 0,
            lightsLoadA = 0,
            cabFanA = 0,
            winterHeaterA = 0,
            peakPulseA = 0,
            iNet = 0,
            dAh = 0,
            altFactor = 0
        },

        radiator = {
            fieldFactor = 1.0,
            dustFactor = 0.0,
            debrisFactor = 0.0,
            workFactor = 1.0,
            wetness = 0,
            wetnessFactor = 1.0,
            baseWetnessFactor = 1.0,
            isOnField = false,
            hasDust = false,
            hasDebris = false,
            totalMultiplier = 0.0
        },

        engineTemp = {
            totalHeat = 0, 
            totalCooling = 0, 
            radiatorCooling = 0, 
            speedCooling = 0, 
            convectionCooling = 0,
            stiction = 0,
            waxSpeed = 0,
            kp = 0
        },

        transmissionTemp = {
            totalHeat = 0, 
            totalCooling = 0, 
            radiatorCooling = 0, 
            speedCooling = 0, 
            convectionCooling = 0,
            loadFactor = 0,
            slipFactor = 0,
            pullFactor = 0,
            wheelSlipFactor = 0,
            accFactor = 0,
            speedLimit = 0,
            cvtSlipActive = 0,
            cvtSlipLocked = 0,
            extraTransmissionHeat = 0,
            stiction = 0,
            waxSpeed = 0,
            kp = 0
        },

        aiWorker = {
            stress = 0,
            filteredStress = 0,
            error = 0,
            integral = 0,
            derivative = 0,
            reduction = 0,
            targetSpeed = 0,
            appliedSpeed = 0,
            baseCruiseSpeed = 0,
            loadStress = 0,
            engineStress = 0,
            transStress = 0
        }
    }

    self.spec_AdvancedDamageSystem.isUnderRoof = true
    self.spec_AdvancedDamageSystem.effectsUpdateTimer = ADS_Config.EFFECTS_UPDATE_DELAY
    self.spec_AdvancedDamageSystem.metaUpdateTimer = math.random() * ADS_Config.META_UPDATE_DELAY
    self.spec_AdvancedDamageSystem.maintenanceTimer = 0
    self.spec_AdvancedDamageSystem.currentState = AdvancedDamageSystem.STATUS.READY
    self.spec_AdvancedDamageSystem.plannedState = AdvancedDamageSystem.STATUS.READY
    self.spec_AdvancedDamageSystem.workshopType = AdvancedDamageSystem.WORKSHOP.DEALER
    self.spec_AdvancedDamageSystem.serviceOptionOne = nil
    self.spec_AdvancedDamageSystem.serviceOptionTwo = nil
    self.spec_AdvancedDamageSystem.serviceOptionThree = false
    self.spec_AdvancedDamageSystem.pendingSelectedBreakdowns = {}
    self.spec_AdvancedDamageSystem.pendingServicePrice = nil
    self.spec_AdvancedDamageSystem.pendingInspectionQueue = {}
    self.spec_AdvancedDamageSystem.pendingRepairQueue = {}
    self.spec_AdvancedDamageSystem.pendingProgressStepIndex = 0
    self.spec_AdvancedDamageSystem.pendingProgressTotalTime = 0
    self.spec_AdvancedDamageSystem.pendingProgressElapsedTime = 0
    self.spec_AdvancedDamageSystem.pendingMaintenanceServiceStart = nil
    self.spec_AdvancedDamageSystem.pendingMaintenanceServiceTarget = nil
    self.spec_AdvancedDamageSystem.pendingPreventiveSystemStressStart = {}
    self.spec_AdvancedDamageSystem.pendingPreventiveSystemStressTarget = {}
    self.spec_AdvancedDamageSystem.pendingOverhaulSystemStart = {}
    self.spec_AdvancedDamageSystem.pendingOverhaulSystemTarget = {}
    self.spec_AdvancedDamageSystem.pendingOverhaulSystemStressStart = {}
    self.spec_AdvancedDamageSystem.pendingOverhaulSystemStressTarget = {}
    self.spec_AdvancedDamageSystem.pendingRepairSystemStressStart = {}
    self.spec_AdvancedDamageSystem.pendingRepairSystemStressTarget = {}
    self.spec_AdvancedDamageSystem.pendingRepairSystemStressStartRatio = {}
    self.spec_AdvancedDamageSystem.hydraulicsMoveAlphaCache = {}
    self.spec_AdvancedDamageSystem.chassisVibState = {
        prevSuspension = {},
        smoothed = 0
    }

    -- Dirty flags for network differential sync
    if self.isServer then
        self.spec_AdvancedDamageSystem.adsDirtyFlag_state = self:getNextDirtyFlag()             -- [1] currentState, plannedState, maintenanceTimer
        self.spec_AdvancedDamageSystem.adsDirtyFlag_serviceContext = self:getNextDirtyFlag()    -- [2] serviceOptionOne, serviceOptionTwo, serviceOptionThree, workshopType
        self.spec_AdvancedDamageSystem.adsDirtyFlag_telemetry = self:getNextDirtyFlag()         -- [3] operatingTime, _fuelUsageRaw, _netMotorLoad -- [5] telemetry
        self.spec_AdvancedDamageSystem.adsDirtyFlag_thermal = self:getNextDirtyFlag()           -- [4] rawEngineTemperature, rawTransmissionTemperature, thermostatState, transmissionThermostatState
        self.spec_AdvancedDamageSystem.adsDirtyFlag_electrical = self:getNextDirtyFlag()        -- [5] batterySoc, batteryChargeAh, batteryTerminalVoltageV, systemVoltageV
        self.spec_AdvancedDamageSystem.adsDirtyFlag_fieldcare = self:getNextDirtyFlag()         -- [6] radiatorClogging, airIntakeClogging, lubricationLevel
        self.spec_AdvancedDamageSystem.adsDirtyFlag_wear = self:getNextDirtyFlag()              -- [7] serviceLevel, conditionLevel, systems[...].condition, systems[...].stress
        self.spec_AdvancedDamageSystem.adsDirtyFlag_breakdowns = self:getNextDirtyFlag()        -- [8] activeBreakdowns
        self.spec_AdvancedDamageSystem.adsDirtyFlag_serviceProgress = self:getNextDirtyFlag()   -- [9] pendingProgressElapsedTime, pendingProgressTotalTime, pendingProgressStepIndex
    end
end

function AdvancedDamageSystem:onPostLoad(savegame)
    log_dbg("onPostLoad called for vehicle:", self:getFullName())
    local spec = self.spec_AdvancedDamageSystem

    spec.isExcludedVehicle = getIsExcludedFromADS(self)
    if spec.isExcludedVehicle then return end

    if spec ~= nil and savegame ~= nil then
        local key = savegame.key .. ".AdvancedDamageSystem"

        log_dbg("Attempting to load from key:", key)

        spec.serviceLevel = savegame.xmlFile:getValue(key .. "#service", spec.serviceLevel)
        spec.conditionLevel = savegame.xmlFile:getValue(key .. "#condition", spec.conditionLevel)
        spec.currentState = savegame.xmlFile:getValue(key .. "#state", spec.currentState)
        spec.plannedState = savegame.xmlFile:getValue(key .. "#plannedState", spec.plannedState)
        spec.maintenanceTimer = savegame.xmlFile:getValue(key .. "#maintenanceTimer", spec.maintenanceTimer) 

        -- Load Breakdowns
        local breakdownString = savegame.xmlFile:getValue(key .. "#breakdowns", "")
        if breakdownString and breakdownString ~= "" then
            spec.activeBreakdowns = ADS_Utils.deserializeBreakdowns(breakdownString)
        else
            spec.activeBreakdowns = {}
        end

        -- Load Simple Variables
        spec.engineTemperature = savegame.xmlFile:getValue(key .. "#engineTemperature", spec.engineTemperature)
        spec.transmissionTemperature = savegame.xmlFile:getValue(key .. "#transmissionTemperature", spec.transmissionTemperature)
        spec.batterySoc = math.clamp(savegame.xmlFile:getValue(key .. "#batterySoc", spec.batterySoc), 0, 1)
        spec.batteryChargeAh = savegame.xmlFile:getValue(key .. "#batteryChargeAh", nil)
        spec.batteryTempC = savegame.xmlFile:getValue(key .. "#batteryTempC", spec.batteryTempC)
        spec.radiatorClogging = math.max(savegame.xmlFile:getValue(key .. "#radiatorClogging", spec.radiatorClogging), 0)
        spec.airIntakeClogging = math.max(savegame.xmlFile:getValue(key .. "#airIntakeClogging", spec.airIntakeClogging), 0)
        spec.lubricationLevel = math.clamp(savegame.xmlFile:getValue(key .. "#lubricationLevel", spec.lubricationLevel), 0.0, 1.0)
        spec.lastLubricationProcessedDay = savegame.xmlFile:getValue(
            key .. "#lastLubricationProcessedDay",
            g_currentMission ~= nil and g_currentMission.environment ~= nil and g_currentMission.environment.currentDay or spec.lastLubricationProcessedDay or 0
        )
        spec.thermostatState = math.clamp(savegame.xmlFile:getValue(key .. "#thermostatState", spec.thermostatState), 0.0, 1.0)
        spec.transmissionThermostatState = math.clamp(savegame.xmlFile:getValue(key .. "#transmissionThermostatState", spec.transmissionThermostatState), 0.0, 1.0)
        if spec.engTermPID ~= nil then
            spec.engTermPID.mechPos = spec.thermostatState
        end
        if spec.transTermPID ~= nil then
            spec.transTermPID.mechPos = spec.transmissionThermostatState
        end
        spec.lastInspectedPower = savegame.xmlFile:getValue(key .. "#lastInspPwr", spec.lastInspectedPower)
        spec.lastInspectedBrake = savegame.xmlFile:getValue(key .. "#lastInspBrk", spec.lastInspectedBrake)
        spec.lastInspectedYieldReduction = savegame.xmlFile:getValue(key .. "#lastInspYld", spec.lastInspectedYieldReduction)
        spec.serviceOptionOne = savegame.xmlFile:getValue(key .. "#serviceOptionOne", spec.serviceOptionOne)
        spec.serviceOptionTwo = savegame.xmlFile:getValue(key .. "#serviceOptionTwo", spec.serviceOptionTwo)
        if spec.serviceOptionOne == "" then spec.serviceOptionOne = nil end
        if spec.serviceOptionTwo == "" then spec.serviceOptionTwo = nil end
        spec.serviceOptionThree = savegame.xmlFile:getValue(key .. "#serviceOptionThree", spec.serviceOptionThree)
        local loadedWorkshopType = savegame.xmlFile:getValue(key .. "#workshopType", "")
        if loadedWorkshopType ~= nil and loadedWorkshopType ~= "" then
            spec.workshopType = loadedWorkshopType
        end
        spec.pendingServicePrice = ADS_Utils.decodeOptionalFloat(savegame.xmlFile:getValue(key .. "#pendingServicePrice", spec.pendingServicePrice))
        spec.pendingSelectedBreakdowns = {}
        local pendingSelBdStr = savegame.xmlFile:getValue(key .. "#pendingSelectedBreakdowns", "")
        if pendingSelBdStr ~= nil and pendingSelBdStr ~= "" then
            for item in string.gmatch(pendingSelBdStr, "([^,]+)") do
                table.insert(spec.pendingSelectedBreakdowns, item)
            end
        end
        spec.pendingInspectionQueue = {}
        local pendingInspectionQueueStr = savegame.xmlFile:getValue(key .. "#pendingInspectionQueue", "")
        if pendingInspectionQueueStr ~= nil and pendingInspectionQueueStr ~= "" then
            for item in string.gmatch(pendingInspectionQueueStr, "([^,]+)") do
                table.insert(spec.pendingInspectionQueue, item)
            end
        end

        spec.pendingRepairQueue = {}
        local pendingRepairQueueStr = savegame.xmlFile:getValue(key .. "#pendingRepairQueue", "")
        if pendingRepairQueueStr ~= nil and pendingRepairQueueStr ~= "" then
            for item in string.gmatch(pendingRepairQueueStr, "([^,]+)") do
                table.insert(spec.pendingRepairQueue, item)
            end
        end

        spec.pendingProgressStepIndex = savegame.xmlFile:getValue(key .. "#pendingProgressStepIndex", spec.pendingProgressStepIndex)
        spec.pendingProgressTotalTime = savegame.xmlFile:getValue(key .. "#pendingProgressTotalTime", spec.pendingProgressTotalTime)
        spec.pendingProgressElapsedTime = savegame.xmlFile:getValue(key .. "#pendingProgressElapsedTime", spec.pendingProgressElapsedTime)
        spec.pendingMaintenanceServiceStart = ADS_Utils.decodeOptionalFloat(savegame.xmlFile:getValue(key .. "#pendingMaintenanceServiceStart", spec.pendingMaintenanceServiceStart))
        spec.pendingMaintenanceServiceTarget = ADS_Utils.decodeOptionalFloat(savegame.xmlFile:getValue(key .. "#pendingMaintenanceServiceTarget", spec.pendingMaintenanceServiceTarget))
        spec.pendingPreventiveSystemStressStart = ADS_Utils.deserializeNumericMap(savegame.xmlFile:getValue(key .. "#pendingPreventiveSystemStressStart", ""))
        spec.pendingPreventiveSystemStressTarget = ADS_Utils.deserializeNumericMap(savegame.xmlFile:getValue(key .. "#pendingPreventiveSystemStressTarget", ""))
        spec.pendingOverhaulSystemStart = ADS_Utils.deserializeNumericMap(savegame.xmlFile:getValue(key .. "#pendingOverhaulSystemStart", ""))
        spec.pendingOverhaulSystemTarget = ADS_Utils.deserializeNumericMap(savegame.xmlFile:getValue(key .. "#pendingOverhaulSystemTarget", ""))
        spec.pendingOverhaulSystemStressStart = ADS_Utils.deserializeNumericMap(savegame.xmlFile:getValue(key .. "#pendingOverhaulSystemStressStart", ""))
        spec.pendingOverhaulSystemStressTarget = ADS_Utils.deserializeNumericMap(savegame.xmlFile:getValue(key .. "#pendingOverhaulSystemStressTarget", ""))
        spec.pendingRepairSystemStressStart = ADS_Utils.deserializeNumericMap(savegame.xmlFile:getValue(key .. "#pendingRepairSystemStressStart", ""))
        spec.pendingRepairSystemStressTarget = ADS_Utils.deserializeNumericMap(savegame.xmlFile:getValue(key .. "#pendingRepairSystemStressTarget", ""))
        spec.pendingRepairSystemStressStartRatio = ADS_Utils.deserializeNumericMap(savegame.xmlFile:getValue(key .. "#pendingRepairSystemStressStartRatio", ""))
        local loadedFactorStatsFlat = ADS_Utils.deserializeNumericMap(savegame.xmlFile:getValue(key .. "#factorStats", ""))

        local loadedSystemsStateRaw = ADS_Utils.deserializeSystemsState(savegame.xmlFile:getValue(key .. "#systemsState", ""))
        local loadedSystemsState = {}
        for loadedKey, loadedData in pairs(loadedSystemsStateRaw) do
            loadedSystemsState[string.lower(tostring(loadedKey))] = loadedData
        end
        local hasSerializedSystemsState = next(loadedSystemsState) ~= nil

        if spec.systems == nil then
            spec.systems = {}
        end
        for systemKey, systemData in pairs(spec.systems) do
            if type(systemData) ~= "table" then
                systemData = {
                    condition = tonumber(systemData) or 1.0,
                    stress = 0.0,
                    enabled = true
                }
                spec.systems[systemKey] = systemData
            end

            local loadedData = loadedSystemsState[string.lower(tostring(systemKey))]
            if loadedData ~= nil then
                systemData.condition = math.clamp(tonumber(loadedData.condition) or systemData.condition or 1.0, 0.001, 1.0)
                systemData.stress = math.max(tonumber(loadedData.stress) or systemData.stress or 0.0, 0.0)
                systemData.enabled = ADS_Utils.normalizeBoolValue(loadedData.enabled, systemData.enabled ~= false)
            else
                if not hasSerializedSystemsState and spec.conditionLevel ~= nil then
                    systemData.condition = math.clamp(tonumber(spec.conditionLevel) or systemData.condition or 1.0, 0.001, 1.0)
                else
                    systemData.condition = math.clamp(tonumber(systemData.condition) or 1.0, 0.001, 1.0)
                end
                systemData.stress = math.max(tonumber(systemData.stress) or 0.0, 0.0)
                systemData.enabled = ADS_Utils.normalizeBoolValue(systemData.enabled, true)
            end

            systemData.name = ADS_Utils.getSystemNameByKey(AdvancedDamageSystem.SYSTEMS, systemKey)
        end
        ensureFactorStats(spec, self)
        applyFlattenedFactorStats(spec, loadedFactorStatsFlat)
        ensureFactorStats(spec, self)

        -- Load Maintenance Log
        spec.maintenanceLog = {}
        local i = 0
        while true do
            local entryKey = string.format("%s.maintenanceLog.entry(%d)", key, i)
            if not savegame.xmlFile:hasProperty(entryKey) then
                break
            end

            local entry = {
                id = savegame.xmlFile:getValue(entryKey .. "#id"),
                type = savegame.xmlFile:getValue(entryKey .. "#type"),
                price = savegame.xmlFile:getValue(entryKey .. "#price"),
                date = ADS_Utils.deserializeDate(savegame.xmlFile:getValue(entryKey .. "#date")),
                conditionData = {}
            }
            local condKey = entryKey .. ".conditionData"
            local hasConditionData = savegame.xmlFile:hasProperty(condKey)

            if hasConditionData then
                entry.location = savegame.xmlFile:getValue(entryKey .. "#location", "UNKNOWN")
                entry.optionOne = savegame.xmlFile:getValue(entryKey .. "#optionOne", "NONE")
                entry.optionTwo = savegame.xmlFile:getValue(entryKey .. "#optionTwo", "NONE")
                entry.optionThree = savegame.xmlFile:getValue(entryKey .. "#optionThree", false)
                entry.isVisible = ADS_Utils.normalizeBoolValue(savegame.xmlFile:getValue(entryKey .. "#isVisible", true), true)
                entry.isCompleted = ADS_Utils.normalizeBoolValue(savegame.xmlFile:getValue(entryKey .. "#isCompleted", true), true)
                entry.isLegacyEntry = ADS_Utils.normalizeBoolValue(savegame.xmlFile:getValue(entryKey .. "#isLegacyEntry", false), false)

                entry.conditionData.year = savegame.xmlFile:getValue(condKey .. "#year", 0)
                entry.conditionData.operatingHours = savegame.xmlFile:getValue(condKey .. "#operatingHours", 0)
                entry.conditionData.age = savegame.xmlFile:getValue(condKey .. "#age", 0)
                entry.conditionData.condition = savegame.xmlFile:getValue(condKey .. "#condition", 1)
                entry.conditionData.service = savegame.xmlFile:getValue(condKey .. "#service", 1)
                entry.conditionData.reliability = savegame.xmlFile:getValue(condKey .. "#reliability", 1)
                entry.conditionData.maintainability = savegame.xmlFile:getValue(condKey .. "#maintainability", 1)
                entry.conditionData.systems = ADS_Utils.createSystemsSnapshot(ADS_Utils.deserializeSystemsState(savegame.xmlFile:getValue(condKey .. "#systems", "")))
                entry.conditionData.batterySoc = savegame.xmlFile:getValue(condKey .. "#batterySoc", 1)

                local bdStr = savegame.xmlFile:getValue(condKey .. "#activeBreakdowns", "")
                entry.conditionData.activeBreakdowns = ADS_Utils.deserializeBreakdowns(bdStr) or {}

                local selBdStr = savegame.xmlFile:getValue(condKey .. "#selectedBreakdowns", "")
                entry.conditionData.selectedBreakdowns = ADS_Utils.parseCsvList(selBdStr)

                entry.conditionData.activeEffects = ADS_Utils.deserializeEffectSnapshot(savegame.xmlFile:getValue(condKey .. "#activeEffects", ""))

                entry.conditionData.activeIndicators = {}
                local indicatorIds = ADS_Utils.parseCsvList(savegame.xmlFile:getValue(condKey .. "#activeIndicators", ""))
                for _, indId in ipairs(indicatorIds) do
                    entry.conditionData.activeIndicators[indId] = true
                end
            else
                -- COMPAT(0.8.5.0): migrate legacy maintenance log entry format (hours/aftermarket/breakdowns/info).
                -- Remove this migration branch after legacy save migration window is over.
                local legacyAftermarket = ADS_Utils.normalizeBoolValue(savegame.xmlFile:getValue(entryKey .. "#aftermarket", false), false)
                local legacyOperatingHours = ADS_Utils.normalizeNumberValue(savegame.xmlFile:getValue(entryKey .. "#hours", 0), 0)
                local legacyBreakdowns = ADS_Utils.parseCsvList(savegame.xmlFile:getValue(entryKey .. "#breakdowns", ""))

                local optionOne = "NONE"
                local optionTwo = legacyAftermarket and AdvancedDamageSystem.PART_TYPES.AFTERMARKET or AdvancedDamageSystem.PART_TYPES.OEM
                local optionThree = false

                if entry.type == AdvancedDamageSystem.STATUS.INSPECTION then
                    optionOne = AdvancedDamageSystem.INSPECTION_TYPES.STANDARD
                    optionTwo = "NONE"
                elseif entry.type == AdvancedDamageSystem.STATUS.MAINTENANCE then
                    optionOne = AdvancedDamageSystem.MAINTENANCE_TYPES.STANDARD
                elseif entry.type == AdvancedDamageSystem.STATUS.REPAIR then
                    optionOne = AdvancedDamageSystem.REPAIR_TYPES.MEDIUM
                elseif entry.type == AdvancedDamageSystem.STATUS.OVERHAUL then
                    optionOne = AdvancedDamageSystem.OVERHAUL_TYPES.STANDARD
                else
                    optionTwo = "NONE"
                end

                entry.location = "UNKNOWN"
                entry.optionOne = optionOne
                entry.optionTwo = optionTwo
                entry.optionThree = optionThree
                entry.isVisible = true
                entry.isCompleted = true
                entry.isLegacyEntry = true

                entry.conditionData.year = spec.year or 0
                entry.conditionData.operatingHours = legacyOperatingHours
                entry.conditionData.age = self.age or 0
                entry.conditionData.condition = 1
                entry.conditionData.service = 1
                entry.conditionData.systems = {}
                entry.conditionData.batterySoc = 1
                entry.conditionData.activeBreakdowns = {}
                entry.conditionData.selectedBreakdowns = legacyBreakdowns
                entry.conditionData.activeEffects = {}
                entry.conditionData.activeIndicators = {}
                entry.conditionData.reliability = spec.reliability or 1
                entry.conditionData.maintainability = spec.maintainability or 1
            end

            table.insert(spec.maintenanceLog, entry)
            i = i + 1
        end

        -- Fill defaults
        if spec.serviceLevel == nil then spec.serviceLevel = spec.baseServiceLevel end
        if spec.conditionLevel == nil then spec.conditionLevel = spec.baseConditionLevel end
        if spec.maintenanceTimer == nil then spec.maintenanceTimer = 0 end
        if spec.currentState == nil then spec.currentState = AdvancedDamageSystem.STATUS.READY end
        if spec.plannedState == nil then spec.plannedState = AdvancedDamageSystem.STATUS.READY end
        if spec.serviceOptionThree == nil then spec.serviceOptionThree = false end
        if spec.pendingSelectedBreakdowns == nil then spec.pendingSelectedBreakdowns = {} end
        if spec.pendingInspectionQueue == nil then spec.pendingInspectionQueue = {} end
        if spec.pendingRepairQueue == nil then spec.pendingRepairQueue = {} end
        if spec.pendingProgressStepIndex == nil then spec.pendingProgressStepIndex = 0 end
        if spec.pendingProgressTotalTime == nil then spec.pendingProgressTotalTime = 0 end
        if spec.pendingProgressElapsedTime == nil then spec.pendingProgressElapsedTime = 0 end
        if spec.pendingPreventiveSystemStressStart == nil then spec.pendingPreventiveSystemStressStart = {} end
        if spec.pendingPreventiveSystemStressTarget == nil then spec.pendingPreventiveSystemStressTarget = {} end
        if spec.pendingOverhaulSystemStart == nil then spec.pendingOverhaulSystemStart = {} end
        if spec.pendingOverhaulSystemTarget == nil then spec.pendingOverhaulSystemTarget = {} end
        if spec.pendingOverhaulSystemStressStart == nil then spec.pendingOverhaulSystemStressStart = {} end
        if spec.pendingOverhaulSystemStressTarget == nil then spec.pendingOverhaulSystemStressTarget = {} end
        if spec.pendingRepairSystemStressStart == nil then spec.pendingRepairSystemStressStart = {} end
        if spec.pendingRepairSystemStressTarget == nil then spec.pendingRepairSystemStressTarget = {} end
        if spec.pendingRepairSystemStressStartRatio == nil then spec.pendingRepairSystemStressStartRatio = {} end
        if spec.aiWorkerPid == nil then
            spec.aiWorkerPid = {
                integral = 0,
                lastError = 0,
                filteredStress = 0,
                currentReduction = 0,
                baseCruiseSpeed = nil,
                applyTimer = 0,
                lastAppliedSpeed = nil
            }
        end
        self:updateConditionLevel()
    end

    spec.isUnderRoof = self:isUnderRoof()

    spec.fieldInspection = spec.fieldInspection or {
        isActive = false,
        elapsedTime = 0,
        duration = ADS_Config.FIELD_CARE.FIELD_INSPECTION_DURATION,
        startTime = 0,
        targetNode = nil,
        targetVehicle = nil,
        wasSoundStarted = false
    }

    -- Sounds Loading
    local xmlSoundFile = loadXMLFile("ads_sounds", AdvancedDamageSystem.modDirectory .. "sounds/ads_sounds.xml")
    if spec.samples == nil then
        spec.samples = {}
    end
    
    if xmlSoundFile ~= nil then
        local soundManager = g_soundManager
        local modDir = AdvancedDamageSystem.modDirectory
        local root = self.rootNode
        local i3d = self.i3dMappings
        
        spec.samples.starter = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "starter", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.starterCranking = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "starterCranking", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.starterCrankingEnd = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "starterCrankingEnd", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.alarm = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "alarm", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.transmissionShiftFailed1 = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "transmissionShiftFailed1", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.transmissionShiftFailed2 = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "transmissionShiftFailed2", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.transmissionShiftFailed3 = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "transmissionShiftFailed3", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.brakes1 = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "brakes1", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.brakes2 = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "brakes2", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.brakes3 = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "brakes3", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.turboWhistle = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "turboWhistle", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.fanNoice = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "fanNoice", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.wheelHubBearingNoise = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "wheelHubBearingNoise", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.vibrationNoice = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "vibrationNoice", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.wheelSeizureGrind = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "wheelSeizureGrind", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.gearDisengage1 = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "gearDisengage1", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.engineKnocking = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "engineKnocking", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.valveTrainNoise = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "valveTrainNoise", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.inspection = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "inspection", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        delete(xmlSoundFile)
    else
        log_dbg("ERROR: AdvancedDamageSystem - Could not load ads_sounds.xml")
    end

    spec.rawEngineTemperature = spec.engineTemperature
    spec.rawTransmissionTemperature = spec.transmissionTemperature

    spec.isElectricVehicle = getIsElectricVehicle(self)
    spec.hydraulicsMoveAlphaCache = {}

    local function resetIsMovingRecursive(vehicleObj, visited)
        if vehicleObj == nil or visited[vehicleObj] then
            return
        end
        visited[vehicleObj] = true

        if vehicleObj.spec_attacherJoints ~= nil then
            if vehicleObj.spec_attacherJoints.attacherJoints ~= nil then
                for _, jointDesc in pairs(vehicleObj.spec_attacherJoints.attacherJoints) do
                    if jointDesc ~= nil then
                        jointDesc.isMoving = false
                    end
                end
            end

            if vehicleObj.spec_attacherJoints.attachedImplements ~= nil then
                for _, implementData in pairs(vehicleObj.spec_attacherJoints.attachedImplements) do
                    if implementData ~= nil and implementData.object ~= nil then
                        resetIsMovingRecursive(implementData.object, visited)
                    end
                end
            end
        end
    end

    local function enableOrDisableSystems(vehicle)
        local spec = vehicle.spec_AdvancedDamageSystem
        for _, systemData in pairs(spec.systems) do
            -- disable engine for electric vehicles
            if systemData.name == AdvancedDamageSystem.SYSTEMS.ENGINE then
                if spec.isElectricVehicle then
                    systemData.enabled = false
                end
            -- disable transsmision for electric vehicles
            elseif systemData.name == AdvancedDamageSystem.SYSTEMS.TRANSMISSION then
                if spec.isElectricVehicle then
                    systemData.enabled = false
                end
            -- disable hydralic for trucks, cars, motorbikes
            elseif systemData.name == AdvancedDamageSystem.SYSTEMS.HYDRAULICS then
                local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
                local vtype = vehicle.type.name
                if storeItem.categoryName == "TRUCKS" or vtype == "car" or vtype == "carFillable" or vtype == "motorbike" then
                    systemData.enabled = false
                end
            -- disable cooling for trucks, cars, motorbikes
            elseif systemData.name == AdvancedDamageSystem.SYSTEMS.COOLING then
                if spec.isElectricVehicle then
                    systemData.enabled = false
                end
            -- electrical is  applicable for all vehicles
            elseif systemData.name == AdvancedDamageSystem.SYSTEMS.ELECTRICAL then
            -- chassis is applicable for all vehicles
            elseif systemData.name == AdvancedDamageSystem.SYSTEMS.CHASSIS  then
            --- disable fuel system for electric vehicles
            elseif systemData.name == AdvancedDamageSystem.SYSTEMS.FUEL then
                if spec.isElectricVehicle then
                    systemData.enabled = false
                end
            --- disables workprocess systems for tractors, cars etc.
            elseif systemData.name == AdvancedDamageSystem.SYSTEMS.WORKPROCESS then
                local vtype = vehicle.type.name
                if  vtype ~= 'combineDrivable' and
                    vtype ~= 'combineCutter' and 
                    vtype ~= 'combineCutterFruitPreparer' and -- add to yield sensor breakdown and test
                    vtype ~= 'cottonHarvester' and -- add to yield sensor breakdown and test
                    vtype ~= 'riceHarvester' and -- add to yield sensor breakdown and test
                    vtype ~= 'vineHarvester' then -- add to yield sensor breakdown and test

                        systemData.enabled = false
                        -- ricePlanter
                        -- balerDrivable
                        -- selfPropelledMower
                        -- woodHarvester
                end
            else
                systemData.enabled = true
            end
        end
    end

    enableOrDisableSystems(self)
    spec.isVehicleNeedLubricate = getIsVehicleNeedLubticate(self)
    spec.isVehicleNeedBlowOut = getIsVehicleNeedBlowOut(self)
    resetIsMovingRecursive(self, {})

    --- for deneral wear and tear calculations
    spec._prevConditionLevel = self:getConditionLevel()

    --- for dirty-flag comparison
    --- [1] state
    spec._lastSyncState_currentState = spec.currentState
    spec._lastSyncState_plannedState = spec.plannedState
    spec._lastSyncState_maintenanceTimer = spec.maintenanceTimer
    --- [2] service context
    spec._lastSyncServiceContext_optionOne = spec.serviceOptionOne
    spec._lastSyncServiceContext_optionTwo = spec.serviceOptionTwo
    spec._lastSyncServiceContext_optionThree = spec.serviceOptionThree
    spec._lastSyncServiceContext_workshopType = spec.workshopType
    --- [3] telemetry
    spec._lastSyncTelemetry_operatingTime = getSyncOperatingTime(self)
    spec._lastSyncTelemetry_fuelUsageRaw = spec._fuelUsageRaw
    spec._lastSyncTelemetry_motorLoad  = getSyncMotorLoad(self)
    --- [4] thermal
    spec._lastSyncThermal_rawEngineTemperature = spec.rawEngineTemperature
    spec._lastSyncThermal_rawTransmissionTemperature = spec.rawTransmissionTemperature
    spec._lastSyncThermal_thermostatState = spec.thermostatState
    spec._lastSyncThermal_transmissionThermostatState = spec.transmissionThermostatState
    --- [5] electrical
    spec._lastSyncElectrical_batterySoc = spec.batterySoc
    spec._lastSyncElectrical_batteryChargeAh = spec.batteryChargeAh
    spec._lastSyncElectrical_batteryTerminalVoltage = spec.batteryTerminalVoltageV
    spec._lastSyncElectrical_systemVoltage = spec.systemVoltageV
    --- [6] fieldcare
    spec._lastSyncFieldcare_radiatorClogging = spec.radiatorClogging
    spec._lastSyncFieldcare_airIntakeClogging = spec.airIntakeClogging
    spec._lastSyncFieldcare_lubricationLevel = spec.lubricationLevel
    --- [7] wear
    spec._lastSyncWear_serviceLevel = spec.serviceLevel
    spec._lastSyncWear_conditionLevel = spec.conditionLevel
    spec._lastSyncWear_systemsHash = computeSystemSyncHash(self)
    --- [8] breakdowns
    spec._lastSyncBreakdowns_serialized = ADS_Utils.serializeBreakdowns(spec.activeBreakdowns or {})
    --- [9] service
    spec._lastSyncServiceProgress_elapsed = spec.pendingProgressElapsedTime
    spec._lastSyncServiceProgress_step = spec.pendingProgressStepIndex
    spec._lastSyncServiceProgress_total = spec.pendingProgressTotalTime

    self:recalculateAndApplyEffects()
end

function AdvancedDamageSystem:onDelete()
    log_dbg("onDelete called for vehicle:", self:getFullName(), "ID:", self.uniqueId)
    local spec = self.spec_AdvancedDamageSystem

    if spec and spec.samples then
        g_soundManager:deleteSamples(spec.samples)
        log_dbg(" -> Sound samples deleted.")
    end

    if ADS_Main and ADS_Main.vehicles and self.uniqueId and ADS_Main.vehicles[self.uniqueId] then
        if ADS_Main.previousKey == self.uniqueId then
            ADS_Main.previousKey = nil
        end
        ADS_Main.vehicles[self.uniqueId] = nil
        ADS_Main.numVehicles = ADS_Main.numVehicles - 1
        log_dbg(" -> Removed from ADS_Main.vehicles list.")
    end
end

function AdvancedDamageSystem:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if not self.isClient then
        return
    end

    local spec = self.spec_AdvancedDamageSystem
    if spec == nil then
        return
    end

    self:clearActionEventsTable(spec.startButtonActionEvents)

    if not isActiveForInputIgnoreSelection then
        return
    end

    local startInputActions = {
        InputAction.TOGGLE_MOTOR_STATE,
        InputAction.MOTOR_STATE_ON or "MOTOR_STATE_ON"
    }

    for _, inputAction in ipairs(startInputActions) do
        local _, actionEventId = self:addActionEvent(
            spec.startButtonActionEvents,
            inputAction,
            self,
            ADS_Breakdowns.onStartButtonAction,
            true,
            true,
            true,
            true,
            nil
        )

        if actionEventId ~= nil then
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
        end
    end
end

-- ==========================================================
--                        UPDATE
-- ==========================================================

local function getConditionLevelFromSellPrice(vehicle)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then return end

    local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
    if storeItem == nil then
        return 1.0
    end

    local price = StoreItemUtil.getDefaultPrice(storeItem, vehicle.configurations)
    if price == nil or price <= 0 then
        price = storeItem.price or vehicle:getPrice() or 0
    end

    local repaintPrice = Wearable.calculateRepaintPrice(price, vehicle:getWearTotalAmount())
    local repairPrice = vehicle:getRepairPrice()
    local vanillaSellPrice = Vehicle.calculateSellPrice(storeItem, vehicle.age, vehicle.operatingTime, price, repairPrice, repaintPrice)
    local adsSellPriceForCondition = vanillaSellPrice + repairPrice + (repaintPrice * 0.75)
    local targetCondition = math.clamp(adsSellPriceForCondition / price, 0.01, 1.0)
    return targetCondition
end

local function initializeVehicleConditionFromVanillaPrice(vehicle, resetBreakdowns)
    local spec = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    if vehicle == nil or spec == nil or spec.isExcludedVehicle then
        return false
    end

    spec.serviceLevel = 1 - vehicle:getDamageAmount()

    local targetCondition = getConditionLevelFromSellPrice(vehicle)
    for _, systemData in pairs(spec.systems or {}) do
        if type(systemData) == "table" then
            local random = math.random() * 0.2 + 0.9
            systemData.condition = math.clamp(targetCondition * random, 0.2, 1.0)
            systemData.stress = 0
            systemData.persistentWearRateState = 0
        end
    end

    vehicle:updateConditionLevel()
    vehicle:setDamageAmount(0.0, true)

    if resetBreakdowns then
        vehicle:removeBreakdown()

        if vehicle:getOperatingTime() > 0 then
            local operatingHours = tonumber(vehicle:getFormattedOperatingTime()) or 0
            local lifespanRatio = ADS_Config.CORE.DEFAULT_SYSTEM_WEAR / ADS_Config.CORE.BASE_SYSTEMS_WEAR
            local chance = operatingHours / (100 * lifespanRatio)
            chance = math.clamp(chance * ADS_Config.CORE.USED_VEHICLE_BREAKDOWN_PRESENCE_CHANGE_MUL, 0, ADS_Config.CORE.USED_VEHICLE_BREAKDOWN_PRESENCE_CHANGE_MAX)
            if math.random() < chance then
                vehicle:addBreakdown(vehicle:getRandomBreakdown())
            end
        end
    end

    return true, targetCondition
end

local function registerVehicle(vehicle)
    if ADS_Main and ADS_Main.vehicles and ADS_Main.vehicles[vehicle.uniqueId] == nil then
        if (vehicle.propertyState == 2 or vehicle.propertyState == 3 or vehicle.propertyState == 4) and vehicle.ownerFarmId ~= 0 and vehicle.ownerFarmId < 10 then

            local spec = vehicle.spec_AdvancedDamageSystem
            if spec == nil then return end

            log_dbg(" -> Registering vehicle in ADS_Main.vehicles list. ID:", vehicle.uniqueId)
            --- Registration in ADS_Main.vehicles
            ADS_Main.vehicles[vehicle.uniqueId] = vehicle
            ADS_Main.numVehicles = ADS_Main.numVehicles + 1
    
            --- if first mod load or used vehicle
            if vehicle.isServer then
                    if (vehicle:getFormattedOperatingTime() > 0.01 and spec.conditionLevel == spec.baseConditionLevel) then
                        -- Used vehicle logic
                        initializeVehicleConditionFromVanillaPrice(vehicle, true)
                    end

                    --- if first mod load and vehicle has no maintenance log, add initial entry with current condition and service levels
                    if (spec.maintenanceLog == nil or #spec.maintenanceLog == 0) then
                        vehicle:addEntryToMaintenanceLog(AdvancedDamageSystem.STATUS.INSPECTION, AdvancedDamageSystem.INSPECTION_TYPES.STANDARD, "NONE", false, 0)
                    end
            end

            --- Updating vehicle's year from Vehicle Years mod
            local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
            if storeItem ~= nil and storeItem.specs ~= nil and storeItem.specs.year ~= nil and tonumber(storeItem.specs.year) ~= nil then
                    spec.year = tonumber(storeItem.specs.year)
            end

            --- Updating vehicle's reliability and maintainability
            spec.reliability, spec.maintainability = AdvancedDamageSystem.getBrandReliability(vehicle)

            local factorStats = ensureFactorStats(spec, vehicle)
            local currentOperatingHours = getVehicleOperatingHours(vehicle)
            for _, systemStats in pairs(factorStats) do
                if type(systemStats) == "table" then
                    local operatingHours = tonumber(systemStats.operatingHours)
                    if operatingHours == nil or operatingHours < 0 then
                        systemStats.operatingHours = currentOperatingHours
                    end
                end
            end
        end
    end
end

local function syncColdEngineEffect(vehicle)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then return end

    if vehicle.isServer then
        local engTemp = spec.rawEngineTemperature or spec.engineTemperature or -99
        local breakdownId = 'COLD_ENGINE'

        if engTemp <= -10 and not vehicle:hasBreakdown(breakdownId) then
            vehicle:addBreakdown(breakdownId)
        elseif engTemp > -10 and vehicle:hasBreakdown(breakdownId) then
            vehicle:removeBreakdown(breakdownId)
        end
    end
end

local function syncDeadBatteryEffect(vehicle)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then return end

    local breakdownId = 'DEAD_BATTERY'
    if spec.batterySoc < 0.001 and vehicle.isServer then
        if (vehicle:getIsMotorStarted() and spec.alternatorHealth < 0.01) or not vehicle:getIsMotorStarted() then
            if not vehicle:hasBreakdown(breakdownId) and spec.externalPowerConnection == nil then
                vehicle:addBreakdown(breakdownId)
                if spec.systems.electrical.isCranking then
                    local engineHardStartEffect = spec.activeEffects ~= nil and spec.activeEffects.ENGINE_HARD_START_MODIFIER or nil
                    local engineFailedEffect = spec.activeEffects ~= nil and spec.activeEffects.ENGINE_FAILURE or nil
                    if engineHardStartEffect ~= nil and engineHardStartEffect.extraData ~= nil and engineHardStartEffect.extraData.status ~= nil then
                        engineHardStartEffect.extraData.status = "IDLE"
                    end
                    if engineFailedEffect ~= nil and engineFailedEffect.extraData ~= nil and engineFailedEffect.extraData.status ~= nil then
                        engineFailedEffect.extraData.status = "IDLE"
                    end
                end
            end
        end
    elseif vehicle:hasBreakdown(breakdownId) then
        vehicle:removeBreakdown(breakdownId)
    end
end

local function syncOverheatProtection(vehicle)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then return end
    local rawEngineTemp =  spec.rawEngineTemperature or spec.engineTemperature or -99 
    local rawTransmissionTemp = not hasCVTAddon(vehicle) and (spec.rawTransmissionTemperature or spec.transmissionTemperature or -99) or -99

    if vehicle.isServer and spec.year >= 2000 then
        local overheatProtectionId = 'OVERHEAT_PROTECTION'
        local overheatProtection = vehicle:getActiveBreakdowns()[overheatProtectionId]
        if overheatProtection and rawTransmissionTemp < 100 and rawEngineTemp < 100 then
            vehicle:removeBreakdown(overheatProtectionId)
        end
        if vehicle:getIsMotorStarted() then
            if (rawTransmissionTemp > 105 or rawEngineTemp > 105) and not overheatProtection then
                vehicle:addBreakdown(overheatProtectionId, 1)
                if vehicle.getIsControlled ~= nil and vehicle:getIsControlled() then
                    g_soundManager:playSample(spec.samples.alarm)
                end
            elseif overheatProtection then
                if vehicle:getCruiseControlState() ~= 0 then
                    vehicle:setCruiseControlState(0, true)
                end
                if (rawTransmissionTemp > 125 or rawEngineTemp > 125) and overheatProtection.stage < 4 then
                    vehicle:changeBreakdownStage(overheatProtectionId)
                    if vehicle.getIsControlled ~= nil and vehicle:getIsControlled() then
                        g_soundManager:playSample(spec.samples.alarm)
                    end
                elseif (rawTransmissionTemp > 115 or rawEngineTemp > 115) and overheatProtection.stage < 3 then
                    vehicle:changeBreakdownStage(overheatProtectionId)
                    if vehicle.getIsControlled ~= nil and vehicle:getIsControlled() then
                        g_soundManager:playSample(spec.samples.alarm)
                    end
                elseif (rawTransmissionTemp > 110 or rawEngineTemp > 110) and overheatProtection.stage < 2 then
                    vehicle:changeBreakdownStage(overheatProtectionId)
                    if vehicle.getIsControlled ~= nil and vehicle:getIsControlled() then
                        g_soundManager:playSample(spec.samples.alarm)
                    end
                end
            end
        end
    else
        if vehicle.isServer then
            local engineFailedEffect = spec.activeEffects.ENGINE_FAILURE
            if rawEngineTemp > 125 and not engineFailedEffect then
                if math.random() < ADS_Utils.getChancePerFrameFromMeanTime(spec.effectsUpdateTimer, 3) then
                    vehicle:addBreakdown('ENGINE_JAM')
                end
            end
        end
    end
end

local function syncVoltageSagEffect(vehicle, dt)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil or not vehicle.isServer then return end
    local triggerDelayMs = 2000
    if spec.syncVoltageSagEffectTimer == nil then
        spec.syncVoltageSagEffectTimer = triggerDelayMs
    end

    local motorState = vehicle:getMotorState()
    local isCranking = spec.systems.electrical.isCranking ~= nil and spec.systems.electrical.isCranking
    local breakdownId = 'VOLTAGE_SAG'
    local systemVoltageV = spec.rawSystemVoltageV or spec.systemVoltageV or 0
    local isVoltageSagging = (motorState == 1 and systemVoltageV < 12.0 and not isCranking) or (motorState == 4 and systemVoltageV < 13.0)
    local clearToRemove = not isCranking

    if isVoltageSagging then
        if not vehicle:hasBreakdown(breakdownId) then
            spec.syncVoltageSagEffectTimer = math.max((spec.syncVoltageSagEffectTimer or triggerDelayMs) - (dt or 0), 0)
            if spec.syncVoltageSagEffectTimer <= 0 then
                vehicle:addBreakdown(breakdownId)
                spec.syncVoltageSagEffectTimer = triggerDelayMs
            end
        else
            spec.syncVoltageSagEffectTimer = triggerDelayMs
        end
    elseif clearToRemove and not isVoltageSagging then
        spec.syncVoltageSagEffectTimer = triggerDelayMs
        if vehicle:hasBreakdown(breakdownId) then
            vehicle:removeBreakdown(breakdownId)
        end
    end
end

local function syncAirIntakeCloggingEffect(vehicle)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil or not vehicle.isServer then return end

    local breakdownId = 'AIRINTAKE_CLOGGING'
    local shouldBeStage = 0
    local threshold = ADS_Config.FIELD_CARE.AIR_INTAKE_BREAKDOWN_THRESHOLD 

    if spec.airIntakeClogging > threshold then
        if spec.airIntakeClogging > (threshold + (threshold / 3 * 2)) then
            shouldBeStage = 3
        elseif spec.airIntakeClogging > (threshold + (threshold / 3)) then
            shouldBeStage = 2
        else
            shouldBeStage = 1
        end
        if not vehicle:hasBreakdown(breakdownId) then
            vehicle:addBreakdown(breakdownId, shouldBeStage)
        else
            local currentStage = vehicle:getActiveBreakdowns()[breakdownId].stage
            if currentStage ~= shouldBeStage then
                vehicle:changeBreakdownStage(breakdownId, shouldBeStage)
            end
        end
    else
        if vehicle:hasBreakdown(breakdownId) then
            vehicle:removeBreakdown(breakdownId)
        end
    end
end

local function syncMessages(vehicle)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then return end

    --- Cold engine message (guard: temperature must be initialized, i.e. > -90)
    if vehicle:getIsMotorStarted() and spec.engineTemperature > -90 and spec.engineTemperature <= ADS_Config.CORE.ENGINE_FACTOR_DATA.COLD_MOTOR_TEMP_THRESHOLD and vehicle:getIsActiveForInput(true) and not vehicle:getIsAIActive() and not spec.isElectricVehicle then
        local spec_motorized = vehicle.spec_motorized
        local lastRpm = spec_motorized.motor:getLastModulatedMotorRpm()
        local maxRpm = spec_motorized.motor.maxRpm
        local rpmLoad = lastRpm / maxRpm
        if rpmLoad > 0.75 then
            g_currentMission:showBlinkingWarning(g_i18n:getText('ads_spec_cold_engine_message'), 2800)
        end
    end

    --- Messages from breakdowns and stop AI
    if spec.activeFunctions ~= nil and next(spec.activeEffects) ~= nil then
        for _, effectData in pairs(spec.activeEffects) do
            if effectData ~= nil and effectData.extraData ~= nil and effectData.extraData.message ~= nil then
                if vehicle:getIsActiveForInput(true) and not vehicle:isUnderService() then
                    g_currentMission:showBlinkingWarning(g_i18n:getText(effectData.extraData.message), 200)
                end
                if vehicle.isServer and vehicle:getIsAIActive() and effectData.extraData.disableAi then 
                    vehicle:stopCurrentAIJob(AIMessageErrorVehicleBroken.new()) 
                end
            end
        end
    end
end

local function getSmoothedMotorLoad(vehicle, dt)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then return end

    if vehicle:getIsMotorStarted() then
        local rawLoad
        if vehicle.isServer then
            rawLoad = math.max(vehicle:getMotorLoadPercentage() or 0, 0)
        else
            rawLoad = math.max(spec._netMotorLoad or 0, 0)
        end
        local loadTau = 300
        local loadAlpha = math.min(dt / (loadTau + dt), 1)
        spec._smoothedMotorLoad = (spec._smoothedMotorLoad or 0) + loadAlpha * (rawLoad - (spec._smoothedMotorLoad or 0))
    else
        spec._smoothedMotorLoad = 0
    end
end

local function syncFuelConsumption(vehicle)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then return end

    -- Fuel consumption sync (same approach as DashboardLive):
    -- Server: capture raw lastFuelUsage every frame for dirty-flag network sync.
    if vehicle.isServer and vehicle.spec_motorized ~= nil then
        if vehicle.getIsMotorStarted ~= nil and vehicle:getIsMotorStarted() then
            spec._fuelUsageRaw = vehicle.spec_motorized.lastFuelUsage or 0
        else
            spec._fuelUsageRaw = 0
        end
    end
    -- Dedicated client: inject synced raw value into spec_motorized.lastFuelUsage
    -- so Motorized's own fuelUsageBuffer picks it up every frame (identical to DashboardLive).
    if vehicle.isClient and not vehicle.isServer and vehicle.spec_motorized ~= nil then
        vehicle.spec_motorized.lastFuelUsage = spec._fuelUsageRaw or 0
    end
    -- Display: always read Motorized's own smoothed value (identical to dashboard gauge).
    if vehicle.isClient and vehicle.spec_motorized ~= nil then
        spec.fuelUsage = vehicle.spec_motorized.lastFuelUsageDisplay or 0
    end
end

local function syncCVTaddonBreakdown(vehicle)
    if not hasCVTAddon(vehicle) then return end
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil or not vehicle.isServer then return end

    local breakdownId = 'CVT_ADDON_MALFUNCTION'
    local spec_CVTaddon = vehicle.spec_CVTaddon
    if spec_CVTaddon ~= nil then
        local shouldHaveBreakdown = spec_CVTaddon.CVTdamage > 60.0
        local shouldBeStage = 1
        if spec_CVTaddon.CVTdamage > 90.0 then
            shouldBeStage = 4
        elseif spec_CVTaddon.CVTdamage > 80.0 then
            shouldBeStage = 3
        elseif spec_CVTaddon.CVTdamage > 70.0 then
            shouldBeStage = 2
        end

        if shouldHaveBreakdown and not vehicle:hasBreakdown(breakdownId) then
            vehicle:addBreakdown(breakdownId, shouldBeStage)
        elseif not shouldHaveBreakdown and vehicle:hasBreakdown(breakdownId) then
            vehicle:removeBreakdown(breakdownId)
        elseif shouldHaveBreakdown and vehicle:hasBreakdown(breakdownId) then
            local currentStage = vehicle:getActiveBreakdowns()[breakdownId].stage
            if currentStage ~= shouldBeStage then
                vehicle:changeBreakdownStage(breakdownId, shouldBeStage)
            end
        end
    else
        if vehicle:hasBreakdown(breakdownId) then
            vehicle:removeBreakdown(breakdownId)
        end
    end
end

function AdvancedDamageSystem:onUpdate(dt, ...)
    local spec = self.spec_AdvancedDamageSystem
    if spec.isExcludedVehicle then return end

    spec.effectsUpdateTimer = spec.effectsUpdateTimer + dt

    -- Smooth motor load for HUD display (EMA filter, TAU ~300ms).
    -- On a dedicated client, Giants' getMotorLoadPercentage() is derived from
    -- a 7-bit quantized rawLoadPercentage sent in Motorized's update stream,
    -- resulting in non-deterministic idle values between restarts.
    -- We sync the server's authoritative value (float32) in dirty flag [1]
    -- and use it as the EMA input on the client for a stable, consistent reading.
    getSmoothedMotorLoad(self, spec.effectsUpdateTimer)

    --- Fuel consumption
    syncFuelConsumption(self)

    if spec.effectsUpdateTimer < ADS_Config.EFFECTS_UPDATE_DELAY then
        return
    end

    --- Registration in ADS_Main.vehicles and first load checks.
    registerVehicle(self)
    
    --- Temperature smoothing
    self:getSmoothedTemperature(spec.effectsUpdateTimer)

    --- Checking for cold engine effect
    syncColdEngineEffect(self)

    --- Checking for dead alternator or dead battery
    syncVoltageSagEffect(self, spec.effectsUpdateTimer)

    --- Checking for airintake clogging
    syncAirIntakeCloggingEffect(self)

    --- Checking for dead battery if motor is off
    syncDeadBatteryEffect(self)
    
    --- Overheat protection for vehcile > 2000 year and engine failure from overheating for < 2000
    syncOverheatProtection(self)

    --- CVT addon breakdown sync
    syncCVTaddonBreakdown(self)
    
    --- Messages
    syncMessages(self)
    
    --- just in case, reset damage amount to 0 if it's not
    if self.isServer and self.getDamageAmount ~= nil and self:getDamageAmount() ~= 0 then self:setDamageAmount(0.0, true) end
    
    --- AI worker overload, temp control
    if ADS_Config.CORE.AI_OVERLOAD_AND_OVERHEAT_CONTROL then
        self:updateAiWorkerCruiseControl(spec.effectsUpdateTimer)
    end

    --- Enables the thermal model for neutral vehicles on the map, should the player happen to use them
    if self.isServer and ADS_Main and ADS_Main.vehicles and ADS_Main.vehicles[self.uniqueId] == nil and self:getIsControlled() then
        self:updateThermalSystems(spec.effectsUpdateTimer)
    end

    --- Random and permanent effects from breakdowns. Skip if spec.activeEffects is empty
    if spec ~= nil and spec.activeFunctions ~= nil and next(spec.activeFunctions) ~= nil then
        for _ , func in pairs(spec.activeFunctions) do
            func(self, spec.effectsUpdateTimer)
        end
    end

    spec.effectsUpdateTimer = spec.effectsUpdateTimer - ADS_Config.EFFECTS_UPDATE_DELAY
end

function AdvancedDamageSystem:adsUpdate(dt, isWorkshopOpen)
    local spec = self.spec_AdvancedDamageSystem
    if spec.isExcludedVehicle then return end

    -- OP Time update for ADS vehicles
    local motorState = self.getMotorState ~= nil and self:getMotorState() or nil
    if motorState == MotorState.ON then
        local currentOperatingTime = self.getOperatingTime ~= nil and self:getOperatingTime() or self.operatingTime or 0

        spec._allowAdsOperatingTimeWrite = true
        self:setOperatingTime(currentOperatingTime + (dt or 0), false)
        spec._allowAdsOperatingTimeWrite = false
    end

    self:updateThermalSystems(dt)
    self:updateBatteryChargingModel(dt)

    if self:isUnderService() then
        self:processService(dt)
    else
        if self:getIsOperating() and self.propertyState ~= 4 then
            self:updateRadiatorClogging(dt)
            self:updateAirIntakeClogging(dt)
            self:processBreakdowns(dt)
            self:tryTriggerBreakdown(dt)
            spec.isUnderRoof = self:isUnderRoof()
        end

        -- service
        self:updateServiceLevel(dt)
        -- systems
        self:updateEngineSystem(dt)
        self:updateTransmissionSystem(dt)
        self:updateHydraulicsSystem(dt)
        self:updateCoolingSystem(dt)
        self:updateElectricalSystem(dt)
        self:updateChassisSystem(dt)
        self:updateFuelSystem(dt)
        self:updateWorkProcessSystem(dt)
        -- condtition
        self:updateConditionLevel()
        -- general wear
        self:processGeneralWearBreakdown()
        -- lubtication level
        self:updateLubricationLevel(dt)
    end

    -- Raise dirty flags for changed data
    if self.isServer then
        markStateDirty(self, spec)
        markServiceContextDirty(self, spec)
        markTelemetryDirty(self, spec)
        markThermalDirty(self, spec)
        markElectricalDirty(self, spec)
        markFieldcareDirty(self, spec)
        markWearDirty(self, spec)
        markBreakdownsDirty(self, spec)
        markServiceProgressDirty(self, spec)
    end
end

-- ==========================================================
--                      VEHICLE STATE
-- ==========================================================

function AdvancedDamageSystem:captureVehicleStateSnaphot(dt)

end

-- ==========================================================
--                        AI WORKER
-- ==========================================================

function AdvancedDamageSystem:resetAiWorkerCruiseControlState()
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil then return end

    local state = spec.aiWorkerPid
    if state == nil then return end

    if state.baseCruiseSpeed ~= nil and state.baseCruiseSpeed > 0 then
        local motor = self:getMotor()
        self:setCruiseControlMaxSpeed(motor:getMaximumForwardSpeed() * 3.6, nil)
    end

    state.integral = 0
    state.lastError = 0
    state.filteredStress = 0
    state.currentReduction = 0
    state.baseCruiseSpeed = nil
    state.applyTimer = 0
    state.lastAppliedSpeed = nil

    if ADS_Config.DEBUG and spec.debugData and spec.debugData.aiWorker then
        local dbg = spec.debugData.aiWorker
        dbg.stress = 0
        dbg.filteredStress = 0
        dbg.error = 0
        dbg.integral = 0
        dbg.derivative = 0
        dbg.reduction = 0
        dbg.targetSpeed = 0
        dbg.appliedSpeed = 0
        dbg.baseCruiseSpeed = 0
        dbg.loadStress = 0
        dbg.engineStress = 0
        dbg.transStress = 0
    end
end

function AdvancedDamageSystem:getAiWorkerImplementSpeedLimit()
    local speedLimit = math.huge

    if self.spec_attacherJoints and self.spec_attacherJoints.attachedImplements and next(self.spec_attacherJoints.attachedImplements) ~= nil then
        for _, implementData in pairs(self.spec_attacherJoints.attachedImplements) do
            if implementData.object ~= nil then
                local implement = implementData.object
                local currentSpeedLimit = implement.speedLimit
                if currentSpeedLimit ~= nil and implement.getIsLowered ~= nil and implement:getIsLowered() then
                    speedLimit = math.min(speedLimit, currentSpeedLimit)
                end
            end
        end
    end

    return speedLimit
end

function AdvancedDamageSystem:updateAiWorkerCruiseControl(dt)
    if not self.isServer then return end
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil then return end

    local config = ADS_Config.CORE and ADS_Config.CORE.AI_WORKER_PID
    if config == nil then return end

    if spec.aiWorkerPid == nil then
        spec.aiWorkerPid = {
            integral = 0,
            lastError = 0,
            filteredStress = 0,
            currentReduction = 0,
            baseCruiseSpeed = nil,
            applyTimer = 0,
            lastAppliedSpeed = nil
        }
    end

    if not self:getIsAIActive() or not self:getIsMotorStarted() then
        self:resetAiWorkerCruiseControlState()
        return
    end

    local cruiseSpeed = self:getCruiseControlSpeed() or 0
    if cruiseSpeed <= 0 then
        self:resetAiWorkerCruiseControlState()
        return
    end

    local state = spec.aiWorkerPid
    local dtMs = math.max(dt or ADS_Config.EFFECTS_UPDATE_DELAY, 1)
    local dtSeconds = math.max(dtMs / 1000, 0.05)

    local function normalizeToUnit(value, startValue, fullValue)
        local denominator = math.max(fullValue - startValue, 0.0001)
        return math.clamp((value - startValue) / denominator, 0.0, 1.0)
    end

    local motorLoad = math.max(self:getMotorLoadPercentage() or 0, 0)
    local rawEngineTemperature = spec.rawEngineTemperature or spec.engineTemperature or 0
    local rawTransmissionTemperature = spec.rawTransmissionTemperature or spec.transmissionTemperature or -99
    if rawTransmissionTemperature < 0 then
        rawTransmissionTemperature = rawEngineTemperature
    end

    local loadStress = normalizeToUnit(motorLoad, config.LOAD_START, config.LOAD_FULL)
    local engineStress = normalizeToUnit(rawEngineTemperature, config.ENGINE_TEMP_START, config.ENGINE_TEMP_FULL)
    local transStress = normalizeToUnit(rawTransmissionTemperature, config.TRANS_TEMP_START, config.TRANS_TEMP_FULL)

    local stress = loadStress * config.WEIGHT_LOAD + engineStress * config.WEIGHT_ENGINE_TEMP + transStress * config.WEIGHT_TRANS_TEMP
    stress = math.clamp(stress, 0.0, 1.0)

    local filterTau = math.max(config.FILTER_TAU or 0.7, 0.05)
    local filterAlpha = dtSeconds / (filterTau + dtSeconds)
    state.filteredStress = state.filteredStress + (stress - state.filteredStress) * filterAlpha

    local error = state.filteredStress - config.TARGET_STRESS
    if math.abs(error) < config.DEADBAND then
        error = 0
    end

    local lastError = state.lastError or 0
    local derivative = (error - lastError) / math.max(dtSeconds, 0.001)

    local maxReduction = math.max(config.MAX_REDUCTION or 16, 0)
    local maxIntegral = math.max(config.MAX_INTEGRAL or 3, 0.001)

    local integrate = true
    if (state.currentReduction <= 0 and error < 0) or (state.currentReduction >= maxReduction and error > 0) then
        integrate = false
    end
    if integrate then
        state.integral = math.clamp((state.integral or 0) + error * dtSeconds, -maxIntegral, maxIntegral)
    end

    local rateCommand = config.KP * error + config.KI * state.integral + config.KD * derivative
    local reductionRate = math.max(config.REDUCTION_RATE_DOWN or 8.0, 0.1)
    local recoveryRate = math.max(config.RECOVERY_RATE_UP or 2.5, 0.1)
    rateCommand = math.clamp(rateCommand, -recoveryRate, reductionRate)
    state.currentReduction = math.clamp(state.currentReduction + rateCommand * dtSeconds, 0, maxReduction)

    local emergency = rawEngineTemperature >= (config.EMERGENCY_ENGINE_TEMP or 112) or rawTransmissionTemperature >= (config.EMERGENCY_TRANS_TEMP or 112)
    if emergency then
        state.currentReduction = maxReduction
        state.integral = math.max(state.integral, 0)
    end

    local minSpeed = math.max(config.MIN_SPEED or 5.0, 0)
    local estimatedBaseCruiseSpeed = math.max(cruiseSpeed + state.currentReduction, minSpeed)
    if state.baseCruiseSpeed == nil then
        state.baseCruiseSpeed = estimatedBaseCruiseSpeed
    end

    if estimatedBaseCruiseSpeed > state.baseCruiseSpeed then
        state.baseCruiseSpeed = estimatedBaseCruiseSpeed
    elseif state.currentReduction < 0.25 then
        local syncDownRate = math.max(config.BASE_SYNC_DOWN_RATE or 1.8, 0.1)
        local syncBlend = math.min(dtSeconds * syncDownRate, 1.0)
        state.baseCruiseSpeed = state.baseCruiseSpeed + (estimatedBaseCruiseSpeed - state.baseCruiseSpeed) * syncBlend
    end

    local baseSpeedLimit = state.baseCruiseSpeed
    local implementSpeedLimit = self:getAiWorkerImplementSpeedLimit()
    if implementSpeedLimit ~= math.huge then
        baseSpeedLimit = math.min(baseSpeedLimit, implementSpeedLimit)
    end

    local targetSpeed = math.max(minSpeed, baseSpeedLimit - state.currentReduction)
    local maxUpStep = recoveryRate * dtSeconds
    local maxDownStep = reductionRate * dtSeconds
    if targetSpeed > cruiseSpeed then
        targetSpeed = math.min(targetSpeed, cruiseSpeed + maxUpStep)
    elseif targetSpeed < cruiseSpeed then
        targetSpeed = math.max(targetSpeed, cruiseSpeed - maxDownStep)
    end
    targetSpeed = math.floor(targetSpeed * 10 + 0.5) / 10

    state.applyTimer = (state.applyTimer or 0) + dtMs
    local applyInterval = math.max(config.APPLY_INTERVAL_MS or 180, 50)
    local minApplyDelta = math.max(config.MIN_APPLY_DELTA or 0.2, 0.01)

    local shouldApply = emergency
    if not shouldApply and state.applyTimer >= applyInterval then
        local lastAppliedSpeed = state.lastAppliedSpeed or cruiseSpeed
        if math.abs(targetSpeed - lastAppliedSpeed) >= minApplyDelta or math.abs(targetSpeed - cruiseSpeed) >= minApplyDelta then
            shouldApply = true
        end
    end

    if shouldApply then
        self:setCruiseControlMaxSpeed(targetSpeed, nil)
        state.lastAppliedSpeed = targetSpeed
        state.applyTimer = 0
    end

    state.lastError = error

    if ADS_Config.DEBUG and spec.debugData and spec.debugData.aiWorker then
        local dbg = spec.debugData.aiWorker
        dbg.stress = stress
        dbg.filteredStress = state.filteredStress
        dbg.error = error
        dbg.integral = state.integral
        dbg.derivative = derivative
        dbg.reduction = state.currentReduction
        dbg.targetSpeed = targetSpeed
        dbg.appliedSpeed = state.lastAppliedSpeed or cruiseSpeed
        dbg.baseCruiseSpeed = state.baseCruiseSpeed or 0
        dbg.loadStress = loadStress
        dbg.engineStress = engineStress
        dbg.transStress = transStress
    end
end

-- ==========================================================
--                      CORE FUNCTIONS
-- =========================================================

local function resolveSystemKey(spec, systemName)
    if spec == nil or spec.systems == nil or type(systemName) ~= "string" then
        return systemName
    end

    if spec.systems[systemName] ~= nil then
        return systemName
    end

    local loweredSystemName = string.lower(systemName)
    local weights = ADS_Config ~= nil and ADS_Config.CORE ~= nil and ADS_Config.CORE.SYSTEM_WEIGHTS or nil
    if type(weights) == "table" then
        for weightedKey, _ in pairs(weights) do
            if string.lower(tostring(weightedKey)) == loweredSystemName and spec.systems[weightedKey] ~= nil then
                return weightedKey
            end
        end
    end

    for existingKey, _ in pairs(spec.systems) do
        if string.lower(tostring(existingKey)) == loweredSystemName then
            return existingKey
        end
    end

    return systemName
end

local function ensureSystemData(spec, systemName)
    if spec.systems == nil then
        spec.systems = {}
    end

    systemName = resolveSystemKey(spec, systemName)

    local systemData = spec.systems[systemName]
    if type(systemData) ~= "table" then
        systemData = {
            condition = tonumber(systemData) or 1.0,
            stress = 0.0
        }
        spec.systems[systemName] = systemData
    end

    systemData.condition = math.clamp(tonumber(systemData.condition) or 1.0, 0.001, 1.0)
    systemData.stress = math.max(tonumber(systemData.stress) or 0.0, 0.0)

    return systemData
end

local function getExpiredServiceMultiplier(serviceLevel, serviceMultiplier)
    if serviceLevel == nil then
        return 1.0
    end

    if serviceLevel < ADS_Config.CORE.SERVICE_EXPIRED_THRESHOLD then
        local severity = ADS_Utils.calculateQuadraticMultiplier(serviceLevel, ADS_Config.CORE.SERVICE_EXPIRED_THRESHOLD, true)
        return 1.0 + severity * (serviceMultiplier or 0)
    end

    return 1.0
end

local function getBreakdownsStageSum(vehicle, system)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then return 0 end

    local activeBreakdowns = vehicle:getActiveBreakdowns()
    if activeBreakdowns == nil or next(activeBreakdowns) == nil then
        return 0
    end

    local breadownsRegistry = ADS_Breakdowns.BreakdownRegistry
    local targetSystemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, system)
    if targetSystemKey == nil or targetSystemKey == "" then
        targetSystemKey = type(system) == "string" and string.lower(system) or ""
    end

    if targetSystemKey == "" then
        return 0
    end

    local sumOfStages = 0

    for breakdownId, breakdownData in pairs(activeBreakdowns) do
        local registryBreakdown = breadownsRegistry[breakdownId]
        if registryBreakdown ~= nil then
            local breakdownSystemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, registryBreakdown.system)
            if breakdownSystemKey == targetSystemKey and breakdownData.isActive ~= false then
                sumOfStages = sumOfStages + (tonumber(breakdownData.stage) or 0)
            end
        end
    end

    return sumOfStages
end

-- service
function AdvancedDamageSystem:updateServiceLevel(dt)
    local spec = self.spec_AdvancedDamageSystem
    local wearRate = ADS_Config.CORE.BASE_SERVICE_WEAR

    if self.getIsMotorStarted ~= nil and self:getIsMotorStarted() then
        wearRate = wearRate * (1 + spec.extraServiceWear) 
    else
        if spec.isUnderRoof then 
            wearRate = wearRate * ADS_Config.CORE.UNDER_ROOF_DOWNTIME_MULTIPLIER 
        else
            wearRate = wearRate * ADS_Config.CORE.DOWNTIME_MULTIPLIER
        end
    end  

    wearRate = wearRate / spec.reliability
    
    local newLevel = spec.serviceLevel -  wearRate / (60 * 60 * 1000) * dt
    spec.serviceLevel = math.max(newLevel, 0)

    if ADS_Config.DEBUG then
        if spec.debugData == nil then
            spec.debugData = {}
        end
        if spec.debugData.service == nil then
            spec.debugData.service = {}
        end

        local dbg = spec.debugData.service
        dbg.totalWearRate = wearRate
    end
end

-- condition
function AdvancedDamageSystem:updateConditionLevel()
    local spec = self.spec_AdvancedDamageSystem
    local weightedCondition = 0
    local totalEnabledWeight = 0
    local systemWeights = ADS_Config.CORE.SYSTEM_WEIGHTS or {}

    for systemName, systemData in pairs(spec.systems) do
        if systemData.enabled ~= false then
            local weight = tonumber(systemWeights[systemName]) or 0
            if weight > 0 then
                local systemCondition = tonumber(systemData.condition) or 1.0
                weightedCondition = weightedCondition + systemCondition * weight
                totalEnabledWeight = totalEnabledWeight + weight
            end
        end
    end

    local condition = 1.0
    if totalEnabledWeight > 0 then
        condition = weightedCondition / totalEnabledWeight
    end

    spec.conditionLevel = math.clamp(condition, 0.001, 1.0)
end

-- system condition and stress
function AdvancedDamageSystem:updateSystemConditionAndStress(dt, systemName, wearRate, debugFactors)
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil then
        return
    end

    systemName = resolveSystemKey(spec, systemName)

    local reliability = math.max(spec.reliability or 1.0, 0.001)
    local baseWearRate = 1.0 / reliability
    local systemData = ensureSystemData(spec, systemName)
    wearRate = tonumber(wearRate) or baseWearRate
    wearRate = wearRate * (1 + spec.extraConditionWear) / reliability

    --- filter
    if systemData.persistentWearRateState == nil then
        systemData.persistentWearRateState = 0
    end
    local tau = 700.0
    local alpha = 1 - math.exp(-dt / tau)
    local impulseWearRate = math.min(math.max(wearRate - systemData.persistentWearRateState, 0), ADS_Config.CORE.IMPULSE_WEAR_RATE_LIMIT)
    systemData.persistentWearRateState = systemData.persistentWearRateState + (wearRate - systemData.persistentWearRateState) * alpha
    local persistentWearRateLimited =  ADS_Config.CORE.PERSISTENT_WEAR_RATE_LIMIT * (1 - math.exp(-systemData.persistentWearRateState / ADS_Config.CORE.PERSISTENT_WEAR_RATE_LIMIT))
    local effectiveWearRate = persistentWearRateLimited + impulseWearRate

    local stressMultipliers = ADS_Config.CORE.SYSTEM_STRESS_ACCUMULATION_MULTIPLIERS or {}
    local systemStressMultiplier = stressMultipliers[systemName] or 1.0
    local globalStressMultiplier = math.max(tonumber(ADS_Config.CORE.SYSTEM_STRESS_GLOBAL_MULTIPLIER) or 1.0, 0.0)
    local dtMultiplier = ADS_Config.CORE.BASE_SYSTEMS_WEAR / (60 * 60 * 1000) * dt

    local conditionToRemove = effectiveWearRate * dtMultiplier
    local newCondition = (systemData.condition or 1.0) - conditionToRemove
    systemData.condition = math.clamp(newCondition, 0.001, 1.0)

    local stressToAdd = math.max(effectiveWearRate - baseWearRate, 0) * dtMultiplier * systemStressMultiplier * globalStressMultiplier
    systemData.stress = math.clamp((systemData.stress or 0) + stressToAdd, 0, math.max(systemData.condition, ADS_Config.CORE.CONDITION_EFFECTIVE_FLOOR))

    local factorStats = ensureFactorStats(spec, self)
    local systemStats = factorStats[systemName]
    if type(systemStats) == "table" then
        systemStats.total = (tonumber(systemStats.total) or 0) + effectiveWearRate * dtMultiplier
        systemStats.stress = (tonumber(systemStats.stress) or 0) + stressToAdd

        if type(debugFactors) == "table" then
            for key, value in pairs(debugFactors) do
                local numericValue = tonumber(value)
                local alias = AdvancedDamageSystem.FACTOR_STATS_ALIASES[tostring(key)]
                if numericValue ~= nil and alias ~= nil then
                    local factorDelta = (numericValue / reliability) * dtMultiplier
                    systemStats[alias] = (tonumber(systemStats[alias]) or 0) + factorDelta
                end
            end
        end
    end

    if ADS_Config.DEBUG and systemName ~= nil then
        if spec.debugData == nil then
            spec.debugData = {}
        end
        if spec.debugData[systemName] == nil then
            spec.debugData[systemName] = {}
        end

        local dbg = spec.debugData[systemName]
        dbg.condition = systemData.condition
        dbg.stress = systemData.stress
        dbg.totalWearRate = effectiveWearRate
        dbg.instantStressRate = dt > 0 and (stressToAdd * (60 * 60 * 1000) / dt) or 0

        if debugFactors ~= nil then
            for key, value in pairs(debugFactors) do
                dbg[key] = value
            end
        end
    end
end

-- damage
function AdvancedDamageSystem:applyInstantDamageToSystem(system, damageAmount)
    local spec = self.spec_AdvancedDamageSystem
    local systemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, system)
    systemKey = resolveSystemKey(spec, systemKey)

    if systemKey == nil or systemKey == "" or spec.systems[systemKey] == nil then
        return
    end

    local dmg = math.max(tonumber(damageAmount) or 0, 0)
    spec.systems[systemKey].condition = math.clamp((spec.systems[systemKey].condition or 1.0) - dmg, 0.001, 1.0)
    local stressToAdd = dmg * (ADS_Config.CORE.SYSTEM_STRESS_ACCUMULATION_MULTIPLIERS[systemKey] or 1)
    local stressCap = math.max(spec.systems[systemKey].condition or 0, ADS_Config.CORE.CONDITION_EFFECTIVE_FLOOR or 0)
    spec.systems[systemKey].stress = math.clamp((spec.systems[systemKey].stress or 0) + stressToAdd, 0, stressCap)

    local factorStats = ensureFactorStats(spec, self)
    local systemStats = factorStats[systemKey]
    if type(systemStats) == "table" then
        systemStats.total = (tonumber(systemStats.total) or 0) + dmg
        systemStats.stress = (tonumber(systemStats.stress) or 0) + stressToAdd
    end
end

-- engine (overload, cold, overheat)
function AdvancedDamageSystem:updateEngineSystem(dt)
    local spec = self.spec_AdvancedDamageSystem
    local spec_motorized = self.spec_motorized
    local C = ADS_Config.CORE.ENGINE_FACTOR_DATA
    local motorLoadFactor, expiredServiceFactor, coldMotorFactor, hotMotorFactor, breakdownPresenceFactor, airIntakeCloggingFactor = 0, 0, 0, 0, 0, 0
    local expiredServiceMultiplier = 1.0
    local baseWearRate = 1.0
    local wearRate = baseWearRate
    local systemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, spec.systems.engine.name)
    local systemData = spec.systems.engine

    if not systemData.enabled then
        systemData.isCranking = false
        return
    end

    if self.getIsMotorStarted ~= nil and self:getIsMotorStarted() and not spec.isElectricVehicle then
        local motorLoad = self:getMotorLoadPercentage()
        local lastRpm = spec_motorized.motor:getLastModulatedMotorRpm()
        local maxRpm = spec_motorized.motor.maxRpm
        local rpmLoad = lastRpm / maxRpm

        -- overload factor
        if motorLoad > C.MOTOR_OVERLOADED_THRESHOLD then
            motorLoadFactor = ADS_Utils.calculateQuadraticMultiplier(motorLoad, C.MOTOR_OVERLOADED_THRESHOLD, false)
            motorLoadFactor = motorLoadFactor * (C.MOTOR_OVERLOADED_MULTIPLIER or 0)
            wearRate = wearRate + motorLoadFactor
        end

        -- airintake cloagging factor
        if spec.airIntakeClogging > C.AIR_INTAKE_CLOGGING_THRESHOLD then
            airIntakeCloggingFactor = ADS_Utils.calculateQuadraticMultiplier(spec.airIntakeClogging, C.AIR_INTAKE_CLOGGING_THRESHOLD, false)
            airIntakeCloggingFactor = airIntakeCloggingFactor * (C.AIR_INTAKE_CLOGGING_MULTIPLIER or 0)
            wearRate = wearRate + airIntakeCloggingFactor
        end

        -- cold engine factor
        if (spec.engineTemperature or -99) < C.COLD_MOTOR_TEMP_THRESHOLD and rpmLoad > C.COLD_MOTOR_RPM_THRESHOLD and not spec.isElectricVehicle and not self:getIsAIActive() then
            coldMotorFactor = ADS_Utils.calculateQuadraticMultiplier(spec.engineTemperature, C.COLD_MOTOR_TEMP_THRESHOLD, true)
            local motorLoadInf = ADS_Utils.calculateQuadraticMultiplier(rpmLoad, C.COLD_MOTOR_RPM_THRESHOLD, false)
            coldMotorFactor = coldMotorFactor * (C.COLD_MOTOR_MULTIPLIER or 0) * motorLoadInf
            coldMotorFactor = math.min(coldMotorFactor, C.COLD_MOTOR_MULTIPLIER or coldMotorFactor)
            wearRate = wearRate + coldMotorFactor

        -- overheating engine factor
        elseif (spec.engineTemperature or -99) > C.OVERHEAT_MOTOR_THRESHOLD and motorLoad > 0.3 and not spec.isElectricVehicle then
            hotMotorFactor = ADS_Utils.calculateQuadraticMultiplier(spec.engineTemperature, C.OVERHEAT_MOTOR_THRESHOLD, false, 120)
            local motorLoadInf = ADS_Utils.calculateQuadraticMultiplier(motorLoad, 0.3, false)
            hotMotorFactor = hotMotorFactor * (C.OVERHEAT_MOTOR_MULTIPLIER or C.OVERHEAT_MOTOR_MULTIPLIER or 0) * motorLoadInf
            hotMotorFactor = math.min(hotMotorFactor, C.OVERHEAT_MOTOR_MULTIPLIER or hotMotorFactor)
            wearRate = wearRate + hotMotorFactor
        end

        -- idling
        if motorLoad < C.MOTOR_IDLING_THRESHOLD and self:getLastSpeed() < 0.003 then
            wearRate = wearRate * C.MOTOR_IDLING_MULTIPLIER
        end

        -- breakdown presence factor
        if self:hasSystemBreakdowns(systemKey) then
            local stagesSum = getBreakdownsStageSum(self, systemKey)
            breakdownPresenceFactor = stagesSum * (ADS_Config.CORE.BREAKDOWN_PRESENCE_FACTOR or 0)
            wearRate = wearRate + breakdownPresenceFactor
        end

        expiredServiceMultiplier = getExpiredServiceMultiplier(spec.serviceLevel, C.SERVICE_EXPIRED_MULTIPLIER)
        local wearRateWithoutService = wearRate
        wearRate = wearRate * expiredServiceMultiplier
        expiredServiceFactor = wearRate - wearRateWithoutService
    else
        if spec.isUnderRoof then 
            wearRate = wearRate * ADS_Config.CORE.UNDER_ROOF_DOWNTIME_MULTIPLIER 
        else
            wearRate = wearRate * ADS_Config.CORE.DOWNTIME_MULTIPLIER
        end
    end

    self:updateSystemConditionAndStress(dt, systemKey, wearRate, {
        motorLoadFactor = motorLoadFactor,
        airIntakeCloggingFactor = airIntakeCloggingFactor,
        expiredServiceFactor = expiredServiceFactor,
        coldMotorFactor = coldMotorFactor,
        hotMotorFactor = hotMotorFactor,
        breakdownPresenceFactor = breakdownPresenceFactor,
        airIntakeClogging = spec.airIntakeClogging
    })
end

-- transmission (pullOverload, lugging, slip, cvtCold, cvtOverheat)
function AdvancedDamageSystem:updateTransmissionSystem(dt)
    local spec = self.spec_AdvancedDamageSystem
    local spec_motorized = self.spec_motorized
    local spec_wheels = self.spec_wheels
    local C = ADS_Config.CORE.TRANSMISSION_FACTOR_DATA
    local systemData = spec.systems.transmission
    systemData.pullOverloadTimer = tonumber(systemData.pullOverloadTimer) or 0
    local vehicleHaveCVT = hasCVTTransmission(self)
    local expiredServiceFactor, pullOverloadFactor, luggingFactor, heavyTrailerFactor, wheelSlipFactor, wheelSlipIntensity, coldTransFactor, hotTransFactor, breakdownPresenceFactor = 0, 0, 0, 0, 0, 0, 0, 0, 0
    local expiredServiceMultiplier = 1.0
    local wearRate = 1.0
    local massRatio = 1.0
    local systemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, spec.systems.transmission.name)

    if not systemData.enabled then
        return
    end

    if hasCVTAddon(self) and self.getIsMotorStarted ~= nil and self:getIsMotorStarted() then
        local spec_CVTaddon = self.spec_CVTaddon

        if self.spec_RealisticDamageSystem == nil then
            self.spec_RealisticDamageSystem = {}
        end

        local currentCVTdamage = math.clamp(tonumber(spec_CVTaddon.CVTdamage) or 0, 0, 100)
        local prevCVTdamage = math.clamp(tonumber(spec._prevCVTdamage) or currentCVTdamage, 0, 100)
        local prevStress = math.max(tonumber(spec._prevStress) or 0, 0)

        local cvtDamageDelta = math.max(currentCVTdamage - prevCVTdamage, 0)
        local normalizedCVTdamage = currentCVTdamage / 100
        local normalizedDelta = cvtDamageDelta / 100

        local systemStressMultiplier = ADS_Config.CORE.SYSTEM_STRESS_ACCUMULATION_MULTIPLIERS[systemKey] or 1.0
        local globalStressMultiplier = math.max(tonumber(ADS_Config.CORE.SYSTEM_STRESS_GLOBAL_MULTIPLIER) or 1.0, 0.001)
        local divisor = math.max(systemStressMultiplier * globalStressMultiplier, 0.001)

        local currentCondition = math.clamp(tonumber(systemData.condition) or 1.0, 0.001, 1.0)
        local conditionToRemove = normalizedDelta / divisor
        local newCondition = math.clamp(currentCondition - conditionToRemove, 0.001, 1.0)

        local currentStress = systemData.stress or 0
        local newStress = math.clamp(currentStress + normalizedDelta, 0, newCondition)
        local previousStress = math.clamp(tonumber(systemData.stress) or 0, 0, math.max(currentCondition, 0.001))

        systemData.condition = newCondition
        systemData.stress = newStress

        spec_CVTaddon.CVTdamage = newStress / math.max(newCondition, 0.001) * 100
        spec._prevCVTdamage = spec_CVTaddon.CVTdamage
        spec._prevStress = newStress

        local factorStats = ensureFactorStats(spec, self)
        local systemStats = factorStats[systemKey]
        if type(systemStats) == "table" then
            systemStats.total = (tonumber(systemStats.total) or 0) + conditionToRemove
            systemStats.stress = (tonumber(systemStats.stress) or 0) + math.max(newStress - previousStress, 0)
        end

        local motorLoad = self:getMotorLoadPercentage()
        local speed = self:getLastSpeed()
        if motorLoad < ADS_Config.CORE.ENGINE_FACTOR_DATA.MOTOR_IDLING_THRESHOLD and speed < 0.003 then
            wearRate = wearRate * C.TRANSMISSION_IDLING_MULTIPLIER
        end

    elseif self.getIsMotorStarted ~= nil and self:getIsMotorStarted() and not spec.isElectricVehicle then
        local motorLoad = self:getMotorLoadPercentage()
        local lastRpm = spec_motorized.motor:getLastModulatedMotorRpm()
        local maxRpm = spec_motorized.motor.maxRpm
        local rpmLoad = lastRpm / maxRpm
        local speed = self:getLastSpeed()
        local totalMass = tonumber(self.getTotalMass ~= nil and self:getTotalMass() or 0) or 0
        local selfMass = tonumber(self.getTotalMass ~= nil and self:getTotalMass(true) or 0) or 0
        massRatio = selfMass > 0 and math.max(totalMass / selfMass, 0) or 1.0

        -- pull overload
        if motorLoad > C.PULL_OVERLOAD_THRESHOLD and speed > 0.5 then
            systemData.pullOverloadTimer = math.min(systemData.pullOverloadTimer + dt / 1000, C.PULL_OVERLOAD_TIMER_THRESHOLD)
            pullOverloadFactor = ADS_Utils.calculateQuadraticMultiplier(systemData.pullOverloadTimer, 0, false, C.PULL_OVERLOAD_TIMER_THRESHOLD)
            pullOverloadFactor = pullOverloadFactor * motorLoad * C.PULL_OVERLOAD_MULTIPLIER
            wearRate = wearRate + pullOverloadFactor
        else
            systemData.pullOverloadTimer = math.max(systemData.pullOverloadTimer - dt / 1000, 0)
        end

        -- lugging factor
        if motorLoad > C.LUGGING_MOTORLOAD_THRESHOLD and rpmLoad < C.LUGGING_RPM_THRESHOLD and speed > 0.5 then
            local minDiff = math.max(C.LUGGING_MOTORLOAD_THRESHOLD - C.LUGGING_RPM_THRESHOLD, 0)
            local maxDiff = 1 - (1 - C.LUGGING_MOTORLOAD_THRESHOLD) + (1 - C.LUGGING_RPM_THRESHOLD)
            local currentDiff = math.clamp(motorLoad - rpmLoad, 0.0, 1.0)
            luggingFactor = ADS_Utils.calculateQuadraticMultiplier(currentDiff, minDiff, false, maxDiff)
            luggingFactor = luggingFactor * C.LUGGING_MULTIPLIER
            wearRate = wearRate + luggingFactor
        end

        --- heavy trailer factor
        if massRatio > C.HEAVY_TRAILER_THRESHOLD and speed > 0.5 then
            heavyTrailerFactor = ADS_Utils.calculateQuadraticMultiplier(massRatio, C.HEAVY_TRAILER_THRESHOLD, false, 5.0)
            heavyTrailerFactor = math.max(heavyTrailerFactor * C.HEAVY_TRAILER_MULTIPLIER * motorLoad, 0)
            heavyTrailerFactor = math.min(heavyTrailerFactor, C.HEAVY_TRAILER_MULTIPLIER or heavyTrailerFactor)
            wearRate = wearRate + heavyTrailerFactor
        end

        -- wheel slip (0 = no slip, 1 = max slip)
        if spec_wheels ~= nil and spec_wheels.wheels ~= nil then
            local sum = 0.0
            local cnt = 0
            local bodySpeed = math.abs(self.lastSpeedReal or 0)
            local minBodySpeed = 0.00002
            local speedKmh = math.abs(speed or 0)
            local clamp = (MathUtil ~= nil and MathUtil.clamp) or math.clamp or function(value, minValue, maxValue)
                if value < minValue then return minValue end
                if value > maxValue then return maxValue end
                return value
            end

            for _, wheel in ipairs(spec_wheels.wheels) do
                local physicsWheel = wheel.physics
                local runtimeWheel = physicsWheel or wheel

                local node = runtimeWheel.node or wheel.node
                local wheelShape = runtimeWheel.wheelShape or wheel.wheelShape
                local hasShapeCreated = runtimeWheel.wheelShapeCreated == true or wheel.wheelShapeCreated == true
                local hasShape = wheelShape ~= nil and wheelShape ~= 0
                local netInfo = runtimeWheel.netInfo or wheel.netInfo
                local hasNetInfo = netInfo ~= nil
                local radius = tonumber(runtimeWheel.radius or runtimeWheel.radiusOriginal or wheel.radius or wheel.radiusOriginal) or 0
                local xDriveSpeed = (hasNetInfo and netInfo.xDriveSpeed ~= nil) and netInfo.xDriveSpeed or 0

                local hasKinematic = hasNetInfo and radius > 0
                local hasPhysical = hasShapeCreated and hasShape and node ~= nil and node ~= 0

                if hasKinematic or hasPhysical then
                    local ratio = 0
                    local kinematicSlip = 0
                    local physicalSlip = 0
                    local loadGate = clamp((motorLoad - 0.45) / 0.45, 0, 1)

                    if hasKinematic then
                        local wheelSpeed = math.abs(MathUtil.rpmToMps(xDriveSpeed / (2 * math.pi) * 60, radius)) -- m/ms
                        ratio = wheelSpeed / math.max(bodySpeed, minBodySpeed)
                        kinematicSlip = clamp((ratio - 1.15) / 1.35, 0, 1)
                    end

                    if hasPhysical then
                        local rawLongSlip, rawLatSlip = getWheelShapeSlip(node, wheelShape)
                        local longSlip = math.abs(tonumber(rawLongSlip) or 0)
                        local latSlip = math.abs(tonumber(rawLatSlip) or 0)
                        local physicalRaw = longSlip + latSlip * 0.15
                        physicalSlip = clamp((physicalRaw - 0.33) / 0.67, 0, 1)
                    end

                    local baseSlip = 0
                    if speedKmh < 1.0 then
                        baseSlip = math.max(kinematicSlip, physicalSlip * 0.25)
                    else
                        baseSlip = 0.8 * kinematicSlip + 0.2 * physicalSlip
                    end

                    local wheelSlip = clamp(baseSlip * loadGate, 0, 1)
                    if speedKmh < 0.5 and motorLoad < 0.25 then
                        wheelSlip = 0
                    end

                    sum = sum + wheelSlip
                    cnt = cnt + 1
                end
            end

            if cnt > 0 then
                wheelSlipIntensity = sum / cnt
            end
        end

        if wheelSlipIntensity < 0.01 then
            wheelSlipIntensity = 0
        end

        if wheelSlipIntensity > C.WHEEL_SLIP_THRESHOLD then
            wheelSlipFactor = ADS_Utils.calculateQuadraticMultiplier(wheelSlipIntensity, C.WHEEL_SLIP_THRESHOLD, false)
            wheelSlipFactor = wheelSlipFactor * (C.WHEEL_SLIP_MULTIPLIER or 0)
            wearRate = wearRate + wheelSlipFactor
        end

        spec.systems.transmission.wheelSlipIntensity = wheelSlipIntensity

        -- breakdown presence factor
        if self:hasSystemBreakdowns(systemKey) then
            local stagesSum = getBreakdownsStageSum(self, systemKey)
            breakdownPresenceFactor = stagesSum * (ADS_Config.CORE.BREAKDOWN_PRESENCE_FACTOR or 0)
            wearRate = wearRate + breakdownPresenceFactor
        end

        if vehicleHaveCVT then
            -- cold CVT factor
            if (spec.transmissionTemperature or -99) < C.COLD_TRANSMISSION_THRESHOLD and rpmLoad > 0.75 and not spec.isElectricVehicle and not self:getIsAIActive() then
                coldTransFactor = ADS_Utils.calculateQuadraticMultiplier(spec.transmissionTemperature, C.COLD_TRANSMISSION_THRESHOLD, true)
                local motorLoadInf = ADS_Utils.calculateQuadraticMultiplier(rpmLoad, 0.75, false)
                coldTransFactor = coldTransFactor * C.COLD_TRANSMISSION_MULTIPLIER * motorLoadInf
                coldTransFactor = math.min(coldTransFactor, C.COLD_TRANSMISSION_MULTIPLIER or coldTransFactor)
                wearRate = wearRate + coldTransFactor

            -- overheating CVT factor
            elseif (spec.transmissionTemperature or -99) > C.OVERHEAT_TRANSMISSION_THRESHOLD and motorLoad > 0.3 and not spec.isElectricVehicle then
                local transTemp = spec.transmissionTemperature
                hotTransFactor = ADS_Utils.calculateQuadraticMultiplier(transTemp, C.OVERHEAT_TRANSMISSION_THRESHOLD, false, 120)
                local motorLoadInf = ADS_Utils.calculateQuadraticMultiplier(rpmLoad, 0.75, false)
                hotTransFactor = hotTransFactor * C.OVERHEAT_TRANSMISSION_MAX_MULTIPLIER * motorLoadInf
                hotTransFactor = math.min(hotTransFactor, C.OVERHEAT_TRANSMISSION_MAX_MULTIPLIER or hotTransFactor)
                wearRate = wearRate + hotTransFactor
            end
        end

        -- idling
        if motorLoad < ADS_Config.CORE.ENGINE_FACTOR_DATA.MOTOR_IDLING_THRESHOLD and speed < 0.003 then
            wearRate = wearRate * C.TRANSMISSION_IDLING_MULTIPLIER
        end

        expiredServiceMultiplier = getExpiredServiceMultiplier(spec.serviceLevel, C.SERVICE_EXPIRED_MULTIPLIER or ADS_Config.CORE.ENGINE_FACTOR_DATA.SERVICE_EXPIRED_MULTIPLIER)
        local wearRateWithoutService = wearRate
        wearRate = wearRate * expiredServiceMultiplier
        expiredServiceFactor = wearRate - wearRateWithoutService
    else
        if hasCVTAddon(self) then
            local spec_CVTaddon = self.spec_CVTaddon
            spec_CVTaddon.CVTdamage = systemData.stress / math.max(systemData.condition, 0.001) * 100
        end

        if spec.isUnderRoof then 
            wearRate = wearRate * ADS_Config.CORE.UNDER_ROOF_DOWNTIME_MULTIPLIER 
        else
            wearRate = wearRate * ADS_Config.CORE.DOWNTIME_MULTIPLIER
        end
    end

    self:updateSystemConditionAndStress(dt, systemKey, wearRate, {
        expiredServiceFactor = expiredServiceFactor,
        pullOverloadFactor = pullOverloadFactor,
        pullOverloadTimer = systemData.pullOverloadTimer,
        heavyTrailerFactor = heavyTrailerFactor,
        heavyTrailerMassRatio = massRatio,
        luggingFactor = luggingFactor,
        wheelSlipFactor = wheelSlipFactor,
        wheelSlipIntensity = wheelSlipIntensity,
        coldTransFactor = coldTransFactor,
        coldMotorFactor = coldTransFactor,
        hotTransFactor = hotTransFactor,
        breakdownPresenceFactor = breakdownPresenceFactor
    })
end

-- hydraulics (heavyLift, operation, coldOperation, ptoOperation, ptoSharpAngle)
function AdvancedDamageSystem:updateHydraulicsSystem(dt)
    local spec = self.spec_AdvancedDamageSystem
    local systemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, spec.systems.hydraulics.name)
    local systemData = spec.systems.hydraulics
    local expiredServiceFactor = 0
    local C = ADS_Config.CORE.HYDRAULICS_FACTOR_DATA
    local heavyLiftFactor, operatingFactor, coldOilFactor, ptoOperatingFactor, sharpAngleFactor, breakdownPresenceFactor = 0, 0, 0, 0, 0, 0
    local ptoSharpAngleDeg = 0
    local expiredServiceMultiplier = 1.0
    local wearRate = 1.0
    local implements = {}
    local prevMoveAlphaCache = spec.hydraulicsMoveAlphaCache or {}
    local nextMoveAlphaCache = {}
    local vehicleMass = self.getTotalMass ~= nil and (self:getTotalMass(true) or 0) or 0
    local heavyLiftMassRatio, operatingMassRatio = 0, 0

    if not systemData.enabled then
        return
    end

    local function getSupportWheelCount(vehicleObj)
        local supportWheelCount = 0
        if vehicleObj ~= nil and vehicleObj.spec_wheels ~= nil and vehicleObj.spec_wheels.wheels ~= nil then
            for _, wheel in ipairs(vehicleObj.spec_wheels.wheels) do
                if wheel ~= nil then
                    local hasGroundContact = false
                    if wheel.physics ~= nil then
                        hasGroundContact = wheel.physics.hasGroundContact == true
                    elseif wheel.hasGroundContact ~= nil then
                        hasGroundContact = wheel.hasGroundContact == true
                    end
                    if hasGroundContact then
                        supportWheelCount = supportWheelCount + 1
                    end
                end
            end
        end
        return supportWheelCount
    end

    local function getMoveState(moveKey, jointDesc)
        local moveAlpha = jointDesc ~= nil and (jointDesc.moveAlpha or 0) or 0
        local prevMoveAlpha = prevMoveAlphaCache[moveKey]
        nextMoveAlphaCache[moveKey] = moveAlpha

        if prevMoveAlpha ~= nil then
            return math.abs(moveAlpha - prevMoveAlpha) > 0.05
        end

        local isMovingRaw = jointDesc ~= nil and jointDesc.isMoving == true
        return isMovingRaw and moveAlpha > 0.001 and moveAlpha < 0.999


    end

    local function getToolMotionFlags(vehicleObj)
        local isFoldMoving = false
        local isPlowRotationMoving = false
        local isCylinderedMoving = false

        if vehicleObj ~= nil and vehicleObj.spec_foldable ~= nil then
            isFoldMoving = math.abs(vehicleObj.spec_foldable.foldMoveDirection or 0) > 0.0001
        end

        if vehicleObj ~= nil and vehicleObj.spec_plow ~= nil and vehicleObj.spec_plow.rotationPart ~= nil and vehicleObj.spec_plow.rotationPart.turnAnimation ~= nil and vehicleObj.getIsAnimationPlaying ~= nil then
            isPlowRotationMoving = vehicleObj:getIsAnimationPlaying(vehicleObj.spec_plow.rotationPart.turnAnimation)
        end

        if vehicleObj ~= nil and vehicleObj.spec_cylindered ~= nil then
            isCylinderedMoving = vehicleObj.spec_cylindered.movingToolNeedsSound == true
        end

        return isFoldMoving, isPlowRotationMoving, isCylinderedMoving
    end

    local function getDefaultNode(vehicleObj)
        if vehicleObj == nil then
            return nil
        end
        if vehicleObj.steeringAxleNode ~= nil then
            return vehicleObj.steeringAxleNode
        end
        if vehicleObj.components ~= nil and vehicleObj.components[1] ~= nil then
            return vehicleObj.components[1].node
        end
        return nil
    end

    local function hasActivePtoInChain(rootVehicle)
        local visited = {}

        local function scan(vehicleObj)
            if vehicleObj == nil or visited[vehicleObj] then
                return false
            end
            visited[vehicleObj] = true

            local ptoActive = vehicleObj.getIsPowerTakeOffActive ~= nil and vehicleObj:getIsPowerTakeOffActive() or false
            local ptoConsuming = vehicleObj.getDoConsumePtoPower ~= nil and vehicleObj:getDoConsumePtoPower() or false
            local ptoRpm = vehicleObj.getPtoRpm ~= nil and (tonumber(vehicleObj:getPtoRpm()) or 0) or 0

            local ptoTorque = 0
            if PowerConsumer ~= nil and PowerConsumer.getTotalConsumedPtoTorque ~= nil then
                local ok, torqueValue = pcall(PowerConsumer.getTotalConsumedPtoTorque, vehicleObj, nil, nil, true)
                if ok then
                    ptoTorque = tonumber(torqueValue) or 0
                end
            end

            if ptoActive or ptoConsuming or ptoRpm > 10 or ptoTorque > 0.001 then
                return true
            end

            if vehicleObj.getAttachedImplements ~= nil then
                local attachedImplements = vehicleObj:getAttachedImplements() or {}
                for _, implement in pairs(attachedImplements) do
                    if implement ~= nil and implement.object ~= nil and scan(implement.object) then
                        return true
                    end
                end
            end

            return false
        end

        return scan(rootVehicle)
    end

    local function getMaxConnectedPtoAngleDeg(rootVehicle)
        local maxAngleDeg = 0
        local hasConnectedPto = false
        local visited = {}

        local function scan(vehicleObj)
            if vehicleObj == nil or visited[vehicleObj] then
                return
            end
            visited[vehicleObj] = true

            if vehicleObj.getAttachedImplements == nil then
                return
            end

            local attachedImplements = vehicleObj:getAttachedImplements() or {}
            for _, implement in pairs(attachedImplements) do
                if implement ~= nil and implement.object ~= nil then
                    local childObj = implement.object
                    local linkAngleDeg = 0
                    local hasLinkPto = false

                    if vehicleObj.getOutputPowerTakeOffsByJointDescIndex ~= nil and implement.jointDescIndex ~= nil then
                        local outputs = vehicleObj:getOutputPowerTakeOffsByJointDescIndex(implement.jointDescIndex) or {}
                        for _, output in ipairs(outputs) do
                            if output ~= nil and output.connectedInput ~= nil then
                                hasLinkPto = true
                                hasConnectedPto = true
                            end
                        end
                    end

                    if hasLinkPto and Utils ~= nil and Utils.getYRotationBetweenNodes ~= nil then
                        local parentNode = getDefaultNode(vehicleObj)
                        local childNode = getDefaultNode(childObj)
                        if parentNode ~= nil and childNode ~= nil then
                            local yRot = Utils.getYRotationBetweenNodes(parentNode, childNode) or 0
                            local horizontalAngleDeg = math.deg(math.abs(yRot))
                            linkAngleDeg = math.max(linkAngleDeg, horizontalAngleDeg)
                        end
                    end

                    maxAngleDeg = math.max(maxAngleDeg, linkAngleDeg)
                    scan(childObj)
                end
            end
        end

        scan(rootVehicle)
        return maxAngleDeg, hasConnectedPto
    end

    if self.getIsMotorStarted ~= nil and self:getIsMotorStarted() then
        local isPtoActive = hasActivePtoInChain(self)
        local headIsMoving = false
        if self.spec_attacherJoints ~= nil and self.spec_attacherJoints.attacherJoints ~= nil then
            for index, jointDesc in pairs(self.spec_attacherJoints.attacherJoints) do
                headIsMoving = headIsMoving or getMoveState('__head:' .. tostring(index), jointDesc)
            end
        end
        local headIsFoldMoving, headIsPlowRotationMoving, headIsCylinderedMoving = getToolMotionFlags(self)

        table.insert(implements, {
            mass = vehicleMass,
            jointTypeId = 0,
            isLowered = self.getIsLowered ~= nil and self:getIsLowered(false) or false,
            supportWheelCount = getSupportWheelCount(self),
            isMoving = headIsMoving,
            isFoldMoving = headIsFoldMoving,
            isPlowRotationMoving = headIsPlowRotationMoving,
            isCylinderedMoving = headIsCylinderedMoving,
            isHead = true
        })

        if self.spec_attacherJoints ~= nil and self.spec_attacherJoints.attachedImplements ~= nil then
            for _, implementData in pairs(self.spec_attacherJoints.attachedImplements) do
                local object = implementData.object
                if object ~= nil then
                    local jointDesc = nil
                    if self.spec_attacherJoints.attacherJoints ~= nil then
                        jointDesc = self.spec_attacherJoints.attacherJoints[implementData.jointDescIndex]
                    end

                    local isLowered = false
                    if object.getIsLowered ~= nil then
                        isLowered = object:getIsLowered(false)
                    elseif jointDesc ~= nil then
                        isLowered = jointDesc.moveDown == true
                    end

                    local isFoldMoving, isPlowRotationMoving, isCylinderedMoving = getToolMotionFlags(object)
                    local moveKey = string.format('%s:%s', tostring(object), tostring(implementData.jointDescIndex or -1))

                    table.insert(implements, {
                        mass = object.getTotalMass ~= nil and (object:getTotalMass(true) or 0) or 0,
                        jointTypeId = jointDesc ~= nil and jointDesc.jointType or nil,
                        isLowered = isLowered,
                        supportWheelCount = getSupportWheelCount(object),
                        isMoving = getMoveState(moveKey, jointDesc),
                        isFoldMoving = isFoldMoving,
                        isPlowRotationMoving = isPlowRotationMoving,
                        isCylinderedMoving = isCylinderedMoving,
                        isHead = false
                    })
                end
            end
        end

        spec.hydraulicsMoveAlphaCache = nextMoveAlphaCache

        local isImplementLifted = false
        local isImplementOperating = false
        local liftedMass = 0
        local operatingMass = 0
    
        for _, impl in ipairs(implements) do
            if impl.jointTypeId ~= 0 and impl.jointTypeId ~= 3 and not impl.isLowered and (impl.supportWheelCount or 0) == 0 then
                liftedMass = liftedMass + (impl.mass or 0)
                isImplementLifted = true
            end
            if (impl.isMoving and impl.jointTypeId ~= 0) or impl.isFoldMoving or impl.isPlowRotationMoving or (impl.isCylinderedMoving and not impl.isHead) then
                isImplementOperating  = true
                if not impl.isHead then operatingMass = operatingMass + (impl.mass or 0) end
            end
        end

        if isImplementLifted or isImplementOperating or isPtoActive then

            -- operating and cold oil
            if isImplementOperating then
                operatingMassRatio = vehicleMass > 0 and (operatingMass / vehicleMass) or 0
                if operatingMassRatio == 0 then
                    operatingMassRatio = 0.3
                end
                operatingFactor = ADS_Utils.calculateQuadraticMultiplier(operatingMassRatio, 0, false)
                operatingFactor = operatingFactor * (C.OPERATING_FACTOR_MULTIPLIER or 0)
                operatingFactor = math.min(operatingFactor, C.OPERATING_FACTOR_MULTIPLIER or operatingFactor)
                wearRate = wearRate + operatingFactor
                if (spec.engineTemperature or -99) < C.COLD_OIL_THRESHOLD then
                    coldOilFactor = ADS_Utils.calculateQuadraticMultiplier(spec.engineTemperature, C.COLD_OIL_THRESHOLD, true)
                    coldOilFactor = coldOilFactor * (C.COLD_OIL_MULTIPLIER or 0) * (1 + ADS_Utils.calculateQuadraticMultiplier(operatingMassRatio, 0, false))
                    coldOilFactor = math.min(coldOilFactor, (C.COLD_OIL_MULTIPLIER or 0) * 2)
                    wearRate = wearRate + coldOilFactor
                end
            end

            -- heavy lift
            heavyLiftMassRatio = vehicleMass > 0 and (liftedMass / vehicleMass) or 0
            if heavyLiftMassRatio > (C.HEAVY_LIFT_FACTOR_THRESHOLD or 0) then
                heavyLiftFactor = ADS_Utils.calculateQuadraticMultiplier(heavyLiftMassRatio, C.HEAVY_LIFT_FACTOR_THRESHOLD, false)
                heavyLiftFactor = heavyLiftFactor * (C.HEAVY_LIFT_FACTOR_MULTIPLIER or 0)
                heavyLiftFactor = math.min(heavyLiftFactor, C.HEAVY_LIFT_FACTOR_MULTIPLIER or heavyLiftFactor)
                wearRate = wearRate + heavyLiftFactor
            end

            -- pto operating
            if isPtoActive then
                ptoOperatingFactor = C.PTO_OPERATING_FACTOR or 0
                wearRate = wearRate + ptoOperatingFactor
                
                -- pto sharp angle factor
                local ptoAngleDeg, hasConnectedPto = getMaxConnectedPtoAngleDeg(self)
                ptoSharpAngleDeg = ptoAngleDeg
                local sharpAngleThreshold = C.PTO_SHARP_ANGLE_FACTOR_THRESHOLD or 30
                if sharpAngleThreshold <= (2 * math.pi + 0.001) then
                    sharpAngleThreshold = math.deg(sharpAngleThreshold)
                end

                if hasConnectedPto and ptoAngleDeg > sharpAngleThreshold then
                    sharpAngleFactor = ADS_Utils.calculateQuadraticMultiplier(ptoAngleDeg, sharpAngleThreshold, false, 50)
                    sharpAngleFactor = sharpAngleFactor * (C.PTO_SHARP_ANGLE_FACTOR_MULTIPLIER or 0)
                    sharpAngleFactor = math.min(sharpAngleFactor, C.PTO_SHARP_ANGLE_FACTOR_MULTIPLIER or sharpAngleFactor)
                    wearRate = wearRate + sharpAngleFactor
                end
            end


        else
            --idling
            wearRate = wearRate * C.HYDRAULICS_IDLING_MULTIPLIER
        end

        -- breakdown presence factor
        if self:hasSystemBreakdowns(systemKey) then
            local stagesSum = getBreakdownsStageSum(self, systemKey)
            breakdownPresenceFactor = stagesSum * (ADS_Config.CORE.BREAKDOWN_PRESENCE_FACTOR or 0)
            wearRate = wearRate + breakdownPresenceFactor
        end

        -- service factor
        expiredServiceMultiplier = getExpiredServiceMultiplier(spec.serviceLevel, C.SERVICE_EXPIRED_MULTIPLIER)
        local wearRateWithoutService = wearRate
        wearRate = wearRate * expiredServiceMultiplier
        expiredServiceFactor = wearRate - wearRateWithoutService

    else
        if spec.isUnderRoof then 
            wearRate = wearRate * ADS_Config.CORE.UNDER_ROOF_DOWNTIME_MULTIPLIER 
        else
            wearRate = wearRate * ADS_Config.CORE.DOWNTIME_MULTIPLIER
        end
    end

    self:updateSystemConditionAndStress(dt, systemKey, wearRate, {
        expiredServiceFactor = expiredServiceFactor,
        heavyLiftFactor = heavyLiftFactor,
        heavyLiftMassRatio = heavyLiftMassRatio,
        operatingFactor = operatingFactor,
        coldOilFactor = coldOilFactor,
        ptoOperatingFactor = ptoOperatingFactor,
        breakdownPresenceFactor = breakdownPresenceFactor,
        sharpAngleFactor = sharpAngleFactor,
        ptoSharpAngleDeg = ptoSharpAngleDeg
    })
end

-- cooling (highCooling, overheat, coldShock)
function AdvancedDamageSystem:updateCoolingSystem(dt)
    local spec = self.spec_AdvancedDamageSystem
    local spec_motorized = self.spec_motorized
    local systemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, spec.systems.cooling.name)
    local systemData = spec.systems.cooling
    local expiredServiceFactor = 0
    local C = ADS_Config.CORE.COOLING_FACTOR_DATA
    local highCoolingFactor, overheatFactor, coldShockFactor, breakdownPresenceFactor = 0, 0, 0, 0
    local wearRate = 1.0

    if not systemData.enabled then
        return
    end

    if self.getIsMotorStarted ~= nil and self:getIsMotorStarted() and not spec.isElectricVehicle then
        local lastRpm = spec_motorized.motor:getLastModulatedMotorRpm()
        local maxRpm = spec_motorized.motor.maxRpm
        local rpmLoad = lastRpm / maxRpm

        -- high cooling
        if spec.thermostatState > 0.0 then
            if spec.thermostatState > C.HIGH_COOLING_FACTOR_THRESHOLD then
                highCoolingFactor = ADS_Utils.calculateQuadraticMultiplier(spec.thermostatState, C.HIGH_COOLING_FACTOR_THRESHOLD, false)
                highCoolingFactor = highCoolingFactor * (C.HIGH_COOLING_FACTOR_MULTIPLIER or 0)
                highCoolingFactor = math.min(highCoolingFactor, C.HIGH_COOLING_FACTOR_MULTIPLIER or highCoolingFactor)
                wearRate = wearRate + highCoolingFactor
            end
        end

        -- overheat
        if (spec.engineTemperature or -99) > C.OVERHEAT_FACTOR_THRESHOLD then
            overheatFactor = ADS_Utils.calculateQuadraticMultiplier(spec.engineTemperature, C.OVERHEAT_FACTOR_THRESHOLD, false, 120)
            overheatFactor = overheatFactor * (C.OVERHEAT_FACTOR_MULTIPLIER or 0)
            overheatFactor = math.min(overheatFactor, C.OVERHEAT_FACTOR_MULTIPLIER or overheatFactor)
            wearRate = wearRate + overheatFactor
        end

        -- cold shock
        if (spec.engineTemperature or -99) < C.COLD_SHOCK_FACTOR_THRESHOLD and rpmLoad > 0.75 and not self:getIsAIActive() then
            coldShockFactor = ADS_Utils.calculateQuadraticMultiplier(spec.engineTemperature, C.COLD_SHOCK_FACTOR_THRESHOLD, true)
            local motorLoadInf = ADS_Utils.calculateQuadraticMultiplier(rpmLoad, 0.75, false)
            coldShockFactor = coldShockFactor * (C.COLD_SHOCK_FACTOR_MULTIPLIER or 0) * motorLoadInf
            coldShockFactor = math.min(coldShockFactor, C.COLD_SHOCK_FACTOR_MULTIPLIER or coldShockFactor)
            wearRate = wearRate + coldShockFactor
        end

        -- breakdown presence factor
        if self:hasSystemBreakdowns(systemKey) then
            local stagesSum = getBreakdownsStageSum(self, systemKey)
            breakdownPresenceFactor = stagesSum * (ADS_Config.CORE.BREAKDOWN_PRESENCE_FACTOR or 0)
            wearRate = wearRate + breakdownPresenceFactor
        end

        -- idling
        if spec.thermostatState == 0 and overheatFactor == 0 and coldShockFactor == 0 then
            wearRate = wearRate * C.COOLING_IDLING_MULTIPLIER
        end

        -- service factor
        local expiredServiceMultiplier = getExpiredServiceMultiplier(spec.serviceLevel, C.SERVICE_EXPIRED_MULTIPLIER)
        local wearRateWithoutService = wearRate
        wearRate = wearRate * expiredServiceMultiplier
        expiredServiceFactor = wearRate - wearRateWithoutService
    else
        if spec.isUnderRoof then 
            wearRate = wearRate * ADS_Config.CORE.UNDER_ROOF_DOWNTIME_MULTIPLIER 
        else
            wearRate = wearRate * ADS_Config.CORE.DOWNTIME_MULTIPLIER
        end
    end

    self:updateSystemConditionAndStress(dt, systemKey, wearRate, {
        expiredServiceFactor = expiredServiceFactor,
        highCoolingFactor = highCoolingFactor,
        overheatFactor = overheatFactor,
        coldShockFactor = coldShockFactor,
        breakdownPresenceFactor = breakdownPresenceFactor
    })
end

-- electrical (weather, cranking, lights, overheat)
function AdvancedDamageSystem:updateElectricalSystem(dt)
    local spec = self.spec_AdvancedDamageSystem
    local systemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, spec.systems.electrical.name)
    local systemData = spec.systems.electrical
    if systemData == nil then return end
    local expiredServiceFactor, weatherExposureFactor, lightsFactor, overheatFactor, crankingStressFactor, breakdownPresenceFactor = 0, 0, 0, 0, 0, 0
    local C = ADS_Config.CORE.ELECTRICAL_FACTOR_DATA
    local wearRate = 1.0

    if not systemData.enabled then
        return
    end

    local isOutdoor = not spec.isUnderRoof

    -- lights factor
    if self.spec_lights ~= nil and self.getLightsTypesMask ~= nil then
        local lightsSpec = self.spec_lights
        local lightsMask = tonumber(self:getLightsTypesMask()) or 0
        local maxLightStateMask = tonumber(lightsSpec.maxLightStateMask) or 0
        local activeMainLightsMask = lightsMask

        if maxLightStateMask > 0 and bitAND ~= nil then
            activeMainLightsMask = bitAND(lightsMask, maxLightStateMask)
        end

        if activeMainLightsMask > 0 then
            lightsFactor = C.LIGHTS_FACTOR_MULTIPLIER or 0
            wearRate = wearRate + lightsFactor
        end
    end

    -- weather factor
    if isOutdoor then
        local weatherType = ADS_Main.currentWeather
        if weatherType == WeatherType.RAIN then
            weatherExposureFactor = C.RAIN_FACTOR_MULTIPLIER or 0
        elseif weatherType == WeatherType.SNOW then
            weatherExposureFactor = C.SNOW_FACTOR_MULTIPLIER or 0
        elseif weatherType == WeatherType.HAIL then
            weatherExposureFactor = C.HAIL_FACTOR_MULTIPLIER or C.HALL_FACTOR_MULTIPLIER or 0
        end
        wearRate = wearRate + weatherExposureFactor
    end

    -- cranking stress damage while starter is engaged
    local engineHardStartEffect = spec.activeEffects ~= nil and spec.activeEffects.ENGINE_HARD_START_MODIFIER or nil
    local engineFailedEffect = spec.activeEffects ~= nil and spec.activeEffects.ENGINE_FAILURE or nil
    local isCranking = self:getMotorState() == 3 or 
        (engineHardStartEffect ~= nil and engineHardStartEffect.extraData ~= nil and engineHardStartEffect.extraData.status ~= nil and (engineHardStartEffect.extraData.status == "CRANKING" or engineHardStartEffect.extraData.status == "PASSED")) or 
        (engineFailedEffect ~= nil and engineFailedEffect.extraData ~= nil and engineFailedEffect.extraData.status ~= nil and engineFailedEffect.extraData.status == "CRANKING")

    if not spec.isElectricVehicle and isCranking then
        systemData.isCranking = true
        crankingStressFactor = C.CRANKING_STRESS_MULTIPLIER
        wearRate = wearRate + crankingStressFactor
    else
        systemData.isCranking = false
    end    

    if self:getIsMotorStarted() and not spec.isElectricVehicle then
        -- service factor
        local expiredServiceMultiplier = getExpiredServiceMultiplier(spec.serviceLevel, C.SERVICE_EXPIRED_MULTIPLIER)
        local wearRateWithoutService = wearRate
        wearRate = wearRate * expiredServiceMultiplier
        expiredServiceFactor = wearRate - wearRateWithoutService

        -- overheating engine compartment
        if (spec.engineTemperature or -99) > C.OVERHEAT_FACTOR_THRESHOLD then
            overheatFactor = ADS_Utils.calculateQuadraticMultiplier(spec.engineTemperature, C.OVERHEAT_FACTOR_THRESHOLD, false, 120)
            overheatFactor = overheatFactor * (C.OVERHEAT_FACTOR_MULTIPLIER or 0)
            overheatFactor = math.min(overheatFactor, C.OVERHEAT_FACTOR_MULTIPLIER or overheatFactor)
            wearRate = wearRate + overheatFactor
        end

        -- breakdown presence factor
        if self:hasSystemBreakdowns(systemKey) then
            local stagesSum = getBreakdownsStageSum(self, systemKey)
            breakdownPresenceFactor = stagesSum * (ADS_Config.CORE.BREAKDOWN_PRESENCE_FACTOR or 0)
            wearRate = wearRate + breakdownPresenceFactor
        end

    elseif lightsFactor == 0 and crankingStressFactor == 0 then 
        if spec.isUnderRoof then 
            wearRate = wearRate * ADS_Config.CORE.UNDER_ROOF_DOWNTIME_MULTIPLIER 
        else
            wearRate = wearRate * ADS_Config.CORE.DOWNTIME_MULTIPLIER 
        end
    end

    self:updateSystemConditionAndStress(dt, systemKey, wearRate, {
        expiredServiceFactor = expiredServiceFactor,
        crankingStressFactor = crankingStressFactor,
        weatherExposureFactor = weatherExposureFactor,
        lightsFactor = lightsFactor,
        overheatFactor = overheatFactor,
        breakdownPresenceFactor = breakdownPresenceFactor
    })
end

-- chassis (vibration, steering load, braking under mass)
function AdvancedDamageSystem:updateChassisSystem(dt)
    local spec = self.spec_AdvancedDamageSystem
    local systemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, spec.systems.chassis.name)
    local systemData = spec.systems.chassis
    local expiredServiceFactor = 0
    local vibFactor = 0
    local vibSignal = 0
    local vibRaw = 0
    local vibWheelCount = 0
    local vibSpeedFactor = 0
    local vibAvgDensityType = 0
    local vibFieldMultiplier = 1
    local steerLoadFactor = 0
    local steerInputAbs = 0
    local steerDeltaRate = 0
    local steerLowSpeedFactor = 0
    local steerAngleFactor = 0
    local steerChangeFactor = 0
    local steerGroundContact = 0
    local brakeMassFactor = 0
    local brakeMassRatio = 0
    local brakePedal = 0
    local breakdownPresenceFactor = 0
    local C = ADS_Config.CORE.CHASSIS_FACTOR_DATA
    local wearRate = 1.0

    if not systemData.enabled then
        return
    end

    local speed = tonumber(self.getLastSpeed ~= nil and self:getLastSpeed() or 0) or 0

    if self.getIsMotorStarted ~= nil and self:getIsMotorStarted() then
        if speed > 0.003 then
             -- vibration
            local vibState = spec.chassisVibState
            if vibState == nil then
                vibState = {
                    prevSuspension = {},
                    smoothed = 0
                }
                spec.chassisVibState = vibState
            end

            local prevSuspension = vibState.prevSuspension or {}
            vibState.prevSuspension = prevSuspension

            local sumSuspNorm = 0
            local countSuspNorm = 0
            local sumDensityType = 0
            local countDensityType = 0

            if self.spec_wheels ~= nil and self.spec_wheels.wheels ~= nil then
                for wheelIndex, wheel in ipairs(self.spec_wheels.wheels) do
                    local runtimeWheel = wheel.physics or wheel
                    local netInfo = runtimeWheel.netInfo or wheel.netInfo
                    local suspTravel = tonumber(runtimeWheel.suspTravel or wheel.suspTravel) or 0
                    local suspLength = tonumber((netInfo and netInfo.suspensionLength) or runtimeWheel.suspensionLength or wheel.suspensionLength) or 0
                    local prevSuspLength = tonumber(prevSuspension[wheelIndex]) or suspLength
                    local suspDelta = math.abs(suspLength - prevSuspLength)
                    prevSuspension[wheelIndex] = suspLength

                    local suspNorm = 0
                    if suspTravel > 0.0001 then
                        suspNorm = math.min(suspDelta / suspTravel, 3.0)
                    end

                    local hasGroundContact = false
                    if wheel.physics ~= nil and wheel.physics.hasGroundContact ~= nil then
                        hasGroundContact = wheel.physics.hasGroundContact == true
                    elseif runtimeWheel.hasGroundContact ~= nil then
                        hasGroundContact = runtimeWheel.hasGroundContact == true
                    elseif wheel.hasGroundContact ~= nil then
                        hasGroundContact = wheel.hasGroundContact == true
                    end

                    local densityType = tonumber(runtimeWheel.densityType or wheel.densityType) or -1

                    if hasGroundContact then
                        sumSuspNorm = sumSuspNorm + suspNorm
                        countSuspNorm = countSuspNorm + 1
                        if densityType >= 0 then
                            sumDensityType = sumDensityType + densityType
                            countDensityType = countDensityType + 1
                        end
                    end
                end
            end

            vibRaw = countSuspNorm > 0 and (sumSuspNorm / countSuspNorm) or 0
            vibWheelCount = countSuspNorm
            local speedForDamage = math.clamp(speed, 0.0, 50.0)
            vibSpeedFactor = ADS_Utils.calculateQuadraticMultiplier(speedForDamage, 0.0, false, 30.0)
            local vibSignalRaw = vibRaw * vibSpeedFactor
            local alpha = dt / (300 + dt)
            vibState.smoothed = vibState.smoothed + (vibSignalRaw - vibState.smoothed) * alpha
            vibSignal = vibState.smoothed
            vibAvgDensityType = countDensityType > 0 and (sumDensityType / countDensityType) or 0
            if vibAvgDensityType > 1 then
                vibFieldMultiplier = tonumber(C.VIB_FIELD_MULTIPLIER) or 1.3
            end

            local vibThreshold = tonumber(C.VIB_FACTOR_THRESHOLD) or 0.12
            local vibMaxSignal = tonumber(C.VIB_FACTOR_MAX_SIGNAL) or 0.22
            local vibMaxForCurve = math.max(vibMaxSignal, vibThreshold + 0.001)
            local vibMultiplier = (tonumber(C.VIB_FACTOR_MULTIPLIER) or 4.0) * vibFieldMultiplier
            if vibSignal > vibThreshold then
                vibFactor = ADS_Utils.calculateQuadraticMultiplier(vibSignal, vibThreshold, false, vibMaxForCurve)
                vibFactor = vibFactor * vibMultiplier
                vibFactor = math.min(vibFactor, vibMultiplier)
                wearRate = wearRate + vibFactor
            end

            -- steering load at standstill / low speed
            local steerSpeedThreshold = tonumber(C.STEER_LOAD_SPEED_THRESHOLD) or 4.0
            if steerSpeedThreshold > 0 and speed <= steerSpeedThreshold then
                local steerState = spec.chassisSteerState
                if steerState == nil then
                    steerState = {
                        prevSteerAbs = nil
                    }
                    spec.chassisSteerState = steerState
                end

                local steeringDirectionAbs = 0
                if self.spec_wheels ~= nil and self.spec_wheels.rotatedTime ~= nil then
                    steeringDirectionAbs = math.abs(tonumber(self.spec_wheels.rotatedTime) or 0)
                elseif self.getSteeringDirection ~= nil then
                    steeringDirectionAbs = math.abs(tonumber(self:getSteeringDirection()) or 0)
                end
                steerInputAbs = math.clamp(steeringDirectionAbs, 0, 1)

                local prevSteerAbs = tonumber(steerState.prevSteerAbs) or steerInputAbs
                steerState.prevSteerAbs = steerInputAbs
                local dtSafe = math.max(tonumber(dt) or 0, 1)
                steerDeltaRate = math.clamp(math.abs(steerInputAbs - prevSteerAbs) * 1000 / dtSafe, 0, 1)

                if self.spec_wheels ~= nil and self.spec_wheels.wheels ~= nil then
                    for _, wheel in ipairs(self.spec_wheels.wheels) do
                        local hasGroundContact = false
                        if wheel.physics ~= nil and wheel.physics.hasGroundContact ~= nil then
                            hasGroundContact = wheel.physics.hasGroundContact == true
                        elseif wheel.hasGroundContact ~= nil then
                            hasGroundContact = wheel.hasGroundContact == true
                        end

                        if hasGroundContact then
                            steerGroundContact = 1
                            break
                        end
                    end
                end

                if steerGroundContact > 0 then
                    steerLowSpeedFactor = ADS_Utils.calculateQuadraticMultiplier(math.clamp(speed, 0, steerSpeedThreshold), steerSpeedThreshold, true)
                    steerAngleFactor = ADS_Utils.calculateQuadraticMultiplier(steerInputAbs, tonumber(C.STEER_LOAD_STEER_THRESHOLD) or 0.2, false, 1.0)
                    steerChangeFactor = ADS_Utils.calculateQuadraticMultiplier(steerDeltaRate, tonumber(C.STEER_LOAD_CHANGE_THRESHOLD) or 0.08, false, 1.0)

                    if steerChangeFactor > 0 and steerLowSpeedFactor > 0 then
                        local steerSignal = (0.35 + 0.65 * steerAngleFactor) * steerChangeFactor * steerLowSpeedFactor
                        local aiMultiplier = self:getIsAIActive() and 0.25 or 1.0
                        steerLoadFactor = steerSignal * (tonumber(C.STEER_LOAD_FACTOR_MULTIPLIER) or 5.0) * aiMultiplier
                        wearRate = wearRate + steerLoadFactor
                    end
                end
            end

            -- braking under mass
            local drivable = self.spec_drivable
            if drivable ~= nil and self.spec_wheels ~= nil then
                local brakePedalRaw = tonumber(self.spec_wheels.brakePedal) or 0
                local axisForward = tonumber(drivable.axisForward or drivable.axisForwardSend or (drivable.lastInputValues and drivable.lastInputValues.axisForward) or 0) or 0
                local movingDirection = tonumber(self.movingDirection) or 0
                local directionMode = self.getDirectionChangeMode ~= nil and self:getDirectionChangeMode() or 1
                local isBrakingByAxis = false
                if directionMode == 2 then
                    isBrakingByAxis = axisForward < -0.01
                else
                    isBrakingByAxis = movingDirection ~= 0 and axisForward ~= 0 and math.sign(movingDirection) ~= math.sign(axisForward)
                end

                local brakePedalThreshold = tonumber(C.BRAKE_PEDAL_THRESHOLD) or 0.15
                brakePedal = math.clamp(brakePedalRaw, 0, 1)
                local isBraking = isBrakingByAxis or brakePedal > brakePedalThreshold

                if isBraking and speed > (tonumber(C.BRAKE_MASS_SPEED_THRESHOLD) or 2.0) then
                    local ownMass = tonumber(self.getTotalMass ~= nil and self:getTotalMass(true) or 0) or 0
                    local totalMass = tonumber(self.getTotalMass ~= nil and self:getTotalMass() or 0) or 0
                    if ownMass > 0 then
                        brakeMassRatio = math.max(totalMass / ownMass, 0)
                        local ratioThreshold = tonumber(C.BRAKE_MASS_RATIO_THRESHOLD) or 1.0
                        local ratioMax = math.max(tonumber(C.BRAKE_MASS_RATIO_MAX) or 1.5, ratioThreshold + 0.01)
                        if brakeMassRatio > ratioThreshold then
                            local ratioFactor = ADS_Utils.calculateQuadraticMultiplier(brakeMassRatio, ratioThreshold, false, ratioMax)
                            local brakeInputFactor = math.max(brakePedal, isBrakingByAxis and 1 or 0)
                            brakeMassFactor = ratioFactor * brakeInputFactor * (tonumber(C.BRAKE_MASS_FACTOR_MULTIPLIER) or 6.0)
                            brakeMassFactor = math.min(brakeMassFactor, tonumber(C.BRAKE_MASS_FACTOR_MULTIPLIER) or brakeMassFactor)
                            wearRate = wearRate + brakeMassFactor
                        end
                    end
                end

            end

            -- breakdown presence factor
            if self:hasSystemBreakdowns(systemKey) then
                local stagesSum = getBreakdownsStageSum(self, systemKey)
                breakdownPresenceFactor = stagesSum * (ADS_Config.CORE.BREAKDOWN_PRESENCE_FACTOR or 0)
                wearRate = wearRate + breakdownPresenceFactor
            end
        else
            wearRate = wearRate * C.CHASSIS_IDLING_MULTIPLIER    
        end

        -- service
        if not spec.isElectricVehicle then
            local expiredServiceMultiplier = getExpiredServiceMultiplier(spec.serviceLevel, C.SERVICE_EXPIRED_MULTIPLIER)
            local wearRateWithoutService = wearRate
            wearRate = wearRate * expiredServiceMultiplier
            expiredServiceFactor = wearRate - wearRateWithoutService
        end
    else
        if spec.isUnderRoof then 
            wearRate = wearRate * ADS_Config.CORE.UNDER_ROOF_DOWNTIME_MULTIPLIER 
        else
            wearRate = wearRate * ADS_Config.CORE.DOWNTIME_MULTIPLIER 
        end
    end

    self:updateSystemConditionAndStress(dt, systemKey, wearRate, {
        expiredServiceFactor = expiredServiceFactor,
        vibFactor = vibFactor,
        vibSignal = vibSignal,
        vibRaw = vibRaw,
        vibWheelCount = vibWheelCount,
        vibSpeedFactor = vibSpeedFactor,
        vibSpeedKmh = speed,
        vibAvgDensityType = vibAvgDensityType,
        vibFieldMultiplier = vibFieldMultiplier,
        steerLoadFactor = steerLoadFactor,
        steerInputAbs = steerInputAbs,
        steerDeltaRate = steerDeltaRate,
        steerLowSpeedFactor = steerLowSpeedFactor,
        steerAngleFactor = steerAngleFactor,
        steerChangeFactor = steerChangeFactor,
        steerGroundContact = steerGroundContact,
        brakeMassFactor = brakeMassFactor,
        brakeMassRatio = brakeMassRatio,
        brakePedal = brakePedal,
        breakdownPresenceFactor = breakdownPresenceFactor
    })
end

-- fuel (lowFuel, coldFuel, idle deposit, highPressure)
function AdvancedDamageSystem:updateFuelSystem(dt)
    local spec = self.spec_AdvancedDamageSystem
    local systemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, spec.systems.fuel.name)
    local systemData = spec.systems.fuel
    if systemData == nil then return end
    local lowFuelStarvationFactor, coldFuelFactor = 0, 0
    local expiredServiceFactor, fuelLevel, fuelTemperature, idleDepositFactor, highPressureFactor, breakdownPresenceFactor = 0, 0, 0, 0, 0, 0
    local currentFuelUsageRatio = 0
    local C = ADS_Config.CORE.FUEL_FACTOR_DATA
    local wearRate = 1.0

    if not systemData.enabled then
        return
    end

    local function getFuelLevel()
        local fuelFillUnit = nil
        if self.getConsumerFillUnitIndex ~= nil and FillType ~= nil and FillType.DIESEL ~= nil then
            fuelFillUnit = self:getConsumerFillUnitIndex(FillType.DIESEL)
        end

        if type(fuelFillUnit) == "table" then
            fuelFillUnit = tonumber(fuelFillUnit.fillUnitIndex or fuelFillUnit.index or fuelFillUnit[1])
        end

        local dieselType = FillType ~= nil and FillType.DIESEL or nil
        local methaneType = FillType ~= nil and FillType.METHANE or nil
        local electricType = FillType ~= nil and FillType.ELECTRICCHARGE or nil

        if fuelFillUnit == nil and self.spec_motorized ~= nil and self.spec_motorized.consumers ~= nil then
            for _, consumer in pairs(self.spec_motorized.consumers) do
                if consumer ~= nil and consumer.fillUnitIndex ~= nil then
                    local fillType = consumer.fillType
                    if fillType == dieselType or fillType == methaneType or fillType == electricType then
                        fuelFillUnit = consumer.fillUnitIndex
                        break
                    end
                end
            end
        end

        if fuelFillUnit ~= nil then
            local fuelLiters = tonumber(self:getFillUnitFillLevel(fuelFillUnit)) or 0
            local fuelCapacity = tonumber(self:getFillUnitCapacity(fuelFillUnit)) or 0
            local fuelPct = fuelCapacity > 0 and (fuelLiters / fuelCapacity) or 0
            return fuelPct, fuelLiters, fuelCapacity, fuelFillUnit
        end

        return 0, 0, 0, nil
    end

    local function getFuelUsageData()
        local motorizedSpec = self.spec_motorized
        if motorizedSpec == nil then
            return 0, 0
        end

        local fuelConsumer = nil

        if motorizedSpec.consumersByFillTypeName ~= nil then
            fuelConsumer = motorizedSpec.consumersByFillTypeName["DIESEL"]
                or motorizedSpec.consumersByFillTypeName["METHANE"]
                or motorizedSpec.consumersByFillTypeName["ELECTRICCHARGE"]
        end

        if fuelConsumer == nil and motorizedSpec.consumers ~= nil then
            for _, consumer in pairs(motorizedSpec.consumers) do
                if consumer ~= nil and consumer.fillType ~= nil then
                    if consumer.fillType == FillType.DIESEL
                    or consumer.fillType == FillType.METHANE
                    or consumer.fillType == FillType.ELECTRICCHARGE then
                        fuelConsumer = consumer
                        break
                    end
                end
            end
        end

        local baseFuelUsageLh = 0
        if fuelConsumer ~= nil and fuelConsumer.usage ~= nil then
            if fuelConsumer.permanentConsumption then
                baseFuelUsageLh = (fuelConsumer.usage or 0) * 60 * 60 * 1000
            else
                baseFuelUsageLh = fuelConsumer.usage or 0
            end
        end

        local currentFuelUsageLh = motorizedSpec.lastFuelUsage or 0

        local missionInfo = g_currentMission ~= nil and g_currentMission.missionInfo or nil
        local usageFactor = 1.5
        if missionInfo ~= nil then
            if missionInfo.fuelUsage == 1 then
                usageFactor = 1.0
            elseif missionInfo.fuelUsage == 3 then
                usageFactor = 2.5
            end
        end

        local damageFactor = 1.0
        if self.getVehicleDamage ~= nil and Motorized ~= nil and Motorized.DAMAGED_USAGE_INCREASE ~= nil then
            local vehicleDamage = self:getVehicleDamage() or 0
            if vehicleDamage > 0 then
                damageFactor = damageFactor * (1 + vehicleDamage * Motorized.DAMAGED_USAGE_INCREASE)
            end
        end

        local maxFuelUsageLh = baseFuelUsageLh * usageFactor * damageFactor

        return currentFuelUsageLh, maxFuelUsageLh
    end

    if self.getIsMotorStarted ~= nil and self:getIsMotorStarted() and not spec.isElectricVehicle then
        local motorLoad = self:getMotorLoadPercentage()
        fuelLevel = getFuelLevel()
        local currentFuelUsageLh, maxFuelUsageLh = getFuelUsageData()
        if maxFuelUsageLh > 0 then
            currentFuelUsageRatio = currentFuelUsageLh / maxFuelUsageLh
        else
            currentFuelUsageRatio = 0
        end

        -- low fuel
        if fuelLevel < C.LOW_FUEL_THRESHOLD then
            lowFuelStarvationFactor = ADS_Utils.calculateQuadraticMultiplier(fuelLevel, C.LOW_FUEL_THRESHOLD, true)
            local motorLoadInf = 1 + ADS_Utils.calculateQuadraticMultiplier(motorLoad, 0.70, false)
            lowFuelStarvationFactor = lowFuelStarvationFactor * motorLoadInf * C.LOW_FUEL_FACTOR_MULTIPLIER
            wearRate = wearRate + lowFuelStarvationFactor
        end

        -- cold fuel factor
        local environmentTemp = 20
        if g_currentMission ~= nil and g_currentMission.environment ~= nil and g_currentMission.environment.weather ~= nil and g_currentMission.environment.weather.forecast ~= nil then
            local weather = g_currentMission.environment.weather.forecast:getCurrentWeather()
            if weather ~= nil and weather.temperature ~= nil then
                environmentTemp = weather.temperature
            end
        end

        fuelTemperature = math.max(spec.engineTemperature / 3.6, environmentTemp)
        if fuelTemperature < C.COLD_FUEL_THRESHOLD and motorLoad > 0.5 then
            coldFuelFactor = ADS_Utils.calculateQuadraticMultiplier(fuelTemperature, C.COLD_FUEL_THRESHOLD, true)
            local motorLoadInf = ADS_Utils.calculateQuadraticMultiplier(motorLoad, 0.50, false)
            coldFuelFactor = coldFuelFactor * motorLoadInf * C.COLD_FUEL_FACTOR_MULTIPLIER
            coldFuelFactor = math.min(coldFuelFactor, C.COLD_FUEL_FACTOR_MULTIPLIER or coldFuelFactor)
            wearRate = wearRate + coldFuelFactor
        end

        -- idle deposit
        local idleSpeedThreshold = tonumber(C.IDLE_DEPOSIT_SPEED_THRESHOLD) or 0.5
        local idleLoadThreshold = tonumber(C.IDLE_DEPOSIT_LOAD_THRESHOLD) or 0.3
        local idleTimer = math.max(tonumber(systemData.idleTimer) or 0, 0)
        local isIdle = (self:getLastSpeed() or 0) <= idleSpeedThreshold and motorLoad <= idleLoadThreshold

        if isIdle then
            idleTimer = math.min(idleTimer + dt / 1000, C.IDLE_DEPOSIT_FACTOR_MAX_TIMER)
            if idleTimer >= C.IDLE_DEPOSIT_FACTOR_TIMER_THRESHOLD then
                idleDepositFactor = ADS_Utils.calculateQuadraticMultiplier(
                    idleTimer,
                    C.IDLE_DEPOSIT_FACTOR_TIMER_THRESHOLD,
                    false,
                    C.IDLE_DEPOSIT_FACTOR_MAX_TIMER
                )
                idleDepositFactor = idleDepositFactor * C.IDLE_DEPOSIT_FACTOR_MULTIPLIER
                wearRate = wearRate + idleDepositFactor
            end
        else
            idleTimer = 0
        end
        systemData.idleTimer = idleTimer

        -- high pressure factor
        local highPressureThreshold = tonumber(C.HIGH_PRESSURE_FACTOR_THRESHOLD) or 0.8
        if currentFuelUsageRatio > highPressureThreshold then
            highPressureFactor = ADS_Utils.calculateQuadraticMultiplier(currentFuelUsageRatio, highPressureThreshold, false)
            highPressureFactor = math.min(highPressureFactor * C.HIGH_PRESSURE_FACTOR_MULTIPLIER, C.HIGH_PRESSURE_FACTOR_MULTIPLIER)
            wearRate = wearRate + highPressureFactor
        end

        -- breakdown presence factor
        if self:hasSystemBreakdowns(systemKey) then
            local stagesSum = getBreakdownsStageSum(self, systemKey)
            breakdownPresenceFactor = stagesSum * (ADS_Config.CORE.BREAKDOWN_PRESENCE_FACTOR or 0)
            wearRate = wearRate + breakdownPresenceFactor
        end

        -- service
        local expiredServiceMultiplier = getExpiredServiceMultiplier(spec.serviceLevel, C.SERVICE_EXPIRED_MULTIPLIER)
        local wearRateWithoutService = wearRate
        wearRate = wearRate * expiredServiceMultiplier
        expiredServiceFactor = wearRate - wearRateWithoutService
    else
        if spec.isUnderRoof then 
            wearRate = wearRate * ADS_Config.CORE.UNDER_ROOF_DOWNTIME_MULTIPLIER 
        else
            wearRate = wearRate * ADS_Config.CORE.DOWNTIME_MULTIPLIER
        end
    end

    self:updateSystemConditionAndStress(dt, systemKey, wearRate, {
        expiredServiceFactor = expiredServiceFactor,
        lowFuelStarvationFactor = lowFuelStarvationFactor,
        coldFuelFactor = coldFuelFactor,
        idleDepositFactor = idleDepositFactor,
        highPressureFactor = highPressureFactor,
        currentFuelUsageRatio = currentFuelUsageRatio,
        breakdownPresenceFactor = breakdownPresenceFactor,
        idleTimer = systemData.idleTimer or 0,
        fuelLevel = fuelLevel,
        fuelTemperature = fuelTemperature
    })
end

-- workprocess (longHarves, wetCrop)
function AdvancedDamageSystem:updateWorkProcessSystem(dt)
    local spec = self.spec_AdvancedDamageSystem
    local spec_combine = self.spec_combine
    local spec_cutter = self.spec_cutter
    local systemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, spec.systems.workprocess.name)
    local systemData = ensureSystemData(spec, systemKey)
    local expiredServiceFactor = 0
    local wetCropFactor, breakdownPresenceFactor, lubricationFactor = 0, 0, 0
    local C = ADS_Config.CORE.WORKPROCESS_FACTOR_DATA
    local wearRate = 1.0

    if not systemData.enabled then
        return
    end

    local isMotorStarted = self.getIsMotorStarted ~= nil and self:getIsMotorStarted()
    local isTurnedOn = self.getIsTurnedOn ~= nil and self:getIsTurnedOn()

    local currentWeather = ADS_Main.currentWeather
    local isHail = (WeatherType.HAIL ~= nil and currentWeather == WeatherType.HAIL) or (WeatherType.HALL ~= nil and currentWeather == WeatherType.HALL)
    local isWetWeather = currentWeather == WeatherType.RAIN or currentWeather == WeatherType.SNOW or isHail
    
    
    local function isHarvesting(vehicle)
        local cutterArea = 0

        if vehicle == nil or not vehicle:getIsOnField() or vehicle:getLastSpeed() < 0.5 then
            return false
        end

        if vehicle.getIsTurnedOn ~= nil and not vehicle:getIsTurnedOn() then
            return false
        end

        if vehicle.spec_attacherJoints ~= nil and vehicle.spec_attacherJoints.attachedImplements ~= nil then
            for _, implementData in pairs(vehicle.spec_attacherJoints.attachedImplements) do
                local implement = implementData.object

                if implement ~= nil and implement.spec_cutter ~= nil and implement.spec_cutter.workAreaParameters ~= nil then
                    cutterArea = math.max(cutterArea, implement.spec_cutter.workAreaParameters.lastArea or 0)
                end
            end
        end

        if cutterArea <= 0 and vehicle.spec_cutter ~= nil and vehicle.spec_cutter.workAreaParameters ~= nil then
            cutterArea = vehicle.spec_cutter.workAreaParameters.lastArea or 0
        end
        return cutterArea > 0
    end
    
    local isHarvestingInProcess = isHarvesting(self)

    if isMotorStarted and not spec.isElectricVehicle then
        if not isTurnedOn then
            wearRate = wearRate * C.WORKPROCESSS_IDLING_MULTIPLIER
        end

        -- wetCrop
        if isTurnedOn and isWetWeather and isHarvestingInProcess then
            wetCropFactor = C.WET_CROP_FACTOR_MULTIPLIER
            wearRate = wearRate + wetCropFactor
        end

        -- lubrication
        if isTurnedOn and spec.isVehicleNeedLubricate then
            lubricationFactor = ADS_Utils.calculateQuadraticMultiplier(spec.lubricationLevel, 1.0, true, 0)
            lubricationFactor = lubricationFactor * (C.LUBRICATION_FACTOR_MULTIPLIER or 0)
            wearRate = wearRate + lubricationFactor
        end

        -- breakdown presence factor
        if self:hasSystemBreakdowns(systemKey) then
            local stagesSum = getBreakdownsStageSum(self, systemKey)
            breakdownPresenceFactor = stagesSum * (ADS_Config.CORE.BREAKDOWN_PRESENCE_FACTOR or 0)
            wearRate = wearRate + breakdownPresenceFactor
        end  

        -- service
        local expiredServiceMultiplier = getExpiredServiceMultiplier(spec.serviceLevel, C.SERVICE_EXPIRED_MULTIPLIER)
        local wearRateWithoutService = wearRate
        wearRate = wearRate * expiredServiceMultiplier
        expiredServiceFactor = wearRate - wearRateWithoutService
    else
        if spec.isUnderRoof then 
            wearRate = wearRate * ADS_Config.CORE.UNDER_ROOF_DOWNTIME_MULTIPLIER 
        else
            wearRate = wearRate * ADS_Config.CORE.DOWNTIME_MULTIPLIER 
        end
    end

    self:updateSystemConditionAndStress(dt, systemKey, wearRate, {
        expiredServiceFactor = expiredServiceFactor,
        wetCropFactor = wetCropFactor,
        lubricationFactor = lubricationFactor,
        breakdownPresenceFactor = breakdownPresenceFactor
    })
end

---------------------- breakdowns ----------------------

function AdvancedDamageSystem:tryTriggerBreakdown(dt)
    local spec = self.spec_AdvancedDamageSystem
    if not spec or dt == 0 then
        return
    end

    local probabilityData = ADS_Config.CORE.BREAKDOWN_PROBABILITIES
    local conditionEffectiveFloor = ADS_Config.CORE.CONDITION_EFFECTIVE_FLOOR or 0.15

    for systemName, systemData in pairs(spec.systems) do
        if systemData.name == AdvancedDamageSystem.SYSTEMS.TRANSMISSION and hasCVTAddon(self) then
            -- skip transmission breakdowns if CVT addon is present
        else
            local systemCondition = math.max(systemData.condition or 1.0, 0.001)
            local effectiveCondition = math.max(systemCondition, conditionEffectiveFloor)
            local systemStress = math.max(systemData.stress or 0.0, 0.0)
            local stressThreshold = probabilityData.STRESS_THRESHOLD
            local hourlyProb = 0.0

            local stressRatio = math.max(systemStress / effectiveCondition, 0.0)
            if stressRatio >= stressThreshold then
                local failureChancePerFrame = AdvancedDamageSystem.calculateBreakdownProbability(stressRatio, probabilityData, dt)
                hourlyProb = 1 - (1 - failureChancePerFrame) ^ (3600000 / dt)

                local random = math.random()
                if random < failureChancePerFrame or systemStress >= effectiveCondition then
                    local systemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, systemData.name)
                    local breakdownId = self:getRandomBreakdownBySystem(systemKey)
                    if breakdownId ~= nil then
                        local registryEntry = ADS_Breakdowns.BreakdownRegistry[breakdownId]
                        if registryEntry ~= nil and registryEntry.stages ~= nil and #registryEntry.stages > 0 then
                            local criticalOutcomeChance = ADS_Utils.getCriticalFailureChance(systemCondition)
                            if math.random() < criticalOutcomeChance then
                                self:addBreakdown(breakdownId, #registryEntry.stages)
                            else
                                local stage = 1
                                if systemCondition <= ADS_Config.CORE.GENERAL_WEAR_LATE_STAGE_THRESHOLD then
                                    stage = 3
                                elseif systemCondition <= ADS_Config.CORE.GENERAL_WEAR_EARLY_STAGE_THRESHOLD then
                                    stage = 2
                                end
                                self:addBreakdown(breakdownId, stage)
                            end

                            systemData.stress = systemStress * ADS_Config.CORE.STRESS_COOLDOWN
                            systemStress = math.max(systemData.stress or 0.0, 0.0)

                            local cooledStressRatio = math.max(systemStress / effectiveCondition, 0.0)
                            if cooledStressRatio >= stressThreshold then
                                local cooledFailureChancePerFrame = AdvancedDamageSystem.calculateBreakdownProbability(cooledStressRatio, probabilityData, dt)
                                hourlyProb = 1 - (1 - cooledFailureChancePerFrame) ^ (3600000 / dt)
                            else
                                hourlyProb = 0.0
                            end
                        end
                    end
                end
            end

            if ADS_Config.DEBUG and spec.debugData[systemName] ~= nil then
                local criticalChance = math.clamp((1 - systemCondition) ^ probabilityData.CRITICAL_DEGREE, probabilityData.CRITICAL_MIN, probabilityData.CRITICAL_MAX)
                spec.debugData[systemName].breakdownProbability = hourlyProb
                spec.debugData[systemName].critBreakdownProbability = criticalChance
            end
        end
    end
end

function AdvancedDamageSystem:getRandomBreakdown()
    if not self.spec_AdvancedDamageSystem then
        return nil
    end

    local activeBreakdowns = self:getActiveBreakdowns()
    local applicableBreakdowns = {}
    local totalProbability = 0

    for id, breakdownData in pairs(ADS_Breakdowns.BreakdownRegistry) do
        if not activeBreakdowns[id] and breakdownData.isSelectable then
            local isApplicable = true
            if breakdownData.isApplicable ~= nil then
                isApplicable = breakdownData.isApplicable(self)
            end

            if isApplicable then
                local probability = 1.0 
                if breakdownData.probability ~= nil then
                    probability = breakdownData.probability(self)
                end

                if probability > 0 then
                    table.insert(applicableBreakdowns, {id = id, probability = probability})
                    totalProbability = totalProbability + probability
                end
            end
        end
    end

    if #applicableBreakdowns == 0 or totalProbability <= 0 then
        return nil
    end

    local randomNumber = math.random() * totalProbability

    local cumulativeProbability = 0
    for _, breakdown in ipairs(applicableBreakdowns) do
        cumulativeProbability = cumulativeProbability + breakdown.probability
        if randomNumber <= cumulativeProbability then
            return breakdown.id
        end
    end
    return nil
end

function AdvancedDamageSystem:getRandomBreakdownBySystem(systemName)
    if not self.spec_AdvancedDamageSystem then
        return nil
    end

    local spec = self.spec_AdvancedDamageSystem

    if systemName == nil then
        return nil
    end

    local targetSystem = systemName
    if type(targetSystem) == "string" and AdvancedDamageSystem.SYSTEMS[targetSystem] ~= nil then
        targetSystem = AdvancedDamageSystem.SYSTEMS[targetSystem]
    end

    local targetSystemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, targetSystem)
    if targetSystemKey == nil or targetSystemKey == "" then
        targetSystemKey = string.lower(tostring(targetSystem))
    end
    local targetSystemData = spec.systems[targetSystemKey]
    if type(targetSystemData) ~= "table" then
        return nil
    end

    local activeBreakdowns = self:getActiveBreakdowns()
    local applicableBreakdowns = {}
    local totalProbability = 0

    for id, breakdownData in pairs(ADS_Breakdowns.BreakdownRegistry) do
        local breakdownSystem = breakdownData.system
        if type(breakdownSystem) == "string" and AdvancedDamageSystem.SYSTEMS[breakdownSystem] ~= nil then
            breakdownSystem = AdvancedDamageSystem.SYSTEMS[breakdownSystem]
        end

        local breakdownSystemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, breakdownSystem)
        if breakdownSystemKey == nil or breakdownSystemKey == "" then
            breakdownSystemKey = string.lower(tostring(breakdownSystem or ""))
        end

        if not activeBreakdowns[id] and breakdownData.isSelectable and breakdownSystemKey == targetSystemKey then
            local isApplicable = true
            if breakdownData.isApplicable ~= nil then
                isApplicable = breakdownData.isApplicable(self)
            end

            if isApplicable then
                local probability = 1.0 
                if breakdownData.probability ~= nil then
                    probability = breakdownData.probability(self)
                end

                if probability > 0 then
                    table.insert(applicableBreakdowns, {id = id, probability = probability})
                    totalProbability = totalProbability + probability
                    log_dbg(string.format(
                        "Breakdown candidate [%s] system=%s weight=%.6f",
                        tostring(id),
                        tostring(targetSystemKey),
                        tonumber(probability) or 0
                    ))
                end
            end
        end
    end

    if #applicableBreakdowns == 0 or totalProbability <= 0 then
        log_dbg(string.format(
            "Breakdown selection skipped for system=%s candidates=%d totalWeight=%.6f",
            tostring(targetSystemKey),
            #applicableBreakdowns,
            tonumber(totalProbability) or 0
        ))
        return nil
    end

    local randomNumber = math.random() * totalProbability
    log_dbg(string.format(
        "Breakdown selection random system=%s random=%.6f totalWeight=%.6f",
        tostring(targetSystemKey),
        tonumber(randomNumber) or 0,
        tonumber(totalProbability) or 0
    ))

    local cumulativeProbability = 0
    for _, breakdown in ipairs(applicableBreakdowns) do
        cumulativeProbability = cumulativeProbability + breakdown.probability
        log_dbg(string.format(
            "Breakdown roll [%s] cumulative=%.6f threshold=%.6f",
            tostring(breakdown.id),
            tonumber(cumulativeProbability) or 0,
            tonumber(randomNumber) or 0
        ))
        if randomNumber <= cumulativeProbability then
            log_dbg(string.format(
                "Breakdown selected [%s] system=%s random=%.6f cumulative=%.6f",
                tostring(breakdown.id),
                tostring(targetSystemKey),
                tonumber(randomNumber) or 0,
                tonumber(cumulativeProbability) or 0
            ))
            return breakdown.id
        end
    end

    log_dbg(string.format(
        "Breakdown selection fell through system=%s random=%.6f totalWeight=%.6f",
        tostring(targetSystemKey),
        tonumber(randomNumber) or 0,
        tonumber(totalProbability) or 0
    ))
    return nil
end

function AdvancedDamageSystem:addBreakdown(breakdownId, stageOrOptions)
    local spec = self.spec_AdvancedDamageSystem
    if not spec then return end

    local options
    if type(stageOrOptions) == "table" then
        options = stageOrOptions
    else
        options = {
            stage = stageOrOptions,
            isActive = true,
        }
    end

    local activeBreakdowns = self:getActiveBreakdowns()
    local breakdownRegistry = ADS_Breakdowns ~= nil and ADS_Breakdowns.BreakdownRegistry or nil
    if breakdownRegistry == nil then
        log_dbg("addBreakdown skipped: BreakdownRegistry is nil for id:", tostring(breakdownId))
        return
    end
    
    local activeBreakdownsCount = 0
    for _, breakdownData in pairs(activeBreakdowns) do
        if type(breakdownData) == "table" and breakdownData.isActive ~= false then
            activeBreakdownsCount = activeBreakdownsCount + 1
        end
    end

    local registryEntry = breakdownRegistry[breakdownId]
    if registryEntry == nil then
        log_dbg("addBreakdown skipped: unknown breakdown id:", tostring(breakdownId))
        return
    end

    if activeBreakdownsCount >= ADS_Config.CORE.CONCURRENT_BREAKDOWN_LIMIT_PER_VEHICLE and registryEntry.isSelectable then
        return nil 
    end

    if self:hasBreakdown(breakdownId) then
        return
    end

    local currentIsActive = false
    if options.isActive == nil then
        currentIsActive = true
    else
        currentIsActive = options.isActive
    end

    local resumeTimer = math.max(tonumber(options.resumeTimer) or 0, 0)
    if not currentIsActive and resumeTimer <= 0 then
        local serviceScale = ADS_Config.CORE.DEFAULT_SERVICE_WEAR / ADS_Config.CORE.BASE_SERVICE_WEAR
        resumeTimer = ADS_Config.CORE.REPEAT_BREAKDOWN_TIME * serviceScale * (math.random() + 0.5)
    end

    spec.activeBreakdowns[breakdownId] = {
        stage = math.max(math.floor(tonumber(options.stage) or 1), 1),
        progressTimer = math.max(tonumber(options.progressTimer) or 0, 0),
        isVisible = ADS_Utils.normalizeBoolValue(options.isVisible, false),
        isSelectedForRepair = ADS_Utils.normalizeBoolValue(options.isSelectedForRepair, true),
        isActive = currentIsActive,
        resumeTimer = resumeTimer,
        source = options.source or AdvancedDamageSystem.BREAKDOWN_SOURCES.RANDOM
    }
    
    self:recalculateAndApplyEffects()

    if self.isServer and spec.adsDirtyFlag_breakdowns ~= nil then
        self:raiseDirtyFlags(spec.adsDirtyFlag_breakdowns)
    end
end

function AdvancedDamageSystem:suspendBreakdown(breakdownId, resumeTimer)
    local spec = self.spec_AdvancedDamageSystem
    if not spec or not spec.activeBreakdowns then
        return
    end

    local breakdown = spec.activeBreakdowns[breakdownId]
    if breakdown == nil then
        return
    end

    breakdown.isActive = false
    breakdown.resumeTimer = math.max(tonumber(resumeTimer) or 0, 0)
    breakdown.source = AdvancedDamageSystem.BREAKDOWN_SOURCES.QUICK_FIX

    self:recalculateAndApplyEffects()

    if self.isServer and spec.adsDirtyFlag_breakdowns ~= nil then
        self:raiseDirtyFlags(spec.adsDirtyFlag_breakdowns)
    end
end

function AdvancedDamageSystem:removeBreakdown(...)
    local spec = self.spec_AdvancedDamageSystem
    if not spec or not spec.activeBreakdowns or next(spec.activeBreakdowns) == nil then
        return
    end
    
    local idsToRemove = {...}

    if #idsToRemove == 0 then
        spec.activeBreakdowns = {}
        self:recalculateAndApplyEffects()
        if self.isServer and spec.adsDirtyFlag_breakdowns ~= nil then
            self:raiseDirtyFlags(spec.adsDirtyFlag_breakdowns)
        end
        return
    end

    local removedCount = 0
    for _, id in ipairs(idsToRemove) do
        if spec.activeBreakdowns[id] then
            spec.activeBreakdowns[id] = nil
            removedCount = removedCount + 1
        end
    end
    
    if removedCount > 0 then
        self:recalculateAndApplyEffects()
        if self.isServer and spec.adsDirtyFlag_breakdowns ~= nil then
            self:raiseDirtyFlags(spec.adsDirtyFlag_breakdowns)
        end
    else
    end
end

function AdvancedDamageSystem:hasBreakdown(breakdownId)
    local spec = self.spec_AdvancedDamageSystem
    if not spec or not spec.activeBreakdowns or next(spec.activeBreakdowns) == nil then
        return false
    end

    return spec.activeBreakdowns[breakdownId] ~= nil
end

function AdvancedDamageSystem:hasSystemBreakdowns(system)
    local spec = self.spec_AdvancedDamageSystem
    if not spec or not spec.activeBreakdowns or next(spec.activeBreakdowns) == nil then
        return false
    end

    local systemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, system)
    if systemKey == nil or systemKey == "" then
        systemKey = type(system) == "string" and string.lower(system) or ""
    end

    if systemKey == "" then
        return false
    end

    for breakdownId, _ in pairs(spec.activeBreakdowns) do
        local registryBreakdown = ADS_Breakdowns.BreakdownRegistry[breakdownId]
        if registryBreakdown ~= nil then
            local breakdownSystemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, registryBreakdown.system)
            if breakdownSystemKey == systemKey then
                return true
            end
        end
    end

    return false
end

function AdvancedDamageSystem:changeBreakdownStage(breakdownId, targetStageOrReverse)
    local spec = self.spec_AdvancedDamageSystem
    if not spec or not spec.activeBreakdowns or next(spec.activeBreakdowns) == nil or spec.activeBreakdowns[breakdownId] == nil then
        return
    end
    
    local registryBreakdown = ADS_Breakdowns.BreakdownRegistry[breakdownId]
    local breakdown = spec.activeBreakdowns[breakdownId]
    if registryBreakdown == nil or registryBreakdown.stages == nil or #registryBreakdown.stages == 0 then
        return
    end

    local currentStage = math.max(math.floor(tonumber(breakdown.stage) or 1), 1)
    local targetStage = currentStage + 1

    if type(targetStageOrReverse) == "boolean" then
        if targetStageOrReverse then
            targetStage = currentStage - 1
        end
    elseif type(targetStageOrReverse) == "number" then
        targetStage = math.floor(targetStageOrReverse)
    end

    targetStage = math.min(math.max(targetStage, 1), #registryBreakdown.stages)

    if targetStage ~= currentStage then
        breakdown.stage = targetStage
        self:recalculateAndApplyEffects()

        -- Sync breakdown stage change
        if self.isServer and spec.adsDirtyFlag_breakdowns ~= nil then
            self:raiseDirtyFlags(spec.adsDirtyFlag_breakdowns)
        end
    end
end

function AdvancedDamageSystem:processBreakdowns(dt)
    local spec = self.spec_AdvancedDamageSystem
    if not spec or not spec.activeBreakdowns or next(spec.activeBreakdowns) == nil then
        return
    end

    local C = ADS_Config.CORE
    local effectsNeedRecalculation = false

    for id, breakdown in pairs(self:getActiveBreakdowns()) do
        local registryEntry = ADS_Breakdowns.BreakdownRegistry[id]

        if registryEntry then
            breakdown.isActive = breakdown.isActive ~= false
            breakdown.resumeTimer = math.max(tonumber(breakdown.resumeTimer) or 0, 0)

            if not breakdown.isActive then
                if breakdown.resumeTimer > 0 then
                    breakdown.resumeTimer = math.max(breakdown.resumeTimer - dt, 0)
                end

                if breakdown.resumeTimer <= 0 then
                    breakdown.resumeTimer = 0
                    breakdown.isActive = true
                    effectsNeedRecalculation = true
                end
            elseif registryEntry.stages[breakdown.stage] then
                local stageData = registryEntry.stages[breakdown.stage]
                
                if stageData.progressMultiplier and stageData.progressMultiplier > 0 then
                    
                    local canProgress = true
                    if registryEntry.isCanProgress ~= nil then
                        canProgress = registryEntry.isCanProgress(self)
                    end

                    if canProgress then
                        breakdown.progressTimer = breakdown.progressTimer or 0
                        breakdown.progressTimer = breakdown.progressTimer + dt
                        
                        local serviceScale = C.DEFAULT_SERVICE_WEAR / C.BASE_SERVICE_WEAR
                        local stageDuration = C.BASE_BREAKDOWN_PROGRESS_TIME * stageData.progressMultiplier * serviceScale

                        if breakdown.progressTimer >= stageDuration then
                            local maxStages = #registryEntry.stages
                            
                            if breakdown.stage < maxStages then
                                breakdown.stage = breakdown.stage + 1
                                breakdown.progressTimer = 0
                                effectsNeedRecalculation = true

                                if breakdown.stage == maxStages and registryEntry.stages[breakdown.stage].detectionChance > 0 then
                                    breakdown.isVisible = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if effectsNeedRecalculation then
        self:recalculateAndApplyEffects()

        -- Sync breakdown stage progression
        if self.isServer and spec.adsDirtyFlag_breakdowns ~= nil then
            self:raiseDirtyFlags(spec.adsDirtyFlag_breakdowns)
        end
    end
end

local function buildGeneralWearBreakdown(vehicle)
    local spec = vehicle.spec_AdvancedDamageSystem
    if not spec then
        return
    end

    local generalWearBreakdown = {
        system = 'vehicle',
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
                description = "ads_breakdowns_general_wear_stage1_description",
                detectionChance = 0.0,
                progressMultiplier = 0.0,
                repairPrice = 0.0,
                effects = {},
                indicators = {}
            }
        }
    }

    local effects = generalWearBreakdown.stages[1].effects
    local systems = AdvancedDamageSystem.SYSTEMS

    for _, systemData in pairs(spec.systems) do
        local systemName = systemData.name
        local systemCondition = vehicle:getSystemConditionLevel(systemName)
        local effect = nil
        local isLateStage = systemCondition <= ADS_Config.CORE.GENERAL_WEAR_LATE_STAGE_THRESHOLD
        
        if systemData.enabled and systemCondition <= ADS_Config.CORE.GENERAL_WEAR_EARLY_STAGE_THRESHOLD  then
            
            --- ENGINE
            if systemName == systems.ENGINE then

                --- early stage
                effect = {
                    id = "ENGINE_TORQUE_MODIFIER",
                    value = function() 
                        local baseEffect = -0.30
                        local condition = systemCondition
                        local multiplier = (1 - condition) ^ 3
                        return baseEffect * multiplier
                    end,
                    aggregation = "sum"
                }
                if effect ~= nil then table.insert(effects, effect) end

            --- TRANSMISSION
            elseif systemName == systems.TRANSMISSION then
                local motor = vehicle:getMotor()
                if not motor then return false end
                
                local isManual = motor.minForwardGearRatio == nil
                local isPowerShift = motor.gearType == VehicleMotor.TRANSMISSION_TYPE.POWERSHIFT
                local isCvt = motor.minForwardGearRatio ~= nil

                --- early stage
                if isManual and hasCVTAddon(vehicle) then
                    effect = {
                        id = "TRANSMISSION_SLIP_EFFECT", 
                        value = function ()
                            local baseEffect = 0.30
                            local condition = systemCondition
                            local multiplier = (1 - condition) ^ 3
                            return baseEffect * multiplier
                        end, 
                        extraData = {accumulatedMod = 0.0}, 
                        aggregation = "max"
                    }
                    if effect ~= nil then table.insert(effects, effect) end

                elseif isPowerShift and hasCVTAddon(vehicle) then
                    effect = { 
                        id = "POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT", 
                        value = function ()
                            local baseEffect = 0.30
                            local condition = systemCondition
                            local multiplier = (1 - condition) ^ 3
                            return baseEffect * multiplier
                        end,
                        extraData = {timer = 0, status = "IDLE", duration = 1000, backup = 0}, 
                        aggregation = "max"
                    }
                    if effect ~= nil then table.insert(effects, effect) end

                elseif isCvt and not hasCVTAddon(vehicle) then
                    effect = { 
                        id = "CVT_MAX_RATIO_MODIFIER", 
                        value = function ()
                            local baseEffect = 0.30
                            local condition = systemCondition
                            local multiplier = (1 - condition) ^ 3
                            return baseEffect * multiplier
                        end,
                        aggregation = "max" 
                    }
                    if effect ~= nil then table.insert(effects, effect) end
                end

            --- HYDRAULIC
            elseif systemName == systems.HYDRAULICS then
                effect = {
                    id = "HYDRAULIC_SPEED_MODIFIER", 
                    value = function ()
                        local baseEffect = -0.30
                        local condition = systemCondition
                        local multiplier = (1 - condition) ^ 3
                        return baseEffect * multiplier
                    end,
                    aggregation = "min"
                }
                if effect ~= nil then table.insert(effects, effect) end
            
            --- FUEL
            elseif systemName == systems.FUEL then

                --- ealry stage
                effect = {
                    id = "FUEL_CONSUMPTION_MODIFIER", 
                    value = function ()
                        local baseEffect = 0.60
                        local condition = systemCondition
                        local multiplier = (1 - condition) ^ 3
                        return baseEffect * multiplier
                    end, 
                    aggregation = "sum" 
                }
                if effect ~= nil then table.insert(effects, effect) end

            --- CHASSIS
            elseif systemName == systems.CHASSIS then
                
                --- early stage
                effect = {
                    id = "BRAKE_FORCE_MODIFIER", 
                    value = function ()
                        local baseEffect = -0.60
                        local condition = systemCondition
                        local multiplier = (1 - condition) ^ 3
                        return baseEffect * multiplier
                    end,  
                    aggregation = "min",  
                    extraData = {timer = 0, soundPlayed = false}
                }
                if effect ~= nil then table.insert(effects, effect) end

                --- late stage
                effect = {
                    id = "STEERING_SENSITIVITY_MODIFIER", 
                    value = function ()
                        local baseEffect = 0.30
                        local condition = systemCondition
                        local multiplier = (1 - condition) ^ 3
                        return baseEffect * multiplier
                    end,   
                    aggregation = "max" 
                }
                if isLateStage and effect ~= nil then table.insert(effects, effect) end

            --- COOLING
            elseif systemName == systems.COOLING then
                
                --- early stage
                effect = {
                    id = "RADIATOR_HEALTH_MODIFIER", 
                    value = function ()
                        local baseEffect = -0.20
                        local condition = systemCondition
                        local multiplier = (1 - condition) ^ 3
                        return baseEffect * multiplier
                    end,  
                    aggregation = "min",  
                }
                if effect ~= nil then table.insert(effects, effect) end

            --- ELECTRICAL
            elseif systemName == systems.ELECTRICAL then

                --- early stage
                effect = {
                    id = "ALTERNATOR_HEALTH_MODIFIER", 
                    value = function ()
                        local baseEffect = -0.60
                        local condition = systemCondition
                        local multiplier = (1 - condition) ^ 3
                        return baseEffect * multiplier
                    end,   
                    aggregation = "min"
                }
                if effect ~= nil then table.insert(effects, effect) end

                effect = {
                    id = "BATTERY_HEALTH_MODIFIER", 
                    value = function ()
                        local baseEffect = -0.60
                        local condition = systemCondition
                        local multiplier = (1 - condition) ^ 3
                        return baseEffect * multiplier
                    end,  
                    aggregation = "min"
                }
                if effect ~= nil then table.insert(effects, effect) end

                --- late stage
                effect = {
                        id = "ENGINE_HARD_START_MODIFIER",
                        value = function ()
                        local baseEffect = 6
                            local condition = systemCondition
                            local multiplier = (1 - condition) ^ 3
                            return math.max(baseEffect * multiplier, 2)
                        end,  
                        aggregation = "max",
                        extraData = {timer = 0, status = 'IDLE'}
                }
                if isLateStage and effect ~= nil and effect.value() >= 2 then table.insert(effects, effect) end

            --- WORKPORCESS
            elseif systemName == systems.WORKPROCESS then

                --- early stage
                effect = {
                    id = "YIELD_REDUCTION_MODIFIER", 
                    value = function ()
                        local baseEffect = -0.20
                        local condition = systemCondition
                        local multiplier = (1 - condition) ^ 3
                        return baseEffect * multiplier
                    end,
                    aggregation = "sum"
                }
                if effect ~= nil then table.insert(effects, effect) end
            end 
        end
    end

    return generalWearBreakdown
end

local function getBreakdownDefinition(vehicle, breakdownId)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec ~= nil and spec.dynamicBreakdowns ~= nil and spec.dynamicBreakdowns[breakdownId] ~= nil then
        return spec.dynamicBreakdowns[breakdownId]
    end
    return ADS_Breakdowns.BreakdownRegistry[breakdownId]
end

function AdvancedDamageSystem:processGeneralWearBreakdown()
    local spec = self.spec_AdvancedDamageSystem
    if not spec or not self.isServer then
        return
    end

    local generalWearId = "GENERAL_WEAR"

    if not ADS_Config.CORE.GENERAL_WEAR_ENABLED then
        if self:hasBreakdown(generalWearId) then
            self:removeBreakdown(generalWearId)
        end
        return
    end

    local isGeneralWearShouldBe = false
    local needToRecalculate = math.abs(self:getConditionLevel() - spec._prevConditionLevel) > ADS_Config.CORE.BASE_SYSTEMS_WEAR / 5
    
    for _, systemData in pairs(spec.systems) do
        if systemData.enabled and systemData.condition <= ADS_Config.CORE.GENERAL_WEAR_EARLY_STAGE_THRESHOLD  then
            isGeneralWearShouldBe = true
        end
    end
    if isGeneralWearShouldBe and not self:hasBreakdown(generalWearId) then
        self:addBreakdown(generalWearId)
        spec._prevConditionLevel = self:getConditionLevel()
        return
    elseif not isGeneralWearShouldBe and self:hasBreakdown(generalWearId) then
        self:removeBreakdown(generalWearId)
        spec._prevConditionLevel = self:getConditionLevel()
        return
    end

    if needToRecalculate and isGeneralWearShouldBe then
        if self.isServer and spec.adsDirtyFlag_breakdowns ~= nil then
            self:raiseDirtyFlags(spec.adsDirtyFlag_breakdowns)
        end
        self:recalculateAndApplyEffects()
        spec._prevConditionLevel = self:getConditionLevel()
    end
end

function AdvancedDamageSystem:recalculateAndApplyEffects()
    local spec = self.spec_AdvancedDamageSystem
    if not spec then return end

    if self:hasBreakdown("GENERAL_WEAR") then
        spec.dynamicBreakdowns.GENERAL_WEAR = buildGeneralWearBreakdown(self)
    else
        spec.dynamicBreakdowns.GENERAL_WEAR = nil
    end

    local previouslyActiveEffects = spec.activeEffects or {}
    local aggregatedEffects = {}

    local unknownBreakdownIds = {}

    for id, breakdown in pairs(self:getActiveBreakdowns()) do
        local registryEntry = getBreakdownDefinition(self, id)

        if registryEntry == nil then
            table.insert(unknownBreakdownIds, id)
        elseif breakdown.isActive ~= false and registryEntry.stages[breakdown.stage] then
            local stageData = registryEntry.stages[breakdown.stage]

            if stageData.effects then
                for _, effectData in ipairs(stageData.effects) do
                    local effectId = effectData.id
                    local strategy = effectData.aggregation or "sum" 

                    local newValue
                    if type(effectData.value) == 'function' then
                        newValue = effectData.value(self)
                    else
                        newValue = effectData.value
                    end
                    
                    local existingEffect = aggregatedEffects[effectId]

                    if existingEffect == nil then
                        local newEffect = ADS_Utils.deepCopy(effectData)
                        newEffect.value = newValue 
                        aggregatedEffects[effectId] = newEffect
                    else
                        if strategy == "sum" then
                            if math.abs(newValue) > math.abs(existingEffect.value) then
                                existingEffect.extraData = ADS_Utils.deepCopy(effectData.extraData)
                            end
                            existingEffect.value = existingEffect.value + newValue

                        elseif strategy == "multiply" then
                            if math.abs(newValue - 1) > math.abs(existingEffect.value - 1) then
                                existingEffect.extraData = ADS_Utils.deepCopy(effectData.extraData)
                            end
                            existingEffect.value = existingEffect.value * newValue
                        
                        elseif strategy == "min" then
                            if newValue < existingEffect.value then
                                existingEffect.value = newValue
                                existingEffect.extraData = ADS_Utils.deepCopy(effectData.extraData)
                            end

                        elseif strategy == "max" then
                            if newValue > existingEffect.value then
                                existingEffect.value = newValue
                                existingEffect.extraData = ADS_Utils.deepCopy(effectData.extraData)
                            end
                        
                        elseif strategy == "boolean_or" then
                            local wasActive = existingEffect.value ~= nil and existingEffect.value ~= false and existingEffect.value ~= 0
                            local isActive = newValue ~= nil and newValue ~= false and newValue ~= 0
                            existingEffect.value = existingEffect.value or newValue

                            if isActive then
                                if effectId == "ENGINE_FAILURE" then
                                    local newExtraData = ADS_Utils.deepCopy(effectData.extraData)

                                    if existingEffect.extraData == nil then
                                        existingEffect.extraData = newExtraData
                                    elseif newExtraData ~= nil then
                                        local existingStarter = existingEffect.extraData.starter == true
                                        local newStarter = newExtraData.starter == true

                                        if existingStarter and not newStarter then
                                            -- Non-starter failures should win over starter-driven causes.
                                            existingEffect.extraData = newExtraData
                                        else
                                            existingEffect.extraData.starter = existingStarter or newStarter

                                            if existingEffect.extraData.message == nil and newExtraData.message ~= nil then
                                                existingEffect.extraData.message = newExtraData.message
                                            end
                                            if existingEffect.extraData.reason == nil and newExtraData.reason ~= nil then
                                                existingEffect.extraData.reason = newExtraData.reason
                                            end
                                            if newExtraData.disableAi == true then
                                                existingEffect.extraData.disableAi = true
                                            end
                                        end
                                    end
                                elseif isActive and not wasActive then
                                    existingEffect.extraData = ADS_Utils.deepCopy(effectData.extraData)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Remove unknown breakdowns safely after iteration completes
    if #unknownBreakdownIds > 0 then
        for _, unknownId in ipairs(unknownBreakdownIds) do
            spec.activeBreakdowns[unknownId] = nil
        end
        if self.isServer and spec.adsDirtyFlag_breakdowns ~= nil then
            self:raiseDirtyFlags(spec.adsDirtyFlag_breakdowns)
        end
    end

    spec.activeEffects = aggregatedEffects

    for effectId, applicator in pairs(ADS_Breakdowns.EffectApplicators) do
        local isCurrentlyActive = spec.activeEffects[effectId] ~= nil
        local wasPreviouslyActive = previouslyActiveEffects[effectId] ~= nil

        if isCurrentlyActive then
            if applicator.apply then
                applicator.apply(self, spec.activeEffects[effectId], applicator)
                local currentEffect = spec.activeEffects[effectId]
                if currentEffect and currentEffect.extraData ~= nil and currentEffect.extraData.message ~= nil
                        and self.isClient and not self:getIsActiveForInput(true)
                        and self:getOwnerFarmId() == g_currentMission:getFarmId()
                        and g_currentMission.hud ~= nil and g_currentMission.hud.addSideNotification ~= nil then
                    g_currentMission.hud:addSideNotification(ADS_Breakdowns.COLORS.WARNING, self:getFullName() .. ": " .. g_i18n:getText(currentEffect.extraData.message))
                end
            end
        elseif wasPreviouslyActive then
            if applicator.remove then
                applicator.remove(self, applicator)
            end
        end
    end
    
    self:recalculateAndApplyIndicators()
end

function AdvancedDamageSystem:recalculateAndApplyIndicators()
    local spec = self.spec_AdvancedDamageSystem
    if not spec then return end

    spec.activeIndicators = {} 
    local aggregatedIndicatorData = {} 

    for id, breakdown in pairs(self:getActiveBreakdowns()) do
        local registryEntry = ADS_Breakdowns.BreakdownRegistry[id]
        if registryEntry and registryEntry.stages[breakdown.stage] then
            local stageData = registryEntry.stages[breakdown.stage]

            if stageData.indicators then
                for _, indicatorDef in ipairs(stageData.indicators) do
                    local id = indicatorDef.id
                    
                    if aggregatedIndicatorData[id] == nil then
                        aggregatedIndicatorData[id] = {
                            color = indicatorDef.color,
                            switchOnConditions = {},
                            switchOffConditions = {}
                        }
                    end

                    local currentData = aggregatedIndicatorData[id]

                    local newPriority = ADS_Breakdowns.COLOR_PRIORITY[indicatorDef.color] or 0
                    local existingPriority = ADS_Breakdowns.COLOR_PRIORITY[currentData.color] or 0
                    
                    if newPriority > existingPriority then
                        currentData.color = indicatorDef.color
                    end

                    if indicatorDef.switchOn then
                        table.insert(currentData.switchOnConditions, indicatorDef.switchOn)
                    end
                    if indicatorDef.switchOff then
                        table.insert(currentData.switchOffConditions, indicatorDef.switchOff)
                    end
                end
            end
        end
    end

    for id, data in pairs(aggregatedIndicatorData) do
        local finalIndicator = {
            color = data.color,
            isActive = false,
        }

        finalIndicator.switchOn = function(vehicle)
            for _, condition in ipairs(data.switchOnConditions) do
                local result = false
                if type(condition) == 'function' then
                    result = condition(vehicle)
                elseif type(condition) == 'boolean' then
                    result = condition
                end
                
                if result then
                    return true
                end
            end
            return false
        end

        finalIndicator.switchOff = function(vehicle)
            for _, condition in ipairs(data.switchOffConditions) do
                local result = false
                if type(condition) == 'function' then
                    result = condition(vehicle)
                elseif type(condition) == 'boolean' then
                    result = condition
                end
                
                if result then
                    return true
                end
            end
            return false
        end

        spec.activeIndicators[id] = finalIndicator
    end
end

--------------------- maintenance --------------------------------

local function isBreakdownSelectedForPlayerRepair(breakdownId, breakdown, optionOne)
    local breakdownDef = ADS_Breakdowns.BreakdownRegistry[breakdownId]
    if breakdownDef == nil or breakdownDef.isSelectable ~= true then
        return false
    end

    local isSelectedForQuickFix = breakdown.isSelectedForRepair and breakdown.isVisible and (optionOne == AdvancedDamageSystem.REPAIR_TYPES.LOW and breakdown.isActive)
    local isSelectedForStandartRepair = breakdown.isSelectedForRepair and breakdown.isVisible and (optionOne == AdvancedDamageSystem.REPAIR_TYPES.MEDIUM or optionOne == AdvancedDamageSystem.REPAIR_TYPES.HIGH)
    return isSelectedForStandartRepair or isSelectedForQuickFix
end

local function getIsSelectableBreakdown(breakdownId)
    local breakdownDef = ADS_Breakdowns.BreakdownRegistry[breakdownId]
    if breakdownDef == nil or breakdownDef.isSelectable ~= true then
        return false
    end
    return true
end

local function resetPendingServiceProgress(spec)
    spec.pendingSelectedBreakdowns = {}
    spec.pendingServicePrice = nil
    spec.pendingInspectionQueue = {}
    spec.pendingRepairQueue = {}
    spec.pendingProgressStepIndex = 0
    spec.pendingProgressTotalTime = 0
    spec.pendingProgressElapsedTime = 0
    spec.pendingMaintenanceServiceStart = nil
    spec.pendingMaintenanceServiceTarget = nil
    spec.pendingPreventiveSystemStressStart = {}
    spec.pendingPreventiveSystemStressTarget = {}
    spec.pendingOverhaulSystemStart = {}
    spec.pendingOverhaulSystemTarget = {}
    spec.pendingOverhaulSystemStressStart = {}
    spec.pendingOverhaulSystemStressTarget = {}
    spec.pendingRepairSystemStressStart = {}
    spec.pendingRepairSystemStressTarget = {}
    spec.pendingRepairSystemStressStartRatio = {}
end

local function applyPendingSystemStressInterpolation(spec, startMap, targetMap, ratio)
    if spec == nil or spec.systems == nil then
        return
    end

    if startMap == nil or targetMap == nil then
        return
    end

    for systemKey, startStress in pairs(startMap) do
        local systemData = spec.systems[systemKey]
        local targetStress = targetMap[systemKey]
        if systemData ~= nil and targetStress ~= nil then
            local interpolatedStress = startStress + (targetStress - startStress) * ratio
            systemData.stress = math.max(interpolatedStress, 0)
        end
    end
end

local function applyPendingPreventiveStressInterpolation(spec, ratio)
    applyPendingSystemStressInterpolation(spec, spec.pendingPreventiveSystemStressStart, spec.pendingPreventiveSystemStressTarget, ratio)
end

local function applyPendingOverhaulStressInterpolation(spec, ratio)
    applyPendingSystemStressInterpolation(spec, spec.pendingOverhaulSystemStressStart, spec.pendingOverhaulSystemStressTarget, ratio)
end

local function markRepairStressReduction(spec, systemKey, optionOne)
    if spec == nil or spec.systems == nil or systemKey == nil or systemKey == "" then
        return
    end

    local systemData = spec.systems[systemKey]
    if systemData == nil then
        return
    end

    local optionOneKey = ADS_Utils.getNameByValue(AdvancedDamageSystem.REPAIR_TYPES, optionOne)

    spec.pendingRepairSystemStressStart = spec.pendingRepairSystemStressStart or {}
    spec.pendingRepairSystemStressTarget = spec.pendingRepairSystemStressTarget or {}
    spec.pendingRepairSystemStressStartRatio = spec.pendingRepairSystemStressStartRatio or {}

    if spec.pendingRepairSystemStressTarget[systemKey] == nil then
        spec.pendingRepairSystemStressStart[systemKey] = math.max(tonumber(systemData.stress) or 0, 0)
        spec.pendingRepairSystemStressTarget[systemKey] = math.max(ADS_Config.MAINTENANCE.REPAIR_REMAINING_STRESS_RATIO[optionOneKey] * systemData.stress * (0.9 + math.random() * 0.2), 0)
        local totalTime = math.max(tonumber(spec.pendingProgressTotalTime) or 0, 0.0001)
        spec.pendingRepairSystemStressStartRatio[systemKey] = math.min(math.max((tonumber(spec.pendingProgressElapsedTime) or 0) / totalTime, 0), 1)
    end
end

local function applyPendingRepairStressInterpolation(spec, ratio)
    if spec == nil or spec.systems == nil then
        return
    end

    if spec.pendingRepairSystemStressStart == nil
        or spec.pendingRepairSystemStressTarget == nil
        or spec.pendingRepairSystemStressStartRatio == nil then
        return
    end

    for systemKey, startStress in pairs(spec.pendingRepairSystemStressStart) do
        local systemData = spec.systems[systemKey]
        local targetStress = spec.pendingRepairSystemStressTarget[systemKey]
        local startRatio = tonumber(spec.pendingRepairSystemStressStartRatio[systemKey]) or 0
        if systemData ~= nil and targetStress ~= nil then
            local localRatio = 1
            if startRatio < 1 then
                localRatio = math.min(math.max((ratio - startRatio) / (1 - startRatio), 0), 1)
            end
            local interpolatedStress = startStress + (targetStress - startStress) * localRatio
            systemData.stress = math.max(interpolatedStress, 0)
        end
    end
end

local function collectPreventiveMaintenanceStressTargets(vehicle)
    local spec = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    if spec == nil or type(spec.systems) ~= "table" then
        return {}, {}
    end

    local config = ADS_Config.MAINTENANCE or {}
    local systemsCount = math.max(math.floor(tonumber(config.MAINTENANCE_PREVENTIVE_SYSTEMS_COUNT) or 0), 0)
    if systemsCount <= 0 then
        return {}, {}
    end

    local targetMultiplier = math.clamp(tonumber(config.MAINTENANCE_PREVENTIVE_STRESS_REMOVE_MULTIPLIER) or 0, 0, 1)
    local candidates = {}

    for systemKey, systemData in pairs(spec.systems) do
        if type(systemData) == "table" and systemData.enabled ~= false then
            local condition = math.clamp(tonumber(systemData.condition) or spec.conditionLevel or 1.0, 0.001, 1.0)
            local currentStress = math.max(tonumber(systemData.stress) or 0, 0)
            local targetStress = math.min(currentStress, condition * targetMultiplier)
            local removableStress = currentStress - targetStress
            if removableStress > 0.0001 then
                table.insert(candidates, {
                    systemKey = systemKey,
                    startStress = currentStress,
                    targetStress = targetStress,
                    mtbf = ADS_Utils.getEstimatedMTBF(condition, currentStress),
                    removableStress = removableStress
                })
            end
        end
    end

    table.sort(candidates, function(a, b)
        if a.mtbf ~= b.mtbf then
            return a.mtbf < b.mtbf
        end
        if a.removableStress ~= b.removableStress then
            return a.removableStress > b.removableStress
        end
        return tostring(a.systemKey) < tostring(b.systemKey)
    end)

    local startMap = {}
    local targetMap = {}
    local selectedCount = math.min(systemsCount, #candidates)
    for i = 1, selectedCount do
        local candidate = candidates[i]
        startMap[candidate.systemKey] = candidate.startStress
        targetMap[candidate.systemKey] = candidate.targetStress
    end

    return startMap, targetMap
end

function AdvancedDamageSystem:initService(type, workshopType, optionOne, optionTwo, optionThree)
    local spec = self.spec_AdvancedDamageSystem
    local states = AdvancedDamageSystem.STATUS
    local vehicleState = self:getCurrentStatus()
    local C = ADS_Config.MAINTENANCE
    local selectedBreakdowns = {}
    local totalTimeMs = 0
    local repairPrice = nil

    if self.spec_enterable ~= nil and self.spec_enterable.setIsTabbable ~= nil and C.PARK_VEHICLE then
        self.spec_enterable:setIsTabbable(false)
    end

    if vehicleState ~= states.READY or (spec.maintenanceTimer or 0) ~= 0 then
        return
    end

    if type == states.OVERHAUL
        and optionOne == AdvancedDamageSystem.OVERHAUL_TYPES.PARTIAL
        and ADS_Utils.getEffectiveSystemWeight(self, optionTwo, AdvancedDamageSystem.SYSTEMS) <= 0 then
        log_dbg(string.format("Skipping partial overhaul for %s: invalid or disabled target system '%s'", self:getFullName(), tostring(optionTwo)))
        return
    end

    if self:getIsOperating() then
        self:stopMotor()
    end

    spec.currentState = type
    spec.plannedState = states.READY
    spec.workshopType = workshopType
    spec.serviceOptionOne = optionOne
    spec.serviceOptionTwo = optionTwo
    spec.serviceOptionThree = optionThree
    resetPendingServiceProgress(spec)

    -- INSPECTION
    if type == states.INSPECTION or type == states.MAINTENANCE then
        if type == states.INSPECTION then
            if C.INSTANT_INSPECTION and optionOne == AdvancedDamageSystem.INSPECTION_TYPES.VISUAL then
                optionOne = AdvancedDamageSystem.INSPECTION_TYPES.STANDARD
                spec.serviceOptionOne = optionOne
            end

            local key = ADS_Utils.getNameByValue(AdvancedDamageSystem.INSPECTION_TYPES, optionOne)
            if C.INSTANT_INSPECTION then
                totalTimeMs = 1000
            else
                totalTimeMs = C.INSPECTION_TIME * C.GLOBAL_SERVICE_TIME_MULTIPLIER * C.INSPECTION_TIME_MULTIPLIERS[key]
            end
        end

        for id, breakdown in pairs(self:getActiveBreakdowns()) do
            if breakdown ~= nil and not breakdown.isVisible then
                table.insert(spec.pendingInspectionQueue, id)
            end
        end
    end

    -- MAINTENANCE
    if type == states.MAINTENANCE then
        local key = ADS_Utils.getNameByValue(AdvancedDamageSystem.MAINTENANCE_TYPES, optionOne)
        totalTimeMs = C.MAINTENANCE_TIME * C.GLOBAL_SERVICE_TIME_MULTIPLIER * C.MAINTENANCE_TIME_MULTIPLIERS[key]
        spec.pendingMaintenanceServiceStart = spec.serviceLevel
        spec.pendingMaintenanceServiceTarget = math.max(spec.pendingMaintenanceServiceStart, C.MAINTENANCE_SERVICE_RESTORE_MULTIPLIERS[key])
        spec.pendingPreventiveSystemStressStart = {}
        spec.pendingPreventiveSystemStressTarget = {}

        if key == "PREVENTIVE" then
            spec.pendingPreventiveSystemStressStart, spec.pendingPreventiveSystemStressTarget = collectPreventiveMaintenanceStressTargets(self)
        end

        if self:hasBreakdown("MAINTENANCE_WITH_POOR_QUALITY_CONSUMABLES") then
            self:removeBreakdown("MAINTENANCE_WITH_POOR_QUALITY_CONSUMABLES")
        end

    -- REPAIR
    elseif type == states.REPAIR then
        local key = ADS_Utils.getNameByValue(AdvancedDamageSystem.REPAIR_TYPES, optionOne)
        local idsToRepair = {}
        for id, breakdown in pairs(self:getActiveBreakdowns()) do
            if isBreakdownSelectedForPlayerRepair(id, breakdown, optionOne) then
                table.insert(idsToRepair, id)
            end
        end

        selectedBreakdowns = idsToRepair
        spec.pendingRepairQueue = ADS_Utils.shallowCopy(idsToRepair)
        totalTimeMs = C.REPAIR_TIME * C.GLOBAL_SERVICE_TIME_MULTIPLIER * C.REPAIR_TIME_MULTIPLIERS[key] * #idsToRepair
        repairPrice = self:getServicePrice(type, optionOne, optionTwo, optionThree)

    -- OVERHAUL
    elseif type == states.OVERHAUL then
        local key = ADS_Utils.getNameByValue(AdvancedDamageSystem.OVERHAUL_TYPES, optionOne)
        totalTimeMs = C.OVERHAUL_TIME * C.GLOBAL_SERVICE_TIME_MULTIPLIER * C.OVERHAUL_TIME_MULTIPLIERS[key]
        local targetOverhaulSystemKey = nil
        if optionOne == AdvancedDamageSystem.OVERHAUL_TYPES.PARTIAL then 
            local systemWeight = ADS_Utils.getEffectiveSystemWeight(self, optionTwo, AdvancedDamageSystem.SYSTEMS)
            totalTimeMs = totalTimeMs * systemWeight
            targetOverhaulSystemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, optionTwo)
            if (targetOverhaulSystemKey == nil or targetOverhaulSystemKey == "") and type(optionTwo) == "string" then
                targetOverhaulSystemKey = string.lower(optionTwo)
            end
        end

        if next(spec.activeBreakdowns) ~= nil then
            local idsToRepair = {}
            for id, _ in pairs(spec.activeBreakdowns) do
                if ADS_Breakdowns.BreakdownRegistry[id] and ADS_Breakdowns.BreakdownRegistry[id].isSelectable then
                    local breakdownSystemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, ADS_Breakdowns.BreakdownRegistry[id].system)
                    if optionOne ~= AdvancedDamageSystem.OVERHAUL_TYPES.PARTIAL or targetOverhaulSystemKey == breakdownSystemKey then
                        table.insert(idsToRepair, id)
                    end
                end
            end
            selectedBreakdowns = idsToRepair
        end

        local overhaulPerformedCount = self:getOverhaulPerformedCount()
        local minRestore = C.OVERHAUL_MIN_CONDITION_RESTORE_MULTIPLIERS[key] - C.OVERHAUL_MIN_CONDITION_RESTORE_MULTIPLIERS[key] * C.RE_OVERHAUL_FACTOR * overhaulPerformedCount
        local maxRestore = C.OVERHAUL_MAX_CONDITION_RESTORE_MULTIPLIERS[key] - C.OVERHAUL_MAX_CONDITION_RESTORE_MULTIPLIERS[key] * C.RE_OVERHAUL_FACTOR * overhaulPerformedCount
        spec.pendingOverhaulSystemStart = {}
        spec.pendingOverhaulSystemTarget = {}
        spec.pendingOverhaulSystemStressStart = {}
        spec.pendingOverhaulSystemStressTarget = {}

        for systemKey, systemData in pairs(spec.systems) do
            if optionOne ~= AdvancedDamageSystem.OVERHAUL_TYPES.PARTIAL or systemKey == targetOverhaulSystemKey or optionTwo == systemData.name then
                local startCondition = math.clamp(tonumber(systemData.condition) or spec.conditionLevel or 1.0, 0.001, 1.0)
                local startStress = math.max(tonumber(systemData.stress) or 0, 0)
                local restoreAmount = math.min((minRestore + math.random() * (maxRestore - minRestore)) * spec.maintainability, spec.baseConditionLevel)
                local desiredSystemTarget = math.max(restoreAmount, C.OVERHAUL_MIN_CONDITION_RESTORE_MULTIPLIERS[key])
                local targetCondition = math.max(startCondition, desiredSystemTarget)
                spec.pendingOverhaulSystemStart[systemKey] = startCondition
                spec.pendingOverhaulSystemTarget[systemKey] = targetCondition
                spec.pendingOverhaulSystemStressStart[systemKey] = startStress
                spec.pendingOverhaulSystemStressTarget[systemKey] = 0
            end
        end

        if optionOne == AdvancedDamageSystem.OVERHAUL_TYPES.PARTIAL and next(spec.pendingOverhaulSystemTarget) == nil then
            log_dbg(string.format("Skipping partial overhaul for %s: no valid system targets resolved for '%s'", self:getFullName(), tostring(optionTwo)))
            spec.currentState = states.READY
            spec.plannedState = states.READY
            spec.workshopType = workshopType
            spec.serviceOptionOne = nil
            spec.serviceOptionTwo = nil
            spec.serviceOptionThree = false
            resetPendingServiceProgress(spec)
            if self.spec_enterable ~= nil and self.spec_enterable.setIsTabbable ~= nil and C.PARK_VEHICLE then
                self.spec_enterable:setIsTabbable(true)
            end
            return
        end

        self:updateConditionLevel()
    end

    spec.pendingSelectedBreakdowns = {}

    spec.pendingServicePrice = repairPrice

    if totalTimeMs > 0 then
        local adjustedTotalTimeMs = totalTimeMs / spec.maintainability
        spec.maintenanceTimer = adjustedTotalTimeMs
        spec.pendingProgressTotalTime = adjustedTotalTimeMs
        spec.pendingProgressElapsedTime = 0
        spec.pendingProgressStepIndex = 0
        log_dbg(string.format('%s initiated for %s, will take %.2f seconds (%.2f seconds after reliability adjustment). Next planned state: %s', spec.currentState, self:getFullName(), totalTimeMs / 1000, spec.maintenanceTimer / 1000, spec.plannedState))
    else
        spec.currentState = states.READY
        resetPendingServiceProgress(spec)
    end

    if self.isServer and spec.adsDirtyFlag_state ~= nil then
        self:raiseDirtyFlags(spec.adsDirtyFlag_state)
        self:raiseDirtyFlags(spec.adsDirtyFlag_serviceProgress)
        self:raiseDirtyFlags(spec.adsDirtyFlag_serviceContext)
    end
end

function AdvancedDamageSystem:processService(dt)
    local spec = self.spec_AdvancedDamageSystem
    local states = AdvancedDamageSystem.STATUS
    local vehicleState = self:getCurrentStatus()
    local C = ADS_Config.MAINTENANCE

    if vehicleState == states.READY 
        or (spec.workshopType == AdvancedDamageSystem.WORKSHOP.DEALER and not ADS_Main.isWorkshopOpen)
        or (spec.workshopType == AdvancedDamageSystem.WORKSHOP.OWN and not ADS_Main.isWorkshopOpen) then
            return
    end

    -- timer progress
    local timeScale = g_currentMission.missionInfo.timeScale
    local prevTimer = spec.maintenanceTimer or 0
    spec.maintenanceTimer = (spec.maintenanceTimer or 0) - dt * timeScale
    local progressed = math.max(prevTimer - math.max(spec.maintenanceTimer, 0), 0)

    if spec.pendingProgressTotalTime > 0 then
        spec.pendingProgressElapsedTime = math.min((spec.pendingProgressElapsedTime or 0) + progressed, spec.pendingProgressTotalTime)
    end

    local serviceType = spec.currentState
    local optionOne = spec.serviceOptionOne
    local optionTwo = spec.serviceOptionTwo
    local optionTwoKey = ADS_Utils.getNameByValue(AdvancedDamageSystem.PART_TYPES, optionTwo) or AdvancedDamageSystem.PART_TYPES.OEM

    -- inspection effect
    if serviceType == states.INSPECTION or serviceType == states.MAINTENANCE then
        local steps = #spec.pendingInspectionQueue
        local breakdownsRevealed = false
        if steps > 0 and spec.pendingProgressTotalTime > 0 then
            local targetStep = math.min(steps, math.floor((spec.pendingProgressElapsedTime / spec.pendingProgressTotalTime) * steps))
            while spec.pendingProgressStepIndex < targetStep do
                spec.pendingProgressStepIndex = spec.pendingProgressStepIndex + 1
                local breakdownId = spec.pendingInspectionQueue[spec.pendingProgressStepIndex]
                local breakdown = self:getActiveBreakdowns()[breakdownId]
                if breakdown ~= nil and not breakdown.isVisible then
                    local breakdownDef = ADS_Breakdowns.BreakdownRegistry[breakdownId]
                    if breakdownDef ~= nil and breakdownDef.stages ~= nil and breakdownDef.stages[breakdown.stage] ~= nil then
                        local inspectionDetectionMul = 1.0
                        if serviceType == states.INSPECTION then
                            local optionOneKey = ADS_Utils.getNameByValue(AdvancedDamageSystem.INSPECTION_TYPES, optionOne)
                            inspectionDetectionMul = C.INSPECTION_DETECTION_CHANCE_MULTIPLIERS[optionOneKey] or 1.0
                        end
                        local chance = (breakdownDef.stages[breakdown.stage].detectionChance * inspectionDetectionMul) or 0
                        if math.random() < chance then
                            if breakdown.isActive or optionOne == AdvancedDamageSystem.INSPECTION_TYPES.COMPLETE then
                                breakdown.isVisible = true
                                breakdownsRevealed = true
                                table.insert(spec.pendingSelectedBreakdowns, breakdownId)
                            end
                        end
                    end
                end
            end
        end
        -- Sync newly-revealed breakdowns
        if breakdownsRevealed and self.isServer and spec.adsDirtyFlag_breakdowns ~= nil then
            self:raiseDirtyFlags(spec.adsDirtyFlag_breakdowns)
        end

    -- repair effect
    elseif serviceType == states.REPAIR then
        local steps = #spec.pendingRepairQueue
        if steps > 0 and spec.pendingProgressTotalTime > 0 then
            local targetStep = math.min(steps, math.floor((spec.pendingProgressElapsedTime / spec.pendingProgressTotalTime) * steps))
            while spec.pendingProgressStepIndex < targetStep do
                spec.pendingProgressStepIndex = spec.pendingProgressStepIndex + 1
                local breakdownId = spec.pendingRepairQueue[spec.pendingProgressStepIndex]
                if breakdownId ~= nil and self:getActiveBreakdowns()[breakdownId] ~= nil then
                    table.insert(spec.pendingSelectedBreakdowns, breakdownId)

                    local breakdownDef = ADS_Breakdowns.BreakdownRegistry[breakdownId]
                    local systemName = breakdownDef ~= nil and breakdownDef.system or nil
                    local systemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, systemName)
                    local systemData = (systemKey ~= nil and systemKey ~= "" and spec.systems ~= nil) and spec.systems[systemKey] or nil
        
                    if optionOne == AdvancedDamageSystem.REPAIR_TYPES.LOW then
                        local random = math.random()
                        local serviceScale = ADS_Config.CORE.DEFAULT_SERVICE_WEAR / ADS_Config.CORE.BASE_SERVICE_WEAR
                        self:suspendBreakdown(breakdownId, ADS_Config.CORE.REPEAT_BREAKDOWN_TIME * serviceScale* (random + 0.5))
                    else
                        local stage = self:getActiveBreakdowns()[breakdownId].stage
                        self:removeBreakdown(breakdownId)
                        if systemData ~= nil then
                            markRepairStressReduction(spec, systemKey, optionOne)
                        else
                            log_dbg(string.format("Repair effect skipped: missing system mapping for breakdown '%s' (system='%s')", tostring(breakdownId), tostring(systemName)))
                        end
                        --- roll for defected parts
                        if optionTwo ~= AdvancedDamageSystem.PART_TYPES.PREMIUM then
                            local defectChance = C.PARTS_BREAKDOWN_CHANCES[optionTwoKey]
                            if math.random() < defectChance then
                                local serviceScale = ADS_Config.CORE.DEFAULT_SERVICE_WEAR / ADS_Config.CORE.BASE_SERVICE_WEAR
                                self:addBreakdown(breakdownId, {
                                    stage = stage,
                                    isVisible = false,
                                    isSelectedForRepair = true,
                                    isActive = false,
                                    resumeTimer =  ADS_Config.CORE.REPEAT_BREAKDOWN_TIME * serviceScale * (math.random() + 0.5),
                                    progressTimer = 0,
                                    source = AdvancedDamageSystem.BREAKDOWN_SOURCES.POOR_PARTS
                                })
                            end
                        end
                    end
                    
                end
            end
        end

        if spec.pendingProgressTotalTime > 0 then
            local ratio = math.min(math.max(spec.pendingProgressElapsedTime / spec.pendingProgressTotalTime, 0), 1)
            applyPendingRepairStressInterpolation(spec, ratio)
        end
        self:updateConditionLevel()
    end

    if serviceType == states.MAINTENANCE and spec.pendingMaintenanceServiceStart ~= nil and spec.pendingMaintenanceServiceTarget ~= nil and spec.pendingProgressTotalTime > 0 then
        local ratio = math.min(math.max(spec.pendingProgressElapsedTime / spec.pendingProgressTotalTime, 0), 1)
        local interpolatedService = spec.pendingMaintenanceServiceStart + (spec.pendingMaintenanceServiceTarget - spec.pendingMaintenanceServiceStart) * ratio
        spec.serviceLevel = math.max(spec.pendingMaintenanceServiceStart, interpolatedService)
        applyPendingPreventiveStressInterpolation(spec, ratio)
    
    --- overhaul
    elseif serviceType == states.OVERHAUL and spec.pendingProgressTotalTime > 0 then
        local ratio = math.min(math.max(spec.pendingProgressElapsedTime / spec.pendingProgressTotalTime, 0), 1)
        local hasPerSystemTargets = spec.pendingOverhaulSystemStart ~= nil and next(spec.pendingOverhaulSystemStart) ~= nil and spec.pendingOverhaulSystemTarget ~= nil and next(spec.pendingOverhaulSystemTarget) ~= nil
        if hasPerSystemTargets then
            for systemKey, startCondition in pairs(spec.pendingOverhaulSystemStart) do
                local systemData = spec.systems[systemKey]
                local targetCondition = spec.pendingOverhaulSystemTarget[systemKey]
                if systemData ~= nil and targetCondition ~= nil then
                    local interpolatedCondition = startCondition + (targetCondition - startCondition) * ratio
                    systemData.condition = math.max(startCondition, interpolatedCondition)
                end
            end
            applyPendingOverhaulStressInterpolation(spec, ratio)
            self:updateConditionLevel()
        end
    end

    -- work done
    if (spec.maintenanceTimer or 0) <= 0 then
        spec.maintenanceTimer = 0
        if serviceType == states.MAINTENANCE and math.random() < C.PARTS_BREAKDOWN_CHANCES[optionTwoKey] then
            self:addBreakdown('MAINTENANCE_WITH_POOR_QUALITY_CONSUMABLES', 1)
            log_dbg("Added breakdown 'MAINTENANCE_WITH_POOR_QUALITY_CONSUMABLES' due to poor quality consumables chance.")
        end
        self:completeService()
    end
end

function AdvancedDamageSystem:completeService()
    local spec = self.spec_AdvancedDamageSystem
    local states = AdvancedDamageSystem.STATUS
    local serviceType = spec.currentState
    local optionOne = spec.serviceOptionOne
    local optionTwo = spec.serviceOptionTwo
    local optionThree = spec.serviceOptionThree
    local selectedBreakdowns = ADS_Utils.shallowCopy(spec.pendingSelectedBreakdowns or {})
    local plannedRepairCandidateIds = {}

    if serviceType ~= states.INSPECTION then
        local nominalCapacityAh = math.max(spec.batteryCapacityAh or 0, 1)
        local usableCapacityAh = math.max(
            nominalCapacityAh * ADS_Config.ELECTRICAL.BATTERY_USABLE_CAPACITY_FACTOR,
            0.01
        )
        local effectiveCapacityAh = math.max(usableCapacityAh * math.max(spec.batteryHealth or 0, 0.0001), 0.01)
        spec.batterySoc = 1.0
        spec.batteryChargeAh = effectiveCapacityAh
    end

    --- charge battery
    if serviceType == states.MAINTENANCE and spec.pendingMaintenanceServiceTarget ~= nil then
        local maintenanceStart = spec.pendingMaintenanceServiceStart or spec.serviceLevel
        spec.serviceLevel = math.max(maintenanceStart, spec.pendingMaintenanceServiceTarget)
        for systemKey, targetStress in pairs(spec.pendingPreventiveSystemStressTarget or {}) do
            local systemData = spec.systems[systemKey]
            if systemData ~= nil then
                systemData.stress = math.max(tonumber(targetStress) or 0, 0)
            end
        end
    end

    if serviceType == states.OVERHAUL then
        local hasPerSystemTargets = spec.pendingOverhaulSystemTarget ~= nil and next(spec.pendingOverhaulSystemTarget) ~= nil
        if hasPerSystemTargets then
            for systemKey, targetCondition in pairs(spec.pendingOverhaulSystemTarget) do
                local systemData = spec.systems[systemKey]
                if systemData ~= nil then
                    systemData.condition = math.clamp(tonumber(targetCondition) or systemData.condition or 1.0, 0.001, 1.0)
                    systemData.stress = 0
                end
            end
            self:updateConditionLevel()
        end
        
        spec.serviceLevel = optionOne ~= AdvancedDamageSystem.OVERHAUL_TYPES.PARTIAL and 1.0 or spec.serviceLevel

        local idsToRepair = {}
        for id, _ in pairs(spec.activeBreakdowns) do
            if ADS_Breakdowns.BreakdownRegistry[id] and ADS_Breakdowns.BreakdownRegistry[id].isSelectable then
                if optionOne ~= AdvancedDamageSystem.OVERHAUL_TYPES.PARTIAL or optionTwo == ADS_Breakdowns.BreakdownRegistry[id].system then
                    table.insert(idsToRepair, id)
                end
            end
        end

        selectedBreakdowns = idsToRepair
        if #idsToRepair > 0 then
            self:removeBreakdown(table.unpack(idsToRepair))
        end
    elseif serviceType == states.REPAIR then
        for systemKey, targetStress in pairs(spec.pendingRepairSystemStressTarget or {}) do
            local systemData = spec.systems[systemKey]
            if systemData ~= nil then
                systemData.stress = math.max(tonumber(targetStress) or 0, 0)
            end
        end
        self:updateConditionLevel()

        if optionThree == true then
            spec.plannedState = states.MAINTENANCE
        end
    end

    if serviceType == states.INSPECTION or serviceType == states.MAINTENANCE then
        local needRepair = #selectedBreakdowns > 0
        for _, breakdownId in ipairs(selectedBreakdowns) do
            table.insert(plannedRepairCandidateIds, breakdownId)
        end

        for breakdownId, breakdown in pairs(self:getActiveBreakdowns()) do
            if breakdown.isVisible and breakdown.isSelectedForRepair then
                needRepair = true
                table.insert(plannedRepairCandidateIds, breakdownId)
            end
        end

        if optionThree and needRepair then
            -- Planned repair should have a concrete queue. Ensure discovered/selected visible
            -- breakdowns are marked for repair before the next service starts.
            for _, breakdownId in ipairs(plannedRepairCandidateIds) do
                local breakdown = self:getActiveBreakdowns()[breakdownId]
                if breakdown ~= nil and breakdown.isVisible then
                    breakdown.isSelectedForRepair = true
                end
            end
            spec.plannedState = states.REPAIR
        end
    end

    spec.pendingSelectedBreakdowns = selectedBreakdowns
    self:recalculateAndApplyEffects()
    self:addEntryToMaintenanceLog(serviceType, optionOne, optionTwo, optionThree, spec.pendingServicePrice, true)

    local lastEntry = spec.maintenanceLog and spec.maintenanceLog[#spec.maintenanceLog]
    if lastEntry ~= nil then
        lastEntry.isVisible = true
    end

    -- unpark vehicle
    if self.spec_enterable ~= nil and self.spec_enterable.setIsTabbable ~= nil then 
        self.spec_enterable:setIsTabbable(true)
    end

    -- clean vehicle
    if serviceType ~= states.INSPECTION then
        self:setDirtAmount(0)
        spec.radiatorClogging = 0
        spec.airIntakeClogging = 0
        spec.lubricationLevel = 1.0
    end

    -- repaint vehicle
    if serviceType == states.OVERHAUL or optionThree == true then
        self:repaintVehicle(true)
    end

    -- cvt addon repair
    if serviceType == states.REPAIR or serviceType == states.OVERHAUL and spec.pendingSelectedBreakdowns.CVT_ADDON_MALFUNCTION ~= nil then
        local systemData = spec.systems.transmission
        if systemData.stress > 0.25 then
            spec.systems.transmission.stress = 0.25
        end
    end

    local maintenanceCompletedText = self:getFullName() .. ": " .. g_i18n:getText(serviceType) .. " " .. g_i18n:getText("ads_spec_maintenance_complete_notification")

    if serviceType == states.INSPECTION or serviceType == states.MAINTENANCE then
        local activeBreakdowns = self:getActiveBreakdowns()
        local activeBreakdownsCount = 0
        for _, value in pairs(activeBreakdowns) do
            if value.isVisible then
                activeBreakdownsCount = activeBreakdownsCount + 1
            end
        end
        if activeBreakdownsCount == 0 then
            maintenanceCompletedText = maintenanceCompletedText .. ". " .. g_i18n:getText("ads_spec_inspection_no_issues_detected_notification")
        else
            maintenanceCompletedText = maintenanceCompletedText .. ". " .. string.format(g_i18n:getText("ads_spec_inspection_issues_detected_notification"), activeBreakdownsCount)
        end
    end

    -- Host-side notification: only if host owns the vehicle (clients get it via ADS_VehicleChangeStatusEvent)
    if g_currentMission.hud ~= nil and g_currentMission.hud.addSideNotification ~= nil
            and self:getOwnerFarmId() == g_currentMission:getFarmId() then
        g_currentMission.hud:addSideNotification({1, 1, 1, 1}, maintenanceCompletedText)
    end

    if g_currentMission:getFarmId() == self.ownerFarmId and ADS_Main.samples ~= nil and ADS_Main.samples.maintenanceCompleted2D ~= nil then
        g_soundManager:playSample(ADS_Main.samples.maintenanceCompleted2D)
    end


    -- Sync maintenance log to all clients via dedicated event
    if self.isServer then
        local lastEntry = spec.maintenanceLog and spec.maintenanceLog[#spec.maintenanceLog]
        if lastEntry ~= nil then
            ADS_LogEntrySyncEvent.sendToClients(self, lastEntry)
        end
    end

    spec.maintenanceTimer = 0
    resetPendingServiceProgress(spec)
    spec.serviceOptionOne = nil
    spec.serviceOptionTwo = nil
    spec.serviceOptionThree = false

    if self.isServer and spec.adsDirtyFlag_state ~= nil then
        self:raiseDirtyFlags(spec.adsDirtyFlag_state)
        self:raiseDirtyFlags(spec.adsDirtyFlag_serviceProgress)
        self:raiseDirtyFlags(spec.adsDirtyFlag_serviceContext)
    end

    if spec.plannedState ~= states.READY then
        local nextWork = spec.plannedState
        spec.plannedState = states.READY
        spec.currentState = states.READY

        local nextOptionOne, nextOptionTwo, nextOptionThree

        if nextWork == states.REPAIR then
            nextOptionOne = AdvancedDamageSystem.REPAIR_TYPES.MEDIUM
            nextOptionTwo = AdvancedDamageSystem.PART_TYPES.OEM
            nextOptionThree = false
        elseif nextWork == states.MAINTENANCE then
            nextOptionOne = AdvancedDamageSystem.MAINTENANCE_TYPES.STANDARD
            nextOptionTwo = AdvancedDamageSystem.PART_TYPES.OEM
            nextOptionThree = false
        end

        if nextWork == states.REPAIR then
            local repairQueueCount = 0
            for breakdownId, breakdown in pairs(self:getActiveBreakdowns()) do
                if isBreakdownSelectedForPlayerRepair(breakdownId, breakdown, AdvancedDamageSystem.REPAIR_TYPES.MEDIUM) then
                    repairQueueCount = repairQueueCount + 1
                end
            end

            if repairQueueCount == 0 then
                log_dbg("Planned REPAIR skipped: no visible selected breakdowns to repair.")
                ADS_VehicleChangeStatusEvent.send(self, maintenanceCompletedText)
                return
            end
        end

        local price = self:getServicePrice(nextWork, nextOptionOne, nextOptionTwo, nextOptionThree)

        if g_currentMission:getMoney() >= price then
            self:initService(nextWork, spec.workshopType, nextOptionOne, nextOptionTwo, nextOptionThree)
            local started = spec.currentState == nextWork and (spec.maintenanceTimer or 0) > 0

            if started then
                if price > 0 then
                    g_currentMission:addMoney(-1 * price, self:getOwnerFarmId(), MoneyType.VEHICLE_RUNNING_COSTS, true, true)
                end
                local nextServiceText = string.format("%s: %s", self:getFullName(), string.format(g_i18n:getText('ads_spec_next_planned_service_notification'), g_i18n:getText(nextWork)))
                if g_currentMission.hud ~= nil and g_currentMission.hud.addSideNotification ~= nil
                        and self:getOwnerFarmId() == g_currentMission:getFarmId() then
                    g_currentMission.hud:addSideNotification({1, 1, 1, 1}, nextServiceText)
                end
                ADS_VehicleChangeStatusEvent.send(self, maintenanceCompletedText)
            else
                log_dbg("Planned service was requested but did not start. State:", tostring(spec.currentState), "Timer:", tostring(spec.maintenanceTimer))
                ADS_VehicleChangeStatusEvent.send(self, maintenanceCompletedText)
            end
        else
            local notEnoughMoneyText = string.format("%s: %s", self:getFullName(), string.format(g_i18n:getText('ads_spec_next_planned_service_not_enouth_money_notification'), g_i18n:getText(nextWork)))
            if g_currentMission.hud ~= nil and g_currentMission.hud.addSideNotification ~= nil
                    and self:getOwnerFarmId() == g_currentMission:getFarmId() then
                g_currentMission.hud:addSideNotification({1, 1, 1, 1}, notEnoughMoneyText)
            end
            ADS_VehicleChangeStatusEvent.send(self, maintenanceCompletedText)
        end
    else
        spec.currentState = states.READY
        ADS_VehicleChangeStatusEvent.send(self, maintenanceCompletedText)
    end
end

function AdvancedDamageSystem:cancelService()
    local spec = self.spec_AdvancedDamageSystem
    local states = AdvancedDamageSystem.STATUS
    local serviceType = spec.currentState

    if serviceType == states.READY then
        return
    end

    local optionOne = spec.serviceOptionOne
    local optionTwo = spec.serviceOptionTwo
    local optionThree = spec.serviceOptionThree
    local selectedBreakdowns = ADS_Utils.shallowCopy(spec.pendingSelectedBreakdowns or {})

    spec.pendingSelectedBreakdowns = selectedBreakdowns
    self:recalculateAndApplyEffects()
    self:addEntryToMaintenanceLog(serviceType, optionOne, optionTwo, optionThree, spec.pendingServicePrice, false)

    local lastEntry = spec.maintenanceLog and spec.maintenanceLog[#spec.maintenanceLog]
    if lastEntry ~= nil then
        lastEntry.isVisible = true
    end

    if self.spec_enterable ~= nil and self.spec_enterable.setIsTabbable ~= nil then
        self.spec_enterable:setIsTabbable(true)
    end

    local cancelText = string.format("%s: %s %s", self:getFullName(), g_i18n:getText(serviceType), g_i18n:getText("ads_spec_maintenance_cancelled_notification"))
    -- Host-side notification: only if host owns the vehicle (clients get it via ADS_VehicleChangeStatusEvent)
    if g_currentMission.hud ~= nil and g_currentMission.hud.addSideNotification ~= nil
            and self:getOwnerFarmId() == g_currentMission:getFarmId() then
        g_currentMission.hud:addSideNotification({1, 1, 1, 1}, cancelText)
    end

    -- Sync maintenance log to all clients via dedicated event
    if self.isServer then
        local lastEntry = spec.maintenanceLog and spec.maintenanceLog[#spec.maintenanceLog]
        if lastEntry ~= nil then
            ADS_LogEntrySyncEvent.sendToClients(self, lastEntry)
        end
    end

    spec.maintenanceTimer = 0
    spec.plannedState = states.READY
    spec.currentState = states.READY
    resetPendingServiceProgress(spec)
    spec.serviceOptionOne = nil
    spec.serviceOptionTwo = nil
    spec.serviceOptionThree = false

    if self.isServer and spec.adsDirtyFlag_state ~= nil then
        self:raiseDirtyFlags(spec.adsDirtyFlag_state)
        self:raiseDirtyFlags(spec.adsDirtyFlag_serviceProgress)
        self:raiseDirtyFlags(spec.adsDirtyFlag_serviceContext)
    end

    ADS_VehicleChangeStatusEvent.send(self, cancelText)
end

function AdvancedDamageSystem:addEntryToMaintenanceLog(maintenanceType, optionOne, optionTwo, optionThree, price, isCompleted)
    local spec = self.spec_AdvancedDamageSystem
    if not spec then return end

    local entryId = (#spec.maintenanceLog or 0) + 1
    local env = g_currentMission.environment
    local selectedBreakdowns = ADS_Utils.shallowCopy(spec.pendingSelectedBreakdowns or {})
    local systemsSnapshot = ADS_Utils.createSystemsSnapshot(spec.systems)

    local entry = {
        id = entryId,                     
        type = maintenanceType,
        price = price ~= nil and price or self:getServicePrice(maintenanceType, optionOne, optionTwo, optionThree),
        location = spec.workshopType,
        date = { 
            day = env.currentDayInPeriod or 1, 
            month = env.currentPeriod, 
            year = env.currentYear 
        },

        optionOne = optionOne,
        optionTwo = optionTwo or "NONE",
        optionThree = optionThree,
        isVisible = false,
        isCompleted = isCompleted ~= false,
        isLegacyEntry = false,

        conditionData = {
            year = spec.year,
            operatingHours = self:getFormattedOperatingTime(), 
            age = self.age,
            condition = self:getConditionLevel(),
            service = self:getServiceLevel(),
            systems = systemsSnapshot,
            batterySoc = tonumber(spec.batterySoc) or 1,
            activeBreakdowns = ADS_Utils.deepCopy(self:getActiveBreakdowns()),
            selectedBreakdowns = selectedBreakdowns,
            activeEffects = ADS_Utils.shallowCopy(spec.activeEffects),
            activeIndicators = ADS_Utils.shallowCopy(spec.activeIndicators),
            reliability = spec.reliability,
            maintainability = spec.maintainability,
        }
    }

    table.insert(spec.maintenanceLog, entry)
    spec.lastLogEntry = entry
end


-- ==========================================================
--                       ELECTRICAL
-- ==========================================================

local function getBatteryTempFactors(tempC)
    local cap = 1.0
    if tempC < 25 then
        cap = math.clamp(1.0 - (25 - tempC) * 0.004, 0.55, 1.0)
    end

    local rint = 1.0
    if tempC < 20 then
        rint = 1.0 + (20 - tempC) * 0.02
    end

    return cap, rint
end

local getBatteryChargeAcceptance

local function evaluateAlternatorRpmCurve(curveData, rpmNorm)
    rpmNorm = math.clamp(rpmNorm or 0, 0, 1)
    if type(curveData) ~= "table" then
        return nil
    end

    local points = {}
    for _, point in pairs(curveData) do
        local x, y
        if type(point) == "table" then
            x = tonumber(point.x or point.rpm or point.rpmNorm or point[1])
            y = tonumber(point.y or point.factor or point.output or point[2])
        end

        if x ~= nil and y ~= nil then
            table.insert(points, {
                x = math.clamp(x, 0, 1),
                y = math.max(y, 0)
            })
        end
    end

    if #points == 0 then
        return nil
    end

    table.sort(points, function(a, b) return a.x < b.x end)

    if rpmNorm <= points[1].x then
        return points[1].y
    end

    for i = 2, #points do
        local p0 = points[i - 1]
        local p1 = points[i]
        if rpmNorm <= p1.x then
            local span = math.max(p1.x - p0.x, 0.000001)
            local t = (rpmNorm - p0.x) / span
            return p0.y + (p1.y - p0.y) * t
        end
    end

    return points[#points].y
end

local function calculateAlternatorOutput(vehicle, isMotorStarted, iLoads, batteryState)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then
        return 0
    end

    local cfg = ADS_Config.ELECTRICAL or {}

    local iAltAvail = 0
    local iAltRaw = 0
    local altFactor = 0
    local acceptK, tempK, socK, healthK = 1.0, 1.0, 1.0, 1.0

    local batteryTempC = spec.batteryTempC
    local batterySoc = spec.batterySoc
    local batteryHealth = spec.batteryHealth

    if batteryState ~= nil then
        batteryTempC = batteryState.tempC
        batterySoc = batteryState.soc
        batteryHealth = batteryState.health
    end

    if isMotorStarted then
        local motor = vehicle:getMotor()
        if motor ~= nil then
            local lastRpm = motor:getLastModulatedMotorRpm() or 0
            local maxRpm = math.max(motor.maxRpm or 1, 1)
            local rpmNorm = math.clamp(lastRpm / maxRpm, 0, 1)

            local curveFactor = evaluateAlternatorRpmCurve(cfg.ALT_RPM_CURVE, rpmNorm)
            if curveFactor == nil then
                local idleFactor = math.clamp(cfg.ALT_IDLE_FACTOR or 0.25, 0, 1)
                curveFactor = idleFactor + (1 - idleFactor) * rpmNorm
            end

            altFactor = math.max(curveFactor, 0)
            iAltRaw = (cfg.ALT_MAX_OUTPUT or 0) * altFactor * math.max(spec.alternatorHealth or 1, 0)

            local loadA = math.max(iLoads or 0, 0)
            local chargeHeadroomA = math.max(iAltRaw - loadA, 0)

            acceptK, tempK, socK, healthK =
                getBatteryChargeAcceptance(batteryTempC, batterySoc, batteryHealth)

            if iAltRaw <= loadA then
                iAltAvail = iAltRaw
            else
                iAltAvail = loadA + chargeHeadroomA * acceptK
            end
        end
    end

    if ADS_Config.DEBUG then
        local dbg = spec.debugData.battery
        dbg.iAltAvail = iAltAvail or 0
        dbg.iAltRaw = iAltRaw or 0
        dbg.altFactor = altFactor or 0
        dbg.acceptK = acceptK
        dbg.acceptTempK = tempK
        dbg.acceptSocK = socK
        dbg.acceptHealthK = healthK
        dbg.acceptSourceSoc = batterySoc or 0
        dbg.acceptSourceTempC = batteryTempC or 0
        dbg.acceptSourceHealth = batteryHealth or 1
        dbg.acceptUsesExternalState = batteryState ~= nil
    end

    return iAltAvail
end

local function calculateCurrentLoadAmps(vehicle, isMotorStarted, envTemp)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then
        return
    end

   -- base load
    local baseLoadA = isMotorStarted and 18 or 0.3

    -- cab fan
    local cabFanA = isMotorStarted and 12 or 0

    -- heater
    local winterHeaterA = 0

    if isMotorStarted and envTemp <= 15 then
        winterHeaterA = 20 * ((15 - envTemp) / 15)

    end

    -- lights (3 load levels by active main lights mask)
    local lightsLoadA = 0
    if vehicle.spec_lights ~= nil and vehicle.getLightsTypesMask ~= nil then
        local lightsSpec = vehicle.spec_lights
        local lightsMask = tonumber(vehicle:getLightsTypesMask()) or 0
        local maxLightStateMask = tonumber(lightsSpec.maxLightStateMask) or 0
        local activeMainLightsMask = lightsMask

        if maxLightStateMask > 0 and bitAND ~= nil then
            activeMainLightsMask = bitAND(lightsMask, maxLightStateMask)
        end

        if activeMainLightsMask > 0 then
            local lightStateLevel = 1
            if activeMainLightsMask == 1 then
                    lightStateLevel = 1
            elseif activeMainLightsMask == 3 then
                    lightStateLevel = 2
            elseif activeMainLightsMask == 7 then
                    lightStateLevel = 3
            elseif activeMainLightsMask == 23 then
                lightStateLevel = 4
            end
            lightsLoadA = (20 / 3) * lightStateLevel
        end
    end

    -- starterCranking
    local crankingA = 0
    if spec.systems.electrical ~= nil and spec.systems.electrical.isCranking ~= nil and spec.systems.electrical.isCranking then
        crankingA = ADS_Config.ELECTRICAL.BATTERY_CRANK_CURRENT_A * (0.8 + math.random() * 0.4)
    end

    -- pulse
    local isPeakPulse = math.random() > 0.95
    local nominalPulse = isPeakPulse and (20 + spec.extraCurrentPeak) or (2 + spec.extraCurrentPeak)
    local pulseA = isMotorStarted and (nominalPulse * math.random()) or 0

    -- total
    local iLoads = baseLoadA + lightsLoadA + cabFanA + winterHeaterA + crankingA + pulseA

    if ADS_Config.DEBUG then
        local dbg = spec.debugData.battery
        dbg.iLoads = iLoads
        dbg.baseLoadA = baseLoadA
        dbg.lightsLoadA = lightsLoadA
        dbg.cabFanA = cabFanA
        dbg.winterHeaterA = winterHeaterA
        dbg.peakPulseA = pulseA
        dbg.crankingLoadA = crankingA
    end

    spec.iLoads = iLoads
    return iLoads
end

local function smoothstep(x)
    x = math.clamp(x, 0, 1)
    return x * x * (3 - 2 * x)
end

local function getBatteryOpenCircuitVoltage(soc)
    local C = ADS_Config.ELECTRICAL or {}
    local vEmpty = C.OCV_EMPTY_V
    local vFull = C.OCV_FULL_V

    soc = math.clamp(soc or 0, 0, 1)

    local shapedSoc = 0.65 * smoothstep(soc) + 0.35 * soc
    return vEmpty + (vFull - vEmpty) * shapedSoc
end

local function getBatteryTerminalVoltage(ocvV, iAltAvail, iLoads, isCranking, rIntOhm)
    local C = ADS_Config.ELECTRICAL or {}

    local chargeRisePer20A = C.BATTERY_CHARGE_RISE_PER_20A_V or 0.18
    local chargeRiseMaxV = C.BATTERY_CHARGE_RISE_MAX_V or 1.6
    local chargeTargetMaxV = C.BATTERY_CHARGE_TARGET_MAX_V or 14.4
    local chargeIrScale = C.BATTERY_CHARGE_IR_SCALE or 0.0

    local termMinV = C.BATTERY_TERMINAL_MIN_V or 8.5
    local termMaxV = C.BATTERY_TERMINAL_MAX_V or 14.8

    local iAlt = math.max(iAltAvail or 0, 0)
    local iLoad = math.max(iLoads or 0, 0)
    local iDischarge = math.max(iLoad - iAlt, 0)
    local iCharge = math.max(iAlt - iLoad, 0)

    local loadDropV = iDischarge * math.max(rIntOhm or 0, 0)

    local vTerm = (ocvV or 0) - loadDropV

    local linearChargeRiseV = (iCharge / 20) * chargeRisePer20A
    local irChargeRiseV = iCharge * math.max(rIntOhm or 0, 0) * math.max(chargeIrScale, 0)
    local chargeRiseV = math.min(linearChargeRiseV + irChargeRiseV, chargeRiseMaxV)
    if iCharge > 0 then
        vTerm = math.min(vTerm + chargeRiseV, math.min(chargeTargetMaxV, termMaxV))
    end

    vTerm = math.clamp(vTerm, termMinV, termMaxV)
    return vTerm, loadDropV, chargeRiseV, iDischarge, iCharge
end

local function getSystemVoltage(isMotorStarted, batteryTerminalV, iAltAvail, iLoads, alternatorHealth)
    local C = ADS_Config.ELECTRICAL

    batteryTerminalV = batteryTerminalV or 12.0
    iAltAvail = math.max(iAltAvail or 0, 0)
    iLoads = math.max(iLoads or 0, 0)
    alternatorHealth = math.clamp(alternatorHealth or 1.0, 0.0, 1.0)

    if not isMotorStarted then
        return batteryTerminalV, batteryTerminalV, 0, 0, 0, 1
    end

    local regMinV = C.ALTERNATOR_MIN_REGULATED_VOLTAGE or 13.6
    local regMaxV = C.ALTERNATOR_REGULATED_VOLTAGE or 14.1
    local altThreshold = math.clamp(C.ALT_HEALTH_REGULATION_THRESHOLD or 0.15, 0.01, 1.0)
    local regulationHealth = math.clamp((alternatorHealth - altThreshold) / math.max(1 - altThreshold, 0.0001), 0, 1)
    local regulatedV = regMinV + (regMaxV - regMinV) * regulationHealth

    local deficitA = math.max(iLoads - iAltAvail, 0)
    local surplusA = math.max(iAltAvail - iLoads, 0)
    local deficitSagPerAmp = C.ALT_DEFICIT_SAG_PER_AMP or 0.045
    local lowHealthDeficitMult = C.ALT_LOW_HEALTH_DEFICIT_MULT or 1.8
    local supportGain = math.clamp(C.ALT_BATTERY_SUPPORT_GAIN or 0.45, 0, 1)
    local maxSystemV = C.MAX_SYSTEM_VOLTAGE or 14.4
    local surplusHeadroomV = math.max(C.ALT_SURPLUS_CHARGE_HEADROOM_V or 0.15, 0)
    local healthDeficitMult = 1 + (1 - alternatorHealth) * math.max(lowHealthDeficitMult - 1, 0)
    local sagV = deficitA * deficitSagPerAmp * healthDeficitMult
    local chargeHeadroomV = 0

    local rawSystemV
    if iAltAvail <= 0.01 or regulationHealth <= 0 then
        rawSystemV = batteryTerminalV
    elseif iAltAvail >= iLoads then
        local chargeHeadroomT = math.clamp(surplusA / 60, 0, 1)
        chargeHeadroomV = math.min(surplusHeadroomV * chargeHeadroomT, math.max(maxSystemV - regulatedV, 0))
        rawSystemV = regulatedV + chargeHeadroomV
    else
        local batterySupportV = batteryTerminalV + (regulatedV - batteryTerminalV) * supportGain * alternatorHealth
        rawSystemV = math.max(regulatedV - sagV, batterySupportV)
    end

    rawSystemV = math.clamp(rawSystemV, C.MIN_SYSTEM_VOLTAGE or 9.0, maxSystemV)

    return rawSystemV, regulatedV, deficitA, sagV, regulationHealth, healthDeficitMult, chargeHeadroomV
end

getBatteryChargeAcceptance = function(tempC, soc, health)
    local C = ADS_Config.ELECTRICAL or {}

    local tMin = C.CHARGE_ACCEPT_TEMP_MIN_C or -15
    local tMax = C.CHARGE_ACCEPT_TEMP_MAX_C or 25
    local taperStart = C.CHARGE_TAPER_SOC_START or 0.80
    local taperEnd = C.CHARGE_TAPER_SOC_END or 0.98
    local minHealthK = math.clamp(C.BATTERY_HEALTH_ACCEPTANCE_MIN or 0.35, 0.02, 1.0)

    tempC = tempC or 20
    soc = math.clamp(soc or 1, 0, 1)
    health = math.clamp(health or 1, 0.0001, 1.0)

    local tempK
    if tempC <= tMin then
        tempK = 0.15
    elseif tempC >= tMax then
        tempK = 1.0
    else
        local t = (tempC - tMin) / math.max(tMax - tMin, 0.001)
        tempK = 0.15 + 0.85 * smoothstep(t)
    end

    local socK
    if soc <= taperStart then
        socK = 1.0
    elseif soc >= taperEnd then
        socK = 0.05
    else
        local t = (soc - taperStart) / math.max(taperEnd - taperStart, 0.001)
        socK = 1.0 - 0.95 * smoothstep(t)
    end

    local healthK = minHealthK + (1 - minHealthK) * smoothstep(health)

    return math.clamp(tempK * socK * healthK, 0.02, 1.0), tempK, socK, healthK
end

function AdvancedDamageSystem.updateBatteryTemperatureC(vehicle, dtS, ambientC, engineC, iBatteryA, rintF)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then
        return
    end

    local cfg = ADS_Config.ELECTRICAL or {}

    ambientC = ambientC or cfg.AMBIENT_DEFAULT_C or 15
    engineC = engineC or ambientC

    -- thermal inertia (time constant, seconds)
    local tauS = math.max(cfg.BATTERY_THERMAL_TAU_S or 120, 1)

    -- coupling coefficient to engine temperature contribution
    local kEngine = cfg.ENGINE_BAY_COUPLING or 0.30
    kEngine = math.clamp(kEngine, 0, 1)

    -- coupling contribution in degrees C from engine temperature
    local couplingC = kEngine * engineC

    -- effective target temp for battery (ambient + engine contribution)
    local targetC = ambientC + couplingC

    local tempC = spec.batteryTempC or ambientC

    local rRef = math.max(cfg.RINT_REF_OHM or 0.005, 0.0001)
    local rInt = rRef * rintF

    local iA = math.max(iBatteryA or 0, 0)
    local pJouleW = iA * iA * rInt

    local cTh = math.max(cfg.BATTERY_THERMAL_CAPACITY_J_PER_K or 18000, 100)
    -- Move current self-heating into targetC (steady-state rise: dT = P / (C/tau) = P * tau / C)
    local targetJouleRiseC = (pJouleW * tauS) / cTh
    targetC = targetC + targetJouleRiseC

    -- 1st-order lag: T = T + (T_target - T) * alpha
    local alpha = 1 - math.exp(-dtS / tauS)
    tempC = tempC + (targetC - tempC) * alpha
    local dTJoule = targetJouleRiseC * alpha

    -- safety clamp
    spec.batteryTempC = math.clamp(tempC, ambientC, 85)

    if ADS_Config.DEBUG and spec.debugData ~= nil and spec.debugData.battery ~= nil then
        local dbg = spec.debugData.battery
        dbg.dtS = dtS
        dbg.ambientC = ambientC
        dbg.engineC = engineC
        dbg.battTempTargetC = targetC
        dbg.battTempTargetJouleRiseC = targetJouleRiseC
        dbg.battTempAlpha = alpha
        dbg.battTempCoupling = couplingC
        dbg.battTempTauS = tauS
        dbg.batteryTempC = spec.batteryTempC
        dbg.iBatteryA = iA
        dbg.rintFactor = rintF
        dbg.rIntOhm = rInt
        dbg.pJouleW = pJouleW
        dbg.dTJoule = dTJoule
    end
end

local function buildBatteryContext(vehicle, dtS)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then
        return nil
    end

    local isMotorStarted = vehicle.getIsMotorStarted ~= nil and vehicle:getIsMotorStarted() or false

    local environmentTemp = 15
    if g_currentMission ~= nil
        and g_currentMission.environment ~= nil
        and g_currentMission.environment.weather ~= nil then
        local weather = g_currentMission.environment.weather.forecast:getCurrentWeather()
        environmentTemp = (weather ~= nil and weather.temperature) or 15
    end

    local capF, rintF = getBatteryTempFactors(spec.batteryTempC)
    local iLoads = calculateCurrentLoadAmps(vehicle, isMotorStarted, environmentTemp) or 0

    local nominalCapacityAh = math.max(spec.batteryCapacityAh or 0, 1)
    local batteryHealth = math.max(spec.batteryHealth or 0, 0.0001)

    local usableCapacityAh = math.max(
        nominalCapacityAh * capF * ADS_Config.ELECTRICAL.BATTERY_USABLE_CAPACITY_FACTOR,
        0.01
    )

    local effectiveCapacityAh = math.max(usableCapacityAh * batteryHealth, 0.01)

    local chargeAh = spec.batteryChargeAh
    if chargeAh == nil then
        chargeAh = math.clamp((spec.batterySoc or 1.0) * effectiveCapacityAh, 0, effectiveCapacityAh)
    end

    local soc = math.clamp(chargeAh / effectiveCapacityAh, 0, 1)

    local cfg = ADS_Config.ELECTRICAL or {}
    local rRef = math.max(cfg.RINT_REF_OHM or 0.005, 0.0001)
    local maxHealthRintMult = math.max(cfg.BATTERY_HEALTH_RINT_MAX_MULT or 3.0, 1.0)
    local healthRintMult = 1 + (1 - batteryHealth) * (maxHealthRintMult - 1)
    local rIntOhm = rRef * (rintF or 1) * healthRintMult

    local iAltAvail = calculateAlternatorOutput(vehicle, isMotorStarted, iLoads) or 0

    local ocvV = getBatteryOpenCircuitVoltage(soc)

    return {
        vehicle = vehicle,
        spec = spec,
        dtS = dtS,

        isMotorStarted = isMotorStarted,
        environmentTemp = environmentTemp,

        batteryTempC = spec.batteryTempC or environmentTemp,
        batteryHealth = batteryHealth,

        capF = capF,
        rintF = rintF,

        nominalCapacityAh = nominalCapacityAh,
        usableCapacityAh = usableCapacityAh,
        capacityAh = effectiveCapacityAh,

        chargeAh = chargeAh,
        soc = soc,

        rIntOhm = rIntOhm,
        ocvV = ocvV,

        iLoads = iLoads,
        iAltAvail = iAltAvail
    }
end

local function orderExternalPowerContexts(ctxA, ctxB)
    if ctxA == nil or ctxB == nil then
        return ctxA, ctxB
    end

    local aStarted = ctxA.isMotorStarted == true
    local bStarted = ctxB.isMotorStarted == true
    if aStarted ~= bStarted then
        if aStarted then
            return ctxB, ctxA
        end

        return ctxA, ctxB
    end

    local aOcv = tonumber(ctxA.ocvV) or 0
    local bOcv = tonumber(ctxB.ocvV) or 0
    if math.abs(aOcv - bOcv) > 0.001 then
        if aOcv < bOcv then
            return ctxA, ctxB
        end

        return ctxB, ctxA
    end

    local aSoc = tonumber(ctxA.soc) or 0
    local bSoc = tonumber(ctxB.soc) or 0
    if math.abs(aSoc - bSoc) > 0.0001 then
        if aSoc < bSoc then
            return ctxA, ctxB
        end

        return ctxB, ctxA
    end

    local aCharge = tonumber(ctxA.chargeAh) or 0
    local bCharge = tonumber(ctxB.chargeAh) or 0
    if math.abs(aCharge - bCharge) > 0.0001 then
        if aCharge < bCharge then
            return ctxA, ctxB
        end

        return ctxB, ctxA
    end

    local aKey = tonumber(ctxA.vehicle ~= nil and (ctxA.vehicle.rootNode or ctxA.vehicle.id or ctxA.vehicle.uniqueId) or 0) or 0
    local bKey = tonumber(ctxB.vehicle ~= nil and (ctxB.vehicle.rootNode or ctxB.vehicle.id or ctxB.vehicle.uniqueId) or 0) or 0
    if aKey <= bKey then
        return ctxA, ctxB
    end

    return ctxB, ctxA
end

local function buildCompositeBatteryContext(consumerCtx, donorCtx)
    if consumerCtx == nil or donorCtx == nil then
        return nil
    end

    local cableResistanceOhm = 0.010

    local totalCapacityAh = math.max(
        (consumerCtx.capacityAh or 0) + (donorCtx.capacityAh or 0),
        0.01
    )

    local totalChargeAh = math.max(
        (consumerCtx.chargeAh or 0) + (donorCtx.chargeAh or 0),
        0
    )

    local compositeSoc = math.clamp(totalChargeAh / totalCapacityAh, 0, 1)

    local compositeTempC =
        ((consumerCtx.batteryTempC or 20) * (consumerCtx.capacityAh or 0) +
         (donorCtx.batteryTempC or 20) * (donorCtx.capacityAh or 0))
        / totalCapacityAh

    local compositeHealth =
        ((consumerCtx.batteryHealth or 1.0) * (consumerCtx.capacityAh or 0) +
         (donorCtx.batteryHealth or 1.0) * (donorCtx.capacityAh or 0))
        / totalCapacityAh

    local rConsumer = math.max(consumerCtx.rIntOhm or 0.01, 0.0001)
    local rDonorPath = math.max((donorCtx.rIntOhm or 0.01) + cableResistanceOhm, 0.0001)

    local gConsumer = 1 / rConsumer
    local gDonor = 1 / rDonorPath

    local compositeRintOhm = 1 / math.max(gConsumer + gDonor, 0.0001)
    local compositeOcvV = getBatteryOpenCircuitVoltage(compositeSoc)

    return {
        capacityAh = totalCapacityAh,
        chargeAh = totalChargeAh,
        soc = compositeSoc,

        tempC = compositeTempC,
        health = compositeHealth,

        ocvV = compositeOcvV,
        rIntOhm = compositeRintOhm,

        cableResistanceOhm = cableResistanceOhm,

        conductanceConsumer = gConsumer,
        conductanceDonor = gDonor
    }
end

local function calculateBatteryBalanceCurrent(consumerCtx, donorCtx, compositeCtx)
    if consumerCtx == nil or donorCtx == nil or compositeCtx == nil then
        return 0
    end

    local cableResistanceOhm = math.max(compositeCtx.cableResistanceOhm or 0.01, 0.0001)
    local maxCableCurrentA = ADS_Config.ELECTRICAL.EXTERNAL_POWER_MAX_CABLE_CURRENT_A or 400

    local consumerOcvV = tonumber(consumerCtx.ocvV) or 0
    local donorOcvV = tonumber(donorCtx.ocvV) or 0

    local consumerRint = math.max(tonumber(consumerCtx.rIntOhm) or 0.01, 0.0001)
    local donorRint = math.max(tonumber(donorCtx.rIntOhm) or 0.01, 0.0001)

    local totalPathResistanceOhm = consumerRint + donorRint + cableResistanceOhm

    local balanceCurrentA = (donorOcvV - consumerOcvV) / totalPathResistanceOhm

    balanceCurrentA = math.clamp(balanceCurrentA, -maxCableCurrentA, maxCableCurrentA)

    return balanceCurrentA
end

local function applyBatteryBalanceCurrent(consumerCtx, donorCtx, balanceCurrentA, dtS)
    if consumerCtx == nil or donorCtx == nil then
        return consumerCtx, donorCtx
    end

    local dAhBalance = (balanceCurrentA * dtS) / 3600

    consumerCtx.chargeAh = math.clamp(
        (consumerCtx.chargeAh or 0) + dAhBalance,
        0,
        math.max(consumerCtx.capacityAh or 0.01, 0.01)
    )

    donorCtx.chargeAh = math.clamp(
        (donorCtx.chargeAh or 0) - dAhBalance,
        0,
        math.max(donorCtx.capacityAh or 0.01, 0.01)
    )

    consumerCtx.soc = math.clamp(
        consumerCtx.chargeAh / math.max(consumerCtx.capacityAh or 0.01, 0.01),
        0,
        1
    )

    donorCtx.soc = math.clamp(
        donorCtx.chargeAh / math.max(donorCtx.capacityAh or 0.01, 0.01),
        0,
        1
    )

    consumerCtx.ocvV = getBatteryOpenCircuitVoltage(consumerCtx.soc)
    donorCtx.ocvV = getBatteryOpenCircuitVoltage(donorCtx.soc)

    consumerCtx.balanceCurrentA = balanceCurrentA
    donorCtx.balanceCurrentA = balanceCurrentA

    consumerCtx.balanceDeltaAh = dAhBalance
    donorCtx.balanceDeltaAh = -dAhBalance

    return consumerCtx, donorCtx
end

local function ensureBatteryDebugData(spec)
    if spec.debugData == nil then
        spec.debugData = {}
    end
    if spec.debugData.battery == nil then
        spec.debugData.battery = {}
    end
    return spec.debugData.battery
end

local function resetExternalPowerDebug(spec)
    local dbg = ensureBatteryDebugData(spec)
    dbg.isValidConnection = false
    dbg.distance = 0
    dbg.externalConnected = 0
    dbg.externalRole = "-"
    dbg.externalPartnerName = "-"
    dbg.externalCompositeSoc = 0
    dbg.externalCompositeCapacityAh = 0
    dbg.externalCompositeChargeAh = 0
    dbg.externalCompositeRintOhm = 0
    dbg.externalBalanceCurrentA = 0
    dbg.externalCommonNetA = 0
    dbg.externalCommonDeltaAh = 0
    dbg.externalLocalDeltaAh = 0
    dbg.externalAltBeforeA = 0
    dbg.externalAltAfterA = 0
end

local function normalizeExternalPowerConnection(connection)
    if connection == nil then
        return nil
    end

    if type(connection) == "table" and connection.object ~= nil then
        return connection.object
    end

    return connection
end

local function commitBatteryContext(vehicle, ctx, dt)
    if vehicle == nil or ctx == nil or ctx.spec == nil then
        return
    end

    local spec = ctx.spec
    local dbg = ensureBatteryDebugData(spec)

    spec.batteryChargeAh = math.clamp(ctx.chargeAh or 0, 0, math.max(ctx.capacityAh or 0.01, 0.01))
    spec.batterySoc = math.clamp(ctx.soc or 0, 0, 1)
    spec.batteryOpenCircuitVoltageV = ctx.ocvV or getBatteryOpenCircuitVoltage(spec.batterySoc)
    spec.rawBatteryTerminalVoltageV = ctx.rawBatteryTerminalVoltageV or spec.batteryOpenCircuitVoltageV
    spec.rawSystemVoltageV = ctx.rawSystemVoltageV or spec.rawBatteryTerminalVoltageV

    local C = ADS_Config.ELECTRICAL or {}
    local batteryVAlpha = math.min((dt or 0) / ((C.BATTERY_VOLTAGE_TAU_MS or 300) + (dt or 0)), 1)
    local systemVAlpha = math.min((dt or 0) / ((C.SYSTEM_VOLTAGE_TAU_MS or 250) + (dt or 0)), 1)

    spec.batteryTerminalVoltageV = (spec.batteryTerminalVoltageV or spec.rawBatteryTerminalVoltageV)
        + batteryVAlpha * (spec.rawBatteryTerminalVoltageV - (spec.batteryTerminalVoltageV or spec.rawBatteryTerminalVoltageV))

    spec.systemVoltageV = (spec.systemVoltageV or spec.rawSystemVoltageV)
        + systemVAlpha * (spec.rawSystemVoltageV - (spec.systemVoltageV or spec.rawSystemVoltageV))

    dbg.soc = spec.batterySoc or 0
    dbg.chargeAh = spec.batteryChargeAh or 0
    dbg.capacityNominalAh = ctx.nominalCapacityAh or spec.batteryCapacityAh or 0
    dbg.capacityFactor = ctx.capF or 1
    dbg.capacityUsableAh = ctx.usableCapacityAh or ctx.capacityAh or 0
    dbg.capacityEffectiveAh = ctx.capacityAh or 0
    dbg.batteryHealth = ctx.batteryHealth or spec.batteryHealth or 0
    dbg.iNetRaw = ctx.iNetA or ((ctx.iAltAvail or 0) - (ctx.iLoads or 0))
    dbg.iNet = dbg.iNetRaw
    dbg.dAh = ctx.dAhTotal or (dbg.iNet * ((ctx.dtS or 0) / 3600))
    dbg.ocvV = spec.batteryOpenCircuitVoltageV or 0
    dbg.batteryTerminalV = spec.rawBatteryTerminalVoltageV or 0
    dbg.rawBatteryTerminalVoltageV = spec.rawBatteryTerminalVoltageV or 0
    dbg.batteryTerminalVoltageV = spec.batteryTerminalVoltageV or 0
    dbg.systemVoltageV = spec.rawSystemVoltageV or 0
    dbg.rawSystemVoltageV = spec.rawSystemVoltageV or 0
    dbg.systemVoltageVSmoothed = spec.systemVoltageV or 0

    if ctx.termLoadDropV ~= nil then dbg.termLoadDropV = ctx.termLoadDropV end
    if ctx.termChargeRiseV ~= nil then dbg.termChargeRiseV = ctx.termChargeRiseV end
    if ctx.termDischargeA ~= nil then dbg.termDischargeA = ctx.termDischargeA end
    if ctx.termChargeA ~= nil then dbg.termChargeA = ctx.termChargeA end
    if ctx.regulatedVoltageV ~= nil then dbg.regulatedVoltageV = ctx.regulatedVoltageV end
    if ctx.altDeficitA ~= nil then dbg.altDeficitA = ctx.altDeficitA end
    if ctx.altSagV ~= nil then dbg.altSagV = ctx.altSagV end
    if ctx.altRegulationHealth ~= nil then dbg.altRegulationHealth = ctx.altRegulationHealth end
    if ctx.altHealthDeficitMult ~= nil then dbg.altHealthDeficitMult = ctx.altHealthDeficitMult end
    if ctx.altChargeHeadroomV ~= nil then dbg.altChargeHeadroomV = ctx.altChargeHeadroomV end
end

local function solveExternalPowerConnection(consumerCtx, donorCtx, dtS)
    if consumerCtx == nil or donorCtx == nil then
        return consumerCtx, donorCtx, nil
    end

    local donorAltBeforeA = donorCtx.iAltAvail or 0
    local consumerAltBeforeA = consumerCtx.iAltAvail or 0
    local compositeCtx = buildCompositeBatteryContext(consumerCtx, donorCtx)
    if compositeCtx == nil then
        return consumerCtx, donorCtx, nil
    end

    local externalBatteryState = {
        soc = compositeCtx.soc,
        tempC = compositeCtx.tempC,
        health = compositeCtx.health
    }

    if donorCtx.isMotorStarted then
        donorCtx.iAltAvail = calculateAlternatorOutput(donorCtx.vehicle, donorCtx.isMotorStarted, donorCtx.iLoads, externalBatteryState) or 0
    end

    if consumerCtx.isMotorStarted then
        consumerCtx.iAltAvail = calculateAlternatorOutput(consumerCtx.vehicle, consumerCtx.isMotorStarted, consumerCtx.iLoads, externalBatteryState) or 0
    end

    local totalLoadsA = math.max((consumerCtx.iLoads or 0) + (donorCtx.iLoads or 0), 0)
    local totalAltA = math.max((consumerCtx.iAltAvail or 0) + (donorCtx.iAltAvail or 0), 0)
    local commonNetA = totalAltA - totalLoadsA
    local dAhCommon = commonNetA * dtS / 3600

    local totalConductance = math.max(
        (compositeCtx.conductanceConsumer or 0) + (compositeCtx.conductanceDonor or 0),
        0.0001
    )
    local consumerShare = (compositeCtx.conductanceConsumer or 0) / totalConductance
    local donorShare = (compositeCtx.conductanceDonor or 0) / totalConductance

    local dAhConsumerCommon = dAhCommon * consumerShare
    local dAhDonorCommon = dAhCommon * donorShare

    consumerCtx.chargeAh = math.clamp(
        (consumerCtx.chargeAh or 0) + dAhConsumerCommon,
        0,
        math.max(consumerCtx.capacityAh or 0.01, 0.01)
    )
    donorCtx.chargeAh = math.clamp(
        (donorCtx.chargeAh or 0) + dAhDonorCommon,
        0,
        math.max(donorCtx.capacityAh or 0.01, 0.01)
    )

    consumerCtx.soc = math.clamp(consumerCtx.chargeAh / math.max(consumerCtx.capacityAh or 0.01, 0.01), 0, 1)
    donorCtx.soc = math.clamp(donorCtx.chargeAh / math.max(donorCtx.capacityAh or 0.01, 0.01), 0, 1)
    consumerCtx.ocvV = getBatteryOpenCircuitVoltage(consumerCtx.soc)
    donorCtx.ocvV = getBatteryOpenCircuitVoltage(donorCtx.soc)

    compositeCtx = buildCompositeBatteryContext(consumerCtx, donorCtx)
    local balanceCurrentA = calculateBatteryBalanceCurrent(consumerCtx, donorCtx, compositeCtx)
    consumerCtx, donorCtx = applyBatteryBalanceCurrent(consumerCtx, donorCtx, balanceCurrentA, dtS)

    local dAhConsumerTotal = dAhConsumerCommon + (consumerCtx.balanceDeltaAh or 0)
    local dAhDonorTotal = dAhDonorCommon + (donorCtx.balanceDeltaAh or 0)

    local consumerBatteryA = math.abs(dAhConsumerTotal * 3600 / math.max(dtS, 0.0001))
    local donorBatteryA = math.abs(dAhDonorTotal * 3600 / math.max(dtS, 0.0001))

    AdvancedDamageSystem.updateBatteryTemperatureC(
        consumerCtx.vehicle,
        dtS,
        consumerCtx.environmentTemp,
        consumerCtx.spec.rawEngineTemperature or consumerCtx.spec.engineTemperature,
        consumerBatteryA,
        consumerCtx.rintF
    )
    AdvancedDamageSystem.updateBatteryTemperatureC(
        donorCtx.vehicle,
        dtS,
        donorCtx.environmentTemp,
        donorCtx.spec.rawEngineTemperature or donorCtx.spec.engineTemperature,
        donorBatteryA,
        donorCtx.rintF
    )

    local finalCompositeCtx = buildCompositeBatteryContext(consumerCtx, donorCtx)
    local networkMotorStarted = consumerCtx.isMotorStarted or donorCtx.isMotorStarted
    local networkIsCranking =
        (consumerCtx.spec.systems.electrical ~= nil and consumerCtx.spec.systems.electrical.isCranking == true)
        or (donorCtx.spec.systems.electrical ~= nil and donorCtx.spec.systems.electrical.isCranking == true)

    local batteryTerminalV, loadDropV, chargeRiseV, iDischargeA, iChargeA =
        getBatteryTerminalVoltage(finalCompositeCtx.ocvV, totalAltA, totalLoadsA, networkIsCranking, finalCompositeCtx.rIntOhm)

    local networkAlternatorHealth = math.max(
        tonumber(consumerCtx.spec.alternatorHealth) or 0,
        tonumber(donorCtx.spec.alternatorHealth) or 0
    )

    local rawSystemV, regulatedV, deficitA, sagV, regulationHealth, healthDeficitMult, chargeHeadroomV =
        getSystemVoltage(networkMotorStarted, batteryTerminalV, totalAltA, totalLoadsA, networkAlternatorHealth)

    consumerCtx.rawBatteryTerminalVoltageV = batteryTerminalV
    consumerCtx.rawSystemVoltageV = rawSystemV
    donorCtx.rawBatteryTerminalVoltageV = batteryTerminalV
    donorCtx.rawSystemVoltageV = rawSystemV

    consumerCtx.termLoadDropV = loadDropV
    consumerCtx.termChargeRiseV = chargeRiseV
    consumerCtx.termDischargeA = iDischargeA
    consumerCtx.termChargeA = iChargeA
    consumerCtx.regulatedVoltageV = regulatedV
    consumerCtx.altDeficitA = deficitA
    consumerCtx.altSagV = sagV
    consumerCtx.altRegulationHealth = regulationHealth
    consumerCtx.altHealthDeficitMult = healthDeficitMult
    consumerCtx.altChargeHeadroomV = chargeHeadroomV

    donorCtx.termLoadDropV = loadDropV
    donorCtx.termChargeRiseV = chargeRiseV
    donorCtx.termDischargeA = iDischargeA
    donorCtx.termChargeA = iChargeA
    donorCtx.regulatedVoltageV = regulatedV
    donorCtx.altDeficitA = deficitA
    donorCtx.altSagV = sagV
    donorCtx.altRegulationHealth = regulationHealth
    donorCtx.altHealthDeficitMult = healthDeficitMult
    donorCtx.altChargeHeadroomV = chargeHeadroomV

    consumerCtx.iNetA = totalAltA - totalLoadsA
    donorCtx.iNetA = totalAltA - totalLoadsA
    consumerCtx.dAhTotal = dAhConsumerTotal
    donorCtx.dAhTotal = dAhDonorTotal

    consumerCtx.externalPowerDebug = {
        connected = true,
        role = "consumer",
        partnerName = donorCtx.vehicle.getFullName ~= nil and donorCtx.vehicle:getFullName() or tostring(donorCtx.vehicle),
        compositeSoc = finalCompositeCtx.soc,
        compositeCapacityAh = finalCompositeCtx.capacityAh,
        compositeChargeAh = finalCompositeCtx.chargeAh,
        compositeRintOhm = finalCompositeCtx.rIntOhm,
        balanceCurrentA = balanceCurrentA,
        commonNetA = commonNetA,
        commonDeltaAh = dAhCommon,
        localDeltaAh = dAhConsumerTotal,
        altBeforeA = consumerAltBeforeA,
        altAfterA = consumerCtx.iAltAvail or 0
    }

    donorCtx.externalPowerDebug = {
        connected = true,
        role = "donor",
        partnerName = consumerCtx.vehicle.getFullName ~= nil and consumerCtx.vehicle:getFullName() or tostring(consumerCtx.vehicle),
        compositeSoc = finalCompositeCtx.soc,
        compositeCapacityAh = finalCompositeCtx.capacityAh,
        compositeChargeAh = finalCompositeCtx.chargeAh,
        compositeRintOhm = finalCompositeCtx.rIntOhm,
        balanceCurrentA = balanceCurrentA,
        commonNetA = commonNetA,
        commonDeltaAh = dAhCommon,
        localDeltaAh = dAhDonorTotal,
        altBeforeA = donorAltBeforeA,
        altAfterA = donorCtx.iAltAvail or 0
    }

    return consumerCtx, donorCtx, finalCompositeCtx
end

function AdvancedDamageSystem.rescaleBatteryChargeFromSoc(vehicle)
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        return
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    local tempC = tonumber(spec.batteryTempC) or 25
    local capF = 1.0

    if tempC < 25 then
        capF = math.clamp(1.0 - (25 - tempC) * 0.004, 0.55, 1.0)
    end

    local nominalCapacityAh = math.max(tonumber(spec.batteryCapacityAh) or 0, 1)
    local batteryHealth = math.max(tonumber(spec.batteryHealth) or 0, 0.0001)

    local usableCapacityAh = math.max(
        nominalCapacityAh * capF * ADS_Config.ELECTRICAL.BATTERY_USABLE_CAPACITY_FACTOR,
        0.01
    )

    local effectiveCapacityAh = math.max(usableCapacityAh * batteryHealth, 0.01)
    local soc = math.clamp(tonumber(spec.batterySoc) or 1.0, 0, 1)

    spec.batteryChargeAh = math.clamp(soc * effectiveCapacityAh, 0, effectiveCapacityAh)
end

function AdvancedDamageSystem:updateBatteryChargingModel(dt)
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil then
        return
    end

    local dtS = math.max((dt or 0) / 1000, 0)
    if dtS <= 0 then
        return
    end

    ensureBatteryDebugData(spec)

    --- check for external connection
    local solveStamp = (g_currentMission ~= nil and g_currentMission.time) or g_time or 0
    if spec._externalPowerSolveStamp == solveStamp then
        return
    end

    resetExternalPowerDebug(spec)

    local connectionVehicle = normalizeExternalPowerConnection(spec.externalPowerConnection)
    local connectionSpec = connectionVehicle ~= nil and connectionVehicle.spec_AdvancedDamageSystem or nil

    if connectionVehicle ~= nil
        and connectionVehicle ~= self
        and connectionSpec ~= nil
        and (connectionVehicle.rootNode == nil or entityExists(connectionVehicle.rootNode)) then

        local selfSpeed = math.abs(tonumber(self.getLastSpeed ~= nil and self:getLastSpeed() or 0) or 0)
        local connectionSpeed = math.abs(tonumber(connectionVehicle.getLastSpeed ~= nil and connectionVehicle:getLastSpeed() or 0) or 0)
        if self.isServer and (selfSpeed > 1 or connectionSpeed > 1) then
            self:clearExternalPowerConnection(connectionVehicle)
            connectionVehicle = nil
            connectionSpec = nil
        end
    end

    if connectionVehicle ~= nil
        and connectionVehicle ~= self
        and connectionSpec ~= nil
        and (connectionVehicle.rootNode == nil or entityExists(connectionVehicle.rootNode)) then

        ensureBatteryDebugData(connectionSpec)
        resetExternalPowerDebug(connectionSpec)

        local selfCtx = buildBatteryContext(self, dtS)
        local connectionCtx = buildBatteryContext(connectionVehicle, dtS)

        if selfCtx ~= nil and connectionCtx ~= nil then
            local consumerCtx, donorCtx = orderExternalPowerContexts(selfCtx, connectionCtx)
            consumerCtx, donorCtx = solveExternalPowerConnection(consumerCtx, donorCtx, dtS)

            if consumerCtx ~= nil and donorCtx ~= nil then
                commitBatteryContext(consumerCtx.vehicle, consumerCtx, dt)
                commitBatteryContext(donorCtx.vehicle, donorCtx, dt)

                local selfIsConsumer = consumerCtx.vehicle == self
                local selfExt = selfIsConsumer and consumerCtx.externalPowerDebug or donorCtx.externalPowerDebug
                local connectionExt = selfIsConsumer and donorCtx.externalPowerDebug or consumerCtx.externalPowerDebug

                local selfDbg = ensureBatteryDebugData(spec)
                local connectionDbg = ensureBatteryDebugData(connectionSpec)

                if selfExt ~= nil then
                    selfDbg.externalConnected = 1
                    selfDbg.externalRole = selfExt.role or "-"
                    selfDbg.externalPartnerName = selfExt.partnerName or "-"
                    selfDbg.externalCompositeSoc = selfExt.compositeSoc or 0
                    selfDbg.externalCompositeCapacityAh = selfExt.compositeCapacityAh or 0
                    selfDbg.externalCompositeChargeAh = selfExt.compositeChargeAh or 0
                    selfDbg.externalCompositeRintOhm = selfExt.compositeRintOhm or 0
                    selfDbg.externalBalanceCurrentA = selfExt.balanceCurrentA or 0
                    selfDbg.externalCommonNetA = selfExt.commonNetA or 0
                    selfDbg.externalCommonDeltaAh = selfExt.commonDeltaAh or 0
                    selfDbg.externalLocalDeltaAh = selfExt.localDeltaAh or 0
                    selfDbg.externalAltBeforeA = selfExt.altBeforeA or 0
                    selfDbg.externalAltAfterA = selfExt.altAfterA or 0
                end

                if connectionExt ~= nil then
                    connectionDbg.externalConnected = 1
                    connectionDbg.externalRole = connectionExt.role or "-"
                    connectionDbg.externalPartnerName = connectionExt.partnerName or "-"
                    connectionDbg.externalCompositeSoc = connectionExt.compositeSoc or 0
                    connectionDbg.externalCompositeCapacityAh = connectionExt.compositeCapacityAh or 0
                    connectionDbg.externalCompositeChargeAh = connectionExt.compositeChargeAh or 0
                    connectionDbg.externalCompositeRintOhm = connectionExt.compositeRintOhm or 0
                    connectionDbg.externalBalanceCurrentA = connectionExt.balanceCurrentA or 0
                    connectionDbg.externalCommonNetA = connectionExt.commonNetA or 0
                    connectionDbg.externalCommonDeltaAh = connectionExt.commonDeltaAh or 0
                    connectionDbg.externalLocalDeltaAh = connectionExt.localDeltaAh or 0
                    connectionDbg.externalAltBeforeA = connectionExt.altBeforeA or 0
                    connectionDbg.externalAltAfterA = connectionExt.altAfterA or 0
                end

                spec._externalPowerSolveStamp = solveStamp
                connectionSpec._externalPowerSolveStamp = solveStamp
                return
            end
        end
    end

    local ctx = buildBatteryContext(self, dtS)
    if ctx == nil then
        return
    end

    local iBatteryA = math.abs((ctx.iAltAvail or 0) - (ctx.iLoads or 0))
    AdvancedDamageSystem.updateBatteryTemperatureC(
        self,
        dtS,
        ctx.environmentTemp,
        spec.rawEngineTemperature or spec.engineTemperature,
        iBatteryA,
        ctx.rintF
    )

    local dAh = ((ctx.iAltAvail or 0) - (ctx.iLoads or 0)) * dtS / 3600
    ctx.chargeAh = math.clamp((ctx.chargeAh or 0) + dAh, 0, math.max(ctx.capacityAh or 0.01, 0.01))
    ctx.soc = math.clamp(ctx.chargeAh / math.max(ctx.capacityAh or 0.01, 0.01), 0, 1)
    ctx.ocvV = getBatteryOpenCircuitVoltage(ctx.soc)

    local cfg = ADS_Config.ELECTRICAL or {}
    local health = math.clamp(spec.batteryHealth or 1, 0.0001, 1.0)
    local rRef = math.max(cfg.RINT_REF_OHM or 0.005, 0.0001)
    local maxHealthRintMult = math.max(cfg.BATTERY_HEALTH_RINT_MAX_MULT or 3.0, 1.0)
    local healthRintMult = 1 + (1 - health) * (maxHealthRintMult - 1)
    local rIntOhm = rRef * (ctx.rintF or 1) * healthRintMult

    local isCranking = spec.systems.electrical ~= nil
        and spec.systems.electrical.isCranking ~= nil
        and spec.systems.electrical.isCranking

    local batteryTerminalV, loadDropV, chargeRiseV, iDischargeA, iChargeA =
        getBatteryTerminalVoltage(ctx.ocvV, ctx.iAltAvail, ctx.iLoads, isCranking, rIntOhm)

    local alternatorHealth = 1.0
    if spec.systems ~= nil and spec.systems.electrical ~= nil then
        alternatorHealth = math.clamp(spec.alternatorHealth or 1.0, 0.0, 1.0)
    end

    local rawSystemV, regulatedV, deficitA, sagV, regulationHealth, healthDeficitMult, chargeHeadroomV =
        getSystemVoltage(ctx.isMotorStarted, batteryTerminalV, ctx.iAltAvail, ctx.iLoads, alternatorHealth)

    ctx.rawBatteryTerminalVoltageV = batteryTerminalV
    ctx.rawSystemVoltageV = rawSystemV
    ctx.termLoadDropV = loadDropV
    ctx.termChargeRiseV = chargeRiseV
    ctx.termDischargeA = iDischargeA
    ctx.termChargeA = iChargeA
    ctx.regulatedVoltageV = regulatedV
    ctx.altDeficitA = deficitA
    ctx.altSagV = sagV
    ctx.altRegulationHealth = regulationHealth
    ctx.altHealthDeficitMult = healthDeficitMult
    ctx.altChargeHeadroomV = chargeHeadroomV
    ctx.iNetA = (ctx.iAltAvail or 0) - (ctx.iLoads or 0)
    ctx.dAhTotal = dAh

    commitBatteryContext(self, ctx, dt)

    local dbg = ensureBatteryDebugData(spec)
    dbg.rIntHealthFactor = healthRintMult
    dbg.termIsCranking = isCranking and 1 or 0
end

function AdvancedDamageSystem.isValidPowerPair(vehicleA, vehicleB)
    if vehicleA == nil or vehicleB == nil or vehicleA == vehicleB then
        return false, ''
    end

    if vehicleA.getRootVehicle ~= nil then
        vehicleA = vehicleA:getRootVehicle()
    end

    if vehicleB.getRootVehicle ~= nil then
        vehicleB = vehicleB:getRootVehicle()
    end

    if vehicleA == nil or vehicleB == nil or vehicleA == vehicleB then
        return false, 'SAME'
    end

    if vehicleA.spec_AdvancedDamageSystem == nil or vehicleB.spec_AdvancedDamageSystem == nil then
        return false, 'NO_ADS'
    end

    local nodeA = vehicleA.rootNode
    if nodeA == nil and vehicleA.components ~= nil and vehicleA.components[1] ~= nil then
        nodeA = vehicleA.components[1].node
    end

    local nodeB = vehicleB.rootNode
    if nodeB == nil and vehicleB.components ~= nil and vehicleB.components[1] ~= nil then
        nodeB = vehicleB.components[1].node
    end

    if nodeA == nil or nodeB == nil then
        return false, ''
    end

    local ax, ay, az = getWorldTranslation(nodeA)
    local bx, by, bz = getWorldTranslation(nodeB)
    local dx = bx - ax
    local dy = by - ay
    local dz = bz - az
    
    local fieldCare = ADS_Config ~= nil and ADS_Config.FIELD_CARE or nil
    local maxConnectionDistance = (fieldCare ~= nil and fieldCare.JUMPER_CABLES_MAX_CONNECTION_DISTANCE) or 12.0

    if MathUtil.vector3Length(dx, dy, dz) > maxConnectionDistance then
        return false, 'TOO_FAR'
    end
    
    return true
end

function AdvancedDamageSystem:establishExternalPowerConnection(externalConnection)
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil or not self.isServer then
        return
    end

    local otherVehicle = externalConnection
    if otherVehicle ~= nil and otherVehicle.getRootVehicle ~= nil then
        otherVehicle = otherVehicle:getRootVehicle()
    end

    local otherSpec = otherVehicle ~= nil and otherVehicle.spec_AdvancedDamageSystem or nil
    local isValid = AdvancedDamageSystem.isValidPowerPair(self, otherVehicle)

    if isValid then
        spec.externalPowerConnection = otherVehicle
        if otherSpec ~= nil then
            otherSpec.externalPowerConnection = self
        end
        return true
    else
        spec.externalPowerConnection = nil
        if otherSpec ~= nil and otherSpec.externalPowerConnection == self then
            otherSpec.externalPowerConnection = nil
        end
        return false
    end
end

function AdvancedDamageSystem:clearExternalPowerConnection(otherVehicle)
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil or not self.isServer then
        return false
    end

    local normalizedOther = otherVehicle
    if normalizedOther ~= nil and normalizedOther.getRootVehicle ~= nil then
        normalizedOther = normalizedOther:getRootVehicle()
    end

    local currentConnection = spec.externalPowerConnection
    if type(currentConnection) == "table" and currentConnection.object ~= nil then
        currentConnection = currentConnection.object
    end

    if normalizedOther == nil then
        normalizedOther = currentConnection
    end

    spec.externalPowerConnection = nil

    local otherSpec = normalizedOther ~= nil and normalizedOther.spec_AdvancedDamageSystem or nil
    if otherSpec ~= nil then
        local reverseConnection = otherSpec.externalPowerConnection
        if type(reverseConnection) == "table" and reverseConnection.object ~= nil then
            reverseConnection = reverseConnection.object
        end

        if reverseConnection == self then
            otherSpec.externalPowerConnection = nil
        end
    end

    return true
end

-- ==========================================================
--                       THERMAL
-- ==========================================================

function AdvancedDamageSystem:updateThermalSystems(dt)
    local motor = self:getMotor()
    if not motor then return end

    local spec = self.spec_AdvancedDamageSystem
    local vehicleHaveCVT = hasCVTTransmission(self)
    
    local isMotorStarted = self:getIsMotorStarted()
    local motorLoad = math.max(self:getMotorLoadPercentage(), 0.0)
    local motorRpm = self:getMotorRpmPercentage()
    local speed = self:getLastSpeed()
    local dirt = spec.radiatorClogging
    local eviromentTemp = g_currentMission.environment.weather.forecast:getCurrentWeather().temperature
    
    local speedCooling = 0
    local C = ADS_Config.THERMAL
    if speed > C.SPEED_COOLING_MIN_SPEED then
        local speedRatio = math.min((speed - C.SPEED_COOLING_MIN_SPEED) / (C.SPEED_COOLING_MAX_SPEED - C.SPEED_COOLING_MIN_SPEED), 1.0)
        speedCooling = C.SPEED_COOLING_MAX_EFFECT * speedRatio
    end

    if (spec.engineTemperature or -99) < eviromentTemp or (g_sleepManager.isSleeping and not isMotorStarted) then spec.engineTemperature = eviromentTemp end
    if (spec.rawEngineTemperature or -99) < eviromentTemp or (g_sleepManager.isSleeping and not isMotorStarted) then spec.rawEngineTemperature = eviromentTemp end
    if vehicleHaveCVT then
        if (spec.transmissionTemperature or -99) < eviromentTemp or (g_sleepManager.isSleeping and not isMotorStarted) then spec.transmissionTemperature = eviromentTemp end
        if (spec.rawTransmissionTemperature or -99) < eviromentTemp or (g_sleepManager.isSleeping and not isMotorStarted) then spec.rawTransmissionTemperature = eviromentTemp end
    end

    if not spec.isElectricVehicle then 
        self:updateEngineThermalModel(dt, spec, isMotorStarted, motorLoad, speedCooling, eviromentTemp, dirt)
    end
    
    if vehicleHaveCVT then
        if hasCVTAddon(self) then
            spec.rawTransmissionTemperature = self.spec_motorized.motorTemperature.value
        else 
            self:updateTransmissionThermalModel(dt, spec, isMotorStarted, motorLoad, motorRpm, speed, speedCooling, eviromentTemp, dirt)
        end
    else
        spec.rawTransmissionTemperature = -99
    end
end

function AdvancedDamageSystem:updateEngineThermalModel(dt, spec, isMotorStarted, motorLoad, speedCooling, eviromentTemp, dirt)
    local C = ADS_Config.THERMAL
    local heat, cooling = 0, 0
    local radiatorCooling, convectionCooling = 0, 0
    
    local deltaTemp = math.max(0, spec.rawEngineTemperature - eviromentTemp)
    convectionCooling = C.CONVECTION_FACTOR * (deltaTemp ^ C.DELTATEMP_FACTOR_DEGREE)

    if isMotorStarted then
        local engineMaxHeat = C.ENGINE_MAX_HEAT + spec.extraEngineHeat
        heat = C.ENGINE_MIN_HEAT + motorLoad * (engineMaxHeat - C.ENGINE_MIN_HEAT)
        
        local brokenFanModifier = 1.0
        if spec.fanClutchHealth < 1.0 then
            local speed = self:getLastSpeed()
            if speed < C.SPEED_COOLING_MIN_SPEED then
                local speedK = 1 - speed / C.SPEED_COOLING_MIN_SPEED
                brokenFanModifier = 1 - math.min(speedK * (1 - spec.fanClutchHealth), 0.5)
            end
        end
        local dirtRadiatorMaxCooling = (C.ENGINE_RADIATOR_MAX_COOLING * spec.radiatorHealth) * (1 - C.MAX_DIRT_INFLUENCE * (dirt ^ 4)) * brokenFanModifier
        radiatorCooling = math.max(dirtRadiatorMaxCooling * spec.thermostatState, C.ENGINE_RADIATOR_MIN_COOLING) * (deltaTemp ^ C.DELTATEMP_FACTOR_DEGREE)
        cooling = (radiatorCooling + convectionCooling) * (1 + speedCooling)
    else
        if (spec.engineTemperature or -99) < C.COOLING_SLOWDOWN_THRESHOLD then
            cooling = convectionCooling / C.COOLING_SLOWDOWN_POWER
        else
            cooling = convectionCooling
        end
    end

    spec.rawEngineTemperature = spec.rawEngineTemperature + (heat - cooling) * (dt / 1000) * C.TEMPERATURE_CHANGE_SPEED
    spec.rawEngineTemperature = math.max(spec.rawEngineTemperature, eviromentTemp)
    
    local dbg = spec.debugData.engineTemp

    local rawEngineTemp = spec.rawEngineTemperature or spec.engineTemperature or -99
    if isMotorStarted and rawEngineTemp > C.ENGINE_THERMOSTAT_MIN_TEMP then
        spec.thermostatState = AdvancedDamageSystem.getNewTermostatState(dt, rawEngineTemp, C.PID_TARGET_TEMP, spec.engTermPID, spec.thermostatHealth, spec.year, spec.thermostatStuckedPosition, dbg)
    else
        spec.thermostatState = 0.0
        spec.engTermPID.integral = 0
        spec.engTermPID.lastError = 0
        
        dbg.kp = 0
        dbg.stiction = 0
        dbg.waxSpeed = 0
    end

    dbg.totalHeat = heat
    dbg.totalCooling = cooling
    dbg.radiatorCooling = radiatorCooling
    dbg.speedCooling = speedCooling
    dbg.convectionCooling = convectionCooling

    return dbg 
end

function AdvancedDamageSystem:updateTransmissionThermalModel(dt, spec, isMotorStarted, motorLoad, motorRpm, speed, speedCooling, eviromentTemp, dirt)
    local C = ADS_Config.THERMAL
    local heat, cooling = 0, 0
    local radiatorCooling, convectionCooling = 0, 0
    local motor = self:getMotor()
    
    local dbg = spec.debugData.transmissionTemp

    local loadFactor = motorLoad - motor.motorExternalTorque / motor.peakMotorTorque
    local pullFactor = 1.0
    local slipFactor = 1.0
    local wheelSlipFactor = 1.0
    local accFactor = 1.0
    local speedLimit = math.huge
    local cvtSlipActive = false
    local cvtSlipLocked = false
    
    local deltaTemp = math.max(0, spec.rawTransmissionTemperature - eviromentTemp)
    convectionCooling = C.CONVECTION_FACTOR * (deltaTemp ^ C.DELTATEMP_FACTOR_DEGREE)

    if isMotorStarted then
        if (self:getAccelerationAxis() > 0 or self:getCruiseControlAxis() > 0) then
            accFactor = math.max(5 * motorRpm * math.clamp(motor.motorRotAccelerationSmoothed / motor.motorRotationAccelerationLimit, 0.0, 1.0), 1.0)

            if self.spec_attacherJoints and self.spec_attacherJoints.attachedImplements and next(self.spec_attacherJoints.attachedImplements) ~= nil then
                for _, implementData in pairs(self.spec_attacherJoints.attachedImplements) do
                    if implementData.object ~= nil then
                        local implement = implementData.object
                        local currentSpeedLimit = implement.speedLimit
                        if currentSpeedLimit ~= nil and implement:getIsLowered() then
                            if currentSpeedLimit < speedLimit then
                                speedLimit = currentSpeedLimit
                            end
                        end
                    end
                end
            end
        end

        if speedLimit ~= math.huge then 
            if self:getCruiseControlState() ~= 0 then
                speedLimit = math.min(self:getCruiseControlSpeed(), speedLimit)
            end
            pullFactor = pullFactor + (1 - math.clamp((speed / speedLimit), 0.0, 1.0)) / 2
        end

        -- slip effect from breakdown
        if spec.activeEffects.CVT_SLIP_EFFECT ~= nil and spec.activeEffects.CVT_SLIP_EFFECT.value > 0 then
            cvtSlipActive = true
            local curSpeed = math.min(motor.vehicle:getLastSpeed() / (motor:getMaximumForwardSpeed() * 3.6), 1.0)
            local minGearRatio, maxGearRatio = motor:getMinMaxGearRatio()
            local isSliping = (1 - minGearRatio / math.max(motor.gearRatio, 0.01) <= 0.02) and curSpeed < 0.8
            if isSliping then
                cvtSlipLocked = true
                slipFactor = slipFactor * 2.0
            end
        end

        -- wheel slip
        if spec.systems.transmission and spec.systems.transmission.wheelSlipIntensity and spec.systems.transmission.wheelSlipIntensity > 0.05 then
            wheelSlipFactor = wheelSlipFactor + (spec.systems.transmission.wheelSlipIntensity or 0)
        end
        
        local maxHeat = C.TRANS_MAX_HEAT + spec.extraTransmissionHeat
        heat = C.TRANS_MIN_HEAT + (maxHeat - C.TRANS_MIN_HEAT) * loadFactor * slipFactor * accFactor * wheelSlipFactor * pullFactor 
        local dirtRadiatorMaxCooling = C.TRANS_RADIATOR_MAX_COOLING * (1 - C.MAX_DIRT_INFLUENCE * (dirt ^ 4))
        
        radiatorCooling = math.max(dirtRadiatorMaxCooling * spec.transmissionThermostatState, C.TRANS_RADIATOR_MIN_COOLING) * (deltaTemp ^ C.DELTATEMP_FACTOR_DEGREE)
        cooling = (radiatorCooling +  convectionCooling) * (1 + speedCooling)
    else
        if (spec.engineTemperature or -99) < C.COOLING_SLOWDOWN_THRESHOLD then
            cooling = convectionCooling / C.COOLING_SLOWDOWN_POWER
        else
            cooling = convectionCooling
        end
    end

    spec.rawTransmissionTemperature = spec.rawTransmissionTemperature + (heat - cooling) * (dt / 1000) * C.TEMPERATURE_CHANGE_SPEED
    spec.rawTransmissionTemperature = math.max(spec.rawTransmissionTemperature, eviromentTemp)

    local rawTransmissionTemp = spec.rawTransmissionTemperature or spec.transmissionTemperature or -99
    if isMotorStarted and rawTransmissionTemp > C.TRANS_THERMOSTAT_MIN_TEMP then
        spec.transmissionThermostatState = AdvancedDamageSystem.getNewTermostatState(dt, rawTransmissionTemp, C.TRANS_PID_TARGET_TEMP, spec.transTermPID, spec.transmissionThermostatHealth, spec.year, spec.transmissionThermostatStuckedPosition, dbg)
    else
        spec.transmissionThermostatState = 0.0
        spec.transTermPID.integral = 0
        spec.transTermPID.lastError = 0
        
        if dbg then
            dbg.kp = 0
            dbg.stiction = 0
            dbg.waxSpeed = 0
        end
    end
    
    if dbg then
        dbg.totalHeat = heat
        dbg.totalCooling = cooling
        dbg.radiatorCooling = radiatorCooling
        dbg.speedCooling = speedCooling
        dbg.convectionCooling = convectionCooling
        dbg.loadFactor = loadFactor
        dbg.slipFactor = slipFactor
        dbg.pullFactor = pullFactor
        dbg.wheelSlipFactor = wheelSlipFactor
        dbg.accFactor = accFactor
        dbg.speedLimit = speedLimit ~= math.huge and speedLimit or 0
        dbg.cvtSlipActive = cvtSlipActive and 1 or 0
        dbg.cvtSlipLocked = cvtSlipLocked and 1 or 0
        dbg.extraTransmissionHeat = spec.extraTransmissionHeat or 0
    end

    return dbg
end

function AdvancedDamageSystem.getNewTermostatState(dt, currentTemp, targetTemp, pidData, thermostatHealth, year, stuckedPosition, debugData)

    if stuckedPosition ~= nil then
        return stuckedPosition
    end
    
    local C = ADS_Config.THERMAL
    local dtSeconds = math.max(dt / 1000, 0.001)

    local isMechanical = year < C.THERMOSTAT_TYPE_YEAR_DIVIDER
    local targetPos = 0
    local maxOpening = 1.0
    
    if isMechanical then
        local startOpenTemp = targetTemp - 7
        local fullOpenTemp = targetTemp + 5 
        targetPos = (currentTemp - startOpenTemp) / (fullOpenTemp - startOpenTemp)
        pidData.integral = 0
        pidData.lastError = 0
        if debugData then debugData.kp = 0 end
    else
        local pidKpYearFactor = (year - C.THERMOSTAT_TYPE_YEAR_DIVIDER) / (C.ELECTRONIC_THERMOSTAT_MAX_YEAR - C.THERMOSTAT_TYPE_YEAR_DIVIDER)
        local pid_kp = math.clamp(C.PID_KP_MIN + (C.PID_KP_MAX - C.PID_KP_MIN) * pidKpYearFactor, C.PID_KP_MIN, C.PID_KP_MAX)
        local errorTemp = currentTemp - targetTemp
        
        local derivative = 0
        if dtSeconds > 0.001 then
            derivative = (errorTemp - (pidData.lastError or 0)) / dtSeconds
        end
        
        local newIntegral = (pidData.integral or 0) + errorTemp * dtSeconds
        local controlSignal = pid_kp * errorTemp + C.PID_KI * newIntegral + C.PID_KD * derivative
        
        if (controlSignal >= 0 and controlSignal <= maxOpening) or 
           (controlSignal < 0 and errorTemp > 0) or 
           (controlSignal > maxOpening and errorTemp < 0) then
            
            pidData.integral = math.clamp(newIntegral, -C.PID_MAX_INTEGRAL, C.PID_MAX_INTEGRAL)
        end
        
        targetPos = pid_kp * errorTemp + C.PID_KI * pidData.integral + C.PID_KD * derivative
        pidData.lastError = errorTemp
        
        if debugData then debugData.kp = pid_kp end
    end

    targetPos = math.clamp(targetPos, 0.0, maxOpening)

    local baseSpeed = isMechanical and C.MECHANIC_THERMOSTAT_MIN_WAX_SPEED or C.ELECTRONIC_THERMOSTAT_MIN_WAX_SPEED
    local yearFactor = isMechanical and (year - 1950) * 0.0005 or (year - 2000) * 0.0016
    
    local waxSpeed = math.clamp(baseSpeed + yearFactor, C.MECHANIC_THERMOSTAT_MIN_WAX_SPEED, C.ELECTRONIC_THERMOSTAT_MAX_WAX_SPEED)
    waxSpeed = waxSpeed * math.max(0.2, thermostatHealth)

    local currentMechPos = pidData.mechPos or 0.0 
    local delta = targetPos - currentMechPos
    local maxMove = waxSpeed * dtSeconds
        
    if math.abs(delta) > maxMove then
        delta = maxMove * (delta > 0 and 1 or -1)
    end
        
    local newPos = math.clamp(currentMechPos + delta, 0.0, maxOpening)
    pidData.mechPos = newPos

    local baseStiction = isMechanical and (0.1 - (year - 1950) * 0.0016) or (0.05 - (year - 2000) * 0.0016)
    local stiction = math.clamp(baseStiction, 0.01, 0.1)
    
    stiction = stiction * (2 - math.max(0.5, thermostatHealth))
    
    if debugData then
        debugData.stiction = stiction
        debugData.waxSpeed = waxSpeed
    end

    return math.clamp(math.floor(newPos / stiction) * stiction, 0.0, maxOpening)
end

function AdvancedDamageSystem:getSmoothedTemperature(dt)
    local C = ADS_Config.THERMAL
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil then
        return
    end

    local alpha = dt / (C.TAU + dt)
    local eviromentTemp = g_currentMission.environment.weather.forecast:getCurrentWeather().temperature or 0
    local motor = self:getMotor()
    local vehicleHaveCVT = hasCVTTransmission(self)
    local snapThreshold = 5.0

    local rawEngineTemperature = spec.rawEngineTemperature or eviromentTemp
    local currentEngineTemperature = spec.engineTemperature or rawEngineTemperature
    if math.abs(rawEngineTemperature - currentEngineTemperature) >= snapThreshold then
        spec.engineTemperature = math.max(rawEngineTemperature, eviromentTemp)
    else
        spec.engineTemperature = math.max(currentEngineTemperature + alpha * (rawEngineTemperature - currentEngineTemperature), eviromentTemp)
    end

    if vehicleHaveCVT then
        local rawTransmissionTemperature = spec.rawTransmissionTemperature or eviromentTemp
        local currentTransmissionTemperature = spec.transmissionTemperature or rawTransmissionTemperature
        if math.abs(rawTransmissionTemperature - currentTransmissionTemperature) >= snapThreshold then
            spec.transmissionTemperature = math.max(rawTransmissionTemperature, eviromentTemp)
        else
            spec.transmissionTemperature = math.max(currentTransmissionTemperature + alpha * (rawTransmissionTemperature - currentTransmissionTemperature), eviromentTemp)
        end
    end
end

function AdvancedDamageSystem.updateMotorTemperature(self, superFunc, dt)
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil or spec.isExcludedVehicle or hasCVTAddon(self) then
        return superFunc(self, dt)
    else
        local spec_motorized = self.spec_motorized
        if spec_motorized ~= nil then
            self.spec_motorized.motorTemperature.value = spec.engineTemperature or 0
        end
    end
end

-- ==========================================================
--                  FIELD CARE MECHANICS
-- ==========================================================

local function getIsThereDebris(vehicle)
    local cutterArea = 0

    if vehicle == nil or not vehicle:getIsOnField() or vehicle:getLastSpeed() < 0.5 then
        return false
    end

    if vehicle.getIsTurnedOn ~= nil and not vehicle:getIsTurnedOn() then
        return false
    end

    if vehicle.spec_attacherJoints ~= nil and vehicle.spec_attacherJoints.attachedImplements ~= nil then
        for _, implementData in pairs(vehicle.spec_attacherJoints.attachedImplements) do
            local implement = implementData.object

            if implement ~= nil and implement.spec_cutter ~= nil and implement.spec_cutter.workAreaParameters ~= nil then
                cutterArea = math.max(cutterArea, implement.spec_cutter.workAreaParameters.lastArea or 0)
            end
        end
    end

    if cutterArea <= 0 and vehicle.spec_cutter ~= nil and vehicle.spec_cutter.workAreaParameters ~= nil then
        cutterArea = vehicle.spec_cutter.workAreaParameters.lastArea or 0
    end

    return cutterArea > 0
end

local function getIsThereDust(vehicle)
    if vehicle == nil or not vehicle:getIsOnField() or vehicle:getLastSpeed() < 0.5 then
        return false
    end

    if vehicle.spec_attacherJoints and vehicle.spec_attacherJoints.attachedImplements and next(vehicle.spec_attacherJoints.attachedImplements) ~= nil then
        for _, implementData in pairs(vehicle.spec_attacherJoints.attachedImplements) do
            if implementData.object ~= nil then
                local implement = implementData.object
                if implement:getIsLowered() then
                    return true
                end
            end
        end
    end
    return false
end

function AdvancedDamageSystem:updateRadiatorClogging(dt)
    local C = ADS_Config.FIELD_CARE
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil then
        return
    end

    if not spec.isVehicleNeedBlowOut then
        spec.radiatorClogging = 0
        return
    end

    if spec.debugData == nil then
        spec.debugData = {}
    end
    if spec.debugData.radiator == nil then
        spec.debugData.radiator = {
            fieldFactor = 1.0,
            dustFactor = 0.0,
            debrisFactor = 0.0,
            wetness = 0,
            wetnessFactor = 1.0,
            baseWetnessFactor = 1.0,
            isOnField = false,
            hasDust = false,
            hasDebris = false,
            totalMultiplier = 0.0
        }
    end
    local dbg = spec.debugData.radiator

    local dirtLevel = self:getDirtAmount()
    local lastSpeed = self:getLastSpeed()
    local washableSpec = self.spec_washable
    local weather = g_currentMission ~= nil and g_currentMission.environment ~= nil and g_currentMission.environment.weather or nil
    local wetness = weather ~= nil and weather:getGroundWetness() or 0
    local baseWetnessFactor = math.max(1 - wetness, 0)
    local wetnessFactor = math.max(baseWetnessFactor ^ 3, 0)
    local isOnField = self:getIsOnField()
    local hasDust = getIsThereDust(self)
    local hasDebris = getIsThereDebris(self)
    local fieldFactor = 0.5
    local dustFactor = hasDust and 1.0 or 0.0
    local debrisFactor = hasDebris and 2.0 or 0.0

    if washableSpec ~= nil then
        fieldFactor = isOnField and (washableSpec.fieldMultiplier or 1.0) or 0.5
    end

    dbg.fieldFactor = fieldFactor
    dbg.dustFactor = dustFactor
    dbg.debrisFactor = debrisFactor
    dbg.wetness = wetness
    dbg.wetnessFactor = wetnessFactor
    dbg.baseWetnessFactor = baseWetnessFactor
    dbg.isOnField = isOnField
    dbg.hasDust = hasDust
    dbg.hasDebris = hasDebris
    dbg.totalMultiplier = 0.0

    if lastSpeed > 0.5 and spec.radiatorClogging < dirtLevel then
        if washableSpec == nil then
            return
        end

        local dirtDuration = ((washableSpec.dirtDuration or 0) / 4) * (ADS_Config.CORE.BASE_SERVICE_WEAR * 10)
        local totalMultiplier = wetnessFactor * (fieldFactor + dustFactor + debrisFactor) * C.CLOGGING_SPEED
        dbg.totalMultiplier = totalMultiplier

        local change = dirtDuration * totalMultiplier * dt
        spec.radiatorClogging = math.min(spec.radiatorClogging + change, dirtLevel)
    else
        if spec.radiatorClogging > dirtLevel then
            spec.radiatorClogging = dirtLevel
        end
    end
end

function AdvancedDamageSystem:updateAirIntakeClogging(dt)
    local C = ADS_Config.FIELD_CARE
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil then
        return
    end

    if not spec.isVehicleNeedBlowOut then
        spec.airIntakeClogging = 0
        return
    end

    if spec.debugData == nil then
        spec.debugData = {}
    end
    if spec.debugData.airIntake == nil then
        spec.debugData.airIntake = {
            fieldFactor = 1.0,
            dustFactor = 0.0,
            debrisFactor = 0.0,
            wetness = 0,
            wetnessFactor = 1.0,
            baseWetnessFactor = 1.0,
            isOnField = false,
            hasDust = false,
            hasDebris = false,
            totalMultiplier = 0.0
        }
    end
    local dbg = spec.debugData.airIntake

    local dirtLevel = self:getDirtAmount()
    local lastSpeed = self:getLastSpeed()
    local washableSpec = self.spec_washable
    local weather = g_currentMission ~= nil and g_currentMission.environment ~= nil and g_currentMission.environment.weather or nil
    local wetness = weather ~= nil and weather:getGroundWetness() or 0
    local baseWetnessFactor = math.max(1 - wetness, 0)
    local wetnessFactor = baseWetnessFactor
    local isOnField = self:getIsOnField()
    local hasDust = getIsThereDust(self)
    local hasDebris = getIsThereDebris(self)
    local fieldFactor = 1.0
    local dustFactor = hasDust and 2.0 or 0.0
    local debrisFactor = hasDebris and 1.0 or 0.0

    if washableSpec ~= nil then
        fieldFactor = isOnField and (washableSpec.fieldMultiplier or 2.0) or 1.0
    end

    dbg.fieldFactor = fieldFactor
    dbg.dustFactor = dustFactor
    dbg.debrisFactor = debrisFactor
    dbg.wetness = wetness
    dbg.wetnessFactor = wetnessFactor
    dbg.baseWetnessFactor = baseWetnessFactor
    dbg.isOnField = isOnField
    dbg.hasDust = hasDust
    dbg.hasDebris = hasDebris
    dbg.totalMultiplier = 0.0

    if lastSpeed > 0.5 and spec.airIntakeClogging < dirtLevel then
        if washableSpec == nil then
            return
        end
        
        local dirtDuration = ((washableSpec.dirtDuration or 0) / 4) * (ADS_Config.CORE.BASE_SERVICE_WEAR * 10)
        local totalMultiplier = wetnessFactor * (fieldFactor + dustFactor + debrisFactor) * C.CLOGGING_SPEED
        dbg.totalMultiplier = totalMultiplier

        local change = dirtDuration * totalMultiplier * dt
        spec.airIntakeClogging = math.min(spec.airIntakeClogging + change, dirtLevel)
    else
        if spec.airIntakeClogging > dirtLevel then
            spec.airIntakeClogging = dirtLevel
        end
    end
end

function AdvancedDamageSystem:cleanRadiatorAndAirIntake(dt)
    local C = ADS_Config.FIELD_CARE
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil then
        return
    end

    local prevRadiatorClogging = tonumber(spec.radiatorClogging) or 0
    local prevAirIntakeClogging = tonumber(spec.airIntakeClogging) or 0
    local cleaningDelta = (C.CLEANING_SPEED / 1000) * dt

    spec.radiatorClogging = math.max(prevRadiatorClogging - cleaningDelta, 0)
    spec.airIntakeClogging = math.max(prevAirIntakeClogging - cleaningDelta, 0)

    if self.isServer then
        markFieldcareDirty(self, spec)
    end
end

function AdvancedDamageSystem:updateLubricationLevel(dt)
    local C = ADS_Config.FIELD_CARE
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil or not spec.isVehicleNeedLubricate then
        return
    end

    local currentDay = g_currentMission.environment.currentDay
    if spec.lastLubricationProcessedDay == nil then
        spec.lastLubricationProcessedDay = currentDay
        return
    end

    if currentDay > spec.lastLubricationProcessedDay and not self:getIsMotorStarted() then
        spec.lubricationLevel = math.max(spec.lubricationLevel - C.LUBRICATION_REDUCE_PER_DAY, 0)
        spec.lastLubricationProcessedDay = currentDay
    end
end

function AdvancedDamageSystem:lubricateVehicle()
    local C = ADS_Config.FIELD_CARE
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil then
        return
    end

    local prevLubricationLevel = tonumber(spec.lubricationLevel) or 0
    spec.lubricationLevel = math.min(prevLubricationLevel + 0.2, 1.0)

    if self.isServer then
        markFieldcareDirty(self, spec)
    end
end

function AdvancedDamageSystem:startFieldVisualInspectionProcess()
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil or spec.isExcludedVehicle then
        return false
    end

    if self.getIsMotorStarted ~= nil and self:getIsMotorStarted() then
        if self.isClient and g_currentMission ~= nil then
            g_currentMission:showBlinkingWarning(g_i18n:getText("ads_field_inspection_engine_must_be_stopped"), 2200)
        end
        return false
    end

    if self:getCurrentStatus() ~= AdvancedDamageSystem.STATUS.READY then
        return false
    end

    local inspection = spec.fieldInspection
    if inspection == nil then
        return false
    end

    if inspection.isActive then
        return false
    end

    inspection.isActive = true
    inspection.elapsedTime = 0
    inspection.duration = 5000
    inspection.startTime = g_time
    inspection.targetVehicle = self
    inspection.wasSoundStarted = false

    local node = self.rootNode
    if (node == nil or node == 0) and self.components ~= nil and self.components[1] ~= nil then
        node = self.components[1].node
    end
    inspection.targetNode = node

    if self.isClient and spec.samples ~= nil and spec.samples.inspection ~= nil then
        g_soundManager:playSample(spec.samples.inspection)
        inspection.wasSoundStarted = true
    end

    if self.isClient and ADS_Hud ~= nil then
        ADS_Hud.showNotification(string.format(g_i18n:getText("ads_field_inspection_progress"), 0), inspection.duration)
    end

    return true
end


-- ==========================================================
--                OVERWRITTEN FUNCTIONS
-- ==========================================================

function AdvancedDamageSystem.updateDamageAmount(wearable, superFunc, dt)
	if wearable.spec_AdvancedDamageSystem ~= nil and not wearable.spec_AdvancedDamageSystem.isExcludedVehicle then
		return 0
	else
		return superFunc(wearable, dt)
	end
end

function AdvancedDamageSystem.setOperatingTime(self, superFunc, operatingTime, isLoading)
    local spec = self.spec_AdvancedDamageSystem
    if spec ~= nil and not spec.isExcludedVehicle and not isLoading and not spec._allowAdsOperatingTimeWrite then
        return
    end

    superFunc(self, operatingTime, isLoading)
end

function AdvancedDamageSystem.getSellPrice(self, superFunc)
	if self.spec_AdvancedDamageSystem ~= nil and not self.spec_AdvancedDamageSystem.isExcludedVehicle then
		local overallCondition = self:getConditionLevel() or 1.0
        local price = self:getPrice() or 0
        local repaintPrice = Wearable.calculateRepaintPrice(price, self:getWearTotalAmount()) * 0.25
        local repairPrice = self:getServicePrice(
            AdvancedDamageSystem.STATUS.REPAIR,
            AdvancedDamageSystem.REPAIR_TYPES.MEDIUM,
            AdvancedDamageSystem.PART_TYPES.OEM, false, AdvancedDamageSystem.WORKSHOP.DEALER, true)
        return math.clamp(price * overallCondition - repaintPrice - repairPrice, price * 0.03, price * 0.8)
	else
		return superFunc(self)
	end
end

-- ==========================================================
--                        GETTERS
-- ==========================================================

function AdvancedDamageSystem:getServiceLevel()
    return self.spec_AdvancedDamageSystem.serviceLevel
end

function AdvancedDamageSystem:getConditionLevel()
    return self.spec_AdvancedDamageSystem.conditionLevel
end

function AdvancedDamageSystem:getSystemConditionLevel(systemName)
    local spec = self.spec_AdvancedDamageSystem
    local systemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, systemName)
    return spec.systems[systemKey].condition
end

function AdvancedDamageSystem:getSystemStressLevel(systemName)
    local spec = self.spec_AdvancedDamageSystem
    local systemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, systemName)
    return spec.systems[systemKey].stress
end

function AdvancedDamageSystem:isUnderRoof()
    local node = self.rootNode
    if (node == nil or node == 0) and self.components ~= nil and self.components[1] ~= nil then
        node = self.components[1].node
    end

    if node == nil or node == 0 then
        return false
    end

    local x, y, z = getWorldTranslation(node)
    local mission = g_currentMission

    if mission ~= nil and mission.indoorMask ~= nil then
        local handle, firstChannel, numChannels = mission.indoorMask:getDensityMapData()
        if handle ~= nil and handle ~= 0 and mission.terrainSize ~= nil and mission.terrainSize > 0 then
            local maskSize = getBitVectorMapSize(handle)
            if maskSize ~= nil and maskSize > 0 then
                local terrainHalfSize = mission.terrainSize * 0.5
                local worldToDensityMap = maskSize / mission.terrainSize
                local xI = math.floor((x + terrainHalfSize) * worldToDensityMap)
                local zI = math.floor((z + terrainHalfSize) * worldToDensityMap)

                if xI >= 0 and xI < maskSize and zI >= 0 and zI < maskSize then
                    local maskValue = getBitVectorMapPoint(handle, xI, zI, firstChannel, numChannels)
                    local indoorValue = IndoorMask ~= nil and IndoorMask.INDOOR or 1
                    return maskValue == indoorValue
                end
            end
        end
    end

    if mission == nil or mission.placeableSystem == nil or mission.placeableSystem.placeables == nil then
        return false
    end

    for _, placeable in pairs(mission.placeableSystem.placeables) do
        local indoorAreas = placeable.spec_indoorAreas
        if indoorAreas ~= nil and indoorAreas.areas ~= nil and placeable.rootNode ~= nil and placeable.rootNode ~= 0 then
            local localX, _, localZ = worldToLocal(placeable.rootNode, x, y, z)

            for _, area in ipairs(indoorAreas.areas) do
                if area.start ~= nil and area.width ~= nil and area.height ~= nil then
                    local sx, sy, sz = getWorldTranslation(area.start)
                    local wx, wy, wz = getWorldTranslation(area.width)
                    local hx, hy, hz = getWorldTranslation(area.height)

                    local localStartX, _, localStartZ = worldToLocal(placeable.rootNode, sx, sy, sz)
                    local localWidthX, _, localWidthZ = worldToLocal(placeable.rootNode, wx, wy, wz)
                    local localHeightX, _, localHeightZ = worldToLocal(placeable.rootNode, hx, hy, hz)

                    local minX = math.min(localStartX, localWidthX, localHeightX)
                    local maxX = math.max(localStartX, localWidthX, localHeightX)
                    local minZ = math.min(localStartZ, localWidthZ, localHeightZ)
                    local maxZ = math.max(localStartZ, localWidthZ, localHeightZ)

                    if localX >= minX and localX <= maxX and localZ >= minZ and localZ <= maxZ then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function AdvancedDamageSystem:isUnderService()
    return self.spec_AdvancedDamageSystem.currentState ~= AdvancedDamageSystem.STATUS.READY
end

function AdvancedDamageSystem:getCurrentStatus()
    return self.spec_AdvancedDamageSystem.currentState
end

function AdvancedDamageSystem:setNewStatus(status)
    self.spec_AdvancedDamageSystem.currentState = status
    ADS_VehicleChangeStatusEvent.send(self)
end

function AdvancedDamageSystem:getActiveBreakdowns()
    return self.spec_AdvancedDamageSystem.activeBreakdowns
end

function AdvancedDamageSystem.getIsLogEntryHasReport(entry)
    local isVisible = ADS_Utils.normalizeBoolValue(entry.isVisible, true)
    local isCompleted = ADS_Utils.normalizeBoolValue(entry.isCompleted, true)
    local isLegacyEntry = ADS_Utils.normalizeBoolValue(entry.isLegacyEntry, false)

    return (entry.type ~= AdvancedDamageSystem.STATUS.REPAIR 
    and entry.optionOne ~= AdvancedDamageSystem.INSPECTION_TYPES.VISUAL 
    and entry.optionOne ~= "NONE" 
    and isCompleted
    and not isLegacyEntry)
end

function AdvancedDamageSystem.getIsCompleteReport(entry)
    return entry.optionOne == AdvancedDamageSystem.INSPECTION_TYPES.COMPLETE or entry.type == AdvancedDamageSystem.STATUS.OVERHAUL
end

function AdvancedDamageSystem:getLastInspectedCondition()
    local spec = self.spec_AdvancedDamageSystem
    if not spec or not spec.maintenanceLog or #spec.maintenanceLog == 0 then
        return 0
    end

    for i = #spec.maintenanceLog, 1, -1 do
        local entry = spec.maintenanceLog[i]
        if AdvancedDamageSystem.getIsLogEntryHasReport(entry) then
            return entry.conditionData.condition, AdvancedDamageSystem.getIsCompleteReport(entry)
        end
    end
    return 1.0
end

function AdvancedDamageSystem:getLastInspectedService()
    local spec = self.spec_AdvancedDamageSystem
    if not spec or not spec.maintenanceLog or #spec.maintenanceLog == 0 then
        return 0
    end

    for i = #spec.maintenanceLog, 1, -1 do
        local entry = spec.maintenanceLog[i]
        if AdvancedDamageSystem.getIsLogEntryHasReport(entry) then
            return entry.conditionData.service, AdvancedDamageSystem.getIsCompleteReport(entry)
        end
    end
    return 1.0
end

function AdvancedDamageSystem:getLastInspectionDate()
    local spec = self.spec_AdvancedDamageSystem
    if not spec or not spec.maintenanceLog or #spec.maintenanceLog == 0 then
        return 0
    end

    for i = #spec.maintenanceLog, 1, -1 do
        local entry = spec.maintenanceLog[i]
        if AdvancedDamageSystem.getIsLogEntryHasReport(entry) then
            return entry.date
        end
    end
end

function AdvancedDamageSystem:getLastMaintenanceDate()
    local spec = self.spec_AdvancedDamageSystem
    if not spec or not spec.maintenanceLog or #spec.maintenanceLog == 0 then
        return 0
    end

    for i = #spec.maintenanceLog, 1, -1 do
        local entry = spec.maintenanceLog[i]
        if entry.type == AdvancedDamageSystem.STATUS.MAINTENANCE or entry.type == AdvancedDamageSystem.STATUS.OVERHAUL then
            return entry.date
        end
    end
end

function AdvancedDamageSystem:getLastInspectionOperatingHours()
    local spec = self.spec_AdvancedDamageSystem
    if not spec or not spec.maintenanceLog or #spec.maintenanceLog == 0 then
        return 0
    end

    for i = #spec.maintenanceLog, 1, -1 do
        local entry = spec.maintenanceLog[i]
        if AdvancedDamageSystem.getIsLogEntryHasReport(entry) then
            return entry.conditionData.operatingHours
        end
    end
    return 0
end

function AdvancedDamageSystem:getLastMaintenanceOperatingHours()
    local spec = self.spec_AdvancedDamageSystem
    if not spec or not spec.maintenanceLog or #spec.maintenanceLog == 0 then
        return 0
    end

    for i = #spec.maintenanceLog, 1, -1 do
        local entry = spec.maintenanceLog[i]
        if entry.type == AdvancedDamageSystem.STATUS.MAINTENANCE or entry.type == AdvancedDamageSystem.STATUS.OVERHAUL then
            return entry.conditionData.operatingHours
        end
    end
    return 0
end

function AdvancedDamageSystem:getMaintenanceInterval()
    local spec = self.spec_AdvancedDamageSystem
    if not spec then return 0 end
    local lastMaintenanceType = AdvancedDamageSystem.MAINTENANCE_TYPES.STANDARD

    for i = #spec.maintenanceLog, 1, -1 do
        local entry = spec.maintenanceLog[i]
        if entry.type == AdvancedDamageSystem.STATUS.MAINTENANCE then
            lastMaintenanceType = entry.optionOne
            break
        end
    end

    local maintenanceIndex = ADS_Utils.getNameByValue(AdvancedDamageSystem.MAINTENANCE_TYPES, lastMaintenanceType)
    local restoreCoeff = ADS_Config.MAINTENANCE.MAINTENANCE_SERVICE_RESTORE_MULTIPLIERS[maintenanceIndex]

    local interval = (spec.baseServiceLevel * restoreCoeff / ADS_Config.CORE.BASE_SERVICE_WEAR / 2) * spec.reliability
    return interval
end

function AdvancedDamageSystem:getHoursSinceLastMaintenance()
    local spec = self.spec_AdvancedDamageSystem
    if not spec then return 0 end

    for i = #spec.maintenanceLog, 1, -1 do
        local entry = spec.maintenanceLog[i]
        if entry.type == AdvancedDamageSystem.STATUS.MAINTENANCE then
            return math.max(self:getFormattedOperatingTime() - (entry.conditionData.operatingHours or 0), 0)
        elseif entry.id == 1 then
            local serviceLevelAtStart = entry.conditionData.service or 0
            local calculatedHoursForMaintenance = entry.conditionData.operatingHours - (spec.baseServiceLevel - serviceLevelAtStart) / (ADS_Config.CORE.BASE_SERVICE_WEAR / spec.reliability)
            return math.max(self:getFormattedOperatingTime() - calculatedHoursForMaintenance, 0)
        end
    end
    return 0
end

function AdvancedDamageSystem:getLastServiceOptions()
    local spec = self.spec_AdvancedDamageSystem
    if not spec or not spec.maintenanceLog or #spec.maintenanceLog == 0 then
        return AdvancedDamageSystem.INSPECTION_TYPES.STANDARD, "NONE", false
    else
        local lastEntry = spec.maintenanceLog[#spec.maintenanceLog]
        return lastEntry.optionOne, lastEntry.optionTwo, lastEntry.optionThree
    end
end

function AdvancedDamageSystem:getOverhaulPerformedCount()
    local spec = self.spec_AdvancedDamageSystem
    if not spec or not spec.maintenanceLog or #spec.maintenanceLog == 0 then
        return 0
    end
    local count = 0
    for i = #spec.maintenanceLog, 1, -1 do
        local entry = spec.maintenanceLog[i]
        if entry.type == AdvancedDamageSystem.STATUS.OVERHAUL  then
            count = count + 1
        end
    end
    return count
end

function AdvancedDamageSystem.getBrandReliability(vehicle, storeItem)
    local year = 2005
    local brandName = 'LIZARD'
    local name = 'LIZARD'

    if vehicle ~= nil then
        name = vehicle:getName()
        local brand = g_brandManager:getBrandByIndex(vehicle:getBrand())
        if not brand then
            return 1.0, 1.0
        end

        local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
        if storeItem.specs ~= nil and storeItem.specs.year ~= nil then
            local newYear =  tonumber(storeItem.specs.year)
            if newYear ~= nil then
                year = newYear
            end
        end
        brandName = brand.name

    elseif storeItem ~= nil then
        name = storeItem.name
        brandName = storeItem.brandNameRaw
        if storeItem.specs ~= nil and storeItem.specs.year ~= nil then
            local newYear =  tonumber(storeItem.specs.year)
            if newYear ~= nil then
                year = newYear
            end
        end
    end

    local yearFactor = 0
    if year < ADS_Config.CORE.RELIABILITY_YEAR_FACTOR_THRESHOLD then
        yearFactor = math.max(ADS_Config.CORE.RELIABILITY_YEAR_FACTOR_THRESHOLD - year, 0) * ADS_Config.CORE.RELIABILITY_YEAR_FACTOR
    end

    local modelData = ADS_Config.BRANDS[name]

    if modelData ~= nil then
        return modelData[1], modelData[2]
    end

    local brandData = ADS_Config.BRANDS[brandName]

    if brandData ~= nil then
        return brandData[1], brandData[2] + yearFactor
    else
        return 1.0, 1.0
    end
end

function AdvancedDamageSystem.calculateBreakdownProbability(level, p, dt)
    local threshold = math.clamp(tonumber(ADS_Config.CORE.BREAKDOWN_PROBABILITIES.STRESS_THRESHOLD) or 1.0, 0.0, 0.999)
    local clampedLevel = math.max(tonumber(level) or 0, 0.0)
    local normalizedLevel = math.clamp((clampedLevel - threshold) / math.max(1 - threshold, 0.001), 0.0, 1.0)

    local calculatedMtbf = p.MAX_MTBF + (p.MIN_MTBF - p.MAX_MTBF) * normalizedLevel ^ (math.max(p.DEGREE - p.DEGREE * normalizedLevel, 0.1))
    local mtbfInMinutes = math.max(calculatedMtbf, p.MIN_MTBF)
    local mtbfInMillis = mtbfInMinutes * 60 * 1000

    if mtbfInMillis <= 0 then
        return 1.0
    end

    return 1 - math.exp(-dt / mtbfInMillis)
end

function AdvancedDamageSystem:isWarrantyRepairCovered(repairType, partType)
    local C = ADS_Config.MAINTENANCE
    if C == nil or not C.WARRANTY_ENABLED then
        return false
    end

    if self.propertyState ~= 2 then
        return false
    end

    local resolvedPartType = partType or AdvancedDamageSystem.PART_TYPES.OEM
    local resolverRepairType = repairType or AdvancedDamageSystem.REPAIR_TYPES.MEDIUM
    if resolvedPartType ~= AdvancedDamageSystem.PART_TYPES.OEM or resolverRepairType ~= AdvancedDamageSystem.REPAIR_TYPES.MEDIUM then
        return false
    end

    local operatingHours = self.getFormattedOperatingTime ~= nil and tonumber(self:getFormattedOperatingTime()) or 0
    local ageMonths = tonumber(self.age) or 0

    local lifespanScale = ADS_Config.CORE.DEFAULT_SYSTEM_WEAR / ADS_Config.CORE.BASE_SYSTEMS_WEAR
    if operatingHours >= ((C.WARRANTY_MAX_OPERATING_HOURS * lifespanScale) or 20) or ageMonths >= (C.WARRANTY_MAX_AGE_MONTHS or 12) then
        return false
    end

    return true
end

function AdvancedDamageSystem:getServicePrice(maintenanceType, optionOne, optionTwo, optionThree, workshopTypeOverride, allBreakdowns)
    local price = self:getPrice()
    local spec = self.spec_AdvancedDamageSystem
    local ageFactor = math.min(math.max(math.log10(self.age), 1), 2)
    local C = ADS_Config.MAINTENANCE

    if not maintenanceType then maintenanceType = spec.currentState end

    if maintenanceType == AdvancedDamageSystem.STATUS.READY then
        return 0
    end

    local workshopType = workshopTypeOverride or spec.workshopType
    local workshopKey = ADS_Utils.getNameByValue(AdvancedDamageSystem.WORKSHOP, workshopType)
    local ownWorkshopDiscount = ADS_Config.WORKSHOP.PRICE_MULTIPLIERS[workshopKey] or 1.0

    -- inspection
    if maintenanceType == AdvancedDamageSystem.STATUS.INSPECTION then
        local key = ADS_Utils.getNameByValue(AdvancedDamageSystem.INSPECTION_TYPES, optionOne)
        local inspectionPrice = math.ceil(math.max((C.GLOBAL_SERVICE_PRICE_MULTIPLIER * C.INSPECTION_PRICE_MULTIPLIERS[key] * price * 0.001 * ownWorkshopDiscount / 10) / spec.maintainability, 2)) * 10
        log_dbg(string.format("Calculated inspection price: %.2f (base price: %.2f, multiplier: %.4f, own workshop discount: %.2f, maintainability: %.2f)", inspectionPrice, price, C.INSPECTION_PRICE_MULTIPLIERS[key] * C.GLOBAL_SERVICE_PRICE_MULTIPLIER * 0.0005, ownWorkshopDiscount, spec.maintainability))
        return inspectionPrice
        
    -- maintenance
    elseif maintenanceType == AdvancedDamageSystem.STATUS.MAINTENANCE then
        local key = ADS_Utils.getNameByValue(AdvancedDamageSystem.MAINTENANCE_TYPES, optionOne)
        local optionTwoKey = ADS_Utils.getNameByValue(AdvancedDamageSystem.PART_TYPES, optionTwo) or AdvancedDamageSystem.PART_TYPES.OEM
        local maintenancePrice = math.ceil(math.max((C.GLOBAL_SERVICE_PRICE_MULTIPLIER * C.MAINTENANCE_PRICE_MULTIPLIERS[key] * C.PARTS_PRICE_MULTIPLIERS[optionTwoKey] * ownWorkshopDiscount * price * ageFactor * 0.01 / 10) / spec.maintainability, 2)) * 10
        log_dbg(string.format("Calculated maintenance price: %.2f (base price: %.2f, multiplier: %.2f, own workshop discount: %.2f, age factor: %.2f, maintainability: %.2f)", maintenancePrice, price, C.MAINTENANCE_PRICE_MULTIPLIERS[key] * C.GLOBAL_SERVICE_PRICE_MULTIPLIER * C.PARTS_PRICE_MULTIPLIERS[optionTwoKey], ownWorkshopDiscount, ageFactor, spec.maintainability))
        return  maintenancePrice

    -- overhaul
    elseif maintenanceType == AdvancedDamageSystem.STATUS.OVERHAUL then
        local key = ADS_Utils.getNameByValue(AdvancedDamageSystem.OVERHAUL_TYPES, optionOne)
        local overhaulPrice = 0

        if optionOne == AdvancedDamageSystem.OVERHAUL_TYPES.PARTIAL then
            local systemWeight = ADS_Utils.getEffectiveSystemWeight(self, optionTwo, AdvancedDamageSystem.SYSTEMS)
            if systemWeight <= 0 then
                return 0
            end
            overhaulPrice = (price * C.OVERHAUL_PRICE_MULTIPLIERS[key] * C.GLOBAL_SERVICE_PRICE_MULTIPLIER * systemWeight * ownWorkshopDiscount ) / spec.maintainability
        else
            overhaulPrice = (price * C.OVERHAUL_PRICE_MULTIPLIERS[key] * C.GLOBAL_SERVICE_PRICE_MULTIPLIER * ownWorkshopDiscount ) / spec.maintainability
        end
        if optionThree then
            overhaulPrice = overhaulPrice + Wearable.calculateRepaintPrice(self:getSellPrice(), self:getWearTotalAmount()) * 0.25
        end
        overhaulPrice = math.max(overhaulPrice, 100)
        log_dbg(string.format("Calculated overhaul price: %.2f (base price: %.2f, multiplier: %.2f, own workshop discount: %.2f, maintainability: %.2f)", overhaulPrice, price, C.OVERHAUL_PRICE_MULTIPLIERS[key] * C.GLOBAL_SERVICE_PRICE_MULTIPLIER, ownWorkshopDiscount, spec.maintainability))
        return overhaulPrice
    
    -- repair
    elseif maintenanceType == AdvancedDamageSystem.STATUS.REPAIR then
        if self:isWarrantyRepairCovered(optionOne, optionTwo) then
            return 0
        end

        local key = ADS_Utils.getNameByValue(AdvancedDamageSystem.REPAIR_TYPES, optionOne)
        local optionTwoKey = ADS_Utils.getNameByValue(AdvancedDamageSystem.PART_TYPES, optionTwo) or AdvancedDamageSystem.PART_TYPES.OEM
        local repairPrice = 0
        local activeBreakdowns = self:getActiveBreakdowns()
        
        for id, breakdown in pairs(activeBreakdowns) do
            if isBreakdownSelectedForPlayerRepair(id, breakdown, optionOne) or (allBreakdowns and getIsSelectableBreakdown(id)) then
                local registryEntry = ADS_Breakdowns.BreakdownRegistry[id]
                if registryEntry ~= nil then
                    repairPrice = repairPrice + registryEntry.stages[breakdown.stage].repairPrice * C.GLOBAL_SERVICE_PRICE_MULTIPLIER * C.PARTS_PRICE_MULTIPLIERS[optionTwoKey] * C.REPAIR_PRICE_MULTIPLIERS[key] * ownWorkshopDiscount * (price / 100) * ageFactor
                end
            end
        end
        repairPrice = repairPrice * (1 / spec.maintainability)
        return repairPrice
    end
    return 0
end

function AdvancedDamageSystem:getBreakdownRepairPrice(breakdownId, breakdownStage, partType)
    local C = ADS_Config.MAINTENANCE
    local spec = self.spec_AdvancedDamageSystem
    local registryEntry = ADS_Breakdowns.BreakdownRegistry[breakdownId]
    if registryEntry == nil then return 0 end

    local stageData = registryEntry.stages[breakdownStage]
    if stageData == nil then return 0 end

    if self:isWarrantyRepairCovered(AdvancedDamageSystem.REPAIR_TYPES.MEDIUM, partType) then
        return 0
    end

    local price = stageData.repairPrice or 0
    local vehiclePrice = self:getPrice()
    local ageFactor = math.min(math.max(math.log10(self.age), 1), 2)

    local workshopKey = ADS_Utils.getNameByValue(AdvancedDamageSystem.WORKSHOP, spec.workshopType)
    local ownWorkshopDiscount = ADS_Config.WORKSHOP.PRICE_MULTIPLIERS[workshopKey] or 1.0

    return price * C.GLOBAL_SERVICE_PRICE_MULTIPLIER * (vehiclePrice / 100) * ageFactor * ownWorkshopDiscount / spec.maintainability
end

function AdvancedDamageSystem:getServiceDuration(maintenanceType, optionOne, optionTwo, optionThree, workshopTypeOverride)
    local spec = self.spec_AdvancedDamageSystem
    local C = ADS_Config.MAINTENANCE
    local workshopType = workshopTypeOverride or spec.workshopType

    if not maintenanceType then maintenanceType = spec.currentState end

    if maintenanceType == AdvancedDamageSystem.STATUS.READY then
        return 0
    end

    local workDurationHours = 0

    if spec.currentState ~= AdvancedDamageSystem.STATUS.READY and spec.currentState ~= AdvancedDamageSystem.STATUS.BROKEN then
        workDurationHours = spec.maintenanceTimer / 3600000
    else
        local totalDurationMs = 0
        -- inspection
        if maintenanceType == AdvancedDamageSystem.STATUS.INSPECTION then
            if C.INSTANT_INSPECTION and optionOne == AdvancedDamageSystem.INSPECTION_TYPES.VISUAL then
                optionOne = AdvancedDamageSystem.INSPECTION_TYPES.STANDARD
            end
            local key = ADS_Utils.getNameByValue(AdvancedDamageSystem.INSPECTION_TYPES, optionOne)
            if C.INSTANT_INSPECTION then
                totalDurationMs = 1000
            else
                totalDurationMs = C.INSPECTION_TIME * C.GLOBAL_SERVICE_TIME_MULTIPLIER * C.INSPECTION_TIME_MULTIPLIERS[key] / spec.maintainability
            end
        -- maintenance
        elseif maintenanceType == AdvancedDamageSystem.STATUS.MAINTENANCE then
            local key = ADS_Utils.getNameByValue(AdvancedDamageSystem.MAINTENANCE_TYPES, optionOne)
            totalDurationMs = C.MAINTENANCE_TIME * C.GLOBAL_SERVICE_TIME_MULTIPLIER * C.MAINTENANCE_TIME_MULTIPLIERS[key] / spec.maintainability
        -- overhaul
        elseif maintenanceType == AdvancedDamageSystem.STATUS.OVERHAUL then
            local key = ADS_Utils.getNameByValue(AdvancedDamageSystem.OVERHAUL_TYPES, optionOne)
            totalDurationMs = C.OVERHAUL_TIME * C.GLOBAL_SERVICE_TIME_MULTIPLIER * C.OVERHAUL_TIME_MULTIPLIERS[key] / spec.maintainability
            if optionOne == AdvancedDamageSystem.OVERHAUL_TYPES.PARTIAL then
                 local systemWeight = ADS_Utils.getEffectiveSystemWeight(self, optionTwo, AdvancedDamageSystem.SYSTEMS)
                 if systemWeight <= 0 then
                    return 0
                 end
                 totalDurationMs = totalDurationMs * systemWeight
            end
            if optionThree then
                totalDurationMs = totalDurationMs + C.REPAINT_TIME
            end
        -- repair
        elseif maintenanceType == AdvancedDamageSystem.STATUS.REPAIR then
            local key = ADS_Utils.getNameByValue(AdvancedDamageSystem.REPAIR_TYPES, optionOne)
            local repairCount = 0
            local breakdowns = self:getActiveBreakdowns()

            if breakdowns ~= nil and next(breakdowns) ~= nil then
                for id, breakdown in pairs(breakdowns) do
                    if isBreakdownSelectedForPlayerRepair(id, breakdown, optionOne) then
                        repairCount = repairCount + 1
                    end
                end
            end
            totalDurationMs = C.REPAIR_TIME * C.GLOBAL_SERVICE_TIME_MULTIPLIER * C.REPAIR_TIME_MULTIPLIERS[key] * repairCount / spec.maintainability
        end
        workDurationHours = totalDurationMs / 3600000
    end

    if workDurationHours <= 0 then
        return 0
    end

    local totalElapsedHours

    if workshopType == AdvancedDamageSystem.WORKSHOP.MOBILE or ADS_Config.WORKSHOP.ALWAYS_AVAILABLE then
        totalElapsedHours = workDurationHours
    else
        local WORKSHOP_HOURS = ADS_Config.WORKSHOP
        local currentHour = (g_currentMission.environment.dayTime / 3600000) % 24

        totalElapsedHours = 0
        local timeRemaining = workDurationHours

        local workStartTimeToday = math.max(currentHour, WORKSHOP_HOURS.OPEN_HOUR)

        if workStartTimeToday >= WORKSHOP_HOURS.CLOSE_HOUR then
            local hoursUntilNextOpen = (24 - currentHour) + WORKSHOP_HOURS.OPEN_HOUR
            totalElapsedHours = totalElapsedHours + hoursUntilNextOpen
            currentHour = WORKSHOP_HOURS.OPEN_HOUR
        elseif currentHour < WORKSHOP_HOURS.OPEN_HOUR then
            local hoursUntilOpen = WORKSHOP_HOURS.OPEN_HOUR - currentHour
            totalElapsedHours = totalElapsedHours + hoursUntilOpen
            currentHour = WORKSHOP_HOURS.OPEN_HOUR
        end

        while timeRemaining > 0 do
            local remainingWorkHoursToday = WORKSHOP_HOURS.CLOSE_HOUR - currentHour

            if timeRemaining <= remainingWorkHoursToday then
                totalElapsedHours = totalElapsedHours + timeRemaining
                timeRemaining = 0
            else
                totalElapsedHours = totalElapsedHours + remainingWorkHoursToday
                timeRemaining = timeRemaining - remainingWorkHoursToday

                local overnightBreak = (24 - WORKSHOP_HOURS.CLOSE_HOUR) + WORKSHOP_HOURS.OPEN_HOUR
                totalElapsedHours = totalElapsedHours + overnightBreak

                currentHour = WORKSHOP_HOURS.OPEN_HOUR
            end
        end
    end

    return totalElapsedHours
end

function AdvancedDamageSystem:getServiceFinishTime(maintenanceType, optionOne, optionTwo, optionThree, workshopTypeOverride)
    local spec = self.spec_AdvancedDamageSystem

    if not maintenanceType then maintenanceType = spec.currentState end
    local savedOptionOne, savedOptionTwo, savedOptionThree = self:getLastServiceOptions()
    if not optionOne then optionOne = savedOptionOne end
    if not optionTwo then optionTwo = savedOptionTwo end
    if not optionThree then optionThree = savedOptionThree end

    if maintenanceType == AdvancedDamageSystem.STATUS.READY then
        return 0
    end

    local totalCalendarDuration = AdvancedDamageSystem.getServiceDuration(self, maintenanceType, optionOne, optionTwo, optionThree, workshopTypeOverride)

    if totalCalendarDuration <= 0 then
        local currentTime = (g_currentMission.environment.dayTime / 3600000) % 24
        return currentTime, 0
    end

    local currentDayTime = g_currentMission.environment.dayTime / 3600000
    local finishDayTimeAbsolute = currentDayTime + totalCalendarDuration

    local currentDay = math.floor(currentDayTime / 24)
    local finishDay = math.floor(finishDayTimeAbsolute / 24)
    
    local finishTimeOfDay = finishDayTimeAbsolute % 24
    local daysToAdd = finishDay - currentDay
    
    return finishTimeOfDay, daysToAdd
end

-- ==========================================================
--                      CONSOLE COMMANDS
-- ==========================================================

AdvancedDamageSystem.ConsoleCommands = {}

function AdvancedDamageSystem.ConsoleCommands:getTargetVehicle()
    if AdvancedDamageSystem.ConsoleCommands._overrideVehicle ~= nil then
        local v = AdvancedDamageSystem.ConsoleCommands._overrideVehicle
        if v.spec_AdvancedDamageSystem ~= nil then
            return v
        end
        print("ADS Error: Override vehicle does not have AdvancedDamageSystem support.")
        return nil
    end
    local vehicle = g_localPlayer.getCurrentVehicle() 
    if not vehicle or not vehicle.spec_AdvancedDamageSystem then
        print("ADS Error: You must be in a vehicle with AdvancedDamageSystem support.")
        return nil
    end
    return vehicle
end

local function parseArguments(argString, ...)
    local extraArgs = { ... }
    local hasExtraArgs = #extraArgs > 0

    if hasExtraArgs then
        local args = {}

        local function appendToken(token)
            if token == nil then
                return
            end
            token = tostring(token)
            if token == "" then
                return
            end

            if string.find(token, "%s") then
                for splitToken in string.gmatch(token, "[^%s]+") do
                    table.insert(args, splitToken)
                end
            else
                table.insert(args, token)
            end
        end

        appendToken(argString)
        for _, extraArg in ipairs(extraArgs) do
            appendToken(extraArg)
        end

        return args
    end

    if argString == nil or type(argString) ~= 'string' or argString == '' then
        return {}
    end

    local args = {}
    for arg in string.gmatch(argString, "[^%s]+") do
        table.insert(args, arg)
    end
    return args
end

local function parsePathTokens(path)
    local tokens = {}
    if type(path) ~= "string" or path == "" then
        return tokens
    end

    for token in string.gmatch(path, "[^%.]+") do
        local numberToken = tonumber(token)
        if numberToken ~= nil then
            table.insert(tokens, numberToken)
        else
            table.insert(tokens, token)
        end
    end

    return tokens
end

local function parseConsoleValue(rawValue)
    if rawValue == nil then
        return nil, false
    end

    local lowerValue = string.lower(tostring(rawValue))
    if lowerValue == "true" then
        return true, true
    end
    if lowerValue == "false" then
        return false, true
    end
    if lowerValue == "nil" then
        return nil, true
    end

    local numberValue = tonumber(rawValue)
    if numberValue ~= nil then
        return numberValue, true
    end

    return rawValue, true
end

local function resolvePathParent(rootTable, fullPath)
    if type(rootTable) ~= "table" then
        return nil, nil, nil, "Root is not a table."
    end

    local tokens = parsePathTokens(fullPath)
    if #tokens == 0 then
        return nil, nil, nil, "Path is empty."
    end

    local current = rootTable
    for i = 1, #tokens - 1 do
        local key = tokens[i]
        if type(current) ~= "table" then
            return nil, nil, nil, string.format("Path segment '%s' is not a table.", tostring(key))
        end

        current = current[key]
        if current == nil then
            return nil, nil, nil, string.format("Path segment '%s' does not exist.", tostring(key))
        end
    end

    return current, tokens[#tokens], tokens
end

local function getPrimaryFuelConsumerInfo(vehicle)
    if vehicle == nil or vehicle.spec_motorized == nil or vehicle.spec_motorized.consumers == nil then
        return nil, nil
    end

    local preferredTypes = {}
    if FillType ~= nil then
        if FillType.DIESEL ~= nil then table.insert(preferredTypes, FillType.DIESEL) end
        if FillType.METHANE ~= nil then table.insert(preferredTypes, FillType.METHANE) end
        if FillType.ELECTRICCHARGE ~= nil then table.insert(preferredTypes, FillType.ELECTRICCHARGE) end
    end

    local function isPreferred(fillType)
        for _, preferredType in ipairs(preferredTypes) do
            if fillType == preferredType then
                return true
            end
        end
        return false
    end

    local fallbackConsumer = nil
    local defFillType = FillType ~= nil and FillType.DEF or nil
    for _, consumer in pairs(vehicle.spec_motorized.consumers) do
        if consumer ~= nil and consumer.fillUnitIndex ~= nil and consumer.fillType ~= nil then
            if isPreferred(consumer.fillType) then
                return consumer.fillUnitIndex, consumer.fillType
            end

            if fallbackConsumer == nil and (defFillType == nil or consumer.fillType ~= defFillType) then
                fallbackConsumer = consumer
            end
        end
    end

    if fallbackConsumer ~= nil then
        return fallbackConsumer.fillUnitIndex, fallbackConsumer.fillType
    end

    return nil, nil
end

local function syncConsoleCloggingState(vehicle, spec, parent, key)
    if vehicle == nil or spec == nil or parent ~= spec then
        return false
    end

    if key ~= "radiatorClogging" and key ~= "airIntakeClogging" then
        return false
    end

    spec.radiatorClogging = math.clamp(tonumber(spec.radiatorClogging) or 0, 0.0, 1.0)
    spec.airIntakeClogging = math.clamp(tonumber(spec.airIntakeClogging) or 0, 0.0, 1.0)

    if vehicle.spec_washable ~= nil and vehicle.setDirtAmount ~= nil and vehicle.getDirtAmount ~= nil then
        local currentDirtAmount = math.clamp(tonumber(vehicle:getDirtAmount()) or 0, 0.0, 1.0)
        local requiredDirtAmount = math.max(spec.radiatorClogging or 0, spec.airIntakeClogging or 0)
        if requiredDirtAmount > currentDirtAmount + 0.0001 then
            vehicle:setDirtAmount(requiredDirtAmount)
        end
    end

    if vehicle.isServer and spec.adsDirtyFlag_fieldcare ~= nil then
        vehicle:raiseDirtyFlags(spec.adsDirtyFlag_fieldcare)
    end

    return true
end

local function printSpecValueRecursive(prefix, value, visited, depth)
    visited = visited or {}
    depth = depth or 0

    if type(value) ~= "table" then
        print(string.format("%s = %s", prefix, tostring(value)))
        return
    end

    if visited[value] then
        print(string.format("%s = <recursive>", prefix))
        return
    end

    visited[value] = true
    print(string.format("%s = {", prefix))

    local keys = {}
    for key, _ in pairs(value) do
        table.insert(keys, key)
    end

    table.sort(keys, function(a, b)
        if type(a) == type(b) then
            if type(a) == "number" or type(a) == "string" then
                return a < b
            end
        end
        return tostring(a) < tostring(b)
    end)

    local indent = string.rep("  ", depth + 1)
    for _, key in ipairs(keys) do
        local childPrefix = string.format("%s[%s]", prefix, tostring(key))
        local childValue = value[key]
        if type(childValue) == "table" then
            print(string.format("%s[%s] = {", indent, tostring(key)))
            printSpecValueRecursive(indent .. "  ", childValue, visited, depth + 1)
            print(string.format("%s}", indent))
        else
            print(string.format("%s[%s] = %s", indent, tostring(key), tostring(childValue)))
        end
    end

    print(string.format("%s}", string.rep("  ", depth)))
end

function AdvancedDamageSystem.ConsoleCommands:setConfigVar(rawArgs, rawValue)
    if not g_currentMission:getIsServer() then
        ADS_ConsoleCommandEvent.sendToServer("setConfigVar", rawArgs, rawValue, nil)
        return
    end
    local path = nil
    local valueToken = nil

    if rawValue ~= nil then
        path = tostring(rawArgs)
        valueToken = tostring(rawValue)
    else
        local args = parseArguments(rawArgs)
        path = args and args[1] or nil
        valueToken = args and args[2] or nil
    end

    if path == nil or valueToken == nil then
        print("ADS Error: Usage: ads_setConfigVar <path> <value>")
        print("Example: ads_setConfigVar CORE.BASE_SYSTEMS_WEAR 0.02")
        return
    end

    local value, valueParsed = parseConsoleValue(valueToken)
    if not valueParsed then
        print("ADS Error: Failed to parse value.")
        return
    end

    local parent, key, _, err = resolvePathParent(ADS_Config, path)
    if parent == nil then
        print(string.format("ADS Error: Invalid ADS_Config path '%s': %s", path, tostring(err)))
        return
    end

    local oldValue = parent[key]
    parent[key] = value

    print(string.format("ADS: ADS_Config.%s changed: %s -> %s", path, tostring(oldValue), tostring(value)))
end

function AdvancedDamageSystem.ConsoleCommands:setSpecVar(rawArgs, rawValue)
    if not g_currentMission:getIsServer() then
        local vehicle = self:getTargetVehicle()
        if vehicle then ADS_ConsoleCommandEvent.sendToServer("setSpecVar", rawArgs, rawValue, vehicle) end
        return
    end
    local vehicle = self:getTargetVehicle()
    if not vehicle then return end

    local path = nil
    local valueToken = nil

    if rawValue ~= nil then
        path = tostring(rawArgs)
        valueToken = tostring(rawValue)
    else
        local args = parseArguments(rawArgs)
        path = args and args[1] or nil
        valueToken = args and args[2] or nil
    end

    if path == nil or valueToken == nil then
        print("ADS Error: Usage: ads_setSpecVar <path> <value>")
        print("Example: ads_setSpecVar systems.engine.condition 0.85")
        return
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    local value, valueParsed = parseConsoleValue(valueToken)
    if not valueParsed then
        print("ADS Error: Failed to parse value.")
        return
    end

    local parent, key, _, err = resolvePathParent(spec, path)
    if parent == nil then
        print(string.format("ADS Error: Invalid ADS spec path '%s': %s", path, tostring(err)))
        return
    end

    local oldValue = parent[key]
    parent[key] = value

    local syncedCloggingState = syncConsoleCloggingState(vehicle, spec, parent, key)

    print(string.format("ADS: spec_AdvancedDamageSystem.%s changed on '%s': %s -> %s", path, vehicle:getFullName(), tostring(oldValue), tostring(value)))
    if syncedCloggingState then
        print(string.format(
            "ADS: clogging state synced on '%s' (dirt=%.2f, radiator=%.2f, airIntake=%.2f).",
            vehicle:getFullName(),
            tonumber(vehicle.getDirtAmount ~= nil and vehicle:getDirtAmount() or 0) or 0,
            tonumber(spec.radiatorClogging) or 0,
            tonumber(spec.airIntakeClogging) or 0
        ))
    end
end

function AdvancedDamageSystem.ConsoleCommands:printSpecVar(rawArgs)
    if not g_currentMission:getIsServer() then
        local vehicle = self:getTargetVehicle()
        if vehicle then ADS_ConsoleCommandEvent.sendToServer("printSpecVar", rawArgs, nil, vehicle) end
        return
    end

    local vehicle = self:getTargetVehicle()
    if not vehicle then return end

    local args = parseArguments(rawArgs)
    local path = args and args[1] or nil
    if path == nil then
        print("ADS Error: Usage: ads_printSpecVar <path>")
        print("Example: ads_printSpecVar systems.engine")
        return
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    local parent, key, _, err = resolvePathParent(spec, path)
    if parent == nil then
        print(string.format("ADS Error: Invalid ADS spec path '%s': %s", path, tostring(err)))
        return
    end

    local value = parent[key]
    if value == nil then
        print(string.format("ADS: spec_AdvancedDamageSystem.%s = nil", path))
        return
    end

    if type(value) == "table" then
        print(string.format("ADS: spec_AdvancedDamageSystem.%s on '%s':", path, vehicle:getFullName()))
        printSpecValueRecursive("spec_AdvancedDamageSystem." .. path, value, {}, 0)
    else
        print(string.format(
            "ADS: spec_AdvancedDamageSystem.%s on '%s' = %s",
            path,
            vehicle:getFullName(),
            tostring(value)
        ))
    end
end

function AdvancedDamageSystem.ConsoleCommands:listBreakdowns()
    print("--- Available Breakdowns ---")
    
    local breakdownIds = {}
    for id, data in pairs(ADS_Breakdowns.BreakdownRegistry) do
        table.insert(breakdownIds, string.format(" - %s (%s)", id, data.part or data.system or "No name"))
    end

    if #breakdownIds > 0 then
        table.sort(breakdownIds)
        print(table.concat(breakdownIds, "\n"))
    else
        print("  No breakdowns found in the registry.")
    end
    print("----------------------------")
end

function AdvancedDamageSystem.ConsoleCommands:addBreakdown(rawArgs, rawArgTwo)
    if not g_currentMission:getIsServer() then
        local vehicle = self:getTargetVehicle()
        if vehicle then ADS_ConsoleCommandEvent.sendToServer("addBreakdown", rawArgs, rawArgTwo, vehicle) end
        return
    end
    local args = parseArguments(rawArgs, rawArgTwo)
    local vehicle = self:getTargetVehicle()
    if not vehicle then return end

    if not args or not args[1] then
        local randomId = vehicle:getRandomBreakdown()
        if randomId then
            vehicle:addBreakdown(randomId, 1)
            print(string.format("ADS: Added random breakdown '%s' to '%s'.", randomId, vehicle:getFullName()))
        end
        return
    end

    local breakdownId = string.upper(args[1])
    local stage = tonumber(args[2]) or 1

    local registryEntry = ADS_Breakdowns.BreakdownRegistry[breakdownId]
    if not registryEntry then
        print(string.format("ADS Error: Breakdown with ID '%s' not found.", breakdownId))
        self:listBreakdowns()
        return
    end
    
    local maxStages = #registryEntry.stages
    if stage < 1 or stage > maxStages then
        print(string.format("ADS Error: Invalid stage '%d' for breakdown '%s'. Valid stages are 1 to %d.", stage, breakdownId, maxStages))
        return
    end

    if registryEntry.isApplicable ~= nil and not registryEntry.isApplicable(vehicle) then
        print(string.format("ADS Error: Breakdown with ID '%s' not applicable to %s", breakdownId, vehicle:getFullName()))
        return
    end
    
    vehicle:addBreakdown(breakdownId, stage)
    print(string.format("ADS: Added breakdown '%s' at stage %d to '%s'.", breakdownId, stage, vehicle:getFullName()))
end

function AdvancedDamageSystem.ConsoleCommands:removeBreakdown(rawArgs)
    if not g_currentMission:getIsServer() then
        local vehicle = self:getTargetVehicle()
        if vehicle then ADS_ConsoleCommandEvent.sendToServer("removeBreakdown", rawArgs, nil, vehicle) end
        return
    end
    local args = parseArguments(rawArgs)
    local vehicle = self:getTargetVehicle()
    if not vehicle then return end

    if args and args[1] then
        local breakdownId = string.upper(args[1])
        vehicle:removeBreakdown(breakdownId)
    else
        vehicle:removeBreakdown() 
    end
end

function AdvancedDamageSystem.ConsoleCommands:changeBreakdownStage(rawArgs)
    if not g_currentMission:getIsServer() then
        local vehicle = self:getTargetVehicle()
        if vehicle then ADS_ConsoleCommandEvent.sendToServer("changeBreakdownStage", rawArgs, nil, vehicle) end
        return
    end
    local args = parseArguments(rawArgs)
    local vehicle = self:getTargetVehicle()
    if not vehicle then return end

    local spec = vehicle.spec_AdvancedDamageSystem
    local advancedCount = 0

    local function parseStageArg(rawValue)
        if rawValue == nil then
            return nil
        end

        local lowered = string.lower(tostring(rawValue))
        if lowered == "true" or lowered == "reverse" or lowered == "down" or lowered == "prev" then
            return true
        end

        local numeric = tonumber(rawValue)
        if numeric ~= nil then
            return numeric
        end

        return nil
    end

    if not args or not args[1] then
        if next(spec.activeBreakdowns) == nil then
            print("ADS: No active breakdowns to advance.")
            return
        end

        for id, breakdown in pairs(vehicle:getActiveBreakdowns()) do
            local previousStage = breakdown.stage
            vehicle:changeBreakdownStage(id)
            if breakdown.stage ~= previousStage then
                print(string.format("ADS: Changed breakdown '%s' from stage %d to stage %d.", id, previousStage, breakdown.stage))
                advancedCount = advancedCount + 1
            else
                print(string.format("ADS: Breakdown '%s' stage unchanged (%d).", id, breakdown.stage))
            end
        end
    else
        local breakdownId = string.upper(args[1])
        local foundBreakdown = spec.activeBreakdowns[breakdownId]

        if not foundBreakdown then
            print(string.format("ADS Error: Active breakdown with ID '%s' not found on this vehicle.", breakdownId))
            return
        end

        local previousStage = foundBreakdown.stage
        vehicle:changeBreakdownStage(breakdownId, parseStageArg(args[2]))
        if foundBreakdown.stage ~= previousStage then
            print(string.format("ADS: Changed breakdown '%s' from stage %d to stage %d.", breakdownId, previousStage, foundBreakdown.stage))
            advancedCount = advancedCount + 1
        else
            print(string.format("ADS: Breakdown '%s' stage unchanged (%d).", breakdownId, foundBreakdown.stage))
        end
    end

    if advancedCount > 0 then
        print(string.format("ADS: Recalculated effects for '%s'.", vehicle:getFullName()))
    end
end

function AdvancedDamageSystem.ConsoleCommands:setSystemCondition(rawArgs, rawArgTwo)
    if not g_currentMission:getIsServer() then
        local vehicle = self:getTargetVehicle()
        if vehicle then ADS_ConsoleCommandEvent.sendToServer("setSystemCondition", rawArgs, rawArgTwo, vehicle) end
        return
    end
    local args = parseArguments(rawArgs, rawArgTwo)
    local vehicle = self:getTargetVehicle()
    if not vehicle then return end
    
    local spec = vehicle.spec_AdvancedDamageSystem

    local function resolveSystemKey(rawSystem)
        if rawSystem == nil or rawSystem == "" then
            return nil
        end

        local normalized = string.lower(rawSystem)
        for key, _ in pairs(spec.systems or {}) do
            if string.lower(tostring(key)) == normalized then
                return key
            end
        end

        return false
    end

    local requestedSystem = args and args[1] or nil
    if requestedSystem == nil then
        print("ADS Error: Missing system. Usage: ads_setSystemCondition [system] [0.0-1.0]")
        return
    end

    local systemKey = resolveSystemKey(requestedSystem)

    if systemKey == false then
        local availableSystems = {}
        for key, _ in pairs(spec.systems or {}) do
            table.insert(availableSystems, tostring(key))
        end
        table.sort(availableSystems)
        print(string.format("ADS Error: Unknown system '%s'. Available systems: %s", tostring(requestedSystem), table.concat(availableSystems, ", ")))
        return
    end

    local value = tonumber(args and args[2] or nil)
    if value == nil or value < 0 or value > 1 then
        print("ADS Error: Invalid value. Please provide a number between 0.0 and 1.0.")
        return
    end

    local systemData = spec.systems[systemKey]
    if type(systemData) == "table" then
        systemData.condition = value
    else
        spec.systems[systemKey] = value
    end
    print(string.format("ADS: Set condition for system '%s' on '%s' to %.2f.", tostring(systemKey), vehicle:getFullName(), value))

    vehicle:updateConditionLevel()
end

function AdvancedDamageSystem.ConsoleCommands:setCondition(rawArgs)
    if not g_currentMission:getIsServer() then
        local vehicle = self:getTargetVehicle()
        if vehicle then ADS_ConsoleCommandEvent.sendToServer("setCondition", rawArgs, nil, vehicle) end
        return
    end

    local args = parseArguments(rawArgs)
    local vehicle = self:getTargetVehicle()
    if not vehicle then
        return
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    local targetCondition = tonumber(args and args[1] or nil)
    if targetCondition == nil or targetCondition < 0 or targetCondition > 1 then
        print("ADS Error: Invalid value. Please provide a number between 0.0 and 1.0.")
        return
    end

    local changedSystems = 0

    for _, systemData in pairs(spec.systems or {}) do
        if type(systemData) == "table" and systemData.enabled ~= false then
            systemData.condition = targetCondition
            changedSystems = changedSystems + 1
        end
    end

    if changedSystems == 0 then
        print("ADS Error: No enabled systems were found on the current vehicle.")
        return
    end

    vehicle:updateConditionLevel()
    print(string.format("ADS: Set condition for %d enabled systems on '%s' to %.3f. Final overall condition: %.3f.",
        changedSystems, vehicle:getFullName(), targetCondition, vehicle.spec_AdvancedDamageSystem.conditionLevel or 0))
end

function AdvancedDamageSystem.ConsoleCommands:setSystemStress(rawArgs, rawArgTwo)
    if not g_currentMission:getIsServer() then
        local vehicle = self:getTargetVehicle()
        if vehicle then ADS_ConsoleCommandEvent.sendToServer("setSystemStress", rawArgs, rawArgTwo, vehicle) end
        return
    end
    local args = parseArguments(rawArgs, rawArgTwo)
    local vehicle = self:getTargetVehicle()
    if not vehicle then return end

    local spec = vehicle.spec_AdvancedDamageSystem

    local function resolveSystemKey(rawSystem)
        if rawSystem == nil or rawSystem == "" then
            return nil
        end

        local normalized = string.lower(rawSystem)
        for key, _ in pairs(spec.systems or {}) do
            if string.lower(tostring(key)) == normalized then
                return key
            end
        end

        return false
    end

    local requestedSystem = args and args[1] or nil
    if requestedSystem == nil then
        print("ADS Error: Missing system. Usage: ads_setSystemStress [system] [>=0.0]")
        return
    end

    local systemKey = resolveSystemKey(requestedSystem)

    if systemKey == false then
        local availableSystems = {}
        for key, _ in pairs(spec.systems or {}) do
            table.insert(availableSystems, tostring(key))
        end
        table.sort(availableSystems)
        print(string.format("ADS Error: Unknown system '%s'. Available systems: %s", tostring(requestedSystem), table.concat(availableSystems, ", ")))
        return
    end

    local value = tonumber(args and args[2] or nil)
    if value == nil or value < 0 then
        print("ADS Error: Invalid value. Please provide a number >= 0.0.")
        return
    end

    local systemData = spec.systems[systemKey]
    if type(systemData) == "table" then
        systemData.stress = value
    else
        spec.systems[systemKey] = { condition = systemData or 1.0, stress = value }
    end
    print(string.format("ADS: Set stress for system '%s' on '%s' to %.4f.", tostring(systemKey), vehicle:getFullName(), value))
end

function AdvancedDamageSystem.ConsoleCommands:setSystemStressMultiplier(rawArgs, rawArgTwo)
    if not g_currentMission:getIsServer() then
        local vehicle = self:getTargetVehicle()
        if vehicle then ADS_ConsoleCommandEvent.sendToServer("setSystemStressMultiplier", rawArgs, rawArgTwo, vehicle) end
        return
    end
    local args = parseArguments(rawArgs, rawArgTwo)
    local vehicle = self:getTargetVehicle()
    if not vehicle then return end

    local spec = vehicle.spec_AdvancedDamageSystem
    local multipliers = ADS_Config.CORE.SYSTEM_STRESS_ACCUMULATION_MULTIPLIERS

    if multipliers == nil then
        print("ADS Error: SYSTEM_STRESS_ACCUMULATION_MULTIPLIERS is missing in config.")
        return
    end

    local value = 1.0
    if args and args[1] then
        local parsedValue = tonumber(args[1])
        if parsedValue == nil or parsedValue < 0 then
            print("ADS Error: Invalid value. Please provide a number >= 0.0.")
            return
        end
        value = parsedValue
    end

    local function resolveSystemKey(rawSystem)
        if rawSystem == nil or rawSystem == "" then
            return nil
        end

        local normalized = string.lower(rawSystem)
        for key, _ in pairs(spec.systems or {}) do
            if string.lower(tostring(key)) == normalized then
                return key
            end
        end

        return false
    end

    local requestedSystem = args and args[2] or nil
    local systemKey = resolveSystemKey(requestedSystem)

    if systemKey == false then
        local availableSystems = {}
        for key, _ in pairs(spec.systems or {}) do
            table.insert(availableSystems, tostring(key))
        end
        table.sort(availableSystems)
        print(string.format("ADS Error: Unknown system '%s'. Available systems: %s", tostring(requestedSystem), table.concat(availableSystems, ", ")))
        return
    end

    if systemKey == nil then
        for key, _ in pairs(multipliers) do
            if type(key) == "string" then
                multipliers[key] = value
            end
        end
        print(string.format("ADS: Set stress accumulation multiplier for all systems to %.4f.", value))
    else
        multipliers[systemKey] = value
        print(string.format("ADS: Set stress accumulation multiplier for system '%s' to %.4f.", tostring(systemKey), value))
    end
end

function AdvancedDamageSystem.ConsoleCommands:setService(rawArgs)
    if not g_currentMission:getIsServer() then
        local vehicle = self:getTargetVehicle()
        if vehicle then ADS_ConsoleCommandEvent.sendToServer("setService", rawArgs, nil, vehicle) end
        return
    end
    local args = parseArguments(rawArgs)
    local vehicle = self:getTargetVehicle()
    if not vehicle then return end
    
    local spec = vehicle.spec_AdvancedDamageSystem
    local value = 1.0

    if args and args[1] then
        local parsedValue = tonumber(args[1])
        if parsedValue == nil or parsedValue < 0 or parsedValue > 1 then
            print("ADS Error: Invalid value. Please provide a number between 0.0 and 1.0.")
            return
        end
        value = parsedValue
    end
    
    spec.serviceLevel = value

    local interval = vehicle:getMaintenanceInterval()
    local currentHours = vehicle:getFormattedOperatingTime()
    local hoursSinceService = (1 - value) * interval
    local targetOpHours = currentHours - hoursSinceService
    local found = false
    for i = #spec.maintenanceLog, 1, -1 do
        local entry = spec.maintenanceLog[i]
        if entry.type == AdvancedDamageSystem.STATUS.MAINTENANCE or entry.id == 1 then
            entry.conditionData.operatingHours = targetOpHours
            entry.conditionData.service = value
            if vehicle.isServer then
                ADS_LogEntrySyncEvent.sendToClients(vehicle, entry)
            end
            found = true
            break
        end
    end
    if not found and vehicle.isServer then
        vehicle:addEntryToMaintenanceLog(AdvancedDamageSystem.STATUS.INSPECTION, AdvancedDamageSystem.INSPECTION_TYPES.STANDARD, "NONE", false, 0)
        local entry = spec.maintenanceLog[#spec.maintenanceLog]
        if entry then
            entry.conditionData.operatingHours = targetOpHours
            entry.conditionData.service = value
            entry.isVisible = false
        end
    end

    print(string.format("ADS: Set Service level for '%s' to %.2f.", vehicle:getFullName(), value))
end

function AdvancedDamageSystem.ConsoleCommands:resetVehicle()
    if not g_currentMission:getIsServer() then
        local vehicle = self:getTargetVehicle()
        if vehicle then ADS_ConsoleCommandEvent.sendToServer("resetVehicle", nil, nil, vehicle) end
        return
    end
    local vehicle = self:getTargetVehicle()
    if not vehicle then return end
    
    local spec = vehicle.spec_AdvancedDamageSystem
    spec.conditionLevel = 1.0
    spec.serviceLevel = 1.0
    vehicle:removeBreakdown()

    local currentHours = vehicle:getFormattedOperatingTime()
    local found = false
    for i = #spec.maintenanceLog, 1, -1 do
        local entry = spec.maintenanceLog[i]
        if entry.type == AdvancedDamageSystem.STATUS.MAINTENANCE or entry.id == 1 then
            entry.conditionData.operatingHours = currentHours
            entry.conditionData.condition = 1.0
            entry.conditionData.service = 1.0
            if vehicle.isServer then
                ADS_LogEntrySyncEvent.sendToClients(vehicle, entry)
            end
            found = true
            break
        end
    end
    if not found and vehicle.isServer then
        vehicle:addEntryToMaintenanceLog(AdvancedDamageSystem.STATUS.INSPECTION, AdvancedDamageSystem.INSPECTION_TYPES.STANDARD, "NONE", false, 0)
        local entry = spec.maintenanceLog[#spec.maintenanceLog]
        if entry then
            entry.conditionData.operatingHours = currentHours
            entry.conditionData.condition = 1.0
            entry.conditionData.service = 1.0
            entry.isVisible = false
        end
    end

    print(string.format("ADS: Fully reset state for '%s'.", vehicle:getFullName()))
end

function AdvancedDamageSystem.ConsoleCommands:reinitializeVehicle()
    if not g_currentMission:getIsServer() then
        local vehicle = self:getTargetVehicle()
        if vehicle then ADS_ConsoleCommandEvent.sendToServer("reinitializeVehicle", nil, nil, vehicle) end
        return
    end

    local vehicle = self:getTargetVehicle()
    if not vehicle then return end

    local ok, targetCondition = initializeVehicleConditionFromVanillaPrice(vehicle, true)
    if not ok then
        print(string.format("ADS Error: Failed to reinitialize '%s'.", vehicle:getFullName()))
        return
    end

    print(string.format(
        "ADS: Reinitialized '%s' from vanilla resale price. Target condition: %.3f, final overall condition: %.3f.",
        vehicle:getFullName(),
        targetCondition or 0,
        vehicle.spec_AdvancedDamageSystem.conditionLevel or 0
    ))
end

function AdvancedDamageSystem.ConsoleCommands:startMaintance(rawArgs, rawArgTwo)
    if not g_currentMission:getIsServer() then
        local vehicle = self:getTargetVehicle()
        if vehicle then ADS_ConsoleCommandEvent.sendToServer("startMaintance", rawArgs, rawArgTwo, vehicle) end
        return
    end
    local args = parseArguments(rawArgs, rawArgTwo)
    local vehicle = self:getTargetVehicle()
    if not vehicle then return end

    local spec = vehicle.spec_AdvancedDamageSystem
    if spec.currentState ~= AdvancedDamageSystem.STATUS.READY then
        print(string.format("ADS Error: Vehicle '%s' is already under service (%s).", vehicle:getFullName(), spec.currentState))
        return
    end

    if not args or not args[1] then
        print("ADS Error: Missing argument. Usage: ads_startService <type> [count]")
        print("Available types: inspection, maintenance, repair, overhaul")
        return
    end

    local maintenanceType = string.lower(args[1])
    local isValidType = false

    for stateName, state in pairs(AdvancedDamageSystem.STATUS) do
        if string.lower(stateName) == maintenanceType then
            isValidType = true
            maintenanceType = state
            break
        end
    end
    
    if not isValidType or maintenanceType == AdvancedDamageSystem.STATUS.READY then
        print("ADS Error: Invalid maintenance type '"..maintenanceType.."'")
        print("Available types: inspection, maintenance, repair, overhaul")
        return
    end

    local breakdownCount = tonumber(args[2]) or 1
    local optionOne, optionTwo, optionThree

    if maintenanceType == AdvancedDamageSystem.STATUS.INSPECTION then
        optionOne = AdvancedDamageSystem.INSPECTION_TYPES.STANDARD
        optionTwo = "NONE"
        optionThree = false
    elseif maintenanceType == AdvancedDamageSystem.STATUS.MAINTENANCE then
        optionOne = AdvancedDamageSystem.MAINTENANCE_TYPES.STANDARD
        optionTwo = AdvancedDamageSystem.PART_TYPES.OEM
        optionThree = false
    elseif maintenanceType == AdvancedDamageSystem.STATUS.REPAIR then
        optionOne = AdvancedDamageSystem.REPAIR_TYPES.MEDIUM
        optionTwo = AdvancedDamageSystem.PART_TYPES.OEM
        optionThree = false

        local visibleRepairableCount = 0
        local selected = 0
        for breakdownId, breakdown in pairs(vehicle:getActiveBreakdowns()) do
            local isRepairable = breakdown ~= nil and breakdown.isVisible == true
            if isRepairable then
                visibleRepairableCount = visibleRepairableCount + 1
            end

            if selected < breakdownCount and isRepairable then
                breakdown.isSelectedForRepair = true
                selected = selected + 1
            else
                breakdown.isSelectedForRepair = false
            end
        end

        if visibleRepairableCount == 0 then
            print(string.format("ADS Error: Vehicle '%s' has no visible breakdowns for repair.", vehicle:getFullName()))
            return
        end

        if selected == 0 then
            print(string.format("ADS Error: No breakdowns selected for repair on '%s'.", vehicle:getFullName()))
            return
        end
    elseif maintenanceType == AdvancedDamageSystem.STATUS.OVERHAUL then
        optionOne = AdvancedDamageSystem.OVERHAUL_TYPES.STANDARD
        optionTwo = "NONE"
        optionThree = false
    end

    vehicle:initService(maintenanceType, AdvancedDamageSystem.WORKSHOP.OWN, optionOne, optionTwo, optionThree)

    if spec.currentState == maintenanceType and (spec.maintenanceTimer or 0) > 0 then
        local finishTime, days = vehicle:getServiceFinishTime()
        print(string.format("ADS: Started '%s' for '%s'. Remaining time: %.1f sec. Finishes in %d day(s) at %.2f.", maintenanceType, vehicle:getFullName(), spec.maintenanceTimer / 1000, days or 0, finishTime or 0))
    else
        print(string.format("ADS Error: Failed to start '%s' for '%s'.", maintenanceType, vehicle:getFullName()))
    end
end

function AdvancedDamageSystem.ConsoleCommands:finishMaintance()
    if not g_currentMission:getIsServer() then
        local vehicle = self:getTargetVehicle()
        if vehicle then ADS_ConsoleCommandEvent.sendToServer("finishMaintance", nil, nil, vehicle) end
        return
    end
    local vehicle = self:getTargetVehicle()
    if not vehicle then return end

    local spec = vehicle.spec_AdvancedDamageSystem
    if spec.currentState == AdvancedDamageSystem.STATUS.READY then
        print(string.format("ADS: Vehicle '%s' is not under service.", vehicle:getFullName()))
        return
    end

    local currentState = spec.currentState
    local remainingMs = math.max(spec.maintenanceTimer or 0, 0)
    local missionInfo = g_currentMission and g_currentMission.missionInfo or nil
    local timeScale = (missionInfo and missionInfo.timeScale) or 1
    if timeScale <= 0 then
        timeScale = 1
    end
    local forceDt = math.max(math.ceil(remainingMs / timeScale) + 1, 1)

    local previousWorkshopOpen = nil
    if ADS_Main ~= nil then
        previousWorkshopOpen = ADS_Main.isWorkshopOpen
        ADS_Main.isWorkshopOpen = true
    end

    local ok, err = pcall(function()
        vehicle:processService(forceDt)
    end)

    if ADS_Main ~= nil and previousWorkshopOpen ~= nil then
        ADS_Main.isWorkshopOpen = previousWorkshopOpen
    end

    if not ok then
        print(string.format("ADS Error: Failed to force-finish service for '%s': %s", vehicle:getFullName(), tostring(err)))
        return
    end

    if spec.currentState ~= AdvancedDamageSystem.STATUS.READY then
        -- Fallback for rare edge-cases where processService didn't finalize.
        spec.pendingProgressElapsedTime = spec.pendingProgressTotalTime or 0
        spec.maintenanceTimer = 0
        vehicle:completeService()
    end

    print(string.format("ADS: Service '%s' force-finished for '%s'.", currentState, vehicle:getFullName()))
end

function AdvancedDamageSystem.ConsoleCommands:getServiceState()
    local vehicle = self:getTargetVehicle()
    if not vehicle then return end

    local spec = vehicle.spec_AdvancedDamageSystem
    local progressPercent = 0
    if (spec.pendingProgressTotalTime or 0) > 0 then
        progressPercent = math.floor(math.max(0, math.min((spec.pendingProgressElapsedTime or 0) / spec.pendingProgressTotalTime, 1)) * 100)
    end

    local selectedForRepairCount = 0
    local activeBreakdownsCount = 0
    for _, breakdown in pairs(spec.activeBreakdowns or {}) do
        activeBreakdownsCount = activeBreakdownsCount + 1
        if breakdown ~= nil and breakdown.isSelectedForRepair then
            selectedForRepairCount = selectedForRepairCount + 1
        end
    end

    print("--- ADS Service State ---")
    print(string.format("Vehicle: %s", vehicle:getFullName()))
    print(string.format("State: current=%s planned=%s workshop=%s", tostring(spec.currentState), tostring(spec.plannedState), tostring(spec.workshopType)))
    print(string.format("Timer: maintenanceTimer=%.0fms elapsed=%.0fms total=%.0fms progress=%d%% stepIndex=%d",
        spec.maintenanceTimer or 0, spec.pendingProgressElapsedTime or 0, spec.pendingProgressTotalTime or 0, progressPercent, spec.pendingProgressStepIndex or 0))
    print(string.format("Options: optionOne=%s optionTwo=%s optionThree=%s price=%s",
        tostring(spec.serviceOptionOne), tostring(spec.serviceOptionTwo), tostring(spec.serviceOptionThree), tostring(spec.pendingServicePrice)))
    local pendingOverhaulSystemsCount = 0
    for _, _ in pairs(spec.pendingOverhaulSystemTarget or {}) do
        pendingOverhaulSystemsCount = pendingOverhaulSystemsCount + 1
    end

    print(string.format("Targets: serviceStart=%s serviceTarget=%s overhaulSystems=%d",
        tostring(spec.pendingMaintenanceServiceStart), tostring(spec.pendingMaintenanceServiceTarget), pendingOverhaulSystemsCount))
    print(string.format("Levels: service=%.4f condition=%.4f", spec.serviceLevel or 0, spec.conditionLevel or 0))
    print(string.format("Queues: selected=%d inspection=%d repair=%d", #(spec.pendingSelectedBreakdowns or {}), #(spec.pendingInspectionQueue or {}), #(spec.pendingRepairQueue or {})))
    print(string.format("Breakdowns: active=%d selectedForRepair=%d", activeBreakdownsCount, selectedForRepairCount))

    if #(spec.pendingSelectedBreakdowns or {}) > 0 then
        print("pendingSelectedBreakdowns: " .. table.concat(spec.pendingSelectedBreakdowns, ", "))
    end
    if #(spec.pendingInspectionQueue or {}) > 0 then
        print("pendingInspectionQueue: " .. table.concat(spec.pendingInspectionQueue, ", "))
    end
    if #(spec.pendingRepairQueue or {}) > 0 then
        print("pendingRepairQueue: " .. table.concat(spec.pendingRepairQueue, ", "))
    end
end

function AdvancedDamageSystem.ConsoleCommands:showServiceLog(rawArgs)
    local vehicle = self:getTargetVehicle()
    if not vehicle then return end

    local spec = vehicle.spec_AdvancedDamageSystem
    local log = spec.maintenanceLog or {}
    local args = parseArguments(rawArgs)

    if #log == 0 then
        print("ADS: Service log is empty.")
        return
    end

    local function formatDate(date)
        if date == nil then
            return "n/a"
        end
        return string.format("%02d/%02d/%04d", date.day or 0, date.month or 0, date.year or 0)
    end

    local function formatList(value)
        if value == nil or #value == 0 then
            return "-"
        end
        return table.concat(value, ", ")
    end

    local function printLogEntry(index, entry, verbose)
        local cond = entry.conditionData or {}
        local selectedBreakdowns = cond.selectedBreakdowns or {}
        local activeBreakdownsCount = 0
        for _, _ in pairs(cond.activeBreakdowns or {}) do
            activeBreakdownsCount = activeBreakdownsCount + 1
        end

        print(string.format("[%d] id=%s type=%s date=%s price=%s visible=%s completed=%s",
            index, tostring(entry.id), tostring(entry.type), formatDate(entry.date), tostring(entry.price), tostring(entry.isVisible), tostring(entry.isCompleted ~= false)))
        print(string.format("    options: one=%s two=%s three=%s location=%s",
            tostring(entry.optionOne), tostring(entry.optionTwo), tostring(entry.optionThree), tostring(entry.location)))

        if verbose then
            print(string.format("    conditionData: year=%s opHours=%s age=%s condition=%s service=%s reliability=%s maintainability=%s",
                tostring(cond.year), tostring(cond.operatingHours), tostring(cond.age), tostring(cond.condition), tostring(cond.service), tostring(cond.reliability), tostring(cond.maintainability)))
            local systemsCount = 0
            for _, _ in pairs(cond.systems or {}) do
                systemsCount = systemsCount + 1
            end
            print(string.format("    conditionData: batterySoc=%s systems=%d",
                tostring(cond.batterySoc), systemsCount))
            print(string.format("    conditionData: activeBreakdowns=%d selectedBreakdowns=%d", activeBreakdownsCount, #selectedBreakdowns))
            print("    selectedBreakdowns: " .. formatList(selectedBreakdowns))
        end
    end

    if args ~= nil and args[1] ~= nil then
        local index = tonumber(args[1])
        if index == nil or index < 1 or index > #log then
            print(string.format("ADS Error: Invalid log index '%s'. Valid range: 1..%d", tostring(args[1]), #log))
            return
        end

        print(string.format("--- ADS Service Log Entry %d/%d ---", index, #log))
        printLogEntry(index, log[index], true)
        return
    end

    print(string.format("--- ADS Service Log (%d entries) ---", #log))
    for i, entry in ipairs(log) do
        printLogEntry(i, entry, false)
    end
end

function AdvancedDamageSystem.ConsoleCommands:getDebugVehicleInfo(rawArgs)
    local args = parseArguments(rawArgs)
    local vehicle = self:getTargetVehicle()
    if not vehicle then return end
    
    local spec = vehicle.spec_AdvancedDamageSystem
    local motor = vehicle:getMotor()

    local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
    print("--- Vehicle Debug Info ---")
    print(string.format("RawBrand: %s", g_brandManager:getBrandByIndex(vehicle:getBrand()).name))
    print(string.format("Name: %s", vehicle:getFullName()))
    print(string.format("Type/Category: %s/%s", vehicle.type.name, storeItem.categoryName))
    print(string.format("Property state: %s", vehicle.propertyState))
    print(string.format("Transmission: %s, %s, %s", motor.minForwardGearRatio, motor.gearType, motor.groupType))

    local hasTurboBaseSound = false
    local hasTurboCurrentConfigSound = false
    local hasTurboAnyConfigSound = false
    local hasTurboLoadedSample = false
    local turboMotorConfigKey = "-"
    local turboConfigIndices = {}
    local motorConfigCount = 0

    if vehicle.xmlFile ~= nil and vehicle.xmlFile.hasProperty ~= nil then
        hasTurboBaseSound = vehicle.xmlFile:hasProperty("vehicle.motorized.sounds.blowOffValve")

        local motorConfigIndex = 1
        if vehicle.configurations ~= nil and vehicle.configurations.motor ~= nil then
            motorConfigIndex = math.max(tonumber(vehicle.configurations.motor) or 1, 1)
        end

        turboMotorConfigKey = string.format("vehicle.motorized.motorConfigurations.motorConfiguration(%d)", motorConfigIndex - 1)
        hasTurboCurrentConfigSound = vehicle.xmlFile:hasProperty(turboMotorConfigKey .. ".sounds.blowOffValve")

        local maxScanCount = 64
        for idx = 0, maxScanCount - 1 do
            local cfgKey = string.format("vehicle.motorized.motorConfigurations.motorConfiguration(%d)", idx)
            if not vehicle.xmlFile:hasProperty(cfgKey) then
                break
            end

            motorConfigCount = motorConfigCount + 1
            if vehicle.xmlFile:hasProperty(cfgKey .. ".sounds.blowOffValve") then
                hasTurboAnyConfigSound = true
                table.insert(turboConfigIndices, tostring(idx + 1))
            end
        end
    end

    local spec_motorized = vehicle.spec_motorized
    if spec_motorized ~= nil and spec_motorized.samples ~= nil then
        hasTurboLoadedSample = spec_motorized.samples.blowOffValve ~= nil
    end

    local turboConfigList = (#turboConfigIndices > 0) and table.concat(turboConfigIndices, ",") or "-"
    local hasTurbo = hasTurboBaseSound or hasTurboCurrentConfigSound or hasTurboAnyConfigSound or hasTurboLoadedSample
    print(string.format(
        "Turbo detect: %s | base=%s | cfgCurrent=%s | cfgAny=%s (%s/%d) | sample=%s | motorCfgKey=%s",
        tostring(hasTurbo),
        tostring(hasTurboBaseSound),
        tostring(hasTurboCurrentConfigSound),
        tostring(hasTurboAnyConfigSound),
        turboConfigList,
        motorConfigCount,
        tostring(hasTurboLoadedSample),
        tostring(turboMotorConfigKey)
    ))

    for _, entry in ipairs(spec.maintenanceLog) do
        for _, breakdown in pairs(entry.conditionData.selectedBreakdowns) do
            print(breakdown)
        end
    end

    if vehicle.spec_attacherJoints and vehicle.spec_attacherJoints.attachedImplements then
        for _, v in pairs(vehicle.spec_attacherJoints.attachedImplements) do
            if v.object.speedLimit ~= nil then
                print(v.object:getFullName() .. " " .. v.object.speedLimit)
            end
	    end
    end

    if args and args[1] then
        print("--------------------------")

        if vehicle.type and vehicle.type.specializationNames then
            local specNamesCopy = {}
            for _, specName in ipairs(vehicle.type.specializationNames) do
                table.insert(specNamesCopy, specName)
            end
            
            table.sort(specNamesCopy)
            
            print("Attached Specializations (" .. #specNamesCopy .. " total):")
            for i, specName in ipairs(specNamesCopy) do
                print(string.format("  %d. %s", i, specName))
            end
        else
            print("No specializations found for this vehicle type.")
        end
        
        print("--------------------------")
    end
end

function AdvancedDamageSystem.ConsoleCommands:setDirtAmount(rawArgs)
    if not g_currentMission:getIsServer() then
        local vehicle = self:getTargetVehicle()
        if vehicle then ADS_ConsoleCommandEvent.sendToServer("setDirtAmount", rawArgs, nil, vehicle) end
        return
    end
    local vehicle = self:getTargetVehicle()
    if not vehicle then
        print("ADS Error: No target vehicle found. Please enter a vehicle.")
        return 
    end

    if vehicle.spec_washable == nil then
        print(string.format("ADS Error: Vehicle '%s' is not washable.", vehicle:getFullName()))
        return
    end

    local args = parseArguments(rawArgs)
    
    if not args or not args[1] then
        print("ADS Error: Missing argument. Usage: ads_setDirtAmount <amount>")
        print("Please provide a dirt amount between 0.0 (clean) and 1.0 (fully dirty).")
        return
    end

    local value = tonumber(args[1])
    if value == nil or value < 0 or value > 1 then
        print("ADS Error: Invalid value. Please provide a number between 0.0 and 1.0.")
        return
    end
    
    vehicle:setDirtAmount(value)
    
    print(string.format("ADS: Set Dirt amount for '%s' to %.2f.", vehicle:getFullName(), value))
end

function AdvancedDamageSystem.ConsoleCommands:setFuelLevel(rawArgs)
    if not g_currentMission:getIsServer() then
        local vehicle = self:getTargetVehicle()
        if vehicle then ADS_ConsoleCommandEvent.sendToServer("setFuelLevel", rawArgs, nil, vehicle) end
        return
    end
    local vehicle = self:getTargetVehicle()
    if not vehicle then
        return
    end

    local args = parseArguments(rawArgs)
    if not args or not args[1] then
        print("ADS Error: Usage: ads_setFuelLevel <value>")
        print("Value: 0.0..1.0 or 0..100 (percent)")
        print("Example: ads_setFuelLevel 0.25")
        print("Example: ads_setFuelLevel 25")
        return
    end

    local inputValue = tonumber(args[1])
    if inputValue == nil then
        print("ADS Error: Invalid value. Expected number.")
        return
    end

    if inputValue > 1 then
        if inputValue <= 100 then
            inputValue = inputValue / 100
        else
            print("ADS Error: Value must be 0.0..1.0 or 0..100.")
            return
        end
    end

    if inputValue < 0 or inputValue > 1 then
        print("ADS Error: Value must be between 0.0 and 1.0 (or 0..100%).")
        return
    end

    local fillUnitIndex, fillType = getPrimaryFuelConsumerInfo(vehicle)
    if fillUnitIndex == nil or fillType == nil then
        print(string.format("ADS Error: Fuel consumer not found for '%s'.", vehicle:getFullName()))
        return
    end

    local capacity = tonumber(vehicle:getFillUnitCapacity(fillUnitIndex)) or 0
    if capacity <= 0 then
        print(string.format("ADS Error: Invalid fuel capacity for '%s' (fillUnit %s).", vehicle:getFullName(), tostring(fillUnitIndex)))
        return
    end

    local currentLevel = tonumber(vehicle:getFillUnitFillLevel(fillUnitIndex)) or 0
    local targetLevel = math.clamp(capacity * inputValue, 0, capacity)
    local delta = targetLevel - currentLevel

    if math.abs(delta) > 0.0001 then
        vehicle:addFillUnitFillLevel(vehicle:getOwnerFarmId(), fillUnitIndex, delta, fillType, ToolType.UNDEFINED)
    end

    local resultLevel = tonumber(vehicle:getFillUnitFillLevel(fillUnitIndex)) or targetLevel
    local resultRatio = resultLevel / math.max(capacity, 0.0001)
    print(string.format(
        "ADS: Fuel level set on '%s' -> %.1f / %.1f L (%.1f%%), fillType=%s, fillUnit=%s",
        vehicle:getFullName(),
        resultLevel,
        capacity,
        resultRatio * 100,
        tostring(fillType),
        tostring(fillUnitIndex)
    ))
end

function AdvancedDamageSystem.ConsoleCommands:resetFactorStats()
    if not g_currentMission:getIsServer() then
        local vehicle = self:getTargetVehicle()
        if vehicle then ADS_ConsoleCommandEvent.sendToServer("resetFactorStats", nil, nil, vehicle) end
        return
    end
    local vehicle = self:getTargetVehicle()
    if not vehicle then
        return
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    local factorStats = ensureFactorStats(spec, vehicle)

    for _, systemStats in pairs(factorStats) do
        if type(systemStats) == "table" then
            for key, value in pairs(systemStats) do
                if key ~= "operatingHours" and tonumber(value) ~= nil then
                    systemStats[key] = 0
                end
            end
            systemStats.total = 0
            systemStats.stress = 0
            systemStats.operatingHours = getVehicleOperatingHours(vehicle)
        end
    end

    print(string.format("ADS: Factor stats reset for '%s'.", vehicle:getFullName()))
end

function AdvancedDamageSystem.ConsoleCommands:toggleHudDebugView(rawArgs)
    local args = parseArguments(rawArgs)
    local requestedMode = args and args[1] and string.lower(tostring(args[1])) or nil
    local currentMode = tostring((ADS_Hud ~= nil and ADS_Hud.debugViewMode) or "default")
    local nextMode = "default"

    if requestedMode == nil or requestedMode == "" or requestedMode == "toggle" then
        if currentMode == "factorStats" then
            nextMode = "default"
        else
            nextMode = "factorStats"
        end
    elseif requestedMode == "default" or requestedMode == "normal" then
        nextMode = "default"
    elseif requestedMode == "stats" or requestedMode == "stat" or requestedMode == "factorstats" or requestedMode == "factor_stats" then
        nextMode = "factorStats"
    else
        print("ADS Error: Usage: ads_toggleHudDebugView [default|stats|toggle]")
        return
    end

    if ADS_Hud ~= nil then
        ADS_Hud.debugViewMode = nextMode
    end

    print(string.format("ADS: HUD debug view mode = %s", nextMode))
end

function AdvancedDamageSystem.ConsoleCommands:debug()
    if not g_currentMission:getIsServer() then
        ADS_ConsoleCommandEvent.sendToServer("debug", nil, nil, nil)
        return
    end
    if ADS_Config.DEBUG then
        ADS_Config.DEBUG = false
    else
        ADS_Config.DEBUG = true
    end
end

addConsoleCommand("ads_listBreakdowns", "Lists all available breakdown IDs.", "listBreakdowns", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_addBreakdown", "Adds a breakdown. Usage: ads_addBreakdown [id] [stage]", "addBreakdown", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_removeBreakdown", "Removes a breakdown. Usage: ads_removeBreakdown [id]", "removeBreakdown", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_advanceBreakdown", "Advances a breakdown to the next stage. Usage: ads_advanceBreakdown [id]", "changeBreakdownStage", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_setCondition", "Sets condition for all enabled systems. Usage: ads_setCondition [0.0-1.0]", "setCondition", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_setSystemCondition", "Sets system condition. Usage: ads_setSystemCondition [system] [0.0-1.0]", "setSystemCondition", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_setSystemStress", "Sets system stress. Usage: ads_setSystemStress [system] [>=0.0]", "setSystemStress", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_setSystemStressMultiplier", "Sets stress accumulation multiplier. Usage: ads_setSystemStressMultiplier [>=0.0] [system]", "setSystemStressMultiplier", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_setService", "Sets vehicle service. Usage: ads_setService [0.0-1.0]", "setService", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_resetVehicle", "Resets vehicle state.", "resetVehicle", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_reinitializeVehicle", "Reinitializes vehicle from vanilla resale price logic.", "reinitializeVehicle", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_startService", "Starts service. Usage: ads_startService <type> [count]", "startMaintance", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_finishService", "Instantly finishes current service.", "finishMaintance", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_getServiceState", "Prints current service/workshop state variables.", "getServiceState", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_showServiceLog", "Shows service log. Usage: ads_showServiceLog [index]", "showServiceLog", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_getDebugVehicleInfo", "Vehicle debug info", "getDebugVehicleInfo", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_setDirtAmount", "Sets vehicle dirt amount. Usage: ads_setDirtAmount [0.0-1.0]", "setDirtAmount", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_setFuelLevel", "Sets vehicle fuel level. Usage: ads_setFuelLevel [0.0-1.0 or 0..100]", "setFuelLevel", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_resetFactorStats", "Resets accumulated factor stats for current vehicle.", "resetFactorStats", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_toggleHudDebugView", "Switch debug HUD view. Usage: ads_toggleHudDebugView [default|stats|toggle]", "toggleHudDebugView", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_debug", "Enbales/disabled ADS debug", "debug", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_setConfigVar", "Sets ADS_Config variable. Usage: ads_setConfigVar <path> <value>", "setConfigVar", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_setSpecVar", "Sets ADS specialization variable on current vehicle. Usage: ads_setSpecVar <path> <value>", "setSpecVar", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_printSpecVar", "Prints ADS specialization variable on current vehicle. Usage: ads_printSpecVar <path>", "printSpecVar", AdvancedDamageSystem.ConsoleCommands)






