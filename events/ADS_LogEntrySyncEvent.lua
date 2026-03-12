-- ADS_LogEntrySyncEvent
-- Server-to-client broadcast event. Sends a new maintenance log entry
-- to all connected clients so their local log stays in sync.
-- Replaces the former dirty-flag group [5] (adsDirtyFlag_meta) which was
-- prone to 32-bit bitmask overflow on heavily-specialised vehicles and
-- also lost entries for 3+ player sessions (pending queue cleared after
-- the first connection write).

ADS_LogEntrySyncEvent = {}
local ADS_LogEntrySyncEvent_mt = Class(ADS_LogEntrySyncEvent, Event)

InitEventClass(ADS_LogEntrySyncEvent, "ADS_LogEntrySyncEvent")


function ADS_LogEntrySyncEvent.emptyNew()
    return Event.new(ADS_LogEntrySyncEvent_mt)
end


function ADS_LogEntrySyncEvent.new(vehicle, serializedEntry)
    local self = ADS_LogEntrySyncEvent.emptyNew()
    self.vehicle = vehicle
    self.serializedEntry = serializedEntry or ""
    return self
end


function ADS_LogEntrySyncEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteString(streamId, self.serializedEntry)
end


function ADS_LogEntrySyncEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.serializedEntry = streamReadString(streamId)
    self:run(connection)
end


function ADS_LogEntrySyncEvent:run(connection)
    local vehicle = self.vehicle
    if vehicle == nil or not vehicle:getIsSynchronized() then
        return
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then
        return
    end

    local entry = ADS_Utils.deserializeMaintenanceLogEntry(self.serializedEntry)
    if entry ~= nil then
        table.insert(spec.maintenanceLog, entry)
    end
end


--- Broadcast a log entry from server to all clients.
--- @param vehicle table  The vehicle that owns the log.
--- @param entry   table  The log entry table (will be serialized internally).
function ADS_LogEntrySyncEvent.sendToClients(vehicle, entry)
    if g_server ~= nil and entry ~= nil then
        local serialized = ADS_Utils.serializeMaintenanceLogEntry(entry)
        g_server:broadcastEvent(ADS_LogEntrySyncEvent.new(vehicle, serialized), nil, nil, vehicle)
    end
end
