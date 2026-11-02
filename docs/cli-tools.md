# cli-tools

Prints a reference for every tool in the set: its arguments and options, its exit codes and what it does. Use it when you can't remember a tool's name or options.

| Platform | Usage |
|---|---|
| Linux | `cli-tools`, `cli-tools -h`, `cli-tools --help`, or `man cli-tools` |
| PowerShell | `cli-tools`, `cli-tools -h`, `cli-tools --help` |
| cmd | `cli-tools`, `cli-tools -h`, `cli-tools --help`, `cli-tools /?` (wrapper) |

Plain `cli-tools` with no arguments shows the same help. Any other argument prints `Unknown option`, then the help, and exits `1`.

## Notes
- The Windows help shows PowerShell syntax, with a `cmd:` line where the native Command Prompt version takes different arguments (`pathlist`, `netinfo`, `hashfile`, `dnscheck`). The Linux help and man page show the bash syntax.
- `man cli-tools` works after running `install.sh`, which installs the page to `~/.local/share/man/man1` (user) or `/usr/local/share/man/man1` (system). `man` finds the user location because `~/.local/bin` is on PATH.
- In PowerShell, `cli-tools -?` is intercepted by PowerShell itself and shows the script's short built-in help instead. Use `-h` or `--help`.
- When adding or changing a tool, update all three help sources: `powershell/cli-tools.ps1`, `linux/cli-tools.sh` and `man/cli-tools.1`.
