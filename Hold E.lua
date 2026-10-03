local VIM = game:GetService("VirtualInputManager")

local HOLD_TIME = 1     -- seconds to hold E
local DELAY     = 0.5   -- seconds to wait before holding again

getgenv().HoldE = true  -- set to false and re-run to stop

task.spawn(function()
    while getgenv().HoldE do
        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)   -- press E down
        task.wait(HOLD_TIME)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)  -- release E
        task.wait(DELAY)
    end
end)