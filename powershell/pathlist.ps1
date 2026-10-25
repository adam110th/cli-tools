<#
.SYNOPSIS  Print each PATH entry on its own line, flagging missing and duplicate entries.
.PARAMETER Scope  Process (default, the PATH this session sees), User or Machine (as stored in the registry).
.EXAMPLE   .\pathlist.ps1 -Scope User
#>
param([ValidateSet('Process', 'User', 'Machine')][string]$Scope = 'Process')
$value = if ($Scope -eq 'Process') { $env:PATH } else { [Environment]::GetEnvironmentVariable('Path', $Scope) }
$seen = @{}; $n = 0
foreach ($p in ($value -split ';')) {
    $n++; $flag = ''
    if ([string]::IsNullOrWhiteSpace($p)) { $p = '(empty entry)' }
    else {
        $expanded = [Environment]::ExpandEnvironmentVariables($p)
        if (-not (Test-Path -LiteralPath $expanded -PathType Container)) { $flag += ' [missing]' }
        if ($seen.ContainsKey($expanded.TrimEnd('\').ToLower())) { $flag += ' [duplicate]' }
        $seen[$expanded.TrimEnd('\').ToLower()] = $true
    }
    '{0,3}  {1}{2}' -f $n, $p, $flag
}
