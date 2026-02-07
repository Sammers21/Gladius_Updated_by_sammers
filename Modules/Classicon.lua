local Gladius = _G.Gladius
if not Gladius then
	DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "Class Icon"))
end
local L = Gladius.L
local LSM

-- Global Functions
local _G = _G
local pairs = pairs
local select = select
local strfind = string.find
local tonumber = tonumber
local tostring = tostring
local unpack = unpack

local CreateFrame = CreateFrame
local GetSpecializationInfoByID = GetSpecializationInfoByID
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local UnitAura = UnitAura
local UnitClass = UnitClass

local CLASS_BUTTONS = CLASS_ICON_TCOORDS

-- Safe GetSpellInfo wrapper that returns nil for removed spells
-- This prevents errors when building the aura list with old spell IDs
local SafeGetSpellInfo = function(spellID)
	if not spellID then return nil end
	-- Try C_Spell.GetSpellInfo first (12.0+)
	if C_Spell and C_Spell.GetSpellInfo then
		local spellInfo = C_Spell.GetSpellInfo(spellID)
		if spellInfo then return spellInfo.name end
	end
	-- Fallback to global GetSpellInfo if available
	if GetSpellInfo then
		local name = GetSpellInfo(spellID)
		if name then return name end
	end
	return nil
end

local function GetDefaultAuraList()
	local auraTable = {
		-- Higher Number is More Priority
		-- Priority List by P0rkz
		-- Unpurgable long lasting buffs
		-- Mobility Auras (0)
		[SafeGetSpellInfo(108843) or "Blazing Speed"]	= 0,	-- Blazing Speed
		[SafeGetSpellInfo(65081) or "Body and Soul"]	= 0,	-- Body and Soul
		[SafeGetSpellInfo(108212) or "Burst of Speed"]	= 0,	-- Burst of Speed
		[SafeGetSpellInfo(68992) or "Darkflight"]	= 0,	-- Darkflight
		[SafeGetSpellInfo(1850) or "Dash"]	= 0,	-- Dash
		[SafeGetSpellInfo(137452) or "Displacer Beast"]	= 0,	-- Displacer Beast
		[SafeGetSpellInfo(114239) or "Phantasm"]	= 0,	-- Phantasm
		[SafeGetSpellInfo(118922) or "Posthaste"]	= 0,	-- Posthaste
		[SafeGetSpellInfo(85499) or "Speed of Light"]	= 0,	-- Speed of Light
		[SafeGetSpellInfo(2983) or "Sprint"]	= 0,	-- Sprint
		[SafeGetSpellInfo(06898) or "Stampeding Roar"]	= 0,	-- Stampeding Roar
		[SafeGetSpellInfo(116841) or "Tiger's Lust"]	= 0, 	-- Tiger's Lust
		[SafeGetSpellInfo(193357) or "Ruthless Precision"]  = 0,    -- Ruthless Precision (Added by Bicmex)
		[SafeGetSpellInfo(193359) or "True Bearing"]  = 0,    -- True Bearing (Added by Bicmex)
		[SafeGetSpellInfo(188501) or "Spectral Sight"]  = 0,    -- Spectral Sight (Added by Bicmex)
		-- Movement Reduction Auras (1)
		[SafeGetSpellInfo(5116) or "Concussive Shot"]	= 1,	-- Concussive Shot
		[SafeGetSpellInfo(120) or "Cone of Cold"]		= 1,	-- Cone of Cold
		[SafeGetSpellInfo(13809) or "Frost Trap"]	= 1,	-- Frost Trap
		[SafeGetSpellInfo(356723) or "Scorpid Venom"]  = 1,    -- Scorpid Venom (Added by Bicmex)
		-- Purgable Buffs (2)
		--[SafeGetSpellInfo(16188)]	= 2,	-- Ancestral Swiftness
--		[SafeGetSpellInfo(31842)]	= 2,	-- Divine Favor
		--[SafeGetSpellInfo(6346)]	= 2,	-- Fear Ward
		[SafeGetSpellInfo(112965) or "Fingers of Frost"]	= 2,	-- Fingers of Frost
		[SafeGetSpellInfo(1044) or "Hand of Freedom"]	= 2,	-- Hand of Freedom
		[SafeGetSpellInfo(1022) or "Hand of Protection"]	= 2,	-- Hand of Protection
		[SafeGetSpellInfo(3411) or "Intervene"]	= 2,	-- Intervene
		--[SafeGetSpellInfo(114039)]	= 2,	-- Hand of Purity
		[SafeGetSpellInfo(6940) or "Hand of Sacrifice"]	= 2,	-- Hand of Sacrifice
		[SafeGetSpellInfo(210256) or "Blessing of Sacrifice"]	= 2,	-- Blessing of Sacrifice
		[SafeGetSpellInfo(235450) or "Prismatic Barrier"]	= 2,	-- Prismatic Barrier
		[SafeGetSpellInfo(53271) or "Master's Call"]	= 2,	-- Master's Call
		[SafeGetSpellInfo(132158) or "Nature's Swiftness"]	= 2,	-- Nature's Swiftness
		--[SafeGetSpellInfo(12043)]	= 2,	-- Presence of Mind
		[SafeGetSpellInfo(48108) or "Pyroblast!"]	= 2,	-- Pyroblast!
		-- Defensive - Damage Redution Auras (3)
	--	[SafeGetSpellInfo(108978)]	= 3,	-- Alter Time
		[SafeGetSpellInfo(277187) or "Emblem"]	= 3,	-- Emblem
		[SafeGetSpellInfo(108271) or "Astral Shift"]	= 3,	-- Astral Shift
		[SafeGetSpellInfo(22812) or "Barkskin"]	= 3,	-- Barkskin
		[SafeGetSpellInfo(18499) or "Berserker Rage"]	= 3,	-- Berserker Rage
		--[SafeGetSpellInfo(111397)]	= 3,	-- Blood Horror
		[SafeGetSpellInfo(74001) or "Combat Readiness"]	= 3,	-- Combat Readiness
		[SafeGetSpellInfo(31224) or "Cloak of Shadows"]	= 3,	-- Cloak of Shadows
		[SafeGetSpellInfo(108359) or "Dark Regeneration"]	= 3,	-- Dark Regeneration
		[SafeGetSpellInfo(118038) or "Die by the Sword"]	= 3,	-- Die by the Sword
		[SafeGetSpellInfo(498) or "Divine Protection"]		= 3,	-- Divine Protection
		[SafeGetSpellInfo(5277) or "Evasion"]	= 3,	-- Evasion
		[SafeGetSpellInfo(47788) or "Guardian Spirit"]	= 3,	-- Guardian Spirit
		[SafeGetSpellInfo(48792) or "Icebound Fortitude"]	= 3,	-- Icebound Fortitude
		[SafeGetSpellInfo(66) or "Invisibility"]		= 3,	-- Invisibility
		[SafeGetSpellInfo(102342) or "Ironbark"]	= 3,	-- Ironbark
		[SafeGetSpellInfo(12975) or "Last Stand"]	= 3,	-- Last Stand
		--[SafeGetSpellInfo(49039)]	= 3,	-- Lichborne
		[SafeGetSpellInfo(116849) or "Life Cocoon"]	= 3,	-- Life Cocoon
		--[SafeGetSpellInfo(114028)]	= 3,	-- Mass Spell Reflection
		--[SafeGetSpellInfo(30884)]	= 3,	-- Nature's Guardian
		[SafeGetSpellInfo(124974) or "Nature's Vigil"]	= 3,	-- Nature's Vigil
		--[SafeGetSpellInfo(137562)]	= 3,	-- Nimble Brew
		[SafeGetSpellInfo(33206) or "Pain Suppression"]	= 3,	-- Pain Suppression
		[SafeGetSpellInfo(53480) or "Roar of Sacrifice"]	= 3,	-- Roar of Sacrifice
		--[SafeGetSpellInfo(30823)]	= 3,	-- Shamanistic Rage
		[SafeGetSpellInfo(871) or "Shield Wall"]		= 3,	-- Shield Wall
		[SafeGetSpellInfo(112833) or "Spectral Guise"]	= 3,	-- Spectral Guise
		[SafeGetSpellInfo(23920) or "Spell Reflection"]	= 3,	-- Spell Reflection
		[SafeGetSpellInfo(122470) or "Touch of Karma"]	= 3,	-- Touch of Karma
		[SafeGetSpellInfo(61336) or "Survival Instincts"]	= 3,	-- Survival Instincts
		[SafeGetSpellInfo(212800) or "Blur"]  = 3,    -- Blur (Added by Bicmex)
		[SafeGetSpellInfo(209426) or "Darkness"]  = 3,    -- Darkness (Added by Bicmex)
		[SafeGetSpellInfo(45182) or "Cheated Death"]   = 3,    -- Cheat Death (Added by Bicmex)
		[SafeGetSpellInfo(248519) or "Interlope"]  = 3,    -- Interlope (Added by Bicmex)
		[SafeGetSpellInfo(370960) or "Emerald Communion"]  = 3,    -- Emerald Communion (Added by Bicmex)
		[SafeGetSpellInfo(357170) or "Time Dilation"]  = 3,    -- Time Dilation (Added by Bicmex)
		[SafeGetSpellInfo(374348) or "Renewing Blaze"]  = 3,    -- Renewing Blaze (Added by Bicmex)
		[SafeGetSpellInfo(363916) or "Obsidian Scales"]  = 3,    -- Obsidian Scales (Added by Bicmex)
		[SafeGetSpellInfo(197721) or "Flourish"]  = 3,    -- Flourish (Added by Bicmex)
		[SafeGetSpellInfo(61336) or "Survival Instincts"]   = 3,    -- Survival Instincts (Added by Bicmex)
		[SafeGetSpellInfo(108978) or "Alter Time"]	= 3,	-- Alter Time (Added by Bicmex)
		[SafeGetSpellInfo(198111) or "Temporal Shield"]  = 3,    -- Temporal Shield (Added by Bicmex)
		[SafeGetSpellInfo(359816) or "Dream Flight"]  = 3, -- Dream Flight (Added by Bicmex)
	
		-- Offensive - Melee Auras (4)
		[SafeGetSpellInfo(152151) or "Shadow Reflection"]	= 4,	-- Shadow Reflection
		[SafeGetSpellInfo(107574) or "Avatar"]	= 4,	-- Avatar
		--[SafeGetSpellInfo(106952)]	= 4,	-- Berserk
		--[SafeGetSpellInfo(12292)]	= 4,	-- Bloodbath
		[SafeGetSpellInfo(51271) or "Pillar of Frost"]	= 4,	-- Pillar of Frost
		[SafeGetSpellInfo(1719) or "Recklessness"]	= 4,	-- Recklessness
		[SafeGetSpellInfo(185422) or "Shadow Dance"]	= 7,	-- Shadow Dance
		[SafeGetSpellInfo(375087) or "Dragonrage"]  = 4,    -- Dragonrage (Added by Bicmex)
		[SafeGetSpellInfo(360952) or "Coordinated Assault"]  = 4,    -- Coordinated Assault (Added by Bicmex)
		[SafeGetSpellInfo(260402) or "Double Tap"]  = 4,    -- Double Tap (Added by Bicmex)
		-- Roots (5)
		[SafeGetSpellInfo(91807) or "Shambling Rush"]	= 5,	-- Shambling Rush (Ghoul)
		["96294"]				= 5,	-- Chains of Ice (Chilblains)
		[SafeGetSpellInfo(61685) or "Charge"]	= 5,	-- Charge (Various)
		[SafeGetSpellInfo(116706) or "Disable"]	= 5,	-- Disable
		[SafeGetSpellInfo(454787) or "Ice Prison"]	= 5,	-- Ice Prison
		--[SafeGetSpellInfo(87194)]	= 5,	-- Mind Blast (Glyphed)
		[SafeGetSpellInfo(114404) or "Void Tendrils"]	= 5,	-- Void Tendrils
		[SafeGetSpellInfo(64695) or "Earthgrab"]	= 5,	-- Earthgrab
		[SafeGetSpellInfo(64803) or "Entrapment"]	= 5,	-- Entrapment
		--[SafeGetSpellInfo(63685)]	= 5,	-- Freeze (Frozen Power)
		--[SafeGetSpellInfo(111340)]	= 5,	-- Ice Ward
	--	[SafeGetSpellInfo(107566)]	= 5,	-- Staggering Shout
		[SafeGetSpellInfo(339) or "Entangling Roots"]		= 5,	-- Entangling Roots
		[SafeGetSpellInfo(235963) or "Entangling Roots"]  = 5,    -- physical roots
		--[SafeGetSpellInfo(113770)]	= 5,	-- Entangling Roots (Force of Nature)
		[SafeGetSpellInfo(33395) or "Freeze"]	= 5,	-- Freeze (Water Elemental)
		[SafeGetSpellInfo(122) or "Frost Nova"]		= 5,	-- Frost Nova
		--[SafeGetSpellInfo(102051)]	= 5,	-- Frostjaw
		[SafeGetSpellInfo(102359) or "Mass Entanglement"]	= 5,	-- Mass Entanglement
		[SafeGetSpellInfo(136634) or "Narrow Escape"]	= 5,	-- Narrow Escape
		[SafeGetSpellInfo(105771) or "Warbringer"]	= 5,	-- Warbringer
		[SafeGetSpellInfo(393456) or "Entrapment"]  = 5,    -- Entrapment (Added by Bicmex)
		[SafeGetSpellInfo(190925) or "Harpoon"]  = 5,    -- Harpoon (Added by Bicmex
		["162480"]              = 5,    -- Steel Trap (Added by Bicmex)
		[SafeGetSpellInfo(358385) or "Landslide"]  = 5,    -- Landslide (Added by Bicmex)
		[SafeGetSpellInfo(114404) or "Void Tendril's Grasp"]  = 5,    -- Void Tendril's Grasp (Added by Bicmex)
		[SafeGetSpellInfo(451517) or "Catch Out"]  = 5,    -- Catch Out (Added by Bicmex)

		-- Offensive - Ranged / Spell Auras (6)
		[SafeGetSpellInfo(266779) or "Coordinated Assault"]	= 6,	-- Coordinated Assault
		[SafeGetSpellInfo(279642) or "Lively Spirit"]	= 6,	-- Lively Spirit
		[SafeGetSpellInfo(12042) or "Arcane Power"]	= 6,	-- Arcane Power
		[SafeGetSpellInfo(190319) or "Combustion"]	= 6,	-- Combustion
		[SafeGetSpellInfo(114049) or "Ascendance"]	= 6,	-- SHAMAN BIG SPELL
		[SafeGetSpellInfo(31884) or "Avenging Wrath"]	= 6,	-- Avenging Wrath
		--[SafeGetSpellInfo(113858)]	= 6,	-- Dark Soul: Instability
		--[SafeGetSpellInfo(113861)]	= 6,	-- Dark Soul: Knowledge
		--[SafeGetSpellInfo(113860)]	= 6,	-- Dark Soul: Misery
		[SafeGetSpellInfo(16166) or "Elemental Mastery"]	= 6,	-- Elemental Mastery
		[SafeGetSpellInfo(12472) or "Icy Veins"]	= 6,	-- Icy Veins
		[SafeGetSpellInfo(198144) or "Ice Form"]	= 6,	-- Ice Form
		[SafeGetSpellInfo(194223) or "Celestial Alignment"]	= 6,	-- Incarnation: Celestial ALignment
		[SafeGetSpellInfo(33891) or "Incarnation: Tree of Life"]	= 6,	-- Incarnation: Tree of Life
		[SafeGetSpellInfo(102560) or "Incarnation: Chosen of Elune"]	= 6,	-- Incarnation: Chosen of Elune
		[SafeGetSpellInfo(102543) or "Incarnation: King of the Jungle"]	= 6,	-- Incarnation: King of the Jungle
		[SafeGetSpellInfo(102558) or "Incarnation: Son of Ursoc"]	= 6,	-- Incarnation: Son of Ursoc
		[SafeGetSpellInfo(10060) or "Power Infusion"]	= 6,	-- Power Infusion
		[SafeGetSpellInfo(315186) or "Grand Delusion"]	= 6,	-- Grand Delusion
	--	[SafeGetSpellInfo(3045)]	= 6,	-- Rapid Fire
		--[SafeGetSpellInfo(48505)]	= 6,	-- Starfall
		-- Silence and Spell Immunities Auras (7)
		[SafeGetSpellInfo(31821) or "Devotion Aura"]	= 7,	-- Devotion Aura
		--[SafeGetSpellInfo(115723)]	= 7,	-- Glyph of Ice Block
		[SafeGetSpellInfo(8178) or "Grounding Totem"]	= 7,	-- Grounding Totem Effect
		[SafeGetSpellInfo(131558) or "Spiritwalker's Aegis"]	= 7,	-- Spiritwalker's Aegis
		[SafeGetSpellInfo(104773) or "Unending Resolve"]	= 7,	-- Unending Resolve
		[SafeGetSpellInfo(124488) or "Zen Focus"]	= 7,	-- Zen Focus
		--[SafeGetSpellInfo(159630)]  = 7,    -- Shadow Magic
		[SafeGetSpellInfo(108416) or "Dark Pact"]  = 7,    -- Dark Pact (Added by Bicmex)
		[SafeGetSpellInfo(202748) or "Survival Tactics"]  = 7,    -- Survival Tactics (Added by Bicmex)
		[SafeGetSpellInfo(23920) or "Spell Reflection"]   = 7,    -- Spell Reflection (Added by Bicmex)
		-- Silence and Disarm Auras (8)
		[SafeGetSpellInfo(207777) or "Dismantle"] = 8, -- Dismantle (Added by Bicmex)
		[SafeGetSpellInfo(233759) or "Grapple Weapon"] = 8, -- Grapple Weapon (Added by Bicmex)
		[SafeGetSpellInfo(236077) or "Disarm"] = 8, -- Disarm (Added by Bicmex)
		[SafeGetSpellInfo(209749) or "Faerie Swarm"] = 8, -- Faerie Swarm (Added by Bicmex)
		[SafeGetSpellInfo(407028) or "Sticky Tar Bomb"] = 8, -- Sticky Tar Bomb (Added by Bicmex)
		[SafeGetSpellInfo(286349) or "Maledict"] = 8, -- Maledict
		[SafeGetSpellInfo(1330) or "Garrote"]	= 8,	-- Garrote (Silence)
		[SafeGetSpellInfo(15487) or "Silence"]	= 8,	-- Silence
		[SafeGetSpellInfo(47476) or "Strangulate"]	= 8,	-- Strangulate
		[SafeGetSpellInfo(31935) or "Avenger's Shield"]	= 8,	-- Avenger's Shield
		[SafeGetSpellInfo(356727) or "Spider Venom"]  = 8,    -- Spider Venom (Added by Bicmex)
		[SafeGetSpellInfo(207684) or "Sigil of Misery"]  = 8,    -- Sigil of Misery (Added by Bicmex)
		[SafeGetSpellInfo(204490) or "Sigil of Silence"]  = 8,    -- Sigil of Silence (Added by Bicmex)
		-- Disorients & Stuns Auras (9)
		[SafeGetSpellInfo(389831) or "Snowdrift"]  = 9,    -- Snowdrift (Added by Bicmex)
		[SafeGetSpellInfo(108194) or "Asphyxiate"]	= 9,	-- Asphyxiate
		[SafeGetSpellInfo(91800) or "Gnaw"]	= 9,	-- Gnaw (Ghoul)
		[SafeGetSpellInfo(91797) or "Monstrous Blow"]	= 9,	-- Monstrous Blow (Dark Transformation Ghoul)
		[SafeGetSpellInfo(89766) or "Axe Toss"]	= 9,	-- Axe Toss (Felguard)
		[SafeGetSpellInfo(117526) or "Binding Shot"]	= 9,	-- Binding Shot
		[SafeGetSpellInfo(224729) or "Bursting Shot"]	= 9,	-- Bursting Shot
		[SafeGetSpellInfo(213691) or "Scatter Shot"]	= 9,	-- Scatter Shot
		[SafeGetSpellInfo(24394) or "Intimidation"]	= 9,	-- Intimidation
		[SafeGetSpellInfo(105421) or "Blinding Light"]	= 9,	-- Blinding Light
		[SafeGetSpellInfo(207167) or "Blinding Sleet"]  = 9,    -- Blinding Sleet
		--[SafeGetSpellInfo(7922)]	= 9,	-- Charge Stun
		--[SafeGetSpellInfo(119392)]	= 9,	-- Charging Ox Wave
		[SafeGetSpellInfo(377048) or "Absolute Zero"]  = 9,    -- Absolute Zero
		[SafeGetSpellInfo(1833) or "Cheap Shot"]	= 9,	-- Cheap Shot
		--[SafeGetSpellInfo(118895)]	= 9,	-- Dragon Roar
		[SafeGetSpellInfo(77505) or "Earthquake"]	= 9,	-- Earthquake
		[SafeGetSpellInfo(120086) or "Fist of Fury"]	= 9,	-- Fist of Fury
		--[SafeGetSpellInfo(44572)]	= 9,	-- Deep Freeze
		[SafeGetSpellInfo(287712) or "Haymaker"] = 9, -- Haymaker
		[SafeGetSpellInfo(99) or "Disorienting Roar"]		= 9,	-- Disorienting Roar
		[SafeGetSpellInfo(31661) or "Dragon's Breath"]	= 9,	-- Dragon's Breath
		--[SafeGetSpellInfo(123393)]	= 9,	-- Breath of Fire (Glyphed)
		--[SafeGetSpellInfo(105593)]	= 9,	-- Fist of Justice
		[SafeGetSpellInfo(47481) or "Gnaw"]	= 9,	-- Gnaw
		[SafeGetSpellInfo(1776) or "Gouge"]	= 9,	-- Gouge
		[SafeGetSpellInfo(853) or "Hammer of Justice"]		= 9,	-- Hammer of Justice
		--[SafeGetSpellInfo(119072)]	= 9,	-- Holy Wrath
		[SafeGetSpellInfo(88625) or "Holy Word: Chastise"]	= 9,	-- Holy Word: Chastise
		[SafeGetSpellInfo(19577) or "Intimidation"]	= 9,	-- Intimidation
		[SafeGetSpellInfo(204437) or "Lightning Lasso"] = 9,
		[SafeGetSpellInfo(408) or "Kidney Shot"]		= 9,	-- Kidney Shot
		[SafeGetSpellInfo(119381) or "Leg Sweep"]	= 9,	-- Leg Sweep
		[SafeGetSpellInfo(458605) or "Leg Sweep"]	= 9,	-- Leg Sweep
		[SafeGetSpellInfo(287254) or "Dead of Winter"]	= 9,	-- Dead of Winter
		[SafeGetSpellInfo(22570) or "Maim"]	= 9,	-- Maim
		[SafeGetSpellInfo(5211) or "Mighty Bash"]	= 9,	-- Mighty Bash
		--[SafeGetSpellInfo(113801)]	= 9,	-- Bash (Treants)
		[SafeGetSpellInfo(118345) or "Pulverize"]	= 9,	-- Pulverize (Primal Earth Elemental)
		--[SafeGetSpellInfo(115001)]	= 9,	-- Remorseless Winter
		[SafeGetSpellInfo(30283) or "Shadowfury"]	= 9,	-- Shadowfury
		[SafeGetSpellInfo(22703) or "Infernal Awakening"]	= 9,	-- Summon Infernal
		[SafeGetSpellInfo(46968) or "Shockwave"]	= 9,	-- Shockwave
		[SafeGetSpellInfo(118905) or "Static Charge"]	= 9,	-- Static Charge (Capacitor Totem Stun)
		[SafeGetSpellInfo(132169) or "Storm Bolt"]	= 9,	-- Storm Bolt
		[SafeGetSpellInfo(20549) or "War Stomp"]	= 9,	-- War Stomp
		[SafeGetSpellInfo(211881) or "Fel Eruption"] = 9, -- fel eruption
		[SafeGetSpellInfo(16979) or "Wild Charge"]	= 9,	-- Wild Charge
		[SafeGetSpellInfo(117526) or "Binding Shot"]  = 9,    -- Binding Shot
		["163505"]              = 9,    -- Rake
		[SafeGetSpellInfo(179057) or "Chaos Nova"]  = 9,    -- Chaos Nova (Added by Bicmex)
		["372245"]              = 9,    -- Deep Breath (Stun, Added by Bicmex)
		-- Crowd Controls Auras (10)
		[SafeGetSpellInfo(710) or "Banish"]		= 10,	-- Banish
		[SafeGetSpellInfo(2094) or "Blind"]	= 10,	-- Blind
		--[SafeGetSpellInfo(137143)]	= 10,	-- Blood Horror
		[SafeGetSpellInfo(33786) or "Cyclone"]	= 10,	-- Cyclone
		[SafeGetSpellInfo(605) or "Dominate Mind"]	= 10,	-- Dominate Mind
		[SafeGetSpellInfo(118699) or "Fear"]	= 10,	-- Fear
		[SafeGetSpellInfo(1513) or "Scare Beast"]    = 10,   -- Scare Beast
		[SafeGetSpellInfo(3355) or "Freezing Trap"]	= 10,	-- Freezing Trap
		[SafeGetSpellInfo(51514) or "Hex"]	= 10,	-- Hex
		[SafeGetSpellInfo(5484) or "Howl of Terror"]	= 10,	-- Howl of Terror
		[SafeGetSpellInfo(5246) or "Intimidating Shout"]	= 10,	-- Intimidating Shout
		[SafeGetSpellInfo(316593) or "Intimidating Shout"]  = 10,   -- Intimidating Shout (Talent)
		[SafeGetSpellInfo(115268) or "Mesmerize"]	= 10,	-- Mesmerize (Shivarra)
		[SafeGetSpellInfo(6789) or "Mortal Coil"]	= 10,	-- Mortal Coil
		[SafeGetSpellInfo(115078) or "Paralysis"]	= 10,	-- Paralysis
		[SafeGetSpellInfo(118) or "Polymorph"]		= 10,	-- Polymorph
		[SafeGetSpellInfo(383121) or "Mass Polymorph"]  = 10,   -- Mass Sheep
		[SafeGetSpellInfo(221527) or "Imprison"]  = 10,   -- imprison
		[SafeGetSpellInfo(217832) or "Imprison"]  = 10,   -- imprison2
		[SafeGetSpellInfo(236026) or "Maim"]  = 10,   -- maim
		[SafeGetSpellInfo(255723) or "Bull Rush"]  = 10,   -- Bull Rush
		[SafeGetSpellInfo(8122) or "Psychic Scream"]	= 10,	-- Psychic Scream
		[SafeGetSpellInfo(64044) or "Psychic Horror"]	= 10,	-- Psychic Horror
		[SafeGetSpellInfo(20066) or "Repentance"]	= 10,	-- Repentance
		[SafeGetSpellInfo(82691) or "Ring of Frost"]	= 10,	-- Ring of Frost
		[SafeGetSpellInfo(6770) or "Sap"]	= 10,	-- Sap
		[SafeGetSpellInfo(107079) or "Quaking Palm"]	= 10,	-- Quaking Palm
		[SafeGetSpellInfo(6358) or "Seduction"]	= 10,	-- Seduction (Succubus)
		[SafeGetSpellInfo(9484) or "Shackle Undead"]	= 10,	-- Shackle Undead
		--[SafeGetSpellInfo(10326)]	= 10,	-- Turn Evil
		[SafeGetSpellInfo(19386) or "Wyvern Sting"]	= 10,	-- Wyvern Sting
		[SafeGetSpellInfo(360806) or "Sleep Walk"]  = 10,   -- Sleep Walk
		[SafeGetSpellInfo(198909) or "Song of Chi-Ji"]  = 10,   -- Song of Chi-Ji
		[SafeGetSpellInfo(198898) or "Song of Chi-Ji"]  = 10,   -- Song of Chi-Ji
		-- Immunity Auras (11)
		[SafeGetSpellInfo(48707) or "Anti-Magic Shell"]	= 11,	-- Anti-Magic Shell
		[SafeGetSpellInfo(46924) or "Bladestorm"]	= 11,	-- Bladestorm
		[SafeGetSpellInfo(410358) or "Anti-Magic Shell"]  = 11,   -- Anti-Magic Shell
		[SafeGetSpellInfo(210294) or "Divine Favor"] = 6, -- DIVINE FAVOR
		--[SafeGetSpellInfo(110913)]	= 11,	-- Dark Bargain
		[SafeGetSpellInfo(19263) or "Deterrence"]	= 11,	-- Deterrence
		[SafeGetSpellInfo(47585) or "Dispersion"]	= 11,	-- Dispersion
		[SafeGetSpellInfo(642) or "Divine Shield"]		= 11,	-- Divine Shield
		[SafeGetSpellInfo(45438) or "Ice Block"]	= 11,	-- Ice Block
		[SafeGetSpellInfo(362699) or "Gladiator's Resolve"] 	= 11,	-- Gladiator's Resolve
		[SafeGetSpellInfo(186265) or "Aspect of the Turtle"] = 11, -- Aspect of the Turtle (Added by Bicmex)
		[SafeGetSpellInfo(196555) or "Netherwalk"] = 11, -- Netherwalk (Added by Bicmex)
		[SafeGetSpellInfo(362486) or "Keeper of the Grove"] = 11, -- Keeper of the Grove (Added by Bicmex)
		[SafeGetSpellInfo(212610) or "Holy Ward"] = 11, -- Holy Ward (Added by Bicmex)
		[SafeGetSpellInfo(353319) or "Peaceweaver"] = 11, -- Peaceweaver (Added by Bicmex)
		[SafeGetSpellInfo(377360) or "Precognition"] = 11, -- Precognition (Added by Bicmex)
		[SafeGetSpellInfo(378464) or "Nullifying Shroud"] = 11, -- Nullifying Shroud (Added by Bicmex)
		[SafeGetSpellInfo(27827) or "Spirit of Redemption"]  = 11, -- Spirit of Redemption (Added by Bicmex)
		[SafeGetSpellInfo(228050) or "Guardian of the Forgotten Queen"] = 11, -- Prot pala Party Bubble (Added by Bicmex)
		[SafeGetSpellInfo(378441) or "Time Stop"] = 11, -- Time Stop (Added by Bicmex)
		[SafeGetSpellInfo(198952) or "Veil of Darkness"] = 11, -- Veil of FUCKINGN PISS (Added by Bicmex)
		[SafeGetSpellInfo(354489) or "Glimpse"] = 11, -- Glimpse (Added by Bicmex)
		[SafeGetSpellInfo(357210) or "Deep Breath"] = 11, -- Deep Breath (Added by Bicmex)
		[SafeGetSpellInfo(409293) or "Burrow"] = 11, -- Burrow (added by Bicmex)
		[SafeGetSpellInfo(473909) or "Ancient of Lore"] = 11, -- Ancient of Lore (added by Bicmex)
		-- Drink (12)
		[SafeGetSpellInfo(118358) or "Drink"]	= 12,	-- Drink

	}
	return auraTable
end

local ClassIcon = Gladius:NewModule("ClassIcon", false, true, {
	classIconAttachTo = "Frame",
	classIconAnchor = "TOPRIGHT",
	classIconRelativePoint = "TOPLEFT",
	classIconAdjustSize = false,
	classIconSize = 40,
	classIconOffsetX = -1,
	classIconOffsetY = 0,
	classIconFrameLevel = 1,
	classIconGloss = true,
	classIconGlossColor = {r = 1, g = 1, b = 1, a = 0.4},
	classIconImportantAuras = true,
	classIconCrop = false,
	classIconCooldown = false,
	classIconCooldownReverse = false,
	classIconShowSpec = false,
	classIconDetached = false,
	classIconAuras = GetDefaultAuraList(),
})

function ClassIcon:OnEnable()
	-- UNIT_AURA returns secret data for arena units in 12.0, aura overlay disabled
	self.version = 1
	LSM = Gladius.LSM
	if not self.frame then
		self.frame = { }
	end
	Gladius.db.auraVersion = self.version
end

function ClassIcon:OnDisable()
	self:UnregisterAllEvents()
	for unit in pairs(self.frame) do
		self.frame[unit]:SetAlpha(0)
	end
end

function ClassIcon:GetAttachTo()
	return Gladius.db.classIconAttachTo
end

function ClassIcon:IsDetached()
	return Gladius.db.classIconDetached
end

function ClassIcon:GetFrame(unit)
	return self.frame[unit]
end

function ClassIcon:UNIT_AURA(event, unit)
	if not Gladius:IsValidUnit(unit) then
		return
	end

	-- important auras
	self:UpdateAura(unit)
end

function ClassIcon:UpdateColors(unit)
	self.frame[unit].normalTexture:SetVertexColor(Gladius.db.classIconGlossColor.r, Gladius.db.classIconGlossColor.g, Gladius.db.classIconGlossColor.b, Gladius.db.classIconGloss and Gladius.db.classIconGlossColor.a or 0)
end

local blacklisted = {
    [458503] = true,
    [458524] = true,
    [458502] = true,
    [458525] = true,
	[462377] = true,
	[1236938] = true
}

function ClassIcon:UpdateAura(unit)
    if not self.frame then return end
    local unitFrame = self.frame[unit]

    if not unitFrame then
        return
    end

    if not Gladius.db.classIconAuras then
        return
    end

    local aura
    if #canOverWrite > 0 then
        for i=1, #canOverWrite, 1 do
            if canOverWrite[i].unit == unit then
                return
            end
        end
    end
    for _, auraType in pairs({'HELPFUL', 'HARMFUL'}) do
        for i = 1, 40 do
            local name, icon, _, _, duration, expires, _, _, _, spellid = UnitAura(unit, i, auraType)

            if not name then
                break
            end
            local auraList = Gladius.db.classIconAuras
            local priority = auraList[name] or auraList[tostring(spellid)]

            if priority and (not aura or aura.priority < priority)  then
                if not blacklisted[spellid] then
                    aura = {
                        name = name,
                        icon = icon,
                        duration = duration,
                        expires = expires,
                        spellid = spellid,
                        priority = priority
                    }
                end
            end
        end
    end

    if aura and (not unitFrame.aura or (unitFrame.aura.id ~= aura or unitFrame.aura.expires ~= aura.expires)) then
        self:ShowAura(unit, aura)
    elseif not aura then
        self.frame[unit].aura = nil
        self:SetClassIcon(unit)
    end
end

function ClassIcon:ShowAura(unit, aura)
	if not self.frame then return end
	local unitFrame = self.frame[unit]
	unitFrame.aura = aura

	-- display aura
	unitFrame.texture:SetTexture(aura.icon)
	if Gladius.db.classIconCrop then
		unitFrame.texture:SetTexCoord(0.075, 0.925, 0.075, 0.925)
	else
		unitFrame.texture:SetTexCoord(0, 1, 0, 1)
	end

	local start

	if aura.expires then
		local timeLeft = aura.expires > 0 and aura.expires - GetTime() or 0
		start = GetTime() - (aura.duration - timeLeft)
	end

	Gladius:Call(Gladius.modules.Timer, "SetTimer", unitFrame, aura.duration, start)
end

function ClassIcon:SetClassIcon(unit)
	if not self.frame[unit] then
		return
	end
	Gladius:Call(Gladius.modules.Timer, "HideTimer", self.frame[unit])
	-- get unit class
	local class
	local specIcon
	if not Gladius.test then
		local frame = Gladius:GetUnitFrame(unit)
		class = frame.class
		specIcon = frame.specIcon
	else
		class = Gladius.testing[unit].unitClass
		local _, _, _, icon = GetSpecializationInfoByID(Gladius.testing[unit].unitSpecId)
		specIcon = icon
	end
	if Gladius.db.classIconShowSpec then
		if specIcon then
			self.frame[unit].texture:SetTexture(specIcon)
			local left, right, top, bottom = 0, 1, 0, 1
			-- Crop class icon borders
			if Gladius.db.classIconCrop then
				left = left + (right - left) * 0.075
				right = right - (right - left) * 0.075
				top = top + (bottom - top) * 0.075
				bottom = bottom - (bottom - top) * 0.075
			end
			self.frame[unit].texture:SetTexCoord(left, right, top, bottom)
		end
	else
		if class then
			self.frame[unit].texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
			local left, right, top, bottom = unpack(CLASS_BUTTONS[class])
			-- Crop class icon borders
			if Gladius.db.classIconCrop then
				left = left + (right - left) * 0.075
				right = right - (right - left) * 0.075
				top = top + (bottom - top) * 0.075
				bottom = bottom - (bottom - top) * 0.075
			end
			self.frame[unit].texture:SetTexCoord(left, right, top, bottom)
		end
	end
end

function ClassIcon:CreateFrame(unit)
	local button = Gladius.buttons[unit]
	if not button then
		return
	end
	-- create frame
	self.frame[unit] = CreateFrame("CheckButton", "Gladius"..self.name.."Frame"..unit, button, "ActionButtonTemplate")
	self.frame[unit]:EnableMouse(false)
	self.frame[unit]:SetNormalTexture("Interface\\AddOns\\Gladius_Updated_by_sammers\\Images\\Gloss")
	self.frame[unit].texture = _G[self.frame[unit]:GetName().."Icon"]
	self.frame[unit].normalTexture = _G[self.frame[unit]:GetName().."NormalTexture"]
	self.frame[unit].cooldown = _G[self.frame[unit]:GetName().."Cooldown"]
	self.frame[unit].IconMask:Hide()
	-- secure
	local secure = CreateFrame("Button", "Gladius"..self.name.."SecureButton"..unit, button, "SecureActionButtonTemplate")
	secure:RegisterForClicks("AnyUp", "AnyDown")
	self.frame[unit].secure = secure
end

function ClassIcon:Update(unit)
	-- TODO: check why we need this >_<
	self.frame = self.frame or { }

	-- create frame
	if not self.frame[unit] then
		self:CreateFrame(unit)
	end

	local unitFrame = self.frame[unit]

	-- update frame
	unitFrame:ClearAllPoints()
	local parent = Gladius:GetParent(unit, Gladius.db.classIconAttachTo)
	unitFrame:SetPoint(Gladius.db.classIconAnchor, parent, Gladius.db.classIconRelativePoint, Gladius.db.classIconOffsetX, Gladius.db.classIconOffsetY)
	-- frame level
	unitFrame:SetFrameLevel(Gladius.db.classIconFrameLevel)
	if Gladius.db.classIconAdjustSize then
		local height = false
		-- need to rethink that
		--[[for _, module in pairs(Gladius.modules) do
			if module:GetAttachTo() == self.name then
				height = false
			end
		end]]
		if height then
			unitFrame:SetWidth(Gladius.buttons[unit].height)
			unitFrame:SetHeight(Gladius.buttons[unit].height)
		else
			unitFrame:SetWidth(Gladius.buttons[unit].frameHeight)
			unitFrame:SetHeight(Gladius.buttons[unit].frameHeight)
		end
	else
		unitFrame:SetWidth(Gladius.db.classIconSize)
		unitFrame:SetHeight(Gladius.db.classIconSize)
	end

	-- Secure frame
	if self.IsDetached() then
		unitFrame.secure:SetAllPoints(unitFrame)
		unitFrame.secure:SetHeight(unitFrame:GetHeight())
		unitFrame.secure:SetWidth(unitFrame:GetWidth())
		unitFrame.secure:Show()
	else
		unitFrame.secure:Hide()
	end

	unitFrame.texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
	-- set frame mouse-interactable area
	local left, right, top, bottom = Gladius.buttons[unit]:GetHitRectInsets()
	if self:GetAttachTo() == "Frame" and not self:IsDetached() then
		if strfind(Gladius.db.classIconRelativePoint, "LEFT") then
			left = - unitFrame:GetWidth() + Gladius.db.classIconOffsetX
		else
			right = - unitFrame:GetWidth() + - Gladius.db.classIconOffsetX
		end
		-- search for an attached frame
		--[[for _, module in pairs(Gladius.modules) do
			if (module.attachTo and module:GetAttachTo() == self.name and module.frame and module.frame[unit]) then
				local attachedPoint = module.frame[unit]:GetPoint()
				if (strfind(Gladius.db.classIconRelativePoint, "LEFT") and (not attachedPoint or (attachedPoint and strfind(attachedPoint, "RIGHT")))) then
					left = left - module.frame[unit]:GetWidth()
				elseif (strfind(Gladius.db.classIconRelativePoint, "LEFT") and (not attachedPoint or (attachedPoint and strfind(attachedPoint, "LEFT")))) then
					right = right - module.frame[unit]:GetWidth()
				end
			end
		end]]
		-- top / bottom
		if unitFrame:GetHeight() > Gladius.buttons[unit]:GetHeight() then
			bottom = -(unitFrame:GetHeight() - Gladius.buttons[unit]:GetHeight()) + Gladius.db.classIconOffsetY
		end
		Gladius.buttons[unit]:SetHitRectInsets(left, right, 0, 0)
		Gladius.buttons[unit].secure:SetHitRectInsets(left, right, 0, 0)
	end
	-- style action button
	unitFrame.normalTexture:SetHeight(unitFrame:GetHeight() + unitFrame:GetHeight() * 0.4)
	unitFrame.normalTexture:SetWidth(unitFrame:GetWidth() + unitFrame:GetWidth() * 0.4)
	unitFrame.normalTexture:ClearAllPoints()
	unitFrame.normalTexture:SetPoint("CENTER", 0, 0)
	unitFrame:SetNormalTexture("Interface\\AddOns\\Gladius_Updated_by_sammers\\Images\\Gloss")
	unitFrame.texture:ClearAllPoints()
	unitFrame.texture:SetPoint("TOPLEFT", unitFrame, "TOPLEFT")
	unitFrame.texture:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT")
	unitFrame.normalTexture:SetVertexColor(Gladius.db.classIconGlossColor.r, Gladius.db.classIconGlossColor.g, Gladius.db.classIconGlossColor.b, Gladius.db.classIconGloss and Gladius.db.classIconGlossColor.a or 0)
	unitFrame.texture:SetTexCoord(left, right, top, bottom)

	-- cooldown
	unitFrame.cooldown.isDisabled = not Gladius.db.classIconCooldown
	unitFrame.cooldown:SetReverse(Gladius.db.classIconCooldownReverse)
	Gladius:Call(Gladius.modules.Timer, "RegisterTimer", unitFrame, Gladius.db.classIconCooldown)

	-- hide
	unitFrame:SetAlpha(0)
	self.frame[unit] = unitFrame
end

function ClassIcon:Show(unit)
	-- show frame
	self.frame[unit]:SetAlpha(1)
	-- set class icon (UpdateAura disabled - UnitAura returns secret data for arena units in 12.0)
	self:SetClassIcon(unit)
end

function ClassIcon:Reset(unit)
	-- reset frame
	self.frame[unit].aura = nil
	self.frame[unit]:SetScript("OnUpdate", nil)
	-- reset cooldown
	self.frame[unit].cooldown:SetCooldown(0, 0)
	-- reset texture
	self.frame[unit].texture:SetTexture("")
	-- hide
	self.frame[unit]:SetAlpha(0)
end

function ClassIcon:ResetModule()
	Gladius.db.classIconAuras = { }
	Gladius.db.classIconAuras = GetDefaultAuraList()
	local newAura = Gladius.options.args[self.name].args.auraList.args.newAura
	Gladius.options.args[self.name].args.auraList.args = {
		newAura = newAura,
	}
	for aura, priority in pairs(Gladius.db.classIconAuras) do
		if priority then
			local isNum = tonumber(aura) ~= nil
			local name = isNum and GetSpellInfo(aura) or aura
			Gladius.options.args[self.name].args.auraList.args[aura] = self:SetupAura(aura, priority, name)
		end
	end
end

function ClassIcon:Test(unit)
	if not Gladius.db.classIconImportantAuras then
		return
	end
	if unit == "arena1" then
		self:ShowAura(unit, {
			icon = select(3, GetSpellInfo(45438)),
			duration = 10
		})
	elseif unit == "arena2" then
		self:ShowAura(unit, {
			icon = select(3, GetSpellInfo(19263)),
			duration = 5
		})
	end
end

function ClassIcon:GetOptions()
	local options = {
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
						classIconImportantAuras = {
							type = "toggle",
							name = L["Class Icon Important Auras"],
							desc = L["Show important auras instead of the class icon"],
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							order = 5,
						},
						classIconCrop = {
							type = "toggle",
							name = L["Class Icon Crop Borders"],
							desc = L["Toggle if the class icon borders should be cropped or not."],
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							hidden = function()
								return not Gladius.db.advancedOptions
							end,
							order = 6,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 7,
						},
						classIconCooldown = {
							type = "toggle",
							name = L["Class Icon Cooldown Spiral"],
							desc = L["Display the cooldown spiral for important auras"],
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							hidden = function()
								return not Gladius.db.advancedOptions
							end,
							order = 10,
						},
						classIconCooldownReverse = {
							type = "toggle",
							name = L["Class Icon Cooldown Reverse"],
							desc = L["Invert the dark/bright part of the cooldown spiral"],
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							hidden = function()
								return not Gladius.db.advancedOptions
							end,
							order = 15,
						},
						classIconShowSpec = {
							type = "toggle",
							name = L["Class Icon Spec Icon"],
							desc = L["Shows the specialization icon instead of the class icon"],
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							hidden = function()
								return not Gladius.db.advancedOptions
							end,
							order = 16,
						},
						sep2 = {
							type = "description",
							name = "",
							width = "full",
							order = 17,
						},
						classIconGloss = {
							type = "toggle",
							name = L["Class Icon Gloss"],
							desc = L["Toggle gloss on the class icon"],
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							hidden = function()
								return not Gladius.db.advancedOptions
							end,
							order = 20,
						},
						classIconGlossColor = {
							type = "color",
							name = L["Class Icon Gloss Color"],
							desc = L["Color of the class icon gloss"],
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
							order = 25,
						},
						sep3 = {
							type = "description",
							name = "",
							width = "full",
							order = 27,
						},
						classIconFrameLevel = {
							type = "range",
							name = L["Class Icon Frame Level"],
							desc = L["Frame level of the class icon"],
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
							order = 30,
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
						classIconAdjustSize = {
							type = "toggle",
							name = L["Class Icon Adjust Size"],
							desc = L["Adjust class icon size to the frame size"],
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							order = 5,
						},
						classIconSize = {
							type = "range",
							name = L["Class Icon Size"],
							desc = L["Size of the class icon"],
							min = 10,
							max = 100,
							step = 1,
							disabled = function()
								return Gladius.dbi.profile.classIconAdjustSize or not Gladius.dbi.profile.modules[self.name]
							end,
							order = 10,
						},
					},
				},
				position = {
					type = "group",
					name = L["Position"],
					desc = L["Position settings"],
					inline = true,
					order = 3,
					args = {
						classIconAttachTo = {
							type = "select",
							name = L["Class Icon Attach To"],
							desc = L["Attach class icon to given frame"],
							values = function()
								return Gladius:GetModules(self.name)
							end,
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							hidden = function()
								return not Gladius.db.advancedOptions
							end,
							order = 5,
						},
						classIconDetached = {
							type = "toggle",
							name = L["Detached from frame"],
							desc = L["Detach the cast bar from the frame itself"],
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							order = 6,
						},
						classIconPosition = {
							type = "select",
							name = L["Class Icon Position"],
							desc = L["Position of the class icon"],
							values={ ["LEFT"] = L["Left"], ["RIGHT"] = L["Right"] },
							get = function()
								return strfind(Gladius.db.classIconAnchor, "RIGHT") and "LEFT" or "RIGHT"
							end,
							set = function(info, value)
								if (value == "LEFT") then
									Gladius.db.classIconAnchor = "TOPRIGHT"
									Gladius.db.classIconRelativePoint = "TOPLEFT"
								else
									Gladius.db.classIconAnchor = "TOPLEFT"
									Gladius.db.classIconRelativePoint = "TOPRIGHT"
								end
								Gladius:UpdateFrame(info[1])
							end,
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							hidden = function()
								return Gladius.db.advancedOptions
							end,
							order = 7,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 8,
						},
						classIconAnchor = {
							type = "select",
							name = L["Class Icon Anchor"],
							desc = L["Anchor of the class icon"],
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
						classIconRelativePoint = {
							type = "select",
							name = L["Class Icon Relative Point"],
							desc = L["Relative point of the class icon"],
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
						classIconOffsetX = {
							type = "range",
							name = L["Class Icon Offset X"],
							desc = L["X offset of the class icon"],
							min = - 100, max = 100, step = 1,
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name]
							end,
							order = 20,
						},
						classIconOffsetY = {
							type = "range",
							name = L["Class Icon Offset Y"],
							desc = L["Y offset of the class icon"],
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
		auraList = {
			type = "group",
			name = L["Auras"],
			childGroups = "tree",
			order = 3,
			args = {
				newAura = {
					type = "group",
					name = L["New Aura"],
					desc = L["New Aura"],
					inline = true,
					order = 1,
					args = {
						name = {
							type = "input",
							name = L["Name"],
							desc = L["Name of the aura"],
							get = function()
								return self.newAuraName or ""
							end,
							set = function(info, value)
								self.newAuraName = value
							end,
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name] or not Gladius.db.classIconImportantAuras
							end,
							order = 1,
						},
						priority = {
							type = "range",
							name = L["Priority"],
							desc = L["Select what priority the aura should have - higher equals more priority"],
							get = function()
								return self.newAuraPriority or 0
							end,
							set = function(info, value)
								self.newAuraPriority = value
							end,
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name] or not Gladius.db.classIconImportantAuras
							end,
							min = 0,
							max = 20,
							step = 1,
							order = 2,
						},
						add = {
							type = "execute",
							name = L["Add new Aura"],
							func = function(info)
								if not self.newAuraName or self.newAuraName == "" then
									return
								end
								if not self.newAuraPriority then
									self.newAuraPriority = 0
								end
								local isNum = tonumber(self.newAuraName) ~= nil
								local name = isNum and GetSpellInfo(self.newAuraName) or self.newAuraName
								Gladius.options.args[self.name].args.auraList.args[self.newAuraName] = self:SetupAura(self.newAuraName, self.newAuraPriority, name)
								Gladius.db.classIconAuras[self.newAuraName] = self.newAuraPriority
								self.newAuraName = ""
							end,
							disabled = function()
								return not Gladius.dbi.profile.modules[self.name] or not Gladius.db.classIconImportantAuras or not self.newAuraName or self.newAuraName == ""
							end,
							order = 3,
						},
					},
				},
			},
		},
	}
	for aura, priority in pairs(Gladius.db.classIconAuras) do
		if priority then
			local isNum = tonumber(aura) ~= nil
			local name = isNum and GetSpellInfo(aura) or aura
			options.auraList.args[aura] = self:SetupAura(aura, priority, name)
		end
	end
	return options
end

local function setAura(info, value)
	if info[#(info)] == "name" then
		if info[#(info) - 1] == value then
			return
		end
		-- create new aura
		Gladius.db.classIconAuras[value] = Gladius.db.classIconAuras[info[#(info) - 1]]
		-- delete old aura
		Gladius.db.classIconAuras[info[#(info) - 1]] = nil
		local newAura = Gladius.options.args["ClassIcon"].args.auraList.args.newAura
		Gladius.options.args["ClassIcon"].args.auraList.args = {
			newAura = newAura,
		}
		for aura, priority in pairs(Gladius.db.classIconAuras) do
			if priority then
				local isNum = tonumber(aura) ~= nil
				local name = isNum and GetSpellInfo(aura) or aura
				Gladius.options.args["ClassIcon"].args.auraList.args[aura] = ClassIcon:SetupAura(aura, priority, name)
			end
		end
	else
		Gladius.dbi.profile.classIconAuras[info[#(info) - 1]] = value
	end
end

local function getAura(info)
	if info[#(info)] == "name" then
		return info[#(info) - 1]
	else
		return Gladius.dbi.profile.classIconAuras[info[#(info) - 1]]
	end
end

function ClassIcon:SetupAura(aura, priority, name)
	local name = name or aura
	return {
		type = "group",
		name = name,
		desc = name,
		get = getAura,
		set = setAura,
		args = {
			name = {
				type = "input",
				name = L["Name or ID"],
				desc = L["Name or ID of the aura"],
				order = 1,
				disabled = function()
					return not Gladius.dbi.profile.modules[self.name] or not Gladius.db.classIconImportantAuras
				end,
			},
			priority = {
				type = "range",
				name = L["Priority"],
				desc = L["Select what priority the aura should have - higher equals more priority"],
				min = 0,
				max = 20,
				step = 1,
				order = 2,
				disabled = function()
					return not Gladius.dbi.profile.modules[self.name] or not Gladius.db.classIconImportantAuras
				end,
			},
			delete = {
				type = "execute",
				name = L["Delete"],
				func = function(info)
					local defaults = GetDefaultAuraList()
					if defaults[info[#(info) - 1]] then
						Gladius.db.classIconAuras[info[#(info) - 1]] = false
					else
						Gladius.db.classIconAuras[info[#(info) - 1]] = nil
					end
					local newAura = Gladius.options.args[self.name].args.auraList.args.newAura
					Gladius.options.args[self.name].args.auraList.args = {
						newAura = newAura,
					}
					for aura, priority in pairs(Gladius.db.classIconAuras) do
						if priority then
							local isNum = tonumber(aura) ~= nil
							local name = isNum and GetSpellInfo(aura) or aura
							Gladius.options.args[self.name].args.auraList.args[aura] = self:SetupAura(aura, priority, name)
						end
					end
				end,
				disabled = function()
					return not Gladius.dbi.profile.modules[self.name] or not Gladius.db.classIconImportantAuras
				end,
				order = 3,
			},
			reset = {
				type = "execute",
				name = L["Reset Auras"],
				func = function(info)
					self:ResetModule()
				end,
				disabled = function()
					return not Gladius.dbi.profile.modules[self.name] or not Gladius.db.classIconImportantAuras
				end,
				order = 4,
			},
		},
	}
end
