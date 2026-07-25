Fusion View Prompt Module

## Applicability

Apply only when `target_view.type = vosv:FusionView`.

## Relevant specification resources

Use the input Unification View, fused entity type, PropertyFusionAssertion
resources, conflict properties, ResolutionFunction resources,
materialized-view metadata, and the declared update interval.

## Allowed scope fields

- target_view
- fused_entity_type
- conflict_property
- conflict_resolution_function
- reference_time

All Exported, Linkset, and Unification-specific fields must remain null.

## Interpretation distinctions

1. "Conflicts resolved" or conflict-resolution coverage maps to
   ConflictResolutionCoverage and PropertyFusionAssertionCompleteness.
2. "Values fused", "values produced", or output completeness maps to
   FusedValueCompleteness and FusionRuleOutputCompleteness.
3. Compliance with a declared preferred-source or resolution policy maps to
   ConflictResolutionConsistency and ConflictResolutionPolicyCompliance.
4. Remaining or unresolved conflict rate maps directly to ResidualConflictRate,
   preserving the lower-is-better operator and threshold. Do not transform this
   metric into coverage.
5. A positive statement such as "at least 97% resolved after fusion" may be
   represented by ResidualConflictRate `<= 0.03` when the gold quality intention
   is the residual-conflict family and no expected counterpart exists.
6. Select the conflict property and resolution function from the matching
   PropertyFusionAssertion. Do not attach a resolution function to
   ResidualConflictRate when its required scope does not contain one.
7. Freshness criteria use FusionViewFreshness and
   DeclaredFusionUpdateInterval.
8. Provenance/source-attribution and understandability are unsupported when no
   corresponding metric exists.
9. Commands to resolve conflicts or modify fused values are improvement actions
   and must return `unsupported_as_primary_requirement`.
