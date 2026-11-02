<#
.SYNOPSIS
    Install recommended third-party CLI tools (not part of cli-tools) on Windows with Chocolatey, falling back to winget.

.DESCRIPTION
    Chocolatey is installed first if it is missing (needs an elevated prompt). Each tool is installed with
    Chocolatey when possible, otherwise with winget. Without admin rights Chocolatey cannot install, so
    winget is used for everything. Running as SYSTEM (Intune) uses Chocolatey only, as winget is not
    available to SYSTEM. Already-installed tools are skipped.

    Linux-only tools are left out: thefuck, fdupes (use cli-tools dupfiles), ddgr and asciinema.
    neofetch is replaced by fastfetch, its maintained Windows equivalent. tre has no package, so tre.exe
    is taken from its GitHub release into the cli-tools folder (already on PATH).

    Writes a marked block (# >>> cli-tools extras >>>) to the PowerShell profiles (Windows PowerShell 5.1
    and PowerShell 7, profile.ps1 for all hosts) that makes eza run as "eza -a -l -h -M --icons=always"
    and hooks zoxide in. Skipped when running as SYSTEM.

    Exit codes: 0 all done, 1 bad arguments, 2 one or more tools could not be installed.

.PARAMETER Tool  Install only these tools (default: all). See -List.
.PARAMETER List  List the tool names and exit.

.EXAMPLE  .\install-extras.ps1
.EXAMPLE  .\install-extras.ps1 eza bat fzf
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)][string[]]$Tool,
    [switch]$List
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Colour only on an interactive console: not when redirected, piped, or NO_COLOR is set.
$useColor = $Host.UI.SupportsVirtualTerminal -and -not [Console]::IsOutputRedirected -and -not $env:NO_COLOR -and $MyInvocation.PipelinePosition -eq $MyInvocation.PipelineLength
function Paint([string]$Code, [string]$Text) { if ($useColor) { "$([char]27)[${Code}m$Text$([char]27)[0m" } else { $Text } }

# name, command(s) that show it is installed, Chocolatey id, winget id ('' = none)
$tools = @(
    @('zoxide',   'zoxide',    'zoxide',      'ajeetdsouza.zoxide'),
    @('tldr',     'tldr',      'tealdeer',    'dbrgn.tealdeer'),
    @('scc',      'scc',       'scc',         'BenBoyter.scc'),
    @('eza',      'eza',       'eza',         'eza-community.eza'),
    @('duf',      'duf',       'duf',         'muesli.duf'),
    @('bat',      'bat',       'bat',         'sharkdp.bat'),
    @('exiftool', 'exiftool',  'exiftool',    'OliverBetz.ExifTool'),
    @('fzf',      'fzf',       'fzf',         'junegunn.fzf'),
    @('jq',       'jq',        'jq',          'jqlang.jq'),
    @('procs',    'procs',     'procs',       'dalance.procs'),
    @('browsh',   'browsh',    '',            'browsh.browsh'),
    @('lazygit',  'lazygit',   'lazygit',     'JesseDuffield.lazygit'),
    @('fastfetch','fastfetch', 'fastfetch',   'Fastfetch-cli.Fastfetch'),
    @('tre',      'tre',       '',            ''),
    @('git',      'git',       'git',         'Git.Git'),
    @('gh',       'gh',        'gh',          'GitHub.cli'),
    @('claude',   'claude',    'claude-code', 'Anthropic.ClaudeCode')
) | ForEach-Object { [pscustomobject]@{ Name = $_[0]; Command = $_[1]; Choco = $_[2]; Winget = $_[3] } }

if ($List) { $tools.Name; exit 0 }
$unknown = @($Tool | Where-Object { $_ -and $_ -notin $tools.Name })
if ($unknown) { Write-Error "Unknown tool: $($unknown -join ', ') (see -List)" -ErrorAction Continue; exit 1 }
if ($Tool) { $tools = @($tools | Where-Object { $_.Name -in $Tool }) }

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$isSystem = $identity.User.Value -eq 'S-1-5-18'
$isAdmin  = (New-Object Security.Principal.WindowsPrincipal $identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

function Update-SessionPath {   # pick up PATH changes the package installers made
    $m = [Environment]::GetEnvironmentVariable('Path', 'Machine'); $u = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:PATH = (@($m, $u) | Where-Object { $_ }) -join ';'
}
function Test-Installed([string]$Command) { [bool](Get-Command $Command -CommandType Application -ErrorAction SilentlyContinue) }
function Step([string]$Text) { ''; Paint '1;36' $Text }

# ---------- package managers ----------
$choco = Get-Command choco.exe -ErrorAction SilentlyContinue
if (-not $choco -and $isAdmin) {
    Step 'Installing Chocolatey'
    # the documented install command, in a child process so its settings do not leak into this script
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" | Out-Null
    Update-SessionPath
    $choco = Get-Command choco.exe -ErrorAction SilentlyContinue
    if (-not $choco -and $env:ProgramData) { $choco = Get-Command (Join-Path $env:ProgramData 'chocolatey\bin\choco.exe') -ErrorAction SilentlyContinue }
    if ($choco) { '  ' + (Paint '32' 'installed') } else { '  ' + (Paint '31' 'FAILED') + ' - continuing with winget' }
} elseif (-not $choco) {
    Write-Warning 'Chocolatey is not installed and needs an elevated prompt to install (and to install packages). Using winget for this run; rerun as administrator to use Chocolatey.'
}
$canChoco  = $choco -and $isAdmin
$winget    = if ($isSystem) { $null } else { Get-Command winget.exe -ErrorAction SilentlyContinue }

function Install-Choco([string]$Id) {
    & $choco.Source install $Id -y --no-progress --limit-output | Out-Null
    return $LASTEXITCODE -in 0, 1641, 3010   # 1641/3010 = installed, reboot required
}
function Install-Winget([string]$Id) {
    & $winget.Source install --id $Id --exact --silent --disable-interactivity --accept-source-agreements --accept-package-agreements | Out-Null
    return $LASTEXITCODE -eq 0
}
function Install-Tre {   # no Chocolatey or winget package: tre.exe from the GitHub release, into the cli-tools folder on PATH
    $cli = Get-Command cli-tools.ps1 -ErrorAction SilentlyContinue
    if (-not $cli -or -not [Environment]::Is64BitOperatingSystem) { return $false }
    $rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/dduan/tre/releases/latest' -UseBasicParsing
    $asset = @($rel.assets | Where-Object { $_.name -match 'x86_64-pc-windows-msvc\.zip$' })[0]
    if (-not $asset) { return $false }
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile (Join-Path $tmp 'tre.zip') -UseBasicParsing
        Expand-Archive -LiteralPath (Join-Path $tmp 'tre.zip') -DestinationPath $tmp -Force
        $exe = Get-ChildItem -LiteralPath $tmp -Recurse -Filter tre.exe | Select-Object -First 1
        if (-not $exe) { return $false }
        Copy-Item -LiteralPath $exe.FullName -Destination (Split-Path $cli.Source -Parent) -Force
        return $true
    } finally { Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue }
}

# ---------- install ----------
$via = @($(if ($canChoco) { 'Chocolatey' }), $(if ($winget) { 'winget' })) | Where-Object { $_ }
Step "Installing third-party CLI tools ($(if ($via) { $via -join ', then ' } else { 'no package manager available' }))"
$installed = @(); $present = @(); $failed = @()
foreach ($t in $tools) {
    $label = '  {0,-10} ' -f $t.Name
    if (Test-Installed $t.Command) { $label + (Paint '2' 'already installed'); $present += $t.Name; continue }
    $how = $null
    try {
        if ($canChoco -and $t.Choco -and (Install-Choco $t.Choco)) { $how = "Chocolatey: $($t.Choco)" }
        elseif ($winget -and $t.Winget -and (Install-Winget $t.Winget)) { $how = "winget: $($t.Winget)" }
        elseif ($t.Name -eq 'tre' -and (Install-Tre)) { $how = 'GitHub release, into the cli-tools folder' }
    } catch { $how = $null }
    Update-SessionPath
    if ($how) {
        $label + (Paint '32' 'installed') + " ($how)"; $installed += $t.Name
        if ($t.Name -eq 'browsh' -and -not (Test-Installed firefox)) { '  ' + (Paint '33' 'browsh needs Firefox: install it with  choco install firefox  or  winget install Mozilla.Firefox') }
    } else {
        $why = if ($t.Name -eq 'tre') { 'needs cli-tools installed first (install.ps1), 64-bit Windows and GitHub access' } else { 'no package manager could install it' }
        $label + (Paint '31' 'FAILED') + " ($why)"; $failed += $t.Name
    }
}

# ---------- PowerShell profile: eza alias and zoxide hook ----------
$begin = '# >>> cli-tools extras >>>'; $end = '# <<< cli-tools extras <<<'
$block = @"
$begin
# aliases and shell hooks for the third-party tools from install-extras.ps1 (safe if a tool is missing)
if (Get-Command eza.exe -CommandType Application -ErrorAction SilentlyContinue) {
    function eza { & (Get-Command eza.exe -CommandType Application | Select-Object -First 1).Source -a -l -h -M --icons=always @args }
}
if (Get-Command zoxide.exe -CommandType Application -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}
$end
"@
if ($isSystem) {
    ''; 'Running as SYSTEM: PowerShell profile aliases skipped (run install-extras.ps1 as the user to add them).'
} else {
    Step 'PowerShell profile (eza alias, zoxide hook)'
    $docs = [Environment]::GetFolderPath('MyDocuments')
    foreach ($p in (Join-Path $docs 'WindowsPowerShell\profile.ps1'), (Join-Path $docs 'PowerShell\profile.ps1')) {
        New-Item -ItemType Directory -Path (Split-Path $p -Parent) -Force | Out-Null
        $text = if (Test-Path -LiteralPath $p) { [IO.File]::ReadAllText($p) } else { '' }
        $text = [regex]::Replace($text, '(?ms)^' + [regex]::Escape($begin) + '\r?$.*?^' + [regex]::Escape($end) + '\r?\n?', '')
        [IO.File]::WriteAllText($p, $text.TrimEnd() + "`r`n`r`n" + ($block -replace '\r?\n', "`r`n") + "`r`n", (New-Object Text.UTF8Encoding $true))
        "  updated $p"
    }
    if ((Get-ExecutionPolicy) -in 'Restricted', 'AllSigned') {
        '  ' + (Paint '33' "Execution policy is $(Get-ExecutionPolicy): profiles will not load. To allow them: Set-ExecutionPolicy -Scope CurrentUser RemoteSigned")
    }
}

# ---------- summary ----------
''
$f = if ($failed) { Paint '31' "$($failed.Count) failed: $($failed -join ', ')" } else { '0 failed' }
(Paint '1' 'Done:') + ' ' + (Paint '32' "$($installed.Count) installed") + ", $($present.Count) already present, $f"
'Open a new window to pick up PATH and the profile. eza --icons needs a Nerd Font in your terminal.'
if ($failed) { exit 2 }
exit 0
