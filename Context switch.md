# Context Switch: The Necromancer (Godot)

## Project Summary
The Necromancer is a turn-based Tolkien roguelike set in Dol Guldur, originally derived from Sil-Q (Angband variant). The project is a full port to Godot 4.6 with added visuals, tiles, UI, and modern engine features. Game content (monsters, items, abilities, races, vaults, terrain, etc.) is data-driven from Sil-Q `data/*.txt` files and loaded at runtime.

## Current Status (as of 2026-02-10)
- Engine: Godot 4.6 (GDScript).
- Core systems implemented; overall parity with Sil-Q estimated ~70%.
- DCSS tileset integration is complete; remaining work is testing/polish and targeted gap closure.
- Build quality is tracked via docs with recent updates:
  - `docs/PARITY_ANALYSIS.md` (2026-02-08)
  - `docs/KNOWN_ISSUES.md` (2026-02-08)
  - `docs/GODOT_IMPLEMENTATION_STATUS.md` (2026-02-05)

## Architecture Overview
Autoload singletons (see `ARCHITECTURE.md`):
- `GameManager`, `EventBus`, `DataManager`, `TileMapper`, `ThemeColors`, `AudioManager`, `LayerConfig`, `AccessibilityManager`, `PanelTransition`, `TooltipManager`, `TutorialManager`, `HelpOverlay`.
- Load order matters and is defined in `project.godot`.

Main system structure:
- `scripts/core/*`: core state, data loading, tile mapping, event bus, audio.
- `scripts/entities/*`: `Entity`, `Player`, `Monster`, `Item`, `NPC`, `Thrain`.
- `scripts/systems/*`: combat loop, dungeon generation, abilities, smithing, status effects, quests, etc.
- `scripts/ui/*`: HUD and panels.
- `data/*`: Sil-Q data files.
- `scenes/*`: Godot scenes.
- `tests/*`: GUT tests (unit/gameplay/integration/bot).

Game loop (high-level):
- Player action -> animation delay -> enemy turns -> end-of-round ticks via `TurnSystem`.

## Known Gaps / Issues (high signal)
From `docs/KNOWN_ISSUES.md` and `docs/PARITY_ANALYSIS.md`:
- Ability stubs: Listen (Perception/Hunting), Silent Kill (Stealth) have no gameplay hook.
- Trap reveal portion of Word of Opening not implemented.
- Word of Shutting does not seal doors (monsters reopen as normal).
- Equipment resistances parsed but not applied in status effects.
- Monster door-opening AI uses flag but lacks behavior.
- No level persistence: floors regenerate on return.
- Rare disconnected rooms after post-decoration; no connectivity validation.
- RID leaks on exit in debug (UI panels not freed explicitly).
- Balance concerns: Word of Command overpowered; smithing doesn’t apply damage dice/weight/parry adjustments; song bonuses arbitrary.

## Current Phase
Testing & polish (from `TODO.md`):
- Visual test of tileset in game.
- Add missing `char_to_monster_id` mappings for sprites.
- Fix GUT test parse error in `test_turn_flow.gd`.
- Clean up old tile mapper files.

## How to Continue Work
Suggested approach:
1. Choose a focus: parity gaps, stability/bugs, or polish.
2. Work in small, isolated changes to avoid cross-system regressions.
3. Update relevant docs (`docs/KNOWN_ISSUES.md`, `docs/PARITY_ANALYSIS.md`, `docs/CHANGELOG.md`) after fixes.

## Collaboration Notes
- Codebase was previously developed with Claude; now you are collaborating with Codex.
- Prefer clear, scoped tasks with explicit “done” criteria (e.g., “Implement Listen ability: reveal monsters through walls when stationary; add tests”).
- If tests are required, run GUT or relevant scripts and capture results.

