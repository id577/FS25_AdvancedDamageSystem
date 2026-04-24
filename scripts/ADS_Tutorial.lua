ADS_Tutorial = {}
ADS_Tutorial.modDirectory = g_currentModDirectory
ADS_Tutorial.vehicle = nil
ADS_Tutorial.timer = 0
ADS_Tutorial.messageDowntime = 3000

local downtimeAfterMessage = 60000

function ADS_Tutorial:showMessage(text, doPause, downtime)
    local mission = g_currentMission
    if mission == nil then
        return
    end

    if doPause then
        if mission.setManualPause ~= nil then
            mission:setManualPause(true)
        elseif mission.pauseGame ~= nil then
            mission:pauseGame()
        end
    end

    ADS_WelcomeDialog.show(text, function(_, disableTutorial)
        if g_currentMission == nil then
            return
        end

        if disableTutorial then
            ADS_Config.TUTORIAL_MODE = false
        end

        if doPause then
            if g_currentMission.setManualPause ~= nil then
                g_currentMission:setManualPause(false)
            elseif g_currentMission.tryUnpauseGame ~= nil then
                g_currentMission:tryUnpauseGame()
            end
        end
    end, self)
    self.messageDowntime = downtime
end

function ADS_Tutorial:getADSVehicle()
    local vehicle = g_localPlayer.getCurrentVehicle() 
    if vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil and not vehicle.spec_AdvancedDamageSystem.isExcludedVehicle then
        self.vehicle = vehicle
    end
end

function ADS_Tutorial:update(dt)
    self.timer = self.timer + dt
    self.messageDowntime = math.max(self.messageDowntime - dt, 0)

    if self.timer < ADS_Config.TUTORIAL_UPDATE_DELAY then
        return
    end

    local mission = g_currentMission
    local isSingleplayer = mission ~= nil
        and mission.missionDynamicInfo ~= nil
        and not mission.missionDynamicInfo.isMultiplayer

    self:getADSVehicle()

    local spec = self.vehicle ~= nil and self.vehicle.spec_AdvancedDamageSystem or nil


    local messagedData = ADS_Config.TUTORIAL_MESSAGES
    
    if ADS_Config.TUTORIAL_MODE and isSingleplayer and self.messageDowntime <= 0 then

        --- GLOBAL MESSAGES
        if not messagedData.WELCOME then
            self:showMessage(g_i18n:getText("ads_tutorial_welcome_message"), false, 5000)
            messagedData.WELCOME = true
        end

        --- VEHICLE MESSAGES
        if self.vehicle ~= nil and spec ~= nil then
            local vehicle = self.vehicle
            local isMotorStarted = vehicle:getIsMotorStarted()
            local speed = vehicle:getLastSpeed()
            local vehicleMass = vehicle.getTotalMass ~= nil and (vehicle:getTotalMass(true) or 0) or 0
            local heavyLiftMassRatio = vehicleMass > 0 and (spec.liftedMass / vehicleMass) or 0
            local heavyLiftThreshold = ADS_Config.CORE.HYDRAULICS_FACTOR_DATA.HEAVY_LIFT_FACTOR_THRESHOLD or 0
            local ptoAngleDeg = tonumber(spec.maxConnectedPtoAngleDeg or 0) or 0
            local hasConnectedPto = spec.hasConnectedPto == true
            local sharpAngleThreshold = ADS_Config.CORE.HYDRAULICS_FACTOR_DATA.PTO_SHARP_ANGLE_FACTOR_THRESHOLD or 30
            local preventiveRiskSystem = nil
            local hasPoorPartsBreakdown = false

            if not messagedData.NEEDS_PREVENTIVE and spec.systems ~= nil then
                for _, systemData in pairs(spec.systems) do
                    if type(systemData) == "table"
                        and systemData.enabled == true
                        and systemData.condition ~= nil
                        and systemData.stress ~= nil then
                        local condition = math.max(tonumber(systemData.condition or 0) or 0, 0.001)
                        local stress = tonumber(systemData.stress or 0) or 0

                        if stress / condition > 0.7 then
                            preventiveRiskSystem = systemData
                            break
                        end
                    end
                end
            end

            if not messagedData.POOR_PARTS and spec.activeBreakdowns ~= nil then
                for breakdownId, breakdown in pairs(spec.activeBreakdowns) do
                    local breakdownDef = ADS_Breakdowns.BreakdownRegistry[breakdownId]

                    if breakdownDef ~= nil
                        and breakdownDef.isSelectable == true
                        and breakdown ~= nil
                        and breakdown.isActive == false
                        and breakdown.source == AdvancedDamageSystem.BREAKDOWN_SOURCES.POOR_PARTS then
                        hasPoorPartsBreakdown = true
                        break
                    end
                end
            end

            if sharpAngleThreshold <= (2 * math.pi + 0.001) then
                sharpAngleThreshold = math.deg(sharpAngleThreshold)
            end

            -- ==========================================================
            -- SERVICE
            -- ==========================================================
            --- service due soon
            if not messagedData.SERVICE_DUE_SOON and vehicle:getHoursSinceLastMaintenance() / vehicle:getMaintenanceInterval() >= 0.9 then
                ADS_Hud.showNotification(
                    string.format(g_i18n:getText("ads_tutorial_service_due_soon_message"), vehicle:getFullName()),
                    0,
                    g_i18n:getText("ads_tutorial_service_due_soon_title"),
                    true
                )
                messagedData.SERVICE_DUE_SOON = true
                self.messageDowntime = downtimeAfterMessage

            --- needs repair
            elseif not messagedData.NEEDS_REPAIR and isMotorStarted and vehicle:hasBreakdown() then
                ADS_Hud.showNotification(
                    string.format(g_i18n:getText("ads_tutorial_needs_repair_message"), vehicle:getFullName()),
                    0,
                    g_i18n:getText("ads_tutorial_needs_repair_title"),
                    true
                )
                messagedData.NEEDS_REPAIR = true
                self.messageDowntime = downtimeAfterMessage

            elseif not messagedData.NEEDS_OVERHAUL and vehicle:getConditionLevel() < 0.19 then
                ADS_Hud.showNotification(
                    string.format(g_i18n:getText("ads_tutorial_needs_overhaul_message"), vehicle:getFullName()),
                    0,
                    g_i18n:getText("ads_tutorial_needs_overhaul_title"),
                    true
                )
                messagedData.NEEDS_OVERHAUL = true
                self.messageDowntime = downtimeAfterMessage

            elseif not messagedData.NEEDS_PREVENTIVE
                and isMotorStarted
                and preventiveRiskSystem ~= nil then
                ADS_Hud.showNotification(
                    string.format(g_i18n:getText("ads_tutorial_needs_preventive_message"), vehicle:getFullName()),
                    0,
                    g_i18n:getText("ads_tutorial_needs_preventive_title"),
                    true
                )
                messagedData.NEEDS_PREVENTIVE = true
                self.messageDowntime = downtimeAfterMessage

            --- poor consumables
            elseif not messagedData.POOR_CONSUMABLES and vehicle:hasBreakdown("MAINTENANCE_WITH_POOR_QUALITY_CONSUMABLES") then
                ADS_Hud.showNotification(
                    string.format(g_i18n:getText("ads_tutorial_poor_consumables_message"), vehicle:getFullName()),
                    0,
                    g_i18n:getText("ads_tutorial_poor_consumables_title"),
                    true
                )
                messagedData.POOR_CONSUMABLES = true
                self.messageDowntime = downtimeAfterMessage

            --- poor parts
            elseif not messagedData.POOR_PARTS and hasPoorPartsBreakdown then
                ADS_Hud.showNotification(
                    string.format(g_i18n:getText("ads_tutorial_poor_parts_message"), vehicle:getFullName()),
                    0,
                    g_i18n:getText("ads_tutorial_poor_parts_title"),
                    true
                )
                messagedData.POOR_PARTS = true
                self.messageDowntime = downtimeAfterMessage

            --- idle and downtime
            elseif not messagedData.IDLE_AND_DOWNTIME and isMotorStarted and spec.fuelState.idleTimer > 30 then
                ADS_Hud.showNotification(
                    g_i18n:getText("ads_tutorial_idle_and_downtime_message"),
                    0,
                    g_i18n:getText("ads_tutorial_idle_and_downtime_title"),
                    true
                )
                messagedData.IDLE_AND_DOWNTIME = true
                self.messageDowntime = downtimeAfterMessage

            --- hot weather
            elseif not messagedData.HOT_WEATHER
                and g_currentMission ~= nil
                and g_currentMission.environment ~= nil
                and g_currentMission.environment.weather ~= nil
                and g_currentMission.environment.weather.forecast ~= nil
                and g_currentMission.environment.weather.forecast:getCurrentWeather() ~= nil
                and g_currentMission.environment.weather.forecast:getCurrentWeather().temperature ~= nil
                and g_currentMission.environment.weather.forecast:getCurrentWeather().temperature > 30 then
                ADS_Hud.showNotification(
                    g_i18n:getText("ads_tutorial_hot_weather_message"),
                    0,
                    g_i18n:getText("ads_tutorial_hot_weather_title"),
                    true
                )
                messagedData.HOT_WEATHER = true
                self.messageDowntime = downtimeAfterMessage

            --- wet weather
            elseif not messagedData.WET_WEATHER
                and (
                    ADS_Main.currentWeather == WeatherType.RAIN
                    or ADS_Main.currentWeather == WeatherType.SNOW
                    or (WeatherType.HAIL ~= nil and ADS_Main.currentWeather == WeatherType.HAIL)
                    or (WeatherType.HALL ~= nil and ADS_Main.currentWeather == WeatherType.HALL)
                ) then
                ADS_Hud.showNotification(
                    g_i18n:getText("ads_tutorial_wet_weather_message"),
                    0,
                    g_i18n:getText("ads_tutorial_wet_weather_title"),
                    true
                )
                messagedData.WET_WEATHER = true
                self.messageDowntime = downtimeAfterMessage

            -- ==========================================================
            -- FIELD CARE
            -- ==========================================================
            elseif not messagedData.RAD_OR_INTAKE_CLOGGED and spec.isVehicleNeedBlowOut and (spec.radiatorClogging >= 0.75 or spec.airIntakeClogging >= 0.75) then
                ADS_Hud.showNotification(
                    g_i18n:getText("ads_tutorial_rad_or_intake_clogged_message"),
                    0,
                    g_i18n:getText("ads_tutorial_rad_or_intake_clogged_title"),
                    true
                )
                messagedData.RAD_OR_INTAKE_CLOGGED = true
                self.messageDowntime = downtimeAfterMessage

            --- needs lubrication
            elseif not messagedData.NEEDS_LUBRICATION and spec.isVehicleNeedLubricate and spec.lubricationLevel <= 0.8 then
                -- self:showMessage(string.format(g_i18n:getText("ads_tutorial_needs_lubrication"), vehicle:getFullName()), true)
                ADS_Hud.showNotification(
                    string.format(g_i18n:getText("ads_tutorial_needs_lubrication_message"), vehicle:getFullName()),
                    0,
                    g_i18n:getText("ads_tutorial_needs_lubrication_title"),
                    true
                )
                messagedData.NEEDS_LUBRICATION = true
                self.messageDowntime = downtimeAfterMessage
            
            -- ==========================================================
            -- ENGINE
            -- ==========================================================
            --- engine overheat
            elseif not messagedData.ENGINE_OVERHEAT and isMotorStarted and spec.engineTemperature > 100 and not spec.isElectricVehicle then
                ADS_Hud.showNotification(
                    g_i18n:getText("ads_tutorial_engine_overheat_message"),
                    0,
                    g_i18n:getText("ads_tutorial_engine_overheat_title"),
                    true
                )
                messagedData.ENGINE_OVERHEAT = true
                messagedData.CVT_OVERHEAT = true
                self.messageDowntime = downtimeAfterMessage

            --- cold engine
            elseif not messagedData.COLD_ENGINE and spec.engineTemperature < 40 and isMotorStarted and speed < 1 and not spec.isElectricVehicle then
                ADS_Hud.showNotification(
                    g_i18n:getText("ads_tutorial_cold_engine_message"),
                    0,
                    g_i18n:getText("ads_tutorial_cold_engine_title"),
                    true
                )
                messagedData.COLD_ENGINE = true
                self.messageDowntime = downtimeAfterMessage

            --- engine overload
            elseif not messagedData.ENGINE_OVERLOAD and isMotorStarted and spec.dynamicMotorLoad >= 1.15 and not spec.isElectricVehicle then
                ADS_Hud.showNotification(
                    g_i18n:getText("ads_tutorial_engine_overload_message"),
                    0,
                    g_i18n:getText("ads_tutorial_engine_overload_title"),
                    true
                )
                messagedData.ENGINE_OVERLOAD = true
                self.messageDowntime = downtimeAfterMessage

            --- lugging
            elseif not messagedData.LUGGING and spec.luggingTutorialTimer ~= nil and spec.luggingTutorialTimer >= 5000 and not spec.isElectricVehicle then
                ADS_Hud.showNotification(  
                    g_i18n:getText("ads_tutorial_lugging_message"),
                    0,
                    g_i18n:getText("ads_tutorial_lugging_title"),
                    true
                )
                messagedData.LUGGING = true
                self.messageDowntime = downtimeAfterMessage

            -- ==========================================================
            -- TRANSMISSION
            -- ==========================================================
            --- cvt overheat
            elseif not messagedData.CVT_OVERHEAT and isMotorStarted and spec.transmissionTemperature > 100 and not spec.isElectricVehicle then
                ADS_Hud.showNotification(
                    g_i18n:getText("ads_tutorial_cvt_overheat_message"),
                    0,
                    g_i18n:getText("ads_tutorial_cvt_overheat_title"),
                    true
                )
                messagedData.CVT_OVERHEAT = true
                messagedData.ENGINE_OVERHEAT = true
                self.messageDowntime = downtimeAfterMessage

            --- heavy trailer
            elseif not messagedData.HEAVY_TRAILER and isMotorStarted and speed > 5 and spec.chassisBrakeState ~= nil and spec.chassisBrakeState.hpMassRatio ~= nil and spec.chassisBrakeState.hpMassRatio <= 8 then
                ADS_Hud.showNotification(
                    g_i18n:getText("ads_tutorial_heavy_trailer_message"),
                    0,
                    g_i18n:getText("ads_tutorial_heavy_trailer_title"),
                    true
                )
                messagedData.HEAVY_TRAILER = true
                self.messageDowntime = downtimeAfterMessage

            --- wheel slip
            elseif not messagedData.WHEEL_SLIP and isMotorStarted and spec.wheelSlipIntensity > 0.9 and spec.wheelSlipTutorialTimer >= 3000 then
                ADS_Hud.showNotification(
                    g_i18n:getText("ads_tutorial_wheel_slip_message"),
                    0,
                    g_i18n:getText("ads_tutorial_wheel_slip_title"),
                    true
                )
                messagedData.WHEEL_SLIP = true
                self.messageDowntime = downtimeAfterMessage

            -- ==========================================================
            -- CHASSIS
            -- ==========================================================
            --- chassis vibration
            elseif not messagedData.CHASSIS_VIBRATION and isMotorStarted and speed > 40 and vehicle:getIsOnField() then
                ADS_Hud.showNotification(
                    string.format(g_i18n:getText("ads_tutorial_chassis_vibration_message"), vehicle:getFullName()),
                    0,
                    g_i18n:getText("ads_tutorial_chassis_vibration_title"),
                    true
                )
                messagedData.CHASSIS_VIBRATION = true
                self.messageDowntime = downtimeAfterMessage

            --- steering
            elseif not messagedData.STEERING
                and isMotorStarted
                and speed <= 0.1
                and spec.chassisSteerState ~= nil
                and (tonumber(spec.chassisSteerState.groundContact or 0) or 0) > 0
                and spec.chassisSteerState.isMoving == true then
                ADS_Hud.showNotification(
                    g_i18n:getText("ads_tutorial_steering_message"),
                    0,
                    g_i18n:getText("ads_tutorial_steering_title"),
                    true
                )
                messagedData.STEERING = true
                self.messageDowntime = downtimeAfterMessage

            -- ==========================================================
            -- ELECTRICAL
            -- ========================================================== 
            --- cranking`
            elseif not messagedData.CRANKING
                and spec.systems.electrical.enabled
                and not spec.isElectricVehicle
                and spec.systems.electrical.crankingTimer ~= nil
                and spec.systems.electrical.crankingTimer >= 9000 then
                ADS_Hud.showNotification(
                    g_i18n:getText("ads_tutorial_cranking_message"),
                    0,
                    g_i18n:getText("ads_tutorial_cranking_title"),
                    true
                )
                messagedData.CRANKING = true
                self.messageDowntime = downtimeAfterMessage

            --- battery low
            elseif not messagedData.BATTERY_LOW
                and spec.systems.electrical.enabled
                and not isMotorStarted
                and not spec.isCranking
                and (tonumber(spec.systemVoltageV or 0) or 0) < 12.0 then
                ADS_Hud.showNotification(
                    g_i18n:getText("ads_tutorial_battery_low_message"),
                    0,
                    g_i18n:getText("ads_tutorial_battery_low_title"),
                    true
                )
                messagedData.BATTERY_LOW = true
                messagedData.HARD_START = true
                self.messageDowntime = downtimeAfterMessage

            --- hard start
            elseif not messagedData.HARD_START
                and vehicle:hasEffect("ENGINE_HARD_START_MODIFIER")
                and not isMotorStarted then
                ADS_Hud.showNotification(
                    string.format(g_i18n:getText("ads_tutorial_hard_start_message"), vehicle:getFullName()),
                    0,
                    g_i18n:getText("ads_tutorial_hard_start_title"),
                    true
                )
                messagedData.HARD_START = true
                self.messageDowntime = downtimeAfterMessage

            --- critical failure
            elseif not messagedData.CRITICAL_FAILURE
                and vehicle:hasEffect("ENGINE_FAILURE") then
                ADS_Hud.showNotification(
                    string.format(g_i18n:getText("ads_tutorial_critical_failure_message"), vehicle:getFullName()),
                    0,
                    g_i18n:getText("ads_tutorial_critical_failure_title"),
                    true
                )
                messagedData.CRITICAL_FAILURE = true
                self.messageDowntime = downtimeAfterMessage

            -- ==========================================================
            -- FUEL
            -- ==========================================================
            --- low fuel
            elseif not messagedData.LOW_FUEL
                and isMotorStarted
                and not spec.isElectricVehicle
                and spec.fuelState ~= nil
                and (tonumber(spec.fuelState.level or 0) or 0) < (ADS_Config.CORE.FUEL_FACTOR_DATA.LOW_FUEL_THRESHOLD or 0.20) then
                ADS_Hud.showNotification(
                    g_i18n:getText("ads_tutorial_low_fuel_message"),
                    0,
                    g_i18n:getText("ads_tutorial_low_fuel_title"),
                    true
                )
                messagedData.LOW_FUEL = true
                self.messageDowntime = downtimeAfterMessage

            --- idle deposit
            elseif not messagedData.IDLE_DEPOSIT
                and isMotorStarted
                and not spec.isElectricVehicle
                and spec.fuelState ~= nil
                and (tonumber(spec.fuelState.idleTimer or 0) or 0) >= 120 then
                ADS_Hud.showNotification(
                    g_i18n:getText("ads_tutorial_idle_deposit_message"),
                    0,
                    g_i18n:getText("ads_tutorial_idle_deposit_title"),
                    true
                )
                messagedData.IDLE_DEPOSIT = true
                self.messageDowntime = downtimeAfterMessage

            -- ==========================================================
            -- HYDRAULIC
            -- ========================================================== 
            --- heavy lift
            elseif not messagedData.HEAVY_LIFT and isMotorStarted and heavyLiftMassRatio > heavyLiftThreshold then
                ADS_Hud.showNotification(
                    string.format(g_i18n:getText("ads_tutorial_heavy_lift_message"), vehicle:getFullName()),
                    0,
                    g_i18n:getText("ads_tutorial_heavy_lift_title"),
                    true
                )
                messagedData.HEAVY_LIFT = true
                self.messageDowntime = downtimeAfterMessage

            --- pto sharp angle
            elseif not messagedData.PTO_SHARP_ANGLE
                and isMotorStarted
                and spec.isPtoActive
                and hasConnectedPto
                and ptoAngleDeg > sharpAngleThreshold
                and not spec.isExcludedFromPTOSharpAngleFactor then
                ADS_Hud.showNotification(
                    g_i18n:getText("ads_tutorial_pto_sharp_angle_message"),
                    0,
                    g_i18n:getText("ads_tutorial_pto_sharp_angle_title"),
                    true
                )
                messagedData.PTO_SHARP_ANGLE = true
                self.messageDowntime = downtimeAfterMessage
            end
        end
    end

    self.timer = self.timer - ADS_Config.TUTORIAL_UPDATE_DELAY
end

addModEventListener(ADS_Tutorial)
