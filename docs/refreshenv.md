# refreshenv

Reloads environment variables, especially PATH, into the window you are already using, so a tool that was just installed (by Intune, winget or an installer) works without closing and reopening the terminal.

| Platform | Usage |
|---|---|
| PowerShell | `. refreshenv.ps1` (note the leading dot and space) |
| cmd | `refreshenv` |
| Linux | `source refreshenv.sh` |

## Why the special syntax
A script normally runs in its own scope or child process, and any changes it makes disappear when it ends. To change *your* session it has to run inside it:
- **PowerShell** must dot-source it. Run without the dot, it prints a warning and changes nothing.
- **cmd** batch files already run inside the calling window, so `refreshenv` works directly. Running `refreshenv.cmd` from PowerShell does nothing useful; use the `.ps1` there.
- **bash** must `source` it. Run directly, it prints a reminder and exits.

## What it does
- **Windows:** re-reads Machine then User variables from the registry (User wins), expanding values such as `%SystemRoot%`. PATH is rebuilt as Machine PATH followed by User PATH, with duplicates removed (PowerShell version). `PSModulePath` and `USERNAME` are left alone. The PowerShell version lists PATH entries added and removed.
- **Linux:** takes PATH from a fresh login shell (`bash -l`), which picks up `/etc/profile.d` and `~/.profile` changes, then clears bash's command cache. Lists added entries.

## Caveat
PATH entries you added to the current session by hand (for example by activating a Python virtual environment) are dropped, because PATH is rebuilt from the stored settings.
