-- No Skill Check Script for Roblox
-- Keybind: RightShift to open/close (minimize) GUI
-- Turn Exit Button: Completely closes the program

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer

-- Variables to track states
local noSkillCheckEnabled = false

-- Connections for cleanup
local noSkillCheckConnections = {}
local keybindConnection

-- Track if script is running
local scriptRunning = true

-- ========== NO SKILL CHECK FUNCTION ==========
local skillCheckNames = {
    "SkillCheckPromptGui",
    "SkillCheckPromptGui-con",
    "SkillCheckEvent",
    "SkillCheckFailEvent",
    "SkillCheckResultEvent",
    "SkillCheckGui",
    "SkillCheck",
    "SkillCheckPrompt",
    "Skillcheck"
}

local function isSkillCheckObject(obj)
    if not obj or not obj.Name then return false end
    local name = string.lower(obj.Name)
    
    -- Check exact names
    for _, skillName in ipairs(skillCheckNames) do
        if name == string.lower(skillName) then
            return true
        end
    end
    
    -- Check for "skillcheck" in name
    if string.find(name, "skillcheck") or string.find(name, "skill check") then
        return true
    end
    
    -- Check for skillcheck in parent names
    if obj.Parent then
        local parentName = string.lower(obj.Parent.Name)
        if string.find(parentName, "skillcheck") or string.find(parentName, "skill check") then
            return true
        end
    end
    
    return false
end

local function removeSkillCheckObject(obj)
    pcall(function()
        if isSkillCheckObject(obj) then
            -- If it's a GUI, disable and destroy it
            if obj:IsA("ScreenGui") or obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") then
                obj.Enabled = false
                obj.Visible = false
            end
            
            -- Destroy the object
            obj:Destroy()
            return true
        end
    end)
    return false
end

local function initialSkillCheckCleanup()
    -- Clean skill checks from all relevant places
    local placesToCheck = {
        LP:FindFirstChild("PlayerGui"),
        StarterGui,
        ReplicatedStorage
    }
    
    for _, place in ipairs(placesToCheck) do
        if place then
            for _, obj in ipairs(place:GetDescendants()) do
                removeSkillCheckObject(obj)
            end
        end
    end
end

local function toggleNoSkillCheck(state)
    noSkillCheckEnabled = state
    
    -- Clear existing connections
    for _, conn in ipairs(noSkillCheckConnections) do
        pcall(function() conn:Disconnect() end)
    end
    noSkillCheckConnections = {}
    
    if state then
        -- Initial cleanup
        initialSkillCheckCleanup()
        
        -- Monitor for new skill check objects
        local function monitorDescendantAdded(parent)
            local conn = parent.DescendantAdded:Connect(function(obj)
                if not scriptRunning then return end
                task.wait(0.1)
                removeSkillCheckObject(obj)
            end)
            table.insert(noSkillCheckConnections, conn)
        end
        
        -- Monitor all relevant places
        local placesToMonitor = {
            LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui", 5),
            StarterGui,
            ReplicatedStorage
        }
        
        for _, place in ipairs(placesToMonitor) do
            if place then
                monitorDescendantAdded(place)
            end
        end
        
        -- Also monitor PlayerGui creation if it doesn't exist yet
        if not LP:FindFirstChild("PlayerGui") then
            local conn = LP.ChildAdded:Connect(function(child)
                if child:IsA("PlayerGui") then
                    monitorDescendantAdded(child)
                end
            end)
            table.insert(noSkillCheckConnections, conn)
        end
        
        print("No Skill Check enabled - skill checks will be blocked")
    else
        print("No Skill Check disabled")
    end
end

-- ========== GUI CREATION ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SkillCheckGUI"
ScreenGui.Parent = LP:WaitForChild("PlayerGui")

-- GUI size (smaller since we only have one feature)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 250, 0, 200)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -100)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
MainFrame.Visible = false -- Start hidden
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.Text = "Skill Check Manager"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- No Skill Check Toggle
local NoSkillToggle = Instance.new("TextButton")
NoSkillToggle.Name = "NoSkillToggle"
NoSkillToggle.Size = UDim2.new(0.8, 0, 0, 40)
NoSkillToggle.Position = UDim2.new(0.1, 0, 0.25, 0)
NoSkillToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
NoSkillToggle.Text = "No Skill Check: OFF"
NoSkillToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
NoSkillToggle.TextSize = 16
NoSkillToggle.Font = Enum.Font.Gotham
NoSkillToggle.Parent = MainFrame

-- Minimize Button
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.new(0.8, 0, 0, 40)
MinimizeButton.Position = UDim2.new(0.1, 0, 0.45, 0)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(180, 120, 60)
MinimizeButton.Text = "Minimize GUI"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.TextSize = 16
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Parent = MainFrame

-- TURN EXIT Button (Closes entire program)
local TurnExitButton = Instance.new("TextButton")
TurnExitButton.Name = "TurnExitButton"
TurnExitButton.Size = UDim2.new(0.8, 0, 0, 40)
TurnExitButton.Position = UDim2.new(0.1, 0, 0.65, 0)
TurnExitButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
TurnExitButton.Text = "TURN EXIT (Close Program)"
TurnExitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TurnExitButton.TextSize = 16
TurnExitButton.Font = Enum.Font.GothamBold
TurnExitButton.Parent = MainFrame

-- Mini Icon (visible when GUI is minimized)
local MiniIcon = Instance.new("TextButton")
MiniIcon.Name = "MiniIcon"
MiniIcon.Size = UDim2.new(0, 50, 0, 50)
MiniIcon.Position = UDim2.new(0, 20, 0, 20)
MiniIcon.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MiniIcon.BorderSizePixel = 2
MiniIcon.BorderColor3 = Color3.fromRGB(60, 60, 60)
MiniIcon.Text = "SC"
MiniIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniIcon.TextSize = 14
MiniIcon.Font = Enum.Font.GothamBold
MiniIcon.Visible = true -- Start visible as minimized
MiniIcon.Parent = ScreenGui

-- Mini Icon Title (tooltip)
local MiniTooltip = Instance.new("TextLabel")
MiniTooltip.Name = "MiniTooltip"
MiniTooltip.Size = UDim2.new(0, 120, 0, 30)
MiniTooltip.Position = UDim2.new(0, 75, 0, 20)
MiniTooltip.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MiniTooltip.BorderSizePixel = 1
MiniTooltip.BorderColor3 = Color3.fromRGB(80, 80, 80)
MiniTooltip.Text = "Skill Check Manager\nRightShift to open"
MiniTooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniTooltip.TextSize = 12
MiniTooltip.Font = Enum.Font.Gotham
MiniTooltip.TextYAlignment = Enum.TextYAlignment.Top
MiniTooltip.Visible = false
MiniTooltip.Parent = ScreenGui

-- ========== BUTTON FUNCTIONS ==========

-- No Skill Check toggle
NoSkillToggle.MouseButton1Click:Connect(function()
    noSkillCheckEnabled = not noSkillCheckEnabled
    toggleNoSkillCheck(noSkillCheckEnabled)
    NoSkillToggle.Text = "No Skill Check: " .. (noSkillCheckEnabled and "ON" or "OFF")
    NoSkillToggle.BackgroundColor3 = noSkillCheckEnabled and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(60, 60, 60)
    print("No Skill Check:", noSkillCheckEnabled and "Enabled" or "Disabled")
end)

-- Minimize button (hides GUI but keeps script running)
MinimizeButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MiniIcon.Visible = true
    print("GUI minimized - script still running, use RightShift to reopen")
end)

-- TURN EXIT button (completely closes the program)
TurnExitButton.MouseButton1Click:Connect(function()
    print("TURN EXIT pressed - closing program...")
    
    -- Mark script as not running
    scriptRunning = false
    
    -- Disable all features
    if noSkillCheckEnabled then 
        toggleNoSkillCheck(false)
        print("No Skill Check disabled")
    end
    
    -- Disconnect all connections
    for _, conn in ipairs(noSkillCheckConnections) do
        pcall(function() conn:Disconnect() end)
    end
    
    if keybindConnection then
        keybindConnection:Disconnect()
    end
    
    -- Destroy GUI
    ScreenGui:Destroy()
    
    -- Clear references
    noSkillCheckConnections = {}
    keybindConnection = nil
    
    print("Program completely closed. To use again, re-execute the script.")
end)

-- Mini Icon click to restore
MiniIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MiniIcon.Visible = false
    MiniTooltip.Visible = false
    print("GUI restored")
end)

-- Mini Icon hover tooltip
MiniIcon.MouseEnter:Connect(function()
    MiniTooltip.Visible = true
end)

MiniIcon.MouseLeave:Connect(function()
    MiniTooltip.Visible = false
end)

-- ========== KEYBIND ==========

-- Keybind function to toggle GUI visibility
local function toggleGUI()
    if MainFrame.Visible then
        -- Minimize
        MainFrame.Visible = false
        MiniIcon.Visible = true
        MiniTooltip.Visible = false
    else
        -- Restore
        MainFrame.Visible = true
        MiniIcon.Visible = false
        MiniTooltip.Visible = false
    end
end

-- Set up keybind (RightShift)
keybindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and scriptRunning then
        if input.KeyCode == Enum.KeyCode.RightShift then
            toggleGUI()
        end
    end
end)

-- ========== DRAGGABLE GUI ==========

-- Make GUI draggable
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Make mini icon draggable too
local miniDragging
local miniDragInput
local miniDragStart
local miniStartPos

MiniIcon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        miniDragging = true
        miniDragStart = input.Position
        miniStartPos = MiniIcon.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                miniDragging = false
            end
        end)
    end
end)

MiniIcon.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        miniDragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == miniDragInput and miniDragging then
        local delta = input.Position - miniDragStart
        MiniIcon.Position = UDim2.new(miniStartPos.X.Scale, miniStartPos.X.Offset + delta.X, miniStartPos.Y.Scale, miniStartPos.Y.Offset + delta.Y)
        MiniTooltip.Position = UDim2.new(miniStartPos.X.Scale, miniStartPos.X.Offset + delta.X + 55, miniStartPos.Y.Scale, miniStartPos.Y.Offset + delta.Y)
    end
end)

-- ========== INITIALIZATION ==========

print("=====================================")
print("Skill Check Script Loaded!")
print("Keybind: RightShift to open/close GUI")
print("Feature:")
print("No Skill Check - Blocks skill check minigames")
print("=====================================")
print("GUI starts minimized - click the 'SC' icon or press RightShift")
print("TURN EXIT button completely closes the program")