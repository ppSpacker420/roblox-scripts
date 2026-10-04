--[[
    Enhanced Control Suite v3.0
    Same features as v2.3, rebuilt internals:
      * single feature registry (toggles, keybinds, panic all share one code path)
      * event-driven instead of polling (no RenderStepped / 5s loops)
      * fully reversible Visual Clarity (no reparenting of instances)
      * built-in Highlight ESP (no remote code execution)
      * re-execute safe (old instance is cleaned up automatically)
]]

-- ==========================================
-- Re-execute protection + library load
-- ==========================================

local env = (getgenv and getgenv()) or _G
if env.ECS_Cleanup then
    pcall(env.ECS_Cleanup)
    env.ECS_Cleanup = nil
end

local okLib, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not okLib or not Rayfield then
    warn("[ECS] Failed to load Rayfield: " .. tostring(Rayfield))
    return
end

-- ==========================================
-- Services & state
-- ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer

local Config = {
    Version = "v3.0",
    DefaultWalkSpeed = 16, -- base for multiplier / reset
    MaxWalkSpeed = 100,    -- safety cap (Settings tab)
    AbsoluteMaxSpeed = 500,
}

local State = {
    WalkSpeed = Config.DefaultWalkSpeed,
    SpeedLock = false,
    AntiAFK = false,
    VisualClarity = false,
    NoSkillCheck = false,
    InfiniteZoom = false,
    CameraNoclip = false,
    ESP = false,
}

local UI = {}
local Connections = {}
local Running = true
local Loading = true   -- suppress notifications during config load
local Quiet = false    -- suppress notifications during bulk operations
local Silent = false   -- suppress callbacks when we Set() elements ourselves
local LastInputTime = tick()
local Humanoid
local SpeedBackup      -- the game's own WalkSpeed, restored when lock is released

local function track(conn)
    table.insert(Connections, conn)
    return conn
end

local function notify(title, content)
    if Loading or Quiet or not Running then return end
    Rayfield:Notify({ Title = title, Content = content, Duration = 2, Image = 4483362458 })
end

local function setElement(element, value)
    if not element then return end
    Silent = true
    pcall(function() element:Set(value) end)
    Silent = false
end

local function guarded(fn)
    return function(...)
        if Silent then return end
        return fn(...)
    end
end

local function optionText(option)
    if type(option) == "table" then return option[1] end
    return option
end

local function parseLeadingNumber(text)
    return tonumber(tostring(text):match("^[%d%.]+"))
end

local function formatClock(seconds)
    seconds = math.floor(seconds)
    return string.format("%02d:%02d", seconds // 60, seconds % 60)
end

-- ==========================================
-- Feature registry (filled in below)
-- ==========================================

local Features = {}      -- key -> { name, set }
local FeatureOrder = {}
local ToggleGroups = {}  -- key -> { toggle elements that mirror each other }

local function registerFeature(key, name, setter)
    Features[key] = { name = name, set = setter }
    table.insert(FeatureOrder, key)
end

-- Single entry point used by toggles, keybinds, panic and cleanup.
local function setFeature(key, value, sourceElement)
    local feature = Features[key]
    if feature and State[key] ~= value then
        feature.set(value)
    end
    for _, element in ipairs(ToggleGroups[key] or {}) do
        if element ~= sourceElement then setElement(element, State[key]) end
    end
end

-- ==========================================
-- Character & speed
-- ==========================================

local function effectiveSpeed()
    return math.min(State.WalkSpeed, Config.MaxWalkSpeed)
end

local function applySpeed()
    if not (Humanoid and Humanoid.Parent) then return end
    if State.SpeedLock then
        local target = effectiveSpeed()
        if Humanoid.WalkSpeed ~= target then Humanoid.WalkSpeed = target end
    end
end

local function restoreSpeed()
    if Humanoid and Humanoid.Parent then
        Humanoid.WalkSpeed = SpeedBackup or Config.DefaultWalkSpeed
    end
end

local function onCharacter(char)
    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end
    Humanoid = hum
    SpeedBackup = hum.WalkSpeed
    applySpeed()
end

if Player.Character then task.spawn(onCharacter, Player.Character) end
track(Player.CharacterAdded:Connect(onCharacter))

-- Keeps both sliders and labels in sync. `source` is the slider being dragged
-- (never Set() the slider the user is touching, it causes jitter).
local function refreshSpeedUI(source)
    if UI.SpeedLabel then
        pcall(function() UI.SpeedLabel:Set("Current Speed: " .. effectiveSpeed() .. " studs") end)
    end
    if UI.SpeedLockLabel then
        pcall(function() UI.SpeedLockLabel:Set("Speed Lock: " .. (State.SpeedLock and "ON" or "OFF")) end)
    end
    if source ~= UI.SpeedSlider then setElement(UI.SpeedSlider, State.WalkSpeed) end
    if source ~= UI.MultiplierSlider then
        local mult = math.floor(State.WalkSpeed / Config.DefaultWalkSpeed * 10 + 0.5) / 10
        setElement(UI.MultiplierSlider, math.clamp(mult, 1, 5))
    end
end

local function setWalkSpeed(speed, source)
    State.WalkSpeed = math.clamp(math.floor(speed + 0.5), 1, Config.AbsoluteMaxSpeed)
    applySpeed()
    refreshSpeedUI(source)
end

registerFeature("SpeedLock", "Speed Lock", function(enabled)
    State.SpeedLock = enabled
    if enabled then
        if Humanoid then SpeedBackup = Humanoid.WalkSpeed end
        applySpeed()
    else
        restoreSpeed()
    end
    refreshSpeedUI()
    notify("Speed Lock", enabled and ("ON - Speed: " .. effectiveSpeed()) or "OFF")
end)

local function resetSpeed()
    setFeature("SpeedLock", false)
    setWalkSpeed(Config.DefaultWalkSpeed)
    notify("Speed Reset", "Reset to " .. Config.DefaultWalkSpeed)
end

track(RunService.Heartbeat:Connect(function()
    if State.SpeedLock then applySpeed() end
end))

-- ==========================================
-- Anti-AFK
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

registerFeature("AntiAFK", "Anti-AFK", function(enabled)
    State.AntiAFK = enabled
    notify("Anti-AFK", enabled and "ON" or "OFF")
end)

-- ==========================================
-- Visual Clarity (reversible, event-driven)
-- ==========================================

local ClarityLighting = {
    Brightness = 2,
    ClockTime = 14,
    FogEnd = 1e6,
    FogStart = 0,
    GlobalShadows = false,
    OutdoorAmbient = Color3.fromRGB(128, 128, 128),
    FogColor = Color3.fromRGB(255, 255, 255),
}

local FogKeywords = { "fog", "mist", "smoke", "haze" }
local Clarity = {
    Active = false,
    SavedLighting = {},
    Touched = setmetatable({}, { __mode = "k" }), -- inst -> { prop = original }
    Conns = {},
}

local function hasFogKeyword(name)
    name = name:lower()
    for _, word in ipairs(FogKeywords) do
        if name:find(word, 1, true) then return true end
    end
    return false
end

local function clarifyInstance(inst)
    if Clarity.Touched[inst] then return end
    local saved
    pcall(function()
        if inst:IsA("Atmosphere") then
            saved = { Density = inst.Density, Haze = inst.Haze }
            inst.Density, inst.Haze = 0, 0
        elseif inst:IsA("Clouds") or inst:IsA("BlurEffect") or inst:IsA("DepthOfFieldEffect") then
            saved = { Enabled = inst.Enabled }
            inst.Enabled = false
        elseif inst:IsA("ParticleEmitter") and hasFogKeyword(inst.Name) then
            saved = { Enabled = inst.Enabled }
            inst.Enabled = false
        end
    end)
    if saved then Clarity.Touched[inst] = saved end
end

local function enforceLightingProp(prop)
    if Clarity.Active and Lighting[prop] ~= ClarityLighting[prop] then
        Lighting[prop] = ClarityLighting[prop]
    end
end

registerFeature("VisualClarity", "Visual Clarity", function(enabled)
    State.VisualClarity = enabled
    Clarity.Active = enabled

    if enabled then
        for prop, value in pairs(ClarityLighting) do
            Clarity.SavedLighting[prop] = Lighting[prop]
            Lighting[prop] = value
            table.insert(Clarity.Conns, Lighting:GetPropertyChangedSignal(prop):Connect(function()
                enforceLightingProp(prop)
            end))
        end

        for _, inst in ipairs(Lighting:GetDescendants()) do clarifyInstance(inst) end
        table.insert(Clarity.Conns, Lighting.DescendantAdded:Connect(function(inst)
            task.defer(clarifyInstance, inst)
        end))
        table.insert(Clarity.Conns, Workspace.DescendantAdded:Connect(function(inst)
            if inst:IsA("ParticleEmitter") or inst:IsA("Clouds") then
                task.defer(clarifyInstance, inst)
            end
        end))

        -- Scan the workspace in chunks so large maps don't freeze the client.
        task.spawn(function()
            local count = 0
            for _, inst in ipairs(Workspace:GetDescendants()) do
                if not Clarity.Active then return end
                clarifyInstance(inst)
                count += 1
                if count % 1000 == 0 then task.wait() end
            end
        end)
    else
        for _, conn in ipairs(Clarity.Conns) do conn:Disconnect() end
        Clarity.Conns = {}

        for prop, value in pairs(Clarity.SavedLighting) do
            pcall(function() Lighting[prop] = value end)
        end
        for inst, props in pairs(Clarity.Touched) do
            for prop, value in pairs(props) do
                pcall(function() inst[prop] = value end)
            end
        end
        Clarity.SavedLighting = {}
        Clarity.Touched = setmetatable({}, { __mode = "k" })
    end

    notify("Visual Clarity", enabled and "ON" or "OFF")
end)

-- ==========================================
-- No Skill Check
-- ==========================================

local SkillCheck = { Guis = setmetatable({}, { __mode = "k" }), Conns = {} }

local function isSkillCheckGui(obj)
    if not obj:IsA("ScreenGui") then return false end
    local name = (obj.Name:lower():gsub("[%s_%-]", ""))
    return name:find("skillcheck", 1, true) ~= nil
end

local function suppressGui(gui)
    if not isSkillCheckGui(gui) then return end
    if SkillCheck.Guis[gui] == nil then
        SkillCheck.Guis[gui] = gui.Enabled
        table.insert(SkillCheck.Conns, gui:GetPropertyChangedSignal("Enabled"):Connect(function()
            if State.NoSkillCheck and gui.Enabled then gui.Enabled = false end
        end))
    end
    gui.Enabled = false
end

registerFeature("NoSkillCheck", "No Skill Check", function(enabled)
    State.NoSkillCheck = enabled

    if enabled then
        local playerGui = Player:WaitForChild("PlayerGui")
        for _, gui in ipairs(playerGui:GetChildren()) do suppressGui(gui) end
        table.insert(SkillCheck.Conns, playerGui.ChildAdded:Connect(suppressGui))
    else
        for _, conn in ipairs(SkillCheck.Conns) do conn:Disconnect() end
        SkillCheck.Conns = {}
        for gui, wasEnabled in pairs(SkillCheck.Guis) do
            pcall(function() gui.Enabled = wasEnabled end)
        end
        SkillCheck.Guis = setmetatable({}, { __mode = "k" })
    end

    notify("No Skill Check", enabled and "ON" or "OFF")
end)

-- ==========================================
-- Camera tools (re-applied instantly when the game changes them)
-- ==========================================

local Camera = { Saved = {}, Conns = {} }

local function connectCamera(prop, shouldApply, apply)
    table.insert(Camera.Conns, Player:GetPropertyChangedSignal(prop):Connect(function()
        if shouldApply() then apply() end
    end))
end

registerFeature("InfiniteZoom", "Infinite Zoom", function(enabled)
    State.InfiniteZoom = enabled
    if enabled then
        Camera.Saved.MaxZoom = Player.CameraMaxZoomDistance
        Player.CameraMaxZoomDistance = math.huge
        connectCamera("CameraMaxZoomDistance",
            function() return State.InfiniteZoom and Player.CameraMaxZoomDistance ~= math.huge end,
            function() Player.CameraMaxZoomDistance = math.huge end)
    else
        if Camera.Saved.MaxZoom then Player.CameraMaxZoomDistance = Camera.Saved.MaxZoom end
    end
    notify("Infinite Zoom", enabled and "ON" or "OFF")
end)

registerFeature("CameraNoclip", "Camera Noclip", function(enabled)
    State.CameraNoclip = enabled
    local mode = Enum.DevCameraOcclusionMode.Invisicam
    if enabled then
        Camera.Saved.Occlusion = Player.DevCameraOcclusionMode
        Player.DevCameraOcclusionMode = mode
        connectCamera("DevCameraOcclusionMode",
            function() return State.CameraNoclip and Player.DevCameraOcclusionMode ~= mode end,
            function() Player.DevCameraOcclusionMode = mode end)
    else
        if Camera.Saved.Occlusion then Player.DevCameraOcclusionMode = Camera.Saved.Occlusion end
    end
    notify("Camera Noclip", enabled and "ON" or "OFF")
end)

-- ==========================================
-- ESP (built-in Highlight + name/distance tag, no external scripts)
-- ==========================================
-- Note: Roblox renders at most ~31 Highlights at once.

local ESPColors = {
    Fill = Color3.fromRGB(255, 70, 70),
    Outline = Color3.fromRGB(255, 255, 255),
}

local ESP = { Objects = {}, Conns = {}, Folder = nil, Token = 0 }

local function getESPFolder()
    if ESP.Folder and ESP.Folder.Parent then return ESP.Folder end
    local folder = Instance.new("Folder")
    folder.Name = "ECS_ESP"
    local ok = pcall(function()
        folder.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    end)
    if not ok then folder.Parent = Player:WaitForChild("PlayerGui") end
    ESP.Folder = folder
    return folder
end

local function removeESP(plr)
    local obj = ESP.Objects[plr]
    if not obj then return end
    for _, conn in ipairs(obj.Conns) do conn:Disconnect() end
    obj.Highlight:Destroy()
    obj.Billboard:Destroy()
    ESP.Objects[plr] = nil
end

local function buildESP(plr)
    if plr == Player or ESP.Objects[plr] then return end
    local folder = getESPFolder()

    local highlight = Instance.new("Highlight")
    highlight.FillColor = ESPColors.Fill
    highlight.OutlineColor = ESPColors.Outline
    highlight.FillTransparency = 0.6
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = folder

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.fromOffset(140, 28)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = folder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.4
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.Text = plr.DisplayName
    label.Parent = billboard

    local obj = { Highlight = highlight, Billboard = billboard, Label = label, Conns = {} }
    ESP.Objects[plr] = obj

    local function bind(char)
        highlight.Adornee = char
        if plr.Team then highlight.FillColor = plr.TeamColor.Color end
        task.spawn(function()
            billboard.Adornee = char and char:WaitForChild("Head", 5) or nil
        end)
    end

    if plr.Character then bind(plr.Character) end
    table.insert(obj.Conns, plr.CharacterAdded:Connect(bind))
end

local function updateESP()
    local myChar = Player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    for plr, obj in pairs(ESP.Objects) do
        local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if root and myRoot then
            local dist = math.floor((root.Position - myRoot.Position).Magnitude)
            obj.Label.Text = string.format("%s [%d studs]", plr.DisplayName, dist)
        else
            obj.Label.Text = plr.DisplayName
        end
    end
end

registerFeature("ESP", "ESP", function(enabled)
    State.ESP = enabled
    ESP.Token += 1

    if enabled then
        for _, plr in ipairs(Players:GetPlayers()) do buildESP(plr) end
        ESP.Conns = {
            Players.PlayerAdded:Connect(buildESP),
            Players.PlayerRemoving:Connect(removeESP),
        }
        local token = ESP.Token
        task.spawn(function()
            while Running and State.ESP and ESP.Token == token do
                updateESP()
                task.wait(0.2)
            end
        end)
    else
        for _, conn in ipairs(ESP.Conns) do conn:Disconnect() end
        ESP.Conns = {}
        for plr in pairs(ESP.Objects) do removeESP(plr) end
        if ESP.Folder then ESP.Folder:Destroy() ESP.Folder = nil end
    end

    notify("ESP", enabled and "ON" or "OFF")
end)

-- ==========================================
-- Panic & cleanup
-- ==========================================

local function disableAll()
    Quiet = true
    for _, key in ipairs(FeatureOrder) do setFeature(key, false) end
    Quiet = false
    notify("Panic", "All features disabled")
end

local function cleanup()
    Running = false
    Quiet = true
    for _, key in ipairs(FeatureOrder) do pcall(setFeature, key, false) end
    for _, conn in ipairs(Connections) do pcall(function() conn:Disconnect() end) end
    Connections = {}
    for _, conn in ipairs(Camera.Conns) do pcall(function() conn:Disconnect() end) end
    Camera.Conns = {}
    pcall(function() Rayfield:Destroy() end)
    if env.ECS_Cleanup == cleanup then env.ECS_Cleanup = nil end
end
env.ECS_Cleanup = cleanup

-- ==========================================
-- UI helpers
-- ==========================================

local Themes = { "Amethyst", "Default", "AmberGlow", "Bloom", "DarkBlue", "Green", "Light", "Ocean", "Serenity" }
local COLOR_ON = Color3.fromRGB(90, 220, 130)
local COLOR_OFF = Color3.fromRGB(150, 150, 165)

local function divider(tab)
    pcall(function() tab:CreateDivider() end) -- missing in older Rayfield builds
end

-- A toggle bound to a feature. Any number of toggles per feature stay in sync.
local function addFeatureToggle(tab, key, name, flag)
    local element
    element = tab:CreateToggle({
        Name = name,
        CurrentValue = State[key],
        Flag = flag, -- nil for mirror toggles (state is saved by the main one)
        Callback = guarded(function(value)
            setFeature(key, value, element)
        end),
    })
    ToggleGroups[key] = ToggleGroups[key] or {}
    table.insert(ToggleGroups[key], element)
    return element
end

-- ==========================================
-- Window
-- ==========================================

local Window = Rayfield:CreateWindow({
    Name = "Enhanced Control Suite  |  " .. Config.Version,
    Icon = "layout-dashboard",
    LoadingTitle = "Enhanced Control Suite",
    LoadingSubtitle = "Speed - Visual - Camera - ESP",
    Theme = "Amethyst",
    ToggleUIKeybind = Enum.KeyCode.RightShift,
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "EnhancedControlConfig",
        FileName = "EnhancedSettings",
    },
    Discord = { Enabled = false, Invite = "noinvitelink", RememberJoins = true },
    KeySystem = false,
})

-- ---------- Home ----------
local HomeTab = Window:CreateTab("Home", "home")

HomeTab:CreateSection("Live Status")
UI.StatusSpeed = HomeTab:CreateLabel("Walk Speed: --", "gauge")
UI.StatusIdle = HomeTab:CreateLabel("Idle: 00:00", "timer")

divider(HomeTab)
HomeTab:CreateSection("Features")

local StatusLabels = {}
for _, key in ipairs(FeatureOrder) do
    StatusLabels[key] = HomeTab:CreateLabel(Features[key].name .. ": OFF", "x", COLOR_OFF)
end

divider(HomeTab)
HomeTab:CreateSection("Quick Actions")
addFeatureToggle(HomeTab, "SpeedLock", "Speed Lock", nil)
HomeTab:CreateButton({ Name = "Reset Speed", Callback = resetSpeed })
HomeTab:CreateButton({ Name = "Panic: Disable Everything", Callback = disableAll })

-- ---------- Speed ----------
local SpeedTab = Window:CreateTab("Speed", "zap")

SpeedTab:CreateSection("Status")
UI.SpeedLabel = SpeedTab:CreateLabel("Current Speed: " .. State.WalkSpeed .. " studs", "gauge")
UI.SpeedLockLabel = SpeedTab:CreateLabel("Speed Lock: OFF", "lock")

divider(SpeedTab)
SpeedTab:CreateSection("Manual Control")

UI.SpeedSlider = SpeedTab:CreateSlider({
    Name = "Walk Speed",
    Range = { 1, Config.AbsoluteMaxSpeed },
    Increment = 1,
    Suffix = " studs",
    CurrentValue = State.WalkSpeed,
    Flag = "SpeedSlider",
    Callback = guarded(function(value) setWalkSpeed(value, UI.SpeedSlider) end),
})

-- No Flag on purpose: Walk Speed is the saved source of truth.
UI.MultiplierSlider = SpeedTab:CreateSlider({
    Name = "Speed Multiplier",
    Range = { 1.0, 5.0 },
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 1.0,
    Callback = guarded(function(value)
        setWalkSpeed(Config.DefaultWalkSpeed * value, UI.MultiplierSlider)
    end),
})

addFeatureToggle(SpeedTab, "SpeedLock", "Speed Lock", "SpeedLockToggle")

divider(SpeedTab)
SpeedTab:CreateSection("Quick Presets")

local function presetNotify()
    notify("Walk Speed", "Set to " .. effectiveSpeed() .. (State.SpeedLock and "" or " (turn on Speed Lock to apply)"))
end

SpeedTab:CreateDropdown({
    Name = "Multiplier Preset",
    Options = { "1.0x", "1.1x", "1.2x", "1.3x", "1.4x", "1.5x", "2.0x", "3.0x", "4.0x", "5.0x" },
    CurrentOption = {},
    MultipleOptions = false,
    Callback = function(option)
        local multiplier = parseLeadingNumber(optionText(option))
        if not multiplier then return end
        setWalkSpeed(Config.DefaultWalkSpeed * multiplier)
        presetNotify()
    end,
})

SpeedTab:CreateDropdown({
    Name = "Studs Preset",
    Options = { "20 studs", "30 studs", "50 studs", "75 studs", "100 studs" },
    CurrentOption = {},
    MultipleOptions = false,
    Callback = function(option)
        local speed = parseLeadingNumber(optionText(option))
        if not speed then return end
        setWalkSpeed(speed)
        presetNotify()
    end,
})

divider(SpeedTab)
SpeedTab:CreateButton({ Name = "Full Speed Reset", Callback = resetSpeed })

-- ---------- Utility ----------
local UtilityTab = Window:CreateTab("Utility", "shield")

UtilityTab:CreateSection("Anti-AFK")
addFeatureToggle(UtilityTab, "AntiAFK", "Enable Anti-AFK", "AntiAFKToggle")
UI.LastInputLabel = UtilityTab:CreateLabel("Last Input: 00:00 ago", "mouse-pointer-click")
UtilityTab:CreateParagraph({
    Title = "How it works",
    Content = "When Roblox flags you as idle, Anti-AFK simulates a click so you are not kicked.",
})

-- ---------- Visual ----------
local VisualTab = Window:CreateTab("Visual", "eye")

VisualTab:CreateSection("Environment")
addFeatureToggle(VisualTab, "VisualClarity", "Visual Clarity", "VisualClarityToggle")
addFeatureToggle(VisualTab, "NoSkillCheck", "No Skill Check", "NoSkillCheckToggle")

divider(VisualTab)
VisualTab:CreateSection("Camera")
addFeatureToggle(VisualTab, "InfiniteZoom", "Infinite Zoom", "InfiniteZoomToggle")
addFeatureToggle(VisualTab, "CameraNoclip", "Camera Noclip", "CameraNoclipToggle")

divider(VisualTab)
VisualTab:CreateSection("ESP")
addFeatureToggle(VisualTab, "ESP", "Player ESP", "ESPToggle")

divider(VisualTab)
VisualTab:CreateParagraph({
    Title = "Notes",
    Content = "Visual Clarity removes fog, blur and depth of field, raises brightness and disables shadows (fully reversible).\n"
        .. "No Skill Check hides skill check GUIs in your PlayerGui.\n"
        .. "Camera tools are re-applied instantly if the game changes them.\n"
        .. "ESP is built in: highlight, name and distance for other players.",
})

-- ---------- Settings ----------
local SettingsTab = Window:CreateTab("Settings", "settings")

SettingsTab:CreateSection("Appearance")
SettingsTab:CreateDropdown({
    Name = "Theme",
    Options = Themes,
    CurrentOption = { "Amethyst" },
    MultipleOptions = false,
    Flag = "ThemeDropdown",
    Callback = function(option)
        local theme = optionText(option)
        if theme then pcall(function() Window.ModifyTheme(theme) end) end
    end,
})

divider(SettingsTab)
SettingsTab:CreateSection("Speed Limits")
SettingsTab:CreateSlider({
    Name = "Default Walk Speed",
    Range = { 1, 50 },
    Increment = 1,
    Suffix = " studs",
    CurrentValue = Config.DefaultWalkSpeed,
    Flag = "DefaultSpeedSlider",
    Callback = guarded(function(value)
        Config.DefaultWalkSpeed = value
        refreshSpeedUI()
    end),
})
-- Acts as a safety cap applied on top of Walk Speed, so the saved speed is never
-- destroyed by load order.
SettingsTab:CreateSlider({
    Name = "Maximum Speed",
    Range = { 50, Config.AbsoluteMaxSpeed },
    Increment = 10,
    Suffix = " studs",
    CurrentValue = Config.MaxWalkSpeed,
    Flag = "MaxSpeedSlider",
    Callback = guarded(function(value)
        Config.MaxWalkSpeed = value
        applySpeed()
        refreshSpeedUI()
    end),
})

divider(SettingsTab)
SettingsTab:CreateSection("Keybinds")
local keybinds = {
    { "Toggle Speed Lock",    "V",   "SpeedLockKeybind",     "SpeedLock" },
    { "Toggle Visual Clarity", "F6",  "VisualClarityKeybind", "VisualClarity" },
    { "Toggle No Skill Check", "F7",  "NoSkillCheckKeybind",  "NoSkillCheck" },
    { "Toggle Infinite Zoom",  "F8",  "InfiniteZoomKeybind",  "InfiniteZoom" },
    { "Toggle Camera Noclip",  "F10", "CameraNoclipKeybind",  "CameraNoclip" },
    { "Toggle ESP",            "F9",  "ESPKeybind",           "ESP" },
}
for _, kb in ipairs(keybinds) do
    local key = kb[4]
    SettingsTab:CreateKeybind({
        Name = kb[1],
        CurrentKeybind = kb[2],
        HoldToInteract = false,
        Flag = kb[3],
        Callback = function() setFeature(key, not State[key]) end,
    })
end

divider(SettingsTab)
SettingsTab:CreateSection("About")
SettingsTab:CreateLabel("Enhanced Control Suite " .. Config.Version, "info")
SettingsTab:CreateLabel("Press RightShift to hide or show the window", "keyboard")
SettingsTab:CreateButton({ Name = "Destroy GUI", Callback = cleanup })

-- ==========================================
-- Live dashboard refresh (only touches labels whose text changed)
-- ==========================================

task.spawn(function()
    local cache = {}

    local function update(id, label, text, icon, color)
        if cache[id] == text then return end
        cache[id] = text
        pcall(label.Set, label, text, icon, color)
    end

    while Running do
        local idleText = formatClock(tick() - LastInputTime)
        local liveSpeed = Humanoid and math.floor(Humanoid.WalkSpeed + 0.5) or "--"

        update("lastInput", UI.LastInputLabel, "Last Input: " .. idleText .. " ago")
        update("idle", UI.StatusIdle, "Idle: " .. idleText)
        update("speed", UI.StatusSpeed, "Walk Speed: " .. liveSpeed .. " studs")

        for _, key in ipairs(FeatureOrder) do
            local on = State[key]
            update(key, StatusLabels[key],
                Features[key].name .. ": " .. (on and "ON" or "OFF"),
                on and "check" or "x",
                on and COLOR_ON or COLOR_OFF)
        end
        task.wait(1)
    end
end)

-- ==========================================
-- Finish
-- ==========================================

Rayfield:LoadConfiguration()
Loading = false
refreshSpeedUI()
notify("System Loaded", "Enhanced Control Suite " .. Config.Version .. " is ready!")