<#
.SYNOPSIS  Is a reboot pending, and why? Exit 0 = no, 2 = yes.
#>
$reasons = @()
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') {
    $reasons += 'Component Based Servicing (Windows updates or features)' }
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') {
    $reasons += 'Windows Update' }
$pfro = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction SilentlyContinue).PendingFileRenameOperations
if ($pfro) { $reasons += "Pending file rename operations ($(@($pfro | Where-Object { $_ }).Count) entries; often from installers or antivirus, may be benign)" }
$active  = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName' -ErrorAction SilentlyContinue).ComputerName
$pending = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName' -ErrorAction SilentlyContinue).ComputerName
if ($active -and $pending -and $active -ne $pending) { $reasons += "Computer rename ($active to $pending)" }

$boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$up = (Get-Date) - $boot
'Last boot: {0:dd/MM/yyyy HH:mm} ({1}d {2}h ago)' -f $boot, $up.Days, $up.Hours
if ($reasons) { $reasons | ForEach-Object { "PENDING: $_" }; 'Reboot pending.'; exit 2 }
'No reboot pending.'; exit 0
