ADS_InGameMenuFrame = {}
ADS_InGameMenuFrame.MOD_DIR = g_currentModDirectory
ADS_InGameMenuFrame.PAGE_NAME = "pageADSFleet"
ADS_InGameMenuFrame.REFRESH_INTERVAL_MS = 1000
ADS_InGameMenuFrame.SORT_COLUMN = {
    VEHICLE = "vehicle",
    AGE = "age",
    WORKING_HOURS = "workingHours",
    CONDITION = "condition",
    INTERVAL = "interval",
    LAST_INSPECTION = "lastInspection",
    LAST_MAINTENANCE = "lastMaintenance",
    COST = "cost",
    LEASING_PRICE = "leasingPrice",
    PRICE = "price"
}

local ADS_InGameMenuFrame_mt = Class(ADS_InGameMenuFrame, TabbedMenuFrameElement)

local function log_dbg(...)
    if ADS_Config ~= nil and ADS_Config.DEBUG then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i])
        end
        print("[ADS_INGAME_MENU] " .. table.concat(args, " "))
    end
end

local function getVehicleTotalCost(vehicle)
    local spec = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    local log = spec ~= nil and spec.maintenanceLog or nil
    local totalCost = 0

    if log == nil then
        return totalCost
    end

    for _, entry in ipairs(log) do
        totalCost = totalCost + (entry.price or 0)
    end

    return totalCost
end

local function getDateSortValue(date)
    if type(date) ~= "table" or date.year == nil or date.month == nil then
        return -1
    end

    return (date.year * 12) + date.month
end

local function safeLower(value)
    return string.lower(tostring(value or ""))
end

local function buildVehicleRow(vehicle)
    local conditionValue, isCompleteInspection = vehicle:getLastInspectedCondition()
    local totalCost = getVehicleTotalCost(vehicle)
    local currentValue = math.min(
        math.floor(vehicle:getSellPrice() * EconomyManager.DIRECT_SELL_MULTIPLIER),
        vehicle:getPrice()
    )
    local isLeased = vehicle.propertyState == 3
    local leasingPriceValue = 0
    local priceText = g_i18n:formatMoney(currentValue, 0, true, true)
    local priceValue = currentValue
    local lastInspectionDate = vehicle:getLastInspectionDate()
    local lastMaintenanceDate = vehicle:getLastMaintenanceDate()
    local intervalCurrent = vehicle:getHoursSinceLastMaintenance()
    local intervalTotal = vehicle:getMaintenanceInterval()
    local operatingHours = tonumber(vehicle:getFormattedOperatingTime()) or 0

    if isLeased then
        leasingPriceValue = (vehicle.price or vehicle:getPrice()) * (
            EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR + EconomyManager.PER_DAY_LEASING_FACTOR
        )
        priceText = "-"
        priceValue = 0
    end

    return {
        vehicle = vehicle,
        vehicleName = vehicle:getFullName() or "",
        age = string.format("%d %s", vehicle.age or 0, g_i18n:getText("ads_ws_age_unit")),
        ageValue = vehicle.age or 0,
        workingHours = string.format("%s %s", vehicle:getFormattedOperatingTime(), g_i18n:getText("ads_ws_hours_unit")),
        workingHoursValue = operatingHours,
        condition = ADS_Utils.formatCondition(conditionValue, isCompleteInspection),
        conditionValue = conditionValue or 0,
        conditionColor = {ADS_Utils.getValueColor(conditionValue, 0.8, 0.6, 0.4, 0.2, false)},
        interval = ADS_Utils.formatOperatingHours(intervalCurrent, intervalTotal),
        intervalValue = intervalCurrent or 0,
        lastInspection = ADS_Utils.formatTimeAgo(lastInspectionDate),
        lastInspectionValue = getDateSortValue(lastInspectionDate),
        lastMaintenance = ADS_Utils.formatTimeAgo(lastMaintenanceDate),
        lastMaintenanceValue = getDateSortValue(lastMaintenanceDate),
        cost = g_i18n:formatMoney(totalCost, 0, true, true),
        costValue = totalCost,
        leasingPrice = leasingPriceValue > 0 and g_i18n:formatMoney(leasingPriceValue, 0, true, true) or "-",
        leasingPriceValue = leasingPriceValue,
        price = priceText,
        priceValue = priceValue
    }
end

function ADS_InGameMenuFrame.register()
    local frame = ADS_InGameMenuFrame.new()
    local filename = ADS_InGameMenuFrame.MOD_DIR .. "gui/ADS_InGameMenuFrame.xml"
    g_gui:loadGui(filename, "adsInGameMenuFleetFrame", frame, false)
    return frame
end

function ADS_InGameMenuFrame.new(target, customMt)
    local self = TabbedMenuFrameElement.new(target, customMt or ADS_InGameMenuFrame_mt)

    self.hasCustomMenuButtons = true
    self.rows = {}
    self.refreshTimerMs = 0
    self.selectedVehicleId = nil
    self.selectedRowIndex = 1
    self.sortColumn = ADS_InGameMenuFrame.SORT_COLUMN.VEHICLE
    self.sortingAsc = true
    self.elementCache = {}

    return self
end

function ADS_InGameMenuFrame:setTemplates()
    if self.attributesLayout == nil then
        return
    end

    self.detailTemplate = self.attributesLayout:getDescendantByName("detailTemplate")
    self.valueTemplate = self.attributesLayout:getDescendantByName("valueTemplate")

    if self.detailTemplate ~= nil then
        self.detailTemplate:setVisible(false)
    end
    if self.valueTemplate ~= nil then
        self.valueTemplate:setVisible(false)
    end
end

function ADS_InGameMenuFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }

    self.nextPageButtonInfo = {
        inputAction = InputAction.MENU_PAGE_NEXT,
        text = g_i18n:getText("ui_ingameMenuNext"),
        callback = function()
            self:onPageNext()
        end
    }

    self.prevPageButtonInfo = {
        inputAction = InputAction.MENU_PAGE_PREV,
        text = g_i18n:getText("ui_ingameMenuPrev"),
        callback = function()
            self:onPagePrevious()
        end
    }

    self.enterVehicleButtonInfo = {
        inputAction = InputAction.MENU_ACCEPT,
        text = g_i18n:getText("button_enterVehicle"),
        callback = function()
            self:onTryEnterVehicle()
        end
    }

    self.sellVehicleButtonInfo = {
        inputAction = InputAction.MENU_CANCEL,
        text = g_i18n:getText("ui_sellItem"),
        callback = function()
            self:onSellSelectedVehicle()
        end
    }

    self.maintenanceLogButtonInfo = {
        inputAction = InputAction.MENU_EXTRA_1,
        text = g_i18n:getText("ads_ws_label_maintenance_log"),
        callback = function()
            self:onShowMaintenanceLog()
        end
    }

    self:setMenuButtonInfo({
        self.backButtonInfo,
        self.prevPageButtonInfo,
        self.nextPageButtonInfo,
        self.maintenanceLogButtonInfo,
        self.enterVehicleButtonInfo,
        self.sellVehicleButtonInfo
    })

    if self.menuHeaderTitle ~= nil then
        self.menuHeaderTitle:setText(g_i18n:getText("ads_ingame_menu_title"))
    end

    if self.vehicleList ~= nil then
        self.vehicleList:setDataSource(self)
        self.vehicleList:setDelegate(self)
    end

    self.sortIconMap = {
        [ADS_InGameMenuFrame.SORT_COLUMN.VEHICLE] = {asc = self.iconVehicleAscending, desc = self.iconVehicleDescending},
        [ADS_InGameMenuFrame.SORT_COLUMN.AGE] = {asc = self.iconAgeAscending, desc = self.iconAgeDescending},
        [ADS_InGameMenuFrame.SORT_COLUMN.WORKING_HOURS] = {asc = self.iconHoursAscending, desc = self.iconHoursDescending},
        [ADS_InGameMenuFrame.SORT_COLUMN.CONDITION] = {asc = self.iconConditionAscending, desc = self.iconConditionDescending},
        [ADS_InGameMenuFrame.SORT_COLUMN.INTERVAL] = {asc = self.iconIntervalAscending, desc = self.iconIntervalDescending},
        [ADS_InGameMenuFrame.SORT_COLUMN.LAST_INSPECTION] = {asc = self.iconInspectionAscending, desc = self.iconInspectionDescending},
        [ADS_InGameMenuFrame.SORT_COLUMN.LAST_MAINTENANCE] = {asc = self.iconMaintenanceAscending, desc = self.iconMaintenanceDescending},
        [ADS_InGameMenuFrame.SORT_COLUMN.COST] = {asc = self.iconCostAscending, desc = self.iconCostDescending},
        [ADS_InGameMenuFrame.SORT_COLUMN.LEASING_PRICE] = {asc = self.iconLeasingAscending, desc = self.iconLeasingDescending},
        [ADS_InGameMenuFrame.SORT_COLUMN.PRICE] = {asc = self.iconPriceAscending, desc = self.iconPriceDescending}
    }

    self:setTemplates()
    self:updateSortIcons()
    self:updateActionButtons()
    self:reloadRows()
end

function ADS_InGameMenuFrame:onFrameOpen()
    if self.detailBox ~= nil then
        self.detailBox:setVisible(true)
    end
    if self.itemDetailsMap ~= nil and g_currentMission ~= nil and g_currentMission.hud ~= nil then
        self.itemDetailsMap:setIngameMap(g_currentMission.hud:getIngameMap())
    end

    ADS_InGameMenuFrame:superClass().onFrameOpen(self)
    self.refreshTimerMs = 0
    self:reloadRows()
end

function ADS_InGameMenuFrame:onFrameClose()
    if self.vehicleList ~= nil then
        self.vehicleList.selectedIndex = 1
    end
    ADS_InGameMenuFrame:superClass().onFrameClose(self)
end

function ADS_InGameMenuFrame:getSelectedVehicle()
    local row = self.rows[self.selectedRowIndex]
    return row ~= nil and row.vehicle or nil
end

function ADS_InGameMenuFrame:updateActionButtons()
    local vehicle = self:getSelectedVehicle()
    local hasVehicle = vehicle ~= nil
    local isLeased = hasVehicle and vehicle.propertyState == 3
    local canEnterVehicle = hasVehicle and vehicle.getIsEnterableFromMenu ~= nil and vehicle:getIsEnterableFromMenu()

    if self.enterVehicleButtonInfo ~= nil then
        self.enterVehicleButtonInfo.disabled = not canEnterVehicle
    end

    if self.sellVehicleButtonInfo ~= nil then
        self.sellVehicleButtonInfo.disabled = not hasVehicle
        self.sellVehicleButtonInfo.text = g_i18n:getText(isLeased and "ui_returnThis" or "ui_sellItem")
    end

    if self.maintenanceLogButtonInfo ~= nil then
        self.maintenanceLogButtonInfo.disabled = not hasVehicle
    end

    self:setMenuButtonInfoDirty()
end

function ADS_InGameMenuFrame:update(dt)
    ADS_InGameMenuFrame:superClass().update(self, dt)

    self.refreshTimerMs = self.refreshTimerMs - dt
    if self.refreshTimerMs <= 0 then
        self.refreshTimerMs = ADS_InGameMenuFrame.REFRESH_INTERVAL_MS
        self:reloadRows()
    end
end

function ADS_InGameMenuFrame:clearDetailElements()
    for _, element in pairs(self.elementCache) do
        if element ~= nil then
            element:delete()
        end
    end

    self.elementCache = {}
end

function ADS_InGameMenuFrame:updateDetailsPanel(vehicle)
    self:clearDetailElements()

    if self.detailBox ~= nil then
        self.detailBox:setVisible(vehicle ~= nil)
    end

    if vehicle == nil then
        return
    end

    local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
    if storeItem == nil then
        return
    end

    if self.itemDetailsImage ~= nil then
        self.itemDetailsImage:setImageFilename(storeItem.imageFilename or vehicle:getImageFilename())
    end
    if self.itemDetailsName ~= nil then
        self.itemDetailsName:setText(vehicle:getFullName())
    end
    if self.itemDetailsMap ~= nil and vehicle.rootNode ~= nil then
        local x, _, z = getTranslation(vehicle.rootNode)
        self.itemDetailsMap:setCenterToWorldPosition(x, z)
        self.itemDetailsMap:setMapZoom(7)
        self.itemDetailsMap:setMapAlpha(1)
    end

    if g_shopController == nil or self.attributesLayout == nil or self.detailTemplate == nil then
        return
    end

    local displayItem = g_shopController:makeDisplayItem(storeItem, vehicle, vehicle.configurations)
    if displayItem == nil or displayItem.attributeIconProfiles == nil then
        return
    end

    for index, profile in pairs(displayItem.attributeIconProfiles) do
        local element = self.detailTemplate:clone(self.attributesLayout)
        table.insert(self.elementCache, element)

        local iconElement = element:getDescendantByName("icon")
        local textElement = element:getDescendantByName("text")

        if iconElement ~= nil then
            iconElement:applyProfile(profile)
        end
        if textElement ~= nil then
            textElement:setText(displayItem.attributeValues[index] or "")
        end

        element:setVisible(true)
        if iconElement ~= nil and textElement ~= nil then
            element:setSize(textElement.size[1] + iconElement.size[1] + 0.0025, textElement.size[2])
        end
    end

    self.attributesLayout:invalidateLayout()
end

function ADS_InGameMenuFrame:getSortValue(row)
    if row == nil then
        return nil
    end

    local col = self.sortColumn
    if col == ADS_InGameMenuFrame.SORT_COLUMN.VEHICLE then
        return safeLower(row.vehicleName)
    elseif col == ADS_InGameMenuFrame.SORT_COLUMN.AGE then
        return row.ageValue or 0
    elseif col == ADS_InGameMenuFrame.SORT_COLUMN.WORKING_HOURS then
        return row.workingHoursValue or 0
    elseif col == ADS_InGameMenuFrame.SORT_COLUMN.CONDITION then
        return row.conditionValue or 0
    elseif col == ADS_InGameMenuFrame.SORT_COLUMN.INTERVAL then
        return row.intervalValue or 0
    elseif col == ADS_InGameMenuFrame.SORT_COLUMN.LAST_INSPECTION then
        return row.lastInspectionValue or -1
    elseif col == ADS_InGameMenuFrame.SORT_COLUMN.LAST_MAINTENANCE then
        return row.lastMaintenanceValue or -1
    elseif col == ADS_InGameMenuFrame.SORT_COLUMN.COST then
        return row.costValue or 0
    elseif col == ADS_InGameMenuFrame.SORT_COLUMN.LEASING_PRICE then
        return row.leasingPriceValue or 0
    elseif col == ADS_InGameMenuFrame.SORT_COLUMN.PRICE then
        return row.priceValue or 0
    end

    return safeLower(row.vehicleName)
end

function ADS_InGameMenuFrame:sortRows()
    table.sort(self.rows, function(a, b)
        local va = self:getSortValue(a)
        local vb = self:getSortValue(b)

        if va == vb then
            return safeLower(a.vehicleName) < safeLower(b.vehicleName)
        end

        if self.sortingAsc then
            return va < vb
        end
        return va > vb
    end)
end

function ADS_InGameMenuFrame:updateSortIcons()
    if self.sortIconMap == nil then
        return
    end

    for column, iconSet in pairs(self.sortIconMap) do
        local isActive = column == self.sortColumn
        if iconSet.asc ~= nil then
            iconSet.asc:setVisible(isActive and self.sortingAsc)
        end
        if iconSet.desc ~= nil then
            iconSet.desc:setVisible(isActive and not self.sortingAsc)
        end
    end
end

function ADS_InGameMenuFrame:selectSortColumn(column)
    if self.sortColumn == column then
        self.sortingAsc = not self.sortingAsc
    else
        self.sortColumn = column
        self.sortingAsc = true
    end

    self:updateSortIcons()
    self:reloadRows()
end

function ADS_InGameMenuFrame:reloadRows()
    self.rows = {}
    local mission = g_currentMission
    local currentFarmId = mission ~= nil and mission:getFarmId() or FarmManager.SPECTATOR_FARM_ID
    local totalCost = 0
    local totalLeasingPrice = 0
    local totalPrice = 0

    if ADS_Main ~= nil and ADS_Main.vehicles ~= nil then
        for _, vehicle in pairs(ADS_Main.vehicles) do
            local spec = vehicle.spec_AdvancedDamageSystem
            local hasAccess = mission ~= nil and mission.accessHandler ~= nil and mission.accessHandler:canPlayerAccess(vehicle)
            local ownerFarmId = vehicle.getOwnerFarmId ~= nil and vehicle:getOwnerFarmId() or vehicle.ownerFarmId

            if spec ~= nil
                and not spec.isExcludedVehicle
                and vehicle.getSellPrice ~= nil
                and vehicle.price ~= nil
                and hasAccess
                and ownerFarmId == currentFarmId then
                local row = buildVehicleRow(vehicle)
                totalCost = totalCost + (row.costValue or 0)
                totalLeasingPrice = totalLeasingPrice + (row.leasingPriceValue or 0)
                totalPrice = totalPrice + (row.priceValue or 0)
                table.insert(self.rows, row)
            end
        end
    end

    self:sortRows()

    if self.totalLabel ~= nil then
        self.totalLabel:setText(g_i18n:getText("ui_total"))
    end
    if self.totalCost ~= nil then
        self.totalCost:setText(g_i18n:formatMoney(totalCost, 0, true, true))
    end
    if self.totalLeasingPrice ~= nil then
        self.totalLeasingPrice:setText(totalLeasingPrice > 0 and g_i18n:formatMoney(totalLeasingPrice, 0, true, true) or "-")
    end
    if self.totalPrice ~= nil then
        self.totalPrice:setText(g_i18n:formatMoney(totalPrice, 0, true, true))
    end

    if self.vehicleList ~= nil then
        self.vehicleList:reloadData()

        if #self.rows > 0 then
            local selectedIndex = 1
            if self.selectedVehicleId ~= nil then
                for index, row in ipairs(self.rows) do
                    if row.vehicle ~= nil and row.vehicle.uniqueId == self.selectedVehicleId then
                        selectedIndex = index
                        break
                    end
                end
            end

            self.selectedRowIndex = selectedIndex
            self.vehicleList:setSelectedItem(1, selectedIndex, false, false)
            self:onListSelectionChanged(self.vehicleList, 1, selectedIndex)
        else
            self.selectedVehicleId = nil
            self.selectedRowIndex = 1
            self:updateDetailsPanel(nil)
        end
    end

    self:updateActionButtons()
end

function ADS_InGameMenuFrame:getNumberOfSections(_list)
    return 1
end

function ADS_InGameMenuFrame:getTitleForSectionHeader(_list, _section)
    return ""
end

function ADS_InGameMenuFrame:getNumberOfItemsInSection(_list, _section)
    return #self.rows
end

function ADS_InGameMenuFrame:populateCellForItemInSection(_list, _section, index, cell)
    local row = self.rows[index]
    if row == nil then
        return
    end

    local vehicleNameText = cell:getAttribute("vehicleNameText")
    local ageText = cell:getAttribute("ageText")
    local workingHoursText = cell:getAttribute("workingHoursText")
    local conditionText = cell:getAttribute("conditionText")
    local intervalText = cell:getAttribute("intervalText")
    local lastInspectionText = cell:getAttribute("lastInspectionText")
    local lastMaintenanceText = cell:getAttribute("lastMaintenanceText")
    local costText = cell:getAttribute("costText")
    local leasingPriceText = cell:getAttribute("leasingPriceText")
    local priceText = cell:getAttribute("priceText")
    local conditionColor = row.conditionColor or {1, 1, 1, 1}

    if vehicleNameText ~= nil then
        vehicleNameText:setText(row.vehicleName or "")
        vehicleNameText:setTextColor(1, 1, 1, 1)
    end
    if ageText ~= nil then
        ageText:setText(row.age or "")
        ageText:setTextColor(1, 1, 1, 1)
    end
    if workingHoursText ~= nil then
        workingHoursText:setText(row.workingHours or "")
        workingHoursText:setTextColor(1, 1, 1, 1)
    end
    if conditionText ~= nil then
        conditionText:setText(row.condition or "")
        conditionText:setTextColor(conditionColor[1], conditionColor[2], conditionColor[3], conditionColor[4])
    end
    if intervalText ~= nil then
        intervalText:setText(row.interval or "")
        intervalText:setTextColor(1, 1, 1, 1)
    end
    if lastInspectionText ~= nil then
        lastInspectionText:setText(row.lastInspection or "")
        lastInspectionText:setTextColor(1, 1, 1, 1)
    end
    if lastMaintenanceText ~= nil then
        lastMaintenanceText:setText(row.lastMaintenance or "")
        lastMaintenanceText:setTextColor(1, 1, 1, 1)
    end
    if costText ~= nil then
        costText:setText(row.cost or "")
        costText:setTextColor(1, 1, 1, 1)
    end
    if leasingPriceText ~= nil then
        leasingPriceText:setText(row.leasingPrice or "")
        leasingPriceText:setTextColor(1, 1, 1, 1)
    end
    if priceText ~= nil then
        priceText:setText(row.price or "")
        priceText:setTextColor(1, 1, 1, 1)
    end
end

function ADS_InGameMenuFrame:onListSelectionChanged(_list, _section, index)
    local row = self.rows[index]
    self.selectedRowIndex = index

    if row ~= nil and row.vehicle ~= nil then
        self.selectedVehicleId = row.vehicle.uniqueId
        self:updateDetailsPanel(row.vehicle)
    else
        self.selectedVehicleId = nil
        self:updateDetailsPanel(nil)
    end

    self:updateActionButtons()
end

function ADS_InGameMenuFrame:onClickVehicleHeader(element)
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
    self:selectSortColumn(ADS_InGameMenuFrame.SORT_COLUMN.VEHICLE)
end

function ADS_InGameMenuFrame:onClickAgeHeader(element)
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
    self:selectSortColumn(ADS_InGameMenuFrame.SORT_COLUMN.AGE)
end

function ADS_InGameMenuFrame:onClickWorkingHoursHeader(element)
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
    self:selectSortColumn(ADS_InGameMenuFrame.SORT_COLUMN.WORKING_HOURS)
end

function ADS_InGameMenuFrame:onClickConditionHeader(element)
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
    self:selectSortColumn(ADS_InGameMenuFrame.SORT_COLUMN.CONDITION)
end

function ADS_InGameMenuFrame:onClickIntervalHeader(element)
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
    self:selectSortColumn(ADS_InGameMenuFrame.SORT_COLUMN.INTERVAL)
end

function ADS_InGameMenuFrame:onClickLastInspectionHeader(element)
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
    self:selectSortColumn(ADS_InGameMenuFrame.SORT_COLUMN.LAST_INSPECTION)
end

function ADS_InGameMenuFrame:onClickLastMaintenanceHeader(element)
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
    self:selectSortColumn(ADS_InGameMenuFrame.SORT_COLUMN.LAST_MAINTENANCE)
end

function ADS_InGameMenuFrame:onClickCostHeader(element)
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
    self:selectSortColumn(ADS_InGameMenuFrame.SORT_COLUMN.COST)
end

function ADS_InGameMenuFrame:onClickLeasingPriceHeader(element)
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
    self:selectSortColumn(ADS_InGameMenuFrame.SORT_COLUMN.LEASING_PRICE)
end

function ADS_InGameMenuFrame:onClickPriceHeader(element)
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
    self:selectSortColumn(ADS_InGameMenuFrame.SORT_COLUMN.PRICE)
end

function ADS_InGameMenuFrame:onVehicleViewOnMap()
    local row = self.rows[self.selectedRowIndex]
    local vehicle = row ~= nil and row.vehicle or nil
    local hotspot = vehicle ~= nil and vehicle.getMapHotspot ~= nil and vehicle:getMapHotspot() or nil

    if hotspot ~= nil and g_inGameMenu ~= nil and g_inGameMenu.pageMapOverview ~= nil then
        g_gui:showGui("")
        g_inGameMenu:openMapOverview()
        g_inGameMenu.pageMapOverview:showMapHotspot(hotspot)
    end
end

function ADS_InGameMenuFrame:onTryEnterVehicle()
    local vehicle = self:getSelectedVehicle()
    if vehicle ~= nil and vehicle.getIsEnterableFromMenu ~= nil and vehicle:getIsEnterableFromMenu() then
        g_gui:showGui("")
        g_localPlayer:requestToEnterVehicle(vehicle)
    end
end

function ADS_InGameMenuFrame:onSellSelectedVehicle()
    local vehicle = self:getSelectedVehicle()
    if vehicle == nil then
        return
    end

    local isLeased = vehicle.propertyState == 3
    local label = g_i18n:getText(isLeased and "ui_youWantToReturnVehicle" or "ui_youWantToSellVehicle")

    YesNoDialog.show(function(target, clickOk)
        if not clickOk then
            return
        end

        g_client:getServerConnection():sendEvent(SellVehicleEvent.new(vehicle, 1, true))
        InfoDialog.show(g_i18n:getText(isLeased and "shop_messageReturnedVehicle" or "shop_messageSoldVehicle"))
    end, self, label)
end

function ADS_InGameMenuFrame:onShowMaintenanceLog()
    local vehicle = self:getSelectedVehicle()
    local spec = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    if spec == nil then
        return
    end

    if #spec.maintenanceLog > 1 then
        ADS_MaintenanceLogDialog.show(vehicle)
    else
        InfoDialog.show(g_i18n:getText("ads_ws_no_log_empty_message"))
    end
end

function ADS_InGameMenuFrame:onShowLastReport()
    local vehicle = self:getSelectedVehicle()
    local spec = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    if spec == nil then
        return
    end

    for i = #spec.maintenanceLog, 1, -1 do
        local entry = spec.maintenanceLog[i]
        if AdvancedDamageSystem.getIsLogEntryHasReport(entry) then
            ADS_ReportDialog.show(vehicle, entry)
            return
        end
    end

    InfoDialog.show(g_i18n:getText("ads_ws_no_last_report_message"))
end
