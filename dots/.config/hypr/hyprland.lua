-- This file sources other files in `hyprland` and `custom` folders
-- You wanna add your stuff in files in `custom`

-- Internal stuff --
require("hyprland.lib")
require("hyprland.services")

-- Environment variables --
require("hyprland.env")
if is_file_exists(HOME .. "/.config/hypr/custom/env.lua") then
    require("custom.env")
end

-- Default configurations --
require("hyprland.execs")
require("hyprland.general")
require("hyprland.rules")
require("hyprland.keybinds")

-- Custom configurations --
if is_file_exists(HOME .. "/.config/hypr/custom/plugins.lua") then
    require("custom.plugins")
end

-- Colors (después de plugins para que hyprbars esté cargado)
local colorsGenerated = HOME .. "/.local/state/quickshell/user/generated/hyprland/colors.lua"
if is_file_exists(colorsGenerated) then dofile(colorsGenerated) else require("hyprland.colors") end
if is_file_exists(HOME .. "/.config/hypr/custom/execs.lua") then
    require("custom.execs")
end
if is_file_exists(HOME .. "/.config/hypr/custom/general.lua") then
    require("custom.general")
end
if is_file_exists(HOME .. "/.config/hypr/custom/rules.lua") then
    require("custom.rules")
end
if is_file_exists(HOME .. "/.config/hypr/custom/keybinds.lua") then
    require("custom.keybinds")
end
if is_file_exists(HOME .. "/.config/hypr/hyprmon.lua") then
    require("hyprmon")
end

-- Shell overrides --
require("hyprland.shellOverrides.main")

-- Local scratch (not managed by Nix, for testing) --
if is_file_exists(HOME .. "/.config/hypr/custom/local.lua") then
    require("custom.local")
end
