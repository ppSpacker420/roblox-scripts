--[[
    Enhanced Control Suite v2.1
    Speed control, Anti-AFK, visual/camera tools, ESP loader (Rayfield UI)
]]

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ==========================================
-- Services & core state
-- ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer

local Config = {
    DefaultWalkSpeed = 16,
    MaxWalkSpeed = 100,
    CameraReapplyInterval = 5, -- seconds
    AFKThreshold = 300,        -- seconds (display only)
    ESPUrl = "https://obj.wearedevs.net/2/scripts/WRD%20ESP.lua",
}

-- Single source of truth. Lives in the script, so it survives death automatically.
local State = {
    WalkSpeed = Config.DefaultWalkSpeed,
    SpeedLock = false,
    AntiAFK = false,
    VisualClarity = false,
    NoSkillCheck = false,
    InfiniteZoom = false,
    CameraNoclip = false,
    ESPLoaded = false,
}

local UI = {}                -- Rayfield element references
local Connections = {}       -- everything we need to disconnect on destroy
local Running = true
local Loading = true         -- suppresses notifications while a saved config loads
local Silent = false         -- true while WE update a UI element (blocks callback echo)
local LastInputTime = tick()
local Humanoid

local function track(conn)
    table.insert(Connections, conn)
    return conn
end

local function notify(title, content)
    if Loading or not Running then return end
    Rayfield:Notify({ Title = title, Content = content, Duration = 2, Image = 4483362458 })
end

-- Update a Rayfield element without triggering its own callback logic.
local function setElement(element, value)
    if not element then return end
    Silent = true
    pcall(function() element:Set(value) end)
    Silent = false
end

-- Wrap a callback so it ignores programmatic :Set() calls.
local function guarded(fn)
    return function(...)
        if Silent then return end
        return fn(...)
    end
end

-- ==========================================
-- Character & speed
-- ==========================================

local function applySpeed()
    if not Humanoid then return end
    Humanoid.WalkSpeed = State.SpeedLock and State.WalkSpeed or Config.DefaultWalkSpeed
end

local function onCharacter(char)
    Humanoid = char:WaitForChild("Humanoid", 10)
    applySpeed()
end

if Player.Character then task.spawn(onCharacter, Player.Character) end
track(Player.CharacterAdded:Connect(onCharacter))

local function updateSpeedLabels()
    if UI.SpeedLabel then UI.SpeedLabel:Set("Current Speed: " .. State.WalkSpeed) end
    if UI.SpeedLockLabel then UI.SpeedLockLabel:Set("Speed Lock: " .. (State.SpeedLock and "ON" or "OFF")) end
end

local function setWalkSpeed(speed)
    State.WalkSpeed = math.clamp(math.floor(speed), 1, Config.MaxWalkSpeed)
    applySpeed()
    updateSpeedLabels()
end

local function setSpeedLock(enabled)
    State.SpeedLock = enabled
    applySpeed()
    updateSpeedLabels()
    notify("Speed Lock", enabled and ("ON - Speed: " .. State.WalkSpeed) or "OFF")
end

local function setMultiplier(multiplier)
    setWalkSpeed(Config.DefaultWalkSpeed * multiplier)
    setElement(UI.SpeedSlider, State.WalkSpeed)
end

local function resetSpeed()
    State.WalkSpeed = Config.DefaultWalkSpeed
    State.SpeedLock = false
    applySpeed()
    setElement(UI.SpeedSlider, State.WalkSpeed)
    setElement(UI.MultiplierSlider, 1.0)
    setElement(UI.SpeedLockToggle, false)
    updateSpeedLabels()
    notify("Speed Reset", "Reset to default: " .. Config.DefaultWalkSpeed)
end

-- Re-enforce the lock if the game overwrites WalkSpeed
track(RunService.Heartbeat:Connect(function()
    if State.SpeedLock and Humanoid and Humanoid.WalkSpeed ~= State.WalkSpeed then
        Humanoid.WalkSpeed = State.WalkSpeed
    end
end))

-- ==========================================
-- Anti-AFK (uses the Idled event instead of polling)
-- ==========================================

local VirtualUser
pcall(function() VirtualUser = game:GetService("VirtualUser") end)

track(Player.Idled:Connect(function()
    if not State.AntiAFK or not VirtualUser then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end))

track(UserInputService.InputBegan:Connect(function()
    LastInputTime = tick()
end))

local function setAntiAFK(enabled)
    State.AntiAFK = enabled
    notify("Anti-AFK", enabled and "ON" or "OFF")
end

-- ==========================================
-- Visual Clarity (non-destructive, no per-frame scans)
-- ==========================================

local ClarityProps = {
    Brightness = 2,
    ClockTime = 14,
    FogEnd = 1e6,
    FogStart = 0,
    GlobalShadows = false,
    OutdoorAmbient = Color3.fromRGB(128, 128, 128),
    FogColor = Color3.fromRGB(255, 255, 255),
}

local Clarity = { Saved = {}, Hidden = {}, Particles = {}, Connections = {} }
local FogKeywords = { "fog", "mist", "smoke", "haze" }

local function hasFogKeyword(name)
    name = name:lower()
    for _, word in ipairs(FogKeywords) do
        if name:find(word, 1, true) then return true end
    end
    return false
end

local function hideInstance(inst)
    pcall(function()
        if not inst.Parent then return end
        if inst:IsA("Atmosphere") or inst:IsA("Clouds") then
            Clarity.Hidden[inst] = inst.Parent
            inst.Parent = nil
        elseif inst:IsA("ParticleEmitter") and hasFogKeyword(inst.Name) then
            Clarity.Particles[inst] = inst.Enabled
            inst.Enabled = false
        end
    end)
end

local function applyClarityLighting()
    for prop, value in pairs(ClarityProps) do
        if Lighting[prop] ~= value then Lighting[prop] = value end
    end
end

local function setVisualClarity(enabled)
    if enabled == State.VisualClarity then return end
    State.VisualClarity = enabled

    if enabled then
        for prop in pairs(ClarityProps) do Clarity.Saved[prop] = Lighting[prop] end
        applyClarityLighting()

        for _, inst in ipairs(Lighting:GetDescendants()) do hideInstance(inst) end
        for _, inst in ipairs(Workspace.Terrain:GetChildren()) do hideInstance(inst) end
        for _, inst in ipairs(Workspace:GetDescendants()) do
            if inst:IsA("ParticleEmitter") then hideInstance(inst) end
        end

        table.insert(Clarity.Connections, RunService.RenderStepped:Connect(applyClarityLighting))
        table.insert(Clarity.Connections, Lighting.DescendantAdded:Connect(function(inst)
            task.defer(hideInstance, inst)
        end))
    else
        for _, conn in ipairs(Clarity.Connections) do conn:Disconnect() end
        Clarity.Connections = {}

        for prop, value in pairs(Clarity.Saved) do
            pcall(function() Lighting[prop] = value end)
        end
        for inst, parent in pairs(Clarity.Hidden) do
            pcall(function() inst.Parent = parent end)
        end
        for inst, wasEnabled in pairs(Clarity.Particles) do
            pcall(function() inst.Enabled = wasEnabled end)
        end
        Clarity.Hidden, Clarity.Particles, Clarity.Saved = {}, {}, {}
    end

    notify("Visual Clarity", enabled and "ON" or "OFF")
end

-- ==========================================
-- No Skill Check (narrow match, disables GUIs instead of destroying them)
-- ==========================================

local SkillCheck = { Hidden = {}, Connections = {} }

local function isSkillCheckGui(obj)
    if not obj:IsA("ScreenGui") then return false end
    local name = obj.Name:lower()
    return name:find("skillcheck", 1, true) ~= nil or name:find("skill check", 1, true) ~= nil
end

local function suppressGui(gui)
    if not isSkillCheckGui(gui) then return end
    if SkillCheck.Hidden[gui] == nil then
        SkillCheck.Hidden[gui] = gui.Enabled
        table.insert(SkillCheck.Connections, gui:GetPropertyChangedSignal("Enabled"):Connect(function()
            if State.NoSkillCheck and gui.Enabled then gui.Enabled = false end
        end))
    end
    gui.Enabled = false
end

local function setNoSkillCheck(enabled)
    if enabled == State.NoSkillCheck then return end
    State.NoSkillCheck = enabled

    if enabled then
        local playerGui = Player:FindFirstChildOfClass("PlayerGui")
        if playerGui then
            for _, gui in ipairs(playerGui:GetChildren()) do suppressGui(gui) end
            table.insert(SkillCheck.Connections, playerGui.ChildAdded:Connect(suppressGui))
        end
    else
        for _, conn in ipairs(SkillCheck.Connections) do conn:Disconnect() end
        SkillCheck.Connections = {}
        for gui, wasEnabled in pairs(SkillCheck.Hidden) do
            pcall(function() gui.Enabled = wasEnabled end)
        end
        SkillCheck.Hidden = {}
    end

    notify("No Skill Check", enabled and "ON" or "OFF")
end

-- ==========================================
-- Camera tools (one reapply loop, no stacking threads)
-- ==========================================

local OriginalCamera = {
    MaxZoom = Player.CameraMaxZoomDistance,
    Occlusion = Player.DevCameraOcclusionMode,
}

local function applyCameraTools()
    if State.InfiniteZoom then
        Player.CameraMaxZoomDistance = math.huge
    end
    if State.CameraNoclip then
        Player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
    end
end

task.spawn(function()
    while Running do
        task.wait(Config.CameraReapplyInterval)
        applyCameraTools()
    end
end)

local function setInfiniteZoom(enabled)
    State.InfiniteZoom = enabled
    Player.CameraMaxZoomDistance = enabled and math.huge or OriginalCamera.MaxZoom
    notify("Infinite Zoom", enabled and "ON" or "OFF")
end

local function setCameraNoclip(enabled)
    State.CameraNoclip = enabled
    Player.DevCameraOcclusionMode = enabled and Enum.DevCameraOcclusionMode.Invisicam or OriginalCamera.Occlusion
    notify("Camera Noclip", enabled and "ON" or "OFF")
end

-- ==========================================
-- ESP (third-party script: only run it if you trust the source)
-- ==========================================

local function loadESP()
    if State.ESPLoaded then
        notify("ESP", "Already loaded")
        return
    end
    local ok, err = pcall(function()
        loadstring(game:HttpGet(Config.ESPUrl))()
    end)
    State.ESPLoaded = ok
    notify("ESP", ok and "Loaded successfully" or ("Failed to load: " .. tostring(err)))
end

-- ==========================================
-- Cleanup
-- ==========================================

local function cleanup()
    Running = false
    State.SpeedLock = false
    applySpeed()
    setVisualClarity(false)
    setNoSkillCheck(false)
    setInfiniteZoom(false)
    setCameraNoclip(false)
    for _, conn in ipairs(Connections) do pcall(function() conn:Disconnect() end) end
    Connections = {}
    Rayfield:Destroy()
end

-- ==========================================
-- UI
-- ==========================================

local Window = Rayfield:CreateWindow({
    Name = "Enhanced Control Suite",
    LoadingTitle = "Loading Enhanced Controls...",
    LoadingSubtitle = "Speed, Visual, Camera & ESP Tools",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "EnhancedControlConfig",
        FileName = "EnhancedSettings",
    },
    Discord = { Enabled = false, Invite = "noinvitelink", RememberJoins = true },
    KeySystem = false,
})

-- Speed tab
local SpeedTab = Window:CreateTab("Speed Control", 4483362458)

SpeedTab:CreateSection("Speed Status")
UI.SpeedLabel = SpeedTab:CreateLabel("Current Speed: " .. State.WalkSpeed)
UI.SpeedLockLabel = SpeedTab:CreateLabel("Speed Lock: OFF")

SpeedTab:CreateSection("Speed Control")

UI.SpeedSlider = SpeedTab:CreateSlider({
    Name = "Walk Speed",
    Range = { Config.DefaultWalkSpeed, Config.MaxWalkSpeed },
    Increment = 1,
    Suffix = " studs",
    CurrentValue = State.WalkSpeed,
    Flag = "SpeedSlider",
    Callback = guarded(function(value)
        setWalkSpeed(value)
    end),
})

UI.SpeedLockToggle = SpeedTab:CreateToggle({
    Name = "Speed Lock",
    CurrentValue = State.SpeedLock,
    Flag = "SpeedLockToggle",
    Callback = guarded(setSpeedLock),
})

SpeedTab:CreateSection("Speed Multiplier")

-- No Flag on purpose: the Walk Speed slider is the saved source of truth,
-- otherwise two saved sliders fight each other when a config loads.
UI.MultiplierSlider = SpeedTab:CreateSlider({
    Name = "Speed Multiplier",
    Range = { 1.0, 5.0 },
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 1.0,
    Callback = guarded(setMultiplier),
})

SpeedTab:CreateSection("Quick Multipliers")
for _, multiplier in ipairs({ 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 2.0, 3.0, 4.0, 5.0 }) do
    SpeedTab:CreateButton({
        Name = multiplier .. "x",
        Callback = function()
            setMultiplier(multiplier)
            setElement(UI.MultiplierSlider, multiplier)
            notify("Walk Speed", "Speed set to: " .. State.WalkSpeed)
        end,
    })
end

SpeedTab:CreateSection("Quick Speed Presets")
for _, speed in ipairs({ 20, 30, 50, 75, 100 }) do
    SpeedTab:CreateButton({
        Name = speed .. " Studs",
        Callback = function()
            setWalkSpeed(speed)
            setElement(UI.SpeedSlider, State.WalkSpeed)
            notify("Walk Speed", "Speed set to: " .. State.WalkSpeed)
        end,
    })
end

SpeedTab:CreateSection("Reset")
SpeedTab:CreateButton({ Name = "FULL SPEED RESET", Callback = resetSpeed })

-- Anti-AFK tab
local AFKTab = Window:CreateTab("Anti-AFK", 7733960981)

AFKTab:CreateSection("Anti-AFK Settings")
UI.AntiAFKToggle = AFKTab:CreateToggle({
    Name = "Enable Anti-AFK",
    CurrentValue = State.AntiAFK,
    Flag = "AntiAFKToggle",
    Callback = guarded(setAntiAFK),
})

AFKTab:CreateParagraph({
    Title = "AFK Protection Info",
    Content = "When Roblox flags you as idle, Anti-AFK simulates a click so you are not kicked.",
})

AFKTab:CreateSection("AFK Status")
UI.LastInputLabel = AFKTab:CreateLabel("Last Input: 00:00 ago")

task.spawn(function()
    while Running do
        local idle = tick() - LastInputTime
        UI.LastInputLabel:Set(string.format("Last Input: %02d:%02d ago", idle // 60, idle % 60))
        task.wait(1)
    end
end)

-- Visual & Camera tab
local VisualTab = Window:CreateTab("Visual & Camera", 6034287595)

VisualTab:CreateSection("Visual Clarity")
UI.VisualClarityToggle = VisualTab:CreateToggle({
    Name = "Visual Clarity",
    CurrentValue = State.VisualClarity,
    Flag = "VisualClarityToggle",
    Callback = guarded(setVisualClarity),
})
VisualTab:CreateParagraph({
    Title = "Visual Clarity Info",
    Content = "Removes fog, raises brightness and disables shadows. Fully reversible. Keybind: F6",
})

VisualTab:CreateSection("No Skill Check")
UI.NoSkillCheckToggle = VisualTab:CreateToggle({
    Name = "No Skill Check",
    CurrentValue = State.NoSkillCheck,
    Flag = "NoSkillCheckToggle",
    Callback = guarded(setNoSkillCheck),
})
VisualTab:CreateParagraph({
    Title = "No Skill Check Info",
    Content = "Hides skill check GUIs in your PlayerGui. Keybind: F7",
})

VisualTab:CreateSection("Camera Tools")
UI.InfiniteZoomToggle = VisualTab:CreateToggle({
    Name = "Infinite Zoom",
    CurrentValue = State.InfiniteZoom,
    Flag = "InfiniteZoomToggle",
    Callback = guarded(setInfiniteZoom),
})
UI.CameraNoclipToggle = VisualTab:CreateToggle({
    Name = "Camera Noclip",
    CurrentValue = State.CameraNoclip,
    Flag = "CameraNoclipToggle",
    Callback = guarded(setCameraNoclip),
})
VisualTab:CreateParagraph({
    Title = "Camera Tools Info",
    Content = "Infinite Zoom (F8) and Camera Noclip (F10) are reapplied every "
        .. Config.CameraReapplyInterval .. "s in case the game resets them.",
})

VisualTab:CreateSection("ESP")
VisualTab:CreateButton({ Name = "Load WRD ESP", Callback = loadESP })
VisualTab:CreateParagraph({
    Title = "ESP Info",
    Content = "Loads an external WeAreDevs ESP script for player/enemy highlighting.",
})

-- Settings tab
local SettingsTab = Window:CreateTab("Settings", 6034509993)

SettingsTab:CreateSection("Speed Configuration")
SettingsTab:CreateSlider({
    Name = "Default Walk Speed",
    Range = { 16, 50 },
    Increment = 1,
    Suffix = " studs",
    CurrentValue = Config.DefaultWalkSpeed,
    Flag = "DefaultSpeedSlider",
    Callback = guarded(function(value)
        Config.DefaultWalkSpeed = value
        applySpeed()
    end),
})

SettingsTab:CreateSlider({
    Name = "Maximum Speed",
    Range = { 50, 500 },
    Increment = 10,
    Suffix = " studs",
    CurrentValue = Config.MaxWalkSpeed,
    Flag = "MaxSpeedSlider",
    Callback = guarded(function(value)
        Config.MaxWalkSpeed = value
        if State.WalkSpeed > value then
            setWalkSpeed(value)
            setElement(UI.SpeedSlider, State.WalkSpeed)
        end
    end),
})

-- Keybinds flip the toggle; the toggle's callback does the real work.
local function flip(toggleName, stateKey)
    return function()
        UI[toggleName]:Set(not State[stateKey])
    end
end

SettingsTab:CreateSection("Keybinds")
local keybinds = {
    { "Toggle Speed Lock", "V", "SpeedLockKeybind", flip("SpeedLockToggle", "SpeedLock") },
    { "Toggle Visual Clarity", "F6", "VisualClarityKeybind", flip("VisualClarityToggle", "VisualClarity") },
    { "Toggle No Skill Check", "F7", "NoSkillCheckKeybind", flip("NoSkillCheckToggle", "NoSkillCheck") },
    { "Toggle Infinite Zoom", "F8", "InfiniteZoomKeybind", flip("InfiniteZoomToggle", "InfiniteZoom") },
    { "Toggle Camera Noclip", "F10", "CameraNoclipKeybind", flip("CameraNoclipToggle", "CameraNoclip") },
}
for _, kb in ipairs(keybinds) do
    SettingsTab:CreateKeybind({
        Name = kb[1],
        CurrentKeybind = kb[2],
        HoldToInteract = false,
        Flag = kb[3],
        Callback = kb[4],
    })
end

SettingsTab:CreateSection("UI Settings")
SettingsTab:CreateButton({ Name = "Destroy GUI", Callback = cleanup })

-- ==========================================
-- Finish
-- ==========================================

Rayfield:LoadConfiguration()
Loading = false
updateSpeedLabels()
notify("System Loaded", "Enhanced Control Suite v2.1 is ready!")