<#
.SYNOPSIS  List every executable on PATH matching each name, in PATH order (first = the one that runs).
.EXAMPLE   .\whichall.ps1 python git
#>
param([Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)][string[]]$Name)
$rc = 0
foreach ($n in $Name) {
    $hits = @(Get-Command -Name $n -All -CommandType Application -ErrorAction SilentlyContinue)
    if ($hits.Count) { $hits | ForEach-Object { $_.Source } }
    else { Write-Warning "${n}: not found on PATH"; $rc = 1 }
}
exit $rc
