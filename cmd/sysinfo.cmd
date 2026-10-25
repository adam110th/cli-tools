@echo off
rem sysinfo - host, OS, hardware, serial, join status and disks. Usage: sysinfo  (systeminfo takes ~10 s)
setlocal
systeminfo | findstr /b /c:"Host Name" /c:"OS Name" /c:"OS Version" /c:"System Manufacturer" /c:"System Model" /c:"System Boot Time" /c:"Total Physical Memory" /c:"Available Physical Memory"
for /f "usebackq delims=" %%s in (`powershell.exe -NoProfile -Command "(Get-CimInstance Win32_BIOS).SerialNumber"`) do echo Serial Number:             %%s
echo.
echo Join status:
dsregcmd /status | findstr /c:"AzureAdJoined" /c:"DomainJoined" /c:"WorkplaceJoined" /c:"TenantName"
echo.
echo Disks:
powershell.exe -NoProfile -Command "Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object { '  {0}  {1,8:N1} GB free of {2,8:N1} GB' -f $_.DeviceID, ($_.FreeSpace/1GB), ($_.Size/1GB) }"
