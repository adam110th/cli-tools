# portowner

Shows which process is listening on, or connected through, a local port. Use it when an app fails with "address already in use", or to see what is answering on a port.

| Platform | Usage |
|---|---|
| Linux | `portowner.sh PORT` |
| PowerShell | `portowner.ps1 PORT` |
| cmd | `portowner PORT` |

## Output
Protocol, state, local and remote address, PID and process name. PowerShell also shows the executable path.

## Exit codes
`0` something found; `2` nothing is using the port; `1` invalid port.

## Notes
- **Elevation:** without admin/root rights, process names and paths for other users' and system processes may be hidden. Run elevated (`sudo` on Linux, an elevated prompt on Windows).
- Linux needs `ss` (iproute2) or `lsof`.
- cmd parses `netstat -ano` and looks up names with `tasklist`.
