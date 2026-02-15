# Scenario Schema v1

## File Format
- Encoding: UTF-8 JSON
- Top-level object required

## Required Top-level Keys
- `schema_version`: string, must be `"v1"`
- `id`: string, unique scenario id
- `name`: string
- `mode`: string enum: `deterministic` or `exploratory`
- `seed`: integer
- `severity`: string enum: `blocker|major|minor|info`
- `tags`: array of strings
- `setup`: array of setup action objects
- `actions`: array of action objects
- `settle_ticks`: integer >= 0
- `checkpoints`: array of checkpoint objects
- `teardown`: array of teardown action objects

## Action Object
- `op`: string
- `args`: object (optional)

## Checkpoint Object
- `id`: string
- `capture`: bool (default true)
- `collect_telemetry`: bool (default true)
- `assertions`: array of assertion objects
- `baseline_key`: string (optional)

## Assertion Object
- `type`: `eq|range|contains|regex|exists`
- `path`: dot-path into telemetry payload
- `value`: any (required for `eq|contains|regex`)
- `min`: number (required for `range`)
- `max`: number (required for `range`)
- `severity`: `blocker|major|minor|info`
- `message`: string (optional)

## Deterministic Scenario Rules
- Must specify `mode=deterministic` and stable `seed`.
- Checkpoint IDs must be deterministic and unique per scenario.
- Any nondeterministic action must be rejected by validator.
