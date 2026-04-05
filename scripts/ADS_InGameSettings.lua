ADS_InGameSettings = {}
ADS_InGameSettings.name = g_currentModName
ADS_InGameSettings.modDirectory = g_currentModDirectory

ADS_InGameSettings.steps = {}

local function formatPercent(val) return string.format("%.0f%%", val * 100) end
local function formatPercentPrecise(val) return string.format("%.1f%%", val * 100) end
local function formatMultiplier(val) return string.format("%.1fx", val) end
local function formatHour(val) return string.format("%02d:00", val) end
local function formatFloat2(val) return string.format("%.2f", val) end
local function formatAh(val)
    local text = string.format("%.2f", val)
    text = text:gsub("(%..-)0+$", "%1")
    text = text:gsub("%.$", "")
    return text .. " Ah"
end

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

    -- Passive Wear During Downtime
    self.ads_downtimeWear = ADS_InGameSettings:addMultiTextOption(
        self, "onDowntimeWearChanged",
        ADS_InGameSettings.steps.downtimeWear.texts,
        g_i18n:getText("ads_downtimeWear_label"),
        g_i18n:getText("ads_downtimeWear_tooltip")
    )

    -- General Wear (Binary)
    self.ads_generalWearEnabled = ADS_InGameSettings:addBinaryOption(
        self,
        "onGeneralWearEnabledChanged",
        g_i18n:getText("ads_generalWearEnabled_label"),
        g_i18n:getText("ads_generalWearEnabled_tooltip")
    )

    -- System Stress Rate
    self.ads_systemStressRate = ADS_InGameSettings:addMultiTextOption(
        self, "onSystemStressRateChanged",
        ADS_InGameSettings.steps.systemStressRate.texts,
        g_i18n:getText("ads_systemStressRate_label"),
        g_i18n:getText("ads_systemStressRate_tooltip")
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

    -- Mobile Workshop Restrictions (Binary)
    self.ads_mobileWorkshopRestrictions = ADS_InGameSettings:addBinaryOption(
        self,
        "onMobileWorkshopRestrictionsChanged",
        g_i18n:getText("ads_mobileWorkshopRestrictions_label"),
        g_i18n:getText("ads_mobileWorkshopRestrictions_tooltip")
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

    -- Battery Capacity
    self.ads_batteryCapacity = ADS_InGameSettings:addMultiTextOption(
        self, "onBatteryCapacityChanged",
        ADS_InGameSettings.steps.batteryCapacity.texts,
        g_i18n:getText("ads_batteryCapacity_label"),
        g_i18n:getText("ads_batteryCapacity_tooltip")
    )

    -- Clogging Speed
    self.ads_cloggingSpeed = ADS_InGameSettings:addMultiTextOption(
        self,
        "onCloggingSpeedChanged",
        ADS_InGameSettings.steps.cloggingSpeed.texts,
        g_i18n:getText("ads_cloggingSpeed_label"),
        g_i18n:getText("ads_cloggingSpeed_tooltip")
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
        local bestIndex = 1
        local bestDiff = math.huge

        for i, v in ipairs(valueList) do
            local diff = math.abs((tonumber(v) or 0) - (tonumber(targetValue) or 0))
            if diff < bestDiff then
                bestDiff = diff
                bestIndex = i
            end
        end

        element:setState(bestIndex)
    end

    setIndex(currentPage.ads_systemStressRate, steps.systemStressRate.values, ADS_Config.CORE.SYSTEM_STRESS_GLOBAL_MULTIPLIER)
    setIndex(currentPage.ads_batteryCapacity,  steps.batteryCapacity.values,  ADS_Config.ELECTRICAL.BATTERY_USABLE_CAPACITY_FACTOR)
    setIndex(currentPage.ads_serviceWear,      steps.serviceWear.values,      ADS_Config.CORE.BASE_SERVICE_WEAR)
    setIndex(currentPage.ads_conditionWear,    steps.conditionWear.values,    ADS_Config.CORE.BASE_SYSTEMS_WEAR)
    setIndex(currentPage.ads_downtimeWear,     steps.downtimeWear.values,     ADS_Config.CORE.DOWNTIME_MULTIPLIER)
    setIndex(currentPage.ads_maintenancePrice,    steps.maintPrice.values,    ADS_Config.MAINTENANCE.GLOBAL_SERVICE_PRICE_MULTIPLIER * 100)
    setIndex(currentPage.ads_maintenanceDuration, steps.maintDuration.values, ADS_Config.MAINTENANCE.GLOBAL_SERVICE_TIME_MULTIPLIER * 100)
    setIndex(currentPage.ads_thermalSensitivity, steps.thermalSensitivity.values, ADS_Config.THERMAL.ENGINE_MAX_HEAT)
    setIndex(currentPage.ads_cloggingSpeed,    steps.cloggingSpeed.values,  ADS_Config.FIELD_CARE.CLOGGING_SPEED)
    
    currentPage.ads_instantInspection:setIsChecked(ADS_Config.MAINTENANCE.INSTANT_INSPECTION, false, false)
    currentPage.ads_parkVehicle:setIsChecked(ADS_Config.MAINTENANCE.PARK_VEHICLE, false, false)
    currentPage.ads_warrantyEnabled:setIsChecked(ADS_Config.MAINTENANCE.WARRANTY_ENABLED, false, false)
    currentPage.ads_generalWearEnabled:setIsChecked(ADS_Config.CORE.GENERAL_WEAR_ENABLED, false, false)
    currentPage.ads_aiOverloadAndOverheatControl:setIsChecked(ADS_Config.CORE.AI_OVERLOAD_AND_OVERHEAT_CONTROL, false, false)
    currentPage.ads_workshopAvailable:setIsChecked(ADS_Config.WORKSHOP.ALWAYS_AVAILABLE, false, false)
    currentPage.ads_mobileWorkshopRestrictions:setIsChecked(ADS_Config.WORKSHOP.MOBILE_WORKSHOP_RESTRICTIONS_ENABLED, false, false)
    currentPage.ads_debugMode:setIsChecked(ADS_Config.DEBUG, false, false)
    
    setIndex(currentPage.ads_workshopOpenHour, steps.hours.values, ADS_Config.WORKSHOP.OPEN_HOUR)
    setIndex(currentPage.ads_workshopCloseHour, steps.hours.values, ADS_Config.WORKSHOP.CLOSE_HOUR)

    local isAlwaysAvailable = ADS_Config.WORKSHOP.ALWAYS_AVAILABLE
    currentPage.ads_workshopOpenHour:setDisabled(isAlwaysAvailable)
    currentPage.ads_workshopCloseHour:setDisabled(isAlwaysAvailable)

    -- MP permission: only server host or dedicated-server admin can change settings.
    local canChangeSettings = g_currentMission ~= nil
        and (g_currentMission:getIsServer() or g_currentMission.isMasterUser)
        and g_currentMission:getIsClient()
    local disableAll = not canChangeSettings

    currentPage.ads_serviceWear:setDisabled(disableAll)
    currentPage.ads_conditionWear:setDisabled(disableAll)
    currentPage.ads_downtimeWear:setDisabled(disableAll)
    currentPage.ads_generalWearEnabled:setDisabled(disableAll)

    currentPage.ads_systemStressRate:setDisabled(disableAll)
    currentPage.ads_batteryCapacity:setDisabled(disableAll)
    currentPage.ads_instantInspection:setDisabled(disableAll)
    currentPage.ads_parkVehicle:setDisabled(disableAll)
    currentPage.ads_warrantyEnabled:setDisabled(disableAll)
    currentPage.ads_maintenancePrice:setDisabled(disableAll)
    currentPage.ads_maintenanceDuration:setDisabled(disableAll)
    currentPage.ads_workshopAvailable:setDisabled(disableAll)
    currentPage.ads_mobileWorkshopRestrictions:setDisabled(disableAll)
    currentPage.ads_thermalSensitivity:setDisabled(disableAll)
    currentPage.ads_cloggingSpeed:setDisabled(disableAll)
    currentPage.ads_aiOverloadAndOverheatControl:setDisabled(disableAll)
    currentPage.ads_debugMode:setDisabled(disableAll)

    -- Workshop hour controls: disabled if non-server OR always-available is on.
    if disableAll or isAlwaysAvailable then
        currentPage.ads_workshopOpenHour:setDisabled(true)
        currentPage.ads_workshopCloseHour:setDisabled(true)
    end
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

function ADS_InGameSettings:onDowntimeWearChanged(state)
    ADS_Config.CORE.DOWNTIME_MULTIPLIER = ADS_InGameSettings.steps.downtimeWear.values[state]
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onGeneralWearEnabledChanged(state)
    ADS_Config.CORE.GENERAL_WEAR_ENABLED = (state == BinaryOptionElement.STATE_RIGHT)
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
    ADS_Main:forceWorkshopUpdate()
end

function ADS_InGameSettings:onMobileWorkshopRestrictionsChanged(state)
    ADS_Config.WORKSHOP.MOBILE_WORKSHOP_RESTRICTIONS_ENABLED = (state == BinaryOptionElement.STATE_RIGHT)
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
    ADS_Main:forceWorkshopUpdate()
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
    ADS_Main:forceWorkshopUpdate()
end


function ADS_InGameSettings:onSystemStressRateChanged(state)
    ADS_Config.CORE.SYSTEM_STRESS_GLOBAL_MULTIPLIER = ADS_InGameSettings.steps.systemStressRate.values[state]
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onBatteryCapacityChanged(state)
    ADS_Config.ELECTRICAL.BATTERY_USABLE_CAPACITY_FACTOR = ADS_InGameSettings.steps.batteryCapacity.values[state]
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onThermalSensitivityChanged(state)
    local val = ADS_InGameSettings.steps.thermalSensitivity.values[state]
    ADS_Config.THERMAL.ENGINE_MAX_HEAT = val
    ADS_Config.THERMAL.TRANS_MAX_HEAT  = val
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onCloggingSpeedChanged(state)
    ADS_Config.FIELD_CARE.CLOGGING_SPEED = ADS_InGameSettings.steps.cloggingSpeed.values[state]
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
    do
        local data = { values = {}, texts = {} }

        local function addHourRange(startHour, endHour, stepHour)
            local hours = startHour
            while hours <= endHour + 0.0001 do
                table.insert(data.values, 0.5 / hours)
                table.insert(data.texts, string.format("%.1f h", hours))
                hours = hours + stepHour
            end
        end

        addHourRange(1.0, 20.0, 1.0)
        addHourRange(22.0, 50.0, 2.0)
        addHourRange(55.0, 100.0, 5.0)

        self.steps.serviceWear = data
    end

    -- Vehicle Lifespan:
    -- 0.001 = 1000h, 0.030 = ~33h
    do
        local data = { values = {}, texts = {} }

        local function addHourRange(startHour, endHour, stepHour)
            local hours = startHour
            while hours <= endHour + 0.0001 do
                table.insert(data.values, 1.0 / hours)
                table.insert(data.texts, string.format("%d h", hours))
                hours = hours + stepHour
            end
        end

        addHourRange(40, 200, 10)
        addHourRange(220, 500, 20)
        addHourRange(550, 1000, 50)

        self.steps.conditionWear = data
    end

    -- Downtime Wear: Off, then 1% to 10%
    do
        local data = { values = {0.0}, texts = {g_i18n:getText("ads_option_off")} }
        for percent = 1, 10 do
            local value = percent / 100
            table.insert(data.values, value)
            table.insert(data.texts, string.format("%d%%", percent))
        end
        self.steps.downtimeWear = data
    end

    -- System Stress Rate: 10% to 300%
    self.steps.systemStressRate = createSteps(0.1, 30, 0.1, function(v)
        return string.format("%.0f%%", v * 100)
    end)

    -- Battery Capacity in Ah (stored as usable capacity factor)
    do
        local nominalCapacity = tonumber(ADS_Config.ELECTRICAL.BATTERY_NOMINAL_CAPACITY) or 150
        local data = { values = {}, texts = {} }
        local factors = {0.025, 0.05, 0.075, 0.1}

        for factor = 0.2, 1.0, 0.1 do
            table.insert(factors, factor)
        end

        for _, factor in ipairs(factors) do
            table.insert(data.values, factor)
            table.insert(data.texts, formatAh(nominalCapacity * factor))
        end

        self.steps.batteryCapacity = data
    end

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

    -- Clogging Speed: 10% to 300%
    self.steps.cloggingSpeed = createSteps(0.1, 30, 0.1, function(v)
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
