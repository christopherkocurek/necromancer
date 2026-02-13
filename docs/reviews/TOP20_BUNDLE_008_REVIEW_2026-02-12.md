# Top-20 Bundle Review 008

Date: 2026-02-12
Bundle ID: `TOP20-B008-ROOMQUALITY-DIFFSURFACE-TELEMETRYOPS`
Top-20 items covered: `#14`, `#18`, `#20` (quality and ops pass)
Quality framework: `docs/TOP20_QUALITY_GATES_AND_REVIEWS.md`

## Tags
- `MAP_GENERATION`
- `FRONTEND_UI_HUD`
- `BACKEND_SYSTEMS`
- `TELEMETRY_BALANCE`

## Files Touched
- `scripts/core/event_bus.gd`
- `scripts/systems/run_goals_manager.gd`
- `scripts/systems/telemetry_logger.gd`
- `scripts/systems/dungeon_generator.gd`
- `scripts/ui/character_creation.gd`
- `scripts/analysis/summarize_telemetry.sh`

## What Was Implemented
- Room storytelling placement upgraded from random filler to room-quality-driven selection:
  - prioritizes vault/terror/deep/grand/exit rooms
  - avoids near-stairs placements
  - falls back safely if no suitable room tile found.
- Difficulty surface polish in character creation:
  - added clearer profile guidance for Easy/Normal/Hard/Ironman.
- Telemetry ops improvement:
  - added `run_goal_completed` event on EventBus
  - telemetry logger now records goal completion events
  - added `scripts/analysis/summarize_telemetry.sh` for quick event summaries.

## Discipline Scores
- Map Generation: `9.1/10`
- Frontend UI/HUD: `8.7/10`
- Backend Systems: `9.0/10`
- Telemetry/Balance: `9.2/10`

## Pass/Fail
- Status: `Pass`
- Reason: Room event quality now matches design intent better, and telemetry is now operational for tuning loops.

## Open Risks
- Storytelling room weighting may need per-layer retuning after broader playtest sampling.

## Next Tuning Actions
1. Add per-layer weighting tables for storytelling room priority.
2. Add CSV export companion for telemetry summary script.
3. Add dashboard threshold alerts (e.g., excessive `Relentless` time share).
