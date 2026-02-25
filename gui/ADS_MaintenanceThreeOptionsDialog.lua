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
    return dialog
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
        dialog.selectedOptionOne = AdvancedDamageSystem.REPAIR_URGENCY[1]
    end
    dialog.selectedOptionTwo = AdvancedDamageSystem.PART_TYPES[1]
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
            g_i18n:getText(AdvancedDamageSystem.MAINTENANCE_TYPES.EXTENDED)
        }
    else
        optionOneText = g_i18n:getText("ads_option_menu_option_one_title_repair")
        optionOneOptions = {
            g_i18n:getText(AdvancedDamageSystem.REPAIR_URGENCY.MEDIUM),
            g_i18n:getText(AdvancedDamageSystem.REPAIR_URGENCY.LOW),
            g_i18n:getText(AdvancedDamageSystem.REPAIR_URGENCY.HIGH)
        }
    end

    self.optionOneText:setText(optionOneText)
    self.optionOne:setTexts(optionOneOptions)

    -- option two
    local optionTwoText = ""
    local optionTwoOptions = {}

    if self.maintenanceType == AdvancedDamageSystem.STATUS.MAINTENANCE then
        optionTwoText = g_i18n:getText("ads_option_menu_option_two_title_maintenance")
    else
        optionTwoText = g_i18n:getText("ads_option_menu_option_two_title_repair")
    end

    optionTwoOptions = {
        g_i18n:getText(AdvancedDamageSystem.PART_TYPES.OEM),
        g_i18n:getText(AdvancedDamageSystem.PART_TYPES.USED),
        g_i18n:getText(AdvancedDamageSystem.PART_TYPES.AFTERMARKET),
        g_i18n:getText(AdvancedDamageSystem.PART_TYPES.PREMIUM)
    }

    self.optionTwoText:setText(optionTwoText)
    self.optionTwo:setTexts(optionTwoOptions)

    -- price, duration, finishtime
    local servicePrice = self.vehicle:getServicePrice(self.maintenanceType, self.selectedOptionOne, self.selectedOptionTwo, self.selectedOptionThree, workshopType)
    if self.maintenanceType == AdvancedDamageSystem.STATUS.REPAIR and self.vehicle:isWarrantyRepairCovered(self.selectedOptionTwo) then
        self.maintenancePrice:setText(g_i18n:getText("ads_option_menu_price_text") .. g_i18n:getText("ads_option_menu_warranty_repair_text"))
    else
        self.maintenancePrice:setText(g_i18n:getText("ads_option_menu_price_text") .. g_i18n:formatMoney(servicePrice))
    end
    self.maintenanceDuration:setText(g_i18n:getText("ads_option_menu_duration_text") .. ADS_Utils.formatDuration(self.vehicle:getServiceDuration(self.maintenanceType, self.selectedOptionOne, self.selectedOptionTwo, self.selectedOptionThree, workshopType)))
    self.maintenanceFinishTime:setText(g_i18n:getText("ads_option_menu_finish_time_text") .. ADS_Utils.formatFinishTime(self.vehicle:getServiceFinishTime(self.maintenanceType, self.selectedOptionOne, self.selectedOptionTwo, self.selectedOptionThree, workshopType)))

    -- disclaimers
    local optionOneDisclaimers = {}

    if self.maintenanceType == AdvancedDamageSystem.STATUS.MAINTENANCE then
        optionOneDisclaimers = {
            g_i18n:getText("ads_option_menu_maintenance_standard_description"),
            g_i18n:getText("ads_option_menu_maintenance_minimal_description"),
            g_i18n:getText("ads_option_menu_maintenance_extended_description")
        }
        self.optionOneDisclaimer:setText(optionOneDisclaimers[ADS_Utils.getIndexByValue(AdvancedDamageSystem.MAINTENANCE_TYPES, self.selectedOptionOne)] or "")
        else
        optionOneDisclaimers = {
            g_i18n:getText("ads_option_menu_repair_urgency_medium_description"),
            g_i18n:getText("ads_option_menu_repair_urgency_low_description"),
            g_i18n:getText("ads_option_menu_repair_urgency_high_description")
        }
        self.optionOneDisclaimer:setText(optionOneDisclaimers[ADS_Utils.getIndexByValue(AdvancedDamageSystem.REPAIR_URGENCY, self.selectedOptionOne)] or "")
    end

    local optionTwoDisclaimers = {
        g_i18n:getText("ads_option_menu_part_oem_description"),
        g_i18n:getText("ads_option_menu_part_used_description"),
        g_i18n:getText("ads_option_menu_part_aftermarket_description"),
        g_i18n:getText("ads_option_menu_part_premium_description")
    }
    self.optionTwoDisclaimer:setText(optionTwoDisclaimers[ADS_Utils.getIndexByValue(AdvancedDamageSystem.PART_TYPES, self.selectedOptionTwo)] or "")

    -- option three
    if self.maintenanceType == AdvancedDamageSystem.STATUS.MAINTENANCE then
        self.optionThreeText:setText(g_i18n:getText("ads_option_menu_perform_repair"))
    else
        self.optionThreeText:setText(g_i18n:getText("ads_option_menu_perform_maintenance"))
    end

end


-- ====================================================================
-- CALLBACKS & EVENTS
-- ====================================================================

function ADS_MaintenanceThreeOptionsDialog:onClickOptionOne(index)
    if self.maintenanceType == AdvancedDamageSystem.STATUS.MAINTENANCE then
        self.selectedOptionOne = AdvancedDamageSystem.MAINTENANCE_TYPES[index]
    elseif self.maintenanceType == AdvancedDamageSystem.STATUS.REPAIR then
        self.selectedOptionOne = AdvancedDamageSystem.REPAIR_URGENCY[index]
    end
    self:updateScreen()
end

function ADS_MaintenanceThreeOptionsDialog:onClickOptionTwo(index)
    self.selectedOptionTwo = AdvancedDamageSystem.PART_TYPES[index]
    self:updateScreen()
end

function ADS_MaintenanceThreeOptionsDialog:onClickOptionThree(state, binaryOptionElement)
    self.selectedOptionThree = (state == BinaryOptionElement.STATE_RIGHT)
    self:updateScreen()
end

function ADS_MaintenanceThreeOptionsDialog:onClickStartService()
    local vehicle = self.vehicle
    local workshopType = ADS_WorkshopDialog.INSTANCE.workshopType
    
    local price = vehicle:getServicePrice(self.maintenanceType, self.selectedOptionOne, self.selectedOptionTwo, self.selectedOptionThree, workshopType)
    if g_currentMission:getMoney() < price then
        InfoDialog.show(g_i18n:getText("shop_messageNotEnoughMoneyToBuy"))
        return
    end

    vehicle:initService(self.maintenanceType, workshopType, self.selectedOptionOne, self.selectedOptionTwo, self.selectedOptionThree)
    g_currentMission:addMoney(-1 * price, vehicle:getOwnerFarmId(), MoneyType.VEHICLE_RUNNING_COSTS, true, true)

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
