-- Put this LocalScript in StarterGui
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

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
title.Text = "Player Pathfinder"
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
selectedLabel.Text = "Selected:"
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
followButton.Text = "Start Following"
followButton.Font = Enum.Font.SourceSansBold
followButton.TextSize = 18
followButton.Parent = buttonContainer

local stopButton = Instance.new("TextButton")
stopButton.Size = UDim2.new(1, 0, 0, 35)
stopButton.Position = UDim2.new(0, 0, 0, 45)
stopButton.BackgroundColor3 = Color3.fromRGB(215, 60, 0)
stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopButton.Text = "Stop Following"
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

-- Variables
local selectedPlayer = nil
local isFollowing = false
local currentPath = nil
local pathVisualization = nil
local connection = nil
local lastPathUpdate = 0
local pathUpdateInterval = 0.3 -- Update path every 0.3 seconds for faster response
local waypointReachedDistance = 4 -- Distance to consider a waypoint reached

-- Function to update player list
local function updatePlayerList()
	-- Clear existing buttons
	for _, child in ipairs(playerListFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	-- Add current players
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
				
				-- Highlight selected button
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

-- Function to create path visualization
local function createPathVisualization()
	if pathVisualization then
		pathVisualization:Destroy()
	end
	
	pathVisualization = Instance.new("Folder")
	pathVisualization.Name = "PathVisualization"
	pathVisualization.Parent = workspace
end

-- Function to visualize path
local function visualizePath(waypoints)
	if not pathVisualization then
		createPathVisualization()
	end
	
	-- Clear previous visualization
	for _, child in ipairs(pathVisualization:GetChildren()) do
		child:Destroy()
	end
	
	-- Create new visualization
	for i, waypoint in ipairs(waypoints) do
		local part = Instance.new("Part")
		part.Size = Vector3.new(0.5, 0.5, 0.5)
		part.Position = waypoint.Position + Vector3.new(0, 2.5, 0)
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 0.3
		part.Material = Enum.Material.Neon
		
		-- Color based on waypoint type
		if waypoint.Action == Enum.PathWaypointAction.Jump then
			part.Color = Color3.fromRGB(255, 100, 100) -- Light red for jumps
		else
			part.Color = Color3.fromRGB(100, 255, 100) -- Light green for normal
		end
		
		-- Add number label
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 40, 0, 40)
		billboard.AlwaysOnTop = true
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.Parent = part
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = tostring(i)
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Font = Enum.Font.SourceSansBold
		label.TextSize = 16
		label.Parent = billboard
		
		part.Parent = pathVisualization
	end
end

-- Improved function to follow waypoints with continuous movement
local function followWaypoints(waypoints)
	if not waypoints or #waypoints == 0 then
		return false
	end
	
	local currentWaypointIndex = 1
	local lastWaypointPosition = humanoidRootPart.Position
	
	while currentWaypointIndex <= #waypoints and isFollowing do
		local waypoint = waypoints[currentWaypointIndex]
		local distanceToWaypoint = (humanoidRootPart.Position - waypoint.Position).Magnitude
		
		-- Check if we reached the waypoint
		if distanceToWaypoint < waypointReachedDistance then
			-- If this is a jump waypoint, make the character jump
			if waypoint.Action == Enum.PathWaypointAction.Jump then
				humanoid.Jump = true
			end
			currentWaypointIndex += 1
		else
			-- Move towards the waypoint
			humanoid:MoveTo(waypoint.Position)
			
			-- Check if we're stuck (not moving towards waypoint)
			local currentPosition = humanoidRootPart.Position
			local distanceMoved = (currentPosition - lastWaypointPosition).Magnitude
			
			-- If stuck for too long, try to jump or skip waypoint
			if distanceMoved < 0.5 then
				humanoid.Jump = true
				task.wait(0.1)
				-- If still stuck after jump, skip to next waypoint
				if (humanoidRootPart.Position - lastWaypointPosition).Magnitude < 0.5 then
					currentWaypointIndex += 1
				end
			end
			
			lastWaypointPosition = currentPosition
		end
		
		-- Small delay to prevent overload
		task.wait(0.05)
	end
	
	return currentWaypointIndex > #waypoints
end

-- Fast pathfinding function with direct movement fallback
local function findAndFollowPath()
	if not selectedPlayer or not isFollowing then
		return
	end
	
	local targetCharacter = selectedPlayer.Character
	if not targetCharacter then
		return
	end
	
	local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart") or targetCharacter:FindFirstChild("Head")
	if not targetRoot then
		return
	end
	
	-- Get current position
	local startPos = humanoidRootPart.Position
	local targetPos = targetRoot.Position
	
	-- Check direct line of sight first (for speed)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {character, targetCharacter}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = true
	
	local raycastResult = workspace:Raycast(startPos, (targetPos - startPos), raycastParams)
	
	-- If direct path is clear, move directly
	if not raycastResult then
		humanoid:MoveTo(targetPos)
		return true
	end
	
	-- Otherwise use pathfinding
	local path = PathfindingService:CreatePath({
		AgentRadius = 1.5, -- Smaller radius for tighter navigation
		AgentHeight = 5,
		AgentCanJump = true,
		AgentCanClimb = true,
		WaypointSpacing = 3, -- Smaller spacing for smoother path
		Costs = {}
	})
	
	-- Compute path
	path:ComputeAsync(startPos, targetPos)
	
	if path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		
		-- Visualize the path (optional)
		visualizePath(waypoints)
		
		-- Follow the waypoints
		return followWaypoints(waypoints)
	else
		-- If pathfinding fails, try direct movement as fallback
		humanoid:MoveTo(targetPos)
		return false
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
	
	-- Create visualization folder
	createPathVisualization()
	
	-- Start following loop with faster updates
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not isFollowing or not selectedPlayer then
			return
		end
		
		-- Update path more frequently for better tracking
		lastPathUpdate += deltaTime
		if lastPathUpdate >= pathUpdateInterval then
			lastPathUpdate = 0
			findAndFollowPath()
		end
	end)
	
	print("Started following " .. selectedPlayer.Name)
end

-- Function to stop following
local function stopFollowing()
	if not isFollowing then
		return
	end
	
	isFollowing = false
	followButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
	followButton.Text = "Start Following"
	
	if connection then
		connection:Disconnect()
		connection = nil
	end
	
	-- Clear path visualization
	if pathVisualization then
		pathVisualization:Destroy()
		pathVisualization = nil
	end
	
	-- Stop movement
	humanoid:MoveTo(humanoidRootPart.Position)
	
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
		task.wait(1) -- Wait a bit for character to fully load
		if isFollowing then -- Check again in case it changed
			startFollowing()
		end
	end
end)

-- Initial setup
updatePlayerList()
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- Toggle GUI with key (optional)
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

-- Debug info
print("Pathfinder GUI loaded!")
print("Press 'P' to toggle visibility")
print("Select a player and click 'Start Following' to begin")