-- ADS_CancelServiceEvent
-- Client-to-server event. Cancels an in-progress service on the server.

ADS_CancelServiceEvent = {}
local ADS_CancelServiceEvent_mt = Class(ADS_CancelServiceEvent, Event)

InitEventClass(ADS_CancelServiceEvent, "ADS_CancelServiceEvent")


function ADS_CancelServiceEvent.emptyNew()
    return Event.new(ADS_CancelServiceEvent_mt)
end


function ADS_CancelServiceEvent.new(vehicle)
    local self = ADS_CancelServiceEvent.emptyNew()
    self.vehicle = vehicle
    return self
end


function ADS_CancelServiceEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
end


function ADS_CancelServiceEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end


-- Server-side execution: validate vehicle, run cancelService.
function ADS_CancelServiceEvent:run(connection)
    if not connection:getIsServer() then
        if self.vehicle ~= nil and self.vehicle:getIsSynchronized() and self.vehicle.spec_AdvancedDamageSystem ~= nil then
            local userId = g_currentMission.userManager:getUserIdByConnection(connection)
            local farm = g_farmManager:getFarmByUserId(userId)
            if farm == nil or farm.farmId ~= self.vehicle:getOwnerFarmId() then
                return
            end

            self.vehicle:cancelService()
        end
    end
end


-- Client convenience: send cancel request to the server.
function ADS_CancelServiceEvent.send(vehicle)
    if g_client ~= nil then
        g_client:getServerConnection():sendEvent(ADS_CancelServiceEvent.new(vehicle))
    end
end
