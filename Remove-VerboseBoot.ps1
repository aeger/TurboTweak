# Remove-VerboseBoot.ps1
# Disables verbose boot messages

. "$PSScriptRoot\Lib-BackupRegistry.ps1"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh.exe "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$confirm = Read-Host "Disable verbose boot messages? (y/n)"
if ($confirm -ne 'y') { Write-Host "❌ Cancelled." -ForegroundColor Yellow; exit }

$logPath = "$PSScriptRoot\TurboTweak.log"
Add-Content -Path $logPath -Value "$(Get-Date): Starting Remove-VerboseBoot"

$key = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$keys = @($key)

try {
    Backup-Registry $keys "VerboseBoot_Remove"
    Add-Content $logPath -Value "$(Get-Date): Backup completed"
} catch {
    Write-Host "⚠️ Backup failed: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Backup error: $_"
    exit
}

try {
    Set-ItemProperty -Path $key -Name "verbosestatus" -Value 0 -Type DWord  # Or Remove-ItemProperty for full default
    Write-Host "🚫 Disabled." -ForegroundColor Yellow
    Add-Content $logPath -Value "$(Get-Date): Removed successfully"
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Error: $_"
}

Add-Content $logPath -Value "$(Get-Date): Completed Remove-VerboseBoot"