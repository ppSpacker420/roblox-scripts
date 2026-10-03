-- Utility function to create buttons with rounded corners
local function createButton(parent, position, size, bgColor, text, scaled)
    local button = Instance.new("TextButton")
    button.Parent = parent
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = bgColor
    button.Text = text
    button.TextScaled = scaled
    button.BorderSizePixel = 0

    -- Rounded corners for a modern look
    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0, 5)
    uicorner.Parent = button

    return button
end

-- Create ScreenGui with optional rounded background for the frame
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Parent = screenGui
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.Size = UDim2.new(0, 220, 0, 240)
frame.Position = UDim2.new(0.5, -110, 0.5, -120)
frame.Active = true
frame.Draggable = true

local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0, 10)
uicorner.Parent = frame

-- TextBox for player input
local playerInput = Instance.new("TextBox")
playerInput.Parent = frame
playerInput.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
playerInput.Size = UDim2.new(0, 180, 0, 30)
playerInput.Position = UDim2.new(0, 20, 0, 20)
playerInput.PlaceholderText = "Enter Player Name"
playerInput.TextScaled = true
playerInput.TextColor3 = Color3.fromRGB(0, 0, 0)

-- Create Buttons: On, Off, Destroy, and Increase/Decrease Distance
local onButton = createButton(frame, UDim2.new(0, 20, 0, 60), UDim2.new(0, 80, 0, 30), Color3.fromRGB(0, 255, 0), "On", true)
local offButton = createButton(frame, UDim2.new(0, 120, 0, 60), UDim2.new(0, 80, 0, 30), Color3.fromRGB(255, 0, 0), "Off", true)
local destroyButton = createButton(frame, UDim2.new(0, 20, 0, 100), UDim2.new(0, 180, 0, 30), Color3.fromRGB(255, 255, 255), "Destroy", true)
local plusButton = createButton(frame, UDim2.new(0, 20, 0, 140), UDim2.new(0, 40, 0, 30), Color3.fromRGB(0, 255, 255), "+", true)
local minusButton = createButton(frame, UDim2.new(0, 160, 0, 140), UDim2.new(0, 40, 0, 30), Color3.fromRGB(255, 165, 0), "-", true)

-- Add "Idle Range" button
local idleToggleButton = createButton(frame, UDim2.new(0, 20, 0, 180), UDim2.new(0, 180, 0, 30), Color3.fromRGB(100, 100, 255), "Idle: ON", true)

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = frame
statusLabel.Size = UDim2.new(0, 220, 0, 30)
statusLabel.Position = UDim2.new(0, 0, 0, -30)
statusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
statusLabel.Text = "Status: Off"
statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.SourceSansBold

-- Distance Labels
local followDistanceLabel = Instance.new("TextLabel")
followDistanceLabel.Parent = frame
followDistanceLabel.Size = UDim2.new(0, 100, 0, 20)
followDistanceLabel.Position = UDim2.new(0, 65, 0, 140)
followDistanceLabel.BackgroundTransparency = 1
followDistanceLabel.Text = "Follow: 10"
followDistanceLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
followDistanceLabel.TextScaled = true
followDistanceLabel.Font = Enum.Font.SourceSansBold

local dodgeDistanceLabel = Instance.new("TextLabel")
dodgeDistanceLabel.Parent = frame
dodgeDistanceLabel.Size = UDim2.new(0, 100, 0, 20)
dodgeDistanceLabel.Position = UDim2.new(0, 65, 0, 160)
dodgeDistanceLabel.BackgroundTransparency = 1
dodgeDistanceLabel.Text = "Dodge: 9.9"
dodgeDistanceLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
dodgeDistanceLabel.TextScaled = true
dodgeDistanceLabel.Font = Enum.Font.SourceSansBold

-- Variables for managing distances
local followDistance = 10
local dodgeDistance = 9.9
local idleRangeEnabled = true
local lookAtEnabled = false
local orbitAngle = 0

-- Function to find a player by partial name
local function findPlayerByName(partialName)
    partialName = string.lower(partialName)
    for _, player in pairs(game.Players:GetPlayers()) do
        if string.find(string.lower(player.Name), partialName) or string.find(string.lower(player.DisplayName), partialName) then
            return player
        end
    end
    return nil
end

-- Function to move to player (used when idle is ON)
local function moveToPlayer(targetPlayer)
    local localPlayer = game.Players.LocalPlayer
    local localChar = localPlayer.Character
    local localRootPart = localChar and localChar:FindFirstChild("HumanoidRootPart")
    local targetRootPart = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not (localRootPart and targetRootPart and localChar.Humanoid) then
        return
    end

    local distance = (localRootPart.Position - targetRootPart.Position).Magnitude
    
    -- FIXED: Proper dodge distance logic
    -- If we're too close (closer than dodgeDistance), move away
    if distance < dodgeDistance then
        local direction = (targetRootPart.Position - localRootPart.Position).unit
        -- Move to dodgeDistance from the target
        local destination = targetRootPart.Position - (direction * dodgeDistance)
        localChar.Humanoid:MoveTo(destination)
        return false  -- Still moving
    end
    
    -- If we're within the stand-still range (between dodgeDistance and followDistance)
    if distance >= dodgeDistance and distance <= followDistance then
        -- Stop moving - we're at the right distance
        localChar.Humanoid:Move(Vector3.new(0, 0, 0))
        return true  -- Reached target and standing still
    end
    
    -- If we're farther than followDistance, move closer
    if distance > followDistance then
        local direction = (targetRootPart.Position - localRootPart.Position).unit
        -- Move to followDistance from the target
        local destination = targetRootPart.Position - (direction * followDistance)
        localChar.Humanoid:MoveTo(destination)
        return false  -- Still moving
    end
    
    -- Default: stand still
    localChar.Humanoid:Move(Vector3.new(0, 0, 0))
    return true
end

-- Function for circular movement around the target
local function circleAroundPlayer(targetPlayer)
    local localPlayer = game.Players.LocalPlayer
    local localChar = localPlayer.Character
    local localRootPart = localChar and localChar:FindFirstChild("HumanoidRootPart")
    local targetRootPart = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not (localRootPart and targetRootPart and localChar.Humanoid) then
        return
    end

    -- Increment the angle for the next position on the circle
    orbitAngle = orbitAngle + 0.05 -- Controls the speed of the orbit

    -- Calculate the new position on a circle around the target
    -- followDistance acts as the orbit radius
    local offsetX = math.cos(orbitAngle) * followDistance
    local offsetZ = math.sin(orbitAngle) * followDistance
    local orbitPosition = targetRootPart.Position + Vector3.new(offsetX, 0, offsetZ)

    -- Optional: Adjust for terrain height (simple version)
    local rayOrigin = Vector3.new(orbitPosition.X, targetRootPart.Position.Y + 50, orbitPosition.Z)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {localChar, targetPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true

    local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -100, 0), raycastParams)
    if rayResult then
        orbitPosition = Vector3.new(orbitPosition.X, rayResult.Position.Y + 3, orbitPosition.Z)
    else
        orbitPosition = Vector3.new(orbitPosition.X, targetRootPart.Position.Y, orbitPosition.Z)
    end

    -- Move the character to the calculated orbit position
    localChar.Humanoid:MoveTo(orbitPosition)
end

-- Update distance labels
local function updateDistanceLabels()
    followDistanceLabel.Text = "Follow: " .. string.format("%.1f", followDistance)
    dodgeDistanceLabel.Text = "Dodge: " .. string.format("%.1f", dodgeDistance)
end

-- Loop for following player
local followLoop
local function startFollowing()
    if followLoop then return end
    followLoop = game:GetService("RunService").Heartbeat:Connect(function()
        if lookAtEnabled then
            local targetPlayer = findPlayerByName(playerInput.Text)
            if targetPlayer then
                -- If idle is ON: Move to player and maintain distance
                -- If idle is OFF: Circle around the player
                if idleRangeEnabled then
                    moveToPlayer(targetPlayer)
                else
                    circleAroundPlayer(targetPlayer)
                end
            end
        end
    end)
end

local function stopFollowing()
    if followLoop then
        followLoop:Disconnect()
        followLoop = nil
    end
end

-- Update status label
local function updateStatusLabel()
    if lookAtEnabled then
        if idleRangeEnabled then
            statusLabel.Text = "Status: Following"
        else
            statusLabel.Text = "Status: Circling"
        end
    else
        statusLabel.Text = "Status: Off"
    end
end

-- Toggle idle range function
local function toggleIdleRange()
    idleRangeEnabled = not idleRangeEnabled
    if idleRangeEnabled then
        idleToggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
        idleToggleButton.Text = "Idle: ON"
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green for following
    else
        idleToggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 120)
        idleToggleButton.Text = "Idle: OFF"
        statusLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange for circling
    end
    updateStatusLabel()
end

-- Button Event Listeners
plusButton.MouseButton1Click:Connect(function()
    followDistance = math.min(30, followDistance + 1)
    dodgeDistance = math.min(followDistance - 0.1, dodgeDistance + 1)
    updateDistanceLabels()
    updateStatusLabel()
end)

minusButton.MouseButton1Click:Connect(function()
    followDistance = math.max(dodgeDistance + 0.1, followDistance - 1)
    dodgeDistance = math.max(1, dodgeDistance - 1)
    updateDistanceLabels()
    updateStatusLabel()
end)

onButton.MouseButton1Click:Connect(function()
    lookAtEnabled = true
    updateStatusLabel()
    if idleRangeEnabled then
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green for following
    else
        statusLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange for circling
    end
    startFollowing()
end)

offButton.MouseButton1Click:Connect(function()
    lookAtEnabled = false
    statusLabel.Text = "Status: Off"
    statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    stopFollowing()
end)

destroyButton.MouseButton1Click:Connect(function()
    lookAtEnabled = false
    stopFollowing()
    screenGui:Destroy()
end)

-- Idle range toggle button
idleToggleButton.MouseButton1Click:Connect(toggleIdleRange)

-- Initialize
updateDistanceLabels()
if idleRangeEnabled then
    idleToggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    idleToggleButton.Text = "Idle: ON"
else
    idleToggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 120)
    idleToggleButton.Text = "Idle: OFF"
end

-- Clean up when character dies
game.Players.LocalPlayer.CharacterAdded:Connect(function()
    if lookAtEnabled then
        orbitAngle = 0 -- Reset orbit angle on respawn
    end
end)