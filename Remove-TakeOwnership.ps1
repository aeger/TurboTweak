# Remove-TakeOwnership.ps1
# Cleans up "Take Ownership" context menu entries

. "$PSScriptRoot\Lib-BackupRegistry.ps1"

$keys = @(
    "HKEY_CLASSES_ROOT\*\shell\TakeOwnership",
    "HKEY_CLASSES_ROOT\*\shell\TakeOwnership\command",
    "HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership",
    "HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership\command",
    "HKEY_CLASSES_ROOT\Drive\shell\runas",
    "HKEY_CLASSES_ROOT\Drive\shell\runas\command"
)

Backup-Registry $keys "TakeOwnership_Remove"

foreach ($key in $keys) {
    Remove-Item -Path ("Registry::" + $key) -Recurse -ErrorAction SilentlyContinue
}

Write-Host "🚫 'Take Ownership' context menu removed." -ForegroundColor Yellow
