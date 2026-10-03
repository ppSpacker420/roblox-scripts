local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- settings
local DEFAULT_COLOR   = Color3.fromRGB(255, 255, 255)
local BOX_ON          = true
local SKELETON_ON     = true
local NAME_ON         = true
local TRACER_ON       = true
local USE_TEAM_COLORS = true
local SHOW_TEAM_NAME  = true
local HIDE_TEAMMATES  = false
local TOGGLE_KEY      = Enum.KeyCode.RightShift  -- on/off
local KILL_KEY        = Enum.KeyCode.End         -- kill switch

-- stop any previous run
if getgenv().ESP_Unload then getgenv().ESP_Unload() end

local R15_BONES = {
    {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
}
local R6_BONES = {
    {"Head","Torso"}, {"Torso","Left Arm"}, {"Torso","Right Arm"},
    {"Torso","Left Leg"}, {"Torso","Right Leg"},
}

local objects = {}
local visible = true
local killed = false

---------------------------------------------------------------- GUI
local guiParent = (gethui and gethui()) or game:GetService("CoreGui")
if guiParent:FindFirstChild("ESPControlGui") then
    guiParent.ESPControlGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "ESPControlGui"
gui.ResetOnSpawn = false
gui.Parent = guiParent

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 150, 0, 100)
frame.Position = UDim2.new(0, 20, 0.4, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -20, 0, 35)
toggleBtn.Position = UDim2.new(0, 10, 0, 10)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.Text = "ESP: ON"
toggleBtn.Parent = frame
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

local killBtn = Instance.new("TextButton")
killBtn.Size = UDim2.new(1, -20, 0, 35)
killBtn.Position = UDim2.new(0, 10, 0, 55)
killBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 20)
killBtn.TextColor3 = Color3.new(1, 1, 1)
killBtn.Font = Enum.Font.GothamBold
killBtn.TextSize = 14
killBtn.Text = "KILL"
killBtn.Parent = frame
Instance.new("UICorner", killBtn).CornerRadius = UDim.new(0, 6)

local function setVisible(state)
    visible = state
    toggleBtn.Text = visible and "ESP: ON" or "ESP: OFF"
    toggleBtn.BackgroundColor3 = visible and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(200, 50, 50)
end

---------------------------------------------------------------- ESP
local function newLine()
    local l = Drawing.new("Line")
    l.Thickness = 1.5
    l.Color = DEFAULT_COLOR
    l.Visible = false
    return l
end

local function create(player)
    if player == LocalPlayer or objects[player] then return end
    local box = Drawing.new("Square")
    box.Thickness = 1.5
    box.Filled = false
    box.Color = DEFAULT_COLOR
    box.Visible = false

    local name = Drawing.new("Text")
    name.Size = 16
    name.Center = true
    name.Outline = true
    name.Color = DEFAULT_COLOR
    name.Text = player.DisplayName
    name.Visible = false

    local tracer = newLine()
    local lines = {}
    for i = 1, #R15_BONES do lines[i] = newLine() end

    objects[player] = {box = box, name = name, tracer = tracer, lines = lines}
end

local function remove(player)
    local o = objects[player]
    if not o then return end
    o.box:Remove()
    o.name:Remove()
    o.tracer:Remove()
    for _, l in ipairs(o.lines) do l:Remove() end
    objects[player] = nil
end

local function hide(o)
    o.box.Visible = false
    o.name.Visible = false
    o.tracer.Visible = false
    for _, l in ipairs(o.lines) do l.Visible = false end
end

local function toScreen(part)
    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
    return Vector2.new(pos.X, pos.Y), onScreen and pos.Z > 0
end

local function getTeamInfo(player)
    local team = player.Team
    if team then
        return USE_TEAM_COLORS and team.TeamColor.Color or DEFAULT_COLOR, team.Name
    end
    return DEFAULT_COLOR, nil
end

local function update()
    if killed then return end
    Camera = workspace.CurrentCamera
    local center = Camera.ViewportSize / 2

    for player, o in pairs(objects) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local isTeammate = LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team

        if not visible or not hrp or not hum or hum.Health <= 0
            or (HIDE_TEAMMATES and isTeammate) then
            hide(o)
        else
            local rootPos, onScreen = toScreen(hrp)
            if not onScreen then
                hide(o)
            else
                local color, teamName = getTeamInfo(player)

                local top = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
                local bottom = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.5, 0))
                local height = math.abs(bottom.Y - top.Y)
                local width = height / 2

                o.box.Visible = BOX_ON
                o.box.Color = color
                o.box.Size = Vector2.new(width, height)
                o.box.Position = Vector2.new(top.X - width / 2, top.Y)

                o.name.Visible = NAME_ON
                o.name.Color = color
                o.name.Text = (SHOW_TEAM_NAME and teamName)
                    and (player.DisplayName .. " [" .. teamName .. "]")
                    or player.DisplayName
                o.name.Position = Vector2.new(top.X, top.Y - 20)

                o.tracer.Visible = TRACER_ON
                o.tracer.Color = color
                o.tracer.From = center
                o.tracer.To = rootPos

                local bones = hum.RigType == Enum.HumanoidRigType.R15 and R15_BONES or R6_BONES
                for i, line in ipairs(o.lines) do
                    local bone = bones[i]
                    local a = bone and char:FindFirstChild(bone[1])
                    local b = bone and char:FindFirstChild(bone[2])
                    if SKELETON_ON and a and b then
                        local p1, v1 = toScreen(a)
                        local p2, v2 = toScreen(b)
                        line.Color = color
                        line.From = p1
                        line.To = p2
                        line.Visible = v1 and v2
                    else
                        line.Visible = false
                    end
                end
            end
        end
    end
end

---------------------------------------------------------------- connections + kill
local conns = {}

local function kill()
    if killed then return end
    killed = true
    for _, c in ipairs(conns) do c:Disconnect() end
    for p in pairs(objects) do remove(p) end
    gui:Destroy()
    getgenv().ESP_Unload = nil
end

for _, p in ipairs(Players:GetPlayers()) do create(p) end
table.insert(conns, Players.PlayerAdded:Connect(create))
table.insert(conns, Players.PlayerRemoving:Connect(remove))
table.insert(conns, RunService.RenderStepped:Connect(update))
table.insert(conns, toggleBtn.MouseButton1Click:Connect(function() setVisible(not visible) end))
table.insert(conns, killBtn.MouseButton1Click:Connect(kill))
table.insert(conns, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == TOGGLE_KEY then
        setVisible(not visible)
    elseif input.KeyCode == KILL_KEY then
        kill()
    end
end))

getgenv().ESP_Unload = kill