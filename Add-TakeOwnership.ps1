# Add-TakeOwnership.ps1
# Adds "Take Ownership" right-click context menu entries for files, directories, and drives.
# Simplified: Uses reg add for permission-bypassing creation, no DllImport, warnings on failure, returns to menu.

. "$PSScriptRoot\Lib-BackupRegistry.ps1"

# Elevation check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh.exe "-File `"$PSCommandPath`"" -Verb RunAs
    return
}

# Confirmation prompt
$confirm = Read-Host "Add 'Take Ownership' context menu? This modifies registry (y/n)"
if ($confirm -ne 'y') { Write-Host "❌ Operation cancelled." -ForegroundColor Yellow; return }

# Logging setup
$logPath = "$PSScriptRoot\TurboTweak.log"
Add-Content -Path $logPath -Value "$(Get-Date): Starting Add-TakeOwnership"

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
    Backup-Registry $keys "TakeOwnership"
    Add-Content $logPath -Value "$(Get-Date): Backup completed"
} catch {
    Write-Host "⚠️ Backup failed: $_ (continuing)." -ForegroundColor Yellow
    Add-Content $logPath -Value "$(Get-Date): Backup warning: $_"
}

# Commands
$cmd_file = 'cmd.exe /c takeown /f "%1" && icacls "%1" /grant *S-1-3-4:F /t /c /l'
$cmd_dir = 'cmd.exe /c takeown /f "%1" /r /d y && icacls "%1" /grant *S-1-3-4:F /t /c /q'
$cmd_drive = 'cmd.exe /c takeown /f "%1" /r /d y && icacls "%1" /grant *S-1-3-4:F /t /c'

# Apply using reg add to avoid permission issues
try {
    # For files
    reg add "HKEY_CLASSES_ROOT\*\shell\runas" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\*\shell\runas" /ve /d "Take Ownership" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\*\shell\runas\command" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\*\shell\runas\command" /ve /d $cmd_file /f | Out-Null
    Write-Host "✅ Added for files." -ForegroundColor Green
    Add-Content $logPath -Value "$(Get-Date): Added for files"
} catch {
    Write-Host "Warning adding for files: $_" -ForegroundColor Yellow
    Add-Content $logPath -Value "$(Get-Date): Warning for files: $_"
}

try {
    # For directories
    reg add "HKEY_CLASSES_ROOT\Directory\shell\runas" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\Directory\shell\runas" /ve /d "Take Ownership" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\Directory\shell\runas\command" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\Directory\shell\runas\command" /ve /d $cmd_dir /f | Out-Null
    Write-Host "✅ Added for directories." -ForegroundColor Green
    Add-Content $logPath -Value "$(Get-Date): Added for directories"
} catch {
    Write-Host "Warning adding for directories: $_" -ForegroundColor Yellow
    Add-Content $logPath -Value "$(Get-Date): Warning for directories: $_"
}

try {
    # For drives
    reg add "HKEY_CLASSES_ROOT\Drive\shell\runas" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\Drive\shell\runas" /ve /d "Take Ownership" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\Drive\shell\runas\command" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\Drive\shell\runas\command" /ve /d $cmd_drive /f | Out-Null
    Write-Host "✅ Added for drives." -ForegroundColor Green
    Add-Content $logPath -Value "$(Get-Date): Added for drives"
} catch {
    Write-Host "Warning adding for drives: $_" -ForegroundColor Yellow
    Add-Content $logPath -Value "$(Get-Date): Warning for drives: $_"
}

Write-Host "✅ 'Take Ownership' context menu added (or partially). Log at $logPath" -ForegroundColor Green
Add-Content $logPath -Value "$(Get-Date): Completed Add-TakeOwnership"

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