ADS_InGameSettings = {};
ADS_InGameSettings.name = g_currentModName;
ADS_InGameSettings.modDirectory = g_currentModDirectory
ADS_InGameSettings.initialized = false

local function findStateIndexByValue(textsArray, targetText)
    for i, v in ipairs(textsArray) do
        if v == targetText then
            return i
        end
    end
    return 1
end

local function getTextByValue(value)
    if value < 0.1 then
        return string.format("%.1f%%", value * 100)
    else
        return string.format("%.0f%%", value * 100)
    end
end

local function getValueByText(text)
    local number_string = string.match(text, "[%d.]+")
    if number_string then
        return tonumber(number_string) / 100
    end
    return nil
end

local function getTextForMultiplier(value)
    return string.format("%.1fx", value)
end

local function getValueFromMultiplierText(text)
    local number_string = string.match(text, "[%d.]+")
    if number_string then
        return tonumber(number_string)
    end
    return nil
end

local function getTextForHour(hour)
    return string.format("%02d:00", hour)
end

local function getValueFromHourText(text)
    local number_string = string.match(text, "%d+")
    if number_string then
        return tonumber(number_string)
    end
    return 0
end

function ADS_InGameSettings.init()
    InGameMenuSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuSettingsFrame.onFrameOpen, ADS_InGameSettings.initSettingsGui)
end

function ADS_InGameSettings:initSettingsGui()
    if not ADS_InGameSettings.initialized then
        -- settings section
        local sectionTitle = self.gameSettingsLayout.elements[7]:clone()
        sectionTitle:applyProfile("fs25_settingsSectionHeader", true)
        sectionTitle:setText("Advanced Damage System")
        sectionTitle.focusChangeData = {}
        sectionTitle.focusId = FocusManager.serveAutoFocusId()
        self.gameSettingsLayout:addElement(sectionTitle)

        self.ads_serviceWear = self.economicDifficulty:clone()
        self.ads_serviceWear.onClickCallback = ADS_InGameSettings.onValueChanged
        self.ads_serviceWear.buttonLRChange = ADS_InGameSettings.onValueChanged
        self.ads_serviceWear.texts = {}
        for i = 1, 30 do
            local value = 0.01 * i
            table.insert(self.ads_serviceWear.texts, getTextByValue(value))
        end
        local currentServiceWearText = getTextByValue(ADS_Config.CORE.BASE_SERVICE_WEAR)
        self.ads_serviceWear:setState(findStateIndexByValue(self.ads_serviceWear.texts, currentServiceWearText))

        self.ads_conditionWear = self.economicDifficulty:clone()
        self.ads_conditionWear.onClickCallback = ADS_InGameSettings.onValueChanged
        self.ads_conditionWear.buttonLRChange = ADS_InGameSettings.onValueChanged
        self.ads_conditionWear.texts = {}
        for i = 1, 30 do
            local value = 0.001 * i
            table.insert(self.ads_conditionWear.texts, getTextByValue(value))
        end
        local currentConditionWearText = getTextByValue(ADS_Config.CORE.BASE_CONDITION_WEAR)
        self.ads_conditionWear:setState(findStateIndexByValue(self.ads_conditionWear.texts, currentConditionWearText))

        self.ads_breakdownProbability = self.economicDifficulty:clone()
        self.ads_breakdownProbability.onClickCallback = ADS_InGameSettings.onValueChanged
        self.ads_breakdownProbability.buttonLRChange = ADS_InGameSettings.onValueChanged
        self.ads_breakdownProbability.texts = {}
        for i = 0, 10 do
            local value = 200 + i * 100
            table.insert(self.ads_breakdownProbability.texts, tostring(value))
        end
        local currentBreakdownProbText = tostring(ADS_Config.CORE.BREAKDOWN_PROBABILITY.MAX_MTBF)
        self.ads_breakdownProbability:setState(findStateIndexByValue(self.ads_breakdownProbability.texts, currentBreakdownProbText))

        self.ads_maintenancePrice = self.economicDifficulty:clone()
        self.ads_maintenancePrice.onClickCallback = ADS_InGameSettings.onValueChanged
        self.ads_maintenancePrice.buttonLRChange = ADS_InGameSettings.onValueChanged
        self.ads_maintenancePrice.texts = {}
        for i = 1, 30 do
            local value = 0.1 * i
            table.insert(self.ads_maintenancePrice.texts, getTextForMultiplier(value))
        end
        local currentMaintPriceText = getTextForMultiplier(ADS_Config.MAINTENANCE.MAINTENANCE_PRICE_MULTIPLIER)
        self.ads_maintenancePrice:setState(findStateIndexByValue(self.ads_maintenancePrice.texts, currentMaintPriceText))

        self.ads_maintenanceDuration = self.economicDifficulty:clone()
        self.ads_maintenanceDuration.onClickCallback = ADS_InGameSettings.onValueChanged
        self.ads_maintenanceDuration.buttonLRChange = ADS_InGameSettings.onValueChanged
        self.ads_maintenanceDuration.texts = {}
        for i = 1, 30 do
            local value = 0.1 * i
            table.insert(self.ads_maintenanceDuration.texts, getTextForMultiplier(value))
        end
        local currentMaintDurationText = getTextForMultiplier(ADS_Config.MAINTENANCE.MAINTENANCE_DURATION_MULTIPLIER)
        self.ads_maintenanceDuration:setState(findStateIndexByValue(self.ads_maintenanceDuration.texts, currentMaintDurationText))

        self.ads_workshopOpenHour = self.economicDifficulty:clone()
        self.ads_workshopOpenHour.onClickCallback = ADS_InGameSettings.onValueChanged
        self.ads_workshopOpenHour.buttonLRChange = ADS_InGameSettings.onValueChanged
        self.ads_workshopOpenHour.texts = {}
        for i = 0, 23 do
            table.insert(self.ads_workshopOpenHour.texts, getTextForHour(i))
        end
        local currentOpenHourText = getTextForHour(ADS_Config.WORKSHOP.OPEN_HOUR)
        self.ads_workshopOpenHour:setState(findStateIndexByValue(self.ads_workshopOpenHour.texts, currentOpenHourText))

        self.ads_workshopCloseHour = self.economicDifficulty:clone()
        self.ads_workshopCloseHour.onClickCallback = ADS_InGameSettings.onValueChanged
        self.ads_workshopCloseHour.buttonLRChange = ADS_InGameSettings.onValueChanged
        self.ads_workshopCloseHour.texts = {}
        for i = 0, 23 do
            table.insert(self.ads_workshopCloseHour.texts, getTextForHour(i))
        end
        local currentCloseHourText = getTextForHour(ADS_Config.WORKSHOP.CLOSE_HOUR)
        self.ads_workshopCloseHour:setState(findStateIndexByValue(self.ads_workshopCloseHour.texts, currentCloseHourText))

        self.ads_engineMaxHeat = self.economicDifficulty:clone()
        self.ads_engineMaxHeat.onClickCallback = ADS_InGameSettings.onValueChanged
        self.ads_engineMaxHeat.buttonLRChange = ADS_InGameSettings.onValueChanged
        self.ads_engineMaxHeat.texts = {}
        for i = 0, 20 do
            local value = 0.9 + (i * 0.01)
            table.insert(self.ads_engineMaxHeat.texts, string.format("%.2f", value))
        end
        local currentEngineMaxHeatText = string.format("%.2f", ADS_Config.THERMAL.ENGINE_MAX_HEAT)
        self.ads_engineMaxHeat:setState(findStateIndexByValue(self.ads_engineMaxHeat.texts, currentEngineMaxHeatText))

        self.ads_transMaxHeat = self.economicDifficulty:clone()
        self.ads_transMaxHeat.onClickCallback = ADS_InGameSettings.onValueChanged
        self.ads_transMaxHeat.buttonLRChange = ADS_InGameSettings.onValueChanged
        self.ads_transMaxHeat.texts = {}
        for i = 0, 20 do
            local value = 0.9 + (i * 0.01)
            table.insert(self.ads_transMaxHeat.texts, string.format("%.2f", value))
        end
        local currentTransMaxHeatText = string.format("%.2f", ADS_Config.THERMAL.TRANS_MAX_HEAT)
        self.ads_transMaxHeat:setState(findStateIndexByValue(self.ads_transMaxHeat.texts, currentTransMaxHeatText))

        self.ads_dirtInfluence = self.economicDifficulty:clone()
        self.ads_dirtInfluence.onClickCallback = ADS_InGameSettings.onValueChanged
        self.ads_dirtInfluence.buttonLRChange = ADS_InGameSettings.onValueChanged
        self.ads_dirtInfluence.texts = {}
        for i = 0, 30 do
            local value = i * 0.01
            table.insert(self.ads_dirtInfluence.texts, getTextByValue(value))
        end
        local currentDirtInfluenceText = getTextByValue(ADS_Config.THERMAL.MAX_DIRT_INFLUENCE)
        self.ads_dirtInfluence:setState(findStateIndexByValue(self.ads_dirtInfluence.texts, currentDirtInfluenceText))

        ADS_InGameSettings:addOptionToLayout(self.gameSettingsLayout, self.ads_serviceWear, "ads_serviceWear", self.gameSettingsLayout.elements[5])
        ADS_InGameSettings:addOptionToLayout(self.gameSettingsLayout, self.ads_conditionWear, "ads_conditionWear", self.gameSettingsLayout.elements[5])
        ADS_InGameSettings:addOptionToLayout(self.gameSettingsLayout, self.ads_breakdownProbability, "ads_breakdownProbability", self.gameSettingsLayout.elements[5])
        ADS_InGameSettings:addOptionToLayout(self.gameSettingsLayout, self.ads_maintenancePrice, "ads_maintenancePrice", self.gameSettingsLayout.elements[5])
        ADS_InGameSettings:addOptionToLayout(self.gameSettingsLayout, self.ads_maintenanceDuration, "ads_maintenanceDuration", self.gameSettingsLayout.elements[5])
        ADS_InGameSettings:addOptionToLayout(self.gameSettingsLayout, self.ads_workshopOpenHour, "ads_workshopOpenHour", self.gameSettingsLayout.elements[5])
        ADS_InGameSettings:addOptionToLayout(self.gameSettingsLayout, self.ads_workshopCloseHour, "ads_workshopCloseHour", self.gameSettingsLayout.elements[5])
        ADS_InGameSettings:addOptionToLayout(self.gameSettingsLayout, self.ads_engineMaxHeat, "ads_engineMaxHeat", self.gameSettingsLayout.elements[5])
        ADS_InGameSettings:addOptionToLayout(self.gameSettingsLayout, self.ads_transMaxHeat, "ads_transMaxHeat", self.gameSettingsLayout.elements[5])
        ADS_InGameSettings:addOptionToLayout(self.gameSettingsLayout, self.ads_dirtInfluence, "ads_dirtInfluence", self.gameSettingsLayout.elements[5])

        self.gameSettingsLayout:invalidateLayout()
        ADS_InGameSettings.initialized = true
    else
        self.ads_serviceWear:setState(findStateIndexByValue(self.ads_serviceWear.texts, getTextByValue(ADS_Config.CORE.BASE_SERVICE_WEAR)))
        self.ads_conditionWear:setState(findStateIndexByValue(self.ads_conditionWear.texts, getTextByValue(ADS_Config.CORE.BASE_CONDITION_WEAR)))
        self.ads_breakdownProbability:setState(findStateIndexByValue(self.ads_breakdownProbability.texts, tostring(ADS_Config.CORE.BREAKDOWN_PROBABILITY.MAX_MTBF)))
        self.ads_maintenancePrice:setState(findStateIndexByValue(self.ads_maintenancePrice.texts, getTextForMultiplier(ADS_Config.MAINTENANCE.MAINTENANCE_PRICE_MULTIPLIER)))
        self.ads_maintenanceDuration:setState(findStateIndexByValue(self.ads_maintenanceDuration.texts, getTextForMultiplier(ADS_Config.MAINTENANCE.MAINTENANCE_DURATION_MULTIPLIER)))
        self.ads_workshopOpenHour:setState(findStateIndexByValue(self.ads_workshopOpenHour.texts, getTextForHour(ADS_Config.WORKSHOP.OPEN_HOUR)))
        self.ads_workshopCloseHour:setState(findStateIndexByValue(self.ads_workshopCloseHour.texts, getTextForHour(ADS_Config.WORKSHOP.CLOSE_HOUR)))
        self.ads_engineMaxHeat:setState(findStateIndexByValue(self.ads_engineMaxHeat.texts, string.format("%.2f", ADS_Config.THERMAL.ENGINE_MAX_HEAT)))
        self.ads_transMaxHeat:setState(findStateIndexByValue(self.ads_transMaxHeat.texts, string.format("%.2f", ADS_Config.THERMAL.TRANS_MAX_HEAT)))
        self.ads_dirtInfluence:setState(findStateIndexByValue(self.ads_dirtInfluence.texts, getTextByValue(ADS_Config.THERMAL.MAX_DIRT_INFLUENCE)))
    end
end

function ADS_InGameSettings:addOptionToLayout(gameSettingsLayout, element, id, settingsClone)
    element.id = id
    local toolTip = element.elements[1]

    toolTip.text = g_i18n:getText(id .. "_tooltip")
    toolTip.sourceText = g_i18n:getText(id .. "_tooltip")

    local optionTitle = settingsClone.elements[2]:clone()
    optionTitle.id = id .. "Title"
    optionTitle:applyProfile("fs25_settingsMultiTextOptionTitle", true)
    optionTitle:setText(g_i18n:getText(id .. "_label"))

    local optionContainer = settingsClone:clone()
    optionContainer.id = id .. "Container"

    optionContainer:applyProfile("fs25_multiTextOptionContainer", true)
    for key, v in pairs(optionContainer.elements) do
        optionContainer.elements[key] = nil
    end

    optionContainer:addElement(optionTitle)
    optionContainer:addElement(element)

    gameSettingsLayout:addElement(optionContainer)
end


function ADS_InGameSettings:onValueChanged(newStateIndex, uiElement, loadFromSavegame)
    local newValueText = uiElement and uiElement.texts and uiElement.texts[newStateIndex]
    if not newValueText then return end
    
    local uiId = uiElement.id
    
    if uiId == "ads_workshopOpenHour" or uiId == "ads_workshopCloseHour" then
        ADS_InGameSettings.onWorkshopHourChanged(self, uiElement)

    elseif uiId == "ads_serviceWear" then
        local newValue = getValueByText(newValueText)
        if newValue ~= nil and newValue ~= ADS_Config.CORE.BASE_SERVICE_WEAR then
            ADS_Config.CORE.BASE_SERVICE_WEAR = newValue
        end
    elseif uiId == "ads_conditionWear" then
        local newValue = getValueByText(newValueText)
        if newValue ~= nil and newValue ~= ADS_Config.CORE.BASE_CONDITION_WEAR then
            ADS_Config.CORE.BASE_CONDITION_WEAR = newValue
        end
    elseif uiId == "ads_breakdownProbability" then
        local newValue = tonumber(newValueText)
        if newValue ~= nil and newValue ~= ADS_Config.CORE.BREAKDOWN_PROBABILITY.MAX_MTBF then
            ADS_Config.CORE.BREAKDOWN_PROBABILITY.MAX_MTBF = newValue
        end
    elseif uiId == "ads_maintenancePrice" then
        local newValue = getValueFromMultiplierText(newValueText)
        if newValue ~= nil and newValue ~= ADS_Config.MAINTENANCE.MAINTENANCE_PRICE_MULTIPLIER then
            ADS_Config.MAINTENANCE.MAINTENANCE_PRICE_MULTIPLIER = newValue
        end
    elseif uiId == "ads_maintenanceDuration" then
        local newValue = getValueFromMultiplierText(newValueText)
        if newValue ~= nil and newValue ~= ADS_Config.MAINTENANCE.MAINTENANCE_DURATION_MULTIPLIER then
            ADS_Config.MAINTENANCE.MAINTENANCE_DURATION_MULTIPLIER = newValue
        end
    elseif uiId == "ads_engineMaxHeat" then
        local newValue = tonumber(newValueText)
        if newValue ~= nil and newValue ~= ADS_Config.THERMAL.ENGINE_MAX_HEAT then
            ADS_Config.THERMAL.ENGINE_MAX_HEAT = newValue
        end
    elseif uiId == "ads_transMaxHeat" then
        local newValue = tonumber(newValueText)
        if newValue ~= nil and newValue ~= ADS_Config.THERMAL.TRANS_MAX_HEAT then
            ADS_Config.THERMAL.TRANS_MAX_HEAT = newValue
        end
    elseif uiId == "ads_dirtInfluence" then
        local newValue = getValueByText(newValueText)
        if newValue ~= nil and newValue ~= ADS_Config.THERMAL.MAX_DIRT_INFLUENCE then
            ADS_Config.THERMAL.MAX_DIRT_INFLUENCE = newValue
        end
    end
end


function ADS_InGameSettings.onWorkshopHourChanged(self, changedElement)
    local openHourText = self.ads_workshopOpenHour.texts[self.ads_workshopOpenHour:getState()]
    local closeHourText = self.ads_workshopCloseHour.texts[self.ads_workshopCloseHour:getState()]
    
    local newOpenHour = getValueFromHourText(openHourText)
    local newCloseHour = getValueFromHourText(closeHourText)

    if newOpenHour >= newCloseHour then
        if changedElement.id == "ads_workshopOpenHour" then
            newCloseHour = newOpenHour + 1
            if newCloseHour > 23 then
                newCloseHour = 23
                newOpenHour = 22
            end
        elseif changedElement.id == "ads_workshopCloseHour" then
            newOpenHour = newCloseHour - 1
            if newOpenHour < 0 then 
                newOpenHour = 0
                newCloseHour = 1
            end
        end
    end

    ADS_Config.WORKSHOP.OPEN_HOUR = newOpenHour
    ADS_Config.WORKSHOP.CLOSE_HOUR = newCloseHour

    local finalOpenText = getTextForHour(newOpenHour)
    local finalCloseText = getTextForHour(newCloseHour)
    self.ads_workshopOpenHour:setState(findStateIndexByValue(self.ads_workshopOpenHour.texts, finalOpenText))
    self.ads_workshopCloseHour:setState(findStateIndexByValue(self.ads_workshopCloseHour.texts, finalCloseText))
end


ADS_InGameSettings.init()