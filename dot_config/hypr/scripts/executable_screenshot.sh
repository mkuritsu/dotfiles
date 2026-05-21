#!/usr/bin/env bash

killall hyprpicker 2> /dev/null
killall slurp 2> /dev/null

MODE="${1:-area}"
case "$MODE" in
    area)
        hyprpicker -r -z >/dev/null 2>&1 &
        PID=$!
        sleep .1
        SELECTION=$(slurp 2>/dev/null)
        kill $PID 2>/dev/null
        [ -z "$SELECTION" ] && exit 0
        grim -g "$SELECTION" - | wl-copy
        ;;

    monitor)
        grim -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" - | wl-copy
        ;;
esac

