# SMITHING OVERHAUL — New Session Instructions

You are working on The Necromancer, a Sil-Q inspired roguelike built in Godot 4.6 (GDScript). The smithing system needs to be overhauled to match the C version's depth, then improved for fun.

Use these skills:
- /rogue-dev-challenge — for roguelike design expertise on smithing balance
- /megapass — for parallel implementation streams if scope warrants it

## READ THESE FILES FIRST (in order)

1. docs/SMITHING_SESSION_PROMPT.md (this file — for context)
2. scripts/systems/smithing_system.gd (current Godot implementation — 449 lines, needs heavy rewrite)
3. scripts/core/constants.gd (SmithingAbility enum at lines 170-183)
4. data/ability.txt (smithing abilities at lines 588-678 — 12 abilities defined, most not implemented)
5. data/object.txt (smithing materials: IDs 410, 491-495)
6. data/artefact.txt (147 artifacts — these are Reclaim outputs)
7. scripts/systems/dungeon_generator.gd (forge placement at lines 1499-1586)
8. scripts/core/data_manager.gd (item/artifact generation helpers)
9. scripts/entities/player.gd (player smithing API)
10. tests/bot/survival_bot.gd (bot forge behavior at lines 1956-2458)
11. tests/bot/archetype_configs.gd (SMITH and ELF_SMITH archetypes)
12. docs/BOT_UPGRADE_PLAN.md (section 1.6 SMITH audit + section 3.2.6 smith upgrades)

## GAP ANALYSIS: C VERSION vs GODOT

| Feature | C Version | Godot Status | Priority |
|---------|-----------|-------------|----------|
| Weaponsmith/Armoursmith/Jeweller | Full CREATE from mithril | Working (basic) | OK |
| Reforge (2 glowing → enchanted) | Type-filtered output, 600 XP cost | Works but output is random depth item, no type filtering, no XP cost | P0 |
| Reclaim (2 strange → artifact) | Type-filtered artifact, level×50 XP | Works but picks ANY random artifact, no type filtering | P0 |
| Masterwork (4 strange → legendary) | Best-tier artifact | NOT IMPLEMENTED | P0 |
| Forge types (Normal/Enchanted/Unique) | +0/+3/+7 bonus, 2-4 uses | All forges identical, always 5 uses | P1 |
| Expertise | 50%/75% cost reduction | Enum exists, not implemented | P1 |
| Reforge Mastery | Reject+reroll once | Enum exists, not implemented | P1 |
| Reclaim Mastery | Show 3 artifacts, pick 1 | Enum exists, not implemented | P1 |
| Master Smith | Masterwork with 2 items instead of 4 | Enum exists, not implemented | P1 |
| Salvage | 50% recover glowing from destroyed gear | Enum exists, not implemented | P2 |
| Grace | +1 GRA stat | Enum exists, not implemented | P2 |
| Melt | Convert mithril items → pieces | NOT IMPLEMENTED | P2 |
| Song of Aule integration | +smithing bonus when song active | Not checked in smithing_system.gd | P1 |
| Custom artifacts | Player-designed items | NOT IN SCOPE (complex UI) | Skip |
| Variable success rates | Different per recipe type | All use same formula (skill×8, cap 95%) | P1 |
| XP costs for Reforge/Reclaim | 600 XP / level×50 XP | NOT IMPLEMENTED — no XP consumption | P0 |
| Forge use tracking | 2-4 uses, consumed per craft | Always returns 5, never decremented | P0 |
| "Broken Glowing Jewelry" item | N/A (C version has weapon+armor only) | MISSING — user wants this added for mid-game jewelry reforging | P0 |

## IMPLEMENTATION TASKS

### P0: Core Mechanics (must fix)

#### Task 1: Add "Broken Glowing Jewelry" item
- Add new item ID 496 to data/object.txt:
```
N:496:& Broken Glowing Ring~
G:=:B
I:45:98:0
W:5:0:1:60
P:0:0d0:0:0d0
A:5/4:10/3:15/2
F:DAMAGED | NO_SMITHING | EASY_KNOW
D:A cracked ring that still pulses with faint enchantment. A skilled smith might reforge it.
```
- Add ID 496 to smithing_system.gd constants
- Add to _spawn_forge_materials() material pool at depth >= 5
- Add to _is_broken_glowing() detection
- Add sprite mapping in tile_mapper.gd

#### Task 2: Implement MASTERWORK recipe
- Add RecipeType.MASTERWORK to enum
- Recipe: 4 Broken Strange items → legendary artifact (highest-tier for chosen type)
- Required ability: SMT_MASTERWORK (enum 6)
- Min smithing: 8
- Implement in new masterwork() function

#### Task 3: Fix Reforge output generation
- Currently: DataManager.get_random_item_for_depth(depth + 2) — returns ANY item
- Should: Player chooses weapon OR armor OR jewelry category. Output is random ENCHANTED item of that type.
- Need: DataManager.get_random_enchanted_item(tval_category, depth) that filters for items with ego properties or special flags
- Add 600 XP cost (consume from player.new_exp)

#### Task 4: Fix Reclaim artifact filtering
- Currently: DataManager.get_random_artifact() — returns ANY artifact
- Should: Filter artifacts by tval matching the input material type:
  - 2 broken strange WEAPONS → weapon artifact
  - 2 broken strange ARMOR → armor artifact
  - 2 broken strange JEWELRY → jewelry artifact
- Need: DataManager.get_random_artifact_by_type(tval_category)
- Add XP cost: artifact.depth × 50 consumed from player.new_exp

#### Task 5: Implement forge use tracking
- Add forge_uses: Dictionary to Level (maps Vector2i → int)
- Initialize forge uses when placed: randi_range(2, 4) (3 for depth ≤ 4)
- consume_forge_use() must actually decrement and remove forge tile when uses = 0
- Each recipe costs 1 forge use

#### Task 6: Add XP costs to Reforge/Reclaim
- Reforge: 600 XP (from player.new_exp)
- Reclaim: artifact.depth × 50 XP
- Masterwork: artifact.depth × 75 XP
- Check affordability before attempting

### P1: Rich Mechanics

#### Task 7: Implement forge types
- Three tiers: FORGE (normal, +0), FORGE_ENCHANTED (+3), FORGE_UNIQUE (+7)
- Add to Level.Tile enum (FORGE is already 9, add FORGE_ENCHANTED = 10, FORGE_UNIQUE = 11)
- Update _ensure_forges():
  - Roll d1000 per forge. >= 1000: Unique (one per game). 990-999: Enchanted. < 990: Normal.
  - Unique forge: 3 uses. Enchanted: 3-4. Normal: 2-4.
- Forge bonus adds to effective smithing skill for success calculation
- Update tileset sprite for enchanted/unique forges

#### Task 8: Variable success rates per recipe
- CREATE: min(skill × 8, 95) (current — fine for basic crafting)
- REFORGE: min((skill + forge_bonus) × 6, 90) (harder, cap 90%)
- RECLAIM: min((skill + forge_bonus) × 5, 85) (hardest, cap 85%)
- MASTERWORK: min((skill + forge_bonus) × 4, 80) (very hard, cap 80%)

#### Task 9: Implement Expertise ability
- When player has SMT_EXPERTISE (ability 4):
  - Smithing 6-9: 50% reduction on XP costs
  - Smithing 10+: 75% reduction on XP costs
- Check in all recipe functions before XP consumption

#### Task 10: Implement Reforge Mastery
- When player has SMT_REFORGE_MASTERY (ability 8):
  - After generating random enchanted item, show it to player
  - Player can reject once → reroll for new random item
  - Must accept second result
- Bot behavior: always accept first result (no UI for bots)

#### Task 11: Implement Reclaim Mastery
- When player has SMT_RECLAIM_MASTERY (ability 10):
  - Generate 3 random artifacts of chosen type
  - Player picks which one to create
- Bot behavior: pick highest-depth artifact (strongest)

#### Task 12: Implement Master Smith
- When player has SMT_MASTER_SMITH (ability 11):
  - Masterwork recipe requires only 2 Broken Strange items instead of 4

#### Task 13: Song of Aule integration
- Check if player has active song == Song of Aule before smithing
- Add +2 to effective smithing skill while Song of Aule is active
- Song of Aule costs 2 voice/turn (already defined in ability.txt)

### P2: Polish

#### Task 14: Implement Salvage ability
- When equipment is destroyed (acid, fire, breakage): 50% chance to recover as Broken Glowing item
- Requires SMT_SALVAGE (ability 9)
- Hook into equipment destruction code in player.gd

#### Task 15: Implement Grace ability
- SMT_GRACE (ability 7): Permanent +1 GRA when learned
- Simple stat modification on ability learn

#### Task 16: Ensure materials spawn at forges in right quantities
- Current: randi_range(1, 3) per forge — can be only 1 item
- Change to: randi_range(2, 3) (minimum 2 materials per forge)
- Ensure depth 2 forge always has at least 2 Broken Glowing items (not just Mithril)
- Material pool fix: At depth 2, pool should ALWAYS include Broken Glowing Weapon + Shattered Elven Mail (currently requires depth 3/4)
  - Lower Broken Glowing Weapon to depth >= 2
  - Lower Shattered Elven Mail to depth >= 2

## FORGE MATERIAL ECONOMY (Target)

| Depth | Forge | Materials Near Forge | Expected Actions |
|-------|-------|---------------------|-----------------|
| 2 | Normal (2-4 uses) | 2-3: Mithril + Broken Glowing Weapon + Shattered Elven Mail | CREATE 1 improved weapon + 1 improved armor from mithril |
| 4 | Normal (2-4 uses) | 2-3: Broken Glowing items (weapon, armor, or jewelry) | REFORGE 1 enchanted item (if 2 glowing collected) |
| 6 | Normal/Enchanted | 2-3: Broken Glowing + maybe Broken Strange | REFORGE another enchanted item |
| 8 | Normal/Enchanted | 2-3: Broken Strange Weapon + Twisted Shadow-plate | RECLAIM 1 artifact (if 2 strange collected) |
| 10 | Normal/Enchanted | 2-3: Broken Strange (all types) | RECLAIM another artifact |
| 12+ | Enchanted/Unique | 2-3: Broken Strange (all types) | MASTERWORK legendary artifact |

## BOT SMITHING IMPROVEMENTS

Update tests/bot/survival_bot.gd:

1. Material pickup priority: Bot must actively seek and pick up Broken Glowing and Broken Strange items (currently only picks up items stepped on)
2. Material hoarding: Track collected smithing materials, prioritize picking up materials over generic items
3. Forge planning: When approaching a forge, check inventory for recipe eligibility. If missing materials, explore more before forging.
4. Recipe priority: RECLAIM > REFORGE > CREATE (prefer higher-tier recipes when materials available)
5. Telemetry: Track materials_collected, reforge_attempts, reforge_successes, reclaim_attempts, reclaim_successes, masterwork_attempts, items_forged_by_type

## DESIGN IMPROVEMENT (use /rogue-dev-challenge)

Before implementing, use the /rogue-dev-challenge skill to:

1. Compare smithing to other roguelike crafting systems (DCSS, Brogue, Caves of Qud, ADOM). What makes crafting FUN vs tedious?
2. Evaluate the RNG tension: Is "2 broken glowing → random enchanted item" exciting enough? Should there be a preview/choice mechanic even without Reforge Mastery?
3. Lucky streak design: How should the game reward a smith who finds 6 Broken Strange items on one floor? Is there a "hot streak" bonus?
4. Failure mitigation: Losing both materials on a failed forge feels BAD. Should failure return 1 material? Should higher skill reduce material loss?
5. Sound/visual feedback: What makes a successful forge feel AWESOME? (This is UI, note for future)

## OUT OF SCOPE (separate workstream)

**Item/Loot Table Retooling** — The enchanted/artifact items that come OUT of the forge need their own balance pass. The current loot tables may produce items that are too weak or too random to feel satisfying. This is a separate workstream covering:
- Weapon damage dice balance
- Armor protection values
- Artifact power levels
- Ego item naming and properties
- Enchantment variety and desirability

Save this as a priority in project memory but DO NOT implement in this session.

## VERIFICATION

After implementation:
1. Run 50 SMITH bot runs — verify forge_successes > 0 for majority of runs
2. Run 25 ELF_SMITH bot runs — verify Song of Aule activates before forging
3. Check that Broken Glowing Jewelry (ID 496) spawns near forges at depth 5+
4. Verify Reforge produces type-filtered enchanted items (not random depth items)
5. Verify Reclaim produces type-filtered artifacts
6. Verify forge uses decrement and forges disappear when exhausted
7. Verify XP costs are consumed on Reforge/Reclaim/Masterwork
8. Run tests/ — all existing tests must still pass

## CONTEXT

### Design Philosophy (Christopher's vision)
- 3rd Age = REFORGING/RECOVERING, not creating from scratch
- "Shards of Narsil → Anduril" as the core metaphor
- Smithing is the most RNG-heavy build but the most powerful when lucky
- Peak fantasy: Elf of Rivendell wielding Ringil + Ring of Power + Glorfindel's Armor
- A smith who hits a lucky streak should feel UNSTOPPABLE

### Intended Progression
1. Forge 1 (depth 2): 3 glowing items → 1 enchanted + 2 improved normal gear
2. Forge 2 (depth 4): 2 enchanted gear (including jewelry via new "Broken Glowing Jewelry" item)
3. Forge 3 (depth 6+): Invest in Reclaim → forge artifacts from Broken Strange items
4. Later forges: Masterwork for legendary artifacts, Reclaim Mastery for choosing artifacts
