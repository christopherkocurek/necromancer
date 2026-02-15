# Intent Rule Pack v1 (Advisory)

## Purpose
Advisory exploratory runs need an explicit oracle for "something is wrong". This pack defines that oracle as machine-checkable intent rules tied to canonical design docs.

## Source Documents
- `docs/GAME_DESIGN_DOCUMENT_BETA_V1_1.md`
- `docs/manual/THE_NECROMANCER_PLAYERS_GUIDE_BETA_V1_1.md`
- `docs/GAME_OVERVIEW_2_PAGER_BETA_V1_1.md`

## Runtime File
- `tests/intent_rules/v1/advisory_core_v1.json`

## Rule Model
Each rule contains:
- `id`: stable identifier
- `severity`: `blocker|major|minor`
- `description`: human-readable intent statement
- `when` (optional): assertion list that gates evaluation
- `assert`: required assertion (`eq|range|contains|regex|exists`)

## Evaluation Semantics
1. Rule ignored when `enabled=false`.
2. If `when` is present, all clauses must pass.
3. Failing `assert` creates advisory finding `intent.<id>`.
4. Findings are included in per-checkpoint evidence and report summaries.

## Why This Works
- Deterministic scenarios remain exact checks for known regressions.
- Advisory exploration adds broad drift detection from design intent.
- Newly discovered manual bugs should be codified as new intent rules or deterministic scenarios.

## Extension Workflow
1. Add new rule to `tests/intent_rules/v1/advisory_core_v1.json`.
2. Reference the source design/manual section in the rule description.
3. Run exploratory advisory and verify finding quality.
4. Promote recurring high-confidence rules to deterministic scenarios when possible.
