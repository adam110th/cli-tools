#!/usr/bin/env bash
# portcheck - test whether a TCP port is reachable.
# Usage: portcheck.sh HOST PORT [TIMEOUT_SECONDS]   (default timeout 3)
set -u
# colour only on a terminal, and never when NO_COLOR is set (https://no-color.org); E* are the stderr set.
# Not every tool uses every colour, hence the SC2034 directive.
# shellcheck disable=SC2034
{ if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' C=$'\e[1;36m' B=$'\e[1m' D=$'\e[2m' N=$'\e[0m'; else R='' G='' Y='' C='' B='' D='' N=''; fi
  if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then ER=$'\e[31m' EY=$'\e[33m' EB=$'\e[1m' EN=$'\e[0m'; else ER='' EY='' EB='' EN=''; fi; }
[[ $# -ge 2 ]] || { echo "${ER}Usage: portcheck.sh HOST PORT [TIMEOUT_SECONDS]${EN}" >&2; exit 1; }
host="$1" port="$2" t="${3:-3}"
[[ "$host" =~ ^[A-Za-z0-9.:_-]+$ ]] || { echo "${ER}Invalid host: $host${EN}" >&2; exit 1; }
[[ "$port" =~ ^[0-9]+$ && $port -ge 1 && $port -le 65535 ]] || { echo "${ER}Port must be 1-65535${EN}" >&2; exit 1; }
[[ "$t" =~ ^[0-9]+$ && $t -ge 1 && $t -le 120 ]] || { echo "${ER}Timeout must be 1-120 seconds${EN}" >&2; exit 1; }
if timeout "$t" bash -c 'exec 3<>"/dev/tcp/$1/$2"' _ "$host" "$port" 2>/dev/null; then
    echo "${G}OPEN${N}    $host:$port"; exit 0
else
    echo "${R}CLOSED${N}  $host:$port ${D}(refused, filtered or no answer within ${t}s)${N}"; exit 2
fi
