@echo off
rem pathlist - print each PATH entry on its own line, flagging missing folders. Usage: pathlist
setlocal
rem Colour via VT escapes (Windows 10+); set NO_COLOR to turn it off.
set "ESC=" & set "C_R=" & set "C_G=" & set "C_Y=" & set "C_H=" & set "C_0="
if not defined NO_COLOR for /f %%a in ('echo prompt $E^| cmd /d') do set "ESC=%%a"
if defined ESC (set "C_R=%ESC%[31m" & set "C_G=%ESC%[32m" & set "C_Y=%ESC%[33m" & set "C_H=%ESC%[1;36m" & set "C_0=%ESC%[0m")
set /a n=0
for %%p in ("%PATH:;=" "%") do call :show "%%~p"
exit /b 0
:show
set /a n+=1
if "%~1"=="" (echo   %n%  %C_Y%^(empty entry^)%C_0%& goto :eof)
set "flag="
if not exist "%~1\" set "flag= %C_Y%[missing]%C_0%"
echo   %n%  %~1%flag%
goto :eof
