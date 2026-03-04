GearAdvisor = GearAdvisor or {}
local CS = GearAdvisor
local U = CS.Util

CS.Racials = CS.Racials or {}

-- Weapon skill racials -> approximate by reducing hit/expertise value slightly if active weapon matches.
local function EquippedWeaponSubClass()
    local link = GetInventoryItemLink("player", 16)
    if not link then return nil end
    local _,_,_,_,_,_,_,_,_,_,_,_,sub = GetItemInfo(link)
    return sub
end

function CS.Racials:Apply(weights)
    local w = U.Copy(weights)
    local race = CS.Detect:GetRace()
    local sub = EquippedWeaponSubClass()

    -- Human: swords (7) + maces (4) weapon skill
    if race == "Human" and (sub == 7 or sub == 4) then
        if w.ITEM_MOD_HIT_RATING_SHORT then w.ITEM_MOD_HIT_RATING_SHORT = w.ITEM_MOD_HIT_RATING_SHORT * 0.90 end
        if w.ITEM_MOD_EXPERTISE_RATING_SHORT then w.ITEM_MOD_EXPERTISE_RATING_SHORT = w.ITEM_MOD_EXPERTISE_RATING_SHORT * 0.90 end
    end

    -- Orc: axes (0)
    if race == "Orc" and sub == 0 then
        if w.ITEM_MOD_HIT_RATING_SHORT then w.ITEM_MOD_HIT_RATING_SHORT = w.ITEM_MOD_HIT_RATING_SHORT * 0.90 end
        if w.ITEM_MOD_EXPERTISE_RATING_SHORT then w.ITEM_MOD_EXPERTISE_RATING_SHORT = w.ITEM_MOD_EXPERTISE_RATING_SHORT * 0.90 end
    end

    -- Troll: bows (2) (mostly ranged; reduce hit slightly)
    if race == "Troll" and sub == 2 then
        if w.ITEM_MOD_HIT_RATING_SHORT then w.ITEM_MOD_HIT_RATING_SHORT = w.ITEM_MOD_HIT_RATING_SHORT * 0.92 end
    end

    return w
end