from __future__ import annotations

import logging
import os
from pathlib import Path
from typing import Any

import json
from dotenv import load_dotenv


load_dotenv()

DEFAULT_LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO").upper()


def get_logger(name: str) -> logging.Logger:
    """Return a configured logger instance."""
    logger = logging.getLogger(name)
    if not logger.handlers:
        handler = logging.StreamHandler()
        formatter = logging.Formatter(
            "%(asctime)s | %(levelname)s | %(name)s | %(message)s"
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
    logger.setLevel(DEFAULT_LOG_LEVEL)
    logger.propagate = False
    return logger


def project_root() -> Path:
    """Return the project root path."""
    return Path(__file__).resolve().parent.parent


def resolve_path_from_env(variable: str, default: str) -> Path:
    """Resolve a directory path from an environment variable or fallback."""
    base = os.environ.get(variable, default)
    path = project_root() / base if not os.path.isabs(base) else Path(base)
    path.mkdir(parents=True, exist_ok=True)
    return path


def ensure_directory(path: Path) -> None:
    """Ensure that a directory exists."""
    path.mkdir(parents=True, exist_ok=True)


def serialize_json(data: Any, path: Path) -> None:
    """Serialize data to JSON file with indentation."""
    ensure_directory(path.parent)
    path.write_text(
        json.dumps(data, indent=2, sort_keys=True, default=str),
        encoding="utf-8",
    )

