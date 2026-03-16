ADS_StartButtonEvent = {}
local ADS_StartButtonEvent_mt = Class(ADS_StartButtonEvent, Event)

InitEventClass(ADS_StartButtonEvent, "ADS_StartButtonEvent")


function ADS_StartButtonEvent.emptyNew()
    return Event.new(ADS_StartButtonEvent_mt)
end


function ADS_StartButtonEvent.new(vehicle, isDown, isHeld, isUp)
    local self = ADS_StartButtonEvent.emptyNew()
    self.vehicle = vehicle
    self.isDown = isDown == true
    self.isHeld = isHeld == true
    self.isUp = isUp == true
    return self
end


function ADS_StartButtonEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.isDown)
    streamWriteBool(streamId, self.isHeld)
    streamWriteBool(streamId, self.isUp)
end


function ADS_StartButtonEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.isDown = streamReadBool(streamId)
    self.isHeld = streamReadBool(streamId)
    self.isUp = streamReadBool(streamId)
    self:run(connection)
end


function ADS_StartButtonEvent:run(connection)

    if connection:getIsServer() then
        return
    end

    local vehicle = self.vehicle
    if vehicle == nil or not vehicle:getIsSynchronized() then
        return
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then
        return
    end

    spec.startButtonDown = self.isDown
    spec.startButtonHeld = self.isHeld
    spec.startButtonUp = self.isUp
end


function ADS_StartButtonEvent.send(vehicle, isDown, isHeld, isUp)
    if g_client ~= nil then
        g_client:getServerConnection():sendEvent(ADS_StartButtonEvent.new(vehicle, isDown, isHeld, isUp))
    end
end

