<#
.SYNOPSIS  Intune / MDM status: Entra join, enrolment, last sync, Intune Management Extension.
.PARAMETER Sync  Trigger an MDM policy sync (needs admin) and an Intune Management Extension app check-in.
.EXAMPLE   .\mdmstatus.ps1 -Sync
#>
param([switch]$Sync)
# Colour only on an interactive console: not when redirected, piped, or NO_COLOR is set.
$useColor = $Host.UI.SupportsVirtualTerminal -and -not [Console]::IsOutputRedirected -and -not $env:NO_COLOR -and $MyInvocation.PipelinePosition -eq $MyInvocation.PipelineLength
function Paint([string]$Code, [string]$Text) { if ($useColor) { "$([char]27)[${Code}m$Text$([char]27)[0m" } else { $Text } }
# Short titles for common scheduled-task / MDM sync results; others come from the system message tables.
$resultTitles = @{
    '0x0' = 'Success'; '0x1' = 'Incorrect function'; '0x41300' = 'Ready to run'; '0x41301' = 'Currently running'
    '0x41302' = 'Task disabled'; '0x41303' = 'Has not run yet'; '0x41306' = 'Terminated by user'
    '0x8004130F' = 'No account info stored'; '0x800710E0' = 'Request refused by operator or administrator'
    '0x80072EE2' = 'Network timeout'; '0x80072EE7' = 'Server name could not be resolved'; '0x80072EFD' = 'Cannot connect to server'
    '0x80190190' = 'HTTP 400 Bad request'; '0x80190191' = 'HTTP 401 Unauthorized'; '0x80190193' = 'HTTP 403 Forbidden'
    '0x80180002' = 'MDM server failed to authenticate the user'; '0x82AC0204' = 'DM session aborted: device roaming'
}
function Get-ResultTitle([int64]$Code) {
    $hex = '0x{0:X}' -f $Code
    if ($resultTitles.ContainsKey($hex)) { return $resultTitles[$hex] }
    $t = ''
    if ([math]::Floor($Code / 65536) -eq 0x8007) {   # HRESULT wrapping a Win32 error
        $t = ([ComponentModel.Win32Exception][int]($Code % 65536)).Message; if ($t -match '^Unknown error') { $t = '' } }
    if (-not $t) { $t = "$(certutil.exe -error $hex 2>$null | Select-Object -Skip 1 -First 1)" -replace '^[^:]*:\s*', '' }
    if (-not $t -or $t -match [regex]::Escape($hex)) { return 'unknown' }
    $t = ($t -split '(?<=\.)\s')[0].TrimEnd('.')
    if ($t.Length -gt 60) { $t = $t.Substring(0, 57) + '...' }
    $t
}
"Device: $env:COMPUTERNAME"
''; Paint '1;36' 'Join status:'
$ds = dsregcmd /status 2>$null
if ($ds) { $ds | Select-String '^\s*(AzureAdJoined|DomainJoined|WorkplaceJoined|TenantName|TenantId|DeviceId)\s*:' | ForEach-Object { '  ' + $_.Line.Trim() } }

''; Paint '1;36' 'MDM enrolments:'
$enrolments = @(Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Enrollments' -ErrorAction SilentlyContinue |
    ForEach-Object { Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction SilentlyContinue } |
    Where-Object { $_.PSObject.Properties['ProviderID'] -and $_.ProviderID -eq 'MS DM Server' })
if (-not $enrolments) { Paint '33' '  None - this device is not MDM (Intune) enrolled.' }
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
        if ($info) {
            $hex = '0x{0:X}' -f $info.LastTaskResult
            $code = if ($hex -eq '0x0') { '32' } elseif ($hex -in '0x41300', '0x41301', '0x41303') { '33' } else { '31' }
            '    Last sync: {0:dd/MM/yyyy HH:mm} (result {1} - {2})' -f $info.LastRunTime, $hex, (Paint $code (Get-ResultTitle $info.LastTaskResult))
        }
    } elseif (-not $tasks) { Paint '33' '    Last sync: unknown (scheduled tasks not readable; try an elevated prompt)' }
}

''; Paint '1;36' 'Intune Management Extension:'
$svc = Get-Service -Name IntuneManagementExtension -ErrorAction SilentlyContinue
if ($svc) { '  Service:  ' + (Paint $(if ("$($svc.Status)" -eq 'Running') { '32' } else { '33' }) "$($svc.Status)") }
else { '  Service:  ' + (Paint '33' 'not installed') + ' (installs with the first Win32 app or script assignment)' }
$logDir = 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs'
if (Test-Path -LiteralPath $logDir) {
    '  Logs:     ' + $logDir
    $log = Get-Item -LiteralPath (Join-Path $logDir 'IntuneManagementExtension.log') -ErrorAction SilentlyContinue
    if ($log) { '  Last log: {0:dd/MM/yyyy HH:mm}' -f $log.LastWriteTime }
}
Paint '2' '  MDM diagnostics report: mdmdiagnosticstool.exe -out C:\Temp\MDMDiag'

if ($Sync) {
    ''; Paint '1;36' 'Sync:'
    foreach ($t in $pushTasks) {
        try { $t | Start-ScheduledTask -ErrorAction Stop; Paint '32' '  MDM policy sync started.' }
        catch { Paint '33' '  MDM policy sync needs an elevated prompt (or use Settings > Accounts > Access work or school > Info > Sync).' }
    }
    if ($svc) {
        try { Start-Process 'intunemanagementextension://syncapp' -ErrorAction Stop; Paint '32' '  Intune Management Extension app check-in requested.' }
        catch { Paint '31' ('  Could not request an app check-in: ' + $_.Exception.Message) }
    }
}
if (-not $enrolments) { exit 2 }
exit 0
