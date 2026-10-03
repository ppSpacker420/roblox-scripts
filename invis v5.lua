local offset = 1100
local invisible = false
local grips = {}
local heldTool
local gripChanged
local handle
local weld
local isToolInInventory = false
local repeatEnabled = true

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

-- Function to check and add tool to inventory
local function checkAndAddToInventory()
    -- Check if tool already exists in inventory
    if backpack:FindFirstChild("Invisible") then
        isToolInInventory = true
        return true
    end
    
    -- Wait for Backpack to exist
    if not player:FindFirstChild("Backpack") then
        repeat task.wait() until player:FindFirstChild("Backpack")
    end
    
    -- Add tool to backpack
    tool.Parent = player.Backpack
    isToolInInventory = true
    
    -- Auto-equip the tool
    player.Backpack:WaitForChild("Invisible")
    tool:Activate()
    
    -- Enable backpack GUI (inventory)
    if game:GetService("StarterGui"):GetCoreGuiEnabled(Enum.CoreGuiType.Backpack) == false then
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
    end
    
    return true
end

-- Function to auto-enable when character respawns
local function onCharacterAdded(newChar)
    character = newChar
    task.wait(1) -- Wait for character to fully load
    
    if invisible then
        -- Re-enable invisible mode on respawn
        tool:Activate()
    end
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Tool equipped event
tool.Equipped:Connect(function()
    task.wait(0.1)
    
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
    task.wait()
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
            task.wait()
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

-- Function to run the check every 5 seconds
local function startRepeatingCheck()
    repeatEnabled = true
    
    -- Use a separate coroutine for the loop
    spawn(function()
        while repeatEnabled do
            task.wait(5) -- Wait 5 seconds
            
            -- Check if player exists
            if not player or not player.Parent then
                break
            end
            
            -- Check if backpack exists
            if not player:FindFirstChild("Backpack") then
                continue
            end
            
            -- Update backpack reference
            backpack = player.Backpack
            
            -- Check if tool is in inventory
            if not backpack:FindFirstChild("Invisible") then
                print("[" .. os.date("%X") .. "] Tool not found in inventory, re-adding...")
                
                -- Recreate the tool if it was destroyed
                if not tool or not tool.Parent then
                    tool = Instance.new("Tool")
                    tool.Name = "Invisible"
                    tool.RequiresHandle = false
                    tool.CanBeDropped = false
                    
                    -- Reconnect the equipped event
                    tool.Equipped:Connect(function()
                        task.wait(0.1)
                        
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
                end
                
                -- Add to inventory
                tool.Parent = backpack
                isToolInInventory = true
                
                -- Auto-equip
                task.wait(0.5)
                if tool and tool.Parent then
                    tool:Activate()
                end
                
                print("[" .. os.date("%X") .. "] Tool re-added to inventory")
            else
                -- Tool is already in inventory
                if not isToolInInventory then
                    isToolInInventory = true
                end
            end
            
            -- Keep backpack GUI enabled
            if not game:GetService("StarterGui"):GetCoreGuiEnabled(Enum.CoreGuiType.Backpack) then
                game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
            end
            
            -- Check if tool is equipped and re-equip if needed
            if isToolInInventory and invisible and not character:FindFirstChild("Invisible") then
                -- Tool should be in character but isn't, re-equip
                if backpack:FindFirstChild("Invisible") then
                    task.wait(0.5)
                    if backpack.Invisible then
                        backpack.Invisible:Activate()
                        print("[" .. os.date("%X") .. "] Re-equipped invisible tool")
                    end
                end
            end
            
            print("[" .. os.date("%X") .. "] Inventory check completed. Tool in inventory: " .. tostring(isToolInInventory))
        end
    end)
end

-- Stop the repeating check (can be called if needed)
local function stopRepeatingCheck()
    repeatEnabled = false
    print("Repeating check stopped")
end

-- Initial setup
task.wait(1) -- Wait for everything to load
checkAndAddToInventory()

-- Start the repeating check
startRepeatingCheck()

-- Enable backpack GUI initially
spawn(function()
    task.wait(2)
    if not game:GetService("StarterGui"):GetCoreGuiEnabled(Enum.CoreGuiType.Backpack) then
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
    end
end)

print("[" .. os.date("%X") .. "] Invisible tool system loaded. Will check inventory every 5 seconds.")

-- Optional: Add a way to stop/start the repeating check (for debugging)
game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
    if not processed then
        if input.KeyCode == Enum.KeyCode.P then
            if repeatEnabled then
                stopRepeatingCheck()
            else
                startRepeatingCheck()
                print("[" .. os.date("%X") .. "] Repeating check restarted")
            end
        elseif input.KeyCode == Enum.KeyCode.O then
            -- Force add tool to inventory
            checkAndAddToInventory()
            print("[" .. os.date("%X") .. "] Force added tool to inventory")
        end
    end
end)