-- Speed Control & Anti-AFK System with Rayfield GUI
-- Enhanced with Visual & Camera Tools + ESP
-- MODIFIED: Speed persists through death AND Saves Config

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- 1. SETUP WINDOW WITH SAVING ENABLED
local Window = Rayfield:CreateWindow({
   Name = "Enhanced Control Suite",
   LoadingTitle = "Loading Controls...",
   LoadingSubtitle = "Speed, Visual, Camera & ESP Tools",
   ConfigurationSaving = {
      Enabled = true,                -- Enable Saving
      FolderName = "EnhancedControlConfig", -- Folder in your workspace
      FileName = "EnhancedSettings"  -- File name
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
local Player = Players.LocalPlayer

-- ==========================================
-- ========== SPEED CONTROL SYSTEM ==========
-- ==========================================

-- Variables
local DefaultWalkSpeed = 16
local MaxWalkSpeed = 500
local CurrentWalkSpeed = 16
local SpeedLockEnabled = false
local WalkSpeedMultiplier = 1.0

local Character
local Humanoid
local HumanoidRootPart

-- Initialize character safely
function InitializeCharacter()
    if Player and Player.Character then
        Character = Player.Character
        Humanoid = Character:FindFirstChildOfClass("Humanoid")
        HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        
        -- Apply settings immediately upon character load
        if Humanoid then
            -- Initial application
            if SpeedLockEnabled then
                Humanoid.WalkSpeed = CurrentWalkSpeed
            end

            -- Re-apply on death/respawn
            Humanoid.Died:Connect(function()
                Player.CharacterAdded:Wait()
                wait(0.5)
                InitializeCharacter()
            end)
        end
        return true
    end
    return false
end

function SetWalkSpeed(speed)
    CurrentWalkSpeed = speed
    if SpeedLockEnabled and Humanoid then
        Humanoid.WalkSpeed = CurrentWalkSpeed
    end
end

function SetSpeedLock(enabled)
    SpeedLockEnabled = enabled
    if not InitializeCharacter() then return end
    
    if SpeedLockEnabled then
        Humanoid.WalkSpeed = CurrentWalkSpeed
        Rayfield:Notify({Title = "Speed Lock", Content = "ON - Speed: " .. CurrentWalkSpeed, Duration = 2, Image = 4483362458})
    else
        Humanoid.WalkSpeed = DefaultWalkSpeed
        Rayfield:Notify({Title = "Speed Lock", Content = "OFF", Duration = 2, Image = 4483362458})
    end
end

-- ==========================================
-- ========== RAYFIELD GUI CREATION ==========
-- ==========================================

local SpeedTab = Window:CreateTab("Speed Control", 4483362458)

SpeedTab:CreateSection("Speed Control")

-- 2. ADD FLAGS TO UI ELEMENTS (Crucial for Saving)

local SpeedSlider = SpeedTab:CreateSlider({
   Name = "Walk Speed",
   Range = {16, 300},
   Increment = 1,
   Suffix = " studs",
   CurrentValue = 16,
   Flag = "SpeedSlider", -- SAVES SLIDER VALUE
   Callback = function(value)
       SetWalkSpeed(value)
   end,
})

SpeedTab:CreateToggle({
   Name = "Enable Speed Lock",
   CurrentValue = false,
   Flag = "SpeedLockToggle", -- SAVES TOGGLE STATE
   Callback = function(value)
       SetSpeedLock(value)
   end,
})

local SpeedResetBtn = SpeedTab:CreateButton({
    Name = "Reset Speed",
    Callback = function()
        SetSpeedLock(false)
        SetWalkSpeed(16)
        SpeedSlider:Set(16)
        local toggle = Rayfield.Flags["SpeedLockToggle"]
        if toggle then toggle:Set(false) end
    end,
})

-- Visual Tab
local VisualTab = Window:CreateTab("Visuals", 6034287595)

VisualTab:CreateToggle({
    Name = "Visual Clarity (Fullbright)",
    CurrentValue = false,
    Flag = "VisualClarityFlag", -- SAVES VISUAL STATE
    Callback = function(value)
        if value then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 100000
        else
            Lighting.Brightness = 1
            Lighting.GlobalShadows = true
            Lighting.FogEnd = 1000
        end
    end,
})

VisualTab:CreateToggle({
    Name = "Infinite Zoom",
    CurrentValue = false,
    Flag = "InfZoomFlag", -- SAVES ZOOM STATE
    Callback = function(value)
        Player.CameraMaxZoomDistance = value and math.huge or 128
    end,
})

-- Settings Tab (Required for proper Rayfield UX)
local SettingsTab = Window:CreateTab("Settings", 6034509993)

SettingsTab:CreateButton({
    Name = "Destroy GUI",
    Callback = function()
        Window:Destroy()
    end,
})

-- ==========================================
-- ========== INITIALIZATION ORDER ==========
-- ==========================================

-- 1. Hook Character Added
Player.CharacterAdded:Connect(function()
    wait(0.5)
    InitializeCharacter()
end)

-- 2. Initial Character Load
InitializeCharacter()

-- 3. LOAD CONFIGURATION (Must be last)
-- This will trigger the Callbacks above, setting 'CurrentWalkSpeed' 
-- and 'SpeedLockEnabled' to your saved values.
Rayfield:LoadConfiguration()