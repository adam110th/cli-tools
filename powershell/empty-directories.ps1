<#
.SYNOPSIS
    Empties (and by default removes) every directory listed in a .txt or .csv file.

.DESCRIPTION
    Input file format:
      - One path per line, OR a comma-separated list (quote any path containing a comma).
      - Optional base path line anywhere in the file:   base: X:\GoogleDrive\Shared
      - Lines starting with # are comments.
      - An optional CSV header of Path / Directory / Folder is ignored.
      - Windows error text pasted after a path (" - The directory is not empty.") is stripped.

    Base path precedence: -BasePath parameter, then the "base:" line in the file, then the
    current directory (only after you confirm it). Absolute entries (X:\... or \\server\...)
    ignore the base path. Relative entries may not climb out of the base path with "..".

    Every entry is checked before anything is touched. Missing, invalid and blocked entries
    are reported as warnings, and you must type YES before any directory is emptied.
    Robocopy does the emptying, so paths longer than 260 characters are handled.

.PARAMETER InputFile    The .txt or .csv file listing the directories.
.PARAMETER BasePath     Optional base path for relative entries.
.PARAMETER Format       Auto (default), Lines or Comma. Auto: several lines = Lines mode,
                        a single line = Comma mode.
.PARAMETER KeepFolders  Empty the directories but leave the empty folders in place.
.PARAMETER Force        Skip the final YES confirmation.
.PARAMETER LogPath      Results CSV. Defaults to <inputfile>-results-<timestamp>.csv.

.EXAMPLE
    .\empty-directories.ps1 .\dirs.txt -WhatIf
.EXAMPLE
    .\empty-directories.ps1 .\dirs.csv -BasePath 'X:\GoogleDrive\Shared' -KeepFolders
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$InputFile,
    [Parameter(Position = 1)][string]$BasePath,
    [ValidateSet('Auto', 'Lines', 'Comma')][string]$Format = 'Auto',
    [switch]$KeepFolders,
    [switch]$Force,
    [string]$LogPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------- helpers ----------
function Get-LongPath([string]$Path) {
    if ($Path.StartsWith('\\?\')) { return $Path }
    if ($Path.StartsWith('\\'))   { return '\\?\UNC\' + $Path.Substring(2) }
    return '\\?\' + $Path
}

function Test-IsAbsolute([string]$Path) {
    return ($Path -match '^[A-Za-z]:\\' -or $Path -match '^\\\\[^\\]+\\[^\\]+')
}

function Test-IsRoot([string]$Path) {
    $p = $Path.TrimEnd('\')
    return ($p -match '^[A-Za-z]:$' -or $p -match '^\\\\[^\\]+\\[^\\]+$')
}

function Read-YesNo([string]$Question) {
    while ($true) {
        $a = (Read-Host "$Question [Y/N]").Trim()
        if ($a -match '^(y|yes)$') { return $true }
        if ($a -match '^(n|no)$')  { return $false }
        Write-Host 'Please answer Y or N.' -ForegroundColor Yellow
    }
}

function Get-ItemCount([string]$Path) {
    return @(Get-ChildItem -LiteralPath (Get-LongPath $Path) -Recurse -Force -ErrorAction SilentlyContinue).Count
}

$errorSuffix   = '\s+-\s+(The directory is not empty|The filename, directory name, or volume label syntax is incorrect|The system cannot find the (file|path) specified|Access is denied)\.?\s*$'
$baseDirective = '^\s*#?\s*base(path)?\s*[:=]\s*(?<p>.+?)\s*$'
$headerRow     = '^\s*"?(path|directory|folder|dir)"?\s*,?\s*$'
$badChars      = [IO.Path]::GetInvalidFileNameChars()

# ---------- read input ----------
if (-not (Test-Path -LiteralPath $InputFile -PathType Leaf)) { throw "Input file not found: $InputFile" }
$InputFile = (Resolve-Path -LiteralPath $InputFile).ProviderPath
$raw = Get-Content -LiteralPath $InputFile -Raw
if ([string]::IsNullOrWhiteSpace($raw)) { throw "Input file is empty: $InputFile" }

$fileBase = $null
$body = New-Object System.Collections.Generic.List[string]
foreach ($line in ($raw -split '\r?\n')) {
    if ($line -match $baseDirective) {
        if (-not $fileBase) { $fileBase = $Matches['p'].Trim().Trim('"', "'") }
        continue
    }
    if ($line.TrimStart().StartsWith('#') -or -not $line.Trim()) { continue }
    if ($body.Count -eq 0 -and $line -match $headerRow) { continue }
    $body.Add($line)
}
if ($body.Count -eq 0) { throw 'No directory entries found in the input file.' }

if ($Format -eq 'Auto') {
    $wrapped = @($body | Where-Object { $_.TrimEnd().EndsWith(',') }).Count -gt 0
    $Format = if ($body.Count -gt 1 -and -not $wrapped) { 'Lines' } else { 'Comma' }
}

$entries = @()
if ($Format -eq 'Lines') {
    $entries = $body | ForEach-Object { $_.Trim().TrimEnd(',').Trim().Trim('"') }
} else {
    Add-Type -AssemblyName Microsoft.VisualBasic
    $reader = New-Object System.IO.StringReader(($body -join "`n"))
    $parser = New-Object Microsoft.VisualBasic.FileIO.TextFieldParser($reader)
    $parser.SetDelimiters(',')
    $parser.HasFieldsEnclosedInQuotes = $true
    $parser.TrimWhiteSpace = $true
    while (-not $parser.EndOfData) { $entries += $parser.ReadFields() }
    $parser.Close()
}

# clean, drop pasted error text, de-duplicate (case-insensitive)
$seen = @{}
$entries = foreach ($e in $entries) {
    $c = ($e -replace $errorSuffix, '').Trim().Trim('"').TrimEnd('\', '/')
    if ($c -and -not $seen.ContainsKey($c.ToLower())) { $seen[$c.ToLower()] = $true; $c }
}
Write-Host "Read $(@($entries).Count) entr$(if (@($entries).Count -eq 1) {'y'} else {'ies'}) ($Format mode) from $InputFile"

# ---------- resolve base path ----------
$needsBase = @($entries | Where-Object { -not (Test-IsAbsolute $_) }).Count -gt 0
if ($needsBase) {
    if ($BasePath) {
        Write-Host "Base path (parameter): $BasePath"
    } elseif ($fileBase) {
        $BasePath = $fileBase
        Write-Host "Base path (from input file): $BasePath"
    } else {
        $cwd = (Get-Location).ProviderPath
        Write-Warning 'No base path was given as a parameter or found in the input file.'
        if (-not (Read-YesNo "Use the current directory '$cwd' as the base path?")) {
            Write-Host 'Cancelled. Re-run with -BasePath or add a "base: <path>" line to the input file.'
            exit 1
        }
        $BasePath = $cwd
    }
    if (-not (Test-IsAbsolute $BasePath)) { throw "Base path must be absolute (X:\... or \\server\share\...): $BasePath" }
    $BasePath = [IO.Path]::GetFullPath($BasePath).TrimEnd('\')
    if (-not (Test-Path -LiteralPath (Get-LongPath $BasePath) -PathType Container)) { throw "Base path not found: $BasePath" }
}

# ---------- validate every entry before touching anything ----------
$results = foreach ($e in $entries) {
    $r = [pscustomobject]@{ Entry = $e; FullPath = ''; Status = ''; Items = 0; Detail = '' }

    $rel = $e -replace '^([A-Za-z]:\\|\\\\)', ''
    $badSeg = $rel -split '[\\/]' | Where-Object { $_.IndexOfAny($badChars) -ge 0 } | Select-Object -First 1
    if ($badSeg) {
        $r.Status = 'Invalid'; $r.Detail = "Name contains characters Windows cannot use: $badSeg"; $r; continue
    }

    $full = if (Test-IsAbsolute $e) { $e } else { Join-Path $BasePath $e.TrimStart('\', '/') }
    try { $full = [IO.Path]::GetFullPath($full).TrimEnd('\') }
    catch { $r.Status = 'Invalid'; $r.Detail = $_.Exception.Message; $r; continue }
    $r.FullPath = $full

    if ((Test-IsRoot $full) -or ($BasePath -and $full -eq $BasePath)) {
        $r.Status = 'Blocked'; $r.Detail = 'Refusing to empty a drive/share root or the base path itself'; $r; continue
    }
    if (-not (Test-IsAbsolute $e) -and -not $full.StartsWith($BasePath + '\', [StringComparison]::OrdinalIgnoreCase)) {
        $r.Status = 'Blocked'; $r.Detail = 'Relative entry resolves outside the base path'; $r; continue
    }

    $long = Get-LongPath $full
    if (Test-Path -LiteralPath $long -PathType Container) {
        $r.Status = 'Found'; $r.Items = Get-ItemCount $full
    } elseif (Test-Path -LiteralPath $long) {
        $r.Status = 'NotADirectory'; $r.Detail = 'Path is a file, not a directory'
    } else {
        $r.Status = 'NotFound'
    }
    $r
}

foreach ($r in $results | Where-Object { $_.Status -ne 'Found' }) {
    $msg = "$($r.Status): $($r.Entry)"
    if ($r.Detail) { $msg += " -- $($r.Detail)" }
    Write-Warning $msg
}

$todo = @($results | Where-Object { $_.Status -eq 'Found' })
if ($todo.Count -eq 0) { Write-Host 'Nothing to do: no listed directories were found.' -ForegroundColor Yellow; exit 1 }

$total = ($todo | Measure-Object Items -Sum).Sum
Write-Host ''
Write-Host "$($todo.Count) director$(if ($todo.Count -eq 1) {'y'} else {'ies'}) found, $total item(s) in total:" -ForegroundColor Cyan
$todo | ForEach-Object { Write-Host ("  {0,7}  {1}" -f $_.Items, $_.FullPath) }
Write-Host ''

if (-not $Force -and -not $WhatIfPreference) {
    $action = if ($KeepFolders) { 'EMPTY' } else { 'EMPTY AND REMOVE' }
    $answer = Read-Host "Type YES to $action these $($todo.Count) directories"
    if ($answer -cne 'YES') { Write-Host 'Cancelled. Nothing was changed.'; exit 1 }
}

# ---------- empty ----------
$emptySrc = Join-Path $env:TEMP ('empty_' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $emptySrc | Out-Null
try {
    foreach ($r in $todo) {
        if (-not $PSCmdlet.ShouldProcess($r.FullPath, ($(if ($KeepFolders) {'Empty directory'} else {'Empty and remove directory'})))) {
            $r.Status = 'WhatIf'; continue
        }
        & robocopy.exe $emptySrc $r.FullPath /MIR /R:2 /W:2 /NFL /NDL /NJH /NJS /NP | Out-Null
        if ($LASTEXITCODE -ge 8) { $r.Detail = "robocopy exit code $LASTEXITCODE" }

        # fallback for read-only or locked leftovers
        $long = Get-LongPath $r.FullPath
        if ((Get-ItemCount $r.FullPath) -gt 0) {
            Get-ChildItem -LiteralPath $long -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }

        $left = Get-ItemCount $r.FullPath
        if ($left -gt 0) {
            $r.Status = 'Partial'; $r.Detail = (("$left item(s) remain (sync lock or open file?) " + $r.Detail).Trim())
            Write-Host "PARTIAL: $($r.FullPath) ($left left)" -ForegroundColor Red
        } elseif ($KeepFolders) {
            $r.Status = 'Emptied'; Write-Host "EMPTIED: $($r.FullPath)" -ForegroundColor Green
        } else {
            try   { Remove-Item -LiteralPath $long -Force; $r.Status = 'Removed'; Write-Host "REMOVED: $($r.FullPath)" -ForegroundColor Green }
            catch { $r.Status = 'Emptied'; $r.Detail = "Emptied but folder not removed: $($_.Exception.Message)"
                    Write-Host "EMPTIED (folder kept): $($r.FullPath)" -ForegroundColor Yellow }
        }
    }
} finally {
    Remove-Item -LiteralPath $emptySrc -Force -ErrorAction SilentlyContinue
}

# ---------- report ----------
if (-not $LogPath) {
    $LogPath = [IO.Path]::ChangeExtension($InputFile, $null).TrimEnd('.') + '-results-' + (Get-Date -Format 'yyyy-MM-dd_HHmmss') + '.csv'
}
$results | Export-Csv -LiteralPath $LogPath -NoTypeInformation
Write-Host ''
$results | Group-Object Status | ForEach-Object { Write-Host ("{0,-14} {1}" -f $_.Name, $_.Count) }
Write-Host "Log: $LogPath"

if (@($results | Where-Object { $_.Status -in 'Partial', 'Invalid', 'Blocked', 'NotFound', 'NotADirectory' }).Count -gt 0) { exit 2 }
exit 0
