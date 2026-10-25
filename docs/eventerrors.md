# eventerrors

Lists recent critical and error events, with a count by source, as a quick first look when a machine is misbehaving.

| Platform | Usage |
|---|---|
| PowerShell | `eventerrors.ps1 [-Hours N] [-Max N] [-IncludeWarnings] [-LogName LOG,...]` |
| cmd | `eventerrors [-Hours N] [-Max N] [-IncludeWarnings] [-LogName LOG,...]` (wrapper) |
| Linux | `eventerrors.sh [HOURS] [MAX] [--warnings]` |

Defaults: last 24 hours, at most 50 events, System and Application logs (Windows).

## Useful Windows logs
Pass any event log name to `-LogName`, for example:
- `Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin` - Intune / MDM policy errors
- `Microsoft-Windows-AAD/Operational` - Entra ID sign-in and token errors
- `Microsoft-Windows-Windows Defender/Operational` - Defender detections and errors

```
eventerrors.ps1 -Hours 72 -LogName 'Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin'
```

## Linux
Uses `journalctl` priorities 0-3 (emergency to error), or 0-4 with `--warnings`. Without root you only see your own and some system entries; use `sudo` for everything. Falls back to `/var/log/syslog` or `/var/log/messages` when journald is not present.

## Notes
- Messages are trimmed to their first line; open Event Viewer (`eventvwr.msc`) for full detail.
- Exit code is `0` whenever the query runs, whether or not events were found.
