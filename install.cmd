@echo off
rem install - runs install.ps1 from this folder, then refreshes this window's PATH.
rem Same arguments as install.ps1, e.g.:   install    install -Scope Machine    install -Uninstall
setlocal
if not exist "%~dp0install.ps1" goto missing
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
if errorlevel 1 exit /b %ERRORLEVEL%
endlocal
set "_RE_SRC=%~dp0cmd\refreshenv.cmd"
if not exist "%_RE_SRC%" set "_RE_SRC=%~dp0refreshenv.cmd"
if exist "%_RE_SRC%" call "%_RE_SRC%"
set "_RE_SRC="
exit /b 0
:missing
echo install.ps1 not found next to install.cmd 1>&2
exit /b 1
