ADS_EffectSyncEvent = {}
local ADS_EffectSyncEvent_mt = Class(ADS_EffectSyncEvent, Event)

InitEventClass(ADS_EffectSyncEvent, "ADS_EffectSyncEvent")


function ADS_EffectSyncEvent.emptyNew()
    return Event.new(ADS_EffectSyncEvent_mt)
end


function ADS_EffectSyncEvent.new(vehicle, effectId, status, timer, extraInt, extraFloat)
    local self = ADS_EffectSyncEvent.emptyNew()
    self.vehicle    = vehicle
    self.effectId   = effectId   or ""
    self.status     = status     or ""
    self.timer      = timer      or 0
    self.extraInt   = extraInt   or 0
    self.extraFloat = extraFloat or 0
    return self
end


function ADS_EffectSyncEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteString(streamId,  self.effectId)
    streamWriteString(streamId,  self.status)
    streamWriteFloat32(streamId, self.timer)
    streamWriteInt32(streamId,   self.extraInt)
    streamWriteFloat32(streamId, self.extraFloat)
end


function ADS_EffectSyncEvent:readStream(streamId, connection)
    self.vehicle    = NetworkUtil.readNodeObject(streamId)
    self.effectId   = streamReadString(streamId)
    self.status     = streamReadString(streamId)
    self.timer      = streamReadFloat32(streamId)
    self.extraInt   = streamReadInt32(streamId)
    self.extraFloat = streamReadFloat32(streamId)
    self:run(connection)
end


function ADS_EffectSyncEvent:run(connection)
    local vehicle = self.vehicle
    if vehicle == nil or not vehicle:getIsSynchronized() then
        return
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then
        return
    end

    local effect = spec.activeEffects[self.effectId]

    if self.effectId == "ENGINE_STALLS_CHANCE" then
        if vehicle.stopMotor then
            vehicle:stopMotor()
        end
        if vehicle.getIsControlled ~= nil and vehicle:getIsControlled() then
            g_currentMission:showBlinkingWarning(g_i18n:getText("ads_breakdowns_engine_stalled_message"), 5000)
        end

    elseif self.effectId == "PTO_AUTO_DISENGAGE_CHANCE" then
        if effect ~= nil then
            effect.extraData = effect.extraData or {}
            effect.extraData.status = self.status
        end

    elseif self.effectId == "PTO_FAILED" then
        if vehicle.getIsControlled ~= nil and vehicle:getIsControlled() then
            g_currentMission:showBlinkingWarning(g_i18n:getText("ads_breakdowns_pto_auto_disengage_message"), 4000)
        end

    elseif self.effectId == "GEAR_SHIFT_FAILURE_CHANCE" then
        if effect and effect.extraData then
            effect.extraData.status = self.status
            effect.extraData.timer  = self.timer
            local motor = vehicle:getMotor()
            if motor and self.extraFloat > 0 then
                motor.gearChangeTimer    = self.extraFloat
                motor.autoGearChangeTimer = self.extraFloat
            end
            if vehicle.spec_AdvancedDamageSystem and self.status == "FAILED" then
                local sampleIdx = math.random(3)
                g_soundManager:playSample(spec.samples['transmissionShiftFailed' .. sampleIdx])
            end
        end

    elseif self.effectId == "GEAR_REJECTION_CHANCE" then
        if effect and effect.extraData then
            effect.extraData.status = self.status
            effect.extraData.timer  = self.timer
            local motor = vehicle:getMotor()
            if motor and motor.setGear then
                motor:setGear(0, false)
            end
            if vehicle.getIsControlled ~= nil and vehicle:getIsControlled() then
                g_soundManager:playSample(spec.samples.gearDisengage1)
                g_currentMission:showBlinkingWarning(g_i18n:getText("ads_breakdowns_gear_disengage_message"), 3000)
            end
        end

    elseif self.effectId == "LIGHTS_FLICKER_CHANCE" then
        if effect and effect.extraData then
            effect.extraData.maskBackup = self.extraInt > 0 and self.extraInt or effect.extraData.maskBackup
            effect.extraData.status = self.status
            effect.extraData.timer  = self.timer
        end

    elseif self.effectId == "ENGINE_HESITATION_CHANCE" then
        if effect and effect.extraData then
            effect.extraData.status = self.status
            effect.extraData.timer  = self.timer
            if self.status == "CHOKING" then
                local cruiseState = vehicle:getCruiseControlState()
                if cruiseState ~= 0 then
                    effect.extraData.cruiseState = cruiseState
                    vehicle:setCruiseControlState(0, true)
                end
            end
        end

    elseif self.effectId == "ENGINE_START_FAILURE_CHANCE" then
        if effect and effect.extraData then
            effect.extraData.status       = self.status
            effect.extraData.timer        = self.timer
            effect.extraData.currentCount = self.extraInt
        end
    end
end


function ADS_EffectSyncEvent.send(vehicle, effectId, status, timer, extraInt, extraFloat)
    if g_server ~= nil then
        g_server:broadcastEvent(ADS_EffectSyncEvent.new(vehicle, effectId, status, timer, extraInt, extraFloat), nil, nil, vehicle)
    end
end
