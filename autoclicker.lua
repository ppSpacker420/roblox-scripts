local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local autoClick = false

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "AutoClickerGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Main frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 200)
frame.Position = UDim2.new(0.5, -125, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.Parent = gui

-- Title / Drag Bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
title.Text = "Auto Clicker"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 22
title.Parent = frame

-- Make GUI draggable
local dragging = false
local dragStart
local startPos

title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart

		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

-- Auto click button
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 200, 0, 45)
button.Position = UDim2.new(0.5, -100, 0, 50)
button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Text = "Auto M1: OFF"
button.TextSize = 18
button.Parent = frame

-- Destroy button
local destroyButton = Instance.new("TextButton")
destroyButton.Size = UDim2.new(0, 200, 0, 45)
destroyButton.Position = UDim2.new(0.5, -100, 0, 105)
destroyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
destroyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
destroyButton.Text = "Destroy GUI"
destroyButton.TextSize = 18
destroyButton.Parent = frame

-- Toggle auto click
local function toggleAutoClick()
	autoClick = not autoClick

	if autoClick then
		button.Text = "Auto M1: ON"
		button.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
	else
		button.Text = "Auto M1: OFF"
		button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	end
end

button.MouseButton1Click:Connect(toggleAutoClick)

-- F6 toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.F6 then
		toggleAutoClick()
	end
end)

-- Destroy GUI
destroyButton.MouseButton1Click:Connect(function()
	autoClick = false
	gui:Destroy()
end)

-- Auto M1
task.spawn(function()
	while gui.Parent do
		if autoClick then
			VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
			VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
			task.wait(0.1)
		else
			task.wait(0.1)
		end
	end
end)