#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="$(basename "$SCRIPT_DIR")"
VENV_DIR="$SCRIPT_DIR/.venv"
REQUIREMENTS_FILE="$SCRIPT_DIR/requirements.txt"
REQUIREMENTS_HASH_FILE="$VENV_DIR/.requirements.sha256"
MINIMUM_PYTHON_VERSION="3.10"

print_step() {
  printf '\n[%s] %s\n' "$1" "$2"
}

print_python_install_instructions() {
  cat <<'EOF'
Python was not found on this computer, or the installed version is older than Python 3.10.

Choose one of the installation options below:

1. Official Python (includes IDLE)
   Download page: https://www.python.org/downloads/
   Installation steps:
   - Open the download page and choose the latest Python 3 release for your operating system.
   - Run the installer.
   - On Windows, enable the "Add python.exe to PATH" option before clicking "Install Now".
   - Finish the installation and close the installer.

2. Anaconda Distribution
   Download page: https://www.anaconda.com/download/success?reg=skipped
   Installation steps:
   - Open the download page and choose the installer for your operating system.
   - Run the installer and keep the default options unless your environment requires otherwise.
   - Finish the installation.
   - Open a new terminal window after the installation completes.

After installing Python, run this script again:
  bash setup.sh
EOF
}

detect_python_command() {
  local candidate=""

  if command -v python3 >/dev/null 2>&1; then
    candidate="python3"
  elif command -v python >/dev/null 2>&1; then
    candidate="python"
  else
    return 1
  fi

  if ! "$candidate" - <<'PY' >/dev/null 2>&1
import sys
sys.exit(0 if sys.version_info >= (3, 10) else 1)
PY
  then
    return 1
  fi

  printf '%s\n' "$candidate"
}

resolve_venv_python() {
  if [ -x "$VENV_DIR/bin/python" ]; then
    printf '%s\n' "$VENV_DIR/bin/python"
    return 0
  fi

  if [ -x "$VENV_DIR/Scripts/python.exe" ]; then
    printf '%s\n' "$VENV_DIR/Scripts/python.exe"
    return 0
  fi

  if [ -x "$VENV_DIR/Scripts/python" ]; then
    printf '%s\n' "$VENV_DIR/Scripts/python"
    return 0
  fi

  return 1
}

calculate_requirements_hash() {
  "$VENV_PYTHON" - "$REQUIREMENTS_FILE" <<'PY'
from hashlib import sha256
from pathlib import Path
import sys

requirements_path = Path(sys.argv[1])
print(sha256(requirements_path.read_bytes()).hexdigest())
PY
}

requirements_hash_matches() {
  local current_hash

  if [ ! -f "$REQUIREMENTS_HASH_FILE" ]; then
    return 1
  fi

  current_hash="$(calculate_requirements_hash)"
  [ "$(cat "$REQUIREMENTS_HASH_FILE")" = "$current_hash" ]
}

check_requirements_installed() {
  "$VENV_PYTHON" - "$REQUIREMENTS_FILE" <<'PY'
from importlib import metadata
from pathlib import Path
import sys

try:
    from pip._vendor.packaging.requirements import Requirement
except Exception as error:
    raise SystemExit(f"Unable to inspect installed dependencies with pip: {error}")

requirements_path = Path(sys.argv[1])
missing_dependencies = []

for raw_line in requirements_path.read_text(encoding="utf-8").splitlines():
    line = raw_line.strip()
    if not line or line.startswith("#"):
        continue

    requirement = Requirement(line)

    try:
        installed_version = metadata.version(requirement.name)
    except metadata.PackageNotFoundError:
        missing_dependencies.append(f"{requirement.name} is not installed.")
        continue

    if requirement.specifier and installed_version not in requirement.specifier:
        missing_dependencies.append(
            f"{requirement.name} {installed_version} does not satisfy {requirement.specifier}."
        )

if missing_dependencies:
    print("\n".join(missing_dependencies), file=sys.stderr)
    raise SystemExit(1)
PY
}

write_requirements_hash() {
  calculate_requirements_hash > "$REQUIREMENTS_HASH_FILE"
}

print_next_steps() {
  cat <<EOF

Environment setup finished for $PROJECT_NAME.

To run the application:
  $VENV_PYTHON main.py

To activate the virtual environment manually:
EOF

  if [ -f "$VENV_DIR/bin/activate" ]; then
    printf '  source "%s/bin/activate"\n' "$VENV_DIR"
  else
    printf '  source "%s/Scripts/activate"\n' "$VENV_DIR"
  fi

  if [ ! -f "$SCRIPT_DIR/.env" ]; then
    cat <<'EOF'

Warning: .env was not found in the project root.
Create a .env file before running the workflow if your environment requires API credentials.
EOF
  fi
}

cd "$SCRIPT_DIR"

if [ ! -f "$REQUIREMENTS_FILE" ]; then
  echo "requirements.txt was not found in the project root." >&2
  exit 1
fi

print_step "1/4" "Checking Python installation"
if ! PYTHON_BIN="$(detect_python_command)"; then
  print_python_install_instructions
  exit 1
fi

print_step "2/4" "Preparing the virtual environment"
if [ -d "$VENV_DIR" ]; then
  echo "Using the existing virtual environment at $VENV_DIR"
else
  echo "Creating a new virtual environment at $VENV_DIR"
  "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

if ! VENV_PYTHON="$(resolve_venv_python)"; then
  echo "The virtual environment was created, but its Python executable could not be found." >&2
  exit 1
fi

print_step "3/4" "Checking project dependencies"
if check_requirements_installed && "$VENV_PYTHON" -m pip check >/dev/null 2>&1; then
  if requirements_hash_matches; then
    echo "All dependencies are already installed and match requirements.txt"
  else
    echo "All dependencies are already installed. Updating the local requirements cache."
    write_requirements_hash
  fi
else
  echo "Installing or updating dependencies from requirements.txt"
  "$VENV_PYTHON" -m pip install -r "$REQUIREMENTS_FILE"
  check_requirements_installed
  "$VENV_PYTHON" -m pip check >/dev/null
  write_requirements_hash
fi

print_step "4/4" "Done"
write_requirements_hash
print_next_steps
