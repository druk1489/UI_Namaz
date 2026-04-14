-- DEX Explorer v1.0 for Solara
-- Part 2: Explorer Panel (Instance Tree + Properties)
-- =====================================================

assert(getgenv().DEX, "DEX Core (Part 1) must be loaded first!")

local DEX = getgenv().DEX
local theme = DEX.CurrentTheme
local Utils = DEX.Utils
local GuiHelpers = DEX.GuiHelpers
local explorerPage = DEX.Pages["Explorer"]

assert(explorerPage, "Explorer page not found!")

-- ========================
-- CONSTANTS
-- ========================
local NODE_HEIGHT = 22
local INDENT_WIDTH = 16
local MAX_VISIBLE_NODES = 200

-- ========================
-- EXPLORER STATE
-- ========================
local ExpState = {
    AllNodes = {},
    VisibleNodes = {},
    ScrollOffset = 0,
    SelectedNode = nil,
    ExpandedMap = {},
    SearchQuery = "",
    ClassFilter = "",
    TotalNodes = 0,
    NeedsRebuild = false,
    PropTarget = nil,
    PropList = {},
}

DEX.ExpState = ExpState

-- ========================
-- LAYOUT: LEFT (tree) + RIGHT (props)
-- ========================
local leftPanel = GuiHelpers.Create("Frame", {
    Name = "LeftPanel",
    Parent = explorerPage,
    Size = UDim2.new(0.52, -1, 1, 0),
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
    Position = UDim2.new(0.52, -1, 0, 0),
    BackgroundColor3 = theme.Border,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local rightPanel = GuiHelpers.Create("Frame", {
    Name = "RightPanel",
    Parent = explorerPage,
    Size = UDim2.new(0.48, -1, 1, 0),
    Position = UDim2.new(0.52, 2, 0, 0),
    BackgroundColor3 = theme.Background,
    BorderSizePixel = 0,
    ZIndex = 8,
    ClipsDescendants = true,
})

-- ========================
-- SEARCH BAR (left)
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
    local sbCorner = Instance.new("UICorner")
    sbCorner.CornerRadius = UDim.new(0, 4)
    sbCorner.Parent = searchBox
end)

pcall(function()
    local sbPad = Instance.new("UIPadding")
    sbPad.PaddingLeft = UDim.new(0, 6)
    sbPad.Parent = searchBox
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
    local cfCorner = Instance.new("UICorner")
    cfCorner.CornerRadius = UDim.new(0, 4)
    cfCorner.Parent = classFilterBox
end)

pcall(function()
    local cfPad = Instance.new("UIPadding")
    cfPad.PaddingLeft = UDim.new(0, 6)
    cfPad.Parent = classFilterBox
end)

-- Refresh button
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
    local rbCorner = Instance.new("UICorner")
    rbCorner.CornerRadius = UDim.new(0, 4)
    rbCorner.Parent = refreshBtn
end)

-- Node count label
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
-- TREE SCROLL FRAME
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

-- Virtual scroll: we render only visible nodes
local treeCanvas = GuiHelpers.Create("Frame", {
    Name = "TreeCanvas",
    Parent = treeContainer,
    Size = UDim2.new(1, 0, 0, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 8,
})

-- Scrollbar
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
    local stCorner = Instance.new("UICorner")
    stCorner.CornerRadius = UDim.new(0, 3)
    stCorner.Parent = scrollThumb
end)

-- ========================
-- NODE DATA STRUCTURE
-- ========================
-- Node = { instance, depth, isExpanded, hasChildren, parentNode }

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
            local childOk = pcall(function()
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

    local gameNode = {
        instance = game,
        depth = 0,
        isExpanded = expanded[game] == true,
        hasChildren = true,
        childCount = 0,
        name = "game",
        className = "DataModel",
    }
    pcall(function()
        local gc = game:GetChildren()
        gameNode.childCount = #gc
    end)
    table.insert(nodes, gameNode)

    if expanded[game] then
        Traverse(game, 1)
    end

    ExpState.AllNodes = nodes
    ExpState.TotalNodes = #nodes
    nodeCountLabel.Text = "Nodes: " .. #nodes
end

-- ========================
-- NODE RENDERING (virtual)
-- ========================
local renderedRows = {}

local function GetContainerHeight()
    local ok, h = pcall(function()
        return treeContainer.AbsoluteSize.Y
    end)
    if ok then return h end
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
            thumbPos = math.floor((ExpState.ScrollOffset / maxOffset) * (containerH - thumbH))
        end
        scrollThumb.Size = UDim2.new(1, 0, 0, thumbH)
        scrollThumb.Position = UDim2.new(0, 0, 0, thumbPos)
    end)
end

local function ClearRenderedRows()
    for _, row in ipairs(renderedRows) do
        pcall(function()
            row:Destroy()
        end)
    end
    renderedRows = {}
end

local function RenderTree()
    pcall(function()
        ClearRenderedRows()
        local containerH = GetContainerHeight()
        local visibleCount = math.min(
            math.ceil(containerH / NODE_HEIGHT) + 2,
            MAX_VISIBLE_NODES
        )
        local total = #ExpState.AllNodes
        local startIdx = ExpState.ScrollOffset + 1
        local endIdx = math.min(startIdx + visibleCount - 1, total)

        treeCanvas.Size = UDim2.new(1, 0, 0, total * NODE_HEIGHT)

        for i = startIdx, endIdx do
            local node = ExpState.AllNodes[i]
            if not node then break end

            local rowY = (i - 1) * NODE_HEIGHT - ExpState.ScrollOffset * NODE_HEIGHT
            local indentX = node.depth * INDENT_WIDTH + 4

            local row = GuiHelpers.Create("Frame", {
                Name = "Node" .. i,
                Parent = treeCanvas,
                Size = UDim2.new(1, -6, 0, NODE_HEIGHT),
                Position = UDim2.new(0, 0, 0, rowY),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 8,
            })

            -- Selection highlight
            local isSelected = ExpState.SelectedNode and
                ExpState.SelectedNode.instance == node.instance

            if isSelected then
                row.BackgroundColor3 = theme.NodeSelected
                row.BackgroundTransparency = 0
            end

            -- Expand arrow
            if node.hasChildren then
                local arrow = GuiHelpers.Create("TextButton", {
                    Name = "Arrow",
                    Parent = row,
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(0, indentX, 0, 4),
                    BackgroundTransparency = 1,
                    Text = node.isExpanded and "v" or ">",
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
                        ExpState.ExpandedMap[inst] = not ExpState.ExpandedMap[inst]
                        BuildNodeList()
                        RenderTree()
                    end)
                end)
            end

            -- Class icon badge
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
                local iconCorner = Instance.new("UICorner")
                iconCorner.CornerRadius = UDim.new(0, 3)
                iconCorner.Parent = iconBg
            end)

            -- Instance name
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
                TextColor3 = isSelected and Color3.new(1, 1, 1) or theme.Text,
                TextSize = 11,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                BorderSizePixel = 0,
                ZIndex = 9,
            })

            -- Hover effect on row
            local capturedNode = node
            local capturedRow = row

            nameLabel.MouseEnter:Connect(function()
                pcall(function()
                    if ExpState.SelectedNode and
                        ExpState.SelectedNode.instance == capturedNode.instance then
                        return
                    end
                    capturedRow.BackgroundColor3 = theme.NodeHover
                    capturedRow.BackgroundTransparency = 0
                end)
            end)

            nameLabel.MouseLeave:Connect(function()
                pcall(function()
                    if ExpState.SelectedNode and
                        ExpState.SelectedNode.instance == capturedNode.instance then
                        return
                    end
                    capturedRow.BackgroundTransparency = 1
                end)
            end)

            -- Left click: select
            nameLabel.MouseButton1Click:Connect(function()
                pcall(function()
                    ExpState.SelectedNode = capturedNode
                    DEX.State.SelectedInstance = capturedNode.instance
                    RenderTree()
                    LoadProperties(capturedNode.instance)
                end)
            end)

            -- Right click: context menu
            nameLabel.MouseButton2Click:Connect(function()
                pcall(function()
                    local mousePos = UserInputService:GetMouseLocation()
                    local inst = capturedNode.instance
                    local instPath = Utils.GetFullPath(inst)
                    local instName = Utils.GetInstanceName(inst)

                    local menuItems = {
                        {
                            label = "Copy Path",
                            callback = function()
                                pcall(function()
                                    setclipboard(instPath)
                                    DEX.ShowNotification("Copied", instPath, "success")
                                end)
                            end
                        },
                        {
                            label = "Copy Name",
                            callback = function()
                                pcall(function()
                                    setclipboard(instName)
                                    DEX.ShowNotification("Copied", instName, "success")
                                end)
                            end
                        },
                        {
                            label = "Copy ClassName",
                            callback = function()
                                pcall(function()
                                    setclipboard(capturedNode.className)
                                    DEX.ShowNotification("Copied",
                                        capturedNode.className, "success")
                                end)
                            end
                        },
                        {
                            label = "Expand All Children",
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
                            label = "Delete Instance",
                            color = theme.Error,
                            callback = function()
                                pcall(function()
                                    inst:Destroy()
                                    ExpState.SelectedNode = nil
                                    BuildNodeList()
                                    RenderTree()
                                    DEX.ShowNotification("Deleted",
                                        instName .. " removed", "warning")
                                end)
                            end
                        },
                        {
                            label = "Print to Console",
                            callback = function()
                                pcall(function()
                                    print("[DEX] " .. instPath ..
                                        " [" .. capturedNode.className .. "]")
                                    DEX.ShowNotification("Printed",
                                        instName, "info")
                                end)
                            end
                        },
                    }

                    DEX.ShowContextMenu(menuItems,
                        mousePos.X,
                        mousePos.Y)
                end)
            end)

            table.insert(renderedRows, row)
        end

        UpdateScrollThumb()
    end)
end

-- ========================
-- SCROLL HANDLING
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

-- Scrollbar drag
local scrollDragging = false
local scrollDragStartY = 0
local scrollDragStartOffset = 0

scrollThumb.InputBegan:Connect(function(input)
    pcall(function()
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            scrollDragging = true
            scrollDragStartY = input.Position.Y
            scrollDragStartOffset = ExpState.ScrollOffset
        end
    end)
end)

UserInputService.InputChanged:Connect(function(input)
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

UserInputService.InputEnded:Connect(function(input)
    pcall(function()
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            scrollDragging = false
        end
    end)
end)

-- ========================
-- SEARCH & FILTER
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
-- PROPERTIES PANEL (right)
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
    local psCorner = Instance.new("UICorner")
    psCorner.CornerRadius = UDim.new(0, 4)
    psCorner.Parent = propSearchBox
end)

pcall(function()
    local psPad = Instance.new("UIPadding")
    psPad.PaddingLeft = UDim.new(0, 6)
    psPad.Parent = propSearchBox
end)

-- Property scroll
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

-- Known properties to display per class
local COMMON_PROPS = {
    "Name", "ClassName", "Parent", "Archivable",
}
local PART_PROPS = {
    "Position", "Size", "Rotation", "Anchored",
    "CanCollide", "Transparency", "BrickColor",
    "Material", "CastShadow", "Locked",
    "Massless", "CFrame",
}
local GUI_PROPS = {
    "Size", "Position", "BackgroundColor3",
    "BackgroundTransparency", "Text", "TextColor3",
    "TextSize", "Font", "Visible", "ZIndex",
    "BorderSizePixel", "ClipsDescendants",
}
local HUMANOID_PROPS = {
    "Health", "MaxHealth", "WalkSpeed",
    "JumpPower", "AutoRotate", "DisplayName",
    "NameDisplayDistance", "HealthDisplayType",
}
local SCRIPT_PROPS = {
    "Disabled", "RunContext",
}
local SOUND_PROPS = {
    "SoundId", "Volume", "Playing",
    "Looped", "Pitch", "TimePosition",
}
local LIGHT_PROPS = {
    "Brightness", "Color", "Enabled", "Range",
    "Shadows",
}

local CLASS_PROP_MAP = {
    ["Part"] = PART_PROPS,
    ["MeshPart"] = PART_PROPS,
    ["UnionOperation"] = PART_PROPS,
    ["SpecialMesh"] = {"MeshType", "Scale", "Offset"},
    ["Humanoid"] = HUMANOID_PROPS,
    ["Frame"] = GUI_PROPS,
    ["TextLabel"] = GUI_PROPS,
    ["TextButton"] = GUI_PROPS,
    ["TextBox"] = GUI_PROPS,
    ["ImageLabel"] = GUI_PROPS,
    ["ImageButton"] = GUI_PROPS,
    ["ScreenGui"] = {"Enabled", "ZIndexBehavior", "DisplayOrder"},
    ["Script"] = SCRIPT_PROPS,
    ["LocalScript"] = SCRIPT_PROPS,
    ["ModuleScript"] = {},
    ["Sound"] = SOUND_PROPS,
    ["PointLight"] = LIGHT_PROPS,
    ["SpotLight"] = LIGHT_PROPS,
    ["SurfaceLight"] = LIGHT_PROPS,
    ["Camera"] = {"CFrame", "FieldOfView", "CameraType"},
    ["RemoteEvent"] = {},
    ["RemoteFunction"] = {},
    ["Folder"] = {},
    ["Model"] = {"PrimaryPart", "WorldPivot"},
    ["Tool"] = {"Enabled", "CanBeDropped", "RequiresHandle", "ToolTip"},
}

local function ValueToString(val)
    local t = typeof(val)
    if t == "nil" then
        return "nil"
    elseif t == "boolean" then
        return tostring(val)
    elseif t == "number" then
        return string.format("%.4g", val)
    elseif t == "string" then
        return '"' .. Utils.Truncate(val, 40) .. '"'
    elseif t == "Vector3" then
        return string.format("(%.2f, %.2f, %.2f)", val.X, val.Y, val.Z)
    elseif t == "Vector2" then
        return string.format("(%.2f, %.2f)", val.X, val.Y)
    elseif t == "CFrame" then
        local p = val.Position
        return string.format("CF(%.1f, %.1f, %.1f)", p.X, p.Y, p.Z)
    elseif t == "Color3" then
        local r = math.floor(val.R * 255)
        local g = math.floor(val.G * 255)
        local b = math.floor(val.B * 255)
        return string.format("RGB(%d,%d,%d)", r, g, b)
    elseif t == "BrickColor" then
        return tostring(val)
    elseif t == "UDim2" then
        return string.format("{%.2f,%d},{%.2f,%d}",
            val.X.Scale, val.X.Offset,
            val.Y.Scale, val.Y.Offset)
    elseif t == "UDim" then
        return string.format("%.2f, %d", val.Scale, val.Offset)
    elseif t == "Instance" then
        if val then
            return Utils.GetInstanceName(val) ..
                " [" .. Utils.GetClassName(val) .. "]"
        end
        return "nil"
    elseif t == "EnumItem" then
        return tostring(val)
    elseif t == "Rect" then
        return string.format("Rect(%.0f,%.0f,%.0f,%.0f)",
            val.Min.X, val.Min.Y, val.Max.X, val.Max.Y)
    end
    return tostring(val)
end

local propFilterQuery = ""

local function GetColorForValue(val)
    local t = typeof(val)
    if t == "boolean" then
        if val then return theme.Success end
        return theme.Error
    elseif t == "number" then
        return theme.SyntaxNumber
    elseif t == "string" then
        return theme.SyntaxString
    elseif t == "Color3" then
        return val
    elseif t == "Instance" then
        return theme.Accent
    end
    return theme.TextSecondary
end

function LoadProperties(instance)
    if not instance then return end

    pcall(function()
        -- Clear old rows
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

        -- Build prop list
        local propsToShow = {}
        for _, p in ipairs(COMMON_PROPS) do
            table.insert(propsToShow, p)
        end

        local classPropList = CLASS_PROP_MAP[className]
        if classPropList then
            for _, p in ipairs(classPropList) do
                table.insert(propsToShow, p)
            end
        end

        -- Extra scan: try common extra props
        local extraProps = {
            "Enabled", "Visible", "Locked", "Anchored",
            "CanCollide", "Transparency", "Reflectance",
            "Mass", "AssemblyMass",
        }
        for _, ep in ipairs(extraProps) do
            local already = false
            for _, existing in ipairs(propsToShow) do
                if existing == ep then
                    already = true
                    break
                end
            end
            if not already then
                table.insert(propsToShow, ep)
            end
        end

        local rowIndex = 0
        for _, propName in ipairs(propsToShow) do
            local filterQ = string.lower(propFilterQuery)
            local propLower = string.lower(propName)
            if filterQ ~= "" and not string.find(propLower, filterQ, 1, true) then
                -- skip filtered
            else
                local ok, val = pcall(function()
                    return instance[propName]
                end)

                local displayVal = ok and ValueToString(val) or "N/A"
                local valColor = ok and GetColorForValue(val) or theme.TextDisabled

                rowIndex = rowIndex + 1
                local rowBg = (rowIndex % 2 == 0)
                    and theme.BackgroundSecondary
                    or theme.Background

                local propRow = GuiHelpers.Create("Frame", {
                    Name = "Prop_" .. propName,
                    Parent = propScroll,
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundColor3 = rowBg,
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    ZIndex = 9,
                    LayoutOrder = rowIndex,
                })

                local propNameLabel = GuiHelpers.Create("TextLabel", {
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

                -- Color swatch for Color3 values
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
                        local swCorner = Instance.new("UICorner")
                        swCorner.CornerRadius = UDim.new(0, 2)
                        swCorner.Parent = swatch
                    end)
                end

                local propValLabel = GuiHelpers.Create("TextButton", {
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

                -- Copy value on click
                local capturedPropName = propName
                local capturedDisplayVal = displayVal
                propValLabel.MouseButton1Click:Connect(function()
                    pcall(function()
                        setclipboard(capturedPropName .. " = " .. capturedDisplayVal)
                        DEX.ShowNotification("Copied",
                            capturedPropName .. " = " .. capturedDisplayVal, "success")
                    end)
                end)

                GuiHelpers.AddHover(propValLabel, rowBg, theme.NodeHover)
            end
        end

        -- Update canvas size
        local totalH = rowIndex * 21
        propScroll.CanvasSize = UDim2.new(0, 0, 0, totalH)
    end)
end

DEX.LoadProperties = LoadProperties

-- Property search
propSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    pcall(function()
        propFilterQuery = propSearchBox.Text
        if ExpState.SelectedNode then
            LoadProperties(ExpState.SelectedNode.instance)
        end
    end)
end)

-- ========================
-- AUTO-REFRESH on tab switch
-- ========================
local explorerLoaded = false

local originalSwitchTab = DEX.SwitchTab
DEX.SwitchTab = function(tabName)
    originalSwitchTab(tabName)
    if tabName == "Explorer" and not explorerLoaded then
        explorerLoaded = true
        task.spawn(function()
            pcall(function()
                task.wait(0.1)
                ExpState.ExpandedMap[game] = true
                BuildNodeList()
                RenderTree()
            end)
        end)
    end
end

-- Update tab buttons to use new SwitchTab
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

-- ========================
-- INITIAL LOAD
-- ========================
task.spawn(function()
    pcall(function()
        task.wait(0.3)
        ExpState.ExpandedMap[game] = true
        BuildNodeList()
        RenderTree()
        DEX.StatusText.Text = "Explorer loaded | " ..
            ExpState.TotalNodes .. " nodes"
    end)
end)

print("[DEX] Part 2: Explorer Panel loaded")
print("[DEX] Type 'готов' for Part 3: Script Viewer")

getgenv().DEX = DEX
