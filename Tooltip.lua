GearAdvisor = GearAdvisor or {}
local GA = GearAdvisor
local U = GA.Util

GA.Tooltip = GA.Tooltip or {}

local SLOT_MAP = {
    INVTYPE_FINGER={11,12}, INVTYPE_TRINKET={13,14},
    INVTYPE_HEAD={1}, INVTYPE_NECK={2}, INVTYPE_SHOULDER={3}, INVTYPE_BODY={4},
    INVTYPE_CHEST={5}, INVTYPE_ROBE={5}, INVTYPE_WAIST={6}, INVTYPE_LEGS={7},
    INVTYPE_FEET={8}, INVTYPE_WRIST={9}, INVTYPE_HAND={10}, INVTYPE_CLOAK={15},
    INVTYPE_WEAPON={16}, INVTYPE_2HWEAPON={16}, INVTYPE_WEAPONMAINHAND={16},
    INVTYPE_WEAPONOFFHAND={17}, INVTYPE_SHIELD={17}, INVTYPE_HOLDABLE={17},
    INVTYPE_RANGED={18}, INVTYPE_RANGEDRIGHT={18},
}

local SLOT_LABEL = {
    [11]="Ring 1",[12]="Ring 2",[13]="Trinket 1",[14]="Trinket 2",
    [1]="Head",[2]="Neck",[3]="Shoulder",[5]="Chest",[6]="Waist",[7]="Legs",[8]="Feet",
    [9]="Wrist",[10]="Hands",[15]="Back",[16]="Weapon",[17]="Offhand",[18]="Ranged",
}

local SLOT_WEIGHT = {
    [1]=1.0,[2]=0.55,[3]=0.8,[5]=1.0,[6]=0.7,[7]=1.0,[8]=0.7,
    [9]=0.55,[10]=0.7,[11]=0.35,[12]=0.35,[13]=0.40,[14]=0.40,
    [15]=0.45,[16]=1.2,[17]=0.8,[18]=1.0
}

local EQUIPPED_SLOTS_FOR_AVG = {1,2,3,5,6,7,8,9,10,11,12,13,14,15,16,17,18}

local function ColorForPercent(v)
    if v >= 50 then return "|cff00ff00" end     -- strong upgrade
    if v > 0 then return "|cffffff00" end       -- upgrade
    if v < 0 then return "|cffff4040" end       -- downgrade
    return "|cffaaaaaa"
end

local function Pretty(text)
    if not text then return "" end
    text = tostring(text):lower()
    text = text:gsub("^%l", string.upper)
    text = text:gsub("dps","DPS")
    text = text:gsub("tank","Tank")
    return text
end

local function CleanLabel(label, classLocal, classToken)
    if not label then return "" end
    label = tostring(label)

    -- strip leading "Druid " / localized class name
    if classLocal and classLocal ~= "" then
        local pat = "^%s*" .. classLocal:gsub("([^%w])","%%%1") .. "%s+"
        label = label:gsub(pat, "")
    end

    -- strip leading class token like "DRUID_"
    if classToken and classToken ~= "" then
        label = label:gsub("^%s*" .. classToken .. "%s*[_%-:]%s*", "")
        label = label:gsub("^%s*" .. classToken:lower() .. "%s*[_%-:]%s*", "")
    end

    -- some profiles might still prefix with "Druid" etc after casing changes
    label = label:gsub("^%s*[Dd][Rr][Uu][Ii][Dd]%s+", "")

    return label
end

local function GetSlotsForItem(link)
    local _,_,_,_,_,_,_,_,equipSlot = GetItemInfo(link)
    return equipSlot and SLOT_MAP[equipSlot] or nil
end

local function Score(link, weights)
    local raw = GetItemStats(link) or {}
    local stats = U.NormalizeItemStats(raw)

    local equipStats = U.ExtractEquipStats and U.ExtractEquipStats(link)
    if equipStats then
        for k,v in pairs(equipStats) do
            if not stats[k] or v > stats[k] then
                stats[k] = v
            end
        end
    end

    local score = 0
    for stat,val in pairs(stats) do
        local w = weights[stat]
        if w then score = score + (val * w) end
    end
    return score
end

local function CharacterAverageScore(weights)
    local sum,n = 0,0
    for _,slot in ipairs(EQUIPPED_SLOTS_FOR_AVG) do
        local link = GetInventoryItemLink("player",slot)
        if link then
            local s = Score(link,weights)
            if s and s>0 then
                sum = sum + s
                n = n + 1
            end
        end
    end
    if n==0 then return 1 end
    return sum/n
end

local function BestSwapForSpec(itemLink, slots, weights)
    local newScore = Score(itemLink,weights)
    local avgScore = CharacterAverageScore(weights)

    local bestSlot,bestSlotPct,bestOverallPct = nil,nil,nil

    for _,slot in ipairs(slots) do
        local eq = GetInventoryItemLink("player",slot)
        if eq then
            local oldScore = Score(eq,weights)
            local diff = newScore - oldScore

            local denom = math.max(newScore, oldScore, 1)
            local slotPct = (diff / denom) * 100
            local overallPct = (diff / avgScore) * (SLOT_WEIGHT[slot] or 0.5) * 100

            if bestSlotPct == nil or slotPct > bestSlotPct then
                bestSlot = slot
                bestSlotPct = slotPct
                bestOverallPct = overallPct
            end
        end
    end

    if bestSlotPct == nil then
        local fallbackSlot = slots and slots[1]
        if fallbackSlot then
            bestSlot = fallbackSlot
            bestSlotPct = 0
            bestOverallPct = 0
        end
    end

    return bestSlot,bestSlotPct,bestOverallPct
end

function GA.Tooltip:Annotate(tooltip)
    if not GA.DB or not GA.DB.enabled then return end

    local _,itemLink = tooltip:GetItem()
    if not itemLink then return end

    local slots = GetSlotsForItem(itemLink)
    if not slots then return end

    local classLocal, classToken = UnitClass("player")

    local ctx = "OPEN WORLD"
    if GA.Detect and GA.Detect.GetContext then
        ctx = GA.Detect:GetContext() or ctx
    end

    tooltip:AddLine(" ")
    tooltip:AddLine("|cff00ff88GearAdvisor|r")

    local lines = {}

    for profileKey,_ in pairs(GA.Weights.Profiles) do
        if profileKey and profileKey:find(classToken,1,true) then
            local weights,label = GA.Weights:BuildWeights(profileKey,ctx)

            local bestSlot,slotPct,overallPct = BestSwapForSpec(itemLink,slots,weights)

            if slotPct ~= nil and math.abs(slotPct) > 0.1 then
                label = CleanLabel(label, classLocal, classToken)

                local slotColor = ColorForPercent(slotPct)
                local overallColor = ColorForPercent(overallPct)

                local s1 = slotPct>0 and "+" or ""
                local s2 = overallPct>0 and "+" or ""
                local slotText = bestSlot and SLOT_LABEL[bestSlot] or "Slot"

                table.insert(lines,{
                    txt =
                        Pretty(label)..": "
                        ..slotColor..s1..U.Fmt(slotPct,1).."%|r slot / "
                        ..overallColor..s2..U.Fmt(overallPct,1).."%|r overall "
                        .."("..slotText..")",
                    sort = slotPct or 0
                })
            end
        end
    end

    table.sort(lines,function(a,b) return a.sort>b.sort end)

    for _,l in ipairs(lines) do
        tooltip:AddLine(l.txt)
    end
end

local function Hook()
    GameTooltip:HookScript("OnTooltipSetItem",function(t) GA.Tooltip:Annotate(t) end)
    ItemRefTooltip:HookScript("OnTooltipSetItem",function(t) GA.Tooltip:Annotate(t) end)
end

local f=CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent",Hook)