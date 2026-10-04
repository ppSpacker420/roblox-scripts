--[[
	Player Teleport GUI (Roblox client script)
	Place in StarterPlayer > StarterPlayerScripts or StarterGui.
]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local LocalPlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Config
local PANEL_SIZE = UDim2.fromOffset(250, 300)
local ROW_HEIGHT = 26
local CLAMP_MARGIN = 8 -- keep this much panel on-screen at all times

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
	text = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(160, 160, 160),
}

-- State
local selectedPlayer = nil -- Player, not Instance: characters respawn
local rowByPlayer = {} -- Player -> TextButton
local connections = {}

-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeleportGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.DisplayOrder = 10
screenGui.Parent = LocalPlayerGui

local panel = Instance.new("Frame")
panel.Size = PANEL_SIZE
panel.Position = UDim2.new(0.5, -PANEL_SIZE.X.Offset / 2, 0.35, 0)
panel.BackgroundColor3 = COLOR.panel
panel.BorderSizePixel = 0
panel.Active = true -- so the title bar receives mouse input
panel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = panel

local titleBar = Instance.new("TextLabel")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = COLOR.titlebar
titleBar.BorderSizePixel = 0
titleBar.Text = "  Player Teleport"
titleBar.TextXAlignment = Enum.TextXAlignment.Left
titleBar.TextColor3 = COLOR.titleText
titleBar.Font = Enum.Font.GothamBold
titleBar.TextSize = 14
titleBar.Parent = panel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 6)
titleCorner.Parent = titleBar

local list = Instance.new("ScrollingFrame")
list.Name = "PlayerList"
list.Size = UDim2.new(1, -12, 1, -72)
list.Position = UDim2.fromOffset(6, 36)
list.BackgroundColor3 = COLOR.list
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
list.AutoCanvasSize = Enum.AutomaticSize.Y -- grows with content, no hardcoded row count
list.CanvasSize = UDim2.new() -- overridden by AutoCanvasSize
list.Parent = panel

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 4)
listCorner.Parent = list

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = list

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 4)
listPadding.PaddingBottom = UDim.new(0, 4)
listPadding.PaddingLeft = UDim.new(0, 4)
listPadding.PaddingRight = UDim.new(0, 4)
listPadding.Parent = list

local action = Instance.new("TextButton")
action.Name = "TeleportButton"
action.AnchorPoint = Vector2.new(0, 1)
action.Size = UDim2.new(1, -12, 0, 32)
action.Position = UDim2.new(0, 6, 1, -6)
action.BackgroundColor3 = COLOR.action
action.BorderSizePixel = 0
action.AutoButtonColor = false
action.Text = "Select a player"
action.TextColor3 = COLOR.text
action.Font = Enum.Font.GothamBold
action.TextSize = 14
action.Parent = panel

local actionCorner = Instance.new("UICorner")
actionCorner.CornerRadius = UDim.new(0, 4)
actionCorner.Parent = action

-- Helpers
local function clearRow(button)
	button.MouseEnter:Disconnect()
	button.MouseLeave:Disconnect()
	button.MouseButton1Click:Disconnect()
	button:Destroy()
end

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

local function refreshAction()
	if selectedPlayer and Players:FindFirstChild(selectedPlayer.Name) then
		action.Text = string.format("Teleport to %s", selectedPlayer.DisplayName)
		action.BackgroundColor3 = COLOR.action
	else
		selectedPlayer = nil
		action.Text = "Select a player"
		action.BackgroundColor3 = COLOR.actionDisabled
	end
end

-- Player list
local function updatePlayerList()
	for player, button in pairs(rowByPlayer) do
		if not player.Parent then -- left between render and now
			clearRow(button)
			rowByPlayer[player] = nil
		end
	end

	local names = {}
	for player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			names[#names + 1] = player.Name
		end
	end
	table.sort(names, function(a, b)
		return a:lower() < b:lower()
	end)

	local order = 0
	for _, name in ipairs(names) do
		order = order + 1
		local player = Players[name]
		local button = rowByPlayer[player]

		if not button then
			button = Instance.new("TextButton")
			button.Size = UDim2.new(1, -8, 0, ROW_HEIGHT)
			button.BackgroundColor3 = COLOR.row
			button.BorderSizePixel = 0
			button.AutoButtonColor = false
			button.Font = Enum.Font.Gotham
			button.TextSize = 12
			button.TextColor3 = COLOR.text
			button.TextTruncate = Enum.TextTruncate.AtEnd
			button.Parent = list

			local rowCorner = Instance.new("UICorner")
			rowCorner.CornerRadius = UDim.new(0, 4)
			rowCorner.Parent = button

			connections[#connections + 1] = button.MouseEnter:Connect(function()
				if button.BackgroundColor3 ~= COLOR.rowSelected then
					button.BackgroundColor3 = COLOR.rowHover
				end
			end)
			connections[#connections + 1] = button.MouseLeave:Connect(function()
				button.BackgroundColor3 = (selectedPlayer == player) and COLOR.rowSelected or COLOR.row
			end)
			connections[#connections + 1] = button.MouseButton1Click:Connect(function()
				-- deselect if clicking the already-selected row
				selectedPlayer = (selectedPlayer == player) and nil or player
				for p, b in pairs(rowByPlayer) do
					b.BackgroundColor3 = (p == selectedPlayer) and COLOR.rowSelected or COLOR.row
				end
				refreshAction()
			end)

			rowByPlayer[player] = button
		end

		button.LayoutOrder = order
		button.Text = player.DisplayName .. (player.DisplayName == player.Name and "" or ("  (@" .. player.Name .. ")"))
		button.BackgroundColor3 = (selectedPlayer == player) and COLOR.rowSelected or COLOR.row
	end

	refreshAction()
end

-- Teleport
connections[#connections + 1] = action.MouseButton1Click:Connect(function()
	if not selectedPlayer or not selectedPlayer.Parent then
		refreshAction()
		return
	end

	-- Resolve both parts at teleport time: either character can respawn or die.
	local target = rootPartOf(selectedPlayer.Character)
	local self = rootPartOf(LocalPlayer.Character)
	if not target or not self then
		return
	end

	-- Preserve the local player's facing direction instead of copying theirs.
	local offset = self.CFrame.LookVector * -4 + Vector3.new(0, 2, 0)
	self.CFrame = target.CFrame + offset
end)

connections[#connections + 1] = action.MouseEnter:Connect(function()
	if selectedPlayer then
		action.BackgroundColor3 = COLOR.actionHover
	end
end)
connections[#connections + 1] = action.MouseLeave:Connect(function()
	refreshAction()
end)

-- Player roster changes
connections[#connections + 1] = Players.PlayerAdded:Connect(updatePlayerList)
connections[#connections + 1] = Players.PlayerRemoving:Connect(updatePlayerList)

-- Draggable panel, clamped to the viewport
local dragging, dragStart, startPos

local function clampPosition(position)
	local camera = workspace.CurrentCamera
	if not camera then
		return position
	end
	local view = camera.ViewportSize
	local size = panel.AbsoluteSize
	local maxX = math.max(0, view.X - size.X - CLAMP_MARGIN)
	local maxY = math.max(0, view.Y - size.Y - CLAMP_MARGIN)
	return UDim2.fromOffset(
		math.clamp(position.X.Offset, CLAMP_MARGIN - size.X, maxX),
		math.clamp(position.Y.Offset, 0, maxY)
	)
end

connections[#connections + 1] = titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = panel.Position
	end
end)

connections[#connections + 1] = UserInputService.InputChanged:Connect(function(input)
	if not dragging then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart
		-- Force offset-based position so dragging is 1:1 with the cursor.
		panel.Position = clampPosition(UDim2.fromOffset(
			startPos.X.Offset + delta.X,
			startPos.Y.Offset + delta.Y
		))
	end
end)

connections[#connections + 1] = UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

updatePlayerList()

-- Teardown: disconnect everything if the GUI is ever destroyed
screenGui.Destroying:Connect(function()
	for _, connection in pairs(connections) do
		connection:Disconnect()
	end
	rowByPlayer = {}
end)
