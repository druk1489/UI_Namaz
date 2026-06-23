--==================================================================
-- DEX EXPLORER for Solara (Luau) | PART 4/6 : REMOTES PANEL
--==================================================================

assert(getgenv().DEX and getgenv().DEX.Loaded and getgenv().DEX.Loaded.Core,
	"[DEX] Сначала запусти PART 1 (Foundation)")

local DEX = getgenv().DEX
DEX.Loaded.Remotes = true

DEX.Remotes = DEX.Remotes or {
	List = {},
	Selected = nil,
	Blocked = {},     -- [instance] = true
	Log = {},         -- { time, name, method, preview }
	Filter = "",
	SpyActive = false,
}

----------------------------------------------------------------
-- УНИВЕРСАЛЬНЫЙ unpack
----------------------------------------------------------------
local function unpackArgs(t, count)
	local f = nil
	if table and table.unpack then
		f = table.unpack
	else
		f = unpack
	end
	return f(t, 1, count)
end

----------------------------------------------------------------
-- ПРЕВЬЮ АРГУМЕНТОВ
----------------------------------------------------------------
local function argPreview(t, count)
	local parts = {}
	local i = 1
	while i <= count do
		local v = t[i]
		local tp = typeof(v)
		local s = nil
		if tp == "string" then
			local short = v
			if #short > 40 then
				short = string.sub(short, 1, 40) .. "..."
			end
			s = '"' .. short .. '"'
		elseif tp == "Instance" then
			local nm = "?"
			pcall(function() nm = v.Name end)
			s = nm .. "<Instance>"
		elseif tp == "table" then
			s = "{table}"
		else
			s = tostring(v)
		end
		table.insert(parts, s)
		i = i + 1
	end
	if count == 0 then
		return "(нет аргументов)"
	end
	return table.concat(parts, ", ")
end

----------------------------------------------------------------
-- ПАРСИНГ АРГУМЕНТОВ ИЗ ТЕКСТА (через loadstring)
----------------------------------------------------------------
local function parseArgs(text)
	if text == nil or text == "" then
		return {}, 0, true
	end
	local fn = nil
	local err = nil
	pcall(function()
		fn, err = loadstring("return {" .. text .. "}")
	end)
	if not fn then
		return {}, 0, false
	end
	local ok, res = pcall(fn)
	if ok and type(res) == "table" then
		-- считаем длину с учётом возможных nil-дыр
		local count = 0
		local n = 1
		while n <= 50 do
			if res[n] ~= nil then
				count = n
			end
			n = n + 1
		end
		return res, count, true
	end
	return {}, 0, false
end

----------------------------------------------------------------
-- ПОПЫТКА ПОДНЯТЬ ПОЛНЫЙ SPY (gracefully degrade)
----------------------------------------------------------------
-- На Solara getrawmetatable/hookmetamethod/getnamecallmethod отсутствуют,
-- поэтому этот блок ВСЕГДА уйдёт в pcall-ошибку и SpyActive останется false.
-- Если запустить на исполнителе посильнее — спай активируется автоматически.
local function tryEnableFullSpy()
	local ok = pcall(function()
		local mt = getrawmetatable(game)
		local oldNamecall = mt.__namecall
		setreadonly(mt, false)
		mt.__namecall = newcclosure(function(self, ...)
			local method = getnamecallmethod()
			local blocked = DEX.Remotes.Blocked[self] == true
			if method == "FireServer" or method == "InvokeServer" then
				local args = { ... }
				local count = select("#", ...)
				local nm = "?"
				pcall(function() nm = self.Name end)
				DEX.Remotes.AddLog(nm, method .. " (spy)", argPreview(args, count))
				if blocked then
					return nil
				end
			end
			return oldNamecall(self, ...)
		end)
		setreadonly(mt, true)
	end)
	DEX.Remotes.SpyActive = ok
	return ok
end

----------------------------------------------------------------
-- СТРАНИЦА И РАЗМЕТКА
----------------------------------------------------------------
local page = DEX.addTab("Remotes", 3)

-- баннер режима
local banner = DEX.new("TextLabel", {
	Size = UDim2.new(1, -16, 0, 22),
	Position = UDim2.new(0, 8, 0, 8),
	BackgroundColor3 = DEX.Theme.Panel2,
	Font = Enum.Font.GothamMedium,
	Text = "",
	TextColor3 = DEX.Theme.SubText,
	TextSize = 12,
	BorderSizePixel = 0,
	Parent = page,
})
DEX.corner(banner, 6)

-- ЛЕВО: список
local listHolder = DEX.new("Frame", {
	Size = UDim2.new(0, 230, 1, -38),
	Position = UDim2.new(0, 8, 0, 34),
	BackgroundColor3 = DEX.Theme.Panel,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = page,
})
DEX.corner(listHolder, 8)

local filterBox = DEX.new("TextBox", {
	Size = UDim2.new(1, -12, 0, 24),
	Position = UDim2.new(0, 6, 0, 6),
	BackgroundColor3 = DEX.Theme.Panel2,
	Font = Enum.Font.Gotham,
	PlaceholderText = "Фильтр remotes...",
	Text = "",
	TextColor3 = DEX.Theme.Text,
	PlaceholderColor3 = DEX.Theme.SubText,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	ClearTextOnFocus = false,
	BorderSizePixel = 0,
	Parent = listHolder,
})
DEX.corner(filterBox, 6)
DEX.new("UIPadding", { PaddingLeft = UDim.new(0, 6), Parent = filterBox })

local rescanBtn = DEX.new("TextButton", {
	Size = UDim2.new(1, -12, 0, 22),
	Position = UDim2.new(0, 6, 0, 34),
	BackgroundColor3 = DEX.Theme.Accent,
	Font = Enum.Font.GothamMedium,
	Text = "Сканировать remotes",
	TextColor3 = DEX.Theme.Text,
	TextSize = 12,
	BorderSizePixel = 0,
	Parent = listHolder,
})
DEX.corner(rescanBtn, 6)

local listScroll = DEX.makeScroll(listHolder)
listScroll.Position = UDim2.new(0, 0, 0, 62)
listScroll.Size = UDim2.new(1, 0, 1, -62)
DEX.new("UIListLayout", {
	Padding = UDim.new(0, 1),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = listScroll,
})

-- ПРАВО ВЕРХ: детали + fire
local detailHolder = DEX.new("Frame", {
	Size = UDim2.new(1, -254, 0, 168),
	Position = UDim2.new(0, 246, 0, 34),
	BackgroundColor3 = DEX.Theme.Panel,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = page,
})
DEX.corner(detailHolder, 8)

local detailLabel = DEX.new("TextLabel", {
	Size = UDim2.new(1, -16, 0, 56),
	Position = UDim2.new(0, 8, 0, 6),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "Выбери remote слева",
	TextColor3 = DEX.Theme.Text,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	Parent = detailHolder,
})

local argsBox = DEX.new("TextBox", {
	Size = UDim2.new(1, -16, 0, 44),
	Position = UDim2.new(0, 8, 0, 64),
	BackgroundColor3 = DEX.Theme.Panel2,
	Font = Enum.Font.Code,
	PlaceholderText = 'Аргументы, напр: 1, "hi", true, workspace',
	Text = "",
	TextColor3 = DEX.Theme.Text,
	PlaceholderColor3 = DEX.Theme.SubText,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	ClearTextOnFocus = false,
	MultiLine = true,
	BorderSizePixel = 0,
	Parent = detailHolder,
})
DEX.corner(argsBox, 6)
DEX.new("UIPadding", {
	PaddingLeft = UDim.new(0, 6),
	PaddingTop = UDim.new(0, 4),
	Parent = argsBox,
})

local function detailButton(text, scaleX, offsetX, color)
	local btn = DEX.new("TextButton", {
		Size = UDim2.new(0, 96, 0, 24),
		Position = UDim2.new(scaleX, offsetX, 1, -30),
		BackgroundColor3 = color,
		Font = Enum.Font.GothamMedium,
		Text = text,
		TextColor3 = DEX.Theme.Text,
		TextSize = 12,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Parent = detailHolder,
	})
	DEX.corner(btn, 6)
	return btn
end

local fireBtn  = detailButton("Fire / Invoke", 0, 8, DEX.Theme.Accent)
local blockBtn = detailButton("Block: OFF", 0, 112, DEX.Theme.Panel2)
local copyPathBtn = detailButton("Copy Path", 0, 216, DEX.Theme.Panel2)

-- ПРАВО НИЗ: лог вызовов
local logHolder = DEX.new("Frame", {
	Size = UDim2.new(1, -254, 1, -212),
	Position = UDim2.new(0, 246, 0, 208),
	BackgroundColor3 = DEX.Theme.Panel,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = page,
})
DEX.corner(logHolder, 8)

local logTitle = DEX.new("TextLabel", {
	Size = UDim2.new(1, -90, 0, 24),
	Position = UDim2.new(0, 8, 0, 4),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "Лог вызовов (исходящие)",
	TextColor3 = DEX.Theme.Text,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = logHolder,
})

local clearLogBtn = DEX.new("TextButton", {
	Size = UDim2.new(0, 70, 0, 20),
	Position = UDim2.new(1, -78, 0, 6),
	BackgroundColor3 = DEX.Theme.Bad,
	Font = Enum.Font.GothamMedium,
	Text = "Очистить",
	TextColor3 = DEX.Theme.Text,
	TextSize = 11,
	BorderSizePixel = 0,
	Parent = logHolder,
})
DEX.corner(clearLogBtn, 5)

local logScroll = DEX.makeScroll(logHolder)
logScroll.Position = UDim2.new(0, 0, 0, 30)
logScroll.Size = UDim2.new(1, 0, 1, -30)
DEX.new("UIListLayout", {
	Padding = UDim.new(0, 1),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = logScroll,
})

----------------------------------------------------------------
-- ЛОГ
----------------------------------------------------------------
function DEX.Remotes.AddLog(name, method, preview)
	local entry = {
		time = os.date("%H:%M:%S"),
		name = name,
		method = method,
		preview = preview,
	}
	table.insert(DEX.Remotes.Log, 1, entry)
	-- кап лога
	while #DEX.Remotes.Log > 200 do
		table.remove(DEX.Remotes.Log)
	end
	DEX.Remotes.RenderLog()
end

function DEX.Remotes.RenderLog()
	for _, child in pairs(logScroll:GetChildren()) do
		if child:IsA("TextLabel") then
			pcall(function() child:Destroy() end)
		end
	end
	for index, entry in ipairs(DEX.Remotes.Log) do
		DEX.new("TextLabel", {
			Size = UDim2.new(1, -8, 0, 18),
			BackgroundColor3 = (index % 2 == 0) and DEX.Theme.Panel or DEX.Theme.Panel2,
			Font = Enum.Font.Code,
			Text = "[" .. entry.time .. "] " .. entry.name
				.. " :" .. entry.method .. "  ->  " .. entry.preview,
			TextColor3 = DEX.Theme.SubText,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BorderSizePixel = 0,
			LayoutOrder = index,
			Parent = logScroll,
		})
	end
end

----------------------------------------------------------------
-- ВЫЗОВ REMOTE (через DEX) + БЛОКИРОВКА
----------------------------------------------------------------
local function fireRemote(inst, argsTable, count)
	local cls = "RemoteEvent"
	pcall(function() cls = inst.ClassName end)
	local nm = "?"
	pcall(function() nm = inst.Name end)

	if DEX.Remotes.Blocked[inst] then
		DEX.Remotes.AddLog(nm, cls .. " [BLOCKED]", argPreview(argsTable, count))
		DEX.notify("Remote заблокирован — вызов не отправлен")
		return
	end

	local method = "FireServer"
	local result = nil
	local ok = false

	if cls == "RemoteEvent" or cls == "UnreliableRemoteEvent" then
		method = "FireServer"
		ok = pcall(function()
			inst:FireServer(unpackArgs(argsTable, count))
		end)
	elseif cls == "RemoteFunction" then
		method = "InvokeServer"
		ok = pcall(function()
			result = inst:InvokeServer(unpackArgs(argsTable, count))
		end)
	elseif cls == "BindableEvent" then
		method = "Fire"
		ok = pcall(function()
			inst:Fire(unpackArgs(argsTable, count))
		end)
	elseif cls == "BindableFunction" then
		method = "Invoke"
		ok = pcall(function()
			result = inst:Invoke(unpackArgs(argsTable, count))
		end)
	else
		DEX.notify("Неизвестный тип remote: " .. cls)
		return
	end

	DEX.Remotes.AddLog(nm, method, argPreview(argsTable, count))
	if ok then
		local extra = ""
		if result ~= nil then
			extra = "  ->  return: " .. tostring(result)
		end
		DEX.notify("Отправлено: " .. nm .. extra)
	else
		DEX.notify("Ошибка вызова remote")
	end
end

----------------------------------------------------------------
-- ВЫБОР REMOTE / ДЕТАЛИ
----------------------------------------------------------------
local function getPath(inst)
	local p = nil
	pcall(function() p = inst:GetFullName() end)
	return p or "?"
end

local function updateBlockBtn()
	local inst = DEX.Remotes.Selected
	if inst and DEX.Remotes.Blocked[inst] then
		blockBtn.Text = "Block: ON"
		blockBtn.BackgroundColor3 = DEX.Theme.Bad
	else
		blockBtn.Text = "Block: OFF"
		blockBtn.BackgroundColor3 = DEX.Theme.Panel2
	end
end

local function selectRemote(inst)
	DEX.Remotes.Selected = inst
	local nm, cls = "?", "?"
	pcall(function() nm = inst.Name end)
	pcall(function() cls = inst.ClassName end)
	detailLabel.Text = "Имя: " .. nm .. "\nКласс: " .. cls
		.. "\nПуть: " .. getPath(inst)
	updateBlockBtn()
end

----------------------------------------------------------------
-- СПИСОК REMOTES
----------------------------------------------------------------
local function clearList()
	for _, child in pairs(listScroll:GetChildren()) do
		if child:IsA("TextButton") then
			pcall(function() child:Destroy() end)
		end
	end
end

local function renderList()
	clearList()
	local filter = string.lower(DEX.Remotes.Filter)
	local order = 0
	for _, inst in ipairs(DEX.Remotes.List) do
		local nm, cls = "?", "RemoteEvent"
		pcall(function() nm = inst.Name end)
		pcall(function() cls = inst.ClassName end)
		local show = (filter == "" or string.find(string.lower(nm), filter, 1, true) ~= nil)
		if show then
			order = order + 1
			local tag = "RE"
			if cls == "RemoteFunction" then tag = "RF"
			elseif cls == "BindableEvent" then tag = "BE"
			elseif cls == "BindableFunction" then tag = "BF"
			elseif cls == "UnreliableRemoteEvent" then tag = "UR" end

			local row = DEX.new("TextButton", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundColor3 = DEX.Theme.Panel,
				Font = Enum.Font.Gotham,
				Text = "[" .. tag .. "] " .. nm,
				TextColor3 = DEX.Theme.SubText,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				LayoutOrder = order,
				Parent = listScroll,
			})
			DEX.new("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = row })
			DEX.connect(row.MouseEnter, function()
				row.BackgroundColor3 = DEX.Theme.Hover
			end)
			DEX.connect(row.MouseLeave, function()
				row.BackgroundColor3 = DEX.Theme.Panel
			end)
			DEX.connect(row.MouseButton1Click, function()
				selectRemote(inst)
			end)
		end
		if order >= 800 then
			break
		end
	end
end

local function scanRemotes()
	DEX.Remotes.List = {}
	local descendants = {}
	pcall(function()
		descendants = game:GetDescendants()
	end)
	for _, inst in ipairs(descendants) do
		local isRemote = false
		pcall(function()
			isRemote = inst:IsA("RemoteEvent")
				or inst:IsA("RemoteFunction")
				or inst:IsA("BindableEvent")
				or inst:IsA("BindableFunction")
				or inst:IsA("UnreliableRemoteEvent")
		end)
		if isRemote then
			table.insert(DEX.Remotes.List, inst)
		end
	end
	DEX.notify("Найдено remotes: " .. tostring(#DEX.Remotes.List))
	renderList()
end

----------------------------------------------------------------
-- ДЕЙСТВИЯ
----------------------------------------------------------------
DEX.connect(fireBtn.MouseButton1Click, function()
	local inst = DEX.Remotes.Selected
	if not inst then
		DEX.notify("Сначала выбери remote")
		return
	end
	local args, count, ok = parseArgs(argsBox.Text)
	if not ok then
		DEX.notify("Ошибка в аргументах (синтаксис Lua)")
		return
	end
	fireRemote(inst, args, count)
end)

DEX.connect(blockBtn.MouseButton1Click, function()
	local inst = DEX.Remotes.Selected
	if not inst then
		return
	end
	DEX.Remotes.Blocked[inst] = not DEX.Remotes.Blocked[inst]
	updateBlockBtn()
end)

DEX.connect(copyPathBtn.MouseButton1Click, function()
	local inst = DEX.Remotes.Selected
	if not inst then
		return
	end
	pcall(function()
		setclipboard(getPath(inst))
	end)
	DEX.notify("Путь скопирован")
end)

DEX.connect(clearLogBtn.MouseButton1Click, function()
	DEX.Remotes.Log = {}
	DEX.Remotes.RenderLog()
end)

DEX.connect(filterBox:GetPropertyChangedSignal("Text"), function()
	DEX.Remotes.Filter = filterBox.Text
end)
DEX.connect(filterBox.FocusLost, function()
	renderList()
end)
DEX.connect(rescanBtn.MouseButton1Click, function()
	scanRemotes()
end)

----------------------------------------------------------------
-- СТАРТ
----------------------------------------------------------------
tryEnableFullSpy()
if DEX.Remotes.SpyActive then
	banner.Text = "  Remote Spy: ПОЛНЫЙ режим (namecall hook активен)"
	banner.TextColor3 = DEX.Theme.Good
else
	banner.Text = "  Remote Spy: пассивный (Solara без hook) — логируются вызовы из DEX"
	banner.TextColor3 = DEX.Theme.SubText
end

DEX.Remotes.RenderLog()
scanRemotes()

print("[DEX] PART 4/6 Remotes Panel загружена. SpyActive=" .. tostring(DEX.Remotes.SpyActive))
