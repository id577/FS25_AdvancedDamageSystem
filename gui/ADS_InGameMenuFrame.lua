ADS_InGameMenuFrame = {}
ADS_InGameMenuFrame.MOD_DIR = g_currentModDirectory
ADS_InGameMenuFrame.PAGE_NAME = "pageADSFleet"
ADS_InGameMenuFrame.REFRESH_INTERVAL_MS = 1000
ADS_InGameMenuFrame.SUB_CATEGORY = {
    ACTIVE = 1,
    SERVICE = 2,
    OTHER = 3
}
ADS_InGameMenuFrame.SORT_COLUMN = {
    VEHICLE = "vehicle",
    VEHICLE_TYPE = "vehicleType",
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

local function getLocalizedStoreCategoryTitle(vehicle)
    if vehicle == nil or g_storeManager == nil or g_storeManager.getItemByXMLFilename == nil then
        return ""
    end

    local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
    if storeItem == nil or storeItem.categoryName == nil then
        return ""
    end

    if g_storeManager.getCategoryByName ~= nil then
        local category = g_storeManager:getCategoryByName(storeItem.categoryName)
        if category ~= nil and category.title ~= nil then
            return tostring(category.title)
        end
    end

    return tostring(storeItem.categoryName or "")
end

local function getVehicleOperatingHoursValue(vehicle)
    if vehicle == nil then
        return 0
    end

    if vehicle.getFormattedOperatingTime ~= nil then
        return tonumber(vehicle:getFormattedOperatingTime()) or 0
    end

    local operatingTimeMs = tonumber(vehicle.getOperatingTime ~= nil and vehicle:getOperatingTime() or vehicle.operatingTime or 0) or 0
    local minutes = operatingTimeMs / (1000 * 60)
    local hours = math.floor(minutes / 60)
    local tenths = math.floor((minutes - hours * 60) / 6)

    return tonumber(string.format("%d.%02d", hours, tenths * 10)) or 0
end

local function formatVehicleOperatingHours(vehicle)
    return string.format("%s %s", getVehicleOperatingHoursValue(vehicle), g_i18n:getText("ads_ws_hours_unit"))
end

local function buildVehicleRow(vehicle)
    local conditionValue, isCompleteInspection = vehicle:getLastInspectedCondition()
    local totalCost = getVehicleTotalCost(vehicle)
    local currentValue = math.min(
        math.floor(vehicle:getSellPrice()),
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
    local operatingHours = getVehicleOperatingHoursValue(vehicle)
    local intervalColor = {1, 1, 1, 1}
    local intervalRatio = intervalTotal ~= nil and intervalTotal > 0 and ((intervalCurrent or 0) / intervalTotal) or 0

    if isLeased then
        leasingPriceValue = (vehicle.price or vehicle:getPrice()) * (
            EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR + EconomyManager.PER_DAY_LEASING_FACTOR
        )
        priceText = "-"
        priceValue = 0
    end

    if intervalRatio > 1.0 then
        intervalColor = {0.88, 0.18, 0.18, 1}
    elseif intervalRatio > 0.8 then
        intervalColor = {1.0, 0.55, 0.0, 1}
    end

    return {
        vehicle = vehicle,
        vehicleName = vehicle:getFullName() or "",
        vehicleType = getLocalizedStoreCategoryTitle(vehicle),
        age = string.format("%d %s", vehicle.age or 0, g_i18n:getText("ads_ws_age_unit")),
        ageValue = vehicle.age or 0,
        workingHours = formatVehicleOperatingHours(vehicle),
        workingHoursValue = operatingHours,
        condition = ADS_Utils.formatCondition(conditionValue, isCompleteInspection),
        conditionValue = conditionValue or 0,
        conditionColor = {ADS_Utils.getValueColor(conditionValue, 0.8, 0.6, 0.4, 0.2, false)},
        interval = ADS_Utils.formatOperatingHours(intervalCurrent, intervalTotal),
        intervalValue = intervalCurrent or 0,
        intervalColor = intervalColor,
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

local function buildServiceRow(vehicle)
    local baseRow = buildVehicleRow(vehicle)
    local spec = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    local currentState = spec ~= nil and spec.currentState or nil
    local finishTime, daysToAdd = vehicle:getServiceFinishTime()
    local duration = vehicle:getServiceDuration()
    local pendingServicePrice = spec ~= nil and spec.pendingServicePrice or nil
    local optionOne = spec ~= nil and spec.serviceOptionOne or nil
    local optionTwo = spec ~= nil and spec.serviceOptionTwo or nil
    local optionThree = spec ~= nil and spec.serviceOptionThree or false

    if (pendingServicePrice == nil or pendingServicePrice <= 0)
        and currentState ~= nil
        and vehicle.getServicePrice ~= nil then
        pendingServicePrice = vehicle:getServicePrice(currentState, optionOne, optionTwo, optionThree)
    end

    baseRow.procedure = currentState ~= nil and g_i18n:getText(currentState) or ""
    baseRow.remainingTime = ADS_Utils.formatDuration(duration)
    baseRow.finishTime = ADS_Utils.formatFinishTime(finishTime, daysToAdd)
    baseRow.serviceCost = g_i18n:formatMoney(pendingServicePrice or 0, 0, true, true)
    baseRow.serviceCostValue = pendingServicePrice or 0

    return baseRow
end

local function buildOtherVehicleRow(vehicle)
    local currentValue = math.min(
        math.floor(vehicle:getSellPrice()),
        vehicle:getPrice()
    )
    local isLeased = vehicle.propertyState == 3
    local leasingPriceValue = 0
    local priceText = g_i18n:formatMoney(currentValue, 0, true, true)
    local priceValue = currentValue
    local operatingHours = getVehicleOperatingHoursValue(vehicle)
    local damageAmount = tonumber(vehicle.getDamageAmount ~= nil and vehicle:getDamageAmount() or vehicle.damageAmount or 0) or 0
    local conditionValue = math.clamp(1 - damageAmount, 0, 1)

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
        vehicleType = getLocalizedStoreCategoryTitle(vehicle),
        age = string.format("%d %s", vehicle.age or 0, g_i18n:getText("ads_ws_age_unit")),
        ageValue = vehicle.age or 0,
        workingHours = formatVehicleOperatingHours(vehicle),
        workingHoursValue = operatingHours,
        condition = string.format("%s%%", g_i18n:formatNumber(conditionValue * 100, 0)),
        conditionValue = conditionValue,
        conditionColor = {ADS_Utils.getValueColor(conditionValue, 0.8, 0.6, 0.4, 0.2, false)},
        interval = "-",
        intervalValue = -1,
        intervalColor = {1, 1, 1, 1},
        lastInspection = "-",
        lastInspectionValue = -1,
        lastMaintenance = "-",
        lastMaintenanceValue = -1,
        cost = "-",
        costValue = -1,
        leasingPrice = leasingPriceValue > 0 and g_i18n:formatMoney(leasingPriceValue, 0, true, true) or "-",
        leasingPriceValue = leasingPriceValue,
        price = priceText,
        priceValue = priceValue
    }
end

local function canDisplayOwnedVehicle(mission, vehicle, currentFarmId)
    if vehicle == nil
        or vehicle.getSellPrice == nil
        or vehicle.getPrice == nil
        or vehicle.price == nil
        or vehicle.getFullName == nil then
        return false
    end

    local hasAccess = mission ~= nil and mission.accessHandler ~= nil and mission.accessHandler:canPlayerAccess(vehicle)
    local ownerFarmId = vehicle.getOwnerFarmId ~= nil and vehicle:getOwnerFarmId() or vehicle.ownerFarmId

    return hasAccess
        and ownerFarmId == currentFarmId
        and (vehicle.propertyState == 2 or vehicle.propertyState == 3 or vehicle.propertyState == 4)
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
    self.serviceRows = {}
    self.otherRows = {}
    self.refreshTimerMs = 0
    self.selectedVehicleId = nil
    self.selectedRowIndex = 1
    self.selectedServiceRowIndex = 1
    self.selectedOtherRowIndex = 1
    self.subCategoryState = ADS_InGameMenuFrame.SUB_CATEGORY.ACTIVE
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

function ADS_InGameMenuFrame:updateBalanceDisplay()
    if self.balanceElement == nil or self.balanceTitleElement == nil or self.moneyBox == nil or self.moneyBoxBg == nil then
        return
    end

    local balanceText = g_i18n:formatMoney(math.floor(g_currentMission:getMoney()), 2, true, true)
    self.balanceElement:setText(balanceText)

    ADS_Utils.updateMoneyBoxLayout(
        self.balanceTitleElement,
        self.balanceElement,
        self.moneyBox,
        self.moneyBoxBg,
        g_i18n:getText("ui_balance"),
        balanceText
    )
end

function ADS_InGameMenuFrame:initialize()
    ADS_InGameMenuFrame:superClass().initialize(self)

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
        inputAction = InputAction.MENU_ACTIVATE,
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

    if self.subCategoryTabs ~= nil then
        for i, tab in pairs(self.subCategoryTabs) do
            local background = tab:getDescendantByName("background")
            if background ~= nil then
                background.getIsSelected = function()
                    return i == self:getCurrentSubCategory()
                end
            end

            function tab.getIsSelected()
                return i == self:getCurrentSubCategory()
            end
        end
    end

    if self.subCategoryPaging ~= nil then
        self.subCategoryPaging:setTexts({"1", "2", "3"})
        self.subCategoryPaging:setState(self.subCategoryState, false)
    end

    if self.subCategoryBox ~= nil then
        self.subCategoryBox:invalidateLayout()
    end

    if self.vehicleList ~= nil then
        self.vehicleList:setDataSource(self)
        self.vehicleList:setDelegate(self)
    end
    if self.serviceVehicleList ~= nil then
        self.serviceVehicleList:setDataSource(self)
        self.serviceVehicleList:setDelegate(self)
    end
    if self.otherVehicleList ~= nil then
        self.otherVehicleList:setDataSource(self)
        self.otherVehicleList:setDelegate(self)
    end

    self.sortIconMap = {
        [ADS_InGameMenuFrame.SORT_COLUMN.VEHICLE] = {asc = self.iconVehicleAscending, desc = self.iconVehicleDescending},
        [ADS_InGameMenuFrame.SORT_COLUMN.VEHICLE_TYPE] = {asc = self.iconTypeAscending, desc = self.iconTypeDescending},
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
    self:updateBalanceDisplay()
    self:updateSortIcons()
    self:updateSubCategoryPages(self.subCategoryState)
    self:updateActionButtons()
    self:reloadRows()
end

function ADS_InGameMenuFrame:getCurrentSubCategory()
    if self.subCategoryPaging ~= nil and self.subCategoryPaging.getState ~= nil then
        return self.subCategoryPaging:getState()
    end

    return self.subCategoryState or ADS_InGameMenuFrame.SUB_CATEGORY.ACTIVE
end

function ADS_InGameMenuFrame:updateSubCategoryPages(subCategoryIndex)
    if subCategoryIndex ~= nil then
        self.subCategoryState = subCategoryIndex
    end

    local state = self:getCurrentSubCategory()

    if self.subCategoryPages ~= nil then
        for index, page in pairs(self.subCategoryPages) do
            page:setVisible(index == state)
        end
    end

    self:updateEmptyStates()
    self:updateDetailsForCurrentSection()
    self:updateActionButtons()
    self:setMenuButtonInfoDirty()
end

function ADS_InGameMenuFrame:onFrameOpen()
    if self.subCategoryBox ~= nil and self.subCategoryPaging ~= nil and self.subCategoryTabs ~= nil then
        local texts = {}
        for index, tab in pairs(self.subCategoryTabs) do
            tab:setVisible(true)
            table.insert(texts, tostring(index))
        end

        self.subCategoryBox:invalidateLayout()
        self.subCategoryPaging:setTexts(texts)
        self.subCategoryPaging:setSize(self.subCategoryBox.maxFlowSize + 140 * g_pixelSizeScaledX)
        self.subCategoryPaging:setState(self.subCategoryState, false)
    end

    self:updateSubCategoryPages(self:getCurrentSubCategory())

    if self.detailBox ~= nil then
        self.detailBox:setVisible(true)
    end
    if self.itemDetailsMap ~= nil and g_currentMission ~= nil and g_currentMission.hud ~= nil then
        self.itemDetailsMap:setIngameMap(g_currentMission.hud:getIngameMap())
    end

    ADS_InGameMenuFrame:superClass().onFrameOpen(self)
    self.refreshTimerMs = 0
    self:updateBalanceDisplay()
    self:reloadRows()
end

function ADS_InGameMenuFrame:onFrameClose()
    if self.vehicleList ~= nil then
        self.vehicleList.selectedIndex = 1
    end
    if self.serviceVehicleList ~= nil then
        self.serviceVehicleList.selectedIndex = 1
    end
    if self.otherVehicleList ~= nil then
        self.otherVehicleList.selectedIndex = 1
    end
    self.selectedServiceRowIndex = 1
    self.selectedOtherRowIndex = 1
    ADS_InGameMenuFrame:superClass().onFrameClose(self)
end

function ADS_InGameMenuFrame:getSelectedVehicle()
    local state = self:getCurrentSubCategory()
    local row = nil

    if state == ADS_InGameMenuFrame.SUB_CATEGORY.SERVICE then
        row = self.serviceRows[self.selectedServiceRowIndex]
    elseif state == ADS_InGameMenuFrame.SUB_CATEGORY.OTHER then
        row = self.otherRows[self.selectedOtherRowIndex]
    else
        row = self.rows[self.selectedRowIndex]
    end

    return row ~= nil and row.vehicle or nil
end

function ADS_InGameMenuFrame:updateActionButtons()
    local currentSection = self:getCurrentSubCategory()
    local isVehicleSection = currentSection == ADS_InGameMenuFrame.SUB_CATEGORY.ACTIVE
        or currentSection == ADS_InGameMenuFrame.SUB_CATEGORY.OTHER
    local isADSSection = currentSection == ADS_InGameMenuFrame.SUB_CATEGORY.ACTIVE
        or currentSection == ADS_InGameMenuFrame.SUB_CATEGORY.SERVICE
    local vehicle = self:getSelectedVehicle()
    local hasVehicle = isVehicleSection and vehicle ~= nil
    local hasADSVehicle = isADSSection and vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil
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
        self.maintenanceLogButtonInfo.disabled = not hasADSVehicle
    end

    self:setMenuButtonInfo({
        self.backButtonInfo,
        self.prevPageButtonInfo,
        self.nextPageButtonInfo,
        self.maintenanceLogButtonInfo,
        self.enterVehicleButtonInfo,
        self.sellVehicleButtonInfo
    })
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

function ADS_InGameMenuFrame:updateDetailsForCurrentSection()
    local row = nil

    if self:getCurrentSubCategory() == ADS_InGameMenuFrame.SUB_CATEGORY.SERVICE then
        row = self.serviceRows[self.selectedServiceRowIndex]
    elseif self:getCurrentSubCategory() == ADS_InGameMenuFrame.SUB_CATEGORY.OTHER then
        row = self.otherRows[self.selectedOtherRowIndex]
    else
        row = self.rows[self.selectedRowIndex]
    end

    if row ~= nil and row.vehicle ~= nil then
        self.selectedVehicleId = row.vehicle.uniqueId
        self:updateDetailsPanel(row.vehicle)
    else
        self.selectedVehicleId = nil
        self:updateDetailsPanel(nil)
    end
end

function ADS_InGameMenuFrame:updateEmptyStates()
    local activeHasItems = #self.rows > 0
    local serviceHasItems = #self.serviceRows > 0
    local otherHasItems = #self.otherRows > 0

    if self.activeTableHeader ~= nil then
        self.activeTableHeader:setVisible(activeHasItems)
    end
    if self.vehicleList ~= nil then
        self.vehicleList:setVisible(activeHasItems)
    end
    if self.activeTableSliderBox ~= nil then
        self.activeTableSliderBox:setVisible(activeHasItems)
    end
    if self.activeTableFooter ~= nil then
        self.activeTableFooter:setVisible(activeHasItems)
    end
    if self.activeEmptyTableText ~= nil then
        self.activeEmptyTableText:setVisible(not activeHasItems)
    end

    if self.serviceTableHeader ~= nil then
        self.serviceTableHeader:setVisible(serviceHasItems)
    end
    if self.serviceVehicleList ~= nil then
        self.serviceVehicleList:setVisible(serviceHasItems)
    end
    if self.serviceTableSliderBox ~= nil then
        self.serviceTableSliderBox:setVisible(serviceHasItems)
    end
    if self.serviceTableFooter ~= nil then
        self.serviceTableFooter:setVisible(serviceHasItems)
    end
    if self.serviceEmptyTableText ~= nil then
        self.serviceEmptyTableText:setVisible(not serviceHasItems)
    end

    if self.otherTableHeader ~= nil then
        self.otherTableHeader:setVisible(otherHasItems)
    end
    if self.otherVehicleList ~= nil then
        self.otherVehicleList:setVisible(otherHasItems)
    end
    if self.otherTableSliderBox ~= nil then
        self.otherTableSliderBox:setVisible(otherHasItems)
    end
    if self.otherTableFooter ~= nil then
        self.otherTableFooter:setVisible(otherHasItems)
    end
    if self.otherEmptyTableText ~= nil then
        self.otherEmptyTableText:setVisible(not otherHasItems)
    end
end

function ADS_InGameMenuFrame:getSortValue(row)
    if row == nil then
        return nil
    end

    local col = self.sortColumn
    if col == ADS_InGameMenuFrame.SORT_COLUMN.VEHICLE then
        return safeLower(row.vehicleName)
    elseif col == ADS_InGameMenuFrame.SORT_COLUMN.VEHICLE_TYPE then
        return safeLower(row.vehicleType)
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
    self.serviceRows = {}
    self.otherRows = {}
    local mission = g_currentMission
    local currentFarmId = mission ~= nil and mission:getFarmId() or FarmManager.SPECTATOR_FARM_ID
    local serviceStates = {
        [AdvancedDamageSystem.STATUS.INSPECTION] = true,
        [AdvancedDamageSystem.STATUS.MAINTENANCE] = true,
        [AdvancedDamageSystem.STATUS.REPAIR] = true,
        [AdvancedDamageSystem.STATUS.OVERHAUL] = true
    }

    self:updateBalanceDisplay()

    if ADS_Main ~= nil and ADS_Main.vehicles ~= nil then
        for _, vehicle in pairs(ADS_Main.vehicles) do
            local spec = vehicle.spec_AdvancedDamageSystem

            if spec ~= nil
                and not spec.isExcludedVehicle
                and canDisplayOwnedVehicle(mission, vehicle, currentFarmId) then
                local row = buildVehicleRow(vehicle)
                table.insert(self.rows, row)

                if serviceStates[spec.currentState] then
                    table.insert(self.serviceRows, buildServiceRow(vehicle))
                end
            end
        end
    end

    if mission ~= nil and mission.vehicleSystem ~= nil and mission.vehicleSystem.vehicles ~= nil then
        for _, vehicle in pairs(mission.vehicleSystem.vehicles) do
            if canDisplayOwnedVehicle(mission, vehicle, currentFarmId)
                and (vehicle.spec_AdvancedDamageSystem == nil or (vehicle.spec_AdvancedDamageSystem ~= nil and vehicle.spec_AdvancedDamageSystem.isExcludedVehicle == true)) then
                table.insert(self.otherRows, buildOtherVehicleRow(vehicle))
            end
        end
    end

    self:sortRows()
    table.sort(self.otherRows, function(a, b)
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
        else
            self.selectedRowIndex = 1
        end
    end

    if self.serviceVehicleList ~= nil then
        self.serviceVehicleList:reloadData()

        if #self.serviceRows > 0 then
            local selectedIndex = 1
            if self.selectedVehicleId ~= nil then
                for index, row in ipairs(self.serviceRows) do
                    if row.vehicle ~= nil and row.vehicle.uniqueId == self.selectedVehicleId then
                        selectedIndex = index
                        break
                    end
                end
            end

            self.selectedServiceRowIndex = selectedIndex
            self.serviceVehicleList:setSelectedItem(1, selectedIndex, false, false)
        else
            self.selectedServiceRowIndex = 1
        end
    end
    if self.otherVehicleList ~= nil then
        self.otherVehicleList:reloadData()

        if #self.otherRows > 0 then
            local selectedIndex = 1
            if self.selectedVehicleId ~= nil then
                for index, row in ipairs(self.otherRows) do
                    if row.vehicle ~= nil and row.vehicle.uniqueId == self.selectedVehicleId then
                        selectedIndex = index
                        break
                    end
                end
            end

            self.selectedOtherRowIndex = selectedIndex
            self.otherVehicleList:setSelectedItem(1, selectedIndex, false, false)
        else
            self.selectedOtherRowIndex = 1
        end
    end

    self:updateEmptyStates()
    self:updateDetailsForCurrentSection()
    self:updateActionButtons()
end

function ADS_InGameMenuFrame:getNumberOfSections(_list)
    return 1
end

function ADS_InGameMenuFrame:getTitleForSectionHeader(_list, _section)
    return ""
end

function ADS_InGameMenuFrame:getNumberOfItemsInSection(_list, _section)
    if _list == self.serviceVehicleList then
        return #self.serviceRows
    elseif _list == self.otherVehicleList then
        return #self.otherRows
    end

    return #self.rows
end

function ADS_InGameMenuFrame:populateCellForItemInSection(_list, _section, index, cell)
    local row = nil
    if _list == self.serviceVehicleList then
        row = self.serviceRows[index]
    elseif _list == self.otherVehicleList then
        row = self.otherRows[index]
    else
        row = self.rows[index]
    end

    if row == nil then
        return
    end

    local vehicleNameText = cell:getAttribute("vehicleNameText")
    local vehicleTypeText = cell:getAttribute("vehicleTypeText")
    local ageText = cell:getAttribute("ageText")
    local workingHoursText = cell:getAttribute("workingHoursText")
    local conditionText = cell:getAttribute("conditionText")
    local intervalText = cell:getAttribute("intervalText")
    local lastInspectionText = cell:getAttribute("lastInspectionText")
    local lastMaintenanceText = cell:getAttribute("lastMaintenanceText")
    local costText = cell:getAttribute("costText")
    local leasingPriceText = cell:getAttribute("leasingPriceText")
    local priceText = cell:getAttribute("priceText")
    local procedureText = cell:getAttribute("procedureText")
    local remainingTimeText = cell:getAttribute("remainingTimeText")
    local finishTimeText = cell:getAttribute("finishTimeText")
    local serviceCostText = cell:getAttribute("serviceCostText")
    local conditionColor = row.conditionColor or {1, 1, 1, 1}
    local intervalColor = row.intervalColor or {1, 1, 1, 1}

    if vehicleNameText ~= nil then
        vehicleNameText:setText(row.vehicleName or "")
        vehicleNameText:setTextColor(1, 1, 1, 1)
    end
    if vehicleTypeText ~= nil then
        vehicleTypeText:setText(row.vehicleType or "")
        vehicleTypeText:setTextColor(1, 1, 1, 1)
    end
    if ageText ~= nil then
        ageText:setText(row.age or "")
        ageText:setTextColor(1, 1, 1, 1)
    end
    if workingHoursText ~= nil then
        workingHoursText:setText(row.workingHours or "")
        workingHoursText:setTextColor(1, 1, 1, 1)
    end
    if procedureText ~= nil then
        procedureText:setText(row.procedure or "")
        procedureText:setTextColor(1, 1, 1, 1)
    end
    if remainingTimeText ~= nil then
        remainingTimeText:setText(row.remainingTime or "")
        remainingTimeText:setTextColor(1, 1, 1, 1)
    end
    if finishTimeText ~= nil then
        finishTimeText:setText(row.finishTime or "")
        finishTimeText:setTextColor(1, 1, 1, 1)
    end
    if serviceCostText ~= nil then
        serviceCostText:setText(row.serviceCost or "")
        serviceCostText:setTextColor(1, 1, 1, 1)
    end
    if conditionText ~= nil then
        conditionText:setText(row.condition or "")
        conditionText:setTextColor(conditionColor[1], conditionColor[2], conditionColor[3], conditionColor[4])
    end
    if intervalText ~= nil then
        intervalText:setText(row.interval or "")
        intervalText:setTextColor(intervalColor[1], intervalColor[2], intervalColor[3], intervalColor[4])
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
    local row = nil

    if _list == self.serviceVehicleList then
        self.selectedServiceRowIndex = index
        row = self.serviceRows[index]
    elseif _list == self.otherVehicleList then
        self.selectedOtherRowIndex = index
        row = self.otherRows[index]
    else
        self.selectedRowIndex = index
        row = self.rows[index]
    end

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

function ADS_InGameMenuFrame:onClickActiveSection()
    if self.subCategoryPaging ~= nil then
        self.subCategoryPaging:setState(ADS_InGameMenuFrame.SUB_CATEGORY.ACTIVE, true)
    end

    self:updateSubCategoryPages(ADS_InGameMenuFrame.SUB_CATEGORY.ACTIVE)
end

function ADS_InGameMenuFrame:onClickServiceSection()
    if self.subCategoryPaging ~= nil then
        self.subCategoryPaging:setState(ADS_InGameMenuFrame.SUB_CATEGORY.SERVICE, true)
    end

    self:updateSubCategoryPages(ADS_InGameMenuFrame.SUB_CATEGORY.SERVICE)
end

function ADS_InGameMenuFrame:onClickOtherSection()
    if self.subCategoryPaging ~= nil then
        self.subCategoryPaging:setState(ADS_InGameMenuFrame.SUB_CATEGORY.OTHER, true)
    end

    self:updateSubCategoryPages(ADS_InGameMenuFrame.SUB_CATEGORY.OTHER)
end

function ADS_InGameMenuFrame:onClickTypeHeader(element)
    self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
    self:selectSortColumn(ADS_InGameMenuFrame.SORT_COLUMN.VEHICLE_TYPE)
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

    local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
    if storeItem == nil then
        return
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    local isLeased = vehicle.propertyState == 3

    if spec ~= nil and not spec.isExcludedVehicle and isLeased then
        ADS_SellItemDialog.show(vehicle, storeItem, self.onADSSellDialogCallback, self)
        return
    end

    g_shopController:sell(storeItem, vehicle)
end

function ADS_InGameMenuFrame:onADSSellDialogCallback(yes)
    if not yes then
        return
    end

    local vehicle = self:getSelectedVehicle()
    if vehicle == nil then
        return
    end

    g_client:getServerConnection():sendEvent(SellVehicleEvent.new(vehicle, 1, true))
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
