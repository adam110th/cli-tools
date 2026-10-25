<#
.SYNOPSIS  Help for cli-tools: every tool, its arguments and options, and what it does.
.EXAMPLE   cli-tools
.EXAMPLE   cli-tools --help
#>
# No param block on purpose: -h, --help and /? arrive in $args instead of failing parameter binding.
$Version = '1.1.0'
# Flat install keeps docs\ beside the scripts; the repo layout has it one level up
$docs = Join-Path $PSScriptRoot 'docs'
if (-not (Test-Path -LiteralPath $docs)) { $docs = Join-Path (Split-Path $PSScriptRoot -Parent) 'docs' }
$help = @"
cli-tools $Version - everyday command-line utilities for PowerShell and Command Prompt

Usage: cli-tools [-h | --help | /?]
  Shows this help (so does plain "cli-tools"). Each tool below runs by name from any
  PowerShell or cmd window. Full notes per tool: $docs\<tool>.md

Conventions
  Exit codes  0 success; 1 bad arguments, nothing to do or cancelled; 2 the check ran but the
              answer was negative (port closed, reboot pending, duplicates found, ...).
  Arguments   PowerShell parameters can be given by name (-Top 10) or, where shown as
              [VALUE] / VALUE, by position. Wrapper tools take the same arguments in cmd.
  cmd:        lines show Command Prompt syntax where a native .cmd version differs.

PATHS AND COMMANDS

  pathlist [-Scope Process|User|Machine]
      Print each PATH entry on its own line, flagging missing folders and duplicates.
      -Scope       Process (default) = the PATH this window sees; User or Machine = as
                   stored in the registry.
      cmd:         pathlist   (no options; this window's PATH)

  whichall NAME [NAME...]
      Every executable on PATH matching each NAME, in search order; the first one listed
      is the one that runs. Exit 1 if a name is not found.

  refreshenv
      Reload PATH and other environment variables from the registry into the current
      window, so newly installed tools work without opening a new window.
      PowerShell:  . refreshenv   (must be dot-sourced)
      cmd:         refreshenv

SYSTEM

  sysinfo
      One-screen summary: host, OS, model, serial, uptime, CPU, memory, disks and
      Entra / domain join. (The cmd version uses systeminfo and takes about 10 s.)

  pendingreboot
      Is a reboot pending, and why (Windows Update, component servicing, pending file
      renames, ...). Exit 0 = no, 2 = yes.

  mdmstatus [-Sync]
      Intune / MDM status: Entra join, MDM enrolments, last sync and the Intune
      Management Extension. Exit 2 if no MDM enrolment is found.
      -Sync        Trigger an MDM policy sync (needs an elevated window) and an Intune
                   Management Extension app check-in. Changes no settings.

  eventerrors [-Hours N] [-Max N] [-IncludeWarnings] [-LogName LOG[,LOG...]]
      Recent critical and error events, with a summary by source.
      -Hours       How far back to look, 1-8760 (default 24).
      -Max         Most events to show, 1-10000 (default 50).
      -IncludeWarnings  Include warning events too.
      -LogName     Event logs to read (default System, Application).

NETWORK

  netinfo [-Public]
      Adapters that are up, with IPv4/IPv6 addresses, default gateway and DNS servers.
      -Public      Also look up the public IP via https://api.ipify.org (one external
                   request).
      cmd:         netinfo [/public]

  portcheck HOST PORT [TIMEOUT]
      Test whether a remote TCP port is reachable. Exit 0 = open, 2 = closed/filtered.
      HOST         Host name or IP address.
      PORT         1-65535.
      TIMEOUT      Seconds to wait, 1-120 (default 3). Named: -TimeoutSeconds.

  portowner PORT
      Which process is listening on (or using) a local TCP/UDP port. Exit 2 if nothing
      is using it. Run elevated to see process paths for other users.

  certcheck HOST [PORT] [-WarnDays N]
      TLS certificate subject, issuer, SANs, expiry and trust for a host.
      Exit 0 = valid, 2 = expired, expiring within WarnDays or untrusted, 1 = error.
      PORT         Default 443.
      -WarnDays    Warn when the certificate expires within N days, 0-3650 (default 30).

  dnscheck NAME [TYPE] [-Server SERVER[,SERVER...]]
      Resolve NAME with the system resolver and other DNS servers side by side.
      Exit 2 if the answers differ (normal for CDNs).
      TYPE         A (default), AAAA, CNAME, MX, TXT, NS, SRV, SOA or PTR.
      -Server      Servers to compare against (default 1.1.1.1, 8.8.8.8); -Server @() for
                   the system resolver only. Public servers see the name you look up.
      cmd:         dnscheck NAME [TYPE] [SERVER...]   ("none" = system resolver only)

FILES AND DISK

  dirsize [PATH] [TOP]
      Largest immediate subfolders of PATH (default: current folder), with size and
      file count. TOP = how many to list, 1-1000 (default 15).

  bigfiles [PATH] [TOP]
      Largest files under PATH (default: current folder). TOP = how many to list,
      1-10000 (default 20).

  hashfile FILE [FILE...] [-Algorithm SHA256|SHA1|MD5|SHA512]
      Hash of each file (default SHA256), lower case, one per line.
      cmd:         hashfile FILE [SHA256|SHA1|MD5|SHA512]   (one file, uses certutil)

  dupfiles [PATH] [MINSIZEKB] [-IncludeCloudOnly] [-CsvPath FILE]
      Find duplicate files (same size, then same SHA256) under PATH. Reports only;
      deletes nothing. Exit 2 if duplicates are found.
      MINSIZEKB    Ignore files smaller than this (default 1).
      -IncludeCloudOnly  Also hash online-only cloud files (downloads every one).
      -CsvPath     Also save the duplicate list to this CSV file.

  syncsafe [PATH] [-MaxPath N] [-CsvPath FILE]
      Find names that break Windows or cloud sync: long paths, invalid characters,
      trailing spaces/dots, reserved names (CON, NUL, COM1...), names over 255 chars.
      Exit 2 if any are found.
      -MaxPath     Path length to flag, 100-32767 (default 260).
      -CsvPath     Also save the findings to this CSV file.

  empty-directories INPUTFILE [BASEPATH] [options]
      Empty (and by default remove) every directory listed in a .txt or .csv file:
      one path per line or a comma-separated list; "base: X:\path" line optional.
      Lists everything first and asks you to type YES before changing anything.
      BASEPATH     Base for relative entries (else the file's "base:" line, else the
                   current folder after you confirm).
      -Format      Auto (default), Lines or Comma.
      -KeepFolders Empty the directories but leave the empty folders in place.
      -Force       Skip the YES confirmation.
      -LogPath     Results CSV (default <inputfile>-results-<timestamp>.csv).
      -WhatIf      Dry run: validate and report only.

HELP

  cli-tools [-h | --help | /?]
      This help.
"@

if ($args.Count -eq 0 -or ($args.Count -eq 1 -and $args[0] -in '-h', '--help', '-help', '/?', '-?', 'help')) {
    $help
    exit 0
}
[Console]::Error.WriteLine("Unknown option: $($args -join ' ')")
$help
exit 1
