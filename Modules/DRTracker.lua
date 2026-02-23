local Gladius = _G.Gladius
if not Gladius then
	DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "DRTracker"))
end
local L = Gladius.L
local LSM

local DRData = LibStub("DRData-1.0")

-- Global Functions
local _G = _G
local ipairs = ipairs
local next = next
local pairs = pairs
local select = select
local strfind = string.find
local tonumber = tonumber
local unpack = unpack

local CreateFontString = CreateFontString
local CreateFrame = CreateFrame
local GetSpellTexture = GetSpellTexture
local GetTime = GetTime
local IsInInstance = IsInInstance
local UnitGUID = UnitGUID

local function ApplyCooldownTextStyle(cooldown, iconSize, fontSize)
	if not cooldown then
		return
	end

	cooldown:SetSwipeColor(0, 0, 0, 0.6)
	cooldown:SetDrawBling(false)
	cooldown:SetHideCountdownNumbers(false)

	local sized = false
	if cooldown.Text and cooldown.Text.SetFont then
		local fontPath = cooldown.Text:GetFont()
		if fontPath then
			cooldown.Text:SetFont(fontPath, fontSize or 12, "OUTLINE")
		end
		cooldown.Text:SetJustifyH("CENTER")
		cooldown.Text:SetJustifyV("MIDDLE")
		sized = true
	end

	if not sized then
		local n = select("#", cooldown:GetRegions())
		for i = 1, n do
			local region = select(i, cooldown:GetRegions())
			if region and region.GetObjectType and region:GetObjectType() == "FontString" and region.SetFont then
				local fontPath = region:GetFont()
				if fontPath then
					region:SetFont(fontPath, fontSize or 12, "OUTLINE")
				end
				region:SetJustifyH("CENTER")
				region:SetJustifyV("MIDDLE")
				break
			end
		end
	end
end


local DRTracker = Gladius:NewModule("DRTracker", false, true, {
	drTrackerAttachTo = "ClassIcon",
	drTrackerAnchor = "TOPRIGHT",
	drTrackerRelativePoint = "TOPLEFT",
	drTrackerAdjustSize = true,
	drTrackerMargin = 5,
	drTrackerSize = 52,
	drTrackerOffsetX = 0,
	drTrackerOffsetY = 0,
	drTrackerFrameLevel = 1,
	drTrackerGloss = false,
	drTrackerGlossColor = {r = 1, g = 1, b = 1, a = 0.4},
	drTrackerCooldown = false,
	drTrackerCooldownReverse = false,
	drFontSize = 18,
	drFontColor = {r = 0, g = 1, b = 0, a = 1},
	drCategories = { },
	drBorder = true,
})

function DRTracker:OnInitialize()
	-- init frames
	self.frame = { }
end


function DRTracker:OnEnable()
	-- COMBAT_LOG_EVENT_UNFILTERED is protected on Midnight (12.x), skip registration.
	-- Use Blizzard's SpellDiminishStatusTray instead of custom DR tracking.
	LSM = Gladius.LSM

	if not self.frame then
		self.frame = { }
	end
	self.blizzDRTrays = {}
	self.originalDRTrayState = {}
	self.retryTimers = {}
	self.drCVarEnabled = false
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "HandleZoneChange")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "HandleZoneChange")
end

function DRTracker:OnDisable()
	self:UnregisterAllEvents()
	for _, frame in pairs(self.frame) do
		frame:SetAlpha(0)
	end
	if self.blizzDRTrays then
		for id in pairs(self.blizzDRTrays) do
			self:RestoreBlizzDRTray(id)
		end
		self.blizzDRTrays = {}
	end
	self.originalDRTrayState = {}
	-- Cancel any pending retry timers
	if self.retryTimers then
		for id, ticker in pairs(self.retryTimers) do
			ticker:Cancel()
		end
		self.retryTimers = {}
	end
	self.drCVarEnabled = false
end

function DRTracker:OnProfileChanged()
	for unit, _ in pairs(self.frame) do
		self:Reset(unit)
	end
	if Gladius.dbi.profile.modules["DRTracker"] then
		Gladius:EnableModule("DRTracker")
	else
		Gladius:DisableModule("DRTracker")
	end
end

function DRTracker:GetAttachTo()
	return Gladius.db.drTrackerAttachTo
end

function DRTracker:GetFrame(unit)
	return self.frame[unit]
end

function DRTracker:UpdateColors(unit)
	for cat, frame in pairs(self.frame[unit].tracker) do
		local tracked = self.frame[unit].tracker[cat]
		tracked.normalTexture:SetVertexColor(Gladius.db.drTrackerGlossColor.r, Gladius.db.drTrackerGlossColor.g, Gladius.db.drTrackerGlossColor.b, Gladius.db.drTrackerGloss and Gladius.db.drTrackerGlossColor.a or 0)
		tracked.text:SetTextColor(Gladius.db.drFontColor.r, Gladius.db.drFontColor.g, Gladius.db.drFontColor.b, Gladius.db.drFontColor.a)
	end
end

-- NOTE: Do NOT replace AnchorFirstTrayItem/AnchorNextTrayItem on the tray.
-- Replacing methods taints the tray object, causing Blizzard's
-- UpdateTrayItemAnchoring to fail when accessing activeItemForCategory
-- (forbidden table). Instead, the tray's SetPoint anchor controls visual
-- growth direction via ResizeLayoutFrame — same approach as sArena_Updated2
-- and sArena_Reloaded.

function DRTracker:StyleBlizzDRItem(drFrame, iconSize)
	if not drFrame then
		return
	end

	drFrame:EnableMouse(false)
	if drFrame.SetMouseClickEnabled then
		drFrame:SetMouseClickEnabled(false)
	end

	if not drFrame._gladiusStyled then
		drFrame._gladiusStyled = true

		drFrame.Boverlay = CreateFrame("Frame", nil, drFrame)
		drFrame.Boverlay:SetAllPoints(drFrame)
		drFrame.Boverlay:SetFrameStrata("MEDIUM")
		drFrame.Boverlay:SetFrameLevel(26)
		drFrame.Boverlay:Show()

		drFrame.Border = drFrame.Boverlay:CreateTexture(nil, "OVERLAY", nil, 6)
		drFrame.Border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
		drFrame.Border:SetVertexColor(0, 1, 0, 1)

		drFrame.DRTextFrame = CreateFrame("Frame", nil, drFrame)
		drFrame.DRTextFrame:SetAllPoints(drFrame)
		drFrame.DRTextFrame:SetFrameStrata("HIGH")
		drFrame.DRTextFrame:SetFrameLevel(30)

		drFrame.DRText = drFrame.DRTextFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		drFrame.DRText:SetPoint("BOTTOMRIGHT", 4, -4)
		drFrame.DRText:SetTextColor(0, 1, 0, 1)
		drFrame.DRText:SetText("\194\189")

		if drFrame.ImmunityIndicator and not drFrame._gladiusImmuneOverlay then
			drFrame._gladiusImmuneOverlay = true
			drFrame.ImmunityIndicator:SetFrameStrata("MEDIUM")
			drFrame.ImmunityIndicator:SetFrameLevel(27)
			drFrame.ImmunityIndicator:SetAlpha(0)

			local immuneOverlay = CreateFrame("Frame", nil, drFrame.ImmunityIndicator)
			immuneOverlay:SetAllPoints(drFrame)
			immuneOverlay:SetFrameStrata("HIGH")
			immuneOverlay:SetFrameLevel(35)
			immuneOverlay:SetIgnoreParentAlpha(true)

			drFrame.BorderImmune = immuneOverlay:CreateTexture(nil, "OVERLAY", nil, 7)
			drFrame.BorderImmune:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
			drFrame.BorderImmune:SetVertexColor(1, 0, 0, 1)

			drFrame.DRText2 = immuneOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
			drFrame.DRText2:SetPoint("BOTTOMRIGHT", 4, -4)
			drFrame.DRText2:SetTextColor(1, 0, 0, 1)
			drFrame.DRText2:SetText("%")
		end

		if not drFrame._gladiusOnHideHooked then
			drFrame._gladiusOnHideHooked = true
			drFrame:HookScript("OnHide", function()
				if drFrame.Border then
					drFrame.Border:SetVertexColor(0, 1, 0, 1)
				end
				if drFrame.DRText then
					drFrame.DRText:SetText("\194\189")
					drFrame.DRText:SetTextColor(0, 1, 0, 1)
				end
			end)
		end

		if not drFrame._gladiusOnShowHooked then
			drFrame._gladiusOnShowHooked = true
			drFrame:HookScript("OnShow", function()
				drFrame:SetSize(drFrame._gladiusIconSize or iconSize, drFrame._gladiusIconSize or iconSize)
			end)
		end
	end

	local borderSize = 2.5
	local innerSize = iconSize - borderSize * 2
	drFrame._gladiusIconSize = innerSize
	drFrame:SetSize(innerSize, innerSize)
	if drFrame.Border then
		drFrame.Border:ClearAllPoints()
		drFrame.Border:SetPoint("TOPLEFT", drFrame, "TOPLEFT", -borderSize, borderSize)
		drFrame.Border:SetPoint("BOTTOMRIGHT", drFrame, "BOTTOMRIGHT", borderSize, -borderSize)
	end
	if drFrame.BorderImmune then
		drFrame.BorderImmune:ClearAllPoints()
		drFrame.BorderImmune:SetPoint("TOPLEFT", drFrame, "TOPLEFT", -borderSize, borderSize)
		drFrame.BorderImmune:SetPoint("BOTTOMRIGHT", drFrame, "BOTTOMRIGHT", borderSize, -borderSize)
	end
	if drFrame.DRText then
		drFrame.DRText:SetFont("Fonts\\ARIALN.TTF", Gladius.db.drFontSize or 14, "OUTLINE")
	end
	if drFrame.DRText2 then
		drFrame.DRText2:SetFont("Fonts\\ARIALN.TTF", Gladius.db.drFontSize or 14, "OUTLINE")
	end

	ApplyCooldownTextStyle(drFrame.Cooldown, iconSize, Gladius.db.drFontSize or 12)
end

function DRTracker:StyleBlizzDRTray(unit, id, drTray)
	if not drTray or not unit then
		return
	end

	local parent = Gladius:GetParent(unit, Gladius.db.drTrackerAttachTo)
	local iconSize = (self.frame[unit] and self.frame[unit]:GetHeight()) or Gladius.db.drTrackerSize
	local halfSize = iconSize / 2
	drTray:ClearAllPoints()
	drTray:SetPoint(Gladius.db.drTrackerAnchor, parent, Gladius.db.drTrackerRelativePoint, Gladius.db.drTrackerOffsetX - halfSize, Gladius.db.drTrackerOffsetY)
	drTray:SetFrameStrata("HIGH")
	drTray:SetFrameLevel(Gladius.db.drTrackerFrameLevel + 5)
	drTray:SetScale(1)
	for _, drFrame in ipairs({ drTray:GetChildren() }) do
		self:StyleBlizzDRItem(drFrame, iconSize)
	end

	if not drTray._gladiusOnEventHooked then
		drTray._gladiusOnEventHooked = true
		local tracker = self
		local trayRef = drTray
		local unitRef = unit
		local idRef = id
		drTray:HookScript("OnEvent", function(_, event)
			if event ~= "UNIT_SPELL_DIMINISH_CATEGORY_STATE_UPDATED" then
				return
			end
			tracker:StyleBlizzDRTray(unitRef, idRef, trayRef)
		end)

		-- Catch newly created pool items that haven't been styled yet.
		drTray:HookScript("OnUpdate", function()
			local sz = (tracker.frame[unitRef] and tracker.frame[unitRef]:GetHeight()) or Gladius.db.drTrackerSize
			for _, child in ipairs({ trayRef:GetChildren() }) do
				if not child._gladiusStyled then
					tracker:StyleBlizzDRItem(child, sz)
				end
			end
		end)
	end
end

function DRTracker:UpdateIcon(unit, drCat)
	local tracked = self.frame[unit].tracker[drCat]
	tracked:EnableMouse(false)
	tracked.reset = 0
	tracked:SetWidth(self.frame[unit]:GetHeight())
	tracked:SetHeight(self.frame[unit]:GetHeight())
	tracked:SetNormalTexture("Interface\\AddOns\\Gladius_Updated_by_sammers\\Images\\Gloss")
	tracked.texture = _G[tracked:GetName().."Icon"]
	tracked.normalTexture = _G[tracked:GetName().."NormalTexture"]

	tracked.cooldown = _G[tracked:GetName().."Cooldown"]
	tracked.cooldown.isDisabled = not Gladius.db.drTrackerCooldown
	tracked.cooldown:SetReverse(Gladius.db.drTrackerCooldownReverse)
	Gladius:Call(Gladius.modules.Timer, "RegisterTimer", tracked, Gladius.db.drTrackerCooldown)

	if not tracked.text then
		tracked.text = tracked:CreateFontString(nil, "OVERLAY")
	end

	tracked.text:SetDrawLayer("OVERLAY")
	tracked.text:SetJustifyH("RIGHT")
	tracked.text:SetPoint("BOTTOMRIGHT", tracked, -2, 0)
	tracked.text:SetFont(LSM:Fetch(LSM.MediaType.FONT, Gladius.db.globalFont), Gladius.db.drFontSize, "OUTLINE")
	tracked.text:SetTextColor(Gladius.db.drFontColor.r, Gladius.db.drFontColor.g, Gladius.db.drFontColor.b, Gladius.db.drFontColor.a)
	-- style action button
	tracked.normalTexture:SetHeight(self.frame[unit]:GetHeight() + self.frame[unit]:GetHeight() * 0.4)
	tracked.normalTexture:SetWidth(self.frame[unit]:GetWidth() + self.frame[unit]:GetWidth() * 0.4)
	tracked.normalTexture:ClearAllPoints()
	tracked.normalTexture:SetPoint("CENTER", 0, 0)
	tracked:SetNormalTexture("Interface\\AddOns\\Gladius_Updated_by_sammers\\Images\\Gloss")
	tracked.texture:ClearAllPoints()
	tracked.texture:SetPoint("TOPLEFT", tracked, "TOPLEFT")
	tracked.texture:SetPoint("BOTTOMRIGHT", tracked, "BOTTOMRIGHT")
	if Gladius.db.drBorder then
		tracked.texture:SetTexCoord(0,1,0,1)
	else
		tracked.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	end
	tracked.normalTexture:SetVertexColor(Gladius.db.drTrackerGlossColor.r, Gladius.db.drTrackerGlossColor.g, Gladius.db.drTrackerGlossColor.b, Gladius.db.drTrackerGloss and Gladius.db.drTrackerGlossColor.a or 0)
end

function DRTracker:DRFaded(unit, spellID, force)
	local drCat = DRData:GetSpellCategory(spellID)
	if not force and Gladius.db.drCategories[drCat] == false then
		return
	end
	local drTexts = {
		[1] = {"\194\189", 0, 1, 0},
		[0.5] = {"\194\188", 1, 0.65, 0},
		[0.25] = {"%", 1, 0, 0},
		[0] = {"%", 1, 0, 0},
	}
	if not self.frame[unit].tracker[drCat] then
		self.frame[unit].tracker[drCat] = CreateFrame("CheckButton", "Gladius"..self.name.."FrameCat"..drCat..unit, self.frame[unit], "ActionButtonTemplate")
		self:UpdateIcon(unit, drCat)
	end
	local tracked = self.frame[unit].tracker[drCat]
	tracked.active = true
	if tracked and tracked.reset <= GetTime() then
		tracked.diminished = 1
	else
		tracked.diminished = DRData:NextDR(tracked.diminished)
	end
	if Gladius.test and tracked.diminished == 0 then
		tracked.diminished = 1
	end
	tracked.timeLeft = DRData:GetResetTime()
	tracked.reset = tracked.timeLeft + GetTime()
	local text, r, g, b = unpack(drTexts[tracked.diminished])
	tracked.text:SetText(text)
	tracked.text:SetTextColor(r,g,b)
	tracked.texture:SetTexture(GetSpellTexture(spellID))
	Gladius:Call(Gladius.modules.Timer, "SetTimer", tracked, tracked.timeLeft)
	tracked:SetScript("OnUpdate", function(f, elapsed)
		f.timeLeft = f.timeLeft - elapsed
		if f.timeLeft <= 0 then
			f.active = false
			Gladius:Call(Gladius.modules.Timer, "HideTimer", f)
			-- position icons
			self:SortIcons(unit)
			-- reset script
			tracked:SetScript("OnUpdate", nil)
		end
	end)
	tracked:SetAlpha(1)
	self:SortIcons(unit)
end

function DRTracker:SortIcons(unit)
	local lastFrame = self.frame[unit]
	for cat, frame in pairs(self.frame[unit].tracker) do
		frame:ClearAllPoints()
		frame:SetAlpha(0)
		if frame.active then
			frame:SetPoint(Gladius.db.drTrackerAnchor, lastFrame, lastFrame == self.frame[unit] and Gladius.db.drTrackerAnchor or Gladius.db.drTrackerRelativePoint, strfind(Gladius.db.drTrackerAnchor,"LEFT") and Gladius.db.drTrackerMargin or - Gladius.db.drTrackerMargin, 0)
			lastFrame = frame
			frame:SetAlpha(1)
		end
	end
end

function DRTracker:COMBAT_LOG_EVENT_UNFILTERED(event)
	local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, auraType = CombatLogGetCurrentEventInfo()
	local unit
	for u, _ in pairs(Gladius.buttons) do
		if UnitGUID(u) == destGUID then
			unit = u
		end
	end
	if not unit then
		return
	end
	-- Enemy had a debuff refreshed before it faded, so fade + gain it quickly
	if eventType == "SPELL_AURA_REFRESH" then
		if auraType == "DEBUFF" and DRData:GetSpellCategory(spellID) then
			self:DRFaded(unit, spellID)
		end
	-- Buff or debuff faded from an enemy
	elseif eventType == "SPELL_AURA_REMOVED" then
		if auraType == "DEBUFF" and DRData:GetSpellCategory(spellID) then
			self:DRFaded(unit, spellID)
		end
	end
end

function DRTracker:CreateFrame(unit)
	local button = Gladius.buttons[unit]
	if not button then
		return
	end
	-- create frame
	self.frame[unit] = CreateFrame("Frame", "Gladius"..self.name.."Frame"..unit, button)

end

function DRTracker:Update(unit)
	-- create frame
	if not self.frame[unit] then
		self:CreateFrame(unit)
	end
	-- frame level
	self.frame[unit]:SetFrameLevel(Gladius.db.drTrackerFrameLevel)
	-- when the attached module is disabled
	if not Gladius:GetModule(self:GetAttachTo()) then
		Gladius.db.drTrackerAttachTo = "Frame"
	end
	if Gladius.db.drTrackerAdjustSize then
		if self:GetAttachTo() == "Frame" then
			local height = false
			-- need to rethink that
			--[[for _, module in pairs(Gladius.modules) do
				if module:GetAttachTo() == self.name then
					height = false
				end
			end]]
			if height then
				self.frame[unit]:SetWidth(Gladius.buttons[unit].height)
				self.frame[unit]:SetHeight(Gladius.buttons[unit].height)
			else
				self.frame[unit]:SetWidth(Gladius.buttons[unit].frameHeight)
				self.frame[unit]:SetHeight(Gladius.buttons[unit].frameHeight)
			end
		else
			self.frame[unit]:SetWidth(Gladius:GetModule(self:GetAttachTo()).frame[unit]:GetHeight() or 1)
			self.frame[unit]:SetHeight(Gladius:GetModule(self:GetAttachTo()).frame[unit]:GetHeight() or 1)
		end
	else
		self.frame[unit]:SetWidth(Gladius.db.drTrackerSize)
		self.frame[unit]:SetHeight(Gladius.db.drTrackerSize)
	end
	-- anchor point (after sizing so iconSize is available)
	self.frame[unit]:ClearAllPoints()
	local parent = Gladius:GetParent(unit, Gladius.db.drTrackerAttachTo)
	local halfSize = self.frame[unit]:GetHeight() / 2
	self.frame[unit]:SetPoint(Gladius.db.drTrackerAnchor, parent, Gladius.db.drTrackerRelativePoint, Gladius.db.drTrackerOffsetX - halfSize, Gladius.db.drTrackerOffsetY)
	-- update icons
	if not self.frame[unit].tracker then
		self.frame[unit].tracker = { }
	else
		for cat, frame in pairs(self.frame[unit].tracker) do
			frame:SetWidth(self.frame[unit]:GetHeight())
			frame:SetHeight(self.frame[unit]:GetHeight())
			frame.normalTexture:SetHeight(self.frame[unit]:GetHeight() + self.frame[unit]:GetHeight() * 0.4)
			frame.normalTexture:SetWidth(self.frame[unit]:GetWidth() + self.frame[unit]:GetWidth() * 0.4)
			self:UpdateIcon(unit, cat)
		end
		self:SortIcons(unit)
	end

	-- Re-apply stolen Blizzard tray visuals/layout when settings change.
	local id = tonumber(unit:match("arena(%d)"))
	if id and self.blizzDRTrays and self.blizzDRTrays[id] then
		self:StyleBlizzDRTray(unit, id, self.blizzDRTrays[id])
	end
	-- hide
	self.frame[unit]:SetAlpha(0)
end

-- Restore Blizzard DR tray to its original parent/position/state.
function DRTracker:RestoreBlizzDRTray(id)
	local drTray = self.blizzDRTrays and self.blizzDRTrays[id]
	if not drTray then
		return
	end

	local state = self.originalDRTrayState and self.originalDRTrayState[id]
	local blizzFrame = _G["CompactArenaFrameMember" .. id]

	if state and state.parent then
		drTray:SetParent(state.parent)
	elseif blizzFrame then
		drTray:SetParent(blizzFrame)
	end

	drTray:ClearAllPoints()
	-- GetPoint() may return secret values in arena context, so always use
	-- a known-safe anchor when restoring the tray to its Blizzard parent.
	if blizzFrame then
		drTray:SetPoint("TOPLEFT", blizzFrame, "TOPLEFT", 0, 0)
	end

	if state and state.frameLevel then
		drTray:SetFrameLevel(state.frameLevel)
	end
	if state and state.scale and state.scale > 0 then
		drTray:SetScale(state.scale)
	end
end

-- Ensure Blizzard trays are restored when leaving arena or loading screens interrupt normal reset flow.
function DRTracker:HandleZoneChange()
	local _, instanceType = IsInInstance()
	if instanceType == "arena" then
		return
	end

	if self.blizzDRTrays then
		for id in pairs(self.blizzDRTrays) do
			self:RestoreBlizzDRTray(id)
			self.blizzDRTrays[id] = nil
		end
	end

	if self.originalDRTrayState then
		self.originalDRTrayState = {}
	end

	if self.retryTimers then
		for id, ticker in pairs(self.retryTimers) do
			ticker:Cancel()
			self.retryTimers[id] = nil
		end
	end

	self.drCVarEnabled = false
end

-- Steal and configure Blizzard's SpellDiminishStatusTray for a given arena unit.
-- Returns true if successful, false if the tray was not found.
function DRTracker:StealBlizzDRTray(unit, id)
	local blizzFrame = _G["CompactArenaFrameMember" .. id]
	if not blizzFrame or not blizzFrame.SpellDiminishStatusTray then
		return false
	end
	-- Don't re-steal if already done for this id
	if self.blizzDRTrays[id] then
		return true
	end

	local drTray = blizzFrame.SpellDiminishStatusTray

	-- Keep original state so we can fully restore on reset/disable.
	-- Note: GetPoint() returns secret values in arena, so we don't store point
	-- data — RestoreBlizzDRTray uses a known-safe fallback anchor instead.
	if not self.originalDRTrayState[id] then
		self.originalDRTrayState[id] = {
			parent = drTray:GetParent(),
			frameLevel = drTray:GetFrameLevel(),
			scale = drTray:GetScale(),
		}
	end

	-- Reparent to Gladius button frame
	drTray:SetParent(Gladius.buttons[unit])
	drTray:ClearAllPoints()
	local parent = Gladius:GetParent(unit, Gladius.db.drTrackerAttachTo)
	local iconSize = (self.frame[unit] and self.frame[unit]:GetHeight()) or Gladius.db.drTrackerSize
	local halfSize = iconSize / 2
	drTray:SetPoint(Gladius.db.drTrackerAnchor, parent, Gladius.db.drTrackerRelativePoint, Gladius.db.drTrackerOffsetX - halfSize, Gladius.db.drTrackerOffsetY)
	drTray:EnableMouse(false)
	if drTray.SetMouseClickEnabled then
		drTray:SetMouseClickEnabled(false)
	end
	drTray:SetFrameStrata("HIGH")
	drTray:SetFrameLevel(Gladius.db.drTrackerFrameLevel + 5)
	drTray:Show()
	self:StyleBlizzDRTray(unit, id, drTray)

	self.blizzDRTrays[id] = drTray
	return true
end

function DRTracker:Show(unit)
	-- In test mode, show the custom DR frame (Blizzard arena frames don't exist)
	if Gladius.test then
		self.frame[unit]:SetAlpha(1)
		return
	end

	local id = tonumber(unit:match("arena(%d)"))

	local _, instanceType = IsInInstance()
	if instanceType ~= "arena" then
		if id and self.blizzDRTrays and self.blizzDRTrays[id] then
			self:RestoreBlizzDRTray(id)
			self.blizzDRTrays[id] = nil
			if self.originalDRTrayState then
				self.originalDRTrayState[id] = nil
			end
		end
		self.frame[unit]:SetAlpha(0)
		return
	end

	if not self.drCVarEnabled then
		-- Enable Blizzard's built-in DR tray only when actually needed in arena.
		pcall(function()
			C_CVar.SetCVar("spellDiminishPVPEnemiesEnabled", "1")
		end)
		self.drCVarEnabled = true
	end

	-- Keep custom DR frame hidden (CLEU is protected on Midnight)
	self.frame[unit]:SetAlpha(0)

	if not id then return end

	-- Try to steal Blizzard's SpellDiminishStatusTray
	if not self.blizzDRTrays[id] then
		local found = self:StealBlizzDRTray(unit, id)
		-- If not found immediately, retry with a timer.
		-- The tray may not exist yet if Blizzard creates it lazily.
		if not found and not self.retryTimers[id] then
			local attempts = 0
			self.retryTimers[id] = C_Timer.NewTicker(0.5, function()
				attempts = attempts + 1
				-- Stop if found, unit gone, or max attempts reached
				if not Gladius.buttons[unit] then
					self.retryTimers[id]:Cancel()
					self.retryTimers[id] = nil
					return
				end
				if self:StealBlizzDRTray(unit, id) or attempts >= 20 then
					if self.retryTimers[id] then
						self.retryTimers[id]:Cancel()
						self.retryTimers[id] = nil
					end
				end
			end)
		end
	end
end

function DRTracker:Reset(unit)
	if not self.frame[unit] then
		return
	end
	-- hide icons
	for _, frame in pairs(self.frame[unit].tracker) do
		frame.active = false
		frame.diminished = 1
		Gladius:Call(Gladius.modules.Timer, "HideTimer", frame)
		frame:SetScript("OnUpdate", nil)
		frame:SetAlpha(0)
	end
	-- hide
	self.frame[unit]:SetAlpha(0)

	-- Clear stolen Blizzard tray reference so it can be re-stolen next arena
	local id = tonumber(unit:match("arena(%d)"))
	if id then
		self:RestoreBlizzDRTray(id)
		self.blizzDRTrays[id] = nil
		if self.originalDRTrayState then
			self.originalDRTrayState[id] = nil
		end
		if self.retryTimers and self.retryTimers[id] then
			self.retryTimers[id]:Cancel()
			self.retryTimers[id] = nil
		end
	end
end

function DRTracker:Test(unit)
	self:DRFaded(unit, 33786, true)
	self:DRFaded(unit, 8122, true)
	self:DRFaded(unit, 118, true)
end

function DRTracker:GetOptions()
	local t = {
		general = {
			type = "group",
			name = L["General"],
			order = 1,
			args = {
				widget = {
					type = "group",
					name = L["Widget"],
					desc = L["Widget settings"],
					inline = true,
					order = 1,
					args = {
						drTrackerMargin = {
							type = "range",
							name = L["DRTracker Space"],
							desc = L["Space between the icons"],
							min = 0,
							max = 100,
							step = 1,
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							order = 5,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 7,
						},
						drBorder = {
							type = "toggle",
							name = L["DRTracker Icon Border"],
							desc = L["Display the border around drtracker icons"],
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							order = 8,
						},
						drTrackerCooldown = {
							type = "toggle",
							name = L["DRTracker Cooldown Spiral"],
							desc = L["Display the cooldown spiral for important auras"],
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							hidden = function()
								return not Gladius.db.advancedOptions
							end,
							order = 10,
						},
						drTrackerCooldownReverse = {
							type = "toggle",
							name = L["DRTracker Cooldown Reverse"],
							desc = L["Invert the dark/bright part of the cooldown spiral"],
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							hidden = function()
								return not Gladius.db.advancedOptions
							end,
							order = 15,
						},
						sep2 = {
							type = "description",
							name = "",
							width = "full",
							order = 17,
						},
						drTrackerGloss = {
							type = "toggle",
							name = L["DRTracker Gloss"],
							desc = L["Toggle gloss on the drTracker icon"],
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							hidden = function()
								return not Gladius.db.advancedOptions
							end,
							order = 25,
						},
						drTrackerGlossColor = {
							type = "color",
							name = L["DRTracker Gloss Color"],
							desc = L["Color of the drTracker icon gloss"],
							get = function(info)
								return Gladius:GetColorOption(info)
							end,
							set = function(info, r, g, b, a)
								return Gladius:SetColorOption(info, r, g, b, a)
							end,
							hasAlpha = true,
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							hidden = function()
								return not Gladius.db.advancedOptions
							end,
							order = 30,
						},
						sep3 = {
							type = "description",
							name = "",
							width = "full",
							hidden = function()
								return not Gladius.db.advancedOptions
							end,
							order = 33,
						},
						drTrackerFrameLevel = {
							type = "range",
							name = L["DRTracker Frame Level"],
							desc = L["Frame level of the drTracker"],
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							hidden = function()
								return not Gladius.db.advancedOptions
							end,
							min = 1,
							max = 5,
							step = 1,
							width = "double",
							order = 35,
						},
					},
				},
				size = {
					type = "group",
					name = L["Size"],
					desc = L["Size settings"],
					inline = true,
					order = 2,
					args = {
						drTrackerAdjustSize = {
							type = "toggle",
							name = L["DRTracker Adjust Size"],
							desc = L["Adjust drTracker size to the frame size"],
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							order = 5,
						},
						drTrackerSize = {
							type = "range",
							name = L["DRTracker Size"],
							desc = L["Size of the drTracker"],
							min = 10,
							max = 100,
							step = 1,
							disabled = function()
								return Gladius.dbi.profile.drTrackerAdjustSize or not Gladius.dbi.profile.modules[self.name]
							end,
							order = 10,
						},
					},
				},
				font = {
					type = "group",
					name = L["Font"],
					desc = L["Font settings"],
					inline = true,
					hidden = function()
						return not Gladius.db.advancedOptions
					end,
					order = 3,
					args = {
						--[[drFontColor = {
							type = "color",
							name = L["DR Text Color"],
							desc = L["Text color of the DR text"],
							hasAlpha = true,
							get = function(info)
								return Gladius:GetColorOption(info)
							end,
							set = function(info, r, g, b, a)
								return Gladius:SetColorOption(info, r, g, b, a)
							end,
							disabled = function()
								return not Gladius.dbi.profile.castText or not Gladius.dbi.profile.modules[self.name]
							end,
							order = 10,
						},]]
						drFontSize = {
							type = "range",
							name = L["DR Text Size"],
							desc = L["Text size of the DR text"],
							min = 1,
							max = 20,
							step = 1,
							disabled = function()
								return not Gladius.dbi.profile.castText or not Gladius.dbi.profile.modules[self.name]
							end,
							order = 15,
						},
					},
				},
				position = {
					type = "group",
					name = L["Position"],
					desc = L["Position settings"],
					inline = true,
					order = 4,
					args = {
						drTrackerAttachTo = {
							type = "select",
							name = L["DRTracker Attach To"],
							desc = L["Attach drTracker to the given frame"],
							values = function()
								return Gladius:GetModules(self.name)
							end,
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							order = 5,
						},
						drTrackerPosition = {
							type = "select",
							name = L["DRTracker Position"],
							desc = L["Position of the class icon"],
							values={["LEFT"] = L["Left"], ["RIGHT"] = L["Right"]},
							get = function()
								return strfind(Gladius.db.drTrackerAnchor, "RIGHT") and "LEFT" or "RIGHT"
							end,
							set = function(info, value)
								if (value == "LEFT") then
									Gladius.db.drTrackerAnchor = "TOPRIGHT"
									Gladius.db.drTrackerRelativePoint = "TOPLEFT"
								else
									Gladius.db.drTrackerAnchor = "TOPLEFT"
									Gladius.db.drTrackerRelativePoint = "TOPRIGHT"
								end
								Gladius:UpdateFrame(info[1])
							end,
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							hidden = function()
								return Gladius.db.advancedOptions
							end,
							order = 6,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 7,
						},
						drTrackerAnchor = {
							type = "select",
							name = L["DRTracker Anchor"],
							desc = L["Anchor of the drTracker"],
							values = function()
								return Gladius:GetPositions()
							end,
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							hidden = function()
								return not Gladius.db.advancedOptions
							end,
							order = 10,
						},
						drTrackerRelativePoint = {
							type = "select",
							name = L["DRTracker Relative Point"],
							desc = L["Relative point of the drTracker"],
							values = function()
								return Gladius:GetPositions()
							end,
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							hidden = function()
								return not Gladius.db.advancedOptions
							end,
							order = 15,
						},
						sep2 = {
							type = "description",
							name = "",
							width = "full",
							order = 17,
						},
						drTrackerOffsetX = {
							type = "range",
							name = L["DRTracker Offset X"],
							desc = L["X offset of the drTracker"],
							min = - 100,
							max = 100,
							step = 1,
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							order = 20,
						},
						drTrackerOffsetY = {
							type = "range",
							name = L["DRTracker Offset Y"],
							desc = L["Y offset of the drTracker"],
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							min = - 50,
							max = 50,
							step = 1,
							order = 25,
						},
					},
				},
			},
		},
	}
	t.categories = {
		type = "group",
		name = L["Categories"],
		order = 2,
		args = {
			categories = {
				type = "group",
				name = L["Categories"],
				desc = L["Category settings"],
				inline = true,
				order = 1,
				args = { },
			},
		},
	}
	local index = 1
	for key, name in pairs(DRData.categoryNames) do
		t.categories.args.categories.args[key] = {
			type = "toggle",
			name = name,
			get = function(info)
				if Gladius.dbi.profile.drCategories[info[#info]] == nil then
					return true
				else
					return Gladius.dbi.profile.drCategories[info[#info]]
				end
			end,
			set = function(info, value)
				Gladius.dbi.profile.drCategories[info[#info]] = value
				if not value then
					for unit, _ in pairs(self.frame) do
						self:Reset(unit)
					end
				end
				Gladius:UpdateFrame()
			end,
			disabled = function()
				return not Gladius.dbi.profile.modules[self.name]
			end,
			order = index * 5,
		}
		index = index + 1
	end
	return t
end
