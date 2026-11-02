@echo off
rem dnscheck - resolve a name with the system resolver and other DNS servers (nslookup).
rem Usage: dnscheck NAME [TYPE] [SERVER...]   TYPE default A; SERVERs default 1.1.1.1 8.8.8.8; "none" = system only.
rem Querying public servers sends the name being looked up to those providers.
setlocal
rem Colour via VT escapes (Windows 10+); set NO_COLOR to turn it off.
set "ESC=" & set "C_R=" & set "C_G=" & set "C_Y=" & set "C_H=" & set "C_0="
if not defined NO_COLOR for /f %%a in ('echo prompt $E^| cmd /d') do set "ESC=%%a"
if defined ESC (set "C_R=%ESC%[31m" & set "C_G=%ESC%[32m" & set "C_Y=%ESC%[33m" & set "C_H=%ESC%[1;36m" & set "C_0=%ESC%[0m")
if "%~1"=="" goto usage
set "NAME=%~1"
echo(%NAME%| findstr /r "^[A-Za-z0-9._-][A-Za-z0-9._-]*$" >nul || goto usage
set "TYPE=%~2"
if "%TYPE%"=="" set "TYPE=A"
echo(%TYPE%| findstr /i /r "^A$ ^AAAA$ ^CNAME$ ^MX$ ^TXT$ ^NS$ ^SRV$ ^SOA$ ^PTR$" >nul || goto usage
echo %C_H%===== system resolver =====%C_0%
nslookup -type=%TYPE% %NAME% 2>&1
if "%~3"=="" (
    call :srv 1.1.1.1
    call :srv 8.8.8.8
    exit /b 0
)
if /i "%~3"=="none" exit /b 0
:loop
if "%~3"=="" exit /b 0
call :srv "%~3"
shift /3
goto loop
:srv
echo(%~1| findstr /r "^[A-Za-z0-9.:_-][A-Za-z0-9.:_-]*$" >nul || goto badsrv
echo.
echo %C_H%===== %~1 =====%C_0%
nslookup -type=%TYPE% %NAME% %~1 2>&1
goto :eof
:badsrv
echo Skipping invalid server name 1>&2
goto :eof
:usage
echo Usage: dnscheck NAME [A^|AAAA^|CNAME^|MX^|TXT^|NS^|SRV^|SOA^|PTR] [SERVER...] 1>&2
exit /b 1
