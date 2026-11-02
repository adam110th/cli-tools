#!/usr/bin/env bash
# dnscheck - resolve a name with the system resolver and other DNS servers side by side.
# Usage: dnscheck.sh NAME [TYPE] [SERVER...]
#   TYPE defaults to A. SERVERs default to 1.1.1.1 and 8.8.8.8; pass "none" for the system resolver only.
#   Note: querying public servers sends the name being looked up to those providers.
set -u
# colour only on a terminal, and never when NO_COLOR is set (https://no-color.org); E* are the stderr set.
# Not every tool uses every colour, hence the SC2034 directive.
# shellcheck disable=SC2034
{ if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' C=$'\e[1;36m' B=$'\e[1m' D=$'\e[2m' N=$'\e[0m'; else R='' G='' Y='' C='' B='' D='' N=''; fi
  if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then ER=$'\e[31m' EY=$'\e[33m' EB=$'\e[1m' EN=$'\e[0m'; else ER='' EY='' EB='' EN=''; fi; }
[[ $# -ge 1 ]] || { echo "${ER}Usage: dnscheck.sh NAME [TYPE] [SERVER...]${EN}" >&2; exit 1; }
name="$1" type="${2:-A}"; shift; [[ $# -gt 0 ]] && shift
type="${type^^}"
[[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "${ER}Invalid name: $name${EN}" >&2; exit 1; }
[[ "$type" =~ ^(A|AAAA|CNAME|MX|TXT|NS|SRV|SOA|PTR)$ ]] || { echo "${ER}TYPE must be A, AAAA, CNAME, MX, TXT, NS, SRV, SOA or PTR${EN}" >&2; exit 1; }
servers=("$@"); [[ ${#servers[@]} -eq 0 ]] && servers=(1.1.1.1 8.8.8.8)
[[ "${servers[0]}" == none ]] && servers=()
for s in "${servers[@]}"; do [[ "$s" =~ ^[A-Za-z0-9.:_-]+$ ]] || { echo "${ER}Invalid server: $s${EN}" >&2; exit 1; }; done

if ! command -v dig >/dev/null && ! command -v nslookup >/dev/null; then
    echo "${ER}Needs dig (dnsutils / bind-utils) or nslookup${EN}" >&2; exit 1
fi
if ! command -v dig >/dev/null; then
    echo "${Y}dig not found (install dnsutils / bind-utils); showing nslookup output instead.${N}"
    nslookup -type="$type" "$name"
    for s in "${servers[@]}"; do echo "${C}===== $s =====${N}"; nslookup -type="$type" "$name" "$s"; done
    exit 0
fi

declare -a labels=() answers=()
q() { dig +short +time=3 +tries=1 "$@" "$name" "$type" 2>/dev/null | sort | paste -sd' '; }
labels+=("system"); answers+=("$(q)")
for s in "${servers[@]}"; do labels+=("$s"); answers+=("$(q "@$s")"); done

for i in "${!labels[@]}"; do printf '%s%-16s%s %s\n' "$C" "${labels[i]}" "$N" "${answers[i]:-${D}(no answer)${N}}"; done
for a in "${answers[@]}"; do
    if [[ "$a" != "${answers[0]}" ]]; then echo; echo "${Y}MISMATCH between resolvers (normal for CDNs; otherwise check DNS filtering or split DNS)${N}"; exit 2; fi
done
echo; echo "${G}All resolvers agree.${N}"; exit 0
