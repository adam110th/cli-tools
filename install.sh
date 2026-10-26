#!/usr/bin/env bash
# install.sh - install (or uninstall) cli-tools on Linux and make sure the bin folder is on PATH.
#
# Locations (systemd file-hierarchy(7) / XDG for user installs, FHS /usr/local for system installs):
#   user    commands in ~/.local/bin           docs in ~/.local/share/cli-tools
#   system  commands in /usr/local/bin         docs in /usr/local/share/cli-tools
# The cli-tools(1) man page goes in ~/.local/share/man/man1 or /usr/local/share/man/man1, where man finds it.
# Commands are installed without the .sh extension (pathlist, portcheck, ...), so names match Windows.
# refreshenv must be sourced, so it is installed as refreshenv.sh plus a "refreshenv" shell function.
#
# Usage: ./install.sh [--user|--system] [--uninstall]
#   default scope: --system when run as root, otherwise --user
set -euo pipefail

APP=cli-tools VERSION=1.1.1
scope="" uninstall=0
for a in "$@"; do
    case "$a" in
        --user) scope=user ;; --system) scope=system ;; --uninstall) uninstall=1 ;;
        -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
        *) echo "Unknown option: $a (see --help)" >&2; exit 1 ;;
    esac
done
[[ -n "$scope" ]] || { [[ $EUID -eq 0 ]] && scope=system || scope=user; }
if [[ $scope == system && $EUID -ne 0 ]]; then echo "--system needs root: sudo $0 --system" >&2; exit 1; fi

if [[ $scope == system ]]; then
    bindir=/usr/local/bin sharedir=/usr/local/share/$APP mandir=/usr/local/share/man/man1
    rcfiles=("/etc/profile.d/$APP.sh")
else
    bindir="$HOME/.local/bin" sharedir="${XDG_DATA_HOME:-$HOME/.local/share}/$APP"
    mandir="$HOME/.local/share/man/man1"   # man-db finds it from ~/.local/bin on PATH
    rcfiles=("$HOME/.profile" "$HOME/.bashrc")
    [[ "${SHELL:-}" == */zsh || -f "$HOME/.zshrc" ]] && rcfiles+=("$HOME/.zshrc")
fi
begin="# >>> $APP >>>" end="# <<< $APP <<<"

remove_block() {   # strip our marked block from a file, if present
    local f="$1"
    [[ -f "$f" ]] && grep -qF "$begin" "$f" || return 0
    sed -i "\|^$begin\$|,\|^$end\$|d" "$f"
}

# ---------- uninstall ----------
if [[ $uninstall -eq 1 ]]; then
    if [[ -f "$sharedir/installed-files.txt" ]]; then
        while IFS= read -r f; do [[ -n "$f" && -e "$bindir/$f" ]] && rm -f -- "$bindir/$f"; done < "$sharedir/installed-files.txt"
    fi
    rm -rf -- "$sharedir"
    rm -f -- "$mandir/$APP.1"
    for f in "${rcfiles[@]}"; do
        if [[ $scope == system ]]; then rm -f -- "$f"; else remove_block "$f"; fi
    done
    echo "Uninstalled ($scope scope). Open a new terminal to drop the refreshenv function."
    exit 0
fi

# ---------- find the source files (repo layout or flat) ----------
src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lin="$src"; [[ -d "$src/linux" ]] && lin="$src/linux"
shopt -s nullglob
tools=("$lin"/*.sh)
shopt -u nullglob
tools=("${tools[@]/$lin\/install.sh/}")
[[ ${#tools[@]} -ge 2 ]] || { echo "No tool scripts found in $lin" >&2; exit 1; }

# ---------- copy ----------
mkdir -p -- "$bindir" "$sharedir"
# remove what a previous version installed, so renamed/removed tools do not linger
previous=()
[[ -f "$sharedir/installed-files.txt" ]] && mapfile -t previous < "$sharedir/installed-files.txt"
for f in "${previous[@]}"; do [[ -n "$f" ]] && rm -f -- "$bindir/$f"; done
: > "$sharedir/installed-files.txt"
n=0
for t in "${tools[@]}"; do
    [[ -n "$t" ]] || continue
    base="$(basename "$t")"
    if [[ "$base" == refreshenv.sh ]]; then target=refreshenv.sh; mode=0644; else target="${base%.sh}"; mode=0755; fi
    if [[ -e "$bindir/$target" ]]; then
        echo "WARNING: $bindir/$target already exists and was not installed by $APP - skipped" >&2; continue
    fi
    install -m "$mode" -- "$t" "$bindir/$target"
    echo "$target" >> "$sharedir/installed-files.txt"; n=$((n + 1))
done
[[ -f "$src/README.md" ]] && install -m 0644 -- "$src/README.md" "$sharedir/README.md"
[[ -d "$src/docs" ]] && { mkdir -p -- "$sharedir/docs"; cp -f -- "$src"/docs/*.md "$sharedir/docs/"; chmod 0644 "$sharedir"/docs/*.md; }
manpage="$src/man/$APP.1"; [[ -f "$manpage" ]] || manpage="$src/$APP.1"
if [[ -f "$manpage" ]]; then mkdir -p -- "$mandir"; install -m 0644 -- "$manpage" "$mandir/$APP.1"; fi
echo "$VERSION" > "$sharedir/VERSION.txt"
echo "Installed $n commands ($scope scope) to: $bindir"
echo "Docs: $sharedir   Help: cli-tools --help, man cli-tools"

# ---------- PATH and refreshenv function ----------
on_path=0
case ":$PATH:" in *":$bindir:"*) on_path=1 ;; esac
block="$begin
case \":\$PATH:\" in *\":$bindir:\"*) ;; *) export PATH=\"$bindir:\$PATH\" ;; esac
[ -n \"\${BASH_VERSION:-}\" ] && refreshenv() { . \"$bindir/refreshenv.sh\"; }
$end"
for f in "${rcfiles[@]}"; do
    if [[ $scope == system ]]; then
        printf '%s\n' "$block" > "$f"; chmod 0644 "$f"
    else
        touch -- "$f"; remove_block "$f"; printf '\n%s\n' "$block" >> "$f"
    fi
done
if [[ $on_path -eq 1 ]]; then
    echo "$bindir is already on PATH."
else
    echo "Added $bindir to PATH in: ${rcfiles[*]}"
fi
echo
echo "Open a new terminal (or run: source ${rcfiles[-1]}) to use the commands and the refreshenv function."
[[ $scope == system ]] && echo "Note: /etc/profile.d is read by login shells; on Ubuntu new terminal windows inherit it after you log out and back in."
exit 0
