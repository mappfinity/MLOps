@echo off
setlocal EnableExtensions
title Install WSL + Ubuntu on H:

REM Install WSL and Ubuntu into a dedicated folder on H:.
REM If Windows requires a reboot, reboot and run this BAT again.

set "DISTRO=Ubuntu"
set "WSL_ROOT=H:\WSL"
set "INSTALL_DIR=H:\WSL\Ubuntu"
set "MARKER=H:\WSL\.wsl-ubuntu-install-in-progress"

REM Request administrator rights if needed.
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Requesting administrator approval...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

if not exist "H:\" (
    echo ERROR: Drive H: was not found in this elevated session.
    echo Make sure H: is available as a local drive, then run this file again.
    pause
    exit /b 1
)

REM Detect an existing Ubuntu-family distribution to avoid accidentally
REM installing over an existing distro or moving it without a backup.
call :UbuntuRegistered
if not errorlevel 1 (
    if exist "%MARKER%" (
        echo Ubuntu is now registered after a previous install attempt.
        del /q "%MARKER%" >nul 2>&1
        goto ConfigureUbuntu
    ) else (
        echo Ubuntu is already registered in WSL.
        echo No changes were made, to avoid overwriting or relocating it.
        echo Check its name and version with: wsl --list --verbose
        pause
        exit /b 0
    )
)

if not exist "%WSL_ROOT%" md "%WSL_ROOT%"
if not exist "%INSTALL_DIR%" md "%INSTALL_DIR%"

REM Allow a non-empty target only when this script previously attempted
REM the installation and left its marker for a safe retry after reboot.
if not exist "%MARKER%" (
    set "DIR_NOT_EMPTY="
    for /f "delims=" %%F in ('dir /b /a "%INSTALL_DIR%" 2^>nul') do set "DIR_NOT_EMPTY=1"
    if defined DIR_NOT_EMPTY (
        echo ERROR: "%INSTALL_DIR%" is not empty, and no pending-install marker exists.
        echo Nothing was changed. Choose an empty folder or inspect the existing files first.
        pause
        exit /b 1
    )
    >"%MARKER%" echo WSL Ubuntu installation in progress. Safe to delete after successful setup.
)

echo.
echo Installing WSL and Ubuntu into:
echo   %INSTALL_DIR%
echo.
echo Windows may require a restart. If this attempt cannot finish before reboot,
echo run this same BAT file again after Windows restarts.
echo.

wsl.exe --install --distribution "%DISTRO%" --location "%INSTALL_DIR%" --no-launch
set "WSL_INSTALL_RC=%errorlevel%"

call :UbuntuRegistered
if errorlevel 1 (
    echo.
    echo WSL/Ubuntu is not yet registered. Installer exit code: %WSL_INSTALL_RC%
    echo If Windows requested a restart, restart now and run this BAT file again.
    echo If no restart was requested, review the error above before retrying.
    echo The pending marker was kept so an interrupted install can be retried safely.
    pause
    exit /b 1
)

del /q "%MARKER%" >nul 2>&1

:ConfigureUbuntu
echo.
echo Configuring WSL 2...
wsl.exe --set-default-version 2
if errorlevel 1 echo WARNING: Could not set WSL 2 as the default. Check the error above.

wsl.exe --set-version "%DISTRO%" 2
if errorlevel 1 echo WARNING: Could not explicitly set Ubuntu to WSL 2. Check the error above.

echo.
echo WSL distributions:
wsl.exe --list --verbose

echo.
echo Installation step complete.
echo Next: open Ubuntu from the Start menu and create your Linux username and password.
echo Ubuntu's intended location: %INSTALL_DIR%
pause
exit /b 0

:UbuntuRegistered
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$lines = @(& wsl.exe --list --quiet 2>$null | ForEach-Object { ($_ -replace [char]0, '').Trim() }); if ($lines -match '^Ubuntu($|[- ])') { exit 0 } else { exit 1 }"
exit /b %errorlevel%
