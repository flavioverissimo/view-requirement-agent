from __future__ import annotations


class APIError(Exception):
    status_code = 500
    detail = "An unexpected error occurred."

    def __init__(self, detail: str | None = None) -> None:
        super().__init__(detail or self.detail)
        self.detail = detail or self.detail


class WorkflowExecutionError(APIError):
    status_code = 500
    detail = "Failed to execute the requirement workflow."


class WorkflowInvalidResultError(APIError):
    status_code = 502
    detail = "The workflow returned an invalid structured result."
