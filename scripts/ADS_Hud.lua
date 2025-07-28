ADS_Hud = {}
ADS_Hud.modDirectory = g_currentModDirectory
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

    self.indicators.battery.offsetX, self.indicators.battery.offsetY = self:scalePixelValuesToScreenVector(-45, -30)
    local batteryWidth, batteryHeight = self:scalePixelValuesToScreenVector(19, 19)
    self.indicators.battery.icon:setDimension(batteryWidth, batteryHeight)

    self.indicators.oil.offsetX, self.indicators.oil.offsetY = self:scalePixelValuesToScreenVector(22, -30)
    local oilWidth, oilHeight = self:scalePixelValuesToScreenVector(19, 19)
    self.indicators.oil.icon:setDimension(oilWidth, oilHeight)

    self.indicators.engine.offsetX, self.indicators.engine.offsetY = self:scalePixelValuesToScreenVector(-50, -11)
    local engineWidth, engineHeight = self:scalePixelValuesToScreenVector(16, 16)
    self.indicators.engine.icon:setDimension(engineWidth, engineHeight)

    self.indicators.transmission.offsetX, self.indicators.transmission.offsetY = self:scalePixelValuesToScreenVector(30, -14)
    local transmissionWidth, transmissionHeight = self:scalePixelValuesToScreenVector(19, 19)
    self.indicators.transmission.icon:setDimension(transmissionWidth, transmissionHeight)

    self.indicators.brakes.offsetX, self.indicators.brakes.offsetY = self:scalePixelValuesToScreenVector(-47, 5)
    local brakesWidth, brakesHeight = self:scalePixelValuesToScreenVector(19, 19)
    self.indicators.brakes.icon:setDimension(brakesWidth, brakesHeight)

    self.indicators.warning.offsetX, self.indicators.warning.offsetY = self:scalePixelValuesToScreenVector(25, 7)
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

            if hudIndicatorId == self.indicators.service.name and spec.serviceLevel < 0.333 then targetColor = colors.WARNING end
            if hudIndicatorId == self.indicators.oil.name and spec.serviceLevel < 0.2 then targetColor = colors.WARNING end
        else
            local activeData = activeIndicators[hudIndicatorId]
            if activeData then
                activeData.isActive = false
            end
        end

        icon:setColor(unpack(targetColor))
        icon:setPosition(posX + hudIndicatorData.offsetX, posY + hudIndicatorData.offsetY)
        icon:setVisible(hudIndicatorData.year < spec.year)
        icon:render()
        end

    local engineTemp, transTemp = spec.engineTemperature, spec.transmissionTemperature
    local tempSign = "°C"

    if g_gameSettings:getValue(GameSettings.SETTING.USE_FAHRENHEIT) then
        engineTemp = engineTemp * 1.8 + 32
        transTemp = transTemp * 1.8 + 32
        tempSign = "°F"
    end

    local tempText = ""

    if transTemp > -90 and spec.year >= self.tsTempText.year then
        tempText = string.format("%.0f%s | %.0f%s", engineTemp, tempSign, transTemp, tempSign)
    else
        tempText = string.format("%.1f%s", engineTemp, tempSign)
    end

    setTextColor(1, 1, 1, 1)
	setTextAlignment(RenderText.ALIGN_CENTER)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_TOP)
	setTextBold(true)

    renderText(posX + self.engineTempText.offsetX, posY + self.engineTempText.offsetY, self.engineTempText.size, tempText)

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

    local panel = self.activeVehicleDebugPanel
    local textSettings = self.text

    local breakdownLines = {}
    if spec.activeBreakdowns and next(spec.activeBreakdowns) ~= nil then
        for id, breakdown in pairs(spec.activeBreakdowns) do
            local visible = breakdown.isVisible and "V" or "-"
            local selected = breakdown.isSelectedForRepair and "S" or "-"
            table.insert(breakdownLines, string.format("%s [S%d] P:%.0fs [%s|%s]", id, breakdown.stage, breakdown.progressTimer / 1000, visible, selected))
        end
    else
        table.insert(breakdownLines, "None")
    end

    local effectLines = {}
    if spec.activeEffects and next(spec.activeEffects) ~= nil then
        for id, effect in pairs(spec.activeEffects) do
            table.insert(effectLines, string.format("%s: %.2f", id, effect.value))
        end
    else
        table.insert(effectLines, "None")
    end

    local baseLines = 12
    local dynamicHeight = (panel.padding * 2) + textSettings.headerSize + (baseLines * panel.lineHeight) + (#breakdownLines * panel.lineHeight) + (#effectLines * panel.lineHeight) + 0.04


    if panel.background ~= nil then
        local overlay = Overlay.new(panel.background, panel.x, panel.y, panel.width, dynamicHeight)
        overlay:setColor(1, 1, 1, 0.7)
        overlay:render()
    end
    
    local textStartX = panel.x + panel.padding
    local textEndX = panel.x + panel.width - panel.padding
    local currentY = panel.y + dynamicHeight - panel.padding

    setTextBold(true)
    renderText(textStartX, currentY, textSettings.headerSize, vehicle:getFullName() .. " " .. spec.year)
    setTextBold(false)
    currentY = currentY - textSettings.headerSize - 0.01
    currentY = currentY - panel.lineHeight
    

    local function drawValueWithColorHigh(value)
        setTextColor(1, math.max(1 - value, 0.1), math.max(1 - value, 0.1), 1)
    end

    local function drawTemp(temp)
        if temp > 105 then setTextColor(1, 0.6, 0.6, 1)
        elseif temp > 95 then setTextColor(1, 1, 0.6, 1)
        else setTextColor(0.6, 0.8, 1, 1) end
    end

    local col1_x = textStartX
    local col2_x = textStartX + (panel.width * 0.33)
    local col3_x = textStartX + (panel.width * 0.66)
    local col4_x = textStartX + panel.width
    local startY = currentY

    local bcw = ADS_Config.CORE.BASE_CONDITION_WEAR * 100
    local bsw = ADS_Config.CORE.BASE_SERVICE_WEAR * 100

    -- COLUMN 1
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    renderText(col1_x, currentY, textSettings.normalSize, string.format("STATUS"))
    setTextBold(false)
    currentY = currentY - panel.lineHeight

    renderText(col1_x, currentY, textSettings.normalSize, string.format("Reliability/Maintainability:"))
    renderText(col2_x - 0.07, currentY, textSettings.normalSize, string.format("%.2f / %.2f", spec.reliability, spec.maintainability))
    renderText(col2_x - 0.01, currentY, textSettings.normalSize, "|")
    currentY = currentY - panel.lineHeight   

    renderText(col1_x, currentY, textSettings.normalSize, string.format("Service:"))
    renderText(col2_x - 0.07, currentY, textSettings.normalSize, string.format("%.2f%% (-%.2f%%)", spec.serviceLevel * 100, spec.debugData.service.totalWearRate * bsw))
    renderText(col2_x - 0.01, currentY, textSettings.normalSize, "|")
    currentY = currentY - panel.lineHeight   

    renderText(col1_x, currentY, textSettings.normalSize, string.format("Condtion:"))
    renderText(col2_x - 0.07, currentY, textSettings.normalSize, string.format("%.2f%% (-%.2f%%)", spec.conditionLevel * 100, spec.debugData.condition.totalWearRate * bcw))
    renderText(col2_x - 0.01, currentY, textSettings.normalSize, "|")
    currentY = currentY - panel.lineHeight   



    local col1_titles = { '  Motor overload factor', '  Service expired factor', '  Cold motor factor', '  Overheat motor factor', '  Overheat CVT factor'}
    local col1_data = {
        spec.debugData.condition.motorLoadFactor * bcw,
        spec.debugData.condition.expiredServiceFactor * bcw,
        spec.debugData.condition.coldMotorFactor * bcw,
        spec.debugData.condition.hotMotorFactor * bcw,
        spec.debugData.condition.hotTransFactor * bcw
    }

    for index , title in ipairs(col1_titles) do
        renderText(col1_x, currentY, textSettings.normalSize * 0.9, string.format("%s:", title))
        drawValueWithColorHigh(col1_data[index], 0.01, 1, true)
        renderText(col2_x - 0.07, currentY, textSettings.normalSize, string.format("-%.2f%%", col1_data[index]))
        setTextColor(1, 1, 1, 1)
        renderText(col2_x - 0.01, currentY, textSettings.normalSize * 0.9, "|")
        currentY = currentY - panel.lineHeight
    end
    
    renderText(col1_x, currentY, textSettings.normalSize, string.format("Failure chance:"))
    renderText(col2_x - 0.07, currentY, textSettings.normalSize, string.format("%.2f%% (%.2f%%)", spec.debugData.breakdown.failureChanceInHour * 100, spec.debugData.breakdown.criticalFailureInHour * 100))
    renderText(col2_x - 0.01, currentY, textSettings.normalSize, "|")
    currentY = currentY - panel.lineHeight
    

    -- COLUMN 2
    currentY = startY
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    renderText(col2_x, currentY, textSettings.normalSize, "THERMALS")
    setTextBold(false)
    currentY = currentY - panel.lineHeight

    renderText(col2_x, currentY, textSettings.normalSize, "Engine:")
    drawTemp(spec.engineTemperature)
    renderText(col3_x - 0.07, currentY, textSettings.normalSize, string.format("%.2f°C", spec.engineTemperature))
    setTextColor(1, 1, 1, 1)
    renderText(col3_x - 0.01, currentY, textSettings.normalSize, "|")
    currentY = currentY - panel.lineHeight
    
    setTextColor(1, 1, 1, 1)
    renderText(col2_x, currentY, textSettings.normalSize, string.format(" T-stat:"))
    renderText(col3_x - 0.07, currentY, textSettings.normalSize * 0.9, string.format("%.0f%%", spec.thermostatState * 100))
    setTextColor(1, 1, 1, 1)
    renderText(col3_x - 0.01, currentY, textSettings.normalSize, "|")
    currentY = currentY - panel.lineHeight

    setTextColor(1, 1, 1, 1)
    renderText(col2_x, currentY, textSettings.normalSize, string.format(" Total heat:"))
    renderText(col3_x - 0.07, currentY, textSettings.normalSize * 0.9, string.format("%.0f%%",  spec.debugData.engineTemp.totalHeat * 100))
    setTextColor(1, 1, 1, 1)
    renderText(col3_x - 0.01, currentY, textSettings.normalSize, "|")
    currentY = currentY - panel.lineHeight

    setTextColor(1, 1, 1, 1)
    renderText(col2_x, currentY, textSettings.normalSize, string.format(" Total cooling:"))
    renderText(col3_x - 0.07, currentY, textSettings.normalSize * 0.9, string.format("%.0f%% (%.0f%% | %.0f%% | %.0f%%)",  spec.debugData.engineTemp.totalCooling * 100, spec.debugData.engineTemp.radiatorCooling * 100, spec.debugData.engineTemp.speedCooling * 100, spec.debugData.engineTemp.convectionCooling * 100))
    setTextColor(1, 1, 1, 1)
    renderText(col3_x - 0.01, currentY, textSettings.normalSize, "|")
    currentY = currentY - panel.lineHeight


    if spec.transmissionTemperature > -30 and spec.year >= 2000 then
        renderText(col2_x, currentY, textSettings.normalSize, "Transmission:")
        drawTemp(spec.transmissionTemperature)
        renderText(col3_x - 0.07, currentY, textSettings.normalSize, string.format("%.2f°C", spec.transmissionTemperature))
        setTextColor(1, 1, 1, 1)
        renderText(col3_x - 0.01, currentY, textSettings.normalSize, "|")
        currentY = currentY - panel.lineHeight
        
        setTextColor(1, 1, 1, 1)
        renderText(col2_x, currentY, textSettings.normalSize, string.format(" T-stat:"))
        renderText(col3_x - 0.07, currentY, textSettings.normalSize * 0.9, string.format("%.0f%%", spec.transmissionThermostatState * 100))
        setTextColor(1, 1, 1, 1)
        renderText(col3_x - 0.01, currentY, textSettings.normalSize, "|")
        currentY = currentY - panel.lineHeight

        setTextColor(1, 1, 1, 1)
        renderText(col2_x, currentY, textSettings.normalSize, string.format(" Total heat:"))
        renderText(col3_x - 0.07, currentY, textSettings.normalSize * 0.9, string.format("%.0f%% | %.2f | %.2f | %.2f",  spec.debugData.transmissionTemp.totalHeat * 100, spec.debugData.transmissionTemp.loadFactor, spec.debugData.transmissionTemp.slipFactor, spec.debugData.transmissionTemp.accFactor))
        setTextColor(1, 1, 1, 1)
        renderText(col3_x - 0.01, currentY, textSettings.normalSize, "|")
        currentY = currentY - panel.lineHeight

        setTextColor(1, 1, 1, 1)
        renderText(col2_x, currentY, textSettings.normalSize, string.format(" Total cooling:"))
        renderText(col3_x - 0.07, currentY, textSettings.normalSize * 0.9, string.format("%.0f%% (%.0f%% | %.0f%% | %.0f%%)",  spec.debugData.transmissionTemp.totalCooling * 100, spec.debugData.transmissionTemp.radiatorCooling * 100, spec.debugData.transmissionTemp.speedCooling * 100, spec.debugData.transmissionTemp.convectionCooling * 100))
        setTextColor(1, 1, 1, 1)
        renderText(col3_x - 0.01, currentY, textSettings.normalSize, "|")
        currentY = currentY - panel.lineHeight
    end
    
    -- COLUMN 3
    currentY = startY
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    renderText(col3_x, currentY, textSettings.normalSize, "DRIVETRAIN")
    setTextBold(false)
    currentY = currentY - panel.lineHeight

    local motorPower = motor:getMotorRotSpeed() * (motor:getMotorAvailableTorque() - motor:getMotorExternalTorque()) * 1000
    renderText(col3_x, currentY, textSettings.normalSize, string.format("Power:"))
    renderText(col4_x - 0.07, currentY, textSettings.normalSize, string.format("%d hp / %d hp", motorPower / 735.5, motor.peakMotorPower * 1.36 or 0))
    currentY = currentY - panel.lineHeight

    renderText(col3_x, currentY, textSettings.normalSize, string.format("Load:"))
    renderText(col4_x - 0.07, currentY, textSettings.normalSize, string.format("%.0f%%", vehicle:getMotorLoadPercentage() * 100))
    currentY = currentY - panel.lineHeight

    renderText(col3_x, currentY, textSettings.normalSize, string.format("Gear:"))
    renderText(col4_x - 0.07, currentY, textSettings.normalSize, string.format("%d -> %d (%d, %1.2f)", motor.gear, motor.targetGear * motor.currentDirection, motor.activeGearGroupIndex or 0, motor:getGearRatio()))
    currentY = currentY - panel.lineHeight

    renderText(col3_x, currentY, textSettings.normalSize, string.format("Fuel:"))
    renderText(col4_x - 0.07, currentY, textSettings.normalSize, string.format("%.2fl/h", vehicle.spec_motorized.lastFuelUsage or 0))
    currentY = currentY - panel.lineHeight

    renderText(col3_x, currentY, textSettings.normalSize, string.format("Damage/Dirt:"))
    renderText(col4_x - 0.07, currentY, textSettings.normalSize, string.format("%.2f%% / %.2f%%", vehicle:getDamageAmount() * 100, vehicle:getDirtAmount() * 100))
    currentY = currentY - panel.lineHeight

    renderText(col3_x, currentY, textSettings.normalSize, string.format("State/Workshop:"))
    renderText(col4_x - 0.07, currentY, textSettings.normalSize, string.format("%s / %s", g_i18n:getText(spec.currentState), spec.workshopType))
    currentY = currentY - panel.lineHeight

    renderText(col3_x, currentY, textSettings.normalSize, string.format("Timer:"))
    renderText(col4_x - 0.07, currentY, textSettings.normalSize, string.format("%0.f s", spec.maintenanceTimer / 1000))
    currentY = currentY - panel.lineHeight

    -- BOTTOM
    
    currentY = startY - (9 * panel.lineHeight) 

    local separator = "________________________________________________________________________________________________________________________________________________________________"
    local function drawSeparator()
        currentY = currentY - (panel.lineHeight * 0.8)
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(textStartX, currentY, textSettings.normalSize, separator)
        currentY = currentY - (panel.lineHeight * 0.2)
    end

    drawSeparator()

    currentY = currentY - panel.lineHeight

    setTextColor(1, 1, 1, 1)
    renderText(textStartX, currentY, textSettings.normalSize, "Active Breakdowns:")
    currentY = currentY - panel.lineHeight
    setTextColor(1, 0.8, 0.8, 1) -- Светло-красный для поломок
    for _, line in ipairs(breakdownLines) do
        renderText(textStartX + 0.01, currentY, textSettings.normalSize, line)
        currentY = currentY - panel.lineHeight
    end

    setTextColor(1, 1, 1, 1)
    renderText(textStartX, currentY, textSettings.normalSize, "Active Effects:")
    currentY = currentY - panel.lineHeight
    setTextColor(0.8, 0.8, 1, 1) -- Светло-синий для эффектов
    for _, line in ipairs(effectLines) do
        renderText(textStartX + 0.01, currentY, textSettings.normalSize, line)
        currentY = currentY - panel.lineHeight
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
        if implement:getIsSelected() and implement:getDamageShowOnHud() then
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
        
        box:addLine(g_i18n:getText('ads_ws_label_condition'), g_i18n:getText(spec.lastInspectedConditionState))
        box:addLine(g_i18n:getText("ads_ws_label_last_inspection"), self:getFormattedLastInspectionText())
        box:addLine(g_i18n:getText("ads_ws_label_last_maintenance"), self:getFormattedLastMaintenanceText())
        box:addLine(g_i18n:getText("ads_ws_label_service_interval"), self:getFormattedServiceIntervalText())

        
        if spec.currentState ~= AdvancedDamageSystem.STATUS.READY and spec.currentState ~= AdvancedDamageSystem.STATUS.BROKEN then
            local maintenanceStatusText = string.format(g_i18n:getText("ads_spec_last_maintenance_until_format"), g_i18n:getText(spec.currentState), self:getFormattedMaintenanceFinishTimeText())
            box:addLine(maintenanceStatusText)
        end
    end
end

Vehicle.showInfo = Utils.appendedFunction(Vehicle.showInfo, ADS_Hud.showInfoVehicle)




