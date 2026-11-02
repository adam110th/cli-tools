#!/usr/bin/env bash
# eventerrors - recent critical and error log entries.
# Usage: eventerrors.sh [HOURS] [MAX] [--warnings]   (defaults: 24, 50)
# Run with sudo to include system-wide entries.
set -u
# colour only on a terminal, and never when NO_COLOR is set (https://no-color.org); E* are the stderr set.
# Not every tool uses every colour, hence the SC2034 directive.
# shellcheck disable=SC2034
{ if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' C=$'\e[1;36m' B=$'\e[1m' D=$'\e[2m' N=$'\e[0m'; else R='' G='' Y='' C='' B='' D='' N=''; fi
  if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then ER=$'\e[31m' EY=$'\e[33m' EB=$'\e[1m' EN=$'\e[0m'; else ER='' EY='' EB='' EN=''; fi; }
hours=24 max=50 prio="0..3"
pos=()
for a in "$@"; do
    case "$a" in --warnings|-w) prio="0..4" ;; -h|--help) sed -n '2,4p' "$0"; exit 0 ;; *) pos+=("$a") ;; esac
done
[[ ${#pos[@]} -ge 1 ]] && hours="${pos[0]}"
[[ ${#pos[@]} -ge 2 ]] && max="${pos[1]}"
[[ "$hours" =~ ^[0-9]+$ && $hours -ge 1 ]] || { echo "${ER}HOURS must be a positive number${EN}" >&2; exit 1; }
[[ "$max" =~ ^[0-9]+$ && $max -ge 1 ]] || { echo "${ER}MAX must be a positive number${EN}" >&2; exit 1; }
if command -v journalctl >/dev/null 2>&1; then
    journalctl -p "$prio" --since "$hours hours ago" -n "$max" --no-pager -o short-iso -q
    rc=$?
    [[ $EUID -eq 0 ]] || echo "${D}(only entries visible to $(id -un); run with sudo for all)${N}"
    exit $rc
fi
for log in /var/log/syslog /var/log/messages; do
    if [[ -r "$log" ]]; then grep -iE 'emerg|alert|crit|error|fail' "$log" | tail -n "$max"; exit 0; fi
done
echo "${ER}No journalctl and no readable syslog found${EN}" >&2; exit 1
