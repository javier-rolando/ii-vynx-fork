-- Monitor
hl.monitor({
    output = "DP-2",
    mode = "5120x1440@144",
    position = "0x0",
    scale = "1"
})

hl.config({
    general = {
        border_size = 2,
        layout = "master"
    },
    input = {
        kb_layout = "latam",
        kb_options = "caps:swapescape",
        accel_profile = "flat"
    },
    dwindle = {
        special_scale_factor = 0.80
    },
    master = {
        mfact = 0.47142,
        orientation = "center",
        slave_count_for_center_master = 0,
        special_scale_factor = 0.80,
        smart_resizing = false
    },
    scrolling = {
        fullscreen_on_one_column = false,
        column_width = 0.47142,
        focus_fit_method = 0
    },
    cursor = {
        hide_on_key_press = true,
        no_warps = true
    },
    misc = {
        vrr = 0
    },
    animations = {
        enabled = true
    },
    decoration = {
        dim_inactive = false
    }
})

-- Custom curves (additions to upstream)
hl.curve("specialWorkSwitch", { type = "bezier", points = {{0.05, 0.7}, {0.1, 1}} })
hl.curve("standard",          { type = "bezier", points = {{0.2,  0},   {0,   1}} })

hl.animation({ leaf = "windowsIn",           enabled = true,  speed = 2.5, bezier = "emphasizedDecel" })
hl.animation({ leaf = "windowsOut",          enabled = true,  speed = 1.5, bezier = "emphasizedAccel" })
hl.animation({ leaf = "windowsMove",         enabled = true,  speed = 3,   bezier = "standard" })
hl.animation({ leaf = "workspaces",          enabled = true,  speed = 3.5, bezier = "menu_decel",      style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true,  speed = 1.4, bezier = "emphasizedDecel", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true,  speed = 0.6, bezier = "emphasizedAccel", style = "slidevert" })
hl.animation({ leaf = "fade",                enabled = false, speed = 3,   bezier = "standard" })
hl.animation({ leaf = "fadeDim",             enabled = false, speed = 3,   bezier = "standard" })
hl.animation({ leaf = "border",              enabled = true,  speed = 2.5, bezier = "emphasizedDecel" })
