--==================================================================
-- DEX EXPLORER for Solara (Luau) | PART 1/6 : FOUNDATION / CORE
-- Совместимо с ~39% sUNC. Без hookfunction/getrawmetatable/getconnections.
--==================================================================

local DEX = getgenv().DEX or {}
getgenv().DEX = DEX

DEX.Version = "1.0"
DEX.Loaded  = DEX.Loaded or {}
DEX.Loaded.Core = true

----------------------------------------------------------------
-- SERVICES (через pcall, чтобы nil не ронял скрипт)
----------------------------------------------------------------
local function getService(serviceName)
	local service = nil
	pcall(function()
		service = game:GetService(serviceName)
	end)
	return service
end

DEX.Services = {
	Players          = getService("Players"),
	CoreGui          = getService("CoreGui"),
	UserInputService = getService("UserInputService"),
	TweenService     = getService("TweenService"),
	RunService       = getService("RunService"),
	LogService       = getService("LogService"),
	Workspace        = getService("Workspace"),
	HttpService      = getService("HttpService"),
}

DEX.LocalPlayer = nil
pcall(function()
	DEX.LocalPlayer = DEX.Services.Players.LocalPlayer
end)

----------------------------------------------------------------
-- ОБЩЕЕ СОСТОЯНИЕ
----------------------------------------------------------------
DEX.State = DEX.State or {
	Open      = true,
	Minimized = false,
	ToggleKey = Enum.KeyCode.RightShift,
}

DEX.UI    = DEX.UI or {}
DEX.Tabs  = DEX.Tabs or {}
DEX.Conns = DEX.Conns or {}   -- сюда складываем соединения, чтобы потом чистить

----------------------------------------------------------------
-- ТЕМЫ (Color3.fromRGB — всегда 3 аргумента)
----------------------------------------------------------------
DEX.Themes = {
	Dark = {
		Background  = Color3.fromRGB(28, 28, 32),
		Panel       = Color3.fromRGB(36, 36, 42),
		Panel2      = Color3.fromRGB(44, 44, 52),
		Accent      = Color3.fromRGB(86, 130, 255),
		Stroke      = Color3.fromRGB(60, 60, 70),
		Text        = Color3.fromRGB(235, 235, 240),
		SubText     = Color3.fromRGB(160, 160, 170),
		Hover       = Color3.fromRGB(54, 54, 64),
		Selected    = Color3.fromRGB(70, 90, 160),
		Good        = Color3.fromRGB(120, 220, 130),
		Bad         = Color3.fromRGB(235, 110, 110),
	},
	Light = {
		Background  = Color3.fromRGB(240, 240, 244),
		Panel       = Color3.fromRGB(255, 255, 255),
		Panel2      = Color3.fromRGB(228, 228, 234),
		Accent      = Color3.fromRGB(60, 110, 245),
		Stroke      = Color3.fromRGB(200, 200, 210),
		Text        = Color3.fromRGB(25, 25, 30),
		SubText     = Color3.fromRGB(110, 110, 120),
		Hover       = Color3.fromRGB(220, 224, 235),
		Selected    = Color3.fromRGB(190, 205, 250),
		Good        = Color3.fromRGB(40, 160, 70),
		Bad         = Color3.fromRGB(200, 60, 60),
	},
	Monokai = {
		Background  = Color3.fromRGB(39, 40, 34),
		Panel       = Color3.fromRGB(46, 47, 41),
		Panel2      = Color3.fromRGB(56, 57, 49),
		Accent      = Color3.fromRGB(166, 226, 46),
		Stroke      = Color3.fromRGB(70, 71, 62),
		Text        = Color3.fromRGB(248, 248, 242),
		SubText     = Color3.fromRGB(150, 150, 138),
		Hover       = Color3.fromRGB(62, 63, 54),
		Selected    = Color3.fromRGB(73, 72, 62),
		Good        = Color3.fromRGB(166, 226, 46),
		Bad         = Color3.fromRGB(249, 38, 114),
	},
}

DEX.Settings = DEX.Settings or {
	Theme       = "Dark",
	UIScale     = 1,
	ShowStats   = true,
}

DEX.Theme = DEX.Themes[DEX.Settings.Theme] or DEX.Themes.Dark

----------------------------------------------------------------
-- УТИЛИТА СОЗДАНИЯ ИНСТАНСОВ (всё через pcall)
----------------------------------------------------------------
function DEX.new(className, props, children)
	local inst = nil
	pcall(function()
		inst = Instance.new(className)
	end)
	if not inst then
		return nil
	end
	if props then
		for key, value in pairs(props) do
			pcall(function()
				inst[key] = value
			end)
		end
	end
	if children then
		for _, child in pairs(children) do
			pcall(function()
				child.Parent = inst
			end)
		end
	end
	return inst
end

-- Безопасное чтение свойства (замена gethiddenproperty)
function DEX.safeGet(instance, propName)
	local value = nil
	local ok = pcall(function()
		value = instance[propName]
	end)
	return ok, value
end

-- Безопасное соединение событий с авто-учётом для очистки
function DEX.connect(signal, callback)
	local conn = nil
	pcall(function()
		conn = signal:Connect(function(...)
			pcall(callback, ...)
		end)
	end)
	if conn then
		table.insert(DEX.Conns, conn)
	end
	return conn
end

-- Простой твин (анимации)
function DEX.tween(inst, time, props)
	local TS = DEX.Services.TweenService
	if not (TS and inst) then
		return
	end
	pcall(function()
		local info = TweenInfo.new(time or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tw = TS:Create(inst, info, props)
		tw:Play()
	end)
end

-- Закруглить угол
function DEX.corner(parent, radius)
	return DEX.new("UICorner", {
		CornerRadius = UDim.new(0, radius or 6),
		Parent = parent,
	})
end

-- Обводка
function DEX.stroke(parent, color, thickness)
	return DEX.new("UIStroke", {
		Color = color or DEX.Theme.Stroke,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

----------------------------------------------------------------
-- ЗАЩИТА GUI + ПАРЕНТ (CoreGui -> PlayerGui fallback)
----------------------------------------------------------------
local function protectGui(gui)
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
		end
	end)
	pcall(function()
		if protect_gui then
			protect_gui(gui)
		end
	end)
end

local function parentGui(gui)
	local parented = false
	-- 1) CoreGui
	pcall(function()
		gui.Parent = DEX.Services.CoreGui
		parented = true
	end)
	-- 2) PlayerGui fallback
	if not parented then
		pcall(function()
			gui.Parent = DEX.LocalPlayer:FindFirstChildOfClass("PlayerGui")
			parented = true
		end)
	end
	-- 3) последняя попытка
	if not parented then
		pcall(function()
			gui.Parent = game:GetService("CoreGui")
		end)
	end
	return parented
end

----------------------------------------------------------------
-- ОЧИСТКА СТАРОЙ КОПИИ (повторный запуск)
----------------------------------------------------------------
pcall(function()
	if DEX.UI.ScreenGui then
		DEX.UI.ScreenGui:Destroy()
	end
end)
for _, conn in pairs(DEX.Conns) do
	pcall(function()
		conn:Disconnect()
	end)
end
DEX.Conns = {}

----------------------------------------------------------------
-- ROOT SCREENGUI
----------------------------------------------------------------
local screenGui = DEX.new("ScreenGui", {
	Name = "DEX_" .. tostring(math.random(10000, 99999)),
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
})
protectGui(screenGui)
parentGui(screenGui)
DEX.UI.ScreenGui = screenGui

----------------------------------------------------------------
-- ГЛАВНОЕ ОКНО
----------------------------------------------------------------
local main = DEX.new("Frame", {
	Name = "Main",
	Size = UDim2.new(0, 760, 0, 470),
	Position = UDim2.new(0.5, -380, 0.5, -235),
	BackgroundColor3 = DEX.Theme.Background,
	BorderSizePixel = 0,
	Active = true,
	Parent = screenGui,
})
DEX.corner(main, 10)
DEX.stroke(main, DEX.Theme.Stroke, 1)
DEX.UI.Main = main

-- TITLE BAR
local titleBar = DEX.new("Frame", {
	Name = "TitleBar",
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundColor3 = DEX.Theme.Panel,
	BorderSizePixel = 0,
	Parent = main,
})
DEX.corner(titleBar, 10)
DEX.UI.TitleBar = titleBar

DEX.new("TextLabel", {
	Name = "Title",
	Size = UDim2.new(1, -110, 1, 0),
	Position = UDim2.new(0, 12, 0, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "DEX EXPLORER  •  Solara",
	TextColor3 = DEX.Theme.Text,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = titleBar,
})

-- кнопки минимайз/закрыть
local function titleButton(symbol, offsetX, color)
	local btn = DEX.new("TextButton", {
		Size = UDim2.new(0, 26, 0, 26),
		Position = UDim2.new(1, offsetX, 0, 4),
		BackgroundColor3 = DEX.Theme.Panel2,
		Text = symbol,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = color or DEX.Theme.Text,
		AutoButtonColor = true,
		BorderSizePixel = 0,
		Parent = titleBar,
	})
	DEX.corner(btn, 6)
	return btn
end

local minBtn   = titleButton("–", -64, DEX.Theme.Text)
local closeBtn = titleButton("×", -32, DEX.Theme.Bad)
DEX.UI.MinBtn = minBtn
DEX.UI.CloseBtn = closeBtn

-- TAB BAR (слева)
local tabBar = DEX.new("Frame", {
	Name = "TabBar",
	Size = UDim2.new(0, 140, 1, -34),
	Position = UDim2.new(0, 0, 0, 34),
	BackgroundColor3 = DEX.Theme.Panel,
	BorderSizePixel = 0,
	Parent = main,
})
DEX.UI.TabBar = tabBar

DEX.new("UIListLayout", {
	Padding = UDim.new(0, 4),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = tabBar,
})
DEX.new("UIPadding", {
	PaddingTop = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
	Parent = tabBar,
})

-- CONTENT (справа)
local content = DEX.new("Frame", {
	Name = "Content",
	Size = UDim2.new(1, -140, 1, -34),
	Position = UDim2.new(0, 140, 0, 34),
	BackgroundColor3 = DEX.Theme.Background,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = main,
})
DEX.UI.Content = content

-- RESIZE HANDLE (нижний правый угол)
local resizeHandle = DEX.new("TextButton", {
	Name = "Resize",
	Size = UDim2.new(0, 16, 0, 16),
	Position = UDim2.new(1, -16, 1, -16),
	BackgroundTransparency = 1,
	Text = "◢",
	TextColor3 = DEX.Theme.SubText,
	TextSize = 14,
	Font = Enum.Font.GothamBold,
	AutoButtonColor = false,
	Parent = main,
})
DEX.UI.ResizeHandle = resizeHandle

----------------------------------------------------------------
-- DRAG (перетаскивание за TitleBar)
----------------------------------------------------------------
local function makeDraggable(frame, handle)
	local UIS = DEX.Services.UserInputService
	local dragging = false
	local dragStart = nil
	local startPos = nil

	DEX.connect(handle.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)

	DEX.connect(handle.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	DEX.connect(UIS.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end
makeDraggable(main, titleBar)

----------------------------------------------------------------
-- RESIZE (через UserInputService)
----------------------------------------------------------------
local function makeResizable(frame, handle)
	local UIS = DEX.Services.UserInputService
	local resizing = false
	local startPos = nil
	local startSize = nil
	local minW, minH = 520, 320

	DEX.connect(handle.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			startPos = input.Position
			startSize = frame.AbsoluteSize
		end
	end)

	DEX.connect(handle.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			resizing = false
		end
	end)

	DEX.connect(UIS.InputChanged, function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startPos
			local newW = math.max(minW, startSize.X + delta.X)
			local newH = math.max(minH, startSize.Y + delta.Y)
			frame.Size = UDim2.new(0, newW, 0, newH)
		end
	end)
end
makeResizable(main, resizeHandle)

----------------------------------------------------------------
-- СИСТЕМА ВКЛАДОК
-- DEX.addTab(name) -> возвращает контентный Frame для панели
----------------------------------------------------------------
function DEX.selectTab(name)
	for tabName, data in pairs(DEX.Tabs) do
		local isSel = (tabName == name)
		pcall(function()
			data.Page.Visible = isSel
			DEX.tween(data.Button, 0.15, {
				BackgroundColor3 = isSel and DEX.Theme.Selected or DEX.Theme.Panel2,
			})
			data.Button.TextColor3 = isSel and DEX.Theme.Text or DEX.Theme.SubText
		end)
	end
	DEX.State.CurrentTab = name
end

function DEX.addTab(name, layoutOrder)
	if DEX.Tabs[name] then
		return DEX.Tabs[name].Page
	end

	local btn = DEX.new("TextButton", {
		Name = name .. "_Tab",
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = DEX.Theme.Panel2,
		Text = name,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextColor3 = DEX.Theme.SubText,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		LayoutOrder = layoutOrder or 1,
		Parent = DEX.UI.TabBar,
	})
	DEX.corner(btn, 6)

	local page = DEX.new("Frame", {
		Name = name .. "_Page",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = DEX.UI.Content,
	})

	DEX.connect(btn.MouseEnter, function()
		if DEX.State.CurrentTab ~= name then
			DEX.tween(btn, 0.12, { BackgroundColor3 = DEX.Theme.Hover })
		end
	end)
	DEX.connect(btn.MouseLeave, function()
		if DEX.State.CurrentTab ~= name then
			DEX.tween(btn, 0.12, { BackgroundColor3 = DEX.Theme.Panel2 })
		end
	end)
	DEX.connect(btn.MouseButton1Click, function()
		DEX.selectTab(name)
	end)

	DEX.Tabs[name] = { Button = btn, Page = page }
	return page
end

----------------------------------------------------------------
-- ПОКАЗ / СКРЫТИЕ ОКНА
----------------------------------------------------------------
function DEX.toggle(forceState)
	local newState = forceState
	if newState == nil then
		newState = not DEX.State.Open
	end
	DEX.State.Open = newState
	pcall(function()
		main.Visible = newState
	end)
end

DEX.connect(minBtn.MouseButton1Click, function()
	DEX.State.Minimized = not DEX.State.Minimized
	local targetH = DEX.State.Minimized and 34 or 470
	DEX.tween(main, 0.2, { Size = UDim2.new(0, main.AbsoluteSize.X, 0, targetH) })
	task.delay(0.05, function()
		pcall(function()
			DEX.UI.TabBar.Visible = not DEX.State.Minimized
			DEX.UI.Content.Visible = not DEX.State.Minimized
		end)
	end)
end)

DEX.connect(closeBtn.MouseButton1Click, function()
	DEX.toggle(false)
end)

-- Хоткей показать/скрыть
DEX.connect(DEX.Services.UserInputService.InputBegan, function(input, gpe)
	if gpe then
		return
	end
	if input.KeyCode == DEX.State.ToggleKey then
		DEX.toggle()
	end
end)

----------------------------------------------------------------
-- ПУБЛИЧНЫЕ ХЕЛПЕРЫ ДЛЯ СЛЕДУЮЩИХ ЧАСТЕЙ
----------------------------------------------------------------
-- Создать стандартный скролл-контейнер внутри страницы
function DEX.makeScroll(parent)
	local scroll = DEX.new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = DEX.Theme.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = parent,
	})
	return scroll
end

-- Уведомление (понадобится в Console/Remotes)
function DEX.notify(text, kind)
	pcall(function()
		print("[DEX] " .. tostring(text))
	end)
end

----------------------------------------------------------------
-- ГОТОВО: первая вкладка-заглушка, чтобы окно не было пустым
----------------------------------------------------------------
local homePage = DEX.addTab("Home", 0)
DEX.new("TextLabel", {
	Size = UDim2.new(1, -20, 0, 60),
	Position = UDim2.new(0, 10, 0, 14),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "DEX Explorer ядро загружено ✓\nЖду остальные модули...",
	TextColor3 = DEX.Theme.Text,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Parent = homePage,
})
DEX.selectTab("Home")

print("[DEX] PART 1/6 Foundation загружена. Toggle: RightShift")
