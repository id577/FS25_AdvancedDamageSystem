-- ADS_VehicleExclusionEvent
-- Server-to-client event for synchronising the user-controlled ADS exclusion flag.

ADS_VehicleExclusionEvent = {}
local ADS_VehicleExclusionEvent_mt = Class(ADS_VehicleExclusionEvent, Event)

InitEventClass(ADS_VehicleExclusionEvent, "ADS_VehicleExclusionEvent")


function ADS_VehicleExclusionEvent.emptyNew()
    return Event.new(ADS_VehicleExclusionEvent_mt)
end


function ADS_VehicleExclusionEvent.new(vehicle, isExcludedByUser)
    local self = ADS_VehicleExclusionEvent.emptyNew()
    self.vehicle = vehicle
    self.isExcludedByUser = isExcludedByUser == true
    return self
end


function ADS_VehicleExclusionEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.isExcludedByUser)
end


function ADS_VehicleExclusionEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.isExcludedByUser = streamReadBool(streamId)
    self:run(connection)
end


function ADS_VehicleExclusionEvent:run(connection)
    if not connection:getIsServer() then
        return
    end

    local vehicle = self.vehicle
    if vehicle == nil or not vehicle:getIsSynchronized() or vehicle.setADSUserExcluded == nil then
        return
    end

    vehicle:setADSUserExcluded(self.isExcludedByUser, true)
end


function ADS_VehicleExclusionEvent.sendToClients(vehicle, isExcludedByUser)
    if g_server ~= nil then
        g_server:broadcastEvent(ADS_VehicleExclusionEvent.new(vehicle, isExcludedByUser), nil, nil, vehicle)
    end
end
