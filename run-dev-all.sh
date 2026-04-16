#!/usr/bin/env bash
set -euo pipefail

# Start/stop/restart BOTH:
# - Go backend: config server.port (default 8888)
# - Next.js UI (in ./ui): next dev (default port 3000)
#
# Usage:
#   ./run-dev-all.sh start
#   ./run-dev-all.sh stop
#   ./run-dev-all.sh restart

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UI_DIR="${ROOT_DIR}/ui"

GO_PORT="${GO_PORT:-8888}"
UI_PORT="${UI_PORT:-3000}"

get_listening_pids_by_port() {
  # Output: newline-separated PIDs
  local port="$1"
  powershell.exe -NoProfile -Command "Get-NetTCPConnection -LocalPort ${port} -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique" 2>/dev/null | tr -d '\r'
}

kill_listening_processes_by_port() {
  # Kill all processes currently listening on given port.
  local port="$1"
  local pids
  pids="$(get_listening_pids_by_port "$port" || true)"

  if [[ -z "${pids//[[:space:]]/}" ]]; then
    return 0
  fi

  while IFS= read -r pid; do
    if [[ -n "${pid}" ]]; then
      powershell.exe -NoProfile -Command "Stop-Process -Id ${pid} -Force -ErrorAction SilentlyContinue" 2>/dev/null || true
    fi
  done <<< "$pids"
}

stop_all() {
  echo "[stop] killing listeners on ports: ${GO_PORT}, ${UI_PORT}"
  kill_listening_processes_by_port "${GO_PORT}"
  kill_listening_processes_by_port "${UI_PORT}"
}

start_all() {
  # Ensure we don't fail with EADDRINUSE: always stop first.
  stop_all

  echo "[start] Go backend on ${GO_PORT}"
  (cd "${ROOT_DIR}" && go run ./cmd/server/main.go) &
  GO_PID="$!"

  echo "[start] Next UI on ${UI_PORT}"
  (cd "${UI_DIR}" && npm run dev -- --port "${UI_PORT}") &
  UI_PID="$!"

  echo "[info] started: go(pid=${GO_PID}) ui(pid=${UI_PID})"
  echo "[info] UI: http://localhost:${UI_PORT}"
  echo "[info] Backend: http://localhost:${GO_PORT}"

  # Keep script attached to foreground so user can Ctrl+C.
  # Stop can still be run from another terminal; it kills by port.
  wait "${GO_PID}" "${UI_PID}" || true
}

main() {
  if [[ "${#}" -lt 1 ]]; then
    echo "Missing command. Use: start | stop | restart"
    exit 2
  fi

  case "$1" in
    start)
      start_all
      ;;
    stop)
      stop_all
      ;;
    restart)
      stop_all
      start_all
      ;;
    *)
      echo "Unknown command: $1 (use: start | stop | restart)"
      exit 2
      ;;
  esac
}

main "$@"

