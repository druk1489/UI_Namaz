-- Mythos Loader v7
-- Fixes Solara-mutilated cmds, nukes duplicate v2 anticheat, injects ;antifling.
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

-- cutKeep: keeps `keepLit` in the result; replacement supplies its own tail
local function cutKeep(src, startLit, keepLit, replacement)
    local s = src:find(startLit, 1, true); if not s then return src, false end
    local e = src:find(keepLit, s, true);  if not e then return src, false end
    return src:sub(1, s - 1) .. replacement .. src:sub(e), true
end

-- cutNotify: for antikick/antiteleport (no clean neighboring addcmd anchor)
local function cutNotify(src, startLit, notifyLit, replacement)
    local s = src:find(startLit, 1, true); if not s then return src, false end
    local nm = src:find(notifyLit, s, true); if not nm then return src, false end
    local e2 = src:find("\nend)\n", nm, true); if not e2 then return src, false end
    return src:sub(1, s - 1) .. replacement .. src:sub(e2 + 7), true
end

local function patchAdmin(src)
    local n, ok = 0

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

    -- Patch 10: nuke the duplicate v2 anticheat block. v3 is authoritative.
    src, ok = cutKeep(src, "-- MYTHOS ANTICHEAT v2", "-- MYTHOS ANTICHEAT v3",
        "-- [Mythos] v2 anticheat removed by loader (superseded by v3)\n")
    if ok then n = n + 1 end

    -- INJECT: sub-cmds + antifling protection
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

    local _loaded = {}

    local function _run(label, file, patcher, once)
        if once and _loaded[file] then
            notify("Mythos", label .. " already loaded")
            return
        end
        notify("Mythos", "Loading " .. label .. "...")
        local src = _httpGet(REPO .. file)
        if not src or #src < 100 then
            notify("Mythos", label .. " download failed"); return
        end
        if patcher then
            local ok, patched = pcall(patcher, src)
            if ok and patched then src = patched end
        end
        local fn, err = loadstring(src, "=" .. file)
        if not fn then notify("Mythos", label .. " compile err: " .. tostring(err)); return end
        local ok, runErr = pcall(fn)
        if not ok then notify("Mythos", label .. " runtime err: " .. tostring(runErr)); return end
        _loaded[file] = true
        notify("Mythos", label .. " loaded OK")
    end

    local function patchExplorer(src)
        src = src:gsub('env%.game:GetService%("CoreGui"%) = game:GetService%("CoreGui"%)',
                       'env.CoreGui = game:GetService("CoreGui")')
        src = src:gsub("env%.{}", "(env.getnilinstances and env.getnilinstances() or {})")
        return src
    end
    local function patchVR(src)
        src = src:gsub('VirtualBody:FindFirstChildOfClass%("Humanoid"%)%.Jump = true',
                       'local _h = VirtualBody and VirtualBody:FindFirstChildOfClass("Humanoid"); if _h then _h.Jump = true end')
        src = src:gsub('local ViewHUD = script:FindFirstChild%("ViewHUD"%) or game:GetObjects%("rbxassetid://4480405425"%)%[1%]',
                       'local ViewHUD; local _okv,_rv = pcall(function() return game:GetObjects("rbxassetid://4480405425")[1] end); if _okv then ViewHUD = _rv end; if not ViewHUD then warn("[Mythos VR] ViewHUD asset failed"); return end')
        return src
    end
    local function patchAudio(src)
        src = src:gsub('aa = game:GetObjects%("rbxassetid://01997056190"%)%[1%]',
                       'local _oka,_ra = pcall(function() return game:GetObjects("rbxassetid://01997056190")[1] end); if not _oka or not _ra then warn("[Mythos Audio] asset failed"); return end; aa = _ra')
        return src
    end

    -- register in cmd list (for ;cmds panel)
    if CMDs then
        CMDs[#CMDs+1] = {NAME = 'dex',         DESC = '[Mythos] Load Dex Explorer'}
        CMDs[#CMDs+1] = {NAME = 'vr',          DESC = '[Mythos] Load VR Tools'}
        CMDs[#CMDs+1] = {NAME = 'audiologger', DESC = '[Mythos] Load Audio Logger'}
        CMDs[#CMDs+1] = {NAME = 'antifling',   DESC = '[Mythos] Anti-fling: cap linear/angular velocity, delete foreign BodyMovers'}
        CMDs[#CMDs+1] = {NAME = 'unantifling', DESC = '[Mythos] Disable anti-fling'}
    end

    addcmd('dex',{'explorer','dexplorer','loaddex'},function(args, speaker)
        _run("Dex Explorer", "mythos_explorer.lua", patchExplorer, true)
    end)
    addcmd('vr',{'vrtools','virtualreality','loadvr'},function(args, speaker)
        _run("VR Tools", "mythos_vr.lua", patchVR, true)
    end)
    addcmd('audiologger',{'audio','soundlogger','loadaudio'},function(args, speaker)
        _run("Audio Logger", "mythos_audiologger.lua", patchAudio, true)
    end)

    -- ============================================================
    -- ANTIFLING PROTECTION
    --   * Deletes foreign BodyMovers (BodyVelocity/BodyAngularVelocity/BodyGyro/
    --     BodyPosition/AlignPosition/AlignOrientation/LinearVelocity/AngularVelocity)
    --     that were attached to your character.
    --   * Caps AssemblyLinearVelocity on parts when it exceeds MAX_LINEAR.
    --   * Caps AssemblyAngularVelocity on parts when it exceeds MAX_ANGULAR.
    --   * Handles character respawn.
    -- ============================================================
    local AF = {
        on         = false,
        conns      = {},
        MAX_LINEAR = 250,       -- studs/sec
        MAX_ANGULAR= 25,        -- rad/sec
        FORBIDDEN  = {
            BodyVelocity        = true,
            BodyAngularVelocity = true,
            BodyGyro            = true,
            BodyPosition        = true,
            BodyThrust          = true,
            BodyForce           = true,
            RocketPropulsion    = true,
            AlignPosition       = true,
            AlignOrientation    = true,
            LinearVelocity      = true,
            AngularVelocity     = true,
            Torque              = true,
            VectorForce         = true,
        },
    }

    local function afDisconnectAll()
        for _, c in ipairs(AF.conns) do pcall(function() c:Disconnect() end) end
        AF.conns = {}
    end

    local function afGuardChar(char)
        if not char then return end
        AF.conns[#AF.conns+1] = char.DescendantAdded:Connect(function(d)
            if AF.FORBIDDEN[d.ClassName] then
                task.wait()  -- give one frame to allow legit tools
                if d.Parent and d.Parent:IsDescendantOf(char) then
                    pcall(function() d:Destroy() end)
                end
            end
        end)
        -- initial sweep
        for _, d in ipairs(char:GetDescendants()) do
            if AF.FORBIDDEN[d.ClassName] then
                pcall(function() d:Destroy() end)
            end
        end
    end

    local function afTick()
        local lp = game:GetService("Players").LocalPlayer
        local char = lp and lp.Character
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then
                local v = p.AssemblyLinearVelocity
                if v.Magnitude > AF.MAX_LINEAR then
                    p.AssemblyLinearVelocity = v.Unit * AF.MAX_LINEAR
                end
                local a = p.AssemblyAngularVelocity
                if a.Magnitude > AF.MAX_ANGULAR then
                    p.AssemblyAngularVelocity = a.Unit * AF.MAX_ANGULAR
                end
            end
        end
    end

    local function afStart()
        if AF.on then notify('Antifling','Already on'); return end
        AF.on = true
        local lp = game:GetService("Players").LocalPlayer
        afGuardChar(lp.Character)
        AF.conns[#AF.conns+1] = lp.CharacterAdded:Connect(function(char)
            if AF.on then afGuardChar(char) end
        end)
        AF.conns[#AF.conns+1] = game:GetService("RunService").Heartbeat:Connect(function()
            if AF.on then pcall(afTick) end
        end)
        notify('Antifling','\240\159\155\161 Enabled (cap '..AF.MAX_LINEAR..' studs/s, '..AF.MAX_ANGULAR..' rad/s)')
    end

    local function afStop()
        AF.on = false
        afDisconnectAll()
        notify('Antifling','Disabled')
    end

    addcmd('antifling',{'antifly','noflingprotect','nofling'},function(args, speaker)
        if args[1] then
            local a = tonumber(args[1])
            if a and a > 20 then AF.MAX_LINEAR = a end
        end
        if args[2] then
            local b = tonumber(args[2])
            if b and b > 1 then AF.MAX_ANGULAR = b end
        end
        afStart()
    end)
    addcmd('unantifling',{'unantifly','stopantifling'},function(args, speaker)
        afStop()
    end)

    notify('Mythos','Registered: ;dex ;vr ;audiologger ;antifling ;unantifling')
end
]==]

    src = src .. INJECT
    return src, n
end

local function loadAdmin()
    say("Mythos", "Downloading Core Admin...")
    local src = httpGet(REPO .. "mythos_admin.lua")
    if not src or #src < 1000 then say("Mythos", "Admin download FAILED"); return end
    local patched, n = patchAdmin(src)
    print("[Mythos Loader] patched admin (" .. tostring(n) .. " patches, +injected sub-cmds+antifling)")
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
    say("Mythos", "Core Admin loaded. Try: ;cmds  ;markcheat  ;antifling")
end

loadAdmin()
