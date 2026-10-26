# empty-directories

Empties, and by default removes, every directory listed in a `.txt` or `.csv` file. Built for clearing out folders that Explorer or `rmdir` refuse to delete ("The directory is not empty"), usually because the paths exceed the Windows 260-character limit.

| Platform | Usage |
|---|---|
| Linux | `empty-directories.sh [options] INPUT_FILE` |
| PowerShell | `empty-directories.ps1 INPUT_FILE [-BasePath PATH] [options]` |
| cmd | `empty-directories INPUT_FILE [same options as PowerShell]` (wrapper) |

## Input file
- One path per line, or a comma-separated list. Quote any path that contains a comma.
- Optional base path line anywhere in the file: `base: X:\GoogleDrive\Shared`
- Lines starting with `#` are comments. A CSV header of `Path`, `Directory` or `Folder` is ignored.
- Windows error text pasted after a path (" - The directory is not empty.") is stripped automatically, so you can paste an error list straight in.
- Duplicate entries are removed.

Example:
```
# folders to clear
base: X:\GoogleDrive\Shared
0. Projects\Client A\2019 Job\3. Valuer Files\5. Research
0. Projects\Client B\2020 Job\2. Client Files\Plans
```

## Base path
Precedence: the base path option, then the `base:` line in the file, then the current directory. The current directory is used only after you answer `Y` to a prompt; any other answer cancels. Absolute entries (`X:\...`, `\\server\share\...`, `/...`) ignore the base path.

## Options

| PowerShell | Linux | Effect |
|---|---|---|
| `-BasePath PATH` | `-b`, `--base PATH` | Base path for relative entries |
| `-Format Auto\|Lines\|Comma` | `-f`, `--format auto\|lines\|comma` | Auto: several lines = one path per line; one line = comma-separated |
| `-KeepFolders` | `-k`, `--keep-folders` | Empty the folders but keep them |
| `-WhatIf` | `-n`, `--dry-run` | Validate and report only |
| `-Force` | `-y`, `--force` | Skip the YES confirmation |
| `-LogPath PATH` | `-l`, `--log PATH` | Results CSV (default: next to the input file, timestamped) |

## Safety checks
Every entry is checked before anything is deleted. These are reported as warnings and skipped:
- **NotFound** - the directory does not exist.
- **NotADirectory** - the path is a file.
- **Invalid** (Windows) - the name contains characters Windows cannot use, such as `"`. Delete these in the cloud service's web interface.
- **Blocked** - a drive or share root, the base path itself, a relative entry that escapes the base path with `..`, or a path that is or goes through a junction or symbolic link (below the base path, for relative entries). List the real folder instead.

The tool then lists each directory with its item count and asks you to type `YES`.

## How it deletes
- Windows: junctions and directory symbolic links inside the folder are removed first (the link only, never what it points to), because `robocopy /MIR` purges *through* them even with `/XJ`. Then `robocopy /MIR` from an empty folder, which handles paths over 260 characters, then a PowerShell fallback for read-only leftovers that also never follows links.
- Linux: `find -delete`, which removes symbolic links without following them.

## Exit codes
`0` all done; `1` cancelled, bad input or nothing to do; `2` some entries skipped, or items were left behind (usually a sync lock or open file).

## Cloud-synced folders
Deleting inside a Google Drive, OneDrive or Dropbox folder syncs the deletion to the cloud. Files normally go to the service's bin or trash, where they can be recovered for a limited time, and anyone the folders are shared with loses access too. If items are left behind, pause sync, run again, then resume.
