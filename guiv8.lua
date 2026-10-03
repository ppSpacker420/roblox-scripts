-- Speed Control & Anti-AFK System with Rayfield GUI
-- Enhanced with Visual & Camera Tools + ESP
-- MODIFIED: Speed persists through death

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Initialize Rayfield
local Window = Rayfield:CreateWindow({
   Name = "Enhanced Control Suite",
   LoadingTitle = "Loading Enhanced Controls...",
   LoadingSubtitle = "Speed, Visual, Camera & ESP Tools",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "EnhancedControlConfig",
      FileName = "EnhancedSettings"
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
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==========================================
-- ========== SPEED CONTROL SYSTEM ==========
-- ==========================================

-- Initialize character safely
local Character
local Humanoid
local HumanoidRootPart

function InitializeCharacter()
    if Player and Player.Character then
        Character = Player.Character
        Humanoid = Character:FindFirstChildOfClass("Humanoid")
        HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        
        -- MODIFIED: Apply saved speed when character is created/respawned
        if Humanoid then
            Humanoid.Died:Connect(function()
                -- Wait for respawn
                Player.CharacterAdded:Wait()
                wait(0.5) -- Small delay to ensure character is fully loaded
                ReapplySpeedSettings()
            end)
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

-- NEW: Store speed settings to persist through death
local PersistentSpeedSettings = {
    WalkSpeed = DefaultWalkSpeed,
    SpeedLock = false,
    Multiplier = 1.0
}

-- Anti-AFK Variables
local AntiAFKEnabled = false
local AFKTime = 300
local LastInputTime = tick()
local VirtualUser

pcall(function()
    VirtualUser = game:GetService("VirtualUser")
end)

-- MODIFIED: Function to reapply speed settings after respawn
function ReapplySpeedSettings()
    wait(0.5) -- Wait for character to fully load
    
    if not InitializeCharacter() then return end
    
    -- Apply persistent settings
    CurrentWalkSpeed = PersistentSpeedSettings.WalkSpeed
    SpeedLockEnabled = PersistentSpeedSettings.SpeedLock
    WalkSpeedMultiplier = PersistentSpeedSettings.Multiplier
    
    if SpeedLockEnabled and Humanoid then
        Humanoid.WalkSpeed = CurrentWalkSpeed
    elseif Humanoid then
        Humanoid.WalkSpeed = DefaultWalkSpeed
    end
    
    -- Update UI elements
    if SpeedSlider then
        SpeedSlider:Set(CurrentWalkSpeed)
    end
    
    if MultiplierSlider then
        MultiplierSlider:Set(WalkSpeedMultiplier)
    end
    
    if SpeedLabel then
        SpeedLabel:Set("Current Speed: " .. CurrentWalkSpeed)
    end
    
    if SpeedLockLabel then
        SpeedLockLabel:Set("Speed Lock: " .. (SpeedLockEnabled and "ON" or "OFF"))
    end
    
    -- Update toggle state
    local speedLockToggle = Rayfield.Flags["SpeedLockToggle"]
    if speedLockToggle then
        speedLockToggle:Set(SpeedLockEnabled)
    end
    
    print("[Speed Persistence] Speed settings restored after respawn: " .. CurrentWalkSpeed .. " studs")
end

-- MODIFIED: Save speed settings when changed
function SaveSpeedSettings()
    PersistentSpeedSettings = {
        WalkSpeed = CurrentWalkSpeed,
        SpeedLock = SpeedLockEnabled,
        Multiplier = WalkSpeedMultiplier
    }
end

-- MODIFIED: Speed Control Functions with persistence
function SetSpeedLock(enabled)
    SpeedLockEnabled = enabled
    SaveSpeedSettings() -- Save to persistent storage
    
    if not InitializeCharacter() then return end
    
    if SpeedLockEnabled then
        Humanoid.WalkSpeed = CurrentWalkSpeed
        Notify("Speed Lock", "Speed Lock: ON - Speed: " .. CurrentWalkSpeed)
    else
        Humanoid.WalkSpeed = DefaultWalkSpeed
        Notify("Speed Lock", "Speed Lock: OFF")
    end
end

function SetWalkSpeed(speed)
    speed = math.floor(speed)
    if speed <= MaxWalkSpeed then
        CurrentWalkSpeed = speed
        SaveSpeedSettings() -- Save to persistent storage
        
        if SpeedLockEnabled and Humanoid then
            Humanoid.WalkSpeed = CurrentWalkSpeed
        end
        Notify("Walk Speed", "Speed set to: " .. speed)
    else
        Notify("Warning", "Maximum speed limit is: " .. MaxWalkSpeed)
    end
end

-- RESET FUNCTION - Resets EVERYTHING about speed
function ResetSpeed()
    -- Reset speed variables
    CurrentWalkSpeed = DefaultWalkSpeed
    SpeedLockEnabled = false
    WalkSpeedMultiplier = 1.0
    SaveSpeedSettings() -- Save to persistent storage
    
    -- Reset humanoid speed
    if Humanoid then
        Humanoid.WalkSpeed = DefaultWalkSpeed
    end
    
    -- Update all GUI elements
    if SpeedSlider then
        SpeedSlider:Set(DefaultWalkSpeed)
    end
    
    if MultiplierSlider then
        MultiplierSlider:Set(1.0)
    end
    
    if SpeedLabel then
        SpeedLabel:Set("Current Speed: " .. DefaultWalkSpeed)
    end
    
    if SpeedLockLabel then
        SpeedLockLabel:Set("Speed Lock: OFF")
    end
    
    -- Update toggle states
    local speedLockToggle = Rayfield.Flags["SpeedLockToggle"]
    if speedLockToggle then
        speedLockToggle:Set(false)
    end
    
    Notify("Speed Reset", "Everything reset to default! Speed: " .. DefaultWalkSpeed)
end

function SetSpeedMultiplier(multiplier)
    WalkSpeedMultiplier = multiplier
    SaveSpeedSettings() -- Save to persistent storage
    
    local newSpeed = math.floor(DefaultWalkSpeed * WalkSpeedMultiplier)
    if newSpeed <= MaxWalkSpeed then
        SetWalkSpeed(newSpeed)
    end
end

-- Anti-AFK Functions
function ToggleAntiAFK(enabled)
    AntiAFKEnabled = enabled
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
            if tick() - LastInputTime > AFKTime then
                pcall(function()
                    if VirtualUser then
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton2(Vector2.new(0, 0))
                    end
                end)
                
                if HumanoidRootPart then
                    pcall(function()
                        if Character and Character.Parent and HumanoidRootPart then
                            HumanoidRootPart.CFrame = HumanoidRootPart.CFrame * CFrame.new(0, 0, 0.1)
                        else
                            InitializeCharacter()
                        end
                    end)
                end
            end
            wait(30)
        end
    end)
end

UserInputService.InputBegan:Connect(function()
    LastInputTime = tick()
end)

-- ==========================================
-- ========== VISUAL & CAMERA TOOLS ==========
-- ==========================================

-- Store original settings
local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogStart = Lighting.FogStart,
    FogColor = Lighting.FogColor
}

local OriginalCameraProps = {
    MaxZoomDistance = Player.CameraMaxZoomDistance,
    OcclusionMode = Player.DevCameraOcclusionMode
}

-- State variables
local VisualClarityEnabled = false
local NoSkillCheckEnabled = false
local ZoomEnabled = false
local NoclipEnabled = false
local ESPLoaded = false

-- Storage for cleanup
local RemovedFogObjects = {}
local OriginalCastShadow = {}
local SkillCheckConnections = {}
local VisualClarityConnection

-- Visual Clarity Functions
local function ApplyFullBright()
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 1000000
    Lighting.GlobalShadows = false
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.FogStart = 0
    Lighting.FogColor = Color3.fromRGB(255, 255, 255)
end

local function RemoveFogObjects()
    RemovedFogObjects = {}
    for _, obj in pairs(Lighting:GetDescendants()) do
        if obj:IsA("Atmosphere") or obj:IsA("Clouds") then
            RemovedFogObjects[obj] = obj:Clone()
            obj:Destroy()
        end
    end
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("Atmosphere") or effect:IsA("BloomEffect") or 
            effect:IsA("DepthOfFieldEffect") or effect:IsA("SunRaysEffect") then
            if string.find(effect.Name:lower(), "fog") or 
                string.find(effect.Name:lower(), "mist") or
                string.find(effect.Name:lower(), "haze") then
                RemovedFogObjects[effect] = effect:Clone()
                effect:Destroy()
            end
        end
    end
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") then
            local name = obj.Name:lower()
            if string.find(name, "fog") or string.find(name, "mist") or 
                string.find(name, "smoke") or string.find(name, "haze") then
                RemovedFogObjects[obj] = obj:Clone()
                obj:Destroy()
            end
        end
    end
end

local function RestoreFogObjects()
    for obj, clone in pairs(RemovedFogObjects) do
        if clone and not obj.Parent then
            pcall(function()
                clone.Parent = obj.Parent or Lighting
            end)
        end
    end
    RemovedFogObjects = {}
end

local function RestoreOriginalLighting()
    for key, value in pairs(OriginalLighting) do
        pcall(function()
            Lighting[key] = value
        end)
    end
end

local function DisableShadows()
    OriginalCastShadow = {}
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            OriginalCastShadow[part] = part.CastShadow
            part.CastShadow = false
        end
    end
end

local function RestoreShadows()
    for part, castShadow in pairs(OriginalCastShadow) do
        if part and part.Parent then
            pcall(function()
                part.CastShadow = castShadow
            end)
        end
    end
    OriginalCastShadow = {}
end

function ToggleVisualClarity()
    if VisualClarityEnabled then
        VisualClarityEnabled = false
        if VisualClarityConnection then
            VisualClarityConnection:Disconnect()
            VisualClarityConnection = nil
        end
        RestoreOriginalLighting()
        RestoreFogObjects()
        RestoreShadows()
        Notify("Visual Clarity", "Visual Clarity: OFF")
    else
        VisualClarityEnabled = true
        ApplyFullBright()
        RemoveFogObjects()
        DisableShadows()
        VisualClarityConnection = RunService.RenderStepped:Connect(function()
            ApplyFullBright()
            for _, obj in pairs(Lighting:GetDescendants()) do
                if obj:IsA("Atmosphere") or obj:IsA("Clouds") then
                    if not RemovedFogObjects[obj] then
                        RemovedFogObjects[obj] = obj:Clone()
                        obj:Destroy()
                    end
                end
            end
        end)
        Notify("Visual Clarity", "Visual Clarity: ON")
    end
end

-- No Skill Check Functions
local SkillCheckNames = {"SkillCheckPromptGui", "SkillCheckPromptGui-con", "SkillCheckEvent", "SkillCheckFailEvent", "SkillCheckResultEvent", "SkillCheckGui", "SkillCheck", "SkillCheckPrompt", "Skillcheck", "Skill", "Check"}

local function IsSkillCheckObject(obj)
    if not obj or not obj.Name then return false end
    local name = string.lower(obj.Name)
    for _, skillName in ipairs(SkillCheckNames) do
        if name == string.lower(skillName) then return true end
    end
    if string.find(name, "skillcheck") or string.find(name, "skill check") then return true end
    if obj.Parent then
        local parentName = string.lower(obj.Parent.Name)
        if string.find(parentName, "skillcheck") or string.find(parentName, "skill check") then return true end
    end
    return false
end

local function RemoveSkillCheckObject(obj)
    pcall(function()
        if IsSkillCheckObject(obj) then
            if obj:IsA("ScreenGui") or obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") then
                obj.Enabled = false
                obj.Visible = false
            end
            if obj:IsA("RemoteEvent") then
                local oldFire = obj.FireServer
                obj.FireServer = function(...)
                    if NoSkillCheckEnabled then return nil end
                    return oldFire(...)
                end
            elseif obj:IsA("RemoteFunction") then
                local oldInvoke = obj.InvokeServer
                obj.InvokeServer = function(...)
                    if NoSkillCheckEnabled then return nil end
                    return oldInvoke(...)
                end
            end
            obj:Destroy()
            return true
        end
    end)
    return false
end

local function InitialSkillCheckCleanup()
    local placesToCheck = {Player:FindFirstChild("PlayerGui"), StarterGui, Workspace, ReplicatedStorage}
    for _, place in ipairs(placesToCheck) do
        if place then
            for _, obj in ipairs(place:GetDescendants()) do
                RemoveSkillCheckObject(obj)
            end
        end
    end
end

function ToggleNoSkillCheck()
    if NoSkillCheckEnabled then
        NoSkillCheckEnabled = false
        for _, conn in ipairs(SkillCheckConnections) do
            pcall(function() conn:Disconnect() end)
        end
        SkillCheckConnections = {}
        Notify("No Skill Check", "No Skill Check: OFF")
    else
        NoSkillCheckEnabled = true
        InitialSkillCheckCleanup()
        local function MonitorDescendantAdded(parent)
            local conn = parent.DescendantAdded:Connect(function(obj)
                task.wait(0.1)
                RemoveSkillCheckObject(obj)
            end)
            table.insert(SkillCheckConnections, conn)
        end
        local placesToMonitor = {Player:FindFirstChild("PlayerGui") or Player:WaitForChild("PlayerGui", 5), StarterGui, Workspace, ReplicatedStorage}
        for _, place in ipairs(placesToMonitor) do
            if place then
                MonitorDescendantAdded(place)
            end
        end
        Notify("No Skill Check", "No Skill Check: ON")
    end
end

-- Camera Functions
function ToggleInfiniteZoom()
    ZoomEnabled = not ZoomEnabled
    if ZoomEnabled then
        Player.CameraMaxZoomDistance = math.huge
        Notify("Infinite Zoom", "Infinite Zoom: ON")
    else
        Player.CameraMaxZoomDistance = OriginalCameraProps.MaxZoomDistance
        Notify("Infinite Zoom", "Infinite Zoom: OFF")
    end
end

function ToggleCameraNoclip()
    NoclipEnabled = not NoclipEnabled
    if NoclipEnabled then
        Player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
        Notify("Camera Noclip", "Camera Noclip: ON")
    else
        Player.DevCameraOcclusionMode = OriginalCameraProps.OcclusionMode
        Notify("Camera Noclip", "Camera Noclip: OFF")
    end
end

-- ESP Function
function LoadESP()
    if not ESPLoaded then
        pcall(function()
            loadstring(game:HttpGet("https://obj.wearedevs.net/2/scripts/WRD%20ESP.lua"))()
        end)
        ESPLoaded = true
        Notify("ESP", "WRD ESP Loaded Successfully!")
    else
        Notify("ESP", "WRD ESP is already loaded")
    end
end

-- Notification Helper
function Notify(title, content)
    Rayfield:Notify({
        Title = title,
        Content = content,
        Duration = 2,
        Image = 4483362458
    })
end

-- ==========================================
-- ========== RAYFIELD GUI CREATION ==========
-- ==========================================

-- Create Speed Control Tab
local SpeedTab = Window:CreateTab("Speed Control", 4483362458)

SpeedTab:CreateSection("Speed Status")
local SpeedLabel = SpeedTab:CreateLabel("Current Speed: " .. CurrentWalkSpeed)
local SpeedLockLabel = SpeedTab:CreateLabel("Speed Lock: " .. (SpeedLockEnabled and "ON" or "OFF"))
local AntiAFKLabel = SpeedTab:CreateLabel("Anti-AFK: " .. (AntiAFKEnabled and "ON" or "OFF"))

SpeedTab:CreateSection("Speed Control")

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

SpeedTab:CreateToggle({
    Name = "Speed Lock",
    CurrentValue = SpeedLockEnabled,
    Flag = "SpeedLockToggle",
    Callback = function(value)
        SetSpeedLock(value)
        SpeedLockLabel:Set("Speed Lock: " .. (value and "ON" or "OFF"))
    end,
})

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

SpeedTab:CreateSection("Quick Multipliers")
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

SpeedTab:CreateSection("Quick Speed Presets")
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

-- COMPLETE RESET BUTTON - Resets EVERYTHING about speed
SpeedTab:CreateSection("Reset")

SpeedTab:CreateButton({
    Name = "🔄 FULL SPEED RESET",
    Callback = function()
        ResetSpeed()
    end,
})

-- Anti-AFK Tab
local AFKTab = Window:CreateTab("Anti-AFK", 7733960981)

AFKTab:CreateSection("Anti-AFK Settings")

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
local LastInputLabel = AFKTab:CreateLabel("Last Input: Active")
local AFKStatusLabel = AFKTab:CreateLabel("Status: Not AFK")

-- Create Visual & Camera Tools Tab
local VisualTab = Window:CreateTab("Visual & Camera", 6034287595)

VisualTab:CreateSection("Visual Clarity")
VisualTab:CreateToggle({
    Name = "Visual Clarity",
    CurrentValue = VisualClarityEnabled,
    Flag = "VisualClarityToggle",
    Callback = function(value)
        ToggleVisualClarity()
    end,
})

VisualTab:CreateParagraph({
    Title = "Visual Clarity Info",
    Content = "Removes fog, increases brightness, disables shadows for better visibility. Keybind: F6"
})

VisualTab:CreateSection("No Skill Check")
VisualTab:CreateToggle({
    Name = "No Skill Check",
    CurrentValue = NoSkillCheckEnabled,
    Flag = "NoSkillCheckToggle",
    Callback = function(value)
        ToggleNoSkillCheck()
    end,
})

VisualTab:CreateParagraph({
    Title = "No Skill Check Info",
    Content = "Removes skill check UI elements and blocks skill check events. Keybind: F7"
})

VisualTab:CreateSection("Camera Tools")
VisualTab:CreateToggle({
    Name = "Infinite Zoom",
    CurrentValue = ZoomEnabled,
    Flag = "InfiniteZoomToggle",
    Callback = function(value)
        ToggleInfiniteZoom()
    end,
})

VisualTab:CreateToggle({
    Name = "Camera Noclip",
    CurrentValue = NoclipEnabled,
    Flag = "CameraNoclipToggle",
    Callback = function(value)
        ToggleCameraNoclip()
    end,
})

VisualTab:CreateParagraph({
    Title = "Camera Tools Info",
    Content = "Infinite Zoom: Remove camera zoom limit (F8)\nCamera Noclip: Camera passes through walls (F10)"
})

VisualTab:CreateSection("ESP")
VisualTab:CreateButton({
    Name = "Load WRD ESP",
    Callback = function()
        LoadESP()
    end,
})

VisualTab:CreateParagraph({
    Title = "ESP Info",
    Content = "Loads external WeAreDevs ESP script for player/enemy highlighting."
})

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings", 6034509993)

SettingsTab:CreateSection("Speed Configuration")
SettingsTab:CreateSlider({
    Name = "Default Walk Speed",
    Range = {16, 50},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = DefaultWalkSpeed,
    Flag = "DefaultSpeedSlider",
    Callback = function(value)
        DefaultWalkSpeed = value
        Notify("Default Speed", "Default speed set to: " .. value)
    end,
})

SettingsTab:CreateSlider({
    Name = "Maximum Speed",
    Range = {50, 500},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = MaxWalkSpeed,
    Flag = "MaxSpeedSlider",
    Callback = function(value)
        MaxWalkSpeed = value
        Notify("Max Speed", "Maximum speed limit: " .. value)
    end,
})

SettingsTab:CreateSection("Keybinds")
SettingsTab:CreateKeybind({
    Name = "Toggle Speed Lock",
    CurrentKeybind = "V",  -- CHANGED FROM F TO V
    HoldToInteract = false,
    Flag = "SpeedLockKeybind",
    Callback = function(keybind)
        SetSpeedLock(not SpeedLockEnabled)
        SpeedLockLabel:Set("Speed Lock: " .. (SpeedLockEnabled and "ON" or "OFF"))
        local toggle = Rayfield.Flags["SpeedLockToggle"]
        if toggle then toggle:Set(SpeedLockEnabled) end
    end,
})

-- REMOVED: Toggle GUI Visibility RightShift keybind (Rayfield has built-in)

SettingsTab:CreateKeybind({
    Name = "Toggle Visual Clarity",
    CurrentKeybind = "F6",
    HoldToInteract = false,
    Flag = "VisualClarityKeybind",
    Callback = function(keybind)
        ToggleVisualClarity()
        local toggle = Rayfield.Flags["VisualClarityToggle"]
        if toggle then toggle:Set(VisualClarityEnabled) end
    end,
})

SettingsTab:CreateKeybind({
    Name = "Toggle Infinite Zoom",
    CurrentKeybind = "F8",
    HoldToInteract = false,
    Flag = "InfiniteZoomKeybind",
    Callback = function(keybind)
        ToggleInfiniteZoom()
        local toggle = Rayfield.Flags["InfiniteZoomToggle"]
        if toggle then toggle:Set(ZoomEnabled) end
    end,
})

SettingsTab:CreateKeybind({
    Name = "Toggle Camera Noclip",
    CurrentKeybind = "F10",
    HoldToInteract = false,
    Flag = "CameraNoclipKeybind",
    Callback = function(keybind)
        ToggleCameraNoclip()
        local toggle = Rayfield.Flags["CameraNoclipToggle"]
        if toggle then toggle:Set(NoclipEnabled) end
    end,
})

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
        Notify("GUI Destroyed", "Enhanced Control GUI has been closed")
    end,
})

-- ==========================================
-- ========== INITIALIZATION ==========
-- ==========================================

-- MODIFIED: Handle character events with persistence
Player.CharacterAdded:Connect(function(character)
    wait(0.5) -- Wait for character to fully load
    InitializeCharacter()
    ReapplySpeedSettings() -- Apply saved speed settings instead of resetting
end)

Player.CharacterRemoving:Connect(function()
    Character = nil
    Humanoid = nil
    HumanoidRootPart = nil
    -- Don't reset speed settings - they persist through death
end)

-- Auto-reconnect speed lock
RunService.Heartbeat:Connect(function()
    if SpeedLockEnabled and Humanoid and Humanoid.WalkSpeed ~= CurrentWalkSpeed then
        Humanoid.WalkSpeed = CurrentWalkSpeed
    end
end)

-- Update AFK status labels
spawn(function()
    while true do
        local timeSinceLastInput = tick() - LastInputTime
        local minutes = math.floor(timeSinceLastInput / 60)
        local seconds = math.floor(timeSinceLastInput % 60)
        
        LastInputLabel:Set(string.format("Last Input: %02d:%02d ago", minutes, seconds))
        
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

-- Initialize
delay(1, function()
    InitializeCharacter()
    ReapplySpeedSettings() -- Apply saved settings on initial load
    
    Notify("System Loaded", "Enhanced Control Suite v2.0 is ready! (Speed Persistence Enabled)")
    
    print([[

    ╔══════════════════════════════════════════╗
    ║      Enhanced Control Suite v2.0        ║
    ║    Speed + Visual + Camera + ESP        ║
    ║       WITH SPEED PERSISTENCE            ║
    ╚══════════════════════════════════════════╝
    
    Features:
    • Speed Control with Multiplier (1.0x-5.0x)
    • SPEED PERSISTS THROUGH DEATH
    • Anti-AFK System
    • Visual Clarity (No fog, full bright)
    • No Skill Check
    • Infinite Camera Zoom
    • Camera Noclip
    • WRD ESP Loader
    • COMPLETE SPEED RESET button
    
    Keybinds:
    • V - Toggle Speed Lock (Changed from F)
    • F6 - Visual Clarity
    • F8 - Infinite Zoom
    • F10 - Camera Noclip
    
    Note: Speed settings now persist through death!
    Note: Use GUI buttons for Reset Speed and Anti-AFK
    Note: Rayfield has built-in GUI toggle (default: RightControl)
    
    ]])
end)

-- Watermark
Rayfield:SetWatermark("Enhanced Control Suite v2.0 | " .. Player.Name)

-- Update watermark
spawn(function()
    while wait(5) do
        Rayfield:SetWatermark(string.format("Enhanced Control v2.0 | %s | Speed: %d", 
            Player.Name, CurrentWalkSpeed))
    end
end)

-- Load saved configuration
Rayfield:LoadConfiguration()