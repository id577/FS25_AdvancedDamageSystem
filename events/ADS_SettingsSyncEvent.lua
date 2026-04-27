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
    self.enableWarningMessages     = ADS_Config.CORE.ENABLE_WARNING_MESSAGES
    self.systemStressGlobalMultiplier = ADS_Config.CORE.SYSTEM_STRESS_GLOBAL_MULTIPLIER
    self.aiOverloadControl         = ADS_Config.CORE.AI_OVERLOAD_AND_OVERHEAT_CONTROL
    self.instantInspection         = ADS_Config.MAINTENANCE.INSTANT_INSPECTION
    self.parkVehicle               = ADS_Config.MAINTENANCE.PARK_VEHICLE
    self.warrantyEnabled           = ADS_Config.MAINTENANCE.WARRANTY_ENABLED
    self.globalPriceMultiplier     = ADS_Config.MAINTENANCE.GLOBAL_SERVICE_PRICE_MULTIPLIER
    self.globalTimeMultiplier      = ADS_Config.MAINTENANCE.GLOBAL_SERVICE_TIME_MULTIPLIER
    self.dealerAlwaysAvailable     = ADS_Config.WORKSHOP.DEALER_ALWAYS_AVAILABLE
    self.mobileAlwaysAvailable     = ADS_Config.WORKSHOP.MOBILE_ALWAYS_AVAILABLE
    self.ownAlwaysAvailable        = ADS_Config.WORKSHOP.OWN_ALWAYS_AVAILABLE
    self.mobileWorkshopRestrictionsEnabled = ADS_Config.WORKSHOP.MOBILE_WORKSHOP_RESTRICTIONS_ENABLED
    self.openHour                  = ADS_Config.WORKSHOP.OPEN_HOUR
    self.closeHour                 = ADS_Config.WORKSHOP.CLOSE_HOUR
    self.engineMaxHeat             = ADS_Config.THERMAL.ENGINE_MAX_HEAT
    self.transMaxHeat              = ADS_Config.THERMAL.TRANS_MAX_HEAT
    self.maxDirtInfluence          = ADS_Config.THERMAL.MAX_DIRT_INFLUENCE
    self.warmingBoostPower         = ADS_Config.THERMAL.WARMING_BOOST_POWER
    self.coolingSlowdownPower      = ADS_Config.THERMAL.COOLING_SLOWDOWN_POWER
    self.batteryUsableCapacityFactor = ADS_Config.ELECTRICAL.BATTERY_USABLE_CAPACITY_FACTOR
    self.alternatorMaxOutput       = ADS_Config.ELECTRICAL.ALT_MAX_OUTPUT
    self.idleCurrentA              = ADS_Config.ELECTRICAL.IDLE_CURRENT_A
    self.cloggingSpeed             = ADS_Config.FIELD_CARE.CLOGGING_SPEED
    self.fieldInspectionDuration   = ADS_Config.FIELD_CARE.VISUAL_INSPECTION_DURATION
    self.lubricationReducePerDay   = ADS_Config.FIELD_CARE.LUBRICATION_REDUCE_PER_DAY
    self.debugMode                 = ADS_Config.DEBUG

    return self
end


function ADS_SettingsSyncEvent:writeStream(streamId, connection)
    streamWriteFloat32(streamId, self.baseServiceWear       or 0)
    streamWriteFloat32(streamId, self.baseSystemsWear       or 0)
    streamWriteFloat32(streamId, self.downtimeMultiplier    or 0)
    streamWriteBool(streamId,    self.generalWearEnabled    or false)
    streamWriteBool(streamId,    self.enableWarningMessages or false)
    streamWriteFloat32(streamId, self.systemStressGlobalMultiplier or 1.0)
    streamWriteBool(streamId,    self.aiOverloadControl      or false)
    streamWriteBool(streamId,    self.instantInspection      or false)
    streamWriteBool(streamId,    self.parkVehicle            or false)
    streamWriteBool(streamId,    self.warrantyEnabled        or false)
    streamWriteFloat32(streamId, self.globalPriceMultiplier  or 1)
    streamWriteFloat32(streamId, self.globalTimeMultiplier   or 1)
    streamWriteBool(streamId,    self.dealerAlwaysAvailable  or false)
    streamWriteBool(streamId,    self.mobileAlwaysAvailable  or false)
    streamWriteBool(streamId,    self.ownAlwaysAvailable     or false)
    streamWriteBool(streamId,    self.mobileWorkshopRestrictionsEnabled or false)
    streamWriteFloat32(streamId, self.openHour               or 8)
    streamWriteFloat32(streamId, self.closeHour              or 19)
    streamWriteFloat32(streamId, self.engineMaxHeat          or 1.05)
    streamWriteFloat32(streamId, self.transMaxHeat           or 1.05)
    streamWriteFloat32(streamId, self.maxDirtInfluence       or 0.2)
    streamWriteFloat32(streamId, self.warmingBoostPower      or 1.0)
    streamWriteFloat32(streamId, self.coolingSlowdownPower   or 1.0)
    streamWriteFloat32(streamId, self.batteryUsableCapacityFactor or 0.1)
    streamWriteFloat32(streamId, self.alternatorMaxOutput    or 100)
    streamWriteFloat32(streamId, self.idleCurrentA           or 0.5)
    streamWriteFloat32(streamId, self.cloggingSpeed          or 1.0)
    streamWriteFloat32(streamId, self.fieldInspectionDuration or 6000)
    streamWriteFloat32(streamId, self.lubricationReducePerDay or 0.2)
    streamWriteBool(streamId,    self.debugMode              or false)
end


function ADS_SettingsSyncEvent:readStream(streamId, connection)
    self.baseServiceWear           = streamReadFloat32(streamId)
    self.baseSystemsWear           = streamReadFloat32(streamId)
    self.downtimeMultiplier        = streamReadFloat32(streamId)
    self.generalWearEnabled        = streamReadBool(streamId)
    self.enableWarningMessages     = streamReadBool(streamId)
    self.systemStressGlobalMultiplier = streamReadFloat32(streamId)
    self.aiOverloadControl         = streamReadBool(streamId)
    self.instantInspection         = streamReadBool(streamId)
    self.parkVehicle               = streamReadBool(streamId)
    self.warrantyEnabled           = streamReadBool(streamId)
    self.globalPriceMultiplier     = streamReadFloat32(streamId)
    self.globalTimeMultiplier      = streamReadFloat32(streamId)
    self.dealerAlwaysAvailable     = streamReadBool(streamId)
    self.mobileAlwaysAvailable     = streamReadBool(streamId)
    self.ownAlwaysAvailable        = streamReadBool(streamId)
    self.mobileWorkshopRestrictionsEnabled = streamReadBool(streamId)
    self.openHour                  = streamReadFloat32(streamId)
    self.closeHour                 = streamReadFloat32(streamId)
    self.engineMaxHeat             = streamReadFloat32(streamId)
    self.transMaxHeat              = streamReadFloat32(streamId)
    self.maxDirtInfluence          = streamReadFloat32(streamId)
    self.warmingBoostPower         = streamReadFloat32(streamId)
    self.coolingSlowdownPower      = streamReadFloat32(streamId)
    self.batteryUsableCapacityFactor = streamReadFloat32(streamId)
    self.alternatorMaxOutput       = streamReadFloat32(streamId)
    self.idleCurrentA              = streamReadFloat32(streamId)
    self.cloggingSpeed             = streamReadFloat32(streamId)
    self.fieldInspectionDuration   = streamReadFloat32(streamId)
    self.lubricationReducePerDay   = streamReadFloat32(streamId)
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
    ADS_Config.CORE.ENABLE_WARNING_MESSAGES                = event.enableWarningMessages
    ADS_Config.CORE.SYSTEM_STRESS_GLOBAL_MULTIPLIER        = event.systemStressGlobalMultiplier
    ADS_Config.CORE.AI_OVERLOAD_AND_OVERHEAT_CONTROL       = event.aiOverloadControl
    ADS_Config.MAINTENANCE.INSTANT_INSPECTION               = event.instantInspection
    ADS_Config.MAINTENANCE.PARK_VEHICLE                     = event.parkVehicle
    ADS_Config.MAINTENANCE.WARRANTY_ENABLED                 = event.warrantyEnabled
    ADS_Config.MAINTENANCE.GLOBAL_SERVICE_PRICE_MULTIPLIER  = event.globalPriceMultiplier
    ADS_Config.MAINTENANCE.GLOBAL_SERVICE_TIME_MULTIPLIER   = event.globalTimeMultiplier
    ADS_Config.WORKSHOP.DEALER_ALWAYS_AVAILABLE             = event.dealerAlwaysAvailable
    ADS_Config.WORKSHOP.MOBILE_ALWAYS_AVAILABLE             = event.mobileAlwaysAvailable
    ADS_Config.WORKSHOP.OWN_ALWAYS_AVAILABLE                = event.ownAlwaysAvailable
    ADS_Config.WORKSHOP.MOBILE_WORKSHOP_RESTRICTIONS_ENABLED = event.mobileWorkshopRestrictionsEnabled
    ADS_Config.WORKSHOP.OPEN_HOUR                           = event.openHour
    ADS_Config.WORKSHOP.CLOSE_HOUR                          = event.closeHour
    ADS_Config.THERMAL.ENGINE_MAX_HEAT                      = event.engineMaxHeat
    ADS_Config.THERMAL.TRANS_MAX_HEAT                       = event.transMaxHeat
    ADS_Config.THERMAL.MAX_DIRT_INFLUENCE                   = event.maxDirtInfluence
    ADS_Config.THERMAL.WARMING_BOOST_POWER                  = event.warmingBoostPower
    ADS_Config.THERMAL.COOLING_SLOWDOWN_POWER               = event.coolingSlowdownPower
    ADS_Config.ELECTRICAL.BATTERY_USABLE_CAPACITY_FACTOR    = event.batteryUsableCapacityFactor
    ADS_Config.ELECTRICAL.ALT_MAX_OUTPUT                    = event.alternatorMaxOutput
    ADS_Config.ELECTRICAL.IDLE_CURRENT_A                    = event.idleCurrentA
    ADS_Config.FIELD_CARE.CLOGGING_SPEED                    = event.cloggingSpeed
    ADS_Config.FIELD_CARE.VISUAL_INSPECTION_DURATION         = event.fieldInspectionDuration
    ADS_Config.FIELD_CARE.LUBRICATION_REDUCE_PER_DAY        = event.lubricationReducePerDay
    ADS_Config.DEBUG                                        = event.debugMode

    local newConfig = {
        parkVehicle = event.parkVehicle,
        instantInspection = event.instantInspection
    }

    ADS_SettingsPage.applyPendingConfigSideEffects(oldConfig, newConfig)

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

    ADS_Main:forceWorkshopUpdate(true)
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
