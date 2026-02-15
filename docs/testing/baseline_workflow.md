# Baseline Workflow

## Baseline Source
- Stored under `tests/baselines/v1/` by scenario id and checkpoint id.

## Update Flow
1. Run deterministic suite and confirm expected behavior manually once.
2. Use baseline manager update mode to write new baseline images + telemetry snapshots.
3. Commit baseline changes in a dedicated change set.
4. Re-run deterministic full mode; require no unexpected diffs.

## Rules
- Never update baselines in exploratory advisory runs.
- Baseline updates must be explicit (`--update-baseline` flag).
- Keep old baseline snapshots when schema changes until migration is validated.
