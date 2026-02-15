# Visual Bot Contract

## Objective
Provide a Godot-native, evidence-first gameplay regression harness that minimizes manual playtesting by combining deterministic scenario execution, telemetry assertions, and visual/text diffing.

## Scope
- Deterministic mode: blocking for `blocker` and `major` failures.
- Exploratory mode: advisory-only, never blocking.
- Core guaranteed classes:
  - Light radius runtime-vs-UI mismatch
  - Item naming/category/identify display regressions
  - Protection model/reporting regressions (including invalid pools `0d0`/`1d0`)
  - Transition boss identity/title/uniqueness regressions
  - XP source-accounting regressions
  - Social aggro propagation regressions

## Severity Policy
- `blocker`: must gate deterministic PR checks.
- `major`: must gate deterministic PR checks.
- `minor`: report-only in deterministic mode.
- `info`: diagnostics only.

## Deterministic Mode Contract
- Toggle ON/OFF via command args and runtime API; no code edits needed.
- Fixed seed, fixed simulation pacing, fixed checkpoint ordering.
- No advisory exploration in deterministic gate phase.

## Evidence Contract
Per run output must include:
- `artifacts/<run_id>/report.md`
- `artifacts/<run_id>/report.json`
- `artifacts/<run_id>/<scenario>/<checkpoint>/full.png`
- `artifacts/<run_id>/<scenario>/<checkpoint>/telemetry.json`
- `artifacts/<run_id>/<scenario>/<checkpoint>/diff.png` when failed

## Assertion Contract
Required assertion types:
- `eq`
- `range`
- `contains`
- `regex`
- `exists`

## CI Contract
- PR gate: deterministic suite only; fail on `blocker`/`major`.
- Nightly: deterministic + exploratory advisory.
- Exploratory findings are attached to reports, non-blocking.
