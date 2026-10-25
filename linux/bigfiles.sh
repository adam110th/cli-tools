#!/usr/bin/env bash
# bigfiles - largest files under a directory (stays on one filesystem).
# Usage: bigfiles.sh [PATH] [TOP]   (defaults: current directory, 20)
set -u
p="${1:-.}" top="${2:-20}"
[[ -d "$p" ]] || { echo "Not a directory: $p" >&2; exit 1; }
[[ "$top" =~ ^[0-9]+$ && $top -ge 1 ]] || { echo "TOP must be a positive number" >&2; exit 1; }
find "$p" -xdev -type f -printf '%s\t%p\n' 2>/dev/null | sort -rn | head -n "$top" \
    | numfmt --to=iec --suffix=B --field=1 -d $'\t' --padding=8
