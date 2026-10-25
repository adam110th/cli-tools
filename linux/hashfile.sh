#!/usr/bin/env bash
# hashfile - file hashes (default SHA256).
# Usage: hashfile.sh [-a sha256|sha1|md5|sha512] FILE [FILE...]
set -u
algo=sha256
if [[ "${1:-}" == "-a" ]]; then algo="${2:-}"; shift 2 || true; fi
algo="${algo,,}"
[[ "$algo" =~ ^(sha256|sha1|md5|sha512)$ ]] || { echo "Algorithm must be sha256, sha1, md5 or sha512" >&2; exit 1; }
[[ $# -ge 1 ]] || { echo "Usage: hashfile.sh [-a sha256|sha1|md5|sha512] FILE [FILE...]" >&2; exit 1; }
"${algo}sum" -- "$@"
