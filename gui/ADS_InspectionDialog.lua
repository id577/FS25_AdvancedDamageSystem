ADS_InspectionDialog = {}
ADS_InspectionDialog.INSTANCE = nil

local ADS_InspectionDialog_mt = Class(ADS_InspectionDialog, MessageDialog)
local modDirectory = g_currentModDirectory
local OK_COLOR = {0.40, 0.95, 0.40, 1.0}
local TEXT_COLOR = {1, 1, 1, 1}
local WARN_COLOR = {1.0, 0.77, 0.24, 1.0}
local CRITICAL_COLOR = {1.0, 0.38, 0.38, 1.0}
local NOT_REQUIRED_COLOR = {0.72, 0.72, 0.72, 1.0}

local TARGET_TO_SECTION = {
    engineOil = "technicalFluidsData",
    coolant = "technicalFluidsData",
    hydraulicFluid = "technicalFluidsData",
    transmissionOil = "technicalFluidsData",
    radiator = "coolingAndAirData",
    airIntake = "coolingAndAirData",
    airFilter = "coolingAndAirData",
    lubrication = "lubricationData"
}

local STATUS_PRIORITY = {
    ads_inspection_ok = 0,
    ads_inspection_status_slightly_low = 1,
    ads_inspection_status_slightly_darkened = 1,
    ads_inspection_status_slight_moisture = 1,
    ads_inspection_status_slightly_dirty = 1,
    ads_inspection_status_low = 2,
    ads_inspection_status_darkened = 2,
    ads_inspection_status_seepage = 2,
    ads_inspection_status_dirty = 2,
    ads_inspection_status_very_low = 3,
    ads_inspection_status_contaminated = 3,
    ads_inspection_status_active_leak = 3,
    ads_inspection_status_heavily_clogged = 3,
    ads_inspection_status_critically_low = 4,
    ads_inspection_status_critical_condition = 4,
    ads_inspection_status_severe_leak = 4,
    ads_inspection_status_critically_clogged = 4,
    ads_inspection_status_not_required = 0
}

local function getLocalizedText(value)
    if value == nil then
        return ""
    end

    if type(value) == "string" and string.sub(value, 1, 4) == "ads_" then
        return g_i18n:getText(value)
    end

    return tostring(value)
end

local function getRowColor(row)
    if row ~= nil and row.statusKey == "ads_inspection_status_not_required" then
        return NOT_REQUIRED_COLOR
    end

    local priority = row ~= nil and STATUS_PRIORITY[row.statusKey or ""] or 0
    if priority >= 4 then
        return CRITICAL_COLOR
    elseif priority >= 1 then
        return WARN_COLOR
    end

    return OK_COLOR
end

local function setRowValue(rows, titleKey, statusKey)
    if rows == nil or titleKey == nil or statusKey == nil then
        return
    end

    for _, row in ipairs(rows) do
        if row.titleKey == titleKey then
            local newPriority = STATUS_PRIORITY[statusKey] or 0
            local currentPriority = STATUS_PRIORITY[row.statusKey or "ads_inspection_ok"] or 0

            if newPriority >= currentPriority then
                row.statusKey = statusKey
                row.value = getLocalizedText(statusKey)
            end

            return
        end
    end
end

local function appendAdditionalLine(lines, textKey)
    if lines == nil or textKey == nil or textKey == "" then
        return
    end

    local text = getLocalizedText(textKey)
    if text == "" then
        return
    end

    for _, existing in ipairs(lines) do
        if existing == text then
            return
        end
    end

    table.insert(lines, text)
end

local function buildAdditionalText(lines)
    if lines == nil or #lines == 0 then
        return g_i18n:getText("ads_inspection_no_suspicious_symptoms")
    end

    local formattedLines = {}
    for _, line in ipairs(lines) do
        table.insert(formattedLines, "- " .. line)
    end

    return table.concat(formattedLines, "\n")
end

local function applyBreakdownInspectionFindings(dialog, additionalLines)
    local vehicle = dialog.vehicle
    if vehicle == nil or vehicle.getActiveBreakdowns == nil or ADS_Breakdowns == nil then
        return
    end

    local activeBreakdowns = vehicle:getActiveBreakdowns() or {}
    local registry = ADS_Breakdowns.BreakdownRegistry or {}
    local targetMap = {
        engineOil = "ads_inspection_engine_oil",
        coolant = "ads_inspection_coolant",
        hydraulicFluid = "ads_inspection_hydraulic_fluid",
        transmissionOil = "ads_inspection_transmission_oil",
        radiator = "ads_inspection_radiator",
        airIntake = "ads_inspection_air_duct",
        airFilter = "ads_inspection_air_filter",
        lubrication = "ads_inspection_lubrication_level"
    }

    for breakdownId, breakdown in pairs(activeBreakdowns) do
        local registryEntry = registry[breakdownId]
        if registryEntry ~= nil and registryEntry.stages ~= nil then
            local stageData = registryEntry.stages[breakdown.stage]
            local findings = stageData ~= nil and stageData.inspection or nil

            if findings ~= nil then
                for _, finding in ipairs(findings) do
                    -- `additional` can be used on its own without target/status, which
                    -- allows breakdowns to contribute only to the 4th section.
                    if finding.target ~= nil and finding.status ~= nil then
                        local titleKey = targetMap[finding.target]
                        local sectionKey = TARGET_TO_SECTION[finding.target]
                        if titleKey ~= nil and sectionKey ~= nil then
                            setRowValue(dialog[sectionKey], titleKey, finding.status)
                        end
                    end

                    appendAdditionalLine(additionalLines, finding.additional)
                end
            end
        end
    end
end

local function applyCloggingInspectionFindings(dialog, additionalLines)
    local vehicle = dialog.vehicle
    local spec = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    if spec == nil then
        return
    end

    if spec.isVehicleNeedBlowOut == false then
        return
    end

    local radiatorClogging = math.clamp(tonumber(spec.radiatorClogging) or 0, 0, 1)
    if radiatorClogging > 0.15 then
        local statusKey
        if radiatorClogging >= 0.85 then
            statusKey = "ads_inspection_status_critically_clogged"
            appendAdditionalLine(additionalLines, "ads_inspection_hint_radiator_clogging_stage4")
        elseif radiatorClogging >= 0.60 then
            statusKey = "ads_inspection_status_heavily_clogged"
            appendAdditionalLine(additionalLines, "ads_inspection_hint_radiator_clogging_stage3")
        elseif radiatorClogging >= 0.35 then
            statusKey = "ads_inspection_status_dirty"
            appendAdditionalLine(additionalLines, "ads_inspection_hint_radiator_clogging_stage2")
        else
            statusKey = "ads_inspection_status_slightly_dirty"
            appendAdditionalLine(additionalLines, "ads_inspection_hint_radiator_clogging_stage1")
        end

        setRowValue(dialog.coolingAndAirData, "ads_inspection_radiator", statusKey)
    end

    local airIntakeClogging = math.clamp(tonumber(spec.airIntakeClogging) or 0, 0, 1)
    if airIntakeClogging > 0.15 then
        local statusKey
        if airIntakeClogging >= 0.85 then
            statusKey = "ads_inspection_status_critically_clogged"
            appendAdditionalLine(additionalLines, "ads_inspection_hint_air_intake_clogging_stage4")
        elseif airIntakeClogging >= 0.60 then
            statusKey = "ads_inspection_status_heavily_clogged"
            appendAdditionalLine(additionalLines, "ads_inspection_hint_air_intake_clogging_stage3")
        elseif airIntakeClogging >= 0.35 then
            statusKey = "ads_inspection_status_dirty"
            appendAdditionalLine(additionalLines, "ads_inspection_hint_air_intake_clogging_stage2")
        else
            statusKey = "ads_inspection_status_slightly_dirty"
            appendAdditionalLine(additionalLines, "ads_inspection_hint_air_intake_clogging_stage1")
        end

        setRowValue(dialog.coolingAndAirData, "ads_inspection_air_duct", statusKey)
    end
end

function ADS_InspectionDialog.register()
    local dialog = ADS_InspectionDialog.new()
    g_gui:loadGui(modDirectory .. "gui/ADS_InspectionDialog.xml", "ADS_InspectionDialog", dialog)
    ADS_InspectionDialog.INSTANCE = dialog
end

function ADS_InspectionDialog.new(target, customMt)
    local dialog = MessageDialog.new(target, customMt or ADS_InspectionDialog_mt)
    dialog.vehicle = nil
    dialog.technicalFluidsData = {}
    dialog.coolingAndAirData = {}
    dialog.lubricationData = {}
    return dialog
end

function ADS_InspectionDialog.show(vehicle)
    if ADS_InspectionDialog.INSTANCE == nil then ADS_InspectionDialog.register() end
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then return end
    
    local dialog = ADS_InspectionDialog.INSTANCE
    dialog.vehicle = vehicle
    dialog:updateScreen()
    g_gui:showDialog("ADS_InspectionDialog")
end

function ADS_InspectionDialog:updateScreen()
    if self.vehicle == nil then return end
    
    self.dialogTitleElement:setText(g_i18n:getText("ads_inspection_dialog_title"))

    self.technicalFluidsData = {
        {titleKey = "ads_inspection_engine_oil", title = g_i18n:getText("ads_inspection_engine_oil"), statusKey = "ads_inspection_ok", value = g_i18n:getText("ads_inspection_ok")},
        {titleKey = "ads_inspection_coolant", title = g_i18n:getText("ads_inspection_coolant"), statusKey = "ads_inspection_ok", value = g_i18n:getText("ads_inspection_ok")},
        {titleKey = "ads_inspection_hydraulic_fluid", title = g_i18n:getText("ads_inspection_hydraulic_fluid"), statusKey = "ads_inspection_ok", value = g_i18n:getText("ads_inspection_ok")},
        {titleKey = "ads_inspection_transmission_oil", title = g_i18n:getText("ads_inspection_transmission_oil"), statusKey = "ads_inspection_ok", value = g_i18n:getText("ads_inspection_ok")}
    }

    self.coolingAndAirData = {
        {titleKey = "ads_inspection_radiator", title = g_i18n:getText("ads_inspection_radiator"), statusKey = "ads_inspection_ok", value = g_i18n:getText("ads_inspection_ok")},
        {titleKey = "ads_inspection_air_duct", title = g_i18n:getText("ads_inspection_air_duct"), statusKey = "ads_inspection_ok", value = g_i18n:getText("ads_inspection_ok")},
        {titleKey = "ads_inspection_air_filter", title = g_i18n:getText("ads_inspection_air_filter"), statusKey = "ads_inspection_ok", value = g_i18n:getText("ads_inspection_ok")}
    }

    self.lubricationData = {
        {titleKey = "ads_inspection_lubrication_level", title = g_i18n:getText("ads_inspection_lubrication_level"), statusKey = "ads_inspection_ok", value = g_i18n:getText("ads_inspection_ok")}
    }

    local spec = self.vehicle.spec_AdvancedDamageSystem
    if spec ~= nil and spec.isVehicleNeedBlowOut == false then
        setRowValue(self.coolingAndAirData, "ads_inspection_radiator", "ads_inspection_status_not_required")
        setRowValue(self.coolingAndAirData, "ads_inspection_air_duct", "ads_inspection_status_not_required")
    end

    if spec ~= nil and spec.isVehicleNeedLubricate == false then
        setRowValue(self.lubricationData, "ads_inspection_lubrication_level", "ads_inspection_status_not_required")
    end

    local additionalLines = {}

    applyBreakdownInspectionFindings(self, additionalLines)
    applyCloggingInspectionFindings(self, additionalLines)

    self.additionalText:setText(buildAdditionalText(additionalLines))

    self.technicalFluidsList:setDataSource(self)
    self.technicalFluidsList:setDelegate(self)
    self.technicalFluidsList:reloadData()

    self.coolingAndAirList:setDataSource(self)
    self.coolingAndAirList:setDelegate(self)
    self.coolingAndAirList:reloadData()

    self.lubricationList:setDataSource(self)
    self.lubricationList:setDelegate(self)
    self.lubricationList:reloadData()
end

local function getListData(self, list)
    if list == self.technicalFluidsList then
        return self.technicalFluidsData
    elseif list == self.coolingAndAirList then
        return self.coolingAndAirData
    elseif list == self.lubricationList then
        return self.lubricationData
    end

    return nil
end

function ADS_InspectionDialog:getNumberOfItemsInSection(list, section)
    local data = getListData(self, list)
    return data ~= nil and #data or 0
end

function ADS_InspectionDialog:populateCellForItemInSection(list, section, index, cell)
    local data = getListData(self, list)
    local row = data ~= nil and data[index] or nil
    if row == nil then
        return
    end

    local titleElement = cell:getAttribute("inspectionTitle")
    local valueElement = cell:getAttribute("inspectionValue")

    titleElement:setText(row.title or "")
    valueElement:setText(row.value or "")
    titleElement:setTextColor(unpack(TEXT_COLOR))
    valueElement:setTextColor(unpack(getRowColor(row)))
end

function ADS_InspectionDialog:onOpen()
    ADS_InspectionDialog:superClass().onOpen(self)
end

function ADS_InspectionDialog:onClose()
    self.vehicle = nil
    ADS_InspectionDialog:superClass().onClose(self)
end

function ADS_InspectionDialog:onClickBack()
    self:close()
end
