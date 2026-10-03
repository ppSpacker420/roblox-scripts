--https://raw.githubusercontent.com/voidsaken-script/Voidsaken-Loader/refs/heads/main/main 
-- Infinite Zoom & Camera Noclip GUI
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- Create the GUI
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local ZoomToggle = Instance.new("TextButton")
local NoclipToggle = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

-- Configure GUI properties
ScreenGui.Parent = game.CoreGui or game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.Name = "CameraToolsGUI"

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.8, 0, 0.1, 0)
MainFrame.Size = UDim2.new(0, 200, 0, 200)

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Title
Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Title.BackgroundTransparency = 0.5
Title.BorderSizePixel = 0
Title.Position = UDim2.new(0, 0, 0, 0)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Font = Enum.Font.GothamBold
Title.Text = "Camera Tools"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18

-- Zoom Toggle Button
ZoomToggle.Name = "ZoomToggle"
ZoomToggle.Parent = MainFrame
ZoomToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
ZoomToggle.BorderSizePixel = 0
ZoomToggle.Position = UDim2.new(0.1, 0, 0.25, 0)
ZoomToggle.Size = UDim2.new(0.8, 0, 0, 40)
ZoomToggle.Font = Enum.Font.Gotham
ZoomToggle.Text = "Infinite Zoom: OFF"
ZoomToggle.TextColor3 = Color3.fromRGB(255, 100, 100)
ZoomToggle.TextSize = 14

-- Noclip Toggle Button
NoclipToggle.Name = "NoclipToggle"
NoclipToggle.Parent = MainFrame
NoclipToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
NoclipToggle.BorderSizePixel = 0
NoclipToggle.Position = UDim2.new(0.1, 0, 0.5, 0)
NoclipToggle.Size = UDim2.new(0.8, 0, 0, 40)
NoclipToggle.Font = Enum.Font.Gotham
NoclipToggle.Text = "Camera Noclip: OFF"
NoclipToggle.TextColor3 = Color3.fromRGB(255, 100, 100)
NoclipToggle.TextSize = 14

-- Close Button
CloseButton.Name = "CloseButton"
CloseButton.Parent = MainFrame
CloseButton.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
CloseButton.BorderSizePixel = 0
CloseButton.Position = UDim2.new(0.1, 0, 0.75, 0)
CloseButton.Size = UDim2.new(0.8, 0, 0, 40)
CloseButton.Font = Enum.Font.Gotham
CloseButton.Text = "Close GUI"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 14

-- Add rounded corners to buttons
for _, button in pairs({ZoomToggle, NoclipToggle, CloseButton}) do
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = button
end

-- State variables
local zoomEnabled = false
local noclipEnabled = false

-- Toggle Infinite Zoom function
ZoomToggle.MouseButton1Click:Connect(function()
    zoomEnabled = not zoomEnabled
    
    if zoomEnabled then
        localPlayer.CameraMaxZoomDistance = math.huge
        ZoomToggle.Text = "Infinite Zoom: ON"
        ZoomToggle.TextColor3 = Color3.fromRGB(100, 255, 100)
        ZoomToggle.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
    else
        localPlayer.CameraMaxZoomDistance = 12  -- Default Roblox zoom
        ZoomToggle.Text = "Infinite Zoom: OFF"
        ZoomToggle.TextColor3 = Color3.fromRGB(255, 100, 100)
        ZoomToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    end
end)

-- Toggle Camera Noclip function
NoclipToggle.MouseButton1Click:Connect(function()
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
end)

-- Close GUI function
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Draggable GUI functionality
local UserInputService = game:GetService("UserInputService")
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

MainFrame.InputBegan:Connect(function(input)
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

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Status indicator
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.9, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Drag to move • Click buttons"
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusLabel.TextSize = 12

-- Optional: Add hotkey support (press Z for zoom, N for noclip)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Z then
        ZoomToggle.MouseButton1Click:Fire()
    elseif input.KeyCode == Enum.KeyCode.N then
        NoclipToggle.MouseButton1Click:Fire()
    elseif input.KeyCode == Enum.KeyCode.X then
        CloseButton.MouseButton1Click:Fire()
    end
end)

print("Camera Tools GUI loaded! Press Z to toggle Zoom, N for Noclip, X to close")