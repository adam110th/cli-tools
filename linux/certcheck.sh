#!/usr/bin/env bash
# certcheck - TLS certificate details and expiry for a host.
# Usage: certcheck.sh HOST [PORT] [WARN_DAYS]   (defaults: 443, 30)
# Exit: 0 valid and not expiring soon, 2 expired / expiring within WARN_DAYS / untrusted, 1 error
set -u
[[ $# -ge 1 ]] || { echo "Usage: certcheck.sh HOST [PORT] [WARN_DAYS]" >&2; exit 1; }
host="$1" port="${2:-443}" warn="${3:-30}"
[[ "$host" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "Invalid host: $host" >&2; exit 1; }
[[ "$port" =~ ^[0-9]+$ && $port -ge 1 && $port -le 65535 ]] || { echo "Port must be 1-65535" >&2; exit 1; }
[[ "$warn" =~ ^[0-9]+$ ]] || { echo "WARN_DAYS must be a number" >&2; exit 1; }
command -v openssl >/dev/null || { echo "Needs openssl" >&2; exit 1; }

out="$(timeout 10 openssl s_client -connect "$host:$port" -servername "$host" </dev/null 2>/dev/null)"
cert="$(openssl x509 2>/dev/null <<<"$out")"
[[ -n "$cert" ]] || { echo "Could not retrieve a certificate from $host:$port"; exit 1; }

field() { openssl x509 -noout "$1" <<<"$cert" 2>/dev/null | sed 's/^[a-zA-Z]*= *//'; }
start="$(field -startdate)" end="$(field -enddate)"
days=$(( ( $(date -d "$end" +%s) - $(date +%s) ) / 86400 ))
san="$(openssl x509 -noout -ext subjectAltName <<<"$cert" 2>/dev/null | tail -n +2 | sed 's/^ *//')"
verify="$(grep -m1 'Verify return code' <<<"$out" | sed 's/^ *//')"

printf '%-10s %s\n' Host "$host:$port" Subject "$(field -subject)" Issuer "$(field -issuer)" \
    "Valid from" "$(date -d "$start" '+%d/%m/%Y %H:%M %Z')" "Expires" "$(date -d "$end" '+%d/%m/%Y %H:%M %Z')" \
    "Days left" "$days" Names "${san:-n/a}" Chain "${verify:-unknown}"

rc=0
if [[ $days -lt 0 ]]; then echo "EXPIRED"; rc=2
elif [[ $days -lt $warn ]]; then echo "WARNING: expires within $warn days"; rc=2; fi
[[ "$verify" == *"return code: 0 "* ]] || { echo "WARNING: certificate chain not trusted by this machine"; rc=2; }
exit $rc
