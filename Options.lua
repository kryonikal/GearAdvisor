GearAdvisor = GearAdvisor or {}
local SA = GearAdvisor

SA.DB_DEFAULTS = {
    enabled = true,
}

local function InitDB()
    if not GearAdvisorDB then
        GearAdvisorDB = {}
    end

    for k,v in pairs(SA.DB_DEFAULTS) do
        if GearAdvisorDB[k] == nil then
            GearAdvisorDB[k] = v
        end
    end

    SA.DB = GearAdvisorDB
end

local function CreateOptions()

    local panel = CreateFrame("Frame")
    panel.name = "GearAdvisor"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("GearAdvisor")

    local checkbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    checkbox.Text:SetText("Enable tooltip upgrades")

    checkbox:SetChecked(SA.DB.enabled)

    checkbox:SetScript("OnClick", function(self)
        SA.DB.enabled = self:GetChecked()
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "GearAdvisor")
        Settings.RegisterAddOnCategory(category)
    end

end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")

f:SetScript("OnEvent", function()
    InitDB()
    CreateOptions()
end)