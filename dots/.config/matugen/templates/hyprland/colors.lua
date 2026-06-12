hl.config({
    general = {
        col = {
            active_border   = "rgba({{colors.primary.default.hex_stripped}}FF)",
            inactive_border = "rgba({{colors.outline_variant.default.hex_stripped}}55)",
        },
    },
    misc = {
        background_color = "rgba({{colors.surface.dark.hex_stripped}}FF)",
    },
})

hl.window_rule({
    match        = { pin = 1 },
    border_color = "rgba({{colors.primary.default.hex_stripped}}AA) rgba({{colors.primary.default.hex_stripped}}77)",
})

hl.config({
    plugin = {
        hyprbars = {
            bar_color                  = "rgba({{colors.background.default.hex_stripped}}FF)",
            bar_height                 = 38,
            bar_padding                = 10,
            bar_text_font              = "Google Sans Flex Medium, Rubik, Geist, AR One Sans, Reddit Sans, Inter, Roboto, Ubuntu, Noto Sans, sans-serif",
            bar_button_padding         = 12,
            bar_buttons_alignment      = "left",
            bar_text_size              = 12,
            bar_part_of_window         = true,
            bar_precedence_over_border = true,
            bar_title_enabled          = false,
            ["col.text"]               = "rgba({{colors.on_background.default.hex_stripped}}FF)",
            on_double_click            = "hyprctl eval \"hl.dispatch(hl.dsp.window.float({ action = 'toggle' }))\"",
        },
    },
})

hl.plugin.hyprbars.add_button({
    bg_color = "rgba({{colors.inverse_primary.default.hex_stripped}}FF)",
    fg_color = "rgb(000000)",
    size     = 15,
    icon     = "",
    action   = "hyprctl eval \"hl.dispatch(hl.dsp.window.close())\"",
})
hl.plugin.hyprbars.add_button({
    bg_color = "rgba({{colors.primary.default.hex_stripped}}FF)",
    fg_color = "rgb(000000)",
    size     = 15,
    icon     = "",
    action   = "hyprctl eval \"hl.dispatch(hl.dsp.window.fullscreen({ mode = 'fullscreen', action = 'toggle' }))\"",
})
hl.plugin.hyprbars.add_button({
    bg_color = "rgba({{colors.tertiary.default.hex_stripped}}FF)",
    fg_color = "rgb(000000)",
    size     = 15,
    icon     = "",
    action   = "hyprctl eval \"local w = hl.get_active_window(); if w and w.workspace.name:match('^special') then hl.dispatch(hl.dsp.workspace.toggle_special(w.workspace.name:gsub('^special:', ''))) else hl.dispatch(hl.dsp.window.move({ workspace = 'special', follow = false })) end\"",
})
