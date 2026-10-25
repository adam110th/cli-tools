#!/usr/bin/env bash
# mdmstatus - Intune status on Linux (Ubuntu/RHEL with the Microsoft Intune app).
# Usage: mdmstatus.sh       Exit: 0 Intune app present, 2 not installed
# Linux has no MDM enrolment equivalent to Windows; this checks the Intune app and identity broker.
set -u
installed=""
if command -v dpkg-query >/dev/null 2>&1; then installed="$(dpkg-query -W -f='${Version}' intune-portal 2>/dev/null)"
elif command -v rpm >/dev/null 2>&1; then installed="$(rpm -q --qf '%{VERSION}' intune-portal 2>/dev/null | grep -v 'not installed')"; fi
if [[ -z "$installed" ]]; then
    echo "Microsoft Intune app (intune-portal) is not installed - this device is not Intune-managed."
    exit 2
fi
echo "Intune app (intune-portal): $installed"
printf '%-38s %s\n' "microsoft-identity-device-broker (system):" "$(systemctl is-active microsoft-identity-device-broker 2>/dev/null || echo unknown)"
printf '%-38s %s\n' "microsoft-identity-broker (user):" "$(systemctl --user is-active microsoft-identity-broker 2>/dev/null || echo unknown)"
echo
echo "To sync or check compliance: open the Intune app (intune-portal) and use 'Refresh'."
echo "Logs: journalctl --user -u microsoft-identity-broker ; journalctl -u microsoft-identity-device-broker"
exit 0
