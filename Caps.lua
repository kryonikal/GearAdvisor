-- Caps.lua (REPLACE WHOLE FILE)
GearAdvisor = GearAdvisor or {}
local CS = GearAdvisor
local U = CS.Util

CS.Caps = CS.Caps or {}

local CAPS = {
    ["OPEN WORLD"] = { melee_hit=79, spell_hit=126, expertise=48, defense=485 },
    ["DUNGEON"]    = { melee_hit=79, spell_hit=126, expertise=48, defense=485 },
    ["RAID"]       = { melee_hit=95, spell_hit=202, expertise=64, defense=490 },
    ["PVP"]        = { melee_hit=50, spell_hit=50 }
}

local function ModeFromContext(ctx)
    if ctx == "RAID" then return "RAID" end
    if ctx == "PVP" then return "PVP" end
    if ctx == "DUNGEON" then return "DUNGEON" end
    return "OPEN WORLD"
end

local function MultFromGap(gap, near1, near2, far)
    if gap <= 0 then return 0.05 end
    if gap <= 10 then return near1 or 2.4 end
    if gap <= 25 then return near2 or 1.9 end
    return far or 1.25
end

function CS.Caps:Apply(weights, profileKey, ctx, role)
    local w = U.Copy(weights)
    local mode = ModeFromContext(ctx)
    local c = CAPS[mode] or CAPS["OPEN WORLD"]

    -- Melee hit
    if (role == "melee" or role == "tank") and w.ITEM_MOD_HIT_RATING_SHORT and c.melee_hit then
        local cur = U.SafeGetCombatRating(6)
        w.ITEM_MOD_HIT_RATING_SHORT = w.ITEM_MOD_HIT_RATING_SHORT * MultFromGap(c.melee_hit - cur, 2.8, 2.1, 1.35)
    end

    -- Spell hit
    if role == "caster" and w.ITEM_MOD_HIT_RATING_SHORT and c.spell_hit then
        local cur = U.SafeGetCombatRating(8)
        w.ITEM_MOD_HIT_RATING_SHORT = w.ITEM_MOD_HIT_RATING_SHORT * MultFromGap(c.spell_hit - cur, 2.4, 1.9, 1.25)
    end

    -- Expertise
    if (role == "melee" or role == "tank") and w.ITEM_MOD_EXPERTISE_RATING_SHORT and c.expertise then
        local cur = U.SafeGetCombatRating(24)
        w.ITEM_MOD_EXPERTISE_RATING_SHORT = w.ITEM_MOD_EXPERTISE_RATING_SHORT * MultFromGap(c.expertise - cur, 3.2, 2.4, 1.45)
    end

    -- Defense (tank)
    if role == "tank" and w.ITEM_MOD_DEFENSE_SKILL_RATING_SHORT and c.defense then
        local cur = U.SafeGetCombatRating(2)
        w.ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = w.ITEM_MOD_DEFENSE_SKILL_RATING_SHORT * MultFromGap(c.defense - cur, 3.0, 2.2, 1.35)
    end

    -- PvP: resilience priority
    if mode == "PVP" then
        w.ITEM_MOD_RESILIENCE_RATING_SHORT = (w.ITEM_MOD_RESILIENCE_RATING_SHORT or 0) + 2.8
        if w.ITEM_MOD_STAMINA_SHORT then w.ITEM_MOD_STAMINA_SHORT = w.ITEM_MOD_STAMINA_SHORT * 1.15 end
    end

    return w
end