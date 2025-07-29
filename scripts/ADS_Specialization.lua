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
        NOT_REQUIRED = "ads_spec_state_not_required",
        RECOMMENDED = "ads_spec_state_recommended",
        REQUIRED = "ads_spec_state_required",
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
        MOBILE = "ads_spec_workshop_mobile",
        OWN = "ads_spec_workshop_own",
        DEALER = "ads_spec_workshop_dealer"
    }
};

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


local function tableToString(tbl)
    if not tbl or next(tbl) == nil then
        return "{}" 
    end
    
    local parts = {}
    for k, v in pairs(tbl) do
        local valueStr
        if type(v) == 'table' then
            valueStr = tableToString(v)
        else
            valueStr = tostring(v)
        end
        table.insert(parts, string.format("%s = %s", tostring(k), valueStr))
    end
    return "{ " .. table.concat(parts, ", ") .. " }"
end

-- ==========================================================
--                    SAVE/LOAD & REGISTRATION
-- ==========================================================

function AdvancedDamageSystem.serializeBreakdowns(breakdownsTable)
    local parts = {}
    for id, breakdown in pairs(breakdownsTable) do
        local visible = breakdown.isVisible and 1 or 0
        local selected = breakdown.isSelectedForRepair and 1 or 0
        
        local part = string.format("%s,%d,%.2f,%d,%d", id, breakdown.stage, breakdown.progressTimer or 0, visible, selected)
        table.insert(parts, part)
    end
    return table.concat(parts, ";")
end


function AdvancedDamageSystem.serializeDate(dateTable)
    if dateTable == nil or dateTable.day == nil then
        return ""
    end
    return string.format("%d,%d,%d", dateTable.day, dateTable.month, dateTable.year)
end


function AdvancedDamageSystem.deserializeDate(dateString)
    if dateString == nil or dateString == "" then
        return {}
    end
    
    local day, month, year = string.match(dateString, "([^,]+),([^,]+),([^,]+)")
    if day and month and year then
        return {
            day = tonumber(day),
            month = tonumber(month),
            year = tonumber(year)
        }
    end
    return {}
end


function AdvancedDamageSystem.deserializeBreakdowns(breakdownString)
    local breakdowns = {}
    if breakdownString == nil or breakdownString == "" then
        return breakdowns
    end
    
    for part in string.gmatch(breakdownString, "([^;]+)") do
        local id, stage, timer, isVisible, isSelected = string.match(part, "([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
        
        if id then
            breakdowns[id] = { 
                stage = tonumber(stage),
                progressTimer = tonumber(timer),
                isVisible = (tonumber(isVisible) == 1),
                isSelectedForRepair = (tonumber(isSelected) == 1)
            }
        else
            id, stage, timer = string.match(part, "([^,]+),([^,]+),([^,]+)")
            if id then
                breakdowns[id] = {
                    stage = tonumber(stage),
                    progressTimer = tonumber(timer),
                    isVisible = false,
                    isSelectedForRepair = true
                }
            end
        end
    end
    return breakdowns
end


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
    schemaSavegame:register(XMLValueType.FLOAT, baseKey .. "#maintenanceTimer", "Maintenance Timer")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#engineTemperature", "Engine Temperature")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#transmissionTemperature", "Transmission Temperature")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#lastServiceDate", "Last Service Date")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#lastInspectionDate", "Last Inspection Date")
    schemaSavegame:register(XMLValueType.FLOAT,  baseKey .. "#lastServiceOpHours", "Last Service Operating Hours")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#lastInspCond", "Last Inspected Condition State")
    schemaSavegame:register(XMLValueType.STRING, baseKey .. "#lastInspServ", "Last Inspected Service State")
    schemaSavegame:register(XMLValueType.FLOAT, baseKey .. "#lastInspPwr", "Last Inspected Power")
    schemaSavegame:register(XMLValueType.FLOAT, baseKey .. "#lastInspBrk", "Last Inspected Brake")
    schemaSavegame:register(XMLValueType.FLOAT, baseKey .. "#lastInspYld", "Last Inspected Yield Reduction")
    
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
    SpecializationUtil.registerFunction(vehicleType, "addBreakdown", AdvancedDamageSystem.addBreakdown)
    SpecializationUtil.registerFunction(vehicleType, "removeBreakdown", AdvancedDamageSystem.removeBreakdown)
    SpecializationUtil.registerFunction(vehicleType, "getRandomBreakdown", AdvancedDamageSystem.getRandomBreakdown)
    SpecializationUtil.registerFunction(vehicleType, "processBreakdowns", AdvancedDamageSystem.processBreakdowns)
    SpecializationUtil.registerFunction(vehicleType, "advanceBreakdown", AdvancedDamageSystem.advanceBreakdown)
    SpecializationUtil.registerFunction(vehicleType, "processPermanentEffects", AdvancedDamageSystem.processPermanentEffects)
    SpecializationUtil.registerFunction(vehicleType, "processMaintenance", AdvancedDamageSystem.processMaintenance)
    SpecializationUtil.registerFunction(vehicleType, "getServiceLevel", AdvancedDamageSystem.getServiceLevel)
    SpecializationUtil.registerFunction(vehicleType, "getConditionLevel", AdvancedDamageSystem.getConditionLevel)
    SpecializationUtil.registerFunction(vehicleType, "updateServiceLevel", AdvancedDamageSystem.updateServiceLevel)
    SpecializationUtil.registerFunction(vehicleType, "updateConditionLevel", AdvancedDamageSystem.updateConditionLevel)
    SpecializationUtil.registerFunction(vehicleType, "getActiveBreakdowns", AdvancedDamageSystem.getActiveBreakdowns)
    SpecializationUtil.registerFunction(vehicleType, "isUnderMaintenance", AdvancedDamageSystem.isUnderMaintenance)
    SpecializationUtil.registerFunction(vehicleType, "getCurrentStatus", AdvancedDamageSystem.getCurrentStatus)
    SpecializationUtil.registerFunction(vehicleType, "initMaintenance", AdvancedDamageSystem.initMaintenance)
    SpecializationUtil.registerFunction(vehicleType, "calculateWearRates", AdvancedDamageSystem.calculateWearRates)
    SpecializationUtil.registerFunction(vehicleType, "checkForNewBreakdown", AdvancedDamageSystem.checkForNewBreakdown)
    SpecializationUtil.registerFunction(vehicleType, "getMaintenancePrice", AdvancedDamageSystem.getMaintenancePrice)
    SpecializationUtil.registerFunction(vehicleType, "getInspectionPrice", AdvancedDamageSystem.getInspectionPrice)
    SpecializationUtil.registerFunction(vehicleType, "getOverhaulPrice", AdvancedDamageSystem.getOverhaulPrice)
    SpecializationUtil.registerFunction(vehicleType, "getADSRepairPrice", AdvancedDamageSystem.getADSRepairPrice)
    SpecializationUtil.registerFunction(vehicleType, "getMaintenancePriceByType", AdvancedDamageSystem.getMaintenancePriceByType)
    SpecializationUtil.registerFunction(vehicleType, "updateThermalSystems", AdvancedDamageSystem.updateThermalSystems)
    SpecializationUtil.registerFunction(vehicleType, "updateEngineThermalModel", AdvancedDamageSystem.updateEngineThermalModel)
    SpecializationUtil.registerFunction(vehicleType, "updateTransmissionThermalModel", AdvancedDamageSystem.updateTransmissionThermalModel)
    SpecializationUtil.registerFunction(vehicleType, "getFormattedMaintenanceFinishTimeText", AdvancedDamageSystem.getFormattedMaintenanceFinishTimeText)
    SpecializationUtil.registerFunction(vehicleType, "getFormattedMaintenanceDurationText", AdvancedDamageSystem.getFormattedMaintenanceDurationText)
    SpecializationUtil.registerFunction(vehicleType, "getFormattedLastInspectionText", AdvancedDamageSystem.getFormattedLastInspectionText)
    SpecializationUtil.registerFunction(vehicleType, "getFormattedLastMaintenanceText", AdvancedDamageSystem.getFormattedLastMaintenanceText)
    SpecializationUtil.registerFunction(vehicleType, "getFormattedServiceIntervalText", AdvancedDamageSystem.getFormattedServiceIntervalText)
    
end


function AdvancedDamageSystem:saveToXMLFile(xmlFile, key, usedModNames)
    log_dbg("saveToXMLFile called for vehicle:", self:getFullName(), "with key:", key)
    local spec = self.spec_AdvancedDamageSystem
    if spec ~= nil then
        xmlFile:setValue(key .. "#service", spec.serviceLevel)
        xmlFile:setValue(key .. "#condition", spec.conditionLevel)
        
        local breakdownString = AdvancedDamageSystem.serializeBreakdowns(spec.activeBreakdowns)
        xmlFile:setValue(key .. "#breakdowns", breakdownString)
        xmlFile:setValue(key .. "#state", spec.currentState)
        xmlFile:setValue(key .. "#maintenanceTimer", spec.maintenanceTimer)
        xmlFile:setValue(key .. "#lastServiceDate", AdvancedDamageSystem.serializeDate(spec.lastServiceDate))
        xmlFile:setValue(key .. "#lastInspectionDate", AdvancedDamageSystem.serializeDate(spec.lastInspectionDate))
        xmlFile:setValue(key .. "#lastServiceOpHours", spec.lastServiceOperatingHours)
        xmlFile:setValue(key .. "#lastInspCond", spec.lastInspectedConditionState)
        xmlFile:setValue(key .. "#lastInspServ", spec.lastInspectedServiceState)
        xmlFile:setValue(key .. "#engineTemperature", spec.engineTemperature)
        xmlFile:setValue(key .. "#transmissionTemperature", spec.transmissionTemperature)
        xmlFile:setValue(key .. "#lastInspPwr", spec.lastInspectedPower)
        xmlFile:setValue(key .. "#lastInspBrk", spec.lastInspectedBrake)
        xmlFile:setValue(key .. "#lastInspYld", spec.lastInspectedYieldReduction)
        
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
    self.spec_AdvancedDamageSystem.engTermPID = {
        integral = 0,
        lastError = 0,
    }

    self.spec_AdvancedDamageSystem.transmissionTemperature = -99
    self.spec_AdvancedDamageSystem.rawTransmissionTemperature = -99
    self.spec_AdvancedDamageSystem.transmissionThermostatState = 0.0
    self.spec_AdvancedDamageSystem.transmissionThermostatHealth = 1.0
    self.spec_AdvancedDamageSystem.transTermPID = {
        integral = 0,
        lastError = 0,
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
            hotTransFactor = 0
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
            convectionCooling = 0
        },

        transmissionTemp = {
            totalHeat = 0, 
            totalCooling = 0, 
            radiatorCooling = 0, 
            speedCooling = 0, 
            convectionCooling = 0,
            loadFactor = 0,
            slipFactor = 0,
            accFactor = 0
        }
    }

    self.spec_AdvancedDamageSystem.effectsUpdateTimer = ADS_Config.EFFECTS_UPDATE_DELAY
    self.spec_AdvancedDamageSystem.metaUpdateTimer = math.random() * ADS_Config.META_UPDATE_DELAY
    self.spec_AdvancedDamageSystem.maintenanceTimer = 0
    self.spec_AdvancedDamageSystem.currentState = AdvancedDamageSystem.STATUS.READY
    self.spec_AdvancedDamageSystem.workshopType = AdvancedDamageSystem.WORKSHOP.DEALER
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
        spec.maintenanceTimer = savegame.xmlFile:getValue(key .. "#maintenanceTimer", spec.maintenanceTimer) 

        local breakdownString = savegame.xmlFile:getValue(key .. "#breakdowns", "")
        if breakdownString and breakdownString ~= "" then
            spec.activeBreakdowns = AdvancedDamageSystem.deserializeBreakdowns(breakdownString)
        else
            spec.activeBreakdowns = {}
        end

        local serviceDateString = savegame.xmlFile:getValue(key .. "#lastServiceDate", "")
        spec.lastServiceDate = AdvancedDamageSystem.deserializeDate(serviceDateString)
        
        local inspectionDateString = savegame.xmlFile:getValue(key .. "#lastInspectionDate", "")
        spec.lastInspectionDate = AdvancedDamageSystem.deserializeDate(inspectionDateString)
        spec.lastServiceOperatingHours = savegame.xmlFile:getValue(key .. "#lastServiceOpHours", spec.lastServiceOperatingHours)
        spec.lastInspectedConditionState = savegame.xmlFile:getValue(key .. "#lastInspCond", spec.lastInspectedConditionState)
        spec.lastInspectedServiceState = savegame.xmlFile:getValue(key .. "#lastInspServ", spec.lastInspectedServiceState)
        spec.engineTemperature = savegame.xmlFile:getValue(key .. "#engineTemperature", spec.engineTemperature)
        spec.transmissionTemperature = savegame.xmlFile:getValue(key .. "#transmissionTemperature", spec.transmissionTemperature)
        spec.lastInspectedPower = savegame.xmlFile:getValue(key .. "#lastInspPwr", spec.lastInspectedPower)
        spec.lastInspectedBrake = savegame.xmlFile:getValue(key .. "#lastInspBrk", spec.lastInspectedBrake)
        spec.lastInspectedYieldReduction = savegame.xmlFile:getValue(key .. "#lastInspYld", spec.lastInspectedYieldReduction)

        if spec.serviceLevel == nil then spec.serviceLevel = spec.baseServiceLevel end
        if spec.conditionLevel == nil then spec.conditionLevel = spec.baseConditionLevel end
        if spec.maintenanceTimer == nil then spec.maintenanceTimer = 0 end
        if spec.currentState == nil then spec.currentState = AdvancedDamageSystem.STATUS.READY end
        if spec.lastServiceDate == nil then spec.lastServiceDate = {} end
        if spec.lastInspectionDate == nil then spec.lastInspectionDate = {} end
        if spec.lastServiceOperatingHours == nil then spec.lastServiceOperatingHours = 0 end
        if spec.lastInspectedConditionState == nil then spec.lastInspectedConditionState = AdvancedDamageSystem.STATES.UNKNOWN end
        if spec.lastInspectedServiceState == nil then spec.lastInspectedServiceState = AdvancedDamageSystem.STATES.UNKNOWN end
        if spec.engineTemperature == nil then spec.engineTemperature = -99 end
        if spec.transmissionTemperature == nil then spec.transmissionTemperature = -99 end
        if spec.lastInspectedPower == nil then spec.lastInspectedPower = 1 end
        if spec.lastInspectedBrake == nil then spec.lastInspectedBrake = 1 end
        if spec.lastInspectedYieldReduction == nil then spec.lastInspectedYieldReduction = 1 end

        local debugLines = {}
        table.insert(debugLines, string.format("--- [AdvancedDamageSystem] Full State Loaded for: %s ---", self:getFullName()))
        table.insert(debugLines, string.format("  - Service Level: %s", tostring(spec.serviceLevel)))
        table.insert(debugLines, string.format("  - Condition Level: %s", tostring(spec.conditionLevel)))
        table.insert(debugLines, string.format("  - Current State: %s", tostring(spec.currentState)))
        table.insert(debugLines, string.format("  - Maintenance Timer: %s", tostring(spec.maintenanceTimer)))
        table.insert(debugLines, string.format("  - Last Service Operating Hours: %.2f", spec.lastServiceOperatingHours))
        
        table.insert(debugLines, string.format("  - Engine Temperature: %.2f", spec.engineTemperature))
        table.insert(debugLines, string.format("  - Transmission Temperature: %.2f", spec.transmissionTemperature))

        table.insert(debugLines, string.format("  - Last Inspected Condition State: %s", tostring(spec.lastInspectedConditionState)))
        table.insert(debugLines, string.format("  - Last Inspected Service State: %s", tostring(spec.lastInspectedServiceState)))
        table.insert(debugLines, string.format("  - Last Inspected Power: %.2f", spec.lastInspectedPower))
        table.insert(debugLines, string.format("  - Last Inspected Brake: %.2f", spec.lastInspectedBrake))
        table.insert(debugLines, string.format("  - Last Inspected Yield Reduction: %.2f", spec.lastInspectedYieldReduction))

        table.insert(debugLines, string.format("  - Active Breakdowns: %s", tableToString(spec.activeBreakdowns)))
        
        local serviceDateStr = "Not set"
        if spec.lastServiceDate and next(spec.lastServiceDate) ~= nil then

            serviceDateStr = string.format("%04d-%02d-%02d", spec.lastServiceDate.year or 0, spec.lastServiceDate.month or 0, spec.lastServiceDate.day or 0)
        end
        table.insert(debugLines, string.format("  - Last Service Date: %s", serviceDateStr))
        
        local inspectionDateStr = "Not set"
        if spec.lastInspectionDate and next(spec.lastInspectionDate) ~= nil then
            inspectionDateStr = string.format("%04d-%02d-%02d", spec.lastInspectionDate.year or 0, spec.lastInspectionDate.month or 0, spec.lastInspectionDate.day or 0)
        end
        table.insert(debugLines, string.format("  - Last Inspection Date: %s", inspectionDateStr))

        table.insert(debugLines, "-------------------------------------------------------------")

        log_dbg(table.concat(debugLines, "\n"))
    end

    local xmlSoundFile = loadXMLFile("ads_sounds", AdvancedDamageSystem.modDirectory .. "sounds/ads_sounds.xml")
    if spec.samples == nil then
        spec.samples = {}
    end
    
    if xmlSoundFile ~= nil then
        spec.samples.starter = g_soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "starter", AdvancedDamageSystem.modDirectory, self.rootNode, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.alarm = g_soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "alarm", AdvancedDamageSystem.modDirectory, self.rootNode, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.transmissionShiftFailed1 = g_soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "transmissionShiftFailed1", AdvancedDamageSystem.modDirectory, self.rootNode, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.transmissionShiftFailed2 = g_soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "transmissionShiftFailed2", AdvancedDamageSystem.modDirectory, self.rootNode, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.transmissionShiftFailed3 = g_soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "transmissionShiftFailed3", AdvancedDamageSystem.modDirectory, self.rootNode, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.brakes1 = g_soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "brakes1", AdvancedDamageSystem.modDirectory, self.rootNode, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.brakes2 = g_soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "brakes2", AdvancedDamageSystem.modDirectory, self.rootNode, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.brakes3 = g_soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "brakes3", AdvancedDamageSystem.modDirectory, self.rootNode, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.turbocharger1 = g_soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "turbocharger1", AdvancedDamageSystem.modDirectory, self.rootNode, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.turbocharger2 = g_soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "turbocharger2", AdvancedDamageSystem.modDirectory, self.rootNode, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.turbocharger3 = g_soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "turbocharger3", AdvancedDamageSystem.modDirectory, self.rootNode, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.turbocharger4 = g_soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "turbocharger4", AdvancedDamageSystem.modDirectory, self.rootNode, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.gearDisengage1 = g_soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "gearDisengage1", AdvancedDamageSystem.modDirectory, self.rootNode, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        delete(xmlSoundFile)
    else
        log_dbg("ERROR: AdvancedDamageSystem - Could not load ads_sounds.xml")
    end

    spec.rawEngineTemperature = spec.engineTemperature
    spec.rawTransmissionTemperature = spec.transmissionTemperature

    local function getIsElectricVehicle(vehicle)
        for _, consumer in pairs(vehicle.spec_motorized.consumers) do
            if consumer.fillType == FillType.ELECTRICCHARGE then
                return true
            end
        end
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

    --- Registration in ADS_Main.vehicles
    if ADS_Main and ADS_Main.vehicles and ADS_Main.vehicles[self.uniqueId] == nil then
        if (self.propertyState == 2 or self.propertyState == 3 or self.propertyState == 4) and self.ownerFarmId ~= 0 and self.ownerFarmId < 10 then
            log_dbg(" -> Registering vehicle in ADS_Main.vehicles list. ID:", self.uniqueId)
            --- Registration in ADS_Main.vehicles
            ADS_Main.vehicles[self.uniqueId] = self
            ADS_Main.numVehicles = ADS_Main.numVehicles + 1

            --- if first mod load or used vehicle
            if self:getOperatingTime() > 0 and spec.conditionLevel == spec.baseConditionLevel or self:getDamageAmount() > 0 then
                spec.serviceLevel = 1 - self:getDamageAmount()
                spec.conditionLevel = math.max(1 - self:getFormattedOperatingTime() / 150, math.random() * 0.3)
                self:setDamageAmount(0.0, true)
                AdvancedDamageSystem.setLastInspectionStates(self, spec.serviceLevel, spec.conditionLevel)
            elseif self:getDamageAmount() == 0 and self:getOperatingTime() == 0 and spec.serviceLevel == spec.baseServiceLevel and spec.conditionLevel == spec.baseConditionLevel then
                AdvancedDamageSystem.setLastInspectionStates(self, spec.serviceLevel, spec.conditionLevel)
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

    --- just in case
    if self:getDamageAmount() ~= 0 then self:setDamageAmount(0.0, true) end

    --- Overheat protection for vehcile > 2000 year and engine failure from overheating for < 2000
    if spec.year >= 2000 then
        local overheatProtection = spec.activeBreakdowns['OVERHEAT_PROTECTION']
        if overheatProtection and spec.transmissionTemperature < 100 and spec.engineTemperature < 100 then
            self:removeBreakdown('OVERHEAT_PROTECTION')    
        end
        if self:getIsMotorStarted() then
            if (spec.transmissionTemperature > 105 or spec.engineTemperature > 105) and not overheatProtection then
                self:addBreakdown('OVERHEAT_PROTECTION', 1)
                g_soundManager:playSample(spec.samples.alarm)
            elseif overheatProtection then
                if self:getCruiseControlState() ~= 0 then
                    self:setCruiseControlState(0, true)
                end
                if (spec.transmissionTemperature > 125 or spec.engineTemperature > 125) and overheatProtection.stage < 4 then
                    self:advanceBreakdown('OVERHEAT_PROTECTION')
                    g_soundManager:playSample(spec.samples.alarm)
                elseif (spec.transmissionTemperature > 115 or spec.engineTemperature > 115) and overheatProtection.stage < 3 then
                    self:advanceBreakdown('OVERHEAT_PROTECTION')
                    g_soundManager:playSample(spec.samples.alarm)
                elseif (spec.transmissionTemperature > 110 or spec.engineTemperature > 110) and overheatProtection.stage < 2 then
                    self:advanceBreakdown('OVERHEAT_PROTECTION')
                    g_soundManager:playSample(spec.samples.alarm)
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

    --- Messages, Ai worker
    if spec ~= nil and spec.activeFunctions ~= nil and next(spec.activeEffects) ~= nil then
        for _, effectData in pairs(spec.activeEffects) do
            if effectData ~= nil and effectData.extraData ~= nil and effectData.extraData.message ~= nil then
                if self.getIsControlled ~= nil and self:getIsControlled() and not self:isUnderMaintenance() then
                    g_currentMission:showBlinkingWarning(g_i18n:getText(effectData.extraData.message), 200)
                end
                if self:getIsAIActive() and effectData.extraData.disableAi then 
                    self:stopCurrentAIJob(AIMessageErrorVehicleBroken.new()) 
                end
            end
        end
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

    if self:isUnderMaintenance() then
        self:processMaintenance(dt)
    else
        local serviceWearRate, conditionWearRate = self:calculateWearRates()
        if self:getIsOperating() then
            self:processBreakdowns(dt)
            self:checkForNewBreakdown(dt, conditionWearRate)
        end
        self:updateConditionLevel(conditionWearRate, dt)
        self:updateServiceLevel(serviceWearRate, dt)
    end
end

-- ==========================================================
--                      CORE FUNCTIONS
-- ==========================================================

------------------- temperatures -------------------

function AdvancedDamageSystem:updateThermalSystems(dt)
    local motor = self:getMotor()
    if not motor then return end

    local spec = self.spec_AdvancedDamageSystem
    local vehicleHaveCVT = (motor.minForwardGearRatio ~= nil and spec.year >= 2000)
    
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

    if spec.engineTemperature < eviromentTemp then spec.engineTemperature = eviromentTemp end
    if spec.rawEngineTemperature < eviromentTemp then spec.rawEngineTemperature = eviromentTemp end
    if vehicleHaveCVT then
        if spec.transmissionTemperature < eviromentTemp then spec.transmissionTemperature = eviromentTemp end
        if spec.rawTransmissionTemperature < eviromentTemp then spec.rawTransmissionTemperature = eviromentTemp end
    end

    local engineDebugData = {}
    if not spec.isElectricVehicle then 
        engineDebugData = self:updateEngineThermalModel(dt, spec, isMotorStarted, motorLoad, speedCooling, eviromentTemp, dirt)
    end
    
    local transDebugData = {}
    if vehicleHaveCVT then
        transDebugData = self:updateTransmissionThermalModel(dt, spec, isMotorStarted, motorLoad, motorRpm, speed, speedCooling, eviromentTemp, dirt)
    end

    if ADS_Config.DEBUG then
        spec.debugData.engineTemp = engineDebugData
        spec.debugData.transmissionTemp = transDebugData
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
        cooling = convectionCooling
    end
    
    local alpha = dt / (C.TAU + dt)
    spec.rawEngineTemperature = spec.rawEngineTemperature + (heat - cooling) * (dt / 1000) * C.TEMPERATURE_CHANGE_SPEED
    spec.rawEngineTemperature = math.max(spec.rawEngineTemperature, eviromentTemp)
    spec.engineTemperature = math.max(spec.engineTemperature + alpha * (spec.rawEngineTemperature - spec.engineTemperature), eviromentTemp)
    
    if isMotorStarted and spec.engineTemperature > C.ENGINE_THERMOSTAT_MIN_TEMP then
        spec.thermostatState = AdvancedDamageSystem.getNewTermostatState(dt, spec.engineTemperature, spec.engTermPID, spec.thermostatHealth)
    else
        spec.thermostatState = 0.0
        spec.engTermPID.integral = 0
        spec.engTermPID.lastError = 0
    end

    return {totalHeat = heat, totalCooling = cooling, radiatorCooling = radiatorCooling, speedCooling = speedCooling, convectionCooling = convectionCooling}
end


function AdvancedDamageSystem:updateTransmissionThermalModel(dt, spec, isMotorStarted, motorLoad, motorRpm, speed, speedCooling, eviromentTemp, dirt)
    local C = ADS_Config.THERMAL
    local heat, cooling = 0, 0
    local radiatorCooling, convectionCooling = 0, 0
    local motor = self:getMotor()
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
        cooling = convectionCooling
    end

    local alpha = dt / (C.TAU + dt)
    spec.rawTransmissionTemperature = spec.rawTransmissionTemperature + (heat - cooling) * (dt / 1000) * C.TEMPERATURE_CHANGE_SPEED
    spec.rawTransmissionTemperature = math.max(spec.rawTransmissionTemperature, eviromentTemp)
    spec.transmissionTemperature = math.max(spec.transmissionTemperature + alpha * (spec.rawTransmissionTemperature - spec.transmissionTemperature), eviromentTemp)

    if isMotorStarted and spec.transmissionTemperature > C.TRANS_THERMOSTAT_MIN_TEMP then
        spec.transmissionThermostatState = AdvancedDamageSystem.getNewTermostatState(dt, spec.transmissionTemperature, spec.transTermPID, spec.transmissionThermostatHealth)
    else
        spec.transmissionThermostatState = 0.0
        spec.transTermPID.integral = 0
        spec.transTermPID.lastError = 0
    end
    
    return {totalHeat = heat, totalCooling = cooling, radiatorCooling = radiatorCooling, speedCooling = speedCooling, convectionCooling = convectionCooling, loadFactor = loadFactor, slipFactor = slipFactor, accFactor = accFactor}
end


function AdvancedDamageSystem.getNewTermostatState(dt, currentTemp, pidData, thermostatHealth)
    local C = ADS_Config.THERMAL
    local dtSeconds = dt / 1000
    
    local errorTemp = currentTemp - C.PID_TARGET_TEMP
    local derivative = (errorTemp - pidData.lastError) / dtSeconds
    local newIntegral = pidData.integral + errorTemp * dtSeconds

    local controlSignal_temp = C.PID_KP * errorTemp + C.PID_KI * newIntegral + C.PID_KD * derivative
    if not ((controlSignal_temp <= 0 and errorTemp < 0) or (controlSignal_temp >= 1 and errorTemp > 0)) then
        pidData.integral = math.clamp(newIntegral, -C.PID_MAX_INTEGRAL, C.PID_MAX_INTEGRAL)
    end
    
    local controlSignal = C.PID_KP * errorTemp + C.PID_KI * pidData.integral + C.PID_KD * derivative
    pidData.lastError = errorTemp
    
    return math.clamp(controlSignal, 0.0, thermostatHealth)
end

------------------- service and condition-------------------

function AdvancedDamageSystem:calculateWearRates()
    local spec = self.spec_AdvancedDamageSystem
    local C = ADS_Config.CORE
    local conditionWearRate = 1.0
    local serviceWearRate = 1.0
    local motorLoadFactor, expiredServiceFactor, coldMotorFactor, hotMotorFactor, hotTransFactor = 0, 0, 0, 0, 0

    if self.getIsMotorStarted ~= nil and self:getIsMotorStarted() and not spec.isElectricVehicle then
        local motorLoad = self:getMotorLoadPercentage()
        if motorLoad > C.MOTOR_OVERLOADED_THRESHOLD then
            motorLoadFactor = ADS_Utils.calculateQuadraticMultiplier(motorLoad, C.MOTOR_OVERLOADED_THRESHOLD, false)
            motorLoadFactor = motorLoadFactor * C.MOTOR_OVERLOADED_MAX_MULTIPLIER
            conditionWearRate = conditionWearRate + motorLoadFactor
        end

        if spec.serviceLevel < C.SERVICE_EXPIRED_THRESHOLD then
            expiredServiceFactor = ADS_Utils.calculateQuadraticMultiplier(spec.serviceLevel, C.SERVICE_EXPIRED_THRESHOLD, true)
            expiredServiceFactor = expiredServiceFactor * C.SERVICE_EXPIRED_MAX_MULTIPLIER
            conditionWearRate = conditionWearRate + expiredServiceFactor
        end

        if spec.engineTemperature < C.COLD_MOTOR_THRESHOLD and motorLoad > 0.3 and not spec.isElectricVehicle then
            coldMotorFactor = ADS_Utils.calculateQuadraticMultiplier(spec.engineTemperature, C.COLD_MOTOR_THRESHOLD, true)
            local motorLoadInf = ADS_Utils.calculateQuadraticMultiplier(motorLoad, 0.3, false)
            coldMotorFactor = coldMotorFactor * C.COLD_MOTOR_MAX_MULTIPLIER * motorLoadInf
            conditionWearRate = conditionWearRate + coldMotorFactor

        elseif spec.engineTemperature > C.OVERHEAT_MOTOR_THRESHOLD and motorLoad > 0.3 and not spec.isElectricVehicle then
            hotMotorFactor = ADS_Utils.calculateQuadraticMultiplier(spec.engineTemperature, C.OVERHEAT_MOTOR_THRESHOLD, false, 120)
            local motorLoadInf = ADS_Utils.calculateQuadraticMultiplier(motorLoad, 0.3, false)
            hotMotorFactor = hotMotorFactor * C.OVERHEAT_MOTOR_MAX_MULTIPLIER * motorLoadInf
            conditionWearRate = conditionWearRate + hotMotorFactor
        end

        if spec.transmissionTemperature > C.OVERHEAT_TRANSMISSION_THRESHOLD then
            hotTransFactor = ADS_Utils.calculateQuadraticMultiplier(spec.transmissionTemperature, C.OVERHEAT_TRANSMISSION_THRESHOLD, false, 120)
            local motorLoadInf = ADS_Utils.calculateQuadraticMultiplier(motorLoad, 0.3, false)
            hotTransFactor = hotTransFactor * C.OVERHEAT_TRANSMISSION_MAX_MULTIPLIER * motorLoadInf * self:getMotorRpmPercentage()
            conditionWearRate = conditionWearRate + hotTransFactor
        end

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
        spec.debugData.condition = {totalWearRate = conditionWearRate, motorLoadFactor = motorLoadFactor, expiredServiceFactor = expiredServiceFactor, coldMotorFactor = coldMotorFactor, hotMotorFactor = hotMotorFactor, hotTransFactor = hotTransFactor}
        spec.debugData.service.totalWearRate = serviceWearRate
    end
    return serviceWearRate, conditionWearRate
end

function AdvancedDamageSystem:updateServiceLevel(wearRate, dt)
    local spec = self.spec_AdvancedDamageSystem
    local newLevel = spec.serviceLevel - (wearRate * ADS_Config.CORE.BASE_SERVICE_WEAR / (60 * 60 * 1000) * dt)
    spec.serviceLevel = math.clamp(newLevel, 0.001, 1)
end

function AdvancedDamageSystem:updateConditionLevel(wearRate, dt)
    local spec = self.spec_AdvancedDamageSystem
    local newLevel = spec.conditionLevel - (wearRate * ADS_Config.CORE.BASE_CONDITION_WEAR / (60 * 60 * 1000) * dt)
    spec.conditionLevel = math.clamp(newLevel, 0.001, 1)
end

---------------------- breakdowns ----------------------

function AdvancedDamageSystem:checkForNewBreakdown(dt, conditionWearRate)
    local spec = self.spec_AdvancedDamageSystem
    if not spec or dt == 0 then
        return
    end
    local probability = ADS_Config.CORE.BREAKDOWN_PROBABILITY

    local failureChancePerFrame = AdvancedDamageSystem.calculateBreakdownProbability(spec.conditionLevel, probability, dt)
    failureChancePerFrame = (failureChancePerFrame * conditionWearRate + (failureChancePerFrame * spec.extraBreakdownProbability))
    failureChancePerFrame = failureChancePerFrame / spec.reliability

    local random = math.random()

    if random < failureChancePerFrame then
        
        local breakdownId = self:getRandomBreakdown()
        if breakdownId == nil then return end

        local criticalOutcomeChance = math.clamp((1 - spec.conditionLevel) ^ probability.CRITICAL_DEGREE, probability.CRITICAL_MIN, probability.CRITICAL_MAX)

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
        if spec.debugDate == nil then spec.debugDate = {} end

        local hourlyProb = 1 - (1 - failureChancePerFrame) ^ (3600000 / dt)
        local criticalChance = math.clamp((1 - spec.conditionLevel) ^ probability.CRITICAL_DEGREE, probability.CRITICAL_MIN, probability.CRITICAL_MAX)

        if self:getIsControlled() then
            print(failureChancePerFrame .. " " .. hourlyProb)
        end
        
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

    local activeBreakdowns = self.spec_AdvancedDamageSystem.activeBreakdowns
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

    local activeBreakdowns = self.spec_AdvancedDamageSystem.activeBreakdowns
    local activeBreakdownsCount = 0
    for _, _ in pairs(activeBreakdowns) do
        activeBreakdownsCount = activeBreakdownsCount + 1
    end

    if activeBreakdownsCount >= ADS_Config.CORE.CONCURRENT_BREAKDOWN_LIMIT_PER_VEHICLE then
        log_dbg("-> Concurrent breakdown limit reached for vehicle:", self:getFullName())
        return nil 
    end
    
    local registryEntry = ADS_Breakdowns.BreakdownRegistry[breakdownId]

    if registryEntry == nil then
        log_dbg("-> Breakdown ID not found in registry. Aborting.")
        return
    end
    
    if spec.activeBreakdowns[breakdownId] then
        log_dbg("-> Breakdown already active. Aborting.")
        return
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

    for id, breakdown in pairs(spec.activeBreakdowns) do
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

                                log_dbg(string.format("ADS: Breakdown '%s' on vehicle '%s' advanced to stage %d.", id, self:getFullName(), breakdown.stage))
                            else
                                breakdown.progressTimer = stageDuration
                                breakdown.isVisible = true
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


function AdvancedDamageSystem:processPermanentEffects(dt)
    log_dbg("processPermanentEffects TICK for vehicle:", self:getFullName())
    local spec = self.spec_AdvancedDamageSystem
    if not spec then
        return
    end

    if spec.activeBreakdowns['GENERAL_WEAR_AND_TEAR'] ~= nil and spec.conditionLevel > 0.67 then
        log_dbg("Condition improved. Removing GENERAL_WEAR_AND_TEAR.")
        self:removeBreakdown('GENERAL_WEAR_AND_TEAR')
    elseif spec.activeBreakdowns['GENERAL_WEAR_AND_TEAR'] == nil and spec.conditionLevel < 0.66 then
        log_dbg("Condition degraded. Adding GENERAL_WEAR_AND_TEAR.")
        self:addBreakdown('GENERAL_WEAR_AND_TEAR', 1)
    end
    if spec.activeBreakdowns['POOR_QUALITY_PARTS'] ~= nil and spec.activeBreakdowns['POOR_QUALITY_PARTS'].progressTimer >= ADS_Config.MAINTENANCE.AFTERMARKETS_PARTS_BREAKDOWN_DURATION then
        self:removeBreakdown('POOR_QUALITY_PARTS')
    end

    self:recalculateAndApplyEffects()
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

    for id, breakdown in pairs(spec.activeBreakdowns) do
        local registryEntry = ADS_Breakdowns.BreakdownRegistry[id]
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
    log_dbg("Recalculated effects:", tableToString(spec.activeEffects))

    for effectId, applicator in pairs(ADS_Breakdowns.EffectApplicators) do
        local isCurrentlyActive = spec.activeEffects[effectId] ~= nil
        local wasPreviouslyActive = previouslyActiveEffects[effectId] ~= nil


        if isCurrentlyActive then
            if applicator.apply then
                applicator.apply(self, spec.activeEffects[effectId], applicator)
                if spec.activeEffects[effectId].extraData ~= nil and spec.activeEffects[effectId].extraData.message ~= nil and self.getIsControlled ~= nil and not self:getIsControlled() then
                    g_currentMission.hud:addSideNotification(ADS_Breakdowns.COLORS.WARNING, self:getFullName() .. ": " .. g_i18n:getText(spec.activeEffects[effectId].extraData.message))
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

    for id, breakdown in pairs(spec.activeBreakdowns) do
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

    log_dbg("Recalculated indicators:", tableToString(spec.activeIndicators))
    log_dbg("-> recalculateAndApplyIndicators finished.")
end


--------------------- maintenance --------------------------------

function AdvancedDamageSystem:initMaintenance(type, workshopType, breadownsCount, isAftermarketParts)
    local spec = self.spec_AdvancedDamageSystem
    local states = AdvancedDamageSystem.STATUS
    local vehicleState = self:getCurrentStatus()
    local C = ADS_Config.MAINTENANCE
    
    if vehicleState == states.READY and spec.maintenanceTimer == 0 then
        if self:getIsOperating() then
            self:stopMotor()
        end
        local totalTimeMs = 0
        spec.currentState = type
        spec.workshopType = workshopType

        if type == states.INSPECTION then
            totalTimeMs = C.INSPECTION_TIME
            local breakdownRegistry = ADS_Breakdowns.BreakdownRegistry
            for id, breakdown in pairs(spec.activeBreakdowns) do
                if not breakdown.isVisible then
                    local chance = breakdownRegistry[id].stages[breakdown.stage].detectionChance
                    if math.random() < chance then
                        breakdown.isVisible = true
                    end
                end
            end

        elseif type == states.MAINTENANCE then
            totalTimeMs = C.MAINTENANCE_TIME
            spec.serviceLevel = 1.0

        elseif type == states.REPAIR then
            totalTimeMs = C.REPAIR_TIME * (breadownsCount or 0)
            local idsToRepair = {}
            for id, breakdown in pairs(spec.activeBreakdowns) do
                if breakdown.isSelectedForRepair then
                    table.insert(idsToRepair, id)
                end
            end
            if #idsToRepair > 0 then
                self:removeBreakdown(table.unpack(idsToRepair))
            end

        elseif type == states.OVERHAUL then
            totalTimeMs = C.OVERHAUL_TIME
            
            if next(spec.activeBreakdowns) ~= nil then
                local idsToRepair = {}
                for id, _ in pairs(spec.activeBreakdowns) do
                    if ADS_Breakdowns.BreakdownRegistry[id] and ADS_Breakdowns.BreakdownRegistry[id].isSelectable then
                        table.insert(idsToRepair, id)
                    end
                end
                if #idsToRepair > 0 then
                    self:removeBreakdown(table.unpack(idsToRepair))
                end
            end
            
            spec.serviceLevel = 1.0
            
            if spec.conditionLevel < spec.baseConditionLevel then
                local missingCondition = spec.baseConditionLevel - spec.conditionLevel
                local minRestore, maxRestore = C.OVERHAUL_MIN_CONDITION_RESTORE, C.OVERHAUL_MAX_CONDITION_RESTORE
                if isAftermarketParts then
                    minRestore = minRestore / 2
                end
                local ageFactor = math.max(math.log10(self.age), 1)
                local randomFactor = minRestore + math.random() * (maxRestore - minRestore)
                local restoredAmount = math.min(missingCondition * randomFactor * spec.maintainability, missingCondition) / ageFactor 
                spec.conditionLevel = math.min(spec.baseConditionLevel, spec.conditionLevel + restoredAmount)
            end
            
        end


        AdvancedDamageSystem.setLastInspectionStates(self, spec.serviceLevel, spec.conditionLevel)
        spec.lastServiceOperatingHours = self:getFormattedOperatingTime()
        spec.lastInspectedPower = (spec.activeEffects.ENGINE_TORQUE_MODIFIER and (1 + spec.activeEffects.ENGINE_TORQUE_MODIFIER.value)) or 1
        spec.lastInspectedBrake = (spec.activeEffects.BRAKE_FORCE_MODIFIER and (1 + spec.activeEffects.BRAKE_FORCE_MODIFIER.value)) or 1
        spec.lastInspectedYieldReduction = (spec.activeEffects.YIELD_REDUCTION_MODIFIER and (1 + spec.activeEffects.YIELD_REDUCTION_MODIFIER.value)) or 1

        local env = g_currentMission.environment
        spec.lastInspectionDate = { day = env.currentDay, month = env.currentPeriod, year = env.currentYear }

        if type ~= states.INSPECTION and type ~= states.REPAIR then
            spec.lastServiceDate = { day = env.currentDay, month = env.currentPeriod, year = env.currentYear }
        end
        

        if isAftermarketParts then
            local chance = C.AFTERMARKETS_PARTS_BREAKDOWN_CHANCE
            if type == AdvancedDamageSystem.STATUS.REPAIR then
                chance = chance + (breadownsCount * 0.33)
            end
            if math.random() < chance then
                if spec.activeBreakdowns['POOR_QUALITY_PARTS'] ~= nil then
                    self:removeBreakdown('POOR_QUALITY_PARTS')
                end
                local stage = math.random(3)
                self:addBreakdown('POOR_QUALITY_PARTS', stage) 
            end
        end

        if totalTimeMs > 0 then
            spec.maintenanceTimer = totalTimeMs
            log_dbg(string.format('%s initiated for %s, will take %s ms. Aftermarket: %s', spec.currentState, self:getFullName(), totalTimeMs, tostring(isAftermarketParts)))
        else
            spec.currentState = states.READY
        end
    end
end


function AdvancedDamageSystem:processMaintenance(dt)
    local spec = self.spec_AdvancedDamageSystem
    local states = AdvancedDamageSystem.STATUS
    local vehicleState = self:getCurrentStatus()

    if vehicleState == states.READY 
        or (spec.workshopType == AdvancedDamageSystem.WORKSHOP.DEALER and not ADS_Main.isWorkshopOpen)
        or (spec.workshopType == AdvancedDamageSystem.WORKSHOP.OWN and not ADS_Main.isWorkshopOpen) then
            return
    end

    local timeScale = g_currentMission.missionInfo.timeScale
    spec.maintenanceTimer = spec.maintenanceTimer - dt * timeScale

    if spec.maintenanceTimer <= 0 then
        if spec.currentState ~= states.INSPECTION then
            self:setDirtAmount(0)
        end
        g_currentMission.hud:addSideNotification({1, 1, 1, 1}, self:getFullName() .. ": " .. g_i18n:getText(spec.currentState) .. " " .. g_i18n:getText("ads_spec_maintenance_complete"))
        spec.maintenanceTimer = 0
        spec.currentState = states.READY
        ADS_VehicleChangeStatusEvent.send(ADS_VehicleChangeStatusEvent.new(self))
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


function AdvancedDamageSystem:isUnderMaintenance()
    if self.spec_AdvancedDamageSystem.currentState ~= AdvancedDamageSystem.STATUS.READY then
        return true
    end
    return false 
end


function AdvancedDamageSystem:getCurrentStatus()
    return self.spec_AdvancedDamageSystem.currentState
end


function AdvancedDamageSystem:getActiveBreakdowns()
    return self.spec_AdvancedDamageSystem.activeBreakdowns
end


function AdvancedDamageSystem:getInspectionPrice()
    return AdvancedDamageSystem.calculateMaintenancePrice(self, AdvancedDamageSystem.STATUS.INSPECTION)
end


function AdvancedDamageSystem:getMaintenancePrice()
    return AdvancedDamageSystem.calculateMaintenancePrice(self, AdvancedDamageSystem.STATUS.MAINTENANCE)
end


function AdvancedDamageSystem:getOverhaulPrice()
    return AdvancedDamageSystem.calculateMaintenancePrice(self, AdvancedDamageSystem.STATUS.OVERHAUL)
end


function AdvancedDamageSystem:getADSRepairPrice(breakdown)
    if breakdown then
        return AdvancedDamageSystem.calculateMaintenancePrice(self, AdvancedDamageSystem.STATUS.REPAIR, breakdown)
    else
        return AdvancedDamageSystem.calculateMaintenancePrice(self, AdvancedDamageSystem.STATUS.REPAIR)
    end
end


function AdvancedDamageSystem:getMaintenancePriceByType(type, breakdowns)
    if breakdowns then
        return AdvancedDamageSystem.calculateMaintenancePrice(self, type, breakdowns)
    else
        return AdvancedDamageSystem.calculateMaintenancePrice(self, type)
    end
end

-- ==========================================================
--                      GUI AND HUD
-- ==========================================================


function AdvancedDamageSystem:getFormattedMaintenanceFinishTimeText(maintenanceType, workshopType)
    local currentStatus = self:getCurrentStatus()
    if currentStatus == AdvancedDamageSystem.STATUS.READY or currentStatus == AdvancedDamageSystem.STATUS.BROKEN then
        if maintenanceType == nil then
            return ""
        end     
    end

    local finishTime, daysToAdd = AdvancedDamageSystem.calculateMaintenanceFinishTime(self, maintenanceType, nil, workshopType)
    local finishTimeHours, finishTimeMinutes = AdvancedDamageSystem.convertHoursToHoursAndMinutes(finishTime)
    local daysText = ""

    if daysToAdd == 1 then
        daysText = g_i18n:getText('ads_spec_tomorrow_at')
    elseif daysToAdd == 2 then
        daysText =  g_i18n:getText('ads_spec_day_after_tommorow_at')
    elseif daysToAdd > 2 then
        daysText = g_i18n:getText('ads_spec_in_days_at')
        daysText = string.gsub(daysText, "{days}", daysToAdd)
    end

    return string.format("%s%02d:%02d", daysText, finishTimeHours, finishTimeMinutes)
end

function AdvancedDamageSystem:getFormattedMaintenanceDurationText(maintenanceType, workshopType)
    local currentStatus = self:getCurrentStatus()
    if currentStatus == AdvancedDamageSystem.STATUS.READY or currentStatus == AdvancedDamageSystem.STATUS.BROKEN then
        if maintenanceType == nil then
            return ""
        end     
    end
    local duration = AdvancedDamageSystem.calculateMaintenanceDuration(self, maintenanceType, nil, workshopType)
    local durationHours, durationMinutes = AdvancedDamageSystem.convertHoursToHoursAndMinutes(duration)
    local days = math.floor(durationHours / 24)
    local daysText = ""
    if days > 0 then
        durationHours = durationHours - days * 24
        daysText = string.format("%s %s ", days, g_i18n:getText('ads_spec_day_s'))
    end

    local durationText = ""
    if durationHours == 0 and durationMinutes > 0 then
        durationText = string.format(g_i18n:getText('ads_spec_duration_format_minutes'), durationMinutes, g_i18n:getText('ads_spec_minute_s'))
    elseif durationHours > 0 and durationMinutes == 0 then
        durationText = string.format(g_i18n:getText('ads_spec_duration_format_hours'), durationHours, g_i18n:getText('ads_spec_hour_s'))
    elseif durationHours > 0 and durationMinutes > 0 then
        local hoursText = string.format(g_i18n:getText('ads_spec_duration_format_hours'), durationHours, g_i18n:getText('ads_spec_hour_s'))
        local minutesText = string.format(g_i18n:getText('ads_spec_duration_format_minutes'), durationMinutes, g_i18n:getText('ads_spec_minute_s'))
        durationText = string.format(g_i18n:getText('ads_spec_duration_format_combined'), hoursText, minutesText)
    end

    return string.format("%s%s", daysText, durationText)
end

function AdvancedDamageSystem:getFormattedLastInspectionText()
    local spec = self.spec_AdvancedDamageSystem
    local lastInpectionDate = spec.lastInspectionDate

    local monthsSinceInspection = 0

    local inspectionText = ""

    if g_currentMission ~= nil and next(lastInpectionDate) ~= nil then
        local currentMonth = g_currentMission.environment.currentPeriod
        local currentYear = g_currentMission.environment.currentYear
        monthsSinceInspection = monthsSinceInspection + (currentYear - lastInpectionDate.year) * 12
        monthsSinceInspection = monthsSinceInspection + (currentMonth - lastInpectionDate.month)
        if monthsSinceInspection == 0 then
            inspectionText = string.format('%s', g_i18n:getText('ads_spec_this_month'))
        else
            inspectionText = string.format('%s %s', monthsSinceInspection, g_i18n:getText('ads_spec_months_ago'))
        end
    else
        inspectionText = g_i18n:getText('ads_spec_never')
    end
    return inspectionText
end

function AdvancedDamageSystem:getFormattedLastMaintenanceText()
    local spec = self.spec_AdvancedDamageSystem
    local lastServiceDate = spec.lastServiceDate
    local ohDelta = self:getFormattedOperatingTime() - spec.lastServiceOperatingHours

    local monthsSinceMaintenance = 0
    local maintenanceText = ""

    local ohText = string.format("%.1f %s", ohDelta, g_i18n:getText('ads_spec_op_hours_short'))

    if next(lastServiceDate) == nil then
        maintenanceText = g_i18n:getText('ads_spec_never')
    end

    if g_currentMission ~= nil and next(lastServiceDate) ~= nil then
        local currentMonth = g_currentMission.environment.currentPeriod
        local currentYear = g_currentMission.environment.currentYear 
        monthsSinceMaintenance = monthsSinceMaintenance + (currentYear - lastServiceDate.year) * 12
        monthsSinceMaintenance = monthsSinceMaintenance + (currentMonth - lastServiceDate.month)

        if monthsSinceMaintenance == 0 then
            dateText = g_i18n:getText('ads_spec_this_month')
        else
            dateText = string.format(g_i18n:getText('ads_spec_months_ago_format'), monthsSinceMaintenance, g_i18n:getText('ads_spec_months_ago_unit'))
        end
        maintenanceText = string.format(g_i18n:getText('ads_spec_last_maintenance_format'), dateText, ohText)
    end
    return maintenanceText
end

function AdvancedDamageSystem:getFormattedServiceIntervalText()
    local spec = self.spec_AdvancedDamageSystem
    local interval = ((spec.baseServiceLevel / ADS_Config.CORE.BASE_SERVICE_WEAR) / 2) * spec.reliability
    local roundedInterval = math.floor(interval * 2 + 0.5) / 2
    if roundedInterval % 1 == 0 then
        return string.format(g_i18n:getText('ads_spec_service_interval_format'), string.format("%.0f", roundedInterval))
    end
    return string.format(g_i18n:getText('ads_spec_service_interval_format'), string.format("%.1f", roundedInterval))
end


function AdvancedDamageSystem.getTextColour(value)
    if value == AdvancedDamageSystem.STATES.UNKNOWN then
        return 0.5, 0.5, 0.5, 1.0
    elseif value == AdvancedDamageSystem.STATES.TERRIBLE then
        return 0.88, 0.12, 0.0, 1.0
    elseif value == AdvancedDamageSystem.STATES.BAD then
        return 0.7, 0.3, 0.0, 1.0
    elseif value == AdvancedDamageSystem.STATES.NORMAL then
        return 0.5, 0.5, 0.0, 1.0
    elseif value == AdvancedDamageSystem.STATES.GOOD then 
        return 0.3, 0.7, 0.0, 1.0
    elseif value == AdvancedDamageSystem.STATES.EXCELLENT then
        return 0.12, 0.88, 0.0, 1.0
    elseif value == AdvancedDamageSystem.STATES.REQUIRED then
        return 0.88, 0.12, 0.0, 1.0
    elseif value == AdvancedDamageSystem.STATES.RECOMMENDED then
        return 0.5, 0.5, 0.0, 1.0
    elseif value == AdvancedDamageSystem.STATES.NOT_REQUIRED then 
        return 0.3, 0.7, 0.0, 1.0
    end
    return 1.0, 1.0, 1.0, 1.0
end

-- ==========================================================
--                          HELPERS
-- ==========================================================

function AdvancedDamageSystem.getBrandReliability(vehicle, storeItem)
    local year = 2000
    local brandName = 'LIZARD'

    if vehicle ~= nil then
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
    local brandData = ADS_Config.BRANDS[brandName]

    if brandData ~= nil then
        return brandData[1], brandData[2] + yearFactor
    else
        return 1.0, 1.0
    end
end


function AdvancedDamageSystem.reliabilityValueToText(value)
    if value < 1.0 then return g_i18n:getText('ads_spec_state_budget')
    elseif value < 1.1 then return g_i18n:getText('ads_spec_state_standart')
    elseif value < 1.2 then return g_i18n:getText('ads_spec_state_premium')
    else return g_i18n:getText('ads_spec_state_legendary') end        
end


function AdvancedDamageSystem.maintainabilityValueToText(value)
    if value < 1.0 then return g_i18n:getText('ads_spec_state_low')
    elseif value < 1.1 then return g_i18n:getText('ads_spec_state_average')
    elseif value < 1.2 then return g_i18n:getText('ads_spec_state_high')
    else return g_i18n:getText('ads_spec_state_workhorse') end        
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


function AdvancedDamageSystem.calculateMaintenancePrice(vehicle, maintenanceType, selectedBreakdown)
    local price = vehicle:getPrice()
    local spec = vehicle.spec_AdvancedDamageSystem
    local ageFactor = math.min(math.max(math.log10(vehicle.age), 1), 2)
    local C = ADS_Config.MAINTENANCE

    if maintenanceType == AdvancedDamageSystem.STATUS.MAINTENANCE then
        return math.ceil(math.max((C.MAINTENANCE_PRICE_MULTIPLIER * price * ageFactor * 0.01 / 100) / spec.maintainability, 2)) * 100
    
    elseif maintenanceType == AdvancedDamageSystem.STATUS.INSPECTION then
        return math.ceil(math.clamp((C.MAINTENANCE_PRICE_MULTIPLIER * price * 0.0005) / spec.maintainability, 10, 100) / 10) * 10
    
    elseif maintenanceType == AdvancedDamageSystem.STATUS.OVERHAUL then
        local breakdownOverhaulPrice = 0
        local breakdownsForOverhaul = vehicle:getActiveBreakdowns()
                
        if breakdownsForOverhaul ~= nil and next(breakdownsForOverhaul) ~= nil then
            for id, breakdown in pairs(breakdownsForOverhaul) do
                local repairPriceM = ADS_Breakdowns.BreakdownRegistry[id].stages[breakdown.stage].repairPrice
                breakdownOverhaulPrice = breakdownOverhaulPrice + repairPriceM * C.MAINTENANCE_PRICE_MULTIPLIER * (price / 100) * ageFactor
            end
        end

        return math.ceil((price * 0.2 * C.MAINTENANCE_PRICE_MULTIPLIER / 100) / spec.maintainability) * 100 + breakdownOverhaulPrice / spec.maintainability
    
    elseif maintenanceType == AdvancedDamageSystem.STATUS.REPAIR then
        local repairPrice = 0
        
        if selectedBreakdown ~= nil then
            local registryEntry = ADS_Breakdowns.BreakdownRegistry[selectedBreakdown]
            if registryEntry ~= nil then
                local repairPriceM = registryEntry.stages[spec.activeBreakdowns[selectedBreakdown].stage].repairPrice
                repairPrice = (repairPriceM * C.MAINTENANCE_PRICE_MULTIPLIER * (price / 100) * ageFactor)
            end
        else
            local breakdowns = vehicle:getActiveBreakdowns()
            
            if breakdowns ~= nil and next(breakdowns) ~= nil  then
                for id, breakdown in pairs(breakdowns) do
                    if breakdown.isSelectedForRepair and breakdown.isVisible then
                        local repairPriceM = ADS_Breakdowns.BreakdownRegistry[id].stages[breakdown.stage].repairPrice
                        repairPrice = (repairPrice + repairPriceM * C.MAINTENANCE_PRICE_MULTIPLIER * (price / 100) * ageFactor)
                    end
                end
            end
        end
        return repairPrice * (1 / spec.maintainability)
    end

    return 0
end


function AdvancedDamageSystem.calculateMaintenanceDuration(vehicle, maintenanceType, selectedBreakdowns, workshopType)
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        return 0
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    local C = ADS_Config.MAINTENANCE
    local workDurationHours = 0
    if workshopType == nil then
        workshopType = spec.workshopType
    end

    if spec.currentState ~= AdvancedDamageSystem.STATUS.READY and spec.currentState ~= AdvancedDamageSystem.STATUS.BROKEN then
        workDurationHours = spec.maintenanceTimer / 3600000
    else
        local totalDurationMs = 0
        if maintenanceType == AdvancedDamageSystem.STATUS.INSPECTION then
            totalDurationMs = C.INSPECTION_TIME / spec.maintainability
        elseif maintenanceType == AdvancedDamageSystem.STATUS.MAINTENANCE then
            totalDurationMs = C.MAINTENANCE_TIME / spec.maintainability
        elseif maintenanceType == AdvancedDamageSystem.STATUS.OVERHAUL then
            totalDurationMs = C.OVERHAUL_TIME / spec.maintainability
        elseif maintenanceType == AdvancedDamageSystem.STATUS.REPAIR then
            local repairCount = 0
            local breakdowns = selectedBreakdowns or vehicle:getActiveBreakdowns()

            if breakdowns ~= nil and next(breakdowns) ~= nil then
                for _, breakdown in pairs(breakdowns) do
                    if breakdown.isSelectedForRepair then
                        repairCount = repairCount + 1
                    end
                end
            end
            totalDurationMs = (C.REPAIR_TIME * repairCount) / spec.maintainability
        end
        workDurationHours = totalDurationMs / 3600000
    end

    if workDurationHours <= 0 then
        return 0
    end

    local totalElapsedHours

    if workshopType == AdvancedDamageSystem.WORKSHOP.MOBILE then
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

    return (totalElapsedHours * C.MAINTENANCE_DURATION_MULTIPLIER)
end


function AdvancedDamageSystem.calculateMaintenanceFinishTime(vehicle, maintenanceType, selectedBreakdowns, workshopType)
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        return 0, 0
    end

    local totalCalendarDuration = AdvancedDamageSystem.calculateMaintenanceDuration(vehicle, maintenanceType, selectedBreakdowns, workshopType)

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


function AdvancedDamageSystem.convertHoursToHoursAndMinutes(totalHours)
    if totalHours == nil then
        return 0, 0
    end
    local hours, fraction = math.modf(totalHours)
    local minutes = math.floor((fraction * 60) + 0.5)
    
    return hours, minutes
end


function AdvancedDamageSystem.setLastInspectionStates(vehicle, s, c)
    local spec = vehicle.spec_AdvancedDamageSystem
    local bs = spec.baseServiceLevel
    local bc = spec.baseConditionLevel

    if bs - s > bs * (2/3) then spec.lastInspectedServiceState = AdvancedDamageSystem.STATES.REQUIRED
    elseif bs - s > bs * (1/3) then spec.lastInspectedServiceState = AdvancedDamageSystem.STATES.RECOMMENDED
    else spec.lastInspectedServiceState = AdvancedDamageSystem.STATES.NOT_REQUIRED end

    if bc - c > bc * (4/5) then spec.lastInspectedConditionState = AdvancedDamageSystem.STATES.TERRIBLE
    elseif bc - c > bc * (3/5) then spec.lastInspectedConditionState = AdvancedDamageSystem.STATES.BAD
    elseif bc - c > bc * (2/5) then spec.lastInspectedConditionState = AdvancedDamageSystem.STATES.NORMAL
    elseif bc - c > bc * (1/5) then spec.lastInspectedConditionState = AdvancedDamageSystem.STATES.GOOD
    else spec.lastInspectedConditionState = AdvancedDamageSystem.STATES.EXCELLENT end
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

        for id, breakdown in pairs(spec.activeBreakdowns) do
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

    if not args or not args[1] then
        print("ADS Error: Missing argument. Usage: ads_startMaintance <type>")
        print("Available types: inspection, maintenance, repair, overhaul")
        return
    end

    local maintenanceType = string.lower(args[1])
    local isValidType = false
    for _, state in pairs(AdvancedDamageSystem.STATUS) do
        if string.lower(state) == maintenanceType then
            isValidType = true
            maintenanceType = state
            break
        end
    end
    
    if not isValidType or maintenanceType == "Ready" then
        print("ADS Error: Invalid maintenance type '"..maintenanceType.."'")
        print("Available types: inspection, maintenance, repair, overhaul")
        return
    end

    local breakdownCount = tonumber(args[2]) or 1

    vehicle:initMaintenance(maintenanceType, AdvancedDamageSystem.WORKSHOP.OWN, breakdownCount, false)
    print(string.format("ADS: Attempted to start '%s' for '%s'.", maintenanceType, vehicle:getFullName()))
end


function AdvancedDamageSystem.ConsoleCommands:finishMaintance()
    local vehicle = self:getTargetVehicle()
    if not vehicle then return end

    local spec = vehicle.spec_AdvancedDamageSystem
    if spec.currentState == AdvancedDamageSystem.STATUS.READY then
        print(string.format("ADS: Vehicle '%s' is not under maintenance.", vehicle:getFullName()))
        return
    end
    
    spec.maintenanceTimer = 1
    print(string.format("ADS: Forcing maintenance completion for '%s'. It will finish on the next update tick.", vehicle:getFullName()))
end

function AdvancedDamageSystem.ConsoleCommands:getDebugVehicleInfo(rawArgs)
    local args = parseArguments(rawArgs)
    local vehicle = self:getTargetVehicle()
    if not vehicle then return end
    
    local spec = vehicle.spec_AdvancedDamageSystem

    print("--- Vehicle Debug Info ---")
    print(string.format("Name: %s", vehicle:getFullName()))
    print(string.format("Type: %s", vehicle.type.name))
    local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
    print(string.format("Category: %s", storeItem.categoryName))
    print(string.format("Property state: %s", vehicle.propertyState))
    local motor = vehicle:getMotor()
    print(string.format("Transmission: %s, %s, %s", motor.minForwardGearRatio, motor.gearType, motor.groupType))

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
addConsoleCommand("ads_startMaintance", "Starts maintenance. Usage: ads_startMaintance <type>", "startMaintance", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_finishMaintance", "Instantly finishes current maintenance.", "finishMaintance", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_getDebugVehicleInfo", "Vehicle debug info", "getDebugVehicleInfo", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_setDirtAmount", "Sets vehicle dirt amount. Usage: ads_setDirtAmount [0.0-1.0]", "setDirtAmount", AdvancedDamageSystem.ConsoleCommands)
addConsoleCommand("ads_debug", "Enbales/disabled ADS debug", "debug", AdvancedDamageSystem.ConsoleCommands)