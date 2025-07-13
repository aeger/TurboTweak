# Lib-BackupRegistry.ps1
# Shared function for registry backups with OneDrive fallback to Documents

function Backup-Registry {
    param (
        [string[]]$keys,
        [string]$label
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $backupRoot = if (Test-Path $env:OneDrive) { "$env:OneDrive\RegistryBackups" } else { "$env:USERPROFILE\Documents\RegistryBackups" }
    $backupPath = "$backupRoot\$label_$timestamp"

    try {
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

        foreach ($key in $keys) {
            $safeName = $key -replace '[\\*{}]', '_'
            $regFile = "$backupPath\$safeName.reg"
            reg export $key $regFile /y 2>$null
        }

        Write-Host "✔ Backup saved at: $backupPath" -ForegroundColor Cyan
    }
    catch {
        Write-Host "⚠️ Backup failed: $_" -ForegroundColor Red
    }

    return $backupPath
}