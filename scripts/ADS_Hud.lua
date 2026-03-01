ADS_Hud = {}
ADS_Hud.modDirectory = g_currentModDirectory
ADS_Hud.debugViewMode = ADS_Hud.debugViewMode or "default"
local ADS_Hud_mt = Class(ADS_Hud, HUDDisplay)

function ADS_Hud:new()
	local self = ADS_Hud:superClass().new(ADS_Hud_mt)
	self.vehicle = nil

    g_overlayManager:addTextureConfigFile(ADS_Hud.modDirectory .. "hud/ads_dashboardHud.xml", "ads_DashboardHud")
    g_overlayManager:createOverlay("ads_DashboardHud.reliability", 0, 0, 0, 0)
    g_overlayManager:createOverlay("ads_DashboardHud.maintainability", 0, 0, 0, 0)

    self.indicators = {
        engine = {
            name = 'engine',
            icon = g_overlayManager:createOverlay("ads_DashboardHud.engine", 0, 0, 0, 0),
            year = 2000
        },
        transmission = {
            name = 'transmission',
            icon = g_overlayManager:createOverlay("ads_DashboardHud.transmission", 0, 0, 0, 0),
            year = 2000,
        },
        brakes = {
            name = 'brakes',
            icon = g_overlayManager:createOverlay("ads_DashboardHud.brakes", 0, 0, 0, 0),
            year = 1980
        },
        battery = {
            name = 'battery',
            icon = g_overlayManager:createOverlay("ads_DashboardHud.battery", 0, 0, 0, 0),
            year = 1950
        },
        coolant = {
            name = 'coolant',
            icon = g_overlayManager:createOverlay("ads_DashboardHud.coolant", 0, 0, 0, 0),
            year = 1950
        },
        warning = {
            name = 'warning',
            icon = g_overlayManager:createOverlay("ads_DashboardHud.warning", 0, 0, 0, 0),
            year = 1990
        },
        service = {
            name = 'service',
            icon = g_overlayManager:createOverlay("ads_DashboardHud.service", 0, 0, 0, 0),
            year = 2005
        },
        oil = {
            name = 'oil',
            icon = g_overlayManager:createOverlay("ads_DashboardHud.oil", 0, 0, 0, 0),
            year = 1950
        }
    }
    self.engineTempText = {}
    self.motorLoadText = {}
    self.tsTempText = {
        year = 2000
    }

    self.activeVehicleDebugPanel = {
        x = 0.25,
        y = 0.05,
        width = 0.5,
        padding = 0.01,
        lineHeight = 0.012,
        background = self.modDirectory .. "hud/ads_debugHud.dds",
        isVisible = false
    }

    self.managerDebugPanel = {
        x = 0.766,
        y = 0.70,
        width = 0.22,
        padding = 0.01,
        lineHeight = 0.012,
        background = self.modDirectory .. "hud/ads_debugHud.dds",
        isVisible = false
    }

    self.text = {
        headerSize = 0.014,
        normalSize = 0.010,
        color = {1, 1, 1, 1}
    }

    self.tempData = {}
    self.serviceData = {}
    self.conditionData = {}

    return self
end

function ADS_Hud:setVisible(isVisible)
    self.activeVehicleDebugPanel.isVisible = isVisible
end

function ADS_Hud:setVehicle(vehicle)
    self.vehicle = vehicle
end


-- =====================================================================================
--                              DRAW
-- =====================================================================================

function ADS_Hud:draw()
    if g_currentMission == nil or not g_currentMission.hud.isVisible then
        return
    end

    if ADS_Config.DEBUG then
        self:drawManagerHUD()
    end

    if ADS_Config.DEBUG and self.vehicle ~= nil and self.activeVehicleDebugPanel.isVisible then
        self:drawActiveVehicleHUD()
    end

    if self.vehicle ~= nil then
        self:drawDashboard()
    end
end

-- =====================================================================================
--                              DASHBOARD
-- =====================================================================================

function ADS_Hud:storeScaledValues()

    self.indicators.battery.offsetX, self.indicators.battery.offsetY = self:scalePixelValuesToScreenVector(23, -33)
    local batteryWidth, batteryHeight = self:scalePixelValuesToScreenVector(19, 19)
    self.indicators.battery.icon:setDimension(batteryWidth, batteryHeight)

    self.indicators.oil.offsetX, self.indicators.oil.offsetY = self:scalePixelValuesToScreenVector(22, -30)
    local oilWidth, oilHeight = self:scalePixelValuesToScreenVector(19, 19)
    self.indicators.oil.icon:setDimension(oilWidth, oilHeight)

    self.indicators.engine.offsetX, self.indicators.engine.offsetY = self:scalePixelValuesToScreenVector(-45, 10)
    local engineWidth, engineHeight = self:scalePixelValuesToScreenVector(16, 16)
    self.indicators.engine.icon:setDimension(engineWidth, engineHeight)

    self.indicators.transmission.offsetX, self.indicators.transmission.offsetY = self:scalePixelValuesToScreenVector(30, -13)
    local transmissionWidth, transmissionHeight = self:scalePixelValuesToScreenVector(19, 19)
    self.indicators.transmission.icon:setDimension(transmissionWidth, transmissionHeight)

    self.indicators.brakes.offsetX, self.indicators.brakes.offsetY = self:scalePixelValuesToScreenVector(-45, -32)
    local brakesWidth, brakesHeight = self:scalePixelValuesToScreenVector(19, 19)
    self.indicators.brakes.icon:setDimension(brakesWidth, brakesHeight)

    self.indicators.warning.offsetX, self.indicators.warning.offsetY = self:scalePixelValuesToScreenVector(25, 8)
    local warningWidth, warningHeight = self:scalePixelValuesToScreenVector(19, 19)
    self.indicators.warning.icon:setDimension(warningWidth, warningHeight)

    self.indicators.coolant.offsetX, self.indicators.coolant.offsetY = self:scalePixelValuesToScreenVector(-10, 37)
    local coolantWidth, coolantHeight = self:scalePixelValuesToScreenVector(19, 19)
    self.indicators.coolant.icon:setDimension(coolantWidth, coolantHeight)

    self.indicators.service.offsetX, self.indicators.service.offsetY = self:scalePixelValuesToScreenVector(-13, -38)
    local serviceWidth, serviceHeight = self:scalePixelValuesToScreenVector(27, 9)
    self.indicators.service.icon:setDimension(serviceWidth, serviceHeight)

    self.engineTempText.offsetX, self.engineTempText.offsetY = self:scalePixelValuesToScreenVector(0, 36)
	self.engineTempText.size = self:scalePixelToScreenHeight(9)

    self.motorLoadText.offsetX, self.motorLoadText.offsetY = self:scalePixelValuesToScreenVector(-39, 4)
	self.motorLoadText.size = self:scalePixelToScreenHeight(9)

    self.tsTempText.offsetX, self.tsTempText.offsetY = self:scalePixelValuesToScreenVector(38, 3)
	self.tsTempText.size = self:scalePixelToScreenHeight(8)
end

function ADS_Hud:drawDashboard()
    if self.vehicle == nil or self.vehicle.spec_AdvancedDamageSystem == nil then
        return
    end

    local vehicle = self.vehicle
    local spec = vehicle.spec_AdvancedDamageSystem
    local colors = ADS_Breakdowns.COLORS
    local activeIndicators = spec.activeIndicators

    g_currentMission.hud.speedMeter.speedTextSize = self:scalePixelToScreenHeight(43)
    local speedBgX, speedBgY = g_currentMission.hud.speedMeter.speedBg:getPosition()
    local posX = speedBgX + g_currentMission.hud.speedMeter.speedGaugeCenterOffsetX
    local posY = speedBgY + g_currentMission.hud.speedMeter.speedGaugeCenterOffsetY


    for hudIndicatorId, hudIndicatorData in pairs(self.indicators) do
        local icon = hudIndicatorData.icon
        local targetColor = colors.DEFAULT 
        

        if vehicle:getIsMotorStarted() then
            local motorStartedDelta = g_currentMission.environment.mission.time - vehicle:getMotorStartTime()
            if motorStartedDelta < 500 and spec.year >= 1990 then targetColor = colors.WARNING end
            if motorStartedDelta < 1000 and motorStartedDelta > 500 and spec.year >= 2005 then targetColor = colors.CRITICAL end

            local activeData = activeIndicators[hudIndicatorId]
            if activeData then
                local isActive = activeData.isActive
                local shouldBeOn = activeData.switchOn(vehicle)
                local shouldBeOff = activeData.switchOff(vehicle)

                if isActive and not shouldBeOff then
                    targetColor = activeData.color
                elseif shouldBeOn and not shouldBeOff then 
                    activeData.isActive = true
                    targetColor = activeData.color
                elseif shouldBeOff then
                    activeData.isActive = false
                end
            end

            if hudIndicatorId == self.indicators.coolant.name and targetColor == colors.DEFAULT and spec.engineTemperature < 50 then targetColor = colors.COOL
            elseif hudIndicatorId == self.indicators.coolant.name and targetColor == colors.DEFAULT and spec.engineTemperature > 99 and spec.engineTemperature < 110 then targetColor = colors.WARNING
            elseif hudIndicatorId == self.indicators.coolant.name and spec.engineTemperature > 110 then targetColor = colors.CRITICAL end

            if hudIndicatorId == self.indicators.transmission.name and targetColor == colors.DEFAULT and spec.transmissionTemperature > 99 and spec.transmissionTemperature < 110 then targetColor = colors.WARNING
            elseif hudIndicatorId == self.indicators.transmission.name and spec.transmissionTemperature > 110 then targetColor = colors.CRITICAL end

            if hudIndicatorId == self.indicators.service.name and spec.serviceLevel < 0.45 then targetColor = colors.WARNING end
            if hudIndicatorId == self.indicators.oil.name and spec.serviceLevel < 0.2 then targetColor = colors.WARNING end

        else
            local activeData = activeIndicators[hudIndicatorId]
            if activeData then
                activeData.isActive = false
            end
        end

        icon:setColor(unpack(targetColor))
        icon:setPosition(posX + hudIndicatorData.offsetX, posY + hudIndicatorData.offsetY)
        if hudIndicatorId == self.indicators.coolant.name and spec.isElectricVehicle or hudIndicatorId == self.indicators.oil.name then 
            icon:setVisible(false)
        else
            icon:setVisible(hudIndicatorData.year < spec.year)
        end
        icon:render()
        end

    local engineTemp, transTemp, motorLoad = spec.engineTemperature, spec.transmissionTemperature, vehicle:getMotorLoadPercentage()
    if not vehicle:getIsMotorStarted() then
        motorLoad = 0
    end

    local tempSign = "°C"

    if g_gameSettings:getValue(GameSettings.SETTING.USE_FAHRENHEIT) then
        engineTemp = engineTemp * 1.8 + 32
        transTemp = transTemp * 1.8 + 32
        tempSign = "°F"
    end

    local tempText = ""

    if transTemp > -90 and spec.year >= self.tsTempText.year then
        tempText = string.format("%.0f%s | %.0f%s" , engineTemp, tempSign, transTemp, tempSign)
    else
        tempText = string.format("%.1f%s", engineTemp, tempSign)
    end

    local motorText = string.format("%.0f%%", math.max(motorLoad * 100, 0))

    local motorLoadTextColor = {1, 1, 1, 1}
    if motorLoad > ADS_Config.CORE.ENGINE_FACTOR_DATA.MOTOR_OVERLOADED_THRESHOLD then
        motorLoadTextColor = colors.WARNING
    end

    if not spec.isElectricVehicle then
        setTextColor(1, 1, 1, 1)
        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_TOP)
        setTextBold(true)
        renderText(posX + self.engineTempText.offsetX, posY + self.engineTempText.offsetY, self.engineTempText.size, tempText)
        setTextColor(motorLoadTextColor[1], motorLoadTextColor[2], motorLoadTextColor[3], motorLoadTextColor[4])
        renderText(posX + self.motorLoadText.offsetX, posY + self.motorLoadText.offsetY, self.motorLoadText.size, motorText)
    end

    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BOTTOM)
    setTextBold(false)
end

-- =====================================================================================
--                              DEBAG HUD ACTIVE
-- =====================================================================================


function ADS_Hud:drawActiveVehicleHUD()
    local vehicle = self.vehicle
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        return
    end
    local spec = vehicle.spec_AdvancedDamageSystem
    local motor = vehicle:getMotor()
    if motor == nil then
        return
    end

    local panel = self.activeVehicleDebugPanel
    local textSettings = self.text
    local fontStep = 0.001
    local activeHeaderSize = textSettings.headerSize + fontStep
    local activeNormalSize = textSettings.normalSize + fontStep
    local activeLineHeight = panel.lineHeight + fontStep
    local sectionGap = activeLineHeight * 0.65

    local function addLine(target, text, color, sizeScale)
        table.insert(target, {
            text = text,
            color = color or {1, 1, 1, 1},
            sizeScale = sizeScale or 1.0
        })
    end

    local function getTempColor(temp)
        if temp > 105 then
            return {1, 0.6, 0.6, 1}
        elseif temp > 95 then
            return {1, 1, 0.6, 1}
        end

        return {0.6, 0.8, 1, 1}
    end

    local function packEntries(entries, maxPerLine, color, sizeScale)
        local lines = {}
        if #entries == 0 then
            addLine(lines, "None", color, sizeScale)
            return lines
        end

        local lineEntries = {}
        for i, entry in ipairs(entries) do
            table.insert(lineEntries, entry)
            if #lineEntries >= maxPerLine or i == #entries then
                addLine(lines, table.concat(lineEntries, ", "), color, sizeScale)
                lineEntries = {}
            end
        end

        return lines
    end

    local function listToString(list)
        if list == nil or #list == 0 then
            return "-"
        end

        return table.concat(list, ",")
    end

    local function localizeDebugValue(value)
        if value == nil then
            return "-"
        end

        if type(value) == "boolean" then
            local key = value and "ads_ws_option_yes" or "ads_ws_option_no"
            if g_i18n ~= nil and g_i18n.hasText ~= nil and g_i18n:hasText(key) then
                return g_i18n:getText(key)
            end
            return tostring(value)
        end

        local key = tostring(value)
        if key == "" then
            return "-"
        end

        if g_i18n ~= nil and g_i18n.hasText ~= nil then
            if g_i18n:hasText(key) then
                return g_i18n:getText(key)
            end
            return key
        end

        return key
    end

    local function getConditionFactorColor(value)
        local v = math.max(value or 0, 0)
        local green = {0.72, 1.0, 0.72, 1}
        local yellow = {1.0, 1.0, 0.62, 1}
        local red = {1.0, 0.62, 0.62, 1}

        if v <= 0.01 then
            local t = math.max(math.min(v / 0.01, 1), 0)
            return {
                green[1] + (yellow[1] - green[1]) * t,
                green[2] + (yellow[2] - green[2]) * t,
                green[3] + (yellow[3] - green[3]) * t,
                1
            }
        end

        local t = math.max(math.min((v - 0.01) / 0.01, 1), 0)
        return {
            yellow[1] + (red[1] - yellow[1]) * t,
            yellow[2] + (red[2] - yellow[2]) * t,
            yellow[3] + (red[3] - yellow[3]) * t,
            1
        }
    end

    if ADS_Hud.debugViewMode == "factorStats" then
        self:drawFactorStatsVehicleHUD(vehicle, spec, panel, activeHeaderSize, activeNormalSize, activeLineHeight, sectionGap)
        return
    end

    local breakdownEntries = {}
    if spec.activeBreakdowns and next(spec.activeBreakdowns) ~= nil then
        for id, breakdown in pairs(spec.activeBreakdowns) do
            local visible = breakdown.isVisible and "V" or "-"
            local selected = breakdown.isSelectedForRepair and "S" or "-"
            table.insert(breakdownEntries, string.format("%s[S%d|%.0fs|%s%s]", id, breakdown.stage, breakdown.progressTimer / 1000, visible, selected))
        end
    end
    table.sort(breakdownEntries)
    local breakdownLines = packEntries(breakdownEntries, 4, {1, 0.8, 0.8, 1}, 0.95)

    local effectEntries = {}
    if spec.activeEffects and next(spec.activeEffects) ~= nil then
        for id, effect in pairs(spec.activeEffects) do
            table.insert(effectEntries, string.format("%s:%.2f", id, effect.value))
        end
    end
    table.sort(effectEntries)
    local effectLines = packEntries(effectEntries, 4, {0.8, 0.8, 1, 1}, 0.95)

    local aiCruiseLines = {}
    if vehicle:getIsAIActive() and spec.debugData and spec.debugData.aiWorker then
        local dbg = spec.debugData.aiWorker
        local pidState = spec.aiWorkerPid or {}
        local cruiseSpeed = vehicle:getCruiseControlSpeed() or 0
        local ccState = vehicle:getCruiseControlState() or 0

        addLine(aiCruiseLines, string.format(
            "cc: %.1f (s:%d) | stress: %.3f (f: %.3f | l/e/t: %.3f/%.3f/%.3f) | e/i/d: %.3f/%.3f/%.3f | red: %.2f | base/tgt/app: %.1f/%.1f/%.1f | t: %.0fms",
            cruiseSpeed,
            ccState,
            dbg.stress or 0,
            dbg.filteredStress or 0,
            dbg.loadStress or 0,
            dbg.engineStress or 0,
            dbg.transStress or 0,
            dbg.error or 0,
            dbg.integral or 0,
            dbg.derivative or 0,
            dbg.reduction or 0,
            dbg.baseCruiseSpeed or 0,
            dbg.targetSpeed or 0,
            dbg.appliedSpeed or 0,
            pidState.applyTimer or 0
        ), {0.75, 1, 0.85, 1}, 0.95)
    end

    local bcw = ADS_Config.CORE.BASE_SYSTEMS_WEAR

    local function asPercent(value)
        return (value or 0) * 100
    end

    local function getSystemCondition(systemKey)
        local systemData = spec.systems and spec.systems[systemKey]
        if type(systemData) == "table" then
            return systemData.condition or 0
        end
        return systemData or 0
    end

    local function getSystemStress(systemKey)
        local systemData = spec.systems and spec.systems[systemKey]
        if type(systemData) == "table" then
            return systemData.stress or 0
        end
        return 0
    end

    local engineDbg = spec.debugData.engine or {}
    local transmissionDbg = spec.debugData.transmission or {}
    local hydraulicsDbg = spec.debugData.hydraulics or {}
    local coolingDbg = spec.debugData.cooling or {}
    local electricalDbg = spec.debugData.electrical or {}
    local chassisDbg = spec.debugData.chassis or {}
    local fuelDbg = spec.debugData.fuel or {}
    local serviceDbg = spec.debugData.service or {}
    local engineMaxFactor = math.max(
        engineDbg.motorLoadFactor or 0,
        engineDbg.expiredServiceFactor or 0,
        engineDbg.weatherFactor or 0,
        engineDbg.coldMotorFactor or 0,
        engineDbg.hotMotorFactor or 0
    ) * bcw
    local transmissionMaxFactor = math.max(
        transmissionDbg.expiredServiceFactor or 0,
        transmissionDbg.weatherFactor or 0,
        transmissionDbg.pullOverloadFactor or 0,
        transmissionDbg.heavyTrailerFactor or 0,
        transmissionDbg.luggingFactor or 0,
        transmissionDbg.wheelSlipFactor or 0,
        transmissionDbg.coldTransFactor or transmissionDbg.coldMotorFactor or 0,
        transmissionDbg.hotTransFactor or 0
    ) * bcw
    local hydraulicsMaxFactor = math.max(
        hydraulicsDbg.expiredServiceFactor or 0,
        hydraulicsDbg.weatherFactor or 0,
        hydraulicsDbg.heavyLiftFactor or 0,
        hydraulicsDbg.operatingFactor or 0,
        hydraulicsDbg.coldOilFactor or 0,
        hydraulicsDbg.ptoOperatingFactor or 0,
        hydraulicsDbg.sharpAngleFactor or 0
    ) * bcw
    local coolingMaxFactor = math.max(
        coolingDbg.expiredServiceFactor or 0,
        coolingDbg.weatherFactor or 0,
        coolingDbg.highCoolingFactor or 0,
        coolingDbg.overheatFactor or 0,
        coolingDbg.coldShockFactor or 0
    ) * bcw
    local electricalMaxFactor = math.max(
        electricalDbg.expiredServiceFactor or 0,
        electricalDbg.weatherFactor or 0,
        electricalDbg.lightsFactor or 0,
        electricalDbg.overheatFactor or 0
    ) * bcw
    local chassisMaxFactor = math.max(
        chassisDbg.expiredServiceFactor or 0,
        chassisDbg.weatherFactor or 0,
        chassisDbg.vibFactor or 0,
        chassisDbg.steerLoadFactor or 0,
        chassisDbg.brakeMassFactor or 0
    ) * bcw
    local fuelMaxFactor = math.max(
        fuelDbg.expiredServiceFactor or 0,
        fuelDbg.weatherFactor or 0,
        fuelDbg.lowFuelStarvationFactor or 0,
        fuelDbg.coldFuelFactor or 0,
        fuelDbg.idleDepositFactor or 0
    ) * bcw

    local overviewLines = {}
    local serviceWearRate = serviceDbg.totalWearRate or ADS_Config.CORE.BASE_SERVICE_WEAR or 0
    local weatherFactor = tonumber((ADS_Main ~= nil and ADS_Main.currentWeatherFactor) or 1.0) or 1.0
    addLine(overviewLines, string.format(
        "service: %.2f%% (service_wear: %.2f%%) | rel: %.2f%% | mnt: %.2f%% | wf: %.3f | roof: %s",
        asPercent(spec.serviceLevel or 0),
        asPercent(serviceWearRate),
        asPercent(spec.reliability or 0),
        asPercent(spec.maintainability or 0),
        weatherFactor,
        tostring(spec.isUnderRoof == true)
    ), {1, 1, 1, 1}, 0.95)

    local engineLines = {}
    addLine(engineLines, string.format(
        "con: %.2f%% (-%.2f%%) | stress: %.2f%% | sf: %.2f%% wf: %.2f%% mlf: %.2f%% cmf: %.2f%% hmf %.2f%% | breakdown: %.2f%% crit: %.2f%%",
        asPercent(getSystemCondition("engine")),
        asPercent((engineDbg.totalWearRate or 0) * bcw),
        asPercent(getSystemStress("engine")),
        asPercent((engineDbg.expiredServiceFactor or 0) * bcw),
        asPercent((engineDbg.weatherFactor or 0) * bcw),
        asPercent((engineDbg.motorLoadFactor or 0) * bcw),
        asPercent((engineDbg.coldMotorFactor or 0) * bcw),
        asPercent((engineDbg.hotMotorFactor or 0) * bcw),
        asPercent(engineDbg.breakdownProbability or 0),
        asPercent(engineDbg.critBreakdownProbability or 0)
    ), getConditionFactorColor(engineMaxFactor), 0.95)

    local transmissionLines = {}
    addLine(transmissionLines, string.format(
        "con: %.2f%% (-%.2f%%) | stress: %.2f%% | sf: %.2f%% wf: %.2f%% pof: %.2f%% (%.1fs) htf: %.2f%% lf: %.2f%% wsf: %.2f%% (wsi: %.2f%%) ctf: %.2f%% hotf: %.2f%% | breakdown: %.2f%% crit: %.2f%%",
        asPercent(getSystemCondition("transmission")),
        asPercent((transmissionDbg.totalWearRate or 0) * bcw),
        asPercent(getSystemStress("transmission")),
        asPercent((transmissionDbg.expiredServiceFactor or 0) * bcw),
        asPercent((transmissionDbg.weatherFactor or 0) * bcw),
        asPercent((transmissionDbg.pullOverloadFactor or 0) * bcw),
        (transmissionDbg.pullOverloadTimer or 0),
        asPercent((transmissionDbg.heavyTrailerFactor or 0) * bcw),
        asPercent((transmissionDbg.luggingFactor or 0) * bcw),
        asPercent((transmissionDbg.wheelSlipFactor or transmissionDbg.wheelSleepFactor or 0) * bcw),
        asPercent(transmissionDbg.wheelSlipIntensity or 0),
        asPercent(((transmissionDbg.coldTransFactor or transmissionDbg.coldMotorFactor) or 0) * bcw),
        asPercent((transmissionDbg.hotTransFactor or 0) * bcw),
        asPercent(transmissionDbg.breakdownProbability or 0),
        asPercent(transmissionDbg.critBreakdownProbability or 0)
    ), getConditionFactorColor(transmissionMaxFactor), 0.95)

    local function buildDefaultSystemLines(systemKey)
        local systemDbg = spec.debugData[systemKey] or {}
        local systemMaxFactor = math.max(systemDbg.expiredServiceFactor or 0, systemDbg.weatherFactor or 0) * bcw
        local lines = {}
        addLine(lines, string.format(
            "con: %.2f%% (-%.2f%%) | stress: %.2f%% | sf: %.2f%% wf: %.2f%% | breakdown: %.2f%% crit: %.2f%%",
            asPercent(getSystemCondition(systemKey)),
            asPercent((systemDbg.totalWearRate or 0) * bcw),
            asPercent(getSystemStress(systemKey)),
            asPercent((systemDbg.expiredServiceFactor or 0) * bcw),
            asPercent((systemDbg.weatherFactor or 0) * bcw),
            asPercent(systemDbg.breakdownProbability or 0),
            asPercent(systemDbg.critBreakdownProbability or 0)
        ), getConditionFactorColor(systemMaxFactor), 0.95)
        return lines
    end

    local hydraulicsLines = {}
    addLine(hydraulicsLines, string.format(
        "con: %.2f%% (-%.2f%%) | stress: %.2f%% | sf: %.2f%% wf: %.2f%% hlf: %.2f%% (mr: %.2f%%) of: %.2f%% cof: %.2f%% ptof: %.2f%% saf: %.2f%% (%.1fdeg) | breakdown: %.2f%% crit: %.2f%%",
        asPercent(getSystemCondition("hydraulics")),
        asPercent((hydraulicsDbg.totalWearRate or 0) * bcw),
        asPercent(getSystemStress("hydraulics")),
        asPercent((hydraulicsDbg.expiredServiceFactor or 0) * bcw),
        asPercent((hydraulicsDbg.weatherFactor or 0) * bcw),
        asPercent((hydraulicsDbg.heavyLiftFactor or 0) * bcw),
        asPercent(hydraulicsDbg.heavyLiftMassRatio or 0),
        asPercent((hydraulicsDbg.operatingFactor or 0) * bcw),
        asPercent((hydraulicsDbg.coldOilFactor or 0) * bcw),
        asPercent((hydraulicsDbg.ptoOperatingFactor or 0) * bcw),
        asPercent((hydraulicsDbg.sharpAngleFactor or 0) * bcw),
        (hydraulicsDbg.ptoSharpAngleDeg or 0),
        asPercent(hydraulicsDbg.breakdownProbability or 0),
        asPercent(hydraulicsDbg.critBreakdownProbability or 0)
    ), getConditionFactorColor(hydraulicsMaxFactor), 0.95)
    local coolingLines = {}
    addLine(coolingLines, string.format(
        "con: %.2f%% (-%.2f%%) | stress: %.2f%% | sf: %.2f%% wf: %.2f%% hcf: %.2f%% (ts: %.1f%%) ohf: %.2f%% csf: %.2f%% | breakdown: %.2f%% crit: %.2f%%",
        asPercent(getSystemCondition("cooling")),
        asPercent((coolingDbg.totalWearRate or 0) * bcw),
        asPercent(getSystemStress("cooling")),
        asPercent((coolingDbg.expiredServiceFactor or 0) * bcw),
        asPercent((coolingDbg.weatherFactor or 0) * bcw),
        asPercent((coolingDbg.highCoolingFactor or 0) * bcw),
        asPercent(spec.thermostatState or 0),
        asPercent((coolingDbg.overheatFactor or 0) * bcw),
        asPercent((coolingDbg.coldShockFactor or 0) * bcw),
        asPercent(coolingDbg.breakdownProbability or 0),
        asPercent(coolingDbg.critBreakdownProbability or 0)
    ), getConditionFactorColor(coolingMaxFactor), 0.95)
    local electricalLines = {}
    addLine(electricalLines, string.format(
        "con: %.2f%% (-%.2f%%) | stress: %.2f%% | sf: %.2f%% wf: %.2f%% ltf: %.2f%% ohf: %.2f%% | breakdown: %.2f%% crit: %.2f%%",
        asPercent(getSystemCondition("electrical")),
        asPercent((electricalDbg.totalWearRate or 0) * bcw),
        asPercent(getSystemStress("electrical")),
        asPercent((electricalDbg.expiredServiceFactor or 0) * bcw),
        asPercent((electricalDbg.weatherFactor or 0) * bcw),
        asPercent((electricalDbg.lightsFactor or 0) * bcw),
        asPercent((electricalDbg.overheatFactor or 0) * bcw),
        asPercent(electricalDbg.breakdownProbability or 0),
        asPercent(electricalDbg.critBreakdownProbability or 0)
    ), getConditionFactorColor(electricalMaxFactor), 0.95)
    local chassisLines = {}
    addLine(chassisLines, string.format(
        "con: %.2f%% (-%.2f%%) | stress: %.2f%% | sf: %.2f%% wf: %.2f%% vf: %.2f%% (raw: %.2f%% sig: %.2f%%) slf: %.2f%% bmf: %.2f%% (mr: %.2f p: %.2f%%) | breakdown: %.2f%% crit: %.2f%%",
        asPercent(getSystemCondition("chassis")),
        asPercent((chassisDbg.totalWearRate or 0) * bcw),
        asPercent(getSystemStress("chassis")),
        asPercent((chassisDbg.expiredServiceFactor or 0) * bcw),
        asPercent((chassisDbg.weatherFactor or 0) * bcw),
        asPercent((chassisDbg.vibFactor or 0) * bcw),
        asPercent(chassisDbg.vibRaw or 0),
        asPercent(chassisDbg.vibSignal or 0),
        asPercent((chassisDbg.steerLoadFactor or 0) * bcw),
        asPercent(chassisDbg.steerInputAbs or 0),
        asPercent(chassisDbg.steerDeltaRate or 0),
        asPercent(chassisDbg.steerLowSpeedFactor or 0),
        asPercent((chassisDbg.brakeMassFactor or 0) * bcw),
        (chassisDbg.brakeMassRatio or 0),
        asPercent(chassisDbg.brakePedal or 0),
        asPercent(chassisDbg.breakdownProbability or 0),
        asPercent(chassisDbg.critBreakdownProbability or 0)
    ), getConditionFactorColor(chassisMaxFactor), 0.95)
    local fuelLines = {}
    addLine(fuelLines, string.format(
        "con: %.2f%% (-%.2f%%) | stress: %.2f%% | sf: %.2f%% wf: %.2f%% lff: %.2f%% (lvl: %.2f%%) cff: %.2f%% (ft: %.1fC) idf: %.2f%% (t: %.0fs) | breakdown: %.2f%% crit: %.2f%%",
        asPercent(getSystemCondition("fuel")),
        asPercent((fuelDbg.totalWearRate or 0) * bcw),
        asPercent(getSystemStress("fuel")),
        asPercent((fuelDbg.expiredServiceFactor or 0) * bcw),
        asPercent((fuelDbg.weatherFactor or 0) * bcw),
        asPercent((fuelDbg.lowFuelStarvationFactor or 0) * bcw),
        asPercent(fuelDbg.fuelLevel or 0),
        asPercent((fuelDbg.coldFuelFactor or 0) * bcw),
        (fuelDbg.fuelTemperature or 0),
        asPercent((fuelDbg.idleDepositFactor or 0) * bcw),
        (fuelDbg.idleTimer or 0),
        asPercent(fuelDbg.breakdownProbability or 0),
        asPercent(fuelDbg.critBreakdownProbability or 0)
    ), getConditionFactorColor(fuelMaxFactor), 0.95)
    local workProcessLines = buildDefaultSystemLines("workProcess")
    local materialFlowLines = buildDefaultSystemLines("materialFlow")

    local engineTempLines = {}
    addLine(engineTempLines, string.format(
        "T: %.1fC | ts: %.3f | k/s/w: %.2f/%.3f/%.3f | h/c: %.3f/%.3f | r/s/c: %.3f/%.3f/%.3f",
        spec.engineTemperature,
        spec.thermostatState,
        spec.debugData.engineTemp.kp,
        spec.debugData.engineTemp.stiction,
        spec.debugData.engineTemp.waxSpeed,
        spec.debugData.engineTemp.totalHeat,
        spec.debugData.engineTemp.totalCooling,
        spec.debugData.engineTemp.radiatorCooling,
        spec.debugData.engineTemp.speedCooling,
        spec.debugData.engineTemp.convectionCooling
    ), getTempColor(spec.engineTemperature), 0.95)

    local vehicleHasCVT = motor.minForwardGearRatio ~= nil and spec.year >= self.tsTempText.year and not spec.isElectricVehicle
    local showTransmissionSection = vehicleHasCVT and spec.transmissionTemperature > -30
    local transmissionTempLines = {}
    if showTransmissionSection then
        addLine(transmissionTempLines, string.format(
            "T: %.1fC | ts: %.3f | k/s/w: %.2f/%.3f/%.3f | h: %.3f(l/s/a: %.2f/%.2f/%.2f) | c: %.3f(r/s/c: %.3f/%.3f/%.3f)",
            spec.transmissionTemperature,
            spec.transmissionThermostatState,
            spec.debugData.transmissionTemp.kp,
            spec.debugData.transmissionTemp.stiction,
            spec.debugData.transmissionTemp.waxSpeed,
            spec.debugData.transmissionTemp.totalHeat,
            spec.debugData.transmissionTemp.loadFactor,
            spec.debugData.transmissionTemp.slipFactor,
            spec.debugData.transmissionTemp.accFactor,
            spec.debugData.transmissionTemp.totalCooling,
            spec.debugData.transmissionTemp.radiatorCooling,
            spec.debugData.transmissionTemp.speedCooling,
            spec.debugData.transmissionTemp.convectionCooling
        ), getTempColor(spec.transmissionTemperature), 0.95)
    end

    local motorPower = motor:getMotorRotSpeed() * (motor:getMotorAvailableTorque() - motor:getMotorExternalTorque()) * 1000
    local peakPowerHp = (motor.peakMotorPower or 0) * 1.36
    local lastRpm = motor:getLastModulatedMotorRpm()
    local maxRpm = math.max(motor.maxRpm or 1, 1)
    local rpmLoad = lastRpm / maxRpm
    local targetGear = (motor.targetGear or 0) * (motor.currentDirection or 1)
    local drivetrainLines = {}
    addLine(drivetrainLines, string.format(
        "hp: %d/%d | ml/rpm: %.3f/%.3f | g: %d>%d(%d,%.2f) | fuel: %.2fl/h | d/dr: %.3f/%.3f" ,
        motorPower / 735.5,
        peakPowerHp,
        vehicle:getMotorLoadPercentage(),
        rpmLoad,
        motor.gear or 0,
        targetGear,
        motor.activeGearGroupIndex or 0,
        motor:getGearRatio() or 0,
        vehicle.spec_motorized.lastFuelUsage or 0,
        vehicle:getDamageAmount(),
        vehicle:getDirtAmount()

    ), {1, 1, 1, 1}, 0.95)

    local serviceDataLines = {}
    local states = AdvancedDamageSystem.STATUS
    local isUnderService = spec.currentState ~= states.READY
    if isUnderService then
        local pendingInspectionQueue = spec.pendingInspectionQueue or {}
        local pendingRepairQueue = spec.pendingRepairQueue or {}
        local pendingSelectedBreakdowns = spec.pendingSelectedBreakdowns or {}
        local progressPercent = 0
        if (spec.pendingProgressTotalTime or 0) > 0 then
            local progressRatio = math.min(math.max((spec.pendingProgressElapsedTime or 0) / spec.pendingProgressTotalTime, 0), 1)
            progressPercent = math.floor(progressRatio * 100)
        end

        addLine(serviceDataLines, string.format(
            "cur/pl/ws: %s/%s/%s | o1/o2/o3/price: %s/%s/%s/%s",
            localizeDebugValue(spec.currentState),
            localizeDebugValue(spec.plannedState),
            localizeDebugValue(spec.workshopType),
            localizeDebugValue(spec.serviceOptionOne),
            localizeDebugValue(spec.serviceOptionTwo),
            localizeDebugValue(spec.serviceOptionThree),
            tostring(spec.pendingServicePrice)
        ), {1, 0.95, 0.75, 1}, 0.95)
        addLine(serviceDataLines, string.format(
            "tm/el/tt(ms): %.0f/%.0f/%.0f | prg: %d%% | step: %d | q(sel/insp/rep): %d/%d/%d",
            spec.maintenanceTimer or 0,
            spec.pendingProgressElapsedTime or 0,
            spec.pendingProgressTotalTime or 0,
            progressPercent,
            spec.pendingProgressStepIndex or 0,
            #pendingSelectedBreakdowns,
            #pendingInspectionQueue,
            #pendingRepairQueue
        ), {1, 0.95, 0.75, 1}, 0.95)
        addLine(serviceDataLines, string.format(
            "svc s->t: %s->%s | cond(avg) s->t: %s->%s | cur s/c: %.4f/%.4f",
            tostring(spec.pendingMaintenanceServiceStart),
            tostring(spec.pendingMaintenanceServiceTarget),
            tostring(spec.pendingOverhaulConditionStart),
            tostring(spec.pendingOverhaulConditionTarget),
            spec.serviceLevel or 0,
            spec.conditionLevel or 0
        ), {1, 0.95, 0.75, 1}, 0.95)

        if spec.currentState == states.OVERHAUL then
            local overhaulSystemStart = spec.pendingOverhaulSystemStart or {}
            local overhaulSystemTarget = spec.pendingOverhaulSystemTarget or {}
            local systemEntries = {}

            for systemKey, systemStart in pairs(overhaulSystemStart) do
                local systemTarget = overhaulSystemTarget[systemKey]
                local systemData = spec.systems and spec.systems[systemKey]
                local currentSystemCondition = 0
                if type(systemData) == "table" then
                    currentSystemCondition = tonumber(systemData.condition) or 0
                else
                    currentSystemCondition = tonumber(systemData) or 0
                end

                if systemTarget ~= nil then
                    table.insert(
                        systemEntries,
                        string.format("%s: %.3f->%.3f (cur %.3f)", tostring(systemKey), tonumber(systemStart) or 0, tonumber(systemTarget) or 0, currentSystemCondition)
                    )
                end
            end

            table.sort(systemEntries)
            addLine(serviceDataLines, "ovh systems:", {1, 0.95, 0.75, 1}, 0.95)
            local systemLines = packEntries(systemEntries, 2, {1, 0.95, 0.75, 1}, 0.95)
            for _, line in ipairs(systemLines) do
                table.insert(serviceDataLines, line)
            end
        end

        addLine(serviceDataLines, "sel: " .. listToString(pendingSelectedBreakdowns), {1, 0.95, 0.75, 1}, 0.95)
        addLine(serviceDataLines, "insp: " .. listToString(pendingInspectionQueue), {1, 0.95, 0.75, 1}, 0.95)
        addLine(serviceDataLines, "rep: " .. listToString(pendingRepairQueue), {1, 0.95, 0.75, 1}, 0.95)
    end

    local sections = {
        {title = "System", lines = overviewLines},
        {title = "Engine", lines = engineLines},
        {title = "Transmission", lines = transmissionLines},
        {title = "Hydraulics", lines = hydraulicsLines},
        {title = "Cooling", lines = coolingLines},
        {title = "Electrical", lines = electricalLines},
        {title = "Chassis", lines = chassisLines},
        {title = "Fuel", lines = fuelLines},
        {title = "Work Process", lines = workProcessLines},
        {title = "Material Flow", lines = materialFlowLines},
        {title = "Engine Temp", lines = engineTempLines}
    }

    if showTransmissionSection then
        table.insert(sections, {title = "CVT Temp", lines = transmissionTempLines})
    end

    table.insert(sections, {title = "Drivetrain", lines = drivetrainLines})
    if isUnderService then
        table.insert(sections, {title = "Service Data", lines = serviceDataLines})
    end
    table.insert(sections, {title = "Active Breakdowns", lines = breakdownLines})
    table.insert(sections, {title = "Active Effects", lines = effectLines})

    if #aiCruiseLines > 0 then
        table.insert(sections, {title = "AI Cruise Control", lines = aiCruiseLines})
    end

    local totalSectionHeight = 0
    for _, section in ipairs(sections) do
        totalSectionHeight = totalSectionHeight + (math.max(#section.lines, 1) * activeLineHeight)
    end
    totalSectionHeight = totalSectionHeight + (math.max(#sections - 1, 0) * sectionGap)

    local dynamicHeight = (panel.padding * 2) + activeHeaderSize + totalSectionHeight + 0.02
    if panel.background ~= nil then
        local overlay = Overlay.new(panel.background, panel.x, panel.y, panel.width, dynamicHeight)
        overlay:setColor(1, 1, 1, 0.7)
        overlay:render()
    end

    local textStartX = panel.x + panel.padding
    local currentY = panel.y + dynamicHeight - panel.padding

    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_TOP)
    setTextBold(true)
    setTextColor(1, 1, 1, 1)
    renderText(textStartX, currentY, activeHeaderSize, vehicle:getFullName() .. " " .. spec.year)
    setTextBold(false)
    currentY = currentY - activeHeaderSize - activeLineHeight

    local function drawSection(section)
        local sectionLines = section.lines or {}
        if #sectionLines == 0 then
            setTextColor(1, 1, 1, 1)
            renderText(textStartX, currentY, activeNormalSize, section.title .. ":")
            currentY = currentY - activeLineHeight
            return
        end

        local firstLine = sectionLines[1]
        local firstColor = firstLine.color or {1, 1, 1, 1}
        local firstSize = activeNormalSize * (firstLine.sizeScale or 1.0)
        setTextColor(firstColor[1], firstColor[2], firstColor[3], firstColor[4] or 1)
        renderText(textStartX, currentY, firstSize, section.title .. ": " .. (firstLine.text or ""))
        currentY = currentY - activeLineHeight

        for index = 2, #sectionLines do
            local line = sectionLines[index]
            local lineText = line.text or ""
            local lineColor = line.color or {1, 1, 1, 1}
            local lineSize = activeNormalSize * (line.sizeScale or 1.0)
            setTextColor(lineColor[1], lineColor[2], lineColor[3], lineColor[4] or 1)
            renderText(textStartX + 0.01, currentY, lineSize, lineText)
            currentY = currentY - activeLineHeight
        end
    end

    for index, section in ipairs(sections) do
        drawSection(section)
        if index < #sections then
            currentY = currentY - sectionGap
        end
    end

    setTextColor(1, 1, 1, 1)
end

function ADS_Hud:drawFactorStatsVehicleHUD(vehicle, spec, panel, activeHeaderSize, activeNormalSize, activeLineHeight, sectionGap)
    local function addLine(target, text, color, sizeScale)
        table.insert(target, {
            text = text,
            color = color or {1, 1, 1, 1},
            sizeScale = sizeScale or 1.0
        })
    end

    local function packEntries(entries, maxPerLine, color, sizeScale)
        local lines = {}
        if #entries == 0 then
            addLine(lines, "-", color, sizeScale)
            return lines
        end

        local lineEntries = {}
        for i, entry in ipairs(entries) do
            table.insert(lineEntries, entry)
            if #lineEntries >= maxPerLine or i == #entries then
                addLine(lines, table.concat(lineEntries, " | "), color, sizeScale)
                lineEntries = {}
            end
        end

        return lines
    end

    local function toPct(value)
        return (tonumber(value) or 0) * 100
    end

    local function getSystemTitle(systemKey)
        local names = {
            engine = "Engine",
            transmission = "Transmission",
            hydraulics = "Hydraulics",
            cooling = "Cooling",
            electrical = "Electrical",
            chassis = "Chassis",
            fuel = "Fuel",
            workProcess = "Work Process",
            materialFlow = "Material Flow"
        }
        return names[systemKey] or tostring(systemKey)
    end

    local sections = {}
    local factorStatsRaw = spec.factorStats or {}
    local factorStats = {}
    for rawSystemKey, rawStats in pairs(factorStatsRaw) do
        if type(rawStats) == "table" then
            local normalizedKey = tostring(rawSystemKey)
            local loweredKey = string.lower(normalizedKey)
            if loweredKey == "workprocess" then
                normalizedKey = "workProcess"
            elseif loweredKey == "materialflow" then
                normalizedKey = "materialFlow"
            end

            if factorStats[normalizedKey] == nil then
                factorStats[normalizedKey] = {}
            end

            for statKey, statValue in pairs(rawStats) do
                local numericValue = tonumber(statValue)
                if numericValue ~= nil then
                    factorStats[normalizedKey][statKey] = (tonumber(factorStats[normalizedKey][statKey]) or 0) + numericValue
                end
            end
        end
    end

    local orderedSystems = {
        "engine", "transmission", "hydraulics", "cooling",
        "electrical", "chassis", "fuel", "workProcess", "materialFlow"
    }

    local usedSystems = {}
    for _, systemKey in ipairs(orderedSystems) do
        local stats = factorStats[systemKey]
        if type(stats) == "table" then
            usedSystems[systemKey] = true
            local lines = {}
            addLine(lines, string.format(
                "total: %.3f%% | stress: %.3f%%",
                toPct(stats.total),
                toPct(stats.stress)
            ), {1, 1, 1, 1}, 0.95)

            local factorEntries = {}
            for key, value in pairs(stats) do
                if key ~= "total" and key ~= "stress" then
                    local numericValue = tonumber(value)
                    if numericValue ~= nil and math.abs(numericValue) > 0 then
                        table.insert(factorEntries, { key = key, value = numericValue })
                    end
                end
            end

            table.sort(factorEntries, function(a, b)
                return math.abs(a.value) > math.abs(b.value)
            end)

            local formattedEntries = {}
            for _, entry in ipairs(factorEntries) do
                table.insert(formattedEntries, string.format("%s: %.3f%%", entry.key, toPct(entry.value)))
            end

            local packedLines = packEntries(formattedEntries, 4, {0.92, 0.96, 1.0, 1}, 0.9)
            for _, packedLine in ipairs(packedLines) do
                table.insert(lines, packedLine)
            end

            table.insert(sections, { title = getSystemTitle(systemKey), lines = lines })
        end
    end

    for systemKey, stats in pairs(factorStats) do
        if type(stats) == "table" and not usedSystems[systemKey] then
            local lines = {}
            addLine(lines, string.format(
                "total: %.3f%% | stress: %.3f%%",
                toPct(stats.total),
                toPct(stats.stress)
            ), {1, 1, 1, 1}, 0.95)
            table.insert(sections, { title = getSystemTitle(systemKey), lines = lines })
        end
    end

    local totalSectionHeight = 0
    for _, section in ipairs(sections) do
        totalSectionHeight = totalSectionHeight + (math.max(#section.lines, 1) * activeLineHeight)
    end
    totalSectionHeight = totalSectionHeight + (math.max(#sections - 1, 0) * sectionGap)

    local dynamicHeight = (panel.padding * 2) + activeHeaderSize + totalSectionHeight + 0.02
    if panel.background ~= nil then
        local overlay = Overlay.new(panel.background, panel.x, panel.y, panel.width, dynamicHeight)
        overlay:setColor(1, 1, 1, 0.7)
        overlay:render()
    end

    local textStartX = panel.x + panel.padding
    local currentY = panel.y + dynamicHeight - panel.padding

    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_TOP)
    setTextBold(true)
    setTextColor(1, 1, 1, 1)
    renderText(textStartX, currentY, activeHeaderSize, vehicle:getFullName() .. " " .. spec.year .. " [Factor Stats]")
    setTextBold(false)
    currentY = currentY - activeHeaderSize - activeLineHeight

    local function drawSection(section)
        local sectionLines = section.lines or {}
        if #sectionLines == 0 then
            setTextColor(1, 1, 1, 1)
            renderText(textStartX, currentY, activeNormalSize, section.title .. ":")
            currentY = currentY - activeLineHeight
            return
        end

        local firstLine = sectionLines[1]
        local firstColor = firstLine.color or {1, 1, 1, 1}
        local firstSize = activeNormalSize * (firstLine.sizeScale or 1.0)
        setTextColor(firstColor[1], firstColor[2], firstColor[3], firstColor[4] or 1)
        renderText(textStartX, currentY, firstSize, section.title .. ": " .. (firstLine.text or ""))
        currentY = currentY - activeLineHeight

        for index = 2, #sectionLines do
            local line = sectionLines[index]
            local lineText = line.text or ""
            local lineColor = line.color or {1, 1, 1, 1}
            local lineSize = activeNormalSize * (line.sizeScale or 1.0)
            setTextColor(lineColor[1], lineColor[2], lineColor[3], lineColor[4] or 1)
            renderText(textStartX + 0.01, currentY, lineSize, lineText)
            currentY = currentY - activeLineHeight
        end
    end

    for index, section in ipairs(sections) do
        drawSection(section)
        if index < #sections then
            currentY = currentY - sectionGap
        end
    end

    setTextColor(1, 1, 1, 1)
end

-- =====================================================================================
--                             DEBAG HUD INACTIVE
-- =====================================================================================

function ADS_Hud:drawManagerHUD()
    if ADS_Main == nil or ADS_Main.vehicles == nil or next(ADS_Main.vehicles) == nil then
        return
    end

    local panel = self.managerDebugPanel
    local textSettings = self.text

    local vehicleLines = {}
    for vehicleId, vehicle in pairs(ADS_Main.vehicles) do
        if vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil then
            local line = string.format("%s | s: %.2f%% | s: %.2f%%",
                                        vehicle:getFullName(),
                                        vehicle:getServiceLevel() * 100,
                                        vehicle:getConditionLevel() * 100)
            table.insert(vehicleLines, line)
        end
    end

    if #vehicleLines == 0 then
        return
    end

    table.sort(vehicleLines)

    local totalLines = #vehicleLines + 1
    local dynamicHeight = (panel.padding * 2) + textSettings.headerSize + (totalLines * panel.lineHeight)

    if panel.background ~= nil then
        local overlay = Overlay.new(panel.background, panel.x, panel.y, panel.width, dynamicHeight)
        overlay:setColor(1, 1, 1, 0.7)
        overlay:render()
    end

    setTextColor(unpack(textSettings.color))
    
    local textStartX = panel.x + panel.padding
    local currentY = panel.y + dynamicHeight - panel.padding - 0.005

    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(true)
    renderText(textStartX, currentY, textSettings.headerSize, "ADS Monitored Vehicles")
    setTextBold(false)

    for _, line in ipairs(vehicleLines) do
        currentY = currentY - panel.lineHeight
        renderText(textStartX, currentY, textSettings.normalSize, line)
    end

    setTextColor(1, 1, 1, 1)
end


-- =====================================================================================
--                             DAMAGE BAR CONTROL
-- =====================================================================================

local originalSpeedMeterDisplayDraw = SpeedMeterDisplay.draw
SpeedMeterDisplay.draw = function(self, ...)
    local vehicle = self.vehicle
    if vehicle == nil or not self.isVehicleDrawSafe or vehicle.rootVehicle == nil then
        return originalSpeedMeterDisplayDraw(self, ...)
    end

    local selectedTool = nil
    local useCustomValue = false
    local customDamageAmount = 0

    for _, implement in ipairs(vehicle.rootVehicle.childVehicles) do
        if implement:getIsSelected() and implement.getDamageShowOnHud ~= nil and implement:getDamageShowOnHud() then
            selectedTool = implement
            break
        end
    end

    if selectedTool ~= nil then
        useCustomValue = true
        if selectedTool.getServiceLevel ~= nil then
            local cs = vehicle.spec_AdvancedDamageSystem.lastInspectedConditionState
            if cs == AdvancedDamageSystem.STATES.UNKNOWN or cs == AdvancedDamageSystem.STATES.EXCELLENT then customDamageAmount = 0.0
            elseif cs == AdvancedDamageSystem.STATES.GOOD then customDamageAmount = 0.25
            elseif cs == AdvancedDamageSystem.STATES.NORMAL then customDamageAmount = 0.5
            elseif cs == AdvancedDamageSystem.STATES.BAD then customDamageAmount = 0.75
            else customDamageAmount = 1.0 end
        else
            customDamageAmount = selectedTool:getDamageAmount()
        end
    end

    local originalGetDamageMethods = {}
    if useCustomValue then
        local allVehicles = vehicle.rootVehicle.childVehicles
        
        for _, v in ipairs(allVehicles) do
            originalGetDamageMethods[v] = v.getDamageAmount 
            v.getDamageAmount = function() 
                return customDamageAmount 
            end
        end
    end

    local result = originalSpeedMeterDisplayDraw(self, ...)

    if useCustomValue then
        for vehicleInstance, originalMethod in pairs(originalGetDamageMethods) do
            vehicleInstance.getDamageAmount = originalMethod
        end
    end
    return result
end

-- =====================================================================================
--                         VEHICLE INFO PANEL
-- =====================================================================================

function ADS_Hud:showInfoVehicle(box)
    if self.spec_AdvancedDamageSystem ~= nil then
        local spec = self.spec_AdvancedDamageSystem
        
        box:addLine(g_i18n:getText('ads_ws_label_condition'), ADS_Utils.formatCondition(self:getLastInspectedCondition()))
        box:addLine(g_i18n:getText("ads_ws_label_last_inspection"), ADS_Utils.formatTimeAgo(self:getLastInspectionDate()))
        box:addLine(g_i18n:getText("ads_ws_label_last_maintenance"), ADS_Utils.formatTimeAgo(self:getLastMaintenanceDate()))
        box:addLine(g_i18n:getText("ads_ws_label_service_interval"), ADS_Utils.formatOperatingHours(self:getHoursSinceLastMaintenance(), self:getMaintenanceInterval()))

        
        if spec.currentState ~= AdvancedDamageSystem.STATUS.READY and spec.currentState ~= AdvancedDamageSystem.STATUS.BROKEN then
            local maintenanceStatusText = string.format(g_i18n:getText("ads_spec_last_maintenance_until_format"), g_i18n:getText(spec.currentState), ADS_Utils.formatFinishTime(self:getServiceFinishTime()))
            box:addLine(maintenanceStatusText)
        end
    end
end

Vehicle.showInfo = Utils.appendedFunction(Vehicle.showInfo, ADS_Hud.showInfoVehicle)




