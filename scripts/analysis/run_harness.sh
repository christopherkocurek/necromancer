#!/usr/bin/env bash
# run_harness.sh — Orchestrate bot playthroughs with configurable archetypes.
# Uses xargs -P for parallel execution with per-run timeout.
#
# Usage: bash scripts/analysis/run_harness.sh [PARALLELISM] [RUNS_PER_ARCHETYPE]
# Env vars:
#   BOT_ARCHETYPES="STEALTH_PURE STEALTH_ASSASSIN"  # Override archetype list
#   GODOT_PATH=/path/to/godot                        # Godot binary
#   BOT_RESULTS_DIR=/path/to/results                 # Output directory
#   BOT_START_DEPTH=5                                # Optional: start all runs at this depth
#   BOT_BONUS_XP=500                                 # Optional: grant bonus XP after warm-start
#   BOT_RUN_INDEX_OFFSET=52                          # Optional: add offset to run indices
# Defaults: 4 parallel, 20 runs each, all 10 archetypes

set -euo pipefail

# Configuration
PARALLELISM="${1:-4}"
RUNS_PER="${2:-40}"
TIMEOUT_SECS="${BOT_TIMEOUT:-300}"
STEALTH_TIMEOUT_SECS="${BOT_TIMEOUT_STEALTH:-$TIMEOUT_SECS}"
START_DEPTH="${BOT_START_DEPTH:-}"
BONUS_XP="${BOT_BONUS_XP:-}"
BOT_TICK_DELAY="${BOT_TICK_DELAY:-}"
RUN_INDEX_OFFSET="${BOT_RUN_INDEX_OFFSET:-0}"

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
if [[ "${STEALTH_TIMEOUT_SECS}" != "${TIMEOUT_SECS}" ]]; then
    echo "  Stealth timeout: ${STEALTH_TIMEOUT_SECS}s"
fi
if [[ -n "${BOT_TICK_DELAY}" ]]; then
    echo "  Bot tick delay override: ${BOT_TICK_DELAY}s"
fi
if [[ -n "$START_DEPTH" ]]; then
    echo "  Start depth override: $START_DEPTH"
fi
if [[ -n "$BONUS_XP" ]]; then
    echo "  Bonus XP override: $BONUS_XP"
fi
if [[ "${RUN_INDEX_OFFSET}" != "0" ]]; then
    echo "  Run index offset: $RUN_INDEX_OFFSET"
fi
echo "  Results dir: $RESULTS_DIR"
echo "============================================================"
echo ""

# Generate job list: archetype run_index seed
generate_jobs() {
    for archetype in "${ARCHETYPES[@]}"; do
        for (( i=0; i<RUNS_PER; i++ )); do
            local run_idx=$((i + RUN_INDEX_OFFSET))
            # Deterministic seed: hash of archetype name + run index
            local seed_input="${archetype}_${run_idx}"
            local seed_hash
            seed_hash=$(echo -n "$seed_input" | shasum | cut -c1-8)
            local seed_dec=$((16#$seed_hash))
            echo "$archetype $run_idx $seed_dec"
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
    local run_timeout="$TIMEOUT_SECS"
    case "$archetype" in
        STEALTH|STEALTH_PURE|STEALTH_ASSASSIN|RANGER_STEALTH_ARCHER|HOBBIT_BURGLAR|GREENWOOD_RANGER)
            run_timeout="$STEALTH_TIMEOUT_SECS"
            ;;
    esac
    if [[ -z "$run_timeout" ]]; then
        run_timeout="$TIMEOUT_SECS"
    fi
    local bot_args=(--survival "--archetype=${archetype}" "--run-index=${run_idx}" "--seed=${run_seed}")
    if [[ -n "${START_DEPTH}" ]]; then
        bot_args+=("--start-depth=${START_DEPTH}")
    fi
    if [[ -n "${BONUS_XP}" ]]; then
        bot_args+=("--bonus-xp=${BONUS_XP}")
    fi
    if [[ -n "${BOT_TICK_DELAY}" ]]; then
        bot_args+=("--tick-delay=${BOT_TICK_DELAY}")
    fi

    echo "[START] ${archetype} #${run_idx} (seed: ${run_seed}, timeout: ${run_timeout}s)"

    # Run Godot with timeout, capture stdout
    local exit_code=0
    timeout "$run_timeout" "$GODOT" \
        --path "$PROJECT_DIR" \
        --headless \
        --log-file "$LOG_DIR/godot_${archetype}_${run_idx}.log" \
        --script res://test_runner.gd \
        -- "${bot_args[@]}" \
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
export GODOT PROJECT_DIR RESULTS_DIR LOG_DIR TIMEOUT_SECS STEALTH_TIMEOUT_SECS START_DEPTH BONUS_XP BOT_TICK_DELAY RUN_INDEX_OFFSET

# Run all jobs with parallelism
START_TIME=$(date +%s)

generate_jobs | xargs -P "$PARALLELISM" -n 3 bash -c 'run_single "$@"' _ || true

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))

# Summary
TOTAL_RESULTS=$(ls "$RESULTS_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
TOTAL_ERRORS=$(grep -l '"outcome":"HARNESS_ERROR"' "$RESULTS_DIR"/*.json 2>/dev/null || true)
TOTAL_ERRORS=$(printf "%s" "$TOTAL_ERRORS" | wc -l | tr -d ' ')

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
