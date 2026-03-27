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
            year = 1970
        },
        oil = {
            name = 'oil',
            icon = g_overlayManager:createOverlay("ads_DashboardHud.oil", 0, 0, 0, 0),
            year = 1950
        }
    }
    self.engineTempText = {}
    self.motorLoadText = {}
    self.batteryVoltageText = {}
    self.tsTempText = {
        year = 2000
    }

    self.fuelConsoText = {}

    self.activeVehicleDebugPanel = {
        x = 0.20,
        y = 0.05,
        width = 0.60,
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

function ADS_Hud:getVehicleTypeCategoryLabel(vehicle)
    local vehicleTypeName = "-"
    local categoryName = "-"

    if vehicle ~= nil and vehicle.type ~= nil and vehicle.type.name ~= nil then
        vehicleTypeName = tostring(vehicle.type.name)
    end

    if vehicle ~= nil and g_storeManager ~= nil and g_storeManager.getItemByXMLFilename ~= nil then
        local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
        if storeItem ~= nil and storeItem.categoryName ~= nil then
            categoryName = tostring(storeItem.categoryName)
        end
    end

    return string.format("%s/%s", vehicleTypeName, categoryName)
end


-- =====================================================================================
--                              DRAW
-- =====================================================================================

function ADS_Hud:draw()
    if g_currentMission == nil or not g_currentMission.hud.isVisible then
        return
    end

    -- manager debug panel temporarily disabled

    if ADS_Config.DEBUG and g_currentMission.isMasterUser and self.vehicle ~= nil and self.activeVehicleDebugPanel.isVisible then
        self:drawActiveVehicleHUD()
    end

    if self.vehicle ~= nil then
        self:drawDashboard()
        self:drawFuelConsumption()
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

    self.batteryVoltageText.offsetX, self.batteryVoltageText.offsetY = self:scalePixelValuesToScreenVector(37, 4)
	self.batteryVoltageText.size = self:scalePixelToScreenHeight(9)

    self.tsTempText.offsetX, self.tsTempText.offsetY = self:scalePixelValuesToScreenVector(38, 3)
	self.tsTempText.size = self:scalePixelToScreenHeight(8)

    self.fuelConsoText.offsetX, self.fuelConsoText.offsetY = self:scalePixelValuesToScreenVector(8, 4)
    self.fuelConsoText.size = self:scalePixelToScreenHeight(13)
end

function ADS_Hud:drawDashboard()
    if self.vehicle == nil or self.vehicle.spec_AdvancedDamageSystem == nil or self.vehicle.spec_AdvancedDamageSystem.isExcludedVehicle then
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
        

        if vehicle:getIsMotorStarted() or vehicle:getMotorState() == 2 then
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

            local serviceInterval = (self.vehicle:getHoursSinceLastMaintenance() or 1) / (self.vehicle:getMaintenanceInterval() or 10)
            if hudIndicatorId == self.indicators.service.name and serviceInterval > 1.0 then targetColor = colors.WARNING end
            if hudIndicatorId == self.indicators.oil.name and spec.serviceLevel < 0.2 then targetColor = colors.WARNING end

            if vehicle:getMotorState() == 2 then
                targetColor = colors.WARNING
            end
        else
            local activeData = activeIndicators[hudIndicatorId]
            if activeData then
                activeData.isActive = false
            end
        end

        icon:setColor(unpack(targetColor))
        icon:setPosition(posX + hudIndicatorData.offsetX, posY + hudIndicatorData.offsetY)
        if hudIndicatorId == self.indicators.coolant.name and spec.isElectricVehicle or hudIndicatorId == self.indicators.oil.name or hudIndicatorId == self.indicators.transmission.name then 
            icon:setVisible(false)
        else
            icon:setVisible(hudIndicatorData.year < spec.year)
        end
        icon:render()
        end

    local engineTemp, transTemp, systemVoltageV = spec.engineTemperature, spec.transmissionTemperature, spec.systemVoltageV
    local motorLoad = spec._smoothedMotorLoad or 0

    local tempSign = "°C"
    local voltageSing = "V"

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

    local batteryVoltageText = string.format("%.1f%s", systemVoltageV, voltageSing)
    local motorText = string.format("%.0f%%", math.max(motorLoad * 100, 0))

    local batteryVoltageTextColor = {1, 1, 1, 1}
    if systemVoltageV < 12 then
        batteryVoltageTextColor = colors.WARNING
    end

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
        setTextColor(batteryVoltageTextColor[1], batteryVoltageTextColor[2], batteryVoltageTextColor[3], batteryVoltageTextColor[4])
        renderText(posX + self.batteryVoltageText.offsetX, posY + self.batteryVoltageText.offsetY, self.batteryVoltageText.size, batteryVoltageText)
    end

    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BOTTOM)
    setTextBold(false)
end

-- =====================================================================================
--                          FUEL CONSUMPTION HUD
-- =====================================================================================

function ADS_Hud:drawFuelConsumption()
    local vehicle = self.vehicle
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil or vehicle.spec_motorized == nil then
        return
    end
    local sm = g_currentMission.hud.speedMeter
    if sm == nil or sm.fuelIcon == nil then
        return
    end

    local fuelLevel, fuelCapacity, fuelType = SpeedMeterDisplay.getVehicleFuelLevelAndCapacity(vehicle)
    if fuelCapacity == nil or fuelCapacity <= 0 then
        return
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    local consumption = 0
    if vehicle:getIsMotorStarted() then
        if spec.isExcludedVehicle then
            consumption = vehicle.spec_motorized.lastFuelUsageDisplay or vehicle.spec_motorized.lastFuelUsage or 0
        else
            consumption = spec.fuelUsage or 0
        end
    end

    local isElectric  = (fuelType == FillType.ELECTRICCHARGE)
    local unit        = isElectric and "kW" or "L/h"

    local fuelIconX, fuelIconY = sm.fuelIcon:getPosition()
    local fuelIconW = sm.fuelIcon.width or 0
    local centerX = fuelIconX + fuelIconW * 0.5
    local textY   = fuelIconY + self.fuelConsoText.offsetY

    local valueStr = string.format("%.1f", consumption)
    local gap = 0.002

    setTextBold(true)
    local valueWidth = getTextWidth(self.fuelConsoText.size, valueStr)
    local unitWidth  = getTextWidth(self.fuelConsoText.size, unit)
    local totalWidth = valueWidth + gap + unitWidth
    local startX = centerX - totalWidth * 0.5

    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_TOP)
    setTextAlignment(RenderText.ALIGN_LEFT)

    setTextColor(1, 0.4287, 0.0006, 1)
    renderText(startX, textY, self.fuelConsoText.size, valueStr)

    setTextColor(1, 1, 1, 1)
    renderText(startX + valueWidth + gap, textY, self.fuelConsoText.size, unit)

    setTextBold(false)
    setTextColor(1, 1, 1, 1)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BOTTOM)
    setTextAlignment(RenderText.ALIGN_LEFT)
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

    local function buildPendingSystemTransitionEntries(startMap, targetMap, currentValueGetter, formatter)
        local entries = {}
        startMap = startMap or {}
        targetMap = targetMap or {}

        for systemKey, startValue in pairs(startMap) do
            local targetValue = targetMap[systemKey]
            if targetValue ~= nil then
                local currentValue = currentValueGetter(systemKey)
                table.insert(entries, string.format(
                    "%s: %s->%s (cur %s)",
                    tostring(systemKey),
                    formatter(startValue),
                    formatter(targetValue),
                    formatter(currentValue)
                ))
            end
        end

        table.sort(entries)
        return entries
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

    local function getBreakdownSourceLabel(source)
        if source == AdvancedDamageSystem.BREAKDOWN_SOURCES.POOR_PARTS then
            return "PARTS"
        elseif source == AdvancedDamageSystem.BREAKDOWN_SOURCES.QUICK_FIX then
            return "QFIX"
        end
        return "RAND"
    end

    local breakdownEntries = {}
    if spec.activeBreakdowns and next(spec.activeBreakdowns) ~= nil then
        for id, breakdown in pairs(spec.activeBreakdowns) do
            local visible = breakdown.isVisible and "V" or "-"
            local selected = breakdown.isSelectedForRepair and "S" or "-"
            local active = breakdown.isActive ~= false and "A" or "-"
            local resumeTimerS = math.max((tonumber(breakdown.resumeTimer) or 0) / 1000, 0)
            local source = getBreakdownSourceLabel(breakdown.source)
            local stage = tonumber(breakdown.stage) or 0
            local progressTimerS = math.max((tonumber(breakdown.progressTimer) or 0) / 1000, 0)

            table.insert(breakdownEntries, string.format(
                "%s[st:%d|pr:%.0fs|rs:%.0fs|%s%s%s|src:%s]",
                id,
                stage,
                progressTimerS,
                resumeTimerS,
                visible,
                selected,
                active,
                source
            ))
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

    local function formatAppliedMultiplier(value)
        local formatted = string.format("%.2f", tonumber(value) or 0)
        formatted = formatted:gsub("(%..-)0+$", "%1")
        formatted = formatted:gsub("%.$", "")
        return "x" .. formatted
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

    local function isSystemEnabled(systemKey)
        local systemData = spec.systems and spec.systems[systemKey]
        if type(systemData) == "table" then
            return systemData.enabled ~= false
        end
        return true
    end

    local engineDbg = spec.debugData.engine or {}
    local transmissionDbg = spec.debugData.transmission or {}
    local hydraulicsDbg = spec.debugData.hydraulics or {}
    local coolingDbg = spec.debugData.cooling or {}
    local electricalDbg = spec.debugData.electrical or {}
    local chassisDbg = spec.debugData.chassis or {}
    local fuelDbg = spec.debugData.fuel or {}
    local workprocessDbg = spec.debugData.workprocess or {}
    local serviceDbg = spec.debugData.service or {}
    local batteryDbg = spec.debugData.battery or {}

    local overviewLines = {}
    local serviceWearRate = serviceDbg.totalWearRate or ADS_Config.CORE.BASE_SERVICE_WEAR or 0
    local weatherFactor = tonumber((ADS_Main ~= nil and ADS_Main.currentWeatherFactor) or 1.0) or 1.0
    local dirtLevel = tonumber(vehicle.getDirtAmount ~= nil and vehicle:getDirtAmount() or 0) or 0
    local radiatorClogging = tonumber(spec.radiatorClogging or 0) or 0
    local airIntakeClogging = tonumber(spec.airIntakeClogging or 0) or 0
    local lubricationLevel = tonumber(spec.lubricationLevel or 0) or 0
    local paintState = math.max(1 - (tonumber(vehicle.getWearTotalAmount ~= nil and vehicle:getWearTotalAmount() or 0) or 0), 0)
    local radiatorDbg = spec.debugData.radiator or {}
    local airIntakeDbg = spec.debugData.airIntake or {}
    local radiatorMultiplier = tonumber(radiatorDbg.totalMultiplier or 0) or 0
    local airIntakeMultiplier = tonumber(airIntakeDbg.totalMultiplier or 0) or 0
    local cloggingIsOnField = radiatorDbg.isOnField == true or airIntakeDbg.isOnField == true
    local cloggingHasDust = radiatorDbg.hasDust == true or airIntakeDbg.hasDust == true
    local cloggingHasDebris = radiatorDbg.hasDebris == true or airIntakeDbg.hasDebris == true
    local cloggingWetnessFactor = tonumber(airIntakeDbg.baseWetnessFactor or radiatorDbg.baseWetnessFactor or 1) or 1
    addLine(overviewLines, string.format(
        "condition: %.2f%% | service: %.2f%% | service_wear: %.2f%% | rel: %.2f%% | mnt: %.2f%% | wf: %.3f | roof: %s | lube: %.2f%% | paint: %.2f%%",
        asPercent(spec.conditionLevel or 0),
        asPercent(spec.serviceLevel or 0),
        asPercent(serviceWearRate),
        asPercent(spec.reliability or 0),
        asPercent(spec.maintainability or 0),
        weatherFactor,
        tostring(spec.isUnderRoof == true),
        asPercent(lubricationLevel),
        asPercent(paintState)
    ), {1, 1, 1, 1}, 0.95)

    addLine(overviewLines, string.format(
        "Clogging: Dirt %.2f%% | Rad: %.2f%% (%s) | AI: %.2f%% (%s) | field: %s, dust: %s, derbis: %s, wtf: %.3f",
        asPercent(dirtLevel),
        asPercent(radiatorClogging),
        formatAppliedMultiplier(radiatorMultiplier),
        asPercent(airIntakeClogging),
        formatAppliedMultiplier(airIntakeMultiplier),
        tostring(cloggingIsOnField),
        tostring(cloggingHasDust),
        tostring(cloggingHasDebris),
        cloggingWetnessFactor
    ), {1, 1, 1, 1}, 0.95)

    local engineMaxFactor = math.max(
        engineDbg.motorLoadFactor or 0,
        engineDbg.airIntakeCloggingFactor or 0,
        engineDbg.expiredServiceFactor or 0,
        engineDbg.coldMotorFactor or 0,
        engineDbg.hotMotorFactor or 0
    ) * bcw
    local transmissionMaxFactor = math.max(
        transmissionDbg.expiredServiceFactor or 0,
        transmissionDbg.pullOverloadFactor or 0,
        transmissionDbg.heavyTrailerFactor or 0,
        transmissionDbg.luggingFactor or 0,
        transmissionDbg.wheelSlipFactor or 0,
        transmissionDbg.coldTransFactor or transmissionDbg.coldMotorFactor or 0,
        transmissionDbg.hotTransFactor or 0
    ) * bcw
    local hydraulicsMaxFactor = math.max(
        hydraulicsDbg.expiredServiceFactor or 0,
        hydraulicsDbg.heavyLiftFactor or 0,
        hydraulicsDbg.operatingFactor or 0,
        hydraulicsDbg.coldOilFactor or 0,
        hydraulicsDbg.ptoOperatingFactor or 0,
        hydraulicsDbg.sharpAngleFactor or 0
    ) * bcw
    local coolingMaxFactor = math.max(
        coolingDbg.expiredServiceFactor or 0,
        coolingDbg.highCoolingFactor or 0,
        coolingDbg.overheatFactor or 0,
        coolingDbg.coldShockFactor or 0
    ) * bcw
    local electricalMaxFactor = math.max(
        electricalDbg.expiredServiceFactor or 0,
        electricalDbg.weatherExposureFactor or 0,
        electricalDbg.lightsFactor or 0,
        electricalDbg.crankingStressFactor or 0,
        electricalDbg.overheatFactor or 0
    ) * bcw
    local chassisMaxFactor = math.max(
        chassisDbg.expiredServiceFactor or 0,
        chassisDbg.vibFactor or 0,
        chassisDbg.steerLoadFactor or 0,
        chassisDbg.brakeMassFactor or 0
    ) * bcw
    local fuelMaxFactor = math.max(
        fuelDbg.expiredServiceFactor or 0,
        fuelDbg.lowFuelStarvationFactor or 0,
        fuelDbg.coldFuelFactor or 0,
        fuelDbg.idleDepositFactor or 0,
        fuelDbg.highPressureFactor or 0
    ) * bcw
    local workprocessMaxFactor = math.max(
        workprocessDbg.expiredServiceFactor or 0,
        workprocessDbg.longHarvestFactor or 0,
        workprocessDbg.wetCropFactor or 0,
        workprocessDbg.lubricationFactor or 0
    ) * bcw

    local factorStats = {}
    for rawSystemKey, rawStats in pairs(spec.factorStats or {}) do
        if type(rawStats) == "table" then
            factorStats[string.lower(tostring(rawSystemKey))] = rawStats
        end
    end

    local function getAccumulatedStat(systemKey, statKey)
        local stats = factorStats[string.lower(tostring(systemKey))]
        if type(stats) ~= "table" then
            return 0
        end
        return tonumber(stats[statKey]) or 0
    end

    local function formatFactorLine(systemKey, shortName, factorValue, statKey, extraInfo, systemStressMultiplier)
        local currentPct = asPercent((factorValue or 0) * bcw)
        local conditionSum = getAccumulatedStat(systemKey, statKey)
        local sumPct = asPercent(conditionSum)
        local stressPct = asPercent(conditionSum * (systemStressMultiplier or 1))
        local extraText = ""
        if extraInfo ~= nil and tostring(extraInfo) ~= "" then
            extraText = " (" .. tostring(extraInfo) .. ")"
        end
        return string.format("%s: %.2f | %.2f | %.2f%s", shortName, currentPct, sumPct, stressPct, extraText)
    end

    local function buildSystemLines(systemKey, dbg, maxFactor, factorEntries)
        local lines = {}
        local systemStressMultiplier = tonumber(ADS_Config.CORE.SYSTEM_STRESS_ACCUMULATION_MULTIPLIERS[systemKey]) or 1
        addLine(lines, string.format(
            "C: %.1f (-%.2f)",
            asPercent(getSystemCondition(systemKey)),
            asPercent((dbg.totalWearRate or 0) * bcw)
        ), getConditionFactorColor(maxFactor), 0.84)
        addLine(lines, string.format(
            "S: %.2f (%.2f)",
            asPercent(getSystemStress(systemKey)),
            asPercent(getAccumulatedStat(systemKey, "stress"))
        ), {1, 1, 1, 1}, 0.84)

        addLine(lines, string.format(
            "B: %.2f | %.2f",
            asPercent(dbg.breakdownProbability or 0),
            asPercent(dbg.critBreakdownProbability or 0)
        ), {1, 0.82, 0.82, 1}, 0.80)

        if #factorEntries > 0 then
            addLine(lines, "", {1, 1, 1, 1}, 0.80)
        end

        for _, entry in ipairs(factorEntries) do
            addLine(
                lines,
                formatFactorLine(systemKey, entry.shortName, entry.value, entry.statKey, entry.extraInfo, systemStressMultiplier),
                {0.92, 0.96, 1.0, 1},
                0.80
            )
        end

        return lines
    end

    local engineLines = buildSystemLines("engine", engineDbg, engineMaxFactor, {
        { shortName = "sf", statKey = "sf", value = engineDbg.expiredServiceFactor or 0 },
        { shortName = "bpf", statKey = "bpf", value = engineDbg.breakdownPresenceFactor or 0 },
        { shortName = "mlf", statKey = "mlf", value = engineDbg.motorLoadFactor or 0 },
        { shortName = "aicf", statKey = "aicf", value = engineDbg.airIntakeCloggingFactor or 0 },
        { shortName = "cmf", statKey = "cmf", value = engineDbg.coldMotorFactor or 0 },
        { shortName = "hmf", statKey = "hmf", value = engineDbg.hotMotorFactor or 0 }
    })

    local transmissionLines = buildSystemLines("transmission", transmissionDbg, transmissionMaxFactor, {
        { shortName = "sf", statKey = "sf", value = transmissionDbg.expiredServiceFactor or 0 },
        { shortName = "bpf", statKey = "bpf", value = transmissionDbg.breakdownPresenceFactor or 0 },
        { shortName = "pof", statKey = "pof", value = transmissionDbg.pullOverloadFactor or 0, extraInfo = string.format("t: %.1fs", transmissionDbg.pullOverloadTimer or 0) },
        { shortName = "lf", statKey = "lf", value = transmissionDbg.luggingFactor or 0 },
        { shortName = "wsf", statKey = "wsf", value = transmissionDbg.wheelSlipFactor or transmissionDbg.wheelSleepFactor or 0, extraInfo = string.format("wsi: %.2f", asPercent(transmissionDbg.wheelSlipIntensity or 0)) },
        { shortName = "ctf", statKey = "ctf", value = (transmissionDbg.coldTransFactor or transmissionDbg.coldMotorFactor) or 0 },
        { shortName = "hotf", statKey = "hotf", value = transmissionDbg.hotTransFactor or 0 }
    })

    local hydraulicsLines = buildSystemLines("hydraulics", hydraulicsDbg, hydraulicsMaxFactor, {
        { shortName = "sf", statKey = "sf", value = hydraulicsDbg.expiredServiceFactor or 0 },
        { shortName = "bpf", statKey = "bpf", value = hydraulicsDbg.breakdownPresenceFactor or 0 },
        { shortName = "hlf", statKey = "hlf", value = hydraulicsDbg.heavyLiftFactor or 0, extraInfo = string.format("mr: %.2f", asPercent(hydraulicsDbg.heavyLiftMassRatio or 0)) },
        { shortName = "of", statKey = "of", value = hydraulicsDbg.operatingFactor or 0 },
        { shortName = "cof", statKey = "cof", value = hydraulicsDbg.coldOilFactor or 0 },
        { shortName = "saf", statKey = "saf", value = hydraulicsDbg.sharpAngleFactor or 0, extraInfo = string.format("%.1f deg", hydraulicsDbg.ptoSharpAngleDeg or 0) }
    })

    local coolingLines = buildSystemLines("cooling", coolingDbg, coolingMaxFactor, {
        { shortName = "sf", statKey = "sf", value = coolingDbg.expiredServiceFactor or 0 },
        { shortName = "bpf", statKey = "bpf", value = coolingDbg.breakdownPresenceFactor or 0 },
        { shortName = "hcf", statKey = "hcf", value = coolingDbg.highCoolingFactor or 0, extraInfo = string.format("ts: %.1f", asPercent(spec.thermostatState or 0)) },
        { shortName = "ohf", statKey = "ohf", value = coolingDbg.overheatFactor or 0 },
        { shortName = "csf", statKey = "csf", value = coolingDbg.coldShockFactor or 0 }
    })

    local electricalLines = buildSystemLines("electrical", electricalDbg, electricalMaxFactor, {
        { shortName = "sf", statKey = "sf", value = electricalDbg.expiredServiceFactor or 0 },
        { shortName = "bpf", statKey = "bpf", value = electricalDbg.breakdownPresenceFactor or 0 },
        { shortName = "wef", statKey = "wef", value = electricalDbg.weatherExposureFactor or 0 },
        { shortName = "ltf", statKey = "ltf", value = electricalDbg.lightsFactor or 0 },
        { shortName = "crf", statKey = "crf", value = electricalDbg.crankingStressFactor or 0, extraInfo = string.format("c: %s", tostring(spec.systems ~= nil and spec.systems.electrical ~= nil and spec.systems.electrical.isCranking == true)) },
        { shortName = "ohf", statKey = "ohf", value = electricalDbg.overheatFactor or 0 }
    })

    local chassisLines = buildSystemLines("chassis", chassisDbg, chassisMaxFactor, {
        { shortName = "sf", statKey = "sf", value = chassisDbg.expiredServiceFactor or 0 },
        { shortName = "bpf", statKey = "bpf", value = chassisDbg.breakdownPresenceFactor or 0 },
        { shortName = "vf", statKey = "vf", value = chassisDbg.vibFactor or 0, extraInfo = string.format("r/s: %.2f / %.2f", asPercent(chassisDbg.vibRaw or 0), asPercent(chassisDbg.vibSignal or 0)) },
        { shortName = "slf", statKey = "slf", value = chassisDbg.steerLoadFactor or 0, extraInfo = string.format("d: %.2f", asPercent(chassisDbg.steerDeltaRate or 0)) },
        { shortName = "bmf", statKey = "bmf", value = chassisDbg.brakeMassFactor or 0, extraInfo = string.format("mr: %.2f", chassisDbg.brakeMassRatio or 0) }
    })

    local fuelLines = buildSystemLines("fuel", fuelDbg, fuelMaxFactor, {
        { shortName = "sf", statKey = "sf", value = fuelDbg.expiredServiceFactor or 0 },
        { shortName = "bpf", statKey = "bpf", value = fuelDbg.breakdownPresenceFactor or 0 },
        { shortName = "lff", statKey = "lff", value = fuelDbg.lowFuelStarvationFactor or 0, extraInfo = string.format("lvl: %.2f", asPercent(fuelDbg.fuelLevel or 0)) },
        { shortName = "cff", statKey = "cff", value = fuelDbg.coldFuelFactor or 0, extraInfo = string.format("ft: %.1f C", fuelDbg.fuelTemperature or 0) },
        { shortName = "idf", statKey = "idf", value = fuelDbg.idleDepositFactor or 0, extraInfo = string.format("t: %.0fs", fuelDbg.idleTimer or 0) },
        { shortName = "hpf", statKey = "hpf", value = fuelDbg.highPressureFactor or 0 }
    })

    local workprocessLines = buildSystemLines("workprocess", workprocessDbg, workprocessMaxFactor, {
        { shortName = "sf", statKey = "sf", value = workprocessDbg.expiredServiceFactor or 0 },
        { shortName = "bpf", statKey = "bpf", value = workprocessDbg.breakdownPresenceFactor or 0 },
        { shortName = "lhf", statKey = "lhf", value = workprocessDbg.longHarvestFactor or 0, extraInfo = string.format("t: %.0fs", workprocessDbg.longHarvestTimer or 0) },
        { shortName = "wcf", statKey = "wcf", value = workprocessDbg.wetCropFactor or 0 },
        { shortName = "lubf", statKey = "lubf", value = workprocessDbg.lubricationFactor or 0, extraInfo = string.format("lvl: %.1f%%", asPercent(lubricationLevel)) }
    })

    if isSystemEnabled("workprocess") then
        local isTurnedOn = vehicle.getIsTurnedOn ~= nil and vehicle:getIsTurnedOn() or false
        local dischargeState = vehicle.spec_dischargeable ~= nil and vehicle.spec_dischargeable.currentDischargeState or -1
        local harvestPercent = workprocessDbg.currentHarvestPercent or 100
        local unloadPercent = workprocessDbg.lastUnloadPercent or 100
        local unloadFactor = workprocessDbg.lastUnloadFactor or 1
        local unloadOriginalFactor = workprocessDbg.lastUnloadOriginalFactor or 1

        addLine(workprocessLines, string.format(
            "proc: on %s | ds %s | yield %.1f%% | unload %.1f%% (%.3f/%.3f)",
            tostring(isTurnedOn),
            tostring(dischargeState),
            harvestPercent,
            unloadPercent,
            unloadFactor,
            unloadOriginalFactor
        ), {0.92, 0.98, 1.0, 1}, 0.90)
    end

    local systemSections = {}
    if isSystemEnabled("engine") then
        table.insert(systemSections, {title = "Engine", lines = engineLines})
    end
    if isSystemEnabled("transmission") then
        table.insert(systemSections, {title = "Transmission", lines = transmissionLines})
    end
    if isSystemEnabled("hydraulics") then
        table.insert(systemSections, {title = "Hydraulics", lines = hydraulicsLines})
    end
    if isSystemEnabled("cooling") then
        table.insert(systemSections, {title = "Cooling", lines = coolingLines})
    end
    if isSystemEnabled("electrical") then
        table.insert(systemSections, {title = "Electrical", lines = electricalLines})
    end
    if isSystemEnabled("chassis") then
        table.insert(systemSections, {title = "Chassis", lines = chassisLines})
    end
    if isSystemEnabled("fuel") then
        table.insert(systemSections, {title = "Fuel", lines = fuelLines})
    end
    if isSystemEnabled("workprocess") then
        table.insert(systemSections, {title = "Work Process", lines = workprocessLines})
    end

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
            "T: %.1fC | ts: %.3f | k/s/w: %.2f/%.3f/%.3f | h: %.3f(l/s/a/p/ws: %.2f/%.2f/%.2f/%.2f/%.2f) | c: %.3f(r/s/c: %.3f/%.3f/%.3f) | cvt: a/l=%d/%d eh=%.3f",
            spec.transmissionTemperature,
            spec.transmissionThermostatState,
            spec.debugData.transmissionTemp.kp or 0,
            spec.debugData.transmissionTemp.stiction or 0,
            spec.debugData.transmissionTemp.waxSpeed or 0,
            spec.debugData.transmissionTemp.totalHeat or 0,
            spec.debugData.transmissionTemp.loadFactor or 0,
            spec.debugData.transmissionTemp.slipFactor or 0,
            spec.debugData.transmissionTemp.accFactor or 0,
            spec.debugData.transmissionTemp.pullFactor or 0,
            spec.debugData.transmissionTemp.wheelSlipFactor or 0,
            spec.debugData.transmissionTemp.totalCooling or 0,
            spec.debugData.transmissionTemp.radiatorCooling or 0,
            spec.debugData.transmissionTemp.speedCooling or 0,
            spec.debugData.transmissionTemp.convectionCooling or 0,
            spec.debugData.transmissionTemp.cvtSlipActive or 0,
            spec.debugData.transmissionTemp.cvtSlipLocked or 0,
            spec.debugData.transmissionTemp.extraTransmissionHeat or 0
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

    local batteryLines = {}
    local soc = spec.batterySoc or batteryDbg.soc or 0
    local ocvV = batteryDbg.ocvV or 0
    local termV = spec.batteryTerminalVoltageV or batteryDbg.batteryTerminalVoltageV or batteryDbg.batteryTerminalV or ocvV
    local systemV = spec.systemVoltageV or batteryDbg.systemVoltageVSmoothed or batteryDbg.systemVoltageV or termV
    local tempC = batteryDbg.batteryTempC or spec.batteryTempC or 0
    local targetC = batteryDbg.battTempTargetC or 0
    local iAlt = batteryDbg.iAltAvail or 0
    local iLoads = batteryDbg.iLoads or 0
    local iNet = batteryDbg.iNet or batteryDbg.iNetRaw or (iAlt - iLoads)
    local chargeAh = batteryDbg.chargeAh or spec.batteryChargeAh or 0

    addLine(batteryLines, string.format(
        "Voltage: sys %.2fV | term: %.2fV | ocv: %.1fV",
        systemV,
        termV,
        ocvV
    ), {0.9, 1.0, 0.9, 1}, 0.95)

    addLine(batteryLines, string.format(
        "Battery: %.1fA | %.2f Ah (%.1f%%) | Temp %.1fC -> %.1fC | acc %.3f | rint %.5f",
        iNet,
        chargeAh,
        asPercent(soc),
        tempC,
        targetC,
        batteryDbg.acceptK or 1,
        batteryDbg.rIntOhm or 0
    ), {0.9, 1.0, 0.9, 1}, 0.95)

    addLine(batteryLines, string.format(
        "Alternator: %.1fA (raw: %.1fA | k %.2f)",
        iAlt,
        batteryDbg.iAltRaw or iAlt,
        batteryDbg.altFactor or 0
    ), {0.9, 1.0, 0.9, 1}, 0.95)

    addLine(batteryLines, string.format(
        "Loads: %.1fA (base: %.1fA | lights: %.1fA | cabFan: %.1fA | winHeat: %.1fA | pulse: %.1fA | crank: %.1fA)",
        iLoads,
        batteryDbg.baseLoadA or 0,
        batteryDbg.lightsLoadA or 0,
        batteryDbg.cabFanA or 0,
        batteryDbg.winterHeaterA or 0,
        batteryDbg.peakPulseA or 0,
        batteryDbg.crankingLoadA or 0
    ), {0.85, 0.95, 1.0, 1}, 0.95)

    if (batteryDbg.externalConnected or 0) > 0 then
        addLine(batteryLines, string.format(
            "External: %s | bal %.1fA | com: %.1fA",
            tostring(batteryDbg.externalPartnerName or "-"),
            batteryDbg.externalBalanceCurrentA or 0,
            batteryDbg.externalCommonNetA or 0
        ), {0.85, 0.95, 1.0, 1}, 0.95)
    end

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
            "svc s->t: %s->%s | cur s/c: %.4f/%.4f",
            tostring(spec.pendingMaintenanceServiceStart),
            tostring(spec.pendingMaintenanceServiceTarget),
            spec.serviceLevel or 0,
            spec.conditionLevel or 0
        ), {1, 0.95, 0.75, 1}, 0.95)

        if spec.currentState == states.OVERHAUL then
            local overhaulSystemStart = spec.pendingOverhaulSystemStart or {}
            local overhaulSystemTarget = spec.pendingOverhaulSystemTarget or {}
            local overhaulStressStart = spec.pendingOverhaulSystemStressStart or {}
            local overhaulStressTarget = spec.pendingOverhaulSystemStressTarget or {}
            local conditionEntries = buildPendingSystemTransitionEntries(
                overhaulSystemStart,
                overhaulSystemTarget,
                function(systemKey)
                    local systemData = spec.systems and spec.systems[systemKey]
                    return type(systemData) == "table" and (tonumber(systemData.condition) or 0) or 0
                end,
                function(value)
                    return string.format("%.3f", tonumber(value) or 0)
                end
            )
            local stressEntries = buildPendingSystemTransitionEntries(
                overhaulStressStart,
                overhaulStressTarget,
                function(systemKey)
                    local systemData = spec.systems and spec.systems[systemKey]
                    return type(systemData) == "table" and (tonumber(systemData.stress) or 0) or 0
                end,
                function(value)
                    return string.format("%.3f", tonumber(value) or 0)
                end
            )

            addLine(serviceDataLines, "ovh cond:", {1, 0.95, 0.75, 1}, 0.95)
            local conditionLines = packEntries(conditionEntries, 2, {1, 0.95, 0.75, 1}, 0.95)
            for _, line in ipairs(conditionLines) do
                table.insert(serviceDataLines, line)
            end

            addLine(serviceDataLines, "ovh stress:", {1, 0.95, 0.75, 1}, 0.95)
            local stressLines = packEntries(stressEntries, 2, {1, 0.95, 0.75, 1}, 0.95)
            for _, line in ipairs(stressLines) do
                table.insert(serviceDataLines, line)
            end
        elseif spec.currentState == states.REPAIR then
            local repairStressEntries = buildPendingSystemTransitionEntries(
                spec.pendingRepairSystemStressStart or {},
                spec.pendingRepairSystemStressTarget or {},
                function(systemKey)
                    local systemData = spec.systems and spec.systems[systemKey]
                    return type(systemData) == "table" and (tonumber(systemData.stress) or 0) or 0
                end,
                function(value)
                    return string.format("%.3f", tonumber(value) or 0)
                end
            )

            if #repairStressEntries > 0 then
                addLine(serviceDataLines, "rep stress:", {1, 0.95, 0.75, 1}, 0.95)
                local repairStressLines = packEntries(repairStressEntries, 2, {1, 0.95, 0.75, 1}, 0.95)
                for _, line in ipairs(repairStressLines) do
                    table.insert(serviceDataLines, line)
                end
            end
        elseif spec.currentState == states.MAINTENANCE and spec.serviceOptionOne == AdvancedDamageSystem.MAINTENANCE_TYPES.PREVENTIVE then
            local preventiveStressEntries = buildPendingSystemTransitionEntries(
                spec.pendingPreventiveSystemStressStart or {},
                spec.pendingPreventiveSystemStressTarget or {},
                function(systemKey)
                    local systemData = spec.systems and spec.systems[systemKey]
                    return type(systemData) == "table" and (tonumber(systemData.stress) or 0) or 0
                end,
                function(value)
                    return string.format("%.3f", tonumber(value) or 0)
                end
            )

            addLine(serviceDataLines, string.format(
                "prev sys: %d/%d | factor: %.3f",
                #preventiveStressEntries,
                tonumber(ADS_Config.MAINTENANCE.MAINTENANCE_PREVENTIVE_SYSTEMS_COUNT) or 0,
                tonumber(ADS_Config.MAINTENANCE.MAINTENANCE_PREVENTIVE_STRESS_REMOVE_MULTIPLIER) or 0
            ), {1, 0.95, 0.75, 1}, 0.95)

            local preventiveStressLines = packEntries(preventiveStressEntries, 2, {1, 0.95, 0.75, 1}, 0.95)
            for _, line in ipairs(preventiveStressLines) do
                table.insert(serviceDataLines, line)
            end
        end

        addLine(serviceDataLines, "sel: " .. listToString(pendingSelectedBreakdowns), {1, 0.95, 0.75, 1}, 0.95)
        addLine(serviceDataLines, "insp: " .. listToString(pendingInspectionQueue), {1, 0.95, 0.75, 1}, 0.95)
        addLine(serviceDataLines, "rep: " .. listToString(pendingRepairQueue), {1, 0.95, 0.75, 1}, 0.95)
    end

    local overviewSection = {title = "Overall", lines = overviewLines}
    local sections = {
        {title = "Engine Temp", lines = engineTempLines}
    }

    if showTransmissionSection then
        table.insert(sections, {title = "CVT Temp", lines = transmissionTempLines})
    end

    table.insert(sections, {title = "Drivetrain", lines = drivetrainLines})
    table.insert(sections, {title = "Battery", lines = batteryLines, showTitle = false})
    if isUnderService then
        table.insert(sections, {title = "Service Data", lines = serviceDataLines})
    end
    if #breakdownEntries > 0 then
        table.insert(sections, {title = "Active Breakdowns", lines = breakdownLines})
    end
    if #effectEntries > 0 then
        table.insert(sections, {title = "Active Effects", lines = effectLines})
    end

    if #aiCruiseLines > 0 then
        table.insert(sections, {title = "AI Cruise Control", lines = aiCruiseLines})
    end

    local systemColumns = math.min(8, math.max(#systemSections, 1))
    local systemGapX = 0.00012
    local systemGapY = sectionGap * 0.16
    local systemRows = (#systemSections > 0) and math.ceil(#systemSections / systemColumns) or 0
    local rowHeights = {}
    local totalSystemHeight = 0

    for row = 1, systemRows do
        local rowMaxLines = 0
        for col = 1, systemColumns do
            local index = (row - 1) * systemColumns + col
            local section = systemSections[index]
            if section ~= nil then
                rowMaxLines = math.max(rowMaxLines, #section.lines)
            end
        end
        local rowHeight = (rowMaxLines + 1) * activeLineHeight
        rowHeights[row] = rowHeight
        totalSystemHeight = totalSystemHeight + rowHeight
    end
    if systemRows > 1 then
        totalSystemHeight = totalSystemHeight + (systemRows - 1) * systemGapY
    end

    local totalSectionHeight = 0
    local allLinearSections = {}
    table.insert(allLinearSections, overviewSection)
    for _, section in ipairs(sections) do
        table.insert(allLinearSections, section)
    end

    for _, section in ipairs(allLinearSections) do
        totalSectionHeight = totalSectionHeight + (math.max(#section.lines, 1) * activeLineHeight)
    end
    totalSectionHeight = totalSectionHeight + (math.max(#allLinearSections - 1, 0) * sectionGap)
    totalSectionHeight = totalSectionHeight + sectionGap + totalSystemHeight

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
    local vehicleTypeCategory = self:getVehicleTypeCategoryLabel(vehicle)
    local headerText = string.format("%s %s | Type/Category: %s", vehicle:getFullName(), tostring(spec.year), vehicleTypeCategory)
    renderText(textStartX, currentY, activeHeaderSize, headerText)
    setTextBold(false)
    currentY = currentY - activeHeaderSize - activeLineHeight

    local function drawSection(section)
        local sectionLines = section.lines or {}
        local showTitle = section.showTitle ~= false
        if #sectionLines == 0 then
            setTextColor(1, 1, 1, 1)
            if showTitle then
                renderText(textStartX, currentY, activeNormalSize, section.title .. ":")
            end
            currentY = currentY - activeLineHeight
            return
        end

        local firstLine = sectionLines[1]
        local firstColor = firstLine.color or {1, 1, 1, 1}
        local firstSize = activeNormalSize * (firstLine.sizeScale or 1.0)
        setTextColor(firstColor[1], firstColor[2], firstColor[3], firstColor[4] or 1)
        local firstText = firstLine.text or ""
        if showTitle then
            firstText = section.title .. ": " .. firstText
        end
        renderText(textStartX, currentY, firstSize, firstText)
        currentY = currentY - activeLineHeight

        for index = 2, #sectionLines do
            local line = sectionLines[index]
            local lineText = line.text or ""
            local lineColor = line.color or {1, 1, 1, 1}
            local lineSize = activeNormalSize * (line.sizeScale or 1.0)
            setTextColor(lineColor[1], lineColor[2], lineColor[3], lineColor[4] or 1)
            renderText(textStartX, currentY, lineSize, lineText)
            currentY = currentY - activeLineHeight
        end
    end

    drawSection(overviewSection)
    currentY = currentY - sectionGap

    if #systemSections > 0 then
        local gridStartX = textStartX
        local gridAvailableWidth = panel.width - panel.padding * 2
        local cardWidth = (gridAvailableWidth - (systemColumns - 1) * systemGapX) / systemColumns
        local rowY = currentY

        for row = 1, systemRows do
            local rowHeight = rowHeights[row] or activeLineHeight
            for col = 1, systemColumns do
                local index = (row - 1) * systemColumns + col
                local section = systemSections[index]
                if section ~= nil then
                    local cardX = gridStartX + (col - 1) * (cardWidth + systemGapX)
                    local cardY = rowY
                    setTextColor(1, 1, 1, 1)
                    renderText(cardX, cardY, activeNormalSize, section.title .. ":")

                    local cardLineY = cardY - activeLineHeight
                    for _, line in ipairs(section.lines) do
                        local lineText = line.text or ""
                        local lineColor = line.color or {1, 1, 1, 1}
                        local lineSize = activeNormalSize * (line.sizeScale or 1.0)
                        setTextColor(lineColor[1], lineColor[2], lineColor[3], lineColor[4] or 1)
                        renderText(cardX + 0.003, cardLineY, lineSize, lineText)
                        cardLineY = cardLineY - activeLineHeight
                    end
                end
            end

            rowY = rowY - rowHeight
            if row < systemRows then
                rowY = rowY - systemGapY
            end
        end

        currentY = currentY - totalSystemHeight
    end

    for index, section in ipairs(sections) do
        currentY = currentY - sectionGap
        drawSection(section)
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
            workprocess = "Work Process",
            materialFlow = "Material Flow"
        }
        return names[systemKey] or tostring(systemKey)
    end

    local aliasToDebugKey = {}
    for debugKey, alias in pairs(AdvancedDamageSystem.FACTOR_STATS_ALIASES or {}) do
        aliasToDebugKey[tostring(alias)] = tostring(debugKey)
    end

    local function buildFactorExtraInfo(debugKey, dbg)
        if type(dbg) ~= "table" then
            return nil
        end

        if debugKey == "heavyLiftFactor" then
            local ratio = tonumber(dbg.heavyLiftMassRatio)
            if ratio ~= nil then
                return string.format("massRatio %.3f", ratio)
            end
        elseif debugKey == "sharpAngleFactor" then
            local angle = tonumber(dbg.ptoSharpAngleDeg)
            if angle ~= nil then
                return string.format("angle %.1fdeg", angle)
            end
        elseif debugKey == "steerLoadFactor" then
            local parts = {}
            if dbg.steerInputAbs ~= nil then
                table.insert(parts, string.format("steer %.3f", tonumber(dbg.steerInputAbs) or 0))
            end
            if dbg.steerLowSpeedFactor ~= nil then
                table.insert(parts, string.format("lowSp %.3f", tonumber(dbg.steerLowSpeedFactor) or 0))
            end
            if #parts > 0 then
                return table.concat(parts, " | ")
            end
        elseif debugKey == "brakeMassFactor" then
            local parts = {}
            if dbg.brakeMassRatio ~= nil then
                table.insert(parts, string.format("massRatio %.3f", tonumber(dbg.brakeMassRatio) or 0))
            end
            if dbg.brakePedal ~= nil then
                table.insert(parts, string.format("brake %.3f", tonumber(dbg.brakePedal) or 0))
            end
            if #parts > 0 then
                return table.concat(parts, " | ")
            end
        elseif debugKey == "vibFactor" then
            local parts = {}
            if dbg.vibSignal ~= nil then
                table.insert(parts, string.format("signal %.3f", tonumber(dbg.vibSignal) or 0))
            end
            if dbg.vibFieldMultiplier ~= nil then
                table.insert(parts, string.format("field %.3f", tonumber(dbg.vibFieldMultiplier) or 0))
            end
            if #parts > 0 then
                return table.concat(parts, " | ")
            end
        elseif debugKey == "motorLoadFactor" then
            if dbg.motorLoad ~= nil then
                return string.format("load %.3f", tonumber(dbg.motorLoad) or 0)
            end
        elseif debugKey == "airIntakeCloggingFactor" then
            if dbg.airIntakeClogging ~= nil then
                return string.format("clog %.1f%%", (tonumber(dbg.airIntakeClogging) or 0) * 100)
            end
        elseif debugKey == "coldMotorFactor" then
            local parts = {}
            if dbg.engineTemperature ~= nil then
                table.insert(parts, string.format("temp %.1fC", tonumber(dbg.engineTemperature) or 0))
            end
            if dbg.rpmLoad ~= nil then
                table.insert(parts, string.format("rpm %.3f", tonumber(dbg.rpmLoad) or 0))
            end
            if #parts > 0 then
                return table.concat(parts, " | ")
            end
        elseif debugKey == "hotMotorFactor" or debugKey == "overheatFactor" then
            if dbg.engineTemperature ~= nil then
                return string.format("temp %.1fC", tonumber(dbg.engineTemperature) or 0)
            end
        elseif debugKey == "coldShockFactor" then
            local parts = {}
            if dbg.engineTemperature ~= nil then
                table.insert(parts, string.format("temp %.1fC", tonumber(dbg.engineTemperature) or 0))
            end
            if dbg.rpmLoad ~= nil then
                table.insert(parts, string.format("rpm %.3f", tonumber(dbg.rpmLoad) or 0))
            end
            if #parts > 0 then
                return table.concat(parts, " | ")
            end
        elseif debugKey == "highCoolingFactor" then
            if dbg.thermostatState ~= nil then
                return string.format("therm %.3f", tonumber(dbg.thermostatState) or 0)
            end
        end

        return nil
    end

    local sections = {}
    local factorStatsRaw = spec.factorStats or {}
    local factorStats = {}
    for rawSystemKey, rawStats in pairs(factorStatsRaw) do
        if type(rawStats) == "table" then
            local normalizedKey = tostring(rawSystemKey)
            local loweredKey = string.lower(normalizedKey)
            if loweredKey == "workprocess" then
                normalizedKey = "workprocess"
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
        "electrical", "chassis", "fuel", "workprocess", "materialFlow"
    }

    local usedSystems = {}
    for _, systemKey in ipairs(orderedSystems) do
        local stats = factorStats[systemKey]
        if type(stats) == "table" then
            usedSystems[systemKey] = true
            local lines = {}
            local dbg = type(spec.debugData) == "table" and spec.debugData[systemKey] or nil
            local systemStressMultiplier = tonumber(ADS_Config.CORE.SYSTEM_STRESS_ACCUMULATION_MULTIPLIERS[systemKey]) or 1
            addLine(lines, string.format(
                "total: %.3f%% | stress: %.3f%%",
                toPct(stats.total),
                toPct(stats.stress)
            ), {1, 1, 1, 1}, 0.95)

            if type(dbg) == "table" then
                addLine(lines, string.format(
                    "breakdown: %.3f%% | critical: %.3f%%",
                    toPct(dbg.breakdownProbability or 0),
                    toPct(dbg.critBreakdownProbability or 0)
                ), {1, 0.92, 0.78, 1}, 0.9)
            end

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

            if #factorEntries > 0 then
                addLine(lines, "", {1, 1, 1, 1}, 0.9)
            end

            for _, entry in ipairs(factorEntries) do
                local alias = tostring(entry.key)
                local accumulatedConditionDamage = tonumber(entry.value) or 0
                local accumulatedStressDamage = accumulatedConditionDamage * systemStressMultiplier
                local debugKey = aliasToDebugKey[alias]
                local currentValue = 0
                if debugKey ~= nil and type(dbg) == "table" then
                    currentValue = tonumber(dbg[debugKey]) or 0
                end

                local lineText = string.format(
                    "%s: %.3f%% | %.3f%% | %.3f%%",
                    alias,
                    toPct(currentValue),
                    toPct(accumulatedConditionDamage),
                    toPct(accumulatedStressDamage)
                )

                local extraInfo = buildFactorExtraInfo(debugKey, dbg)
                if extraInfo ~= nil and extraInfo ~= "" then
                    lineText = lineText .. " (" .. extraInfo .. ")"
                end

                addLine(lines, lineText, {0.92, 0.96, 1.0, 1}, 0.9)
            end

            table.insert(sections, { title = getSystemTitle(systemKey), lines = lines })
        end
    end

    for systemKey, stats in pairs(factorStats) do
        if type(stats) == "table" and not usedSystems[systemKey] then
            local lines = {}
            local dbg = type(spec.debugData) == "table" and spec.debugData[systemKey] or nil
            addLine(lines, string.format(
                "total: %.3f%% | stress: %.3f%%",
                toPct(stats.total),
                toPct(stats.stress)
            ), {1, 1, 1, 1}, 0.95)
            if type(dbg) == "table" then
                addLine(lines, string.format(
                    "breakdown: %.3f%% | critical: %.3f%%",
                    toPct(dbg.breakdownProbability or 0),
                    toPct(dbg.critBreakdownProbability or 0)
                ), {1, 0.92, 0.78, 1}, 0.9)
            end
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
    local vehicleTypeCategory = self:getVehicleTypeCategoryLabel(vehicle)
    local headerText = string.format("%s %s | Type/Category: %s [Factor Stats]", vehicle:getFullName(), tostring(spec.year), vehicleTypeCategory)
    renderText(textStartX, currentY, activeHeaderSize, headerText)
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

    local maxVehicleLines = 20
    local shownVehicleCount = math.min(#vehicleLines, maxVehicleLines)
    local hiddenVehicleCount = math.max(#vehicleLines - shownVehicleCount, 0)
    local hasOverflowLine = hiddenVehicleCount > 0

    local totalLines = shownVehicleCount + 1 + (hasOverflowLine and 1 or 0)
    local dynamicHeight = (panel.padding * 2) + textSettings.headerSize + (totalLines * panel.lineHeight)
    local panelY = panel.y - dynamicHeight

    if panel.background ~= nil then
        local overlay = Overlay.new(panel.background, panel.x, panelY, panel.width, dynamicHeight)
        overlay:setColor(1, 1, 1, 0.7)
        overlay:render()
    end

    setTextColor(unpack(textSettings.color))
    
    local textStartX = panel.x + panel.padding
    local currentY = panel.y - panel.padding - 0.005

    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_TOP)
    setTextBold(true)
    renderText(textStartX, currentY, textSettings.headerSize, "ADS Monitored Vehicles")
    setTextBold(false)

    for i = 1, shownVehicleCount do
        local line = vehicleLines[i]
        currentY = currentY - panel.lineHeight
        renderText(textStartX, currentY, textSettings.normalSize, line)
    end

    if hasOverflowLine then
        currentY = currentY - panel.lineHeight
        renderText(textStartX, currentY, textSettings.normalSize, string.format("and %d more vehicles...", hiddenVehicleCount))
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
    if self.spec_AdvancedDamageSystem ~= nil and not self.spec_AdvancedDamageSystem.isExcludedVehicle then
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





