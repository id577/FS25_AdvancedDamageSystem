ADS_HandToolSyncEvent = {}
local ADS_HandToolSyncEvent_mt = Class(ADS_HandToolSyncEvent, Event)

InitEventClass(ADS_HandToolSyncEvent, "ADS_HandToolSyncEvent")


function ADS_HandToolSyncEvent.emptyNew()
    return Event.new(ADS_HandToolSyncEvent_mt)
end


function ADS_HandToolSyncEvent.new(tool, state)
    local self = ADS_HandToolSyncEvent.emptyNew()
    self.tool = tool
    self.state = state or ""
    return self
end


function ADS_HandToolSyncEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.tool)
    streamWriteString(streamId, self.state)
end


function ADS_HandToolSyncEvent:readStream(streamId, connection)
    self.tool = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadString(streamId)
    self:run(connection)
end


function ADS_HandToolSyncEvent:run(connection)
    if connection == nil or connection:getIsServer() then
        return
    end

    local tool = self.tool
    if tool == nil or not tool:getIsSynchronized() then
        return
    end

    local specName = "spec_" .. g_currentModName .. ".adsHandTools"
    local spec = tool[specName]
    if spec == nil then
        return
    end

    local player = g_currentMission ~= nil and g_currentMission.connectionsToPlayer ~= nil and g_currentMission.connectionsToPlayer[connection] or nil
    if player == nil or tool.getCarryingPlayer == nil or tool:getCarryingPlayer() ~= player then
        return
    end

    if spec.toolKind == "airBlower" then
        tool:setAirBlowerActiveServer(self.state == "start", connection)
    elseif spec.toolKind == "greaseGun" and self.state == "use" then
        tool:tryUseGreaseGunServer(connection)
    end
end


function ADS_HandToolSyncEvent.send(tool, state)
    if g_client ~= nil then
        g_client:getServerConnection():sendEvent(ADS_HandToolSyncEvent.new(tool, state))
    end
end
