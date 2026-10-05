local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local FILL_COLOR    = Color3.fromRGB(255, 0, 0)
local OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)
local NAME_COLOR    = Color3.fromRGB(255, 255, 255)
local PULSE_SPEED   = 0.5 -- lower = faster pulse, higher = slower pulse

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
frame.Size = UDim2.new(0, 220, 0, 320)
frame.Position = UDim2.new(0, 20, 0.4, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -20, 0, 32)
box.Position = UDim2.new(0, 10, 0, 10)
box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
box.TextColor3 = Color3.new(1, 1, 1)
box.PlaceholderText = "Player name"
box.Text = ""
box.Font = Enum.Font.Gotham
box.TextSize = 14
box.ClearTextOnFocus = false
box.Parent = frame
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

local addButton = Instance.new("TextButton")
addButton.Size = UDim2.new(0.5, -15, 0, 32)
addButton.Position = UDim2.new(0, 10, 0, 48)
addButton.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
addButton.TextColor3 = Color3.new(1, 1, 1)
addButton.Font = Enum.Font.GothamBold
addButton.TextSize = 14
addButton.Text = "Add"
addButton.Parent = frame
Instance.new("UICorner", addButton).CornerRadius = UDim.new(0, 6)

local clearButton = Instance.new("TextButton")
clearButton.Size = UDim2.new(0.5, -15, 0, 32)
clearButton.Position = UDim2.new(0.5, 5, 0, 48)
clearButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
clearButton.TextColor3 = Color3.new(1, 1, 1)
clearButton.Font = Enum.Font.GothamBold
clearButton.TextSize = 14
clearButton.Text = "Clear All"
clearButton.Parent = frame
Instance.new("UICorner", clearButton).CornerRadius = UDim.new(0, 6)

local reapplyButton = Instance.new("TextButton")
reapplyButton.Size = UDim2.new(1, -20, 0, 32)
reapplyButton.Position = UDim2.new(0, 10, 0, 86)
reapplyButton.BackgroundColor3 = Color3.fromRGB(100, 150, 200)
reapplyButton.TextColor3 = Color3.new(1, 1, 1)
reapplyButton.Font = Enum.Font.GothamBold
reapplyButton.TextSize = 14
reapplyButton.Text = "Reapply All"
reapplyButton.Parent = frame
Instance.new("UICorner", reapplyButton).CornerRadius = UDim.new(0, 6)

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -20, 0, 18)
hint.Position = UDim2.new(0, 10, 0, 124)
hint.BackgroundTransparency = 1
hint.TextColor3 = Color3.fromRGB(170, 170, 170)
hint.Font = Enum.Font.Gotham
hint.TextSize = 12
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Text = "Highlighted (click a name to remove):"
hint.Parent = frame

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -20, 1, -152)
list.Position = UDim2.new(0, 10, 0, 144)
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
local targets = {} -- targets[player] = { conn = RBXScriptConnection, pulseLoop = thread }

local function findPlayer(name)
    name = name:lower()
    if name == "" then return nil end

    -- exact match first
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and (p.Name:lower() == name or p.DisplayName:lower() == name) then
            return p
        end
    end

    -- partial match second
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and (p.Name:lower():find(name, 1, true) or p.DisplayName:lower():find(name, 1, true)) then
            return p
        end
    end
end

local function removeVisuals(character)
    if not character then return end

    local highlight = character:FindFirstChild("PH_Highlight")
    if highlight then highlight:Destroy() end

    local head = character:FindFirstChild("Head")
    local tag = head and head:FindFirstChild("PH_NameTag")
    if tag then tag:Destroy() end
end

local function startPulseLoop(highlight)
    return task.spawn(function()
        while highlight and highlight.Parent do
            -- fade out from 0.5 to 1.0
            for i = 0, 1, 0.05 do
                if not highlight or not highlight.Parent then return end
                highlight.FillTransparency = 0.5 + (i * 0.5)
                task.wait(PULSE_SPEED / 40)
            end

            -- fade in from 1.0 to 0.5
            for i = 1, 0, -0.05 do
                if not highlight or not highlight.Parent then return end
                highlight.FillTransparency = 0.5 + (i * 0.5)
                task.wait(PULSE_SPEED / 40)
            end
        end
    end)
end

local function applyVisuals(player, character, oldPulseThread)
    removeVisuals(character)

    local highlight = Instance.new("Highlight")
    highlight.Name = "PH_Highlight"
    highlight.FillColor = FILL_COLOR
    highlight.OutlineColor = OUTLINE_COLOR
    highlight.FillTransparency = 0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = character
    highlight.Parent = character

    if oldPulseThread then
        task.cancel(oldPulseThread)
    end

    local pulseLoop = startPulseLoop(highlight)
    if targets[player] then
        targets[player].pulseLoop = pulseLoop
    end

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

local function refreshList()
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    for player in pairs(targets) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -6, 0, 26)
        b.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Font = Enum.Font.Gotham
        b.TextSize = 13
        b.TextTruncate = Enum.TextTruncate.AtEnd
        b.Text = player.DisplayName .. " (@" .. player.Name .. ")"
        b.Parent = list
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)

        b.MouseButton1Click:Connect(function()
            removeTarget(player)
        end)
    end
end

function removeTarget(player)
    local t = targets[player]
    if not t then return end

    if t.conn then
        t.conn:Disconnect()
    end

    if t.pulseLoop then
        task.cancel(t.pulseLoop)
    end

    removeVisuals(player.Character)
    targets[player] = nil
    refreshList()
end

local function addTarget(player)
    if targets[player] then return end

    local t = {}
    targets[player] = t

    if player.Character then
        task.spawn(applyVisuals, player, player.Character, nil)
    end

    t.conn = player.CharacterAdded:Connect(function(char)
        local pulseThread = t.pulseLoop
        applyVisuals(player, char, pulseThread)
    end)

    refreshList()
end

local function flash(text)
    addButton.Text = text
    task.delay(1.2, function()
        addButton.Text = "Add"
    end)
end

local function tryAdd()
    local player = findPlayer(box.Text)
    if not player then
        flash("Not found")
        return
    end

    if targets[player] then
        flash("Already added")
        return
    end

    addTarget(player)
    box.Text = ""
end

local function reapplyAll()
    for player in pairs(targets) do
        if player.Character then
            local t = targets[player]
            applyVisuals(player, player.Character, t.pulseLoop)
        end
    end
    reapplyButton.Text = "Reapplied!"
    task.delay(1, function()
        reapplyButton.Text = "Reapply All"
    end)
end

addButton.MouseButton1Click:Connect(tryAdd)
box.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        tryAdd()
    end
end)

clearButton.MouseButton1Click:Connect(function()
    for player in pairs(targets) do
        removeTarget(player)
    end
end)

reapplyButton.MouseButton1Click:Connect(reapplyAll)

Players.PlayerRemoving:Connect(function(p)
    if targets[p] then
        removeTarget(p)
    end
end)