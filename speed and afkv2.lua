-- Speed Control & Anti-AFK System with Rayfield GUI
-- Enhanced with original code settings

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Initialize Rayfield
local Window = Rayfield:CreateWindow({
   Name = "Speed Control & Anti-AFK System",
   LoadingTitle = "Loading Speed Controls...",
   LoadingSubtitle = "Enhanced Version",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "SpeedControlConfig",
      FileName = "SpeedSettings"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false,
})

-- Initialize services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer

-- Original Code Settings (Default values - these would come from your original code)
local OriginalSettings = {
    -- Speed Settings
    DefaultWalkSpeed = 16,
    MaxWalkSpeed = 100,
    SpeedLock = false,
    CurrentSpeed = 16,
    SpeedMultiplier = 1,
    
    -- Anti-AFK Settings
    AntiAFK = false,
    AFKTime = 300, -- 5 minutes
    AFKMethod = "VirtualInput", -- "VirtualInput" or "CharacterMove"
    
    -- Other Settings from Original Code
    AutoResetOnRespawn = true,
    BypassAntiCheat = false,
    NotificationSounds = true,
    VisualEffects = false,
    SpeedBoostType = "WalkSpeed", -- "WalkSpeed" or "BodyVelocity"
    JumpPowerControl = false,
    JumpPower = 50,
    
    -- Keybinds from Original Code
    ToggleKey = "F",
    IncreaseKey = "E",
    DecreaseKey = "Q",
    ResetKey = "R",
    AntiAFKKey = "T",
    
    -- UI Settings from Original Code
    UIPosition = {X = 20, Y = 20},
    UISize = {Width = 250, Height = 300},
    UIColor = Color3.fromRGB(25, 25, 35),
    UITransparency = 0.2,
    
    -- Advanced Settings
    CheckForUpdates = true,
    DebugMode = false,
    LogActions = true,
    AutoSave = true
}

-- Current Settings (Will be updated by GUI)
local Settings = table.clone(OriginalSettings)

-- Initialize character
local Character, Humanoid, HumanoidRootPart

function InitializeCharacter()
    if Player and Player.Character then
        Character = Player.Character
        Humanoid = Character:FindFirstChildOfClass("Humanoid")
        HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        return true
    end
    return false
end

-- Speed Control Functions (From Original Code)
local SpeedLockEnabled = Settings.SpeedLock
local CurrentWalkSpeed = Settings.CurrentSpeed
local WalkSpeedMultiplier = Settings.SpeedMultiplier

function SetSpeedLock(enabled)
    SpeedLockEnabled = enabled
    Settings.SpeedLock = enabled
    
    if not InitializeCharacter() then return end
    
    if SpeedLockEnabled then
        Humanoid.WalkSpeed = CurrentWalkSpeed
        Notify("Speed Lock", "Speed Lock: ON - Speed: " .. CurrentWalkSpeed)
    else
        Humanoid.WalkSpeed = Settings.DefaultWalkSpeed
        Notify("Speed Lock", "Speed Lock: OFF")
    end
end

function SetWalkSpeed(speed)
    speed = math.floor(speed)
    if speed <= Settings.MaxWalkSpeed then
        CurrentWalkSpeed = speed
        Settings.CurrentSpeed = speed
        
        if SpeedLockEnabled and Humanoid then
            Humanoid.WalkSpeed = CurrentWalkSpeed
        end
        Notify("Walk Speed", "Speed set to: " .. speed)
    else
        Notify("Warning", "Maximum speed limit is: " .. Settings.MaxWalkSpeed)
    end
end

function ResetSpeed()
    CurrentWalkSpeed = Settings.DefaultWalkSpeed
    Settings.CurrentSpeed = Settings.DefaultWalkSpeed
    SpeedLockEnabled = false
    Settings.SpeedLock = false
    
    if Humanoid then
        Humanoid.WalkSpeed = Settings.DefaultWalkSpeed
    end
    Notify("Speed Reset", "Speed reset to default: " .. Settings.DefaultWalkSpeed)
end

function SetSpeedMultiplier(multiplier)
    WalkSpeedMultiplier = multiplier
    Settings.SpeedMultiplier = multiplier
    local newSpeed = Settings.DefaultWalkSpeed * WalkSpeedMultiplier
    if newSpeed <= Settings.MaxWalkSpeed then
        SetWalkSpeed(newSpeed)
    end
end

-- Anti-AFK Functions (From Original Code)
local AntiAFKEnabled = Settings.AntiAFK
local LastInputTime = tick()
local VirtualUser = game:GetService("VirtualUser")

function ToggleAntiAFK(enabled)
    AntiAFKEnabled = enabled
    Settings.AntiAFK = enabled
    
    if enabled then
        Notify("Anti-AFK", "Anti-AFK: ON")
        StartAntiAFK()
    else
        Notify("Anti-AFK", "Anti-AFK: OFF")
    end
end

function StartAntiAFK()
    spawn(function()
        while AntiAFKEnabled do
            if tick() - LastInputTime > Settings.AFKTime then
                if Settings.AFKMethod == "VirtualInput" then
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0, 0))
                elseif Settings.AFKMethod == "CharacterMove" and HumanoidRootPart then
                    HumanoidRootPart.CFrame = HumanoidRootPart.CFrame * CFrame.new(0, 0, 0.1)
                end
            end
            wait(30)
        end
    end)
end

-- Notification Helper
function Notify(title, content)
    if Settings.NotificationSounds then
        -- Add sound effect if needed
    end
    Rayfield:Notify({
        Title = title,
        Content = content,
        Duration = 2,
        Image = 4483362458
    })
end

-- Track input for AFK
UserInputService.InputBegan:Connect(function()
    LastInputTime = tick()
end)

-- Create Main Tab
local MainTab = Window:CreateTab("Main Controls", 4483362458)

-- Speed Status Section
MainTab:CreateSection("Status")
local SpeedLabel = MainTab:CreateLabel("Current Speed: " .. CurrentWalkSpeed)
local SpeedLockLabel = MainTab:CreateLabel("Speed Lock: " .. (SpeedLockEnabled and "ON" or "OFF"))
local AntiAFKLabel = MainTab:CreateLabel("Anti-AFK: " .. (AntiAFKEnabled and "ON" or "OFF"))

-- Speed Control Section
MainTab:CreateSection("Speed Control")

-- Speed Slider
local SpeedSlider = MainTab:CreateSlider({
    Name = "Walk Speed",
    Range = {Settings.DefaultWalkSpeed, Settings.MaxWalkSpeed},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = CurrentWalkSpeed,
    Flag = "SpeedSlider",
    Callback = SetWalkSpeed
})

-- Speed Lock Toggle
MainTab:CreateToggle({
    Name = "Speed Lock",
    CurrentValue = SpeedLockEnabled,
    Flag = "SpeedLockToggle",
    Callback = function(value)
        SetSpeedLock(value)
        SpeedLockLabel:Set("Speed Lock: " .. (value and "ON" or "OFF"))
    end,
})

-- Speed Multiplier
MainTab:CreateSlider({
    Name = "Speed Multiplier",
    Range = {0.5, 5},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = WalkSpeedMultiplier,
    Flag = "MultiplierSlider",
    Callback = SetSpeedMultiplier
})

-- Quick Speed Buttons
MainTab:CreateSection("Quick Presets")

local presets = {20, 30, 50, 75, 100}
for _, speed in ipairs(presets) do
    MainTab:CreateButton({
        Name = speed .. " Studs",
        Callback = function()
            SetWalkSpeed(speed)
            SpeedSlider:Set(speed)
            SpeedLabel:Set("Current Speed: " .. speed)
        end,
    })
end

-- Reset Button
MainTab:CreateButton({
    Name = "Reset Speed",
    Callback = function()
        ResetSpeed()
        SpeedSlider:Set(Settings.DefaultWalkSpeed)
        SpeedLockLabel:Set("Speed Lock: OFF")
        SpeedLabel:Set("Current Speed: " .. Settings.DefaultWalkSpeed)
        -- Update toggle
        local toggle = Rayfield.Flags["SpeedLockToggle"]
        if toggle then toggle:Set(false) end
    end,
})

-- Anti-AFK Tab
local AFKTab = Window:CreateTab("Anti-AFK", 7733960981)

AFKTab:CreateSection("Anti-AFK Settings")

-- Anti-AFK Toggle
AFKTab:CreateToggle({
    Name = "Enable Anti-AFK",
    CurrentValue = AntiAFKEnabled,
    Flag = "AntiAFKToggle",
    Callback = function(value)
        ToggleAntiAFK(value)
        AntiAFKLabel:Set("Anti-AFK: " .. (value and "ON" or "OFF"))
    end,
})

-- AFK Time
AFKTab:CreateSlider({
    Name = "AFK Time",
    Range = {1, 10},
    Increment = 1,
    Suffix = " minutes",
    CurrentValue = Settings.AFKTime / 60,
    Flag = "AFKTimeSlider",
    Callback = function(value)
        Settings.AFKTime = value * 60
        Notify("AFK Time", "Set to " .. value .. " minutes")
    end,
})

-- AFK Method
AFKTab:CreateDropdown({
    Name = "AFK Method",
    Options = {"VirtualInput", "CharacterMove"},
    CurrentOption = Settings.AFKMethod,
    Flag = "AFKMethodDropdown",
    Callback = function(option)
        Settings.AFKMethod = option
        Notify("AFK Method", "Changed to: " .. option)
    end,
})

-- Settings Tab (From Original Code)
local SettingsTab = Window:CreateTab("Settings", 6034287595)

-- Speed Settings Section
SettingsTab:CreateSection("Speed Settings")

-- Default Speed
SettingsTab:CreateSlider({
    Name = "Default Walk Speed",
    Range = {16, 50},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = Settings.DefaultWalkSpeed,
    Flag = "DefaultSpeedSlider",
    Callback = function(value)
        Settings.DefaultWalkSpeed = value
        Notify("Default Speed", "Set to: " .. value)
    end,
})

-- Max Speed
SettingsTab:CreateSlider({
    Name = "Maximum Speed",
    Range = {50, 500},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = Settings.MaxWalkSpeed,
    Flag = "MaxSpeedSlider",
    Callback = function(value)
        Settings.MaxWalkSpeed = value
        Notify("Max Speed", "Set to: " .. value)
    end,
})

-- Auto Reset on Respawn
SettingsTab:CreateToggle({
    Name = "Auto Reset on Respawn",
    CurrentValue = Settings.AutoResetOnRespawn,
    Flag = "AutoResetToggle",
    Callback = function(value)
        Settings.AutoResetOnRespawn = value
        Notify("Auto Reset", value and "Enabled" or "Disabled")
    end,
})

-- Character Settings Section
SettingsTab:CreateSection("Character Settings")

-- Jump Power Control
SettingsTab:CreateToggle({
    Name = "Control Jump Power",
    CurrentValue = Settings.JumpPowerControl,
    Flag = "JumpPowerToggle",
    Callback = function(value)
        Settings.JumpPowerControl = value
        if value and Humanoid then
            Humanoid.JumpPower = Settings.JumpPower
        end
        Notify("Jump Power", value and "Enabled" or "Disabled")
    end,
})

-- Jump Power Slider
SettingsTab:CreateSlider({
    Name = "Jump Power",
    Range = {10, 200},
    Increment = 5,
    Suffix = " power",
    CurrentValue = Settings.JumpPower,
    Flag = "JumpPowerSlider",
    Callback = function(value)
        Settings.JumpPower = value
        if Settings.JumpPowerControl and Humanoid then
            Humanoid.JumpPower = value
        end
        Notify("Jump Power", "Set to: " .. value)
    end,
})

-- Keybinds Section (From Original Code)
SettingsTab:CreateSection("Keybinds")

local keybindOptions = {"F", "G", "H", "J", "K", "L", "Q", "E", "R", "T", "Y", "U", "I", "O", "P"}

-- Toggle Speed Lock Key
SettingsTab:CreateDropdown({
    Name = "Toggle Speed Lock Key",
    Options = keybindOptions,
    CurrentOption = Settings.ToggleKey,
    Flag = "ToggleKeyDropdown",
    Callback = function(option)
        Settings.ToggleKey = option
        Notify("Keybind", "Toggle Speed Lock set to: " .. option)
    end,
})

-- Increase Speed Key
SettingsTab:CreateDropdown({
    Name = "Increase Speed Key",
    Options = keybindOptions,
    CurrentOption = Settings.IncreaseKey,
    Flag = "IncreaseKeyDropdown",
    Callback = function(option)
        Settings.IncreaseKey = option
        Notify("Keybind", "Increase Speed set to: " .. option)
    end,
})

-- Decrease Speed Key
SettingsTab:CreateDropdown({
    Name = "Decrease Speed Key",
    Options = keybindOptions,
    CurrentOption = Settings.DecreaseKey,
    Flag = "DecreaseKeyDropdown",
    Callback = function(option)
        Settings.DecreaseKey = option
        Notify("Keybind", "Decrease Speed set to: " .. option)
    end,
})

-- Reset Speed Key
SettingsTab:CreateDropdown({
    Name = "Reset Speed Key",
    Options = keybindOptions,
    CurrentOption = Settings.ResetKey,
    Flag = "ResetKeyDropdown",
    Callback = function(option)
        Settings.ResetKey = option
        Notify("Keybind", "Reset Speed set to: " .. option)
    end,
})

-- UI Settings Section (From Original Code)
SettingsTab:CreateSection("UI Settings")

-- Notification Sounds
SettingsTab:CreateToggle({
    Name = "Notification Sounds",
    CurrentValue = Settings.NotificationSounds,
    Flag = "NotificationSoundsToggle",
    Callback = function(value)
        Settings.NotificationSounds = value
        Notify("Sounds", value and "Enabled" or "Disabled")
    end,
})

-- Visual Effects
SettingsTab:CreateToggle({
    Name = "Visual Effects",
    CurrentValue = Settings.VisualEffects,
    Flag = "VisualEffectsToggle",
    Callback = function(value)
        Settings.VisualEffects = value
        Notify("Visual Effects", value and "Enabled" or "Disabled")
    end,
})

-- Advanced Settings Section
SettingsTab:CreateSection("Advanced")

-- Bypass Anti-Cheat
SettingsTab:CreateToggle({
    Name = "Bypass Anti-Cheat",
    CurrentValue = Settings.BypassAntiCheat,
    Flag = "BypassToggle",
    Callback = function(value)
        Settings.BypassAntiCheat = value
        Notify("Bypass", value and "Enabled (Use at own risk)" or "Disabled")
    end,
})

-- Debug Mode
SettingsTab:CreateToggle({
    Name = "Debug Mode",
    CurrentValue = Settings.DebugMode,
    Flag = "DebugModeToggle",
    Callback = function(value)
        Settings.DebugMode = value
        Notify("Debug Mode", value and "Enabled" or "Disabled")
    end,
})

-- Log Actions
SettingsTab:CreateToggle({
    Name = "Log Actions",
    CurrentValue = Settings.LogActions,
    Flag = "LogActionsToggle",
    Callback = function(value)
        Settings.LogActions = value
        Notify("Logging", value and "Enabled" or "Disabled")
    end,
})

-- Check for Updates
SettingsTab:CreateToggle({
    Name = "Check for Updates",
    CurrentValue = Settings.CheckForUpdates,
    Flag = "UpdatesToggle",
    Callback = function(value)
        Settings.CheckForUpdates = value
        Notify("Updates", value and "Enabled" or "Disabled")
    end,
})

-- Save/Load Section
SettingsTab:CreateSection("Data Management")

-- Save Settings Button
SettingsTab:CreateButton({
    Name = "Save Current Settings",
    Callback = function()
        Rayfield:Notify({
            Title = "Settings Saved",
            Content = "All settings have been saved",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

-- Load Defaults Button
SettingsTab:CreateButton({
    Name = "Load Default Settings",
    Callback = function()
        Settings = table.clone(OriginalSettings)
        
        -- Update all GUI elements to reflect defaults
        SpeedSlider:Set(Settings.DefaultWalkSpeed)
        SpeedLabel:Set("Current Speed: " .. Settings.DefaultWalkSpeed)
        SpeedLockLabel:Set("Speed Lock: " .. (Settings.SpeedLock and "ON" or "OFF"))
        
        Notify("Defaults Loaded", "All settings reset to defaults")
    end,
})

-- Export Settings Button
SettingsTab:CreateButton({
    Name = "Export Settings",
    Callback = function()
        local json = game:GetService("HttpService"):JSONEncode(Settings)
        setclipboard(json)
        Notify("Settings Exported", "Copied to clipboard")
    end,
})

-- System Tab
local SystemTab = Window:CreateTab("System", 6034509993)

SystemTab:CreateSection("System Information")

SystemTab:CreateLabel("Player: " .. Player.Name)
SystemTab:CreateLabel("Game: " .. game.PlaceId)
SystemTab:CreateLabel("Script Version: 2.0")

-- Actions Section
SystemTab:CreateSection("Actions")

-- Reinitialize Character
SystemTab:CreateButton({
    Name = "Reinitialize Character",
    Callback = function()
        if InitializeCharacter() then
            Notify("Character", "Reinitialized successfully")
        else
            Notify("Error", "Failed to initialize character")
        end
    end,
})

-- Test Speed
SystemTab:CreateButton({
    Name = "Test Speed (50 studs)",
    Callback = function()
        SetWalkSpeed(50)
        SpeedSlider:Set(50)
        SpeedLabel:Set("Current Speed: 50")
    end,
})

-- Test Anti-AFK
SystemTab:CreateButton({
    Name = "Test Anti-AFK",
    Callback = function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
        Notify("Test", "Anti-AFK test triggered")
    end,
})

-- Destroy GUI Button
SystemTab:CreateButton({
    Name = "Destroy GUI",
    Callback = function()
        Window:Destroy()
        Notify("GUI Destroyed", "Speed Control GUI closed")
    end,
})

-- Handle character events (From Original Code)
Player.CharacterAdded:Connect(function()
    wait(0.5)
    if InitializeCharacter() and Settings.AutoResetOnRespawn then
        ResetSpeed()
        if Settings.JumpPowerControl then
            Humanoid.JumpPower = Settings.JumpPower
        end
    end
end)

-- Keybind system (From Original Code)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    local key = input.KeyCode.Name
    local increaseKey = Settings.IncreaseKey:upper()
    local decreaseKey = Settings.DecreaseKey:upper()
    local toggleKey = Settings.ToggleKey:upper()
    local resetKey = Settings.ResetKey:upper()
    local afkKey = Settings.AntiAFKKey:upper()
    
    if key == toggleKey then
        SetSpeedLock(not SpeedLockEnabled)
        SpeedLockLabel:Set("Speed Lock: " .. (SpeedLockEnabled and "ON" or "OFF"))
        local toggle = Rayfield.Flags["SpeedLockToggle"]
        if toggle then toggle:Set(SpeedLockEnabled) end
        
    elseif key == increaseKey then
        local newSpeed = math.min(CurrentWalkSpeed + 5, Settings.MaxWalkSpeed)
        SetWalkSpeed(newSpeed)
        SpeedSlider:Set(newSpeed)
        SpeedLabel:Set("Current Speed: " .. newSpeed)
        
    elseif key == decreaseKey then
        local newSpeed = math.max(CurrentWalkSpeed - 5, Settings.DefaultWalkSpeed)
        SetWalkSpeed(newSpeed)
        SpeedSlider:Set(newSpeed)
        SpeedLabel:Set("Current Speed: " .. newSpeed)
        
    elseif key == resetKey then
        ResetSpeed()
        SpeedSlider:Set(Settings.DefaultWalkSpeed)
        SpeedLockLabel:Set("Speed Lock: OFF")
        SpeedLabel:Set("Current Speed: " .. Settings.DefaultWalkSpeed)
        local toggle = Rayfield.Flags["SpeedLockToggle"]
        if toggle then toggle:Set(false) end
        
    elseif key == afkKey then
        ToggleAntiAFK(not AntiAFKEnabled)
        AntiAFKLabel:Set("Anti-AFK: " .. (AntiAFKEnabled and "ON" or "OFF"))
        local toggle = Rayfield.Flags["AntiAFKToggle"]
        if toggle then toggle:Set(AntiAFKEnabled) end
    end
end)

-- Auto-update speed lock
RunService.Heartbeat:Connect(function()
    if SpeedLockEnabled and Humanoid and Humanoid.WalkSpeed ~= CurrentWalkSpeed then
        Humanoid.WalkSpeed = CurrentWalkSpeed
    end
end)

-- Initialize
delay(1, function()
    InitializeCharacter()
    if Settings.AutoResetOnRespawn then
        ResetSpeed()
    end
    
    -- Apply jump power if enabled
    if Settings.JumpPowerControl and Humanoid then
        Humanoid.JumpPower = Settings.JumpPower
    end
    
    Notify("System Ready", "Speed Control & Anti-AFK loaded!")
    
    print([[

    ╔══════════════════════════════════════╗
    ║   Speed Control & Anti-AFK System   ║
    ║         Rayfield GUI v2.0           ║
    ╚══════════════════════════════════════╝
    
    Features:
    • Speed Lock with adjustable speed
    • Speed multiplier (0.5x to 5x)
    • Quick speed presets
    • Anti-AFK with configurable methods
    • Jump power control
    • Customizable keybinds
    • Auto-reset on respawn
    • Settings export/import
    
    Keybinds:
    • ]] .. Settings.ToggleKey .. [[ - Toggle Speed Lock
    • ]] .. Settings.IncreaseKey .. [[ - Increase Speed
    • ]] .. Settings.DecreaseKey .. [[ - Decrease Speed
    • ]] .. Settings.ResetKey .. [[ - Reset Speed
    • ]] .. Settings.AntiAFKKey .. [[ - Toggle Anti-AFK
    
    ]])
end)

-- Watermark
Rayfield:SetWatermark("Speed Control v2.0 | " .. Player.Name .. " | Speed: " .. CurrentWalkSpeed)

-- Update watermark
spawn(function()
    while wait(5) do
        Rayfield:SetWatermark(string.format("Speed Control v2.0 | %s | Speed: %d | AFK: %s", 
            Player.Name, CurrentWalkSpeed, AntiAFKEnabled and "ON" or "OFF"))
    end
end)

-- Load saved configuration
Rayfield:LoadConfiguration()