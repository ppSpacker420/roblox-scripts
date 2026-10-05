local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local LocalPlayer = Players.LocalPlayer

local FILL_COLOR    = Color3.fromRGB(255, 0, 0)
local OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)
local NAME_COLOR    = Color3.fromRGB(255, 255, 255)

-- remove old GUI if re-executed
local parent = (gethui and gethui()) or game:GetService("CoreGui")
if parent:FindFirstChild("PlayerHighlightGui") then
    parent.PlayerHighlightGui:Destroy()
end

------------------------------------------------------------
-- GUI
------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "PlayerHighlightGui"
gui.ResetOnSpawn = false
gui.Parent = parent

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 310)
frame.Position = UDim2.new(0, 20, 0.4, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

-- Auto-highlight toggle
local autoLabel = Instance.new("TextLabel")
autoLabel.Size = UDim2.new(1, -20, 0, 18)
autoLabel.Position = UDim2.new(0, 10, 0, 10)
autoLabel.BackgroundTransparency = 1
autoLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
autoLabel.Font = Enum.Font.Gotham
autoLabel.TextSize = 12
autoLabel.TextXAlignment = Enum.TextXAlignment.Left
autoLabel.Text = "Auto-highlight enemies:"
autoLabel.Parent = frame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 48, 0, 24)
toggleButton.Position = UDim2.new(1, -58, 0, 7)
toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 12
toggleButton.Text = "OFF"
toggleButton.Parent = frame
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 12)

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -20, 0, 32)
box.Position = UDim2.new(0, 10, 0, 38)
box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
box.TextColor3 = Color3.new(1, 1, 1)
box.PlaceholderText = "Player name (manual)"
box.Text = ""
box.Font = Enum.Font.Gotham
box.TextSize = 14
box.ClearTextOnFocus = false
box.Parent = frame
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

local addButton = Instance.new("TextButton")
addButton.Size = UDim2.new(0.5, -15, 0, 32)
addButton.Position = UDim2.new(0, 10, 0, 76)
addButton.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
addButton.TextColor3 = Color3.new(1, 1, 1)
addButton.Font = Enum.Font.GothamBold
addButton.TextSize = 14
addButton.Text = "Add"
addButton.Parent = frame
Instance.new("UICorner", addButton).CornerRadius = UDim.new(0, 6)

local clearButton = Instance.new("TextButton")
clearButton.Size = UDim2.new(0.5, -15, 0, 32)
clearButton.Position = UDim2.new(0.5, 5, 0, 76)
clearButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
clearButton.TextColor3 = Color3.new(1, 1, 1)
clearButton.Font = Enum.Font.GothamBold
clearButton.TextSize = 14
clearButton.Text = "Clear All"
clearButton.Parent = frame
Instance.new("UICorner", clearButton).CornerRadius = UDim.new(0, 6)

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -20, 0, 18)
hint.Position = UDim2.new(0, 10, 0, 114)
hint.BackgroundTransparency = 1
hint.TextColor3 = Color3.fromRGB(170, 170, 170)
hint.Font = Enum.Font.Gotham
hint.TextSize = 12
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Text = "Highlighted (click a name to remove):"
hint.Parent = frame

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -20, 1, -140)
list.Position = UDim2.new(0, 10, 0, 134)
list.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = frame
Instance.new("UICorner", list).CornerRadius = UDim.new(0, 6)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 3)
layout.Parent = list

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 3)
pad.PaddingLeft = UDim.new(0, 3)
pad.PaddingRight = UDim.new(0, 3)
pad.Parent = list

------------------------------------------------------------
-- Targets
------------------------------------------------------------
local targets = {}       -- targets[player] = { conn, auto }
local autoEnabled = false
local autoConnections = {}  -- connections for auto-mode (PlayerAdded, TeamChanged, etc.)

------------------------------------------------------------
-- Team helpers
------------------------------------------------------------
local function getLocalTeam()
    return LocalPlayer.Team  -- nil if not on a team
end

local function isEnemy(player)
    if player == LocalPlayer then return false end
    local myTeam = getLocalTeam()
    if myTeam == nil then return false end          -- no teams in this game/round
    local theirTeam = player.Team
    if theirTeam == nil then return false end       -- they're teamless
    return theirTeam ~= myTeam                      -- different team = enemy
end

------------------------------------------------------------
-- Visuals
------------------------------------------------------------
local function removeVisuals(character)
    if not character then return end
    local h = character:FindFirstChild("PH_Highlight")
    if h then h:Destroy() end
    local head = character:FindFirstChild("Head")
    local tag = head and head:FindFirstChild("PH_NameTag")
    if tag then tag:Destroy() end
end

local function applyVisuals(player, character)
    removeVisuals(character)

    local highlight = Instance.new("Highlight")
    highlight.Name = "PH_Highlight"
    highlight.FillColor = FILL_COLOR
    highlight.OutlineColor = OUTLINE_COLOR
    highlight.FillTransparency = 0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = character
    highlight.Parent = character

    local head = character:WaitForChild("Head", 5)
    if not head then return end

    local tag = Instance.new("BillboardGui")
    tag.Name = "PH_NameTag"
    tag.Adornee = head
    tag.Size = UDim2.new(0, 200, 0, 40)
    tag.StudsOffset = Vector3.new(0, 2.5, 0)
    tag.AlwaysOnTop = true
    tag.Parent = head

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = player.DisplayName .. " (@" .. player.Name .. ")"
    label.TextColor3 = NAME_COLOR
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Parent = tag
end

------------------------------------------------------------
-- Target management
------------------------------------------------------------
local refreshList  -- forward declare

local function removeTarget(player)
    local t = targets[player]
    if not t then return end
    if t.conn then t.conn:Disconnect() end
    removeVisuals(player.Character)
    targets[player] = nil
    refreshList()
end

local function addTarget(player, isAuto)
    if targets[player] then return end

    local t = { auto = isAuto or false }
    targets[player] = t

    if player.Character then
        task.spawn(applyVisuals, player, player.Character)
    end
    t.conn = player.CharacterAdded:Connect(function(char)
        applyVisuals(player, char)
    end)

    refreshList()
end

refreshList = function()
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for player, info in pairs(targets) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -6, 0, 26)
        b.BackgroundColor3 = info.auto
            and Color3.fromRGB(60, 30, 30)   -- auto entries tinted darker red
            or  Color3.fromRGB(45, 45, 45)
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Font = Enum.Font.Gotham
        b.TextSize = 13
        b.TextTruncate = Enum.TextTruncate.AtEnd
        b.Text = (info.auto and "⚔ " or "") .. player.DisplayName .. " (@" .. player.Name .. ")"
        b.Parent = list
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)

        b.MouseButton1Click:Connect(function()
            removeTarget(player)
        end)
    end
end

------------------------------------------------------------
-- Auto-highlight logic
------------------------------------------------------------
local function scanAndHighlightEnemies()
    -- Remove auto-highlights that are no longer enemies
    for player, info in pairs(targets) do
        if info.auto and not isEnemy(player) then
            removeTarget(player)
        end
    end
    -- Add any new enemies
    for _, player in ipairs(Players:GetPlayers()) do
        if isEnemy(player) then
            addTarget(player, true)
        end
    end
end

local function clearAutoConnections()
    for _, c in ipairs(autoConnections) do c:Disconnect() end
    autoConnections = {}
end

local function removeAutoTargets()
    for player, info in pairs(targets) do
        if info.auto then
            removeTarget(player)
        end
    end
end

local function enableAuto()
    autoEnabled = true
    toggleButton.Text = "ON"
    toggleButton.BackgroundColor3 = Color3.fromRGB(50, 180, 80)

    -- Initial scan
    scanAndHighlightEnemies()

    -- Watch for new players joining
    table.insert(autoConnections, Players.PlayerAdded:Connect(function(player)
        if not autoEnabled then return end
        -- Wait a moment for team assignment
        task.delay(1, function()
            if autoEnabled and isEnemy(player) then
                addTarget(player, true)
            end
        end)
    end))

    -- Watch for players leaving
    table.insert(autoConnections, Players.PlayerRemoving:Connect(function(player)
        if targets[player] and targets[player].auto then
            removeTarget(player)
        end
    end))

    -- Watch for team changes on all current and future players
    local function watchTeam(player)
        local c = player:GetPropertyChangedSignal("Team"):Connect(function()
            if not autoEnabled then return end
            if isEnemy(player) then
                addTarget(player, true)
            else
                if targets[player] and targets[player].auto then
                    removeTarget(player)
                end
            end
        end)
        table.insert(autoConnections, c)
    end

    for _, player in ipairs(Players:GetPlayers()) do
        watchTeam(player)
    end
    table.insert(autoConnections, Players.PlayerAdded:Connect(watchTeam))

    -- Watch for local player's own team change (affects who counts as enemy)
    table.insert(autoConnections, LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
        if autoEnabled then
            scanAndHighlightEnemies()
        end
    end))
end

local function disableAuto()
    autoEnabled = false
    toggleButton.Text = "OFF"
    toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    clearAutoConnections()
    removeAutoTargets()
end

toggleButton.MouseButton1Click:Connect(function()
    if autoEnabled then
        disableAuto()
    else
        enableAuto()
    end
end)

------------------------------------------------------------
-- Manual add
------------------------------------------------------------
local function findPlayer(name)
    name = name:lower()
    if name == "" then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and (p.Name:lower() == name or p.DisplayName:lower() == name) then
            return p
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and (p.Name:lower():find(name, 1, true) or p.DisplayName:lower():find(name, 1, true)) then
            return p
        end
    end
end

local function flash(text)
    addButton.Text = text
    task.delay(1.2, function() addButton.Text = "Add" end)
end

local function tryAdd()
    local player = findPlayer(box.Text)
    if not player then flash("Not found") return end
    if targets[player] then flash("Already added") return end
    addTarget(player, false)
    box.Text = ""
end

addButton.MouseButton1Click:Connect(tryAdd)
box.FocusLost:Connect(function(enterPressed)
    if enterPressed then tryAdd() end
end)

clearButton.MouseButton1Click:Connect(function()
    disableAuto()
    for player in pairs(targets) do
        removeTarget(player)
    end
end)

-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(p)
    if targets[p] then removeTarget(p) end
end)