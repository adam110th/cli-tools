#!/usr/bin/env bash
# dnscheck - resolve a name with the system resolver and other DNS servers side by side.
# Usage: dnscheck.sh NAME [TYPE] [SERVER...]
#   TYPE defaults to A. SERVERs default to 1.1.1.1 and 8.8.8.8; pass "none" for the system resolver only.
#   Note: querying public servers sends the name being looked up to those providers.
set -u
[[ $# -ge 1 ]] || { echo "Usage: dnscheck.sh NAME [TYPE] [SERVER...]" >&2; exit 1; }
name="$1" type="${2:-A}"; shift; [[ $# -gt 0 ]] && shift
type="${type^^}"
[[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "Invalid name: $name" >&2; exit 1; }
[[ "$type" =~ ^(A|AAAA|CNAME|MX|TXT|NS|SRV|SOA|PTR)$ ]] || { echo "TYPE must be A, AAAA, CNAME, MX, TXT, NS, SRV, SOA or PTR" >&2; exit 1; }
servers=("$@"); [[ ${#servers[@]} -eq 0 ]] && servers=(1.1.1.1 8.8.8.8)
[[ "${servers[0]}" == none ]] && servers=()
for s in "${servers[@]}"; do [[ "$s" =~ ^[A-Za-z0-9.:_-]+$ ]] || { echo "Invalid server: $s" >&2; exit 1; }; done

if ! command -v dig >/dev/null && ! command -v nslookup >/dev/null; then
    echo "Needs dig (dnsutils / bind-utils) or nslookup" >&2; exit 1
fi
if ! command -v dig >/dev/null; then
    echo "dig not found (install dnsutils / bind-utils); showing nslookup output instead."
    nslookup -type="$type" "$name"
    for s in "${servers[@]}"; do echo "===== $s ====="; nslookup -type="$type" "$name" "$s"; done
    exit 0
fi

declare -a labels=() answers=()
q() { dig +short +time=3 +tries=1 "$@" "$name" "$type" 2>/dev/null | sort | paste -sd' '; }
labels+=("system"); answers+=("$(q)")
for s in "${servers[@]}"; do labels+=("$s"); answers+=("$(q "@$s")"); done

for i in "${!labels[@]}"; do printf '%-16s %s\n' "${labels[i]}" "${answers[i]:-(no answer)}"; done
for a in "${answers[@]}"; do
    if [[ "$a" != "${answers[0]}" ]]; then echo; echo "MISMATCH between resolvers (normal for CDNs; otherwise check DNS filtering or split DNS)"; exit 2; fi
done
echo; echo "All resolvers agree."; exit 0
