"""Command-line interface for TurboTweak."""

from __future__ import annotations

import argparse
from typing import Callable, Dict

from . import __version__
from .menu import Menu
from .registry import AdminRequirementError, SESSION, is_windows, platform_summary
from . import tweaks

Action = Callable[[], None]


def _actions() -> Dict[str, Action]:
    return {
        "add-take-ownership": tweaks.add_take_ownership,
        "remove-take-ownership": tweaks.remove_take_ownership,
        "add-recent-folders": tweaks.add_recent_places,
        "remove-recent-folders": tweaks.remove_recent_places,
        "enable-verbose-boot": tweaks.enable_verbose_boot,
        "disable-verbose-boot": tweaks.disable_verbose_boot,
        "apply-performance": tweaks.apply_performance_tweaks,
        "remove-performance": tweaks.remove_performance_tweaks,
        "enable-registry-backup": tweaks.enable_registry_backup,
        "disable-registry-backup": tweaks.disable_registry_backup,
        "apply-all": tweaks.apply_all,
        "remove-all": tweaks.remove_all,
    }


def _confirm(prompt: str) -> bool:
    choice = input(f"{prompt} [y/N]: ").strip().lower()
    return choice in {"y", "yes"}


def run_action(name: str, assume_yes: bool) -> int:
    actions = _actions()
    action = actions.get(name)
    if not action:
        print("❌ Unknown action. Use --list to see available options.")
        return 2

    if not assume_yes and not _confirm(f"Proceed with '{name}'?"):
        print("ℹ️ Aborted by user.")
        return 1

    try:
        action()
        print("✅ Completed. Details logged to", SESSION.log_path)
        return 0
    except AdminRequirementError as exc:
        print(f"❌ {exc}")
        return 5
    except Exception as exc:  # pragma: no cover - defensive logging
        SESSION.log(f"Error running action {name}: {exc}")
        print(f"❌ Error: {exc}")
        return 3


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="TurboTweak Python edition — registry tweak helper",
    )
    parser.add_argument(
        "action",
        nargs="?",
        help="Action to perform (use --list for options). Omitting runs the menu.",
    )
    parser.add_argument(
        "--assume-yes",
        action="store_true",
        help="Skip confirmation prompts.",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List available actions and exit.",
    )
    parser.add_argument(
        "--version",
        action="version",
        version=f"turbotweak {__version__} ({platform_summary()})",
    )

    args = parser.parse_args(argv)

    if args.list:
        print("Available actions:")
        for key in _actions():
            print(f" - {key}")
        return 0

    if args.action:
        return run_action(args.action, assume_yes=args.assume_yes)

    menu = Menu()
    if not is_windows():
        print("This menu is intended for Windows. Detected:", platform_summary())
        return 4

    menu.loop()
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
