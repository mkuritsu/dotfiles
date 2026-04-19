#!/usr/bin/env bash

if grep -q closed /proc/acpi/button/lid/*/state; then
    hyprctl keyword monitor "eDP-1,disable"
fi