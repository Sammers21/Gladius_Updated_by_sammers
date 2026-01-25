-- Code written by Rhythm

-- 10.0.0
if not CursorCanGoInSlot then
    CursorCanGoInSlot = C_PaperDollInfo.CanCursorCanGoInSlot
end

if C_TradeSkillUI and not C_TradeSkillUI.GetRecipeRepeatCount then
    ---@diagnostic disable-next-line: duplicate-set-field
    C_TradeSkillUI.GetRecipeRepeatCount = function()
		return C_TradeSkillUI.GetRemainingRecasts() + 1
	end
end

-- 10.1.0
if not GetAddOnMetadata then
    GetAddOnMetadata = C_AddOns.GetAddOnMetadata
end

if not GetSpellTexture then
    GetSpellTexture = C_Spell.GetSpellTexture
end

if not GetSpellDescription then
    GetSpellDescription = C_Spell.GetSpellDescription
end

-- 10.1.5
if not GetClassIDFromSpecID then
    GetClassIDFromSpecID = C_SpecializationInfo.GetClassIDFromSpecID
end

-- if not GetTexCoordsForRole then
--     GetTexCoordsForRole = function(role)
-- 		local textureHeight, textureWidth = 256, 256
-- 		local roleHeight, roleWidth = 67, 67

-- 		if ( role == 'GUIDE' ) then
-- 			return GetTexCoordsByGrid(1, 1, textureWidth, textureHeight, roleWidth, roleHeight)
-- 		elseif ( role == 'TANK' ) then
-- 			return GetTexCoordsByGrid(1, 2, textureWidth, textureHeight, roleWidth, roleHeight)
-- 		elseif ( role == 'HEALER' ) then
-- 			return GetTexCoordsByGrid(2, 1, textureWidth, textureHeight, roleWidth, roleHeight)
-- 		elseif ( role == 'DAMAGER' ) then
-- 			return GetTexCoordsByGrid(2, 2, textureWidth, textureHeight, roleWidth, roleHeight)
-- 		else
-- 			error('Unknown role: '..tostring(role))
-- 		end
-- 	end
-- end

-- if not GetBackgroundTexCoordsForRole then
--     GetBackgroundTexCoordsForRole = function(role)
--         local textureHeight, textureWidth = 128, 256
--         local roleHeight, roleWidth = 75, 75

--         if ( role == 'TANK' ) then
--             return GetTexCoordsByGrid(2, 1, textureWidth, textureHeight, roleWidth, roleHeight)
--         elseif ( role == 'HEALER' ) then
--             return GetTexCoordsByGrid(1, 1, textureWidth, textureHeight, roleWidth, roleHeight)
--         elseif ( role == 'DAMAGER' ) then
--             return GetTexCoordsByGrid(3, 1, textureWidth, textureHeight, roleWidth, roleHeight)
--         else
--             error('Role does not have background: '..tostring(role))
--         end
--     end
-- end

-- if not GetTexCoordsForRoleSmallCircle then
--     GetTexCoordsForRoleSmallCircle = function(role)
--         if ( role == 'TANK' ) then
--             return 0, 19/64, 22/64, 41/64
--         elseif ( role == 'HEALER' ) then
--             return 20/64, 39/64, 1/64, 20/64
--         elseif ( role == 'DAMAGER' ) then
--             return 20/64, 39/64, 22/64, 41/64
--         else
--             error('Unknown role: '..tostring(role))
--         end
--     end
-- end

-- if not GetTexCoordsForRoleSmall then
--     GetTexCoordsForRoleSmall = function(role)
--         if ( role == 'TANK' ) then
--             return 0.5, 0.75, 0, 1
--         elseif ( role == 'HEALER' ) then
--             return 0.75, 1, 0, 1
--         elseif ( role == 'DAMAGER' ) then
--             return 0.25, 0.5, 0, 1
--         else
--             error('Unknown role: '..tostring(role))
--         end
--     end
-- end

-- if not LE_MODEL_BLEND_OPERATION_NONE then
--     LE_MODEL_BLEND_OPERATION_NONE = Enum.ModelBlendOperation.None
-- end

-- if not LE_MODEL_BLEND_OPERATION_ANIM then
--     LE_MODEL_BLEND_OPERATION_ANIM = Enum.ModelBlendOperation.Anim
-- end

-- 10.2.0
if not GetCVarInfo then
    GetCVarInfo = C_CVar.GetCVarInfo
end

if not EnableAddOn then
    EnableAddOn = C_AddOns.EnableAddOn
end

if not DisableAddOn then
    DisableAddOn = C_AddOns.DisableAddOn
end

if not GetAddOnEnableState then
    GetAddOnEnableState = function(character, name) return C_AddOns.GetAddOnEnableState(name, character) end
end

if not LoadAddOn then
    LoadAddOn = C_AddOns.LoadAddOn
end

if not IsAddOnLoaded then
    IsAddOnLoaded = C_AddOns.IsAddOnLoaded
end

if not EnableAllAddOns then
    EnableAllAddOns = C_AddOns.EnableAllAddOns
end

if not DisableAllAddOns then
    DisableAllAddOns = C_AddOns.DisableAllAddOns
end

if not GetAddOnInfo then
    GetAddOnInfo = C_AddOns.GetAddOnInfo
end

if not GetAddOnDependencies then
    GetAddOnDependencies = C_AddOns.GetAddOnDependencies
end

if not GetAddOnOptionalDependencies then
    GetAddOnOptionalDependencies = C_AddOns.GetAddOnOptionalDependencies
end

if not GetNumAddOns then
    GetNumAddOns = C_AddOns.GetNumAddOns
end

if not SaveAddOns then
    SaveAddOns = C_AddOns.SaveAddOns
end

if not ResetAddOns then
    ResetAddOns = C_AddOns.ResetAddOns
end

if not ResetDisabledAddOns then
    ResetDisabledAddOns = C_AddOns.ResetDisabledAddOns
end

if not IsAddonVersionCheckEnabled then
    IsAddonVersionCheckEnabled = C_AddOns.IsAddonVersionCheckEnabled
end

if not SetAddonVersionCheck then
    SetAddonVersionCheck = C_AddOns.SetAddonVersionCheck
end

if not IsAddOnLoadOnDemand then
    IsAddOnLoadOnDemand = C_AddOns.IsAddOnLoadOnDemand
end

hooksecurefunc('SetPortraitToTexture', function(texture)
    if type(texture) == 'string' then
        print(format('FIXME: SetPortraitToTexture Caller: %s, Debug Stack: %s', debugstack(2, 1, 0), debugstack(2)))
    end
end)

-- 10.2.5
if not GetTimeToWellRested then
    GetTimeToWellRested = function() return nil end
end

-- if not FillLocalizedClassList then
-- 	FillLocalizedClassList = function(tbl, isFemale)
-- 		local classList = LocalizedClassList(isFemale)
-- 		MergeTable(tbl, classList)
-- 		return tbl
-- 	end
-- end

if not GetSetBonusesForSpecializationByItemID then
    GetSetBonusesForSpecializationByItemID = C_Item.GetSetBonusesForSpecializationByItemID
end

if not GetItemStats then
    GetItemStats = function(itemLink, existingTable)
		local statTable = C_Item.GetItemStats(itemLink)
		if existingTable then
			MergeTable(existingTable, statTable)
			return existingTable
		else
			return statTable
		end
	end
end

if not GetItemStatDelta then
    GetItemStatDelta = function(itemLink1, itemLink2, existingTable)
        local statTable = C_Item.GetItemStatDelta(itemLink1, itemLink2)
        if existingTable then
            MergeTable(existingTable, statTable)
            return existingTable
        else
            return statTable
        end
    end
end

if not UnitAura then
    UnitAura = function(unitToken, index, filter)
        local auraData = C_UnitAuras.GetAuraDataByIndex(unitToken, index, filter)
        if not auraData then
            return nil
        end

        return AuraUtil.UnpackAuraData(auraData)
    end
end

if not UnitBuff then
    UnitBuff = function(unitToken, index, filter)
        local auraData = C_UnitAuras.GetBuffDataByIndex(unitToken, index, filter)
        if not auraData then
            return nil
        end

        return AuraUtil.UnpackAuraData(auraData)
    end
end

if not UnitDebuff then
    UnitDebuff = function(unitToken, index, filter)
        local auraData = C_UnitAuras.GetDebuffDataByIndex(unitToken, index, filter)
        if not auraData then
            return nil
        end

        return AuraUtil.UnpackAuraData(auraData)
    end
end

if not UnitAuraBySlot then
    UnitAuraBySlot = function(unitToken, index)
        local auraData = C_UnitAuras.GetAuraDataBySlot(unitToken, index)
        if not auraData then
            return nil
        end

        return AuraUtil.UnpackAuraData(auraData)
    end
end

if not UnitAuraSlots then
    UnitAuraSlots = C_UnitAuras.GetAuraSlots
end

-- 10.2.6
if not FrameXML_Debug then
    FrameXML_Debug = C_Debug.FrameXMLDebug
end

if not GetMawPowerLinkBySpellID then
    GetMawPowerLinkBySpellID = C_Spell.GetMawPowerLinkBySpellID
end

if C_TaskQuest and not C_TaskQuest.GetUIWidgetSetIDFromQuestID then
    C_TaskQuest.GetUIWidgetSetIDFromQuestID = C_TaskQuest.GetQuestTooltipUIWidgetSet
end

-- 10.2.7
if not ClosePetStables then
    ClosePetStables = C_StableInfo.ClosePetStables
end

if not GetStablePetInfo then
    GetStablePetInfo = function(...)
        local t = C_StableInfo.GetStablePetInfo(...)
        if t then
           return t.icon, t.name, t.level, t.familyName, t.specialization
        end
     end
end

if not PickupStablePet then
    PickupStablePet = C_StableInfo.PickupStablePet
end

if not GetStablePetFoodTypes then
    GetStablePetFoodTypes = function(...)
        local t = C_StableInfo.GetStablePetFoodTypes(...)
        if t then
           return unpack(t)
        end
     end
end

if not IsAtStableMaster then
    IsAtStableMaster = C_StableInfo.IsAtStableMaster
end

if not SetPetSlot then
    SetPetSlot = C_StableInfo.SetPetSlot
end

if not PetAbandon then
    PetAbandon = C_PetInfo.PetAbandon
end

if not PetRename then
    PetRename = function(name, declensions)
        C_PetInfo.PetRename(name, nil, declensions)
    end
end

if not PetCanBeRenamed then
    PetCanBeRenamed = function() return true end
end

-- C_CurrencyInfo
if not GetCoinIcon then
    GetCoinIcon = C_CurrencyInfo.GetCoinIcon
end

if not GetCoinText then
    GetCoinText = C_CurrencyInfo.GetCoinText
end

if not GetCoinTextureString then
    GetCoinTextureString = C_CurrencyInfo.GetCoinTextureString
end

-- C_GuildInfo
if not GuildInvite then
    GuildInvite = C_GuildInfo.Invite
end

if not GuildUninvite then
    GuildUninvite = C_GuildInfo.Uninvite
end

if not GuildPromote then
    GuildPromote = C_GuildInfo.Promote
end

if not GuildDemote then
    GuildDemote = C_GuildInfo.Demote
end

if not GuildSetLeader then
    GuildSetLeader = C_GuildInfo.SetLeader
end

if not GuildSetMOTD then
    GuildSetMOTD = C_GuildInfo.SetMOTD
end

if not GuildLeave then
    GuildLeave = C_GuildInfo.Leave
end

if not GuildDisband then
    GuildDisband = C_GuildInfo.Disband
end

-- C_Item
if not GetItemQualityColor then
    GetItemQualityColor = C_Item.GetItemQualityColor
end

if not GetItemInfoInstant then
    GetItemInfoInstant = C_Item.GetItemInfoInstant
end

if not GetItemSetInfo then
    GetItemSetInfo = C_Item.GetItemSetInfo
end

if not GetItemChildInfo then
    GetItemChildInfo = C_Item.GetItemChildInfo
end

if not DoesItemContainSpec then
    DoesItemContainSpec = C_Item.DoesItemContainSpec
end

if not GetItemGem then
    GetItemGem = C_Item.GetItemGem
end

if not GetItemCreationContext then
    GetItemCreationContext = C_Item.GetItemCreationContext
end

if not GetItemIcon then
    GetItemIcon = C_Item.GetItemIconByID
end

if not GetItemFamily then
    GetItemFamily = C_Item.GetItemFamily
end

if not GetItemSpell then
    GetItemSpell = C_Item.GetItemSpell
end

if not IsArtifactPowerItem then
    IsArtifactPowerItem = C_Item.IsArtifactPowerItem
end

if not IsCurrentItem then
    IsCurrentItem = C_Item.IsCurrentItem
end

if not IsUsableItem then
    IsUsableItem = C_Item.IsUsableItem
end

if not IsHelpfulItem then
    IsHelpfulItem = C_Item.IsHelpfulItem
end

if not IsHarmfulItem then
    IsHarmfulItem = C_Item.IsHarmfulItem
end

if not IsConsumableItem then
    IsConsumableItem = C_Item.IsConsumableItem
end

if not IsEquippableItem then
    IsEquippableItem = C_Item.IsEquippableItem
end

if not IsEquippedItem then
    IsEquippedItem = C_Item.IsEquippedItem
end

if not IsEquippedItemType then
    IsEquippedItemType = C_Item.IsEquippedItemType
end

if not ItemHasRange then
    ItemHasRange = C_Item.ItemHasRange
end

if not IsItemInRange then
    IsItemInRange = C_Item.IsItemInRange
end

if not GetItemClassInfo then
    GetItemClassInfo = C_Item.GetItemClassInfo
end

if not GetItemInventorySlotInfo then
    GetItemInventorySlotInfo = C_Item.GetItemInventorySlotInfo
end

if not BindEnchant then
    BindEnchant = C_Item.BindEnchant
end

if not ActionBindsItem then
    ActionBindsItem = C_Item.ActionBindsItem
end

if not ReplaceEnchant then
    ReplaceEnchant = C_Item.ReplaceEnchant
end

if not ReplaceTradeEnchant then
    ReplaceTradeEnchant = C_Item.ReplaceTradeEnchant
end

if not ConfirmBindOnUse then
    ConfirmBindOnUse = C_Item.ConfirmBindOnUse
end

if not ConfirmOnUse then
    ConfirmOnUse = C_Item.ConfirmOnUse
end

if not ConfirmNoRefundOnUse then
    ConfirmNoRefundOnUse = C_Item.ConfirmNoRefundOnUse
end

if not DropItemOnUnit then
    DropItemOnUnit = C_Item.DropItemOnUnit
end

if not EndBoundTradeable then
    EndBoundTradeable = C_Item.EndBoundTradeable
end

if not EndRefund then
    EndRefund = C_Item.EndRefund
end

if not GetItemInfo then
    GetItemInfo = C_Item.GetItemInfo
end

if not GetDetailedItemLevelInfo then
    GetDetailedItemLevelInfo = C_Item.GetDetailedItemLevelInfo
end

if not GetItemSpecInfo then
    GetItemSpecInfo = C_Item.GetItemSpecInfo
end

if not GetItemUniqueness then
    GetItemUniqueness = C_Item.GetItemUniqueness
end

if not GetItemCount then
    GetItemCount = C_Item.GetItemCount
end

if not PickupItem then
    PickupItem = C_Item.PickupItem
end

if not GetItemSubClassInfo then
    GetItemSubClassInfo = C_Item.GetItemSubClassInfo
end

if not UseItemByName then
    UseItemByName = C_Item.UseItemByName
end

if not EquipItemByName then
    EquipItemByName = C_Item.EquipItemByName
end

if not ReplaceTradeskillEnchant then
    ReplaceTradeskillEnchant = C_Item.ReplaceTradeskillEnchant
end

if not GetItemCooldown then
    GetItemCooldown = C_Item.GetItemCooldown
end

if not IsCorruptedItem then
    IsCorruptedItem = C_Item.IsCorruptedItem
end

if not IsCosmeticItem then
    IsCosmeticItem = C_Item.IsCosmeticItem
end

if not IsDressableItem then
    IsDressableItem = C_Item.IsDressableItem
end

-- C_PvP
if not IsSubZonePVPPOI then
    IsSubZonePVPPOI = C_PvP.IsSubZonePVPPOI
end

if not GetZonePVPInfo then
    GetZonePVPInfo = C_PvP.GetZonePVPInfo
end

if not TogglePVP then
    TogglePVP = C_PvP.TogglePVP
end

if not SetPVP then
    SetPVP = C_PvP.SetPVP
end

-- C_Sound
if not PlayVocalErrorSoundID then
    PlayVocalErrorSoundID = C_Sound.PlayVocalErrorSound
end

-- C_Spell
if not TargetSpellReplacesBonusTree then
    TargetSpellReplacesBonusTree = C_Spell.TargetSpellReplacesBonusTree
end

if not GetMaxSpellStartRecoveryOffset then
    GetMaxSpellStartRecoveryOffset = C_Spell.GetSpellQueueWindow
end

if not GetSpellQueueWindow then
    GetSpellQueueWindow = C_Spell.GetSpellQueueWindow
end

if not GetSchoolString then
    GetSchoolString = C_Spell.GetSchoolString
end

-- 11.0.0
if not GetSpellInfo then
    GetSpellInfo = function(spellID)
        if not spellID then
            return nil
        end

        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if spellInfo then
            return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID
        end
    end
end

if not GetNumSpellTabs then
    GetNumSpellTabs = C_SpellBook.GetNumSpellBookSkillLines
end

if not GetSpellTabInfo then
    GetSpellTabInfo = function(index)
        local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(index)
        if skillLineInfo then
            return	skillLineInfo.name,
                    skillLineInfo.iconID,
                    skillLineInfo.itemIndexOffset,
                    skillLineInfo.numSpellBookItems,
                    skillLineInfo.isGuild,
                    skillLineInfo.offSpecID,
                    skillLineInfo.shouldHide,
                    skillLineInfo.specID
        end
    end
end

if not GetSpellCooldown then
    GetSpellCooldown = function(spellID)
        local spellCooldownInfo = C_Spell.GetSpellCooldown(spellID)
        if spellCooldownInfo then
            return spellCooldownInfo.startTime, spellCooldownInfo.duration, spellCooldownInfo.isEnabled, spellCooldownInfo.modRate
        end
    end
end
