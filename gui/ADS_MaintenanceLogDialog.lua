ADS_MaintenanceLogDialog = {}
ADS_MaintenanceLogDialog.INSTANCE = nil

local ADS_MaintenanceLogDialog_mt = Class(ADS_MaintenanceLogDialog, MessageDialog)
local modDirectory = g_currentModDirectory

local function log_dbg(...)
    if ADS_Config and ADS_Config.DEBUG then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i])
        end
        print(" " .. table.concat(args, " "))
    end
end

local function isLoggableRepairBreakdownId(breakdownId)
    return breakdownId ~= nil and breakdownId ~= "GENERAL_WEAR"
end

local function getLoggableRepairBreakdownCount(entry)
    if entry == nil or entry.conditionData == nil or entry.conditionData.selectedBreakdowns == nil then
        return 0
    end

    local count = 0
    for _, breakdownId in ipairs(entry.conditionData.selectedBreakdowns) do
        if isLoggableRepairBreakdownId(breakdownId) then
            count = count + 1
        end
    end

    return count
end

function ADS_MaintenanceLogDialog.register()
    local dialog = ADS_MaintenanceLogDialog.new()
    g_gui:loadGui(modDirectory .. "gui/ADS_MaintenanceLogDialog.xml", "ADS_MaintenanceLogDialog", dialog)
    ADS_MaintenanceLogDialog.INSTANCE = dialog
end

function ADS_MaintenanceLogDialog.new(target, customMt)
    local dialog = MessageDialog.new(target, customMt or ADS_MaintenanceLogDialog_mt)
    dialog.vehicle = nil
    return dialog
end

function ADS_MaintenanceLogDialog.show(vehicle)
    if ADS_MaintenanceLogDialog.INSTANCE == nil then ADS_MaintenanceLogDialog.register() end
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then return end
    
    local dialog = ADS_MaintenanceLogDialog.INSTANCE
    dialog.vehicle = vehicle
    
    dialog.logData = vehicle.spec_AdvancedDamageSystem.maintenanceLog or {}
    
    dialog:updateScreen()
    g_gui:showDialog("ADS_MaintenanceLogDialog")
end

function ADS_MaintenanceLogDialog:updateScreen()
    if self.vehicle == nil then return end
    log_dbg("Updating log Screen...")

    local spec = self.vehicle.spec_AdvancedDamageSystem
    self.balanceElement:setText(g_i18n:formatMoney(g_currentMission:getMoney(), 0, true, true))
    self.vehicleNameValue:setText(g_i18n:getText('ads_log_title') .. " " .. self.vehicle:getFullName())

    local totalCost = 0
    local totalBreakdowns = 0
    local purchaseDate = {}
    local purchaseHours = 0

    for _, entry in pairs(self.logData) do
        totalCost = totalCost + (entry.price or 0)
        if entry.type == AdvancedDamageSystem.STATUS.REPAIR then
            totalBreakdowns = totalBreakdowns + getLoggableRepairBreakdownCount(entry)
        end
        if entry.id == 1 then
            purchaseDate = entry.date or {}
            purchaseHours = entry.conditionData and entry.conditionData.operatingHours or 0
        end
    end

    self.totalCostValue:setText(g_i18n:formatMoney(totalCost, 0, true, true))

    local currentYear = g_currentMission.environment.currentYear
    local currentMonth = g_currentMission.environment.currentPeriod
    
    local pMonth = (purchaseDate and purchaseDate.month) or currentMonth
    local pYear = (purchaseDate and purchaseDate.year) or currentYear
    local age = math.max(1, (currentMonth + (currentYear - 1) * 12) - (pMonth + (pYear - 1) * 12))
    
    local costPerMonth = totalCost / age
    local avgBreakdownInterval = totalBreakdowns > 0 and ((self.vehicle:getFormattedOperatingTime() - (purchaseHours or 0)) / totalBreakdowns) or 0
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
        local lastServiceHours = purchaseHours or 0
        for i = 1, #self.logData do
            local nextEntry = self.logData[i]
            if nextEntry.type == AdvancedDamageSystem.STATUS.MAINTENANCE then
                if nextEntry.conditionData and nextEntry.conditionData.operatingHours then
                    sumMaintenanceInterval = sumMaintenanceInterval + (nextEntry.conditionData.operatingHours - lastServiceHours)
                    lastServiceHours = nextEntry.conditionData.operatingHours
                end
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

function ADS_MaintenanceLogDialog:getNumberOfItemsInSection(list, section)
    return #self.logData
end

function ADS_MaintenanceLogDialog:populateCellForItemInSection(list, section, index, cell)
    local entryIndex = #self.logData - index + 1
    local entry = self.logData[entryIndex]
    local spec = self.vehicle.spec_AdvancedDamageSystem

    if entry == nil then return end

    -- date
    local yearStr = "00"
    if entry.date and entry.date.year then
        if entry.date.year >= 10 then
            yearStr = tostring(entry.date.year)
        else
            yearStr = "0" .. tostring(entry.date.year)
        end
    end
    local dDay = (entry.date and entry.date.day) or 1
    local dMonth = (entry.date and entry.date.month) or 1
    local dateStr = string.format("%s %s. '%s", dDay, g_i18n:formatPeriod(dMonth, true), yearStr)
    cell:getAttribute("logDate"):setText(dateStr)
    
    -- operating hours
    local opHours = (entry.conditionData and entry.conditionData.operatingHours) or 0
    cell:getAttribute("logHours"):setText(string.format("%.1f", opHours) .. " " .. g_i18n:getText("ads_spec_hour_s"))

    -- maintenance type
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

    -- description
    local descText = ""
    local repairedParts = {}
    local seenParts = {}

    if entry.conditionData and entry.conditionData.selectedBreakdowns then
        for _, breakdownId in ipairs(entry.conditionData.selectedBreakdowns) do
            if isLoggableRepairBreakdownId(breakdownId) then
                local breakdownDef = ADS_Breakdowns.BreakdownRegistry[breakdownId]
                 
                if breakdownDef and breakdownDef.part then
                    if not seenParts[breakdownDef.part] then
                        table.insert(repairedParts, breakdownDef.part)
                        seenParts[breakdownDef.part] = true
                    end
                end
            end
        end
    end

    local partsNames = {}
    if repairedParts and #repairedParts > 0 then
        for _, partKey in ipairs(repairedParts) do
            table.insert(partsNames, g_i18n:getText(partKey))
        end
    end
   
    -- repair 
    if entry.type == S.REPAIR then     
        local repairedPartsText = table.concat(partsNames, ", ")
        if repairedPartsText == "" then
            repairedPartsText = g_i18n:getText("ads_log_repair_desc_generic")
        end
        descText = repairedPartsText .. " (" .. g_i18n:getText(entry.optionTwo or "NONE") .. ")"

    -- maintenance
    elseif entry.type == S.MAINTENANCE then 
        descText = string.format(g_i18n:getText("ads_log_performed"), g_i18n:getText(entry.optionOne) .. " " .. g_i18n:getText("ads_ws_task_maintenance"))
        descText = descText .. " (" .. g_i18n:getText(entry.optionTwo) .. ")"
        if #repairedParts > 0 then
            descText = descText .. ". " .. string.format(g_i18n:getText("ads_log_inspection_desc_with_breakdowns"), table.concat(partsNames, ", "))
        end

    -- inspection
    elseif entry.type == S.INSPECTION then
        if spec.currentState == AdvancedDamageSystem.STATUS.INSPECTION and entry.id == #spec.maintenanceLog then
            descText = g_i18n:getText("ads_ws_inspecting_status")
        else
            descText = string.format(g_i18n:getText("ads_log_performed"), g_i18n:getText(entry.optionOne) .. " " .. g_i18n:getText("ads_ws_task_inspection"))
            if #repairedParts > 0 then
                descText = descText .. ". " .. string.format(g_i18n:getText("ads_log_inspection_desc_with_breakdowns"), table.concat(partsNames, ", "))
            else
                descText = descText .. ". " .. g_i18n:getText("ads_log_inspection_desc_no_breakdowns")
            end
        end

    -- overhaul
    elseif entry.type == S.OVERHAUL then
        descText = string.format(g_i18n:getText("ads_log_performed"), g_i18n:getText(entry.optionOne) .. " " .. g_i18n:getText("ads_ws_task_overhaul"))
        if entry.optionThree then
            descText = descText .. ". " .. g_i18n:getText("ads_ws_option_overhaul_with_painting")
        end
    end

    if entry.location == "UNKNOWN" then
        descText = "NO DATA"
    end

    cell:getAttribute("logDescription"):setText(descText)
    
    cell:getAttribute("logPrice"):setText(g_i18n:formatMoney(entry.price or 0, 0, true, true))
    color = {0.88, 0.12, 0.12, 1}
    cell:getAttribute("logPrice"):setTextColor(unpack(color))
end

-- ====================================================================
-- CALLBACKS & EVENTS
-- ====================================================================

function ADS_MaintenanceLogDialog:onClickBack()
    self:close()
end

function ADS_MaintenanceLogDialog:onRowClick(row)
    if row == nil or row.indexInSection == nil then return end
    local spec = self.vehicle.spec_AdvancedDamageSystem
    
    local entry = self.logData[#self.logData - row.indexInSection + 1]
    if entry ~= nil and AdvancedDamageSystem.getIsLogEntryHasReport(entry) then
        ADS_ReportDialog.show(self.vehicle, entry)
        return
    end
    InfoDialog.show(g_i18n:getText("ads_ws_no_report_message"))
    
end

function ADS_MaintenanceLogDialog:onOpen(superFunc)
    g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.updateScreen, self)
end

function ADS_MaintenanceLogDialog:onClose(superFunc)
    self.vehicle = nil
    self.logData = nil
    g_messageCenter:unsubscribeAll(self)
end
