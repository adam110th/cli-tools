#!/usr/bin/env bash
# portcheck - test whether a TCP port is reachable.
# Usage: portcheck.sh HOST PORT [TIMEOUT_SECONDS]   (default timeout 3)
set -u
[[ $# -ge 2 ]] || { echo "Usage: portcheck.sh HOST PORT [TIMEOUT_SECONDS]" >&2; exit 1; }
host="$1" port="$2" t="${3:-3}"
[[ "$host" =~ ^[A-Za-z0-9.:_-]+$ ]] || { echo "Invalid host: $host" >&2; exit 1; }
[[ "$port" =~ ^[0-9]+$ && $port -ge 1 && $port -le 65535 ]] || { echo "Port must be 1-65535" >&2; exit 1; }
[[ "$t" =~ ^[0-9]+$ && $t -ge 1 && $t -le 120 ]] || { echo "Timeout must be 1-120 seconds" >&2; exit 1; }
if timeout "$t" bash -c 'exec 3<>"/dev/tcp/$1/$2"' _ "$host" "$port" 2>/dev/null; then
    echo "OPEN    $host:$port"; exit 0
else
    echo "CLOSED  $host:$port (refused, filtered or no answer within ${t}s)"; exit 2
fi
