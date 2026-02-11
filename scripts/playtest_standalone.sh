#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -n "${GODOT_PATH:-}" ]]; then
  GODOT_BIN="$GODOT_PATH"
elif command -v godot >/dev/null 2>&1; then
  GODOT_BIN="$(command -v godot)"
else
  GODOT_BIN="/opt/homebrew/bin/godot"
fi

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "ERROR: Godot binary not found or not executable: $GODOT_BIN"
  echo "Set GODOT_PATH to your Godot binary path."
  exit 1
fi

MODE="standalone"
DETACH=1
KILL_EXISTING=1
OPEN_APP=1
COMPATIBILITY=0
LOG_DIR="$PROJECT_DIR/.playtest_logs"
mkdir -p "$LOG_DIR"
PID_FILE="$LOG_DIR/standalone.pid"

usage() {
  cat <<USAGE
Usage: scripts/playtest_standalone.sh [options]

Options:
  --editor            Launch editor for this project instead of game.
  --foreground        Keep process attached to current terminal.
  --no-kill           Do not stop previously launched playtest process.
  --no-open           Do not bring Godot app to foreground.
  --compatibility     Use compatibility renderer (OpenGL 3) for stability.
  --help              Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --editor)
      MODE="editor"
      shift
      ;;
    --foreground)
      DETACH=0
      shift
      ;;
    --no-kill)
      KILL_EXISTING=0
      shift
      ;;
    --no-open)
      OPEN_APP=0
      shift
      ;;
    --compatibility)
      COMPATIBILITY=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ "$KILL_EXISTING" -eq 1 && -f "$PID_FILE" ]]; then
  OLD_PID="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "${OLD_PID}" ]] && kill -0 "$OLD_PID" >/dev/null 2>&1; then
    kill "$OLD_PID" >/dev/null 2>&1 || true
    sleep 0.3
  fi
fi

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$LOG_DIR/${MODE}-${TIMESTAMP}.log"

CMD=("$GODOT_BIN" "--path" "$PROJECT_DIR")
if [[ "$MODE" == "editor" ]]; then
  CMD+=("-e")
fi
if [[ "$COMPATIBILITY" -eq 1 ]]; then
  CMD+=("--rendering-driver" "opengl3")
fi

if [[ "$DETACH" -eq 1 ]]; then
  nohup "${CMD[@]}" >"$LOG_FILE" 2>&1 &
  NEW_PID=$!
  echo "$NEW_PID" > "$PID_FILE"
  if [[ "$OPEN_APP" -eq 1 ]]; then
    open -a Godot >/dev/null 2>&1 || true
  fi
  echo "Launched $MODE (PID $NEW_PID)"
  echo "Log: $LOG_FILE"
  if [[ "$COMPATIBILITY" -eq 1 ]]; then
    echo "Renderer: compatibility (OpenGL 3)"
  fi
else
  echo "Running in foreground: ${CMD[*]}"
  echo "Log: $LOG_FILE"
  "${CMD[@]}" 2>&1 | tee "$LOG_FILE"
fi
