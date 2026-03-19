ADS_MaintenanceThreeOptionsDialog = {}
ADS_MaintenanceThreeOptionsDialog.INSTANCE = nil

local ADS_MaintenanceThreeOptionsDialog_mt = Class(ADS_MaintenanceThreeOptionsDialog, MessageDialog)
local modDirectory = g_currentModDirectory

local function log_dbg(...)
    if ADS_Config and ADS_Config.DEBUG then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i])
        end
        print("[ADS_REPORT_DIALOG] " .. table.concat(args, " "))
    end
end

function ADS_MaintenanceThreeOptionsDialog.register()
    local dialog = ADS_MaintenanceThreeOptionsDialog.new()
    g_gui:loadGui(modDirectory .. "gui/ADS_MaintenanceThreeOptionsDialog.xml", "ADS_MaintenanceThreeOptionsDialog", dialog)
    ADS_MaintenanceThreeOptionsDialog.INSTANCE = dialog
end

function ADS_MaintenanceThreeOptionsDialog.new(target, customMt)
    local dialog = MessageDialog.new(target, customMt or ADS_MaintenanceThreeOptionsDialog_mt)
    dialog.vehicle = nil
    dialog.overhaulSystemValues = nil
    return dialog
end

local function getOverhaulSystemValues()
    local values = {}
    local index = 1

    while AdvancedDamageSystem.SYSTEMS[index] ~= nil do
        table.insert(values, AdvancedDamageSystem.SYSTEMS[index])
        index = index + 1
    end

    return values
end

local function getEnabledOverhaulSystemValues(vehicle)
    local values = {}
    local spec = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    local allSystems = getOverhaulSystemValues()

    if spec == nil or type(spec.systems) ~= "table" then
        return allSystems
    end

    for _, systemL10nKey in ipairs(allSystems) do
        local systemKey = ADS_Utils.getSystemKey(AdvancedDamageSystem.SYSTEMS, systemL10nKey)
        local systemData = spec.systems[systemKey]
        if type(systemData) == "table" and systemData.enabled ~= false then
            table.insert(values, systemL10nKey)
        end
    end

    return values
end

local function getEffectiveOptionTwo(dialog)
    if dialog == nil then
        return "NONE"
    end

    if dialog.maintenanceType == AdvancedDamageSystem.STATUS.OVERHAUL
        and dialog.selectedOptionOne ~= AdvancedDamageSystem.OVERHAUL_TYPES.PARTIAL then
        return "NONE"
    end

    return dialog.selectedOptionTwo
end

function ADS_MaintenanceThreeOptionsDialog.show(vehicle, maintenanceType)
    if ADS_MaintenanceThreeOptionsDialog.INSTANCE == nil then ADS_MaintenanceThreeOptionsDialog.register() end
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil or maintenanceType == nil then return end
    
    local dialog = ADS_MaintenanceThreeOptionsDialog.INSTANCE
    dialog.vehicle = vehicle
    dialog.maintenanceType = maintenanceType
    dialog.optionOne:setState(1)
    dialog.optionTwo:setState(1)
    dialog.optionThree:setState(BinaryOptionElement.STATE_LEFT)

    if dialog.maintenanceType == AdvancedDamageSystem.STATUS.MAINTENANCE then
        dialog.selectedOptionOne = AdvancedDamageSystem.MAINTENANCE_TYPES[1]
    elseif dialog.maintenanceType == AdvancedDamageSystem.STATUS.REPAIR then
        dialog.selectedOptionOne = AdvancedDamageSystem.REPAIR_TYPES[1]
    elseif dialog.maintenanceType == AdvancedDamageSystem.STATUS.OVERHAUL then
        dialog.selectedOptionOne = AdvancedDamageSystem.OVERHAUL_TYPES[1]
    end
    dialog.overhaulSystemValues = getEnabledOverhaulSystemValues(vehicle)
    dialog.selectedOptionTwo = dialog.maintenanceType == AdvancedDamageSystem.STATUS.OVERHAUL
        and dialog.overhaulSystemValues[1]
        or AdvancedDamageSystem.PART_TYPES[1]
    dialog.selectedOptionThree = false
    dialog.optionThree.useYesNoTexts = true
    
    dialog:updateScreen()
    g_gui:showDialog("ADS_MaintenanceThreeOptionsDialog")
end

function ADS_MaintenanceThreeOptionsDialog:updateScreen()
    if self.vehicle == nil then return end
    log_dbg("Updating log Screen...")

    local spec = self.vehicle.spec_AdvancedDamageSystem
    local workshopType = ADS_WorkshopDialog.INSTANCE ~= nil and ADS_WorkshopDialog.INSTANCE.workshopType or spec.workshopType

    -- title
    self.dialogTitleElement:setText(g_i18n:getText(self.maintenanceType))

    -- option one
    local optionOneText = ""
    local optionOneOptions = {}

    if self.maintenanceType == AdvancedDamageSystem.STATUS.MAINTENANCE then
        optionOneText = g_i18n:getText("ads_option_menu_option_one_title_maintenance")
        optionOneOptions = {
            g_i18n:getText(AdvancedDamageSystem.MAINTENANCE_TYPES.STANDARD),
            g_i18n:getText(AdvancedDamageSystem.MAINTENANCE_TYPES.MINIMAL),
            g_i18n:getText(AdvancedDamageSystem.MAINTENANCE_TYPES.EXTENDED),
            g_i18n:getText(AdvancedDamageSystem.MAINTENANCE_TYPES.PREVENTIVE)
        }
    elseif self.maintenanceType == AdvancedDamageSystem.STATUS.REPAIR then
        optionOneText = g_i18n:getText("ads_option_menu_option_one_title_repair")
        optionOneOptions = {
            g_i18n:getText(AdvancedDamageSystem.REPAIR_TYPES.LOW),
            g_i18n:getText(AdvancedDamageSystem.REPAIR_TYPES.MEDIUM),
            g_i18n:getText(AdvancedDamageSystem.REPAIR_TYPES.HIGH)
        }
    else
        optionOneText = g_i18n:getText("ads_option_menu_option_one_title_overhaul")
        optionOneOptions = {
            g_i18n:getText(AdvancedDamageSystem.OVERHAUL_TYPES.STANDARD),
            g_i18n:getText(AdvancedDamageSystem.OVERHAUL_TYPES.PARTIAL),
            g_i18n:getText(AdvancedDamageSystem.OVERHAUL_TYPES.FULL)
        }
    end

    self.optionOneText:setText(optionOneText)
    self.optionOne:setTexts(optionOneOptions)

    -- option two
    local optionTwoText = ""
    local optionTwoOptions = {}

    if self.maintenanceType == AdvancedDamageSystem.STATUS.MAINTENANCE then
        optionTwoText = g_i18n:getText("ads_option_menu_option_two_title_maintenance")
        optionTwoOptions = {
            g_i18n:getText(AdvancedDamageSystem.PART_TYPES.OEM),
            g_i18n:getText(AdvancedDamageSystem.PART_TYPES.USED),
            g_i18n:getText(AdvancedDamageSystem.PART_TYPES.AFTERMARKET),
            g_i18n:getText(AdvancedDamageSystem.PART_TYPES.PREMIUM)
        }
    elseif self.maintenanceType == AdvancedDamageSystem.STATUS.REPAIR then
        optionTwoText = g_i18n:getText("ads_option_menu_option_two_title_repair")
        optionTwoOptions = {
            g_i18n:getText(AdvancedDamageSystem.PART_TYPES.OEM),
            g_i18n:getText(AdvancedDamageSystem.PART_TYPES.USED),
            g_i18n:getText(AdvancedDamageSystem.PART_TYPES.AFTERMARKET),
            g_i18n:getText(AdvancedDamageSystem.PART_TYPES.PREMIUM)
        }
    else
        optionTwoText = g_i18n:getText("ads_option_menu_option_two_title_overhaul")
        optionTwoOptions = {}
        self.overhaulSystemValues = self.overhaulSystemValues or getEnabledOverhaulSystemValues(self.vehicle)
        for _, systemL10nKey in ipairs(self.overhaulSystemValues) do
            table.insert(optionTwoOptions, g_i18n:getText(systemL10nKey))
        end
    end

    self.optionTwoText:setText(optionTwoText)
    self.optionTwo:setTexts(optionTwoOptions)

    -- Keep selected options synchronized with actual UI state.
    -- This avoids mismatches if callback parameters differ across UI elements.
    if self.optionOne ~= nil and self.optionOne.getState ~= nil then
        local optionOneState = tonumber(self.optionOne:getState())
        if optionOneState ~= nil then
            if self.maintenanceType == AdvancedDamageSystem.STATUS.MAINTENANCE and AdvancedDamageSystem.MAINTENANCE_TYPES[optionOneState] ~= nil then
                self.selectedOptionOne = AdvancedDamageSystem.MAINTENANCE_TYPES[optionOneState]
            elseif self.maintenanceType == AdvancedDamageSystem.STATUS.REPAIR and AdvancedDamageSystem.REPAIR_TYPES[optionOneState] ~= nil then
                self.selectedOptionOne = AdvancedDamageSystem.REPAIR_TYPES[optionOneState]
            elseif self.maintenanceType == AdvancedDamageSystem.STATUS.OVERHAUL and AdvancedDamageSystem.OVERHAUL_TYPES[optionOneState] ~= nil then
                self.selectedOptionOne = AdvancedDamageSystem.OVERHAUL_TYPES[optionOneState]
            end
        end
    end

    if self.optionTwo ~= nil and self.optionTwo.getState ~= nil then
        local optionTwoState = tonumber(self.optionTwo:getState())
        if optionTwoState ~= nil then
            if self.maintenanceType == AdvancedDamageSystem.STATUS.OVERHAUL then
                self.overhaulSystemValues = self.overhaulSystemValues or getEnabledOverhaulSystemValues(self.vehicle)
                if self.overhaulSystemValues[optionTwoState] ~= nil then
                    self.selectedOptionTwo = self.overhaulSystemValues[optionTwoState]
                end
            elseif AdvancedDamageSystem.PART_TYPES[optionTwoState] ~= nil then
                self.selectedOptionTwo = AdvancedDamageSystem.PART_TYPES[optionTwoState]
            end
        end
    end

    local disableOptionTwo = false
    if self.maintenanceType == AdvancedDamageSystem.STATUS.REPAIR then
        disableOptionTwo = self.selectedOptionOne == AdvancedDamageSystem.REPAIR_TYPES.LOW
    elseif self.maintenanceType == AdvancedDamageSystem.STATUS.OVERHAUL then
        disableOptionTwo = self.selectedOptionOne ~= AdvancedDamageSystem.OVERHAUL_TYPES.PARTIAL
    end
    self.optionTwo:setDisabled(disableOptionTwo)

    -- price, duration, finishtime
    local isWarrantyRepair = self.maintenanceType == AdvancedDamageSystem.STATUS.REPAIR
        and self.vehicle:isWarrantyRepairCovered(self.selectedOptionOne, self.selectedOptionTwo)
    local effectiveOptionTwo = getEffectiveOptionTwo(self)
    local servicePrice = self.vehicle:getServicePrice(self.maintenanceType, self.selectedOptionOne, effectiveOptionTwo, self.selectedOptionThree, workshopType)

    if isWarrantyRepair then
        self.maintenancePrice:setText(g_i18n:getText("ads_option_menu_price_text") .. g_i18n:getText("ads_option_menu_warranty_repair_text"))
    else
        self.maintenancePrice:setText(g_i18n:getText("ads_option_menu_price_text") .. g_i18n:formatMoney(servicePrice))
    end
    self.maintenanceDuration:setText(g_i18n:getText("ads_option_menu_duration_text") .. ADS_Utils.formatDuration(self.vehicle:getServiceDuration(self.maintenanceType, self.selectedOptionOne, effectiveOptionTwo, self.selectedOptionThree, workshopType)))
    self.maintenanceFinishTime:setText(g_i18n:getText("ads_option_menu_finish_time_text") .. ADS_Utils.formatFinishTime(self.vehicle:getServiceFinishTime(self.maintenanceType, self.selectedOptionOne, effectiveOptionTwo, self.selectedOptionThree, workshopType)))

    -- disclaimers
    local optionOneDisclaimers = {}

    if self.maintenanceType == AdvancedDamageSystem.STATUS.MAINTENANCE then
        optionOneDisclaimers = {
            g_i18n:getText("ads_option_menu_maintenance_standard_description"),
            g_i18n:getText("ads_option_menu_maintenance_minimal_description"),
            g_i18n:getText("ads_option_menu_maintenance_extended_description"),
            g_i18n:getText("ads_option_menu_maintenance_preventive_description")
        }
        self.optionOneDisclaimer:setText(optionOneDisclaimers[ADS_Utils.getIndexByValue(AdvancedDamageSystem.MAINTENANCE_TYPES, self.selectedOptionOne)] or "")
    elseif self.maintenanceType == AdvancedDamageSystem.STATUS.REPAIR then
        optionOneDisclaimers = {
            g_i18n:getText("ads_option_menu_repair_type_fix_description"),
            g_i18n:getText("ads_option_menu_repair_type_replacement_description"),
            g_i18n:getText("ads_option_menu_repair_type_with_related_parts_description")
        }
        self.optionOneDisclaimer:setText(optionOneDisclaimers[ADS_Utils.getIndexByValue(AdvancedDamageSystem.REPAIR_TYPES, self.selectedOptionOne)] or "")
    else
        optionOneDisclaimers = {
            g_i18n:getText("ads_option_menu_overhaul_standard_description"),
            g_i18n:getText("ads_option_menu_overhaul_partial_description"),
            g_i18n:getText("ads_option_menu_overhaul_full_description")
        }
        self.optionOneDisclaimer:setText(optionOneDisclaimers[ADS_Utils.getIndexByValue(AdvancedDamageSystem.OVERHAUL_TYPES, self.selectedOptionOne)] or "")
    end

    if self.maintenanceType == AdvancedDamageSystem.STATUS.OVERHAUL then
        self.optionTwoDisclaimer:setText("")
    else
        local optionTwoDisclaimers = {
            g_i18n:getText("ads_option_menu_part_oem_description"),
            g_i18n:getText("ads_option_menu_part_used_description"),
            g_i18n:getText("ads_option_menu_part_aftermarket_description"),
            g_i18n:getText("ads_option_menu_part_premium_description")
        }
        self.optionTwoDisclaimer:setText(optionTwoDisclaimers[ADS_Utils.getIndexByValue(AdvancedDamageSystem.PART_TYPES, self.selectedOptionTwo)] or "")
    end

    -- option three
    if self.maintenanceType == AdvancedDamageSystem.STATUS.MAINTENANCE then
        self.optionThreeText:setText(g_i18n:getText("ads_option_menu_perform_repair"))
    elseif self.maintenanceType == AdvancedDamageSystem.STATUS.REPAIR then
        self.optionThreeText:setText(g_i18n:getText("ads_option_menu_perform_maintenance"))
    else
        self.optionThreeText:setText(g_i18n:getText("ads_option_menu_perform_renew_paint"))
    end

end


-- ====================================================================
-- CALLBACKS & EVENTS
-- ====================================================================

function ADS_MaintenanceThreeOptionsDialog:onClickOptionOne(index)
    if self.maintenanceType == AdvancedDamageSystem.STATUS.MAINTENANCE then
        self.selectedOptionOne = AdvancedDamageSystem.MAINTENANCE_TYPES[index]
    elseif self.maintenanceType == AdvancedDamageSystem.STATUS.REPAIR then
        self.selectedOptionOne = AdvancedDamageSystem.REPAIR_TYPES[index]
    elseif self.maintenanceType == AdvancedDamageSystem.STATUS.OVERHAUL then
        self.selectedOptionOne = AdvancedDamageSystem.OVERHAUL_TYPES[index]
    end
    self:updateScreen()
end

function ADS_MaintenanceThreeOptionsDialog:onClickOptionTwo(index)
    if self.maintenanceType == AdvancedDamageSystem.STATUS.OVERHAUL then
        self.overhaulSystemValues = self.overhaulSystemValues or getEnabledOverhaulSystemValues(self.vehicle)
        self.selectedOptionTwo = self.overhaulSystemValues[index] or self.selectedOptionTwo
    else
        self.selectedOptionTwo = AdvancedDamageSystem.PART_TYPES[index]
    end
    self:updateScreen()
end

function ADS_MaintenanceThreeOptionsDialog:onClickOptionThree(state, binaryOptionElement)
    self.selectedOptionThree = (state == BinaryOptionElement.STATE_RIGHT)
    self:updateScreen()
end

function ADS_MaintenanceThreeOptionsDialog:onClickStartService()
    local vehicle = self.vehicle
    local workshopType = ADS_WorkshopDialog.INSTANCE.workshopType
    local effectiveOptionTwo = getEffectiveOptionTwo(self)
    
    local price = vehicle:getServicePrice(self.maintenanceType, self.selectedOptionOne, effectiveOptionTwo, self.selectedOptionThree, workshopType)
    if g_currentMission:getMoney() < price then
        InfoDialog.show(g_i18n:getText("shop_messageNotEnoughMoneyToBuy"))
        return
    end

    if g_server ~= nil then
        -- Server: execute locally and broadcast
        vehicle:initService(self.maintenanceType, workshopType, self.selectedOptionOne, effectiveOptionTwo, self.selectedOptionThree)
        g_currentMission:addMoney(-1 * price, vehicle:getOwnerFarmId(), MoneyType.VEHICLE_RUNNING_COSTS, true, true)
        ADS_VehicleChangeStatusEvent.send(vehicle)
    else
        -- Client: only send request to server
        ADS_ServiceRequestEvent.send(vehicle, self.maintenanceType, workshopType, self.selectedOptionOne, effectiveOptionTwo, self.selectedOptionThree, price)
    end

    self:close()
end

function ADS_MaintenanceThreeOptionsDialog:onClickBack()
    self:close()
end

function ADS_MaintenanceThreeOptionsDialog:onOpen(superFunc)
    g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.updateScreen, self)
end

function ADS_MaintenanceThreeOptionsDialog:onClose(superFunc)
    self.vehicle = nil
    g_messageCenter:unsubscribeAll(self)
end
