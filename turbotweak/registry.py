"""Registry helpers for TurboTweak.

The original PowerShell scripts relied on ``reg.exe`` and PowerShell cmdlets.
This module recreates that behavior with the standard library so the tweaks can
be applied from Python.
"""

from __future__ import annotations

import os
import platform
import re
import subprocess
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Iterable, Optional, Tuple

if os.name == "nt":
    import winreg
else:  # pragma: no cover - guard for non-Windows CI
    winreg = None  # type: ignore


ROOTS = {
    "HKEY_CLASSES_ROOT": winreg.HKEY_CLASSES_ROOT if winreg else None,
    "HKCR": winreg.HKEY_CLASSES_ROOT if winreg else None,
    "HKEY_CURRENT_USER": winreg.HKEY_CURRENT_USER if winreg else None,
    "HKCU": winreg.HKEY_CURRENT_USER if winreg else None,
    "HKEY_LOCAL_MACHINE": winreg.HKEY_LOCAL_MACHINE if winreg else None,
    "HKLM": winreg.HKEY_LOCAL_MACHINE if winreg else None,
}


def _ensure_windows() -> None:
    if os.name != "nt":  # pragma: no cover - platform guard
        raise OSError("Registry tweaks require Windows.")


def _split_root(path: str) -> Tuple[int, str]:
    _ensure_windows()
    for prefix, root in ROOTS.items():
        if path.startswith(prefix + "\\") and root is not None:
            return root, path[len(prefix) + 1 :]
    raise ValueError(f"Unsupported registry path: {path}")


@dataclass
class RegistrySession:
    base_dir: Path

    @property
    def log_path(self) -> Path:
        return self.base_dir / "TurboTweak.log"

    def log(self, message: str) -> None:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with self.log_path.open("a", encoding="utf-8") as handle:
            handle.write(f"{timestamp}: {message}\n")

    def backup(self, keys: Iterable[str], label: str) -> Path:
        """Export registry keys using ``reg.exe``.

        The backup location mirrors the PowerShell helper: prefer OneDrive if
        present, otherwise fall back to Documents.
        """

        _ensure_windows()
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        backup_root = (
            Path(os.environ["OneDrive"]) / "RegistryBackups"
            if "OneDrive" in os.environ
            else Path.home() / "Documents" / "RegistryBackups"
        )
        backup_path = backup_root / f"{label}_{timestamp}"
        backup_path.mkdir(parents=True, exist_ok=True)

        for key in keys:
            safe_name = re.sub(r"[\\\\*{}]", "_", key)
            reg_file = backup_path / f"{safe_name}.reg"
            try:
                subprocess.run(
                    ["reg", "export", key, str(reg_file), "/y"],
                    check=True,
                    capture_output=True,
                    text=True,
                )
            except subprocess.CalledProcessError as exc:
                self.log(f"Backup warning for {key}: {exc.stderr.strip()}")

        self.log(f"Backup saved at: {backup_path}")
        return backup_path

    def set_value(self, path: str, name: Optional[str], value, reg_type) -> None:
        """Create the key and set a value."""

        root, subkey = _split_root(path)
        with winreg.CreateKey(root, subkey) as handle:  # type: ignore[arg-type]
            winreg.SetValueEx(handle, name or "", 0, reg_type, value)  # type: ignore[arg-type]

    def delete_tree(self, path: str) -> None:
        root, subkey = _split_root(path)
        try:
            winreg.DeleteKey(root, subkey)  # type: ignore[arg-type]
        except FileNotFoundError:
            return
        except OSError:
            # Fallback to reg.exe for recursive deletion
            subprocess.run(["reg", "delete", path, "/f"], check=False)

    def delete_value(self, path: str, name: str) -> None:
        root, subkey = _split_root(path)
        try:
            with winreg.OpenKey(root, subkey, 0, winreg.KEY_SET_VALUE) as handle:  # type: ignore[arg-type]
                winreg.DeleteValue(handle, name)
        except FileNotFoundError:
            return
        except OSError:
            subprocess.run(["reg", "delete", path, "/v", name, "/f"], check=False)

    def set_dword(self, path: str, name: str, value: int) -> None:
        self.set_value(path, name, value, winreg.REG_DWORD)

    def set_string(self, path: str, name: Optional[str], value: str) -> None:
        self.set_value(path, name, value, winreg.REG_SZ)


class AdminRequirementError(PermissionError):
    """Raised when administrative rights are required."""


def assert_admin(required: bool = True) -> None:
    """Optionally enforce administrative rights."""

    if not required:
        return

    _ensure_windows()
    import ctypes  # Imported lazily to keep module importable on non-Windows

    if not bool(ctypes.windll.shell32.IsUserAnAdmin()):
        raise AdminRequirementError("Administrator privileges are required for this operation.")


BASE_DIR = Path(__file__).resolve().parent.parent
SESSION = RegistrySession(base_dir=BASE_DIR)


def is_windows() -> bool:
    return os.name == "nt"


def platform_summary() -> str:
    return f"{platform.system()} {platform.release()} ({platform.version()})"
