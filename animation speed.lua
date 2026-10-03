-- Speed Hack GUI
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Create GUI
local SpeedHackGUI = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local SpeedLabel = Instance.new("TextLabel")
local SpeedValue = Instance.new("TextLabel")
local SpeedSlider = Instance.new("TextButton")
local ToggleButton = Instance.new("TextButton")

-- GUI Properties
SpeedHackGUI.Name = "SpeedHackGUI"
SpeedHackGUI.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

MainFrame.Name = "MainFrame"
MainFrame.Parent = SpeedHackGUI
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
MainFrame.Size = UDim2.new(0, 250, 0, 180)
MainFrame.Active = true
MainFrame.Draggable = true

Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "Animation Speed Hack"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18

SpeedLabel.Name = "SpeedLabel"
SpeedLabel.Parent = MainFrame
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Position = UDim2.new(0.1, 0, 0.3, 0)
SpeedLabel.Size = UDim2.new(0.4, 0, 0, 30)
SpeedLabel.Font = Enum.Font.SourceSans
SpeedLabel.Text = "Speed Multiplier:"
SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedLabel.TextSize = 16
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left

SpeedValue.Name = "SpeedValue"
SpeedValue.Parent = MainFrame
SpeedValue.BackgroundTransparency = 1
SpeedValue.Position = UDim2.new(0.6, 0, 0.3, 0)
SpeedValue.Size = UDim2.new(0.3, 0, 0, 30)
SpeedValue.Font = Enum.Font.SourceSansBold
SpeedValue.Text = "15x"
SpeedValue.TextColor3 = Color3.fromRGB(0, 255, 0)
SpeedValue.TextSize = 18

SpeedSlider.Name = "SpeedSlider"
SpeedSlider.Parent = MainFrame
SpeedSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
SpeedSlider.BorderSizePixel = 0
SpeedSlider.Position = UDim2.new(0.1, 0, 0.5, 0)
SpeedSlider.Size = UDim2.new(0.8, 0, 0, 20)
SpeedSlider.Font = Enum.Font.SourceSans
SpeedSlider.Text = ""
SpeedSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedSlider.TextSize = 14

ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = MainFrame
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
ToggleButton.BorderSizePixel = 0
ToggleButton.Position = UDim2.new(0.2, 0, 0.75, 0)
ToggleButton.Size = UDim2.new(0.6, 0, 0, 40)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "ENABLED"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 18

-- Variables
local enabled = true
local currentSpeed = 15
local connection = nil
local isDraggingSlider = false

-- Speed slider visual
local sliderFill = Instance.new("Frame")
sliderFill.Name = "SliderFill"
sliderFill.Parent = SpeedSlider
sliderFill.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
sliderFill.BorderSizePixel = 0
sliderFill.Size = UDim2.new(1, 0, 1, 0)

-- Function to update speed value
local function updateSpeed(value)
    currentSpeed = math.clamp(math.floor(value), 1, 100)
    SpeedValue.Text = currentSpeed .. "x"
    
    -- Update slider fill
    local fillRatio = currentSpeed / 100
    sliderFill.Size = UDim2.new(fillRatio, 0, 1, 0)
    
    -- Change color based on speed
    if currentSpeed <= 5 then
        sliderFill.BackgroundColor3 = Color3.fromRGB(0, 200, 0) -- Green
        SpeedValue.TextColor3 = Color3.fromRGB(0, 255, 0)
    elseif currentSpeed <= 20 then
        sliderFill.BackgroundColor3 = Color3.fromRGB(200, 200, 0) -- Yellow
        SpeedValue.TextColor3 = Color3.fromRGB(255, 255, 0)
    else
        sliderFill.BackgroundColor3 = Color3.fromRGB(200, 0, 0) -- Red
        SpeedValue.TextColor3 = Color3.fromRGB(255, 50, 50)
    end
end

-- Initialize speed
updateSpeed(currentSpeed)

-- Slider dragging logic
SpeedSlider.MouseButton1Down:Connect(function()
    isDraggingSlider = true
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDraggingSlider = false
    end
end)

SpeedSlider.MouseMoved:Connect(function()
    if isDraggingSlider then
        local mousePosition = UserInputService:GetMouseLocation()
        local sliderAbsolutePosition = SpeedSlider.AbsolutePosition
        local sliderAbsoluteSize = SpeedSlider.AbsoluteSize
        
        local relativeX = (mousePosition.X - sliderAbsolutePosition.X) / sliderAbsoluteSize.X
        relativeX = math.clamp(relativeX, 0, 1)
        
        updateSpeed(1 + math.floor(relativeX * 99))
    end
end)

-- Toggle button functionality
ToggleButton.MouseButton1Click:Connect(function()
    enabled = not enabled
    
    if enabled then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        ToggleButton.Text = "ENABLED"
        SpeedValue.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(215, 50, 0)
        ToggleButton.Text = "DISABLED"
        SpeedValue.TextColor3 = Color3.fromRGB(255, 50, 50)
    end
end)

-- Main speed hack logic
local function startSpeedHack()
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    
    while wait() do
        if not enabled then
            -- If disabled, reset any previously sped up animations
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid") or character:FindFirstChildOfClass("AnimationController")
                if humanoid then
                    for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                        track:AdjustSpeed(1) -- Reset to normal speed
                    end
                end
            end
            continue
        end
        
        if not character then
            character = player.Character or player.CharacterAdded:Wait()
        end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid") or character:FindFirstChildOfClass("AnimationController")
        if not humanoid or not character then 
            continue 
        end
        
        -- Apply speed multiplier to all playing animations
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            if track and track.IsPlaying then
                track:AdjustSpeed(currentSpeed)
            end
        end
    end
end

-- Start the script
spawn(startSpeedHack)

-- Add a close button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Parent = MainFrame
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseButton.BorderSizePixel = 0
CloseButton.Position = UDim2.new(0.9, -25, 0, 5)
CloseButton.Size = UDim2.new(0, 20, 0, 20)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 14

CloseButton.MouseButton1Click:Connect(function()
    SpeedHackGUI:Destroy()
end)

-- Add a minimize button
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Parent = MainFrame
MinimizeButton.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Position = UDim2.new(0.8, -25, 0, 5)
MinimizeButton.Size = UDim2.new(0, 20, 0, 20)
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.Text = "_"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.TextSize = 14

local isMinimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 250, 0, 30)
        Title.Size = UDim2.new(1, 0, 1, 0)
    else
        MainFrame.Size = UDim2.new(0, 250, 0, 180)
        Title.Size = UDim2.new(1, 0, 0, 30)
    end
end)