Linkset View Prompt Module

## Applicability

Apply only when `target_view.type = vosv:LinksetView`.

## Relevant specification resources

Use source and target Exported Views, LinkRule resources, source and target
classes, link predicate, MatchFunction resources, materialized-view metadata,
and the declared update interval.

## Allowed scope fields

- target_view
- source_class
- target_entity_type
- link_predicate
- reference_time

All Exported, Unification, and Fusion-specific fields must remain null.

## Interpretation rules

1. The proportion of source entities linked to target entities is link coverage.
2. "No more than X% unlinked" is the complement of LinkCoverage.
3. Compliance of generated links with the declared predicate is link-predicate
   consistency.
4. Consistency of owl:sameAs chains is SameAsChainConsistency; include its
   expected transitivity-support counterpart when compatible.
5. Correctness of entity matches is LinkAccuracy with MatchFunctionValidity.
6. Completeness of the LinkRule itself is specification-only and selects
   LinkRuleCompleteness.
7. Vague link quality such as "links should be good" is ambiguous among primary
   observed link metrics and also lacks a threshold.
8. If the link predicate is not explicitly named but the criterion unambiguously
   refers to the only declared LinkRule and its link family, use that rule's
   predicate. Do not ask for a redundant predicate clarification.
9. Freshness criteria use LinksetFreshness and DeclaredLinksetUpdateInterval.
10. Commands to create, generate, repair, or add links are improvement actions
    and must return `unsupported_as_primary_requirement`.
