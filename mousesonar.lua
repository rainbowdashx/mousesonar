


_G.CreateFrame("Frame"):SetScript("OnUpdate", function(self, elapsed)

	if IsMouselooking() then
		AddHideCondition("Mouselook");
	else
		RemoveHideCondition("Mouselook");
	end
end)

BINDING_HEADER_MOUSESONAR = "Mouse Sonar";
BINDING_NAME_MOUSESONAR = "Pulse";

local g_mouseSonarOptPanel = {};
local g_activeHideConditions = {};
local g_combat = false;
local g_circleInitialized = false;

local g_circle = CreateFrame("Model", nil, self);
g_circle:SetWidth(0);
g_circle:SetHeight(0);
g_circle:Show();
local g_texture = g_circle:CreateTexture(nil,"BACKGROUND");
g_texture:SetTexture("Interface\\AddOns\\mousesonar\\Circle_White");
g_texture:SetVertexColor(1, 1, 1 , 1);
g_texture:SetAllPoints(g_circle);
g_texture:SetVertexColor(1,1,1);

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


	local alpha = SquareInvertFunc(g_totalElapsed, mouseSonarOpt.startingAlphaValue);
	g_texture:SetAlpha(alpha);

	local pulseSizeThisFrame = SquareInvertFunc(g_totalElapsed, mouseSonarOpt.pulseSize);
	g_circle:SetWidth(pulseSizeThisFrame);
	g_circle:SetHeight(pulseSizeThisFrame);

	local cursorX, cursorY = GetCursorPosition();
	g_circle:SetPoint("BOTTOMLEFT", cursorX - (pulseSizeThisFrame * 0.5), cursorY - (pulseSizeThisFrame * 0.5));

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
	local raidOK = not mouseSonarOpt.onlyRaid or IsInRaid();
	local canBeShown = combatOK and raidOK;

	local isCurrentlyVisible = g_circle:IsVisible();

	if not isCurrentlyVisible and canBeShown then
		g_circle:Show();
	elseif isCurrentlyVisible and not canBeShown then
		g_circle:Hide();
	end


	local cursorX, cursorY = GetCursorPosition();
	g_circle:SetPoint("BOTTOMLEFT", cursorX - (mouseSonarOpt.pulseSize * 0.5), cursorY - (mouseSonarOpt.pulseSize * 0.5));
end

local function onUpdate(self, elapsed)

	if mouseSonarOpt.deactivated then
		return;
	end

	if mouseSonarOpt.alwaysVisible then
		UpdateAlwaysVisible();
	else
		UpdatePulse(elapsed);
	end
end


local function refreshPulseColor()
	g_texture:SetVertexColor(mouseSonarOpt.colorValue[1], mouseSonarOpt.colorValue[2], mouseSonarOpt.colorValue[3])
end


local mouseSonar = CreateFrame("frame");
mouseSonar:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...);
end);
g_circle:SetScript("OnUpdate", onUpdate);
mouseSonar:RegisterEvent("ADDON_LOADED");
mouseSonar:RegisterEvent("CINEMATIC_START");
mouseSonar:RegisterEvent("CINEMATIC_STOP");
mouseSonar:RegisterEvent("SCREENSHOT_FAILED");
mouseSonar:RegisterEvent("SCREENSHOT_SUCCEEDED");
mouseSonar:RegisterEvent("PLAYER_REGEN_DISABLED");
mouseSonar:RegisterEvent("PLAYER_REGEN_ENABLED");


function mouseSonar:ADDON_LOADED(addon,...)
	if addon == "mousesonar" then
		mouseSonarOpt =
			{
				deactivated = (mouseSonarOpt ~= nil and mouseSonarOpt.deactivated) or (mouseSonarOpt == nil and false),
				alwaysVisible = (mouseSonarOpt ~= nil and mouseSonarOpt.alwaysVisible) or (mouseSonarOpt == nil and false),
				pulseSize = (mouseSonarOpt ~= nil and mouseSonarOpt.pulseSize) or 256,
				startingAlphaValue = (mouseSonarOpt ~= nil and mouseSonarOpt.startingAlphaValue) or 1,
				onlyCombat = (mouseSonarOpt ~= nil and mouseSonarOpt.onlyCombat) or (mouseSonarOpt == nil and true),
				onlyRaid = (mouseSonarOpt ~= nil and mouseSonarOpt.onlyRaid) or (mouseSonarOpt == nil and false),
				onMouselook = (mouseSonarOpt ~= nil and mouseSonarOpt.onMouselook) or (mouseSonarOpt == nil and true),
				colorValue = (mouseSonarOpt ~= nil and mouseSonarOpt.colorValue) or {1,1,1},
			}
		createOptions();
		refreshPulseColor();
		ToggleAlwaysVisible();
	end
end

function mouseSonar:SCREENSHOT_FAILED()
	RemoveHideCondition("Screenshot");
end

function mouseSonar:PLAYER_REGEN_ENABLED( ... )
	g_combat = false;
end

function mouseSonar:PLAYER_REGEN_DISABLED( ... )
	g_combat = true;
	ToggleAlwaysVisible();
end

mouseSonar.SCREENSHOT_SUCCEEDED = mouseSonar.SCREENSHOT_FAILED;


function mouseSonar:CINEMATIC_START()
	AddHideCondition("Cinematic");
end

function mouseSonar:CINEMATIC_STOP()
	RemoveHideCondition("Cinematic");
end

-- Hide during screenshots
_G.hooksecurefunc("Screenshot", function()
	AddHideCondition("Screenshot");
end);

-- Hide while FMV movies play
_G.MovieFrame:HookScript("OnShow", function()
	AddHideCondition("Movie") -- FMV movie sequence, like the Wrathgate cinematic
end);

_G.MovieFrame:HookScript("OnHide", function()
	RemoveHideCondition("Movie");
end);

-- Hook camera movement to hide cursor effects
_G.hooksecurefunc("CameraOrSelectOrMoveStart", function()
	AddHideCondition("Camera");
end);

_G.hooksecurefunc("CameraOrSelectOrMoveStop", function()
	RemoveHideCondition("Camera");
end);



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
	if (g_combat or not mouseSonarOpt.onlyCombat) and (IsInRaid() or not mouseSonarOpt.onlyRaid) or bypass then

		g_totalElapsed = 0;
		g_circleInitialized = false;
		g_circle:Show();
	end
end

function ToggleAlwaysVisible()

	if mouseSonarOpt.alwaysVisible and not mouseSonarOpt.deactivated and (not mouseSonarOpt.onlyCombat or g_combat) and (not mouseSonarOpt.onlyRaid or IsInRaid()) then
		ShowCircle();
		return true;
	end

	return false;
end

SlashCmdList["PULSE"] = function() ShowCircle(1) end;
SLASH_PULSE1 = "/pulse";


--OPTIONS

local function createLabel(name)
	local label = g_mouseSonarOptPanel.panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
	label:SetText(name);
	return label;
end
local function createCheck(key, wth, hgt)
	local chkOpt = CreateFrame("CheckButton", "mousesonar_" .. key, g_mouseSonarOptPanel.panel, "OptionsCheckButtonTemplate");
	chkOpt:SetWidth(wth);
	chkOpt:SetHeight(hgt);
	return chkOpt;
end
local function createSlider(name, x, y, min, max, step)
	local sliderOpt = CreateFrame("Slider", "mousesonar_" .. name, g_mouseSonarOptPanel.panel, "OptionsSliderTemplate");
	sliderOpt:SetWidth(x);
	sliderOpt:SetHeight(y);
	sliderOpt:SetMinMaxValues(min, max);
	sliderOpt:SetValueStep(step);
	_G[sliderOpt:GetName() .. "Low"]:SetText(min);
	_G[sliderOpt:GetName() .. "High"]:SetText(max);
	_G[sliderOpt:GetName() .. "Text"]:SetText(name);
	return sliderOpt;
end

local function showColorPicker(r,g,b,a,callback)
	ColorPickerFrame:SetColorRGB(r,g,b);
	ColorPickerFrame.hasOpacity = false;
	ColorPickerFrame.opacity = (a ~= nil), a;
	ColorPickerFrame.previousValues = {r,g,b,a};
	ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = callback, callback, callback;
	ColorPickerFrame:Hide(); -- Need to run the OnShow handler.
	ColorPickerFrame:Show();
end


local function createColorSelect(name,...)
	--frame
	local f = CreateFrame("FRAME","mousesonar_" .. name,g_mouseSonarOptPanel.panel);
	f:SetSize(25,25);
	f:SetPoint("CENTER",0,0);

	--texture
	f.tex = f:CreateTexture(nil,"BACKGROUND");
	f.tex:SetAllPoints(f);
	f.tex:SetColorTexture(mouseSonarOpt.colorValue[1], mouseSonarOpt.colorValue[2], mouseSonarOpt.colorValue[3], 1);

	--recolor callback function
	f.recolorTexture = function(oldColor)
		local r,g,b,a;
		if not oldColor then
			r,g,b = ColorPickerFrame:GetColorRGB();
			a = 1;
			f.tex:SetColorTexture(r,g,b,a);
			mouseSonarOpt.colorValue[1], mouseSonarOpt.colorValue[2], mouseSonarOpt.colorValue[3] = r,g,b;
			refreshPulseColor();
		else
			f.tex:SetColorTexture(mouseSonarOpt.colorValue[1], mouseSonarOpt.colorValue[2], mouseSonarOpt.colorValue[3], 1);
		end
	end

	f:EnableMouse(true)
	f:SetScript("OnMouseDown", function(self,button,...)
		if button == "LeftButton" then
			local r,g,b = mouseSonarOpt.colorValue[1], mouseSonarOpt.colorValue[2], mouseSonarOpt.colorValue[3];
			showColorPicker(r,g,b,1,self.recolorTexture);
		end
	end)

	return f
end

function createOptions()
	g_mouseSonarOptPanel.panel = CreateFrame( "Frame", "Mouse Sonar Options", UIParent);
	g_mouseSonarOptPanel.panel.name = "Mouse Sonar Options";


	-- DEACTIVATED
	g_mouseSonarOptPanel.lab = createLabel("Deactivated");
	g_mouseSonarOptPanel.lab:SetPoint("TOPLEFT", 80, -48);
	g_mouseSonarOptPanel.chk = createCheck("chkDeactivate", 20, 20);
	g_mouseSonarOptPanel.chk:SetPoint("TOPLEFT", 60, -45);
	g_mouseSonarOptPanel.chk:SetChecked(mouseSonarOpt.deactivated);

	g_mouseSonarOptPanel.chk:SetScript("OnClick", function()
		mouseSonarOpt.deactivated = not mouseSonarOpt.deactivated;

		if not ToggleAlwaysVisible() then
			g_circle:Hide();
		end
	end);


	-- ALWAYS VISIBLE
	g_mouseSonarOptPanel.lab = createLabel("Circle always visible");
	g_mouseSonarOptPanel.lab:SetPoint("TOPLEFT", 80, -68);
	g_mouseSonarOptPanel.chk = createCheck("chkAlwaysVisible", 20, 20);
	g_mouseSonarOptPanel.chk:SetPoint("TOPLEFT", 60, -65);
	g_mouseSonarOptPanel.chk:SetChecked(mouseSonarOpt.alwaysVisible);

	g_mouseSonarOptPanel.chk:SetScript("OnClick", function()
		mouseSonarOpt.alwaysVisible = not mouseSonarOpt.alwaysVisible;
		ToggleAlwaysVisible();
	end);

	-- ONLY IN COMBAT
	g_mouseSonarOptPanel.lab = createLabel("Show only in Combat");
	g_mouseSonarOptPanel.lab:SetPoint("TOPLEFT", 80, -88);
	g_mouseSonarOptPanel.chk = createCheck("chkOnlyInCombat", 20, 20);
	g_mouseSonarOptPanel.chk:SetPoint("TOPLEFT", 60, -85);
	g_mouseSonarOptPanel.chk:SetChecked(mouseSonarOpt.onlyCombat);

	g_mouseSonarOptPanel.chk:SetScript("OnClick", function()
		mouseSonarOpt.onlyCombat = not mouseSonarOpt.onlyCombat;
		ToggleAlwaysVisible();
	end)

	-- ONLY IN RAID
	g_mouseSonarOptPanel.lab = createLabel("Show only while in raid group");
	g_mouseSonarOptPanel.lab:SetPoint("TOPLEFT", 80, -108);
	g_mouseSonarOptPanel.chk = createCheck("chkOnlyInRaid", 20, 20);
	g_mouseSonarOptPanel.chk:SetPoint("TOPLEFT", 60, -105);
	g_mouseSonarOptPanel.chk:SetChecked(mouseSonarOpt.onlyRaid);

	g_mouseSonarOptPanel.chk:SetScript("OnClick", function()
		mouseSonarOpt.onlyRaid = not mouseSonarOpt.onlyRaid;
		ToggleAlwaysVisible();
	end)


	-- MOUSE LOOK END
	g_mouseSonarOptPanel.lab = createLabel("Show on Mouselook end");
	g_mouseSonarOptPanel.lab:SetPoint("TOPLEFT", 80, -128);
	g_mouseSonarOptPanel.chk = createCheck("chkMouselook", 20, 20);
	g_mouseSonarOptPanel.chk:SetPoint("TOPLEFT", 60, -125);
	g_mouseSonarOptPanel.chk:SetChecked(mouseSonarOpt.onMouselook);

	g_mouseSonarOptPanel.chk:SetScript("OnClick", function()
		mouseSonarOpt.onMouselook = not mouseSonarOpt.onMouselook;
	end);


	-- PULSE SIZE
	g_mouseSonarOptPanel.slider = createSlider("Pulse Size", 140, 15, 64, 1024, 32);
	g_mouseSonarOptPanel.slider:SetValue(mouseSonarOpt.pulseSize);
	g_mouseSonarOptPanel.slider:SetPoint("TOPLEFT", 60, -165);

	g_mouseSonarOptPanel.slider:SetScript("OnValueChanged", function(self, value)
		mouseSonarOpt.pulseSize = value;
		ShowCircle();
	end);


	-- STARTING ALPHA VALUE
	g_mouseSonarOptPanel.slider = createSlider("Starting alpha value", 160, 15, 0, 255, 1);
	g_mouseSonarOptPanel.slider:SetValue(mouseSonarOpt.startingAlphaValue * 255);
	g_mouseSonarOptPanel.slider:SetPoint("TOPLEFT", 60, -205);

	g_mouseSonarOptPanel.slider:SetScript("OnValueChanged", function(self, value)
		mouseSonarOpt.startingAlphaValue = value / 255;
		ShowCircle();
	end);


	-- COLOR
	g_mouseSonarOptPanel.lab = createLabel("Color");
	g_mouseSonarOptPanel.lab:SetPoint("TOPLEFT", 90, -255);
	g_mouseSonarOptPanel.clr = createColorSelect("ColorSelect");
	g_mouseSonarOptPanel.clr:SetPoint("TOPLEFT", 60, -245);


	g_mouseSonarOptPanel.helpText = createLabel("You can Keybind or macro /pulse to Pulse Manually");
	g_mouseSonarOptPanel.helpText:SetPoint("TOPLEFT", 60, -285);

	InterfaceOptions_AddCategory(g_mouseSonarOptPanel.panel);
end
