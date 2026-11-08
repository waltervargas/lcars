#!/bin/sh
# Usage: brightness.sh +5|-5. Goes through logind, so it needs no root or video group.
dev=$(ls /sys/class/backlight 2>/dev/null | head -n1)
[ -n "$dev" ] || exit 0  # no backlight, e.g. a desktop monitor
cur=$(cat "/sys/class/backlight/$dev/brightness")
max=$(cat "/sys/class/backlight/$dev/max_brightness")
new=$((cur + max * $1 / 100))
[ "$new" -gt "$max" ] && new=$max
[ "$new" -lt $((max / 100 + 1)) ] && new=$((max / 100 + 1))
busctl call org.freedesktop.login1 /org/freedesktop/login1/session/auto \
    org.freedesktop.login1.Session SetBrightness ssu backlight "$dev" "$new"
exec "$(dirname "$0")/osd.sh" $((new * 100 / max)) lum
