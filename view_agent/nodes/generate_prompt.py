from classes.state import RequirementWorkflowState


def _get_required_prompt_section(
    workflow_state: RequirementWorkflowState,
    key: str,
) -> str:
    value = workflow_state.get(key)

    if not isinstance(value, str) or not value.strip():
        raise ValueError(
            f"The field '{key}' must be populated before generating the prompt."
        )

    return value


def generate_final_prompt(
    workflow_state: RequirementWorkflowState,
) -> RequirementWorkflowState:
    system_prompt = _get_required_prompt_section(
        workflow_state,
        "system_prompt",
    )
    skill_instructions = _get_required_prompt_section(
        workflow_state,
        "skill",
    )
    retrieved_context = _get_required_prompt_section(
        workflow_state,
        "context",
    )
    result_examples = _get_required_prompt_section(
        workflow_state,
        "examples",
    )
    prompt_suffix = f"""

# You need to follow this skill to fix issues from now on:
{skill_instructions}

# Context:
{retrieved_context}

# Examples of Results:
{result_examples}

"""

    workflow_state["final_system_prompt"] = system_prompt + prompt_suffix

    return workflow_state
