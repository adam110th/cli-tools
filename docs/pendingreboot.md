# pendingreboot

Reports whether a reboot is pending and why. A pending reboot is a common reason Intune app installs, Windows updates and feature installs stall or fail.

| Platform | Usage |
|---|---|
| Linux | `pendingreboot.sh` |
| PowerShell | `pendingreboot.ps1` |
| cmd | `pendingreboot` |

## Checks
**Windows**
- Component Based Servicing `RebootPending` key (updates, optional features).
- Windows Update `RebootRequired` key.
- `PendingFileRenameOperations` in Session Manager. Installers and antivirus often leave entries here, so this one alone may be benign.
- A computer rename waiting for a reboot.

**Linux**
- `/var/run/reboot-required` (Debian/Ubuntu), including the packages that requested it.
- `needs-restarting -r` (RHEL/Fedora, if installed).
- A newer kernel in `/boot` than the one running.

## Exit codes
`0` no reboot pending; `2` reboot pending. Handy in scripts: `pendingreboot || echo "reboot first"`.
