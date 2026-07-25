from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator

RequirementInterpretationStatus = Literal[
    "valid",
    "clarification_required",
    "insufficient_context",
    "unsupported_dimension",
    "unsupported_as_primary_requirement",
]


class StrictRequirementOutputModel(BaseModel):
    """Base configuration for requirement output models."""

    model_config = ConfigDict(extra="forbid")


class EKGReference(StrictRequirementOutputModel):
    name: str | None = Field(
        default=None,
        description="Name of the EKG associated with the requirement.",
    )
    uri: str | None = Field(
        default=None,
        description="URI that identifies the EKG.",
    )
    metadata_graph: str | None = Field(
        default=None,
        description="Metadata graph URI or identifier.",
    )
    quality_metadata_graph: str | None = Field(
        default=None,
        description="Quality metadata graph URI or identifier.",
    )
    data_graph: str | None = Field(
        default=None,
        description="Data graph URI or identifier.",
    )


class ViewReference(StrictRequirementOutputModel):
    name: str | None = Field(
        default=None,
        description="Recognized view name.",
    )
    uri: str | None = Field(
        default=None,
        description="URI that identifies the view.",
    )
    type: str | None = Field(
        default=None,
        description="View type.",
    )


class MetricReference(StrictRequirementOutputModel):
    uri: str | None = Field(
        default=None,
        description="URI that identifies the metric.",
    )
    evidence_type: str | None = Field(
        default=None,
        description="Evidence type represented by the metric.",
    )


class RequirementScope(StrictRequirementOutputModel):
    target_view: str | None = Field(
        default=None,
        description="View to which the requirement applies.",
    )
    target_class: str | None = Field(
        default=None,
        description="Target class of the requirement.",
    )
    target_property: str | None = Field(
        default=None,
        description="Primary target property.",
    )
    target_properties: list[str] = Field(
        default_factory=list,
        description="List of target properties.",
    )
    source_class: str | None = Field(
        default=None,
        description="Source class.",
    )
    target_entity_type: str | None = Field(
        default=None,
        description="Expected target entity type.",
    )
    link_predicate: str | None = Field(
        default=None,
        description="Predicate that connects source and target.",
    )
    generalization_class: str | None = Field(
        default=None,
        description="Class used for generalization.",
    )
    canonical_resource: str | None = Field(
        default=None,
        description="Canonical resource used in the evaluation.",
    )
    normalization_function: str | None = Field(
        default=None,
        description="Function used to normalize values.",
    )
    fused_entity_type: str | None = Field(
        default=None,
        description="Entity type resulting from fusion.",
    )
    conflict_property: str | None = Field(
        default=None,
        description="Property where conflicts are identified.",
    )
    conflict_resolution_function: str | None = Field(
        default=None,
        description="Function used to resolve conflicts.",
    )
    expected_node_kind: str | None = Field(
        default=None,
        description="Expected RDF node kind.",
    )
    expected_domain: str | None = Field(
        default=None,
        description="Expected property domain.",
    )
    expected_range: str | None = Field(
        default=None,
        description="Expected property range.",
    )
    reference_time: str | None = Field(
        default=None,
        description="Reference time for temporal evaluation.",
    )


class Threshold(StrictRequirementOutputModel):
    value: float | None = Field(
        default=None,
        description="Numeric threshold value.",
    )
    unit: str | None = Field(
        default=None,
        description="Threshold unit.",
    )


class RequirementInterpretation(StrictRequirementOutputModel):
    requirement_id: str = Field(
        description="Unique identifier of the interpreted requirement.",
    )
    original_criterion: str = Field(
        description="Original criterion provided by the user.",
    )
    ekg: EKGReference = Field(
        description="EKG recognized in the requirement.",
    )
    view: ViewReference = Field(
        description="View recognized in the requirement.",
    )
    dimension: str | None = Field(
        default=None,
        description="Recognized quality dimension.",
    )
    quality_level: str | None = Field(
        default=None,
        description="Recognized quality level.",
    )
    observed_metric: MetricReference = Field(
        description="Metric used for the observed value.",
    )
    expected_metric: MetricReference = Field(
        description="Metric used for the expected value.",
    )
    scope: RequirementScope = Field(
        description="Scope extracted from the requirement.",
    )
    operator: str | None = Field(
        default=None,
        description="Requirement comparison operator.",
    )
    threshold: Threshold = Field(
        description="Threshold extracted from the criterion.",
    )
    interpretation_note: str | None = Field(
        default=None,
        description="Additional interpretation note.",
    )


class RequirementAgentOutput(StrictRequirementOutputModel):
    """Structured output contract for the requirement interpretation agent."""

    status: RequirementInterpretationStatus = Field(
        description=(
            "Interpretation status: valid, clarification_required, "
            "insufficient_context, unsupported_dimension or "
            "unsupported_as_primary_requirement."
        )
    )
    reason: str | None = Field(
        default=None,
        description="Reason associated with the status.",
    )
    requirements: list[RequirementInterpretation] = Field(
        default_factory=list,
        max_length=1,
        description="Interpreted requirements. Must contain at most one item.",
    )
    missing_or_ambiguous_fields: list[str] = Field(
        default_factory=list,
        description="Missing, ambiguous or unclear fields.",
    )
    missing_information: list[str] = Field(
        default_factory=list,
        description="Information still needed to complete the interpretation.",
    )
    candidate_metrics: list[str] = Field(
        default_factory=list,
        description="Candidate metric URIs identified by the agent.",
    )
    clarification_question: str | None = Field(
        default=None,
        description="Question to ask when clarification is required.",
    )
    recognized_scope: RequirementScope = Field(
        default_factory=RequirementScope,
        description=(
            "Recognized scope, including cases where a complete requirement "
            "cannot be produced."
        ),
    )

    @model_validator(mode="after")
    def validate_status_invariants(self) -> RequirementAgentOutput:
        if self.status == "valid":
            if len(self.requirements) != 1:
                raise ValueError(
                    "Status 'valid' requires exactly one requirement."
                )

            if self.reason is not None:
                raise ValueError("Status 'valid' requires reason to be None.")

            if self.missing_or_ambiguous_fields:
                raise ValueError(
                    "Status 'valid' requires missing_or_ambiguous_fields to be empty."
                )

            if self.missing_information:
                raise ValueError(
                    "Status 'valid' requires missing_information to be empty."
                )

            if self.candidate_metrics:
                raise ValueError(
                    "Status 'valid' requires candidate_metrics to be empty."
                )

            if self.clarification_question is not None:
                raise ValueError(
                    "Status 'valid' requires clarification_question to be None."
                )

            return self

        if self.requirements:
            raise ValueError(
                "Statuses other than 'valid' require requirements to be empty."
            )

        if self.status == "clarification_required":
            if not self.clarification_question:
                raise ValueError(
                    "Status 'clarification_required' requires clarification_question."
                )

            if not self.missing_or_ambiguous_fields:
                raise ValueError(
                    "Status 'clarification_required' requires ambiguous or "
                    "missing fields to be listed."
                )

        if self.status in {
            "insufficient_context",
            "unsupported_dimension",
            "unsupported_as_primary_requirement",
        } and not self.reason:
            raise ValueError(
                f"Status '{self.status}' requires a concise reason."
            )

        return self

    def to_json(self, *, indent: int = 2) -> str:
        """Serialize the full output as a JSON string."""

        return self.model_dump_json(
            indent=indent,
            exclude_none=False,
        )
