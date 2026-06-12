#!/usr/bin/env bash
# Este script decide si llamar a workspace_action.sh con "up" o "down"

# El primer argumento es el dispatcher (workspace, movetoworkspace, etc.)
# Si no se pasa ninguno, usa "workspace" por defecto.
dispatcher=${1:-workspace}

curr_workspace="$(hyprctl activeworkspace -j | jq -r ".id")"

# Si estamos en el bloque 1-10, subimos. Si no, bajamos.
if ((curr_workspace <= 10)); then
  /home/javier/.config/hypr/custom/scripts/workspace_action.sh "$dispatcher" up
else
  /home/javier/.config/hypr/custom/scripts/workspace_action.sh "$dispatcher" down
fi
