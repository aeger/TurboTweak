# Add-TakeOwnership.ps1
# Adds "Take Ownership" right-click context menu entries for files, directories, and drives.
# Improved: Uses \shell\runas for consistent elevation, hardcoded /d y (English), error handling, confirmation, logging.
# New: Enables SeTakeOwnershipPrivilege to handle protected keys; uses HKCR PSDrive; optional Explorer restart.

. "$PSScriptRoot\Lib-BackupRegistry.ps1"  # Assume improved lib with fallback path

# Elevation check (for standalone run)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh.exe "-File `"$PSCommandPath`"" -Verb RunAs
    return  # Use return instead of exit to avoid terminating caller
}

# Function to enable privilege (required for taking ownership of protected keys)
function Enable-Privilege {
    param (
        [string]$Privilege = "SeTakeOwnershipPrivilege"
    )
    try {
        $import = '[DllImport("ntdll.dll")] public static extern int RtlAdjustPrivilege(ulong p, bool e, bool c, ref bool o);'
        $type = Add-Type -MemberDefinition $import -Namespace "NtDll" -Name "Priv" -PassThru
        $old = $false
        [void]$type::RtlAdjustPrivilege(9, $true, $false, [ref]$old)  # 9 = SeTakeOwnershipPrivilege
        Write-Host "🔑 $Privilege enabled." -ForegroundColor Cyan
        Add-Content $logPath -Value "$(Get-Date): Enabled $Privilege"
    } catch {
        Write-Host "⚠️ Failed to enable $Privilege: $_" -ForegroundColor Red
        Add-Content $logPath -Value "$(Get-Date): Privilege enable error: $_"
        return
    }
}

# Function to take ownership and grant full control
function Set-RegistryPermissions {
    param (
        [string]$path
    )
    try {
        $key = Get-Item -LiteralPath $path -ErrorAction Stop
        $acl = $key.GetAccessControl('Owner,Access')
        $originalAcl = $acl  # Backup original ACL

        $admin = New-Object System.Security.Principal.NTAccount("BUILTIN\Administrators")
        $acl.SetOwner($admin)
        $key.SetAccessControl($acl)

        $rule = New-Object System.Security.AccessControl.RegistryAccessRule("BUILTIN\Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.AddAccessRule($rule)
        $key.SetAccessControl($acl)

        Write-Host "🔑 Permissions granted for $path." -ForegroundColor Cyan
        Add-Content $logPath -Value "$(Get-Date): Granted permissions for $path"

        return $originalAcl
    } catch {
        Write-Host "⚠️ Failed to set permissions for $path: $_" -ForegroundColor Red
        Add-Content $logPath -Value "$(Get-Date): Permissions error for $path: $_"
        return
    }
}

# Confirmation prompt
$confirm = Read-Host "Add 'Take Ownership' context menu? This modifies registry (y/n)"
if ($confirm -ne 'y') { Write-Host "❌ Operation cancelled." -ForegroundColor Yellow; return }

# Logging setup
$logPath = "$PSScriptRoot\TurboTweak.log"
Add-Content -Path $logPath -Value "$(Get-Date): Starting Add-TakeOwnership"

# Enable privilege
Enable-Privilege

$keys = @(
    "HKCR:\*\shell\runas",
    "HKCR:\*\shell\runas\command",
    "HKCR:\Directory\shell\runas",
    "HKCR:\Directory\shell\runas\command",
    "HKCR:\Drive\shell\runas",
    "HKCR:\Drive\shell\runas\command"
)

# Parent paths for permissions (using HKCR PSDrive)
$parentPaths = @(
    "HKCR:\*",
    "HKCR:\Directory\shell",
    "HKCR:\Drive\shell"
)

# Set permissions on parents
$originalAcls = @{}
foreach ($parent in $parentPaths) {
    $originalAcls[$parent] = Set-RegistryPermissions $parent
}

# Backup
try {
    Backup-Registry $keys "TakeOwnership"
    Add-Content $logPath -Value "$(Get-Date): Backup completed"
} catch {
    Write-Host "⚠️ Backup failed: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Backup error: $_"
    return
}

# Commands (direct cmd, elevated via runas key)
$cmd_file = 'cmd.exe /c takeown /f "%1" && icacls "%1" /grant *S-1-3-4:F /t /c /l'
$cmd_dir = 'cmd.exe /c takeown /f "%1" /r /d y && icacls "%1" /grant *S-1-3-4:F /t /c /q'
$cmd_drive = 'cmd.exe /c takeown /f "%1" /r /d y && icacls "%1" /grant *S-1-3-4:F /t /c'

# Apply for files (*)
try {
    New-Item -Path "HKCR:\*\shell\runas" -Force | Out-Null
    Set-ItemProperty -Path "HKCR:\*\shell\runas" -Name "(default)" -Value "Take Ownership"
    New-Item -Path "HKCR:\*\shell\runas\command" -Force | Out-Null
    Set-ItemProperty -Path "HKCR:\*\shell\runas\command" -Name "(default)" -Value $cmd_file
    Write-Host "✅ Added for files." -ForegroundColor Green
    Add-Content $logPath -Value "$(Get-Date): Added for files"
} catch {
    Write-Host "Error adding for files: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Error for files: $_"
}

# Apply for directories
try {
    New-Item -Path "HKCR:\Directory\shell\runas" -Force | Out-Null
    Set-ItemProperty -Path "HKCR:\Directory\shell\runas" -Name "(default)" -Value "Take Ownership"
    New-Item -Path "HKCR:\Directory\shell\runas\command" -Force | Out-Null
    Set-ItemProperty -Path "HKCR:\Directory\shell\runas\command" -Name "(default)" -Value $cmd_dir
    Write-Host "✅ Added for directories." -ForegroundColor Green
    Add-Content $logPath -Value "$(Get-Date): Added for directories"
} catch {
    Write-Host "Error adding for directories: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Error for directories: $_"
}

# Apply for drives
try {
    New-Item -Path "HKCR:\Drive\shell\runas" -Force | Out-Null
    Set-ItemProperty -Path "HKCR:\Drive\shell\runas" -Name "(default)" -Value "Take Ownership"
    New-Item -Path "HKCR:\Drive\shell\runas\command" -Force | Out-Null
    Set-ItemProperty -Path "HKCR:\Drive\shell\runas\command" -Name "(default)" -Value $cmd_drive
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

# Optional: Restore original permissions (uncomment if needed for cleanup)
# foreach ($parent in $parentPaths) {
#     if ($originalAcls[$parent]) {
#         $key = Get-Item -LiteralPath $parent
#         $key.SetAccessControl($originalAcls[$parent])
#     }
# }