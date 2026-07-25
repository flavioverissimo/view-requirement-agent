from __future__ import annotations

from schemas.requirements import RequirementRequest, RequirementResponse
from services.requirement_workflow_service import (
    RequirementWorkflowService,
)


class RequirementController:
    def __init__(self, service: RequirementWorkflowService) -> None:
        self._service = service

    def interpret(
        self,
        request_data: RequirementRequest,
    ) -> RequirementResponse:
        workflow_result = self._service.interpret(
            view_name=request_data.view_name,
            criterion=request_data.criterion,
        )
        return RequirementResponse(result=workflow_result)
