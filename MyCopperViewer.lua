local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_MONEY")

MyCopperViewerDB = MyCopperViewerDB or {
    x = 0, y = 0,
    size = 16,
    r = 1, g = 0.82, b = 0,
    show = true,
    mode = "copper",
    full = false,
    space = true,
    lang = "ru",
    shortType = "m", -- k / m / kk / e
}

local holder = CreateFrame("Frame", "MCV_Frame", UIParent)
holder:SetFrameStrata("HIGH")
holder:SetSize(200, 50)
holder:SetPoint("BOTTOMRIGHT", MainMenuBarBackpackButton, "TOPRIGHT", MyCopperViewerDB.x, MyCopperViewerDB.y)
holder:EnableMouse(true)
holder:SetMovable(true)
holder:RegisterForDrag("LeftButton")

holder:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

holder:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    MyCopperViewerDB.x = x
    MyCopperViewerDB.y = y
end)

local text = holder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("CENTER")

local L = {
    ru = {c="м", s="с", copper="медь", silver="серебро"},
    en = {c="c", s="s", copper="copper", silver="silver"},
}

local function GetSuffix()
    local loc = L[MyCopperViewerDB.lang]

    if MyCopperViewerDB.mode == "copper" then
        return MyCopperViewerDB.full and loc.copper or loc.c
    elseif MyCopperViewerDB.mode == "silver" then
        return MyCopperViewerDB.full and loc.silver or loc.s
    end
    return ""
end

local function ShortFormat(copper)
    local t = MyCopperViewerDB.shortType

    if t == "e" then
        return string.format("%.1e", copper)
    elseif t == "kk" then
        return string.format("%.1fkk", copper / 1000000)
    elseif t == "m" then
        return string.format("%.1fm", copper / 1000000)
    else
        return string.format("%.1fk", copper / 1000)
    end
end

local function FormatMoney(copper)
    if MyCopperViewerDB.mode == "short" then
        return ShortFormat(copper)
    end

    local value = copper
    if MyCopperViewerDB.mode == "silver" then
        value = math.floor(copper / 100)
    end

    local suffix = GetSuffix()

    if MyCopperViewerDB.space and suffix ~= "" then
        return value .. " " .. suffix
    else
        return value .. suffix
    end
end

local function Update()
    if not MyCopperViewerDB.show then
        holder:Hide()
        return
    end

    holder:Show()

    local copper = GetMoney()
    text:SetText(FormatMoney(copper))
    text:SetTextColor(MyCopperViewerDB.r, MyCopperViewerDB.g, MyCopperViewerDB.b)
    text:SetFont("Fonts\\FRIZQT__.TTF", MyCopperViewerDB.size, "OUTLINE")
end

frame:SetScript("OnEvent", Update)

local panel = CreateFrame("Frame", "MCV_Config", InterfaceOptionsFramePanelContainer)
panel.name = "MyCopperViewer"

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("MyCopperViewer")

local showCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
showCheck:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
showCheck.text:SetText("Показывать")
showCheck:SetScript("OnClick", function(self)
    MyCopperViewerDB.show = self:GetChecked()
    Update()
end)

local langBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
langBtn:SetSize(120, 25)
langBtn:SetPoint("TOPLEFT", showCheck, "BOTTOMLEFT", 0, -10)
langBtn:SetText("Сменить язык")
langBtn:SetScript("OnClick", function()
    MyCopperViewerDB.lang = (MyCopperViewerDB.lang == "ru") and "en" or "ru"
    Update()
end)

panel:SetScript("OnShow", function()
    showCheck:SetChecked(MyCopperViewerDB.show)
end)

InterfaceOptions_AddCategory(panel)

SLASH_MYCV1 = "/mcv"
SlashCmdList["MYCV"] = function(msg)
    msg = msg:lower()

    if msg == "config" then
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel)
        return
    end

    if msg:find("x") then
        local val = tonumber(msg:match("%-?%d+"))
        if val then MyCopperViewerDB.x = val end
    elseif msg:find("y") then
        local val = tonumber(msg:match("%-?%d+"))
        if val then MyCopperViewerDB.y = val end
    end

    holder:ClearAllPoints()
    holder:SetPoint("BOTTOMRIGHT", MainMenuBarBackpackButton, "TOPRIGHT", MyCopperViewerDB.x, MyCopperViewerDB.y)

    Update()
end

local dropdown = CreateFrame("Frame", "MCV_ModeDropdown", panel, "UIDropDownMenuTemplate")
dropdown:SetPoint("TOPLEFT", langBtn, "BOTTOMLEFT", -15, -10)

local function GetPreview(mode)
    local copper = GetMoney()

    if mode == "copper" then
        return copper .. "c"
    elseif mode == "silver" then
        return math.floor(copper/100) .. "s"
    elseif mode == "short" then
        return ShortFormat(copper)
    end
end

UIDropDownMenu_SetWidth(dropdown, 180)

UIDropDownMenu_Initialize(dropdown, function(self, level)
    local modes = {"copper","silver","short"}

    for _,mode in ipairs(modes) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = mode .. " (" .. GetPreview(mode) .. ")"
        info.func = function()
            MyCopperViewerDB.mode = mode
            UIDropDownMenu_SetText(dropdown, info.text)
            Update()
        end
        UIDropDownMenu_AddButton(info)
    end
end)

UIDropDownMenu_SetText(dropdown, MyCopperViewerDB.mode)