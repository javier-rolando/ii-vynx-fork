#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_JSON="$SCRIPT_DIR/themes.json"
COLOR_MATCH_PY="$SCRIPT_DIR/color_match.py"

INSTALL_DIR="${BIBATA_MATUGEN_INSTALL_DIR:-$HOME/.icons}"
COLORS_FILE="$HOME/.config/colors.json"

MATUGEN_KEY="${MATUGEN_KEY:-.colors.color13}"

# --- Preflight checks --------------------------------------------------
if [[ ! -f "$COLORS_FILE" ]]; then
    echo "Error: color profile missing at $COLORS_FILE" >&2
    exit 1
fi

if [[ ! -f "$THEMES_JSON" ]]; then
    echo "Error: themes.json not found at $THEMES_JSON" >&2
    exit 1
fi

if [[ ! -f "$COLOR_MATCH_PY" ]]; then
    echo "Error: color_match.py not found at $COLOR_MATCH_PY" >&2
    exit 1
fi

# --- 1. Extract active wallpaper hex color (JSON or Raw Text) ----------
hex_input=""

# Case A: Try reading as JSON if jq is available
if command -v jq >/dev/null 2>&1 && jq empty "$COLORS_FILE" 2>/dev/null; then
    hex_input=$(jq -r "$MATUGEN_KEY // ." "$COLORS_FILE" 2>/dev/null | tr '[:upper:]' '[:lower:]')
fi

# Case B: Fallback to reading raw text (e.g. if file contains just #ffb5a0)
if [[ -z "$hex_input" || "$hex_input" == "null" || ! "$hex_input" =~ ^#[0-9a-f]{6}$ ]]; then
    hex_input=$(tr -d '[:space:]"' < "$COLORS_FILE" | tr '[:upper:]' '[:lower:]')
fi

# Final validation
if [[ ! "$hex_input" =~ ^#[0-9a-f]{6}$ ]]; then
    echo "Error: Could not extract a valid 6-digit hex color from $COLORS_FILE" >&2
    exit 1
fi

echo "Active wallpaper color: $hex_input"

# --- 2. Match to closest pre-built theme via CIEDE2000 -------------------
match_stderr=$(mktemp)
if ! nearest_theme=$(python3 "$COLOR_MATCH_PY" "$hex_input" "$THEMES_JSON" 2>"$match_stderr"); then
    echo "Error: color_match.py failed:" >&2
    cat "$match_stderr" >&2
    rm -f "$match_stderr"
    exit 1
fi
cat "$match_stderr" >&2
rm -f "$match_stderr"

if [[ -z "$nearest_theme" ]]; then
    echo "Error: no matching theme returned" >&2
    exit 1
fi

THEME_NAME="Bibata-Material-$nearest_theme"

# --- 3. Verify the theme is actually installed across known icon directories ---
FOUND_DIR=""

for candidate_dir in "$INSTALL_DIR" "$HOME/.local/share/icons" "/usr/share/icons"; do
    if [[ -d "$candidate_dir/$THEME_NAME" ]]; then
        FOUND_DIR="$candidate_dir"
        break
    fi
done

if [[ -z "$FOUND_DIR" ]]; then
    echo "Error: matched theme '$THEME_NAME' was not found in:" >&2
    echo "  - $INSTALL_DIR" >&2
    echo "  - $HOME/.local/share/icons" >&2
    echo "  - /usr/share/icons" >&2
    exit 1
fi

INSTALL_DIR="$FOUND_DIR"

# --- 4. Apply the chosen theme across desktop environments ---------------

# A. GNOME & GTK Applications (Works for GNOME & GTK apps running in Hyprland)
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface cursor-theme "$THEME_NAME" 2>/dev/null || true
    echo "✓ Set gsettings cursor-theme: $THEME_NAME"
fi

# B. Hyprland compositor
# NixOS wraps the Hyprland binary, so its /proc comm is truncated to
# something like ".Hyprland-wrapp" — `pgrep -x Hyprland` never matches
# there. HYPRLAND_INSTANCE_SIGNATURE is what hyprctl itself uses to find
# the running instance, so check that instead of the process name.
if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    hyprctl setcursor "$THEME_NAME" 24 >/dev/null 2>&1 \
        && echo "✓ Set hyprctl cursor: $THEME_NAME" \
        || echo "Warning: hyprctl setcursor failed" >&2
fi

# C. XCursor fallback (ensures legacy X11 & Wayland apps show the cursor
# under Hyprland). Best-effort: on setups where ~/.icons/default is a
# read-only symlink managed elsewhere (e.g. home-manager's
# home.pointerCursor), this write fails — don't let that abort the hook
# after gsettings/hyprctl already applied the theme above.
if mkdir -p "$HOME/.icons/default" 2>/dev/null && cat <<EOF > "$HOME/.icons/default/index.theme" 2>/dev/null
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=$THEME_NAME
EOF
then
    echo "✓ Updated ~/.icons/default/index.theme"
else
    echo "Warning: could not update ~/.icons/default/index.theme (read-only? managed elsewhere)" >&2
fi
