from typing import Literal, TypedDict

from workflow.classes.agent_output import RequirementAgentOutput

WorkflowValidationStatus = Literal["valid_structure", "invalid_structure"]


class RequirementWorkflowInputState(TypedDict):
    criterion: str
    view_name: str


class RequirementWorkflowOutputState(TypedDict):
    structured_result: RequirementAgentOutput | None = None
    validation_status: WorkflowValidationStatus


class RequirementWorkflowState(TypedDict):
    criterion: str
    view_name: str
    view_type: str | None = None
    system_prompt: str | None = None
    final_system_prompt: str | None = None
    context: str | None = None
    examples: str | None = None
    skill: str | None = None
    max_retry_count: int = 2
    retry_count: int = 0
    structured_result: RequirementAgentOutput | None = None
    validation_status: WorkflowValidationStatus
