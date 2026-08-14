-- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function ()

    -- Bar, wallpaper
    hl.exec_cmd("$HOME/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")
    hl.exec_cmd("qs -c $qsConfig")
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/__restore_video_wallpaper.sh")

    -- Core components (authentication, lock screen, notification daemon)
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") -- Some fix idk

    -- Audio
    hl.exec_cmd("easyeffects --hide-window --service-mode")

    -- Clipboard: history
    --hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("wl-paste --type text --watch bash -c 'cliphist store && qs -c $qsConfig ipc call cliphistService update'")
    hl.exec_cmd("wl-paste --type image --watch bash -c 'cliphist store && qs -c $qsConfig ipc call cliphistService update'")

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
        "bash -c 'for i in $(seq 1 30); do " ..
        "$HOME/.local/state/quickshell/user/generated/material-bibata-cursor/cursor_matugen.sh >/dev/null 2>&1; " ..
        "sleep 2; done'"
    )
end)
