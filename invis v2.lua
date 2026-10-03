--[[
Invisible Body Parts Toggle Script
Creates a GUI to toggle body part transparency on/off
]]

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local ToggleButton = Instance.new("TextButton")
local Status = Instance.new("TextLabel")

-- GUI Properties
ScreenGui.Name = "InvisibilityGUI"
ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

Frame.Name = "MainFrame"
Frame.Parent = ScreenGui
Frame.Size = UDim2.new(0, 200, 0, 150)
Frame.Position = UDim2.new(0.5, -100, 0, 20)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

Title.Name = "Title"
Title.Parent = Frame
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "Invisibility Toggle"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20

ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = Frame
ToggleButton.Size = UDim2.new(0.8, 0, 0, 40)
ToggleButton.Position = UDim2.new(0.1, 0, 0.3, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 18
ToggleButton.Text = "TOGGLE"

Status.Name = "Status"
Status.Parent = Frame
Status.Size = UDim2.new(1, 0, 0, 40)
Status.Position = UDim2.new(0, 0, 0.7, 0)
Status.BackgroundTransparency = 1
Status.TextColor3 = Color3.fromRGB(255, 255, 255)
Status.Font = Enum.Font.SourceSans
Status.TextSize = 16
Status.Text = "Status: OFF"

-- Variables
local isInvisible = false
local character = game:GetService("Players").LocalPlayer.Character or game:GetService("Players").LocalPlayer.CharacterAdded:Wait()

-- Function to toggle visibility
local function setInvisibility(value)
    isInvisible = value
    
    if isInvisible then
        Status.Text = "Status: ON"
        Status.TextColor3 = Color3.fromRGB(0, 255, 0)
        ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 100, 30)
    else
        Status.Text = "Status: OFF"
        Status.TextColor3 = Color3.fromRGB(255, 50, 50)
        ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
    
    -- Make character invisible/visible
    if character then
        local transparency = isInvisible and 1 or 0
        
        -- R6 Parts
        if character:FindFirstChild("Head") then
            character.Head.Transparency = transparency
        end
        
        if character:FindFirstChild("Torso") then
            character.Torso.Transparency = transparency
        end
        
        if character:FindFirstChild("Left Arm") then
            character["Left Arm"].Transparency = transparency
        end
        
        if character:FindFirstChild("Right Arm") then
            character["Right Arm"].Transparency = transparency
        end
        
        if character:FindFirstChild("Left Leg") then
            character["Left Leg"].Transparency = transparency
        end
        
        if character:FindFirstChild("Right Leg") then
            character["Right Leg"].Transparency = transparency
        end
        
        -- R15 Parts
        local r15Parts = {
            "UpperTorso", "LowerTorso",
            "LeftUpperArm", "LeftLowerArm", "LeftHand",
            "RightUpperArm", "RightLowerArm", "RightHand",
            "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
            "RightUpperLeg", "RightLowerLeg", "RightFoot"
        }
        
        for _, partName in ipairs(r15Parts) do
            local part = character:FindFirstChild(partName)
            if part then
                part.Transparency = transparency
            end
        end
        
        -- Handle accessories (hats, etc.)
        for _, child in pairs(character:GetChildren()) do
            if child:IsA("Accessory") and child:FindFirstChild("Handle") then
                child.Handle.Transparency = transparency
            end
        end
    end
end

-- Handle character respawns
game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(newChar)
    character = newChar
    wait(1) -- Wait for character to fully load
    if isInvisible then
        setInvisibility(true) -- Reapply invisibility on respawn
    end
end)

-- Toggle button click event
ToggleButton.MouseButton1Click:Connect(function()
    setInvisibility(not isInvisible)
end)

-- Initialize with invisibility off
setInvisible(false)

-- Close button (optional, uncomment if you want it)
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Parent = Frame
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -30, 0, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Text = "X"
CloseButton.TextSize = 18

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

print("Invisibility GUI loaded! Drag the window to move it.")