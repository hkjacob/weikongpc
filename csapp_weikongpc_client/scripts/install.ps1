# ============================================================================
# WeikongPC Install Script (install.ps1)
# Run as Administrator: right-click -> Run with PowerShell
# ============================================================================

# Require Administrator
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Error: Please run as Administrator" -ForegroundColor Red
    Write-Host "Right-click this file -> Run with PowerShell (as Admin)"
    Read-Host "Press Enter to exit"
    exit 1
}

$ErrorActionPreference = "Stop"
$InstallPath = "C:\Program Files\WeikongPC"
$ServiceName = "WeikongPC"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Log {
    param([string]$Msg)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Msg" -ForegroundColor Green
}

Write-Log "=========================================="
Write-Log "WeikongPC Install Script"
Write-Log "=========================================="

# --- 1. Check Windows version (Win10 1607+) ---
$os = Get-CimInstance Win32_OperatingSystem
$osVersion = [Version]$os.Version
Write-Log "OS: $($os.Caption) ($($osVersion.ToString()))"
if ($osVersion -lt [Version]"10.0.14393") {
    Write-Host "Error: Windows 10 1607 or later required" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# --- 2. Stop running service/process FIRST (exe file may be locked) ---
$existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Log "Existing service found, stopping first..."
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# Also kill any running WeikongPC.exe process (e.g. debug mode)
$runningProc = Get-Process -Name "WeikongPC" -ErrorAction SilentlyContinue
if ($runningProc) {
    Write-Log "Killing running WeikongPC.exe process..."
    Stop-Process -Name "WeikongPC" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# --- 3. Create install directory ---
Write-Log "Creating directory: $InstallPath"
New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
New-Item -ItemType Directory -Path "$InstallPath\logs" -Force | Out-Null

# --- 4. Copy files ---
Write-Log "Copying files..."
Copy-Item "$ScriptDir\WeikongPC.exe" "$InstallPath\WeikongPC.exe" -Force

# --- 5. Generate uid and key (if ini not exists) ---
$iniPath = "$InstallPath\WeikongPC.ini"
if (-not (Test-Path $iniPath)) {
    Write-Log "Generating device identity..."

    $cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).ProcessorId
    $mb = (Get-CimInstance Win32_BaseBoard | Select-Object -First 1).SerialNumber
    $raw = "$cpu|$mb"
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($raw))
    $uid = (-join ($hash | ForEach-Object { $_.ToString("x2") })).Substring(0, 32)

    $chars = "abcdefghijkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789"
    $rnd = New-Object System.Random
    $key = ""
    for ($i = 0; $i -lt 16; $i++) { $key += $chars[$rnd.Next(0, $chars.Length)] }

    $osCaption = $os.Caption
    $machineName = $env:COMPUTERNAME
    $iniContent = @"
; ============================================================================
; WeikongPC Client Config (WeikongPC.ini)
; ============================================================================

[server]
url=https://weikongpc.com/beat

[device]
uid=$uid
uid_key=$key
os=$osCaption
name=$machineName
"@
    Set-Content -Path $iniPath -Value $iniContent -Encoding UTF8
    Write-Log "Generated uid: $uid"
    Write-Log "Generated key: $key"
} else {
    Write-Log "ini already exists, keeping existing identity"
    $iniContent = Get-Content $iniPath
    $uid = ($iniContent | Where-Object { $_ -match "^uid=" }) -replace "uid=", ""
    $key = ($iniContent | Where-Object { $_ -match "^uid_key=" }) -replace "uid_key=", ""
    Write-Log "Existing uid: $uid"
}

# --- 6. Remove existing service definition (if any) ---
$existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Log "Deleting existing service..."
    sc.exe delete $ServiceName | Out-Null
    Start-Sleep -Seconds 1
}

# --- 7. Register service ---
Write-Log "Registering service: $ServiceName"
$binPath = "`"$InstallPath\WeikongPC.exe`""
sc.exe create $ServiceName binPath= $binPath start= auto | Out-Null
sc.exe description $ServiceName "WeikongPC PC client - process reporting and command execution" | Out-Null
sc.exe config $ServiceName DisplayName= "WeikongPC Report Service" | Out-Null
sc.exe failure $ServiceName reset= 86400 actions= restart/60000/restart/60000/restart/60000 | Out-Null

# --- 8. Start service ---
Write-Log "Starting service..."
Start-Service -Name $ServiceName
Start-Sleep -Seconds 2
$status = (Get-Service -Name $ServiceName).Status
Write-Log "Service status: $status"

# --- 9. Wait 5s for client to send first beat, then open bind page ---
Write-Log "Waiting 5 seconds for the client to initialize..."
Start-Sleep -Seconds 5
Write-Log "Opening bind page in browser..."
$ts = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$bindUrl = "https://weikongpc.com/bind?uid=$uid&uid_key=$key&ts=$ts"
Start-Process $bindUrl

Write-Log "=========================================="
Write-Log "Install complete!"
Write-Log "=========================================="
Write-Log ""
Write-Log "Service: $ServiceName (Status: $status)"
Write-Log "Path: $InstallPath"
Write-Log "Bind URL: $bindUrl"
Write-Log ""
Write-Log "Next steps:"
Write-Log "  1. Follow the WeChat public account: WeikongPC"
Write-Log "  2. Bind this device in the WeChat menu"
Write-Log "  3. The service will auto-retry until bound"
Write-Log ""
Read-Host "Press Enter to exit"