local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local FILL_COLOR    = Color3.fromRGB(255, 0, 0)
local OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)

-- remove the previous copy if re-executed
if getgenv().PH_Unload then getgenv().PH_Unload() end

local parent = (gethui and gethui()) or game:GetService("CoreGui")
if parent:FindFirstChild("PlayerHighlightGui") then
    parent.PlayerHighlightGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "PlayerHighlightGui"
gui.ResetOnSpawn = false
gui.Parent = parent

local function mk(class, props, par)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = par
    return o
end
local function round(o, r) Instance.new("UICorner", o).CornerRadius = UDim.new(0, r or 6) end

local frame = mk("Frame", {
    Size = UDim2.new(0, 220, 0, 290), Position = UDim2.new(0, 20, 0.3, 0),
    BackgroundColor3 = Color3.fromRGB(30, 30, 30), Active = true, Draggable = true,
}, gui)
round(frame, 8)

mk("TextLabel", {
    Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1,
    Text = "Highlight Players", TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold, TextSize = 14,
}, frame)

local list = mk("ScrollingFrame", {
    Size = UDim2.new(1, -20, 0, 195), Position = UDim2.new(0, 10, 0, 30),
    BackgroundColor3 = Color3.fromRGB(20, 20, 20), BorderSizePixel = 0,
    ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0),
}, frame)
round(list, 6)
local layout = mk("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.Name}, list)

local function button(text, x, w, color)
    local b = mk("TextButton", {
        Size = UDim2.new(0, w, 0, 30), Position = UDim2.new(0, x, 0, 235),
        BackgroundColor3 = color, TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold, TextSize = 12, Text = text,
    }, frame)
    round(b, 5)
    return b
end

local allBtn   = button("All",   10,  62, Color3.fromRGB(60, 110, 200))
local clearBtn = button("Clear", 79,  62, Color3.fromRGB(90, 60, 60))
local killBtn  = button("KILL",  148, 62, Color3.fromRGB(150, 25, 25))

local targets = {}  -- [player] = {hl = Highlight, conn = connection}
local rows = {}     -- [player] = TextButton

local OFF_COLOR = Color3.fromRGB(45, 45, 45)
local ON_COLOR  = Color3.fromRGB(50, 150, 70)

local function updateRow(p)
    local row = rows[p]
    if row then row.BackgroundColor3 = targets[p] and ON_COLOR or OFF_COLOR end
end

local function enable(p)
    if targets[p] then return end
    local data = {}
    local function apply(char)
        if data.hl then data.hl:Destroy() end
        local hl = Instance.new("Highlight")
        hl.FillColor = FILL_COLOR
        hl.OutlineColor = OUTLINE_COLOR
        hl.FillTransparency = 0.5
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = char
        hl.Parent = char
        data.hl = hl
    end
    if p.Character then apply(p.Character) end
    data.conn = p.CharacterAdded:Connect(apply)
    targets[p] = data
    updateRow(p)
end

local function disable(p)
    local data = targets[p]
    if not data then return end
    data.conn:Disconnect()
    if data.hl then data.hl:Destroy() end
    targets[p] = nil
    updateRow(p)
end

local function addRow(p)
    if p == LocalPlayer or rows[p] then return end
    local row = mk("TextButton", {
        Name = p.Name:lower(), Size = UDim2.new(1, -6, 0, 24),
        BackgroundColor3 = OFF_COLOR, TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.Gotham, TextSize = 12,
        Text = "  " .. p.DisplayName .. " (@" .. p.Name .. ")",
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, list)
    round(row, 4)
    rows[p] = row
    row.MouseButton1Click:Connect(function()
        if targets[p] then disable(p) else enable(p) end
    end)
    list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 4)
end

local function removePlayer(p)
    disable(p)
    if rows[p] then rows[p]:Destroy() rows[p] = nil end
    task.defer(function()
        list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 4)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do addRow(p) end

local conns = {}
table.insert(conns, Players.PlayerAdded:Connect(addRow))
table.insert(conns, Players.PlayerRemoving:Connect(removePlayer))

allBtn.MouseButton1Click:Connect(function()
    for p in pairs(rows) do enable(p) end
end)
clearBtn.MouseButton1Click:Connect(function()
    for p in pairs(rows) do disable(p) end
end)

local function kill()
    for p in pairs(targets) do disable(p) end
    for _, c in ipairs(conns) do c:Disconnect() end
    gui:Destroy()
    getgenv().PH_Unload = nil
end
killBtn.MouseButton1Click:Connect(kill)
getgenv().PH_Unload = kill