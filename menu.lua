-- Client-Side Lua Executor - XYZ Menu System
local menuDui = nil
local isMenuOpen = false
local menuState = 'menu' -- menu, colorpicker, positionpicker
local positionMode = nil -- menu, spectator
local menuLevel = 0  -- 0 = main menu, 1+ = submenus

-- JSON encode helper
function json.encode(t)
    -- Simple JSON encoder for basic needs
    if type(t) == "table" then
        local result = "{"
        local first = true
        for k, v in pairs(t) do
            if not first then result = result .. "," end
            first = false
            if type(v) == "string" then
                result = result .. '"' .. k .. '":"' .. v .. '"'
            elseif type(v) == "number" or type(v) == "boolean" then
                result = result .. '"' .. k .. '":' .. tostring(v)
            end
        end
        return result .. "}"
    else
        return tostring(t)
    end
end

-- Create menu
function CreateMenu()
    if menuDui == nil then
        -- Use GitHub Pages hosted version
        menuDui = MachoCreateDui("https://arresmr.github.io/xyzmenu/")
        
        Citizen.Wait(800)
        
        -- Inject banner load fallback
        MachoInjectJavaScript([[
            const bannerImg = document.getElementById('bannerImage');
            if (bannerImg) {
                bannerImg.src = 'https://raw.githubusercontent.com/arresmr/xyzmenu/refs/heads/main/banner/banner%20bwhitle.png';
                bannerImg.onerror = function() {
                    this.style.background = 'linear-gradient(90deg, #8a2be2 0%, #4b0082 100%)';
                    this.style.backgroundSize = 'cover';
                    this.src = '';
                };
            }
        ]])
    end
end

-- Show menu
function ShowMenu()
    if menuDui == nil then
        CreateMenu()
    end
    
    MachoShowDui(menuDui)
    isMenuOpen = true
    menuState = 'menu'
    menuLevel = 0  -- Reset to main menu level
    SetNuiFocus(false, false) -- No NUI focus needed, all input via Lua
end

-- Hide menu
function HideMenu()
    if menuDui then
        MachoHideDui(menuDui)
        isMenuOpen = false
        menuState = 'menu'
        menuLevel = 0  -- Reset level
        SetNuiFocus(false, false)
        
        -- Send close message to reset any open modals
        MachoSendDuiMessage(menuDui, json.encode({action = "close"}))
    end
end

-- Toggle menu
function ToggleMenu()
    if isMenuOpen then
        HideMenu()
    else
        ShowMenu()
    end
end

-- Navigation functions based on state
function NavigateUp()
    if menuDui and isMenuOpen then
        MachoSendDuiMessage(menuDui, json.encode({
            action = "navigate", 
            direction = "up"
        }))
    end
end

function NavigateDown()
    if menuDui and isMenuOpen then
        MachoSendDuiMessage(menuDui, json.encode({
            action = "navigate", 
            direction = "down"
        }))
    end
end

function NavigateLeft()
    if menuDui and isMenuOpen then
        MachoSendDuiMessage(menuDui, json.encode({
            action = "navigate", 
            direction = "left"
        }))
    end
end

function NavigateRight()
    if menuDui and isMenuOpen then
        MachoSendDuiMessage(menuDui, json.encode({
            action = "navigate", 
            direction = "right"
        }))
    end
end

function SelectItem()
    if menuDui and isMenuOpen then
        MachoSendDuiMessage(menuDui, json.encode({action = "select"}))
        -- Increase level when entering submenu
        menuLevel = menuLevel + 1
    end
end

function GoBack()
    if menuDui and isMenuOpen then
        if menuLevel > 0 then
            -- Go back in menu
            MachoSendDuiMessage(menuDui, json.encode({action = "back"}))
            menuLevel = menuLevel - 1
        else
            -- At main menu - close menu
            HideMenu()
        end
        
        -- Reset state when backing out of modals
        if menuState ~= 'menu' then
            menuState = 'menu'
        end
    end
end

-- Main input handler thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if isMenuOpen then
            -- Arrow Up
            if IsControlPressed(0, 172) then
                NavigateUp()
                Citizen.Wait(75)
            end
            
            -- Arrow Down
            if IsControlPressed(0, 173) then
                NavigateDown()
                Citizen.Wait(75)
            end
            
            -- Arrow Left
            if IsControlPressed(0, 174) then
                NavigateLeft()
                Citizen.Wait(75)
            end
            
            -- Arrow Right
            if IsControlPressed(0, 175) then
                NavigateRight()
                Citizen.Wait(75)
            end
            
            -- Enter
            if IsControlJustPressed(0, 176) then
                SelectItem()
            end
            
            -- Backspace
            if IsControlJustPressed(0, 177) then
                GoBack()
            end
            
        else
            -- F5 to open menu
            if IsControlJustPressed(0, 166) then
                ToggleMenu()
            end
        end
    end
end)

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if menuDui then
            MachoDestroyDui(menuDui)
            menuDui = nil
        end
    end
end)

-- Initialize
Citizen.CreateThread(function()
    Citizen.Wait(1000)
    CreateMenu()
    print("^2[XYZ Menu]^7 System loaded! Press ^3F5^7 to toggle menu")
    print("^2[XYZ Menu]^7 Use ^3Arrow Keys^7 to navigate, ^3Enter^7 to select, ^3Backspace^7 to go back")
end)

-- Utility functions for external use (simplified)
function SetMenuColor(r, g, b, a)
    if menuDui then
        MachoSendDuiMessage(menuDui, json.encode({
            action = "updateColor", 
            r = r, 
            g = g, 
            b = b, 
            a = a or 1
        }))
    end
end

function UpdateBanner(imageUrl)
    if menuDui then
        MachoSendDuiMessage(menuDui, json.encode({
            action = "updateBanner", 
            url = imageUrl
        }))
    end
end
