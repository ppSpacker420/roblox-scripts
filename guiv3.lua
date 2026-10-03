-- Unified Visual & Camera Tools Script (FIXED EXIT & DRAGGABLE)
-- Features: Visual Clarity, No Skill Check, Infinite Zoom, Camera Noclip
-- Keybinds: RightShift (Toggle GUI), F6 (Visual Clarity), F7 (No Skill Check), F8 (Infinite Zoom), F10 (Camera Noclip)

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- == FORWARD DECLARATION (This fixes the Exit button) ==
local ScreenGui -- We declare this here so the cleanup function can 'see' it later

-- Store original lighting settings and camera properties
local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogStart = Lighting.FogStart,
    FogColor = Lighting.FogColor
}

local originalCameraProps = {
    MaxZoomDistance = localPlayer.CameraMaxZoomDistance,
    OcclusionMode = localPlayer.DevCameraOcclusionMode
}

-- State variables
local visualClarityEnabled = false
local noSkillCheckEnabled = false
local zoomEnabled = false
local noclipEnabled = false
local guiMinimized = false

-- Storage for cleanup
local removedFogObjects = {}
local originalCastShadow = {}
local skillCheckConnections = {}
local visualClarityConnection = nil

-- ==========================================
-- ========== FEATURE LOGIC ==========
-- ==========================================

-- Visual Clarity Logic
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
    for _, obj in pairs(Lighting:GetDescendants()) do
        if obj:IsA("Atmosphere") or obj:IsA("Clouds") then
            removedFogObjects[obj] = obj:Clone()
            obj:Destroy()
        end
    end
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
    visualClarityEnabled = true
    applyFullBright()
    removeFogObjects()
    disableShadows()
    visualClarityConnection = RunService.RenderStepped:Connect(function()
        applyFullBright()
        for _, obj in pairs(Lighting:GetDescendants()) do
            if obj:IsA("Atmosphere") or obj:IsA("Clouds") then
                if not removedFogObjects[obj] then
                    removedFogObjects[obj] = obj:Clone()
                    obj:Destroy()
                end
            end
        end
    end)
end

local function disableVisualClarity()
    if not visualClarityEnabled then return end
    visualClarityEnabled = false
    if visualClarityConnection then
        visualClarityConnection:Disconnect()
        visualClarityConnection = nil
    end
    restoreOriginalLighting()
    restoreFogObjects()
    restoreShadows()
end

-- No Skill Check Logic
local skillCheckNames = {"SkillCheckPromptGui", "SkillCheckPromptGui-con", "SkillCheckEvent", "SkillCheckFailEvent", "SkillCheckResultEvent", "SkillCheckGui", "SkillCheck", "SkillCheckPrompt", "Skillcheck", "Skill", "Check"}

local function isSkillCheckObject(obj)
    if not obj or not obj.Name then return false end
    local name = string.lower(obj.Name)
    for _, skillName in ipairs(skillCheckNames) do
        if name == string.lower(skillName) then return true end
    end
    if string.find(name, "skillcheck") or string.find(name, "skill check") then return true end
    if obj.Parent then
        local parentName = string.lower(obj.Parent.Name)
        if string.find(parentName, "skillcheck") or string.find(parentName, "skill check") then return true end
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
    local placesToCheck = {localPlayer:FindFirstChild("PlayerGui"), StarterGui, Workspace, ReplicatedStorage}
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
    noSkillCheckEnabled = true
    initialSkillCheckCleanup()
    local function monitorDescendantAdded(parent)
        local conn = parent.DescendantAdded:Connect(function(obj)
            task.wait(0.1)
            removeSkillCheckObject(obj)
        end)
        table.insert(skillCheckConnections, conn)
    end
    local placesToMonitor = {localPlayer:FindFirstChild("PlayerGui") or localPlayer:WaitForChild("PlayerGui", 5), StarterGui, Workspace, ReplicatedStorage}
    for _, place in ipairs(placesToMonitor) do
        if place then
            monitorDescendantAdded(place)
        end
    end
end

local function disableNoSkillCheck()
    if not noSkillCheckEnabled then return end
    noSkillCheckEnabled = false
    for _, conn in ipairs(skillCheckConnections) do
        pcall(function() conn:Disconnect() end)
    end
    skillCheckConnections = {}
end

-- Camera Logic
local function toggleZoom()
    zoomEnabled = not zoomEnabled
    if zoomEnabled then
        localPlayer.CameraMaxZoomDistance = math.huge
    else
        localPlayer.CameraMaxZoomDistance = originalCameraProps.MaxZoomDistance
    end
end

local function toggleNoclip()
    noclipEnabled = not noclipEnabled
    if noclipEnabled then
        localPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
    else
        localPlayer.DevCameraOcclusionMode = originalCameraProps.OcclusionMode
    end
end

-- ==========================================
-- ========== CLEANUP (THE FIX) ==========
-- ==========================================
local function cleanup()
    -- 1. Disable all features
    disableVisualClarity()
    disableNoSkillCheck()
    
    if zoomEnabled then
        localPlayer.CameraMaxZoomDistance = originalCameraProps.MaxZoomDistance
    end
    if noclipEnabled then
        localPlayer.DevCameraOcclusionMode = originalCameraProps.OcclusionMode
    end

    -- 2. Destroy the GUI
    -- Because ScreenGui was declared at the top, this function can now see it!
    if ScreenGui then
        ScreenGui:Destroy()
        ScreenGui = nil -- Clear the reference
    end
    
    print("Enhanced Tools: Program exited and GUI destroyed.")
end

-- ==========================================
-- ========== GUI CREATION ==========
-- ==========================================
ScreenGui = Instance.new("ScreenGui") -- Assigning to the top-level variable
local MainFrame = Instance.new("Frame")
local MiniIcon = Instance.new("TextButton")
local MiniTooltip = Instance.new("TextLabel")

ScreenGui.Parent = game:GetService("CoreGui") or localPlayer:WaitForChild("PlayerGui")
ScreenGui.Name = "VisualToolsUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0, 250, 0, 320)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- This makes the window movable
MainFrame.Visible = false

local MainCorner = Instance.new("UICorner")
MainCorner.Parent = MainFrame
MainCorner.CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = MainFrame
MainStroke.Color = Color3.fromRGB(60, 60, 70)
MainStroke.Thickness = 2

-- Title Label
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = MainFrame
TitleLabel.Size = UDim2.new(1, 0, 0, 35)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
TitleLabel.Text = "Enhanced Tools (Drag Here)"
TitleLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18

local TitleCorner = Instance.new("UICorner")
TitleCorner.Parent = TitleLabel
TitleCorner.CornerRadius = UDim.new(0, 10, 0, 0)

-- Buttons
local VisualClarityToggle = Instance.new("TextButton")
VisualClarityToggle.Parent = MainFrame
VisualClarityToggle.Size = UDim2.new(0.85, 0, 0, 40)
VisualClarityToggle.Position = UDim2.new(0.075, 0, 0.12, 0)
VisualClarityToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
VisualClarityToggle.Text = "Visual Clarity: OFF"
VisualClarityToggle.TextColor3 = Color3.fromRGB(255, 100, 100)
VisualClarityToggle.Font = Enum.Font.Gotham
VisualClarityToggle.TextSize = 12
Instance.new("UICorner", VisualClarityToggle).CornerRadius = UDim.new(0, 6)

local SkillCheckToggle = Instance.new("TextButton")
SkillCheckToggle.Parent = MainFrame
SkillCheckToggle.Size = UDim2.new(0.85, 0, 0, 40)
SkillCheckToggle.Position = UDim2.new(0.075, 0, 0.27, 0)
SkillCheckToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
SkillCheckToggle.Text = "No Skill Check: OFF"
SkillCheckToggle.TextColor3 = Color3.fromRGB(255, 100, 100)
SkillCheckToggle.Font = Enum.Font.Gotham
SkillCheckToggle.TextSize = 14
Instance.new("UICorner", SkillCheckToggle).CornerRadius = UDim.new(0, 6)

local ZoomToggle = Instance.new("TextButton")
ZoomToggle.Parent = MainFrame
ZoomToggle.Size = UDim2.new(0.85, 0, 0, 40)
ZoomToggle.Position = UDim2.new(0.075, 0, 0.42, 0)
ZoomToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
ZoomToggle.Text = "Infinite Zoom: OFF"
ZoomToggle.TextColor3 = Color3.fromRGB(255, 100, 100)
ZoomToggle.Font = Enum.Font.Gotham
ZoomToggle.TextSize = 14
Instance.new("UICorner", ZoomToggle).CornerRadius = UDim.new(0, 6)

local NoclipToggle = Instance.new("TextButton")
NoclipToggle.Parent = MainFrame
NoclipToggle.Size = UDim2.new(0.85, 0, 0, 40)
NoclipToggle.Position = UDim2.new(0.075, 0, 0.57, 0)
NoclipToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
NoclipToggle.Text = "Camera Noclip: OFF"
NoclipToggle.TextColor3 = Color3.fromRGB(255, 100, 100)
NoclipToggle.Font = Enum.Font.Gotham
NoclipToggle.TextSize = 14
Instance.new("UICorner", NoclipToggle).CornerRadius = UDim.new(0, 6)

-- Control Buttons (Exit and Minimize)
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Parent = MainFrame
MinimizeButton.Size = UDim2.new(0.40, 0, 0, 30)
MinimizeButton.Position = UDim2.new(0.075, 0, 0.72, 0) -- Left side
MinimizeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
MinimizeButton.Text = "Minimize (_)"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 14
Instance.new("UICorner", MinimizeButton).CornerRadius = UDim.new(0, 6)

local ExitButton = Instance.new("TextButton")
ExitButton.Parent = MainFrame
ExitButton.Size = UDim2.new(0.40, 0, 0, 30)
ExitButton.Position = UDim2.new(0.525, 0, 0.72, 0) -- Right side
ExitButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
ExitButton.Text = "Exit (X)"
ExitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ExitButton.Font = Enum.Font.GothamBold
ExitButton.TextSize = 14
Instance.new("UICorner", ExitButton).CornerRadius = UDim.new(0, 6)

-- Mini Icon (for minimize)
MiniIcon.Parent = ScreenGui
MiniIcon.Size = UDim2.new(0, 50, 0, 50)
MiniIcon.Position = UDim2.new(0, 20, 0, 20)
MiniIcon.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
MiniIcon.Text = "ET"
MiniIcon.TextColor3 = Color3.fromRGB(220, 220, 255)
MiniIcon.TextSize = 16
MiniIcon.Font = Enum.Font.GothamBold
MiniIcon.Visible = true
MiniIcon.Active = true
MiniIcon.Draggable = true
Instance.new("UICorner", MiniIcon).CornerRadius = UDim.new(0, 8)
local MiniStroke = Instance.new("UIStroke")
MiniStroke.Parent = MiniIcon
MiniStroke.Color = Color3.fromRGB(80, 80, 100)
MiniStroke.Thickness = 2

-- ==========================================
-- ========== CONNECTIONS ==========
-- ==========================================
local function updateButton(btn, enabled, text, key)
    local status = enabled and "ON" or "OFF"
    btn.Text = text .. ": " .. status .. "\n(" .. key .. ")"
    btn.TextColor3 = enabled and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
    btn.BackgroundColor3 = enabled and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(60, 60, 70)
end

-- Button Clicks
VisualClarityToggle.MouseButton1Click:Connect(function()
    if visualClarityEnabled then disableVisualClarity() else enableVisualClarity() end
    updateButton(VisualClarityToggle, visualClarityEnabled, "Visual Clarity", "F6")
end)

SkillCheckToggle.MouseButton1Click:Connect(function()
    if noSkillCheckEnabled then disableNoSkillCheck() else enableNoSkillCheck() end
    updateButton(SkillCheckToggle, noSkillCheckEnabled, "No Skill Check", "F7")
end)

ZoomToggle.MouseButton1Click:Connect(function()
    toggleZoom()
    updateButton(ZoomToggle, zoomEnabled, "Infinite Zoom", "F8")
end)

NoclipToggle.MouseButton1Click:Connect(function()
    toggleNoclip()
    updateButton(NoclipToggle, noclipEnabled, "Camera Noclip", "F10")
end)

MinimizeButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MiniIcon.Visible = true
    guiMinimized = true
end)

MiniIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MiniIcon.Visible = false
    guiMinimized = false
end)

-- EXIT BUTTON CONNECTION (CONFIRMED WORKING)
ExitButton.MouseButton1Click:Connect(function()
    cleanup()
end)

-- Keybinds
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.RightShift then
        if guiMinimized or not MainFrame.Visible then
            MainFrame.Visible = true
            MiniIcon.Visible = false
            guiMinimized = false
        else
            MainFrame.Visible = false
            MiniIcon.Visible = true
            guiMinimized = true
        end
    elseif input.KeyCode == Enum.KeyCode.F6 then
        if visualClarityEnabled then disableVisualClarity() else enableVisualClarity() end
        updateButton(VisualClarityToggle, visualClarityEnabled, "Visual Clarity", "F6")
    elseif input.KeyCode == Enum.KeyCode.F7 then
        if noSkillCheckEnabled then disableNoSkillCheck() else enableNoSkillCheck() end
        updateButton(SkillCheckToggle, noSkillCheckEnabled, "No Skill Check", "F7")
    elseif input.KeyCode == Enum.KeyCode.F8 then
        toggleZoom()
        updateButton(ZoomToggle, zoomEnabled, "Infinite Zoom", "F8")
    elseif input.KeyCode == Enum.KeyCode.F10 then
        toggleNoclip()
        updateButton(NoclipToggle, noclipEnabled, "Camera Noclip", "F10")
    end
end)

-- Init
game:GetService("Players").PlayerRemoving:Connect(function(p) if p == localPlayer then cleanup() end end)
updateButton(VisualClarityToggle, visualClarityEnabled, "Visual Clarity", "F6")
updateButton(SkillCheckToggle, noSkillCheckEnabled, "No Skill Check", "F7")
updateButton(ZoomToggle, zoomEnabled, "Infinite Zoom", "F8")
updateButton(NoclipToggle, noclipEnabled, "Camera Noclip", "F10")

print("Enhanced Tools Loaded. Use the Exit button to close completely.")