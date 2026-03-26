ADS_HandToolSyncEvent = {}
local ADS_HandToolSyncEvent_mt = Class(ADS_HandToolSyncEvent, Event)

InitEventClass(ADS_HandToolSyncEvent, "ADS_HandToolSyncEvent")


local function getHandToolSpec(tool)
    if tool == nil then
        return nil
    end

    if g_currentModName ~= nil then
        local spec = tool["spec_" .. g_currentModName .. ".adsHandTools"]
        if spec ~= nil then
            return spec
        end
    end

    for key, value in pairs(tool) do
        if type(key) == "string"
            and string.sub(key, 1, 5) == "spec_"
            and string.sub(key, -13) == ".adsHandTools" then
            return value
        end
    end

    return nil
end


function ADS_HandToolSyncEvent.emptyNew()
    return Event.new(ADS_HandToolSyncEvent_mt)
end


function ADS_HandToolSyncEvent.new(tool, state, targetVehicle)
    local self = ADS_HandToolSyncEvent.emptyNew()
    self.tool = tool
    self.state = state or ""
    self.targetVehicle = targetVehicle
    return self
end


function ADS_HandToolSyncEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.tool)
    streamWriteString(streamId, self.state)
    NetworkUtil.writeNodeObject(streamId, self.targetVehicle)
end


function ADS_HandToolSyncEvent:readStream(streamId, connection)
    self.tool = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadString(streamId)
    self.targetVehicle = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end


function ADS_HandToolSyncEvent:run(connection)
    local tool = self.tool
    if tool == nil or not tool:getIsSynchronized() then
        return
    end

    local spec = getHandToolSpec(tool)
    if spec == nil then
        return
    end

    if connection ~= nil and not connection:getIsServer() then
        local player = g_currentMission ~= nil and g_currentMission.connectionsToPlayer ~= nil and g_currentMission.connectionsToPlayer[connection] or nil
        if player == nil or tool.getCarryingPlayer == nil or tool:getCarryingPlayer() ~= player then
            return
        end

        if spec.toolKind == "airBlower" then
            if self.state == "start" then
                tool:setAirBlowerActiveServer(true, connection)
            elseif self.state == "stop" then
                tool:setAirBlowerActiveServer(false, connection)
            elseif self.state == "use" then
                tool:setAirBlowerTargetServer(self.targetVehicle, connection)
            end
        elseif spec.toolKind == "greaseGun" and self.state == "use" then
            tool:tryUseGreaseGunServer(self.targetVehicle, connection)
        end

        return
    end
end


function ADS_HandToolSyncEvent.send(tool, state, targetVehicle)
    if g_client ~= nil then
        g_client:getServerConnection():sendEvent(ADS_HandToolSyncEvent.new(tool, state, targetVehicle))
    end
end
