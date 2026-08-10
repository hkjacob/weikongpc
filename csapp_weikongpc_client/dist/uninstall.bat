@echo off
setlocal EnableExtensions
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$lines = Get-Content -LiteralPath '%~f0' -Encoding UTF8; $idx = [Array]::IndexOf($lines, '#__WKP_PS_START__'); $s = ($lines | Select-Object -Skip ($idx + 1)) -join [char]10; Invoke-Expression $s"
if %errorlevel% neq 0 (
    echo.
    echo Uninstall FAILED. Check messages above.
    pause
)
exit /b
#__WKP_PS_START__
$ErrorActionPreference = 'Stop'

Write-Host ''
Write-Host '=========================================='
Write-Host ' 微控儿童电脑 PC 客户端 - 卸载程序'
Write-Host '=========================================='
Write-Host ''

$InstallPath = 'C:\Program Files\WeikongPC'
$ServiceName = 'WeikongPC'

# 1. Stop service
$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($svc) {
    Write-Host '正在停止服务...'
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
} else {
    Write-Host '未找到服务，跳过停止。'
}

# 2. Delete service
$wmi = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'" -ErrorAction SilentlyContinue
if ($wmi) {
    Write-Host '正在删除服务...'
    sc.exe delete $ServiceName | Out-Null
    Start-Sleep -Seconds 1
} else {
    Write-Host '未找到服务，跳过删除。'
}

# 3. Remove files
if (Test-Path $InstallPath) {
    Write-Host "正在清理文件: $InstallPath"
    Remove-Item -Path $InstallPath -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path $InstallPath) {
        Write-Host '部分文件无法删除（可能正在使用），请手动清理。'
    }
} else {
    Write-Host "未找到安装目录: $InstallPath"
}

Write-Host ''
Write-Host '=========================================='
Write-Host ' 卸载完成！'
Write-Host '=========================================='
Write-Host ''
