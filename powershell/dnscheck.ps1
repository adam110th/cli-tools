<#
.SYNOPSIS  Resolve a name with the system resolver and other DNS servers side by side. Exit 2 if answers differ.
.PARAMETER Server  DNS servers to compare against (default 1.1.1.1, 8.8.8.8). Use -Server @() for the system resolver only.
                   Querying public servers sends the name being looked up to those providers.
.EXAMPLE   .\dnscheck.ps1 example.com
.EXAMPLE   .\dnscheck.ps1 example.org MX -Server 9.9.9.9
#>
param(
    [Parameter(Mandatory = $true, Position = 0)][ValidatePattern('^[A-Za-z0-9._-]+$')][string]$Name,
    [Parameter(Position = 1)][ValidateSet('A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SRV', 'SOA', 'PTR')][string]$Type = 'A',
    [ValidatePattern('^[A-Za-z0-9.:_-]+$')][string[]]$Server = @('1.1.1.1', '8.8.8.8')
)
# Colour only on an interactive console: not when redirected, piped, or NO_COLOR is set.
$useColor = $Host.UI.SupportsVirtualTerminal -and -not [Console]::IsOutputRedirected -and -not $env:NO_COLOR -and $MyInvocation.PipelinePosition -eq $MyInvocation.PipelineLength
function Paint([string]$Code, [string]$Text) { if ($useColor) { "$([char]27)[${Code}m$Text$([char]27)[0m" } else { $Text } }
function Get-Answer([string]$Srv) {
    $p = @{ Name = $Name; Type = $Type; DnsOnly = $true; QuickTimeout = $true; ErrorAction = 'Stop' }
    if ($Srv) { $p.Server = $Srv }
    try {
        $r = Resolve-DnsName @p | Where-Object { $_.Section -eq 'Answer' -and "$($_.Type)" -eq $Type }
        $vals = foreach ($x in $r) {
            switch ($Type) {
                { $_ -in 'A', 'AAAA' } { $x.IPAddress }
                'MX'    { "$($x.Preference) $($x.NameExchange)" }
                'TXT'   { '"' + ($x.Strings -join '') + '"' }
                'SRV'   { "$($x.Priority) $($x.Weight) $($x.Port) $($x.NameTarget)" }
                'SOA'   { "$($x.PrimaryServer) $($x.NameAdministrator) $($x.SerialNumber)" }
                default { $x.NameHost }
            }
        }
        if ($vals) { ($vals | Sort-Object -Unique) -join ' ' } else { '(no answer)' }
    } catch { '(error: ' + $_.Exception.Message.Split([Environment]::NewLine)[0] + ')' }
}
$results = [ordered]@{ system = Get-Answer '' }
foreach ($s in $Server) { $results[$s] = Get-Answer $s }
$results.GetEnumerator() | ForEach-Object {
    $v = if ($_.Value -like '(error*') { Paint '31' $_.Value } elseif ($_.Value -eq '(no answer)') { Paint '2' $_.Value } else { $_.Value }
    (Paint '1;36' ('{0,-16}' -f $_.Key)) + ' ' + $v
}
''
if (@($results.Values | Sort-Object -Unique).Count -gt 1) {
    Paint '33' 'MISMATCH between resolvers (normal for CDNs; otherwise check DNS filtering or split DNS)'; exit 2 }
Paint '32' 'All resolvers agree.'; exit 0
