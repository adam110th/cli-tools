#!/usr/bin/env bash
# install-extras.sh - install recommended third-party CLI tools (not part of cli-tools) with the system package manager.
#
# Uses apt, dnf/yum, pacman, zypper, apk or brew, whichever is present. Adds the official apt repositories
# and keyrings for gh (cli.github.com) and, when the distro has no eza package, eza (deb.gierens.de).
# Tools a distro does not package are taken from the project's latest GitHub release (to /usr/local/bin);
# claude uses Anthropic's native installer (to ~/.local/bin of the invoking user).
# Writes a marked block (# >>> cli-tools extras >>>) to ~/.bashrc and ~/.zshrc with the eza alias,
# bat -> batcat on Debian/Ubuntu, and the zoxide and thefuck shell hooks.
# Already-installed tools are skipped. Needs root or sudo for package installs.
#
# Usage: ./install-extras.sh [--list] [TOOL...]     (default: every tool)
#   exit 0 all done, 1 bad arguments, 2 one or more tools could not be installed
set -uo pipefail

# colour only on a terminal, and never when NO_COLOR is set (https://no-color.org); E* are the stderr set.
{ if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' C=$'\e[1;36m' B=$'\e[1m' D=$'\e[2m' N=$'\e[0m'; else R='' G='' Y='' C='' B='' D='' N=''; fi
  if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then ER=$'\e[31m' EY=$'\e[33m' EN=$'\e[0m'; else ER='' EY='' EN=''; fi; }

# name      command(s)          apt                      dnf                 pacman               zypper     apk          brew
TOOLS="
thefuck     thefuck             thefuck                  thefuck             thefuck              thefuck    -            thefuck
zoxide      zoxide              zoxide                   zoxide              zoxide               zoxide     zoxide       zoxide
tldr        tldr                tealdeer,tldr            tealdeer,tldr       tealdeer             tealdeer   tealdeer     tealdeer
scc         scc                 -                        -                   scc                  -          -            scc
eza         eza                 eza                      eza                 eza                  eza        eza          eza
duf         duf                 duf                      duf                 duf                  duf        duf          duf
bat         bat,batcat          bat                      bat                 bat                  bat        bat          bat
exiftool    exiftool            libimage-exiftool-perl   perl-Image-ExifTool perl-image-exiftool  exiftool   exiftool     exiftool
fdupes      fdupes              fdupes                   fdupes              fdupes               fdupes     fdupes       fdupes
fzf         fzf                 fzf                      fzf                 fzf                  fzf        fzf          fzf
jq          jq                  jq                       jq                  jq                   jq         jq           jq
procs       procs               procs                    procs               procs                procs      procs        procs
browsh      browsh              -                        -                   -                    -          -            browsh
ddgr        ddgr                ddgr                     ddgr                ddgr                 ddgr       -            ddgr
lazygit     lazygit             lazygit                  lazygit             lazygit              lazygit    lazygit      lazygit
asciinema   asciinema           asciinema                asciinema           asciinema            asciinema  asciinema    asciinema
neofetch    neofetch,fastfetch  neofetch,fastfetch       neofetch,fastfetch  fastfetch            neofetch   neofetch     fastfetch
tre         tre                 -                        -                   -                    -          -            tre-command
git         git                 git                      git                 git                  git        git          git
gh          gh                  gh                       gh                  github-cli           gh         github-cli   gh
claude      claude              -                        -                   -                    -          -            -
"
names=() ; while read -r n _; do [[ -n "$n" ]] && names+=("$n"); done <<< "$TOOLS"

want=()
for a in "$@"; do
    case "$a" in
        -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
        --list) printf '%s\n' "${names[@]}"; exit 0 ;;
        -*) echo "${ER}Unknown option: $a (see --help)${EN}" >&2; exit 1 ;;
        *) [[ " ${names[*]} " == *" $a "* ]] || { echo "${ER}Unknown tool: $a (see --list)${EN}" >&2; exit 1; }; want+=("$a") ;;
    esac
done
[[ ${#want[@]} -gt 0 ]] || want=("${names[@]}")

# ---------- privileges, target user, package manager ----------
as_root() { if [[ $EUID -eq 0 ]]; then "$@"; else sudo "$@"; fi; }
if [[ $EUID -ne 0 ]] && ! command -v sudo >/dev/null; then echo "${ER}Needs root or sudo to install packages.${EN}" >&2; exit 1; fi
tuser="${SUDO_USER:-$(id -un)}"
thome="$(getent passwd "$tuser" 2>/dev/null | cut -d: -f6)"; thome="${thome:-$HOME}"
as_user() { if [[ $EUID -eq 0 && "$tuser" != root ]]; then sudo -u "$tuser" -H "$@"; else "$@"; fi; }

pm="" col=0
for p in apt-get:3 dnf:4 yum:4 pacman:5 zypper:6 apk:7 brew:8; do
    command -v "${p%%:*}" >/dev/null && { pm="${p%%:*}"; col="${p##*:}"; break; }
done
[[ -n "$pm" ]] || echo "${EY}No supported package manager found; trying GitHub releases only.${EN}" >&2

available() {   # is package $1 installable from the configured repositories?
    case "$pm" in
        apt-get) apt-cache policy "$1" 2>/dev/null | grep -q 'Candidate: [^(]' ;;
        dnf|yum) "$pm" -q info "$1" >/dev/null 2>&1 ;;
        pacman)  pacman -Si "$1" >/dev/null 2>&1 ;;
        zypper)  zypper -q -n search -x "$1" >/dev/null 2>&1 ;;
        apk)     [[ -n "$(apk search -q -e "$1" 2>/dev/null)" ]] ;;
        brew)    brew info "$1" >/dev/null 2>&1 ;;
        *) return 1 ;;
    esac
}
pm_install() {
    case "$pm" in
        apt-get) as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
        dnf|yum) as_root "$pm" install -y "$@" ;;
        pacman)  as_root pacman -S --needed --noconfirm "$@" ;;
        zypper)  as_root zypper -n install "$@" ;;
        apk)     as_root apk add "$@" ;;
        brew)    as_user brew install "$@" ;;
    esac
}

# ---------- repositories and keyrings ----------
need_cmd() { command -v "$1" >/dev/null || pm_install "${2:-$1}" >/dev/null; }
step() { echo; echo "${C}$*${N}"; }

if [[ $pm == apt-get ]]; then
    step "Preparing apt (prerequisites, GitHub CLI repository)"
    as_root apt-get update -qq
    as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ca-certificates curl gpg unzip >/dev/null
    as_root install -d -m 0755 /etc/apt/keyrings
    if [[ " ${want[*]} " == *" gh "* && ! -f /etc/apt/sources.list.d/github-cli.list ]]; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | as_root tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null &&
        as_root chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg &&
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
            as_root tee /etc/apt/sources.list.d/github-cli.list >/dev/null && echo "  added cli.github.com"
    fi
    if [[ " ${want[*]} " == *" eza "* ]] && ! command -v eza >/dev/null && ! available eza && [[ ! -f /etc/apt/sources.list.d/gierens.list ]]; then
        curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | as_root gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg &&
        as_root chmod go+r /etc/apt/keyrings/gierens.gpg &&
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" |
            as_root tee /etc/apt/sources.list.d/gierens.list >/dev/null && echo "  added deb.gierens.de (eza)"
    fi
    as_root apt-get update -qq
elif [[ -n "$pm" ]]; then
    step "Preparing $pm (prerequisites)"
    case "$pm" in zypper) as_root zypper -q refresh ;; apk) as_root apk update -q ;; esac
    need_cmd curl; need_cmd tar; need_cmd unzip
    if [[ $pm == dnf || $pm == yum || $pm == zypper ]] && [[ " ${want[*]} " == *" gh "* ]] && ! command -v gh >/dev/null && ! available gh; then
        repo=https://cli.github.com/packages/rpm/gh-cli.repo
        case "$pm" in
            zypper) as_root zypper -n addrepo "$repo" && as_root zypper -n --gpg-auto-import-keys refresh ;;
            *) as_root "$pm" install -y 'dnf-command(config-manager)' >/dev/null 2>&1
               as_root "$pm" config-manager addrepo --from-repofile="$repo" 2>/dev/null || as_root "$pm" config-manager --add-repo "$repo" ;;
        esac && echo "  added cli.github.com"
    fi
fi

# ---------- fallbacks for tools a distro does not package ----------
case "$(uname -m)" in x86_64|amd64) A='(x86_64|amd64)' ;; aarch64|arm64) A='(aarch64|arm64)' ;; *) A='' ;; esac
gh_release() {   # gh_release OWNER/REPO REGEX BIN - newest release asset matching REGEX (lower case) to /usr/local/bin/BIN
    local repo="$1" re="${2//@A@/$A}" bin="$3" assets url="" u q tmp f rc=1
    [[ -n "$A" ]] || return 1
    # the latest release first; some projects (browsh) ship binaries only in earlier ones, so then the last few
    for q in releases/latest 'releases?per_page=5'; do
        assets="$(curl -fsSL "https://api.github.com/repos/$repo/$q" | grep -o '"browser_download_url": *"[^"]*"' | cut -d'"' -f4)" || continue
        while read -r u; do [[ "${u,,}" =~ $re ]] && { url="$u"; break; }; done <<< "$assets"
        [[ -n "$url" ]] && break
    done
    [[ -n "$url" ]] || return 1
    tmp="$(mktemp -d)"
    if curl -fsSL -o "$tmp/asset" "$url"; then
        case "$url" in
            *.tar.gz|*.tgz) tar -xzf "$tmp/asset" -C "$tmp" ;;
            *.zip) unzip -q "$tmp/asset" -d "$tmp" ;;
            *) mv "$tmp/asset" "$tmp/$bin" ;;
        esac
        f="$(find "$tmp" -type f -name "$bin" -print -quit)"
        [[ -n "$f" ]] && as_root install -m 0755 "$f" "/usr/local/bin/$bin" && rc=0
    fi
    rm -rf -- "$tmp"; return $rc
}
fallback() {
    case "$1" in
        thefuck)   command -v pipx >/dev/null && as_user pipx install thefuck ;;
        zoxide)    gh_release ajeetdsouza/zoxide 'zoxide-[0-9.]+-@A@-unknown-linux-musl\.tar\.gz$' zoxide ;;
        tldr)      gh_release tealdeer-rs/tealdeer 'tealdeer-linux-@A@-musl$' tldr ;;
        scc)       gh_release boyter/scc 'scc_linux_@A@\.tar\.gz$' scc ;;
        eza)       gh_release eza-community/eza 'eza_@A@-unknown-linux-gnu\.tar\.gz$' eza ;;
        duf)       gh_release muesli/duf 'duf_[0-9.]+_linux_@A@\.tar\.gz$' duf ;;
        bat)       gh_release sharkdp/bat 'bat-v[0-9.]+-@A@-unknown-linux-(musl|gnu)\.tar\.gz$' bat ;;
        fzf)       gh_release junegunn/fzf 'fzf-[0-9.]+-linux_@A@\.tar\.gz$' fzf ;;
        jq)        gh_release jqlang/jq 'jq-linux-@A@$' jq ;;
        procs)     gh_release dalance/procs 'procs-v[0-9.]+-@A@-linux\.zip$' procs ;;
        browsh)    gh_release browsh-org/browsh 'browsh_[0-9.]+_linux_@A@$' browsh &&
                   { command -v firefox >/dev/null || echo "  ${Y}browsh needs Firefox: install firefox to use it${N}"; } ;;
        lazygit)   gh_release jesseduffield/lazygit 'lazygit_[0-9.]+_linux_@A@\.tar\.gz$' lazygit ;;
        asciinema) gh_release asciinema/asciinema 'asciinema-@A@-unknown-linux-(gnu|musl)$' asciinema ;;
        tre)       gh_release dduan/tre 'tre-v[0-9.]+-@A@-unknown-linux-(musl|gnu)\.tar\.gz$' tre ;;
        gh)        gh_release cli/cli 'gh_[0-9.]+_linux_@A@\.tar\.gz$' gh ;;
        claude)    as_user bash -c 'curl -fsSL https://claude.ai/install.sh | bash' ;;
        *) return 1 ;;
    esac
}

# ---------- install ----------
installed=() present=() failed=()
have() {   # is any of the comma-separated commands on PATH (or in the target user's ~/.local/bin)?
    local c; IFS=, read -ra cs <<< "$1"
    for c in "${cs[@]}"; do command -v "$c" >/dev/null || [[ -x "$thome/.local/bin/$c" ]] && return 0; done; return 1
}
step "Installing third-party CLI tools${pm:+ with $pm}"
while read -r -a row; do
    [[ ${#row[@]} -ge 8 ]] || continue
    name="${row[0]}"
    [[ " ${want[*]} " == *" $name "* ]] || continue
    if have "${row[1]}"; then printf '  %-10s %s\n' "$name" "${D}already installed${N}"; present+=("$name"); continue; fi
    pkg=""
    if [[ $col -gt 0 && "${row[$((col - 1))]}" != - ]]; then
        IFS=, read -ra alts <<< "${row[$((col - 1))]}"
        for p in "${alts[@]}"; do available "$p" && { pkg="$p"; break; }; done
    fi
    if [[ -n "$pkg" ]] && pm_install "$pkg" >/dev/null 2>&1; then
        printf '  %-10s %s\n' "$name" "${G}installed${N} ($pm: $pkg)"; installed+=("$name")
    elif fallback "$name" >/dev/null 2>&1 && { hash -r; have "${row[1]}"; }; then
        printf '  %-10s %s\n' "$name" "${G}installed${N} (upstream release)"; installed+=("$name")
    else
        printf '  %-10s %s\n' "$name" "${R}FAILED${N} (no package for $pm${pm:+ and no usable upstream release})"; failed+=("$name")
    fi
done <<< "$TOOLS"

# ---------- shell aliases and hooks ----------
begin="# >>> cli-tools extras >>>" end="# <<< cli-tools extras <<<"
block="$begin
# aliases and shell hooks for the third-party tools from install-extras.sh (safe if a tool is missing)
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then alias bat='batcat'; fi
if command -v eza >/dev/null 2>&1; then alias eza='eza -a -l -h -M --icons=always'; fi
if [ -n \"\${BASH_VERSION:-}\" ]; then _clt_sh=bash; elif [ -n \"\${ZSH_VERSION:-}\" ]; then _clt_sh=zsh; else _clt_sh=; fi
if [ -n \"\$_clt_sh\" ]; then
    if command -v zoxide >/dev/null 2>&1; then eval \"\$(zoxide init \$_clt_sh)\"; fi
    if command -v thefuck >/dev/null 2>&1; then eval \"\$(thefuck --alias 2>/dev/null)\"; fi
fi
unset _clt_sh
$end"
step "Shell aliases (eza, bat) and hooks (zoxide, thefuck)"
rcs=("$thome/.bashrc"); [[ -f "$thome/.zshrc" ]] && rcs+=("$thome/.zshrc")
for f in "${rcs[@]}"; do
    [[ -f "$f" ]] && sed -i "\|^$begin\$|,\|^$end\$|d" "$f"
    printf '\n%s\n' "$block" >> "$f"
    [[ $EUID -eq 0 && "$tuser" != root ]] && chown "$tuser": "$f"
    echo "  updated $f"
done

# ---------- summary ----------
echo
echo "${B}Done:${N} ${G}${#installed[@]} installed${N}, ${#present[@]} already present, $([[ ${#failed[@]} -gt 0 ]] && echo "$R")${#failed[@]} failed${N}${failed[*]:+: ${failed[*]}}"
echo "Open a new terminal (or: source ~/.bashrc) to pick up the aliases. eza --icons needs a Nerd Font in your terminal."
[[ ${#failed[@]} -eq 0 ]] || exit 2
exit 0
