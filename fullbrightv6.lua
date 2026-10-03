-- Optimized Full Bright & No Fog with Minimal GUI
-- Only updates when needed

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local enabled = true

-- Store original values to restore if needed
local originalValues = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogStart = Lighting.FogStart
}

-- Create Minimal Notification GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FullBrightNotification"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ResetOnSpawn = false

-- Notification frame
local notificationFrame = Instance.new("Frame")
notificationFrame.Name = "Notification"
notificationFrame.Size = UDim2.new(0, 300, 0, 80)
notificationFrame.Position = UDim2.new(0.5, -150, 0.1, 0) -- Top center
notificationFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
notificationFrame.BorderSizePixel = 0
notificationFrame.BackgroundTransparency = 1
notificationFrame.Visible = false

-- Corner rounding
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = notificationFrame

-- Shadow
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.Size = UDim2.new(1, 10, 1, 10)
shadow.Position = UDim2.new(0, -5, 0, -5)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://5554236805"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.8
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(23, 23, 277, 277)
shadow.Parent = notificationFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Text = "Full Bright & No Fog"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left

-- Status text
local statusText = Instance.new("TextLabel")
statusText.Name = "StatusText"
statusText.Size = UDim2.new(1, -20, 0, 30)
statusText.Position = UDim2.new(0, 10, 0, 40)
statusText.BackgroundTransparency = 1
statusText.Text = "Status: ENABLED"
statusText.TextColor3 = Color3.fromRGB(100, 255, 100)
statusText.TextSize = 16
statusText.Font = Enum.Font.Gotham
statusText.TextXAlignment = Enum.TextXAlignment.Left

notificationFrame.Parent = screenGui
title.Parent = notificationFrame
statusText.Parent = notificationFrame
screenGui.Parent = CoreGui

-- Show notification function
local function showNotification()
    notificationFrame.Visible = true
    notificationFrame.BackgroundTransparency = 1
    
    -- Fade in
    for i = 0, 1, 0.1 do
        notificationFrame.BackgroundTransparency = 1 - i
        task.wait(0.01)
    end
    
    -- Wait 2 seconds
    task.wait(2)
    
    -- Fade out
    for i = 0, 1, 0.1 do
        notificationFrame.BackgroundTransparency = i
        task.wait(0.01)
    end
    
    notificationFrame.Visible = false
end

-- Update notification
local function updateNotification()
    if enabled then
        statusText.Text = "Status: ENABLED"
        statusText.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        statusText.Text = "Status: DISABLED"
        statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
    showNotification()
end

-- Lighting functions
local function enableFeatures()
    -- Apply full bright
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.GlobalShadows = false
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    
    -- Remove fog and atmospheres
    Lighting.FogEnd = 1000000
    Lighting.FogStart = 0
    
    -- Clean up existing atmospheres once
    local atmospheres = {}
    for _, obj in pairs(Lighting:GetDescendants()) do
        if obj:IsA("Atmosphere") then
            table.insert(atmospheres, obj)
        end
    end
    for _, atm in ipairs(atmospheres) do
        atm:Destroy()
    end
    
    enabled = true
    updateNotification()
    print("Full Bright & No Fog: ENABLED")
end

local function disableFeatures()
    -- Restore original values
    for key, value in pairs(originalValues) do
        Lighting[key] = value
    end
    
    enabled = false
    updateNotification()
    print("Full Bright & No Fog: DISABLED")
end

-- Toggle function
local function toggle()
    if enabled then
        disableFeatures()
    else
        enableFeatures()
    end
end

-- Show/hide keybinds info
local function showKeybinds()
    if notificationFrame.Visible then return end
    
    -- Temporarily change text to show keybinds
    local originalTitle = title.Text
    local originalStatus = statusText.Text
    local originalStatusColor = statusText.TextColor3
    
    title.Text = "Keybinds"
    statusText.Text = "F8: Toggle | F9: Keybinds"
    statusText.TextColor3 = Color3.fromRGB(200, 200, 255)
    
    notificationFrame.Visible = true
    notificationFrame.BackgroundTransparency = 1
    
    -- Fade in
    for i = 0, 1, 0.1 do
        notificationFrame.BackgroundTransparency = 1 - i
        task.wait(0.01)
    end
    
    -- Wait 3 seconds for keybinds
    task.wait(3)
    
    -- Fade out
    for i = 0, 1, 0.1 do
        notificationFrame.BackgroundTransparency = i
        task.wait(0.01)
    end
    
    notificationFrame.Visible = false
    
    -- Restore original text
    title.Text = originalTitle
    statusText.Text = originalStatus
    statusText.TextColor3 = originalStatusColor
end

-- Keybinds
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode.F8 then
            toggle()
        elseif input.KeyCode == Enum.KeyCode.F9 then
            showKeybinds()
        end
    end
end)

-- Enable on startup
enableFeatures()

-- Create simple command
local function handleChat(command)
    if command:lower() == "/fullbright" then
        toggle()
        return true
    elseif command:lower() == "/keybinds" or command:lower() == "/help" then
        showKeybinds()
        return true
    end
    return false
end

-- Hook into chat if available
if game:GetService("TextChatService") then
    game:GetService("TextChatService").TextChannelAdded:Connect(function(channel)
        channel.OnIncomingMessage = function(message)
            if handleChat(message.Text) then
                return nil -- Block the message
            end
            return message
        end
    end)
end

print("Full Bright & No Fog loaded!")
print("Keybinds:")
print("  F8 - Toggle Full Bright & No Fog")
print("  F9 - Show keybinds info")
print("Chat Commands:")
print("  /fullbright - Toggle features")
print("  /keybinds or /help - Show keybinds")

-- Auto-update for new atmospheres
Lighting.DescendantAdded:Connect(function(child)
    if enabled and child:IsA("Atmosphere") then
        task.wait(0.1) -- Small delay to ensure it's fully added
        if child and child.Parent then
            child:Destroy()
        end
    end
end)

-- Initial keybinds info
task.wait(2) -- Wait 2 seconds after loading
showKeybinds()