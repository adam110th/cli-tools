<#
.SYNOPSIS  Largest immediate subfolders of a directory, with total size and file count.
.EXAMPLE   .\dirsize.ps1 C:\Users -Top 10
#>
param([Parameter(Position = 0)][string]$Path = '.', [Parameter(Position = 1)][ValidateRange(1, 1000)][int]$Top = 15)
function Format-Size([double]$b) {
    if ($b -ge 1TB) { '{0:N1} TB' -f ($b / 1TB) } elseif ($b -ge 1GB) { '{0:N1} GB' -f ($b / 1GB) }
    elseif ($b -ge 1MB) { '{0:N1} MB' -f ($b / 1MB) } elseif ($b -ge 1KB) { '{0:N1} KB' -f ($b / 1KB) } else { "$b B" }
}
if (-not (Test-Path -LiteralPath $Path -PathType Container)) { Write-Error "Not a directory: $Path"; exit 1 }
Get-ChildItem -LiteralPath $Path -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Progress -Activity 'Measuring' -Status $_.FullName
    $m = Get-ChildItem -LiteralPath $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum
    [pscustomobject]@{ Bytes = [double]$m.Sum; Files = $m.Count; Folder = $_.FullName }
} | Sort-Object Bytes -Descending | Select-Object -First $Top |
    Format-Table @{n='Size';e={Format-Size $_.Bytes};a='right'}, Files, Folder -AutoSize
