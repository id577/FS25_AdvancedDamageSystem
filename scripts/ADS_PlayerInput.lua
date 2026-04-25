local adsInspectionVehicle = nil
local adsInspectionActionId = nil
local adsNotificationAcceptActionIds = {}

local adsInspectionHoldVehicle = nil
local adsInspectionHoldTime = 0
local adsInspectionHoldThreshold = 600
local adsInspectionHoldTriggered = false

local adsActiveInspectionVehicle = nil
local adsInspectionProgressPercent = -1
local adsInspectionMaxDistance = 6.0


local function adsResetInspectionHoldState()
    adsInspectionHoldVehicle = nil
    adsInspectionHoldTime = 0
    adsInspectionHoldTriggered = false
end

local function adsGetInspectionVehicleFromTargeter(player)
    local object = nil

    if player.targeter ~= nil then
        local node = player.targeter:getClosestTargetedNodeFromType(PlayerInputComponent)

        if node ~= nil then
            object = g_currentMission:getNodeObject(node)
        end
    end

    if object == nil then
        return nil
    end

    local spec = object.spec_AdvancedDamageSystem
    if spec == nil or spec.isExcludedVehicle then
        return nil
    end

    if g_currentMission ~= nil and g_currentMission.accessHandler ~= nil and not g_currentMission.accessHandler:canPlayerAccess(object, player) then
        return nil
    end

    return object
end

local function adsCancelActiveInspection(reasonText)
    local vehicle = adsActiveInspectionVehicle
    if vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil then
        local spec = vehicle.spec_AdvancedDamageSystem
        local inspection = spec.fieldInspection

        if inspection ~= nil then
            inspection.isActive = false
            inspection.elapsedTime = 0
            inspection.startTime = 0
            inspection.targetNode = nil
            inspection.targetVehicle = nil
            inspection.wasSoundStarted = false
        end

        if spec.samples ~= nil and spec.samples.inspection ~= nil then
            g_soundManager:stopSample(spec.samples.inspection)
        end
    end

    adsActiveInspectionVehicle = nil
    adsInspectionProgressPercent = -1

    if reasonText ~= nil and reasonText ~= "" then
        ADS_Hud.showNotification(reasonText, 1500)
    else
        ADS_Hud.hideNotification()
    end
end

local function adsCompleteActiveInspection()
    local vehicle = adsActiveInspectionVehicle
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        adsCancelActiveInspection()
        return
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    local inspection = spec.fieldInspection

    if inspection ~= nil then
        inspection.isActive = false
        inspection.elapsedTime = inspection.duration
        inspection.startTime = 0
        inspection.targetNode = nil
        inspection.targetVehicle = nil
        inspection.wasSoundStarted = false
    end

    adsActiveInspectionVehicle = nil
    adsInspectionProgressPercent = -1
    ADS_Hud.hideNotification()

    if ADS_InspectionDialog ~= nil then
        ADS_InspectionDialog.show(vehicle)
    end
end

local function adsUpdateActiveInspection(inputComponent, dt)
    local vehicle = adsActiveInspectionVehicle
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        return
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    local inspection = spec.fieldInspection
    local player = inputComponent.player

    if inspection == nil or not inspection.isActive then
        adsCancelActiveInspection()
        return
    end

    if player == nil or not player.isControlled then
        adsCancelActiveInspection()
        return
    end

    if player:getIsInVehicle() or player:getAreHandsHoldingObject() or player:getIsHoldingHandTool() then
        adsCancelActiveInspection(g_i18n:getText("ads_field_inspection_cancelled"))
        return
    end

    local currentTargetVehicle = adsGetInspectionVehicleFromTargeter(player)
    if currentTargetVehicle ~= vehicle then
        adsCancelActiveInspection(g_i18n:getText("ads_field_inspection_cancelled"))
        return
    end

    if player.rootNode == nil then
        adsCancelActiveInspection(g_i18n:getText("ads_field_inspection_cancelled"))
        return
    end

    local distance = vehicle:getDistanceToNode(player.rootNode)
    if distance == nil or distance > adsInspectionMaxDistance then
        adsCancelActiveInspection(g_i18n:getText("ads_field_inspection_cancelled"))
        return
    end

    inspection.elapsedTime = math.min(inspection.elapsedTime + dt, inspection.duration)

    local percent = math.floor((inspection.elapsedTime / math.max(inspection.duration, 1)) * 100)
    if percent ~= adsInspectionProgressPercent then
        adsInspectionProgressPercent = percent
        ADS_Hud.showNotification(string.format(g_i18n:getText("ads_field_inspection_progress"), percent), 250)
    end

    if inspection.elapsedTime >= inspection.duration then
        adsCompleteActiveInspection()
    end
end

local function adsOnInputFieldInspection(actionName, inputValue, callbackState, isAnalog)
    if adsActiveInspectionVehicle ~= nil then
        return
    end

    if adsInspectionVehicle == nil then
        adsResetInspectionHoldState()
        return
    end

    if inputValue == 0 then
        adsResetInspectionHoldState()
        return
    end

    if adsInspectionHoldVehicle ~= adsInspectionVehicle then
        adsInspectionHoldVehicle = adsInspectionVehicle
        adsInspectionHoldTime = 0
        adsInspectionHoldTriggered = false
    end

    if adsInspectionHoldTriggered then
        return
    end

    adsInspectionHoldTime = adsInspectionHoldTime + g_currentDt

    if adsInspectionHoldTime >= adsInspectionHoldThreshold then
        adsInspectionHoldTriggered = true

        if adsInspectionHoldVehicle ~= nil and adsInspectionHoldVehicle.startFieldVisualInspectionProcess ~= nil then
            local started = adsInspectionHoldVehicle:startFieldVisualInspectionProcess()

            if started then
                adsActiveInspectionVehicle = adsInspectionHoldVehicle
                adsInspectionProgressPercent = -1
            end
        end

        adsResetInspectionHoldState()
    end
end

local function adsOnPlayerInputComponentUpdate(inputComponent, superFunc, dt)
    superFunc(inputComponent, dt)

    if #adsNotificationAcceptActionIds > 0 then
        local canCloseNotification = ADS_Main ~= nil
            and ADS_Main.hud ~= nil
            and ADS_Main.hud.hasClosableNotification ~= nil
            and ADS_Main.hud:hasClosableNotification()
            and (g_gui == nil or not g_gui:getIsGuiVisible())

        for _, actionId in ipairs(adsNotificationAcceptActionIds) do
            g_inputBinding:setActionEventActive(actionId, canCloseNotification)
        end
    end

    if not inputComponent.player.isOwner
        or g_inputBinding:getContextName() ~= PlayerInputComponent.INPUT_CONTEXT_NAME
        or adsInspectionActionId == nil then
        return
    end

    if adsActiveInspectionVehicle ~= nil then
        g_inputBinding:setActionEventActive(adsInspectionActionId, false)
        adsUpdateActiveInspection(inputComponent, dt)
        return
    end

    local previousVehicle = adsInspectionVehicle
    adsInspectionVehicle = nil

    local player = inputComponent.player
    if player.isControlled
        and not player:getIsInVehicle()
        and not player:getAreHandsHoldingObject()
        and not player:getIsHoldingHandTool() then
        adsInspectionVehicle = adsGetInspectionVehicleFromTargeter(player)
    end

    if adsInspectionVehicle ~= previousVehicle then
        adsResetInspectionHoldState()
    end

    local isActive = adsInspectionVehicle ~= nil
    g_inputBinding:setActionEventActive(adsInspectionActionId, isActive)

    if isActive then
        g_inputBinding:setActionEventText(adsInspectionActionId, g_i18n:getText("ads_field_inspection_hold_to_start"))
    else
        adsResetInspectionHoldState()
    end
end

local function adsOnPlayerInputComponentRegisterActionEvents(inputComponent)
    if not inputComponent.player.isOwner then
        return
    end

    g_inputBinding:beginActionEventsModification(PlayerInputComponent.INPUT_CONTEXT_NAME)

    local _, eventId = g_inputBinding:registerActionEvent(
        InputAction.ADS_FIELD_INSPECTION,
        inputComponent,
        adsOnInputFieldInspection,
        true,
        true,
        true,
        true,
        nil,
        true
    )

    adsInspectionActionId = eventId

    if adsInspectionActionId ~= nil then
        g_inputBinding:setActionEventActive(adsInspectionActionId, false)
        g_inputBinding:setActionEventTextPriority(adsInspectionActionId, GS_PRIO_NORMAL)
    end

    g_inputBinding:endActionEventsModification()
end

local function adsOnInputConfirmNotification(actionName, inputValue, callbackState, isAnalog)
    if inputValue == 0 or ADS_Main == nil or ADS_Main.hud == nil then
        return
    end

    if g_gui ~= nil and g_gui:getIsGuiVisible() then
        return
    end

    ADS_Main.hud:onNotificationConfirm(actionName, inputValue)
end

local function adsOnPlayerInputComponentRegisterGlobalPlayerActionEvents(inputComponent, superFunc, ...)
    superFunc(inputComponent, ...)

    if not inputComponent.player.isOwner then
        return
    end

    adsNotificationAcceptActionIds = {}

    local _, menuAcceptId = g_inputBinding:registerActionEvent(
        InputAction.MENU_ACCEPT,
        inputComponent,
        adsOnInputConfirmNotification,
        false,
        true,
        false,
        true,
        nil,
        true
    )

    if menuAcceptId ~= nil then
        g_inputBinding:setActionEventTextVisibility(menuAcceptId, false)
        g_inputBinding:setActionEventActive(menuAcceptId, false)
        table.insert(adsNotificationAcceptActionIds, menuAcceptId)
    end

    local _, skipMessageId = g_inputBinding:registerActionEvent(
        InputAction.SKIP_MESSAGE_BOX,
        inputComponent,
        adsOnInputConfirmNotification,
        false,
        true,
        false,
        true,
        nil,
        true
    )

    if skipMessageId ~= nil then
        g_inputBinding:setActionEventTextVisibility(skipMessageId, false)
        g_inputBinding:setActionEventActive(skipMessageId, false)
        table.insert(adsNotificationAcceptActionIds, skipMessageId)
    end
end

PlayerInputComponent.update = Utils.overwrittenFunction(PlayerInputComponent.update, adsOnPlayerInputComponentUpdate)
PlayerInputComponent.registerActionEvents = Utils.appendedFunction(PlayerInputComponent.registerActionEvents, adsOnPlayerInputComponentRegisterActionEvents)
PlayerInputComponent.registerGlobalPlayerActionEvents = Utils.overwrittenFunction(PlayerInputComponent.registerGlobalPlayerActionEvents, adsOnPlayerInputComponentRegisterGlobalPlayerActionEvents)
