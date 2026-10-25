# mdmstatus

Shows a device's Intune / MDM state in one place: Entra join, tenant, MDM enrolment and user, last MDM sync time, and the Intune Management Extension (IME) service and logs. Can also trigger a sync.

| Platform | Usage |
|---|---|
| PowerShell | `mdmstatus.ps1 [-Sync]` |
| cmd | `mdmstatus [-Sync]` (wrapper) |
| Linux | `mdmstatus.sh` |

## Windows output
- **Join status** from `dsregcmd /status`: AzureAdJoined, DomainJoined, WorkplaceJoined, TenantName, TenantId, DeviceId.
- **MDM enrolments** from `HKLM\SOFTWARE\Microsoft\Enrollments` (provider `MS DM Server`), with the enrolled UPN and the last run of the `PushLaunch` sync task.
- **Intune Management Extension**: service state, log folder (`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs`) and when the main log last changed. The IME handles Win32 apps, PowerShell scripts and remediations.

## -Sync
- Starts the MDM `PushLaunch` task (policy and configuration sync). Needs an elevated prompt; otherwise use Settings > Accounts > Access work or school > Info > Sync.
- Requests an IME check-in through `intunemanagementextension://syncapp` (Win32 apps and scripts). Works as a standard user.

## Linux
Linux devices are managed through the Microsoft Intune app rather than an MDM enrolment. The Linux version checks whether `intune-portal` is installed and whether the identity broker services are running; sync is done from the Intune app.

## Exit codes
`0` enrolled (Windows) or Intune app present (Linux); `2` not enrolled / not installed.

## Notes
- For a full diagnostic bundle to send to support: `mdmdiagnosticstool.exe -out C:\Temp\MDMDiag`.
- Last sync time may show as unknown without admin rights, because the EnterpriseMgmt scheduled tasks are not always readable by standard users.
