#!/bin/bash

lock="󰌾  Lock"
logout="󰍃  Logout"
reboot="󰜉  Reboot"
shutdown="󰐥  Shutdown"

chosen=$(printf '%s\n%s\n%s\n%s\n' \
    "$lock" "$logout" "$reboot" "$shutdown" |
    rofi -dmenu -i -p "Power")

case "$chosen" in
    "$lock")
        hyprlock
        ;;
    "$logout")
        hyprshutdown --vt 1
        ;;
    "$reboot")
        systemctl reboot
        ;;
    "$shutdown")
        systemctl poweroff
        ;;
esac