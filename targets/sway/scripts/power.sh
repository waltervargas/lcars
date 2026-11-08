#!/bin/sh
# Power menu: lock, suspend, log out, reboot, shut down. Uses wlogout with the
# layout and style in ~/.config/wlogout; without wlogout, falls back to a
# swaynag prompt to end the session.
if command -v wlogout >/dev/null; then
    exec wlogout -b 5 -p layer-shell -T 300 -B 300 -L 80 -R 80
fi
exec swaynag -t lcars -m 'End this Wayland session?' -B 'Exit sway' 'swaymsg exit'
