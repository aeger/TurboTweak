# Add-Performance.ps1
# Applies Windows performance & responsiveness registry tweaks

. "$PSScriptRoot\Lib-BackupRegistry.ps1"

# Elevation check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh.exe "-File `"$PSCommandPath`"" -Verb RunAs
    return
}

$confirm = Read-Host "Apply performance tweaks? Reboot recommended after (y/n)"
if ($confirm -ne 'y') { Write-Host "❌ Cancelled." -ForegroundColor Yellow; return }

$logPath = "$PSScriptRoot\TurboTweak.log"
Add-Content -Path $logPath -Value "$(Get-Date): Starting Add-Performance"

$keys = @(
    "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize",
    "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
)

try {
    Backup-Registry $keys "Performance"
    Add-Content $logPath -Value "$(Get-Date): Backup completed"
} catch {
    Write-Host "⚠️ Backup failed: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Backup error: $_"
    return  # Changed from exit for graceful return to menu
}

try {
    New-Item -Path $keys[0] -Force | Out-Null
    Set-ItemProperty -Path $keys[0] -Name "StartupDelayInMSec" -Value 0 -Type DWord
    # Optional: For Win11 compatibility
    Set-ItemProperty -Path $keys[0] -Name "WaitforIdleState" -Value 0 -Type DWord

    New-Item -Path $keys[1] -Force | Out-Null
    Set-ItemProperty -Path $keys[1] -Name "SystemResponsiveness" -Value 10 -Type DWord
    Set-ItemProperty -Path $keys[1] -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord

    Write-Host "⚡ Tweaks applied. Reboot for full effect." -ForegroundColor Green
    Add-Content $logPath -Value "$(Get-Date): Applied successfully"
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Error: $_"
}

Add-Content $logPath -Value "$(Get-Date): Completed Add-Performance"