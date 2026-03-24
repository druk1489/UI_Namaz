-- ============================================================
--   LordHubLib v2.0
--   Style: ASU AutoBuild / Boat Builder Hub
--   - Slight rounded corners
--   - Semi-transparent dark bg
--   - Tabs in header (horizontal)
--   - Sections slide up on select
--   - No resize bar
--   - Single instance (unload on re-run)
--   - Gear button top right
-- ============================================================

-- ── Unload предыдущего экземпляра ────────────────────────────
if _G.LordHubUnload then
    pcall(_G.LordHubUnload)
end

local LordHubLib = {}
_G.LordHubActive = true

local connections = {}
local function trackConn(c)
    table.insert(connections, c)
    return c
end

local function unload()
    _G.LordHubActive = false
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    connections = {}
    local PGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    for _, gui in ipairs(PGui:GetChildren()) do
        if gui.Name:find("LordHub") then
            gui:Destroy()
        end
    end
    -- Удаляем handles
    local wp = workspace:FindFirstChild("LordHubBB")
    if wp then wp:Destroy() end
    local mh = PGui:FindFirstChild("LordHubMove")
    if mh then mh:Destroy() end
    local rh = PGui:FindFirstChild("LordHubRot")
    if rh then rh:Destroy() end
end

_G.LordHubUnload = unload
LordHubLib.Unload = unload

local TweenService  = game:GetService("TweenService")
local UIS           = game:GetService("UserInputService")
local Players       = game:GetService("Players")
local LP            = Players.LocalPlayer
local PGui          = LP:WaitForChild("PlayerGui")

-- ── Тема ─────────────────────────────────────────────────────
local T = {
    BG          = Color3.fromRGB(18, 22, 28),
    BG_T        = 0.08,
    HDR         = Color3.fromRGB(12, 16, 22),
    HDR_T       = 0.05,
    SECT        = Color3.fromRGB(22, 28, 36),
    SECT_T      = 0.15,
    ROW         = Color3.fromRGB(28, 34, 44),
    ROW_T       = 0.2,
    BTN         = Color3.fromRGB(32, 40, 52),
    BTN_T       = 0.15,
    ACCENT      = Color3.fromRGB(80, 140, 220),
    TXT         = Color3.fromRGB(200, 210, 225),
    MUT         = Color3.fromRGB(100, 115, 140),
    SEP         = Color3.fromRGB(40, 50, 65),
    GREEN       = Color3.fromRGB(80, 200, 120),
    RED         = Color3.fromRGB(220, 70, 70),
    YEL         = Color3.fromRGB(240, 190, 45),
    STAR        = Color3.fromRGB(255, 200, 40),
    CORNER      = 4,
}
LordHubLib.Theme = T

-- ── Утилиты ──────────────────────────────────────────────────
local function tw(obj, props, dur, style, dir)
    local t = TweenService:Create(obj,
        TweenInfo.new(
            dur   or 0.15,
            style or Enum.EasingStyle.Quart,
            dir   or Enum.EasingDirection.Out
        ), props)
    t:Play()
    return t
end

local function cr(r, p)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r)
    return c
end

local function pad(p, v, h)
    local ui = Instance.new("UIPadding", p)
    ui.PaddingTop    = UDim.new(0, v)
    ui.PaddingBottom = UDim.new(0, v)
    ui.PaddingLeft   = UDim.new(0, h)
    ui.PaddingRight  = UDim.new(0, h)
    return ui
end

local function mkFrame(parent, props)
    local f = Instance.new("Frame", parent)
    f.BorderSizePixel = 0
    for k, v in pairs(props or {}) do
        f[k] = v
    end
    return f
end

local function mkLabel(parent, props)
    local l = Instance.new("TextLabel", parent)
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.Font = Enum.Font.Gotham
    l.TextSize = 11
    l.TextColor3 = T.TXT
    l.TextXAlignment = Enum.TextXAlignment.Left
    for k, v in pairs(props or {}) do
        l[k] = v
    end
    return l
end

local function mkBtn(parent, props)
    local b = Instance.new("TextButton", parent)
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.TextColor3 = T.TXT
    b.AutoButtonColor = false
    for k, v in pairs(props or {}) do
        b[k] = v
    end
    return b
end

-- ── Notifications ─────────────────────────────────────────────
local notifSG = Instance.new("ScreenGui", PGui)
notifSG.Name           = "LordHub_Notif"
notifSG.ResetOnSpawn   = false
notifSG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
notifSG.DisplayOrder   = 999

local notifHolder = mkFrame(notifSG, {
    Size = UDim2.new(0,260,0,500),
    Position = UDim2.new(1,-268,0,12),
    BackgroundTransparency = 1,
})
local notifList = Instance.new("UIListLayout", notifHolder)
notifList.Padding           = UDim.new(0,4)
notifList.VerticalAlignment = Enum.VerticalAlignment.Top
notifList.SortOrder         = Enum.SortOrder.LayoutOrder
local notifN = 0

function LordHubLib.Notify(title, msg, kind, duration)
    notifN    = notifN + 1
    duration  = duration or 4
    local acc = kind=="error"   and T.RED
             or kind=="success" and T.GREEN
             or kind=="warn"    and T.YEL
             or T.ACCENT

    local f = mkFrame(notifHolder, {
        Size = UDim2.new(1,0,0,54),
        BackgroundColor3 = T.HDR,
        BackgroundTransparency = 0.05,
        ClipsDescendants = true,
        LayoutOrder = notifN,
    })
    cr(T.CORNER, f)
    Instance.new("UIStroke", f).Color = acc

    local bar = mkFrame(f, {
        Size = UDim2.new(0,2,1,0),
        BackgroundColor3 = acc,
    })

    local prog = mkFrame(f, {
        Size = UDim2.new(1,0,0,2),
        Position = UDim2.new(0,0,1,-2),
        BackgroundColor3 = acc,
    })

    mkLabel(f, {
        Size = UDim2.new(1,-14,0,18),
        Position = UDim2.new(0,10,0,5),
        Text = tostring(title),
        TextColor3 = acc,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
    })
    mkLabel(f, {
        Size = UDim2.new(1,-14,0,14),
        Position = UDim2.new(0,10,0,26),
        Text = tostring(msg),
        TextColor3 = T.MUT,
        TextSize = 10,
    })

    f.Position = UDim2.new(0,280,0,0)
    tw(f, {Position=UDim2.new(0,0,0,0)}, 0.3, Enum.EasingStyle.Back)
    tw(prog, {Size=UDim2.new(0,0,0,2)}, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        tw(f, {Position=UDim2.new(0,280,0,0)}, 0.2)
        task.wait(0.22)
        f:Destroy()
    end)
end

-- ============================================================
--   WINDOW
-- ============================================================
function LordHubLib.NewWindow(cfg)
    cfg = cfg or {}
    local title  = cfg.Title  or "Lord Hub"
    local width  = cfg.Width  or 240
    local height = cfg.Height or 500
    local accent = cfg.Accent or T.ACCENT
    local pos    = cfg.Position or UDim2.new(0,40,0,60)

    -- ── ScreenGui ────────────────────────────────────────────
    local SG = Instance.new("ScreenGui", PGui)
    SG.Name            = cfg.Name or "LordHub_Win"
    SG.ResetOnSpawn    = false
    SG.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    SG.DisplayOrder    = 100

    -- ── Main Frame ───────────────────────────────────────────
    local WIN = mkFrame(SG, {
        Size = UDim2.new(0,width,0,height),
        Position = pos,
        BackgroundColor3 = T.BG,
        BackgroundTransparency = T.BG_T,
        ClipsDescendants = true,
    })
    cr(T.CORNER, WIN)
    local winStroke = Instance.new("UIStroke", WIN)
    winStroke.Color       = accent
    winStroke.Thickness   = 1
    winStroke.Transparency= 0.5

    -- ── Header ───────────────────────────────────────────────
    local HDR = mkFrame(WIN, {
        Size = UDim2.new(1,0,0,28),
        BackgroundColor3 = T.HDR,
        BackgroundTransparency = T.HDR_T,
        ZIndex = 5,
    })

    -- Collapse button
    local collapsed = false
    local savedH    = height

    local colBtn = mkBtn(HDR, {
        Size = UDim2.new(0,22,0,22),
        Position = UDim2.new(0,4,0.5,-11),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = T.MUT,
        TextSize = 10,
        ZIndex = 6,
    })

    -- Title
    mkLabel(HDR, {
        Size = UDim2.new(1,-90,1,0),
        Position = UDim2.new(0,24,0,0),
        Text = title,
        TextColor3 = T.TXT,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        ZIndex = 6,
    })

    -- Header right buttons container
    local hdrRight = mkFrame(HDR, {
        Size = UDim2.new(0,66,1,0),
        Position = UDim2.new(1,-68,0,0),
        BackgroundTransparency = 1,
        ZIndex = 6,
    })
    local hdrRightLayout = Instance.new("UIListLayout", hdrRight)
    hdrRightLayout.FillDirection       = Enum.FillDirection.Horizontal
    hdrRightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    hdrRightLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
    hdrRightLayout.Padding             = UDim.new(0,2)

    local function makeHdrBtn(icon, col)
        local b = mkBtn(hdrRight, {
            Size = UDim2.new(0,20,0,20),
            BackgroundColor3 = T.BTN,
            BackgroundTransparency = 0.5,
            Text = icon,
            TextColor3 = col or T.MUT,
            TextSize = 12,
            ZIndex = 7,
        })
        cr(3, b)
        trackConn(b.MouseEnter:Connect(function()
            tw(b, {BackgroundTransparency=0.1, TextColor3=T.TXT}, .1)
        end))
        trackConn(b.MouseLeave:Connect(function()
            tw(b, {BackgroundTransparency=0.5, TextColor3=col or T.MUT}, .1)
        end))
        return b
    end

    -- Collapse logic
    colBtn.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        if collapsed then
            savedH = WIN.AbsoluteSize.Y
            tw(WIN, {Size=UDim2.new(0,width,0,28)}, 0.2, Enum.EasingStyle.Quart)
            colBtn.Text = "▶"
        else
            tw(WIN, {Size=UDim2.new(0,width,0,savedH)}, 0.25, Enum.EasingStyle.Back)
            colBtn.Text = "▼"
        end
    end)

    -- ── Drag ─────────────────────────────────────────────────
    local dragging, dStart, wStart = false, nil, nil
    trackConn(HDR.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dStart   = i.Position
            wStart   = WIN.Position
        end
    end))
    trackConn(HDR.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
    trackConn(UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dStart
            WIN.Position = UDim2.new(
                wStart.X.Scale, wStart.X.Offset + d.X,
                wStart.Y.Scale, wStart.Y.Offset + d.Y
            )
        end
    end))

    -- ── Tab Bar ──────────────────────────────────────────────
    local TABBAR = mkFrame(WIN, {
        Size = UDim2.new(1,0,0,26),
        Position = UDim2.new(0,0,0,28),
        BackgroundColor3 = T.HDR,
        BackgroundTransparency = 0.1,
    })

    local tabLineTop = mkFrame(WIN, {
        Size = UDim2.new(1,0,0,1),
        Position = UDim2.new(0,0,0,28),
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.6,
    })
    local tabLineBot = mkFrame(WIN, {
        Size = UDim2.new(1,0,0,1),
        Position = UDim2.new(0,0,0,54),
        BackgroundColor3 = T.SEP,
        BackgroundTransparency = 0.3,
    })

    local tabLayout = Instance.new("UIListLayout", TABBAR)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    tabLayout.Padding       = UDim.new(0,0)

    -- ── Content ───────────────────────────────────────────────
    local CONTENT = mkFrame(WIN, {
        Size = UDim2.new(1,0,1,-55),
        Position = UDim2.new(0,0,0,55),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    })

    -- ── Tab система ──────────────────────────────────────────
    local tabs      = {}
    local activeTab = nil
    local tabCount  = 0

    local function makeScroll(parent)
        local s = Instance.new("ScrollingFrame", parent)
        s.Size                   = UDim2.new(1,0,1,0)
        s.BackgroundTransparency = 1
        s.BorderSizePixel        = 0
        s.ScrollBarThickness     = 2
        s.ScrollBarImageColor3   = accent
        s.CanvasSize             = UDim2.new(0,0,0,0)
        s.Visible                = false
        s.ScrollingDirection     = Enum.ScrollingDirection.Y
        local sl = Instance.new("UIListLayout", s)
        sl.Padding       = UDim.new(0,0)
        sl.SortOrder     = Enum.SortOrder.LayoutOrder
        sl.HorizontalAlignment = Enum.HorizontalAlignment.Center
        sl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            s.CanvasSize = UDim2.new(0,0,0,sl.AbsoluteContentSize.Y+6)
        end)
        return s
    end

    local function switchTab(name)
        if activeTab == name then return end
        if activeTab and tabs[activeTab] then
            local old = tabs[activeTab]
            old.scroll.Visible = false
            old.btn.BackgroundTransparency = 1
            old.ul.BackgroundTransparency  = 1
            tw(old.btn, {TextColor3=T.MUT}, .1)
        end
        activeTab = name
        local new = tabs[name]
        new.scroll.Visible = true
        new.btn.BackgroundTransparency = 0.7
        new.ul.BackgroundTransparency  = 0
        tw(new.btn, {TextColor3=T.TXT}, .1)
    end

    -- ── Section factory ──────────────────────────────────────
    local function makeSectionAPI(scroll, accentCol)
        accentCol = accentCol or accent
        local rowN = 0
        local api  = {}

        function api.Space(h)
            rowN = rowN + 1
            local f = mkFrame(scroll, {
                Size = UDim2.new(1,0,0,h or 4),
                BackgroundTransparency = 1,
                LayoutOrder = rowN,
            })
        end

        function api.Separator()
            rowN = rowN + 1
            local f = mkFrame(scroll, {
                Size = UDim2.new(1,0,0,1),
                BackgroundColor3 = T.SEP,
                BackgroundTransparency = 0.4,
                LayoutOrder = rowN,
            })
        end

        function api.Label(text, col, indent)
            rowN = rowN + 1
            local wrap = mkFrame(scroll, {
                Size = UDim2.new(1,0,0,18),
                BackgroundTransparency = 1,
                LayoutOrder = rowN,
            })
            local l = mkLabel(wrap, {
                Size = UDim2.new(1,-(indent or 8),1,0),
                Position = UDim2.new(0,indent or 8,0,0),
                Text = tostring(text),
                TextColor3 = col or T.MUT,
                TextWrapped = true,
            })
            return l
        end

        function api.Button(text, col, cb)
            rowN = rowN + 1
            col  = col or T.BTN
            local wrap = mkFrame(scroll, {
                Size = UDim2.new(1,0,0,30),
                BackgroundTransparency = 1,
                LayoutOrder = rowN,
            })
            pad(wrap, 3, 8)
            local b = mkBtn(wrap, {
                Size = UDim2.new(1,0,1,0),
                BackgroundColor3 = col,
                BackgroundTransparency = 0.2,
                Text = tostring(text),
            })
            cr(T.CORNER, b)

            trackConn(b.MouseEnter:Connect(function()
                tw(b, {BackgroundTransparency=0}, .1)
            end))
            trackConn(b.MouseLeave:Connect(function()
                tw(b, {BackgroundTransparency=0.2}, .1)
            end))
            trackConn(b.MouseButton1Down:Connect(function()
                tw(b, {
                    BackgroundTransparency=0.4,
                    Size=UDim2.new(0.97,0,0.88,0)
                }, .07)
            end))
            trackConn(b.MouseButton1Up:Connect(function()
                tw(b, {
                    BackgroundTransparency=0.2,
                    Size=UDim2.new(1,0,1,0)
                }, .12, Enum.EasingStyle.Back)
            end))
            if cb then
                trackConn(b.MouseButton1Click:Connect(cb))
            end
            return b
        end

        function api.Button2(t1,c1,t2,c2,cb1,cb2)
            rowN = rowN + 1
            local wrap = mkFrame(scroll, {
                Size = UDim2.new(1,0,0,30),
                BackgroundTransparency = 1,
                LayoutOrder = rowN,
            })
            pad(wrap, 3, 8)
            local inner = mkFrame(wrap, {
                Size = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1,
            })
            local ul = Instance.new("UIListLayout", inner)
            ul.FillDirection = Enum.FillDirection.Horizontal
            ul.Padding       = UDim.new(0,6)

            local function mkB(t, col, cb)
                col = col or T.BTN
                local b = mkBtn(inner, {
                    Size = UDim2.new(0.5,-3,1,0),
                    BackgroundColor3 = col,
                    BackgroundTransparency = 0.2,
                    Text = tostring(t),
                    TextSize = 10,
                })
                cr(T.CORNER, b)
                trackConn(b.MouseEnter:Connect(function()
                    tw(b,{BackgroundTransparency=0},.1)
                end))
                trackConn(b.MouseLeave:Connect(function()
                    tw(b,{BackgroundTransparency=0.2},.1)
                end))
                trackConn(b.MouseButton1Down:Connect(function()
                    tw(b,{BackgroundTransparency=0.4,
                        Size=UDim2.new(0.47,-3,0.88,0)},.07)
                end))
                trackConn(b.MouseButton1Up:Connect(function()
                    tw(b,{BackgroundTransparency=0.2,
                        Size=UDim2.new(0.5,-3,1,0)},.12,Enum.EasingStyle.Back)
                end))
                if cb then trackConn(b.MouseButton1Click:Connect(cb)) end
                return b
            end
            return mkB(t1,c1,cb1), mkB(t2,c2,cb2)
        end

        function api.Input(ph, numeric, default, cb)
            rowN = rowN + 1
            local wrap = mkFrame(scroll, {
                Size = UDim2.new(1,0,0,28),
                BackgroundTransparency = 1,
                LayoutOrder = rowN,
            })
            pad(wrap, 3, 8)
            local f = mkFrame(wrap, {
                Size = UDim2.new(1,0,1,0),
                BackgroundColor3 = T.ROW,
                BackgroundTransparency = T.ROW_T,
            })
            cr(T.CORNER, f)
            pad(f, 0, 7)
            local b = Instance.new("TextBox", f)
            b.Size               = UDim2.new(1,0,1,0)
            b.BackgroundTransparency = 1
            b.PlaceholderText    = tostring(ph or "")
            b.PlaceholderColor3  = T.MUT
            b.Text               = tostring(default or "")
            b.TextColor3         = T.TXT
            b.Font               = Enum.Font.Gotham
            b.TextSize           = 11
            b.ClearTextOnFocus   = false
            b.BorderSizePixel    = 0
            if numeric then
                trackConn(b:GetPropertyChangedSignal("Text"):Connect(function()
                    local v = b.Text:gsub("[^%d%.%-]","")
                    if v ~= b.Text then b.Text = v end
                end))
            end
            trackConn(b.Focused:Connect(function()
                tw(f, {BackgroundTransparency=0.05}, .1)
                local s = Instance.new("UIStroke", f)
                s.Name="IFS"; s.Thickness=1; s.Color=accentCol
            end))
            trackConn(b.FocusLost:Connect(function()
                tw(f, {BackgroundTransparency=T.ROW_T}, .1)
                local s = f:FindFirstChild("IFS")
                if s then s:Destroy() end
                if cb then cb(b.Text) end
            end))
            return b
        end

        function api.Toggle(labelText, default, cb)
            default = default == true
            rowN = rowN + 1
            local wrap = mkFrame(scroll, {
                Size = UDim2.new(1,0,0,26),
                BackgroundTransparency = 1,
                LayoutOrder = rowN,
            })
            -- Hover bg
            local hov = mkFrame(wrap, {
                Size = UDim2.new(1,0,1,0),
                BackgroundColor3 = accentCol,
                BackgroundTransparency = 1,
            })
            cr(T.CORNER, hov)

            mkLabel(wrap, {
                Size = UDim2.new(1,-42,1,0),
                Position = UDim2.new(0,10,0,0),
                Text = tostring(labelText),
                TextColor3 = T.TXT,
            })

            local track = mkFrame(wrap, {
                Size = UDim2.new(0,30,0,14),
                Position = UDim2.new(1,-36,0.5,-7),
                BackgroundColor3 = default and accentCol or T.ROW,
                BackgroundTransparency = default and 0.1 or 0.3,
            })
            cr(7, track)

            local knob = mkFrame(track, {
                Size = UDim2.new(0,10,0,10),
                Position = default
                    and UDim2.new(1,-12,0.5,-5)
                    or  UDim2.new(0,2,0.5,-5),
                BackgroundColor3 = default and T.TXT or T.MUT,
            })
            cr(5, knob)

            local on = default
            local clickBtn = mkBtn(wrap, {
                Size = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1,
                Text = "",
            })
            trackConn(clickBtn.MouseEnter:Connect(function()
                tw(hov,{BackgroundTransparency=0.9},.1)
            end))
            trackConn(clickBtn.MouseLeave:Connect(function()
                tw(hov,{BackgroundTransparency=1},.1)
            end))
            trackConn(clickBtn.MouseButton1Click:Connect(function()
                on = not on
                if on then
                    tw(track,{BackgroundColor3=accentCol,BackgroundTransparency=0.1},.15)
                    tw(knob,{Position=UDim2.new(1,-12,0.5,-5),BackgroundColor3=T.TXT},
                        .15,Enum.EasingStyle.Back)
                else
                    tw(track,{BackgroundColor3=T.ROW,BackgroundTransparency=0.3},.15)
                    tw(knob,{Position=UDim2.new(0,2,0.5,-5),BackgroundColor3=T.MUT},
                        .15,Enum.EasingStyle.Back)
                end
                if cb then pcall(cb, on) end
            end))
            return {
                GetValue = function() return on end,
                SetValue = function(v)
                    on = v == true
                    track.BackgroundColor3 = on and accentCol or T.ROW
                    track.BackgroundTransparency = on and 0.1 or 0.3
                    knob.Position = on
                        and UDim2.new(1,-12,0.5,-5)
                        or  UDim2.new(0,2,0.5,-5)
                    knob.BackgroundColor3 = on and T.TXT or T.MUT
                end,
            }
        end

        function api.Dropdown(items, cb)
            rowN = rowN + 1
            local cur = items[1] or "Select"
            local wrap = mkFrame(scroll, {
                Size = UDim2.new(1,0,0,26),
                BackgroundTransparency = 1,
                LayoutOrder = rowN,
            })
            pad(wrap, 2, 8)

            local host = mkBtn(wrap, {
                Size = UDim2.new(1,0,1,0),
                BackgroundColor3 = T.ROW,
                BackgroundTransparency = T.ROW_T,
                Text = "",
            })
            cr(T.CORNER, host)

            mkLabel(host, {
                Size = UDim2.new(1,-24,1,0),
                Position = UDim2.new(0,8,0,0),
                Text = tostring(cur),
                TextColor3 = T.TXT,
            })
            local arr = mkLabel(host, {
                Size = UDim2.new(0,18,1,0),
                Position = UDim2.new(1,-20,0,0),
                Text = "▾",
                TextColor3 = T.MUT,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
            })

            local popup = mkFrame(SG, {
                BackgroundColor3 = T.ROW,
                BackgroundTransparency = 0.05,
                ZIndex = 150,
                Visible = false,
            })
            cr(T.CORNER, popup)
            local pStroke = Instance.new("UIStroke", popup)
            pStroke.Color = accentCol; pStroke.Thickness = 1
            pStroke.Transparency = 0.5

            local psl = Instance.new("ScrollingFrame", popup)
            psl.Size = UDim2.new(1,0,1,0)
            psl.BackgroundTransparency = 1
            psl.BorderSizePixel = 0
            psl.ScrollBarThickness = 2
            psl.ScrollBarImageColor3 = accentCol
            psl.ZIndex = 151
            psl.CanvasSize = UDim2.new(0,0,0,0)
            local psll = Instance.new("UIListLayout", psl)
            psll.Padding = UDim.new(0,1)
            psll.SortOrder = Enum.SortOrder.LayoutOrder
            pad(psl, 3, 4)
            psll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                psl.CanvasSize = UDim2.new(0,0,0,psll.AbsoluteContentSize.Y+8)
            end)

            local lbl2 = host:FindFirstChildOfClass("TextLabel")
            local ddBtns = {}

            local function closeDD()
                tw(popup,{BackgroundTransparency=1},0.1)
                task.delay(0.1,function()
                    popup.Visible = false
                    popup.BackgroundTransparency = 0.05
                end)
                arr.Text = "▾"
            end

            local function buildList(newItems)
                for _,b in ipairs(ddBtns) do b:Destroy() end
                ddBtns = {}
                for i,item in ipairs(newItems) do
                    local ib = mkBtn(psl, {
                        Size = UDim2.new(1,0,0,22),
                        BackgroundTransparency = 1,
                        BackgroundColor3 = accentCol:Lerp(T.BG,.7),
                        Text = tostring(item),
                        TextColor3 = T.TXT,
                        TextSize = 11,
                        LayoutOrder = i,
                        ZIndex = 152,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    })
                    cr(3,ib)
                    pad(ib, 0, 8)
                    trackConn(ib.MouseEnter:Connect(function()
                        tw(ib,{BackgroundTransparency=0},.1)
                    end))
                    trackConn(ib.MouseLeave:Connect(function()
                        tw(ib,{BackgroundTransparency=1},.1)
                    end))
                    trackConn(ib.MouseButton1Click:Connect(function()
                        cur = item
                        lbl2.Text = tostring(item)
                        closeDD()
                        if cb then cb(item) end
                    end))
                    table.insert(ddBtns, ib)
                end
            end

            buildList(items)

            trackConn(host.MouseEnter:Connect(function()
                tw(host,{BackgroundTransparency=0.05},.1)
            end))
            trackConn(host.MouseLeave:Connect(function()
                tw(host,{BackgroundTransparency=T.ROW_T},.1)
            end))
            trackConn(host.MouseButton1Click:Connect(function()
                if popup.Visible then closeDD(); return end
                local ap = host.AbsolutePosition
                local aw = host.AbsoluteSize.X
                local H  = math.min(#ddBtns*23+8, 160)
                popup.Size     = UDim2.new(0,aw,0,H)
                popup.Position = UDim2.new(0,ap.X,0,ap.Y+28)
                popup.Visible  = true
                popup.BackgroundTransparency = 1
                tw(popup,{BackgroundTransparency=0.05},0.15)
                arr.Text = "▴"
            end))
            trackConn(SG.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then
                    task.wait()
                    if popup.Visible then closeDD() end
                end
            end))

            return {
                GetValue  = function() return cur end,
                SetValues = function(v)
                    buildList(v)
                    if #v>0 then cur=v[1]; lbl2.Text=tostring(v[1]) end
                end,
            }
        end

        function api.StatusBar(lines)
            rowN = rowN + 1
            local wrap = mkFrame(scroll, {
                Size = UDim2.new(1,0,0,14+(lines or 1)*14),
                BackgroundTransparency = 1,
                LayoutOrder = rowN,
            })
            pad(wrap, 3, 8)
            local f = mkFrame(wrap, {
                Size = UDim2.new(1,0,1,0),
                BackgroundColor3 = T.SECT,
                BackgroundTransparency = T.SECT_T,
            })
            cr(T.CORNER, f)
            pad(f, 3, 7)
            local l = mkLabel(f, {
                Size = UDim2.new(1,0,1,0),
                Text = "",
                TextColor3 = T.MUT,
                TextSize = 10,
                TextWrapped = true,
                TextYAlignment = Enum.TextYAlignment.Top,
            })
            return l
        end

        function api.ProgressBar()
            rowN = rowN + 1
            local wrap = mkFrame(scroll, {
                Size = UDim2.new(1,0,0,6),
                BackgroundTransparency = 1,
                LayoutOrder = rowN,
            })
            pad(wrap, 1, 8)
            local bg = mkFrame(wrap, {
                Size = UDim2.new(1,0,1,0),
                BackgroundColor3 = T.ROW,
                BackgroundTransparency = 0.2,
            })
            cr(3, bg)
            local fill = mkFrame(bg, {
                Size = UDim2.new(0,0,1,0),
                BackgroundColor3 = accentCol,
            })
            cr(3, fill)
            return fill
        end

        function api.FileList()
            rowN = rowN + 1
            local f = mkFrame(scroll, {
                Size = UDim2.new(1,0,0,0),
                BackgroundTransparency = 1,
                LayoutOrder = rowN,
            })
            local fl = Instance.new("UIListLayout", f)
            fl.Padding   = UDim.new(0,0)
            fl.SortOrder = Enum.SortOrder.LayoutOrder
            fl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                f.Size = UDim2.new(1,0,0,fl.AbsoluteContentSize.Y)
            end)
            local entries    = {}
            local selRow     = nil
            local onSelCb    = nil

            local function rebuild(list)
                for _,e in ipairs(entries) do e:Destroy() end
                entries = {}; selRow = nil
                for i,item in ipairs(list) do
                    local row = mkBtn(f, {
                        Size = UDim2.new(1,0,0,22),
                        BackgroundColor3 = accentCol,
                        BackgroundTransparency = 0.82,
                        Text = tostring(item),
                        TextColor3 = T.TXT,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        LayoutOrder = i,
                    })
                    cr(3, row)
                    pad(row, 0, 14)
                    trackConn(row.MouseEnter:Connect(function()
                        if selRow~=row then tw(row,{BackgroundTransparency=0.6},.1) end
                    end))
                    trackConn(row.MouseLeave:Connect(function()
                        if selRow~=row then tw(row,{BackgroundTransparency=0.82},.1) end
                    end))
                    trackConn(row.MouseButton1Click:Connect(function()
                        if selRow then tw(selRow,{BackgroundTransparency=0.82},.1) end
                        selRow = row
                        tw(row,{BackgroundTransparency=0.35},.1)
                        if onSelCb then
                            onSelCb(item:match("^(.-)%s*$") or item)
                        end
                    end))
                    table.insert(entries, row)
                end
            end

            return {
                SetValues  = rebuild,
                OnSelected = function(cb) onSelCb = cb end,
            }
        end

        function api.NoteText(text)
            rowN = rowN + 1
            local wrap = mkFrame(scroll, {
                Size = UDim2.new(1,0,0,0),
                BackgroundTransparency = 1,
                LayoutOrder = rowN,
                AutomaticSize = Enum.AutomaticSize.Y,
            })
            pad(wrap, 4, 8)
            local l = mkLabel(wrap, {
                Size = UDim2.new(1,0,0,0),
                Text = tostring(text),
                TextColor3 = T.MUT,
                TextSize = 10,
                TextWrapped = true,
                AutomaticSize = Enum.AutomaticSize.Y,
            })
            return l
        end

        -- ── Section header row (с анимацией slide up) ────────
        function api.SectionHeader(sTitle, accentOverride)
            local ac = accentOverride or accentCol
            rowN = rowN + 1
            local f = mkFrame(scroll, {
                Size = UDim2.new(1,0,0,22),
                BackgroundColor3 = T.SECT,
                BackgroundTransparency = T.SECT_T,
                LayoutOrder = rowN,
            })
            cr(T.CORNER, f)

            local bar = mkFrame(f, {
                Size = UDim2.new(0,2,0.7,0),
                Position = UDim2.new(0,0,0.15,0),
                BackgroundColor3 = ac,
            })
            cr(1,bar)

            local sep1 = mkFrame(f, {
                Size = UDim2.new(0.25,0,0,1),
                Position = UDim2.new(0,8,0.5,0),
                BackgroundColor3 = ac,
                BackgroundTransparency = 0.5,
            })
            mkLabel(f, {
                Size = UDim2.new(1,-80,1,0),
                Position = UDim2.new(0,12,0,0),
                Text = "— "..tostring(sTitle),
                TextColor3 = ac,
                Font = Enum.Font.GothamBold,
                TextSize = 10,
            })
            local sep2 = mkFrame(f, {
                Size = UDim2.new(0.25,0,0,1),
                Position = UDim2.new(1,-50,0.5,0),
                BackgroundColor3 = ac,
                BackgroundTransparency = 0.5,
            })

            -- Slide up анимация при появлении
            f.Position = UDim2.new(0,0,0,8)
            tw(f, {Position=UDim2.new(0,0,0,0)}, 0.25, Enum.EasingStyle.Back)
        end

        return api
    end

    -- ── AddTab ────────────────────────────────────────────────
    local WIN_OBJ = {}
    WIN_OBJ.WIN  = WIN
    WIN_OBJ.SG   = SG
    WIN_OBJ.Tabs = tabs

    function WIN_OBJ.AddTab(tabName, tabLabel, tabOrder)
        tabCount = tabCount + 1
        local btn = mkBtn(TABBAR, {
            BackgroundColor3 = T.HDR,
            BackgroundTransparency = 1,
            Text = tabLabel or tabName,
            TextColor3 = T.MUT,
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            LayoutOrder = tabOrder or tabCount,
        })

        -- Underline
        local ul = mkFrame(btn, {
            Size = UDim2.new(1,0,0,2),
            Position = UDim2.new(0,0,1,-2),
            BackgroundColor3 = accent,
            BackgroundTransparency = 1,
        })

        local scr = makeScroll(CONTENT)
        tabs[tabName] = {btn=btn, scroll=scr, ul=ul}

        -- Пересчёт ширины
        local function recalcWidths()
            local cnt = 0
            for _ in pairs(tabs) do cnt=cnt+1 end
            local bw = math.floor(width/cnt)
            for _,t in pairs(tabs) do
                t.btn.Size = UDim2.new(0,bw,1,0)
            end
        end
        recalcWidths()

        trackConn(btn.MouseEnter:Connect(function()
            if activeTab~=tabName then
                tw(btn,{TextColor3=T.TXT:Lerp(T.MUT,0.3),
                    BackgroundTransparency=0.85},.1)
            end
        end))
        trackConn(btn.MouseLeave:Connect(function()
            if activeTab~=tabName then
                tw(btn,{TextColor3=T.MUT,BackgroundTransparency=1},.1)
            end
        end))
        trackConn(btn.MouseButton1Click:Connect(function()
            switchTab(tabName)
        end))

        if not activeTab then switchTab(tabName) end

        -- Возвращаем Section factory для этого таба
        local sapi = makeSectionAPI(scr, accent)

        -- Обёртка Section с заголовком
        local tabAPI = {}
        function tabAPI.Section(sTitle, accentOverride)
            sapi.SectionHeader(sTitle, accentOverride)
            sapi.Space(2)
            return sapi
        end
        -- Прямой доступ к sapi
        for k,v in pairs(sapi) do
            if not tabAPI[k] then tabAPI[k]=v end
        end

        WIN_OBJ.Tabs = tabs
        return tabAPI
    end

    function WIN_OBJ.AddHeaderButton(icon, col, cb)
        local b = makeHdrBtn(icon, col)
        if cb then trackConn(b.MouseButton1Click:Connect(cb)) end
        return b
    end

    function WIN_OBJ.SwitchTab(name)
        if tabs[name] then switchTab(name) end
    end

    function WIN_OBJ.Destroy()
        SG:Destroy()
    end

    return WIN_OBJ
end

return LordHubLib
