ADS_Main = {}

local modDirectory = g_currentModDirectory
local modName = g_currentModName

source(g_currentModDirectory .. "scripts/ADS_Config.lua")
source(g_currentModDirectory .. "scripts/ADS_Utils.lua")
source(g_currentModDirectory .. "scripts/ADS_Breakdowns.lua")
source(g_currentModDirectory .. "scripts/ADS_Leasing.lua")
source(g_currentModDirectory .. "gui/ADS_WorkshopDialog.lua")
source(g_currentModDirectory .. "gui/ADS_MaintenanceLogDialog.lua")
source(g_currentModDirectory .. "gui/ADS_ReportDialog.lua")
source(g_currentModDirectory .. "gui/ADS_InspectionDialog.lua")
source(g_currentModDirectory .. "gui/ADS_SellItemDialog.lua")
source(g_currentModDirectory .. "gui/ADS_InGameMenuFrame.lua")
source(g_currentModDirectory .. "gui/ADS_MaintenanceTwoOptionsDialog.lua")
source(g_currentModDirectory .. "gui/ADS_MaintenanceThreeOptionsDialog.lua")
source(g_currentModDirectory .. "scripts/ADS_Hud.lua")
source(g_currentModDirectory .. "scripts/ADS_PlayerInput.lua")
source(g_currentModDirectory .. "scripts/ADS_InGameSettings.lua")
source(g_currentModDirectory .. "events/ADS_VehicleChangeStatusEvent.lua")
source(g_currentModDirectory .. "events/ADS_WorkshopChangeStatusEvent.lua")
source(g_currentModDirectory .. "events/ADS_ServiceRequestEvent.lua")
source(g_currentModDirectory .. "events/ADS_CancelServiceEvent.lua")
source(g_currentModDirectory .. "events/ADS_SettingsSyncEvent.lua")
source(g_currentModDirectory .. "events/ADS_EffectSyncEvent.lua")
source(g_currentModDirectory .. "events/ADS_LogEntrySyncEvent.lua")
source(g_currentModDirectory .. "events/ADS_ConsoleCommandEvent.lua")
source(g_currentModDirectory .. "events/ADS_StartButtonEvent.lua")
source(g_currentModDirectory .. "events/ADS_HandToolSyncEvent.lua")
source(g_currentModDirectory .. "events/ADS_JumperCablesEvent.lua")

-- Network hook: wrap every settings callback so changes made by an admin
-- client are automatically replicated to the dedicated server (and then
-- re-broadcast to all other clients via ADS_SettingsSyncEvent).
do
    local cbs = {
        "onServiceWearChanged", "onConditionWearChanged", "onDowntimeWearChanged", "onGeneralWearEnabledChanged",
        "onSystemStressRateChanged", "onInstantInspectionChanged", "onParkVehicleChanged", "onWarrantyEnabledChanged",
        "onMaintenancePriceChanged", "onMaintenanceDurationChanged", "onWorkshopAvailableChanged",
        "onWorkshopOpenHourChanged", "onWorkshopCloseHourChanged", "onThermalSensitivityChanged",
        "onBatteryCapacityChanged", "onCloggingSpeedChanged", "onAiOverloadAndOverheatControlChanged", "onDebugModeChanged"
    }
    for _, name in ipairs(cbs) do
        local orig = ADS_InGameSettings[name]
        if orig ~= nil then
            ADS_InGameSettings[name] = function(self, ...)
                orig(self, ...)
                if g_currentMission ~= nil then
                    if g_currentMission:getIsServer() and g_server ~= nil then
                        g_server:broadcastEvent(ADS_SettingsSyncEvent.new())
                    elseif g_client ~= nil then
                        ADS_SettingsSyncEvent.send()
                    end
                end
            end
        end
    end
end


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
            not string.find(vehicleType, "FS25_ASM_FarmyardTrailerDolly")  and
            vehicleType ~= "motorbike" and 
            vehicleType ~= "inlineWrapper" and 
            vehicleType ~= "locomotive" and 
            vehicleType ~= "сonveyorBelt" and 
            vehicleType ~= "pickupConveyorBelt" and 
            vehicleType ~= "woodCrusherTrailermotorized" and 
            vehicleType ~= "baleWrapper" and 
            vehicleType ~= "craneTrailer" and
            vehicleType ~= "highPressureWasher" and
            vehicleType ~= "pdlc_highlandsFishingPack.cargoBoat" and
            vehicleType ~= "pdlc_highlandsFishingPack.boat" then

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

-- ===========================================================
--                  HANDTOOLS REGISTRATION
-- ===========================================================

local htPath = modDirectory .. "xml/handTools.xml"
local xmlFile = XMLFile.loadIfExists("adsHandTools", htPath)

if xmlFile ~= nil then
    xmlFile:iterate("handTools.specializations.specialization", function(_, key)
        local name = xmlFile:getString(key .. "#name")
        local className = xmlFile:getString(key .. "#className")
        local filename = xmlFile:getString(key .. "#filename")

        g_handToolSpecializationManager:addSpecialization(name, className, modDirectory .. filename)
    end)

    xmlFile:iterate("handTools.types.type", function(_, key)
        g_handToolTypeManager:loadTypeFromXML(xmlFile.handle, key, false, nil, modName)
    end)

    xmlFile:delete()
end


-- ==========================================================
--             HUD, GUI and Workshop Screen Reg
-- ==========================================================

function ADS_Main:onStartMission()
    self.shopMenuPageInstalled = false
    self.shopMenuFrame = nil

    ADS_WorkshopDialog.register()
    ADS_MaintenanceLogDialog.register()
    ADS_ReportDialog.register()
    ADS_InspectionDialog.register()
    ADS_SellItemDialog.register()
    ADS_MaintenanceTwoOptionsDialog.register()
    ADS_MaintenanceThreeOptionsDialog.register()

    local mission = g_currentMission
    ADS_Main.hud = ADS_Hud:new()
    ADS_Main.hud:setScale(g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE))
	ADS_Main.hud:setVehicle(nil)

	table.insert(mission.hud.displayComponents, ADS_Main.hud)

	mission.hud.setControlledVehicle = Utils.appendedFunction(mission.hud.setControlledVehicle, function(self, vehicle)
		ADS_Main.hud:setVehicle(vehicle)
		ADS_Main.hud:setVisible(vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil and not vehicle.spec_AdvancedDamageSystem.isExcludedVehicle, true)
	end)

	mission.hud.drawControlledEntityHUD = Utils.appendedFunction(mission.hud.drawControlledEntityHUD, function(self)
		ADS_Main.hud:draw()
	end)

    -- spec list damage fix (store and garage overwiev)
    for _, spec in ipairs(g_storeManager.specTypes) do
        if spec.name == 'wearable' then
            local origFunc = spec.getValueFunc
            spec.getValueFunc = function(s, v)
                if v ~= nil and v.spec_AdvancedDamageSystem ~= nil and not v.spec_AdvancedDamageSystem.isExcludedVehicle then
                    return ADS_Utils.formatTimeAgo(v:getLastMaintenanceDate())
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
    if vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil and not vehicle.spec_AdvancedDamageSystem.isExcludedVehicle then
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
        return ADS_Utils.formatReliability(reliability)
    end
end

local function getMaintainability(storeItem)
    if storeItem.specs.power ~= nil then
        local _, maintainability = AdvancedDamageSystem.getBrandReliability(nil, storeItem)
        return ADS_Utils.formatMaintainability(maintainability)
    end
end

-- adds spec while browsing
    g_storeManager:addSpecType("reliability", "shopListAttributeIconReliability", nil, getReliability, StoreSpecies.VEHICLE)
g_storeManager:addSpecType("maintainability", "shopListAttributeIconMaintainability", nil, getMaintainability, StoreSpecies.VEHICLE)

function ADS_Main.addShopMenuPage(frame, pageName, uvs, predicateFunc, insertAfter)
    local targetPosition = 0

    g_shopMenu.controlIDs[pageName] = nil

    for i = 1, #g_shopMenu.pagingElement.elements do
        local child = g_shopMenu.pagingElement.elements[i]
        if child == g_shopMenu[insertAfter] then
            targetPosition = i + 1
            break
        end
    end

    if targetPosition == 0 then
        targetPosition = #g_shopMenu.pagingElement.elements + 1
    end

    g_shopMenu[pageName] = frame
    g_shopMenu.pagingElement:addElement(g_shopMenu[pageName])
    g_shopMenu:exposeControlsAsFields(pageName)

    for i = 1, #g_shopMenu.pagingElement.elements do
        local child = g_shopMenu.pagingElement.elements[i]
        if child == g_shopMenu[pageName] then
            table.remove(g_shopMenu.pagingElement.elements, i)
            table.insert(g_shopMenu.pagingElement.elements, targetPosition, child)
            break
        end
    end

    for i = 1, #g_shopMenu.pagingElement.pages do
        local child = g_shopMenu.pagingElement.pages[i]
        if child.element == g_shopMenu[pageName] then
            table.remove(g_shopMenu.pagingElement.pages, i)
            table.insert(g_shopMenu.pagingElement.pages, targetPosition, child)
            break
        end
    end

    g_shopMenu.pagingElement:updateAbsolutePosition()
    g_shopMenu.pagingElement:updatePageMapping()
    g_shopMenu:registerPage(g_shopMenu[pageName], nil, predicateFunc)
    g_shopMenu:addPageTab(g_shopMenu[pageName], Utils.getFilename("images/menuIcon.dds", modDirectory), GuiUtils.getUVs(uvs))

    for i = 1, #g_shopMenu.pageFrames do
        local child = g_shopMenu.pageFrames[i]
        if child == g_shopMenu[pageName] then
            table.remove(g_shopMenu.pageFrames, i)
            table.insert(g_shopMenu.pageFrames, targetPosition, child)
            break
        end
    end

    g_shopMenu:rebuildTabList()
end

function ADS_Main:tryRegisterShopMenuPage()
    if self.shopMenuPageInstalled then
        return true
    end

    if ADS_InGameMenuFrame == nil or g_shopMenu == nil then
        return false
    end

    if g_shopMenu[ADS_InGameMenuFrame.PAGE_NAME] ~= nil then
        self.shopMenuPageInstalled = true
        return true
    end

    local frame = ADS_InGameMenuFrame.register()
    ADS_Main.addShopMenuPage(frame, ADS_InGameMenuFrame.PAGE_NAME, {0, 0, 1024, 1024}, function()
        return true
    end, "pageUsedSale")
    frame:initialize()

    self.shopMenuFrame = frame
    self.shopMenuPageInstalled = true
    return true
end


-- adds spec in config screen 
function ADS_Main.processAttributeData(self, storeItem, vehicle, saleItem)
    if vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil and not vehicle.spec_AdvancedDamageSystem.isExcludedVehicle then
        local reliabilityItemElement = self.attributeItem:clone(self.attributesLayout)
        local reliabilityIconElement = reliabilityItemElement:getDescendantByName("icon")
        local reliabilityTextElement = reliabilityItemElement:getDescendantByName("text")

        local rel, mel = AdvancedDamageSystem.getBrandReliability(vehicle, nil)
        reliabilityIconElement:applyProfile("shopConfigAttributeIconReliability")
        reliabilityTextElement:setText(ADS_Utils.formatReliability(rel))
        self.attributesLayout:invalidateLayout()

        local maintainabilityItemElement = self.attributeItem:clone(self.attributesLayout)
        local maintainabilityIconElement = maintainabilityItemElement:getDescendantByName("icon")
        local maintainabilityTextElement = maintainabilityItemElement:getDescendantByName("text")

        maintainabilityIconElement:applyProfile("shopConfigAttributeIconMaintainability")
        maintainabilityTextElement:setText(ADS_Utils.formatMaintainability(mel))
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

    if vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil and not vehicle.spec_AdvancedDamageSystem.isExcludedVehicle then
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
        if vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil and not vehicle.spec_AdvancedDamageSystem.isExcludedVehicle then
            superFunc(self, list, section, index, cell)
            local condition, isCompleteInspection = vehicle:getLastInspectedCondition()
            cell:getAttribute("damage"):setText(ADS_Utils.formatCondition(condition, isCompleteInspection))
            cell:getAttribute("damage"):setTextColor(ADS_Utils.getValueColor(condition, 0.8, 0.6, 0.4, 0.2, false))
        else
            superFunc(self, list, section, index, cell)
        end
    else
        superFunc(self, list, section, index, cell)
    end
end


FSBaseMission.onStartMission = Utils.prependedFunction(FSBaseMission.onStartMission, ADS_Main.onStartMission)
FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, ADS_Config.saveToXMLFile)
Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, function()
    log_dbg("Mission00.loadMission00Finished hook fired")
    ADS_Config.loadFromXMLFile()
end)
FSBaseMission.sendInitialClientState = Utils.appendedFunction(FSBaseMission.sendInitialClientState, function(_, connection)
    if g_server ~= nil then
        connection:sendEvent(ADS_SettingsSyncEvent.new())
    end
end)
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
ADS_Main.currentWeather = WeatherType.SUN
ADS_Main.currentWeatherFactor = 1.0
ADS_Main.samples = ADS_Main.samples or {}

local xmlFile = loadXMLFile("adsSounds2D", Utils.getFilename("sounds/ads_sounds.xml", g_currentModDirectory))
ADS_Main.samples.maintenanceCompleted2D = g_soundManager:loadSample2DFromXML(xmlFile, "sounds", "maintenanceCompleted2D", g_currentModDirectory, 1, AudioGroup.GUI)

-- Compute workshop open/close from config hours and current game time.
-- Runs on all machines for consistent local state.
function ADS_Main:evaluateWorkshopState()
    if g_currentMission == nil or g_currentMission.environment == nil then
        return self.isWorkshopOpen
    end
    local currentDayHour = g_currentMission.environment.dayTime / (60 * 60 * 1000)
    return ADS_Config.WORKSHOP.ALWAYS_AVAILABLE
        or (currentDayHour >= ADS_Config.WORKSHOP.OPEN_HOUR
        and currentDayHour < ADS_Config.WORKSHOP.CLOSE_HOUR)
end


-- Re-evaluate and broadcast workshop state immediately (settings change).
function ADS_Main:forceWorkshopUpdate()
    local isWorkshopOpen = self:evaluateWorkshopState()
    if isWorkshopOpen ~= self.isWorkshopOpen then
        self.isWorkshopOpen = isWorkshopOpen
        if g_currentMission:getIsServer() then
            ADS_WorkshopChangeStatusEvent.send(self.isWorkshopOpen)
        end
        g_messageCenter:publish(MessageType.ADS_WORKSHOP_CHANGE_STATUS, self.isWorkshopOpen)
    end
end


function ADS_Main:update(dt)
    if g_currentMission ~= nil and g_currentMission.getIsClient ~= nil and g_currentMission:getIsClient() then
        if not self.shopMenuPageInstalled then
            self:tryRegisterShopMenuPage()
        end
    end

    local function updateOpenWorkshopDialog()
        local dialog = ADS_WorkshopDialog.INSTANCE
        if dialog == nil or not dialog.isDialogOpen or dialog.vehicle == nil or dialog.vehicle.spec_AdvancedDamageSystem == nil then
            return
        end

        local currentStatus = dialog.vehicle:getCurrentStatus()
        if dialog.lastObservedStatus ~= currentStatus then
            dialog:updateScreen()
        elseif currentStatus ~= AdvancedDamageSystem.STATUS.READY then
            dialog:updateServiceProgressText()
        end
    end

    --- workshop
    self.workshopCheckTimer = self.workshopCheckTimer + dt
    if self.workshopFirstEval == nil or self.workshopCheckTimer >= ADS_Config.CORE_UPDATE_DELAY then
        self.workshopFirstEval = true
        self:forceWorkshopUpdate()
        if self.workshopCheckTimer >= ADS_Config.CORE_UPDATE_DELAY then
            self.workshopCheckTimer = self.workshopCheckTimer - ADS_Config.CORE_UPDATE_DELAY
        end
    end

    if not g_currentMission:getIsServer() or self.numVehicles == 0 then
        self.previousKey = nil
        updateOpenWorkshopDialog()
        return
    end

    self.updateAlphaTimer = self.updateAlphaTimer + dt

    --- vehicles
    local timePerVehicle = ADS_Config.CORE_UPDATE_DELAY / self.numVehicles
    local vehiclesToUpdate = math.floor(self.updateAlphaTimer / timePerVehicle)

    if vehiclesToUpdate < 1 then
        updateOpenWorkshopDialog()
        return
    end

    for i = 1, vehiclesToUpdate do
        local vehicle = nil
        self.previousKey, vehicle = next(self.vehicles, self.previousKey)

        if self.previousKey == nil and self.numVehicles > 0 then
             self.previousKey, vehicle = next(self.vehicles)
        end
        
        if vehicle ~= nil and vehicle.spec_AdvancedDamageSystem ~= nil and not vehicle.spec_AdvancedDamageSystem.isExcludedVehicle then
            vehicle:adsUpdate(ADS_Config.CORE_UPDATE_DELAY, self.isWorkshopOpen)

            --- meta
            local spec = vehicle.spec_AdvancedDamageSystem
            spec.metaUpdateTimer = spec.metaUpdateTimer + ADS_Config.CORE_UPDATE_DELAY
            if spec.metaUpdateTimer > ADS_Config.META_UPDATE_DELAY then

                if g_currentMission ~= nil and g_currentMission.environment ~= nil and g_currentMission.environment.weather ~= nil then
                    ADS_Main.currentWeather = g_currentMission.environment.weather:getCurrentWeatherType()
                    if ADS_Main.currentWeather == WeatherType.RAIN then
                        ADS_Main.currentWeatherFactor = ADS_Config.CORE.RAIN_FACTOR or 1.0
                    elseif ADS_Main.currentWeather == WeatherType.SNOW then
                        ADS_Main.currentWeatherFactor = ADS_Config.CORE.SNOW_FACTOR or 1.0
                    elseif ADS_Main.currentWeather == WeatherType.HAIL then
                        ADS_Main.currentWeatherFactor = ADS_Config.CORE.HALL_FACTOR or 1.0
                    else
                        ADS_Main.currentWeatherFactor = 1.0
                    end
                end

                if not vehicle:getIsOperating() then
                    spec.isUnderRoof = vehicle:isUnderRoof()
                end

                spec.metaUpdateTimer = spec.metaUpdateTimer - ADS_Config.META_UPDATE_DELAY
  
            end
        end
    end
    self.updateAlphaTimer = self.updateAlphaTimer - vehiclesToUpdate * timePerVehicle
    updateOpenWorkshopDialog()
end

function ADS_Main:loadMap()
    log_dbg("loadMap() called")
    self.shopMenuPageInstalled = false
    self.shopMenuFrame = nil
    ADS_Config.loadFromXMLFile()
    self:tryRegisterShopMenuPage()
end

function ADS_Main:deleteMap()
    self.shopMenuPageInstalled = false
    self.shopMenuFrame = nil
    ADS_Config._loaded = nil
end

addModEventListener(ADS_Main)


