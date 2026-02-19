local Gladius = _G.Gladius
if not Gladius then
	DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "Power Bar"))
end
local L = Gladius.L
local LSM

-- Global Functions
local strfind = string.find
local pairs = pairs

local CreateFrame = CreateFrame
local PowerBarColor = PowerBarColor
local UnitExists = UnitExists
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType
local UnitClass = UnitClass
local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE

local PowerBar = Gladius:NewModule("PowerBar", true, true, {
	powerBarAttachTo = "HealthBar",
	powerBarHeight = 15,
	powerBarAdjustWidth = true,
	powerBarWidth = 200,
	powerBarInverse = false,
	powerBarColor = {r = 1, g = 1, b = 1, a = 1},
	powerBarDefaultColor = true,
	powerBarBackgroundColor = {r = 1, g = 1, b = 1, a = 0.3},
	powerBarTexture = "Minimalist",
	powerBarOffsetX = 0,
	powerBarOffsetY = 0,
	powerBarAnchor = "TOPLEFT",
	powerBarRelativePoint = "BOTTOMLEFT",
	powerBarUseDefaultColorMana = false,
	powerBarColorMana = {r = 0.18, g = 0.44, b = 0.75, a = 1},
	powerBarUseDefaultColorRage = false,
	powerBarColorRage = {r = 1, g = 0, b = 0, a = 1},
	powerBarUseDefaultColorFocus = false,
	powerBarColorFocus = {r = 1, g = 0.5, b = 0.25, a = 1},
	powerBarUseDefaultColorEnergy = false,
	powerBarColorEnergy = {r = 1, g = 1, b = 0, a = 1},
	powerBarUseDefaultColorRunicPower = false,
	powerBarColorRunicPower = {r = 0, g = 0.82, b = 1, a = 1},
})

local powerTypeFallback = {
    -- Specializations
    ["Feral"] = 3,           -- Energy
    ["Windwalker"] = 3,      -- Energy
    ["Guardian"] = 1,        -- Rage

    -- Classes
    ["MAGE"] = 0, ["PRIEST"] = 0, ["WARLOCK"] = 0,
    ["SHAMAN"] = 0, ["PALADIN"] = 0, ["EVOKER"] = 0,
    ["ROGUE"] = 3, ["WARRIOR"] = 1, ["DEATHKNIGHT"] = 6,
    ["DEMONHUNTER"] = 17, ["HUNTER"] = 2, ["DRUID"] = 0,
}

function PowerBar:OnEnable()
	self:RegisterEvent("UNIT_POWER_UPDATE")
	self:RegisterEvent("UNIT_MAXPOWER", "UNIT_POWER_UPDATE")
	self:RegisterEvent("UNIT_MANA", "UNIT_POWER_UPDATE")
	--self:RegisterEvent("UNIT_RAGE", "UNIT_POWER_UPDATE")
	--self:RegisterEvent("UNIT_ENERGY", "UNIT_POWER_UPDATE")
	--self:RegisterEvent("UNIT_FOCUS", "UNIT_POWER_UPDATE")
	--self:RegisterEvent("UNIT_RUNIC_POWER", "UNIT_POWER_UPDATE")
	--self:RegisterEvent("UNIT_MAXMANA", "UNIT_POWER_UPDATE")
	--self:RegisterEvent("UNIT_MAXRAGE", "UNIT_POWER_UPDATE")
	--self:RegisterEvent("UNIT_MAXENERGY", "UNIT_POWER_UPDATE")
	--self:RegisterEvent("UNIT_MAXFOCUS", "UNIT_POWER_UPDATE")
	--self:RegisterEvent("UNIT_MAXRUNIC_POWER", "UNIT_POWER_UPDATE")
	self:RegisterEvent("UNIT_DISPLAYPOWER", "UNIT_POWER_UPDATE")
	LSM = Gladius.LSM
	-- set frame type
	if Gladius.db.healthBarAttachTo == "Frame" or strfind(Gladius.db.powerBarRelativePoint, "BOTTOM") then
		self.isBar = true
	else
		self.isBar = false
	end
	if not self.frame then
		self.frame = { }
	end
end

function PowerBar:OnDisable()
	self:UnregisterAllEvents()
	for unit in pairs(self.frame) do
		self.frame[unit]:SetAlpha(0)
	end
end

function PowerBar:GetAttachTo()
	return Gladius.db.powerBarAttachTo
end

function PowerBar:GetFrame(unit)
	return self.frame[unit]
end

function PowerBar:UNIT_POWER_UPDATE(event, unit)
	if not Gladius:IsValidUnit(unit) or not UnitExists(unit) then
		return
	end
	local power, maxPower, powerType = UnitPower(unit), UnitPowerMax(unit), UnitPowerType(unit)
	self:UpdatePower(unit, power, maxPower, powerType)
end

function PowerBar:UpdatePower(unit, power, maxPower, powerType)
	if not self.frame[unit] then
		return
	end
	if not self.frame[unit] then
		if not Gladius.buttons[unit] then
			Gladius:UpdateUnit(unit)
		else
			self:Update(unit)
		end
	end
	-- update min max values
	self.frame[unit]:SetMinMaxValues(0, maxPower)
	-- In 12.0, power values are secret for arena units; SetValue accepts secrets
	-- Inverse bar not supported (arithmetic on secrets crashes)
	self.frame[unit]:SetValue(power)
	-- update bar color
	if not Gladius.db.powerBarDefaultColor then
		local color = Gladius.db.powerBarColor
		self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a)
	else
		local color = self:GetBarColor(powerType)
		self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b)
	end
	self:UpdateSpecClassText(unit)
end

function PowerBar:UpdateColors(unit)
	local powerType
	if not Gladius.test then
		powerType = UnitPowerType(unit)
	else
		powerType = Gladius.testing[unit].powerType
	end
	if not Gladius.db.powerBarDefaultColor then
		local color = Gladius.db.powerBarColor
		self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a)
	else
		local color = self:GetBarColor(powerType)
		self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b)
	end
	self.frame[unit].background:SetVertexColor(Gladius.db.powerBarBackgroundColor.r, Gladius.db.powerBarBackgroundColor.g, Gladius.db.powerBarBackgroundColor.b, Gladius.db.powerBarBackgroundColor.a)
end

function PowerBar:CreateBar(unit)
	local button = Gladius.buttons[unit]
	if not button then
		return
	end
	-- create bar + text
	self.frame[unit] = CreateFrame("STATUSBAR", "Gladius"..self.name..unit, button)
	self.frame[unit].background = self.frame[unit]:CreateTexture("Gladius"..self.name..unit.."Background", "BACKGROUND")
	self.frame[unit].highlight = self.frame[unit]:CreateTexture("Gladius"..self.name.."Highlight"..unit, "OVERLAY")
	self.frame[unit].specClassText = self.frame[unit]:CreateFontString("Gladius"..self.name..unit.."SpecClassText", "OVERLAY")
end

function PowerBar:UpdateSpecClassText(unit)
	local frame = self.frame[unit]
	if not frame or not frame.specClassText then
		return
	end
	local text = ""
	if Gladius.test then
		local spec = Gladius.testing[unit] and Gladius.testing[unit].unitSpec
		local classToken = Gladius.testing[unit] and Gladius.testing[unit].unitClass
		local classText = classToken and (LOCALIZED_CLASS_NAMES_MALE[classToken] or classToken) or ""
		if spec and spec ~= "" and classText ~= "" then
			text = spec .. " " .. classText
		elseif spec and spec ~= "" then
			text = spec
		else
			text = classText
		end
	else
		local unitFrame = Gladius.buttons and Gladius.buttons[unit]
		local spec = unitFrame and unitFrame.spec or ""
		local classToken = unitFrame and unitFrame.class or ""
		if classToken == "" then
			local _, fallbackClass = UnitClass(unit)
			if fallbackClass then
				classToken = fallbackClass
				if unitFrame then
					unitFrame.class = fallbackClass
				end
			end
		end
		local classText = classToken ~= "" and (LOCALIZED_CLASS_NAMES_MALE[classToken] or classToken) or ""
		if spec ~= "" and classText ~= "" then
			text = spec .. " " .. classText
		elseif spec ~= "" then
			text = spec
		else
			text = classText
		end
	end
	frame.specClassText:SetText(text or "")
end

function PowerBar:Update(unit)
	-- check parent module
	if not Gladius:GetModule(Gladius.db.castBarAttachTo) then
		if self.frame[unit] then
			self.frame[unit]:Hide()
		end
		return
	end
	-- get unit powerType
	local powerType
	if not Gladius.test then
    powerType = UnitPowerType(unit) or self:GetUnitPowerTypeFallback(unit)
	else
		powerType = Gladius.testing[unit].powerType
	end
	-- create power bar
	if not self.frame[unit] then
		self:CreateBar(unit)
	end
	-- set bar type
	local parent = Gladius:GetParent(unit, Gladius.db.powerBarAttachTo)
	if Gladius.db.healthBarAttachTo == "Frame" or strfind(Gladius.db.powerBarRelativePoint, "BOTTOM") then
		self.isBar = true
	else
		self.isBar = false
	end
	-- update power bar
	self.frame[unit]:ClearAllPoints()
	local width = Gladius.db.powerBarAdjustWidth and Gladius.db.barWidth or Gladius.db.powerBarWidth
	-- add width of the widget if attached to an widget
	if Gladius.db.healthBarAttachTo ~= "Frame" and not strfind(Gladius.db.powerBarRelativePoint, "BOTTOM") and Gladius.db.powerBarAdjustWidth then
		if not Gladius:GetModule(Gladius.db.powerBarAttachTo).frame[unit] then
			Gladius:GetModule(Gladius.db.powerBarAttachTo):Update(unit)
		end
		width = width + Gladius:GetModule(Gladius.db.powerBarAttachTo).frame[unit]:GetWidth()
	end
	self.frame[unit]:SetHeight(Gladius.db.powerBarHeight)
	self.frame[unit]:SetWidth(width)
	self.frame[unit]:SetPoint(Gladius.db.powerBarAnchor, parent, Gladius.db.powerBarRelativePoint, Gladius.db.powerBarOffsetX, Gladius.db.powerBarOffsetY)
	self.frame[unit]:SetMinMaxValues(0, 1)
	self.frame[unit]:SetValue(1)
	self.frame[unit]:SetStatusBarTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, Gladius.db.powerBarTexture))
	-- disable tileing
	self.frame[unit]:GetStatusBarTexture():SetHorizTile(false)
	self.frame[unit]:GetStatusBarTexture():SetVertTile(false)
	-- update power bar background
	self.frame[unit].background:ClearAllPoints()
	self.frame[unit].background:SetAllPoints(self.frame[unit])
	self.frame[unit].background:SetWidth(self.frame[unit]:GetWidth())
	self.frame[unit].background:SetHeight(self.frame[unit]:GetHeight())
	self.frame[unit].background:SetTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, Gladius.db.powerBarTexture))
	self.frame[unit].background:SetVertexColor(Gladius.db.powerBarBackgroundColor.r, Gladius.db.powerBarBackgroundColor.g, Gladius.db.powerBarBackgroundColor.b, Gladius.db.powerBarBackgroundColor.a)
	-- disable tileing
	self.frame[unit].background:SetHorizTile(false)
	self.frame[unit].background:SetVertTile(false)
	-- set color
	if not Gladius.db.powerBarDefaultColor then
		local color = Gladius.db.powerBarColor
		self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a)
	else
		local color = self:GetBarColor(powerType)
		self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b)
	end
	-- update highlight texture
	self.frame[unit].highlight:SetAllPoints(self.frame[unit])
	self.frame[unit].highlight:SetTexture([=[Interface\QuestFrame\UI-QuestTitleHighlight]=])
	self.frame[unit].highlight:SetBlendMode("ADD")
	self.frame[unit].highlight:SetVertexColor(1.0, 1.0, 1.0, 1.0)
	self.frame[unit].highlight:SetAlpha(0)

	-- spec/class text (replaces old tag text on powerbar)
	local fontSize = Gladius.db.useGlobalFontSize and Gladius.db.globalFontSize or 11
	local fontPath = LSM:Fetch(LSM.MediaType.FONT, Gladius.db.globalFont)
	self.frame[unit].specClassText:ClearAllPoints()
	self.frame[unit].specClassText:SetPoint("LEFT", self.frame[unit], "LEFT", 2, 0)
	self.frame[unit].specClassText:SetJustifyH("LEFT")
	self.frame[unit].specClassText:SetJustifyV("MIDDLE")
	self.frame[unit].specClassText:SetFont(fontPath, fontSize)
	self.frame[unit].specClassText:SetTextColor(1, 1, 1, 1)
	self.frame[unit].specClassText:SetShadowOffset(1, -1)
	self.frame[unit].specClassText:SetShadowColor(0, 0, 0, 1)
	self:UpdateSpecClassText(unit)
	-- hide frame
	self.frame[unit]:SetAlpha(0)
end

function PowerBar:GetBarColor(powerType)
	if powerType == 0 and not Gladius.db.powerBarUseDefaultColorMana then
		return Gladius.db.powerBarColorMana
	elseif powerType == 1 and not Gladius.db.powerBarUseDefaultColorRage then
		return Gladius.db.powerBarColorRage
	elseif powerType == 2 and not Gladius.db.powerBarUseDefaultColorFocus then
		return Gladius.db.powerBarColorFocus
	elseif powerType == 3 and not Gladius.db.powerBarUseDefaultColorEnergy then
		return Gladius.db.powerBarColorEnergy
	elseif powerType == 6 and not Gladius.db.powerBarUseDefaultColorRunicPower then
		return Gladius.db.powerBarColorRunicPower
	end
	return PowerBarColor[powerType]
end

function PowerBar:GetUnitPowerTypeFallback(unit)
	local button = Gladius.buttons and Gladius.buttons[unit]
	if not button then
		return nil
	end
	local spec = button.spec
	local class = button.class
	if not class or class == "" then
		local _, fallbackClass = UnitClass(unit)
		if fallbackClass then
			class = fallbackClass
			button.class = fallbackClass
		end
	end
	return powerTypeFallback[spec] or powerTypeFallback[class]
end

function PowerBar:Show(unit)
    -- show frame
    self.frame[unit]:SetAlpha(1)
    self.frame[unit]:SetValue(1)
    if not Gladius.db.powerBarDefaultColor then
        local color = Gladius.db.powerBarColor
        self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a)
    else
        local powerType = UnitPowerType(unit) or self:GetUnitPowerTypeFallback(unit)
        local color = self:GetBarColor(powerType)
        if color then
            self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b)
        end
    end
    if not Gladius.test then
        self:UNIT_POWER_UPDATE("UNIT_POWER_UPDATE", unit)
    end
	self:UpdateSpecClassText(unit)
end

function PowerBar:Reset(unit)
    -- reset bar
    self.frame[unit]:SetMinMaxValues(0, 1)
    if not Gladius.db.powerBarDefaultColor then
        local color = Gladius.db.powerBarColor
        self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a)
    else
        local powerType = UnitPowerType(unit) or self:GetUnitPowerTypeFallback(unit)
        local color = self:GetBarColor(powerType)
        if color then
            self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b)
        end
    end
    self.frame[unit]:SetValue(1)
	if self.frame[unit].specClassText then
		self.frame[unit].specClassText:SetText("")
	end
    -- hide
    self.frame[unit]:SetAlpha(0)
end


function PowerBar:Test(unit)
	local powerType = Gladius.testing[unit].powerType
	local maxPower = Gladius.testing[unit].maxPower
	local power = Gladius.testing[unit].power
	self:UpdatePower(unit, power, maxPower, powerType)
end

function PowerBar:GetOptions()
	return {
		general = {
			type = "group",
			name = L["General"],
			order = 1,
			args = {
				bar = {
				type = "group",
				name = L["Bar"],
				desc = L["Bar settings"],
				inline = true,
				order = 1,
					args = {
						powerBarDefaultColor = {
							type = "toggle",
							name = L["Power Bar Default Color"],
							desc = L["Toggle power bar default color"],
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							order = 5,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							hidden = function()
								return not Gladius.db.advancedOptions
							end,
							order = 7,
						},
						powerBarColor = {
							type = "color",
							name = L["Power Bar Color"],
							desc = L["Color of the power bar"],
							hasAlpha = true,
							get = function(info)
								return Gladius:GetColorOption(info)
							end,
							set = function(info, r, g, b, a)
								return Gladius:SetColorOption(info, r, g, b, a)
							end,
							disabled = function()
								return Gladius.dbi.profile.powerBarDefaultColor or not Gladius.dbi.profile.modules[self.name]
							end,
							order = 10,
						},
						powerBarBackgroundColor = {
							type = "color",
							name = L["Power Bar Background Color"],
							desc = L["Color of the power bar background"],
							hasAlpha = true,
							get = function(info)
								return Gladius:GetColorOption(info)
							end,
							set = function(info, r, g, b, a)
								return Gladius:SetColorOption(info, r, g, b, a)
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
						powerBarInverse = {
							type = "toggle",
							name = L["Power Bar Inverse"],
							desc = L["Inverse the power bar"],
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							hidden = function()
								return not Gladius.db.advancedOptions
							end,
							order = 20,
						},
						powerBarTexture = {
							type = "select",
							name = L["Power Bar Texture"],
							desc = L["Texture of the power bar"],
							dialogControl = "LSM30_Statusbar",
							values = AceGUIWidgetLSMlists.statusbar,
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							order = 25,
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
						powerBarAdjustWidth = {
							type = "toggle",
							name = L["Power Bar Adjust Width"],
							desc = L["Adjust power bar width to the frame width"],
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							order = 5,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 13,
						},
						powerBarWidth = {
							type = "range",
							name = L["Power Bar Width"],
							desc = L["Width of the power bar"],
							min = 10, max = 500, step = 1,
							disabled = function()
								return Gladius.dbi.profile.powerBarAdjustWidth or not Gladius.dbi.profile.modules[self.name]
							end,
							order = 15,
						},
						powerBarHeight = {
							type = "range",
							name = L["Power Bar Height"],
							desc = L["Height of the power bar"],
							min = 10, max = 200, step = 1,
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							order = 20,
						},
					},
				},
				position = {
					type = "group",
					name = L["Position"],
					desc = L["Position settings"],
					inline = true,
					hidden = function()
						return not Gladius.db.advancedOptions
					end,
					order = 3,
					args = {
						powerBarAttachTo = {
							type = "select",
							name = L["Power Bar Attach To"],
							desc = L["Attach power bar to the given frame"],
							values = function()
								return Gladius:GetModules(self.name)
							end,
							set = function(info, value)
								local key = info.arg or info[#info]
								if strfind(Gladius.db.powerBarRelativePoint, "BOTTOM") then
									self.isBar = true
								else
									self.isBar = false
								end
								Gladius.dbi.profile[key] = value
								Gladius:UpdateFrame()
							end,
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							width = "double",
							order = 5,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 7,
						},
						powerBarAnchor = {
							type = "select",
							name = L["Power Bar Anchor"],
							desc = L["Anchor of the power bar"],
							values = function()
								return Gladius:GetPositions()
							end,
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							order = 10,
						},
						powerBarRelativePoint = {
							type = "select",
							name = L["Power Bar Relative Point"],
							desc = L["Relative point of the power bar"],
							values = function()
								return Gladius:GetPositions()
							end,
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							order = 15,
						},
						sep2 = {
							type = "description",
							name = "",
							width = "full",
							order = 17,
						},
						powerBarOffsetX = {
							type = "range",
							name = L["Power Bar Offset X"],
							desc = L["X offset of the power bar"],
							min = - 100, max = 100, step = 1,
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							order = 20,
						},
						powerBarOffsetY = {
							type = "range",
							name = L["Power Bar Offset Y"],
							desc = L["X offset of the power bar"],
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							min = - 100, max = 100, step = 1,
							order = 25,
						},
					},
				},
			},
		},
		powerDefaultColors = {
			type = "group",
			name = L["Power colors"],
			hidden = function()
				return not Gladius.db.advancedOptions
			end,
			order = 4,
			args = {
				powerBarUseDefaultColorMana = {
					type = "toggle",
					name = L["Default Power Mana Color"],
					desc = L["Toggle default power mana color"],
					disabled = function()
						return not Gladius.dbi.profile.modules[self.name]
					end,
					order = 0,
				},
				powerBarColorMana = {
					type = "color",
					name = L["Power Mana Color"],
					get = function(info)
						return Gladius:GetColorOption(info)
					end,
					set = function(info, r, g, b, a)
						return Gladius:SetColorOption(info, r, g, b, 1)
					end,
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
				powerBarUseDefaultColorRage = {
					type = "toggle",
					name = L["Default Power Rage Color"],
					desc = L["Toggle default power rage color"],
					disabled = function()
						return not Gladius.dbi.profile.modules[self.name]
					end,
					order = 10,
				},
				powerBarColorRage = {
					type = "color",
					name = L["Power Rage Color"],
					get = function(info)
						return Gladius:GetColorOption(info)
					end,
					set = function(info, r, g, b, a)
						return Gladius:SetColorOption(info, r, g, b, 1)
					end,
					disabled = function()
						return not Gladius.dbi.profile.modules[self.name]
					end,
					order = 15,
				},
				sep2 = {
					type = "description",
					name = "",
					width = "full",
					order = 17,
				},
				powerBarUseDefaultColorFocus = {
					type = "toggle",
					name = L["Default Power Focus Color"],
					desc = L["Toggle default power focus color"],
					disabled = function()
						return not Gladius.dbi.profile.modules[self.name]
					end,
					order = 20,
				},
				powerBarColorFocus = {
					type = "color",
					name = L["Power Focus Color"],
					get = function(info)
						return Gladius:GetColorOption(info)
					end,
					set = function(info, r, g, b, a)
						return Gladius:SetColorOption(info, r, g, b, 1)
					end,
					disabled = function()
						return not Gladius.dbi.profile.modules[self.name]
					end,
					order = 25,
				},
				sep3 = {
					type = "description",
					name = "",
					width = "full",
					order = 27,
				},
				powerBarUseDefaultColorEnergy = {
					type = "toggle",
					name = L["Default Power Energy Color"],
					desc = L["Toggle default power energy color"],
					disabled = function()
						return not Gladius.dbi.profile.modules[self.name]
					end,
					order = 30,
				},
				powerBarColorEnergy = {
					type = "color",
					name = L["Power Energy Color"],
					get = function(info)
						return Gladius:GetColorOption(info)
					end,
					set = function(info, r, g, b, a)
						return Gladius:SetColorOption(info, r, g, b, 1)
					end,
					disabled = function()
						return not Gladius.dbi.profile.modules[self.name]
					end,
					order = 35,
				},
				sep4 = {
					type = "description",
					name = "",
					width = "full",
					order = 37,
				},
				powerBarUseDefaultColorRunicPower = {
					type = "toggle",
					name = L["Default Power Runic Power Color"],
					desc = L["Toggle default power runic power color"],
					disabled = function()
						return not Gladius.dbi.profile.modules[self.name]
					end,
					order = 40,
				},
				powerBarColorRunicPower = {
					type = "color",
					name = L["Power Runic Power Color"],
					get = function(info)
						return Gladius:GetColorOption(info)
					end,
					set = function(info, r, g, b, a)
						return Gladius:SetColorOption(info, r, g, b, 1)
					end,
					disabled = function()
						return not Gladius.dbi.profile.modules[self.name]
					end,
					order = 45,
				},
			},
		},
	}
end
