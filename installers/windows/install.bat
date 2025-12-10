@echo off
REM PacketCloak Installer Wrapper for Windows
REM Author: Walter Hofstetter
REM License: GPL-2.0
REM Repository: https://github.com/netwho/PacketCloak

setlocal

echo.
echo ======================================================
echo   PacketCloak Installer for Windows v0.2.0
echo ======================================================
echo.
echo Author: Walter Hofstetter
echo License: GPL-2.0
echo.
echo Starting PowerShell installer...
echo.

REM Run PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "%~dp0install.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Installation encountered an error.
    echo.
    echo If you see an execution policy error, try running:
    echo   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    echo.
    echo Or run PowerShell as Administrator.
    echo.
)

pause
