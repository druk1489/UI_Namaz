if _G.LordHubUnload then
    pcall(_G.LordHubUnload)
    task.wait(0.1)
end

local LordHubLib = {}
_G.LordHubActive = true

local connections = {}
local blurEffect  = nil

local function trackConn(c)
    table.insert(connections, c)
    return c
end

local function unload()
    _G.LordHubActive = false
    for _,c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    connections = {}
    if blurEffect then
        game:GetService("TweenService"):Create(
            blurEffect, TweenInfo.new(0.3),
            {Size=0}
        ):Play()
        task.delay(0.35, function()
            pcall(function() blurEffect:Destroy() end)
        end)
    end
    local PGui = game:GetService("Players").LocalPlayer
        :WaitForChild("PlayerGui")
    for _,gui in ipairs(PGui:GetChildren()) do
        if gui.Name:find("LordHub") then
            gui:Destroy()
        end
    end
    local bb = workspace:FindFirstChild("LordHubBB")
    if bb then bb:Destroy() end
    local mh = PGui:FindFirstChild("LordHubMove")
    if mh then mh:Destroy() end
    local rh = PGui:FindFirstChild("LordHubRot")
    if rh then rh:Destroy() end
end

_G.LordHubUnload = unload
LordHubLib.Unload = unload

-- ── Services ─────────────────────────────────────────────────
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local LP           = Players.LocalPlayer
local PGui         = LP:WaitForChild("PlayerGui")

-- ── Blur Effect (iPhone glass) ────────────────────────────────
local cam = workspace.CurrentCamera
blurEffect = Instance.new("BlurEffect", cam)
blurEffect.Size = 0
TweenService:Create(blurEffect, TweenInfo.new(0.5), {Size=12}):Play()

-- ── Тема ─────────────────────────────────────────────────────
local T = {
    -- Стекло
    GLASS       = Color3.fromRGB(255, 255, 255),
    GLASS_T     = 0.82,        -- почти прозрачный
    GLASS_DARK  = Color3.fromRGB(10, 14, 20),
    GLASS_DARK_T= 0.55,

    -- Frosted glass слои
    LAYER1      = Color3.fromRGB(180, 200, 230),
    LAYER1_T    = 0.88,
    LAYER2      = Color3.fromRGB(140, 165, 210),
    LAYER2_T    = 0.82,
    LAYER3      = Color3.fromRGB(20, 28, 42),
    LAYER3_T    = 0.45,

    -- Header (тёмное стекло)
    HDR         = Color3.fromRGB(8, 12, 20),
    HDR_T       = 0.35,

    -- Секции
    SECT        = Color3.fromRGB(255, 255, 255),
    SECT_T      = 0.90,
    SECT_DARK   = Color3.fromRGB(15, 20, 32),
    SECT_DARK_T = 0.50,

    -- Кнопки
    BTN         = Color3.fromRGB(255, 255, 255),
    BTN_T       = 0.75,
    BTN_DARK    = Color3.fromRGB(20, 30, 50),
    BTN_DARK_T  = 0.40,

    -- Input
    INPUT       = Color3.fromRGB(255, 255, 255),
    INPUT_T     = 0.80,

    -- Accent (iPhone blue)
    ACCENT      = Color3.fromRGB(10, 132, 255),
    ACCENT2     = Color3.fromRGB(48, 209, 88),  -- green
    ACCENT3     = Color3.fromRGB(255, 159, 10), -- orange

    -- Text
    TXT         = Color3.fromRGB(255, 255, 255),
    TXT_DARK    = Color3.fromRGB(20, 20, 20),
    MUT         = Color3.fromRGB(180, 190, 210),
    MUT_DARK    = Color3.fromRGB(100, 110, 130),

    -- System
    SEP         = Color3.fromRGB(255, 255, 255),
    SEP_T       = 0.80,
    GREEN       = Color3.fromRGB(48, 209, 88),
    RED         = Color3.fromRGB(255, 69, 58),
    YEL         = Color3.fromRGB(255, 214, 10),
    STAR        = Color3.fromRGB(255, 200, 40),

    CORNER      = 12,   -- iPhone-like corners
    CORNER_SM   = 8,
    CORNER_XS   = 6,
}
LordHubLib.Theme = T

-- ── Утилиты ──────────────────────────────────────────────────
local function tw(obj, props, dur, style, dir)
    local t = TweenService:Create(obj,
        TweenInfo.new(
            dur   or 0.2,
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

-- Создаёт glass frame с несколькими слоями
local function glassFrame(parent, props)
    local f = Instance.new("Frame", parent)
    f.BorderSizePixel = 0
    f.BackgroundColor3 = T.GLASS_DARK
    f.BackgroundTransparency = T.GLASS_DARK_T
    for k,v in pairs(props or {}) do
        pcall(function() f[k]=v end)
    end

    -- Световой слой сверху (имитация отражения)
    local shine = Instance.new("Frame", f)
    shine.Size = UDim2.new(1,0,0.45,0)
    shine.Position = UDim2.new(0,0,0,0)
    shine.BackgroundColor3 = T.GLASS
    shine.BackgroundTransparency = 0.93
    shine.BorderSizePixel = 0
    shine.ZIndex = (f.ZIndex or 1) + 1

    -- Gradient на shine
    local grad = Instance.new("UIGradient", shine)
    grad.Rotation = 90
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })

    -- Тонкая рамка (стекло)
    local stroke = Instance.new("UIStroke", f)
    stroke.Color = T.GLASS
    stroke.Thickness = 1
    stroke.Transparency = 0.6
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    return f, stroke, shine
end

local function mkLabel(parent, props)
    local l = Instance.new("TextLabel", parent)
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 11
    l.TextColor3 = T.TXT
    l.TextXAlignment = Enum.TextXAlignment.Left
    for k,v in pairs(props or {}) do
        pcall(function() l[k]=v end)
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
    b.BackgroundTransparency = 1
    for k,v in pairs(props or {}) do
        pcall(function() b[k]=v end)
    end
    return b
end

-- ── Notifications ─────────────────────────────────────────────
local notifSG = Instance.new("ScreenGui", PGui)
notifSG.Name           = "LordHub_Notif"
notifSG.ResetOnSpawn   = false
notifSG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
notifSG.DisplayOrder   = 999

local notifHolder = Instance.new("Frame", notifSG)
notifHolder.Size = UDim2.new(0,280,0,500)
notifHolder.Position = UDim2.new(1,-288,0,12)
notifHolder.BackgroundTransparency = 1
notifHolder.BorderSizePixel = 0

local notifList = Instance.new("UIListLayout", notifHolder)
notifList.Padding = UDim.new(0,6)
notifList.VerticalAlignment = Enum.VerticalAlignment.Top
notifList.SortOrder = Enum.SortOrder.LayoutOrder
local notifN = 0

function LordHubLib.Notify(title, msg, kind, duration)
    notifN   = notifN + 1
    duration = duration or 4
    local acc = kind=="error"   and T.RED
             or kind=="success" and T.GREEN
             or kind=="warn"    and T.YEL
             or T.ACCENT

    -- Glass notification frame
    local f,fStroke = glassFrame(notifHolder, {
        Size = UDim2.new(1,0,0,60),
        BackgroundColor3 = T.GLASS_DARK,
        BackgroundTransparency = 0.25,
        ClipsDescendants = true,
        LayoutOrder = notifN,
        ZIndex = 200,
    })
    cr(T.CORNER, f)
    fStroke.Color = acc
    fStroke.Transparency = 0.3

    -- Accent line left
    local bar = Instance.new("Frame", f)
    bar.Size = UDim2.new(0,3,0.7,0)
    bar.Position = UDim2.new(0,0,0.15,0)
    bar.BackgroundColor3 = acc
    bar.BorderSizePixel = 0
    cr(2,bar)

    -- Progress bar
    local prog = Instance.new("Frame", f)
    prog.Size = UDim2.new(1,0,0,2)
    prog.Position = UDim2.new(0,0,1,-2)
    prog.BackgroundColor3 = acc
    prog.BackgroundTransparency = 0.2
    prog.BorderSizePixel = 0

    -- Icon dot
    local dot = Instance.new("Frame", f)
    dot.Size = UDim2.new(0,6,0,6)
    dot.Position = UDim2.new(0,10,0,10)
    dot.BackgroundColor3 = acc
    dot.BorderSizePixel = 0
    cr(3,dot)

    mkLabel(f, {
        Size = UDim2.new(1,-20,0,18),
        Position = UDim2.new(0,22,0,6),
        Text = tostring(title),
        TextColor3 = acc,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        ZIndex = 201,
    })
    mkLabel(f, {
        Size = UDim2.new(1,-20,0,28),
        Position = UDim2.new(0,22,0,26),
        Text = tostring(msg),
        TextColor3 = T.MUT,
        TextSize = 10,
        TextWrapped = true,
        ZIndex = 201,
    })

    -- Анимация входа
    f.Position = UDim2.new(0,300,0,0)
    f.BackgroundTransparency = 1
    tw(f, {
        Position = UDim2.new(0,0,0,0),
        BackgroundTransparency = 0.25,
    }, 0.35, Enum.EasingStyle.Back)
    tw(prog, {Size=UDim2.new(0,0,0,2)}, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        tw(f, {
            Position = UDim2.new(0,300,0,0),
            BackgroundTransparency = 1,
        }, 0.25)
        task.wait(0.28)
        f:Destroy()
    end)
end

-- ============================================================
--   WINDOW
-- ============================================================
function LordHubLib.NewWindow(cfg)
    cfg    = cfg or {}
    local title  = cfg.Title    or "Lord Hub"
    local width  = cfg.Width    or 240
    local height = cfg.Height   or 520
    local accent = cfg.Accent   or T.ACCENT
    local pos    = cfg.Position or UDim2.new(0,40,0,60)

    -- ── ScreenGui ────────────────────────────────────────────
    local SG = Instance.new("ScreenGui", PGui)
    SG.Name            = cfg.Name or "LordHub_GUI"
    SG.ResetOnSpawn    = false
    SG.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    SG.DisplayOrder    = 100

    -- ── Main Glass Frame ─────────────────────────────────────
    local WIN, winStroke = glassFrame(SG, {
        Size = UDim2.new(0,width,0,height),
        Position = pos,
        BackgroundColor3 = T.GLASS_DARK,
        BackgroundTransparency = T.GLASS_DARK_T,
        ClipsDescendants = true,
    })
    cr(T.CORNER, WIN)
    winStroke.Color = accent
    winStroke.Transparency = 0.4

    -- Появление окна
    WIN.BackgroundTransparency = 1
    WIN.Position = UDim2.new(
        pos.X.Scale, pos.X.Offset,
        pos.Y.Scale, pos.Y.Offset - 20
    )
    tw(WIN, {
        BackgroundTransparency = T.GLASS_DARK_T,
        Position = pos,
    }, 0.4, Enum.EasingStyle.Back)

    -- ── Header (тёмное стекло) ────────────────────────────────
    local HDR, hdrStroke = glassFrame(WIN, {
        Size = UDim2.new(1,0,0,32),
        BackgroundColor3 = T.HDR,
        BackgroundTransparency = T.HDR_T,
        ZIndex = 5,
    })
    hdrStroke.Transparency = 0.7

    -- Header bottom border
    local hdrBorder = Instance.new("Frame", HDR)
    hdrBorder.Size = UDim2.new(1,0,0,1)
    hdrBorder.Position = UDim2.new(0,0,1,-1)
    hdrBorder.BackgroundColor3 = accent
    hdrBorder.BackgroundTransparency = 0.5
    hdrBorder.BorderSizePixel = 0

    -- Collapse btn
    local colBtn = mkBtn(HDR, {
        Size = UDim2.new(0,24,0,24),
        Position = UDim2.new(0,4,0.5,-12),
        Text = "▼",
        TextColor3 = T.MUT,
        TextSize = 10,
        ZIndex = 6,
    })

    -- Title
    mkLabel(HDR, {
        Size = UDim2.new(1,-90,1,0),
        Position = UDim2.new(0,28,0,0),
        Text = title,
        TextColor3 = T.TXT,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        ZIndex = 6,
    })

    -- Header right buttons
    local hdrRight = Instance.new("Frame", HDR)
    hdrRight.Size = UDim2.new(0,68,1,0)
    hdrRight.Position = UDim2.new(1,-70,0,0)
    hdrRight.BackgroundTransparency = 1
    hdrRight.BorderSizePixel = 0
    hdrRight.ZIndex = 6
    local hdrRL = Instance.new("UIListLayout", hdrRight)
    hdrRL.FillDirection = Enum.FillDirection.Horizontal
    hdrRL.HorizontalAlignment = Enum.HorizontalAlignment.Right
    hdrRL.VerticalAlignment = Enum.VerticalAlignment.Center
    hdrRL.Padding = UDim.new(0,3)

    local function makeHdrBtn(icon, col)
        local bg, bgS = glassFrame(hdrRight, {
            Size = UDim2.new(0,22,0,22),
            BackgroundColor3 = T.GLASS_DARK,
            BackgroundTransparency = 0.5,
            ZIndex = 7,
        })
        cr(T.CORNER_XS, bg)
        bgS.Transparency = 0.7

        local b = mkBtn(bg, {
            Size = UDim2.new(1,0,1,0),
            Text = icon,
            TextColor3 = col or T.MUT,
            TextSize = 13,
            ZIndex = 8,
        })
        trackConn(b.MouseEnter:Connect(function()
            tw(bg,{BackgroundTransparency=0.2},.1)
            tw(b,{TextColor3=T.TXT},.1)
        end))
        trackConn(b.MouseLeave:Connect(function()
            tw(bg,{BackgroundTransparency=0.5},.1)
            tw(b,{TextColor3=col or T.MUT},.1)
        end))
        return b
    end

    -- Collapse logic
    local collapsed = false
    local savedH    = height
    colBtn.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        if collapsed then
            savedH = WIN.AbsoluteSize.Y
            tw(WIN,{Size=UDim2.new(0,width,0,32)},0.25,Enum.EasingStyle.Quart)
            colBtn.Text = "▶"
        else
            tw(WIN,{Size=UDim2.new(0,width,0,savedH)},0.3,Enum.EasingStyle.Back)
            colBtn.Text = "▼"
        end
    end)

    -- ── Drag ─────────────────────────────────────────────────
    local dragging,dStart,wStart = false,nil,nil
    trackConn(HDR.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dStart=i.Position; wStart=WIN.Position
            tw(WIN,{BackgroundTransparency=T.GLASS_DARK_T+0.1},.1)
        end
    end))
    trackConn(HDR.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=false
            tw(WIN,{BackgroundTransparency=T.GLASS_DARK_T},.1)
        end
    end))
    trackConn(UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-dStart
            WIN.Position=UDim2.new(
                wStart.X.Scale,wStart.X.Offset+d.X,
                wStart.Y.Scale,wStart.Y.Offset+d.Y
            )
        end
    end))

    -- ── Tab Bar ──────────────────────────────────────────────
    local TABBAR, tabBarStroke = glassFrame(WIN, {
        Size = UDim2.new(1,0,0,28),
        Position = UDim2.new(0,0,0,32),
        BackgroundColor3 = T.HDR,
        BackgroundTransparency = 0.4,
    })
    tabBarStroke.Transparency = 0.8

    local tabLayout = Instance.new("UIListLayout", TABBAR)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    tabLayout.Padding       = UDim.new(0,0)

    -- Tab bottom accent line
    local tabLine = Instance.new("Frame", WIN)
    tabLine.Size = UDim2.new(1,0,0,1)
    tabLine.Position = UDim2.new(0,0,0,60)
    tabLine.BackgroundColor3 = accent
    tabLine.BackgroundTransparency = 0.5
    tabLine.BorderSizePixel = 0

    -- ── Content ───────────────────────────────────────────────
    local CONTENT = Instance.new("Frame", WIN)
    CONTENT.Size = UDim2.new(1,0,1,-61)
    CONTENT.Position = UDim2.new(0,0,0,61)
    CONTENT.BackgroundTransparency = 1
    CONTENT.BorderSizePixel = 0
    CONTENT.ClipsDescendants = true

    -- ── Tabs система ─────────────────────────────────────────
    local tabs      = {}
    local activeTab = nil
    local tabCount  = 0

    local function makeScroll(parent)
        local s = Instance.new("ScrollingFrame", parent)
        s.Size = UDim2.new(1,0,1,0)
        s.BackgroundTransparency = 1
        s.BorderSizePixel = 0
        s.ScrollBarThickness = 2
        s.ScrollBarImageColor3 = accent
        s.CanvasSize = UDim2.new(0,0,0,0)
        s.Visible = false
        s.ScrollingDirection = Enum.ScrollingDirection.Y
        local sl = Instance.new("UIListLayout", s)
        sl.Padding = UDim.new(0,0)
        sl.SortOrder = Enum.SortOrder.LayoutOrder
        sl.HorizontalAlignment = Enum.HorizontalAlignment.Center
        sl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            s.CanvasSize = UDim2.new(0,0,0,sl.AbsoluteContentSize.Y+8)
        end)
        return s
    end

    local function switchTab(name)
        if activeTab==name then return end
        if activeTab and tabs[activeTab] then
            local old = tabs[activeTab]
            old.scroll.Visible = false
            tw(old.btn,{TextColor3=T.MUT:Lerp(T.TXT,0.2)},.15)
            tw(old.ul,{BackgroundTransparency=1},.15)
            tw(old.bg,{BackgroundTransparency=1},.15)
        end
        activeTab = name
        local new = tabs[name]
        new.scroll.Visible = true
        tw(new.btn,{TextColor3=T.TXT},.15)
        tw(new.ul,{BackgroundTransparency=0.3},.15)
        tw(new.bg,{BackgroundTransparency=0.8},.15)
    end

    -- ── Section API factory ───────────────────────────────────
    local function makeSectionAPI(scroll, ac)
        ac = ac or accent
        local rowN = 0
        local api  = {}

        function api.Space(h)
            rowN=rowN+1
            local f=Instance.new("Frame",scroll)
            f.Size=UDim2.new(1,0,0,h or 4)
            f.BackgroundTransparency=1
            f.BorderSizePixel=0
            f.LayoutOrder=rowN
        end

        function api.Separator()
            rowN=rowN+1
            local wrap=Instance.new("Frame",scroll)
            wrap.Size=UDim2.new(1,0,0,9)
            wrap.BackgroundTransparency=1
            wrap.BorderSizePixel=0
            wrap.LayoutOrder=rowN
            local f=Instance.new("Frame",wrap)
            f.Size=UDim2.new(1,-16,0,1)
            f.Position=UDim2.new(0,8,0.5,0)
            f.BackgroundColor3=T.SEP
            f.BackgroundTransparency=T.SEP_T
            f.BorderSizePixel=0
        end

        function api.SectionHeader(sTitle, ac2)
            ac2=ac2 or ac
            rowN=rowN+1
            -- Glass section header
            local wrap=Instance.new("Frame",scroll)
            wrap.Size=UDim2.new(1,0,0,24)
            wrap.BackgroundTransparency=1
            wrap.BorderSizePixel=0
            wrap.LayoutOrder=rowN
            pad(wrap,0,8)

            local f,fS=glassFrame(wrap,{
                Size=UDim2.new(1,0,1,0),
                BackgroundColor3=T.GLASS_DARK,
                BackgroundTransparency=0.65,
            })
            cr(T.CORNER_XS,f)
            fS.Color=ac2
            fS.Transparency=0.6

            mkLabel(f,{
                Size=UDim2.new(1,-20,1,0),
                Position=UDim2.new(0,10,0,0),
                Text="— "..tostring(sTitle),
                TextColor3=ac2,
                Font=Enum.Font.GothamBold,
                TextSize=10,
            })

            -- Slide up анимация
            wrap.Position=UDim2.new(0,0,0,10)
            tw(wrap,{Position=UDim2.new(0,0,0,0)},0.3,Enum.EasingStyle.Back)
        end

        function api.Label(text, col, indent)
            rowN=rowN+1
            local wrap=Instance.new("Frame",scroll)
            wrap.Size=UDim2.new(1,0,0,18)
            wrap.BackgroundTransparency=1
            wrap.BorderSizePixel=0
            wrap.LayoutOrder=rowN
            local l=mkLabel(wrap,{
                Size=UDim2.new(1,-(indent or 8),1,0),
                Position=UDim2.new(0,indent or 8,0,0),
                Text=tostring(text),
                TextColor3=col or T.MUT,
                TextWrapped=true,
            })
            return l
        end

        function api.Button(text, col, cb)
            rowN=rowN+1
            col=col or T.BTN_DARK
            local wrap=Instance.new("Frame",scroll)
            wrap.Size=UDim2.new(1,0,0,32)
            wrap.BackgroundTransparency=1
            wrap.LayoutOrder=rowN
            pad(wrap,3,8)

            -- Glass button
            local f,fS=glassFrame(wrap,{
                Size=UDim2.new(1,0,1,0),
                BackgroundColor3=col,
                BackgroundTransparency=0.45,
            })
            cr(T.CORNER_SM,f)
            fS.Color=T.GLASS
            fS.Transparency=0.7

            local b=mkBtn(f,{
                Size=UDim2.new(1,0,1,0),
                Text=tostring(text),
                TextColor3=T.TXT,
                Font=Enum.Font.GothamBold,
                TextSize=11,
            })

            trackConn(b.MouseEnter:Connect(function()
                tw(f,{BackgroundTransparency=0.2},.12)
                tw(fS,{Transparency=0.4},.12)
            end))
            trackConn(b.MouseLeave:Connect(function()
                tw(f,{BackgroundTransparency=0.45},.12)
                tw(fS,{Transparency=0.7},.12)
            end))
            trackConn(b.MouseButton1Down:Connect(function()
                tw(f,{BackgroundTransparency=0.6,
                    Size=UDim2.new(0.97,0,0.88,0)},.08)
            end))
            trackConn(b.MouseButton1Up:Connect(function()
                tw(f,{BackgroundTransparency=0.45,
                    Size=UDim2.new(1,0,1,0)},.15,Enum.EasingStyle.Back)
            end))
            if cb then trackConn(b.MouseButton1Click:Connect(cb)) end
            return b
        end

        function api.Button2(t1,c1,t2,c2,cb1,cb2)
            rowN=rowN+1
            local wrap=Instance.new("Frame",scroll)
            wrap.Size=UDim2.new(1,0,0,32)
            wrap.BackgroundTransparency=1
            wrap.LayoutOrder=rowN
            pad(wrap,3,8)
            local inner=Instance.new("Frame",wrap)
            inner.Size=UDim2.new(1,0,1,0)
            inner.BackgroundTransparency=1
            local ul=Instance.new("UIListLayout",inner)
            ul.FillDirection=Enum.FillDirection.Horizontal
            ul.Padding=UDim.new(0,6)

            local function mkB(t,col,cb)
                col=col or T.BTN_DARK
                local f,fS=glassFrame(inner,{
                    Size=UDim2.new(0.5,-3,1,0),
                    BackgroundColor3=col,
                    BackgroundTransparency=0.45,
                })
                cr(T.CORNER_SM,f)
                fS.Transparency=0.7
                local b=mkBtn(f,{
                    Size=UDim2.new(1,0,1,0),
                    Text=tostring(t),
                    TextColor3=T.TXT,
                    TextSize=10,
                })
                trackConn(b.MouseEnter:Connect(function()
                    tw(f,{BackgroundTransparency=0.2},.12)
                end))
                trackConn(b.MouseLeave:Connect(function()
                    tw(f,{BackgroundTransparency=0.45},.12)
                end))
                trackConn(b.MouseButton1Down:Connect(function()
                    tw(f,{BackgroundTransparency=0.6,
                        Size=UDim2.new(0.47,-3,0.88,0)},.08)
                end))
                trackConn(b.MouseButton1Up:Connect(function()
                    tw(f,{BackgroundTransparency=0.45,
                        Size=UDim2.new(0.5,-3,1,0)},.15,Enum.EasingStyle.Back)
                end))
                if cb then trackConn(b.MouseButton1Click:Connect(cb)) end
                return b
            end
            return mkB(t1,c1,cb1), mkB(t2,c2,cb2)
        end

        function api.Input(ph, numeric, default, cb)
            rowN=rowN+1
            local wrap=Instance.new("Frame",scroll)
            wrap.Size=UDim2.new(1,0,0,30)
            wrap.BackgroundTransparency=1
            wrap.LayoutOrder=rowN
            pad(wrap,3,8)

            local f,fS=glassFrame(wrap,{
                Size=UDim2.new(1,0,1,0),
                BackgroundColor3=T.INPUT,
                BackgroundTransparency=0.82,
            })
            cr(T.CORNER_SM,f)
            fS.Transparency=0.65

            pad(f,0,8)
            local b=Instance.new("TextBox",f)
            b.Size=UDim2.new(1,0,1,0)
            b.BackgroundTransparency=1
            b.PlaceholderText=tostring(ph or "")
            b.PlaceholderColor3=T.MUT
            b.Text=tostring(default or "")
            b.TextColor3=T.TXT
            b.Font=Enum.Font.GothamMedium
            b.TextSize=11
            b.ClearTextOnFocus=false
            b.BorderSizePixel=0

            if numeric then
                trackConn(b:GetPropertyChangedSignal("Text"):Connect(function()
                    local v=b.Text:gsub("[^%d%.%-]","")
                    if v~=b.Text then b.Text=v end
                end))
            end
            trackConn(b.Focused:Connect(function()
                tw(f,{BackgroundTransparency=0.6},.15)
                tw(fS,{Transparency=0.2,Color=ac},.15)
            end))
            trackConn(b.FocusLost:Connect(function()
                tw(f,{BackgroundTransparency=0.82},.15)
                tw(fS,{Transparency=0.65,Color=T.GLASS},.15)
                if cb then cb(b.Text) end
            end))
            return b
        end

        function api.Toggle(labelText, default, cb)
            default=default==true
            rowN=rowN+1
            local wrap=Instance.new("Frame",scroll)
            wrap.Size=UDim2.new(1,0,0,28)
            wrap.BackgroundTransparency=1
            wrap.BorderSizePixel=0
            wrap.LayoutOrder=rowN
            pad(wrap,0,8)

            -- Glass row
            local f,fS=glassFrame(wrap,{
                Size=UDim2.new(1,0,1,0),
                BackgroundColor3=T.GLASS_DARK,
                BackgroundTransparency=0.65,
            })
            cr(T.CORNER_SM,f)
            fS.Transparency=0.75

            mkLabel(f,{
                Size=UDim2.new(1,-52,1,0),
                Position=UDim2.new(0,10,0,0),
                Text=tostring(labelText),
                TextColor3=T.TXT,
            })

            -- Track
            local track,trackS=glassFrame(f,{
                Size=UDim2.new(0,36,0,20),
                Position=UDim2.new(1,-44,0.5,-10),
                BackgroundColor3=default and ac or T.GLASS_DARK,
                BackgroundTransparency=default and 0.1 or 0.5,
            })
            cr(10,track)
            trackS.Transparency=0.5

            -- Knob
            local knob=Instance.new("Frame",track)
            knob.Size=UDim2.new(0,16,0,16)
            knob.Position=default
                and UDim2.new(1,-18,0.5,-8)
                or  UDim2.new(0,2,0.5,-8)
            knob.BackgroundColor3=T.TXT
            knob.BorderSizePixel=0
            cr(8,knob)
            -- Knob shadow
            local ks=Instance.new("UIStroke",knob)
            ks.Color=Color3.new(0,0,0)
            ks.Transparency=0.6
            ks.Thickness=1

            local on=default
            local clickBtn=mkBtn(f,{
                Size=UDim2.new(1,0,1,0),
                Text="",
            })
            trackConn(clickBtn.MouseEnter:Connect(function()
                tw(f,{BackgroundTransparency=0.45},.1)
            end))
            trackConn(clickBtn.MouseLeave:Connect(function()
                tw(f,{BackgroundTransparency=0.65},.1)
            end))
            trackConn(clickBtn.MouseButton1Click:Connect(function()
                on=not on
                if on then
                    tw(track,{BackgroundColor3=ac,BackgroundTransparency=0.1},.2)
                    tw(knob,{Position=UDim2.new(1,-18,0.5,-8)},.2,Enum.EasingStyle.Back)
                else
                    tw(track,{BackgroundColor3=T.GLASS_DARK,BackgroundTransparency=0.5},.2)
                    tw(knob,{Position=UDim2.new(0,2,0.5,-8)},.2,Enum.EasingStyle.Back)
                end
                if cb then pcall(cb,on) end
            end))
            return {
                GetValue=function() return on end,
                SetValue=function(v)
                    on=v==true
                    track.BackgroundColor3=on and ac or T.GLASS_DARK
                    track.BackgroundTransparency=on and 0.1 or 0.5
                    knob.Position=on
                        and UDim2.new(1,-18,0.5,-8)
                        or  UDim2.new(0,2,0.5,-8)
                end,
            }
        end

        function api.Dropdown(items, cb)
            rowN=rowN+1
            local cur=items[1] or "Select"
            local wrap=Instance.new("Frame",scroll)
            wrap.Size=UDim2.new(1,0,0,30)
            wrap.BackgroundTransparency=1
            wrap.LayoutOrder=rowN
            pad(wrap,3,8)

            local host,hostS=glassFrame(wrap,{
                Size=UDim2.new(1,0,1,0),
                BackgroundColor3=T.INPUT,
                BackgroundTransparency=0.82,
            })
            cr(T.CORNER_SM,host)

            local lbl2=mkLabel(host,{
                Size=UDim2.new(1,-28,1,0),
                Position=UDim2.new(0,10,0,0),
                Text=tostring(cur),
                TextColor3=T.TXT,
            })
            local arr=mkLabel(host,{
                Size=UDim2.new(0,22,1,0),
                Position=UDim2.new(1,-24,0,0),
                Text="▾",
                TextColor3=T.MUT,
                Font=Enum.Font.GothamBold,
                TextXAlignment=Enum.TextXAlignment.Center,
            })

            -- Popup (glass)
            local popup,popupS=glassFrame(SG,{
                BackgroundColor3=T.GLASS_DARK,
                BackgroundTransparency=0.15,
                ZIndex=150,
                Visible=false,
            })
            cr(T.CORNER_SM,popup)
            popupS.Color=ac
            popupS.Transparency=0.5

            local psl=Instance.new("ScrollingFrame",popup)
            psl.Size=UDim2.new(1,0,1,0)
            psl.BackgroundTransparency=1
            psl.BorderSizePixel=0
            psl.ScrollBarThickness=2
            psl.ScrollBarImageColor3=ac
            psl.ZIndex=151
            psl.CanvasSize=UDim2.new(0,0,0,0)
            local psll=Instance.new("UIListLayout",psl)
            psll.Padding=UDim.new(0,2)
            psll.SortOrder=Enum.SortOrder.LayoutOrder
            pad(psl,4,5)
            psll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                psl.CanvasSize=UDim2.new(0,0,0,psll.AbsoluteContentSize.Y+10)
            end)

            local ddBtns={}
            local function closeDD()
                tw(popup,{BackgroundTransparency=1},0.15)
                task.delay(0.15,function()
                    popup.Visible=false
                    popup.BackgroundTransparency=0.15
                end)
                arr.Text="▾"
            end

            local function buildList(newItems)
                for _,b in ipairs(ddBtns) do b:Destroy() end
                ddBtns={}
                for i,item in ipairs(newItems) do
                    local ib,ibS=glassFrame(psl,{
                        Size=UDim2.new(1,0,0,24),
                        BackgroundColor3=T.GLASS,
                        BackgroundTransparency=0.92,
                        ZIndex=152,
                        LayoutOrder=i,
                    })
                    cr(T.CORNER_XS,ib)
                    ibS.Transparency=0.85

                    local ibb=mkBtn(ib,{
                        Size=UDim2.new(1,0,1,0),
                        Text=tostring(item),
                        TextColor3=T.TXT,
                        TextSize=11,
                        ZIndex=153,
                        TextXAlignment=Enum.TextXAlignment.Left,
                    })
                    pad(ibb,0,8)
                    trackConn(ibb.MouseEnter:Connect(function()
                        tw(ib,{BackgroundTransparency=0.65},.1)
                        tw(ibS,{Transparency=0.4},.1)
                    end))
                    trackConn(ibb.MouseLeave:Connect(function()
                        tw(ib,{BackgroundTransparency=0.92},.1)
                        tw(ibS,{Transparency=0.85},.1)
                    end))
                    trackConn(ibb.MouseButton1Click:Connect(function()
                        cur=item
                        lbl2.Text=tostring(item)
                        closeDD()
                        if cb then cb(item) end
                    end))
                    table.insert(ddBtns,ib)
                end
            end

            buildList(items)

            local hostBtn=mkBtn(host,{
                Size=UDim2.new(1,0,1,0),
                Text="",
            })
            trackConn(hostBtn.MouseEnter:Connect(function()
                tw(host,{BackgroundTransparency=0.6},.12)
            end))
            trackConn(hostBtn.MouseLeave:Connect(function()
                tw(host,{BackgroundTransparency=0.82},.12)
            end))
            trackConn(hostBtn.MouseButton1Click:Connect(function()
                if popup.Visible then closeDD(); return end
                local ap=host.AbsolutePosition
                local aw=host.AbsoluteSize.X
                local H=math.min(#ddBtns*26+12,180)
                popup.Size=UDim2.new(0,aw,0,H)
                popup.Position=UDim2.new(0,ap.X,0,ap.Y+32)
                popup.Visible=true
                popup.BackgroundTransparency=1
                tw(popup,{BackgroundTransparency=0.15},0.2,Enum.EasingStyle.Back)
                arr.Text="▴"
            end))
            trackConn(UIS.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then
                    task.wait()
                    if popup.Visible then closeDD() end
                end
            end))

            return {
                GetValue=function() return cur end,
                SetValues=function(v)
                    buildList(v)
                    if #v>0 then cur=v[1]; lbl2.Text=tostring(v[1]) end
                end,
            }
        end

        function api.StatusBar(lines)
            rowN=rowN+1
            local wrap=Instance.new("Frame",scroll)
            wrap.Size=UDim2.new(1,0,0,14+(lines or 1)*14)
            wrap.BackgroundTransparency=1
            wrap.LayoutOrder=rowN
            pad(wrap,3,8)
            local f,fS=glassFrame(wrap,{
                Size=UDim2.new(1,0,1,0),
                BackgroundColor3=T.GLASS_DARK,
                BackgroundTransparency=0.55,
            })
            cr(T.CORNER_SM,f)
            fS.Transparency=0.75
            pad(f,4,8)
            local l=mkLabel(f,{
                Size=UDim2.new(1,0,1,0),
                Text="",
                TextColor3=T.MUT,
                TextSize=10,
                TextWrapped=true,
                TextYAlignment=Enum.TextYAlignment.Top,
            })
            return l
        end

        function api.ProgressBar()
            rowN=rowN+1
            local wrap=Instance.new("Frame",scroll)
            wrap.Size=UDim2.new(1,0,0,8)
            wrap.BackgroundTransparency=1
            wrap.LayoutOrder=rowN
            pad(wrap,1,8)
            local bg,bgS=glassFrame(wrap,{
                Size=UDim2.new(1,0,1,0),
                BackgroundColor3=T.GLASS_DARK,
                BackgroundTransparency=0.45,
            })
            cr(4,bg)
            bgS.Transparency=0.8

            local fill=Instance.new("Frame",bg)
            fill.Size=UDim2.new(0,0,1,0)
            fill.BackgroundColor3=ac
            fill.BackgroundTransparency=0.1
            fill.BorderSizePixel=0
            cr(4,fill)

            -- Shimmer
            local shimmer=Instance.new("Frame",fill)
            shimmer.Size=UDim2.new(0,30,1,0)
            shimmer.BackgroundColor3=T.TXT
            shimmer.BackgroundTransparency=0.75
            shimmer.BorderSizePixel=0
            cr(4,shimmer)
            task.spawn(function()
                while shimmer.Parent do
                    shimmer.Position=UDim2.new(0,-30,0,0)
                    tw(shimmer,{Position=UDim2.new(1,0,0,0)},
                        1.2,Enum.EasingStyle.Linear)
                    task.wait(1.4)
                end
            end)
            return fill
        end

        function api.FileList()
            rowN=rowN+1
            local f=Instance.new("Frame",scroll)
            f.Size=UDim2.new(1,0,0,0)
            f.BackgroundTransparency=1
            f.BorderSizePixel=0
            f.LayoutOrder=rowN
            local fl=Instance.new("UIListLayout",f)
            fl.Padding=UDim.new(0,2)
            fl.SortOrder=Enum.SortOrder.LayoutOrder
            fl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                f.Size=UDim2.new(1,0,0,fl.AbsoluteContentSize.Y+4)
            end)
            local entries={}
            local selRow=nil
            local onSelCb=nil

            local function rebuild(list)
                for _,e in ipairs(entries) do e:Destroy() end
                entries={}; selRow=nil
                for i,item in ipairs(list) do
                    local wrap=Instance.new("Frame",f)
                    wrap.Size=UDim2.new(1,0,0,24)
                    wrap.BackgroundTransparency=1
                    wrap.BorderSizePixel=0
                    wrap.LayoutOrder=i
                    pad(wrap,0,8)

                    local row,rowS=glassFrame(wrap,{
                        Size=UDim2.new(1,0,1,0),
                        BackgroundColor3=ac,
                        BackgroundTransparency=0.80,
                    })
                    cr(T.CORNER_XS,row)
                    rowS.Transparency=0.7

                    local rowBtn=mkBtn(row,{
                        Size=UDim2.new(1,0,1,0),
                        Text=tostring(item),
                        TextColor3=T.TXT,
                        TextSize=11,
                        TextXAlignment=Enum.TextXAlignment.Left,
                    })
                    pad(rowBtn,0,10)

                    trackConn(rowBtn.MouseEnter:Connect(function()
                        if selRow~=row then
                            tw(row,{BackgroundTransparency=0.55},.1)
                        end
                    end))
                    trackConn(rowBtn.MouseLeave:Connect(function()
                        if selRow~=row then
                            tw(row,{BackgroundTransparency=0.80},.1)
                        end
                    end))
                    trackConn(rowBtn.MouseButton1Click:Connect(function()
                        if selRow then tw(selRow,{BackgroundTransparency=0.80},.1) end
                        selRow=row
                        tw(row,{BackgroundTransparency=0.30},.15)
                        if onSelCb then
                            onSelCb(item:match("^(.-)%s*$") or item)
                        end
                    end))
                    table.insert(entries,row)
                end
            end

            return {
                SetValues=rebuild,
                OnSelected=function(cb) onSelCb=cb end,
            }
        end

        function api.NoteText(text)
            rowN=rowN+1
            local wrap=Instance.new("Frame",scroll)
            wrap.Size=UDim2.new(1,0,0,0)
            wrap.BackgroundTransparency=1
            wrap.BorderSizePixel=0
            wrap.LayoutOrder=rowN
            wrap.AutomaticSize=Enum.AutomaticSize.Y
            pad(wrap,4,8)
            local l=mkLabel(wrap,{
                Size=UDim2.new(1,0,0,0),
                Text=tostring(text),
                TextColor3=T.MUT,
                TextSize=10,
                TextWrapped=true,
                AutomaticSize=Enum.AutomaticSize.Y,
            })
            return l
        end

        return api
    end

    -- ── AddTab ────────────────────────────────────────────────
    local WIN_OBJ = {}
    WIN_OBJ.WIN  = WIN
    WIN_OBJ.SG   = SG
    WIN_OBJ.Tabs = tabs

    function WIN_OBJ.AddTab(tabName, tabLabel, tabOrder)
        tabCount=tabCount+1

        -- Tab bg (glass pill)
        local bg,bgS=glassFrame(TABBAR,{
            BackgroundColor3=T.GLASS,
            BackgroundTransparency=1,
            ZIndex=4,
            LayoutOrder=tabOrder or tabCount,
        })

        local btn=mkBtn(bg,{
            Size=UDim2.new(1,0,1,0),
            Text=tabLabel or tabName,
            TextColor3=T.MUT,
            Font=Enum.Font.GothamBold,
            TextSize=10,
            ZIndex=5,
        })

        -- Underline
        local ul=Instance.new("Frame",bg)
        ul.Size=UDim2.new(0.8,0,0,2)
        ul.Position=UDim2.new(0.1,0,1,-2)
        ul.BackgroundColor3=accent
        ul.BackgroundTransparency=1
        ul.BorderSizePixel=0
        cr(1,ul)

        local scr=makeScroll(CONTENT)
        tabs[tabName]={btn=btn,scroll=scr,ul=ul,bg=bg}

        -- Пересчёт ширин
        local function recalc()
            local cnt=0
            for _ in pairs(tabs) do cnt=cnt+1 end
            local bw=math.floor(width/cnt)
            for _,t in pairs(tabs) do
                t.bg.Size=UDim2.new(0,bw,1,0)
            end
        end
        recalc()

        trackConn(btn.MouseEnter:Connect(function()
            if activeTab~=tabName then
                tw(btn,{TextColor3=T.TXT:Lerp(T.MUT,0.3)},.1)
                tw(bg,{BackgroundTransparency=0.9},.1)
            end
        end))
        trackConn(btn.MouseLeave:Connect(function()
            if activeTab~=tabName then
                tw(btn,{TextColor3=T.MUT},.1)
                tw(bg,{BackgroundTransparency=1},.1)
            end
        end))
        trackConn(btn.MouseButton1Click:Connect(function()
            switchTab(tabName)
        end))

        if not activeTab then switchTab(tabName) end

        local sapi=makeSectionAPI(scr, accent)

        local tabAPI={}
        function tabAPI.Section(sTitle, ac2)
            sapi.SectionHeader(sTitle, ac2)
            sapi.Space(2)
            return sapi
        end
        for k,v in pairs(sapi) do
            if not tabAPI[k] then tabAPI[k]=v end
        end

        WIN_OBJ.Tabs=tabs
        return tabAPI
    end

    function WIN_OBJ.AddHeaderButton(icon, col, cb)
        local b=makeHdrBtn(icon, col)
        if cb then trackConn(b.MouseButton1Click:Connect(cb)) end
        return b
    end

    function WIN_OBJ.SwitchTab(name)
        if tabs[name] then switchTab(name) end
    end

    function WIN_OBJ.Destroy()
        SG:Destroy()
    end

    -- Keybind INSERT
    trackConn(UIS.InputBegan:Connect(function(i,gpe)
        if gpe then return end
        if i.KeyCode==Enum.KeyCode.Insert then
            WIN.Visible=not WIN.Visible
        end
    end))

    return WIN_OBJ
end

return LordHubLib
