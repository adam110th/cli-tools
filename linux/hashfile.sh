#!/usr/bin/env bash
# hashfile - file hashes (default SHA256).
# Usage: hashfile.sh [-a sha256|sha1|md5|sha512] FILE [FILE...]
set -u
# colour only on a terminal, and never when NO_COLOR is set (https://no-color.org); E* are the stderr set.
# Not every tool uses every colour, hence the SC2034 directive.
# shellcheck disable=SC2034
{ if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' C=$'\e[1;36m' B=$'\e[1m' D=$'\e[2m' N=$'\e[0m'; else R='' G='' Y='' C='' B='' D='' N=''; fi
  if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then ER=$'\e[31m' EY=$'\e[33m' EB=$'\e[1m' EN=$'\e[0m'; else ER='' EY='' EB='' EN=''; fi; }
algo=sha256
if [[ "${1:-}" == "-a" ]]; then algo="${2:-}"; shift 2 || true; fi
algo="${algo,,}"
[[ "$algo" =~ ^(sha256|sha1|md5|sha512)$ ]] || { echo "${ER}Algorithm must be sha256, sha1, md5 or sha512${EN}" >&2; exit 1; }
[[ $# -ge 1 ]] || { echo "${ER}Usage: hashfile.sh [-a sha256|sha1|md5|sha512] FILE [FILE...]${EN}" >&2; exit 1; }
"${algo}sum" -- "$@"
