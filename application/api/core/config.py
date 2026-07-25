from __future__ import annotations

import os
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parents[1]

load_dotenv(dotenv_path=PROJECT_ROOT / ".env")


def _parse_csv_env(name: str, default: list[str]) -> tuple[str, ...]:
    raw_value = os.getenv(name)

    if raw_value is None:
        return tuple(default)

    parsed_values = [value.strip() for value in raw_value.split(",")]
    return tuple(value for value in parsed_values if value)


def _parse_bool_env(name: str, default: bool) -> bool:
    raw_value = os.getenv(name)

    if raw_value is None:
        return default

    return raw_value.strip().lower() in {"1", "true", "yes", "on"}


def _parse_int_env(name: str, default: int) -> int:
    raw_value = os.getenv(name)

    if raw_value is None:
        return default

    return int(raw_value.strip())


@dataclass(frozen=True, slots=True)
class Settings:
    project_root: Path
    api_title: str
    api_version: str
    api_prefix: str
    openai_model: str
    cors_allowed_origins: tuple[str, ...]
    cors_allow_credentials: bool
    cors_allow_methods: tuple[str, ...]
    cors_allow_headers: tuple[str, ...]
    rate_limit_window_seconds: int
    rate_limit_max_requests: int

    def validate_required(self) -> None:
        if not self.openai_model:
            raise RuntimeError(
                "The OPENAI_MODEL environment variable must be configured "
                "before starting the API."
            )

        if self.rate_limit_window_seconds <= 0:
            raise RuntimeError(
                "RATE_LIMIT_WINDOW_SECONDS must be greater than zero."
            )

        if self.rate_limit_max_requests <= 0:
            raise RuntimeError(
                "RATE_LIMIT_MAX_REQUESTS must be greater than zero."
            )


@lru_cache
def get_settings() -> Settings:
    return Settings(
        project_root=PROJECT_ROOT,
        api_title=os.getenv(
            "API_TITLE",
            "Requirement Interpretation API",
        ).strip(),
        api_version=os.getenv("API_VERSION", "1.0.0").strip(),
        api_prefix=os.getenv("API_PREFIX", "/api/v1").strip(),
        openai_model=os.getenv("OPENAI_MODEL", "").strip(),
        cors_allowed_origins=_parse_csv_env(
            "CORS_ALLOWED_ORIGINS",
            [
                "http://localhost:3000",
                "http://127.0.0.1:3000",
            ],
        ),
        cors_allow_credentials=_parse_bool_env(
            "CORS_ALLOW_CREDENTIALS",
            False,
        ),
        cors_allow_methods=_parse_csv_env(
            "CORS_ALLOW_METHODS",
            ["GET", "POST", "OPTIONS"],
        ),
        cors_allow_headers=_parse_csv_env(
            "CORS_ALLOW_HEADERS",
            ["Authorization", "Content-Type"],
        ),
        rate_limit_window_seconds=_parse_int_env(
            "RATE_LIMIT_WINDOW_SECONDS",
            60,
        ),
        rate_limit_max_requests=_parse_int_env(
            "RATE_LIMIT_MAX_REQUESTS",
            10,
        ),
    )
