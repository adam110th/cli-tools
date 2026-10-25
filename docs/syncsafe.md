# syncsafe

Scans a folder for files and folders that break Windows, Explorer or cloud sync (Google Drive, OneDrive, Dropbox), before they cause errors like "The directory is not empty" or "The filename, directory name, or volume label syntax is incorrect". Reports only; changes nothing.

| Platform | Usage |
|---|---|
| Linux | `syncsafe.sh [PATH] [--max N] [--win-root PREFIX]` |
| PowerShell | `syncsafe.ps1 [PATH] [-MaxPath N] [-CsvPath FILE]` |
| cmd | `syncsafe [PATH] [-MaxPath N] [-CsvPath FILE]` (wrapper) |

## What it flags

| Issue | Meaning |
|---|---|
| `LongPath` | Full path is 260 characters or more (change with `-MaxPath` / `--max`). Explorer, `rmdir` and many apps fail on these. |
| `NameTooLong` | A single name over 255 characters. |
| `InvalidChar` | Contains `< > : " \| ? * \ /` or control characters. Windows cannot address these files at all; rename or delete them in the cloud service's web interface. |
| `TrailingSpaceOrDot` | Name ends in a space or `.`; Windows strips these silently, so the item cannot be opened or deleted normally. |
| `LeadingSpace` | Name starts with a space; legal but causes sorting and scripting surprises. |
| `ReservedName` | `CON`, `PRN`, `AUX`, `NUL`, `COM1`-`COM9`, `LPT1`-`LPT9`, with or without an extension (`nul.txt`). |

## Linux --win-root
Scanning a Windows share or synced folder from Linux? Pass the Windows path it will be used under so lengths are measured the way Windows will see them:
```
syncsafe.sh /mnt/gdrive/shared --win-root 'X:\GoogleDrive\Shared'
```

## Exit codes
`0` nothing found; `2` problems found; `1` invalid arguments.

## Notes
- The PowerShell version reads through the `\\?\` long-path prefix, so it can see items that Explorer cannot.
- Pair it with [empty-directories](empty-directories.md): run `syncsafe` to find the problems, fix names that can be fixed, then clear what is left.
