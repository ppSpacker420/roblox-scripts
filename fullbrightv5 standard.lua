-- Full Bright & No Fog Standalone Script
-- Paste this in your executor

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local localPlayer = Players.LocalPlayer

-- Function to apply Full Bright
local function applyFullBright()
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = false
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.FogStart = 0
    Lighting.FogColor = Color3.fromRGB(255, 255, 255)
end

-- Function to remove fog
local function removeFog()
    -- Remove atmosphere objects
    for _, obj in pairs(Lighting:GetDescendants()) do
        if obj:IsA("Atmosphere") then
            obj:Destroy()
        end
    end
    
    -- Set fog to maximum distance
    Lighting.FogEnd = 9999999
    Lighting.FogStart = 9999998
    
    -- Also check for post-processing effects that might create fog
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") then
            if effect.Name:lower():find("fog") or effect.Name:lower():find("blur") then
                effect:Destroy()
            end
        end
    end
end

-- Function to enable both features
local function enableFullBrightNoFog()
    print("Enabling Full Bright & No Fog...")
    
    -- Apply initial settings
    applyFullBright()
    removeFog()
    
    -- Create loop to maintain settings
    local connection
    connection = game:GetService("RunService").RenderStepped:Connect(function()
        applyFullBright()
        removeFog()
    end)
    
    -- Return function to disable
    return function()
        if connection then
            connection:Disconnect()
            connection = nil
        end
        print("Full Bright & No Fog disabled")
    end
end

-- Enable the features
local disableFunction = enableFullBrightNoFog()

-- Create simple GUI for control
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local ToggleButton = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")

ScreenGui.Parent = game:GetService("CoreGui") or game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.Name = "FullBrightNoFogUI"

Frame.Parent = ScreenGui
Frame.Size = UDim2.new(0, 200, 0, 100)
Frame.Position = UDim2.new(0.5, -100, 0, 20)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.Parent = Frame
UICorner.CornerRadius = UDim.new(0, 8)

StatusLabel.Parent = Frame
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Position = UDim2.new(0, 0, 0, 10)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Full Bright & No Fog: ON"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.TextSize = 16

ToggleButton.Parent = Frame
ToggleButton.Size = UDim2.new(0.8, 0, 0, 30)
ToggleButton.Position = UDim2.new(0.1, 0, 0, 50)
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
ToggleButton.Text = "Toggle OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 14

local UICorner2 = Instance.new("UICorner")
UICorner2.Parent = ToggleButton
UICorner2.CornerRadius = UDim.new(0, 6)

local enabled = true

ToggleButton.MouseButton1Click:Connect(function()
    enabled = not enabled
    
    if enabled then
        disableFunction = enableFullBrightNoFog()
        StatusLabel.Text = "Full Bright & No Fog: ON"
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        ToggleButton.Text = "Toggle OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    else
        if disableFunction then
            disableFunction()
        end
        StatusLabel.Text = "Full Bright & No Fog: OFF"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        ToggleButton.Text = "Toggle ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    end
end)

print("Full Bright & No Fog script loaded! GUI created.")