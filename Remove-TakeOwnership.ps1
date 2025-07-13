# Remove-TakeOwnership.ps1
# Cleans up "Take Ownership" context menu entries
# Improved: Targets \shell\runas paths, error handling, confirmation, logging, optional Explorer restart.

. "$PSScriptRoot\Lib-BackupRegistry.ps1"

# Elevation check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh.exe "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Confirmation prompt
$confirm = Read-Host "Remove 'Take Ownership' context menu? This modifies registry (y/n)"
if ($confirm -ne 'y') { Write-Host "❌ Operation cancelled." -ForegroundColor Yellow; exit }

# Logging setup
$logPath = "$PSScriptRoot\TurboTweak.log"
Add-Content -Path $logPath -Value "$(Get-Date): Starting Remove-TakeOwnership"

$keys = @(
    "HKEY_CLASSES_ROOT\*\shell\runas",
    "HKEY_CLASSES_ROOT\*\shell\runas\command",
    "HKEY_CLASSES_ROOT\Directory\shell\runas",
    "HKEY_CLASSES_ROOT\Directory\shell\runas\command",
    "HKEY_CLASSES_ROOT\Drive\shell\runas",
    "HKEY_CLASSES_ROOT\Drive\shell\runas\command"
)

# Backup
try {
    Backup-Registry $keys "TakeOwnership_Remove"
    Add-Content $logPath -Value "$(Get-Date): Backup completed"
} catch {
    Write-Host "⚠️ Backup failed: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Backup error: $_"
    exit
}

# Remove keys
try {
    foreach ($key in $keys) {
        Remove-Item -Path ("Registry::" + $key) -Recurse -ErrorAction Stop
    }
    Write-Host "🚫 'Take Ownership' context menu removed." -ForegroundColor Yellow
    Add-Content $logPath -Value "$(Get-Date): Removed successfully"
} catch {
    Write-Host "Error removing keys: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Removal error: $_"
}

Add-Content $logPath -Value "$(Get-Date): Completed Remove-TakeOwnership"

# Optional Explorer restart
$restartConfirm = Read-Host "Restart Windows Explorer to apply changes immediately? (Recommended; y/n)"
if ($restartConfirm -eq 'y') {
    try {
        Stop-Process -Name explorer -Force
        Write-Host "🛡️ Explorer restarted successfully." -ForegroundColor Green
        Add-Content $logPath -Value "$(Get-Date): Explorer restarted"
    } catch {
        Write-Host "⚠️ Failed to restart Explorer: $_. Please restart manually via Task Manager." -ForegroundColor Red
        Add-Content $logPath -Value "$(Get-Date): Explorer restart error: $_"
    }
}