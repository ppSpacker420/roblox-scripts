--[[
	Player Teleport GUI
	Rework of the original script: same features, cleaner structure.
	Select a player from the list, press Teleport.
]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local GUI_WIDTH = 250
local GUI_HEIGHT = 300
local TELEPORT_HEIGHT = 3 -- studs above the target

-- Theme
local COLORS = {
	Frame = Color3.fromRGB(25, 25, 25),
	Title = Color3.fromRGB(30, 30, 30),
	List = Color3.fromRGB(20, 20, 20),
	Button = Color3.fromRGB(50, 150, 50),
	Row = Color3.fromRGB(40, 40, 40),
	RowSelected = Color3.fromRGB(55, 90, 55),
	Text = Color3.fromRGB(255, 255, 255),
	Placeholder = Color3.fromRGB(150, 150, 150),
}

local DEFAULT_TELEPORT_TEXT = "Teleport"

-- State (UI elements are declared up front so the functions below can close over them)
local target: Player? = nil
local gui: Frame = nil :: any
local scroller: ScrollingFrame = nil :: any
local emptyLabel: TextLabel = nil :: any
local teleportButton: TextButton = nil :: any
local playerRows: { [Player]: TextButton } = {}

-- Helpers
local function new(className, properties, children)
	local instance = Instance.new(className)
	for property, value in properties do
		instance[property] = value
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	return instance
end

local function setRowColors(row: TextButton, selected: boolean)
	row.BackgroundColor3 = selected and COLORS.RowSelected or COLORS.Row
end

local function setTarget(player: Player?)
	target = player
	teleportButton.Text = if player then "Teleport to: " .. player.Name else DEFAULT_TELEPORT_TEXT
	for rowPlayer, row in playerRows do
		setRowColors(row, rowPlayer == player)
	end
end

-- List ----------------------------------------------------------------
local function rebuildRows()
	for _, row in playerRows do
		row:Destroy()
	end
	table.clear(playerRows)

	local others = {}
	for _, player in Players:GetPlayers() do
		if player ~= LocalPlayer then
			table.insert(others, player)
		end
	end
	table.sort(others, function(a, b)
		return a.Name:lower() < b.Name:lower()
	end)

	for index, player in others do
		local row = new("TextButton", {
			Size = UDim2.new(1, -10, 0, 25),
			BackgroundColor3 = COLORS.Row,
			Text = player.DisplayName,
			TextColor3 = COLORS.Text,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			LayoutOrder = index,
			AutoButtonColor = false,
		}, {
			new("UICorner", { CornerRadius = UDim.new(0, 4) }),
		})
		row.Parent = scroller
		playerRows[player] = row

		row.MouseButton1Click:Connect(function()
			setTarget(player)
		end)
		row.MouseEnter:Connect(function()
			if target ~= player then
				row.BackgroundColor3 = COLORS.Row:Lerp(COLORS.Title, 0.5)
			end
		end)
		row.MouseLeave:Connect(function()
			setRowColors(row, target == player)
		end)

		setRowColors(row, target == player)
	end

	if #others == 0 then
		emptyLabel.Visible = true
	else
		emptyLabel.Visible = false
	end

	-- The selected player may have left
	if target and not playerRows[target] then
		setTarget(nil)
	end
end

-- Teleport -----------------------------------------------------------
local function teleportTo(player: Player)
	local myCharacter = LocalPlayer.Character
	local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
	local theirCharacter = player.Character
	local theirRoot = theirCharacter and theirCharacter:FindFirstChild("HumanoidRootPart")

	if not myRoot or not theirRoot then
		return false
	end

	myRoot.CFrame = theirRoot.CFrame + Vector3.new(0, TELEPORT_HEIGHT, 0)
	return true
end

local function onTeleportClick()
	if not target then
		return
	end
	if not teleportTo(target) then
		teleportButton.Text = "Target not ready"
		task.delay(1, function()
			if target then
				setTarget(target)
			end
		end)
	end
end

-- Dragging -----------------------------------------------------------
local function makeDraggable(handle: GuiObject, target: Instance)
	local dragging = false
	local dragStart = Vector2.zero
	local startPos = UDim2.zero

	handle.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
		end
	end)

	handle.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if not dragging then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local delta = input.Position - dragStart
		local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
			or Vector2.new(gui.Frame.AbsoluteSize.X, gui.Frame.AbsoluteSize.Y)
		local size = target.AbsoluteSize

		-- Clamp so the panel can never be dragged fully off screen
		local x = math.clamp(startPos.X.Offset + delta.X, -size.X + 40, viewport.X - 40)
		local y = math.clamp(startPos.Y.Offset + delta.Y, 0, viewport.Y - 40)
		target.Position = UDim2.new(startPos.X.Scale, x, startPos.Y.Scale, y)
	end)
end

-- Build --------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerTeleportGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

-- Re-running the script should not stack duplicate windows
local previous = game.CoreGui:FindFirstChild(screenGui.Name)
if previous then
	previous:Destroy()
end

gui = new("Frame", {
	Size = UDim2.fromOffset(GUI_WIDTH, GUI_HEIGHT),
	Position = UDim2.new(0.5, -GUI_WIDTH / 2, 0.4, 0),
	BackgroundColor3 = COLORS.Frame,
	BorderSizePixel = 2,
	Active = true,
	Parent = screenGui,
})

new("UICorner", { CornerRadius = UDim.new(0, 6) }, { gui })

local title = new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundColor3 = COLORS.Title,
	Text = "Player Teleport GUI",
	TextColor3 = COLORS.Text,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	Active = true,
	Parent = gui,
})

scroller = new("ScrollingFrame", {
	Size = UDim2.new(1, -10, 1, -70),
	Position = UDim2.fromOffset(5, 35),
	BackgroundColor3 = COLORS.List,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = COLORS.Text,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = gui,
})

new("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 4),
	Parent = scroller,
})

emptyLabel = new("TextLabel", {
	Size = UDim2.new(1, -10, 0, 25),
	BackgroundTransparency = 1,
	Text = "No other players",
	TextColor3 = COLORS.Placeholder,
	Font = Enum.Font.Gotham,
	TextSize = 12,
	Visible = false,
	Parent = scroller,
})

teleportButton = new("TextButton", {
	Size = UDim2.new(1, -10, 0, 30),
	Position = UDim2.new(0, 5, 1, -35),
	BackgroundColor3 = COLORS.Button,
	Text = DEFAULT_TELEPORT_TEXT,
	TextColor3 = COLORS.Text,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	AutoButtonColor = false,
	Parent = gui,
}, {
	new("UICorner", { CornerRadius = UDim.new(0, 4) }),
})

teleportButton.MouseButton1Click:Connect(onTeleportClick)

makeDraggable(title, gui)

Players.PlayerAdded:Connect(rebuildRows)
Players.PlayerRemoving:Connect(rebuildRows)
LocalPlayer.CharacterAdded:Connect(rebuildRows)
rebuildRows()

