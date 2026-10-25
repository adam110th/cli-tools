@echo off
rem hashfile - file hash via certutil (default SHA256). Usage: hashfile FILE [SHA256|SHA1|MD5|SHA512]
setlocal
if "%~1"=="" goto usage
set "ALG=%~2"
if "%ALG%"=="" set "ALG=SHA256"
for %%a in (SHA256 SHA1 MD5 SHA512) do if /i "%ALG%"=="%%a" goto algok
goto usage
:algok
if not exist "%~1" goto notfound
set "H="
for /f "skip=1 delims=" %%h in ('certutil -hashfile "%~1" %ALG% ^| findstr /v /c:"CertUtil"') do (set "H=%%h" & goto done)
:done
if not defined H exit /b 1
echo %H%  %~f1
exit /b 0
:notfound
echo File not found: %~1 1>&2
exit /b 1
:usage
echo Usage: hashfile FILE [SHA256^|SHA1^|MD5^|SHA512] 1>&2
exit /b 1
