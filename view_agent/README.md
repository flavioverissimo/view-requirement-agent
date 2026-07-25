# Requirement Interpretation Workflow

## Overview
This repository contains a Python application that converts a natural-language quality criterion into a structured JSON output. The workflow is designed to support research validation scenarios in which users provide:

- a view name
- a natural-language quality criterion

The application loads the assets associated with the selected view, builds a prompt, invokes an OpenAI-backed agent, validates the structured response, and returns a machine-readable JSON result.

This project was prepared to be usable by people with different levels of technical experience. For that reason, the repository includes setup scripts for Windows, Linux, and macOS.

## What the Application Does
At a high level, the workflow performs the following steps:

1. Loads the selected view definition from `dictionary.json`.
2. Loads the prompt configuration from `prompt_manifest.json`.
3. Loads the system prompt and view-specific assets such as examples, skill guidance, and context.
4. Sends the criterion to the model defined in the environment configuration.
5. Validates the returned structured output against the Pydantic schema.
6. Prints the final JSON to standard output.

## Supported Views
The repository currently includes the following view names:

- `DBpedia Artist Exported View`
- `MusicArtist Fusion View`
- `MusicArtist Linkset View`
- `MusicArtist Unification View`

These names must be passed exactly as they appear above when using the command-line interface.

## Repository Structure
The most important files and directories are:

- `main.py`: application entry point and command-line interface
- `requirement_workflow.py`: workflow graph construction
- `dictionary.json`: available views and their types
- `prompt_manifest.json`: prompt asset configuration per view type
- `system_prompt.md`: base system prompt
- `skills/`: view-type-specific instructions used during prompt construction
- `examples/`: example criteria and interpretations
- `contexts/`: view-specific domain context
- `setup.ps1`: recommended Windows setup script
- `setup.bat`: Windows setup wrapper for Command Prompt users
- `setup.sh`: Linux and macOS setup script
- `requirements.txt`: Python dependencies

## Requirements
To run the application, you need:

- Python 3.10 or newer
- internet access to call the OpenAI API
- an OpenAI API key

## Quick Start
Choose the setup command that matches your operating system.

### Windows PowerShell
This is the recommended setup path for Windows users:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

### Windows Command Prompt
If you prefer `cmd.exe`, run:

```bat
setup.bat
```

### Linux
Run:

```bash
bash setup.sh
```

### macOS
Run:

```bash
bash setup.sh
```

## What the Setup Scripts Do
The setup scripts are designed to be safe to run more than once. They do the following:

1. Check whether Python is installed.
2. Check whether the available Python version is at least 3.10.
3. If Python is missing, show installation guidance and download links.
4. Check whether a virtual environment already exists in `.venv`.
5. Create `.venv` only if it does not already exist.
6. Check whether the dependencies from `requirements.txt` are already installed and still valid.
7. Install dependencies only when they are missing, incompatible, or the environment is unhealthy.
8. Print the command needed to run the application.

## If Python Is Not Installed
The setup scripts will stop and show installation instructions if Python is not available.

They provide two installation options:

1. Official Python with IDLE  
   Download page: `https://www.python.org/downloads/`

2. Anaconda Distribution  
   Download page: `https://www.anaconda.com/download/success?reg=skipped`

After Python is installed, run the setup script again from the project root.

## Environment Configuration
Before running the application, create a `.env` file in the repository root.

The application expects the following variables:

- `OPENAI_API_KEY`
- `OPENAI_MODEL`

Example:

```env
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-5.4-mini
```

## Manual Setup
If you prefer not to use the setup scripts, you can prepare the environment manually.

### Windows PowerShell
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

### Windows Command Prompt
```bat
python -m venv .venv
.\.venv\Scripts\activate.bat
python -m pip install -r requirements.txt
```

### Linux and macOS
```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
```

## Running the Application
The application is executed through `main.py`.

### Default Execution
If you run the application without arguments, it uses the built-in defaults:

```bash
python main.py
```

Current default values:

- `input_view = "DBpedia Artist Exported View"`
- `input_criterion = "Musical artists should have good homepage coverage."`

### Custom Execution
You can pass your own view name and criterion:

```bash
python main.py --input_view "DBpedia Artist Exported View" --input_criterion "Musical artists should have good homepage coverage."
```

The command-line parser also accepts the hyphenated argument names:

```bash
python main.py --input-view "DBpedia Artist Exported View" --input-criterion "Musical artists should have good homepage coverage."
```

### Saving the Output to a File
By default, the application prints the result only to standard output.

If you also want to save the JSON to a file, use `--output_file`:

```bash
python main.py --input_view "DBpedia Artist Exported View" --input_criterion "Musical artists should have good homepage coverage." --output_file "result/result.json"
```

You can also use the hyphenated version:

```bash
python main.py --input-view "DBpedia Artist Exported View" --input-criterion "Musical artists should have good homepage coverage." --output-file "result/result.json"
```

### Help Command
To see the built-in CLI help and usage examples:

```bash
python main.py --help
```

## Important Command-Line Notes
If a view name or criterion contains spaces, wrap it in quotation marks.

Correct:

```bash
python main.py --input_view "DBpedia Artist Exported View"
```

Incorrect:

```bash
python main.py --input_view DBpedia Artist Exported View
```

Without quotation marks, the shell splits the value into multiple arguments.

## Output Behavior
On success, the application prints only the final JSON to `stdout`.

This makes the tool easier to integrate with:

- shell scripts
- backend services
- Node.js `spawn`
- automated evaluation pipelines

If the workflow fails before producing a valid structured result:

- the application prints the error message to `stderr`
- the process exits with code `1`

## Output Schema
The JSON output follows the schema defined in `classes/agent_output.py`.

At the top level, the output includes fields such as:

- `status`
- `reason`
- `requirements`
- `missing_or_ambiguous_fields`
- `missing_information`
- `candidate_metrics`
- `clarification_question`
- `recognized_scope`

The `status` field can be one of:

- `valid`
- `clarification_required`
- `insufficient_context`
- `unsupported_dimension`
- `unsupported_as_primary_requirement`

### Status Meaning
- `valid`: the criterion was interpreted successfully and exactly one structured requirement was produced
- `clarification_required`: the criterion looks relevant, but the user must clarify missing or ambiguous details
- `insufficient_context`: the criterion is understandable, but the available view context is not enough to interpret it safely
- `unsupported_dimension`: the criterion refers to a dimension that the workflow does not support
- `unsupported_as_primary_requirement`: the criterion is not a supported primary quality requirement for this workflow

## Example Output
The exact content depends on the model response, but a successful response has this general shape:

```json
{
  "status": "valid",
  "reason": null,
  "requirements": [
    {
      "requirement_id": "REQ-001",
      "original_criterion": "Musical artists should have good homepage coverage.",
      "ekg": {
        "name": null,
        "uri": null,
        "metadata_graph": null,
        "quality_metadata_graph": null,
        "data_graph": null
      },
      "view": {
        "name": "DBpedia Artist Exported View",
        "uri": "svm:EV_DBpedia_Artist",
        "type": "exported_view"
      },
      "dimension": "completeness",
      "quality_level": null,
      "observed_metric": {
        "uri": null,
        "evidence_type": null
      },
      "expected_metric": {
        "uri": null,
        "evidence_type": null
      },
      "scope": {
        "target_view": "DBpedia Artist Exported View",
        "target_class": null,
        "target_property": null,
        "target_properties": [],
        "source_class": null,
        "target_entity_type": null,
        "link_predicate": null,
        "generalization_class": null,
        "canonical_resource": null,
        "normalization_function": null,
        "fused_entity_type": null,
        "conflict_property": null,
        "conflict_resolution_function": null,
        "expected_node_kind": null,
        "expected_domain": null,
        "expected_range": null,
        "reference_time": null
      },
      "operator": null,
      "threshold": {
        "value": null,
        "unit": null
      },
      "interpretation_note": null
    }
  ],
  "missing_or_ambiguous_fields": [],
  "missing_information": [],
  "candidate_metrics": [],
  "clarification_question": null,
  "recognized_scope": {
    "target_view": "DBpedia Artist Exported View",
    "target_class": null,
    "target_property": null,
    "target_properties": [],
    "source_class": null,
    "target_entity_type": null,
    "link_predicate": null,
    "generalization_class": null,
    "canonical_resource": null,
    "normalization_function": null,
    "fused_entity_type": null,
    "conflict_property": null,
    "conflict_resolution_function": null,
    "expected_node_kind": null,
    "expected_domain": null,
    "expected_range": null,
    "reference_time": null
  }
}
```

This example is illustrative. Real responses depend on:

- the selected view
- the criterion wording
- the model output
- the available context for the selected view type

## Exit Codes
- `0`: the workflow completed and returned a valid structured JSON payload
- `1`: the workflow failed, the environment was not configured correctly, or the graph did not produce a valid structured result

## Troubleshooting
### `python` Is Not Recognized
This usually means Python is not installed or was not added to the system `PATH`.

Use one of the setup scripts first. If Python is missing, the script will show installation instructions and download links.

### PowerShell Blocks Script Execution
If PowerShell blocks scripts because of execution policy restrictions, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

### The `.venv` Directory Already Exists
This is not a problem. The setup scripts detect the existing environment and reuse it instead of creating a new one.

### Dependencies Are Already Installed
This is also expected. The setup scripts are idempotent and skip reinstallation when the environment already satisfies `requirements.txt`.

### Missing Environment Variables
If `OPENAI_MODEL` or `OPENAI_API_KEY` is missing or invalid, the workflow cannot run correctly. Verify that your `.env` file exists and contains valid values.

### The View Name Was Not Found
If the selected view is not in `dictionary.json`, the workflow will fail. Use one of the supported view names listed in the "Supported Views" section.

## Reproducibility Notes
For research and article validation scenarios, consider the following:

- use the same Python version across machines when possible
- use the same `OPENAI_MODEL` value across experiments
- keep a copy of the exact input criteria used in the evaluation
- save the JSON output for each run when reproducibility is important

For reproducible output capture, prefer:

```bash
python main.py --input_view "DBpedia Artist Exported View" --input_criterion "Musical artists should have good homepage coverage." --output_file "result/result.json"
```

## Recommended Workflow for End Users
If you are distributing this repository to non-technical users, the simplest instructions are:

1. Download or clone the repository.
2. Open a terminal in the project folder.
3. Run the setup script for the operating system.
4. Create the `.env` file with a valid OpenAI API key and model name.
5. Run `python main.py` or provide custom arguments.