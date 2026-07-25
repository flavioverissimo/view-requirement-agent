from __future__ import annotations

from pydantic import AliasChoices, BaseModel, ConfigDict, Field

from workflow.classes.agent_output import RequirementAgentOutput


class RequirementRequest(BaseModel):
    model_config = ConfigDict(
        extra="forbid",
        str_strip_whitespace=True,
    )

    view_name: str = Field(
        ...,
        min_length=1,
        max_length=255,
        validation_alias=AliasChoices("view_name", "input_view"),
        description="View name passed to the workflow.",
    )
    criterion: str = Field(
        ...,
        min_length=1,
        max_length=4000,
        validation_alias=AliasChoices("criterion", "input_criterion"),
        description="Natural-language criterion passed to the workflow.",
    )


class RequirementResponse(BaseModel):
    result: RequirementAgentOutput
