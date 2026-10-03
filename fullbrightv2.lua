-- Fullbright, No Fog, and No Shadows Script for Roblox
-- Keybind: RightShift to open/close (minimize) GUI

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer

-- Store original lighting settings
local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ExposureCompensation = Lighting.ExposureCompensation
}

-- Variables to track states
local fullbrightEnabled = false
local noFogEnabled = false
local noShadowsEnabled = false

-- Connections for cleanup
local fullbrightLoop
local noFogConnections = {}
local noShadowsConnections = {}
local keybindConnection

-- ========== FULLBRIGHT FUNCTION ==========
local function toggleFullbright(state)
    fullbrightEnabled = state
    
    if state then
        -- Start fullbright loop
        fullbrightLoop = task.spawn(function()
            while fullbrightEnabled do
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogStart = 0
                Lighting.FogEnd = 1000000000
                Lighting.GlobalShadows = false
                Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
                Lighting.ExposureCompensation = 0
                task.wait(0.5)
            end
        end)
    else
        -- Stop loop and restore original settings
        if fullbrightLoop then
            task.cancel(fullbrightLoop)
            fullbrightLoop = nil
        end
        
        -- Restore original lighting values
        for key, value in pairs(originalLighting) do
            pcall(function()
                Lighting[key] = value
            end)
        end
    end
end

-- ========== NO FOG FUNCTION ==========
local function containsFogInName(obj)
    if not obj or not obj.Name then return false end
    return string.find(string.lower(obj.Name), "fog") ~= nil
end

local function removeFogObject(obj)
    pcall(function()
        -- Check if object is fog-related
        if containsFogInName(obj) then
            obj:Destroy()
            return true
        end
        
        -- Check for other fog/atmospheric effects
        if obj:IsA("Atmosphere") or obj:IsA("Clouds") then
            obj:Destroy()
            return true
        end
        
        -- Check for particle emitters that might be fog
        if obj:IsA("ParticleEmitter") then
            local name = string.lower(obj.Name)
            if string.find(name, "fog") or string.find(name, "mist") or string.find(name, "smoke") then
                obj:Destroy()
                return true
            end
        end
        
        -- Check for post-processing effects that might cause fog
        if obj:IsA("BloomEffect") or obj:IsA("SunRaysEffect") or obj:IsA("DepthOfFieldEffect") then
            obj:Destroy()
            return true
        end
    end)
    return false
end

local function initialFogCleanup()
    -- Clean fog from all services
    local services = {Workspace, Lighting}
    
    for _, service in ipairs(services) do
        for _, obj in ipairs(service:GetDescendants()) do
            removeFogObject(obj)
        end
    end
end

local function toggleNoFog(state)
    noFogEnabled = state
    
    -- Clear existing connections
    for _, conn in ipairs(noFogConnections) do
        pcall(function() conn:Disconnect() end)
    end
    noFogConnections = {}
    
    if state then
        -- Initial cleanup
        initialFogCleanup()
        
        -- Also remove fog from Lighting properties
        Lighting.FogStart = 0
        Lighting.FogEnd = 1000000000
        
        -- Monitor for new fog objects
        local function monitorDescendantAdded(parent)
            local conn = parent.DescendantAdded:Connect(function(obj)
                task.wait(0.1) -- Small delay to ensure object is fully loaded
                removeFogObject(obj)
            end)
            table.insert(noFogConnections, conn)
        end
        
        -- Monitor all relevant services
        monitorDescendantAdded(Workspace)
        monitorDescendantAdded(Lighting)
        
        print("No Fog enabled - fog objects will be automatically removed")
    else
        -- Restore original fog settings if they were saved
        if originalLighting.FogStart then
            Lighting.FogStart = originalLighting.FogStart
        end
        if originalLighting.FogEnd then
            Lighting.FogEnd = originalLighting.FogEnd
        end
        print("No Fog disabled")
    end
end

-- ========== NO SHADOWS FUNCTION ==========
local function toggleNoShadows(state)
    noShadowsEnabled = state
    
    -- Clear existing connections
    for _, conn in ipairs(noShadowsConnections) do
        pcall(function() conn:Disconnect() end)
    end
    noShadowsConnections = {}
    
    if state then
        -- Disable global shadows
        Lighting.GlobalShadows = false
        
        -- Store original CastShadow values
        local originalCastShadow = {}
        
        -- Disable shadows on all existing parts
        for _, part in ipairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                originalCastShadow[part] = part.CastShadow
                part.CastShadow = false
            elseif part:IsA("MeshPart") then
                originalCastShadow[part] = part.CastShadow
                part.CastShadow = false
            end
        end
        
        -- Monitor for new parts and disable their shadows
        local conn = Workspace.DescendantAdded:Connect(function(obj)
            task.wait(0.05)
            if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                originalCastShadow[obj] = obj.CastShadow
                obj.CastShadow = false
            end
        end)
        table.insert(noShadowsConnections, conn)
        
        print("No Shadows enabled - all shadows disabled")
    else
        -- Re-enable global shadows
        Lighting.GlobalShadows = originalLighting.GlobalShadows or true
        
        print("No Shadows disabled - shadows restored")
    end
end

-- ========== GUI CREATION ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VisualSettingsGUI"
ScreenGui.Parent = LP:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 250, 0, 300)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -150)
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
Title.Text = "Visual Settings"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Fullbright Toggle
local FullbrightToggle = Instance.new("TextButton")
FullbrightToggle.Name = "FullbrightToggle"
FullbrightToggle.Size = UDim2.new(0.8, 0, 0, 40)
FullbrightToggle.Position = UDim2.new(0.1, 0, 0.15, 0)
FullbrightToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
FullbrightToggle.Text = "Fullbright: OFF"
FullbrightToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
FullbrightToggle.TextSize = 16
FullbrightToggle.Font = Enum.Font.Gotham
FullbrightToggle.Parent = MainFrame

-- No Fog Toggle
local NoFogToggle = Instance.new("TextButton")
NoFogToggle.Name = "NoFogToggle"
NoFogToggle.Size = UDim2.new(0.8, 0, 0, 40)
NoFogToggle.Position = UDim2.new(0.1, 0, 0.35, 0)
NoFogToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
NoFogToggle.Text = "No Fog: OFF"
NoFogToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
NoFogToggle.TextSize = 16
NoFogToggle.Font = Enum.Font.Gotham
NoFogToggle.Parent = MainFrame

-- No Shadows Toggle
local NoShadowsToggle = Instance.new("TextButton")
NoShadowsToggle.Name = "NoShadowsToggle"
NoShadowsToggle.Size = UDim2.new(0.8, 0, 0, 40)
NoShadowsToggle.Position = UDim2.new(0.1, 0, 0.55, 0)
NoShadowsToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
NoShadowsToggle.Text = "No Shadows: OFF"
NoShadowsToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
NoShadowsToggle.TextSize = 16
NoShadowsToggle.Font = Enum.Font.Gotham
NoShadowsToggle.Parent = MainFrame

-- Close/Minimize Button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0.8, 0, 0, 40)
CloseButton.Position = UDim2.new(0.1, 0, 0.75, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
CloseButton.Text = "Minimize GUI"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 16
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = MainFrame

-- Mini Icon (visible when GUI is minimized)
local MiniIcon = Instance.new("TextButton")
MiniIcon.Name = "MiniIcon"
MiniIcon.Size = UDim2.new(0, 50, 0, 50)
MiniIcon.Position = UDim2.new(0, 20, 0, 20)
MiniIcon.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MiniIcon.BorderSizePixel = 2
MiniIcon.BorderColor3 = Color3.fromRGB(60, 60, 60)
MiniIcon.Text = "VS"
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
MiniTooltip.Text = "Visual Settings\nRightShift to open"
MiniTooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniTooltip.TextSize = 12
MiniTooltip.Font = Enum.Font.Gotham
MiniTooltip.TextYAlignment = Enum.TextYAlignment.Top
MiniTooltip.Visible = false
MiniTooltip.Parent = ScreenGui

-- Toggle button functions
FullbrightToggle.MouseButton1Click:Connect(function()
    fullbrightEnabled = not fullbrightEnabled
    toggleFullbright(fullbrightEnabled)
    FullbrightToggle.Text = "Fullbright: " .. (fullbrightEnabled and "ON" or "OFF")
    FullbrightToggle.BackgroundColor3 = fullbrightEnabled and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(60, 60, 60)
    print("Fullbright:", fullbrightEnabled and "Enabled" or "Disabled")
end)

NoFogToggle.MouseButton1Click:Connect(function()
    noFogEnabled = not noFogEnabled
    toggleNoFog(noFogEnabled)
    NoFogToggle.Text = "No Fog: " .. (noFogEnabled and "ON" or "OFF")
    NoFogToggle.BackgroundColor3 = noFogEnabled and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(60, 60, 60)
    print("No Fog:", noFogEnabled and "Enabled" or "Disabled")
end)

NoShadowsToggle.MouseButton1Click:Connect(function()
    noShadowsEnabled = not noShadowsEnabled
    toggleNoShadows(noShadowsEnabled)
    NoShadowsToggle.Text = "No Shadows: " .. (noShadowsEnabled and "ON" or "OFF")
    NoShadowsToggle.BackgroundColor3 = noShadowsEnabled and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(60, 60, 60)
    print("No Shadows:", noShadowsEnabled and "Enabled" or "Disabled")
end)

CloseButton.MouseButton1Click:Connect(function()
    -- Minimize the GUI instead of closing
    MainFrame.Visible = false
    MiniIcon.Visible = true
    print("GUI minimized - use RightShift to reopen")
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
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode.RightShift then
            toggleGUI()
        end
    end
end)

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

-- Cleanup function
local function cleanup()
    -- Disable all features
    if fullbrightEnabled then toggleFullbright(false) end
    if noFogEnabled then toggleNoFog(false) end
    if noShadowsEnabled then toggleNoShadows(false) end
    
    -- Disconnect connections
    if keybindConnection then
        keybindConnection:Disconnect()
    end
    
    -- Remove GUI
    ScreenGui:Destroy()
    
    print("Script cleaned up - all features disabled")
end

-- Connect to cleanup when player leaves
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LP then
        cleanup()
    end
end)

print("=====================================")
print("Visual Settings Script Loaded!")
print("Keybind: RightShift to open/close GUI")
print("Features:")
print("1. Fullbright - Makes the game brighter")
print("2. No Fog - Removes all fog effects")
print("3. No Shadows - Disables all shadows")
print("=====================================")
print("GUI starts minimized - click the 'VS' icon or press RightShift")