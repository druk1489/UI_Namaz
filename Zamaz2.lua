-- DEX Explorer v1.0 for Solara
-- Part 2: Explorer Panel (FIXED)
-- ================================

assert(getgenv().DEX, "DEX Core (Part 1) must be loaded first!")

local DEX = getgenv().DEX
local theme = DEX.CurrentTheme
local Utils = DEX.Utils
local GuiHelpers = DEX.GuiHelpers
local explorerPage = DEX.Pages["Explorer"]

assert(explorerPage, "Explorer page not found!")

local NODE_HEIGHT = 22
local INDENT_WIDTH = 16
local MAX_VISIBLE_NODES = 200

local ExpState = {
    AllNodes = {},
    VisibleNodes = {},
    ScrollOffset = 0,
    SelectedNode = nil,
    ExpandedMap = {},
    SearchQuery = "",
    ClassFilter = "",
    TotalNodes = 0,
    PropTarget = nil,
    PropList = {},
}

DEX.ExpState = ExpState

-- ========================
-- LAYOUT: 55% left + 45% right
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
    Text = "Nodes: 0",
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
                local name = string.lower(Utils.GetInstanceName(child))
                local cls = string.lower(Utils.GetClassName(child))

                local matchSearch = (searchQ == "") or
                    string.find(name, searchQ, 1, true) or
                    string.find(cls, searchQ, 1, true)

                local matchClass = (classF == "") or
                    string.find(cls, classF, 1, true)

                local hasChildren = false
                local childCount = 0
                pcall(function()
                    local gc = child:GetChildren()
                    childCount = #gc
                    hasChildren = childCount > 0
                end)

                if matchSearch and matchClass then
                    local node = {
                        instance = child,
                        depth = depth,
                        isExpanded = expanded[child] == true,
                        hasChildren = hasChildren,
                        childCount = childCount,
                        name = Utils.GetInstanceName(child),
                        className = Utils.GetClassName(child),
                    }
                    table.insert(nodes, node)
                end

                if expanded[child] and hasChildren then
                    Traverse(child, depth + 1)
                end
            end)
        end
    end

    local gameChildCount = 0
    pcall(function()
        gameChildCount = #game:GetChildren()
    end)

    local gameNode = {
        instance = game,
        depth = 0,
        isExpanded = expanded[game] == true,
        hasChildren = true,
        childCount = gameChildCount,
        name = "game",
        className = "DataModel",
    }
    table.insert(nodes, gameNode)

    if expanded[game] then
        Traverse(game, 1)
    end

    ExpState.AllNodes = nodes
    ExpState.TotalNodes = #nodes
    nodeCountLabel.Text = "Nodes: " .. #nodes
end

-- ========================
-- RENDER TREE
-- ========================
local renderedRows = {}

local function GetContainerHeight()
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
        local containerH = GetContainerHeight()
        local visibleCount = math.floor(containerH / NODE_HEIGHT)
        if total <= visibleCount then
            scrollThumb.Size = UDim2.new(1, 0, 1, 0)
            scrollThumb.Position = UDim2.new(0, 0, 0, 0)
            return
        end
        local ratio = visibleCount / total
        local thumbH = math.max(20, math.floor(containerH * ratio))
        local maxOffset = total - visibleCount
        local thumbPos = 0
        if maxOffset > 0 then
            thumbPos = math.floor(
                (ExpState.ScrollOffset / maxOffset) * (containerH - thumbH)
            )
        end
        scrollThumb.Size = UDim2.new(1, 0, 0, thumbH)
        scrollThumb.Position = UDim2.new(0, 0, 0, thumbPos)
    end)
end

local function ClearRenderedRows()
    for _, row in ipairs(renderedRows) do
        pcall(function() row:Destroy() end)
    end
    renderedRows = {}
end

-- Forward declare LoadProperties
local LoadProperties

local function RenderTree()
    pcall(function()
        ClearRenderedRows()
        local containerH = GetContainerHeight()
        local visibleCount = math.min(
            math.ceil(containerH / NODE_HEIGHT) + 4,
            MAX_VISIBLE_NODES
        )
        local total = #ExpState.AllNodes
        local startIdx = ExpState.ScrollOffset + 1
        local endIdx = math.min(startIdx + visibleCount - 1, total)

        treeCanvas.Size = UDim2.new(1, 0, 0, total * NODE_HEIGHT)

        for i = startIdx, endIdx do
            local node = ExpState.AllNodes[i]
            if not node then break end

            local rowY = (i - 1) * NODE_HEIGHT -
                ExpState.ScrollOffset * NODE_HEIGHT
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

            if node.hasChildren then
                local arrowText = node.isExpanded and "v" or ">"
                local arrow = GuiHelpers.Create("TextButton", {
                    Name = "Arrow",
                    Parent = row,
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(0, indentX, 0, 4),
                    BackgroundTransparency = 1,
                    Text = arrowText,
                    TextColor3 = theme.TextSecondary,
                    TextSize = 9,
                    Font = Enum.Font.GothamBold,
                    BorderSizePixel = 0,
                    ZIndex = 9,
                })

                local nodeRef = node
                arrow.MouseButton1Click:Connect(function()
                    pcall(function()
                        local inst = nodeRef.instance
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

            local iconX = indentX + (node.hasChildren and 16 or 0)
            local clsIcon = Utils.GetClassIcon(node.className)

            local iconBg = GuiHelpers.Create("TextLabel", {
                Name = "Icon",
                Parent = row,
                Size = UDim2.new(0, 18, 0, 14),
                Position = UDim2.new(0, iconX, 0, 4),
                BackgroundColor3 = theme.AccentDark,
                Text = clsIcon,
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

            local nameX = iconX + 22
            local displayName = Utils.Truncate(node.name, 32)
            if node.childCount > 0 then
                displayName = displayName .. " (" .. node.childCount .. ")"
            end

            local nameLabel = GuiHelpers.Create("TextButton", {
                Name = "NameLabel",
                Parent = row,
                Size = UDim2.new(1, -(nameX + 4), 1, 0),
                Position = UDim2.new(0, nameX, 0, 0),
                BackgroundTransparency = 1,
                Text = displayName,
                TextColor3 = isSelected
                    and Color3.new(1, 1, 1) or theme.Text,
                TextSize = 11,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                BorderSizePixel = 0,
                ZIndex = 9,
            })

            local capturedNode = node
            local capturedRow = row

            nameLabel.MouseEnter:Connect(function()
                pcall(function()
                    if ExpState.SelectedNode and
                        ExpState.SelectedNode.instance ==
                        capturedNode.instance then
                        return
                    end
                    capturedRow.BackgroundColor3 = theme.NodeHover
                    capturedRow.BackgroundTransparency = 0
                end)
            end)

            nameLabel.MouseLeave:Connect(function()
                pcall(function()
                    if ExpState.SelectedNode and
                        ExpState.SelectedNode.instance ==
                        capturedNode.instance then
                        return
                    end
                    capturedRow.BackgroundTransparency = 1
                end)
            end)

            nameLabel.MouseButton1Click:Connect(function()
                pcall(function()
                    ExpState.SelectedNode = capturedNode
                    DEX.State.SelectedInstance = capturedNode.instance
                    RenderTree()
                    if LoadProperties then
                        LoadProperties(capturedNode.instance)
                    end
                end)
            end)

            nameLabel.MouseButton2Click:Connect(function()
                pcall(function()
                    local UserInputSvc = game:GetService("UserInputService")
                    local mousePos = UserInputSvc:GetMouseLocation()
                    local inst = capturedNode.instance
                    local instPath = Utils.GetFullPath(inst)
                    local instName = Utils.GetInstanceName(inst)

                    DEX.ShowContextMenu({
                        {
                            label = "Copy Path",
                            callback = function()
                                pcall(function()
                                    setclipboard(instPath)
                                    DEX.ShowNotification(
                                        "Copied", instPath, "success"
                                    )
                                end)
                            end
                        },
                        {
                            label = "Copy Name",
                            callback = function()
                                pcall(function()
                                    setclipboard(instName)
                                    DEX.ShowNotification(
                                        "Copied", instName, "success"
                                    )
                                end)
                            end
                        },
                        {
                            label = "Copy ClassName",
                            callback = function()
                                pcall(function()
                                    setclipboard(capturedNode.className)
                                    DEX.ShowNotification(
                                        "Copied",
                                        capturedNode.className,
                                        "success"
                                    )
                                end)
                            end
                        },
                        {
                            label = "Expand All",
                            callback = function()
                                pcall(function()
                                    local function ExpandAll(target)
                                        local ok2, kids = pcall(function()
                                            return target:GetChildren()
                                        end)
                                        if ok2 then
                                            for _, k in ipairs(kids) do
                                                ExpState.ExpandedMap[k] = true
                                                ExpandAll(k)
                                            end
                                        end
                                    end
                                    ExpState.ExpandedMap[inst] = true
                                    ExpandAll(inst)
                                    BuildNodeList()
                                    RenderTree()
                                end)
                            end
                        },
                        {
                            label = "Collapse",
                            callback = function()
                                pcall(function()
                                    ExpState.ExpandedMap[inst] = false
                                    BuildNodeList()
                                    RenderTree()
                                end)
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
                    }, mousePos.X, mousePos.Y)
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
            local containerH = GetContainerHeight()
            local visibleCount = math.floor(containerH / NODE_HEIGHT)
            local maxOffset = math.max(0, total - visibleCount)
            local delta = -input.Position.Z
            ExpState.ScrollOffset = math.clamp(
                ExpState.ScrollOffset + delta * 3,
                0,
                maxOffset
            )
            RenderTree()
        end
    end)
end)

local scrollDragging = false
local scrollDragStartY = 0
local scrollDragStartOffset = 0

local UserInputSvc = game:GetService("UserInputService")

scrollThumb.InputBegan:Connect(function(input)
    pcall(function()
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            scrollDragging = true
            scrollDragStartY = input.Position.Y
            scrollDragStartOffset = ExpState.ScrollOffset
        end
    end)
end)

UserInputSvc.InputChanged:Connect(function(input)
    pcall(function()
        if scrollDragging and
            input.UserInputType == Enum.UserInputType.MouseMovement then
            local total = #ExpState.AllNodes
            local containerH = GetContainerHeight()
            local visibleCount = math.floor(containerH / NODE_HEIGHT)
            local maxOffset = math.max(0, total - visibleCount)
            local delta = input.Position.Y - scrollDragStartY
            local ratio = delta / containerH
            ExpState.ScrollOffset = math.clamp(
                math.floor(scrollDragStartOffset + ratio * total),
                0,
                maxOffset
            )
            RenderTree()
        end
    end)
end)

UserInputSvc.InputEnded:Connect(function(input)
    pcall(function()
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            scrollDragging = false
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
        DEX.ShowNotification("Explorer", "Tree refreshed", "info")
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
    Size = UDim2.new(1, -8, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "Properties",
    TextColor3 = theme.Text,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 10,
})

local propSearchBox = GuiHelpers.Create("TextBox", {
    Name = "PropSearch",
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
    Name = "PropScroll",
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

-- ========================
-- PROPERTIES DATA
-- ========================
local COMMON_PROPS = {
    "Name", "ClassName", "Parent", "Archivable",
}

local EXTRA_PROPS = {
    "Position", "Size", "Rotation", "Anchored",
    "CanCollide", "Transparency", "Visible",
    "Enabled", "Locked", "CFrame",
    "Health", "MaxHealth", "WalkSpeed", "JumpPower",
    "Text", "TextColor3", "BackgroundColor3",
    "ZIndex", "Font", "TextSize",
    "SoundId", "Volume", "Playing",
    "Disabled", "RunContext",
}

local function ValueToString(val)
    local t = typeof(val)
    if t == "nil" then return "nil" end
    if t == "boolean" then return tostring(val) end
    if t == "number" then
        return string.format("%.4g", val)
    end
    if t == "string" then
        return '"' .. Utils.Truncate(val, 40) .. '"'
    end
    if t == "Vector3" then
        return string.format("(%.2f, %.2f, %.2f)",
            val.X, val.Y, val.Z)
    end
    if t == "Vector2" then
        return string.format("(%.2f, %.2f)", val.X, val.Y)
    end
    if t == "CFrame" then
        local p = val.Position
        return string.format("CF(%.1f, %.1f, %.1f)",
            p.X, p.Y, p.Z)
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
            val.X.Scale, val.X.Offset,
            val.Y.Scale, val.Y.Offset)
    end
    if t == "Instance" then
        if val then
            return Utils.GetInstanceName(val) ..
                " [" .. Utils.GetClassName(val) .. "]"
        end
        return "nil"
    end
    if t == "EnumItem" then return tostring(val) end
    return tostring(val)
end

local function GetValueColor(val)
    local t = typeof(val)
    if t == "boolean" then
        if val then return theme.Success end
        return theme.Error
    end
    if t == "number" then return theme.SyntaxNumber end
    if t == "string" then return theme.SyntaxString end
    if t == "Color3" then return val end
    if t == "Instance" then return theme.Accent end
    return theme.TextSecondary
end

local propFilterQuery = ""

LoadProperties = function(instance)
    if not instance then return end
    pcall(function()
        for _, child in ipairs(propScroll:GetChildren()) do
            pcall(function()
                if child:IsA("Frame") or child:IsA("TextLabel") then
                    child:Destroy()
                end
            end)
        end

        local instName = Utils.GetInstanceName(instance)
        local className = Utils.GetClassName(instance)
        propTitle.Text = instName .. " [" .. className .. "]"

        local propsToShow = {}
        for _, p in ipairs(COMMON_PROPS) do
            table.insert(propsToShow, p)
        end
        for _, p in ipairs(EXTRA_PROPS) do
            table.insert(propsToShow, p)
        end

        local rowIndex = 0
        local filterQ = string.lower(propFilterQuery)

        for _, propName in ipairs(propsToShow) do
            local propLower = string.lower(propName)
            local matchFilter = filterQ == "" or
                string.find(propLower, filterQ, 1, true)

            if matchFilter then
                local ok, val = pcall(function()
                    return instance[propName]
                end)

                local displayVal = ok and ValueToString(val) or "N/A"
                local valColor = ok
                    and GetValueColor(val) or theme.TextDisabled

                rowIndex = rowIndex + 1
                local rowBg = rowIndex % 2 == 0
                    and theme.BackgroundSecondary
                    or theme.Background

                local propRow = GuiHelpers.Create("Frame", {
                    Name = "Prop_" .. propName,
                    Parent = propScroll,
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundColor3 = rowBg,
                    BorderSizePixel = 0,
                    ZIndex = 9,
                    LayoutOrder = rowIndex,
                })

                GuiHelpers.Create("TextLabel", {
                    Parent = propRow,
                    Size = UDim2.new(0.45, 0, 1, 0),
                    Position = UDim2.new(0, 4, 0, 0),
                    BackgroundTransparency = 1,
                    Text = propName,
                    TextColor3 = theme.TextSecondary,
                    TextSize = 10,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 10,
                })

                if ok and typeof(val) == "Color3" then
                    local swatch = GuiHelpers.Create("Frame", {
                        Parent = propRow,
                        Size = UDim2.new(0, 12, 0, 12),
                        Position = UDim2.new(0.45, 2, 0, 4),
                        BackgroundColor3 = val,
                        BorderSizePixel = 0,
                        ZIndex = 10,
                    })
                    pcall(function()
                        local c = Instance.new("UICorner")
                        c.CornerRadius = UDim.new(0, 2)
                        c.Parent = swatch
                    end)
                end

                local valBtn = GuiHelpers.Create("TextButton", {
                    Parent = propRow,
                    Size = UDim2.new(0.55, -20, 1, 0),
                    Position = UDim2.new(0.45, 16, 0, 0),
                    BackgroundTransparency = 1,
                    Text = displayVal,
                    TextColor3 = valColor,
                    TextSize = 10,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderSizePixel = 0,
                    ZIndex = 10,
                })

                local capProp = propName
                local capVal = displayVal
                valBtn.MouseButton1Click:Connect(function()
                    pcall(function()
                        setclipboard(capProp .. " = " .. capVal)
                        DEX.ShowNotification(
                            "Copied",
                            capProp .. " = " .. capVal,
                            "success"
                        )
                    end)
                end)
            end
        end

        propScroll.CanvasSize = UDim2.new(0, 0, 0, rowIndex * 21)
    end)
end

DEX.LoadProperties = LoadProperties

propSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    pcall(function()
        propFilterQuery = propSearchBox.Text
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
            ExpState.TotalNodes .. " nodes"
        DEX.ShowNotification(
            "Explorer",
            "Tree loaded: " .. ExpState.TotalNodes .. " nodes",
            "success"
        )
    end)
end)

-- Tab switch handler
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

print("[DEX] Part 2 (FIXED): Explorer Panel loaded")
print("[DEX] Tree should now auto-load with game nodes")

getgenv().DEX = DEX
