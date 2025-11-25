"""Menu-driven CLI mirroring ``TurboTweakMenu.ps1``."""

from __future__ import annotations

import sys
from typing import Callable, Dict

from . import __version__
from .registry import SESSION, AdminRequirementError, is_windows, platform_summary
from . import tweaks


class Menu:
    def __init__(self) -> None:
        self.actions: Dict[str, Callable[[], None]] = {
            "1": tweaks.add_take_ownership,
            "2": tweaks.remove_take_ownership,
            "3": tweaks.add_recent_places,
            "4": tweaks.remove_recent_places,
            "5": tweaks.enable_verbose_boot,
            "6": tweaks.disable_verbose_boot,
            "7": tweaks.apply_performance_tweaks,
            "8": tweaks.remove_performance_tweaks,
            "9": tweaks.enable_registry_backup,
            "10": tweaks.disable_registry_backup,
            "11": tweaks.apply_all,
            "12": tweaks.remove_all,
        }

    def show(self) -> None:
        print("============= TurboTweak (Python) =============")
        print(f"Version: {__version__} | Platform: {platform_summary()}")
        print(" [1] Add Take Ownership")
        print(" [2] Remove Take Ownership")
        print(" [3] Add Recent Folders")
        print(" [4] Remove Recent Folders")
        print(" [5] Enable Verbose Boot Messages")
        print(" [6] Disable Verbose Boot Messages")
        print(" [7] Apply Performance Tweaks")
        print(" [8] Remove Performance Tweaks")
        print(" [9] Enable Registry Backup")
        print(" [10] Disable Registry Backup")
        print(" [11] Apply All Tweaks")
        print(" [12] Remove All Tweaks")
        print(" [0] Exit")
        print("===============================================")

    def run_action(self, choice: str) -> None:
        action = self.actions.get(choice)
        if not action:
            print("Invalid selection. Please try again.")
            return

        try:
            action()
            print("✅ Completed. Details logged to", SESSION.log_path)
        except AdminRequirementError as exc:
            print(f"❌ {exc}")
        except Exception as exc:  # pragma: no cover - defensive logging
            SESSION.log(f"Error running action {choice}: {exc}")
            print(f"❌ Error: {exc}")

    def loop(self) -> None:
        if not is_windows():
            print("This menu is intended for Windows. Detected:", platform_summary())
            return

        while True:
            self.show()
            choice = input("Enter your choice: ").strip()
            if choice == "0":
                print("\n👋 TurboTweak session ended.")
                break
            self.run_action(choice)
            input("Press Enter to return to the menu...")


def main(argv: list[str] | None = None) -> int:
    _ = argv  # Unused placeholder for API compatibility
    menu = Menu()
    menu.loop()
    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
