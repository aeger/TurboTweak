# Add-Performance.ps1
# Applies Windows performance & responsiveness registry tweaks

. "$PSScriptRoot\Lib-BackupRegistry.ps1"

$keys = @(
    "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize",
    "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
)

Backup-Registry $keys "Performance"

New-Item -Path $keys[0] -Force | Out-Null
Set-ItemProperty -Path $keys[0] -Name "StartupDelayInMSec" -Value 0 -Type DWord

Set-ItemProperty -Path $keys[1] -Name "SystemResponsiveness" -Value 10 -Type DWord
Set-ItemProperty -Path $keys[1] -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord

Write-Host "⚡ Performance tweaks applied. UI should feel snappier after reboot." -ForegroundColor Green
