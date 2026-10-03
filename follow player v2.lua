-- Utility function to create modern buttons
local function createButton(parent, position, size, bgColor, text, textColor)
    local button = Instance.new("TextButton")
    button.Parent = parent
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = bgColor
    button.Text = text
    button.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Font = Enum.Font.GothamSemibold
    
    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 8)
    uicorner.Parent = button
    
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Parent = button
    uiStroke.Color = Color3.fromRGB(60, 60, 60)
    uiStroke.Thickness = 2
    
    return button
end

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerFollowGUI"
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main container with gradient
local container = Instance.new("Frame")
container.Parent = screenGui
container.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
container.Size = UDim2.new(0, 300, 0, 360)
container.Position = UDim2.new(0.5, -150, 0.5, -180)
container.Active = true
container.Draggable = true
container.ClipsDescendants = true

-- Add shadow effect
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.Parent = container
shadow.Size = UDim2.new(1, 10, 1, 10)
shadow.Position = UDim2.new(0, -5, 0, -5)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.8
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.ZIndex = -1

local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0, 12)
uicorner.Parent = container

local uiStroke = Instance.new("UIStroke")
uiStroke.Parent = container
uiStroke.Color = Color3.fromRGB(80, 80, 100)
uiStroke.Thickness = 2

-- Title bar with gradient
local titleBar = Instance.new("Frame")
titleBar.Parent = container
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.Active = true
titleBar.Draggable = true

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12, 0, 0)
titleCorner.Parent = titleBar

local title = Instance.new("TextLabel")
title.Parent = titleBar
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "Player Follow System"
title.TextColor3 = Color3.fromRGB(220, 220, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Center

local dragIcon = Instance.new("ImageLabel")
dragIcon.Parent = titleBar
dragIcon.Size = UDim2.new(0, 20, 0, 20)
dragIcon.Position = UDim2.new(0, 10, 0.5, -10)
dragIcon.BackgroundTransparency = 1
dragIcon.Image = "rbxassetid://3926305904"
dragIcon.ImageRectOffset = Vector2.new(964, 324)
dragIcon.ImageRectSize = Vector2.new(36, 36)
dragIcon.ImageColor3 = Color3.fromRGB(180, 180, 220)

-- Content area
local content = Instance.new("Frame")
content.Parent = container
content.BackgroundTransparency = 1
content.Size = UDim2.new(1, -40, 1, -60)
content.Position = UDim2.new(0, 20, 0, 50)

-- Player input with icon
local inputFrame = Instance.new("Frame")
inputFrame.Parent = content
inputFrame.Size = UDim2.new(1, 0, 0, 40)
inputFrame.Position = UDim2.new(0, 0, 0, 0)
inputFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 8)
inputCorner.Parent = inputFrame

local playerIcon = Instance.new("ImageLabel")
playerIcon.Parent = inputFrame
playerIcon.Size = UDim2.new(0, 24, 0, 24)
playerIcon.Position = UDim2.new(0, 10, 0.5, -12)
playerIcon.BackgroundTransparency = 1
playerIcon.Image = "rbxassetid://3926305904"
playerIcon.ImageRectOffset = Vector2.new(4, 644)
playerIcon.ImageRectSize = Vector2.new(36, 36)
playerIcon.ImageColor3 = Color3.fromRGB(180, 180, 220)

local playerInput = Instance.new("TextBox")
playerInput.Parent = inputFrame
playerInput.BackgroundTransparency = 1
playerInput.Size = UDim2.new(1, -50, 1, 0)
playerInput.Position = UDim2.new(0, 40, 0, 0)
playerInput.PlaceholderText = "Enter Player Name or Display Name"
playerInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 170)
playerInput.TextScaled = true
playerInput.TextColor3 = Color3.fromRGB(240, 240, 255)
playerInput.Font = Enum.Font.Gotham
playerInput.ClearTextOnFocus = false

-- Control buttons in a grid
local controlGrid = Instance.new("Frame")
controlGrid.Parent = content
controlGrid.Size = UDim2.new(1, 0, 0, 120)
controlGrid.Position = UDim2.new(0, 0, 0, 60)
controlGrid.BackgroundTransparency = 1

local onButton = createButton(controlGrid, UDim2.new(0, 0, 0, 0), UDim2.new(0.48, 0, 0, 50), 
    Color3.fromRGB(50, 180, 80), "ON", Color3.fromRGB(255, 255, 255))
local offButton = createButton(controlGrid, UDim2.new(0.52, 0, 0, 0), UDim2.new(0.48, 0, 0, 50), 
    Color3.fromRGB(180, 50, 50), "OFF", Color3.fromRGB(255, 255, 255))

local destroyButton = createButton(controlGrid, UDim2.new(0, 0, 0, 60), UDim2.new(1, 0, 0, 50), 
    Color3.fromRGB(70, 70, 90), "DESTROY GUI", Color3.fromRGB(255, 100, 100))

-- Distance controls
local distanceFrame = Instance.new("Frame")
distanceFrame.Parent = content
distanceFrame.Size = UDim2.new(1, 0, 0, 80)
distanceFrame.Position = UDim2.new(0, 0, 0, 190)
distanceFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
distanceFrame.BackgroundTransparency = 0.5

local distanceCorner = Instance.new("UICorner")
distanceCorner.CornerRadius = UDim.new(0, 8)
distanceCorner.Parent = distanceFrame

local distanceLabel = Instance.new("TextLabel")
distanceLabel.Parent = distanceFrame
distanceLabel.Size = UDim2.new(1, 0, 0, 30)
distanceLabel.Position = UDim2.new(0, 0, 0, 5)
distanceLabel.BackgroundTransparency = 1
distanceLabel.Text = "Follow Distance"
distanceLabel.TextColor3 = Color3.fromRGB(200, 200, 230)
distanceLabel.TextScaled = true
distanceLabel.Font = Enum.Font.GothamSemibold

local distanceValue = Instance.new("TextLabel")
distanceValue.Parent = distanceFrame
distanceValue.Size = UDim2.new(0, 60, 0, 30)
distanceValue.Position = UDim2.new(0.5, -30, 0, 40)
distanceValue.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
distanceValue.Text = "10"
distanceValue.TextColor3 = Color3.fromRGB(100, 200, 255)
distanceValue.TextScaled = true
distanceValue.Font = Enum.Font.GothamBold

local distanceCorner2 = Instance.new("UICorner")
distanceCorner2.CornerRadius = UDim.new(0, 6)
distanceCorner2.Parent = distanceValue

local minusButton = createButton(distanceFrame, UDim2.new(0, 20, 0, 40), UDim2.new(0, 30, 0, 30),
    Color3.fromRGB(200, 100, 50), "-", Color3.fromRGB(255, 255, 255))
local plusButton = createButton(distanceFrame, UDim2.new(1, -50, 0, 40), UDim2.new(0, 30, 0, 30),
    Color3.fromRGB(50, 150, 200), "+", Color3.fromRGB(255, 255, 255))

-- Status display
local statusFrame = Instance.new("Frame")
statusFrame.Parent = content
statusFrame.Size = UDim2.new(1, 0, 0, 40)
statusFrame.Position = UDim2.new(0, 0, 1, -40)
statusFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 8)
statusCorner.Parent = statusFrame

local statusIcon = Instance.new("ImageLabel")
statusIcon.Parent = statusFrame
statusIcon.Size = UDim2.new(0, 20, 0, 20)
statusIcon.Position = UDim2.new(0, 10, 0.5, -10)
statusIcon.BackgroundTransparency = 1
statusIcon.Image = "rbxassetid://3926305904"
statusIcon.ImageRectOffset = Vector2.new(324, 364)
statusIcon.ImageRectSize = Vector2.new(36, 36)
statusIcon.ImageColor3 = Color3.fromRGB(255, 50, 50)

local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = statusFrame
statusLabel.Size = UDim2.new(1, -40, 1, 0)
statusLabel.Position = UDim2.new(0, 40, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Offline"
statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize button
local minimizeButton = Instance.new("TextButton")
minimizeButton.Parent = titleBar
minimizeButton.Size = UDim2.new(0, 20, 0, 20)
minimizeButton.Position = UDim2.new(1, -30, 0.5, -10)
minimizeButton.BackgroundTransparency = 1
minimizeButton.Text = "_"
minimizeButton.TextColor3 = Color3.fromRGB(180, 180, 220)
minimizeButton.TextScaled = true
minimizeButton.Font = Enum.Font.GothamBold

-- Variables
local followDistance = 10
local dodgeDistance = 9.5
local lookAtEnabled = false
local followLoop = nil
local minimized = false
local lastTarget = nil

-- Enhanced player finding with autocomplete
local function findPlayerByName(partialName)
    if partialName == "" then return nil end
    partialName = string.lower(partialName:gsub("%s+", ""))
    
    -- Check for exact match first
    for _, player in pairs(game.Players:GetPlayers()) do
        if player.Name:lower() == partialName or player.DisplayName:lower() == partialName then
            return player
        end
    end
    
    -- Check for partial matches
    for _, player in pairs(game.Players:GetPlayers()) do
        if string.find(player.Name:lower(), partialName) or 
           string.find(player.DisplayName:lower(), partialName) then
            return player
        end
    end
    
    return nil
end

-- Advanced movement with pathfinding
local function moveToPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    
    local localPlayer = game.Players.LocalPlayer
    local localChar = localPlayer.Character
    if not localChar then return end
    
    local humanoid = localChar:FindFirstChild("Humanoid")
    local humanoidRootPart = localChar:FindFirstChild("HumanoidRootPart")
    local targetRootPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not humanoidRootPart or not targetRootPart then return end
    
    local distance = (humanoidRootPart.Position - targetRootPart.Position).Magnitude
    
    -- Update status with distance
    if lookAtEnabled then
        statusLabel.Text = string.format("Following: %s (%.1f studs)", targetPlayer.Name, distance)
    end
    
    -- Use pathfinding for complex movement
    if distance > followDistance + 1 then
        -- Calculate direction to target
        local direction = (targetRootPart.Position - humanoidRootPart.Position).unit
        local destination = targetRootPart.Position - (direction * followDistance)
        
        -- Simple obstacle avoidance
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {localChar}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.IgnoreWater = true
        
        local rayResult = workspace:Raycast(humanoidRootPart.Position, direction * (followDistance + 5), raycastParams)
        
        if rayResult then
            -- Obstacle detected, try dodging
            local rightVector = humanoidRootPart.CFrame.RightVector
            local leftVector = -rightVector
            
            -- Try moving right first, then left
            local dodgeRay = workspace:Raycast(humanoidRootPart.Position, rightVector * 10, raycastParams)
            if not dodgeRay then
                destination = humanoidRootPart.Position + (rightVector * 5)
            else
                dodgeRay = workspace:Raycast(humanoidRootPart.Position, leftVector * 10, raycastParams)
                if not dodgeRay then
                    destination = humanoidRootPart.Position + (leftVector * 5)
                else
                    -- Jump if stuck
                    humanoid.Jump = true
                end
            end
        end
        
        -- Smooth movement with lerp
        humanoid:MoveTo(destination)
        
        -- Look at target
        humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, 
            Vector3.new(targetRootPart.Position.X, humanoidRootPart.Position.Y, targetRootPart.Position.Z))
        
    elseif distance < dodgeDistance then
        -- Move away if too close
        local retreatDirection = (humanoidRootPart.Position - targetRootPart.Position).unit
        local retreatPosition = humanoidRootPart.Position + (retreatDirection * dodgeDistance)
        humanoid:MoveTo(retreatPosition)
    end
end

-- Start/stop following
local function startFollowing()
    if followLoop then return end
    
    local targetPlayer = findPlayerByName(playerInput.Text)
    if not targetPlayer then
        statusLabel.Text = "Error: Player not found"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        statusIcon.ImageColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    
    lastTarget = targetPlayer
    lookAtEnabled = true
    
    -- Update UI
    statusLabel.Text = string.format("Following: %s", targetPlayer.Name)
    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    statusIcon.ImageColor3 = Color3.fromRGB(100, 255, 100)
    statusIcon.ImageRectOffset = Vector2.new(84, 204)
    
    onButton.BackgroundColor3 = Color3.fromRGB(30, 150, 60)
    offButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    
    -- Start follow loop
    followLoop = game:GetService("RunService").Heartbeat:Connect(function()
        if lookAtEnabled and targetPlayer and targetPlayer.Character then
            moveToPlayer(targetPlayer)
        end
    end)
end

local function stopFollowing()
    lookAtEnabled = false
    
    -- Update UI
    statusLabel.Text = "Status: Offline"
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    statusIcon.ImageColor3 = Color3.fromRGB(255, 100, 100)
    statusIcon.ImageRectOffset = Vector2.new(324, 364)
    
    onButton.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
    offButton.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
    
    -- Stop follow loop
    if followLoop then
        followLoop:Disconnect()
        followLoop = nil
    end
end

-- Toggle minimize
minimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    
    if minimized then
        container.Size = UDim2.new(0, 300, 0, 40)
        minimizeButton.Text = "+"
    else
        container.Size = UDim2.new(0, 300, 0, 360)
        minimizeButton.Text = "_"
    end
end)

-- Button events
onButton.MouseButton1Click:Connect(startFollowing)

offButton.MouseButton1Click:Connect(stopFollowing)

plusButton.MouseButton1Click:Connect(function()
    followDistance = math.min(50, followDistance + 1)
    dodgeDistance = math.max(1, followDistance - 0.5)
    distanceValue.Text = tostring(followDistance)
end)

minusButton.MouseButton1Click:Connect(function()
    followDistance = math.max(1, followDistance - 1)
    dodgeDistance = math.max(1, followDistance - 0.5)
    distanceValue.Text = tostring(followDistance)
end)

destroyButton.MouseButton1Click:Connect(function()
    stopFollowing()
    screenGui:Destroy()
end)

-- Autocomplete suggestion
playerInput.Focused:Connect(function()
    if playerInput.Text == "" then
        local players = game.Players:GetPlayers()
        if #players > 0 then
            playerInput.PlaceholderText = "Try: " .. players[1].Name
        end
    end
end)

playerInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        startFollowing()
    end
end)

-- Update status when target leaves
game.Players.PlayerRemoving:Connect(function(player)
    if lastTarget and player == lastTarget then
        stopFollowing()
        statusLabel.Text = "Target left game"
    end
end)

-- Initial UI update
stopFollowing()