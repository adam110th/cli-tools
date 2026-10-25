# dupfiles

Finds duplicate files: files are grouped by size first, and only same-size files are hashed (SHA256), so large trees are scanned quickly. Reports only; deletes nothing.

| Platform | Usage |
|---|---|
| Linux | `dupfiles.sh [PATH] [MIN_SIZE_KB]` |
| PowerShell | `dupfiles.ps1 [PATH] [MIN_SIZE_KB] [-IncludeCloudOnly] [-CsvPath FILE]` |
| cmd | `dupfiles [PATH] [MIN_SIZE_KB] [-IncludeCloudOnly] [-CsvPath FILE]` (wrapper) |

Defaults: current directory, ignore files under 1 KB. Empty files are always ignored.

## Output
Groups sorted by space wasted, largest first. Each group shows the copy count, file size, wasted space and the start of the hash, then each path (PowerShell also shows the modified date, oldest first). A summary gives the total reclaimable space.

## Cloud folders
On Windows, online-only files in OneDrive, Google Drive or Dropbox are **skipped by default**, because hashing a file reads all of it and would download everything. The skipped count is reported. Use `-IncludeCloudOnly` to include them, preferably on a small folder.

## Exit codes
`0` no duplicates; `2` duplicates found; `1` invalid arguments.

## Notes
- `-CsvPath` saves every duplicate with its group number, which is the easiest way to review a large result in Excel.
- Linux stays on one filesystem and does not support file names containing the 0x1F control character.
