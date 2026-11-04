#!/bin/sh
# Lock the screen. -f returns once locked, so this is safe in before-sleep hooks.
if ! command -v swaylock >/dev/null; then
    swaynag -t lcars -m 'swaylock is not installed: the screen was NOT locked. Run: sudo apt install swaylock'
    exit 1
fi
exec swaylock -f -i "$HOME/.config/sway/lcars.png" --scaling fill \
    --inside-color 000000 --line-color 000000 --separator-color 000000 \
    --ring-color FF9900 --key-hl-color FFCC99 --bs-hl-color CC4444 --text-color FFCC99 \
    --inside-ver-color 000000 --ring-ver-color 9999FF --text-ver-color 9999FF \
    --inside-wrong-color 000000 --ring-wrong-color CC4444 --text-wrong-color CC4444 \
    --inside-clear-color 000000 --ring-clear-color CC99CC --text-clear-color CC99CC
