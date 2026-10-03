local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- settings
local DEFAULT_COLOR  = Color3.fromRGB(255, 255, 255)
local BOX_ON         = true
local SKELETON_ON    = true
local NAME_ON        = true
local TRACER_ON      = true
local SHOW_TEAM_NAME = true
local HIDE_TEAMMATES = false
local TOGGLE_KEY     = Enum.KeyCode.RightShift  -- ESP on/off
local MENU_KEY       = Enum.KeyCode.Insert      -- show/hide menu
local KILL_KEY       = Enum.KeyCode.End         -- kill switch

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
local overrides = {}      -- [player] = {box = Color3?, skel = Color3?}
local visible = true
local killed = false
local selected = nil      -- player picked in the menu
local target = "Both"     -- which part the color applies to

---------------------------------------------------------------- TEAM
local TEAM_KEYS = {"Team", "team", "TeamName", "teamName", "Side", "Faction"}

local function hashColor(str)
    local h = 0
    for i = 1, #str do h = (h * 31 + str:byte(i)) % 360 end
    return Color3.fromHSV(h / 360, 0.75, 1)
end

local function fromValue(v)
    if typeof(v) == "Instance" then
        return v.Name, v:IsA("Team") and v.TeamColor.Color or hashColor(v.Name)
    end
    local s = tostring(v)
    return s, hashColor(s)
end

-- returns teamName (or nil), teamColor (or nil)
local function getTeam(player)
    -- 1) Roblox Team service
    if player.Team then
        return player.Team.Name, player.Team.TeamColor.Color
    end

    -- 2) attributes on the player, then on the character
    local char = player.Character
    for _, holder in ipairs({player, char}) do
        if holder then
            for _, key in ipairs(TEAM_KEYS) do
                local a = holder:GetAttribute(key)
                if a ~= nil then return fromValue(a) end
            end
        end
    end

    -- 3) value objects in player, leaderstats, or character
    local places = {player, player:FindFirstChild("leaderstats"), char}
    for _, holder in ipairs(places) do
        if holder then
            for _, key in ipairs(TEAM_KEYS) do
                local v = holder:FindFirstChild(key)
                if v and v:IsA("ValueBase") then return fromValue(v.Value) end
            end
        end
    end

    -- 4) TeamColor without a Team object
    if not player.Neutral then
        return tostring(player.TeamColor), player.TeamColor.Color
    end

    return nil, nil
end

---------------------------------------------------------------- GUI
local guiParent = (gethui and gethui()) or game:GetService("CoreGui")
if guiParent:FindFirstChild("ESPControlGui") then
    guiParent.ESPControlGui:Destroy()
end

local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end
local function round(o, r) Instance.new("UICorner", o).CornerRadius = UDim.new(0, r or 6) end

local gui = mk("ScreenGui", {Name = "ESPControlGui", ResetOnSpawn = false}, guiParent)

local frame = mk("Frame", {
    Size = UDim2.new(0, 300, 0, 370), Position = UDim2.new(0, 20, 0.2, 0),
    BackgroundColor3 = Color3.fromRGB(28, 28, 28), Active = true, Draggable = true,
}, gui)
round(frame, 8)

mk("TextLabel", {
    Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1,
    Text = "ESP Menu  (Insert = hide)", TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold, TextSize = 13,
}, frame)

local function button(text, x, y, w, h, color, parent)
    local b = mk("TextButton", {
        Size = UDim2.new(0, w, 0, h), Position = UDim2.new(0, x, 0, y),
        BackgroundColor3 = color, TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold, TextSize = 12, Text = text, AutoButtonColor = true,
    }, parent or frame)
    round(b, 5)
    return b
end

local toggleBtn = button("ESP: ON", 10, 28, 88, 28, Color3.fromRGB(50, 180, 80))
local teamBtn   = button("Hide team: OFF", 106, 28, 88, 28, Color3.fromRGB(70, 70, 70))
local killBtn   = button("KILL", 202, 28, 88, 28, Color3.fromRGB(150, 25, 25))

local list = mk("ScrollingFrame", {
    Size = UDim2.new(1, -20, 0, 150), Position = UDim2.new(0, 10, 0, 64),
    BackgroundColor3 = Color3.fromRGB(20, 20, 20), BorderSizePixel = 0,
    ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0),
}, frame)
round(list, 6)
local layout = mk("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.Name}, list)

local selLabel = mk("TextLabel", {
    Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 220),
    BackgroundTransparency = 1, Text = "Select a player", TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
}, frame)

local targetBtns = {}
local function setTarget(t)
    target = t
    for name, b in pairs(targetBtns) do
        b.BackgroundColor3 = (name == t) and Color3.fromRGB(60, 110, 200) or Color3.fromRGB(70, 70, 70)
    end
end
for i, name in ipairs({"Box", "Skeleton", "Both"}) do
    targetBtns[name] = button(name, 10 + (i - 1) * 97, 244, 93, 26, Color3.fromRGB(70, 70, 70))
    targetBtns[name].MouseButton1Click:Connect(function() setTarget(name) end)
end
setTarget("Both")

local function applyColor(color)
    if not selected then return end
    local ov = overrides[selected] or {}
    if target == "Box" or target == "Both" then ov.box = color end
    if target == "Skeleton" or target == "Both" then ov.skel = color end
    overrides[selected] = (ov.box or ov.skel) and ov or nil
end

local SWATCHES = {
    Color3.fromRGB(255, 0, 0),   Color3.fromRGB(255, 140, 0), Color3.fromRGB(255, 230, 0),
    Color3.fromRGB(0, 220, 60),  Color3.fromRGB(0, 220, 220), Color3.fromRGB(0, 100, 255),
    Color3.fromRGB(170, 0, 255), Color3.fromRGB(255, 80, 200), Color3.fromRGB(255, 255, 255),
}
for i, c in ipairs(SWATCHES) do
    local s = button("", 10 + (i - 1) * 29, 278, 25, 25, c)
    s.MouseButton1Click:Connect(function() applyColor(c) end)
end

local hexBox = mk("TextBox", {
    Size = UDim2.new(0, 170, 0, 28), Position = UDim2.new(0, 10, 0, 312),
    BackgroundColor3 = Color3.fromRGB(50, 50, 50), TextColor3 = Color3.new(1, 1, 1),
    PlaceholderText = "Hex color, e.g. FF8800", Text = "", Font = Enum.Font.Gotham,
    TextSize = 13, ClearTextOnFocus = false,
}, frame)
round(hexBox, 5)

local function parseHex(s)
    s = s:gsub("#", ""):gsub("%s", "")
    if #s ~= 6 then return nil end
    local r, g, b = tonumber(s:sub(1, 2), 16), tonumber(s:sub(3, 4), 16), tonumber(s:sub(5, 6), 16)
    if r and g and b then return Color3.fromRGB(r, g, b) end
end
hexBox.FocusLost:Connect(function()
    local c = parseHex(hexBox.Text)
    if c then applyColor(c) end
end)

local resetBtn = button("Reset", 188, 312, 102, 28, Color3.fromRGB(90, 60, 60))
resetBtn.MouseButton1Click:Connect(function() applyColor(nil) end)

mk("TextLabel", {
    Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 344),
    BackgroundTransparency = 1, Text = "Reset = back to team color",
    TextColor3 = Color3.fromRGB(150, 150, 150), Font = Enum.Font.Gotham, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, frame)

local function setVisible(state)
    visible = state
    toggleBtn.Text = visible and "ESP: ON" or "ESP: OFF"
    toggleBtn.BackgroundColor3 = visible and Color3.fromRGB(50, 180, 80) or Color3.fromRGB(200, 50, 50)
end

local function setHideTeam(state)
    HIDE_TEAMMATES = state
    teamBtn.Text = state and "Hide team: ON" or "Hide team: OFF"
    teamBtn.BackgroundColor3 = state and Color3.fromRGB(60, 110, 200) or Color3.fromRGB(70, 70, 70)
end

local function refreshList()
    for _, c in ipairs(list:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local teamName, teamColor = getTeam(p)
            local row = mk("TextButton", {
                Name = p.Name:lower(), Size = UDim2.new(1, -6, 0, 24),
                BackgroundColor3 = (p == selected) and Color3.fromRGB(60, 110, 200) or Color3.fromRGB(45, 45, 45),
                TextColor3 = teamColor or Color3.new(1, 1, 1), Font = Enum.Font.Gotham, TextSize = 12,
                Text = "  " .. p.DisplayName .. "  [" .. (teamName or "No Team") .. "]",
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            }, list)
            round(row, 4)
            row.MouseButton1Click:Connect(function()
                selected = p
                selLabel.Text = "Selected: " .. p.DisplayName
                refreshList()
            end)
        end
    end
    list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 4)
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

    local lines = {}
    for i = 1, #R15_BONES do lines[i] = newLine() end
    objects[player] = {box = box, name = name, tracer = newLine(), lines = lines}
end

local function remove(player)
    local o = objects[player]
    if o then
        o.box:Remove()
        o.name:Remove()
        o.tracer:Remove()
        for _, l in ipairs(o.lines) do l:Remove() end
        objects[player] = nil
    end
    overrides[player] = nil
    if selected == player then
        selected = nil
        selLabel.Text = "Select a player"
    end
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

local function update()
    if killed then return end
    Camera = workspace.CurrentCamera
    local center = Camera.ViewportSize / 2
    local myTeam = getTeam(LocalPlayer)

    for player, o in pairs(objects) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local teamName, teamColor = getTeam(player)
        local isTeammate = myTeam ~= nil and teamName == myTeam

        if not visible or not hrp or not hum or hum.Health <= 0
            or (HIDE_TEAMMATES and isTeammate) then
            hide(o)
        else
            local rootPos, onScreen = toScreen(hrp)
            if not onScreen then
                hide(o)
            else
                local base = teamColor or DEFAULT_COLOR
                local ov = overrides[player]
                local boxColor  = (ov and ov.box)  or base
                local skelColor = (ov and ov.skel) or base

                local top = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
                local bottom = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.5, 0))
                local height = math.abs(bottom.Y - top.Y)
                local width = height / 2

                o.box.Visible = BOX_ON
                o.box.Color = boxColor
                o.box.Size = Vector2.new(width, height)
                o.box.Position = Vector2.new(top.X - width / 2, top.Y)

                o.name.Visible = NAME_ON
                o.name.Color = base
                o.name.Text = (SHOW_TEAM_NAME and teamName)
                    and (player.DisplayName .. " [" .. teamName .. "]") or player.DisplayName
                o.name.Position = Vector2.new(top.X, top.Y - 20)

                o.tracer.Visible = TRACER_ON
                o.tracer.Color = base
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
                        line.Color = skelColor
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
refreshList()

table.insert(conns, Players.PlayerAdded:Connect(function(p) create(p) refreshList() end))
table.insert(conns, Players.PlayerRemoving:Connect(function(p) remove(p) task.defer(refreshList) end))
table.insert(conns, RunService.RenderStepped:Connect(update))
table.insert(conns, toggleBtn.MouseButton1Click:Connect(function() setVisible(not visible) end))
table.insert(conns, teamBtn.MouseButton1Click:Connect(function() setHideTeam(not HIDE_TEAMMATES) end))
table.insert(conns, killBtn.MouseButton1Click:Connect(kill))
table.insert(conns, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == TOGGLE_KEY then
        setVisible(not visible)
    elseif input.KeyCode == MENU_KEY then
        frame.Visible = not frame.Visible
    elseif input.KeyCode == KILL_KEY then
        kill()
    end
end))

-- keep team labels in the list up to date
task.spawn(function()
    while not killed do
        task.wait(2)
        if not killed and frame.Visible then refreshList() end
    end
end)

getgenv().ESP_Unload = kill