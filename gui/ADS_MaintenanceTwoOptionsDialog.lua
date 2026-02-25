ADS_MaintenanceTwoOptionsDialog = {}
ADS_MaintenanceTwoOptionsDialog.INSTANCE = nil

local ADS_MaintenanceTwoOptionsDialog_mt = Class(ADS_MaintenanceTwoOptionsDialog, MessageDialog)
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

function ADS_MaintenanceTwoOptionsDialog.register()
    local dialog = ADS_MaintenanceTwoOptionsDialog.new()
    g_gui:loadGui(modDirectory .. "gui/ADS_MaintenanceTwoOptionsDialog.xml", "ADS_MaintenanceTwoOptionsDialog", dialog)
    ADS_MaintenanceTwoOptionsDialog.INSTANCE = dialog
end

function ADS_MaintenanceTwoOptionsDialog.new(target, customMt)
    local dialog = MessageDialog.new(target, customMt or ADS_MaintenanceTwoOptionsDialog_mt)
    dialog.vehicle = nil
    dialog.inspectionOptionValues = nil
    return dialog
end

function ADS_MaintenanceTwoOptionsDialog.show(vehicle, maintenanceType)
    if ADS_MaintenanceTwoOptionsDialog.INSTANCE == nil then ADS_MaintenanceTwoOptionsDialog.register() end
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil or maintenanceType == nil then return end
    
    local dialog = ADS_MaintenanceTwoOptionsDialog.INSTANCE
    dialog.vehicle = vehicle
    dialog.maintenanceType = maintenanceType

    dialog.optionThree.useYesNoTexts = true
    dialog.optionOne:setState(1)
    dialog.optionThree:setState(BinaryOptionElement.STATE_LEFT)

    if dialog.maintenanceType == AdvancedDamageSystem.STATUS.INSPECTION then
        dialog.selectedOptionOne = AdvancedDamageSystem.INSPECTION_TYPES[1]
    elseif dialog.maintenanceType == AdvancedDamageSystem.STATUS.OVERHAUL then
        dialog.selectedOptionOne = AdvancedDamageSystem.OVERHAUL_TYPES[1]
    end
    dialog.selectedOptionThree = false
    
    dialog:updateScreen()
    g_gui:showDialog("ADS_MaintenanceTwoOptionsDialog")
end

function ADS_MaintenanceTwoOptionsDialog:updateScreen()
    if self.vehicle == nil then return end
    log_dbg("Updating log Screen...")

    local spec = self.vehicle.spec_AdvancedDamageSystem

    -- title
    self.dialogTitleElement:setText(g_i18n:getText(self.maintenanceType))

    -- option one
    local optionOneText = ""
    local optionOneOptions = {}

    if self.maintenanceType == AdvancedDamageSystem.STATUS.INSPECTION then
        optionOneText = g_i18n:getText("ads_option_menu_option_one_title_inspection")
        local instantInspection = ADS_Config.MAINTENANCE.INSTANT_INSPECTION
        if instantInspection then
            self.inspectionOptionValues = {
                AdvancedDamageSystem.INSPECTION_TYPES.STANDARD,
                AdvancedDamageSystem.INSPECTION_TYPES.COMPLETE
            }
            if self.selectedOptionOne == AdvancedDamageSystem.INSPECTION_TYPES.VISUAL then
                self.selectedOptionOne = AdvancedDamageSystem.INSPECTION_TYPES.STANDARD
            end
            optionOneOptions = {
                g_i18n:getText(AdvancedDamageSystem.INSPECTION_TYPES.STANDARD),
                g_i18n:getText(AdvancedDamageSystem.INSPECTION_TYPES.COMPLETE)
            }
        else
            self.inspectionOptionValues = {
                AdvancedDamageSystem.INSPECTION_TYPES.STANDARD,
                AdvancedDamageSystem.INSPECTION_TYPES.VISUAL,
                AdvancedDamageSystem.INSPECTION_TYPES.COMPLETE
            }
            optionOneOptions = {
                g_i18n:getText(AdvancedDamageSystem.INSPECTION_TYPES.STANDARD),
                g_i18n:getText(AdvancedDamageSystem.INSPECTION_TYPES.VISUAL),
                g_i18n:getText(AdvancedDamageSystem.INSPECTION_TYPES.COMPLETE)
            }
        end
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

    -- price, duration, finishtime
    local workshopType = ADS_WorkshopDialog.INSTANCE ~= nil and ADS_WorkshopDialog.INSTANCE.workshopType or spec.workshopType
    self.maintenancePrice:setText(g_i18n:getText("ads_option_menu_price_text") .. g_i18n:formatMoney(self.vehicle:getServicePrice(self.maintenanceType, self.selectedOptionOne, self.selectedOptionTwo, self.selectedOptionThree, workshopType)))
    if ADS_Config.MAINTENANCE.INSTANT_INSPECTION and  self.maintenanceType == AdvancedDamageSystem.STATUS.INSPECTION then
        self.maintenanceDuration:setText(g_i18n:getText("ads_option_menu_duration_text") .. g_i18n:getText("ads_option_menu_duration_instant"))
    else
        self.maintenanceDuration:setText(g_i18n:getText("ads_option_menu_duration_text") .. ADS_Utils.formatDuration(self.vehicle:getServiceDuration(self.maintenanceType, self.selectedOptionOne, self.selectedOptionTwo, self.selectedOptionThree, workshopType)))
    end
    self.maintenanceFinishTime:setText(g_i18n:getText("ads_option_menu_finish_time_text") .. ADS_Utils.formatFinishTime(self.vehicle:getServiceFinishTime(self.maintenanceType, self.selectedOptionOne, self.selectedOptionTwo, self.selectedOptionThree, workshopType)))


    -- disclaimers
    local optionOneDisclaimers = {}

    if self.maintenanceType == AdvancedDamageSystem.STATUS.INSPECTION then
        local disclaimerByType = {
            [AdvancedDamageSystem.INSPECTION_TYPES.STANDARD] = g_i18n:getText("ads_option_menu_inspection_standard_description"),
            [AdvancedDamageSystem.INSPECTION_TYPES.VISUAL] = g_i18n:getText("ads_option_menu_inspection_visual_description"),
            [AdvancedDamageSystem.INSPECTION_TYPES.COMPLETE] = g_i18n:getText("ads_option_menu_inspection_complete_description")
        }
        self.optionOneDisclaimer:setText(disclaimerByType[self.selectedOptionOne] or "")
        else
        optionOneDisclaimers = {
            g_i18n:getText("ads_option_menu_overhaul_standard_description"),
            g_i18n:getText("ads_option_menu_overhaul_partial_description"),
            g_i18n:getText("ads_option_menu_overhaul_full_description")
        }
        self.optionOneDisclaimer:setText(optionOneDisclaimers[ADS_Utils.getIndexByValue(AdvancedDamageSystem.OVERHAUL_TYPES, self.selectedOptionOne)] or "")
    end

    

    -- option three
    if self.maintenanceType == AdvancedDamageSystem.STATUS.INSPECTION then
        self.optionThreeText:setText(g_i18n:getText("ads_option_menu_perform_repair"))
    else
        self.optionThreeText:setText(g_i18n:getText("ads_option_menu_perform_renew_paint"))
    end
end

-- ====================================================================
-- CALLBACKS & EVENTS
-- ====================================================================

function ADS_MaintenanceTwoOptionsDialog:onClickOptionOne(index)
    if self.maintenanceType == AdvancedDamageSystem.STATUS.INSPECTION then
        if self.inspectionOptionValues ~= nil and self.inspectionOptionValues[index] ~= nil then
            self.selectedOptionOne = self.inspectionOptionValues[index]
        else
            self.selectedOptionOne = AdvancedDamageSystem.INSPECTION_TYPES.STANDARD
        end
    elseif self.maintenanceType == AdvancedDamageSystem.STATUS.OVERHAUL then
        self.selectedOptionOne = AdvancedDamageSystem.OVERHAUL_TYPES[index]
    end
    self:updateScreen()
end

function ADS_MaintenanceTwoOptionsDialog:onClickOptionThree(state, binaryOptionElement)
    self.selectedOptionThree = (state == BinaryOptionElement.STATE_RIGHT)
    self:updateScreen()
end

function ADS_MaintenanceTwoOptionsDialog:onClickStartService()
    local vehicle = self.vehicle
    local workshopType = ADS_WorkshopDialog.INSTANCE.workshopType
    local spec = vehicle.spec_AdvancedDamageSystem
    
    local price = vehicle:getServicePrice(self.maintenanceType, self.selectedOptionOne, self.selectedOptionTwo, self.selectedOptionThree, workshopType)
    
    if g_currentMission:getMoney() < price then
        InfoDialog.show(g_i18n:getText("shop_messageNotEnoughMoneyToBuy"))
        return
    end
    
    spec.serviceOptionOne = self.selectedOptionOne
    spec.serviceOptionTwo = self.selectedOptionTwo
    spec.serviceOptionThree = self.selectedOptionThree

    vehicle:initService(self.maintenanceType, workshopType, self.selectedOptionOne, self.selectedOptionTwo, self.selectedOptionThree)
    g_currentMission:addMoney(-1 * price, vehicle:getOwnerFarmId(), MoneyType.VEHICLE_RUNNING_COSTS, true, true)
    
    self:close()
end

function ADS_MaintenanceTwoOptionsDialog:onClickBack()
    self:close()
end

function ADS_MaintenanceTwoOptionsDialog:onOpen(superFunc)
    g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.updateScreen, self)
end

function ADS_MaintenanceTwoOptionsDialog:onClose(superFunc)
    self.vehicle = nil
    g_messageCenter:unsubscribeAll(self)
end
