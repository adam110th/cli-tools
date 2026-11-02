# Changelog

## v1.2.0 - 02/11/2026

### Added
- **Third-party tools (extras),** kept separate from cli-tools' own tools: `install-extras.sh` (Linux) and `install-extras.ps1` (Windows) install thefuck, zoxide, tldr, scc, eza, duf, bat, exiftool, fdupes, fzf, jq, procs, browsh, ddgr, lazygit, asciinema, neofetch (fastfetch on Windows), tre, git, gh and claude. Run them through `install.sh --extras` / `install.cmd -Extras`, or on their own. See [docs/extras.md](docs/extras.md).
  - Linux: apt, dnf/yum, pacman, zypper, apk or brew; adds the GitHub CLI apt repository and keyring, and the eza repository when the distro has no eza package; GitHub-release fallback for unpackaged tools.
  - Windows: installs Chocolatey if missing, installs with Chocolatey and falls back to winget.
  - Shell setup: `eza` runs as `eza -a -l -h -M --icons=always`, plus the zoxide hook (and on Linux the thefuck hook and `bat` for `batcat`). Removed by uninstall.
- `cli-tools --help`, `man cli-tools` and the README list the third-party tools in their own section.
- **Colour output** in every tool on all three platforms: status words, headings and problems are coloured on a terminal, piped output stays plain, and `NO_COLOR` turns it off.

### Fixed
- `sysinfo` showed firmware placeholders ("System Product Name", "System Serial Number", "To be filled by O.E.M.") on custom-built PCs. It now ignores them and shows the motherboard's maker, model and serial, marked `(motherboard)`.

### Changed
- `mdmstatus` (Windows) shows a short name after the last-sync result code, for example `(result 0x82AC0204 - DM session aborted: device roaming)`.
- `sysinfo` (PowerShell) colours disks yellow at 80% used and red at 90%. In `sysinfo.cmd` the serial line is now aligned with the other lines.
- Installers report version 1.2.0.

## v1.1.1 - 26/10/2026

### Fixed
- **`empty-directories` could delete files outside the listed folders through junctions and symbolic links.** On Windows, `robocopy /MIR` purges through a junction inside the folder (with or without `/XJ`), and the PowerShell fallback and item count followed links too. Links inside a listed folder are now removed as links before robocopy runs (robocopy is skipped if one cannot be removed), and the fallback and count never follow them. On both platforms, an entry whose path goes through a junction or symbolic link (below the base path for relative entries) is now Blocked.
- `install.ps1`: machine scope installs to the 64-bit Program Files even when run from 32-bit PowerShell (as the Intune Management Extension does).

### Changed
- Installers report version 1.1.1 (`VERSION.txt`), so deployments of 1.1.0 (e.g. Intune) upgrade.

## v1.1.0 - 26/10/2026

### Added
- **`cli-tools`** help command on every platform: lists each tool with its arguments, options, exit codes and a description. `cli-tools`, `cli-tools -h` and `cli-tools --help` all show it (`/?` too in cmd).
- **`man cli-tools`** (Linux): `man/cli-tools.1`, installed by `install.sh` to `~/.local/share/man/man1` or `/usr/local/share/man/man1` and removed on uninstall.

### Changed
- Installers report version 1.1.0 (`VERSION.txt`).

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
