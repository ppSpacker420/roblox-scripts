-- Speed Control & Anti-AFK System with Rayfield GUI
-- Make sure Rayfield is loaded before running this script

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Initialize Rayfield
local Window = Rayfield:CreateWindow({
   Name = "Speed Control & Anti-AFK System",
   LoadingTitle = "Loading Speed Controls...",
   LoadingSubtitle = "by Your Script",
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

-- Initialize character safely
local Character
local Humanoid
local HumanoidRootPart

-- Function to safely initialize character
function InitializeCharacter()
    if Player and Player.Character then
        Character = Player.Character
        Humanoid = Character:FindFirstChildOfClass("Humanoid")
        HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        
        if not Humanoid then
            Humanoid = Character:WaitForChild("Humanoid")
        end
        
        if not HumanoidRootPart then
            HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
        end
        
        return true
    end
    return false
end

-- Speed Variables
local DefaultWalkSpeed = 16
local MaxWalkSpeed = 100
local CurrentWalkSpeed = DefaultWalkSpeed
local SpeedLockEnabled = false
local WalkSpeedMultiplier = 1.0

-- Anti-AFK Variables
local AntiAFKEnabled = false
local AFKTime = 300 -- 5 minutes in seconds (fixed)
local LastInputTime = tick()
local VirtualUser

-- Try to get VirtualUser safely
pcall(function()
    VirtualUser = game:GetService("VirtualUser")
end)

-- Speed Control Functions
function SetSpeedLock(enabled)
    SpeedLockEnabled = enabled
    if not Character or not Humanoid then
        if not InitializeCharacter() then
            Rayfield:Notify({
                Title = "Error",
                Content = "Character not found!",
                Duration = 3,
                Image = 4483362458
            })
            return
        end
    end
    
    if SpeedLockEnabled then
        Humanoid.WalkSpeed = CurrentWalkSpeed
        Rayfield:Notify({
            Title = "Speed Lock",
            Content = "Speed Lock: ON - Speed: " .. CurrentWalkSpeed,
            Duration = 2,
            Image = 4483362458
        })
    else
        Humanoid.WalkSpeed = DefaultWalkSpeed
        Rayfield:Notify({
            Title = "Speed Lock",
            Content = "Speed Lock: OFF",
            Duration = 2,
            Image = 4483362458
        })
    end
end

function SetWalkSpeed(speed)
    speed = math.floor(speed)
    if speed <= MaxWalkSpeed then
        CurrentWalkSpeed = speed
        if SpeedLockEnabled then
            if not Character or not Humanoid then
                if not InitializeCharacter() then
                    return
                end
            end
            Humanoid.WalkSpeed = CurrentWalkSpeed
        end
        Rayfield:Notify({
            Title = "Walk Speed",
            Content = "Speed set to: " .. speed,
            Duration = 2,
            Image = 4483362458
        })
    else
        Rayfield:Notify({
            Title = "Warning",
            Content = "Maximum speed limit is: " .. MaxWalkSpeed,
            Duration = 3,
            Image = 4483362458
        })
    end
end

function ResetSpeed()
    CurrentWalkSpeed = DefaultWalkSpeed
    SpeedLockEnabled = false
    WalkSpeedMultiplier = 1.0
    if Character and Humanoid then
        Humanoid.WalkSpeed = DefaultWalkSpeed
    end
    Rayfield:Notify({
        Title = "Speed Reset",
        Content = "Speed reset to default: " .. DefaultWalkSpeed,
        Duration = 2,
        Image = 4483362458
    })
end

function SetSpeedMultiplier(multiplier)
    WalkSpeedMultiplier = multiplier
    local newSpeed = math.floor(DefaultWalkSpeed * WalkSpeedMultiplier)
    if newSpeed <= MaxWalkSpeed then
        SetWalkSpeed(newSpeed)
    else
        Rayfield:Notify({
            Title = "Warning",
            Content = "Speed would exceed maximum limit",
            Duration = 3,
            Image = 4483362458
        })
    end
end

-- Anti-AFK Functions
function ToggleAntiAFK(enabled)
    AntiAFKEnabled = enabled
    if enabled then
        Rayfield:Notify({
            Title = "Anti-AFK",
            Content = "Anti-AFK: ON",
            Duration = 2,
            Image = 4483362458
        })
        StartAntiAFK()
    else
        Rayfield:Notify({
            Title = "Anti-AFK",
            Content = "Anti-AFK: OFF",
            Duration = 2,
            Image = 4483362458
        })
    end
end

function StartAntiAFK()
    spawn(function()
        while AntiAFKEnabled do
            local currentTime = tick()
            
            if currentTime - LastInputTime > AFKTime then
                pcall(function()
                    if VirtualUser then
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton2(Vector2.new(0, 0))
                    end
                end)
                
                if Character and HumanoidRootPart then
                    pcall(function()
                        if Character and Character.Parent and HumanoidRootPart then
                            HumanoidRootPart.CFrame = HumanoidRootPart.CFrame * CFrame.new(0, 0, 0.1)
                        else
                            InitializeCharacter()
                        end
                    end)
                else
                    InitializeCharacter()
                end
            end
            
            wait(30)
        end
    end)
end

-- Track player input for AFK detection
pcall(function()
    UserInputService.InputBegan:Connect(function()
        LastInputTime = tick()
    end)
    
    UserInputService.MouseMoved:Connect(function()
        LastInputTime = tick()
    end)
end)

-- Create Speed Control Tab
local SpeedTab = Window:CreateTab("Speed Control", 4483362458)

-- Speed Status Section
SpeedTab:CreateSection("Speed Status")

local SpeedLabel = SpeedTab:CreateLabel("Current Speed: " .. CurrentWalkSpeed)
local SpeedLockLabel = SpeedTab:CreateLabel("Speed Lock: " .. (SpeedLockEnabled and "ON" or "OFF"))
local AntiAFKLabel = SpeedTab:CreateLabel("Anti-AFK: " .. (AntiAFKEnabled and "ON" or "OFF"))

-- Speed Control Section
SpeedTab:CreateSection("Speed Control")

-- Speed Slider
local SpeedSlider = SpeedTab:CreateSlider({
    Name = "Walk Speed",
    Range = {DefaultWalkSpeed, MaxWalkSpeed},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = CurrentWalkSpeed,
    Flag = "SpeedSlider",
    Callback = function(value)
        SetWalkSpeed(value)
        SpeedLabel:Set("Current Speed: " .. math.floor(value))
    end,
})

-- Speed Lock Toggle
SpeedTab:CreateToggle({
    Name = "Speed Lock",
    CurrentValue = SpeedLockEnabled,
    Flag = "SpeedLockToggle",
    Callback = function(value)
        SetSpeedLock(value)
        SpeedLockLabel:Set("Speed Lock: " .. (value and "ON" or "OFF"))
    end,
})

-- Speed Multiplier Section
SpeedTab:CreateSection("Speed Multiplier")

local MultiplierSlider = SpeedTab:CreateSlider({
    Name = "Speed Multiplier",
    Range = {1.0, 5.0},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = WalkSpeedMultiplier,
    Flag = "MultiplierSlider",
    Callback = function(value)
        SetSpeedMultiplier(value)
        SpeedLabel:Set("Current Speed: " .. CurrentWalkSpeed)
    end,
})

-- Quick Multiplier Buttons
SpeedTab:CreateSection("Quick Multipliers")

-- Create quick multiplier buttons (1.0, 1.1, 1.2, 1.5, 2.0, 3.0, 4.0, 5.0)
local multipliers = {1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 2.0, 3.0, 4.0, 5.0}
for _, multiplier in ipairs(multipliers) do
    SpeedTab:CreateButton({
        Name = multiplier .. "x",
        Callback = function()
            SetSpeedMultiplier(multiplier)
            MultiplierSlider:Set(multiplier)
            SpeedLabel:Set("Current Speed: " .. CurrentWalkSpeed)
        end,
    })
end

-- Quick Speed Buttons
SpeedTab:CreateSection("Quick Speed Presets")

-- Create quick speed buttons
local speeds = {20, 30, 50, 75, 100}
for _, speed in ipairs(speeds) do
    SpeedTab:CreateButton({
        Name = speed .. " Studs",
        Callback = function()
            SetWalkSpeed(speed)
            SpeedSlider:Set(speed)
            SpeedLabel:Set("Current Speed: " .. speed)
        end,
    })
end

-- Reset Button
SpeedTab:CreateButton({
    Name = "Reset Speed",
    Callback = function()
        ResetSpeed()
        SpeedSlider:Set(DefaultWalkSpeed)
        MultiplierSlider:Set(1.0)
        SpeedLabel:Set("Current Speed: " .. DefaultWalkSpeed)
        SpeedLockLabel:Set("Speed Lock: OFF")
        -- Update toggle state
        local toggle = Rayfield.Flags["SpeedLockToggle"]
        if toggle then
            toggle:Set(false)
        end
    end,
})

-- Anti-AFK Tab
local AFKTab = Window:CreateTab("Anti-AFK", 4483362458)

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

AFKTab:CreateSection("AFK Information")
AFKTab:CreateParagraph({
    Title = "AFK Protection Info",
    Content = "Anti-AFK will activate after 5 minutes of inactivity. It will simulate mouse clicks to prevent you from being kicked."
})

AFKTab:CreateSection("AFK Status")

-- Create AFK status labels
local LastInputLabel = AFKTab:CreateLabel("Last Input: Active")
local AFKStatusLabel = AFKTab:CreateLabel("Status: Not AFK")

-- Update AFK status labels
spawn(function()
    while true do
        local timeSinceLastInput = tick() - LastInputTime
        local minutes = math.floor(timeSinceLastInput / 60)
        local seconds = math.floor(timeSinceLastInput % 60)
        
        -- Update last input label
        LastInputLabel:Set(string.format("Last Input: %02d:%02d ago", minutes, seconds))
        
        -- Update AFK status
        if timeSinceLastInput > AFKTime then
            AFKStatusLabel:Set("Status: AFK (Protection Active)")
            AFKStatusLabel:SetTextColor(Color3.fromRGB(255, 100, 100))
        else
            AFKStatusLabel:Set("Status: Active")
            AFKStatusLabel:SetTextColor(Color3.fromRGB(100, 255, 100))
        end
        
        wait(1)
    end
end)

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings", 4483362458)

SettingsTab:CreateSection("Configuration")

-- Default Speed Setting
SettingsTab:CreateSlider({
    Name = "Default Walk Speed",
    Range = {16, 50},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = DefaultWalkSpeed,
    Flag = "DefaultSpeedSlider",
    Callback = function(value)
        DefaultWalkSpeed = value
        Rayfield:Notify({
            Title = "Default Speed Updated",
            Content = "Default speed set to: " .. value,
            Duration = 2,
            Image = 4483362458
        })
    end,
})

-- Max Speed Setting
SettingsTab:CreateSlider({
    Name = "Maximum Walk Speed",
    Range = {50, 500},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = MaxWalkSpeed,
    Flag = "MaxSpeedSlider",
    Callback = function(value)
        MaxWalkSpeed = value
        Rayfield:Notify({
            Title = "Max Speed Updated",
            Content = "Maximum speed limit: " .. value,
            Duration = 2,
            Image = 4483362458
        })
    end,
})

SettingsTab:CreateSection("Keybinds")

SettingsTab:CreateKeybind({
    Name = "Toggle Speed Lock",
    CurrentKeybind = "F",
    HoldToInteract = false,
    Flag = "SpeedLockKeybind",
    Callback = function(keybind)
        SetSpeedLock(not SpeedLockEnabled)
        SpeedLockLabel:Set("Speed Lock: " .. (SpeedLockEnabled and "ON" or "OFF"))
        local toggle = Rayfield.Flags["SpeedLockToggle"]
        if toggle then
            toggle:Set(SpeedLockEnabled)
        end
    end,
})

SettingsTab:CreateKeybind({
    Name = "Reset Speed",
    CurrentKeybind = "R",
    HoldToInteract = false,
    Flag = "ResetSpeedKeybind",
    Callback = function(keybind)
        ResetSpeed()
        SpeedSlider:Set(DefaultWalkSpeed)
        MultiplierSlider:Set(1.0)
        SpeedLabel:Set("Current Speed: " .. DefaultWalkSpeed)
        SpeedLockLabel:Set("Speed Lock: OFF")
        local toggle = Rayfield.Flags["SpeedLockToggle"]
        if toggle then
            toggle:Set(false)
        end
    end,
})

SettingsTab:CreateKeybind({
    Name = "Toggle Anti-AFK",
    CurrentKeybind = "T",
    HoldToInteract = false,
    Flag = "AntiAFKKeybind",
    Callback = function(keybind)
        ToggleAntiAFK(not AntiAFKEnabled)
        AntiAFKLabel:Set("Anti-AFK: " .. (AntiAFKEnabled and "ON" or "OFF"))
        local toggle = Rayfield.Flags["AntiAFKToggle"]
        if toggle then
            toggle:Set(AntiAFKEnabled)
        end
    end,
})

-- UI Settings
SettingsTab:CreateSection("UI Settings")

SettingsTab:CreateToggle({
    Name = "Watermark",
    CurrentValue = true,
    Flag = "WatermarkToggle",
    Callback = function(value)
        Rayfield:SetWatermarkVisibility(value)
    end,
})

SettingsTab:CreateButton({
    Name = "Destroy GUI",
    Callback = function()
        Window:Destroy()
        Rayfield:Notify({
            Title = "GUI Destroyed",
            Content = "Speed Control GUI has been closed",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

-- Handle character events
Player.CharacterAdded:Connect(function(character)
    wait(0.5)
    InitializeCharacter()
    ResetSpeed()
end)

Player.CharacterRemoving:Connect(function()
    Character = nil
    Humanoid = nil
    HumanoidRootPart = nil
end)

-- Auto-reconnect speed lock
RunService.Heartbeat:Connect(function()
    if SpeedLockEnabled and Character and Humanoid then
        if Humanoid.WalkSpeed ~= CurrentWalkSpeed then
            Humanoid.WalkSpeed = CurrentWalkSpeed
        end
    end
end)

-- Initialize character
delay(1, function()
    InitializeCharacter()
    ResetSpeed()
    
    Rayfield:Notify({
        Title = "System Loaded",
        Content = "Speed Control & Anti-AFK system is ready!",
        Duration = 5,
        Image = 4483362458
    })
    
    print("=== Speed Control & Anti-AFK System ===")
    print("✅ Rayfield GUI loaded successfully!")
    print("\nFeatures:")
    print("- Speed Lock with adjustable speed")
    print("- Speed multiplier (1.0x to 5.0x in 0.1 increments)")
    print("- Quick multiplier buttons")
    print("- Quick speed presets")
    print("- Anti-AFK system (5 min fixed)")
    print("- Configurable settings")
    print("- Keybinds (F, R, T)")
    print("=====================================")
end)

-- Load saved settings
Rayfield:LoadConfiguration()

-- Watermark
Rayfield:SetWatermark("Speed Control v1.0 | " .. Player.Name)

-- Add watermark update
spawn(function()
    while wait(5) do
        Rayfield:SetWatermark(string.format("Speed Control v1.0 | %s | Speed: %d", Player.Name, CurrentWalkSpeed))
    end
end)