adsHandTools = {}

local specName = "spec_" .. g_currentModName .. ".adsHandTools"
local RAYCAST_DISTANCE = 1.5

-- ==========================================================
--                          HELPERS
-- ==========================================================

local function log_dbg(...)
    if ADS_Config ~= nil and ADS_Config.DEBUG then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i])
        end
        print("[ADS_HAND_TOOLS] " .. table.concat(args, " "))
    end
end

local function ensureSpec(object)
    local spec = object[specName]
    if spec == nil then
        spec = {}
        object[specName] = spec
    end

    return spec
end

local function getToolKind(handTool)
    local configFileName = string.lower(handTool ~= nil and handTool.configFileName or "")

    if string.find(configFileName, "airblower", 1, true) then
        return "airBlower"
    end

    if string.find(configFileName, "greasegun", 1, true) then
        return "greaseGun"
    end

    if string.find(configFileName, "jumpercables", 1, true) then
        return "jumperCables"
    end

    return "unknown"
end

local function resolveMappedNode(object, mappingKey)
    if object == nil or object.components == nil or object.i3dMappings == nil then
        return nil
    end

    return I3DUtil.indexToObject(object.components, mappingKey, object.i3dMappings)
end

local function getRaycastVehicle(handTool, maxDistance)
    local spec = ensureSpec(handTool)
    spec.raycastVehicle = nil
    spec.raycastVehicleDistance = math.huge
    spec.raycastHitX = nil
    spec.raycastHitY = nil
    spec.raycastHitZ = nil
    spec.raycastHitNX = nil
    spec.raycastHitNY = nil
    spec.raycastHitNZ = nil

    if spec.raycastNode == nil or spec.raycastNode == 0 then
        log_dbg("Raycast aborted: raycastNode is missing")
        return nil
    end

    local x, y, z = getWorldTranslation(spec.raycastNode)
    local dx, dy, dz = localDirectionToWorld(spec.raycastNode, 0, 0, -1)

    raycastAll(x, y, z, dx, dy, dz, maxDistance or RAYCAST_DISTANCE, "handToolRaycastCallback", handTool, nil, false, true)

    return spec.raycastVehicle
end

local function setActionText(handTool, text)
    local spec = ensureSpec(handTool)
    if spec.activateActionEventId ~= nil then
        g_inputBinding:setActionEventText(spec.activateActionEventId, text)
    end
end

local function getDefaultActionText(handTool)
    local toolKind = getToolKind(handTool)

    if toolKind == "airBlower" then
        return g_i18n:getText("ads_air_blower_action")
    elseif toolKind == "greaseGun" then
        return g_i18n:getText("ads_grease_gun_action")
    elseif toolKind == "jumperCables" then
        if g_i18n ~= nil and g_i18n.hasText ~= nil and g_i18n:hasText("ads_jumper_cables_action") then
            return g_i18n:getText("ads_jumper_cables_action")
        end

        return "Connect jumper cables"
    end

    return ""
end

local function setToolSoundState(handTool, shouldPlay)
    local spec = ensureSpec(handTool)
    if spec == nil or spec.samples == nil then
        return
    end

    local sample = nil
    if spec.toolKind == "airBlower" then
        sample = spec.samples.airBlower
    end

    if sample == nil then
        return
    end

    if shouldPlay and not spec.toolSoundPlaying then
        g_soundManager:playSample(sample)
        spec.toolSoundPlaying = true
    elseif not shouldPlay and spec.toolSoundPlaying then
        g_soundManager:stopSample(sample)
        spec.toolSoundPlaying = false
    end
end

local function setAirResistanceSoundState(handTool, shouldPlay)
    local spec = ensureSpec(handTool)
    if spec == nil or spec.samples == nil then
        return
    end

    local sample = nil
    if spec.toolKind == "airBlower" then
        sample = spec.samples.airBlowerAirResistance
    end

    if sample == nil then
        return
    end

    if shouldPlay and not spec.airResistanceSoundPlaying then
        g_soundManager:playSample(sample)
        spec.airResistanceSoundPlaying = true
    elseif not shouldPlay and spec.airResistanceSoundPlaying then
        g_soundManager:stopSample(sample)
        spec.airResistanceSoundPlaying = false
    end
end

local function resetDustEmitterPosition(handTool)
    local spec = ensureSpec(handTool)
    if spec.dustEmitterRootNode ~= nil and spec.dustEmitterRootNode ~= 0 then
        setTranslation(
            spec.dustEmitterRootNode,
            spec.dustEmitterBaseX or 0,
            spec.dustEmitterBaseY or 0,
            spec.dustEmitterBaseZ or 0
        )
    end
end

local function setDustEmitterDistance(handTool, distance)
    local spec = ensureSpec(handTool)
    if spec.dustEmitterRootNode == nil or spec.dustEmitterRootNode == 0 then
        return
    end

    local clampedDistance = math.max(tonumber(distance) or 0, 0.1)

    setTranslation(
        spec.dustEmitterRootNode,
        spec.dustEmitterBaseX or 0,
        spec.dustEmitterBaseY or 0,
        -clampedDistance
    )
end

local function sendHandToolStateToServer(handTool, state, force, targetVehicle)
    if handTool.isServer or g_client == nil then
        return
    end

    local spec = ensureSpec(handTool)
    if state == "use" then
        if not force and spec.lastSentUseTargetVehicle == targetVehicle then
            return
        end

        ADS_HandToolSyncEvent.send(handTool, state, targetVehicle)
        spec.lastSentUseTargetVehicle = targetVehicle
        return
    end

    if not force and spec.lastSentNetworkState == state then
        return
    end

    ADS_HandToolSyncEvent.send(handTool, state, targetVehicle)

    if state == "stop" then
        spec.lastSentUseTargetVehicle = nil
    end

    spec.lastSentNetworkState = state
end

local function broadcastJumperCablesState(handTool, state, targetVehicle)
    local spec = ensureSpec(handTool)

    if g_server ~= nil then
        ADS_JumperCablesEvent.broadcastState(handTool, state, targetVehicle, spec.connectedVehicleA, spec.connectedVehicleB)
    end

    if handTool.isClient then
        handTool:applyJumperCablesState(state, targetVehicle, spec.connectedVehicleA, spec.connectedVehicleB)
    end
end

local function updateJumperCablesVisibility(handTool)
    local spec = ensureSpec(handTool)
    if spec.toolKind ~= "jumperCables" then
        return
    end

    if spec.leftPairNode ~= nil and spec.leftPairNode ~= 0 then
        setVisibility(spec.leftPairNode, spec.connectedVehicleA == nil)
    end

    if spec.rightPairNode ~= nil and spec.rightPairNode ~= 0 then
        setVisibility(spec.rightPairNode, spec.connectedVehicleB == nil)
    end
end

local function normalizeConnectedVehicle(vehicle)
    if vehicle == nil then
        return nil
    end

    if vehicle.getRootVehicle ~= nil then
        return vehicle:getRootVehicle()
    end

    return vehicle
end

local function areVehiclesExternallyConnected(vehicleA, vehicleB)
    vehicleA = normalizeConnectedVehicle(vehicleA)
    vehicleB = normalizeConnectedVehicle(vehicleB)

    if vehicleA == nil or vehicleB == nil or vehicleA == vehicleB then
        return false
    end

    local specA = vehicleA.spec_AdvancedDamageSystem
    local specB = vehicleB.spec_AdvancedDamageSystem
    if specA == nil or specB == nil then
        return false
    end

    local connectionA = specA.externalPowerConnection
    if type(connectionA) == "table" and connectionA.object ~= nil then
        connectionA = connectionA.object
    end

    local connectionB = specB.externalPowerConnection
    if type(connectionB) == "table" and connectionB.object ~= nil then
        connectionB = connectionB.object
    end

    return connectionA == vehicleB and connectionB == vehicleA
end

-- ==========================================================
--                     REGISTRATION & INIT
-- ==========================================================

function adsHandTools.prerequisitesPresent(specializations)
    return true
end

function adsHandTools.registerFunctions(handTool)
    SpecializationUtil.registerFunction(handTool, "handToolRaycastCallback", adsHandTools.handToolRaycastCallback)
    SpecializationUtil.registerFunction(handTool, "setAirBlowerActiveServer", adsHandTools.setAirBlowerActiveServer)
    SpecializationUtil.registerFunction(handTool, "setAirBlowerTargetServer", adsHandTools.setAirBlowerTargetServer)
    SpecializationUtil.registerFunction(handTool, "tryUseGreaseGunServer", adsHandTools.tryUseGreaseGunServer)
    SpecializationUtil.registerFunction(handTool, "handleJumperCablesActionServer", adsHandTools.handleJumperCablesActionServer)
    SpecializationUtil.registerFunction(handTool, "applyJumperCablesState", adsHandTools.applyJumperCablesState)
end

function adsHandTools.registerEventListeners(handTool)
    SpecializationUtil.registerEventListener(handTool, "onLoad", adsHandTools)
    SpecializationUtil.registerEventListener(handTool, "onPostLoad", adsHandTools)
    SpecializationUtil.registerEventListener(handTool, "onDelete", adsHandTools)
    SpecializationUtil.registerEventListener(handTool, "onUpdate", adsHandTools)
    SpecializationUtil.registerEventListener(handTool, "onHeldStart", adsHandTools)
    SpecializationUtil.registerEventListener(handTool, "onHeldEnd", adsHandTools)
    SpecializationUtil.registerEventListener(handTool, "onRegisterActionEvents", adsHandTools)
end

function adsHandTools:onLoad(savegame)
    ensureSpec(self)
end

function adsHandTools:onPostLoad(savegame)
    local spec = ensureSpec(self)
    spec.toolKind = getToolKind(self)
    spec.activateText = getDefaultActionText(self)
    spec.isActive = false
    spec.activatePressed = false
    spec.raycastVehicle = nil
    spec.raycastVehicleDistance = math.huge
    spec.raycastHitX = nil
    spec.raycastHitY = nil
    spec.raycastHitZ = nil
    spec.raycastHitNX = nil
    spec.raycastHitNY = nil
    spec.raycastHitNZ = nil
    spec.raycastNode = resolveMappedNode(self, "raycastNode")
    spec.leftPairNode = nil
    spec.rightPairNode = nil
    spec.dustEmitterNode = nil
    spec.dustEmitterRootNode = nil
    spec.dustEmitterBaseX = nil
    spec.dustEmitterBaseY = nil
    spec.dustEmitterBaseZ = nil
    spec.dustParticleSystem = nil
    spec.lastAirBlowerHintKey = nil
    spec.serverUseActive = false
    spec.serverTargetVehicle = nil
    spec.lastSentNetworkState = nil
    spec.lastSentUseTargetVehicle = nil
    spec.toolSoundPlaying = false
    spec.airResistanceSoundPlaying = false
    spec.samples = spec.samples or {}

    if self.isClient then
        local xmlSoundFile = loadXMLFile("adsHandToolSounds", self.baseDirectory .. "sounds/ads_sounds.xml")
        if xmlSoundFile ~= nil then
            if spec.toolKind == "airBlower" then
                spec.samples.airBlower = g_soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "airBlowerTool", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
                spec.samples.airBlowerAirResistance = g_soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "airBlowerAirResistanceTool", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
            elseif spec.toolKind == "greaseGun" then
                spec.samples.greaseGun = g_soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "greaseGunTool", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
            elseif spec.toolKind == "jumperCables" then
                spec.samples.jumperCablesConnect = g_soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "jumperCablesConnectTool", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
                spec.samples.jumperCablesDisconnect = g_soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "jumperCablesDisconnectTool", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
                spec.samples.jumperCablesSparks = g_soundManager:loadSampleFromXML(xmlSoundFile, "sounds", "jumperCablesSparksTool", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
            end

            delete(xmlSoundFile)
        end
    end

    if spec.toolKind == "airBlower" then
        spec.dustEmitterNode = resolveMappedNode(self, "dustEmitterNode")
    end

    if spec.toolKind == "airBlower" and spec.dustEmitterNode ~= nil and spec.dustEmitterNode ~= 0 then
        local emitterParent = getParent(spec.dustEmitterNode)
        if emitterParent ~= nil and emitterParent ~= 0 then
            spec.dustEmitterRootNode = emitterParent
        else
            spec.dustEmitterRootNode = spec.dustEmitterNode
        end

        if spec.dustEmitterRootNode ~= nil and spec.dustEmitterRootNode ~= 0 then
            spec.dustEmitterBaseX, spec.dustEmitterBaseY, spec.dustEmitterBaseZ = getTranslation(spec.dustEmitterRootNode)
        end

        local sourceParticleSystem = g_particleSystemManager:getParticleSystem("wheel_dust")

        if sourceParticleSystem ~= nil then
            spec.dustParticleSystem = ParticleUtil.copyParticleSystem(nil, nil, sourceParticleSystem, spec.dustEmitterNode)

            if spec.dustParticleSystem ~= nil then
                ParticleUtil.setEmittingState(spec.dustParticleSystem, false)
            end
        end
    end

    if spec.toolKind == "jumperCables" then
        spec.leftPairNode = resolveMappedNode(self, "leftPair")
        spec.rightPairNode = resolveMappedNode(self, "rightPair")
        spec.connectedVehicleA = nil
        spec.connectedVehicleB = nil
        updateJumperCablesVisibility(self)
    end
end

function adsHandTools:onDelete()
    local spec = ensureSpec(self)

    setToolSoundState(self, false)
    setAirResistanceSoundState(self, false)

    if spec.samples ~= nil then
        if spec.samples.airBlower ~= nil then
            g_soundManager:deleteSample(spec.samples.airBlower)
        end

        if spec.samples.airBlowerAirResistance ~= nil then
            g_soundManager:deleteSample(spec.samples.airBlowerAirResistance)
        end

        if spec.samples.greaseGun ~= nil then
            g_soundManager:deleteSample(spec.samples.greaseGun)
        end

        if spec.samples.jumperCablesConnect ~= nil then
            g_soundManager:deleteSample(spec.samples.jumperCablesConnect)
        end

        if spec.samples.jumperCablesDisconnect ~= nil then
            g_soundManager:deleteSample(spec.samples.jumperCablesDisconnect)
        end

        if spec.samples.jumperCablesSparks ~= nil then
            g_soundManager:deleteSample(spec.samples.jumperCablesSparks)
        end
    end

    if spec.dustParticleSystem ~= nil then
        ParticleUtil.deleteParticleSystem(spec.dustParticleSystem)
        spec.dustParticleSystem = nil
    end
end

-- ==========================================================
--                        EVENTS
-- ==========================================================

function adsHandTools:onHeldStart()
    if g_localPlayer == nil or self:getCarryingPlayer() ~= g_localPlayer then
        return
    end

    local spec = ensureSpec(self)
    spec.isActive = true
    spec.activatePressed = false
    spec.serverUseActive = false
    spec.serverTargetVehicle = nil
    spec.lastAirBlowerHintKey = nil
    spec.lastSentNetworkState = nil
    spec.lastSentUseTargetVehicle = nil

    if spec.toolKind == 'jumperCables' and self.isClient and spec.connectedVehicleA ~= nil and spec.connectedVehicleB ~= nil then
        g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("ads_jumper_cables_both_already_connected"), spec.connectedVehicleA:getFullName(), spec.connectedVehicleB:getFullName()), 2200)
    end

    log_dbg("Hand tool equipped:", getToolKind(self))
end

function adsHandTools:onHeldEnd()
    local spec = ensureSpec(self)

    if not self.isServer and spec.toolKind == "airBlower" and spec.lastSentNetworkState == "start" then
        sendHandToolStateToServer(self, "stop", true)
    end

    spec.isActive = false
    spec.activatePressed = false
    spec.serverUseActive = false
    spec.serverTargetVehicle = nil
    spec.lastAirBlowerHintKey = nil
    spec.lastSentUseTargetVehicle = nil
    setActionText(self, spec.activateText)
    setToolSoundState(self, false)
    setAirResistanceSoundState(self, false)
    resetDustEmitterPosition(self)

    log_dbg("Hand tool unequipped:", getToolKind(self))
end

function adsHandTools:setAirBlowerActiveServer(isActive, connection)
    if not self.isServer then
        return false
    end

    local spec = ensureSpec(self)
    if spec.toolKind ~= "airBlower" then
        return false
    end

    if connection ~= nil then
        local player = g_currentMission ~= nil and g_currentMission.connectionsToPlayer ~= nil and g_currentMission.connectionsToPlayer[connection] or nil
        if player == nil or self.getCarryingPlayer == nil or self:getCarryingPlayer() ~= player then
            return false
        end
    end

    spec.serverUseActive = isActive == true
    if not spec.serverUseActive then
        spec.serverTargetVehicle = nil
    end

    return true
end

function adsHandTools:setAirBlowerTargetServer(targetVehicle, connection)
    if not self.isServer then
        return false
    end

    local spec = ensureSpec(self)
    if spec.toolKind ~= "airBlower" then
        return false
    end

    if connection ~= nil then
        local player = g_currentMission ~= nil and g_currentMission.connectionsToPlayer ~= nil and g_currentMission.connectionsToPlayer[connection] or nil
        if player == nil or self.getCarryingPlayer == nil or self:getCarryingPlayer() ~= player then
            return false
        end
    end

    spec.serverUseActive = true

    local vehicle = normalizeConnectedVehicle(targetVehicle)
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        spec.serverTargetVehicle = nil
        return false
    end

    spec.serverTargetVehicle = vehicle
    return true
end

function adsHandTools:tryUseGreaseGunServer(targetVehicle, connection)
    if not self.isServer then
        return false
    end

    local spec = ensureSpec(self)
    if spec.toolKind ~= "greaseGun" then
        return false
    end

    if connection ~= nil then
        local player = g_currentMission ~= nil and g_currentMission.connectionsToPlayer ~= nil and g_currentMission.connectionsToPlayer[connection] or nil
        if player == nil or self.getCarryingPlayer == nil or self:getCarryingPlayer() ~= player then
            return false
        end
    end

    local vehicle = normalizeConnectedVehicle(targetVehicle)
    if vehicle == nil then
        vehicle = getRaycastVehicle(self, RAYCAST_DISTANCE)
    end

    if vehicle == nil then
        return false
    end

    local vehicleSpec = vehicle.spec_AdvancedDamageSystem
    if vehicleSpec == nil or not vehicleSpec.isVehicleNeedLubricate then
        return false
    end

    if (tonumber(vehicleSpec.lubricationLevel) or 0) >= 1.0 then
        return false
    end

    vehicle:lubricateVehicle()
    return true
end

function adsHandTools:handleJumperCablesActionServer(state, targetVehicle, connection)
    if not self.isServer then
        return false
    end

    local spec = ensureSpec(self)
    if spec.toolKind ~= "jumperCables" then
        return false
    end

    if connection ~= nil then
        local player = g_currentMission ~= nil and g_currentMission.connectionsToPlayer ~= nil and g_currentMission.connectionsToPlayer[connection] or nil
        if player == nil or self.getCarryingPlayer == nil or self:getCarryingPlayer() ~= player then
            return false
        end
    end

    local resultState = "jumperInvalid"
    local vehicle = targetVehicle

    if state ~= "jumperInteract" then
        return false
    end

    -- no ads
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        resultState = "jumperInvalid"

    -- disconect
    elseif vehicle == spec.connectedVehicleA or vehicle == spec.connectedVehicleB then
        if spec.connectedVehicleA ~= nil and spec.connectedVehicleA.clearExternalPowerConnection ~= nil then
            spec.connectedVehicleA:clearExternalPowerConnection(spec.connectedVehicleB)
        elseif spec.connectedVehicleB ~= nil and spec.connectedVehicleB.clearExternalPowerConnection ~= nil then
            spec.connectedVehicleB:clearExternalPowerConnection(spec.connectedVehicleA)
        end

        if vehicle == spec.connectedVehicleA then
            spec.connectedVehicleA = nil
        else
            spec.connectedVehicleB = nil
        end

        resultState = "jumperDisconnected"

    -- connect first
    elseif spec.connectedVehicleA == nil and spec.connectedVehicleB == nil then
        spec.connectedVehicleA = vehicle
        resultState = "jumperSelected"

    -- connect second
    elseif spec.connectedVehicleA == nil or spec.connectedVehicleB == nil then
        local firstVehicle = spec.connectedVehicleA or spec.connectedVehicleB
        local isValid, reason = AdvancedDamageSystem.isValidPowerPair(firstVehicle, vehicle)

        if not isValid then
            if reason == "TOO_FAR" then
                resultState = "jumperTooFar"
            else
                resultState = "jumperInvalid"
            end
        else
            if spec.connectedVehicleB == nil then
                spec.connectedVehicleB = vehicle
            else
                spec.connectedVehicleA = vehicle
            end

            if firstVehicle:establishExternalPowerConnection(vehicle) then
                resultState = "jumperConnected"
            else
                if spec.connectedVehicleA == vehicle then
                    spec.connectedVehicleA = nil
                elseif spec.connectedVehicleB == vehicle then
                    spec.connectedVehicleB = nil
                end

                resultState = "jumperInvalid"
            end
        end
    else
        resultState = "jumperFull"
    end

    broadcastJumperCablesState(self, resultState, vehicle)
    return resultState == "jumperSelected" or resultState == "jumperConnected" or resultState == "jumperDisconnected"
end

function adsHandTools:applyJumperCablesState(state, targetVehicle, connectedVehicleA, connectedVehicleB)
    local spec = ensureSpec(self)
    spec.connectedVehicleA = connectedVehicleA
    spec.connectedVehicleB = connectedVehicleB
    updateJumperCablesVisibility(self)

    if not self.isClient or g_localPlayer == nil or self.getCarryingPlayer == nil or self:getCarryingPlayer() ~= g_localPlayer then
        return
    end

    local targetName = targetVehicle ~= nil and targetVehicle.getFullName ~= nil and targetVehicle:getFullName() or nil
    local firstVehicle = spec.connectedVehicleA or spec.connectedVehicleB
    local firstVehicleName = firstVehicle ~= nil and firstVehicle.getFullName ~= nil and firstVehicle:getFullName() or nil

    if state == "jumperSelected" and targetName ~= nil then
        g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("ads_jumper_cables_connected"), targetName), 2200)
        if spec.samples ~= nil and spec.samples.jumperCablesConnect ~= nil then
            g_soundManager:playSample(spec.samples.jumperCablesConnect)
        end
    elseif state == "jumperConnected" and targetName ~= nil then
        g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("ads_jumper_cables_connected"), targetName), 2200)
        if spec.samples ~= nil and spec.samples.jumperCablesConnect ~= nil then
            g_soundManager:playSample(spec.samples.jumperCablesConnect)
        end
        if spec.samples ~= nil and spec.samples.jumperCablesSparks ~= nil then
            g_soundManager:playSample(spec.samples.jumperCablesSparks)
        end
    elseif state == "jumperDisconnected" and targetName ~= nil then
        g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("ads_jumper_cables_disconnected"), targetName), 2200)
        if spec.samples ~= nil and spec.samples.jumperCablesDisconnect ~= nil then
            g_soundManager:playSample(spec.samples.jumperCablesDisconnect)
        end
    elseif state == "jumperAutoDisconnected" then
        g_currentMission:showBlinkingWarning(g_i18n:getText("ads_jumper_cables_auto_disconnected"), 2200)
        if spec.samples ~= nil and spec.samples.jumperCablesDisconnect ~= nil then
            g_soundManager:playSample(spec.samples.jumperCablesDisconnect)
        end
    elseif state == "jumperTooFar" and targetName ~= nil and firstVehicleName ~= nil then
        g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("ads_jumper_cables_is_too_far"), targetName, firstVehicleName), 2200)
    elseif state == "jumperFull" and spec.connectedVehicleA ~= nil and spec.connectedVehicleB ~= nil then
        g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("ads_jumper_cables_both_already_connected"), spec.connectedVehicleA:getFullName(), spec.connectedVehicleB:getFullName()), 2200)
    elseif state == "jumperInvalid" then
        g_currentMission:showBlinkingWarning(g_i18n:getText("ads_jumper_cables_impossible_to_connect"), 2200)
    end
end

-- ==========================================================
--                        CALLBACKS
-- ==========================================================

function adsHandTools:onRegisterActionEvents()
    local spec = ensureSpec(self)
    if not self:getIsActiveForInput(true) then
        return
    end

    if spec.activateText == nil or spec.activateText == "" then
        return
    end

    local _, eventId = self:addActionEvent(
        InputAction.ACTIVATE_HANDTOOL,
        self,
        adsHandTools.onActionCallback,
        true,
        true,
        false,
        true,
        nil
    )

    spec.activateActionEventId = eventId

    if eventId ~= nil then
        g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_HIGH)
        g_inputBinding:setActionEventText(eventId, spec.activateText)
        g_inputBinding:setActionEventActive(eventId, true)
    end
end

function adsHandTools:onActionCallback(actionName, inputValue)
    local spec = ensureSpec(self)
    local isPressed = inputValue > 0

    if not spec.isActive then
        return
    end

    spec.activatePressed = isPressed

    --- airBlower
    if not isPressed then
        if spec.toolKind == "airBlower" then
            if self.isServer then
                spec.serverUseActive = false
                spec.serverTargetVehicle = nil
            else
                sendHandToolStateToServer(self, "stop")
            end
        end

        spec.lastAirBlowerHintKey = nil
        setActionText(self, spec.activateText)
        setToolSoundState(self, false)
        setAirResistanceSoundState(self, false)
        resetDustEmitterPosition(self)
        return
    end

    if spec.toolKind == "airBlower" then
        if self.isServer then
            spec.serverUseActive = true
        else
            sendHandToolStateToServer(self, "start")
        end
    end

    local vehicle = getRaycastVehicle(self, RAYCAST_DISTANCE)

    --- greaseGun
    if vehicle ~= nil and spec.toolKind == "greaseGun" then
        local vehicleSpec = vehicle.spec_AdvancedDamageSystem
        if vehicleSpec ~= nil and vehicleSpec.isVehicleNeedLubricate and (tonumber(vehicleSpec.lubricationLevel) or 0) < 1.0 then
            if self.isServer then
                self:tryUseGreaseGunServer(vehicle)
            else
                sendHandToolStateToServer(self, "use", true, vehicle)
            end

            if self.isClient and spec.samples ~= nil and spec.samples.greaseGun ~= nil then
                g_soundManager:playSample(spec.samples.greaseGun)
            end
        elseif vehicleSpec ~= nil and not vehicleSpec.isVehicleNeedLubricate then
            if self.isClient then
                g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("ads_grease_gun_lubrication_not_require"), vehicle:getFullName()), 2200)
            end
        else
            if self.isClient then
                g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("ads_grease_gun_already_lubricated"), vehicle:getFullName()), 2200)
            end
        end
    end

    --- jumperCables
    if vehicle ~= nil and spec.toolKind == "jumperCables" then
        local vehicleSpec = vehicle.spec_AdvancedDamageSystem
        if vehicleSpec ~= nil then
            if self.isServer then
                self:handleJumperCablesActionServer("jumperInteract", vehicle)
            else
                ADS_JumperCablesEvent.sendRequest(self, "jumperInteract", vehicle)
            end
        else
            g_currentMission:showBlinkingWarning(g_i18n:getText("ads_jumper_cables_impossible_to_connect"), 2200)
        end
    end

    --- airBlower
    if vehicle ~= nil and spec.toolKind == "airBlower" then
        local vehicleSpec = vehicle.spec_AdvancedDamageSystem
        local needsBlowOut = vehicleSpec ~= nil and vehicleSpec.isVehicleNeedBlowOut == true
        local isAlreadyClean = vehicleSpec ~= nil
            and (tonumber(vehicleSpec.radiatorClogging) or 0) <= 0
            and (tonumber(vehicleSpec.airIntakeClogging) or 0) <= 0

        if not needsBlowOut and self.isClient then
            g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("ads_air_blower_cleaning_not_require"), vehicle:getFullName()), 2200)
        elseif isAlreadyClean and self.isClient then
            g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("ads_air_blower_already_clean"), vehicle:getFullName()), 2200)
        end
    end

    if vehicle == nil then
        if spec.toolKind == "airBlower" and self.isClient then
            g_currentMission:showBlinkingWarning(g_i18n:getText("ads_air_blower_no_vehicle"), 2200)
        elseif spec.toolKind == "greaseGun" and self.isClient then
            g_currentMission:showBlinkingWarning(g_i18n:getText("ads_grease_gun_no_vehicle"), 2200)
        end
    end
end

function adsHandTools:handToolRaycastCallback(hitActorId, x, y, z, distance, nx, ny, nz, subShapeIndex, hitShapeId)
    local spec = ensureSpec(self)
    local vehicle = g_currentMission.nodeToObject[hitActorId] or g_currentMission:getNodeObject(hitActorId)

    if vehicle == nil and hitShapeId ~= nil and hitShapeId ~= 0 then
        local parentId = hitShapeId
        while parentId ~= 0 do
            vehicle = g_currentMission.nodeToObject[parentId] or g_currentMission:getNodeObject(parentId)
            if vehicle ~= nil then
                break
            end
            parentId = getParent(parentId)
        end
    end

    if vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil and distance < (spec.raycastVehicleDistance or math.huge) then
        spec.raycastVehicle = vehicle
        spec.raycastVehicleDistance = distance
        spec.raycastHitX = x
        spec.raycastHitY = y
        spec.raycastHitZ = z
        spec.raycastHitNX = nx
        spec.raycastHitNY = ny
        spec.raycastHitNZ = nz
    end
end

-- ==========================================================
--                        UPDATE
-- ==========================================================

function adsHandTools:onUpdate(dt)
    local spec = ensureSpec(self)
    local isUsing = spec.activatePressed or (self.isServer and spec.serverUseActive)
    local isOperational = spec.isActive or (self.isServer and spec.serverUseActive)

    if spec.toolKind == "jumperCables"
        and self.isServer
        and spec.connectedVehicleA ~= nil
        and spec.connectedVehicleB ~= nil
        and not areVehiclesExternallyConnected(spec.connectedVehicleA, spec.connectedVehicleB) then

        spec.connectedVehicleA = nil
        spec.connectedVehicleB = nil
        updateJumperCablesVisibility(self)
        broadcastJumperCablesState(self, "jumperAutoDisconnected", nil)
    end

    if not isOperational then
        spec.lastAirBlowerHintKey = nil
        setToolSoundState(self, false)
        setAirResistanceSoundState(self, false)
        if spec.dustParticleSystem ~= nil then
            ParticleUtil.setEmittingState(spec.dustParticleSystem, false)
        end
        resetDustEmitterPosition(self)
        return
    end

    if not isUsing then
        spec.lastAirBlowerHintKey = nil
        setToolSoundState(self, false)
        setAirResistanceSoundState(self, false)
        if spec.dustParticleSystem ~= nil then
            ParticleUtil.setEmittingState(spec.dustParticleSystem, false)
        end
        resetDustEmitterPosition(self)
        return
    end

    setToolSoundState(self, spec.toolKind == "airBlower")

    local vehicle = nil
    if spec.toolKind == "airBlower" and self.isServer and not self.isClient then
        vehicle = normalizeConnectedVehicle(spec.serverTargetVehicle)
    else
        vehicle = getRaycastVehicle(self, RAYCAST_DISTANCE)
    end

    if vehicle == nil then
        if spec.toolKind == "airBlower" and not self.isServer then
            sendHandToolStateToServer(self, "use", false, nil)
        end

        spec.lastAirBlowerHintKey = nil
        setActionText(self, spec.activateText)
        setAirResistanceSoundState(self, false)
        if spec.dustParticleSystem ~= nil then
            ParticleUtil.setEmittingState(spec.dustParticleSystem, false)
        end
        resetDustEmitterPosition(self)
        return
    end

    if spec.toolKind == "airBlower" then
        local vehicleSpec = vehicle.spec_AdvancedDamageSystem
        local needsBlowOut = vehicleSpec ~= nil and vehicleSpec.isVehicleNeedBlowOut == true
        local isAlreadyClean = vehicleSpec ~= nil
            and (tonumber(vehicleSpec.radiatorClogging) or 0) <= 0
            and (tonumber(vehicleSpec.airIntakeClogging) or 0) <= 0
        local vehicleId = tostring(vehicle.uniqueId or vehicle.id or vehicle.rootNode or vehicle:getFullName())
        local hintKey = nil

        if not needsBlowOut then
            hintKey = vehicleId .. ":not_require"
            if spec.lastAirBlowerHintKey ~= hintKey then
                if self.isClient then
                    g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("ads_air_blower_cleaning_not_require"), vehicle:getFullName()), 2200)
                end
            end
        elseif isAlreadyClean then
            hintKey = vehicleId .. ":already_clean"
            if spec.lastAirBlowerHintKey ~= hintKey then
                if self.isClient then
                    g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("ads_air_blower_already_clean"), vehicle:getFullName()), 2200)
                end
            end
        end

        spec.lastAirBlowerHintKey = hintKey
        setAirResistanceSoundState(self, true)

        if not self.isServer then
            local targetVehicle = needsBlowOut and not isAlreadyClean and vehicle or nil
            sendHandToolStateToServer(self, "use", false, targetVehicle)
        end

        if self.isServer and needsBlowOut then
            vehicle:cleanRadiatorAndAirIntake(dt)
        end

        if self.isClient then
            local currentAirIntakeClogging = tonumber(vehicleSpec ~= nil and vehicleSpec.airIntakeClogging or 0) or 0
            local currentRadiatorClogging = tonumber(vehicleSpec ~= nil and vehicleSpec.radiatorClogging or 0) or 0
            local hasCleaningDust = currentAirIntakeClogging > 0 or currentRadiatorClogging > 0
            local dustScale = math.max((currentAirIntakeClogging + currentRadiatorClogging) / 20, 0.01)
            local dustLifespan = math.clamp((currentAirIntakeClogging + currentRadiatorClogging) * 1200, 600, 1200)

            if spec.dustParticleSystem ~= nil and hasCleaningDust then
                setDustEmitterDistance(self, spec.raycastVehicleDistance)
                ParticleUtil.setEmitCountScale(spec.dustParticleSystem, dustScale)
                ParticleUtil.setParticleLifespan(spec.dustParticleSystem, dustLifespan)
                ParticleUtil.setEmittingState(spec.dustParticleSystem, true)
            elseif spec.dustParticleSystem ~= nil then
                ParticleUtil.setEmittingState(spec.dustParticleSystem, false)
                resetDustEmitterPosition(self)
            end
        end
    else
        setAirResistanceSoundState(self, false)
        if spec.dustParticleSystem ~= nil then
            ParticleUtil.setEmittingState(spec.dustParticleSystem, false)
        end
        resetDustEmitterPosition(self)
        return
    end
end
