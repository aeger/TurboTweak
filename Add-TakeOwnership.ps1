# Add-TakeOwnership.ps1
# Adds "Take Ownership" right-click context menu entries for files, directories, and drives.
# Updated: Uses custom \shell\TakeOwnership to avoid conflicting with built-in RunAs verb; best practice for shell tweaks.

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
    "HKEY_CLASSES_ROOT\*\shell\TakeOwnership",
    "HKEY_CLASSES_ROOT\*\shell\TakeOwnership\command",
    "HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership",
    "HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership\command",
    "HKEY_CLASSES_ROOT\Drive\shell\TakeOwnership",
    "HKEY_CLASSES_ROOT\Drive\shell\TakeOwnership\command"
)

# Backup
try {
    Backup-Registry $keys "TakeOwnership"
    Add-Content $logPath -Value "$(Get-Date): Backup completed"
} catch {
    Write-Host "⚠️ Backup failed: $_ (continuing)." -ForegroundColor Yellow
    Add-Content $logPath -Value "$(Get-Date): Backup warning: $_"
}

# Commands (requires manual UAC on use, but no conflict)
$cmd_file = 'cmd.exe /k takeown /f "%1" && icacls "%1" /grant *S-1-3-4:F /t /c /l && pause'
$cmd_dir = 'cmd.exe /k takeown /f "%1" /r /d y && icacls "%1" /grant *S-1-3-4:F /t /c /q && pause'
$cmd_drive = 'cmd.exe /k takeown /f "%1" /r /d y && icacls "%1" /grant *S-1-3-4:F /t /c && pause'

# Apply using reg add
try {
    reg add "HKEY_CLASSES_ROOT\*\shell\TakeOwnership" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\*\shell\TakeOwnership" /ve /d "Take Ownership" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\*\shell\TakeOwnership" /v "NoWorkingDirectory" /d "" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\*\shell\TakeOwnership" /v "Extended" /d "" /f | Out-Null  # Optional: Shift+Right-click only
    reg add "HKEY_CLASSES_ROOT\*\shell\TakeOwnership\command" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\*\shell\TakeOwnership\command" /ve /d $cmd_file /f | Out-Null
    Write-Host "✅ Added for files." -ForegroundColor Green
    Add-Content $logPath -Value "$(Get-Date): Added for files"
} catch {
    Write-Host "Warning adding for files: $_" -ForegroundColor Yellow
    Add-Content $logPath -Value "$(Get-Date): Warning for files: $_"
}

try {
    reg add "HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership" /ve /d "Take Ownership" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership" /v "NoWorkingDirectory" /d "" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership" /v "Extended" /d "" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership\command" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership\command" /ve /d $cmd_dir /f | Out-Null
    Write-Host "✅ Added for directories." -ForegroundColor Green
    Add-Content $logPath -Value "$(Get-Date): Added for directories"
} catch {
    Write-Host "Warning adding for directories: $_" -ForegroundColor Yellow
    Add-Content $logPath -Value "$(Get-Date): Warning for directories: $_"
}

try {
    reg add "HKEY_CLASSES_ROOT\Drive\shell\TakeOwnership" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\Drive\shell\TakeOwnership" /ve /d "Take Ownership" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\Drive\shell\TakeOwnership" /v "NoWorkingDirectory" /d "" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\Drive\shell\TakeOwnership" /v "Extended" /d "" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\Drive\shell\TakeOwnership\command" /f | Out-Null
    reg add "HKEY_CLASSES_ROOT\Drive\shell\TakeOwnership\command" /ve /d $cmd_drive /f | Out-Null
    Write-Host "✅ Added for drives." -ForegroundColor Green
    Add-Content $logPath -Value "$(Get-Date): Added for drives"
} catch {
    Write-Host "Warning adding for drives: $_" -ForegroundColor Yellow
    Add-Content $logPath -Value "$(Get-Date): Warning for drives: $_"
}

Write-Host "✅ 'Take Ownership' context menu added. Log at $logPath" -ForegroundColor Green
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