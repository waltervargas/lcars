#!/bin/sh
# Lock after 10 minutes idle, blank displays after 15, and lock before suspend.
command -v swayidle >/dev/null || exit 0
lock="$HOME/.config/sway/scripts/lock.sh"
exec swayidle -w \
    timeout 600 "$lock" \
    timeout 900 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
    before-sleep "$lock"
