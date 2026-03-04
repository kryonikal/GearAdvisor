GearAdvisor = GearAdvisor or {}
local CS = GearAdvisor

CS.DB_DEFAULTS = {
    enabled = true,

    useSpecDetect = true,
    useCaps = true,
    useBuffs = true,
    useRacials = true,

    showProfile = true,
    showContext = true,
    showReplace = true,
    showScore = true,
    showPercent = true,
    showPerSlot = true,      -- ring1 vs ring2, trinket1 vs trinket2
    useUpgradeTiers = true,
    showBreakdown = false,   -- heavier tooltip

    enableDungeon = true,
    enableHeroic = true,
    enableRaid = true,
    enablePvP = true,

    decimals = 1,

    profileOverride = "AUTO",
}