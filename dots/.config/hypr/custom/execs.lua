hl.on("hyprland.start", function()
	-- greetd (--cmd start-hyprland) lanza Hyprland como proceso crudo, no como
	-- unidad systemd, así que el sd_notify(READY=1) interno de Hyprland nunca
	-- llega a systemd y graphical-session.target no se marca como alcanzado.
	-- Desde xdg-desktop-portal 1.22, el portal pide Requisite=graphical-session.target
	-- y falla si nadie lo arrancó. Lo arrancamos nosotros a mano.
	hl.exec_cmd("systemctl --user start nixos-fake-graphical-session.target")
	hl.exec_cmd("steam -nochatui -nofriendsui -silent")
	hl.exec_cmd("solaar -w hide")
	hl.exec_cmd("kdeconnect-indicator")
	hl.exec_cmd("fcitx5")
	hl.exec_cmd("sleep 1 && setxkbmap latam")
	-- hl.exec_cmd(
	-- 	"linux-wallpaperengine --disable-mouse --scaling fill --silent --screen-root DP-2 --assets-dir /mnt/ssd/SteamLibrary/steamapps/common/wallpaper_engine/assets /mnt/ssd/SteamLibrary/steamapps/workshop/content/431960/3264616910"
	-- )
	-- Cursor
	-- Corre el hook completo de matugen (gsettings + hyprctl + Xresources +
	-- symlink Bibata-Material-Current) usando el último color guardado en
	-- ~/.config/colors.json, en vez de solo hyprctl. Xresources se resetea
	-- en cada boot (a diferencia del symlink, que persiste en disco) y
	-- home-manager reinicia el symlink al valor declarado en Nix en cada
	-- switch — sin esto, Steam (que arranca enseguida y cachea su cursor al
	-- inicio) agarra un tema viejo/default en vez del último matcheado.
	-- Corre antes que "steam" en custom/execs.lua (hyprland.execs se
	-- importa primero en hyprland.lua) para llegar a tiempo.
	--
	-- XWayland resetea Xresources (Xcursor.theme vuelve a "default") en
	-- algún punto de su propia inicialización, en un momento variable que
	-- no podemos predecir con un sleep fijo (probado con 8s y 15s, falla
	-- en algunos boots). En vez de adivinar el momento exacto, reaplicamos
	-- el hook cada 2s durante 1 minuto — así, sea cuando sea que XWayland
	-- haga el reset, la próxima pasada (a los 2s como mucho) lo corrige.
	hl.exec_cmd(
		"bash -c 'for i in $(seq 1 30); do "
			.. "$HOME/.local/state/quickshell/user/generated/material-bibata-cursor/cursor_matugen.sh >/dev/null 2>&1; "
			.. "sleep 2; done'"
	)
end)
