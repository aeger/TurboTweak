"""Python equivalents for the PowerShell tweak modules."""

from __future__ import annotations

import subprocess
from typing import List

from .registry import SESSION, assert_admin, is_windows


def _run_reg(args: List[str]) -> None:
    subprocess.run(["reg", *args], check=True)


def add_take_ownership(require_admin: bool = True) -> None:
    assert_admin(require_admin)
    SESSION.log("Starting Add-TakeOwnership")

    keys = [
        "HKEY_CLASSES_ROOT\\*\\shell\\TakeOwnership",
        "HKEY_CLASSES_ROOT\\*\\shell\\TakeOwnership\\command",
        "HKEY_CLASSES_ROOT\\Directory\\shell\\TakeOwnership",
        "HKEY_CLASSES_ROOT\\Directory\\shell\\TakeOwnership\\command",
        "HKEY_CLASSES_ROOT\\Drive\\shell\\TakeOwnership",
        "HKEY_CLASSES_ROOT\\Drive\\shell\\TakeOwnership\\command",
    ]
    SESSION.backup(keys, "TakeOwnership")

    cmd_file = "cmd.exe /k takeown /f \"%1\" && icacls \"%1\" /grant *S-1-3-4:F /t /c /l && pause"
    cmd_dir = "cmd.exe /k takeown /f \"%1\" /r /d y && icacls \"%1\" /grant *S-1-3-4:F /t /c /q && pause"
    cmd_drive = "cmd.exe /k takeown /f \"%1\" /r /d y && icacls \"%1\" /grant *S-1-3-4:F /t /c && pause"

    def _add_context(base: str, command: str) -> None:
        _run_reg(["add", base, "/f"])
        _run_reg(["add", base, "/ve", "/d", "Take Ownership", "/f"])
        _run_reg(["add", base, "/v", "NoWorkingDirectory", "/d", "", "/f"])
        _run_reg(["add", base, "/v", "Extended", "/d", "", "/f"])
        _run_reg(["add", f"{base}\\command", "/f"])
        _run_reg(["add", f"{base}\\command", "/ve", "/d", command, "/f"])

    _add_context(r"HKEY_CLASSES_ROOT\*\shell\TakeOwnership", cmd_file)
    _add_context(r"HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership", cmd_dir)
    _add_context(r"HKEY_CLASSES_ROOT\Drive\shell\TakeOwnership", cmd_drive)

    SESSION.log("Completed Add-TakeOwnership")


def remove_take_ownership(require_admin: bool = True) -> None:
    assert_admin(require_admin)
    SESSION.log("Starting Remove-TakeOwnership")

    keys = [
        "HKEY_CLASSES_ROOT\\*\\shell\\TakeOwnership",
        "HKEY_CLASSES_ROOT\\Directory\\shell\\TakeOwnership",
        "HKEY_CLASSES_ROOT\\Drive\\shell\\TakeOwnership",
    ]
    SESSION.backup(keys, "TakeOwnership_Remove")

    for key in keys:
        subprocess.run(["reg", "delete", key, "/f"], check=False)

    SESSION.log("Completed Remove-TakeOwnership")


def add_recent_places(require_admin: bool = False) -> None:
    assert_admin(require_admin)
    SESSION.log("Starting Add-RecentFolders")

    keys = [
        "HKEY_CURRENT_USER\\SOFTWARE\\Classes\\CLSID\\{22877a6d-37a1-461a-91b0-dbda5aaebc99}",
        "HKEY_CURRENT_USER\\SOFTWARE\\Classes\\CLSID\\{22877a6d-37a1-461a-91b0-dbda5aaebc99}\\ShellFolder",
        "HKEY_CURRENT_USER\\SOFTWARE\\Classes\\Wow6432Node\\CLSID\\{22877a6d-37a1-461a-91b0-dbda5aaebc99}",
        "HKEY_CURRENT_USER\\SOFTWARE\\Classes\\Wow6432Node\\CLSID\\{22877a6d-37a1-461a-91b0-dbda5aaebc99}\\ShellFolder",
    ]
    SESSION.backup(keys, "RecentFolders")

    SESSION.set_string(keys[0], None, "Recent Places")
    SESSION.set_dword(keys[1], "Attributes", 0x30040000)
    SESSION.set_string(keys[2], None, "Recent Places")
    SESSION.set_dword(keys[3], "Attributes", 0x30040000)

    SESSION.log("Completed Add-RecentFolders")


def remove_recent_places(require_admin: bool = False) -> None:
    assert_admin(require_admin)
    SESSION.log("Starting Remove-RecentFolders")

    keys = [
        "HKEY_CURRENT_USER\\SOFTWARE\\Classes\\CLSID\\{22877a6d-37a1-461a-91b0-dbda5aaebc99}",
        "HKEY_CURRENT_USER\\SOFTWARE\\Classes\\Wow6432Node\\CLSID\\{22877a6d-37a1-461a-91b0-dbda5aaebc99}",
    ]
    SESSION.backup(keys, "RecentFolders_Remove")

    for key in keys:
        SESSION.delete_tree(key)

    SESSION.log("Completed Remove-RecentFolders")


def enable_verbose_boot(require_admin: bool = True) -> None:
    assert_admin(require_admin)
    SESSION.log("Starting Add-VerboseBoot")

    key = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System"
    SESSION.backup([key], "VerboseBoot")
    SESSION.set_dword(key, "verbosestatus", 1)

    SESSION.log("Completed Add-VerboseBoot")


def disable_verbose_boot(require_admin: bool = True) -> None:
    assert_admin(require_admin)
    SESSION.log("Starting Remove-VerboseBoot")

    key = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System"
    SESSION.backup([key], "VerboseBoot_Remove")
    SESSION.delete_value(key, "verbosestatus")

    SESSION.log("Completed Remove-VerboseBoot")


def apply_performance_tweaks(require_admin: bool = True) -> None:
    assert_admin(require_admin)
    SESSION.log("Starting Add-Performance")

    keys = [
        "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Serialize",
        "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile",
    ]
    SESSION.backup(keys, "Performance")

    SESSION.set_dword(keys[0], "StartupDelayInMSec", 0)
    SESSION.set_dword(keys[0], "WaitforIdleState", 0)
    SESSION.set_dword(keys[1], "SystemResponsiveness", 10)
    SESSION.set_dword(keys[1], "NetworkThrottlingIndex", 0xFFFFFFFF)

    SESSION.log("Completed Add-Performance")


def remove_performance_tweaks(require_admin: bool = True) -> None:
    assert_admin(require_admin)
    SESSION.log("Starting Remove-Performance")

    keys = [
        "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Serialize",
        "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile",
    ]
    SESSION.backup(keys, "Performance_Remove")

    SESSION.delete_value(keys[0], "StartupDelayInMSec")
    SESSION.delete_value(keys[0], "WaitforIdleState")
    SESSION.set_dword(keys[1], "SystemResponsiveness", 20)
    SESSION.set_dword(keys[1], "NetworkThrottlingIndex", 10)

    SESSION.log("Completed Remove-Performance")


def enable_registry_backup(require_admin: bool = True) -> None:
    assert_admin(require_admin)
    SESSION.log("Starting Add-RegistryBackup")

    key = "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Configuration Manager"
    SESSION.backup([key], "RegistryBackup")
    SESSION.set_dword(key, "EnablePeriodicBackup", 1)

    SESSION.log("Completed Add-RegistryBackup")


def disable_registry_backup(require_admin: bool = True) -> None:
    assert_admin(require_admin)
    SESSION.log("Starting Remove-RegistryBackup")

    key = "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Configuration Manager"
    SESSION.backup([key], "RegistryBackup_Remove")
    SESSION.set_dword(key, "EnablePeriodicBackup", 0)

    SESSION.log("Completed Remove-RegistryBackup")


def create_restore_point(description: str = "Pre-Tweaks") -> None:
    if not is_windows():  # pragma: no cover - platform guard
        raise OSError("System restore points are only available on Windows.")

    command = [
        "powershell",
        "-Command",
        f"Checkpoint-Computer -Description '{description}' -RestorePointType MODIFY_SETTINGS",
    ]
    subprocess.run(command, check=True)
    SESSION.log(f"Created system restore point: {description}")


def apply_all(require_admin: bool = True) -> None:
    add_take_ownership(require_admin=require_admin)
    add_recent_places(require_admin=False)
    enable_verbose_boot(require_admin=require_admin)
    apply_performance_tweaks(require_admin=require_admin)
    enable_registry_backup(require_admin=require_admin)


def remove_all(require_admin: bool = True) -> None:
    remove_take_ownership(require_admin=require_admin)
    remove_recent_places(require_admin=False)
    disable_verbose_boot(require_admin=require_admin)
    remove_performance_tweaks(require_admin=require_admin)
    disable_registry_backup(require_admin=require_admin)
