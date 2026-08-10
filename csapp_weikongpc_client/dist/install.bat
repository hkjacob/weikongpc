@echo off
setlocal EnableExtensions
set "WKP_DIR=%~dp0"
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$lines = Get-Content -LiteralPath '%~f0' -Encoding UTF8; $idx = [Array]::IndexOf($lines, '#__WKP_PS_START__'); $s = ($lines | Select-Object -Skip ($idx + 1)) -join [char]10; Invoke-Expression $s"
if %errorlevel% neq 0 (
    echo.
    echo Installation FAILED. Check messages above.
    pause
)
exit /b
#__WKP_PS_START__
$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$Msg)
    Write-Host ("[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $Msg) -ForegroundColor Green
}

Write-Host ''
Write-Host '=========================================='
Write-Host ' 微控儿童电脑 PC 客户端 - 安装程序'
Write-Host '=========================================='
Write-Host ''

$InstallPath = 'C:\Program Files\WeikongPC'
$ServiceName = 'WeikongPC'
$SourceDir = $env:WKP_DIR

# 1. Windows version check
$os = Get-CimInstance Win32_OperatingSystem
$osVersion = [Version]$os.Version
Write-Log ("OS: {0} ({1})" -f $os.Caption, $osVersion.ToString())
if ($osVersion -lt [Version]"10.0.14393") {
    Write-Host '错误：需要 Windows 10 1607 或更高版本。' -ForegroundColor Red
    exit 1
}

# 2. Stop running service / process (exe may be locked)
$existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Log '发现已存在的服务，正在停止...'
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}
$runningProc = Get-Process -Name "WeikongPC" -ErrorAction SilentlyContinue
if ($runningProc) {
    Write-Log '正在结束残留的 WeikongPC.exe 进程...'
    Stop-Process -Name "WeikongPC" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# 3. Create install directory
Write-Log "创建目录: $InstallPath"
New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
New-Item -ItemType Directory -Path "$InstallPath\logs" -Force | Out-Null

# 4. Copy files
Write-Log '正在复制文件...'
Copy-Item "$SourceDir\WeikongPC.exe" "$InstallPath\WeikongPC.exe" -Force

# 5. Generate uid/key if ini not exists
$iniPath = "$InstallPath\WeikongPC.ini"
if (-not (Test-Path $iniPath)) {
    Write-Log '正在生成设备标识...'
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
    $iniContent = @"
; ============================================================================
; WeikongPC Client Config (WeikongPC.ini)
; ============================================================================

[server]
url=https://weikongpc.com/beat

[device]
uid=$uid
uid_key=$key
os=$($os.Caption)
name=$env:COMPUTERNAME
"@
    Set-Content -Path $iniPath -Value $iniContent -Encoding UTF8
    Write-Log "已生成 uid: $uid"
    Write-Log "已生成 key: $key"
} else {
    Write-Log 'ini 已存在，保留原有设备标识'
    $iniContent = Get-Content $iniPath
    $uid = ($iniContent | Where-Object { $_ -match "^uid=" }) -replace "uid=", ""
    $key = ($iniContent | Where-Object { $_ -match "^uid_key=" }) -replace "uid_key=", ""
    Write-Log "已有 uid: $uid"
}

# 6. Remove existing service definition
$existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Log '正在删除旧服务...'
    sc.exe delete $ServiceName | Out-Null
    Start-Sleep -Seconds 1
}

# 7. Register service
Write-Log "正在注册服务: $ServiceName"
$binPath = "`"$InstallPath\WeikongPC.exe`""
sc.exe create $ServiceName binPath= $binPath start= auto | Out-Null
sc.exe description $ServiceName "WeikongPC PC client - process reporting and command execution" | Out-Null
sc.exe config $ServiceName DisplayName= "WeikongPC Report Service" | Out-Null
sc.exe failure $ServiceName reset= 86400 actions= restart/60000/restart/60000/restart/60000 | Out-Null

# 8. Start service
Write-Log '正在启动服务...'
Start-Service -Name $ServiceName
Start-Sleep -Seconds 2
$status = (Get-Service -Name $ServiceName).Status
Write-Log "服务状态: $status"

# 9. Wait 5s for first beat, then open bind page
Write-Log '等待 5 秒，等待客户端首次上报...'
Start-Sleep -Seconds 5
Write-Log '正在打开浏览器绑定页面...'
$ts = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$bindUrl = "https://weikongpc.com/bind?uid=$uid&uid_key=$key&ts=$ts"
Start-Process $bindUrl

Write-Host ''
Write-Host '=========================================='
Write-Host ' 安装完成！'
Write-Host '=========================================='
Write-Host ''
Write-Host "服务: $ServiceName (状态: $status)"
Write-Host "安装路径: $InstallPath"
Write-Host "绑定链接: $bindUrl"
Write-Host ''
Write-Host '后续步骤：'
Write-Host '  1. 用手机微信扫描浏览器中的二维码'
Write-Host '  2. 关注公众号「微控儿童电脑PC」即完成绑定'
Write-Host ''
