# Add-VerboseBoot.ps1
# Enables detailed boot/shutdown status messages

. "$PSScriptRoot\Lib-BackupRegistry.ps1"

$key = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
Backup-Registry @($key) "VerboseBoot"

New-Item -Path $key -Force | Out-Null
Set-ItemProperty -Path $key -Name "verbosestatus" -Value 1 -Type DWord

Write-Host "🧠 Verbose Boot Messages enabled. You’ll see detailed startup and shutdown info." -ForegroundColor Cyan
