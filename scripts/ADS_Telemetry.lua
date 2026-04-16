ADS_Telemetry = {}
ADS_Telemetry.modDirectory = g_currentModDirectory

ADS_Telemetry.isRecording = false
ADS_Telemetry.intervalMs = 1000
ADS_Telemetry.elapsedMs = 0
ADS_Telemetry.samples = {}
ADS_Telemetry.startedAt = nil
ADS_Telemetry.stoppedAt = nil
ADS_Telemetry.vehicleId = nil
ADS_Telemetry.vehicleName = nil
ADS_Telemetry.filePrefix = "ads_telemetry"
ADS_Telemetry.fileSequence = 0
ADS_Telemetry.recordingScenario = nil
ADS_Telemetry.sessionInfo = nil

-- =====================================================================================
--                              HELPER FUNCTIONS
-- =====================================================================================

local function log_dbg(...)
    if ADS_Config.DEBUG then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i])
        end
        print("[ADS_TELEMETRY] " .. table.concat(args, " "))
    end
end

local function getTelemetryOutputDirectory()
    return getUserProfileAppPath() .. "modSettings/FS25_AdvancedDamageSystem/"
end

local function sanitizeFileName(value)
    value = tostring(value or "unknown")
    value = value:gsub("[\\/:*?\"<>|]", "_")
    value = value:gsub("%s+", "_")
    value = value:gsub("_+", "_")
    value = value:gsub("^_+", "")
    value = value:gsub("_+$", "")

    if value == "" then
        value = "unknown"
    end

    return value
end

local function csvEscape(value)
    local text = value == nil and "" or tostring(value)
    text = text:gsub('"', '""')
    return '"' .. text .. '"'
end

local function flattenTable(target, prefix, value)
    local valueType = type(value)

    if valueType ~= "table" then
        target[prefix] = value
        return
    end

    local keys = {}
    for key, _ in pairs(value) do
        table.insert(keys, key)
    end

    table.sort(keys, function(a, b)
        if type(a) == type(b) and (type(a) == "number" or type(a) == "string") then
            return a < b
        end
        return tostring(a) < tostring(b)
    end)

    if #keys == 0 then
        target[prefix] = ""
        return
    end

    for _, key in ipairs(keys) do
        local childValue = value[key]
        local childKey = prefix ~= nil and prefix ~= ""
            and (prefix .. "." .. tostring(key))
            or tostring(key)
        flattenTable(target, childKey, childValue)
    end
end

local function buildCsvRows(samples)
    local rows = {}
    local headerSet = {}
    local headerOrder = {}

    for _, sample in ipairs(samples or {}) do
        local flatRow = {}

        flattenTable(flatRow, nil, sample)
        table.insert(rows, flatRow)

        for key, _ in pairs(flatRow) do
            if not headerSet[key] then
                headerSet[key] = true
                table.insert(headerOrder, key)
            end
        end
    end

    table.sort(headerOrder)
    return headerOrder, rows
end

local function getTelemetryTargetVehicle()
    local vehicle = g_localPlayer ~= nil and g_localPlayer.getCurrentVehicle ~= nil and g_localPlayer:getCurrentVehicle() or nil
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        log_dbg("Telemetry: no current ADS vehicle found.")
        return nil
    end

    return vehicle
end

local function collectAttachedImplementNames(rootVehicle, names, visited)
    names = names or {}
    visited = visited or {}

    if rootVehicle == nil or visited[rootVehicle] then
        return names
    end

    visited[rootVehicle] = true

    local attachedImplements = rootVehicle.getAttachedImplements ~= nil and rootVehicle:getAttachedImplements() or nil
    if attachedImplements ~= nil then
        for _, implement in pairs(attachedImplements) do
            local object = implement.object
            if object ~= nil and not visited[object] then
                local objectName = object.getFullName ~= nil and object:getFullName() or tostring(object.configFileName or object)
                table.insert(names, tostring(objectName))
                collectAttachedImplementNames(object, names, visited)
            end
        end
    end

    return names
end

local function hasCVTTransmission(vehicle)
    local motor = vehicle ~= nil and vehicle.getMotor ~= nil and vehicle:getMotor() or nil
    return motor ~= nil and motor.minForwardGearRatio ~= nil
end

local function hasCVTAddon(vehicle)
    local spec_CVTaddon = vehicle ~= nil and vehicle.spec_CVTaddon or nil
    local cvtAddonConfig = spec_CVTaddon ~= nil and (tonumber(spec_CVTaddon.CVTconfig) or 0) or 0
    return spec_CVTaddon ~= nil
        and spec_CVTaddon.CVTcfgExists
        and cvtAddonConfig ~= 0
        and cvtAddonConfig ~= 8
end

local function splitConsoleArgs(text)
    local args = {}
    for token in tostring(text or ""):gmatch("%S+") do
        table.insert(args, token)
    end
    return args
end

function ADS_Telemetry:buildOutputFilePath()
    local baseDir = getTelemetryOutputDirectory()
    createFolder(baseDir)

    self.fileSequence = (self.fileSequence or 0) + 1

    local safeVehicleName = sanitizeFileName(self.vehicleName)
    local safeVehicleId = sanitizeFileName(self.vehicleId)
    local safeScenarioName = sanitizeFileName(self.recordingScenario or "default")
    local baseName = string.format(
        "%s_%s_%s_%s_%03d",
        tostring(self.filePrefix or "ads_telemetry"),
        safeScenarioName,
        safeVehicleName,
        safeVehicleId,
        self.fileSequence
    )

    local filePath = baseDir .. baseName .. ".csv"
    local collisionIndex = 1

    while fileExists(filePath) do
        filePath = string.format("%s%s_%02d.csv", baseDir, baseName, collisionIndex)
        collisionIndex = collisionIndex + 1
    end

    return filePath
end

-- =====================================================================================
--                              FILE OUTPUT
-- =====================================================================================

function ADS_Telemetry:saveToFile()
    local filePath = self:buildOutputFilePath()
    local file = io.open(filePath, "w")

    if file == nil then
        log_dbg("Telemetry: failed to open file for writing:", filePath)
        return false
    end

    local metadata = {
        startedAt = self.startedAt,
        stoppedAt = self.stoppedAt,
        vehicleId = self.vehicleId,
        vehicleName = self.vehicleName,
        scenario = self.recordingScenario,
        intervalMs = self.intervalMs,
        sampleCount = self.samples ~= nil and #self.samples or 0
    }

    if type(self.sessionInfo) == "table" then
        for key, value in pairs(self.sessionInfo) do
            metadata[key] = value
        end
    end

    local flatMetadata = {}
    flattenTable(flatMetadata, nil, metadata)

    local metadataHeaders = {}
    for key, _ in pairs(flatMetadata) do
        table.insert(metadataHeaders, key)
    end
    table.sort(metadataHeaders)

    file:write("metadataKey,metadataValue\n")
    for _, key in ipairs(metadataHeaders) do
        file:write(csvEscape(key))
        file:write(",")
        file:write(csvEscape(flatMetadata[key]))
        file:write("\n")
    end

    file:write("\n")

    local headers, rows = buildCsvRows(self.samples or {})
    if #headers > 0 then
        file:write(table.concat(headers, ","))
        file:write("\n")

        for _, row in ipairs(rows) do
            local values = {}
            for _, header in ipairs(headers) do
                table.insert(values, csvEscape(row[header]))
            end
            file:write(table.concat(values, ","))
            file:write("\n")
        end
    end

    file:close()

    log_dbg("Telemetry: saved file:", filePath)
    return true
end

-- =====================================================================================
--                              SERVICE FUNCTIONS
-- =====================================================================================

function ADS_Telemetry:reset()
    self.isRecording = false
    self.elapsedMs = 0
    self.samples = {}
    self.startedAt = nil
    self.stoppedAt = nil
    self.vehicleId = nil
    self.vehicleName = nil
    self.recordingScenario = nil
    self.sessionInfo = nil
end

function ADS_Telemetry:getRecordedVehicle()
    if self.vehicleId == nil or ADS_Main == nil or ADS_Main.vehicles == nil then
        return nil
    end

    return ADS_Main.vehicles[self.vehicleId]
end

-- =====================================================================================
--                              SESSION INFO
-- =====================================================================================

function ADS_Telemetry:collectSessionInfo(vehicle)
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        return nil
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    local environment = g_currentMission ~= nil and g_currentMission.environment or nil
    local weather = environment ~= nil and environment.weather or nil
    local ambientTemperatureC = weather ~= nil and weather.getCurrentTemperature ~= nil and weather:getCurrentTemperature() or 0
    local operatingTimeMs = tonumber(vehicle.getOperatingTime ~= nil and vehicle:getOperatingTime() or vehicle.operatingTime or 0) or 0
    local operatingTimeSec = operatingTimeMs / 1000
    local operatingHours = operatingTimeMs / 3600000
    local ageMonths = tonumber(vehicle.age or 0) or 0
    local tractorMassKg = tonumber(vehicle.getTotalMass ~= nil and vehicle:getTotalMass(true) or 0) or 0
    local totalMassKg = tonumber(vehicle.getTotalMass ~= nil and vehicle:getTotalMass() or tractorMassKg) or tractorMassKg
    local attachedNames = collectAttachedImplementNames(vehicle, {}, {})

    return {
        subjectFullName = vehicle.getFullName ~= nil and vehicle:getFullName() or "unknown",
        subjectAgeMonths = ageMonths,
        subjectAgeYears = ageMonths / 12,
        subjectOperatingTimeSec = operatingTimeSec,
        subjectOperatingHours = operatingHours,
        subjectReliability = tonumber(spec.reliability or 0) or 0,
        subjectMaintainability = tonumber(spec.maintainability or 0) or 0,
        subjectTractorMassKg = tractorMassKg,
        subjectTotalMassKg = totalMassKg,
        subjectAttachedCount = #attachedNames,
        subjectAttachedNames = table.concat(attachedNames, " | "),
        environmentAmbientTemperatureC = tonumber(ambientTemperatureC or 0) or 0
    }
end

-- =====================================================================================
--                              DATA COLLECTORS
-- =====================================================================================

function ADS_Telemetry:collectTransmissionSystemInfo(vehicle)
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        return nil
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    local debugData = type(spec.debugData) == "table" and spec.debugData or {}
    local transmissionDbg = type(debugData.transmission) == "table" and debugData.transmission or {}
    local systemData = spec.systems ~= nil and spec.systems.transmission or nil
    local systemStats = type(spec.factorStats) == "table" and spec.factorStats.transmission or nil

    return {
        condition = tonumber(systemData ~= nil and systemData.condition or 0) or 0,
        stress = tonumber(systemData ~= nil and systemData.stress or 0) or 0,
        totalWearRate = tonumber(transmissionDbg.totalWearRate or 0) or 0,
        instantStressRate = tonumber(transmissionDbg.instantStressRate or 0) or 0,
        avgStress = tonumber(transmissionDbg._avgStress or 0) or 0,
        accumulatedStress = tonumber(systemStats ~= nil and systemStats.stress or 0) or 0,
        breakdownProbability = tonumber(transmissionDbg.breakdownProbability or 0) or 0,
        critBreakdownProbability = tonumber(transmissionDbg.critBreakdownProbability or 0) or 0,
        expiredServiceFactor = tonumber(transmissionDbg.expiredServiceFactor or 0) or 0,
        breakdownPresenceFactor = tonumber(transmissionDbg.breakdownPresenceFactor or 0) or 0,
        pullOverloadFactor = tonumber(transmissionDbg.pullOverloadFactor or 0) or 0,
        pullOverloadTimer = tonumber(transmissionDbg.pullOverloadTimer or 0) or 0,
        heavyTrailerFactor = tonumber(transmissionDbg.heavyTrailerFactor or 0) or 0,
        heavyTrailerMassRatio = tonumber(transmissionDbg.heavyTrailerMassRatio or 0) or 0,
        luggingFactor = tonumber(transmissionDbg.luggingFactor or 0) or 0,
        wheelSlipFactor = tonumber(transmissionDbg.wheelSlipFactor or transmissionDbg.wheelSleepFactor or 0) or 0,
        wheelSlipIntensity = tonumber(spec.wheelSlipIntensity or 0) or 0,
        avgTireGroundFrictionCoeff = tonumber(spec.avgTireGroundFrictionCoeff or 0) or 0,
        coldTransFactor = tonumber((transmissionDbg.coldTransFactor or transmissionDbg.coldMotorFactor) or 0) or 0,
        hotTransFactor = tonumber(transmissionDbg.hotTransFactor or 0) or 0
    }
end

function ADS_Telemetry:collectCVTTempInfo(vehicle)
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil or not hasCVTTransmission(vehicle) then
        return nil
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    local debugData = type(spec.debugData) == "table" and spec.debugData or {}
    local transmissionTempDbg = type(debugData.transmissionTemp) == "table" and debugData.transmissionTemp or {}

    return {
        temperatureC = tonumber(spec.transmissionTemperature or -99) or -99,
        rawTemperatureC = tonumber(spec.rawTransmissionTemperature or spec.transmissionTemperature or -99) or -99,
        thermostatState = tonumber(spec.transmissionThermostatState or 0) or 0,
        kp = tonumber(transmissionTempDbg.kp or 0) or 0,
        stiction = tonumber(transmissionTempDbg.stiction or 0) or 0,
        waxSpeed = tonumber(transmissionTempDbg.waxSpeed or 0) or 0,
        totalHeat = tonumber(transmissionTempDbg.totalHeat or 0) or 0,
        totalCooling = tonumber(transmissionTempDbg.totalCooling or 0) or 0,
        radiatorCooling = tonumber(transmissionTempDbg.radiatorCooling or 0) or 0,
        speedCooling = tonumber(transmissionTempDbg.speedCooling or 0) or 0,
        convectionCooling = tonumber(transmissionTempDbg.convectionCooling or 0) or 0,
        loadFactor = tonumber(transmissionTempDbg.loadFactor or 0) or 0,
        slipFactor = tonumber(transmissionTempDbg.slipFactor or 0) or 0,
        accFactor = tonumber(transmissionTempDbg.accFactor or 0) or 0,
        pullFactor = tonumber(transmissionTempDbg.pullFactor or 0) or 0,
        wheelSlipFactor = tonumber(transmissionTempDbg.wheelSlipFactor or 0) or 0,
        cvtSlipActive = tonumber(transmissionTempDbg.cvtSlipActive or 0) or 0,
        cvtSlipLocked = tonumber(transmissionTempDbg.cvtSlipLocked or 0) or 0,
        extraTransmissionHeat = tonumber(transmissionTempDbg.extraTransmissionHeat or 0) or 0
    }
end

function ADS_Telemetry:collectDrivetrainInfo(vehicle)
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        return nil
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    local motor = vehicle.getMotor ~= nil and vehicle:getMotor() or nil
    if motor == nil then
        return nil
    end

    local availableTorque = tonumber(motor.getMotorAvailableTorque ~= nil and motor:getMotorAvailableTorque() or 0) or 0
    local motorPowerW = (tonumber(motor.getMotorRotSpeed ~= nil and motor:getMotorRotSpeed() or 0) or 0)
        * ((availableTorque - (tonumber(motor.getMotorExternalTorque ~= nil and motor:getMotorExternalTorque() or 0) or 0)) * 1000)
    local motorPowerHp = motorPowerW / 735.5
    local peakPowerHp = (tonumber(motor.peakMotorPower) or 0) * 1.36
    local lastRpm = tonumber(motor.getLastModulatedMotorRpm ~= nil and motor:getLastModulatedMotorRpm() or 0) or 0
    local maxRpm = math.max(tonumber(motor.maxRpm) or 1, 1)
    local rpmLoad = lastRpm / maxRpm
    local motorLoad = tonumber(vehicle.getMotorLoadPercentage ~= nil and vehicle:getMotorLoadPercentage() or 0) or 0
    local dynamicMotorLoad = tonumber(spec.dynamicMotorLoad) or motorLoad
    local avgAbsDiffAcc = tonumber(spec.avgAbsDiffAcc) or 0
    local acceleratorPedal = tonumber(motor.lastAcceleratorPedal or 0) or 0
    local currentSpeedKmh = tonumber(vehicle.getLastSpeed ~= nil and vehicle:getLastSpeed() or 0) or 0
    local currentSpeedLimitKmh = tonumber(vehicle.getSpeedLimit ~= nil and vehicle:getSpeedLimit(true) or 0) or 0
    if currentSpeedLimitKmh == math.huge or currentSpeedLimitKmh < 0 then
        currentSpeedLimitKmh = 0
    end
    if currentSpeedLimitKmh <= 0 and vehicle.spec_attacherJoints ~= nil and vehicle.spec_attacherJoints.attachedImplements ~= nil then
        local implementSpeedLimit = math.huge
        for _, implementData in pairs(vehicle.spec_attacherJoints.attachedImplements) do
            local implement = implementData ~= nil and implementData.object or nil
            local limit = implement ~= nil and tonumber(implement.speedLimit) or nil
            local isLowered = implement ~= nil and implement.getIsLowered ~= nil and implement:getIsLowered() or false
            if limit ~= nil and limit > 0 and isLowered then
                implementSpeedLimit = math.min(implementSpeedLimit, limit)
            end
        end
        if implementSpeedLimit < math.huge then
            currentSpeedLimitKmh = implementSpeedLimit
        end
    end
    if currentSpeedLimitKmh <= 0 then
        currentSpeedLimitKmh = (tonumber(motor.getMaximumForwardSpeed ~= nil and motor:getMaximumForwardSpeed() or 0) or 0) * 3.6
    end
    local targetGear = (tonumber(motor.targetGear) or 0) * (tonumber(motor.currentDirection) or 1)
    local spec_CVTaddon = vehicle.spec_CVTaddon

    return {
        motorPowerHp = motorPowerHp,
        peakPowerHp = peakPowerHp,
        motorLoad = motorLoad,
        dynamicMotorLoad = dynamicMotorLoad,
        avgAbsDiffAcc = avgAbsDiffAcc,
        acceleratorPedal = acceleratorPedal,
        rpmLoad = rpmLoad,
        currentSpeedKmh = currentSpeedKmh,
        currentSpeedLimitKmh = currentSpeedLimitKmh,
        currentGear = tonumber(motor.gear) or 0,
        targetGear = targetGear,
        activeGearGroupIndex = tonumber(motor.activeGearGroupIndex) or 0,
        gearRatio = tonumber(motor.getGearRatio ~= nil and motor:getGearRatio() or 0) or 0,
        draftMaxForce = tonumber(spec.activeDraftMaxForce) or 0,
        draftEffectiveForceCap = tonumber(spec.activeDraftEffectiveForceCap) or 0,
        cvtAddon = hasCVTAddon(vehicle) and {
            damage = tonumber(spec_CVTaddon.CVTdamage) or 0,
            warnDamage = spec_CVTaddon.forDBL_warndamage == 1,
            critDamage = spec_CVTaddon.forDBL_critdamage == 1,
            warnHeat = spec_CVTaddon.forDBL_warnheat == 1,
            critHeat = spec_CVTaddon.forDBL_critheat == 1,
            highPressure = spec_CVTaddon.forDBL_highpressure == 1
        } or nil
    }
end

function ADS_Telemetry:collectCloggingInfo(vehicle)
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        return nil
    end

    local spec = vehicle.spec_AdvancedDamageSystem
    local debugData = type(spec.debugData) == "table" and spec.debugData or {}
    local radiatorDbg = type(debugData.radiator) == "table" and debugData.radiator or {}
    local airIntakeDbg = type(debugData.airIntake) == "table" and debugData.airIntake or {}

    return {
        dirtLevel = tonumber(vehicle.getDirtAmount ~= nil and vehicle:getDirtAmount() or 0) or 0,
        radiatorClogging = tonumber(spec.radiatorClogging or 0) or 0,
        radiatorMultiplier = tonumber(radiatorDbg.totalMultiplier or 0) or 0,
        airIntakeClogging = tonumber(spec.airIntakeClogging or 0) or 0,
        airIntakeMultiplier = tonumber(airIntakeDbg.totalMultiplier or 0) or 0,
        isOnField = radiatorDbg.isOnField == true or airIntakeDbg.isOnField == true,
        hasDust = radiatorDbg.hasDust == true or airIntakeDbg.hasDust == true,
        hasDebris = radiatorDbg.hasDebris == true or airIntakeDbg.hasDebris == true,
        wetnessFactor = tonumber(airIntakeDbg.baseWetnessFactor or radiatorDbg.baseWetnessFactor or 1) or 1
    }
end

-- =====================================================================================
--                              SCENARIOS
-- =====================================================================================

function ADS_Telemetry:collectSample(vehicle)
    if vehicle == nil or vehicle.spec_AdvancedDamageSystem == nil then
        return nil
    end

    local scenario = tostring(self.recordingScenario or "default")
    local sample = {
        timestamp = g_currentMission ~= nil and g_currentMission.time or 0,
        vehicleId = vehicle.uniqueId,
        vehicleName = vehicle.getFullName ~= nil and vehicle:getFullName() or "unknown",
        scenario = scenario
    }

    if scenario == "transmission" then
        sample.transmissionSystem = self:collectTransmissionSystemInfo(vehicle)
        sample.cvtTemp = self:collectCVTTempInfo(vehicle)
        sample.drivetrain = self:collectDrivetrainInfo(vehicle)
        sample.clogging = self:collectCloggingInfo(vehicle)
    end

    return sample
end

-- =====================================================================================
--                              RECORDING CONTROL
-- =====================================================================================

function ADS_Telemetry:update(dt)
    if not self.isRecording then
        return
    end

    local vehicle = self:getRecordedVehicle()
    if vehicle == nil then
        self:finishRecording("vehicle_missing")
        return
    end

    self.elapsedMs = (self.elapsedMs or 0) + (dt or 0)
    if self.elapsedMs < self.intervalMs then
        return
    end

    self.elapsedMs = self.elapsedMs - self.intervalMs

    local sample = self:collectSample(vehicle)
    if sample ~= nil then
        table.insert(self.samples, sample)
    end
end

function ADS_Telemetry:finishRecording(reason)
    if not self.isRecording then
        log_dbg("Telemetry: recording is not active.")
        return false
    end

    self.isRecording = false
    self.stoppedAt = g_currentMission ~= nil and g_currentMission.time or 0

    log_dbg(string.format(
        "Telemetry: recording stopped (%s). Samples collected: %d.",
        tostring(reason or "manual"),
        self.samples ~= nil and #self.samples or 0
    ))

    return self:saveToFile()
end

function ADS_Telemetry:startRecording(scenarioName, intervalMs)
    local vehicle = getTelemetryTargetVehicle()
    if vehicle == nil then
        log_dbg("Telemetry: no current ADS vehicle is currently selected.")
        return false
    end

    local requestedScenario = tostring(scenarioName or "default")
    if requestedScenario ~= "default" and requestedScenario ~= "transmission" then
        log_dbg("Telemetry: unsupported scenario:", requestedScenario)
        return false
    end

    local requestedIntervalMs = math.floor(tonumber(intervalMs) or self.intervalMs or 1000)
    if requestedIntervalMs <= 0 then
        requestedIntervalMs = 1000
    end

    if self.isRecording then
        if self.vehicleId == vehicle.uniqueId and self.recordingScenario == requestedScenario and self.intervalMs == requestedIntervalMs then
            return true
        end

        self:finishRecording("switch_vehicle")
    end

    self:reset()
    self.isRecording = true
    self.startedAt = g_currentMission ~= nil and g_currentMission.time or 0
    self.vehicleId = vehicle.uniqueId
    self.vehicleName = vehicle.getFullName ~= nil and vehicle:getFullName() or tostring(vehicle.configFileName or "unknown")
    self.intervalMs = requestedIntervalMs
    self.recordingScenario = requestedScenario
    self.sessionInfo = self:collectSessionInfo(vehicle)

    log_dbg(string.format(
        "Telemetry recording started for '%s' (id: %s, scenario: %s, intervalMs: %d).",
        tostring(self.vehicleName),
        tostring(self.vehicleId),
        tostring(self.recordingScenario),
        tonumber(self.intervalMs) or 0
    ))
    return true
end

function ADS_Telemetry:stopRecording()
    return self:finishRecording("manual")
end

function ADS_Telemetry:startConsole(args)
    local tokens = splitConsoleArgs(args)
    local scenarioName = tokens[1] or "default"
    local intervalMs = tokens[2]
    self:startRecording(scenarioName, intervalMs)
end

function ADS_Telemetry:stopConsole()
    self:stopRecording()
end

-- =====================================================================================
--                              REGISTRATION
-- =====================================================================================

addConsoleCommand("ads_telemetryStart", "Starts ADS telemetry recording for the current vehicle.", "startConsole", ADS_Telemetry)
addConsoleCommand("ads_telemetryStop", "Stops ADS telemetry recording.", "stopConsole", ADS_Telemetry)
addModEventListener(ADS_Telemetry)
