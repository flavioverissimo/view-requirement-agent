from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends

from controllers.requirements_controller import RequirementController
from schemas.common import ErrorResponse
from schemas.requirements import RequirementRequest, RequirementResponse
from services.requirement_workflow_service import (
    get_requirement_workflow_service,
)

router = APIRouter(prefix="/requirements", tags=["requirements"])


def get_requirement_controller() -> RequirementController:
    workflow_service = get_requirement_workflow_service()
    return RequirementController(workflow_service)


@router.post(
    "/interpret",
    response_model=RequirementResponse,
    responses={
        429: {"model": ErrorResponse},
        500: {"model": ErrorResponse},
        502: {"model": ErrorResponse},
    },
)
def interpret_requirement(
    request_data: RequirementRequest,
    controller: Annotated[
        RequirementController,
        Depends(get_requirement_controller),
    ],
) -> RequirementResponse:
    return controller.interpret(request_data)
