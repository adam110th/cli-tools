# pathlist

Prints each PATH entry on its own numbered line and flags problems.

| Platform | Usage |
|---|---|
| Linux | `pathlist.sh` |
| PowerShell | `pathlist.ps1 [-Scope Process\|User\|Machine]` |
| cmd | `pathlist` |

## Flags in the output
- `[missing]` - the folder does not exist.
- `[duplicate]` - the same folder appears earlier in PATH (Linux and PowerShell only).
- An empty entry (`::` on Linux, `;;` on Windows) is shown explicitly. On Linux an empty entry means the current directory, which is a security risk.

## PowerShell -Scope
- `Process` (default) - the PATH this session actually uses.
- `User` / `Machine` - the value stored in the registry. Variables such as `%SystemRoot%` are expanded before checking whether the folder exists. Use this to see what a new session will get after an installer changes PATH.

## Examples
```
pathlist.ps1 -Scope Machine
```
```
  1  C:\Windows\system32
  2  C:\Program Files\OldTool\bin [missing]
```

## Notes
- The cmd version does not detect duplicates.
- Equivalent one-liners: `$env:PATH -split ';'` (PowerShell), `for %p in ("%PATH:;=" "%") do @echo %~p` (cmd).
