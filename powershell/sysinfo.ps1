<#
.SYNOPSIS  One-screen summary of host, OS, hardware, serial, Entra/domain join, memory and disks.
#>
$os   = Get-CimInstance Win32_OperatingSystem
$cs   = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
$cpu  = Get-CimInstance Win32_Processor | Select-Object -First 1
$up   = (Get-Date) - $os.LastBootUpTime
$rows = [ordered]@{
    Host   = $env:COMPUTERNAME
    User   = "$env:USERDOMAIN\$env:USERNAME"
    OS     = "$($os.Caption) $($os.Version) build $($os.BuildNumber) ($($os.OSArchitecture))"
    Model  = "$($cs.Manufacturer) $($cs.Model)"
    Serial = $bios.SerialNumber
    Uptime = '{0}d {1}h {2}m (booted {3:dd/MM/yyyy HH:mm})' -f $up.Days, $up.Hours, $up.Minutes, $os.LastBootUpTime
    CPU    = "$($cpu.Name.Trim()) ($($cpu.NumberOfCores) cores / $($cpu.NumberOfLogicalProcessors) threads)"
    Memory = '{0:N1} GB free of {1:N1} GB' -f ($os.FreePhysicalMemory / 1MB), ($os.TotalVisibleMemorySize / 1MB)
}
$rows.GetEnumerator() | ForEach-Object { '{0,-8} {1}' -f $_.Key, $_.Value }

''; 'Join status:'
$ds = dsregcmd /status 2>$null
if ($ds) { $ds | Select-String 'AzureAdJoined|DomainJoined|WorkplaceJoined|TenantName' | ForEach-Object { '  ' + $_.Line.Trim() } }
else { '  dsregcmd not available' }

''; 'Disks:'
Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object {
    '  {0}  {1,8:N1} GB free of {2,8:N1} GB  ({3:N0}% used)' -f $_.DeviceID, ($_.FreeSpace / 1GB), ($_.Size / 1GB), (100 - 100 * $_.FreeSpace / [math]::Max($_.Size, 1))
}
