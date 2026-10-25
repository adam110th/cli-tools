# bigfiles

Lists the largest files under a directory, searching all subfolders.

| Platform | Usage |
|---|---|
| Linux | `bigfiles.sh [PATH] [TOP]` |
| PowerShell | `bigfiles.ps1 [PATH] [TOP]` |
| cmd | `bigfiles [PATH] [TOP]` (wrapper) |

Defaults: current directory, top 20.

## Notes
- PowerShell shows size, last-modified date (dd/mm/yyyy) and full path. Linux shows size and path.
- Linux stays on one filesystem (`find -xdev`).
- Unreadable folders are skipped silently; run elevated for a complete picture.
