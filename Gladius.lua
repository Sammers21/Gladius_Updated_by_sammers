local abs = abs
local math = math
local max = max
local pairs = pairs
local print = print
local rawset = rawset
local setmetatable = setmetatable
local strfind = string.find
local string = string
local tonumber = tonumber
local tostring = tostring
local type = type

local CreateFrame = CreateFrame
local GetArenaOpponentSpec = GetArenaOpponentSpec
local GetBuildInfo = GetBuildInfo
local GetNumArenaOpponentSpecs = GetNumArenaOpponentSpecs
local GetNumGroupMembers = GetNumGroupMembers
local GetSpecializationInfoByID = GetSpecializationInfoByID
local InCombatLockdown = InCombatLockdown
local IsActiveBattlefieldArena = IsActiveBattlefieldArena
local IsAddOnLoaded = IsAddOnLoaded
local IsInInstance = IsInInstance
local IsLoggedIn = IsLoggedIn
local UnitAura = UnitAura
local UnitCastingInfo = UnitCastingInfo
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local ReloadUI = ReloadUI

local UIParent = UIParent

Gladius = { }
Gladius.eventHandler = CreateFrame("Frame")
Gladius.eventHandler.events = { }
Gladius.eventHandler.pendingEvents = { }
Gladius.midnightBeenInArena = false
Gladius.midnightReloadWarningShown = false

Gladius.eventHandler:RegisterEvent("PLAYER_LOGIN")
Gladius.eventHandler:RegisterEvent("ADDON_LOADED")
Gladius.eventHandler:RegisterEvent("PLAYER_REGEN_ENABLED")

Gladius.eventHandler:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_REGEN_ENABLED" then
		if next(self.pendingEvents) then
			for pendingEvent in pairs(self.pendingEvents) do
				self.pendingEvents[pendingEvent] = nil
				Gladius:RegisterEvent(pendingEvent)
			end
		end
		-- Run deferred operations that require out-of-combat
		if Gladius.pendingHideBlizz then
			Gladius:HideBlizzArenaFrames()
		end
	end
	if event == "PLAYER_LOGIN" then
		Gladius:OnInitialize()
		-- Mirror sArena behavior:
		-- - login outside arena: first arena entry should show warning
		-- - login inside arena (reconnect): do not show in that arena
		local _, loginInstanceType = IsInInstance()
		if loginInstanceType ~= "arena" then
			C_Timer.After(3, function()
				Gladius.midnightBeenInArena = true
			end)
		end
		-- Defer OnEnable to avoid protected state issues in 12.0+
		C_Timer.After(0, function()
			Gladius:OnEnable()
		end)
		Gladius.eventHandler:UnregisterEvent("PLAYER_LOGIN")
	else
		local func = self.events[event]
		if type(Gladius[func]) == "function" then
			Gladius[func](Gladius, event, ...)
		end
	end
end)

Gladius.modules = { }
Gladius.defaults = { }

local L
-- interfaceVersion no longer needed; always assume WoW 12.0 Midnight

function Gladius:SafeRegisterEvent(frame, event)
	if InCombatLockdown() or (frame.IsForbidden and frame:IsForbidden()) then
		return false, "defer"
	end
	frame:RegisterEvent(event)
	return true
end

function Gladius:Call(handler, func, ...)
	if not handler or type(handler.IsEnabled) ~= "function" then
		return
	end
	-- module disabled, return
	if not handler:IsEnabled() then
		return
	end
	-- save module function call
	if type(handler[func]) == "function" then
		handler[func](handler, ...)
	end
end

function Gladius:Debug(...)
	print("|cff33ff99Gladius|r:", ...)
end

function Gladius:Print(...)
	print("|cff33ff99Gladius|r:", ...)
end

function Gladius:SendMessage(event, ...)
	for _, module in pairs(self.modules) do
		self:Call(module, module.messages[event], ...)
	end
end

function Gladius:RegisterEvent(event, func)
	self.eventHandler.events[event] = func or event
	local ok, reason = self:SafeRegisterEvent(self.eventHandler, event)
	if not ok and reason == "defer" then
		self.eventHandler.pendingEvents[event] = true
	end
end

function Gladius:UnregisterEvent(event)
	self.eventHandler.events[event] = nil
	pcall(self.eventHandler.UnregisterEvent, self.eventHandler, event)
end

function Gladius:UnregisterAllEvents()
	pcall(self.eventHandler.UnregisterAllEvents, self.eventHandler)
	-- Always keep PLAYER_REGEN_ENABLED for deferred operations and pending event registration
	pcall(self.eventHandler.RegisterEvent, self.eventHandler, "PLAYER_REGEN_ENABLED")
end

function Gladius:NewModule(key, bar, attachTo, defaults, templates)
	local module = { }
	module.eventHandler = CreateFrame("Frame")
	-- event handling
	module.eventHandler.events = { }
	module.eventHandler.messages = { }
	module.eventHandler.pendingEvents = { }
	module.eventHandler:SetScript("OnEvent", function(self, event, ...)
		-- Handle pending event registrations when leaving combat
		if event == "PLAYER_REGEN_ENABLED" and next(self.pendingEvents) then
			for pendingEvent in pairs(self.pendingEvents) do
				self.pendingEvents[pendingEvent] = nil
				module:RegisterEvent(pendingEvent)
			end
		end
		local func = module.eventHandler.events[event]
		if type(module[func]) == "function" then
			module[func](module, event, ...)
		end
	end)
	module.eventHandler:RegisterEvent("PLAYER_REGEN_ENABLED")
	module.RegisterEvent = function(self, event, func)
		self.eventHandler.events[event] = func or event
		local ok, reason = Gladius:SafeRegisterEvent(self.eventHandler, event)
		if not ok and reason == "defer" then
			self.eventHandler.pendingEvents[event] = true
		end
	end
	module.UnregisterEvent = function(self, event)
		self.eventHandler.events[event] = nil
		pcall(self.eventHandler.UnregisterEvent, self.eventHandler, event)
	end
	module.UnregisterAllEvents = function(self)
		pcall(self.eventHandler.UnregisterAllEvents, self.eventHandler)
	end
	-- module status
	module.Enable = function(self)
		if not self.enabled then
			-- Check for combat lockdown and defer if needed
			if InCombatLockdown() then
				C_Timer.After(1, function()
					self:Enable()
				end)
				return
			end
			self.enabled = true
			if type(self.OnEnable) == "function" then
				self:OnEnable()
			end
		end
	end
	module.Disable = function(self)
		if self.enabled then
			self.enabled = false
			if type(self.OnDisable) == "function" then
				self:OnDisable()
			end
		end
	end
	module.IsEnabled = function(self)
		return self.enabled
	end
	-- message system
	module.RegisterMessage = function(self, event, func)
		self.eventHandler.messages[event] = func or self[event]
	end

	module.SendMessage = function(self, event, ...)
		for _, module in pairs(Gladius.modules) do
			self:Call(module, module.eventHandler.messages[event], ...)
		end
	end
	-- register module
	module.name = key
	module.isBarOption = bar
	--module.isBar = bar
	module.defaults = defaults
	module.attachTo = attachTo
	module.templates = templates
	module.messages = { }
	self.modules[key] = module
	-- set db defaults
	for k, v in pairs(defaults) do
		self.defaults.profile[k] = v
	end
	return module
end

function Gladius:GetParent(unit, module)
	-- get parent frame
	if module == "Frame" then
		return self.buttons[unit]
	else
		-- get parent module frame
		local m = self:GetModule(module)
		if m and type(m.GetFrame) == "function" then
			-- return frame as parent, if parent module is not enabled
			if not m:IsEnabled() then
				return self.buttons[unit]
			end
			-- update module, if frame doesn't exist
			local frame = m:GetFrame(unit)
			if not frame then
				self:Call(m, "Update", unit)
				frame = m:GetFrame(unit)
			end
				return frame
			end
		return nil
	end
end

function Gladius:EnableModule(name)
	local m = self:GetModule(name)
	if m ~= nil then
		m:Enable()
	end
end

function Gladius:DisableModule(name)
	local m = self:GetModule(name)
	if m ~= nil then
		m:Disable()
	end
end

function Gladius:GetModule(name)
	return self.modules[name]
end

function Gladius:GetModules(module)
	-- Get module list for frame anchor
	local t = {["Frame"] = L["Frame"]}
	for moduleName, m in pairs(self.modules) do
		if moduleName ~= module and m:GetAttachTo() ~= module and m.attachTo and m:IsEnabled() then
			t[moduleName] = L[moduleName]
		end
	end
	return t
end

function Gladius:OnInitialize()
	-- setup db
	self.dbi = LibStub("AceDB-3.0"):New("Gladius2DB", self.defaults)
	self.dbi.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.dbi.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.dbi.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")

	-- dispel module updates (3.2.6)
	for k, v in pairs(self.dbi["profiles"]) do
		if self.dbi["profiles"][k]["modules"] then
			if self.dbi["profiles"][k]["modules"]["Dispell"] ~= nil then
				self.dbi["profiles"][k]["modules"]["Dispel"] = self.dbi["profiles"][k]["modules"]["Dispell"]
			end
			self.dbi["profiles"][k]["modules"]["Dispell"] = nil
		end
	end

	for k, v in pairs(self.dbi["profiles"]) do
		if self.dbi["profiles"][k]["aurasFrameAuras"] ~= nil then
			self.dbi["profiles"][k]["aurasFrameAuras"] = nil
		end
	end

	local removedModules = {
		Announcements = true,
		Auras = true,
		Timer = true,
		TargetBar = true,
	}

	for _, profile in pairs(self.dbi["profiles"]) do
		if profile["modules"] then
			for moduleName in pairs(removedModules) do
				profile["modules"][moduleName] = nil
			end
		end
		profile["announcements"] = nil

		for optionKey, optionValue in pairs(profile) do
			if type(optionKey) == "string" and type(optionValue) == "string" and strfind(optionKey, "AttachTo$") and removedModules[optionValue] then
				profile[optionKey] = "Frame"
			end
		end

		if type(profile["tagsTexts"]) == "table" then
			for _, textConfig in pairs(profile["tagsTexts"]) do
				if type(textConfig) == "table" and removedModules[textConfig.attachTo] then
					textConfig.attachTo = "HealthBar"
				end
			end
		end
	end

	self.db = setmetatable(self.dbi.profile, {
		__newindex = function(t, index, value)
		if type(value) == "table" then
			rawset(self.defaults.profile, index, value)
		end
		rawset(t, index, value)
	end})
	-- Legacy key from old reload-warning behavior; no longer used.
	self.db.midnightReloadShown = nil

	-- localization
	L = self.L

	-- libsharedmedia
	self.LSM = LibStub("LibSharedMedia-3.0")
	self.LSM:Register(self.LSM.MediaType.STATUSBAR, "Bars", "Interface\\AddOns\\Gladius_Updated_by_sammers\\Images\\Bars")
	self.LSM:Register(self.LSM.MediaType.STATUSBAR, "Minimalist", "Interface\\AddOns\\Gladius_Updated_by_sammers\\Images\\Minimalist")
	self.LSM:Register(self.LSM.MediaType.STATUSBAR, "Smooth", "Interface\\AddOns\\Gladius_Updated_by_sammers\\Images\\Smooth")

	-- test environment
	self.test = false
	self.testCount = 0
	self.testing = setmetatable({
		["arena1"] = {health = 400000, maxHealth = 400000, power = 300000, maxPower = 300000, powerType = 0, unitClass = "MAGE", unitRace = "Draenei", unitSpec = "Frost", unitSpecId = 64},
		["arena2"] = {health = 380000, maxHealth = 400000, power = 100, maxPower = 120, powerType = 2, unitClass = "HUNTER", unitRace = "Night Elf", unitSpec = "Survival", unitSpecId = 255},
		["arena3"] = {health = 240000, maxHealth = 400000, power = 90, maxPower = 130, powerType = 3, unitClass = "ROGUE", unitRace = "Human", unitSpec = "Combat", unitSpecId = 260},
	},
	{
		__index = function(t, k)
			return t["arena1"]
		end
	})

	-- buttons
	self.buttons = { }
end

function Gladius:OnEnable()
	-- Check for combat lockdown and defer if needed
	if InCombatLockdown() then
		C_Timer.After(1, function()
			Gladius:OnEnable()
		end)
		return
	end
	
	-- register the appropriate events that fires when you enter an arena
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
	-- enable modules
	for moduleName, module in pairs(self.modules) do
		if self.db.modules[moduleName] then
			module:Enable()
		else
			module:Disable()
		end
	end
	-- display help message
	if not self.db.locked and not self.db.x["arena1"] and not self.db.y["arena1"] then
		-- Defer test mode to next frame to avoid protected state
		C_Timer.After(0.1, function()
			SlashCmdList["GLADIUS"]("test 3")
			self:Print(L["Welcome to Gladius!"])
			self:Print(L["First run has been detected, displaying test frame."])
			self:Print(L["Valid slash commands are:"])
			self:Print(L["/gladius ui"])
			self:Print(L["/gladius test 2-3"])
			self:Print(L["/gladius hide"])
			self:Print(L["/gladius reset"])
			self:Print(L["If this is not your first run please lock or move the frame to prevent this from happening."])
		end)
	end
	-- see if we are already in arena
	if IsLoggedIn() then
		Gladius:ZONE_CHANGED_NEW_AREA()
	end
end

function Gladius:OnDisable()
	-- unregister events and disable modules
	self:UnregisterAllEvents()
	for _, module in pairs(self.modules) do
		module:Disable()
		self:Call(module, "OnDisable")
	end
end

function Gladius:OnProfileChanged(event, database, newProfileKey)
	-- call function for each module
	for _, module in pairs(self.modules) do
		self:Call(module, "OnProfileChanged")
	end
	-- update frame on profile change
	self:UpdateFrame()
end

function Gladius:ZONE_CHANGED_NEW_AREA()
	local _, instanceType = IsInInstance()
	-- check if we are entering or leaving an arena
	if instanceType == "arena" then
		self:JoinedArena()
	elseif instanceType ~= "arena" and self.instanceType == "arena" then
		self:LeftArena()
	end
	self.instanceType = instanceType
end

function Gladius:HideBlizzArenaFrames()
	if not self.blizzHider then
		self.blizzHider = CreateFrame("Frame")
		self.blizzHider:Hide()
	end
	if InCombatLockdown() then
		-- Defer until combat ends
		self.pendingHideBlizz = true
		return
	end
	self.pendingHideBlizz = nil
	if CompactArenaFrame then
		CompactArenaFrame:SetParent(self.blizzHider)
	end
	if CompactArenaFrameTitle then
		CompactArenaFrameTitle:SetParent(self.blizzHider)
	end
end

function Gladius:JoinedArena()
	-- special arena event
	self:RegisterEvent("UNIT_NAME_UPDATE")
	self:RegisterEvent("ARENA_OPPONENT_UPDATE")
	self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UNIT_MAXHEALTH", "UNIT_HEALTH")

	-- reset test
	self.test = false
	self.testCount = 0

	-- hide buttons
	self:HideFrame()

	-- Reset and re-hook Blizzard's DebuffFrame for CC display BEFORE hiding the frame
	-- On /reload, Blizzard frames are recreated so old hooks are lost
	local classIconModule = self.modules["ClassIcon"]
	if classIconModule and classIconModule:IsEnabled() then
		classIconModule.hookedBlizzDebuffs = {}
		for i = 1, 5 do
			classIconModule:HookBlizzDebuffs("arena" .. i)
		end
	end
	-- Trinket hooking is handled by Trinket:Show() with retry logic.
	-- Do NOT reset hookedBlizzTrinkets here — hooksecurefunc stacks
	-- and cannot be removed, so re-hooking causes duplicate calls.

	-- Hook Blizzard's CompactArenaFrame name/health text BEFORE hiding
	-- This allows us to capture name and HP values that are secret in 12.0
	if not self.hookedBlizzData then
		self.hookedBlizzData = {}
	end
	local function tryHookBlizzData(id)
		if self.hookedBlizzData[id] then
			return true
		end
		local unit = "arena" .. id
		local blizzFrame = _G["CompactArenaFrameMember" .. id]
		if not blizzFrame then
			return false
		end

		self.hookedBlizzData[id] = true
		-- Hook name text
		if blizzFrame.name and blizzFrame.name.SetText then
			hooksecurefunc(blizzFrame.name, "SetText", function(_, text)
				local button = self.buttons[unit]
				if button and button.secretNameSink then
					pcall(button.secretNameSink.SetText, button.secretNameSink, text)
					if self.modules and self.modules["HealthBar"] and self.modules["HealthBar"].UpdateInfoText then
						self.modules["HealthBar"]:UpdateInfoText(unit)
					end
				end
			end)
			-- Capture current value immediately too.
			local ok, currentName = pcall(blizzFrame.name.GetText, blizzFrame.name)
			if ok then
				local button = self.buttons[unit]
				if button and button.secretNameSink then
					pcall(button.secretNameSink.SetText, button.secretNameSink, currentName)
					if self.modules and self.modules["HealthBar"] and self.modules["HealthBar"].UpdateInfoText then
						self.modules["HealthBar"]:UpdateInfoText(unit)
					end
				end
			end
		end
		-- Hook health bar value
		if blizzFrame.healthBar and blizzFrame.healthBar.SetValue then
			hooksecurefunc(blizzFrame.healthBar, "SetValue", function(_, value)
				local button = self.buttons[unit]
				if button and button.secretHealthSink then
					pcall(button.secretHealthSink.SetValue, button.secretHealthSink, value)
					if self.modules and self.modules["HealthBar"] and self.modules["HealthBar"].UpdateInfoText then
						self.modules["HealthBar"]:UpdateInfoText(unit)
					end
				end
			end)
			local ok, currentValue = pcall(blizzFrame.healthBar.GetValue, blizzFrame.healthBar)
			if ok then
				local button = self.buttons[unit]
				if button and button.secretHealthSink then
					pcall(button.secretHealthSink.SetValue, button.secretHealthSink, currentValue)
					if self.modules and self.modules["HealthBar"] and self.modules["HealthBar"].UpdateInfoText then
						self.modules["HealthBar"]:UpdateInfoText(unit)
					end
				end
			end
		end
		if blizzFrame.healthBar and blizzFrame.healthBar.SetMinMaxValues then
			hooksecurefunc(blizzFrame.healthBar, "SetMinMaxValues", function(_, minVal, maxVal)
				local button = self.buttons[unit]
				if button and button.secretHealthSink then
					pcall(button.secretHealthSink.SetMinMaxValues, button.secretHealthSink, minVal, maxVal)
					if self.modules and self.modules["HealthBar"] and self.modules["HealthBar"].UpdateInfoText then
						self.modules["HealthBar"]:UpdateInfoText(unit)
					end
				end
			end)
			local ok, minVal, maxVal = pcall(blizzFrame.healthBar.GetMinMaxValues, blizzFrame.healthBar)
			if ok then
				local button = self.buttons[unit]
				if button and button.secretHealthSink then
					pcall(button.secretHealthSink.SetMinMaxValues, button.secretHealthSink, minVal, maxVal)
					if self.modules and self.modules["HealthBar"] and self.modules["HealthBar"].UpdateInfoText then
						self.modules["HealthBar"]:UpdateInfoText(unit)
					end
				end
			end
		end

		return true
	end

	for i = 1, 5 do
		local id = i
		if not tryHookBlizzData(id) then
			C_Timer.After(0.5, function()
				if not tryHookBlizzData(id) then
					C_Timer.After(1.5, function()
						tryHookBlizzData(id)
					end)
				end
			end)
		end
	end

	-- Hide Blizzard's CompactArenaFrame (Midnight 12.x)
	-- Deferred if in combat lockdown
	self:HideBlizzArenaFrames()

	-- background
	if self.db.groupButtons then
		if not self.background then
			local background = CreateFrame("Frame", "GladiusButtonBackground", UIParent, BackdropTemplateMixin and "BackdropTemplate");
			background:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16})
			background:SetBackdropColor(self.db.backgroundColor.r, self.db.backgroundColor.g, self.db.backgroundColor.b, self.db.backgroundColor.a)
			background:SetFrameStrata("BACKGROUND")
			self.background = background
		end
		self.background:SetAlpha(1)
		if not self.db.locked then
			if self.anchor then
				self.anchor:SetAlpha(1)
				self.anchor:SetFrameStrata("LOW")
			end
		end
	end

	local numOpps = GetNumArenaOpponentSpecs()
	if (numOpps and numOpps > 0) then
		self:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
	end

	-- Show warning only once, matching sArena's first-arena-entry behavior.
	if self.midnightBeenInArena then
		self:ShowMidnightReloadWarning()
	else
		self.midnightBeenInArena = true
	end
end

function Gladius:LeftArena()
	self:HideFrame()
	-- reset units
	for unit, _ in pairs(self.buttons) do
		Gladius.buttons[unit]:RegisterForDrag()
		Gladius.buttons[unit]:Hide()
		self:ResetUnit(unit)
	end

	-- unregister combat events
	self:UnregisterAllEvents()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
end

function Gladius:ShowMidnightReloadWarning()
	-- Session-local one-time warning (same practical behavior as sArena).
	if self.midnightReloadWarningShown then
		return
	end
	self.midnightReloadWarningShown = true

	if self.midnightReloadWarningFrame then
		self.midnightReloadWarningFrame:SetAlpha(0)
		self.midnightReloadWarningFrame:Show()
	else
		local template = BackdropTemplateMixin and "BackdropTemplate" or nil
		local frame = CreateFrame("Frame", "GladiusMidnightReloadWarning", UIParent, template)
		frame:SetSize(460, 250)
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 140)
		frame:SetFrameStrata("DIALOG")
		frame:EnableMouse(true)
		frame:SetMovable(true)
		frame:RegisterForDrag("LeftButton")
		frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
		frame:SetScript("OnDragStop", function(f) f:StopMovingOrSizing() end)

		frame:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = 1,
			insets = {left = 1, right = 1, top = 1, bottom = 1},
		})
		frame:SetBackdropColor(0.04, 0.05, 0.09, 0.96)
		frame:SetBackdropBorderColor(0.22, 0.75, 0.82, 0.55)

		local stripe = frame:CreateTexture(nil, "ARTWORK")
		stripe:SetTexture("Interface\\Buttons\\WHITE8x8")
		stripe:SetPoint("TOPLEFT", 1, -1)
		stripe:SetPoint("TOPRIGHT", -1, -1)
		stripe:SetHeight(3)
		stripe:SetVertexColor(0.20, 0.82, 0.90, 1)

		local icon = frame:CreateTexture(nil, "OVERLAY")
		icon:SetTexture("Interface\\DialogFrame\\DialogAlertIcon")
		icon:SetSize(44, 44)
		icon:SetPoint("TOP", 0, -14)

		local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		title:SetPoint("TOP", icon, "BOTTOM", 0, -8)
		title:SetText("|cff40d0e0Gladius: Reload Recommended|r")

		local body = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		body:SetPoint("TOP", title, "BOTTOM", 0, -12)
		body:SetWidth(410)
		body:SetJustifyH("CENTER")
		body:SetText("Midnight (12.x) UI restrictions can cause arena data\n" ..
			"to behave inconsistently on first load.\n\n" ..
			"|cff88a0b0Reload UI once now for the most stable behavior.|r")

		local reloadButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		reloadButton:SetSize(160, 30)
		reloadButton:SetPoint("BOTTOM", 0, 34)
		reloadButton:SetText("Reload UI")
		reloadButton:SetScript("OnClick", function()
			ReloadUI()
		end)

		local dismissText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		dismissText:SetPoint("TOP", reloadButton, "BOTTOM", 0, -4)
		dismissText:SetText("|cff555566dismiss|r")

		local dismissButton = CreateFrame("Button", nil, frame)
		dismissButton:SetPoint("TOPLEFT", dismissText, "TOPLEFT", -6, 2)
		dismissButton:SetPoint("BOTTOMRIGHT", dismissText, "BOTTOMRIGHT", 6, -2)
		dismissButton:SetScript("OnClick", function()
			frame:Hide()
		end)
		dismissButton:SetScript("OnEnter", function()
			dismissText:SetText("|cff8899aadismiss|r")
		end)
		dismissButton:SetScript("OnLeave", function()
			dismissText:SetText("|cff555566dismiss|r")
		end)

		local animationGroup = frame:CreateAnimationGroup()
		local fade = animationGroup:CreateAnimation("Alpha")
		fade:SetFromAlpha(0)
		fade:SetToAlpha(1)
		fade:SetDuration(0.4)
		fade:SetSmoothing("OUT")
		animationGroup:SetScript("OnFinished", function()
			frame:SetAlpha(1)
		end)
		frame._fadeIn = animationGroup

		self.midnightReloadWarningFrame = frame
	end

	local warningFrame = self.midnightReloadWarningFrame
	if warningFrame then
		warningFrame:Show()
		if warningFrame._fadeIn then
			warningFrame._fadeIn:Stop()
			warningFrame:SetAlpha(0)
			warningFrame._fadeIn:Play()
		end
	end
end

function Gladius:UNIT_NAME_UPDATE(event, unit)
	if not IsActiveBattlefieldArena() then
		return
	end

	if not self:IsValidUnit(unit) then
		return
	end

	self:ShowUnit(unit)
end

function Gladius:ARENA_OPPONENT_UPDATE(event, unit, type)
	if not IsActiveBattlefieldArena() then
		return
	end
	if not self:IsValidUnit(unit) then
		return
	end
	if not self.buttons[unit] then
		self:CreateButton(unit)
	end
	local id = string.match(unit, "arena(%d)")
	local specID = GetArenaOpponentSpec(id)
	if specID and specID > 0 then
		--local id, name, description, icon, background, role, class = GetSpecializationInfoByID(specID)
		local id, name, description, icon, role, class = GetSpecializationInfoByID(specID)
		self.buttons[unit].spec = name
		self.buttons[unit].specIcon = icon
		self.buttons[unit].class = class
	else
		local _, class = UnitClass(unit)
		if class then
			self.buttons[unit].class = class
		end
	end
	self:UpdateUnit(unit)
	self:ShowUnit(unit)
	-- enemy seen
	if type == "seen" then
		self:ShowUnit(unit, false, nil)
	-- enemy stealth
	elseif type == "unseen" then
		self:UpdateAlpha(unit, 0.5)
	-- enemy left arena
	elseif type == "destroyed" then
		self:UpdateAlpha(unit, 0.3)
	-- arena over
	elseif type == "cleared" then
		self:UpdateAlpha(unit, 0)
	end
end

function Gladius:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
	-- Update spec from API
	for i = 1, GetNumArenaOpponentSpecs() do
		local unit = "arena"..i
		local specID = GetArenaOpponentSpec(i)
		if specID and specID > 0 then
			--local id, name, description, icon, background, role, class = GetSpecializationInfoByID(specID)
			local id, name, description, icon, role, class = GetSpecializationInfoByID(specID)
			if not self.buttons[unit] then
				self:CreateButton(unit)
			end
			self.buttons[unit].spec = name
			self.buttons[unit].specIcon = icon
			self.buttons[unit].class = class
			if not class then
				local _, fallbackClass = UnitClass(unit)
				if fallbackClass then
					self.buttons[unit].class = fallbackClass
				end
			end
			self:UpdateUnit(unit)
			self:ShowUnit(unit)
			self:UpdateAlpha(unit, 0.5)
						
			if(Gladius.modules["DRTracker"]) then
			     Gladius:Call(Gladius.modules.DRTracker, "Reset", unit)
				end
		end
	end
end

function Gladius:UpdateFrame()
	self.db = self.dbi.profile
	-- TODO: check why we need this
	self.buttons = self.buttons or { }
	for unit, _ in pairs(self.buttons) do
		local unitId = tonumber(string.match(unit, "^arena(.+)"))
		if self.testCount >= unitId then
			-- update frame will only be called in the test environment
			self:UpdateUnit(unit)
			self:ShowUnit(unit, true)

			-- test environment
			if self.test then
				self:TestUnit(unit)
			end
		end
	end
end

function Gladius:UpdateColors()
	self.background:SetBackdropColor(self.db.backgroundColor.r, self.db.backgroundColor.g, self.db.backgroundColor.b, self.db.backgroundColor.a)
end

function Gladius:HideFrame()
	-- hide units
	for unit, _ in pairs(self.buttons) do
		self:ResetUnit(unit)
	end

	-- hide background
	if self.background then
		self.background:SetAlpha(0)
		--self.background:Hide()
	end

	-- hide anchor
	if self.anchor then
		--self.anchor:SetAlpha(0)
		self.anchor:Hide()
	end
end

function Gladius:UpdateUnit(unit, module)
	local _, instanceType = IsInInstance()
	if instanceType ~= "arena" and not Gladius.test then
		return
	end
	if not self:IsValidUnit(unit) then
		return
	end

	if InCombatLockdown() then
		return
	end

	-- create button
	if not self.buttons[unit] then
		self:CreateButton(unit)
	end

	local height = 0
	local frameHeight = 0

	-- default height values
	self.buttons[unit].frameHeight = 1
	self.buttons[unit].height = 1

	-- reset hit rect
	self.buttons[unit]:SetHitRectInsets(0, 0, 0, 0)
	self.buttons[unit].secure:SetHitRectInsets(0, 0, 0, 0)

	-- update modules (bars first, because we need the height)
	for _, m in pairs(self.modules) do
		if m:IsEnabled() then
			-- update and get bar height
			if m.isBarOption then
				if module == nil or (module and m.name == module) then
					self:Call(m, "Update", unit)
				end

				local attachTo = m:GetAttachTo()
				local detached = false

				if type(m.IsDetached) == "function" then
					detached = m:IsDetached()
				end

				if (not detached and (attachTo == "Frame" or m.isBar)) then
					frameHeight = frameHeight + (m.frame[unit] and m.frame[unit]:GetHeight() or 0)
				else
					height = height + (m.frame[unit] and m.frame[unit]:GetHeight() or 0)
				end
			end
		end
	end
	self.buttons[unit].height = height + frameHeight
	self.buttons[unit].frameHeight = frameHeight
	-- update button
	self.buttons[unit]:SetScale(self.db.frameScale)
	self.buttons[unit]:SetWidth(self.db.barWidth)
	self.buttons[unit]:SetHeight(frameHeight)
	-- update modules (indicator)
	local indicatorHeight = 0
	for _, m in pairs(self.modules) do
		if m:IsEnabled() and not m.isBarOption then
			self:Call(m, "Update", unit)
		end
	end
	-- set point
	self.buttons[unit]:ClearAllPoints()
	if unit == "arena1" or not self.db.groupButtons then
		if (not self.db.x and not self.db.y) or (not self.db.x[unit] and not self.db.y[unit]) then
			self.buttons[unit]:SetPoint("CENTER")
		else
			local scale = self.buttons[unit]:GetEffectiveScale()
			self.buttons[unit]:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.x[unit] / scale, self.db.y[unit] / scale)
		end
	else
		local parent = string.match(unit, "^arena(.+)") - 1
		local parentButton = self.buttons["arena"..parent]
		if parentButton then
			if self.db.growUp then
				self.buttons[unit]:SetPoint("BOTTOMLEFT", parentButton, "TOPLEFT", 0, self.db.bottomMargin + indicatorHeight)
			else
				self.buttons[unit]:SetPoint("TOPLEFT", parentButton, "BOTTOMLEFT", 0, - self.db.bottomMargin - indicatorHeight)
			end
			if self.db.growLeft then
				local left, right = self.buttons[unit]:GetHitRectInsets()
				self.buttons[unit]:SetPoint("TOPLEFT", parentButton, "TOPLEFT", - self.buttons[unit]:GetWidth() - self.db.bottomMargin - abs(left), 0)
			end
			if self.db.growRight then
				local left, right = self.buttons[unit]:GetHitRectInsets()
				self.buttons[unit]:SetPoint("TOPLEFT", parentButton, "TOPLEFT", self.buttons[unit]:GetWidth() + self.db.bottomMargin + abs(left), 0)
			end
		end
	end
	-- show the button
	self.buttons[unit]:Show()
	self.buttons[unit]:SetAlpha(0)
	-- update secure frame
	self.buttons[unit].secure:SetWidth(self.buttons[unit]:GetWidth())
	self.buttons[unit].secure:SetHeight(self.buttons[unit]:GetHeight())
	self.buttons[unit].secure:ClearAllPoints()
	self.buttons[unit].secure:SetAllPoints(self.buttons[unit])
	-- show the secure frame
	self.buttons[unit].secure:Show()
	self.buttons[unit].secure:SetAlpha(1)
	self.buttons[unit]:SetFrameStrata("LOW")
	self.buttons[unit].secure:SetFrameStrata("MEDIUM")
	-- update background
	if unit == "arena1" then
		local left, right = self.buttons[unit]:GetHitRectInsets()
		-- background
		self.background:SetBackdropColor(self.db.backgroundColor.r, self.db.backgroundColor.g, self.db.backgroundColor.b, self.db.backgroundColor.a)
		self.background:SetWidth(self.buttons[unit]:GetWidth() + self.db.backgroundPadding * 2 + abs(right) + abs(left))
		self.background:ClearAllPoints()
		if self.db.growUp then
			self.background:SetPoint("BOTTOMLEFT", self.buttons["arena1"], "BOTTOMLEFT", - self.db.backgroundPadding + left, - self.db.backgroundPadding)
		--[[elseif self.db.growLeft then
			self.background:SetPoint("TOPLEFT", self.buttons["arena5"], "TOPLEFT", - self.db.backgroundPadding + left, self.db.backgroundPadding)
			self.background:SetPoint("BOTTOMRIGHT", self.buttons["arena1"], "BOTTOMRIGHT", self.db.backgroundPadding, - self.db.backgroundPadding)
		elseif self.db.growRight then
			self.background:SetPoint("TOPLEFT", self.buttons["arena1"], "TOPLEFT", - self.db.backgroundPadding + left, self.db.backgroundPadding)
			self.background:SetPoint("BOTTOMRIGHT", self.buttons["arena5"], "BOTTOMRIGHT", self.db.backgroundPadding, - self.db.backgroundPadding)]]
		else
			self.background:SetPoint("TOPLEFT", self.buttons["arena1"], "TOPLEFT", - self.db.backgroundPadding + left, self.db.backgroundPadding)
		end
		self.background:SetScale(self.db.frameScale)
		if self.db.groupButtons and not self.db.growLeft and not self.db.growRight then
			self.background:Show()
			self.background:SetAlpha(0)
		else
			self.background:Hide()
		end
		-- anchor
		self.anchor:ClearAllPoints()
		if self.db.backgroundColor.a > 0 then
			self.anchor:SetWidth(self.buttons[unit]:GetWidth() + self.db.backgroundPadding * 2 + abs(right) + abs(left))
			if self.db.growUp then
				self.anchor:SetPoint("TOPLEFT", self.background, "BOTTOMLEFT")
			else
				self.anchor:SetPoint("BOTTOMLEFT", self.background, "TOPLEFT")
			end
		else
			self.anchor:SetWidth(self.buttons[unit]:GetWidth() + abs(right) + abs(left))
			if self.db.growUp then
				self.anchor:SetPoint("TOPLEFT", self.buttons["arena1"], "BOTTOMLEFT", left, 0)
			else
				self.anchor:SetPoint("BOTTOMLEFT", self.buttons["arena1"], "TOPLEFT", left, 0)
			end
		end
		self.anchor:SetHeight(20)
		self.anchor:SetScale(self.db.frameScale)
		self.anchor.text:SetPoint("CENTER", self.anchor, "CENTER")
		self.anchor.text:SetFont(self.LSM:Fetch(self.LSM.MediaType.FONT, Gladius.db.globalFont), (Gladius.db.useGlobalFontSize and Gladius.db.globalFontSize or 11))
		self.anchor.text:SetTextColor(1, 1, 1, 1)
		self.anchor.text:SetShadowOffset(1, -1)
		self.anchor.text:SetShadowColor(0, 0, 0, 1)
		self.anchor.text:SetText(L["Gladius Anchor - click to move"])
		if self.db.groupButtons and not self.db.locked then
			self.anchor:Show()
			self.anchor:SetAlpha(0)
		else
			self.anchor:Hide()
		end
	end
end

function Gladius:ShowUnit(unit, testing, module)
	if not self:IsValidUnit(unit) then
		return
	end

	if not self.buttons[unit] then
		return
	end

	if self:IsUnitShown(unit) then
		return
	end

	-- disable test mode, when there are real arena opponents (happens when entering arena and using /gladius test)
	local testing = testing or false
	if not testing and self.test then
		-- reset frame
		self:HideFrame()
		-- disable test mode
		self.test = false
	end

	self.buttons[unit]:SetAlpha(1)
	for _, m in pairs(self.modules) do
		if m:IsEnabled() then
			if module == nil or (module and m.name == module) then
				self:Call(m, "Show", unit)
			end
		end
	end

	-- background
	if self.db.groupButtons then
		self.background:SetAlpha(1)
		if not self.db.locked then
			self.anchor:SetAlpha(1)
			self.anchor:SetFrameStrata("LOW")
		end
	end

	local maxHeight = 0
	for u, button in pairs(self.buttons) do
		local unitId = tonumber(string.match(u, "^arena(.+)"))
		if button:GetAlpha() > 0 then
			maxHeight = math.max(maxHeight, unitId)
		end
	end

	self.background:SetHeight(self.buttons[unit]:GetHeight() * maxHeight + self.db.bottomMargin * (maxHeight - 1) + self.db.backgroundPadding * 2)
end

function Gladius:TestUnit(unit, module)
	if not self:IsValidUnit(unit) then
		return
	end

	-- test modules
	for _, m in pairs(self.modules) do
		if m:IsEnabled() then
			if module == nil or (module and m.name == module) then
				self:Call(m, "Test", unit)
			end
		end
	end
	-- disable secure frame in test mode so we can move the frame
	self.buttons[unit]:SetFrameStrata("LOW")
	self.buttons[unit].secure:SetFrameStrata("BACKGROUND")
end

function Gladius:ResetUnit(unit, module)
	if not self:IsValidUnit(unit) then
		return
	end

	if not self.buttons[unit] then
		return
	end

	-- reset modules
	for _, m in pairs(self.modules) do
		if m:IsEnabled() then
			if module == nil or (module and m.name == module) then
				self:Call(m, "Reset", unit)
			end
		end
	end
	self.buttons[unit].spec = ""
	if self.buttons[unit].secretNameSink then
		self.buttons[unit].secretNameSink:SetText("")
	end
	if self.buttons[unit].secretHealthSink then
		self.buttons[unit].secretHealthSink:SetMinMaxValues(0, 1)
		self.buttons[unit].secretHealthSink:SetValue(0)
	end
	-- hide the button
	self.buttons[unit]:SetAlpha(0)
	-- hide the secure frame
	self.buttons[unit].secure:SetAlpha(0)
end

function Gladius:UpdateAlpha(unit, alpha)
	-- update button alpha
	--alpha = alpha and alpha or 0.25
	if self.buttons[unit] then
		self.buttons[unit]:SetAlpha(alpha)
	end
end

function Gladius:GetCapturedArenaName(unit)
	local button = self.buttons and self.buttons[unit]
	if button and button.secretNameSink then
		local ok, name = pcall(button.secretNameSink.GetText, button.secretNameSink)
		if ok then
			local valueType = type(name)
			if valueType == "string" then
				return name, true
			end
		end
	end
	return nil, false
end

function Gladius:GetCapturedArenaHealth(unit)
	local button = self.buttons and self.buttons[unit]
	if button and button.secretHealthSink then
		local ok, value = pcall(button.secretHealthSink.GetValue, button.secretHealthSink)
		if ok then
			local valueType = type(value)
			if valueType == "number" then
				return value, true
			end
		end
	end
	return nil, false
end

function Gladius:GetCapturedArenaMaxHealth(unit)
	local button = self.buttons and self.buttons[unit]
	if button and button.secretHealthSink then
		local ok, _, maxValue = pcall(button.secretHealthSink.GetMinMaxValues, button.secretHealthSink)
		if ok then
			local valueType = type(maxValue)
			if valueType == "number" then
				return maxValue, true
			end
		end
	end
	return nil, false
end

function Gladius:CreateButton(unit)
	local _, instanceType = IsInInstance()
	if instanceType ~= "arena" and not Gladius.test then
		return
	end
	local button = CreateFrame("Frame", "GladiusButtonFrame"..unit, UIParent)
	--[[button:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,})
	button:SetBackdropColor(0, 0, 0, 0.4)]]
	button:SetClampedToScreen(true)
	button:EnableMouse(true)
	--button:EnableKeyboard(true)
	button:SetMovable(true)
	button:RegisterForDrag("LeftButton")
	button:SetScript("OnDragStart", function(f)
		if not InCombatLockdown() and not self.db.locked then
			local f = self.db.groupButtons and self.buttons["arena1"] or f
			f:StartMoving()
		end
	end)
	button:SetScript("OnDragStop", function(f)
		if not InCombatLockdown() then
			local f = self.db.groupButtons and self.buttons["arena1"] or f
			local unit = self.db.groupButtons and "arena1" or unit
			f:StopMovingOrSizing()
			local scale = f:GetEffectiveScale()
			self.db.x[unit] = f:GetLeft() * scale
			self.db.y[unit] = f:GetTop() * scale
		end
	end)
	-- secure
	local secure = CreateFrame("Button", "GladiusButton"..unit, button, "SecureActionButtonTemplate")
	secure:EnableMouse(true)
	secure:EnableKeyboard(true)
	secure:RegisterForClicks("AnyUp", "AnyDown")
	button.secure = secure
	-- Secret-value sinks for Midnight arena data.
	button.secretNameSink = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	button.secretNameSink:Hide()
	button.secretHealthSink = CreateFrame("StatusBar", nil, button)
	button.secretHealthSink:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
	button.secretHealthSink:SetMinMaxValues(0, 1)
	button.secretHealthSink:SetValue(0)
	button.secretHealthSink:Hide()
	-- clique
	ClickCastFrames = ClickCastFrames or {}
	ClickCastFrames[secure] = true
	self.buttons[unit] = button
	-- group background
	if unit == "arena1" then
		-- anchor
		local anchor = CreateFrame("Frame", "GladiusButtonAnchor", UIParent, BackdropTemplateMixin and "BackdropTemplate");
		anchor:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16})
		anchor:SetBackdropColor(0, 0, 0, 1)
		anchor:SetClampedToScreen(true)
		anchor:EnableMouse(true)
		anchor:SetMovable(true)
		anchor:RegisterForDrag("LeftButton")
		anchor:SetScript("OnDragStart", function(f)
			if not self.db.locked then
				local f = self.buttons["arena1"]
				f:StartMoving()
			end
		end)
		anchor:SetScript("OnDragStop", function(f)
			local f = self.buttons["arena1"]
			f:StopMovingOrSizing()
			local scale = f:GetEffectiveScale()
			self.db.x[unit] = f:GetLeft() * scale
			self.db.y[unit] = f:GetTop() * scale
		end)
		anchor.text = anchor:CreateFontString("GladiusButtonAnchorText", "OVERLAY")
		self.anchor = anchor
		-- background
		local background = CreateFrame("Frame", "GladiusButtonBackground", UIParent, BackdropTemplateMixin and "BackdropTemplate");
		background:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16})
		background:SetBackdropColor(self.db.backgroundColor.r, self.db.backgroundColor.g, self.db.backgroundColor.b, self.db.backgroundColor.a)
		background:SetFrameStrata("BACKGROUND")
		self.background = background
	end
end

function Gladius:UNIT_AURA(event, unit)
	if not self:IsValidUnit(unit) then
		return
	end

	self:ShowUnit(unit)
end

function Gladius:UNIT_SPELLCAST_START(event, unit)
	if not self:IsValidUnit(unit) then
		return
	end

	self:ShowUnit(unit)
end

function Gladius:UNIT_HEALTH(event, unit)
	if not unit then
		return
	end
	if not self:IsValidUnit(unit) then
		return
	end

	-- update unit
	self:ShowUnit(unit)

	if UnitIsDeadOrGhost(unit) then
		self:UpdateAlpha(unit, 0.5)
	end
end

function Gladius:IsUnitShown(unit)
	return self.buttons[unit] and self.buttons[unit]:GetAlpha() == 1
end

function Gladius:GetUnitFrame(unit)
	return self.buttons[unit]
end

function Gladius:IsValidUnit(unit)
	if not unit then
		return
	end

	return strfind(unit, "arena") and not strfind(unit, "pet")
end
