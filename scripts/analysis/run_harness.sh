#!/usr/bin/env bash
# run_harness.sh — Orchestrate bot playthroughs with configurable archetypes.
# Uses xargs -P for parallel execution with per-run timeout.
#
# Usage: bash scripts/analysis/run_harness.sh [PARALLELISM] [RUNS_PER_ARCHETYPE]
# Env vars:
#   BOT_ARCHETYPES="STEALTH_PURE STEALTH_ASSASSIN"  # Override archetype list
#   GODOT_PATH=/path/to/godot                        # Godot binary
#   BOT_RESULTS_DIR=/path/to/results                 # Output directory
# Defaults: 4 parallel, 20 runs each, all 10 archetypes

set -euo pipefail

# Configuration
PARALLELISM="${1:-4}"
RUNS_PER="${2:-40}"
TIMEOUT_SECS=300

# Paths
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
GODOT="${GODOT_PATH:-/opt/homebrew/bin/godot}"
RESULTS_DIR="${BOT_RESULTS_DIR:-$PROJECT_DIR/bot_results}"
LOG_DIR="$RESULTS_DIR/logs"

# Verify Godot
if [[ ! -x "$GODOT" ]]; then
    echo "ERROR: Godot not found at $GODOT"
    echo "Set GODOT_PATH environment variable to your Godot binary."
    exit 1
fi

# Setup output dirs
mkdir -p "$RESULTS_DIR" "$LOG_DIR"

# Archetypes — configurable via BOT_ARCHETYPES env var
if [[ -n "${BOT_ARCHETYPES:-}" ]]; then
    read -ra ARCHETYPES <<< "$BOT_ARCHETYPES"
else
    ARCHETYPES=(WARRIOR STEALTH LORE_MAGE RANGER TANK SMITH STEALTH_PURE STEALTH_ASSASSIN RANGER_MARKSMAN RANGER_STEALTH_ARCHER POLEARM_MASTER ELF_SMITH WILL_TANK HOBBIT_SNIPER GREENWOOD_RANGER HOBBIT_BURGLAR BANISHMENT_MAGE SHIELD_WALL)
fi

echo "============================================================"
echo "  NECROMANCER BOT HARNESS"
echo "============================================================"
echo "  Archetypes: ${ARCHETYPES[*]}"
echo "  Runs per archetype: $RUNS_PER"
echo "  Total runs: $(( ${#ARCHETYPES[@]} * RUNS_PER ))"
echo "  Parallelism: $PARALLELISM"
echo "  Timeout per run: ${TIMEOUT_SECS}s"
echo "  Results dir: $RESULTS_DIR"
echo "============================================================"
echo ""

# Generate job list: archetype run_index seed
generate_jobs() {
    for archetype in "${ARCHETYPES[@]}"; do
        for (( i=0; i<RUNS_PER; i++ )); do
            # Deterministic seed: hash of archetype name + run index
            local seed_input="${archetype}_${i}"
            local seed_hash
            seed_hash=$(echo -n "$seed_input" | shasum | cut -c1-8)
            local seed_dec=$((16#$seed_hash))
            echo "$archetype $i $seed_dec"
        done
    done
}

# Run a single bot
run_single() {
    local archetype="$1"
    local run_idx="$2"
    local run_seed="$3"
    local result_file="$RESULTS_DIR/${archetype}_${run_idx}.json"
    local log_file="$LOG_DIR/${archetype}_${run_idx}.log"

    echo "[START] ${archetype} #${run_idx} (seed: ${run_seed})"

    # Run Godot with timeout, capture stdout
    local exit_code=0
    timeout "$TIMEOUT_SECS" "$GODOT" \
        --path "$PROJECT_DIR" \
        --headless \
        --script res://test_runner.gd \
        -- --survival "--archetype=${archetype}" "--run-index=${run_idx}" "--seed=${run_seed}" \
        > "$log_file" 2>&1 || exit_code=$?

    # Extract JSON result from stdout
    if grep -q "^JSON_RESULT:" "$log_file"; then
        grep "^JSON_RESULT:" "$log_file" | tail -1 | sed 's/^JSON_RESULT://' > "$result_file"
        echo "[DONE]  ${archetype} #${run_idx} -> $(cat "$result_file" | python3 -c "import sys,json; d=json.load(sys.stdin); print('Floor %s, %s' % (d.get('deepest_floor','?'), d.get('outcome','?')))" 2>/dev/null || echo "result saved")"
    else
        # No JSON result — create error entry
        echo "{\"archetype\":\"${archetype}\",\"run_index\":${run_idx},\"seed\":${run_seed},\"outcome\":\"HARNESS_ERROR\",\"deepest_floor\":0,\"total_turns\":0,\"total_kills\":0,\"total_items\":0,\"total_damage_taken\":0,\"total_healing_done\":0,\"total_errors\":1,\"per_floor_stats\":[],\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%S)\",\"error\":\"exit_code=${exit_code}\"}" > "$result_file"
        echo "[FAIL]  ${archetype} #${run_idx} (exit: ${exit_code}, no JSON output)"
    fi
}

export -f run_single
export GODOT PROJECT_DIR RESULTS_DIR LOG_DIR TIMEOUT_SECS

# Run all jobs with parallelism
START_TIME=$(date +%s)

generate_jobs | xargs -P "$PARALLELISM" -n 3 bash -c 'run_single "$@"' _ || true

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))

# Summary
TOTAL_RESULTS=$(ls "$RESULTS_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
TOTAL_ERRORS=$(grep -l '"outcome":"HARNESS_ERROR"' "$RESULTS_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "============================================================"
echo "  HARNESS COMPLETE"
echo "============================================================"
echo "  Total runs: $TOTAL_RESULTS"
echo "  Errors: $TOTAL_ERRORS"
echo "  Elapsed: ${ELAPSED}s ($(( ELAPSED / 60 ))m $(( ELAPSED % 60 ))s)"
echo "  Results: $RESULTS_DIR/"
echo "============================================================"
echo ""
echo "Run analysis: python3 scripts/analysis/analyze_results.py"
