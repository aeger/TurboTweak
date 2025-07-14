# Add-RecentFolders.ps1
# Restores "Recent Places" folder in Explorer/File Dialogs

. "$PSScriptRoot\Lib-BackupRegistry.ps1"

# Elevation not strictly needed (HKCU), but check for consistency
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ℹ️ Running without elevation (HKCU keys). If issues, run as admin." -ForegroundColor Yellow
}

# Confirmation
$confirm = Read-Host "Restore 'Recent Places' in Explorer? (y/n)"
if ($confirm -ne 'y') { Write-Host "❌ Cancelled." -ForegroundColor Yellow; exit }

# Logging
$logPath = "$PSScriptRoot\TurboTweak.log"
Add-Content -Path $logPath -Value "$(Get-Date): Starting Add-RecentFolders"

$keys = @(
    "HKCU\SOFTWARE\Classes\CLSID\{22877a6d-37a1-461a-91b0-dbda5aaebc99}",
    "HKCU\SOFTWARE\Classes\CLSID\{22877a6d-37a1-461a-91b0-dbda5aaebc99}\ShellFolder",
    "HKCU\SOFTWARE\Classes\Wow6432Node\CLSID\{22877a6d-37a1-461a-91b0-dbda5aaebc99}",
    "HKCU\SOFTWARE\Classes\Wow6432Node\CLSID\{22877a6d-37a1-461a-91b0-dbda5aaebc99}\ShellFolder"
)

try {
    Backup-Registry $keys "RecentFolders"
    Add-Content $logPath -Value "$(Get-Date): Backup completed"
} catch {
    Write-Host "⚠️ Backup failed: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Backup error: $_"
    return  # Changed from exit
}

try {
    New-Item -Path $keys[0] -Force | Out-Null
    Set-ItemProperty -Path $keys[0] -Name "(default)" -Value "Recent Places"
    New-Item -Path $keys[1] -Force | Out-Null
    Set-ItemProperty -Path $keys[1] -Name "Attributes" -Value 0x30040000 -Type DWord

    New-Item -Path $keys[2] -Force | Out-Null
    Set-ItemProperty -Path $keys[2] -Name "(default)" -Value "Recent Places"
    New-Item -Path $keys[3] -Force | Out-Null
    Set-ItemProperty -Path $keys[3] -Name "Attributes" -Value 0x30040000 -Type DWord

    Write-Host "✅ 'Recent Places' restored." -ForegroundColor Green
    Add-Content $logPath -Value "$(Get-Date): Applied successfully"

    $launch = Read-Host "Launch Recent Places to pin? (y/n)"
    if ($launch -eq 'y') {
        Start-Process 'explorer.exe' "shell:::{22877a6d-37a1-461a-91b0-dbda5aaebc99}"
        Write-Host "📌 Launched. Right-click and pin to Quick Access." -ForegroundColor Magenta
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Error: $_"
}

Add-Content $logPath -Value "$(Get-Date): Completed Add-RecentFolders"