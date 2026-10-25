#!/usr/bin/env bash
# dirsize - largest immediate subfolders of a directory (stays on one filesystem).
# Usage: dirsize.sh [PATH] [TOP]   (defaults: current directory, 15)
set -u
p="${1:-.}" top="${2:-15}"
[[ -d "$p" ]] || { echo "Not a directory: $p" >&2; exit 1; }
[[ "$top" =~ ^[0-9]+$ && $top -ge 1 ]] || { echo "TOP must be a positive number" >&2; exit 1; }
du -xh --max-depth=1 -- "$p" 2>/dev/null | sort -rh | head -n $((top + 1))
