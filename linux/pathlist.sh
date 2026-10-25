#!/usr/bin/env bash
# pathlist - print each PATH entry on its own line, flagging missing and duplicate entries.
# Usage: pathlist.sh
set -u
declare -A seen=()
IFS=: read -r -a parts <<< "${PATH:-}"
n=0
for p in "${parts[@]}"; do
    n=$((n + 1)); flag=""
    if [[ -z "$p" ]]; then p="(empty - means current directory)"
    else
        [[ -d "$p" ]] || flag+=" [missing]"
        [[ -n "${seen[$p]:-}" ]] && flag+=" [duplicate]"
        seen[$p]=1
    fi
    printf '%3d  %s%s\n' "$n" "$p" "$flag"
done
