#!/usr/bin/env bash
# netinfo - addresses, default gateway and DNS servers; public IP only with --public.
# Usage: netinfo.sh [--public]
set -u
# colour only on a terminal, and never when NO_COLOR is set (https://no-color.org); E* are the stderr set.
# Not every tool uses every colour, hence the SC2034 directive.
# shellcheck disable=SC2034
{ if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' C=$'\e[1;36m' B=$'\e[1m' D=$'\e[2m' N=$'\e[0m'; else R='' G='' Y='' C='' B='' D='' N=''; fi
  if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then ER=$'\e[31m' EY=$'\e[33m' EB=$'\e[1m' EN=$'\e[0m'; else ER='' EY='' EB='' EN=''; fi; }
PUBLIC=0
case "${1:-}" in --public|-p) PUBLIC=1 ;; "") ;; *) echo "${ER}Usage: netinfo.sh [--public]${EN}" >&2; exit 1 ;; esac
echo "${C}Host:${N} $(hostname)"
echo; echo "${C}Interfaces:${N}"
if command -v ip >/dev/null; then ip -brief address show | grep -v '^lo ' | sed 's/^/  /'
elif command -v ifconfig >/dev/null; then ifconfig | grep -E 'flags|inet ' | sed 's/^/  /'
else echo '  (ip and ifconfig not available)'; fi
echo; echo "${C}Default gateway:${N}"
if command -v ip >/dev/null; then ip route show default | sed 's/^/  /'
else awk 'NR>1 && $2=="00000000"{printf "  via %d.%d.%d.%d dev %s\n", strtonum("0x" substr($3,7,2)), strtonum("0x" substr($3,5,2)), strtonum("0x" substr($3,3,2)), strtonum("0x" substr($3,1,2)), $1}' /proc/net/route 2>/dev/null; fi
echo; echo "${C}DNS servers:${N}"
if command -v resolvectl >/dev/null && resolvectl dns >/dev/null 2>&1; then resolvectl dns | sed 's/^/  /'
else grep '^nameserver' /etc/resolv.conf 2>/dev/null | sed 's/^/  /'; fi
if [[ $PUBLIC -eq 1 ]]; then
    echo; printf '%sPublic IP:%s ' "$C" "$N"; curl -fsS --max-time 5 https://api.ipify.org || echo "${R}(lookup failed)${N}"; echo
fi
