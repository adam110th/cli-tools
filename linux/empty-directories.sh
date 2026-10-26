#!/usr/bin/env bash
# empty-directories.sh - empty (and by default remove) every directory listed in a .txt or .csv file.
# Linux equivalent of Empty-Directories.ps1. Requires bash 4+ and GNU coreutils/findutils.

set -uo pipefail

usage() {
    cat <<'EOF'
Usage: empty-directories.sh [options] INPUT_FILE

Input file:
  - One path per line, OR a comma-separated list (quote any path containing a comma).
  - Optional base path line anywhere in the file:   base: /mnt/gdrive/shared
  - Lines starting with # are comments; an optional Path/Directory/Folder CSV header is ignored.
  - Pasted error text after a path (" - The directory is not empty.") is stripped.

Base path precedence: -b/--base, then the "base:" line in the file, then the current
directory (only after you confirm it). Absolute entries (/...) ignore the base path.
Relative entries may not climb out of the base path with "..".

Options:
  -b, --base PATH       Base path for relative entries
  -f, --format FORMAT   auto (default), lines or comma. auto: several lines = lines mode,
                        a single line = comma mode
  -k, --keep-folders    Empty the directories but leave the empty folders in place
  -n, --dry-run         Validate and report only; change nothing
  -y, --force           Skip the final YES confirmation
  -l, --log PATH        Results CSV (default: <inputfile>-results-<timestamp>.csv)
  -h, --help            Show this help

Exit codes: 0 clean run, 1 cancelled or nothing to do, 2 some entries skipped or only partly emptied.
EOF
}

die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
warn() { printf '\033[33mWARNING: %s\033[0m\n' "$*" >&2; }

BASE="" FORMAT="auto" KEEP=0 DRYRUN=0 FORCE=0 LOG="" INPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--base)         [[ $# -ge 2 ]] || die "$1 needs a value"; BASE="$2"; shift 2 ;;
        -f|--format)       [[ $# -ge 2 ]] || die "$1 needs a value"; FORMAT="${2,,}"; shift 2 ;;
        -k|--keep-folders) KEEP=1; shift ;;
        -n|--dry-run)      DRYRUN=1; shift ;;
        -y|--force)        FORCE=1; shift ;;
        -l|--log)          [[ $# -ge 2 ]] || die "$1 needs a value"; LOG="$2"; shift 2 ;;
        -h|--help)         usage; exit 0 ;;
        --)                shift; INPUT="${1:-}"; break ;;
        -*)                die "Unknown option: $1 (see --help)" ;;
        *)                 [[ -z "$INPUT" ]] || die "Only one input file allowed"; INPUT="$1"; shift ;;
    esac
done
[[ -n "$INPUT" ]] || { usage; exit 1; }
[[ "$FORMAT" =~ ^(auto|lines|comma)$ ]] || die "--format must be auto, lines or comma"
[[ -f "$INPUT" ]] || die "Input file not found: $INPUT"
INPUT="$(realpath -- "$INPUT")"

read_yes_no() {   # $1 = question; re-prompts until Y or N
    local a
    while true; do
        read -r -p "$1 [Y/N]: " a || return 1
        case "${a,,}" in y|yes) return 0 ;; n|no) return 1 ;; *) echo "Please answer Y or N." ;; esac
    done
}

trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }

strip_quotes() { local s="$1"; [[ "$s" == \"*\" && ${#s} -ge 2 ]] && s="${s:1:${#s}-2}"; printf '%s' "$s"; }

item_count() { find "$1" -mindepth 1 -printf '.' 2>/dev/null | wc -c; }

ERR_SUFFIX='[[:space:]]+-[[:space:]]+(The directory is not empty|The filename, directory name, or volume label syntax is incorrect|The system cannot find the (file|path) specified|Access is denied|Directory not empty|No such file or directory|Permission denied)\.?[[:space:]]*$'
BASE_RE='^[[:space:]]*#?[[:space:]]*[Bb][Aa][Ss][Ee]([Pp][Aa][Tt][Hh])?[[:space:]]*[:=][[:space:]]*(.+)$'
HEADER_RE='^[[:space:]]*"?([Pp]ath|[Dd]irectory|[Ff]older|[Dd]ir)"?[[:space:]]*,?[[:space:]]*$'

# ---------- read input ----------
FILE_BASE="" body=()
while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    if [[ "$line" =~ $BASE_RE ]]; then
        [[ -z "$FILE_BASE" ]] && FILE_BASE="$(strip_quotes "$(trim "${BASH_REMATCH[2]}")")"
        continue
    fi
    t="$(trim "$line")"
    [[ -z "$t" || "$t" == \#* ]] && continue
    [[ ${#body[@]} -eq 0 && "$t" =~ $HEADER_RE ]] && continue
    body+=("$t")
done < "$INPUT"
[[ ${#body[@]} -gt 0 ]] || die "No directory entries found in the input file."

if [[ "$FORMAT" == auto ]]; then
    FORMAT=comma
    if [[ ${#body[@]} -gt 1 ]]; then
        FORMAT=lines
        for l in "${body[@]}"; do [[ "$l" == *, ]] && { FORMAT=comma; break; }; done
    fi
fi

raw=()
if [[ "$FORMAT" == lines ]]; then
    for l in "${body[@]}"; do l="${l%,}"; raw+=("$(strip_quotes "$(trim "$l")")"); done
else
    # quote-aware comma split ("" inside quotes is a literal quote)
    text="$(printf '%s\n' "${body[@]}")" field="" inq=0 i=0
    while [[ $i -lt ${#text} ]]; do
        c="${text:i:1}"
        if [[ $inq -eq 1 ]]; then
            if [[ "$c" == '"' ]]; then
                if [[ "${text:i+1:1}" == '"' ]]; then field+='"'; ((i++)); else inq=0; fi
            else field+="$c"; fi
        else
            case "$c" in
                '"')        inq=1 ;;
                ','|$'\n')  raw+=("$(trim "$field")"); field="" ;;
                *)          field+="$c" ;;
            esac
        fi
        ((i++))
    done
    raw+=("$(trim "$field")")
fi

# clean, drop pasted error text, de-duplicate
declare -A seen=()
entries=()
for e in "${raw[@]}"; do
    [[ "$e" =~ $ERR_SUFFIX ]] && e="${e%"${BASH_REMATCH[0]}"}"
    e="$(strip_quotes "$(trim "$e")")"
    while [[ "$e" == */ && "$e" != / ]]; do e="${e%/}"; done
    [[ -z "$e" || -n "${seen[$e]:-}" ]] && continue
    seen[$e]=1; entries+=("$e")
done
[[ ${#entries[@]} -gt 0 ]] || die "No usable entries after cleaning."
echo "Read ${#entries[@]} entr$([[ ${#entries[@]} -eq 1 ]] && echo y || echo ies) ($FORMAT mode) from $INPUT"

# ---------- resolve base path ----------
needs_base=0
for e in "${entries[@]}"; do [[ "$e" == /* ]] || { needs_base=1; break; }; done
if [[ $needs_base -eq 1 ]]; then
    if [[ -n "$BASE" ]]; then
        echo "Base path (parameter): $BASE"
    elif [[ -n "$FILE_BASE" ]]; then
        BASE="$FILE_BASE"; echo "Base path (from input file): $BASE"
    else
        warn "No base path was given as a parameter or found in the input file."
        if ! read_yes_no "Use the current directory '$PWD' as the base path?"; then
            echo 'Cancelled. Re-run with --base or add a "base: <path>" line to the input file.'
            exit 1
        fi
        BASE="$PWD"
    fi
    [[ "$BASE" == /* ]] || die "Base path must be absolute: $BASE"
    BASE="$(realpath -m -s -- "$BASE")"
    [[ -d "$BASE" ]] || die "Base path not found: $BASE"
fi

# ---------- validate every entry before touching anything ----------
R_ENTRY=() R_FULL=() R_STATUS=() R_ITEMS=() R_DETAIL=()
add_result() { R_ENTRY+=("$1"); R_FULL+=("$2"); R_STATUS+=("$3"); R_ITEMS+=("$4"); R_DETAIL+=("$5"); }

for e in "${entries[@]}"; do
    if [[ "$e" == /* ]]; then full="$(realpath -m -s -- "$e")"
    else full="$(realpath -m -s -- "$BASE/$e")"; fi

    if [[ "$full" == / || ( -n "$BASE" && "$full" == "$BASE" ) ]]; then
        add_result "$e" "$full" Blocked 0 "Refusing to empty / or the base path itself"; continue
    fi
    if [[ "$e" != /* && "$full" != "$BASE"/* ]]; then
        add_result "$e" "$full" Blocked 0 "Relative entry resolves outside the base path"; continue
    fi
    if [[ -L "$full" ]]; then
        add_result "$e" "$full" Blocked 0 "Path is a symbolic link"; continue
    fi
    # a symlinked parent would make find -delete empty the link's target instead. Links above the
    # base path are the user's choice, so relative entries are compared below the resolved base only.
    want="$full"; [[ "$e" != /* ]] && want="$(realpath -e -- "$BASE")${full#"$BASE"}"
    if [[ -e "$full" && "$(realpath -e -- "$full")" != "$want" ]]; then
        add_result "$e" "$full" Blocked 0 "Path goes through a symbolic link; list the real folder instead"; continue
    fi
    if [[ -d "$full" ]]; then
        add_result "$e" "$full" Found "$(item_count "$full")" ""
    elif [[ -e "$full" ]]; then
        add_result "$e" "$full" NotADirectory 0 "Path is a file, not a directory"
    else
        add_result "$e" "$full" NotFound 0 ""
    fi
done

todo=() total=0
for i in "${!R_ENTRY[@]}"; do
    if [[ "${R_STATUS[i]}" == Found ]]; then
        todo+=("$i"); total=$((total + R_ITEMS[i]))
    else
        msg="${R_STATUS[i]}: ${R_ENTRY[i]}"; [[ -n "${R_DETAIL[i]}" ]] && msg+=" -- ${R_DETAIL[i]}"
        warn "$msg"
    fi
done

if [[ ${#todo[@]} -eq 0 ]]; then echo "Nothing to do: no listed directories were found."; exit 1; fi

echo
echo "${#todo[@]} director$([[ ${#todo[@]} -eq 1 ]] && echo y || echo ies) found, $total item(s) in total:"
for i in "${todo[@]}"; do printf '  %7s  %s\n' "${R_ITEMS[i]}" "${R_FULL[i]}"; done
echo

if [[ $FORCE -eq 0 && $DRYRUN -eq 0 ]]; then
    action="EMPTY AND REMOVE"; [[ $KEEP -eq 1 ]] && action="EMPTY"
    read -r -p "Type YES to $action these ${#todo[@]} directories: " answer || answer=""
    [[ "$answer" == YES ]] || { echo "Cancelled. Nothing was changed."; exit 1; }
fi

# ---------- empty ----------
for i in "${todo[@]}"; do
    d="${R_FULL[i]}"
    if [[ $DRYRUN -eq 1 ]]; then
        echo "DRY RUN: would $([[ $KEEP -eq 1 ]] && echo empty || echo 'empty and remove') $d"
        R_STATUS[i]=DryRun; continue
    fi
    find "$d" -mindepth 1 -delete 2>/dev/null
    left="$(item_count "$d")"
    if [[ $left -gt 0 ]]; then
        R_STATUS[i]=Partial; R_DETAIL[i]="$left item(s) remain (permissions or open file?)"
        printf '\033[31mPARTIAL: %s (%s left)\033[0m\n' "$d" "$left"
    elif [[ $KEEP -eq 1 ]]; then
        R_STATUS[i]=Emptied; printf '\033[32mEMPTIED: %s\033[0m\n' "$d"
    elif rmdir -- "$d" 2>/dev/null; then
        R_STATUS[i]=Removed; printf '\033[32mREMOVED: %s\033[0m\n' "$d"
    else
        R_STATUS[i]=Emptied; R_DETAIL[i]="Emptied but folder not removed"
        printf '\033[33mEMPTIED (folder kept): %s\033[0m\n' "$d"
    fi
done

# ---------- report ----------
[[ -n "$LOG" ]] || LOG="${INPUT%.*}-results-$(date +%Y-%m-%d_%H%M%S).csv"
csv() { local s="${1//\"/\"\"}"; printf '"%s"' "$s"; }
{
    echo '"Entry","FullPath","Status","Items","Detail"'
    for i in "${!R_ENTRY[@]}"; do
        printf '%s,%s,%s,%s,%s\n' "$(csv "${R_ENTRY[i]}")" "$(csv "${R_FULL[i]}")" \
            "$(csv "${R_STATUS[i]}")" "$(csv "${R_ITEMS[i]}")" "$(csv "${R_DETAIL[i]}")"
    done
} > "$LOG" || warn "Could not write log: $LOG"

echo
printf '%s\n' "${R_STATUS[@]}" | sort | uniq -c | awk '{printf "%-14s %s\n", $2, $1}'
echo "Log: $LOG"

for s in "${R_STATUS[@]}"; do
    case "$s" in Partial|Blocked|NotFound|NotADirectory) exit 2 ;; esac
done
exit 0
