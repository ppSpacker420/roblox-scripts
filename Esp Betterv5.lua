local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- settings
local DEFAULT_COLOR   = Color3.fromRGB(255, 255, 255)
local ALLY_COLOR      = Color3.fromRGB(0, 255, 0)
local ENEMY_COLOR     = Color3.fromRGB(255, 0, 0)
local ENEMY_PER_TEAM  = false
local BOX_ON          = true
local SKELETON_ON     = true
local NAME_ON         = true
local TRACER_ON       = true
local SHOW_TEAM_NAME  = true
local HIDE_TEAMMATES  = false
local TOGGLE_KEY      = Enum.KeyCode.RightShift
local MENU_KEY        = Enum.KeyCode.Insert
local KILL_KEY        = Enum.KeyCode.End

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
local overrides = {}
local visible = true
local killed = false
local selected = nil
local target = "All"

---------------------------------------------------------------- TEAM AUTO-DETECT
local NAME_HINTS = {"team", "side", "faction", "squad", "clan"}
local teamCache = {}

local function hasHint(n)
    n = tostring(n):lower()
    for _, h in ipairs(NAME_HINTS) do
        if n:find(h, 1, true) then return true end
    end
    return false
end

local function hashColor(str)
    local h = 0
    for i = 1, #str do h = (h * 31 + str:byte(i)) % 360 end
    return Color3.fromHSV(h / 360, 0.75, 1)
end

local function teamColorFromName(name)
    local t = Teams:FindFirstChild(name)
    if t and t:IsA("Team") then return t.TeamColor.Color end
    return hashColor(name)
end

local function hex(c)
    return string.format("%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255)
end

local function fromValue(v)
    local t = typeof(v)
    if t == "Instance" then
        if v:IsA("Team") then return v.Name, v.TeamColor.Color end
        return v.Name, teamColorFromName(v.Name)
    elseif t == "BrickColor" then
        return v.Name, v.Color
    elseif t == "Color3" then
        return "#" .. hex(v), v
    elseif v == nil then
        return nil
    end
    local s = tostring(v)
    if s == "" then return nil end
    return s, teamColorFromName(s)
end

local function scanHolder(holder, label)
    for k, v in pairs(holder:GetAttributes()) do
        if hasHint(k) then
            local n, c = fromValue(v)
            if n then return n, c, label .. " attribute '" .. k .. "'" end
        end
    end
    for _, tag in ipairs(CollectionService:GetTags(holder)) do
        if hasHint(tag) then
            return tag, teamColorFromName(tag), label .. " tag"
        end
    end
    local function checkChildren(parent, path)
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("ValueBase") and hasHint(child.Name) then
                local n, c = fromValue(child.Value)
                if n then return n, c, label .. " value '" .. path .. child.Name .. "'" end
            end
        end
    end
    local n, c, m = checkChildren(holder, "")
    if n then return n, c, m end
    for _, child in ipairs(holder:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Configuration") then
            n, c, m = checkChildren(child, child.Name .. ".")
            if n then return n, c, m end
        end
    end
end

local function buildFolderMap()
    local map, names = {}, {}
    local function playerFrom(inst)
        local p = Players:FindFirstChild(inst.Name)
        if p and p:IsA("Player") then return p end
        if inst:IsA("ObjectValue") and typeof(inst.Value) == "Instance" and inst.Value:IsA("Player") then
            return inst.Value
        end
    end
    local function scanGroup(group)
        for _, m in ipairs(group:GetChildren()) do
            local p = playerFrom(m)
            if p then
                map[p] = group.Name
                names[group.Name] = true
            end
        end
    end
    for _, root in ipairs({workspace, ReplicatedStorage}) do
        for _, group in ipairs(root:GetChildren()) do
            if group:IsA("Folder") or group:IsA("Configuration") then
                scanGroup(group)
                for _, sub in ipairs(group:GetChildren()) do
                    if sub:IsA("Folder") or sub:IsA("Configuration") then scanGroup(sub) end
                end
            end
        end
    end
    local count = 0
    for _ in pairs(names) do count += 1 end
    if count < 2 then return {} end
    return map
end

local function detect(player, folderMap)
    if player.Team then
        return player.Team.Name, player.Team.TeamColor.Color, "Teams service"
    end

    local n, c, m = scanHolder(player, "player")
    if n then return n, c, m end

    local char = player.Character
    if char then
        n, c, m = scanHolder(char, "character")
        if n then return n, c, m end
    end

    if folderMap[player] then
        return folderMap[player], teamColorFromName(folderMap[player]), "folder"
    end

    if not player.Neutral then
        return tostring(player.TeamColor), player.TeamColor.Color, "TeamColor"
    end

    if char then
        local hl = char:FindFirstChildOfClass("Highlight")
        if hl then
            return "#" .. hex(hl.FillColor), hl.FillColor, "character Highlight"
        end
    end

    return nil, nil, nil
end

local function rescan()
    local okMap, folderMap = pcall(buildFolderMap)
    if not okMap then folderMap = {} end
    for _, p in ipairs(Players:GetPlayers()) do
        local ok, n, c, m = pcall(detect, p, folderMap)
        if ok then
            teamCache[p] = {name = n, color = c, method = m}
        end
    end
end

local function getTeam(player)
    local t = teamCache[player]
    if t then return t.name, t.color, t.method end
    return nil, nil, nil
end

local function getDisplayColor(teamName, teamColor, myTeam)
    if not teamName then return DEFAULT_COLOR end
    if not myTeam then return teamColor or hashColor(teamName) end
    if teamName == myTeam then return ALLY_COLOR end
    if ENEMY_PER_TEAM then return hashColor(teamName) end
    return ENEMY_COLOR
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

local function button(text, x, y, w, h, color)
    local b = mk("TextButton", {
        Size = UDim2.new(0, w, 0, h), Position = UDim2.new(0, x, 0, y),
        BackgroundColor3 = color, TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold, TextSize = 12, Text = text, AutoButtonColor = true,
    }, frame)
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
    Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, frame)

local targetBtns = {}
local function setTarget(t)
    target = t
    for name, b in pairs(targetBtns) do
        b.BackgroundColor3 = (name == t) and Color3.fromRGB(60, 110, 200) or Color3.fromRGB(70, 70, 70)
    end
end
for i, name in ipairs({"Box", "Skeleton", "Tracer", "All"}) do
    targetBtns[name] = button(name, 10 + (i - 1) * 71, 244, 67, 26, Color3.fromRGB(70, 70, 70))
    targetBtns[name].MouseButton1Click:Connect(function() setTarget(name) end)
end
setTarget("All")

local function applyColor(color)
    if not selected then return end
    local ov = overrides[selected] or {}
    if target == "Box" or target == "All" then ov.box = color end
    if target == "Skeleton" or target == "All" then ov.skel = color end
    if target == "Tracer" or target == "All" then ov.tracer = color end
    overrides[selected] = (ov.box or ov.skel or ov.tracer) and ov or nil
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
    BackgroundTransparency = 1, Text = "Reset = back to ally/enemy color",
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
    local myTeam = getTeam(LocalPlayer)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local teamName, teamColor = getTeam(p)
            local row = mk("TextButton", {
                Name = p.Name:lower(), Size = UDim2.new(1, -6, 0, 24),
                BackgroundColor3 = (p == selected) and Color3.fromRGB(60, 110, 200) or Color3.fromRGB(45, 45, 45),
                TextColor3 = getDisplayColor(teamName, teamColor, myTeam),
                Font = Enum.Font.Gotham, TextSize = 12,
                Text = "  " .. p.DisplayName .. "  [" .. (teamName or "No Team") .. "]",
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            }, list)
            round(row, 4)
            row.MouseButton1Click:Connect(function()
                selected = p
                local _, _, mth = getTeam(p)
                selLabel.Text = "Selected: " .. p.DisplayName .. "  (team from: " .. (mth or "not found") .. ")"
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
    teamCache[player] = nil
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
                local base = getDisplayColor(teamName, teamColor, myTeam)
                local ov = overrides[player]
                local boxColor    = (ov and ov.box)    or base
                local skelColor   = (ov and ov.skel)   or base
                local tracerColor = (ov and ov.tracer) or base

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

                -- tracer points to the head, falls back to HumanoidRootPart
                local head = char:FindFirstChild("Head")
                local headPos = head and select(1, toScreen(head)) or rootPos

                o.tracer.Visible = TRACER_ON
                o.tracer.Color = tracerColor
                o.tracer.From = center
                o.tracer.To = headPos

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

rescan()
for _, p in ipairs(Players:GetPlayers()) do
    create(p)
    local n, _, m = getTeam(p)
    print(("[ESP] %s -> team: %s (from: %s)"):format(p.Name, n or "none", m or "nothing found"))
end
refreshList()

table.insert(conns, Players.PlayerAdded:Connect(function(p)
    create(p) rescan() refreshList()
end))
table.insert(conns, Players.PlayerRemoving:Connect(function(p)
    remove(p) task.defer(refreshList)
end))
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

task.spawn(function()
    while not killed do
        task.wait(1.5)
        if killed then break end
        rescan()
        if frame.Visible then refreshList() end
    end
end)

getgenv().ESP_Unload = kill