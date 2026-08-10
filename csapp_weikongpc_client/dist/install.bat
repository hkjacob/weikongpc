@echo off
rem ============================================================================
rem WeikongPC Install Helper
rem Double-click to install (BAT is not blocked by PowerShell execution policy)
rem ============================================================================

rem Request administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ==========================================
echo  WeikongPC Client Installation
echo ==========================================
echo.

rem Run install.ps1 with execution policy bypass
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"

if %errorlevel% equ 0 (
    echo.
    echo Installation finished successfully.
) else (
    echo.
    echo Installation failed. See messages above.
)

pause
