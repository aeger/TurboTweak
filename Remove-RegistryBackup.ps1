# Remove-RegistryBackup.ps1
# Disables built-in registry backup engine

. "$PSScriptRoot\Lib-BackupRegistry.ps1"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh.exe "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$confirm = Read-Host "Disable registry backup service? (y/n)"
if ($confirm -ne 'y') { Write-Host "❌ Cancelled." -ForegroundColor Yellow; exit }

$logPath = "$PSScriptRoot\TurboTweak.log"
Add-Content -Path $logPath -Value "$(Get-Date): Starting Remove-RegistryBackup"

$key = "HKLM:\System\CurrentControlSet\Control\Session Manager\Configuration Manager"
$keys = @($key)

try {
    Backup-Registry $keys "RegistryBackup_Remove"
    Add-Content $logPath -Value "$(Get-Date): Backup completed"
} catch {
    Write-Host "⚠️ Backup failed: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Backup error: $_"
    exit
}

try {
    Set-ItemProperty -Path $key -Name "EnablePeriodicBackup" -Value 0 -Type DWord
    Write-Host "🚫 Registry backup disabled." -ForegroundColor Yellow
    Add-Content $logPath -Value "$(Get-Date): Disabled successfully"
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Error: $_"
}

Add-Content $logPath -Value "$(Get-Date): Completed Remove-RegistryBackup"