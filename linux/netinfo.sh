#!/usr/bin/env bash
# netinfo - addresses, default gateway and DNS servers; public IP only with --public.
# Usage: netinfo.sh [--public]
set -u
PUBLIC=0
case "${1:-}" in --public|-p) PUBLIC=1 ;; "") ;; *) echo "Usage: netinfo.sh [--public]" >&2; exit 1 ;; esac
echo "Host: $(hostname)"
echo; echo "Interfaces:"
if command -v ip >/dev/null; then ip -brief address show | grep -v '^lo ' | sed 's/^/  /'
elif command -v ifconfig >/dev/null; then ifconfig | grep -E 'flags|inet ' | sed 's/^/  /'
else echo '  (ip and ifconfig not available)'; fi
echo; echo "Default gateway:"
if command -v ip >/dev/null; then ip route show default | sed 's/^/  /'
else awk 'NR>1 && $2=="00000000"{printf "  via %d.%d.%d.%d dev %s\n", strtonum("0x" substr($3,7,2)), strtonum("0x" substr($3,5,2)), strtonum("0x" substr($3,3,2)), strtonum("0x" substr($3,1,2)), $1}' /proc/net/route 2>/dev/null; fi
echo; echo "DNS servers:"
if command -v resolvectl >/dev/null && resolvectl dns >/dev/null 2>&1; then resolvectl dns | sed 's/^/  /'
else grep '^nameserver' /etc/resolv.conf 2>/dev/null | sed 's/^/  /'; fi
if [[ $PUBLIC -eq 1 ]]; then
    echo; printf 'Public IP: '; curl -fsS --max-time 5 https://api.ipify.org || echo "(lookup failed)"; echo
fi
