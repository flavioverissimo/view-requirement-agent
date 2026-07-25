import json
import os
from pathlib import Path
from typing import Any

from dotenv import load_dotenv

API_ROOT = Path(__file__).resolve().parents[2]
WORKFLOW_ROOT = API_ROOT / "workflow"

load_dotenv(dotenv_path=API_ROOT / ".env")


def _normalize_path_text(path: str | Path) -> str:
    raw_path = str(path).strip().strip('"').strip("'")

    if not raw_path:
        raise ValueError("The provided path cannot be empty.")

    expanded_path = os.path.expandvars(raw_path)
    expanded_path = os.path.expanduser(expanded_path)

    return expanded_path.replace("\\", os.sep).replace("/", os.sep)


def normalize_path(path: str | Path) -> Path:
    normalized_path = _normalize_path_text(path)
    return Path(normalized_path).resolve()


def normalize_relative_path(path: str | Path) -> Path:
    normalized_path = _normalize_path_text(path)
    relative_path = Path(normalized_path)

    if relative_path.is_absolute():
        raise ValueError("Provide only a path relative to the application.")

    return relative_path


def get_base_dir(base_dir: str | Path | None = None) -> Path:
    configured_base_dir = base_dir if base_dir is not None else WORKFLOW_ROOT

    return normalize_path(configured_base_dir)


def resolve_file_path(
    relative_path: str | Path,
    base_dir: str | Path | None = None,
) -> Path:
    if not relative_path or not str(relative_path).strip():
        raise ValueError("The file path cannot be empty.")

    normalized_base_dir = get_base_dir(base_dir)
    relative_file_path = normalize_relative_path(relative_path)
    resolved_file_path = (normalized_base_dir / relative_file_path).resolve()

    try:
        resolved_file_path.relative_to(normalized_base_dir)
    except ValueError as error:
        raise ValueError(
            "The provided file is outside the application directory."
        ) from error

    return resolved_file_path


def _read_json_file(file_path: Path) -> dict[str, Any] | list[Any]:
    try:
        with file_path.open("r", encoding="utf-8") as file:
            return json.load(file)
    except json.JSONDecodeError as error:
        raise ValueError(f"Invalid JSON file: {file_path}") from error


def _read_text_file(file_path: Path) -> str:
    return file_path.read_text(encoding="utf-8")


def read_file(
    relative_path: str | Path,
    base_dir: str | Path | None = None,
) -> Any:
    file_path = resolve_file_path(relative_path, base_dir)

    if not file_path.exists():
        raise FileNotFoundError(f"File not found: {file_path}")

    if not file_path.is_file():
        raise IsADirectoryError(
            f"The provided path is not a file: {file_path}"
        )

    file_extension = file_path.suffix.lower()

    if file_extension == ".json":
        return _read_json_file(file_path)

    if file_extension == ".md":
        return _read_text_file(file_path)

    raise ValueError(
        f"Unsupported format: '{file_extension}'. "
        "Only .json and .md files are allowed."
    )
