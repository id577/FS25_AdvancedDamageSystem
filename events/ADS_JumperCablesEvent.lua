ADS_JumperCablesEvent = {}
local ADS_JumperCablesEvent_mt = Class(ADS_JumperCablesEvent, Event)

InitEventClass(ADS_JumperCablesEvent, "ADS_JumperCablesEvent")


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


function ADS_JumperCablesEvent.emptyNew()
    return Event.new(ADS_JumperCablesEvent_mt)
end


function ADS_JumperCablesEvent.new(tool, state, targetVehicle, connectedVehicleA, connectedVehicleB)
    local self = ADS_JumperCablesEvent.emptyNew()
    self.tool = tool
    self.state = state or ""
    self.targetVehicle = targetVehicle
    self.connectedVehicleA = connectedVehicleA
    self.connectedVehicleB = connectedVehicleB
    return self
end


function ADS_JumperCablesEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.tool)
    streamWriteString(streamId, self.state)
    NetworkUtil.writeNodeObject(streamId, self.targetVehicle)
    NetworkUtil.writeNodeObject(streamId, self.connectedVehicleA)
    NetworkUtil.writeNodeObject(streamId, self.connectedVehicleB)
end


function ADS_JumperCablesEvent:readStream(streamId, connection)
    self.tool = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadString(streamId)
    self.targetVehicle = NetworkUtil.readNodeObject(streamId)
    self.connectedVehicleA = NetworkUtil.readNodeObject(streamId)
    self.connectedVehicleB = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end


function ADS_JumperCablesEvent:run(connection)
    local tool = self.tool
    if tool == nil or not tool:getIsSynchronized() then
        return
    end

    local spec = getHandToolSpec(tool)
    if spec == nil or spec.toolKind ~= "jumperCables" then
        return
    end

    if connection ~= nil and not connection:getIsServer() then
        local player = g_currentMission ~= nil and g_currentMission.connectionsToPlayer ~= nil and g_currentMission.connectionsToPlayer[connection] or nil
        if player == nil or tool.getCarryingPlayer == nil or tool:getCarryingPlayer() ~= player then
            return
        end

        tool:handleJumperCablesActionServer(self.state, self.targetVehicle, connection)
        return
    end

    tool:applyJumperCablesState(self.state, self.targetVehicle, self.connectedVehicleA, self.connectedVehicleB)
end


function ADS_JumperCablesEvent.sendRequest(tool, state, targetVehicle)
    if g_client ~= nil then
        g_client:getServerConnection():sendEvent(ADS_JumperCablesEvent.new(tool, state, targetVehicle, nil, nil))
    end
end


function ADS_JumperCablesEvent.broadcastState(tool, state, targetVehicle, connectedVehicleA, connectedVehicleB)
    if g_server ~= nil then
        g_server:broadcastEvent(ADS_JumperCablesEvent.new(tool, state, targetVehicle, connectedVehicleA, connectedVehicleB), nil, nil, tool)
    end
end
