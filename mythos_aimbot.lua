if _G.MYTHOS_AIMBOT_LOADED then
	return
end

local Players = Players or game:GetService("Players")
local RunService = RunService or game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local localPlayer = Players.LocalPlayer

local coreOk, CoreGui = pcall(function()
	return game:GetService("CoreGui")
end)
if not coreOk then
	CoreGui = nil
end

local _notify = notify or function(a, b)
	print("[Mythos Aim] " .. tostring(a) .. ": " .. tostring(b))
end

local _addcmd = addcmd or function() end

local CONFIG_FILE = "mythos_aimbot.json"

local COLORS = {
	{ name = "Red", color = Color3.fromRGB(255, 60, 60) },
	{ name = "Green", color = Color3.fromRGB(80, 220, 120) },
	{ name = "Cyan", color = Color3.fromRGB(70, 200, 255) },
	{ name = "White", color = Color3.fromRGB(240, 240, 240) },
	{ name = "Purple", color = Color3.fromRGB(190, 110, 255) },
}

local DEFAULTS = {
	enabled = false,
	fov = 180,
	smooth = 0.18,
	part = "Head",
	maxDist = 300,
	prediction = 0,
	visibleOnly = false,
	teamCheck = false,
	showCircle = true,
	activation = "Toggle",
	key = "G",
	color = 1,
	thickness = 1.5,
}

local cfg = {}
for k, v in pairs(DEFAULTS) do
	cfg[k] = v
end

local state = {
	conn = nil,
	circle = nil,
	gui = nil,
	visible = false,
	keyDown = false,
	capturing = false,
	targetName = "none",
	status = nil,
	statusClock = 0,
}

local refreshers = {}

local function refreshAll()
	for _, fn in ipairs(refreshers) do
		pcall(fn)
	end
end

local function saveConfig()
	if not writefile then
		return
	end
	local ok, data = pcall(function()
		return HttpService:JSONEncode(cfg)
	end)
	if ok and data then
		pcall(writefile, CONFIG_FILE, data)
	end
end

local saveToken = 0
local function saveConfigSoon()
	saveToken = saveToken + 1
	local token = saveToken
	task.delay(0.25, function()
		if token == saveToken then
			saveConfig()
		end
	end)
end

local function loadConfig()
	if not (readfile and isfile) then
		return
	end
	local ok, exists = pcall(isfile, CONFIG_FILE)
	if not ok or not exists then
		return
	end
	local ok2, data = pcall(readfile, CONFIG_FILE)
	if not ok2 or type(data) ~= "string" then
		return
	end
	local ok3, decoded = pcall(function()
		return HttpService:JSONDecode(data)
	end)
	if not ok3 or type(decoded) ~= "table" then
		return
	end
	for k, v in pairs(DEFAULTS) do
		if k ~= "enabled" and type(decoded[k]) == type(v) then
			cfg[k] = decoded[k]
		end
	end
	if type(cfg.color) ~= "number" or cfg.color < 1 or cfg.color > #COLORS then
		cfg.color = 1
	end
	if cfg.activation ~= "Toggle" and cfg.activation ~= "Hold" then
		cfg.activation = "Toggle"
	end
	if cfg.part ~= "Head" and cfg.part ~= "Torso" and cfg.part ~= "Nearest" then
		cfg.part = "Head"
	end
	if type(cfg.key) ~= "string" or cfg.key == "" then
		cfg.key = "G"
	end
	cfg.enabled = false
end

loadConfig()

local function isTyping()
	return UIS:GetFocusedTextBox() ~= nil
end

local function isTeammate(plr)
	if not cfg.teamCheck then
		return false
	end
	local team = localPlayer.Team
	return team ~= nil and plr.Team == team
end

local function targetPos(part)
	local pos = part.Position
	if cfg.prediction > 0 then
		local ok, vel = pcall(function()
			return part.AssemblyLinearVelocity
		end)
		if ok and vel then
			pos = pos + vel * (cfg.prediction * 0.12)
		end
	end
	return pos
end

local function isVisible(part)
	local cam = workspace.CurrentCamera
	if not cam then
		return true
	end
	local own = localPlayer.Character
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = own and { own } or {}
	local result = workspace:Raycast(cam.CFrame.Position, part.Position - cam.CFrame.Position, params)
	if result and result.Instance then
		local char = part.Parent
		return char ~= nil and result.Instance:IsDescendantOf(char)
	end
	return true
end

local function getTarget(cam)
	local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
	local bestPart, bestPos, bestDist = nil, nil, cfg.fov
	local own = localPlayer.Character

	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		if plr ~= localPlayer and char and char ~= own and not isTeammate(plr) then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				local parts = {}
				if cfg.part == "Nearest" then
					local head = char:FindFirstChild("Head")
					local root = char:FindFirstChild("HumanoidRootPart")
					if head then
						parts[#parts + 1] = head
					end
					if root then
						parts[#parts + 1] = root
					end
				else
					local name = cfg.part == "Torso" and "HumanoidRootPart" or "Head"
					local part = char:FindFirstChild(name) or char:FindFirstChild("HumanoidRootPart")
					if part then
						parts[1] = part
					end
				end

				for _, part in ipairs(parts) do
					local pos = targetPos(part)
					if (pos - cam.CFrame.Position).Magnitude <= cfg.maxDist then
						local sp, onScreen = cam:WorldToViewportPoint(pos)
						if onScreen and sp.Z > 0 then
							local dx, dy = sp.X - center.X, sp.Y - center.Y
							local dist = math.sqrt(dx * dx + dy * dy)
							if dist < bestDist then
								bestDist, bestPart, bestPos = dist, part, pos
							end
						end
					end
				end
			end
		end
	end

	if bestPart and cfg.visibleOnly and not isVisible(bestPart) then
		return nil
	end
	return bestPart, bestPos
end

local function ensureCircle()
	if state.circle or not Drawing then
		return
	end
	local ok, circle = pcall(function()
		return Drawing.new("Circle")
	end)
	if ok and circle then
		circle.NumSides = 64
		circle.Filled = false
		circle.Transparency = 0.55
		state.circle = circle
	end
end

local function updateCircle(cam)
	if not cfg.showCircle or not cfg.enabled then
		if state.circle then
			state.circle.Visible = false
		end
		return
	end
	ensureCircle()
	if state.circle then
		local col = COLORS[cfg.color] or COLORS[1]
		state.circle.Visible = true
		state.circle.Thickness = cfg.thickness
		state.circle.Radius = cfg.fov
		state.circle.Position = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
		state.circle.Color = col.color
	end
end

local function isActive()
	if not cfg.enabled then
		return false
	end
	if cfg.activation == "Hold" then
		return state.keyDown
	end
	return true
end

local function onRender()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	updateCircle(cam)

	if not isActive() then
		state.targetName = "none"
	else
		local part, pos = getTarget(cam)
		if part and pos then
			state.targetName = part.Parent and part.Parent.Name or "target"
			if (pos - cam.CFrame.Position).Magnitude > 1 then
				cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, pos), math.clamp(cfg.smooth, 0.01, 1))
			end
		else
			state.targetName = "none"
		end
	end

	if state.status and state.status.Parent then
		local now = os.clock()
		if now - state.statusClock >= 0.1 then
			state.statusClock = now
			local active = isActive()
			state.status.Text = "Target: " .. state.targetName .. "  |  " .. (active and "ACTIVE" or "IDLE")
			state.status.TextColor3 = active and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(150, 150, 160)
		end
	end
end

local function syncConnection()
	if cfg.enabled then
		if not state.conn then
			state.conn = RunService.RenderStepped:Connect(function()
				pcall(onRender)
			end)
		end
	else
		if state.conn then
			state.conn:Disconnect()
			state.conn = nil
		end
		if state.circle then
			state.circle.Visible = false
		end
	end
end

local function setEnabled(on)
	cfg.enabled = on and true or false
	syncConnection()
	saveConfig()
	refreshAll()
	_notify("Aimbot", cfg.enabled and ("ON (" .. cfg.activation .. ")") or "OFF")
end

local UI = {
	bg = Color3.fromRGB(26, 26, 30),
	title = Color3.fromRGB(18, 18, 21),
	text = Color3.fromRGB(235, 235, 240),
	muted = Color3.fromRGB(150, 150, 160),
	accent = Color3.fromRGB(220, 60, 60),
	on = Color3.fromRGB(70, 180, 100),
	off = Color3.fromRGB(60, 60, 68),
	track = Color3.fromRGB(50, 50, 58),
}

local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(inst, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = inst
	return c
end

local layoutOrder = 0
local function nextOrder()
	layoutOrder = layoutOrder + 1
	return layoutOrder
end

local function makeSection(parent, text)
	return new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = UI.accent,
		Text = string.upper(text),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = nextOrder(),
	}, parent)
end

local function makeToggle(parent, label, getter, setter)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, parent)

	new("TextLabel", {
		Size = UDim2.new(1, -64, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = UI.text,
		Text = label,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local btn = new("TextButton", {
		Size = UDim2.new(0, 54, 0, 22),
		Position = UDim2.new(1, -54, 0.5, -11),
		BackgroundColor3 = UI.off,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = UI.text,
		Text = "OFF",
		AutoButtonColor = false,
	}, row)
	corner(btn, 5)

	local function refresh()
		local on = getter()
		btn.Text = on and "ON" or "OFF"
		btn.BackgroundColor3 = on and UI.on or UI.off
	end

	btn.MouseButton1Click:Connect(function()
		setter(not getter())
		refresh()
	end)
	refresh()
	refreshers[#refreshers + 1] = refresh
	return row
end

local function makeSlider(parent, label, min, max, step, getter, setter, format)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, parent)

	new("TextLabel", {
		Size = UDim2.new(1, -70, 0, 18),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = UI.text,
		Text = label,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local val = new("TextLabel", {
		Size = UDim2.new(0, 70, 0, 18),
		Position = UDim2.new(1, -70, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = UI.muted,
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Right,
	}, row)

	local track = new("Frame", {
		Size = UDim2.new(1, 0, 0, 5),
		Position = UDim2.new(0, 0, 1, -9),
		BackgroundColor3 = UI.track,
		BorderSizePixel = 0,
	}, row)
	corner(track, 3)

	local fill = new("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = UI.accent,
		BorderSizePixel = 0,
	}, track)
	corner(fill, 3)

	local knob = new("Frame", {
		Size = UDim2.new(0, 12, 0, 12),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = UI.text,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, track)
	corner(knob, 6)

	local function refresh()
		local v = getter()
		local rel = math.clamp((v - min) / (max - min), 0, 1)
		fill.Size = UDim2.new(rel, 0, 1, 0)
		knob.Position = UDim2.new(rel, 0, 0.5, 0)
		val.Text = format and format(v) or tostring(v)
	end

	local dragging = false
	local function apply(x)
		local rel = 0
		if track.AbsoluteSize.X > 0 then
			rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		end
		local v = min + (max - min) * rel
		if step then
			v = math.floor(v / step + 0.5) * step
		end
		v = math.clamp(v, min, max)
		setter(v)
		refresh()
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			apply(input.Position.X)
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			apply(input.Position.X)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	refresh()
	refreshers[#refreshers + 1] = refresh
	return row
end

local function makeCycle(parent, label, options, getter, setter, toText)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, parent)

	new("TextLabel", {
		Size = UDim2.new(1, -104, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = UI.text,
		Text = label,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local btn = new("TextButton", {
		Size = UDim2.new(0, 96, 0, 22),
		Position = UDim2.new(1, -96, 0.5, -11),
		BackgroundColor3 = UI.off,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = UI.text,
		Text = "",
		AutoButtonColor = false,
	}, row)
	corner(btn, 5)

	local display = toText or tostring

	local function refresh()
		btn.Text = display(getter())
	end

	btn.MouseButton1Click:Connect(function()
		local current = getter()
		local idx = 1
		for i = 1, #options do
			if options[i] == current then
				idx = i
				break
			end
		end
		idx = idx % #options + 1
		setter(options[idx])
		refresh()
	end)

	refresh()
	refreshers[#refreshers + 1] = refresh
	return row
end

local function makeKeybind(parent)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, parent)

	new("TextLabel", {
		Size = UDim2.new(1, -104, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = UI.text,
		Text = "Aim key",
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local btn = new("TextButton", {
		Size = UDim2.new(0, 96, 0, 22),
		Position = UDim2.new(1, -96, 0.5, -11),
		BackgroundColor3 = UI.off,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = UI.text,
		Text = cfg.key,
		AutoButtonColor = false,
	}, row)
	corner(btn, 5)

	btn.MouseButton1Click:Connect(function()
		state.capturing = true
		state.keyDown = false
		btn.Text = "PRESS..."
		btn.BackgroundColor3 = UI.accent
		task.delay(5, function()
			if state.capturing then
				state.capturing = false
				refreshAll()
			end
		end)
	end)

	refreshers[#refreshers + 1] = function()
		if not state.capturing then
			btn.Text = cfg.key
			btn.BackgroundColor3 = UI.off
		end
	end
	return row
end

local function resetConfig()
	for k, v in pairs(DEFAULTS) do
		cfg[k] = v
	end
	syncConnection()
	saveConfig()
	refreshAll()
	_notify("Aimbot", "Defaults restored")
end

local function buildGui()
	if state.gui and state.gui.Parent then
		return state.gui
	end

	refreshers = {}
	layoutOrder = 0

	local screen = Instance.new("ScreenGui")
	screen.Name = "MythosAimGui"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Enabled = false

	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(screen)
		end
	end)

	if CoreGui then
		pcall(function()
			screen.Parent = CoreGui
		end)
	end
	if not screen.Parent then
		screen.Parent = localPlayer:WaitForChild("PlayerGui")
	end

	local main = new("Frame", {
		Name = "Main",
		Size = UDim2.new(0, 320, 0, 520),
		Position = UDim2.new(0.5, -160, 0.5, -260),
		BackgroundColor3 = UI.bg,
		BorderSizePixel = 0,
		Active = true,
	}, screen)
	corner(main, 8)

	local title = new("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = UI.title,
		BorderSizePixel = 0,
	}, main)
	corner(title, 8)

	new("Frame", {
		Size = UDim2.new(0, 3, 1, -12),
		Position = UDim2.new(0, 10, 0, 6),
		BackgroundColor3 = UI.accent,
		BorderSizePixel = 0,
	}, title)

	new("TextLabel", {
		Size = UDim2.new(1, -96, 1, 0),
		Position = UDim2.new(0, 20, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = UI.text,
		Text = "MYTHOS // AIMBOT",
		TextXAlignment = Enum.TextXAlignment.Left,
	}, title)

	local minBtn = new("TextButton", {
		Size = UDim2.new(0, 24, 0, 24),
		Position = UDim2.new(1, -54, 0.5, -12),
		BackgroundColor3 = UI.off,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = UI.text,
		Text = "-",
		AutoButtonColor = false,
	}, title)
	corner(minBtn, 5)

	local closeBtn = new("TextButton", {
		Size = UDim2.new(0, 24, 0, 24),
		Position = UDim2.new(1, -28, 0.5, -12),
		BackgroundColor3 = UI.accent,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = UI.text,
		Text = "X",
		AutoButtonColor = false,
	}, title)
	corner(closeBtn, 5)

	local body = new("ScrollingFrame", {
		Name = "Body",
		Size = UDim2.new(1, -16, 1, -44),
		Position = UDim2.new(0, 8, 0, 38),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = UI.accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, main)

	new("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, body)

	new("UIPadding", {
		PaddingTop = UDim.new(0, 2),
		PaddingBottom = UDim.new(0, 10),
	}, body)

	makeSection(body, "Targeting")

	makeToggle(body, "Enabled", function()
		return cfg.enabled
	end, function(v)
		setEnabled(v)
	end)

	makeKeybind(body)

	makeCycle(body, "Activation", { "Toggle", "Hold" }, function()
		return cfg.activation
	end, function(v)
		cfg.activation = v
		saveConfig()
	end)

	makeCycle(body, "Target part", { "Head", "Torso", "Nearest" }, function()
		return cfg.part
	end, function(v)
		cfg.part = v
		saveConfig()
	end)

	makeSlider(body, "FOV radius", 10, 800, 1, function()
		return cfg.fov
	end, function(v)
		cfg.fov = v
		saveConfigSoon()
	end, function(v)
		return tostring(math.floor(v + 0.5))
	end)

	makeSlider(body, "Max distance", 10, 1500, 10, function()
		return cfg.maxDist
	end, function(v)
		cfg.maxDist = v
		saveConfigSoon()
	end, function(v)
		return tostring(math.floor(v + 0.5))
	end)

	makeToggle(body, "Visible only", function()
		return cfg.visibleOnly
	end, function(v)
		cfg.visibleOnly = v
		saveConfig()
	end)

	makeToggle(body, "Team check", function()
		return cfg.teamCheck
	end, function(v)
		cfg.teamCheck = v
		saveConfig()
	end)

	makeSection(body, "Aim behavior")

	makeSlider(body, "Smoothness", 0.01, 1, 0.01, function()
		return cfg.smooth
	end, function(v)
		cfg.smooth = v
		saveConfigSoon()
	end, function(v)
		return string.format("%.2f", v)
	end)

	makeSlider(body, "Prediction", 0, 1, 0.01, function()
		return cfg.prediction
	end, function(v)
		cfg.prediction = v
		saveConfigSoon()
	end, function(v)
		return string.format("%.2f", v)
	end)

	makeSection(body, "Visuals")

	makeToggle(body, "FOV circle", function()
		return cfg.showCircle
	end, function(v)
		cfg.showCircle = v
		if not v and state.circle then
			state.circle.Visible = false
		end
		saveConfig()
	end)

	makeCycle(body, "Circle color", { 1, 2, 3, 4, 5 }, function()
		return cfg.color
	end, function(v)
		cfg.color = v
		saveConfig()
	end, function(v)
		return COLORS[v] and COLORS[v].name or "?"
	end)

	makeSlider(body, "Circle thickness", 1, 5, 0.5, function()
		return cfg.thickness
	end, function(v)
		cfg.thickness = v
		saveConfigSoon()
	end, function(v)
		return string.format("%.1f", v)
	end)

	makeSection(body, "Status")

	local status = new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = UI.muted,
		Text = "Target: none  |  IDLE",
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = nextOrder(),
	}, body)
	state.status = status

	refreshers[#refreshers + 1] = function()
		local active = isActive()
		status.Text = "Target: " .. state.targetName .. "  |  " .. (active and "ACTIVE" or "IDLE")
		status.TextColor3 = active and UI.on or UI.muted
	end

	local resetBtn = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = Color3.fromRGB(60, 40, 44),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = UI.text,
		Text = "RESET DEFAULTS",
		AutoButtonColor = false,
		LayoutOrder = nextOrder(),
	}, body)
	corner(resetBtn, 5)
	resetBtn.MouseButton1Click:Connect(resetConfig)

	local dragStart, startPos
	local dragging = false

	title.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	local normalSize = UDim2.new(0, 320, 0, 520)
	local minimized = false

	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		body.Visible = not minimized
		main.Size = minimized and UDim2.new(0, 320, 0, 34) or normalSize
		minBtn.Text = minimized and "+" or "-"
	end)

	closeBtn.MouseButton1Click:Connect(function()
		screen.Enabled = false
		state.visible = false
	end)

	screen.Enabled = false
	state.gui = screen
	return screen
end

local function showGui()
	local screen = buildGui()
	screen.Enabled = true
	state.visible = true
	refreshAll()
end

local function hideGui()
	if state.gui then
		state.gui.Enabled = false
	end
	state.visible = false
end

local function toggleGui()
	if state.gui and state.gui.Parent and state.gui.Enabled then
		hideGui()
	else
		showGui()
	end
end

UIS.InputBegan:Connect(function(input, processed)
	if state.capturing then
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			cfg.key = input.KeyCode.Name
			state.capturing = false
			state.keyDown = false
			saveConfig()
			refreshAll()
			_notify("Aimbot", "Aim key: " .. cfg.key)
		end
		return
	end
	if processed or isTyping() then
		return
	end
	if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name == cfg.key then
		state.keyDown = true
		if cfg.activation == "Toggle" then
			setEnabled(not cfg.enabled)
		end
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name == cfg.key then
		state.keyDown = false
	end
end)

local function arg1(args)
	if type(args) == "table" then
		return args[1]
	end
	return args
end

local function boolArg(args)
	local v = arg1(args)
	if type(v) == "string" then
		v = v:lower()
		if v == "on" or v == "true" or v == "1" or v == "yes" then
			return true
		end
		if v == "off" or v == "false" or v == "0" or v == "no" then
			return false
		end
		return nil
	end
	if type(v) == "boolean" then
		return v
	end
	if type(v) == "number" then
		return v ~= 0
	end
	return nil
end

local function toggleFlag(key, label, args)
	local forced = boolArg(args)
	if forced == nil then
		forced = not cfg[key]
	end
	cfg[key] = forced
	saveConfig()
	refreshAll()
	_notify("Aimbot", label .. ": " .. (forced and "ON" or "OFF"))
end

_addcmd("aimlock", { "aim", "aimbot", "aimassist" }, function(args)
	local forced = boolArg(args)
	if forced == nil then
		forced = not cfg.enabled
	end
	setEnabled(forced)
end)

_addcmd("aimgui", { "aimmenu", "aimsettings", "aimcfg" }, function()
	toggleGui()
end)

_addcmd("aimhide", { "aimclose" }, function()
	hideGui()
end)

_addcmd("aimfov", { "aimradius" }, function(args)
	local n = tonumber(arg1(args))
	if not n then
		_notify("Aimbot", "FOV: " .. tostring(cfg.fov))
		return
	end
	cfg.fov = math.clamp(n, 10, 1000)
	saveConfig()
	refreshAll()
	_notify("Aimbot", "FOV: " .. tostring(cfg.fov))
end)

_addcmd("aimsmooth", { "aimspeed" }, function(args)
	local n = tonumber(arg1(args))
	if not n then
		_notify("Aimbot", "Smoothness: " .. tostring(cfg.smooth))
		return
	end
	cfg.smooth = math.clamp(n, 0.01, 1)
	saveConfig()
	refreshAll()
	_notify("Aimbot", "Smoothness: " .. tostring(cfg.smooth))
end)

_addcmd("aimpart", { "aimtarget" }, function(args)
	local p = tostring(arg1(args) or ""):lower()
	if p == "torso" or p == "body" or p == "hrp" then
		cfg.part = "Torso"
	elseif p == "nearest" then
		cfg.part = "Nearest"
	else
		cfg.part = "Head"
	end
	saveConfig()
	refreshAll()
	_notify("Aimbot", "Target part: " .. cfg.part)
end)

_addcmd("aimdist", { "aimdistance" }, function(args)
	local n = tonumber(arg1(args))
	if not n then
		_notify("Aimbot", "Max distance: " .. tostring(cfg.maxDist))
		return
	end
	cfg.maxDist = math.clamp(n, 10, 5000)
	saveConfig()
	refreshAll()
	_notify("Aimbot", "Max distance: " .. tostring(cfg.maxDist))
end)

_addcmd("aimpred", { "aimprediction" }, function(args)
	local n = tonumber(arg1(args))
	if not n then
		_notify("Aimbot", "Prediction: " .. tostring(cfg.prediction))
		return
	end
	cfg.prediction = math.clamp(n, 0, 1)
	saveConfig()
	refreshAll()
	_notify("Aimbot", "Prediction: " .. tostring(cfg.prediction))
end)

_addcmd("aimvis", { "aimvisible", "aimwallcheck" }, function(args)
	toggleFlag("visibleOnly", "Visible only", args)
end)

_addcmd("aimteam", { "aimteamcheck" }, function(args)
	toggleFlag("teamCheck", "Team check", args)
end)

_addcmd("aimcircle", { "aimfovcircle" }, function(args)
	toggleFlag("showCircle", "FOV circle", args)
end)

_addcmd("aimmode", { "aimactivation" }, function(args)
	local v = tostring(arg1(args) or ""):lower()
	if v == "hold" then
		cfg.activation = "Hold"
	elseif v == "toggle" then
		cfg.activation = "Toggle"
	else
		cfg.activation = cfg.activation == "Toggle" and "Hold" or "Toggle"
	end
	saveConfig()
	refreshAll()
	_notify("Aimbot", "Activation: " .. cfg.activation)
end)

_addcmd("aimcolor", { "aimcolour" }, function(args)
	local v = arg1(args)
	local picked = nil
	if type(v) == "number" then
		picked = math.clamp(math.floor(v), 1, #COLORS)
	elseif type(v) == "string" then
		local wanted = v:lower()
		for i, col in ipairs(COLORS) do
			if col.name:lower() == wanted then
				picked = i
				break
			end
		end
	end
	cfg.color = picked or ((cfg.color % #COLORS) + 1)
	saveConfig()
	refreshAll()
	_notify("Aimbot", "Circle color: " .. COLORS[cfg.color].name)
end)

_addcmd("aimkey", {}, function(args)
	local first = arg1(args)
	local k = first and tostring(first):upper() or ""
	if k == "" then
		_notify("Aimbot", "Aim key: " .. cfg.key)
		return
	end
	cfg.key = k
	state.keyDown = false
	saveConfig()
	refreshAll()
	_notify("Aimbot", "Aim key: " .. cfg.key)
end)

_addcmd("aimstatus", { "aiminfo" }, function()
	_notify("Aimbot", string.format("enabled=%s mode=%s fov=%s smooth=%s part=%s dist=%s pred=%s vis=%s team=%s key=%s",
		tostring(cfg.enabled), cfg.activation, tostring(cfg.fov), tostring(cfg.smooth), cfg.part,
		tostring(cfg.maxDist), tostring(cfg.prediction), tostring(cfg.visibleOnly), tostring(cfg.teamCheck), cfg.key))
end)

_addcmd("aimreset", { "aimdefaults" }, function()
	resetConfig()
end)

syncConnection()

if not addcmd then
	showGui()
end

pcall(function()
	local root = getgenv and getgenv() or _G
	root.MythosAimbot = {
		config = cfg,
		setEnabled = setEnabled,
		showGui = showGui,
		hideGui = hideGui,
		toggleGui = toggleGui,
		getTarget = getTarget,
		step = onRender,
	}
end)

_G.MYTHOS_AIMBOT_LOADED = true

_notify("Aimbot", "Loaded. ;aimgui opens settings, ;aimlock toggles")
