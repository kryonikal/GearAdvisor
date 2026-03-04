GearAdvisor = GearAdvisor or {}
local CS = GearAdvisor

CS.Util = CS.Util or {}
local U = CS.Util

function U.Copy(t)
    local n = {}
    if not t then return n end
    for k,v in pairs(t) do n[k] = v end
    return n
end

function U.Fmt(v,d)
    d = tonumber(d) or 1
    if d < 0 then d = 0 end
    if d > 2 then d = 2 end
    local p = math.pow(10,d)
    return tostring(math.floor((tonumber(v) or 0)*p+0.5)/p)
end

function U.SafeGetCombatRating(id)
    if not GetCombatRating then return 0 end
    local v = GetCombatRating(id)
    return tonumber(v) or 0
end

function U.NormalizeItemStats(raw)
    local stats = {}
    if not raw then return stats end

    for k,v in pairs(raw) do
        v = tonumber(v) or 0
        if v ~= 0 then
            if k == "ARMOR" then
                stats.RESISTANCE0_NAME = (stats.RESISTANCE0_NAME or 0) + v
            else
                stats[k] = (stats[k] or 0) + v
            end
        end
    end

    return stats
end

--------------------------------------------------
-- TOOLTIP SCANNER
--------------------------------------------------

local scanner = CreateFrame("GameTooltip","GearAdvisorScanner",nil,"GameTooltipTemplate")
scanner:SetOwner(UIParent,"ANCHOR_NONE")

local function AddStat(stats,key,val)
    val = tonumber(val)
    if not val or val == 0 then return end
    stats[key] = (stats[key] or 0) + val
end

local RATING_PATTERNS = {
    { key="ITEM_MOD_EXPERTISE_RATING_SHORT",  kw="expertise" },
    { key="ITEM_MOD_HIT_RATING_SHORT",        kw="hit" },
    { key="ITEM_MOD_CRIT_RATING_SHORT",       kw="critical strike" },
    { key="ITEM_MOD_HASTE_RATING_SHORT",      kw="haste" },
    { key="ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", kw="defense" },
    { key="ITEM_MOD_DODGE_RATING_SHORT",      kw="dodge" },
    { key="ITEM_MOD_PARRY_RATING_SHORT",      kw="parry" },
    { key="ITEM_MOD_BLOCK_RATING_SHORT",      kw="block" },
    { key="ITEM_MOD_RESILIENCE_RATING_SHORT", kw="resilience" },
}

local function MatchAny(text, patterns)
    for _,pat in ipairs(patterns) do
        local v = string.match(text, pat)
        if v then return v end
    end
    return nil
end

function U.ExtractEquipStats(link)
    local stats = {}
    if not link then return stats end

    scanner:SetOwner(UIParent,"ANCHOR_NONE")
    scanner:SetHyperlink(link)

    local lines = scanner:NumLines()

    for i=1,lines do
        local line = _G["GearAdvisorScannerTextLeft"..i]
        if line then
            local text = line:GetText()
            if text then
                text = string.lower(text)

                -- Ratings (handles: "increases your X rating by N", "improves X rating by N", and "X rating by N")
                for _,r in ipairs(RATING_PATTERNS) do
                    local kw = r.kw
                    local v = MatchAny(text, {
                        "increases%s+your%s+"..kw.."%s+rating%s+by%s+(%d+)",
                        "increases%s+"..kw.."%s+rating%s+by%s+(%d+)",
                        "improves%s+"..kw.."%s+rating%s+by%s+(%d+)",
                        kw.."%s+rating%s+by%s+(%d+)",
                    })
                    if v then AddStat(stats, r.key, v) end
                end

                -- Attack power
                do
                    local v = MatchAny(text, {
                        "increases%s+attack%s+power%s+by%s+(%d+)",
                        "attack%s+power%s+by%s+(%d+)",
                    })
                    if v then AddStat(stats,"ITEM_MOD_ATTACK_POWER_SHORT",v) end
                end

                -- MP5 / Mana regen
                do
                    local v = MatchAny(text, {
                        "restores%s+(%d+)%s+mana%s+per%s+5%s+sec",
                        "(%d+)%s+mana%s+per%s+5%s+sec",
                        "(%d+)%s+mana%s+every%s+5%s+sec",
                    })
                    if v then AddStat(stats,"ITEM_MOD_MANA_REGENERATION_SHORT",v) end
                end

                -- Spell power / Healing
                do
                    local v = MatchAny(text, {
                        "increases%s+damage%s+and%s+healing%s+done%s+by%s+up%s+to%s+(%d+)",
                        "increases%s+spell%s+damage%s+and%s+healing%s+by%s+up%s+to%s+(%d+)",
                    })
                    if v then AddStat(stats,"ITEM_MOD_SPELL_DAMAGE_DONE_SHORT",v) end
                end

                do
                    local v = MatchAny(text, {
                        "increases%s+healing%s+done%s+by%s+up%s+to%s+(%d+)",
                        "increases%s+healing%s+by%s+up%s+to%s+(%d+)",
                    })
                    if v then AddStat(stats,"ITEM_MOD_HEALING_DONE_SHORT",v) end
                end
            end
        end
    end

    scanner:Hide()
    return stats
end

--------------------------------------------------
-- WEAPON SCANNER
--------------------------------------------------

function U.ExtractWeaponStats(link)
    local out = { min=nil, max=nil, speed=nil, dps=nil }
    if not link then return out end

    scanner:SetOwner(UIParent,"ANCHOR_NONE")
    scanner:SetHyperlink(link)

    local lines = scanner:NumLines()

    local minD, maxD, spd, dps

    for i=1,lines do
        local line = _G["GearAdvisorScannerTextLeft"..i]
        if line then
            local text = line:GetText()
            if text then
                text = string.lower(text)

                if not minD then
                    local a,b = string.match(text,"(%d+)%s*%-%s*(%d+)%s*damage")
                    if a and b then
                        minD = tonumber(a)
                        maxD = tonumber(b)
                    end
                end

                if not spd then
                    local s = string.match(text,"speed%s*([%d%.]+)")
                    if s then spd = tonumber(s) end
                end

                if not dps then
                    local d = string.match(text,"([%d%.]+)%s*dps")
                    if d then dps = tonumber(d) end
                end
            end
        end
    end

    scanner:Hide()

    out.min = minD
    out.max = maxD
    out.speed = spd

    if dps and dps > 0 then
        out.dps = dps
    elseif minD and maxD and spd and spd > 0 then
        out.dps = ((minD + maxD) / 2) / spd
    end

    return out
end