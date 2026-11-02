#!/usr/bin/env bash
# cli-tools - help for cli-tools: every tool, its arguments and options, and what it does.
# Usage: cli-tools [-h|--help]   (plain "cli-tools" shows the same help; see also: man cli-tools)
set -u
VERSION=1.1.1

show_help() {
    cat <<EOF
cli-tools $VERSION - everyday command-line utilities (Linux)

Usage: cli-tools [-h | --help]
  Shows this help (so does plain "cli-tools"). The same reference is in "man cli-tools".
  Each tool below runs by name from any shell. Full notes per tool: docs/<tool>.md in
  ~/.local/share/cli-tools (user install) or /usr/local/share/cli-tools (system install).

Conventions
  Exit codes  0 success; 1 bad arguments, nothing to do or cancelled; 2 the check ran but the
              answer was negative (port closed, reboot pending, duplicates found, ...).
  Arguments   UPPER CASE words are values; [square brackets] mark optional ones.

PATHS AND COMMANDS

  pathlist
      Print each PATH entry on its own line, flagging missing folders and duplicates.

  whichall NAME [NAME...]
      Every executable on PATH matching each NAME, in search order; the first one listed
      is the one that runs. Exit 1 if a name is not found.

  refreshenv
      Reload PATH into the current bash session from a fresh login shell, picking up
      changes installers made to /etc/profile.d, ~/.profile and similar. "refreshenv" is
      a shell function set up by the installer; without it run: source refreshenv.sh

SYSTEM

  sysinfo
      One-screen summary: host, OS, model, serial, uptime, CPU, memory and disks.

  pendingreboot
      Is a reboot pending, and why (/var/run/reboot-required, needs-restarting, ...).
      Exit 0 = no, 2 = yes.

  mdmstatus
      Intune status on Linux: the Microsoft Intune app and identity broker services.
      Exit 0 = Intune app present, 2 = not installed.

  eventerrors [HOURS] [MAX] [-w | --warnings]
      Recent critical and error log entries (journalctl, else syslog). Run with sudo to
      include system-wide entries.
      HOURS        How far back to look (default 24).
      MAX          Most entries to show (default 50).
      -w, --warnings  Include warnings too.

NETWORK

  netinfo [-p | --public]
      Addresses, default gateway and DNS servers.
      -p, --public Also look up the public IP via https://api.ipify.org (one external
                   request; needs curl).

  portcheck HOST PORT [TIMEOUT]
      Test whether a remote TCP port is reachable. Exit 0 = open, 2 = closed/filtered.
      TIMEOUT      Seconds to wait (default 3).

  portowner PORT
      Which process is listening on (or using) a local port. Exit 2 if nothing is using
      it. Run with sudo to see other users' processes.

  certcheck HOST [PORT] [WARN_DAYS]
      TLS certificate subject, issuer, expiry and trust for a host (needs openssl).
      Exit 0 = valid, 2 = expired, expiring within WARN_DAYS or untrusted, 1 = error.
      PORT         Default 443.
      WARN_DAYS    Warn when the certificate expires within this many days (default 30).

  dnscheck NAME [TYPE] [SERVER...]
      Resolve NAME with the system resolver and other DNS servers side by side.
      Exit 2 if the answers differ (normal for CDNs). Works best with dig installed.
      TYPE         A (default), AAAA, CNAME, MX, TXT, NS, SRV, SOA or PTR.
      SERVER       Servers to compare against (default 1.1.1.1 8.8.8.8); "none" for the
                   system resolver only. Public servers see the name you look up.

FILES AND DISK

  dirsize [PATH] [TOP]
      Largest immediate subfolders of PATH (default: current directory), staying on one
      filesystem. TOP = how many to list (default 15).

  bigfiles [PATH] [TOP]
      Largest files under PATH (default: current directory), staying on one filesystem.
      TOP = how many to list (default 20).

  hashfile [-a sha256|sha1|md5|sha512] FILE [FILE...]
      Hash of each file (default sha256).

  dupfiles [PATH] [MIN_SIZE_KB]
      Find duplicate files (same size, then same SHA256) under PATH. Reports only;
      deletes nothing. Exit 2 if duplicates are found.
      MIN_SIZE_KB  Ignore files smaller than this (default 1).

  syncsafe [PATH] [--max N] [--win-root PREFIX]
      Find names that break Windows or cloud sync: long paths, invalid characters,
      trailing spaces/dots, reserved names (CON, NUL, COM1...), names over 255 chars.
      Exit 2 if any are found.
      --max N      Path length to flag, 100 or more (default 260).
      --win-root PREFIX  Measure lengths as if PATH were mounted at this Windows path,
                   e.g. --win-root 'X:\\GoogleDrive\\Shared'

  empty-directories [options] INPUT_FILE
      Empty (and by default remove) every directory listed in a .txt or .csv file:
      one path per line or a comma-separated list; "base: /path" line optional.
      Lists everything first and asks you to type YES before changing anything.
      -b, --base PATH      Base for relative entries (else the file's "base:" line, else
                           the current directory after you confirm).
      -f, --format FORMAT  auto (default), lines or comma.
      -k, --keep-folders   Empty the directories but leave the empty folders in place.
      -n, --dry-run        Validate and report only; change nothing.
      -y, --force          Skip the YES confirmation.
      -l, --log PATH       Results CSV (default <inputfile>-results-<timestamp>.csv).
      -h, --help           Show its own help.

HELP

  cli-tools [-h | --help]
      This help.  man cli-tools  shows the same reference as a manual page.
EOF
}

case "${1:-}" in
    ""|-h|--help|help) [[ $# -le 1 ]] && { show_help; exit 0; } ;;
esac
echo "Unknown option: $*" >&2
show_help
exit 1
