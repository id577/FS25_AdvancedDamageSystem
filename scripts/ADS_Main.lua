ADS_Main = {}

source(g_currentModDirectory .. "scripts/ADS_Config.lua")
source(g_currentModDirectory .. "scripts/ADS_Utils.lua")
source(g_currentModDirectory .. "scripts/ADS_Breakdowns.lua")
source(g_currentModDirectory .. "scripts/ADS_WorkshopDialog.lua")
source(g_currentModDirectory .. "scripts/ADS_Hud.lua")
source(g_currentModDirectory .. "scripts/ADS_InGameSettings.lua")
source(g_currentModDirectory .. "events/ADS_VehicleChangeStatusEvent.lua")
source(g_currentModDirectory .. "events/ADS_WorkshopChangeStatusEvent.lua")


local function log_dbg(...)
    if ADS_Config.DEBUG then
        local args = {...}
        for i = 1, #args do
            args[i] = tostring(args[i])
        end
        print("[ADS_MAIN] " .. table.concat(args, " "))
    end
end

-- ===========================================================
--                   SPECIALIZATION REGISTRATION
-- ===========================================================

function ADS_Main.initSpec()
    g_specializationManager:addSpecialization("AdvancedDamageSystem", "AdvancedDamageSystem", g_currentModDirectory.."scripts/ADS_Specialization.lua", "")
    TypeManager.finalizeTypes = Utils.appendedFunction(TypeManager.finalizeTypes, ADS_Main.registerSpecializationToVehicles)
end

function ADS_Main.registerSpecializationToVehicles()
	local specName = "AdvancedDamageSystem"
	for vehicleType, vehicle in pairs(g_vehicleTypeManager.types) do
		if vehicle ~= nil and 
            not string.find(string.lower(vehicleType), "handtool") and
            not string.find(string.lower(vehicleType), "pushable") and
            not string.find(vehicleType, "FS25_lsfmFarmEquipmentPack") and
            not string.find(vehicleType, "FS25_FillablePallet")  and
            vehicleType ~= "inlineWrapper" and 
            vehicleType ~= "locomotive" and 
            vehicleType ~= "сonveyorBelt" and 
            vehicleType ~= "pickupConveyorBelt" and 
            vehicleType ~= "woodCrusherTrailermotorized" and 
            vehicleType ~= "baleWrapper" and 
            vehicleType ~= "craneTrailer" and
            vehicleType ~= "highPressureWasher" then

			local ismotorized = false;
			local hasNotADS = true;
			for name, spec in pairs(vehicle.specializationsByName) do
				if name == "motorized" then
					ismotorized = true;
				elseif name == "AdvancedDamageSystem" then
					hasNotADS = false;
				end
			end
			if hasNotADS and ismotorized then
				local specObject = g_specializationManager:getSpecializationObjectByName(specName);
				if specObject then
                    vehicle.specializationsByName[specName] = specObject;
				    table.insert(vehicle.specializationNames, specName);
				    table.insert(vehicle.specializations, specObject);
                end
			end
		end
	end
    log_dbg("Specialization applied!")
end

-- ==========================================================
--             HUD, GUI and Workshop Screen Reg
-- ==========================================================

function ADS_Main:onStartMission()

    ADS_WorkshopDialog.register()

    local mission = g_currentMission
    ADS_Main.hud = ADS_Hud:new()
    ADS_Main.hud:setScale(g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE))
	ADS_Main.hud:setVehicle(nil)

	table.insert(mission.hud.displayComponents, ADS_Main.hud)

	mission.hud.setControlledVehicle = Utils.appendedFunction(mission.hud.setControlledVehicle, function(self, vehicle)
		ADS_Main.hud:setVehicle(vehicle)
		ADS_Main.hud:setVisible(vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil, true)
	end)

	mission.hud.drawControlledEntityHUD = Utils.appendedFunction(mission.hud.drawControlledEntityHUD, function(self)
		ADS_Main.hud:draw()
	end)

    -- spec list damage fix (store and garage overwiev)
    for _, spec in ipairs(g_storeManager.specTypes) do
        print(spec.name)
        if spec.name == 'wearable' then
            local origFunc = spec.getValueFunc
            spec.getValueFunc = function(s, v)
                if v ~= nil and v.spec_AdvancedDamageSystem ~= nil then
                    return v:getFormattedLastMaintenanceText() 
                else
                    return origFunc(s, v)
                end
            end
        end
    end
end


function ADS_Main.onCustomRepairClick(screenInstance)
    ADS_WorkshopDialog.show(screenInstance.vehicle)
end

-- workshop repairButton control for ADS vehicles
function ADS_Main.hookRepairButton(screenInstance, vehicle)
    if screenInstance.ads_originalRepairCallback == nil and screenInstance.repairButton.onClickCallback ~= nil then
        screenInstance.ads_originalRepairCallback = screenInstance.repairButton.onClickCallback
    end
    if vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil then
        screenInstance.repairButton.onClickCallback = function()           
            ADS_Main.onCustomRepairClick(screenInstance)
        end
        screenInstance.repairButton:setDisabled(false)
    else
        screenInstance.repairButton.onClickCallback = screenInstance.ads_originalRepairCallback
    end
end


local function getReliability(storeItem)
    if storeItem.specs.power ~= nil then
        local reliability = AdvancedDamageSystem.getBrandReliability(nil, storeItem)
        return AdvancedDamageSystem.reliabilityValueToText(reliability)
    end
end

local function getMaintainability(storeItem)
    if storeItem.specs.power ~= nil then
        local _, maintainability = AdvancedDamageSystem.getBrandReliability(nil, storeItem)
        return AdvancedDamageSystem.maintainabilityValueToText(maintainability)
    end
end

-- adds spec while browsing
g_storeManager:addSpecType("reliability", "shopListAttributeIconReliability", nil, getReliability, StoreSpecies.VEHICLE)
g_storeManager:addSpecType("maintainability", "shopListAttributeIconMaintainability", nil, getMaintainability, StoreSpecies.VEHICLE)


-- adds spec in config screen 
function ADS_Main.processAttributeData(self, storeItem, vehicle, saleItem)
    if vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil then
        local reliabilityItemElement = self.attributeItem:clone(self.attributesLayout)
        local reliabilityIconElement = reliabilityItemElement:getDescendantByName("icon")
        local reliabilityTextElement = reliabilityItemElement:getDescendantByName("text")

        local rel, mel = AdvancedDamageSystem.getBrandReliability(vehicle, nil)
        reliabilityIconElement:applyProfile("shopConfigAttributeIconReliability")
        reliabilityTextElement:setText(AdvancedDamageSystem.reliabilityValueToText(rel))
        self.attributesLayout:invalidateLayout()

        local maintainabilityItemElement = self.attributeItem:clone(self.attributesLayout)
        local maintainabilityIconElement = maintainabilityItemElement:getDescendantByName("icon")
        local maintainabilityTextElement = maintainabilityItemElement:getDescendantByName("text")

        maintainabilityIconElement:applyProfile("shopConfigAttributeIconMaintainability")
        maintainabilityTextElement:setText(AdvancedDamageSystem.maintainabilityValueToText(mel))
        self.attributesLayout:invalidateLayout()
    end
end

-- workshop condition bar fix
function ADS_Main.setStatusBarValue(screenInstance, superFunc, bar, value)
    local vehicle = nil

    for _, v in screenInstance.vehicles do
        if v:getDamageAmount() == 1 - value then
            vehicle = v
        end
    end

    if vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil then
        local cs = vehicle.spec_AdvancedDamageSystem.lastInspectedConditionState
        if cs == AdvancedDamageSystem.STATES.UNKNOWN or cs == AdvancedDamageSystem.STATES.EXCELLENT then value = 1.0
        elseif cs == AdvancedDamageSystem.STATES.GOOD then value = 0.75
        elseif cs == AdvancedDamageSystem.STATES.NORMAL then value = 0.5
        elseif cs == AdvancedDamageSystem.STATES.BAD then value = 0.25
        else value = 0.0 end
    end
    superFunc(screenInstance, bar, value)
end

-- garage overwiev fix
function ADS_Main.populateCellForItemInSection(self, superFunc, list, section, index, cell)
    if list.id == 'vehiclesList' then
        local vehicle = self.vehicles[index].vehicle
        if vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil then
            superFunc(self, list, section, index, cell)
            local condition = vehicle.spec_AdvancedDamageSystem.lastInspectedConditionState
            cell:getAttribute("damage"):setText(g_i18n:getText(condition))
            cell:getAttribute("damage"):setTextColor(AdvancedDamageSystem.getTextColour(condition))
        else
            superFunc(self, list, section, index, cell)
        end
    else
        superFunc(self, list, section, index, cell)
    end
end


FSBaseMission.onStartMission = Utils.prependedFunction(FSBaseMission.onStartMission, ADS_Main.onStartMission)
WorkshopScreen.setVehicle = Utils.appendedFunction(WorkshopScreen.setVehicle, ADS_Main.hookRepairButton)
WorkshopScreen.setStatusBarValue = Utils.overwrittenFunction(WorkshopScreen.setStatusBarValue, ADS_Main.setStatusBarValue)
InGameMenuStatisticsFrame.populateCellForItemInSection = Utils.overwrittenFunction(InGameMenuStatisticsFrame.populateCellForItemInSection, ADS_Main.populateCellForItemInSection)
ShopConfigScreen.processAttributeData = Utils.appendedFunction(ShopConfigScreen.processAttributeData, ADS_Main.processAttributeData)


ADS_Main.initSpec()

-- ==========================================================
--                        CORE UPDATE
-- ==========================================================

ADS_Main.vehicles = {}
ADS_Main.numVehicles = 0
ADS_Main.previousKey = nil
ADS_Main.updateAlphaTimer = 0
ADS_Main.workshopCheckTimer = 0
ADS_Main.isWorkshopOpen = true

function ADS_Main:update(dt)
    if not g_currentMission:getIsServer() or self.numVehicles == 0 then
        self.previousKey = nil 
        return
    end
        
    self.updateAlphaTimer = self.updateAlphaTimer + dt
    self.workshopCheckTimer = self.workshopCheckTimer + dt

    --- workshop
    if self.workshopCheckTimer >= ADS_Config.CORE_UPDATE_DELAY then
        local currentDayHour = g_currentMission.environment.dayTime / (60 * 60 * 1000)
        local isWorkshopOpen = currentDayHour >= ADS_Config.WORKSHOP.OPEN_HOUR and currentDayHour < ADS_Config.WORKSHOP.CLOSE_HOUR
        if isWorkshopOpen ~= self.isWorkshopOpen then
            self.isWorkshopOpen = isWorkshopOpen
            ADS_WorkshopChangeStatusEvent.send(ADS_VehicleChangeStatusEvent.new(self.isWorkshopOpen))
        end
         self.workshopCheckTimer = self.workshopCheckTimer - ADS_Config.CORE_UPDATE_DELAY 
    end

    --- vehicles
    local timePerVehicle = ADS_Config.CORE_UPDATE_DELAY / self.numVehicles
    local vehiclesToUpdate = math.floor(self.updateAlphaTimer / timePerVehicle)

    if vehiclesToUpdate < 1 then
        return
    end

    for i = 1, vehiclesToUpdate do
        local vehicle = nil
        self.previousKey, vehicle = next(self.vehicles, self.previousKey)

        if self.previousKey == nil and self.numVehicles > 0 then
             self.previousKey, vehicle = next(self.vehicles)
        end
        
        if vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil then
            vehicle:adsUpdate(ADS_Config.CORE_UPDATE_DELAY, self.isWorkshopOpen)

            --- meta
            local spec = vehicle.spec_AdvancedDamageSystem
            spec.metaUpdateTimer = spec.metaUpdateTimer + ADS_Config.CORE_UPDATE_DELAY
            if spec.metaUpdateTimer > ADS_Config.META_UPDATE_DELAY then
                vehicle:processPermanentEffects(spec.metaUpdateTimer)
                spec.metaUpdateTimer = spec.metaUpdateTimer - ADS_Config.META_UPDATE_DELAY
            end
        end
    end
    self.updateAlphaTimer = self.updateAlphaTimer - vehiclesToUpdate * timePerVehicle
end

addModEventListener(ADS_Main)


