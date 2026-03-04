GearAdvisor = GearAdvisor or {}
local GA = GearAdvisor
local U = GA.Util

GA.Weights = GA.Weights or {}

--------------------------------------------------
-- PROFILES
--------------------------------------------------

GA.Weights.Profiles = {

-- DRUID

DRUID_FERAL_DPS = {
label = "Feral DPS",
weights = {
ITEM_MOD_AGILITY_SHORT = 2.1,
ITEM_MOD_STRENGTH_SHORT = 2.0,
ITEM_MOD_ATTACK_POWER_SHORT = 1.0,
ITEM_MOD_CRIT_RATING_SHORT = 1.3,
ITEM_MOD_HIT_RATING_SHORT = 1.8,
ITEM_MOD_EXPERTISE_RATING_SHORT = 2.8,
ITEM_MOD_HASTE_RATING_SHORT = 1.4,
}
},

DRUID_FERAL_TANK = {
label = "Feral Tank",
weights = {
ITEM_MOD_AGILITY_SHORT = 2.0,
ITEM_MOD_STAMINA_SHORT = 1.6,
ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = 2.5,
ITEM_MOD_DODGE_RATING_SHORT = 2.2,
ITEM_MOD_EXPERTISE_RATING_SHORT = 1.2,
ITEM_MOD_HIT_RATING_SHORT = 0.9,
}
},

DRUID_BALANCE = {
label = "Balance",
weights = {
ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 1.9,
ITEM_MOD_INTELLECT_SHORT = 1.1,
ITEM_MOD_CRIT_RATING_SHORT = 1.2,
ITEM_MOD_HIT_RATING_SHORT = 1.7,
ITEM_MOD_HASTE_RATING_SHORT = 1.4,
}
},

DRUID_RESTORATION = {
label = "Restoration",
weights = {
ITEM_MOD_HEALING_DONE_SHORT = 2.0,
ITEM_MOD_INTELLECT_SHORT = 1.2,
ITEM_MOD_SPIRIT_SHORT = 1.0,
ITEM_MOD_MANA_REGENERATION_SHORT = 1.4,
}
},

-- WARRIOR

WARRIOR_ARMS = {
label = "Arms",
weights = {
ITEM_MOD_STRENGTH_SHORT = 2.2,
ITEM_MOD_CRIT_RATING_SHORT = 1.4,
ITEM_MOD_HIT_RATING_SHORT = 1.8,
ITEM_MOD_EXPERTISE_RATING_SHORT = 2.5,
ITEM_MOD_HASTE_RATING_SHORT = 1.1,
}
},

WARRIOR_FURY = {
label = "Fury",
weights = {
ITEM_MOD_STRENGTH_SHORT = 2.3,
ITEM_MOD_CRIT_RATING_SHORT = 1.5,
ITEM_MOD_HIT_RATING_SHORT = 2.0,
ITEM_MOD_EXPERTISE_RATING_SHORT = 2.6,
ITEM_MOD_HASTE_RATING_SHORT = 1.2,
}
},

WARRIOR_PROTECTION = {
label = "Protection",
weights = {
ITEM_MOD_STAMINA_SHORT = 1.8,
ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = 2.8,
ITEM_MOD_DODGE_RATING_SHORT = 2.2,
ITEM_MOD_PARRY_RATING_SHORT = 2.0,
ITEM_MOD_BLOCK_RATING_SHORT = 1.6,
}
},

-- MAGE

MAGE_ARCANE = {
label = "Arcane",
weights = {
ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 2.0,
ITEM_MOD_INTELLECT_SHORT = 1.3,
ITEM_MOD_HIT_RATING_SHORT = 1.8,
ITEM_MOD_CRIT_RATING_SHORT = 1.2,
ITEM_MOD_HASTE_RATING_SHORT = 1.4,
}
},

MAGE_FIRE = {
label = "Fire",
weights = {
ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 2.1,
ITEM_MOD_INTELLECT_SHORT = 1.2,
ITEM_MOD_HIT_RATING_SHORT = 1.9,
ITEM_MOD_CRIT_RATING_SHORT = 1.4,
ITEM_MOD_HASTE_RATING_SHORT = 1.3,
}
},

MAGE_FROST = {
label = "Frost",
weights = {
ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = 1.9,
ITEM_MOD_INTELLECT_SHORT = 1.3,
ITEM_MOD_HIT_RATING_SHORT = 1.8,
ITEM_MOD_CRIT_RATING_SHORT = 1.3,
ITEM_MOD_HASTE_RATING_SHORT = 1.2,
}
},

}

--------------------------------------------------
-- CAPS
--------------------------------------------------

local CAPS = {
MELEE_HIT = 142,
SPELL_HIT = 202,
EXPERTISE = 103,
DEFENSE = 490
}

--------------------------------------------------
-- CURRENT PLAYER STATS
--------------------------------------------------

local function GetCurrentStats()

local stats = {}

stats.hit = U.SafeGetCombatRating(6) or 0
stats.spellhit = U.SafeGetCombatRating(8) or 0
stats.expertise = U.SafeGetCombatRating(24) or 0
stats.defense = U.SafeGetCombatRating(2) or 0

return stats

end

--------------------------------------------------
-- SCALE FUNCTION
--------------------------------------------------

local function ScaleWeight(base,current,cap)

if not base then return base end

local remaining = cap - current

if remaining <= 0 then
return 0
end

local scale = remaining / cap

if scale < 0 then scale = 0 end
if scale > 1 then scale = 1 end

return base * scale

end

--------------------------------------------------
-- BUILD WEIGHTS
--------------------------------------------------

function GA.Weights:BuildWeights(profileKey,context)

local profile = self.Profiles[profileKey]
if not profile then return {}, "" end

local weights = U.Copy(profile.weights)
local stats = GetCurrentStats()

--------------------------------------------------
-- HIT SCALING
--------------------------------------------------

if weights.ITEM_MOD_HIT_RATING_SHORT then

local cap = CAPS.MELEE_HIT

if weights.ITEM_MOD_SPELL_DAMAGE_DONE_SHORT then
cap = CAPS.SPELL_HIT
end

weights.ITEM_MOD_HIT_RATING_SHORT =
ScaleWeight(weights.ITEM_MOD_HIT_RATING_SHORT,stats.hit,cap)

end

--------------------------------------------------
-- EXPERTISE SCALING
--------------------------------------------------

if weights.ITEM_MOD_EXPERTISE_RATING_SHORT then

weights.ITEM_MOD_EXPERTISE_RATING_SHORT =
ScaleWeight(weights.ITEM_MOD_EXPERTISE_RATING_SHORT,stats.expertise,CAPS.EXPERTISE)

end

--------------------------------------------------
-- DEFENSE SCALING
--------------------------------------------------

if weights.ITEM_MOD_DEFENSE_SKILL_RATING_SHORT then

weights.ITEM_MOD_DEFENSE_SKILL_RATING_SHORT =
ScaleWeight(weights.ITEM_MOD_DEFENSE_SKILL_RATING_SHORT,stats.defense,CAPS.DEFENSE)

end

return weights, profile.label

end