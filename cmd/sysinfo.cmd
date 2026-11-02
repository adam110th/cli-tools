@echo off
rem sysinfo - host, OS, hardware, serial, join status and disks. Usage: sysinfo  (systeminfo takes ~10 s)
setlocal
rem Colour via VT escapes (Windows 10+); set NO_COLOR to turn it off.
set "ESC=" & set "C_R=" & set "C_G=" & set "C_Y=" & set "C_H=" & set "C_0="
if not defined NO_COLOR for /f %%a in ('echo prompt $E^| cmd /d') do set "ESC=%%a"
if defined ESC (set "C_R=%ESC%[31m" & set "C_G=%ESC%[32m" & set "C_Y=%ESC%[33m" & set "C_H=%ESC%[1;36m" & set "C_0=%ESC%[0m")
systeminfo | findstr /b /c:"Host Name" /c:"OS Name" /c:"OS Version" /c:"System Boot Time" /c:"Total Physical Memory" /c:"Available Physical Memory"
rem Model and serial, skipping OEM placeholders ("System Product Name" etc.) in favour of the motherboard's values.
powershell.exe -NoProfile -Command "$ph = '', '0', 'none', 'oem', 'o.e.m.', 'default string', 'not applicable', '0123456789', 'system manufacturer', 'system product name', 'system serial number', 'system version', 'to be filled by o.e.m.', 'chassis serial number', 'base board serial number'; function Real($s) { $s = ([string]$s).Trim(); if ($ph -contains $s) { '' } else { $s } }; $cs = Get-CimInstance Win32_ComputerSystem; $bb = Get-CimInstance Win32_BaseBoard | Select-Object -First 1; $m = (@((Real $cs.Manufacturer), (Real $cs.Model)) -ne '') -join ' '; if (-not (Real $cs.Model)) { $b = (@((Real $bb.Manufacturer), (Real $bb.Product)) -ne '') -join ' '; if ($b) { $m = $b + ' (motherboard)' } }; $s = Real (Get-CimInstance Win32_BIOS).SerialNumber; if (-not $s) { $b = Real $bb.SerialNumber; if ($b) { $s = $b + ' (motherboard)' } }; if (-not $m) { $m = 'n/a' }; if (-not $s) { $s = 'n/a' }; 'System Model:                  ' + $m; 'Serial Number:                 ' + $s"
echo.
echo %C_H%Join status:%C_0%
dsregcmd /status | findstr /c:"AzureAdJoined" /c:"DomainJoined" /c:"WorkplaceJoined" /c:"TenantName"
echo.
echo %C_H%Disks:%C_0%
powershell.exe -NoProfile -Command "Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object { '  {0}  {1,8:N1} GB free of {2,8:N1} GB' -f $_.DeviceID, ($_.FreeSpace/1GB), ($_.Size/1GB) }"
