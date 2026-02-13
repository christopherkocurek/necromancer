#!/usr/bin/env bash
set -euo pipefail

INPUT_FILE="${1:-$HOME/Library/Application Support/Godot/app_userdata/The Necromancer/telemetry/current_run.ndjson}"

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Telemetry file not found: $INPUT_FILE"
  exit 1
fi

echo "Telemetry Summary"
echo "File: $INPUT_FILE"
echo

TOTAL_LINES=$(wc -l < "$INPUT_FILE" | tr -d ' ')
echo "Total events: $TOTAL_LINES"
echo

echo "Event counts:"
awk -F'"event":"' '
  NF>1 {
    split($2, a, "\"");
    evt=a[1];
    c[evt]++
  }
  END {
    for (k in c) printf("  %-26s %d\n", k, c[k]);
  }
' "$INPUT_FILE" | sort

echo
echo "Recent threat transitions:"
grep '"event":"threat_summary_updated"' "$INPUT_FILE" | tail -n 8 || true

echo
echo "Completed run goals:"
grep '"event":"run_goal_completed"' "$INPUT_FILE" || echo "  none"

echo
echo "Latest game over:"
grep '"event":"game_over"' "$INPUT_FILE" | tail -n 1 || echo "  none"
