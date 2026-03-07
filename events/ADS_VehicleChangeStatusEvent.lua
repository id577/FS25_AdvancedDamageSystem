-- ADS_VehicleChangeStatusEvent
-- Server-to-client broadcast. Notifies clients of ADS state changes
-- (service completion, cancellation, status transition).
-- Carries an optional HUD notification string; bulk state data is
-- synchronised via the update-stream dirty-flag pipeline.

ADS_VehicleChangeStatusEvent = {}
local ADS_VehicleChangeStatusEvent_mt = Class(ADS_VehicleChangeStatusEvent, Event)
MessageType.ADS_VEHICLE_CHANGE_STATUS = nextMessageTypeId()

InitEventClass(ADS_VehicleChangeStatusEvent, "ADS_VehicleChangeStatusEvent")


function ADS_VehicleChangeStatusEvent.emptyNew()
    return Event.new(ADS_VehicleChangeStatusEvent_mt)
end


function ADS_VehicleChangeStatusEvent.new(vehicle, notificationText)
    local self = ADS_VehicleChangeStatusEvent.emptyNew()
    self.vehicle = vehicle
    self.notificationText = notificationText or ""
    return self
end


function ADS_VehicleChangeStatusEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteString(streamId, self.notificationText or "")
end


function ADS_VehicleChangeStatusEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.notificationText = streamReadString(streamId)
    self:run(connection)
end


function ADS_VehicleChangeStatusEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:recalculateAndApplyEffects()
        self.vehicle:recalculateAndApplyIndicators()

        -- Client-side: show HUD notification + play completion sound
        if connection:getIsServer() and self.notificationText ~= nil and self.notificationText ~= "" then
            if g_currentMission ~= nil and g_currentMission.hud ~= nil then
                g_currentMission.hud:addSideNotification({1, 1, 1, 1}, self.notificationText)
            end
            local spec = self.vehicle.spec_AdvancedDamageSystem
            if spec ~= nil and spec.samples ~= nil and spec.samples.maintenanceCompleted ~= nil then
                g_soundManager:playSample(spec.samples.maintenanceCompleted)
            end
        end

        g_messageCenter:publish(MessageType.ADS_VEHICLE_CHANGE_STATUS, self.vehicle)
    end

    -- Server relay: re-broadcast if received from a client (with ownership check)
    if not connection:getIsServer() then
        if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
            local userId = g_currentMission.userManager:getUserIdByConnection(connection)
            local farm = g_farmManager:getFarmByUserId(userId)
            if farm ~= nil and farm.farmId == self.vehicle:getOwnerFarmId() then
                g_server:broadcastEvent(ADS_VehicleChangeStatusEvent.new(self.vehicle, self.notificationText), nil, connection, self.vehicle)
            end
        end
    end
end


-- Server convenience: broadcast status change to all clients.
function ADS_VehicleChangeStatusEvent.send(vehicle, notificationText)
    if g_server ~= nil then
        g_server:broadcastEvent(ADS_VehicleChangeStatusEvent.new(vehicle, notificationText or ""), nil, nil, vehicle)
    end
end
