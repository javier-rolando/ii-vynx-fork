#!/usr/bin/env bash
curr_workspace="$(hyprctl activeworkspace -j | jq -r ".id")"
dispatcher="$1"
shift ## The target is now in $1, not $2

if [[ -z "${dispatcher}" || "${dispatcher}" == "--help" || "${dispatcher}" == "-h" || -z "$1" ]]; then
  echo "Usage: $0 <dispatcher> <target>"
  echo "  <dispatcher>: hyprctl dispatcher (e.g., workspace, movetoworkspace)"
  echo "  <target>: Can be a number (1-10), a relative value (+1, -1), or a keyword (up, down)."
  exit 1
fi

_dispatch() {
  local target="$1"
  case "${dispatcher}" in
    workspace)
      hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = '$target' }))"
      ;;
    movetoworkspace)
      hyprctl eval "hl.dispatch(hl.dsp.window.move({ workspace = '$target', follow = true }))"
      ;;
    movetoworkspacesilent)
      hyprctl eval "hl.dispatch(hl.dsp.window.move({ workspace = '$target', follow = false }))"
      ;;
    *)
      hyprctl dispatch "${dispatcher}" "$target"
      ;;
  esac
}

if [[ "$1" == *"+"* || "$1" == *"-"* ]]; then ## Is this something like r+1 or -1?
  _dispatch "$1"

elif [[ "$1" == "up" ]]; then
  target_workspace=$((curr_workspace + 10))
  _dispatch "${target_workspace}"

elif [[ "$1" == "down" ]]; then
  target_workspace=$((curr_workspace - 10))
  if (( target_workspace > 0 )); then
    _dispatch "${target_workspace}"
  fi

elif [[ "$1" =~ ^[0-9]+$ ]]; then ## Is this just a number?
  target_workspace=$(((($curr_workspace - 1) / 10 ) * 10 + $1))
  _dispatch "${target_workspace}"

else
  _dispatch "$1" ## In case the target is a string, required for special workspaces.
  exit 1
fi