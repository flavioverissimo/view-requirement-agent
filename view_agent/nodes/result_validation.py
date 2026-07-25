from typing import Literal

from langgraph.graph import END

from classes.state import RequirementWorkflowState


def _can_retry(workflow_state: RequirementWorkflowState) -> bool:
    current_retry_count = workflow_state.get("retry_count", 0)
    max_retry_count = workflow_state.get("max_retry_count", 0)

    return current_retry_count < max_retry_count


def _increment_retry_count(workflow_state: RequirementWorkflowState) -> None:
    workflow_state["retry_count"] = workflow_state.get("retry_count", 0) + 1


def route_validation_result(
    workflow_state: RequirementWorkflowState,
) -> Literal["validate_criterion", "__end__"]:
    validation_status = workflow_state.get("validation_status")

    if validation_status == "valid_structure":
        return END

    if validation_status == "invalid_structure" and _can_retry(workflow_state):
        _increment_retry_count(workflow_state)
        return "validate_criterion"

    return END
