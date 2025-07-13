# Add-TakeOwnership.ps1
# Adds "Take Ownership" right-click context menu entries

. "$PSScriptRoot\Lib-BackupRegistry.ps1"

$keys = @(
    "HKEY_CLASSES_ROOT\*\shell\TakeOwnership",
    "HKEY_CLASSES_ROOT\*\shell\TakeOwnership\command",
    "HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership",
    "HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership\command",
    "HKEY_CLASSES_ROOT\Drive\shell\runas",
    "HKEY_CLASSES_ROOT\Drive\shell\runas\command"
)

Backup-Registry $keys "TakeOwnership"

$cmd1 = 'powershell -windowstyle hidden -command "Start-Process cmd -ArgumentList ''/c takeown /f \"%1\" && icacls \"%1\" /grant *S-1-3-4:F /t /c /l'' -Verb runAs"'
$cmd2 = 'powershell -windowstyle hidden -command "$Y = ($null | choice).Substring(1,1); Start-Process cmd -ArgumentList ''/c takeown /f \"%1\" /r /d '' + $Y + '' && icacls \"%1\" /grant *S-1-3-4:F /t /c /l /q'' -Verb runAs"'
$cmd3 = 'cmd.exe /c takeown /f \"%1\" /r /d y && icacls \"%1\" /grant *S-1-3-4:F /t /c'

New-Item -Path "Registry::HKEY_CLASSES_ROOT\*\shell\TakeOwnership" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\*\shell\TakeOwnership" -Name "(default)" -Value "Take Ownership"
New-Item -Path "Registry::HKEY_CLASSES_ROOT\*\shell\TakeOwnership\command" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\*\shell\TakeOwnership\command" -Name "(default)" -Value $cmd1

New-Item -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership" -Name "(default)" -Value "Take Ownership"
New-Item -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership\command" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership\command" -Name "(default)" -Value $cmd2

New-Item -Path "Registry::HKEY_CLASSES_ROOT\Drive\shell\runas" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Drive\shell\runas" -Name "(default)" -Value "Take Ownership"
New-Item -Path "Registry::HKEY_CLASSES_ROOT\Drive\shell\runas\command" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Drive\shell\runas\command" -Name "(default)" -Value $cmd3

Write-Host "✅ 'Take Ownership' context menu added." -ForegroundColor Green
