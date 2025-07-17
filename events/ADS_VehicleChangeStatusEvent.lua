ADS_VehicleChangeStatusEvent = {}
local ADS_VehicleChangeStatusEvent_mt = Class(ADS_VehicleChangeStatusEvent, Event)
MessageType.ADS_VEHICLE_CHANGE_STATUS = nextMessageTypeId()

InitEventClass(ADS_VehicleChangeStatusEvent, "ADS_VehicleChangeStatusEvent")

function ADS_VehicleChangeStatusEvent.emptyNew()
    return Event.new(ADS_VehicleChangeStatusEvent_mt)
end

function ADS_VehicleChangeStatusEvent.new(vehicle)
    local self = ADS_VehicleChangeStatusEvent.emptyNew()
    self.vehicle = vehicle
    return self
end

function ADS_VehicleChangeStatusEvent:writeStream(streamId, connection)
    -- NetworkUtil.writeNodeObject(streamId, self.vehicle)
    -- streamWriteString(streamId, self.maintenanceType)
end

function ADS_VehicleChangeStatusEvent:readStream(streamId, connection)
    -- self.vehicle = NetworkUtil.readNodeObject(streamId)
    -- self.maintenanceType = streamReadString(streamId)
    -- self:run(connection) 
end

function ADS_VehicleChangeStatusEvent:run(connection)
    if connection:getIsServer() and self.vehicle ~= nil then
		g_messageCenter:publish(MessageType.ADS_VEHICLE_CHANGE_STATUS, self.vehicle)
		return
    end
end

function ADS_VehicleChangeStatusEvent.send(vehicle)
    if g_server ~= nil then
        g_server:broadcastEvent(ADS_VehicleChangeStatusEvent.new(vehicle), true)
    else
        g_eventManager:addEvent(ADS_VehicleChangeStatusEvent.new(vehicle))
    end
end

