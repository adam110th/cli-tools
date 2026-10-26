<#
.SYNOPSIS
    Install (or uninstall) cli-tools on Windows and make sure the install folder is on PATH.

.DESCRIPTION
    Locations:
      User scope     %LOCALAPPDATA%\Programs\cli-tools   (Windows per-user program folder, FOLDERID_UserProgramFiles)
      Machine scope  %ProgramFiles%\cli-tools            (admin-only write, so it is safe to put on the machine PATH)

    -Scope Auto (default) picks Machine when running as SYSTEM (for example an Intune deployment)
    and User otherwise. Machine scope needs an elevated prompt.

    The .ps1 and .cmd tools are copied into one flat folder (the cmd wrappers find their .ps1 there),
    with README.md and docs\. Downloaded files are unblocked. If the folder is not on the User (or Machine)
    PATH it is added, the current session is updated, and running programs are notified so new windows
    pick it up. A VERSION.txt file is written for Intune detection rules.

.PARAMETER Scope      Auto (default), User or Machine.
.PARAMETER Uninstall  Remove the install folder and its PATH entry.

.EXAMPLE  .\install.ps1
.EXAMPLE  .\install.ps1 -Scope Machine
.EXAMPLE  .\install.ps1 -Uninstall
#>
[CmdletBinding()]
param(
    [ValidateSet('Auto', 'User', 'Machine')][string]$Scope = 'Auto',
    [switch]$Uninstall
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Version = '1.1.1'
$AppName = 'cli-tools'

# ---------- scope and destination ----------
$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$isSystem  = $identity.User.Value -eq 'S-1-5-18'
$isAdmin   = (New-Object Security.Principal.WindowsPrincipal $identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($Scope -eq 'Auto') { $Scope = if ($isSystem) { 'Machine' } else { 'User' } }
if ($Scope -eq 'Machine' -and -not $isAdmin) { Write-Error 'Machine scope needs an elevated prompt (Run as administrator), or use -Scope User.'; exit 1 }
if ($Scope -eq 'User' -and $isSystem) { Write-Error 'Running as SYSTEM: use -Scope Machine (User scope would install into the SYSTEM profile).'; exit 1 }

# ProgramW6432 is the 64-bit Program Files even in a 32-bit PowerShell (the Intune Management Extension
# launches install commands from a 32-bit process, where %ProgramFiles% is "Program Files (x86)")
$programFiles = if ($env:ProgramW6432) { $env:ProgramW6432 } else { $env:ProgramFiles }
$dest = if ($Scope -eq 'Machine') { Join-Path $programFiles $AppName } else { Join-Path $env:LOCALAPPDATA "Programs\$AppName" }
$regKey = if ($Scope -eq 'Machine') { 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' } else { 'HKCU:\Environment' }

# ---------- PATH helpers (read/write raw so %VARS% in PATH are preserved as REG_EXPAND_SZ) ----------
function Get-RawPath {
    $k = Get-Item -LiteralPath $regKey
    return [string]$k.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
}
function Set-RawPath([string]$Value) {
    Set-ItemProperty -LiteralPath $regKey -Name Path -Value $Value -Type ExpandString
    # Tell Explorer and other running programs that the environment changed (new windows pick it up)
    if (-not ('CliTools.NativeMethods' -as [type])) {
        Add-Type -Namespace CliTools -Name NativeMethods -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
'@
    }
    $r = [UIntPtr]::Zero
    [void][CliTools.NativeMethods]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$r)
}
function Test-SameDir([string]$a, [string]$b) {
    $x = [Environment]::ExpandEnvironmentVariables($a).TrimEnd('\')
    $y = [Environment]::ExpandEnvironmentVariables($b).TrimEnd('\')
    return [string]::Equals($x, $y, [StringComparison]::OrdinalIgnoreCase)
}

# ---------- uninstall ----------
if ($Uninstall) {
    $entries = @((Get-RawPath) -split ';' | Where-Object { $_ })
    $kept = @($entries | Where-Object { -not (Test-SameDir $_ $dest) })
    if ($kept.Count -ne $entries.Count) { Set-RawPath ($kept -join ';'); "Removed from $Scope PATH: $dest" }
    if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force; "Removed: $dest" }
    else { "Not installed at: $dest" }
    $env:PATH = (@($env:PATH -split ';' | Where-Object { $_ -and -not (Test-SameDir $_ $dest) })) -join ';'
    exit 0
}

# ---------- find the source files (repo layout or flat) ----------
$src = $PSScriptRoot
$psDir  = if (Test-Path -LiteralPath (Join-Path $src 'powershell')) { Join-Path $src 'powershell' } else { $src }
$cmdDir = if (Test-Path -LiteralPath (Join-Path $src 'cmd')) { Join-Path $src 'cmd' } else { $src }
$files = @(Get-ChildItem -LiteralPath $psDir -Filter *.ps1 -File) + @(Get-ChildItem -LiteralPath $cmdDir -Filter *.cmd -File) |
    Where-Object { $_.Name -notmatch '^install\.(ps1|cmd)$' }
if ($files.Count -lt 2) { Write-Error "No tool scripts found next to install.ps1 (looked in $psDir and $cmdDir)."; exit 1 }

# ---------- copy ----------
New-Item -ItemType Directory -Path $dest -Force | Out-Null
foreach ($f in $files) { Copy-Item -LiteralPath $f.FullName -Destination $dest -Force }
foreach ($extra in 'README.md') {
    $p = Join-Path $src $extra; if (Test-Path -LiteralPath $p) { Copy-Item -LiteralPath $p -Destination $dest -Force }
}
$docs = Join-Path $src 'docs'
if (Test-Path -LiteralPath $docs) { Copy-Item -LiteralPath $docs -Destination $dest -Recurse -Force }
# Remove tools that no longer exist in the source (keeps upgrades clean)
$wanted = @($files | ForEach-Object Name)
Get-ChildItem -LiteralPath $dest -File | Where-Object { $_.Extension -in '.ps1', '.cmd' -and $_.Name -notin $wanted } | Remove-Item -Force
Get-ChildItem -LiteralPath $dest -Recurse -File | Unblock-File -ErrorAction SilentlyContinue
Set-Content -LiteralPath (Join-Path $dest 'VERSION.txt') -Value $Version -Encoding ASCII
"Installed $($files.Count) files ($Scope scope) to: $dest"

# ---------- PATH ----------
$entries = @((Get-RawPath) -split ';' | Where-Object { $_ })
if ($entries | Where-Object { Test-SameDir $_ $dest }) {
    "Already on the $Scope PATH."
} else {
    Set-RawPath ((@($entries) + $dest) -join ';')
    "Added to the $Scope PATH: $dest"
}
if (-not (@($env:PATH -split ';') | Where-Object { $_ -and (Test-SameDir $_ $dest) })) { $env:PATH = $env:PATH.TrimEnd(';') + ';' + $dest }

''
'Ready in this window and in any new window. Windows opened before the install need to be reopened'
'(or run "refreshenv" in cmd / ". refreshenv" in PowerShell).'
'Optional - make plain "refreshenv" work in PowerShell by adding this line to your profile ($PROFILE):'
'  function refreshenv { . (Get-Command refreshenv.ps1).Source }'
exit 0
