--==================================================================
-- DEX EXPLORER for Solara (Luau) | PART 3/6 : SCRIPT VIEWER
--==================================================================

assert(getgenv().DEX and getgenv().DEX.Loaded and getgenv().DEX.Loaded.Core,
	"[DEX] Сначала запусти PART 1 (Foundation)")

local DEX = getgenv().DEX
DEX.Loaded.ScriptViewer = true

DEX.Scripts = DEX.Scripts or {
	List = {},        -- найденные скрипты
	Tabs = {},        -- открытые вкладки { inst, source }
	Active = nil,     -- индекс активной вкладки
	Filter = "",
	CodeSearch = "",
}

----------------------------------------------------------------
-- ТОКЕНАЙЗЕР LUAU (подсветка через RichText)
----------------------------------------------------------------
local COLORS = {
	keyword  = "#f92672",
	builtin  = "#66d9ef",
	string   = "#a6e22e",
	number   = "#ae81ff",
	comment  = "#75715e",
	operator = "#f8f8f2",
	ident    = "#f8f8f2",
	match    = "#ffd866",
}

local KEYWORDS = {
	["and"]=true,["break"]=true,["do"]=true,["else"]=true,["elseif"]=true,
	["end"]=true,["false"]=true,["for"]=true,["function"]=true,["if"]=true,
	["in"]=true,["local"]=true,["nil"]=true,["not"]=true,["or"]=true,
	["repeat"]=true,["return"]=true,["then"]=true,["true"]=true,["until"]=true,
	["while"]=true,["continue"]=true,["export"]=true,["type"]=true,
}

local BUILTINS = {
	["game"]=true,["workspace"]=true,["script"]=true,["self"]=true,
	["math"]=true,["table"]=true,["string"]=true,["task"]=true,["os"]=true,
	["coroutine"]=true,["pairs"]=true,["ipairs"]=true,["next"]=true,
	["print"]=true,["warn"]=true,["error"]=true,["assert"]=true,
	["pcall"]=true,["xpcall"]=true,["select"]=true,["typeof"]=true,
	["type"]=true,["tostring"]=true,["tonumber"]=true,["unpack"]=true,
	["setmetatable"]=true,["getmetatable"]=true,["rawget"]=true,["rawset"]=true,
	["tick"]=true,["wait"]=true,["spawn"]=true,["delay"]=true,["Instance"]=true,
	["Vector3"]=true,["Vector2"]=true,["CFrame"]=true,["Color3"]=true,
	["UDim2"]=true,["UDim"]=true,["Enum"]=true,["BrickColor"]=true,
}

local function escapeRich(s)
	s = string.gsub(s, "&", "&amp;")
	s = string.gsub(s, "<", "&lt;")
	s = string.gsub(s, ">", "&gt;")
	s = string.gsub(s, '"', "&quot;")
	return s
end

local function span(color, text)
	return '<font color="' .. color .. '">' .. escapeRich(text) .. '</font>'
end

-- проверка символа
local function isAlpha(c)
	return string.match(c, "[%a_]") ~= nil
end
local function isAlphaNum(c)
	return string.match(c, "[%w_]") ~= nil
end
local function isDigit(c)
	return string.match(c, "%d") ~= nil
end

-- основной токенайзер -> RichText
local function highlightLuau(src)
	local out = {}
	local i = 1
	local len = #src

	while i <= len do
		local c = string.sub(src, i, i)

		-- перевод строки / пробелы
		if c == "\n" or c == "\r" or c == " " or c == "\t" then
			table.insert(out, escapeRich(c))
			i = i + 1
		-- комментарии
		elseif c == "-" and string.sub(src, i + 1, i + 1) == "-" then
			local j = i + 2
			-- длинный комментарий --[[ ... ]] или --[=[ ]=]
			if string.sub(src, j, j) == "[" then
				local eq = ""
				local k = j + 1
				while string.sub(src, k, k) == "=" do
					eq = eq .. "="
					k = k + 1
				end
				if string.sub(src, k, k) == "[" then
					local closeTag = "]" .. eq .. "]"
					local endPos = string.find(src, closeTag, k + 1, true)
					local stop = endPos and (endPos + #closeTag - 1) or len
					table.insert(out, span(COLORS.comment, string.sub(src, i, stop)))
					i = stop + 1
				else
					-- обычный однострочный
					local nl = string.find(src, "\n", j, true)
					local stop = nl and (nl - 1) or len
					table.insert(out, span(COLORS.comment, string.sub(src, i, stop)))
					i = stop + 1
				end
			else
				local nl = string.find(src, "\n", j, true)
				local stop = nl and (nl - 1) or len
				table.insert(out, span(COLORS.comment, string.sub(src, i, stop)))
				i = stop + 1
			end
		-- длинные строки [[ ]] / [=[ ]=]
		elseif c == "[" and (string.sub(src, i + 1, i + 1) == "[" or string.sub(src, i + 1, i + 1) == "=") then
			local eq = ""
			local k = i + 1
			while string.sub(src, k, k) == "=" do
				eq = eq .. "="
				k = k + 1
			end
			if string.sub(src, k, k) == "[" then
				local closeTag = "]" .. eq .. "]"
				local endPos = string.find(src, closeTag, k + 1, true)
				local stop = endPos and (endPos + #closeTag - 1) or len
				table.insert(out, span(COLORS.string, string.sub(src, i, stop)))
				i = stop + 1
			else
				table.insert(out, escapeRich(c))
				i = i + 1
			end
		-- обычные строки " ' 
		elseif c == '"' or c == "'" then
			local quote = c
			local j = i + 1
			local escaped = false
			while j <= len do
				local cj = string.sub(src, j, j)
				if escaped then
					escaped = false
				elseif cj == "\\" then
					escaped = true
				elseif cj == quote or cj == "\n" then
					break
				end
				j = j + 1
			end
			table.insert(out, span(COLORS.string, string.sub(src, i, j)))
			i = j + 1
		-- числа
		elseif isDigit(c) or (c == "." and isDigit(string.sub(src, i + 1, i + 1))) then
			local j = i
			while j <= len do
				local cj = string.sub(src, j, j)
				if isAlphaNum(cj) or cj == "." or cj == "x" or cj == "X" then
					j = j + 1
				else
					break
				end
			end
			table.insert(out, span(COLORS.number, string.sub(src, i, j - 1)))
			i = j
		-- идентификаторы / ключевые слова
		elseif isAlpha(c) then
			local j = i
			while j <= len and isAlphaNum(string.sub(src, j, j)) do
				j = j + 1
			end
			local word = string.sub(src, i, j - 1)
			if KEYWORDS[word] then
				table.insert(out, span(COLORS.keyword, word))
			elseif BUILTINS[word] then
				table.insert(out, span(COLORS.builtin, word))
			else
				table.insert(out, span(COLORS.ident, word))
			end
			i = j
		-- всё остальное (операторы/пунктуация)
		else
			table.insert(out, escapeRich(c))
			i = i + 1
		end
	end

	return table.concat(out)
end

-- режим поиска: плоский текст с подсветкой совпадений
local function highlightSearch(src, query)
	if query == "" then
		return highlightLuau(src)
	end
	local out = {}
	local lowerSrc = string.lower(src)
	local lowerQ = string.lower(query)
	local qlen = #query
	local pos = 1
	local count = 0
	while true do
		local found = string.find(lowerSrc, lowerQ, pos, true)
		if not found then
			table.insert(out, span(COLORS.ident, string.sub(src, pos)))
			break
		end
		if found > pos then
			table.insert(out, span(COLORS.ident, string.sub(src, pos, found - 1)))
		end
		local matchText = string.sub(src, found, found + qlen - 1)
		table.insert(out, '<font color="' .. COLORS.match .. '"><b>'
			.. escapeRich(matchText) .. '</b></font>')
		pos = found + qlen
		count = count + 1
		if count > 4000 then
			table.insert(out, span(COLORS.ident, string.sub(src, pos)))
			break
		end
	end
	DEX.Scripts.MatchCount = count
	return table.concat(out)
end

----------------------------------------------------------------
-- ПОЛУЧЕНИЕ ИСХОДНИКА (декомпайлер-фолбэк)
----------------------------------------------------------------
local MAX_SRC = 60000

local function getScriptSource(inst)
	-- 1) прямой доступ к Source (модули/анхопнутые)
	local ok, src = pcall(function()
		return inst.Source
	end)
	if ok and type(src) == "string" and src ~= "" then
		return src, "Source"
	end

	-- 2) попытки декомпиляторов (если вдруг есть в окружении)
	local d = nil
	pcall(function()
		if decompile then
			d = decompile(inst)
		end
	end)
	if type(d) == "string" and d ~= "" then
		return d, "decompile"
	end

	pcall(function()
		if getscriptsource then
			d = getscriptsource(inst)
		end
	end)
	if type(d) == "string" and d ~= "" then
		return d, "getscriptsource"
	end

	-- 3) честный фолбэк: Solara не умеет декомпилировать байткод
	local nm = "?"
	local cls = "Script"
	pcall(function() nm = inst.Name end)
	pcall(function() cls = inst.ClassName end)
	local notice = "-- [DEX] Исходник недоступен.\n"
		.. "-- Класс: " .. cls .. "  |  Имя: " .. nm .. "\n"
		.. "-- Solara (39% sUNC) не имеет декомпилятора байткода\n"
		.. "-- (нет getscriptbytecode / decompile / getscriptclosure).\n"
		.. "-- .Source читается только у ModuleScript-ов и незащищённых скриптов.\n"
	return notice, "unavailable"
end

----------------------------------------------------------------
-- СТРАНИЦА И РАЗМЕТКА
----------------------------------------------------------------
local page = DEX.addTab("Scripts", 2)

-- ЛЕВО: список скриптов
local listHolder = DEX.new("Frame", {
	Size = UDim2.new(0, 220, 1, -16),
	Position = UDim2.new(0, 8, 0, 8),
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
	PlaceholderText = "Фильтр скриптов...",
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
	Text = "Сканировать скрипты",
	TextColor3 = DEX.Theme.Text,
	TextSize = 12,
	BorderSizePixel = 0,
	AutoButtonColor = true,
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

-- ПРАВО: вьювер
local viewHolder = DEX.new("Frame", {
	Size = UDim2.new(1, -244, 1, -16),
	Position = UDim2.new(0, 236, 0, 8),
	BackgroundColor3 = DEX.Theme.Panel,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = page,
})
DEX.corner(viewHolder, 8)

-- панель вкладок
local tabStrip = DEX.new("ScrollingFrame", {
	Size = UDim2.new(1, 0, 0, 26),
	BackgroundColor3 = DEX.Theme.Panel2,
	BorderSizePixel = 0,
	ScrollBarThickness = 2,
	ScrollingDirection = Enum.ScrollingDirection.X,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.X,
	Parent = viewHolder,
})
DEX.new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 2),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = tabStrip,
})

-- тулбар (поиск в коде + действия)
local toolbar = DEX.new("Frame", {
	Size = UDim2.new(1, 0, 0, 28),
	Position = UDim2.new(0, 0, 0, 26),
	BackgroundColor3 = DEX.Theme.Panel2,
	BorderSizePixel = 0,
	Parent = viewHolder,
})

local codeSearchBox = DEX.new("TextBox", {
	Size = UDim2.new(0.45, 0, 0, 20),
	Position = UDim2.new(0, 6, 0, 4),
	BackgroundColor3 = DEX.Theme.Panel,
	Font = Enum.Font.Gotham,
	PlaceholderText = "Поиск в коде...",
	Text = "",
	TextColor3 = DEX.Theme.Text,
	PlaceholderColor3 = DEX.Theme.SubText,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	ClearTextOnFocus = false,
	BorderSizePixel = 0,
	Parent = toolbar,
})
DEX.corner(codeSearchBox, 5)
DEX.new("UIPadding", { PaddingLeft = UDim.new(0, 6), Parent = codeSearchBox })

local function toolButton(text, scaleX, offsetX, color)
	local btn = DEX.new("TextButton", {
		Size = UDim2.new(0, 70, 0, 20),
		Position = UDim2.new(scaleX, offsetX, 0, 4),
		BackgroundColor3 = color or DEX.Theme.Panel,
		Font = Enum.Font.GothamMedium,
		Text = text,
		TextColor3 = DEX.Theme.Text,
		TextSize = 12,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Parent = toolbar,
	})
	DEX.corner(btn, 5)
	return btn
end

local saveBtn = toolButton("Save", 0.48, 6, DEX.Theme.Panel)
local runBtn  = toolButton("Run", 0.48, 82, DEX.Theme.Accent)
local copyBtn = toolButton("Copy", 0.48, 158, DEX.Theme.Panel)

-- область кода
local codeScroll = DEX.makeScroll(viewHolder)
codeScroll.Position = UDim2.new(0, 0, 0, 54)
codeScroll.Size = UDim2.new(1, 0, 1, -54)
codeScroll.ScrollingDirection = Enum.ScrollingDirection.XY
codeScroll.CanvasSize = UDim2.new(0, 2000, 0, 0)
codeScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local codeLabel = DEX.new("TextLabel", {
	Size = UDim2.new(1, -16, 0, 0),
	Position = UDim2.new(0, 8, 0, 4),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Font = Enum.Font.Code,
	RichText = true,
	Text = "",
	TextColor3 = DEX.Theme.Text,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = false,
	Parent = codeScroll,
})

----------------------------------------------------------------
-- РЕНДЕР АКТИВНОГО КОДА
----------------------------------------------------------------
local function renderActiveCode()
	local idx = DEX.Scripts.Active
	if not idx or not DEX.Scripts.Tabs[idx] then
		codeLabel.Text = span(COLORS.comment, "-- Откройте скрипт слева")
		return
	end
	local tab = DEX.Scripts.Tabs[idx]
	local src = tab.source
	if #src > MAX_SRC then
		src = string.sub(src, 1, MAX_SRC)
			.. "\n\n-- [DEX] ... обрезано (" .. tostring(#tab.source) .. " символов)"
	end
	local query = DEX.Scripts.CodeSearch
	if query ~= "" then
		codeLabel.Text = highlightSearch(src, query)
	else
		codeLabel.Text = highlightLuau(src)
	end
end

----------------------------------------------------------------
-- ВКЛАДКИ
----------------------------------------------------------------
local function rebuildTabStrip()
	for _, child in pairs(tabStrip:GetChildren()) do
		if child:IsA("Frame") then
			pcall(function() child:Destroy() end)
		end
	end
	for index, tab in ipairs(DEX.Scripts.Tabs) do
		local isActive = (DEX.Scripts.Active == index)
		local nm = "?"
		pcall(function() nm = tab.inst.Name end)

		local holder = DEX.new("Frame", {
			Size = UDim2.new(0, 130, 1, 0),
			BackgroundColor3 = isActive and DEX.Theme.Selected or DEX.Theme.Panel,
			BorderSizePixel = 0,
			LayoutOrder = index,
			Parent = tabStrip,
		})

		local nameBtn = DEX.new("TextButton", {
			Size = UDim2.new(1, -20, 1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = nm,
			TextColor3 = isActive and DEX.Theme.Text or DEX.Theme.SubText,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = holder,
		})
		DEX.new("UIPadding", { PaddingLeft = UDim.new(0, 6), Parent = nameBtn })

		local closeBtn = DEX.new("TextButton", {
			Size = UDim2.new(0, 18, 1, 0),
			Position = UDim2.new(1, -18, 0, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = "×",
			TextColor3 = DEX.Theme.Bad,
			TextSize = 14,
			Parent = holder,
		})

		DEX.connect(nameBtn.MouseButton1Click, function()
			DEX.Scripts.Active = index
			rebuildTabStrip()
			renderActiveCode()
		end)
		DEX.connect(closeBtn.MouseButton1Click, function()
			table.remove(DEX.Scripts.Tabs, index)
			if DEX.Scripts.Active == index then
				DEX.Scripts.Active = #DEX.Scripts.Tabs > 0 and 1 or nil
			end
			rebuildTabStrip()
			renderActiveCode()
		end)
	end
end

local function openScript(inst)
	-- если уже открыт — активировать
	for index, tab in ipairs(DEX.Scripts.Tabs) do
		if tab.inst == inst then
			DEX.Scripts.Active = index
			rebuildTabStrip()
			renderActiveCode()
			return
		end
	end
	local src, mode = getScriptSource(inst)
	table.insert(DEX.Scripts.Tabs, { inst = inst, source = src, mode = mode })
	DEX.Scripts.Active = #DEX.Scripts.Tabs
	rebuildTabStrip()
	renderActiveCode()
	if mode == "unavailable" then
		DEX.notify("Исходник недоступен (нет декомпилятора)")
	end
end

----------------------------------------------------------------
-- СПИСОК СКРИПТОВ
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
	local filter = string.lower(DEX.Scripts.Filter)
	local order = 0
	for _, inst in ipairs(DEX.Scripts.List) do
		local nm = "?"
		local cls = "Script"
		pcall(function() nm = inst.Name end)
		pcall(function() cls = inst.ClassName end)
		local show = (filter == "" or string.find(string.lower(nm), filter, 1, true) ~= nil)
		if show then
			order = order + 1
			local tag = "S"
			if cls == "LocalScript" then tag = "L"
			elseif cls == "ModuleScript" then tag = "M" end

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
				openScript(inst)
			end)
		end
		if order >= 800 then
			break
		end
	end
end

local function scanScripts()
	DEX.Scripts.List = {}
	local descendants = {}
	pcall(function()
		descendants = game:GetDescendants()
	end)
	for _, inst in ipairs(descendants) do
		local isScript = false
		pcall(function()
			isScript = inst:IsA("Script")
				or inst:IsA("LocalScript")
				or inst:IsA("ModuleScript")
		end)
		if isScript then
			table.insert(DEX.Scripts.List, inst)
		end
	end
	DEX.notify("Найдено скриптов: " .. tostring(#DEX.Scripts.List))
	renderList()
end

----------------------------------------------------------------
-- ДЕЙСТВИЯ ТУЛБАРА
----------------------------------------------------------------
local function sanitizeName(name)
	local clean = string.gsub(name, "[^%w_%-]", "_")
	if clean == "" then
		clean = "script"
	end
	return clean
end

DEX.connect(saveBtn.MouseButton1Click, function()
	local idx = DEX.Scripts.Active
	if not idx or not DEX.Scripts.Tabs[idx] then
		DEX.notify("Нет активного скрипта")
		return
	end
	local tab = DEX.Scripts.Tabs[idx]
	local nm = "script"
	pcall(function() nm = tab.inst.Name end)
	local fileName = "DEX_" .. sanitizeName(nm) .. ".luau"
	local ok = pcall(function()
		writefile(fileName, tab.source)
	end)
	if ok then
		DEX.notify("Сохранено: " .. fileName)
	else
		DEX.notify("Ошибка записи файла")
	end
end)

DEX.connect(runBtn.MouseButton1Click, function()
	local idx = DEX.Scripts.Active
	if not idx or not DEX.Scripts.Tabs[idx] then
		DEX.notify("Нет активного скрипта")
		return
	end
	local tab = DEX.Scripts.Tabs[idx]
	task.spawn(function()
		local fn, err = nil, nil
		local okComp = pcall(function()
			fn, err = loadstring(tab.source)
		end)
		if okComp and fn then
			local okRun, runErr = pcall(fn)
			if okRun then
				DEX.notify("Скрипт выполнен")
			else
				DEX.notify("Ошибка выполнения: " .. tostring(runErr))
			end
		else
			DEX.notify("Ошибка компиляции: " .. tostring(err))
		end
	end)
end)

DEX.connect(copyBtn.MouseButton1Click, function()
	local idx = DEX.Scripts.Active
	if not idx or not DEX.Scripts.Tabs[idx] then
		return
	end
	pcall(function()
		setclipboard(DEX.Scripts.Tabs[idx].source)
	end)
	DEX.notify("Код скопирован")
end)

----------------------------------------------------------------
-- ПОДКЛЮЧЕНИЯ ПОИСКА
----------------------------------------------------------------
DEX.connect(filterBox:GetPropertyChangedSignal("Text"), function()
	DEX.Scripts.Filter = filterBox.Text
end)
DEX.connect(filterBox.FocusLost, function()
	renderList()
end)
DEX.connect(codeSearchBox:GetPropertyChangedSignal("Text"), function()
	DEX.Scripts.CodeSearch = codeSearchBox.Text
end)
DEX.connect(codeSearchBox.FocusLost, function()
	renderActiveCode()
	if DEX.Scripts.CodeSearch ~= "" then
		DEX.notify("Совпадений: " .. tostring(DEX.Scripts.MatchCount or 0))
	end
end)
DEX.connect(rescanBtn.MouseButton1Click, function()
	scanScripts()
end)

----------------------------------------------------------------
-- СТАРТ
----------------------------------------------------------------
renderActiveCode()
scanScripts()

print("[DEX] PART 3/6 Script Viewer загружена.")
