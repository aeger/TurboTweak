# TurboTweakMenu.ps1
# Master menu to launch tweak modules

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Run-Module {
    param (
        [string]$fileName,
        [string]$label
    )
    $fullPath = Join-Path $scriptDir $fileName
    if (Test-Path $fullPath) {
        Write-Host "`n🧩 Running $label..."
        . $fullPath
        Pause
    } else {
        Write-Host "❌ Module '$fileName' not found." -ForegroundColor Red
        Pause
    }
}

function Show-Menu {
    Clear-Host
    Write-Host "============= TurboTweak Launcher =============" -ForegroundColor Cyan
    Write-Host " [1] Add Take Ownership"
    Write-Host " [2] Remove Take Ownership"
    Write-Host " [3] Add Recent Folders"
    Write-Host " [4] Remove Recent Folders"
    Write-Host " [5] Enable Verbose Boot Messages"
    Write-Host " [6] Apply Performance Tweaks"
    Write-Host " [7] Enable Registry Backup"
    Write-Host " [8] Apply All Tweaks"
    Write-Host " [9] Remove All Tweaks"
    Write-Host " [0] Exit"
    Write-Host "==============================================="

    $choice = Read-Host "Enter your choice"
    switch ($choice) {
        "1" { Run-Module "Add-TakeOwnership.ps1" "Add Take Ownership" }
        "2" { Run-Module "Remove-TakeOwnership.ps1" "Remove Take Ownership" }
        "3" { Run-Module "Add-RecentFolders.ps1" "Add Recent Folders" }
        "4" { Run-Module "Remove-RecentFolders.ps1" "Remove Recent Folders" }
        "5" { Run-Module "Add-VerboseBoot.ps1" "Enable Verbose Boot" }
        "6" { Run-Module "Add-Performance.ps1" "Apply Performance Tweaks" }
        "7" { Run-Module "Add-RegistryBackup.ps1" "Enable Registry Backup" }
        "8" {
            Run-Module "Add-TakeOwnership.ps1" "Add Take Ownership"
            Run-Module "Add-RecentFolders.ps1" "Add Recent Folders"
            Run-Module "Add-VerboseBoot.ps1" "Enable Verbose Boot"
            Run-Module "Add-Performance.ps1" "Apply Performance Tweaks"
            Run-Module "Add-RegistryBackup.ps1" "Enable Registry Backup"
        }
        "9" {
            Run-Module "Remove-TakeOwnership.ps1" "Remove Take Ownership"
            Run-Module "Remove-RecentFolders.ps1" "Remove Recent Folders"
        }
        "0" { Write-Host "`n👋 TurboTweak session ended." -ForegroundColor Gray; exit }
        default {
            Write-Host "Invalid selection. Please try again." -ForegroundColor Red
            Pause
        }
    }
    Show-Menu
}

Show-Menu
