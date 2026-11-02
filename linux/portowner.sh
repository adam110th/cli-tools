#!/usr/bin/env bash
# portowner - show which process is listening on (or using) a local port.
# Usage: portowner.sh PORT    (run with sudo to see other users' processes)
set -u
# colour only on a terminal, and never when NO_COLOR is set (https://no-color.org); E* are the stderr set.
# Not every tool uses every colour, hence the SC2034 directive.
# shellcheck disable=SC2034
{ if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' C=$'\e[1;36m' B=$'\e[1m' D=$'\e[2m' N=$'\e[0m'; else R='' G='' Y='' C='' B='' D='' N=''; fi
  if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then ER=$'\e[31m' EY=$'\e[33m' EB=$'\e[1m' EN=$'\e[0m'; else ER='' EY='' EB='' EN=''; fi; }
port="${1:-}"
[[ "$port" =~ ^[0-9]+$ && $port -ge 1 && $port -le 65535 ]] || { echo "${ER}Usage: portowner.sh PORT (1-65535)${EN}" >&2; exit 1; }
if command -v ss >/dev/null; then
    out="$(ss -Htanup "( sport = :$port )" 2>/dev/null)"
    [[ -n "$out" ]] || { echo "${Y}Nothing is using local port $port${N}"; exit 2; }
    printf '%s%-6s %-10s %-28s %-28s %s%s\n' "$C" Proto State Local Peer Process "$N"
    echo "$out" | awk '{printf "%-6s %-10s %-28s %-28s %s\n",$1,$2,$5,$6,$7}'
elif command -v lsof >/dev/null; then
    lsof -nP -i ":$port" || { echo "${Y}Nothing is using local port $port${N}"; exit 2; }
else
    echo "${ER}Needs ss (iproute2) or lsof${EN}" >&2; exit 1
fi
[[ $EUID -eq 0 ]] || echo "${D}(process names may be hidden for other users; re-run with sudo)${N}"
