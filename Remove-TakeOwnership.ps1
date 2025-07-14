# Remove-TakeOwnership.ps1
# Cleans up "Take Ownership" context menu entries
# Updated: Targets custom \shell\TakeOwnership paths.

. "$PSScriptRoot\Lib-BackupRegistry.ps1"

# Elevation check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh.exe "-File `"$PSCommandPath`"" -Verb RunAs
    return
}

# Confirmation prompt
$confirm = Read-Host "Remove 'Take Ownership' context menu? This modifies registry (y/n)"
if ($confirm -ne 'y') { Write-Host "❌ Operation cancelled." -ForegroundColor Yellow; return }

# Logging setup
$logPath = "$PSScriptRoot\TurboTweak.log"
Add-Content -Path $logPath -Value "$(Get-Date): Starting Remove-TakeOwnership"

$keys = @(
    "HKEY_CLASSES_ROOT\*\shell\TakeOwnership",
    "HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership",
    "HKEY_CLASSES_ROOT\Drive\shell\TakeOwnership"
)

# Backup
try {
    Backup-Registry $keys "TakeOwnership_Remove"
    Add-Content $logPath -Value "$(Get-Date): Backup completed"
} catch {
    Write-Host "⚠️ Backup failed: $_ (continuing)." -ForegroundColor Yellow
    Add-Content $logPath -Value "$(Get-Date): Backup warning: $_"
}

# Remove keys
try {
    foreach ($key in $keys) {
        reg delete $key /f | Out-Null
    }
    Write-Host "🚫 'Take Ownership' context menu removed." -ForegroundColor Yellow
    Add-Content $logPath -Value "$(Get-Date): Removed successfully"
} catch {
    Write-Host "Warning removing keys: $_" -ForegroundColor Yellow
    Add-Content $logPath -Value "$(Get-Date): Removal warning: $_"
}

Add-Content $logPath -Value "$(Get-Date): Completed Remove-TakeOwnership"

# Optional Explorer restart
$restartConfirm = Read-Host "Restart Windows Explorer to apply changes immediately? (y/n)"
if ($restartConfirm -eq 'y') {
    try {
        Stop-Process -Name explorer -Force
        Write-Host "🛡️ Explorer restarted." -ForegroundColor Green
        Add-Content $logPath -Value "$(Get-Date): Explorer restarted"
    } catch {
        Write-Host "⚠️ Explorer restart failed: $_" -ForegroundColor Yellow
        Add-Content $logPath -Value "$(Get-Date): Explorer restart warning: $_"
    }
}