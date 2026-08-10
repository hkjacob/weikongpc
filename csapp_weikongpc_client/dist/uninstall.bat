@echo off
rem ============================================================================
rem WeikongPC Uninstall Helper
rem Double-click to uninstall (BAT is not blocked by PowerShell execution policy)
rem ============================================================================

rem Request administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ==========================================
echo  WeikongPC Client Uninstall
echo ==========================================
echo.

rem Run uninstall.ps1 with execution policy bypass
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"

if %errorlevel% equ 0 (
    echo.
    echo Uninstall finished successfully.
) else (
    echo.
    echo Uninstall failed. See messages above.
)

pause
