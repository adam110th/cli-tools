<#
.SYNOPSIS  Find files/folders that break Windows or cloud sync: long paths, invalid characters,
           trailing spaces/dots, reserved names (CON, NUL, COM1...), names over 255 characters.
.PARAMETER MaxPath  Path length to flag (default 260, the Windows MAX_PATH limit).
.PARAMETER CsvPath  Also save the findings to this CSV file.
.EXAMPLE   .\syncsafe.ps1 'X:\GoogleDrive\Shared\Projects' -CsvPath .\syncsafe.csv
#>
param(
    [Parameter(Position = 0)][string]$Path = '.',
    [ValidateRange(100, 32767)][int]$MaxPath = 260,
    [string]$CsvPath
)
if (-not (Test-Path -LiteralPath $Path -PathType Container)) { Write-Error "Not a directory: $Path"; exit 1 }
$root = (Resolve-Path -LiteralPath $Path).ProviderPath.TrimEnd('\')
$long = if ($root.StartsWith('\\')) { '\\?\UNC\' + $root.Substring(2) } else { '\\?\' + $root }
$reserved = '^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\..*)?$'
$badChars = '[<>:"|?*\\/\x00-\x1F]'

$found = Get-ChildItem -LiteralPath $long -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $full = $_.FullName -replace '^\\\\\?\\UNC\\', '\\' -replace '^\\\\\?\\', ''
    $name = $_.Name
    $issues = @()
    if ($full.Length -ge $MaxPath) { $issues += 'LongPath' }
    if ($name.Length -gt 255)      { $issues += 'NameTooLong' }
    if ($name -match $badChars)    { $issues += 'InvalidChar' }
    if ($name -match '[ .]$')      { $issues += 'TrailingSpaceOrDot' }
    if ($name -match '^ ')         { $issues += 'LeadingSpace' }
    if ($name -match $reserved)    { $issues += 'ReservedName' }
    if ($issues) { [pscustomobject]@{ Issue = $issues -join ','; Length = $full.Length; Path = $full } }
}
if (-not $found) { "No sync problems found under $root"; exit 0 }
$found | Sort-Object Issue, Path | Format-Table -AutoSize -Wrap | Out-String -Width 4096
$found | Group-Object { ($_.Issue -split ',')[0] } | ForEach-Object { '{0,-20} {1}' -f $_.Name, $_.Count }
if ($CsvPath) { $found | Export-Csv -LiteralPath $CsvPath -NoTypeInformation; "Saved: $CsvPath" }
"$(@($found).Count) item(s) with problems"
exit 2
