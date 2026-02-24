ADS_ReportDialog = {}
ADS_ReportDialog.INSTANCE = nil

local ADS_ReportDialog_mt = Class(ADS_ReportDialog, MessageDialog)
local modDirectory = g_currentModDirectory
local REPORT_TABLE_MIN_ROWS_MAIN = 10
local REPORT_TABLE_MIN_ROWS_BOTTOM = 4
local SUSPICIOUS_SYMPTOMS_BY_EFFECT = {
    {id = "DARK_EXHAUST_EFFECT", l10nKey = "ads_report_system_symptoms_dark_exhaust"},
    {id = "TURBOCHARGER_GRINDING_EFFECT", l10nKey = "ads_report_system_symptoms_turbo_grinding"},
    {id = "LIGHTS_FLICKER_CHANCE", l10nKey = "ads_report_system_symptoms_lights_flicker"},
    {id = "LIGHTS_FAILURE", l10nKey = "ads_report_system_symptoms_lights_failure"},
    {id = "ENGINE_STALLS_CHANCE", l10nKey = "ads_report_system_symptoms_engine_stalls"},
    {id = "ENGINE_START_FAILURE_CHANCE", l10nKey = "ads_report_system_symptoms_start_failure"},
    {id = "IDLE_HUNTING_EFFECT", l10nKey = "ads_report_system_symptoms_idle_hunting"},
    {id = "ENGINE_HESITATION_CHANCE", l10nKey = "ads_report_system_symptoms_engine_hesitation"},
    {id = "ENGINE_FAILURE", l10nKey = "ads_report_system_symptoms_engine_failure"},
    {id = "TRANSMISSION_SLIP_EFFECT", l10nKey = "ads_report_system_symptoms_transmission_slip"},
    {id = "GEAR_SHIFT_FAILURE_CHANCE", l10nKey = "ads_report_system_symptoms_gear_shift_failure"},
    {id = "GEAR_REJECTION_CHANCE", l10nKey = "ads_report_system_symptoms_gear_rejection"},
    {id = "POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT", l10nKey = "ads_report_system_symptoms_powershift_lag_harsh"},
    {id = "UNLOADING_SPEED_MODIFIER", l10nKey = "ads_report_system_symptoms_unloading_speed"}
}
local RECOMMENDATION_RULES = {
    {
        l10nKey = "ads_report_recommendation_service_due",
        check = function(vehicle, reportEntry, metrics)
            if reportEntry == nil or reportEntry.conditionData == nil then
                return false
            end
            local service = reportEntry.conditionData.service
            return type(service) == "number" and service > 0.45 and service < 0.65
        end
    },
    {
        l10nKey = "ads_report_recommendation_service_urgent",
        check = function(vehicle, reportEntry, metrics)
            if reportEntry == nil or reportEntry.conditionData == nil then
                return false
            end
            local service = reportEntry.conditionData.service
            return type(service) == "number" and service < 0.45
        end
    },
    {
        l10nKey = "ads_report_recommendation_repair_active_breakdowns",
        check = function(vehicle, reportEntry, metrics)
            if metrics == nil then
                return false
            end
            return (metrics.visibleSelectableBreakdownsCount or 0) > 0
        end
    },
    {
        l10nKey = "ads_report_recommendation_overhaul",
        check = function(vehicle, reportEntry, metrics)
            if reportEntry == nil or reportEntry.conditionData == nil then
                return false
            end
            local condition = reportEntry.conditionData.condition
            return type(condition) == "number" and condition < 0.2
        end
    },
    {
        l10nKey = "ads_report_recommendation_operating_conditions",
        check = function(vehicle, reportEntry, metrics)
            if metrics == nil or not metrics.isCompleteInspection then
                return false
            end
            local wearRate = metrics.wearRate
            local nominalWearRate = metrics.nominalWearRate
            if type(wearRate) ~= "number" or type(nominalWearRate) ~= "number" or nominalWearRate <= 0 then
                return false
            end
            return (wearRate / nominalWearRate) > 1.1
        end
    },
    {
        l10nKey = "ads_report_recommendation_repeat_maintenance",
        check = function(vehicle, reportEntry, metrics)
            if metrics == nil or not metrics.isCompleteInspection then
                return false
            end
            return metrics.hasPoorQualityConsumablesBreakdown == true
        end
    }
}

local function log_dbg(...)
    if ADS_Config and ADS_Config.DEBUG then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i])
        end
        print("[ADS_REPORT_DIALOG] " .. table.concat(args, " "))
    end
end

local function getEffectValue(activeEffects, effectId)
    local effect = activeEffects[effectId]
    if type(effect) == "table" and type(effect.value) == "number" then
        return effect.value
    end
    return nil
end

local function hasActiveEffect(activeEffects, effectId)
    local effect = activeEffects[effectId]
    if effect == nil then
        return false
    end

    if type(effect) ~= "table" then
        return true
    end

    if type(effect.value) == "number" then
        return math.abs(effect.value) > 0
    end

    return true
end

local function padRowsToCount(rows, minRows, makePaddingRow)
    while #rows < minRows do
        table.insert(rows, makePaddingRow())
    end
end

local function buildRecommendationsData(vehicle, reportEntry, metrics)
    local recommendations = {}

    for _, rule in ipairs(RECOMMENDATION_RULES) do
        if type(rule.check) == "function" then
            local ok, shouldAdd = pcall(rule.check, vehicle, reportEntry, metrics)
            if ok and shouldAdd then
                table.insert(recommendations, "- " .. g_i18n:getText(rule.l10nKey))
            end
        end
    end

    if #recommendations == 0 then
        table.insert(recommendations, "- " .. g_i18n:getText("ads_report_recommendation_all_ok"))
    end

    return recommendations
end

function ADS_ReportDialog.register()
    local dialog = ADS_ReportDialog.new()
    g_gui:loadGui(modDirectory .. "gui/ADS_ReportDialog.xml", "ADS_ReportDialog", dialog)
    ADS_ReportDialog.INSTANCE = dialog
end

function ADS_ReportDialog.new(target, customMt)
    local dialog = MessageDialog.new(target, customMt or ADS_ReportDialog_mt)
    dialog.vehicle = nil
    return dialog
end

function ADS_ReportDialog.show(vehicle, logEntry)

    if logEntry == nil or not AdvancedDamageSystem.getIsLogEntryHasReport(logEntry) then
        log_dbg("Invalid log entry")
        return
    end

    if ADS_ReportDialog.INSTANCE == nil then ADS_ReportDialog.register() end
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then return end
    
    local dialog = ADS_ReportDialog.INSTANCE
    local spec = vehicle.spec_AdvancedDamageSystem

    dialog.maintenanceLog = spec.maintenanceLog or {}
    dialog.vehicle = vehicle
    dialog.lastReport = logEntry
    dialog.isCompleteInspection = AdvancedDamageSystem.getIsCompleteReport(logEntry)

    dialog.overallAssessmentData = {}
    dialog.systemConditionData = {}
    dialog.suspiciousSymptomsData = {}
    dialog.breakdownsData = {}
    dialog.recommendationsData = {}
    
    dialog:updateScreen()
    g_gui:showDialog("ADS_ReportDialog")
end

function ADS_ReportDialog:updateScreen()
    if self.vehicle == nil then return end
    log_dbg("Updating log Screen...")
    local spec = self.vehicle.spec_AdvancedDamageSystem

    self.overallAssessmentData = {}
    self.systemConditionData = {}
    self.suspiciousSymptomsData = {}
    self.breakdownsData = {}
    self.recommendationsData = {}

    self.balanceElement:setText(g_i18n:formatMoney(g_currentMission:getMoney(), 0, true, true))

-- ==========================================================
--                          HEADER  
-- ==========================================================
    -- title
    self.reportTitle:setText(g_i18n:getText("ads_report_header_title") .. " #" .. self.lastReport.id)

    -- name
    self.vehicleNameValue:setText(self.vehicle:getFullName())

    local yearStr = "00"
    if self.lastReport.date and self.lastReport.date.year then
        if self.lastReport.date.year >= 10 then
            yearStr = tostring(self.lastReport.date.year)
        else
            yearStr = "0" .. tostring(self.lastReport.date.year)
        end
    end
    local dDay = (self.lastReport.date and self.lastReport.date.day) or 1
    local dMonth = (self.lastReport.date and self.lastReport.date.month) or 1
    local dateStr = string.format("%s %s. '%s", dDay, g_i18n:formatPeriod(dMonth, true), yearStr)
    
    self.reportDateValue:setText(dateStr)
    self.vehicleAgeValue:setText(self.lastReport.conditionData.age .. " " .. g_i18n:getText("ads_ws_age_unit"))
    self.vehicleOperatingHoursValue:setText(string.format("%.1f", self.lastReport.conditionData.operatingHours) .. " " .. g_i18n:getText("ads_ws_hours_unit"))
        

    self.inspectionTypeValue:setText(g_i18n:getText(self.lastReport.type) .. " (" .. g_i18n:getText(self.lastReport.optionOne) .. ")")

    self.inspectionLocationValue:setText(g_i18n:getText(self.lastReport.location) or "UNKNOWN")

-- ==========================================================
--                   OVERALL ASSESSMENT   
-- ==========================================================

    -- condition and service
    local condition = self.lastReport.conditionData.condition or 1.0
    local service = self.lastReport.conditionData.service or 1.0
    table.insert(self.overallAssessmentData, {'ads_report_overall_assessment_condition', condition})
    table.insert(self.overallAssessmentData, {'ads_report_overall_assessment_service', service})

    -- currentMTBF calculation
    local currentCondition = self.lastReport.conditionData.condition or 1.0
    local currentMTBF = ADS_Utils.getEstimatedMTBF(currentCondition, ADS_Config.CORE.BREAKDOWN_PROBABILITY) 
    if currentMTBF > ADS_Config.CORE.BREAKDOWN_PROBABILITY.MAX_MTBF then
        currentMTBF = ADS_Config.CORE.BREAKDOWN_PROBABILITY.MAX_MTBF
    end
    currentMTBF = currentMTBF / 60
    table.insert(self.overallAssessmentData, {'ads_report_overall_assessment_mtbf', currentMTBF})

    -- current crit failure risk
    local critFailureRisk = ADS_Utils.getCriticalFailureChance(currentCondition)
    table.insert(self.overallAssessmentData, {'ads_report_overall_assessment_crit_fail_risk', critFailureRisk})
    
    -- wear rate
    local wearRate = ADS_Config.CORE.BASE_CONDITION_WEAR
    local startOperatingTime = 0.0
    local startCondition = 1.0
    local currentOperatingTime = self.lastReport.conditionData.operatingHours or 0.0

    for i = #self.maintenanceLog, 1, -1 do
        local entry = self.maintenanceLog[i]
        if entry.id == 1 then
            startOperatingTime = entry.conditionData.operatingHours or 0
            startCondition = entry.conditionData.condition or 1.0
            break
        elseif entry.type == AdvancedDamageSystem.STATUS.OVERHAUL then
            startOperatingTime = entry.conditionData.operatingHours or 0
            startCondition = entry.conditionData.condition or 1.0
            break
        end
    end

    local operatingTimeDiff = math.max(currentOperatingTime - startOperatingTime, 0.001)
    local conditionDiff = math.max(startCondition - currentCondition, 0)

    if currentOperatingTime < 0.1 or operatingTimeDiff < 0.1 then 
        wearRate = ADS_Config.CORE.BASE_CONDITION_WEAR
    else
        wearRate = conditionDiff / operatingTimeDiff
    end

    table.insert(self.overallAssessmentData, {'ads_report_overall_assessment_wear_rate',  wearRate})

    -- nominalWearRate
    local nominalWearRate = 1 / spec.reliability / 100
    table.insert(self.overallAssessmentData, {'ads_report_overall_assessment_nominal_wear_rate', nominalWearRate})

    -- expected residual life
    local rul = currentCondition / wearRate
    table.insert(self.overallAssessmentData, {'ads_report_overall_assessment_rul', rul})

-- ==========================================================
--                   SYSTEM CONDITION   
-- ==========================================================

    local activeEffects = self.lastReport.conditionData.activeEffects or {}

    -- harvesting performance
    if ADS_Breakdowns.BreakdownRegistry.YIELD_SENSOR_MALFUNCTION.isApplicable(self.vehicle) then
        local harvestingEfficiencyModifier = 1.0
        local yieldReductionModifier = getEffectValue(activeEffects, "YIELD_REDUCTION_MODIFIER") or 0
        if yieldReductionModifier then
            harvestingEfficiencyModifier = 1.0 + yieldReductionModifier
        end
        table.insert(self.systemConditionData, {'ads_report_system_condition_harvesting', harvestingEfficiencyModifier})
    end

    -- power
    local motor = self.vehicle:getMotor()
    local defaultPower = motor.peakMotorPower * 1.36 or 0
    local engineTorqueModifier = getEffectValue(activeEffects, "ENGINE_TORQUE_MODIFIER") or 0
    local currentPowerModifier = 1.0
    if engineTorqueModifier then
        currentPowerModifier = 1.0 + engineTorqueModifier
    end
    table.insert(self.systemConditionData, {'ads_report_system_condition_power', currentPowerModifier})

    -- brakes
    local brakesPowerModifier = 1.0
    local brakeForceModifier = getEffectValue(activeEffects, "BRAKE_FORCE_MODIFIER") or 0
    if brakeForceModifier then
        brakesPowerModifier = 1.0 + brakeForceModifier
    end
    table.insert(self.systemConditionData, {'ads_report_system_condition_brakes', brakesPowerModifier})

    -- transmission
    local transmissionEfficiencyModifier = 1.0
    local transmissionSlipModifier = getEffectValue(activeEffects, "TRANSMISSION_SLIP_EFFECT") or 0
    if transmissionSlipModifier then
        transmissionEfficiencyModifier = 1.0 + transmissionSlipModifier
    end

    local transmissionGearFailureChance = getEffectValue(activeEffects, "GEAR_SHIFT_FAILURE_CHANCE") or 0
    if transmissionGearFailureChance then
        transmissionEfficiencyModifier = transmissionEfficiencyModifier * (1.0 - transmissionGearFailureChance)
    end

    local transmissionPowershiftHydraulicPumpMalfunction = getEffectValue(activeEffects, "POWERSHIFT_HYDRAULIC_PUMP_MALFUNCTION") or 0
    if transmissionPowershiftHydraulicPumpMalfunction then
        transmissionEfficiencyModifier = transmissionEfficiencyModifier * (1.0 - transmissionPowershiftHydraulicPumpMalfunction)
    end
    table.insert(self.systemConditionData, {'ads_report_system_condition_transmission', transmissionEfficiencyModifier})

    -- cooling system
    local coolingEfficiencyModifier = 1.0
    local thermostatHealthModifier = getEffectValue(activeEffects, "THERMOSTAT_HEALTH_MODIFIER") or 0
    if thermostatHealthModifier then
        coolingEfficiencyModifier = 1.0 + thermostatHealthModifier
    end
    table.insert(self.systemConditionData, {'ads_report_system_condition_cooling', coolingEfficiencyModifier})

    -- cooling system CVT
    if ADS_Breakdowns.BreakdownRegistry.CVT_THERMOSTAT_MALFUNCTION.isApplicable(self.vehicle) then
        local cvtEfficiencyModifier = 1.0
        local cvtThermostatHealthModifier = getEffectValue(activeEffects, "CVT_THERMOSTAT_HEALTH_MODIFIER") or 0
        if cvtThermostatHealthModifier then
            cvtEfficiencyModifier = 1.0 + cvtThermostatHealthModifier
        end
        table.insert(self.systemConditionData, {'ads_report_system_condition_cvt_cooling', cvtEfficiencyModifier})
    end

    -- fuel consumption
    local fuelConsumptionModifier = 1.0
    local fuelConsumptionEffectValue = getEffectValue(activeEffects, "FUEL_CONSUMPTION_MODIFIER")
    if fuelConsumptionEffectValue then
        fuelConsumptionModifier = 1.0 + fuelConsumptionEffectValue
    end
    table.insert(self.systemConditionData, {'ads_report_system_condition_consumption', fuelConsumptionModifier})


    -- hydraulic performance
    if ADS_Breakdowns.BreakdownRegistry.HYDRAULIC_PUMP_MALFUNCTION.isApplicable(self.vehicle) then
        local hydraulicEfficiencyModifier = 1.0
        local hydraulicSpeedModifier = getEffectValue(activeEffects, "HYDRAULIC_SPEED_MODIFIER") or 0
        if hydraulicSpeedModifier then
            hydraulicEfficiencyModifier = 1.0 + hydraulicSpeedModifier
        end
        table.insert(self.systemConditionData, {'ads_report_system_condition_hydraulic', hydraulicEfficiencyModifier})
    end

-- ==========================================================
--                   SUSPICIOUS_SYMPTOMS
-- ==========================================================

    for _, item in ipairs(SUSPICIOUS_SYMPTOMS_BY_EFFECT) do
        if hasActiveEffect(activeEffects, item.id) then
            table.insert(self.suspiciousSymptomsData, "- " .. g_i18n:getText(item.l10nKey))
        end
    end

    if #self.suspiciousSymptomsData == 0 then
        table.insert(self.suspiciousSymptomsData, "- " .. g_i18n:getText("ads_report_system_symptoms_none"))
    end

-- ==========================================================
--             BREAKDOWNS and RECCOMENDATIONS 
-- ==========================================================

    local reportMetrics = {
        visibleSelectableBreakdownsCount = 0,
        wearRate = wearRate,
        nominalWearRate = nominalWearRate,
        hasPoorQualityConsumablesBreakdown = false,
        isCompleteInspection = self.isCompleteInspection == true
    }

    local reportActiveBreakdowns = (self.lastReport.conditionData and self.lastReport.conditionData.activeBreakdowns) or {}
    local breakdownIds = {}
    for breakdownId, _ in pairs(reportActiveBreakdowns) do
        table.insert(breakdownIds, breakdownId)
    end
    table.sort(breakdownIds)

    for _, breakdownId in ipairs(breakdownIds) do
        local breakdownData = reportActiveBreakdowns[breakdownId]
        local registryEntry = ADS_Breakdowns.BreakdownRegistry[breakdownId]

        if breakdownId == "MAINTENANCE_WITH_POOR_QUALITY_CONSUMABLES" then
            reportMetrics.hasPoorQualityConsumablesBreakdown = true
        end

        if breakdownData ~= nil and breakdownData.isVisible and registryEntry ~= nil and registryEntry.isSelectable then
            reportMetrics.visibleSelectableBreakdownsCount = reportMetrics.visibleSelectableBreakdownsCount + 1
            local stage = breakdownData.stage or 1
            local stageData = registryEntry.stages and registryEntry.stages[stage]
            if stageData ~= nil then
                local partText = g_i18n:getText(registryEntry.part)
                local severityText = g_i18n:getText(stageData.severity)
                local descriptionText = g_i18n:getText(stageData.description)
                table.insert(self.breakdownsData, string.format("- %s (%s): %s", partText, severityText, descriptionText))
            end
        end
    end

    if #self.breakdownsData == 0 then
        table.insert(self.breakdownsData, "- " .. g_i18n:getText("ads_log_inspection_desc_no_breakdowns"))
    end

    self.recommendationsData = buildRecommendationsData(self.vehicle, self.lastReport, reportMetrics)

    padRowsToCount(self.overallAssessmentData, REPORT_TABLE_MIN_ROWS_MAIN, function()
        return {isPadding = true}
    end)
    padRowsToCount(self.systemConditionData, REPORT_TABLE_MIN_ROWS_MAIN, function()
        return {isPadding = true}
    end)
    padRowsToCount(self.suspiciousSymptomsData, REPORT_TABLE_MIN_ROWS_MAIN, function()
        return ""
    end)
    padRowsToCount(self.breakdownsData, REPORT_TABLE_MIN_ROWS_BOTTOM, function()
        return ""
    end)
    padRowsToCount(self.recommendationsData, REPORT_TABLE_MIN_ROWS_BOTTOM, function()
        return ""
    end)

    self.overallAssessmentTable:setDataSource(self)
    self.systemConditionTable:setDataSource(self)
    self.suspiciousSymptomsTable:setDataSource(self)
    self.breakdownsTable:setDataSource(self)
    self.recommendationsTable:setDataSource(self)
    self.overallAssessmentTable:reloadData()
    self.systemConditionTable:reloadData()
    self.suspiciousSymptomsTable:reloadData()
    self.breakdownsTable:reloadData()
    self.recommendationsTable:reloadData()
end

function ADS_ReportDialog:getNumberOfItemsInSection(list, section)
    if list == self.overallAssessmentTable then
        return #self.overallAssessmentData
    elseif list == self.systemConditionTable then
        return #self.systemConditionData
    elseif list == self.suspiciousSymptomsTable then
        return #self.suspiciousSymptomsData
    elseif list == self.breakdownsTable then
        return #self.breakdownsData
    elseif list == self.recommendationsTable then
        return #self.recommendationsData
    end
end

function ADS_ReportDialog:populateCellForItemInSection(list, section, index, cell)
    if list == self.overallAssessmentTable then
        self:populateOverallAssessmentCell(index, cell)
    elseif list == self.systemConditionTable then
        self:populateSystemConditionCell(index, cell)
    elseif list == self.suspiciousSymptomsTable then
        self:populateSuspiciousSymptomsCell(index, cell)
    elseif list == self.breakdownsTable then
        self:populateBreakdownsCell(index, cell)
    elseif list == self.recommendationsTable then
        self:populateRecommendationsCell(index, cell)
    end
end

function ADS_ReportDialog:populateOverallAssessmentCell(index, cell)
    local data = self.overallAssessmentData[index]
    if not data then return end

    if data.isPadding then
        local titleElement = cell:getAttribute("reportTableOverallAssessmentTitle")
        local valueElement = cell:getAttribute("reportTableOverallAssessmentValue")
        titleElement:setText("")
        valueElement:setText("")
        titleElement:setTextColor(1.0, 1.0, 1.0, 1.0)
        valueElement:setTextColor(1.0, 1.0, 1.0, 1.0)
        return
    end

    local spec = self.vehicle.spec_AdvancedDamageSystem
    local maxMtbf = ADS_Config.CORE.BREAKDOWN_PROBABILITY.MAX_MTBF / 60
    local minMtbf = ADS_Config.CORE.BREAKDOWN_PROBABILITY.MIN_MTBF / 60
    local diffMtbf = maxMtbf - minMtbf
    local minCrit = ADS_Config.CORE.BREAKDOWN_PROBABILITY.CRITICAL_MIN
    local maxCrit = ADS_Config.CORE.BREAKDOWN_PROBABILITY.CRITICAL_MAX
    local critDiff = maxCrit - minCrit
    local rel = 1 / (ADS_Config.CORE.BASE_CONDITION_WEAR / spec.reliability)
    local nominalWearRate = 1 / spec.reliability / 100

    local assessmentConfig = {
        ads_report_overall_assessment_condition =  {inverted = false, ideal = 0.8, high = 0.6, mid = 0.4, low = 0.2, stdVisible = true, isPercent = true},
        ads_report_overall_assessment_service = {inverted = false, ideal = 0.9, high = 0.65, mid = 0.55, low = 0.45, stdVisible = true, isPercent = true},
        ads_report_overall_assessment_mtbf = {inverted = false, ideal = maxMtbf, high = diffMtbf * 0.66, mid = diffMtbf * 0.33, low = minMtbf, stdVisible = false, isPercent = false},
        ads_report_overall_assessment_rul = {inverted = false, ideal = rel, high = rel * 0.66, mid = rel * 0.33, low = minMtbf, stdVisible = false, isPercent = false},
        ads_report_overall_assessment_wear_rate = {inverted = true, ideal = nominalWearRate, high = nominalWearRate * 1.1, mid = nominalWearRate * 1.2, low = nominalWearRate * 1.3, stdVisible = false, isPercent = true},
        ads_report_overall_assessment_nominal_wear_rate = {inverted = true, ideal = nominalWearRate, high = nominalWearRate * 1.1, mid = nominalWearRate * 1.2, low = nominalWearRate * 1.3, stdVisible = false, isPercent = true},
        ads_report_overall_assessment_crit_fail_risk = {inverted = true, ideal = minCrit, high = critDiff * 0.33, mid = critDiff * 0.66, low = maxCrit * 1.3, stdVisible = false, isPercent = true},
    }
    local defaultConfig = {inverted = false, ideal = 100, high = 95, mid = 90, low = 70, stdVisible = false, isPercent = true}

    local key = data[1]
    local cfg = assessmentConfig[key] or defaultConfig
    local val = data[2]

    local function getColor(smooth)
        if not cfg.stdVisible and not self.isCompleteInspection then
            return 0.5, 0.5, 0.5, 1.0
        end
        if cfg.inverted then
            return ADS_Utils.getValueColorInverted(val, cfg.ideal, cfg.low, cfg.mid, cfg.high, smooth)
        else
            return ADS_Utils.getValueColor(val, cfg.ideal, cfg.high, cfg.mid, cfg.low, smooth)
        end
    end
    
    cell:getAttribute("reportTableOverallAssessmentTitle"):setText(g_i18n:getText(key))
    local valueElement = cell:getAttribute("reportTableOverallAssessmentValue")

    if self.isCompleteInspection then
        cell:getAttribute("reportTableOverallAssessmentTitle"):setTextColor(1.0, 1.0, 1.0, 1.0)
        if cfg.isPercent then
            valueElement:setText(string.format("%.2f %%", val * 100))
        else
            valueElement:setText(string.format("%.1f", val))
        end
        valueElement:setTextColor(getColor(true))
    else
        if not cfg.stdVisible then cell:getAttribute("reportTableOverallAssessmentTitle"):setTextColor(0.5, 0.5, 0.5, 1.0) end
        local conditionStateTexts = {
            g_i18n:getText("ads_spec_state_excellent"),
            g_i18n:getText("ads_spec_state_good"),
            g_i18n:getText("ads_spec_state_normal"),
            g_i18n:getText("ads_spec_state_bad"),
            g_i18n:getText("ads_spec_state_terrible")
        }

        local serviceStateTexts = {
            g_i18n:getText("ads_spec_state_optimal"),
            g_i18n:getText("ads_spec_state_good"),
            g_i18n:getText("ads_spec_state_recommended"),
            g_i18n:getText("ads_spec_state_required"),
            g_i18n:getText("ads_spec_state_overdue")
        }

        if cfg.stdVisible then
            if key == 'ads_report_overall_assessment_condition' then
                valueElement:setText(ADS_Utils.getValueLabel(val, cfg.ideal, cfg.high, cfg.mid, cfg.low, table.unpack(conditionStateTexts)))
            elseif key == 'ads_report_overall_assessment_service' then
                 valueElement:setText(ADS_Utils.getValueLabel(val, cfg.ideal, cfg.high, cfg.mid, cfg.low, table.unpack(serviceStateTexts)))
            end
        else
            valueElement:setText(g_i18n:getText('ads_report_state_not_available'))
        end
        valueElement:setTextColor(getColor(false))
    end

end

function ADS_ReportDialog:populateSystemConditionCell(index, cell)
    local data = self.systemConditionData[index]
    if not data then return end

    if data.isPadding then
        local titleElement = cell:getAttribute("reportTableSystemConditionTitle")
        local valueElement = cell:getAttribute("reportTableSystemConditionValue")
        titleElement:setText("")
        valueElement:setText("")
        titleElement:setTextColor(1.0, 1.0, 1.0, 1.0)
        valueElement:setTextColor(1.0, 1.0, 1.0, 1.0)
        return
    end

    local conditionConfig = {
        ads_report_system_condition_consumption = {inverted = true, ideal = 100, low = 105, mid = 110, high = 130, stdVisible = false},
        ads_report_system_condition_power = {inverted = false, ideal = 100, high = 95, mid = 90, low = 70, stdVisible = true},
        ads_report_system_condition_brakes = {inverted = false, ideal = 100, high = 95, mid = 90, low = 70, stdVisible = true},
        ads_report_system_condition_harvest = {inverted = false, ideal = 100, high = 95, mid = 90, low = 70, stdVisible = true}
    }
    local defaultConfig = {inverted = false, ideal = 100, high = 95, mid = 90, low = 70, stdVisible = false}

    local key = data[1]
    local cfg = conditionConfig[key] or defaultConfig
    local val = data[2] * 100

    local function getColor(smooth)
        if not cfg.stdVisible and not self.isCompleteInspection then
            return 0.5, 0.5, 0.5, 1.0
        end
        if cfg.inverted then
            return ADS_Utils.getValueColorInverted(val, cfg.ideal, cfg.low, cfg.mid, cfg.high, smooth)
        else
            return ADS_Utils.getValueColor(val, cfg.ideal, cfg.high, cfg.mid, cfg.low, smooth)
        end
    end

    cell:getAttribute("reportTableSystemConditionTitle"):setText(g_i18n:getText(key))
    

    local valueElement = cell:getAttribute("reportTableSystemConditionValue")

    if self.isCompleteInspection then
        cell:getAttribute("reportTableSystemConditionTitle"):setTextColor(1.0, 1.0, 1.0, 1.0)
        valueElement:setText(string.format("%.1f %%", val))
        valueElement:setTextColor(getColor(true))
    else
        if not cfg.stdVisible then cell:getAttribute("reportTableSystemConditionTitle"):setTextColor(0.5, 0.5, 0.5, 1.0) end
        local stateTexts = {
            g_i18n:getText("ads_report_state_optimal"),
            g_i18n:getText("ads_report_state_normal"),
            g_i18n:getText("ads_report_state_degraded"),
            g_i18n:getText("ads_report_state_impaired"),
            g_i18n:getText("ads_report_state_critical")
        }

        if cfg.stdVisible then
            if cfg.inverted then
                valueElement:setText(ADS_Utils.getValueLabelInverted(val, cfg.ideal, cfg.low, cfg.mid, cfg.high, table.unpack(stateTexts)))
            else
                valueElement:setText(ADS_Utils.getValueLabel(val, cfg.ideal, cfg.high, cfg.mid, cfg.low, table.unpack(stateTexts)))
            end
        else
            valueElement:setText(g_i18n:getText('ads_report_state_not_available'))
        end
        valueElement:setTextColor(getColor(false))
    end
end

function ADS_ReportDialog:populateSuspiciousSymptomsCell(index, cell)
    local data = self.suspiciousSymptomsData[index]
    cell:getAttribute("reportTableSuspiciousSymptomsTitle"):setText(data or "")
end

function ADS_ReportDialog:populateBreakdownsCell(index, cell)
    local data = self.breakdownsData[index]
    cell:getAttribute("reportBreakdownsRow"):setText(data or "")
end

function ADS_ReportDialog:populateRecommendationsCell(index, cell)
    local data = self.recommendationsData[index]
    cell:getAttribute("reportRecRow"):setText(data or "")
end

-- ====================================================================
-- CALLBACKS & EVENTS
-- ====================================================================

function ADS_ReportDialog:onClickBack()
    self:close()
end

function ADS_ReportDialog:onOpen(superFunc)
    g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.updateScreen, self)
end

function ADS_ReportDialog:onClose(superFunc)
    self.vehicle = nil
    g_messageCenter:unsubscribeAll(self)
end
