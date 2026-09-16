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
end)

-- Cursor: aislado en su propio hl.on, no dentro de la función grande de
-- arriba — así un error en cualquiera de esos otros exec_cmd no le impide
-- correr. apply-on-login.sh (del paquete material-bibata-cursor) reaplica
-- cursor_matugen.sh cada 2s durante 1 minuto: XWayland resetea Xresources
-- en un momento variable de su propia inicialización, y home-manager
-- resetea el symlink Bibata-Material-Current al default declarado en cada
-- switch — sin esto, Steam y los juegos vía Wine (que cachean el cursor al
-- arrancar) agarran ese valor viejo en vez del último matcheado.
hl.on("hyprland.start", function()
	hl.exec_cmd("$HOME/.local/state/quickshell/user/generated/material-bibata-cursor/apply-on-login.sh")
end)
