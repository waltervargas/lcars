#!/bin/sh
# Clipboard history: pick an entry with wmenu and copy it back to the clipboard.
# Needs cliphist and `wl-paste --watch cliphist store` running (see sway config).
command -v cliphist >/dev/null || exit 0
cliphist list \
    | wmenu -b -i -l 12 -p CLIPBOARD -f 'Liberation Sans Narrow Bold 13' \
        -N 000000 -n FFCC99 -M FF9900 -m 000000 -S FF9900 -s 000000 \
    | cliphist decode \
    | wl-copy
