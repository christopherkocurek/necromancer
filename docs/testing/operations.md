# Operations

## Flake Handling
- Re-run deterministic scenario twice with same seed.
- If mismatch persists, mark as deterministic failure and investigate.
- If mismatch disappears, mark as suspected flake and open calibration task.

## Waiver Policy
- Waivers allowed only for `minor` in deterministic mode.
- `blocker` and `major` require fix or explicit temporary gate override in CI config.
- Exploratory advisories are never waived because they are non-blocking by design.

## Schema Evolution
- Introduce new schema version files alongside existing versions.
- Keep readers backward-compatible for one version window.
- Add migration note to `runbook.md` when changing required keys.

## Intent Rule Pack Evolution
- Keep advisory packs versioned under `tests/intent_rules/v*/`.
- Every new rule must cite a canonical source doc section in its `description` or pack notes.
- If a rule fires frequently and is high-confidence, convert it into deterministic scenario coverage.
- Disable (`enabled=false`) only when rule semantics are incorrect; do not suppress findings by widening thresholds first.

## Calibration SOP
- Tune visual diff threshold using known-good repeated runs.
- Prefer ROI + masks for unstable pixels.
- Keep deterministic mode fixed timestep and seed for reproducibility.
