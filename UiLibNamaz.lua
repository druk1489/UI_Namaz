local LordHubLib = {}

local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local Players      = game:GetService("Players")
local LP           = Players.LocalPlayer
local PGui         = LP:WaitForChild("PlayerGui")

-- ── Тема ─────────────────────────────────────────────────────
local THEME = {
    BG          = Color3.fromRGB(10, 12, 16),
    BG_T        = 0.18,       -- прозрачность фона окна
    HDR         = Color3.fromRGB(15, 18, 24),
    HDR_T       = 0.12,
    SECT        = Color3.fromRGB(8, 10, 14),
    SECT_T      = 0.25,
    ROW         = Color3.fromRGB(20, 24, 32),
    ROW_T       = 0.3,
    BTN         = Color3.fromRGB(30, 36, 48),
    BTN_T       = 0.2,
    ACCENT      = Color3.fromRGB(100, 160, 255),
    ACCENT_T    = 0.0,
    TXT         = Color3.fromRGB(220, 225, 235),
    MUT         = Color3.fromRGB(110, 120, 140),
    SEP         = Color3.fromRGB(40, 48, 64),
    SEP_T       = 0.5,
    GREEN       = Color3.fromRGB(80, 200, 120),
    RED         = Color3.fromRGB(220, 70, 70),
    YEL         = Color3.fromRGB(240, 190, 45),
    STAR        = Color3.fromRGB(255, 200, 40),
    SCROLL      = Color3.fromRGB(100, 160, 255),
}

LordHubLib.Theme = THEME

-- ── Утилиты ──────────────────────────────────────────────────
local function tw(obj, props, dur, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(
            dur   or 0.15,
            style or Enum.EasingStyle.Quart,
            dir   or Enum.EasingDirection.Out
        ),
        props
    ):Play()
end

local function pad(parent, v, h)
    local p = Instance.new("UIPadding", parent)
    p.PaddingTop    = UDim.new(0, v)
    p.PaddingBottom = UDim.new(0, v)
    p.PaddingLeft   = UDim.new(0, h)
    p.PaddingRight  = UDim.new(0, h)
    return p
end

local function makeFill(parent, color, transp)
    -- Полупрозрачный фон через UIGradient trick или просто BackgroundTransparency
    parent.BackgroundColor3    = color
    parent.BackgroundTransparency = transp or 0
    parent.BorderSizePixel     = 0
end

local function scanline(parent)
    -- Эффект сканлайна (тонкие горизонтальные линии)
    local img = Instance.new("ImageLabel", parent)
    img.Size = UDim2.new(1,0,1,0)
    img.BackgroundTransparency = 1
    img.Image = "rbxassetid://6095838486" -- scanline texture
    img.ImageTransparency = 0.94
    img.ScaleType = Enum.ScaleType.Tile
    img.TileSize  = UDim2.new(0,4,0,4)
    img.ZIndex    = parent.ZIndex + 1
    return img
end

-- ── Notifications ─────────────────────────────────────────────
local notifGui = Instance.new("ScreenGui", PGui)
notifGui.Name          = "LordHubLib_Notif"
notifGui.ResetOnSpawn  = false
notifGui.ZIndexBehavior= Enum.ZIndexBehavior.Sibling
notifGui.DisplayOrder  = 999

local notifHolder = Instance.new("Frame", notifGui)
notifHolder.Size              = UDim2.new(0,260,0,500)
notifHolder.Position          = UDim2.new(1,-268,0,12)
notifHolder.BackgroundTransparency = 1
notifHolder.BorderSizePixel   = 0

local notifLayout = Instance.new("UIListLayout", notifHolder)
notifLayout.Padding            = UDim.new(0,4)
notifLayout.VerticalAlignment  = Enum.VerticalAlignment.Top
notifLayout.SortOrder          = Enum.SortOrder.LayoutOrder

local notifN = 0

function LordHubLib.Notify(title, msg, kind, duration)
    notifN  = notifN + 1
    duration= duration or 4

    local acc = kind=="error"   and THEME.RED
             or kind=="success" and THEME.GREEN
             or kind=="warn"    and THEME.YEL
             or THEME.ACCENT

    local f = Instance.new("Frame", notifHolder)
    f.Size             = UDim2.new(1,0,0,52)
    f.BackgroundColor3 = THEME.HDR
    f.BackgroundTransparency = 0.1
    f.BorderSizePixel  = 0
    f.ZIndex           = 200
    f.LayoutOrder      = notifN
    f.ClipsDescendants = true

    -- Accent полоска слева
    local bar = Instance.new("Frame", f)
    bar.Size             = UDim2.new(0,2,1,0)
    bar.BackgroundColor3 = acc
    bar.BorderSizePixel  = 0
    bar.ZIndex           = 201

    -- Progress bar снизу
    local prog = Instance.new("Frame", f)
    prog.Size             = UDim2.new(1,0,0,2)
    prog.Position         = UDim2.new(0,0,1,-2)
    prog.BackgroundColor3 = acc
    prog.BorderSizePixel  = 0
    prog.ZIndex           = 201

    -- Title
    local tl = Instance.new("TextLabel", f)
    tl.Size              = UDim2.new(1,-14,0,18)
    tl.Position          = UDim2.new(0,10,0,6)
    tl.BackgroundTransparency = 1
    tl.Text              = tostring(title)
    tl.TextColor3        = acc
    tl.Font              = Enum.Font.GothamBold
    tl.TextSize          = 11
    tl.TextXAlignment    = Enum.TextXAlignment.Left
    tl.ZIndex            = 201

    -- Message
    local ml = Instance.new("TextLabel", f)
    ml.Size              = UDim2.new(1,-14,0,14)
    ml.Position          = UDim2.new(0,10,0,26)
    ml.BackgroundTransparency = 1
    ml.Text              = tostring(msg)
    ml.TextColor3        = THEME.MUT
    ml.Font              = Enum.Font.Gotham
    ml.TextSize          = 10
    ml.TextXAlignment    = Enum.TextXAlignment.Left
    ml.ZIndex            = 201

    scanline(f)

    -- Анимация входа
    f.Position = UDim2.new(0,280,0,0)
    tw(f, {Position=UDim2.new(0,0,0,0)}, 0.25, Enum.EasingStyle.Back)

    -- Progress animation
    tw(prog, {Size=UDim2.new(0,0,0,2)}, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        tw(f, {Position=UDim2.new(0,280,0,0)}, 0.2)
        task.wait(0.22)
        f:Destroy()
    end)

    return f
end

-- ============================================================
--   WINDOW
-- ============================================================
function LordHubLib.NewWindow(config)
    config = config or {}
    local title     = config.Title    or "Lord Hub"
    local width     = config.Width    or 240
    local height    = config.Height   or 500
    local minH      = config.MinHeight or 28
    local accent    = config.Accent   or THEME.ACCENT
    local pos       = config.Position or UDim2.new(0,40,0,60)

    -- ── ScreenGui ────────────────────────────────────────────
    local SG = Instance.new("ScreenGui", PGui)
    SG.Name            = config.Name or "LordHubLib_Win"
    SG.ResetOnSpawn    = false
    SG.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    SG.DisplayOrder    = 100

    -- ── Main Frame ───────────────────────────────────────────
    local WIN = Instance.new("Frame", SG)
    WIN.Size                  = UDim2.new(0,width,0,height)
    WIN.Position              = pos
    WIN.BackgroundColor3      = THEME.BG
    WIN.BackgroundTransparency= THEME.BG_T
    WIN.BorderSizePixel       = 0
    WIN.ClipsDescendants      = true

    -- Border (1px accent)
    local border = Instance.new("Frame", WIN)
    border.Size             = UDim2.new(1,0,1,0)
    border.BackgroundTransparency = 1
    border.BorderSizePixel  = 0
    local borderStroke = Instance.new("UIStroke", WIN)
    borderStroke.Color     = accent
    borderStroke.Thickness = 1
    borderStroke.Transparency = 0.6

    scanline(WIN)

    -- ── Header ───────────────────────────────────────────────
    local HDR = Instance.new("Frame", WIN)
    HDR.Size                  = UDim2.new(1,0,0,28)
    HDR.BackgroundColor3      = THEME.HDR
    HDR.BackgroundTransparency= THEME.HDR_T
    HDR.BorderSizePixel       = 0
    HDR.ZIndex                = 5

    -- Header accent line bottom
    local hdrLine = Instance.new("Frame", HDR)
    hdrLine.Size             = UDim2.new(1,0,0,1)
    hdrLine.Position         = UDim2.new(0,0,1,-1)
    hdrLine.BackgroundColor3 = accent
    hdrLine.BorderSizePixel  = 0
    hdrLine.BackgroundTransparency = 0.4

    -- Title
    local titleLbl = Instance.new("TextLabel", HDR)
    titleLbl.Size             = UDim2.new(1,-80,1,0)
    titleLbl.Position         = UDim2.new(0,10,0,0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text             = title
    titleLbl.TextColor3       = THEME.TXT
    titleLbl.Font             = Enum.Font.GothamBold
    titleLbl.TextSize         = 12
    titleLbl.TextXAlignment   = Enum.TextXAlignment.Left
    titleLbl.ZIndex           = 6

    -- Кнопки хедера (справа)
    local hdrBtns = Instance.new("Frame", HDR)
    hdrBtns.Size             = UDim2.new(0,70,1,0)
    hdrBtns.Position         = UDim2.new(1,-70,0,0)
    hdrBtns.BackgroundTransparency = 1
    hdrBtns.BorderSizePixel  = 0
    hdrBtns.ZIndex           = 6

    local hdrBtnsLayout = Instance.new("UIListLayout", hdrBtns)
    hdrBtnsLayout.FillDirection = Enum.FillDirection.Horizontal
    hdrBtnsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    hdrBtnsLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
    hdrBtnsLayout.Padding = UDim.new(0,2)

    local function makeHdrBtn(icon, col)
        local b = Instance.new("TextButton", hdrBtns)
        b.Size             = UDim2.new(0,22,0,22)
        b.BackgroundColor3 = THEME.BTN
        b.BackgroundTransparency = 0.6
        b.BorderSizePixel  = 0
        b.Text             = icon
        b.TextColor3       = col or THEME.MUT
        b.Font             = Enum.Font.GothamBold
        b.TextSize         = 11
        b.ZIndex           = 7
        b.MouseEnter:Connect(function()
            tw(b,{BackgroundTransparency=0.2, TextColor3=THEME.TXT},.1)
        end)
        b.MouseLeave:Connect(function()
            tw(b,{BackgroundTransparency=0.6, TextColor3=col or THEME.MUT},.1)
        end)
        return b
    end

    -- ── Drag ─────────────────────────────────────────────────
    local dragging,dStart,wStart = false,nil,nil
    HDR.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dStart=i.Position; wStart=WIN.Position
            tw(WIN,{BackgroundTransparency=THEME.BG_T+0.05},.1)
        end
    end)
    HDR.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=false
            tw(WIN,{BackgroundTransparency=THEME.BG_T},.1)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-dStart
            WIN.Position=UDim2.new(
                wStart.X.Scale, wStart.X.Offset+d.X,
                wStart.Y.Scale, wStart.Y.Offset+d.Y
            )
        end
    end)

    -- ── Resize (нижний край) ─────────────────────────────────
    local resizeBar = Instance.new("Frame", WIN)
    resizeBar.Size             = UDim2.new(1,0,0,6)
    resizeBar.Position         = UDim2.new(0,0,1,-6)
    resizeBar.BackgroundColor3 = accent
    resizeBar.BackgroundTransparency = 0.7
    resizeBar.BorderSizePixel  = 0
    resizeBar.ZIndex           = 10
    resizeBar.Active           = true

    -- Resize cursor hint
    local resizeLbl = Instance.new("TextLabel", resizeBar)
    resizeLbl.Size             = UDim2.new(1,0,1,0)
    resizeLbl.BackgroundTransparency = 1
    resizeLbl.Text             = "⋯"
    resizeLbl.TextColor3       = accent
    resizeLbl.Font             = Enum.Font.GothamBold
    resizeLbl.TextSize         = 8
    resizeLbl.TextTransparency = 0.5

    local resizing,rStart,rH = false,nil,nil
    resizeBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            resizing=true
            rStart=i.Position.Y
            rH=WIN.AbsoluteSize.Y
            tw(resizeBar,{BackgroundTransparency=0.3},.1)
        end
    end)
    resizeBar.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            resizing=false
            tw(resizeBar,{BackgroundTransparency=0.7},.1)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if resizing and i.UserInputType==Enum.UserInputType.MouseMovement then
            local newH = math.max(minH, rH+(i.Position.Y-rStart))
            WIN.Size = UDim2.new(0,width,0,newH)
        end
    end)

    resizeBar.MouseEnter:Connect(function()
        tw(resizeBar,{BackgroundTransparency=0.4},.1)
    end)
    resizeBar.MouseLeave:Connect(function()
        if not resizing then
            tw(resizeBar,{BackgroundTransparency=0.7},.1)
        end
    end)

    -- ── Collapse ─────────────────────────────────────────────
    local collapsed = false
    local savedH    = height
    local colBtn    = makeHdrBtn("▼")

    colBtn.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        if collapsed then
            savedH = WIN.AbsoluteSize.Y
            tw(WIN,{Size=UDim2.new(0,width,0,28)},0.2,Enum.EasingStyle.Quart)
            colBtn.Text = "▶"
            tw(resizeBar,{BackgroundTransparency=1},.1)
        else
            tw(WIN,{Size=UDim2.new(0,width,0,savedH)},0.2,Enum.EasingStyle.Back)
            colBtn.Text = "▼"
            tw(resizeBar,{BackgroundTransparency=0.7},.15)
        end
    end)

    -- ── Tab Bar ──────────────────────────────────────────────
    local TABBAR = Instance.new("Frame", WIN)
    TABBAR.Size                  = UDim2.new(1,0,0,24)
    TABBAR.Position              = UDim2.new(0,0,0,28)
    TABBAR.BackgroundColor3      = THEME.HDR
    TABBAR.BackgroundTransparency= 0.2
    TABBAR.BorderSizePixel       = 0

    local tabLine = Instance.new("Frame", TABBAR)
    tabLine.Size             = UDim2.new(1,0,0,1)
    tabLine.Position         = UDim2.new(0,0,1,-1)
    tabLine.BackgroundColor3 = THEME.SEP
    tabLine.BorderSizePixel  = 0
    tabLine.BackgroundTransparency = THEME.SEP_T

    local tabLayout2 = Instance.new("UIListLayout", TABBAR)
    tabLayout2.FillDirection = Enum.FillDirection.Horizontal
    tabLayout2.SortOrder     = Enum.SortOrder.LayoutOrder
    tabLayout2.Padding       = UDim.new(0,0)

    -- Separator header/tabs
    local sepHdr = Instance.new("Frame", WIN)
    sepHdr.Size             = UDim2.new(1,0,0,1)
    sepHdr.Position         = UDim2.new(0,0,0,52)
    sepHdr.BackgroundColor3 = accent
    sepHdr.BorderSizePixel  = 0
    sepHdr.BackgroundTransparency = 0.5

    -- ── Content ───────────────────────────────────────────────
    local CONTENT = Instance.new("Frame", WIN)
    CONTENT.Size             = UDim2.new(1,0,1,-59)
    CONTENT.Position         = UDim2.new(0,0,0,53)
    CONTENT.BackgroundTransparency = 1
    CONTENT.BorderSizePixel  = 0
    CONTENT.ClipsDescendants = true

    -- ── Tab система ──────────────────────────────────────────
    local tabs      = {}
    local activeTab = nil

    local function makeScroll(parent)
        local s = Instance.new("ScrollingFrame", parent)
        s.Size                   = UDim2.new(1,0,1,0)
        s.BackgroundTransparency = 1
        s.BorderSizePixel        = 0
        s.ScrollBarThickness     = 2
        s.ScrollBarImageColor3   = accent
        s.CanvasSize             = UDim2.new(0,0,0,0)
        s.Visible                = false
        local sl = Instance.new("UIListLayout", s)
        sl.Padding       = UDim.new(0,0)
        sl.SortOrder     = Enum.SortOrder.LayoutOrder
        sl.HorizontalAlignment = Enum.HorizontalAlignment.Center
        sl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            s.CanvasSize = UDim2.new(0,0,0,sl.AbsoluteContentSize.Y+6)
        end)
        return s, sl
    end

    local function switchTab(name)
        if activeTab==name then return end
        -- Анимация fade out старого
        if activeTab and tabs[activeTab] then
            local old = tabs[activeTab].scroll
            tw(old,{GroupTransparency=1},0.1)
            task.delay(0.1,function()
                old.Visible=false
                old.GroupTransparency=0
            end)
            tabs[activeTab].btn.BackgroundTransparency = 1
            tabs[activeTab].ul.BackgroundTransparency  = 1
        end
        activeTab = name
        -- Анимация fade in нового
        local new = tabs[name].scroll
        new.GroupTransparency = 1
        new.Visible = true
        tw(new,{GroupTransparency=0},0.15)
        tabs[name].btn.BackgroundTransparency = 0.7
        tabs[name].ul.BackgroundTransparency  = 0
        tabs[name].btn.TextColor3 = THEME.TXT
    end

    local WIN_OBJ = {}

    -- Добавляем таб
    function WIN_OBJ.AddTab(tabName, tabLabel, tabOrder)
        local tabCount = 0
        for _ in pairs(tabs) do tabCount=tabCount+1 end

        local btn = Instance.new("TextButton", TABBAR)
        btn.Size             = UDim2.new(0,math.floor(width/#{}),1,0)
        btn.BackgroundColor3 = THEME.HDR
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel  = 0
        btn.Text             = tabLabel or tabName
        btn.TextColor3       = THEME.MUT
        btn.Font             = Enum.Font.GothamBold
        btn.TextSize         = 10
        btn.LayoutOrder      = tabOrder or (tabCount+1)

        local ul = Instance.new("Frame", btn)
        ul.Size             = UDim2.new(1,0,0,2)
        ul.Position         = UDim2.new(0,0,1,-2)
        ul.BackgroundColor3 = accent
        ul.BorderSizePixel  = 0
        ul.BackgroundTransparency = 1

        local scr, _ = makeScroll(CONTENT)
        tabs[tabName] = {btn=btn, scroll=scr, ul=ul}

        btn.MouseEnter:Connect(function()
            if activeTab~=tabName then
                tw(btn,{TextColor3=THEME.TXT:Lerp(THEME.MUT,0.3)},.1)
                tw(btn,{BackgroundTransparency=0.85},.1)
            end
        end)
        btn.MouseLeave:Connect(function()
            if activeTab~=tabName then
                tw(btn,{TextColor3=THEME.MUT},.1)
                tw(btn,{BackgroundTransparency=1},.1)
            end
        end)
        btn.MouseButton1Click:Connect(function()
            switchTab(tabName)
        end)

        -- Пересчёт ширины кнопок
        local tCount = 0
        for _ in pairs(tabs) do tCount=tCount+1 end
        local bw = math.floor(width/tCount)
        for _,t in pairs(tabs) do
            t.btn.Size = UDim2.new(0,bw,1,0)
        end

        -- Section factory для этого таба
        local SEC = {}

        local rowN = 0
        local scroll = scr

        function SEC.Section(sTitle)
            rowN=rowN+1
            local f=Instance.new("Frame",scroll)
            f.Size=UDim2.new(1,0,0,20)
            f.BackgroundColor3=THEME.SECT
            f.BackgroundTransparency=THEME.SECT_T
            f.BorderSizePixel=0
            f.LayoutOrder=rowN

            local accent2=Instance.new("Frame",f)
            accent2.Size=UDim2.new(0,2,1,0)
            accent2.BackgroundColor3=accent
            accent2.BorderSizePixel=0
            accent2.BackgroundTransparency=0.3

            local lbl=Instance.new("TextLabel",f)
            lbl.Size=UDim2.new(1,-14,1,0)
            lbl.Position=UDim2.new(0,10,0,0)
            lbl.BackgroundTransparency=1
            lbl.Text=tostring(sTitle)
            lbl.TextColor3=accent
            lbl.Font=Enum.Font.GothamBold
            lbl.TextSize=10
            lbl.TextXAlignment=Enum.TextXAlignment.Left

            local sapi={}

            function sapi.Space(h)
                rowN=rowN+1
                local sp=Instance.new("Frame",scroll)
                sp.Size=UDim2.new(1,0,0,h or 4)
                sp.BackgroundTransparency=1
                sp.BorderSizePixel=0
                sp.LayoutOrder=rowN
            end

            function sapi.Separator()
                rowN=rowN+1
                local sp=Instance.new("Frame",scroll)
                sp.Size=UDim2.new(1,0,0,1)
                sp.BackgroundColor3=THEME.SEP
                sp.BackgroundTransparency=THEME.SEP_T
                sp.BorderSizePixel=0
                sp.LayoutOrder=rowN
            end

            function sapi.Label(text, color, indent)
                rowN=rowN+1
                local f2=Instance.new("Frame",scroll)
                f2.Size=UDim2.new(1,0,0,18)
                f2.BackgroundTransparency=1
                f2.BorderSizePixel=0
                f2.LayoutOrder=rowN
                local lbl2=Instance.new("TextLabel",f2)
                lbl2.Size=UDim2.new(1,-(indent or 10),1,0)
                lbl2.Position=UDim2.new(0,indent or 10,0,0)
                lbl2.BackgroundTransparency=1
                lbl2.Text=tostring(text)
                lbl2.TextColor3=color or THEME.MUT
                lbl2.Font=Enum.Font.Gotham
                lbl2.TextSize=11
                lbl2.TextXAlignment=Enum.TextXAlignment.Left
                lbl2.TextWrapped=true
                return lbl2
            end

            function sapi.Button(text, color, callback)
                rowN=rowN+1
                color=color or THEME.BTN
                local wrap=Instance.new("Frame",scroll)
                wrap.Size=UDim2.new(1,0,0,30)
                wrap.BackgroundTransparency=1
                wrap.LayoutOrder=rowN
                pad(wrap,3,8)

                local b=Instance.new("TextButton",wrap)
                b.Size=UDim2.new(1,0,1,0)
                b.BackgroundColor3=color
                b.BackgroundTransparency=0.3
                b.BorderSizePixel=0
                b.Text=tostring(text)
                b.TextColor3=THEME.TXT
                b.Font=Enum.Font.GothamBold
                b.TextSize=11

                -- Hover анимация
                b.MouseEnter:Connect(function()
                    tw(b,{BackgroundTransparency=0.1,TextColor3=Color3.new(1,1,1)},.1)
                end)
                b.MouseLeave:Connect(function()
                    tw(b,{BackgroundTransparency=0.3,TextColor3=THEME.TXT},.1)
                end)
                b.MouseButton1Down:Connect(function()
                    tw(b,{BackgroundTransparency=0.5,Size=UDim2.new(0.97,0,0.9,0)},.07)
                end)
                b.MouseButton1Up:Connect(function()
                    tw(b,{BackgroundTransparency=0.3,Size=UDim2.new(1,0,1,0)},.1,Enum.EasingStyle.Back)
                end)
                if callback then
                    b.MouseButton1Click:Connect(callback)
                end
                return b
            end

            function sapi.Button2(t1,c1,t2,c2,cb1,cb2)
                rowN=rowN+1
                local wrap=Instance.new("Frame",scroll)
                wrap.Size=UDim2.new(1,0,0,30)
                wrap.BackgroundTransparency=1
                wrap.LayoutOrder=rowN
                pad(wrap,3,8)
                local inner=Instance.new("Frame",wrap)
                inner.Size=UDim2.new(1,0,1,0)
                inner.BackgroundTransparency=1
                local ul2=Instance.new("UIListLayout",inner)
                ul2.FillDirection=Enum.FillDirection.Horizontal
                ul2.Padding=UDim.new(0,6)
                local function mkB(t,col,cb)
                    col=col or THEME.BTN
                    local b=Instance.new("TextButton",inner)
                    b.Size=UDim2.new(0.5,-3,1,0)
                    b.BackgroundColor3=col
                    b.BackgroundTransparency=0.3
                    b.BorderSizePixel=0
                    b.Text=tostring(t)
                    b.TextColor3=THEME.TXT
                    b.Font=Enum.Font.GothamBold
                    b.TextSize=10
                    b.MouseEnter:Connect(function()
                        tw(b,{BackgroundTransparency=0.1},.1)
                    end)
                    b.MouseLeave:Connect(function()
                        tw(b,{BackgroundTransparency=0.3},.1)
                    end)
                    b.MouseButton1Down:Connect(function()
                        tw(b,{BackgroundTransparency=0.5,Size=UDim2.new(0.47,-3,0.9,0)},.07)
                    end)
                    b.MouseButton1Up:Connect(function()
                        tw(b,{BackgroundTransparency=0.3,Size=UDim2.new(0.5,-3,1,0)},.1,Enum.EasingStyle.Back)
                    end)
                    if cb then b.MouseButton1Click:Connect(cb) end
                    return b
                end
                return mkB(t1,c1,cb1), mkB(t2,c2,cb2)
            end

            function sapi.Input(placeholder, numeric, default, callback)
                rowN=rowN+1
                local wrap=Instance.new("Frame",scroll)
                wrap.Size=UDim2.new(1,0,0,28)
                wrap.BackgroundTransparency=1
                wrap.LayoutOrder=rowN
                pad(wrap,3,8)
                local f2=Instance.new("Frame",wrap)
                f2.Size=UDim2.new(1,0,1,0)
                f2.BackgroundColor3=THEME.ROW
                f2.BackgroundTransparency=THEME.ROW_T
                f2.BorderSizePixel=0
                local ip=Instance.new("UIPadding",f2)
                ip.PaddingLeft=UDim.new(0,7)
                ip.PaddingRight=UDim.new(0,7)
                local b=Instance.new("TextBox",f2)
                b.Size=UDim2.new(1,0,1,0)
                b.BackgroundTransparency=1
                b.PlaceholderText=tostring(placeholder or "")
                b.PlaceholderColor3=THEME.MUT
                b.Text=tostring(default or "")
                b.TextColor3=THEME.TXT
                b.Font=Enum.Font.Gotham
                b.TextSize=11
                b.ClearTextOnFocus=false
                if numeric then
                    b:GetPropertyChangedSignal("Text"):Connect(function()
                        local v=b.Text:gsub("[^%d%.%-]","")
                        if v~=b.Text then b.Text=v end
                    end)
                end
                b.Focused:Connect(function()
                    tw(f2,{BackgroundTransparency=0.1},.1)
                    local s=Instance.new("UIStroke",f2)
                    s.Name="IFS"; s.Thickness=1; s.Color=accent
                    tw(s,{Transparency=0},.1)
                end)
                b.FocusLost:Connect(function()
                    tw(f2,{BackgroundTransparency=THEME.ROW_T},.1)
                    local s=f2:FindFirstChild("IFS")
                    if s then s:Destroy() end
                    if callback then callback(b.Text) end
                end)
                return b
            end

            function sapi.Toggle(labelText, default, callback)
                default=default==true
                rowN=rowN+1
                local wrap=Instance.new("Frame",scroll)
                wrap.Size=UDim2.new(1,0,0,26)
                wrap.BackgroundTransparency=1
                wrap.BorderSizePixel=0
                wrap.LayoutOrder=rowN

                -- Hover
                local hov=Instance.new("Frame",wrap)
                hov.Size=UDim2.new(1,0,1,0)
                hov.BackgroundColor3=accent
                hov.BackgroundTransparency=1
                hov.BorderSizePixel=0

                local lbl2=Instance.new("TextLabel",wrap)
                lbl2.Size=UDim2.new(1,-42,1,0)
                lbl2.Position=UDim2.new(0,10,0,0)
                lbl2.BackgroundTransparency=1
                lbl2.Text=tostring(labelText)
                lbl2.TextColor3=THEME.TXT
                lbl2.Font=Enum.Font.Gotham
                lbl2.TextSize=11
                lbl2.TextXAlignment=Enum.TextXAlignment.Left

                -- Toggle track
                local track=Instance.new("Frame",wrap)
                track.Size=UDim2.new(0,28,0,14)
                track.Position=UDim2.new(1,-34,0.5,-7)
                track.BackgroundColor3=default and accent or THEME.ROW
                track.BackgroundTransparency=default and 0.2 or 0.4
                track.BorderSizePixel=0

                -- Toggle knob
                local knob=Instance.new("Frame",track)
                knob.Size=UDim2.new(0,10,0,10)
                knob.Position=default
                    and UDim2.new(1,-12,0.5,-5)
                    or  UDim2.new(0,2,0.5,-5)
                knob.BackgroundColor3=default and THEME.TXT or THEME.MUT
                knob.BorderSizePixel=0

                local on=default
                local clickBtn=Instance.new("TextButton",wrap)
                clickBtn.Size=UDim2.new(1,0,1,0)
                clickBtn.BackgroundTransparency=1
                clickBtn.Text=""
                clickBtn.BorderSizePixel=0

                clickBtn.MouseEnter:Connect(function()
                    tw(hov,{BackgroundTransparency=0.92},.1)
                end)
                clickBtn.MouseLeave:Connect(function()
                    tw(hov,{BackgroundTransparency=1},.1)
                end)
                clickBtn.MouseButton1Click:Connect(function()
                    on=not on
                    if on then
                        tw(track,{BackgroundColor3=accent,BackgroundTransparency=0.2},.15)
                        tw(knob,{Position=UDim2.new(1,-12,0.5,-5),BackgroundColor3=THEME.TXT},.15,Enum.EasingStyle.Back)
                    else
                        tw(track,{BackgroundColor3=THEME.ROW,BackgroundTransparency=0.4},.15)
                        tw(knob,{Position=UDim2.new(0,2,0.5,-5),BackgroundColor3=THEME.MUT},.15,Enum.EasingStyle.Back)
                    end
                    if callback then pcall(callback,on) end
                end)

                return {
                    GetValue=function() return on end,
                    SetValue=function(v)
                        on=v==true
                        track.BackgroundColor3=on and accent or THEME.ROW
                        track.BackgroundTransparency=on and 0.2 or 0.4
                        knob.Position=on
                            and UDim2.new(1,-12,0.5,-5)
                            or  UDim2.new(0,2,0.5,-5)
                        knob.BackgroundColor3=on and THEME.TXT or THEME.MUT
                    end,
                }
            end

            function sapi.Dropdown(items, callback)
                rowN=rowN+1
                local cur=items[1] or "Select"
                local wrap=Instance.new("Frame",scroll)
                wrap.Size=UDim2.new(1,0,0,26)
                wrap.BackgroundTransparency=1
                wrap.LayoutOrder=rowN
                pad(wrap,2,8)

                local host=Instance.new("TextButton",wrap)
                host.Size=UDim2.new(1,0,1,0)
                host.BackgroundColor3=THEME.ROW
                host.BackgroundTransparency=THEME.ROW_T
                host.BorderSizePixel=0
                host.Text=""

                local lbl2=Instance.new("TextLabel",host)
                lbl2.Size=UDim2.new(1,-24,1,0)
                lbl2.Position=UDim2.new(0,8,0,0)
                lbl2.BackgroundTransparency=1
                lbl2.Text=tostring(cur)
                lbl2.TextColor3=THEME.TXT
                lbl2.Font=Enum.Font.Gotham
                lbl2.TextSize=11
                lbl2.TextXAlignment=Enum.TextXAlignment.Left

                local arr=Instance.new("TextLabel",host)
                arr.Size=UDim2.new(0,18,1,0)
                arr.Position=UDim2.new(1,-20,0,0)
                arr.BackgroundTransparency=1
                arr.Text="∨"
                arr.TextColor3=THEME.MUT
                arr.Font=Enum.Font.GothamBold
                arr.TextSize=10

                local popup=Instance.new("Frame",SG)
                popup.BackgroundColor3=THEME.ROW
                popup.BackgroundTransparency=0.05
                popup.BorderSizePixel=0
                popup.ZIndex=150
                popup.Visible=false
                local pStroke=Instance.new("UIStroke",popup)
                pStroke.Color=accent; pStroke.Thickness=1
                pStroke.Transparency=0.5

                local psl=Instance.new("ScrollingFrame",popup)
                psl.Size=UDim2.new(1,0,1,0)
                psl.BackgroundTransparency=1
                psl.BorderSizePixel=0
                psl.ScrollBarThickness=2
                psl.ScrollBarImageColor3=accent
                psl.ZIndex=151
                psl.CanvasSize=UDim2.new(0,0,0,0)
                local psll=Instance.new("UIListLayout",psl)
                psll.Padding=UDim.new(0,1)
                psll.SortOrder=Enum.SortOrder.LayoutOrder
                pad(psl,3,4)
                psll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    psl.CanvasSize=UDim2.new(0,0,0,psll.AbsoluteContentSize.Y+8)
                end)

                local ddBtns={}
                local function closeDD()
                    tw(popup,{BackgroundTransparency=1},0.1)
                    task.delay(0.1,function()
                        popup.Visible=false
                        popup.BackgroundTransparency=0.05
                    end)
                    arr.Text="∨"
                end

                local function buildList(newItems)
                    for _,b in ipairs(ddBtns) do b:Destroy() end; ddBtns={}
                    for i,item in ipairs(newItems) do
                        local ib=Instance.new("TextButton",psl)
                        ib.Size=UDim2.new(1,0,0,22)
                        ib.BackgroundTransparency=1
                        ib.BackgroundColor3=accent:Lerp(THEME.BG,.7)
                        ib.Text=tostring(item)
                        ib.TextColor3=THEME.TXT
                        ib.Font=Enum.Font.Gotham
                        ib.TextSize=11
                        ib.BorderSizePixel=0
                        ib.TextXAlignment=Enum.TextXAlignment.Left
                        ib.LayoutOrder=i
                        ib.ZIndex=152
                        local ipp=Instance.new("UIPadding",ib)
                        ipp.PaddingLeft=UDim.new(0,8)
                        ipp.PaddingRight=UDim.new(0,8)
                        ib.MouseEnter:Connect(function()
                            tw(ib,{BackgroundTransparency=0},.1)
                        end)
                        ib.MouseLeave:Connect(function()
                            tw(ib,{BackgroundTransparency=1},.1)
                        end)
                        ib.MouseButton1Click:Connect(function()
                            cur=item; lbl2.Text=tostring(item); closeDD()
                            if callback then callback(item) end
                        end)
                        table.insert(ddBtns,ib)
                    end
                end

                buildList(items)

                host.MouseEnter:Connect(function()
                    tw(host,{BackgroundTransparency=0.1},.1)
                end)
                host.MouseLeave:Connect(function()
                    tw(host,{BackgroundTransparency=THEME.ROW_T},.1)
                end)
                host.MouseButton1Click:Connect(function()
                    if popup.Visible then closeDD(); return end
                    local ap=host.AbsolutePosition
                    local aw=host.AbsoluteSize.X
                    local H=math.min(#ddBtns*23+8,160)
                    popup.Size=UDim2.new(0,aw,0,H)
                    popup.Position=UDim2.new(0,ap.X,0,ap.Y+28)
                    popup.Visible=true
                    popup.BackgroundTransparency=1
                    tw(popup,{BackgroundTransparency=0.05},0.15)
                    arr.Text="∧"
                end)

                SG.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then
                        task.wait()
                        if popup.Visible then closeDD() end
                    end
                end)

                return {
                    GetValue=function() return cur end,
                    SetValues=function(v)
                        buildList(v)
                        if #v>0 then cur=v[1]; lbl2.Text=tostring(v[1]) end
                    end,
                }
            end

            function sapi.StatusBar(lines)
                rowN=rowN+1
                local wrap=Instance.new("Frame",scroll)
                wrap.Size=UDim2.new(1,0,0,14+(lines or 1)*14)
                wrap.BackgroundTransparency=1
                wrap.LayoutOrder=rowN
                pad(wrap,3,8)
                local f2=Instance.new("Frame",wrap)
                f2.Size=UDim2.new(1,0,1,0)
                f2.BackgroundColor3=THEME.SECT
                f2.BackgroundTransparency=THEME.SECT_T
                f2.BorderSizePixel=0
                pad(f2,3,7)
                local l=Instance.new("TextLabel",f2)
                l.Size=UDim2.new(1,0,1,0)
                l.BackgroundTransparency=1
                l.Text=""
                l.TextColor3=THEME.MUT
                l.Font=Enum.Font.Gotham
                l.TextSize=10
                l.TextWrapped=true
                l.TextXAlignment=Enum.TextXAlignment.Left
                l.TextYAlignment=Enum.TextYAlignment.Top
                return l
            end

            function sapi.ProgressBar()
                rowN=rowN+1
                local wrap=Instance.new("Frame",scroll)
                wrap.Size=UDim2.new(1,0,0,8)
                wrap.BackgroundTransparency=1
                wrap.LayoutOrder=rowN
                pad(wrap,1,8)
                local bg=Instance.new("Frame",wrap)
                bg.Size=UDim2.new(1,0,1,0)
                bg.BackgroundColor3=THEME.ROW
                bg.BackgroundTransparency=THEME.ROW_T
                bg.BorderSizePixel=0
                local fill=Instance.new("Frame",bg)
                fill.Size=UDim2.new(0,0,1,0)
                fill.BackgroundColor3=accent
                fill.BorderSizePixel=0

                -- Shimmer анимация
                local shimmer=Instance.new("Frame",fill)
                shimmer.Size=UDim2.new(0,20,1,0)
                shimmer.BackgroundColor3=Color3.new(1,1,1)
                shimmer.BackgroundTransparency=0.7
                shimmer.BorderSizePixel=0
                task.spawn(function()
                    while shimmer.Parent do
                        shimmer.Position=UDim2.new(0,-20,0,0)
                        tw(shimmer,{Position=UDim2.new(1,0,0,0)},1,Enum.EasingStyle.Linear)
                        task.wait(1.2)
                    end
                end)

                return fill
            end

            function sapi.FileList()
                rowN=rowN+1
                local f2=Instance.new("Frame",scroll)
                f2.Size=UDim2.new(1,0,0,0)
                f2.BackgroundTransparency=1
                f2.BorderSizePixel=0
                f2.LayoutOrder=rowN
                local fl=Instance.new("UIListLayout",f2)
                fl.Padding=UDim.new(0,0)
                fl.SortOrder=Enum.SortOrder.LayoutOrder
                fl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    f2.Size=UDim2.new(1,0,0,fl.AbsoluteContentSize.Y)
                end)
                local entries={}
                local selectedRow=nil
                local onSelCb=nil

                local function rebuild(list)
                    for _,e in ipairs(entries) do e:Destroy() end
                    entries={}; selectedRow=nil
                    for i,item in ipairs(list) do
                        local row=Instance.new("TextButton",f2)
                        row.Size=UDim2.new(1,0,0,22)
                        row.BackgroundColor3=accent
                        row.BackgroundTransparency=0.85
                        row.Text=tostring(item)
                        row.TextColor3=THEME.TXT
                        row.Font=Enum.Font.Gotham
                        row.TextSize=11
                        row.TextXAlignment=Enum.TextXAlignment.Left
                        row.BorderSizePixel=0
                        row.LayoutOrder=i
                        local rip=Instance.new("UIPadding",row)
                        rip.PaddingLeft=UDim.new(0,14)
                        row.MouseEnter:Connect(function()
                            if selectedRow~=row then
                                tw(row,{BackgroundTransparency=0.65},.1)
                            end
                        end)
                        row.MouseLeave:Connect(function()
                            if selectedRow~=row then
                                tw(row,{BackgroundTransparency=0.85},.1)
                            end
                        end)
                        row.MouseButton1Click:Connect(function()
                            if selectedRow then
                                tw(selectedRow,{BackgroundTransparency=0.85},.1)
                            end
                            selectedRow=row
                            tw(row,{BackgroundTransparency=0.4},.1)
                            if onSelCb then
                                onSelCb(item:match("^(.-)%s*$") or item)
                            end
                        end)
                        table.insert(entries,row)
                    end
                end

                return {
                    SetValues=rebuild,
                    OnSelected=function(cb) onSelCb=cb end,
                }
            end

            function sapi.NoteText(text)
                rowN=rowN+1
                local wrap=Instance.new("Frame",scroll)
                wrap.Size=UDim2.new(1,0,0,0)
                wrap.BackgroundTransparency=1
                wrap.BorderSizePixel=0
                wrap.LayoutOrder=rowN
                wrap.AutomaticSize=Enum.AutomaticSize.Y
                pad(wrap,4,8)
                local lbl2=Instance.new("TextLabel",wrap)
                lbl2.Size=UDim2.new(1,0,0,0)
                lbl2.BackgroundTransparency=1
                lbl2.Text=tostring(text)
                lbl2.TextColor3=THEME.MUT
                lbl2.Font=Enum.Font.Gotham
                lbl2.TextSize=10
                lbl2.TextWrapped=true
                lbl2.AutomaticSize=Enum.AutomaticSize.Y
                lbl2.TextXAlignment=Enum.TextXAlignment.Left
                return lbl2
            end

            return sapi
        end

        -- Активируем первый таб автоматически
        if not activeTab then
            switchTab(tabName)
        end

        WIN_OBJ.Tabs = tabs
        WIN_OBJ.SG   = SG
        WIN_OBJ.WIN  = WIN

        return SEC
    end

    -- Добавляем кнопку шестерёнки в хедер
    function WIN_OBJ.AddHeaderButton(icon, color, callback)
        local b = makeHdrBtn(icon, color)
        if callback then b.MouseButton1Click:Connect(callback) end
        return b
    end

    function WIN_OBJ.SwitchTab(name)
        if tabs[name] then switchTab(name) end
    end

    function WIN_OBJ.SetAccent(col)
        accent = col
        borderStroke.Color = col
        hdrLine.BackgroundColor3 = col
        sepHdr.BackgroundColor3  = col
    end

    function WIN_OBJ.Destroy()
        SG:Destroy()
    end

    return WIN_OBJ
end

return LordHubLib
