@echo off
rem portowner - which process is using a local port (netstat + tasklist). Usage: portowner PORT
setlocal
rem Colour via VT escapes (Windows 10+); set NO_COLOR to turn it off.
set "ESC=" & set "C_R=" & set "C_G=" & set "C_Y=" & set "C_H=" & set "C_0="
if not defined NO_COLOR for /f %%a in ('echo prompt $E^| cmd /d') do set "ESC=%%a"
if defined ESC (set "C_R=%ESC%[31m" & set "C_G=%ESC%[32m" & set "C_Y=%ESC%[33m" & set "C_H=%ESC%[1;36m" & set "C_0=%ESC%[0m")
set "PORT=%~1"
echo(%PORT%| findstr /r "^[1-9][0-9]*$" >nul || goto usage
if %PORT% GTR 65535 goto usage
set "FOUND="
for /f "tokens=1-5" %%a in ('netstat -ano ^| findstr /c:":%PORT% "') do call :row %%a %%b %%c %%d %%e
if not defined FOUND goto none
exit /b 0
:row
rem TCP lines: proto local remote state pid   UDP lines: proto local remote pid
echo(%~2| findstr /e /c:":%PORT%" >nul || goto :eof
if /i "%~1"=="TCP" (set "STATE=%~4" & set "PID=%~5") else (set "STATE=-" & set "PID=%~4")
set "PNAME=?"
for /f "tokens=1 delims=," %%n in ('tasklist /fi "PID eq %PID%" /fo csv /nh 2^>nul') do set "PNAME=%%~n"
echo %~1  %STATE%  %~2  -^>  %~3  PID %PID%  %PNAME%
set "FOUND=1"
goto :eof
:none
echo %C_Y%Nothing is using local port %PORT%%C_0%
exit /b 2
:usage
echo Usage: portowner PORT   (1-65535) 1>&2
exit /b 1
