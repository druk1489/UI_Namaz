-- DEX Explorer v1.0 for Solara
-- Part 6: Settings Panel + Final Integration
-- ===========================================

assert(getgenv().DEX, "DEX Core (Part 1) must be loaded first!")

local DEX = getgenv().DEX
local theme = DEX.CurrentTheme
local Utils = DEX.Utils
local GuiHelpers = DEX.GuiHelpers
local settingsPage = DEX.Pages["Settings"]

assert(settingsPage, "Settings page not found!")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ========================
-- SETTINGS STATE
-- ========================
local SETState = {
    CurrentTheme = "Dark",
    FontSize = 11,
    Transparency = 0,
    ShowStatusBar = true,
    ShowLineNumbers = true,
    AutoScanOnOpen = true,
    MaxLogEntries = 500,
    NotificationsEnabled = true,
    RemoteSpyEnabled = false,
    SaveSettings = true,
}

DEX.SETState = SETState

-- ========================
-- SETTINGS LAYOUT
-- ========================
local settingsScroll = GuiHelpers.Create("ScrollingFrame", {
    Name = "SettingsScroll",
    Parent = settingsPage,
    Size = UDim2.new(0.55, -2, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.Background,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = theme.Scrollbar,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 8,
    ClipsDescendants = true,
})

local settingsLayout = GuiHelpers.Create("UIListLayout", {
    Parent = settingsScroll,
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4),
})

local statsDivider = GuiHelpers.Create("Frame", {
    Name = "StatsDivider",
    Parent = settingsPage,
    Size = UDim2.new(0, 2, 1, 0),
    Position = UDim2.new(0.55, -1, 0, 0),
    BackgroundColor3 = theme.Border,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local statsPanel = GuiHelpers.Create("Frame", {
    Name = "StatsPanel",
    Parent = settingsPage,
    Size = UDim2.new(0.45, -1, 1, 0),
    Position = UDim2.new(0.55, 2, 0, 0),
    BackgroundColor3 = theme.BackgroundTertiary,
    BorderSizePixel = 0,
    ZIndex = 8,
    ClipsDescendants = true,
})

-- ========================
-- SECTION HELPERS
-- ========================
local settingsRowOrder = 0

local function MakeSection(title)
    settingsRowOrder = settingsRowOrder + 1
    local sec = GuiHelpers.Create("Frame", {
        Name = "Section_" .. title,
        Parent = settingsScroll,
        Size = UDim2.new(1, -8, 0, 26),
        BackgroundColor3 = theme.AccentDark,
        BorderSizePixel = 0,
        ZIndex = 9,
        LayoutOrder = settingsRowOrder,
    })
    pcall(function()
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 8)
        pad.Parent = sec
    end)
    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 5)
        c.Parent = sec
    end)
    local lbl = GuiHelpers.Create("TextLabel", {
        Parent = sec,
        Size = UDim2.new(1, -8, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10,
    })
    return sec
end

local function MakeSettingRow(labelText, controlFunc)
    settingsRowOrder = settingsRowOrder + 1
    local row = GuiHelpers.Create("Frame", {
        Name = "SettingRow_" .. settingsRowOrder,
        Parent = settingsScroll,
        Size = UDim2.new(1, -8, 0, 32),
        BackgroundColor3 = settingsRowOrder % 2 == 0
            and theme.BackgroundSecondary
            or theme.Background,
        BorderSizePixel = 0,
        ZIndex = 9,
        LayoutOrder = settingsRowOrder,
    })
    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = row
    end)

    local lbl = GuiHelpers.Create("TextLabel", {
        Parent = row,
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = theme.Text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10,
    })

    local controlFrame = GuiHelpers.Create("Frame", {
        Parent = row,
        Size = UDim2.new(0.5, -10, 1, -6),
        Position = UDim2.new(0.5, 0, 0, 3),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 10,
    })

    if controlFunc then
        controlFunc(controlFrame)
    end

    return row, controlFrame
end

-- Toggle control
local function MakeToggle(parent, initial, callback)
    local isOn = initial
    local toggleBg = GuiHelpers.Create("Frame", {
        Name = "ToggleBg",
        Parent = parent,
        Size = UDim2.new(0, 44, 0, 22),
        Position = UDim2.new(0, 0, 0.5, -11),
        BackgroundColor3 = isOn and theme.Success or theme.ButtonBg,
        BorderSizePixel = 0,
        ZIndex = 11,
    })
    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = toggleBg
    end)

    local knob = GuiHelpers.Create("Frame", {
        Name = "Knob",
        Parent = toggleBg,
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, isOn and 23 or 3, 0.5, -9),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 12,
    })
    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = knob
    end)

    local statusLbl = GuiHelpers.Create("TextLabel", {
        Parent = parent,
        Size = UDim2.new(0, 30, 0, 22),
        Position = UDim2.new(0, 48, 0.5, -11),
        BackgroundTransparency = 1,
        Text = isOn and "ON" or "OFF",
        TextColor3 = isOn and theme.Success or theme.TextSecondary,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        ZIndex = 11,
    })

    local clickArea = GuiHelpers.Create("TextButton", {
        Parent = toggleBg,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        BorderSizePixel = 0,
        ZIndex = 13,
    })

    clickArea.MouseButton1Click:Connect(function()
        pcall(function()
            isOn = not isOn
            local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
            local TweenSvc = game:GetService("TweenService")

            if isOn then
                pcall(function()
                    TweenSvc:Create(toggleBg, tweenInfo,
                        {BackgroundColor3 = theme.Success}):Play()
                    TweenSvc:Create(knob, tweenInfo,
                        {Position = UDim2.new(0, 23, 0.5, -9)}):Play()
                end)
                statusLbl.Text = "ON"
                statusLbl.TextColor3 = theme.Success
            else
                pcall(function()
                    TweenSvc:Create(toggleBg, tweenInfo,
                        {BackgroundColor3 = theme.ButtonBg}):Play()
                    TweenSvc:Create(knob, tweenInfo,
                        {Position = UDim2.new(0, 3, 0.5, -9)}):Play()
                end)
                statusLbl.Text = "OFF"
                statusLbl.TextColor3 = theme.TextSecondary
            end

            if callback then
                pcall(callback, isOn)
            end
        end)
    end)

    return toggleBg, function() return isOn end
end

-- Dropdown control
local function MakeDropdown(parent, options, current, callback)
    local selectedLabel = GuiHelpers.Create("TextButton", {
        Name = "Dropdown",
        Parent = parent,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = theme.InputBg,
        Text = current,
        TextColor3 = theme.Text,
        TextSize = 10,
        Font = Enum.Font.GothamSemibold,
        BorderSizePixel = 0,
        ZIndex = 11,
    })
    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = selectedLabel
    end)

    local arrowLbl = GuiHelpers.Create("TextLabel", {
        Parent = selectedLabel,
        Size = UDim2.new(0, 16, 1, 0),
        Position = UDim2.new(1, -18, 0, 0),
        BackgroundTransparency = 1,
        Text = "v",
        TextColor3 = theme.TextSecondary,
        TextSize = 9,
        Font = Enum.Font.GothamBold,
        ZIndex = 12,
    })

    local dropOpen = false
    local dropFrame = nil

    selectedLabel.MouseButton1Click:Connect(function()
        pcall(function()
            dropOpen = not dropOpen
            if dropOpen then
                local screenGui = DEX.ScreenGui
                local absPos = selectedLabel.AbsolutePosition
                local absSize = selectedLabel.AbsoluteSize
                local optH = 24
                local totalH = #options * optH + 4

                dropFrame = GuiHelpers.Create("Frame", {
                    Name = "DropdownMenu",
                    Parent = screenGui,
                    Size = UDim2.new(0, absSize.X, 0, totalH),
                    Position = UDim2.new(
                        0, absPos.X,
                        0, absPos.Y + absSize.Y + 2
                    ),
                    BackgroundColor3 = theme.BackgroundSecondary,
                    BorderSizePixel = 0,
                    ZIndex = 500,
                })
                pcall(function()
                    local c = Instance.new("UICorner")
                    c.CornerRadius = UDim.new(0, 4)
                    c.Parent = dropFrame
                end)
                pcall(function()
                    local s = Instance.new("UIStroke")
                    s.Color = theme.Border
                    s.Thickness = 1
                    s.Parent = dropFrame
                end)

                local dLayout = GuiHelpers.Create("UIListLayout", {
                    Parent = dropFrame,
                    FillDirection = Enum.FillDirection.Vertical,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 1),
                })

                for oi, opt in ipairs(options) do
                    local isCurrent = (opt == current)
                    local optBtn = GuiHelpers.Create("TextButton", {
                        Name = "Opt_" .. oi,
                        Parent = dropFrame,
                        Size = UDim2.new(1, -4, 0, optH - 1),
                        BackgroundColor3 = isCurrent
                            and theme.AccentDark
                            or theme.BackgroundSecondary,
                        Text = opt,
                        TextColor3 = isCurrent
                            and Color3.new(1, 1, 1)
                            or theme.Text,
                        TextSize = 10,
                        Font = Enum.Font.Gotham,
                        BorderSizePixel = 0,
                        ZIndex = 501,
                        LayoutOrder = oi,
                    })

                    local capturedOpt = opt
                    optBtn.MouseButton1Click:Connect(function()
                        pcall(function()
                            current = capturedOpt
                            selectedLabel.Text = capturedOpt
                            dropOpen = false
                            if dropFrame then
                                dropFrame:Destroy()
                                dropFrame = nil
                            end
                            if callback then
                                pcall(callback, capturedOpt)
                            end
                        end)
                    end)
                    GuiHelpers.AddHover(optBtn,
                        isCurrent and theme.AccentDark or theme.BackgroundSecondary,
                        theme.ButtonHover
                    )
                end
            else
                if dropFrame then
                    dropFrame:Destroy()
                    dropFrame = nil
                end
            end
        end)
    end)

    return selectedLabel
end

-- Slider control
local function MakeSlider(parent, minVal, maxVal, currentVal, callback)
    local sliderBg = GuiHelpers.Create("Frame", {
        Name = "SliderBg",
        Parent = parent,
        Size = UDim2.new(1, -50, 0, 6),
        Position = UDim2.new(0, 0, 0.5, -3),
        BackgroundColor3 = theme.ButtonBg,
        BorderSizePixel = 0,
        ZIndex = 11,
    })
    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = sliderBg
    end)

    local ratio = (currentVal - minVal) / (maxVal - minVal)
    local fillBar = GuiHelpers.Create("Frame", {
        Name = "FillBar",
        Parent = sliderBg,
        Size = UDim2.new(ratio, 0, 1, 0),
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 12,
    })
    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = fillBar
    end)

    local handle = GuiHelpers.Create("Frame", {
        Name = "Handle",
        Parent = sliderBg,
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(ratio, -7, 0.5, -7),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 13,
    })
    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = handle
    end)

    local valLabel = GuiHelpers.Create("TextLabel", {
        Parent = parent,
        Size = UDim2.new(0, 40, 1, 0),
        Position = UDim2.new(1, -42, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(currentVal),
        TextColor3 = theme.Accent,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 11,
    })

    local dragging = false
    local UserInputSvc = game:GetService("UserInputService")

    handle.InputBegan:Connect(function(input)
        pcall(function()
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)
    end)

    UserInputSvc.InputChanged:Connect(function(input)
        pcall(function()
            if dragging and
                input.UserInputType == Enum.UserInputType.MouseMovement then
                local bgPos = sliderBg.AbsolutePosition.X
                local bgW = sliderBg.AbsoluteSize.X
                local relX = math.clamp(input.Position.X - bgPos, 0, bgW)
                local newRatio = relX / bgW
                local newVal = math.floor(
                    minVal + newRatio * (maxVal - minVal)
                )
                currentVal = newVal
                fillBar.Size = UDim2.new(newRatio, 0, 1, 0)
                handle.Position = UDim2.new(newRatio, -7, 0.5, -7)
                valLabel.Text = tostring(newVal)
                if callback then
                    pcall(callback, newVal)
                end
            end
        end)
    end)

    UserInputSvc.InputEnded:Connect(function(input)
        pcall(function()
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
    end)

    return sliderBg, valLabel
end

-- ========================
-- THEME SECTION
-- ========================
MakeSection("Appearance")

MakeSettingRow("Theme", function(frame)
    MakeDropdown(
        frame,
        {"Dark", "Light", "Monokai"},
        SETState.CurrentTheme,
        function(val)
            SETState.CurrentTheme = val
            DEX.ApplyTheme(val)
        end
    )
end)

MakeSettingRow("Window Transparency", function(frame)
    MakeSlider(frame, 0, 80, 0, function(val)
        pcall(function()
            SETState.Transparency = val
            local t = val / 100
            DEX.MainFrame.BackgroundTransparency = t
        end)
    end)
end)

-- ========================
-- BEHAVIOUR SECTION
-- ========================
MakeSection("Behaviour")

MakeSettingRow("Auto Scan on Open", function(frame)
    MakeToggle(frame, SETState.AutoScanOnOpen, function(val)
        SETState.AutoScanOnOpen = val
    end)
end)

MakeSettingRow("Notifications", function(frame)
    MakeToggle(frame, SETState.NotificationsEnabled, function(val)
        SETState.NotificationsEnabled = val
        if not val then
            DEX.ShowNotification = function() end
        else
            DEX.ShowNotification = getgenv().DEX._origShowNotif
                or DEX.ShowNotification
        end
    end)
end)

MakeSettingRow("Show Status Bar", function(frame)
    MakeToggle(frame, SETState.ShowStatusBar, function(val)
        pcall(function()
            SETState.ShowStatusBar = val
            local statusBar = DEX.MainFrame:FindFirstChild("StatusBar")
                or DEX.ScreenGui:FindFirstChildWhichIsA(
                    "Frame", true
                )
            if DEX.MainFrame then
                local sb = DEX.MainFrame:FindFirstChild("StatusBar", true)
                if sb then
                    sb.Visible = val
                end
            end
        end)
    end)
end)

MakeSettingRow("Max Log Entries", function(frame)
    MakeSlider(frame, 100, 1000, SETState.MaxLogEntries, function(val)
        SETState.MaxLogEntries = val
        if DEX.CSState then
            DEX.CSState.MaxEntries = val
        end
    end)
end)

-- ========================
-- EXPLORER SECTION
-- ========================
MakeSection("Explorer")

MakeSettingRow("Auto-Expand game", function(frame)
    MakeToggle(frame, true, function(val)
        pcall(function()
            if DEX.ExpState then
                DEX.ExpState.ExpandedMap[game] = val
            end
        end)
    end)
end)

MakeSettingRow("Node Height", function(frame)
    MakeSlider(frame, 16, 32, 22, function(val)
        pcall(function()
            DEX.ShowNotification(
                "Setting",
                "Node height: " .. val .. "px (reload tree to apply)",
                "info"
            )
        end)
    end)
end)

-- ========================
-- REMOTE SPY SECTION
-- ========================
MakeSection("Remote Spy")

MakeSettingRow("Enable Spy on Scan", function(frame)
    MakeToggle(frame, false, function(val)
        pcall(function()
            SETState.RemoteSpyEnabled = val
            if DEX.RMState then
                DEX.RMState.SpyEnabled = val
            end
        end)
    end)
end)

MakeSettingRow("Max Spy Log Entries", function(frame)
    MakeSlider(frame, 50, 500, 200, function(val)
        pcall(function()
            if DEX.RMState then
                DEX.RMState.MaxLogEntries = val
            end
        end)
    end)
end)

-- ========================
-- SAVE / LOAD SETTINGS
-- ========================
MakeSection("Save & Load")

local saveRow = MakeSettingRow("Settings File", function(frame)
    local saveBtn = GuiHelpers.Create("TextButton", {
        Parent = frame,
        Size = UDim2.new(0, 70, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = theme.AccentDark,
        Text = "Save",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        ZIndex = 11,
    })
    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = saveBtn
    end)

    local loadBtn = GuiHelpers.Create("TextButton", {
        Parent = frame,
        Size = UDim2.new(0, 70, 1, 0),
        Position = UDim2.new(0, 74, 0, 0),
        BackgroundColor3 = theme.ButtonBg,
        Text = "Load",
        TextColor3 = theme.Text,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        ZIndex = 11,
    })
    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = loadBtn
    end)

    saveBtn.MouseButton1Click:Connect(function()
        pcall(function()
            local data = {
                "-- DEX Settings",
                "-- " .. os.date("%Y-%m-%d %H:%M:%S"),
                "Theme=" .. SETState.CurrentTheme,
                "Transparency=" .. tostring(SETState.Transparency),
                "AutoScan=" .. tostring(SETState.AutoScanOnOpen),
                "Notifications=" .. tostring(SETState.NotificationsEnabled),
                "MaxLogEntries=" .. tostring(SETState.MaxLogEntries),
                "RemoteSpy=" .. tostring(SETState.RemoteSpyEnabled),
            }
            writefile("dex_settings.txt", table.concat(data, "\n"))
            DEX.ShowNotification("Settings", "Saved to dex_settings.txt", "success")
        end)
    end)

    loadBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if not isfile("dex_settings.txt") then
                DEX.ShowNotification(
                    "Settings", "No settings file found", "warning"
                )
                return
            end
            local content = readfile("dex_settings.txt")
            for line in string.gmatch(content, "[^\n]+") do
                pcall(function()
                    if string.sub(line, 1, 2) == "--" then return end
                    local key, val = string.match(line, "^(.-)=(.+)$")
                    if key and val then
                        if key == "Theme" then
                            DEX.ApplyTheme(val)
                            SETState.CurrentTheme = val
                        elseif key == "Transparency" then
                            local t = tonumber(val) or 0
                            SETState.Transparency = t
                            DEX.MainFrame.BackgroundTransparency = t / 100
                        elseif key == "AutoScan" then
                            SETState.AutoScanOnOpen = (val == "true")
                        elseif key == "Notifications" then
                            SETState.NotificationsEnabled = (val == "true")
                        elseif key == "MaxLogEntries" then
                            SETState.MaxLogEntries = tonumber(val) or 500
                        elseif key == "RemoteSpy" then
                            SETState.RemoteSpyEnabled = (val == "true")
                        end
                    end
                end)
            end
            DEX.ShowNotification("Settings", "Loaded from dex_settings.txt", "success")
        end)
    end)

    GuiHelpers.AddHover(saveBtn, theme.AccentDark, theme.Accent)
    GuiHelpers.AddHover(loadBtn, theme.ButtonBg, theme.ButtonHover)
end)

-- ========================
-- ABOUT SECTION
-- ========================
MakeSection("About DEX")

MakeSettingRow("Version", function(frame)
    local vLbl = GuiHelpers.Create("TextLabel", {
        Parent = frame,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "v" .. DEX.Version .. " | Solara Edition",
        TextColor3 = theme.Accent,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 11,
    })
end)

MakeSettingRow("Executor sUNC", function(frame)
    local suncLbl = GuiHelpers.Create("TextLabel", {
        Parent = frame,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "Solara ~39% sUNC",
        TextColor3 = theme.Warning,
        TextSize = 10,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 11,
    })
end)

MakeSettingRow("Supported APIs", function(frame)
    local apiLbl = GuiHelpers.Create("TextLabel", {
        Parent = frame,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "pcall, loadstring, task.*, LogService",
        TextColor3 = theme.TextSecondary,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 11,
    })
end)

-- Recreate buttons row
settingsRowOrder = settingsRowOrder + 1
local actionRow = GuiHelpers.Create("Frame", {
    Name = "ActionRow",
    Parent = settingsScroll,
    Size = UDim2.new(1, -8, 0, 36),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 9,
    LayoutOrder = settingsRowOrder,
})

local reloadBtn = GuiHelpers.Create("TextButton", {
    Name = "ReloadBtn",
    Parent = actionRow,
    Size = UDim2.new(0, 100, 1, -6),
    Position = UDim2.new(0, 0, 0, 3),
    BackgroundColor3 = theme.Warning,
    Text = "Reload DEX",
    TextColor3 = Color3.new(0, 0, 0),
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = reloadBtn
end)

local closeAllBtn = GuiHelpers.Create("TextButton", {
    Name = "CloseAllBtn",
    Parent = actionRow,
    Size = UDim2.new(0, 100, 1, -6),
    Position = UDim2.new(0, 106, 0, 3),
    BackgroundColor3 = theme.Error,
    Text = "Close DEX",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = closeAllBtn
end)

reloadBtn.MouseButton1Click:Connect(function()
    pcall(function()
        DEX.ShowNotification("DEX", "Reloading...", "warning")
        task.delay(0.5, function()
            pcall(function()
                DEX.ScreenGui:Destroy()
            end)
        end)
    end)
end)

closeAllBtn.MouseButton1Click:Connect(function()
    pcall(function()
        pcall(function()
            if DEX.StatsConnection then
                DEX.StatsConnection:Disconnect()
            end
        end)
        pcall(function()
            if DEX.PLState and DEX.PLState.SpectateConnection then
                DEX.PLState.SpectateConnection:Disconnect()
            end
        end)
        DEX.ScreenGui:Destroy()
    end)
end)

GuiHelpers.AddHover(reloadBtn, theme.Warning,
    Color3.new(theme.Warning.R, theme.Warning.G * 0.8, 0)
)
GuiHelpers.AddHover(closeAllBtn, theme.Error,
    Color3.new(theme.Error.R * 0.7, 0, 0)
)

-- Update canvas
local function UpdateSettingsCanvas()
    pcall(function()
        local totalH = settingsLayout.AbsoluteContentSize.Y + 20
        settingsScroll.CanvasSize = UDim2.new(0, 0, 0, totalH)
    end)
end

settingsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(
    UpdateSettingsCanvas
)

-- ========================
-- LIVE STATS PANEL (RIGHT)
-- ========================
local statsTitle = GuiHelpers.Create("Frame", {
    Name = "StatsTitle",
    Parent = statsPanel,
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.BackgroundSecondary,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local statsTitleLbl = GuiHelpers.Create("TextLabel", {
    Parent = statsTitle,
    Size = UDim2.new(1, -8, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "Live Statistics",
    TextColor3 = theme.Text,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 10,
})

local statsScroll = GuiHelpers.Create("ScrollingFrame", {
    Name = "StatsScroll",
    Parent = statsPanel,
    Size = UDim2.new(1, 0, 1, -30),
    Position = UDim2.new(0, 0, 0, 30),
    BackgroundColor3 = theme.BackgroundTertiary,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = theme.Scrollbar,
    CanvasSize = UDim2.new(0, 0, 0, 600),
    ZIndex = 8,
    ClipsDescendants = true,
})

local statsContentLayout = GuiHelpers.Create("UIListLayout", {
    Parent = statsScroll,
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2),
})

-- Stat display row
local statRowOrder = 0
local statLabels = {}

local function MakeStatDisplay(label, initialVal, color)
    statRowOrder = statRowOrder + 1
    local row = GuiHelpers.Create("Frame", {
        Name = "Stat_" .. label,
        Parent = statsScroll,
        Size = UDim2.new(1, -4, 0, 28),
        BackgroundColor3 = statRowOrder % 2 == 0
            and theme.BackgroundSecondary
            or theme.BackgroundTertiary,
        BorderSizePixel = 0,
        ZIndex = 9,
        LayoutOrder = statRowOrder,
    })
    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = row
    end)

    local lbl = GuiHelpers.Create("TextLabel", {
        Parent = row,
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = theme.TextSecondary,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10,
    })

    -- Mini bar background
    local barBg = GuiHelpers.Create("Frame", {
        Parent = row,
        Size = UDim2.new(0.3, 0, 0, 4),
        Position = UDim2.new(0.5, 0, 0.5, -2),
        BackgroundColor3 = theme.ButtonBg,
        BorderSizePixel = 0,
        ZIndex = 10,
    })
    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = barBg
    end)

    local barFill = GuiHelpers.Create("Frame", {
        Parent = barBg,
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = color or theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 11,
    })
    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = barFill
    end)

    local valLbl = GuiHelpers.Create("TextLabel", {
        Parent = row,
        Size = UDim2.new(0.18, 0, 1, 0),
        Position = UDim2.new(0.82, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(initialVal),
        TextColor3 = color or theme.Accent,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 10,
    })

    statLabels[label] = {
        valLbl = valLbl,
        barFill = barFill,
    }

    return row
end

-- Create stat rows
MakeStatDisplay("FPS", "0", theme.Success)
MakeStatDisplay("Ping (ms)", "0", theme.Accent)
MakeStatDisplay("Memory (MB)", "0", theme.Warning)
MakeStatDisplay("Script Count", "0", theme.SyntaxKeyword)
MakeStatDisplay("Remote Count", "0", theme.SyntaxFunction)
MakeStatDisplay("Player Count", "0", theme.SyntaxString)
MakeStatDisplay("Instance Count", "0", theme.TextSecondary)
MakeStatDisplay("Run Time (s)", "0", theme.AccentDark)
MakeStatDisplay("Camera CFrame", "...", theme.TextSecondary)
MakeStatDisplay("LocalPlayer Pos", "...", theme.Accent)
MakeStatDisplay("Humanoid Health", "...", theme.Success)
MakeStatDisplay("WalkSpeed", "...", theme.SyntaxNumber)

local function UpdateStatLabel(label, value, barRatio)
    pcall(function()
        local data = statLabels[label]
        if not data then return end
        data.valLbl.Text = tostring(value)
        if barRatio then
            local clampedRatio = math.clamp(barRatio, 0, 1)
            data.barFill.Size = UDim2.new(clampedRatio, 0, 1, 0)

            if label == "FPS" then
                local c = theme.Error
                if clampedRatio > 0.3 then c = theme.Warning end
                if clampedRatio > 0.6 then c = theme.Success end
                data.barFill.BackgroundColor3 = c
                data.valLbl.TextColor3 = c
            elseif label == "Ping (ms)" then
                local c = theme.Success
                if clampedRatio > 0.3 then c = theme.Warning end
                if clampedRatio > 0.6 then c = theme.Error end
                data.barFill.BackgroundColor3 = c
                data.valLbl.TextColor3 = c
            end
        end
    end)
end

-- ========================
-- LIVE STATS UPDATE LOOP
-- ========================
local fpsCounter = 0
local lastFPSTick = tick()
local liveFPS = 0
local startTime = tick()
local statsUpdateConn = nil

pcall(function()
    statsUpdateConn = RunService.RenderStepped:Connect(function()
        pcall(function()
            fpsCounter = fpsCounter + 1
            local now = tick()
            if now - lastFPSTick >= 0.5 then
                liveFPS = math.floor(fpsCounter / (now - lastFPSTick))
                fpsCounter = 0
                lastFPSTick = now

                -- Only update if settings tab is active
                if DEX.ActiveTab ~= "Settings" then return end

                -- FPS
                UpdateStatLabel("FPS", liveFPS, liveFPS / 60)

                -- Ping
                local ping = 0
                pcall(function()
                    ping = math.floor(
                        LocalPlayer:GetNetworkPing() * 1000
                    )
                end)
                UpdateStatLabel("Ping (ms)", ping .. "ms", ping / 500)

                -- Memory
                local mem = 0
                pcall(function()
                    mem = math.floor(gcinfo() / 1024)
                end)
                UpdateStatLabel("Memory (MB)", mem .. "MB", mem / 512)

                -- Script Count
                local scriptCount = 0
                if DEX.SVState then
                    scriptCount = #DEX.SVState.AllScripts
                end
                UpdateStatLabel("Script Count", scriptCount, scriptCount / 200)

                -- Remote Count
                local remoteCount = 0
                if DEX.RMState then
                    remoteCount = #DEX.RMState.AllRemotes
                end
                UpdateStatLabel("Remote Count", remoteCount, remoteCount / 100)

                -- Player Count
                local playerCount = #Players:GetPlayers()
                UpdateStatLabel("Player Count", playerCount, playerCount / 20)

                -- Run Time
                local runTime = math.floor(now - startTime)
                local mins = math.floor(runTime / 60)
                local secs = runTime % 60
                UpdateStatLabel(
                    "Run Time (s)",
                    string.format("%dm %ds", mins, secs),
                    nil
                )

                -- Camera CFrame
                pcall(function()
                    local cam = workspace.CurrentCamera
                    local pos = cam.CFrame.Position
                    UpdateStatLabel(
                        "Camera CFrame",
                        string.format("%.0f, %.0f, %.0f",
                            pos.X, pos.Y, pos.Z),
                        nil
                    )
                end)

                -- LocalPlayer pos + humanoid
                pcall(function()
                    local char = LocalPlayer.Character
                    if char then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local pos = hrp.Position
                            UpdateStatLabel(
                                "LocalPlayer Pos",
                                string.format("%.0f, %.0f, %.0f",
                                    pos.X, pos.Y, pos.Z),
                                nil
                            )
                        end
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then
                            local hp = math.floor(hum.Health)
                            local maxHp = math.floor(hum.MaxHealth)
                            UpdateStatLabel(
                                "Humanoid Health",
                                hp .. "/" .. maxHp,
                                maxHp > 0 and hp / maxHp or 0
                            )
                            UpdateStatLabel(
                                "WalkSpeed",
                                tostring(hum.WalkSpeed),
                                hum.WalkSpeed / 32
                            )
                        end
                    end
                end)

                -- Instance count estimate
                pcall(function()
                    local count = 0
                    local desc = game:GetDescendants()
                    count = #desc
                    UpdateStatLabel(
                        "Instance Count",
                        tostring(count),
                        math.min(count / 5000, 1)
                    )
                end)
            end
        end)
    end)
end)

DEX.StatsUpdateConn = statsUpdateConn

-- ========================
-- SETTINGS TAB AUTO-LOAD
-- ========================
local origSwitch = DEX.SwitchTab
DEX.SwitchTab = function(tabName)
    origSwitch(tabName)
    if tabName == "Settings" then
        task.spawn(function()
            pcall(UpdateSettingsCanvas)
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

-- ========================
-- KEYBIND: Toggle DEX (RightControl)
-- ========================
local dexVisible = true
local UserInputSvc = game:GetService("UserInputService")

UserInputSvc.InputBegan:Connect(function(input, processed)
    pcall(function()
        if processed then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            dexVisible = not dexVisible
            DEX.MainFrame.Visible = dexVisible
            if dexVisible then
                DEX.ShowNotification("DEX", "Opened (RCtrl to hide)", "info")
            end
        end
        if input.KeyCode == Enum.KeyCode.RightShift then
            DEX.SwitchTab("Console")
            DEX.MainFrame.Visible = true
            dexVisible = true
        end
    end)
end)

-- ========================
-- STORE ORIGINAL NOTIF
-- ========================
DEX._origShowNotif = DEX.ShowNotification

-- ========================
-- FINAL STATUS UPDATE
-- ========================
pcall(function()
    DEX.StatusText.Text = "DEX Ready | All 6 modules loaded | RCtrl = toggle"
end)

-- ========================
-- STARTUP SUMMARY
-- ========================
task.spawn(function()
    pcall(function()
        task.wait(0.5)
        if DEX.AddLogEntry then
            DEX.AddLogEntry(
                "All DEX modules loaded successfully!", "Info"
            )
            DEX.AddLogEntry(
                "RightControl = toggle DEX | RightShift = open console", "Info"
            )
            DEX.AddLogEntry(
                "Solara sUNC 39% - using compatible API only", "Info"
            )
        end
    end)
end)

print("[DEX] Part 6: Settings + Integration loaded")
print("[DEX] ================================")
print("[DEX] DEX Explorer v1.0 FULLY LOADED!")
print("[DEX] Keybinds:")
print("[DEX]   RightControl = Toggle visibility")
print("[DEX]   RightShift   = Open Console")
print("[DEX] ================================")
print("[DEX] getgenv().DEX is available globally")

getgenv().DEX = DEX
