--[[
	Portal Gun (PotatOS) - refactored
	Same behaviour as the original, restructured:
	  * one buildTool() instead of two 200-line copies
	  * one openPortal() used for both "create" and "re-place" (the original
	    copy-pasted the entire block twice per portal colour)
	  * per-slot portal tables instead of the TP1/portalin1/velocheck/... globals
	  * one cursor-icon function instead of 6 copies of the if/if/if/if chain
	  * every connection tracked and torn down on respawn
	  * R6/R15 arm animation in dedicated, self-restoring functions
]]

-- Services -------------------------------------------------------------------
local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local Debris             = game:GetService("Debris")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")

-- Objects --------------------------------------------------------------------
local player  = Players.LocalPlayer
local mouse   = player:GetMouse()
local world   = workspace

-- Tunables (named, so they are not magic numbers scattered through the file) --
local RAY_LENGTH          = 1000000000 -- original: 9999999999
local SPEED_OF_LIGHT      = 1070687350 -- studs/sec, for the travelling orb
local PORTAL_SPEED_GAIN   = 2.75
local SPEED_DAMPEN_GAIN   = 0.1
local GRAB_RANGE          = 10
local FOV_HELD            = 20
local FOV_DEFAULT         = 70
local FOV_LERP            = 0.4
local TOUCH_COOLDOWN      = 0.2
local VELOCITY_SAMPLE_WAIT = 0.1

local BLUE   = { name = "Blue1",   color = BrickColor.new("Bright blue"), outline = Color3.fromRGB(65, 222, 253) }
local ORANGE = { name = "Orange2", color = BrickColor.new("Neon orange"), outline = Color3.fromRGB(255, 225, 58) }
local LINKED = BrickColor.new("Really black") -- colour of a portal that has a pair

local CURSOR = {
	empty  = "rbxassetid://13683282532",
	blue   = "rbxassetid://13683350503",
	orange = "rbxassetid://13683371140",
	linked = "rbxassetid://13683216197",
	grab   = "",
}

-- State ----------------------------------------------------------------------
local state = {
	portals     = {},        -- [1] = blue slot, [2] = orange slot
	teleporting = false,
	equipped    = false,
	holding     = false,
	grabbed     = nil,
	dragger     = nil,
	tool        = nil,       -- bundle returned by buildTool()
}

local connections = {}     -- everything disconnected on respawn
local function track(conn)
	table.insert(connections, conn)
	return conn
end
local function disconnectAll()
	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
	table.clear(connections)
end

-- Shared sounds --------------------------------------------------------------
local teleportSound = Instance.new("Sound")
teleportSound.Name = "woosh"
teleportSound.Parent = world

local function playTeleportSound()
	teleportSound.SoundId = math.random(1, 2) == 2
		and "rbxassetid://232806289"
		or  "rbxassetid://2769872789"
	teleportSound:Play()
end

-- Cursor ---------------------------------------------------------------------
local function updateCursor()
	local p1, p2 = state.portals[1], state.portals[2]
	local icon
	if state.holding then
		icon = CURSOR.grab
	elseif p1 and p2 then
		icon = CURSOR.linked
	elseif p1 then
		icon = CURSOR.blue
	elseif p2 then
		icon = CURSOR.orange
	else
		icon = CURSOR.empty
	end
	mouse.Icon = icon
end

-- Portal rendering -----------------------------------------------------------
local openTweenInfo = TweenInfo.new(0.333, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)

local function makeSound(parent, name, soundId, volume, extra)
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = soundId
	s.Volume = volume
	for k, v in pairs(extra or {}) do
		s[k] = v
	end
	s.Parent = parent
	return s
end

-- Make the invisible trigger + surface-offset parts for a slot at (position, normal)
local function buildPortalParts(slot, position, normal)
	local face = CFrame.lookAt(position, position + normal)

	-- Surface trigger used to detect the player entering the portal
	slot.surface = Instance.new("Part", slot.root)
	slot.surface.Size = Vector3.new(0.5, 0.5, 0.5)
	slot.surface.Transparency = 1
	slot.surface.CanCollide = false
	slot.surface.Anchored = true
	slot.surface.CFrame = face * CFrame.Angles(0, -90, 0)

	-- Wide invisible probe that samples the player's speed just before entry
	slot.probe = Instance.new("Part", slot.root)
	slot.probe.Size = Vector3.new(10, 16, 20)
	slot.probe.Transparency = 1
	slot.probe.CanCollide = false
	slot.probe.CanQuery = false
	slot.probe.Anchored = true
	slot.probe.CFrame = face

	-- The visible "hole"
	slot.inner = Instance.new("Part", slot.root)
	slot.inner.Size = Vector3.new(0.5, 0.5, 0.5)
	slot.inner.CanCollide = false
	slot.inner.CanQuery = false
	slot.inner.Anchored = true
	slot.inner.Material = Enum.Material.Neon
	slot.inner.BrickColor = slot.config.color
	slot.inner.CFrame = face * CFrame.Angles(90, 0, 0)

	local mesh = Instance.new("SpecialMesh", slot.inner)
	mesh.MeshType = "Sphere"
	mesh.Scale = Vector3.new(1.1, 6, 0.05)
	mesh.Offset = Vector3.new(0, 0, -0.02)

	-- R15 characters need a wider, rounder trigger than the default mesh part
	if slot.isR15 then
		slot.r15Trigger = Instance.new("Part", slot.root)
		slot.r15Trigger.Size = Vector3.new(0.7, 0.7, 0.7)
		slot.r15Trigger.Transparency = 1
		slot.r15Trigger.CanCollide = false
		slot.r15Trigger.CanQuery = false
		slot.r15Trigger.Anchored = true
		slot.r15Trigger.CFrame = face
		TweenService:Create(slot.r15Trigger, openTweenInfo, {
			Size = Vector3.new(5, 7, 2.5),
		}):Play()
	end
end

local function destroyPortalParts(slot)
	for _, key in ipairs({ "surface", "probe", "inner", "r15Trigger" }) do
		if slot[key] then
			slot[key]:Destroy()
			slot[key] = nil
		end
	end
end

-- Both portals go dark once they are linked, so make sure both are re-coloured
local function refreshPortalColours()
	for i, slot in ipairs(state.portals) do
		if slot then
			local linked = state.portals[3 - i] ~= nil
			slot.inner.BrickColor = linked and LINKED or slot.config.color
			slot.inner.Material = Enum.Material.Neon
		end
	end
end

-- Teleport -------------------------------------------------------------------
local function doTeleport(fromSlot)
	local toSlot = state.portals[3 - fromSlot.index]
	local char   = player.Character
	local root   = char and char:FindFirstChild("HumanoidRootPart")
	if not (toSlot and root and not state.teleporting) then
		return
	end

	state.teleporting = true
	playTeleportSound()

	root.CFrame = toSlot.surface.CFrame
	root.AssemblyLinearVelocity = toSlot.root.CFrame.LookVector * (fromSlot.entrySpeed * PORTAL_SPEED_GAIN)
	world.CurrentCamera.CFrame = toSlot.root.CFrame

	-- If both portals are mounted flat in a wall, bleed off the speed again
	-- (mirrors the original check; wall-mounted portals report these angles).
	if fromSlot.inner.Orientation == Vector3.new(90, 90, 0)
		and toSlot.inner.Orientation == Vector3.new(90, 90, 0) then
		wait(TOUCH_COOLDOWN)
		root.AssemblyLinearVelocity = toSlot.root.CFrame.LookVector
			* (root.AssemblyLinearVelocity.Magnitude * SPEED_DAMPEN_GAIN)
	end

	wait(TOUCH_COOLDOWN)
	state.teleporting = false
end

local function connectPortalTouch(slot)
	slot.probe.Touched:Connect(function()
		slot.entrySpeed = player.Character.HumanoidRootPart.AssemblyLinearVelocity.Magnitude
		task.wait(VELOCITY_SAMPLE_WAIT)
	end)

	local trigger = slot.isR15 and slot.r15Trigger or slot.surface
	trigger.Touched:Connect(function(hit)
		if hit.Parent == player.Character then
			doTeleport(slot)
		end
	end)
end

-- Create or re-place a portal. Handles both cases; the original duplicated it.
local function openPortal(index, position, normal)
	local config = index == 1 and BLUE or ORANGE
	local slot   = state.portals[index]
	local isNew  = slot == nil

	if isNew then
		slot = {
			index    = index,
			config   = config,
			isR15    = player.Character.Humanoid.RigType == Enum.HumanoidRigType.R15,
			entrySpeed = 0,
		}
		state.portals[index] = slot

		slot.root = Instance.new("Part")
		slot.root.Name = config.name
		slot.root.Anchored = true
		slot.root.CanCollide = false
		slot.root.BrickColor = config.color
		slot.root.Material = Enum.Material.Neon

		local orbMesh = Instance.new("SpecialMesh", slot.root)
		orbMesh.MeshType = "Sphere"
		orbMesh.Scale = Vector3.new(1, 1.33, 0.05)
		orbMesh.Offset = Vector3.new(0, 0, -0.02)

		slot.idle = makeSound(slot.root, "Idle", "rbxassetid://148894502", 0.2, { Looped = true })
		slot.open = makeSound(slot.root, "Open", "rbxassetid://182981587", 0.35, {
			PlaybackSpeed = 1.02,
			PlayOnRemove  = true,
		})
		local burst = makeSound(slot.root, "OpenBurst", "rbxassetid://171399373", 0.6, {
			RollOffMinDistance = 30,
		})
		burst:Play()

		slot.highlight = Instance.new("Highlight", slot.root)
		slot.highlight.FillTransparency = 1
		slot.highlight.OutlineColor = config.outline
		slot.highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

		slot.root.Parent = world
	else
		-- Re-placing: destroy the old open sound so PlayOnRemove gives the
		-- re-triggered "woosh", then rebuild the parts at the new transform.
		slot.open:Destroy()
		slot.open = makeSound(slot.root, "Open", "rbxassetid://182981587", 0.35, {
			PlaybackSpeed = 1.02,
			PlayOnRemove  = true,
		})
		makeSound(slot.root, "OpenBurst", "rbxassetid://171399373", 0.6, {
			RollOffMinDistance = 30,
		}).Play()
	end

	slot.root.Size = Vector3.new(0.7, 0.7, 0.7)
	slot.root.CFrame = CFrame.lookAt(position, position + normal)

	destroyPortalParts(slot)
	buildPortalParts(slot, position, normal)
	connectPortalTouch(slot)
	refreshPortalColours()

	TweenService:Create(slot.inner, openTweenInfo, {
		Size        = Vector3.new(4.1, 1.23, 2.5),
		Transparency = 0,
	}):Play()
	TweenService:Create(slot.root, openTweenInfo, {
		Size        = Vector3.new(5, 6, 1),
		Transparency = 0,
	}):Play()

	if isNew then
		slot.idle:Play()
	end
	updateCursor()
end

-- Fire a portal: launch the orb, wait for it to land, then open the portal ----
local function firePortal(index, muzzlePosition)
	local info = TweenInfo.new(
		(muzzlePosition - mouse.Hit.Position).Magnitude / SPEED_OF_LIGHT,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.InOut
	)

	local orb = Instance.new("Part")
	orb.Name = "PortalOrb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(0.7, 0.7, 0.7)
	orb.Position = muzzlePosition
	orb.Anchored = true
	orb.CanCollide = false
	orb.Material = Enum.Material.Neon
	orb.BrickColor = index == 1 and BLUE.color or ORANGE.color
	Debris:AddItem(orb, info.Time)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local excluded = { player.Character, state.dragger }
	for _, slot in ipairs(state.portals) do
		if slot then
			excluded[#excluded + 1] = slot.root
		end
	end
	params.FilterDescendantsInstances = excluded

	orb.Parent = world
	TweenService:Create(orb, info, { Position = muzzlePosition }):Play()
	task.wait(info.Time)

	local hit = world:Raycast(muzzlePosition, (mouse.Hit.Position - muzzlePosition).Unit * RAY_LENGTH, params)
	if not hit then
		return
	end
	openPortal(index, hit.Position, hit.Normal)
end

local function clearPortals()
	for index, slot in ipairs(state.portals) do
		if slot then
			slot.root:Destroy()
			state.portals[index] = nil
		end
	end
	state.teleporting = false
end

-- World optimisation ---------------------------------------------------------
-- BasePart already covers Part/MeshPart/WedgePart/TrussPart.
local function disableQueryOnNonCollidables()
	for _, child in ipairs(world:GetDescendants()) do
		if child:IsA("BasePart") and not child.CanCollide then
			child.CanQuery = false
		end
	end
end
disableQueryOnNonCollidables()

-- Tool -----------------------------------------------------------------------
local function part(class, parent, props)
	local p = Instance.new(class, parent)
	for k, v in pairs(props) do
		p[k] = v
	end
	return p
end

local function weld(a, b, parent)
	local w = Instance.new("WeldConstraint", parent)
	w.Part0 = a
	w.Part1 = b
	return w
end

local function buildTool(character)
	local tool = Instance.new("Tool")
	tool.Name = "Portal Gun"
	tool.CanBeDropped = false
	tool.ToolTip = "LMB blue | RMB orange | R fizzle | F flashlight | E grab | C zoom"

	local handle = part("Part", nil, {
		Name        = "Handle",
		Size        = Vector3.new(1.1, 1.1, 2.8),
		Color       = Color3.fromRGB(255, 255, 255),
		Material    = Enum.Material.SmoothPlastic,
		CanCollide  = false,
	})
	handle.Parent = tool

	-- Grip mesh
	local grip = Instance.new("SpecialMesh", handle)
	grip.MeshId = "rbxassetid://10017565642"
	grip.TextureId = "rbxassetid://10017566144"
	grip.Scale = Vector3.new(0.2, 0.2, 0.2)

	-- Barrel (colour reflects the last portal fired) and muzzle ring
	local barrel = part("Part", handle, {
		Shape       = Enum.PartType.Cylinder,
		Orientation = Vector3.new(0, 90, 0),
		Position    = Vector3.new(0, -0.1, 0),
		Size        = Vector3.new(2, 0.5, 0.5),
		Material    = Enum.Material.SmoothPlastic,
		Color       = Color3.fromRGB(50, 50, 50),
		CanCollide  = false,
	})
	local ring = part("Part", handle, {
		Shape       = Enum.PartType.Cylinder,
		Orientation = Vector3.new(0, 0, -90),
		Position    = Vector3.new(0, 0, 0.88),
		Size        = Vector3.new(1, 0.2, 0.2),
		Material    = Enum.Material.Neon,
		BrickColor  = BrickColor.new("Really black"),
		CanCollide  = false,
	})

	-- Potato mascot
	local potato = part("Part", handle, {
		Orientation = Vector3.new(62.661, -41.965, 98.722),
		Position    = Vector3.new(0, 0.75, -1.5),
		CanCollide  = false,
	})
	local potatoMesh = Instance.new("SpecialMesh", potato)
	potatoMesh.MeshId = "rbxassetid://434881581"
	potatoMesh.TextureId = "rbxassetid://434881609"
	potatoMesh.Scale = Vector3.new(0.25, 0.25, 0.25)

	-- Gravity-gun field, hidden until a part is grabbed
	local fieldSpecs = {
		{ Size = Vector3.new(0.05, 0.743, 0.05),   Position = Vector3.new(0.025, 0.355, -2.277), Orientation = nil },
		{ Size = Vector3.new(0.05, 0.05, 1.222),   Position = Vector3.new(-0.433, -0.377, -2.26), Orientation = Vector3.new(39.204, -86.193, -4.388) },
		{ Size = Vector3.new(0.05, 0.05, 1.222),   Position = Vector3.new(0.486, -0.37, -2.258),   Orientation = Vector3.new(37.547, 86.861, 176.758) },
		{ Size = Vector3.new(0.224, 0.224, 0.224), Position = Vector3.new(0.051, 0.699, -2.306),  Orientation = nil, Ball = true },
		{ Size = Vector3.new(0.224, 0.224, 0.224), Position = Vector3.new(-0.93, -0.765, -2.23),  Orientation = nil, Ball = true },
		{ Size = Vector3.new(0.224, 0.224, 0.224), Position = Vector3.new(0.931, -0.743, -2.23),  Orientation = nil, Ball = true },
	}
	local fieldParts = {}
	for _, spec in ipairs(fieldSpecs) do
		local props = {
			CanCollide  = false,
			Material    = Enum.Material.Neon,
			BrickColor  = BrickColor.new("Pastel Blue"),
			Position    = spec.Position,
			Size        = spec.Size,
			Transparency = 1,
		}
		if spec.Ball then
			props.Shape = Enum.PartType.Ball
		end
		if spec.Orientation then
			props.Orientation = spec.Orientation
		end
		local p = part("Part", handle, props)
		weld(handle, p, tool)
		table.insert(fieldParts, p)
	end

	for _, p in ipairs({ ring, barrel, potato }) do
		weld(handle, p, tool)
	end

	local bundle = {
		tool    = tool,
		handle  = handle,
		barrel  = barrel,
		ring    = ring,
		field   = fieldParts,
		shoot   = {
			[1] = makeSound(handle, "ShootBlue", "rbxassetid://182981554", 1),
			[2] = makeSound(handle, "ShootOrange", "rbxassetid://142774034", 1),
		},
		potato  = makeSound(handle, "Potato", "rbxassetid://224618488", 1),
		gravity = makeSound(handle, "Gravity", "rbxassetid://7449423195", 1, { Looped = true }),
		click   = makeSound(handle, "Click", "rbxassetid://5991592592", 1),
		light   = part("SpotLight", handle, {
			Angle = 45, Brightness = 2, Range = 60, Enabled = false,
		}),
	}

	-- Grip is set by setupCharacter() once the rig type is known; this is the
	-- fallback for the first frame.
	tool.GripPos = Vector3.new(0.35, 0.25, 0.25)
	tool.Parent = player.Backpack

	return bundle
end

-- Gravity gun ----------------------------------------------------------------
local function setFieldVisible(bundle, visible)
	for _, p in ipairs(bundle.field) do
		p.Transparency = visible and 0 or 1
	end
end

local function createDragBall()
	local ball = part("Part", world, {
		Name         = "DragBall",
		Shape        = Enum.PartType.Ball,
		Size         = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1,
		CanCollide   = false,
	})
	return ball
end

local function addMover(part0)
	part0.Mover = Instance.new("BodyPosition", part0)
	part0.Mover.MaxForce = Vector3.new(40000, 40000, 40000)
	part0.Mover.P = 40000
	part0.Mover.D = 1000
	part0.Mover.Position = part0.Position

	part0.RotMover = Instance.new("BodyGyro", part0)
	part0.RotMover.MaxTorque = Vector3.new(3000, 3000, 3000)
	part0.RotMover.P = 3000
	part0.RotMover.D = 500
	part0.RotMover.CFrame = world.CurrentCamera.CFrame

	part0.RotOffset = Instance.new("CFrameValue", part0)
end

local function releaseGrab(bundle)
	state.grabbed = nil
	state.holding = false
	mouse.TargetFilter = nil
	if state.dragger then
		state.dragger:Destroy()
		state.dragger = nil
	end
	bundle.gravity:Stop()
	setFieldVisible(bundle, false)
	updateCursor()
end

local function toggleGrab(bundle, character)
	if state.holding then
		releaseGrab(bundle)
		return
	end

	local head = character:FindFirstChild("Head")
	local target = mouse.Target
	if not (head and target) then
		return
	end
	if (mouse.Hit.Position - head.Position).Magnitude > GRAB_RANGE or target.Anchored then
		return
	end

	state.grabbed = target
	state.holding = true
	bundle.gravity:Play()
	setFieldVisible(bundle, true)
	updateCursor()

	local ball = createDragBall()
	ball.CFrame = CFrame.new(mouse.Hit.Position)
	addMover(ball)
	state.dragger = ball

	-- Weld the grabbed part to the drag ball
	local weldJoint = Instance.new("ManualWeld", ball)
	weldJoint.Part0 = ball
	weldJoint.Part1 = target
	weldJoint.C0 = ball.CFrame:ToObjectSpace(target.CFrame)

	mouse.TargetFilter = target

	-- Follow the cursor until something releases the grab
	while state.dragger == ball do
		local cf = CFrame.new(head.Position, mouse.Hit.Position)
		ball.Mover.Position = (cf + cf.LookVector * 10).Position
		local offset = ball.RotOffset.Value
		ball.RotMover.CFrame = world.CurrentCamera.CFrame * CFrame.Angles(offset.X, offset.Y, offset.Z)
		task.wait()
	end
	mouse.TargetFilter = nil
end

-- Input ----------------------------------------------------------------------
local function connectInput(character, bundle)
	local tool = bundle.tool
	local function armed() -- can the gun be used right now
		return state.equipped and not state.holding and tool.Parent == character
	end

	track(tool.Equipped:Connect(function()
		state.equipped = true
		updateCursor()
		bundle.potato:Play()
		task.delay(6, function()
			if bundle.potato then
				bundle.potato.Volume = 0
			end
		end)
	end))

	track(tool.Unequipped:Connect(function()
		mouse.Icon = ""
		state.equipped = false
		releaseGrab(bundle)
	end))

	track(mouse.Button1Down:Connect(function()
		if not armed() then
			return
		end
		bundle.shoot[1]:Play()
		firePortal(1, bundle.barrel.CFrame * CFrame.new(0, 0, -2.7).Position)
		bundle.barrel.BrickColor = BLUE.color
		bundle.barrel.Material = Enum.Material.Neon
		bundle.ring.BrickColor = BLUE.color
	end))

	track(mouse.Button2Down:Connect(function()
		if not armed() then
			return
		end
		bundle.shoot[2]:Play()
		firePortal(2, bundle.barrel.CFrame * CFrame.new(0, 0, -2.7).Position)
		bundle.barrel.BrickColor = ORANGE.color
		bundle.barrel.Material = Enum.Material.Neon
		bundle.ring.BrickColor = ORANGE.color
	end))

	-- One key handler instead of three separate KeyDown connections
	track(mouse.KeyDown:Connect(function(key)
		if key == "f" and armed() then
			bundle.click:Play()
			bundle.light.Enabled = not bundle.light.Enabled
		elseif key == "r" and armed() then
			clearPortals()
			bundle.barrel.Material = Enum.Material.SmoothPlastic
			bundle.barrel.Color = Color3.fromRGB(50, 50, 50)
			bundle.ring.BrickColor = BrickColor.new("Really black")
			updateCursor()
		elseif key == "e" and state.equipped and tool.Parent == character then
			toggleGrab(bundle, character)
		end
	end))

	track(character.Humanoid.Died:Connect(function()
		tool:Destroy()
		clearPortals()
		releaseGrab(bundle)
	end))
end

-- Arm animation --------------------------------------------------------------
local function startR15ArmAnimation(character)
	local upperArm = character:WaitForChild("RightUpperArm")
	local shoulder = upperArm and upperArm:WaitForChild("RightShoulder")
	local root = character:WaitForChild("HumanoidRootPart")
	if not (shoulder and root) then
		return
	end
	local original = shoulder.Transform

	track(RunService.Stepped:Connect(function()
		if not state.equipped then
			shoulder.Transform = original
			return
		end
		local direction = mouse.Hit.lookVector * 5000
		-- Strip translation so the offset is purely rotational
		local rotationOffset = (root.CFrame - root.CFrame.p):inverse()
		shoulder.Transform = rotationOffset
			* CFrame.new(Vector3.zero, direction)
			* CFrame.Angles(math.pi / 2, 0, 0)
	end))
end

local function startR6ArmAnimation(character)
	local torso = character:WaitForChild("Torso")
	if not torso then
		return
	end
	local right = torso:FindFirstChild("Right Shoulder")
	local left  = torso:FindFirstChild("Left Shoulder")
	local neck  = torso:FindFirstChild("Neck")
	local origRight = right and right.C0
	local origLeft  = left and left.C0
	local origNeck  = neck and neck.C0

	local function setLerp(part0, target, alpha)
		if part0 then
			part0.C0 = part0.C0:Lerp(target, alpha)
		end
	end

	track(RunService.RenderStepped:Connect(function()
		if not state.equipped then
			setLerp(right, origRight, 0.1)
			setLerp(left, origLeft, 0.1)
			setLerp(neck, origNeck, 0.2)
			return
		end
		local pitch = -math.asin((mouse.Origin.Position - mouse.Hit.Position).Unit.Y)
		setLerp(right, CFrame.new(1, 0.65, 0) * CFrame.Angles(pitch, 1.55, 0), 0.1)
		setLerp(left,  CFrame.new(-1, 0.65, 0) * CFrame.Angles(pitch, -1.55, 0), 0.1)
		setLerp(neck,  CFrame.new(0, 1, 0) * CFrame.Angles(pitch + 1.55, 3.15, 0), 0.2)
	end))
end

-- Spyglass ------------------------------------------------------------------
local function startZoom()
	task.spawn(function()
		while task.wait() do
			local cam = world.CurrentCamera
			local target = UserInputService:IsKeyDown(Enum.KeyCode.C) and FOV_HELD or FOV_DEFAULT
			if cam and cam.FieldOfView ~= target then
				cam.FieldOfView = math.clamp(
					cam.FieldOfView + (target - cam.FieldOfView) * FOV_LERP,
					0, 480
				)
			end
		end
	end)
end

-- Character lifecycle --------------------------------------------------------
local function setupCharacter(character)
	disconnectAll()

	if state.tool then
		state.tool.tool:Destroy()
	end
	clearPortals()
	releaseGrab(state.tool or { gravity = { Stop = function() end } })

	local humanoid = character:WaitForChild("Humanoid")
	if not humanoid then
		return
	end

	local bundle = buildTool(character)
	state.tool = bundle
	bundle.isR15 = humanoid.RigType == Enum.HumanoidRigType.R15
	if bundle.isR15 then
		bundle.tool.GripPos = Vector3.new(0.2, 0.25, -0.1)
	else
		bundle.tool.GripPos = Vector3.new(0.35, 0.25, 0.25)
	end

	connectInput(character, bundle)
	if bundle.isR15 then
		startR15ArmAnimation(character)
	else
		startR6ArmAnimation(character)
	end

	updateCursor()
end

player.CharacterAdded:Connect(setupCharacter)
if player.Character then
	task.spawn(setupCharacter, player.Character)
end

startZoom()

print("GLaDOS: Oh hi. You're an exploiter huh? Well I'm a POTATO. I am communicating via the ROBLOX console.")
print("GLaDOS: Oh by the way, I am not liable if you get banned from ROBLOX games with this portal device.")
warn("'Speedy thing goes in, speedy thing comes out.'")
warn("Controls: LMB Blue | RMB Orange | R Fizzle | F Flashlight | E Grab | C Zoom")
