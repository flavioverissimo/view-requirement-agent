import json
from pathlib import Path
from typing import Any

from workflow.file_io.read_file import normalize_path


def _resolve_output_path(file_path: str | Path) -> Path:
    resolved_output_path = normalize_path(file_path)

    if resolved_output_path.exists() and not resolved_output_path.is_file():
        raise IsADirectoryError(
            f"The provided destination is not a file: {resolved_output_path}"
        )

    return resolved_output_path


def save_json(
    data: dict[str, Any],
    file_path: str | Path,
) -> Path:
    output_path = _resolve_output_path(file_path)

    output_path.parent.mkdir(parents=True, exist_ok=True)

    try:
        with output_path.open("w", encoding="utf-8") as file:
            json.dump(
                data,
                file,
                ensure_ascii=False,
                indent=4,
            )
    except (TypeError, ValueError) as error:
        raise ValueError(
            f"Failed to serialize JSON to file: {output_path}"
        ) from error
    except OSError as error:
        raise OSError(
            f"Failed to write JSON file: {output_path}"
        ) from error

    return output_path.resolve()
