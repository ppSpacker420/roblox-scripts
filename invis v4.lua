local offset = 1100
local invisible = false
local grips = {}
local heldTool
local gripChanged
local handle
local weld

-- Get player
local player = game.Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")
local character = player.Character or player.CharacterAdded:Wait()

-- Function to set display distances
function setDisplayDistance(distance)
    for _, player in pairs(game.Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChildWhichIsA("Humanoid") then
            player.Character:FindFirstChildWhichIsA("Humanoid").NameDisplayDistance = distance
            player.Character:FindFirstChildWhichIsA("Humanoid").HealthDisplayDistance = distance
        end
    end
end

-- Create the invisible tool
local tool = Instance.new("Tool")
tool.Name = "Invisible"
tool.RequiresHandle = false
tool.CanBeDropped = false

-- Function to add tool to inventory
local function addToInventory()
    -- Wait for Backpack to exist
    if not player:FindFirstChild("Backpack") then
        repeat wait() until player:FindFirstChild("Backpack")
    end
    
    -- Add tool to backpack
    tool.Parent = player.Backpack
    
    -- Auto-equip the tool
    player.Backpack:WaitForChild("Invisible")
    tool:Activate()
    
    -- Enable backpack GUI (inventory)
    if game:GetService("StarterGui"):GetCoreGuiEnabled(Enum.CoreGuiType.Backpack) == false then
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
    end
end

-- Function to auto-enable when character respawns
local function onCharacterAdded(newChar)
    character = newChar
    wait(1) -- Wait for character to fully load
    
    if invisible then
        -- Re-enable invisible mode on respawn
        tool:Activate()
    end
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Tool equipped event
tool.Equipped:Connect(function()
    wait(0.1)
    
    if not invisible then
        -- Enable invisible mode
        invisible = true
        tool.Name = "Enabled Invisible"
        
        if handle then handle:Destroy() end
        if weld then weld:Destroy() end
        
        -- Create handle for camera
        handle = Instance.new("Part", workspace)
        handle.Name = "Handle"
        handle.Transparency = 1
        handle.CanCollide = false
        handle.Size = Vector3.new(2, 1, 1)
        
        -- Create weld to character
        weld = Instance.new("Weld", handle)
        weld.Part0 = handle
        weld.Part1 = character:WaitForChild("HumanoidRootPart")
        weld.C0 = CFrame.new(0, offset - 1.5, 0)
        
        -- Set display distances
        setDisplayDistance(offset + 100)
        
        -- Set camera to handle
        workspace.CurrentCamera.CameraSubject = handle
        
        -- Move character up
        character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, offset, 0)
        character.Humanoid.HipHeight = offset
        character.Humanoid:ChangeState(11) -- Free fall state
        
        -- Save tool grips
        for _, child in pairs(backpack:GetChildren()) do
            if child:IsA("Tool") and child ~= tool then
                grips[child] = child.Grip
            end
        end
        
    else
        -- Disable invisible mode
        invisible = false
        tool.Name = "Disabled Invisible"
        
        if handle then handle:Destroy() end
        if weld then weld:Destroy() end
        
        -- Move tools back to backpack
        for _, child in pairs(character:GetChildren()) do
            if child:IsA("Tool") then
                child.Parent = backpack
            end
        end
        
        -- Restore original grips
        for toolObj, grip in pairs(grips) do
            if toolObj and toolObj.Parent then
                toolObj.Grip = grip
            end
        end
        
        heldTool = nil
        
        -- Reset display distances
        setDisplayDistance(100)
        
        -- Reset camera
        workspace.CurrentCamera.CameraSubject = character.Humanoid
        
        -- Move character back down
        character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, -offset, 0)
        character.Humanoid.HipHeight = 0
    end
    
    -- Return tool to backpack
    tool.Parent = backpack
end)

-- Handle tool pickup while invisible
character.ChildAdded:Connect(function(child)
    wait()
    if invisible and child:IsA("Tool") and child ~= heldTool and child ~= tool then
        heldTool = child
        local lastGrip = heldTool.Grip
        
        if not grips[heldTool] then
            grips[heldTool] = lastGrip
        end
        
        -- Stop animations
        for _, track in pairs(character.Humanoid:GetPlayingAnimationTracks()) do
            track:Stop()
        end
        
        if character:FindFirstChild("Animate") then
            character.Animate.Disabled = true
        end
        
        -- Adjust grip for invisible mode
        heldTool.Grip = heldTool.Grip * (CFrame.new(0, offset - 1.5, 1.5) * CFrame.Angles(math.rad(-90), 0, 0))
        
        -- Move tool between backpack and character to refresh
        heldTool.Parent = backpack
        heldTool.Parent = character
        
        if gripChanged then
            gripChanged:Disconnect()
        end
        
        -- Monitor grip changes
        gripChanged = heldTool:GetPropertyChangedSignal("Grip"):Connect(function()
            wait()
            if not invisible then
                gripChanged:Disconnect()
            end
            
            if heldTool.Grip ~= lastGrip then
                lastGrip = heldTool.Grip * (CFrame.new(0, offset - 1.5, 1.5) * CFrame.Angles(math.rad(-90), 0, 0))
                heldTool.Grip = lastGrip
                heldTool.Parent = backpack
                heldTool.Parent = character
            end
        end)
    end
end)

-- Auto-execute when script runs
wait(1) -- Wait for everything to load
addToInventory()

-- Enable backpack (inventory) if disabled
spawn(function()
    wait(2)
    if not game:GetService("StarterGui"):GetCoreGuiEnabled(Enum.CoreGuiType.Backpack) then
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
    end
end)

print("Invisible tool added to inventory and auto-enabled!")