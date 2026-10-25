# whichall

Lists every executable on PATH that matches a name, in search order. The first result is the one that runs when you type the name. Useful when two versions of a tool are installed (Python, Git, Node).

| Platform | Usage |
|---|---|
| Linux | `whichall.sh NAME [NAME...]` |
| PowerShell | `whichall.ps1 NAME [NAME...]` |
| cmd | `whichall NAME [NAME...]` |

## Behaviour
- Linux checks each PATH folder for an executable file with that exact name.
- PowerShell uses `Get-Command -All -CommandType Application`, so it honours PATHEXT (`python` finds `python.exe`). Aliases and functions are not listed.
- cmd uses the built-in `where.exe`, which also checks the current folder first and accepts wildcards (`whichall py*`).

## Exit codes
`0` all names found; `1` at least one name not found (a warning names it).
