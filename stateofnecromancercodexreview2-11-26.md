# State of Necromancer Codex Review (2026-02-11)

## Core Architecture Summary

The current project architecture is centered on a Godot `main.gd` scene coordinator plus autoload singletons.

- `main.gd` orchestrates scene lifecycle, level generation, player spawn, panel/UI management, and turn handoff.
- Core autoloads:
- `GameManager`: global run state (depth, turns, player/level references, logs, progression).
- `EventBus`: cross-system signal hub for combat/status/movement/game-state events.
- `DataManager`: content loader/indexer for monsters, items, artifacts, abilities, races, houses, vaults.
- `TileMapper`: atlas mapping between game enums/IDs and sprite coordinates.
- `LayerConfig`: depth-to-layer rules, visual/config tuning per dungeon band.
- Game loop uses an energy-driven turn system:
- player action -> enemy turns in energy order -> round-complete updates (cooldowns/status/voice) -> next player input.
- Entity model:
- `Entity` base class (movement/combat/status hooks), `Player` and `Monster` specializations.
- `StatusEffects` + `EffectDefinitions` handle effect logic, decay, resistance checks.
- Dungeon generation is in `dungeon_generator.gd`, with connectivity validation and post-decoration stairs connectivity repair already present.

## Bug Summary and Fix Status

### Fixed in this pass

1. Equipment resistances were not consulted by status effect resistance checks.
- File: `scripts/systems/status_effects.gd`
- Fix: wired resistance property -> equipment flag checks (`RES_FIRE`, `RES_FEAR`, `FREE_ACT`) for players.

2. `PER_LISTEN` ability had no gameplay hook.
- Files: `scripts/entities/player.gd`, `scripts/main.gd`
- Fix: implemented stationary Listen pulse that reveals nearby monsters through walls for observation/visibility handling.

3. `STL_SILENT_KILL` had no concrete behavior.
- Files: `scripts/entities/monster.gd`, `scripts/core/constants.gd`
- Fix: added non-silent kill noise emission and made Silent Kill suppress that by classifying kills as silent for noise/logging behavior (without granting unintended 2x XP unless the target was actually unwary).

4. Exit cleanup was incomplete for dynamically created UI/runtime nodes.
- File: `scripts/main.gd`
- Fix: added `_cleanup_before_exit()` wiring from `_on_quit_requested`, window close notification, and `_exit_tree`, with signal disconnection and explicit node teardown.

### Verified already fixed before this pass (no new code change needed)

1. Monster `OPEN_DOOR` behavior is connected in movement checks.
- File: `scripts/entities/monster.gd`

2. Post-decoration stairs connectivity repair exists.
- File: `scripts/systems/dungeon_generator.gd`

3. Axe proficiency tval bug is already corrected to `22`.
- File: `scripts/entities/player.gd`

### Still observed (test-harness level)

- Headless test run still reports CanvasItem/ObjectDB leak warnings at process exit.
- Test output also reports existing integration-test orphans in `test_turn_flow.gd`.
- This indicates remaining teardown/orphan behavior beyond the newly added quit-path cleanup.

## Validation Run

- Command: `godot --path . --headless --script res://test_runner.gd -- --unit-only`
- Result: pass (`4906` passing asserts, `5` existing pending tests), with pre-existing exit leak/orphan warnings still present.
