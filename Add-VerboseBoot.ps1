# Add-VerboseBoot.ps1
# Enables detailed boot/shutdown status messages

. "$PSScriptRoot\Lib-BackupRegistry.ps1"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh.exe "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$confirm = Read-Host "Enable verbose boot messages? (y/n)"
if ($confirm -ne 'y') { Write-Host "❌ Cancelled." -ForegroundColor Yellow; exit }

$logPath = "$PSScriptRoot\TurboTweak.log"
Add-Content -Path $logPath -Value "$(Get-Date): Starting Add-VerboseBoot"

$key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$keys = @($key)

try {
    Backup-Registry $keys "VerboseBoot"
    Add-Content $logPath -Value "$(Get-Date): Backup completed"
} catch {
    Write-Host "⚠️ Backup failed: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Backup error: $_"
    exit
}

try {
    New-Item -Path $key -Force | Out-Null
    Set-ItemProperty -Path $key -Name "verbosestatus" -Value 1 -Type DWord
    Write-Host "🧠 Enabled. Detailed info on startup/shutdown." -ForegroundColor Cyan
    Add-Content $logPath -Value "$(Get-Date): Applied successfully"
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Error: $_"
}

Add-Content $logPath -Value "$(Get-Date): Completed Add-VerboseBoot"