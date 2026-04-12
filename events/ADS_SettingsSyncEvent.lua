-- ADS_SettingsSyncEvent
-- Client-to-server event. Replicates all adjustable ADS_Config values
-- from the admin client to the dedicated server so both machines share
-- identical tuning.  Sent once after every in-game settings change.

ADS_SettingsSyncEvent = {}
local ADS_SettingsSyncEvent_mt = Class(ADS_SettingsSyncEvent, Event)

InitEventClass(ADS_SettingsSyncEvent, "ADS_SettingsSyncEvent")


function ADS_SettingsSyncEvent.emptyNew()
    return Event.new(ADS_SettingsSyncEvent_mt)
end


function ADS_SettingsSyncEvent.new()
    local self = ADS_SettingsSyncEvent.emptyNew()

    self.baseServiceWear           = ADS_Config.CORE.BASE_SERVICE_WEAR
    self.baseSystemsWear           = ADS_Config.CORE.BASE_SYSTEMS_WEAR
    self.downtimeMultiplier        = ADS_Config.CORE.DOWNTIME_MULTIPLIER
    self.generalWearEnabled        = ADS_Config.CORE.GENERAL_WEAR_ENABLED
    self.systemStressGlobalMultiplier = ADS_Config.CORE.SYSTEM_STRESS_GLOBAL_MULTIPLIER
    self.aiOverloadControl         = ADS_Config.CORE.AI_OVERLOAD_AND_OVERHEAT_CONTROL
    self.instantInspection         = ADS_Config.MAINTENANCE.INSTANT_INSPECTION
    self.parkVehicle               = ADS_Config.MAINTENANCE.PARK_VEHICLE
    self.warrantyEnabled           = ADS_Config.MAINTENANCE.WARRANTY_ENABLED
    self.globalPriceMultiplier     = ADS_Config.MAINTENANCE.GLOBAL_SERVICE_PRICE_MULTIPLIER
    self.globalTimeMultiplier      = ADS_Config.MAINTENANCE.GLOBAL_SERVICE_TIME_MULTIPLIER
    self.alwaysAvailable           = ADS_Config.WORKSHOP.ALWAYS_AVAILABLE
    self.mobileWorkshopRestrictionsEnabled = ADS_Config.WORKSHOP.MOBILE_WORKSHOP_RESTRICTIONS_ENABLED
    self.openHour                  = ADS_Config.WORKSHOP.OPEN_HOUR
    self.closeHour                 = ADS_Config.WORKSHOP.CLOSE_HOUR
    self.engineMaxHeat             = ADS_Config.THERMAL.ENGINE_MAX_HEAT
    self.transMaxHeat              = ADS_Config.THERMAL.TRANS_MAX_HEAT
    self.batteryUsableCapacityFactor = ADS_Config.ELECTRICAL.BATTERY_USABLE_CAPACITY_FACTOR
    self.cloggingSpeed             = ADS_Config.FIELD_CARE.CLOGGING_SPEED
    self.debugMode                 = ADS_Config.DEBUG

    return self
end


function ADS_SettingsSyncEvent:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.baseServiceWear       or 0)
    streamWriteFloat32(streamId, self.baseSystemsWear       or 0)
    streamWriteFloat32(streamId, self.downtimeMultiplier    or 0)
    streamWriteBool(streamId,    self.generalWearEnabled    or false)
    streamWriteFloat32(streamId, self.systemStressGlobalMultiplier or 1.0)
    streamWriteBool(streamId,    self.aiOverloadControl      or false)
    streamWriteBool(streamId,    self.instantInspection      or false)
    streamWriteBool(streamId,    self.parkVehicle            or false)
    streamWriteBool(streamId,    self.warrantyEnabled        or false)
    streamWriteFloat32(streamId, self.globalPriceMultiplier  or 1)
    streamWriteFloat32(streamId, self.globalTimeMultiplier   or 1)
    streamWriteBool(streamId,    self.alwaysAvailable        or false)
    streamWriteBool(streamId,    self.mobileWorkshopRestrictionsEnabled or false)
    streamWriteFloat32(streamId, self.openHour               or 8)
    streamWriteFloat32(streamId, self.closeHour              or 19)
    streamWriteFloat32(streamId, self.engineMaxHeat          or 1.05)
    streamWriteFloat32(streamId, self.transMaxHeat           or 1.05)
    streamWriteFloat32(streamId, self.batteryUsableCapacityFactor or 0.1)
    streamWriteFloat32(streamId, self.cloggingSpeed          or 1.0)
    streamWriteBool(streamId,    self.debugMode              or false)
end


function ADS_SettingsSyncEvent:readStream(streamId, connection)
    self.baseServiceWear           = streamReadFloat32(streamId)
    self.baseSystemsWear           = streamReadFloat32(streamId)
    self.downtimeMultiplier        = streamReadFloat32(streamId)
    self.generalWearEnabled        = streamReadBool(streamId)
    self.systemStressGlobalMultiplier = streamReadFloat32(streamId)
    self.aiOverloadControl         = streamReadBool(streamId)
    self.instantInspection         = streamReadBool(streamId)
    self.parkVehicle               = streamReadBool(streamId)
    self.warrantyEnabled           = streamReadBool(streamId)
    self.globalPriceMultiplier     = streamReadFloat32(streamId)
    self.globalTimeMultiplier      = streamReadFloat32(streamId)
    self.alwaysAvailable           = streamReadBool(streamId)
    self.mobileWorkshopRestrictionsEnabled = streamReadBool(streamId)
    self.openHour                  = streamReadFloat32(streamId)
    self.closeHour                 = streamReadFloat32(streamId)
    self.engineMaxHeat             = streamReadFloat32(streamId)
    self.transMaxHeat              = streamReadFloat32(streamId)
    self.batteryUsableCapacityFactor = streamReadFloat32(streamId)
    self.cloggingSpeed             = streamReadFloat32(streamId)
    self.debugMode                 = streamReadBool(streamId)

    self:run(connection)
end


-- Apply received values to ADS_Config.
local function applyConfig(event)
    local oldBatteryCapacityFactor = ADS_Config.ELECTRICAL.BATTERY_USABLE_CAPACITY_FACTOR
    local oldConfig = {
        parkVehicle = ADS_Config.MAINTENANCE.PARK_VEHICLE,
        instantInspection = ADS_Config.MAINTENANCE.INSTANT_INSPECTION
    }

    ADS_Config.CORE.BASE_SERVICE_WEAR                      = event.baseServiceWear
    ADS_Config.CORE.BASE_SYSTEMS_WEAR                      = event.baseSystemsWear
    ADS_Config.CORE.DOWNTIME_MULTIPLIER                    = event.downtimeMultiplier
    ADS_Config.CORE.GENERAL_WEAR_ENABLED                   = event.generalWearEnabled
    ADS_Config.CORE.SYSTEM_STRESS_GLOBAL_MULTIPLIER        = event.systemStressGlobalMultiplier
    ADS_Config.CORE.AI_OVERLOAD_AND_OVERHEAT_CONTROL       = event.aiOverloadControl
    ADS_Config.MAINTENANCE.INSTANT_INSPECTION               = event.instantInspection
    ADS_Config.MAINTENANCE.PARK_VEHICLE                     = event.parkVehicle
    ADS_Config.MAINTENANCE.WARRANTY_ENABLED                 = event.warrantyEnabled
    ADS_Config.MAINTENANCE.GLOBAL_SERVICE_PRICE_MULTIPLIER  = event.globalPriceMultiplier
    ADS_Config.MAINTENANCE.GLOBAL_SERVICE_TIME_MULTIPLIER   = event.globalTimeMultiplier
    ADS_Config.WORKSHOP.ALWAYS_AVAILABLE                    = event.alwaysAvailable
    ADS_Config.WORKSHOP.MOBILE_WORKSHOP_RESTRICTIONS_ENABLED = event.mobileWorkshopRestrictionsEnabled
    ADS_Config.WORKSHOP.OPEN_HOUR                           = event.openHour
    ADS_Config.WORKSHOP.CLOSE_HOUR                          = event.closeHour
    ADS_Config.THERMAL.ENGINE_MAX_HEAT                      = event.engineMaxHeat
    ADS_Config.THERMAL.TRANS_MAX_HEAT                       = event.transMaxHeat
    ADS_Config.ELECTRICAL.BATTERY_USABLE_CAPACITY_FACTOR    = event.batteryUsableCapacityFactor
    ADS_Config.FIELD_CARE.CLOGGING_SPEED                    = event.cloggingSpeed
    ADS_Config.DEBUG                                        = event.debugMode

    local newConfig = {
        parkVehicle = event.parkVehicle,
        instantInspection = event.instantInspection
    }

    ADS_InGameSettings.applyPendingConfigSideEffects(oldConfig, newConfig)

    if math.abs((oldBatteryCapacityFactor or 0) - (event.batteryUsableCapacityFactor or 0)) > 0.0001
        and ADS_Main ~= nil and ADS_Main.vehicles ~= nil then
        for _, vehicle in pairs(ADS_Main.vehicles) do
            if vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil and not vehicle.spec_AdvancedDamageSystem.isExcludedVehicle then
                AdvancedDamageSystem.rescaleBatteryChargeFromSoc(vehicle)

                local spec = vehicle.spec_AdvancedDamageSystem
                if vehicle.isServer and spec.adsDirtyFlag_electrical ~= nil then
                    vehicle:raiseDirtyFlags(spec.adsDirtyFlag_electrical)
                end
            end
        end
    end

    ADS_Main:forceWorkshopUpdate()
end


function ADS_SettingsSyncEvent:run(connection)
    if not connection:getIsServer() then
        local userId = g_currentMission.userManager:getUserIdByConnection(connection)
        local user = g_currentMission.userManager:getUserByUserId(userId)
        if user == nil or not user:getIsMasterUser() then
            return
        end

        applyConfig(self)
        g_server:broadcastEvent(ADS_SettingsSyncEvent.new(), nil, connection)
    else
        applyConfig(self)
    end
end


-- Send current config from client to server.
function ADS_SettingsSyncEvent.send()
    if g_client ~= nil then
        g_client:getServerConnection():sendEvent(ADS_SettingsSyncEvent.new())
    end
end
