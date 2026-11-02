<#
.SYNOPSIS  TLS certificate details and expiry for a host.
           Exit 0 = valid and not expiring soon, 2 = expired / expiring within WarnDays / untrusted, 1 = error.
.EXAMPLE   .\certcheck.ps1 example.com
.EXAMPLE   .\certcheck.ps1 mail.example.com 993 -WarnDays 60
#>
param(
    [Parameter(Mandatory = $true, Position = 0)][ValidatePattern('^[A-Za-z0-9._-]+$')][string]$HostName,
    [Parameter(Position = 1)][ValidateRange(1, 65535)][int]$Port = 443,
    [ValidateRange(0, 3650)][int]$WarnDays = 30
)
# Colour only on an interactive console: not when redirected, piped, or NO_COLOR is set.
$useColor = $Host.UI.SupportsVirtualTerminal -and -not [Console]::IsOutputRedirected -and -not $env:NO_COLOR -and $MyInvocation.PipelinePosition -eq $MyInvocation.PipelineLength
function Paint([string]$Code, [string]$Text) { if ($useColor) { "$([char]27)[${Code}m$Text$([char]27)[0m" } else { $Text } }
$state = @{ Errors = 'Unknown' }
$callback = [System.Net.Security.RemoteCertificateValidationCallback] { param($s, $c, $ch, $e) $state.Errors = $e; $true }
$tcp = New-Object System.Net.Sockets.TcpClient
try {
    $iar = $tcp.BeginConnect($HostName, $Port, $null, $null)
    if (-not $iar.AsyncWaitHandle.WaitOne(10000)) { throw "No answer from ${HostName}:$Port within 10 s" }
    $tcp.EndConnect($iar)
    $ssl = New-Object System.Net.Security.SslStream($tcp.GetStream(), $false, $callback)
    $ssl.AuthenticateAsClient($HostName)
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($ssl.RemoteCertificate)
    $ssl.Dispose()
} catch {
    $m = $_.Exception.Message; if ($_.Exception.InnerException) { $m = $_.Exception.InnerException.Message }
    Paint '31' "ERROR: $m"; exit 1
} finally { $tcp.Dispose() }

$days = [int][math]::Floor(($cert.NotAfter - (Get-Date)).TotalDays)
$san = ($cert.Extensions | Where-Object { $_.Oid.Value -eq '2.5.29.17' } | ForEach-Object { $_.Format($false) }) -join ', '
$rows = [ordered]@{
    Host = "${HostName}:$Port"; Subject = $cert.Subject; Issuer = $cert.Issuer
    'Valid from' = $cert.NotBefore.ToString('dd/MM/yyyy HH:mm'); Expires = $cert.NotAfter.ToString('dd/MM/yyyy HH:mm')
    'Days left' = $days; Names = $(if ($san) { $san } else { 'n/a' }); Chain = $(if ("$($state.Errors)" -eq 'None') { 'trusted' } else { "$($state.Errors)" })
    Thumbprint = $cert.Thumbprint
}
$rows.GetEnumerator() | ForEach-Object {
    $v = "$($_.Value)"
    if ($_.Key -eq 'Days left') { $v = Paint $(if ($days -lt 0) { '31' } elseif ($days -lt $WarnDays) { '33' } else { '32' }) $v }
    elseif ($_.Key -eq 'Chain') { $v = Paint $(if ($v -eq 'trusted') { '32' } else { '31' }) $v }
    (Paint '1;36' ('{0,-11}' -f $_.Key)) + ' ' + $v
}
$rc = 0
if ($days -lt 0) { Paint '31' 'EXPIRED'; $rc = 2 } elseif ($days -lt $WarnDays) { Paint '33' "WARNING: expires within $WarnDays days"; $rc = 2 }
if ("$($state.Errors)" -ne 'None') { Paint '33' 'WARNING: certificate not trusted by this machine or name mismatch'; $rc = 2 }
exit $rc
