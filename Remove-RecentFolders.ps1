# Remove-RecentFolders.ps1
# Cleans up "Recent Places" tweak from registry

. "$PSScriptRoot\Lib-BackupRegistry.ps1"

# Elevation check (optional for HKCU)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ℹ️ Running without elevation (HKCU keys)." -ForegroundColor Yellow
}

$confirm = Read-Host "Remove 'Recent Places' from Explorer? (y/n)"
if ($confirm -ne 'y') { Write-Host "❌ Cancelled." -ForegroundColor Yellow; exit }

$logPath = "$PSScriptRoot\TurboTweak.log"
Add-Content -Path $logPath -Value "$(Get-Date): Starting Remove-RecentFolders"

$keys = @(
    "HKCU\SOFTWARE\Classes\CLSID\{22877a6d-37a1-461a-91b0-dbda5aaebc99}",
    "HKCU\SOFTWARE\Classes\CLSID\{22877a6d-37a1-461a-91b0-dbda5aaebc99}\ShellFolder",
    "HKCU\SOFTWARE\Classes\Wow6432Node\CLSID\{22877a6d-37a1-461a-91b0-dbda5aaebc99}",
    "HKCU\SOFTWARE\Classes\Wow6432Node\CLSID\{22877a6d-37a1-461a-91b0-dbda5aaebc99}\ShellFolder"
)

try {
    Backup-Registry $keys "RecentFolders_Remove"
    Add-Content $logPath -Value "$(Get-Date): Backup completed"
} catch {
    Write-Host "⚠️ Backup failed: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Backup error: $_"
    exit
}

try {
    foreach ($key in $keys[0,2]) {  # Remove parent CLSID keys recursively
        Remove-Item -Path ("Registry::" + $key) -Recurse -ErrorAction Stop
    }
    Write-Host "🚫 'Recent Places' removed." -ForegroundColor Yellow
    Add-Content $logPath -Value "$(Get-Date): Removed successfully"
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Add-Content $logPath -Value "$(Get-Date): Error: $_"
}

Add-Content $logPath -Value "$(Get-Date): Completed Remove-RecentFolders"