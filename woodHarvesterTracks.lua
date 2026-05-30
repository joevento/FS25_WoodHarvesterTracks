--
-- Wood Harvester Tracks for FS19
-- @author:    	kenny456 (kenny456@seznam.cz)
-- @history:	v1.0.0.0 - 2020-08-31 - first release
--
WoodHarvesterTracks = {}
WoodHarvesterTracks.confDir = getUserProfileAppPath().. "modSettings/FS25_WoodHarvesterTracks/"
WoodHarvesterTracks.modDirectory = g_currentModDirectory

function WoodHarvesterTracks.prerequisitesPresent(specializations)
	return true
end
function WoodHarvesterTracks.registerOverwrittenFunctions(vehicleType)
end

function WoodHarvesterTracks.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "groundRaycastCallbackNew", 			WoodHarvesterTracks.groundRaycastCallbackNew)
	SpecializationUtil.registerFunction(vehicleType, "toggleActiveWoodHarvesterTracks", 		WoodHarvesterTracks.toggleActiveWoodHarvesterTracks)
	SpecializationUtil.registerFunction(vehicleType, "getHasDttImplement", 					WoodHarvesterTracks.getHasDttImplement)
	SpecializationUtil.registerFunction(vehicleType, "activateDttMod", 						WoodHarvesterTracks.activateDttMod)
	SpecializationUtil.registerFunction(vehicleType, "saveToXmlWoodHarvesterTracks", 				WoodHarvesterTracks.saveToXmlWoodHarvesterTracks)
	SpecializationUtil.registerFunction(vehicleType, "loadFromXmlWoodHarvesterTracks", 			WoodHarvesterTracks.loadFromXmlWoodHarvesterTracks)
end
function WoodHarvesterTracks:onRegisterActionEvents(isSelected, isOnActiveVehicle)
	local spec = self.spec_woodHarvesterTracks
	if not spec.modInitialized then
		return
	end
	
	self:loadFromXmlWoodHarvesterTracks(self:getFullName())
	
	if self.isServer then
		self:toggleActiveWoodHarvesterTracks(spec.modActive, WoodHarvesterTracks.modActive, false)
	end
	if g_dedicatedServerInfo ~= nil then
		return
	end
	if spec.event_IDs == nil then
		spec.event_IDs = {}
	end
	if self:getIsActive() and (self:getIsActiveForInput() or not self:getHasDttImplement()) then
		local actions = { InputAction.WOODHARVESTERTRACK_ACTIVATE, InputAction.WOODHARVESTERTRACK_ACTIVATE_ALL }
		for _,actionName in pairs(actions) do
			local always = false
			local _, eventID = g_inputBinding:registerActionEvent(actionName, self, WoodHarvesterTracks.actionCallback, true, true, always, true)
			spec.event_IDs[actionName] = eventID
			if g_inputBinding ~= nil and g_inputBinding.events ~= nil and g_inputBinding.events[eventID] ~= nil then
				if actionName == 'something with lower priority' then
					g_inputBinding:setActionEventTextPriority(eventID, GS_PRIO_NORMAL)
				else
					g_inputBinding:setActionEventTextPriority(eventID, GS_PRIO_VERY_HIGH)
				end
				g_inputBinding:setActionEventTextVisibility(eventID, WoodHarvesterTracks.showHelp)
			end
			local colliding = false
			_, colliding, _ = g_inputBinding:checkEventCollision(actionName)
			if colliding then
				if g_inputBinding.nameActions[actionName].bindings[1] ~= nil then
					if g_inputBinding.nameActions[actionName].bindings[1].inputString ~= nil then
						print(string.format('Warning: WoodHarvesterTracks got a colliding input action: %s', actionName)..' ('..g_inputBinding.nameActions[actionName].bindings[1].inputString..'). You can remap it in controls settings')
					end
				else
					print(string.format('Warning: WoodHarvesterTracks got a colliding input action: %s', actionName))
				end
			end
		end
	end
end
function WoodHarvesterTracks.registerEventListeners(vehicleType)
	for _,n in pairs( { "onLoad", "onPostLoad", "onUpdate", "onRegisterActionEvents", "toggleActiveWoodHarvesterTracks", "activateDttMod", "onReadStream", "onWriteStream", "saveToXmlWoodHarvesterTracks", "loadFromXmlWoodHarvesterTracks"} ) do
		SpecializationUtil.registerEventListener(vehicleType, n, WoodHarvesterTracks)
	end
end
function WoodHarvesterTracks:onLoad(savegame)
	self.spec_woodHarvesterTracks = {}
	local spec = self.spec_woodHarvesterTracks
	
	WoodHarvesterTracks.showHelp = true
	WoodHarvesterTracks.modActive = true
	spec.event_IDs = {}
	spec.modInitialized = false
	spec.modAllowed = false
	spec.modActive = false
	spec.groundRaycastResult = {}
    spec.groundRaycastResult.y = 0.0
    spec.groundRaycastResult.object = nil
    spec.groundRaycastResult.distance = 0.0
	if self.spec_wheels ~= nil and self.spec_wheels.wheels ~= nil then
		spec.modInitialized = true
	end
	if not spec.modInitialized then
		print("Error: WoodHarvesterTracks initialization failed for "..tostring(self:getFullName()).." !")
		return
	end
	local hasTireTracks = false
	local hasParticles = false
	local count = 0
	for _,wheel in pairs(self.spec_wheels.wheels) do
		if wheel.hasTireTracks then
			hasTireTracks = true
		end
		if wheel.hasParticles then
			hasParticles = true
		end
		count = count + 1
	end
	if (hasTireTracks or hasParticles) and count > 0 then
		spec.modAllowed = true
	end
	spec.infoText = ''
	if self.spec_washable ~= nil then
		spec.fieldMultiplierOrig =  self.spec_washable.fieldMultiplier
	end
	spec.timer = 0
	
	local configFile = WoodHarvesterTracks.confDir .. "WoodHarvesterTracksConfig.xml"
	if fileExists(configFile) then
		self:loadFromXmlWoodHarvesterTracks(self:getFullName())
	else
		createFolder(getUserProfileAppPath().. "modSettings/")
		createFolder(WoodHarvesterTracks.confDir)
		WoodHarvesterTracks.configXml = createXMLFile("WoodHarvesterTracks_XML", configFile, "WoodHarvesterTracksConfig")
		self:saveToXmlWoodHarvesterTracks()
	end
end
function WoodHarvesterTracks:onPostLoad(savegame)
	local spec = self.spec_woodHarvesterTracks
	if not spec.modInitialized then
		return
	end
	
	if spec.event_IDs == nil then
		spec.event_IDs = {}
	end
	for _,wheel in pairs(self.spec_wheels.wheels) do
		wheel.supportsWheelSinkOrig = wheel.supportsWheelSink
		if wheel.additionalWheels ~= nil then
			for _,additionalWheel in pairs(wheel.additionalWheels) do
				additionalWheel.supportsWheelSinkOrig = additionalWheel.supportsWheelSink
			end
		end
	end
end
function WoodHarvesterTracks:saveToXMLFile(xmlFile, key)
	local spec = self.spec_woodHarvesterTracks
	if not spec.modInitialized then
		return
	end
end
function WoodHarvesterTracks:onDelete()
	local spec = self.spec_woodHarvesterTracks
	if not spec.modInitialized then
		return
	end
end
function WoodHarvesterTracks:loadFromXmlWoodHarvesterTracks(vehicle)
	local spec = self.spec_woodHarvesterTracks
	local configFile = WoodHarvesterTracks.confDir .. "WoodHarvesterTracksConfig.xml"
	if fileExists(configFile) then
		WoodHarvesterTracks.configXml = loadXMLFile("WoodHarvesterTracks_XML", configFile)
	end
	if self.isServer and fileExists(configFile) then
		if getXMLBool(WoodHarvesterTracks.configXml, "WoodHarvesterTracksConfig.showHelp") ~= nil then
			WoodHarvesterTracks.showHelp = getXMLBool(WoodHarvesterTracks.configXml, "WoodHarvesterTracksConfig.showHelp")
		end;
		if getXMLBool(WoodHarvesterTracks.configXml, "WoodHarvesterTracksConfig.modActiveGlobal") ~= nil then
			WoodHarvesterTracks.modActive = getXMLBool(WoodHarvesterTracks.configXml, "WoodHarvesterTracksConfig.modActiveGlobal")
		end
		if vehicle ~= nil then
			local key = "WoodHarvesterTracksConfig.dttActiveVehicles"
			local i = 0
			while true do
				local name = getXMLString(WoodHarvesterTracks.configXml, "WoodHarvesterTracksConfig.dttActiveVehicles"..string.format(".vehicle(%d)", i).."#name")
				if name ~= nil then
					if name == vehicle then
						spec.modActive = getXMLBool(WoodHarvesterTracks.configXml, "WoodHarvesterTracksConfig.dttActiveVehicles"..string.format(".vehicle(%d)", i))
						break
					end
				else
					break
				end
				i = i + 1
			end
		end
	end
end
function WoodHarvesterTracks:saveToXmlWoodHarvesterTracks(vehicle, active)
	local spec = self.spec_woodHarvesterTracks
	
	if WoodHarvesterTracks.configXml ~= nil then
		setXMLBool(WoodHarvesterTracks.configXml, "WoodHarvesterTracksConfig.showHelp", WoodHarvesterTracks.showHelp)
		setXMLBool(WoodHarvesterTracks.configXml, "WoodHarvesterTracksConfig.modActiveGlobal", WoodHarvesterTracks.modActive)
		if vehicle ~= nil and active ~= nil then
			local key = "WoodHarvesterTracksConfig.dttActiveVehicles"
			local i = 0
			while true do
				local name = getXMLString(WoodHarvesterTracks.configXml, "WoodHarvesterTracksConfig.dttActiveVehicles"..string.format(".vehicle(%d)", i).."#name")
				if name ~= nil then
					if name == vehicle then
						setXMLString(WoodHarvesterTracks.configXml, "WoodHarvesterTracksConfig.dttActiveVehicles"..string.format(".vehicle(%d)", i).."#name", vehicle)
						setXMLBool(WoodHarvesterTracks.configXml, "WoodHarvesterTracksConfig.dttActiveVehicles"..string.format(".vehicle(%d)", i), active)
						break
					end
				else
					setXMLString(WoodHarvesterTracks.configXml, "WoodHarvesterTracksConfig.dttActiveVehicles"..string.format(".vehicle(%d)", i).."#name", vehicle)
					setXMLBool(WoodHarvesterTracks.configXml, "WoodHarvesterTracksConfig.dttActiveVehicles"..string.format(".vehicle(%d)", i), active)
					break
				end
				i = i + 1
				local name = key .. string.format(".vehicle(%d)", i)
				if not hasXMLProperty(WoodHarvesterTracks.configXml, name) then
					setXMLString(WoodHarvesterTracks.configXml, "WoodHarvesterTracksConfig.dttActiveVehicles"..string.format(".vehicle(%d)", i).."#name", vehicle)
					setXMLBool(WoodHarvesterTracks.configXml, "WoodHarvesterTracksConfig.dttActiveVehicles"..string.format(".vehicle(%d)", i), active)
					break
				end
			end
		end
		saveXMLFile(WoodHarvesterTracks.configXml)
	end
end
function WoodHarvesterTracks:groundRaycastCallbackNew(hitObjectId, x, y, z, distance)
    local spec = self.spec_woodHarvesterTracks
	
    spec.groundRaycastResult.y = y
    spec.groundRaycastResult.object = hitObjectId
    spec.groundRaycastResult.distance = distance
    return false
end
function WoodHarvesterTracks:onUpdate(dt)
	local spec = self.spec_woodHarvesterTracks
	
	if not spec.modInitialized then
		return
	end
	
	spec.infoText = ''
	if self:getIsActive() and spec.modActive and WoodHarvesterTracks.modActive then
		local anyActive = false
		if self.spec_wheels.wheels ~= nil then
			local isServer = self.isServer
			local terrainRootNode = g_currentMission.terrainRootNode
			local movingDirection = self.movingDirection

			for i, wheel in pairs(self.spec_wheels.wheels) do
				local effects = wheel.effects
				if effects ~= nil and (effects.hasTireTracks or effects.hasParticles) then
					local visualWheels = wheel.visualWheels
					local hasVisualWheels = visualWheels ~= nil and #visualWheels > 0
					local numTargets = hasVisualWheels and #visualWheels or 1
					
					local baseLx, baseLy, baseLz = 0, 0, 0
					local hasBasePos = false
					local driveNode = wheel.driveNode
					local repr = wheel.repr

					for j = 1, numTargets do
						local visualTarget = hasVisualWheels and visualWheels[j] or wheel
						local w = visualTarget.width or (wheel.physics and wheel.physics.width) or 0.5
						local width = 0.2 * w
						local length = math.min(0.2, 0.2 * w)
						
						local lx, ly, lz = 0, 0, 0
						if j == 1 then
							if driveNode ~= nil then
								lx, ly, lz = localToLocal(driveNode, repr, 0, 0, 0)
								baseLx, baseLy, baseLz = lx, ly, lz
								hasBasePos = true
							end
						elseif visualTarget.connectedVisualWheelOffset ~= nil then
							if not hasBasePos and driveNode ~= nil then
								baseLx, baseLy, baseLz = localToLocal(driveNode, repr, 0, 0, 0)
								hasBasePos = true
							end
							
							local firstWheel = hasVisualWheels and visualWheels[1] or wheel
							local mainWidth = firstWheel.width or 0.5
							local dir = visualTarget.connectedVisualWheelOffsetDirection or 1
							local totalOffset = (mainWidth * 0.5) + visualTarget.connectedVisualWheelOffset + (visualTarget.width * 0.5)
							lx, ly, lz = baseLx + (totalOffset * dir), baseLy, baseLz
						end

						local x0, y0, z0 = localToWorld(repr, lx + width, ly, lz - length)
						local x1, y1, z1 = localToWorld(repr, lx - width, ly, lz - length)
						local x2, y2, z2 = localToWorld(repr, lx + width, ly, lz + length)
						
						spec.groundRaycastResult.object = 0
						spec.groundRaycastResult.y = y0 - 1
						raycastClosest(x0, y0, z0, 0.0, -1.0, 0.0, 5, "groundRaycastCallbackNew", self, 256)

						if spec.groundRaycastResult.object == terrainRootNode then
							if isServer then
								local realArea, area = FSDensityMapUtil.updateCultivatorArea(x0, z0, x1, z1, x2, z2, true, true, nil, nil)
								if realArea ~= nil and realArea ~= 0 then
									FSDensityMapUtil.clearDecoArea(x0, z0, x1, z1, x2, z2)
									anyActive = true
								end
							end
						end
					end
				end
			end
		end
		if spec.timer <= 2000 then
			spec.timer = spec.timer + dt
		end
		if anyActive then
			spec.timer = 0
		end
		--spec.infoText = spec.infoText .. 'timer - '..string.format("%.3f",spec.timer)..'\n'
		for i,wheel in pairs(self.spec_wheels.wheels) do
			if spec.timer >= 1000 and spec.timer < 2000 then
				wheel.physics.supportsWheelSink = wheel.supportsWheelSinkOrig
				if wheel.additionalWheels ~= nil then
					for _,additionalWheel in pairs(wheel.additionalWheels) do
						additionalWheel.physics.supportsWheelSink = additionalWheel.physics.supportsWheelSinkOrig
						--spec.infoText = spec.infoText .. i..'add supportsWheelSink - '..tostring(additionalWheel.supportsWheelSink)..'\n'
					end
				end
				if self.spec_washable ~= nil then
					self.spec_washable.fieldMultiplier = spec.fieldMultiplierOrig
				end
			elseif spec.timer == 0 then
				wheel.physics.supportsWheelSink = false
				if wheel.additionalWheels ~= nil then
					for _,additionalWheel in pairs(wheel.additionalWheels) do
						additionalWheel.physics.supportsWheelSink = false
						--spec.infoText = spec.infoText .. i..'add supportsWheelSink - '..tostring(additionalWheel.supportsWheelSink)..'\n'
					end
				end
				if self.spec_washable ~= nil then
					self.spec_washable.fieldMultiplier = 0.1
				end
			end
			--spec.infoText = spec.infoText .. i..' supportsWheelSink - '..tostring(wheel.supportsWheelSink)..'\n'
		end
	end
	if self:getIsActive() then
		--spec.infoText = spec.infoText .. "fieldMultiplier: " .. string.format("%.3f",self.spec_washable.fieldMultiplier).."\n"
		if self.spec_washable ~= nil then
			for index,dirt in pairs(self.spec_washable.washableNodes) do
				spec.infoText = spec.infoText .. "dirty: " .. string.format("%.5f",self.spec_washable.washableNodes[index].dirtAmount).."\n"
			end
		end
		--spec.infoText = spec.infoText .. ' hasDtt - '..tostring(self:getHasDttImplement())..'\n'
		--spec.infoText = spec.infoText .. ' modActive - '..tostring(spec.modActive)..'\n'
		--spec.infoText = spec.infoText .. ' modActiveGlobal - '..tostring(WoodHarvesterTracks.modActive)..'\n'
		--renderText(0.7, 0.97, 0.015, spec.infoText)
	end
	if self.isClient then
		if self:getIsActive() and (self:getIsActiveForInput() or not self:getHasDttImplement()) then
			if spec.event_IDs ~= nil and g_dedicatedServerInfo == nil then
				for actionName,eventID in pairs(spec.event_IDs) do
					if actionName == InputAction.WOODHARVESTERTRACK_ACTIVATE then
						g_inputBinding:setActionEventActive(eventID, g_currentMission.isMasterUser)
						g_inputBinding:setActionEventText(eventID, spec.modActive and g_i18n:getText('WOODHARVESTERTRACK_DEACTIVATE') or g_i18n:getText('WOODHARVESTERTRACK_ACTIVATE'))
					end
					if actionName == InputAction.WOODHARVESTERTRACK_ACTIVATE_ALL then
						g_inputBinding:setActionEventActive(eventID, g_currentMission.isMasterUser)
						g_inputBinding:setActionEventText(eventID, WoodHarvesterTracks.modActive and g_i18n:getText('WOODHARVESTERTRACK_DEACTIVATE_ALL') or g_i18n:getText('WOODHARVESTERTRACK_ACTIVATE_ALL'))
					end
				end
			end
		end
	end
end
function WoodHarvesterTracks:actionCallback(actionName, keyStatus, arg4, arg5, arg6)
	local spec = self.spec_woodHarvesterTracks
	if not spec.modInitialized then
		return
	end
	
	if keyStatus > 0 then
		if actionName == 'WOODHARVESTERTRACK_ACTIVATE' then
			if g_currentMission.isMasterUser then
				if WoodHarvesterTracks.modActive == false then
					g_currentMission:showBlinkingWarning("First activate Wood Harvester Tracks global (CTRL + T)")
				else
					self:activateDttMod(not spec.modActive, 'THIS')
				end
			end
		elseif actionName == 'WOODHARVESTERTRACK_ACTIVATE_ALL' then
			if g_currentMission.isMasterUser then
				self:activateDttMod(not WoodHarvesterTracks.modActive, 'ALL')
			end
		end
	end
end
function WoodHarvesterTracks:activateDttMod(status, mode)
	local spec = self.spec_woodHarvesterTracks
	if not spec.modInitialized then
		return
	end
	
	if mode == 'THIS' then
		mode = self:getFullName()
	end
	local text = 'ACTIVATED'
	if not status then
		text = 'DEACTIVATED'
	end
	g_currentMission:showBlinkingWarning("Wood Harvester Tracks function "..tostring(text).." for "..tostring(mode).." vehicle", 2000)
	if mode == 'ALL' then
		self:toggleActiveWoodHarvesterTracks(spec.modActive, status, false)
	else
		self:toggleActiveWoodHarvesterTracks(status, WoodHarvesterTracks.modActive, false)
	end
end
function WoodHarvesterTracks:toggleActiveWoodHarvesterTracks(modActive, modActiveGlobal, noEventSend)
	local spec = self.spec_woodHarvesterTracks
	if not spec.modInitialized then
		return
	end
	
	if self.isServer or g_currentMission.isMasterUser then
		if spec.modActive ~= modActive then
			spec.modActive = modActive
			WoodHarvesterTracks.modActive = modActiveGlobal
			self:saveToXmlWoodHarvesterTracks(self:getFullName(), modActive)
		elseif WoodHarvesterTracks.modActive ~= modActiveGlobal then
			spec.modActive = modActive
			WoodHarvesterTracks.modActive = modActiveGlobal
			self:saveToXmlWoodHarvesterTracks()
		end
	end
	spec.modActive = modActive
	WoodHarvesterTracks.modActive = modActiveGlobal
	
	WoodHarvesterTracksToggleActiveEvent.sendEvent(self, modActive, modActiveGlobal, noEventSend)
end
function WoodHarvesterTracks:getHasDttImplement()
	local spec = self.spec_woodHarvesterTracks
	if not spec.modInitialized then
		return
	end
	
	local hasDtt = false
	if self.spec_attacherJoints ~= nil and self.spec_attacherJoints.attachedImplements ~= nil then
		for i,implement in pairs(self.spec_attacherJoints.attachedImplements) do
			if implement.object.spec_woodHarvesterTracks ~= nil and implement.object.spec_woodHarvesterTracks.modAllowed then
				hasDtt = true
			end
		end
	end
	return hasDtt
end
function WoodHarvesterTracks:onReadStream(streamId, connection)
	local spec = self.spec_woodHarvesterTracks
	if not spec.modInitialized then
		return
	end
	
    local modActive = streamReadBool(streamId)
    local modActiveGlobal = streamReadBool(streamId)
	if modActive ~= nil and modActiveGlobal ~= nil then
		self:toggleActiveWoodHarvesterTracks(modActive, modActiveGlobal, true)
	end
end
function WoodHarvesterTracks:onWriteStream(streamId, connection)
	local spec = self.spec_woodHarvesterTracks
	if not spec.modInitialized then
		return
	end
	
    streamWriteBool(streamId, spec.modActive)
    streamWriteBool(streamId, WoodHarvesterTracks.modActive)
end

WoodHarvesterTracksToggleActiveEvent = {}
WoodHarvesterTracksToggleActiveEvent_mt = Class(WoodHarvesterTracksToggleActiveEvent, Event)

InitEventClass(WoodHarvesterTracksToggleActiveEvent, "WoodHarvesterTracksToggleActiveEvent")

function WoodHarvesterTracksToggleActiveEvent.emptyNew()
    local self = Event.new(WoodHarvesterTracksToggleActiveEvent_mt)
    self.className="WoodHarvesterTracksToggleActiveEvent"
    return self
end

function WoodHarvesterTracksToggleActiveEvent.new(object, modActive, modActiveGlobal)
	local self = WoodHarvesterTracksToggleActiveEvent.emptyNew()
	self.object = object
	self.modActive = modActive
	self.modActiveGlobal = modActiveGlobal
	return self
end

function WoodHarvesterTracksToggleActiveEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
    self.modActive = streamReadBool(streamId)
    self.modActiveGlobal = streamReadBool(streamId)
    self:run(connection)
end

function WoodHarvesterTracksToggleActiveEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.modActive)
	streamWriteBool(streamId, self.modActiveGlobal)
end

function WoodHarvesterTracksToggleActiveEvent:run(connection)
	if self.object ~= nil then
		self.object:toggleActiveWoodHarvesterTracks(self.modActive, self.modActiveGlobal, true)
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(WoodHarvesterTracksToggleActiveEvent.new(self.object, self.modActive, self.modActiveGlobal), nil, connection, self.object)
	end
end

function WoodHarvesterTracksToggleActiveEvent.sendEvent(vehicle, modActive, modActiveGlobal, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(WoodHarvesterTracksToggleActiveEvent.new(vehicle, modActive, modActiveGlobal), nil, nil, vehicle)
		else
			g_client:getServerConnection():sendEvent(WoodHarvesterTracksToggleActiveEvent.new(vehicle, modActive, modActiveGlobal))
		end
	end
end