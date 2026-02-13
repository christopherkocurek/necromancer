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
OPEN_APP=0
COMPATIBILITY=1
FORCE_REIMPORT=0
REIMPORT_IF_EMPTY=1
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
  --focus             Bring Godot app to foreground after launch.
  --forward-plus      Use Forward+ renderer instead of compatibility.
  --compatibility     Use compatibility renderer (OpenGL 3) for stability.
  --reimport          Force Godot resource reimport before launch.
  --no-auto-reimport  Disable auto-reimport when .godot/imported is empty.
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
    --focus)
      OPEN_APP=1
      shift
      ;;
    --compatibility)
      COMPATIBILITY=1
      shift
      ;;
    --forward-plus)
      COMPATIBILITY=0
      shift
      ;;
    --reimport)
      FORCE_REIMPORT=1
      shift
      ;;
    --no-auto-reimport)
      REIMPORT_IF_EMPTY=0
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

if [[ "$FORCE_REIMPORT" -eq 1 || ( "$REIMPORT_IF_EMPTY" -eq 1 && ! -d "$PROJECT_DIR/.godot/imported" ) ]]; then
  echo "Running resource import..."
  "$GODOT_BIN" --path "$PROJECT_DIR" --import --quit >/dev/null 2>&1 || true
elif [[ "$REIMPORT_IF_EMPTY" -eq 1 && -d "$PROJECT_DIR/.godot/imported" ]]; then
  if ! find "$PROJECT_DIR/.godot/imported" -type f -maxdepth 1 2>/dev/null | head -1 | grep -q .; then
    echo "Detected empty import cache; running resource import..."
    "$GODOT_BIN" --path "$PROJECT_DIR" --import --quit >/dev/null 2>&1 || true
  fi
fi

CMD=("$GODOT_BIN" "--path" "$PROJECT_DIR")
if [[ "$MODE" == "editor" ]]; then
  CMD+=("-e")
else
  # Force direct game launch instead of project manager.
  CMD+=("--scene" "res://scenes/main.tscn")
fi
if [[ "$COMPATIBILITY" -eq 1 ]]; then
  CMD+=("--rendering-driver" "opengl3")
fi
CMD+=("--log-file" "$LOG_FILE")

if [[ "$DETACH" -eq 1 ]]; then
  if [[ "$(uname -s)" == "Darwin" ]]; then
    CMD_ARGS=("--path" "$PROJECT_DIR")
    if [[ "$MODE" == "editor" ]]; then
      CMD_ARGS+=("-e")
    else
      CMD_ARGS+=("--scene" "res://scenes/main.tscn")
    fi
    if [[ "$COMPATIBILITY" -eq 1 ]]; then
      CMD_ARGS+=("--rendering-driver" "opengl3")
    fi
    CMD_ARGS+=("--log-file" "$LOG_FILE")
    open -n -a Godot --args "${CMD_ARGS[@]}"
    sleep 1
    NEW_PID="$(pgrep -f "/Applications/Godot.app/Contents/MacOS/Godot --path $PROJECT_DIR" | tail -1 || true)"
    if [[ -n "$NEW_PID" ]]; then
      echo "$NEW_PID" > "$PID_FILE"
      echo "Launched $MODE (PID $NEW_PID)"
    else
      echo "Launched $MODE (PID unknown)"
      : > "$PID_FILE"
    fi
  else
    nohup "${CMD[@]}" >>"$LOG_FILE" 2>&1 &
    NEW_PID=$!
    echo "$NEW_PID" > "$PID_FILE"
    echo "Launched $MODE (PID $NEW_PID)"
  fi
  if [[ "$OPEN_APP" -eq 1 && "$MODE" == "standalone" ]]; then
    open -a Godot >/dev/null 2>&1 || true
  fi
  echo "Log: $LOG_FILE"
  if [[ "$COMPATIBILITY" -eq 1 ]]; then
    echo "Renderer: compatibility (OpenGL 3)"
  fi
else
  echo "Running in foreground: ${CMD[*]}"
  echo "Log: $LOG_FILE"
  "${CMD[@]}" 2>&1 | tee "$LOG_FILE"
fi
