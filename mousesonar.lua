


_G.CreateFrame("Frame"):SetScript("OnUpdate", function(self, elapsed)

          if IsMouselooking() then
              AddHideCondition("Mouselook")
          else
              RemoveHideCondition("Mouselook")
          end
      
  end)

BINDING_HEADER_MOUSESONAR = "Mouse Sonar"
BINDING_NAME_MOUSESONAR = "Pulse"

local mouseSonarOptPanel = {}
local ActiveHideConditions = {}
local combate = false
local previousX,previousY,toggleHide = false

local model = CreateFrame("Model", nil, self)
model:SetWidth(256) 
model:SetHeight(256)
model:Show()
local t = model:CreateTexture(nil,"BACKGROUND")
--t:SetTexture(1,1,1,0.3)
t:SetTexture("Interface\\AddOns\\mousesonar\\Circle_White")
t:SetVertexColor(1, 1, 1 , 0.6)
t:SetAllPoints(model)



local UPDATE_INTERVAL = 0.0 --seconds
local TotalElapsed = 0

-- t = time ==  time elapsed
-- b = begin ==  //begin value
-- c = change == //ending value
-- d = duration == duration secs
local function outCirc(t, b, c, d)  return(c * math.sqrt(1 - math.pow((t / d) - 1, 2)) + b) end
local function inCirc(t, b, c, d) return(-c * (math.sqrt(1 - math.pow(t / d, 2)) - 1) + b) end

local endingTime=0
local duration =0 
local function onUpdate(self,elapsed)

    TotalElapsed = TotalElapsed + elapsed
    if TotalElapsed > 2 then
        TotalElapsed=0
        model:Hide()
    end
   -- if TotalElapsed >= UPDATE_INTERVAL thend
      --  TotalElapsed = 0
        local pulseSize = mouseSonarOpt.pulseSize

        local cursorX, cursorY = GetCursorPosition()
       

        if cursorX == previousX and cursorY == previousY then
           -- return
        end

         local pulse = outCirc(TotalElapsed,1,pulseSize,2)   
         t:SetVertexColor(1, 1, 1 , 1-outCirc(TotalElapsed,0,1,2))
        --local pulse = math.abs(math.sin(GetTime())) *128
        
        pulse=pulseSize-pulse
	       
        model:SetWidth(pulse) 
        model:SetHeight(pulse)
		    model:SetPoint("BOTTOMLEFT",(cursorX-pulse/2),cursorY-(pulse/2))
        				
        previousX = cursorX
        previousY = cursorY
    --end

end




local mouseSonar = CreateFrame("frame")
mouseSonar:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)
model:SetScript("OnUpdate", onUpdate)
mouseSonar:RegisterEvent("ADDON_LOADED");
mouseSonar:RegisterEvent("CINEMATIC_START")
mouseSonar:RegisterEvent("CINEMATIC_STOP")
mouseSonar:RegisterEvent("SCREENSHOT_FAILED")
mouseSonar:RegisterEvent("SCREENSHOT_SUCCEEDED")
mouseSonar:RegisterEvent("PLAYER_REGEN_DISABLED")
mouseSonar:RegisterEvent("PLAYER_REGEN_ENABLED")


function mouseSonar:ADDON_LOADED(addon,...)
  if addon == "mousesonar" then
    if mouseSonarOpt == nil then
      mouseSonarOpt = {}
      mouseSonarOpt.pulseSize = 256
      mouseSonarOpt.onlyCombat = true
      mouseSonarOpt.onMouselook = true
    end
    createOptions()
  end
end

function mouseSonar:SCREENSHOT_FAILED()
    RemoveHideCondition("Screenshot")
end

function mouseSonar:PLAYER_REGEN_ENABLED( ... )
  combate = false
end

function mouseSonar:PLAYER_REGEN_DISABLED( ... )
  combate = true
end

mouseSonar.SCREENSHOT_SUCCEEDED = mouseSonar.SCREENSHOT_FAILED


function mouseSonar:CINEMATIC_START()
    AddHideCondition("Cinematic")
end

function mouseSonar:CINEMATIC_STOP()
    RemoveHideCondition("Cinematic")
end

-- Hide during screenshots
_G.hooksecurefunc("Screenshot", function()
    AddHideCondition("Screenshot")
end)

-- Hide while FMV movies play
_G.MovieFrame:HookScript("OnShow", function()
    AddHideCondition("Movie") -- FMV movie sequence, like the Wrathgate cinematic
end)

_G.MovieFrame:HookScript("OnHide", function()
    RemoveHideCondition("Movie")
end)

-- Hook camera movement to hide cursor effects
_G.hooksecurefunc("CameraOrSelectOrMoveStart", function()
    AddHideCondition("Camera")
end)

_G.hooksecurefunc("CameraOrSelectOrMoveStop", function()
    RemoveHideCondition("Camera")
end)





    function AddHideCondition(conditionName)
        if not ActiveHideConditions[conditionName] then
            ActiveHideConditions[conditionName] = true
            model:Hide()
        end
    end

    function RemoveHideCondition(conditionName)
        if ActiveHideConditions[conditionName] then
            ActiveHideConditions[conditionName] = nil

            if next(ActiveHideConditions) == nil then
                TotalElapsed =0 

                if combate or not mouseSonarOpt.onlyCombat then
                  if mouseSonarOpt.onMouselook then 
                    model:Show()
                  end
                end
            end
        end
    end

    function goPulse()
      TotalElapsed =0 
      model:Show()
    end

SlashCmdList["PULSE"] = function() goPulse() end
SLASH_PULSE1="/pulse"


--OPTIONS

local function createLabel(frame, name)
  local label = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  label:SetText(name)
  return label
end
local function createCheck(frame, key, wth, hgt)
  local chkOpt = CreateFrame("CheckButton", "mousesonar" .. key, frame, "OptionsCheckButtonTemplate")
  chkOpt:SetWidth(wth)
  chkOpt:SetHeight(hgt)
  return chkOpt
end
local function createSlider(name, x, y, min, max, step,frame)
  local sliderOpt = CreateFrame("Slider", "mousesonar" .. name, frame, "OptionsSliderTemplate")
  sliderOpt:SetWidth(x)
  sliderOpt:SetHeight(y)
  sliderOpt:SetMinMaxValues(min, max)
  sliderOpt:SetValueStep(step)
  _G[sliderOpt:GetName() .. "Low"]:SetText('64')
  _G[sliderOpt:GetName() .. "High"]:SetText('1024')
  _G[sliderOpt:GetName() .. 'Text']:SetText('Pulse Size')
  return sliderOpt
end

function createOptions()
  mouseSonarOptPanel.panel = CreateFrame( "Frame", "Mouse Sonar Options", UIParent );
  mouseSonarOptPanel.panel.name = "Mouse Sonar Options";
  mouseSonarOptPanel.lab = createLabel(mouseSonarOptPanel.panel, "Show Only inCombat")
  mouseSonarOptPanel.lab:SetPoint("TOPLEFT", 80, -48)
  mouseSonarOptPanel.chk = createCheck(mouseSonarOptPanel.panel, "chkincombat", 20, 20)
  mouseSonarOptPanel.chk:SetPoint("TOPLEFT", 60, -45)
  if (mouseSonarOpt.onlyCombat) then
    mouseSonarOptPanel.chk:SetChecked(true)
  end
  mouseSonarOptPanel.chk:SetScript("OnClick", function()
            if(mouseSonarOpt.onlyCombat) then
              mouseSonarOpt.onlyCombat = false
            else
              mouseSonarOpt.onlyCombat = true
            end
          end)


  mouseSonarOptPanel.lab = createLabel(mouseSonarOptPanel.panel, "Show on Mouselook end")
  mouseSonarOptPanel.lab:SetPoint("TOPLEFT", 80, -88)
  mouseSonarOptPanel.chk = createCheck(mouseSonarOptPanel.panel, "chkMouselook", 20, 20)
  mouseSonarOptPanel.chk:SetPoint("TOPLEFT", 60, -85)
  if (mouseSonarOpt.onMouselook) then
    mouseSonarOptPanel.chk:SetChecked(true)
  end
  mouseSonarOptPanel.chk:SetScript("OnClick", function()
            if(mouseSonarOpt.onMouselook) then
              mouseSonarOpt.onMouselook = false
            else
              mouseSonarOpt.onMouselook = true
            end
          end)






  mouseSonarOptPanel.slider = createSlider("Pulse Size", 140, 15, 64, 1024, 32,mouseSonarOptPanel.panel)
  mouseSonarOptPanel.slider:SetValue(mouseSonarOpt.pulseSize)
  mouseSonarOptPanel.slider:SetPoint("TOPLEFT", 60, -125)
  mouseSonarOptPanel.slider:SetScript("OnValueChanged", function(self, value)
    mouseSonarOpt.pulseSize = value
    goPulse()
  end)



  
  mouseSonarOptPanel.helpText=createLabel(mouseSonarOptPanel.panel, "You can Keybind or macro /pulse to Pulse Manually")
  mouseSonarOptPanel.helpText:SetPoint("TOPLEFT", 60, -165)


  InterfaceOptions_AddCategory(mouseSonarOptPanel.panel);

  
end
 



 --[[
 -- Make a child panel
 mouseSonarOpt.childpanel = CreateFrame( "Frame", "mouseSonarOptChild", mouseSonarOpt.panel);
 mouseSonarOpt.childpanel.name = "MyChild";
 -- Specify childness of this panel (this puts it under the little red [+], instead of giving it a normal AddOn category)
 mouseSonarOpt.childpanel.parent = mouseSonarOpt.panel.name;
 -- Add the child to the Interface Options
 InterfaceOptions_AddCategory(mouseSonarOpt.childpanel);
 ]]