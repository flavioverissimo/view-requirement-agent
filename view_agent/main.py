import argparse
import os
import sys
from pathlib import Path

from dotenv import load_dotenv

from requirement_workflow import build_requirement_graph
from classes.agent_output import RequirementAgentOutput
from file_io.save_json import save_json

PROJECT_ROOT = Path(__file__).resolve().parent

load_dotenv(dotenv_path=PROJECT_ROOT / ".env")


def _build_cli_parser() -> argparse.ArgumentParser:
    help_examples = """Examples:
  python main.py
  python main.py --input_view "DBpedia Artist Exported View" --input_criterion "Musical artists should have good homepage coverage."
  python main.py --input_view "DBpedia Artist Exported View" --input_criterion "Musical artists should have good homepage coverage." --output_file "result\\result.json"
"""
    parser = argparse.ArgumentParser(
        description="Run the requirement interpretation workflow.",
        epilog=help_examples,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--input_view",
        "--input-view",
        dest="input_view",
        default="DBpedia Artist Exported View",
        help="View name used as workflow input.",
    )
    parser.add_argument(
        "--input_criterion",
        "--input-criterion",
        dest="input_criterion",
        default="Musical artists should have good homepage coverage.",
        help="Natural-language criterion interpreted by the workflow.",
    )
    parser.add_argument(
        "--output_file",
        "--output-file",
        dest="output_file",
        default=None,
        help=(
            "Optional file path where the JSON result should also be saved. "
            "If omitted, the workflow prints the JSON only to stdout."
        ),
    )
    return parser


def _resolve_output_file(output_file: str | None) -> Path | None:
    if not output_file or not output_file.strip():
        return None

    return Path(output_file).expanduser().resolve()

def _extract_valid_result(
    workflow_output: dict[str, object],
) -> RequirementAgentOutput | None:
    validation_status = workflow_output.get("validation_status")

    if validation_status != "valid_structure":
        return None

    structured_result = workflow_output.get("structured_result")

    if not isinstance(structured_result, RequirementAgentOutput):
        raise TypeError(
            "The graph returned validation_status='valid_structure' without a "
            "valid RequirementAgentOutput."
        )

    return structured_result


def _persist_result_if_requested(
    structured_result: RequirementAgentOutput,
    output_file: str | None,
) -> Path | None:
    resolved_output_file = _resolve_output_file(output_file)

    if resolved_output_file is None:
        return None

    try:
        save_json(
            data=structured_result.model_dump(mode="json"),
            file_path=resolved_output_file,
        )
    except Exception as error:
        raise RuntimeError("Failed to persist the agent result.") from error

    return resolved_output_file


def main(
    input_view: str = "DBpedia Artist Exported View",
    input_criterion: str = "Musical artists should have good homepage coverage.",
    output_file: str | None = None,
) -> RequirementAgentOutput | None:
    try:
        workflow_agent = build_requirement_graph()
        workflow_output = workflow_agent.invoke(
            {
                "view_name": input_view,
                "criterion": input_criterion,
            }
        )
    except Exception as error:
        raise RuntimeError("Failed to execute the requirement workflow.") from error

    if not isinstance(workflow_output, dict):
        raise TypeError("The graph returned a result in an unexpected format.")

    structured_result = _extract_valid_result(workflow_output)

    if structured_result is None:
        return None

    _persist_result_if_requested(
        structured_result=structured_result,
        output_file=output_file,
    )

    return structured_result


if __name__ == "__main__":
    cli_arguments = _build_cli_parser().parse_args()
    try:
        structured_result = main(
            input_view=cli_arguments.input_view,
            input_criterion=cli_arguments.input_criterion,
            output_file=cli_arguments.output_file,
        )
    except Exception as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1) from error

    if structured_result is None:
        print(
            "The workflow completed without a valid structured result.",
            file=sys.stderr,
        )
        raise SystemExit(1)

    print(structured_result.to_json())
