# Telemetry Schema v1

## Envelope
- `schema_version`: `"v1"`
- `run_id`: string
- `scenario_id`: string
- `checkpoint_id`: string
- `timestamp_unix_ms`: integer
- `seed`: integer
- `test_mode`: bool

## Required Runtime Sections
- `light_state`
- `naming_state`
- `protection_state`
- `boss_state`
- `xp_state`
- `aggro_state`

## Required Keys
### boss_state
- `base_monster_name`: string
- `displayed_title`: string
- `unique_key`: string
- `spawn_source`: string
- `is_transition_boss`: bool

### xp_state
- `source`: string
- `raw_amount`: number
- `multiplier`: number
- `final_amount`: number
- `event_context`: string

### aggro_state
- `source_monster`: string
- `alerted_monsters`: array of strings
- `radius`: number
- `wake_count`: integer
- `target_updates`: integer

## Optional Diagnostics
- `ui_snapshot`: object
- `timing`: object
- `warnings`: array of strings
