#!/usr/bin/env bash

# Script para intercambiar ventanas de forma inteligente en Hyprland (v3).
# Este script captura la salida estándar (stdout) de hyprctl y reacciona
# si la salida no es "ok", lo que indica un fallo.

DIRECTION=$1

if [ -z "$DIRECTION" ]; then
    echo "Uso: $0 <l|r|u|d>"
    exit 1
fi

OUTPUT=$(hyprctl eval "hl.dispatch(hl.dsp.window.swap({ direction = '$DIRECTION' }))" 2>&1)

if [[ "$OUTPUT" == *"No window"* ]]; then
    case "$DIRECTION" in
        l) hyprctl eval "hl.dispatch(hl.dsp.layout('swapnext'))" ;;
        r) hyprctl eval "hl.dispatch(hl.dsp.layout('swapprev'))" ;;
    esac
fi
