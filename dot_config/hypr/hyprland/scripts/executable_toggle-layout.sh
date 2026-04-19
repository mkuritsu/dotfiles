#!/usr/bin/env bash

json=$(hyprctl activeworkspace -j)
current_workspace=$(echo "$json" | jq -r '.id')
current_layout=$(echo "$json" | jq -r '.tiledLayout')

new_layout="scrolling"

if [ "$current_layout" = "scrolling" ]; then
    new_layout="dwindle"
fi

hyprctl keyword workspace $current_workspace, layout:$new_layout
notify-send " " "Layout changed to $new_layout"
