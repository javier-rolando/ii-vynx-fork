#!/usr/bin/env bash

# Script para cambiar focus de forma inteligente en Hyprland (v3).
# Este script captura la salida estándar (stdout) de hyprctl y reacciona
# si la salida no es "ok", lo que indica un fallo.

DIRECTION=$1

if [ -z "$DIRECTION" ]; then
  echo "Uso: $0 <l|r|u|d>"
  exit 1
fi

# Ejecuta el comando y captura su salida estándar.
# Redirigimos stderr a /dev/null por si acaso.
OUTPUT=$(~/.config/hypr/custom/scripts/dispatch_warp.sh movefocus "$DIRECTION" 2>/dev/null)

# Comprueba si la salida contiene "Nothing to focus", que indica un fallo.
if [[ "$OUTPUT" == *"Nothing to focus"* ]]; then
  # El cycle por defecto falló. Verificamos si fue un intento de cycle horizontal.
  case "$DIRECTION" in
  l)
    # Si el cycle a la izquierda falló, usamos 'cyclenext'.
    ~/.config/hypr/custom/scripts/dispatch_warp.sh layoutmsg cyclenext
    ;;
  r)
    # Si el cycle a la derecha falló, usamos 'cycleprev'.
    ~/.config/hypr/custom/scripts/dispatch_warp.sh layoutmsg cycleprev
    ;;
  *)
    # Para fallos con 'u' o 'd', no hacemos nada.
    ;;
  esac
fi
