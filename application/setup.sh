#!/usr/bin/env sh
set -eu

backend_root="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
api_dir="$backend_root/api"
frontend_dir="$backend_root/frontend"
venv_dir="$api_dir/.venv"
venv_python="$venv_dir/bin/python"
requirements_file="$api_dir/requirements.txt"
requirements_marker="$venv_dir/.requirements.sha256"
frontend_lock_file="$frontend_dir/package-lock.json"
frontend_package_file="$frontend_dir/package.json"
frontend_node_modules_dir="$frontend_dir/node_modules"
frontend_marker="$frontend_node_modules_dir/.package-lock.sha256"

log_info() {
  printf '[INFO] %s\n' "$1"
}

log_skip() {
  printf '[SKIP] %s\n' "$1"
}

log_ok() {
  printf '[OK] %s\n' "$1"
}

if command -v python3 >/dev/null 2>&1; then
  python_bin="python3"
elif command -v python >/dev/null 2>&1; then
  python_bin="python"
else
  python_bin=""
fi

if command -v node >/dev/null 2>&1; then
  node_bin="node"
else
  node_bin=""
fi

if command -v npm >/dev/null 2>&1; then
  npm_bin="npm"
else
  npm_bin=""
fi

missing_dependencies=""

if [ -z "$python_bin" ]; then
  missing_dependencies="${missing_dependencies} - Python: https://www.python.org/downloads/\n"
fi

if [ -z "$node_bin" ]; then
  missing_dependencies="${missing_dependencies} - Node.js: https://nodejs.org/en/download\n"
fi

if [ -z "$npm_bin" ]; then
  missing_dependencies="${missing_dependencies} - npm: https://nodejs.org/en/download\n"
fi

if [ -n "$missing_dependencies" ]; then
  printf '\nNao foi possivel continuar porque as dependencias abaixo nao estao instaladas:\n'
  printf '%b' "$missing_dependencies"
  exit 1
fi

if [ ! -d "$api_dir" ]; then
  printf "O diretorio 'api' nao foi encontrado em '%s'.\n" "$api_dir" >&2
  exit 1
fi

if [ ! -d "$frontend_dir" ]; then
  printf "O diretorio 'frontend' nao foi encontrado em '%s'.\n" "$frontend_dir" >&2
  exit 1
fi

get_file_digest() {
  "$python_bin" - "$1" <<'PY'
import hashlib
import pathlib
import sys

print(hashlib.sha256(pathlib.Path(sys.argv[1]).read_bytes()).hexdigest())
PY
}

read_stored_digest() {
  if [ -f "$1" ]; then
    tr -d '\r\n' <"$1"
  fi
}

write_stored_digest() {
  printf '%s' "$2" >"$1"
}

list_requirement_packages() {
  "$python_bin" - "$1" <<'PY'
import pathlib
import re
import sys

seen = set()

for raw_line in pathlib.Path(sys.argv[1]).read_text(encoding="utf-8").splitlines():
    line = raw_line.strip()
    if not line or line.startswith("#") or line.startswith("-"):
        continue
    match = re.match(r"([A-Za-z0-9_.-]+)", line)
    if not match:
        continue
    package = match.group(1)
    if package not in seen:
        seen.add(package)
        print(package)
PY
}

test_api_requirements_installed() {
  [ -x "$venv_python" ] || return 1

  while IFS= read -r package; do
    [ -n "$package" ] || continue

    if ! "$venv_python" -m pip show "$package" >/dev/null 2>&1; then
      return 1
    fi
  done <<EOF
$(list_requirement_packages "$requirements_file")
EOF

  return 0
}

test_frontend_dependencies_installed() {
  [ -d "$frontend_node_modules_dir" ] || return 1
  (
    cd "$frontend_dir"
    "$npm_bin" list --depth=0 --silent >/dev/null 2>&1
  )
}

log_info "Python detectado em '$(command -v "$python_bin")'."
log_info "Node detectado em '$(command -v "$node_bin")'."
log_info "npm detectado em '$(command -v "$npm_bin")'."

if [ ! -x "$venv_python" ]; then
  log_info "Criando o ambiente virtual em '$venv_dir'."
  (
    cd "$api_dir"
    "$python_bin" -m venv .venv
  )

  if [ ! -x "$venv_python" ]; then
    printf "Falha ao criar o ambiente virtual em '%s'.\n" "$venv_dir" >&2
    exit 1
  fi

  log_ok "Ambiente virtual criado."
else
  log_skip "Ambiente virtual ja existe em '$venv_dir'."
fi

requirements_digest="$(get_file_digest "$requirements_file")"
stored_requirements_digest="$(read_stored_digest "$requirements_marker")"

if [ "$stored_requirements_digest" = "$requirements_digest" ]; then
  api_dependencies_ready="yes"
elif test_api_requirements_installed; then
  write_stored_digest "$requirements_marker" "$requirements_digest"
  api_dependencies_ready="yes"
else
  api_dependencies_ready="no"
fi

if [ "$api_dependencies_ready" = "yes" ]; then
  log_skip "Dependencias do backend ja estao instaladas."
else
  log_info "Instalando dependencias do backend."
  (
    cd "$api_dir"
    "$venv_python" -m pip install -r requirements.txt
  )
  write_stored_digest "$requirements_marker" "$requirements_digest"
  log_ok "Dependencias do backend instaladas."
fi

if [ -f "$frontend_lock_file" ]; then
  frontend_manifest_file="$frontend_lock_file"
else
  frontend_manifest_file="$frontend_package_file"
fi

frontend_digest="$(get_file_digest "$frontend_manifest_file")"
stored_frontend_digest="$(read_stored_digest "$frontend_marker")"

if [ "$stored_frontend_digest" = "$frontend_digest" ]; then
  frontend_dependencies_ready="yes"
elif test_frontend_dependencies_installed; then
  mkdir -p "$frontend_node_modules_dir"
  write_stored_digest "$frontend_marker" "$frontend_digest"
  frontend_dependencies_ready="yes"
else
  frontend_dependencies_ready="no"
fi

if [ "$frontend_dependencies_ready" = "yes" ]; then
  log_skip "Dependencias do front-end ja estao instaladas."
else
  log_info "Instalando dependencias do front-end."
  (
    cd "$frontend_dir"
    "$npm_bin" install
  )
  write_stored_digest "$frontend_marker" "$frontend_digest"
  log_ok "Dependencias do front-end instaladas."
fi

printf '\nAmbiente preparado com sucesso.\n'
printf 'Abra 2 terminais e execute os comandos abaixo nesta ordem:\n\n'
printf '1. Back-end\n'
printf '   cd "%s"\n' "$api_dir"
printf '   source .venv/bin/activate\n'
printf '   uvicorn main:app --reload\n\n'
printf '2. Front-end\n'
printf '   cd "%s"\n' "$frontend_dir"
printf '   npm run dev\n'
printf '\nSimpler option:\n'
printf ' - To prepare and start everything automatically on macOS/Linux, run sh start.sh\n'
