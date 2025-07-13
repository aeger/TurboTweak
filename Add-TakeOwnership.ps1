# Add-TakeOwnership.ps1
# Adds "Take Ownership" right-click context menu entries for files, directories, and drives.
# Improved: Uses \shell\runas for consistent elevation, hardcoded /d y (English), error handling, confirmation, logging.
# New: Takes ownership and grants permissions on parent keys to handle access denied errors; optional Explorer restart.

. "$PSScriptRoot\Lib-BackupRegistry.ps1"  # Assume improved lib with fallback path

# Elevation check (for standalone run)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh.exe "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Function to take ownership and grant full control
function Set-RegistryPermissions {
    param (
        [string]$path
    )
    try {
        $acl = Get-Acl $path
        $originalAcl = $acl  # Backup original ACL for potential restore

        $admin = New-Object System.Security.Principal.NTAccount("BUILTIN\Administrators")
        $acl.SetOwner($admin)
        Set-Acl $path $acl

        $rule = New-Object System.Security.AccessControl.RegistryAccessRule("BUILTIN\Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.AddAccessRule($rule)
        Set-Acl $path $acl

        Write-Host "🔑 Permissions granted for $path." -ForegroundColor Cyan
        Add-Content $logPath -Value "$(Get-Date): Granted permissions for $path"

        # Optional: Return original ACL if you want to restore later
        return $originalAcl
    } catch {
        Write-Host "⚠️ Failed to set permissions for $path: $_" -ForegroundColor Red
        Add-Content $logPath -Value "$(Get-Date): Permissions error for $path: $_"
        exit
    }
}

# Confirmation prompt
$confirm = Read-Host "Add 'Take Ownership' context menu? This modifies registry (y/n)"
if ($confirm -ne 'y') { Write-Host "❌ Operation cancelled." -ForegroundColor Yellow; exit }

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

# Parent paths for permissions
$parentPaths = @(
    "Registry::HKEY_CLASSES_ROOT\*",
    "Registry::HKEY_CLASSES_ROOT\Directory\shell",
    "Registry::HKEY_CLASSES_ROOT\Drive\shell"
)

# Set permissions on parents
foreach ($parent in $parentPaths) {
    Set-RegistryPermissions $parent
}

# Backup
try {
    Backup-Registry $keys "TakeOwnership"
    Add-Content $logPath -Value "$(Get-Date): Backup completed"
} catch {
    Write-Host "⚠️ Backup failed: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Backup error: $_"
    exit
}

# Commands (direct cmd, elevated via runas key)
$cmd_file = 'cmd.exe /c takeown /f "%1" && icacls "%1" /grant *S-1-3-4:F /t /c /l'
$cmd_dir = 'cmd.exe /c takeown /f "%1" /r /d y && icacls "%1" /grant *S-1-3-4:F /t /c /q'
$cmd_drive = 'cmd.exe /c takeown /f "%1" /r /d y && icacls "%1" /grant *S-1-3-4:F /t /c'

# Apply for files (*)
try {
    New-Item -Path "Registry::HKEY_CLASSES_ROOT\*\shell\runas" -Force | Out-Null
    Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\*\shell\runas" -Name "(default)" -Value "Take Ownership"
    New-Item -Path "Registry::HKEY_CLASSES_ROOT\*\shell\runas\command" -Force | Out-Null
    Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\*\shell\runas\command" -Name "(default)" -Value $cmd_file
    Write-Host "✅ Added for files." -ForegroundColor Green
    Add-Content $logPath -Value "$(Get-Date): Added for files"
} catch {
    Write-Host "Error adding for files: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Error for files: $_"
}

# Apply for directories
try {
    New-Item -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\runas" -Force | Out-Null
    Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\runas" -Name "(default)" -Value "Take Ownership"
    New-Item -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\runas\command" -Force | Out-Null
    Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\runas\command" -Name "(default)" -Value $cmd_dir
    Write-Host "✅ Added for directories." -ForegroundColor Green
    Add-Content $logPath -Value "$(Get-Date): Added for directories"
} catch {
    Write-Host "Error adding for directories: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Error for directories: $_"
}

# Apply for drives
try {
    New-Item -Path "Registry::HKEY_CLASSES_ROOT\Drive\shell\runas" -Force | Out-Null
    Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Drive\shell\runas" -Name "(default)" -Value "Take Ownership"
    New-Item -Path "Registry::HKEY_CLASSES_ROOT\Drive\shell\runas\command" -Force | Out-Null
    Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Drive\shell\runas\command" -Name "(default)" -Value $cmd_drive
    Write-Host "✅ Added for drives." -ForegroundColor Green
    Add-Content $logPath -Value "$(Get-Date): Added for drives"
} catch {
    Write-Host "Error adding for drives: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Error for drives: $_"
}

Write-Host "✅ 'Take Ownership' context menu added. Log at $logPath" -ForegroundColor Green
Add-Content $logPath -Value "$(Get-Date): Completed Add-TakeOwnership"

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

# Optional: Restore original permissions (uncomment if needed)
# foreach ($parent in $parentPaths) {
#     Set-Acl $parent $originalAcl  # Use stored original ACL
# }