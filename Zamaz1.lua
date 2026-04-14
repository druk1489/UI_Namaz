if _G.LordHubUnload then
    pcall(_G.LordHubUnload)
    task.wait(0.1)
end

local LordHubLib = {}
local connections = {}
local blurEffect  = nil

local function trackConn(c)
    table.insert(connections, c)
    return c
end

_G.LordHubUnload = function()
    _G.LordHubActive = false
    for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    connections = {}
    if blurEffect then
        game:GetService("TweenService"):Create(
            blurEffect,TweenInfo.new(0.3),{Size=0}):Play()
        task.delay(0.4,function() pcall(function() blurEffect:Destroy() end) end)
    end
    local PGui=game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    for _,g in ipairs(PGui:GetChildren()) do
        if g.Name:find("LordHub") then g:Destroy() end
    end
    local bb=workspace:FindFirstChild("LordHubBB")
    if bb then bb:Destroy() end
end

LordHubLib.Unload = _G.LordHubUnload
_G.LordHubActive  = true

local TS       = game:GetService("TweenService")
local UIS      = game:GetService("UserInputService")
local Players  = game:GetService("Players")
local LP       = Players.LocalPlayer
local PGui     = LP:WaitForChild("PlayerGui")

-- Blur
blurEffect = Instance.new("BlurEffect", workspace.CurrentCamera)
blurEffect.Size = 0
TS:Create(blurEffect,TweenInfo.new(0.5),{Size=10}):Play()

-- ── Тема ─────────────────────────────────────────────────────
local T = {
    BG      = Color3.fromRGB(8,  12, 20),
    BG_T    = 0.45,
    HDR     = Color3.fromRGB(5,  8,  15),
    HDR_T   = 0.30,
    ROW     = Color3.fromRGB(20, 28, 42),
    ROW_T   = 0.50,
    BTN     = Color3.fromRGB(25, 35, 55),
    BTN_T   = 0.35,
    ACCENT  = Color3.fromRGB(10, 132,255),
    TXT     = Color3.fromRGB(240,245,255),
    MUT     = Color3.fromRGB(140,155,180),
    SEP     = Color3.fromRGB(255,255,255),
    GREEN   = Color3.fromRGB(48, 209, 88),
    RED     = Color3.fromRGB(255, 69, 58),
    YEL     = Color3.fromRGB(255,214, 10),
    STAR    = Color3.fromRGB(255,200, 40),
    CORNER  = 10,
    CORNER_S= 6,
}
LordHubLib.Theme = T

-- ── Хелперы ──────────────────────────────────────────────────
local function tw(o,p,d,s,dr)
    TS:Create(o,TweenInfo.new(d or .18,s or Enum.EasingStyle.Quart,
        dr or Enum.EasingDirection.Out),p):Play()
end

local function cr(r,p)
    local c=Instance.new("UICorner",p)
    c.CornerRadius=UDim.new(0,r)
end

local function pd(p,v,h)
    local u=Instance.new("UIPadding",p)
    u.PaddingTop=UDim.new(0,v); u.PaddingBottom=UDim.new(0,v)
    u.PaddingLeft=UDim.new(0,h); u.PaddingRight=UDim.new(0,h)
end

-- Стеклянный фрейм
local function glass(parent, bgCol, bgT, props)
    local f = Instance.new("Frame", parent)
    f.BackgroundColor3 = bgCol or T.BG
    f.BackgroundTransparency = bgT or T.BG_T
    f.BorderSizePixel = 0
    if props then
        for k,v in pairs(props) do
            pcall(function() f[k]=v end)
        end
    end

    -- Белая обводка (стекло)
    local st = Instance.new("UIStroke", f)
    st.Color = Color3.fromRGB(255,255,255)
    st.Thickness = 1
    st.Transparency = 0.65
    st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Световой блик сверху
    local shine = Instance.new("Frame", f)
    shine.Size = UDim2.new(1,0,0.4,0)
    shine.BackgroundColor3 = Color3.fromRGB(255,255,255)
    shine.BackgroundTransparency = 0.93
    shine.BorderSizePixel = 0
    shine.ZIndex = (f.ZIndex or 1)+1
    local g = Instance.new("UIGradient", shine)
    g.Rotation = 90
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,0),
        NumberSequenceKeypoint.new(1,1),
    })

    return f, st
end

local function mkTxt(parent, props)
    local l = Instance.new("TextLabel", parent)
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 11
    l.TextColor3 = T.TXT
    l.TextXAlignment = Enum.TextXAlignment.Left
    for k,v in pairs(props or {}) do pcall(function() l[k]=v end) end
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
    for k,v in pairs(props or {}) do pcall(function() b[k]=v end) end
    return b
end

-- ── Notifications ─────────────────────────────────────────────
local notifSG = Instance.new("ScreenGui",PGui)
notifSG.Name="LordHub_Notif"; notifSG.ResetOnSpawn=false
notifSG.DisplayOrder=999; notifSG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling

local nHolder = Instance.new("Frame",notifSG)
nHolder.Size=UDim2.new(0,270,0,500)
nHolder.Position=UDim2.new(1,-278,0,10)
nHolder.BackgroundTransparency=1; nHolder.BorderSizePixel=0
local nLayout=Instance.new("UIListLayout",nHolder)
nLayout.Padding=UDim.new(0,5)
nLayout.SortOrder=Enum.SortOrder.LayoutOrder
local nN=0

function LordHubLib.Notify(title,msg,kind,dur)
    nN=nN+1; dur=dur or 4
    local acc=kind=="error" and T.RED or kind=="success" and T.GREEN
        or kind=="warn" and T.YEL or T.ACCENT

    local f,fSt=glass(nHolder,T.BG,0.20,{
        Size=UDim2.new(1,0,0,56),
        ClipsDescendants=true,
        LayoutOrder=nN,
        ZIndex=200,
    })
    cr(T.CORNER,f)
    fSt.Color=acc; fSt.Transparency=0.3

    local bar=Instance.new("Frame",f)
    bar.Size=UDim2.new(0,3,0.7,0)
    bar.Position=UDim2.new(0,0,0.15,0)
    bar.BackgroundColor3=acc; bar.BorderSizePixel=0
    cr(2,bar)

    local prog=Instance.new("Frame",f)
    prog.Size=UDim2.new(1,0,0,2)
    prog.Position=UDim2.new(0,0,1,-2)
    prog.BackgroundColor3=acc; prog.BorderSizePixel=0

    mkTxt(f,{
        Size=UDim2.new(1,-14,0,19),
        Position=UDim2.new(0,10,0,5),
        Text=tostring(title),
        TextColor3=acc,
        Font=Enum.Font.GothamBold,
        TextSize=12,ZIndex=201,
    })
    mkTxt(f,{
        Size=UDim2.new(1,-14,0,16),
        Position=UDim2.new(0,10,0,27),
        Text=tostring(msg),
        TextColor3=T.MUT,
        TextSize=10,TextWrapped=true,ZIndex=201,
    })

    f.Position=UDim2.new(0,290,0,0)
    tw(f,{Position=UDim2.new(0,0,0,0)},0.3,Enum.EasingStyle.Back)
    tw(prog,{Size=UDim2.new(0,0,0,2)},dur,Enum.EasingStyle.Linear)
    task.delay(dur,function()
        tw(f,{Position=UDim2.new(0,290,0,0)},0.2)
        task.wait(0.22); f:Destroy()
    end)
end

-- ============================================================
--   WINDOW
-- ============================================================
function LordHubLib.NewWindow(cfg)
    cfg=cfg or {}
    local title  = cfg.Title    or "Lord Hub"
    local width  = cfg.Width    or 240
    local height = cfg.Height   or 520
    local accent = cfg.Accent   or T.ACCENT
    local pos    = cfg.Position or UDim2.new(0,40,0,60)

    local SG=Instance.new("ScreenGui",PGui)
    SG.Name=cfg.Name or "LordHub_GUI"
    SG.ResetOnSpawn=false
    SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    SG.DisplayOrder=100

    -- Main window glass
    local WIN,winSt=glass(SG,T.BG,T.BG_T,{
        Size=UDim2.new(0,width,0,height),
        Position=pos,
        ClipsDescendants=true,
    })
    cr(T.CORNER,WIN)
    winSt.Color=accent; winSt.Transparency=0.4

    -- Появление
    WIN.Position=UDim2.new(pos.X.Scale,pos.X.Offset,pos.Y.Scale,pos.Y.Offset-18)
    WIN.BackgroundTransparency=1
    tw(WIN,{
        BackgroundTransparency=T.BG_T,
        Position=pos,
    },0.35,Enum.EasingStyle.Back)

    -- ── Header ───────────────────────────────────────────────
    local HDR,hdrSt=glass(WIN,T.HDR,T.HDR_T,{
        Size=UDim2.new(1,0,0,30),
        ZIndex=5,
    })
    hdrSt.Transparency=0.75

    local hdrLine=Instance.new("Frame",HDR)
    hdrLine.Size=UDim2.new(1,0,0,1)
    hdrLine.Position=UDim2.new(0,0,1,-1)
    hdrLine.BackgroundColor3=accent
    hdrLine.BackgroundTransparency=0.5
    hdrLine.BorderSizePixel=0

    -- Collapse
    local colBtn=mkBtn(HDR,{
        Size=UDim2.new(0,22,0,22),
        Position=UDim2.new(0,4,0.5,-11),
        Text="▼",TextColor3=T.MUT,TextSize=10,ZIndex=6,
    })
    mkTxt(HDR,{
        Size=UDim2.new(1,-90,1,0),
        Position=UDim2.new(0,26,0,0),
        Text=title,TextColor3=T.TXT,
        Font=Enum.Font.GothamBold,TextSize=13,ZIndex=6,
    })

    -- Header right
    local hdrR=Instance.new("Frame",HDR)
    hdrR.Size=UDim2.new(0,66,1,0)
    hdrR.Position=UDim2.new(1,-68,0,0)
    hdrR.BackgroundTransparency=1; hdrR.BorderSizePixel=0; hdrR.ZIndex=6
    local hdrRL=Instance.new("UIListLayout",hdrR)
    hdrRL.FillDirection=Enum.FillDirection.Horizontal
    hdrRL.HorizontalAlignment=Enum.HorizontalAlignment.Right
    hdrRL.VerticalAlignment=Enum.VerticalAlignment.Center
    hdrRL.Padding=UDim.new(0,3)

    local function makeHBtn(icon,col)
        local bg,bgS=glass(hdrR,T.HDR,0.55,{
            Size=UDim2.new(0,20,0,20),ZIndex=7,
        })
        cr(T.CORNER_S,bg)
        bgS.Transparency=0.75
        local b=mkBtn(bg,{
            Size=UDim2.new(1,0,1,0),
            Text=icon,TextColor3=col or T.MUT,TextSize=13,ZIndex=8,
        })
        trackConn(b.MouseEnter:Connect(function()
            tw(bg,{BackgroundTransparency=0.2},.1)
            tw(b,{TextColor3=T.TXT},.1)
        end))
        trackConn(b.MouseLeave:Connect(function()
            tw(bg,{BackgroundTransparency=0.55},.1)
            tw(b,{TextColor3=col or T.MUT},.1)
        end))
        return b
    end

    local collapsed=false; local savedH=height
    colBtn.MouseButton1Click:Connect(function()
        collapsed=not collapsed
        if collapsed then
            savedH=WIN.AbsoluteSize.Y
            tw(WIN,{Size=UDim2.new(0,width,0,30)},0.22)
            colBtn.Text="▶"
        else
            tw(WIN,{Size=UDim2.new(0,width,0,savedH)},0.28,Enum.EasingStyle.Back)
            colBtn.Text="▼"
        end
    end)

    -- Drag
    local drag,dS,wS=false,nil,nil
    trackConn(HDR.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true; dS=i.Position; wS=WIN.Position
        end
    end))
    trackConn(HDR.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end))
    trackConn(UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-dS
            WIN.Position=UDim2.new(wS.X.Scale,wS.X.Offset+d.X,wS.Y.Scale,wS.Y.Offset+d.Y)
        end
    end))

    -- ── Tab Bar ──────────────────────────────────────────────
    local TABBAR,tbSt=glass(WIN,T.HDR,0.35,{
        Size=UDim2.new(1,0,0,26),
        Position=UDim2.new(0,0,0,30),
    })
    tbSt.Transparency=0.85
    local tabLL=Instance.new("UIListLayout",TABBAR)
    tabLL.FillDirection=Enum.FillDirection.Horizontal
    tabLL.SortOrder=Enum.SortOrder.LayoutOrder

    local tabBotLine=Instance.new("Frame",WIN)
    tabBotLine.Size=UDim2.new(1,0,0,1)
    tabBotLine.Position=UDim2.new(0,0,0,56)
    tabBotLine.BackgroundColor3=accent
    tabBotLine.BackgroundTransparency=0.5
    tabBotLine.BorderSizePixel=0

    -- Content
    local CONTENT=Instance.new("Frame",WIN)
    CONTENT.Size=UDim2.new(1,0,1,-57)
    CONTENT.Position=UDim2.new(0,0,0,57)
    CONTENT.BackgroundTransparency=1
    CONTENT.BorderSizePixel=0
    CONTENT.ClipsDescendants=true

    local tabs={}
    local activeTab=nil
    local tabCount=0

    local function makeScroll()
        local s=Instance.new("ScrollingFrame",CONTENT)
        s.Size=UDim2.new(1,0,1,0)
        s.BackgroundTransparency=1
        s.BorderSizePixel=0
        s.ScrollBarThickness=2
        s.ScrollBarImageColor3=accent
        s.CanvasSize=UDim2.new(0,0,0,0)
        s.Visible=false
        s.ScrollingDirection=Enum.ScrollingDirection.Y
        local sl=Instance.new("UIListLayout",s)
        sl.Padding=UDim.new(0,0)
        sl.SortOrder=Enum.SortOrder.LayoutOrder
        sl.HorizontalAlignment=Enum.HorizontalAlignment.Center
        sl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            s.CanvasSize=UDim2.new(0,0,0,sl.AbsoluteContentSize.Y+8)
        end)
        return s
    end

    local function switchTab(name)
        if activeTab==name then return end
        if activeTab and tabs[activeTab] then
            local old=tabs[activeTab]
            old.scroll.Visible=false
            tw(old.btn,{TextColor3=T.MUT},.15)
            tw(old.ul,{BackgroundTransparency=1},.15)
        end
        activeTab=name
        local new=tabs[name]
        new.scroll.Visible=true
        tw(new.btn,{TextColor3=T.TXT},.15)
        tw(new.ul,{BackgroundTransparency=0.2},.15)
    end

    -- ── Section API ───────────────────────────────────────────
    local function makeSAPI(scroll, ac)
        ac=ac or accent
        local rowN=0
        local api={}

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
            local w=Instance.new("Frame",scroll)
            w.Size=UDim2.new(1,0,0,8)
            w.BackgroundTransparency=1
            w.BorderSizePixel=0
            w.LayoutOrder=rowN
            local f=Instance.new("Frame",w)
            f.Size=UDim2.new(1,-16,0,1)
            f.Position=UDim2.new(0,8,0.5,0)
            f.BackgroundColor3=T.SEP
            f.BackgroundTransparency=0.75
            f.BorderSizePixel=0
        end

        function api.SectionHeader(sTitle,ac2)
            ac2=ac2 or ac
            rowN=rowN+1
            local w=Instance.new("Frame",scroll)
            w.Size=UDim2.new(1,0,0,22)
            w.BackgroundTransparency=1
            w.BorderSizePixel=0
            w.LayoutOrder=rowN
            pd(w,0,8)

            local f,fS=glass(w,T.HDR,0.55,{
                Size=UDim2.new(1,0,1,0),
            })
            cr(T.CORNER_S,f)
            fS.Color=ac2; fS.Transparency=0.5

            mkTxt(f,{
                Size=UDim2.new(1,-10,1,0),
                Position=UDim2.new(0,10,0,0),
                Text="— "..tostring(sTitle),
                TextColor3=ac2,
                Font=Enum.Font.GothamBold,
                TextSize=10,
            })

            -- Slide up
            w.Position=UDim2.new(0,0,0,8)
            tw(w,{Position=UDim2.new(0,0,0,0)},0.28,Enum.EasingStyle.Back)
        end

        function api.Label(text,col,indent)
            rowN=rowN+1
            local w=Instance.new("Frame",scroll)
            w.Size=UDim2.new(1,0,0,18)
            w.BackgroundTransparency=1
            w.BorderSizePixel=0
            w.LayoutOrder=rowN
            local l=mkTxt(w,{
                Size=UDim2.new(1,-(indent or 8),1,0),
                Position=UDim2.new(0,indent or 8,0,0),
                Text=tostring(text),
                TextColor3=col or T.MUT,
                TextWrapped=true,
            })
            return l
        end

        function api.Button(text,col,cb)
            rowN=rowN+1
            col=col or T.BTN
            local w=Instance.new("Frame",scroll)
            w.Size=UDim2.new(1,0,0,32)
            w.BackgroundTransparency=1
            w.LayoutOrder=rowN
            pd(w,3,8)

            local f,fS=glass(w,col,0.40,{
                Size=UDim2.new(1,0,1,0),
            })
            cr(T.CORNER_S,f)
            fS.Transparency=0.65

            local b=mkBtn(f,{
                Size=UDim2.new(1,0,1,0),
                Text=tostring(text),
                TextColor3=T.TXT,
            })
            trackConn(b.MouseEnter:Connect(function()
                tw(f,{BackgroundTransparency=0.15},.12)
            end))
            trackConn(b.MouseLeave:Connect(function()
                tw(f,{BackgroundTransparency=0.40},.12)
            end))
            trackConn(b.MouseButton1Down:Connect(function()
                tw(f,{BackgroundTransparency=0.6,
                    Size=UDim2.new(0.97,0,0.88,0)},.08)
            end))
            trackConn(b.MouseButton1Up:Connect(function()
                tw(f,{BackgroundTransparency=0.40,
                    Size=UDim2.new(1,0,1,0)},.15,Enum.EasingStyle.Back)
            end))
            if cb then trackConn(b.MouseButton1Click:Connect(cb)) end
            return b
        end

        function api.Button2(t1,c1,t2,c2,cb1,cb2)
            rowN=rowN+1
            local w=Instance.new("Frame",scroll)
            w.Size=UDim2.new(1,0,0,32)
            w.BackgroundTransparency=1
            w.LayoutOrder=rowN
            pd(w,3,8)
            local inner=Instance.new("Frame",w)
            inner.Size=UDim2.new(1,0,1,0)
            inner.BackgroundTransparency=1
            local ul2=Instance.new("UIListLayout",inner)
            ul2.FillDirection=Enum.FillDirection.Horizontal
            ul2.Padding=UDim.new(0,6)

            local function mkB(t,col,cb)
                col=col or T.BTN
                local f,fS=glass(inner,col,0.40,{
                    Size=UDim2.new(0.5,-3,1,0),
                })
                cr(T.CORNER_S,f)
                fS.Transparency=0.65
                local b=mkBtn(f,{
                    Size=UDim2.new(1,0,1,0),
                    Text=tostring(t),TextSize=10,
                })
                trackConn(b.MouseEnter:Connect(function()
                    tw(f,{BackgroundTransparency=0.15},.12)
                end))
                trackConn(b.MouseLeave:Connect(function()
                    tw(f,{BackgroundTransparency=0.40},.12)
                end))
                trackConn(b.MouseButton1Down:Connect(function()
                    tw(f,{BackgroundTransparency=0.6,
                        Size=UDim2.new(0.47,-3,0.88,0)},.08)
                end))
                trackConn(b.MouseButton1Up:Connect(function()
                    tw(f,{BackgroundTransparency=0.40,
                        Size=UDim2.new(0.5,-3,1,0)},.15,Enum.EasingStyle.Back)
                end))
                if cb then trackConn(b.MouseButton1Click:Connect(cb)) end
                return b
            end
            return mkB(t1,c1,cb1), mkB(t2,c2,cb2)
        end

        function api.Input(ph,numeric,default,cb)
            rowN=rowN+1
            local w=Instance.new("Frame",scroll)
            w.Size=UDim2.new(1,0,0,30)
            w.BackgroundTransparency=1
            w.LayoutOrder=rowN
            pd(w,3,8)

            local f,fS=glass(w,T.ROW,T.ROW_T,{
                Size=UDim2.new(1,0,1,0),
            })
            cr(T.CORNER_S,f)
            fS.Transparency=0.65
            pd(f,0,8)

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
                tw(f,{BackgroundTransparency=0.25},.15)
                tw(fS,{Transparency=0.2,Color=ac},.15)
            end))
            trackConn(b.FocusLost:Connect(function()
                tw(f,{BackgroundTransparency=T.ROW_T},.15)
                tw(fS,{Transparency=0.65,Color=Color3.new(1,1,1)},.15)
                if cb then cb(b.Text) end
            end))
            return b
        end

        function api.Toggle(labelText,default,cb)
            default=default==true
            rowN=rowN+1
            local w=Instance.new("Frame",scroll)
            w.Size=UDim2.new(1,0,0,28)
            w.BackgroundTransparency=1
            w.BorderSizePixel=0
            w.LayoutOrder=rowN
            pd(w,0,8)

            local f,fS=glass(w,T.ROW,0.55,{
                Size=UDim2.new(1,0,1,0),
            })
            cr(T.CORNER_S,f)
            fS.Transparency=0.72

            mkTxt(f,{
                Size=UDim2.new(1,-52,1,0),
                Position=UDim2.new(0,10,0,0),
                Text=tostring(labelText),
            })

            local track,trS=glass(f,default and ac or T.ROW,
                default and 0.1 or 0.55,{
                Size=UDim2.new(0,34,0,18),
                Position=UDim2.new(1,-42,0.5,-9),
            })
            cr(9,track)
            trS.Transparency=0.6

            local knob=Instance.new("Frame",track)
            knob.Size=UDim2.new(0,14,0,14)
            knob.Position=default and UDim2.new(1,-16,0.5,-7)
                or UDim2.new(0,2,0.5,-7)
            knob.BackgroundColor3=Color3.new(1,1,1)
            knob.BorderSizePixel=0
            cr(7,knob)

            local on=default
            local cb2=mkBtn(f,{Size=UDim2.new(1,0,1,0),Text=""})
            trackConn(cb2.MouseEnter:Connect(function()
                tw(f,{BackgroundTransparency=0.35},.1)
            end))
            trackConn(cb2.MouseLeave:Connect(function()
                tw(f,{BackgroundTransparency=0.55},.1)
            end))
            trackConn(cb2.MouseButton1Click:Connect(function()
                on=not on
                if on then
                    tw(track,{BackgroundColor3=ac,BackgroundTransparency=0.1},.2)
                    tw(knob,{Position=UDim2.new(1,-16,0.5,-7)},
                        .2,Enum.EasingStyle.Back)
                else
                    tw(track,{BackgroundColor3=T.ROW,BackgroundTransparency=0.55},.2)
                    tw(knob,{Position=UDim2.new(0,2,0.5,-7)},
                        .2,Enum.EasingStyle.Back)
                end
                if cb then pcall(cb,on) end
            end))
            return {
                GetValue=function() return on end,
                SetValue=function(v)
                    on=v==true
                    track.BackgroundColor3=on and ac or T.ROW
                    track.BackgroundTransparency=on and 0.1 or 0.55
                    knob.Position=on and UDim2.new(1,-16,0.5,-7)
                        or UDim2.new(0,2,0.5,-7)
                end,
            }
        end

        function api.Dropdown(items,cb)
            rowN=rowN+1
            local cur=items[1] or "Select"
            local w=Instance.new("Frame",scroll)
            w.Size=UDim2.new(1,0,0,30)
            w.BackgroundTransparency=1
            w.LayoutOrder=rowN
            pd(w,3,8)

            local host,hostS=glass(w,T.ROW,T.ROW_T,{
                Size=UDim2.new(1,0,1,0),
            })
            cr(T.CORNER_S,host)

            local lbl2=mkTxt(host,{
                Size=UDim2.new(1,-26,1,0),
                Position=UDim2.new(0,10,0,0),
                Text=tostring(cur),
            })
            local arr=mkTxt(host,{
                Size=UDim2.new(0,20,1,0),
                Position=UDim2.new(1,-22,0,0),
                Text="▾",TextColor3=T.MUT,
                Font=Enum.Font.GothamBold,
                TextXAlignment=Enum.TextXAlignment.Center,
            })

            local popup,popS=glass(SG,T.BG,0.15,{
                ZIndex=150,Visible=false,
            })
            cr(T.CORNER_S,popup)
            popS.Color=ac; popS.Transparency=0.45

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
            pd(psl,4,5)
            psll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                psl.CanvasSize=UDim2.new(0,0,0,psll.AbsoluteContentSize.Y+10)
            end)

            local ddBtns={}

            local function closeDD()
                tw(popup,{BackgroundTransparency=1},0.15)
                task.delay(0.16,function()
                    popup.Visible=false
                    popup.BackgroundTransparency=0.15
                end)
                arr.Text="▾"
            end

            local function buildList(newItems)
                for _,b in ipairs(ddBtns) do b:Destroy() end
                ddBtns={}
                for i,item in ipairs(newItems) do
                    local ib,ibS=glass(psl,T.ROW,0.75,{
                        Size=UDim2.new(1,0,0,24),
                        ZIndex=152,LayoutOrder=i,
                    })
                    cr(T.CORNER_S,ib)
                    ibS.Transparency=0.80

                    local ibb=mkBtn(ib,{
                        Size=UDim2.new(1,0,1,0),
                        Text=tostring(item),
                        TextSize=11,ZIndex=153,
                        TextXAlignment=Enum.TextXAlignment.Left,
                    })
                    pd(ibb,0,8)
                    trackConn(ibb.MouseEnter:Connect(function()
                        tw(ib,{BackgroundTransparency=0.35},.1)
                    end))
                    trackConn(ibb.MouseLeave:Connect(function()
                        tw(ib,{BackgroundTransparency=0.75},.1)
                    end))
                    trackConn(ibb.MouseButton1Click:Connect(function()
                        cur=item; lbl2.Text=tostring(item)
                        closeDD()
                        if cb then cb(item) end
                    end))
                    table.insert(ddBtns,ib)
                end
            end

            buildList(items)

            local hostBtn=mkBtn(host,{Size=UDim2.new(1,0,1,0),Text=""})
            trackConn(hostBtn.MouseEnter:Connect(function()
                tw(host,{BackgroundTransparency=0.25},.12)
            end))
            trackConn(hostBtn.MouseLeave:Connect(function()
                tw(host,{BackgroundTransparency=T.ROW_T},.12)
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
            local w=Instance.new("Frame",scroll)
            w.Size=UDim2.new(1,0,0,14+(lines or 1)*14)
            w.BackgroundTransparency=1
            w.LayoutOrder=rowN
            pd(w,3,8)
            local f,fS=glass(w,T.HDR,0.40,{
                Size=UDim2.new(1,0,1,0),
            })
            cr(T.CORNER_S,f)
            fS.Transparency=0.72
            pd(f,4,8)
            local l=mkTxt(f,{
                Size=UDim2.new(1,0,1,0),
                Text="",TextColor3=T.MUT,
                TextSize=10,TextWrapped=true,
                TextYAlignment=Enum.TextYAlignment.Top,
            })
            return l
        end

        function api.ProgressBar()
            rowN=rowN+1
            local w=Instance.new("Frame",scroll)
            w.Size=UDim2.new(1,0,0,8)
            w.BackgroundTransparency=1
            w.LayoutOrder=rowN
            pd(w,1,8)
            local bg,bgS=glass(w,T.ROW,0.40,{
                Size=UDim2.new(1,0,1,0),
            })
            cr(4,bg); bgS.Transparency=0.80

            local fill=Instance.new("Frame",bg)
            fill.Size=UDim2.new(0,0,1,0)
            fill.BackgroundColor3=ac
            fill.BackgroundTransparency=0.05
            fill.BorderSizePixel=0
            cr(4,fill)

            local sh=Instance.new("Frame",fill)
            sh.Size=UDim2.new(0,30,1,0)
            sh.BackgroundColor3=Color3.new(1,1,1)
            sh.BackgroundTransparency=0.72
            sh.BorderSizePixel=0
            cr(4,sh)
            task.spawn(function()
                while sh.Parent do
                    sh.Position=UDim2.new(0,-30,0,0)
                    tw(sh,{Position=UDim2.new(1,0,0,0)},1.3,Enum.EasingStyle.Linear)
                    task.wait(1.5)
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
                    local w2=Instance.new("Frame",f)
                    w2.Size=UDim2.new(1,0,0,24)
                    w2.BackgroundTransparency=1
                    w2.BorderSizePixel=0
                    w2.LayoutOrder=i
                    pd(w2,0,8)

                    local row,rowS=glass(w2,ac,0.78,{
                        Size=UDim2.new(1,0,1,0),
                    })
                    cr(T.CORNER_S,row)
                    rowS.Transparency=0.65

                    local rb=mkBtn(row,{
                        Size=UDim2.new(1,0,1,0),
                        Text=tostring(item),TextSize=11,
                        TextXAlignment=Enum.TextXAlignment.Left,
                    })
                    pd(rb,0,10)
                    trackConn(rb.MouseEnter:Connect(function()
                        if selRow~=row then
                            tw(row,{BackgroundTransparency=0.50},.1)
                        end
                    end))
                    trackConn(rb.MouseLeave:Connect(function()
                        if selRow~=row then
                            tw(row,{BackgroundTransparency=0.78},.1)
                        end
                    end))
                    trackConn(rb.MouseButton1Click:Connect(function()
                        if selRow then tw(selRow,{BackgroundTransparency=0.78},.1) end
                        selRow=row
                        tw(row,{BackgroundTransparency=0.25},.15)
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
            local w=Instance.new("Frame",scroll)
            w.Size=UDim2.new(1,0,0,0)
            w.BackgroundTransparency=1
            w.BorderSizePixel=0
            w.LayoutOrder=rowN
            w.AutomaticSize=Enum.AutomaticSize.Y
            pd(w,4,8)
            local l=mkTxt(w,{
                Size=UDim2.new(1,0,0,0),
                Text=tostring(text),TextColor3=T.MUT,
                TextSize=10,TextWrapped=true,
                AutomaticSize=Enum.AutomaticSize.Y,
            })
            return l
        end

        return api
    end

    -- ── WIN объект ────────────────────────────────────────────
    local WIN_OBJ={}
    WIN_OBJ.WIN=WIN; WIN_OBJ.SG=SG; WIN_OBJ.Tabs=tabs

    function WIN_OBJ.AddTab(tabName,tabLabel,tabOrder)
        tabCount=tabCount+1

        -- Tab кнопка
        local tabWrap=Instance.new("Frame",TABBAR)
        tabWrap.BackgroundTransparency=1
        tabWrap.BorderSizePixel=0
        tabWrap.LayoutOrder=tabOrder or tabCount

        local btn=mkBtn(tabWrap,{
            Size=UDim2.new(1,0,1,0),
            Text=tabLabel or tabName,
            TextColor3=T.MUT,
            TextSize=10,
            ZIndex=4,
        })

        local ul=Instance.new("Frame",tabWrap)
        ul.Size=UDim2.new(0.8,0,0,2)
        ul.Position=UDim2.new(0.1,0,1,-2)
        ul.BackgroundColor3=accent
        ul.BackgroundTransparency=1
        ul.BorderSizePixel=0

        local scr=makeScroll()
        tabs[tabName]={btn=btn,scroll=scr,ul=ul,wrap=tabWrap}

        -- Пересчёт ширин
        local function recalc()
            local cnt=0
            for _ in pairs(tabs) do cnt=cnt+1 end
            local bw=math.floor(width/cnt)
            for _,t in pairs(tabs) do
                t.wrap.Size=UDim2.new(0,bw,1,0)
            end
        end
        recalc()

        trackConn(btn.MouseEnter:Connect(function()
            if activeTab~=tabName then
                tw(btn,{TextColor3=T.TXT:Lerp(T.MUT,0.3)},.1)
            end
        end))
        trackConn(btn.MouseLeave:Connect(function()
            if activeTab~=tabName then
                tw(btn,{TextColor3=T.MUT},.1)
            end
        end))
        trackConn(btn.MouseButton1Click:Connect(function()
            switchTab(tabName)
        end))

        if not activeTab then switchTab(tabName) end

        WIN_OBJ.Tabs=tabs

        local sapi=makeSAPI(scr,accent)

        -- TabAPI обёртка
        local tabAPI={}
        function tabAPI.Section(sTitle,ac2)
            sapi.SectionHeader(sTitle,ac2)
            sapi.Space(2)
            return sapi
        end
        for k,v in pairs(sapi) do
            if not tabAPI[k] then tabAPI[k]=v end
        end
        return tabAPI
    end

    function WIN_OBJ.AddHeaderButton(icon,col,cb)
        local b=makeHBtn(icon,col)
        if cb then trackConn(b.MouseButton1Click:Connect(cb)) end
        return b
    end

    function WIN_OBJ.SwitchTab(name)
        if tabs[name] then switchTab(name) end
    end

    function WIN_OBJ.Destroy() SG:Destroy() end

    -- INSERT hide/show
    trackConn(UIS.InputBegan:Connect(function(i,gpe)
        if gpe then return end
        if i.KeyCode==Enum.KeyCode.Insert then
            WIN.Visible=not WIN.Visible
        end
    end))

    return WIN_OBJ
end

return LordHubLib
