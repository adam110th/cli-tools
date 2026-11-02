<#
.SYNOPSIS  Test whether a TCP port is reachable. Exit 0 = open, 2 = closed/filtered.
.EXAMPLE   .\portcheck.ps1 smtp.office365.com 587
#>
param(
    [Parameter(Mandatory = $true, Position = 0)][ValidatePattern('^[A-Za-z0-9.:_-]+$')][string]$HostName,
    [Parameter(Mandatory = $true, Position = 1)][ValidateRange(1, 65535)][int]$Port,
    [Parameter(Position = 2)][ValidateRange(1, 120)][int]$TimeoutSeconds = 3
)
# Colour only on an interactive console: not when redirected, piped, or NO_COLOR is set.
$useColor = $Host.UI.SupportsVirtualTerminal -and -not [Console]::IsOutputRedirected -and -not $env:NO_COLOR -and $MyInvocation.PipelinePosition -eq $MyInvocation.PipelineLength
function Paint([string]$Code, [string]$Text) { if ($useColor) { "$([char]27)[${Code}m$Text$([char]27)[0m" } else { $Text } }
$client = New-Object System.Net.Sockets.TcpClient
try {
    $task = $client.ConnectAsync($HostName, $Port)
    $ok = $task.Wait($TimeoutSeconds * 1000) -and $client.Connected
} catch { $ok = $false } finally { $client.Dispose() }
if ($ok) { (Paint '32' 'OPEN') + "    ${HostName}:$Port"; exit 0 }
(Paint '31' 'CLOSED') + "  ${HostName}:$Port (refused, filtered or no answer within ${TimeoutSeconds}s)"; exit 2
