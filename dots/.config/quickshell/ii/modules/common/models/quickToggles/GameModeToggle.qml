import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common.models.hyprland
import qs.services

QuickToggleModel {
    id: root
    name: Translation.tr("Game mode")
    toggled: !confOpt.value
    icon: "gamepad"

    // Forces every window opaque so custom opacity rules (kitty/code/etc.) stop applying.
    readonly property string opaqueRule: 'hl.window_rule({name="shell:game-mode-opaque",match={class=".*"},opacity="1.0 override 1.0 override 1.0 override",opaque=true})'
    readonly property string opaqueRuleMarker: "shell:game-mode-opaque"

    mainAction: () => {
        root.toggled = !root.toggled;
        if (root.toggled) {
            Quickshell.execDetached(["bash", "-c", `hyprctl eval "hl.config({ animations = { enabled = false }, decoration = { shadow = { enabled = false }, blur = { enabled = false }, rounding = 0 }, general = { gaps_in = 0, gaps_out = 0, border_size = 1, allow_tearing = true }, input = { kb_options = '' } })"; warp-cli disconnect`])
        } else {
            Quickshell.execDetached(["bash", "-c", "hyprctl reload; warp-cli connect"])
        }
    }

    HyprlandConfigOption {
        id: confOpt
        key: "animations:enabled"
    }

    tooltipText: Translation.tr("Game mode")
}
