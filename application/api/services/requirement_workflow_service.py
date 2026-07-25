from __future__ import annotations

from functools import lru_cache

from dotenv import load_dotenv

from core.config import get_settings
from core.exceptions import (
    WorkflowExecutionError,
    WorkflowInvalidResultError,
)
from workflow.classes.agent_output import RequirementAgentOutput
from workflow.requirement_workflow import build_requirement_graph


class RequirementWorkflowService:
    def __init__(self) -> None:
        settings = get_settings()
        load_dotenv(dotenv_path=settings.project_root / ".env")
        self._workflow_agent = build_requirement_graph()

    def interpret(
        self,
        *,
        view_name: str,
        criterion: str,
    ) -> RequirementAgentOutput:
        try:
            workflow_output = self._workflow_agent.invoke(
                {
                    "view_name": view_name,
                    "criterion": criterion,
                }
            )
        except Exception as error:
            raise WorkflowExecutionError() from error

        if not isinstance(workflow_output, dict):
            raise WorkflowInvalidResultError(
                "The workflow returned a result in an unexpected format."
            )

        validation_status = workflow_output.get("validation_status")

        if validation_status != "valid_structure":
            raise WorkflowInvalidResultError(
                "The workflow completed without a valid structured result."
            )

        structured_result = workflow_output.get("structured_result")

        if not isinstance(structured_result, RequirementAgentOutput):
            raise WorkflowInvalidResultError(
                "The workflow returned validation_status='valid_structure' "
                "without a valid RequirementAgentOutput."
            )

        return structured_result


@lru_cache
def get_requirement_workflow_service() -> RequirementWorkflowService:
    return RequirementWorkflowService()
