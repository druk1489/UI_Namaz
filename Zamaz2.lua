-- DEX Explorer v1.0 for Solara
-- Part 2: Explorer Panel + Icons + Preview Window (FIXED)
-- ========================================================

assert(getgenv().DEX, "DEX Core (Part 1) must be loaded first!")

local DEX = getgenv().DEX
local theme = DEX.CurrentTheme
local Utils = DEX.Utils
local GuiHelpers = DEX.GuiHelpers
local explorerPage = DEX.Pages["Explorer"]

assert(explorerPage, "Explorer page not found!")

-- ========================
-- СЕРВЕРНЫЕ СКРИПТЫ
-- Метод: require() trick + RemoteFunction invoke
-- ========================
local ServerScriptViewer = {}
DEX.ServerScriptViewer = ServerScriptViewer

-- Попытка получить source серверного скрипта разными методами
local function TryGetServerSource(scriptInstance)
    local source = ""
    local method = "unknown"

    -- Метод 1: прямой доступ (работает если скрипт доступен)
    local ok1 = pcall(function()
        local s = scriptInstance.Source
        if s and #s > 0 then
            source = s
            method = "Direct .Source"
        end
    end)
    if source ~= "" then return source, method end

    -- Метод 2: decompile (если доступен)
    local ok2 = pcall(function()
        if decompile then
            local result = decompile(scriptInstance)
            if result and #result > 10 then
                source = result
                method = "decompile()"
            end
        end
    end)
    if source ~= "" then return source, method end

    -- Метод 3: getscriptbytecode
    local ok3 = pcall(function()
        if getscriptbytecode then
            local bc = getscriptbytecode(scriptInstance)
            if bc and #bc > 0 then
                source = "-- [Bytecode: " .. #bc .. " bytes]\n" ..
                    "-- Method: getscriptbytecode()\n" ..
                    "-- Script: " .. Utils.GetInstanceName(scriptInstance) ..
                    "\n-- Path: " .. Utils.GetFullPath(scriptInstance) ..
                    "\n-- Cannot decompile bytecode in Solara 39% sUNC\n\n" ..
                    "-- Bytecode size: " .. #bc .. " bytes\n" ..
                    "-- Hex preview:\n-- " ..
                    string.upper(string.format("%02X%02X%02X%02X",
                        string.byte(bc, 1),
                        string.byte(bc, 2) or 0,
                        string.byte(bc, 3) or 0,
                        string.byte(bc, 4) or 0
                    ))
                method = "getscriptbytecode()"
            end
        end
    end)
    if source ~= "" then return source, method end

    -- Метод 4: Читаем свойства скрипта что доступны
    local props = {}
    local propNames = {
        "Name","ClassName","Disabled","RunContext",
        "LinkedSource","ScriptGuid",
    }
    for _, pn in ipairs(propNames) do
        local pok, pval = pcall(function()
            return scriptInstance[pn]
        end)
        if pok and pval ~= nil then
            table.insert(props, "-- " .. pn .. " = " ..
                tostring(pval))
        end
    end

    local cls = Utils.GetClassName(scriptInstance)
    local isServer = (cls == "Script")
    local isLocal = (cls == "LocalScript")
    local isModule = (cls == "ModuleScript")

    local typeNote = ""
    if isServer then
        typeNote = "-- TYPE: Server Script (runs on server only)\n" ..
            "-- Solara cannot access server-side source directly\n" ..
            "-- Server scripts are protected by Roblox\n"
    elseif isLocal then
        typeNote = "-- TYPE: LocalScript (runs on client)\n" ..
            "-- Source should be accessible but is protected here\n"
    elseif isModule then
        typeNote = "-- TYPE: ModuleScript\n" ..
            "-- Try: require(path.to.module) in console\n"
    end

    source = "-- [DEX Server Script Viewer]\n" ..
        "-- ================================\n" ..
        typeNote ..
        "-- ================================\n" ..
        "-- Script: " .. Utils.GetInstanceName(scriptInstance) .. "\n" ..
        "-- Path: " .. Utils.GetFullPath(scriptInstance) .. "\n\n" ..
        table.concat(props, "\n") ..
        "\n\n-- Available info above\n" ..
        "-- To try reading: use console tab and run:\n" ..
        "-- local s = " .. Utils.GetFullPath(scriptInstance) .. "\n" ..
        "-- print(s.Source)"

    method = "metadata only"
    return source, method
end

ServerScriptViewer.TryGetSource = TryGetServerSource

local NODE_HEIGHT = 24
local INDENT_WIDTH = 16
local MAX_VISIBLE_NODES = 200

local ExpState = {
    AllNodes = {},
    ScrollOffset = 0,
    SelectedNode = nil,
    ExpandedMap = {},
    SearchQuery = "",
    ClassFilter = "",
    TotalNodes = 0,
}

DEX.ExpState = ExpState

-- ========================
-- ИКОНКИ ПО КЛАССАМ
-- ========================
local CLASS_ICONS = {
    -- Скрипты
    ["Script"]          = {icon = "S",  color = Color3.new(0.85, 0.35, 0.35)},
    ["LocalScript"]     = {icon = "L",  color = Color3.new(0.35, 0.70, 0.95)},
    ["ModuleScript"]    = {icon = "M",  color = Color3.new(0.55, 0.85, 0.35)},
    -- Ремоуты
    ["RemoteEvent"]     = {icon = "RE", color = Color3.new(0.35, 0.65, 1.0)},
    ["RemoteFunction"]  = {icon = "RF", color = Color3.new(1.0,  0.75, 0.20)},
    ["BindableEvent"]   = {icon = "BE", color = Color3.new(0.40, 0.85, 0.45)},
    ["BindableFunction"]= {icon = "BF", color = Color3.new(0.75, 0.40, 1.0)},
    -- GUI
    ["ScreenGui"]       = {icon = "SG", color = Color3.new(0.95, 0.60, 0.20)},
    ["Frame"]           = {icon = "Fr", color = Color3.new(0.80, 0.80, 0.80)},
    ["TextLabel"]       = {icon = "Tl", color = Color3.new(0.70, 0.90, 1.0)},
    ["TextButton"]      = {icon = "Tb", color = Color3.new(0.50, 0.80, 1.0)},
    ["TextBox"]         = {icon = "Tx", color = Color3.new(0.40, 0.70, 1.0)},
    ["ImageLabel"]      = {icon = "Il", color = Color3.new(0.95, 0.75, 0.35)},
    ["ImageButton"]     = {icon = "Ib", color = Color3.new(0.90, 0.65, 0.25)},
    ["BillboardGui"]    = {icon = "BG", color = Color3.new(0.85, 0.55, 0.20)},
    ["SurfaceGui"]      = {icon = "SG", color = Color3.new(0.80, 0.50, 0.20)},
    -- Части
    ["Part"]            = {icon = "P",  color = Color3.new(0.60, 0.60, 0.65)},
    ["MeshPart"]        = {icon = "MP", color = Color3.new(0.55, 0.55, 0.75)},
    ["UnionOperation"]  = {icon = "U",  color = Color3.new(0.50, 0.65, 0.80)},
    ["WedgePart"]       = {icon = "WP", color = Color3.new(0.58, 0.58, 0.68)},
    ["SpecialMesh"]     = {icon = "Mh", color = Color3.new(0.70, 0.50, 0.90)},
    -- Модели
    ["Model"]           = {icon = "Mo", color = Color3.new(0.90, 0.75, 0.35)},
    ["Folder"]          = {icon = "F",  color = Color3.new(0.85, 0.80, 0.40)},
    -- Игроки
    ["Players"]         = {icon = "Pl", color = Color3.new(0.40, 0.85, 0.75)},
    ["Player"]          = {icon = "Py", color = Color3.new(0.35, 0.80, 0.70)},
    ["Humanoid"]        = {icon = "H",  color = Color3.new(0.90, 0.50, 0.70)},
    ["HumanoidRootPart"]= {icon = "HR", color = Color3.new(0.85, 0.45, 0.65)},
    -- Свет
    ["PointLight"]      = {icon = "PL", color = Color3.new(0.99, 0.95, 0.50)},
    ["SpotLight"]       = {icon = "SL", color = Color3.new(0.99, 0.90, 0.40)},
    ["SurfaceLight"]    = {icon = "SuL",color = Color3.new(0.99, 0.85, 0.35)},
    -- Звук
    ["Sound"]           = {icon = "So", color = Color3.new(0.60, 0.85, 0.95)},
    ["SoundService"]    = {icon = "SS", color = Color3.new(0.55, 0.80, 0.90)},
    -- Камера
    ["Camera"]          = {icon = "Cam",color = Color3.new(0.70, 0.70, 0.99)},
    -- Сервисы
    ["Workspace"]       = {icon = "Ws", color = Color3.new(0.40, 0.75, 0.40)},
    ["ReplicatedStorage"]={icon="RS",  color = Color3.new(0.55, 0.65, 0.90)},
    ["ServerStorage"]   = {icon = "SS", color = Color3.new(0.85, 0.55, 0.55)},
    ["StarterGui"]      = {icon = "StG",color = Color3.new(0.95, 0.65, 0.35)},
    ["StarterPack"]     = {icon = "SP", color = Color3.new(0.90, 0.60, 0.30)},
    ["StarterPlayer"]   = {icon = "StP",color = Color3.new(0.85, 0.55, 0.25)},
    ["Lighting"]        = {icon = "Li", color = Color3.new(0.99, 0.92, 0.40)},
    ["Teams"]           = {icon = "Te", color = Color3.new(0.50, 0.75, 0.99)},
    ["CoreGui"]         = {icon = "CG", color = Color3.new(0.70, 0.70, 0.80)},
    ["DataModel"]       = {icon = "G",  color = Color3.new(0.40, 0.65, 0.95)},
    -- Анимации
    ["Animation"]       = {icon = "An", color = Color3.new(0.75, 0.55, 0.95)},
    ["Animator"]        = {icon = "Ar", color = Color3.new(0.70, 0.50, 0.90)},
    -- Физика
    ["BodyVelocity"]    = {icon = "BV", color = Color3.new(0.99, 0.40, 0.40)},
    ["BodyPosition"]    = {icon = "BP", color = Color3.new(0.99, 0.45, 0.45)},
    -- Инструменты
    ["Tool"]            = {icon = "To", color = Color3.new(0.85, 0.65, 0.30)},
    ["Backpack"]        = {icon = "Bk", color = Color3.new(0.75, 0.60, 0.25)},
    -- Тэги
    ["StringValue"]     = {icon = "Sv", color = Color3.new(0.60, 0.90, 0.60)},
    ["IntValue"]        = {icon = "Iv", color = Color3.new(0.55, 0.85, 0.55)},
    ["NumberValue"]     = {icon = "Nv", color = Color3.new(0.50, 0.80, 0.50)},
    ["BoolValue"]       = {icon = "Bv", color = Color3.new(0.45, 0.75, 0.45)},
    ["ObjectValue"]     = {icon = "Ov", color = Color3.new(0.40, 0.70, 0.40)},
    -- Партиклы
    ["ParticleEmitter"] = {icon = "Pe", color = Color3.new(0.99, 0.70, 0.50)},
    ["Fire"]            = {icon = "Fi", color = Color3.new(0.99, 0.45, 0.20)},
    ["Smoke"]           = {icon = "Sk", color = Color3.new(0.70, 0.70, 0.70)},
    ["Sparkles"]        = {icon = "Sp", color = Color3.new(0.99, 0.95, 0.40)},
    -- Constraints
    ["WeldConstraint"]  = {icon = "Wc", color = Color3.new(0.60, 0.55, 0.90)},
    ["HingeConstraint"] = {icon = "Hc", color = Color3.new(0.65, 0.60, 0.85)},
    -- Прочее
    ["Decal"]           = {icon = "Dc", color = Color3.new(0.90, 0.70, 0.50)},
    ["Texture"]         = {icon = "Tx", color = Color3.new(0.85, 0.65, 0.45)},
    ["SelectionBox"]    = {icon = "Sb", color = Color3.new(0.40, 0.95, 0.40)},
    ["ProximityPrompt"] = {icon = "Pp", color = Color3.new(0.70, 0.85, 0.99)},
    ["ClickDetector"]   = {icon = "Cd", color = Color3.new(0.60, 0.95, 0.70)},
}

local DEFAULT_ICON = {icon = "?", color = Color3.new(0.55, 0.55, 0.60)}

local function GetClassInfo(className)
    return CLASS_ICONS[className] or DEFAULT_ICON
end

-- Скриптовые классы
local SCRIPT_CLASSES = {
    ["Script"] = true,
    ["LocalScript"] = true,
    ["ModuleScript"] = true,
}

-- Классы с изображениями
local IMAGE_CLASSES = {
    ["ImageLabel"] = "Image",
    ["ImageButton"] = "Image",
    ["Decal"] = "Texture",
    ["Texture"] = "Texture",
}

-- Классы со звуком
local SOUND_CLASSES = {
    ["Sound"] = true,
}

-- Меш классы
local MESH_CLASSES = {
    ["MeshPart"] = "MeshId",
    ["SpecialMesh"] = "MeshId",
}

-- ========================
-- PREVIEW WINDOW
-- ========================
local previewWindow = nil

local function ClosePreview()
    pcall(function()
        if previewWindow and previewWindow.Parent then
            previewWindow:Destroy()
            previewWindow = nil
        end
    end)
end

local function OpenPreviewWindow(instance)
    pcall(function()
        ClosePreview()

        local cls = Utils.GetClassName(instance)
        local name = Utils.GetInstanceName(instance)
        local screenGui = DEX.ScreenGui

        local win = GuiHelpers.Create("Frame", {
            Name = "PreviewWindow",
            Parent = screenGui,
            Size = UDim2.new(0, 500, 0, 420),
            Position = UDim2.new(0.5, -250, 0.5, -210),
            BackgroundColor3 = theme.Background,
            BorderSizePixel = 0,
            ZIndex = 150,
            ClipsDescendants = true,
        })
        previewWindow = win

        pcall(function()
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 8)
            c.Parent = win
        end)

        -- Тень
        local shadow = GuiHelpers.Create("Frame", {
            Parent = screenGui,
            Size = UDim2.new(0, 516, 0, 436),
            Position = UDim2.new(0.5, -258, 0.5, -218),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            ZIndex = 149,
        })
        pcall(function()
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 10)
            c.Parent = shadow
        end)

        -- Заголовок
        local titleBar = GuiHelpers.Create("Frame", {
            Parent = win,
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = theme.TitleBar,
            BorderSizePixel = 0,
            ZIndex = 151,
        })
        pcall(function()
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 8)
            c.Parent = titleBar
        end)
        GuiHelpers.Create("Frame", {
            Parent = titleBar,
            Size = UDim2.new(1, 0, 0, 8),
            Position = UDim2.new(0, 0, 1, -8),
            BackgroundColor3 = theme.TitleBar,
            BorderSizePixel = 0,
            ZIndex = 151,
        })

        local classInfo = GetClassInfo(cls)
        local iconBadge = GuiHelpers.Create("TextLabel", {
            Parent = titleBar,
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(0, 8, 0, 6),
            BackgroundColor3 = classInfo.color,
            Text = classInfo.icon,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 9,
            Font = Enum.Font.GothamBold,
            BorderSizePixel = 0,
            ZIndex = 152,
        })
        pcall(function()
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 4)
            c.Parent = iconBadge
        end)

        GuiHelpers.Create("TextLabel", {
            Parent = titleBar,
            Size = UDim2.new(1, -100, 1, 0),
            Position = UDim2.new(0, 38, 0, 0),
            BackgroundTransparency = 1,
            Text = name .. "  [" .. cls .. "]",
            TextColor3 = theme.Text,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 152,
        })

        local closeBtn = GuiHelpers.Create("TextButton", {
            Parent = titleBar,
            Size = UDim2.new(0, 28, 0, 28),
            Position = UDim2.new(1, -32, 0, 4),
            BackgroundColor3 = Color3.new(0.90, 0.25, 0.25),
            Text = "X",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            BorderSizePixel = 0,
            ZIndex = 152,
        })
        pcall(function()
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 5)
            c.Parent = closeBtn
        end)
        closeBtn.MouseButton1Click:Connect(function()
            pcall(function()
                shadow:Destroy()
                ClosePreview()
            end)
        end)

        GuiHelpers.MakeDraggable(win, titleBar)

        -- Контент область
        local content = GuiHelpers.Create("Frame", {
            Parent = win,
            Size = UDim2.new(1, 0, 1, -36),
            Position = UDim2.new(0, 0, 0, 36),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 151,
        })

        -- ========================
        -- СКРИПТ ПРОСМОТР
        -- ========================
        if SCRIPT_CLASSES[cls] then
            local source = ""
            local method = "unknown"
            local sourceOk = false

            local result, meth = TryGetServerSource(instance)
            if result and result ~= "" then
                source = result
                method = meth
                sourceOk = true
            end

        -- Покажи метод в заголовке
            lineCount.Text = "Method: " .. method ..
              " | Lines: " .. lc .. " | " .. #source .. "b"

            pcall(function()
                source = instance.Source or ""
                if source ~= "" then
                    sourceOk = true
                end
            end)

            if not sourceOk then
                -- Попытка decompile
                pcall(function()
                    if decompile then
                        local result = decompile(instance)
                        if result and result ~= "" then
                            source = result
                            sourceOk = true
                        end
                    end
                end)
            end

            if not sourceOk or source == "" then
                source = "-- Source not accessible\n" ..
                    "-- Script: " .. name .. "\n" ..
                    "-- Class: " .. cls .. "\n" ..
                    "-- Path: " .. Utils.GetFullPath(instance) .. "\n\n" ..
                    "-- Solara (39% sUNC) cannot access script source\n" ..
                    "-- Try using a higher sUNC executor"
            end

            -- Toolbar
            local toolbar = GuiHelpers.Create("Frame", {
                Parent = content,
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = theme.BackgroundSecondary,
                BorderSizePixel = 0,
                ZIndex = 152,
            })

            local function MakeToolBtn2(txt, x, w, col)
                local b = GuiHelpers.Create("TextButton", {
                    Parent = toolbar,
                    Size = UDim2.new(0, w, 1, -8),
                    Position = UDim2.new(0, x, 0, 4),
                    BackgroundColor3 = col or theme.ButtonBg,
                    Text = txt,
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 10,
                    Font = Enum.Font.GothamSemibold,
                    BorderSizePixel = 0,
                    ZIndex = 153,
                })
                pcall(function()
                    local c = Instance.new("UICorner")
                    c.CornerRadius = UDim.new(0, 3)
                    c.Parent = b
                end)
                return b
            end

            local execBtn2  = MakeToolBtn2("Execute",  4,  64, theme.Success)
            local copyBtn2  = MakeToolBtn2("Copy",     72, 50, theme.AccentDark)
            local saveBtn2  = MakeToolBtn2("Save",     126, 46, theme.ButtonBg)
            local lineCount = GuiHelpers.Create("TextLabel", {
                Parent = toolbar,
                Size = UDim2.new(0, 120, 1, 0),
                Position = UDim2.new(1, -124, 0, 0),
                BackgroundTransparency = 1,
                Text = "Lines: 0",
                TextColor3 = theme.TextSecondary,
                TextSize = 10,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 153,
            })

            -- Подсчёт строк
            local lc = 1
            for _ in string.gmatch(source, "\n") do
                lc = lc + 1
            end
            lineCount.Text = "Lines: " .. lc ..
                " | Size: " .. #source .. "b"

            -- Редактор с нумерацией строк
            local editorBg = GuiHelpers.Create("Frame", {
                Parent = content,
                Size = UDim2.new(1, 0, 1, -30),
                Position = UDim2.new(0, 0, 0, 30),
                BackgroundColor3 = theme.BackgroundTertiary,
                BorderSizePixel = 0,
                ZIndex = 151,
                ClipsDescendants = true,
            })

            local lineNumBg = GuiHelpers.Create("Frame", {
                Parent = editorBg,
                Size = UDim2.new(0, 38, 1, 0),
                BackgroundColor3 = theme.BackgroundSecondary,
                BorderSizePixel = 0,
                ZIndex = 152,
            })

            local codeScroll = GuiHelpers.Create("ScrollingFrame", {
                Parent = editorBg,
                Size = UDim2.new(1, -38, 1, 0),
                Position = UDim2.new(0, 38, 0, 0),
                BackgroundColor3 = theme.BackgroundTertiary,
                BorderSizePixel = 0,
                ScrollBarThickness = 5,
                ScrollBarImageColor3 = theme.Scrollbar,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ZIndex = 152,
                ClipsDescendants = true,
            })

            local lineNumScroll = GuiHelpers.Create("ScrollingFrame", {
                Parent = lineNumBg,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 0,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ZIndex = 152,
                ScrollingEnabled = false,
            })

            local lnLayout = GuiHelpers.Create("UIListLayout", {
                Parent = lineNumScroll,
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 0),
            })

            local codeLayout = GuiHelpers.Create("UIListLayout", {
                Parent = codeScroll,
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 0),
            })

            -- Синтаксис (упрощённый)
            local KEYWORDS_SET = {
                ["and"]=true,["break"]=true,["do"]=true,
                ["else"]=true,["elseif"]=true,["end"]=true,
                ["false"]=true,["for"]=true,["function"]=true,
                ["if"]=true,["in"]=true,["local"]=true,
                ["nil"]=true,["not"]=true,["or"]=true,
                ["repeat"]=true,["return"]=true,["then"]=true,
                ["true"]=true,["until"]=true,["while"]=true,
            }

            local LINE_H = 16
            local lines = {}
            local pos2 = 1
            while pos2 <= #source do
                local nl = string.find(source, "\n", pos2, true)
                if nl then
                    table.insert(lines, string.sub(source, pos2, nl-1))
                    pos2 = nl + 1
                else
                    table.insert(lines, string.sub(source, pos2))
                    break
                end
            end

            local renderLimit = math.min(#lines, 400)

            for li = 1, renderLimit do
                local lineText = lines[li] or ""

                -- Line number
                GuiHelpers.Create("TextLabel", {
                    Parent = lineNumScroll,
                    Size = UDim2.new(1, 0, 0, LINE_H),
                    BackgroundTransparency = 1,
                    Text = tostring(li),
                    TextColor3 = theme.TextDisabled,
                    TextSize = 10,
                    Font = Enum.Font.Code,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    BorderSizePixel = 0,
                    ZIndex = 153,
                    LayoutOrder = li,
                })
                pcall(function()
                    local p = Instance.new("UIPadding")
                    p.PaddingRight = UDim.new(0, 4)
                    p.Parent = lineNumScroll:GetChildren()[li]
                end)

                -- Определяем цвет строки
                local lineColor = theme.SyntaxDefault
                local trimmed = string.match(lineText, "^%s*(.-)%s*$") or ""

                if string.sub(trimmed, 1, 2) == "--" then
                    lineColor = theme.SyntaxComment
                elseif string.match(trimmed, "^%s*[%a_][%w_]*%s*%(") then
                    lineColor = theme.SyntaxFunction
                else
                    local firstWord = string.match(trimmed, "^([%a_]+)")
                    if firstWord and KEYWORDS_SET[firstWord] then
                        lineColor = theme.SyntaxKeyword
                    elseif string.match(trimmed, '^"') or
                        string.match(trimmed, "^'") then
                        lineColor = theme.SyntaxString
                    elseif string.match(trimmed, "^%d") then
                        lineColor = theme.SyntaxNumber
                    end
                end

                local codeLine = GuiHelpers.Create("TextLabel", {
                    Parent = codeScroll,
                    Size = UDim2.new(1, -8, 0, LINE_H),
                    BackgroundTransparency = 1,
                    Text = lineText,
                    TextColor3 = lineColor,
                    TextSize = 11,
                    Font = Enum.Font.Code,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    BorderSizePixel = 0,
                    ZIndex = 153,
                    LayoutOrder = li,
                })
                pcall(function()
                    local p = Instance.new("UIPadding")
                    p.PaddingLeft = UDim.new(0, 4)
                    p.Parent = codeLine
                end)
            end

            if #lines > renderLimit then
                GuiHelpers.Create("TextLabel", {
                    Parent = codeScroll,
                    Size = UDim2.new(1, 0, 0, LINE_H),
                    BackgroundTransparency = 1,
                    Text = "-- [" .. (#lines - renderLimit) ..
                        " more lines not shown]",
                    TextColor3 = theme.Warning,
                    TextSize = 11,
                    Font = Enum.Font.Code,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 153,
                    LayoutOrder = renderLimit + 1,
                })
            end

            local totalH = (renderLimit + 1) * LINE_H
            codeScroll.CanvasSize = UDim2.new(0, 800, 0, totalH)
            lineNumScroll.CanvasSize = UDim2.new(0, 0, 0, totalH)

            codeScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(
                function()
                    pcall(function()
                        lineNumScroll.CanvasPosition = Vector2.new(
                            0, codeScroll.CanvasPosition.Y
                        )
                    end)
                end
            )

            -- Кнопки
            local capturedSource = source
            local capturedName = name

            execBtn2.MouseButton1Click:Connect(function()
                pcall(function()
                    local fn, err = loadstring(capturedSource)
                    if fn then
                        task.spawn(function()
                            local ok, e = pcall(fn)
                            if ok then
                                DEX.ShowNotification(
                                    "Execute", capturedName .. " OK", "success"
                                )
                            else
                                DEX.ShowNotification(
                                    "Error", tostring(e), "error"
                                )
                            end
                        end)
                    else
                        DEX.ShowNotification(
                            "Syntax Error", tostring(err), "error"
                        )
                    end
                end)
            end)

            copyBtn2.MouseButton1Click:Connect(function()
                pcall(function()
                    setclipboard(capturedSource)
                    DEX.ShowNotification("Copied", "Source copied", "success")
                end)
            end)

            saveBtn2.MouseButton1Click:Connect(function()
                pcall(function()
                    local fname = "dex_" .. capturedName .. ".lua"
                    writefile(fname, capturedSource)
                    DEX.ShowNotification("Saved", fname, "success")
                end)
            end)

        -- ========================
        -- ИЗОБРАЖЕНИЕ ПРОСМОТР
        -- ========================
        elseif IMAGE_CLASSES[cls] then
            local imgId = ""
            pcall(function()
                imgId = instance[IMAGE_CLASSES[cls]] or ""
            end)

            local infoFrame = GuiHelpers.Create("Frame", {
                Parent = content,
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = theme.BackgroundSecondary,
                BorderSizePixel = 0,
                ZIndex = 152,
            })

            GuiHelpers.Create("TextLabel", {
                Parent = infoFrame,
                Size = UDim2.new(1, -8, 0.5, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Text = "Image ID: " .. (imgId ~= "" and imgId or "None"),
                TextColor3 = theme.Accent,
                TextSize = 11,
                Font = Enum.Font.Code,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 153,
            })

            local copyIdBtn2 = GuiHelpers.Create("TextButton", {
                Parent = infoFrame,
                Size = UDim2.new(0, 80, 0, 22),
                Position = UDim2.new(0, 8, 0, 24),
                BackgroundColor3 = theme.AccentDark,
                Text = "Copy ID",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 10,
                Font = Enum.Font.GothamSemibold,
                BorderSizePixel = 0,
                ZIndex = 153,
            })
            pcall(function()
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 3)
                c.Parent = copyIdBtn2
            end)

            local capturedId = imgId
            copyIdBtn2.MouseButton1Click:Connect(function()
                pcall(function()
                    setclipboard(capturedId)
                    DEX.ShowNotification("Copied", capturedId, "success")
                end)
            end)

            -- Превью изображения
            local previewBg = GuiHelpers.Create("Frame", {
                Parent = content,
                Size = UDim2.new(1, 0, 1, -50),
                Position = UDim2.new(0, 0, 0, 50),
                BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),
                BorderSizePixel = 0,
                ZIndex = 151,
            })

            -- Шахматная подложка
            local chess1 = GuiHelpers.Create("Frame", {
                Parent = previewBg,
                Size = UDim2.new(0.5, 0, 0.5, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Color3.new(0.15, 0.15, 0.15),
                BorderSizePixel = 0,
                ZIndex = 151,
            })
            local chess2 = GuiHelpers.Create("Frame", {
                Parent = previewBg,
                Size = UDim2.new(0.5, 0, 0.5, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundColor3 = Color3.new(0.15, 0.15, 0.15),
                BorderSizePixel = 0,
                ZIndex = 151,
            })

            if imgId ~= "" then
                local previewImg = GuiHelpers.Create("ImageLabel", {
                    Parent = previewBg,
                    Size = UDim2.new(0.8, 0, 0.8, 0),
                    Position = UDim2.new(0.1, 0, 0.1, 0),
                    BackgroundTransparency = 1,
                    Image = imgId,
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 152,
                })
            else
                GuiHelpers.Create("TextLabel", {
                    Parent = previewBg,
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "No image",
                    TextColor3 = theme.TextDisabled,
                    TextSize = 18,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 152,
                })
            end

        -- ========================
        -- ЗВУК ПРОСМОТР
        -- ========================
        elseif SOUND_CLASSES[cls] then
            local soundId = Utils.SafeGet(instance, "SoundId") or ""
            local volume = Utils.SafeGet(instance, "Volume") or 0
            local pitch = Utils.SafeGet(instance, "PlaybackSpeed") or 1
            local looped = Utils.SafeGet(instance, "Looped") or false
            local playing = Utils.SafeGet(instance, "Playing") or false
            local timeLen = Utils.SafeGet(instance, "TimeLength") or 0

            local soundPanel = GuiHelpers.Create("Frame", {
                Parent = content,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = theme.BackgroundSecondary,
                BorderSizePixel = 0,
                ZIndex = 151,
            })

            local function MakeSoundRow(label, value, y)
                GuiHelpers.Create("TextLabel", {
                    Parent = soundPanel,
                    Size = UDim2.new(0.4, 0, 0, 28),
                    Position = UDim2.new(0, 12, 0, y),
                    BackgroundTransparency = 1,
                    Text = label,
                    TextColor3 = theme.TextSecondary,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 152,
                })
                GuiHelpers.Create("TextLabel", {
                    Parent = soundPanel,
                    Size = UDim2.new(0.6, -12, 0, 28),
                    Position = UDim2.new(0.4, 0, 0, y),
                    BackgroundTransparency = 1,
                    Text = tostring(value),
                    TextColor3 = theme.Accent,
                    TextSize = 11,
                    Font = Enum.Font.GothamSemibold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 152,
                })
            end

            MakeSoundRow("Sound ID:", soundId, 10)
            MakeSoundRow("Volume:", string.format("%.2f", volume), 40)
            MakeSoundRow("Playback Speed:", string.format("%.2f", pitch), 70)
            MakeSoundRow("Looped:", tostring(looped), 100)
            MakeSoundRow("Playing:", tostring(playing), 130)
            MakeSoundRow("Duration:", string.format("%.2fs", timeLen), 160)

            -- Кнопки управления
            local playBtn = GuiHelpers.Create("TextButton", {
                Parent = soundPanel,
                Size = UDim2.new(0, 80, 0, 30),
                Position = UDim2.new(0, 12, 0, 200),
                BackgroundColor3 = theme.Success,
                Text = playing and "Stop" or "Play",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                BorderSizePixel = 0,
                ZIndex = 152,
            })
            pcall(function()
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 4)
                c.Parent = playBtn
            end)

            local copySoundBtn = GuiHelpers.Create("TextButton", {
                Parent = soundPanel,
                Size = UDim2.new(0, 100, 0, 30),
                Position = UDim2.new(0, 100, 0, 200),
                BackgroundColor3 = theme.AccentDark,
                Text = "Copy ID",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                BorderSizePixel = 0,
                ZIndex = 152,
            })
            pcall(function()
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 4)
                c.Parent = copySoundBtn
            end)

            local capturedInst = instance
            local capturedId = soundId

            playBtn.MouseButton1Click:Connect(function()
                pcall(function()
                    local isPlaying = capturedInst.Playing
                    if isPlaying then
                        capturedInst:Stop()
                        playBtn.Text = "Play"
                        playBtn.BackgroundColor3 = theme.Success
                    else
                        capturedInst:Play()
                        playBtn.Text = "Stop"
                        playBtn.BackgroundColor3 = theme.Error
                    end
                end)
            end)

            copySoundBtn.MouseButton1Click:Connect(function()
                pcall(function()
                    setclipboard(capturedId)
                    DEX.ShowNotification("Copied", capturedId, "success")
                end)
            end)

        -- ========================
        -- МЕШИ ПРОСМОТР
        -- ========================
        elseif MESH_CLASSES[cls] then
            local meshId = Utils.SafeGet(instance, "MeshId") or ""
            local texId = Utils.SafeGet(instance, "TextureId") or ""
            local meshType = Utils.SafeGet(instance, "MeshType")

            local meshPanel = GuiHelpers.Create("Frame", {
                Parent = content,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = theme.BackgroundSecondary,
                BorderSizePixel = 0,
                ZIndex = 151,
            })

            local function MakeMeshRow(label, value, y, col)
                GuiHelpers.Create("TextLabel", {
                    Parent = meshPanel,
                    Size = UDim2.new(0.35, 0, 0, 26),
                    Position = UDim2.new(0, 12, 0, y),
                    BackgroundTransparency = 1,
                    Text = label,
                    TextColor3 = theme.TextSecondary,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 152,
                })
                GuiHelpers.Create("TextLabel", {
                    Parent = meshPanel,
                    Size = UDim2.new(0.65, -24, 0, 26),
                    Position = UDim2.new(0.35, 12, 0, y),
                    BackgroundTransparency = 1,
                    Text = Utils.Truncate(tostring(value), 50),
                    TextColor3 = col or theme.Accent,
                    TextSize = 10,
                    Font = Enum.Font.Code,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 152,
                })
            end

            MakeMeshRow("Mesh ID:", meshId, 10, theme.SyntaxString)
            MakeMeshRow("Texture ID:", texId, 38, theme.SyntaxString)
            MakeMeshRow("MeshType:", tostring(meshType), 66, theme.Accent)

            local function MakeCopyBtn(label, value, x, y)
                local btn = GuiHelpers.Create("TextButton", {
                    Parent = meshPanel,
                    Size = UDim2.new(0, 110, 0, 26),
                    Position = UDim2.new(0, x, 0, y),
                    BackgroundColor3 = theme.AccentDark,
                    Text = label,
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 10,
                    Font = Enum.Font.GothamSemibold,
                    BorderSizePixel = 0,
                    ZIndex = 152,
                })
                pcall(function()
                    local c = Instance.new("UICorner")
                    c.CornerRadius = UDim.new(0, 3)
                    c.Parent = btn
                end)
                local capturedVal = value
                btn.MouseButton1Click:Connect(function()
                    pcall(function()
                        setclipboard(capturedVal)
                        DEX.ShowNotification("Copied", capturedVal, "success")
                    end)
                end)
            end

            MakeCopyBtn("Copy Mesh ID", meshId, 12, 100)
            MakeCopyBtn("Copy Texture ID", texId, 132, 100)

        -- ========================
        -- ОБЩИЙ ПРОСМОТР (любой объект)
        -- ========================
        else
            local propsScroll = GuiHelpers.Create("ScrollingFrame", {
                Parent = content,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = theme.Background,
                BorderSizePixel = 0,
                ScrollBarThickness = 4,
                ScrollBarImageColor3 = theme.Scrollbar,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ZIndex = 151,
                ClipsDescendants = true,
            })

            local propsLayout2 = GuiHelpers.Create("UIListLayout", {
                Parent = propsScroll,
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 1),
            })

            local allProps = {
                "Name", "ClassName", "Parent", "Archivable",
                "Position", "Size", "Rotation", "CFrame",
                "Anchored", "CanCollide", "Transparency",
                "BrickColor", "Material", "Color",
                "Visible", "Enabled", "ZIndex",
                "Text", "TextColor3", "BackgroundColor3",
                "Health", "MaxHealth", "WalkSpeed", "JumpPower",
                "SoundId", "Volume", "Playing", "Looped",
                "Image", "MeshId", "TextureId",
                "Disabled", "RunContext", "Value",
                "TeamColor", "NeutralTeam", "AutoAssignable",
            }

            local rowIdx2 = 0
            for _, propName in ipairs(allProps) do
                local ok, val = pcall(function()
                    return instance[propName]
                end)
                if ok then
                    rowIdx2 = rowIdx2 + 1
                    local rowBg = rowIdx2 % 2 == 0
                        and theme.BackgroundSecondary
                        or theme.Background

                    local row = GuiHelpers.Create("Frame", {
                        Parent = propsScroll,
                        Size = UDim2.new(1, 0, 0, 22),
                        BackgroundColor3 = rowBg,
                        BorderSizePixel = 0,
                        ZIndex = 152,
                        LayoutOrder = rowIdx2,
                    })

                    GuiHelpers.Create("TextLabel", {
                        Parent = row,
                        Size = UDim2.new(0.42, 0, 1, 0),
                        Position = UDim2.new(0, 8, 0, 0),
                        BackgroundTransparency = 1,
                        Text = propName,
                        TextColor3 = theme.TextSecondary,
                        TextSize = 10,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 153,
                    })

                    local valStr = ""
                    pcall(function()
                        local t = typeof(val)
                        if t == "nil" then valStr = "nil"
                        elseif t == "boolean" then valStr = tostring(val)
                        elseif t == "number" then
                            valStr = string.format("%.4g", val)
                        elseif t == "string" then
                            valStr = '"' .. Utils.Truncate(val, 35) .. '"'
                        elseif t == "Vector3" then
                            valStr = string.format("%.1f, %.1f, %.1f",
                                val.X, val.Y, val.Z)
                        elseif t == "Color3" then
                            valStr = string.format("RGB(%d,%d,%d)",
                                math.floor(val.R*255),
                                math.floor(val.G*255),
                                math.floor(val.B*255))
                        elseif t == "CFrame" then
                            local p = val.Position
                            valStr = string.format("%.1f, %.1f, %.1f",
                                p.X, p.Y, p.Z)
                        elseif t == "Instance" then
                            valStr = Utils.GetInstanceName(val)
                        elseif t == "EnumItem" then
                            valStr = tostring(val)
                        elseif t == "UDim2" then
                            valStr = string.format("{%.2f,%d},{%.2f,%d}",
                                val.X.Scale, val.X.Offset,
                                val.Y.Scale, val.Y.Offset)
                        else
                            valStr = tostring(val)
                        end
                    end)

                    if typeof(val) == "Color3" then
                        GuiHelpers.Create("Frame", {
                            Parent = row,
                            Size = UDim2.new(0, 14, 0, 14),
                            Position = UDim2.new(0.42, 2, 0, 4),
                            BackgroundColor3 = val,
                            BorderSizePixel = 0,
                            ZIndex = 153,
                        })
                    end

                    local valLbl = GuiHelpers.Create("TextButton", {
                        Parent = row,
                        Size = UDim2.new(0.58, -20, 1, 0),
                        Position = UDim2.new(0.42, 18, 0, 0),
                        BackgroundTransparency = 1,
                        Text = valStr,
                        TextColor3 = theme.Text,
                        TextSize = 10,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        BorderSizePixel = 0,
                        ZIndex = 153,
                    })

                    local capN = propName
                    local capV = valStr
                    valLbl.MouseButton1Click:Connect(function()
                        pcall(function()
                            setclipboard(capN .. " = " .. capV)
                            DEX.ShowNotification(
                                "Copied", capN .. " = " .. capV, "success"
                            )
                        end)
                    end)
                end
            end

            propsScroll.CanvasSize = UDim2.new(0, 0, 0, rowIdx2 * 23)
        end
    end)
end

DEX.OpenPreviewWindow = OpenPreviewWindow

-- ========================
-- LAYOUT
-- ========================
local leftPanel = GuiHelpers.Create("Frame", {
    Name = "LeftPanel",
    Parent = explorerPage,
    Size = UDim2.new(0.55, -1, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.BackgroundTertiary,
    BorderSizePixel = 0,
    ZIndex = 8,
    ClipsDescendants = true,
})

local divider = GuiHelpers.Create("Frame", {
    Name = "Divider",
    Parent = explorerPage,
    Size = UDim2.new(0, 2, 1, 0),
    Position = UDim2.new(0.55, -1, 0, 0),
    BackgroundColor3 = theme.Border,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local rightPanel = GuiHelpers.Create("Frame", {
    Name = "RightPanel",
    Parent = explorerPage,
    Size = UDim2.new(0.45, -1, 1, 0),
    Position = UDim2.new(0.55, 2, 0, 0),
    BackgroundColor3 = theme.Background,
    BorderSizePixel = 0,
    ZIndex = 8,
    ClipsDescendants = true,
})

-- ========================
-- SEARCH BAR
-- ========================
local searchBar = GuiHelpers.Create("Frame", {
    Name = "SearchBar",
    Parent = leftPanel,
    Size = UDim2.new(1, 0, 0, 34),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.BackgroundSecondary,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local searchBox = GuiHelpers.Create("TextBox", {
    Name = "SearchBox",
    Parent = searchBar,
    Size = UDim2.new(1, -90, 1, -8),
    Position = UDim2.new(0, 6, 0, 4),
    BackgroundColor3 = theme.InputBg,
    Text = "",
    PlaceholderText = "Search instances...",
    PlaceholderColor3 = theme.TextDisabled,
    TextColor3 = theme.Text,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = searchBox
end)
pcall(function()
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, 6)
    p.Parent = searchBox
end)

local classFilterBox = GuiHelpers.Create("TextBox", {
    Name = "ClassFilter",
    Parent = searchBar,
    Size = UDim2.new(0, 78, 1, -8),
    Position = UDim2.new(1, -84, 0, 4),
    BackgroundColor3 = theme.InputBg,
    Text = "",
    PlaceholderText = "Class...",
    PlaceholderColor3 = theme.TextDisabled,
    TextColor3 = theme.Text,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = classFilterBox
end)
pcall(function()
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, 6)
    p.Parent = classFilterBox
end)

local refreshBtn = GuiHelpers.Create("TextButton", {
    Name = "RefreshBtn",
    Parent = leftPanel,
    Size = UDim2.new(1, -8, 0, 22),
    Position = UDim2.new(0, 4, 0, 36),
    BackgroundColor3 = theme.ButtonBg,
    Text = "  Refresh Tree",
    TextColor3 = theme.Text,
    TextSize = 11,
    Font = Enum.Font.GothamSemibold,
    TextXAlignment = Enum.TextXAlignment.Left,
    BorderSizePixel = 0,
    ZIndex = 9,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = refreshBtn
end)

local nodeCountLabel = GuiHelpers.Create("TextLabel", {
    Name = "NodeCount",
    Parent = leftPanel,
    Size = UDim2.new(1, 0, 0, 16),
    Position = UDim2.new(0, 6, 0, 62),
    BackgroundTransparency = 1,
    Text = "Nodes: 0  |  Click node to preview",
    TextColor3 = theme.TextSecondary,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 9,
})

-- ========================
-- TREE CONTAINER
-- ========================
local treeContainer = GuiHelpers.Create("Frame", {
    Name = "TreeContainer",
    Parent = leftPanel,
    Size = UDim2.new(1, 0, 1, -80),
    Position = UDim2.new(0, 0, 0, 80),
    BackgroundColor3 = theme.BackgroundTertiary,
    BorderSizePixel = 0,
    ZIndex = 8,
    ClipsDescendants = true,
})

local treeCanvas = GuiHelpers.Create("Frame", {
    Name = "TreeCanvas",
    Parent = treeContainer,
    Size = UDim2.new(1, 0, 0, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 8,
})

local scrollTrack = GuiHelpers.Create("Frame", {
    Name = "ScrollTrack",
    Parent = treeContainer,
    Size = UDim2.new(0, 6, 1, 0),
    Position = UDim2.new(1, -6, 0, 0),
    BackgroundColor3 = theme.BackgroundSecondary,
    BorderSizePixel = 0,
    ZIndex = 10,
})

local scrollThumb = GuiHelpers.Create("Frame", {
    Name = "ScrollThumb",
    Parent = scrollTrack,
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.Scrollbar,
    BorderSizePixel = 0,
    ZIndex = 11,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 3)
    c.Parent = scrollThumb
end)

-- ========================
-- BUILD NODE LIST
-- ========================
local function BuildNodeList()
    local nodes = {}
    local expanded = ExpState.ExpandedMap
    local searchQ = string.lower(ExpState.SearchQuery)
    local classF = string.lower(ExpState.ClassFilter)

    local function Traverse(inst, depth)
        if depth > 60 then return end
        local ok, children = pcall(function()
            return inst:GetChildren()
        end)
        if not ok then return end

        for _, child in ipairs(children) do
            pcall(function()
                local cname = string.lower(Utils.GetInstanceName(child))
                local ccls = string.lower(Utils.GetClassName(child))

                local matchS = (searchQ == "") or
                    string.find(cname, searchQ, 1, true) or
                    string.find(ccls, searchQ, 1, true)
                local matchC = (classF == "") or
                    string.find(ccls, classF, 1, true)

                local hasKids = false
                local kidCount = 0
                pcall(function()
                    local gc = child:GetChildren()
                    kidCount = #gc
                    hasKids = kidCount > 0
                end)

                if matchS and matchC then
                    table.insert(nodes, {
                        instance = child,
                        depth = depth,
                        isExpanded = expanded[child] == true,
                        hasChildren = hasKids,
                        childCount = kidCount,
                        name = Utils.GetInstanceName(child),
                        className = Utils.GetClassName(child),
                    })
                end

                if expanded[child] and hasKids then
                    Traverse(child, depth + 1)
                end
            end)
        end
    end

    local gameKids = 0
    pcall(function() gameKids = #game:GetChildren() end)

    table.insert(nodes, {
        instance = game,
        depth = 0,
        isExpanded = expanded[game] == true,
        hasChildren = true,
        childCount = gameKids,
        name = "game",
        className = "DataModel",
    })

    if expanded[game] then
        Traverse(game, 1)
    end

    ExpState.AllNodes = nodes
    ExpState.TotalNodes = #nodes
    nodeCountLabel.Text = "Nodes: " .. #nodes ..
        "  |  Click = properties  |  DblClick = preview"
end

-- ========================
-- RENDER TREE
-- ========================
local renderedRows = {}

local function GetContainerH()
    local ok, h = pcall(function()
        return treeContainer.AbsoluteSize.Y
    end)
    if ok and h > 0 then return h end
    return 400
end

local function UpdateScrollThumb()
    pcall(function()
        local total = #ExpState.AllNodes
        if total == 0 then return end
        local cH = GetContainerH()
        local vis = math.floor(cH / NODE_HEIGHT)
        if total <= vis then
            scrollThumb.Size = UDim2.new(1, 0, 1, 0)
            scrollThumb.Position = UDim2.new(0, 0, 0, 0)
            return
        end
        local ratio = vis / total
        local thumbH = math.max(20, math.floor(cH * ratio))
        local maxOff = total - vis
        local thumbPos = 0
        if maxOff > 0 then
            thumbPos = math.floor(
                (ExpState.ScrollOffset / maxOff) * (cH - thumbH)
            )
        end
        scrollThumb.Size = UDim2.new(1, 0, 0, thumbH)
        scrollThumb.Position = UDim2.new(0, 0, 0, thumbPos)
    end)
end

local function ClearRows()
    for _, r in ipairs(renderedRows) do
        pcall(function() r:Destroy() end)
    end
    renderedRows = {}
end

-- Forward declare
local LoadProperties

local lastClickTime = {}

local function RenderTree()
    pcall(function()
        ClearRows()
        local cH = GetContainerH()
        local vis = math.min(
            math.ceil(cH / NODE_HEIGHT) + 4,
            MAX_VISIBLE_NODES
        )
        local total = #ExpState.AllNodes
        local startI = ExpState.ScrollOffset + 1
        local endI = math.min(startI + vis - 1, total)

        treeCanvas.Size = UDim2.new(1, 0, 0, total * NODE_HEIGHT)

        for i = startI, endI do
            local node = ExpState.AllNodes[i]
            if not node then break end

            local rowY = (i-1)*NODE_HEIGHT -
                ExpState.ScrollOffset*NODE_HEIGHT
            local indentX = node.depth * INDENT_WIDTH + 4
            local isSelected = ExpState.SelectedNode and
                ExpState.SelectedNode.instance == node.instance

            local row = GuiHelpers.Create("Frame", {
                Name = "Node" .. i,
                Parent = treeCanvas,
                Size = UDim2.new(1, -6, 0, NODE_HEIGHT),
                Position = UDim2.new(0, 0, 0, rowY),
                BackgroundColor3 = isSelected
                    and theme.NodeSelected
                    or theme.BackgroundTertiary,
                BackgroundTransparency = isSelected and 0 or 1,
                BorderSizePixel = 0,
                ZIndex = 8,
            })

            -- Стрелка
            if node.hasChildren then
                local arrow = GuiHelpers.Create("TextButton", {
                    Parent = row,
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(0, indentX, 0, 5),
                    BackgroundTransparency = 1,
                    Text = node.isExpanded and "v" or ">",
                    TextColor3 = theme.TextSecondary,
                    TextSize = 9,
                    Font = Enum.Font.GothamBold,
                    BorderSizePixel = 0,
                    ZIndex = 9,
                })
                local nr = node
                arrow.MouseButton1Click:Connect(function()
                    pcall(function()
                        local inst = nr.instance
                        if ExpState.ExpandedMap[inst] then
                            ExpState.ExpandedMap[inst] = false
                        else
                            ExpState.ExpandedMap[inst] = true
                        end
                        BuildNodeList()
                        RenderTree()
                    end)
                end)
            end

            -- Иконка с цветом класса
            local iconX = indentX + (node.hasChildren and 16 or 0)
            local classInfo = GetClassInfo(node.className)

            local iconBg = GuiHelpers.Create("TextLabel", {
                Parent = row,
                Size = UDim2.new(0, 20, 0, 16),
                Position = UDim2.new(0, iconX, 0, 4),
                BackgroundColor3 = classInfo.color,
                Text = classInfo.icon,
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 8,
                Font = Enum.Font.GothamBold,
                BorderSizePixel = 0,
                ZIndex = 9,
            })
            pcall(function()
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 3)
                c.Parent = iconBg
            end)

            -- Имя
            local nameX = iconX + 24
            local dispName = Utils.Truncate(node.name, 30)
            if node.childCount > 0 then
                dispName = dispName .. " (" .. node.childCount .. ")"
            end

            local nameLabel = GuiHelpers.Create("TextButton", {
                Parent = row,
                Size = UDim2.new(1, -(nameX+4), 1, 0),
                Position = UDim2.new(0, nameX, 0, 0),
                BackgroundTransparency = 1,
                Text = dispName,
                TextColor3 = isSelected
                    and Color3.new(1,1,1) or theme.Text,
                TextSize = 11,
                Font = SCRIPT_CLASSES[node.className]
                    and Enum.Font.GothamBold
                    or Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                BorderSizePixel = 0,
                ZIndex = 9,
            })

            local cn = node
            local cr = row

            nameLabel.MouseEnter:Connect(function()
                pcall(function()
                    if not (ExpState.SelectedNode and
                        ExpState.SelectedNode.instance == cn.instance) then
                        cr.BackgroundColor3 = theme.NodeHover
                        cr.BackgroundTransparency = 0
                    end
                end)
            end)
            nameLabel.MouseLeave:Connect(function()
                pcall(function()
                    if not (ExpState.SelectedNode and
                        ExpState.SelectedNode.instance == cn.instance) then
                        cr.BackgroundTransparency = 1
                    end
                end)
            end)

            -- Одинарный клик = свойства
            -- Двойной клик = превью окно
            nameLabel.MouseButton1Click:Connect(function()
                pcall(function()
                    local now = tick()
                    local inst = cn.instance
                    local lastT = lastClickTime[inst] or 0

                    if now - lastT < 0.4 then
                        -- Двойной клик — открыть превью
                        OpenPreviewWindow(inst)
                        lastClickTime[inst] = 0
                    else
                        -- Одинарный клик — выбрать + свойства
                        ExpState.SelectedNode = cn
                        DEX.State.SelectedInstance = inst
                        lastClickTime[inst] = now
                        RenderTree()
                        if LoadProperties then
                            LoadProperties(inst)
                        end
                    end
                end)
            end)

            -- ПКМ меню
            nameLabel.MouseButton2Click:Connect(function()
                pcall(function()
                    local UIS = game:GetService("UserInputService")
                    local mp = UIS:GetMouseLocation()
                    local inst = cn.instance
                    local instPath = Utils.GetFullPath(inst)
                    local instName = Utils.GetInstanceName(inst)
                    local iname = cn.className

                    DEX.ShowContextMenu({
                        {
                            label = "Preview / Open",
                            color = theme.Accent,
                            callback = function()
                                OpenPreviewWindow(inst)
                            end
                        },
                        {
                            label = "Copy Path",
                            callback = function()
                                setclipboard(instPath)
                                DEX.ShowNotification(
                                    "Copied", instPath, "success"
                                )
                            end
                        },
                        {
                            label = "Copy Name",
                            callback = function()
                                setclipboard(instName)
                                DEX.ShowNotification(
                                    "Copied", instName, "success"
                                )
                            end
                        },
                        {
                            label = "Copy ClassName",
                            callback = function()
                                setclipboard(iname)
                                DEX.ShowNotification(
                                    "Copied", iname, "success"
                                )
                            end
                        },
                        {
                            label = "Expand All",
                            callback = function()
                                pcall(function()
                                    local function EA(t)
                                        local ok2, kids = pcall(function()
                                            return t:GetChildren()
                                        end)
                                        if ok2 then
                                            for _, k in ipairs(kids) do
                                                ExpState.ExpandedMap[k] = true
                                                EA(k)
                                            end
                                        end
                                    end
                                    ExpState.ExpandedMap[inst] = true
                                    EA(inst)
                                    BuildNodeList()
                                    RenderTree()
                                end)
                            end
                        },
                        {
                            label = "Collapse",
                            callback = function()
                                ExpState.ExpandedMap[inst] = false
                                BuildNodeList()
                                RenderTree()
                            end
                        },
                        {
                            label = "Delete",
                            color = theme.Error,
                            callback = function()
                                pcall(function()
                                    inst:Destroy()
                                    ExpState.SelectedNode = nil
                                    BuildNodeList()
                                    RenderTree()
                                    DEX.ShowNotification(
                                        "Deleted", instName, "warning"
                                    )
                                end)
                            end
                        },
                    }, mp.X, mp.Y)
                end)
            end)

            table.insert(renderedRows, row)
        end

        UpdateScrollThumb()
    end)
end

-- ========================
-- SCROLL
-- ========================
treeContainer.InputChanged:Connect(function(input)
    pcall(function()
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            local total = #ExpState.AllNodes
            local cH = GetContainerH()
            local vis = math.floor(cH / NODE_HEIGHT)
            local maxOff = math.max(0, total - vis)
            ExpState.ScrollOffset = math.clamp(
                ExpState.ScrollOffset + (-input.Position.Z) * 3,
                0, maxOff
            )
            RenderTree()
        end
    end)
end)

local sDrag = false
local sDragY = 0
local sDragOff = 0
local UIS2 = game:GetService("UserInputService")

scrollThumb.InputBegan:Connect(function(input)
    pcall(function()
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sDrag = true
            sDragY = input.Position.Y
            sDragOff = ExpState.ScrollOffset
        end
    end)
end)
UIS2.InputChanged:Connect(function(input)
    pcall(function()
        if sDrag and
            input.UserInputType == Enum.UserInputType.MouseMovement then
            local total = #ExpState.AllNodes
            local cH = GetContainerH()
            local vis = math.floor(cH / NODE_HEIGHT)
            local maxOff = math.max(0, total - vis)
            local delta = input.Position.Y - sDragY
            local ratio = delta / cH
            ExpState.ScrollOffset = math.clamp(
                math.floor(sDragOff + ratio * total), 0, maxOff
            )
            RenderTree()
        end
    end)
end)
UIS2.InputEnded:Connect(function(input)
    pcall(function()
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sDrag = false
        end
    end)
end)

-- ========================
-- SEARCH
-- ========================
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    pcall(function()
        ExpState.SearchQuery = searchBox.Text
        ExpState.ScrollOffset = 0
        BuildNodeList()
        RenderTree()
    end)
end)

classFilterBox:GetPropertyChangedSignal("Text"):Connect(function()
    pcall(function()
        ExpState.ClassFilter = classFilterBox.Text
        ExpState.ScrollOffset = 0
        BuildNodeList()
        RenderTree()
    end)
end)

refreshBtn.MouseButton1Click:Connect(function()
    pcall(function()
        ExpState.ScrollOffset = 0
        BuildNodeList()
        RenderTree()
        DEX.ShowNotification("Explorer", "Refreshed", "info")
    end)
end)
GuiHelpers.AddHover(refreshBtn, theme.ButtonBg, theme.ButtonHover)

-- ========================
-- PROPERTIES PANEL
-- ========================
local propHeader = GuiHelpers.Create("Frame", {
    Name = "PropHeader",
    Parent = rightPanel,
    Size = UDim2.new(1, 0, 0, 34),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.BackgroundSecondary,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local propTitle = GuiHelpers.Create("TextLabel", {
    Name = "PropTitle",
    Parent = propHeader,
    Size = UDim2.new(0.7, 0, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "Properties",
    TextColor3 = theme.Text,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 10,
})

-- Кнопка открыть превью в правой панели
local openPreviewBtn = GuiHelpers.Create("TextButton", {
    Parent = propHeader,
    Size = UDim2.new(0, 70, 1, -8),
    Position = UDim2.new(1, -74, 0, 4),
    BackgroundColor3 = theme.AccentDark,
    Text = "Preview",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 10,
    Font = Enum.Font.GothamSemibold,
    BorderSizePixel = 0,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 3)
    c.Parent = openPreviewBtn
end)
openPreviewBtn.MouseButton1Click:Connect(function()
    pcall(function()
        if ExpState.SelectedNode then
            OpenPreviewWindow(ExpState.SelectedNode.instance)
        end
    end)
end)

local propSearchBox = GuiHelpers.Create("TextBox", {
    Parent = rightPanel,
    Size = UDim2.new(1, -8, 0, 22),
    Position = UDim2.new(0, 4, 0, 36),
    BackgroundColor3 = theme.InputBg,
    Text = "",
    PlaceholderText = "Filter properties...",
    PlaceholderColor3 = theme.TextDisabled,
    TextColor3 = theme.Text,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = propSearchBox
end)
pcall(function()
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, 6)
    p.Parent = propSearchBox
end)

local propScroll = GuiHelpers.Create("ScrollingFrame", {
    Parent = rightPanel,
    Size = UDim2.new(1, 0, 1, -62),
    Position = UDim2.new(0, 0, 0, 62),
    BackgroundColor3 = theme.Background,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = theme.Scrollbar,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 8,
    ClipsDescendants = true,
})

local propLayout = GuiHelpers.Create("UIListLayout", {
    Parent = propScroll,
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 1),
})

local ALL_PROPS = {
    "Name","ClassName","Parent","Archivable",
    "Position","Size","Rotation","CFrame","Anchored",
    "CanCollide","Transparency","BrickColor","Material",
    "Color","Reflectance","Locked","Massless","CastShadow",
    "Visible","Enabled","ZIndex","BorderSizePixel",
    "BackgroundColor3","BackgroundTransparency","ClipsDescendants",
    "Text","TextColor3","TextSize","Font","TextWrapped",
    "Image","ImageColor3","ScaleType",
    "Health","MaxHealth","WalkSpeed","JumpPower",
    "AutoRotate","DisplayName","NameDisplayDistance",
    "SoundId","Volume","Playing","Looped","PlaybackSpeed",
    "TimeLength","TimePosition",
    "MeshId","TextureId","MeshType","VertexColor","Scale",
    "Disabled","RunContext","Value","TeamColor",
    "Brightness","Range","Shadows","LightInfluence",
    "Acceleration","MaxVelocity","P","D",
}

local function ValToStr(val)
    local t = typeof(val)
    if t == "nil" then return "nil" end
    if t == "boolean" then return tostring(val) end
    if t == "number" then return string.format("%.4g", val) end
    if t == "string" then
        return '"' .. Utils.Truncate(val, 38) .. '"'
    end
    if t == "Vector3" then
        return string.format("(%.2f,%.2f,%.2f)",
            val.X,val.Y,val.Z)
    end
    if t == "Vector2" then
        return string.format("(%.2f,%.2f)",val.X,val.Y)
    end
    if t == "CFrame" then
        local p = val.Position
        return string.format("CF(%.1f,%.1f,%.1f)",p.X,p.Y,p.Z)
    end
    if t == "Color3" then
        return string.format("RGB(%d,%d,%d)",
            math.floor(val.R*255),
            math.floor(val.G*255),
            math.floor(val.B*255))
    end
    if t == "BrickColor" then return tostring(val) end
    if t == "UDim2" then
        return string.format("{%.2f,%d},{%.2f,%d}",
            val.X.Scale,val.X.Offset,
            val.Y.Scale,val.Y.Offset)
    end
    if t == "Instance" then
        return Utils.GetInstanceName(val) ..
            "[" .. Utils.GetClassName(val) .. "]"
    end
    if t == "EnumItem" then return tostring(val) end
    return tostring(val)
end

local propFilter = ""

LoadProperties = function(instance)
    if not instance then return end
    pcall(function()
        for _, c in ipairs(propScroll:GetChildren()) do
            pcall(function()
                if not c:IsA("UIListLayout") then
                    c:Destroy()
                end
            end)
        end

        local iname = Utils.GetInstanceName(instance)
        local icls = Utils.GetClassName(instance)
        local ci = GetClassInfo(icls)

        -- Заголовок с иконкой класса
        propTitle.Text = iname .. " [" .. icls .. "]"
        propHeader.BackgroundColor3 = Color3.new(
            ci.color.R * 0.3 + theme.BackgroundSecondary.R * 0.7,
            ci.color.G * 0.3 + theme.BackgroundSecondary.G * 0.7,
            ci.color.B * 0.3 + theme.BackgroundSecondary.B * 0.7
        )

        local rowIdx = 0
        local fq = string.lower(propFilter)

        for _, pname in ipairs(ALL_PROPS) do
            local matchF = fq == "" or
                string.find(string.lower(pname), fq, 1, true)
            if matchF then
                local ok, val = pcall(function()
                    return instance[pname]
                end)
                if ok then
                    rowIdx = rowIdx + 1
                    local rowBg = rowIdx % 2 == 0
                        and theme.BackgroundSecondary
                        or theme.Background

                    local pr = GuiHelpers.Create("Frame", {
                        Parent = propScroll,
                        Size = UDim2.new(1, 0, 0, 20),
                        BackgroundColor3 = rowBg,
                        BorderSizePixel = 0,
                        ZIndex = 9,
                        LayoutOrder = rowIdx,
                    })

                    GuiHelpers.Create("TextLabel", {
                        Parent = pr,
                        Size = UDim2.new(0.44, 0, 1, 0),
                        Position = UDim2.new(0, 4, 0, 0),
                        BackgroundTransparency = 1,
                        Text = pname,
                        TextColor3 = theme.TextSecondary,
                        TextSize = 10,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 10,
                    })

                    local vstr = ValToStr(val)
                    local vcol = theme.Text
                    pcall(function()
                        local t = typeof(val)
                        if t == "boolean" then
                            vcol = val and theme.Success or theme.Error
                        elseif t == "number" then
                            vcol = theme.SyntaxNumber
                        elseif t == "string" then
                            vcol = theme.SyntaxString
                        elseif t == "Instance" then
                            vcol = theme.Accent
                        end
                    end)

                    if typeof(val) == "Color3" then
                        GuiHelpers.Create("Frame", {
                            Parent = pr,
                            Size = UDim2.new(0, 12, 0, 12),
                            Position = UDim2.new(0.44, 2, 0, 4),
                            BackgroundColor3 = val,
                            BorderSizePixel = 0,
                            ZIndex = 10,
                        })
                    end

                    local vbtn = GuiHelpers.Create("TextButton", {
                        Parent = pr,
                        Size = UDim2.new(0.56, -20, 1, 0),
                        Position = UDim2.new(0.44, 16, 0, 0),
                        BackgroundTransparency = 1,
                        Text = vstr,
                        TextColor3 = vcol,
                        TextSize = 10,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        BorderSizePixel = 0,
                        ZIndex = 10,
                    })

                    local cpn = pname
                    local cpv = vstr
                    vbtn.MouseButton1Click:Connect(function()
                        pcall(function()
                            setclipboard(cpn .. " = " .. cpv)
                            DEX.ShowNotification(
                                "Copied", cpn .. " = " .. cpv, "success"
                            )
                        end)
                    end)
                end
            end
        end

        propScroll.CanvasSize = UDim2.new(0, 0, 0, rowIdx * 21)
    end)
end

DEX.LoadProperties = LoadProperties

propSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    pcall(function()
        propFilter = propSearchBox.Text
        if ExpState.SelectedNode then
            LoadProperties(ExpState.SelectedNode.instance)
        end
    end)
end)

-- ========================
-- INITIAL LOAD
-- ========================
task.spawn(function()
    pcall(function()
        task.wait(0.5)
        ExpState.ExpandedMap[game] = true
        BuildNodeList()
        RenderTree()
        DEX.StatusText.Text = "Explorer | " ..
            ExpState.TotalNodes .. " nodes | DblClick = preview"
        DEX.ShowNotification(
            "Explorer",
            ExpState.TotalNodes .. " nodes | Double-click to preview",
            "success"
        )
    end)
end)

local origSwitch = DEX.SwitchTab
DEX.SwitchTab = function(tabName)
    origSwitch(tabName)
    if tabName == "Explorer" then
        task.spawn(function()
            pcall(function()
                task.wait(0.1)
                BuildNodeList()
                RenderTree()
            end)
        end)
    end
end

for _, tabName in ipairs(DEX.Tabs) do
    pcall(function()
        local btn = DEX.TabButtons[tabName]
        if btn then
            btn.MouseButton1Click:Connect(function()
                DEX.SwitchTab(tabName)
            end)
        end
    end)
end

print("[DEX] Part 2: Explorer + Icons + Preview loaded")
print("[DEX] Single click = properties | Double click = preview")

getgenv().DEX = DEX
