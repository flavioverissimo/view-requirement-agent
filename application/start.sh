#!/usr/bin/env sh
set -eu

backend_root="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
api_dir="$backend_root/api"
frontend_dir="$backend_root/frontend"
setup_script="$backend_root/setup.sh"
venv_python="$api_dir/.venv/bin/python"

log_info() {
  printf '[INFO] %s\n' "$1"
}

log_ok() {
  printf '[OK] %s\n' "$1"
}

if [ ! -f "$setup_script" ]; then
  printf "O script de setup nao foi encontrado em '%s'.\n" "$setup_script" >&2
  exit 1
fi

log_info "Preparando o ambiente antes de iniciar a aplicacao."
sh "$setup_script"

if [ ! -x "$venv_python" ]; then
  printf "O Python do ambiente virtual nao foi encontrado em '%s'.\n" "$venv_python" >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  printf "O npm nao foi encontrado apos a etapa de setup.\n" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
  printf "O Python base nao foi encontrado apos a etapa de setup.\n" >&2
  exit 1
fi

if command -v python3 >/dev/null 2>&1; then
  python_bin="python3"
else
  python_bin="python"
fi

shell_quote() {
  "$python_bin" -c 'import shlex, sys; print(shlex.quote(sys.argv[1]))' "$1"
}

escape_for_applescript() {
  "$python_bin" -c 'import sys; print(sys.argv[1].replace("\\", "\\\\").replace("\"", "\\\""))' "$1"
}

api_dir_quoted="$(shell_quote "$api_dir")"
frontend_dir_quoted="$(shell_quote "$frontend_dir")"

backend_command="cd $api_dir_quoted && . .venv/bin/activate && uvicorn main:app --reload"
frontend_command="cd $frontend_dir_quoted && npm run dev"

open_macos_terminals() {
  backend_command_escaped="$(escape_for_applescript "$backend_command")"
  frontend_command_escaped="$(escape_for_applescript "$frontend_command")"

  osascript <<EOF
tell application "Terminal"
  activate
  do script "$backend_command_escaped"
  do script "$frontend_command_escaped"
end tell
EOF
}

open_linux_terminal() {
  title="$1"
  command_text="$2"

  if command -v x-terminal-emulator >/dev/null 2>&1; then
    x-terminal-emulator -T "$title" -e sh -lc "$command_text"
    return 0
  fi

  if command -v gnome-terminal >/dev/null 2>&1; then
    gnome-terminal --title="$title" -- sh -lc "$command_text"
    return 0
  fi

  if command -v konsole >/dev/null 2>&1; then
    konsole --new-tab -p tabtitle="$title" -e sh -lc "$command_text"
    return 0
  fi

  if command -v xterm >/dev/null 2>&1; then
    xterm -T "$title" -e sh -lc "$command_text"
    return 0
  fi

  return 1
}

fallback_background_start() {
  log_info "Nenhum terminal grafico suportado foi encontrado. Iniciando no shell atual."

  (
    cd "$api_dir"
    . .venv/bin/activate
    exec uvicorn main:app --reload
  ) &
  backend_pid=$!

  (
    cd "$frontend_dir"
    exec npm run dev
  ) &
  frontend_pid=$!

  printf '\nBack-end PID: %s\n' "$backend_pid"
  printf 'Front-end PID: %s\n' "$frontend_pid"
  printf 'Pressione Ctrl+C para encerrar este script. Os processos continuarao ativos ate serem finalizados manualmente.\n'
  wait
}

system_name="$(uname -s)"

case "$system_name" in
  Darwin)
    if command -v osascript >/dev/null 2>&1; then
      log_info "Abrindo terminais no macOS."
      open_macos_terminals
      printf '\n'
      log_ok "Os terminais do back-end e do front-end foram iniciados."
      exit 0
    fi
    ;;
  Linux)
    log_info "Abrindo o terminal do back-end."
    if open_linux_terminal "Requirement Backend" "$backend_command"; then
      sleep 1
      log_info "Abrindo o terminal do front-end."
      if open_linux_terminal "Requirement Frontend" "$frontend_command"; then
        printf '\n'
        log_ok "Os terminais do back-end e do front-end foram iniciados."
        exit 0
      fi
    fi
    ;;
esac

fallback_background_start
