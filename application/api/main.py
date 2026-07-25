from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from core.config import get_settings
from core.exceptions import APIError
from middleware.rate_limit import InMemoryRateLimitMiddleware
from routes.health import router as health_router
from routes.requirements import router as requirements_router
from services.requirement_workflow_service import (
    get_requirement_workflow_service,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    settings.validate_required()
    get_requirement_workflow_service()
    app.state.settings = settings
    yield


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(
        title=settings.api_title,
        version=settings.api_version,
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=list(settings.cors_allowed_origins),
        allow_credentials=settings.cors_allow_credentials,
        allow_methods=list(settings.cors_allow_methods),
        allow_headers=list(settings.cors_allow_headers),
    )
    app.add_middleware(
        InMemoryRateLimitMiddleware,
        max_requests=settings.rate_limit_max_requests,
        window_seconds=settings.rate_limit_window_seconds,
    )

    @app.exception_handler(APIError)
    async def handle_api_error(
        _: Request,
        error: APIError,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=error.status_code,
            content={"detail": error.detail},
        )

    app.include_router(health_router, prefix=settings.api_prefix)
    app.include_router(requirements_router, prefix=settings.api_prefix)

    return app


app = create_app()
