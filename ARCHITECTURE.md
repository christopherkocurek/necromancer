# The Necromancer -- Godot Architecture

```
+==========================================================================================+
|                        THE NECROMANCER -- GODOT ARCHITECTURE                              |
+==========================================================================================+

+------------------------------------------------------------------------------------------+
|                                    AUTOLOADS (Singletons)                                |
+----+------------------+------------------+------------------+------------------+----------+
|    |   GameManager    |    EventBus      |   DataManager    |    TileMapper    |          |
|    |                  |    (Signals)     |                  |                  |          |
|    | . current_state  |                  | . monsters{}     | . tile -> atlas  |          |
|    | . current_depth  | entity_damaged   | . items{}        | . light/dark     |          |
|    | . turn_count     | entity_died      | . artifacts{}    |   variants       |          |
|    | . difficulty     | entity_moved     | . abilities{}    +------------------+          |
|    | . player ref     | status_applied   | . races{}        |  ThemeColors     |          |
|    | . level ref      | level_entered    | . vaults[]       | . MSG_INFO       |          |
|    | . zoom_levels    | ability_used     | . houses{}       | . COMBAT_HIT     |          |
|    | . identified{}   | game_started     |                  | . HEALTH_HIGH    |          |
|    +------------------+ round_completed  +------------------+------------------+          |
|    |  AudioManager    | npc_interacted   | LayerConfig      |AccessibilityMgr  |          |
|    | . sfx_play()     | item_dropped     | . 7 layer defs   | . god_mode       |          |
|    | . music_play()   | game_paused      | . depth->layer   | . colorblind     |          |
|    +------------------+------------------+ . fov_radius     | . font_scale     |          |
|    |  PanelTransition | TooltipManager   | . room params    +------------------+          |
|    |  TutorialManager | HelpOverlay      +------------------+                             |
+------------------------------------------------------------------------------------------+
```

## Autoload Dependency Graph

All autoloads are registered in `project.godot` under `[autoload]`. Load order matters -- earlier autoloads are available to later ones.

```
LayerConfig          (no dependencies)
GameManager          (no dependencies)
EventBus             (no dependencies)
DataManager          (no dependencies -- loads data files in _ready)
TileMapper           (reads DataManager for terrain mapping)
ThemeColors          (no dependencies -- pure color constants)
AccessibilityManager (no dependencies -- reads user://settings.cfg)
PanelTransition      (no dependencies)
TooltipManager       (no dependencies)
TutorialManager      (reads GameManager for state checks)
HelpOverlay          (no dependencies)
AudioManager         (no dependencies)
```

### Autoload Roles

| Autoload | File | Purpose |
|----------|------|---------|
| `LayerConfig` | `scripts/systems/layer_config.gd` | Dungeon layer definitions (7 tiers), depth-to-layer mapping, room parameters, visual tinting, ambient messages |
| `GameManager` | `scripts/core/game_manager.gd` | Central game state (depth, turn count, difficulty), zoom, identification system, artifact tracking, difficulty modifiers |
| `EventBus` | `scripts/core/event_bus.gd` | Global signal hub decoupling all systems. 20+ signals for damage, death, movement, status, UI, game state |
| `DataManager` | `scripts/core/data_manager.gd` | Loads and indexes all Sil-Q data files at startup. Provides lookup by name, index, tval:sval, depth-weighted random |
| `TileMapper` | `scripts/core/tile_mapper.gd` | Maps tile enum values to DCSS tileset atlas coordinates. Handles light/dark variants, layer-specific terrain |
| `ThemeColors` | `scripts/core/theme_colors.gd` | Color constants for UI, combat messages, status effects, skill categories. Single source of truth for all colors |
| `AccessibilityManager` | `scripts/systems/accessibility_manager.gd` | Persisted settings: god mode, colorblind mode, font scale, animation speed. Death-count scaling for god mode |
| `PanelTransition` | `scripts/ui/panel_transition.gd` | Shared animation logic for UI panel open/close transitions |
| `TooltipManager` | `scripts/ui/tooltip_manager.gd` | Global tooltip display for hover-over information |
| `TutorialManager` | `scripts/ui/tutorial_manager.gd` | Context-sensitive tutorial hints for new players |
| `HelpOverlay` | `scripts/ui/help_overlay.gd` | Full keybinding reference overlay (? key) |
| `AudioManager` | `scripts/core/audio_manager.gd` | Sound effect and music playback management |

---

## Game State Machine

```
                              +-------------+
                              |  MAIN_MENU  |
                              +------+------+
                                     | start_new_game()
                                     v
     +-----------+  game_over() +---------+  change_state()  +-----------+
     | GAME_OVER |<-------------|  PLAYING |<--------------->|  PAUSED   |
     |           |              +----+----+                  |           |
     | . victory |                   |                       | . tree    |
     | . defeat  |                   |                       |   paused  |
     +-----------+                   | open UI panel         +-----------+
                              +------+------+
                              |  INVENTORY  |
                              |  DIALOGUE   |
                              +-------------+
```

The main scene (`scripts/main.gd`) manages its own `GameState` enum (CHARACTER_CREATION, PLAYING, PAUSED, GAME_OVER) separately from GameManager's state. The main scene coordinates UI panel visibility and input routing.

---

## Turn State Machine

```
    +----------------------------------------------------------------+
    |                                                                |
    |    +--------------+         +----------------+                 |
    |    | PLAYER_INPUT |-------->| PLAYER_ACTING  |                 |
    |    |              | action  |                |                 |
    |    | . awaiting   | taken   | . processing   |                 |
    |    |   input      |         |   player move  |                 |
    |    +--------------+         +-------+--------+                 |
    |           ^                         |                          |
    |           |                         v                          |
    |           |                   +-----------+    +-------------+ |
    |           |                   | ANIMATING |    | ENEMY_TURN  | |
    |           |                   |           |--->|             | |
    |           |                   | . 0.15s   |    | . iterate   | |
    |           |                   |   delay   |    |   monsters  | |
    |           |                   +-----------+    +------+------+ |
    |           |                                           |        |
    |           +-------------------------------------------+        |
    |                          _end_round()                          |
    |                          round_completed signal                |
    +----------------------------------------------------------------+
```

The `TurnSystem` (`scripts/systems/turn_system.gd`) drives the game loop:
1. Player inputs an action (move, attack, use item, ability)
2. Player action is processed, energy consumed
3. Brief animation delay (0.15s) for visual feedback
4. All monsters take their turns in energy order
5. Round completes: cooldowns tick, status effects tick, voice regenerates
6. Return to player input

---

## Monster AI State Machine

```
         can't see player             +------------+          can't see player
        +--------------------------->|    IDLE    |<------------------------+
        |         10% chance          +-----+------+         30% chance     |
        |                                   | 10% chance                    |
        |                                   v                               |
   +----+-----+                      +------------+                    +----+-----+
   | HUNTING  |<---------------------|  WANDERING |-------------------->| FLEEING  |
   |          |    see player &      +------------+    see player &    |          |
   | . path   |    health > 20%            ^           health < 20%    | . run    |
   |   toward |                            |                           |   away   |
   |   player |                            |                           |          |
   +----+-----+                            |                           +----+-----+
        |                                  |                                |
        |         see player &             |         far from player        |
        +----------------------------------+--------------------------------+
                  health < 20%                    (2x perception range)
```

Monsters use an energy system matching the player. Speed values (0-7) determine energy gain per tick via `Constants.ENERGY_TABLE`. A speed-2 monster acts once per player turn; speed-3 acts 1.25x as often.

### Morale System

Morale determines combat stance:
- `> 200`: Aggressive (charges, uses abilities freely)
- `> 0`: Confident (standard AI)
- `<= 0`: Fleeing (moves away from player)

Morale is affected by: taking damage, allies dying, player Majesty ability, Word of Command fear, horn effects. Fleeing monsters rally (gain +60 temporary morale) when they stop running.

---

## Sustained Song System

Added in Ralph Loop Tier 4. Songs are a toggle ability type that drain voice charges per turn while active.

```
  Player presses V -> selects Song of Freedom [SINGING]
       |
       v
  AbilitySystem._toggle_song(SONG_OF_FREEDOM)
       |
       +-> Stop current song (if any)
       +-> Set player.active_song_id = 155
       +-> Set player.song_voice_drain = 1
       |
  Each round (via _on_round_completed):
       |
       v
  AbilitySystem._tick_active_song()
       |
       +-> Drain player.voice_charges by song_voice_drain
       +-> If voice < cost: song ends ("Your voice falters...")
       |
  Combat/stealth systems query bonuses:
       |
       +-> get_song_evasion_bonus()  -> +3 if Freedom active
       +-> get_song_stealth_bonus()  -> +5 if Trees active
       +-> get_song_melee_bonus()    -> +2 if Aule active
```

Only one song can be active at a time. Toggling the same song off, or starting a different song, stops the current one. Voice regeneration continues while singing but is effectively reduced by the per-turn drain.

### Song Definitions

| Song | Ability ID | Voice/Turn | Effect |
|------|-----------|------------|--------|
| Song of Freedom | 155 | 1 | +3 evasion |
| Song of the Trees | 156 | 1 | +5 stealth |
| Song of Aule | 157 | 2 | +2 melee, +1 smithing |

---

## Boss System

Added in Ralph Loop Tier 5. Bosses are enhanced monsters that spawn at layer transition depths.

```
DungeonGenerator.generate(level, depth)
    |
    +-> if depth in [3, 6, 9, 12, 15, 18, 20]:
            _add_boss_room(depth)
                |
                +-> Select random room (not first/last)
                +-> Pick boss from BOSS_POOL[depth] (random of 3)
                +-> Instantiate base monster for depth+3
                +-> Override: name = boss_info.title
                +->           HP *= boss_info.hp_mult
                +->           XP *= boss_info.xp_mult
                +->           is_unique = true
```

The `BOSS_POOL` dictionary in `dungeon_generator.gd` defines 3 named Tolkien bosses per transition depth (e.g., depth 3 might have "Bolg the Taskmaster", "Mauhur the Relentless", or "Ufthak the Defiler"). A random boss is selected each run for replayability. Depth 20 has the final boss pool.

---

## Ego Enchantment System

Added in Ralph Loop Tier 3. Ego enchantments are random magical properties applied to dropped weapons and armor.

```
Monster dies -> drop calculation
    |
    +-> Depth-based chance of ego enchant
    +-> Roll ego type from weighted table:
         Flaming   - fire damage bonus
         Frost     - cold damage bonus
         Venom     - poison on hit
         Sharpness - improved crit chance
         Warding   - protection bonus
         Speed     - reduced action cost
    +-> Apply ego prefix/suffix to item name
    +-> Modify item stats based on ego type
```

Ego items are identified on pickup (the enchantment is visible). They appear in the item name as a prefix (e.g., "Flaming Longsword" or "Sword of Warding").

---

## Difficulty Mode Architecture

Added in Ralph Loop Tier 8. Four difficulty levels with modifier tables.

```
GameManager.DIFFICULTY_MODIFIERS = {
    EASY:    {xp: 1.5x, dmg: 0.75x, items: 1.25x, perception: +0, traps: revealed}
    NORMAL:  {xp: 1.0x, dmg: 1.0x, items: 1.0x, perception: +0, traps: hidden}
    HARD:    {xp: 1.0x, dmg: 1.0x, items: 0.8x, perception: +3, traps: hidden}
    IRONMAN: {xp: 1.0x, dmg: 1.0x, items: 0.8x, perception: +3, no rest healing}
}
```

Difficulty is selected during character creation and stored in `GameManager.current_difficulty`. Systems query modifier values via helper methods:
- `get_xp_multiplier()` -- applied when granting XP
- `get_monster_damage_multiplier()` -- applied in `take_damage()`
- `get_item_spawn_multiplier()` -- applied in dungeon generator
- `get_monster_perception_bonus()` -- added to stealth checks
- `should_reveal_traps()` -- traps visible on Easy
- `allows_rest_healing()` -- disabled on Ironman

---

## Horn and Flute System

Horns (tval 66) are directional consumable items that produce cone or area effects.

```
Player presses P -> _open_item_selection(TVAL_HORN, ...)
    |
    v
Select horn from inventory popup
    |
    v
ConsumableSystem.use_item() -> detects TVAL_HORN
    |
    v
ConsumableSystem sets pending horn state
    |
    v
Main._unhandled_input() intercepts direction key
    |
    v
ConsumableSystem.complete_horn_use(direction)
    |
    v
HornSystem.use_horn(player, item, direction)
    |
    +-> Match sval:
         0: Horn of Terror    -> 90-degree fear cone
         1: Horn of Thunder   -> 10d4 damage cone + stun
         2: Horn of Force     -> Knockback cone
         3: Horn of Blasting  -> Ranged line destruction
         4: Horn of Challenge -> Self-targeted battle fury buff
         5: Fairy Flute       -> Area mist (obscures vision)
```

Horns 0-3 require directional targeting (the player chooses which way to aim the cone). Horn of Challenge and Fairy Flute are self/area targeted and skip the direction prompt.

All horns generate noise that raises floor alertness, with louder horns (Thunder, Blasting) generating more noise.

---

## Herb Ecology

Herbs are food items (tval 80) with effects that range from healing to stat restoration. They are part of the consumable item system and interact with several other systems.

```
Player presses , -> _open_item_selection(80, "eat", ...)
    |
    v
ConsumableSystem.eat_food(player, item)
    |
    +-> Match sval:
         Lembas          -> Full heal + cure poison
         Athelas         -> Cure all status effects
         Pipe-weed       -> Temporary Grace boost
         Thorny Vine     -> Temporary protection
         Phosphorescent  -> +1 light radius (status effect)
         Poisonous Herb  -> Apply poison to self
         Various healing -> Scaled HP restore
```

The Herbcraft passive ability (Lore 145) doubles healing from all herb effects. Herb identification follows the standard item identification system -- unidentified herbs have randomized flavor names ("a pungent green herb") until used or identified via Lore skill.

---

## Description Generator

Added in Ralph Loop Tier 6. A static utility class that produces procedural text descriptions.

```
DescriptionGenerator (RefCounted, static methods)
    |
    +-> generate_monster_description(data, tier)
    |       Maps display_char to creature type, then generates
    |       physical description from color, size, and flags.
    |       "o" -> _describe_orc()
    |       "T" -> _describe_troll()
    |       "W" -> _describe_wraith()
    |       ... 17 creature type handlers
    |
    +-> generate_contextual_description(data, tier, context)
    |       Adds health, morale, and layer-aware modifiers:
    |       "It looks badly wounded" (health < 25%)
    |       "It seems ready to flee" (stance == FLEEING)
    |
    +-> generate_health_description(health_pct)
    +-> generate_terrain_description(tile, depth)
    +-> generate_ego_description(ego_type)
```

Used by:
- **MonsterMemory** -- displays descriptions in the bestiary at appropriate knowledge tiers
- **LookPanel** -- shows descriptions when examining tiles/monsters with X key
- **DeathScreen** -- provides flavor text for the killer

---

## Smithing System Architecture

```
SmithingSystem (RefCounted)
    |
    +-> 5 Recipe Types:
    |     CREATE_WEAPON  (Mithril + Weaponsmith ability)
    |     CREATE_ARMOR   (Mithril + Armoursmith ability)
    |     CREATE_JEWELRY (Mithril + Jeweller ability)
    |     REFORGE        (2 Broken Glowing items + Reforge ability)
    |     RECLAIM        (2 Broken Strange items + Reclaim ability)
    |
    +-> Success Formula: min(smithing_skill * 8, 95)
    |
    +-> SmithingPanel (UI)
    |     Lists available recipes based on:
    |       - Player's smithing skill level
    |       - Player's learned smithing abilities
    |       - Materials in inventory
    |       - Standing on a forge tile
    |
    +-> Forge Placement:
          Forges spawn every 2 floors up to depth 10
          Forge terrain IDs: 64-79 from terrain.txt
```

---

## Scene Tree Structure

```
Main (Node2D)
+-- LevelContainer (Node2D)
|   +-- Level (Node2D) <--- instantiated at runtime
|       +-- TerrainLayer (TileMapLayer)
|       +-- Items (Node2D)
|       +-- Entities (Node2D)
|       |   +-- Player (Node2D)
|       |   |   +-- Sprite2D
|       |   |   +-- Camera2D
|       |   +-- Monster (Node2D)
|       |   |   +-- Sprite2D
|       |   |   +-- EntityHealthBar
|       |   +-- ... more monsters
|       +-- Effects (Node2D) <--- floater container
|           +-- DamageFloater
|           +-- ... more floaters
+-- TurnSystem (Node)
+-- FloaterManager (Node)
+-- HUD (CanvasLayer)
|   +-- TopPanel
|   |   +-- HealthBar, VoiceBar, XPBar
|   |   +-- DepthLabel, TurnLabel
|   |   +-- StatusContainer (status effect icons)
|   |   +-- DetectionEye (stealth indicator)
|   |   +-- SongIndicator
|   |   +-- HotkeyBar (ability hotkeys 1-4)
|   +-- BottomPanel
|   |   +-- MessageLog (RichTextLabel)
|   +-- Minimap
+-- UILayer (CanvasLayer, layer 10)
    +-- InventoryPanel
    +-- TomePanel
    +-- DeathScreen
    +-- LookPanel
    +-- TargetPanel
    +-- DialoguePanel
    +-- SmithingPanel
    +-- BestiaryPanel
    +-- SettingsPanel
    +-- VoiceMenu (PopupMenu)
    +-- ItemMenu (PopupMenu)
    +-- TransitionOverlay (ColorRect)
```

---

## Data Flow

```
+-----------------------------------------------------------------------+
|                          DATA FILES (res://data/)                      |
+-----------------------------------------------------------------------+
| monster.txt  object.txt  artefact.txt  ability.txt  race.txt          |
| house.txt    terrain.txt  vault.txt    trait.txt    flavor.txt         |
| names.txt    history.txt  epitaphs.txt  special.txt  limits.txt       |
+-----------------------------------+-----------------------------------+
                                    | _ready() -> load_all_data()
                                    v
+-----------------------------------------------------------------------+
|                          DataManager (Autoload)                       |
+-----------------------------------------------------------------------+
| monsters: Dictionary    --> get_random_monster_for_depth(depth)        |
| items: Dictionary       --> get_random_item_for_depth(depth)          |
| artifacts: Dictionary   --> get_artifact(name)                        |
| abilities: Dictionary   --> get_ability(name)                         |
| races: Dictionary       --> get_race(name)                            |
| houses: Dictionary      --> get_house(name)                           |
| vaults: Array           --> vaults[i]                                 |
| traits: Dictionary      --> get_trait(name)                           |
+-----------------------------------+-----------------------------------+
                                    |
                                    v
+-----------------------------------------------------------------------+
|                         DungeonGenerator                              |
+-----------------------------------------------------------------------+
| generate(level, depth)                                                |
|     +-> _generate_rooms()      --> carve floor tiles (6 room types)   |
|     +-> _connect_rooms()       --> carve corridors (MST + extras)     |
|     +-> _place_stairs(depth)   --> stairs up/down                     |
|     +-> _add_features(depth)   --> doors, rubble, forges, traps       |
|     +-> _add_decorations()     --> inscriptions, bone piles, items    |
|     +-> _spawn_monsters(depth) --> DataManager themed + random        |
|     +-> _spawn_items(depth)    --> DataManager depth-weighted         |
|     +-> _add_boss_room(depth)  --> boss at layer transitions          |
+-----------------------------------------------------------------------+
```

### Data File Format Reference

All data files use the Sil-Q angband format:

```
N:<index>:<name>
G:<display_char>:<color>
I:<tval>:<sval>:<pval>
W:<depth>:<rarity>:<weight>:<cost>
A:<allocation_entries>
P:<attack_bonus>:<damage_dice>:<evasion_bonus>:<protection_dice>
F:<flag1> | <flag2> | <flag3>
D:<description text>
E:<starting_equipment_entries>  (race.txt only)
```

| File | Record Type | Count | Key Fields |
|------|-------------|-------|------------|
| `monster.txt` | MonsterData | 77 | HP, speed, attack dice, spells, flags |
| `object.txt` | ItemData | 100+ | tval, sval, damage/protection dice, flags |
| `artefact.txt` | ArtifactData | 30+ | Base item + unique name + special flags |
| `ability.txt` | AbilityData | 93 | Skill, index, XP cost, prerequisites |
| `race.txt` | RaceData | 4 | Stat modifiers, starting equipment, history |
| `house.txt` | HouseData | 6 | Skill affinity, stat modifiers |
| `terrain.txt` | TerrainData | 87 | Passability, visibility, tile mapping |
| `vault.txt` | VaultData | 96 | Grid templates with symbol mapping |
| `trait.txt` | TraitData | 10 | Gameplay effect, description |
| `flavor.txt` | FlavorData | -- | Randomized names for unidentified items |

---

## Combat Resolution Flow

```
Player.attack_entity(target)
        |
        v
+-------------------+
| CALCULATE ATTACK  |
| hit_roll = 1d20   |
|   + melee_bonus   |
|   + dex/2         |
|   + ability mods  |
|   + song bonus    |
|   + stealth bonus |
|   + light penalty |
+--------+----------+
         |
         v
+-------------------+     NO      +-------------------+
| hit_roll >=       |------------>| EventBus.attack_  |
| target_evasion?   |             | missed.emit()     |
+---------+---------+             +-------------------+
          | YES
          v
+-------------------+
| ROLL DAMAGE       |
| damage = roll_dice|
|   (weapon_dice)   |
|   + strength/2    |
|   + ego bonus     |
+---------+---------+
          |
          v
+-------------------+     YES     +-------------------+
| Critical hit?     |------------>| damage *= 2       |
| (weight-based)    |             | Check Deadly Lore |
+---------+---------+             +---------+---------+
          |                                 |
          +---------------------------------+
          |
          v
+---------+---------+
| target.take_dmg() |
|   - protection    |
|   - difficulty mod|
+-------------------+
```

---

## Testing Infrastructure

```
tests/
+-- unit/                          # Isolated function-level tests
|   +-- test_combat.gd             # Attack rolls, damage, crits
|   +-- test_fov.gd                # FOV raycasting, visibility
|   +-- test_energy_system.gd      # Speed, energy gain, action costs
|   +-- test_status_effects_formulas.gd  # DOT, decay, resistance
|   +-- test_monster_ai.gd         # AI state transitions, pathfinding
|   +-- test_player_skills.gd      # Skill XP, ability learning
|   +-- test_abilities.gd          # Ability activation, cooldowns
|   +-- test_save_load.gd          # Serialization roundtrips
|
+-- gameplay/                      # Multi-system scenario tests
|   +-- test_combat_flow.gd        # Full combat encounters
|   +-- test_abilities_and_status.gd # Ability + status interaction
|   +-- test_inventory_flow.gd     # Pickup, equip, use, drop
|   +-- test_dungeon_generation.gd # Room placement, connectivity
|   +-- test_level_transitions.gd  # Stair descent/ascent
|   +-- test_save_load_roundtrip.gd # Full game state persistence
|
+-- integration/                   # Cross-system integration
|   +-- test_turn_flow.gd          # Full turn cycle with all systems
|
+-- bot/                           # Automated playtest bots
    +-- fuzz_bot.gd                # Random action crash finder (500+ turns)
    +-- survival_bot.gd            # Intelligent 20-floor auto-play
    +-- playtest_bot.gd            # Configurable archetype testing
    +-- archetype_configs.gd       # Bot playstyle configurations
```

Tests use the [GUT](https://github.com/bitwes/Gut) framework (Godot Unit Testing). Current status: 125/130 passing, 684 assertions, 5 pending baseline tests.

Run tests from the command line:
```bash
godot --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit
```

---

## Entity Hierarchy

```
Entity (entity.gd) -- base class
    |
    +-- Player (player.gd)
    |     . grid_position, stats (STR/DEX/CON/GRA)
    |     . equipment{}, inventory[]
    |     . skills{}, learned_abilities{}
    |     . stealth_mode, active_song_id
    |     . run_stats (RunStats)
    |     . ability_hotkeys[4]
    |
    +-- Monster (monster.gd)
    |     . monster_data (from DataManager)
    |     . ai_state (IDLE/WANDERING/HUNTING/FLEEING)
    |     . alertness, morale, perception
    |     . is_sleeping, is_unique
    |     . status_effects (StatusEffects)
    |
    +-- Item (item.gd)
    |     . item_data or artifact_data
    |     . grid_position (when on ground)
    |
    +-- NPC (npc.gd)
          +-- ThrainNPC (thrain_npc.gd)
                . quest dialogue, Ring of Thrain quest
```

---

## Key Design Decisions

1. **EventBus Pattern** -- Decouples systems for easy visual feedback additions. Any system can listen for `entity_damaged` without the combat system knowing about UI.

2. **Turn-based with Animation Delays** -- 0.15s delay between actions for readability. Configurable via AccessibilityManager.animation_speed.

3. **Component-based Entities** -- Entity base class with Player/Monster specializations. StatusEffects is a composition object (RefCounted), not inheritance.

4. **Data-driven Content** -- All monsters, items, abilities loaded from Sil-Q text files. No hardcoded content in GDScript beyond system logic.

5. **Autoload Singletons** -- GameManager, EventBus, DataManager accessible globally. Avoids deep dependency injection at the cost of implicit coupling.

6. **Static Systems** -- ConsumableSystem, HornSystem, DescriptionGenerator, and SmithingSystem use static methods on RefCounted classes. They hold no state and are called as utility functions.

7. **UI Panel Pattern** -- All UI panels follow the same lifecycle: `open(data) -> visible = true`, `close() -> visible = false -> closed.emit()`. Main scene connects to `closed` signal to restore player turn.

8. **d10 vs d20 Design Split** -- Stealth uses d10 (each +1 skill = 10% improvement) for impactful progression. Combat uses d20 (each +1 = 5%) for higher variance and excitement.

9. **Difficulty as Modifier Table** -- Difficulty does not change game logic, only numeric parameters. All systems query GameManager for multipliers rather than branching on difficulty enum.

10. **Energy-based Timing** -- Both player and monsters use the same energy system. Speed determines energy gain per tick. Actions cost 100 energy. Faster entities act more often, not sooner within a turn.
