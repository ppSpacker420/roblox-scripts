-- Infinite Zoom & Camera Noclip GUI (Simplified)
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Create the GUI
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TitleBar = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local MinimizeButton = Instance.new("TextButton")
local ExitButton = Instance.new("TextButton")
local ContentFrame = Instance.new("Frame")
local ZoomToggle = Instance.new("TextButton")
local NoclipToggle = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

-- Configure GUI properties
ScreenGui.Parent = game.CoreGui or game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.Name = "CameraToolsGUI"
ScreenGui.Enabled = true

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.8, 0, 0.1, 0)
MainFrame.Size = UDim2.new(0, 220, 0, 170)
MainFrame.ClipsDescendants = true

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Title Bar
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
TitleBar.BorderSizePixel = 0
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.Size = UDim2.new(1, 0, 0, 35)

-- Title
Title.Name = "Title"
Title.Parent = TitleBar
Title.BackgroundTransparency = 1
Title.BorderSizePixel = 0
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Size = UDim2.new(0.6, -10, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "Camera Tools"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize Button (_)
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Parent = TitleBar
MinimizeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Position = UDim2.new(0.7, 0, 0.2, 0)
MinimizeButton.Size = UDim2.new(0, 20, 0, 20)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Text = "_"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.TextSize = 16

-- Exit Button (X)
ExitButton.Name = "ExitButton"
ExitButton.Parent = TitleBar
ExitButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
ExitButton.BorderSizePixel = 0
ExitButton.Position = UDim2.new(0.85, 0, 0.2, 0)
ExitButton.Size = UDim2.new(0, 20, 0, 20)
ExitButton.Font = Enum.Font.GothamBold
ExitButton.Text = "X"
ExitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ExitButton.TextSize = 14

-- Content Frame
ContentFrame.Name = "ContentFrame"
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0
ContentFrame.Position = UDim2.new(0, 0, 0, 35)
ContentFrame.Size = UDim2.new(1, 0, 1, -35)

-- Zoom Toggle Button
ZoomToggle.Name = "ZoomToggle"
ZoomToggle.Parent = ContentFrame
ZoomToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
ZoomToggle.BorderSizePixel = 0
ZoomToggle.Position = UDim2.new(0.1, 0, 0.1, 0)
ZoomToggle.Size = UDim2.new(0.8, 0, 0, 40)
ZoomToggle.Font = Enum.Font.Gotham
ZoomToggle.Text = "Infinite Zoom: OFF"
ZoomToggle.TextColor3 = Color3.fromRGB(255, 100, 100)
ZoomToggle.TextSize = 14

-- Noclip Toggle Button
NoclipToggle.Name = "NoclipToggle"
NoclipToggle.Parent = ContentFrame
NoclipToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
NoclipToggle.BorderSizePixel = 0
NoclipToggle.Position = UDim2.new(0.1, 0, 0.55, 0)
NoclipToggle.Size = UDim2.new(0.8, 0, 0, 40)
NoclipToggle.Font = Enum.Font.Gotham
NoclipToggle.Text = "Camera Noclip: OFF"
NoclipToggle.TextColor3 = Color3.fromRGB(255, 100, 100)
NoclipToggle.TextSize = 14

-- Add rounded corners
for _, button in pairs({ZoomToggle, NoclipToggle, MinimizeButton, ExitButton}) do
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = button
end

-- State variables
local zoomEnabled = false
local noclipEnabled = false
local guiHidden = false  -- Track if GUI is fully hidden

-- Toggle Infinite Zoom
local function toggleZoom()
    zoomEnabled = not zoomEnabled
    
    if zoomEnabled then
        localPlayer.CameraMaxZoomDistance = math.huge
        ZoomToggle.Text = "Infinite Zoom: ON"
        ZoomToggle.TextColor3 = Color3.fromRGB(100, 255, 100)
        ZoomToggle.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
    else
        localPlayer.CameraMaxZoomDistance = 12
        ZoomToggle.Text = "Infinite Zoom: OFF"
        ZoomToggle.TextColor3 = Color3.fromRGB(255, 100, 100)
        ZoomToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    end
end

-- Toggle Camera Noclip
local function toggleNoclip()
    noclipEnabled = not noclipEnabled
    
    if noclipEnabled then
        localPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
        NoclipToggle.Text = "Camera Noclip: ON"
        NoclipToggle.TextColor3 = Color3.fromRGB(100, 255, 100)
        NoclipToggle.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
    else
        localPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
        NoclipToggle.Text = "Camera Noclip: OFF"
        NoclipToggle.TextColor3 = Color3.fromRGB(255, 100, 100)
        NoclipToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    end
end

-- Hide/Show GUI (completely)
local function toggleGUI()
    guiHidden = not guiHidden
    
    if guiHidden then
        MainFrame.Visible = false
        MinimizeButton.Text = "+"
        MinimizeButton.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
    else
        MainFrame.Visible = true
        MinimizeButton.Text = "_"
        MinimizeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end
end

-- Connect button events
ZoomToggle.MouseButton1Click:Connect(toggleZoom)
NoclipToggle.MouseButton1Click:Connect(toggleNoclip)
MinimizeButton.MouseButton1Click:Connect(toggleGUI)

ExitButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    print("Camera Tools GUI: CLOSED")
end)

-- Draggable GUI
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Status label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = ContentFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.9, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Drag title • M to hide"
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusLabel.TextSize = 11

-- Keybind for hiding/showing GUI (M key)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.M then
        toggleGUI()
    elseif input.KeyCode == Enum.KeyCode.Z then
        toggleZoom()
    elseif input.KeyCode == Enum.KeyCode.N then
        toggleNoclip()
    elseif input.KeyCode == Enum.KeyCode.X then
        ScreenGui:Destroy()
    end
end)

print("Camera Tools GUI loaded!")
print("Hotkeys:")
print("  M = Hide/Show GUI")
print("  Z = Toggle Infinite Zoom")
print("  N = Toggle Camera Noclip")
print("  X = Close GUI")
print("Drag the title bar to move")