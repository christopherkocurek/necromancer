# Top20 Bundle 009 Review (2026-02-12)

Top-20 items covered: `#2` (Death Forensics Panel), `#9` (Status Effect Clarity), telemetry data quality for cluster A.

## Scope
- Fix data integrity bug in damage-source tracking.
- Improve death recap readability and causality depth.
- Add status resist/DOT forensic traces to complete the "why I died" chain.

## Changes
- `scripts/entities/player.gd`
  - Fixed `last_damage_source_id` assignment so valid monster IDs are preserved.
  - Forensic damage entries now include mitigation note when elemental resistance reduced damage.
- `scripts/systems/status_effects.gd`
  - Added player forensic entries when a status is resisted.
  - Added player forensic entries for DOT ticks (`poisoned`, `cut`, `burning`) with severity context.
- `scripts/ui/death_screen.gd`
  - Increased recap depth from 5 to 8 events.
  - Added explicit killing effect line and last damage packet line.
  - Added severity markers and category tags per forensic row.

## Discipline Checks
- Frontend/UI: PASS
  - Death screen information hierarchy now exposes source/effect/severity with minimal noise.
- Backend/system contracts: PASS
  - RunStats forensic schema reused consistently (`turn`, `category`, `severity`, `text`).
- Gameplay readability: PASS
  - Death feedback now more directly maps to actionable counterplay.
- Telemetry readiness: PASS
  - Source ID bug fix improves downstream run analysis quality.

## Risks
- Forensic event volume may grow faster on DOT-heavy runs; currently capped by `MAX_FORENSIC_EVENTS`.
- Category labels are raw IDs; future polish can map to localized player-facing labels.

## Validation
- `godot --headless --path . --quit` passed.
- Existing pre-existing warnings remain unrelated (DataManager key warnings, exit leak warning).

## Recommendation
- Accept bundle.
- Next follow-up: optional per-turn "death replay strip" widget in death screen with timeline scrub controls.
