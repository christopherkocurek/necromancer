# The Necromancer - Godot Architecture

```
╔══════════════════════════════════════════════════════════════════════════════════════════╗
║                        THE NECROMANCER - GODOT ARCHITECTURE                              ║
╚══════════════════════════════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                    AUTOLOADS (Singletons)                               │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│   ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐                  │
│   │   GameManager   │     │    EventBus     │     │   DataManager   │                  │
│   │                 │     │    (Signals)    │     │                 │                  │
│   │ • current_state │     │                 │     │ • monsters{}    │                  │
│   │ • current_depth │◄───►│ ────────────────│◄───►│ • items{}       │                  │
│   │ • turn_count    │     │ entity_damaged  │     │ • artifacts{}   │                  │
│   │ • player ref    │     │ entity_healed   │     │ • abilities{}   │                  │
│   │ • level ref     │     │ entity_died     │     │ • races{}       │                  │
│   └────────┬────────┘     │ entity_moved    │     │ • vaults[]      │                  │
│            │              │ turn_started    │     └─────────────────┘                  │
│            │              │ turn_ended      │                                           │
│            │              │ status_applied  │                                           │
│            │              │ level_entered   │                                           │
│            │              │ message_logged  │                                           │
│            │              └────────┬────────┘                                           │
│            │                       │                                                    │
└────────────┼───────────────────────┼────────────────────────────────────────────────────┘
             │                       │
             ▼                       ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              GAME STATE MACHINE (GameManager)                           │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│                              ┌─────────────┐                                            │
│                              │  MAIN_MENU  │                                            │
│                              └──────┬──────┘                                            │
│                                     │ start_new_game()                                  │
│                                     ▼                                                   │
│     ┌───────────┐  game_over() ┌─────────┐  change_state()  ┌───────────┐              │
│     │ GAME_OVER │◄─────────────│ PLAYING │◄────────────────►│  PAUSED   │              │
│     │           │              └────┬────┘                  │           │              │
│     │ • victory │                   │                       │ • tree    │              │
│     │ • defeat  │                   │ open inventory        │   paused  │              │
│     └───────────┘                   ▼                       └───────────┘              │
│                              ┌───────────┐                                              │
│                              │ INVENTORY │                                              │
│                              └───────────┘                                              │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              TURN STATE MACHINE (TurnSystem)                            │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│    ┌──────────────────────────────────────────────────────────────────────────────┐    │
│    │                                                                              │    │
│    │    ┌──────────────┐         ┌────────────────┐         ┌─────────────┐      │    │
│    │    │ PLAYER_INPUT │────────►│ PLAYER_ACTING  │────────►│ ENEMY_TURN  │      │    │
│    │    │              │ action  │                │ done    │             │      │    │
│    │    │ • awaiting   │ taken   │ • processing   │         │ • iterate   │      │    │
│    │    │   input      │         │   player move  │         │   monsters  │      │    │
│    │    └──────────────┘         └───────┬────────┘         └──────┬──────┘      │    │
│    │           ▲                         │                         │             │    │
│    │           │                         ▼                         ▼             │    │
│    │           │                   ┌───────────┐              ┌───────────┐      │    │
│    │           │                   │ ANIMATING │              │ ANIMATING │      │    │
│    │           │                   │           │              │           │      │    │
│    │           │                   │ • 0.15s   │              │ • per     │      │    │
│    │           │                   │   delay   │              │   monster │      │    │
│    │           │                   └───────────┘              └─────┬─────┘      │    │
│    │           │                                                    │            │    │
│    │           └────────────────────────────────────────────────────┘            │    │
│    │                              _end_round()                                   │    │
│    │                              round_completed signal                         │    │
│    └──────────────────────────────────────────────────────────────────────────────┘    │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              MONSTER AI STATE MACHINE                                   │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│         can't see player             ┌────────────┐          can't see player          │
│        ┌────────────────────────────►│    IDLE    │◄────────────────────────┐          │
│        │         10% chance          └─────┬──────┘         30% chance      │          │
│        │                                   │ 10% chance                     │          │
│        │                                   ▼                                │          │
│   ┌────┴─────┐                      ┌────────────┐                    ┌─────┴────┐     │
│   │ HUNTING  │◄─────────────────────│ WANDERING  │───────────────────►│ FLEEING  │     │
│   │          │    see player &      └────────────┘    see player &    │          │     │
│   │ • path   │    health > 20%            ▲           health < 20%    │ • run    │     │
│   │   toward │                            │                           │   away   │     │
│   │   player │                            │                           │          │     │
│   └────┬─────┘                            │                           └────┬─────┘     │
│        │                                  │                                │           │
│        │         see player &             │         far from player        │           │
│        └──────────────────────────────────┴────────────────────────────────┘           │
│                  health < 20%                    (2x perception range)                 │
│                                                                                         │
│   ┌─────────────────────────────────────────────────────────────────────────────────┐  │
│   │  HUNTING BEHAVIOR:                                                              │  │
│   │    if adjacent to player → attack_entity(player)                                │  │
│   │    else → move toward player using _direction_toward()                          │  │
│   └─────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                   EVENT FLOW DIAGRAM                                    │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│   PLAYER ACTION                                                                         │
│        │                                                                                │
│        ▼                                                                                │
│   ┌─────────┐     ┌───────────────────────────────────────────────────────────┐        │
│   │ Player  │────►│                      EventBus                             │        │
│   │ attacks │     │                                                           │        │
│   │ monster │     │  entity_damaged(monster, 15, "physical", player)          │        │
│   └─────────┘     └───────────────────────────────────────────────────────────┘        │
│                              │                    │                    │               │
│                              ▼                    ▼                    ▼               │
│                    ┌──────────────┐     ┌──────────────┐     ┌──────────────┐          │
│                    │FloaterManager│     │     HUD      │     │   Monster    │          │
│                    │              │     │              │     │              │          │
│                    │ spawn damage │     │ log message  │     │ flash red    │          │
│                    │ floater at   │     │ "You hit..." │     │ check death  │          │
│                    │ monster pos  │     │              │     │              │          │
│                    └──────┬───────┘     └──────────────┘     └──────┬───────┘          │
│                           │                                         │                  │
│                           ▼                                         ▼                  │
│                    ┌──────────────┐                         ┌──────────────┐           │
│                    │DamageFloater │                         │entity_died() │           │
│                    │              │                         │              │           │
│                    │ "15" rises   │                         │ emit signal  │           │
│                    │ and fades    │                         │ grant XP     │           │
│                    │ COLOR_PHYS   │                         │ death anim   │           │
│                    └──────────────┘                         └──────────────┘           │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                   SCENE TREE STRUCTURE                                  │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│   Main (Node2D)                                                                         │
│   ├── LevelContainer (Node2D)                                                           │
│   │   └── Level (Node2D) ◄─── instantiated at runtime                                   │
│   │       ├── TerrainLayer (TileMapLayer)                                               │
│   │       ├── Items (Node2D)                                                            │
│   │       ├── Entities (Node2D)                                                         │
│   │       │   ├── Player (Node2D)                                                       │
│   │       │   │   ├── Sprite2D                                                          │
│   │       │   │   └── Camera2D                                                          │
│   │       │   ├── Monster (Node2D)                                                      │
│   │       │   │   └── Sprite2D                                                          │
│   │       │   └── ... more monsters                                                     │
│   │       └── Effects (Node2D) ◄─── floater_container                                   │
│   │           ├── DamageFloater                                                         │
│   │           │   └── Label                                                             │
│   │           └── ... more floaters                                                     │
│   ├── TurnSystem (Node)                                                                 │
│   ├── FloaterManager (Node)                                                             │
│   └── HUD (CanvasLayer)                                                                 │
│       ├── TopPanel                                                                      │
│       │   ├── HealthBar                                                                 │
│       │   ├── HealthLabel                                                               │
│       │   ├── DepthLabel                                                                │
│       │   ├── TurnLabel                                                                 │
│       │   └── StatusContainer                                                           │
│       └── BottomPanel                                                                   │
│           └── MessageLog (RichTextLabel)                                                │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                   DATA FLOW DIAGRAM                                     │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│   ┌─────────────────────────────────────────────────────────────────────────────────┐  │
│   │                              DATA FILES (res://data/)                           │  │
│   ├─────────────────────────────────────────────────────────────────────────────────┤  │
│   │  monster.txt  object.txt  artefact.txt  ability.txt  race.txt  house.txt  ...   │  │
│   └────────────────────────────────────┬────────────────────────────────────────────┘  │
│                                        │ _ready() -> load_all_data()                   │
│                                        ▼                                               │
│   ┌─────────────────────────────────────────────────────────────────────────────────┐  │
│   │                              DataManager (Autoload)                             │  │
│   ├─────────────────────────────────────────────────────────────────────────────────┤  │
│   │  monsters: Dictionary    ──►  get_random_monster_for_depth(depth) ──┐           │  │
│   │  items: Dictionary       ──►  get_random_item_for_depth(depth)    ──┤           │  │
│   │  artifacts: Dictionary   ──►  get_artifact(name)                  ──┤           │  │
│   │  abilities: Dictionary   ──►  get_ability(name)                   ──┤           │  │
│   │  races: Dictionary       ──►  get_race(name)                      ──┤           │  │
│   │  houses: Dictionary      ──►  get_house(name)                     ──┤           │  │
│   │  vaults: Array           ──►  vaults[i]                           ──┤           │  │
│   └─────────────────────────────────────────────────────────────────────┼───────────┘  │
│                                                                         │              │
│                              ┌──────────────────────────────────────────┘              │
│                              ▼                                                         │
│   ┌─────────────────────────────────────────────────────────────────────────────────┐  │
│   │                           DungeonGenerator                                      │  │
│   ├─────────────────────────────────────────────────────────────────────────────────┤  │
│   │  generate(level, depth)                                                         │  │
│   │       │                                                                         │  │
│   │       ├──► _generate_rooms()      ──► carve floor tiles                         │  │
│   │       ├──► _connect_rooms()       ──► carve corridors                           │  │
│   │       ├──► _place_stairs(depth)   ──► stairs up/down                            │  │
│   │       ├──► _add_features(depth)   ──► doors, rubble, forges                     │  │
│   │       ├──► _spawn_monsters(depth) ──► DataManager.get_random_monster_for_depth  │  │
│   │       └──► _spawn_items(depth)    ──► DataManager.get_random_item_for_depth     │  │
│   └─────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                COMBAT RESOLUTION FLOW                                   │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│   Player.attack_entity(target)                                                          │
│           │                                                                             │
│           ▼                                                                             │
│   ┌───────────────────┐                                                                 │
│   │ ROLL TO HIT       │                                                                 │
│   │                   │                                                                 │
│   │ hit_roll = 1d20   │                                                                 │
│   │   + melee_bonus   │                                                                 │
│   │   + dex/2         │                                                                 │
│   └─────────┬─────────┘                                                                 │
│             │                                                                           │
│             ▼                                                                           │
│   ┌───────────────────┐     NO      ┌───────────────────┐                              │
│   │ hit_roll >=       │────────────►│ EventBus.attack_  │                              │
│   │ target_evasion?   │             │ missed.emit()     │                              │
│   └─────────┬─────────┘             └───────────────────┘                              │
│             │ YES                                                                       │
│             ▼                                                                           │
│   ┌───────────────────┐                                                                 │
│   │ ROLL DAMAGE       │                                                                 │
│   │                   │                                                                 │
│   │ damage = roll_dice│                                                                 │
│   │   (damage_dice)   │                                                                 │
│   │   + strength/2    │                                                                 │
│   └─────────┬─────────┘                                                                 │
│             │                                                                           │
│             ▼                                                                           │
│   ┌───────────────────┐     YES     ┌───────────────────┐                              │
│   │ hit_roll >= 20?   │────────────►│ damage *= 2       │                              │
│   │ (critical hit)    │             │ (CRITICAL!)       │                              │
│   └─────────┬─────────┘             └─────────┬─────────┘                              │
│             │ NO                              │                                         │
│             └────────────────┬────────────────┘                                         │
│                              ▼                                                          │
│                    target.take_damage(damage, "physical", self)                         │
│                              │                                                          │
│                              ▼                                                          │
│   ┌───────────────────────────────────────────────────────────────────────────────┐    │
│   │ Entity.take_damage()                                                          │    │
│   │     │                                                                         │    │
│   │     ├──► actual_damage = damage - (armor_class / 5)                           │    │
│   │     ├──► current_health -= actual_damage                                      │    │
│   │     ├──► EventBus.entity_damaged.emit() ──► FloaterManager ──► DamageFloater  │    │
│   │     ├──► _flash_damage() (red tint tween)                                     │    │
│   │     │                                                                         │    │
│   │     └──► if current_health <= 0:                                              │    │
│   │              die(source) ──► EventBus.entity_died.emit()                      │    │
│   │                          ──► _play_death_animation() (fade out)               │    │
│   └───────────────────────────────────────────────────────────────────────────────┘    │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

## Key Design Decisions

1. **EventBus Pattern** - Decouples systems for easy visual feedback additions
2. **Turn-based with Animation Delays** - 0.15s delay between actions for readability
3. **Component-based Entities** - Entity base class with Player/Monster specializations
4. **Data-driven Content** - All monsters, items, abilities loaded from text files
5. **Autoload Singletons** - GameManager, EventBus, DataManager accessible globally
