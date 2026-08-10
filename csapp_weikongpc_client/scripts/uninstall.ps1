# ============================================================================
# WeikongPC Uninstall Script (uninstall.ps1)
# Run as Administrator: right-click -> Run with PowerShell
# ============================================================================

# Require Administrator
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Error: Please run as Administrator" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$ErrorActionPreference = "Stop"
$InstallPath = "C:\Program Files\WeikongPC"
$ServiceName = "WeikongPC"

function Write-Log {
    param([string]$Msg)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Msg" -ForegroundColor Yellow
}

Write-Log "=========================================="
Write-Log "WeikongPC Uninstall Script"
Write-Log "=========================================="

# --- 1. Stop service ---
$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($svc) {
    Write-Log "Stopping service: $ServiceName"
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
} else {
    Write-Log "Service not found, skipping stop"
}

# --- 2. Delete service ---
$wmi = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'" -ErrorAction SilentlyContinue
if ($wmi) {
    Write-Log "Deleting service: $ServiceName"
    sc.exe delete $ServiceName | Out-Null
    Start-Sleep -Seconds 1
} else {
    Write-Log "Service not found, skipping delete"
}

# --- 3. Remove files ---
if (Test-Path $InstallPath) {
    Write-Log "Removing files: $InstallPath"
    Remove-Item -Path $InstallPath -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path $InstallPath) {
        Write-Log "Some files could not be removed (may be in use). Please delete manually."
    }
} else {
    Write-Log "Install path not found: $InstallPath"
}

Write-Log "=========================================="
Write-Log "Uninstall complete!"
Write-Log "=========================================="
Read-Host "Press Enter to exit"