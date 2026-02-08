# V3 Bot Brain + Alpha Systemic Fixes — Session Prompt

**Paste this entire document as your opening message in a fresh Claude Code session.**

**Working directory:** `~/dev/active/games/necromancer-godot`
**Branch:** `necromancer-godot-alpha`
**Starting commit:** `7854ab5` (Bot v2 intelligence upgrade)
**Skills available:** `/necromancer-dev`, `/rogue-dev-challenge`, `/megapass`

---

## Context

The Necromancer is a Sil-Q successor roguelike rebuilt in Godot 4.6 (GDScript). The automated testing bot has gone through two generations:

- **V1:** Basic combat only. 120 runs, 0% win rate, max depth 3.
- **V2:** Added stealth, songs, ranged combat, forge-seeking, 10 archetypes. 200 runs, 0% win rate, max depth 6.

The V3 upgrade focuses on **tactical intelligence** (corridor fighting, threat assessment, door tactics) and **archetype expansion** (8 new builds for 18 total). A comprehensive 1327-line plan exists at `docs/BOT_UPGRADE_PLAN.md` with full pseudocode.

### V2 Baseline (beat these numbers)

| Metric | V2 Value |
|--------|----------|
| Win rate | 0.0% |
| Mean depth | 1.8 |
| Max depth | 6 |
| Floor 1 survival | 24-100% (varies by archetype) |
| Floor 3 survival | 16-46% |
| Floor 5 survival | 0-6% |
| Best archetype | LORE_MAGE (avg depth 2.3) |
| Worst archetype | SMITH (avg depth 1.5) |

---

## Step 0: Read Key Files First

Before writing any code, read these files to understand the codebase:

```
docs/BOT_UPGRADE_PLAN.md          # 1327 lines — full v3 plan with pseudocode for every upgrade
tests/bot/survival_bot.gd         # Current bot AI (~1200 lines) — modify heavily
tests/bot/archetype_configs.gd    # Current 10 archetypes — add 8 new ones
scripts/entities/player.gd        # Player API (abilities, equipment, combat, stealth)
scripts/core/constants.gd         # Ability IDs, alert levels, tile enums, noise constants
scripts/systems/dungeon_generator.gd  # Forge spawning, item placement, _spawn_forge_materials()
scripts/systems/smithing_system.gd    # Smithing recipes, success formula
data/race.txt                     # Starting equipment per race (add bow+arrows to all)
data/object.txt                   # Item definitions — Silvan Bow sval=12 tval=19, Arrow sval=1 tval=17
scripts/analysis/analyze_results.py   # Analysis pipeline — add v3 telemetry columns
scripts/analysis/run_harness.sh       # Bot run harness — add 18 archetypes
docs/BALANCE_REPORT.md               # V2 baseline metrics
```

---

## Step 1: Two Systemic Fixes (Do First)

### Fix 1A: Universal Starting Bow + Arrows

Add to ALL races in `data/race.txt`: 1x Silvan Bow (tval=19, sval=12) + 1x stack of 20 Arrows (tval=17, sval=1).

- Read `data/race.txt` and `data/object.txt` first to understand the format
- Each race's starting equipment section needs the bow and arrows added
- This is a temporary testing change — gives ranged builds immediate access
- After adding to starting equipment, **remove** `_spawn_guaranteed_bow()` from `scripts/systems/dungeon_generator.gd` (no longer needed)

### Fix 1B: Forge Material Spawning

In `scripts/systems/dungeon_generator.gd`, function `_spawn_forge_materials()`:
- Change `randi_range(1, 3)` to `randi_range(2, 3)` — guarantee minimum 2 Mithril pieces per forge
- Verify the SMITH bot's `_try_seek_forge()` pathfinds to materials FIRST, then to the forge tile
- The SMITH archetype had 0 forge successes across 50 runs despite 2.8 forge visits — likely because bot reaches forge without materials

---

## Step 2: P0 Quick Fixes (~1 hour)

These are 5-minute fixes from the BOT_UPGRADE_PLAN.md appendix:

1. **Fix Song of Trees ability ID:** In `archetype_configs.gd`, STEALTH and STEALTH_PURE wishlists reference ability ID 15 (Song of Freedom). Change to 16 (Song of the Trees). Verify against `constants.gd` enum values.

2. **Remove Song of Aule from SMITH wishlist:** Song of Aule requires Lore 7 + voice charges. SMITH has GRA 0 (20 voice) and zero Lore investment — it's unreachable.

3. **Wire up `_total_stealth_kills`:** In `survival_bot.gd`, before each melee attack, capture `monster.alertness`. After kill, if alertness was < `Constants.ALERTNESS_ALERT`, increment `_total_stealth_kills`. See BOT_UPGRADE_PLAN.md §3.3.1 for exact code.

4. **Wire up `_total_detections`:** Track monster alertness transitions per turn. When a monster goes from unwary → alert while player is stealthed, increment. See BOT_UPGRADE_PLAN.md §3.3.1 for the `_update_detection_tracking()` function.

5. **Separate STEALTH and STEALTH_PURE init:** In `survival_bot.gd`, `_init_archetype_strategy()` has `"STEALTH", "STEALTH_PURE":` sharing the same match branch. Give STEALTH its own behavior (hybrid combat/stealth) while STEALTH_PURE stays pure avoidance.

---

## Step 3: P1 Tactical AI (~12 hours, use /megapass)

This is the core v3 work. Use `/megapass` to parallelize these 7 streams:

### Stream 1: Corridor/Doorway Fighting (all archetypes)
- Implement `_tile_combat_score(pos)` — score tiles by wall count, doorway proximity
- Implement `_retreat_to_corridor()` — pathfind to best nearby fighting position
- Insert as Priority 0.5 in the decision engine (between emergency and flee)
- Add `_total_corridor_fights` and `_total_corridor_repositions` counters
- See BOT_UPGRADE_PLAN.md §3.1.1 for full pseudocode

### Stream 2: Threat Assessment (all archetypes)
- Implement `_assess_threat(monster)` — compare attack/evasion differentials, HP ratio, monster flags
- Implement `_should_fight(monster)` — per-archetype thresholds (STEALTH_PURE: < 0.3, TANK: < 2.0)
- Wire into combat decisions: only engage if `_should_fight()` returns true
- Add `_total_threat_assessments` and `_total_threats_avoided` counters
- See BOT_UPGRADE_PLAN.md §3.1.2

### Stream 3: Door Tactics (all archetypes)
- Implement `_try_close_door_behind()` — close doors after passing through when monsters are chasing
- Track `_last_position` each turn for door detection
- Stealth archetypes close proactively; combat archetypes close when pursued
- Add `_total_doors_closed` counter
- See BOT_UPGRADE_PLAN.md §3.1.3

### Stream 4: STEALTH_ASSASSIN Kill Loop
- Implement `_stealth_assassin_decide_v3()` with alertness-aware targeting
- Replace `_get_weakest_visible_monster()` targeting with `_get_best_assassination_target()` (lowest alertness, then lowest HP)
- Fix `_manage_stealth()`: stealth should only be re-entered OUT of all monster LOS, not just when no adjacent monster
- Track Nimble Striker procs (move + attack kills → free move)
- See BOT_UPGRADE_PLAN.md §3.2.3

### Stream 5: RANGER Stealth Fix + Kiting
- Fix `_manage_stealth()` for RANGER archetypes: keep stealth ON when monsters are visible (currently turns OFF)
- RANGER_STEALTH_ARCHER needs its own `_stealth_archer_decide()` function
- Implement `_ranger_kite_in_corridor()` — fire from corridor, retreat after shot
- See BOT_UPGRADE_PLAN.md §3.2.5

### Stream 6: LORE_MAGE Voice Budget
- Implement `_lore_mage_voice_budget()` — allocate voice across emergency/song/offensive/utility
- Fix Deep Memory overuse: only fire when stairs are unknown (max 2 per floor)
- Fix Lore of Sleep targeting: target CLOSEST approaching monster, not strongest
- Add song cycling: Trees for exploration, Freedom for combat, Aule for forging
- See BOT_UPGRADE_PLAN.md §3.2.4

### Stream 7: TANK/WARRIOR Positional AI
- TANK: `_tank_doorway_decide()` — seek doorways, stand and fight (Blocking requires standing still)
- WARRIOR: `_warrior_combat_upgrade()` — exploit Last Stand zone (15-25% HP → fight aggressively)
- SHIELD_WALL: shield-aware behavior (stand still for Blocking, Shield Brother -1 evasion debuff)
- See BOT_UPGRADE_PLAN.md §3.2.1, §3.2.7

---

## Step 4: P2 Archetype Expansion (~4 hours)

### Add 8 New Archetypes to `archetype_configs.gd`

Full stat blocks, wishlists, and skill priorities are in BOT_UPGRADE_PLAN.md §2.2:

1. **POLEARM_MASTER** — Man of Rohan, Defiance. Melee/EVN/Hunting/Will. Corridor specialist.
2. **ELF_SMITH** — Elf of Rivendell, Forge Intuition. Smithing/EVN/Lore/Melee. Song of Aule access.
3. **WILL_TANK** — Dwarf of Khazad-dum, Undying Resolve. Will/Melee/EVN/Hunting. Dual death prevention.
4. **HOBBIT_SNIPER** — Hobbit of Shire, Steady Aim. Archery/Stealth/EVN/Will. Stand-then-shoot.
5. **GREENWOOD_RANGER** — Elf of Greenwood, Patient Stalker. Stealth/Archery/EVN/Lore. 3-turn proc tracker.
6. **HOBBIT_BURGLAR** — Hobbit of Gamgees, Shadow Step. Stealth/EVN/Hunting/Melee. Theft mechanics.
7. **BANISHMENT_MAGE** — Elf of Lothlorien, Song of Banishment. Lore/Will/EVN/Stealth. Victory path.
8. **SHIELD_WALL** — Man of Gondor, Shield Brother. Melee/EVN/Will/Hunting. Shield-focused tank.

### Per-Archetype Exploration Thresholds

Implement `_get_archetype_explore_threshold()`:
- STEALTH_PURE: 30% (beeline stairs)
- STEALTH_ASSASSIN, STEALTH, RANGER_STEALTH_ARCHER: 40%
- LORE_MAGE, BANISHMENT_MAGE: 60%
- WARRIOR, TANK, SHIELD_WALL, POLEARM_MASTER: 80%
- SMITH, ELF_SMITH: 90%

### Per-Ability Telemetry

Replace flat `_total_abilities_used` with `_total_abilities_by_id: Dictionary = {}` tracking per ability ID. Add to JSON output.

### Update Analysis Pipeline

In `scripts/analysis/analyze_results.py`:
- Add all 18 archetype names
- Add v3 telemetry columns: corridor_fights, doors_closed, threats_avoided, stealth_kills, detections, voice_at_death, abilities_by_id
- Add Wilson CI calculation for win rates

In `scripts/analysis/run_harness.sh`:
- Add all 18 archetype names to the loop
- Set 40 runs per archetype
- Keep seeds 1000-1039

---

## Step 5: P3 Advanced Features (~8 hours, if time allows)

Lower priority. Do these after P0-P2 are working:

1. **BANISHMENT_MAGE victory path:** Track Rod of Istari pieces at depths 10/15/18. When rod assembled + Lore >= 12 + Will >= 10, navigate to Throne Room for Banishment attempt.
2. **Patient Stalker turn tracking:** GREENWOOD_RANGER must count consecutive stealth turns. Proc double-damage after 3+.
3. **Steady Aim awareness:** HOBBIT_SNIPER must wait one turn (stand still) before firing for Steady Aim bonus.
4. **Smith material hoarding:** `_smith_should_seek_materials()` + `_smith_material_item_score()` for targeted material pickup.
5. **Hunger management:** `_check_hunger()` as Priority 0.1 (before all combat). Eat food when hunger > threshold.

---

## Step 6: Experiments (run after implementation)

### Experiment 1: V3 Normal (720 runs)
```bash
# 40 runs × 18 archetypes = 720 runs, seeds 1000-1039
cd ~/dev/active/games/necromancer-godot
bash scripts/analysis/run_harness.sh
python3 scripts/analysis/analyze_results.py bot_results_v3/ > docs/BALANCE_REPORT_V3.md
```

### Experiment 2: V3 Easy (720 runs)
```bash
# Same but on Easy difficulty
# Modify run_harness.sh to pass --difficulty easy
bash scripts/analysis/run_harness.sh
python3 scripts/analysis/analyze_results.py bot_results_v3_easy/ > docs/BALANCE_REPORT_V3_EASY.md
```

### Compare V2 vs V3
- V2 baseline is in `docs/BALANCE_REPORT.md` and `bot_results_v2/`
- Generate comparative analysis: depth improvement, survival curves, system engagement

---

## Verification Checklist

After all implementation + experiments:

- [ ] All 18 archetypes run without crashes (headless Godot)
- [ ] V3 mean depth > 3.0 (vs v2 baseline 1.8)
- [ ] V3 floor 1 survival > 80% (vs v2 baseline 38-76%)
- [ ] At least 1 archetype achieves non-zero win rate on Easy
- [ ] All telemetry counters produce non-zero values for relevant archetypes
- [ ] Stealth kills tracked for STEALTH_ASSASSIN, detections tracked for all stealth builds
- [ ] Corridor fights tracked for WARRIOR/TANK
- [ ] Forge successes > 0 for SMITH/ELF_SMITH
- [ ] Starting bow+arrows present for all races
- [ ] `_spawn_guaranteed_bow()` removed from dungeon_generator.gd

---

## Commit Strategy

Commit after each logical milestone, not at the end:

1. `Step 1 complete` — systemic fixes (starting bow, forge materials)
2. `Step 2 complete` — P0 quick fixes (ability IDs, telemetry wiring)
3. `Step 3 complete` — P1 tactical AI (corridor fighting, threat assessment, door tactics)
4. `Step 4 complete` — P2 archetype expansion (8 new archetypes, analysis pipeline)
5. `Step 5 complete` — P3 advanced features (if implemented)
6. `Step 6 complete` — experiment results + balance reports

---

## Important Codebase Notes

- **GDScript typing:** Always explicitly type variables, especially error returns. Use `var err: int = ...` not `var err = ...`.
- **Ability IDs:** Defined in `scripts/core/constants.gd`. Cross-reference with `data/ability.txt`. The IDs are NOT the same as skill tree positions.
- **Monster alertness levels:** `ALERTNESS_SLEEPING` < `ALERTNESS_UNWARY` < `ALERTNESS_ALERT` < `ALERTNESS_AGGRESSIVE`. Check `constants.gd` for exact values.
- **Stealth check formula:** d10 + perception + difficulty_bonus vs d10 + stealth_score. Distance modifier: max(0, 6-dist). The d10 makes every +1 worth 10%.
- **Combat formula:** d20 + attack vs d20 + evasion. Damage = weapon_dice + STR_bonus - protection_roll.
- **Smithing success:** `min(smithing * 8, 95)`. At smithing 1 = 8% success. At smithing 5 = 40%.
- **Voice regen:** max_voice / 150 per turn. GRA 7 = 72 voice, 0.48/turn regen.
- **HP formula:** 24 * 1.2^CON. CON 7 = 86 HP. CON 2 = 35 HP.
- **Bot harness:** `scripts/analysis/run_harness.sh` uses `xargs -P4`. `test_runner.gd` must `return` after bot launch to avoid premature `quit()`.
- **Tile system:** Row 18 = DALL-E terrain. Rows 24-26 = monsters. `Level.Tile.DOOR_OPEN` and `Level.Tile.DOOR_CLOSED` for door tactics.
