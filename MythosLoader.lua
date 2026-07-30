-- ================================================================
-- MYTHOS LOADER
-- Грузит модули с GitHub и патчит их на лету (для Solar/Solara)
-- ================================================================

local REPO_URL  = "https://raw.githubusercontent.com/druk1489/UI_Namaz/main/"

local MODULES = {
    { name = "Core Admin",   file = "mythos_admin.lua",       default = true  },
    { name = "Explorer",     file = "mythos_explorer.lua",    default = false },
    { name = "Console",      file = "mythos_console.lua",     default = false },
    { name = "VR Tools",     file = "mythos_vr.lua",          default = false },
    { name = "Audio Logger", file = "mythos_audiologger.lua", default = false },
}

-- ----------------------------------------------------------------
-- РАНТАЙМ-ПАТЧИ (фиксят несовместимости Solara/Solar)
-- ----------------------------------------------------------------
local PATCHES = {
    ["mythos_admin.lua"] = {
        { pattern = 'and "":lower() == "kick"', replace = 'and method:lower() == "kick"', plain = true },
    },
    ["mythos_explorer.lua"] = {
        { pattern = 'env.{}', replace = '(env.getnilinstances and env.getnilinstances() or {})', plain = true },
    },
    ["mythos_console.lua"] = {
    },
    ["mythos_vr.lua"] = {
        { pattern = 'character1.HumanoidRootPart', replace = '(character1 and (character1:FindFirstChild("HumanoidRootPart") or character1:WaitForChild("HumanoidRootPart",5)))', plain = true },
        { pattern = 'AutoRespawn = true', replace = 'AutoRespawn = false', plain = true },
        { pattern = 'RagdollHeadMovement = true', replace = 'RagdollHeadMovement = false', plain = true },
        { pattern = 'local sethidden = sethiddenproperty or set_hidden_property or setscriptable', replace = 'local sethidden = function() end -- disabled in Solara', plain = true },
    },
    ["mythos_audiologger.lua"] = {
        { pattern = 'aa = game:GetObjects("rbxassetid://01997056190")[1]', replace = 'local _ok,_r=pcall(function() return game:GetObjects("rbxassetid://01997056190")[1] end); if not _ok or not _r then warn("[Mythos] AudioLogger GUI не загрузился") return end; aa=_r', plain = true },
    },
}

local function escapePattern(s)
    return (s:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"))
end
local function escapeReplace(s)
    return (s:gsub("%%", "%%%%"))
end

local function applyPatches(fileName, source)
    local patches = PATCHES[fileName]
    local total = 0
    if patches then
        for _, p in ipairs(patches) do
            local pat = p.plain and escapePattern(p.pattern) or p.pattern
            local rep = p.plain and escapeReplace(p.replace) or p.replace
            local new, n = source:gsub(pat, rep)
            if n > 0 then
                source = new
                total = total + n
            end
        end
    end
    if fileName == "mythos_console.lua" then
        source = source:gsub(
            'require%(([^%)]+CoreGui[^%)]+)%)',
            '(function() local _o,_r=pcall(require,%1); if _o then return _r else warn("[Mythos] require failed: ".._r); return {} end end)()'
        )
    end
    return source, total
end

local function httpGet(url)
    if syn and syn.request then
        local r = syn.request({ Url = url, Method = "GET" })
        if r.StatusCode == 200 then return r.Body end
        error("HTTP " .. r.StatusCode)
    elseif http and http.request then
        local r = http.request({ Url = url, Method = "GET" })
        if r.StatusCode == 200 then return r.Body end
        error("HTTP " .. r.StatusCode)
    elseif request then
        local r = request({ Url = url, Method = "GET" })
        if r.StatusCode == 200 then return r.Body end
        error("HTTP " .. r.StatusCode)
    elseif game.HttpGet then
        local ok, body = pcall(function() return game:HttpGet(url) end)
        if ok and body and #body > 0 then return body end
        error("HttpGet failed")
    else
        error("Нет HTTP-функции в этом эксплойте")
    end
end

local function loadModule(mod)
    local url = REPO_URL .. mod.file
    local ok, result = pcall(httpGet, url)
    if not ok then
        warn("[Mythos Loader] ❌ " .. mod.name .. " — " .. tostring(result))
        return false
    end

    local patched, count = applyPatches(mod.file, result)
    if count > 0 then
        print(("[Mythos Loader] 🔧 %s — применено %d патчей"):format(mod.name, count))
    end

    local fn, err = loadstring(patched)
    if not fn then
        warn("[Mythos Loader] ❌ Компиляция " .. mod.name .. ":\n" .. tostring(err))
        return false
    end
    local ok2, err2 = pcall(fn)
    if not ok2 then
        warn("[Mythos Loader] ❌ Выполнение " .. mod.name .. ":\n" .. tostring(err2))
        return false
    end
    return true
end

local function buildUI()
    local lp = game:GetService("Players").LocalPlayer
    local pg = lp:FindFirstChild("PlayerGui")
    if not pg then
        warn("[Mythos Loader] PlayerGui не найден, грузим default-модули")
        for _, m in ipairs(MODULES) do
            if m.default then
                print("[Mythos Loader] Загружаю: " .. m.name)
                loadModule(m)
            end
        end
        return
    end

    local old = pg:FindFirstChild("MythosLoader")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name           = "MythosLoader"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent         = pg

    local frame = Instance.new("Frame")
    frame.Name             = "Main"
    frame.Size             = UDim2.new(0, 320, 0, 60 + #MODULES * 44)
    frame.Position         = UDim2.new(0.5, -160, 0.5, -(30 + #MODULES * 22))
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    frame.BorderSizePixel  = 0
    frame.Active           = true
    frame.Draggable        = true
    frame.Parent           = gui
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 10); corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Text             = "✦ MYTHOS LOADER"
    title.Size             = UDim2.new(1, 0, 0, 38)
    title.BackgroundColor3 = Color3.fromRGB(90, 40, 160)
    title.TextColor3       = Color3.new(1, 1, 1)
    title.Font             = Enum.Font.GothamBold
    title.TextSize         = 16
    title.Parent           = frame
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 10); tc.Parent = title

    local closeBtn = Instance.new("TextButton")
    closeBtn.Text                   = "✕"
    closeBtn.Size                   = UDim2.new(0, 30, 0, 30)
    closeBtn.Position               = UDim2.new(1, -34, 0, 4)
    closeBtn.BackgroundTransparency = 1
    closeBtn.TextColor3             = Color3.new(1, 1, 1)
    closeBtn.Font                   = Enum.Font.GothamBold
    closeBtn.TextSize               = 16
    closeBtn.Parent                 = title
    closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Text                   = "Выбери модули и нажми Load"
    statusLbl.Size                   = UDim2.new(1, -20, 0, 20)
    statusLbl.Position               = UDim2.new(0, 10, 0, 42)
    statusLbl.BackgroundTransparency = 1
    statusLbl.TextColor3             = Color3.fromRGB(160, 160, 180)
    statusLbl.Font                   = Enum.Font.Gotham
    statusLbl.TextSize               = 12
    statusLbl.TextXAlignment         = Enum.TextXAlignment.Left
    statusLbl.Parent                 = frame

    local selected  = {}
    local checkBtns = {}
    for i, m in ipairs(MODULES) do
        selected[i] = m.default

        local row = Instance.new("Frame")
        row.Size             = UDim2.new(1, -20, 0, 36)
        row.Position         = UDim2.new(0, 10, 0, 58 + (i - 1) * 40)
        row.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
        row.BorderSizePixel  = 0
        row.Parent           = frame
        local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 7); rc.Parent = row

        local chk = Instance.new("TextButton")
        chk.Size             = UDim2.new(0, 26, 0, 26)
        chk.Position         = UDim2.new(0, 5, 0.5, -13)
        chk.BackgroundColor3 = selected[i] and Color3.fromRGB(90, 40, 160) or Color3.fromRGB(50, 50, 62)
        chk.Text             = selected[i] and "✓" or ""
        chk.TextColor3       = Color3.new(1, 1, 1)
        chk.Font             = Enum.Font.GothamBold
        chk.TextSize         = 14
        chk.BorderSizePixel  = 0
        chk.Parent           = row
        local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 5); cc.Parent = chk
        checkBtns[i] = chk

        local lbl = Instance.new("TextLabel")
        lbl.Text                   = m.name
        lbl.Size                   = UDim2.new(1, -80, 1, 0)
        lbl.Position               = UDim2.new(0, 38, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3             = Color3.new(1, 1, 1)
        lbl.Font                   = Enum.Font.Gotham
        lbl.TextSize               = 13
        lbl.TextXAlignment         = Enum.TextXAlignment.Left
        lbl.Parent                 = row

        local fileLbl = Instance.new("TextLabel")
        fileLbl.Text                   = m.file
        fileLbl.Size                   = UDim2.new(0, 165, 0, 14)
        fileLbl.Position               = UDim2.new(1, -168, 0.5, -7)
        fileLbl.BackgroundTransparency = 1
        fileLbl.TextColor3             = Color3.fromRGB(100, 100, 120)
        fileLbl.Font                   = Enum.Font.Code
        fileLbl.TextSize               = 10
        fileLbl.TextXAlignment         = Enum.TextXAlignment.Right
        fileLbl.Parent                 = row

        local idx = i
        chk.MouseButton1Click:Connect(function()
            selected[idx] = not selected[idx]
            chk.BackgroundColor3 = selected[idx] and Color3.fromRGB(90, 40, 160) or Color3.fromRGB(50, 50, 62)
            chk.Text             = selected[idx] and "✓" or ""
        end)
    end

    local loadBtn = Instance.new("TextButton")
    loadBtn.Text             = "⬇  LOAD SELECTED"
    loadBtn.Size             = UDim2.new(1, -20, 0, 34)
    loadBtn.Position         = UDim2.new(0, 10, 1, -42)
    loadBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 160)
    loadBtn.TextColor3       = Color3.new(1, 1, 1)
    loadBtn.Font             = Enum.Font.GothamBold
    loadBtn.TextSize         = 14
    loadBtn.BorderSizePixel  = 0
    loadBtn.Parent           = frame
    local lbc = Instance.new("UICorner"); lbc.CornerRadius = UDim.new(0, 7); lbc.Parent = loadBtn

    loadBtn.MouseButton1Click:Connect(function()
        loadBtn.Text             = "⏳ Загружаю..."
        loadBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        local loaded, failed = 0, 0
        for i, m in ipairs(MODULES) do
            if selected[i] then
                statusLbl.Text = "→ " .. m.name .. "..."
                task.wait()
                if loadModule(m) then
                    loaded = loaded + 1
                    checkBtns[i].BackgroundColor3 = Color3.fromRGB(30, 140, 60)
                else
                    failed = failed + 1
                    checkBtns[i].BackgroundColor3 = Color3.fromRGB(160, 40, 40)
                end
            end
        end
        statusLbl.Text = ("✅ %d загружено"):format(loaded)
            .. (failed > 0 and ("  ❌ %d ошибок"):format(failed) or "")
        loadBtn.Text             = "✓ ГОТОВО — закрыть"
        loadBtn.BackgroundColor3 = Color3.fromRGB(30, 120, 50)
        loadBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
    end)

    return gui
end

buildUI()
