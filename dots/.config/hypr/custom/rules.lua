-- Workspace defaults
hl.workspace_rule({ workspace = "1", monitor = "DP-2", default = true })
hl.workspace_rule({ workspace = "r[1-99]", layout = "master" })

-- Global
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

-- Float
hl.window_rule({ match = { title = "^(Selector de Wallpapers)$" }, float = true })
hl.window_rule({ match = { title = "^(nmtui)$" }, float = true })
hl.window_rule({ match = { title = "^(update.sh)$" }, float = true, size = { 1600, 800 } })
hl.window_rule({ match = { title = "^(Blender Animation Player)$" }, float = true })
hl.window_rule({ match = { initial_title = "^(.*Reminder.*)$" }, float = true, size = { "60%", "60%" }, center = true })
hl.window_rule({ match = { class = "(qalculate-gtk)" }, float = true })
hl.window_rule({ match = { title = "^(.*Aseprite.*)$" }, tile = true })
hl.window_rule({ match = { class = "^steam_app_%d+$" }, monitor = "DP-2" })
hl.window_rule({ match = { class = "^(chromium-chatgpt|chromium-translate)$" }, tile = true })
hl.window_rule({ match = { title = "^(Friends List)$" }, float = true, center = true })
hl.window_rule({ match = { class = "(hyprland-share-picker)" }, float = true, center = true })

-- Picture-in-Picture
hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, move = { 3840, 717 } })
hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, size = { 1260, 709 } })

-- Layer rules
-- hl.layer_rule({ match = { namespace = "^quickshell.*" },                    xray = false })
-- hl.layer_rule({ match = { namespace = "^quickshell.*" },                    ignore_alpha = 0.39 })
-- hl.layer_rule({ match = { namespace = "^quickshell:onScreenDisplay.*" },    blur = false })

-- Special workspaces
hl.workspace_rule({ workspace = "special:term", ["on_created_empty"] = 'kitty --class "kitty-special"' })
hl.workspace_rule({
	workspace = "special:update",
	["on_created_empty"] = 'kitty --class "kitty-update" -e fish -c "upd"',
})
hl.workspace_rule({
	workspace = "special:install",
	["on_created_empty"] = 'kitty --class "kitty-install" -e fish -c "pkginstall"',
})
hl.workspace_rule({
	workspace = "special:uninstall",
	["on_created_empty"] = 'kitty --class "kitty-uninstall" -e fish -c "pkgremove"',
})
hl.workspace_rule({
	workspace = "special:yazi",
	["on_created_empty"] = 'kitty --class "kitty-yazi" -e fish -c "yazi"',
})
hl.workspace_rule({
	workspace = "special:btop",
	["on_created_empty"] = 'kitty --class "kitty-btop" -e fish -c "btop"',
})
hl.workspace_rule({
	workspace = "special:spotify-term",
	["on_created_empty"] = 'kitty --class "kitty-spotify" -e spotify_player',
})
hl.workspace_rule({
	workspace = "special:english",
	["on_created_empty"] = 'kitty --class "kitty-english" -e fish -c "nvim /home/javier/Documents/ingles.txt"',
})
hl.workspace_rule({
	workspace = "special:translate",
	["on_created_empty"] = 'chromium --app="https://translate.google.com/?sl=en&tl=es&op=translate"',
})
hl.workspace_rule({ workspace = "special:spotify", ["on_created_empty"] = "spotify" })
hl.workspace_rule({
	workspace = "special:yt-music",
	["on_created_empty"] = "youtube-music --enable-features=UseOzonePlatform --ozone-platform=wayland",
})

-- Workspace assignments
hl.window_rule({ match = { class = "brave-browser" }, workspace = 1, fullscreen_state = "0 1" })
hl.window_rule({ match = { class = "zen" }, workspace = 1, fullscreen_state = "0 1" })
hl.window_rule({ match = { class = "vesktop" }, workspace = 2, fullscreen_state = "0 1" })
hl.window_rule({ match = { class = "waterfox" }, workspace = 5, fullscreen_state = "0 1" })
hl.window_rule({ match = { class = "librewolf" }, workspace = 11, fullscreen_state = "0 1" })
hl.window_rule({ match = { class = "firefox" }, fullscreen_state = "0 1" })
hl.window_rule({ match = { class = "Opera GX" }, fullscreen_state = "0 1" })
hl.window_rule({ match = { class = "(elecwhat)" }, workspace = 2 })
hl.window_rule({ match = { class = "(eu.betterbird.Betterbird)" }, workspace = 2 })
hl.window_rule({ match = { class = "(steam)" }, workspace = 3 })
hl.window_rule({ match = { class = "(net.lutris.Lutris)" }, workspace = 3 })
hl.window_rule({ match = { class = "(heroic)" }, workspace = 3 })
hl.window_rule({ match = { class = "(chrome-chat.openai.com__-Default)" }, workspace = 4 })
hl.window_rule({ match = { class = "(chrome-gemini.google.com__app-Default)" }, workspace = 4 })
