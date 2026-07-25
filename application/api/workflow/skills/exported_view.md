Exported View Prompt Module

## Applicability

Apply only when `target_view.type = vosv:ExportedView`.

## Relevant specification resources

Use the data source, ontology fragment, mappings container, logical mappings,
materialized-view metadata, and declared update interval. Ontology domain,
range, expected node kind, and datatype are valid grounding evidence.

## Allowed scope fields

- target_view
- target_class
- target_property
- target_properties
- expected_node_kind
- expected_domain
- expected_range
- reference_time

All Linkset, Unification, and Fusion scope fields must remain null.

## Interpretation rules

1. A criterion about the proportion of instances having one property maps to
   property/attribute coverage at AttributeLevel.
2. A criterion about completeness across a selected property set for all class
   instances maps to class-level attribute completeness.
3. A criterion requiring values to be IRIs or literals maps to node-kind
   consistency and must ground `expected_node_kind`.
4. A criterion about declared domain and range maps to domain-range consistency
   and must ground both expected values.
5. A criterion explicitly about a property mapping in the specification is
   specification-only and selects the expected mapping metric only.
6. A criterion asking only whether a class mapping exists is
   `insufficient_context` when the catalog has no class-mapping-presence metric.
7. "The mapping must be correct" is ambiguous when completeness, node-kind, and
   domain/range specification metrics remain possible.
8. Vague property completeness with a known property but no threshold requires
   clarification for the threshold.
9. Freshness criteria use ViewFreshness and DeclaredUpdateInterval.
10. A requirement that a value must originate from a named source is unsupported
    when no provenance/source-origin metric is present.
