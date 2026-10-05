--[[
	CS:GO Wall-Aware ESP + Player Teleport (combined)

	Merged from:
	  - csgo esp wall aware v1.lua   (ESP, team detection, wall detection, color overrides)
	  - player teleport gui v1.lua   (player list, drag window, teleport button)

	The ESP list already selected a player for color overrides, so the teleport
	GUI's separate list is gone: clicking a row selects it, and TELEPORT moves
	you to whoever is selected.

	Keys: RightShift = ESP on/off | Insert = show/hide menu | End = unload
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Teams = game:GetService("Teams")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

----------------------------------------------------------------
-- SETTINGS
----------------------------------------------------------------
local COLORS = {
	Frame       = Color3.fromRGB(20, 20, 28),
	TitleBar    = Color3.fromRGB(30, 120, 200),
	List        = Color3.fromRGB(14, 14, 20),
	Row         = Color3.fromRGB(35, 35, 45),
	RowSelected = Color3.fromRGB(30, 120, 200),
	On          = Color3.fromRGB(40, 160, 70),
	Off         = Color3.fromRGB(60, 60, 60),
	Neutral     = Color3.fromRGB(70, 70, 70),
	Accent      = Color3.fromRGB(30, 120, 200),
	Button      = Color3.fromRGB(55, 55, 55),
	Danger      = Color3.fromRGB(150, 25, 25),
	Health      = Color3.fromRGB(0, 220, 60),
	Text        = Color3.fromRGB(255, 255, 255),
	Muted       = Color3.fromRGB(160, 160, 160),
	Weapon      = Color3.fromRGB(255, 220, 100),
	Distance    = Color3.fromRGB(200, 200, 200),
}

local CT_COLOR          = Color3.fromRGB(100, 180, 255)
local T_COLOR           = Color3.fromRGB(255, 120, 40)
local DEFAULT_COLOR     = Color3.fromRGB(255, 255, 255)
local ALLY_COLOR        = Color3.fromRGB(0, 255, 100)
local ALLY_BEHIND_WALL  = Color3.fromRGB(0, 150, 60)
local ENEMY_COLOR       = Color3.fromRGB(255, 50, 50)
local ENEMY_BEHIND_WALL = Color3.fromRGB(180, 30, 30)

-- one table so the GUI toggles and the render loop read the same live values
local state = {
	BOX_ON = true,
	SKELETON_ON = true,
	NAME_ON = true,
	TRACER_ON = true,
	HEALTHBAR_ON = true,
	DISTANCE_ON = true,
	WEAPON_ON = true,
	SHOW_TEAM_NAME = true,
	HIDE_TEAMMATES = false,

	TOGGLE_KEY = Enum.KeyCode.RightShift,
	MENU_KEY = Enum.KeyCode.Insert,
	KILL_KEY = Enum.KeyCode.End,

	TELEPORT_HEIGHT = 3, -- studs above the target
}

local CT_HINTS = {"ct", "counter", "police", "blue", "law", "guard", "swat", "nato"}
local T_HINTS  = {"t", "terror", "red", "bomb", "crook", "rebel", "enemy"}

if getgenv().ESP_Unload then
	getgenv().ESP_Unload()
end

----------------------------------------------------------------
-- BONES
----------------------------------------------------------------
local R15_BONES = {
	{"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
	{"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
	{"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
	{"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"}, {"LeftLowerLeg","LeftFoot"},
	{"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
}

local R6_BONES = {
	{"Head","Torso"}, {"Torso","Left Arm"}, {"Torso","Right Arm"},
	{"Torso","Left Leg"}, {"Torso","Right Leg"},
}

----------------------------------------------------------------
-- STATE
----------------------------------------------------------------
local objects = {}
local overrides = {}
local teamCache = {}
local visible = true
local killed = false
local selected = nil   -- the Player the row list has selected
local target = "All"   -- which part of the ESP a swatch recolors

----------------------------------------------------------------
-- WALL DETECTION
----------------------------------------------------------------
local function isBehindWall(player1Hrp, player2Hrp)
	if not player1Hrp or not player2Hrp then
		return false
	end

	local direction = player2Hrp.Position - player1Hrp.Position
	local distance = direction.Magnitude

	if distance < 0.1 then
		return false
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local filterList = {}
	local char1 = player1Hrp.Parent
	local char2 = player2Hrp.Parent
	if char1 then table.insert(filterList, char1) end
	if char2 then table.insert(filterList, char2) end
	raycastParams:AddToFilter(filterList)

	local hit = workspace:Raycast(player1Hrp.Position, direction.Unit * distance, raycastParams)
	return hit ~= nil
end

----------------------------------------------------------------
-- TEAM DETECTION
----------------------------------------------------------------
local function strLower(s)
	return tostring(s):lower()
end

local function matchesHints(str, hints)
	local s = strLower(str)
	for _, h in ipairs(hints) do
		if s:find(h, 1, true) then
			return true
		end
	end
	return false
end

local function hashColor(str)
	local h = 0
	for i = 1, #str do
		h = (h * 31 + str:byte(i)) % 360
	end
	return Color3.fromHSV(h / 360, 0.75, 1)
end

local function csgoTeamColor(name)
	if matchesHints(name, CT_HINTS) then return CT_COLOR end
	if matchesHints(name, T_HINTS) then return T_COLOR end

	local t = Teams:FindFirstChild(name)
	if t and t:IsA("Team") then
		return t.TeamColor.Color
	end

	return hashColor(name)
end

local function detect(player)
	if player.Team then
		return player.Team.Name, csgoTeamColor(player.Team.Name), "Teams service"
	end

	for _, holder in ipairs({player, player.Character or Instance.new("Folder")}) do
		for k, v in pairs(holder:GetAttributes()) do
			local ks = strLower(k)
			if ks:find("team") or ks:find("side") or ks:find("faction") then
				local name = tostring(v)
				return name, csgoTeamColor(name), "attribute '" .. k .. "'"
			end
		end
	end

	for _, holder in ipairs({player, player.Character or Instance.new("Folder")}) do
		for _, child in ipairs(holder:GetChildren()) do
			if child:IsA("ValueBase") then
				local cn = strLower(child.Name)
				if cn == "team" or cn == "side" or cn == "faction" then
					local name = tostring(child.Value)
					return name, csgoTeamColor(name), "value '" .. child.Name .. "'"
				end
			end
		end
	end

	local char = player.Character
	if char then
		local hl = char:FindFirstChildOfClass("Highlight")
		if hl then
			local name
			if matchesHints(tostring(hl.Name), CT_HINTS) then
				name = "CounterTerrorist"
			elseif matchesHints(tostring(hl.Name), T_HINTS) then
				name = "Terrorist"
			end
			return name or "Unknown", hl.FillColor, "character Highlight"
		end
	end

	if not player.Neutral then
		return tostring(player.TeamColor), player.TeamColor.Color, "TeamColor"
	end

	return nil, nil, nil
end

local function rescan()
	for _, p in ipairs(Players:GetPlayers()) do
		local ok, n, c, m = pcall(detect, p)
		if ok then
			teamCache[p] = {name = n, color = c, method = m}
		end
	end
end

local function getTeam(player)
	local t = teamCache[player]
	if t then
		return t.name, t.color, t.method
	end
	return nil, nil, nil
end

local function isSameTeam(player)
	local myTeam = getTeam(LocalPlayer)
	local plyTeam = getTeam(player)
	return myTeam ~= nil and plyTeam ~= nil and myTeam == plyTeam
end

local function getDisplayColor(player, hrp)
	local isAlly = isSameTeam(player)
	local myChar = LocalPlayer.Character
	local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local behindWall = myHrp and hrp and isBehindWall(myHrp, hrp)

	if isAlly then
		return behindWall and ALLY_BEHIND_WALL or ALLY_COLOR
	end
	return behindWall and ENEMY_BEHIND_WALL or ENEMY_COLOR
end

----------------------------------------------------------------
-- UTILITIES
----------------------------------------------------------------
local function getWeapon(player)
	local char = player.Character
	if not char then return nil end

	local tool = char:FindFirstChildOfClass("Tool")
	if tool then return tool.Name end

	local bp = player.Backpack
	if bp then
		local t = bp:FindFirstChildOfClass("Tool")
		if t then return t.Name end
	end

	return nil
end

local function getHrp(player)
	local char = player and player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function getDistance(hrp)
	local myHrp = getHrp(LocalPlayer)
	if not myHrp then return nil end
	return math.floor((hrp.Position - myHrp.Position).Magnitude)
end

local function getHealth(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return 0, 100 end
	return hum.Health, hum.MaxHealth
end

-- resolve the target's parts at click time; a cached HumanoidRootPart is a
-- destroyed instance after a respawn, and a dead target lands you in a corpse
local function teleportTo(player)
	if not player then return end
	local hrp = getHrp(player)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local myHrp = getHrp(LocalPlayer)
	if not hrp or not myHrp then return end
	if hum and hum.Health <= 0 then return end
	myHrp.CFrame = hrp.CFrame + Vector3.new(0, state.TELEPORT_HEIGHT, 0)
end

----------------------------------------------------------------
-- GUI HELPERS
----------------------------------------------------------------
local guiParent = (gethui and gethui()) or game:GetService("CoreGui")
if guiParent:FindFirstChild("ESPControlGui") then
	guiParent.ESPControlGui:Destroy()
end

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do
		o[k] = v
	end
	o.Parent = parent
	return o
end

local function round(o, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 6)
	c.Parent = o
end

local gui = mk("ScreenGui", {Name = "ESPControlGui", ResetOnSpawn = false}, guiParent)

local PANEL_W, PANEL_H = 310, 410
local frame = mk("Frame", {
	Size = UDim2.fromOffset(PANEL_W, PANEL_H),
	Position = UDim2.fromOffset(20, 80),
	BackgroundColor3 = COLORS.Frame,
	Active = false, -- stays false so the list below can take the mouse wheel
	Draggable = true,
}, gui)
round(frame, 8)

local titleBar = mk("Frame", {
	Size = UDim2.new(1, 0, 0, 28),
	BackgroundColor3 = COLORS.TitleBar,
	Active = true, -- the only element that needs Active, for dragging
}, frame)
round(titleBar, 8)

mk("TextLabel", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Text = "CS:GO ESP + Teleport  |  Insert = menu",
	TextColor3 = COLORS.Text,
	Font = Enum.Font.GothamBold,
	TextSize = 12,
}, titleBar)

local function button(text, x, y, w, h, color)
	local b = mk("TextButton", {
		Size = UDim2.fromOffset(w, h),
		Position = UDim2.fromOffset(x, y),
		BackgroundColor3 = color,
		TextColor3 = COLORS.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		Text = text,
		AutoButtonColor = true,
	}, frame)
	round(b, 5)
	return b
end

----------------------------------------------------------------
-- GUI: TOP ROW
----------------------------------------------------------------
local toggleBtn = button("ESP: ON", 10, 34, 88, 26, COLORS.On)
local teamBtn = button("Hide Allies: OFF", 104, 34, 110, 26, COLORS.Neutral)
local killBtn = button("UNLOAD", 220, 34, 80, 26, COLORS.Danger)

----------------------------------------------------------------
-- GUI: FEATURE TOGGLES
----------------------------------------------------------------
local function featureToggle(label, key, x, y)
	local b = mk("TextButton", {
		Size = UDim2.fromOffset(140, 22),
		Position = UDim2.fromOffset(x, y),
		BackgroundColor3 = state[key] and COLORS.On or COLORS.Off,
		TextColor3 = COLORS.Text,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		Text = label .. ": " .. (state[key] and "ON" or "OFF"),
		AutoButtonColor = true,
	}, frame)
	round(b, 4)

	b.MouseButton1Click:Connect(function()
		state[key] = not state[key]
		b.BackgroundColor3 = state[key] and COLORS.On or COLORS.Off
		b.Text = label .. ": " .. (state[key] and "ON" or "OFF")
	end)
	return b
end

local featureY = 66
featureToggle("Box", "BOX_ON", 10, featureY)
featureToggle("Skeleton", "SKELETON_ON", 158, featureY)
featureToggle("Tracer", "TRACER_ON", 10, featureY + 26)
featureToggle("Health Bar", "HEALTHBAR_ON", 158, featureY + 26)
featureToggle("Name", "NAME_ON", 10, featureY + 52)
featureToggle("Distance", "DISTANCE_ON", 158, featureY + 52)
featureToggle("Weapon", "WEAPON_ON", 10, featureY + 78)
featureToggle("Team Name", "SHOW_TEAM_NAME", 158, featureY + 78)

----------------------------------------------------------------
-- GUI: PLAYER LIST
----------------------------------------------------------------
local list = mk("ScrollingFrame", {
	Size = UDim2.new(1, -20, 0, 110),
	Position = UDim2.fromOffset(10, 178),
	BackgroundColor3 = COLORS.List,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = Color3.fromRGB(120, 120, 120),
	VerticalScrollBarInset = Enum.ScrollBarInset.None,
	ScrollingEnabled = true,
	Active = true,
	CanvasSize = UDim2.fromOffset(0, 0),
}, frame)
round(list, 6)
local layout = mk("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.Name}, list)

local selLabel = mk("TextLabel", {
	Size = UDim2.new(1, -20, 0, 18),
	Position = UDim2.fromOffset(10, 294),
	BackgroundTransparency = 1,
	Text = "Select a player: recolor their ESP, or teleport to them",
	TextColor3 = COLORS.Muted,
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd,
}, frame)

----------------------------------------------------------------
-- GUI: COLOR TARGET + SWATCHES
----------------------------------------------------------------
local targetBtns = {}
local function setTarget(t)
	target = t
	for name, b in pairs(targetBtns) do
		b.BackgroundColor3 = (name == t) and COLORS.Accent or COLORS.Button
	end
end

for i, name in ipairs({"Box", "Skeleton", "Tracer", "All"}) do
	local b = button(name, 10 + (i - 1) * 72, 316, 68, 22, COLORS.Button)
	targetBtns[name] = b
	b.MouseButton1Click:Connect(function()
		setTarget(name)
	end)
end
setTarget("All")

local function applyColor(color)
	if not selected then return end
	local ov = overrides[selected] or {}
	if target == "Box" or target == "All" then ov.box = color end
	if target == "Skeleton" or target == "All" then ov.skel = color end
	if target == "Tracer" or target == "All" then ov.tracer = color end
	overrides[selected] = ov
end

local SWATCHES = {
	Color3.fromRGB(255,50,50),   Color3.fromRGB(255,140,0),  Color3.fromRGB(255,230,0),
	Color3.fromRGB(0,220,60),    Color3.fromRGB(100,180,255),Color3.fromRGB(0,60,255),
	Color3.fromRGB(170,0,255),   Color3.fromRGB(255,80,200), Color3.fromRGB(255,255,255),
}

for i, c in ipairs(SWATCHES) do
	local s = button("", 10 + (i - 1) * 29, 344, 25, 22, c)
	s.MouseButton1Click:Connect(function()
		applyColor(c)
	end)
end

----------------------------------------------------------------
-- GUI: TELEPORT + RESET (bottom row, below the swatches)
----------------------------------------------------------------
local tpBtn = button("TELEPORT to Selected", 10, 372, 200, 26, COLORS.Health)
local resetBtn = button("Reset Color", 216, 372, 84, 26, Color3.fromRGB(80, 50, 50))

tpBtn.MouseButton1Click:Connect(function()
	teleportTo(selected)
end)

resetBtn.MouseButton1Click:Connect(function()
	if selected then
		overrides[selected] = nil
	end
end)

----------------------------------------------------------------
-- GUI: LIST + VISIBILITY STATE
----------------------------------------------------------------
local function setVisible(v)
	visible = v
	toggleBtn.Text = visible and "ESP: ON" or "ESP: OFF"
	toggleBtn.BackgroundColor3 = visible and COLORS.On or Color3.fromRGB(200, 50, 50)
end

local function setHideTeam(v)
	state.HIDE_TEAMMATES = v
	teamBtn.Text = v and "Hide Allies: ON" or "Hide Allies: OFF"
	teamBtn.BackgroundColor3 = v and COLORS.Accent or COLORS.Neutral
end

local function refreshList()
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local teamName = getTeam(p)
			local hp, maxHp = getHealth(p)
			local hpPct = maxHp > 0 and math.floor((hp / maxHp) * 100) or 0
			local weapon = getWeapon(p)
			local displayCol = isSameTeam(p) and ALLY_COLOR or ENEMY_COLOR

			local row = mk("TextButton", {
				Name = p.Name:lower(),
				Size = UDim2.new(1, -6, 0, 24),
				BackgroundColor3 = (p == selected) and COLORS.RowSelected or COLORS.Row,
				TextColor3 = displayCol,
				Font = Enum.Font.Gotham,
				TextSize = 11,
				Text = ("  %s  [%s]  %d HP%s"):format(
					p.DisplayName,
					teamName or "?",
					hpPct,
					weapon and ("  " .. weapon) or ""
				),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, list)
			round(row, 4)

			row.MouseButton1Click:Connect(function()
				selected = p
				local _, _, mth = getTeam(p)
				selLabel.Text = "Selected: " .. p.DisplayName .. "  (via: " .. (mth or "unknown") .. ")"
				refreshList()
			end)
		end
	end

	list.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 4)
end

----------------------------------------------------------------
-- ESP DRAWING
----------------------------------------------------------------
local function newLine()
	local l = Drawing.new("Line")
	l.Thickness = 1.5
	l.Color = DEFAULT_COLOR
	l.Visible = false
	return l
end

local function newText()
	local t = Drawing.new("Text")
	t.Size = 14
	t.Center = true
	t.Outline = true
	t.Color = DEFAULT_COLOR
	t.Visible = false
	return t
end

local function create(player)
	if player == LocalPlayer or objects[player] then return end

	local box = Drawing.new("Square")
	box.Thickness = 1.5
	box.Filled = false
	box.Color = DEFAULT_COLOR
	box.Visible = false

	local hbBg = Drawing.new("Square")
	hbBg.Thickness = 1
	hbBg.Filled = true
	hbBg.Color = Color3.fromRGB(0, 0, 0)
	hbBg.Transparency = 0.5
	hbBg.Visible = false

	local hbFill = Drawing.new("Square")
	hbFill.Thickness = 1
	hbFill.Filled = true
	hbFill.Color = Color3.fromRGB(0, 255, 0)
	hbFill.Visible = false

	local nameText = newText()
	local distText = newText()
	local weaponText = newText()
	nameText.Size = 13

	local lines = {}
	for i = 1, #R15_BONES do
		lines[i] = newLine()
	end

	objects[player] = {
		box = box,
		hbBg = hbBg,
		hbFill = hbFill,
		name = nameText,
		dist = distText,
		weapon = weaponText,
		tracer = newLine(),
		lines = lines,
	}
end

local function remove(player)
	local o = objects[player]
	if o then
		o.box:Remove()
		o.hbBg:Remove()
		o.hbFill:Remove()
		o.name:Remove()
		o.dist:Remove()
		o.weapon:Remove()
		o.tracer:Remove()
		for _, l in ipairs(o.lines) do
			l:Remove()
		end
		objects[player] = nil
	end

	overrides[player] = nil
	teamCache[player] = nil

	if selected == player then
		selected = nil
		selLabel.Text = "Select a player: recolor their ESP, or teleport to them"
	end
end

local function hideAll(o)
	o.box.Visible = false
	o.hbBg.Visible = false
	o.hbFill.Visible = false
	o.name.Visible = false
	o.dist.Visible = false
	o.weapon.Visible = false
	o.tracer.Visible = false
	for _, l in ipairs(o.lines) do
		l.Visible = false
	end
end

local function toScreen(part)
	local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
	return Vector2.new(pos.X, pos.Y), onScreen and pos.Z > 0
end

local function healthColor(pct)
	if pct >= 0.5 then
		return Color3.new(1 - (pct - 0.5) * 2, 1, 0)
	end
	return Color3.new(1, pct * 2, 0)
end

local function update()
	if killed then return end

	Camera = workspace.CurrentCamera
	local center = Camera.ViewportSize / 2

	for player, o in pairs(objects) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")

		if not visible or not hrp or not hum or hum.Health <= 0
			or (state.HIDE_TEAMMATES and isSameTeam(player)) then
			hideAll(o)
		else
			local rootPos, onScreen = toScreen(hrp)
			if not onScreen then
				hideAll(o)
			else
				local col = getDisplayColor(player, hrp)
				local ov = overrides[player] or {}
				local boxColor = ov.box or col
				local skelColor = ov.skel or col
				local tracerColor = ov.tracer or col

				local topSc = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3.2, 0))
				local bottomSc = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.2, 0))
				local height = math.abs(bottomSc.Y - topSc.Y)
				local width = height * 0.55
				local left = topSc.X - width / 2
				local top = topSc.Y

				o.box.Visible = state.BOX_ON
				o.box.Color = boxColor
				o.box.Size = Vector2.new(width, height)
				o.box.Position = Vector2.new(left, top)

				local hp, maxHp = getHealth(player)
				local hpPct = maxHp > 0 and (hp / maxHp) or 0
				local barW = 4
				local barH = height

				o.hbBg.Visible = state.HEALTHBAR_ON
				o.hbBg.Size = Vector2.new(barW, barH)
				o.hbBg.Position = Vector2.new(left - barW - 2, top)

				o.hbFill.Visible = state.HEALTHBAR_ON
				o.hbFill.Color = healthColor(hpPct)
				o.hbFill.Size = Vector2.new(barW, barH * hpPct)
				o.hbFill.Position = Vector2.new(left - barW - 2, top + barH * (1 - hpPct))

				local teamName = getTeam(player)
				local nameStr = player.DisplayName
				if state.SHOW_TEAM_NAME and teamName then
					nameStr = nameStr .. " [" .. teamName .. "]"
				end

				o.name.Visible = state.NAME_ON
				o.name.Color = col
				o.name.Text = nameStr
				o.name.Position = Vector2.new(topSc.X, top - 18)

				local dist = getDistance(hrp)
				o.dist.Visible = state.DISTANCE_ON and dist ~= nil
				o.dist.Color = COLORS.Distance
				o.dist.Size = 11
				o.dist.Text = dist and (dist .. "m") or ""
				o.dist.Position = Vector2.new(topSc.X, top - 30)

				local wpn = getWeapon(player)
				o.weapon.Visible = state.WEAPON_ON and wpn ~= nil
				o.weapon.Color = COLORS.Weapon
				o.weapon.Size = 11
				o.weapon.Text = wpn or ""
				o.weapon.Position = Vector2.new(topSc.X, bottomSc.Y + 4)

				local head = char:FindFirstChild("Head")
				local headPos = head and select(1, toScreen(head)) or rootPos
				o.tracer.Visible = state.TRACER_ON
				o.tracer.Color = tracerColor
				o.tracer.From = center
				o.tracer.To = headPos

				local bones = hum.RigType == Enum.HumanoidRigType.R15 and R15_BONES or R6_BONES
				for i, line in ipairs(o.lines) do
					local bone = bones[i]
					local a = bone and char:FindFirstChild(bone[1])
					local b = bone and char:FindFirstChild(bone[2])
					if state.SKELETON_ON and a and b then
						local p1, v1 = toScreen(a)
						local p2, v2 = toScreen(b)
						line.Color = skelColor
						line.From = p1
						line.To = p2
						line.Visible = v1 and v2
					else
						line.Visible = false
					end
				end
			end
		end
	end
end

----------------------------------------------------------------
-- CONNECTIONS + UNLOAD
----------------------------------------------------------------
local conns = {}

local function kill()
	if killed then return end
	killed = true

	for _, c in ipairs(conns) do
		c:Disconnect()
	end

	for p in pairs(objects) do
		remove(p)
	end

	gui:Destroy()
	getgenv().ESP_Unload = nil
end

rescan()
for _, p in ipairs(Players:GetPlayers()) do
	create(p)
	local n, _, m = getTeam(p)
	print(("[ESP+TP] %s -> %s (via: %s)"):format(p.Name, n or "none", m or "not found"))
end
refreshList()

table.insert(conns, Players.PlayerAdded:Connect(function(p)
	create(p)
	rescan()
	refreshList()
end))

table.insert(conns, Players.PlayerRemoving:Connect(function(p)
	remove(p)
	task.defer(refreshList)
end))

table.insert(conns, RunService.RenderStepped:Connect(update))

table.insert(conns, toggleBtn.MouseButton1Click:Connect(function()
	setVisible(not visible)
end))

table.insert(conns, teamBtn.MouseButton1Click:Connect(function()
	setHideTeam(not state.HIDE_TEAMMATES)
end))

table.insert(conns, killBtn.MouseButton1Click:Connect(kill))

table.insert(conns, UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	if input.KeyCode == state.TOGGLE_KEY then
		setVisible(not visible)
	elseif input.KeyCode == state.MENU_KEY then
		frame.Visible = not frame.Visible
	elseif input.KeyCode == state.KILL_KEY then
		kill()
	end
end))

task.spawn(function()
	while not killed do
		task.wait(2)
		if killed then break end
		rescan()
		if frame.Visible then
			refreshList()
		end
	end
end)

getgenv().ESP_Unload = kill