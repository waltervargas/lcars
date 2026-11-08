#!/bin/sh
# Usage: volume.sh up|down|mute. Changes the default sink with wpctl, then shows
# the level in the on-screen bar.
scripts=$(dirname "$0")
case $1 in
    up) wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
    down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
    *) echo "usage: $0 up|down|mute" >&2; exit 1 ;;
esac
out=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)  # "Volume: 0.74 [MUTED]"
pct=$(echo "$out" | awk '{printf "%d", $2 * 100 + 0.5}')
case $out in
    *MUTED*) "$scripts/osd.sh" "$pct" muted ;;
    *) "$scripts/osd.sh" "$pct" vol ;;
esac
