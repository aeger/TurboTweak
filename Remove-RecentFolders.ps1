# Remove-RecentFolders.ps1
# Cleans up "Recent Places" tweak from registry

. "$PSScriptRoot\Lib-BackupRegistry.ps1"

$keys = @(
    "HKCU\SOFTWARE\Classes\CLSID\{22877a6d-37a1-461a-91b0-dbda5aaebc99}",
    "HKCU\SOFTWARE\Classes\Wow6432Node\CLSID\{22877a6d-37a1-461a-91b0-dbda5aaebc99}"
)

Backup-Registry $keys "RecentFolders_Remove"

foreach ($key in $keys) {
    Remove-Item -Path ("Registry::" + $key) -Recurse -ErrorAction SilentlyContinue
}

Write-Host "🚫 'Recent Folders' tweak removed." -ForegroundColor Yellow
