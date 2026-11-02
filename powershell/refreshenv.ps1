<#
.SYNOPSIS  Reload environment variables (including PATH) from the registry into the CURRENT PowerShell session,
           so newly installed tools work without opening a new window.
.DESCRIPTION
    Must be dot-sourced:   . refreshenv.ps1
    PATH is rebuilt as Machine PATH followed by User PATH. Entries added only to this session are dropped.
    PSModulePath is left alone.
#>
if ($MyInvocation.InvocationName -ne '.') {
    Write-Warning 'Run this dot-sourced:  . refreshenv.ps1   (otherwise the changes vanish when the script ends)'
    return
}
# Colour only on an interactive console: not when redirected, piped, or NO_COLOR is set. Names prefixed and removed at the end.
$_reColor = $Host.UI.SupportsVirtualTerminal -and -not [Console]::IsOutputRedirected -and -not $env:NO_COLOR -and $MyInvocation.PipelinePosition -eq $MyInvocation.PipelineLength
function _rePaint([string]$Code, [string]$Text) { if ($_reColor) { "$([char]27)[${Code}m$Text$([char]27)[0m" } else { $Text } }
$_reOld = $env:PATH -split ';' | Where-Object { $_ }
foreach ($_reScope in 'Machine', 'User') {
    $_reVars = [Environment]::GetEnvironmentVariables($_reScope)
    foreach ($_reKey in $_reVars.Keys) {
        if ($_reKey -in 'Path', 'PSModulePath', 'USERNAME') { continue }
        Set-Item -Path "Env:$_reKey" -Value ([Environment]::ExpandEnvironmentVariables($_reVars[$_reKey]))
    }
}
$_reNew = foreach ($_reScope in 'Machine', 'User') {
    $v = [Environment]::GetEnvironmentVariable('Path', $_reScope)
    if ($v) { [Environment]::ExpandEnvironmentVariables($v) -split ';' | Where-Object { $_ } }
}
$_reSeen = @{}
$env:PATH = ($_reNew | Where-Object { $k = $_.TrimEnd('\').ToLower(); if ($_reSeen.ContainsKey($k)) { $false } else { $_reSeen[$k] = 1; $true } }) -join ';'
_rePaint '32' 'Environment refreshed.'
Compare-Object @($_reOld) @($env:PATH -split ';') | ForEach-Object {
    if ($_.SideIndicator -eq '=>') { '  ' + (_rePaint '32' 'added:') + '   ' + $_.InputObject } else { '  ' + (_rePaint '33' 'removed:') + ' ' + $_.InputObject }
}
Remove-Variable _reOld, _reNew, _reSeen, _reScope, _reVars, _reKey, _reColor -ErrorAction SilentlyContinue
Remove-Item Function:\_rePaint -ErrorAction SilentlyContinue
