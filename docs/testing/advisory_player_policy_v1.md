# Advisory Player Policy v1

## Purpose
This document is the handoff for continuing the visual + telemetry bot harness in a new session. It records current capability, command surface, and the implementation plan for an advisory policy that can actually play the game (including abilities).

## Current State (Implemented)
### Deterministic visual suite (strict checks)
- Script: `scripts/testing/run_visual_suite.gd`
- Scenarios:
  - `tests/scenarios/v1/light_matrix_v1.json`
  - `tests/scenarios/v1/identify_naming_v1.json`
  - `tests/scenarios/v1/protection_model_v1.json`
  - `tests/scenarios/v1/transition_boss_v1.json`
  - `tests/scenarios/v1/xp_sources_v1.json`
  - `tests/scenarios/v1/social_aggro_v1.json`
- Purpose: PR-gateable deterministic pass/fail for the 6 guaranteed regression classes.

### Exploratory advisory suite (non-blocking)
- Script: `scripts/testing/run_exploratory_suite.gd`
- Policy: `scripts/testing/exploration_policy.gd`
- Invariants: `scripts/testing/invariant_registry.gd`
- Intent pack: `tests/intent_rules/v1/advisory_core_v1.json`
- Rule pack spec: `docs/testing/intent_rule_pack_v1.md`
- Purpose: broad advisory drift detection with evidence artifacts.

### Evidence artifacts
- `artifacts/<run_id>/report.md`
- `artifacts/<run_id>/report.json`
- `artifacts/<run_id>/<scenario>/<checkpoint>/full.png`
- `artifacts/<run_id>/<scenario>/<checkpoint>/telemetry.json`
- `artifacts/<run_id>/repros/*.json` and `artifacts/<run_id>/repros/*.md`

## Important Limitation Right Now
Advisory exploration does not yet play full builds like a human. It currently does:
- movement
- inventory/character panel toggles
- probe actions (`gain_xp`, naming sample/identify, protection pool set, transition boss spawn, social aggro simulate)

This means advisory depth/coverage is useful but still shallow for true long-run gameplay validation.

## Run Commands
From repo root:
- Smoke deterministic:
  - `godot --headless --path . -s scripts/testing/run_visual_suite.gd -- --mode smoke`
- Full deterministic:
  - `godot --headless --path . -s scripts/testing/run_visual_suite.gd -- --mode full`
- Advisory exploratory default:
  - `godot --headless --path . -s scripts/testing/run_exploratory_suite.gd -- --mode advisory`
- Advisory exploratory with explicit intent pack:
  - `godot --headless --path . -s scripts/testing/run_exploratory_suite.gd -- --mode advisory --intent-pack tests/intent_rules/v1/advisory_core_v1.json`

## Advisory Player Policy v1 Implementation Plan
Goal: make advisory bot capable of practical autonomous play with ability usage and tactical decisions while remaining non-blocking.

### Phase 1: Expand action surface (4-6 hours)
Implement in `scripts/testing/game_adapter.gd`:
- `use_hotbar_slot` action (`slot`, optional `target_mode`, optional `target_pos`).
- `set_target_entity` action (nearest hostile, explicit entity id, or tile).
- `toggle_auto_explore` action.
- `spend_xp` action (buy skill/ability by id).
- `equip_item` / `unequip_item` action where available.

Telemetry additions in adapter:
- `ability_state`: cooldown/charges/usable flags for bound slots.
- `threat_state`: nearest hostile distance, hostile_count_visible, surrounded_count.
- `resource_state`: health_pct, voice/mana-like resource pct, light budget markers.

### Phase 2: Decision policy core (6-10 hours)
Create `scripts/testing/advisory_player_policy_v1.gd`:
- Priority loop per step:
  1. Survive: retreat/heal/defensive ability when lethal risk.
  2. Stabilize visibility/light if low information.
  3. Engage favorable targets with valid abilities.
  4. Reposition to geometry advantage.
  5. Explore when safe.
- Behavior states:
  - `SAFE_EXPLORE`, `TACTICAL_ENGAGE`, `RETREAT_RESET`, `RESOURCE_RECOVERY`.
- Add anti-loop rules:
  - break repeated move oscillation,
  - force state transition after N repeated actions,
  - fallback escape action when stuck.

### Phase 3: Wire policy into exploratory runner (2-3 hours)
In `scripts/testing/run_exploratory_suite.gd`:
- Add `--policy` arg (`probe` default, `player_v1` optional).
- Route policy selection:
  - `probe` -> existing `exploration_policy.gd`
  - `player_v1` -> `advisory_player_policy_v1.gd`
- Add policy telemetry in summary:
  - chosen policy
  - ability_usage_count
  - combat_encounters
  - retreats_triggered

### Phase 4: Coverage + quality metrics (3-5 hours)
Report metrics:
- depth reached
- unique tiles explored
- hostile encounters started/resolved
- abilities used by id and count
- deaths and immediate precursors
- advisory finding density per 100 turns

### Phase 5: Guardrails + calibration (3-4 hours)
- Keep exploratory advisory exit non-blocking (`exit 0` for gameplay findings).
- Add replay seed + action trace persistence for every run.
- Tune noisy rules in `tests/intent_rules/v1/advisory_core_v1.json` with evidence-based thresholds.

## Definition of Done for Advisory Player Policy v1
- Bot can use hotbar abilities during encounters.
- Bot can retreat and recover instead of only random movement.
- Advisory run reaches deeper/broader states than probe policy.
- Findings are reproducible from run seed + repro traces.
- Deterministic suite remains unchanged and green.

## New Session Kickoff Prompt
Use this in a new coding session:

"Continue from `docs/testing/advisory_player_policy_v1.md`. Implement Phase 1-3 fully, run advisory with `--policy player_v1`, and show report with ability usage metrics plus one pass and one injected-fail advisory run. Keep exploratory advisory non-blocking."
