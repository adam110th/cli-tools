@echo off
rem refreshenv - reload environment variables (including PATH) from the registry into THIS cmd window,
rem so newly installed tools work without opening a new window. Usage: refreshenv
rem Run it from cmd. Run from PowerShell it only updates a short-lived child process; use . refreshenv.ps1 there.
rem No setlocal on purpose: the changes must stay in the calling window.
for /f "tokens=1,2,*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" 2^>nul ^| findstr /c:"REG_"') do if /i not "%%a"=="Path" if /i not "%%a"=="PSModulePath" if /i not "%%a"=="USERNAME" call set "%%a=%%c"
for /f "tokens=1,2,*" %%a in ('reg query "HKCU\Environment" 2^>nul ^| findstr /c:"REG_"') do if /i not "%%a"=="Path" if /i not "%%a"=="PSModulePath" call set "%%a=%%c"
set "_RE_M=" & set "_RE_U="
for /f "tokens=2,*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul ^| findstr /c:"REG_"') do set "_RE_M=%%b"
for /f "tokens=2,*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul ^| findstr /c:"REG_"') do set "_RE_U=%%b"
call set "PATH=%_RE_M%;%_RE_U%"
set "_RE_M=" & set "_RE_U="
echo Environment refreshed.
