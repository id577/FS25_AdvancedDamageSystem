ADS_ReportDialog = {}
ADS_ReportDialog.INSTANCE = nil

local ADS_ReportDialog_mt = Class(ADS_ReportDialog, MessageDialog)
local modDirectory = g_currentModDirectory
local REPORT_TABLE_MIN_ROWS_MAIN = 10
local REPORT_TABLE_MIN_ROWS_BOTTOM = 4
local getSystemDisplayName
local formatRecommendationText
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
            return (metrics.visibleSelectableActiveBreakdownsCount or 0) > 0
        end
    },
    {
        l10nKey = "ads_report_recommendation_defective_parts",
        check = function(vehicle, reportEntry, metrics)
            if metrics == nil then
                return false
            end

            local partsText = joinRecommendationParts(metrics.inactivePoorPartsNames)
            if partsText ~= nil then
                return {
                    params = {partsText}
                }
            end

            return false
        end
    },
    {
        l10nKey = "ads_report_recommendation_quick_fix",
        check = function(vehicle, reportEntry, metrics)
            if metrics == nil then
                return false
            end

            local partsText = joinRecommendationParts(metrics.inactiveQuickFixPartsNames)
            if partsText ~= nil then
                return {
                    params = {partsText}
                }
            end

            return false
        end
    },
    {
        l10nKey = "ads_report_recommendation_overhaul",
        check = function(vehicle, reportEntry, metrics)
            if reportEntry == nil or reportEntry.conditionData == nil then
                return false
            end
            local condition = reportEntry.conditionData.condition
            return type(condition) == "number" and condition < 0.4
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
            return (wearRate / nominalWearRate) > 1.3
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
    },
    {
        l10nKey = "ads_report_recommendation_system_overhaul",
        check = function(vehicle, reportEntry, metrics)
            if reportEntry == nil or reportEntry.conditionData == nil then
                return false
            end

            local overallCondition = tonumber(reportEntry.conditionData.condition)
            if overallCondition ~= nil and overallCondition <= 0.4 then
                return false
            end

            local minCond = 1.0
            local targetSystemKey = nil
            local systems = reportEntry.conditionData.systems or {}

            for systemName, systemData in pairs(systems) do
                if type(systemData) == "table" and systemData.enabled ~= false then
                    local systemCondition = tonumber(systemData.condition)
                    if systemCondition ~= nil and systemCondition < 0.4 and systemCondition < minCond then
                        minCond = systemCondition
                        targetSystemKey = systemName
                    end
                end
            end

            if targetSystemKey ~= nil then
                return {
                    params = {getSystemDisplayName(targetSystemKey)}
                }
            end

            return false
        end
    },
    {
        l10nKey = "ads_report_recommendation_system_preventive_maintenance",
        check = function(vehicle, reportEntry, metrics)
            if reportEntry == nil or reportEntry.conditionData == nil or metrics == nil or not metrics.isCompleteInspection then
                return false
            end

            local overallCondition = tonumber(reportEntry.conditionData.condition)
            if overallCondition ~= nil and overallCondition <= 0.4 then
                return false
            end

            local highestRelativeStress = 0
            local targetSystemKey = nil
            local systems = reportEntry.conditionData.systems or {}

            for systemName, systemData in pairs(systems) do
                if type(systemData) == "table" and systemData.enabled ~= false then
                    local systemCondition = math.max(tonumber(systemData.condition) or 0, 0.001)
                    local systemStress = math.max(tonumber(systemData.stress) or 0, 0)
                    local relativeStress = systemStress / systemCondition

                    if systemCondition >= 0.4 and relativeStress > 0.8 and relativeStress > highestRelativeStress then
                        highestRelativeStress = relativeStress
                        targetSystemKey = systemName
                    end
                end
            end

            if targetSystemKey ~= nil then
                return {
                    params = {getSystemDisplayName(targetSystemKey)}
                }
            end

            return false
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

local function getTextOrFallback(key, fallback)
    local text = g_i18n:getText(key)
    if text == nil or text == "" or text == key then
        return fallback
    end
    return text
end

function getSystemDisplayName(systemKey)
    local normalizedKey = string.lower(tostring(systemKey or ""))

    for enumKey, l10nKey in pairs(AdvancedDamageSystem.SYSTEMS or {}) do
        if type(enumKey) == "string" and string.lower(enumKey) == normalizedKey then
            return getTextOrFallback(l10nKey, tostring(systemKey))
        end
    end

    return tostring(systemKey or "")
end

function formatRecommendationText(l10nKey, params, fallback)
    local template = getTextOrFallback(l10nKey, fallback or l10nKey)
    if type(params) == "table" and #params > 0 then
        local ok, formattedText = pcall(string.format, template, table.unpack(params))
        if ok and formattedText ~= nil and formattedText ~= "" then
            return formattedText
        end
    end

    return template
end

local function getEffectValue(activeEffects, effectId)
    local effect = activeEffects[effectId]
    if type(effect) == "table" and type(effect.value) == "number" then
        return effect.value
    end
    return nil
end

local function getStressLabel(stress, condition)
    local safeCondition = math.max(tonumber(condition) or 0, 0.001)
    local normalizedStress = math.max(math.min((tonumber(stress) or 0.0) / safeCondition, 1.0), 0.0)

    if normalizedStress < ADS_Config.CORE.BREAKDOWN_PROBABILITIES.STRESS_THRESHOLD then
        return getTextOrFallback("ads_report_stress_absent", "Absent")
    elseif normalizedStress < 0.4 then
        return getTextOrFallback("ads_report_stress_low", "Low")
    elseif normalizedStress < 0.6 then
        return getTextOrFallback("ads_report_stress_moderate", "Moderate")
    elseif normalizedStress < 0.8 then
        return getTextOrFallback("ads_report_stress_elevated", "Elevated")
    else
        return getTextOrFallback("ads_report_stress_high", "High")
    end
end

local function clampUnitRatio(value)
    return math.max(math.min(tonumber(value) or 0, 1), 0)
end

local function getTransmissionEffectValue(activeEffects, effectId)
    local effect = activeEffects ~= nil and activeEffects[effectId] or nil
    if type(effect) == "table" and type(effect.value) == "number" then
        return effect.value
    end
    return nil
end

local function padRowsToCount(rows, minRows, makePaddingRow)
    while #rows < minRows do
        table.insert(rows, makePaddingRow())
    end
end

local function appendUniqueText(list, seen, value)
    if value == nil or value == "" or seen[value] then
        return
    end

    seen[value] = true
    table.insert(list, value)
end

local function joinRecommendationParts(parts)
    if type(parts) ~= "table" or #parts == 0 then
        return nil
    end

    table.sort(parts)
    return table.concat(parts, ", ")
end

local function buildRecommendationsData(vehicle, reportEntry, metrics)
    local recommendations = {}

    for _, rule in ipairs(RECOMMENDATION_RULES) do
        if type(rule.check) == "function" then
            local ok, result = pcall(rule.check, vehicle, reportEntry, metrics)
            if ok and result then
                local recommendationText = nil

                if result == true then
                    recommendationText = formatRecommendationText(rule.l10nKey)
                elseif type(result) == "table" then
                    recommendationText = formatRecommendationText(
                        result.l10nKey or rule.l10nKey,
                        result.params,
                        result.fallback
                    )
                end

                if recommendationText ~= nil and recommendationText ~= "" then
                    table.insert(recommendations, "- " .. recommendationText)
                end
            end
        end
    end

    if #recommendations == 0 then
        table.insert(recommendations, "- " .. formatRecommendationText("ads_report_recommendation_all_ok"))
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
    dialog.vehicleSpecData = {}
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
    self.vehicleSpecData = {}
    self.breakdownsData = {}
    self.recommendationsData = {}

    local balanceText = g_i18n:formatMoney(g_currentMission:getMoney(), 0, true, true)
    self.balanceElement:setText(balanceText)
    ADS_Utils.updateMoneyBoxLayout(
        self.balanceTitleElement,
        self.balanceElement,
        self.moneyBox,
        self.moneyBoxBg,
        g_i18n:getText("ui_balance"),
        balanceText
    )

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
    local systems = self.lastReport.conditionData.systems or {}
    local lowestCondition = 1.0
    local minMTBF = ADS_Config.CORE.BREAKDOWN_PROBABILITIES.MAX_MTBF
    local totalCurrentSystemCondition = 0.0
    local enabledSystemsCount = 0
    for _, systemData in pairs(systems) do
        if systemData.enabled ~= false then
            local systemCondition = math.max(math.min(systemData.condition or 1.0, 1.0), 0.0)
            local mtbf = ADS_Utils.getEstimatedMTBF(systemCondition, systemData.stress)
            minMTBF = (mtbf < minMTBF and mtbf) or minMTBF
            lowestCondition = (systemCondition < lowestCondition and systemCondition) or lowestCondition
            totalCurrentSystemCondition = totalCurrentSystemCondition + systemCondition
            enabledSystemsCount = enabledSystemsCount + 1
        end
    end

    local currentCondition = enabledSystemsCount > 0 and (totalCurrentSystemCondition / enabledSystemsCount) or condition

    minMTBF = minMTBF / 60
    table.insert(self.overallAssessmentData, {'ads_report_overall_assessment_mtbf', minMTBF})

    -- current crit failure risk
    local critFailureRisk = ADS_Utils.getCriticalFailureChance(lowestCondition)
    table.insert(self.overallAssessmentData, {'ads_report_overall_assessment_crit_fail_risk', critFailureRisk})
    
    -- wear rate
    local wearRate = ADS_Config.CORE.BASE_SYSTEMS_WEAR
    local startOperatingTime = 0.0
    local startCondition = 1.0
    local startSystems = nil
    local currentOperatingTime = self.lastReport.conditionData.operatingHours or 0.0
    local systemWearRates = {}

    for i = #self.maintenanceLog, 1, -1 do
        local entry = self.maintenanceLog[i]
        if entry.id == 1 then
            startOperatingTime = entry.conditionData.operatingHours or 0
            startCondition = entry.conditionData.condition or 1.0
            startSystems = entry.conditionData.systems or {}
            break
        elseif entry.type == AdvancedDamageSystem.STATUS.OVERHAUL then
            startOperatingTime = entry.conditionData.operatingHours or 0
            startCondition = entry.conditionData.condition or 1.0
            startSystems = entry.conditionData.systems or {}
            break
        end
    end

    local operatingTimeDiff = math.max(currentOperatingTime - startOperatingTime, 0.001)

    if currentOperatingTime < 0.1 or operatingTimeDiff < 0.1 then 
        wearRate = ADS_Config.CORE.BASE_SYSTEMS_WEAR
    else
        local totalWearRate = 0.0
        local wearRateSystemsCount = 0

        for systemKey, systemData in pairs(systems) do
            if systemData.enabled ~= false then
                local currentSystemCondition = math.max(math.min(systemData.condition or 1.0, 1.0), 0.0)
                local startSystemData = startSystems ~= nil and startSystems[systemKey] or nil
                local startSystemCondition = startCondition

                if type(startSystemData) == "table" then
                    startSystemCondition = math.max(math.min(startSystemData.condition or startCondition, 1.0), 0.0)
                elseif type(startSystemData) == "number" then
                    startSystemCondition = math.max(math.min(startSystemData, 1.0), 0.0)
                end

                local conditionDiff = math.max(startSystemCondition - currentSystemCondition, 0.0)
                local systemWearRate = conditionDiff / operatingTimeDiff
                systemWearRates[systemKey] = systemWearRate
                totalWearRate = totalWearRate + systemWearRate
                wearRateSystemsCount = wearRateSystemsCount + 1
            end
        end

        if wearRateSystemsCount > 0 then
            wearRate = totalWearRate / wearRateSystemsCount
        else
            wearRate = ADS_Config.CORE.BASE_SYSTEMS_WEAR
        end
    end

    table.insert(self.overallAssessmentData, {'ads_report_overall_assessment_wear_rate',  wearRate})

    -- nominalWearRate
    local nominalWearRate = 1 / spec.reliability / 100
    table.insert(self.overallAssessmentData, {'ads_report_overall_assessment_nominal_wear_rate', nominalWearRate})

    -- expected residual life
    local rul = 0
    local targetCondition = ADS_Config.CORE.GENERAL_WEAR_EARLY_STAGE_THRESHOLD or 0.66
    local minSystemRUL = math.huge
    local hasValidRUL = false

    for systemKey, systemData in pairs(systems) do
        if systemData.enabled ~= false then
            local currentSystemCondition = math.max(math.min(systemData.condition or 1.0, 1.0), 0.0)
            local remainingCondition = math.max(currentSystemCondition - targetCondition, 0.0)
            local systemWearRate = systemWearRates[systemKey]

            if type(systemWearRate) ~= "number" or systemWearRate <= 0 then
                systemWearRate = nominalWearRate
            end

            if systemWearRate > 0 then
                local systemRUL = remainingCondition / systemWearRate
                if systemRUL < minSystemRUL then
                    minSystemRUL = systemRUL
                end
                hasValidRUL = true
            end
        end
    end

    if hasValidRUL then
        rul = minSystemRUL
    else
        local remainingCondition = math.max(currentCondition - targetCondition, 0.0)
        rul = nominalWearRate > 0 and (remainingCondition / nominalWearRate) or 0
    end

    table.insert(self.overallAssessmentData, {'ads_report_overall_assessment_rul', rul})

-- ==========================================================
--                   SYSTEM CONDITION   
-- ==========================================================

    local systemOrder = {
        "ENGINE",
        "TRANSMISSION",
        "HYDRAULICS",
        "COOLING",
        "ELECTRICAL",
        "CHASSIS",
        "WORKPROCESS",
        "FUEL"
    }

    for _, systemEnumKey in ipairs(systemOrder) do
        local systemKey = string.lower(systemEnumKey)
        local systemData = systems[systemKey]
        if type(systemData) == "table" and systemData.enabled ~= false then
            local systemCondition = math.max(math.min(systemData.condition or 1.0, 1.0), 0.0)
            local systemStress = math.max(math.min(systemData.stress or 0.0, 1.0), 0.0)
            table.insert(self.systemConditionData, {AdvancedDamageSystem.SYSTEMS[systemEnumKey], systemCondition, systemStress})
        end
    end

-- ==========================================================
--                      VEHICLE SPECS
-- ==========================================================

    local activeEffects = self.lastReport.conditionData.activeEffects or {}
    local nominalBatteryCapacityAh = ADS_Config.ELECTRICAL.BATTART_NOMINAL_CAPACITY or 0
    local batterySoc = clampUnitRatio(self.lastReport.conditionData.batterySoc or 1)
    local batteryHealth = clampUnitRatio(1.0 + (getEffectValue(activeEffects, "BATTERY_HEALTH_MODIFIER") or 0))
    local alternatorHealth = clampUnitRatio(1.0 + (getEffectValue(activeEffects, "ALTERNATOR_HEALTH_MODIFIER") or 0))
    local thermostatHealth = clampUnitRatio(1.0 + (getEffectValue(activeEffects, "THERMOSTAT_HEALTH_MODIFIER") or 0))
    local radiatorHealth = clampUnitRatio(1.0 + (getEffectValue(activeEffects, "RADIATOR_HEALTH_MODIFIER") or 0))
    local fanClutchHealth = clampUnitRatio(1.0 + (getEffectValue(activeEffects, "FAN_CLUTCH_MODIFIER") or 0))

    local function addVehicleSpec(data)
        table.insert(self.vehicleSpecData, data)
    end

    --- harvest efficiency
    if ADS_Breakdowns.BreakdownRegistry.HARVEST_PROCESSING_SYSTEM_WEAR.isApplicable(self.vehicle) then
        local harvestingEfficiencyModifier = 1.0
        local yieldReductionModifier = getEffectValue(activeEffects, "YIELD_REDUCTION_MODIFIER") or 0
        harvestingEfficiencyModifier = harvestingEfficiencyModifier + yieldReductionModifier
        addVehicleSpec({
            key = "ads_report_system_condition_harvest",
            kind = "ratio",
            value = harvestingEfficiencyModifier,
            stdVisible = true
        })
    end

    --- power
    local motor = self.vehicle:getMotor()
    local peakPowerHp = ((motor ~= nil and motor.peakMotorPower) or 0) * 1.36
    local currentPowerModifier = 1.0 + (getEffectValue(activeEffects, "ENGINE_TORQUE_MODIFIER") or 0)
    local currentPowerHp = math.max(peakPowerHp * currentPowerModifier, 0)
    addVehicleSpec({
        key = "ads_report_system_condition_power",
        kind = "pair",
        currentValue = currentPowerHp,
        nominalValue = peakPowerHp,
        ratio = peakPowerHp > 0 and (currentPowerHp / peakPowerHp) or 1.0,
        unit = "hp",
        stdVisible = true
    })

    --- brakes
    local brakesPowerModifier = 1.0 + (getEffectValue(activeEffects, "BRAKE_FORCE_MODIFIER") or 0)
    addVehicleSpec({
        key = "ads_report_system_condition_brakes",
        kind = "ratio",
        value = brakesPowerModifier,
        stdVisible = true
    })

    local function addTransmissionTextSpec(titleKey, textKey, ratio)
        addVehicleSpec({
            key = titleKey,
            kind = "text",
            textKey = textKey,
            ratio = clampUnitRatio(ratio),
            stdVisible = false
        })
    end

    addVehicleSpec({
        key = "ads_report_vehicle_spec_battery_charge",
        kind = "ratio",
        value = batterySoc,
        stdVisible = true
    })

    --- transmission 
    local hasTransmissionIssues = false

    local transmissionSlipValue = getTransmissionEffectValue(activeEffects, "TRANSMISSION_SLIP_EFFECT")
    if transmissionSlipValue ~= nil and not hasTransmissionIssues then
        hasTransmissionIssues = true
        addTransmissionTextSpec(
            "ads_report_system_condition_transmission",
            transmissionSlipValue >= 1.0 and "ads_report_transmission_failed" or "ads_report_transmission_slipping",
            1.0 - transmissionSlipValue
        )
    end

    local gearShiftFailureValue = getTransmissionEffectValue(activeEffects, "GEAR_SHIFT_FAILURE_CHANCE")
    if gearShiftFailureValue ~= nil and not hasTransmissionIssues then
        hasTransmissionIssues = true
        addTransmissionTextSpec(
            "ads_report_system_condition_transmission",
            gearShiftFailureValue >= 1.0 and "ads_report_transmission_failed" or "ads_report_transmission_shifting_impaired",
            1.0 - gearShiftFailureValue
        )
    end

    local gearRejectionValue = getTransmissionEffectValue(activeEffects, "GEAR_REJECTION_CHANCE")
    if gearRejectionValue ~= nil and not hasTransmissionIssues then
        hasTransmissionIssues = true
        addTransmissionTextSpec(
            "ads_report_system_condition_transmission",
            gearRejectionValue <= 3.0 and "ads_report_transmission_failed" or "ads_report_transmission_gear_rejection",
            gearRejectionValue / 20.0
        )
    end

    local powershiftLagValue = getTransmissionEffectValue(activeEffects, "POWERSHIFT_ENGAGEMENT_LAG_AND_HARSH_EFFECT")
    if powershiftLagValue ~= nil and not hasTransmissionIssues then
        hasTransmissionIssues = true
        addTransmissionTextSpec(
            "ads_report_system_condition_transmission",
            powershiftLagValue >= 1.0 and "ads_report_transmission_failed" or "ads_report_transmission_shift_delay",
            1.0 - powershiftLagValue
        )
    end

    local cvtSlipValue = getTransmissionEffectValue(activeEffects, "CVT_SLIP_EFFECT")
    if cvtSlipValue ~= nil and not hasTransmissionIssues then
        hasTransmissionIssues = true
        addTransmissionTextSpec(
            "ads_report_system_condition_transmission",
            cvtSlipValue >= 1.0 and "ads_report_transmission_failed" or "ads_report_transmission_cvt_slipping",
            1.0 - cvtSlipValue
        )
    end

    local cvtRatioLimitValue = getTransmissionEffectValue(activeEffects, "CVT_MAX_RATIO_MODIFIER")
    if cvtRatioLimitValue ~= nil and not hasTransmissionIssues then
        hasTransmissionIssues = true
        addTransmissionTextSpec(
            "ads_report_system_condition_transmission",
            cvtRatioLimitValue >= 0.8 and "ads_report_transmission_failed" or "ads_report_transmission_cvt_ratio_limited",
            1.0 - cvtRatioLimitValue
        )
    end

    local cvtPressureDropValue = getTransmissionEffectValue(activeEffects, "CVT_PRESSURE_DROP_CHANCE")
    if cvtPressureDropValue ~= nil and not hasTransmissionIssues then
        hasTransmissionIssues = true
        addTransmissionTextSpec(
            "ads_report_system_condition_transmission",
            cvtPressureDropValue <= 0.1 and "ads_report_transmission_failed" or "ads_report_transmission_cvt_pressure_instability",
            cvtPressureDropValue / 2.0
        )
    end

    if not hasTransmissionIssues then
        addTransmissionTextSpec(
            "ads_report_system_condition_transmission",
            "ads_report_state_optimal",
            1.0
        )
    end

    local coolingEfficiencyModifier = math.min(thermostatHealth, radiatorHealth, fanClutchHealth)
    addVehicleSpec({
        key = "ads_report_system_condition_cooling",
        kind = "ratio",
        value = coolingEfficiencyModifier,
        stdVisible = false
    })

    local fuelConsumptionModifier = 1.0 + (getEffectValue(activeEffects, "FUEL_CONSUMPTION_MODIFIER") or 0)
    addVehicleSpec({
        key = "ads_report_system_condition_consumption",
        kind = "ratio",
        value = fuelConsumptionModifier,
        stdVisible = false,
        inverted = true,
        ideal = 100,
        low = 105,
        mid = 110,
        high = 130
    })

    if ADS_Breakdowns.BreakdownRegistry.HYDRAULIC_PUMP_MALFUNCTION.isApplicable(self.vehicle) then
        local hydraulicEfficiencyModifier = 1.0 + (getEffectValue(activeEffects, "HYDRAULIC_SPEED_MODIFIER") or 0)
        addVehicleSpec({
            key = "ads_report_system_condition_hydraulic",
            kind = "ratio",
            value = hydraulicEfficiencyModifier,
            stdVisible = false
        })
    end

    local nominalAlternatorCurrent = ADS_Config.ELECTRICAL.ALT_MAX_OUTPUT or 0
    local currentAlternatorCurrent = nominalAlternatorCurrent * alternatorHealth
    addVehicleSpec({
        key = "ads_report_vehicle_spec_max_alternator_current",
        kind = "pair",
        currentValue = currentAlternatorCurrent,
        nominalValue = nominalAlternatorCurrent,
        ratio = nominalAlternatorCurrent > 0 and (currentAlternatorCurrent / nominalAlternatorCurrent) or 1.0,
        unit = "A",
        stdVisible = false
    })

    local effectiveBatteryCapacityAh = nominalBatteryCapacityAh * batteryHealth
    addVehicleSpec({
        key = "ads_report_vehicle_spec_battery_capacity",
        kind = "pair",
        currentValue = effectiveBatteryCapacityAh,
        nominalValue = nominalBatteryCapacityAh,
        ratio = nominalBatteryCapacityAh > 0 and (effectiveBatteryCapacityAh / nominalBatteryCapacityAh) or batteryHealth,
        unit = "Ah",
        stdVisible = false
    })

-- ==========================================================
--             BREAKDOWNS and RECCOMENDATIONS 
-- ==========================================================

    local reportMetrics = {
        visibleSelectableBreakdownsCount = 0,
        visibleSelectableActiveBreakdownsCount = 0,
        wearRate = wearRate,
        nominalWearRate = nominalWearRate,
        hasPoorQualityConsumablesBreakdown = false,
        isCompleteInspection = self.isCompleteInspection == true,
        inactivePoorPartsNames = {},
        inactiveQuickFixPartsNames = {}
    }
    local inactivePoorPartsSeen = {}
    local inactiveQuickFixSeen = {}

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
                local partKey = registryEntry.part or registryEntry.system
                local partText = partKey ~= nil and g_i18n:getText(partKey) or tostring(breakdownId)

                if breakdownData.isActive ~= false then
                    reportMetrics.visibleSelectableActiveBreakdownsCount = reportMetrics.visibleSelectableActiveBreakdownsCount + 1
                elseif breakdownData.source == AdvancedDamageSystem.BREAKDOWN_SOURCES.POOR_PARTS then
                    appendUniqueText(reportMetrics.inactivePoorPartsNames, inactivePoorPartsSeen, partText)
                elseif breakdownData.source == AdvancedDamageSystem.BREAKDOWN_SOURCES.QUICK_FIX then
                    appendUniqueText(reportMetrics.inactiveQuickFixPartsNames, inactiveQuickFixSeen, partText)
                end

                local severityText = g_i18n:getText(stageData.severity)
                local descriptionText = g_i18n:getText(stageData.description)

                if breakdownData.isActive == false and breakdownData.source == AdvancedDamageSystem.BREAKDOWN_SOURCES.QUICK_FIX then
                    severityText = g_i18n:getText("ads_breakdowns_quick_fix_stage")
                    descriptionText = g_i18n:getText("ads_breakdowns_temporarily_repaired_description")
                elseif breakdownData.isActive == false and breakdownData.source == AdvancedDamageSystem.BREAKDOWN_SOURCES.POOR_PARTS then
                    severityText = g_i18n:getText("ads_breakdowns_defected_parts_stage")
                    descriptionText = g_i18n:getText("ads_breakdowns_defected_parts_detected_description")
                end

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
    padRowsToCount(self.vehicleSpecData, REPORT_TABLE_MIN_ROWS_MAIN, function()
        return {isPadding = true}
    end)
    padRowsToCount(self.breakdownsData, REPORT_TABLE_MIN_ROWS_BOTTOM, function()
        return ""
    end)
    padRowsToCount(self.recommendationsData, REPORT_TABLE_MIN_ROWS_BOTTOM, function()
        return ""
    end)

    self.overallAssessmentTable:setDataSource(self)
    self.systemConditionTable:setDataSource(self)
    self.vehicleSpecTable:setDataSource(self)
    self.breakdownsTable:setDataSource(self)
    self.recommendationsTable:setDataSource(self)
    self.overallAssessmentTable:reloadData()
    self.systemConditionTable:reloadData()
    self.vehicleSpecTable:reloadData()
    self.breakdownsTable:reloadData()
    self.recommendationsTable:reloadData()
end

function ADS_ReportDialog:getNumberOfItemsInSection(list, section)
    if list == self.overallAssessmentTable then
        return #self.overallAssessmentData
    elseif list == self.systemConditionTable then
        return #self.systemConditionData
    elseif list == self.vehicleSpecTable then
        return #self.vehicleSpecData
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
    elseif list == self.vehicleSpecTable then
        self:populateVehicleSpecCell(index, cell)
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
    local maxMtbf = ADS_Config.CORE.BREAKDOWN_PROBABILITIES.MAX_MTBF / 60
    local minMtbf = ADS_Config.CORE.BREAKDOWN_PROBABILITIES.MIN_MTBF / 60
    local diffMtbf = maxMtbf - minMtbf
    local minCrit = ADS_Config.CORE.BREAKDOWN_PROBABILITIES.CRITICAL_MIN
    local maxCrit = ADS_Config.CORE.BREAKDOWN_PROBABILITIES.CRITICAL_MAX
    local critDiff = maxCrit - minCrit
    local rel = 1 / (ADS_Config.CORE.BASE_SYSTEMS_WEAR / spec.reliability)
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
        local riskElement = cell:getAttribute("reportTableSystemRiskValue")
        titleElement:setText("")
        valueElement:setText("")
        riskElement:setText("")
        titleElement:setTextColor(1.0, 1.0, 1.0, 1.0)
        valueElement:setTextColor(1.0, 1.0, 1.0, 1.0)
        riskElement:setTextColor(1.0, 1.0, 1.0, 1.0)
        return
    end

    local key = data[1]
    local condition = tonumber(data[2]) or 0
    local val = condition * 100
    local stress = data[3] or 0
    local safeCondition = math.max(condition, 0.001)
    local normalizedRisk = math.max(math.min((tonumber(stress) or 0) / safeCondition, 1.0), 0.0)
    local riskValue = normalizedRisk * 100
    local stressLabel = getStressLabel(stress, condition)

    local function getConditionColor(smooth)
        return ADS_Utils.getValueColor(val, 80, 60, 40, 20, smooth)
    end

    local function getRiskColor(smooth)
        return ADS_Utils.getValueColorInverted(riskValue, 20, 40, 60, 80, smooth)
    end

    cell:getAttribute("reportTableSystemConditionTitle"):setText(g_i18n:getText(key))
    

    local valueElement = cell:getAttribute("reportTableSystemConditionValue")
    local riskElement = cell:getAttribute("reportTableSystemRiskValue")

    if self.isCompleteInspection then
        cell:getAttribute("reportTableSystemConditionTitle"):setTextColor(1.0, 1.0, 1.0, 1.0)
        valueElement:setText(string.format("%.1f %%", val))
        riskElement:setText(stressLabel)
        valueElement:setTextColor(getConditionColor(true))
        riskElement:setTextColor(getRiskColor(true))
    else
        local stateTexts = {
            g_i18n:getText("ads_spec_state_excellent"),
            g_i18n:getText("ads_spec_state_good"),
            g_i18n:getText("ads_spec_state_normal"),
            g_i18n:getText("ads_spec_state_bad"),
            g_i18n:getText("ads_spec_state_terrible")
        }

        cell:getAttribute("reportTableSystemConditionTitle"):setTextColor(1.0, 1.0, 1.0, 1.0)
        valueElement:setText(ADS_Utils.getValueLabel(val, 80, 60, 40, 20, table.unpack(stateTexts)))
        riskElement:setText(g_i18n:getText("ads_report_state_not_available"))
        valueElement:setTextColor(getConditionColor(false))
        riskElement:setTextColor(0.5, 0.5, 0.5, 1.0)
    end
end

function ADS_ReportDialog:populateVehicleSpecCell(index, cell)
    local data = self.vehicleSpecData[index]
    if not data then return end

    if data.isPadding then
        local titleElement = cell:getAttribute("reportTableVehicleSpecTitle")
        local valueElement = cell:getAttribute("reportTableVehicleSpecValue")
        titleElement:setText("")
        valueElement:setText("")
        titleElement:setTextColor(1.0, 1.0, 1.0, 1.0)
        valueElement:setTextColor(1.0, 1.0, 1.0, 1.0)
        return
    end

    local key = data.key or data[1]
    local kind = data.kind or "ratio"
    local forceNumericPercent = key == "ads_report_vehicle_spec_battery_charge"
    local ratioValue = clampUnitRatio(data.ratio or data.value or data[2] or 0)
    local val = ratioValue * 100
    local cfg = {
        inverted = data.inverted == true,
        ideal = data.ideal or 99,
        high = data.high or 90,
        mid = data.mid or 70,
        low = data.low or 30,
        stdVisible = data.stdVisible ~= false
    }

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

    cell:getAttribute("reportTableVehicleSpecTitle"):setText(g_i18n:getText(key))
    local valueElement = cell:getAttribute("reportTableVehicleSpecValue")

    local displayText
    if self.isCompleteInspection then
        cell:getAttribute("reportTableVehicleSpecTitle"):setTextColor(1.0, 1.0, 1.0, 1.0)
    else
        if not cfg.stdVisible then
            cell:getAttribute("reportTableVehicleSpecTitle"):setTextColor(0.5, 0.5, 0.5, 1.0)
        else
            cell:getAttribute("reportTableVehicleSpecTitle"):setTextColor(1.0, 1.0, 1.0, 1.0)
        end

        local stateTexts = {
            g_i18n:getText("ads_report_state_optimal"),
            g_i18n:getText("ads_report_state_normal"),
            g_i18n:getText("ads_report_state_degraded"),
            g_i18n:getText("ads_report_state_impaired"),
            g_i18n:getText("ads_report_state_critical")
        }

        if cfg.stdVisible then
            if kind == "text" then
                displayText = g_i18n:getText(data.textKey or "")
            elseif kind == "pair" then
                displayText = string.format("%.1f | %.1f %s", data.currentValue or 0, data.nominalValue or 0, data.unit or "")
            elseif forceNumericPercent then
                displayText = string.format("%.1f %%", val)
            elseif cfg.inverted then
                displayText = ADS_Utils.getValueLabelInverted(val, cfg.ideal, cfg.low, cfg.mid, cfg.high, table.unpack(stateTexts))
            else
                displayText = ADS_Utils.getValueLabel(val, cfg.ideal, cfg.high, cfg.mid, cfg.low, table.unpack(stateTexts))
            end
        else
            displayText = g_i18n:getText("ads_report_state_not_available")
        end
    end

    if self.isCompleteInspection then
        if kind == "text" then
            displayText = g_i18n:getText(data.textKey or "")
        elseif kind == "pair" then
            displayText = string.format("%.1f | %.1f %s", data.currentValue or 0, data.nominalValue or 0, data.unit or "")
        else
            displayText = string.format("%.1f %%", val)
        end
    end

    valueElement:setText(displayText or "")
    valueElement:setTextColor(getColor(self.isCompleteInspection))
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
