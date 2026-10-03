--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local AimRadius = 100
local AimEnabled = false
local ToggleKey = Enum.KeyCode.E
local TargetPlayer = nil

local Smoothness = 0.2

local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = AimRadius

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local character = player.Character
            local head = character:FindFirstChild("Head")
            local screenPos, onScreen = workspace.CurrentCamera:WorldToScreenPoint(head.Position)

            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                if distance < shortestDistance then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end

    return closestPlayer
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == ToggleKey then
        if AimEnabled then
            AimEnabled = false
            TargetPlayer = nil
        else
            TargetPlayer = GetClosestPlayer()
            AimEnabled = TargetPlayer ~= nil
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if AimEnabled and TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChild("Head") then
        local head = TargetPlayer.Character:FindFirstChild("Head")
        local screenPos = workspace.CurrentCamera:WorldToScreenPoint(head.Position)

        local targetX = (screenPos.X - Mouse.X) * Smoothness
        local targetY = (screenPos.Y - Mouse.Y) * Smoothness

        mousemoverel(targetX, targetY)
    end
end)
