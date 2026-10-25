#!/usr/bin/env bash
# dupfiles - find duplicate files (same size, then same SHA256). Reports only; deletes nothing.
# Usage: dupfiles.sh [PATH] [MIN_SIZE_KB]   (defaults: current directory, 1)
# Exit: 0 no duplicates, 2 duplicates found. File names containing the 0x1F control character are not supported.
set -u
p="${1:-.}" minkb="${2:-1}"
[[ -d "$p" ]] || { echo "Not a directory: $p" >&2; exit 1; }
[[ "$minkb" =~ ^[0-9]+$ ]] || { echo "MIN_SIZE_KB must be a number" >&2; exit 1; }
minbytes=$((minkb * 1024))

declare -A bysize=()
while IFS= read -r -d '' size && IFS= read -r -d '' f; do
    [[ $size -ge $minbytes && $size -gt 0 ]] || continue
    bysize[$size]+="$f"$'\x1f'
done < <(find "$p" -xdev -type f -printf '%s\0%p\0' 2>/dev/null)

declare -A byhash=() hsize=()
for size in "${!bysize[@]}"; do
    IFS=$'\x1f' read -r -a files <<< "${bysize[$size]%$'\x1f'}"
    [[ ${#files[@]} -gt 1 ]] || continue
    for f in "${files[@]}"; do
        h="$(sha256sum -- "$f" 2>/dev/null | cut -d' ' -f1)" || continue
        [[ -n "$h" ]] || continue
        byhash[$h]+="$f"$'\x1f'; hsize[$h]=$size
    done
done

groups=0 wasted=0
for h in "${!byhash[@]}"; do
    IFS=$'\x1f' read -r -a files <<< "${byhash[$h]%$'\x1f'}"
    [[ ${#files[@]} -gt 1 ]] || continue
    groups=$((groups + 1)); w=$(( hsize[$h] * (${#files[@]} - 1) )); wasted=$((wasted + w))
    echo "${#files[@]} copies x $(numfmt --to=iec --suffix=B "${hsize[$h]}")  (wasted $(numfmt --to=iec --suffix=B "$w"))  sha256 ${h:0:12}"
    printf '  %s\n' "${files[@]}"
done
echo
if [[ $groups -eq 0 ]]; then echo "No duplicates found."; exit 0; fi
echo "$groups duplicate group(s), $(numfmt --to=iec --suffix=B "$wasted") reclaimable."; exit 2
