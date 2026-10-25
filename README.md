# cli-tools

A small set of everyday command-line utilities with matching **Linux (bash)**, **PowerShell** and **Windows Command Prompt (cmd)** versions. Each tool has the same name, the same purpose and, as far as each shell allows, the same arguments on every platform.

## Tools

| Tool | What it does | Linux | PowerShell | cmd |
|---|---|---|---|---|
| [pathlist](docs/pathlist.md) | Print each PATH entry on its own line; flag missing and duplicate entries | native | native | native |
| [whichall](docs/whichall.md) | Every match for a command on PATH, in search order | native | native | native (`where`) |
| [sysinfo](docs/sysinfo.md) | Host, OS, model, serial, uptime, CPU, memory, disks, Entra/domain join | native | native | native |
| [netinfo](docs/netinfo.md) | Adapters, IPs, gateway, DNS; public IP on request | native | native | native |
| [portcheck](docs/portcheck.md) | Test whether a remote TCP port is reachable | native | native | wrapper |
| [portowner](docs/portowner.md) | Which process is using a local port | native | native | native |
| [dirsize](docs/dirsize.md) | Largest immediate subfolders of a directory | native | native | wrapper |
| [bigfiles](docs/bigfiles.md) | Largest files under a directory | native | native | wrapper |
| [hashfile](docs/hashfile.md) | SHA256 (or SHA1/MD5/SHA512) of files | native | native | native (`certutil`) |
| [empty-directories](docs/empty-directories.md) | Empty (and remove) a list of directories read from a txt/csv file | native | native | wrapper |
| [syncsafe](docs/syncsafe.md) | Find long paths, invalid characters, trailing spaces/dots and reserved names that break Windows or cloud sync | native | native | wrapper |
| [pendingreboot](docs/pendingreboot.md) | Is a reboot pending, and why | native | native | native |
| [mdmstatus](docs/mdmstatus.md) | Intune/MDM enrolment, last sync, Intune Management Extension; optional sync | Intune app check only | native | wrapper |
| [refreshenv](docs/refreshenv.md) | Reload PATH and other variables into the current window after an install | native (source it) | native (dot-source it) | native |
| [certcheck](docs/certcheck.md) | TLS certificate details, expiry and trust for a host | native | native | wrapper |
| [dnscheck](docs/dnscheck.md) | Compare DNS answers from the system resolver and other servers | native | native | native (`nslookup`) |
| [dupfiles](docs/dupfiles.md) | Find duplicate files by size then SHA256; skips online-only cloud files | native | native | wrapper |
| [eventerrors](docs/eventerrors.md) | Recent critical and error events, summarised by source | native (`journalctl`) | native | wrapper |

**Wrapper** means the `.cmd` file runs the matching `.ps1` with the same arguments, because a native batch version would be unreliable. Wrappers look for the `.ps1` in the same folder first, then in `..\powershell\`, so they work in either layout below.

## Layout

```
cli-tools/
  linux/        *.sh   (bash 4+, GNU coreutils/findutils)
  powershell/   *.ps1  (Windows PowerShell 5.1 or PowerShell 7+)
  cmd/          *.cmd  (Windows 10 1803+ / Windows 11)
  docs/         one page per tool
  install.ps1   Windows installer      install.cmd  launcher for it
  install.sh    Linux installer
  .gitattributes
```

`.gitattributes` forces CRLF for `.cmd` and `.ps1` and LF for `.sh`. Keep it: batch files with LF endings can break `goto`/`call` labels, and bash scripts with CRLF fail with `$'\r': command not found`.

## Requirements

- **Linux:** bash 4+, coreutils, findutils. `netinfo`/`portowner` use `ip`/`ss` (iproute2) and fall back to `ifconfig`/`lsof` or `/proc`. `netinfo --public` needs `curl`, `certcheck` needs `openssl`, `dnscheck` works best with `dig` (dnsutils / bind-utils).
- **PowerShell:** Windows PowerShell 5.1 or PowerShell 7+. `sysinfo`, `netinfo`, `portowner`, `pendingreboot`, `mdmstatus`, `refreshenv`, `dnscheck`, `eventerrors` and `syncsafe` are Windows-only. `whichall`, `hashfile`, `portcheck`, `dirsize`, `bigfiles`, `certcheck` and `dupfiles` also run under PowerShell 7 on Linux/macOS.
- **cmd:** Windows 10 1803 or later (`curl.exe` is built in from that release). Wrappers need `powershell.exe`.

## Installing

Each platform has an installer that copies the tools to the recommended location and adds that location to PATH if it is not there already. Run it from the extracted repo folder; it works with the repo layout or a flat folder. Running it again upgrades in place (tools removed from the source are removed from the install).

### Install locations

| Platform | Scope | Tools | Docs | Why this location |
|---|---|---|---|---|
| Windows | User (default) | `%LOCALAPPDATA%\Programs\cli-tools` | same folder | Windows' per-user program folder (FOLDERID_UserProgramFiles); no admin needed |
| Windows | Machine | `%ProgramFiles%\cli-tools` | same folder | Only admins can write here, so it is safe on the machine PATH. Avoid `C:\ProgramData` for this: standard users can write there, which would let anyone plant a command on every user's PATH |
| Linux | User (default) | `~/.local/bin` | `~/.local/share/cli-tools` | Per-user command folder in the systemd file-hierarchy / XDG layout |
| Linux | System | `/usr/local/bin` | `/usr/local/share/cli-tools` | Locally installed software under the Filesystem Hierarchy Standard |

### Windows

From cmd (also refreshes PATH in that cmd window when it finishes):
```
install.cmd                     :: current user
install.cmd -Scope Machine      :: all users (elevated prompt)
install.cmd -Uninstall          :: remove (add -Scope Machine for a machine install)
```
From PowerShell:
```powershell
.\install.ps1                   # current user
.\install.ps1 -Scope Machine    # all users (elevated prompt)
.\install.ps1 -Uninstall
```
If execution policy blocks `install.ps1`, use `install.cmd`, which runs it with `-ExecutionPolicy Bypass` for that one process.

What the installer does:
1. Picks the scope. `-Scope Auto` (the default) uses **Machine** when running as SYSTEM, as Intune does, and **User** otherwise. Machine scope needs admin rights.
2. Copies every `.ps1` and `.cmd` tool into one flat folder, plus `README.md`, `docs\` and `VERSION.txt`, and unblocks the files (removes the downloaded-from-internet mark).
3. Adds the folder to the **User** PATH (or **Machine** PATH for machine scope) if missing. Existing PATH entries such as `%SystemRoot%` are preserved unexpanded.
4. Updates PATH in the current session and notifies Windows, so new windows see the change straight away. Windows that were already open need to be reopened, or run `refreshenv` (cmd) / `. refreshenv` (PowerShell).

Optional: to make plain `refreshenv` work in PowerShell, add this line to your profile (`notepad $PROFILE`):
```powershell
function refreshenv { . (Get-Command refreshenv.ps1).Source }
```

### Intune (Win32 app)

| Setting | Value |
|---|---|
| Install command | `install.cmd -Scope Machine` |
| Uninstall command | `install.cmd -Uninstall -Scope Machine` |
| Install behaviour | System |
| Detection rule | File exists: `%ProgramFiles%\cli-tools\VERSION.txt` (or compare its contents to the version for upgrades) |
| Return codes | `0` success, `1` failure |

If an AllSigned execution policy is enforced, sign the `.ps1` files before packaging; `-ExecutionPolicy Bypass` does not override a Group Policy or Intune setting.

### Linux

```bash
./install.sh                    # current user
sudo ./install.sh --system      # all users
./install.sh --uninstall        # remove (add --system for a system install)
```
What the installer does:
1. Picks the scope: `--system` when run as root, otherwise `--user`.
2. Installs each tool **without** the `.sh` extension (`pathlist`, `portcheck`, ...) so the names match Windows. It will not overwrite a command of the same name that it did not install; it warns and skips it.
3. Installs `refreshenv.sh` (it has to be sourced) and defines a `refreshenv` shell function so you can type `refreshenv`.
4. Adds the bin folder to PATH if needed, in a marked block (`# >>> cli-tools >>>`) in `~/.profile`, `~/.bashrc` and `~/.zshrc` if present. System installs write `/etc/profile.d/cli-tools.sh` instead. Running the installer again replaces the block rather than adding another.
5. Records what it installed in `installed-files.txt` so uninstall and upgrades remove exactly those files.

Open a new terminal afterwards, or `source ~/.bashrc`.

### Manual install
Copy `powershell\*.ps1` and `cmd\*.cmd` into one folder on PATH (Windows), or copy `linux/*.sh` into a folder on PATH and make them executable (Linux).

## Conventions

- **Exit codes:** `0` success; `1` bad arguments, nothing to do, or cancelled; `2` the check ran but the answer was negative (port closed, nothing on the port, items skipped or left behind).
- **Validation:** host names, ports, counts and algorithm names are validated before use. Nothing user-supplied is passed through `eval` or string-built shell commands.
- **External calls:** `netinfo` contacts `https://api.ipify.org` only when asked (`--public` / `-Public` / `/public`). `dnscheck` queries 1.1.1.1 and 8.8.8.8 by default, which sends the looked-up name to Cloudflare and Google; pass your own servers for client or internal names. `certcheck` connects only to the host you name.
- **Destructive actions:** only `empty-directories` deletes anything (`mdmstatus -Sync` triggers a sync but changes no settings; `dupfiles` and `syncsafe` only report). It validates every entry, lists what it will touch, and requires typing `YES`. It has a dry-run mode.
- **Dates** in output use dd/mm/yyyy.

## Testing status

| | Linux | PowerShell | cmd |
|---|---|---|---|
| Syntax | shellcheck clean | all files parse (PowerShell 7) | reviewed only |
| Run | All tools run on Ubuntu 24.04. Not exercised: `portowner` via `ss`, and `dnscheck` against a real `dig` (comparison logic tested with a stub). `certcheck` was run through a TLS-inspecting proxy, so only that path was seen. | Run under PowerShell 7 on Linux: `whichall`, `hashfile`, `portcheck`, `dirsize`, `bigfiles`, `certcheck`, `dupfiles`, and `syncsafe` (logic only). Windows-only tools not run. | not run |

`install.sh` was tested on Ubuntu (user and system scope, re-run, clash protection, uninstall). `install.ps1` parses but has not been run on Windows.

Before deploying, run `install.cmd` (user and machine scope, then `-Uninstall`) and each Windows tool once on a test device, including the cmd wrappers from both a flat folder and the repo layout. Priorities: `refreshenv.cmd` (registry parsing), `pendingreboot.cmd`, `mdmstatus.ps1` (with and without elevation) and `dnscheck.ps1`.

## License

GPL-3.0. See [LICENSE](LICENSE). Changes are listed in [CHANGELOG.md](CHANGELOG.md).
