#!/usr/bin/env bash
# pendingreboot - is a reboot pending, and why?
# Usage: pendingreboot.sh     Exit: 0 no reboot pending, 2 reboot pending
set -u
# colour only on a terminal, and never when NO_COLOR is set (https://no-color.org); E* are the stderr set.
# Not every tool uses every colour, hence the SC2034 directive.
# shellcheck disable=SC2034
{ if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' C=$'\e[1;36m' B=$'\e[1m' D=$'\e[2m' N=$'\e[0m'; else R='' G='' Y='' C='' B='' D='' N=''; fi
  if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then ER=$'\e[31m' EY=$'\e[33m' EB=$'\e[1m' EN=$'\e[0m'; else ER='' EY='' EB='' EN=''; fi; }
p=0
if [[ -f /var/run/reboot-required ]]; then
    echo "${Y}PENDING:${N} /var/run/reboot-required exists (Debian/Ubuntu)"; p=1
    [[ -f /var/run/reboot-required.pkgs ]] && sort -u /var/run/reboot-required.pkgs | sed "s/^/  ${D}package:${N} /"
fi
if command -v needs-restarting >/dev/null 2>&1; then
    needs-restarting -r >/dev/null 2>&1
    [[ $? -eq 1 ]] && { echo "${Y}PENDING:${N} needs-restarting -r reports a reboot is required (RHEL/Fedora)"; p=1; }
fi
running="$(uname -r)"
newest="$(find /boot -maxdepth 1 -name 'vmlinuz-*' -printf '%f\n' 2>/dev/null | sed 's/^vmlinuz-//' | sort -V | tail -1)"
if [[ -n "$newest" && "$newest" != "$running" ]]; then
    echo "${Y}PENDING:${N} newer kernel installed ($running running, $newest installed)"; p=1
fi
echo "${C}Uptime:${N} $(uptime -p 2>/dev/null || uptime)"
if [[ $p -eq 1 ]]; then echo "${Y}Reboot pending.${N}"; exit 2; fi
echo "${G}No reboot pending.${N}"; exit 0
