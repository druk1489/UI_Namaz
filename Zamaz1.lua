-- DEX Explorer v1.0 for Solara
-- Part 1: Core Foundation (FIXED - no transparent bg)
-- =====================================================

local DEX = {}
getgenv().DEX = DEX

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

DEX.Version = "1.0.0"
DEX.IsOpen = false
DEX.ActiveTab = "Explorer"
DEX.Tabs = {"Explorer","Scripts","Remotes","Players","Console","Settings"}

DEX.State = {
    SelectedInstance = nil,
    ExpandedNodes = {},
    SearchQuery = "",
    ClassFilter = "",
    RemoteLog = {},
    ConsoleHistory = {},
    ConsoleIndex = 0,
    ScriptTabs = {},
    ActiveScriptTab = 1,
    RemoteSpy = false,
    SpyLog = {},
}

-- ========================
-- THEMES
-- ========================
DEX.Themes = {}

DEX.Themes.Dark = {
    Name = "Dark",
    Background = Color3.new(0.11, 0.11, 0.13),
    BackgroundSecondary = Color3.new(0.15, 0.15, 0.18),
    BackgroundTertiary = Color3.new(0.09, 0.09, 0.11),
    TitleBar = Color3.new(0.08, 0.08, 0.10),
    Accent = Color3.new(0.25, 0.55, 1.0),
    AccentHover = Color3.new(0.35, 0.65, 1.0),
    AccentDark = Color3.new(0.15, 0.40, 0.85),
    Text = Color3.new(0.92, 0.92, 0.95),
    TextSecondary = Color3.new(0.60, 0.60, 0.65),
    TextDisabled = Color3.new(0.35, 0.35, 0.40),
    Border = Color3.new(0.20, 0.20, 0.25),
    BorderLight = Color3.new(0.28, 0.28, 0.33),
    Scrollbar = Color3.new(0.25, 0.25, 0.30),
    InputBg = Color3.new(0.13, 0.13, 0.16),
    ButtonBg = Color3.new(0.20, 0.20, 0.25),
    ButtonHover = Color3.new(0.28, 0.28, 0.33),
    Success = Color3.new(0.20, 0.80, 0.40),
    Warning = Color3.new(1.0, 0.75, 0.10),
    Error = Color3.new(1.0, 0.30, 0.30),
    NodeHover = Color3.new(0.18, 0.18, 0.22),
    NodeSelected = Color3.new(0.20, 0.40, 0.75),
    TabActive = Color3.new(0.15, 0.15, 0.18),
    TabInactive = Color3.new(0.09, 0.09, 0.11),
    SyntaxKeyword = Color3.new(0.80, 0.47, 1.0),
    SyntaxString = Color3.new(0.60, 0.90, 0.45),
    SyntaxNumber = Color3.new(1.0, 0.75, 0.45),
    SyntaxComment = Color3.new(0.45, 0.52, 0.60),
    SyntaxFunction = Color3.new(0.40, 0.75, 1.0),
    SyntaxOperator = Color3.new(0.90, 0.90, 0.90),
    SyntaxDefault = Color3.new(0.92, 0.92, 0.95),
}

DEX.Themes.Light = {
    Name = "Light",
    Background = Color3.new(0.95, 0.95, 0.97),
    BackgroundSecondary = Color3.new(0.90, 0.90, 0.93),
    BackgroundTertiary = Color3.new(0.98, 0.98, 1.0),
    TitleBar = Color3.new(0.85, 0.85, 0.90),
    Accent = Color3.new(0.15, 0.45, 0.90),
    AccentHover = Color3.new(0.25, 0.55, 1.0),
    AccentDark = Color3.new(0.10, 0.30, 0.70),
    Text = Color3.new(0.10, 0.10, 0.12),
    TextSecondary = Color3.new(0.35, 0.35, 0.40),
    TextDisabled = Color3.new(0.60, 0.60, 0.65),
    Border = Color3.new(0.75, 0.75, 0.80),
    BorderLight = Color3.new(0.85, 0.85, 0.88),
    Scrollbar = Color3.new(0.65, 0.65, 0.70),
    InputBg = Color3.new(1.0, 1.0, 1.0),
    ButtonBg = Color3.new(0.85, 0.85, 0.90),
    ButtonHover = Color3.new(0.78, 0.78, 0.83),
    Success = Color3.new(0.10, 0.60, 0.25),
    Warning = Color3.new(0.80, 0.55, 0.0),
    Error = Color3.new(0.80, 0.15, 0.15),
    NodeHover = Color3.new(0.88, 0.88, 0.92),
    NodeSelected = Color3.new(0.70, 0.83, 1.0),
    TabActive = Color3.new(0.90, 0.90, 0.93),
    TabInactive = Color3.new(0.82, 0.82, 0.86),
    SyntaxKeyword = Color3.new(0.55, 0.10, 0.80),
    SyntaxString = Color3.new(0.15, 0.55, 0.15),
    SyntaxNumber = Color3.new(0.70, 0.40, 0.0),
    SyntaxComment = Color3.new(0.40, 0.45, 0.50),
    SyntaxFunction = Color3.new(0.10, 0.40, 0.75),
    SyntaxOperator = Color3.new(0.15, 0.15, 0.15),
    SyntaxDefault = Color3.new(0.10, 0.10, 0.12),
}

DEX.Themes.Monokai = {
    Name = "Monokai",
    Background = Color3.new(0.15, 0.15, 0.12),
    BackgroundSecondary = Color3.new(0.18, 0.18, 0.15),
    BackgroundTertiary = Color3.new(0.12, 0.12, 0.10),
    TitleBar = Color3.new(0.10, 0.10, 0.08),
    Accent = Color3.new(0.97, 0.58, 0.11),
    AccentHover = Color3.new(1.0, 0.68, 0.21),
    AccentDark = Color3.new(0.77, 0.42, 0.05),
    Text = Color3.new(0.97, 0.97, 0.95),
    TextSecondary = Color3.new(0.65, 0.65, 0.60),
    TextDisabled = Color3.new(0.40, 0.40, 0.38),
    Border = Color3.new(0.25, 0.25, 0.20),
    BorderLight = Color3.new(0.33, 0.33, 0.28),
    Scrollbar = Color3.new(0.30, 0.30, 0.25),
    InputBg = Color3.new(0.17, 0.17, 0.14),
    ButtonBg = Color3.new(0.25, 0.25, 0.20),
    ButtonHover = Color3.new(0.33, 0.33, 0.28),
    Success = Color3.new(0.65, 0.89, 0.18),
    Warning = Color3.new(0.97, 0.58, 0.11),
    Error = Color3.new(0.98, 0.15, 0.45),
    NodeHover = Color3.new(0.22, 0.22, 0.18),
    NodeSelected = Color3.new(0.40, 0.30, 0.10),
    TabActive = Color3.new(0.18, 0.18, 0.15),
    TabInactive = Color3.new(0.12, 0.12, 0.10),
    SyntaxKeyword = Color3.new(0.98, 0.15, 0.45),
    SyntaxString = Color3.new(0.89, 0.86, 0.34),
    SyntaxNumber = Color3.new(0.68, 0.51, 1.0),
    SyntaxComment = Color3.new(0.47, 0.53, 0.47),
    SyntaxFunction = Color3.new(0.65, 0.89, 0.18),
    SyntaxOperator = Color3.new(0.98, 0.15, 0.45),
    SyntaxDefault = Color3.new(0.97, 0.97, 0.95),
}

DEX.CurrentTheme = DEX.Themes.Dark

-- ========================
-- UTILS
-- ========================
local Utils = {}
DEX.Utils = Utils

function Utils.SafeGet(inst, prop)
    local ok, v = pcall(function() return inst[prop] end)
    if ok then return v end
    return nil
end

function Utils.SafeSet(inst, prop, val)
    local ok, e = pcall(function() inst[prop] = val end)
    return ok, e
end

function Utils.GetFullPath(inst)
    if not inst then return "nil" end
    local ok, result = pcall(function()
        local path = inst.Name
        local cur = inst.Parent
        local depth = 0
        while cur and depth < 50 do
            depth = depth + 1
            if cur == game then
                path = "game." .. path
                break
            end
            path = cur.Name .. "." .. path
            cur = cur.Parent
        end
        return path
    end)
    if ok then return result end
    return "unknown"
end

function Utils.GetClassName(inst)
    local ok, c = pcall(function() return inst.ClassName end)
    if ok then return c end
    return "Unknown"
end

function Utils.GetInstanceName(inst)
    local ok, n = pcall(function() return inst.Name end)
    if ok then return n end
    return "Unknown"
end

function Utils.Truncate(str, maxLen)
    if type(str) ~= "string" then str = tostring(str) end
    if #str > maxLen then
        return string.sub(str, 1, maxLen - 3) .. "..."
    end
    return str
end

function Utils.GetClassIcon(cls)
    return string.sub(cls, 1, 2)
end

function Utils.IsValidInstance(inst)
    local ok, r = pcall(function() return typeof(inst) == "Instance" end)
    return ok and r
end

function Utils.GetChildren(inst)
    local ok, c = pcall(function() return inst:GetChildren() end)
    if ok then return c end
    return {}
end

function Utils.GetDescendants(inst)
    local ok, d = pcall(function() return inst:GetDescendants() end)
    if ok then return d end
    return {}
end

function Utils.ColorToHex(c)
    local ok, r = pcall(function()
        return string.format("#%02X%02X%02X",
            math.floor(c.R*255),
            math.floor(c.G*255),
            math.floor(c.B*255))
    end)
    if ok then return r end
    return "#FFFFFF"
end

-- ========================
-- GUI HELPERS
-- ========================
local GuiHelpers = {}
DEX.GuiHelpers = GuiHelpers

function GuiHelpers.Create(className, props)
    local ok, inst = pcall(function()
        return Instance.new(className)
    end)
    if not ok then return nil end
    if props then
        for k, v in pairs(props) do
            pcall(function() inst[k] = v end)
        end
    end
    return inst
end

function GuiHelpers.Tween(instance, tweenInfo, props)
    local ok, tween = pcall(function()
        return TweenService:Create(instance, tweenInfo, props)
    end)
    if ok and tween then
        pcall(function() tween:Play() end)
        return tween
    end
    return nil
end

function GuiHelpers.MakeDraggable(frame, dragHandle)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local handle = dragHandle or frame

    handle.InputBegan:Connect(function(input)
        pcall(function()
            if input.UserInputType ==
                Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
            end
        end)
    end)

    UserInputService.InputChanged:Connect(function(input)
        pcall(function()
            if dragging and
                input.UserInputType ==
                Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
    end)

    UserInputService.InputEnded:Connect(function(input)
        pcall(function()
            if input.UserInputType ==
                Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
    end)
end

function GuiHelpers.MakeResizable(frame, minW, minH)
    minW = minW or 400
    minH = minH or 300
    local resizing = false
    local resizeStart = nil
    local startSize = nil
    local EDGE = 8

    local resizeHandle = GuiHelpers.Create("Frame", {
        Name = "ResizeHandle",
        Parent = frame,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, EDGE, 0, EDGE),
        Position = UDim2.new(1, -EDGE, 1, -EDGE),
        ZIndex = 100,
    })

    if resizeHandle then
        resizeHandle.InputBegan:Connect(function(input)
            pcall(function()
                if input.UserInputType ==
                    Enum.UserInputType.MouseButton1 then
                    resizing = true
                    resizeStart = input.Position
                    startSize = frame.Size
                end
            end)
        end)
    end

    UserInputService.InputChanged:Connect(function(input)
        pcall(function()
            if resizing and
                input.UserInputType ==
                Enum.UserInputType.MouseMovement then
                local delta = input.Position - resizeStart
                local newW = math.max(minW, startSize.X.Offset + delta.X)
                local newH = math.max(minH, startSize.Y.Offset + delta.Y)
                frame.Size = UDim2.new(0, newW, 0, newH)
            end
        end)
    end)

    UserInputService.InputEnded:Connect(function(input)
        pcall(function()
            if input.UserInputType ==
                Enum.UserInputType.MouseButton1 then
                resizing = false
            end
        end)
    end)
end

function GuiHelpers.AddHover(btn, normalColor, hoverColor)
    btn.MouseEnter:Connect(function()
        pcall(function()
            GuiHelpers.Tween(btn, TweenInfo.new(0.15),
                {BackgroundColor3 = hoverColor})
        end)
    end)
    btn.MouseLeave:Connect(function()
        pcall(function()
            GuiHelpers.Tween(btn, TweenInfo.new(0.15),
                {BackgroundColor3 = normalColor})
        end)
    end)
end

-- ========================
-- DESTROY EXISTING
-- ========================
local function DestroyExisting()
    pcall(function()
        local e = CoreGui:FindFirstChild("DEXExplorer")
        if e then e:Destroy() end
    end)
    pcall(function()
        if LocalPlayer and LocalPlayer.PlayerGui then
            local e = LocalPlayer.PlayerGui:FindFirstChild("DEXExplorer")
            if e then e:Destroy() end
        end
    end)
end

DestroyExisting()

-- ========================
-- SCREENGUI — БЕЗ фона
-- ========================
local screenGui = nil
pcall(function()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DEXExplorer"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999
    screenGui.IgnoreGuiInset = true

    -- ВАЖНО: BackgroundTransparency не нужен у ScreenGui
    -- Просто не добавляем никакого фонового фрейма

    local parentOk = pcall(function()
        screenGui.Parent = CoreGui
    end)
    if not parentOk then
        screenGui.Parent = LocalPlayer.PlayerGui
    end
end)

if not screenGui then
    error("DEX: Failed to create ScreenGui")
end

DEX.ScreenGui = screenGui

local theme = DEX.CurrentTheme

-- ========================
-- MAIN WINDOW (только окно, без теней на весь экран)
-- ========================
local mainFrame = GuiHelpers.Create("Frame", {
    Name = "MainFrame",
    Parent = screenGui,
    Size = UDim2.new(0, 900, 0, 600),
    Position = UDim2.new(0.5, -450, 0.5, -300),
    BackgroundColor3 = theme.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
})

if not mainFrame then
    error("DEX: Failed to create MainFrame")
end

DEX.MainFrame = mainFrame

pcall(function()
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
end)

-- Тонкая обводка вместо тени
pcall(function()
    local stroke = Instance.new("UIStroke")
    stroke.Color = theme.Border
    stroke.Thickness = 1.5
    stroke.Parent = mainFrame
end)

-- ========================
-- TITLE BAR
-- ========================
local titleBar = GuiHelpers.Create("Frame", {
    Name = "TitleBar",
    Parent = mainFrame,
    Size = UDim2.new(1, 0, 0, 36),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.TitleBar,
    BorderSizePixel = 0,
    ZIndex = 10,
})
DEX.TitleBar = titleBar

pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = titleBar
end)
pcall(function()
    local cover = GuiHelpers.Create("Frame", {
        Parent = titleBar,
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.new(0, 0, 1, -8),
        BackgroundColor3 = theme.TitleBar,
        BorderSizePixel = 0,
        ZIndex = titleBar.ZIndex,
    })
end)

local titleIcon = GuiHelpers.Create("TextLabel", {
    Name = "TitleIcon",
    Parent = titleBar,
    Size = UDim2.new(0, 28, 0, 28),
    Position = UDim2.new(0, 8, 0, 4),
    BackgroundColor3 = theme.Accent,
    Text = "D",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    ZIndex = titleBar.ZIndex + 1,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = titleIcon
end)

local titleText = GuiHelpers.Create("TextLabel", {
    Name = "TitleText",
    Parent = titleBar,
    Size = UDim2.new(0, 200, 1, 0),
    Position = UDim2.new(0, 42, 0, 0),
    BackgroundTransparency = 1,
    Text = "DEX Explorer v1.0",
    TextColor3 = theme.Text,
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = titleBar.ZIndex + 1,
})

local versionLabel = GuiHelpers.Create("TextLabel", {
    Name = "VersionLabel",
    Parent = titleBar,
    Size = UDim2.new(0, 100, 0, 16),
    Position = UDim2.new(0, 200, 0, 10),
    BackgroundTransparency = 1,
    Text = "Solara Edition",
    TextColor3 = theme.Accent,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = titleBar.ZIndex + 1,
})

local closeBtn = GuiHelpers.Create("TextButton", {
    Name = "CloseBtn",
    Parent = titleBar,
    Size = UDim2.new(0, 28, 0, 28),
    Position = UDim2.new(1, -34, 0, 4),
    BackgroundColor3 = Color3.new(0.90, 0.25, 0.25),
    Text = "X",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    ZIndex = titleBar.ZIndex + 1,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = closeBtn
end)

local minimizeBtn = GuiHelpers.Create("TextButton", {
    Name = "MinimizeBtn",
    Parent = titleBar,
    Size = UDim2.new(0, 28, 0, 28),
    Position = UDim2.new(1, -66, 0, 4),
    BackgroundColor3 = Color3.new(0.85, 0.65, 0.10),
    Text = "-",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    ZIndex = titleBar.ZIndex + 1,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = minimizeBtn
end)

GuiHelpers.MakeDraggable(mainFrame, titleBar)
GuiHelpers.MakeResizable(mainFrame, 700, 450)

closeBtn.MouseButton1Click:Connect(function()
    pcall(function()
        GuiHelpers.Tween(mainFrame, TweenInfo.new(0.2), {
            Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, 0),
        })
        task.delay(0.25, function()
            pcall(function() screenGui:Destroy() end)
        end)
    end)
end)

-- ========================
-- TAB BAR
-- ========================
local tabBar = GuiHelpers.Create("Frame", {
    Name = "TabBar",
    Parent = mainFrame,
    Size = UDim2.new(1, 0, 0, 32),
    Position = UDim2.new(0, 0, 0, 36),
    BackgroundColor3 = theme.TabInactive,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local tabLayout = GuiHelpers.Create("UIListLayout", {
    Parent = tabBar,
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 2),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

local tabSep = GuiHelpers.Create("Frame", {
    Name = "TabSeparator",
    Parent = mainFrame,
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.new(0, 0, 0, 68),
    BackgroundColor3 = theme.Accent,
    BorderSizePixel = 0,
    ZIndex = 9,
})

-- Content area — НЕПРОЗРАЧНЫЙ фон
local contentArea = GuiHelpers.Create("Frame", {
    Name = "ContentArea",
    Parent = mainFrame,
    Size = UDim2.new(1, 0, 1, -69),
    Position = UDim2.new(0, 0, 0, 69),
    BackgroundColor3 = theme.Background,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    ZIndex = 8,
    ClipsDescendants = true,
})

DEX.ContentArea = contentArea

local tabPages = GuiHelpers.Create("Frame", {
    Name = "TabPages",
    Parent = contentArea,
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.Background,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    ZIndex = 8,
})

DEX.TabPages = tabPages

DEX.Pages = {}
for _, tabName in ipairs(DEX.Tabs) do
    local page = GuiHelpers.Create("Frame", {
        Name = tabName .. "Page",
        Parent = tabPages,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = theme.Background,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 8,
    })
    DEX.Pages[tabName] = page
end

-- ========================
-- TAB BUTTONS
-- ========================
DEX.TabButtons = {}

local tabWidths = {
    ["Explorer"] = 80,
    ["Scripts"]  = 70,
    ["Remotes"]  = 76,
    ["Players"]  = 70,
    ["Console"]  = 68,
    ["Settings"] = 70,
}

local function SwitchTab(tabName)
    pcall(function()
        DEX.ActiveTab = tabName
        for _, t in ipairs(DEX.Tabs) do
            local btn = DEX.TabButtons[t]
            local page = DEX.Pages[t]
            if btn and page then
                if t == tabName then
                    btn.BackgroundColor3 = theme.TabActive
                    btn.TextColor3 = theme.Accent
                    page.Visible = true
                else
                    btn.BackgroundColor3 = theme.TabInactive
                    btn.TextColor3 = theme.TextSecondary
                    page.Visible = false
                end
            end
        end
    end)
end

DEX.SwitchTab = SwitchTab

for i, tabName in ipairs(DEX.Tabs) do
    local w = tabWidths[tabName] or 70
    local tabBtn = GuiHelpers.Create("TextButton", {
        Name = tabName .. "Tab",
        Parent = tabBar,
        Size = UDim2.new(0, w, 1, 0),
        BackgroundColor3 = theme.TabInactive,
        Text = tabName,
        TextColor3 = theme.TextSecondary,
        TextSize = 11,
        Font = Enum.Font.GothamSemibold,
        BorderSizePixel = 0,
        LayoutOrder = i,
        ZIndex = 10,
    })
    DEX.TabButtons[tabName] = tabBtn

    tabBtn.MouseButton1Click:Connect(function()
        SwitchTab(tabName)
    end)
    GuiHelpers.AddHover(tabBtn, theme.TabInactive, theme.ButtonHover)
end

-- Minimize
local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    pcall(function()
        minimized = not minimized
        if minimized then
            GuiHelpers.Tween(mainFrame, TweenInfo.new(0.2), {
                Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, 36),
            })
        else
            GuiHelpers.Tween(mainFrame, TweenInfo.new(0.2), {
                Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, 600),
            })
        end
    end)
end)

-- ========================
-- STATUS BAR
-- ========================
local statusBar = GuiHelpers.Create("Frame", {
    Name = "StatusBar",
    Parent = mainFrame,
    Size = UDim2.new(1, 0, 0, 20),
    Position = UDim2.new(0, 0, 1, -20),
    BackgroundColor3 = theme.TitleBar,
    BorderSizePixel = 0,
    ZIndex = 10,
})

local statusText = GuiHelpers.Create("TextLabel", {
    Name = "StatusText",
    Parent = statusBar,
    Size = UDim2.new(0.5, 0, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "Ready | DEX Explorer",
    TextColor3 = theme.TextSecondary,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 11,
})
DEX.StatusText = statusText

local fpsLabel = GuiHelpers.Create("TextLabel", {
    Name = "FPSLabel",
    Parent = statusBar,
    Size = UDim2.new(0, 140, 1, 0),
    Position = UDim2.new(1, -200, 0, 0),
    BackgroundTransparency = 1,
    Text = "FPS: -- | Ping: --",
    TextColor3 = theme.TextSecondary,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 11,
})
DEX.FPSLabel = fpsLabel

local memLabel = GuiHelpers.Create("TextLabel", {
    Name = "MemLabel",
    Parent = statusBar,
    Size = UDim2.new(0, 80, 1, 0),
    Position = UDim2.new(1, -62, 0, 0),
    BackgroundTransparency = 1,
    Text = "MEM: --",
    TextColor3 = theme.TextSecondary,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 11,
})
DEX.MemLabel = memLabel

-- ========================
-- LIVE STATS
-- ========================
local frameCount = 0
local lastFPSTime = tick()
local statsConn = nil

pcall(function()
    statsConn = RunService.RenderStepped:Connect(function()
        pcall(function()
            frameCount = frameCount + 1
            local now = tick()
            if now - lastFPSTime >= 1.0 then
                local fps = math.floor(frameCount / (now - lastFPSTime))
                frameCount = 0
                lastFPSTime = now
                local ping = 0
                pcall(function()
                    ping = math.floor(
                        LocalPlayer:GetNetworkPing() * 1000
                    )
                end)
                local mem = 0
                pcall(function()
                    mem = math.floor(gcinfo() / 1024)
                end)
                fpsLabel.Text = "FPS: " .. fps ..
                    " | Ping: " .. ping .. "ms"
                memLabel.Text = "MEM: " .. mem .. "MB"
            end
        end)
    end)
end)

DEX.StatsConnection = statsConn

-- ========================
-- CONTEXT MENU
-- ========================
local ctxMenu = GuiHelpers.Create("Frame", {
    Name = "ContextMenu",
    Parent = screenGui,
    Size = UDim2.new(0, 175, 0, 0),
    BackgroundColor3 = theme.BackgroundSecondary,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 200,
    ClipsDescendants = true,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = ctxMenu
end)
pcall(function()
    local s = Instance.new("UIStroke")
    s.Color = theme.Border
    s.Thickness = 1
    s.Parent = ctxMenu
end)

local ctxLayout = GuiHelpers.Create("UIListLayout", {
    Parent = ctxMenu,
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2),
})

DEX.ContextMenu = ctxMenu

local function HideContextMenu()
    pcall(function()
        ctxMenu.Visible = false
        for _, child in ipairs(ctxMenu:GetChildren()) do
            pcall(function()
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end)
        end
    end)
end

local function ShowContextMenu(items, posX, posY)
    pcall(function()
        HideContextMenu()
        local totalH = 4
        for idx, item in ipairs(items) do
            local btn = GuiHelpers.Create("TextButton", {
                Name = "CtxItem" .. idx,
                Parent = ctxMenu,
                Size = UDim2.new(1, -4, 0, 26),
                BackgroundColor3 = theme.BackgroundSecondary,
                Text = "  " .. item.label,
                TextColor3 = item.color or theme.Text,
                TextSize = 11,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                BorderSizePixel = 0,
                LayoutOrder = idx,
                ZIndex = 201,
            })
            totalH = totalH + 28
            GuiHelpers.AddHover(btn,
                theme.BackgroundSecondary, theme.ButtonHover)
            local cb = item.callback
            btn.MouseButton1Click:Connect(function()
                HideContextMenu()
                if cb then pcall(cb) end
            end)
        end
        ctxMenu.Size = UDim2.new(0, 175, 0, totalH)

        -- Не выходить за экран
        local screenX = screenGui.AbsoluteSize.X
        local screenY = screenGui.AbsoluteSize.Y
        local menuW = 175
        local menuH = totalH
        local finalX = posX
        local finalY = posY
        if finalX + menuW > screenX then
            finalX = screenX - menuW - 4
        end
        if finalY + menuH > screenY then
            finalY = screenY - menuH - 4
        end

        ctxMenu.Position = UDim2.new(0, finalX, 0, finalY)
        ctxMenu.Visible = true
    end)
end

DEX.ShowContextMenu = ShowContextMenu
DEX.HideContextMenu = HideContextMenu

UserInputService.InputBegan:Connect(function(input)
    pcall(function()
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if ctxMenu.Visible then
                HideContextMenu()
            end
        end
    end)
end)

-- ========================
-- NOTIFICATIONS
-- ========================
local notifContainer = GuiHelpers.Create("Frame", {
    Name = "NotifContainer",
    Parent = screenGui,
    Size = UDim2.new(0, 280, 1, 0),
    Position = UDim2.new(1, -290, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 300,
})

local notifLayout = GuiHelpers.Create("UIListLayout", {
    Parent = notifContainer,
    FillDirection = Enum.FillDirection.Vertical,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

local notifCount = 0

local function ShowNotification(title, message, notifType)
    if not DEX.SETState or DEX.SETState.NotificationsEnabled ~= false then
        notifType = notifType or "info"
        notifCount = notifCount + 1
        local typeColor = theme.Accent
        if notifType == "success" then typeColor = theme.Success end
        if notifType == "warning" then typeColor = theme.Warning end
        if notifType == "error" then typeColor = theme.Error end

        pcall(function()
            local notif = GuiHelpers.Create("Frame", {
                Name = "Notif" .. notifCount,
                Parent = notifContainer,
                Size = UDim2.new(0, 260, 0, 60),
                BackgroundColor3 = theme.BackgroundSecondary,
                BorderSizePixel = 0,
                LayoutOrder = notifCount,
            })
            pcall(function()
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 6)
                c.Parent = notif
            end)
            pcall(function()
                local s = Instance.new("UIStroke")
                s.Color = typeColor
                s.Thickness = 1
                s.Parent = notif
            end)

            local colorBar = GuiHelpers.Create("Frame", {
                Parent = notif,
                Size = UDim2.new(0, 3, 1, 0),
                BackgroundColor3 = typeColor,
                BorderSizePixel = 0,
                ZIndex = notif.ZIndex + 1,
            })
            pcall(function()
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 3)
                c.Parent = colorBar
            end)

            GuiHelpers.Create("TextLabel", {
                Parent = notif,
                Size = UDim2.new(1, -16, 0, 22),
                Position = UDim2.new(0, 10, 0, 4),
                BackgroundTransparency = 1,
                Text = title,
                TextColor3 = typeColor,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = notif.ZIndex + 1,
            })

            GuiHelpers.Create("TextLabel", {
                Parent = notif,
                Size = UDim2.new(1, -16, 0, 28),
                Position = UDim2.new(0, 10, 0, 24),
                BackgroundTransparency = 1,
                Text = Utils.Truncate(message, 60),
                TextColor3 = theme.TextSecondary,
                TextSize = 10,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                ZIndex = notif.ZIndex + 1,
            })

            notif.Position = UDim2.new(1, 10, 0, 0)
            GuiHelpers.Tween(notif,
                TweenInfo.new(0.3, Enum.EasingStyle.Back),
                {Position = UDim2.new(0, 0, 0, 0)})

            task.delay(3.5, function()
                pcall(function()
                    GuiHelpers.Tween(notif, TweenInfo.new(0.2), {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, 10, 0, 0),
                    })
                    task.delay(0.25, function()
                        pcall(function() notif:Destroy() end)
                    end)
                end)
            end)
        end)
    end
end

DEX.ShowNotification = ShowNotification

-- ========================
-- APPLY THEME
-- ========================
function DEX.ApplyTheme(themeName)
    local newTheme = DEX.Themes[themeName]
    if not newTheme then return end
    DEX.CurrentTheme = newTheme
    theme = newTheme
    pcall(function()
        mainFrame.BackgroundColor3 = theme.Background
        titleBar.BackgroundColor3 = theme.TitleBar
        tabBar.BackgroundColor3 = theme.TabInactive
        contentArea.BackgroundColor3 = theme.Background
        tabPages.BackgroundColor3 = theme.Background
        statusBar.BackgroundColor3 = theme.TitleBar
        statusText.TextColor3 = theme.TextSecondary
        fpsLabel.TextColor3 = theme.TextSecondary
        memLabel.TextColor3 = theme.TextSecondary
        titleText.TextColor3 = theme.Text
        versionLabel.TextColor3 = theme.Accent
        titleIcon.BackgroundColor3 = theme.Accent
        tabSep.BackgroundColor3 = theme.Accent
    end)
    for _, tabName in ipairs(DEX.Tabs) do
        pcall(function()
            local btn = DEX.TabButtons[tabName]
            local page = DEX.Pages[tabName]
            if btn then
                if tabName == DEX.ActiveTab then
                    btn.BackgroundColor3 = theme.TabActive
                    btn.TextColor3 = theme.Accent
                else
                    btn.BackgroundColor3 = theme.TabInactive
                    btn.TextColor3 = theme.TextSecondary
                end
            end
            if page then
                page.BackgroundColor3 = theme.Background
            end
        end)
    end
    ShowNotification("Theme", "Switched to " .. themeName, "info")
end

-- ========================
-- STARTUP
-- ========================
SwitchTab("Explorer")
DEX.IsOpen = true

ShowNotification("DEX Explorer", "Loaded v" .. DEX.Version, "success")

print("[DEX] Core loaded | No transparent background")
print("[DEX] Type ready for Part 2")

getgenv().DEX = DEX
