--[[
	Save Location / Teleport To Location
	Standalone executor script. Uses writefile so saves persist across re-executes.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local SAVE_FILE = "laptoip_saved_locations.json"
local GUI_NAME = "SaveTpGui"

-- wipe old gui if re-executed
if game.CoreGui:FindFirstChild(GUI_NAME) then
	game.CoreGui:FindFirstChild(GUI_NAME):Destroy()
end

-- ---------- storage ----------
local encode, decode = nil, nil
if syn and syn.request then
	pcall(function()
		local r = game:HttpGet("https://luau-lang.org/")
		encode, decode = loadstring(r)()
	end)
end
if not encode then
	-- fallback: simple positional format, no cjson
	encode = function(t)
		local out = {}
		for i, v in ipairs(t) do
			out[#out + 1] = string.format("%s|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d",
				v.name,
				math.floor(v.cf.Position.X + 0.5),
				math.floor(v.cf.Position.Y + 0.5),
				math.floor(v.cf.Position.Z + 0.5),
				math.floor(v.cf.LookVector.X * 10000 + 0.5),
				math.floor(v.cf.LookVector.Y * 10000 + 0.5),
				math.floor(v.cf.LookVector.Z * 10000 + 0.5),
				math.floor(v.cf.UpVector.X * 10000 + 0.5),
				math.floor(v.cf.UpVector.Y * 10000 + 0.5),
				math.floor(v.cf.UpVector.Z * 10000 + 0.5),
				i)
		end
		return table.concat(out, "\n")
	end
	decode = function(s)
		local t = {}
		for line in tostring(s or ""):gmatch("[^\n]+") do
			local f = {}
			for part in line:gmatch("([^|]*)") do
				f[#f + 1] = part
			end
			if #f >= 11 then
				local pos = Vector3.new(tonumber(f[2]), tonumber(f[3]), tonumber(f[4]))
				local look = Vector3.new(tonumber(f[5]) / 10000, tonumber(f[6]) / 10000, tonumber(f[7]) / 10000)
				local up = Vector3.new(tonumber(f[8]) / 10000, tonumber(f[9]) / 10000, tonumber(f[10]) / 10000)
				table.insert(t, { name = f[1], cf = CFrame.lookAt(pos, pos + look, up) })
			end
		end
		return t
	end
end

local function loadData()
	if writefile and isfile and isfile(SAVE_FILE) then
		local ok, raw = pcall(readfile, SAVE_FILE)
		if ok and type(raw) == "string" and raw ~= "" then
			local ok2, result = pcall(decode, raw)
			if ok2 and type(result) == "table" then
				return result
			end
		end
	end
	return {}
end

local function saveData(list)
	if writefile then
		local ok, raw = pcall(encode, list)
		if ok then
			pcall(writefile, SAVE_FILE, raw)
		end
	end
end

local locations = loadData()

-- ---------- gui ----------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 230, 0, 320)
Frame.Position = UDim2.new(0, 30, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 2
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.Text = "Saved Locations"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = Frame

local NameBox = Instance.new("TextBox")
NameBox.Size = UDim2.new(1, -10, 0, 26)
NameBox.Position = UDim2.new(0, 5, 0, 33)
NameBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
NameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
NameBox.Font = Enum.Font.Gotham
NameBox.TextSize = 12
NameBox.PlaceholderText = "name for this spot"
NameBox.ClearTextOnFocus = false
NameBox.Parent = Frame

local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(1, -10, 1, -105)
ScrollingFrame.Position = UDim2.new(0, 5, 0, 62)
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.ScrollBarThickness = 4
ScrollingFrame.Parent = Frame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollingFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 3)

local function getRoot()
	local char = LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function teleportTo(cf)
	local root = getRoot()
	if not root then
		return
	end
	if cf.Position.Magnitude > 20000 then
		Title.Text = "out of bounds"
		return
	end
	LocalPlayer.Character:PivotTo(cf)
	Title.Text = "teleported"
	task.wait(0.8)
	Title.Text = "Saved Locations"
end

local function deleteAt(index)
	table.remove(locations, index)
	saveData(locations)
	rebuild()
end

local function rebuild()
	for _, child in ipairs(ScrollingFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	if #locations == 0 then
		local empty = Instance.new("TextLabel")
		empty.Name = "Empty"
		empty.Size = UDim2.new(1, 0, 0, 20)
		empty.BackgroundTransparency = 1
		empty.Text = "no saves yet"
		empty.TextColor3 = Color3.fromRGB(120, 120, 120)
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 12
		empty.LayoutOrder = 0
		empty.Parent = ScrollingFrame
		return
	end

	for i, loc in ipairs(locations) do
		local index = i
		local row = Instance.new("TextButton")
		row.Name = "Row"
		row.Size = UDim2.new(1, -6, 0, 26)
		row.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		row.TextColor3 = Color3.fromRGB(255, 255, 255)
		row.Font = Enum.Font.Gotham
		row.TextSize = 12
		row.Text = (i .. ". " .. loc.name)
		row.LayoutOrder = index
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Parent = ScrollingFrame

		row.MouseButton1Click:Connect(function()
			teleportTo(loc.cf)
		end)

		row.MouseButton2Click:Connect(function()
			deleteAt(index)
		end)
	end
end

-- save button
local SaveButton = Instance.new("TextButton")
SaveButton.Size = UDim2.new(0.5, -8, 0, 28)
SaveButton.Position = UDim2.new(0, 5, 1, -33)
SaveButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
SaveButton.Text = "SAVE HERE"
SaveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveButton.Font = Enum.Font.GothamBold
SaveButton.TextSize = 13
SaveButton.Parent = Frame

SaveButton.MouseButton1Click:Connect(function()
	local root = getRoot()
	if not root then
		Title.Text = "no character"
		return
	end
	local name = NameBox.Text
	if name == "" then
		name = "Spot " .. (#locations + 1)
	end
	table.insert(locations, { name = name, cf = root.CFrame })
	saveData(locations)
	NameBox.Text = ""
	rebuild()
	Title.Text = "saved: " .. name
	task.wait(1)
	Title.Text = "Saved Locations"
end)

-- keybind button (clear list)
local ClearButton = Instance.new("TextButton")
ClearButton.Size = UDim2.new(0.5, -8, 0, 28)
ClearButton.Position = UDim2.new(0.5, 3, 1, -33)
ClearButton.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
ClearButton.Text = "CLEAR ALL"
ClearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearButton.Font = Enum.Font.GothamBold
ClearButton.TextSize = 13
ClearButton.Parent = Frame

ClearButton.MouseButton1Click:Connect(function()
	locations = {}
	saveData(locations)
	rebuild()
end)

local Tip = Instance.new("TextLabel")
Tip.Size = UDim2.new(1, -10, 0, 16)
Tip.Position = UDim2.new(0, 5, 1, -50)
Tip.BackgroundTransparency = 1
Tip.Text = "left click = tp   |   right click = delete"
Tip.TextColor3 = Color3.fromRGB(130, 130, 130)
Tip.Font = Enum.Font.Gotham
Tip.TextSize = 10
Tip.Parent = Frame

rebuild()

-- ---------- drag ----------
local dragging, dragInput, dragStart, startPos

Title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = Frame.Position
	end
end)

Title.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		Frame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

Title.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)