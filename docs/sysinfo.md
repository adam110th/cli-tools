# sysinfo

One-screen summary of the machine: host, user, OS and build, manufacturer/model, serial number, uptime, CPU, memory and fixed disks. Windows versions also show Entra ID / domain join status and tenant name, which is handy when checking Intune enrolment.

| Platform | Usage |
|---|---|
| Linux | `sysinfo.sh` |
| PowerShell | `sysinfo.ps1` |
| cmd | `sysinfo` |

## Notes
- **Serial number:** on Linux it is read from `/sys/class/dmi/id/product_serial`, which needs root (`sudo sysinfo.sh`).
- **Placeholder values:** custom-built PCs often report firmware placeholders such as `System manufacturer`, `System Product Name`, `System Serial Number`, `To be filled by O.E.M.` or `Default string`. These are ignored and the motherboard's maker, model and serial are shown instead, marked `(motherboard)`. If nothing real is reported, `n/a` is shown.
- **Join status** comes from `dsregcmd /status` (`AzureAdJoined`, `DomainJoined`, `WorkplaceJoined`, `TenantName`).
- The cmd version uses `systeminfo`, which takes around 10 seconds, and matches English field labels. On a non-English Windows install some lines will not appear; use the PowerShell version instead.
- The cmd version calls PowerShell for the serial number and disk list, because `wmic` is deprecated and removed from current Windows 11 builds.
