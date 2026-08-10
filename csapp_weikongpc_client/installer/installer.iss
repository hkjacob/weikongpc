; ============================================================================
; WeikongPC Installer Script (installer.iss)
; Inno Setup 6.x
; Modes: install / repair / uninstall
; Service registration delegated to WeikongPC.exe install/uninstall
; ============================================================================

#define MyAppName "WeikongPC Client"
#define MyAppShortName "WeikongPC"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "weikongpc.com"
#define MyAppURL "https://weikongpc.com/"
#define MyAppCopyright "(C) 2026 weikongpc.com"

#define MyInstallDir "C:\Program Files\WeikongPC"

#define SetupHelperPath "scripts\setup-helper.ps1"
#define SuccessWindowPath "scripts\success-window.ps1"
#define WechatQrFile "assets\wechat-qr.jpg"

[Setup]
AppId={{A8F4E5B7-1234-4567-8901-23456789ABCD}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
AppCopyright={#MyAppCopyright}

DefaultDirName={#MyInstallDir}
LicenseFile=assets\LICENSE.txt

OutputDir=output
OutputBaseFilename=WeikongPC-Setup-{#MyAppVersion}

; Use normal compression for faster install (was ultra64, caused slowness)
Compression=lzma2/normal
SolidCompression=yes

PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog

MinVersion=10.0

UninstallDisplayIcon={app}\WeikongPC.exe
UninstallDisplayName={#MyAppName}

[Files]
Source: "..\cswsv_weikongpc_report\bin\Release\net8.0-windows\win-x64\publish\WeikongPC.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SetupHelperPath}"; DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "{#SuccessWindowPath}"; DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "{#WechatQrFile}"; DestDir: "{app}"; Flags: ignoreversion

[Dirs]
Name: "{app}\logs"

[Icons]
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"

[Run]
; 1. Generate ini + QR code via PowerShell helper
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-ExecutionPolicy Bypass -NoProfile -File ""{app}\scripts\setup-helper.ps1"" -Mode install -InstallPath ""{app}"" -QrOutputPath ""{app}\ini-qr.png"""; Flags: waituntilterminated runhidden

; 2. Register service via WeikongPC.exe install (program knows its own path)
Filename: "{app}\WeikongPC.exe"; Parameters: "install"; Flags: waituntilterminated runhidden

; 3. Show success window with QR codes
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-ExecutionPolicy Bypass -NoProfile -File ""{app}\scripts\success-window.ps1"" -WechatQrPath ""{app}\wechat-qr.jpg"" -IniQrPath ""{app}\ini-qr.png"" -IniContent ""See WeikongPC.ini"""; Flags: waituntilterminated

[UninstallRun]
; 1. Unregister service via WeikongPC.exe uninstall
Filename: "{app}\WeikongPC.exe"; Parameters: "uninstall"; Flags: waituntilterminated runhidden; RunOnceId: "StopService"

; 2. Run helper cleanup
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-ExecutionPolicy Bypass -NoProfile -File ""{app}\scripts\setup-helper.ps1"" -Mode uninstall -InstallPath ""{app}"""; Flags: waituntilterminated runhidden

[UninstallDelete]
Type: filesandordirs; Name: "{app}\WeikongPC.ini"
Type: filesandordirs; Name: "{app}\WeikongPC.log"
Type: filesandordirs; Name: "{app}\ini-qr.png"
Type: filesandordirs; Name: "{app}\logs"
Type: filesandordirs; Name: "{app}\scripts"