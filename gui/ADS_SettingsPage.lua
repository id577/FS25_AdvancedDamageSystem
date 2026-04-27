ADS_SettingsPage = {}
ADS_InGameSettings = ADS_SettingsPage
ADS_InGameSettings.name = g_currentModName
ADS_InGameSettings.modDirectory = g_currentModDirectory

ADS_InGameSettings.steps = {}

local function formatAh(val)
    local text = string.format("%.2f", val)
    text = text:gsub("(%..-)0+$", "%1")
    text = text:gsub("%.$", "")
    return text .. " Ah"
end

local function valuesDiffer(a, b)
    if type(a) == "number" or type(b) == "number" then
        return math.abs((tonumber(a) or 0) - (tonumber(b) or 0)) > 0.0001
    end

    return a ~= b
end

local function buildPendingConfigFromAdsConfig()
    return {
        tutorialMode = ADS_Config.TUTORIAL_MODE,

        baseServiceWear = ADS_Config.CORE.BASE_SERVICE_WEAR,
        baseSystemsWear = ADS_Config.CORE.BASE_SYSTEMS_WEAR,
        downtimeMultiplier = ADS_Config.CORE.DOWNTIME_MULTIPLIER,
        generalWearEnabled = ADS_Config.CORE.GENERAL_WEAR_ENABLED,
        enableWarningMessages = ADS_Config.CORE.ENABLE_WARNING_MESSAGES,
        systemStressGlobalMultiplier = ADS_Config.CORE.SYSTEM_STRESS_GLOBAL_MULTIPLIER,
        aiOverloadControl = ADS_Config.CORE.AI_OVERLOAD_AND_OVERHEAT_CONTROL,

        instantInspection = ADS_Config.MAINTENANCE.INSTANT_INSPECTION,
        parkVehicle = ADS_Config.MAINTENANCE.PARK_VEHICLE,
        warrantyEnabled = ADS_Config.MAINTENANCE.WARRANTY_ENABLED,
        globalPriceMultiplier = ADS_Config.MAINTENANCE.GLOBAL_SERVICE_PRICE_MULTIPLIER,
        globalTimeMultiplier = ADS_Config.MAINTENANCE.GLOBAL_SERVICE_TIME_MULTIPLIER,

        dealerAlwaysAvailable = ADS_Config.WORKSHOP.DEALER_ALWAYS_AVAILABLE,
        mobileAlwaysAvailable = ADS_Config.WORKSHOP.MOBILE_ALWAYS_AVAILABLE,
        ownAlwaysAvailable = ADS_Config.WORKSHOP.OWN_ALWAYS_AVAILABLE,
        mobileWorkshopRestrictionsEnabled = ADS_Config.WORKSHOP.MOBILE_WORKSHOP_RESTRICTIONS_ENABLED,
        openHour = ADS_Config.WORKSHOP.OPEN_HOUR,
        closeHour = ADS_Config.WORKSHOP.CLOSE_HOUR,

        engineMaxHeat = ADS_Config.THERMAL.ENGINE_MAX_HEAT,
        transMaxHeat = ADS_Config.THERMAL.TRANS_MAX_HEAT,
        maxDirtInfluence = ADS_Config.THERMAL.MAX_DIRT_INFLUENCE,
        warmingBoostPower = ADS_Config.THERMAL.WARMING_BOOST_POWER,
        coolingSlowdownPower = ADS_Config.THERMAL.COOLING_SLOWDOWN_POWER,

        batteryUsableCapacityFactor = ADS_Config.ELECTRICAL.BATTERY_USABLE_CAPACITY_FACTOR,
        alternatorMaxOutput = ADS_Config.ELECTRICAL.ALT_MAX_OUTPUT,
        idleCurrentA = ADS_Config.ELECTRICAL.IDLE_CURRENT_A,

        cloggingSpeed = ADS_Config.FIELD_CARE.CLOGGING_SPEED,
        fieldInspectionDuration = ADS_Config.FIELD_CARE.VISUAL_INSPECTION_DURATION,
        lubricationReducePerDay = ADS_Config.FIELD_CARE.LUBRICATION_REDUCE_PER_DAY,

        debugMode = ADS_Config.DEBUG
    }
end

local function getPendingConfig()
    if ADS_InGameSettings.pendingConfig == nil then
        ADS_InGameSettings.pendingConfig = buildPendingConfigFromAdsConfig()
    end

    return ADS_InGameSettings.pendingConfig
end

local function getSettingsProfile(defaultProfileName)
    return g_gui:getProfile(defaultProfileName)
end

local function applyButtonBackgroundProfile(button)
    if button == nil or button.elements == nil then
        return
    end

    for _, child in pairs(button.elements) do
        if child ~= nil and child.applyProfile ~= nil and child.profile == "fs25_settingsButtonBg" then
            child:applyProfile("ads_settingsButtonBg")
            return
        end
    end
end

local function applyMultiTextOptionBackgroundProfile(option)
    if option == nil or option.elements == nil then
        return
    end

    for _, child in pairs(option.elements) do
        if child ~= nil and child.applyProfile ~= nil and child.profile == "fs25_multiTextOptionBg" then
            child:applyProfile("ads_settingsMultiTextOptionBg")
            return
        end
    end
end

local function addDisabledLockToSettingsRow(rowElement, optionElement, tooltip)
    if rowElement == nil or optionElement == nil then
        return nil
    end

    local lockButton = ButtonElement.new()
    lockButton.name = "iconDisabled"
    lockButton:loadProfile(getSettingsProfile("fs25_settingsMultiTextOptionLocked"), true)
    lockButton.target = ADS_InGameSettings
    lockButton:setCallback("onClickCallback", "onClickSettingsLockedIcon")
    lockButton:setCallback("onFocusCallback", "onFocusSettingsLockedIcon")

    local lockTooltip = TextElement.new()
    lockTooltip:loadProfile(getSettingsProfile("fs25_multiTextOptionTooltip"), true)
    lockTooltip:setText(tooltip)
    lockTooltip:setPosition(unpack(GuiUtils.getNormalizedScreenValues("940px 0px", lockTooltip.position)))
    lockButton:addElement(lockTooltip)

    rowElement:addElement(lockButton)
    lockButton:onGuiSetupFinished()
    lockTooltip:onGuiSetupFinished()
    lockButton:setDisabled(true)

    local oldSetDisabled = optionElement.setDisabled
    optionElement.setDisabled = function(element, disabled, ...)
        oldSetDisabled(element, disabled, ...)
        lockButton:setDisabled(not disabled)
    end

    optionElement.ads_disabledLockIcon = lockButton

    return lockButton
end

local function applySettingsRowColor(page, rowElement)
    if page == nil or not page.ads_useFleetMenuStyle or rowElement == nil or rowElement.setImageColor == nil then
        return
    end

    if InGameMenuSettingsFrame ~= nil and InGameMenuSettingsFrame.COLOR_ALTERNATING ~= nil then
        rowElement:setImageColor(nil, table.unpack(InGameMenuSettingsFrame.COLOR_ALTERNATING[page.ads_settingsRowIsEven]))
    end

    page.ads_settingsRowIsEven = not page.ads_settingsRowIsEven
end

local function getVanillaSettingsButtonTemplate()
    local settingsPage = g_inGameMenu ~= nil and g_inGameMenu.pageSettings or nil
    local scrollPanel = settingsPage ~= nil and settingsPage.gameSettingsLayout or nil

    if scrollPanel == nil or scrollPanel.elements == nil then
        return nil
    end

    for _, element in pairs(scrollPanel.elements) do
        if element.typeName == "Bitmap"
            and element.elements ~= nil
            and element.elements[1] ~= nil
            and element.elements[1].typeName == "Button" then
            return element
        end
    end

    return nil
end

function ADS_InGameSettings:onClickSettingsLockedIcon()
end

function ADS_InGameSettings:onFocusSettingsLockedIcon(icon)
    local page = ADS_InGameSettings.embeddedPage
    if page ~= nil and page.settingsLayout ~= nil and page.settingsLayout.scrollToMakeElementVisible ~= nil then
        page.settingsLayout:scrollToMakeElementVisible(icon)
    end
end

local function getCurrentSettingsPage()
    local embeddedPage = ADS_InGameSettings.embeddedPage
    if embeddedPage ~= nil
        and embeddedPage.getCurrentSubCategory ~= nil
        and ADS_InGameMenuFrame ~= nil
        and ADS_InGameMenuFrame.SUB_CATEGORY ~= nil
        and embeddedPage:getCurrentSubCategory() == ADS_InGameMenuFrame.SUB_CATEGORY.SETTINGS then
        return embeddedPage
    end

    return nil
end

local function isCurrentMissionMultiplayer()
    return g_currentMission ~= nil
        and g_currentMission.missionDynamicInfo ~= nil
        and g_currentMission.missionDynamicInfo.isMultiplayer == true
end

local function canChangeADSSettings()
    return g_currentMission ~= nil
        and g_currentMission.getIsClient ~= nil
        and g_currentMission:getIsClient()
        and (not isCurrentMissionMultiplayer() or g_currentMission:getIsServer() or g_currentMission.isMasterUser)
end

local function refreshCurrentSettingsPage()
    local currentPage = getCurrentSettingsPage()
    if currentPage ~= nil then
        ADS_InGameSettings:updateADSSettings(currentPage)
    end
end

function ADS_InGameSettings.applyPendingConfigSideEffects(oldConfig, newConfig)
    if g_currentMission == nil or not g_currentMission:getIsServer() then
        return
    end

    if oldConfig == nil or newConfig == nil or ADS_Main == nil or ADS_Main.vehicles == nil then
        return
    end

    local parkVehicleChanged = valuesDiffer(oldConfig.parkVehicle, newConfig.parkVehicle)
    local instantInspectionEnabled = (oldConfig.instantInspection ~= true and newConfig.instantInspection == true)

    if not parkVehicleChanged and not instantInspectionEnabled then
        return
    end

    local states = AdvancedDamageSystem.STATUS

    for _, vehicle in pairs(ADS_Main.vehicles) do
        if vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil and not vehicle.spec_AdvancedDamageSystem.isExcludedVehicle then
            local spec = vehicle.spec_AdvancedDamageSystem
            local currentState = spec.currentState

            if parkVehicleChanged
                and currentState ~= states.READY
                and currentState ~= states.BROKEN
                and vehicle.spec_enterable ~= nil
                and vehicle.spec_enterable.setIsTabbable ~= nil then
                vehicle.spec_enterable:setIsTabbable(not newConfig.parkVehicle)
            end

            if instantInspectionEnabled and currentState == states.INSPECTION then
                if AdvancedDamageSystem.forceFinishService(vehicle) then
                    AdvancedDamageSystem.raiseServiceLifecycleDirtyFlags(vehicle)
                end
            end
        end
    end
end

function ADS_InGameSettings.commitPendingConfig(current, pending)
    if pending == nil or current == nil then
        return
    end

    ADS_InGameSettings.applyPendingConfigSideEffects(current, pending)

    local batteryFactorChanged = valuesDiffer(pending.batteryUsableCapacityFactor, current.batteryUsableCapacityFactor)
    local workshopChanged =
        valuesDiffer(pending.dealerAlwaysAvailable, current.dealerAlwaysAvailable) or
        valuesDiffer(pending.mobileAlwaysAvailable, current.mobileAlwaysAvailable) or
        valuesDiffer(pending.ownAlwaysAvailable, current.ownAlwaysAvailable) or
        valuesDiffer(pending.mobileWorkshopRestrictionsEnabled, current.mobileWorkshopRestrictionsEnabled) or
        valuesDiffer(pending.openHour, current.openHour) or
        valuesDiffer(pending.closeHour, current.closeHour)

    if isCurrentMissionMultiplayer() then
        pending.tutorialMode = false
    end

    ADS_Config.TUTORIAL_MODE = pending.tutorialMode

    ADS_Config.CORE.BASE_SERVICE_WEAR = pending.baseServiceWear
    ADS_Config.CORE.BASE_SYSTEMS_WEAR = pending.baseSystemsWear
    ADS_Config.CORE.DOWNTIME_MULTIPLIER = pending.downtimeMultiplier
    ADS_Config.CORE.GENERAL_WEAR_ENABLED = pending.generalWearEnabled
    ADS_Config.CORE.ENABLE_WARNING_MESSAGES = pending.enableWarningMessages
    ADS_Config.CORE.SYSTEM_STRESS_GLOBAL_MULTIPLIER = pending.systemStressGlobalMultiplier
    ADS_Config.CORE.AI_OVERLOAD_AND_OVERHEAT_CONTROL = pending.aiOverloadControl

    ADS_Config.MAINTENANCE.INSTANT_INSPECTION = pending.instantInspection
    ADS_Config.MAINTENANCE.PARK_VEHICLE = pending.parkVehicle
    ADS_Config.MAINTENANCE.WARRANTY_ENABLED = pending.warrantyEnabled
    ADS_Config.MAINTENANCE.GLOBAL_SERVICE_PRICE_MULTIPLIER = pending.globalPriceMultiplier
    ADS_Config.MAINTENANCE.GLOBAL_SERVICE_TIME_MULTIPLIER = pending.globalTimeMultiplier

    ADS_Config.WORKSHOP.DEALER_ALWAYS_AVAILABLE = pending.dealerAlwaysAvailable
    ADS_Config.WORKSHOP.MOBILE_ALWAYS_AVAILABLE = pending.mobileAlwaysAvailable
    ADS_Config.WORKSHOP.OWN_ALWAYS_AVAILABLE = pending.ownAlwaysAvailable
    ADS_Config.WORKSHOP.MOBILE_WORKSHOP_RESTRICTIONS_ENABLED = pending.mobileWorkshopRestrictionsEnabled
    ADS_Config.WORKSHOP.OPEN_HOUR = pending.openHour
    ADS_Config.WORKSHOP.CLOSE_HOUR = pending.closeHour

    ADS_Config.THERMAL.ENGINE_MAX_HEAT = pending.engineMaxHeat
    ADS_Config.THERMAL.TRANS_MAX_HEAT = pending.transMaxHeat
    ADS_Config.THERMAL.MAX_DIRT_INFLUENCE = pending.maxDirtInfluence
    ADS_Config.THERMAL.WARMING_BOOST_POWER = pending.warmingBoostPower
    ADS_Config.THERMAL.COOLING_SLOWDOWN_POWER = pending.coolingSlowdownPower

    ADS_Config.ELECTRICAL.BATTERY_USABLE_CAPACITY_FACTOR = pending.batteryUsableCapacityFactor
    ADS_Config.ELECTRICAL.ALT_MAX_OUTPUT = pending.alternatorMaxOutput
    ADS_Config.ELECTRICAL.IDLE_CURRENT_A = pending.idleCurrentA

    ADS_Config.FIELD_CARE.CLOGGING_SPEED = pending.cloggingSpeed
    ADS_Config.FIELD_CARE.VISUAL_INSPECTION_DURATION = pending.fieldInspectionDuration
    ADS_Config.FIELD_CARE.LUBRICATION_REDUCE_PER_DAY = pending.lubricationReducePerDay

    ADS_Config.DEBUG = pending.debugMode

    if batteryFactorChanged and ADS_Main ~= nil and ADS_Main.vehicles ~= nil then
        for _, vehicle in pairs(ADS_Main.vehicles) do
            if vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil and not vehicle.spec_AdvancedDamageSystem.isExcludedVehicle then
                AdvancedDamageSystem.rescaleBatteryChargeFromSoc(vehicle)

                local spec = vehicle.spec_AdvancedDamageSystem
                if vehicle.isServer and spec.adsDirtyFlag_electrical ~= nil then
                    vehicle:raiseDirtyFlags(spec.adsDirtyFlag_electrical)
                end
            end
        end
    end

    if workshopChanged and ADS_Main ~= nil and ADS_Main.forceWorkshopUpdate ~= nil then
        ADS_Main:forceWorkshopUpdate(true)
    end

    if g_currentMission ~= nil then
        if g_currentMission:getIsServer() and g_server ~= nil then
            g_server:broadcastEvent(ADS_SettingsSyncEvent.new())
        elseif g_client ~= nil then
            ADS_SettingsSyncEvent.send()
        end
    end
end

function ADS_InGameSettings.beginSettingsSession()
    ADS_InGameSettings.pendingConfig = buildPendingConfigFromAdsConfig()
    ADS_InGameSettings.ads_hasPendingSettingsChange = false

    if isCurrentMissionMultiplayer() then
        ADS_Config.TUTORIAL_MODE = false
        ADS_InGameSettings.pendingConfig.tutorialMode = false
    end

end

function ADS_InGameSettings:initializeSettingsPageControls(targetPage)
    local page = targetPage
    if page == nil or page.ads_initSettingsMenuDone then
        return
    end

    local function deleteElementById(elementId)
        local root = page.settingsPage or page.settingsLayout or page
        local element = root ~= nil and root:getDescendantById(elementId) or nil
        if element ~= nil then
            element:delete()
        end
    end

    ADS_InGameSettings:generateAllSteps()
    page.ads_settingsRowIsEven = false

    -- General
    page.ads_tutorialMode = ADS_InGameSettings:addBinaryOption(
        page,
        "onTutorialModeChanged",
        g_i18n:getText("ads_tutorialMode_label"),
        g_i18n:getText("ads_tutorialMode_tooltip")
    )
    page.ads_tutorialResetTips = ADS_InGameSettings:addButtonOption(
        page,
        "onResetTutorialTipsClicked",
        g_i18n:getText("ads_tutorialResetTips_label"),
        g_i18n:getText("ads_tutorialResetTips_text"),
        g_i18n:getText("ads_tutorialResetTips_tooltip")
    )
    page.ads_warningMessages = ADS_InGameSettings:addBinaryOption(
        page,
        "onWarningMessagesChanged",
        g_i18n:getText("ads_warningMessages_label"),
        g_i18n:getText("ads_warningMessages_tooltip")
    )
    page.ads_debugMode = ADS_InGameSettings:addBinaryOption(
        page,
        "onDebugModeChanged",
        g_i18n:getText("ads_debugMode_label"),
        g_i18n:getText("ads_debugMode_tooltip")
    )

    ADS_InGameSettings:addSectionHeader(page, g_i18n:getText("ads_settings_section_service_wear"))

    page.ads_serviceWear = ADS_InGameSettings:addMultiTextOption(
        page, "onServiceWearChanged",
        ADS_InGameSettings.steps.serviceWear.texts,
        g_i18n:getText("ads_serviceInterval_label"),
        g_i18n:getText("ads_serviceInterval_tooltip")
    )
    page.ads_conditionWear = ADS_InGameSettings:addMultiTextOption(
        page, "onConditionWearChanged",
        ADS_InGameSettings.steps.conditionWear.texts,
        g_i18n:getText("ads_vehicleLifespan_label"),
        g_i18n:getText("ads_vehicleLifespan_tooltip")
    )
    page.ads_systemStressRate = ADS_InGameSettings:addMultiTextOption(
        page, "onSystemStressRateChanged",
        ADS_InGameSettings.steps.systemStressRate.texts,
        g_i18n:getText("ads_systemStressRate_label"),
        g_i18n:getText("ads_systemStressRate_tooltip")
    )
    page.ads_downtimeWear = ADS_InGameSettings:addMultiTextOption(
        page, "onDowntimeWearChanged",
        ADS_InGameSettings.steps.downtimeWear.texts,
        g_i18n:getText("ads_downtimeWear_label"),
        g_i18n:getText("ads_downtimeWear_tooltip")
    )
    page.ads_generalWearEnabled = ADS_InGameSettings:addBinaryOption(
        page,
        "onGeneralWearEnabledChanged",
        g_i18n:getText("ads_generalWearEnabled_label"),
        g_i18n:getText("ads_generalWearEnabled_tooltip")
    )

    ADS_InGameSettings:addSectionHeader(page, g_i18n:getText("ads_ws_header_title"))

    -- Instant Inspection (Binary)
    page.ads_instantInspection = ADS_InGameSettings:addBinaryOption(
        page,
        "onInstantInspectionChanged",
        g_i18n:getText("ads_instantInspection_label"),
        g_i18n:getText("ads_instantInspection_tooltip")
    )

    -- Park Vehicle (Binary)
    page.ads_parkVehicle = ADS_InGameSettings:addBinaryOption(
        page,
        "onParkVehicleChanged",
        g_i18n:getText("ads_parkVehicle_label"),
        g_i18n:getText("ads_parkVehicle_tooltip")
    )

    -- Warranty Coverage (Binary)
    page.ads_warrantyEnabled = ADS_InGameSettings:addBinaryOption(
        page,
        "onWarrantyEnabledChanged",
        g_i18n:getText("ads_warrantyEnabled_label"),
        g_i18n:getText("ads_warrantyEnabled_tooltip")
    )

    -- Maintenance Price
    page.ads_maintenancePrice = ADS_InGameSettings:addMultiTextOption(
        page,
        "onMaintenancePriceChanged",
        ADS_InGameSettings.steps.maintPrice.texts,
        g_i18n:getText("ads_maintenancePrice_label"),
        g_i18n:getText("ads_maintenancePrice_tooltip")
    )

    -- Maintenance Duration
    page.ads_maintenanceDuration = ADS_InGameSettings:addMultiTextOption(
        page,
        "onMaintenanceDurationChanged",
        ADS_InGameSettings.steps.maintDuration.texts,
        g_i18n:getText("ads_maintenanceDuration_label"),
        g_i18n:getText("ads_maintenanceDuration_tooltip")
    )

    -- Mobile Workshop Restrictions (Binary)
    page.ads_mobileWorkshopRestrictions = ADS_InGameSettings:addBinaryOption(
        page,
        "onMobileWorkshopRestrictionsChanged",
        g_i18n:getText("ads_mobileWorkshopRestrictions_label"),
        g_i18n:getText("ads_mobileWorkshopRestrictions_tooltip")
    )

    -- Dealer Workshop Available (Binary)
    page.ads_dealerWorkshopAvailable = ADS_InGameSettings:addBinaryOption(
        page,
        "onDealerWorkshopAvailableChanged",
        g_i18n:getText("ads_dealerWorkshopAvailable_label"),
        g_i18n:getText("ads_dealerWorkshopAvailable_tooltip")
    )

    -- Mobile Workshop Available (Binary)
    page.ads_mobileWorkshopAvailable = ADS_InGameSettings:addBinaryOption(
        page,
        "onMobileWorkshopAvailableChanged",
        g_i18n:getText("ads_mobileWorkshopAvailable_label"),
        g_i18n:getText("ads_mobileWorkshopAvailable_tooltip")
    )

    -- Own Workshop Available (Binary)
    page.ads_ownWorkshopAvailable = ADS_InGameSettings:addBinaryOption(
        page,
        "onOwnWorkshopAvailableChanged",
        g_i18n:getText("ads_ownWorkshopAvailable_label"),
        g_i18n:getText("ads_ownWorkshopAvailable_tooltip")
    )

    -- Workshop Open Hour
    page.ads_workshopOpenHour = ADS_InGameSettings:addMultiTextOption(
        page,
        "onWorkshopOpenHourChanged",
        ADS_InGameSettings.steps.hours.texts,
        g_i18n:getText("ads_workshopOpenHour_label"),
        g_i18n:getText("ads_workshopOpenHour_tooltip")
    )

    -- Workshop Close Hour
    page.ads_workshopCloseHour = ADS_InGameSettings:addMultiTextOption(
        page,
        "onWorkshopCloseHourChanged",
        ADS_InGameSettings.steps.hours.texts,
        g_i18n:getText("ads_workshopCloseHour_label"),
        g_i18n:getText("ads_workshopCloseHour_tooltip")
    )

    ADS_InGameSettings:addSectionHeader(page, g_i18n:getText("ads_settings_section_thermal_model"))

    page.ads_thermalSensitivity = ADS_InGameSettings:addMultiTextOption(
        page, "onThermalSensitivityChanged",
        ADS_InGameSettings.steps.thermalSensitivity.texts,
        g_i18n:getText("ads_thermalSensitivity_label"),
        g_i18n:getText("ads_thermalSensitivity_tooltip")
    )
    page.ads_radiatorDirtInfluence = ADS_InGameSettings:addMultiTextOption(
        page,
        "onRadiatorDirtInfluenceChanged",
        ADS_InGameSettings.steps.radiatorDirtInfluence.texts,
        g_i18n:getText("ads_radiatorDirtInfluence_label"),
        g_i18n:getText("ads_radiatorDirtInfluence_tooltip")
    )
    page.ads_warmingBoostPower = ADS_InGameSettings:addMultiTextOption(
        page,
        "onWarmingBoostPowerChanged",
        ADS_InGameSettings.steps.thermalPower.texts,
        g_i18n:getText("ads_warmingBoostPower_label"),
        g_i18n:getText("ads_warmingBoostPower_tooltip")
    )
    page.ads_coolingSlowdownPower = ADS_InGameSettings:addMultiTextOption(
        page,
        "onCoolingSlowdownPowerChanged",
        ADS_InGameSettings.steps.thermalPower.texts,
        g_i18n:getText("ads_coolingSlowdownPower_label"),
        g_i18n:getText("ads_coolingSlowdownPower_tooltip")
    )

    ADS_InGameSettings:addSectionHeader(page, g_i18n:getText("ads_settings_section_battery_alternator"))

    page.ads_batteryCapacity = ADS_InGameSettings:addMultiTextOption(
        page, "onBatteryCapacityChanged",
        ADS_InGameSettings.steps.batteryCapacity.texts,
        g_i18n:getText("ads_batteryCapacity_label"),
        g_i18n:getText("ads_batteryCapacity_tooltip")
    )
    page.ads_alternatorMaxOutput = ADS_InGameSettings:addMultiTextOption(
        page,
        "onAlternatorMaxOutputChanged",
        ADS_InGameSettings.steps.alternatorMaxOutput.texts,
        g_i18n:getText("ads_alternatorMaxOutput_label"),
        g_i18n:getText("ads_alternatorMaxOutput_tooltip")
    )
    page.ads_idleCurrent = ADS_InGameSettings:addMultiTextOption(
        page,
        "onIdleCurrentChanged",
        ADS_InGameSettings.steps.idleCurrent.texts,
        g_i18n:getText("ads_idleCurrent_label"),
        g_i18n:getText("ads_idleCurrent_tooltip")
    )

    ADS_InGameSettings:addSectionHeader(page, g_i18n:getText("ads_settings_section_preshift_maintenance"))

    page.ads_cloggingSpeed = ADS_InGameSettings:addMultiTextOption(
        page,
        "onCloggingSpeedChanged",
        ADS_InGameSettings.steps.cloggingSpeed.texts,
        g_i18n:getText("ads_cloggingSpeed_label"),
        g_i18n:getText("ads_cloggingSpeed_tooltip")
    )
    page.ads_fieldInspectionDuration = ADS_InGameSettings:addMultiTextOption(
        page,
        "onFieldInspectionDurationChanged",
        ADS_InGameSettings.steps.fieldInspectionDuration.texts,
        g_i18n:getText("ads_fieldInspectionDuration_label"),
        g_i18n:getText("ads_fieldInspectionDuration_tooltip")
    )
    page.ads_lubricationReducePerDay = ADS_InGameSettings:addMultiTextOption(
        page,
        "onLubricationReducePerDayChanged",
        ADS_InGameSettings.steps.lubricationReducePerDay.texts,
        g_i18n:getText("ads_lubricationReducePerDay_label"),
        g_i18n:getText("ads_lubricationReducePerDay_tooltip")
    )

    ADS_InGameSettings:addSectionHeader(page, g_i18n:getText("ads_settings_section_other"))

    page.ads_aiOverloadAndOverheatControl = ADS_InGameSettings:addBinaryOption(
        page,
        "onAiOverloadAndOverheatControlChanged",
        g_i18n:getText("ads_aiOverloadAndOverheatControl_label"),
        g_i18n:getText("ads_aiOverloadAndOverheatControl_tooltip")
    )

    deleteElementById("subTitlePrefab")
    deleteElementById("binaryPrefab")
    deleteElementById("multiPrefab")

    page.settingsLayout:invalidateLayout()
    page.ads_initSettingsMenuDone = true
end

function ADS_InGameSettings:activateEmbeddedSettingsPage(page)
    if page == nil then
        return
    end

    self.embeddedPage = page
    page.ads_useFleetMenuStyle = true

    if self.pendingConfig == nil then
        ADS_InGameSettings.beginSettingsSession()
    end

    self:updateADSPageVisibility(page)

    if not canChangeADSSettings() then
        return
    end

    self:initializeSettingsPageControls(page)
    if page.settingsSlider ~= nil and page.settingsSlider.setDataElement ~= nil then
        page.settingsSlider:setDataElement(page.settingsLayout)
    end
    ADS_InGameSettings.registerEmbeddedFocus(page)
    self:updateADSPageVisibility(page)
    self:updateADSSettings(page)
end

function ADS_InGameSettings.registerEmbeddedFocus(page)
    if page == nil
        or page.ads_settingsFocusLoaded
        or page.settingsLayout == nil
        or FocusManager == nil
        or FocusManager.loadElementFromCustomValues == nil then
        return
    end

    local currentGui = FocusManager.currentGui
    if page.name ~= nil and FocusManager.setGui ~= nil then
        FocusManager:setGui(page.name)
    end

    if FocusManager.removeElement ~= nil then
        FocusManager:removeElement(page.settingsLayout)
    end
    FocusManager:loadElementFromCustomValues(page.settingsLayout)

    if currentGui ~= nil and FocusManager.setGui ~= nil then
        FocusManager:setGui(currentGui)
    end

    page.ads_settingsFocusLoaded = true
end

function ADS_InGameSettings:updateADSPageVisibility(targetPage)
    local page = targetPage
    if page == nil then
        return
    end

    local canChangeSettings = canChangeADSSettings()

    if page.noPermissionText ~= nil then
        page.noPermissionText:setVisible(not canChangeSettings)
    end
    if page.settingsLayout ~= nil then
        page.settingsLayout:setVisible(canChangeSettings and page.ads_initSettingsMenuDone == true)
    end
    if page.settingsSliderBox ~= nil then
        page.settingsSliderBox:setVisible(canChangeSettings and page.ads_initSettingsMenuDone == true)
    end
    if page.settingsTooltipSeparator ~= nil then
        page.settingsTooltipSeparator:setVisible(canChangeSettings and page.ads_initSettingsMenuDone == true)
    end
end

function ADS_InGameSettings:onFrameClose()
    if not ADS_InGameSettings.ads_hasPendingSettingsChange then
        ADS_InGameSettings.pendingConfig = nil
        return
    end

    local pending = ADS_InGameSettings.pendingConfig
    local current = buildPendingConfigFromAdsConfig()

    ADS_InGameSettings.pendingConfig = nil
    ADS_InGameSettings.ads_hasPendingSettingsChange = false

    if pending == nil then
        return
    end

    local anyChanged = false
    for key, oldValue in pairs(current) do
        if valuesDiffer(pending[key], oldValue) then
            anyChanged = true
            break
        end
    end

    if not anyChanged then
        return
    end

    ADS_InGameSettings.commitPendingConfig(current, pending)
end


function ADS_InGameSettings:updateADSSettings(currentPage)
    if currentPage == nil or not currentPage.ads_initSettingsMenuDone then return end

    local steps = ADS_InGameSettings.steps
    local pending = ADS_InGameSettings.pendingConfig or buildPendingConfigFromAdsConfig()
    local isMultiplayer = isCurrentMissionMultiplayer()
    local tutorialOption = currentPage.ads_tutorialMode
    local tutorialContainer = tutorialOption ~= nil and tutorialOption.parent or nil
    local tutorialResetButton = currentPage.ads_tutorialResetTips
    local tutorialResetContainer = tutorialResetButton ~= nil and tutorialResetButton.parent or nil

    if isMultiplayer then
        pending.tutorialMode = false
    end

    if tutorialContainer ~= nil then
        tutorialContainer:setVisible(not isMultiplayer)
    end
    if tutorialResetContainer ~= nil then
        tutorialResetContainer:setVisible(not isMultiplayer)
    end

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

    setIndex(currentPage.ads_systemStressRate, steps.systemStressRate.values, pending.systemStressGlobalMultiplier)
    setIndex(currentPage.ads_batteryCapacity, steps.batteryCapacity.values, pending.batteryUsableCapacityFactor)
    setIndex(currentPage.ads_alternatorMaxOutput, steps.alternatorMaxOutput.values, pending.alternatorMaxOutput)
    setIndex(currentPage.ads_idleCurrent, steps.idleCurrent.values, pending.idleCurrentA)
    setIndex(currentPage.ads_serviceWear, steps.serviceWear.values, pending.baseServiceWear)
    setIndex(currentPage.ads_conditionWear, steps.conditionWear.values, pending.baseSystemsWear)
    setIndex(currentPage.ads_downtimeWear, steps.downtimeWear.values, pending.downtimeMultiplier)
    setIndex(currentPage.ads_maintenancePrice, steps.maintPrice.values, pending.globalPriceMultiplier * 100)
    setIndex(currentPage.ads_maintenanceDuration, steps.maintDuration.values, pending.globalTimeMultiplier * 100)
    setIndex(currentPage.ads_thermalSensitivity, steps.thermalSensitivity.values, pending.engineMaxHeat)
    setIndex(currentPage.ads_radiatorDirtInfluence, steps.radiatorDirtInfluence.values, pending.maxDirtInfluence)
    setIndex(currentPage.ads_warmingBoostPower, steps.thermalPower.values, pending.warmingBoostPower)
    setIndex(currentPage.ads_coolingSlowdownPower, steps.thermalPower.values, pending.coolingSlowdownPower)
    setIndex(currentPage.ads_cloggingSpeed, steps.cloggingSpeed.values, pending.cloggingSpeed)
    setIndex(currentPage.ads_fieldInspectionDuration, steps.fieldInspectionDuration.values, pending.fieldInspectionDuration)
    setIndex(currentPage.ads_lubricationReducePerDay, steps.lubricationReducePerDay.values, pending.lubricationReducePerDay)
    
    if tutorialOption ~= nil then
        tutorialOption:setIsChecked(pending.tutorialMode, false, false)
    end
    currentPage.ads_instantInspection:setIsChecked(pending.instantInspection, false, false)
    currentPage.ads_parkVehicle:setIsChecked(pending.parkVehicle, false, false)
    currentPage.ads_warrantyEnabled:setIsChecked(pending.warrantyEnabled, false, false)
    currentPage.ads_generalWearEnabled:setIsChecked(pending.generalWearEnabled, false, false)
    currentPage.ads_warningMessages:setIsChecked(pending.enableWarningMessages, false, false)
    currentPage.ads_aiOverloadAndOverheatControl:setIsChecked(pending.aiOverloadControl, false, false)
    currentPage.ads_dealerWorkshopAvailable:setIsChecked(pending.dealerAlwaysAvailable, false, false)
    currentPage.ads_mobileWorkshopAvailable:setIsChecked(pending.mobileAlwaysAvailable, false, false)
    currentPage.ads_ownWorkshopAvailable:setIsChecked(pending.ownAlwaysAvailable, false, false)
    currentPage.ads_mobileWorkshopRestrictions:setIsChecked(pending.mobileWorkshopRestrictionsEnabled, false, false)
    currentPage.ads_debugMode:setIsChecked(pending.debugMode, false, false)
    
    setIndex(currentPage.ads_workshopOpenHour, steps.hours.values, pending.openHour)
    setIndex(currentPage.ads_workshopCloseHour, steps.hours.values, pending.closeHour)

    local areAllWorkshopAlwaysAvailableOptionsOff = not pending.dealerAlwaysAvailable
        and not pending.mobileAlwaysAvailable
        and not pending.ownAlwaysAvailable
    currentPage.ads_workshopOpenHour:setDisabled(areAllWorkshopAlwaysAvailableOptionsOff)
    currentPage.ads_workshopCloseHour:setDisabled(areAllWorkshopAlwaysAvailableOptionsOff)

    -- MP permission: only server host or dedicated-server admin can change settings.
    local canChangeSettings = canChangeADSSettings()
    local disableAll = not canChangeSettings

    if tutorialOption ~= nil then
        tutorialOption:setDisabled(disableAll or isMultiplayer)
    end
    if tutorialResetButton ~= nil then
        tutorialResetButton:setDisabled(disableAll or isMultiplayer)
    end
    currentPage.ads_serviceWear:setDisabled(disableAll)
    currentPage.ads_conditionWear:setDisabled(disableAll)
    currentPage.ads_downtimeWear:setDisabled(disableAll)
    currentPage.ads_generalWearEnabled:setDisabled(disableAll)

    currentPage.ads_systemStressRate:setDisabled(disableAll)
    currentPage.ads_batteryCapacity:setDisabled(disableAll)
    currentPage.ads_alternatorMaxOutput:setDisabled(disableAll)
    currentPage.ads_idleCurrent:setDisabled(disableAll)
    currentPage.ads_instantInspection:setDisabled(disableAll)
    currentPage.ads_parkVehicle:setDisabled(disableAll)
    currentPage.ads_warrantyEnabled:setDisabled(disableAll)
    currentPage.ads_maintenancePrice:setDisabled(disableAll)
    currentPage.ads_maintenanceDuration:setDisabled(disableAll)
    currentPage.ads_dealerWorkshopAvailable:setDisabled(disableAll)
    currentPage.ads_mobileWorkshopAvailable:setDisabled(disableAll)
    currentPage.ads_ownWorkshopAvailable:setDisabled(disableAll)
    currentPage.ads_mobileWorkshopRestrictions:setDisabled(disableAll)
    currentPage.ads_thermalSensitivity:setDisabled(disableAll)
    currentPage.ads_cloggingSpeed:setDisabled(disableAll)
    currentPage.ads_fieldInspectionDuration:setDisabled(disableAll)
    currentPage.ads_lubricationReducePerDay:setDisabled(disableAll)
    currentPage.ads_aiOverloadAndOverheatControl:setDisabled(disableAll)
    currentPage.ads_warningMessages:setDisabled(disableAll)
    currentPage.ads_debugMode:setDisabled(disableAll)

    -- Workshop hour controls are disabled while all workshop 24/7 options are off.
    if disableAll or areAllWorkshopAlwaysAvailableOptionsOff then
        currentPage.ads_workshopOpenHour:setDisabled(true)
        currentPage.ads_workshopCloseHour:setDisabled(true)
    end

    if tutorialContainer ~= nil or tutorialResetContainer ~= nil then
        currentPage.settingsLayout:invalidateLayout()
    end
end

-- --- Callback Handlers --- --
function ADS_InGameSettings:onServiceWearChanged(state)
    getPendingConfig().baseServiceWear = ADS_InGameSettings.steps.serviceWear.values[state]
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onTutorialModeChanged(state, optionElement)
    local pending = getPendingConfig()
    local newValue = false

    if not isCurrentMissionMultiplayer() then
        if optionElement ~= nil and optionElement.getIsChecked ~= nil then
            newValue = optionElement:getIsChecked()
        elseif ADS_InGameSettings.embeddedPage ~= nil
            and ADS_InGameSettings.embeddedPage.ads_tutorialMode ~= nil
            and ADS_InGameSettings.embeddedPage.ads_tutorialMode.getIsChecked ~= nil then
            newValue = ADS_InGameSettings.embeddedPage.ads_tutorialMode:getIsChecked()
        elseif BinaryOptionElement ~= nil and state == BinaryOptionElement.STATE_RIGHT then
            newValue = true
        elseif type(state) == "boolean" then
            newValue = not state
        end
    end

    pending.tutorialMode = newValue
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onResetTutorialTipsClicked()
    if isCurrentMissionMultiplayer() then
        return
    end

    YesNoDialog.show(function(shouldReset)
        if shouldReset then
            ADS_Config.resetTutorialMessages()
        end
    end, nil, g_i18n:getText("ads_tutorialResetConfirm_message"), g_i18n:getText("ads_tutorialResetConfirm_title"))
end

function ADS_InGameSettings:onConditionWearChanged(state)
    getPendingConfig().baseSystemsWear = ADS_InGameSettings.steps.conditionWear.values[state]
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onDowntimeWearChanged(state)
    getPendingConfig().downtimeMultiplier = ADS_InGameSettings.steps.downtimeWear.values[state]
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onGeneralWearEnabledChanged(state)
    getPendingConfig().generalWearEnabled = (state == BinaryOptionElement.STATE_RIGHT)
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onInstantInspectionChanged(state)
    getPendingConfig().instantInspection = (state == BinaryOptionElement.STATE_RIGHT)
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onParkVehicleChanged(state)
    getPendingConfig().parkVehicle = (state == BinaryOptionElement.STATE_RIGHT)
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onWarrantyEnabledChanged(state)
    getPendingConfig().warrantyEnabled = (state == BinaryOptionElement.STATE_RIGHT)
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onMaintenancePriceChanged(state)
    getPendingConfig().globalPriceMultiplier = ADS_InGameSettings.steps.maintPrice.values[state] / 100
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onMaintenanceDurationChanged(state)
    getPendingConfig().globalTimeMultiplier = ADS_InGameSettings.steps.maintDuration.values[state] / 100
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onDealerWorkshopAvailableChanged(state)
    getPendingConfig().dealerAlwaysAvailable = (state == BinaryOptionElement.STATE_RIGHT)
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onMobileWorkshopAvailableChanged(state)
    getPendingConfig().mobileAlwaysAvailable = (state == BinaryOptionElement.STATE_RIGHT)
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onOwnWorkshopAvailableChanged(state)
    getPendingConfig().ownAlwaysAvailable = (state == BinaryOptionElement.STATE_RIGHT)
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onMobileWorkshopRestrictionsChanged(state)
    getPendingConfig().mobileWorkshopRestrictionsEnabled = (state == BinaryOptionElement.STATE_RIGHT)
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onWorkshopOpenHourChanged(state)
    local pending = getPendingConfig()
    local newOpen = ADS_InGameSettings.steps.hours.values[state]
    local currentClose = pending.closeHour

    -- Keep open/close hours from overlapping.
    if newOpen >= currentClose then
        currentClose = newOpen + 1
        if currentClose > 23 then
            currentClose = 23
            newOpen = 22
        end
        pending.closeHour = currentClose
    end

    pending.openHour = newOpen
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onWorkshopCloseHourChanged(state)
    local pending = getPendingConfig()
    local newClose = ADS_InGameSettings.steps.hours.values[state]
    local currentOpen = pending.openHour

    -- Keep open/close hours from overlapping.
    if currentOpen >= newClose then
        currentOpen = newClose - 1
        if currentOpen < 0 then
            currentOpen = 0
            newClose = 1
        end
        pending.openHour = currentOpen
    end

    pending.closeHour = newClose
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end


function ADS_InGameSettings:onSystemStressRateChanged(state)
    getPendingConfig().systemStressGlobalMultiplier = ADS_InGameSettings.steps.systemStressRate.values[state]
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onBatteryCapacityChanged(state)
    getPendingConfig().batteryUsableCapacityFactor = ADS_InGameSettings.steps.batteryCapacity.values[state]
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onAlternatorMaxOutputChanged(state)
    getPendingConfig().alternatorMaxOutput = ADS_InGameSettings.steps.alternatorMaxOutput.values[state]
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onIdleCurrentChanged(state)
    getPendingConfig().idleCurrentA = ADS_InGameSettings.steps.idleCurrent.values[state]
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end


function ADS_InGameSettings:onThermalSensitivityChanged(state)
    local val = ADS_InGameSettings.steps.thermalSensitivity.values[state]
    local pending = getPendingConfig()
    pending.engineMaxHeat = val
    pending.transMaxHeat = val
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onRadiatorDirtInfluenceChanged(state)
    getPendingConfig().maxDirtInfluence = ADS_InGameSettings.steps.radiatorDirtInfluence.values[state]
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onWarmingBoostPowerChanged(state)
    getPendingConfig().warmingBoostPower = ADS_InGameSettings.steps.thermalPower.values[state]
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onCoolingSlowdownPowerChanged(state)
    getPendingConfig().coolingSlowdownPower = ADS_InGameSettings.steps.thermalPower.values[state]
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onCloggingSpeedChanged(state)
    getPendingConfig().cloggingSpeed = ADS_InGameSettings.steps.cloggingSpeed.values[state]
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onFieldInspectionDurationChanged(state)
    getPendingConfig().fieldInspectionDuration = ADS_InGameSettings.steps.fieldInspectionDuration.values[state]
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onLubricationReducePerDayChanged(state)
    getPendingConfig().lubricationReducePerDay = ADS_InGameSettings.steps.lubricationReducePerDay.values[state]
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onAiOverloadAndOverheatControlChanged(state)
    getPendingConfig().aiOverloadControl = (state == BinaryOptionElement.STATE_RIGHT)
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onWarningMessagesChanged(state)
    getPendingConfig().enableWarningMessages = (state == BinaryOptionElement.STATE_RIGHT)
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onDebugModeChanged(state)
    getPendingConfig().debugMode = (state == BinaryOptionElement.STATE_RIGHT)
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end


-- --- UI Helper Methods --- --
function ADS_InGameSettings:addSectionHeader(inGameMenuSettingsFrame, titleText)
    local textElement = TextElement.new()
    local textElementProfile = getSettingsProfile("fs25_settingsSectionHeader")
    textElement.name = "sectionHeader"
    textElement:loadProfile(textElementProfile, true)
    textElement:setText(titleText)
    inGameMenuSettingsFrame.settingsLayout:addElement(textElement)
    textElement:onGuiSetupFinished()
end

function ADS_InGameSettings:addMultiTextOption(inGameMenuSettingsFrame, onClickCallback, texts, title, tooltip)
    local bitMap = BitmapElement.new()
    local bitMapProfile = getSettingsProfile("fs25_multiTextOptionContainer")
    bitMap:loadProfile(bitMapProfile, true)
    applySettingsRowColor(inGameMenuSettingsFrame, bitMap)

    local multiTextOption = MultiTextOptionElement.new()
    local multiTextOptionProfile = getSettingsProfile("fs25_settingsMultiTextOption")
    multiTextOption:loadProfile(multiTextOptionProfile, true)
    multiTextOption.updateChildrenState = true
    multiTextOption.target = ADS_InGameSettings
    multiTextOption:setCallback("onClickCallback", onClickCallback)
    multiTextOption:setTexts(texts)

    local multiTextOptionTitle = TextElement.new()
    local multiTextOptionTitleProfile = getSettingsProfile("fs25_settingsMultiTextOptionTitle")
    multiTextOptionTitle:loadProfile(multiTextOptionTitleProfile, true)
    multiTextOptionTitle:setText(title)

    local multiTextOptionTooltip = TextElement.new()
    local multiTextOptionTooltipProfile = getSettingsProfile("fs25_multiTextOptionTooltip")
    multiTextOptionTooltip.name = "ignore"
    multiTextOptionTooltip:loadProfile(multiTextOptionTooltipProfile, true)
    multiTextOptionTooltip:setText(tooltip)

    multiTextOption:addElement(multiTextOptionTooltip)
    bitMap:addElement(multiTextOption)
    addDisabledLockToSettingsRow(bitMap, multiTextOption, tooltip)
    bitMap:addElement(multiTextOptionTitle)

    multiTextOption:onGuiSetupFinished()
    applyMultiTextOptionBackgroundProfile(multiTextOption)
    multiTextOptionTitle:onGuiSetupFinished()
    multiTextOptionTooltip:onGuiSetupFinished()

    inGameMenuSettingsFrame.settingsLayout:addElement(bitMap)
    bitMap:onGuiSetupFinished()
    
    return multiTextOption
end

function ADS_InGameSettings:addBinaryOption(inGameMenuSettingsFrame, onClickCallback, title, tooltip)
    local bitMap = BitmapElement.new()
    local bitMapProfile = getSettingsProfile("fs25_multiTextOptionContainer")
    bitMap:loadProfile(bitMapProfile, true)
    applySettingsRowColor(inGameMenuSettingsFrame, bitMap)

    local binaryOption = BinaryOptionElement.new()
    binaryOption.useYesNoTexts = true
    local binaryOptionProfile = getSettingsProfile("fs25_settingsBinaryOption")
    binaryOption:loadProfile(binaryOptionProfile, true)
    binaryOption.target = ADS_InGameSettings
    binaryOption:setCallback("onClickCallback", onClickCallback)

    local binaryOptionTitle = TextElement.new()
    local binaryOptionTitleProfile = getSettingsProfile("fs25_settingsMultiTextOptionTitle")
    binaryOptionTitle:loadProfile(binaryOptionTitleProfile, true)
    binaryOptionTitle:setText(title)

    local binaryOptionTooltip = TextElement.new()
    local binaryOptionTooltipProfile = getSettingsProfile("fs25_multiTextOptionTooltip")
    binaryOptionTooltip.name = "ignore"
    binaryOptionTooltip:loadProfile(binaryOptionTooltipProfile, true)
    binaryOptionTooltip:setText(tooltip)

    binaryOption:addElement(binaryOptionTooltip)
    bitMap:addElement(binaryOption)
    addDisabledLockToSettingsRow(bitMap, binaryOption, tooltip)
    bitMap:addElement(binaryOptionTitle)

    binaryOption:onGuiSetupFinished()
    binaryOptionTitle:onGuiSetupFinished()
    binaryOptionTooltip:onGuiSetupFinished()

    inGameMenuSettingsFrame.settingsLayout:addElement(bitMap)
    bitMap:onGuiSetupFinished()
    
    return binaryOption
end

function ADS_InGameSettings:addButtonOption(inGameMenuSettingsFrame, onClickCallback, title, text, tooltip)
    local template = getVanillaSettingsButtonTemplate()
    local bitMap
    local clonedTemplate = template ~= nil and template.clone ~= nil

    if clonedTemplate then
        bitMap = template:clone(inGameMenuSettingsFrame.settingsLayout)
        bitMap.id = nil
    else
        bitMap = BitmapElement.new()
        local bitMapProfile = getSettingsProfile("fs25_multiTextOptionContainer")
        bitMap:loadProfile(bitMapProfile, true)
        inGameMenuSettingsFrame.settingsLayout:addElement(bitMap)
    end

    applySettingsRowColor(inGameMenuSettingsFrame, bitMap)

    local button
    local buttonTitle

    for _, element in pairs(bitMap.elements) do
        if element.typeName == "Button" then
            button = element
        elseif element.typeName == "Text" and element.name ~= "ignore" then
            buttonTitle = element
        end
    end

    if button == nil then
        button = ButtonElement.new()
        bitMap:addElement(button)
    end

    button:applyProfile("ads_settingsButton")
    applyButtonBackgroundProfile(button)
    button.target = ADS_InGameSettings
    button:setCallback("onClickCallback", onClickCallback)
    button:setText(text)
    button.id = nil
    button.isAlwaysFocusedOnOpen = false
    button.focused = false

    if buttonTitle == nil then
        buttonTitle = TextElement.new()
        local buttonTitleProfile = getSettingsProfile("fs25_settingsMultiTextOptionTitle")
        buttonTitle:loadProfile(buttonTitleProfile, true)
        bitMap:addElement(buttonTitle)
    end

    buttonTitle:setText(title)
    buttonTitle.id = nil

    local buttonTooltip = button:getDescendantByName("ignore")
    if buttonTooltip == nil then
        buttonTooltip = TextElement.new()
        local buttonTooltipProfile = getSettingsProfile("fs25_multiTextOptionTooltip")
        buttonTooltip.name = "ignore"
        buttonTooltip:loadProfile(buttonTooltipProfile, true)
        button:addElement(buttonTooltip)
    end

    buttonTooltip:setText(tooltip)
    buttonTooltip.id = nil

    button:onGuiSetupFinished()
    buttonTitle:onGuiSetupFinished()
    buttonTooltip:onGuiSetupFinished()

    bitMap:onGuiSetupFinished()

    return button
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
        addHourRange(200.0, 1000.0, 100.0)

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
        addHourRange(2000, 10000, 1000)
        addHourRange(20000, 50000, 10000)

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

    -- System Stress Rate: 10% to 300%, then 350% to 1000% by 50%
    do
        local data = createSteps(0.1, 30, 0.1, function(v)
            return string.format("%.0f%%", v * 100)
        end)

        for percent = 350, 1000, 50 do
            table.insert(data.values, percent / 100)
            table.insert(data.texts, string.format("%d%%", percent))
        end

        self.steps.systemStressRate = data
    end

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

    -- Alternator Max Output: 100 A to 300 A.
    self.steps.alternatorMaxOutput = createSteps(100, 5, 50, function(v)
        return string.format("%d A", v)
    end)

    -- Idle Current: none, then 0.1 A to 2.0 A.
    do
        local data = { values = {0.0}, texts = {g_i18n:getText("ads_option_none")} }
        for tenths = 1, 20 do
            local value = tenths / 10
            table.insert(data.values, value)
            table.insert(data.texts, string.format("%.1f A", value))
        end
        self.steps.idleCurrent = data
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

    -- Radiator Dirt Influence: Off, then 10% to 50%.
    do
        local data = { values = {0.0}, texts = {g_i18n:getText("ads_option_off")} }
        for percent = 10, 50, 10 do
            table.insert(data.values, percent / 100)
            table.insert(data.texts, string.format("%d%%", percent))
        end
        self.steps.radiatorDirtInfluence = data
    end

    -- Thermal artificial scaling: Off, then 2x to 20x.
    do
        local data = { values = {1.0}, texts = {g_i18n:getText("ads_option_off")} }
        for multiplier = 2, 20 do
            table.insert(data.values, multiplier)
            table.insert(data.texts, string.format("%dx", multiplier))
        end
        self.steps.thermalPower = data
    end

    -- Clogging Speed: 10% to 300%
    self.steps.cloggingSpeed = createSteps(0.1, 30, 0.1, function(v)
        return string.format("%.0f%%", v * 100)
    end)

    -- Field Inspection Duration: 1 s to 30 s.
    self.steps.fieldInspectionDuration = createSteps(1000, 30, 1000, function(v)
        return string.format("%d s", v / 1000)
    end)

    -- Lubrication Drying: Off, then 10% to 100% per day.
    do
        local data = { values = {0.0}, texts = {g_i18n:getText("ads_option_off")} }
        for percent = 10, 100, 10 do
            table.insert(data.values, percent / 100)
            table.insert(data.texts, string.format("%d%%", percent))
        end
        self.steps.lubricationReducePerDay = data
    end

    self.steps.generated = true
end


function ADS_InGameSettings.reset()
    ADS_InGameSettings.steps = {}
    ADS_InGameSettings.pendingConfig = nil
    ADS_InGameSettings.ads_hasPendingSettingsChange = false
    ADS_InGameSettings.embeddedPage = nil
end
