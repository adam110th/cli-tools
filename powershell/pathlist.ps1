<#
.SYNOPSIS  Print each PATH entry on its own line, flagging missing and duplicate entries.
.PARAMETER Scope  Process (default, the PATH this session sees), User or Machine (as stored in the registry).
.EXAMPLE   .\pathlist.ps1 -Scope User
#>
param([ValidateSet('Process', 'User', 'Machine')][string]$Scope = 'Process')
# Colour only on an interactive console: not when redirected, piped, or NO_COLOR is set.
$useColor = $Host.UI.SupportsVirtualTerminal -and -not [Console]::IsOutputRedirected -and -not $env:NO_COLOR -and $MyInvocation.PipelinePosition -eq $MyInvocation.PipelineLength
function Paint([string]$Code, [string]$Text) { if ($useColor) { "$([char]27)[${Code}m$Text$([char]27)[0m" } else { $Text } }
$value = if ($Scope -eq 'Process') { $env:PATH } else { [Environment]::GetEnvironmentVariable('Path', $Scope) }
$seen = @{}; $n = 0
foreach ($p in ($value -split ';')) {
    $n++; $flag = ''
    if ([string]::IsNullOrWhiteSpace($p)) { $p = Paint '33' '(empty entry)' }
    else {
        $expanded = [Environment]::ExpandEnvironmentVariables($p)
        if (-not (Test-Path -LiteralPath $expanded -PathType Container)) { $flag += ' [missing]' }
        if ($seen.ContainsKey($expanded.TrimEnd('\').ToLower())) { $flag += ' [duplicate]' }
        $seen[$expanded.TrimEnd('\').ToLower()] = $true
    }
    '{0,3}  {1}{2}' -f $n, $p, $(if ($flag) { Paint '33' $flag } else { '' })
}
