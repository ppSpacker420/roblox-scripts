-- Visual Clarity + No Skill Check Script
-- Features: Full Bright, No Fog, No Skill Check
-- Keybind: RightShift to toggle GUI, F6 to toggle Visual Clarity

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer

-- Store original lighting settings
local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogStart = Lighting.FogStart,
    FogColor = Lighting.FogColor
}

-- State variables
local visualClarityEnabled = false
local noSkillCheckEnabled = false
local guiMinimized = false

-- Storage for cleanup
local removedFogObjects = {}
local originalCastShadow = {}
local skillCheckConnections = {}
local visualClarityConnection = nil

-- ========== VISUAL CLARITY (FULL BRIGHT + NO FOG) ==========
local function applyFullBright()
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 1000000
    Lighting.GlobalShadows = false
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.FogStart = 0
    Lighting.FogColor = Color3.fromRGB(255, 255, 255)
end

local function removeFogObjects()
    removedFogObjects = {}
    
    -- Remove atmosphere objects
    for _, obj in pairs(Lighting:GetDescendants()) do
        if obj:IsA("Atmosphere") or obj:IsA("Clouds") then
            removedFogObjects[obj] = obj:Clone()
            obj:Destroy()
        end
    end
    
    -- Remove fog-related effects
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("Atmosphere") or effect:IsA("BloomEffect") or 
           effect:IsA("DepthOfFieldEffect") or effect:IsA("SunRaysEffect") then
            if string.find(effect.Name:lower(), "fog") or 
               string.find(effect.Name:lower(), "mist") or
               string.find(effect.Name:lower(), "haze") then
                removedFogObjects[effect] = effect:Clone()
                effect:Destroy()
            end
        end
    end
    
    -- Remove fog particles in workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") then
            local name = obj.Name:lower()
            if string.find(name, "fog") or string.find(name, "mist") or 
               string.find(name, "smoke") or string.find(name, "haze") then
                removedFogObjects[obj] = obj:Clone()
                obj:Destroy()
            end
        end
    end
end

local function restoreFogObjects()
    for obj, clone in pairs(removedFogObjects) do
        if clone and not obj.Parent then
            pcall(function()
                clone.Parent = obj.Parent or Lighting
            end)
        end
    end
    removedFogObjects = {}
end

local function restoreOriginalLighting()
    for key, value in pairs(originalLighting) do
        pcall(function()
            Lighting[key] = value
        end)
    end
end

local function disableShadows()
    originalCastShadow = {}
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("MeshPart") then
            originalCastShadow[part] = part.CastShadow
            part.CastShadow = false
        end
    end
end

local function restoreShadows()
    for part, castShadow in pairs(originalCastShadow) do
        if part and part.Parent then
            pcall(function()
                part.CastShadow = castShadow
            end)
        end
    end
    originalCastShadow = {}
end

local function enableVisualClarity()
    if visualClarityEnabled then return end
    
    print("Enabling Visual Clarity (Full Bright + No Fog)...")
    visualClarityEnabled = true
    
    applyFullBright()
    removeFogObjects()
    disableShadows()
    
    visualClarityConnection = RunService.RenderStepped:Connect(function()
        applyFullBright()
        
        -- Continuous fog removal
        for _, obj in pairs(Lighting:GetDescendants()) do
            if obj:IsA("Atmosphere") or obj:IsA("Clouds") then
                if not removedFogObjects[obj] then
                    removedFogObjects[obj] = obj:Clone()
                    obj:Destroy()
                end
            end
        end
    end)
    
    return true
end

local function disableVisualClarity()
    if not visualClarityEnabled then return end
    
    print("Disabling Visual Clarity...")
    visualClarityEnabled = false
    
    if visualClarityConnection then
        visualClarityConnection:Disconnect()
        visualClarityConnection = nil
    end
    
    restoreOriginalLighting()
    restoreFogObjects()
    restoreShadows()
    
    return true
end

-- ========== NO SKILL CHECK ==========
local skillCheckNames = {
    "SkillCheckPromptGui", "SkillCheckPromptGui-con", "SkillCheckEvent",
    "SkillCheckFailEvent", "SkillCheckResultEvent", "SkillCheckGui",
    "SkillCheck", "SkillCheckPrompt", "Skillcheck", "Skill", "Check"
}

local function isSkillCheckObject(obj)
    if not obj or not obj.Name then return false end
    local name = string.lower(obj.Name)
    
    for _, skillName in ipairs(skillCheckNames) do
        if name == string.lower(skillName) then
            return true
        end
    end
    
    if string.find(name, "skillcheck") or string.find(name, "skill check") then
        return true
    end
    
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
            if obj:IsA("ScreenGui") or obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") then
                obj.Enabled = false
                obj.Visible = false
            end
            
            if obj:IsA("RemoteEvent") then
                local oldFire = obj.FireServer
                obj.FireServer = function(...)
                    if noSkillCheckEnabled then return nil end
                    return oldFire(...)
                end
            elseif obj:IsA("RemoteFunction") then
                local oldInvoke = obj.InvokeServer
                obj.InvokeServer = function(...)
                    if noSkillCheckEnabled then return nil end
                    return oldInvoke(...)
                end
            end
            
            obj:Destroy()
            return true
        end
    end)
    return false
end

local function initialSkillCheckCleanup()
    local placesToCheck = {
        localPlayer:FindFirstChild("PlayerGui"),
        StarterGui,
        Workspace,
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

local function enableNoSkillCheck()
    if noSkillCheckEnabled then return end
    
    print("Enabling No Skill Check...")
    noSkillCheckEnabled = true
    
    initialSkillCheckCleanup()
    
    local function monitorDescendantAdded(parent)
        local conn = parent.DescendantAdded:Connect(function(obj)
            task.wait(0.1)
            removeSkillCheckObject(obj)
        end)
        table.insert(skillCheckConnections, conn)
    end
    
    local placesToMonitor = {
        localPlayer:FindFirstChild("PlayerGui") or localPlayer:WaitForChild("PlayerGui", 5),
        StarterGui,
        Workspace,
        ReplicatedStorage
    }
    
    for _, place in ipairs(placesToMonitor) do
        if place then
            monitorDescendantAdded(place)
        end
    end
    
    return true
end

local function disableNoSkillCheck()
    if not noSkillCheckEnabled then return end
    
    print("Disabling No Skill Check...")
    noSkillCheckEnabled = false
    
    for _, conn in ipairs(skillCheckConnections) do
        pcall(function() conn:Disconnect() end)
    end
    skillCheckConnections = {}
    
    return true
end

-- ========== GUI CREATION ==========
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local MiniIcon = Instance.new("TextButton")
local MiniTooltip = Instance.new("TextLabel")

ScreenGui.Parent = game:GetService("CoreGui") or localPlayer:WaitForChild("PlayerGui")
ScreenGui.Name = "VisualToolsUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame (starts hidden)
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0, 250, 0, 180)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -90)
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = false

local MainCorner = Instance.new("UICorner")
MainCorner.Parent = MainFrame
MainCorner.CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = MainFrame
MainStroke.Color = Color3.fromRGB(60, 60, 70)
MainStroke.Thickness = 2

-- Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = MainFrame
TitleLabel.Size = UDim2.new(1, 0, 0, 35)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
TitleLabel.Text = "Visual Tools"
TitleLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18

local TitleCorner = Instance.new("UICorner")
TitleCorner.Parent = TitleLabel
TitleCorner.CornerRadius = UDim.new(0, 10, 0, 0)

-- Visual Clarity Toggle
local VisualClarityToggle = Instance.new("TextButton")
VisualClarityToggle.Parent = MainFrame
VisualClarityToggle.Size = UDim2.new(0.85, 0, 0, 40)
VisualClarityToggle.Position = UDim2.new(0.075, 0, 0.22, 0)
VisualClarityToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
VisualClarityToggle.Text = "Visual Clarity: OFF\n(Full Bright + No Fog)"
VisualClarityToggle.TextColor3 = Color3.fromRGB(255, 100, 100)
VisualClarityToggle.Font = Enum.Font.Gotham
VisualClarityToggle.TextSize = 12
VisualClarityToggle.TextWrapped = true

local VCToggleCorner = Instance.new("UICorner")
VCToggleCorner.Parent = VisualClarityToggle
VCToggleCorner.CornerRadius = UDim.new(0, 6)

-- No Skill Check Toggle
local SkillCheckToggle = Instance.new("TextButton")
SkillCheckToggle.Parent = MainFrame
SkillCheckToggle.Size = UDim2.new(0.85, 0, 0, 40)
SkillCheckToggle.Position = UDim2.new(0.075, 0, 0.5, 0)
SkillCheckToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
SkillCheckToggle.Text = "No Skill Check: OFF"
SkillCheckToggle.TextColor3 = Color3.fromRGB(255, 100, 100)
SkillCheckToggle.Font = Enum.Font.Gotham
SkillCheckToggle.TextSize = 14

local SCToggleCorner = Instance.new("UICorner")
SCToggleCorner.Parent = SkillCheckToggle
SCToggleCorner.CornerRadius = UDim.new(0, 6)

-- Minimize Button
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Parent = MainFrame
MinimizeButton.Size = UDim2.new(0.85, 0, 0, 30)
MinimizeButton.Position = UDim2.new(0.075, 0, 0.78, 0)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
MinimizeButton.Text = "Minimize"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 14

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.Parent = MinimizeButton
MinimizeCorner.CornerRadius = UDim.new(0, 6)

-- Mini Icon (shown when minimized)
MiniIcon.Parent = ScreenGui
MiniIcon.Size = UDim2.new(0, 50, 0, 50)
MiniIcon.Position = UDim2.new(0, 20, 0, 20)
MiniIcon.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
MiniIcon.BorderSizePixel = 0
MiniIcon.Text = "VT"
MiniIcon.TextColor3 = Color3.fromRGB(220, 220, 255)
MiniIcon.TextSize = 16
MiniIcon.Font = Enum.Font.GothamBold
MiniIcon.Visible = true
MiniIcon.Active = true
MiniIcon.Draggable = true

local MiniCorner = Instance.new("UICorner")
MiniCorner.Parent = MiniIcon
MiniCorner.CornerRadius = UDim.new(0, 8)

local MiniStroke = Instance.new("UIStroke")
MiniStroke.Parent = MiniIcon
MiniStroke.Color = Color3.fromRGB(80, 80, 100)
MiniStroke.Thickness = 2

-- Mini Tooltip
MiniTooltip.Parent = ScreenGui
MiniTooltip.Size = UDim2.new(0, 130, 0, 40)
MiniTooltip.Position = UDim2.new(0, 75, 0, 20)
MiniTooltip.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
MiniTooltip.BorderSizePixel = 0
MiniTooltip.Text = "Visual Tools\nRightShift to open"
MiniTooltip.TextColor3 = Color3.fromRGB(200, 200, 220)
MiniTooltip.Font = Enum.Font.Gotham
MiniTooltip.TextSize = 12
MiniTooltip.TextYAlignment = Enum.TextYAlignment.Top
MiniTooltip.Visible = false

local TooltipCorner = Instance.new("UICorner")
TooltipCorner.Parent = MiniTooltip
TooltipCorner.CornerRadius = UDim.new(0, 6)

local TooltipStroke = Instance.new("UIStroke")
TooltipStroke.Parent = MiniTooltip
TooltipStroke.Color = Color3.fromRGB(80, 80, 100)
TooltipStroke.Thickness = 1

-- ========== GUI FUNCTIONALITY ==========
-- Button hover effects
local function setupButtonHover(button, enabledColor, disabledColor)
    button.MouseEnter:Connect(function()
        if button.BackgroundColor3 == enabledColor then
            button.BackgroundColor3 = Color3.fromRGB(
                math.floor(enabledColor.R * 255 * 0.8),
                math.floor(enabledColor.G * 255 * 0.8),
                math.floor(enabledColor.B * 255 * 0.8)
            ) / 255
        else
            button.BackgroundColor3 = Color3.fromRGB(
                math.floor(disabledColor.R * 255 * 1.2),
                math.floor(disabledColor.G * 255 * 1.2),
                math.floor(disabledColor.B * 255 * 1.2)
            ) / 255
        end
    end)
    
    button.MouseLeave:Connect(function()
        if button.BackgroundColor3 == Color3.fromRGB(60, 180, 60) or 
           button.BackgroundColor3 == Color3.fromRGB(48, 144, 48) then
            button.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
        else
            button.BackgroundColor3 = disabledColor
        end
    end)
end

-- Visual Clarity toggle
VisualClarityToggle.MouseButton1Click:Connect(function()
    if visualClarityEnabled then
        disableVisualClarity()
        VisualClarityToggle.Text = "Visual Clarity: OFF\n(Full Bright + No Fog)"
        VisualClarityToggle.TextColor3 = Color3.fromRGB(255, 100, 100)
        VisualClarityToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    else
        enableVisualClarity()
        VisualClarityToggle.Text = "Visual Clarity: ON\n(Full Bright + No Fog)"
        VisualClarityToggle.TextColor3 = Color3.fromRGB(100, 255, 100)
        VisualClarityToggle.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
    end
end)

-- No Skill Check toggle
SkillCheckToggle.MouseButton1Click:Connect(function()
    if noSkillCheckEnabled then
        disableNoSkillCheck()
        SkillCheckToggle.Text = "No Skill Check: OFF"
        SkillCheckToggle.TextColor3 = Color3.fromRGB(255, 100, 100)
        SkillCheckToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    else
        enableNoSkillCheck()
        SkillCheckToggle.Text = "No Skill Check: ON"
        SkillCheckToggle.TextColor3 = Color3.fromRGB(100, 255, 100)
        SkillCheckToggle.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
    end
end)

-- Minimize button
MinimizeButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MiniIcon.Visible = true
    guiMinimized = true
end)

-- Mini Icon functionality
MiniIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MiniIcon.Visible = false
    MiniTooltip.Visible = false
    guiMinimized = false
end)

MiniIcon.MouseEnter:Connect(function()
    MiniTooltip.Visible = true
end)

MiniIcon.MouseLeave:Connect(function()
    MiniTooltip.Visible = false
end)

-- Setup hover effects
setupButtonHover(VisualClarityToggle, Color3.fromRGB(60, 180, 60), Color3.fromRGB(60, 60, 70))
setupButtonHover(SkillCheckToggle, Color3.fromRGB(60, 180, 60), Color3.fromRGB(60, 60, 70))

-- ========== KEYBINDS ==========
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- RightShift: Toggle GUI visibility
    if input.KeyCode == Enum.KeyCode.RightShift then
        if guiMinimized or not MainFrame.Visible then
            MainFrame.Visible = true
            MiniIcon.Visible = false
            MiniTooltip.Visible = false
            guiMinimized = false
        else
            MainFrame.Visible = false
            MiniIcon.Visible = true
            guiMinimized = true
        end
    
    -- F6: Toggle Visual Clarity
    elseif input.KeyCode == Enum.KeyCode.F6 then
        if visualClarityEnabled then
            disableVisualClarity()
            VisualClarityToggle.Text = "Visual Clarity: OFF\n(Full Bright + No Fog)"
            VisualClarityToggle.TextColor3 = Color3.fromRGB(255, 100, 100)
            VisualClarityToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        else
            enableVisualClarity()
            VisualClarityToggle.Text = "Visual Clarity: ON\n(Full Bright + No Fog)"
            VisualClarityToggle.TextColor3 = Color3.fromRGB(100, 255, 100)
            VisualClarityToggle.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
        end
    
    -- F7: Toggle No Skill Check
    elseif input.KeyCode == Enum.KeyCode.F7 then
        if noSkillCheckEnabled then
            disableNoSkillCheck()
            SkillCheckToggle.Text = "No Skill Check: OFF"
            SkillCheckToggle.TextColor3 = Color3.fromRGB(255, 100, 100)
            SkillCheckToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        else
            enableNoSkillCheck()
            SkillCheckToggle.Text = "No Skill Check: ON"
            SkillCheckToggle.TextColor3 = Color3.fromRGB(100, 255, 100)
            SkillCheckToggle.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
        end
    end
end)

-- ========== CLEANUP ==========
local function cleanup()
    disableVisualClarity()
    disableNoSkillCheck()
    if ScreenGui then
        ScreenGui:Destroy()
    end
    print("Visual Tools script cleaned up")
end

game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == localPlayer then
        cleanup()
    end
end)

-- Initial state update
VisualClarityToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
SkillCheckToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)

print("=======================================")
print("Visual Tools Script Loaded!")
print("Features:")
print("1. Visual Clarity (Full Bright + No Fog)")
print("2. No Skill Check")
print("Keybinds:")
print("- RightShift: Toggle GUI")
print("- F6: Toggle Visual Clarity")
print("- F7: Toggle No Skill Check")
print("=======================================")