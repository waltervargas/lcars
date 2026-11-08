#!/bin/sh
# Night light with wlsunset: warm the display between sunset and sunrise.
# Usage: nightlight.sh         start it (sway startup)
#        nightlight.sh toggle  stop it if running, else start it
# Latitude and longitude of Berlin; change them for your location.
# wlsunset 0.3 has no toggle signal, so toggling stops and starts the process.
command -v wlsunset >/dev/null || exit 0
if pgrep -x wlsunset >/dev/null; then
    [ "$1" = toggle ] && pkill -x wlsunset
    exit 0
fi
exec wlsunset -l 52.5 -L 13.4 -t 4000 -T 6500
