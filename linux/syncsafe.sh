#!/usr/bin/env bash
# syncsafe - find files/folders that break Windows or cloud sync: long paths, invalid characters,
# trailing spaces/dots, reserved names (CON, NUL, COM1...), names over 255 characters.
# Usage: syncsafe.sh [PATH] [--max N] [--win-root PREFIX]
#   --max N            path length to flag (default 260, the Windows MAX_PATH limit)
#   --win-root PREFIX  measure lengths as if PATH were mounted at this Windows path,
#                      e.g. --win-root 'X:\GoogleDrive\Shared'
set -u
# colour only on a terminal, and never when NO_COLOR is set (https://no-color.org); E* are the stderr set.
# Not every tool uses every colour, hence the SC2034 directive.
# shellcheck disable=SC2034
{ if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' C=$'\e[1;36m' B=$'\e[1m' D=$'\e[2m' N=$'\e[0m'; else R='' G='' Y='' C='' B='' D='' N=''; fi
  if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then ER=$'\e[31m' EY=$'\e[33m' EB=$'\e[1m' EN=$'\e[0m'; else ER='' EY='' EB='' EN=''; fi; }
root="" max=260 winroot=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --max)      max="${2:-}"; shift 2 || true ;;
        --win-root) winroot="${2:-}"; shift 2 || true ;;
        -h|--help)  sed -n '2,8p' "$0"; exit 0 ;;
        -*)         echo "${ER}Unknown option: $1${EN}" >&2; exit 1 ;;
        *)          root="$1"; shift ;;
    esac
done
root="${root:-.}"
[[ -d "$root" ]] || { echo "${ER}Not a directory: $root${EN}" >&2; exit 1; }
[[ "$max" =~ ^[0-9]+$ && $max -ge 100 ]] || { echo "${ER}--max must be a number >= 100${EN}" >&2; exit 1; }
root="${root%/}"; [[ -z "$root" ]] && root="/"

re_bad='[<>:"|?*\\]'
re_reserved='^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\..*)?$'
count=0
while IFS= read -r -d '' f; do
    name="${f##*/}"
    if [[ -n "$winroot" ]]; then rel="${f#"$root"/}"; full="${winroot%\\}\\${rel//\//\\}"; else full="$f"; fi
    issues=""
    [[ ${#full} -ge $max ]] && issues+="LongPath,"
    [[ ${#name} -gt 255 ]] && issues+="NameTooLong,"
    { [[ "$name" =~ $re_bad ]] || [[ "$name" == *[[:cntrl:]]* ]]; } && issues+="InvalidChar,"
    [[ "$name" == *" " || "$name" == *. ]] && issues+="TrailingSpaceOrDot,"
    [[ "$name" == " "* ]] && issues+="LeadingSpace,"
    [[ "${name^^}" =~ $re_reserved ]] && issues+="ReservedName,"
    if [[ -n "$issues" ]]; then
        printf '%s%-32s%s %s%5d%s  %s\n' "$Y" "${issues%,}" "$N" "$D" "${#full}" "$N" "$full"; count=$((count + 1))
    fi
done < <(find "$root" -mindepth 1 -print0 2>/dev/null)

echo
if [[ $count -eq 0 ]]; then echo "${G}No sync problems found under $root${N}"; exit 0; fi
echo "${R}$count item(s) with problems${N}"; exit 2
