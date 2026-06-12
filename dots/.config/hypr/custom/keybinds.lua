-- Unbind upstream defaults
for _, bind in ipairs({
    "SUPER + Period",    "SUPER + A",             "SUPER + B",                      "SUPER + O",
    "SUPER + N",         "SUPER + Slash",          "SUPER + K",                      "SUPER + M",
    "SUPER + J",         "SUPER + SHIFT + T",      "SUPER + BracketLeft",            "SUPER + BracketRight",
    "SUPER + Semicolon", "SUPER + Apostrophe",     "SUPER + ALT + Space",            "SUPER + D",
    "SUPER + F",         "SUPER + P",              "CTRL + SUPER + S",               "ALT + Tab",
    "SUPER + S",         "SUPER + L",              "SUPER + SHIFT + L",              "CTRL + SHIFT + ALT + SUPER + Delete",
    "SUPER + SHIFT + N", "SUPER + SHIFT + B",      "SUPER + SHIFT + P",              "SUPER + Return",
    "SUPER + T",         "CTRL + ALT + T",         "SUPER + E",                      "SUPER + W",
    "SUPER + C",         "SUPER + SHIFT + W",      "SUPER + X",                      "CTRL + SUPER + V",
    "SUPER + I",         "SUPER + G",              "SUPER + SHIFT + M",              "SUPER + ALT + W",
    "SUPER + Left",      "SUPER + Right",          "SUPER + Up",                     "SUPER + Down",
    "SUPER + ALT + F",   "SUPER + ALT + M",        "SUPER + ALT + S",
    "XF86AudioNext",     "XF86AudioPrev",          "XF86AudioPlay",                  "XF86AudioPause",
    "CTRL + SUPER + R",
}) do hl.unbind(bind) end

for _, code in ipairs({ 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }) do
    hl.unbind("SUPER + code:" .. code)
end
for _, code in ipairs({ 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }) do
    hl.unbind("SUPER + code:" .. code)
end

-- Helpers
local function warp_dispatch(dispatch_fn)
    hl.config({ cursor = { no_warps = false } })
    local r = hl.dispatch(dispatch_fn)
    hl.config({ cursor = { no_warps = true } })
    return r
end

local function smart_focus(dir)
    local fallback = { l = "cyclenext", r = "cycleprev" }
    local r = warp_dispatch(hl.dsp.focus({ direction = dir }))
    if not r.ok and fallback[dir] then
        warp_dispatch(hl.dsp.layout(fallback[dir]))
    end
end

local function smart_swap(dir)
    local fallback = { l = "swapnext", r = "swapprev" }
    local r = hl.dispatch(hl.dsp.window.swap({ direction = dir }))
    if not r.ok and fallback[dir] then
        hl.dispatch(hl.dsp.layout(fallback[dir]))
    end
end

local function toggle_float_center()
    local floating = hl.get_active_window().floating
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    if not floating then
        local m = hl.get_active_monitor()
        hl.dispatch(hl.dsp.window.resize({ x = math.floor(m.width * 0.8), y = math.floor(m.height * 0.8), "exact" }))
        hl.dispatch(hl.dsp.window.center())
    end
end

local function switch_layout(layout)
    local ws_name = hl.get_active_workspace().name
    hl.workspace_rule({ workspace = "name:" .. ws_name, layout = layout })
    local gaps = layout == "dwindle"
        and { top = 5, right = 1360, bottom = 5, left = 1360 }
        or  { top = 5, right = 5,    bottom = 5, left = 5    }
    hl.workspace_rule({ workspace = "name:" .. ws_name .. " w[t1]f[-1]", gaps_out = gaps })
end

-- Shell config / keybinds
hl.bind("CTRL + SUPER + Slash",       hl.dsp.exec_cmd("xdg-open ~/.config/illogical-impulse/config.json"), { description = "Edit shell config" })
hl.bind("CTRL + SUPER + ALT + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"),     { description = "Edit user keybinds" })

-- Cheatsheet
hl.bind("SUPER + Apostrophe", hl.dsp.global("quickshell:cheatsheetToggle"), { description = "Toggle cheatsheet" })

-- Core apps / window management
hl.bind("SUPER + Return",         hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + SHIFT + Return", hl.dsp.exec_cmd("warp-terminal"))
hl.bind("SUPER + B",              hl.dsp.exec_cmd(browser))
hl.bind("SUPER + Q",              hl.dsp.window.close())
hl.bind("SUPER + CTRL + Q",       hl.dsp.exit())
hl.bind("SUPER + SHIFT + E",      hl.dsp.exec_cmd(fileManager))
hl.bind("SUPER + braceright",     hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + F",              hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + ALT + F",        hl.dsp.window.fullscreen({ mode = "maximized",  action = "toggle" }))
hl.bind("SUPER + SHIFT + F",      hl.dsp.window.fullscreen_state({ internal = 0, client = 1, action = "toggle" }))
hl.bind("SUPER + P",              hl.dsp.window.pseudo({ action = "toggle" }))
hl.bind("SUPER + SHIFT + P",      hl.dsp.window.pin())
hl.bind("SUPER + R",              toggle_float_center)
hl.bind("ALT + Tab",              function() warp_dispatch(hl.dsp.focus({ workspace = "previous" })) end)
hl.bind("SUPER + SHIFT + Tab",    hl.dsp.window.cycle_next({ visible = true, hist = true }))

-- Master layout
hl.bind("SUPER + Plus",             hl.dsp.layout("mfact +0.05"))
hl.bind("SUPER + Minus",            hl.dsp.layout("mfact -0.05"))
hl.bind("SUPER + Backspace",        hl.dsp.layout("mfact exact 0.47142"))
hl.bind("SUPER + ALT + Backspace",  hl.dsp.layout("mfact exact 0.55"))
hl.bind("CTRL + SUPER + Backspace", hl.dsp.layout("mfact exact 0.3544"))
hl.bind("SUPER + Left",             hl.dsp.layout("orientationnext"))
hl.bind("SUPER + Right",            hl.dsp.layout("orientationprev"))
hl.bind("SUPER + I",                hl.dsp.layout("rollnext"))
hl.bind("SUPER + O",                hl.dsp.layout("rollprev"))

-- Layout switch
hl.bind("SUPER + code:87",  function() switch_layout("master") end,    { passthrough = true })
hl.bind("CTRL + SUPER + U", function() switch_layout("master") end,    { passthrough = true })
hl.bind("SUPER + code:88",  function() switch_layout("dwindle") end,   { passthrough = true })
hl.bind("CTRL + SUPER + I", function() switch_layout("dwindle") end,   { passthrough = true })
hl.bind("SUPER + code:89",  function() switch_layout("scrolling") end, { passthrough = true })
hl.bind("CTRL + SUPER + O", function() switch_layout("scrolling") end, { passthrough = true })

-- App shortcuts
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("betterbird"))
hl.bind("SUPER + A",         hl.dsp.exec_cmd("elecwhat"))
hl.bind("SUPER + D",         hl.dsp.exec_cmd("vesktop --enable-features=UseOzonePlatform --ozone-platform=wayland"))
hl.bind("SUPER + ALT + S",   hl.dsp.exec_cmd('chromium --app="https://chat.openai.com"'))
hl.bind("SUPER + S",         hl.dsp.exec_cmd('chromium --app="https://gemini.google.com/app"'))
hl.bind("SUPER + T",         hl.dsp.exec_cmd('chromium --app="https://translate.google.com/?sl=en&tl=es&op=translate"'))
hl.bind("SUPER + ALT + M",   hl.dsp.exec_cmd("spotify"))
hl.bind("SUPER + E",         hl.dsp.exec_cmd('kitty --class "kitty-yazi" -e fish -c "yazi"'))
hl.bind("SUPER + SHIFT + U", hl.dsp.exec_cmd('kitty --class "kitty-update" -e fish -c "upd"'))

-- Restart QuickShell
hl.bind("CTRL + SUPER + R", hl.dsp.exec_cmd("pkill -x .quickshell-wra; qs -c $qsConfig &"))

-- Monitor scripts
hl.bind("SUPER + CTRL + F1", hl.dsp.exec_cmd("/home/javier/scripts/configure_monitors.sh 1monitor"))
hl.bind("SUPER + CTRL + F2", hl.dsp.exec_cmd("/home/javier/scripts/configure_monitors.sh pbp"))

-- Focus (hjkl)
hl.bind("SUPER + H", function() smart_focus("l") end)
hl.bind("SUPER + L", function() smart_focus("r") end)
hl.bind("SUPER + K", function() smart_focus("u") end)
hl.bind("SUPER + J", function() smart_focus("d") end)

-- Workspace navigation (monitor-relative)
hl.bind("SUPER + Period", function() warp_dispatch(hl.dsp.focus({ workspace = "m+1" })) end)
hl.bind("SUPER + Comma",  function() warp_dispatch(hl.dsp.focus({ workspace = "m-1" })) end)

-- Swap windows
hl.bind("SUPER + ALT + H", function() smart_swap("l") end)
hl.bind("SUPER + ALT + L", function() smart_swap("r") end)
hl.bind("SUPER + ALT + K", function() smart_swap("u") end)
hl.bind("SUPER + ALT + J", function() smart_swap("d") end)

-- Resize windows
hl.bind("SUPER + SHIFT + H", hl.dsp.window.resize({ x = -60, y = 0 }), { repeating = true })
hl.bind("SUPER + SHIFT + L", hl.dsp.window.resize({ x = 60,  y = 0 }), { repeating = true })
hl.bind("SUPER + SHIFT + K", hl.dsp.window.resize({ x = 0,  y = -60 }), { repeating = true })
hl.bind("SUPER + SHIFT + J", hl.dsp.window.resize({ x = 0,   y = 60 }), { repeating = true })

-- Workspaces 1-10
for i = 1, 10 do
    local key = i == 10 and "0" or tostring(i)
    hl.bind("SUPER + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Workspaces 11-20
for i = 1, 10 do
    local key = i == 10 and "0" or tostring(i)
    hl.bind("CTRL + SUPER + " .. key, hl.dsp.focus({ workspace = i + 10 }))
end

hl.bind("SUPER + N",         hl.dsp.focus({ workspace = "emptym" }))
hl.bind("SUPER + SHIFT + N", hl.dsp.window.move({ workspace = "emptym" }))

-- Mouse drag/resize
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media (Spotify)
hl.bind("SUPER + F6",     hl.dsp.exec_cmd("playerctl --player spotify previous"),   { locked = true })
hl.bind("SUPER + F7",     hl.dsp.exec_cmd("playerctl --player spotify play-pause"), { locked = true })
hl.bind("SUPER + F8",     hl.dsp.exec_cmd("playerctl --player spotify next"),       { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl --player spotify next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl --player spotify previous"),   { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl --player spotify play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl --player spotify play-pause"), { locked = true })
hl.bind("SUPER + F9",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

-- QuickShell
hl.bind("SUPER + SHIFT + Q", hl.dsp.global("quickshell:barDockToggle"),          { description = "Toggle bar/dock" })
hl.bind("SUPER + Z",         hl.dsp.global("quickshell:sidebarLeftToggle"),       { description = "Toggle left sidebar" })
hl.bind("SUPER + ALT + Z",   hl.dsp.global("quickshell:sidebarLeftToggleDetach"))
hl.bind("SUPER + X",         hl.dsp.global("quickshell:sidebarRightToggle"),      { description = "Toggle right sidebar" })
hl.bind("SUPER + G",         hl.dsp.global("quickshell:overlayToggle"),           { description = "Toggle overlay" })
hl.bind("CTRL + SUPER + L",  hl.dsp.global("quickshell:lock"))
hl.bind("SUPER + SHIFT + I", hl.dsp.exec_cmd("qs -p ~/.config/quickshell/$qsConfig/settings.qml"))
hl.bind("CTRL + SUPER + F9", hl.dsp.exec_cmd("~/scripts/vm.sh"))
hl.bind("SUPER + SHIFT + Z", hl.dsp.global("quickshell:mediaModeToggle"),         { description = "Toggle media mode" })
hl.bind("SUPER + SHIFT + V", hl.dsp.global("quickshell:screenTranslate"))

-- Special workspaces
hl.bind("SUPER + W",         hl.dsp.workspace.toggle_special("special"))
hl.bind("SUPER + M",         hl.dsp.workspace.toggle_special("spotify"))
hl.bind("SUPER + ALT + E",   hl.dsp.workspace.toggle_special("yazi"))
hl.bind("SUPER + ALT + T",   hl.dsp.workspace.toggle_special("translate"))
hl.bind("SUPER + ntilde",    hl.dsp.workspace.toggle_special("term"))
hl.bind("SUPER + SHIFT + B", hl.dsp.workspace.toggle_special("btop"))
hl.bind("SUPER + SHIFT + W", hl.dsp.window.move({ workspace = "special" }))
hl.bind("SUPER + ALT + W",   hl.dsp.window.move({ workspace = "special", follow = false }))
hl.bind("SUPER + ALT + U",   hl.dsp.workspace.toggle_special("update"))
hl.bind("SUPER + SHIFT + M", hl.dsp.workspace.toggle_special("yt-music"))

-- Screenshot
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m output -m DP-2"))
