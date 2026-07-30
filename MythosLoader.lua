-- Mythos Loader v6
-- Auto-loads Core Admin. Injects ;dex / ;vr / ;audiologger as admin sub-cmds.
-- Fixes Solara-mutilated commands (stripped firetouchinterest / hookmetamethod calls).
-- Repo: druk1489/UI_Namaz

local REPO = "https://raw.githubusercontent.com/druk1489/UI_Namaz/main/"

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

local function say(t, m)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title=t, Text=m, Duration=4})
    end)
    print("[Mythos] " .. t .. ": " .. m)
end

-- ============================================================
-- cutKeep: replace [startLit .. beforeKeepLit) with `replacement`.
--   `keepLit` is the FIRST character of the region we want to keep.
--   We do NOT consume `keepLit` — replacement must supply its own separator/end).
-- ============================================================
local function cutKeep(src, startLit, keepLit, replacement)
    local s = src:find(startLit, 1, true)
    if not s then return src, false end
    local e = src:find(keepLit, s, true)
    if not e then return src, false end
    return src:sub(1, s - 1) .. replacement .. src:sub(e), true
end

-- cutNotify: for antikick/antiteleport where next boundary isn't a clean addcmd.
--   Find the block, then the `notify` sentinel inside it, then consume up to and
--   INCLUDING the following `\nend)\n`.
local function cutNotify(src, startLit, notifyLit, replacement)
    local s = src:find(startLit, 1, true)
    if not s then return src, false end
    local nm = src:find(notifyLit, s, true)
    if not nm then return src, false end
    local e2 = src:find("\nend)\n", nm, true)
    if not e2 then return src, false end
    -- "\nend)\n" is 7 bytes: keep from e2+7 (Lua string.sub is 1-indexed)
    return src:sub(1, s - 1) .. replacement .. src:sub(e2 + 7), true
end

-- ============================================================
-- Admin patcher
-- ============================================================
local function patchAdmin(src)
    local n = 0
    local ok

    src, ok = cutNotify(src, "addcmd('clientantikick'", "\n\tnotify('Client Antikick'",
        "addcmd('clientantikick',{'antikick'},function() notify('Antikick','Disabled') end)\n")
    if ok then n = n + 1 end

    src, ok = cutNotify(src, "addcmd('clientantiteleport'", "\n\tnotify('Client AntiTP'",
        "addcmd('clientantiteleport',{'antiteleport'},function() notify('AntiTP','Disabled') end)\n")
    if ok then n = n + 1 end

    src, ok = cutKeep(src, "addcmd('spoofspeed'", "addcmd('loopspeed'",
        "addcmd('spoofspeed',{'spoofws','spoofwalkspeed'},function() notify('SpoofSpeed','Disabled') end)\n\n")
    if ok then n = n + 1 end

    src, ok = cutKeep(src, "addcmd('spoofjumppower'", "addcmd('loopjumppower'",
        "addcmd('spoofjumppower',{'spoofjp'},function() notify('SpoofJump','Disabled') end)\n\n")
    if ok then n = n + 1 end

    src, ok = cutKeep(src, "addcmd('clearhats'", "addcmd('vr'",
        "addcmd('clearhats',{'cleanhats'},function()\n\tfor _,v in pairs(Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid'):GetAccessories()) do pcall(function() v:Destroy() end) end\n\tnotify('ClearHats','Removed (no-fire)')\nend)\n\n")
    if ok then n = n + 1 end

    src, ok = cutKeep(src, "addcmd('dupetools'", "local RS = RunService.RenderStepped",
        "addcmd('dupetools',{'clonetools'},function() notify('DupeTools','Disabled (broken source)') end)\n\n")
    if ok then n = n + 1 end

    src, ok = cutKeep(src, "addcmd('givetool'", "addcmd('touchinterests'",
        "addcmd('givetool',{'givetools'},function() notify('GiveTool','Disabled (broken source)') end)\n\n")
    if ok then n = n + 1 end

    src, ok = cutKeep(src, "addcmd('touchinterests'", "addcmd('fullbright'",
        "addcmd('touchinterests',{'touchinterest','firetouchinterests','firetouchinterest'},function() notify('TouchInterests','Disabled (broken source)') end)\n\n")
    if ok then n = n + 1 end

    src, ok = cutKeep(src, "addcmd('handlekill'", "local hb = RunService.Heartbeat",
        "addcmd('handlekill',{'hkill'},function() notify('HandleKill','Disabled (broken source)') end)\n\n")
    if ok then n = n + 1 end

    -- INJECT sub-cmds
    local INJECT = [==[

-- ================================================================
-- MYTHOS: dynamically-loaded sub-modules as admin commands
-- ================================================================
do
    local REPO = "]==] .. REPO .. [==["

    local function _httpGet(url)
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

    local _loadedFlags = {}

    local function _run(label, file, patcher, once)
        if once and _loadedFlags[file] then
            notify("Mythos", label .. " already loaded")
            return
        end
        notify("Mythos", "Loading " .. label .. "...")
        local src = _httpGet(REPO .. file)
        if not src or #src < 100 then
            notify("Mythos", label .. " download failed")
            return
        end
        if patcher then
            local ok, patched = pcall(patcher, src)
            if ok and patched then src = patched end
        end
        local fn, err = loadstring(src, "=" .. file)
        if not fn then
            notify("Mythos", label .. " compile err: " .. tostring(err))
            return
        end
        local ok, runErr = pcall(fn)
        if not ok then
            notify("Mythos", label .. " runtime err: " .. tostring(runErr))
            return
        end
        _loadedFlags[file] = true
        notify("Mythos", label .. " loaded OK")
    end

    local function patchExplorer(src)
        src = src:gsub(
            'env%.game:GetService%("CoreGui"%) = game:GetService%("CoreGui"%)',
            'env.CoreGui = game:GetService("CoreGui")'
        )
        src = src:gsub("env%.{}", "(env.getnilinstances and env.getnilinstances() or {})")
        return src
    end

    local function patchVR(src)
        src = src:gsub(
            'VirtualBody:FindFirstChildOfClass%("Humanoid"%)%.Jump = true',
            'local _h = VirtualBody and VirtualBody:FindFirstChildOfClass("Humanoid"); if _h then _h.Jump = true end'
        )
        src = src:gsub(
            'local ViewHUD = script:FindFirstChild%("ViewHUD"%) or game:GetObjects%("rbxassetid://4480405425"%)%[1%]',
            'local ViewHUD; local _okv,_rv = pcall(function() return game:GetObjects("rbxassetid://4480405425")[1] end); if _okv then ViewHUD = _rv end; if not ViewHUD then warn("[Mythos VR] ViewHUD asset failed"); return end'
        )
        return src
    end

    local function patchAudio(src)
        src = src:gsub(
            'aa = game:GetObjects%("rbxassetid://01997056190"%)%[1%]',
            'local _oka,_ra = pcall(function() return game:GetObjects("rbxassetid://01997056190")[1] end); if not _oka or not _ra then warn("[Mythos Audio] asset failed"); return end; aa = _ra'
        )
        return src
    end

    if CMDs then
        CMDs[#CMDs+1] = {NAME = 'dex',        DESC = '[Mythos] Load Dex Explorer'}
        CMDs[#CMDs+1] = {NAME = 'vr',         DESC = '[Mythos] Load VR Tools'}
        CMDs[#CMDs+1] = {NAME = 'audiologger',DESC = '[Mythos] Load Audio Logger'}
    end

    addcmd('dex', {'explorer','dexplorer','loaddex'}, function(args, speaker)
        _run("Dex Explorer", "mythos_explorer.lua", patchExplorer, true)
    end)

    addcmd('vr', {'vrtools','virtualreality','loadvr'}, function(args, speaker)
        _run("VR Tools", "mythos_vr.lua", patchVR, true)
    end)

    addcmd('audiologger', {'audio','soundlogger','loadaudio'}, function(args, speaker)
        _run("Audio Logger", "mythos_audiologger.lua", patchAudio, true)
    end)

    notify('Mythos', 'Commands registered: ;dex  ;vr  ;audiologger')
end
]==]

    src = src .. INJECT
    return src, n
end

-- ============================================================
-- Load admin
-- ============================================================
local function loadAdmin()
    say("Mythos", "Downloading Core Admin...")
    local src = httpGet(REPO .. "mythos_admin.lua")
    if not src or #src < 1000 then
        say("Mythos", "Admin download FAILED")
        return
    end

    local patched, n = patchAdmin(src)
    print("[Mythos Loader] patched admin (" .. tostring(n) .. " patches, +injected sub-cmds)")

    local fn, err = loadstring(patched, "=mythos_admin.lua")
    if not fn then
        say("Mythos", "Admin compile FAILED")
        warn("[Mythos Loader] compile err:\n" .. tostring(err))
        return
    end

    local ok, runErr = pcall(fn)
    if not ok then
        say("Mythos", "Admin runtime FAILED")
        warn("[Mythos Loader] runtime err:\n" .. tostring(runErr))
        return
    end

    say("Mythos", "Core Admin loaded. Use ;dex ;vr ;audiologger")
end

loadAdmin()
