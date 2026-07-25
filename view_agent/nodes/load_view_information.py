import json
from typing import Any

from classes.state import RequirementWorkflowState
from file_io.read_file import read_file

REQUIRED_VIEW_ASSETS = ("skill", "examples", "context")


def _read_mapping_file(file_path: str, file_label: str) -> dict[str, Any]:
    file_content = read_file(file_path)

    if not isinstance(file_content, dict):
        raise TypeError(f"{file_label} must contain a JSON object at the root.")

    return file_content


def _stringify_asset_content(asset_content: Any) -> str:
    if isinstance(asset_content, str):
        return asset_content

    return json.dumps(asset_content, ensure_ascii=False, indent=2)


def _get_required_mapping(
    source: dict[str, Any],
    key: str,
    source_label: str,
) -> dict[str, Any]:
    value = source.get(key)

    if not isinstance(value, dict):
        raise KeyError(
            f"The key '{key}' was not found with a valid value in "
            f"{source_label}."
        )

    return value


def _get_required_string(
    source: dict[str, Any],
    key: str,
    source_label: str,
) -> str:
    value = source.get(key)

    if not isinstance(value, str) or not value.strip():
        raise KeyError(
            f"The key '{key}' was not found with a valid value in "
            f"{source_label}."
        )

    return value


def _load_system_prompt(prompt_manifest: dict[str, Any]) -> str:
    system_prompt_path = _get_required_string(
        prompt_manifest,
        "system_prompt",
        "prompt_manifest.json",
    )
    system_prompt_content = read_file(system_prompt_path)

    if not isinstance(system_prompt_content, str):
        raise TypeError("The system prompt must be a text file.")

    return system_prompt_content


def _resolve_view_definition(
    view_catalog: dict[str, Any],
    view_name: str,
) -> dict[str, Any]:
    view_definition = view_catalog.get(view_name)

    if not isinstance(view_definition, dict):
        raise KeyError(
            f"The view '{view_name}' was not found in dictionary.json."
        )

    return view_definition


def _load_view_assets(view_manifest: dict[str, Any]) -> dict[str, str]:
    loaded_assets: dict[str, str] = {}

    for asset_name in REQUIRED_VIEW_ASSETS:
        asset_path = _get_required_string(
            view_manifest,
            asset_name,
            "the view configuration in prompt_manifest.json",
        )
        asset_content = read_file(asset_path)
        loaded_assets[asset_name] = _stringify_asset_content(asset_content)

    return loaded_assets


def load_view_information(
    workflow_state: RequirementWorkflowState,
) -> RequirementWorkflowState:
    selected_view_name = workflow_state["view_name"]

    try:
        view_catalog = _read_mapping_file("dictionary.json", "dictionary.json")
        prompt_manifest = _read_mapping_file(
            "prompt_manifest.json",
            "prompt_manifest.json",
        )
        view_definition = _resolve_view_definition(
            view_catalog,
            selected_view_name,
        )
        view_type = _get_required_string(
            view_definition,
            "type",
            f"the definition of view '{selected_view_name}'",
        )
        available_views = _get_required_mapping(
            prompt_manifest,
            "views",
            "prompt_manifest.json",
        )
        selected_view_manifest = _get_required_mapping(
            available_views,
            view_type,
            "prompt_manifest.json",
        )
        system_prompt = _load_system_prompt(prompt_manifest)
        loaded_assets = _load_view_assets(selected_view_manifest)
    except (
        KeyError,
        TypeError,
        ValueError,
        json.JSONDecodeError,
        FileNotFoundError,
        IsADirectoryError,
    ) as error:
        raise RuntimeError(
            f"Failed to load information for view '{selected_view_name}'."
        ) from error

    workflow_state["system_prompt"] = system_prompt
    workflow_state["view_type"] = view_type
    workflow_state.update(loaded_assets)

    return workflow_state
