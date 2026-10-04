--[[
	universal sens + rebindable keybinds
	-----------------------------------
	Universal sensitivity: your mouse moves the camera by the same number of
	degrees per pixel no matter what FOV / zoom the game is using. The engine's
	own look speed scales with FieldOfView, so this script zeroes that out
	(MouseDeltaSensitivity = 0) and drives the camera itself from the raw
	mouse delta with a fixed rad-per-pixel, corrected by BASE_FOV / current FOV.

	Every action below is rebindable: click a row, press a key, done.
	Settings persist between games when the executor has writefile.

	Toggle menu: RightShift (changeable below).
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== config =====

local BASE_FOV = 70 -- the FOV your sens value is calibrated at
local MIN_SENS, MAX_SENS, STEP = 0.02, 3.0, 0.05
local SAVE_FILE = "universal_sens_cfg.json"

local DEFAULT_BINDS = {
	menu = "RightShift",
	sensUp = "PageUp",
	sensDown = "PageDown",
	toggle = "B",
	resetSens = "R",
	resetBinds = "End",
}

local ACTION_LABELS = {
	menu = "Toggle menu",
	sensUp = "Sensitivity +",
	sensDown = "Sensitivity -",
	toggle = "Universal sens on/off",
	resetSens = "Reset sensitivity",
	resetBinds = "Reset keybinds",
}

local ACTIONS = {}
for name in pairs(DEFAULT_BINDS) do
	ACTIONS[#ACTIONS + 1] = name
end
table.sort(ACTIONS)

local binds = {}
for name, key in pairs(DEFAULT_BINDS) do
	binds[name] = key
end

local state = {
	sens = 0.35,
	enabled = true,
	listening = nil, -- action currently waiting for a new key
	yaw = 0,
	pitch = 0,
}

local function clamp(v, lo, hi)
	return math.min(math.max(v, lo), hi)
end

-- ===== persistence (optional) =====

local function loadSettings()
	if not writefile or not readfile or not HttpService then return end
	local ok, raw = pcall(readfile, SAVE_FILE)
	if not ok or type(raw) ~= "string" or raw == "" then return end
	local ok2, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok2 or type(data) ~= "table" then return end
	if type(data.sens) == "number" then
		state.sens = clamp(data.sens, MIN_SENS, MAX_SENS)
	end
	if type(data.enabled) == "boolean" then
		state.enabled = data.enabled
	end
	if type(data.binds) == "table" then
		for _, name in ipairs(ACTIONS) do
			local key = data.binds[name]
			if type(key) == "string" and Enum.KeyCode[key] then
				binds[name] = key
			end
		end
	end
end

local function saveSettings()
	if not writefile or not HttpService then return end
	pcall(function()
		local payload = HttpService:JSONEncode({
			sens = state.sens,
			enabled = state.enabled,
			binds = binds,
		})
		writefile(SAVE_FILE, payload)
	end)
end

-- ===== universal sensitivity =====

local function applySensitivity()
	-- 0 stops the engine applying its own (FOV-dependent) look speed; we
	-- rotate the camera ourselves below.
	UIS.MouseDeltaSensitivity = state.enabled and 0 or 0.3
end

local function currentCamera()
	return workspace.CurrentCamera
end

local function seedOrientation()
	local cam = currentCamera()
	if not cam then return end
	state.yaw, state.pitch = 0, 0
	cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, 0)
end

local function onRenderStep()
	if not state.enabled then return end
	local cam = currentCamera()
	if not cam then return end
	local delta = UIS:GetMouseDelta()
	if not delta or (delta.X == 0 and delta.Y == 0) then return end

	-- rad per pixel, held constant across FOV
	local fov = cam.FieldOfView or BASE_FOV
	local scale = state.sens * (BASE_FOV / fov)

	state.pitch = clamp(state.pitch - delta.Y * scale, -1.55, 1.55)
	state.yaw = state.yaw - delta.X * scale

	cam.CFrame = cam.CFrame * CFrame.Angles(state.pitch, state.yaw, 0)
end

RunService:BindToRenderStep("UniversalSens", 201, onRenderStep)

-- ===== gui =====

local GUI_NAME = "UniversalSensGui"

local old = playerGui:FindFirstChild(GUI_NAME)
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local PANEL_W, PANEL_H = 320, 372

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(PANEL_W, PANEL_H)
panel.Position = UDim2.fromOffset(24, 90)
panel.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
panel.BorderSizePixel = 0
panel.Active = false
panel.ClipsDescendants = true
panel.Parent = gui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
title.BorderSizePixel = 0
title.Text = "UNIVERSAL SENS"
title.TextColor3 = Color3.fromRGB(235, 235, 240)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Active = true -- drag handle
title.ZIndex = 2
title.Parent = panel

-- drag the panel by its title bar
do
	local dragging, startPos, startMouse = false, nil, nil
	title.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			startPos = panel.Position
			startMouse = UIS:GetMouseLocation()
		end
	end)
	title.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	title.InputChanged:Connect(function(input)
		if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		local m = UIS:GetMouseLocation()
		panel.Position = UDim2.fromOffset(
			startPos.X.Offset + (m.X - startMouse.X),
			startPos.Y.Offset + (m.Y - startMouse.Y)
		)
	end)
end

local body = Instance.new("Frame")
body.Name = "Body"
body.Size = UDim2.new(1, -16, 1, -36)
body.Position = UDim2.fromOffset(8, 32)
body.BackgroundTransparency = 1
body.Active = false
body.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = body

local sensLabel = Instance.new("TextLabel")
sensLabel.Name = "SensLabel"
sensLabel.Size = UDim2.new(1, 0, 0, 22)
sensLabel.BackgroundTransparency = 1
sensLabel.TextColor3 = Color3.fromRGB(220, 220, 228)
sensLabel.Font = Enum.Font.GothamMedium
sensLabel.TextSize = 14
sensLabel.TextXAlignment = Enum.TextXAlignment.Left
sensLabel.LayoutOrder = 0
sensLabel.ZIndex = 2
sensLabel.Parent = body

local sensRow = Instance.new("Frame")
sensRow.Name = "SensRow"
sensRow.Size = UDim2.new(1, 0, 0, 28)
sensRow.BackgroundTransparency = 1
sensRow.Active = false
sensRow.LayoutOrder = 1
sensRow.Parent = body

local function makeButton(parent, name, text, order, width)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = UDim2.new(0, width or 92, 1, 0)
	b.BackgroundColor3 = Color3.fromRGB(48, 48, 58)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.fromRGB(235, 235, 240)
	b.Font = Enum.Font.Gotham
	b.TextSize = 14
	b.AutoButtonColor = true
	b.LayoutOrder = order
	b.ZIndex = 2
	b.Parent = parent
	return b
end

local btnDown = makeButton(sensRow, "Down", "-", 0)
btnDown.Position = UDim2.fromOffset(0, 0)
local btnUp = makeButton(sensRow, "Up", "+", 0)
btnUp.Position = UDim2.fromOffset(98, 0)
local btnToggle = makeButton(sensRow, "Toggle", "OFF", 0, 100)
btnToggle.Position = UDim2.fromOffset(196, 0)

local bindHeader = Instance.new("TextLabel")
bindHeader.Name = "BindHeader"
bindHeader.Size = UDim2.new(1, 0, 0, 20)
bindHeader.BackgroundTransparency = 1
bindHeader.Text = "KEYBINDS  (click a key, then press one)"
bindHeader.TextColor3 = Color3.fromRGB(150, 150, 160)
bindHeader.Font = Enum.Font.Gotham
bindHeader.TextSize = 12
bindHeader.TextXAlignment = Enum.TextXAlignment.Left
bindHeader.LayoutOrder = 2
bindHeader.ZIndex = 2
bindHeader.Parent = body

-- one row per action: label + the key that triggers it
local bindButtons = {}
for i, action in ipairs(ACTIONS) do
	local row = Instance.new("Frame")
	row.Name = "Row_" .. action
	row.Size = UDim2.new(1, 0, 0, 26)
	row.BackgroundTransparency = 1
	row.Active = false
	row.LayoutOrder = 2 + i
	row.Parent = body

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -92, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = ACTION_LABELS[action]
	label.TextColor3 = Color3.fromRGB(210, 210, 218)
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 2
	label.Parent = row

	local btn = makeButton(row, "Key", binds[action], 0, 88)
	btn.Position = UDim2.new(1, -88, 0, 0)
	btn.TextSize = 12
	bindButtons[action] = btn

	btn.MouseButton1Click:Connect(function()
		if state.listening then return end
		state.listening = action
		refresh()
	end)
end

-- ===== refresh / actions =====

function refresh()
	sensLabel.Text = string.format("Sensitivity: %.3f", state.sens)
	btnToggle.Text = state.enabled and "ON" or "OFF"
	btnToggle.BackgroundColor3 = state.enabled
		and Color3.fromRGB(38, 92, 58)
		or Color3.fromRGB(92, 44, 44)
	for _, action in ipairs(ACTIONS) do
		local btn = bindButtons[action]
		if state.listening == action then
			btn.Text = "press a key..."
			btn.BackgroundColor3 = Color3.fromRGB(96, 78, 32)
		else
			btn.Text = binds[action]
			btn.BackgroundColor3 = Color3.fromRGB(48, 48, 58)
		end
	end
end

local function runAction(action)
	if action == "menu" then
		gui.Enabled = not gui.Enabled
	elseif action == "sensUp" then
		state.sens = clamp(state.sens + STEP, MIN_SENS, MAX_SENS)
		saveSettings()
		refresh()
	elseif action == "sensDown" then
		state.sens = clamp(state.sens - STEP, MIN_SENS, MAX_SENS)
		saveSettings()
		refresh()
	elseif action == "toggle" then
		state.enabled = not state.enabled
		if state.enabled then seedOrientation() end
		applySensitivity()
		saveSettings()
		refresh()
	elseif action == "resetSens" then
		state.sens = 0.35
		saveSettings()
		refresh()
	elseif action == "resetBinds" then
		for name, key in pairs(DEFAULT_BINDS) do
			binds[name] = key
		end
		saveSettings()
		refresh()
	end
end

btnDown.MouseButton1Click:Connect(function()
	runAction("sensDown")
end)
btnUp.MouseButton1Click:Connect(function()
	runAction("sensUp")
end)
btnToggle.MouseButton1Click:Connect(function()
	runAction("toggle")
end)

UIS.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

	if state.listening then
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			binds[state.listening] = input.KeyCode.Name
			state.listening = nil
			saveSettings()
			refresh()
		end
		return
	end

	if gameProcessed then return end
	local name = input.KeyCode.Name
	for _, action in ipairs(ACTIONS) do
		if binds[action] == name then
			runAction(action)
			return
		end
	end
end)

-- ===== startup =====

loadSettings()
applySensitivity()
if state.enabled then seedOrientation() end
refresh()