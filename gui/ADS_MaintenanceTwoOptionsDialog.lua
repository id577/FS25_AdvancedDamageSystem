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
    dialog.serviceInfoData = {}
    return dialog
end

local function ensureTrailingColon(text)
    local normalized = tostring(text or ""):gsub("%s*:%s*$", "")
    return normalized .. ":"
end

local function getMobileWorkshopAvailability(dialog)
    local vehicle = dialog ~= nil and dialog.vehicle or nil
    local spec = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    local workshopType = ADS_WorkshopDialog.INSTANCE ~= nil and ADS_WorkshopDialog.INSTANCE.workshopType or (spec ~= nil and spec.workshopType or nil)

    if vehicle == nil or spec == nil or workshopType ~= AdvancedDamageSystem.WORKSHOP.MOBILE then
        return true
    end

    if not ADS_Config.WORKSHOP.MOBILE_WORKSHOP_RESTRICTIONS_ENABLED then
        return true
    end

    local serviceKey = ADS_Utils.getNameByValue(AdvancedDamageSystem.STATUS, dialog.maintenanceType)
    local optionKey

    if dialog.maintenanceType == AdvancedDamageSystem.STATUS.INSPECTION then
        optionKey = ADS_Utils.getNameByValue(AdvancedDamageSystem.INSPECTION_TYPES, dialog.selectedOptionOne)
    elseif dialog.maintenanceType == AdvancedDamageSystem.STATUS.OVERHAUL then
        optionKey = ADS_Utils.getNameByValue(AdvancedDamageSystem.OVERHAUL_TYPES, dialog.selectedOptionOne)
    end

    local limits = ADS_Config.WORKSHOP.MOBILE_WORKSHOP_SERVICES_BY_MAINTAINABILITY
    local requiredMaintainability = limits ~= nil and serviceKey ~= nil and optionKey ~= nil and limits[serviceKey] ~= nil and limits[serviceKey][optionKey] or 0
    local currentMaintainability = spec.maintainability or 0

    return currentMaintainability >= requiredMaintainability
end

local function getSelectedWorkshopAvailability(dialog)
    local vehicle = dialog ~= nil and dialog.vehicle or nil
    local spec = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    local workshopType = ADS_WorkshopDialog.INSTANCE ~= nil and ADS_WorkshopDialog.INSTANCE.workshopType or (spec ~= nil and spec.workshopType or nil)

    if ADS_Main ~= nil and ADS_Main.isWorkshopTypeOpen ~= nil then
        return ADS_Main:isWorkshopTypeOpen(workshopType)
    end

    return true
end

local function getSelectedProcedureDisplayName(dialog)
    if dialog == nil then
        return ""
    end

    local optionOneText = dialog.selectedOptionOne ~= nil and g_i18n:getText(dialog.selectedOptionOne) or ""
    local typeText = dialog.maintenanceType ~= nil and g_i18n:getText(dialog.maintenanceType) or ""

    if optionOneText == "" then
        return typeText
    end

    if typeText == "" then
        return optionOneText
    end

    return string.format("%s %s", optionOneText, typeText)
end

function ADS_MaintenanceTwoOptionsDialog.show(vehicle, maintenanceType)
    if ADS_MaintenanceTwoOptionsDialog.INSTANCE == nil then ADS_MaintenanceTwoOptionsDialog.register() end
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil or maintenanceType == nil then return end
    
    local dialog = ADS_MaintenanceTwoOptionsDialog.INSTANCE
    dialog.vehicle = vehicle
    dialog.maintenanceType = maintenanceType

    dialog.optionThree.useYesNoTexts = true
    dialog.optionOne:setState(1)
    if dialog.optionThree.setIsChecked ~= nil then
        dialog.optionThree:setIsChecked(false, false, false)
    else
        dialog.optionThree:setState(BinaryOptionElement.STATE_LEFT)
    end

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

    if self.optionOne ~= nil and self.optionOne.getState ~= nil then
        local optionOneState = tonumber(self.optionOne:getState())
        if optionOneState ~= nil then
            if self.maintenanceType == AdvancedDamageSystem.STATUS.INSPECTION then
                if self.inspectionOptionValues ~= nil and self.inspectionOptionValues[optionOneState] ~= nil then
                    self.selectedOptionOne = self.inspectionOptionValues[optionOneState]
                end
            elseif self.maintenanceType == AdvancedDamageSystem.STATUS.OVERHAUL then
                if AdvancedDamageSystem.OVERHAUL_TYPES[optionOneState] ~= nil then
                    self.selectedOptionOne = AdvancedDamageSystem.OVERHAUL_TYPES[optionOneState]
                end
            end
        end
    end

    local isAllowedInMobileWorkshop = getMobileWorkshopAvailability(self)
    local isWorkshopOpen = getSelectedWorkshopAvailability(self)

    -- price, duration, finishtime
    local workshopType = ADS_WorkshopDialog.INSTANCE ~= nil and ADS_WorkshopDialog.INSTANCE.workshopType or spec.workshopType
    local priceValue = g_i18n:formatMoney(self.vehicle:getServicePrice(self.maintenanceType, self.selectedOptionOne, self.selectedOptionTwo, self.selectedOptionThree, workshopType))
    local durationValue = ""
    if ADS_Config.MAINTENANCE.INSTANT_INSPECTION and  self.maintenanceType == AdvancedDamageSystem.STATUS.INSPECTION then
        durationValue = g_i18n:getText("ads_option_menu_duration_instant")
    else
        durationValue = ADS_Utils.formatDuration(self.vehicle:getServiceDuration(self.maintenanceType, self.selectedOptionOne, self.selectedOptionTwo, self.selectedOptionThree, workshopType))
    end
    local finishTimeValue = ADS_Utils.formatFinishTime(self.vehicle:getServiceFinishTime(self.maintenanceType, self.selectedOptionOne, self.selectedOptionTwo, self.selectedOptionThree, workshopType))

    self.serviceInfoData = {
        {title = ensureTrailingColon(g_i18n:getText("ads_option_menu_price_text")), value = priceValue},
        {title = ensureTrailingColon(g_i18n:getText("ads_option_menu_duration_text")), value = durationValue},
        {title = ensureTrailingColon(g_i18n:getText("ads_option_menu_finish_time_text")), value = finishTimeValue}
    }

    self.serviceInfoTable:setDataSource(self)
    self.serviceInfoTable:setDelegate(self)
    self.serviceInfoTable:reloadData()


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

    if not isAllowedInMobileWorkshop then
        local procedureName = getSelectedProcedureDisplayName(self)
        local vehicleName = self.vehicle.getFullName ~= nil and self.vehicle:getFullName() or g_i18n:getText("ui_vehicle")
        self.optionOneDisclaimer:setText(string.format(g_i18n:getText("ads_mobile_workshop_low_maintainability"), procedureName, vehicleName))
        self.optionOneDisclaimer:setTextColor(0.88, 0.18, 0.18, 1)
    else
        self.optionOneDisclaimer:setTextColor(1, 1, 1, 1)
    end

    

    -- option three
    if self.maintenanceType == AdvancedDamageSystem.STATUS.INSPECTION then
        self.optionThreeText:setText(g_i18n:getText("ads_option_menu_perform_repair"))
        self.optionThreeDisclaimer:setText(g_i18n:getText("ads_option_menu_option_three_disclaimer_repair_after_detection"))
    else
        self.optionThreeText:setText(g_i18n:getText("ads_option_menu_perform_renew_paint"))
        self.optionThreeDisclaimer:setText(g_i18n:getText("ads_option_menu_option_three_disclaimer_overhaul_repaint"))
    end

    if self.startServiceButton ~= nil then
        self.startServiceButton:setDisabled(not isAllowedInMobileWorkshop or not isWorkshopOpen)
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
    if not getMobileWorkshopAvailability(self) or not getSelectedWorkshopAvailability(self) then
        return
    end

    local vehicle = self.vehicle
    local workshopType = ADS_WorkshopDialog.INSTANCE.workshopType
    local spec = vehicle.spec_AdvancedDamageSystem
    
    local price = vehicle:getServicePrice(self.maintenanceType, self.selectedOptionOne, self.selectedOptionTwo, self.selectedOptionThree, workshopType)
    
    if g_currentMission:getMoney() < price then
        InfoDialog.show(g_i18n:getText("shop_messageNotEnoughMoneyToBuy"))
        return
    end
    
    if g_server ~= nil then
        -- Server: execute locally and broadcast
        spec.serviceOptionOne = self.selectedOptionOne
        spec.serviceOptionTwo = self.selectedOptionTwo
        spec.serviceOptionThree = self.selectedOptionThree
        vehicle:initService(self.maintenanceType, workshopType, self.selectedOptionOne, self.selectedOptionTwo, self.selectedOptionThree)
        g_currentMission:addMoney(-1 * price, vehicle:getOwnerFarmId(), MoneyType.VEHICLE_RUNNING_COSTS, true, true)
        ADS_VehicleChangeStatusEvent.send(vehicle)
    else
        -- Client: only send request to server
        ADS_ServiceRequestEvent.send(vehicle, self.maintenanceType, workshopType, self.selectedOptionOne, self.selectedOptionTwo, self.selectedOptionThree, price)
    end
    
    self:close()
end

function ADS_MaintenanceTwoOptionsDialog:onClickBack()
    self:close()
end

function ADS_MaintenanceTwoOptionsDialog:getNumberOfItemsInSection(list, section)
    if list == self.serviceInfoTable then
        return #self.serviceInfoData
    end

    return 0
end

function ADS_MaintenanceTwoOptionsDialog:populateCellForItemInSection(list, section, index, cell)
    if list ~= self.serviceInfoTable then
        return
    end

    local data = self.serviceInfoData[index]
    if data == nil then
        return
    end

    local titleElement = cell:getAttribute("serviceInfoTitle")
    local valueElement = cell:getAttribute("serviceInfoValue")
    titleElement:setText(data.title or "")
    valueElement:setText(data.value or "")
    titleElement:setTextColor(1, 1, 1, 1)
    valueElement:setTextColor(1, 1, 1, 1)
end

function ADS_MaintenanceTwoOptionsDialog:onOpen(superFunc)
    if self.optionThree ~= nil then
        self.optionThree.useYesNoTexts = true
        if self.optionThree.setIsChecked ~= nil then
            self.optionThree:setIsChecked(self.selectedOptionThree == true, false, false)
        elseif self.optionThree.getState ~= nil then
            self.optionThree:setState(self.optionThree:getState())
        end
    end

    g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.updateScreen, self)
end

function ADS_MaintenanceTwoOptionsDialog:onClose(superFunc)
    self.vehicle = nil
    g_messageCenter:unsubscribeAll(self)
end
