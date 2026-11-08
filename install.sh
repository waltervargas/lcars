#!/bin/sh
# Symlink theme targets into place. Usage: install.sh [-n] [target ...]
#   -n  dry run: print what would happen and change nothing
# With no targets, installs the defaults for this OS. Existing files are kept
# as <file>.bak-<timestamp>.
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
config=${XDG_CONFIG_HOME:-$HOME/.config}
stamp=$(date +%Y%m%d-%H%M%S)

# Targets installed by default on each OS.
case $(uname -s) in
    Linux) defaults="sway swaynag foot kitty glow" ;;
    Darwin) defaults="kitty" ;;
    *) defaults="" ;;
esac

# Where each target's files go. Add new targets here.
dest() {
    case $1 in
        sway | swaynag | foot | kitty | glow) echo "$config/$1" ;;
        *) return 1 ;;
    esac
}

dry=false
if [ "${1:-}" = "-n" ]; then
    dry=true
    shift
fi
[ $# -gt 0 ] || set -- $defaults

for target in "$@"; do
    if [ ! -d "$root/targets/$target" ] || ! dir=$(dest "$target"); then
        echo "unknown target: $target" >&2
        exit 1
    fi
    find "$root/targets/$target" -type f ! -name README.md | while IFS= read -r src; do
        dst="$dir/${src#"$root/targets/$target/"}"
        if [ "$(readlink "$dst" 2>/dev/null || true)" = "$src" ]; then
            continue
        fi
        echo "link $dst -> $src"
        "$dry" && continue
        mkdir -p "$(dirname "$dst")"
        if [ -e "$dst" ] || [ -L "$dst" ]; then
            mv "$dst" "$dst.bak-$stamp"
        fi
        ln -s "$src" "$dst"
    done
done
