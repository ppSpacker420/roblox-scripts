--[[
	Player Teleport GUI (Roblox client script)
	Place in StarterPlayer > StarterPlayerScripts or StarterGui.

	Any runtime error is caught and shown ON the GUI, so a broken run tells you
	why instead of showing an empty panel.
]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local LocalPlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Config
local PANEL_WIDTH = 250
local PANEL_HEIGHT = 300
local TITLE_HEIGHT = 30
local BUTTON_HEIGHT = 32
local ROW_HEIGHT = 26
local ROW_PADDING = 4
local LIST_TOP = 36
local LIST_BOTTOM_GAP = 6
local CLAMP_MARGIN = 8

-- Theme
local COLOR = {
	panel = Color3.fromRGB(25, 25, 25),
	titlebar = Color3.fromRGB(32, 32, 32),
	titleText = Color3.fromRGB(235, 235, 235),
	list = Color3.fromRGB(20, 20, 20),
	row = Color3.fromRGB(42, 42, 42),
	rowHover = Color3.fromRGB(58, 58, 58),
	rowSelected = Color3.fromRGB(40, 110, 200),
	action = Color3.fromRGB(50, 150, 50),
	actionHover = Color3.fromRGB(65, 170, 65),
	actionDisabled = Color3.fromRGB(70, 70, 70),
	actionError = Color3.fromRGB(170, 50, 50),
	text = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(150, 150, 150),
}

-- State
local selectedPlayer = nil -- Player, not Instance: characters respawn
local rowByPlayer = {} -- Player -> TextButton
local connections = {}
local guiRefs = {}

-- ===== GUI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeleportGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.DisplayOrder = 10
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayerGui
guiRefs.screenGui = screenGui

local function round(gui, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 4)
	c.Parent = gui
end

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(PANEL_WIDTH, PANEL_HEIGHT)
panel.Position = UDim2.fromOffset(120, 60)
panel.BackgroundColor3 = COLOR.panel
panel.BorderSizePixel = 0
-- Leave Active off on this Frame: an Active ancestor captures the mouse and
-- swallows the scroll wheel, which silently stops the list from scrolling.
-- The title bar below has its own Active=true, which is all dragging needs.
panel.Active = false
panel.ClipsDescendants = true
panel.Parent = screenGui
guiRefs.panel = panel
round(panel, 6)

local titleBar = Instance.new("TextLabel")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.fromOffset(PANEL_WIDTH, TITLE_HEIGHT)
titleBar.BackgroundColor3 = COLOR.titlebar
titleBar.BorderSizePixel = 0
titleBar.Text = "  Player Teleport"
titleBar.TextXAlignment = Enum.TextXAlignment.Left
titleBar.TextColor3 = COLOR.titleText
titleBar.Font = Enum.Font.GothamBold
titleBar.TextSize = 14
titleBar.Active = true -- required or InputBegan never fires
titleBar.ZIndex = 2
titleBar.Parent = panel
guiRefs.titleBar = titleBar

-- List uses explicit pixel offsets so it can never overlap the button,
-- regardless of panel size or DPI.
local listHeight = PANEL_HEIGHT - LIST_TOP - BUTTON_HEIGHT - LIST_BOTTOM_GAP * 2

local list = Instance.new("ScrollingFrame")
list.Name = "PlayerList"
list.Size = UDim2.fromOffset(PANEL_WIDTH - 12, listHeight)
list.Position = UDim2.fromOffset(6, LIST_TOP)
list.BackgroundColor3 = COLOR.list
list.BorderSizePixel = 0
list.Active = true -- a ScrollingFrame needs Active to receive the scroll wheel
list.ScrollBarThickness = 5
list.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.ScrollingEnabled = true
list.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
list.CanvasSize = UDim2.fromOffset(0, 0)
list.AutomaticSize = Enum.AutomaticSize.Y -- canvas grows with content
list.ZIndex = 1
list.Parent = panel
guiRefs.list = list
round(list, 4)

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, ROW_PADDING)
listLayout.Parent = list

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 4)
listPadding.PaddingBottom = UDim.new(0, 4)
listPadding.PaddingLeft = UDim.new(0, 4)
listPadding.PaddingRight = UDim.new(0, 4)
listPadding.Parent = list

local action = Instance.new("TextButton")
action.Name = "TeleportButton"
action.Size = UDim2.fromOffset(PANEL_WIDTH - 12, BUTTON_HEIGHT)
action.Position = UDim2.fromOffset(
	6,
	LIST_TOP + listHeight + LIST_BOTTOM_GAP
)
action.BackgroundColor3 = COLOR.actionDisabled
action.BorderSizePixel = 0
action.AutoButtonColor = false
action.Text = "Select a player"
action.TextColor3 = COLOR.text
action.Font = Enum.Font.GothamBold
action.TextSize = 14
action.TextWrapped = true
action.ZIndex = 3
action.Parent = panel
guiRefs.action = action
round(action, 4)

-- ===== Helpers =====
local function rootPartOf(character)
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function setAction(text, color)
	action.Text = text
	action.BackgroundColor3 = color
end

local function refreshAction()
	if selectedPlayer and Players:FindFirstChild(selectedPlayer.Name) then
		setAction("Teleport to " .. selectedPlayer.DisplayName, COLOR.action)
	else
		selectedPlayer = nil
		setAction("Select a player", COLOR.actionDisabled)
	end
end

local function clearRow(button)
	button.MouseEnter:Disconnect()
	button.MouseLeave:Disconnect()
	button.MouseButton1Click:Disconnect()
	button:Destroy()
end

local function repaintRows()
	for p, b in pairs(rowByPlayer) do
		b.BackgroundColor3 = (selectedPlayer == p) and COLOR.rowSelected or COLOR.row
	end
end

-- ===== Player list =====
local function updatePlayerList()
	for player, button in pairs(rowByPlayer) do
		if not player.Parent then -- left between render and now
			clearRow(button)
			rowByPlayer[player] = nil
		end
	end

	local names = {}
	-- pairs() yields the KEY (an index), so the value is the second return.
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Parent then
			names[#names + 1] = player.Name
		end
	end
	table.sort(names, function(a, b)
		return a:lower() < b:lower()
	end)

	local order = 0
	for _, name in ipairs(names) do
		order = order + 1
		local player = Players:FindFirstChild(name)
		if player then
			local button = rowByPlayer[player]

			if not button then
				button = Instance.new("TextButton")
				button.Name = "Row_" .. name
				button.Size = UDim2.new(1, -8, 0, ROW_HEIGHT)
				button.BackgroundColor3 = COLOR.row
				button.BorderSizePixel = 0
				button.AutoButtonColor = false
				button.Font = Enum.Font.Gotham
				button.TextSize = 12
				button.TextColor3 = COLOR.text
				button.TextTruncate = Enum.TextTruncate.AtEnd
				button.ZIndex = 1
				button.Parent = list
				round(button, 4)

				connections[#connections + 1] = button.MouseEnter:Connect(function()
					if button.BackgroundColor3 ~= COLOR.rowSelected then
						button.BackgroundColor3 = COLOR.rowHover
					end
				end)
				connections[#connections + 1] = button.MouseLeave:Connect(function()
					button.BackgroundColor3 =
						(selectedPlayer == player) and COLOR.rowSelected or COLOR.row
				end)
				connections[#connections + 1] = button.MouseButton1Click:Connect(function()
					selectedPlayer = (selectedPlayer == player) and nil or player
					repaintRows()
					refreshAction()
				end)

				rowByPlayer[player] = button
			end

			button.LayoutOrder = order
			button.Text = (player.DisplayName ~= player.Name)
				and (player.DisplayName .. "  (@" .. player.Name .. ")")
				or player.DisplayName
			button.BackgroundColor3 = (selectedPlayer == player) and COLOR.rowSelected or COLOR.row
		end
	end

	-- Rows can be destroyed while the list is scrolled down, which would leave
	-- CanvasPosition past the new end and show empty space. Pull it back.
	local contentHeight = order * (ROW_HEIGHT + ROW_PADDING) + 8
	local maxScroll = math.max(0, contentHeight - listHeight)
	if list.CanvasPosition.Y > maxScroll then
		list.CanvasPosition = Vector2.new(0, maxScroll)
	end

	refreshAction()
end

-- ===== Teleport =====
connections[#connections + 1] = action.MouseButton1Click:Connect(function()
	if not selectedPlayer or not selectedPlayer.Parent then
		refreshAction()
		return
	end

	-- Resolve both parts at teleport time: either character can respawn or die.
	local target = rootPartOf(selectedPlayer.Character)
	local self = rootPartOf(LocalPlayer.Character)
	if not target or not self then
		setAction("Target unavailable", COLOR.actionError)
		return
	end

	-- Keep the local player's facing direction instead of copying the target's.
	local offset = self.CFrame.LookVector * -4 + Vector3.new(0, 2, 0)
	self.CFrame = target.CFrame + offset
	refreshAction()
end)

connections[#connections + 1] = action.MouseEnter:Connect(function()
	if selectedPlayer then
		action.BackgroundColor3 = COLOR.actionHover
	end
end)
connections[#connections + 1] = action.MouseLeave:Connect(function()
	refreshAction()
end)

-- ===== Roster changes =====
connections[#connections + 1] = Players.PlayerAdded:Connect(function()
	updatePlayerList()
end)
connections[#connections + 1] = Players.PlayerRemoving:Connect(function(player)
	local button = rowByPlayer[player]
	if button then
		clearRow(button)
		rowByPlayer[player] = nil
	end
	if selectedPlayer == player then
		selectedPlayer = nil
	end
	updatePlayerList()
end)

-- ===== Draggable panel, clamped to the viewport =====
local dragging, dragStart, startPos

local function clampPosition(x, y)
	local camera = workspace.CurrentCamera
	local size = panel.AbsoluteSize
	if not camera then
		return UDim2.fromOffset(x, y)
	end
	local view = camera.ViewportSize
	local w = size.X > 0 and size.X or PANEL_WIDTH
	local h = size.Y > 0 and size.Y or PANEL_HEIGHT
	local maxX = math.max(0, view.X - w - CLAMP_MARGIN)
	local maxY = math.max(0, view.Y - h - CLAMP_MARGIN)
	return UDim2.fromOffset(
		math.clamp(x, CLAMP_MARGIN - w, maxX),
		math.clamp(y, 0, maxY)
	)
end

local function isDragInput(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

connections[#connections + 1] = titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = panel.Position
	end
end)

connections[#connections + 1] = UserInputService.InputChanged:Connect(function(input)
	if not dragging or not isDragInput(input) then
		return
	end
	local delta = input.Position - dragStart
	-- Force offset-based position so dragging is 1:1 with the cursor.
	panel.Position = clampPosition(
		startPos.X.Offset + delta.X,
		startPos.Y.Offset + delta.Y
	)
end)

connections[#connections + 1] = UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- ===== Error trap: show failures on the GUI instead of an empty panel =====
local function showError(message)
	local label = Instance.new("TextLabel")
	label.Name = "ErrorLabel"
	label.Size = UDim2.fromOffset(PANEL_WIDTH - 12, PANEL_HEIGHT - LIST_TOP - 10)
	label.Position = UDim2.fromOffset(6, LIST_TOP + 5)
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.TextColor3 = COLOR.actionError
	label.Font = Enum.Font.Code
	label.TextSize = 11
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Text = "Error:\n" .. tostring(message)
	label.ZIndex = 10
	label.Parent = panel
	setAction("Failed to start", COLOR.actionError)
end

-- Run the risky part under xpcall so a failure is visible on screen.
local ok, err = xpcall(function()
	updatePlayerList()
end, function(e)
	return tostring(e) .. "\n" .. debug.traceback("", 2)
end)

if not ok then
	warn("TeleportGui failed: " .. tostring(err))
	showError(err)
end

-- ===== Teardown =====
screenGui.Destroying:Connect(function()
	for _, connection in pairs(connections) do
		connection:Disconnect()
	end
	rowByPlayer = {}
end)
