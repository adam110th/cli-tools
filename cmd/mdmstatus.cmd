@echo off
rem mdmstatus - wrapper that runs mdmstatus.ps1 (same folder, or ..\powershell\). Same arguments as the .ps1.
setlocal
set "PS1=%~dp0mdmstatus.ps1"
if not exist "%PS1%" set "PS1=%~dp0..\powershell\mdmstatus.ps1"
if not exist "%PS1%" goto missing
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
exit /b %ERRORLEVEL%
:missing
echo mdmstatus.ps1 not found next to this script or in ..\powershell\ 1>&2
exit /b 1
