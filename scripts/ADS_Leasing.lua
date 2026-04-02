ADS_Leasing = {}

local function getNumber(value, fallback)
    local numericValue = tonumber(value)
    if numericValue == nil then
        return fallback or 0
    end

    return numericValue
end

function ADS_Leasing.hasExtendedLeasing()
    return g_modIsLoaded ~= nil and g_modIsLoaded["FS25_ExtendedLeasing"] == true
end

function ADS_Leasing.preLoad(_mission)
    SellVehicleEvent.run = Utils.overwrittenFunction(SellVehicleEvent.run, ADS_Leasing.onSellVehicleEventRun)
end

function ADS_Leasing.init()
    Mission00.load = Utils.prependedFunction(Mission00.load, ADS_Leasing.preLoad)
end

function ADS_Leasing.isADSVehicle(vehicle)
    return vehicle ~= nil
        and vehicle.spec_AdvancedDamageSystem ~= nil
        and not vehicle.spec_AdvancedDamageSystem.isExcludedVehicle
end

function ADS_Leasing.isLeasedVehicle(vehicle)
    if vehicle == nil then
        return false
    end

    local leasedState = Vehicle ~= nil and Vehicle.PROPERTY_STATE_LEASED or 3
    return vehicle.propertyState == leasedState
end

function ADS_Leasing.isSupportedVehicle(vehicle)
    return ADS_Leasing.isADSVehicle(vehicle) and ADS_Leasing.isLeasedVehicle(vehicle)
end

function ADS_Leasing.getReturnBreakdown(vehicle)
    local emptyResult = {
        vehicle = vehicle,
        hasExtendedLeasing = ADS_Leasing.hasExtendedLeasing(),
        raw = {
            depositReturn = 0,
            overdueMaintenance = 0,
            repair = 0,
            washing = 0
        },
        display = {
            depositReturn = 0,
            overdueMaintenance = 0,
            repair = 0,
            washing = 0,
            total = 0
        },
        charge = {
            depositReturn = 0,
            overdueMaintenance = 0,
            repair = 0,
            washing = 0,
            total = 0
        },
        rows = {
            { label = "ads_sell_dialog_deposit_return", key = "depositReturn", value = 0 },
            { label = "ads_sell_dialog_overdue_maintenance_penalty", key = "overdueMaintenance", value = 0 },
            { label = "ads_sell_dialog_repair_penalty", key = "repair", value = 0 },
            { label = "ads_sell_dialog_washing_penalty", key = "washing", value = 0 }
        }
    }

    if not ADS_Leasing.isADSVehicle(vehicle) then
        return emptyResult
    end

    local ads = AdvancedDamageSystem
    local hasExtendedLeasing = ADS_Leasing.hasExtendedLeasing()
    local vehiclePrice = getNumber(vehicle.getPrice ~= nil and vehicle:getPrice(), 0)
    local depositReturn = MathUtil.round(vehiclePrice * EconomyManager.DEFAULT_LEASING_DEPOSIT_FACTOR, 0)
    local dirtAmount = math.min(getNumber(vehicle.getDirtAmount ~= nil and vehicle:getDirtAmount(), 0), 1)
    local washingCost = depositReturn * 0.3 * dirtAmount
    local serviceLevel = getNumber(vehicle.getServiceLevel ~= nil and vehicle:getServiceLevel(), ADS_Config.CORE.SERVICE_EXPIRED_THRESHOLD)
    local serviceExpiredThreshold = math.max(getNumber(ADS_Config.CORE.SERVICE_EXPIRED_THRESHOLD, 0), 0.0001)
    local overdueMaintenanceRatio = math.max(serviceExpiredThreshold - serviceLevel, 0) * (1 / serviceExpiredThreshold)
    local overdueMaintenanceCost = overdueMaintenanceRatio * getNumber(
        vehicle.getServicePrice ~= nil and vehicle:getServicePrice(
            ads.STATUS.MAINTENANCE,
            ads.MAINTENANCE_TYPES.STANDARD,
            ads.PART_TYPES.OEM,
            false,
            ads.WORKSHOP.DEALER
        ),
        0
    )
    local repairCost = getNumber(
        vehicle.getServicePrice ~= nil and vehicle:getServicePrice(
            ads.STATUS.REPAIR,
            ads.REPAIR_TYPES.MEDIUM,
            ads.PART_TYPES.OEM,
            false,
            ads.WORKSHOP.DEALER,
            true
        ),
        0
    )

    emptyResult.hasExtendedLeasing = hasExtendedLeasing
    emptyResult.raw.depositReturn = depositReturn
    emptyResult.raw.overdueMaintenance = overdueMaintenanceCost
    emptyResult.raw.repair = repairCost
    emptyResult.raw.washing = washingCost

    emptyResult.display.depositReturn = depositReturn
    emptyResult.display.overdueMaintenance = -overdueMaintenanceCost
    emptyResult.display.repair = -repairCost
    emptyResult.display.washing = -washingCost
    emptyResult.display.total = emptyResult.display.depositReturn
        + emptyResult.display.overdueMaintenance
        + emptyResult.display.repair
        + emptyResult.display.washing

    if hasExtendedLeasing then
        emptyResult.charge.depositReturn = 0
        emptyResult.charge.washing = 0
    else
        emptyResult.charge.depositReturn = depositReturn
        emptyResult.charge.washing = -washingCost
    end

    emptyResult.charge.overdueMaintenance = -overdueMaintenanceCost
    emptyResult.charge.repair = -repairCost
    emptyResult.charge.total = emptyResult.charge.depositReturn
        + emptyResult.charge.overdueMaintenance
        + emptyResult.charge.repair
        + emptyResult.charge.washing

    emptyResult.rows[1].value = emptyResult.display.depositReturn
    emptyResult.rows[2].value = emptyResult.display.overdueMaintenance
    emptyResult.rows[3].value = emptyResult.display.repair
    emptyResult.rows[4].value = emptyResult.display.washing

    return emptyResult
end

function ADS_Leasing.onSellVehicleEventRun(self, overwrittenFunc, connection)
    local vehicle = self.vehicle
    local ownerFarmId = vehicle ~= nil and vehicle:getOwnerFarmId() or FarmManager.SPECTATOR_FARM_ID
    local hasPermission = vehicle ~= nil
        and g_currentMission:getHasPlayerPermission(Farm.PERMISSION.SELL_VEHICLE, connection, ownerFarmId)
    local isVehicleInUse = vehicle ~= nil and vehicle:getIsInUse(connection)
    local shouldApplyCharges = ADS_Leasing.isSupportedVehicle(vehicle)
        and hasPermission
        and not isVehicleInUse

    overwrittenFunc(self, connection)

    if connection:getIsServer() or not shouldApplyCharges or vehicle == nil then
        return
    end

    local farm = g_farmManager:getFarmById(ownerFarmId)
    if ownerFarmId == nil or ownerFarmId == FarmManager.SPECTATOR_FARM_ID or farm == nil then
        return
    end

    local breakdown = ADS_Leasing.getReturnBreakdown(vehicle)
    if breakdown == nil or breakdown.charge == nil then
        return
    end

    local changes = {
        { value = breakdown.charge.depositReturn, moneyType = MoneyType.VEHICLE_RUNNING_COSTS },
        { value = breakdown.charge.overdueMaintenance, moneyType = MoneyType.VEHICLE_RUNNING_COSTS },
        { value = breakdown.charge.repair, moneyType = MoneyType.VEHICLE_RUNNING_COSTS },
        { value = breakdown.charge.washing, moneyType = MoneyType.VEHICLE_RUNNING_COSTS }
    }

    for _, change in ipairs(changes) do
        local value = getNumber(change.value, 0)
        if value ~= 0 and change.moneyType ~= nil then
            farm:changeBalance(value, change.moneyType)
            g_currentMission:addMoneyChange(value, ownerFarmId, change.moneyType, true)
        end
    end
end

ADS_Leasing.init()
