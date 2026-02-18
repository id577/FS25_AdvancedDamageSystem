ADS_WorkshopDialog = {}
ADS_WorkshopDialog.INSTANCE = nil

local ADS_WorkshopDialog_mt = Class(ADS_WorkshopDialog, MessageDialog)
local modDirectory = g_currentModDirectory

local function log_dbg(...)
    if ADS_Main.DEBUG then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i])
        end
        print("[ADS_WORKSHOP_DIALOG] " .. table.concat(args, " "))
    end
end


function ADS_WorkshopDialog.register()
    log_dbg("Registering ADS_WorkshopDialog...")
    local dialog = ADS_WorkshopDialog.new()
    g_gui:loadGui(modDirectory .. "gui/ADS_WorkshopDialog.xml", "ADS_WorkshopDialog", dialog)
    ADS_WorkshopDialog.INSTANCE = dialog
end

function ADS_WorkshopDialog.new(target, customMt)
    local dialog = MessageDialog.new(target, customMt or ADS_WorkshopDialog_mt)
    dialog.vehicle = nil
    return dialog
end


function ADS_WorkshopDialog.show(vehicle)
    if ADS_WorkshopDialog.INSTANCE.updateScreen == nil then ADS_WorkshopDialog.register() end
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        log_dbg("Tried to show ADS_WorkshopDialog without a valid vehicle.")
        return
    end
    local dialog = ADS_WorkshopDialog.INSTANCE
    dialog.vehicle = vehicle
    dialog.activeBreakdowns = vehicle:getActiveBreakdowns()
    dialog.visibleBreakdowns = {}
    dialog.breakdonRegistry = ADS_Breakdowns.BreakdownRegistry
    dialog.workshopType = AdvancedDamageSystem.WORKSHOP.DEALER

    if g_workshopScreen.isMobileWorkshop then  dialog.workshopType = AdvancedDamageSystem.WORKSHOP.MOBILE end
    if g_workshopScreen.isOwnWorkshop then  dialog.workshopType = AdvancedDamageSystem.WORKSHOP.OWN end

    dialog:updateScreen()
    g_gui:showDialog("ADS_WorkshopDialog")
end

function ADS_WorkshopDialog:updateScreen()
    if self.vehicle == nil then return end
    log_dbg("Updating ADS_WorkshopDialog screen...")
    local spec = self.vehicle.spec_AdvancedDamageSystem
    local vehicle = self.vehicle
    local STATUS = AdvancedDamageSystem.STATUS

    -- ====================================================================
    -- 1: Vehicle Info Panel
    -- ====================================================================

    self.balanceElement:setText(g_i18n:formatMoney(g_currentMission:getMoney() , 2, true, true))
    self.vehicleImage:setImageFilename(vehicle:getImageFilename())
    self.vehicleNameValue:setText(self.vehicle:getFullName())
    self.valueValue:setText(g_i18n:formatMoney(vehicle:getSellPrice() * EconomyManager.DIRECT_SELL_MULTIPLIER))
    
    self.ageValue:setText(string.format("%d %s", vehicle.age, g_i18n:getText("ads_ws_age_unit")))
    self.operatingHoursValue:setText(string.format("%s %s", vehicle:getFormattedOperatingTime(), g_i18n:getText("ads_ws_hours_unit")))
    
    self.lastServiceValue:setText(self.vehicle:getFormattedLastMaintenanceText())

    local monthsSinceInspectionText = self.vehicle:getFormattedLastInspectionText()
    local serviceText = g_i18n:getText(spec.lastInspectedServiceState)
    local conditionText = g_i18n:getText(spec.lastInspectedConditionState)

    self.serviceValue:setText(serviceText)
    self.serviceValue:setTextColor(AdvancedDamageSystem.getTextColour(spec.lastInspectedServiceState))
    self.condtionValue:setText(conditionText)
    self.condtionValue:setTextColor(AdvancedDamageSystem.getTextColour(spec.lastInspectedConditionState))
    self.serviceLastInspectionDeltaValue:setTextColor(0.5, 0.5, 0.5, 1.0)
    self.condtionLastInspectionDelataValue:setTextColor(0.5, 0.5, 0.5, 1.0)
    self.serviceLastInspectionDeltaValue:setText(monthsSinceInspectionText)
    self.condtionLastInspectionDelataValue:setText(monthsSinceInspectionText)

    self.relAndMainValue:setText(self.vehicle:getFormattedServiceIntervalText())

    local motor = self.vehicle:getMotor()
    local defaultPower = motor.peakMotorPower * 1.36 or 0
    local powerText = string.format("%.1f%% (%.0f hp / %.0f hp)", spec.lastInspectedPower * 100, defaultPower * spec.lastInspectedPower, defaultPower)
    local brakeText = string.format("%.1f%%", spec.lastInspectedBrake * 100)
    local yieldReductionText = string.format("%.1f%%", spec.lastInspectedYieldReduction * 100)

    self.powerValue:setTextColor(1.0, 1.0, 1.0, 1.0)
    self.yieldReductionValue:setTextColor(1.0, 1.0, 1.0, 1.0)
    self.brakeValue:setTextColor(1.0, 1.0, 1.0, 1.0)
    self.powerValue:setText(powerText)
    self.brakeValue:setText(brakeText)

    if  (self.vehicle.type.name == 'combineDrivable' or self.vehicle.type.name == 'combineCutter') then
        self.yieldReductionValue:setText(yieldReductionText)
    else
        self.yieldReductionValue:setText('-')
    end

    -- ====================================================================
    -- 2: Breakdowns Table
    -- ====================================================================

    self.visibleBreakdowns = {}
    for id, breakdown in pairs(self.activeBreakdowns) do
        if breakdown.isVisible then
            table.insert(self.visibleBreakdowns, id)
        end
    end

    self.breakdownTable:setDataSource(self)
    self.breakdownTable:setDelegate(self)
    self.breakdownTable:reloadData()

    -- ====================================================================
    -- 3: Status Text
    -- ====================================================================
    
    local buttonsDisabled = false
    local statusText = ""
    local statusColor = {1, 1, 1, 1}
    
    self.maintanceInProgressSpinner:setVisible(false)
    if g_workshopScreen.isDealer or g_workshopScreen.isOwnWorkshop then
        if not ADS_Main.isWorkshopOpen then
            buttonsDisabled = true
            statusText = g_i18n:getText("ads_ws_status_closed")
            statusColor = {0.6, 0.6, 0.6, 1}
        else
            statusText = g_i18n:getText("ads_ws_status_open")
            buttonsDisabled = false
        end
    end

    if spec.currentState ~= STATUS.READY then
        self.maintanceInProgressSpinner:setVisible(true)
        buttonsDisabled = true
        local finishTimeText = self.vehicle:getFormattedMaintenanceFinishTimeText()
        local localizedStatus = g_i18n:getText(spec.currentState)
        statusText = string.format(g_i18n:getText("ads_ws_status_in_progress_format"), localizedStatus, finishTimeText)
        if spec.currentState ~= STATUS.REPAIR then
            local inspectingText = g_i18n:getText("ads_ws_inspecting_status")
            self.serviceValue:setText(inspectingText)
            self.serviceValue:setTextColor(0.5, 0.5, 0.5, 1.0)
            self.condtionValue:setText(inspectingText)
            self.condtionValue:setTextColor(0.5, 0.5, 0.5, 1.0)
            self.powerValue:setText(inspectingText)
            self.powerValue:setTextColor(0.5, 0.5, 0.5, 1.0)
            self.brakeValue:setText(inspectingText)
            self.brakeValue:setTextColor(0.5, 0.5, 0.5, 1.0)
            self.yieldReductionValue:setText(inspectingText)
            self.yieldReductionValue:setTextColor(0.5, 0.5, 0.5, 1.0)
        end
    end

    self.statusText:setText(statusText)
    self.statusText:setTextColor(statusColor[1], statusColor[2], statusColor[3], statusColor[4])

    -- ====================================================================
    -- 4: Action Buttons
    -- ====================================================================

    if g_workshopScreen.isDealer or g_workshopScreen.isOwnWorkshop then
        self.inscpectionButton.disabled = buttonsDisabled 
        self.maintenanceButton.disabled = buttonsDisabled
        self.repairButton.disabled = buttonsDisabled
        self.overhaulButton.disabled = buttonsDisabled or self.vehicle:getConditionLevel() >= 0.5
    else
        self.inscpectionButton.disabled = false or spec.currentState ~= STATUS.READY
        self.maintenanceButton.disabled = not (g_workshopScreen.isMobileWorkshop and spec.maintainability >= 1.1) or spec.currentState ~= STATUS.READY
        self.repairButton.disabled = not (g_workshopScreen.isMobileWorkshop and spec.maintainability >= 1.2) or spec.currentState ~= STATUS.READY
        self.overhaulButton.disabled = true
    end

    local inspectionPrice = self.vehicle:getInspectionPrice() * (g_workshopScreen.isOwnWorkshop and 0.8 or 1)
    local maintenancePrice = self.vehicle:getMaintenancePrice() * (g_workshopScreen.isOwnWorkshop and 0.8 or 1)
    local repairPrice = self.vehicle:getADSRepairPrice() * (g_workshopScreen.isOwnWorkshop and 0.8 or 1)
    local overhaulPrice = self.vehicle:getOverhaulPrice() * (g_workshopScreen.isOwnWorkshop and 0.8 or 1)

    if repairPrice == 0 then
        self.repairButton.disabled = true
    end
    
    local buttonFormat = g_i18n:getText("ads_ws_button_price_format")
    self.inscpectionButton:setText(string.format(buttonFormat, g_i18n:getText("ads_ws_action_inspection"), g_i18n:formatMoney(inspectionPrice)))
    self.maintenanceButton:setText(string.format(buttonFormat, g_i18n:getText("ads_ws_action_maintenance"), g_i18n:formatMoney(maintenancePrice)))
    self.repairButton:setText(string.format(buttonFormat, g_i18n:getText("ads_ws_action_repair"), g_i18n:formatMoney(repairPrice)))
    self.overhaulButton:setText(string.format(buttonFormat, g_i18n:getText("ads_ws_action_overhaul"), g_i18n:formatMoney(overhaulPrice)))

    -- ====================================================================
    -- 5: Table Visibility
    -- ====================================================================
    
    local isListEmpty = #self.visibleBreakdowns == 0
    self.breakdownTable:setVisible(not isListEmpty)
    self.tableSlider:setVisible(not isListEmpty)
    if self.vehicle:getCurrentStatus() == STATUS.READY then
        self.emptyTableText:setVisible(isListEmpty)
        self.emptyTableText:setText(g_i18n:getText("ads_ws_info_no_breakdowns"))
    else
        self.emptyTableText:setVisible(true)
        self.breakdownTable:setVisible(false)
        self.tableSlider:setVisible(false)
        self.emptyTableText:setText(g_i18n:getText(self.vehicle:getCurrentStatus()) .. "...")
    end
    --self.statusText:setPosition(0, 0.015)
end

function ADS_WorkshopDialog:getNumberOfItemsInSection(list, section)
    return #self.visibleBreakdowns
end


function ADS_WorkshopDialog:populateCellForItemInSection(list, section, index, cell)
    local breadownId = self.visibleBreakdowns[index]
    local data = self.activeBreakdowns[breadownId]
    if data == nil then return end

    local part_key = self.breakdonRegistry[breadownId].part
    local stage_key = self.breakdonRegistry[breadownId].stages[data.stage].severity
    local description_key = self.breakdonRegistry[breadownId].stages[data.stage].description
    local price = self.vehicle:getADSRepairPrice(breadownId)
    local selected = data.isSelectedForRepair

    if data.stage == 1 then
        cell:getAttribute("ads_tableBreakdownStage"):setTextColor(1, 1, 1, 1)
    elseif data.stage == 2 then
        cell:getAttribute("ads_tableBreakdownStage"):setTextColor( 0.5, 0.5, 0, 1)
    elseif data.stage == 3 then
        cell:getAttribute("ads_tableBreakdownStage"):setTextColor( 0.7, 0.3, 0, 1)
    else
        cell:getAttribute("ads_tableBreakdownStage"):setTextColor(0.88, 0.12, 0, 1)
    end

    cell:getAttribute("ads_tableBreakdownName"):setText(g_i18n:getText(part_key))
    cell:getAttribute("ads_tableBreakdownDisc"):setText(g_i18n:getText(description_key))
    cell:getAttribute("ads_tableBreakdownStage"):setText(g_i18n:getText(stage_key))
    cell:getAttribute("ads_tableBreakdownPrice"):setText(g_i18n:formatMoney(price))
    
    
    local selectedText = g_i18n:getText("ads_ws_option_no")
    if selected then 
        selectedText = g_i18n:getText("ads_ws_option_yes")
        cell:getAttribute("ads_tableBreakdownName"):setDisabled(false)
        cell:getAttribute("ads_tableBreakdownDisc"):setDisabled(false)
        cell:getAttribute("ads_tableBreakdownStage"):setDisabled(false)
        cell:getAttribute("ads_tableBreakdownPrice"):setDisabled(false)
        cell:getAttribute("ads_tableBreakdownSelect"):setTextColor(0.3, 0.7, 0.0, 1.0)
    else
        cell:getAttribute("ads_tableBreakdownName"):setDisabled(true)
        cell:getAttribute("ads_tableBreakdownDisc"):setDisabled(true)
        cell:getAttribute("ads_tableBreakdownStage"):setDisabled(true)
        cell:getAttribute("ads_tableBreakdownPrice"):setDisabled(true)
        cell:getAttribute("ads_tableBreakdownSelect"):setTextColor(0.2, 0.2, 0.2, 1)
    end
    cell:getAttribute("ads_tableBreakdownSelect"):setText(selectedText)
end


function ADS_WorkshopDialog:onRowClick(button)
    if self.vehicle:getCurrentStatus() ~= AdvancedDamageSystem.STATUS.READY then return end
    if button == nil or self.visibleBreakdowns[button.parent.indexInSection] == nil then return end
    
    local id = self.visibleBreakdowns[button.parent.indexInSection]
    local breakdown = self.activeBreakdowns[id]
    if breakdown then
        breakdown.isSelectedForRepair = not breakdown.isSelectedForRepair
        self:updateScreen()
    end
end


function ADS_WorkshopDialog:showMaintenanceConfirmationDialog(maintenanceType, dialogTitleKey, dialogTextKey)
    local price = self.vehicle:getMaintenancePriceByType(maintenanceType) * (g_workshopScreen.isOwnWorkshop and 0.8 or 1)
    local finalDialogText = g_i18n:getText(dialogTextKey)

    finalDialogText = string.gsub(finalDialogText, "\\n", "\n")
    finalDialogText = string.gsub(finalDialogText, "{price}", g_i18n:formatMoney(price))
    finalDialogText = string.gsub(finalDialogText, "{aftermarket_price}", g_i18n:formatMoney(price / 1.8))
    finalDialogText = string.gsub(finalDialogText, "{time}", self.vehicle:getFormattedMaintenanceFinishTimeText(maintenanceType, self.workshopType))
    finalDialogText = string.gsub(finalDialogText, "{duration}", self.vehicle:getFormattedMaintenanceDurationText(maintenanceType, self.workshopType))


    if maintenanceType == AdvancedDamageSystem.STATUS.INSPECTION then
        YesNoDialog.show(
            ADS_WorkshopDialog.maintanceCallback,
            nil,
            finalDialogText,
            g_i18n:getText(dialogTitleKey),
            nil, nil, nil, nil, nil,
            { maintenanceType, self.workshopType }
        )
    else
        local options = { g_i18n:getText('ads_ws_option_genuine_parts'), g_i18n:getText('ads_ws_option_aftermarket_parts') }        
        local optionDialog = g_gui:showDialog("OptionDialog")
        if optionDialog ~= nil then
            optionDialog.target:setText(finalDialogText)
            optionDialog.target:setTitle(g_i18n:getText(dialogTitleKey))
            optionDialog.target:setOptions(options)
            optionDialog.target:setCallback(ADS_WorkshopDialog.maintanceCallback, nil, { maintenanceType, self.workshopType })
        end
    end
end

function ADS_WorkshopDialog:onClickShowLog()
    ADS_maintenanceLogDialog.show(self.vehicle)
end


function ADS_WorkshopDialog:onClickInspection()
    self:showMaintenanceConfirmationDialog(AdvancedDamageSystem.STATUS.INSPECTION, "ads_ws_confirm_inspection_title", "ads_ws_confirm_inspection_text")
end


function ADS_WorkshopDialog:onClickService()
    self:showMaintenanceConfirmationDialog(AdvancedDamageSystem.STATUS.MAINTENANCE, "ads_ws_confirm_maintenance_title", "ads_ws_confirm_maintenance_text")
end


function ADS_WorkshopDialog:onClickRepair()
    local selectedBreakdowns = {}
    for id, breakdown in pairs(self.activeBreakdowns) do
        if breakdown.isSelectedForRepair then
            table.insert(selectedBreakdowns, id)
        end
    end

    if #selectedBreakdowns == 0 then
        InfoDialog.show(g_i18n:getText("ads_ws_info_nothing_to_repair_title"), g_i18n:getText("ads_ws_info_nothing_to_repair_text"), g_i18n:getText("ads_ws_button_ok"))
        return
    end

    self:showMaintenanceConfirmationDialog(AdvancedDamageSystem.STATUS.REPAIR, "ads_ws_confirm_repair_title", "ads_ws_confirm_repair_text")
end

function ADS_WorkshopDialog:onClickOverhaul()
    self:showMaintenanceConfirmationDialog(AdvancedDamageSystem.STATUS.OVERHAUL, "ads_ws_confirm_overhaul_title", "ads_ws_confirm_overhaul_text")
end

function ADS_WorkshopDialog.maintanceCallback(option, args)
    if not option or option == 0 or args == nil then return end
    local dialog = ADS_WorkshopDialog.INSTANCE
    if dialog == nil or dialog.vehicle == nil then return end

    local type = args[1]
    local workshopType = args[2]
    local vehicle = dialog.vehicle

    local selectedBreakdowns = {}

    for _, id in ipairs(dialog.visibleBreakdowns) do
        if dialog.activeBreakdowns[id].isSelectedForRepair then
            table.insert(selectedBreakdowns, id)
        end
    end

    local isAftermarketParts = (option == 2)
    local price = AdvancedDamageSystem.calculateMaintenancePrice(vehicle, type) * (g_workshopScreen.isOwnWorkshop and 0.8 or 1)
    if isAftermarketParts then price = price / 1.8 end
    
    if g_currentMission:getMoney() < price then
        InfoDialog.show(g_i18n:getText("shop_messageNotEnoughMoneyToBuy"))
        return
    end

    local breakdownCount = #selectedBreakdowns
    local info = ""

    vehicle:addEntryToMaintenanceLog(type, price, selectedBreakdowns, isAftermarketParts, info)
    vehicle:initMaintenance(type, workshopType, breakdownCount, isAftermarketParts)
    g_currentMission:addMoney(-1 * price, vehicle:getOwnerFarmId(), MoneyType.VEHICLE_RUNNING_COSTS, true, true)
    dialog:updateScreen()
end


function ADS_WorkshopDialog:onCreate(superFunc)
    --
end

function ADS_WorkshopDialog:onOpen(superFunc)

    local function onVehicleChangeStatusEvent(vehicle)
        if self.vehicle.node == vehicle.node then
            log_dbg("Received ADS_VEHICLE_CHANGE_STATUS event for current vehicle. Updating screen.")
            self:updateScreen()
        else
            log_dbg("Received ADS_VEHICLE_CHANGE_STATUS event for another vehicle. Ignoring.")
        end
    end

    local function onWorkshopChangeStatusEvent(vehicle)
        log_dbg("Received ADS_WORKSHOP_CHANGE_STATUS event. Updating screen.")
        self:updateScreen()
    end

    g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.updateScreen, self)
    g_messageCenter:subscribe(MessageType.ADS_VEHICLE_CHANGE_STATUS, onVehicleChangeStatusEvent, self)
    g_messageCenter:subscribe(MessageType.ADS_WORKSHOP_CHANGE_STATUS, onWorkshopChangeStatusEvent, self)
end

function ADS_WorkshopDialog:onClose(superFunc)
    self.vehicle = nil
    g_messageCenter:unsubscribeAll(self)
    g_currentMission:showMoneyChange(MoneyType.VEHICLE_RUNNING_COSTS)
    g_currentMission:showMoneyChange(MoneyType.SHOP_VEHICLE_BUY)
	g_currentMission:showMoneyChange(MoneyType.SHOP_VEHICLE_SELL)
end

function ADS_WorkshopDialog:onClickBack()
    self:close()
end

