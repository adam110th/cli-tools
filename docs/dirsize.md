# dirsize

Lists the largest immediate subfolders of a directory, biggest first. Use it to find what is filling a disk.

| Platform | Usage |
|---|---|
| Linux | `dirsize.sh [PATH] [TOP]` |
| PowerShell | `dirsize.ps1 [PATH] [TOP]` |
| cmd | `dirsize [PATH] [TOP]` (wrapper) |

Defaults: current directory, top 15.

## Notes
- Linux uses `du -x`, so it stays on one filesystem, and the first line is the total for the directory itself.
- PowerShell also shows the file count per folder, and includes hidden and system files. Folders you cannot read are skipped silently, so totals can be lower than the real size when run without admin rights.
- Large trees (a whole drive, a synced cloud folder) can take minutes. On Google Drive or OneDrive "online-only" folders the reported size is the cloud size; nothing is downloaded.
