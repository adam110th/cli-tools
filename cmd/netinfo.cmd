@echo off
rem netinfo - adapters, IPv4, gateway and DNS from ipconfig. Usage: netinfo [/public]
setlocal
echo Host: %COMPUTERNAME%
ipconfig /all | findstr /c:"adapter" /c:"Description" /c:"Media State" /c:"Physical Address" /c:"IPv4 Address" /c:"Subnet Mask" /c:"Default Gateway" /c:"DNS Servers"
if /i not "%~1"=="/public" exit /b 0
echo.
<nul set /p "=Public IP: "
curl.exe -fsS --max-time 5 https://api.ipify.org || echo (lookup failed)
echo.
