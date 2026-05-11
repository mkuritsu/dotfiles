#!/usr/bin/env bash

killall hyprpicker
killall slurp

hyprpicker -r -z >/dev/null 2>&1 &
PID=$!
sleep .1
SELECTION=$(slurp 2>/dev/null)
kill $PID 2>/dev/null
grim -g "$SELECTION" - | wl-copy
