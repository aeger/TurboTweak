"""Python implementation of TurboTweak registry utilities."""

from importlib.metadata import version, PackageNotFoundError

__all__ = [
    "__version__",
]

try:
    __version__ = version("turbotweak")
except PackageNotFoundError:  # pragma: no cover - local development fallback
    __version__ = "0.0.0"
