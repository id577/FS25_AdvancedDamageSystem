-- ADS_WorkshopChangeStatusEvent
-- Server-to-client broadcast. Synchronises workshop open/close state
-- (driven by time-of-day) to all clients.

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
    streamWriteBool(streamId, self.isOpen)
end


function ADS_WorkshopChangeStatusEvent:readStream(streamId, connection)
    self.isOpen = streamReadBool(streamId)
    self:run(connection)
end


function ADS_WorkshopChangeStatusEvent:run(connection)
    if not connection:getIsServer() then
        return
    end

    ADS_Main.isWorkshopOpen = self.isOpen
    g_messageCenter:publish(MessageType.ADS_WORKSHOP_CHANGE_STATUS, self.isOpen)
end


-- Server convenience: broadcast workshop state to all clients.
function ADS_WorkshopChangeStatusEvent.send(isOpen)
    if g_server ~= nil then
        g_server:broadcastEvent(ADS_WorkshopChangeStatusEvent.new(isOpen))
    end
end
