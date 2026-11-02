<#
.SYNOPSIS  Is a reboot pending, and why? Exit 0 = no, 2 = yes.
#>
# Colour only on an interactive console: not when redirected, piped, or NO_COLOR is set.
$useColor = $Host.UI.SupportsVirtualTerminal -and -not [Console]::IsOutputRedirected -and -not $env:NO_COLOR -and $MyInvocation.PipelinePosition -eq $MyInvocation.PipelineLength
function Paint([string]$Code, [string]$Text) { if ($useColor) { "$([char]27)[${Code}m$Text$([char]27)[0m" } else { $Text } }
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
if ($reasons) { $reasons | ForEach-Object { (Paint '33' 'PENDING:') + " $_" }; Paint '33' 'Reboot pending.'; exit 2 }
Paint '32' 'No reboot pending.'; exit 0
