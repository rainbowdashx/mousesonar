_G.CreateFrame("Frame"):SetScript("OnUpdate", function(self, elapsed)

    if IsMouselooking() then
        if not mouseSonarOpt.doNotHideOnMouseLook then
        AddHideCondition("Mouselook");
        end
    else
        RemoveHideCondition("Mouselook");
    end

    ON_UPDATE();
end)

BINDING_HEADER_MOUSESONAR = "Mouse Sonar";
BINDING_NAME_FINDMOUSE = "Find Mouse";

local g_mouseSonarOptPanel = {};
local g_activeHideConditions = {};
local g_combat = false;
local g_circleInitialized = false;
local g_mouseHistory = {};
local g_mouseHistoryMaxSize = 30;
local g_lastHistoryUpdateTime = 0;
local category, layout

local g_circle = CreateFrame("Model", nil, self);
g_circle:SetWidth(0);
g_circle:SetHeight(0);
g_circle:Show();
local g_texture = g_circle:CreateTexture(nil, "BACKGROUND");
g_texture:SetTexture("Interface\\AddOns\\mousesonar\\Circle_White");
g_texture:SetVertexColor(1, 1, 1, 1);
g_texture:SetAllPoints(g_circle);
g_texture:SetVertexColor(1, 1, 1);

local PULSE_LIFE_TIME = 0.5; -- seconds
local g_totalElapsed = -1;

local function SquareInvertFunc(elapsedTime, startingValue)
    local temp = elapsedTime / PULSE_LIFE_TIME;
    local value = 1.0 - (temp * temp);
    return value * startingValue;
end

local function UpdatePulse(elapsed)

    if g_totalElapsed == -1 then
        return;
    elseif g_totalElapsed > PULSE_LIFE_TIME then
        g_totalElapsed = -1;
        g_circle:Hide();
        return;
    end

    local alpha = SquareInvertFunc(g_totalElapsed,
                                   mouseSonarOpt.startingAlphaValue);
    g_texture:SetAlpha(alpha);

    local pulseSizeThisFrame = SquareInvertFunc(g_totalElapsed,
                                                mouseSonarOpt.pulseSize);
    g_circle:SetWidth(pulseSizeThisFrame);
    g_circle:SetHeight(pulseSizeThisFrame);

    local cursorX, cursorY = GetCursorPosition();
    g_circle:SetPoint("BOTTOMLEFT", cursorX - (pulseSizeThisFrame * 0.5),
                      cursorY - (pulseSizeThisFrame * 0.5));

    g_totalElapsed = g_totalElapsed + elapsed;
end

local function UpdateAlwaysVisible()

    if not g_circleInitialized then

        g_circle:SetWidth(mouseSonarOpt.pulseSize);
        g_circle:SetHeight(mouseSonarOpt.pulseSize);
        g_texture:SetAlpha(mouseSonarOpt.startingAlphaValue);

        g_circleInitialized = true;
    end

    -- TOGGLE VISIBLE
    local combatOK = not mouseSonarOpt.onlyCombat or g_combat;
    local raidOK = not mouseSonarOpt.onlyRaid or isInRaidOrParty();
    local canBeShown = combatOK and raidOK;

    local isCurrentlyVisible = g_circle:IsVisible();

    if not isCurrentlyVisible and canBeShown then
        g_circle:Show();
    elseif isCurrentlyVisible and not canBeShown then
        g_circle:Hide();
    end

    local cursorX, cursorY = GetCursorPosition();
    g_circle:SetPoint("BOTTOMLEFT", cursorX - (mouseSonarOpt.pulseSize * 0.5),
                      cursorY - (mouseSonarOpt.pulseSize * 0.5));
end

local function removeOldEntries()

    local timeNow = GetTime();
    local timeThreshold = timeNow - 0.5;

    local lastEntry = nil;
    for i, entry in ipairs(g_mouseHistory) do
        if entry.time < timeThreshold then
            table.remove(g_mouseHistory, i);
        end
    end

end

local function pushHistoryEntry()
    local cursorX, cursorY = GetCursorPosition();

    local entry = {x = cursorX, y = cursorY, time = GetTime()};

    table.insert(g_mouseHistory, entry);

    if #g_mouseHistory > g_mouseHistoryMaxSize then
        table.remove(g_mouseHistory, 1);
    end

    g_lastHistoryEntryTime = GetTime();

    removeOldEntries();
end

local function checkIfMouseShake()

    local numChanges = 0;
    local timeNow = GetTime();
    local timeThreshold = timeNow - 0.5;
    local lastDirection = nil;
    local lastEntry = nil;

    for i, entry in ipairs(g_mouseHistory) do

        if lastEntry ~= nil then

            local dx = entry.x - lastEntry.x
            local dy = entry.y - lastEntry.y
            local distance = math.sqrt(dx * dx + dy * dy)

            local direction
            if dx > 0 then
                direction = "right"
            elseif dx < 0 then
                direction = "left"
            elseif dy > 0 then
                direction = "down"
            elseif dy < 0 then
                direction = "up"
            else
                direction = "none"
            end

            if distance > mouseSonarOpt.mouseShakeThreshold and
                (lastDirection == nil or lastDirection ~= direction) then
                numChanges = numChanges + 1;
            end
            lastDirection = direction
        end
        lastEntry = entry;
    end

    if numChanges > 2 then return true; end
    return false;
end

local function onUpdate(self, elapsed)

    if mouseSonarOpt.deactivated then return; end

    if mouseSonarOpt.alwaysVisible then
        UpdateAlwaysVisible();
    else
        UpdatePulse(elapsed);
    end
end

local function refreshPulseColor()
    g_texture:SetVertexColor(mouseSonarOpt.colorValue[1],
                             mouseSonarOpt.colorValue[2],
                             mouseSonarOpt.colorValue[3])
end

local mouseSonar = CreateFrame("frame");
mouseSonar:SetScript("OnEvent",
                     function(self, event, ...) self[event](self, ...); end);
g_circle:SetScript("OnUpdate", onUpdate);
mouseSonar:RegisterEvent("ADDON_LOADED");
mouseSonar:RegisterEvent("CINEMATIC_START");
mouseSonar:RegisterEvent("CINEMATIC_STOP");
mouseSonar:RegisterEvent("SCREENSHOT_FAILED");
mouseSonar:RegisterEvent("SCREENSHOT_SUCCEEDED");
mouseSonar:RegisterEvent("PLAYER_REGEN_DISABLED");
mouseSonar:RegisterEvent("PLAYER_REGEN_ENABLED");

function mouseSonar:ADDON_LOADED(addon, ...)
    if addon == "mousesonar" then
        mouseSonarOpt = {
            deactivated = (mouseSonarOpt ~= nil and mouseSonarOpt.deactivated) or
                (mouseSonarOpt == nil and false),
            alwaysVisible = (mouseSonarOpt ~= nil and
                mouseSonarOpt.alwaysVisible) or (mouseSonarOpt == nil and false),
            pulseSize = (mouseSonarOpt ~= nil and mouseSonarOpt.pulseSize) or
                256,
            startingAlphaValue = (mouseSonarOpt ~= nil and
                mouseSonarOpt.startingAlphaValue) or 1,
            onlyCombat = (mouseSonarOpt ~= nil and mouseSonarOpt.onlyCombat) or
                (mouseSonarOpt == nil and true),
            onlyRaid = (mouseSonarOpt ~= nil and mouseSonarOpt.onlyRaid) or
                (mouseSonarOpt == nil and false),
            onMouselook = (mouseSonarOpt ~= nil and mouseSonarOpt.onMouselook) or
                (mouseSonarOpt == nil and true),
            colorValue = (mouseSonarOpt ~= nil and mouseSonarOpt.colorValue) or
                {1, 1, 1},
            HollowCircle = (mouseSonarOpt ~= nil and mouseSonarOpt.HollowCircle) or
                (mouseSonarOpt == nil and false),
            mouseShakeDetection = (mouseSonarOpt ~= nil and
                mouseSonarOpt.mouseShakeDetection) or
                (mouseSonarOpt == nil and false),
            mouseShakeThreshold = (mouseSonarOpt ~= nil and
                mouseSonarOpt.mouseShakeThreshold) or 300,
            doNotHideOnMouseLook = (mouseSonarOpt ~= nil and
                mouseSonarOpt.doNotHideOnMouseLook) or
                (mouseSonarOpt == nil and false)
        }
        UpdatePulseTexture();
        createOptions();
        refreshPulseColor();
        ToggleAlwaysVisible();
    end
end

function mouseSonar:SCREENSHOT_FAILED() RemoveHideCondition("Screenshot"); end

function mouseSonar:PLAYER_REGEN_ENABLED(...) g_combat = false; end

function mouseSonar:PLAYER_REGEN_DISABLED(...)
    g_combat = true;
    ToggleAlwaysVisible();
end

mouseSonar.SCREENSHOT_SUCCEEDED = mouseSonar.SCREENSHOT_FAILED;

function mouseSonar:CINEMATIC_START() AddHideCondition("Cinematic"); end

function mouseSonar:CINEMATIC_STOP() RemoveHideCondition("Cinematic"); end

function ON_UPDATE() -- script on update
    if mouseSonarOpt.mouseShakeDetection then
        if g_lastHistoryUpdateTime == nil or GetTime() - g_lastHistoryUpdateTime >
            0.1 then
            pushHistoryEntry();
            if checkIfMouseShake() then ShowCircle(); end
            g_lastHistoryUpdateTime = GetTime();
        end
    end
end

-- Hide during screenshots
_G.hooksecurefunc("Screenshot", function() AddHideCondition("Screenshot"); end);

-- Hide while FMV movies play
_G.MovieFrame:HookScript("OnShow", function()
    AddHideCondition("Movie") -- FMV movie sequence, like the Wrathgate cinematic
end);

_G.MovieFrame:HookScript("OnHide", function() RemoveHideCondition("Movie"); end);

-- Hook camera movement to hide cursor effects
_G.hooksecurefunc("CameraOrSelectOrMoveStart", function()
    if mouseSonarOpt.doNotHideOnMouseLook then return; end
    AddHideCondition("Camera");
end);

_G.hooksecurefunc("CameraOrSelectOrMoveStop",
                  function() RemoveHideCondition("Camera"); end);

function AddHideCondition(conditionName)
    if not g_activeHideConditions[conditionName] then
        g_activeHideConditions[conditionName] = true;
        g_circle:Hide();
    end
end

function RemoveHideCondition(conditionName)
    if g_activeHideConditions[conditionName] then
        g_activeHideConditions[conditionName] = nil;

        if next(g_activeHideConditions) == nil and mouseSonarOpt.onMouselook then
            ShowCircle();
        end
    end
end

function ShowCircle(bypass)
    if (g_combat or not mouseSonarOpt.onlyCombat) and
        (isInRaidOrParty() or not mouseSonarOpt.onlyRaid) or bypass then

        g_totalElapsed = 0;
        g_circleInitialized = false;
        g_circle:Show();
    end
end

function ToggleAlwaysVisible()

    if mouseSonarOpt.alwaysVisible and not mouseSonarOpt.deactivated and
        (not mouseSonarOpt.onlyCombat or g_combat) and
        (not mouseSonarOpt.onlyRaid or isInRaidOrParty()) then
        ShowCircle();
        return true;
    end

    return false;
end

SlashCmdList["PULSE"] = function() ShowCircle(1) end;
SLASH_PULSE1 = "/pulse";

-- OPTIONS

local function createLabel(name)
    local label = g_mouseSonarOptPanel.panel:CreateFontString(nil, "ARTWORK",
                                                              "GameFontHighlight");
    label:SetText(name);
    return label;
end
local function createCheck(key, wth, hgt)
    local chkOpt = CreateFrame("CheckButton", "mousesonar_" .. key,
                               g_mouseSonarOptPanel.panel,
                               "InterfaceOptionsCheckButtonTemplate");
    chkOpt:SetWidth(wth);
    chkOpt:SetHeight(hgt);
    return chkOpt;
end
local function createSlider(name, x, y, min, max, step)
    local sliderOpt = CreateFrame("Slider", "mousesonar_" .. name,
                                  g_mouseSonarOptPanel.panel,
                                  "OptionsSliderTemplate");
    sliderOpt:SetWidth(x);
    sliderOpt:SetHeight(y);
    sliderOpt:SetMinMaxValues(min, max);
    sliderOpt:SetValueStep(step);
    _G[sliderOpt:GetName() .. "Low"]:SetText(min);
    _G[sliderOpt:GetName() .. "High"]:SetText(max);
    _G[sliderOpt:GetName() .. "Text"]:SetText(name);
    return sliderOpt;
end

local function showColorPicker(r, g, b, a, callback)

    local info = {}
    info.r, info.g, info.b = r, g, b
    info.opacity = a
    info.hasOpacity = false
    info.swatchFunc = function()
        local _r, _g, _b = ColorPickerFrame:GetColorRGB()
        local _a = 1;
        mouseSonarOpt.colorValue[1], mouseSonarOpt.colorValue[2], mouseSonarOpt.colorValue[3] =
            _r, _g, _b;
        refreshPulseColor();
        callback(_r, _g, _b, _a);
    end

    info.cancelFunc = function()
        local _r, _g, _b = ColorPickerFrame.previousValues.r,
                           ColorPickerFrame.previousValues.g,
                           ColorPickerFrame.previousValues.b;
        local _a = 1;
        mouseSonarOpt.colorValue[1], mouseSonarOpt.colorValue[2], mouseSonarOpt.colorValue[3] =
            _r, _g, _b;
        refreshPulseColor();
        callback(_r, _g, _b, _a);
    end
    ColorPickerFrame:SetupColorPickerAndShow(info)

end

local function createColorSelect(name, ...)
    -- frame
    local f = CreateFrame("FRAME", "mousesonar_" .. name,
                          g_mouseSonarOptPanel.panel);
    f:SetSize(25, 25);
    f:SetPoint("CENTER", 0, 0);

    -- texture
    f.tex = f:CreateTexture(nil, "BACKGROUND");
    f.tex:SetAllPoints(f);
    f.tex:SetColorTexture(mouseSonarOpt.colorValue[1],
                          mouseSonarOpt.colorValue[2],
                          mouseSonarOpt.colorValue[3], 1);

    -- recolor callback function
    f.recolorTexture = function(r, g, b, a)
        local _r, _g, _b, _a = r, g, b, a;
        f.tex:SetColorTexture(_r, _g, _b, _a);
    end

    f:EnableMouse(true)
    f:SetScript("OnMouseDown", function(self, button, ...)
        if button == "LeftButton" then
            local r, g, b = mouseSonarOpt.colorValue[1],
                            mouseSonarOpt.colorValue[2],
                            mouseSonarOpt.colorValue[3];
            showColorPicker(r, g, b, 1, self.recolorTexture);
        end
    end)

    return f
end

function UpdatePulseTexture()
    if mouseSonarOpt.HollowCircle then
        g_texture:SetTexture("Interface\\AddOns\\mousesonar\\Circle_Hollow");
    else
        g_texture:SetTexture("Interface\\AddOns\\mousesonar\\Circle_White");
    end
end

function createOptions()
    g_mouseSonarOptPanel.panel = CreateFrame("Frame", "Mouse Sonar Options",
                                             UIParent);
    g_mouseSonarOptPanel.panel.name = "Mouse Sonar Options";

    local local_x = 60;
    local local_y = -45;

    local chk_margin_x = 20;
    local chk_margin_y = -3;

    local margin_y = 20;

    -- DEACTIVATED
    g_mouseSonarOptPanel.lab = createLabel("Deactivated");
    g_mouseSonarOptPanel.lab:SetPoint("TOPLEFT", local_x + chk_margin_x,
                                      local_y + chk_margin_y);
    g_mouseSonarOptPanel.chk = createCheck("chkDeactivate", 20, 20);
    g_mouseSonarOptPanel.chk:SetPoint("TOPLEFT", local_x, local_y);
    g_mouseSonarOptPanel.chk:SetChecked(mouseSonarOpt.deactivated);

    g_mouseSonarOptPanel.chk:SetScript("OnClick", function()
        mouseSonarOpt.deactivated = not mouseSonarOpt.deactivated;

        if not ToggleAlwaysVisible() then g_circle:Hide(); end
    end);

    local_y = local_y - margin_y;

    -- ALWAYS VISIBLE
    g_mouseSonarOptPanel.lab = createLabel("Circle always visible");
    g_mouseSonarOptPanel.lab:SetPoint("TOPLEFT", local_x + chk_margin_x,
                                      local_y + chk_margin_y);
    g_mouseSonarOptPanel.chk = createCheck("chkAlwaysVisible", 20, 20);
    g_mouseSonarOptPanel.chk:SetPoint("TOPLEFT", local_x, local_y);
    g_mouseSonarOptPanel.chk:SetChecked(mouseSonarOpt.alwaysVisible);

    g_mouseSonarOptPanel.chk:SetScript("OnClick", function()
        mouseSonarOpt.alwaysVisible = not mouseSonarOpt.alwaysVisible;
        ToggleAlwaysVisible();
    end);

    local_y = local_y - margin_y;

    -- DO NOT HIDE ON MOUSELOOK
    g_mouseSonarOptPanel.lab = createLabel("Do not hide on Mouselook");
    g_mouseSonarOptPanel.lab:SetPoint("TOPLEFT", local_x + chk_margin_x,
                                      local_y + chk_margin_y);
    g_mouseSonarOptPanel.chk = createCheck("chkDoNotHideOnMouseLook", 20, 20);
    g_mouseSonarOptPanel.chk:SetPoint("TOPLEFT", local_x, local_y);
    g_mouseSonarOptPanel.chk:SetChecked(mouseSonarOpt.doNotHideOnMouseLook);

    g_mouseSonarOptPanel.chk:SetScript("OnClick", function()
        mouseSonarOpt.doNotHideOnMouseLook =
            not mouseSonarOpt.doNotHideOnMouseLook;
    end);

    local_y = local_y - margin_y;

    -- ONLY IN COMBAT
    g_mouseSonarOptPanel.lab = createLabel("Show only in Combat");
    g_mouseSonarOptPanel.lab:SetPoint("TOPLEFT", local_x + chk_margin_x,
                                      local_y + chk_margin_y);
    g_mouseSonarOptPanel.chk = createCheck("chkOnlyInCombat", 20, 20);
    g_mouseSonarOptPanel.chk:SetPoint("TOPLEFT", local_x, local_y);
    g_mouseSonarOptPanel.chk:SetChecked(mouseSonarOpt.onlyCombat);

    g_mouseSonarOptPanel.chk:SetScript("OnClick", function()
        mouseSonarOpt.onlyCombat = not mouseSonarOpt.onlyCombat;
        ToggleAlwaysVisible();
    end)

    local_y = local_y - margin_y;

    -- ONLY IN RAID
    g_mouseSonarOptPanel.lab = createLabel(
                                   "Show only while in raid group or a party with more 5 or more people");
    g_mouseSonarOptPanel.lab:SetPoint("TOPLEFT", local_x + chk_margin_x,
                                      local_y + chk_margin_y);
    g_mouseSonarOptPanel.chk = createCheck("chkOnlyInRaid", 20, 20);
    g_mouseSonarOptPanel.chk:SetPoint("TOPLEFT", local_x, local_y);
    g_mouseSonarOptPanel.chk:SetChecked(mouseSonarOpt.onlyRaid);

    g_mouseSonarOptPanel.chk:SetScript("OnClick", function()
        mouseSonarOpt.onlyRaid = not mouseSonarOpt.onlyRaid;
        ToggleAlwaysVisible();
    end)

    local_y = local_y - margin_y;

    -- MOUSE LOOK END
    g_mouseSonarOptPanel.lab = createLabel("Show on Mouselook end");
    g_mouseSonarOptPanel.lab:SetPoint("TOPLEFT", local_x + chk_margin_x,
                                      local_y + chk_margin_y);
    g_mouseSonarOptPanel.chk = createCheck("chkMouselook", 20, 20);
    g_mouseSonarOptPanel.chk:SetPoint("TOPLEFT", local_x, local_y);
    g_mouseSonarOptPanel.chk:SetChecked(mouseSonarOpt.onMouselook);

    g_mouseSonarOptPanel.chk:SetScript("OnClick", function()
        mouseSonarOpt.onMouselook = not mouseSonarOpt.onMouselook;
    end);

    local_y = local_y - margin_y;

    -- MOUSE SHAKE DETECTION
    g_mouseSonarOptPanel.lab = createLabel("Mouse Shake Detection");
    g_mouseSonarOptPanel.lab:SetPoint("TOPLEFT", local_x + chk_margin_x,
                                      local_y + chk_margin_y);
    g_mouseSonarOptPanel.chk = createCheck("chkMouseShake", 20, 20);
    g_mouseSonarOptPanel.chk:SetPoint("TOPLEFT", local_x, local_y);
    g_mouseSonarOptPanel.chk:SetChecked(mouseSonarOpt.mouseShakeDetection);

    g_mouseSonarOptPanel.chk:SetScript("OnClick", function()
        mouseSonarOpt.mouseShakeDetection =
            not mouseSonarOpt.mouseShakeDetection;
    end);

    local_y = local_y - margin_y;

    -- HOLLOW CIRCLE OPTION
    g_mouseSonarOptPanel.lab = createLabel("Show as Hollow Circle");
    g_mouseSonarOptPanel.lab:SetPoint("TOPLEFT", local_x + chk_margin_x,
                                      local_y + chk_margin_y);
    g_mouseSonarOptPanel.chk = createCheck("chkHollowCircle", 20, 20);
    g_mouseSonarOptPanel.chk:SetPoint("TOPLEFT", local_x, local_y);
    g_mouseSonarOptPanel.chk:SetChecked(mouseSonarOpt.HollowCircle);

    g_mouseSonarOptPanel.chk:SetScript("OnClick", function()
        mouseSonarOpt.HollowCircle = not mouseSonarOpt.HollowCircle;
        UpdatePulseTexture();
    end);

    local_y = local_y - (margin_y * 2)

    -- PULSE SIZE
    g_mouseSonarOptPanel.slider = createSlider("Pulse Size", 140, 15, 16, 1024,
                                               32);
    g_mouseSonarOptPanel.slider:SetValue(mouseSonarOpt.pulseSize);
    g_mouseSonarOptPanel.slider:SetPoint("TOPLEFT", local_x, local_y);

    g_mouseSonarOptPanel.slider:SetScript("OnValueChanged",
                                          function(self, value)
        mouseSonarOpt.pulseSize = value;
        ShowCircle(1);
    end);

    local_y = local_y - (margin_y * 2)

    -- STARTING ALPHA VALUE
    g_mouseSonarOptPanel.slider = createSlider("Starting alpha value", 160, 15,
                                               0, 255, 1);
    g_mouseSonarOptPanel.slider:SetValue(mouseSonarOpt.startingAlphaValue * 255);
    g_mouseSonarOptPanel.slider:SetPoint("TOPLEFT", local_x, local_y);

    g_mouseSonarOptPanel.slider:SetScript("OnValueChanged",
                                          function(self, value)
        mouseSonarOpt.startingAlphaValue = value / 255;
        ShowCircle(1);
    end);

    local_y = local_y - (margin_y * 2)

    -- COLOR
    g_mouseSonarOptPanel.lab = createLabel("Color");
    g_mouseSonarOptPanel.lab:SetPoint("TOPLEFT", local_x + chk_margin_x * 2,
                                      local_y + chk_margin_y * 2);
    g_mouseSonarOptPanel.clr = createColorSelect("ColorSelect");
    g_mouseSonarOptPanel.clr:SetPoint("TOPLEFT", local_x, local_y);

    local_y = local_y - (margin_y * 3)

    -- MOUSE SHAKE threshold
    g_mouseSonarOptPanel.slider = createSlider("Mouse Shake Threshold", 160, 15,
                                               10, 1000, 1);
    g_mouseSonarOptPanel.slider:SetValue(mouseSonarOpt.mouseShakeThreshold);
    g_mouseSonarOptPanel.slider:SetPoint("TOPLEFT", local_x, local_y);

    g_mouseSonarOptPanel.slider:SetScript("OnValueChanged",
                                          function(self, value)
        mouseSonarOpt.mouseShakeThreshold = value;
    end);

    local_y = local_y - (margin_y * 3)

    g_mouseSonarOptPanel.helpText = createLabel(
                                        "You can Keybind or macro /pulse to Pulse Manually");
    g_mouseSonarOptPanel.helpText:SetPoint("TOPLEFT", local_x, local_y);

    category, layout = Settings.RegisterCanvasLayoutCategory(
                           g_mouseSonarOptPanel.panel,
                           g_mouseSonarOptPanel.panel.name,
                           g_mouseSonarOptPanel.panel.name);
    category.ID = g_mouseSonarOptPanel.panel.name
    Settings.RegisterAddOnCategory(category);

end

--[[
    local category = Settings.RegisterVerticalLayoutCategory("Mouse Sonar")

    local function OnSettingChanged(setting, value)
        print("Setting changed:", setting:GetVariable(), value)
    end

    g_mouseSonarOptPanel.lab = createLabel("Deactivated");
    g_mouseSonarOptPanel.lab:SetPoint("TOPLEFT", 80, -48);
    g_mouseSonarOptPanel.chk = createCheck("chkDeactivate", 20, 20);
    g_mouseSonarOptPanel.chk:SetPoint("TOPLEFT", 60, -45);
    g_mouseSonarOptPanel.chk:SetChecked(mouseSonarOpt.deactivated);

    g_mouseSonarOptPanel.chk:SetScript("OnClick", function()
        mouseSonarOpt.deactivated = not mouseSonarOpt.deactivated;

        if not ToggleAlwaysVisible() then g_circle:Hide(); end
    end);

do 
    local name = "Deactivated"
    local variable = "deactivated"
	local variableKey = "toggle"
	local variableTbl = MyAddOn_SavedVars
    local defaultValue = false

    local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
	setting:SetValueChangedCallback(OnSettingChanged)

    local tooltip = "Mouse Sonar is deactivated"
	Settings.CreateCheckbox(category, setting, tooltip)
end
]]

function isInRaidOrParty() return IsInRaid() or GetNumSubgroupMembers() > 4; end
