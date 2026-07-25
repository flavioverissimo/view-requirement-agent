Unification View Prompt Module

## Applicability

Apply only when `target_view.type = vosv:UnificationView`.

## Relevant specification resources

Use source Linkset Views, the generalization class, canonical resource,
NormalizationFunction resources, source entity types, materialized-view
metadata, and the declared update interval.

## Allowed scope fields

- target_view
- generalization_class
- canonical_resource
- normalization_function
- link_predicate
- reference_time

All Exported, Linkset class-pair, and Fusion-specific fields must remain null.

## Deterministic function grounding

The context declares an identity-resolution function and a name-normalization
function. For canonicalization coverage, entity unification, canonical entity
creation, or owl:sameAs normalization, select
`svm:ArtistIdentityResolutionFunction`. Select the name-normalization function
only when the criterion explicitly concerns name-value normalization.

Thus, generic phrases such as "the declared normalization function" do not
require clarification when the criterion's quality aspect is canonicalization
or sameAs normalization and the applicable identity-resolution function is
uniquely determined by this rule.

## Interpretation rules

1. Canonicalization or unification coverage maps to CanonicalizationCoverage and
   NormalizationFunctionCompleteness.
2. "No more than X% outside canonicalization" is normalized to positive
   canonicalization coverage.
3. Remaining duplicate rate maps directly to DuplicateResidualRate, which is
   lower-is-better. Do not replace it with an invented positive metric.
4. Unique canonical identifiers map to CanonicalIRIUniqueness and
   NormalizationUniquenessConstraint, grounding the canonical resource.
5. owl:sameAs compliance with identity normalization maps to
   SameAsNormalizationConsistency and NormalizationFunctionConsistency.
6. Freshness criteria use UnificationViewFreshness and
   DeclaredUnificationUpdateInterval.
7. Provenance/source-attribution and understandability are unsupported when no
   corresponding metric exists.
8. Commands to generate canonical entities or eliminate duplicates are
   improvement actions, not primary quality requirements.