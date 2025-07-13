# Remove-Performance.ps1
# Removes performance tweaks and restores defaults

. "$PSScriptRoot\Lib-BackupRegistry.ps1"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh.exe "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$confirm = Read-Host "Remove performance tweaks and restore defaults? (y/n)"
if ($confirm -ne 'y') { Write-Host "❌ Cancelled." -ForegroundColor Yellow; exit }

$logPath = "$PSScriptRoot\TurboTweak.log"
Add-Content -Path $logPath -Value "$(Get-Date): Starting Remove-Performance"

$keys = @(
    "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize",
    "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
)

try {
    Backup-Registry $keys "Performance_Remove"
    Add-Content $logPath -Value "$(Get-Date): Backup completed"
} catch {
    Write-Host "⚠️ Backup failed: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Backup error: $_"
    exit
}

try {
    # Remove Serialize properties (key may remain if other values)
    Remove-ItemProperty -Path $keys[0] -Name "StartupDelayInMSec" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $keys[0] -Name "WaitforIdleState" -ErrorAction SilentlyContinue
    # If Serialize now empty, remove it
    if ((Get-ItemProperty $keys[0]).PSChildName.Count -eq 0) { Remove-Item -Path $keys[0] -Recurse }

    Set-ItemProperty -Path $keys[1] -Name "SystemResponsiveness" -Value 20 -Type DWord
    Set-ItemProperty -Path $keys[1] -Name "NetworkThrottlingIndex" -Value 10 -Type DWord

    Write-Host "🚫 Tweaks removed, defaults restored." -ForegroundColor Yellow
    Add-Content $logPath -Value "$(Get-Date): Removed successfully"
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Error: $_"
}

Add-Content $logPath -Value "$(Get-Date): Completed Remove-Performance"