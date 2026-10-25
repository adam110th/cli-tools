<#
.SYNOPSIS  Intune / MDM status: Entra join, enrolment, last sync, Intune Management Extension.
.PARAMETER Sync  Trigger an MDM policy sync (needs admin) and an Intune Management Extension app check-in.
.EXAMPLE   .\mdmstatus.ps1 -Sync
#>
param([switch]$Sync)
"Device: $env:COMPUTERNAME"
''; 'Join status:'
$ds = dsregcmd /status 2>$null
if ($ds) { $ds | Select-String '^\s*(AzureAdJoined|DomainJoined|WorkplaceJoined|TenantName|TenantId|DeviceId)\s*:' | ForEach-Object { '  ' + $_.Line.Trim() } }

''; 'MDM enrolments:'
$enrolments = @(Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Enrollments' -ErrorAction SilentlyContinue |
    ForEach-Object { Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction SilentlyContinue } |
    Where-Object { $_.PSObject.Properties['ProviderID'] -and $_.ProviderID -eq 'MS DM Server' })
if (-not $enrolments) { '  None - this device is not MDM (Intune) enrolled.' }
$pushTasks = @()
foreach ($e in $enrolments) {
    $guid = $e.PSChildName
    '  Enrolment: ' + $guid
    if ($e.PSObject.Properties['UPN']) { '    UPN:       ' + $e.UPN }
    $tasks = @(Get-ScheduledTask -TaskPath "\Microsoft\Windows\EnterpriseMgmt\$guid\" -ErrorAction SilentlyContinue)
    $push = $tasks | Where-Object TaskName -like 'PushLaunch*' | Select-Object -First 1
    if ($push) {
        $pushTasks += $push
        $info = $push | Get-ScheduledTaskInfo -ErrorAction SilentlyContinue
        if ($info) { '    Last sync: {0:dd/MM/yyyy HH:mm} (result 0x{1:X})' -f $info.LastRunTime, $info.LastTaskResult }
    } elseif (-not $tasks) { '    Last sync: unknown (scheduled tasks not readable; try an elevated prompt)' }
}

''; 'Intune Management Extension:'
$svc = Get-Service -Name IntuneManagementExtension -ErrorAction SilentlyContinue
if ($svc) { '  Service:  ' + $svc.Status } else { '  Service:  not installed (installs with the first Win32 app or script assignment)' }
$logDir = 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs'
if (Test-Path -LiteralPath $logDir) {
    '  Logs:     ' + $logDir
    $log = Get-Item -LiteralPath (Join-Path $logDir 'IntuneManagementExtension.log') -ErrorAction SilentlyContinue
    if ($log) { '  Last log: {0:dd/MM/yyyy HH:mm}' -f $log.LastWriteTime }
}
'  MDM diagnostics report: mdmdiagnosticstool.exe -out C:\Temp\MDMDiag'

if ($Sync) {
    ''; 'Sync:'
    foreach ($t in $pushTasks) {
        try { $t | Start-ScheduledTask -ErrorAction Stop; '  MDM policy sync started.' }
        catch { '  MDM policy sync needs an elevated prompt (or use Settings > Accounts > Access work or school > Info > Sync).' }
    }
    if ($svc) {
        try { Start-Process 'intunemanagementextension://syncapp' -ErrorAction Stop; '  Intune Management Extension app check-in requested.' }
        catch { '  Could not request an app check-in: ' + $_.Exception.Message }
    }
}
if (-not $enrolments) { exit 2 }
exit 0
