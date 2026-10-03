-- Utility function to create buttons with rounded corners
--https://raw.githubusercontent.com/ScpGuest666/Random-Roblox-script/refs/heads/main/Roblox%20follow%20player%20script
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

-- Variables for managing distances
local followDistance = 10
local dodgeDistance = 9.9
local idleRangeEnabled = true  -- New variable for idle range feature
local lookAtEnabled = false
local lastMoveTime = 0  -- Track when we last moved
local idleCheckDelay = 0.5  -- How often to check if we should stand still

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

-- Enhanced movement function with smarter obstacle avoidance and idle range
local function moveToPlayer(targetPlayer)
    local localPlayer = game.Players.LocalPlayer
    local localChar = localPlayer.Character
    local localRootPart = localChar and localChar:FindFirstChild("HumanoidRootPart")
    local targetRootPart = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not (localRootPart and targetRootPart and localChar.Humanoid) then
        return
    end

    local distance = (localRootPart.Position - targetRootPart.Position).Magnitude
    
    -- Calculate idle range (slightly larger than dodge distance to prevent constant movement)
    local idleRange = dodgeDistance + 1.5
    
    -- If idle range is enabled and we're within idle range, stand still
    if idleRangeEnabled and distance <= idleRange then
        -- Stop moving by setting MoveDirection to zero
        localChar.Humanoid:Move(Vector3.new(0, 0, 0))
        return  -- Exit early, don't move at all
    end
    
    -- If we're within the perfect follow distance range (with small buffer), stand still
    if math.abs(distance - followDistance) <= 0.5 then
        -- Stop moving by setting MoveDirection to zero
        localChar.Humanoid:Move(Vector3.new(0, 0, 0))
        return  -- Exit early, don't move
    end
    
    -- Only move if we're outside the acceptable range
    if distance > followDistance + 0.5 or distance < dodgeDistance then
        -- Define initial direction and destination
        local direction = (targetRootPart.Position - localRootPart.Position).unit
        local destination
        
        if distance > followDistance then
            -- Move closer
            destination = targetRootPart.Position - (direction * followDistance)
        else
            -- Move away if too close
            destination = localRootPart.Position - (direction * dodgeDistance)
        end

        -- Set up raycasting parameters for collision detection
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {localChar}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

        -- Check if destination is clear
        local rayResult = workspace:Raycast(localRootPart.Position, direction * followDistance, raycastParams)
        if rayResult then
            -- If collision detected, try alternative dodge directions
            local dodgeOptions = {
                Vector3.new(-direction.Z, 0, direction.X).unit,   -- Perpendicular left
                Vector3.new(direction.Z, 0, -direction.X).unit,   -- Perpendicular right
                direction * 0.5,                                  -- Halfway forward
                -direction                                        -- Opposite (back)
            }
            
            for _, dodgeDirection in ipairs(dodgeOptions) do
                local dodgePosition = localRootPart.Position + (dodgeDirection * dodgeDistance)
                local dodgeRayResult = workspace:Raycast(localRootPart.Position, dodgeDirection * dodgeDistance, raycastParams)
                
                -- Move to the first clear dodge position
                if not dodgeRayResult then
                    destination = dodgePosition
                    break
                end
            end
        end

        -- Smoothly move to the calculated destination
        localChar.Humanoid:MoveTo(destination)
        lastMoveTime = tick()
    else
        -- We're in the perfect distance range, stand still
        localChar.Humanoid:Move(Vector3.new(0, 0, 0))
    end
end

-- Loop for following/dodging player
local followLoop
local function startFollowing()
    if followLoop then return end
    followLoop = game:GetService("RunService").Heartbeat:Connect(function()
        if lookAtEnabled then
            local targetPlayer = findPlayerByName(playerInput.Text)
            if targetPlayer then
                moveToPlayer(targetPlayer)
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
        statusLabel.Text = "Status: On (Follow: " .. tostring(followDistance) .. " studs, Dodge: " .. tostring(dodgeDistance) .. " studs)"
        if idleRangeEnabled then
            statusLabel.Text = statusLabel.Text .. " [IDLE ON]"
        else
            statusLabel.Text = statusLabel.Text .. " [IDLE OFF]"
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
    else
        idleToggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 120)
        idleToggleButton.Text = "Idle: OFF"
    end
    updateStatusLabel()
end

-- Button Event Listeners
plusButton.MouseButton1Click:Connect(function()
    followDistance = math.min(30, followDistance + 1)
    dodgeDistance = math.min(30, dodgeDistance + 1)
    updateStatusLabel()
end)

minusButton.MouseButton1Click:Connect(function()
    followDistance = math.max(1, followDistance - 1)
    dodgeDistance = math.max(1, dodgeDistance - 1)
    updateStatusLabel()
end)

onButton.MouseButton1Click:Connect(function()
    lookAtEnabled = true
    updateStatusLabel()
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
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

-- Initialize idle range button text
if idleRangeEnabled then
    idleToggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    idleToggleButton.Text = "Idle: ON"
else
    idleToggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 120)
    idleToggleButton.Text = "Idle: OFF"
end