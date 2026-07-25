from __future__ import annotations

import time
from collections import defaultdict, deque
from threading import Lock

from fastapi import Request
from fastapi.responses import JSONResponse, Response
from starlette.middleware.base import BaseHTTPMiddleware


class InMemoryRateLimitMiddleware(BaseHTTPMiddleware):
    def __init__(
        self,
        app,
        *,
        max_requests: int,
        window_seconds: int,
    ) -> None:
        super().__init__(app)
        self._max_requests = max_requests
        self._window_seconds = window_seconds
        self._requests: dict[str, deque[float]] = defaultdict(deque)
        self._lock = Lock()

    async def dispatch(
        self,
        request: Request,
        call_next,
    ) -> Response:
        if request.method.upper() == "OPTIONS":
            return await call_next(request)

        client_key = self._build_rate_limit_key(request)
        is_allowed, remaining, reset_after = self._consume_token(client_key)

        if not is_allowed:
            return JSONResponse(
                status_code=429,
                content={"detail": "Rate limit exceeded."},
                headers=self._build_headers(remaining, reset_after),
            )

        response = await call_next(request)
        response.headers.update(
            self._build_headers(remaining, reset_after),
        )
        return response

    def _build_rate_limit_key(self, request: Request) -> str:
        return f"{request.method.upper()}:{request.url.path}"

    def _consume_token(self, client_key: str) -> tuple[bool, int, int]:
        now = time.time()

        with self._lock:
            request_times = self._requests[client_key]

            while request_times and request_times[0] <= now - self._window_seconds:
                request_times.popleft()

            if len(request_times) >= self._max_requests:
                reset_after = max(
                    1,
                    int(request_times[0] + self._window_seconds - now),
                )
                return False, 0, reset_after

            request_times.append(now)
            remaining = self._max_requests - len(request_times)
            reset_after = max(
                1,
                int(request_times[0] + self._window_seconds - now),
            )

            return True, remaining, reset_after

    def _build_headers(self, remaining: int, reset_after: int) -> dict[str, str]:
        return {
            "X-RateLimit-Limit": str(self._max_requests),
            "X-RateLimit-Remaining": str(remaining),
            "X-RateLimit-Reset": str(reset_after),
        }
