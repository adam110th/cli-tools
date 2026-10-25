#!/usr/bin/env bash
# pendingreboot - is a reboot pending, and why?
# Usage: pendingreboot.sh     Exit: 0 no reboot pending, 2 reboot pending
set -u
p=0
if [[ -f /var/run/reboot-required ]]; then
    echo "PENDING: /var/run/reboot-required exists (Debian/Ubuntu)"; p=1
    [[ -f /var/run/reboot-required.pkgs ]] && sort -u /var/run/reboot-required.pkgs | sed 's/^/  package: /'
fi
if command -v needs-restarting >/dev/null 2>&1; then
    needs-restarting -r >/dev/null 2>&1
    [[ $? -eq 1 ]] && { echo "PENDING: needs-restarting -r reports a reboot is required (RHEL/Fedora)"; p=1; }
fi
running="$(uname -r)"
newest="$(find /boot -maxdepth 1 -name 'vmlinuz-*' -printf '%f\n' 2>/dev/null | sed 's/^vmlinuz-//' | sort -V | tail -1)"
if [[ -n "$newest" && "$newest" != "$running" ]]; then
    echo "PENDING: newer kernel installed ($running running, $newest installed)"; p=1
fi
echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
if [[ $p -eq 1 ]]; then echo "Reboot pending."; exit 2; fi
echo "No reboot pending."; exit 0
