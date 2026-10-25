# netinfo

Shows network adapters, addresses, default gateway and DNS servers. Optionally shows the public IP.

| Platform | Usage |
|---|---|
| Linux | `netinfo.sh [--public]` |
| PowerShell | `netinfo.ps1 [-Public]` |
| cmd | `netinfo [/public]` |

## Public IP
Off by default. With the switch, the tool makes one HTTPS request to `https://api.ipify.org` (5 second timeout). This sends your public IP to a third-party service; leave it off where that matters.

## Notes
- PowerShell lists only adapters that are up, with IPv4/IPv6, gateway, IPv4 DNS servers and MAC per adapter.
- cmd filters `ipconfig /all`. Only the first DNS server line is labelled by `ipconfig`, so secondary DNS servers may not appear; use the PowerShell version for a complete list.
- Linux uses `ip`, falling back to `ifconfig` and `/proc/net/route`. DNS comes from `resolvectl` when systemd-resolved is in use, otherwise `/etc/resolv.conf`.
- Where DNS is forced through a DoH profile (for example NextDNS deployed by Intune), the adapter DNS servers shown may not be the resolver actually used.
