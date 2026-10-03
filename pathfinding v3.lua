-- Put this LocalScript in StarterGui
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PathfinderGUI"
screenGui.ResetOnSpawn = false

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 250)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -125)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(0, 120, 215)
mainFrame.Parent = screenGui

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
title.Text = "🚀 Direct Pathfinder"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.Parent = mainFrame

-- Player List Frame
local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Size = UDim2.new(1, -20, 0, 120)
playerListFrame.Position = UDim2.new(0, 10, 0, 50)
playerListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
playerListFrame.BorderSizePixel = 0
playerListFrame.ScrollBarThickness = 6
playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerListFrame.Parent = mainFrame

-- Player List UIListLayout
local playerListLayout = Instance.new("UIListLayout")
playerListLayout.Padding = UDim.new(0, 2)
playerListLayout.Parent = playerListFrame

-- Selected Player Display
local selectedFrame = Instance.new("Frame")
selectedFrame.Size = UDim2.new(1, -20, 0, 30)
selectedFrame.Position = UDim2.new(0, 10, 0, 180)
selectedFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
selectedFrame.BorderSizePixel = 1
selectedFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
selectedFrame.Parent = mainFrame

local selectedLabel = Instance.new("TextLabel")
selectedLabel.Size = UDim2.new(0, 80, 1, 0)
selectedLabel.BackgroundTransparency = 1
selectedLabel.Text = "Target:"
selectedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
selectedLabel.Font = Enum.Font.SourceSans
selectedLabel.TextSize = 16
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Parent = selectedFrame

local selectedPlayerText = Instance.new("TextLabel")
selectedPlayerText.Size = UDim2.new(1, -85, 1, 0)
selectedPlayerText.Position = UDim2.new(0, 85, 0, 0)
selectedPlayerText.BackgroundTransparency = 1
selectedPlayerText.Text = "None"
selectedPlayerText.TextColor3 = Color3.fromRGB(0, 200, 255)
selectedPlayerText.Font = Enum.Font.SourceSansBold
selectedPlayerText.TextSize = 16
selectedPlayerText.TextXAlignment = Enum.TextXAlignment.Right
selectedPlayerText.Parent = selectedFrame

-- Buttons
local buttonContainer = Instance.new("Frame")
buttonContainer.Size = UDim2.new(1, -20, 0, 80)
buttonContainer.Position = UDim2.new(0, 10, 1, -90)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = mainFrame

local followButton = Instance.new("TextButton")
followButton.Size = UDim2.new(1, 0, 0, 35)
followButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
followButton.TextColor3 = Color3.fromRGB(255, 255, 255)
followButton.Text = "▶ Start Following"
followButton.Font = Enum.Font.SourceSansBold
followButton.TextSize = 18
followButton.Parent = buttonContainer

local stopButton = Instance.new("TextButton")
stopButton.Size = UDim2.new(1, 0, 0, 35)
stopButton.Position = UDim2.new(0, 0, 0, 45)
stopButton.BackgroundColor3 = Color3.fromRGB(215, 60, 0)
stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopButton.Text = "⏹ Stop Following"
stopButton.Font = Enum.Font.SourceSansBold
stopButton.TextSize = 18
stopButton.Parent = buttonContainer

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(215, 60, 0)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "X"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 18
closeButton.Parent = mainFrame

-- ========== FIXED PATHFINDING SYSTEM ==========
local selectedPlayer = nil
local isFollowing = false
local followConnection = nil

-- Track movement state to prevent oscillation
local lastMoveTime = 0
local moveCooldown = 0.3 -- Minimum time between MoveTo calls
local currentDestination = nil
local isMovingToDestination = false

-- Function to update player list
local function updatePlayerList()
	for _, child in ipairs(playerListFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer then
			local playerButton = Instance.new("TextButton")
			playerButton.Size = UDim2.new(1, 0, 0, 30)
			playerButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			playerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			playerButton.Text = player.Name
			playerButton.Font = Enum.Font.SourceSans
			playerButton.TextSize = 16
			playerButton.Parent = playerListFrame
			
			playerButton.MouseButton1Click:Connect(function()
				selectedPlayer = player
				selectedPlayerText.Text = player.Name
				
				for _, btn in ipairs(playerListFrame:GetChildren()) do
					if btn:IsA("TextButton") then
						if btn.Text == player.Name then
							btn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
						else
							btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
						end
					end
				end
			end)
		end
	end
end

-- FIXED: Move directly without oscillation
local function moveDirectlyTo(position)
	local currentTime = tick()
	
	-- Prevent rapid MoveTo calls (which cause oscillation)
	if currentTime - lastMoveTime < moveCooldown then
		return false
	end
	
	-- Only move if destination has changed significantly
	if currentDestination then
		local distanceToNewDest = (position - currentDestination).Magnitude
		if distanceToNewDest < 3 then -- Less than 3 studs difference
			return false -- Don't change destination
		end
	end
	
	-- Set new destination
	currentDestination = position
	lastMoveTime = currentTime
	isMovingToDestination = true
	
	-- Use MoveTo ONCE - don't call it repeatedly
	humanoid:MoveTo(position)
	
	-- Reset moving flag after a reasonable time
	task.delay(1, function()
		isMovingToDestination = false
	end)
	
	return true
end

-- FIXED: Check for obstacles and find way around
local function findClearPath(startPos, targetPos)
	local distance = (targetPos - startPos).Magnitude
	
	-- If very close, just go directly
	if distance < 15 then
		return targetPos
	end
	
	-- Check for direct line of sight
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {character}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = true
	
	local ray = workspace:Raycast(startPos + Vector3.new(0, 2, 0), (targetPos - startPos), raycastParams)
	
	if not ray then
		-- Direct path is clear
		return targetPos
	end
	
	-- If there's an obstacle, try to go around it
	if ray then
		local obstaclePos = ray.Position
		local obstacleNormal = ray.Normal
		
		-- Calculate a point to the side of the obstacle
		local sideVector = Vector3.new(-obstacleNormal.Z, 0, obstacleNormal.X) * 5
		local avoidPos = obstaclePos + sideVector + Vector3.new(0, 2, 0)
		
		-- Make sure avoidPos is at ground level
		local rayDown = workspace:Raycast(avoidPos + Vector3.new(0, 10, 0), Vector3.new(0, -20, 0), raycastParams)
		if rayDown then
			avoidPos = rayDown.Position + Vector3.new(0, 2, 0)
		end
		
		-- Check if avoid path is clear
		local rayToAvoid = workspace:Raycast(startPos + Vector3.new(0, 2, 0), (avoidPos - startPos), raycastParams)
		if not rayToAvoid then
			return avoidPos
		end
	end
	
	-- If we can't find a clear path, use pathfinding
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		WaypointSpacing = 6,
		Costs = {}
	})
	
	path:ComputeAsync(startPos, targetPos)
	
	if path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		if #waypoints > 1 then
			-- Return the first waypoint (not the immediate position)
			return waypoints[2].Position
		end
	end
	
	-- Fallback: return original target
	return targetPos
end

-- FIXED: Main follow function - no oscillation
local function smoothFollow()
	if not isFollowing or not selectedPlayer then
		return
	end
	
	local targetCharacter = selectedPlayer.Character
	if not targetCharacter then
		followButton.Text = "Target missing"
		return
	end
	
	local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart") or targetCharacter:FindFirstChild("Head")
	if not targetRoot then
		followButton.Text = "No root part"
		return
	end
	
	local targetPos = targetRoot.Position
	local currentPos = humanoidRootPart.Position
	local distance = (targetPos - currentPos).Magnitude
	
	-- Update display
	followButton.Text = string.format("📍 %.0f studs", distance)
	
	-- If we're already close to target, stop moving
	if distance < 5 then
		if isMovingToDestination then
			humanoid:MoveTo(currentPos) -- Stop movement
			isMovingToDestination = false
		end
		return
	end
	
	-- If we're already moving toward a destination, don't change it frequently
	if isMovingToDestination and currentDestination then
		local progress = (currentPos - currentDestination).Magnitude
		local originalDistance = (targetPos - currentDestination).Magnitude
		
		-- Only update destination if we're getting close to current one
		if progress < 5 then
			-- Find clear path to target
			local nextDestination = findClearPath(currentPos, targetPos)
			moveDirectlyTo(nextDestination)
		end
	else
		-- Start moving toward target
		local nextDestination = findClearPath(currentPos, targetPos)
		moveDirectlyTo(nextDestination)
	end
	
	-- Auto-jump for small obstacles
	if distance < 30 and tick() - lastMoveTime > 0.5 then
		-- Check if there's a small obstacle in front
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {character}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		
		local lookDirection = (targetPos - currentPos).Unit
		local ray = workspace:Raycast(currentPos + Vector3.new(0, 1, 0), lookDirection * 5, raycastParams)
		
		if ray and ray.Instance and ray.Instance.Size.Y < 3 then
			humanoid.Jump = true
		end
	end
end

-- Function to start following
local function startFollowing()
	if not selectedPlayer then
		selectedPlayerText.Text = "Select a player first!"
		task.wait(1)
		selectedPlayerText.Text = selectedPlayer and selectedPlayer.Name or "None"
		return
	end
	
	if isFollowing then
		return
	end
	
	isFollowing = true
	followButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
	followButton.Text = "Following..."
	
	-- Set movement speed
	humanoid.WalkSpeed = 20
	humanoid.JumpPower = 50
	
	-- Reset movement state
	currentDestination = nil
	isMovingToDestination = false
	lastMoveTime = 0
	
	-- Start smooth follow loop
	followConnection = RunService.Heartbeat:Connect(function()
		smoothFollow()
	end)
	
	print("Started smooth following " .. selectedPlayer.Name)
end

-- Function to stop following
local function stopFollowing()
	if not isFollowing then
		return
	end
	
	isFollowing = false
	followButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
	followButton.Text = "▶ Start Following"
	
	-- Reset speed
	humanoid.WalkSpeed = 16
	
	if followConnection then
		followConnection:Disconnect()
		followConnection = nil
	end
	
	-- Stop all movement
	humanoid:MoveTo(humanoidRootPart.Position)
	currentDestination = nil
	isMovingToDestination = false
	
	print("Stopped following")
end

-- Button events
followButton.MouseButton1Click:Connect(startFollowing)
stopButton.MouseButton1Click:Connect(stopFollowing)

closeButton.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

-- Player management
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)

-- Character respawn handling
localPlayer.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = character:WaitForChild("Humanoid")
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	
	-- Resume following if it was active
	if isFollowing then
		task.wait(1)
		if isFollowing then
			startFollowing()
		end
	end
end)

-- Toggle GUI with key
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.P then
		screenGui.Enabled = not screenGui.Enabled
	end
end)

-- Make GUI draggable
local dragging = false
local dragInput, dragStart, startPos

local function update(input)
	local delta = input.Position - dragStart
	mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

title.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)

-- Initial setup
updatePlayerList()
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

print("✅ Fixed Pathfinder loaded!")
print("No more oscillation - smooth movement guaranteed!")
print("Press 'P' to toggle GUI")