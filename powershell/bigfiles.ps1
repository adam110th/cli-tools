<#
.SYNOPSIS  Largest files under a directory.
.EXAMPLE   .\bigfiles.ps1 D:\ -Top 50
#>
param([Parameter(Position = 0)][string]$Path = '.', [Parameter(Position = 1)][ValidateRange(1, 10000)][int]$Top = 20)
function Format-Size([double]$b) {
    if ($b -ge 1TB) { '{0:N1} TB' -f ($b / 1TB) } elseif ($b -ge 1GB) { '{0:N1} GB' -f ($b / 1GB) }
    elseif ($b -ge 1MB) { '{0:N1} MB' -f ($b / 1MB) } elseif ($b -ge 1KB) { '{0:N1} KB' -f ($b / 1KB) } else { "$b B" }
}
if (-not (Test-Path -LiteralPath $Path -PathType Container)) { Write-Error "Not a directory: $Path"; exit 1 }
Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
    Sort-Object Length -Descending | Select-Object -First $Top |
    Format-Table @{n='Size';e={Format-Size $_.Length};a='right'}, @{n='Modified';e={$_.LastWriteTime.ToString('dd/MM/yyyy')}}, FullName -AutoSize
