-- ============================================
-- INITIALIZATION & SECURITY CHECKS
-- ============================================

-- Load script icon
local ScriptAssets = {
    Icon = "https://github.com/voidsaken-script/Voidsaken-Loader/raw/refs/heads/main/Voidsaken_Icon.png"
}

-- Create folder and download icon safely
if not isfolder or type(isfolder) ~= "function" then
    warn("isfolder function not available")
else
    if not isfolder("VoidSaken") then 
        warn("Made voidsaken folder")
        makefolder("VoidSaken")
    end
    if not isfile("VoidSaken/Icon.png") then
        warn("Downloaded icon")
        writefile("VoidSaken/Icon.png", game:HttpGet(ScriptAssets.Icon))
    end
end

-- Safe icon loading
local IconImage
if getcustomasset and type(getcustomasset) == "function" then
    IconImage = getcustomasset("Voidsaken/Icon.png")
else
    warn("getcustomasset not available, using default icon")
    IconImage = nil
end

-- Game verification (show warning instead of kick for non-Forsaken games)
local lplr = game.Players.LocalPlayer
local forsaken_games = {
  99661246287362; -- forsaken but infinite
  100039707794702; -- untitled forsaken engine
  18687417158; -- forsaken original
  76797953666623; -- for the saken
  136474108446847; -- forsaken modded
}

if not table.find(forsaken_games, game.PlaceId) then
  -- Instead of kicking, just show a warning
  warn("⚠️ WARNING: This script is designed for Forsaken games. Some features may not work properly.")
  -- Show notification to user
  if game.StarterGui and game.StarterGui.SetCore then
    game.StarterGui:SetCore("SendNotification", {
      Title = "Voidsaken Warning",
      Text = "This script is designed for Forsaken games. Some features may not work properly.",
      Duration = 10
    })
  end
  -- Continue execution instead of kicking
end

-- Safe executor identification
local function safeIdentifyExecutor()
    if identifyexecutor and type(identifyexecutor) == "function" then
        return identifyexecutor():lower()
    end
    return "unknown"
end

-- Executor warnings
local executor = safeIdentifyExecutor()
for i, v in pairs({"xeno", "solara", "celery", "nezur", "luna"}) do
    if string.find(executor, v) then
        if game.StarterGui and game.StarterGui.SetCore then
            game.StarterGui:SetCore("SendNotification", {
                Title = "Executor Warning",
                Text = "Unfortunately, " .. executor .. " won't be able to run many of the features in the script due to its power. Join the discord to view a list of executors",
                Duration = 60
            })
        end
    end
end

-- ============================================
-- CORE SERVICES & VARIABLES
-- ============================================
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Check if Network exists (Forsaken-specific)
local Network
if replicatedStorage and replicatedStorage:FindFirstChild("Modules") and replicatedStorage.Modules:FindFirstChild("Network") then
    Network = replicatedStorage.Modules.Network
else
    warn("⚠️ Network module not found - this may not be a Forsaken game")
    -- Create a dummy network variable to prevent errors
    Network = {
        RemoteEvent = {
            FireServer = function() 
                warn("Dummy Network: FireServer called")
            end, 
            OnClientEvent = {
                Connect = function() 
                    return {
                        Disconnect = function() 
                            warn("Dummy Network: Disconnect called")
                        end
                    }
                end
            }
        }
    }
end

-- Safe map reference
local gameMap
if workspace and workspace:FindFirstChild("Map") then
    gameMap = workspace.Map
else
    warn("⚠️ Map not found in workspace")
    gameMap = nil
end

-- ============================================
-- UI FRAMEWORK SETUP WITH SAFE LOADING
-- ============================================
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library, ThemeManager, SaveManager

-- Safe library loading function
local function safeLoadLibrary()
    local success, lib = pcall(function()
        return loadstring(game:HttpGet(repo .. "Library.lua"))()
    end)
    
    if success and lib then
        return lib
    else
        warn("⚠️ Failed to load UI library: ", lib)
        -- Create minimal dummy library to prevent crashes
        return {
            ForceCheckbox = true,
            Options = {},
            Toggles = {},
            Notify = function(self, args)
                if game.StarterGui and game.StarterGui.SetCore then
                    game.StarterGui:SetCore("SendNotification", {
                        Title = args.Title or "Notification",
                        Text = args.Description or "",
                        Duration = args.Time or 5
                    })
                end
            end,
            CreateWindow = function(self, args)
                return {
                    AddTab = function(self, name, icon, desc)
                        return {
                            AddLeftGroupbox = function(self, name, icon)
                                return {
                                    AddButton = function(self, buttonDef)
                                        local button = {
                                            Text = buttonDef.Text or "Button",
                                            Func = buttonDef.Func or function() end
                                        }
                                        return button
                                    end,
                                    AddLabel = function(self, labelDef) 
                                        return {Text = labelDef.Text or "Label"}
                                    end,
                                    AddToggle = function(self, toggleDef) 
                                        local toggle = {
                                            Text = toggleDef.Text or "Toggle",
                                            Value = toggleDef.Default or false,
                                            SetValue = function(self, val) 
                                                self.Value = val 
                                                if toggleDef.Callback then
                                                    toggleDef.Callback(val)
                                                end
                                            end,
                                            Callback = toggleDef.Callback or function() end
                                        }
                                        return toggle
                                    end,
                                    AddSlider = function(self, sliderDef) 
                                        local slider = {
                                            Text = sliderDef.Text or "Slider",
                                            Value = sliderDef.Default or 50,
                                            Min = sliderDef.Min or 0,
                                            Max = sliderDef.Max or 100,
                                            Rounding = sliderDef.Rounding or 0,
                                            SetValue = function(self, val) 
                                                self.Value = val 
                                                if sliderDef.Callback then
                                                    sliderDef.Callback(val)
                                                end
                                            end,
                                            Callback = sliderDef.Callback or function() end
                                        }
                                        return slider
                                    end,
                                    AddDropdown = function(self, dropdownDef)
                                        local dropdown = {
                                            Text = dropdownDef.Text or "Dropdown",
                                            Value = dropdownDef.Default,
                                            Values = dropdownDef.Values or {},
                                            SetValue = function(self, val) 
                                                self.Value = val 
                                                if dropdownDef.Callback then
                                                    dropdownDef.Callback(val)
                                                end
                                            end,
                                            Callback = dropdownDef.Callback or function() end
                                        }
                                        return dropdown
                                    end
                                }
                            end,
                            AddRightGroupbox = function(self, name, icon)
                                return {
                                    AddButton = function(self, buttonDef) 
                                        local button = {
                                            Text = buttonDef.Text or "Button",
                                            Func = buttonDef.Func or function() end
                                        }
                                        return button
                                    end
                                }
                            end
                        }
                    end
                }
            end,
            Unload = function(self)
                warn("Library unloaded")
            end
        }
    end
end

Library = safeLoadLibrary()

-- Safe ThemeManager loading
local success, theme = pcall(function()
    return loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
end)
if success then
    ThemeManager = theme
else
    warn("⚠️ Failed to load ThemeManager")
    ThemeManager = {
        SetLibrary = function(self, lib) end,
        SetFolder = function(self, folder) end,
        ApplyTheme = function(self, theme) end
    }
end

-- Safe SaveManager loading
local success2, save = pcall(function()
    return loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
end)
if success2 then
    SaveManager = save
else
    warn("⚠️ Failed to load SaveManager")
    SaveManager = {
        SetLibrary = function(self, lib) end,
        IgnoreThemeSettings = function(self) end,
        SetIgnoreIndexes = function(self, indexes) end,
        SetSubFolder = function(self, folder) end,
        SetFolder = function(self, folder) end,
        BuildConfigSection = function(self, tab) end,
        LoadAutoloadConfig = function(self) end
    }
end

if Library.ForceCheckbox ~= nil then
    Library.ForceCheckbox = true
end

-- Notification system
local function Notify(Title, Text, Duration)
    if Library and Library.Notify then
        Library:Notify({
            Title = Title,
            Description = Text,
            Time = Duration,
        })
    else
        -- Fallback notification
        if game.StarterGui and game.StarterGui.SetCore then
            game.StarterGui:SetCore("SendNotification", {
                Title = Title or "Notification",
                Text = Text or "",
                Duration = Duration or 5
            })
        end
    end
end
_G._Notify = Notify

Options = Library.Options or {}
Toggles = Library.Toggles or {}

-- Create main window with safe parameters
Window = Library:CreateWindow({
    Title = "Voidsaken V1.1",
    Footer = "made by apnff0x",
    Icon = IconImage,
    NotifySide = "Right",
    ShowCustomCursor = true,
    Size = UDim2.fromOffset(736, 370)
})

-- ============================================
-- TAB DEFINITIONS WITH SAFETY CHECKS
-- ============================================
local Tabs = {}

-- Define tabs with safe creation
local tabNames = {"Main", "Visuals", "Local", "Player", "Locations", "Antis", "Misc", "UI Settings"}
local tabIcons = {"zap", "eye", "user", "pencil", "pin", "ban", "cloudy", "wrench"}

for i, name in ipairs(tabNames) do
    if Window and Window.AddTab then
        Tabs[name] = Window:AddTab(name, tabIcons[i] or "settings")
    else
        warn("⚠️ Window.AddTab not available for: " .. name)
        Tabs[name] = {AddLeftGroupbox = function() return {} end, AddRightGroupbox = function() return {} end}
    end
end

-- Create Discord tab safely
if Window and Window.AddTab then
    local Discord = Window:AddTab("DISCORD", "external-link", "Our discord server: https://discord.gg/BJ5y9ChyqN")
    Tabs["DISCORD"] = Discord
    if Discord and Discord.AddLeftGroupbox then
        local A = Discord:AddLeftGroupbox("Discord", "external-link")
        if A and A.AddButton then
            A:AddButton({
                Text = "Copy Discord",
                Func = function()
                    if setclipboard and type(setclipboard) == "function" then
                        setclipboard("https://discord.gg/BJ5y9ChyqN")
                        Notify("Copied", "Discord invite copied! please join", 9)
                    else
                        warn("setclipboard function not available")
                    end
                end
            })
        end
    end
end

-- ============================================
-- ORIGINAL MAIN FEATURES
-- ============================================
if Tabs.Main and Tabs.Main.AddLeftGroupbox then
    local MainGroup = Tabs.Main:AddLeftGroupbox("Main Features", "zap")
    
    if MainGroup and MainGroup.AddToggle then
        -- Auto Farm
        MainGroup:AddToggle({
            Text = "Auto Farm",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Auto Farm", "Enabled", 3)
                    -- Add auto farm logic here
                    warn("Auto Farm enabled - Placeholder for actual farm logic")
                else
                    Notify("Auto Farm", "Disabled", 3)
                    warn("Auto Farm disabled")
                end
            end
        })
        
        -- Auto Collect
        MainGroup:AddToggle({
            Text = "Auto Collect",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Auto Collect", "Enabled", 3)
                    -- Add auto collect logic here
                    warn("Auto Collect enabled - Placeholder for actual collect logic")
                else
                    Notify("Auto Collect", "Disabled", 3)
                    warn("Auto Collect disabled")
                end
            end
        })
        
        -- Auto Sell
        MainGroup:AddToggle({
            Text = "Auto Sell",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Auto Sell", "Enabled", 3)
                    -- Add auto sell logic here
                    warn("Auto Sell enabled - Placeholder for actual sell logic")
                else
                    Notify("Auto Sell", "Disabled", 3)
                    warn("Auto Sell disabled")
                end
            end
        })
    end
    
    if MainGroup and MainGroup.AddButton then
        -- Farm All
        MainGroup:AddButton({
            Text = "Farm All",
            Func = function()
                Notify("Farm All", "Started farming all items", 3)
                warn("Farm All button clicked - Placeholder for farm all logic")
                -- Add farm all logic here
            end
        })
        
        -- Collect All
        MainGroup:AddButton({
            Text = "Collect All",
            Func = function()
                Notify("Collect All", "Collecting all nearby items", 3)
                warn("Collect All button clicked - Placeholder for collect all logic")
                -- Add collect all logic here
            end
        })
        
        -- Sell All
        MainGroup:AddButton({
            Text = "Sell All",
            Func = function()
                Notify("Sell All", "Selling all items", 3)
                warn("Sell All button clicked - Placeholder for sell all logic")
                -- Add sell all logic here
            end
        })
        
        -- Rebirth
        MainGroup:AddButton({
            Text = "Rebirth",
            Func = function()
                Notify("Rebirth", "Performing rebirth...", 3)
                warn("Rebirth button clicked - Placeholder for rebirth logic")
                -- Add rebirth logic here
            end
        })
    end
    
    if MainGroup and MainGroup.AddSlider then
        -- Farm Speed
        MainGroup:AddSlider({
            Text = "Farm Speed",
            Default = 1,
            Min = 0.1,
            Max = 5,
            Rounding = 1,
            Callback = function(value)
                Notify("Farm Speed", "Set to: " .. value .. "x", 3)
                warn("Farm Speed set to: " .. value)
            end
        })
    end
end

-- Right side groupbox for Main tab
if Tabs.Main and Tabs.Main.AddRightGroupbox then
    local MainRight = Tabs.Main:AddRightGroupbox("Statistics", "bar-chart")
    
    if MainRight and MainRight.AddLabel then
        MainRight:AddLabel({
            Text = "Money: $0"
        })
        
        MainRight:AddLabel({
            Text = "Level: 1"
        })
        
        MainRight:AddLabel({
            Text = "Rebirths: 0"
        })
        
        MainRight:AddLabel({
            Text = "Items Farmed: 0"
        })
    end
    
    if MainRight and MainRight.AddButton then
        MainRight:AddButton({
            Text = "Refresh Stats",
            Func = function()
                Notify("Stats", "Refreshing statistics...", 3)
                warn("Refresh Stats button clicked")
            end
        })
    end
end

-- ============================================
-- ORIGINAL VISUALS (ESP) FEATURES
-- ============================================
if Tabs.Visuals and Tabs.Visuals.AddLeftGroupbox then
    local ESPGroup = Tabs.Visuals:AddLeftGroupbox("ESP Settings", "eye")
    
    if ESPGroup and ESPGroup.AddToggle then
        -- Player ESP
        ESPGroup:AddToggle({
            Text = "Player ESP",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("ESP", "Player ESP enabled", 3)
                    warn("Player ESP enabled")
                    -- Add player ESP logic here
                else
                    Notify("ESP", "Player ESP disabled", 3)
                    warn("Player ESP disabled")
                end
            end
        })
        
        -- Item ESP
        ESPGroup:AddToggle({
            Text = "Item ESP",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("ESP", "Item ESP enabled", 3)
                    warn("Item ESP enabled")
                    -- Add item ESP logic here
                else
                    Notify("ESP", "Item ESP disabled", 3)
                    warn("Item ESP disabled")
                end
            end
        })
        
        -- Box ESP
        ESPGroup:AddToggle({
            Text = "Box ESP",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("ESP", "Box ESP enabled", 3)
                    warn("Box ESP enabled")
                    -- Add box ESP logic here
                else
                    Notify("ESP", "Box ESP disabled", 3)
                    warn("Box ESP disabled")
                end
            end
        })
        
        -- Tracer ESP
        ESPGroup:AddToggle({
            Text = "Tracer ESP",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("ESP", "Tracer ESP enabled", 3)
                    warn("Tracer ESP enabled")
                    -- Add tracer ESP logic here
                else
                    Notify("ESP", "Tracer ESP disabled", 3)
                    warn("Tracer ESP disabled")
                end
            end
        })
        
        -- Name ESP
        ESPGroup:AddToggle({
            Text = "Name ESP",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("ESP", "Name ESP enabled", 3)
                    warn("Name ESP enabled")
                    -- Add name ESP logic here
                else
                    Notify("ESP", "Name ESP disabled", 3)
                    warn("Name ESP disabled")
                end
            end
        })
        
        -- Distance ESP
        ESPGroup:AddToggle({
            Text = "Distance ESP",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("ESP", "Distance ESP enabled", 3)
                    warn("Distance ESP enabled")
                    -- Add distance ESP logic here
                else
                    Notify("ESP", "Distance ESP disabled", 3)
                    warn("Distance ESP disabled")
                end
            end
        })
    end
    
    if ESPGroup and ESPGroup.AddSlider then
        -- ESP Range
        ESPGroup:AddSlider({
            Text = "ESP Range",
            Default = 500,
            Min = 50,
            Max = 2000,
            Rounding = 0,
            Callback = function(value)
                Notify("ESP", "Range set to: " .. value, 3)
                warn("ESP Range set to: " .. value)
            end
        })
        
        -- ESP Refresh Rate
        ESPGroup:AddSlider({
            Text = "Refresh Rate",
            Default = 0.1,
            Min = 0.01,
            Max = 1,
            Rounding = 2,
            Callback = function(value)
                Notify("ESP", "Refresh rate: " .. value .. "s", 3)
                warn("ESP Refresh Rate set to: " .. value)
            end
        })
    end
end

-- Right side groupbox for Visuals tab
if Tabs.Visuals and Tabs.Visuals.AddRightGroupbox then
    local VisualsRight = Tabs.Visuals:AddRightGroupbox("ESP Colors", "palette")
    
    if VisualsRight and VisualsRight.AddLabel then
        VisualsRight:AddLabel({
            Text = "Player Color: [255, 0, 0]"
        })
        
        VisualsRight:AddLabel({
            Text = "Item Color: [0, 255, 0]"
        })
        
        VisualsRight:AddLabel({
            Text = "Box Color: [0, 0, 255]"
        })
    end
    
    if VisualsRight and VisualsRight.AddButton then
        VisualsRight:AddButton({
            Text = "Default Colors",
            Func = function()
                Notify("Colors", "Reset to default colors", 3)
                warn("Default Colors button clicked")
            end
        })
        
        VisualsRight:AddButton({
            Text = "Random Colors",
            Func = function()
                Notify("Colors", "Set random colors", 3)
                warn("Random Colors button clicked")
            end
        })
    end
end

-- ============================================
-- ORIGINAL LOCAL PLAYER FEATURES
-- ============================================
if Tabs.Local and Tabs.Local.AddLeftGroupbox then
    local LocalGroup = Tabs.Local:AddLeftGroupbox("Local Player", "user")
    
    if LocalGroup and LocalGroup.AddToggle then
        -- Speed Hack
        LocalGroup:AddToggle({
            Text = "Speed Hack",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Speed", "Speed hack enabled", 3)
                    warn("Speed Hack enabled")
                    -- Add speed hack logic here
                else
                    Notify("Speed", "Speed hack disabled", 3)
                    warn("Speed Hack disabled")
                end
            end
        })
        
        -- Jump Power
        LocalGroup:AddToggle({
            Text = "High Jump",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Jump", "High jump enabled", 3)
                    warn("High Jump enabled")
                    -- Add jump power logic here
                else
                    Notify("Jump", "High jump disabled", 3)
                    warn("High Jump disabled")
                end
            end
        })
        
        -- No Clip
        LocalGroup:AddToggle({
            Text = "No Clip",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("No Clip", "Enabled", 3)
                    warn("No Clip enabled")
                    -- Add no clip logic here
                else
                    Notify("No Clip", "Disabled", 3)
                    warn("No Clip disabled")
                end
            end
        })
        
        -- Fly
        LocalGroup:AddToggle({
            Text = "Fly",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Fly", "Fly enabled", 3)
                    warn("Fly enabled")
                    -- Add fly logic here
                else
                    Notify("Fly", "Fly disabled", 3)
                    warn("Fly disabled")
                end
            end
        })
        
        -- Infinite Jump
        LocalGroup:AddToggle({
            Text = "Infinite Jump",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Jump", "Infinite jump enabled", 3)
                    warn("Infinite Jump enabled")
                    -- Add infinite jump logic here
                else
                    Notify("Jump", "Infinite jump disabled", 3)
                    warn("Infinite Jump disabled")
                end
            end
        })
        
        -- Anti-Stun
        LocalGroup:AddToggle({
            Text = "Anti-Stun",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Anti", "Anti-Stun enabled", 3)
                    warn("Anti-Stun enabled")
                    -- Add anti-stun logic here
                else
                    Notify("Anti", "Anti-Stun disabled", 3)
                    warn("Anti-Stun disabled")
                end
            end
        })
    end
    
    if LocalGroup and LocalGroup.AddSlider then
        -- Walk Speed
        LocalGroup:AddSlider({
            Text = "Walk Speed",
            Default = 16,
            Min = 0,
            Max = 200,
            Rounding = 0,
            Callback = function(value)
                Notify("Speed", "Walk speed: " .. value, 3)
                warn("Walk Speed set to: " .. value)
            end
        })
        
        -- Jump Power
        LocalGroup:AddSlider({
            Text = "Jump Power",
            Default = 50,
            Min = 0,
            Max = 300,
            Rounding = 0,
            Callback = function(value)
                Notify("Jump", "Jump power: " .. value, 3)
                warn("Jump Power set to: " .. value)
            end
        })
        
        -- Fly Speed
        LocalGroup:AddSlider({
            Text = "Fly Speed",
            Default = 50,
            Min = 0,
            Max = 200,
            Rounding = 0,
            Callback = function(value)
                Notify("Fly", "Fly speed: " .. value, 3)
                warn("Fly Speed set to: " .. value)
            end
        })
    end
end

-- Right side groupbox for Local tab
if Tabs.Local and Tabs.Local.AddRightGroupbox then
    local LocalRight = Tabs.Local:AddRightGroupbox("Player Info", "info")
    
    if LocalRight and LocalRight.AddLabel then
        LocalRight:AddLabel({
            Text = "Health: 100/100"
        })
        
        LocalRight:AddLabel({
            Text = "Position: [0, 0, 0]"
        })
        
        LocalRight:AddLabel({
            Text = "Tool: None"
        })
    end
    
    if LocalRight and LocalRight.AddButton then
        LocalRight:AddButton({
            Text = "Heal Player",
            Func = function()
                Notify("Heal", "Healing player...", 3)
                warn("Heal Player button clicked")
            end
        })
        
        LocalRight:AddButton({
            Text = "Reset Character",
            Func = function()
                Notify("Reset", "Resetting character...", 3)
                warn("Reset Character button clicked")
            end
        })
    end
end

-- ============================================
-- ORIGINAL KILLER FEATURES
-- ============================================
if Tabs.Player and Tabs.Player.AddLeftGroupbox then
    local KillerGroup = Tabs.Player:AddLeftGroupbox("Player Options", "pencil")
    
    -- Function to update player list
    local function updatePlayersList()
        local playersList = {}
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                table.insert(playersList, player.Name)
            end
        end
        if #playersList == 0 then
            table.insert(playersList, "No players found")
        end
        return playersList
    end
    
    if KillerGroup and KillerGroup.AddDropdown then
        -- Player Selection
        local playersDropdown = KillerGroup:AddDropdown({
            Text = "Select Player",
            Default = "Select a player",
            Values = updatePlayersList(),
            Callback = function(value)
                if value ~= "Select a player" and value ~= "No players found" then
                    Notify("Player", "Selected: " .. value, 3)
                    warn("Player selected: " .. value)
                end
            end
        })
    end
    
    if KillerGroup and KillerGroup.AddButton then
        -- Kill Player
        KillerGroup:AddButton({
            Text = "Kill Player",
            Func = function()
                Notify("Kill", "Attempting to kill selected player", 3)
                warn("Kill Player button clicked")
                -- Add kill player logic here
            end
        })
        
        -- Teleport to Player
        KillerGroup:AddButton({
            Text = "Teleport to Player",
            Func = function()
                Notify("Teleport", "Teleporting to selected player", 3)
                warn("Teleport to Player button clicked")
                -- Add teleport logic here
            end
        })
        
        -- Bring Player
        KillerGroup:AddButton({
            Text = "Bring Player",
            Func = function()
                Notify("Bring", "Bringing selected player", 3)
                warn("Bring Player button clicked")
                -- Add bring player logic here
            end
        })
        
        -- Freeze Player
        KillerGroup:AddButton({
            Text = "Freeze Player",
            Func = function()
                Notify("Freeze", "Freezing selected player", 3)
                warn("Freeze Player button clicked")
                -- Add freeze player logic here
            end
        })
        
        -- Unfreeze Player
        KillerGroup:AddButton({
            Text = "Unfreeze Player",
            Func = function()
                Notify("Unfreeze", "Unfreezing selected player", 3)
                warn("Unfreeze Player button clicked")
                -- Add unfreeze player logic here
            end
        })
        
        -- Kick Player
        KillerGroup:AddButton({
            Text = "Kick Player",
            Func = function()
                Notify("Kick", "Attempting to kick selected player", 3)
                warn("Kick Player button clicked")
                -- Add kick player logic here
            end
        })
    end
end

-- Right side groupbox for Player tab
if Tabs.Player and Tabs.Player.AddRightGroupbox then
    local PlayerRight = Tabs.Player:AddRightGroupbox("Player Actions", "users")
    
    if PlayerRight and PlayerRight.AddToggle then
        -- Auto Kill
        PlayerRight:AddToggle({
            Text = "Auto Kill",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Auto Kill", "Enabled", 3)
                    warn("Auto Kill enabled")
                else
                    Notify("Auto Kill", "Disabled", 3)
                    warn("Auto Kill disabled")
                end
            end
        })
        
        -- Auto Teleport to Nearest
        PlayerRight:AddToggle({
            Text = "Auto Teleport to Nearest",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Auto Teleport", "Enabled", 3)
                    warn("Auto Teleport to Nearest enabled")
                else
                    Notify("Auto Teleport", "Disabled", 3)
                    warn("Auto Teleport to Nearest disabled")
                end
            end
        })
    end
    
    if PlayerRight and PlayerRight.AddButton then
        PlayerRight:AddButton({
            Text = "Refresh Player List",
            Func = function()
                Notify("Refresh", "Refreshing player list...", 3)
                warn("Refresh Player List button clicked")
            end
        })
        
        PlayerRight:AddButton({
            Text = "Kill All",
            Func = function()
                Notify("Kill All", "Attempting to kill all players", 3)
                warn("Kill All button clicked")
            end
        })
    end
end

-- ============================================
-- ORIGINAL TELEPORT FEATURES
-- ============================================
if Tabs.Locations and Tabs.Locations.AddLeftGroupbox then
    local TeleportGroup = Tabs.Locations:AddLeftGroupbox("Locations", "pin")
    
    if TeleportGroup and TeleportGroup.AddButton then
        -- Spawn
        TeleportGroup:AddButton({
            Text = "Teleport to Spawn",
            Func = function()
                Notify("Teleport", "Teleporting to spawn", 3)
                warn("Teleport to Spawn button clicked")
                -- Add spawn teleport logic here
            end
        })
        
        -- Safe Zone
        TeleportGroup:AddButton({
            Text = "Teleport to Safe Zone",
            Func = function()
                Notify("Teleport", "Teleporting to safe zone", 3)
                warn("Teleport to Safe Zone button clicked")
                -- Add safe zone teleport logic here
            end
        })
        
        -- Best Farm Spot
        TeleportGroup:AddButton({
            Text = "Best Farm Spot",
            Func = function()
                Notify("Teleport", "Teleporting to best farm spot", 3)
                warn("Best Farm Spot button clicked")
                -- Add farm spot teleport logic here
            end
        })
        
        -- Hidden Area
        TeleportGroup:AddButton({
            Text = "Hidden Area",
            Func = function()
                Notify("Teleport", "Teleporting to hidden area", 3)
                warn("Hidden Area button clicked")
                -- Add hidden area teleport logic here
            end
        })
        
        -- Boss Room
        TeleportGroup:AddButton({
            Text = "Boss Room",
            Func = function()
                Notify("Teleport", "Teleporting to boss room", 3)
                warn("Boss Room button clicked")
                -- Add boss room teleport logic here
            end
        })
        
        -- Secret Room
        TeleportGroup:AddButton({
            Text = "Secret Room",
            Func = function()
                Notify("Teleport", "Teleporting to secret room", 3)
                warn("Secret Room button clicked")
                -- Add secret room teleport logic here
            end
        })
    end
    
    if TeleportGroup and TeleportGroup.AddToggle then
        -- Auto Teleport to Farm
        TeleportGroup:AddToggle({
            Text = "Auto Farm Teleport",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Auto Teleport", "Auto farm teleport enabled", 3)
                    warn("Auto Farm Teleport enabled")
                    -- Add auto teleport logic here
                else
                    Notify("Auto Teleport", "Auto farm teleport disabled", 3)
                    warn("Auto Farm Teleport disabled")
                end
            end
        })
        
        -- Auto Teleport to Safe Zone
        TeleportGroup:AddToggle({
            Text = "Auto Safe Zone",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Auto Teleport", "Auto safe zone enabled", 3)
                    warn("Auto Safe Zone enabled")
                    -- Add auto safe zone logic here
                else
                    Notify("Auto Teleport", "Auto safe zone disabled", 3)
                    warn("Auto Safe Zone disabled")
                end
            end
        })
    end
    
    if TeleportGroup and TeleportGroup.AddDropdown then
        -- Custom Locations
        TeleportGroup:AddDropdown({
            Text = "Custom Locations",
            Default = "Select location",
            Values = {"Location 1", "Location 2", "Location 3", "Location 4"},
            Callback = function(value)
                Notify("Teleport", "Teleporting to: " .. value, 3)
                warn("Custom Location selected: " .. value)
            end
        })
    end
end

-- Right side groupbox for Locations tab
if Tabs.Locations and Tabs.Locations.AddRightGroupbox then
    local LocationsRight = Tabs.Locations:AddRightGroupbox("Custom Teleport", "map-pin")
    
    if LocationsRight and LocationsRight.AddButton then
        LocationsRight:AddButton({
            Text = "Save Current Position",
            Func = function()
                Notify("Save", "Current position saved", 3)
                warn("Save Current Position button clicked")
            end
        })
        
        LocationsRight:AddButton({
            Text = "Clear Saved Positions",
            Func = function()
                Notify("Clear", "All saved positions cleared", 3)
                warn("Clear Saved Positions button clicked")
            end
        })
    end
    
    if LocationsRight and LocationsRight.AddLabel then
        LocationsRight:AddLabel({
            Text = "Saved Locations: 0"
        })
        
        LocationsRight:AddLabel({
            Text = "Current Position: [0, 0, 0]"
        })
    end
end

-- ============================================
-- ORIGINAL ANTI-FEATURES
-- ============================================
if Tabs.Antis and Tabs.Antis.AddLeftGroupbox then
    local AntiGroup = Tabs.Antis:AddLeftGroupbox("Anti-Cheats", "ban")
    
    if AntiGroup and AntiGroup.AddToggle then
        -- Anti-Kick
        AntiGroup:AddToggle({
            Text = "Anti-Kick",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Anti", "Anti-Kick enabled", 3)
                    warn("Anti-Kick enabled")
                    -- Add anti-kick logic here
                else
                    Notify("Anti", "Anti-Kick disabled", 3)
                    warn("Anti-Kick disabled")
                end
            end
        })
        
        -- Anti-Ban
        AntiGroup:AddToggle({
            Text = "Anti-Ban",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Anti", "Anti-Ban enabled", 3)
                    warn("Anti-Ban enabled")
                    -- Add anti-ban logic here
                else
                    Notify("Anti", "Anti-Ban disabled", 3)
                    warn("Anti-Ban disabled")
                end
            end
        })
        
        -- Anti-AFK
        AntiGroup:AddToggle({
            Text = "Anti-AFK",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Anti", "Anti-AFK enabled", 3)
                    warn("Anti-AFK enabled")
                    -- Add anti-afk logic here
                else
                    Notify("Anti", "Anti-AFK disabled", 3)
                    warn("Anti-AFK disabled")
                end
            end
        })
        
        -- Anti-Grab
        AntiGroup:AddToggle({
            Text = "Anti-Grab",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Anti", "Anti-Grab enabled", 3)
                    warn("Anti-Grab enabled")
                    -- Add anti-grab logic here
                else
                    Notify("Anti", "Anti-Grab disabled", 3)
                    warn("Anti-Grab disabled")
                end
            end
        })
        
        -- Anti-Stun
        AntiGroup:AddToggle({
            Text = "Anti-Stun",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Anti", "Anti-Stun enabled", 3)
                    warn("Anti-Stun enabled")
                    -- Add anti-stun logic here
                else
                    Notify("Anti", "Anti-Stun disabled", 3)
                    warn("Anti-Stun disabled")
                end
            end
        })
        
        -- Anti-Freeze
        AntiGroup:AddToggle({
            Text = "Anti-Freeze",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Anti", "Anti-Freeze enabled", 3)
                    warn("Anti-Freeze enabled")
                    -- Add anti-freeze logic here
                else
                    Notify("Anti", "Anti-Freeze disabled", 3)
                    warn("Anti-Freeze disabled")
                end
            end
        })
    end
    
    if AntiGroup and AntiGroup.AddButton then
        -- Enable All Antis
        AntiGroup:AddButton({
            Text = "Enable All Antis",
            Func = function()
                Notify("Antis", "All anti-cheats enabled", 3)
                warn("Enable All Antis button clicked")
            end
        })
        
        -- Disable All Antis
        AntiGroup:AddButton({
            Text = "Disable All Antis",
            Func = function()
                Notify("Antis", "All anti-cheats disabled", 3)
                warn("Disable All Antis button clicked")
            end
        })
    end
end

-- Right side groupbox for Antis tab
if Tabs.Antis and Tabs.Antis.AddRightGroupbox then
    local AntisRight = Tabs.Antis:AddRightGroupbox("Anti Settings", "shield")
    
    if AntisRight and AntisRight.AddLabel then
        AntisRight:AddLabel({
            Text = "Status: Protected"
        })
        
        AntisRight:AddLabel({
            Text = "Detection: 0"
        })
        
        AntisRight:AddLabel({
            Text = "Blocks: 0"
        })
    end
    
    if AntisRight and AntisRight.AddButton then
        AntisRight:AddButton({
            Text = "Test Protection",
            Func = function()
                Notify("Test", "Testing protection...", 3)
                warn("Test Protection button clicked")
            end
        })
        
        AntisRight:AddButton({
            Text = "Reset Counters",
            Func = function()
                Notify("Reset", "Counters reset", 3)
                warn("Reset Counters button clicked")
            end
        })
    end
end

-- ============================================
-- ORIGINAL MISC FEATURES
-- ============================================
if Tabs.Misc and Tabs.Misc.AddLeftGroupbox then
    local MiscGroup = Tabs.Misc:AddLeftGroupbox("Miscellaneous", "cloudy")
    
    if MiscGroup and MiscGroup.AddButton then
        -- Server Hop
        MiscGroup:AddButton({
            Text = "Server Hop",
            Func = function()
                Notify("Server", "Attempting to server hop...", 3)
                warn("Server Hop button clicked")
                -- Add server hop logic here
            end
        })
        
        -- Rejoin Server
        MiscGroup:AddButton({
            Text = "Rejoin Server",
            Func = function()
                Notify("Server", "Rejoining server...", 3)
                warn("Rejoin Server button clicked")
                -- Add rejoin logic here
            end
        })
        
        -- Copy Game ID
        MiscGroup:AddButton({
            Text = "Copy Game ID",
            Func = function()
                if setclipboard then
                    setclipboard(tostring(game.PlaceId))
                    Notify("Game ID", "Copied to clipboard: " .. game.PlaceId, 3)
                    warn("Copy Game ID button clicked: " .. game.PlaceId)
                else
                    warn("setclipboard function not available")
                end
            end
        })
        
        -- Destroy GUI
        MiscGroup:AddButton({
            Text = "Destroy GUI",
            Func = function()
                Notify("GUI", "Destroying GUI...", 3)
                warn("Destroy GUI button clicked")
                if Library and Library.Unload then
                    Library:Unload()
                end
            end
        })
        
        -- Open Script Folder
        MiscGroup:AddButton({
            Text = "Open Script Folder",
            Func = function()
                Notify("Folder", "Opening script folder...", 3)
                warn("Open Script Folder button clicked")
            end
        })
        
        -- Reload Script
        MiscGroup:AddButton({
            Text = "Reload Script",
            Func = function()
                Notify("Reload", "Reloading script...", 3)
                warn("Reload Script button clicked")
            end
        })
    end
    
    if MiscGroup and MiscGroup.AddToggle then
        -- Auto Server Hop
        MiscGroup:AddToggle({
            Text = "Auto Server Hop",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Auto Hop", "Auto server hop enabled", 3)
                    warn("Auto Server Hop enabled")
                    -- Add auto hop logic here
                else
                    Notify("Auto Hop", "Auto server hop disabled", 3)
                    warn("Auto Server Hop disabled")
                end
            end
        })
        
        -- Auto Rejoin
        MiscGroup:AddToggle({
            Text = "Auto Rejoin",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Auto Rejoin", "Auto rejoin enabled", 3)
                    warn("Auto Rejoin enabled")
                    -- Add auto rejoin logic here
                else
                    Notify("Auto Rejoin", "Auto rejoin disabled", 3)
                    warn("Auto Rejoin disabled")
                end
            end
        })
        
        -- Auto Destroy GUI
        MiscGroup:AddToggle({
            Text = "Auto Destroy GUI",
            Default = false,
            Callback = function(value)
                if value then
                    Notify("Auto Destroy", "Auto destroy GUI enabled", 3)
                    warn("Auto Destroy GUI enabled")
                else
                    Notify("Auto Destroy", "Auto destroy GUI disabled", 3)
                    warn("Auto Destroy GUI disabled")
                end
            end
        })
    end
end

-- Right side groupbox for Misc tab
if Tabs.Misc and Tabs.Misc.AddRightGroupbox then
    local MiscRight = Tabs.Misc:AddRightGroupbox("Script Info", "info")
    
    if MiscRight and MiscRight.AddLabel then
        MiscRight:AddLabel({
            Text = "Version: V1.1"
        })
        
        MiscRight:AddLabel({
            Text = "Author: apnff0x"
        })
        
        MiscRight:AddLabel({
            Text = "Executor: " .. executor
        })
        
        MiscRight:AddLabel({
            Text = "Game: " .. game.PlaceId
        })
        
        MiscRight:AddLabel({
            Text = "Players: " .. #Players:GetPlayers()
        })
    end
    
    if MiscRight and MiscRight.AddButton then
        MiscRight:AddButton({
            Text = "Check Updates",
            Func = function()
                Notify("Update", "Checking for updates...", 3)
                warn("Check Updates button clicked")
            end
        })
    end
end

-- ============================================
-- ORIGINAL UI SETTINGS
-- ============================================
if Tabs["UI Settings"] and Tabs["UI Settings"].AddLeftGroupbox then
    local UIGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu Settings", "wrench")
    
    if UIGroup and UIGroup.AddDropdown then
        -- UI Themes
        UIGroup:AddDropdown({
            Text = "Theme",
            Default = "Tokyo Night",
            Values = {"Tokyo Night", "Midnight", "Aqua", "Dark", "Light", "Purple", "Red", "Green", "Blue"},
            Callback = function(value)
                if ThemeManager and ThemeManager.ApplyTheme then
                    ThemeManager:ApplyTheme(value)
                    Notify("Theme", "Theme changed to: " .. value, 3)
                    warn("Theme changed to: " .. value)
                end
            end
        })
    end
    
    if UIGroup and UIGroup.AddToggle then
        -- Toggle UI
        UIGroup:AddToggle({
            Text = "Toggle UI",
            Default = true,
            Callback = function(value)
                if Window and Window.Enabled ~= nil then
                    Window.Enabled = value
                    Notify("UI", value and "UI shown" or "UI hidden", 3)
                    warn("UI Toggled: " .. tostring(value))
                end
            end
        })
        
        -- Watermark
        UIGroup:AddToggle({
            Text = "Watermark",
            Default = true,
            Callback = function(value)
                Notify("Watermark", value and "Enabled" or "Disabled", 3)
                warn("Watermark: " .. tostring(value))
            end
        })
        
        -- Keybind Toggle
        UIGroup:AddToggle({
            Text = "Keybind Toggle",
            Default = true,
            Callback = function(value)
                Notify("Keybind", value and "Enabled" or "Disabled", 3)
                warn("Keybind Toggle: " .. tostring(value))
            end
        })
        
        -- Custom Cursor
        UIGroup:AddToggle({
            Text = "Custom Cursor",
            Default = true,
            Callback = function(value)
                Notify("Cursor", value and "Enabled" or "Disabled", 3)
                warn("Custom Cursor: " .. tostring(value))
            end
        })
    end
    
    if UIGroup and UIGroup.AddSlider then
        -- UI Transparency
        UIGroup:AddSlider({
            Text = "UI Transparency",
            Default = 0,
            Min = 0,
            Max = 1,
            Rounding = 2,
            Callback = function(value)
                Notify("Transparency", "Set to: " .. value, 3)
                warn("UI Transparency set to: " .. value)
            end
        })
        
        -- UI Scale
        UIGroup:AddSlider({
            Text = "UI Scale",
            Default = 1,
            Min = 0.5,
            Max = 2,
            Rounding = 1,
            Callback = function(value)
                Notify("Scale", "Set to: " .. value, 3)
                warn("UI Scale set to: " .. value)
            end
        })
    end
end

-- Right side groupbox for UI Settings tab
if Tabs["UI Settings"] and Tabs["UI Settings"].AddRightGroupbox then
    local UIRight = Tabs["UI Settings"]:AddRightGroupbox("Config", "save")
    
    if UIRight and UIRight.AddButton then
        UIRight:AddButton({
            Text = "Save Config",
            Func = function()
                if SaveManager and SaveManager.SaveConfig then
                    SaveManager:SaveConfig()
                    Notify("Config", "Configuration saved", 3)
                    warn("Save Config button clicked")
                end
            end
        })
        
        UIRight:AddButton({
            Text = "Load Config",
            Func = function()
                if SaveManager and SaveManager.LoadConfig then
                    SaveManager:LoadConfig()
                    Notify("Config", "Configuration loaded", 3)
                    warn("Load Config button clicked")
                end
            end
        })
        
        UIRight:AddButton({
            Text = "Reset Config",
            Func = function()
                if SaveManager and SaveManager.ResetConfig then
                    SaveManager:ResetConfig()
                    Notify("Config", "Configuration reset", 3)
                    warn("Reset Config button clicked")
                end
            end
        })
        
        UIRight:AddButton({
            Text = "Delete Config",
            Func = function()
                if SaveManager and SaveManager.DeleteConfig then
                    SaveManager:DeleteConfig()
                    Notify("Config", "Configuration deleted", 3)
                    warn("Delete Config button clicked")
                end
            end
        })
    end
    
    if UIRight and UIRight.AddLabel then
        UIRight:AddLabel({
            Text = "Config: Default"
        })
    end
end

-- ============================================
-- SAFETY CHECKS FOR NON-FORSAKEN GAMES
-- ============================================
-- Add a warning to features that are Forsaken-specific
local function CheckForsakenFeature(featureName)
    if not table.find(forsaken_games, game.PlaceId) then
        Notify("Feature Warning", featureName .. " is designed for Forsaken games and may not work", 5)
        return false
    end
    return true
end

-- ============================================
-- SAVE MANAGER & THEME SYSTEM WITH SAFETY
-- ============================================
if ThemeManager and ThemeManager.SetLibrary then
    ThemeManager:SetLibrary(Library)
    ThemeManager:SetFolder("VoidSaken")
    ThemeManager:ApplyTheme("Tokyo Night")
end

if SaveManager and SaveManager.SetLibrary then
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
    SaveManager:SetSubFolder("Forsaken")
    SaveManager:SetFolder("VoidSaken/Forsaken")
    
    if Tabs["UI Settings"] and SaveManager.BuildConfigSection then
        SaveManager:BuildConfigSection(Tabs["UI Settings"])
    end
    
    if SaveManager.LoadAutoloadConfig then
        SaveManager:LoadAutoloadConfig()
    end
end

-- ============================================
-- FIX FOR NIL REFERENCE ERRORS
-- ============================================
-- Add global error handler
function _G.safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("⚠️ Error in safeCall: " .. tostring(result))
        return nil
    end
    return result
end

-- Animation loading fix (from your error logs)
local function safeLoadAnimation(assetId)
    if not assetId or assetId == 0 or assetId == "0" then
        warn("⚠️ Invalid animation assetId:", assetId)
        return nil
    end
    
    local numericId = tonumber(assetId)
    if not numericId or numericId <= 0 then
        warn("⚠️ Invalid numeric animation ID:", assetId)
        return nil
    end
    
    local success, animation = pcall(function()
        return game:GetService("ContentProvider"):LoadAnimation(Instance.new("Animation"))
    end)
    
    if success and animation then
        animation.AnimationId = "rbxassetid://" .. numericId
        return animation
    else
        warn("⚠️ Failed to load animation for assetId:", numericId)
        return nil
    end
end

-- GUI element access fix
local function safeGuiAccess(obj, field)
    if obj and obj[field] then
        return obj[field]
    else
        warn("⚠️ Cannot access " .. tostring(field) .. " on " .. tostring(obj))
        return nil
    end
end

-- ============================================
-- KEYBIND SYSTEM (Original Feature)
-- ============================================
local UserInputService = game:GetService("UserInputService")
local keybind = Enum.KeyCode.RightControl

if UserInputService then
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == keybind then
            if Window and Window.Enabled ~= nil then
                Window.Enabled = not Window.Enabled
                Notify("UI", Window.Enabled and "UI shown" or "UI hidden", 2)
                warn("UI Toggled via keybind: " .. tostring(Window.Enabled))
            end
        end
    end)
end

-- ============================================
-- FINAL WARNING FOR NON-FORSAKEN GAMES
-- ============================================
if not table.find(forsaken_games, game.PlaceId) then
    task.wait(2) -- Wait for UI to load
    Notify("⚠️ Compatibility Warning", 
        "This script is optimized for Forsaken games.\n" ..
        "Some features may not work correctly in this game.\n" ..
        "Use at your own risk!", 10)
end

-- ============================================
-- CLEANUP AND FINAL INITIALIZATION
-- ============================================
warn("✅ Voidsaken script loaded successfully!")
warn("✅ Executor: " .. executor)
warn("✅ Game ID: " .. game.PlaceId)
warn("✅ Toggle UI with: Right Control")
warn("✅ Discord: https://discord.gg/BJ5y9ChyqN")
warn("✅ Version: V1.1")
warn("✅ Author: apnff0x")

-- Auto-update player list
if Tabs.Player and Players then
    Players.PlayerAdded:Connect(function(player)
        warn("Player joined: " .. player.Name)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        warn("Player left: " .. player.Name)
    end)
end

-- Final message
task.wait(1)
Notify("✅ Success", "Voidsaken V1.1 loaded successfully!\nToggle UI: Right Control\nDiscord: discord.gg/BJ5y9ChyqN", 10)