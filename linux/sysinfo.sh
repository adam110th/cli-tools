#!/usr/bin/env bash
# sysinfo - one-screen summary of host, OS, uptime, CPU, memory and disks.
# Usage: sysinfo.sh
set -u
# colour only on a terminal, and never when NO_COLOR is set (https://no-color.org); E* are the stderr set.
# Not every tool uses every colour, hence the SC2034 directive.
# shellcheck disable=SC2034
{ if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' C=$'\e[1;36m' B=$'\e[1m' D=$'\e[2m' N=$'\e[0m'; else R='' G='' Y='' C='' B='' D='' N=''; fi
  if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then ER=$'\e[31m' EY=$'\e[33m' EB=$'\e[1m' EN=$'\e[0m'; else ER='' EY='' EB='' EN=''; fi; }
os="unknown"; [[ -r /etc/os-release ]] && os="$(. /etc/os-release; echo "${PRETTY_NAME:-$NAME}")"
cpu="$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2- | sed 's/^ *//')"
# DMI value, trimmed; prints nothing for an OEM placeholder, fails if unreadable (serials need root)
dmi() { local v; v="$(cat "/sys/class/dmi/id/$1" 2>/dev/null)" || return 1
    v="${v#"${v%%[![:space:]]*}"}"; v="${v%"${v##*[![:space:]]}"}"
    case "${v,,}" in ""|"system manufacturer"|"system product name"|"system serial number"|"system version"|\
        "to be filled by o.e.m."|"default string"|"not applicable"|none|0|0123456789|"chassis serial number"|\
        "base board serial number"|oem|o.e.m.) return 0 ;; esac
    printf '%s' "$v"; }
# custom-built PCs report placeholders for the system; fall back to the motherboard's values
v="$(dmi sys_vendor)" m="$(dmi product_name)"
if [[ -n "$v" && -n "$m" ]]; then model="$v $m"
else bv="$(dmi board_vendor)" bn="$(dmi board_name)"; model="$bv${bv:+${bn:+ }}$bn"
    if [[ -n "$model" ]]; then model+=" (motherboard)"; else model="$v$m"; fi
fi
if serial="$(dmi product_serial)"; then
    [[ -n "$serial" ]] || { serial="$(dmi board_serial)"; serial="${serial:+$serial (motherboard)}"; serial="${serial:-n/a}"; }
else serial='n/a (needs root)'; fi
# shellcheck disable=SC2059  # format holds only colour codes
printf "${C}%-12s${N} %s\n" Host "$(hostname)" User "$(id -un)" OS "$os" Kernel "$(uname -r) ($(uname -m))" \
    Model "${model:-n/a}" Serial "$serial" Uptime "$(uptime -p 2>/dev/null || uptime)" \
    CPU "${cpu:-n/a} x $(nproc 2>/dev/null || echo ?)"
echo; echo "${C}Memory:${N}"; free -h 2>/dev/null || echo "  free not available"
echo; echo "${C}Disks:${N}"; df -h -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null || df -h
