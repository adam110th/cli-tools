<#
.SYNOPSIS  Test whether a TCP port is reachable. Exit 0 = open, 2 = closed/filtered.
.EXAMPLE   .\portcheck.ps1 smtp.office365.com 587
#>
param(
    [Parameter(Mandatory = $true, Position = 0)][ValidatePattern('^[A-Za-z0-9.:_-]+$')][string]$HostName,
    [Parameter(Mandatory = $true, Position = 1)][ValidateRange(1, 65535)][int]$Port,
    [Parameter(Position = 2)][ValidateRange(1, 120)][int]$TimeoutSeconds = 3
)
$client = New-Object System.Net.Sockets.TcpClient
try {
    $task = $client.ConnectAsync($HostName, $Port)
    $ok = $task.Wait($TimeoutSeconds * 1000) -and $client.Connected
} catch { $ok = $false } finally { $client.Dispose() }
if ($ok) { "OPEN    ${HostName}:$Port"; exit 0 }
"CLOSED  ${HostName}:$Port (refused, filtered or no answer within ${TimeoutSeconds}s)"; exit 2
