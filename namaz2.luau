--==================================================================
-- DEX EXPLORER for Solara (Luau) | PART 2/6 : EXPLORER PANEL
--==================================================================

assert(getgenv().DEX and getgenv().DEX.Loaded and getgenv().DEX.Loaded.Core,
	"[DEX] Сначала запусти PART 1 (Foundation)")

local DEX = getgenv().DEX
DEX.Loaded.Explorer = true

DEX.Explorer = DEX.Explorer or {
	Expanded = {},      -- [instance] = true
	Selected = nil,
	SearchText = "",
	ClassFilter = "",
	Rows = {},
}

----------------------------------------------------------------
-- СТРАНИЦА И РАЗМЕТКА
----------------------------------------------------------------
local page = DEX.addTab("Explorer", 1)

-- верхняя панель поиска/фильтра
local topBar = DEX.new("Frame", {
	Size = UDim2.new(1, -16, 0, 56),
	Position = UDim2.new(0, 8, 0, 8),
	BackgroundTransparency = 1,
	Parent = page,
})

local searchBox = DEX.new("TextBox", {
	Size = UDim2.new(1, 0, 0, 24),
	BackgroundColor3 = DEX.Theme.Panel2,
	Font = Enum.Font.Gotham,
	PlaceholderText = "Поиск по имени...",
	Text = "",
	TextColor3 = DEX.Theme.Text,
	PlaceholderColor3 = DEX.Theme.SubText,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	ClearTextOnFocus = false,
	BorderSizePixel = 0,
	Parent = topBar,
})
DEX.corner(searchBox, 6)
DEX.new("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = searchBox })

local classBox = DEX.new("TextBox", {
	Size = UDim2.new(1, 0, 0, 24),
	Position = UDim2.new(0, 0, 0, 30),
	BackgroundColor3 = DEX.Theme.Panel2,
	Font = Enum.Font.Gotham,
	PlaceholderText = "Фильтр по классу (напр. Part, RemoteEvent)...",
	Text = "",
	TextColor3 = DEX.Theme.Text,
	PlaceholderColor3 = DEX.Theme.SubText,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	ClearTextOnFocus = false,
	BorderSizePixel = 0,
	Parent = topBar,
})
DEX.corner(classBox, 6)
DEX.new("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = classBox })

-- контейнер: слева дерево, справа свойства
local treeHolder = DEX.new("Frame", {
	Size = UDim2.new(0.58, -8, 1, -76),
	Position = UDim2.new(0, 8, 0, 68),
	BackgroundColor3 = DEX.Theme.Panel,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = page,
})
DEX.corner(treeHolder, 8)

local treeScroll = DEX.makeScroll(treeHolder)
DEX.new("UIListLayout", {
	Padding = UDim.new(0, 1),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = treeScroll,
})

local propHolder = DEX.new("Frame", {
	Size = UDim2.new(0.42, -8, 1, -76),
	Position = UDim2.new(0.58, 8, 0, 68),
	BackgroundColor3 = DEX.Theme.Panel,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = page,
})
DEX.corner(propHolder, 8)

local propTitle = DEX.new("TextLabel", {
	Size = UDim2.new(1, -16, 0, 26),
	Position = UDim2.new(0, 8, 0, 6),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "Свойства",
	TextColor3 = DEX.Theme.Text,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = propHolder,
})

local propScroll = DEX.makeScroll(propHolder)
propScroll.Position = UDim2.new(0, 0, 0, 34)
propScroll.Size = UDim2.new(1, 0, 1, -34)
DEX.new("UIListLayout", {
	Padding = UDim.new(0, 3),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = propScroll,
})
DEX.new("UIPadding", {
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
	PaddingTop = UDim.new(0, 4),
	Parent = propScroll,
})

----------------------------------------------------------------
-- УТИЛИТЫ ПУТИ
----------------------------------------------------------------
local function getFullPath(inst)
	local path = nil
	pcall(function()
		path = inst:GetFullName()
	end)
	if path then
		return path
	end
	-- ручная сборка
	local parts = {}
	local cur = inst
	local guard = 0
	while cur and guard < 200 do
		guard = guard + 1
		local nm = "?"
		pcall(function()
			nm = cur.Name
		end)
		table.insert(parts, 1, nm)
		local par = nil
		pcall(function()
			par = cur.Parent
		end)
		if not par then
			break
		end
		cur = par
	end
	return table.concat(parts, ".")
end

local function getClassName(inst)
	local cls = "Instance"
	pcall(function()
		cls = inst.ClassName
	end)
	return cls
end

local function getName(inst)
	local nm = "?"
	pcall(function()
		nm = inst.Name
	end)
	return nm
end

local function hasChildren(inst)
	local result = false
	pcall(function()
		result = #inst:GetChildren() > 0
	end)
	return result
end

----------------------------------------------------------------
-- ПАНЕЛЬ СВОЙСТВ
----------------------------------------------------------------
-- список самых частых свойств, читаем через pcall (без gethiddenproperty)
local COMMON_PROPS = {
	"Name", "ClassName", "Parent", "Archivable",
	"Position", "Size", "CFrame", "Orientation", "Rotation",
	"Anchored", "CanCollide", "Transparency", "Reflectance",
	"Color", "BrickColor", "Material", "Massless",
	"Value", "Text", "Visible", "Enabled", "Active",
	"Health", "MaxHealth", "WalkSpeed", "JumpPower", "HipHeight",
	"Velocity", "AssemblyLinearVelocity", "Mass",
	"Source", "LinkedSource", "Disabled",
	"UserId", "DisplayName", "Team", "TeamColor",
	"PrimaryPart", "AdorneeName",
}

local function valueToString(v)
	local t = typeof(v)
	if t == "Instance" then
		return getName(v) .. " (" .. getClassName(v) .. ")"
	elseif t == "Vector3" then
		return string.format("%.2f, %.2f, %.2f", v.X, v.Y, v.Z)
	elseif t == "CFrame" then
		local x, y, z = v.X, v.Y, v.Z
		return string.format("pos %.1f, %.1f, %.1f", x, y, z)
	elseif t == "Color3" then
		return string.format("%d, %d, %d",
			math.floor(v.R * 255), math.floor(v.G * 255), math.floor(v.B * 255))
	elseif t == "EnumItem" then
		return tostring(v)
	elseif t == "boolean" or t == "number" or t == "string" then
		return tostring(v)
	else
		return tostring(v)
	end
end

-- попытка записать новое значение обратно (для bool/number/string)
local function tryWrite(inst, propName, newText, oldValue)
	local t = typeof(oldValue)
	local ok = false
	if t == "number" then
		local num = tonumber(newText)
		if num then
			ok = pcall(function()
				inst[propName] = num
			end)
		end
	elseif t == "boolean" then
		local b = (newText == "true" or newText == "1")
		ok = pcall(function()
			inst[propName] = b
		end)
	elseif t == "string" then
		ok = pcall(function()
			inst[propName] = newText
		end)
	end
	return ok
end

local function clearProps()
	for _, child in pairs(propScroll:GetChildren()) do
		if child:IsA("Frame") then
			pcall(function()
				child:Destroy()
			end)
		end
	end
end

local function addPropRow(inst, propName, value, order)
	local row = DEX.new("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundColor3 = DEX.Theme.Panel2,
		BorderSizePixel = 0,
		LayoutOrder = order,
		Parent = propScroll,
	})
	DEX.corner(row, 4)

	DEX.new("TextLabel", {
		Size = UDim2.new(0.42, -4, 1, 0),
		Position = UDim2.new(0, 6, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = propName,
		TextColor3 = DEX.Theme.SubText,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})

	local t = typeof(value)
	local editable = (t == "number" or t == "boolean" or t == "string")
		and propName ~= "ClassName"

	local valBox = DEX.new("TextBox", {
		Size = UDim2.new(0.58, -8, 1, -4),
		Position = UDim2.new(0.42, 2, 0, 2),
		BackgroundColor3 = DEX.Theme.Panel,
		Font = Enum.Font.Gotham,
		Text = valueToString(value),
		TextColor3 = editable and DEX.Theme.Text or DEX.Theme.SubText,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ClearTextOnFocus = false,
		TextEditable = editable,
		BorderSizePixel = 0,
		Parent = row,
	})
	DEX.corner(valBox, 4)
	DEX.new("UIPadding", { PaddingLeft = UDim.new(0, 6), Parent = valBox })

	if editable then
		DEX.connect(valBox.FocusLost, function(enter)
			if enter then
				local ok = tryWrite(inst, propName, valBox.Text, value)
				if not ok then
					valBox.Text = valueToString(value)
					DEX.notify("Не удалось записать " .. propName)
				end
			end
		end)
	end
end

local function showProps(inst)
	clearProps()
	if not inst then
		propTitle.Text = "Свойства"
		return
	end
	propTitle.Text = "Свойства: " .. getName(inst)

	local order = 0
	for _, propName in ipairs(COMMON_PROPS) do
		local ok, value = DEX.safeGet(inst, propName)
		if ok and value ~= nil then
			order = order + 1
			addPropRow(inst, propName, value, order)
		end
	end

	if order == 0 then
		DEX.new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = "Нет доступных свойств",
			TextColor3 = DEX.Theme.SubText,
			TextSize = 12,
			Parent = propScroll,
		})
	end
end

----------------------------------------------------------------
-- КОНТЕКСТНОЕ МЕНЮ
----------------------------------------------------------------
local function closeContextMenu()
	pcall(function()
		if DEX.Explorer.Menu then
			DEX.Explorer.Menu:Destroy()
			DEX.Explorer.Menu = nil
		end
	end)
end

local function contextItem(parentMenu, text, order, callback)
	local btn = DEX.new("TextButton", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundColor3 = DEX.Theme.Panel2,
		Font = Enum.Font.Gotham,
		Text = "  " .. text,
		TextColor3 = DEX.Theme.Text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		LayoutOrder = order,
		Parent = parentMenu,
	})
	DEX.connect(btn.MouseEnter, function()
		btn.BackgroundColor3 = DEX.Theme.Hover
	end)
	DEX.connect(btn.MouseLeave, function()
		btn.BackgroundColor3 = DEX.Theme.Panel2
	end)
	DEX.connect(btn.MouseButton1Click, function()
		closeContextMenu()
		pcall(callback)
	end)
end

local function openContextMenu(inst, posX, posY)
	closeContextMenu()
	local menu = DEX.new("Frame", {
		Size = UDim2.new(0, 160, 0, 26 * 4),
		Position = UDim2.new(0, posX, 0, posY),
		BackgroundColor3 = DEX.Theme.Panel,
		BorderSizePixel = 0,
		ZIndex = 50,
		Parent = DEX.UI.ScreenGui,
	})
	DEX.corner(menu, 6)
	DEX.stroke(menu, DEX.Theme.Stroke, 1)
	DEX.new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = menu,
	})
	DEX.Explorer.Menu = menu

	contextItem(menu, "Копировать путь", 1, function()
		pcall(function()
			setclipboard(getFullPath(inst))
		end)
		DEX.notify("Путь скопирован")
	end)
	contextItem(menu, "Копировать имя", 2, function()
		pcall(function()
			setclipboard(getName(inst))
		end)
		DEX.notify("Имя скопировано")
	end)
	contextItem(menu, "Развернуть в дереве", 3, function()
		DEX.Explorer.Expanded[inst] = true
		DEX.Explorer.Render()
	end)
	contextItem(menu, "Удалить", 4, function()
		pcall(function()
			inst:Destroy()
		end)
		DEX.Explorer.Render()
		DEX.notify("Объект удалён")
	end)
end

----------------------------------------------------------------
-- ОТРИСОВКА ДЕРЕВА
----------------------------------------------------------------
local function clearTree()
	for _, child in pairs(treeScroll:GetChildren()) do
		if child:IsA("TextButton") then
			pcall(function()
				child:Destroy()
			end)
		end
	end
	DEX.Explorer.Rows = {}
end

local function makeRow(inst, depth, order)
	local nm = getName(inst)
	local cls = getClassName(inst)
	local expandable = hasChildren(inst)
	local isExpanded = DEX.Explorer.Expanded[inst] == true

	local arrow = "   "
	if expandable then
		arrow = isExpanded and "▼ " or "▶ "
	end

	local isSel = (DEX.Explorer.Selected == inst)

	local row = DEX.new("TextButton", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundColor3 = isSel and DEX.Theme.Selected or DEX.Theme.Panel,
		Font = Enum.Font.Gotham,
		Text = arrow .. nm .. "   [" .. cls .. "]",
		TextColor3 = isSel and DEX.Theme.Text or DEX.Theme.SubText,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		LayoutOrder = order,
		Parent = treeScroll,
	})
	DEX.new("UIPadding", {
		PaddingLeft = UDim.new(0, 8 + depth * 16),
		Parent = row,
	})

	DEX.connect(row.MouseEnter, function()
		if DEX.Explorer.Selected ~= inst then
			row.BackgroundColor3 = DEX.Theme.Hover
		end
	end)
	DEX.connect(row.MouseLeave, function()
		if DEX.Explorer.Selected ~= inst then
			row.BackgroundColor3 = DEX.Theme.Panel
		end
	end)

	DEX.connect(row.MouseButton1Click, function()
		-- одиночный клик = выбрать + показать свойства;
		-- если есть дети — переключить раскрытие
		DEX.Explorer.Selected = inst
		showProps(inst)
		if expandable then
			DEX.Explorer.Expanded[inst] = not isExpanded
		end
		DEX.Explorer.Render()
	end)

	DEX.connect(row.MouseButton2Click, function()
		DEX.Explorer.Selected = inst
		showProps(inst)
		local mouse = DEX.Services.UserInputService:GetMouseLocation()
		openContextMenu(inst, mouse.X, mouse.Y)
	end)

	return row
end

-- рекурсивный обход с учётом раскрытия
local function renderNode(inst, depth, orderRef)
	orderRef.n = orderRef.n + 1
	makeRow(inst, depth, orderRef.n)

	if DEX.Explorer.Expanded[inst] then
		local children = {}
		pcall(function()
			children = inst:GetChildren()
		end)
		for _, child in ipairs(children) do
			if orderRef.n < 1500 then
				renderNode(child, depth + 1, orderRef)
			end
		end
	end
end

-- режим поиска: плоский список совпадений
local function renderSearch(query, classFilter)
	local orderRef = { n = 0 }
	local lowerQ = string.lower(query)
	local lowerC = string.lower(classFilter)
	local descendants = {}
	pcall(function()
		descendants = game:GetDescendants()
	end)
	for _, inst in ipairs(descendants) do
		if orderRef.n >= 600 then
			break
		end
		local nm = string.lower(getName(inst))
		local cls = string.lower(getClassName(inst))
		local nameOk = (query == "" or string.find(nm, lowerQ, 1, true) ~= nil)
		local classOk = (classFilter == "" or string.find(cls, lowerC, 1, true) ~= nil)
		if nameOk and classOk then
			orderRef.n = orderRef.n + 1
			makeRow(inst, 0, orderRef.n)
		end
	end
	if orderRef.n == 0 then
		DEX.new("TextButton", {
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = "  Ничего не найдено",
			TextColor3 = DEX.Theme.SubText,
			TextSize = 12,
			AutoButtonColor = false,
			Parent = treeScroll,
		})
	end
end

function DEX.Explorer.Render()
	clearTree()
	local query = DEX.Explorer.SearchText
	local classFilter = DEX.Explorer.ClassFilter

	if query ~= "" or classFilter ~= "" then
		renderSearch(query, classFilter)
	else
		local orderRef = { n = 0 }
		-- корни: game + основные сервисы (раскрываем по клику)
		renderNode(game, 0, orderRef)
	end
end

----------------------------------------------------------------
-- ПОДКЛЮЧЕНИЕ ПОИСКА/ФИЛЬТРА
----------------------------------------------------------------
DEX.connect(searchBox:GetPropertyChangedSignal("Text"), function()
	DEX.Explorer.SearchText = searchBox.Text
end)
DEX.connect(searchBox.FocusLost, function()
	DEX.Explorer.Render()
end)
DEX.connect(classBox:GetPropertyChangedSignal("Text"), function()
	DEX.Explorer.ClassFilter = classBox.Text
end)
DEX.connect(classBox.FocusLost, function()
	DEX.Explorer.Render()
end)

-- клик в пустоту закрывает контекстное меню
DEX.connect(DEX.Services.UserInputService.InputBegan, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		task.delay(0.05, function()
			if DEX.Explorer.Menu then
				-- закрываем, если клик не по меню (грубая проверка по позиции)
				local m = DEX.Services.UserInputService:GetMouseLocation()
				local menu = DEX.Explorer.Menu
				if menu then
					local p = menu.AbsolutePosition
					local s = menu.AbsoluteSize
					local inside = m.X >= p.X and m.X <= p.X + s.X
						and m.Y >= p.Y and m.Y <= p.Y + s.Y
					if not inside then
						closeContextMenu()
					end
				end
			end
		end)
	end
end)

----------------------------------------------------------------
-- СТАРТ: game раскрыт на первом уровне
----------------------------------------------------------------
DEX.Explorer.Expanded[game] = true
DEX.Explorer.Render()

print("[DEX] PART 2/6 Explorer Panel загружена.")
