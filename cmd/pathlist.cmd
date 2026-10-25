@echo off
rem pathlist - print each PATH entry on its own line, flagging missing folders. Usage: pathlist
setlocal
set /a n=0
for %%p in ("%PATH:;=" "%") do call :show "%%~p"
exit /b 0
:show
set /a n+=1
if "%~1"=="" (echo   %n%  ^(empty entry^)& goto :eof)
set "flag="
if not exist "%~1\" set "flag= [missing]"
echo   %n%  %~1%flag%
goto :eof
