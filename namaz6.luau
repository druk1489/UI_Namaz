--==================================================================
-- DEX EXPLORER for Solara (Luau) | PART 6/6 : CONSOLE + SETTINGS
--==================================================================

assert(getgenv().DEX and getgenv().DEX.Loaded and getgenv().DEX.Loaded.Core,
	"[DEX] Сначала запусти PART 1 (Foundation)")

local DEX = getgenv().DEX
DEX.Loaded.Console = true
DEX.Loaded.Settings = true

DEX.Console = DEX.Console or {
	Log = {},
	History = {},
	HistIndex = 0,
	MaxLines = 250,
	HookPrint = true,
}

local RunService = DEX.Services.RunService
local LogService  = DEX.Services.LogService

--==================================================================
-- ============================ CONSOLE =============================
--==================================================================
local consolePage = DEX.addTab("Console", 5)

-- область вывода
local outHolder = DEX.new("Frame", {
	Size = UDim2.new(1, -16, 1, -120),
	Position = UDim2.new(0, 8, 0, 8),
	BackgroundColor3 = DEX.Theme.Panel,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = consolePage,
})
DEX.corner(outHolder, 8)

local outScroll = DEX.makeScroll(outHolder)
DEX.new("UIListLayout", {
	Padding = UDim.new(0, 0),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = outScroll,
})

-- поле ввода кода
local execBox = DEX.new("TextBox", {
	Size = UDim2.new(1, -16, 0, 64),
	Position = UDim2.new(0, 8, 1, -104),
	BackgroundColor3 = DEX.Theme.Panel2,
	Font = Enum.Font.Code,
	PlaceholderText = 'Lua код... напр: print(game.PlaceId)',
	Text = "",
	TextColor3 = DEX.Theme.Text,
	PlaceholderColor3 = DEX.Theme.SubText,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	ClearTextOnFocus = false,
	MultiLine = true,
	BorderSizePixel = 0,
	Parent = consolePage,
})
DEX.corner(execBox, 6)
DEX.new("UIPadding", {
	PaddingLeft = UDim.new(0, 6),
	PaddingTop = UDim.new(0, 4),
	Parent = execBox,
})

-- кнопки
local function consoleButton(text, scaleX, offsetX, width, color)
	local btn = DEX.new("TextButton", {
		Size = UDim2.new(0, width, 0, 26),
		Position = UDim2.new(scaleX, offsetX, 1, -34),
		BackgroundColor3 = color,
		Font = Enum.Font.GothamMedium,
		Text = text,
		TextColor3 = DEX.Theme.Text,
		TextSize = 12,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Parent = consolePage,
	})
	DEX.corner(btn, 6)
	return btn
end

local runBtn      = consoleButton("Run (выполнить)", 0, 8, 130, DEX.Theme.Accent)
local clearOutBtn = consoleButton("Очистить", 0, 144, 80, DEX.Theme.Bad)
local prevBtn     = consoleButton("◀ History", 0, 230, 80, DEX.Theme.Panel2)
local nextBtn     = consoleButton("History ▶", 0, 314, 80, DEX.Theme.Panel2)

-- сниппеты (выпадашка кнопками)
local snipBtn = consoleButton("Сниппеты ▾", 0, 400, 100, DEX.Theme.Panel2)

local SNIPPETS = {
	{ name = "PlaceId / JobId", code = 'print("Place:", game.PlaceId, "Job:", game.JobId)' },
	{ name = "Список игроков", code = 'for _, p in pairs(game.Players:GetPlayers()) do print(p.Name) end' },
	{ name = "Мой пинг", code = 'print(game.Players.LocalPlayer:GetNetworkPing() * 1000, "ms")' },
	{ name = "Кол-во потомков", code = 'print(#game:GetDescendants(), "объектов")' },
	{ name = "Память", code = 'print(gcinfo(), "KB")' },
}

----------------------------------------------------------------
-- РЕНДЕР ВЫВОДА
----------------------------------------------------------------
local function colorForType(mt)
	if mt == Enum.MessageType.MessageError then
		return DEX.Theme.Bad
	elseif mt == Enum.MessageType.MessageWarning then
		return Color3.fromRGB(240, 200, 90)
	elseif mt == Enum.MessageType.MessageInfo then
		return DEX.Theme.Builtin or DEX.Theme.Accent
	end
	return DEX.Theme.Text
end

function DEX.Console.Add(text, messageType)
	local entry = { text = tostring(text), mt = messageType }
	table.insert(DEX.Console.Log, entry)
	while #DEX.Console.Log > DEX.Console.MaxLines do
		table.remove(DEX.Console.Log, 1)
	end
	-- добавляем только одну новую строку для скорости
	local order = #outScroll:GetChildren()
	DEX.new("TextLabel", {
		Size = UDim2.new(1, -10, 0, 16),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		Text = entry.text,
		TextColor3 = colorForType(messageType),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		LayoutOrder = order,
		Parent = outScroll,
	})
	-- обрезаем старые UI-строки
	local kids = outScroll:GetChildren()
	if #kids > DEX.Console.MaxLines + 5 then
		for _, k in ipairs(kids) do
			if k:IsA("TextLabel") and k.LayoutOrder < order - DEX.Console.MaxLines then
				pcall(function() k:Destroy() end)
			end
		end
	end
	-- автоскролл вниз
	task.defer(function()
		pcall(function()
			outScroll.CanvasPosition = Vector2.new(0, outScroll.AbsoluteCanvasSize.Y)
		end)
	end)
end

----------------------------------------------------------------
-- ПЕРЕХВАТ LogService.MessageOut
----------------------------------------------------------------
if LogService then
	DEX.connect(LogService.MessageOut, function(message, messageType)
		DEX.Console.Add(message, messageType)
	end)
end

----------------------------------------------------------------
-- СВОЯ РЕАЛИЗАЦИЯ print/warn ЧЕРЕЗ getgenv()
-- (вывод всё равно ловится MessageOut, дублирования нет —
--  здесь только делегирование оригиналам)
----------------------------------------------------------------
local genv = getgenv()
DEX.Console.OrigPrint = DEX.Console.OrigPrint or genv.print or print
DEX.Console.OrigWarn  = DEX.Console.OrigWarn  or genv.warn  or warn

pcall(function()
	genv.print = function(...)
		DEX.Console.OrigPrint(...)
	end
	genv.warn = function(...)
		DEX.Console.OrigWarn(...)
	end
end)

-- прямые помощники для записи в консоль DEX без зависимости от MessageOut
DEX.print = function(...)
	local parts = {}
	local n = select("#", ...)
	local i = 1
	while i <= n do
		table.insert(parts, tostring((select(i, ...))))
		i = i + 1
	end
	DEX.Console.OrigPrint(...)
end
DEX.warn = DEX.warn or function(...)
	DEX.Console.OrigWarn(...)
end

----------------------------------------------------------------
-- ВЫПОЛНЕНИЕ КОДА
----------------------------------------------------------------
local function execute(code)
	if code == "" then
		return
	end
	table.insert(DEX.Console.History, code)
	DEX.Console.HistIndex = #DEX.Console.History + 1
	DEX.Console.Add(">> " .. string.gsub(code, "\n", " "), Enum.MessageType.MessageInfo)

	task.spawn(function()
		local fn, compErr = nil, nil
		local okComp = pcall(function()
			fn, compErr = loadstring(code)
		end)
		if okComp and fn then
			local okRun, runErr = pcall(fn)
			if not okRun then
				DEX.Console.Add("Ошибка: " .. tostring(runErr), Enum.MessageType.MessageError)
			end
		else
			DEX.Console.Add("Компиляция: " .. tostring(compErr), Enum.MessageType.MessageError)
		end
	end)
end

DEX.connect(runBtn.MouseButton1Click, function()
	execute(execBox.Text)
end)

DEX.connect(clearOutBtn.MouseButton1Click, function()
	DEX.Console.Log = {}
	for _, k in pairs(outScroll:GetChildren()) do
		if k:IsA("TextLabel") then
			pcall(function() k:Destroy() end)
		end
	end
end)

DEX.connect(prevBtn.MouseButton1Click, function()
	if #DEX.Console.History == 0 then
		return
	end
	DEX.Console.HistIndex = math.max(1, DEX.Console.HistIndex - 1)
	execBox.Text = DEX.Console.History[DEX.Console.HistIndex] or ""
end)

DEX.connect(nextBtn.MouseButton1Click, function()
	if #DEX.Console.History == 0 then
		return
	end
	DEX.Console.HistIndex = math.min(#DEX.Console.History, DEX.Console.HistIndex + 1)
	execBox.Text = DEX.Console.History[DEX.Console.HistIndex] or ""
end)

-- меню сниппетов
local function closeSnipMenu()
	pcall(function()
		if DEX.Console.SnipMenu then
			DEX.Console.SnipMenu:Destroy()
			DEX.Console.SnipMenu = nil
		end
	end)
end

DEX.connect(snipBtn.MouseButton1Click, function()
	if DEX.Console.SnipMenu then
		closeSnipMenu()
		return
	end
	local menu = DEX.new("Frame", {
		Size = UDim2.new(0, 200, 0, #SNIPPETS * 26),
		Position = UDim2.new(0, snipBtn.AbsolutePosition.X, 0, snipBtn.AbsolutePosition.Y - #SNIPPETS * 26 - 4),
		BackgroundColor3 = DEX.Theme.Panel,
		BorderSizePixel = 0,
		ZIndex = 60,
		Parent = DEX.UI.ScreenGui,
	})
	DEX.corner(menu, 6)
	DEX.stroke(menu, DEX.Theme.Stroke, 1)
	DEX.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = menu })
	DEX.Console.SnipMenu = menu

	for index, snip in ipairs(SNIPPETS) do
		local item = DEX.new("TextButton", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = DEX.Theme.Panel2,
			Font = Enum.Font.Gotham,
			Text = "  " .. snip.name,
			TextColor3 = DEX.Theme.Text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			ZIndex = 61,
			LayoutOrder = index,
			Parent = menu,
		})
		DEX.connect(item.MouseEnter, function()
			item.BackgroundColor3 = DEX.Theme.Hover
		end)
		DEX.connect(item.MouseLeave, function()
			item.BackgroundColor3 = DEX.Theme.Panel2
		end)
		DEX.connect(item.MouseButton1Click, function()
			execBox.Text = snip.code
			closeSnipMenu()
		end)
	end
end)

--==================================================================
-- ============================ SETTINGS ============================
--==================================================================
local settingsPage = DEX.addTab("Settings", 6)

-- UIScale на главное окно
DEX.UI.Scale = DEX.UI.Scale or DEX.new("UIScale", {
	Scale = DEX.Settings.UIScale or 1,
	Parent = DEX.UI.Main,
})

local function sectionLabel(text, y)
	DEX.new("TextLabel", {
		Size = UDim2.new(1, -16, 0, 22),
		Position = UDim2.new(0, 12, 0, y),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = DEX.Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = settingsPage,
	})
end

----------------------------------------------------------------
-- ПЕРЕКРАШИВАНИЕ ТЕМЫ (живое, по карте старых -> новых цветов)
----------------------------------------------------------------
local function colorsEqual(a, b)
	if typeof(a) ~= "Color3" or typeof(b) ~= "Color3" then
		return false
	end
	local e = 0.003
	return math.abs(a.R - b.R) < e
		and math.abs(a.G - b.G) < e
		and math.abs(a.B - b.B) < e
end

local function applyTheme(themeName)
	local oldT = DEX.Theme
	local newT = DEX.Themes[themeName]
	if not newT then
		return
	end
	-- карта старый цвет -> новый цвет
	local map = {}
	for key, oldCol in pairs(oldT) do
		if typeof(oldCol) == "Color3" and newT[key] then
			table.insert(map, { old = oldCol, new = newT[key] })
		end
	end

	local props = { "BackgroundColor3", "TextColor3", "ImageColor3",
		"ScrollBarImageColor3", "PlaceholderColor3" }

	local function remap(inst)
		for _, propName in ipairs(props) do
			local ok, cur = pcall(function()
				return inst[propName]
			end)
			if ok and typeof(cur) == "Color3" then
				for _, pair in ipairs(map) do
					if colorsEqual(cur, pair.old) then
						pcall(function()
							inst[propName] = pair.new
						end)
						break
					end
				end
			end
		end
		-- UIStroke.Color
		if inst:IsA("UIStroke") then
			for _, pair in ipairs(map) do
				if colorsEqual(inst.Color, pair.old) then
					pcall(function()
						inst.Color = pair.new
					end)
					break
				end
			end
		end
	end

	local all = {}
	pcall(function()
		all = DEX.UI.ScreenGui:GetDescendants()
	end)
	for _, inst in ipairs(all) do
		pcall(function()
			remap(inst)
		end)
	end

	DEX.Theme = newT
	DEX.Settings.Theme = themeName
	DEX.notify("Тема: " .. themeName)
end

sectionLabel("Тема оформления", 10)
local themeNames = { "Dark", "Light", "Monokai" }
for index, name in ipairs(themeNames) do
	local btn = DEX.new("TextButton", {
		Size = UDim2.new(0, 110, 0, 30),
		Position = UDim2.new(0, 12 + (index - 1) * 118, 0, 38),
		BackgroundColor3 = DEX.Theme.Panel2,
		Font = Enum.Font.GothamMedium,
		Text = name,
		TextColor3 = DEX.Theme.Text,
		TextSize = 13,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Parent = settingsPage,
	})
	DEX.corner(btn, 6)
	DEX.connect(btn.MouseButton1Click, function()
		applyTheme(name)
	end)
end

----------------------------------------------------------------
-- МАСШТАБ UI
----------------------------------------------------------------
sectionLabel("Масштаб интерфейса", 84)

local scaleValue = DEX.new("TextLabel", {
	Size = UDim2.new(0, 80, 0, 30),
	Position = UDim2.new(0, 90, 0, 112),
	BackgroundColor3 = DEX.Theme.Panel2,
	Font = Enum.Font.Code,
	Text = string.format("%.2f", DEX.Settings.UIScale or 1),
	TextColor3 = DEX.Theme.Text,
	TextSize = 14,
	BorderSizePixel = 0,
	Parent = settingsPage,
})
DEX.corner(scaleValue, 6)

local function scaleButton(text, x)
	local btn = DEX.new("TextButton", {
		Size = UDim2.new(0, 70, 0, 30),
		Position = UDim2.new(0, x, 0, 112),
		BackgroundColor3 = DEX.Theme.Accent,
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = DEX.Theme.Text,
		TextSize = 16,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Parent = settingsPage,
	})
	DEX.corner(btn, 6)
	return btn
end

local minusBtn = scaleButton("−", 12)
local plusBtn  = scaleButton("+", 178)

local function setScale(v)
	local clamped = math.clamp(v, 0.5, 1.6)
	DEX.Settings.UIScale = clamped
	pcall(function()
		DEX.UI.Scale.Scale = clamped
	end)
	scaleValue.Text = string.format("%.2f", clamped)
end

DEX.connect(minusBtn.MouseButton1Click, function()
	setScale((DEX.Settings.UIScale or 1) - 0.1)
end)
DEX.connect(plusBtn.MouseButton1Click, function()
	setScale((DEX.Settings.UIScale or 1) + 0.1)
end)

----------------------------------------------------------------
-- LIVE STATS
----------------------------------------------------------------
sectionLabel("Live Stats", 158)

local statsLabel = DEX.new("TextLabel", {
	Size = UDim2.new(1, -24, 0, 90),
	Position = UDim2.new(0, 12, 0, 186),
	BackgroundColor3 = DEX.Theme.Panel,
	Font = Enum.Font.Code,
	Text = "FPS: --\nPing: --\nMemory: --\nObjects: --",
	TextColor3 = DEX.Theme.Good,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	BorderSizePixel = 0,
	Parent = settingsPage,
})
DEX.corner(statsLabel, 8)
DEX.new("UIPadding", {
	PaddingLeft = UDim.new(0, 10),
	PaddingTop = UDim.new(0, 6),
	Parent = statsLabel,
})

-- статистика обновляется на RenderStepped, текст раз в ~0.5с
DEX.Stats = DEX.Stats or { frames = 0, elapsed = 0, fps = 0 }

if RunService then
	DEX.connect(RunService.RenderStepped, function(dt)
		DEX.Stats.frames = DEX.Stats.frames + 1
		DEX.Stats.elapsed = DEX.Stats.elapsed + dt
		if DEX.Stats.elapsed >= 0.5 then
			DEX.Stats.fps = DEX.Stats.frames / DEX.Stats.elapsed
			DEX.Stats.frames = 0
			DEX.Stats.elapsed = 0

			local fps = math.floor(DEX.Stats.fps + 0.5)
			local ping = "n/a"
			pcall(function()
				ping = string.format("%d ms",
					math.floor(DEX.LocalPlayer:GetNetworkPing() * 1000))
			end)
			local mem = "n/a"
			pcall(function()
				mem = string.format("%.1f MB", gcinfo() / 1024)
			end)
			local objs = "?"
			pcall(function()
				objs = tostring(#game:GetDescendants())
			end)

			pcall(function()
				statsLabel.Text = "FPS: " .. tostring(fps)
					.. "\nPing: " .. ping
					.. "\nMemory: " .. mem
					.. "\nObjects: " .. objs
			end)
		end
	end)
end

----------------------------------------------------------------
-- ИНФО
----------------------------------------------------------------
DEX.new("TextLabel", {
	Size = UDim2.new(1, -24, 0, 40),
	Position = UDim2.new(0, 12, 1, -48),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "DEX Explorer v" .. tostring(DEX.Version)
		.. "  •  Solara build  •  Toggle: RightShift",
	TextColor3 = DEX.Theme.SubText,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = settingsPage,
})

----------------------------------------------------------------
-- СТАРТ
----------------------------------------------------------------
DEX.Console.Add("[DEX] Console готова. Перехват LogService активен.",
	Enum.MessageType.MessageOutput)

print("[DEX] PART 6/6 Console + Settings загружена. Сборка завершена ✓")
