# Visual Bot Runbook

## Local Commands
- Smoke: `godot --headless --path . -s scripts/testing/run_visual_suite.gd -- --mode smoke`
- Full: `godot --headless --path . -s scripts/testing/run_visual_suite.gd -- --mode full`
- Advisory exploratory: `godot --headless --path . -s scripts/testing/run_exploratory_suite.gd -- --mode advisory`
- Advisory exploratory (explicit intent pack): `godot --headless --path . -s scripts/testing/run_exploratory_suite.gd -- --mode advisory --intent-pack tests/intent_rules/v1/advisory_core_v1.json`

## Operational Modes
- `smoke`: deterministic subset, fast signal.
- `full`: full deterministic suite, gate candidate.
- `advisory`: exploratory-only, never gating.

## Advisory Oracle
- Advisory checks use hard invariants plus an intent rule pack.
- Default pack: `tests/intent_rules/v1/advisory_core_v1.json`
- Contract/spec: `docs/testing/intent_rule_pack_v1.md`

## Exit Behavior
- Deterministic runner exits non-zero on `blocker`/`major` assertion failures.
- Exploratory runner exits zero unless infra failure occurs.

## Artifact Review Sequence
1. Open `artifacts/<run_id>/report.md`.
2. Inspect `report.json` for machine-readable status.
3. Drill into failed checkpoint folder for `telemetry.json` and `diff.png`.
