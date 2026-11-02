<#
.SYNOPSIS  Show which process is listening on (or using) a local TCP/UDP port. Run elevated to see process paths for all users.
.EXAMPLE   .\portowner.ps1 3389
#>
param([Parameter(Mandatory = $true, Position = 0)][ValidateRange(1, 65535)][int]$Port)
# Colour only on an interactive console: not when redirected, piped, or NO_COLOR is set.
$useColor = $Host.UI.SupportsVirtualTerminal -and -not [Console]::IsOutputRedirected -and -not $env:NO_COLOR -and $MyInvocation.PipelinePosition -eq $MyInvocation.PipelineLength
function Paint([string]$Code, [string]$Text) { if ($useColor) { "$([char]27)[${Code}m$Text$([char]27)[0m" } else { $Text } }
$rows = @()
$rows += Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
    Select-Object @{n='Proto';e={'TCP'}}, State, LocalAddress, LocalPort, RemoteAddress, RemotePort, OwningProcess
$rows += Get-NetUDPEndpoint -LocalPort $Port -ErrorAction SilentlyContinue |
    Select-Object @{n='Proto';e={'UDP'}}, @{n='State';e={'-'}}, LocalAddress, LocalPort, @{n='RemoteAddress';e={'*'}}, @{n='RemotePort';e={'*'}}, OwningProcess
if (-not $rows) { Paint '33' "Nothing is using local port $Port"; exit 2 }
$rows | ForEach-Object {
    $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Proto = $_.Proto; State = $_.State
        Local = "$($_.LocalAddress):$($_.LocalPort)"; Remote = "$($_.RemoteAddress):$($_.RemotePort)"
        PID = $_.OwningProcess; Process = $p.ProcessName; Path = $p.Path
    }
} | Sort-Object Proto, State, PID -Unique | Format-Table -AutoSize
