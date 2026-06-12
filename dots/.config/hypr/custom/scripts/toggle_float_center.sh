#!/usr/bin/env bash

# Get active window information in JSON format
ACTIVE_WINDOW_INFO=$(hyprctl activewindow -j)

# Check if the window is floating
IS_FLOATING=$(echo "$ACTIVE_WINDOW_INFO" | jq -r '.floating')

if [ "$IS_FLOATING" = "false" ]; then
  # It's a tiled window, so make it floating, resize, center and dim around
  hyprctl eval "hl.dispatch(hl.dsp.window.float({ action = 'toggle' })); hl.dispatch(hl.dsp.window.resize({ x = '80%', y = '80%', relative = false })); hl.dispatch(hl.dsp.window.center())"
else
  # It's a floating window, so just toggle it back to tiled and remove dim
  hyprctl eval "hl.dispatch(hl.dsp.window.float({ action = 'toggle' }))"
fi
