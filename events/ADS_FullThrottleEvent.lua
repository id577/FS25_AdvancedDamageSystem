ADS_FullThrottleEvent = {}
local ADS_FullThrottleEvent_mt = Class(ADS_FullThrottleEvent, Event)

InitEventClass(ADS_FullThrottleEvent, "ADS_FullThrottleEvent")


function ADS_FullThrottleEvent.emptyNew()
    return Event.new(ADS_FullThrottleEvent_mt)
end


function ADS_FullThrottleEvent.new(vehicle, isPressed)
    local self = ADS_FullThrottleEvent.emptyNew()
    self.vehicle = vehicle
    self.isPressed = isPressed == true
    return self
end


function ADS_FullThrottleEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.isPressed)
end


function ADS_FullThrottleEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.isPressed = streamReadBool(streamId)
    self:run(connection)
end


function ADS_FullThrottleEvent:run(connection)
    if connection:getIsServer() then
        return
    end

    local vehicle = self.vehicle
    if vehicle == nil or not vehicle:getIsSynchronized() then
        return
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    if spec ~= nil then
        spec.fullThrottleOverridePressed = self.isPressed
    end
end


function ADS_FullThrottleEvent.send(vehicle, isPressed)
    if g_client ~= nil then
        g_client:getServerConnection():sendEvent(ADS_FullThrottleEvent.new(vehicle, isPressed))
    end
end
