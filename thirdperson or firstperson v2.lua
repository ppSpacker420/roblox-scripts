-- Toggle between First Person and Third Person Camera
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Camera settings
local isFirstPerson = false
local toggleKey = Enum.KeyCode.F5 -- More reliable keybind
local defaultZoom = 10 -- Default third-person zoom distance
local maxZoom = 100 -- Maximum zoom distance
local minZoom = 0.5 -- Minimum zoom distance
local zoomSpeed = 2 -- How fast to zoom with scroll wheel

-- Function to set first-person camera
local function setFirstPerson()
    if not player.Character or not player.Character:FindFirstChild("Humanoid") then
        return
    end
    
    player.CameraMode = Enum.CameraMode.LockFirstPerson
    isFirstPerson = true
    
    print("Switched to First Person")
end

-- Function to set third-person camera
local function setThirdPerson()
    if not player.Character or not player.Character:FindFirstChild("Humanoid") then
        return
    end
    
    player.CameraMode = Enum.CameraMode.Classic
    player.CameraMaxZoomDistance = maxZoom
    
    -- Start with default zoom
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.CameraOffset = Vector3.new(0, 0, 0)
    end
    
    isFirstPerson = false
    print("Switched to Third Person")
end

-- Function to toggle between camera modes
local function toggleCamera()
    if isFirstPerson then
        setThirdPerson()
    else
        setFirstPerson()
    end
end

-- Set up input listener for toggle
local function setupInput()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == toggleKey then
            toggleCamera()
        end
    end)
    
    -- Mouse wheel zoom for third person
    mouse.WheelForward:Connect(function()
        if not isFirstPerson and player.Character then
            local currentZoom = player.CameraMaxZoomDistance
            player.CameraMaxZoomDistance = math.min(currentZoom + zoomSpeed, maxZoom)
        end
    end)
    
    mouse.WheelBackward:Connect(function()
        if not isFirstPerson and player.Character then
            local currentZoom = player.CameraMaxZoomDistance
            player.CameraMaxZoomDistance = math.max(currentZoom - zoomSpeed, minZoom)
        end
    end)
end

-- Initialize camera
local function initialize()
    -- Wait for player to load
    repeat wait() until player.Character
    wait(1) -- Extra wait for character to fully load
    
    -- Start in third person by default
    setThirdPerson()
    
    -- Setup input
    setupInput()
    
    -- Handle character respawns
    player.CharacterAdded:Connect(function()
        wait(1) -- Wait for character to load
        if isFirstPerson then
            setFirstPerson()
        else
            setThirdPerson()
        end
    end)
    
    print("Camera toggle system loaded. Press F5 to toggle between first/third person.")
end

-- Start the system
initialize()