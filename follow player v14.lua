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
frame.Size = UDim2.new(0, 220, 0, 300)
frame.Position = UDim2.new(0.5, -110, 0.8, -150)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.Active, frame.Draggable = true, true
Instance.new("UICorner", frame)

local playerInput = Instance.new("TextBox", frame)
playerInput.Size, playerInput.Position = UDim2.new(0, 180, 0, 30), UDim2.new(0, 20, 0, 15)
playerInput.PlaceholderText = "Target Name..."
playerInput.Text = ""

local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size, toggleBtn.Position = UDim2.new(0, 180, 0, 35), UDim2.new(0, 20, 0, 55)
toggleBtn.Text, toggleBtn.BackgroundColor3 = "FOLLOW: OFF", Color3.fromRGB(150, 0, 0)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", toggleBtn)

local orbitBtn = Instance.new("TextButton", frame)
orbitBtn.Size, orbitBtn.Position = UDim2.new(0, 180, 0, 35), UDim2.new(0, 20, 0, 95)
orbitBtn.Text, orbitBtn.BackgroundColor3 = "JUMP ORBIT: OFF", Color3.fromRGB(60, 60, 150)
orbitBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", orbitBtn)

local rangeUp = Instance.new("TextButton", frame)
rangeUp.Size, rangeUp.Position = UDim2.new(0, 85, 0, 30), UDim2.new(0, 20, 0, 140)
rangeUp.Text, rangeUp.BackgroundColor3 = "Range +", Color3.fromRGB(50, 50, 50)
rangeUp.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", rangeUp)

local rangeDown = Instance.new("TextButton", frame)
rangeDown.Size, rangeDown.Position = UDim2.new(0, 85, 0, 30), UDim2.new(0, 115, 0, 140)
rangeDown.Text, rangeDown.BackgroundColor3 = "Range -", Color3.fromRGB(50, 50, 50)
rangeDown.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", rangeDown)

local status = Instance.new("TextLabel", frame)
status.Size, status.Position = UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 175)
status.BackgroundTransparency, status.TextColor3 = 1, Color3.new(1, 1, 1)
status.Text = "Range: 5 studs"

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size, closeBtn.Position = UDim2.new(0, 180, 0, 30), UDim2.new(0, 20, 0, 255)
closeBtn.Text, closeBtn.BackgroundColor3 = "DESTROY GUI", Color3.fromRGB(60, 60, 60)
closeBtn.TextColor3 = Color3.new(1, 0.4, 0.4)
Instance.new("UICorner", closeBtn)

-- // VARIABLES \\ --
local isFollowing, isOrbiting, isDestroyed = false, false, false
local orbitAngle, orbitSpeed = 0, 5
local followDistance = 5
local nextUpdate, waypointIndex, currentWaypoints = 0, 1, {}

-- Stuck Check
local lastPos = Vector3.new(0,0,0)
local stuckTimer = 0
local lastCheck = tick()

-- // LOGIC \\ --
local function performForwardLeap(hum, root)
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
    hum:MoveTo(root.Position + (root.CFrame.LookVector * 8))
end

-- // CORE ENGINE \\ --
local connection
connection = RunService.Heartbeat:Connect(function(dt)
    if isDestroyed then connection:Disconnect() return end
    if not isFollowing then return end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    
    -- Target Detection
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

    -- 1. CONTINUOUS JUMP DURING ORBIT
    if isOrbiting and hum.FloorMaterial ~= Enum.Material.Air then
        performForwardLeap(hum, root)
    end

    -- 2. JUMP OVERRIDE (Maintain forward momentum while in air)
    local state = hum:GetState()
    if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
        hum:MoveTo(root.Position + (root.CFrame.LookVector * 5))
        return 
    end

    -- 3. 5-SECOND STUCK BUSTER
    if tick() - lastCheck > 1 then
        if (root.Position - lastPos).Magnitude < 1 then
            stuckTimer = stuckTimer + 1
            if stuckTimer >= 5 then
                performForwardLeap(hum, root)
                stuckTimer = 0
            end
        else stuckTimer = 0 end
        lastPos = root.Position
        lastCheck = tick()
    end

    -- 4. CALC DESTINATION
    local destination
    if isOrbiting then
        orbitAngle = orbitAngle + (orbitSpeed * dt)
        destination = tRoot.Position + Vector3.new(math.cos(orbitAngle) * followDistance, 0, math.sin(orbitAngle) * followDistance)
    else
        destination = tRoot.Position
    end

    -- 5. PATHFINDING
    local distToTarget = (root.Position - tRoot.Position).Magnitude
    if distToTarget > followDistance or isOrbiting then
        if tick() > nextUpdate then
            nextUpdate = tick() + 0.3
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
            if wp.Action == Enum.PathWaypointAction.Jump then performForwardLeap(hum, root) end
            if (root.Position - wp.Position).Magnitude < 4 then waypointIndex = waypointIndex + 1 end
        end
    else
        hum:Move(Vector3.new(0,0,0))
    end
end)

-- // BUTTONS \\ --
rangeUp.MouseButton1Click:Connect(function()
    followDistance = math.min(followDistance + 2, 50)
    status.Text = "Range: " .. followDistance .. " studs"
end)

rangeDown.MouseButton1Click:Connect(function()
    followDistance = math.max(followDistance - 2, 2)
    status.Text = "Range: " .. followDistance .. " studs"
end)

toggleBtn.MouseButton1Click:Connect(function()
    isFollowing = not isFollowing
    toggleBtn.Text = isFollowing and "FOLLOW: ON" or "FOLLOW: OFF"
    toggleBtn.BackgroundColor3 = isFollowing and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
end)

orbitBtn.MouseButton1Click:Connect(function()
    isOrbiting = not isOrbiting
    orbitBtn.Text = isOrbiting and "JUMP ORBIT: ON" or "JUMP ORBIT: OFF"
    orbitBtn.BackgroundColor3 = isOrbiting and Color3.fromRGB(0, 180, 200) or Color3.fromRGB(60, 60, 150)
end)

closeBtn.MouseButton1Click:Connect(function()
    isFollowing = false; isDestroyed = true
    PathFolder:Destroy(); screenGui:Destroy()
end)