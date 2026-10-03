--[[
	Cooldown v1.0.1 by NoirSplash
	
	For API see github repository;
	https://github.com/NoirSplash/cooldown
]]

local GARBAGE_COLLECT_INTERVAL = 120

local Cooldown = {}
Cooldown.__index = Cooldown

Cooldown.cache = {}
Cooldown.doCleaning = true

function Cooldown.set(cooldownId: string, duration: number, isMillis: boolean?)
	local now = DateTime.now().UnixTimestampMillis
	local duration = if isMillis then duration else duration * 1000
	local endTime = now + duration

	Cooldown.cache[cooldownId] = endTime
end

function Cooldown.get(cooldownId: string): number?
	local cachedCd = Cooldown.cache[cooldownId]
	local now = DateTime.now().UnixTimestampMillis
	
	if cachedCd ~= nil then
		if now > cachedCd then
			Cooldown.cache[cooldownId] = nil
			cachedCd = nil
		else
			cachedCd -= now
		end
	end
	
	return cachedCd
end

task.spawn(function()
	local function cleanCache()
		local now = DateTime.now().UnixTimestampMillis
		for index, value in Cooldown.cache do
			if now > value then
				Cooldown.cache[index] = nil
			end
		end
	end
	
	while Cooldown.doCleaning do
		task.wait(GARBAGE_COLLECT_INTERVAL)
		cleanCache()
	end
end)

return Cooldown