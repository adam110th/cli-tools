# Changelog

## v1.0.1 - 25/10/2026

### Fixed
- `install.ps1` machine scope now always installs to the 64-bit `Program Files` (via `%ProgramW6432%`). Intune can run Win32 app installs in 32-bit PowerShell, where `%ProgramFiles%` is `Program Files (x86)`, so the tools landed in the wrong folder and the documented detection rule failed.

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
