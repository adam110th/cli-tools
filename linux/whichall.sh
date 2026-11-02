#!/usr/bin/env bash
# whichall - list every executable on PATH matching each NAME, in PATH order (first = the one that runs).
# Usage: whichall.sh NAME [NAME...]
set -u
# colour only on a terminal, and never when NO_COLOR is set (https://no-color.org); E* are the stderr set.
# Not every tool uses every colour, hence the SC2034 directive.
# shellcheck disable=SC2034
{ if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' C=$'\e[1;36m' B=$'\e[1m' D=$'\e[2m' N=$'\e[0m'; else R='' G='' Y='' C='' B='' D='' N=''; fi
  if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then ER=$'\e[31m' EY=$'\e[33m' EB=$'\e[1m' EN=$'\e[0m'; else ER='' EY='' EB='' EN=''; fi; }
[[ $# -ge 1 ]] || { echo "${ER}Usage: whichall.sh NAME [NAME...]${EN}" >&2; exit 1; }
IFS=: read -r -a parts <<< "${PATH:-}"
rc=0
for name in "$@"; do
    found=0
    for d in "${parts[@]}"; do
        f="${d:-.}/$name"
        if [[ -x "$f" && ! -d "$f" ]]; then
            if [[ $found -eq 0 ]]; then echo "$G$f$N"; else echo "$D$f$N"; fi; found=1
        fi
    done
    [[ $found -eq 1 ]] || { echo "${ER}$name: not found on PATH${EN}" >&2; rc=1; }
done
exit $rc
