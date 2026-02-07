
--8.0 unitbuff fix
local ub = UnitBuff
local UnitBuff = function(uId, spellName)
	if (type(spellName) == "number") then
		 return ub(uId, spellName)
	end
	for i = 1, 40 do
		local bfaspellName = ub(uId, i)
		if not bfaspellName then return end
		if spellName == bfaspellName then
			return ub(uId, i)
		end
	end
end

--8.0 unitdebuff fix
local udb = UnitDebuff
local UnitDebuff = function(uId, spellName)
	if (type(spellName) == "number") then
		 return udb(uId, spellName)
	end
	for i = 1, 40 do
		local bfaspellName = udb(uId, i)
		if not bfaspellName then return end
		if spellName == bfaspellName then
			return udb(uId, i)
		end
	end
end


local Gladius = _G.Gladius
if not Gladius then
	DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "Interrupts"))
end
local L = Gladius.L
local LSM

local GetSpellTexture = GetSpellTexture
local GetNumArenaOpponents = GetNumArenaOpponents
local UnitGUID = UnitGUID
local UnitChannelInfo = UnitChannelInfo
local IsInInstance = IsInInstance
local GetTime = GetTime
local select = select

local Interrupt = Gladius:NewModule("Interrupts", false, false, {InterruptFrameLevel = 5},{})

function Interrupt:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function Interrupt:OnDisable()
	self:UnregisterAllEvents()
	for unit in pairs(self.frame) do
		self.frame[unit]:SetAlpha(0)
	end
end

function Interrupt:COMBAT_LOG_EVENT_UNFILTERED(event)
		local _,subEvent,_,sourceGUID,sourceName,_,_,destGUID,destName,destFlags,destRaidFlags,spellID,spellName,_,auraType,extraSpellName,_,auraType2 = CombatLogGetCurrentEventInfo()
    local _, instanceType = IsInInstance()
    ---Lockout icons over the gladius frame--
    --Channel--
    if subEvent == "SPELL_CAST_SUCCESS" then
        goFar = false
        for index, value in ipairs (interruptsList) do
            if value == spellID then
                goFar = true
            end
        end
        if goFar then
            for i=1,GetNumArenaOpponents() do
                -- In 12.0, UnitGUID/UnitChannelInfo return secret values for arena units.
                -- pcall to handle comparison/boolean test errors on secrets.
                local ok, match = pcall(function()
                    return destGUID == UnitGUID("arena"..i) and select(7,UnitChannelInfo("arena"..i))==false
                end)
                if ok and match then
                    unit="arena"..i
                    local d = iDurations[spellID]
                    self:UpdateInterrupt("arena"..i, spellID, d)
                end
            end
        end
    end



    --Casted--
    if subEvent == "SPELL_INTERRUPT" then
        goFar = false
        for index, value in ipairs (interruptsList) do
            if value == spellID then
                goFar = true
            end
        end

        if goFar then
            for i=1,GetNumArenaOpponents() do
                -- In 12.0, UnitGUID returns secret values for arena units.
                local ok, match = pcall(function() return destGUID == UnitGUID("arena"..i) end)
                if ok and match then
                    unit="arena"..i
                    local d = iDurations[spellID]
                    self:UpdateInterrupt("arena"..i, spellID, d)
                end
            end
        end
    end
end
function Interrupt:UpdateInterrupt(unit, duration)
    Gladius:Call(Gladius.modules.Timer, "SetTimer", self.frame[unit], duration)
end

function Interrupt:CreateFrame(unit)

end

CreateFrame("Frame"):SetScript("OnUpdate",
function()
        for i=#canOverWrite,1,-1 do
                    if GetTime() - canOverWrite[i].time > 0 then
                               local u = canOverWrite[i].unit
                               table.remove(canOverWrite,i);
                               ClassIcon:UpdateAura(u);
                    end
        end
end)
function Interrupt:UpdateInterrupt(unitt, sp, d)
    ClassIcon = Gladius.modules["ClassIcon"]
    local icon
    if sp then
        icon = GetSpellTexture(sp)
    else
        icon = 135856
    end
    ClassIcon:ShowAura(unitt, {icon = icon, duration=d});
    table.insert(canOverWrite, {unit=unitt, time=GetTime()+d});
end

function Interrupt:Show(unit)

end

function Interrupt:Reset(unit)

end
function Interrupt:GetAttachTo()
    return nil
end

function Interrupt:IsDetached()
    return nil
end

function Interrupt:Test(unit)
	self:UpdateInterrupt("arena1", interruptsList[1], iDurations[interruptsList[1]])
	self:UpdateInterrupt("arena2", interruptsList[6], iDurations[interruptsList[6]])
	self:UpdateInterrupt("arena3", interruptsList[12], iDurations[interruptsList[12]])
end


function Interrupt:GetOptions()
	return {
		general = {
			type = "group",
			name = L["General"],
			order = 1,
			args = {
                sep2 = {
                    type = "description",
                    name = "This module shows interrupt durations over the Arena Enemy Class Icons when they are interrupted.",
                    width = "full",
                    order = 17,
                },
								InterruptFrameLevel = {
									type = "range",
									name = L["Interrupt Frame Level"],
									desc = L["Frame level of the Interrupt"],
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
									order = 46,
								},
							},
        },
    }
end

canOverWrite = {};
interruptsList = {
    6552,   -- [Warrior] Pummel
    96231,  -- [Paladin] Rebuke
    231665, -- [Paladin] Avengers Shield
    147362, -- [Hunter] Countershot
    187707, -- [Hunter] Muzzle
    1766,   -- [Rogue] Kick
    183752, -- [DH] Consume Magic
    47528,  -- [DK] Mind Freeze
    91802,  -- [DK] Shambling Rush
    57994,  -- [Shaman] Wind Shear
    115781, -- [Warlock] Optical Blast
    19647,  -- [Warlock] Spell Lock
    212619, -- [Warlock] Call Felhunter
    132409, -- [Warlock] Spell Lock (Old)
    171138, -- [Warlock] Shadow Lock
    2139,   -- [Mage] Counterspell
    116705, -- [Monk] Spear Hand Strike
    106839, -- [Feral] Skull Bash
	93985,	-- [Feral] Skull Bash
	97547,  -- [Moonkin] Solar Beam
    351338, -- [Evoker] Quell
}
iDurations = {
    [6552] = 3,   -- [Warrior] Pummel
    [96231] = 3,  -- [Paladin] Rebuke
    [231665] = 3, -- [Paladin] Avengers Shield
    [147362] = 3, -- [Hunter] Countershot
    [187707] = 3, -- [Hunter] Muzzle
    [1766] = 3,   -- [Rogue] Kick
    [183752] = 3, -- [DH] Consume Magic
    [47528] = 3,  -- [DK] Mind Freeze
    [91802] = 2,  -- [DK] Shambling Rush
    [57994] = 2,  -- [Shaman] Wind Shear
    [115781] = 5, -- [Warlock] Optical Blast
    [19647] = 5,  -- [Warlock] Spell Lock
    [212619] = 5, -- [Warlock] Call Felhunter
    [132409] = 5, -- [Warlock] Spell Lock
    [171138] = 5, -- [Warlock] Shadow Lock
    [2139] = 5,   -- [Mage] Counterspell
    [116705] = 3, -- [Monk] Spear Hand Strike
    [106839] = 3, -- [Feral] Skull Bash
	[93985] = 3,  -- [Feral] Skull Bash
	[97547] = 4,  -- [Moonkin] Solar Beam
    [351338] = 4, -- [Evoker] Quell
}
