@echo off
rem pendingreboot - is a reboot pending, and why? Usage: pendingreboot   Exit: 0 no, 2 yes
setlocal
rem Colour via VT escapes (Windows 10+); set NO_COLOR to turn it off.
set "ESC=" & set "C_R=" & set "C_G=" & set "C_Y=" & set "C_H=" & set "C_0="
if not defined NO_COLOR for /f %%a in ('echo prompt $E^| cmd /d') do set "ESC=%%a"
if defined ESC (set "C_R=%ESC%[31m" & set "C_G=%ESC%[32m" & set "C_Y=%ESC%[33m" & set "C_H=%ESC%[1;36m" & set "C_0=%ESC%[0m")
set "P="
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" >nul 2>&1 && (echo %C_Y%PENDING:%C_0% Component Based Servicing - Windows updates or features& set "P=1")
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" >nul 2>&1 && (echo %C_Y%PENDING:%C_0% Windows Update& set "P=1")
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations >nul 2>&1 && (echo %C_Y%PENDING:%C_0% file rename operations - often installers or antivirus, may be benign& set "P=1")
set "A=" & set "B="
for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName" /v ComputerName 2^>nul ^| findstr /c:"REG_SZ"') do set "A=%%a"
for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" /v ComputerName 2^>nul ^| findstr /c:"REG_SZ"') do set "B=%%a"
if defined A if defined B if /i not "%A%"=="%B%" (echo %C_Y%PENDING:%C_0% computer rename %A% to %B%& set "P=1")
if defined P goto pending
echo %C_G%No reboot pending.%C_0%
exit /b 0
:pending
echo %C_Y%Reboot pending.%C_0%
exit /b 2
