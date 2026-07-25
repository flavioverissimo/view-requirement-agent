from langgraph.graph import StateGraph, START

from classes.state import (
    RequirementWorkflowInputState,
    RequirementWorkflowOutputState,
    RequirementWorkflowState,
)
from nodes.load_view_information import load_view_information
from nodes.generate_prompt import generate_final_prompt
from nodes.criterion_validation import validate_criterion
from nodes.result_validation import route_validation_result


def build_requirement_graph():
    workflow_graph = StateGraph(
        state_schema=RequirementWorkflowState,
        input_schema=RequirementWorkflowInputState,
        output_schema=RequirementWorkflowOutputState,
    )

    # Langgraph Nodes
    workflow_graph.add_node("load_view_information", load_view_information)
    workflow_graph.add_node("generate_final_prompt", generate_final_prompt)
    workflow_graph.add_node("validate_criterion", validate_criterion)

    # Langgraph Edges
    workflow_graph.add_edge(START, "load_view_information")
    workflow_graph.add_edge(
        "load_view_information",
        "generate_final_prompt",
    )
    workflow_graph.add_edge(
        "generate_final_prompt",
        "validate_criterion",
    )
    workflow_graph.add_conditional_edges(
        "validate_criterion",
        route_validation_result,
    )

    compiled_workflow = workflow_graph.compile()

    return compiled_workflow
