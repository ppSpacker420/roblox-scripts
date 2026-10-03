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
frame.Size = UDim2.new(0, 220, 0, 180)
frame.Position = UDim2.new(0.5, -110, 0.8, -100)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Instance.new("UICorner", frame)

local playerInput = Instance.new("TextBox", frame)
playerInput.Size = UDim2.new(0, 180, 0, 30)
playerInput.Position = UDim2.new(0, 20, 0, 20)
playerInput.PlaceholderText = "Target Name..."
playerInput.Text = ""

local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.new(0, 180, 0, 40)
toggleBtn.Position = UDim2.new(0, 20, 0, 60)
toggleBtn.Text = "FOLLOW: OFF"
toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", toggleBtn)

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, 0, 0, 30)
status.Position = UDim2.new(0, 0, 0, 110)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.new(1, 1, 1)
status.Text = "Ready"

-- // VARIABLES \\ --
local isFollowing = false
local followDistance = 5
local nextUpdate = 0
local currentWaypoints = {}
local waypointIndex = 1

-- Stuck Logic
local lastPos = Vector3.new(0,0,0)
local stuckTimer = 0
local lastCheck = tick()

-- // SENSOR & DEBUG VISUALS \\ --
local function createDebugRay(name)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Size = Vector3.new(0.1, 0.1, 4)
	p.Transparency = 0.5
	p.Parent = PathFolder
	return p
end

local footRayPart = createDebugRay("FootRay")
local waistRayPart = createDebugRay("WaistRay")

local function updateJumpSensors(root, hum)
	local rayDir = root.CFrame.LookVector * 3.5
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {LocalPlayer.Character, PathFolder}
	params.FilterType = Enum.RaycastFilterType.Exclude

	-- Positions
	local footPos = root.Position - Vector3.new(0, 1.8, 0)
	local waistPos = root.Position - Vector3.new(0, 0.5, 0)

	-- Cast Rays
	local hit1 = workspace:Raycast(footPos, rayDir, params)
	local hit2 = workspace:Raycast(waistPos, rayDir, params)

	-- Update Visual Debugger
	footRayPart.CFrame = CFrame.new(footPos + rayDir/2, footPos + rayDir)
	waistRayPart.CFrame = CFrame.new(waistPos + rayDir/2, waistPos + rayDir)

	if (hit1 and hit1.Instance.CanCollide) or (hit2 and hit2.Instance.CanCollide) then
		footRayPart.Color = Color3.new(1, 0, 0)
		waistRayPart.Color = Color3.new(1, 0, 0)
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
	else
		footRayPart.Color = Color3.new(0, 1, 0)
		waistRayPart.Color = Color3.new(0, 1, 0)
	end
end

-- // CORE ENGINE \\ --
RunService.Heartbeat:Connect(function()
	if not isFollowing then 
		footRayPart.Transparency = 1
		waistRayPart.Transparency = 1
		return 
	end
	
	footRayPart.Transparency = 0.5
	waistRayPart.Transparency = 0.5

	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChild("Humanoid")
	
	-- Get Target
	local target = nil
	local text = string.lower(playerInput.Text)
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and (string.find(string.lower(p.Name), text) or string.find(string.lower(p.DisplayName), text)) then
			target = p
			break
		end
	end

	if not root or not hum or not target or not target.Character then return end
	local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
	if not tRoot then return end

	local dist = (root.Position - tRoot.Position).Magnitude

	-- 1. AUTO-JUMP SENSORS
	updateJumpSensors(root, hum)

	-- 2. 5-SECOND STUCK RESET
	if tick() - lastCheck > 1 then
		if (root.Position - lastPos).Magnitude < 1 and dist > followDistance then
			stuckTimer = stuckTimer + 1
			if stuckTimer >= 5 then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
				hum:Move(Vector3.new(math.random(-1,1), 0, math.random(-1,1)))
				nextUpdate = 0
				stuckTimer = 0
			end
		else
			stuckTimer = 0
		end
		lastPos = root.Position
		lastCheck = tick()
	end

	-- 3. MOVEMENT LOGIC
	if dist <= followDistance then
		hum:Move(Vector3.new(0,0,0))
		return
	end

	if tick() > nextUpdate then
		nextUpdate = tick() + 0.5
		local path = PathfindingService:CreatePath({AgentRadius = 2, AgentCanJump = true})
		local success, _ = pcall(function() path:ComputeAsync(root.Position, tRoot.Position) end)
		if success and path.Status == Enum.PathStatus.Success then
			currentWaypoints = path:GetWaypoints()
			waypointIndex = 2
		end
	end

	if currentWaypoints and waypointIndex <= #currentWaypoints then
		local wp = currentWaypoints[waypointIndex]
		hum:MoveTo(wp.Position)
		if wp.Action == Enum.PathWaypointAction.Jump then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
		if (root.Position - wp.Position).Magnitude < 4 then waypointIndex = waypointIndex + 1 end
	end
end)

toggleBtn.MouseButton1Click:Connect(function()
	isFollowing = not isFollowing
	toggleBtn.Text = isFollowing and "FOLLOW: ON" or "FOLLOW: OFF"
	toggleBtn.BackgroundColor3 = isFollowing and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
end)