#!/usr/bin/env bash
# mdmstatus - Intune status on Linux (Ubuntu/RHEL with the Microsoft Intune app).
# Usage: mdmstatus.sh       Exit: 0 Intune app present, 2 not installed
# Linux has no MDM enrolment equivalent to Windows; this checks the Intune app and identity broker.
set -u
# colour only on a terminal, and never when NO_COLOR is set (https://no-color.org); E* are the stderr set.
# Not every tool uses every colour, hence the SC2034 directive.
# shellcheck disable=SC2034
{ if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' C=$'\e[1;36m' B=$'\e[1m' D=$'\e[2m' N=$'\e[0m'; else R='' G='' Y='' C='' B='' D='' N=''; fi
  if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then ER=$'\e[31m' EY=$'\e[33m' EB=$'\e[1m' EN=$'\e[0m'; else ER='' EY='' EB='' EN=''; fi; }
installed=""
if command -v dpkg-query >/dev/null 2>&1; then installed="$(dpkg-query -W -f='${Version}' intune-portal 2>/dev/null)"
elif command -v rpm >/dev/null 2>&1; then installed="$(rpm -q --qf '%{VERSION}' intune-portal 2>/dev/null | grep -v 'not installed')"; fi
if [[ -z "$installed" ]]; then
    echo "${R}Microsoft Intune app (intune-portal) is not installed - this device is not Intune-managed.${N}"
    exit 2
fi
echo "${C}Intune app (intune-portal):${N} ${G}$installed${N}"
# service state: active green, unknown yellow, anything else red
svc() { local s; s="$("$@" 2>/dev/null || echo unknown)"; case "$s" in active) echo "$G$s$N" ;; unknown) echo "$Y$s$N" ;; *) echo "$R$s$N" ;; esac; }
printf '%-38s %s\n' "microsoft-identity-device-broker (system):" "$(svc systemctl is-active microsoft-identity-device-broker)"
printf '%-38s %s\n' "microsoft-identity-broker (user):" "$(svc systemctl --user is-active microsoft-identity-broker)"
echo
echo "${D}To sync or check compliance: open the Intune app (intune-portal) and use 'Refresh'."
echo "Logs: journalctl --user -u microsoft-identity-broker ; journalctl -u microsoft-identity-device-broker${N}"
exit 0
