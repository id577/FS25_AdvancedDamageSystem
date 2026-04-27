-- ADS_ServiceRequestEvent
-- Client-to-server event. Sends a service request (inspection/maintenance/repair/overhaul)
-- to the server for authoritative execution.

ADS_ServiceRequestEvent = {}
local ADS_ServiceRequestEvent_mt = Class(ADS_ServiceRequestEvent, Event)

InitEventClass(ADS_ServiceRequestEvent, "ADS_ServiceRequestEvent")


function ADS_ServiceRequestEvent.emptyNew()
    return Event.new(ADS_ServiceRequestEvent_mt)
end


function ADS_ServiceRequestEvent.new(vehicle, serviceType, workshopType, optionOne, optionTwo, optionThree, price)
    local self = ADS_ServiceRequestEvent.emptyNew()
    self.vehicle = vehicle
    self.serviceType = serviceType
    self.workshopType = workshopType
    self.optionOne = optionOne
    self.optionTwo = optionTwo
    self.optionThree = optionThree
    self.price = price
    return self
end


function ADS_ServiceRequestEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteString(streamId, self.serviceType or "")
    streamWriteString(streamId, self.workshopType or "")
    streamWriteString(streamId, self.optionOne or "")
    streamWriteString(streamId, self.optionTwo or "")
    streamWriteBool(streamId, self.optionThree or false)
    streamWriteFloat32(streamId, self.price or 0)
end


function ADS_ServiceRequestEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.serviceType = streamReadString(streamId)
    self.workshopType = streamReadString(streamId)
    self.optionOne = streamReadString(streamId)
    self.optionTwo = streamReadString(streamId)
    self.optionThree = streamReadBool(streamId)
    self.price = streamReadFloat32(streamId)

    if self.optionOne == "" then self.optionOne = nil end
    if self.optionTwo == "" then self.optionTwo = nil end
    if self.workshopType == "" then self.workshopType = nil end

    self:run(connection)
end


-- Server-side execution: validate vehicle, run initService, debit money.
-- Price is recalculated server-side to prevent client tampering.
function ADS_ServiceRequestEvent:run(connection)
    if not connection:getIsServer() then
        if self.vehicle ~= nil and self.vehicle:getIsSynchronized() and self.vehicle.spec_AdvancedDamageSystem ~= nil then
            local userId = g_currentMission.userManager:getUserIdByConnection(connection)
            local farm = g_farmManager:getFarmByUserId(userId)
            if farm == nil or farm.farmId ~= self.vehicle:getOwnerFarmId() then
                return
            end

            local spec = self.vehicle.spec_AdvancedDamageSystem
            if spec.currentState ~= AdvancedDamageSystem.STATUS.READY then
                return
            end

            local validTypes = {
                [AdvancedDamageSystem.STATUS.INSPECTION] = true,
                [AdvancedDamageSystem.STATUS.MAINTENANCE] = true,
                [AdvancedDamageSystem.STATUS.REPAIR] = true,
                [AdvancedDamageSystem.STATUS.OVERHAUL] = true
            }
            if not validTypes[self.serviceType] then
                return
            end

            if ADS_Main ~= nil
                and ADS_Main.isWorkshopTypeOpen ~= nil
                and not ADS_Main:isWorkshopTypeOpen(self.workshopType) then
                return
            end

            local serverPrice = self.vehicle:getServicePrice(self.serviceType, self.optionOne, self.optionTwo, self.optionThree, self.workshopType) or 0

            self.vehicle:initService(self.serviceType, self.workshopType, self.optionOne, self.optionTwo, self.optionThree)

            if serverPrice > 0 then
                g_currentMission:addMoney(-1 * serverPrice, self.vehicle:getOwnerFarmId(), MoneyType.VEHICLE_RUNNING_COSTS, true, true)
            end

            ADS_VehicleChangeStatusEvent.send(self.vehicle)
        end
    end
end


-- Client convenience: send service request to the server.
function ADS_ServiceRequestEvent.send(vehicle, serviceType, workshopType, optionOne, optionTwo, optionThree, price)
    if g_client ~= nil then
        g_client:getServerConnection():sendEvent(ADS_ServiceRequestEvent.new(vehicle, serviceType, workshopType, optionOne, optionTwo, optionThree, price))
    end
end
