# sysinfo

One-screen summary of the machine: host, user, OS and build, manufacturer/model, serial number, uptime, CPU, memory and fixed disks. Windows versions also show Entra ID / domain join status and tenant name, which is handy when checking Intune enrolment.

| Platform | Usage |
|---|---|
| Linux | `sysinfo.sh` |
| PowerShell | `sysinfo.ps1` |
| cmd | `sysinfo` |

## Notes
- **Serial number:** on Linux it is read from `/sys/class/dmi/id/product_serial`, which needs root (`sudo sysinfo.sh`). Virtual machines may report a placeholder.
- **Join status** comes from `dsregcmd /status` (`AzureAdJoined`, `DomainJoined`, `WorkplaceJoined`, `TenantName`).
- The cmd version uses `systeminfo`, which takes around 10 seconds, and matches English field labels. On a non-English Windows install some lines will not appear; use the PowerShell version instead.
- The cmd version calls PowerShell for the serial number and disk list, because `wmic` is deprecated and removed from current Windows 11 builds.
