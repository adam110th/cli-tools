<#
.SYNOPSIS  Find duplicate files (same size, then same SHA256). Reports only; deletes nothing. Exit 2 if duplicates found.
.PARAMETER MinSizeKB         Ignore files smaller than this (default 1).
.PARAMETER IncludeCloudOnly  Also hash online-only cloud files (OneDrive, Google Drive, Dropbox placeholders).
                             Off by default because hashing them downloads every file.
.PARAMETER CsvPath           Also save the duplicate list to this CSV file.
.EXAMPLE   .\dupfiles.ps1 D:\Photos -MinSizeKB 100 -CsvPath .\dups.csv
#>
param(
    [Parameter(Position = 0)][string]$Path = '.',
    [Parameter(Position = 1)][ValidateRange(0, 100000000)][long]$MinSizeKB = 1,
    [switch]$IncludeCloudOnly,
    [string]$CsvPath
)
function Format-Size([double]$b) {
    if ($b -ge 1GB) { '{0:N1} GB' -f ($b / 1GB) } elseif ($b -ge 1MB) { '{0:N1} MB' -f ($b / 1MB) }
    elseif ($b -ge 1KB) { '{0:N1} KB' -f ($b / 1KB) } else { "$b B" }
}
if (-not (Test-Path -LiteralPath $Path -PathType Container)) { Write-Error "Not a directory: $Path"; exit 1 }
$cloudMask = 0x00400000 -bor 0x00040000 -bor 0x00001000   # RecallOnDataAccess, RecallOnOpen, Offline
$skipped = 0
$candidates = Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -gt 0 -and $_.Length -ge ($MinSizeKB * 1KB) } |
    Where-Object {
        if (-not $IncludeCloudOnly -and ([int64]$_.Attributes -band $cloudMask)) { $script:skipped++; $false } else { $true }
    } |
    Group-Object Length | Where-Object Count -gt 1 | ForEach-Object { $_.Group }

$i = 0; $n = @($candidates).Count
$hashed = foreach ($f in $candidates) {
    $i++; Write-Progress -Activity 'Hashing candidates' -Status $f.FullName -PercentComplete (100 * $i / [math]::Max($n, 1))
    $h = Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue
    if ($h) { [pscustomobject]@{ Hash = $h.Hash; Length = $f.Length; Modified = $f.LastWriteTime; Path = $f.FullName } }
}
Write-Progress -Activity 'Hashing candidates' -Completed
$groups = @($hashed | Group-Object Hash | Where-Object Count -gt 1 | Sort-Object { $_.Group[0].Length * ($_.Count - 1) } -Descending)

if ($skipped) { "Skipped $skipped online-only cloud file(s); use -IncludeCloudOnly to include them (downloads them)." }
if (-not $groups) { 'No duplicates found.'; exit 0 }
$total = 0; $g = 0; $rows = @()
foreach ($grp in $groups) {
    $g++; $size = $grp.Group[0].Length; $wasted = $size * ($grp.Count - 1); $total += $wasted
    ''
    '{0} copies x {1}  (wasted {2})  sha256 {3}' -f $grp.Count, (Format-Size $size), (Format-Size $wasted), $grp.Name.Substring(0, 12).ToLower()
    $grp.Group | Sort-Object Modified | ForEach-Object {
        '  {0:dd/MM/yyyy}  {1}' -f $_.Modified, $_.Path
        $rows += [pscustomobject]@{ Group = $g; Hash = $_.Hash; Bytes = $_.Length; Modified = $_.Modified.ToString('dd/MM/yyyy HH:mm'); Path = $_.Path }
    }
}
''
'{0} duplicate group(s), {1} reclaimable.' -f $groups.Count, (Format-Size $total)
if ($CsvPath) { $rows | Export-Csv -LiteralPath $CsvPath -NoTypeInformation; "Saved: $CsvPath" }
exit 2
