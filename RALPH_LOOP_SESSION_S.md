# Ralph Loop Mega-Pass: Session S — "Make It Fun"

## Mission Statement
Transform The Necromancer from a rough prototype into a polished, fun, balanced, winnable roguelike worthy of 10,000 installs. Every change must serve one goal: **make the player want to do "one more run."**

## Skills & Tools Available
- `/megapass` — Parallel multi-stream execution with test gates
- `/necromancer-godot` — Full project context, testing framework, file structure
- `/rogue-dev-challenge` — 50+ game roguelike design expertise
- `/tileset-gen` — **REQUIRED** for any new tile/sprite additions. Invokes DALL-E generation pipeline with proper protocols (BG removal, HSV correction, tileset integration). If a boss, item, or terrain type needs a new sprite, invoke `/tileset-gen` to generate it. NEVER manually edit tileset PNGs.
- `playtest_bot.gd` — Automated gameplay simulation (10-turn survival test)
- `test_runner.gd` — 125 tests, 684 assertions (unit + integration + bot)
- Sil-Q C reference: `~/dev/active/games/necromancer-master/` (READ-ONLY reference) or check my necromancer github repo for game design document or manual for visioning.

## Execution Model
Run as autonomous mega-pass cycles. Each cycle:
1. **Audit** — Run tests + bot, identify issues
2. **Design** — Plan fixes using roguelike design principles
3. **Implement** — Code changes in parallel streams
4. **Test** — Run full test suite + bot after each stream (use all 4 bots as needed)
5. **Verify** — Playtest bot confirms no regressions
6. **Commit** — One commit per stream with descriptive message
7. **Clean** — Remove unecessary code without accidentally deleting things the system needs
8. **Repeat** — Start next cycle with remaining items

## Priority Tiers (execute in order)

---

### TIER 1: CRITICAL BUGS & BROKEN SYSTEMS (Cycle 1)
*These block basic gameplay. Fix first.*

#### 1.1 Smithing System — Port from C Version
**Problem**: Smithing materials (tval 91/92) never spawn. System is completely non-functional.
**Solution**:
- Reference `~/dev/active/games/necromancer-master/src/` for the original smithing implementation
- Reference `~/dev/active/games/necromancer-master/lib/edit/object.txt` for smithing material definitions
- Ensure smithing materials spawn near forges (1-3 materials within 3 tiles of each forge)
- Also spawn smithing materials as rare floor drops (5% of item spawns on floors with forges)
- Port the FULL smithing recipe tree from the C version — do not simplify
- Verify: Player can find materials, walk to forge, press F, and either create new weapons & armor or reforge / reclaim - ENHANCE DOES NOT EXIST !
**Files**: `dungeon_generator.gd`, `smithing_system.gd`, `data_manager.gd`, `smithing_panel.gd`

#### 1.2 Weapon Evasion — Port Sil-Q Mechanic
**Problem**: Weapons don't contribute to evasion. Parry ability is therefore broken/useless.
**Solution**:
- Reference Sil-Q source for the weapon evasion formula
- In Sil-Q, melee weapons provide evasion bonus based on weapon weight and melee skill. Make sure all weapon ports -> are accurate
- Implement: `weapon_evasion = weapon.pval * melee_skill / 10` or similar Sil-Q formula
- Parry ability should multiply this: `parry_bonus = weapon_evasion * (1 + evasion_skill / 5)`
- Display weapon evasion contribution in inventory tooltip
**Files**: `player.gd` (evasion calculation ~line 1299), `inventory_panel.gd`

<!-- //#### 1.3 Secret Doors — Fix Depth 1-2 Spawn
**Problem**: `mini(2, depth/3)` = 0 for depths 1-2. No secret doors on early floors.
**Solution**: Change formula to `maxi(1, mini(3, 1 + depth / 3))` — always at least 1 secret door per floor
- Bonus: Add a message when player finds one: "You discover a hidden passage!" in gold
- Add a Shift+S search animation/delay (0.5s) for tactile feedback
**Files**: `dungeon_generator.gd` (~line 573), `main.gd` (search action)/// commented out because i actually like this implmeentation :p -->

#### 1.4 Kill-Move Visual Bug Investigation
**Problem**: Player reports moving into killed monster's tile on same turn when attacking up/diagonally.
**Reality**: Code returns `false` after attack in `can_move_to()`. BUT — investigate:
- Does the monster's death free the tile, causing a SECOND movement input to process?
- Is there a race condition with input buffering?
- Does the visual sprite position update before the logic resolves?
- Test specifically: attack monster diagonally upward, kill it, observe if player position changes
**Action**: Run playtest bot with diagonal combat scenarios. If bug found, fix. If not reproducible, add input debounce safety.
**Files**: `player.gd` (~line 2274), `main.gd` (input handling)

---

### TIER 2: STEALTH OVERHAUL (Cycle 2)
*Stealth is a core playstyle. It must feel powerful and readable.*

#### 2.1 HUD Detection State — HIDDEN / ALERT / COMBAT
**Problem**: No visible indicator of player's detection state. Can't tell when stealthing works.
**Solution**: Add a prominent, always-visible status indicator in the form of an EYE to the HUD in between the HP and VOICE UI features:
- **HIDDEN** (Eye is closed) — No monsters have alertness > -5 within FOV
- **ALERT** (eye is halfway open) — At least one monster has alertness > -5 but < 5
- **COMBAT** (eye is open) — At least one monster has alertness >= 5 and is hunting
- Position: TNext to health orb. LARGE text, not subtle.
- Also show: Small stealth score number next to indicator (e.g., "HIDDEN [14]")
- Update every turn by scanning all monsters in FOV range
**Files**: `hud.gd`, `player.gd`, `monster.gd`

#### 2.2 Stealth Balance Pass
**Problem**: Maxed stealth Hobbit (6 DEX, 7 stealth, Disguise) getting detected by spiders on floor 1.
**Analysis needed**:
- Check spider perception values in monster.txt. If perception > 5, that's likely too high for a floor 1 mob.
- Current stealth score for this build: 7 (base) + STEALTH_MODE_BONUS (check value) + 2 (small stature) + 2 (disguise) = ~11-13
- Compare to Sil-Q detection formulas and adjust
**Solution**:
- Reduce early monster perception by ~30% (floors 1-5 monsters should have perception 1-4)
- Increase STEALTH_MODE_BONUS if it's less than +5
- Add distance scaling: monsters beyond 5 tiles should almost never detect a stealthed player
- Stealth-invested characters should feel POWERFUL at stealth. A maxed stealth build should be able to walk past most floor 1-5 monsters undetected.
- Assassin fantasy: Unwary monsters should die in one hit (backstab multiplier: 2x damage, or auto-crit)
- When detected, show message: "The [monster] notices you!" in bright yellow
- When entering stealth successfully: "You melt into the shadows." in dark purple
**Files**: `monster.gd` (detection formula ~line 257), `player.gd` (stealth score), `constants.gd` (STEALTH_MODE_BONUS)

#### 2.3 Stealth Across Full Game
**Verify**: Can a pure stealth build reach depth 15+ and win via Escape Victory?
- Stealth should scale with depth — player stealth investments should outpace monster perception growth
- Deep monsters should be HARDER to stealth past but not impossible for invested builds
- Consider: Stealth kill XP bonus (+25% for killing unwary monsters) to reward the playstyle
- Consider: "Shadow Walk" ability (stealth tree) — teleport to unwary monster's tile for guaranteed backstab

#### 2.4 LIGHTING ECOLOGY FUnctions and feels like ''breathing''
**Verify**: are we having a light ecology like sil-q C version of necromancer in the godot build?
- Some rooms feel overlit. it could just be upper floors.
- need to make sure the increasing danger of darkness is balanced with increasing accessibility of light radius via skills or items
- can add more mechanics or ideas into light ecology - this is a fun, differentiated and very tolkien concept!

---

### TIER 3: GAME BALANCE — MAKE IT EASIER & MORE FUN (Cycle 3)
*Target: 30% easier base game than Sil-Q. Floors 1-5 should feel approachable. First win at ~5 hours for decent player.*

#### 3.1 Early Game Difficulty Reduction (Floors 1-5)
**Changes**:
- **Starting XP**: Increase from 5000 to 7000 (lets players buy 2-3 early skills)
- **Floor 1-2 monster stats**: Cap monster melee_bonus at +2 for depth 1, +4 for depth 2
- **Guaranteed equipment**: Spawn 1 weapon + 1 armor piece per floor for depths 1-3
- **Starting food**: Ensure 3+ food items in starting inventory (prevent early starvation)
- **Trap damage on floor 1**: Reduce to 1d2 (from 1d4 + depth/3)
**Files**: `dungeon_generator.gd`, `player.gd`, `main.gd`, `constants.gd`

#### 3.2 Item Scarcity Fix
**Problem**: Not enough equipment by floor 3 vs Sil-Q experience.
**Solution**:
- investigate if this is true - if it is, balance to match sil-q experience. 
- Add guaranteed equipment drops: 1 weapon OR armor per floor (floors 1-10)
- Monster drops: 10% chance to drop an item on kill (currently 0% — monsters drop nothing!)
- Add item quality scaling: deeper floors spawn better base items
**Files**: `dungeon_generator.gd`, `monster.gd` (add death drop logic), `data_manager.gd`

#### 3.3 Ego/Magic Item System
**Problem**: No enchanted items exist. All items are base stats from object.txt. Feels flat.
**Solution**: Implement ego item generation:
- Weapon egos: "of Gondolin" (+1d4 vs orc/troll), "of Flame" (fire brand), "Blessed" (+2 attack), "Keen" (+1 crit)
- Armor egos: "of Resistance" (+1 protection die), "of Stealth" (+2 stealth), "of Speed" (+1 speed)
- Ring/amulet egos: Already have 15 rings/amulets — ensure they actually spawn
- Magic item chance: 15% of spawned equipment gets an ego prefix (scales with depth: +2% per depth)
- Cursed items: 5% chance, negative ego (-1 to stat), removable at forge
- Display: Ego items in blue text, cursed in red
- crosscheck this system with SMITHING. EGO/MAGIC RANDOM SPAWNS AND SMITHING MUST WORK TOGETHER - I.E., MUST FUNCTION TOGETHER. SMITHING MUST BE THE WAY TO GET THE BEST/MOST POWERFUL GEAR RELIABLy.
- no soft upgrade item system like sil-q. in sil-q you had all these different parts of a weapon/armor that could be improved. evasion. protection die. damage. atk. we need more of that in here so that as you go deeper you're getting empirically better gear, even if it isn't magic.
**Files**: `data_manager.gd` (new ego generation), `dungeon_generator.gd`, `item.gd`, `inventory_panel.gd`

#### 3.4 Monster Drop System
**Problem**: Monsters currently drop NOTHING on death. Zero loot. This removes a core roguelike dopamine loop.
**Solution**:
- Base drop chance: 5-10% for normal monsters, 50% for uniques/bosses, 100% for named bosses
- Drop table: weighted by monster depth/rarity
  - Common: food, herbs, potions
  - Uncommon: equipment, scrolls
  - Rare: ego items, rings, amulets
- Use monster's `DROP_30`, `DROP_60`, `DROP_90` flags from monster.txt (they exist but aren't processed!)
- XP bonus items: Some monsters drop "trophy" items worth extra XP
**Files**: `monster.gd` (death handler), `dungeon_generator.gd`, `data_manager.gd`

#### 3.5 Snowball Mechanics
**Problem**: Player can't tell they're getting stronger. No clear power curve.
**Solution**:
- **Level-up notification**: When player spends XP on a skill, show dramatic "SKILL UP!" floater
- **Kill streak bonus**: 3+ kills in a row grants temporary +1 attack (visible buff, 10 turns)
- **Equipment comparison**: Show green/red arrows when picking up items vs current equipment
- **XP milestone rewards**: At 1000, 3000, 6000, 10000 XP spent total, should we grant a free ability point ? or does this get TOO overpowered?
- **Power scaling feedback**: Show "Effective Power: X" in character sheet (composite of attack + evasion + abilities)
**Files**: `player.gd`, `hud.gd`, `inventory_panel.gd`, `floater_manager.gd`

---

### TIER 4: LORE SYSTEM REWORK — ACTIVE SONGS (Cycle 4)
*Bring back Sil-Q singing. Make Lore builds feel active and powerful.*

#### 4.1 Sustained Song System
**Design**: Port the Sil-Q singing mechanic with Necromancer flavor.
- **Songs are sustained abilities** that drain voice per turn while active
- Player can have ONE song active at a time (toggle on/off)
- Songs cost voice_drain per turn (varies by song power)
- Songs broadcast noise (stealth penalty while singing)
- Stopping a song is free action
- Starting a song costs 1 turn

**Song List** (replace or augment existing Lore abilities). . Lore needs update to design & balance. here are ideas:
1. **Chant of Silence** (Lore 3) — Reduce all monster perception by 3 within radius 5. Drain: 1/turn. Paradox: reduces noise but the chant itself makes some noise.
2. **Chant of Endurance** (Lore 5) — Regenerate 1 HP every 3 turns. Drain: 2/turn. This is like ''song of healing'' from Sil. If we have this we'd take healing out of herbcraft. 
3. **Chant of Mastery** (Lore 7) — Reduce all monster morale by 15 within radius 4. Drain: 2/turn.
4. **Chant of Battle** (Lore 9) — +2 attack, +1 damage die. Drain: 3/turn.
5. **Chant of the Valar** (Lore 12) — All nearby allies (if any) get +2 to all stats. Drain: 4/turn.
6. **Chant of Banishment** (Lore 15) — Undead within radius 3 take 1d4 damage per turn. Drain: 5/turn.
7. **Chant of Memory** Deep Memory (Lore 2) - map around you unveils - distance you can see is based on lore skill (look at sil-q for scaling here)

**Keep as instant-cast**: Word of Command, Word of Opening, Word of Shutting, Deadly Lore, Herbcraft (passive), Device Mastery (passive), 

**Voice pool**: Increase max_voice formula to support sustained drain. Current `20 * 1.2^Grace` is fine if Grace can reach 5-8.

**UI**: Show active song name below health orb with pulsing glow. Show voice drain rate.

**Files**: `ability_system.gd`, `player.gd`, `hud.gd`, `constants.gd`, `tome_panel.gd`

#### 4.2 Herbcraft Balance
**Problem**: 3 points into Lore for Herbcraft feels like mandatory must-have (OP).
**Solution**:
- Move Herbcraft to Lore 5 requirement (from 3) — makes it a meaningful investment
- Reduce Herbcraft bonus from 2x to 1.5x healing
- Add alternative healing: rest healing scales with Will skill (+1 HP per 2 Will per rest cycle)
- This way non-Lore builds have a viable healing path too
- HUMAN AUTHOR SAYS: I THINK THAT IF YOU USE CHANT OF ENDURANCE AS YOUR LORE BASED ACTIVE HEALING. YOU CAN HAVE HERBCRAFT BE A 3 POINT SKILL THAT SPEEDS UP YOUR HEALING --WHILE RESTED-- BY 50%. SO ESSENTIALLY THIS BECOMES A PASSIVE HEALING BUFF THAT REDUCES CONSUMPTION OF FOOD / LIGHT / DECREASES DANGER OF HEALING PASSIVELY. while you keep rest of hercraft components. i like that!
- this is VERY UNRESOLVED. YOU NEED TO THEORYCRAFT AND GO FOR MAX FUN. I THINK MAYBE MOVING THIS PASSIVE HEAL REST BOOST TO WILL MAKES SENSE - MAYBE EVEN HUNTING - IM NOT SURE. COME UP WITH SOMETHING DELIGHTFUL AS A SOLUTION!!! THINK ABOUT THIS FROM LOTR. ELROND SINGS TO HEAL - LEVEL 5 LORE. ARAGORN HAS HERBCRAFT. LEVEL 2 LORE. NOT AS GOOD !!!! SO YEAH THINK ON IT
**Files**: `ability_system.gd`, `consumable_system.gd`, `player.gd`

---

### TIER 5: CUSTOM TOLKIEN BOSSES (Cycle 5)
*1 boss every 3 floors. Each boss themed to their dungeon layer.*

#### 5.1 Boss Design & Implementation
**Boss Roster** (7 custom bosses, one per layer transition):

| Floor | Boss Name | Layer | Mechanics |
|-------|-----------|-------|-----------|
| 3 | **Shelob's Daughter** | Outer Pits | Spider queen. Spawns 2 spiderlings per turn. Web terrain AOE. Poison bite 2d6. Weak to fire (great, but we have no fire skills/abilities/droppables at this point so the vuln doesn't matter. design a better vuln or introduce fire somehwere.) |
| 6 | **Bolg the Orc-Captain** | Lower Halls | Armored orc. Rallies nearby orcs (+morale). Shield bash stun. Drops a guaranteed ego weapon. |
| 9 | **The Wight-Lord of Rhudaur** | Dark Halls | Undead wraith. Darkness aura (FOV -2). Life drain attack. Cold damage AOE. Immune to poison/fear. |
| 12 | **Khamul the Shadow** | Necropolis | Nazgul lieutenant. Fear aura (Will save or flee). Morgul blade (permanent -1 max HP). Teleports when below 30% HP. |
| 15 | **Thuringwethil** | Pits of Despair | Vampire bat form. Flight (ignores terrain). Blood drain heals her. Shriek stun AOE. Transforms between bat and humanoid. |
| 18 | **The Mouth of Sauron** | Inner Sanctum | Dark sorcerer. Casts all spell types. Summons 1-2 elites per 5 turns. Will-based attacks. Drops Rod of Istari piece. |
| 20 | **Sauron (The Necromancer)** | Throne Room | Final boss. Already exists. Verify he works correctly. |

THIS IS A GOOD START BUT IT DOESN'T CREATE RNG VARIETY. WE NEED 3 POTENTIAL BOSSES PER LAYER TRANSITION, OUTSIDE OF SAURON. HE'S THE BOSS ONT HE SAURON LAYER. hehe

**Implementation**:
- Add boss monster definitions to `monster.txt` (IDs 88-94)
- Add boss AI behaviors to `monster.gd` (special ability methods per boss)
- Modify `dungeon_generator.gd`: boss spawns at depths 3,6,9,12,15,18 in dedicated boss room
- Boss rooms: Larger than normal (12x12 min), single entrance, themed terrain, guaranteed lore object
- Boss death: Guaranteed quality item drop + XP bonus (3x normal) + message log fanfare
- Boss health bars: Special large health bar at top of screen (like a souls-like boss bar)

**Files**: `monster.txt`, `monster.gd`, `dungeon_generator.gd`, `data_manager.gd`, `hud.gd`

---

### TIER 6: PROCEDURAL DESCRIPTION DEPTH (Cycle 6)
*10x the variety. Tie descriptions to game state. Make examination a joy.*

#### 6.1 Expanded Description Templates
**Current**: ~190 templates across 17 creature types + 27 terrain.
**Target**: 500+ templates with state-aware variations.

**Enhancements**:
- **Health-aware descriptions**: "The orc bleeds from several wounds" vs "The orc looks healthy and alert"
- **Morale-aware**: "Its eyes dart nervously" (fleeing) vs "It snarls with confidence" (aggressive)
- **Status-effect descriptions**: "Flames lick its body" (burning), "It stumbles drunkenly" (confused)
- **Equipment-aware**: "It wields a crude iron blade" vs "Its claws drip with venom"
- **Kill-history aware**: "You've slain 5 of these before" → "You know their weaknesses well"
- **Layer-themed**: Same monster type described differently per dungeon layer
  - Spider in Outer Pits: "A bloated Mirkwood spider, its web glistening with morning dew"
  - Spider in Necropolis: "A skeletal spider, its carapace fused with bone fragments"
- **Character creation descriptions**: 50+ backstory fragments per race/house combination
  - Tie backstory to starting stats: High STR = "You were known for your strength in the forge"
  - Tie to trait chosen: "Your keen eyes served you well as a scout" (for perception trait)
- **Death descriptions**: Layer-themed death messages
  - Outer Pits: "You fall among the roots of Mirkwood, never to rise again."
  - Necropolis: "Your bones join the countless dead of Dol Guldur."
  - Throne Room: "Sauron's laughter echoes as darkness claims you."

**Files**: `description_generator.gd`, `monster_memory.gd`, `character_creation.gd`, `death_screen.gd`

#### 6.2 Terrain Flavor Expansion
- Every tile type gets 3-5 examination variants (currently 1 each)
- Depth-scaled descriptions: Same tile type reads differently at depth 1 vs depth 15
- Interactive descriptions for special terrain: forges, lore objects, stairs
- "You notice..." discovery messages for secret rooms, hidden treasures

---

### TIER 7: MAP GENERATION ENRICHMENT (Cycle 7)
*Make each layer feel like a distinct place in Dol Guldur.*

#### 7.1 Layer-Specific Room Templates
**Current**: Same room shapes across all layers with different decorators.
**Improvement**:
- **Outer Pits**: Natural cave shapes (cellular automata), tree root obstacles, clearings
- **Lower Halls**: Rectangular military architecture, barracks rows, armory vaults
- **Dark Halls**: Winding corridors, ritual circles, trapped hallways
- **Necropolis**: Crypts with alcoves, bone-filled ossuaries, sarcophagus rooms
- **Pits of Despair**: Irregular chasms, bridge-connected platforms, vertical shafts
- **Inner Sanctum**: Grand chambers, throne-like spaces, lava-bordered rooms
- **Throne Room**: Already has special generation

**Implementation**: Add `_generate_layer_rooms()` that selects room generation algorithm based on layer.

#### 7.2 Environmental Storytelling
- **Readable objects**: Scattered notes, carvings, graffiti that hint at lore. create 300 readable snippets with procedural generation.
  - "A crude orc marking: three slashes. A warning."
  - "Elvish script, barely legible: 'Turn back, mortal.'"
- **Visual set pieces**: Pre-built template vignettes (torture room, abandoned camp, shrine)
- **Progressive destruction**: Deeper layers show more decay and corruption
- **Sound-based atmosphere**: Layer-specific ambient descriptions in message log
  - Outer Pits: "You hear rustling in the undergrowth."
  - Necropolis: "A cold wind moans through empty corridors."

**Files**: `dungeon_generator.gd`, `layer_config.gd`, `level.gd`

---

### TIER 8: VICTORY PATH SIMULATION & OVERALL BALANCE (Cycle 8)
*Mathematically verify the game is winnable, then tune.*

#### 8.1 Victory Path Analysis
Run mathematical simulations (can be pseudocode/spreadsheet logic in a subagent):

**Build Archetypes to Verify**:
1. **Melee Fighter** (STR/Melee focus): Can they outdamage monsters through to depth 15+?
2. **Stealth Assassin** (DEX/Stealth focus): Can they sneak to depth 15 and escape?
3. **Lore Scholar** (GRA/Lore focus): Can sustained songs carry them to victory?
4. **Balanced Explorer** (even stats): Is generalist viable?
5. **Smithing Specialist** (GRA/Smithing): Can forged equipment carry them? (THIS IS A PROBABLY NOT, SO THINK ABOUT IT)

**For each build, calculate**:
- Expected XP per floor (kills + lore objects) -> do we need to make more XP flow for seeing monsters
- Expected skill/ability purchases by floor 5, 10, 15, 20
- Expected equipment quality by floor 5, 10, 15
- Expected combat outcome vs average monster per floor
- Expected combat outcome vs boss per floor
- Estimated death rate per floor

**Output**: A balance report with specific recommended adjustments.

**Files**: `character_creation.gd`, `game_manager.gd`, `constants.gd`, all combat/spawning files

---

## Testing Protocol (Run After EVERY Stream)

```bash
# Unit + Integration tests
godot --path ~/dev/active/games/necromancer-godot --headless --script res://test_runner.gd

# Bot playtest (10-turn survival)
godot --path ~/dev/active/games/necromancer-godot --headless --script res://test_runner.gd -- --bot-only

# Quick crash check
godot --path ~/dev/active/games/necromancer-godot --headless --quit-after 3
```

**New tests to write** for each tier:
- Tier 1: test_smithing_material_spawn, test_weapon_evasion_bonus, test_secret_doors_depth_1
- Tier 2: test_stealth_detection_formula, test_stealth_mode_bonus
- Tier 3: test_monster_drops, test_ego_item_generation, test_guaranteed_equipment_spawn
- Tier 4: test_sustained_song_drain, test_song_toggle, test_herbcraft_rebalance
- Tier 5: test_boss_spawn_every_3_floors, test_boss_special_abilities
- Tier 8: test_difficulty_mode_modifiers

bash
  # Full suite: unit + gameplay + bot (319 tests, ~21K assertions)
  godot --path ~/dev/active/games/necromancer-godot --headless --script res://test_runner.gd

  # Unit + integration only (fast, ~10s)
  godot --path ~/dev/active/games/necromancer-godot --headless --script res://test_runner.gd -- --unit-only

  # Gameplay scenario tests only (~80s, generates dungeons)
  godot --path ~/dev/active/games/necromancer-godot --headless --script res://test_runner.gd -- --gameplay-only

  # Fuzz bot: 500+ random actions, finds crashes, writes report to user://fuzz_crash_report.txt
  godot --path ~/dev/active/games/necromancer-godot --headless --script res://test_runner.gd -- --fuzz

  # Survival bot: intelligent 20-floor auto-play with per-floor telemetry
  godot --path ~/dev/active/games/necromancer-godot --headless --script res://test_runner.gd -- --survival

  # Legacy bot playtest (10-turn survival smoke test)
  godot --path ~/dev/active/games/necromancer-godot --headless --script res://test_runner.gd -- --bot-only

  After each stream: Run --unit-only (fast gate). Before final commit: run full suite.
  After risky changes (combat, inventory, dungeon gen): also run --fuzz for crash detection.

## Commit Protocol
- One commit per stream/tier completion
- Format: `Session S Stream [X]: [Theme] — [1-line summary]`
- Run tests BEFORE committing. Never commit failing tests.

## Reference Files (READ-ONLY)
- Sil-Q C source: `~/dev/active/games/necromancer-master/src/`
- Sil-Q data files: `~/dev/active/games/necromancer-master/lib/edit/`
- Active Godot project: `~/dev/active/games/necromancer-godot/`

## Key Constraints
- Engine: Godot 4.6, GDScript only
- Explicit typing required (`var x: int = ...`)
- macOS keycode fallback for symbol keys
- `is_instance_valid()` before `is` operator on freed objects
- `.duplicate(true)` for nested arrays in save/load
- **Tileset changes**: If new sprites are needed (bosses, ego item icons, new terrain), invoke `/tileset-gen` skill. NEVER manually edit tileset PNGs or .tres files. The skill handles DALL-E generation, BG removal, HSV correction, and tileset integration following established protocols.
- NEVER use "pixel art" in any DALL-E prompts — use "painting", "illustration", "dark fantasy illustration"
- After any tileset modification, note: "Clear .godot/imported/ cache to see changes"

## Success Criteria
After all tiers complete:
1. All existing tests pass (319+)
2. New tests pass (30+ new tests across tiers)
3. Bot playtest survives 10 turns without crash
4. Smithing works end-to-end
5. Stealth build can reach depth 10 in bot simulation
6. At least 1 ego item spawns per 3 floors
7. Bosses spawn at depths 3,6,9,12,15,18
8. Active songs toggle on/off correctly
