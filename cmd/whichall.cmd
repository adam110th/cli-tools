@echo off
rem whichall - every match for each NAME on PATH, in search order (uses where.exe). Usage: whichall NAME [NAME...]
if "%~1"=="" goto usage
where %*
exit /b %ERRORLEVEL%
:usage
echo Usage: whichall NAME [NAME...] 1>&2
exit /b 1
