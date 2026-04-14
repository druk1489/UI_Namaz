-- DEX Explorer v1.0 for Solara
-- Part 3: Script Viewer (Scripts list, tabs, syntax highlight, decompiler, save)
-- =============================================================================

assert(getgenv().DEX, "DEX Core (Part 1) must be loaded first!")

local DEX = getgenv().DEX
local theme = DEX.CurrentTheme
local Utils = DEX.Utils
local GuiHelpers = DEX.GuiHelpers
local scriptsPage = DEX.Pages["Scripts"]

assert(scriptsPage, "Scripts page not found!")

-- ========================
-- SCRIPT VIEWER STATE
-- ========================
local SVState = {
    AllScripts = {},
    FilteredScripts = {},
    SelectedScript = nil,
    Tabs = {},
    ActiveTabIndex = 0,
    SearchQuery = "",
    TypeFilter = "All",
    ScrollOffset = 0,
}

DEX.SVState = SVState

-- ========================
-- LAYOUT
-- ========================
local leftPanel = GuiHelpers.Create("Frame", {
    Name = "SVLeft",
    Parent = scriptsPage,
    Size = UDim2.new(0, 220, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.BackgroundTertiary,
    BorderSizePixel = 0,
    ZIndex = 8,
    ClipsDescendants = true,
})

local divider = GuiHelpers.Create("Frame", {
    Name = "SVDivider",
    Parent = scriptsPage,
    Size = UDim2.new(0, 2, 1, 0),
    Position = UDim2.new(0, 220, 0, 0),
    BackgroundColor3 = theme.Border,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local rightPanel = GuiHelpers.Create("Frame", {
    Name = "SVRight",
    Parent = scriptsPage,
    Size = UDim2.new(1, -222, 1, 0),
    Position = UDim2.new(0, 222, 0, 0),
    BackgroundColor3 = theme.Background,
    BorderSizePixel = 0,
    ZIndex = 8,
    ClipsDescendants = true,
})

-- ========================
-- LEFT: SCRIPT LIST
-- ========================
local listHeader = GuiHelpers.Create("Frame", {
    Name = "ListHeader",
    Parent = leftPanel,
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.BackgroundSecondary,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local listTitle = GuiHelpers.Create("TextLabel", {
    Name = "ListTitle",
    Parent = listHeader,
    Size = UDim2.new(1, -8, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "Scripts (0)",
    TextColor3 = theme.Text,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 10,
})

local searchBox = GuiHelpers.Create("TextBox", {
    Name = "ScriptSearch",
    Parent = leftPanel,
    Size = UDim2.new(1, -8, 0, 22),
    Position = UDim2.new(0, 4, 0, 32),
    BackgroundColor3 = theme.InputBg,
    Text = "",
    PlaceholderText = "Search scripts...",
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
    c.Parent = searchBox
end)
pcall(function()
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, 6)
    p.Parent = searchBox
end)

-- Type filter buttons
local filterFrame = GuiHelpers.Create("Frame", {
    Name = "FilterFrame",
    Parent = leftPanel,
    Size = UDim2.new(1, 0, 0, 24),
    Position = UDim2.new(0, 0, 0, 56),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local filterTypes = {"All", "Local", "Server", "Module"}
local filterBtns = {}
local filterBtnW = math.floor(220 / #filterTypes)

for i, ft in ipairs(filterTypes) do
    local isActive = (ft == "All")
    local fb = GuiHelpers.Create("TextButton", {
        Name = "Filter_" .. ft,
        Parent = filterFrame,
        Size = UDim2.new(0, filterBtnW - 2, 1, -4),
        Position = UDim2.new(0, (i - 1) * filterBtnW + 1, 0, 2),
        BackgroundColor3 = isActive and theme.Accent or theme.ButtonBg,
        Text = ft,
        TextColor3 = isActive and Color3.new(1, 1, 1) or theme.TextSecondary,
        TextSize = 10,
        Font = Enum.Font.GothamSemibold,
        BorderSizePixel = 0,
        ZIndex = 10,
    })
    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 3)
        c.Parent = fb
    end)
    filterBtns[ft] = fb
end

local scanBtn = GuiHelpers.Create("TextButton", {
    Name = "ScanBtn",
    Parent = leftPanel,
    Size = UDim2.new(1, -8, 0, 20),
    Position = UDim2.new(0, 4, 0, 82),
    BackgroundColor3 = theme.AccentDark,
    Text = "Scan All Scripts",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 10,
    Font = Enum.Font.GothamSemibold,
    BorderSizePixel = 0,
    ZIndex = 9,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = scanBtn
end)

-- Script list scroll
local listScroll = GuiHelpers.Create("ScrollingFrame", {
    Name = "ScriptListScroll",
    Parent = leftPanel,
    Size = UDim2.new(1, 0, 1, -104),
    Position = UDim2.new(0, 0, 0, 104),
    BackgroundColor3 = theme.BackgroundTertiary,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = theme.Scrollbar,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 8,
    ClipsDescendants = true,
})

local listLayout = GuiHelpers.Create("UIListLayout", {
    Parent = listScroll,
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 1),
})

-- ========================
-- RIGHT: TAB BAR + EDITOR
-- ========================
local tabBar = GuiHelpers.Create("Frame", {
    Name = "SVTabBar",
    Parent = rightPanel,
    Size = UDim2.new(1, 0, 0, 28),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.TabInactive,
    BorderSizePixel = 0,
    ZIndex = 9,
    ClipsDescendants = true,
})

local tabBarLayout = GuiHelpers.Create("UIListLayout", {
    Parent = tabBar,
    FillDirection = Enum.FillDirection.Horizontal,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2),
})

-- Toolbar
local toolbar = GuiHelpers.Create("Frame", {
    Name = "Toolbar",
    Parent = rightPanel,
    Size = UDim2.new(1, 0, 0, 28),
    Position = UDim2.new(0, 0, 0, 28),
    BackgroundColor3 = theme.BackgroundSecondary,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local function MakeToolBtn(label, xPos, w, color)
    local btn = GuiHelpers.Create("TextButton", {
        Name = "Btn_" .. label,
        Parent = toolbar,
        Size = UDim2.new(0, w or 60, 1, -6),
        Position = UDim2.new(0, xPos, 0, 3),
        BackgroundColor3 = color or theme.ButtonBg,
        Text = label,
        TextColor3 = theme.Text,
        TextSize = 10,
        Font = Enum.Font.GothamSemibold,
        BorderSizePixel = 0,
        ZIndex = 10,
    })
    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 3)
        c.Parent = btn
    end)
    GuiHelpers.AddHover(btn, color or theme.ButtonBg, theme.ButtonHover)
    return btn
end

local saveBtn    = MakeToolBtn("Save",     4,   48)
local execBtn    = MakeToolBtn("Execute",  56,  56, theme.AccentDark)
local decompBtn  = MakeToolBtn("Decompile", 116, 70)
local copyBtn    = MakeToolBtn("Copy All", 190, 64)
local searchBtn  = MakeToolBtn("Find",     258, 44)

local infoLabel = GuiHelpers.Create("TextLabel", {
    Name = "InfoLabel",
    Parent = toolbar,
    Size = UDim2.new(0, 200, 1, 0),
    Position = UDim2.new(1, -205, 0, 0),
    BackgroundTransparency = 1,
    Text = "No script selected",
    TextColor3 = theme.TextSecondary,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 10,
})

-- Code search bar (hidden by default)
local codeSearchBar = GuiHelpers.Create("Frame", {
    Name = "CodeSearchBar",
    Parent = rightPanel,
    Size = UDim2.new(1, 0, 0, 26),
    Position = UDim2.new(0, 0, 0, 56),
    BackgroundColor3 = theme.BackgroundSecondary,
    BorderSizePixel = 0,
    ZIndex = 9,
    Visible = false,
})

local codeSearchBox = GuiHelpers.Create("TextBox", {
    Name = "CodeSearchBox",
    Parent = codeSearchBar,
    Size = UDim2.new(1, -100, 1, -6),
    Position = UDim2.new(0, 4, 0, 3),
    BackgroundColor3 = theme.InputBg,
    Text = "",
    PlaceholderText = "Find in code...",
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
    c.CornerRadius = UDim.new(0, 3)
    c.Parent = codeSearchBox
end)
pcall(function()
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, 6)
    p.Parent = codeSearchBox
end)

local codeSearchResults = GuiHelpers.Create("TextLabel", {
    Name = "CodeSearchResults",
    Parent = codeSearchBar,
    Size = UDim2.new(0, 90, 1, 0),
    Position = UDim2.new(1, -94, 0, 0),
    BackgroundTransparency = 1,
    Text = "0 matches",
    TextColor3 = theme.TextSecondary,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 10,
})

local searchVisible = false
searchBtn.MouseButton1Click:Connect(function()
    pcall(function()
        searchVisible = not searchVisible
        codeSearchBar.Visible = searchVisible
        local editorTop = searchVisible and 82 or 56
        if rightPanel:FindFirstChild("EditorArea") then
            rightPanel.EditorArea.Position = UDim2.new(0, 0, 0, editorTop)
            rightPanel.EditorArea.Size = UDim2.new(1, 0, 1, -editorTop)
        end
    end)
end)

-- Editor Area
local editorArea = GuiHelpers.Create("Frame", {
    Name = "EditorArea",
    Parent = rightPanel,
    Size = UDim2.new(1, 0, 1, -56),
    Position = UDim2.new(0, 0, 0, 56),
    BackgroundColor3 = theme.BackgroundTertiary,
    BorderSizePixel = 0,
    ZIndex = 8,
    ClipsDescendants = true,
})

-- Line numbers panel
local lineNumPanel = GuiHelpers.Create("Frame", {
    Name = "LineNumPanel",
    Parent = editorArea,
    Size = UDim2.new(0, 36, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.BackgroundSecondary,
    BorderSizePixel = 0,
    ZIndex = 9,
    ClipsDescendants = true,
})

local lineNumScroll = GuiHelpers.Create("ScrollingFrame", {
    Name = "LineNumScroll",
    Parent = lineNumPanel,
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 9,
    ScrollingEnabled = false,
})

local lineNumLayout = GuiHelpers.Create("UIListLayout", {
    Parent = lineNumScroll,
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 0),
})

-- Code scroll
local codeScroll = GuiHelpers.Create("ScrollingFrame", {
    Name = "CodeScroll",
    Parent = editorArea,
    Size = UDim2.new(1, -36, 1, 0),
    Position = UDim2.new(0, 36, 0, 0),
    BackgroundColor3 = theme.BackgroundTertiary,
    BorderSizePixel = 0,
    ScrollBarThickness = 5,
    ScrollBarImageColor3 = theme.Scrollbar,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 8,
    ClipsDescendants = true,
})

local codeLinesFrame = GuiHelpers.Create("Frame", {
    Name = "CodeLines",
    Parent = codeScroll,
    Size = UDim2.new(1, 0, 0, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 8,
})

local codeLinesLayout = GuiHelpers.Create("UIListLayout", {
    Parent = codeLinesFrame,
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 0),
})

-- Sync scroll between line numbers and code
codeScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    pcall(function()
        lineNumScroll.CanvasPosition = Vector2.new(
            0,
            codeScroll.CanvasPosition.Y
        )
    end)
end)

-- ========================
-- TOKENIZER / SYNTAX HIGHLIGHT
-- ========================
local KEYWORDS = {
    ["and"] = true, ["break"] = true, ["do"] = true,
    ["else"] = true, ["elseif"] = true, ["end"] = true,
    ["false"] = true, ["for"] = true, ["function"] = true,
    ["if"] = true, ["in"] = true, ["local"] = true,
    ["nil"] = true, ["not"] = true, ["or"] = true,
    ["repeat"] = true, ["return"] = true, ["then"] = true,
    ["true"] = true, ["until"] = true, ["while"] = true,
    ["continue"] = true, ["type"] = true, ["export"] = true,
}

local BUILTINS = {
    ["print"] = true, ["warn"] = true, ["error"] = true,
    ["pairs"] = true, ["ipairs"] = true, ["next"] = true,
    ["pcall"] = true, ["xpcall"] = true, ["select"] = true,
    ["tostring"] = true, ["tonumber"] = true, ["typeof"] = true,
    ["unpack"] = true, ["rawget"] = true, ["rawset"] = true,
    ["setmetatable"] = true, ["getmetatable"] = true,
    ["require"] = true, ["loadstring"] = true,
    ["math"] = true, ["table"] = true, ["string"] = true,
    ["game"] = true, ["workspace"] = true, ["script"] = true,
    ["task"] = true, ["Instance"] = true, ["Enum"] = true,
    ["Vector3"] = true, ["Vector2"] = true, ["CFrame"] = true,
    ["Color3"] = true, ["UDim2"] = true, ["UDim"] = true,
    ["TweenInfo"] = true, ["Ray"] = true, ["Region3"] = true,
}

-- Token types
local TK = {
    KEYWORD   = 1,
    BUILTIN   = 2,
    STRING    = 3,
    NUMBER    = 4,
    COMMENT   = 5,
    OPERATOR  = 6,
    DEFAULT   = 7,
    SPACE     = 8,
}

local function GetTokenColor(tkType)
    if tkType == TK.KEYWORD   then return theme.SyntaxKeyword  end
    if tkType == TK.BUILTIN   then return theme.SyntaxFunction  end
    if tkType == TK.STRING    then return theme.SyntaxString    end
    if tkType == TK.NUMBER    then return theme.SyntaxNumber    end
    if tkType == TK.COMMENT   then return theme.SyntaxComment   end
    if tkType == TK.OPERATOR  then return theme.SyntaxOperator  end
    return theme.SyntaxDefault
end

local function TokenizeLine(line)
    local tokens = {}
    local i = 1
    local len = #line

    while i <= len do
        local ch = string.sub(line, i, i)

        -- Comment
        if ch == "-" and string.sub(line, i, i + 1) == "--" then
            local rest = string.sub(line, i)
            table.insert(tokens, {text = rest, ttype = TK.COMMENT})
            break

        -- String with "
        elseif ch == '"' then
            local j = i + 1
            while j <= len do
                local c2 = string.sub(line, j, j)
                if c2 == "\\" then
                    j = j + 2
                elseif c2 == '"' then
                    j = j + 1
                    break
                else
                    j = j + 1
                end
            end
            table.insert(tokens, {
                text = string.sub(line, i, j - 1),
                ttype = TK.STRING
            })
            i = j

        -- String with '
        elseif ch == "'" then
            local j = i + 1
            while j <= len do
                local c2 = string.sub(line, j, j)
                if c2 == "\\" then
                    j = j + 2
                elseif c2 == "'" then
                    j = j + 1
                    break
                else
                    j = j + 1
                end
            end
            table.insert(tokens, {
                text = string.sub(line, i, j - 1),
                ttype = TK.STRING
            })
            i = j

        -- Long string [[
        elseif ch == "[" and string.sub(line, i, i + 1) == "[[" then
            local j = string.find(line, "]]", i + 2, true)
            if j then
                table.insert(tokens, {
                    text = string.sub(line, i, j + 1),
                    ttype = TK.STRING
                })
                i = j + 2
            else
                table.insert(tokens, {
                    text = string.sub(line, i),
                    ttype = TK.STRING
                })
                break
            end

        -- Number
        elseif string.match(ch, "%d") or
            (ch == "." and string.match(string.sub(line, i + 1, i + 1), "%d")) then
            local j = i
            while j <= len do
                local c2 = string.sub(line, j, j)
                if string.match(c2, "[%d%.xXeE_]") or
                    ((c2 == "+" or c2 == "-") and
                    string.match(string.sub(line, j - 1, j - 1), "[eE]")) then
                    j = j + 1
                else
                    break
                end
            end
            table.insert(tokens, {
                text = string.sub(line, i, j - 1),
                ttype = TK.NUMBER
            })
            i = j

        -- Identifier or keyword
        elseif string.match(ch, "[%a_]") then
            local j = i
            while j <= len and string.match(string.sub(line, j, j), "[%w_]") do
                j = j + 1
            end
            local word = string.sub(line, i, j - 1)
            local ttype = TK.DEFAULT
            if KEYWORDS[word] then
                ttype = TK.KEYWORD
            elseif BUILTINS[word] then
                ttype = TK.BUILTIN
            end
            table.insert(tokens, {text = word, ttype = ttype})
            i = j

        -- Operators
        elseif string.match(ch, "[%+%-%*%/%^%%#&|~<>=%(%)%{%}%[%]%;%:%,%.%!%?]") then
            local two = string.sub(line, i, i + 1)
            local ops2 = {
                ["=="] = true, ["~="] = true, ["<="] = true,
                [">="] = true, [".."] = true, ["//"] = true,
                ["->"] = true, ["::"] = true,
            }
            if ops2[two] then
                table.insert(tokens, {text = two, ttype = TK.OPERATOR})
                i = i + 2
            else
                table.insert(tokens, {text = ch, ttype = TK.OPERATOR})
                i = i + 1
            end

        -- Space / whitespace
        elseif string.match(ch, "%s") then
            local j = i
            while j <= len and string.match(string.sub(line, j, j), "%s") do
                j = j + 1
            end
            table.insert(tokens, {
                text = string.sub(line, i, j - 1),
                ttype = TK.SPACE
            })
            i = j
        else
            table.insert(tokens, {text = ch, ttype = TK.DEFAULT})
            i = i + 1
        end
    end

    return tokens
end

-- ========================
-- RENDER CODE (highlighted)
-- ========================
local LINE_H = 16
local MAX_RENDER_LINES = 500

local function ClearCodeView()
    pcall(function()
        for _, c in ipairs(codeLinesFrame:GetChildren()) do
            pcall(function()
                if not c:IsA("UIListLayout") then
                    c:Destroy()
                end
            end)
        end
        for _, c in ipairs(lineNumScroll:GetChildren()) do
            pcall(function()
                if not c:IsA("UIListLayout") then
                    c:Destroy()
                end
            end)
        end
    end)
end

local function RenderCode(sourceCode, highlightQuery)
    pcall(function()
        ClearCodeView()
        if not sourceCode or sourceCode == "" then
            local empty = GuiHelpers.Create("TextLabel", {
                Parent = codeLinesFrame,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = "  -- No source available",
                TextColor3 = theme.SyntaxComment,
                TextSize = 11,
                Font = Enum.Font.Code,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 9,
                LayoutOrder = 1,
            })
            codeScroll.CanvasSize = UDim2.new(0, 0, 0, 30)
            lineNumScroll.CanvasSize = UDim2.new(0, 0, 0, 30)
            return
        end

        local lines = {}
        local lineNum = 1
        local lastEnd = 1
        local src = sourceCode

        for newlinePos in string.gmatch(src .. "\n", "()[^\n]*\n") do
        end

        -- Split lines
        local tempLines = {}
        local pos = 1
        while pos <= #src do
            local nlPos = string.find(src, "\n", pos, true)
            if nlPos then
                table.insert(tempLines, string.sub(src, pos, nlPos - 1))
                pos = nlPos + 1
            else
                table.insert(tempLines, string.sub(src, pos))
                break
            end
        end

        local totalLines = #tempLines
        local renderCount = math.min(totalLines, MAX_RENDER_LINES)
        local hq = highlightQuery and string.lower(highlightQuery) or ""

        for li = 1, renderCount do
            local line = tempLines[li] or ""
            local isHighlighted = hq ~= "" and
                string.find(string.lower(line), hq, 1, true)

            -- Line number
            local lineNumLabel = GuiHelpers.Create("TextLabel", {
                Name = "LN" .. li,
                Parent = lineNumScroll,
                Size = UDim2.new(1, 0, 0, LINE_H),
                BackgroundColor3 = isHighlighted
                    and theme.AccentDark
                    or theme.BackgroundSecondary,
                BackgroundTransparency = isHighlighted and 0 or 0,
                Text = tostring(li),
                TextColor3 = theme.TextDisabled,
                TextSize = 10,
                Font = Enum.Font.Code,
                TextXAlignment = Enum.TextXAlignment.Right,
                BorderSizePixel = 0,
                ZIndex = 9,
                LayoutOrder = li,
            })
            pcall(function()
                local p = Instance.new("UIPadding")
                p.PaddingRight = UDim.new(0, 4)
                p.Parent = lineNumLabel
            end)

            -- Code line row
            local lineRow = GuiHelpers.Create("Frame", {
                Name = "Line" .. li,
                Parent = codeLinesFrame,
                Size = UDim2.new(1, 0, 0, LINE_H),
                BackgroundColor3 = isHighlighted
                    and theme.AccentDark
                    or theme.BackgroundTertiary,
                BackgroundTransparency = isHighlighted and 0.7 or 1,
                BorderSizePixel = 0,
                ZIndex = 8,
                LayoutOrder = li,
            })

            -- If line is empty just skip tokenize
            if line == "" then
                -- empty row placeholder
            else
                local tokens = TokenizeLine(line)
                local xOff = 4
                local charW = 7

                for _, tok in ipairs(tokens) do
                    if tok.ttype ~= TK.SPACE then
                        local tokW = #tok.text * charW
                        local tokLabel = GuiHelpers.Create("TextLabel", {
                            Parent = lineRow,
                            Size = UDim2.new(0, tokW + 2, 1, 0),
                            Position = UDim2.new(0, xOff, 0, 0),
                            BackgroundTransparency = 1,
                            Text = tok.text,
                            TextColor3 = GetTokenColor(tok.ttype),
                            TextSize = 11,
                            Font = Enum.Font.Code,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            BorderSizePixel = 0,
                            ZIndex = 9,
                        })
                        xOff = xOff + tokW
                    else
                        xOff = xOff + #tok.text * charW
                    end
                end
            end
        end

        if totalLines > MAX_RENDER_LINES then
            local warnLabel = GuiHelpers.Create("TextLabel", {
                Parent = codeLinesFrame,
                Size = UDim2.new(1, 0, 0, LINE_H),
                BackgroundTransparency = 1,
                Text = "  -- [Showing first " .. MAX_RENDER_LINES ..
                    " of " .. totalLines .. " lines]",
                TextColor3 = theme.Warning,
                TextSize = 11,
                Font = Enum.Font.Code,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 9,
                LayoutOrder = MAX_RENDER_LINES + 1,
            })
        end

        local totalH = (math.min(totalLines, MAX_RENDER_LINES) + 1) * LINE_H
        codeScroll.CanvasSize = UDim2.new(0, 800, 0, totalH)
        lineNumScroll.CanvasSize = UDim2.new(0, 0, 0, totalH)
    end)
end

DEX.RenderCode = RenderCode

-- ========================
-- DECOMPILER (Luau bytecode attempt)
-- ========================
local function TryDecompile(scriptInstance)
    local result = nil

    -- Method 1: decompile() function (some executors)
    if not result then
        pcall(function()
            if decompile then
                result = decompile(scriptInstance)
            end
        end)
    end

    -- Method 2: decompilelua (alternative name)
    if not result then
        pcall(function()
            if decompilelua then
                result = decompilelua(scriptInstance)
            end
        end)
    end

    -- Method 3: getscriptbytecode + reconstruct header
    if not result then
        pcall(function()
            if getscriptbytecode then
                local bytecode = getscriptbytecode(scriptInstance)
                if bytecode and #bytecode > 0 then
                    result = "-- [Bytecode retrieved: " ..
                        #bytecode .. " bytes]\n" ..
                        "-- Decompiler not available in Solara\n" ..
                        "-- Bytecode hash: " ..
                        string.format("0x%X", #bytecode) .. "\n\n" ..
                        "-- Script: " ..
                        Utils.GetInstanceName(scriptInstance) .. "\n" ..
                        "-- Class: " ..
                        Utils.GetClassName(scriptInstance) .. "\n" ..
                        "-- Path: " ..
                        Utils.GetFullPath(scriptInstance)
                end
            end
        end)
    end

    -- Method 4: Try direct .Source access
    if not result then
        pcall(function()
            local src = scriptInstance.Source
            if src and #src > 0 then
                result = src
            end
        end)
    end

    -- Method 5: Reconstruct from environment
    if not result then
        pcall(function()
            local ok, env = pcall(function()
                return getfenv and getfenv(scriptInstance) or nil
            end)
            if ok and env then
                local lines = {
                    "-- [Reconstructed from environment]",
                    "-- Script: " .. Utils.GetInstanceName(scriptInstance),
                    "-- Class: " .. Utils.GetClassName(scriptInstance),
                    "-- Path: " .. Utils.GetFullPath(scriptInstance),
                    "",
                }
                result = table.concat(lines, "\n")
            end
        end)
    end

    -- Final fallback
    if not result or result == "" then
        result = "-- [DEX Decompiler]\n" ..
            "-- Script: " ..
            Utils.GetInstanceName(scriptInstance) .. "\n" ..
            "-- Class: " ..
            Utils.GetClassName(scriptInstance) .. "\n" ..
            "-- Path: " ..
            Utils.GetFullPath(scriptInstance) .. "\n\n" ..
            "-- Source not accessible in Solara environment.\n" ..
            "-- This executor (39% sUNC) does not support:\n" ..
            "--   getscriptclosure, getsenv, debug.getprotos\n\n" ..
            "-- What we know about this script:\n" ..
            "-- Disabled: " ..
            tostring(Utils.SafeGet(scriptInstance, "Disabled")) .. "\n" ..
            "-- RunContext: " ..
            tostring(Utils.SafeGet(scriptInstance, "RunContext")) .. "\n"
    end

    return result
end

DEX.TryDecompile = TryDecompile

-- ========================
-- TAB MANAGEMENT
-- ========================
local function RebuildTabBar()
    pcall(function()
        for _, c in ipairs(tabBar:GetChildren()) do
            pcall(function()
                if c:IsA("TextButton") or c:IsA("Frame") then
                    c:Destroy()
                end
            end)
        end

        for i, tabData in ipairs(SVState.Tabs) do
            local isActive = (i == SVState.ActiveTabIndex)
            local tabW = math.min(120, math.max(60, #tabData.name * 7 + 24))

            local tabFrame = GuiHelpers.Create("Frame", {
                Name = "SVTab" .. i,
                Parent = tabBar,
                Size = UDim2.new(0, tabW, 1, 0),
                BackgroundColor3 = isActive
                    and theme.TabActive
                    or theme.TabInactive,
                BorderSizePixel = 0,
                ZIndex = 10,
                LayoutOrder = i,
            })

            local tabLabel = GuiHelpers.Create("TextButton", {
                Parent = tabFrame,
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = Utils.Truncate(tabData.name, 14),
                TextColor3 = isActive
                    and theme.Accent
                    or theme.TextSecondary,
                TextSize = 10,
                Font = Enum.Font.Gotham,
                BorderSizePixel = 0,
                ZIndex = 11,
            })

            local closeTab = GuiHelpers.Create("TextButton", {
                Parent = tabFrame,
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(1, -15, 0.5, -7),
                BackgroundTransparency = 1,
                Text = "x",
                TextColor3 = theme.TextDisabled,
                TextSize = 9,
                Font = Enum.Font.GothamBold,
                BorderSizePixel = 0,
                ZIndex = 12,
            })

            local capturedI = i
            tabLabel.MouseButton1Click:Connect(function()
                pcall(function()
                    SVState.ActiveTabIndex = capturedI
                    local td = SVState.Tabs[capturedI]
                    if td then
                        RenderCode(td.source, "")
                        infoLabel.Text = td.name ..
                            " [" .. td.className .. "]"
                    end
                    RebuildTabBar()
                end)
            end)

            closeTab.MouseButton1Click:Connect(function()
                pcall(function()
                    table.remove(SVState.Tabs, capturedI)
                    if SVState.ActiveTabIndex >= capturedI then
                        SVState.ActiveTabIndex =
                            math.max(1, SVState.ActiveTabIndex - 1)
                    end
                    if #SVState.Tabs == 0 then
                        SVState.ActiveTabIndex = 0
                        ClearCodeView()
                        infoLabel.Text = "No script selected"
                    else
                        local td = SVState.Tabs[SVState.ActiveTabIndex]
                        if td then
                            RenderCode(td.source, "")
                            infoLabel.Text = td.name ..
                                " [" .. td.className .. "]"
                        end
                    end
                    RebuildTabBar()
                end)
            end)
        end
    end)
end

local function OpenScriptInTab(scriptInstance)
    pcall(function()
        local name = Utils.GetInstanceName(scriptInstance)
        local cls = Utils.GetClassName(scriptInstance)

        -- Check if already open
        for i, tab in ipairs(SVState.Tabs) do
            if tab.instance == scriptInstance then
                SVState.ActiveTabIndex = i
                RenderCode(tab.source, "")
                infoLabel.Text = name .. " [" .. cls .. "]"
                RebuildTabBar()
                return
            end
        end

        -- Get source
        local source = ""
        local ok = pcall(function()
            source = scriptInstance.Source or ""
        end)
        if not ok or source == "" then
            source = TryDecompile(scriptInstance)
        end

        local newTab = {
            instance = scriptInstance,
            name = name,
            className = cls,
            source = source,
            path = Utils.GetFullPath(scriptInstance),
        }

        table.insert(SVState.Tabs, newTab)
        SVState.ActiveTabIndex = #SVState.Tabs

        RenderCode(source, "")
        infoLabel.Text = name .. " [" .. cls .. "]"
        RebuildTabBar()
    end)
end

-- ========================
-- SCRIPT LIST RENDERING
-- ========================
local TYPE_COLORS = {
    ["Script"] = Color3.new(0.85, 0.35, 0.35),
    ["LocalScript"] = Color3.new(0.35, 0.70, 0.95),
    ["ModuleScript"] = Color3.new(0.65, 0.90, 0.35),
}

local function RenderScriptList()
    pcall(function()
        for _, c in ipairs(listScroll:GetChildren()) do
            pcall(function()
                if not c:IsA("UIListLayout") then
                    c:Destroy()
                end
            end)
        end

        local query = string.lower(SVState.SearchQuery)
        local typeF = SVState.TypeFilter
        local shown = 0

        for idx, scriptData in ipairs(SVState.AllScripts) do
            local name = string.lower(scriptData.name)
            local cls = scriptData.className

            local matchSearch = query == "" or
                string.find(name, query, 1, true) or
                string.find(string.lower(scriptData.path), query, 1, true)

            local matchType = (typeF == "All") or
                (typeF == "Local"  and cls == "LocalScript") or
                (typeF == "Server" and cls == "Script") or
                (typeF == "Module" and cls == "ModuleScript")

            if matchSearch and matchType then
                shown = shown + 1

                local rowColor = (shown % 2 == 0)
                    and theme.BackgroundSecondary
                    or theme.BackgroundTertiary

                local row = GuiHelpers.Create("Frame", {
                    Name = "ScriptRow" .. idx,
                    Parent = listScroll,
                    Size = UDim2.new(1, 0, 0, 38),
                    BackgroundColor3 = rowColor,
                    BorderSizePixel = 0,
                    ZIndex = 9,
                    LayoutOrder = shown,
                })

                local clsColor = TYPE_COLORS[cls] or theme.TextSecondary
                local badge = GuiHelpers.Create("TextLabel", {
                    Parent = row,
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(0, 4, 0, 4),
                    BackgroundColor3 = clsColor,
                    Text = string.sub(cls, 1, 1),
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 8,
                    Font = Enum.Font.GothamBold,
                    BorderSizePixel = 0,
                    ZIndex = 10,
                })
                pcall(function()
                    local c = Instance.new("UICorner")
                    c.CornerRadius = UDim.new(0, 3)
                    c.Parent = badge
                end)

                local nameLabel = GuiHelpers.Create("TextLabel", {
                    Parent = row,
                    Size = UDim2.new(1, -24, 0, 16),
                    Position = UDim2.new(0, 22, 0, 2),
                    BackgroundTransparency = 1,
                    Text = Utils.Truncate(scriptData.name, 24),
                    TextColor3 = theme.Text,
                    TextSize = 11,
                    Font = Enum.Font.GothamSemibold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 10,
                })

                local pathLabel = GuiHelpers.Create("TextLabel", {
                    Parent = row,
                    Size = UDim2.new(1, -8, 0, 14),
                    Position = UDim2.new(0, 4, 0, 20),
                    BackgroundTransparency = 1,
                    Text = Utils.Truncate(scriptData.path, 30),
                    TextColor3 = theme.TextDisabled,
                    TextSize = 9,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 10,
                })

                local openBtn = GuiHelpers.Create("TextButton", {
                    Parent = row,
                    Size = UDim2.new(1, 0, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    BorderSizePixel = 0,
                    ZIndex = 11,
                })

                local capturedData = scriptData
                local capturedRow = row

                openBtn.MouseEnter:Connect(function()
                    pcall(function()
                        capturedRow.BackgroundColor3 = theme.NodeHover
                    end)
                end)
                openBtn.MouseLeave:Connect(function()
                    pcall(function()
                        capturedRow.BackgroundColor3 = rowColor
                    end)
                end)

                openBtn.MouseButton1Click:Connect(function()
                    pcall(function()
                        OpenScriptInTab(capturedData.instance)
                    end)
                end)

                openBtn.MouseButton2Click:Connect(function()
                    pcall(function()
                        local mp = UserInputService:GetMouseLocation()
                        DEX.ShowContextMenu({
                            {
                                label = "Open",
                                callback = function()
                                    OpenScriptInTab(capturedData.instance)
                                end
                            },
                            {
                                label = "Decompile",
                                callback = function()
                                    pcall(function()
                                        local result = TryDecompile(
                                            capturedData.instance
                                        )
                                        local decompTab = {
                                            instance = capturedData.instance,
                                            name = "[D]" .. capturedData.name,
                                            className = capturedData.className,
                                            source = result,
                                            path = capturedData.path,
                                        }
                                        table.insert(SVState.Tabs, decompTab)
                                        SVState.ActiveTabIndex = #SVState.Tabs
                                        RenderCode(result, "")
                                        infoLabel.Text = "[Decompiled] " ..
                                            capturedData.name
                                        RebuildTabBar()
                                    end)
                                end
                            },
                            {
                                label = "Copy Path",
                                callback = function()
                                    pcall(function()
                                        setclipboard(capturedData.path)
                                        DEX.ShowNotification(
                                            "Copied", capturedData.path, "success"
                                        )
                                    end)
                                end
                            },
                            {
                                label = "Save to File",
                                callback = function()
                                    pcall(function()
                                        local src = ""
                                        pcall(function()
                                            src = capturedData.instance.Source or ""
                                        end)
                                        if src == "" then
                                            src = TryDecompile(capturedData.instance)
                                        end
                                        local fname = "dex_" ..
                                            capturedData.name .. ".lua"
                                        writefile(fname, src)
                                        DEX.ShowNotification(
                                            "Saved", fname, "success"
                                        )
                                    end)
                                end
                            },
                        }, mp.X, mp.Y)
                    end)
                end)
            end
        end

        local totalH = shown * 39
        listScroll.CanvasSize = UDim2.new(0, 0, 0, totalH)
        listTitle.Text = "Scripts (" .. #SVState.AllScripts ..
            " | shown: " .. shown .. ")"
    end)
end

-- ========================
-- SCAN SCRIPTS
-- ========================
local function ScanScripts()
    pcall(function()
        SVState.AllScripts = {}
        listTitle.Text = "Scanning..."

        task.spawn(function()
            pcall(function()
                local desc = game:GetDescendants()
                for _, inst in ipairs(desc) do
                    pcall(function()
                        local cls = Utils.GetClassName(inst)
                        if cls == "Script" or
                            cls == "LocalScript" or
                            cls == "ModuleScript" then
                            table.insert(SVState.AllScripts, {
                                instance = inst,
                                name = Utils.GetInstanceName(inst),
                                className = cls,
                                path = Utils.GetFullPath(inst),
                            })
                        end
                    end)
                end

                -- Sort by name
                table.sort(SVState.AllScripts, function(a, b)
                    return a.name < b.name
                end)

                RenderScriptList()
                DEX.ShowNotification(
                    "Scripts",
                    "Found " .. #SVState.AllScripts .. " scripts",
                    "success"
                )
                DEX.StatusText.Text = "Scripts: " ..
                    #SVState.AllScripts .. " found"
            end)
        end)
    end)
end

-- ========================
-- TOOLBAR ACTIONS
-- ========================
saveBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local tab = SVState.Tabs[SVState.ActiveTabIndex]
        if not tab then
            DEX.ShowNotification("Save", "No script open", "warning")
            return
        end
        local fname = "dex_" .. tab.name .. ".lua"
        writefile(fname, tab.source or "")
        DEX.ShowNotification("Saved", fname, "success")
    end)
end)

execBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local tab = SVState.Tabs[SVState.ActiveTabIndex]
        if not tab or not tab.source or tab.source == "" then
            DEX.ShowNotification("Execute", "No source to execute", "warning")
            return
        end
        local fn, err = loadstring(tab.source)
        if fn then
            task.spawn(function()
                local ok2, err2 = pcall(fn)
                if not ok2 then
                    DEX.ShowNotification("Execute Error", tostring(err2), "error")
                else
                    DEX.ShowNotification("Execute", "Script ran successfully", "success")
                end
            end)
        else
            DEX.ShowNotification("Syntax Error", tostring(err), "error")
        end
    end)
end)

decompBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local tab = SVState.Tabs[SVState.ActiveTabIndex]
        if not tab then
            DEX.ShowNotification("Decompile", "No script selected", "warning")
            return
        end
        local result = TryDecompile(tab.instance)
        tab.source = result
        RenderCode(result, "")
        DEX.ShowNotification("Decompile", "Attempted decompilation", "info")
    end)
end)

copyBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local tab = SVState.Tabs[SVState.ActiveTabIndex]
        if not tab then
            DEX.ShowNotification("Copy", "No script open", "warning")
            return
        end
        setclipboard(tab.source or "")
        DEX.ShowNotification("Copied", "Source copied to clipboard", "success")
    end)
end)

-- Code search
local function DoCodeSearch()
    pcall(function()
        local q = codeSearchBox.Text
        local tab = SVState.Tabs[SVState.ActiveTabIndex]
        if not tab or not tab.source then return end

        if q == "" then
            RenderCode(tab.source, "")
            codeSearchResults.Text = "0 matches"
            return
        end

        local src = tab.source
        local lq = string.lower(q)
        local count = 0
        local pos = 1
        while true do
            local f = string.find(string.lower(src), lq, pos, true)
            if not f then break end
            count = count + 1
            pos = f + 1
        end

        RenderCode(src, q)
        codeSearchResults.Text = count .. " match" .. (count ~= 1 and "es" or "")
    end)
end

codeSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    pcall(DoCodeSearch)
end)

-- ========================
-- FILTER BUTTONS
-- ========================
for _, ft in ipairs(filterTypes) do
    local fb = filterBtns[ft]
    if fb then
        local capturedFt = ft
        fb.MouseButton1Click:Connect(function()
            pcall(function()
                SVState.TypeFilter = capturedFt
                for _, ft2 in ipairs(filterTypes) do
                    local btn2 = filterBtns[ft2]
                    if btn2 then
                        if ft2 == capturedFt then
                            btn2.BackgroundColor3 = theme.Accent
                            btn2.TextColor3 = Color3.new(1, 1, 1)
                        else
                            btn2.BackgroundColor3 = theme.ButtonBg
                            btn2.TextColor3 = theme.TextSecondary
                        end
                    end
                end
                RenderScriptList()
            end)
        end)
    end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    pcall(function()
        SVState.SearchQuery = searchBox.Text
        RenderScriptList()
    end)
end)

scanBtn.MouseButton1Click:Connect(function()
    ScanScripts()
end)

GuiHelpers.AddHover(scanBtn, theme.AccentDark, theme.Accent)

-- ========================
-- AUTO SCAN on tab switch
-- ========================
local svLoaded = false
local origSwitch = DEX.SwitchTab
DEX.SwitchTab = function(tabName)
    origSwitch(tabName)
    if tabName == "Scripts" and not svLoaded then
        svLoaded = true
        task.spawn(function()
            pcall(function()
                task.wait(0.2)
                ScanScripts()
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

print("[DEX] Part 3: Script Viewer loaded")
print("[DEX] Type 'готов' for Part 4: Remotes Panel + Remote Spy")

getgenv().DEX = DEX
