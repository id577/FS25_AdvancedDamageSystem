ADS_WorkshopChangeStatusEvent = {}
local ADS_WorkshopChangeStatusEvent_mt = Class(ADS_WorkshopChangeStatusEvent, Event)
MessageType.ADS_WORKSHOP_CHANGE_STATUS = nextMessageTypeId()

InitEventClass(ADS_WorkshopChangeStatusEvent, "ADS_WorkshopChangeStatusEvent")

function ADS_WorkshopChangeStatusEvent.emptyNew()
    return Event.new(ADS_WorkshopChangeStatusEvent_mt)
end

function ADS_WorkshopChangeStatusEvent.new(isOpen)
    local self = ADS_WorkshopChangeStatusEvent.emptyNew()
    self.isOpen = isOpen
    return self
end

function ADS_WorkshopChangeStatusEvent:writeStream(streamId, connection)
    -- NetworkUtil.writeNodeObject(streamId, self.vehicle)
    -- streamWriteString(streamId, self.maintenanceType)
end

function ADS_WorkshopChangeStatusEvent:readStream(streamId, connection)
    -- self.vehicle = NetworkUtil.readNodeObject(streamId)
    -- self.maintenanceType = streamReadString(streamId)
    -- self:run(connection) 
end

function ADS_WorkshopChangeStatusEvent:run(connection)
    if connection:getIsServer() and self.isOpen ~= nil then
		g_messageCenter:publish(MessageType.ADS_WORKSHOP_CHANGE_STATUS, self.isOpen)
		return
    end
end

function ADS_WorkshopChangeStatusEvent.send(isOpen)
    if g_server ~= nil then
        g_server:broadcastEvent(ADS_WorkshopChangeStatusEvent.new(isOpen), true)
    else
        g_eventManager:addEvent(ADS_WorkshopChangeStatusEvent.new(isOpen))
    end
end