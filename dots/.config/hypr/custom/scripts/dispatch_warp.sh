#!/usr/bin/env bash

if [ "$#" -eq 0 ]; then
  echo "Uso: $0 <dispatcher> <argumentos...>"
  exit 1
fi

DISPATCHER=$1
shift

hyprctl eval "hl.config({ cursor = { no_warps = false } })"

case "$DISPATCHER" in
  movefocus)
    hyprctl eval "hl.dispatch(hl.dsp.focus({ direction = '$1' }))"
    ;;
  workspace)
    hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = '$1' }))"
    ;;
  layoutmsg)
    hyprctl eval "hl.dispatch(hl.dsp.layout('$1'))"
    ;;
  *)
    hyprctl eval "hl.dispatch(hl.dsp.exec_cmd('hyprctl dispatch $DISPATCHER $*')())" 2>/dev/null \
      || hyprctl dispatch "$DISPATCHER" "$@"
    ;;
esac

hyprctl eval "hl.config({ cursor = { no_warps = true } })"
