@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-DockerH.ps1"
set "RESULT=%ERRORLEVEL%"
echo.
if not "%RESULT%"=="0" (
    echo Installer exited with code %RESULT%.
) else (
    echo Script finished. Follow any instructions shown above.
)
pause
exit /b %RESULT%
