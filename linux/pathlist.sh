#!/usr/bin/env bash
# pathlist - print each PATH entry on its own line, flagging missing and duplicate entries.
# Usage: pathlist.sh
set -u
# colour only on a terminal, and never when NO_COLOR is set (https://no-color.org); E* are the stderr set.
# Not every tool uses every colour, hence the SC2034 directive.
# shellcheck disable=SC2034
{ if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' C=$'\e[1;36m' B=$'\e[1m' D=$'\e[2m' N=$'\e[0m'; else R='' G='' Y='' C='' B='' D='' N=''; fi
  if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then ER=$'\e[31m' EY=$'\e[33m' EB=$'\e[1m' EN=$'\e[0m'; else ER='' EY='' EB='' EN=''; fi; }
declare -A seen=()
IFS=: read -r -a parts <<< "${PATH:-}"
n=0
for p in "${parts[@]}"; do
    n=$((n + 1)); flag=""
    if [[ -z "$p" ]]; then p="${Y}(empty - means current directory)${N}"
    else
        [[ -d "$p" ]] || flag+=" ${Y}[missing]${N}"
        [[ -n "${seen[$p]:-}" ]] && flag+=" ${Y}[duplicate]${N}"
        seen[$p]=1
    fi
    printf '%s%3d%s  %s%s\n' "$D" "$n" "$N" "$p" "$flag"
done
