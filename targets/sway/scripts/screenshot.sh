#!/bin/sh
# Usage: screenshot.sh [region]. Saves to ~/Pictures/Screenshots and copies to the clipboard.
if ! command -v grim >/dev/null; then
    swaynag -t lcars -m 'grim is not installed. Run: sudo apt install grim slurp'
    exit 1
fi
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
if [ "$1" = region ]; then
    area=$(slurp) || exit 0
    grim -g "$area" "$file"
else
    grim "$file"
fi && wl-copy --type image/png < "$file"
