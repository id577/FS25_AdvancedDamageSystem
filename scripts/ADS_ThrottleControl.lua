ADS_ThrottleControl = {}

ADS_ThrottleControl.STEP = 0.05


function ADS_ThrottleControl.isAdjustmentModeActive(vehicle)
    local spec = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    local drivableSpec = vehicle ~= nil and vehicle.spec_drivable or nil
    if spec == nil or drivableSpec == nil or spec.isExcludedVehicle then
        return false
    end

    local isAdjustmentKeyPressed = spec.throttleAdjustmentPressed == true
    if Input ~= nil and Input.KEY_t ~= nil then
        isAdjustmentKeyPressed = Input.isKeyPressed(Input.KEY_t)
    end

    if not isAdjustmentKeyPressed or (tonumber(drivableSpec.axisForward) or 0) <= 0.01 then
        return false
    end

    if g_gui ~= nil and g_gui:getIsGuiVisible() then
        return false
    end

    return vehicle.getIsEnteredForInput ~= nil and vehicle:getIsEnteredForInput()
end


function ADS_ThrottleControl.onAdjustmentAction(vehicle, actionName, inputValue, callbackState, isAnalog, isMouse, deviceCategory, binding)
    local spec = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    if spec == nil then
        return
    end

    local value = tonumber(inputValue) or 0
    local isPressed = binding ~= nil and binding.isPressed == true
    spec.throttleAdjustmentPressed = isPressed or value > 0.5

    if not spec.throttleAdjustmentPressed then
        spec.throttleAdjustmentModeActive = false
    end
end


function ADS_ThrottleControl.setAcceleratorPedalLimit(vehicle, value, noEventSend)
    local spec = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    if spec == nil then
        return
    end

    local clampedValue = math.clamp(tonumber(value) or 1.0, 0.0, 1.0)
    if math.abs(clampedValue - (tonumber(spec.acceleratorPedalLimit) or 1.0)) < 0.0001 then
        return
    end

    spec.acceleratorPedalLimit = clampedValue

    if noEventSend ~= true and ADS_AcceleratorPedalLimitEvent ~= nil then
        ADS_AcceleratorPedalLimitEvent.send(vehicle, clampedValue)
    end
end


function ADS_ThrottleControl.update(vehicle)
    local spec = vehicle ~= nil and vehicle.spec_AdvancedDamageSystem or nil
    if spec == nil or not vehicle.isClient then
        return
    end

    local isControlled = vehicle.getIsEnteredForInput ~= nil and vehicle:getIsEnteredForInput()
    if isControlled and Input ~= nil and Input.KEY_lctrl ~= nil then
        local isFullThrottlePressed = Input.isKeyPressed(Input.KEY_lctrl)
        if spec.fullThrottleOverridePressed ~= isFullThrottlePressed then
            spec.fullThrottleOverridePressed = isFullThrottlePressed
            ADS_FullThrottleEvent.send(vehicle, isFullThrottlePressed)
        end
    end

    local isActive = ADS_ThrottleControl.isAdjustmentModeActive(vehicle)
    spec.throttleAdjustmentModeActive = isActive
    if not isActive then
        return
    end

    local direction = 0
    if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) then
        direction = 1
    elseif Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) then
        direction = -1
    end

    if direction ~= 0 then
        ADS_ThrottleControl.setAcceleratorPedalLimit(
            vehicle,
            (tonumber(spec.acceleratorPedalLimit) or 1.0) + direction * ADS_ThrottleControl.STEP
        )
    end
end


local function isCameraControlBlocked(camera)
    local vehicle = camera ~= nil and camera.vehicle or nil
    return ADS_ThrottleControl.isAdjustmentModeActive(vehicle)
end


function ADS_ThrottleControl.installCameraHooks()
    if ADS_ThrottleControl.cameraHooksInstalled or VehicleCamera == nil then
        return
    end

    VehicleCamera.zoomSmoothly = Utils.overwrittenFunction(
        VehicleCamera.zoomSmoothly,
        function(camera, superFunc, ...)
            if isCameraControlBlocked(camera) then
                return
            end
            return superFunc(camera, ...)
        end
    )

    ADS_ThrottleControl.cameraHooksInstalled = true
end
