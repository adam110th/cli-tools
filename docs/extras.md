# Third-party tools (extras)

These are **other people's projects, not part of cli-tools**. They are recommended alongside it, and the optional extras installers set them up with your package manager. cli-tools does not update or support them: update them with your package manager, and see each tool's own `--help`, man page or website.

| Platform | Install |
|---|---|
| Linux | `./install.sh --extras` (with the cli-tools install) or `./install-extras.sh [TOOL...]` on its own |
| Windows | `install.cmd -Extras` / `.\install.ps1 -Extras`, or `.\install-extras.ps1 [TOOL...]` on its own |

Give tool names to install only those (`./install-extras.sh eza bat fzf`). `--list` / `-List` prints the names. Tools that are already installed are skipped, so running it again is safe.

## Tools

| Tool | What it does | Linux | Windows (Chocolatey / winget) |
|---|---|---|---|
| [thefuck](https://github.com/nvbn/thefuck) | Fix the previous command: type `fuck` after a typo | package (pipx fallback) | not available |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd`: `z NAME` jumps to a frequently used folder, `zi` picks with fzf | package | `zoxide` / `ajeetdsouza.zoxide` |
| [tldr](https://github.com/tealdeer-rs/tealdeer) | Short, example-first help pages: `tldr tar` (tealdeer client) | `tealdeer` or `tldr` | `tealdeer` / `dbrgn.tealdeer` |
| [scc](https://github.com/boyter/scc) | Count lines of code, comments and complexity per language | package or GitHub release | `scc` / `BenBoyter.scc` |
| [eza](https://github.com/eza-community/eza) | Modern `ls`; aliased to `eza -a -l -h -M --icons=always` | package; apt repo `deb.gierens.de` if the distro has none | `eza` / `eza-community.eza` |
| [duf](https://github.com/muesli/duf) | Disk usage and free space per filesystem, as a table | package | `duf` / `muesli.duf` |
| [bat](https://github.com/sharkdp/bat) | `cat` with syntax highlighting and paging | package (`batcat` on Debian/Ubuntu, aliased to `bat`) | `bat` / `sharkdp.bat` |
| [exiftool](https://exiftool.org) | Read and write photo and document metadata | `libimage-exiftool-perl` (apt), `perl-Image-ExifTool` (dnf) | `exiftool` / `OliverBetz.ExifTool` |
| [fdupes](https://github.com/adrianlopezroche/fdupes) | Find, and optionally delete, duplicate files | package | not available (use `dupfiles`) |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder for any list | package | `fzf` / `junegunn.fzf` |
| [jq](https://jqlang.org) | Query and reshape JSON | package | `jq` / `jqlang.jq` |
| [procs](https://github.com/dalance/procs) | Modern `ps`: coloured, searchable process list | package or GitHub release | `procs` / `dalance.procs` |
| [browsh](https://www.brow.sh) | Text-mode web browser; needs Firefox | GitHub release | winget `browsh.browsh` |
| [ddgr](https://github.com/jarun/ddgr) | DuckDuckGo search from the terminal | package | not available |
| [lazygit](https://github.com/jesseduffield/lazygit) | Terminal UI for git | package or GitHub release | `lazygit` / `JesseDuffield.lazygit` |
| [asciinema](https://asciinema.org) | Record and replay terminal sessions | package or GitHub release | not available |
| [neofetch](https://github.com/dylanaraps/neofetch) | System summary beside the OS logo. neofetch is no longer maintained, so fastfetch is used where neofetch is not packaged | `neofetch`, else `fastfetch` | [fastfetch](https://github.com/fastfetch-cli/fastfetch): `fastfetch` / `Fastfetch-cli.Fastfetch` |
| [tre](https://github.com/dduan/tre) | `tree` that respects `.gitignore` | GitHub release (`tre-command` on brew) | GitHub release, copied into the cli-tools folder |
| [git](https://git-scm.com) | Version control | package | `git` / `Git.Git` |
| [gh](https://cli.github.com) | GitHub CLI | package; apt/dnf/zypper repo `cli.github.com` | `gh` / `GitHub.cli` |
| [claude](https://github.com/anthropics/claude-code) | Claude Code, Anthropic's coding agent for the terminal | Anthropic's native installer (to `~/.local/bin`) | `claude-code` / `Anthropic.ClaudeCode` |

## Linux: what `install-extras.sh` does
1. Finds the package manager: apt, dnf (or yum), pacman, zypper, apk or Homebrew, in that order. Package installs need root, so it uses `sudo` when not run as root.
2. **apt:** installs `ca-certificates curl gpg unzip`, then adds the GitHub CLI repository (keyring `/etc/apt/keyrings/githubcli-archive-keyring.gpg`, source `/etc/apt/sources.list.d/github-cli.list`). If the distro has no `eza` package (Ubuntu before 24.04, Debian before 13), it also adds the eza repository (`/etc/apt/keyrings/gierens.gpg`, `/etc/apt/sources.list.d/gierens.list`). **dnf/zypper:** adds `cli.github.com/packages/rpm/gh-cli.repo` only if `gh` is not already available.
3. Installs each tool from the package manager. Where a column lists two packages (`tealdeer,tldr`, `neofetch,fastfetch`) the first available one is used.
4. For tools the distro does not package, downloads the latest matching x86_64 or arm64 build from the project's GitHub releases into `/usr/local/bin`. `claude` uses Anthropic's installer (`curl -fsSL https://claude.ai/install.sh | bash`), run as the invoking user.
5. Adds a marked block (`# >>> cli-tools extras >>>`) to `~/.bashrc` and `~/.zshrc` (if present). When run with `sudo`, it writes to the invoking user's files. The block:
   - aliases `eza` to `eza -a -l -h -M --icons=always`;
   - aliases `bat` to `batcat` where only `batcat` exists (Debian/Ubuntu);
   - loads the `zoxide` (`z`, `zi`) and `thefuck` (`fuck`) shell hooks.

   Each line checks the tool exists first, so the block is harmless if one is missing. Running again replaces the block.
6. Prints a summary. Exit code `0` when everything is installed, `2` if any tool failed.

## Windows: what `install-extras.ps1` does
1. Installs **Chocolatey** with its documented install command if it is missing. This needs an elevated prompt.
2. Installs each tool with Chocolatey (`choco install ID -y`), falling back to winget (`winget install --id ID --exact`). Without admin rights Chocolatey cannot install, so winget is used for everything. Running as SYSTEM (Intune) uses Chocolatey only, because winget is not available to SYSTEM.
3. `tre` has neither package, so `tre.exe` is taken from its GitHub release and copied into the cli-tools folder, which is already on PATH. Install cli-tools first.
4. Adds a marked block to the PowerShell profile (`Documents\WindowsPowerShell\profile.ps1` and `Documents\PowerShell\profile.ps1`) that makes `eza` run as `eza -a -l -h -M --icons=always` and loads the `zoxide` hook (`z`, `zi`). Skipped when running as SYSTEM. If the execution policy is `Restricted` or `AllSigned`, profiles do not load; the installer says so (fix: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`).
5. Prints a summary. Exit code `0` when everything is installed, `2` if any tool failed.

NuGet is a library package manager, not an application installer, so it is not used.

## Uninstall
`install.sh --uninstall` and `install.ps1 -Uninstall` remove the alias and profile blocks. They leave the third-party tools, repositories and Chocolatey installed: remove those with your package manager (`apt remove eza`, `choco uninstall eza`, `winget uninstall eza-community.eza`).

## Notes
- `eza --icons=always` needs a [Nerd Font](https://www.nerdfonts.com) in your terminal, otherwise icons show as boxes.
- `thefuck` 3.32 can fail on Python 3.12 and later with `No module named 'imp'` unless your distribution has patched it. The shell hook hides that error, so if `fuck` does nothing, that is the likely cause.
- `tldr` needs its page cache once: `tldr --update`.
- `browsh` needs Firefox (`sudo apt install firefox`, `choco install firefox`).
- The GitHub release downloads use GitHub's API without a token (60 requests an hour per IP), which is plenty for one run.
