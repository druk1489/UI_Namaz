-- DEX Explorer v1.0 for Solara
-- Part 4: Remotes Panel + Remote Spy (FIXED)
-- ============================================

assert(getgenv().DEX, "DEX Core (Part 1) must be loaded first!")

local DEX = getgenv().DEX
local theme = DEX.CurrentTheme
local Utils = DEX.Utils
local GuiHelpers = DEX.GuiHelpers
local remotesPage = DEX.Pages["Remotes"]

assert(remotesPage, "Remotes page not found!")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- ========================
-- REMOTES STATE
-- ========================
local RMState = {
    AllRemotes = {},
    SearchQuery = "",
    TypeFilter = "All",
    SelectedRemote = nil,
    SpyLog = {},
    SpyEnabled = false,
    SpyConnections = {},
    BlockedRemotes = {},
    MaxLogEntries = 200,
}

DEX.RMState = RMState

-- ========================
-- LAYOUT
-- ========================
local leftPanel = GuiHelpers.Create("Frame", {
    Name = "RMLeft",
    Parent = remotesPage,
    Size = UDim2.new(0, 230, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.BackgroundTertiary,
    BorderSizePixel = 0,
    ZIndex = 8,
    ClipsDescendants = true,
})

local divider = GuiHelpers.Create("Frame", {
    Name = "RMDivider",
    Parent = remotesPage,
    Size = UDim2.new(0, 2, 1, 0),
    Position = UDim2.new(0, 230, 0, 0),
    BackgroundColor3 = theme.Border,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local rightPanel = GuiHelpers.Create("Frame", {
    Name = "RMRight",
    Parent = remotesPage,
    Size = UDim2.new(1, -232, 1, 0),
    Position = UDim2.new(0, 232, 0, 0),
    BackgroundColor3 = theme.Background,
    BorderSizePixel = 0,
    ZIndex = 8,
    ClipsDescendants = true,
})

-- ========================
-- LEFT: REMOTE LIST HEADER
-- ========================
local listHeader = GuiHelpers.Create("Frame", {
    Name = "RMListHeader",
    Parent = leftPanel,
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.BackgroundSecondary,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local listTitle = GuiHelpers.Create("TextLabel", {
    Name = "RMListTitle",
    Parent = listHeader,
    Size = UDim2.new(1, -8, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "Remotes (0)",
    TextColor3 = theme.Text,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 10,
})

local searchBox = GuiHelpers.Create("TextBox", {
    Name = "RMSearch",
    Parent = leftPanel,
    Size = UDim2.new(1, -8, 0, 22),
    Position = UDim2.new(0, 4, 0, 32),
    BackgroundColor3 = theme.InputBg,
    Text = "",
    PlaceholderText = "Search remotes...",
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
    Name = "RMFilterFrame",
    Parent = leftPanel,
    Size = UDim2.new(1, 0, 0, 22),
    Position = UDim2.new(0, 0, 0, 56),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local rmFilterTypes = {"All", "RE", "RF", "BE", "BF"}
local rmFilterBtns = {}
local rmFilterW = math.floor(230 / #rmFilterTypes)

for i, ft in ipairs(rmFilterTypes) do
    local isActive = (ft == "All")
    local fb = GuiHelpers.Create("TextButton", {
        Name = "RMFilter_" .. ft,
        Parent = filterFrame,
        Size = UDim2.new(0, rmFilterW - 2, 1, -2),
        Position = UDim2.new(0, (i-1)*rmFilterW + 1, 0, 1),
        BackgroundColor3 = isActive and theme.Accent or theme.ButtonBg,
        Text = ft,
        TextColor3 = isActive
            and Color3.new(1, 1, 1) or theme.TextSecondary,
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
    rmFilterBtns[ft] = fb
end

local scanBtn = GuiHelpers.Create("TextButton", {
    Name = "RMScanBtn",
    Parent = leftPanel,
    Size = UDim2.new(1, -8, 0, 20),
    Position = UDim2.new(0, 4, 0, 80),
    BackgroundColor3 = theme.AccentDark,
    Text = "Scan Remotes",
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

local remotesScroll = GuiHelpers.Create("ScrollingFrame", {
    Name = "RemotesScroll",
    Parent = leftPanel,
    Size = UDim2.new(1, 0, 1, -102),
    Position = UDim2.new(0, 0, 0, 102),
    BackgroundColor3 = theme.BackgroundTertiary,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = theme.Scrollbar,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 8,
    ClipsDescendants = true,
})

local remotesLayout = GuiHelpers.Create("UIListLayout", {
    Parent = remotesScroll,
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 1),
})

-- ========================
-- RIGHT: TAB BAR
-- ========================
local rightTabBar = GuiHelpers.Create("Frame", {
    Name = "RMRightTabBar",
    Parent = rightPanel,
    Size = UDim2.new(1, 0, 0, 28),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.TabInactive,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local rightTabNames = {"Fire", "Spy Log", "Blocked"}
local rightTabBtns = {}
local rightTabPages = {}
local activeRightTab = "Fire"
local rightTabW = math.floor(400 / #rightTabNames)

for i, rtn in ipairs(rightTabNames) do
    local isActive = (rtn == "Fire")
    local rtb = GuiHelpers.Create("TextButton", {
        Name = "RMRTab_" .. rtn,
        Parent = rightTabBar,
        Size = UDim2.new(0, rightTabW, 1, 0),
        Position = UDim2.new(0, (i-1)*rightTabW, 0, 0),
        BackgroundColor3 = isActive
            and theme.TabActive or theme.TabInactive,
        Text = rtn,
        TextColor3 = isActive
            and theme.Accent or theme.TextSecondary,
        TextSize = 11,
        Font = Enum.Font.GothamSemibold,
        BorderSizePixel = 0,
        ZIndex = 10,
    })
    rightTabBtns[rtn] = rtb

    local page = GuiHelpers.Create("Frame", {
        Name = "RMRPage_" .. rtn,
        Parent = rightPanel,
        Size = UDim2.new(1, 0, 1, -28),
        Position = UDim2.new(0, 0, 0, 28),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = isActive,
        ZIndex = 8,
    })
    rightTabPages[rtn] = page
end

local function SwitchRightTab(name)
    pcall(function()
        activeRightTab = name
        for _, rtn in ipairs(rightTabNames) do
            local btn = rightTabBtns[rtn]
            local page = rightTabPages[rtn]
            if btn and page then
                if rtn == name then
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

for _, rtn in ipairs(rightTabNames) do
    local capturedRtn = rtn
    if rightTabBtns[rtn] then
        rightTabBtns[rtn].MouseButton1Click:Connect(function()
            SwitchRightTab(capturedRtn)
        end)
    end
end

-- ========================
-- FIRE PAGE
-- ========================
local firePage = rightTabPages["Fire"]

local fireHeader = GuiHelpers.Create("Frame", {
    Name = "FireHeader",
    Parent = firePage,
    Size = UDim2.new(1, 0, 0, 36),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.BackgroundSecondary,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local selectedLabel = GuiHelpers.Create("TextLabel", {
    Name = "SelectedLabel",
    Parent = fireHeader,
    Size = UDim2.new(1, -8, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "No remote selected",
    TextColor3 = theme.TextSecondary,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 10,
})

GuiHelpers.Create("TextLabel", {
    Name = "ArgsLabel",
    Parent = firePage,
    Size = UDim2.new(1, -8, 0, 16),
    Position = UDim2.new(0, 8, 0, 40),
    BackgroundTransparency = 1,
    Text = "Arguments (Lua values, comma separated):",
    TextColor3 = theme.TextSecondary,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 9,
})

local argsInput = GuiHelpers.Create("TextBox", {
    Name = "ArgsInput",
    Parent = firePage,
    Size = UDim2.new(1, -8, 0, 80),
    Position = UDim2.new(0, 4, 0, 58),
    BackgroundColor3 = theme.InputBg,
    Text = "",
    PlaceholderText = 'e.g.  "Hello", 42, true',
    PlaceholderColor3 = theme.TextDisabled,
    TextColor3 = theme.Text,
    TextSize = 11,
    Font = Enum.Font.Code,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    MultiLine = true,
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = argsInput
end)
pcall(function()
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, 6)
    p.PaddingTop = UDim.new(0, 4)
    p.Parent = argsInput
end)

local fireControlsRow = GuiHelpers.Create("Frame", {
    Name = "FireControls",
    Parent = firePage,
    Size = UDim2.new(1, -8, 0, 28),
    Position = UDim2.new(0, 4, 0, 142),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local fireBtn = GuiHelpers.Create("TextButton", {
    Name = "FireBtn",
    Parent = fireControlsRow,
    Size = UDim2.new(0, 80, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.Success,
    Text = "Fire",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = fireBtn
end)

local invokeBtn = GuiHelpers.Create("TextButton", {
    Name = "InvokeBtn",
    Parent = fireControlsRow,
    Size = UDim2.new(0, 80, 1, 0),
    Position = UDim2.new(0, 84, 0, 0),
    BackgroundColor3 = theme.Accent,
    Text = "Invoke",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = invokeBtn
end)

local blockBtn = GuiHelpers.Create("TextButton", {
    Name = "BlockBtn",
    Parent = fireControlsRow,
    Size = UDim2.new(0, 80, 1, 0),
    Position = UDim2.new(0, 168, 0, 0),
    BackgroundColor3 = theme.Error,
    Text = "Block",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = blockBtn
end)

local copyPathBtn = GuiHelpers.Create("TextButton", {
    Name = "CopyPathBtn",
    Parent = fireControlsRow,
    Size = UDim2.new(0, 80, 1, 0),
    Position = UDim2.new(0, 252, 0, 0),
    BackgroundColor3 = theme.ButtonBg,
    Text = "Copy Path",
    TextColor3 = theme.Text,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    BorderSizePixel = 0,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = copyPathBtn
end)

GuiHelpers.Create("TextLabel", {
    Name = "ResponseLabel",
    Parent = firePage,
    Size = UDim2.new(1, -8, 0, 14),
    Position = UDim2.new(0, 8, 0, 176),
    BackgroundTransparency = 1,
    Text = "Response:",
    TextColor3 = theme.TextSecondary,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 9,
})

local responseArea = GuiHelpers.Create("ScrollingFrame", {
    Name = "ResponseArea",
    Parent = firePage,
    Size = UDim2.new(1, -8, 0, 100),
    Position = UDim2.new(0, 4, 0, 192),
    BackgroundColor3 = theme.BackgroundTertiary,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = theme.Scrollbar,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 9,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = responseArea
end)

local responseText = GuiHelpers.Create("TextLabel", {
    Name = "ResponseText",
    Parent = responseArea,
    Size = UDim2.new(1, -8, 0, 30),
    Position = UDim2.new(0, 4, 0, 4),
    BackgroundTransparency = 1,
    Text = "-- Fire a remote to see response",
    TextColor3 = theme.SyntaxComment,
    TextSize = 10,
    Font = Enum.Font.Code,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true,
    ZIndex = 10,
})

GuiHelpers.Create("TextLabel", {
    Parent = firePage,
    Size = UDim2.new(0, 100, 0, 14),
    Position = UDim2.new(0, 8, 0, 298),
    BackgroundTransparency = 1,
    Text = "Repeat (times):",
    TextColor3 = theme.TextSecondary,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 9,
})

local repeatInput = GuiHelpers.Create("TextBox", {
    Name = "RepeatInput",
    Parent = firePage,
    Size = UDim2.new(0, 50, 0, 20),
    Position = UDim2.new(0, 112, 0, 296),
    BackgroundColor3 = theme.InputBg,
    Text = "1",
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
    c.Parent = repeatInput
end)

GuiHelpers.Create("TextLabel", {
    Parent = firePage,
    Size = UDim2.new(0, 60, 0, 14),
    Position = UDim2.new(0, 170, 0, 298),
    BackgroundTransparency = 1,
    Text = "Delay(s):",
    TextColor3 = theme.TextSecondary,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 9,
})

local delayInput = GuiHelpers.Create("TextBox", {
    Name = "DelayInput",
    Parent = firePage,
    Size = UDim2.new(0, 50, 0, 20),
    Position = UDim2.new(0, 228, 0, 296),
    BackgroundColor3 = theme.InputBg,
    Text = "0",
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
    c.Parent = delayInput
end)

-- ========================
-- VALUE TO STRING
-- ========================
local function ValueToStr(val)
    local ok, result = pcall(function()
        local t = typeof(val)
        if t == "nil" then return "nil" end
        if t == "string" then return '"' .. val .. '"' end
        if t == "number" then return tostring(val) end
        if t == "boolean" then return tostring(val) end
        if t == "table" then
            local parts = {}
            local count = 0
            for k, v in pairs(val) do
                count = count + 1
                if count <= 8 then
                    table.insert(parts,
                        tostring(k) .. "=" .. tostring(v))
                end
            end
            return "{" .. table.concat(parts, ", ") .. "}"
        end
        if t == "Instance" then
            return Utils.GetFullPath(val)
        end
        if t == "Vector3" then
            return string.format("Vector3(%.2f,%.2f,%.2f)",
                val.X, val.Y, val.Z)
        end
        if t == "CFrame" then
            local p = val.Position
            return string.format("CFrame(%.2f,%.2f,%.2f)",
                p.X, p.Y, p.Z)
        end
        return tostring(val)
    end)
    if ok then return result end
    return tostring(val)
end

-- ========================
-- SET RESPONSE
-- ========================
local function SetResponse(text, color)
    pcall(function()
        local txt = tostring(text)
        responseText.Text = txt
        responseText.TextColor3 = color or theme.Text
        local lines = 1
        for _ in string.gmatch(txt, "\n") do
            lines = lines + 1
        end
        local h = math.max(30, lines * 14 + 8)
        responseText.Size = UDim2.new(1, -8, 0, h)
        responseArea.CanvasSize = UDim2.new(0, 0, 0, h + 8)
    end)
end

-- ========================
-- ADD SPY LOG ENTRY
-- ========================
local function AddSpyLog(entry)
    pcall(function()
        table.insert(RMState.SpyLog, 1, entry)
        if #RMState.SpyLog > RMState.MaxLogEntries then
            table.remove(RMState.SpyLog, #RMState.SpyLog)
        end
    end)
end

-- ========================
-- PARSE ARGS
-- Без vararg, без table.unpack
-- ========================
local function ParseArgs(argsStr)
    local args = {}
    if not argsStr or argsStr == "" then
        return args
    end

    -- Попытка через loadstring
    local fn, err = loadstring("return " .. argsStr)
    if fn then
        local ok, r1, r2, r3, r4, r5, r6, r7, r8 = pcall(fn)
        if ok then
            if r1 ~= nil then table.insert(args, r1) end
            if r2 ~= nil then table.insert(args, r2) end
            if r3 ~= nil then table.insert(args, r3) end
            if r4 ~= nil then table.insert(args, r4) end
            if r5 ~= nil then table.insert(args, r5) end
            if r6 ~= nil then table.insert(args, r6) end
            if r7 ~= nil then table.insert(args, r7) end
            if r8 ~= nil then table.insert(args, r8) end
            return args
        end
    end

    -- Ручной парсинг
    local parts = {}
    local current = ""
    local depth = 0
    local inStr = false
    local strChar = nil

    for i = 1, #argsStr do
        local ch = string.sub(argsStr, i, i)
        if inStr then
            current = current .. ch
            if ch == strChar then
                inStr = false
                strChar = nil
            end
        elseif ch == '"' or ch == "'" then
            inStr = true
            strChar = ch
            current = current .. ch
        elseif ch == "{" or ch == "(" or ch == "[" then
            depth = depth + 1
            current = current .. ch
        elseif ch == "}" or ch == ")" or ch == "]" then
            depth = depth - 1
            current = current .. ch
        elseif ch == "," and depth == 0 then
            table.insert(parts, current)
            current = ""
        else
            current = current .. ch
        end
    end
    if current ~= "" then
        table.insert(parts, current)
    end

    for _, part in ipairs(parts) do
        local trimmed = string.match(part, "^%s*(.-)%s*$")
        if trimmed and trimmed ~= "" then
            local pFn = loadstring("return " .. trimmed)
            if pFn then
                local pOk, pVal = pcall(pFn)
                if pOk then
                    table.insert(args, pVal)
                else
                    table.insert(args, trimmed)
                end
            else
                table.insert(args, trimmed)
            end
        end
    end

    return args
end

-- ========================
-- FIRE WITH FIXED ARGS
-- Без table.unpack и vararg
-- ========================
local function FireRemote(remote, args, isInvoke)
    local cls = Utils.GetClassName(remote)
    local n = #args

    if isInvoke then
        if cls == "RemoteFunction" then
            if n == 0 then
                return pcall(function()
                    return remote:InvokeServer()
                end)
            elseif n == 1 then
                return pcall(function()
                    return remote:InvokeServer(args[1])
                end)
            elseif n == 2 then
                return pcall(function()
                    return remote:InvokeServer(args[1], args[2])
                end)
            elseif n == 3 then
                return pcall(function()
                    return remote:InvokeServer(
                        args[1], args[2], args[3]
                    )
                end)
            elseif n == 4 then
                return pcall(function()
                    return remote:InvokeServer(
                        args[1], args[2], args[3], args[4]
                    )
                end)
            else
                return pcall(function()
                    return remote:InvokeServer(
                        args[1], args[2], args[3],
                        args[4], args[5]
                    )
                end)
            end
        elseif cls == "BindableFunction" then
            if n == 0 then
                return pcall(function()
                    return remote:Invoke()
                end)
            elseif n == 1 then
                return pcall(function()
                    return remote:Invoke(args[1])
                end)
            elseif n == 2 then
                return pcall(function()
                    return remote:Invoke(args[1], args[2])
                end)
            else
                return pcall(function()
                    return remote:Invoke(args[1], args[2], args[3])
                end)
            end
        else
            return false, "Cannot invoke: " .. cls
        end
    else
        if cls == "RemoteEvent" then
            if n == 0 then
                return pcall(function()
                    remote:FireServer()
                end)
            elseif n == 1 then
                return pcall(function()
                    remote:FireServer(args[1])
                end)
            elseif n == 2 then
                return pcall(function()
                    remote:FireServer(args[1], args[2])
                end)
            elseif n == 3 then
                return pcall(function()
                    remote:FireServer(args[1], args[2], args[3])
                end)
            elseif n == 4 then
                return pcall(function()
                    remote:FireServer(
                        args[1], args[2], args[3], args[4]
                    )
                end)
            else
                return pcall(function()
                    remote:FireServer(
                        args[1], args[2], args[3],
                        args[4], args[5]
                    )
                end)
            end
        elseif cls == "BindableEvent" then
            if n == 0 then
                return pcall(function() remote:Fire() end)
            elseif n == 1 then
                return pcall(function() remote:Fire(args[1]) end)
            elseif n == 2 then
                return pcall(function()
                    remote:Fire(args[1], args[2])
                end)
            else
                return pcall(function()
                    remote:Fire(args[1], args[2], args[3])
                end)
            end
        else
            return false, "Cannot fire: " .. cls
        end
    end
end

-- ========================
-- DO FIRE (главная логика)
-- ========================
local function DoFire(remote, args, isInvoke)
    if not remote then
        DEX.ShowNotification("Fire", "No remote selected", "warning")
        return
    end

    local cls = Utils.GetClassName(remote)
    local name = Utils.GetInstanceName(remote)

    if RMState.BlockedRemotes[remote] then
        DEX.ShowNotification("Blocked", name .. " is blocked", "warning")
        return
    end

    local argsDisplay = ""
    pcall(function()
        local parts = {}
        for _, a in ipairs(args) do
            table.insert(parts, ValueToStr(a))
        end
        argsDisplay = table.concat(parts, ", ")
    end)

    local logEntry = {
        time = os.date("%H:%M:%S"),
        name = name,
        path = Utils.GetFullPath(remote),
        className = cls,
        args = argsDisplay,
        direction = "OUT",
        response = nil,
    }

    if isInvoke then
        task.spawn(function()
            pcall(function()
                local ok, result = FireRemote(remote, args, true)
                if ok then
                    local respStr = ValueToStr(result)
                    logEntry.response = respStr
                    AddSpyLog(logEntry)
                    SetResponse("Response:\n" .. respStr, theme.Success)
                    DEX.ShowNotification("Invoke OK", name, "success")
                else
                    local errStr = tostring(result)
                    logEntry.response = "ERROR: " .. errStr
                    AddSpyLog(logEntry)
                    SetResponse("Error:\n" .. errStr, theme.Error)
                    DEX.ShowNotification("Invoke Error", errStr, "error")
                end
            end)
        end)
    else
        local ok, err = FireRemote(remote, args, false)
        if ok then
            AddSpyLog(logEntry)
            SetResponse(
                "Fired OK\nArgs: " .. argsDisplay,
                theme.Success
            )
            DEX.ShowNotification("Fired", name, "success")
        else
            local errStr = tostring(err)
            SetResponse("Error: " .. errStr, theme.Error)
            DEX.ShowNotification("Fire Error", errStr, "error")
        end
    end
end

-- ========================
-- FIRE / INVOKE BUTTONS
-- ========================
fireBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local remote = RMState.SelectedRemote
        if not remote then
            DEX.ShowNotification("Fire", "Select a remote first", "warning")
            return
        end
        local args = ParseArgs(argsInput.Text)
        local times = math.clamp(
            tonumber(repeatInput.Text) or 1, 1, 100
        )
        local delay = math.clamp(
            tonumber(delayInput.Text) or 0, 0, 10
        )

        if times == 1 then
            DoFire(remote, args, false)
        else
            task.spawn(function()
                for i = 1, times do
                    pcall(function()
                        DoFire(remote, args, false)
                    end)
                    if delay > 0 then
                        task.wait(delay)
                    else
                        task.wait()
                    end
                end
                DEX.ShowNotification(
                    "Fire Complete",
                    "Fired " .. times .. " times",
                    "success"
                )
            end)
        end
    end)
end)

invokeBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local remote = RMState.SelectedRemote
        if not remote then
            DEX.ShowNotification(
                "Invoke", "Select a remote first", "warning"
            )
            return
        end
        local args = ParseArgs(argsInput.Text)
        DoFire(remote, args, true)
    end)
end)

blockBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local remote = RMState.SelectedRemote
        if not remote then return end
        local name = Utils.GetInstanceName(remote)
        if RMState.BlockedRemotes[remote] then
            RMState.BlockedRemotes[remote] = nil
            blockBtn.Text = "Block"
            blockBtn.BackgroundColor3 = theme.Error
            DEX.ShowNotification("Unblocked", name, "info")
        else
            RMState.BlockedRemotes[remote] = true
            blockBtn.Text = "Unblock"
            blockBtn.BackgroundColor3 = theme.Success
            DEX.ShowNotification("Blocked", name, "warning")
        end
    end)
end)

copyPathBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local remote = RMState.SelectedRemote
        if not remote then return end
        local path = Utils.GetFullPath(remote)
        setclipboard(path)
        DEX.ShowNotification("Copied", path, "success")
    end)
end)

GuiHelpers.AddHover(fireBtn, theme.Success,
    Color3.new(0.15, 0.75, 0.35))
GuiHelpers.AddHover(invokeBtn, theme.Accent, theme.AccentHover)
GuiHelpers.AddHover(copyPathBtn, theme.ButtonBg, theme.ButtonHover)

-- ========================
-- SPY LOG PAGE
-- ========================
local spyPage = rightTabPages["Spy Log"]

local spyToolbar = GuiHelpers.Create("Frame", {
    Name = "SpyToolbar",
    Parent = spyPage,
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.BackgroundSecondary,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local spyToggleBtn = GuiHelpers.Create("TextButton", {
    Name = "SpyToggleBtn",
    Parent = spyToolbar,
    Size = UDim2.new(0, 100, 1, -6),
    Position = UDim2.new(0, 4, 0, 3),
    BackgroundColor3 = theme.ButtonBg,
    Text = "Spy: OFF",
    TextColor3 = theme.TextSecondary,
    TextSize = 10,
    Font = Enum.Font.GothamSemibold,
    BorderSizePixel = 0,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 3)
    c.Parent = spyToggleBtn
end)

local clearLogBtn = GuiHelpers.Create("TextButton", {
    Name = "ClearLogBtn",
    Parent = spyToolbar,
    Size = UDim2.new(0, 70, 1, -6),
    Position = UDim2.new(0, 108, 0, 3),
    BackgroundColor3 = theme.ButtonBg,
    Text = "Clear Log",
    TextColor3 = theme.Text,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    BorderSizePixel = 0,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 3)
    c.Parent = clearLogBtn
end)

local saveLogBtn = GuiHelpers.Create("TextButton", {
    Name = "SaveLogBtn",
    Parent = spyToolbar,
    Size = UDim2.new(0, 70, 1, -6),
    Position = UDim2.new(0, 182, 0, 3),
    BackgroundColor3 = theme.ButtonBg,
    Text = "Save Log",
    TextColor3 = theme.Text,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    BorderSizePixel = 0,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 3)
    c.Parent = saveLogBtn
end)

local logCountLabel = GuiHelpers.Create("TextLabel", {
    Name = "LogCountLabel",
    Parent = spyToolbar,
    Size = UDim2.new(0, 100, 1, 0),
    Position = UDim2.new(1, -104, 0, 0),
    BackgroundTransparency = 1,
    Text = "0 entries",
    TextColor3 = theme.TextSecondary,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 10,
})

local spyScroll = GuiHelpers.Create("ScrollingFrame", {
    Name = "SpyScroll",
    Parent = spyPage,
    Size = UDim2.new(1, 0, 1, -30),
    Position = UDim2.new(0, 0, 0, 30),
    BackgroundColor3 = theme.BackgroundTertiary,
    BorderSizePixel = 0,
    ScrollBarThickness = 5,
    ScrollBarImageColor3 = theme.Scrollbar,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 8,
    ClipsDescendants = true,
})

local spyLayout = GuiHelpers.Create("UIListLayout", {
    Parent = spyScroll,
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2),
})

-- ========================
-- RENDER SPY LOG
-- ========================
local function RenderSpyLog()
    pcall(function()
        for _, c in ipairs(spyScroll:GetChildren()) do
            pcall(function()
                if not c:IsA("UIListLayout") then
                    c:Destroy()
                end
            end)
        end

        local entries = RMState.SpyLog
        logCountLabel.Text = #entries .. " entries"

        local clsColors = {
            ["RemoteEvent"]      = theme.Accent,
            ["RemoteFunction"]   = theme.Warning,
            ["BindableEvent"]    = theme.Success,
            ["BindableFunction"] = theme.SyntaxKeyword,
        }

        for i, entry in ipairs(entries) do
            local rowAccent = clsColors[entry.className] or theme.TextSecondary

            local row = GuiHelpers.Create("Frame", {
                Name = "SpyRow" .. i,
                Parent = spyScroll,
                Size = UDim2.new(1, -4, 0, 54),
                BackgroundColor3 = theme.BackgroundSecondary,
                BorderSizePixel = 0,
                ZIndex = 9,
                LayoutOrder = i,
            })
            pcall(function()
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 4)
                c.Parent = row
            end)

            local accentBar = GuiHelpers.Create("Frame", {
                Parent = row,
                Size = UDim2.new(0, 3, 1, 0),
                BackgroundColor3 = rowAccent,
                BorderSizePixel = 0,
                ZIndex = 10,
            })
            pcall(function()
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 3)
                c.Parent = accentBar
            end)

            GuiHelpers.Create("TextLabel", {
                Parent = row,
                Size = UDim2.new(0, 58, 0, 14),
                Position = UDim2.new(0, 8, 0, 2),
                BackgroundTransparency = 1,
                Text = entry.time,
                TextColor3 = theme.TextDisabled,
                TextSize = 9,
                Font = Enum.Font.Code,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 10,
            })

            local dirBg = entry.direction == "OUT"
                and theme.AccentDark or theme.Success
            local dirBadge = GuiHelpers.Create("TextLabel", {
                Parent = row,
                Size = UDim2.new(0, 28, 0, 14),
                Position = UDim2.new(0, 68, 0, 2),
                BackgroundColor3 = dirBg,
                Text = entry.direction,
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 8,
                Font = Enum.Font.GothamBold,
                BorderSizePixel = 0,
                ZIndex = 10,
            })
            pcall(function()
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 2)
                c.Parent = dirBadge
            end)

            local clsBadge = GuiHelpers.Create("TextLabel", {
                Parent = row,
                Size = UDim2.new(0, 100, 0, 14),
                Position = UDim2.new(0, 100, 0, 2),
                BackgroundColor3 = rowAccent,
                BackgroundTransparency = 0.5,
                Text = entry.className,
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 8,
                Font = Enum.Font.Gotham,
                BorderSizePixel = 0,
                ZIndex = 10,
            })
            pcall(function()
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 2)
                c.Parent = clsBadge
            end)

            GuiHelpers.Create("TextLabel", {
                Parent = row,
                Size = UDim2.new(1, -12, 0, 16),
                Position = UDim2.new(0, 8, 0, 17),
                BackgroundTransparency = 1,
                Text = Utils.Truncate(entry.name, 50),
                TextColor3 = rowAccent,
                TextSize = 11,
                Font = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 10,
            })

            local argsDisp = "Args: " .. (
                entry.args ~= "" and entry.args or "(none)"
            )
            GuiHelpers.Create("TextLabel", {
                Parent = row,
                Size = UDim2.new(1, -50, 0, 14),
                Position = UDim2.new(0, 8, 0, 34),
                BackgroundTransparency = 1,
                Text = Utils.Truncate(argsDisp, 80),
                TextColor3 = theme.TextSecondary,
                TextSize = 9,
                Font = Enum.Font.Code,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 10,
            })

            local copyRowBtn = GuiHelpers.Create("TextButton", {
                Parent = row,
                Size = UDim2.new(0, 36, 0, 14),
                Position = UDim2.new(1, -40, 0, 20),
                BackgroundColor3 = theme.ButtonBg,
                Text = "Copy",
                TextColor3 = theme.Text,
                TextSize = 8,
                Font = Enum.Font.Gotham,
                BorderSizePixel = 0,
                ZIndex = 11,
            })
            pcall(function()
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 2)
                c.Parent = copyRowBtn
            end)

            local capturedEntry = entry
            copyRowBtn.MouseButton1Click:Connect(function()
                pcall(function()
                    local txt = "[" .. capturedEntry.time .. "] " ..
                        capturedEntry.className .. " " ..
                        capturedEntry.name .. "\n" ..
                        "Path: " .. capturedEntry.path .. "\n" ..
                        "Args: " .. capturedEntry.args
                    if capturedEntry.response then
                        txt = txt .. "\nResponse: " ..
                            capturedEntry.response
                    end
                    setclipboard(txt)
                    DEX.ShowNotification(
                        "Copied", "Log entry copied", "success"
                    )
                end)
            end)
        end

        local totalH = #entries * 58
        spyScroll.CanvasSize = UDim2.new(0, 0, 0, totalH)
    end)
end

DEX.RenderSpyLog = RenderSpyLog

-- ========================
-- SPY ENGINE
-- OnClientEvent monitoring
-- ========================
local monitoredRemotes = {}
local spyActive = false

local function WrapRemoteForSpy(remoteData)
    pcall(function()
        local inst = remoteData.instance
        local cls = remoteData.className

        if monitoredRemotes[inst] then return end
        monitoredRemotes[inst] = true

        if cls == "RemoteEvent" then
            local ok, conn = pcall(function()
                return inst.OnClientEvent:Connect(function(
                    a1, a2, a3, a4, a5, a6, a7, a8
                )
                    pcall(function()
                        if not spyActive then return end
                        local argParts = {}
                        if a1 ~= nil then
                            table.insert(argParts, ValueToStr(a1))
                        end
                        if a2 ~= nil then
                            table.insert(argParts, ValueToStr(a2))
                        end
                        if a3 ~= nil then
                            table.insert(argParts, ValueToStr(a3))
                        end
                        if a4 ~= nil then
                            table.insert(argParts, ValueToStr(a4))
                        end
                        if a5 ~= nil then
                            table.insert(argParts, ValueToStr(a5))
                        end
                        if a6 ~= nil then
                            table.insert(argParts, ValueToStr(a6))
                        end
                        if a7 ~= nil then
                            table.insert(argParts, ValueToStr(a7))
                        end
                        if a8 ~= nil then
                            table.insert(argParts, ValueToStr(a8))
                        end
                        local entry = {
                            time = os.date("%H:%M:%S"),
                            name = Utils.GetInstanceName(inst),
                            path = Utils.GetFullPath(inst),
                            className = cls,
                            args = table.concat(argParts, ", "),
                            direction = "IN",
                            response = nil,
                        }
                        AddSpyLog(entry)
                        if activeRightTab == "Spy Log" then
                            RenderSpyLog()
                        end
                    end)
                end)
            end)
            if ok and conn then
                table.insert(RMState.SpyConnections, conn)
            end
        end
    end)
end

local function StartSpy()
    spyActive = true
    RMState.SpyEnabled = true
    spyToggleBtn.Text = "Spy: ON"
    spyToggleBtn.BackgroundColor3 = theme.Success
    spyToggleBtn.TextColor3 = Color3.new(1, 1, 1)
    for _, rd in ipairs(RMState.AllRemotes) do
        pcall(function()
            WrapRemoteForSpy(rd)
        end)
    end
    DEX.ShowNotification(
        "Remote Spy",
        "Monitoring " .. #RMState.AllRemotes .. " remotes",
        "success"
    )
end

local function StopSpy()
    spyActive = false
    RMState.SpyEnabled = false
    spyToggleBtn.Text = "Spy: OFF"
    spyToggleBtn.BackgroundColor3 = theme.ButtonBg
    spyToggleBtn.TextColor3 = theme.TextSecondary
    for _, conn in ipairs(RMState.SpyConnections) do
        pcall(function() conn:Disconnect() end)
    end
    RMState.SpyConnections = {}
    monitoredRemotes = {}
    DEX.ShowNotification("Remote Spy", "Spy stopped", "info")
end

spyToggleBtn.MouseButton1Click:Connect(function()
    pcall(function()
        if spyActive then
            StopSpy()
        else
            StartSpy()
        end
    end)
end)

clearLogBtn.MouseButton1Click:Connect(function()
    pcall(function()
        RMState.SpyLog = {}
        RenderSpyLog()
        DEX.ShowNotification("Log", "Cleared", "info")
    end)
end)

saveLogBtn.MouseButton1Click:Connect(function()
    pcall(function()
        if #RMState.SpyLog == 0 then
            DEX.ShowNotification("Save Log", "Log is empty", "warning")
            return
        end
        local lines = {
            "-- DEX Remote Spy Log",
            "-- " .. os.date("%Y-%m-%d %H:%M:%S"),
            "-- Total: " .. #RMState.SpyLog,
            "",
        }
        for i, entry in ipairs(RMState.SpyLog) do
            table.insert(lines,
                "[" .. i .. "] " .. entry.time ..
                " [" .. entry.direction .. "] " ..
                entry.className
            )
            table.insert(lines, "  Name: " .. entry.name)
            table.insert(lines, "  Path: " .. entry.path)
            table.insert(lines, "  Args: " .. entry.args)
            if entry.response then
                table.insert(lines,
                    "  Response: " .. entry.response)
            end
            table.insert(lines, "")
        end
        writefile("dex_spy_log.txt", table.concat(lines, "\n"))
        DEX.ShowNotification("Saved", "dex_spy_log.txt", "success")
    end)
end)

GuiHelpers.AddHover(clearLogBtn, theme.ButtonBg, theme.ButtonHover)
GuiHelpers.AddHover(saveLogBtn, theme.ButtonBg, theme.ButtonHover)

-- ========================
-- BLOCKED PAGE
-- ========================
local blockedPage = rightTabPages["Blocked"]

local blockedHeader = GuiHelpers.Create("Frame", {
    Name = "BlockedHeader",
    Parent = blockedPage,
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.BackgroundSecondary,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local blockedTitle = GuiHelpers.Create("TextLabel", {
    Name = "BlockedTitle",
    Parent = blockedHeader,
    Size = UDim2.new(0.6, 0, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "Blocked (0)",
    TextColor3 = theme.Text,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 10,
})

local clearBlockBtn = GuiHelpers.Create("TextButton", {
    Name = "ClearBlockBtn",
    Parent = blockedHeader,
    Size = UDim2.new(0, 80, 1, -6),
    Position = UDim2.new(1, -84, 0, 3),
    BackgroundColor3 = theme.ButtonBg,
    Text = "Unblock All",
    TextColor3 = theme.Text,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    BorderSizePixel = 0,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 3)
    c.Parent = clearBlockBtn
end)

local blockedScroll = GuiHelpers.Create("ScrollingFrame", {
    Name = "BlockedScroll",
    Parent = blockedPage,
    Size = UDim2.new(1, 0, 1, -30),
    Position = UDim2.new(0, 0, 0, 30),
    BackgroundColor3 = theme.BackgroundTertiary,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = theme.Scrollbar,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 8,
})

local blockedLayout = GuiHelpers.Create("UIListLayout", {
    Parent = blockedScroll,
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2),
})

local function RenderBlockedList()
    pcall(function()
        for _, c in ipairs(blockedScroll:GetChildren()) do
            pcall(function()
                if not c:IsA("UIListLayout") then
                    c:Destroy()
                end
            end)
        end
        local count = 0
        for remote, _ in pairs(RMState.BlockedRemotes) do
            count = count + 1
            local name = Utils.GetInstanceName(remote)
            local cls = Utils.GetClassName(remote)

            local row = GuiHelpers.Create("Frame", {
                Name = "BlockedRow" .. count,
                Parent = blockedScroll,
                Size = UDim2.new(1, -4, 0, 32),
                BackgroundColor3 = theme.BackgroundSecondary,
                BorderSizePixel = 0,
                ZIndex = 9,
                LayoutOrder = count,
            })
            pcall(function()
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 3)
                c.Parent = row
            end)

            GuiHelpers.Create("Frame", {
                Parent = row,
                Size = UDim2.new(0, 3, 1, 0),
                BackgroundColor3 = theme.Error,
                BorderSizePixel = 0,
                ZIndex = 10,
            })

            GuiHelpers.Create("TextLabel", {
                Parent = row,
                Size = UDim2.new(1, -90, 0, 16),
                Position = UDim2.new(0, 8, 0, 2),
                BackgroundTransparency = 1,
                Text = name .. " [" .. cls .. "]",
                TextColor3 = theme.Error,
                TextSize = 11,
                Font = Enum.Font.GothamSemibold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 10,
            })

            GuiHelpers.Create("TextLabel", {
                Parent = row,
                Size = UDim2.new(1, -90, 0, 12),
                Position = UDim2.new(0, 8, 0, 18),
                BackgroundTransparency = 1,
                Text = Utils.Truncate(Utils.GetFullPath(remote), 38),
                TextColor3 = theme.TextDisabled,
                TextSize = 9,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 10,
            })

            local unblockBtn = GuiHelpers.Create("TextButton", {
                Parent = row,
                Size = UDim2.new(0, 68, 1, -8),
                Position = UDim2.new(1, -72, 0, 4),
                BackgroundColor3 = theme.Success,
                Text = "Unblock",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 10,
                Font = Enum.Font.Gotham,
                BorderSizePixel = 0,
                ZIndex = 11,
            })
            pcall(function()
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 3)
                c.Parent = unblockBtn
            end)

            local capturedRemote = remote
            unblockBtn.MouseButton1Click:Connect(function()
                pcall(function()
                    RMState.BlockedRemotes[capturedRemote] = nil
                    RenderBlockedList()
                    DEX.ShowNotification(
                        "Unblocked",
                        Utils.GetInstanceName(capturedRemote),
                        "success"
                    )
                end)
            end)
        end

        blockedTitle.Text = "Blocked (" .. count .. ")"
        blockedScroll.CanvasSize = UDim2.new(0, 0, 0, count * 36)
    end)
end

clearBlockBtn.MouseButton1Click:Connect(function()
    pcall(function()
        RMState.BlockedRemotes = {}
        RenderBlockedList()
        DEX.ShowNotification("Unblocked", "All unblocked", "success")
    end)
end)
GuiHelpers.AddHover(clearBlockBtn, theme.ButtonBg, theme.ButtonHover)

-- ========================
-- REMOTE LIST RENDER
-- ========================
local TYPE_COLORS_RM = {
    ["RemoteEvent"]      = Color3.new(0.35, 0.65, 1.0),
    ["RemoteFunction"]   = Color3.new(1.0,  0.75, 0.20),
    ["BindableEvent"]    = Color3.new(0.40, 0.85, 0.45),
    ["BindableFunction"] = Color3.new(0.75, 0.40, 1.0),
}

local TYPE_SHORT = {
    ["RemoteEvent"]      = "RE",
    ["RemoteFunction"]   = "RF",
    ["BindableEvent"]    = "BE",
    ["BindableFunction"] = "BF",
}

local function RenderRemoteList()
    pcall(function()
        for _, c in ipairs(remotesScroll:GetChildren()) do
            pcall(function()
                if not c:IsA("UIListLayout") then
                    c:Destroy()
                end
            end)
        end

        local query = string.lower(RMState.SearchQuery)
        local typeF = RMState.TypeFilter
        local shown = 0

        local typeMap = {
            ["RE"] = "RemoteEvent",
            ["RF"] = "RemoteFunction",
            ["BE"] = "BindableEvent",
            ["BF"] = "BindableFunction",
        }

        for idx, rd in ipairs(RMState.AllRemotes) do
            local nameLower = string.lower(rd.name)
            local cls = rd.className

            local matchSearch = query == "" or
                string.find(nameLower, query, 1, true) or
                string.find(string.lower(rd.path), query, 1, true)

            local matchType = (typeF == "All") or
                (typeMap[typeF] == cls)

            if matchSearch and matchType then
                shown = shown + 1

                local rowBg = shown % 2 == 0
                    and theme.BackgroundSecondary
                    or theme.BackgroundTertiary

                local isBlocked = RMState.BlockedRemotes[rd.instance] == true
                local isSelected = RMState.SelectedRemote == rd.instance

                local row = GuiHelpers.Create("Frame", {
                    Name = "RMRow" .. idx,
                    Parent = remotesScroll,
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundColor3 = isSelected
                        and theme.NodeSelected or rowBg,
                    BorderSizePixel = 0,
                    ZIndex = 9,
                    LayoutOrder = shown,
                })

                local clsColor = TYPE_COLORS_RM[cls] or theme.TextSecondary
                local clsShort = TYPE_SHORT[cls] or "??"

                local badge = GuiHelpers.Create("TextLabel", {
                    Parent = row,
                    Size = UDim2.new(0, 20, 0, 14),
                    Position = UDim2.new(0, 3, 0, 4),
                    BackgroundColor3 = isBlocked
                        and theme.Error or clsColor,
                    Text = clsShort,
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

                if isBlocked then
                    GuiHelpers.Create("TextLabel", {
                        Parent = row,
                        Size = UDim2.new(0, 14, 0, 10),
                        Position = UDim2.new(1, -16, 0, 2),
                        BackgroundTransparency = 1,
                        Text = "X",
                        TextColor3 = theme.Error,
                        TextSize = 10,
                        Font = Enum.Font.GothamBold,
                        ZIndex = 11,
                    })
                end

                GuiHelpers.Create("TextLabel", {
                    Parent = row,
                    Size = UDim2.new(1, -28, 0, 16),
                    Position = UDim2.new(0, 26, 0, 2),
                    BackgroundTransparency = 1,
                    Text = Utils.Truncate(rd.name, 26),
                    TextColor3 = isSelected
                        and Color3.new(1, 1, 1) or theme.Text,
                    TextSize = 11,
                    Font = Enum.Font.GothamSemibold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 10,
                })

                GuiHelpers.Create("TextLabel", {
                    Parent = row,
                    Size = UDim2.new(1, -8, 0, 12),
                    Position = UDim2.new(0, 4, 0, 20),
                    BackgroundTransparency = 1,
                    Text = Utils.Truncate(rd.path, 30),
                    TextColor3 = theme.TextDisabled,
                    TextSize = 9,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 10,
                })

                GuiHelpers.Create("TextLabel", {
                    Parent = row,
                    Size = UDim2.new(1, -8, 0, 10),
                    Position = UDim2.new(0, 26, 0, 30),
                    BackgroundTransparency = 1,
                    Text = cls,
                    TextColor3 = clsColor,
                    TextSize = 9,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 10,
                })

                local clickBtn = GuiHelpers.Create("TextButton", {
                    Parent = row,
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    BorderSizePixel = 0,
                    ZIndex = 11,
                })

                local capturedRd = rd
                local capturedRow = row
                local capturedRowBg = rowBg

                clickBtn.MouseEnter:Connect(function()
                    pcall(function()
                        if RMState.SelectedRemote ~= capturedRd.instance then
                            capturedRow.BackgroundColor3 = theme.NodeHover
                        end
                    end)
                end)
                clickBtn.MouseLeave:Connect(function()
                    pcall(function()
                        if RMState.SelectedRemote ~= capturedRd.instance then
                            capturedRow.BackgroundColor3 = capturedRowBg
                        end
                    end)
                end)
                clickBtn.MouseButton1Click:Connect(function()
                    pcall(function()
                        RMState.SelectedRemote = capturedRd.instance
                        selectedLabel.Text = capturedRd.name ..
                            "  [" .. capturedRd.className .. "]"
                        if RMState.BlockedRemotes[capturedRd.instance] then
                            blockBtn.Text = "Unblock"
                            blockBtn.BackgroundColor3 = theme.Success
                        else
                            blockBtn.Text = "Block"
                            blockBtn.BackgroundColor3 = theme.Error
                        end
                        SwitchRightTab("Fire")
                        RenderRemoteList()
                    end)
                end)
                clickBtn.MouseButton2Click:Connect(function()
                    pcall(function()
                        local mp = UserInputService:GetMouseLocation()
                        local inst = capturedRd.instance
                        DEX.ShowContextMenu({
                            {
                                label = "Select",
                                callback = function()
                                    RMState.SelectedRemote = inst
                                    selectedLabel.Text = capturedRd.name ..
                                        " [" .. capturedRd.className .. "]"
                                    SwitchRightTab("Fire")
                                    RenderRemoteList()
                                end
                            },
                            {
                                label = "Fire (no args)",
                                callback = function()
                                    DoFire(inst, {}, false)
                                end
                            },
                            {
                                label = "Copy Path",
                                callback = function()
                                    setclipboard(capturedRd.path)
                                    DEX.ShowNotification(
                                        "Copied", capturedRd.path, "success"
                                    )
                                end
                            },
                            {
                                label = "Copy Name",
                                callback = function()
                                    setclipboard(capturedRd.name)
                                    DEX.ShowNotification(
                                        "Copied", capturedRd.name, "success"
                                    )
                                end
                            },
                            {
                                label = RMState.BlockedRemotes[inst]
                                    and "Unblock" or "Block",
                                color = RMState.BlockedRemotes[inst]
                                    and theme.Success or theme.Error,
                                callback = function()
                                    if RMState.BlockedRemotes[inst] then
                                        RMState.BlockedRemotes[inst] = nil
                                    else
                                        RMState.BlockedRemotes[inst] = true
                                    end
                                    RenderRemoteList()
                                    RenderBlockedList()
                                end
                            },
                        }, mp.X, mp.Y)
                    end)
                end)
            end
        end

        local totalH = shown * 42
        remotesScroll.CanvasSize = UDim2.new(0, 0, 0, totalH)
        listTitle.Text = "Remotes (" .. #RMState.AllRemotes ..
            " | shown: " .. shown .. ")"
    end)
end

-- ========================
-- SCAN REMOTES
-- ========================
local function ScanRemotes()
    pcall(function()
        RMState.AllRemotes = {}
        listTitle.Text = "Scanning..."

        task.spawn(function()
            pcall(function()
                local desc = game:GetDescendants()
                for _, inst in ipairs(desc) do
                    pcall(function()
                        local cls = Utils.GetClassName(inst)
                        if cls == "RemoteEvent" or
                            cls == "RemoteFunction" or
                            cls == "BindableEvent" or
                            cls == "BindableFunction" then
                            table.insert(RMState.AllRemotes, {
                                instance = inst,
                                name = Utils.GetInstanceName(inst),
                                className = cls,
                                path = Utils.GetFullPath(inst),
                            })
                        end
                    end)
                end

                table.sort(RMState.AllRemotes, function(a, b)
                    return a.className .. a.name <
                        b.className .. b.name
                end)

                RenderRemoteList()

                if spyActive then
                    for _, rd in ipairs(RMState.AllRemotes) do
                        pcall(function()
                            WrapRemoteForSpy(rd)
                        end)
                    end
                end

                DEX.ShowNotification(
                    "Remotes",
                    "Found " .. #RMState.AllRemotes,
                    "success"
                )
                DEX.StatusText.Text = "Remotes: " ..
                    #RMState.AllRemotes .. " found"
            end)
        end)
    end)
end

-- ========================
-- FILTER BUTTONS
-- ========================
for _, ft in ipairs(rmFilterTypes) do
    local capturedFt = ft
    local btn = rmFilterBtns[ft]
    if btn then
        btn.MouseButton1Click:Connect(function()
            pcall(function()
                RMState.TypeFilter = capturedFt
                for _, ft2 in ipairs(rmFilterTypes) do
                    local b2 = rmFilterBtns[ft2]
                    if b2 then
                        if ft2 == capturedFt then
                            b2.BackgroundColor3 = theme.Accent
                            b2.TextColor3 = Color3.new(1, 1, 1)
                        else
                            b2.BackgroundColor3 = theme.ButtonBg
                            b2.TextColor3 = theme.TextSecondary
                        end
                    end
                end
                RenderRemoteList()
            end)
        end)
    end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    pcall(function()
        RMState.SearchQuery = searchBox.Text
        RenderRemoteList()
    end)
end)

scanBtn.MouseButton1Click:Connect(function()
    ScanRemotes()
end)
GuiHelpers.AddHover(scanBtn, theme.AccentDark, theme.Accent)

-- ========================
-- AUTO LOAD ON TAB SWITCH
-- ========================
local rmLoaded = false
local origSwitch = DEX.SwitchTab

DEX.SwitchTab = function(tabName)
    origSwitch(tabName)
    if tabName == "Remotes" and not rmLoaded then
        rmLoaded = true
        task.spawn(function()
            pcall(function()
                task.wait(0.2)
                ScanRemotes()
            end)
        end)
    end
    if tabName == "Remotes" then
        if activeRightTab == "Spy Log" then
            RenderSpyLog()
        end
        if activeRightTab == "Blocked" then
            RenderBlockedList()
        end
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

print("[DEX] Part 4 (FIXED): Remotes Panel loaded")
print("[DEX] Type 'готов' for Part 5: Players + Console")

getgenv().DEX = DEX
