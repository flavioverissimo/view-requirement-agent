function titleizeStatus(status) {
  if (status === "valid") {
    return "Valid interpretation";
  }
  if (status === "clarification_required") {
    return "Clarification required";
  }
  if (status === "insufficient_context") {
    return "Insufficient context";
  }
  if (status === "unsupported_dimension") {
    return "Unsupported dimension";
  }
  if (status === "unsupported_as_primary_requirement") {
    return "Out of scope as a primary requirement";
  }
  return status || "Response without a recognized status";
}

function pushList(lines, title, values) {
  if (!Array.isArray(values) || values.length === 0) {
    return;
  }
  lines.push(`## ${title}`, "");
  for (const value of values) {
    lines.push(`- ${value}`);
  }
  lines.push("");
}

function pushScope(lines, scope) {
  if (!scope) {
    return;
  }
  const scopeLines = [
    ["Target view", scope.target_view],
    ["Target class", scope.target_class],
    ["Target property", scope.target_property],
    [
      "Target properties",
      Array.isArray(scope.target_properties) && scope.target_properties.length > 0
        ? scope.target_properties.join(", ")
        : null,
    ],
    ["Expected node kind", scope.expected_node_kind],
    ["Expected domain", scope.expected_domain],
    ["Expected range", scope.expected_range],
    ["Reference time", scope.reference_time],
  ].filter(([, value]) => value);

  if (scopeLines.length === 0) {
    return;
  }

  lines.push("### Scope", "");
  for (const [label, value] of scopeLines) {
    lines.push(`- **${label}:** ${value}`);
  }
  lines.push("");
}

function pushMetric(lines, title, metric) {
  if (!metric) {
    return;
  }
  lines.push(`### ${title}`, "");
  lines.push(`- **URI:** ${metric.uri}`);
  lines.push(`- **Evidence type:** ${metric.evidence_type}`);
  lines.push("");
}

function pushRecognizedScope(lines, recognizedScope) {
  if (!recognizedScope) {
    return;
  }
  const values = [
    ["Target view", recognizedScope.target_view],
    ["Target class", recognizedScope.target_class],
    ["Target property", recognizedScope.target_property],
  ].filter(([, value]) => value);
  if (values.length === 0) {
    return;
  }
  lines.push("## Recognized scope", "");
  for (const [label, value] of values) {
    lines.push(`- **${label}:** ${value}`);
  }
  lines.push("");
}

function formatThreshold(threshold) {
  if (!threshold) {
    return null;
  }
  return threshold.unit ? `${threshold.value} ${threshold.unit}` : String(threshold.value);
}

function formatValidResponse(lines, response) {
  const requirements = Array.isArray(response?.requirements) ? response.requirements : [];
  lines.push("## Formal requirements", "");
  lines.push(`Number of returned requirements: **${requirements.length}**`, "");

  requirements.forEach((requirement, index) => {
    lines.push(`### Requirement ${index + 1}`, "");
    if (requirement.requirement_id) {
      lines.push(`- **Requirement ID:** ${requirement.requirement_id}`);
    }
    lines.push(`- **Original criterion:** ${requirement.original_criterion}`);
    lines.push(`- **Dimension:** ${requirement.dimension}`);
    lines.push(`- **Quality level:** ${requirement.quality_level}`);
    lines.push(`- **Operator:** ${requirement.operator}`);
    lines.push(`- **Threshold:** ${formatThreshold(requirement.threshold)}`);
    lines.push("");

    if (requirement.ekg) {
      lines.push("### EKG", "");
      lines.push(`- **Name:** ${requirement.ekg.name}`);
      if (requirement.ekg.uri) {
        lines.push(`- **URI:** ${requirement.ekg.uri}`);
      }
      if (requirement.ekg.metadata_graph) {
        lines.push(`- **Metadata graph:** ${requirement.ekg.metadata_graph}`);
      }
      if (requirement.ekg.quality_metadata_graph) {
        lines.push(`- **Quality metadata graph:** ${requirement.ekg.quality_metadata_graph}`);
      }
      if (requirement.ekg.data_graph) {
        lines.push(`- **Data graph:** ${requirement.ekg.data_graph}`);
      }
      lines.push("");
    }

    if (requirement.view) {
      lines.push("### View", "");
      lines.push(`- **Name:** ${requirement.view.name}`);
      lines.push(`- **URI:** ${requirement.view.uri}`);
      lines.push(`- **Type:** ${requirement.view.type}`);
      lines.push("");
    }

    pushMetric(lines, "Observed metric", requirement.observed_metric);
    pushMetric(lines, "Expected metric", requirement.expected_metric);
    pushScope(lines, requirement.scope);

    if (requirement.interpretation_note) {
      lines.push("### Interpretation note", "", requirement.interpretation_note, "");
    }
  });
}

function formatClarificationResponse(lines, response) {
  lines.push("## Reason", "", response.reason, "");
  pushList(lines, "Missing or ambiguous fields", response.missing_or_ambiguous_fields);
  pushList(lines, "Candidate metrics", response.candidate_metrics);
  if (response.clarification_question) {
    lines.push("## Clarification question", "", response.clarification_question, "");
  }
  pushRecognizedScope(lines, response.recognized_scope);
}

function formatInsufficientContextResponse(lines, response) {
  lines.push("## Reason", "", response.reason, "");
  pushList(lines, "Missing information", response.missing_information);
  pushList(lines, "Candidate metrics", response.candidate_metrics);
  pushRecognizedScope(lines, response.recognized_scope);
}

function formatUnsupportedResponse(lines, response) {
  lines.push("## Reason", "", response.reason, "");
  pushList(lines, "Candidate metrics", response.candidate_metrics);
  pushRecognizedScope(lines, response.recognized_scope);
}

export function formatRuntimeResultMarkdown({
  response,
  resolvedView,
  agentInput,
  rawOutput,
}) {
  const lines = [];
  lines.push("# Interpretation Result", "");

  if (response?.status) {
    lines.push(`**Status:** ${titleizeStatus(response.status)}`, "");
  }
  if (resolvedView) {
    lines.push(`**Selected view:** ${resolvedView.name}`, "");
    lines.push(`**Resolved type:** \`${resolvedView.type}\``, "");
  }

  if (response?.status === "valid") {
    formatValidResponse(lines, response);
  } else if (response?.status === "clarification_required") {
    formatClarificationResponse(lines, response);
  } else if (response?.status === "insufficient_context") {
    formatInsufficientContextResponse(lines, response);
  } else if (
    response?.status === "unsupported_dimension" ||
    response?.status === "unsupported_as_primary_requirement"
  ) {
    formatUnsupportedResponse(lines, response);
  } else {
    lines.push(
      "## Unstructured response",
      "",
      "The output did not match the expected schema. The raw response was preserved below for auditing.",
      ""
    );
  }

  if (agentInput) {
    lines.push("## Input sent to the model", "");
    lines.push("```json");
    lines.push(JSON.stringify(agentInput, null, 2));
    lines.push("```", "");
  }

  if (rawOutput) {
    lines.push("## Raw model output", "");
    lines.push("```json");
    lines.push(rawOutput);
    lines.push("```");
  }

  return lines.join("\n");
}
