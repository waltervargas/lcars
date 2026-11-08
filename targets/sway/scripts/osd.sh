#!/bin/sh
# On-screen bar for volume and brightness, drawn by wob.
# Usage: osd.sh                       start the wob daemon (sway startup)
#        osd.sh PERCENT [vol|lum|muted]  show PERCENT; starts the daemon if needed
# wob reads "value background border bar" lines from a FIFO; see wob(1).
command -v wob >/dev/null || exit 0
fifo="${XDG_RUNTIME_DIR:-/tmp}/lcars-wob.fifo"
[ -p "$fifo" ] || mkfifo "$fifo"
if ! pgrep -x wob >/dev/null; then
    setsid -f sh -c "tail -f '$fifo' | wob"
fi
[ $# -gt 0 ] || exit 0
case ${2:-vol} in
    lum) bar=FFCC99 ;;    # peach, like the LUM block
    muted) bar=CC4444 ;;  # red
    *) bar=9999FF ;;      # blue, like the VOL block
esac
echo "$1 000000 FF9900 $bar" > "$fifo"
