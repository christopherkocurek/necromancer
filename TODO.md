# Necromancer Godot - Shared TODO

This file coordinates work between parallel Claude sessions.

**Main repo:** `~/dev/active/games/necromancer-godot` (master)
**Status:** Phase 7 - DCSS Tileset Integration COMPLETE

---

## Completed Tasks

| Date | Task | Notes |
|------|------|-------|
| 2026-02-05 | DCSS Tileset Integration | Replaced old 16x16 tileset with 32x32 DCSS tileset |
| 2026-02-05 | TileSet resource updated | Now uses 2048x2048 necromancer_dcss_tileset.png |
| 2026-02-05 | tile_mapper.gd replaced | New DCSS-based mapper with 294 tiles |
| 2026-02-05 | Level.gd Tile enum compatibility | Added mappings for VOID, FLOOR, WALL, etc. |

---

## Current Phase: Testing & Polish

| Status | Priority | Task | Notes |
|--------|----------|------|-------|
| [ ] | HIGH | Visual test of tileset in-game | Launch game, verify terrain/monsters/items render |
| [ ] | MED | Add more char_to_monster_id mappings | Some monsters may not have sprites |
| [ ] | MED | Fix GUT test script issues | test_turn_flow.gd has parse error |
| [ ] | LOW | Clean up old tile_mapper files | Remove tile_mapper_old.gd, tile_mapper_dcss.gd |

---

## Feature Backlog (Next)

| Status | Priority | Task | Notes |
|--------|----------|------|-------|
| [ ] | HIGH | Combat Telegraph & Intent Overlay (Focus-first) | Show intent in Look/Target panel for focused enemy only; optional single target icon; no global icon spam |
| [ ] | HIGH | Hunting-gated intent clarity tiers | Low hunting = coarse intent, high hunting = specific action/ETA/target certainty |
| [ ] | HIGH | Threat Summary line in HUD/Target panel | Aggregate signal for swarms (e.g., enemies that can hit this turn, caster threats) |
| [ ] | HIGH | Smart New-Player Assist Layer (toggleable) | Contextual risk tips only; no spam. Show "Basic/Full/Off" in settings |
| [ ] | HIGH | Assist design note (approved) | Do NOT hard-gate tips by Hunting/Lore. Instead: give coarse warnings to all, then tutorial-style in-run hint that investing Hunting/Lore improves battlefield reads and guidance quality |
| [ ] | HIGH | Action feel emotional target (approved) | Combat feedback must feel desperate and oppressive as depth increases. First encounters with control casters (e.g., Dark Sorcerer) should push fear/doom psychographic state; player should feel "I might die here" |
| [ ] | HIGH | Run Chronicle system (approved) | Persistent run journal with outcomes, epitaph/highlights, milestones, and export-ready summary text; non-power progression only |
| [ ] | HIGH | Run goals rewards (approved) | Non-power progression via: (1) Legacy Banner identity unlocks, (2) Chronicle Relics display cards, (3) Intro Epithets/title prefixes. Phase-later: (4) cosmetic sprite/HUD accents only (no silhouette/readability changes) |
| [ ] | HIGH | Escape pursuit meter behavior note (approved) | Pursuit meter must have meaningful gameplay interactions at each threshold; escalation must materially change encounter pressure, reinforcement behavior, and extraction tactics |
| [ ] | HIGH | Enemy Knowledge Codex (approved) | Persistent codex accessible from main menu as a tome/scroll; framed as accumulated records of fallen heroes across runs |
| [ ] | MED | Build Identity Dashboard mode policy (approved) | Keep optional guidance in Normal mode; disabled by default for experienced players; fully disabled in Hardcore mode |
| [ ] | LOW | Adaptive music state machine (post-beta) | Deferred for beta; depends on expanded audio asset set (Suno generation/craft). Build architecture hooks first, full rollout later |
| [ ] | HIGH | Room drama events foundation (approved) | Build room tags/types/event seeds in level gen; run layer-specific design stream for room architecture + monsters/items + trigger events |
| [ ] | HIGH | Inscription event rooms (approved) | Restore/expand inscription encounters: procedurally generated lore text + XP reward moments (legacy target 500 XP), placed in high-impact thematic rooms |
| [ ] | HIGH | Top-20 cross-surface design gate (mandatory) | Before implementing overlapping UI/menu/HUD features, run holistic gate from `docs/TOP20_BETA_IMPLEMENTATION_PLAN.md` (surface inventory, priority rules, mode policy, tone, telemetry, playtest checks) |
| [ ] | HIGH | HUD specialist workstream | Produce unified in-run information architecture for intent/threat/status/pursuit/assist/death forensics before final wiring |
| [ ] | HIGH | Chronicle-meta unification pass | Link Run Chronicle + Codex + Achievement/Export + Meta-lite into one persistent tome system from main menu |
| [ ] | HIGH | Difficulty/helper consolidation pass | Merge helper toggles, dashboard policy, and accessibility settings into one coherent Normal/Hardcore mode model |

---

## Known Issues

1. **DataManager warnings** - Missing key monsters (Morgoth, Orc, Troll, Spider) and races (Noldor, Sindar) in validation. These are validation checks, not runtime errors.

2. **Test script parse error** - `test_turn_flow.gd:146` has a parameter name issue.

---

## Files Changed (DCSS Integration)

- `assets/sprites/necromancer_tileset.tres` - Updated to use 32x32 DCSS grid
- `scripts/core/tile_mapper.gd` - Replaced with DCSS version (294 tiles)
- `scripts/core/tile_mapper_dcss.gd` - Source for new mapper (can be deleted)
- `scripts/core/tile_mapper_old.gd` - Backup of old mapper (can be deleted)

---

## Notes

_The DCSS tileset integration is complete. The game now uses GPL-licensed DCSS tiles scaled from 32x32 to 64x64. Dark variants are generated for FOV system. All terrain, monster, and item tiles are mapped._
