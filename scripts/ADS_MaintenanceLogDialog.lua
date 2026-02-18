ADS_maintenanceLogDialog = {}
ADS_maintenanceLogDialog.INSTANCE = nil

local ADS_maintenanceLogDialog_mt = Class(ADS_maintenanceLogDialog, MessageDialog)
local modDirectory = g_currentModDirectory

local function log_dbg(...)
    if ADS_Config and ADS_Config.DEBUG then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i])
        end
        print("[ADS_log_DIALOG] " .. table.concat(args, " "))
    end
end

function ADS_maintenanceLogDialog.register()
    local dialog = ADS_maintenanceLogDialog.new()
    g_gui:loadGui(modDirectory .. "gui/ADS_maintenanceLogDialog.xml", "ADS_maintenanceLogDialog", dialog)
    ADS_maintenanceLogDialog.INSTANCE = dialog
end

function ADS_maintenanceLogDialog.new(target, customMt)
    local dialog = MessageDialog.new(target, customMt or ADS_maintenanceLogDialog_mt)
    dialog.vehicle = nil
    return dialog
end

function ADS_maintenanceLogDialog.show(vehicle)
    if ADS_maintenanceLogDialog.INSTANCE == nil then ADS_maintenanceLogDialog.register() end
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then return end
    
    local dialog = ADS_maintenanceLogDialog.INSTANCE
    dialog.vehicle = vehicle
    
    dialog.logData = vehicle.spec_AdvancedDamageSystem.maintenanceLog or {}
    
    dialog:updateScreen()
    g_gui:showDialog("ADS_maintenanceLogDialog")
end

function ADS_maintenanceLogDialog:updateScreen()
    if self.vehicle == nil then return end
    log_dbg("Updating log Screen...")

    local spec = self.vehicle.spec_AdvancedDamageSystem
    self.balanceElement:setText(g_i18n:formatMoney(g_currentMission:getMoney(), 0, true, true))
    self.vehicleNameValue:setText(g_i18n:getText('ads_log_title') .. " " .. self.vehicle:getFullName())

    local totalCost = 0
    local totalBreakdowns = 0
    for _, entry in pairs(self.logData) do
        totalCost = totalCost + (entry.price or 0)
        if entry.type == AdvancedDamageSystem.STATUS.REPAIR then
            local selectedBreakdownsCount = entry.selectedBreakdowns and #entry.selectedBreakdowns or 0
            totalBreakdowns = totalBreakdowns + selectedBreakdownsCount
        end
    end

    self.totalCostValue:setText(g_i18n:formatMoney(totalCost, 0, true, true))

    local currentYear = g_currentMission.environment.currentYear
    local currentMonth = g_currentMission.environment.currentPeriod
    local age = math.max(1, (currentMonth + (currentYear - 1) * 12) - (spec.purchaseDate.month + (spec.purchaseDate.year - 1) * 12))
    local costPerMonth = totalCost / age
    local avgBreakdownInterval = totalBreakdowns > 0 and ((self.vehicle:getFormattedOperatingTime()- (spec.purchaseHours or 0)) / totalBreakdowns)
    local averageMaintenanceInterval = 0

    self.costPerMonthValue:setText(g_i18n:formatMoney(costPerMonth, 0, true, true) .. " / " .. g_i18n:getText("ads_ws_age_unit"))
    self.ownershipMonthsValue:setText(tostring(age) .. " " .. g_i18n:getText("ads_ws_age_unit"))
    self.totalBreakdownsCountValue:setText(string.format("%d", totalBreakdowns))
    if totalBreakdowns > 0 then
        self.averageBreakdownsIntervalValue:setText(string.format("%.1f", avgBreakdownInterval) .. " " .. g_i18n:getText("ads_spec_hour_s"))
    else
        self.averageBreakdownsIntervalValue:setText("-")
    end

    local maintenanceCount = 0
    for _, entry in pairs(self.logData) do
        if entry.type == AdvancedDamageSystem.STATUS.MAINTENANCE then
            maintenanceCount = maintenanceCount + 1
        end
    end

    if maintenanceCount > 0 then
        local sumMaintenanceInterval = 0
        local lastServiceHours = spec.purchaseHours or 0
        for i = 1, #self.logData do
            local nextEntry = self.logData[i]
            if nextEntry.type == AdvancedDamageSystem.STATUS.MAINTENANCE then
                sumMaintenanceInterval = sumMaintenanceInterval + (nextEntry.operatingHours - lastServiceHours)
                lastServiceHours = nextEntry.operatingHours
            end
        end
        averageMaintenanceInterval = sumMaintenanceInterval / maintenanceCount
        self.averageMaintenanceIntervalValue:setText(string.format("%.1f", averageMaintenanceInterval) .. " " .. g_i18n:getText("ads_spec_hour_s"))
    end

    self.logTable:setDataSource(self)
    self.logTable:setDelegate(self)
    self.logTable:reloadData()

    local isEmpty = #self.logData == 0
    self.logTable:setVisible(not isEmpty)
    self.emptylogText:setVisible(isEmpty)
end

-- ====================================================================
-- LIST DELEGATE METHODS
-- ====================================================================

function ADS_maintenanceLogDialog:getNumberOfItemsInSection(list, section)
    return #self.logData
end

function ADS_maintenanceLogDialog:populateCellForItemInSection(list, section, index, cell)
    local entryIndex = #self.logData - index + 1
    local entry = self.logData[entryIndex]
    local spec = self.vehicle.spec_AdvancedDamageSystem

    if entry == nil then return end

    local yearStr = "00"
    if entry.date.year >= 10 then
        yearStr = tostring(entry.date.year)
    else
        yearStr = "0" .. tostring(entry.date.year)
    end
    local dateStr = string.format("%s %s. '%s", entry.date.day, g_i18n:formatPeriod(entry.date.month, true), yearStr)

    cell:getAttribute("logDate"):setText(dateStr)
    cell:getAttribute("logHours"):setText(string.format("%.1f", entry.operatingHours) .. " " .. g_i18n:getText("ads_spec_hour_s"))

    local typeText = "UNKNOWN"
    local color = {1, 1, 1, 1}
    
    local S = AdvancedDamageSystem.STATUS
    if entry.type == S.REPAIR then
        typeText = g_i18n:getText("ads_ws_action_repair")
        color = {0.88, 0.12, 0.12, 1}
    elseif entry.type == S.MAINTENANCE then
        typeText = g_i18n:getText("ads_ws_action_maintenance")
        color = {0.2, 0.6, 1.0, 1}
    elseif entry.type == S.INSPECTION then
        typeText = g_i18n:getText("ads_ws_action_inspection")
        color = {1, 1, 1, 1}
    elseif entry.type == S.OVERHAUL then
        typeText = g_i18n:getText("ads_ws_action_overhaul")
        color = {1.0, 0.5, 0.0, 1}
    end
    
    cell:getAttribute("logType"):setText(typeText)
    cell:getAttribute("logType"):setTextColor(unpack(color))

    local descText = ""
    local repairedParts = {}
    local seenParts = {}
        
    for _, breakdownId in ipairs(entry.selectedBreakdowns) do
        local breakdownDef = ADS_Breakdowns.BreakdownRegistry[breakdownId]
            
        if breakdownDef and breakdownDef.part then
            if not seenParts[breakdownDef.part] then
                table.insert(repairedParts, breakdownDef.part)
                seenParts[breakdownDef.part] = true
            end
        end
    end

    local partsNames = {}
    if repairedParts and #repairedParts > 0 then
        for _, partKey in ipairs(repairedParts) do
            table.insert(partsNames, g_i18n:getText(partKey))
        end
    end
    
    if entry.type == S.REPAIR then     
        descText = table.concat(partsNames, ", ")
        if entry.isAftermarketParts then
            descText = descText .. " (" .. g_i18n:getText("ads_ws_option_aftermarket_parts") .. ")"
        end

    elseif entry.type == S.MAINTENANCE then
        local lastServiceHours = spec.purchaseHours or 0
        for i = 1, entryIndex - 1 do
            local nextEntry = self.logData[i]
            if nextEntry.type == S.MAINTENANCE then
                lastServiceHours = nextEntry.operatingHours
            end
        end
        descText = string.format(g_i18n:getText("ads_log_maintenance_desc"), entry.operatingHours - lastServiceHours)
        if entry.isAftermarketParts then
            descText = descText .. " (" .. g_i18n:getText("ads_ws_option_aftermarket_parts") .. ")"
        end
        if #repairedParts > 0 then
            descText = descText .. ". " .. string.format(g_i18n:getText("ads_log_inspection_desc_with_breakdowns"), table.concat(partsNames, ", "))
        end

    elseif entry.type == S.INSPECTION then
        if spec.currentState == AdvancedDamageSystem.STATUS.INSPECTION and entry.id == #spec.maintenanceLog then
            descText = g_i18n:getText("ads_ws_inspecting_status")
        else
            if #repairedParts > 0 then
                descText = string.format(g_i18n:getText("ads_log_inspection_desc_with_breakdowns"), table.concat(partsNames, ", "))
            else
                descText = g_i18n:getText("ads_log_inspection_desc_no_breakdowns")
            end
        end

    elseif entry.type == S.OVERHAUL then
        descText = g_i18n:getText("ads_log_overhaul_desc")
    end

    cell:getAttribute("logDescription"):setText(descText)
    cell:getAttribute("logPrice"):setText(g_i18n:formatMoney(entry.price, 0, true, true))
    color = {0.88, 0.12, 0.12, 1}
    cell:getAttribute("logPrice"):setTextColor(unpack(color))
end

-- ====================================================================
-- CALLBACKS & EVENTS
-- ====================================================================

function ADS_maintenanceLogDialog:onClickBack()
    self:close()
end

function ADS_maintenanceLogDialog:onOpen(superFunc)
    g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.updateScreen, self)
end

function ADS_maintenanceLogDialog:onClose(superFunc)
    self.vehicle = nil
    self.logData = nil
    g_messageCenter:unsubscribeAll(self)
end