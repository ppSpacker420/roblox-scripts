local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PathFolder = Instance.new("Folder", workspace)
PathFolder.Name = "PathVisualizer"

-- // GUI SETUP \\ --
local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 220, 0, 260)
frame.Position = UDim2.new(0.5, -110, 0.8, -130)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.Active, frame.Draggable = true, true
Instance.new("UICorner", frame)

local playerInput = Instance.new("TextBox", frame)
playerInput.Size, playerInput.Position = UDim2.new(0, 180, 0, 30), UDim2.new(0, 20, 0, 20)
playerInput.PlaceholderText = "Target Name..."
playerInput.Text = ""

local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size, toggleBtn.Position = UDim2.new(0, 180, 0, 40), UDim2.new(0, 20, 0, 60)
toggleBtn.Text, toggleBtn.BackgroundColor3 = "FOLLOW: OFF", Color3.fromRGB(150, 0, 0)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", toggleBtn)

local orbitBtn = Instance.new("TextButton", frame)
orbitBtn.Size, orbitBtn.Position = UDim2.new(0, 180, 0, 40), UDim2.new(0, 20, 0, 105)
orbitBtn.Text, orbitBtn.BackgroundColor3 = "ORBIT: OFF", Color3.fromRGB(60, 60, 150)
orbitBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", orbitBtn)

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size, closeBtn.Position = UDim2.new(0, 180, 0, 30), UDim2.new(0, 20, 0, 215)
closeBtn.Text, closeBtn.BackgroundColor3 = "DESTROY GUI", Color3.fromRGB(60, 60, 60)
closeBtn.TextColor3 = Color3.new(1, 0.4, 0.4)
Instance.new("UICorner", closeBtn)

-- // VARIABLES \\ --
local isFollowing, isOrbiting, isDestroyed = false, false, false
local orbitAngle, orbitRadius, orbitSpeed = 0, 8, 4
local nextUpdate, waypointIndex, currentWaypoints = 0, 1, {}

-- // THE FORWARD-JUMP LOGIC \\ --
local function performForwardLeap(hum, root)
	-- 1. Switch to Jumping State
	hum:ChangeState(Enum.HumanoidStateType.Jumping)
	
	-- 2. Create a point 10 studs directly in front of the character
	local forwardPoint = root.Position + (root.CFrame.LookVector * 10)
	
	-- 3. Force move to that point (ignores path dots)
	hum:MoveTo(forwardPoint)
end

local function checkObstacles(root, hum)
	local rayDir = root.CFrame.LookVector * 3.5
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {LocalPlayer.Character, PathFolder}
	
	local hit = workspace:Raycast(root.Position - Vector3.new(0, 1, 0), rayDir, params)
	
	if hit and hit.Instance.CanCollide then
		performForwardLeap(hum, root)
	end
end

-- // CORE ENGINE \\ --
local connection
connection = RunService.Heartbeat:Connect(function(dt)
	if isDestroyed then connection:Disconnect() return end
	if not isFollowing then return end

	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChild("Humanoid")
	
	-- Find Target
	local target = nil
	local text = string.lower(playerInput.Text)
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and (string.find(string.lower(p.Name), text) or string.find(string.lower(p.DisplayName), text)) then
			target = p; break
		end
	end

	if not root or not hum or not target or not target.Character then return end
	local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
	if not tRoot then return end

	-- IF JUMPING: Only move forward, ignore Pathfinding
	if hum:GetState() == Enum.HumanoidStateType.Jumping or hum:GetState() == Enum.HumanoidStateType.Freefall then
		hum:MoveTo(root.Position + (root.CFrame.LookVector * 5))
		return -- Exit loop so pathfinding doesn't interfere mid-air
	end

	-- IF ON GROUND: Normal Pathfinding
	checkObstacles(root, hum)

	local destination
	if isOrbiting then
		orbitAngle = orbitAngle + (orbitSpeed * dt)
		destination = tRoot.Position + Vector3.new(math.cos(orbitAngle) * orbitRadius, 0, math.sin(orbitAngle) * orbitRadius)
	else
		destination = tRoot.Position
	end

	if tick() > nextUpdate then
		nextUpdate = tick() + 0.4
		local path = PathfindingService:CreatePath({AgentRadius = 2, AgentCanJump = true})
		local success, _ = pcall(function() path:ComputeAsync(root.Position, destination) end)
		if success and path.Status == Enum.PathStatus.Success then
			currentWaypoints = path:GetWaypoints()
			waypointIndex = 2
		end
	end

	if currentWaypoints and waypointIndex <= #currentWaypoints then
		local wp = currentWaypoints[waypointIndex]
		hum:MoveTo(wp.Position)
		if wp.Action == Enum.PathWaypointAction.Jump then 
			performForwardLeap(hum, root) 
		end
		if (root.Position - wp.Position).Magnitude < 4 then waypointIndex = waypointIndex + 1 end
	end
end)

-- // BUTTONS \\ --
toggleBtn.MouseButton1Click:Connect(function()
	isFollowing = not isFollowing
	toggleBtn.Text = isFollowing and "FOLLOW: ON" or "FOLLOW: OFF"
	toggleBtn.BackgroundColor3 = isFollowing and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
end)

orbitBtn.MouseButton1Click:Connect(function()
	isOrbiting = not isOrbiting
	orbitBtn.Text = isOrbiting and "ORBIT: ON" or "ORBIT: OFF"
	orbitBtn.BackgroundColor3 = isOrbiting and Color3.fromRGB(150, 150, 0) or Color3.fromRGB(60, 60, 150)
end)

closeBtn.MouseButton1Click:Connect(function()
	isFollowing = false; isDestroyed = true
	PathFolder:Destroy(); screenGui:Destroy()
end)