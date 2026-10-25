<#
.SYNOPSIS  Addresses, default gateway and DNS servers per connected adapter; public IP only with -Public.
.PARAMETER Public  Also look up the public IP via https://api.ipify.org (sends one request to an external service).
#>
param([switch]$Public)
"Host: $env:COMPUTERNAME"
Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq 'Up' } | ForEach-Object {
    ''
    "$($_.InterfaceAlias)  [$($_.NetAdapter.InterfaceDescription)]"
    '  IPv4:    ' + (($_.IPv4Address | ForEach-Object { "$($_.IPAddress)/$($_.PrefixLength)" }) -join ', ')
    if ($_.IPv6Address) { '  IPv6:    ' + (($_.IPv6Address.IPAddress) -join ', ') }
    '  Gateway: ' + (($_.IPv4DefaultGateway.NextHop) -join ', ')
    '  DNS:     ' + (($_.DNSServer | Where-Object AddressFamily -eq 2).ServerAddresses -join ', ')
    '  MAC:     ' + $_.NetAdapter.MacAddress
}
if ($Public) {
    ''
    try   { 'Public IP: ' + (Invoke-RestMethod -Uri 'https://api.ipify.org' -TimeoutSec 5) }
    catch { 'Public IP: (lookup failed)' }
}
