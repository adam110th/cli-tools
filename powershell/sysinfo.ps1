<#
.SYNOPSIS  One-screen summary of host, OS, hardware, serial, Entra/domain join, memory and disks.
#>
# Colour only on an interactive console: not when redirected, piped, or NO_COLOR is set.
$useColor = $Host.UI.SupportsVirtualTerminal -and -not [Console]::IsOutputRedirected -and -not $env:NO_COLOR -and $MyInvocation.PipelinePosition -eq $MyInvocation.PipelineLength
function Paint([string]$Code, [string]$Text) { if ($useColor) { "$([char]27)[${Code}m$Text$([char]27)[0m" } else { $Text } }
# OEM placeholder strings seen on custom-built PCs; treated as empty.
$placeholders = '', '0', 'none', 'oem', 'o.e.m.', 'default string', 'not applicable', '0123456789', 'system manufacturer', 'system product name',
    'system serial number', 'system version', 'to be filled by o.e.m.', 'chassis serial number', 'base board serial number'
function Get-Real($s) { $s = "$s".Trim(); if ($placeholders -contains $s) { '' } else { $s } }
$os   = Get-CimInstance Win32_OperatingSystem
$cs   = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
$cpu  = Get-CimInstance Win32_Processor | Select-Object -First 1
$bb   = Get-CimInstance Win32_BaseBoard | Select-Object -First 1
$model = (@((Get-Real $cs.Manufacturer), (Get-Real $cs.Model)) -ne '') -join ' '
if (-not (Get-Real $cs.Model)) { $b = (@((Get-Real $bb.Manufacturer), (Get-Real $bb.Product)) -ne '') -join ' '; if ($b) { $model = "$b (motherboard)" } }
$serial = Get-Real $bios.SerialNumber
if (-not $serial) { $b = Get-Real $bb.SerialNumber; $serial = if ($b) { "$b (motherboard)" } else { '' } }
$up   = (Get-Date) - $os.LastBootUpTime
$rows = [ordered]@{
    Host   = $env:COMPUTERNAME
    User   = "$env:USERDOMAIN\$env:USERNAME"
    OS     = "$($os.Caption) $($os.Version) build $($os.BuildNumber) ($($os.OSArchitecture))"
    Model  = $(if ($model) { $model } else { 'n/a' })
    Serial = $(if ($serial) { $serial } else { 'n/a' })
    Uptime = '{0}d {1}h {2}m (booted {3:dd/MM/yyyy HH:mm})' -f $up.Days, $up.Hours, $up.Minutes, $os.LastBootUpTime
    CPU    = "$($cpu.Name.Trim()) ($($cpu.NumberOfCores) cores / $($cpu.NumberOfLogicalProcessors) threads)"
    Memory = '{0:N1} GB free of {1:N1} GB' -f ($os.FreePhysicalMemory / 1MB), ($os.TotalVisibleMemorySize / 1MB)
}
$rows.GetEnumerator() | ForEach-Object { (Paint '1;36' ('{0,-8}' -f $_.Key)) + ' ' + $_.Value }

''; Paint '1;36' 'Join status:'
$ds = dsregcmd /status 2>$null
if ($ds) { $ds | Select-String 'AzureAdJoined|DomainJoined|WorkplaceJoined|TenantName' | ForEach-Object { '  ' + $_.Line.Trim() } }
else { Paint '2' '  dsregcmd not available' }

''; Paint '1;36' 'Disks:'
Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object {
    $used = 100 - 100 * $_.FreeSpace / [math]::Max($_.Size, 1)
    $pct = '({0:N0}% used)' -f $used
    '  {0}  {1,8:N1} GB free of {2,8:N1} GB  {3}' -f $_.DeviceID, ($_.FreeSpace / 1GB), ($_.Size / 1GB), $(if ($used -ge 90) { Paint '31' $pct } elseif ($used -ge 80) { Paint '33' $pct } else { $pct })
}
