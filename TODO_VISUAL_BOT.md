# Visual + Telemetry Bot Harness TODO

## Foundation
- [ ] T001 Define testing contract and severity policy (`blocker/major/minor`, deterministic vs advisory).
- [ ] T002 Add toggleable deterministic `test_mode` (fixed render/UI/seed behavior).
- [ ] T003 Implement scenario runner lifecycle (`setup -> actions -> settle -> checkpoint -> teardown`).

## Core Regression Detection (Guaranteed Classes)
- [ ] T006 Light telemetry + deterministic assertions (stack breakdown + final radius).
- [ ] T007 Naming/identification telemetry + assertions (raw vs display, category prefixes, identify state transitions).
- [ ] T008 Protection telemetry + assertions (pool aggregation, min/max, invalid pool filtering).
- [ ] T009 Boss identity/title telemetry + assertions (base id, title override, uniqueness keys, spawn source).
- [ ] T010 XP source ledger telemetry + assertions (event source, raw/base/multiplier/final).
- [ ] T011 Social aggro telemetry + assertions (wake/alert propagation chains).

## Visual Evidence + Diffing
- [ ] T012 Capture pipeline (full-frame + ROI PNG + metadata sidecar per checkpoint).
- [ ] T013 Godot-native visual/text diff engine (threshold + masks).
- [ ] T014 Assertion engine (`eq/range/contains/regex/exists`) with structured failures.
- [ ] T015 Report builder (`report.md` + `report.json` + evidence links).
- [ ] T016 Baseline manager with explicit baseline update flow.

## Execution + CI
- [ ] T017 Add local run commands (`smoke`, `full`, `exploratory_advisory`).
- [ ] T018 Wire CI topology (PR deterministic gate, nightly deterministic + advisory exploratory).
- [ ] T019 Expand broader deterministic suite (rendering/UI/combat/AI/spawn/progression/status/save-load/transitions).
- [ ] T020 Add calibration/operations SOP (flake handling, waiver process, schema evolution).

## Acceptance Gates
- [ ] G1 Known regressions for the 6 guaranteed classes are reproducibly detected.
- [ ] G2 Repeated deterministic runs are stable (low false positives).
- [ ] G3 Reports are actionable with direct artifact links.
- [ ] G4 PR gate blocks deterministic `blocker/major`; exploratory remains advisory.
