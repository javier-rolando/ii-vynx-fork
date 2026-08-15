-- Cursor
-- Bibata-Material-Current: alias fijo cuyo destino reapunta cursor_matugen.sh
-- (ln -sfn) en cada cambio de wallpaper. Este hl.env corre al arrancar
-- Hyprland y pisa lo que haya seteado home-manager/systemd para la sesión,
-- así que hay que declarar el nombre dinámico acá también, no alcanza con
-- cambiarlo solo del lado de Nix.
hl.env("XCURSOR_THEME", "Bibata-Material-Current")
hl.env("XCURSOR_SIZE", "24")

-- Input methods (fcitx5)
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("SDL_IM_MODULE", "fcitx")
hl.env("GLFW_IM_MODULE", "ibus")
hl.env("INPUT_METHOD", "fcitx")
