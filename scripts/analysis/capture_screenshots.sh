#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <output-dir> <label> [attempts] [seed]"
  echo "Example: $0 .playtest_logs/shots baseline 3 424242"
  exit 1
fi

OUT_DIR="$1"
LABEL="$2"
ATTEMPTS="${3:-3}"
SEED="${4:-${SCREENSHOT_SEED:--1}}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
GODOT="${GODOT_PATH:-/opt/homebrew/bin/godot}"
SCREENSHOT_HEADLESS="${SCREENSHOT_HEADLESS:-0}"

if [[ ! -x "$GODOT" ]]; then
  echo "ERROR: Godot not found at $GODOT"
  echo "Set GODOT_PATH environment variable."
  exit 1
fi

mkdir -p "$OUT_DIR"
OUT_DIR_ABS="$(cd "$OUT_DIR" && pwd)"

echo "[screenshots] project=$PROJECT_DIR"
echo "[screenshots] out=$OUT_DIR_ABS"
echo "[screenshots] label=$LABEL"
echo "[screenshots] attempts=$ATTEMPTS"
echo "[screenshots] headless=$SCREENSHOT_HEADLESS"
echo "[screenshots] seed=$SEED"

ok=0
for ((a=1; a<=ATTEMPTS; a++)); do
  echo "[screenshots] attempt $a/$ATTEMPTS"
  if [[ "$SCREENSHOT_HEADLESS" == "1" ]]; then
    "$GODOT" --path "$PROJECT_DIR" --headless --script res://test_runner.gd -- \
      --screenshot-capture "--screenshots-dir=$OUT_DIR_ABS" "--screenshot-label=$LABEL" "--screenshot-seed=$SEED" || true
  else
    "$GODOT" --path "$PROJECT_DIR" --rendering-driver opengl3 --script res://test_runner.gd -- \
      --screenshot-capture "--screenshots-dir=$OUT_DIR_ABS" "--screenshot-label=$LABEL" "--screenshot-seed=$SEED" || true
  fi

  shot_count="$(find "$OUT_DIR_ABS" -maxdepth 1 -type f -name "${LABEL}_*.png" | wc -l | tr -d ' ')"
  valid_count="$(find "$OUT_DIR_ABS" -maxdepth 1 -type f -name "${LABEL}_*.png" -size +1k | wc -l | tr -d ' ')"
  manifest="$OUT_DIR_ABS/${LABEL}_manifest.json"

  echo "[screenshots] captured=$shot_count valid(>1KB)=$valid_count manifest=$manifest"
  if [[ "$valid_count" -ge 3 && -f "$manifest" ]]; then
    ok=1
    break
  fi

  sleep 1
done

if [[ "$ok" -ne 1 ]]; then
  echo "ERROR: screenshot capture failed after $ATTEMPTS attempts"
  exit 1
fi

echo "[screenshots] success"
