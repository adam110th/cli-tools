@echo off
rem dupfiles - wrapper that runs dupfiles.ps1 (same folder, or ..\powershell\). Same arguments as the .ps1.
setlocal
set "PS1=%~dp0dupfiles.ps1"
if not exist "%PS1%" set "PS1=%~dp0..\powershell\dupfiles.ps1"
if not exist "%PS1%" goto missing
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
exit /b %ERRORLEVEL%
:missing
echo dupfiles.ps1 not found next to this script or in ..\powershell\ 1>&2
exit /b 1
