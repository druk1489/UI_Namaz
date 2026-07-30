-- Mythos Loader v2 (runtime-patch)
-- Fetches modules from GitHub and patches them before loadstring.
-- Repo: druk1489/UI_Namaz

local REPO = "https://raw.githubusercontent.com/druk1489/UI_Namaz/main/"

-- ================================================================
-- HTTP
-- ================================================================
local function httpGet(url)
    local ok, res
    if syn and syn.request then
        ok, res = pcall(function() return syn.request({Url = url, Method = "GET"}).Body end)
        if ok and res then return res end
    end
    if http and http.request then
        ok, res = pcall(function() return http.request({Url = url, Method = "GET"}).Body end)
        if ok and res then return res end
    end
    if request then
        ok, res = pcall(function() return request({Url = url, Method = "GET"}).Body end)
        if ok and res then return res end
    end
    ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res then return res end
    return nil
end

local function notify(t, m)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title=t, Text=m, Duration=4})
    end)
    print("[Mythos] " .. t .. ": " .. m)
end

-- ================================================================
-- PATCHERS (by file name)
-- ================================================================
local PATCHERS = {}

-- -- ADMIN --------------------------------------------------------
PATCHERS["mythos_admin.lua"] = function(src)
    local n = 0
    do
        local s = src:find("addcmd%('clientantikick'", 1, false)
        if s then
            local e = src:find("\n\tnotify%('Client Antikick'", s, false)
            if e then
                local e2 = src:find("\nend%)\n", e, false)
                if e2 then
                    src = src:sub(1, s-1) ..
                          "addcmd('clientantikick',{'antikick'},function() notify('Antikick','Disabled in Mythos (broken source)') end)" ..
                          src:sub(e2 + 5)
                    n = n + 1
                end
            end
        end
    end
    do
        local s = src:find("addcmd%('clientantiteleport'", 1, false)
        if s then
            local e = src:find("\n\tnotify%('Client AntiTP'", s, false)
            if e then
                local e2 = src:find("\nend%)\n", e, false)
                if e2 then
                    src = src:sub(1, s-1) ..
                          "addcmd('clientantiteleport',{'antiteleport'},function() notify('AntiTP','Disabled in Mythos (broken source)') end)" ..
                          src:sub(e2 + 5)
                    n = n + 1
                end
            end
        end
    end
    return src, n
end

-- -- EXPLORER -----------------------------------------------------
PATCHERS["mythos_explorer.lua"] = function(src)
    local n = 0
    local new, c = src:gsub(
        'env%.game:GetService%("CoreGui"%) = game:GetService%("CoreGui"%)',
        'env.CoreGui = game:GetService("CoreGui")'
    )
    if c > 0 then src = new; n = n + c end
    new, c = src:gsub("env%.{}", "(env.getnilinstances and env.getnilinstances() or {})")
    if c > 0 then src = new; n = n + c end
    return src, n
end

-- -- VR ----------------------------------------------------------
PATCHERS["mythos_vr.lua"] = function(src)
    local n = 0
    local new, c
    new, c = src:gsub(
        'VirtualBody:FindFirstChildOfClass%("Humanoid"%)%.Jump = true',
        'local _h = VirtualBody and VirtualBody:FindFirstChildOfClass("Humanoid"); if _h then _h.Jump = true end'
    )
    if c > 0 then src = new; n = n + c end
    new, c = src:gsub(
        'local ViewHUD = script:FindFirstChild%("ViewHUD"%) or game:GetObjects%("rbxassetid://4480405425"%)%[1%]',
        'local ViewHUD; local _okv,_rv = pcall(function() return game:GetObjects("rbxassetid://4480405425")[1] end); if _okv then ViewHUD = _rv end; if not ViewHUD then warn("[Mythos VR] ViewHUD asset failed"); return end'
    )
    if c > 0 then src = new; n = n + c end
    return src, n
end

-- -- AUDIO LOGGER ------------------------------------------------
PATCHERS["mythos_audiologger.lua"] = function(src)
    local n = 0
    local new, c = src:gsub(
        'aa = game:GetObjects%("rbxassetid://01997056190"%)%[1%]',
        'local _oka,_ra = pcall(function() return game:GetObjects("rbxassetid://01997056190")[1] end); if not _oka or not _ra then warn("[Mythos Audio] asset failed"); return end; aa = _ra'
    )
    if c > 0 then src = new; n = n + c end
    return src, n
end

-- ================================================================
-- LOAD MODULE
-- ================================================================
local function loadModule(name, label)
    notify("Mythos", "-> " .. label)
    local src = httpGet(REPO .. name)
    if not src or #src < 100 then
        notify("Mythos", "X " .. label .. ": HTTP fail")
        return false
    end
    local patcher = PATCHERS[name]
    if patcher then
        local ok, patched, patchCount = pcall(patcher, src)
        if ok and patched then
            src = patched
            print("[Mythos Loader] patched " .. label .. " (" .. tostring(patchCount) .. " patches)")
        else
            warn("[Mythos Loader] patcher error on " .. label)
        end
    end
    local fn, err = loadstring(src, "=" .. name)
    if not fn then
        warn("[Mythos Loader] X compile " .. label .. ":\n" .. tostring(err))
        notify("Mythos", "X " .. label .. " compile error")
        return false
    end
    local ok, runErr = pcall(fn)
    if not ok then
        warn("[Mythos Loader] X runtime " .. label .. ":\n" .. tostring(runErr))
        notify("Mythos", "X " .. label .. " runtime error")
        return false
    end
    notify("Mythos", "OK " .. label)
    return true
end

-- ================================================================
-- MODULES + UI
-- ================================================================
local MODULES = {
    {name = "mythos_admin.lua",       label = "Core Admin",   default = true},
    {name = "mythos_explorer.lua",    label = "Explorer",     default = false},
    {name = "mythos_vr.lua",          label = "VR Tools",     default = false},
    {name = "mythos_audiologger.lua", label = "Audio Logger", default = false},
    -- Console excluded: DeveloperConsole init cannot be loadstring'd
    -- (it requires sibling ModuleScripts under script.Modules.*)
}

local function buildUI()
    local player = game:GetService("Players").LocalPlayer
    local parent = player:WaitForChild("PlayerGui")
    pcall(function() if gethui then parent = gethui() end end)

    local existing = parent:FindFirstChild("MythosLoader")
    if existing then existing:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "MythosLoader"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 260, 0, 320)
    frame.Position = UDim2.new(0.5, -130, 0.5, -160)
    frame.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 36)
    title.BackgroundColor3 = Color3.fromRGB(38, 38, 42)
    title.BorderSizePixel = 0
    title.Text = "MYTHOS LOADER v2"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Parent = frame
    local tCorner = Instance.new("UICorner", title); tCorner.CornerRadius = UDim.new(0, 8)

    local list = Instance.new("Frame")
    list.Position = UDim2.new(0, 10, 0, 44)
    list.Size = UDim2.new(1, -20, 1, -100)
    list.BackgroundTransparency = 1
    list.Parent = frame
    local layout = Instance.new("UIListLayout", list); layout.Padding = UDim.new(0, 6)

    local state = {}
    for _, mod in ipairs(MODULES) do
        state[mod.name] = mod.default
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, 0, 0, 32)
        row.BackgroundColor3 = Color3.fromRGB(40, 40, 44)
        row.BorderSizePixel = 0
        row.Text = ""
        row.AutoButtonColor = false
        row.Parent = list
        local rc = Instance.new("UICorner", row); rc.CornerRadius = UDim.new(0, 4)

        local check = Instance.new("Frame")
        check.Size = UDim2.new(0, 14, 0, 14)
        check.Position = UDim2.new(0, 10, 0.5, -7)
        check.BackgroundColor3 = mod.default and Color3.fromRGB(90, 200, 90) or Color3.fromRGB(70, 70, 74)
        check.BorderSizePixel = 0
        check.Parent = row
        local cc = Instance.new("UICorner", check); cc.CornerRadius = UDim.new(0, 3)

        local lbl = Instance.new("TextLabel")
        lbl.Position = UDim2.new(0, 34, 0, 0)
        lbl.Size = UDim2.new(1, -40, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = mod.label
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextColor3 = Color3.fromRGB(230, 230, 230)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        row.MouseButton1Click:Connect(function()
            state[mod.name] = not state[mod.name]
            check.BackgroundColor3 = state[mod.name] and Color3.fromRGB(90, 200, 90) or Color3.fromRGB(70, 70, 74)
        end)
    end

    local loadBtn = Instance.new("TextButton")
    loadBtn.Position = UDim2.new(0, 10, 1, -46)
    loadBtn.Size = UDim2.new(1, -20, 0, 36)
    loadBtn.BackgroundColor3 = Color3.fromRGB(90, 130, 220)
    loadBtn.BorderSizePixel = 0
    loadBtn.Text = "LOAD SELECTED"
    loadBtn.Font = Enum.Font.GothamBold
    loadBtn.TextSize = 14
    loadBtn.TextColor3 = Color3.new(1, 1, 1)
    loadBtn.Parent = frame
    local lbc = Instance.new("UICorner", loadBtn); lbc.CornerRadius = UDim.new(0, 4)

    loadBtn.MouseButton1Click:Connect(function()
        loadBtn.Text = "LOADING..."
        loadBtn.Active = false
        task.spawn(function()
            for _, mod in ipairs(MODULES) do
                if state[mod.name] then
                    loadModule(mod.name, mod.label)
                    task.wait(0.15)
                end
            end
            loadBtn.Text = "DONE - CLOSE"
            loadBtn.Active = true
            loadBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
        end)
    end)
end

local ok, err = pcall(buildUI)
if not ok then warn("[Mythos Loader] UI error: " .. tostring(err)) end
