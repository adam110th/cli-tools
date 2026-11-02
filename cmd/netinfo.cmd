@echo off
rem netinfo - adapters, IPv4, gateway and DNS from ipconfig. Usage: netinfo [/public]
setlocal
rem Colour via VT escapes (Windows 10+); set NO_COLOR to turn it off.
set "ESC=" & set "C_R=" & set "C_G=" & set "C_Y=" & set "C_H=" & set "C_0="
if not defined NO_COLOR for /f %%a in ('echo prompt $E^| cmd /d') do set "ESC=%%a"
if defined ESC (set "C_R=%ESC%[31m" & set "C_G=%ESC%[32m" & set "C_Y=%ESC%[33m" & set "C_H=%ESC%[1;36m" & set "C_0=%ESC%[0m")
echo Host: %COMPUTERNAME%
ipconfig /all | findstr /c:"adapter" /c:"Description" /c:"Media State" /c:"Physical Address" /c:"IPv4 Address" /c:"Subnet Mask" /c:"Default Gateway" /c:"DNS Servers"
if /i not "%~1"=="/public" exit /b 0
echo.
<nul set /p "=Public IP: "
curl.exe -fsS --max-time 5 https://api.ipify.org || echo %C_R%(lookup failed)%C_0%
echo.
