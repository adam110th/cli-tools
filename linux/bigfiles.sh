#!/usr/bin/env bash
# bigfiles - largest files under a directory (stays on one filesystem).
# Usage: bigfiles.sh [PATH] [TOP]   (defaults: current directory, 20)
set -u
# colour only on a terminal, and never when NO_COLOR is set (https://no-color.org); E* are the stderr set.
# Not every tool uses every colour, hence the SC2034 directive.
# shellcheck disable=SC2034
{ if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' C=$'\e[1;36m' B=$'\e[1m' D=$'\e[2m' N=$'\e[0m'; else R='' G='' Y='' C='' B='' D='' N=''; fi
  if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then ER=$'\e[31m' EY=$'\e[33m' EB=$'\e[1m' EN=$'\e[0m'; else ER='' EY='' EB='' EN=''; fi; }
p="${1:-.}" top="${2:-20}"
[[ -d "$p" ]] || { echo "${ER}Not a directory: $p${EN}" >&2; exit 1; }
[[ "$top" =~ ^[0-9]+$ && $top -ge 1 ]] || { echo "${ER}TOP must be a positive number${EN}" >&2; exit 1; }
find "$p" -xdev -type f -printf '%s\t%p\n' 2>/dev/null | sort -rn | head -n "$top" \
    | numfmt --to=iec --suffix=B --field=1 -d $'\t' --padding=8 | sed "s/^/$B/; s/\t/$N\t/"   # sizes in bold
