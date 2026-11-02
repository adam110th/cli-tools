<#
.SYNOPSIS  Recent critical and error events from the System and Application logs, with a summary by source.
.EXAMPLE   .\eventerrors.ps1 -Hours 72 -Max 100 -IncludeWarnings
.EXAMPLE   .\eventerrors.ps1 -LogName 'Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin'
#>
param(
    [ValidateRange(1, 8760)][int]$Hours = 24,
    [ValidateRange(1, 10000)][int]$Max = 50,
    [switch]$IncludeWarnings,
    [string[]]$LogName = @('System', 'Application')
)
# Colour only on an interactive console: not when redirected, piped, or NO_COLOR is set.
$useColor = $Host.UI.SupportsVirtualTerminal -and -not [Console]::IsOutputRedirected -and -not $env:NO_COLOR -and $MyInvocation.PipelinePosition -eq $MyInvocation.PipelineLength
function Paint([string]$Code, [string]$Text) { if ($useColor) { "$([char]27)[${Code}m$Text$([char]27)[0m" } else { $Text } }
$levels = @(1, 2); if ($IncludeWarnings) { $levels += 3 }
$events = @(Get-WinEvent -FilterHashtable @{ LogName = $LogName; Level = $levels; StartTime = (Get-Date).AddHours(-$Hours) } `
    -MaxEvents $Max -ErrorAction SilentlyContinue)
if (-not $events) { Paint '32' "No matching events in the last $Hours hour(s)."; exit 0 }
$events | Select-Object @{n = 'Time'; e = { $_.TimeCreated.ToString('dd/MM/yyyy HH:mm:ss') } },
    @{n = 'Level'; e = { $_.LevelDisplayName } }, @{n = 'Source'; e = { $_.ProviderName } }, Id,
    @{n = 'Message'; e = { (("$($_.Message)" -split "`r?`n")[0]) } } |
    Format-Table -AutoSize -Wrap | Out-String -Width 4096
Paint '1;36' 'By source:'
$events | Group-Object ProviderName | Sort-Object Count -Descending | ForEach-Object { '  {0,4}  {1}' -f $_.Count, $_.Name }
Paint '2' "Showing the most recent $($events.Count) event(s) from the last $Hours hour(s)."
exit 0
