#!/usr/bin/env bash
# portowner - show which process is listening on (or using) a local port.
# Usage: portowner.sh PORT    (run with sudo to see other users' processes)
set -u
port="${1:-}"
[[ "$port" =~ ^[0-9]+$ && $port -ge 1 && $port -le 65535 ]] || { echo "Usage: portowner.sh PORT (1-65535)" >&2; exit 1; }
if command -v ss >/dev/null; then
    out="$(ss -Htanup "( sport = :$port )" 2>/dev/null)"
    [[ -n "$out" ]] || { echo "Nothing is using local port $port"; exit 2; }
    printf '%-6s %-10s %-28s %-28s %s\n' Proto State Local Peer Process
    echo "$out" | awk '{printf "%-6s %-10s %-28s %-28s %s\n",$1,$2,$5,$6,$7}'
elif command -v lsof >/dev/null; then
    lsof -nP -i ":$port" || { echo "Nothing is using local port $port"; exit 2; }
else
    echo "Needs ss (iproute2) or lsof" >&2; exit 1
fi
[[ $EUID -eq 0 ]] || echo "(process names may be hidden for other users; re-run with sudo)"
