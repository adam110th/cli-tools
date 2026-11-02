<#
.SYNOPSIS  Addresses, default gateway and DNS servers per connected adapter; public IP only with -Public.
.PARAMETER Public  Also look up the public IP via https://api.ipify.org (sends one request to an external service).
#>
param([switch]$Public)
# Colour only on an interactive console: not when redirected, piped, or NO_COLOR is set.
$useColor = $Host.UI.SupportsVirtualTerminal -and -not [Console]::IsOutputRedirected -and -not $env:NO_COLOR -and $MyInvocation.PipelinePosition -eq $MyInvocation.PipelineLength
function Paint([string]$Code, [string]$Text) { if ($useColor) { "$([char]27)[${Code}m$Text$([char]27)[0m" } else { $Text } }
"Host: $env:COMPUTERNAME"
Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq 'Up' } | ForEach-Object {
    ''
    (Paint '1;36' $_.InterfaceAlias) + '  ' + (Paint '2' "[$($_.NetAdapter.InterfaceDescription)]")
    '  IPv4:    ' + (($_.IPv4Address | ForEach-Object { "$($_.IPAddress)/$($_.PrefixLength)" }) -join ', ')
    if ($_.IPv6Address) { '  IPv6:    ' + (($_.IPv6Address.IPAddress) -join ', ') }
    '  Gateway: ' + (($_.IPv4DefaultGateway.NextHop) -join ', ')
    '  DNS:     ' + (($_.DNSServer | Where-Object AddressFamily -eq 2).ServerAddresses -join ', ')
    '  MAC:     ' + $_.NetAdapter.MacAddress
}
if ($Public) {
    ''
    try   { 'Public IP: ' + (Invoke-RestMethod -Uri 'https://api.ipify.org' -TimeoutSec 5) }
    catch { 'Public IP: ' + (Paint '31' '(lookup failed)') }
}
