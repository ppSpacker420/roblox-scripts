local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local FILL_COLOR    = Color3.fromRGB(255, 0, 0)
local OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)

-- remove old GUI if re-executed
local parent = (gethui and gethui()) or game:GetService("CoreGui")
if parent:FindFirstChild("PlayerHighlightGui") then
    parent.PlayerHighlightGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "PlayerHighlightGui"
gui.ResetOnSpawn = false
gui.Parent = parent

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0, 20, 0.4, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -20, 0, 35)
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

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -20, 0, 35)
button.Position = UDim2.new(0, 10, 0, 55)
button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.GothamBold
button.TextSize = 14
button.Text = "Highlight: OFF"
button.Parent = frame
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

local target = nil
local highlight = nil
local charConn = nil

local function findPlayer(name)
    name = name:lower()
    if name == "" then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and (p.Name:lower():find(name, 1, true) or p.DisplayName:lower():find(name, 1, true)) then
            return p
        end
    end
end

local function applyHighlight(character)
    if highlight then highlight:Destroy() end
    highlight = Instance.new("Highlight")
    highlight.FillColor = FILL_COLOR
    highlight.OutlineColor = OUTLINE_COLOR
    highlight.FillTransparency = 0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop  -- visible through walls
    highlight.Adornee = character
    highlight.Parent = character
end

local function clear()
    if charConn then charConn:Disconnect() charConn = nil end
    if highlight then highlight:Destroy() highlight = nil end
    target = nil
    button.Text = "Highlight: OFF"
    button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
end

button.MouseButton1Click:Connect(function()
    if target then
        clear()
        return
    end

    local player = findPlayer(box.Text)
    if not player then
        button.Text = "Player not found"
        task.wait(1.2)
        if not target then button.Text = "Highlight: OFF" end
        return
    end

    target = player
    button.Text = "ON: " .. player.Name
    button.BackgroundColor3 = Color3.fromRGB(50, 180, 80)

    if player.Character then applyHighlight(player.Character) end
    charConn = player.CharacterAdded:Connect(applyHighlight)
end)

-- clear if the target leaves the game
Players.PlayerRemoving:Connect(function(p)
    if p == target then clear() end
end)