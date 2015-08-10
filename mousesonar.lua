



BINDING_HEADER_KARATE = "KARATE DRUCK"
BINDING_NAME_KARATE = "Call Karate Target"



_G.CreateFrame("Frame"):SetScript("OnUpdate", function(self, elapsed)

          if IsMouselooking() then
              AddHideCondition("Mouselook")
          else
              RemoveHideCondition("Mouselook")
          end
      
  end)

local ActiveHideConditions = {}
local combate = false
local   previousX,previousY,toggleHide = false
local model = CreateFrame("Model", nil, self)
model:SetWidth(128) 
model:SetHeight(128)
model:Show()

local t = model:CreateTexture(nil,"BACKGROUND")
--t:SetTexture(1,1,1,0.3)
t:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_White")
t:SetVertexColor(1, 1, 1 , 0.6)
t:SetAllPoints(model)


local UPDATE_INTERVAL = 0.0 --seconds
local TotalElapsed = 0

-- t = time ==  time elapsed
-- b = begin ==  //begin value
-- c = change == //ending value
-- d = duration == duration secs
local function outCirc(t, b, c, d)  return(c * math.sqrt(1 - math.pow((t / d) - 1, 2)) + b) end

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


        local cursorX, cursorY = GetCursorPosition()
       

        if cursorX == previousX and cursorY == previousY then
           -- return
        end

         local pulse = outCirc(TotalElapsed,1,128,2)   
         t:SetVertexColor(1, 1, 1 , 1-outCirc(TotalElapsed,0,1,2))
        --local pulse = math.abs(math.sin(GetTime())) *128
        
	       
        model:SetWidth(pulse) 
        model:SetHeight(pulse)
		    model:SetPoint("BOTTOMLEFT",(cursorX-pulse/2),cursorY-(pulse/2))
        				
        previousX = cursorX
        previousY = cursorY
    --end

end


local mouseSonar = CreateFrame("frame")
model:SetScript("OnUpdate", onUpdate)
mouseSonar:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)
mouseSonar:RegisterEvent("ADDON_LOADED");
mouseSonar:RegisterEvent("CINEMATIC_START")
mouseSonar:RegisterEvent("CINEMATIC_STOP")
mouseSonar:RegisterEvent("SCREENSHOT_FAILED")
mouseSonar:RegisterEvent("SCREENSHOT_SUCCEEDED")
mouseSonar:RegisterEvent("PLAYER_REGEN_DISABLED")
mouseSonar:RegisterEvent("PLAYER_REGEN_ENABLED")


function mouseSonar:ADDON_LOADED(...)

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
                if combate then
                  model:Show()
                end
            end
        end
    end


SlashCmdList["MDDEBUG"] = function() debugTest() end
SLASH_MDDEBUG1="/deb"



