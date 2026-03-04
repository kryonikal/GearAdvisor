GearAdvisor = GearAdvisor or {}
local CS = GearAdvisor

CS.Detect = CS.Detect or {}

local DRUID="DRUID"

function CS.Detect:GetClass()
    return select(2,UnitClass("player"))
end

function CS.Detect:GetRace()
    return select(2,UnitRace("player"))
end

function CS.Detect:GetPrimaryTalentTab()
    if not GetNumTalentTabs or not GetTalentTabInfo then return nil end

    local bestTab, bestPts = 1, -1
    local tabs = GetNumTalentTabs() or 0

    for i=1,tabs do
        local _,_,points = GetTalentTabInfo(i)
        points = tonumber(points) or 0
        if points > bestPts then
            bestPts = points
            bestTab = i
        end
    end

    return bestTab
end

local function ActiveDruidForm()
    if not GetShapeshiftFormInfo then return nil end

    for i=1,10 do
        local icon, name, active = GetShapeshiftFormInfo(i)
        if active then
            if type(name) ~= "string" then name = "" end
            local n = string.lower(name)
            if string.find(n, "bear", 1, true) then return "BEAR" end
            if string.find(n, "dire bear", 1, true) then return "BEAR" end
            if string.find(n, "cat", 1, true) then return "CAT" end
            if string.find(n, "moonkin", 1, true) then return "MOONKIN" end
        end
    end

    return nil
end

function CS.Detect:GetSpec()
    local class = self:GetClass()
    if not class then return "GENERIC" end

    -- If user set override in UI, Weights.lua uses it; this is just AUTO.
    if class == DRUID then
        local form = ActiveDruidForm()

        if form == "BEAR" then return "DRUID_FERAL_TANK" end
        if form == "CAT" then return "DRUID_FERAL_DPS" end
        if form == "MOONKIN" then return "DRUID_BALANCE" end
        -- If no form: fall back to talents
    end

    local tab = self:GetPrimaryTalentTab()
    if not tab then return "GENERIC" end

    if class == "DRUID" then
        if tab == 1 then return "DRUID_BALANCE" end
        if tab == 2 then return "DRUID_FERAL_DPS" end
        if tab == 3 then return "DRUID_RESTO" end
    end

    if class == "WARRIOR" then
        if tab == 3 then return "WARRIOR_PROT" end
        if tab == 2 then return "WARRIOR_FURY" end
        return "WARRIOR_ARMS"
    end

    if class == "PALADIN" then
        if tab == 1 then return "PALADIN_HOLY" end
        if tab == 2 then return "PALADIN_PROT" end
        return "PALADIN_RET"
    end

    if class == "PRIEST" then
        if tab == 3 then return "PRIEST_SHADOW" end
        if tab == 1 then return "PRIEST_DISC" end
        return "PRIEST_HOLY"
    end

    if class == "SHAMAN" then
        if tab == 1 then return "SHAMAN_ELE" end
        if tab == 2 then return "SHAMAN_ENH" end
        return "SHAMAN_RESTO"
    end

    if class == "MAGE" then
        if tab == 1 then return "MAGE_ARCANE" end
        if tab == 2 then return "MAGE_FIRE" end
        return "MAGE_FROST"
    end

    if class == "WARLOCK" then
        if tab == 1 then return "WARLOCK_AFF" end
        if tab == 2 then return "WARLOCK_DEMO" end
        return "WARLOCK_DEST"
    end

    if class == "ROGUE" then
        if tab == 2 then return "ROGUE_COMBAT" end
        if tab == 3 then return "ROGUE_SUB" end
        return "ROGUE_ASSA"
    end

    if class == "HUNTER" then
        if tab == 1 then return "HUNTER_BM" end
        if tab == 2 then return "HUNTER_MM" end
        return "HUNTER_SV"
    end

    return "GENERIC"
end

function CS.Detect:GetContext()
    local instanceType = "none"
    if IsInInstance then
        local _,t = IsInInstance()
        if type(t) == "string" then instanceType = t end
    end

    local isPvP = UnitIsPVP and UnitIsPVP("player")

    if isPvP and CS.DB.enablePvP then return "PVP" end
    if instanceType == "raid" and CS.DB.enableRaid then return "RAID" end
    if instanceType == "party" then
        if CS.DB.enableHeroic then return "DUNGEON/HEROIC" end
        if CS.DB.enableDungeon then return "DUNGEON" end
    end

    return "OPEN WORLD"
end