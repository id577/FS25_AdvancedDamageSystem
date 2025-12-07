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

    -- Service Wear
    self.ads_serviceWear = ADS_InGameSettings:addMultiTextOption(
        self,
        "onServiceWearChanged",
        ADS_InGameSettings.steps.serviceWear.texts,
        g_i18n:getText("ads_serviceWear_label"),
        g_i18n:getText("ads_serviceWear_tooltip")
    )

    -- Condition Wear
    self.ads_conditionWear = ADS_InGameSettings:addMultiTextOption(
        self,
        "onConditionWearChanged",
        ADS_InGameSettings.steps.conditionWear.texts,
        g_i18n:getText("ads_conditionWear_label"),
        g_i18n:getText("ads_conditionWear_tooltip")
    )

    -- Breakdown Probability
    self.ads_breakdownProbability = ADS_InGameSettings:addMultiTextOption(
        self,
        "onBreakdownProbabilityChanged",
        ADS_InGameSettings.steps.breakdown.texts,
        g_i18n:getText("ads_breakdownProbability_label"),
        g_i18n:getText("ads_breakdownProbability_tooltip")
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

    -- Engine Max Heat
    self.ads_engineMaxHeat = ADS_InGameSettings:addMultiTextOption(
        self,
        "onEngineMaxHeatChanged",
        ADS_InGameSettings.steps.engineHeat.texts,
        g_i18n:getText("ads_engineMaxHeat_label"),
        g_i18n:getText("ads_engineMaxHeat_tooltip")
    )

    -- Transmission Max Heat
    self.ads_transMaxHeat = ADS_InGameSettings:addMultiTextOption(
        self,
        "onTransMaxHeatChanged",
        ADS_InGameSettings.steps.transHeat.texts,
        g_i18n:getText("ads_transMaxHeat_label"),
        g_i18n:getText("ads_transMaxHeat_tooltip")
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

    setIndex(currentPage.ads_serviceWear, steps.serviceWear.values, ADS_Config.CORE.BASE_SERVICE_WEAR)
    setIndex(currentPage.ads_conditionWear, steps.conditionWear.values, ADS_Config.CORE.BASE_CONDITION_WEAR)
    setIndex(currentPage.ads_breakdownProbability, steps.breakdown.values, ADS_Config.CORE.BREAKDOWN_PROBABILITY.MAX_MTBF)
    setIndex(currentPage.ads_maintenancePrice, steps.maintPrice.values, ADS_Config.MAINTENANCE.MAINTENANCE_PRICE_MULTIPLIER)
    setIndex(currentPage.ads_maintenanceDuration, steps.maintDuration.values, ADS_Config.MAINTENANCE.MAINTENANCE_DURATION_MULTIPLIER)
    
    currentPage.ads_instantInspection:setIsChecked(ADS_Config.MAINTENANCE.INSTANT_INSPECTION, false, false)
    currentPage.ads_parkVehicle:setIsChecked(ADS_Config.MAINTENANCE.PARK_VEHICLE, false, false)
    currentPage.ads_aiOverloadAndOverheatControl:setIsChecked(ADS_Config.CORE.AI_OVERLOAD_AND_OVERHEAT_CONTROL, false, false)
    currentPage.ads_workshopAvailable:setIsChecked(ADS_Config.WORKSHOP.ALWAYS_AVAILABLE, false, false)
    
    setIndex(currentPage.ads_workshopOpenHour, steps.hours.values, ADS_Config.WORKSHOP.OPEN_HOUR)
    setIndex(currentPage.ads_workshopCloseHour, steps.hours.values, ADS_Config.WORKSHOP.CLOSE_HOUR)
    
    setIndex(currentPage.ads_engineMaxHeat, steps.engineHeat.values, ADS_Config.THERMAL.ENGINE_MAX_HEAT)
    setIndex(currentPage.ads_transMaxHeat, steps.transHeat.values, ADS_Config.THERMAL.TRANS_MAX_HEAT)
    setIndex(currentPage.ads_dirtInfluence, steps.dirt.values, ADS_Config.THERMAL.MAX_DIRT_INFLUENCE)

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
    ADS_Config.CORE.BASE_CONDITION_WEAR = ADS_InGameSettings.steps.conditionWear.values[state]
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onBreakdownProbabilityChanged(state)
    ADS_Config.CORE.BREAKDOWN_PROBABILITY.MAX_MTBF = ADS_InGameSettings.steps.breakdown.values[state]
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

function ADS_InGameSettings:onMaintenancePriceChanged(state)
    ADS_Config.MAINTENANCE.MAINTENANCE_PRICE_MULTIPLIER = ADS_InGameSettings.steps.maintPrice.values[state]
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onMaintenanceDurationChanged(state)
    ADS_Config.MAINTENANCE.MAINTENANCE_DURATION_MULTIPLIER = ADS_InGameSettings.steps.maintDuration.values[state]
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

function ADS_InGameSettings:onEngineMaxHeatChanged(state)
    ADS_Config.THERMAL.ENGINE_MAX_HEAT = ADS_InGameSettings.steps.engineHeat.values[state]
    ADS_InGameSettings:updateADSSettings(g_gui.currentGui.target.currentPage)
end

function ADS_InGameSettings:onTransMaxHeatChanged(state)
    ADS_Config.THERMAL.TRANS_MAX_HEAT = ADS_InGameSettings.steps.transHeat.values[state]
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

    local function createSteps(startVal, count, stepSize, formatter, isFloat)
        local data = { values = {}, texts = {} }
        for i = 0, count - 1 do
            local val = startVal + (i * stepSize)
            table.insert(data.values, val)
            if formatter then
                table.insert(data.texts, formatter(val))
            else
                table.insert(data.texts, tostring(val))
            end
        end
        return data
    end

    -- Service Wear: 1% to 30% (steps of 0.01)
    self.steps.serviceWear = createSteps(0.01, 30, 0.01, formatPercent, true)
    
    -- Condition Wear: 0.1% to 3.0% (steps of 0.001) -> original code 1..30 * 0.001
    self.steps.conditionWear = createSteps(0.001, 30, 0.001, formatPercentPrecise, true)

    -- Breakdown: 200 to 2200 (steps of 100) -> original 0..20 * 100 + 200
    self.steps.breakdown = createSteps(200, 21, 100, nil, false)

    -- Maint Price: 0.1x to 3.0x
    self.steps.maintPrice = createSteps(0.1, 30, 0.1, formatMultiplier, true)

    -- Maint Duration: 0.1x to 3.0x
    self.steps.maintDuration = createSteps(0.1, 30, 0.1, formatMultiplier, true)

    -- Hours: 00:00 to 23:00
    self.steps.hours = createSteps(0, 24, 1, formatHour, false)

    -- Engine Heat: 0.90 to 1.10
    self.steps.engineHeat = createSteps(0.90, 21, 0.01, formatFloat2, true)

    -- Trans Heat: 0.90 to 1.10
    self.steps.transHeat = createSteps(0.90, 21, 0.01, formatFloat2, true)

    -- Dirt Influence: 0% to 30%
    self.steps.dirt = createSteps(0.00, 31, 0.01, formatPercent, true)

    self.steps.generated = true
end


-- --- Initialization Hook --- --

function ADS_InGameSettings.init()
    InGameMenuSettingsFrame.updateGameSettings = Utils.appendedFunction(InGameMenuSettingsFrame.updateGameSettings, ADS_InGameSettings.updateGameSettings)
    InGameMenuSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuSettingsFrame.onFrameOpen, ADS_InGameSettings.onFrameOpen)
end

ADS_InGameSettings.init()