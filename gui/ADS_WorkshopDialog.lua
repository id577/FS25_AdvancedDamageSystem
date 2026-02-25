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
    dialog.isDialogOpen = false
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
    
    self.lastServiceValue:setText(ADS_Utils.formatTimeAgo(vehicle:getLastMaintenanceDate()))
    self.maintainabilityValue:setText(string.format("%.1f%%", (spec.maintainability or 0) * 100))
    self.maintainabilityValue:setTextColor(ADS_Utils.getValueColor(spec.maintainability, 1.2, 1.1, 1.1, 0.9, false))

    local monthsSinceInspectionText = ADS_Utils.formatTimeAgo(self.vehicle:getLastInspectionDate())
    local serviceText = ADS_Utils.formatService(self.vehicle:getLastInspectedService())
    local conditionText = ADS_Utils.formatCondition(self.vehicle:getLastInspectedCondition())

    self.serviceValue:setText(serviceText)
    self.serviceValue:setTextColor(ADS_Utils.getValueColor(self.vehicle:getLastInspectedService(), 0.9, 0.65, 0.55, 0.45, false))
    self.condtionValue:setText(conditionText)
    self.condtionValue:setTextColor(ADS_Utils.getValueColor(self.vehicle:getLastInspectedCondition(), 0.8, 0.6, 0.4, 0.2, false))
    self.serviceLastInspectionDeltaValue:setTextColor(0.5, 0.5, 0.5, 1.0)
    self.condtionLastInspectionDelataValue:setTextColor(0.5, 0.5, 0.5, 1.0)
    self.serviceLastInspectionDeltaValue:setText(monthsSinceInspectionText)
    self.condtionLastInspectionDelataValue:setText(monthsSinceInspectionText)

    self.relAndMainValue:setText(ADS_Utils.formatOperatingHours(self.vehicle:getHoursSinceLastMaintenance(), self.vehicle:getMaintenanceInterval()))

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
        local finishTimeText = ADS_Utils.formatFinishTime(self.vehicle:getServiceFinishTime(nil, nil, nil, nil))
        local localizedStatus = g_i18n:getText(spec.currentState)
        statusText = string.format(g_i18n:getText("ads_ws_status_in_progress_format"), localizedStatus, finishTimeText)
        if spec.currentState ~= STATUS.REPAIR then
            local inspectingText = g_i18n:getText("ads_ws_inspecting_status")
            self.serviceValue:setText(inspectingText)
            self.serviceValue:setTextColor(0.5, 0.5, 0.5, 1.0)
            self.condtionValue:setText(inspectingText)
            self.condtionValue:setTextColor(0.5, 0.5, 0.5, 1.0)
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

    local isUnderService = spec.currentState ~= STATUS.READY
    self.cancelServiceButton:setVisible(isUnderService)
    self.cancelServiceButton.disabled = not isUnderService

    local inspectionPrice = self.vehicle:getServicePrice(AdvancedDamageSystem.STATUS.INSPECTION, AdvancedDamageSystem.INSPECTION_TYPES.STANDARD, "NONE", false, self.workshopType)
    local maintenancePrice = self.vehicle:getServicePrice(AdvancedDamageSystem.STATUS.MAINTENANCE, AdvancedDamageSystem.MAINTENANCE_TYPES.STANDARD, AdvancedDamageSystem.PART_TYPES.OEM, false, self.workshopType)
    local repairPrice = self.vehicle:getServicePrice(AdvancedDamageSystem.STATUS.REPAIR, AdvancedDamageSystem.REPAIR_URGENCY.MEDIUM, AdvancedDamageSystem.PART_TYPES.OEM, false, self.workshopType)
    local overhaulPrice = self.vehicle:getServicePrice(AdvancedDamageSystem.STATUS.OVERHAUL, AdvancedDamageSystem.OVERHAUL_TYPES.STANDARD, "NONE", false, self.workshopType)

    local selectedRepairCount = 0
    for _, breakdown in pairs(self.activeBreakdowns) do
        if breakdown ~= nil and breakdown.isVisible and breakdown.isSelectedForRepair then
            selectedRepairCount = selectedRepairCount + 1
        end
    end

    if selectedRepairCount == 0 then
        self.repairButton.disabled = true
    end
    
    local buttonFormat = g_i18n:getText("ads_ws_button_price_format")
    self.inscpectionButton:setText(string.format(buttonFormat, g_i18n:getText("ads_ws_action_inspection"), g_i18n:formatMoney(inspectionPrice)))
    self.maintenanceButton:setText(string.format(buttonFormat, g_i18n:getText("ads_ws_action_maintenance"), g_i18n:formatMoney(maintenancePrice)))
    if self.vehicle:isWarrantyRepairCovered(AdvancedDamageSystem.PART_TYPES.OEM) and selectedRepairCount > 0 then
        self.repairButton:setText(string.format(buttonFormat, g_i18n:getText("ads_ws_action_repair"), g_i18n:getText("ads_option_menu_warranty_repair_text")))
    else
        self.repairButton:setText(string.format(buttonFormat, g_i18n:getText("ads_ws_action_repair"), g_i18n:formatMoney(repairPrice)))
    end
    self.overhaulButton:setText(string.format(buttonFormat, g_i18n:getText("ads_ws_action_overhaul"), g_i18n:formatMoney(overhaulPrice)))

    -- ====================================================================
    -- 5: Table Visibility
    -- ====================================================================
    
    local isListEmpty = #self.visibleBreakdowns == 0

    if self.vehicle:getCurrentStatus() == STATUS.READY then
        self.breakdownTable:setVisible(not isListEmpty)
        self.tableSlider:setVisible(not isListEmpty)
        self.emptyTableText:setVisible(isListEmpty)
        self.emptyTableText:setText(g_i18n:getText("ads_ws_info_no_breakdowns"))
        self.emptyTableText:setTextColor(0.5, 0.5, 0.5, 1)
    else
        self:updateServiceProgressText()
    end
    --self.statusText:setPosition(0, 0.015)
end

function ADS_WorkshopDialog:getServiceProgressPercent()
    if self.vehicle == nil or self.vehicle.spec_AdvancedDamageSystem == nil then
        return nil
    end

    local spec = self.vehicle.spec_AdvancedDamageSystem
    local totalTime = spec.pendingProgressTotalTime or 0
    local elapsedTime = spec.pendingProgressElapsedTime or 0

    if totalTime <= 0 then
        return nil
    end

    local ratio = math.max(0, math.min(elapsedTime / totalTime, 1))
    return math.floor(ratio * 100)
end

function ADS_WorkshopDialog:updateServiceProgressText()
    if self.vehicle == nil or self.vehicle.spec_AdvancedDamageSystem == nil then
        return
    end

    if self.vehicle:getCurrentStatus() == AdvancedDamageSystem.STATUS.READY then
        return
    end

    local progressPercent = self:getServiceProgressPercent()

    if progressPercent ~= nil then
        progressText = string.format("%d%%", progressPercent)
    end

    self.emptyTableText:setVisible(true)
    self.breakdownTable:setVisible(false)
    self.tableSlider:setVisible(false)
    self.emptyTableText:setText(progressText)
    self.emptyTableText:setTextColor(0.455, 0.565, 0.115, 1)
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
    local price = self.vehicle:getBreakdownRepairPrice(breadownId, data.stage, AdvancedDamageSystem.PART_TYPES.OEM)
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

function ADS_WorkshopDialog:onClickShowLog()
    local spec = self.vehicle.spec_AdvancedDamageSystem
    if #spec.maintenanceLog > 1 then
        ADS_MaintenanceLogDialog.show(self.vehicle)
    else
        InfoDialog.show(g_i18n:getText("ads_ws_no_log_empty_message"))
    end
end

function ADS_WorkshopDialog:onClickShowReport()
    local spec = self.vehicle.spec_AdvancedDamageSystem
    for i = #spec.maintenanceLog, 1, -1 do
        local entry = spec.maintenanceLog[i]
        if AdvancedDamageSystem.getIsLogEntryHasReport(entry) then
            ADS_ReportDialog.show(self.vehicle, entry)
            return
        end
    end
    InfoDialog.show(g_i18n:getText("ads_ws_no_last_report_message"))
end

function ADS_WorkshopDialog:onClickInspection()
    ADS_MaintenanceTwoOptionsDialog.show(self.vehicle, AdvancedDamageSystem.STATUS.INSPECTION)
end

function ADS_WorkshopDialog:onClickService()
    ADS_MaintenanceThreeOptionsDialog.show(self.vehicle, AdvancedDamageSystem.STATUS.MAINTENANCE)
end

function ADS_WorkshopDialog:onClickRepair()
    ADS_MaintenanceThreeOptionsDialog.show(self.vehicle, AdvancedDamageSystem.STATUS.REPAIR)
end

function ADS_WorkshopDialog:onClickOverhaul()
    ADS_MaintenanceTwoOptionsDialog.show(self.vehicle, AdvancedDamageSystem.STATUS.OVERHAUL)
end

function ADS_WorkshopDialog:onClickCancelService()
    if self.vehicle == nil then return end
    local spec = self.vehicle.spec_AdvancedDamageSystem
    if spec == nil or spec.currentState == AdvancedDamageSystem.STATUS.READY then return end

    local title = string.format(g_i18n:getText("ads_ws_cancel_confirm_title"), g_i18n:getText(spec.currentState))
    local text = g_i18n:getText("ads_ws_cancel_confirm_text")

    if YesNoDialog ~= nil and YesNoDialog.show ~= nil then
        YesNoDialog.show(self.onCancelServiceConfirm, self, text, title, nil, nil)
    end
end

function ADS_WorkshopDialog:onCancelServiceConfirm(yes)
    if yes and self.vehicle ~= nil then
        self.vehicle:cancelService()
        self:updateScreen()
    end
end


function ADS_WorkshopDialog:onCreate(superFunc)
    --
end

function ADS_WorkshopDialog:onOpen(superFunc)
    self.isDialogOpen = true

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
    self.isDialogOpen = false
    self.vehicle = nil
    g_messageCenter:unsubscribeAll(self)
    g_currentMission:showMoneyChange(MoneyType.VEHICLE_RUNNING_COSTS)
    g_currentMission:showMoneyChange(MoneyType.SHOP_VEHICLE_BUY)
	g_currentMission:showMoneyChange(MoneyType.SHOP_VEHICLE_SELL)
end

function ADS_WorkshopDialog:onClickBack()
    self:close()
end

