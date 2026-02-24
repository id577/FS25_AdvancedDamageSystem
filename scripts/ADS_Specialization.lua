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
    [1] = "ads_spec_maintenance_standard",
    [2] = "ads_spec_maintenance_minimal",
    [3] = "ads_spec_maintenance_extended",
},

REPAIR_URGENCY = {
    MEDIUM = "ads_spec_repair_urgency_medium",
    LOW    = "ads_spec_repair_urgency_low",
    HIGH   = "ads_spec_repair_urgency_high",
    [1] = "ads_spec_repair_urgency_medium",
    [2] = "ads_spec_repair_urgency_low",
    [3] = "ads_spec_repair_urgency_high",
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

local function log_dbg(...)
    if ADS_Config and ADS_Config.DEBUG then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i])
        end
        print("[ADS_SPEC] " .. table.concat(args, " "))
    end
end

local function normalizeBoolValue(value, defaultValue)
    if value == nil then
        return defaultValue == true
    end

    if type(value) == "boolean" then
        return value
    end

    if type(value) == "number" then
        return value ~= 0
    end

    if type(value) == "string" then
        local v = string.lower(value)
        if v == "false" or v == "0" or v == "off" or v == "no" then
            return false
        end
        if v == "true" or v == "1" or v == "on" or v == "yes" then
            return true
        end
    end

    return value and true or false
end

local function normalizeNumberValue(value, defaultValue)
    if value == nil then
        return defaultValue
    end

    local num = tonumber(value)
    if num == nil then
        return defaultValue
    end

    return num
end

local SAVEGAME_OPTIONAL_FLOAT_SENTINEL = -1

local function encodeOptionalFloat(value)
    if value == nil then
        return SAVEGAME_OPTIONAL_FLOAT_SENTINEL
    end

    local num = tonumber(value)
    if num == nil then
        return SAVEGAME_OPTIONAL_FLOAT_SENTINEL
    end

    return num
end

local function decodeOptionalFloat(value)
    local num = tonumber(value)
    if num == nil or num < 0 then
        return nil
    end

    return num
end

local function parseCsvList(csvString)
    local result = {}
    if csvString == nil or csvString == "" then
        return result
    end

    for item in string.gmatch(csvString, "([^,]+)") do
        local trimmed = tostring(item):gsub("^%s+", ""):gsub("%s+$", "")
        if trimmed ~= "" then
            table.insert(result, trimmed)
        end
    end

    return result
end

-- ==========================================================
--                    SAVE/LOAD & REGISTRATION
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
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#lastServiceDate", "Last Service Date")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#lastInspectionDate", "Last Inspection Date")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#lastServiceOpHours", "Last Service Operating Hours")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#lastInspCond", "Last Inspected Condition State")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#lastInspServ", "Last Inspected Service State")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#lastInspPwr", "Last Inspected Power")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#lastInspBrk", "Last Inspected Brake")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#lastInspYld", "Last Inspected Yield Reduction")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#serviceOptionOne", "Current Service Option One")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#serviceOptionTwo", "Current Service Option Two")
    schemaSavegame:register(XMLValueType.BOOL,   baseKey .. "#serviceOptionThree", "Current Service Option Three")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#pendingSelectedBreakdowns", "Pending Selected Breakdowns")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#pendingServicePrice", "Pending Service Price")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#pendingInspectionQueue", "Pending Inspection Queue")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#pendingRepairQueue", "Pending Repair Queue")
    schemaSavegame:register(XMLValueType.INT,    baseKey .. "#pendingProgressStepIndex", "Pending Progress Step Index")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#pendingProgressTotalTime", "Pending Progress Total Time")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#pendingProgressElapsedTime", "Pending Progress Elapsed Time")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#pendingMaintenanceServiceStart", "Pending Maintenance Service Start")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#pendingMaintenanceServiceTarget", "Pending Maintenance Service Target")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#pendingOverhaulConditionStart", "Pending Overhaul Condition Start")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#pendingOverhaulConditionTarget", "Pending Overhaul Condition Target")
    schemaSavegame:register(XMLValueType.INT,    baseKey .. "#totalBreakdownsOccurred", "Total Breakdowns Occurred")
    
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
    
    schema:setXMLSpecializationType()
end


function AdvancedDamageSystem.registerEventListeners(vehicleType)
    log_dbg("registerEventListeners called for vehicleType:", vehicleType.name)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AdvancedDamageSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AdvancedDamageSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", AdvancedDamageSystem)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AdvancedDamageSystem)
    SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", AdvancedDamageSystem)
end

function AdvancedDamageSystem.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanMotorRun", ADS_Breakdowns.getCanMotorRun)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "startMotor", ADS_Breakdowns.startMotor)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateDamageAmount", ADS_Breakdowns.updateDamageAmount)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setLightsTypesMask", ADS_Breakdowns.setLightsTypesMask)
end


function AdvancedDamageSystem.registerFunctions(vehicleType)
    log_dbg("registerFunctions called for vehicleType:", vehicleType.name)
    SpecializationUtil.registerFunction(vehicleType, "adsUpdate", AdvancedDamageSystem.adsUpdate)
	
    SpecializationUtil.registerFunction(vehicleType, "recalculateAndApplyEffects", AdvancedDamageSystem.recalculateAndApplyEffects)
    SpecializationUtil.registerFunction(vehicleType, "recalculateAndApplyIndicators", AdvancedDamageSystem.recalculateAndApplyIndicators)
    
    SpecializationUtil.registerFunction(vehicleType, "checkForNewBreakdown", AdvancedDamageSystem.checkForNewBreakdown)
    SpecializationUtil.registerFunction(vehicleType, "getRandomBreakdown", AdvancedDamageSystem.getRandomBreakdown)
    SpecializationUtil.registerFunction(vehicleType, "addBreakdown", AdvancedDamageSystem.addBreakdown)
    SpecializationUtil.registerFunction(vehicleType, "removeBreakdown", AdvancedDamageSystem.removeBreakdown)
    SpecializationUtil.registerFunction(vehicleType, "hasBreakdown", AdvancedDamageSystem.hasBreakdown)
    SpecializationUtil.registerFunction(vehicleType, "processBreakdowns", AdvancedDamageSystem.processBreakdowns)
    SpecializationUtil.registerFunction(vehicleType, "advanceBreakdown", AdvancedDamageSystem.advanceBreakdown)
    SpecializationUtil.registerFunction(vehicleType, "getActiveBreakdowns", AdvancedDamageSystem.getActiveBreakdowns)
    
    SpecializationUtil.registerFunction(vehicleType, "initService", AdvancedDamageSystem.initService)
    SpecializationUtil.registerFunction(vehicleType, "processService", AdvancedDamageSystem.processService)
    SpecializationUtil.registerFunction(vehicleType, "completeService", AdvancedDamageSystem.completeService)
    SpecializationUtil.registerFunction(vehicleType, "cancelService", AdvancedDamageSystem.cancelService)

    SpecializationUtil.registerFunction(vehicleType, "getServiceLevel", AdvancedDamageSystem.getServiceLevel)
    SpecializationUtil.registerFunction(vehicleType, "getConditionLevel", AdvancedDamageSystem.getConditionLevel)
    SpecializationUtil.registerFunction(vehicleType, "updateServiceLevel", AdvancedDamageSystem.updateServiceLevel)
    SpecializationUtil.registerFunction(vehicleType, "updateConditionLevel", AdvancedDamageSystem.updateConditionLevel)
    SpecializationUtil.registerFunction(vehicleType, "updateConditionLevelCVTAddon", AdvancedDamageSystem.updateConditionLevelCVTAddon)
    SpecializationUtil.registerFunction(vehicleType, "calculateWearRates", AdvancedDamageSystem.calculateWearRates)
    
    SpecializationUtil.registerFunction(vehicleType, "isUnderService", AdvancedDamageSystem.isUnderService)
    SpecializationUtil.registerFunction(vehicleType, "getCurrentStatus", AdvancedDamageSystem.getCurrentStatus)
    
    SpecializationUtil.registerFunction(vehicleType, "updateThermalSystems", AdvancedDamageSystem.updateThermalSystems)
    SpecializationUtil.registerFunction(vehicleType, "updateEngineThermalModel", AdvancedDamageSystem.updateEngineThermalModel)
    SpecializationUtil.registerFunction(vehicleType, "updateTransmissionThermalModel", AdvancedDamageSystem.updateTransmissionThermalModel)

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
    SpecializationUtil.registerFunction(vehicleType, "getLastServiceOptions", AdvancedDamageSystem.getLastServiceOptions)
end


function AdvancedDamageSystem:saveToXMLFile(xmlFile, key, usedModNames)
    log_dbg("saveToXMLFile called for vehicle:", self:getFullName(), "with key:", key)
    local spec = self.spec_AdvancedDamageSystem
    if spec ~= nil then
        xmlFile:setValue(key .. "#service", spec.serviceLevel)
        xmlFile:setValue(key .. "#condition", spec.conditionLevel)
        
        local breakdownString = ADS_Utils.serializeBreakdowns(spec.activeBreakdowns)
        xmlFile:setValue(key .. "#breakdowns", breakdownString)
        xmlFile:setValue(key .. "#state", spec.currentState)
        xmlFile:setValue(key .. "#plannedState", spec.plannedState)
        xmlFile:setValue(key .. "#maintenanceTimer", spec.maintenanceTimer)
        xmlFile:setValue(key .. "#lastServiceDate", ADS_Utils.serializeDate(spec.lastServiceDate))
        xmlFile:setValue(key .. "#lastInspectionDate", ADS_Utils.serializeDate(spec.lastInspectionDate))
        xmlFile:setValue(key .. "#lastServiceOpHours", spec.lastServiceOperatingHours)
        xmlFile:setValue(key .. "#lastInspCond", spec.lastInspectedConditionState)
        xmlFile:setValue(key .. "#lastInspServ", spec.lastInspectedServiceState)
        xmlFile:setValue(key .. "#engineTemperature", spec.engineTemperature)
        xmlFile:setValue(key .. "#transmissionTemperature", spec.transmissionTemperature)
        xmlFile:setValue(key .. "#lastInspPwr", spec.lastInspectedPower)
        xmlFile:setValue(key .. "#lastInspBrk", spec.lastInspectedBrake)
        xmlFile:setValue(key .. "#lastInspYld", spec.lastInspectedYieldReduction)
        xmlFile:setValue(key .. "#serviceOptionOne", spec.serviceOptionOne or "")
        xmlFile:setValue(key .. "#serviceOptionTwo", spec.serviceOptionTwo or "")
        xmlFile:setValue(key .. "#serviceOptionThree", spec.serviceOptionThree)
        xmlFile:setValue(key .. "#pendingSelectedBreakdowns", table.concat(spec.pendingSelectedBreakdowns or {}, ","))
        xmlFile:setValue(key .. "#pendingServicePrice", encodeOptionalFloat(spec.pendingServicePrice))
        xmlFile:setValue(key .. "#pendingInspectionQueue", table.concat(spec.pendingInspectionQueue or {}, ","))
        xmlFile:setValue(key .. "#pendingRepairQueue", table.concat(spec.pendingRepairQueue or {}, ","))
        xmlFile:setValue(key .. "#pendingProgressStepIndex", spec.pendingProgressStepIndex or 0)
        xmlFile:setValue(key .. "#pendingProgressTotalTime", spec.pendingProgressTotalTime or 0)
        xmlFile:setValue(key .. "#pendingProgressElapsedTime", spec.pendingProgressElapsedTime or 0)
        xmlFile:setValue(key .. "#pendingMaintenanceServiceStart", encodeOptionalFloat(spec.pendingMaintenanceServiceStart))
        xmlFile:setValue(key .. "#pendingMaintenanceServiceTarget", encodeOptionalFloat(spec.pendingMaintenanceServiceTarget))
        xmlFile:setValue(key .. "#pendingOverhaulConditionStart", encodeOptionalFloat(spec.pendingOverhaulConditionStart))
        xmlFile:setValue(key .. "#pendingOverhaulConditionTarget", encodeOptionalFloat(spec.pendingOverhaulConditionTarget))
        xmlFile:setValue(key .. "#totalBreakdownsOccurred", spec.totalBreakdownsOccurred or 0)

        if spec.maintenanceLog and #spec.maintenanceLog > 0 then
            for i, entry in ipairs(spec.maintenanceLog) do
                local entryKey = string.format("%s.maintenanceLog.entry(%d)", key, i - 1)
                
                xmlFile:setValue(entryKey .. "#id", entry.id)
                xmlFile:setValue(entryKey .. "#type", entry.type)
                xmlFile:setValue(entryKey .. "#price", entry.price)
                xmlFile:setValue(entryKey .. "#date", ADS_Utils.serializeDate(entry.date)) 
                xmlFile:setValue(entryKey .. "#location", entry.location or "UNKNOWN")
                xmlFile:setValue(entryKey .. "#optionOne", entry.optionOne or "NONE")
                xmlFile:setValue(entryKey .. "#optionTwo", entry.optionTwo or "NONE")
                xmlFile:setValue(entryKey .. "#optionThree", entry.optionThree or false)
                xmlFile:setValue(entryKey .. "#isVisible", tostring(normalizeBoolValue(entry.isVisible, true)))
                xmlFile:setValue(entryKey .. "#isCompleted", normalizeBoolValue(entry.isCompleted, true))
                xmlFile:setValue(entryKey .. "#isLegacyEntry", normalizeBoolValue(entry.isLegacyEntry, false))

                if entry.conditionData then
                    local condKey = entryKey .. ".conditionData"
                    xmlFile:setValue(condKey .. "#year", entry.conditionData.year or 0)
                    xmlFile:setValue(condKey .. "#operatingHours", entry.conditionData.operatingHours or 0)
                    xmlFile:setValue(condKey .. "#age", entry.conditionData.age or 0)
                    xmlFile:setValue(condKey .. "#condition", entry.conditionData.condition or 1)
                    xmlFile:setValue(condKey .. "#service", entry.conditionData.service or 1)
                    xmlFile:setValue(condKey .. "#reliability", entry.conditionData.reliability or 1)
                    xmlFile:setValue(condKey .. "#maintainability", entry.conditionData.maintainability or 1)

                    if entry.conditionData.activeBreakdowns then
                        xmlFile:setValue(condKey .. "#activeBreakdowns", ADS_Utils.serializeBreakdowns(entry.conditionData.activeBreakdowns))
                    end
                    
                    if entry.conditionData.selectedBreakdowns and #entry.conditionData.selectedBreakdowns > 0 then
                        xmlFile:setValue(condKey .. "#selectedBreakdowns", table.concat(entry.conditionData.selectedBreakdowns, ","))
                    end
                    
                    if entry.conditionData.activeEffects then
                        local effKeys = {}
                        for effId, _ in pairs(entry.conditionData.activeEffects) do 
                            table.insert(effKeys, tostring(effId)) 
                        end
                        xmlFile:setValue(condKey .. "#activeEffects", table.concat(effKeys, ","))
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
    self.spec_AdvancedDamageSystem = {}
    self.spec_AdvancedDamageSystem.baseServiceLevel = 1.0
    self.spec_AdvancedDamageSystem.baseConditionLevel = 1.0
    self.spec_AdvancedDamageSystem.serviceLevel = self.spec_AdvancedDamageSystem.baseServiceLevel
    self.spec_AdvancedDamageSystem.conditionLevel = self.spec_AdvancedDamageSystem.baseConditionLevel

    self.spec_AdvancedDamageSystem.extraConditionWear = 0
    self.spec_AdvancedDamageSystem.extraServiceWear = 0
    self.spec_AdvancedDamageSystem.extraBreakdownProbability = 0
    
    self.spec_AdvancedDamageSystem.reliability = 1.0
    self.spec_AdvancedDamageSystem.maintainability = 1.0
    self.spec_AdvancedDamageSystem.year = 2000

    self.spec_AdvancedDamageSystem.activeBreakdowns = {}
    self.spec_AdvancedDamageSystem.activeEffects = {}
    self.spec_AdvancedDamageSystem.activeIndicators = {}
    self.spec_AdvancedDamageSystem.activeFunctions = {}
    self.spec_AdvancedDamageSystem.originalFunctions = {}

    self.spec_AdvancedDamageSystem.maintenanceLog = {}
    self.spec_AdvancedDamageSystem.lastServiceDate = {}
    self.spec_AdvancedDamageSystem.lastInspectionDate = {}
    self.spec_AdvancedDamageSystem.lastServiceOperatingHours = 0
    self.spec_AdvancedDamageSystem.lastInspectedConditionState = AdvancedDamageSystem.STATES.UNKNOWN
    self.spec_AdvancedDamageSystem.lastInspectedServiceState = AdvancedDamageSystem.STATES.UNKNOWN
    self.spec_AdvancedDamageSystem.lastInspectedPower = 1
    self.spec_AdvancedDamageSystem.lastInspectedBrake = 1
    self.spec_AdvancedDamageSystem.lastInspectedYieldReduction = 1
    
    self.spec_AdvancedDamageSystem.engineTemperature = -99
    self.spec_AdvancedDamageSystem.rawEngineTemperature = -99
    self.spec_AdvancedDamageSystem.thermostatState = 0.0
    self.spec_AdvancedDamageSystem.thermostatHealth = 1.0
    self.spec_AdvancedDamageSystem.thermostatStuckedPosition = nil
    self.spec_AdvancedDamageSystem.engTermPID = {
        integral = 0,
        lastError = 0
    }

    self.spec_AdvancedDamageSystem.transmissionTemperature = -99
    self.spec_AdvancedDamageSystem.rawTransmissionTemperature = -99
    self.spec_AdvancedDamageSystem.transmissionThermostatState = 0.0
    self.spec_AdvancedDamageSystem.transmissionThermostatHealth = 1.0
    self.spec_AdvancedDamageSystem.transmissionThermostatStuckedPosition = nil
    self.spec_AdvancedDamageSystem.transTermPID = {
        integral = 0,
        lastError = 0
    }

    self.spec_AdvancedDamageSystem.debugData = {
        service = {
            totalWearRate = 0
        },
        condition = {
            totalWearRate = 0,
            motorLoadFactor = 0,
            expiredServiceFactor = 0,
            coldMotorFactor = 0,
            hotMotorFactor = 0,
            coldTransFactor = 0,
            hotTransFactor = 0
        },
        cvtAddon = {
            warnheat = 0,
            warndamage = 0,
            critheat = 0,
            critdamage = 0,
            highpressure = 0,
            totalWearRate = 0,
            reducedAmount = 0,
            resetTimer = 0
        },
        breakdown = {
            failureChancePerFrame = 0,
            criticalOutcomeChance = 0,
            failureChanceInHour = 0,
            criticalFailureInHour = 0
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
            accFactor = 0,
            stiction = 0,
            waxSpeed = 0,
            kp = 0
        }
    }

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
    self.spec_AdvancedDamageSystem.pendingOverhaulConditionStart = nil
    self.spec_AdvancedDamageSystem.pendingOverhaulConditionTarget = nil
    self.spec_AdvancedDamageSystem.totalBreakdownsOccurred = 0
    self.spec_AdvancedDamageSystem.isElectricVehicle = false
end

function AdvancedDamageSystem:onPostLoad(savegame)
    log_dbg("onPostLoad called for vehicle:", self:getFullName())
    local spec = self.spec_AdvancedDamageSystem
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
        local serviceDateString = savegame.xmlFile:getValue(key .. "#lastServiceDate", "")
        spec.lastServiceDate = ADS_Utils.deserializeDate(serviceDateString)
        local inspectionDateString = savegame.xmlFile:getValue(key .. "#lastInspectionDate", "")
        spec.lastInspectionDate = ADS_Utils.deserializeDate(inspectionDateString)
        spec.lastServiceOperatingHours = savegame.xmlFile:getValue(key .. "#lastServiceOpHours", spec.lastServiceOperatingHours)
        spec.lastInspectedConditionState = savegame.xmlFile:getValue(key .. "#lastInspCond", spec.lastInspectedConditionState)
        spec.lastInspectedServiceState = savegame.xmlFile:getValue(key .. "#lastInspServ", spec.lastInspectedServiceState)
        spec.engineTemperature = savegame.xmlFile:getValue(key .. "#engineTemperature", spec.engineTemperature)
        spec.transmissionTemperature = savegame.xmlFile:getValue(key .. "#transmissionTemperature", spec.transmissionTemperature)
        spec.lastInspectedPower = savegame.xmlFile:getValue(key .. "#lastInspPwr", spec.lastInspectedPower)
        spec.lastInspectedBrake = savegame.xmlFile:getValue(key .. "#lastInspBrk", spec.lastInspectedBrake)
        spec.lastInspectedYieldReduction = savegame.xmlFile:getValue(key .. "#lastInspYld", spec.lastInspectedYieldReduction)
        spec.serviceOptionOne = savegame.xmlFile:getValue(key .. "#serviceOptionOne", spec.serviceOptionOne)
        spec.serviceOptionTwo = savegame.xmlFile:getValue(key .. "#serviceOptionTwo", spec.serviceOptionTwo)
        if spec.serviceOptionOne == "" then spec.serviceOptionOne = nil end
        if spec.serviceOptionTwo == "" then spec.serviceOptionTwo = nil end
        spec.serviceOptionThree = savegame.xmlFile:getValue(key .. "#serviceOptionThree", spec.serviceOptionThree)
        spec.pendingServicePrice = decodeOptionalFloat(savegame.xmlFile:getValue(key .. "#pendingServicePrice", spec.pendingServicePrice))
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
        spec.pendingMaintenanceServiceStart = decodeOptionalFloat(savegame.xmlFile:getValue(key .. "#pendingMaintenanceServiceStart", spec.pendingMaintenanceServiceStart))
        spec.pendingMaintenanceServiceTarget = decodeOptionalFloat(savegame.xmlFile:getValue(key .. "#pendingMaintenanceServiceTarget", spec.pendingMaintenanceServiceTarget))
        spec.pendingOverhaulConditionStart = decodeOptionalFloat(savegame.xmlFile:getValue(key .. "#pendingOverhaulConditionStart", spec.pendingOverhaulConditionStart))
        spec.pendingOverhaulConditionTarget = decodeOptionalFloat(savegame.xmlFile:getValue(key .. "#pendingOverhaulConditionTarget", spec.pendingOverhaulConditionTarget))
        local hasTotalBreakdownsOccurred = savegame.xmlFile:hasProperty(key .. "#totalBreakdownsOccurred")
        spec.totalBreakdownsOccurred = savegame.xmlFile:getValue(key .. "#totalBreakdownsOccurred", spec.totalBreakdownsOccurred)

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
                entry.isVisible = normalizeBoolValue(savegame.xmlFile:getValue(entryKey .. "#isVisible", true), true)
                entry.isCompleted = normalizeBoolValue(savegame.xmlFile:getValue(entryKey .. "#isCompleted", true), true)
                entry.isLegacyEntry = normalizeBoolValue(savegame.xmlFile:getValue(entryKey .. "#isLegacyEntry", false), false)

                entry.conditionData.year = savegame.xmlFile:getValue(condKey .. "#year", 0)
                entry.conditionData.operatingHours = savegame.xmlFile:getValue(condKey .. "#operatingHours", 0)
                entry.conditionData.age = savegame.xmlFile:getValue(condKey .. "#age", 0)
                entry.conditionData.condition = savegame.xmlFile:getValue(condKey .. "#condition", 1)
                entry.conditionData.service = savegame.xmlFile:getValue(condKey .. "#service", 1)
                entry.conditionData.reliability = savegame.xmlFile:getValue(condKey .. "#reliability", 1)
                entry.conditionData.maintainability = savegame.xmlFile:getValue(condKey .. "#maintainability", 1)

                local bdStr = savegame.xmlFile:getValue(condKey .. "#activeBreakdowns", "")
                entry.conditionData.activeBreakdowns = ADS_Utils.deserializeBreakdowns(bdStr) or {}

                local selBdStr = savegame.xmlFile:getValue(condKey .. "#selectedBreakdowns", "")
                entry.conditionData.selectedBreakdowns = parseCsvList(selBdStr)

                entry.conditionData.activeEffects = {}
                local effectIds = parseCsvList(savegame.xmlFile:getValue(condKey .. "#activeEffects", ""))
                for _, effId in ipairs(effectIds) do
                    entry.conditionData.activeEffects[effId] = true
                end

                entry.conditionData.activeIndicators = {}
                local indicatorIds = parseCsvList(savegame.xmlFile:getValue(condKey .. "#activeIndicators", ""))
                for _, indId in ipairs(indicatorIds) do
                    entry.conditionData.activeIndicators[indId] = true
                end
            else
                -- COMPAT(0.8.5.0): migrate legacy maintenance log entry format (hours/aftermarket/breakdowns/info).
                -- Remove this migration branch after legacy save migration window is over.
                local legacyAftermarket = normalizeBoolValue(savegame.xmlFile:getValue(entryKey .. "#aftermarket", false), false)
                local legacyOperatingHours = normalizeNumberValue(savegame.xmlFile:getValue(entryKey .. "#hours", 0), 0)
                local legacyBreakdowns = parseCsvList(savegame.xmlFile:getValue(entryKey .. "#breakdowns", ""))

                local optionOne = "NONE"
                local optionTwo = legacyAftermarket and AdvancedDamageSystem.PART_TYPES.AFTERMARKET or AdvancedDamageSystem.PART_TYPES.OEM
                local optionThree = false

                if entry.type == AdvancedDamageSystem.STATUS.INSPECTION then
                    optionOne = AdvancedDamageSystem.INSPECTION_TYPES.STANDARD
                    optionTwo = "NONE"
                elseif entry.type == AdvancedDamageSystem.STATUS.MAINTENANCE then
                    optionOne = AdvancedDamageSystem.MAINTENANCE_TYPES.STANDARD
                elseif entry.type == AdvancedDamageSystem.STATUS.REPAIR then
                    optionOne = AdvancedDamageSystem.REPAIR_URGENCY.MEDIUM
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

        if not hasTotalBreakdownsOccurred then
            -- COMPAT(0.8.5.0): bootstrap totalBreakdownsOccurred for legacy saves lacking this field.
            -- Remove this bootstrap after legacy save migration window is over.
            local bootstrapOccurred = 0
            for _, entry in ipairs(spec.maintenanceLog) do
                if entry.type == AdvancedDamageSystem.STATUS.REPAIR then
                    local selectedBreakdowns = entry.conditionData and entry.conditionData.selectedBreakdowns or {}
                    for _, breakdownId in ipairs(selectedBreakdowns) do
                        local breakdownDef = ADS_Breakdowns.BreakdownRegistry[breakdownId]
                        if breakdownDef ~= nil and breakdownDef.isSelectable == true then
                            bootstrapOccurred = bootstrapOccurred + 1
                        end
                    end
                end
            end
            spec.totalBreakdownsOccurred = math.max(spec.totalBreakdownsOccurred or 0, bootstrapOccurred)
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
        if spec.totalBreakdownsOccurred == nil then spec.totalBreakdownsOccurred = 0 end
    end

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
        spec.samples.alarm = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "alarm", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.transmissionShiftFailed1 = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "transmissionShiftFailed1", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.transmissionShiftFailed2 = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "transmissionShiftFailed2", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.transmissionShiftFailed3 = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "transmissionShiftFailed3", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.brakes1 = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "brakes1", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.brakes2 = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "brakes2", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.brakes3 = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "brakes3", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.turbocharger1 = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "turbocharger1", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.turbocharger2 = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "turbocharger2", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.turbocharger3 = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "turbocharger3", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.turbocharger4 = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "turbocharger4", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.gearDisengage1 = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "gearDisengage1", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        spec.samples.maintenanceCompleted = soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "maintenanceCompleted", modDir, root, 1, AudioGroup.VEHICLE, i3d, self)
        delete(xmlSoundFile)
    else
        log_dbg("ERROR: AdvancedDamageSystem - Could not load ads_sounds.xml")
    end

    spec.rawEngineTemperature = spec.engineTemperature
    spec.rawTransmissionTemperature = spec.transmissionTemperature

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
    
    spec.isElectricVehicle = getIsElectricVehicle(self)
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

-- ==========================================================
--                        UPDATE
-- ==========================================================

function AdvancedDamageSystem:onUpdate(dt, ...)
    local spec = self.spec_AdvancedDamageSystem
    
    spec.effectsUpdateTimer = spec.effectsUpdateTimer + dt

    if spec.effectsUpdateTimer < ADS_Config.EFFECTS_UPDATE_DELAY then
        return
    end

    --- Registration in ADS_Main.vehicles and first load checks.
    if ADS_Main and ADS_Main.vehicles and ADS_Main.vehicles[self.uniqueId] == nil then
        if (self.propertyState == 2 or self.propertyState == 3 or self.propertyState == 4) and self.ownerFarmId ~= 0 and self.ownerFarmId < 10 then
            log_dbg(" -> Registering vehicle in ADS_Main.vehicles list. ID:", self.uniqueId)
            --- Registration in ADS_Main.vehicles
            ADS_Main.vehicles[self.uniqueId] = self
            ADS_Main.numVehicles = ADS_Main.numVehicles + 1
   
            --- if first mod load or used vehicle
            if self:getOperatingTime() > 0 and spec.conditionLevel == spec.baseConditionLevel or self:getDamageAmount() > 0 then
                -- Used vehicle logic
                spec.serviceLevel = 1 - self:getDamageAmount()
                spec.conditionLevel = math.max(1 - self:getFormattedOperatingTime() / 150, math.random() * 0.3)
                self:setDamageAmount(0.0, true)
            end

            --- if first mod load and vehicle has no maintenance log, add initial entry with current condition and service levels
            if (spec.maintenanceLog == nil or #spec.maintenanceLog == 0) then
                self:addEntryToMaintenanceLog(AdvancedDamageSystem.STATUS.INSPECTION, AdvancedDamageSystem.INSPECTION_TYPES.STANDARD, "NONE", false, 0)
            end

            --- Updating vehicle's year from Vehicle Years mod
            local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
            if storeItem ~= nil and storeItem.specs ~= nil and storeItem.specs.year ~= nil and tonumber(storeItem.specs.year) ~= nil then
                spec.year = tonumber(storeItem.specs.year)
            end

            --- Updating vehicle's reliability and maintainability
            spec.reliability, spec.maintainability = AdvancedDamageSystem.getBrandReliability(self)
        end
    end

    --- just in case, reset damage amount to 0 if it's not
    if self.getDamageAmount ~= nil and self:getDamageAmount() ~= 0 then self:setDamageAmount(0.0, true) end

    --- general wear and tear
    if self:getConditionLevel() < ADS_Config.CORE.GENERAL_WEAR_THRESHOLD and not self:hasBreakdown('GENERAL_WEAR') then
        self:addBreakdown('GENERAL_WEAR', 1)
    elseif self:hasBreakdown('GENERAL_WEAR') and self:getConditionLevel() > ADS_Config.CORE.GENERAL_WEAR_THRESHOLD then
        self:removeBreakdown('GENERAL_WEAR')
    end

    --- Overheat protection for vehcile > 2000 year and engine failure from overheating for < 2000
    if spec.year >= 2000 then
        local overheatProtectionId = 'OVERHEAT_PROTECTION'
        local overheatProtection = self:getActiveBreakdowns()[overheatProtectionId]
        if overheatProtection and spec.transmissionTemperature < 100 and spec.engineTemperature < 100 then
            self:removeBreakdown(overheatProtectionId)    
        end
        if self:getIsMotorStarted() then
            if (spec.transmissionTemperature > 105 or spec.engineTemperature > 105) and not overheatProtection then
                self:addBreakdown(overheatProtectionId, 1)
                if self.getIsControlled ~= nil and self:getIsControlled() then
                    g_soundManager:playSample(spec.samples.alarm)
                end
            elseif overheatProtection then
                if self:getCruiseControlState() ~= 0 then
                    self:setCruiseControlState(0, true)
                end
                if (spec.transmissionTemperature > 125 or spec.engineTemperature > 125) and overheatProtection.stage < 4 then
                    self:advanceBreakdown(overheatProtectionId)
                    if self.getIsControlled ~= nil and self:getIsControlled() then
                        g_soundManager:playSample(spec.samples.alarm)
                    end
                elseif (spec.transmissionTemperature > 115 or spec.engineTemperature > 115) and overheatProtection.stage < 3 then
                    self:advanceBreakdown(overheatProtectionId)
                    if self.getIsControlled ~= nil and self:getIsControlled() then
                        g_soundManager:playSample(spec.samples.alarm)
                    end
                elseif (spec.transmissionTemperature > 110 or spec.engineTemperature > 110) and overheatProtection.stage < 2 then
                    self:advanceBreakdown(overheatProtectionId)
                    if self.getIsControlled ~= nil and self:getIsControlled() then
                        g_soundManager:playSample(spec.samples.alarm)
                    end
                end
            end
        end
    else
        local engineFailedEffect = spec.activeEffects.ENGINE_FAILURE
        if spec.engineTemperature > 125 and not engineFailedEffect then
            if math.random() < ADS_Utils.getChancePerFrameFromMeanTime(spec.effectsUpdateTimer, 3) then
                self:addBreakdown('ENGINE_JAM')
            end
       end
    end

    --- Cold engine message
    if spec ~= nil and self:getIsMotorStarted() and spec.engineTemperature <= ADS_Config.CORE.COLD_MOTOR_THRESHOLD and self.getIsControlled ~= nil and self:getIsControlled()  and not self:getIsAIActive() and not spec.isElectricVehicle then
            local spec_motorized = self.spec_motorized
            local lastRpm = spec_motorized.motor:getLastModulatedMotorRpm()
            local maxRpm = spec_motorized.motor.maxRpm
            local rpmLoad = lastRpm / maxRpm
            if rpmLoad > 0.75 then
                g_currentMission:showBlinkingWarning(g_i18n:getText('ads_cold_engine_message'), 2800)
            end
    end

    --- Messages, stop ai worker
    if spec ~= nil and spec.activeFunctions ~= nil and next(spec.activeEffects) ~= nil then
        for _, effectData in pairs(spec.activeEffects) do
            if effectData ~= nil and effectData.extraData ~= nil and effectData.extraData.message ~= nil then
                if self.getIsControlled ~= nil and self:getIsControlled() and not self:isUnderService() then
                    g_currentMission:showBlinkingWarning(g_i18n:getText(effectData.extraData.message), 200)
                end
                if self:getIsAIActive() and effectData.extraData.disableAi then 
                    self:stopCurrentAIJob(AIMessageErrorVehicleBroken.new()) 
                end
            end
        end
    end

    --- ai worker overload, temp control
    if ADS_Config.CORE.AI_OVERLOAD_AND_OVERHEAT_CONTROL and self:getIsAIActive() and self:getIsMotorStarted() then
        local motorLoad = self:getMotorLoadPercentage()
        if (motorLoad > 0.95 or spec.rawEngineTemperature > 97 or spec.rawTransmissionTemperature > 97) and self:getCruiseControlSpeed() > 5 then

            if self.spec_attacherJoints and self.spec_attacherJoints.attachedImplements and next(self.spec_attacherJoints.attachedImplements) ~= nil then
                for _, implementData in pairs(self.spec_attacherJoints.attachedImplements) do
                    if implementData.object ~= nil then
                        local implement = implementData.object
                        local currentSpeedLimit = implement.speedLimit
                        if currentSpeedLimit ~= nil and implement:getIsLowered() then
                            if currentSpeedLimit < self:getCruiseControlSpeed() then
                                self:setCruiseControlMaxSpeed(currentSpeedLimit, nil)
                            end
                        end
                    end
                end
            end
    
            self:setCruiseControlMaxSpeed(self:getCruiseControlSpeed() - 1, nil)
        elseif motorLoad < 0.75 and spec.rawEngineTemperature < 92 and spec.rawTransmissionTemperature < 92  then
            self:setCruiseControlMaxSpeed(self:getCruiseControlSpeed() + 1, nil)
        end
    end

    --- Enables the thermal model for neutral vehicles on the map, should the player happen to use them
    if ADS_Main and ADS_Main.vehicles and ADS_Main.vehicles[self.uniqueId] == nil and self:getIsControlled() then
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
    if spec == nil then return end
 
    self:updateThermalSystems(dt)

    if self:isUnderService() then
        self:processService(dt)
    else
        local serviceWearRate, conditionWearRate = self:calculateWearRates()
        if self:getIsOperating() and self.propertyState ~= 4 then
            self:processBreakdowns(dt)
            self:checkForNewBreakdown(dt, conditionWearRate)
        end
        self:updateConditionLevel(conditionWearRate, dt)
        self:updateServiceLevel(serviceWearRate, dt)
    end
end

-- ==========================================================
--                        AI WORKER
-- ==========================================================

-- ==========================================================
--                      CORE FUNCTIONS
-- ==========================================================

------------------- temperatures -------------------

function AdvancedDamageSystem:updateThermalSystems(dt)
    local motor = self:getMotor()
    if not motor then return end

    local spec = self.spec_AdvancedDamageSystem
    local vehicleHaveCVT = (motor.minForwardGearRatio ~= nil and spec.year >= 2000 and not spec.isElectricVehicle)
    
    local isMotorStarted = self:getIsMotorStarted()
    local motorLoad = math.max(self:getMotorLoadPercentage(), 0.0)
    local motorRpm = self:getMotorRpmPercentage()
    local speed = self:getLastSpeed()
    local dirt = self:getDirtAmount()
    local eviromentTemp = g_currentMission.environment.weather.forecast:getCurrentWeather().temperature
    
    local speedCooling = 0
    local C = ADS_Config.THERMAL
    if speed > C.SPEED_COOLING_MIN_SPEED then
        local speedRatio = math.min((speed - C.SPEED_COOLING_MIN_SPEED) / (C.SPEED_COOLING_MAX_SPEED - C.SPEED_COOLING_MIN_SPEED), 1.0)
        speedCooling = C.SPEED_COOLING_MAX_EFFECT * speedRatio
    end

    if spec.engineTemperature < eviromentTemp or (g_sleepManager.isSleeping and not isMotorStarted) then spec.engineTemperature = eviromentTemp end
    if spec.rawEngineTemperature < eviromentTemp or (g_sleepManager.isSleeping and not isMotorStarted) then spec.rawEngineTemperature = eviromentTemp end
    if vehicleHaveCVT then
        if spec.transmissionTemperature < eviromentTemp or (g_sleepManager.isSleeping and not isMotorStarted) then spec.transmissionTemperature = eviromentTemp end
        if spec.rawTransmissionTemperature < eviromentTemp or (g_sleepManager.isSleeping and not isMotorStarted) then spec.rawTransmissionTemperature = eviromentTemp end
    end

    if not spec.isElectricVehicle then 
        self:updateEngineThermalModel(dt, spec, isMotorStarted, motorLoad, speedCooling, eviromentTemp, dirt)
    end
    
    if vehicleHaveCVT then
        self:updateTransmissionThermalModel(dt, spec, isMotorStarted, motorLoad, motorRpm, speed, speedCooling, eviromentTemp, dirt)
    else
        spec.transmissionTemperature = -99
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
        heat = C.ENGINE_MIN_HEAT + motorLoad * (C.ENGINE_MAX_HEAT - C.ENGINE_MIN_HEAT)
        
        local dirtRadiatorMaxCooling = C.ENGINE_RADIATOR_MAX_COOLING * (1 - C.MAX_DIRT_INFLUENCE * (dirt ^ 4))
        radiatorCooling = math.max(dirtRadiatorMaxCooling * spec.thermostatState, C.ENGINE_RADIATOR_MIN_COOLING) * (deltaTemp ^ C.DELTATEMP_FACTOR_DEGREE)
        cooling = (radiatorCooling + convectionCooling) * (1 + speedCooling)
    else
        if spec.engineTemperature < C.COOLING_SLOWDOWN_THRESHOLD then
            cooling = convectionCooling / C.COOLING_SLOWDOWN_POWER
        else
            cooling = convectionCooling
        end
    end
    
    local alpha = dt / (C.TAU + dt)

    spec.rawEngineTemperature = spec.rawEngineTemperature + (heat - cooling) * (dt / 1000) * C.TEMPERATURE_CHANGE_SPEED
    spec.rawEngineTemperature = math.max(spec.rawEngineTemperature, eviromentTemp)
    spec.engineTemperature = math.max(spec.engineTemperature + alpha * (spec.rawEngineTemperature - spec.engineTemperature), eviromentTemp)
    
    local dbg = spec.debugData.engineTemp

    if isMotorStarted and spec.engineTemperature > C.ENGINE_THERMOSTAT_MIN_TEMP then
        spec.thermostatState = AdvancedDamageSystem.getNewTermostatState(dt, spec.engineTemperature, spec.engTermPID, spec.thermostatHealth, spec.year, spec.thermostatStuckedPosition, dbg)
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
    local slipFactor = 1.0
    local accFactor = 1.0
    local speedLimit = math.huge
    
    local deltaTemp = math.max(0, spec.rawTransmissionTemperature - eviromentTemp)
    convectionCooling = C.CONVECTION_FACTOR * (deltaTemp ^ C.DELTATEMP_FACTOR_DEGREE)

    if isMotorStarted then
        if (self:getAccelerationAxis() > 0 or self:getCruiseControlAxis() > 0) then
            accFactor = math.max(5 * motorRpm * math.max(motor.motorRotAccelerationSmoothed / motor.motorRotationAccelerationLimit, 0.0), 1.0)

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
            slipFactor = 1 + (1 - math.clamp((speed / speedLimit), 0.0, 1.0)) / 2
        end
        heat = C.TRANS_MIN_HEAT + (C.TRANS_MAX_HEAT - C.TRANS_MIN_HEAT) * loadFactor * slipFactor * accFactor
        local dirtRadiatorMaxCooling = C.TRANS_RADIATOR_MAX_COOLING * (1 - C.MAX_DIRT_INFLUENCE * (dirt ^ 4))
        
        radiatorCooling = math.max(dirtRadiatorMaxCooling * spec.transmissionThermostatState, C.TRANS_RADIATOR_MIN_COOLING) * (deltaTemp ^ C.DELTATEMP_FACTOR_DEGREE)
        cooling = (radiatorCooling +  convectionCooling) * (1 + speedCooling)
    else
        if spec.engineTemperature < C.COOLING_SLOWDOWN_THRESHOLD then
            cooling = convectionCooling / C.COOLING_SLOWDOWN_POWER
        else
            cooling = convectionCooling
        end
    end

    local alpha = dt / (C.TAU + dt)
    spec.rawTransmissionTemperature = spec.rawTransmissionTemperature + (heat - cooling) * (dt / 1000) * C.TEMPERATURE_CHANGE_SPEED
    spec.rawTransmissionTemperature = math.max(spec.rawTransmissionTemperature, eviromentTemp)
    spec.transmissionTemperature = math.max(spec.transmissionTemperature + alpha * (spec.rawTransmissionTemperature - spec.transmissionTemperature), eviromentTemp)

    if isMotorStarted and spec.transmissionTemperature > C.TRANS_THERMOSTAT_MIN_TEMP then
        spec.transmissionThermostatState = AdvancedDamageSystem.getNewTermostatState(dt, spec.transmissionTemperature, spec.transTermPID, spec.transmissionThermostatHealth, spec.year, spec.transmissionThermostatStuckedPosition, dbg)
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
        dbg.accFactor = accFactor
    end

    return dbg
end


function AdvancedDamageSystem.getNewTermostatState(dt, currentTemp, pidData, thermostatHealth, year, stuckedPosition, debugData)

    if stuckedPosition ~= nil then
        return stuckedPosition
    end
    
    local C = ADS_Config.THERMAL
    local dtSeconds = math.max(dt / 1000, 0.001)

    local isMechanical = year < C.THERMOSTAT_TYPE_YEAR_DIVIDER
    local targetPos = 0
    local maxOpening = 1.0
    
    if isMechanical then
        local startOpenTemp = C.PID_TARGET_TEMP - 10 
        local fullOpenTemp = C.PID_TARGET_TEMP + 3  
        targetPos = (currentTemp - startOpenTemp) / (fullOpenTemp - startOpenTemp)
        pidData.integral = 0
        pidData.lastError = 0
        if debugData then debugData.kp = 0 end
    else
        local pidKpYearFactor = (year - C.THERMOSTAT_TYPE_YEAR_DIVIDER) / (C.ELECTRONIC_THERMOSTAT_MAX_YEAR - C.THERMOSTAT_TYPE_YEAR_DIVIDER)
        local pid_kp = math.clamp(C.PID_KP_MIN + (C.PID_KP_MAX - C.PID_KP_MIN) * pidKpYearFactor, C.PID_KP_MIN, C.PID_KP_MAX)
        local errorTemp = currentTemp - C.PID_TARGET_TEMP
        
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

------------------- service and condition-------------------

function AdvancedDamageSystem:calculateWearRates()
    local spec = self.spec_AdvancedDamageSystem
    local spec_motorized = self.spec_motorized
    local C = ADS_Config.CORE
    local conditionWearRate = 1.0
    local serviceWearRate = 1.0
    local motorLoadFactor, expiredServiceFactor, coldMotorFactor, hotMotorFactor, coldTransFactor, hotTransFactor = 0, 0, 0, 0, 0, 0
    local vehicleHaveCVT = (spec_motorized.motor.minForwardGearRatio ~= nil and spec.year >= 2000 and not spec.isElectricVehicle)

    if self.getIsMotorStarted ~= nil and self:getIsMotorStarted() and not spec.isElectricVehicle then
        local motorLoad = self:getMotorLoadPercentage()
        local lastRpm = spec_motorized.motor:getLastModulatedMotorRpm()
        local maxRpm = spec_motorized.motor.maxRpm
        local rpmLoad = lastRpm / maxRpm

        -- overload
        if motorLoad > C.MOTOR_OVERLOADED_THRESHOLD then
            motorLoadFactor = ADS_Utils.calculateQuadraticMultiplier(motorLoad, C.MOTOR_OVERLOADED_THRESHOLD, false)
            motorLoadFactor = motorLoadFactor * C.MOTOR_OVERLOADED_MAX_MULTIPLIER
            conditionWearRate = conditionWearRate + motorLoadFactor
        end

        -- service
        if self:getServiceLevel() < C.SERVICE_EXPIRED_THRESHOLD then
            expiredServiceFactor = ADS_Utils.calculateQuadraticMultiplier(spec.serviceLevel, C.SERVICE_EXPIRED_THRESHOLD, true)
            expiredServiceFactor = expiredServiceFactor * C.SERVICE_EXPIRED_MAX_MULTIPLIER
            conditionWearRate = conditionWearRate + expiredServiceFactor
        end

        -- engine temperature
        if spec.engineTemperature < C.COLD_MOTOR_THRESHOLD and rpmLoad > 0.75 and not spec.isElectricVehicle and not self:getIsAIActive() then
            coldMotorFactor = ADS_Utils.calculateQuadraticMultiplier(spec.engineTemperature, C.COLD_MOTOR_THRESHOLD, true)
            local motorLoadInf = ADS_Utils.calculateQuadraticMultiplier(rpmLoad, 0.75, false)
            coldMotorFactor = coldMotorFactor * C.COLD_MOTOR_MAX_MULTIPLIER * motorLoadInf
            conditionWearRate = conditionWearRate + coldMotorFactor

        elseif spec.engineTemperature > C.OVERHEAT_MOTOR_THRESHOLD and motorLoad > 0.3 and not spec.isElectricVehicle then
            hotMotorFactor = ADS_Utils.calculateQuadraticMultiplier(spec.engineTemperature, C.OVERHEAT_MOTOR_THRESHOLD, false, 120)
            local motorLoadInf = ADS_Utils.calculateQuadraticMultiplier(motorLoad, 0.3, false)
            hotMotorFactor = hotMotorFactor * C.OVERHEAT_MOTOR_MAX_MULTIPLIER * motorLoadInf
            conditionWearRate = conditionWearRate + hotMotorFactor
        end

        -- cvt temperature
        if vehicleHaveCVT then
            if spec.transmissionTemperature < C.COLD_TRANSMISSION_THRESHOLD and rpmLoad > 0.75 and not spec.isElectricVehicle and not self:getIsAIActive() then
                coldTransFactor = ADS_Utils.calculateQuadraticMultiplier(spec.transmissionTemperature, C.COLD_TRANSMISSION_THRESHOLD, true)
                local motorLoadInf = ADS_Utils.calculateQuadraticMultiplier(rpmLoad, 0.75, false)
                coldTransFactor = coldTransFactor * C.COLD_TRANSMISSION_MULTIPLIER * motorLoadInf
                conditionWearRate = conditionWearRate + coldTransFactor

            elseif spec.transmissionTemperature > C.OVERHEAT_TRANSMISSION_THRESHOLD and motorLoad > 0.3 and not spec.isElectricVehicle then
                local transTemp = spec.transmissionTemperature
                hotTransFactor = ADS_Utils.calculateQuadraticMultiplier(transTemp, C.OVERHEAT_TRANSMISSION_THRESHOLD, false, 120)
                local motorLoadInf = ADS_Utils.calculateQuadraticMultiplier(rpmLoad, 0.75, false)
                hotTransFactor = hotTransFactor * C.OVERHEAT_TRANSMISSION_MAX_MULTIPLIER * motorLoadInf
                conditionWearRate = conditionWearRate + hotTransFactor
            end
        end

        -- idling
        if motorLoad < C.MOTOR_IDLING_THRESHOLD and self:getLastSpeed() < 0.003 then
            conditionWearRate = conditionWearRate * C.MOTOR_IDLING_MULTIPLIER
            serviceWearRate = serviceWearRate * C.MOTOR_IDLING_MULTIPLIER
        end
    else
        conditionWearRate = C.DOWNTIME_MULTIPLIER
        serviceWearRate = C.DOWNTIME_MULTIPLIER
    end

    conditionWearRate = (conditionWearRate + spec.extraConditionWear) / spec.reliability
    serviceWearRate = (serviceWearRate + spec.extraServiceWear) / spec.reliability
    
    if ADS_Config.DEBUG then
        spec.debugData.condition = {totalWearRate = conditionWearRate, motorLoadFactor = motorLoadFactor, expiredServiceFactor = expiredServiceFactor, coldMotorFactor = coldMotorFactor, hotMotorFactor = hotMotorFactor, coldTransFactor = coldTransFactor, hotTransFactor = hotTransFactor}
        spec.debugData.service.totalWearRate = serviceWearRate
    end
    return serviceWearRate, conditionWearRate
end

function AdvancedDamageSystem:updateServiceLevel(wearRate, dt)
    local spec = self.spec_AdvancedDamageSystem
    local newLevel = spec.serviceLevel - (wearRate * ADS_Config.CORE.BASE_SERVICE_WEAR / (60 * 60 * 1000) * dt)
    spec.serviceLevel = math.max(newLevel, 0)
end

function AdvancedDamageSystem:updateConditionLevel(wearRate, dt)
    local spec = self.spec_AdvancedDamageSystem
    local newLevel = spec.conditionLevel - (wearRate * ADS_Config.CORE.BASE_CONDITION_WEAR / (60 * 60 * 1000) * dt)
    spec.conditionLevel = math.clamp(newLevel, 0.001, 1)
end

function AdvancedDamageSystem:updateConditionLevelCVTAddon(wearRate, amount, dt)
    local spec = self.spec_AdvancedDamageSystem
    if wearRate ~= nil and wearRate > 0 then
        local newLevel = spec.conditionLevel - (wearRate * ADS_Config.CORE.BASE_CONDITION_WEAR / (60 * 60 * 1000) * dt)
        spec.conditionLevel = math.clamp(newLevel, 0.001, 1)
    end
    if amount ~= nil and amount > 0 then
        local newLevel = spec.conditionLevel - amount
        spec.conditionLevel = math.clamp(newLevel, 0.001, 1)
        spec.debugData.cvtAddon.reducedAmount = amount
    end

    if ADS_Config.DEBUG then
        local cvtSpec = self.spec_CVTaddon
        spec.debugData.cvtAddon = {
            warnheat = cvtSpec.forDBL_warnheat,
            warndamage = cvtSpec.forDBL_warndamage,
            critheat = cvtSpec.forDBL_critheat,
            critdamage = cvtSpec.forDBL_critdamage,
            highpressure = cvtSpec.forDBL_highpressure,
            totalWearRate = wearRate or 0.0,
            reducedAmount = spec.debugData.cvtAddon.reducedAmount,
            resetTimer = spec.debugData.cvtAddon.resetTimer,
        }

        if spec.debugData.cvtAddon.reducedAmount > 0 then
            local resetTimer = spec.debugData.cvtAddon.resetTimer + dt
            if resetTimer >= 5000 then
                spec.debugData.cvtAddon.reducedAmount = 0
                spec.debugData.cvtAddon.resetTimer = 0
            else
                spec.debugData.cvtAddon.resetTimer = resetTimer
            end
        end
    end
end

---------------------- breakdowns ----------------------

function AdvancedDamageSystem:checkForNewBreakdown(dt, conditionWearRate)
    local spec = self.spec_AdvancedDamageSystem
    if not spec or dt == 0 then
        return
    end
    local probability = ADS_Config.CORE.BREAKDOWN_PROBABILITY
    local minFailureChancePerFrame = 0.01 / 3600000 * ADS_Config.CORE_UPDATE_DELAY

    local failureChancePerFrame = AdvancedDamageSystem.calculateBreakdownProbability(self:getConditionLevel(), probability, dt)
    if self:getFormattedOperatingTime() > probability.VEHICLE_HONEYMOON_HOURS then
        failureChancePerFrame = math.max((failureChancePerFrame + failureChancePerFrame * spec.extraBreakdownProbability) * conditionWearRate, minFailureChancePerFrame)
    else
        failureChancePerFrame = math.max((failureChancePerFrame + failureChancePerFrame * spec.extraBreakdownProbability) * conditionWearRate - failureChancePerFrame * ((probability.VEHICLE_HONEYMOON_HOURS - self:getFormattedOperatingTime()) / probability.VEHICLE_HONEYMOON_HOURS), minFailureChancePerFrame)
    end

    local random = math.random()
    
    if random < failureChancePerFrame then
        
        local breakdownId = self:getRandomBreakdown()
        if breakdownId == nil then return end

        local criticalOutcomeChance = ADS_Utils.getCriticalFailureChance(self:getConditionLevel())

        local registryEntry = ADS_Breakdowns.BreakdownRegistry[breakdownId]
        if not registryEntry then
            log_dbg("Warning: Could not find registry entry for breakdown ID:", breakdownId)
            return
        end

        if math.random() < criticalOutcomeChance then
            log_dbg("Breakdown is CRITICAL!")
            self:addBreakdown(breakdownId, #registryEntry.stages)
        else
            log_dbg("Breakdown is MINOR.")
            self:addBreakdown(breakdownId, 1)
        end
    end

    if ADS_Config.DEBUG then
        if spec.debugData == nil then spec.debugData = {} end

        local hourlyProb = 1 - (1 - failureChancePerFrame) ^ (3600000 / dt)
        local criticalChance = math.clamp((1 - spec.conditionLevel) ^ probability.CRITICAL_DEGREE, probability.CRITICAL_MIN, probability.CRITICAL_MAX)
        
        spec.debugData.breakdown = {
            failureChancePerFrame = failureChancePerFrame,
            criticalOutcomeChance = failureChancePerFrame * criticalChance,
            failureChanceInHour = hourlyProb,
            criticalFailureInHour = hourlyProb * criticalChance
        }
    end
end


function AdvancedDamageSystem:getRandomBreakdown()
    log_dbg("getRandomBreakdown called for vehicle:", self:getFullName())
    if not self.spec_AdvancedDamageSystem then
        log_dbg("-> Vehicle has no ADS spec. Returning nil.")
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
        log_dbg("-> No new applicable breakdowns available with positive probability.")
        return nil
    end

    log_dbg("-> Found "..#applicableBreakdowns.." applicable breakdowns. Total probability weight:", totalProbability)

    local randomNumber = math.random() * totalProbability

    local cumulativeProbability = 0
    for _, breakdown in ipairs(applicableBreakdowns) do
        cumulativeProbability = cumulativeProbability + breakdown.probability
        if randomNumber <= cumulativeProbability then
            log_dbg("-> Weighted random choice selected:", breakdown.id, "with probability", breakdown.probability)
            return breakdown.id
        end
    end

    return nil
end


function AdvancedDamageSystem:addBreakdown(breakdownId, stage)
    log_dbg("addBreakdown called for", self:getFullName(), "with ID:", breakdownId, "and stage:", stage)
    local spec = self.spec_AdvancedDamageSystem
    if not spec then return end

    local activeBreakdowns = self:getActiveBreakdowns()
    
    local activeBreakdownsCount = 0
    for _, _ in pairs(activeBreakdowns) do
        activeBreakdownsCount = activeBreakdownsCount + 1
    end

    local registryEntry = ADS_Breakdowns.BreakdownRegistry[breakdownId]

    if activeBreakdownsCount >= ADS_Config.CORE.CONCURRENT_BREAKDOWN_LIMIT_PER_VEHICLE and registryEntry.isSelectable then
        log_dbg("-> Concurrent breakdown limit reached for vehicle:", self:getFullName())
        return nil 
    end


    if registryEntry == nil then
        log_dbg("-> Breakdown ID not found in registry. Aborting.")
        return
    end
    
    if self:hasBreakdown(breakdownId) then
        log_dbg("-> Breakdown already active. Aborting.")
        return
    end

    if registryEntry.isSelectable == true then
        spec.totalBreakdownsOccurred = (spec.totalBreakdownsOccurred or 0) + 1
    end

    log_dbg("-> Creating new breakdown instance.")
    spec.activeBreakdowns[breakdownId] = {
        stage = stage or 1,
        progressTimer = 0,
        isVisible = false,
        isSelectedForRepair = true
    }
    
    self:recalculateAndApplyEffects()
    log_dbg("-> Successfully created breakdown.")
end


function AdvancedDamageSystem:removeBreakdown(...)
    local spec = self.spec_AdvancedDamageSystem
    if not spec or next(spec.activeBreakdowns) == nil then
        return
    end
    
    local idsToRemove = {...}

    if #idsToRemove == 0 then
        log_dbg("removeBreakdown called for", self:getFullName(), "with no arguments. Removing all breakdowns.")
        spec.activeBreakdowns = {}
        self:recalculateAndApplyEffects()
        log_dbg("-> removeBreakdown finished.")
        return
    end

    log_dbg("removeBreakdown called for", self:getFullName(), "with IDs:", table.concat(idsToRemove, ", "))

    local removedCount = 0
    for _, id in ipairs(idsToRemove) do
        if spec.activeBreakdowns[id] then
            spec.activeBreakdowns[id] = nil
            removedCount = removedCount + 1
        end
    end
    
    if removedCount > 0 then
        log_dbg("-> Removed", removedCount, "breakdown(s).")
        self:recalculateAndApplyEffects()
    else
        log_dbg("-> No matching breakdowns found to remove.")
    end
    log_dbg("-> removeBreakdown finished.")
end

function AdvancedDamageSystem:hasBreakdown(breakdownId)
    local spec = self.spec_AdvancedDamageSystem
    if not spec or not spec.activeBreakdowns or next(spec.activeBreakdowns) == nil then
        return false
    end

    return spec.activeBreakdowns[breakdownId] ~= nil
end


function AdvancedDamageSystem:advanceBreakdown(breakdownId)
    local spec = self.spec_AdvancedDamageSystem
    if not spec or not spec.activeBreakdowns or next(spec.activeBreakdowns) == nil or spec.activeBreakdowns[breakdownId] == nil then
        return
    end
    
    local registryBreakdown = ADS_Breakdowns.BreakdownRegistry[breakdownId]
    local breakdown = spec.activeBreakdowns[breakdownId]

    if breakdown.stage < #registryBreakdown.stages then
        breakdown.stage = breakdown.stage + 1
        self:recalculateAndApplyEffects()
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
            
            if registryEntry.stages[breakdown.stage] then
                local stageData = registryEntry.stages[breakdown.stage]
                
                if stageData.progressMultiplier and stageData.progressMultiplier > 0 then
                    
                    local canProgress = true
                    if registryEntry.isCanProgress ~= nil then
                        canProgress = registryEntry.isCanProgress(self)
                    end

                    if canProgress then
                        breakdown.progressTimer = breakdown.progressTimer or 0
                        breakdown.progressTimer = breakdown.progressTimer + dt
                        
                        local stageDuration = C.BASE_BREAKDOWN_PROGRESS_TIME * stageData.progressMultiplier * math.clamp(0.333 + spec.conditionLevel, 0.333, 1)

                        if breakdown.progressTimer >= stageDuration then
                            local maxStages = #registryEntry.stages
                            
                            if breakdown.stage < maxStages then
                                breakdown.stage = breakdown.stage + 1
                                breakdown.progressTimer = 0
                                effectsNeedRecalculation = true

                                if breakdown.stage == maxStages and registryEntry.stages[breakdown.stage].detectionChance > 0 then
                                    breakdown.isVisible = true
                                end

                                log_dbg(string.format("ADS: Breakdown '%s' on vehicle '%s' advanced to stage %d.", id, self:getFullName(), breakdown.stage))
                            end

                            if id == "GENERAL_WEAR" then
                                breakdown.progressTimer = 0
                                effectsNeedRecalculation = true
                            end
                        end
                    end
                end
            end
        end
    end

    if effectsNeedRecalculation then
        self:recalculateAndApplyEffects()
    end
end

local function shallow_copy(original)
    local copy = {}
    for k, v in pairs(original) do
        copy[k] = v
    end
    return copy
end


function AdvancedDamageSystem:recalculateAndApplyEffects()
    log_dbg("recalculateAndApplyEffects called for vehicle:", self:getFullName())
    local spec = self.spec_AdvancedDamageSystem
    if not spec then return end

    local previouslyActiveEffects = spec.activeEffects or {}
    local aggregatedEffects = {}

    for id, breakdown in pairs(self:getActiveBreakdowns()) do
        local registryEntry = ADS_Breakdowns.BreakdownRegistry[id]

        if registryEntry == nil then
            log_dbg("Warning: Could not find registry entry for breakdown ID: ".. id ..". Removing breakdown from active list.")
            self:removeBreakdown(id)
        end

        if registryEntry and registryEntry.stages[breakdown.stage] then
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
                        local newEffect = shallow_copy(effectData)
                        newEffect.value = newValue 
                        aggregatedEffects[effectId] = newEffect
                    else
                        if strategy == "sum" then
                            if math.abs(newValue) > math.abs(existingEffect.value) then
                                existingEffect.extraData = effectData.extraData
                            end
                            existingEffect.value = existingEffect.value + newValue

                        elseif strategy == "multiply" then
                            if math.abs(newValue - 1) > math.abs(existingEffect.value - 1) then
                                existingEffect.extraData = effectData.extraData
                            end
                            existingEffect.value = existingEffect.value * newValue
                        
                        elseif strategy == "min" then
                            if newValue < existingEffect.value then
                                existingEffect.value = newValue
                                existingEffect.extraData = effectData.extraData 
                            end

                        elseif strategy == "max" then
                            if newValue > existingEffect.value then
                                existingEffect.value = newValue
                                existingEffect.extraData = effectData.extraData 
                            end
                        
                        elseif strategy == "boolean_or" then
                            existingEffect.value = existingEffect.value or newValue
                            if newValue == true and (existingEffect.value == false or existingEffect.value == nil) then
                                existingEffect.extraData = effectData.extraData
                            end
                        end
                    end
                end
            end
        end
    end

    spec.activeEffects = aggregatedEffects
    log_dbg("Recalculated effects:", ADS_Utils.tableToString(spec.activeEffects))

    for effectId, applicator in pairs(ADS_Breakdowns.EffectApplicators) do
        local isCurrentlyActive = spec.activeEffects[effectId] ~= nil
        local wasPreviouslyActive = previouslyActiveEffects[effectId] ~= nil

        if isCurrentlyActive then
            if applicator.apply then
                applicator.apply(self, spec.activeEffects[effectId], applicator)
                local currentEffect = spec.activeEffects[effectId]
                if currentEffect and currentEffect.extraData ~= nil and currentEffect.extraData.message ~= nil and self.getIsControlled ~= nil and not self:getIsControlled() then
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
    log_dbg("-> recalculateAndApplyEffects finished.")
end


function AdvancedDamageSystem:recalculateAndApplyIndicators()
    log_dbg("recalculateAndApplyIndicators called for vehicle:", self:getFullName())
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

    log_dbg("Recalculated indicators:", ADS_Utils.tableToString(spec.activeIndicators))
    log_dbg("-> recalculateAndApplyIndicators finished.")
end

--------------------- maintenance --------------------------------

local function isBreakdownSelectedForPlayerRepair(breakdownId, breakdown)
    if breakdownId == "GENERAL_WEAR" then
        return false
    end

    return breakdown ~= nil and breakdown.isSelectedForRepair == true and breakdown.isVisible == true
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
    spec.pendingOverhaulConditionStart = nil
    spec.pendingOverhaulConditionTarget = nil
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

    if vehicleState ~= states.READY or spec.maintenanceTimer ~= 0 then
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

        if self:hasBreakdown("MAINTENANCE_WITH_POOR_QUALITY_CONSUMABLES") then
            self:removeBreakdown("MAINTENANCE_WITH_POOR_QUALITY_CONSUMABLES")
        end

    -- REPAIR
    elseif type == states.REPAIR then
        local key = ADS_Utils.getNameByValue(AdvancedDamageSystem.REPAIR_URGENCY, optionOne)
        local idsToRepair = {}
        for id, breakdown in pairs(self:getActiveBreakdowns()) do
            if isBreakdownSelectedForPlayerRepair(id, breakdown) then
                table.insert(idsToRepair, id)
            end
        end

        selectedBreakdowns = idsToRepair
        spec.pendingRepairQueue = shallow_copy(idsToRepair)
        totalTimeMs = C.REPAIR_TIME * C.GLOBAL_SERVICE_TIME_MULTIPLIER * C.REPAIR_TIME_MULTIPLIERS[key] * #idsToRepair
        repairPrice = self:getServicePrice(type, optionOne, optionTwo, optionThree)

    -- OVERHAUL
    elseif type == states.OVERHAUL then
        local key = ADS_Utils.getNameByValue(AdvancedDamageSystem.OVERHAUL_TYPES, optionOne)
        totalTimeMs = C.OVERHAUL_TIME * C.GLOBAL_SERVICE_TIME_MULTIPLIER * C.OVERHAUL_TIME_MULTIPLIERS[key]

        if next(spec.activeBreakdowns) ~= nil then
            local idsToRepair = {}
            for id, _ in pairs(spec.activeBreakdowns) do
                if ADS_Breakdowns.BreakdownRegistry[id] and ADS_Breakdowns.BreakdownRegistry[id].isSelectable then
                    table.insert(idsToRepair, id)
                end
            end
            selectedBreakdowns = idsToRepair
        end

        local ageFactor = math.min(self.age / 12 / 100, 0.50)
        local minRestore = C.OVERHAUL_MIN_CONDITION_RESTORE_MULTIPLIERS[key] - ageFactor
        local maxRestore = C.OVERHAUL_MAX_CONDITION_RESTORE_MULTIPLIERS[key] - ageFactor
        local restoreAmount = math.min((minRestore + math.random() * (maxRestore - minRestore)) * spec.maintainability, spec.baseConditionLevel)
        spec.pendingOverhaulConditionStart = spec.conditionLevel
        local desiredConditionTarget = math.max(restoreAmount, ADS_Config.MAINTENANCE.OVERHAUL_MIN_CONDITION_RESTORE_MULTIPLIERS[2])
        spec.pendingOverhaulConditionTarget = math.max(spec.pendingOverhaulConditionStart, desiredConditionTarget)
    end

    spec.pendingSelectedBreakdowns = {}

    spec.pendingServicePrice = repairPrice

    if totalTimeMs > 0 then
        local adjustedTotalTimeMs = totalTimeMs / spec.reliability
        spec.maintenanceTimer = adjustedTotalTimeMs
        spec.pendingProgressTotalTime = adjustedTotalTimeMs
        spec.pendingProgressElapsedTime = 0
        spec.pendingProgressStepIndex = 0
        log_dbg(string.format('%s initiated for %s, will take %.2f seconds (%.2f seconds after reliability adjustment). Next planned state: %s', spec.currentState, self:getFullName(), totalTimeMs / 1000, spec.maintenanceTimer / 1000, spec.plannedState))
    else
        spec.currentState = states.READY
        resetPendingServiceProgress(spec)
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
    local prevTimer = spec.maintenanceTimer
    spec.maintenanceTimer = spec.maintenanceTimer - dt * timeScale
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
        if steps > 0 and spec.pendingProgressTotalTime > 0 then
            local targetStep = math.min(steps, math.floor((spec.pendingProgressElapsedTime / spec.pendingProgressTotalTime) * steps))
            while spec.pendingProgressStepIndex < targetStep do
                spec.pendingProgressStepIndex = spec.pendingProgressStepIndex + 1
                local breakdownId = spec.pendingInspectionQueue[spec.pendingProgressStepIndex]
                local breakdown = self:getActiveBreakdowns()[breakdownId]
                if breakdown ~= nil and not breakdown.isVisible then
                    if optionOne ~= AdvancedDamageSystem.INSPECTION_TYPES.VISUAL or breakdown.stage > 1 then
                        local breakdownDef = ADS_Breakdowns.BreakdownRegistry[breakdownId]
                        if breakdownDef ~= nil and breakdownDef.stages ~= nil and breakdownDef.stages[breakdown.stage] ~= nil then
                            local chance = breakdownDef.stages[breakdown.stage].detectionChance or 0
                            if math.random() < chance then
                                breakdown.isVisible = true
                                table.insert(spec.pendingSelectedBreakdowns, breakdownId)
                            end
                        end
                    end
                end
            end
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
                    self:removeBreakdown(breakdownId)
                    table.insert(spec.pendingSelectedBreakdowns, breakdownId)
                end

                -- defects check after each repaired part
                if math.random() < C.PARTS_BREAKDOWN_CHANCES[optionTwoKey] then
                    self:addBreakdown('REPAIR_WITH_POOR_QUALITY_PARTS', 1)
                    log_dbg("Added breakdown 'REPAIR_WITH_POOR_QUALITY_PARTS' due to poor quality parts chance.")
                end
            end
        end
    end

    if serviceType == states.MAINTENANCE and spec.pendingMaintenanceServiceStart ~= nil and spec.pendingMaintenanceServiceTarget ~= nil and spec.pendingProgressTotalTime > 0 then
        local ratio = math.min(math.max(spec.pendingProgressElapsedTime / spec.pendingProgressTotalTime, 0), 1)
        local interpolatedService = spec.pendingMaintenanceServiceStart + (spec.pendingMaintenanceServiceTarget - spec.pendingMaintenanceServiceStart) * ratio
        spec.serviceLevel = math.max(spec.pendingMaintenanceServiceStart, interpolatedService)
    elseif serviceType == states.OVERHAUL and spec.pendingOverhaulConditionStart ~= nil and spec.pendingOverhaulConditionTarget ~= nil and spec.pendingProgressTotalTime > 0 then
        local ratio = math.min(math.max(spec.pendingProgressElapsedTime / spec.pendingProgressTotalTime, 0), 1)
        local interpolatedCondition = spec.pendingOverhaulConditionStart + (spec.pendingOverhaulConditionTarget - spec.pendingOverhaulConditionStart) * ratio
        spec.conditionLevel = math.max(spec.pendingOverhaulConditionStart, interpolatedCondition)
    end

    -- work done
    if spec.maintenanceTimer <= 0 then
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
    local selectedBreakdowns = shallow_copy(spec.pendingSelectedBreakdowns or {})

    if serviceType == states.MAINTENANCE and spec.pendingMaintenanceServiceTarget ~= nil then
        local maintenanceStart = spec.pendingMaintenanceServiceStart or spec.serviceLevel
        spec.serviceLevel = math.max(maintenanceStart, spec.pendingMaintenanceServiceTarget)
    end

    if serviceType == states.OVERHAUL then
        if spec.pendingOverhaulConditionTarget ~= nil then
            local overhaulStart = spec.pendingOverhaulConditionStart or spec.conditionLevel
            spec.conditionLevel = math.max(overhaulStart, spec.pendingOverhaulConditionTarget)
        end
        spec.serviceLevel = 1.0

        local idsToRepair = {}
        for id, _ in pairs(spec.activeBreakdowns) do
            if ADS_Breakdowns.BreakdownRegistry[id] and ADS_Breakdowns.BreakdownRegistry[id].isSelectable then
                table.insert(idsToRepair, id)
            end
        end
        selectedBreakdowns = idsToRepair
        if #idsToRepair > 0 then
            self:removeBreakdown(table.unpack(idsToRepair))
        end
    elseif serviceType == states.REPAIR and optionThree == true then
        spec.plannedState = states.MAINTENANCE
    end

    if serviceType == states.INSPECTION or serviceType == states.MAINTENANCE then
        local needRepair = #selectedBreakdowns > 0
        for _, breakdown in pairs(self:getActiveBreakdowns()) do
            if breakdown.isVisible and breakdown.isSelectedForRepair then
                needRepair = true
                break
            end
        end

        if optionThree and needRepair then
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
    end

    -- repaint vehicle
    if serviceType == states.OVERHAUL and optionThree == true then
        self:repaintVehicle(true)
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

    g_currentMission.hud:addSideNotification({1, 1, 1, 1}, maintenanceCompletedText)
    g_soundManager:playSample(spec.samples.maintenanceCompleted)

    spec.maintenanceTimer = 0
    resetPendingServiceProgress(spec)
    spec.serviceOptionOne = nil
    spec.serviceOptionTwo = nil
    spec.serviceOptionThree = false

    if spec.plannedState ~= states.READY then
        local nextWork = spec.plannedState
        spec.plannedState = states.READY
        spec.currentState = states.READY

        local nextOptionOne, nextOptionTwo, nextOptionThree

        if nextWork == states.REPAIR then
            nextOptionOne = AdvancedDamageSystem.REPAIR_URGENCY.MEDIUM
            nextOptionTwo = AdvancedDamageSystem.PART_TYPES.OEM
            nextOptionThree = false
        elseif nextWork == states.MAINTENANCE then
            nextOptionOne = AdvancedDamageSystem.MAINTENANCE_TYPES.STANDARD
            nextOptionTwo = AdvancedDamageSystem.PART_TYPES.OEM
            nextOptionThree = false
        end

        local price = self:getServicePrice(nextWork, nextOptionOne, nextOptionTwo, nextOptionThree)

        print(nextWork .. " " .. tostring(nextOptionOne) .. " " .. tostring(nextOptionTwo) .. " " .. tostring(nextOptionThree) .. " " .. tostring(price))
        if g_currentMission:getMoney() >= price then
            self:initService(nextWork, spec.workshopType, nextOptionOne, nextOptionTwo, nextOptionThree)
            ADS_VehicleChangeStatusEvent.send(ADS_VehicleChangeStatusEvent.new(self))
            g_currentMission:addMoney(-1 * price, self:getOwnerFarmId(), MoneyType.VEHICLE_RUNNING_COSTS, true, true)
            g_currentMission.hud:addSideNotification(
                {1, 1, 1, 1},
                string.format("%s: %s", self:getFullName(), string.format(g_i18n:getText('ads_spec_next_planned_service_notification'), g_i18n:getText(nextWork)))
            )
        else
            ADS_VehicleChangeStatusEvent.send(ADS_VehicleChangeStatusEvent.new(self))
            g_currentMission.hud:addSideNotification(
                {1, 1, 1, 1},
                string.format("%s: %s", self:getFullName(), string.format(g_i18n:getText('ads_spec_next_planned_service_not_enouth_money_notification'), g_i18n:getText(nextWork)))
            )
        end
    else
        spec.currentState = states.READY
        ADS_VehicleChangeStatusEvent.send(ADS_VehicleChangeStatusEvent.new(self))
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
    local selectedBreakdowns = shallow_copy(spec.pendingSelectedBreakdowns or {})

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

    g_currentMission.hud:addSideNotification(
        {1, 1, 1, 1},
        string.format("%s: %s %s", self:getFullName(), g_i18n:getText(serviceType), g_i18n:getText("ads_spec_maintenance_cancelled_notification"))
    )

    spec.maintenanceTimer = 0
    spec.plannedState = states.READY
    spec.currentState = states.READY
    resetPendingServiceProgress(spec)
    spec.serviceOptionOne = nil
    spec.serviceOptionTwo = nil
    spec.serviceOptionThree = false

    ADS_VehicleChangeStatusEvent.send(ADS_VehicleChangeStatusEvent.new(self))
end

function AdvancedDamageSystem:addEntryToMaintenanceLog(maintenanceType, optionOne, optionTwo, optionThree, price, isCompleted)
    local spec = self.spec_AdvancedDamageSystem
    if not spec then return end

    local entryId = (#spec.maintenanceLog or 0) + 1
    local env = g_currentMission.environment
    local selectedBreakdowns = shallow_copy(spec.pendingSelectedBreakdowns or {})

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
            activeBreakdowns = self:getActiveBreakdowns(),
            selectedBreakdowns = selectedBreakdowns,
            activeEffects = shallow_copy(spec.activeEffects),
            activeIndicators = shallow_copy(spec.activeIndicators),
            reliability = spec.reliability,
            maintainability = spec.maintainability,
        }
    }

    table.insert(spec.maintenanceLog, entry)
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


function AdvancedDamageSystem:isUnderService()
    return self.spec_AdvancedDamageSystem.currentState ~= AdvancedDamageSystem.STATUS.READY
end


function AdvancedDamageSystem:getCurrentStatus()
    return self.spec_AdvancedDamageSystem.currentState
end

function AdvancedDamageSystem:setNewStatus(status)
    self.spec_AdvancedDamageSystem.currentState = status
    ADS_VehicleChangeStatusEvent.send(ADS_VehicleChangeStatusEvent.new(self))
end


function AdvancedDamageSystem:getActiveBreakdowns()
    return self.spec_AdvancedDamageSystem.activeBreakdowns
end


function AdvancedDamageSystem.getIsLogEntryHasReport(entry)
    local isVisible = normalizeBoolValue(entry.isVisible, true)
    local isCompleted = normalizeBoolValue(entry.isCompleted, true)
    local isLegacyEntry = normalizeBoolValue(entry.isLegacyEntry, false)

    return (entry.type ~= AdvancedDamageSystem.STATUS.REPAIR 
    and entry.optionOne ~= AdvancedDamageSystem.INSPECTION_TYPES.VISUAL 
    and entry.optionOne ~= "NONE" 
    and isVisible
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

    local interval = ((spec.baseServiceLevel / ADS_Config.CORE.BASE_SERVICE_WEAR) / 2) * spec.reliability
    return interval
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

function AdvancedDamageSystem.getBrandReliability(vehicle, storeItem)
    local year = 2000
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
    if year < 2000 then
        yearFactor = math.max(2000 - year, 0) * 0.01
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
    local wear = 1 - math.max(0, math.min(1, level))

    local calculatedMtbf = p.MAX_MTBF + (p.MIN_MTBF - p.MAX_MTBF) * wear ^ (math.max(p.DEGREE - p.DEGREE * wear, 0.1))
    local mtbfInMinutes = math.max(calculatedMtbf, p.MIN_MTBF)
    local mtbfInMillis = mtbfInMinutes * 60 * 1000

    if mtbfInMillis <= 0 then
        return 1.0
    end
    local probability = 1 - math.exp(-dt / mtbfInMillis)

    return probability
end

function AdvancedDamageSystem:getServicePrice(maintenanceType, optionOne, optionTwo, optionThree)
    local price = self:getPrice()
    local spec = self.spec_AdvancedDamageSystem
    local ageFactor = math.min(math.max(math.log10(self.age), 1), 2)
    local C = ADS_Config.MAINTENANCE
    local optionTwoKey = ADS_Utils.getNameByValue(AdvancedDamageSystem.PART_TYPES, optionTwo) or AdvancedDamageSystem.PART_TYPES.OEM

    if not maintenanceType then maintenanceType = spec.currentState end

    if maintenanceType == AdvancedDamageSystem.STATUS.READY then
        return 0
    end

    local ownWorkshopDiscount = 1.0
    if spec.workshopType == AdvancedDamageSystem.WORKSHOP.OWN then
        ownWorkshopDiscount = C.OWN_WORKSHOP_DISCOUNT
    end

    -- inspection
    if maintenanceType == AdvancedDamageSystem.STATUS.INSPECTION then
        local key = ADS_Utils.getNameByValue(AdvancedDamageSystem.INSPECTION_TYPES, optionOne)
        local inspectionPrice = math.ceil(math.max((C.GLOBAL_SERVICE_PRICE_MULTIPLIER * C.INSPECTION_PRICE_MULTIPLIERS[key] * price * 0.001 * ownWorkshopDiscount / 10) / spec.maintainability, 2)) * 10
        log_dbg(string.format("Calculated inspection price: %.2f (base price: %.2f, multiplier: %.4f, own workshop discount: %.2f, maintainability: %.2f)", inspectionPrice, price, C.INSPECTION_PRICE_MULTIPLIERS[key] * C.GLOBAL_SERVICE_PRICE_MULTIPLIER * 0.0005, ownWorkshopDiscount, spec.maintainability))
        return inspectionPrice
        
    -- maintenance
    elseif maintenanceType == AdvancedDamageSystem.STATUS.MAINTENANCE then
        local key = ADS_Utils.getNameByValue(AdvancedDamageSystem.MAINTENANCE_TYPES, optionOne)
        local maintenancePrice = math.ceil(math.max((C.GLOBAL_SERVICE_PRICE_MULTIPLIER * C.MAINTENANCE_PRICE_MULTIPLIERS[key] * C.PARTS_PRICE_MULTIPLIERS[optionTwoKey] * ownWorkshopDiscount * price * ageFactor * 0.01 / 10) / spec.maintainability, 2)) * 10
        log_dbg(string.format("Calculated maintenance price: %.2f (base price: %.2f, multiplier: %.2f, own workshop discount: %.2f, age factor: %.2f, maintainability: %.2f)", maintenancePrice, price, C.MAINTENANCE_PRICE_MULTIPLIERS[key] * C.GLOBAL_SERVICE_PRICE_MULTIPLIER * C.PARTS_PRICE_MULTIPLIERS[optionTwoKey], ownWorkshopDiscount, ageFactor, spec.maintainability))
        return  maintenancePrice

    -- overhaul
    elseif maintenanceType == AdvancedDamageSystem.STATUS.OVERHAUL then
        local key = ADS_Utils.getNameByValue(AdvancedDamageSystem.OVERHAUL_TYPES, optionOne)
        local overhaulPrice = (price * C.OVERHAUL_PRICE_MULTIPLIERS[key] * C.GLOBAL_SERVICE_PRICE_MULTIPLIER * ownWorkshopDiscount ) / spec.maintainability
        if optionThree then
            overhaulPrice = overhaulPrice + Wearable.calculateRepaintPrice(self:getSellPrice(), self:getWearTotalAmount()) * 0.25
        end
        overhaulPrice = math.max(overhaulPrice, 100)
        log_dbg(string.format("Calculated overhaul price: %.2f (base price: %.2f, multiplier: %.2f, own workshop discount: %.2f, maintainability: %.2f)", overhaulPrice, price, C.OVERHAUL_PRICE_MULTIPLIERS[key] * C.GLOBAL_SERVICE_PRICE_MULTIPLIER, ownWorkshopDiscount, spec.maintainability))
        return overhaulPrice
    -- repair
    elseif maintenanceType == AdvancedDamageSystem.STATUS.REPAIR then
        local key = ADS_Utils.getNameByValue(AdvancedDamageSystem.REPAIR_URGENCY, optionOne)
        local repairPrice = 0
        local activeBreakdowns = self:getActiveBreakdowns()
        
        for id, breakdown in pairs(activeBreakdowns) do
            if breakdown.isSelectedForRepair and breakdown.isVisible then
                local registryEntry = ADS_Breakdowns.BreakdownRegistry[id]
                if registryEntry ~= nil then
                    repairPrice = repairPrice + registryEntry.stages[breakdown.stage].repairPrice * C.GLOBAL_SERVICE_PRICE_MULTIPLIER * C.PARTS_PRICE_MULTIPLIERS[optionTwoKey] * C.REPAIR_PRICE_MULTIPLIERS[key] * ownWorkshopDiscount * (price / 100) * ageFactor
                end
            end
        end
        repairPrice = repairPrice * (1 / spec.maintainability)
        log_dbg(string.format("Calculated repair price: %.2f (base price: %.2f, breakdown repair price sum: %.2f, own workshop discount: %.2f, age factor: %.2f, maintainability: %.2f)", repairPrice, price, repairPrice * spec.maintainability, ownWorkshopDiscount, ageFactor, spec.maintainability))
        return repairPrice
    end
    return 0
end

function AdvancedDamageSystem:getBreakdownRepairPrice(breakdownId, breakdownStage)
    local C = ADS_Config.MAINTENANCE
    local spec = self.spec_AdvancedDamageSystem
    local registryEntry = ADS_Breakdowns.BreakdownRegistry[breakdownId]
    if registryEntry == nil then return 0 end

    local stageData = registryEntry.stages[breakdownStage]
    if stageData == nil then return 0 end

    local price = stageData.repairPrice or 0
    local vehiclePrice = self:getPrice()
    local ageFactor = math.min(math.max(math.log10(self.age), 1), 2)
    local ownWorkshopDiscount = 1.0
    if spec.workshopType == AdvancedDamageSystem.WORKSHOP.OWN then
        ownWorkshopDiscount = C.OWN_WORKSHOP_DISCOUNT
    end

    return price * C.GLOBAL_SERVICE_PRICE_MULTIPLIER * (vehiclePrice / 100) * ageFactor * ownWorkshopDiscount / spec.maintainability
end

function AdvancedDamageSystem:getServiceDuration(maintenanceType, optionOne, optionTwo, optionThree)
    local spec = self.spec_AdvancedDamageSystem
    local C = ADS_Config.MAINTENANCE
    local workshopType = spec.workshopType

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
        -- repair
        elseif maintenanceType == AdvancedDamageSystem.STATUS.REPAIR then
            local key = ADS_Utils.getNameByValue(AdvancedDamageSystem.REPAIR_URGENCY, optionOne)
            local repairCount = 0
            local breakdowns = self:getActiveBreakdowns()

            if breakdowns ~= nil and next(breakdowns) ~= nil then
                for id, breakdown in pairs(breakdowns) do
                    if isBreakdownSelectedForPlayerRepair(id, breakdown) then
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


function AdvancedDamageSystem:getServiceFinishTime(maintenanceType, optionOne, optionTwo, optionThree)
    local spec = self.spec_AdvancedDamageSystem

    if not maintenanceType then maintenanceType = spec.currentState end
    local savedOptionOne, savedOptionTwo, savedOptionThree = self:getLastServiceOptions()
    if not optionOne then optionOne = savedOptionOne end
    if not optionTwo then optionTwo = savedOptionTwo end
    if not optionThree then optionThree = savedOptionThree end

    if maintenanceType == AdvancedDamageSystem.STATUS.READY then
        return 0
    end

    local totalCalendarDuration = AdvancedDamageSystem.getServiceDuration(self, maintenanceType, optionOne, optionTwo, optionThree)

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
    local vehicle = g_localPlayer.getCurrentVehicle() 
    if not vehicle or not vehicle.spec_AdvancedDamageSystem then
        print("ADS Error: You must be in a vehicle with AdvancedDamageSystem support.")
        return nil
    end
    return vehicle
end

local function parseArguments(argString)
    if argString == nil or type(argString) ~= 'string' or argString == '' then
        return {}
    end
    
    local args = {}
    for arg in string.gmatch(argString, "[^%s]+") do
        table.insert(args, arg)
    end
    return args
end


function AdvancedDamageSystem.ConsoleCommands:listBreakdowns()
    print("--- Available Breakdowns ---")
    
    local breakdownIds = {}
    for id, data in pairs(ADS_Breakdowns.BreakdownRegistry) do
        table.insert(breakdownIds, string.format(" - %s (%s)", id, data.part or "No name"))
    end

    if #breakdownIds > 0 then
        table.sort(breakdownIds)
        print(table.concat(breakdownIds, "\n"))
    else
        print("  No breakdowns found in the registry.")
    end
    print("----------------------------")
end


function AdvancedDamageSystem.ConsoleCommands:addBreakdown(rawArgs)
    local args = parseArguments(rawArgs)
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


function AdvancedDamageSystem.ConsoleCommands:advanceBreakdown(rawArgs)
    local args = parseArguments(rawArgs)
    local vehicle = self:getTargetVehicle()
    if not vehicle then return end

    local spec = vehicle.spec_AdvancedDamageSystem
    local advancedCount = 0

    if not args or not args[1] then
        if next(spec.activeBreakdowns) == nil then
            print("ADS: No active breakdowns to advance.")
            return
        end

        for id, breakdown in pairs(vehicle:getActiveBreakdowns()) do
            local registryEntry = ADS_Breakdowns.BreakdownRegistry[id]
            if registryEntry and breakdown.stage < #registryEntry.stages then
                breakdown.stage = breakdown.stage + 1
                print(string.format("ADS: Advanced breakdown '%s' to stage %d.", id, breakdown.stage))
                advancedCount = advancedCount + 1
            else
                print(string.format("ADS: Breakdown '%s' is already at its final stage.", breakdown.id))
            end
        end
    else
        local breakdownId = string.upper(args[1])
        local foundBreakdown = spec.activeBreakdowns[breakdownId]

        if not foundBreakdown then
            print(string.format("ADS Error: Active breakdown with ID '%s' not found on this vehicle.", breakdownId))
            return
        end

        local registryEntry = ADS_Breakdowns.BreakdownRegistry[breakdownId]
        if registryEntry and foundBreakdown.stage < #registryEntry.stages then
            foundBreakdown.stage = foundBreakdown.stage + 1
            print(string.format("ADS: Advanced breakdown '%s' to stage %d.", foundBreakdown.id, foundBreakdown.stage))
            advancedCount = advancedCount + 1
        else
            print(string.format("ADS: Breakdown '%s' is already at its final stage.", foundBreakdown.id))
        end
    end

    if advancedCount > 0 then
        vehicle:recalculateAndApplyEffects()
        print(string.format("ADS: Recalculated effects for '%s'.", vehicle:getFullName()))
    end
end


function AdvancedDamageSystem.ConsoleCommands:setCondition(rawArgs)
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
    
    spec.conditionLevel = value
    print(string.format("ADS: Set Condition level for '%s' to %.2f.", vehicle:getFullName(), value))
end


function AdvancedDamageSystem.ConsoleCommands:setService(rawArgs)
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
    print(string.format("ADS: Set Service level for '%s' to %.2f.", vehicle:getFullName(), value))
end


function AdvancedDamageSystem.ConsoleCommands:resetVehicle()
    local vehicle = self:getTargetVehicle()
    if not vehicle then return end
    
    local spec = vehicle.spec_AdvancedDamageSystem
    spec.conditionLevel = 1.0
    spec.serviceLevel = 1.0
    vehicle:removeBreakdown()
    print(string.format("ADS: Fully reset state for '%s'.", vehicle:getFullName()))
end


function AdvancedDamageSystem.ConsoleCommands:startMaintance(rawArgs)
    local args = parseArguments(rawArgs)
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
        optionOne = AdvancedDamageSystem.REPAIR_URGENCY.MEDIUM
        optionTwo = AdvancedDamageSystem.PART_TYPES.OEM
        optionThree = false

        local visibleRepairableCount = 0
        local selected = 0
        for breakdownId, breakdown in pairs(vehicle:getActiveBreakdowns()) do
            local isRepairable = breakdownId ~= "GENERAL_WEAR" and breakdown ~= nil and breakdown.isVisible == true
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

    if spec.currentState == maintenanceType and spec.maintenanceTimer > 0 then
        local finishTime, days = vehicle:getServiceFinishTime()
        print(string.format("ADS: Started '%s' for '%s'. Remaining time: %.1f sec. Finishes in %d day(s) at %.2f.", maintenanceType, vehicle:getFullName(), spec.maintenanceTimer / 1000, days or 0, finishTime or 0))
    else
        print(string.format("ADS Error: Failed to start '%s' for '%s'.", maintenanceType, vehicle:getFullName()))
    end
end


function AdvancedDamageSystem.ConsoleCommands:finishMaintance()
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
    print(string.format("Targets: serviceStart=%s serviceTarget=%s conditionStart=%s conditionTarget=%s",
        tostring(spec.pendingMaintenanceServiceStart), tostring(spec.pendingMaintenanceServiceTarget), tostring(spec.pendingOverhaulConditionStart), tostring(spec.pendingOverhaulConditionTarget)))
    print(string.format("Levels: service=%.4f condition=%.4f", spec.serviceLevel or 0, spec.conditionLevel or 0))
    print(string.format("Queues: selected=%d inspection=%d repair=%d", #(spec.pendingSelectedBreakdowns or {}), #(spec.pendingInspectionQueue or {}), #(spec.pendingRepairQueue or {})))
    print(string.format("Breakdowns: active=%d selectedForRepair=%d totalOccurred=%d", activeBreakdownsCount, selectedForRepairCount, spec.totalBreakdownsOccurred or 0))

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

    print("--- Vehicle Debug Info ---")
    print(string.format("RawBrand: %s", g_brandManager:getBrandByIndex(vehicle:getBrand()).name))
    print(string.format("Name: %s", vehicle:getFullName()))
    print(string.format("Type: %s", vehicle.type.name))
    local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
    print(string.format("Category: %s", storeItem.categoryName))
    print(string.format("Property state: %s", vehicle.propertyState))
    local motor = vehicle:getMotor()
    print(string.format("Transmission: %s, %s, %s", motor.minForwardGearRatio, motor.gearType, motor.groupType))

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

function AdvancedDamageSystem.ConsoleCommands:debug()
    if ADS_Config.DEBUG then
        ADS_Config.DEBUG = false
    else
        ADS_Config.DEBUG = true
    end
end

addConsoleCommand("ads_listBreakdowns", "Lists all available breakdown IDs.", "listBreakdowns", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_addBreakdown", "Adds a breakdown. Usage: ads_addBreakdown [id] [stage]", "addBreakdown", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_removeBreakdown", "Removes a breakdown. Usage: ads_removeBreakdown [id]", "removeBreakdown", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_advanceBreakdown", "Advances a breakdown to the next stage. Usage: ads_advanceBreakdown [id]", "advanceBreakdown", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_setCondition", "Sets vehicle condition. Usage: ads_setCondition [0.0-1.0]", "setCondition", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_setService", "Sets vehicle service. Usage: ads_setService [0.0-1.0]", "setService", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_resetVehicle", "Resets vehicle state.", "resetVehicle", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_startService", "Starts service. Usage: ads_startService <type> [count]", "startMaintance", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_finishService", "Instantly finishes current service.", "finishMaintance", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_getServiceState", "Prints current service/workshop state variables.", "getServiceState", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_showServiceLog", "Shows service log. Usage: ads_showServiceLog [index]", "showServiceLog", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_getDebugVehicleInfo", "Vehicle debug info", "getDebugVehicleInfo", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_setDirtAmount", "Sets vehicle dirt amount. Usage: ads_setDirtAmount [0.0-1.0]", "setDirtAmount", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_debug", "Enbales/disabled ADS debug", "debug", AdvancedDamageSystem.ConsoleCommands)
