#!/usr/bin/env bash
# eventerrors - recent critical and error log entries.
# Usage: eventerrors.sh [HOURS] [MAX] [--warnings]   (defaults: 24, 50)
# Run with sudo to include system-wide entries.
set -u
hours=24 max=50 prio="0..3"
pos=()
for a in "$@"; do
    case "$a" in --warnings|-w) prio="0..4" ;; -h|--help) sed -n '2,4p' "$0"; exit 0 ;; *) pos+=("$a") ;; esac
done
[[ ${#pos[@]} -ge 1 ]] && hours="${pos[0]}"
[[ ${#pos[@]} -ge 2 ]] && max="${pos[1]}"
[[ "$hours" =~ ^[0-9]+$ && $hours -ge 1 ]] || { echo "HOURS must be a positive number" >&2; exit 1; }
[[ "$max" =~ ^[0-9]+$ && $max -ge 1 ]] || { echo "MAX must be a positive number" >&2; exit 1; }
if command -v journalctl >/dev/null 2>&1; then
    journalctl -p "$prio" --since "$hours hours ago" -n "$max" --no-pager -o short-iso -q
    rc=$?
    [[ $EUID -eq 0 ]] || echo "(only entries visible to $(id -un); run with sudo for all)"
    exit $rc
fi
for log in /var/log/syslog /var/log/messages; do
    if [[ -r "$log" ]]; then grep -iE 'emerg|alert|crit|error|fail' "$log" | tail -n "$max"; exit 0; fi
done
echo "No journalctl and no readable syslog found" >&2; exit 1
