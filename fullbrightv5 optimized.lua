-- Optimized Full Bright & No Fog
-- Only updates when needed

local Lighting = game:GetService("Lighting")
local enabled = true

-- Store original values to restore if needed
local originalValues = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogStart = Lighting.FogStart
}

local function enableFeatures()
    -- Apply full bright
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.GlobalShadows = false
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    
    -- Remove fog and atmospheres
    Lighting.FogEnd = 1000000
    Lighting.FogStart = 0
    
    -- Clean up existing atmospheres once
    local atmospheres = {}
    for _, obj in pairs(Lighting:GetDescendants()) do
        if obj:IsA("Atmosphere") then
            table.insert(atmospheres, obj)
        end
    end
    for _, atm in ipairs(atmospheres) do
        atm:Destroy()
    end
    
    print("Full Bright & No Fog: ENABLED")
end

local function disableFeatures()
    -- Restore original values
    for key, value in pairs(originalValues) do
        Lighting[key] = value
    end
    print("Full Bright & No Fog: DISABLED")
end

-- Toggle function
local function toggle()
    enabled = not enabled
    if enabled then
        enableFeatures()
    else
        disableFeatures()
    end
end

-- Enable on startup
enableFeatures()

-- Create simple command
local function handleChat(command)
    if command:lower() == "/fullbright" then
        toggle()
        return true
    end
    return false
end

-- Hook into chat if available
if game:GetService("TextChatService") then
    game:GetService("TextChatService").TextChannelAdded:Connect(function(channel)
        channel.OnIncomingMessage = function(message)
            if handleChat(message.Text) then
                return nil -- Block the message
            end
            return message
        end
    end)
end

print("Full Bright & No Fog loaded!")
print("Type /fullbright in chat to toggle")