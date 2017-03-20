


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

local g_circle = CreateFrame("Model", nil, self);
g_circle:SetWidth(0);
g_circle:SetHeight(0);
g_circle:Show();
local g_texture = g_circle:CreateTexture(nil,"BACKGROUND");
g_texture:SetTexture("Interface\\AddOns\\mousesonar\\Circle_White");
g_texture:SetVertexColor(1, 1, 1 , 1);
g_texture:SetAllPoints(g_circle);

local PULSE_LIFE_TIME = 0.5; -- seconds
local g_totalElapsed = -1;

local function SquareInvertFunc(elapsedTime, startingValue)
	local temp = elapsedTime / PULSE_LIFE_TIME;
	local value = 1.0 - (temp * temp);
	return value * startingValue;
end

local function onUpdate(self,elapsed)

	if g_totalElapsed == -1 or mouseSonarOpt.deactivated then
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
				deactivated = (mouseSonarOpt ~= nil and mouseSonarOpt.deactivated) or false,
				pulseSize = (mouseSonarOpt ~= nil and mouseSonarOpt.pulseSize) or 256,
				startingAlphaValue = (mouseSonarOpt ~= nil and mouseSonarOpt.startingAlphaValue) or 1,
				onlyCombat = (mouseSonarOpt ~= nil and mouseSonarOpt.onlyCombat) or true,
				onlyRaid = (mouseSonarOpt ~= nil and mouseSonarOpt.onlyRaid) or false,
				onMouselook = (mouseSonarOpt ~= nil and mouseSonarOpt.onMouselook) or true,
        ConstantCircle = (mouseSonarOpt ~= nil and mouseSonarOpt.ConstantCircle) or false,
			}
		createOptions();
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
    if not mouseSonarOpt.ConstantCircle then
		  g_circle:Hide();
    end
	end
end


function RemoveHideCondition(conditionName)
	if g_activeHideConditions[conditionName] then
		g_activeHideConditions[conditionName] = nil;

		if next(g_activeHideConditions) == nil and mouseSonarOpt.onMouselook then
			goPulse();
		end
	end
end

function goPulse()
	if (g_combat or not mouseSonarOpt.onlyCombat) and (IsInRaid() or not mouseSonarOpt.onlyRaid) then
		g_totalElapsed = 0;
		g_circle:Show();
	end
end

SlashCmdList["PULSE"] = function() goPulse() end;
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
	return sliderOpt
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
	end);

--[[
--CONSTANT CHECK BOX
  g_mouseSonarOptPanel.lab = createLabel("Constant Circle")
  g_mouseSonarOptPanel.lab:SetPoint("TOPLEFT", 80, -208)
  g_mouseSonarOptPanel.chk = createCheck("chkConstantCircle", 20, 20)
  g_mouseSonarOptPanel.chk:SetPoint("TOPLEFT", 60, -205)
  if (mouseSonarOpt.ConstantCircle) then
    g_mouseSonarOptPanel.chk:SetChecked(true)
  end
  g_mouseSonarOptPanel.chk:SetScript("OnClick", function()
            if(mouseSonarOpt.ConstantCircle) then
              mouseSonarOpt.ConstantCircle = false
            else
              mouseSonarOpt.ConstantCircle = true
            end
          end)

]]

	-- ONLY IN COMBAT
	g_mouseSonarOptPanel.lab = createLabel("Show only in Combat");
	g_mouseSonarOptPanel.lab:SetPoint("TOPLEFT", 80, -68);
	g_mouseSonarOptPanel.chk = createCheck("chkOnlyInCombat", 20, 20);
	g_mouseSonarOptPanel.chk:SetPoint("TOPLEFT", 60, -65);
	g_mouseSonarOptPanel.chk:SetChecked(mouseSonarOpt.onlyCombat);

	g_mouseSonarOptPanel.chk:SetScript("OnClick", function()
		mouseSonarOpt.onlyCombat = not mouseSonarOpt.onlyCombat;
	end)

	-- ONLY IN RAID
	g_mouseSonarOptPanel.lab = createLabel("Show only while in raid group");
	g_mouseSonarOptPanel.lab:SetPoint("TOPLEFT", 80, -88);
	g_mouseSonarOptPanel.chk = createCheck("chkOnlyInRaid", 20, 20);
	g_mouseSonarOptPanel.chk:SetPoint("TOPLEFT", 60, -85);
	g_mouseSonarOptPanel.chk:SetChecked(mouseSonarOpt.onlyRaid);

	g_mouseSonarOptPanel.chk:SetScript("OnClick", function()
		mouseSonarOpt.onlyRaid = not mouseSonarOpt.onlyRaid;
	end)


	-- MOUSE LOOK END
	g_mouseSonarOptPanel.lab = createLabel("Show on Mouselook end");
	g_mouseSonarOptPanel.lab:SetPoint("TOPLEFT", 80, -108);
	g_mouseSonarOptPanel.chk = createCheck("chkMouselook", 20, 20);
	g_mouseSonarOptPanel.chk:SetPoint("TOPLEFT", 60, -105);
	g_mouseSonarOptPanel.chk:SetChecked(mouseSonarOpt.onMouselook);

	g_mouseSonarOptPanel.chk:SetScript("OnClick", function()
		mouseSonarOpt.onMouselook = not mouseSonarOpt.onMouselook;
	end);


	-- PULSE SIZE
	g_mouseSonarOptPanel.slider = createSlider("Pulse Size", 140, 15, 64, 1024, 32);
	g_mouseSonarOptPanel.slider:SetValue(mouseSonarOpt.pulseSize);
	g_mouseSonarOptPanel.slider:SetPoint("TOPLEFT", 60, -145);

	g_mouseSonarOptPanel.slider:SetScript("OnValueChanged", function(self, value)
		mouseSonarOpt.pulseSize = value;
		goPulse();
	end);

	-- STARTING ALPHA VALUE
	g_mouseSonarOptPanel.slider = createSlider("Starting alpha value", 160, 15, 0, 255, 1);
	g_mouseSonarOptPanel.slider:SetValue(mouseSonarOpt.startingAlphaValue * 255);
	g_mouseSonarOptPanel.slider:SetPoint("TOPLEFT", 60, -185);

	g_mouseSonarOptPanel.slider:SetScript("OnValueChanged", function(self, value)
		mouseSonarOpt.startingAlphaValue = value / 255;
		goPulse();
	end);


	g_mouseSonarOptPanel.helpText = createLabel("You can Keybind or macro /pulse to Pulse Manually");
	g_mouseSonarOptPanel.helpText:SetPoint("TOPLEFT", 60, -225);

	InterfaceOptions_AddCategory(g_mouseSonarOptPanel.panel);
end


