ADS_AcceleratorPedalLimitEvent = {}
local ADS_AcceleratorPedalLimitEvent_mt = Class(ADS_AcceleratorPedalLimitEvent, Event)

InitEventClass(ADS_AcceleratorPedalLimitEvent, "ADS_AcceleratorPedalLimitEvent")


function ADS_AcceleratorPedalLimitEvent.emptyNew()
    return Event.new(ADS_AcceleratorPedalLimitEvent_mt)
end


function ADS_AcceleratorPedalLimitEvent.new(vehicle, value)
    local self = ADS_AcceleratorPedalLimitEvent.emptyNew()
    self.vehicle = vehicle
    self.value = math.clamp(tonumber(value) or 1.0, 0.0, 1.0)
    return self
end


function ADS_AcceleratorPedalLimitEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteFloat32(streamId, self.value)
end


function ADS_AcceleratorPedalLimitEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.value = math.clamp(streamReadFloat32(streamId), 0.0, 1.0)
    self:run(connection)
end


function ADS_AcceleratorPedalLimitEvent:run(connection)
    local vehicle = self.vehicle
    if vehicle == nil or not vehicle:getIsSynchronized() then
        return
    end

    ADS_ThrottleControl.setAcceleratorPedalLimit(vehicle, self.value, true)

    if not connection:getIsServer() and g_server ~= nil then
        g_server:broadcastEvent(
            ADS_AcceleratorPedalLimitEvent.new(vehicle, self.value),
            nil,
            connection,
            vehicle
        )
    end
end


function ADS_AcceleratorPedalLimitEvent.send(vehicle, value)
    local event = ADS_AcceleratorPedalLimitEvent.new(vehicle, value)
    if g_server ~= nil then
        g_server:broadcastEvent(event, nil, nil, vehicle)
    elseif g_client ~= nil then
        g_client:getServerConnection():sendEvent(event)
    end
end
