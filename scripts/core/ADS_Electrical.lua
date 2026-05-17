ADS_Electrical = ADS_Electrical or {}

-- ==========================================================
--                     HELPERS
-- ==========================================================

local function sanitizeNumber(value, fallback, minValue, maxValue)
    if AdvancedDamageSystem ~= nil and AdvancedDamageSystem.sanitizeNumber ~= nil then
        return AdvancedDamageSystem.sanitizeNumber(value, fallback, minValue, maxValue)
    end

    local sanitized = tonumber(value)
    if type(sanitized) ~= "number" or sanitized ~= sanitized or sanitized == math.huge or sanitized == -math.huge then
        sanitized = tonumber(fallback) or 0
    end

    if minValue ~= nil then
        sanitized = math.max(sanitized, minValue)
    end
    if maxValue ~= nil then
        sanitized = math.min(sanitized, maxValue)
    end

    return sanitized
end

-- ==========================================================
--                     MAIN
-- ==========================================================

local function getBatteryTempFactors(tempC)
    local cap = 1.0
    if tempC < 25 then
        cap = math.clamp(1.0 - (25 - tempC) * 0.004, 0.55, 1.0)
    end

    local rint = 1.0
    if tempC < 20 then
        rint = 1.0 + (20 - tempC) * 0.02
    end

    return cap, rint
end

local getBatteryChargeAcceptance

local function evaluateAlternatorRpmCurve(curveData, rpmNorm)
    rpmNorm = math.clamp(rpmNorm or 0, 0, 1)
    if type(curveData) ~= "table" then
        return nil
    end

    local points = {}
    for _, point in pairs(curveData) do
        local x, y
        if type(point) == "table" then
            x = tonumber(point.x or point.rpm or point.rpmNorm or point[1])
            y = tonumber(point.y or point.factor or point.output or point[2])
        end

        if x ~= nil and y ~= nil then
            table.insert(points, {
                x = math.clamp(x, 0, 1),
                y = math.max(y, 0)
            })
        end
    end

    if #points == 0 then
        return nil
    end

    table.sort(points, function(a, b) return a.x < b.x end)

    if rpmNorm <= points[1].x then
        return points[1].y
    end

    for i = 2, #points do
        local p0 = points[i - 1]
        local p1 = points[i]
        if rpmNorm <= p1.x then
            local span = math.max(p1.x - p0.x, 0.000001)
            local t = (rpmNorm - p0.x) / span
            return p0.y + (p1.y - p0.y) * t
        end
    end

    return points[#points].y
end

local function calculateAlternatorOutput(vehicle, isMotorStarted, iLoads, batteryState)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then
        return 0
    end

    local cfg = ADS_Config.ELECTRICAL or {}

    local iAltAvail = 0
    local iAltRaw = 0
    local altFactor = 0
    local acceptK, tempK, socK, healthK = 1.0, 1.0, 1.0, 1.0

    local batteryTempC = spec.batteryTempC
    local batterySoc = spec.batterySoc
    local batteryHealth = spec.batteryHealth

    if batteryState ~= nil then
        batteryTempC = batteryState.tempC
        batterySoc = batteryState.soc
        batteryHealth = batteryState.health
    end

    if isMotorStarted then
        local motor = vehicle:getMotor()
        if motor ~= nil then
            local lastRpm = motor:getLastModulatedMotorRpm() or 0
            local maxRpm = math.max(motor.maxRpm or 1, 1)
            local rpmNorm = math.clamp(lastRpm / maxRpm, 0, 1)

            local curveFactor = evaluateAlternatorRpmCurve(cfg.ALT_RPM_CURVE, rpmNorm)
            if curveFactor == nil then
                local idleFactor = math.clamp(cfg.ALT_IDLE_FACTOR or 0.25, 0, 1)
                curveFactor = idleFactor + (1 - idleFactor) * rpmNorm
            end

            altFactor = math.max(curveFactor, 0)
            iAltRaw = (cfg.ALT_MAX_OUTPUT or 0) * altFactor * math.max(spec.alternatorHealth or 1, 0)

            local loadA = math.max(iLoads or 0, 0)
            local chargeHeadroomA = math.max(iAltRaw - loadA, 0)

            acceptK, tempK, socK, healthK =
                getBatteryChargeAcceptance(batteryTempC, batterySoc, batteryHealth)

            if iAltRaw <= loadA then
                iAltAvail = iAltRaw
            else
                iAltAvail = loadA + chargeHeadroomA * acceptK
            end
        end
    end

    if ADS_Config.DEBUG then
        local dbg = spec.debugData.battery
        dbg.iAltAvail = iAltAvail or 0
        dbg.iAltRaw = iAltRaw or 0
        dbg.altFactor = altFactor or 0
        dbg.acceptK = acceptK
        dbg.acceptTempK = tempK
        dbg.acceptSocK = socK
        dbg.acceptHealthK = healthK
        dbg.acceptSourceSoc = batterySoc or 0
        dbg.acceptSourceTempC = batteryTempC or 0
        dbg.acceptSourceHealth = batteryHealth or 1
        dbg.acceptUsesExternalState = batteryState ~= nil
    end

    return iAltAvail
end

local function calculateCurrentLoadAmps(vehicle, isMotorStarted, envTemp)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then
        return
    end
    local C = ADS_Config.ELECTRICAL or {}

   -- base load
    local baseLoadA = isMotorStarted and 18 or C.IDLE_CURRENT_A or 0.5

    -- cab fan
    local cabFanA = isMotorStarted and 12 or 0

    -- heater
    local winterHeaterA = 0

    if isMotorStarted and envTemp <= 15 then
        winterHeaterA = 20 * ((15 - envTemp) / 15)

    end

    -- lights (3 load levels by active main lights mask)
    local lightsLoadA = 0
    if vehicle.spec_lights ~= nil and vehicle.getLightsTypesMask ~= nil then
        local lightsSpec = vehicle.spec_lights
        local lightsMask = tonumber(vehicle:getLightsTypesMask()) or 0
        local maxLightStateMask = tonumber(lightsSpec.maxLightStateMask) or 0
        local activeMainLightsMask = lightsMask

        if maxLightStateMask > 0 and bitAND ~= nil then
            activeMainLightsMask = bitAND(lightsMask, maxLightStateMask)
        end

        if activeMainLightsMask > 0 then
            local lightStateLevel = 1
            if activeMainLightsMask == 1 then
                    lightStateLevel = 1
            elseif activeMainLightsMask == 3 then
                    lightStateLevel = 2
            elseif activeMainLightsMask == 7 then
                    lightStateLevel = 3
            elseif activeMainLightsMask == 23 then
                lightStateLevel = 4
            end
            lightsLoadA = (20 / 3) * lightStateLevel
        end
    end

    -- starterCranking
    local crankingA = 0
    if spec.isCranking ~= nil and spec.isCranking then
        crankingA = ADS_Config.ELECTRICAL.BATTERY_CRANK_CURRENT_A * (0.8 + math.random() * 0.4)
    end

    -- pulse
    local isPeakPulse = math.random() > 0.95
    local nominalPulse = isPeakPulse and (20 + spec.extraCurrentPeak) or (2 + spec.extraCurrentPeak)
    local pulseA = isMotorStarted and (nominalPulse * math.random()) or 0

    -- total
    local iLoads = baseLoadA + lightsLoadA + cabFanA + winterHeaterA + crankingA + pulseA

    if ADS_Config.DEBUG then
        local dbg = spec.debugData.battery
        dbg.iLoads = iLoads
        dbg.baseLoadA = baseLoadA
        dbg.lightsLoadA = lightsLoadA
        dbg.cabFanA = cabFanA
        dbg.winterHeaterA = winterHeaterA
        dbg.peakPulseA = pulseA
        dbg.crankingLoadA = crankingA
    end

    spec.iLoads = iLoads
    return iLoads
end

local function smoothstep(x)
    x = math.clamp(x, 0, 1)
    return x * x * (3 - 2 * x)
end

local function getBatteryOpenCircuitVoltage(soc)
    local C = ADS_Config.ELECTRICAL or {}
    local vEmpty = C.OCV_EMPTY_V
    local vFull = C.OCV_FULL_V

    soc = math.clamp(soc or 0, 0, 1)

    local shapedSoc = 0.65 * smoothstep(soc) + 0.35 * soc
    return vEmpty + (vFull - vEmpty) * shapedSoc
end

local function getBatteryTerminalVoltage(ocvV, iAltAvail, iLoads, isCranking, rIntOhm)
    local C = ADS_Config.ELECTRICAL or {}

    local chargeRisePer20A = C.BATTERY_CHARGE_RISE_PER_20A_V or 0.18
    local chargeRiseMaxV = C.BATTERY_CHARGE_RISE_MAX_V or 1.6
    local chargeTargetMaxV = C.BATTERY_CHARGE_TARGET_MAX_V or 14.4
    local chargeIrScale = C.BATTERY_CHARGE_IR_SCALE or 0.0

    local termMinV = C.BATTERY_TERMINAL_MIN_V or 8.5
    local termMaxV = C.BATTERY_TERMINAL_MAX_V or 14.8

    local iAlt = math.max(iAltAvail or 0, 0)
    local iLoad = math.max(iLoads or 0, 0)
    local iDischarge = math.max(iLoad - iAlt, 0)
    local iCharge = math.max(iAlt - iLoad, 0)

    local loadDropV = iDischarge * math.max(rIntOhm or 0, 0)

    local vTerm = (ocvV or 0) - loadDropV

    local linearChargeRiseV = (iCharge / 20) * chargeRisePer20A
    local irChargeRiseV = iCharge * math.max(rIntOhm or 0, 0) * math.max(chargeIrScale, 0)
    local chargeRiseV = math.min(linearChargeRiseV + irChargeRiseV, chargeRiseMaxV)
    if iCharge > 0 then
        vTerm = math.min(vTerm + chargeRiseV, math.min(chargeTargetMaxV, termMaxV))
    end

    vTerm = math.clamp(vTerm, termMinV, termMaxV)
    return vTerm, loadDropV, chargeRiseV, iDischarge, iCharge
end

local function getSystemVoltage(isMotorStarted, batteryTerminalV, iAltAvail, iLoads, alternatorHealth)
    local C = ADS_Config.ELECTRICAL

    batteryTerminalV = batteryTerminalV or 12.0
    iAltAvail = math.max(iAltAvail or 0, 0)
    iLoads = math.max(iLoads or 0, 0)
    alternatorHealth = math.clamp(alternatorHealth or 1.0, 0.0, 1.0)

    if not isMotorStarted then
        return batteryTerminalV, batteryTerminalV, 0, 0, 0, 1
    end

    local regMinV = C.ALTERNATOR_MIN_REGULATED_VOLTAGE or 13.6
    local regMaxV = C.ALTERNATOR_REGULATED_VOLTAGE or 14.1
    local altThreshold = math.clamp(C.ALT_HEALTH_REGULATION_THRESHOLD or 0.15, 0.01, 1.0)
    local regulationHealth = math.clamp((alternatorHealth - altThreshold) / math.max(1 - altThreshold, 0.0001), 0, 1)
    local regulatedV = regMinV + (regMaxV - regMinV) * regulationHealth

    local deficitA = math.max(iLoads - iAltAvail, 0)
    local surplusA = math.max(iAltAvail - iLoads, 0)
    local deficitSagPerAmp = C.ALT_DEFICIT_SAG_PER_AMP or 0.045
    local lowHealthDeficitMult = C.ALT_LOW_HEALTH_DEFICIT_MULT or 1.8
    local supportGain = math.clamp(C.ALT_BATTERY_SUPPORT_GAIN or 0.45, 0, 1)
    local maxSystemV = C.MAX_SYSTEM_VOLTAGE or 14.4
    local surplusHeadroomV = math.max(C.ALT_SURPLUS_CHARGE_HEADROOM_V or 0.15, 0)
    local healthDeficitMult = 1 + (1 - alternatorHealth) * math.max(lowHealthDeficitMult - 1, 0)
    local sagV = deficitA * deficitSagPerAmp * healthDeficitMult
    local chargeHeadroomV = 0

    local rawSystemV
    if iAltAvail <= 0.01 or regulationHealth <= 0 then
        rawSystemV = batteryTerminalV
    elseif iAltAvail >= iLoads then
        local chargeHeadroomT = math.clamp(surplusA / 60, 0, 1)
        chargeHeadroomV = math.min(surplusHeadroomV * chargeHeadroomT, math.max(maxSystemV - regulatedV, 0))
        rawSystemV = regulatedV + chargeHeadroomV
    else
        local batterySupportV = batteryTerminalV + (regulatedV - batteryTerminalV) * supportGain * alternatorHealth
        rawSystemV = math.max(regulatedV - sagV, batterySupportV)
    end

    rawSystemV = math.clamp(rawSystemV, C.MIN_SYSTEM_VOLTAGE or 9.0, maxSystemV)

    return rawSystemV, regulatedV, deficitA, sagV, regulationHealth, healthDeficitMult, chargeHeadroomV
end

getBatteryChargeAcceptance = function(tempC, soc, health)
    local C = ADS_Config.ELECTRICAL or {}

    local tMin = C.CHARGE_ACCEPT_TEMP_MIN_C or -15
    local tMax = C.CHARGE_ACCEPT_TEMP_MAX_C or 25
    local taperStart = C.CHARGE_TAPER_SOC_START or 0.80
    local taperEnd = C.CHARGE_TAPER_SOC_END or 0.98
    local minHealthK = math.clamp(C.BATTERY_HEALTH_ACCEPTANCE_MIN or 0.35, 0.02, 1.0)

    tempC = tempC or 20
    soc = math.clamp(soc or 1, 0, 1)
    health = math.clamp(health or 1, 0.0001, 1.0)

    local tempK
    if tempC <= tMin then
        tempK = 0.15
    elseif tempC >= tMax then
        tempK = 1.0
    else
        local t = (tempC - tMin) / math.max(tMax - tMin, 0.001)
        tempK = 0.15 + 0.85 * smoothstep(t)
    end

    local socK
    if soc <= taperStart then
        socK = 1.0
    elseif soc >= taperEnd then
        socK = 0.05
    else
        local t = (soc - taperStart) / math.max(taperEnd - taperStart, 0.001)
        socK = 1.0 - 0.95 * smoothstep(t)
    end

    local healthK = minHealthK + (1 - minHealthK) * smoothstep(health)

    return math.clamp(tempK * socK * healthK, 0.02, 1.0), tempK, socK, healthK
end

function ADS_Electrical.updateBatteryTemperatureC(vehicle, dtS, ambientC, engineC, iBatteryA, rintF)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then
        return
    end

    local cfg = ADS_Config.ELECTRICAL or {}

    dtS = sanitizeNumber(dtS, 0, 0)
    ambientC = sanitizeNumber(ambientC, cfg.AMBIENT_DEFAULT_C or 15, -80, 80)
    engineC = sanitizeNumber(engineC, ambientC, -80, 160)

    -- thermal inertia (time constant, seconds)
    local tauS = math.max(cfg.BATTERY_THERMAL_TAU_S or 120, 1)

    -- coupling coefficient to engine temperature contribution
    local kEngine = cfg.ENGINE_BAY_COUPLING or 0.30
    kEngine = math.clamp(kEngine, 0, 1)

    -- coupling contribution in degrees C from engine temperature
    local couplingC = kEngine * engineC

    -- effective target temp for battery (ambient + engine contribution)
    local targetC = ambientC + couplingC

    local tempC = spec.batteryTempC or ambientC

    local rRef = math.max(cfg.RINT_REF_OHM or 0.005, 0.0001)
    rintF = sanitizeNumber(rintF, 1.0, 0.1, 10.0)
    local rInt = rRef * rintF

    local iA = sanitizeNumber(iBatteryA, 0, 0, 10000)
    local pJouleW = iA * iA * rInt

    local cTh = math.max(cfg.BATTERY_THERMAL_CAPACITY_J_PER_K or 18000, 100)
    -- Move current self-heating into targetC (steady-state rise: dT = P / (C/tau) = P * tau / C)
    local targetJouleRiseC = (pJouleW * tauS) / cTh
    targetC = targetC + targetJouleRiseC

    -- 1st-order lag: T = T + (T_target - T) * alpha
    local alpha = 1 - math.exp(-dtS / tauS)
    tempC = sanitizeNumber(tempC + (targetC - tempC) * alpha, ambientC, -80, 120)
    local dTJoule = targetJouleRiseC * alpha

    -- safety clamp
    spec.batteryTempC = math.clamp(tempC, ambientC, 85)

    if ADS_Config.DEBUG and spec.debugData ~= nil and spec.debugData.battery ~= nil then
        local dbg = spec.debugData.battery
        dbg.dtS = dtS
        dbg.ambientC = ambientC
        dbg.engineC = engineC
        dbg.battTempTargetC = targetC
        dbg.battTempTargetJouleRiseC = targetJouleRiseC
        dbg.battTempAlpha = alpha
        dbg.battTempCoupling = couplingC
        dbg.battTempTauS = tauS
        dbg.batteryTempC = spec.batteryTempC
        dbg.iBatteryA = iA
        dbg.rintFactor = rintF
        dbg.rIntOhm = rInt
        dbg.pJouleW = pJouleW
        dbg.dTJoule = dTJoule
    end
end

local function buildBatteryContext(vehicle, dtS)
    local spec = vehicle.spec_AdvancedDamageSystem
    if spec == nil then
        return nil
    end

    local isMotorStarted = vehicle.getIsMotorStarted ~= nil and vehicle:getIsMotorStarted() or false

    local environmentTemp = 15
    if g_currentMission ~= nil
        and g_currentMission.environment ~= nil
        and g_currentMission.environment.weather ~= nil
        and g_currentMission.environment.weather.forecast ~= nil then
        local weather = g_currentMission.environment.weather.forecast:getCurrentWeather()
        environmentTemp = sanitizeNumber(weather ~= nil and weather.temperature or nil, 15, -80, 80)
    end

    spec.batteryTempC = sanitizeNumber(spec.batteryTempC, environmentTemp, -80, 85)
    local capF, rintF = getBatteryTempFactors(spec.batteryTempC)
    local iLoads = sanitizeNumber(calculateCurrentLoadAmps(vehicle, isMotorStarted, environmentTemp), 0, 0, 10000)

    local nominalCapacityAh = sanitizeNumber(spec.batteryCapacityAh, ADS_Config.ELECTRICAL.BATTERY_NOMINAL_CAPACITY or 1, 1, 10000)
    local batteryHealth = sanitizeNumber(spec.batteryHealth, 1.0, 0.0001, 1.0)

    local usableCapacityAh = math.max(
        nominalCapacityAh * capF * ADS_Config.ELECTRICAL.BATTERY_USABLE_CAPACITY_FACTOR,
        0.01
    )

    local effectiveCapacityAh = math.max(usableCapacityAh * batteryHealth, 0.01)

    spec.batterySoc = sanitizeNumber(spec.batterySoc, 1.0, 0, 1)
    local chargeAh = AdvancedDamageSystem.isFiniteNumber(tonumber(spec.batteryChargeAh)) and tonumber(spec.batteryChargeAh) or nil
    if chargeAh == nil then
        chargeAh = math.clamp(spec.batterySoc * effectiveCapacityAh, 0, effectiveCapacityAh)
    else
        chargeAh = sanitizeNumber(chargeAh, spec.batterySoc * effectiveCapacityAh, 0, effectiveCapacityAh)
    end

    local soc = sanitizeNumber(chargeAh / effectiveCapacityAh, spec.batterySoc, 0, 1)

    local cfg = ADS_Config.ELECTRICAL or {}
    local rRef = math.max(cfg.RINT_REF_OHM or 0.005, 0.0001)
    local maxHealthRintMult = math.max(cfg.BATTERY_HEALTH_RINT_MAX_MULT or 3.0, 1.0)
    local healthRintMult = 1 + (1 - batteryHealth) * (maxHealthRintMult - 1)
    local rIntOhm = rRef * (rintF or 1) * healthRintMult

    local iAltAvail = sanitizeNumber(calculateAlternatorOutput(vehicle, isMotorStarted, iLoads), 0, 0, 10000)

    local ocvV = getBatteryOpenCircuitVoltage(soc)

    return {
        vehicle = vehicle,
        spec = spec,
        dtS = dtS,

        isMotorStarted = isMotorStarted,
        environmentTemp = environmentTemp,

        batteryTempC = spec.batteryTempC or environmentTemp,
        batteryHealth = batteryHealth,

        capF = capF,
        rintF = rintF,

        nominalCapacityAh = nominalCapacityAh,
        usableCapacityAh = usableCapacityAh,
        capacityAh = effectiveCapacityAh,

        chargeAh = chargeAh,
        soc = soc,

        rIntOhm = rIntOhm,
        ocvV = ocvV,

        iLoads = iLoads,
        iAltAvail = iAltAvail
    }
end

local function orderExternalPowerContexts(ctxA, ctxB)
    if ctxA == nil or ctxB == nil then
        return ctxA, ctxB
    end

    local aStarted = ctxA.isMotorStarted == true
    local bStarted = ctxB.isMotorStarted == true
    if aStarted ~= bStarted then
        if aStarted then
            return ctxB, ctxA
        end

        return ctxA, ctxB
    end

    local aOcv = tonumber(ctxA.ocvV) or 0
    local bOcv = tonumber(ctxB.ocvV) or 0
    if math.abs(aOcv - bOcv) > 0.001 then
        if aOcv < bOcv then
            return ctxA, ctxB
        end

        return ctxB, ctxA
    end

    local aSoc = tonumber(ctxA.soc) or 0
    local bSoc = tonumber(ctxB.soc) or 0
    if math.abs(aSoc - bSoc) > 0.0001 then
        if aSoc < bSoc then
            return ctxA, ctxB
        end

        return ctxB, ctxA
    end

    local aCharge = tonumber(ctxA.chargeAh) or 0
    local bCharge = tonumber(ctxB.chargeAh) or 0
    if math.abs(aCharge - bCharge) > 0.0001 then
        if aCharge < bCharge then
            return ctxA, ctxB
        end

        return ctxB, ctxA
    end

    local aKey = tonumber(ctxA.vehicle ~= nil and (ctxA.vehicle.rootNode or ctxA.vehicle.id or ctxA.vehicle.uniqueId) or 0) or 0
    local bKey = tonumber(ctxB.vehicle ~= nil and (ctxB.vehicle.rootNode or ctxB.vehicle.id or ctxB.vehicle.uniqueId) or 0) or 0
    if aKey <= bKey then
        return ctxA, ctxB
    end

    return ctxB, ctxA
end

local function buildCompositeBatteryContext(consumerCtx, donorCtx)
    if consumerCtx == nil or donorCtx == nil then
        return nil
    end

    local cableResistanceOhm = 0.010

    local totalCapacityAh = math.max(
        (consumerCtx.capacityAh or 0) + (donorCtx.capacityAh or 0),
        0.01
    )

    local totalChargeAh = math.max(
        (consumerCtx.chargeAh or 0) + (donorCtx.chargeAh or 0),
        0
    )

    local compositeSoc = math.clamp(totalChargeAh / totalCapacityAh, 0, 1)

    local compositeTempC =
        ((consumerCtx.batteryTempC or 20) * (consumerCtx.capacityAh or 0) +
         (donorCtx.batteryTempC or 20) * (donorCtx.capacityAh or 0))
        / totalCapacityAh

    local compositeHealth =
        ((consumerCtx.batteryHealth or 1.0) * (consumerCtx.capacityAh or 0) +
         (donorCtx.batteryHealth or 1.0) * (donorCtx.capacityAh or 0))
        / totalCapacityAh

    local rConsumer = math.max(consumerCtx.rIntOhm or 0.01, 0.0001)
    local rDonorPath = math.max((donorCtx.rIntOhm or 0.01) + cableResistanceOhm, 0.0001)

    local gConsumer = 1 / rConsumer
    local gDonor = 1 / rDonorPath

    local compositeRintOhm = 1 / math.max(gConsumer + gDonor, 0.0001)
    local compositeOcvV = getBatteryOpenCircuitVoltage(compositeSoc)

    return {
        capacityAh = totalCapacityAh,
        chargeAh = totalChargeAh,
        soc = compositeSoc,

        tempC = compositeTempC,
        health = compositeHealth,

        ocvV = compositeOcvV,
        rIntOhm = compositeRintOhm,

        cableResistanceOhm = cableResistanceOhm,

        conductanceConsumer = gConsumer,
        conductanceDonor = gDonor
    }
end

local function calculateBatteryBalanceCurrent(consumerCtx, donorCtx, compositeCtx)
    if consumerCtx == nil or donorCtx == nil or compositeCtx == nil then
        return 0
    end

    local cableResistanceOhm = math.max(compositeCtx.cableResistanceOhm or 0.01, 0.0001)
    local maxCableCurrentA = ADS_Config.ELECTRICAL.EXTERNAL_POWER_MAX_CABLE_CURRENT_A or 400

    local consumerOcvV = tonumber(consumerCtx.ocvV) or 0
    local donorOcvV = tonumber(donorCtx.ocvV) or 0

    local consumerRint = math.max(tonumber(consumerCtx.rIntOhm) or 0.01, 0.0001)
    local donorRint = math.max(tonumber(donorCtx.rIntOhm) or 0.01, 0.0001)

    local totalPathResistanceOhm = consumerRint + donorRint + cableResistanceOhm

    local balanceCurrentA = (donorOcvV - consumerOcvV) / totalPathResistanceOhm

    balanceCurrentA = math.clamp(balanceCurrentA, -maxCableCurrentA, maxCableCurrentA)

    return balanceCurrentA
end

local function applyBatteryBalanceCurrent(consumerCtx, donorCtx, balanceCurrentA, dtS)
    if consumerCtx == nil or donorCtx == nil then
        return consumerCtx, donorCtx
    end

    local dAhBalance = (balanceCurrentA * dtS) / 3600

    consumerCtx.chargeAh = math.clamp(
        (consumerCtx.chargeAh or 0) + dAhBalance,
        0,
        math.max(consumerCtx.capacityAh or 0.01, 0.01)
    )

    donorCtx.chargeAh = math.clamp(
        (donorCtx.chargeAh or 0) - dAhBalance,
        0,
        math.max(donorCtx.capacityAh or 0.01, 0.01)
    )

    consumerCtx.soc = math.clamp(
        consumerCtx.chargeAh / math.max(consumerCtx.capacityAh or 0.01, 0.01),
        0,
        1
    )

    donorCtx.soc = math.clamp(
        donorCtx.chargeAh / math.max(donorCtx.capacityAh or 0.01, 0.01),
        0,
        1
    )

    consumerCtx.ocvV = getBatteryOpenCircuitVoltage(consumerCtx.soc)
    donorCtx.ocvV = getBatteryOpenCircuitVoltage(donorCtx.soc)

    consumerCtx.balanceCurrentA = balanceCurrentA
    donorCtx.balanceCurrentA = balanceCurrentA

    consumerCtx.balanceDeltaAh = dAhBalance
    donorCtx.balanceDeltaAh = -dAhBalance

    return consumerCtx, donorCtx
end

local function ensureBatteryDebugData(spec)
    if spec.debugData == nil then
        spec.debugData = {}
    end
    if spec.debugData.battery == nil then
        spec.debugData.battery = {}
    end
    return spec.debugData.battery
end

local function resetExternalPowerDebug(spec)
    local dbg = ensureBatteryDebugData(spec)
    dbg.isValidConnection = false
    dbg.distance = 0
    dbg.externalConnected = 0
    dbg.externalRole = "-"
    dbg.externalPartnerName = "-"
    dbg.externalCompositeSoc = 0
    dbg.externalCompositeCapacityAh = 0
    dbg.externalCompositeChargeAh = 0
    dbg.externalCompositeRintOhm = 0
    dbg.externalBalanceCurrentA = 0
    dbg.externalCommonNetA = 0
    dbg.externalCommonDeltaAh = 0
    dbg.externalLocalDeltaAh = 0
    dbg.externalAltBeforeA = 0
    dbg.externalAltAfterA = 0
end

local function normalizeExternalPowerConnection(connection)
    if connection == nil then
        return nil
    end

    if type(connection) == "table" and connection.object ~= nil then
        return connection.object
    end

    return connection
end

local function commitBatteryContext(vehicle, ctx, dt)
    if vehicle == nil or ctx == nil or ctx.spec == nil then
        return
    end

    local spec = ctx.spec
    local dbg = ensureBatteryDebugData(spec)

    local capacityAh = sanitizeNumber(ctx.capacityAh, 0.01, 0.01, 10000)
    spec.batteryChargeAh = sanitizeNumber(ctx.chargeAh, 0, 0, capacityAh)
    spec.batterySoc = sanitizeNumber(ctx.soc, 0, 0, 1)
    spec.batteryOpenCircuitVoltageV = sanitizeNumber(ctx.ocvV, getBatteryOpenCircuitVoltage(spec.batterySoc), 0, 30)
    spec.rawBatteryTerminalVoltageV = sanitizeNumber(ctx.rawBatteryTerminalVoltageV, spec.batteryOpenCircuitVoltageV, 0, 30)
    spec.rawSystemVoltageV = sanitizeNumber(ctx.rawSystemVoltageV, spec.rawBatteryTerminalVoltageV, 0, 30)

    local C = ADS_Config.ELECTRICAL or {}
    local safeDt = sanitizeNumber(dt, 0, 0)
    local batteryVAlpha = math.min(safeDt / ((C.BATTERY_VOLTAGE_TAU_MS or 300) + safeDt), 1)
    local systemVAlpha = math.min(safeDt / ((C.SYSTEM_VOLTAGE_TAU_MS or 250) + safeDt), 1)

    local currentBatteryTerminalV = sanitizeNumber(spec.batteryTerminalVoltageV, spec.rawBatteryTerminalVoltageV, 0, 30)
    spec.batteryTerminalVoltageV = sanitizeNumber(
        currentBatteryTerminalV + batteryVAlpha * (spec.rawBatteryTerminalVoltageV - currentBatteryTerminalV),
        spec.rawBatteryTerminalVoltageV,
        0,
        30
    )

    local currentSystemV = sanitizeNumber(spec.systemVoltageV, spec.rawSystemVoltageV, 0, 30)
    spec.systemVoltageV = sanitizeNumber(
        currentSystemV + systemVAlpha * (spec.rawSystemVoltageV - currentSystemV),
        spec.rawSystemVoltageV,
        0,
        30
    )

    dbg.soc = spec.batterySoc or 0
    dbg.chargeAh = spec.batteryChargeAh or 0
    dbg.capacityNominalAh = ctx.nominalCapacityAh or spec.batteryCapacityAh or 0
    dbg.capacityFactor = ctx.capF or 1
    dbg.capacityUsableAh = ctx.usableCapacityAh or ctx.capacityAh or 0
    dbg.capacityEffectiveAh = ctx.capacityAh or 0
    dbg.batteryHealth = ctx.batteryHealth or spec.batteryHealth or 0
    dbg.iNetRaw = ctx.iNetA or ((ctx.iAltAvail or 0) - (ctx.iLoads or 0))
    dbg.iNet = dbg.iNetRaw
    dbg.dAh = ctx.dAhTotal or (dbg.iNet * ((ctx.dtS or 0) / 3600))
    dbg.ocvV = spec.batteryOpenCircuitVoltageV or 0
    dbg.batteryTerminalV = spec.rawBatteryTerminalVoltageV or 0
    dbg.rawBatteryTerminalVoltageV = spec.rawBatteryTerminalVoltageV or 0
    dbg.batteryTerminalVoltageV = spec.batteryTerminalVoltageV or 0
    dbg.systemVoltageV = spec.rawSystemVoltageV or 0
    dbg.rawSystemVoltageV = spec.rawSystemVoltageV or 0
    dbg.systemVoltageVSmoothed = spec.systemVoltageV or 0

    if ctx.termLoadDropV ~= nil then dbg.termLoadDropV = ctx.termLoadDropV end
    if ctx.termChargeRiseV ~= nil then dbg.termChargeRiseV = ctx.termChargeRiseV end
    if ctx.termDischargeA ~= nil then dbg.termDischargeA = ctx.termDischargeA end
    if ctx.termChargeA ~= nil then dbg.termChargeA = ctx.termChargeA end
    if ctx.regulatedVoltageV ~= nil then dbg.regulatedVoltageV = ctx.regulatedVoltageV end
    if ctx.altDeficitA ~= nil then dbg.altDeficitA = ctx.altDeficitA end
    if ctx.altSagV ~= nil then dbg.altSagV = ctx.altSagV end
    if ctx.altRegulationHealth ~= nil then dbg.altRegulationHealth = ctx.altRegulationHealth end
    if ctx.altHealthDeficitMult ~= nil then dbg.altHealthDeficitMult = ctx.altHealthDeficitMult end
    if ctx.altChargeHeadroomV ~= nil then dbg.altChargeHeadroomV = ctx.altChargeHeadroomV end
end

local function solveExternalPowerConnection(consumerCtx, donorCtx, dtS)
    if consumerCtx == nil or donorCtx == nil then
        return consumerCtx, donorCtx, nil
    end

    local donorAltBeforeA = donorCtx.iAltAvail or 0
    local consumerAltBeforeA = consumerCtx.iAltAvail or 0
    local compositeCtx = buildCompositeBatteryContext(consumerCtx, donorCtx)
    if compositeCtx == nil then
        return consumerCtx, donorCtx, nil
    end

    local externalBatteryState = {
        soc = compositeCtx.soc,
        tempC = compositeCtx.tempC,
        health = compositeCtx.health
    }

    if donorCtx.isMotorStarted then
        donorCtx.iAltAvail = calculateAlternatorOutput(donorCtx.vehicle, donorCtx.isMotorStarted, donorCtx.iLoads, externalBatteryState) or 0
    end

    if consumerCtx.isMotorStarted then
        consumerCtx.iAltAvail = calculateAlternatorOutput(consumerCtx.vehicle, consumerCtx.isMotorStarted, consumerCtx.iLoads, externalBatteryState) or 0
    end

    local totalLoadsA = math.max((consumerCtx.iLoads or 0) + (donorCtx.iLoads or 0), 0)
    local totalAltA = math.max((consumerCtx.iAltAvail or 0) + (donorCtx.iAltAvail or 0), 0)
    local commonNetA = totalAltA - totalLoadsA
    local dAhCommon = commonNetA * dtS / 3600

    local totalConductance = math.max(
        (compositeCtx.conductanceConsumer or 0) + (compositeCtx.conductanceDonor or 0),
        0.0001
    )
    local consumerShare = (compositeCtx.conductanceConsumer or 0) / totalConductance
    local donorShare = (compositeCtx.conductanceDonor or 0) / totalConductance

    local dAhConsumerCommon = dAhCommon * consumerShare
    local dAhDonorCommon = dAhCommon * donorShare

    consumerCtx.chargeAh = math.clamp(
        (consumerCtx.chargeAh or 0) + dAhConsumerCommon,
        0,
        math.max(consumerCtx.capacityAh or 0.01, 0.01)
    )
    donorCtx.chargeAh = math.clamp(
        (donorCtx.chargeAh or 0) + dAhDonorCommon,
        0,
        math.max(donorCtx.capacityAh or 0.01, 0.01)
    )

    consumerCtx.soc = math.clamp(consumerCtx.chargeAh / math.max(consumerCtx.capacityAh or 0.01, 0.01), 0, 1)
    donorCtx.soc = math.clamp(donorCtx.chargeAh / math.max(donorCtx.capacityAh or 0.01, 0.01), 0, 1)
    consumerCtx.ocvV = getBatteryOpenCircuitVoltage(consumerCtx.soc)
    donorCtx.ocvV = getBatteryOpenCircuitVoltage(donorCtx.soc)

    compositeCtx = buildCompositeBatteryContext(consumerCtx, donorCtx)
    local balanceCurrentA = calculateBatteryBalanceCurrent(consumerCtx, donorCtx, compositeCtx)
    consumerCtx, donorCtx = applyBatteryBalanceCurrent(consumerCtx, donorCtx, balanceCurrentA, dtS)

    local dAhConsumerTotal = dAhConsumerCommon + (consumerCtx.balanceDeltaAh or 0)
    local dAhDonorTotal = dAhDonorCommon + (donorCtx.balanceDeltaAh or 0)

    local consumerBatteryA = math.abs(dAhConsumerTotal * 3600 / math.max(dtS, 0.0001))
    local donorBatteryA = math.abs(dAhDonorTotal * 3600 / math.max(dtS, 0.0001))

    ADS_Electrical.updateBatteryTemperatureC(
        consumerCtx.vehicle,
        dtS,
        consumerCtx.environmentTemp,
        sanitizeNumber(consumerCtx.spec.rawEngineTemperature or consumerCtx.spec.engineTemperature, consumerCtx.environmentTemp, -80, 160),
        consumerBatteryA,
        consumerCtx.rintF
    )
    ADS_Electrical.updateBatteryTemperatureC(
        donorCtx.vehicle,
        dtS,
        donorCtx.environmentTemp,
        sanitizeNumber(donorCtx.spec.rawEngineTemperature or donorCtx.spec.engineTemperature, donorCtx.environmentTemp, -80, 160),
        donorBatteryA,
        donorCtx.rintF
    )

    local finalCompositeCtx = buildCompositeBatteryContext(consumerCtx, donorCtx)
    local networkMotorStarted = consumerCtx.isMotorStarted or donorCtx.isMotorStarted
    local networkIsCranking =
        (consumerCtx.spec.isCranking ~= nil and consumerCtx.spec.isCranking == true)
        or (donorCtx.spec.isCranking ~= nil and donorCtx.spec.isCranking == true)

    local batteryTerminalV, loadDropV, chargeRiseV, iDischargeA, iChargeA =
        getBatteryTerminalVoltage(finalCompositeCtx.ocvV, totalAltA, totalLoadsA, networkIsCranking, finalCompositeCtx.rIntOhm)

    local networkAlternatorHealth = math.max(
        tonumber(consumerCtx.spec.alternatorHealth) or 0,
        tonumber(donorCtx.spec.alternatorHealth) or 0
    )

    local rawSystemV, regulatedV, deficitA, sagV, regulationHealth, healthDeficitMult, chargeHeadroomV =
        getSystemVoltage(networkMotorStarted, batteryTerminalV, totalAltA, totalLoadsA, networkAlternatorHealth)

    consumerCtx.rawBatteryTerminalVoltageV = batteryTerminalV
    consumerCtx.rawSystemVoltageV = rawSystemV
    donorCtx.rawBatteryTerminalVoltageV = batteryTerminalV
    donorCtx.rawSystemVoltageV = rawSystemV

    consumerCtx.termLoadDropV = loadDropV
    consumerCtx.termChargeRiseV = chargeRiseV
    consumerCtx.termDischargeA = iDischargeA
    consumerCtx.termChargeA = iChargeA
    consumerCtx.regulatedVoltageV = regulatedV
    consumerCtx.altDeficitA = deficitA
    consumerCtx.altSagV = sagV
    consumerCtx.altRegulationHealth = regulationHealth
    consumerCtx.altHealthDeficitMult = healthDeficitMult
    consumerCtx.altChargeHeadroomV = chargeHeadroomV

    donorCtx.termLoadDropV = loadDropV
    donorCtx.termChargeRiseV = chargeRiseV
    donorCtx.termDischargeA = iDischargeA
    donorCtx.termChargeA = iChargeA
    donorCtx.regulatedVoltageV = regulatedV
    donorCtx.altDeficitA = deficitA
    donorCtx.altSagV = sagV
    donorCtx.altRegulationHealth = regulationHealth
    donorCtx.altHealthDeficitMult = healthDeficitMult
    donorCtx.altChargeHeadroomV = chargeHeadroomV

    consumerCtx.iNetA = totalAltA - totalLoadsA
    donorCtx.iNetA = totalAltA - totalLoadsA
    consumerCtx.dAhTotal = dAhConsumerTotal
    donorCtx.dAhTotal = dAhDonorTotal

    consumerCtx.externalPowerDebug = {
        connected = true,
        role = "consumer",
        partnerName = donorCtx.vehicle.getFullName ~= nil and donorCtx.vehicle:getFullName() or tostring(donorCtx.vehicle),
        compositeSoc = finalCompositeCtx.soc,
        compositeCapacityAh = finalCompositeCtx.capacityAh,
        compositeChargeAh = finalCompositeCtx.chargeAh,
        compositeRintOhm = finalCompositeCtx.rIntOhm,
        balanceCurrentA = balanceCurrentA,
        commonNetA = commonNetA,
        commonDeltaAh = dAhCommon,
        localDeltaAh = dAhConsumerTotal,
        altBeforeA = consumerAltBeforeA,
        altAfterA = consumerCtx.iAltAvail or 0
    }

    donorCtx.externalPowerDebug = {
        connected = true,
        role = "donor",
        partnerName = consumerCtx.vehicle.getFullName ~= nil and consumerCtx.vehicle:getFullName() or tostring(consumerCtx.vehicle),
        compositeSoc = finalCompositeCtx.soc,
        compositeCapacityAh = finalCompositeCtx.capacityAh,
        compositeChargeAh = finalCompositeCtx.chargeAh,
        compositeRintOhm = finalCompositeCtx.rIntOhm,
        balanceCurrentA = balanceCurrentA,
        commonNetA = commonNetA,
        commonDeltaAh = dAhCommon,
        localDeltaAh = dAhDonorTotal,
        altBeforeA = donorAltBeforeA,
        altAfterA = donorCtx.iAltAvail or 0
    }

    return consumerCtx, donorCtx, finalCompositeCtx
end

function ADS_Electrical.rescaleBatteryChargeFromSoc(vehicle)
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        return
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    local tempC = tonumber(spec.batteryTempC) or 25
    local capF = 1.0

    if tempC < 25 then
        capF = math.clamp(1.0 - (25 - tempC) * 0.004, 0.55, 1.0)
    end

    local nominalCapacityAh = math.max(tonumber(spec.batteryCapacityAh) or 0, 1)
    local batteryHealth = math.max(tonumber(spec.batteryHealth) or 0, 0.0001)

    local usableCapacityAh = math.max(
        nominalCapacityAh * capF * ADS_Config.ELECTRICAL.BATTERY_USABLE_CAPACITY_FACTOR,
        0.01
    )

    local effectiveCapacityAh = math.max(usableCapacityAh * batteryHealth, 0.01)
    local soc = math.clamp(tonumber(spec.batterySoc) or 1.0, 0, 1)

    spec.batteryChargeAh = math.clamp(soc * effectiveCapacityAh, 0, effectiveCapacityAh)
end

function ADS_Electrical:syncDeadBatteryEffect()
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil then return end

    local breakdownId = 'DEAD_BATTERY'
    if spec.batterySoc < 0.001 and self.isServer then
        if (self:getIsMotorStarted() and spec.alternatorHealth < 0.01) or not self:getIsMotorStarted() then
            if not self:hasBreakdown(breakdownId) and spec.externalPowerConnection == nil then
                self:addBreakdown(breakdownId)
                if spec.isCranking ~= nil and spec.isCranking then
                    local engineHardStartEffect = spec.activeEffects ~= nil and spec.activeEffects.ENGINE_HARD_START_MODIFIER or nil
                    local engineFailedEffect = spec.activeEffects ~= nil and spec.activeEffects.ENGINE_FAILURE or nil
                    if engineHardStartEffect ~= nil and engineHardStartEffect.extraData ~= nil and engineHardStartEffect.extraData.status ~= nil then
                        engineHardStartEffect.extraData.status = "IDLE"
                    end
                    if engineFailedEffect ~= nil and engineFailedEffect.extraData ~= nil and engineFailedEffect.extraData.status ~= nil then
                        engineFailedEffect.extraData.status = "IDLE"
                    end
                end
            end
        end
    elseif self:hasBreakdown(breakdownId) then
        self:removeBreakdown(breakdownId)
    end
end

function ADS_Electrical:syncVoltageSagEffect(dt)
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil or not self.isServer then return end

    local triggerDelayMs = 2000
    if spec.syncVoltageSagEffectTimer == nil then
        spec.syncVoltageSagEffectTimer = triggerDelayMs
    end

    local motorState = self:getMotorState()
    local isCranking = spec.isCranking ~= nil and spec.isCranking
    local breakdownId = 'VOLTAGE_SAG'
    local systemVoltageV = sanitizeNumber(spec.rawSystemVoltageV or spec.systemVoltageV, 12.7, 0, 30)
    local isVoltageSagging = (motorState == 1 and systemVoltageV < 12.0 and not isCranking) or (motorState == 4 and systemVoltageV < 13.0)
    local clearToRemove = not isCranking

    if isVoltageSagging then
        if not self:hasBreakdown(breakdownId) then
            spec.syncVoltageSagEffectTimer = math.max((spec.syncVoltageSagEffectTimer or triggerDelayMs) - (dt or 0), 0)
            if spec.syncVoltageSagEffectTimer <= 0 then
                self:addBreakdown(breakdownId)
                spec.syncVoltageSagEffectTimer = triggerDelayMs
            end
        else
            spec.syncVoltageSagEffectTimer = triggerDelayMs
        end
    elseif clearToRemove and not isVoltageSagging then
        spec.syncVoltageSagEffectTimer = triggerDelayMs
        if self:hasBreakdown(breakdownId) then
            self:removeBreakdown(breakdownId)
        end
    end
end

function ADS_Electrical:updateBatteryChargingModel(dt)
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil then
        return
    end

    local dtS = math.max(sanitizeNumber(dt, 0, 0) / 1000, 0)
    if dtS <= 0 then
        return
    end

    ensureBatteryDebugData(spec)

    --- check for external connection
    local solveStamp = (g_currentMission ~= nil and g_currentMission.time) or g_time or 0
    if spec._externalPowerSolveStamp == solveStamp then
        return
    end

    resetExternalPowerDebug(spec)

    local connectionVehicle = normalizeExternalPowerConnection(spec.externalPowerConnection)
    local connectionSpec = connectionVehicle ~= nil and connectionVehicle.spec_AdvancedDamageSystem or nil

    if connectionVehicle ~= nil
        and connectionVehicle ~= self
        and connectionSpec ~= nil
        and (connectionVehicle.rootNode == nil or entityExists(connectionVehicle.rootNode)) then

        local selfSpeed = math.abs(tonumber(self.getLastSpeed ~= nil and self:getLastSpeed() or 0) or 0)
        local connectionSpeed = math.abs(tonumber(connectionVehicle.getLastSpeed ~= nil and connectionVehicle:getLastSpeed() or 0) or 0)
        if self.isServer and (selfSpeed > 1 or connectionSpeed > 1) then
            self:clearExternalPowerConnection(connectionVehicle)
            connectionVehicle = nil
            connectionSpec = nil
        end
    end

    if connectionVehicle ~= nil
        and connectionVehicle ~= self
        and connectionSpec ~= nil
        and (connectionVehicle.rootNode == nil or entityExists(connectionVehicle.rootNode)) then

        ensureBatteryDebugData(connectionSpec)
        resetExternalPowerDebug(connectionSpec)

        local selfCtx = buildBatteryContext(self, dtS)
        local connectionCtx = buildBatteryContext(connectionVehicle, dtS)

        if selfCtx ~= nil and connectionCtx ~= nil then
            local consumerCtx, donorCtx = orderExternalPowerContexts(selfCtx, connectionCtx)
            consumerCtx, donorCtx = solveExternalPowerConnection(consumerCtx, donorCtx, dtS)

            if consumerCtx ~= nil and donorCtx ~= nil then
                commitBatteryContext(consumerCtx.vehicle, consumerCtx, dt)
                commitBatteryContext(donorCtx.vehicle, donorCtx, dt)

                local selfIsConsumer = consumerCtx.vehicle == self
                local selfExt = selfIsConsumer and consumerCtx.externalPowerDebug or donorCtx.externalPowerDebug
                local connectionExt = selfIsConsumer and donorCtx.externalPowerDebug or consumerCtx.externalPowerDebug

                local selfDbg = ensureBatteryDebugData(spec)
                local connectionDbg = ensureBatteryDebugData(connectionSpec)

                if selfExt ~= nil then
                    selfDbg.externalConnected = 1
                    selfDbg.externalRole = selfExt.role or "-"
                    selfDbg.externalPartnerName = selfExt.partnerName or "-"
                    selfDbg.externalCompositeSoc = selfExt.compositeSoc or 0
                    selfDbg.externalCompositeCapacityAh = selfExt.compositeCapacityAh or 0
                    selfDbg.externalCompositeChargeAh = selfExt.compositeChargeAh or 0
                    selfDbg.externalCompositeRintOhm = selfExt.compositeRintOhm or 0
                    selfDbg.externalBalanceCurrentA = selfExt.balanceCurrentA or 0
                    selfDbg.externalCommonNetA = selfExt.commonNetA or 0
                    selfDbg.externalCommonDeltaAh = selfExt.commonDeltaAh or 0
                    selfDbg.externalLocalDeltaAh = selfExt.localDeltaAh or 0
                    selfDbg.externalAltBeforeA = selfExt.altBeforeA or 0
                    selfDbg.externalAltAfterA = selfExt.altAfterA or 0
                end

                if connectionExt ~= nil then
                    connectionDbg.externalConnected = 1
                    connectionDbg.externalRole = connectionExt.role or "-"
                    connectionDbg.externalPartnerName = connectionExt.partnerName or "-"
                    connectionDbg.externalCompositeSoc = connectionExt.compositeSoc or 0
                    connectionDbg.externalCompositeCapacityAh = connectionExt.compositeCapacityAh or 0
                    connectionDbg.externalCompositeChargeAh = connectionExt.compositeChargeAh or 0
                    connectionDbg.externalCompositeRintOhm = connectionExt.compositeRintOhm or 0
                    connectionDbg.externalBalanceCurrentA = connectionExt.balanceCurrentA or 0
                    connectionDbg.externalCommonNetA = connectionExt.commonNetA or 0
                    connectionDbg.externalCommonDeltaAh = connectionExt.commonDeltaAh or 0
                    connectionDbg.externalLocalDeltaAh = connectionExt.localDeltaAh or 0
                    connectionDbg.externalAltBeforeA = connectionExt.altBeforeA or 0
                    connectionDbg.externalAltAfterA = connectionExt.altAfterA or 0
                end

                spec._externalPowerSolveStamp = solveStamp
                connectionSpec._externalPowerSolveStamp = solveStamp
                return
            end
        end
    end

    local ctx = buildBatteryContext(self, dtS)
    if ctx == nil then
        return
    end

    local iBatteryA = math.abs(sanitizeNumber((ctx.iAltAvail or 0) - (ctx.iLoads or 0), 0, -10000, 10000))
    ADS_Electrical.updateBatteryTemperatureC(
        self,
        dtS,
        ctx.environmentTemp,
        sanitizeNumber(spec.rawEngineTemperature or spec.engineTemperature, ctx.environmentTemp, -80, 160),
        iBatteryA,
        ctx.rintF
    )

    local capacityAh = sanitizeNumber(ctx.capacityAh, 0.01, 0.01, 10000)
    local dAh = sanitizeNumber(((ctx.iAltAvail or 0) - (ctx.iLoads or 0)) * dtS / 3600, 0, -capacityAh, capacityAh)
    ctx.chargeAh = sanitizeNumber((ctx.chargeAh or 0) + dAh, 0, 0, capacityAh)
    ctx.soc = sanitizeNumber(ctx.chargeAh / capacityAh, 0, 0, 1)
    ctx.ocvV = sanitizeNumber(getBatteryOpenCircuitVoltage(ctx.soc), 12.7, 0, 30)

    local cfg = ADS_Config.ELECTRICAL or {}
    local health = sanitizeNumber(spec.batteryHealth, 1, 0.0001, 1.0)
    local rRef = math.max(cfg.RINT_REF_OHM or 0.005, 0.0001)
    local maxHealthRintMult = math.max(cfg.BATTERY_HEALTH_RINT_MAX_MULT or 3.0, 1.0)
    local healthRintMult = 1 + (1 - health) * (maxHealthRintMult - 1)
    local rIntOhm = sanitizeNumber(rRef * (ctx.rintF or 1) * healthRintMult, rRef, 0.0001, 10)

    local isCranking = spec.isCranking ~= nil and spec.isCranking

    local batteryTerminalV, loadDropV, chargeRiseV, iDischargeA, iChargeA =
        getBatteryTerminalVoltage(ctx.ocvV, ctx.iAltAvail, ctx.iLoads, isCranking, rIntOhm)
    batteryTerminalV = sanitizeNumber(batteryTerminalV, ctx.ocvV, 0, 30)

    local alternatorHealth = 1.0
    if spec.systems ~= nil and spec.systems.electrical ~= nil then
        alternatorHealth = sanitizeNumber(spec.alternatorHealth, 1.0, 0.0, 1.0)
    end

    local rawSystemV, regulatedV, deficitA, sagV, regulationHealth, healthDeficitMult, chargeHeadroomV =
        getSystemVoltage(ctx.isMotorStarted, batteryTerminalV, ctx.iAltAvail, ctx.iLoads, alternatorHealth)
    rawSystemV = sanitizeNumber(rawSystemV, batteryTerminalV, 0, 30)

    ctx.rawBatteryTerminalVoltageV = batteryTerminalV
    ctx.rawSystemVoltageV = rawSystemV
    ctx.termLoadDropV = loadDropV
    ctx.termChargeRiseV = chargeRiseV
    ctx.termDischargeA = iDischargeA
    ctx.termChargeA = iChargeA
    ctx.regulatedVoltageV = regulatedV
    ctx.altDeficitA = deficitA
    ctx.altSagV = sagV
    ctx.altRegulationHealth = regulationHealth
    ctx.altHealthDeficitMult = healthDeficitMult
    ctx.altChargeHeadroomV = chargeHeadroomV
    ctx.iNetA = (ctx.iAltAvail or 0) - (ctx.iLoads or 0)
    ctx.dAhTotal = dAh

    commitBatteryContext(self, ctx, dt)

    local dbg = ensureBatteryDebugData(spec)
    dbg.rIntHealthFactor = healthRintMult
    dbg.termIsCranking = isCranking and 1 or 0
end

function ADS_Electrical.isValidPowerPair(vehicleA, vehicleB)
    if vehicleA == nil or vehicleB == nil or vehicleA == vehicleB then
        return false, ''
    end

    if vehicleA.getRootVehicle ~= nil then
        vehicleA = vehicleA:getRootVehicle()
    end

    if vehicleB.getRootVehicle ~= nil then
        vehicleB = vehicleB:getRootVehicle()
    end

    if vehicleA == nil or vehicleB == nil or vehicleA == vehicleB then
        return false, 'SAME'
    end

    if vehicleA.spec_AdvancedDamageSystem == nil or vehicleB.spec_AdvancedDamageSystem == nil then
        return false, 'NO_ADS'
    end

    local nodeA = vehicleA.rootNode
    if nodeA == nil and vehicleA.components ~= nil and vehicleA.components[1] ~= nil then
        nodeA = vehicleA.components[1].node
    end

    local nodeB = vehicleB.rootNode
    if nodeB == nil and vehicleB.components ~= nil and vehicleB.components[1] ~= nil then
        nodeB = vehicleB.components[1].node
    end

    if nodeA == nil or nodeB == nil then
        return false, ''
    end

    local ax, ay, az = getWorldTranslation(nodeA)
    local bx, by, bz = getWorldTranslation(nodeB)
    local dx = bx - ax
    local dy = by - ay
    local dz = bz - az
    
    local fieldCare = ADS_Config ~= nil and ADS_Config.FIELD_CARE or nil
    local maxConnectionDistance = (fieldCare ~= nil and fieldCare.JUMPER_CABLES_MAX_CONNECTION_DISTANCE) or 12.0

    if MathUtil.vector3Length(dx, dy, dz) > maxConnectionDistance then
        return false, 'TOO_FAR'
    end
    
    return true
end

function ADS_Electrical:establishExternalPowerConnection(externalConnection)
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil or not self.isServer then
        return
    end

    local otherVehicle = externalConnection
    if otherVehicle ~= nil and otherVehicle.getRootVehicle ~= nil then
        otherVehicle = otherVehicle:getRootVehicle()
    end

    local otherSpec = otherVehicle ~= nil and otherVehicle.spec_AdvancedDamageSystem or nil
    local isValid = ADS_Electrical.isValidPowerPair(self, otherVehicle)

    if isValid then
        spec.externalPowerConnection = otherVehicle
        if otherSpec ~= nil then
            otherSpec.externalPowerConnection = self
        end
        return true
    else
        spec.externalPowerConnection = nil
        if otherSpec ~= nil and otherSpec.externalPowerConnection == self then
            otherSpec.externalPowerConnection = nil
        end
        return false
    end
end

function ADS_Electrical:clearExternalPowerConnection(otherVehicle)
    local spec = self.spec_AdvancedDamageSystem
    if spec == nil or not self.isServer then
        return false
    end

    local normalizedOther = otherVehicle
    if normalizedOther ~= nil and normalizedOther.getRootVehicle ~= nil then
        normalizedOther = normalizedOther:getRootVehicle()
    end

    local currentConnection = spec.externalPowerConnection
    if type(currentConnection) == "table" and currentConnection.object ~= nil then
        currentConnection = currentConnection.object
    end

    if normalizedOther == nil then
        normalizedOther = currentConnection
    end

    spec.externalPowerConnection = nil

    local otherSpec = normalizedOther ~= nil and normalizedOther.spec_AdvancedDamageSystem or nil
    if otherSpec ~= nil then
        local reverseConnection = otherSpec.externalPowerConnection
        if type(reverseConnection) == "table" and reverseConnection.object ~= nil then
            reverseConnection = reverseConnection.object
        end

        if reverseConnection == self then
            otherSpec.externalPowerConnection = nil
        end
    end

    return true
end
