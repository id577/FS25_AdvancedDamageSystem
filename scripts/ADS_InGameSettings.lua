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

        alwaysAvailable = ADS_Config.WORKSHOP.ALWAYS_AVAILABLE,
        mobileWorkshopRestrictionsEnabled = ADS_Config.WORKSHOP.MOBILE_WORKSHOP_RESTRICTIONS_ENABLED,
        openHour = ADS_Config.WORKSHOP.OPEN_HOUR,
        closeHour = ADS_Config.WORKSHOP.CLOSE_HOUR,

        engineMaxHeat = ADS_Config.THERMAL.ENGINE_MAX_HEAT,
        transMaxHeat = ADS_Config.THERMAL.TRANS_MAX_HEAT,

        batteryUsableCapacityFactor = ADS_Config.ELECTRICAL.BATTERY_USABLE_CAPACITY_FACTOR,

        cloggingSpeed = ADS_Config.FIELD_CARE.CLOGGING_SPEED,

        debugMode = ADS_Config.DEBUG
    }
end

local function getPendingConfig()
    if ADS_InGameSettings.pendingConfig == nil then
        ADS_InGameSettings.pendingConfig = buildPendingConfigFromAdsConfig()
    end

    return ADS_InGameSettings.pendingConfig
end

local function getCurrentSettingsPage()
    return g_gui ~= nil
        and g_gui.currentGui ~= nil
        and g_gui.currentGui.target ~= nil
        and g_gui.currentGui.target.currentPage
        or nil
end

local function isCurrentMissionMultiplayer()
    return g_currentMission ~= nil
        and g_currentMission.missionDynamicInfo ~= nil
        and g_currentMission.missionDynamicInfo.isMultiplayer == true
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
        valuesDiffer(pending.alwaysAvailable, current.alwaysAvailable) or
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

    ADS_Config.WORKSHOP.ALWAYS_AVAILABLE = pending.alwaysAvailable
    ADS_Config.WORKSHOP.MOBILE_WORKSHOP_RESTRICTIONS_ENABLED = pending.mobileWorkshopRestrictionsEnabled
    ADS_Config.WORKSHOP.OPEN_HOUR = pending.openHour
    ADS_Config.WORKSHOP.CLOSE_HOUR = pending.closeHour

    ADS_Config.THERMAL.ENGINE_MAX_HEAT = pending.engineMaxHeat
    ADS_Config.THERMAL.TRANS_MAX_HEAT = pending.transMaxHeat

    ADS_Config.ELECTRICAL.BATTERY_USABLE_CAPACITY_FACTOR = pending.batteryUsableCapacityFactor

    ADS_Config.FIELD_CARE.CLOGGING_SPEED = pending.cloggingSpeed

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
        ADS_Main:forceWorkshopUpdate()
    end

    if g_currentMission ~= nil then
        if g_currentMission:getIsServer() and g_server ~= nil then
            g_server:broadcastEvent(ADS_SettingsSyncEvent.new())
        elseif g_client ~= nil then
            ADS_SettingsSyncEvent.send()
        end
    end
end

function ADS_InGameSettings:onFrameOpen()
    ADS_InGameSettings.pendingConfig = buildPendingConfigFromAdsConfig()
    ADS_InGameSettings.ads_hasPendingSettingsChange = false

    if isCurrentMissionMultiplayer() then
        ADS_Config.TUTORIAL_MODE = false
        ADS_InGameSettings.pendingConfig.tutorialMode = false
    end

    if self.ads_initSettingsMenuDone then
        ADS_InGameSettings:updateADSSettings(self)
        return
    end
    if self.ads_initSettingsMenuDone then
        return
    end

    ADS_InGameSettings:generateAllSteps()

    ADS_InGameSettings:addSectionHeader(self, "Advanced Damage System")

    -- Tutorial mode (Binary)
    self.ads_tutorialMode = ADS_InGameSettings:addBinaryOption(
        self,
        "onTutorialModeChanged",
        g_i18n:getText("ads_tutorialMode_label"),
        g_i18n:getText("ads_tutorialMode_tooltip")
    )

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

    -- Warning Messages (Binary)
    self.ads_warningMessages = ADS_InGameSettings:addBinaryOption(
        self,
        "onWarningMessagesChanged",
        g_i18n:getText("ads_warningMessages_label"),
        g_i18n:getText("ads_warningMessages_tooltip")
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

    local shouldAskTutorialReset = current.tutorialMode ~= true
        and pending.tutorialMode == true
        and not isCurrentMissionMultiplayer()

    if shouldAskTutorialReset then
        YesNoDialog.show(function(shouldReset)
            if shouldReset then
                ADS_Config.resetTutorialMessages()
            end

            ADS_InGameSettings.commitPendingConfig(current, pending)
        end, self, g_i18n:getText("ads_tutorialResetConfirm_message"), g_i18n:getText("ads_tutorialResetConfirm_title"))
        return
    end

    ADS_InGameSettings.commitPendingConfig(current, pending)
end


function ADS_InGameSettings:updateGameSettings()
    ADS_InGameSettings:updateADSSettings(self)
end

function ADS_InGameSettings:updateADSSettings(currentPage)
    if not currentPage.ads_initSettingsMenuDone then return end

    local steps = ADS_InGameSettings.steps
    local pending = ADS_InGameSettings.pendingConfig or buildPendingConfigFromAdsConfig()
    local isMultiplayer = isCurrentMissionMultiplayer()
    local tutorialOption = currentPage.ads_tutorialMode
    local tutorialContainer = tutorialOption ~= nil and tutorialOption.parent or nil

    if isMultiplayer then
        pending.tutorialMode = false
    end

    if tutorialContainer ~= nil then
        tutorialContainer:setVisible(not isMultiplayer)
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
    setIndex(currentPage.ads_serviceWear, steps.serviceWear.values, pending.baseServiceWear)
    setIndex(currentPage.ads_conditionWear, steps.conditionWear.values, pending.baseSystemsWear)
    setIndex(currentPage.ads_downtimeWear, steps.downtimeWear.values, pending.downtimeMultiplier)
    setIndex(currentPage.ads_maintenancePrice, steps.maintPrice.values, pending.globalPriceMultiplier * 100)
    setIndex(currentPage.ads_maintenanceDuration, steps.maintDuration.values, pending.globalTimeMultiplier * 100)
    setIndex(currentPage.ads_thermalSensitivity, steps.thermalSensitivity.values, pending.engineMaxHeat)
    setIndex(currentPage.ads_cloggingSpeed, steps.cloggingSpeed.values, pending.cloggingSpeed)
    
    if tutorialOption ~= nil then
        tutorialOption:setIsChecked(pending.tutorialMode, false, false)
    end
    currentPage.ads_instantInspection:setIsChecked(pending.instantInspection, false, false)
    currentPage.ads_parkVehicle:setIsChecked(pending.parkVehicle, false, false)
    currentPage.ads_warrantyEnabled:setIsChecked(pending.warrantyEnabled, false, false)
    currentPage.ads_generalWearEnabled:setIsChecked(pending.generalWearEnabled, false, false)
    currentPage.ads_warningMessages:setIsChecked(pending.enableWarningMessages, false, false)
    currentPage.ads_aiOverloadAndOverheatControl:setIsChecked(pending.aiOverloadControl, false, false)
    currentPage.ads_workshopAvailable:setIsChecked(pending.alwaysAvailable, false, false)
    currentPage.ads_mobileWorkshopRestrictions:setIsChecked(pending.mobileWorkshopRestrictionsEnabled, false, false)
    currentPage.ads_debugMode:setIsChecked(pending.debugMode, false, false)
    
    setIndex(currentPage.ads_workshopOpenHour, steps.hours.values, pending.openHour)
    setIndex(currentPage.ads_workshopCloseHour, steps.hours.values, pending.closeHour)

    local isAlwaysAvailable = pending.alwaysAvailable
    currentPage.ads_workshopOpenHour:setDisabled(isAlwaysAvailable)
    currentPage.ads_workshopCloseHour:setDisabled(isAlwaysAvailable)

    -- MP permission: only server host or dedicated-server admin can change settings.
    local canChangeSettings = g_currentMission ~= nil
        and (g_currentMission:getIsServer() or g_currentMission.isMasterUser)
        and g_currentMission:getIsClient()
    local disableAll = not canChangeSettings

    if tutorialOption ~= nil then
        tutorialOption:setDisabled(disableAll or isMultiplayer)
    end
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
    currentPage.ads_warningMessages:setDisabled(disableAll)
    currentPage.ads_debugMode:setDisabled(disableAll)

    -- Workshop hour controls: disabled if non-server OR always-available is on.
    if disableAll or isAlwaysAvailable then
        currentPage.ads_workshopOpenHour:setDisabled(true)
        currentPage.ads_workshopCloseHour:setDisabled(true)
    end

    if tutorialContainer ~= nil then
        currentPage.gameSettingsLayout:invalidateLayout()
        currentPage:updateAlternatingElements(currentPage.gameSettingsLayout)
        currentPage:updateGeneralSettings(currentPage.gameSettingsLayout)
    end
end

-- --- Callback Handlers --- --
function ADS_InGameSettings:onServiceWearChanged(state)
    getPendingConfig().baseServiceWear = ADS_InGameSettings.steps.serviceWear.values[state]
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onTutorialModeChanged(state)
    local pending = getPendingConfig()
    pending.tutorialMode = not isCurrentMissionMultiplayer() and (state == BinaryOptionElement.STATE_RIGHT)
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
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

function ADS_InGameSettings:onWorkshopAvailableChanged(state)
    getPendingConfig().alwaysAvailable = (state == BinaryOptionElement.STATE_RIGHT)
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

    -- Logic for avoiding overlap
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

    -- Logic for avoiding overlap
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


function ADS_InGameSettings:onThermalSensitivityChanged(state)
    local val = ADS_InGameSettings.steps.thermalSensitivity.values[state]
    local pending = getPendingConfig()
    pending.engineMaxHeat = val
    pending.transMaxHeat = val
    ADS_InGameSettings.ads_hasPendingSettingsChange = true
    refreshCurrentSettingsPage()
end

function ADS_InGameSettings:onCloggingSpeedChanged(state)
    getPendingConfig().cloggingSpeed = ADS_InGameSettings.steps.cloggingSpeed.values[state]
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
    InGameMenuSettingsFrame.onFrameClose = Utils.appendedFunction(InGameMenuSettingsFrame.onFrameClose, ADS_InGameSettings.onFrameClose)
end


ADS_InGameSettings.init()
