-- DEX Explorer v1.0 for Solara
-- Part 5: Players Panel + Console (FIXED)
-- =========================================

assert(getgenv().DEX, "DEX Core (Part 1) must be loaded first!")

local DEX = getgenv().DEX
local theme = DEX.CurrentTheme
local Utils = DEX.Utils
local GuiHelpers = DEX.GuiHelpers
local playersPage = DEX.Pages["Players"]
local consolePage = DEX.Pages["Console"]

assert(playersPage, "Players page not found!")
assert(consolePage, "Console page not found!")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

-- ========================
-- PLAYERS STATE
-- ========================
local PLState = {
    SelectedPlayer = nil,
    SpectateTarget = nil,
    SpectateConnection = nil,
    PlayerRows = {},
    AvatarCache = {},
}

DEX.PLState = PLState

-- ========================
-- PLAYERS LAYOUT
-- ========================
local plLeftPanel = GuiHelpers.Create("Frame", {
    Name = "PLLeft",
    Parent = playersPage,
    Size = UDim2.new(0, 240, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.BackgroundTertiary,
    BorderSizePixel = 0,
    ZIndex = 8,
    ClipsDescendants = true,
})

local plDivider = GuiHelpers.Create("Frame", {
    Name = "PLDivider",
    Parent = playersPage,
    Size = UDim2.new(0, 2, 1, 0),
    Position = UDim2.new(0, 240, 0, 0),
    BackgroundColor3 = theme.Border,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local plRightPanel = GuiHelpers.Create("Frame", {
    Name = "PLRight",
    Parent = playersPage,
    Size = UDim2.new(1, -242, 1, 0),
    Position = UDim2.new(0, 242, 0, 0),
    BackgroundColor3 = theme.Background,
    BorderSizePixel = 0,
    ZIndex = 8,
    ClipsDescendants = true,
})

-- ========================
-- LEFT: PLAYER LIST HEADER
-- ========================
local plHeader = GuiHelpers.Create("Frame", {
    Name = "PLHeader",
    Parent = plLeftPanel,
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.BackgroundSecondary,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local plTitle = GuiHelpers.Create("TextLabel", {
    Name = "PLTitle",
    Parent = plHeader,
    Size = UDim2.new(1, -8, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "Players (0)",
    TextColor3 = theme.Text,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 10,
})

local plRefreshBtn = GuiHelpers.Create("TextButton", {
    Name = "PLRefresh",
    Parent = plHeader,
    Size = UDim2.new(0, 60, 1, -6),
    Position = UDim2.new(1, -64, 0, 3),
    BackgroundColor3 = theme.ButtonBg,
    Text = "Refresh",
    TextColor3 = theme.Text,
    TextSize = 9,
    Font = Enum.Font.Gotham,
    BorderSizePixel = 0,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 3)
    c.Parent = plRefreshBtn
end)

local plScroll = GuiHelpers.Create("ScrollingFrame", {
    Name = "PLScroll",
    Parent = plLeftPanel,
    Size = UDim2.new(1, 0, 1, -30),
    Position = UDim2.new(0, 0, 0, 30),
    BackgroundColor3 = theme.BackgroundTertiary,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = theme.Scrollbar,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 8,
    ClipsDescendants = true,
})

local plLayout = GuiHelpers.Create("UIListLayout", {
    Parent = plScroll,
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2),
})

-- ========================
-- RIGHT: PLAYER DETAILS
-- ========================
local plDetailHeader = GuiHelpers.Create("Frame", {
    Name = "PLDetailHeader",
    Parent = plRightPanel,
    Size = UDim2.new(1, 0, 0, 110),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.BackgroundSecondary,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local plAvatar = GuiHelpers.Create("ImageLabel", {
    Name = "PLAvatar",
    Parent = plDetailHeader,
    Size = UDim2.new(0, 80, 0, 80),
    Position = UDim2.new(0, 14, 0, 15),
    BackgroundColor3 = theme.ButtonBg,
    Image = "",
    BorderSizePixel = 0,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = plAvatar
end)

local plAvatarPlaceholder = GuiHelpers.Create("TextLabel", {
    Parent = plAvatar,
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "?",
    TextColor3 = theme.TextDisabled,
    TextSize = 28,
    Font = Enum.Font.GothamBold,
    ZIndex = 11,
})

local plDetailName = GuiHelpers.Create("TextLabel", {
    Name = "PLDetailName",
    Parent = plDetailHeader,
    Size = UDim2.new(1, -110, 0, 24),
    Position = UDim2.new(0, 104, 0, 16),
    BackgroundTransparency = 1,
    Text = "Select a player",
    TextColor3 = theme.Text,
    TextSize = 15,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 10,
})

local plDetailId = GuiHelpers.Create("TextLabel", {
    Name = "PLDetailId",
    Parent = plDetailHeader,
    Size = UDim2.new(1, -110, 0, 16),
    Position = UDim2.new(0, 104, 0, 40),
    BackgroundTransparency = 1,
    Text = "UserId: --",
    TextColor3 = theme.TextSecondary,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 10,
})

local plDetailPing = GuiHelpers.Create("TextLabel", {
    Name = "PLDetailPing",
    Parent = plDetailHeader,
    Size = UDim2.new(1, -110, 0, 16),
    Position = UDim2.new(0, 104, 0, 56),
    BackgroundTransparency = 1,
    Text = "Ping: --ms",
    TextColor3 = theme.TextSecondary,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 10,
})

local plDetailTeam = GuiHelpers.Create("TextLabel", {
    Name = "PLDetailTeam",
    Parent = plDetailHeader,
    Size = UDim2.new(1, -110, 0, 16),
    Position = UDim2.new(0, 104, 0, 72),
    BackgroundTransparency = 1,
    Text = "Team: --",
    TextColor3 = theme.TextSecondary,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 10,
})

local plDetailAcct = GuiHelpers.Create("TextLabel", {
    Name = "PLDetailAcct",
    Parent = plDetailHeader,
    Size = UDim2.new(1, -110, 0, 16),
    Position = UDim2.new(0, 104, 0, 88),
    BackgroundTransparency = 1,
    Text = "Account: --",
    TextColor3 = theme.TextSecondary,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 10,
})

-- ========================
-- PLAYER ACTION BUTTONS
-- ========================
local plActionsFrame = GuiHelpers.Create("Frame", {
    Name = "PLActions",
    Parent = plRightPanel,
    Size = UDim2.new(1, 0, 0, 36),
    Position = UDim2.new(0, 0, 0, 110),
    BackgroundColor3 = theme.BackgroundSecondary,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local function MakePLBtn(label, xPos, w, color)
    local btn = GuiHelpers.Create("TextButton", {
        Name = "PLBtn_" .. label,
        Parent = plActionsFrame,
        Size = UDim2.new(0, w, 1, -8),
        Position = UDim2.new(0, xPos, 0, 4),
        BackgroundColor3 = color or theme.ButtonBg,
        Text = label,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 10,
        Font = Enum.Font.GothamSemibold,
        BorderSizePixel = 0,
        ZIndex = 10,
    })
    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = btn
    end)
    GuiHelpers.AddHover(btn, color or theme.ButtonBg, theme.ButtonHover)
    return btn
end

local teleportBtn = MakePLBtn("Teleport To",  4,   90, theme.Accent)
local spectateBtn = MakePLBtn("Spectate",      98,  70, theme.AccentDark)
local copyNameBtn = MakePLBtn("Copy Name",     172, 76, theme.ButtonBg)
local copyIdBtn   = MakePLBtn("Copy UserId",   252, 80, theme.ButtonBg)

-- ========================
-- PLAYER STATS SCROLL
-- ========================
local plStatsScroll = GuiHelpers.Create("ScrollingFrame", {
    Name = "PLStatsScroll",
    Parent = plRightPanel,
    Size = UDim2.new(1, 0, 1, -152),
    Position = UDim2.new(0, 0, 0, 152),
    BackgroundColor3 = theme.Background,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = theme.Scrollbar,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 8,
    ClipsDescendants = true,
})

local plStatsLayout = GuiHelpers.Create("UIListLayout", {
    Parent = plStatsScroll,
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 1),
})

-- ========================
-- STAT ROW HELPER
-- ========================
local function MakeStatRow(labelText, valueText, color, order)
    local row = GuiHelpers.Create("Frame", {
        Name = "Stat_" .. labelText,
        Parent = plStatsScroll,
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundColor3 = order % 2 == 0
            and theme.BackgroundSecondary
            or theme.Background,
        BorderSizePixel = 0,
        ZIndex = 9,
        LayoutOrder = order,
    })

    GuiHelpers.Create("TextLabel", {
        Parent = row,
        Size = UDim2.new(0.45, 0, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = theme.TextSecondary,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10,
    })

    GuiHelpers.Create("TextLabel", {
        Parent = row,
        Size = UDim2.new(0.55, -8, 1, 0),
        Position = UDim2.new(0.45, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(valueText),
        TextColor3 = color or theme.Text,
        TextSize = 10,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10,
    })

    return row
end

-- ========================
-- LOAD PLAYER DETAILS
-- ========================
local pingUpdateConn = nil

local function LoadPlayerDetails(player)
    pcall(function()
        for _, c in ipairs(plStatsScroll:GetChildren()) do
            pcall(function()
                if not c:IsA("UIListLayout") then
                    c:Destroy()
                end
            end)
        end

        if not player then return end
        PLState.SelectedPlayer = player

        local name = Utils.SafeGet(player, "Name") or "Unknown"
        local userId = Utils.SafeGet(player, "UserId") or 0
        local displayName = Utils.SafeGet(player, "DisplayName") or name

        local nameText = displayName
        if displayName ~= name then
            nameText = displayName .. " (@" .. name .. ")"
        end
        plDetailName.Text = nameText
        plDetailId.Text = "UserId: " .. tostring(userId)

        plAvatar.Image = ""
        plAvatarPlaceholder.Text = string.upper(string.sub(name, 1, 1))

        task.spawn(function()
            pcall(function()
                local imgUrl, isReady = Players:GetUserThumbnailAsync(
                    userId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size100x100
                )
                if isReady and imgUrl then
                    plAvatar.Image = imgUrl
                    plAvatarPlaceholder.Text = ""
                    PLState.AvatarCache[userId] = imgUrl
                end
            end)
        end)

        local teamName = "None"
        pcall(function()
            if player.Team then
                teamName = player.Team.Name
            end
        end)
        plDetailTeam.Text = "Team: " .. teamName

        local acctAge = Utils.SafeGet(player, "AccountAge") or 0
        plDetailAcct.Text = "Account Age: " .. tostring(acctAge) .. " days"

        if player == LocalPlayer then
            local ping = 0
            pcall(function()
                ping = math.floor(player:GetNetworkPing() * 1000)
            end)
            plDetailPing.Text = "Ping: " .. tostring(ping) .. "ms"

            if pingUpdateConn then
                pcall(function() pingUpdateConn:Disconnect() end)
            end
            pingUpdateConn = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local p = math.floor(player:GetNetworkPing() * 1000)
                    plDetailPing.Text = "Ping: " .. tostring(p) .. "ms"
                    local pingColor = theme.Success
                    if p > 150 then pingColor = theme.Warning end
                    if p > 300 then pingColor = theme.Error end
                    plDetailPing.TextColor3 = pingColor
                end)
            end)
        else
            plDetailPing.Text = "Ping: N/A"
            plDetailPing.TextColor3 = theme.TextSecondary
        end

        local rowIdx = 0

        rowIdx = rowIdx + 1
        local secHeader = GuiHelpers.Create("Frame", {
            Name = "SecHeader_Player",
            Parent = plStatsScroll,
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundColor3 = theme.AccentDark,
            BorderSizePixel = 0,
            ZIndex = 9,
            LayoutOrder = rowIdx,
        })
        GuiHelpers.Create("TextLabel", {
            Parent = secHeader,
            Size = UDim2.new(1, -8, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = "Player Info",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 10,
        })

        rowIdx = rowIdx + 1
        MakeStatRow("Name", name, theme.Text, rowIdx)
        rowIdx = rowIdx + 1
        MakeStatRow("DisplayName", displayName, theme.Text, rowIdx)
        rowIdx = rowIdx + 1
        MakeStatRow("UserId", tostring(userId), theme.Accent, rowIdx)
        rowIdx = rowIdx + 1
        MakeStatRow("AccountAge", tostring(acctAge) .. " days",
            theme.TextSecondary, rowIdx)
        rowIdx = rowIdx + 1
        MakeStatRow("Team", teamName, theme.Text, rowIdx)

        local isFriend = false
        pcall(function()
            isFriend = LocalPlayer:IsFriendsWith(userId)
        end)
        rowIdx = rowIdx + 1
        MakeStatRow("Friend",
            tostring(isFriend),
            isFriend and theme.Success or theme.TextSecondary,
            rowIdx
        )

        local char = Utils.SafeGet(player, "Character")
        if char then
            rowIdx = rowIdx + 1
            local charHeader = GuiHelpers.Create("Frame", {
                Name = "SecHeader_Char",
                Parent = plStatsScroll,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundColor3 = theme.AccentDark,
                BorderSizePixel = 0,
                ZIndex = 9,
                LayoutOrder = rowIdx,
            })
            GuiHelpers.Create("TextLabel", {
                Parent = charHeader,
                Size = UDim2.new(1, -8, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1,
                Text = "Character",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 10,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 10,
            })

            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local pos = Utils.SafeGet(hrp, "Position")
                if pos then
                    rowIdx = rowIdx + 1
                    MakeStatRow(
                        "Position",
                        string.format("%.1f, %.1f, %.1f",
                            pos.X, pos.Y, pos.Z),
                        theme.SyntaxNumber,
                        rowIdx
                    )
                end
            end

            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local hp = math.floor(Utils.SafeGet(hum, "Health") or 0)
                local maxHp = math.floor(Utils.SafeGet(hum, "MaxHealth") or 0)
                local ws = Utils.SafeGet(hum, "WalkSpeed") or 0
                local jp = Utils.SafeGet(hum, "JumpPower") or 0

                rowIdx = rowIdx + 1
                MakeStatRow("Health",
                    hp .. " / " .. maxHp, theme.Success, rowIdx)
                rowIdx = rowIdx + 1
                MakeStatRow("WalkSpeed",
                    tostring(ws), theme.Accent, rowIdx)
                rowIdx = rowIdx + 1
                MakeStatRow("JumpPower",
                    tostring(jp), theme.Accent, rowIdx)
            end
        end

        local totalH = rowIdx * 23
        plStatsScroll.CanvasSize = UDim2.new(0, 0, 0, totalH)
    end)
end

-- ========================
-- TELEPORT
-- ========================
teleportBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local target = PLState.SelectedPlayer
        if not target then
            DEX.ShowNotification("Teleport", "No player selected", "warning")
            return
        end
        if target == LocalPlayer then
            DEX.ShowNotification(
                "Teleport", "Cannot teleport to yourself", "warning"
            )
            return
        end
        local targetChar = Utils.SafeGet(target, "Character")
        if not targetChar then
            DEX.ShowNotification(
                "Teleport", "Target has no character", "warning"
            )
            return
        end
        local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
        if not targetHRP then
            DEX.ShowNotification("Teleport", "HRP not found", "warning")
            return
        end
        local localChar = Utils.SafeGet(LocalPlayer, "Character")
        if not localChar then return end
        local localHRP = localChar:FindFirstChild("HumanoidRootPart")
        if not localHRP then return end
        local ok, cf = pcall(function()
            return targetHRP.CFrame
        end)
        if ok and cf then
            localHRP.CFrame = cf * CFrame.new(2, 0, 0)
            DEX.ShowNotification(
                "Teleported",
                "To: " .. Utils.GetInstanceName(target),
                "success"
            )
        end
    end)
end)

-- ========================
-- SPECTATE
-- ========================
local spectating = false

spectateBtn.MouseButton1Click:Connect(function()
    pcall(function()
        if spectating then
            if PLState.SpectateConnection then
                pcall(function()
                    PLState.SpectateConnection:Disconnect()
                end)
                PLState.SpectateConnection = nil
            end
            pcall(function()
                camera.CameraType = Enum.CameraType.Custom
                local lc = LocalPlayer.Character
                if lc then
                    local lh = lc:FindFirstChildOfClass("Humanoid")
                    if lh then
                        camera.CameraSubject = lh
                    end
                end
            end)
            spectating = false
            spectateBtn.Text = "Spectate"
            spectateBtn.BackgroundColor3 = theme.AccentDark
            PLState.SpectateTarget = nil
            DEX.ShowNotification("Spectate", "Stopped", "info")
            return
        end

        local target = PLState.SelectedPlayer
        if not target then
            DEX.ShowNotification("Spectate", "No player selected", "warning")
            return
        end
        if target == LocalPlayer then
            DEX.ShowNotification(
                "Spectate", "Cannot spectate yourself", "warning"
            )
            return
        end
        local targetChar = Utils.SafeGet(target, "Character")
        if not targetChar then
            DEX.ShowNotification(
                "Spectate", "Target has no character", "warning"
            )
            return
        end
        local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
        if targetHum then
            pcall(function()
                camera.CameraType = Enum.CameraType.Custom
                camera.CameraSubject = targetHum
            end)
        end

        PLState.SpectateTarget = target
        spectating = true
        spectateBtn.Text = "Stop Spec"
        spectateBtn.BackgroundColor3 = theme.Warning

        PLState.SpectateConnection = RunService.RenderStepped:Connect(
            function()
                pcall(function()
                    local tc = Utils.SafeGet(target, "Character")
                    if not tc then return end
                    local th = tc:FindFirstChildOfClass("Humanoid")
                    if th then
                        camera.CameraSubject = th
                    end
                end)
            end
        )

        DEX.ShowNotification(
            "Spectating", Utils.GetInstanceName(target), "success"
        )
    end)
end)

copyNameBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local p = PLState.SelectedPlayer
        if not p then return end
        local name = Utils.SafeGet(p, "Name") or "Unknown"
        setclipboard(name)
        DEX.ShowNotification("Copied", name, "success")
    end)
end)

copyIdBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local p = PLState.SelectedPlayer
        if not p then return end
        local uid = tostring(Utils.SafeGet(p, "UserId") or 0)
        setclipboard(uid)
        DEX.ShowNotification("Copied", "UserId: " .. uid, "success")
    end)
end)

GuiHelpers.AddHover(teleportBtn, theme.Accent, theme.AccentHover)

-- ========================
-- RENDER PLAYER LIST
-- ========================
local function RenderPlayerList()
    pcall(function()
        for _, c in ipairs(plScroll:GetChildren()) do
            pcall(function()
                if not c:IsA("UIListLayout") then
                    c:Destroy()
                end
            end)
        end

        local playerList = Players:GetPlayers()
        plTitle.Text = "Players (" .. #playerList .. ")"

        for idx, player in ipairs(playerList) do
            local isLocal = (player == LocalPlayer)
            local isSelected = (PLState.SelectedPlayer == player)

            local rowBg = theme.BackgroundTertiary
            if idx % 2 == 0 then
                rowBg = theme.BackgroundSecondary
            end
            if isLocal then
                rowBg = Color3.new(
                    theme.AccentDark.R * 0.7,
                    theme.AccentDark.G * 0.7,
                    theme.AccentDark.B * 0.7
                )
            end

            local row = GuiHelpers.Create("Frame", {
                Name = "PLRow_" .. idx,
                Parent = plScroll,
                Size = UDim2.new(1, -4, 0, 58),
                BackgroundColor3 = isSelected
                    and theme.NodeSelected or rowBg,
                BorderSizePixel = 0,
                ZIndex = 9,
                LayoutOrder = idx,
            })
            pcall(function()
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 4)
                c.Parent = row
            end)

            local avatarImg = GuiHelpers.Create("ImageLabel", {
                Name = "Avatar",
                Parent = row,
                Size = UDim2.new(0, 42, 0, 42),
                Position = UDim2.new(0, 6, 0, 8),
                BackgroundColor3 = theme.ButtonBg,
                Image = "",
                BorderSizePixel = 0,
                ZIndex = 10,
            })
            pcall(function()
                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(0, 6)
                c.Parent = avatarImg
            end)

            local userId = Utils.SafeGet(player, "UserId") or 0
            local playerName = Utils.SafeGet(player, "Name") or "?"

            if PLState.AvatarCache[userId] then
                avatarImg.Image = PLState.AvatarCache[userId]
            else
                local phText = string.upper(string.sub(playerName, 1, 1))
                local placeholder = GuiHelpers.Create("TextLabel", {
                    Parent = avatarImg,
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = phText,
                    TextColor3 = theme.TextSecondary,
                    TextSize = 18,
                    Font = Enum.Font.GothamBold,
                    ZIndex = 11,
                })

                local capturedUid = userId
                local capturedImg = avatarImg
                local capturedPh = placeholder
                task.spawn(function()
                    pcall(function()
                        local imgUrl, isReady =
                            Players:GetUserThumbnailAsync(
                                capturedUid,
                                Enum.ThumbnailType.HeadShot,
                                Enum.ThumbnailSize.Size60x60
                            )
                        if isReady and imgUrl then
                            capturedImg.Image = imgUrl
                            PLState.AvatarCache[capturedUid] = imgUrl
                            if capturedPh and capturedPh.Parent then
                                capturedPh.Text = ""
                            end
                        end
                    end)
                end)
            end

            if isLocal then
                local localBadge = GuiHelpers.Create("TextLabel", {
                    Parent = row,
                    Size = UDim2.new(0, 22, 0, 12),
                    Position = UDim2.new(0, 6, 0, 42),
                    BackgroundColor3 = theme.Accent,
                    Text = "YOU",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 7,
                    Font = Enum.Font.GothamBold,
                    BorderSizePixel = 0,
                    ZIndex = 11,
                })
                pcall(function()
                    local c = Instance.new("UICorner")
                    c.CornerRadius = UDim.new(0, 2)
                    c.Parent = localBadge
                end)
            end

            local displayName = Utils.SafeGet(player, "DisplayName") or "Unknown"
            GuiHelpers.Create("TextLabel", {
                Parent = row,
                Size = UDim2.new(1, -58, 0, 18),
                Position = UDim2.new(0, 54, 0, 6),
                BackgroundTransparency = 1,
                Text = Utils.Truncate(displayName, 20),
                TextColor3 = isSelected and Color3.new(1,1,1) or theme.Text,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 10,
            })

            GuiHelpers.Create("TextLabel", {
                Parent = row,
                Size = UDim2.new(1, -58, 0, 14),
                Position = UDim2.new(0, 54, 0, 24),
                BackgroundTransparency = 1,
                Text = "@" .. playerName,
                TextColor3 = theme.TextSecondary,
                TextSize = 9,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 10,
            })

            GuiHelpers.Create("TextLabel", {
                Parent = row,
                Size = UDim2.new(1, -58, 0, 12),
                Position = UDim2.new(0, 54, 0, 38),
                BackgroundTransparency = 1,
                Text = "ID: " .. tostring(userId),
                TextColor3 = theme.TextDisabled,
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

            local capturedPlayer = player
            local capturedRow = row
            local capturedRowBg = rowBg

            clickBtn.MouseEnter:Connect(function()
                pcall(function()
                    if PLState.SelectedPlayer ~= capturedPlayer then
                        capturedRow.BackgroundColor3 = theme.NodeHover
                    end
                end)
            end)
            clickBtn.MouseLeave:Connect(function()
                pcall(function()
                    if PLState.SelectedPlayer ~= capturedPlayer then
                        capturedRow.BackgroundColor3 = capturedRowBg
                    end
                end)
            end)
            clickBtn.MouseButton1Click:Connect(function()
                pcall(function()
                    LoadPlayerDetails(capturedPlayer)
                    RenderPlayerList()
                end)
            end)
            clickBtn.MouseButton2Click:Connect(function()
                pcall(function()
                    local mp = UserInputService:GetMouseLocation()
                    local pName = Utils.SafeGet(capturedPlayer, "Name") or "?"
                    local pId = tostring(
                        Utils.SafeGet(capturedPlayer, "UserId") or 0
                    )
                    DEX.ShowContextMenu({
                        {
                            label = "View Details",
                            callback = function()
                                LoadPlayerDetails(capturedPlayer)
                                RenderPlayerList()
                            end
                        },
                        {
                            label = "Copy Name",
                            callback = function()
                                setclipboard(pName)
                                DEX.ShowNotification(
                                    "Copied", pName, "success"
                                )
                            end
                        },
                        {
                            label = "Copy UserId",
                            callback = function()
                                setclipboard(pId)
                                DEX.ShowNotification(
                                    "Copied", "ID: " .. pId, "success"
                                )
                            end
                        },
                        {
                            label = "Copy Profile URL",
                            callback = function()
                                local url = "https://www.roblox.com/users/"
                                    .. pId .. "/profile"
                                setclipboard(url)
                                DEX.ShowNotification(
                                    "URL Copied", url, "success"
                                )
                            end
                        },
                    }, mp.X, mp.Y)
                end)
            end)
        end

        local totalH = #playerList * 62
        plScroll.CanvasSize = UDim2.new(0, 0, 0, totalH)
    end)
end

plRefreshBtn.MouseButton1Click:Connect(function()
    pcall(function()
        RenderPlayerList()
        if PLState.SelectedPlayer then
            LoadPlayerDetails(PLState.SelectedPlayer)
        end
    end)
end)
GuiHelpers.AddHover(plRefreshBtn, theme.ButtonBg, theme.ButtonHover)

Players.PlayerAdded:Connect(function()
    pcall(function()
        task.wait(0.5)
        RenderPlayerList()
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    pcall(function()
        if PLState.SelectedPlayer == player then
            PLState.SelectedPlayer = nil
        end
        RenderPlayerList()
    end)
end)

-- ========================
-- CONSOLE STATE
-- ========================
local CSState = {
    History = {},
    HistoryIndex = 0,
    LogEntries = {},
    MaxEntries = 500,
    AutoScroll = true,
    Filter = "All",
}

DEX.CSState = CSState

-- ========================
-- CONSOLE LAYOUT
-- ========================
local consoleToolbar = GuiHelpers.Create("Frame", {
    Name = "ConsoleToolbar",
    Parent = consolePage,
    Size = UDim2.new(1, 0, 0, 32),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = theme.BackgroundSecondary,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local logFilterTypes = {"All", "Print", "Warn", "Error", "Info"}
local logFilterBtns = {}
local logFilterW = 54

for i, ft in ipairs(logFilterTypes) do
    local isActive = ft == "All"
    local fb = GuiHelpers.Create("TextButton", {
        Name = "LogFilter_" .. ft,
        Parent = consoleToolbar,
        Size = UDim2.new(0, logFilterW, 1, -8),
        Position = UDim2.new(0, (i-1)*logFilterW + 2, 0, 4),
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
    logFilterBtns[ft] = fb
end

local clearConsoleBtn = GuiHelpers.Create("TextButton", {
    Name = "ClearConsoleBtn",
    Parent = consoleToolbar,
    Size = UDim2.new(0, 50, 1, -8),
    Position = UDim2.new(0, #logFilterTypes * logFilterW + 6, 0, 4),
    BackgroundColor3 = theme.ButtonBg,
    Text = "Clear",
    TextColor3 = theme.Text,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    BorderSizePixel = 0,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 3)
    c.Parent = clearConsoleBtn
end)

local saveConsoleBtn = GuiHelpers.Create("TextButton", {
    Name = "SaveConsoleBtn",
    Parent = consoleToolbar,
    Size = UDim2.new(0, 50, 1, -8),
    Position = UDim2.new(0, #logFilterTypes * logFilterW + 60, 0, 4),
    BackgroundColor3 = theme.ButtonBg,
    Text = "Save",
    TextColor3 = theme.Text,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    BorderSizePixel = 0,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 3)
    c.Parent = saveConsoleBtn
end)

local autoScrollBtn = GuiHelpers.Create("TextButton", {
    Name = "AutoScrollBtn",
    Parent = consoleToolbar,
    Size = UDim2.new(0, 80, 1, -8),
    Position = UDim2.new(0, #logFilterTypes * logFilterW + 114, 0, 4),
    BackgroundColor3 = theme.Success,
    Text = "AutoScroll ON",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 9,
    Font = Enum.Font.GothamSemibold,
    BorderSizePixel = 0,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 3)
    c.Parent = autoScrollBtn
end)

local consoleLogCount = GuiHelpers.Create("TextLabel", {
    Name = "ConsoleLogCount",
    Parent = consoleToolbar,
    Size = UDim2.new(0, 80, 1, 0),
    Position = UDim2.new(1, -84, 0, 0),
    BackgroundTransparency = 1,
    Text = "0 entries",
    TextColor3 = theme.TextSecondary,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 10,
})

local consoleLog = GuiHelpers.Create("ScrollingFrame", {
    Name = "ConsoleLog",
    Parent = consolePage,
    Size = UDim2.new(1, 0, 1, -100),
    Position = UDim2.new(0, 0, 0, 34),
    BackgroundColor3 = theme.BackgroundTertiary,
    BorderSizePixel = 0,
    ScrollBarThickness = 5,
    ScrollBarImageColor3 = theme.Scrollbar,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 8,
    ClipsDescendants = true,
})

local consoleLogLayout = GuiHelpers.Create("UIListLayout", {
    Parent = consoleLog,
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 1),
})

-- ========================
-- INPUT AREA
-- ========================
local inputArea = GuiHelpers.Create("Frame", {
    Name = "InputArea",
    Parent = consolePage,
    Size = UDim2.new(1, 0, 0, 66),
    Position = UDim2.new(0, 0, 1, -66),
    BackgroundColor3 = theme.BackgroundSecondary,
    BorderSizePixel = 0,
    ZIndex = 9,
})

GuiHelpers.Create("TextLabel", {
    Name = "InputPrompt",
    Parent = inputArea,
    Size = UDim2.new(0, 20, 0, 34),
    Position = UDim2.new(0, 4, 0, 2),
    BackgroundTransparency = 1,
    Text = ">",
    TextColor3 = theme.Accent,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    ZIndex = 10,
})

local consoleInput = GuiHelpers.Create("TextBox", {
    Name = "ConsoleInput",
    Parent = inputArea,
    Size = UDim2.new(1, -100, 0, 34),
    Position = UDim2.new(0, 24, 0, 2),
    BackgroundColor3 = theme.InputBg,
    Text = "",
    PlaceholderText = "Enter Lua code...",
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
    c.Parent = consoleInput
end)
pcall(function()
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, 6)
    p.PaddingTop = UDim.new(0, 4)
    p.Parent = consoleInput
end)

local runBtn = GuiHelpers.Create("TextButton", {
    Name = "RunBtn",
    Parent = inputArea,
    Size = UDim2.new(0, 68, 0, 34),
    Position = UDim2.new(1, -72, 0, 2),
    BackgroundColor3 = theme.Success,
    Text = "Run",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    ZIndex = 10,
})
pcall(function()
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = runBtn
end)

-- Snippets
local snippetsFrame = GuiHelpers.Create("Frame", {
    Name = "SnippetsFrame",
    Parent = inputArea,
    Size = UDim2.new(1, 0, 0, 28),
    Position = UDim2.new(0, 0, 0, 38),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 9,
})

local snippets = {
    {label = "print()",  code = 'print("Hello from DEX!")'},
    {label = "game",     code = "print(game.Name)"},
    {label = "memory",   code = "print('Memory: ' .. math.floor(gcinfo()/1024) .. ' MB')"},
    {label = "ping",     code = "print('Ping: ' .. math.floor(game:GetService('Players').LocalPlayer:GetNetworkPing()*1000) .. 'ms')"},
    {label = "players",  code = "for _,p in ipairs(game:GetService('Players'):GetPlayers()) do print(p.Name) end"},
}

local snippetX = 4
for _, snip in ipairs(snippets) do
    local sw = #snip.label * 7 + 16
    local sb = GuiHelpers.Create("TextButton", {
        Name = "Snip_" .. snip.label,
        Parent = snippetsFrame,
        Size = UDim2.new(0, sw, 1, -4),
        Position = UDim2.new(0, snippetX, 0, 2),
        BackgroundColor3 = theme.ButtonBg,
        Text = snip.label,
        TextColor3 = theme.Accent,
        TextSize = 9,
        Font = Enum.Font.Code,
        BorderSizePixel = 0,
        ZIndex = 10,
    })
    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 3)
        c.Parent = sb
    end)
    snippetX = snippetX + sw + 4

    local capturedCode = snip.code
    sb.MouseButton1Click:Connect(function()
        pcall(function()
            consoleInput.Text = capturedCode
        end)
    end)
    GuiHelpers.AddHover(sb, theme.ButtonBg, theme.ButtonHover)
end

-- ========================
-- LOG ENTRY ADD
-- ========================
local LOG_COLORS = {
    ["Print"]  = theme.Text,
    ["Warn"]   = theme.Warning,
    ["Error"]  = theme.Error,
    ["Info"]   = theme.Accent,
    ["DEX"]    = theme.SyntaxFunction,
}
local LOG_ICONS = {
    ["Print"]  = "i",
    ["Warn"]   = "!",
    ["Error"]  = "X",
    ["Info"]   = "?",
    ["DEX"]    = "D",
}

local entryCount = 0

local function AddLogEntry(message, logType)
    pcall(function()
        logType = logType or "Print"
        entryCount = entryCount + 1

        local entry = {
            id = entryCount,
            message = tostring(message),
            logType = logType,
            time = os.date("%H:%M:%S"),
        }

        table.insert(CSState.LogEntries, entry)
        if #CSState.LogEntries > CSState.MaxEntries then
            table.remove(CSState.LogEntries, 1)
        end

        local filterMatch = (CSState.Filter == "All") or
            (CSState.Filter == logType)
        if not filterMatch then return end

        local msgColor = LOG_COLORS[logType] or theme.Text
        local icon = LOG_ICONS[logType] or "i"

        local lineCount = 1
        for _ in string.gmatch(entry.message, "\n") do
            lineCount = lineCount + 1
        end
        local rowH = math.max(20, lineCount * 14 + 6)

        local rowBg = theme.BackgroundTertiary
        if entryCount % 2 == 0 then
            rowBg = theme.BackgroundSecondary
        end
        if logType == "Error" then
            rowBg = Color3.new(
                theme.Error.R * 0.15,
                theme.Error.G * 0.05,
                theme.Error.B * 0.05
            )
        elseif logType == "Warn" then
            rowBg = Color3.new(
                theme.Warning.R * 0.12,
                theme.Warning.G * 0.10,
                theme.Warning.B * 0.02
            )
        end

        local row = GuiHelpers.Create("Frame", {
            Name = "LogEntry" .. entryCount,
            Parent = consoleLog,
            Size = UDim2.new(1, -4, 0, rowH),
            BackgroundColor3 = rowBg,
            BorderSizePixel = 0,
            ZIndex = 9,
            LayoutOrder = entryCount,
        })

        local iconBadge = GuiHelpers.Create("TextLabel", {
            Parent = row,
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 2, 0, 2),
            BackgroundColor3 = msgColor,
            BackgroundTransparency = 0.6,
            Text = icon,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 9,
            Font = Enum.Font.GothamBold,
            BorderSizePixel = 0,
            ZIndex = 10,
        })
        pcall(function()
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 3)
            c.Parent = iconBadge
        end)

        GuiHelpers.Create("TextLabel", {
            Parent = row,
            Size = UDim2.new(0, 52, 0, 16),
            Position = UDim2.new(0, 20, 0, 2),
            BackgroundTransparency = 1,
            Text = entry.time,
            TextColor3 = theme.TextDisabled,
            TextSize = 9,
            Font = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 10,
        })

        GuiHelpers.Create("TextLabel", {
            Parent = row,
            Size = UDim2.new(1, -78, 0, rowH - 4),
            Position = UDim2.new(0, 74, 0, 2),
            BackgroundTransparency = 1,
            Text = Utils.Truncate(entry.message, 300),
            TextColor3 = msgColor,
            TextSize = 11,
            Font = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            ZIndex = 10,
        })

        local copyRowBtn = GuiHelpers.Create("TextButton", {
            Parent = row,
            Size = UDim2.new(0, 32, 0, 14),
            Position = UDim2.new(1, -36, 0, 3),
            BackgroundColor3 = theme.ButtonBg,
            Text = "Copy",
            TextColor3 = theme.TextSecondary,
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

        local capturedMsg = entry.message
        copyRowBtn.MouseButton1Click:Connect(function()
            pcall(function()
                setclipboard(capturedMsg)
                DEX.ShowNotification("Copied", "Log entry copied", "success")
            end)
        end)

        local totalH = entryCount * 22
        consoleLog.CanvasSize = UDim2.new(0, 0, 0, totalH + 10)

        if CSState.AutoScroll then
            pcall(function()
                consoleLog.CanvasPosition = Vector2.new(
                    0,
                    math.max(0, totalH - consoleLog.AbsoluteSize.Y + 30)
                )
            end)
        end

        consoleLogCount.Text = #CSState.LogEntries .. " entries"
    end)
end

DEX.AddLogEntry = AddLogEntry

-- ========================
-- REBUILD LOG
-- ========================
local function RebuildLogDisplay()
    pcall(function()
        for _, c in ipairs(consoleLog:GetChildren()) do
            pcall(function()
                if not c:IsA("UIListLayout") then
                    c:Destroy()
                end
            end)
        end
        entryCount = 0
        for _, entry in ipairs(CSState.LogEntries) do
            local filterMatch = (CSState.Filter == "All") or
                (CSState.Filter == entry.logType)
            if filterMatch then
                AddLogEntry(entry.message, entry.logType)
            end
        end
    end)
end

-- ========================
-- LOGSERVICE HOOK
-- ========================
pcall(function()
    LogService.MessageOut:Connect(function(message, messageType)
        pcall(function()
            local logType = "Print"
            if messageType == Enum.MessageType.MessageWarning then
                logType = "Warn"
            elseif messageType == Enum.MessageType.MessageError then
                logType = "Error"
            elseif messageType == Enum.MessageType.MessageInfo then
                logType = "Info"
            end
            AddLogEntry(message, logType)
        end)
    end)
end)

-- ========================
-- DEXPRINT / DEXWARN
-- Явные параметры вместо vararg
-- ========================
pcall(function()
    local origPrint = print
    local origWarn = warn

    getgenv().dexprint = function(a, b, c, d, e, f, g, h)
        pcall(function()
            local parts = {}
            if a ~= nil then table.insert(parts, tostring(a)) end
            if b ~= nil then table.insert(parts, tostring(b)) end
            if c ~= nil then table.insert(parts, tostring(c)) end
            if d ~= nil then table.insert(parts, tostring(d)) end
            if e ~= nil then table.insert(parts, tostring(e)) end
            if f ~= nil then table.insert(parts, tostring(f)) end
            if g ~= nil then table.insert(parts, tostring(g)) end
            if h ~= nil then table.insert(parts, tostring(h)) end
            local msg = table.concat(parts, "\t")
            AddLogEntry(msg, "Print")
        end)
        pcall(origPrint, a, b, c, d, e, f, g, h)
    end

    getgenv().dexwarn = function(a, b, c, d, e, f, g, h)
        pcall(function()
            local parts = {}
            if a ~= nil then table.insert(parts, tostring(a)) end
            if b ~= nil then table.insert(parts, tostring(b)) end
            if c ~= nil then table.insert(parts, tostring(c)) end
            if d ~= nil then table.insert(parts, tostring(d)) end
            if e ~= nil then table.insert(parts, tostring(e)) end
            if f ~= nil then table.insert(parts, tostring(f)) end
            if g ~= nil then table.insert(parts, tostring(g)) end
            if h ~= nil then table.insert(parts, tostring(h)) end
            local msg = table.concat(parts, "\t")
            AddLogEntry(msg, "Warn")
        end)
        pcall(origWarn, a, b, c, d, e, f, g, h)
    end
end)

-- ========================
-- EXECUTE CODE
-- Без vararg, чистый pcall(fn)
-- ========================
local function ExecuteCode(code)
    pcall(function()
        if not code or code == "" then return end

        table.insert(CSState.History, code)
        if #CSState.History > 100 then
            table.remove(CSState.History, 1)
        end
        CSState.HistoryIndex = #CSState.History + 1

        AddLogEntry("> " .. Utils.Truncate(code, 100), "DEX")

        local fn, compErr = loadstring(code)
        if not fn then
            local errMsg = tostring(compErr)
            AddLogEntry("Syntax Error: " .. errMsg, "Error")
            DEX.ShowNotification("Syntax Error", errMsg, "error")
            return
        end

        task.spawn(function()
            local ok, runErr = pcall(fn)
            if not ok then
                local errMsg = tostring(runErr)
                AddLogEntry("Runtime Error: " .. errMsg, "Error")
                DEX.ShowNotification("Runtime Error", errMsg, "error")
            else
                DEX.ShowNotification("Execute", "Ran successfully", "success")
            end
        end)
    end)
end

-- ========================
-- RUN BUTTON
-- ========================
runBtn.MouseButton1Click:Connect(function()
    pcall(function()
        local code = consoleInput.Text
        ExecuteCode(code)
        consoleInput.Text = ""
    end)
end)

GuiHelpers.AddHover(runBtn, theme.Success,
    Color3.new(0.2, 0.9, 0.4)
)

-- ========================
-- HISTORY NAVIGATION
-- ========================
consoleInput.InputBegan:Connect(function(input)
    pcall(function()
        if input.KeyCode == Enum.KeyCode.Return then
            if not UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                local code = consoleInput.Text
                ExecuteCode(code)
                consoleInput.Text = ""
            end
        elseif input.KeyCode == Enum.KeyCode.Up then
            if #CSState.History > 0 then
                CSState.HistoryIndex = math.max(1, CSState.HistoryIndex - 1)
                local h = CSState.History[CSState.HistoryIndex]
                if h then consoleInput.Text = h end
            end
        elseif input.KeyCode == Enum.KeyCode.Down then
            if #CSState.History > 0 then
                CSState.HistoryIndex = math.min(
                    #CSState.History + 1,
                    CSState.HistoryIndex + 1
                )
                if CSState.HistoryIndex > #CSState.History then
                    consoleInput.Text = ""
                else
                    local h = CSState.History[CSState.HistoryIndex]
                    if h then consoleInput.Text = h end
                end
            end
        end
    end)
end)

-- ========================
-- FILTER BUTTONS
-- ========================
for _, ft in ipairs(logFilterTypes) do
    local capturedFt = ft
    local fbtn = logFilterBtns[ft]
    if fbtn then
        fbtn.MouseButton1Click:Connect(function()
            pcall(function()
                CSState.Filter = capturedFt
                for _, ft2 in ipairs(logFilterTypes) do
                    local b2 = logFilterBtns[ft2]
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
                RebuildLogDisplay()
            end)
        end)
    end
end

clearConsoleBtn.MouseButton1Click:Connect(function()
    pcall(function()
        CSState.LogEntries = {}
        for _, c in ipairs(consoleLog:GetChildren()) do
            pcall(function()
                if not c:IsA("UIListLayout") then
                    c:Destroy()
                end
            end)
        end
        entryCount = 0
        consoleLog.CanvasSize = UDim2.new(0, 0, 0, 0)
        consoleLogCount.Text = "0 entries"
        DEX.ShowNotification("Console", "Cleared", "info")
    end)
end)

saveConsoleBtn.MouseButton1Click:Connect(function()
    pcall(function()
        if #CSState.LogEntries == 0 then
            DEX.ShowNotification("Save", "Log is empty", "warning")
            return
        end
        local lines = {
            "-- DEX Console Log",
            "-- " .. os.date("%Y-%m-%d %H:%M:%S"),
            "",
        }
        for _, entry in ipairs(CSState.LogEntries) do
            table.insert(lines,
                "[" .. entry.time .. "] [" .. entry.logType .. "] " ..
                entry.message
            )
        end
        writefile("dex_console_log.txt", table.concat(lines, "\n"))
        DEX.ShowNotification("Saved", "dex_console_log.txt", "success")
    end)
end)

autoScrollBtn.MouseButton1Click:Connect(function()
    pcall(function()
        CSState.AutoScroll = not CSState.AutoScroll
        if CSState.AutoScroll then
            autoScrollBtn.Text = "AutoScroll ON"
            autoScrollBtn.BackgroundColor3 = theme.Success
            autoScrollBtn.TextColor3 = Color3.new(1, 1, 1)
        else
            autoScrollBtn.Text = "AutoScroll OFF"
            autoScrollBtn.BackgroundColor3 = theme.ButtonBg
            autoScrollBtn.TextColor3 = theme.TextSecondary
        end
    end)
end)

GuiHelpers.AddHover(clearConsoleBtn, theme.ButtonBg, theme.ButtonHover)
GuiHelpers.AddHover(saveConsoleBtn, theme.ButtonBg, theme.ButtonHover)

-- ========================
-- AUTO LOAD ON TAB SWITCH
-- ========================
local plLoaded = false
local origSwitch = DEX.SwitchTab

DEX.SwitchTab = function(tabName)
    origSwitch(tabName)
    if tabName == "Players" and not plLoaded then
        plLoaded = true
        task.spawn(function()
            pcall(function()
                task.wait(0.1)
                RenderPlayerList()
                LoadPlayerDetails(LocalPlayer)
                RenderPlayerList()
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

-- ========================
-- STARTUP MESSAGES
-- ========================
AddLogEntry("DEX Explorer v1.0 Console Ready", "Info")
AddLogEntry("Solara | sUNC ~39% | Compatible mode", "Info")
AddLogEntry("Enter = Run code | Shift+Enter = newline", "Info")
AddLogEntry("Up/Down = history navigation", "Info")
AddLogEntry("Use dexprint() and dexwarn() for tagged output", "Info")

print("[DEX] Part 5 (FIXED): Players + Console loaded")
print("[DEX] Type 'готов' for Part 6: Settings Panel")

getgenv().DEX = DEX
