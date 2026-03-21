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
    dialog.optionOneValues = nil
    dialog.serviceInfoData = {}
    return dialog
end

local function ensureTrailingColon(text)
    local normalized = tostring(text or ""):gsub("%s*:%s*$", "")
    return normalized .. ":"
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
    dialog.optionThree.useYesNoTexts = true
    dialog.optionOne:setState(1)
    dialog.optionTwo:setState(1)
    if dialog.optionThree.setIsChecked ~= nil then
        dialog.optionThree:setIsChecked(false, false, false)
    else
        dialog.optionThree:setState(BinaryOptionElement.STATE_LEFT)
    end

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
    local optionOneValues = {}
    local choosenPartsForQuickFix = {}
    local choosenPartsForRepair = {}

    if self.maintenanceType == AdvancedDamageSystem.STATUS.MAINTENANCE then
        optionOneText = g_i18n:getText("ads_option_menu_option_one_title_maintenance")
        optionOneValues = {
            AdvancedDamageSystem.MAINTENANCE_TYPES.STANDARD,
            AdvancedDamageSystem.MAINTENANCE_TYPES.MINIMAL,
            AdvancedDamageSystem.MAINTENANCE_TYPES.EXTENDED,
            AdvancedDamageSystem.MAINTENANCE_TYPES.PREVENTIVE
        }
    elseif self.maintenanceType == AdvancedDamageSystem.STATUS.REPAIR then
        optionOneText = g_i18n:getText("ads_option_menu_option_one_title_repair")

        local isHaveBreakdownToBeQuickFixed = false
        local isHaveBreakdownToBeReplaced = false
        local activeBreakdowns = self.vehicle:getActiveBreakdowns()
        local breakdownRegistry = ADS_Breakdowns.BreakdownRegistry
        for breakdownId, breakdownData in pairs(activeBreakdowns) do
            if breakdownData.isSelectedForRepair and breakdownData.isVisible then
                if breakdownData.isActive then
                    isHaveBreakdownToBeQuickFixed = true
                    isHaveBreakdownToBeReplaced = true
                    table.insert(choosenPartsForQuickFix, breakdownRegistry[breakdownId].part)
                    table.insert(choosenPartsForRepair, breakdownRegistry[breakdownId].part)
                else 
                    isHaveBreakdownToBeReplaced = true
                    table.insert(choosenPartsForRepair, breakdownRegistry[breakdownId].part)
                end
            end
        end

        if isHaveBreakdownToBeQuickFixed then
            table.insert(optionOneValues, AdvancedDamageSystem.REPAIR_TYPES.LOW)
        end
        if isHaveBreakdownToBeReplaced then
            table.insert(optionOneValues, AdvancedDamageSystem.REPAIR_TYPES.MEDIUM)
        end

    else
        optionOneText = g_i18n:getText("ads_option_menu_option_one_title_overhaul")
        optionOneValues = {
            AdvancedDamageSystem.OVERHAUL_TYPES.STANDARD,
            AdvancedDamageSystem.OVERHAUL_TYPES.PARTIAL,
            AdvancedDamageSystem.OVERHAUL_TYPES.FULL
        }
    end

    for _, optionValue in ipairs(optionOneValues) do
        table.insert(optionOneOptions, g_i18n:getText(optionValue))
    end

    self.optionOneValues = optionOneValues
    if self.optionOneValues[1] == nil then
        self.selectedOptionOne = nil
    elseif ADS_Utils.getIndexByValue(self.optionOneValues, self.selectedOptionOne) == nil then
        self.selectedOptionOne = self.optionOneValues[1]
        if self.optionOne.setState ~= nil then
            self.optionOne:setState(1)
        end
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
            if self.optionOneValues ~= nil and self.optionOneValues[optionOneState] ~= nil then
                self.selectedOptionOne = self.optionOneValues[optionOneState]
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
    local priceValue = ""

    if isWarrantyRepair then
        priceValue = g_i18n:getText("ads_option_menu_warranty_repair_text")
    else
        priceValue = g_i18n:formatMoney(servicePrice)
    end
    local durationValue = ADS_Utils.formatDuration(self.vehicle:getServiceDuration(self.maintenanceType, self.selectedOptionOne, effectiveOptionTwo, self.selectedOptionThree, workshopType))
    local finishTimeValue = ADS_Utils.formatFinishTime(self.vehicle:getServiceFinishTime(self.maintenanceType, self.selectedOptionOne, effectiveOptionTwo, self.selectedOptionThree, workshopType))

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

    if self.maintenanceType == AdvancedDamageSystem.STATUS.MAINTENANCE then
        optionOneDisclaimers = {
            g_i18n:getText("ads_option_menu_maintenance_standard_description"),
            g_i18n:getText("ads_option_menu_maintenance_minimal_description"),
            g_i18n:getText("ads_option_menu_maintenance_extended_description"),
            g_i18n:getText("ads_option_menu_maintenance_preventive_description")
        }
        self.optionOneDisclaimer:setText(optionOneDisclaimers[ADS_Utils.getIndexByValue(AdvancedDamageSystem.MAINTENANCE_TYPES, self.selectedOptionOne)] or "")
        self.choosenPartsText:setVisible(false)
    elseif self.maintenanceType == AdvancedDamageSystem.STATUS.REPAIR then
        local choosenPartsText = g_i18n:getText("ads_option_menu_choosen_parts_text")
        local choosenPartsLabels = {}
        if self.selectedOptionOne == AdvancedDamageSystem.REPAIR_TYPES.LOW then
            for _, part in ipairs(choosenPartsForQuickFix) do
                table.insert(choosenPartsLabels, g_i18n:getText(part))
            end
            self.optionOneDisclaimer:setText(g_i18n:getText("ads_option_menu_repair_type_fix_description"))
        else
            for _, part in ipairs(choosenPartsForRepair) do
                table.insert(choosenPartsLabels, g_i18n:getText(part))
            end
            self.optionOneDisclaimer:setText(g_i18n:getText("ads_option_menu_repair_type_replacement_description"))
        end
        if #choosenPartsLabels > 0 then
            choosenPartsText = choosenPartsText .. " " .. table.concat(choosenPartsLabels, ", ")
        end
        self.choosenPartsText:setTextColor(0.88, 0.45, 0.10, 1)
        self.choosenPartsText:setText(choosenPartsText)
        self.choosenPartsText:setVisible(true)
    else
        optionOneDisclaimers = {
            g_i18n:getText("ads_option_menu_overhaul_standard_description"),
            g_i18n:getText("ads_option_menu_overhaul_partial_description"),
            g_i18n:getText("ads_option_menu_overhaul_full_description")
        }
        self.optionOneDisclaimer:setText(optionOneDisclaimers[ADS_Utils.getIndexByValue(AdvancedDamageSystem.OVERHAUL_TYPES, self.selectedOptionOne)] or "")
        self.choosenPartsText:setVisible(false)
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
    if self.optionOneValues ~= nil and self.optionOneValues[index] ~= nil then
        self.selectedOptionOne = self.optionOneValues[index]
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

function ADS_MaintenanceThreeOptionsDialog:getNumberOfItemsInSection(list, section)
    if list == self.serviceInfoTable then
        return #self.serviceInfoData
    end

    return 0
end

function ADS_MaintenanceThreeOptionsDialog:populateCellForItemInSection(list, section, index, cell)
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

function ADS_MaintenanceThreeOptionsDialog:onOpen(superFunc)
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

function ADS_MaintenanceThreeOptionsDialog:onClose(superFunc)
    self.vehicle = nil
    g_messageCenter:unsubscribeAll(self)
end
