ADS_Consumptables = ADS_Consumptables or {}

-- ==========================================================
--                  HELPER FUNCTIONS
-- ==========================================================

local function raiseFieldcareDirty(vehicle, spec)
    if vehicle ~= nil
        and vehicle.isServer
        and spec ~= nil
        and spec.adsDirtyFlag_fieldcare ~= nil
        and vehicle.raiseDirtyFlags ~= nil then
        vehicle:raiseDirtyFlags(spec.adsDirtyFlag_fieldcare)
    end
end

-- ==========================================================
--                      ENGINE
-- ==========================================================

local function updateMotorOilState(spec, motorLoad, motorTemp, dtMultiplier)
    local C = ADS_Config.CONSUMABLES

    spec.motorOil = spec.motorOil or { level = 1.0, quality = 1.0 , contamination = 0.0, dilution = 0.0}
    spec.oilFilterClogging = spec.oilFilterClogging or 0.0
    spec.engineLubricationLevel = spec.engineLubricationLevel or 1.0
    spec.debugData = spec.debugData or {}
    spec.debugData.engConsumptables = spec.debugData.engConsumptables or {}

    local motorLoadFactor = ADS_Utils.calculateQuadraticMultiplier(motorLoad, C.MOTOR_OIL_OVERLOAD_THRESHOLD, false, 1.05)
    local motorTempFactor = ADS_Utils.calculateQuadraticMultiplier(motorTemp, C.MOTOR_OIL_OVERHEAT_THRESHOLD, false, 120)
    local engineCondition = spec.systems ~= nil and spec.systems.engine ~= nil and spec.systems.engine.condition or 1.0
    local engineWearFactor = ADS_Utils.calculateQuadraticMultiplier(engineCondition or 1.0, 0.66, true)

    local loadInfluence = motorLoadFactor * (C.MOTOR_OIL_OVERLOAD_FACTOR or 0)
    local tempInfluence = motorTempFactor * (C.MOTOR_OIL_OVERHEAT_FACTOR or 0)
    local wearInfluence = engineWearFactor * (C.MOTOR_OIL_ENGINE_WEAR_FACTOR or 0)
    local wearMultiplier = 1 + loadInfluence + tempInfluence + wearInfluence

    local levelToReduce = C.MOTOR_OIL_BURN_RATE * wearMultiplier * dtMultiplier
    local qualityToReduce = C.MOTOR_OIL_QUALITY_DEGRADATION_RATE * wearMultiplier * dtMultiplier
    local contaminationToAdd = C.MOTOR_OIL_CONTAMINATION_RATE * wearMultiplier * dtMultiplier

    spec.motorOil.level = math.max(spec.motorOil.level - levelToReduce, 0.0)
    spec.motorOil.quality = math.max(spec.motorOil.quality - qualityToReduce, 0.0)

    local trappedByFilter = contaminationToAdd * math.min(1 - spec.oilFilterClogging, 0.9)
    local passedByFilter = contaminationToAdd - trappedByFilter

    spec.oilFilterClogging = math.min(spec.oilFilterClogging + trappedByFilter, 1.0)
    spec.motorOil.contamination = math.min(spec.motorOil.contamination + passedByFilter, 1.0)

    local effectiveOilLevel = math.clamp(spec.motorOil.level + 0.2, 0.0, 1.0)
    spec.engineLubricationLevel = math.clamp((effectiveOilLevel + spec.motorOil.quality + (1 - spec.motorOil.contamination)) / 3, 0.01, 1.0)

    local dbg = spec.debugData.engConsumptables
    dbg.motorLoad = motorLoad
    dbg.motorTemp = motorTemp
    dbg.dtMultiplier = dtMultiplier
    dbg.motorLoadFactor = motorLoadFactor
    dbg.motorTempFactor = motorTempFactor
    dbg.engineWearFactor = engineWearFactor
    dbg.loadInfluence = loadInfluence
    dbg.tempInfluence = tempInfluence
    dbg.wearInfluence = wearInfluence
    dbg.stressMultiplier = stressMultiplier
    dbg.wearMultiplier = wearMultiplier
    dbg.levelToReduce = levelToReduce
    dbg.qualityToReduce = qualityToReduce
    dbg.contaminationToAdd = contaminationToAdd
    dbg.filterContamination = trappedByFilter
    dbg.levelToReducePerInterval = dtMultiplier > 0 and levelToReduce / dtMultiplier or 0
    dbg.qualityToReducePerInterval = dtMultiplier > 0 and qualityToReduce / dtMultiplier or 0
    dbg.contaminationToAddPerInterval = dtMultiplier > 0 and contaminationToAdd / dtMultiplier or 0
    dbg.filterContaminationPerInterval = dtMultiplier > 0 and trappedByFilter / dtMultiplier or 0
    dbg.totalOilContamination = filterContamination
    dbg.filterBypassRatio = bypassRatio
    dbg.engineLubricationLevel = spec.engineLubricationLevel
    dbg.motorOilLevel = spec.motorOil.level
    dbg.motorOilQuality = spec.motorOil.quality
    dbg.motorOilContamination = spec.motorOil.contamination
    dbg.oilFilterClogging = spec.oilFilterClogging
end

function ADS_Consumptables:updateEngineConsumables(dt)
    local C = ADS_Config.CONSUMABLES
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil or not self:getIsMotorStarted() then
        return
    end

    local motorTemp = spec.engineTemperature or 0
    local motorLoad = spec.dynamicMotorLoad or self:getMotorLoadPercentage() or 0
   
    local dtMultiplier = ADS_Config.CORE.BASE_SERVICE_WEAR / (1 - ADS_Config.CORE.SERVICE_EXPIRED_THRESHOLD) / (60 * 60 * 1000) * dt

    updateMotorOilState(spec, motorLoad, motorTemp, dtMultiplier)
end



-- ==========================================================
--          RADIATOR AND AIR INTAKE CLOGGING
-- ==========================================================

function ADS_Consumptables:updateRadiatorClogging(dt)
    local C = ADS_Config.FIELD_CARE
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil then
        return
    end

    if not spec.isVehicleNeedBlowOut then
        spec.radiatorClogging = 0
        return
    end

    if spec.debugData == nil then
        spec.debugData = {}
    end
    if spec.debugData.radiator == nil then
        spec.debugData.radiator = {
            fieldFactor = 1.0,
            dustFactor = 0.0,
            debrisFactor = 0.0,
            wetness = 0,
            wetnessFactor = 1.0,
            baseWetnessFactor = 1.0,
            isOnField = false,
            hasDust = false,
            hasDebris = false,
            totalMultiplier = 0.0
        }
    end
    local dbg = spec.debugData.radiator

    local dirtLevel = self:getDirtAmount()
    local lastSpeed = self:getLastSpeed()
    local washableSpec = self.spec_washable
    local weather = g_currentMission ~= nil and g_currentMission.environment ~= nil and g_currentMission.environment.weather or nil
    local wetness = weather ~= nil and weather:getGroundWetness() or 0
    local baseWetnessFactor = math.max(1 - wetness, 0)
    local wetnessFactor = math.max(baseWetnessFactor ^ 3, 0)
    local isOnField = self:getIsOnField()
    local hasDust = isOnField and spec.isImplementLowered and lastSpeed > 0.1
    local hasDebris = spec.isHarvesting
    local fieldFactor = 0.5
    local dustFactor = hasDust and 1.0 or 0.0
    local debrisFactor = hasDebris and 2.0 or 0.0

    if washableSpec ~= nil then
        fieldFactor = isOnField and (washableSpec.fieldMultiplier or 1.0) or 0.5
    end

    dbg.fieldFactor = fieldFactor
    dbg.dustFactor = dustFactor
    dbg.debrisFactor = debrisFactor
    dbg.wetness = wetness
    dbg.wetnessFactor = wetnessFactor
    dbg.baseWetnessFactor = baseWetnessFactor
    dbg.isOnField = isOnField
    dbg.hasDust = hasDust
    dbg.hasDebris = hasDebris
    dbg.totalMultiplier = 0.0

    if lastSpeed > 0.5 and spec.radiatorClogging < dirtLevel then
        if washableSpec == nil then
            return
        end

        local dirtDuration = ((washableSpec.dirtDuration or 0) / 4) * (ADS_Config.CORE.BASE_SERVICE_WEAR * 10)
        local totalMultiplier = wetnessFactor * (fieldFactor + dustFactor + debrisFactor) * C.CLOGGING_SPEED
        dbg.totalMultiplier = totalMultiplier

        local change = dirtDuration * totalMultiplier * dt
        spec.radiatorClogging = math.min(spec.radiatorClogging + change, dirtLevel)
    else
        if spec.radiatorClogging > dirtLevel then
            spec.radiatorClogging = dirtLevel
        end
    end
end

function ADS_Consumptables:updateAirIntakeClogging(dt)
    local C = ADS_Config.FIELD_CARE
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil then
        return
    end

    if not spec.isVehicleNeedBlowOut then
        spec.airIntakeClogging = 0
        return
    end

    if spec.debugData == nil then
        spec.debugData = {}
    end
    if spec.debugData.airIntake == nil then
        spec.debugData.airIntake = {
            fieldFactor = 1.0,
            dustFactor = 0.0,
            debrisFactor = 0.0,
            wetness = 0,
            wetnessFactor = 1.0,
            baseWetnessFactor = 1.0,
            isOnField = false,
            hasDust = false,
            hasDebris = false,
            totalMultiplier = 0.0
        }
    end
    local dbg = spec.debugData.airIntake

    local dirtLevel = self:getDirtAmount()
    local lastSpeed = self:getLastSpeed()
    local washableSpec = self.spec_washable
    local weather = g_currentMission ~= nil and g_currentMission.environment ~= nil and g_currentMission.environment.weather or nil
    local wetness = weather ~= nil and weather:getGroundWetness() or 0
    local baseWetnessFactor = math.max(1 - wetness, 0)
    local wetnessFactor = baseWetnessFactor
    local isOnField = self:getIsOnField()
    local hasDust = isOnField and spec.isImplementLowered and lastSpeed > 0.1
    local hasDebris = spec.isHarvesting
    local fieldFactor = 1.0
    local dustFactor = hasDust and 2.0 or 0.0
    local debrisFactor = hasDebris and 1.0 or 0.0

    if washableSpec ~= nil then
        fieldFactor = isOnField and (washableSpec.fieldMultiplier or 2.0) or 1.0
    end

    dbg.fieldFactor = fieldFactor
    dbg.dustFactor = dustFactor
    dbg.debrisFactor = debrisFactor
    dbg.wetness = wetness
    dbg.wetnessFactor = wetnessFactor
    dbg.baseWetnessFactor = baseWetnessFactor
    dbg.isOnField = isOnField
    dbg.hasDust = hasDust
    dbg.hasDebris = hasDebris
    dbg.totalMultiplier = 0.0

    if lastSpeed > 0.5 and spec.airIntakeClogging < dirtLevel then
        if washableSpec == nil then
            return
        end
        
        local dirtDuration = ((washableSpec.dirtDuration or 0) / 4) * (ADS_Config.CORE.BASE_SERVICE_WEAR * 10)
        local totalMultiplier = wetnessFactor * (fieldFactor + dustFactor + debrisFactor) * C.CLOGGING_SPEED
        dbg.totalMultiplier = totalMultiplier

        local change = dirtDuration * totalMultiplier * dt
        spec.airIntakeClogging = math.min(spec.airIntakeClogging + change, dirtLevel)
    else
        if spec.airIntakeClogging > dirtLevel then
            spec.airIntakeClogging = dirtLevel
        end
    end
end

function ADS_Consumptables:cleanRadiatorAndAirIntake(dt)
    local C = ADS_Config.FIELD_CARE
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil then
        return
    end

    local prevRadiatorClogging = tonumber(spec.radiatorClogging) or 0
    local prevAirIntakeClogging = tonumber(spec.airIntakeClogging) or 0
    local cleaningDelta = (C.CLEANING_SPEED / 1000) * dt

    spec.radiatorClogging = math.max(prevRadiatorClogging - cleaningDelta, 0)
    spec.airIntakeClogging = math.max(prevAirIntakeClogging - cleaningDelta, 0)

    --- tutorial message
    if ADS_Config.TUTORIAL_MESSAGES ~= nil and ADS_Config.TUTORIAL_MESSAGES.RAD_OR_INTAKE_CLOGGED ~= nil and not ADS_Config.TUTORIAL_MESSAGES.RAD_OR_INTAKE_CLOGGED then
        ADS_Config.TUTORIAL_MESSAGES.RAD_OR_INTAKE_CLOGGED = true
    end

    if self.isServer then
        raiseFieldcareDirty(self, spec)
    end
end

-- ==========================================================
--                  LUCRICATION
-- ==========================================================

function ADS_Consumptables:updateLubricationLevel(dt)
    local C = ADS_Config.FIELD_CARE
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil or not spec.isVehicleNeedLubricate then
        return
    end

    local currentDay = g_currentMission.environment.currentDay
    if spec.lastLubricationProcessedDay == nil then
        spec.lastLubricationProcessedDay = currentDay
        return
    end

    local lubricationReducePerDay = math.max(tonumber(C.LUBRICATION_REDUCE_PER_DAY) or 0, 0)
    if currentDay > spec.lastLubricationProcessedDay and not self:getIsMotorStarted() then
        if lubricationReducePerDay > 0 then
            spec.lubricationLevel = math.max(spec.lubricationLevel - lubricationReducePerDay, 0)
        end
        spec.lastLubricationProcessedDay = currentDay
    end
end

function ADS_Consumptables:lubricateVehicle()
    local C = ADS_Config.FIELD_CARE
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil then
        return
    end

    local prevLubricationLevel = tonumber(spec.lubricationLevel) or 0
    spec.lubricationLevel = math.min(prevLubricationLevel + 0.2, 1.0)

    --- tutorial message
    if ADS_Config.TUTORIAL_MESSAGES ~= nil and ADS_Config.TUTORIAL_MESSAGES.NEEDS_LUBRICATION ~= nil and not ADS_Config.TUTORIAL_MESSAGES.NEEDS_LUBRICATION then
        ADS_Config.TUTORIAL_MESSAGES.NEEDS_LUBRICATION = true
    end

    if self.isServer then
        raiseFieldcareDirty(self, spec)
    end
end

function ADS_Consumptables:startFieldVisualInspectionProcess()
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil or spec.isExcludedVehicle then
        return false
    end

    if self.getIsMotorStarted ~= nil and self:getIsMotorStarted() then
        if self.isClient and g_currentMission ~= nil then
            g_currentMission:showBlinkingWarning(g_i18n:getText("ads_field_inspection_engine_must_be_stopped"), 2200)
        end
        return false
    end

    if self:getCurrentStatus() ~= AdvancedDamageSystem.STATUS.READY then
        return false
    end

    local inspection = spec.fieldInspection
    if inspection == nil then
        return false
    end

    if inspection.isActive then
        return false
    end

    inspection.isActive = true
    inspection.elapsedTime = 0
    inspection.duration = ADS_Config.FIELD_CARE.VISUAL_INSPECTION_DURATION
    inspection.startTime = g_time
    inspection.targetVehicle = self
    inspection.wasSoundStarted = false

    local node = self.rootNode
    if (node == nil or node == 0) and self.components ~= nil and self.components[1] ~= nil then
        node = self.components[1].node
    end
    inspection.targetNode = node

    if self.isClient and spec.samples ~= nil and spec.samples.inspection ~= nil then
        g_soundManager:playSample(spec.samples.inspection)
        inspection.wasSoundStarted = true
    end

    if self.isClient and ADS_Hud ~= nil then
        ADS_Hud.showNotification(string.format(g_i18n:getText("ads_field_inspection_progress"), 0), inspection.duration)
    end

    return true
end
