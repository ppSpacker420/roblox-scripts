-- Full Bright & No Fog Standalone Script
-- Paste this in your executor

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local localPlayer = Players.LocalPlayer

-- Store original lighting settings
local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogStart = Lighting.FogStart,
    FogColor = Lighting.FogColor
}

-- Store removed fog objects
local removedFogObjects = {}
local connection = nil
local enabled = false

-- Function to apply Full Bright settings
local function applyFullBright()
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 1000000  -- Very far to effectively disable fog
    Lighting.GlobalShadows = false
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.FogStart = 0
    Lighting.FogColor = Color3.fromRGB(255, 255, 255)  -- White fog if any remains
end

-- Function to remove fog objects
local function removeFogObjects()
    removedFogObjects = {}
    
    -- Remove atmosphere objects
    for _, obj in pairs(Lighting:GetDescendants()) do
        if obj:IsA("Atmosphere") or obj:IsA("Clouds") then
            removedFogObjects[obj] = obj:Clone()
            obj:Destroy()
        end
    end
    
    -- Remove fog-related post-processing effects
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("Atmosphere") or 
           effect:IsA("BloomEffect") or 
           effect:IsA("DepthOfFieldEffect") or
           effect:IsA("SunRaysEffect") then
            if string.find(effect.Name:lower(), "fog") or 
               string.find(effect.Name:lower(), "mist") or
               string.find(effect.Name:lower(), "haze") then
                removedFogObjects[effect] = effect:Clone()
                effect:Destroy()
            end
        end
    end
    
    -- Check workspace for fog particles
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") then
            local name = obj.Name:lower()
            if string.find(name, "fog") or 
               string.find(name, "mist") or 
               string.find(name, "smoke") or
               string.find(name, "haze") then
                removedFogObjects[obj] = obj:Clone()
                obj:Destroy()
            end
        end
    end
end

-- Function to restore fog objects
local function restoreFogObjects()
    for obj, clone in pairs(removedFogObjects) do
        if clone and not obj.Parent then
            pcall(function()
                clone.Parent = Lighting
            end)
        end
    end
    removedFogObjects = {}
end

-- Function to restore original lighting
local function restoreOriginalLighting()
    for key, value in pairs(originalLighting) do
        pcall(function()
            Lighting[key] = value
        end)
    end
end

-- Function to enable Visual Clarity (Full Bright + No Fog)
local function enableVisualClarity()
    if enabled then return end
    
    print("Enabling Visual Clarity (Full Bright + No Fog)...")
    enabled = true
    
    -- Apply initial settings
    applyFullBright()
    removeFogObjects()
    
    -- Create loop to maintain settings
    connection = RunService.RenderStepped:Connect(function()
        applyFullBright()
        
        -- Continuously check for new fog objects
        for _, obj in pairs(Lighting:GetDescendants()) do
            if obj:IsA("Atmosphere") or obj:IsA("Clouds") then
                if not removedFogObjects[obj] then
                    removedFogObjects[obj] = obj:Clone()
                    obj:Destroy()
                end
            end
        end
        
        -- Check for fog effects
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("Atmosphere") then
                if not removedFogObjects[effect] then
                    removedFogObjects[effect] = effect:Clone()
                    effect:Destroy()
                end
            end
        end
    end)
    
    return true
end

-- Function to disable Visual Clarity
local function disableVisualClarity()
    if not enabled then return end
    
    print("Disabling Visual Clarity...")
    enabled = false
    
    -- Disconnect the loop
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    -- Restore original settings
    restoreOriginalLighting()
    restoreFogObjects()
    
    return true
end

-- Function to toggle Visual Clarity
local function toggleVisualClarity()
    if enabled then
        disableVisualClarity()
        return false
    else
        enableVisualClarity()
        return true
    end
end

-- Create simple GUI for control
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local ToggleButton = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")
local TitleLabel = Instance.new("TextLabel")

ScreenGui.Parent = game:GetService("CoreGui") or game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.Name = "VisualClarityUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Frame.Parent = ScreenGui
Frame.Size = UDim2.new(0, 220, 0, 120)  -- Slightly wider for better text
Frame.Position = UDim2.new(0.5, -110, 0, 20)
Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

-- Add corner radius
local UICorner = Instance.new("UICorner")
UICorner.Parent = Frame
UICorner.CornerRadius = UDim.new(0, 10)

-- Add subtle shadow
local UIStroke = Instance.new("UIStroke")
UIStroke.Parent = Frame
UIStroke.Color = Color3.fromRGB(60, 60, 70)
UIStroke.Thickness = 2

-- Title Label
TitleLabel.Parent = Frame
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.Position = UDim2.new(0, 0, 0, 5)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Visual Clarity"
TitleLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18

-- Status Label
StatusLabel.Parent = Frame
StatusLabel.Size = UDim2.new(1, 0, 0, 25)
StatusLabel.Position = UDim2.new(0, 0, 0, 35)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Full Bright + No Fog: OFF"
StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 14

-- Subtitle
local SubLabel = Instance.new("TextLabel")
SubLabel.Parent = Frame
SubLabel.Size = UDim2.new(1, 0, 0, 15)
SubLabel.Position = UDim2.new(0, 0, 0, 60)
SubLabel.BackgroundTransparency = 1
SubLabel.Text = "(One-click activation)"
SubLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
SubLabel.Font = Enum.Font.Gotham
SubLabel.TextSize = 11

-- Toggle Button
ToggleButton.Parent = Frame
ToggleButton.Size = UDim2.new(0.8, 0, 0, 30)
ToggleButton.Position = UDim2.new(0.1, 0, 0, 80)
ToggleButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)  -- Green for ON state
ToggleButton.Text = "ENABLE"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 14
ToggleButton.AutoButtonColor = true

-- Button corner radius
local ButtonCorner = Instance.new("UICorner")
ButtonCorner.Parent = ToggleButton
ButtonCorner.CornerRadius = UDim.new(0, 6)

-- Button hover effect
ToggleButton.MouseEnter:Connect(function()
    if enabled then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    end
end)

ToggleButton.MouseLeave:Connect(function()
    if enabled then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
    end
end)

-- Toggle functionality
ToggleButton.MouseButton1Click:Connect(function()
    enabled = toggleVisualClarity()
    
    if enabled then
        StatusLabel.Text = "Full Bright + No Fog: ON"
        StatusLabel.TextColor3 = Color3.fromRGB(80, 220, 80)
        ToggleButton.Text = "DISABLE"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
    else
        StatusLabel.Text = "Full Bright + No Fog: OFF"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        ToggleButton.Text = "ENABLE"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
    end
end)

-- Keybind support (optional - press F6 to toggle)
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F6 then
        enabled = toggleVisualClarity()
        
        if enabled then
            StatusLabel.Text = "Full Bright + No Fog: ON"
            StatusLabel.TextColor3 = Color3.fromRGB(80, 220, 80)
            ToggleButton.Text = "DISABLE"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
        else
            StatusLabel.Text = "Full Bright + No Fog: OFF"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            ToggleButton.Text = "ENABLE"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        end
        
        -- Flash the GUI to show it was toggled
        Frame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        task.wait(0.1)
        Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    end
end)

-- Cleanup function
local function cleanup()
    disableVisualClarity()
    if ScreenGui then
        ScreenGui:Destroy()
    end
    print("Visual Clarity script cleaned up")
end

-- Auto-cleanup on script termination
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == localPlayer then
        cleanup()
    end
end)

-- Optional: Auto-enable on startup (uncomment if desired)
-- task.wait(1)
-- if not enabled then
--     enabled = toggleVisualClarity()
--     if enabled then
--         StatusLabel.Text = "Full Bright + No Fog: ON"
--         StatusLabel.TextColor3 = Color3.fromRGB(80, 220, 80)
--         ToggleButton.Text = "DISABLE"
--         ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
--     end
-- end

print("====================================")
print("Visual Clarity Script Loaded!")
print("Features: Full Bright + No Fog")
print("Controls:")
print("- Click the ENABLE/DISABLE button")
print("- Press F6 to toggle (optional)")
print("====================================")