ADS_InGameSettings = {}
ADS_InGameSettings.name = g_currentModName
ADS_InGameSettings.modDirectory = g_currentModDirectory

ADS_InGameSettings.steps = {}

local function formatPercent(val) return string.format("%.0f%%", val * 100) end
local function formatPercentPrecise(val) return string.format("%.1f%%", val * 100) end
local function formatMultiplier(val) return string.format("%.1fx", val) end
local function formatHour(val) return string.format("%02d:00", val) end
local function formatFloat2(val) return string.format("%.2f", val) end

function ADS_InGameSettings:onFrameOpen()
    if self.ads_initSettingsMenuDone then
        return
    end

    ADS_InGameSettings:generateAllSteps()

    ADS_InGameSettings:addSectionHeader(self, "Advanced Damage System")

    -- Base Service Interval (ex.: Service Wear)
    self.ads_serviceWear = ADS_InGameSettings:addMultiTextOption(
        self, "onServiceWearChanged",
        ADS_InGameSettings.steps.serviceWear.texts,
        g_i18n:getText("ads_serviceInterval_label"),
        g_i18n:getText("ads_serviceInterval_tooltip")
    )

    -- Base Service Life (ex.: Condition Wear)
    self.ads_conditionWear = ADS_InGameSettings:addMultiTextOption(
        self, "onConditionWearChanged",
        ADS_InGameSettings.steps.conditionWear.texts,
        g_i18n:getText("ads_vehicleLifespan_label"),
        g_i18n:getText("ads_vehicleLifespan_tooltip")
    )

    -- Breakdown Frequency (ex.: Breakdown Probability)
self.ads_breakdownProbability = ADS_InGameSettings:addMultiTextOption(
        self, "onBreakdownProbabilityChanged",
        ADS_InGameSettings.steps.breakdown.texts,
        g_i18n:getText("ads_breakdownFrequency_label"),
        g_i18n:getText("ads_breakdownFrequency_tooltip")
    )

    -- Instant Inspection (Binary)
    self.ads_instantInspection = ADS_InGameSettings:addBinaryOption(
        self,
        "onInstantInspectionChanged",
        g_i18n:getText("ads_instantInspection_label"),
        g_i18n:getText("ads_instantInspection_tooltip")
    )

    -- Park Vehicle (Binary)
    self.ads_parkVehicle = ADS_InGameSettings:addBinaryOption(
        self,
        "onParkVehicleChanged",
        g_i18n:getText("ads_parkVehicle_label"),
        g_i18n:getText("ads_parkVehicle_tooltip")
    )

    -- Warranty Coverage (Binary)
    self.ads_warrantyEnabled = ADS_InGameSettings:addBinaryOption(
        self,
        "onWarrantyEnabledChanged",
        g_i18n:getText("ads_warrantyEnabled_label"),
        g_i18n:getText("ads_warrantyEnabled_tooltip")
    )

    -- Maintenance Price
    self.ads_maintenancePrice = ADS_InGameSettings:addMultiTextOption(
        self,
        "onMaintenancePriceChanged",
        ADS_InGameSettings.steps.maintPrice.texts,
        g_i18n:getText("ads_maintenancePrice_label"),
        g_i18n:getText("ads_maintenancePrice_tooltip")
    )

    -- Maintenance Duration
    self.ads_maintenanceDuration = ADS_InGameSettings:addMultiTextOption(
        self,
        "onMaintenanceDurationChanged",
        ADS_InGameSettings.steps.maintDuration.texts,
        g_i18n:getText("ads_maintenanceDuration_label"),
        g_i18n:getText("ads_maintenanceDuration_tooltip")
    )

    -- Workshop Available (Binary)
    self.ads_workshopAvailable = ADS_InGameSettings:addBinaryOption(
        self,
        "onWorkshopAvailableChanged",
        g_i18n:getText("ads_workshopAvailable_label"),
        g_i18n:getText("ads_workshopAvailable_tooltip")
    )

    -- Workshop Open Hour
    self.ads_workshopOpenHour = ADS_InGameSettings:addMultiTextOption(
        self,
        "onWorkshopOpenHourChanged",
        ADS_InGameSettings.steps.hours.texts,
        g_i18n:getText("ads_workshopOpenHour_label"),
        g_i18n:getText("ads_workshopOpenHour_tooltip")
    )

    -- Workshop Close Hour
    self.ads_workshopCloseHour = ADS_InGameSettings:addMultiTextOption(
        self,
        "onWorkshopCloseHourChanged",
        ADS_InGameSettings.steps.hours.texts,
        g_i18n:getText("ads_workshopCloseHour_label"),
        g_i18n:getText("ads_workshopCloseHour_tooltip")
    )

    -- Thermal Sensitivity (engine + trans heat)
    self.ads_thermalSensitivity = ADS_InGameSettings:addMultiTextOption(
        self, "onThermalSensitivityChanged",
        ADS_InGameSettings.steps.thermalSensitivity.texts,
        g_i18n:getText("ads_thermalSensitivity_label"),
        g_i18n:getText("ads_thermalSensitivity_tooltip")
    )

    -- Dirt Influence
    self.ads_dirtInfluence = ADS_InGameSettings:addMultiTextOption(
        self,
        "onDirtInfluenceChanged",
        ADS_InGameSettings.steps.dirt.texts,
        g_i18n:getText("ads_dirtInfluence_label"),
        g_i18n:getText("ads_dirtInfluence_tooltip")
    )

    -- AI overload and overheat control (Binary)
    self.ads_aiOverloadAndOverheatControl = ADS_InGameSettings:addBinaryOption(
        self,
        "onAiOverloadAndOverheatControlChanged",
        g_i18n:getText("ads_aiOverloadAndOverheatControl_label"),
        g_i18n:getText("ads_aiOverloadAndOverheatControl_tooltip")
    )

    -- DEbug Mode (Binary)
    self.ads_debugMode = ADS_InGameSettings:addBinaryOption(
        self,
        "onDebugModeChanged",
        g_i18n:getText("ads_debugMode_label"),
        g_i18n:getText("ads_debugMode_tooltip")
    )

    self.gameSettingsLayout:invalidateLayout()
    
    self:updateAlternatingElements(self.gameSettingsLayout)
    self:updateGeneralSettings(self.gameSettingsLayout)

    self.ads_initSettingsMenuDone = true
    ADS_InGameSettings:updateADSSettings(self)
end

function ADS_InGameSettings:updateGameSettings()
    ADS_InGameSettings:updateADSSettings(self)
end

function ADS_InGameSettings:updateADSSettings(currentPage)
    if not currentPage.ads_initSettingsMenuDone then return end

    local steps = ADS_InGameSettings.steps

    local function setIndex(element, valueList, targetValue)
        for i, v in ipairs(valueList) do
            if math.abs(v - targetValue) < 0.0001 then
                element:setState(i)
                return
            end
        end
        element:setState(1)
    end

     local currentBreakdownPct = math.floor((1200 / ADS_Config.CORE.BREAKDOWN_PROBABILITY.MAX_MTBF) * 100 + 0.5)
    setIndex(currentPage.ads_breakdownProbability, steps.breakdown.values, currentBreakdownPct)
    setIndex(currentPage.ads_serviceWear,       steps.serviceWear.values,    ADS_Config.CORE.BASE_SERVICE_WEAR)
    setIndex(currentPage.ads_conditionWear,     steps.conditionWear.values,  ADS_Config.CORE.BASE_SYSTEMS_WEAR)
    setIndex(currentPage.ads_maintenancePrice,    steps.maintPrice.values,    ADS_Config.MAINTENANCE.GLOBAL_SERVICE_PRICE_MULTIPLIER * 100)
    setIndex(currentPage.ads_maintenanceDuration, steps.maintDuration.values, ADS_Config.MAINTENANCE.GLOBAL_SERVICE_TIME_MULTIPLIER * 100)
    setIndex(currentPage.ads_thermalSensitivity, steps.thermalSensitivity.values, ADS_Config.THERMAL.ENGINE_MAX_HEAT)
    setIndex(currentPage.ads_dirtInfluence,     steps.dirt.values,           ADS_Config.THERMAL.MAX_DIRT_INFLUENCE)
    
    currentPage.ads_instantInspection:setIsChecked(ADS_Config.MAINTENANCE.INSTANT_INSPECTION, false, false)
    currentPage.ads_parkVehicle:setIsChecked(ADS_Config.MAINTENANCE.PARK_VEHICLE, false, false)
    currentPage.ads_warrantyEnabled:setIsChecked(ADS_Config.MAINTENANCE.WARRANTY_ENABLED, false, false)
    currentPage.ads_aiOverloadAndOverheatControl:setIsChecked(ADS_Config.CORE.AI_OVERLOAD_AND_OVERHEAT_CONTROL, false, false)
    currentPage.ads_workshopAvailable:setIsChecked(ADS_Config.WORKSHOP.ALWAYS_AVAILABLE, false, false)
    currentPage.ads_debugMode:setIsChecked(ADS_Config.DEBUG, false, false)
    
    setIndex(currentPage.ads_workshopOpenHour, steps.hours.values, ADS_Config.WORKSHOP.OPEN_HOUR)
    setIndex(currentPage.ads_workshopCloseHour, steps.hours.values, ADS_Config.WORKSHOP.CLOSE_HOUR)

    local isAlwaysAvailable = ADS_Config.WORKSHOP.ALWAYS_AVAILABLE
    currentPage.ads_workshopOpenHour:setDisabled(isAlwaysAvailable)
    currentPage.ads_workshopCloseHour:setDisabled(isAlwaysAvailable)
end

-- --- Callback Handlers --- --
function ADS_InGameSettings:onServiceWearChanged(state)
    ADS_Config.CORE.BASE_SERVICE_WEAR = ADS_InGameSettings.steps.serviceWear.values[state]
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onConditionWearChanged(state)
    ADS_Config.CORE.BASE_SYSTEMS_WEAR = ADS_InGameSettings.steps.conditionWear.values[state]
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onInstantInspectionChanged(state)
    ADS_Config.MAINTENANCE.INSTANT_INSPECTION = (state == BinaryOptionElement.STATE_RIGHT)
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onParkVehicleChanged(state)
    ADS_Config.MAINTENANCE.PARK_VEHICLE = (state == BinaryOptionElement.STATE_RIGHT)
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onWarrantyEnabledChanged(state)
    ADS_Config.MAINTENANCE.WARRANTY_ENABLED = (state == BinaryOptionElement.STATE_RIGHT)
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onMaintenancePriceChanged(state)
    ADS_Config.MAINTENANCE.GLOBAL_SERVICE_PRICE_MULTIPLIER = ADS_InGameSettings.steps.maintPrice.values[state] / 100
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onMaintenanceDurationChanged(state)
    ADS_Config.MAINTENANCE.GLOBAL_SERVICE_TIME_MULTIPLIER = ADS_InGameSettings.steps.maintDuration.values[state] / 100
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onWorkshopAvailableChanged(state)
    ADS_Config.WORKSHOP.ALWAYS_AVAILABLE = (state == BinaryOptionElement.STATE_RIGHT)
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onWorkshopOpenHourChanged(state)
    local newOpen = ADS_InGameSettings.steps.hours.values[state]
    local currentClose = ADS_Config.WORKSHOP.CLOSE_HOUR

    -- Logic for avoiding overlap
    if newOpen >= currentClose then
        currentClose = newOpen + 1
        if currentClose > 23 then
            currentClose = 23
            newOpen = 22
        end
        ADS_Config.WORKSHOP.CLOSE_HOUR = currentClose
    end

    ADS_Config.WORKSHOP.OPEN_HOUR = newOpen
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onWorkshopCloseHourChanged(state)
    local newClose = ADS_InGameSettings.steps.hours.values[state]
    local currentOpen = ADS_Config.WORKSHOP.OPEN_HOUR

    -- Logic for avoiding overlap
    if currentOpen >= newClose then
        currentOpen = newClose - 1
        if currentOpen < 0 then
            currentOpen = 0
            newClose = 1
        end
        ADS_Config.WORKSHOP.OPEN_HOUR = currentOpen
    end

    ADS_Config.WORKSHOP.CLOSE_HOUR = newClose
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onBreakdownProbabilityChanged(state)
    local pct = ADS_InGameSettings.steps.breakdown.values[state]
    ADS_Config.CORE.BREAKDOWN_PROBABILITY.MAX_MTBF = math.floor(1200 / (pct / 100) + 0.5)
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onThermalSensitivityChanged(state)
    local val = ADS_InGameSettings.steps.thermalSensitivity.values[state]
    ADS_Config.THERMAL.ENGINE_MAX_HEAT = val
    ADS_Config.THERMAL.TRANS_MAX_HEAT  = val
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onDirtInfluenceChanged(state)
    ADS_Config.THERMAL.MAX_DIRT_INFLUENCE = ADS_InGameSettings.steps.dirt.values[state]
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onAiOverloadAndOverheatControlChanged(state)
    ADS_Config.CORE.AI_OVERLOAD_AND_OVERHEAT_CONTROL = (state == BinaryOptionElement.STATE_RIGHT)
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onDebugModeChanged(state)
    ADS_Config.DEBUG = (state == BinaryOptionElement.STATE_RIGHT)
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage) 
end


-- --- UI Helper Methods --- --
function ADS_InGameSettings:addSectionHeader(inGameMenuSettingsFrame, titleText)
    local textElement = TextElement.new()
    local textElementProfile = g_gui:getProfile("fs25_settingsSectionHeader")
    textElement.name = "sectionHeader"
    textElement:loadProfile(textElementProfile, true)
    textElement:setText(titleText)
    inGameMenuSettingsFrame.gameSettingsLayout:addElement(textElement)
    textElement:onGuiSetupFinished()
end

function ADS_InGameSettings:addMultiTextOption(inGameMenuSettingsFrame, onClickCallback, texts, title, tooltip)
    local bitMap = BitmapElement.new()
    local bitMapProfile = g_gui:getProfile("fs25_multiTextOptionContainer")
    bitMap:loadProfile(bitMapProfile, true)

    local multiTextOption = MultiTextOptionElement.new()
    local multiTextOptionProfile = g_gui:getProfile("fs25_settingsMultiTextOption")
    multiTextOption:loadProfile(multiTextOptionProfile, true)
    multiTextOption.target = ADS_InGameSettings
    multiTextOption:setCallback("onClickCallback", onClickCallback)
    multiTextOption:setTexts(texts)

    local multiTextOptionTitle = TextElement.new()
    local multiTextOptionTitleProfile = g_gui:getProfile("fs25_settingsMultiTextOptionTitle")
    multiTextOptionTitle:loadProfile(multiTextOptionTitleProfile, true)
    multiTextOptionTitle:setText(title)

    local multiTextOptionTooltip = TextElement.new()
    local multiTextOptionTooltipProfile = g_gui:getProfile("fs25_multiTextOptionTooltip")
    multiTextOptionTooltip.name = "ignore"
    multiTextOptionTooltip:loadProfile(multiTextOptionTooltipProfile, true)
    multiTextOptionTooltip:setText(tooltip)

    multiTextOption:addElement(multiTextOptionTooltip)
    bitMap:addElement(multiTextOption)
    bitMap:addElement(multiTextOptionTitle)

    multiTextOption:onGuiSetupFinished()
    multiTextOptionTitle:onGuiSetupFinished()
    multiTextOptionTooltip:onGuiSetupFinished()

    inGameMenuSettingsFrame.gameSettingsLayout:addElement(bitMap)
    bitMap:onGuiSetupFinished()
    
    return multiTextOption
end

function ADS_InGameSettings:addBinaryOption(inGameMenuSettingsFrame, onClickCallback, title, tooltip)
    local bitMap = BitmapElement.new()
    local bitMapProfile = g_gui:getProfile("fs25_multiTextOptionContainer")
    bitMap:loadProfile(bitMapProfile, true)

    local binaryOption = BinaryOptionElement.new()
    binaryOption.useYesNoTexts = true
    local binaryOptionProfile = g_gui:getProfile("fs25_settingsBinaryOption")
    binaryOption:loadProfile(binaryOptionProfile, true)
    binaryOption.target = ADS_InGameSettings
    binaryOption:setCallback("onClickCallback", onClickCallback)

    local binaryOptionTitle = TextElement.new()
    local binaryOptionTitleProfile = g_gui:getProfile("fs25_settingsMultiTextOptionTitle")
    binaryOptionTitle:loadProfile(binaryOptionTitleProfile, true)
    binaryOptionTitle:setText(title)

    local binaryOptionTooltip = TextElement.new()
    local binaryOptionTooltipProfile = g_gui:getProfile("fs25_multiTextOptionTooltip")
    binaryOptionTooltip.name = "ignore"
    binaryOptionTooltip:loadProfile(binaryOptionTooltipProfile, true)
    binaryOptionTooltip:setText(tooltip)

    binaryOption:addElement(binaryOptionTooltip)
    bitMap:addElement(binaryOption)
    bitMap:addElement(binaryOptionTitle)

    binaryOption:onGuiSetupFinished()
    binaryOptionTitle:onGuiSetupFinished()
    binaryOptionTooltip:onGuiSetupFinished()

    inGameMenuSettingsFrame.gameSettingsLayout:addElement(bitMap)
    bitMap:onGuiSetupFinished()
    
    return binaryOption
end


-- --- Data Generation --- --
function ADS_InGameSettings:generateAllSteps()
    if self.steps.generated then return end

    local function createSteps(startVal, count, stepSize, formatter)
        local data = { values = {}, texts = {} }
        for i = 0, count - 1 do
            local val = startVal + (i * stepSize)
            table.insert(data.values, val)
            table.insert(data.texts, formatter and formatter(val) or tostring(val))
        end
        return data
    end

    -- Service Interval
    self.steps.serviceWear = createSteps(2.0, 37, 0.5, function(v)
        return string.format("%.1f h", v)
    end)
    do
        local data = { values = {}, texts = {} }
        for i = 0, 36 do
            local hours = 2.0 + i * 0.5
            table.insert(data.values, 0.5 / hours)
            table.insert(data.texts, string.format("%.1f h", hours))
        end
        self.steps.serviceWear = data
    end

    -- Vehicle Lifespan:
    -- 0.001 = 1000h, 0.030 = ~33h
    do
        local data = { values = {}, texts = {} }
        for i = 0, 36 do
            local hours = 40 + i * 10
            table.insert(data.values, 1.0 / hours)  -- конвертируем в wear
            table.insert(data.texts, string.format("%d h", hours))
        end
        self.steps.conditionWear = data
    end

    -- Breakdown Frequency:
    -- 100% = 1200 MTBF (дефолт), 200% = 600, 50% = 2400
    self.steps.breakdown = createSteps(20, 15, 20, function(v)
        return string.format("%.0f%%", v)
    end)

-- Maint Price: 10% to 300%
    self.steps.maintPrice = createSteps(10, 30, 10, function(v)
        return string.format("%.0f%%", v)
    end)

    -- Maint Duration: 10% to 300%
    self.steps.maintDuration = createSteps(10, 30, 10, function(v)
        return string.format("%.0f%%", v)
    end)

    -- Hours: 00:00 to 23:00
    self.steps.hours = createSteps(0, 24, 1, function(v)
        return string.format("%02d:00", v)
    end)

    -- Thermal Sensitivity:
    self.steps.thermalSensitivity = {
        values = {0.9, 1.0, 1.05, 1.1},
        texts  = {
            g_i18n:getText("ads_thermal_none"),
            g_i18n:getText("ads_thermal_mild"),
            g_i18n:getText("ads_thermal_default"),
            g_i18n:getText("ads_thermal_aggressive"),
        }
    }

    -- Dirt Influence: 0% to 30%
    self.steps.dirt = createSteps(0.00, 31, 0.01, function(v)
        return string.format("%.0f%%", v * 100)
    end)

    self.steps.generated = true
end


-- --- Initialization Hook --- --

function ADS_InGameSettings.init()
    InGameMenuSettingsFrame.updateGameSettings = Utils.appendedFunction(InGameMenuSettingsFrame.updateGameSettings, ADS_InGameSettings.updateGameSettings)
    InGameMenuSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuSettingsFrame.onFrameOpen, ADS_InGameSettings.onFrameOpen)
end

ADS_InGameSettings.init()
