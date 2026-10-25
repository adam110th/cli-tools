@echo off
rem pendingreboot - is a reboot pending, and why? Usage: pendingreboot   Exit: 0 no, 2 yes
setlocal
set "P="
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" >nul 2>&1 && (echo PENDING: Component Based Servicing - Windows updates or features& set "P=1")
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" >nul 2>&1 && (echo PENDING: Windows Update& set "P=1")
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations >nul 2>&1 && (echo PENDING: file rename operations - often installers or antivirus, may be benign& set "P=1")
set "A=" & set "B="
for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName" /v ComputerName 2^>nul ^| findstr /c:"REG_SZ"') do set "A=%%a"
for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" /v ComputerName 2^>nul ^| findstr /c:"REG_SZ"') do set "B=%%a"
if defined A if defined B if /i not "%A%"=="%B%" (echo PENDING: computer rename %A% to %B%& set "P=1")
if defined P goto pending
echo No reboot pending.
exit /b 0
:pending
echo Reboot pending.
exit /b 2
