#!/usr/bin/env bash
# sysinfo - one-screen summary of host, OS, uptime, CPU, memory and disks.
# Usage: sysinfo.sh
set -u
os="unknown"; [[ -r /etc/os-release ]] && os="$(. /etc/os-release; echo "${PRETTY_NAME:-$NAME}")"
cpu="$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2- | sed 's/^ *//')"
serial="$(cat /sys/class/dmi/id/product_serial 2>/dev/null || echo 'n/a (needs root)')"
model="$(cat /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name 2>/dev/null | paste -sd' ')"
printf '%-12s %s\n' Host "$(hostname)" User "$(id -un)" OS "$os" Kernel "$(uname -r) ($(uname -m))" \
    Model "${model:-n/a}" Serial "$serial" Uptime "$(uptime -p 2>/dev/null || uptime)" \
    CPU "${cpu:-n/a} x $(nproc 2>/dev/null || echo ?)"
echo; echo "Memory:"; free -h 2>/dev/null || echo "  free not available"
echo; echo "Disks:"; df -h -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null || df -h
