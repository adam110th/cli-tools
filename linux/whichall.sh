#!/usr/bin/env bash
# whichall - list every executable on PATH matching each NAME, in PATH order (first = the one that runs).
# Usage: whichall.sh NAME [NAME...]
set -u
[[ $# -ge 1 ]] || { echo "Usage: whichall.sh NAME [NAME...]" >&2; exit 1; }
IFS=: read -r -a parts <<< "${PATH:-}"
rc=0
for name in "$@"; do
    found=0
    for d in "${parts[@]}"; do
        f="${d:-.}/$name"
        if [[ -x "$f" && ! -d "$f" ]]; then echo "$f"; found=1; fi
    done
    [[ $found -eq 1 ]] || { echo "$name: not found on PATH" >&2; rc=1; }
done
exit $rc
