# Add-RegistryBackup.ps1
# Enables built-in registry backup engine (if disabled)

. "$PSScriptRoot\Lib-BackupRegistry.ps1"

$key = "HKLM:\System\CurrentControlSet\Control\Session Manager\Configuration Manager"
Backup-Registry @($key) "RegistryBackup"

New-Item -Path $key -Force | Out-Null
Set-ItemProperty -Path $key -Name "EnablePeriodicBackup" -Value 1 -Type DWord

Write-Host "🛡️ Registry backup service enabled. Windows will periodically back up the registry automatically." -ForegroundColor Green
