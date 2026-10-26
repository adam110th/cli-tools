@echo off
rem cli-tools - wrapper that runs cli-tools.ps1 (same folder, or ..\powershell\). Usage: cli-tools [-h ^| --help ^| /?]
setlocal
set "PS1=%~dp0cli-tools.ps1"
if not exist "%PS1%" set "PS1=%~dp0..\powershell\cli-tools.ps1"
if not exist "%PS1%" goto missing
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
exit /b %ERRORLEVEL%
:missing
echo cli-tools.ps1 not found next to this script or in ..\powershell\ 1>&2
exit /b 1
