local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_MONEY")
frame:RegisterEvent("PLAYER_LOGIN")

MyCopperViewerDB = MyCopperViewerDB or {
    x = 0, y = 0,
    size = 16,
    r = 1, g = 0.82, b = 0,
    show = true,
    mode = "copper",   -- copper / silver / short
    full = false,      -- c / copper
    space = true,      -- пробел между числом и суффиксом
    lang = "ru",       -- ru / en
    shortType = "m",   -- k / m / kk / e
}

local holder = CreateFrame("Frame", "MCV_Frame", UIParent)
holder:SetFrameStrata("DIALOG")
holder:SetSize(200, 50)
holder:EnableMouse(true)
holder:SetMovable(true)
holder:RegisterForDrag("LeftButton")

local function ApplyPosition()
    holder:ClearAllPoints()
    holder:SetPoint("BOTTOMRIGHT", MainMenuBarBackpackButton, "TOPRIGHT", MyCopperViewerDB.x, MyCopperViewerDB.y)
end

holder:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

holder:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local _, _, _, x, y = self:GetPoint()
    MyCopperViewerDB.x = x
    MyCopperViewerDB.y = y
end)

local text = holder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("CENTER")

local L = {
    ru = {
        c = "м",
        s = "с",
        copper = "медь",
        silver = "серебро",
        short = "сокр.",
        mode = "Режим",
    },
    en = {
        c = "c",
        s = "s",
        copper = "copper",
        silver = "silver",
        short = "short",
        mode = "Mode",
    },
}

local function GetLang()
    return L[MyCopperViewerDB.lang] or L.ru
end

local function GetSuffix()
    local loc = GetLang()

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

frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        ApplyPosition()
    end
    Update()
end)

local panel = CreateFrame("Frame", "MCV_Config")
panel.name = "MyCopperViewer"

local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("MyCopperViewer")

local showCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
showCheck:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
showCheck:SetText("Показывать")
showCheck:SetScript("OnClick", function(self)
    MyCopperViewerDB.show = self:GetChecked() and true or false
    Update()
end)

local langBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
langBtn:SetSize(120, 25)
langBtn:SetPoint("TOPLEFT", showCheck, "BOTTOMLEFT", 0, -10)
langBtn:SetText("Сменить язык")
langBtn:SetScript("OnClick", function()
    MyCopperViewerDB.lang = (MyCopperViewerDB.lang == "ru") and "en" or "ru"
    Update()
    RefreshDropdownText()
end)

local function GetPreview(mode)
    local copper = GetMoney()

    if mode == "copper" then
        return copper .. GetLang().c
    elseif mode == "silver" then
        return math.floor(copper / 100) .. GetLang().s
    elseif mode == "short" then
        return ShortFormat(copper)
    end

    return ""
end

local function GetModeLabel(mode)
    local loc = GetLang()

    if mode == "copper" then
        return loc.copper
    elseif mode == "silver" then
        return loc.silver
    elseif mode == "short" then
        return loc.short
    end

    return mode
end

local dropdown = CreateFrame("Frame", "MCV_ModeDropdown", panel, "UIDropDownMenuTemplate")
dropdown:SetPoint("TOPLEFT", langBtn, "BOTTOMLEFT", -15, -10)
UIDropDownMenu_SetWidth(dropdown, 180)

local function RefreshDropdownText()
    UIDropDownMenu_SetText(dropdown, GetModeLabel(MyCopperViewerDB.mode))
end

UIDropDownMenu_Initialize(dropdown, function(self, level)
    local modes = { "copper", "silver", "short" }

    for _, mode in ipairs(modes) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = GetModeLabel(mode) .. " (" .. GetPreview(mode) .. ")"
        info.checked = (MyCopperViewerDB.mode == mode)
        info.func = function()
            MyCopperViewerDB.mode = mode
            RefreshDropdownText()
            Update()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end)

panel:SetScript("OnShow", function()
    showCheck:SetChecked(MyCopperViewerDB.show and true or false)
    RefreshDropdownText()
end)

InterfaceOptions_AddCategory(panel)

SLASH_MYCV1 = "/mcv"
SlashCmdList["MYCV"] = function(msg)
    msg = (msg or ""):lower()

    if msg == "config" then
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel)
        return
    end

    if msg:find("x") then
        local val = tonumber(msg:match("%-?%d+"))
        if val then
            MyCopperViewerDB.x = val
        end
    elseif msg:find("y") then
        local val = tonumber(msg:match("%-?%d+"))
        if val then
            MyCopperViewerDB.y = val
        end
    end

    ApplyPosition()
    Update()
end

ApplyPosition()
RefreshDropdownText()
Update()