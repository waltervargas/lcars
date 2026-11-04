#!/bin/sh
# Application launcher, equivalent to i3's dmenu_run but using wmenu.
find -L $(printf %s "$PATH" | tr : ' ') -maxdepth 1 -type f -executable -printf '%f\n' 2>/dev/null \
    | sort -u \
    | wmenu -b -i -p LCARS -f 'Liberation Sans Narrow Bold 13' \
        -N 000000 -n FFCC99 -M FF9900 -m 000000 -S FF9900 -s 000000 \
    | xargs -r swaymsg exec --
