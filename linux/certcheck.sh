#!/usr/bin/env bash
# certcheck - TLS certificate details and expiry for a host.
# Usage: certcheck.sh HOST [PORT] [WARN_DAYS]   (defaults: 443, 30)
# Exit: 0 valid and not expiring soon, 2 expired / expiring within WARN_DAYS / untrusted, 1 error
set -u
# colour only on a terminal, and never when NO_COLOR is set (https://no-color.org); E* are the stderr set.
# Not every tool uses every colour, hence the SC2034 directive.
# shellcheck disable=SC2034
{ if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' C=$'\e[1;36m' B=$'\e[1m' D=$'\e[2m' N=$'\e[0m'; else R='' G='' Y='' C='' B='' D='' N=''; fi
  if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then ER=$'\e[31m' EY=$'\e[33m' EB=$'\e[1m' EN=$'\e[0m'; else ER='' EY='' EB='' EN=''; fi; }
[[ $# -ge 1 ]] || { echo "${ER}Usage: certcheck.sh HOST [PORT] [WARN_DAYS]${EN}" >&2; exit 1; }
host="$1" port="${2:-443}" warn="${3:-30}"
[[ "$host" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "${ER}Invalid host: $host${EN}" >&2; exit 1; }
[[ "$port" =~ ^[0-9]+$ && $port -ge 1 && $port -le 65535 ]] || { echo "${ER}Port must be 1-65535${EN}" >&2; exit 1; }
[[ "$warn" =~ ^[0-9]+$ ]] || { echo "${ER}WARN_DAYS must be a number${EN}" >&2; exit 1; }
command -v openssl >/dev/null || { echo "${ER}Needs openssl${EN}" >&2; exit 1; }

out="$(timeout 10 openssl s_client -connect "$host:$port" -servername "$host" </dev/null 2>/dev/null)"
cert="$(openssl x509 2>/dev/null <<<"$out")"
[[ -n "$cert" ]] || { echo "${R}Could not retrieve a certificate from $host:$port${N}"; exit 1; }

field() { openssl x509 -noout "$1" <<<"$cert" 2>/dev/null | sed 's/^[a-zA-Z]*= *//'; }
start="$(field -startdate)" end="$(field -enddate)"
days=$(( ( $(date -d "$end" +%s) - $(date +%s) ) / 86400 ))
san="$(openssl x509 -noout -ext subjectAltName <<<"$cert" 2>/dev/null | tail -n +2 | sed 's/^ *//')"
verify="$(grep -m1 'Verify return code' <<<"$out" | sed 's/^ *//')"

# shellcheck disable=SC2059  # format holds only colour codes
printf "${C}%-10s${N} %s\n" Host "$host:$port" Subject "$(field -subject)" Issuer "$(field -issuer)" \
    "Valid from" "$(date -d "$start" '+%d/%m/%Y %H:%M %Z')" "Expires" "$(date -d "$end" '+%d/%m/%Y %H:%M %Z')" \
    "Days left" "$days" Names "${san:-n/a}" Chain "${verify:-unknown}"

rc=0
if [[ $days -lt 0 ]]; then echo "${R}EXPIRED${N}"; rc=2
elif [[ $days -lt $warn ]]; then echo "${Y}WARNING: expires within $warn days${N}"; rc=2; fi
[[ "$verify" == *"return code: 0 "* ]] || { echo "${Y}WARNING: certificate chain not trusted by this machine${N}"; rc=2; }
exit $rc
