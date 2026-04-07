-- ADS_ConsoleCommandEvent
-- Client-to-server event for console commands that mutate vehicle or config
-- state. Only admin (master user) connections are allowed to execute commands.

ADS_ConsoleCommandEvent = {}
local ADS_ConsoleCommandEvent_mt = Class(ADS_ConsoleCommandEvent, Event)

InitEventClass(ADS_ConsoleCommandEvent, "ADS_ConsoleCommandEvent")

ADS_ConsoleCommandEvent.ALLOWED_COMMANDS = {
    setService = true,
    setCondition = true,
    setSystemCondition = true,
    setSystemStress = true,
    setSystemStressMultiplier = true,
    resetVehicle = true,
    addBreakdown = true,
    removeBreakdown = true,
    changeBreakdownStage = true,
    startMaintance = true,
    finishMaintance = true,
    setDirtAmount = true,
    setFuelLevel = true,
    resetFactorStats = true,
    reinitializeVehicle = true,
    printSpecVar = true,
    setSpecVar = true,
    setConfigVar = true,
    debug = true
}

function ADS_ConsoleCommandEvent.emptyNew()
    return Event.new(ADS_ConsoleCommandEvent_mt)
end


function ADS_ConsoleCommandEvent.new(commandName, argsOne, argsTwo, vehicle)
    local self = ADS_ConsoleCommandEvent.emptyNew()
    self.commandName = commandName
    self.argsOne = argsOne
    self.argsTwo = argsTwo
    self.vehicle = vehicle
    return self
end


function ADS_ConsoleCommandEvent:writeStream(streamId, connection)
    streamWriteString(streamId, self.commandName or "")
    streamWriteString(streamId, self.argsOne or "")
    streamWriteString(streamId, self.argsTwo or "")
    local hasVehicle = self.vehicle ~= nil
    streamWriteBool(streamId, hasVehicle)
    if hasVehicle then
        NetworkUtil.writeNodeObject(streamId, self.vehicle)
    end
end


function ADS_ConsoleCommandEvent:readStream(streamId, connection)
    self.commandName = streamReadString(streamId)
    self.argsOne = streamReadString(streamId)
    self.argsTwo = streamReadString(streamId)
    local hasVehicle = streamReadBool(streamId)
    if hasVehicle then
        self.vehicle = NetworkUtil.readNodeObject(streamId)
    end

    if self.argsOne == "" then self.argsOne = nil end
    if self.argsTwo == "" then self.argsTwo = nil end

    self:run(connection)
end


function ADS_ConsoleCommandEvent:run(connection)
    if connection:getIsServer() then
        return
    end

    local userId = g_currentMission.userManager:getUserIdByConnection(connection)
    local user = g_currentMission.userManager:getUserByUserId(userId)
    if user == nil then
        return
    end

    local isAllowed = user:getIsMasterUser()
    if not isAllowed then
        local ok, result = pcall(function()
            local farm = g_farmManager:getFarmByUserId(userId)
            if farm ~= nil and farm.userIdToPlayer ~= nil then
                local player = farm.userIdToPlayer[userId]
                if player ~= nil and player.isFarmManager == true then
                    return true
                end
            end
            return false
        end)
        isAllowed = ok and result == true
    end

    if not isAllowed then
        return
    end

    if not ADS_ConsoleCommandEvent.ALLOWED_COMMANDS[self.commandName] then
        return
    end

    local func = AdvancedDamageSystem.ConsoleCommands[self.commandName]
    if func == nil then
        return
    end

    AdvancedDamageSystem.ConsoleCommands._overrideVehicle = self.vehicle
    func(AdvancedDamageSystem.ConsoleCommands, self.argsOne, self.argsTwo)
    AdvancedDamageSystem.ConsoleCommands._overrideVehicle = nil

    if self.vehicle ~= nil and self.vehicle.spec_AdvancedDamageSystem ~= nil then
        local spec = self.vehicle.spec_AdvancedDamageSystem
        if spec.adsDirtyFlag_state ~= nil then
            self.vehicle:raiseDirtyFlags(spec.adsDirtyFlag_state)
        end
        if spec.adsDirtyFlag_systems ~= nil then
            self.vehicle:raiseDirtyFlags(spec.adsDirtyFlag_systems)
        end
        if spec.adsDirtyFlag_breakdown ~= nil then
            self.vehicle:raiseDirtyFlags(spec.adsDirtyFlag_breakdown)
        end
        if spec.adsDirtyFlag_service ~= nil then
            self.vehicle:raiseDirtyFlags(spec.adsDirtyFlag_service)
        end
    end

    if self.commandName == "setConfigVar" or self.commandName == "debug" then
        g_server:broadcastEvent(ADS_SettingsSyncEvent.new())
    end
end


function ADS_ConsoleCommandEvent.sendToServer(commandName, argsOne, argsTwo, vehicle)
    if g_client ~= nil then
        if not g_currentMission.isMasterUser then
            print("ADS: Admin access required.")
            return
        end
        g_client:getServerConnection():sendEvent(ADS_ConsoleCommandEvent.new(commandName, argsOne, argsTwo, vehicle))
    end
end
