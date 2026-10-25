<#
.SYNOPSIS  File hashes (default SHA256).
.EXAMPLE   .\hashfile.ps1 setup.exe -Algorithm SHA1
#>
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromRemainingArguments = $true)][string[]]$Path,
    [ValidateSet('SHA256', 'SHA1', 'MD5', 'SHA512')][string]$Algorithm = 'SHA256'
)
Get-FileHash -Path $Path -Algorithm $Algorithm | ForEach-Object { '{0}  {1}' -f $_.Hash.ToLower(), $_.Path }
