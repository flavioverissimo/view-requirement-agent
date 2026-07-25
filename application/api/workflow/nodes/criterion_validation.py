import os

from langchain.agents import create_agent
from langchain.messages import HumanMessage
from pydantic import ValidationError

from workflow.classes.agent_output import RequirementAgentOutput
from workflow.classes.state import RequirementWorkflowState


def _get_required_state_text(
    workflow_state: RequirementWorkflowState,
    key: str,
) -> str:
    value = workflow_state.get(key)

    if not isinstance(value, str) or not value.strip():
        raise ValueError(
            f"The field '{key}' must be populated before validation."
        )

    return value


def _build_validation_agent(final_system_prompt: str):
    model_name = os.getenv("OPENAI_MODEL", "").strip()

    if not model_name:
        raise RuntimeError(
            "The OPENAI_MODEL environment variable is not configured."
        )

    return create_agent(
        model=model_name,
        system_prompt=final_system_prompt,
        response_format=RequirementAgentOutput,
    )


def _validate_structured_response(
    agent_response: object,
) -> RequirementAgentOutput:
    if not isinstance(agent_response, dict):
        raise TypeError("The agent response is not in the expected format.")

    structured_response = agent_response.get("structured_response")

    if structured_response is None:
        raise ValueError("The agent response did not include structured_response.")

    if isinstance(structured_response, RequirementAgentOutput):
        return structured_response

    return RequirementAgentOutput.model_validate(structured_response)


def _mark_invalid_result(
    workflow_state: RequirementWorkflowState,
) -> RequirementWorkflowState:
    workflow_state["structured_result"] = None
    workflow_state["validation_status"] = "invalid_structure"
    return workflow_state


def validate_state_with_prompt(
    workflow_state: RequirementWorkflowState,
    criterion_message_template: str,
) -> RequirementWorkflowState:
    try:
        criterion_text = _get_required_state_text(
            workflow_state,
            "criterion",
        )
        final_system_prompt = _get_required_state_text(
            workflow_state,
            "final_system_prompt",
        )
        validation_agent = _build_validation_agent(final_system_prompt)
        agent_response = validation_agent.invoke(
            {
                "messages": HumanMessage(
                    content=criterion_message_template.format(
                        criterion_text=criterion_text
                    )
                )
            }
        )
        structured_response = _validate_structured_response(agent_response)
    except ValidationError:
        return _mark_invalid_result(workflow_state)
    except Exception:
        return _mark_invalid_result(workflow_state)

    workflow_state["structured_result"] = structured_response
    workflow_state["validation_status"] = "valid_structure"
    return workflow_state


def validate_criterion(
    workflow_state: RequirementWorkflowState,
) -> RequirementWorkflowState:
    return validate_state_with_prompt(
        workflow_state,
        "User criterion: {criterion_text}",
    )
