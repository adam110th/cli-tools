# Changelog

## v1.1.0 - 26/10/2026

### Added
- **`cli-tools`** help command on every platform: lists each tool with its arguments, options, exit codes and a description. `cli-tools`, `cli-tools -h` and `cli-tools --help` all show it (`/?` too in cmd).
- **`man cli-tools`** (Linux): `man/cli-tools.1`, installed by `install.sh` to `~/.local/share/man/man1` or `/usr/local/share/man/man1` and removed on uninstall.

### Changed
- Installers report version 1.1.0 (`VERSION.txt`).

### Fixed
- **`empty-directories` could delete files outside the listed folders through junctions and symbolic links.** On Windows, `robocopy /MIR` purges through a junction inside the folder (with or without `/XJ`), and the PowerShell fallback and item count followed links too. Links inside a listed folder are now removed as links before robocopy runs (robocopy is skipped if one cannot be removed), and the fallback and count never follow them. On both platforms, an entry whose path goes through a junction or symbolic link (below the base path for relative entries) is now Blocked.
- `install.ps1`: machine scope installs to the 64-bit Program Files even when run from 32-bit PowerShell (as the Intune Management Extension does).

## v1.0.0 - 25/10/2026

Initial release.

### Tools (Linux bash, PowerShell, Windows cmd)
- **Paths and commands:** `pathlist`, `whichall`, `refreshenv`
- **System:** `sysinfo`, `pendingreboot`, `mdmstatus`, `eventerrors`
- **Network:** `netinfo`, `portcheck`, `portowner`, `certcheck`, `dnscheck`
- **Files and disk:** `dirsize`, `bigfiles`, `hashfile`, `dupfiles`, `syncsafe`, `empty-directories`

### Installers
- `install.ps1` / `install.cmd` (Windows): user scope to `%LOCALAPPDATA%\Programs\cli-tools`, machine scope to `%ProgramFiles%\cli-tools`, adds the folder to PATH, uninstall support, `VERSION.txt` for Intune detection.
- `install.sh` (Linux): user scope to `~/.local/bin`, system scope to `/usr/local/bin`, adds PATH and a `refreshenv` function, uninstall support.

### Known limitations
- Windows `.cmd` files and the Windows-only PowerShell tools have been syntax-checked and reviewed but not yet run on Windows. See "Testing status" in the README.
