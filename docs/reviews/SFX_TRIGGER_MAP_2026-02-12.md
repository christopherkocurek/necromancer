# SFX Trigger Map (updated 2026-02-13)

Purpose: canonical map of all runtime SFX entries in `scripts/core/audio_manager.gd`, what they are meant to convey, and where they trigger.

## Runtime SFX Inventory (`AudioManager.SFX_FILES`)

| Key | File | Intended Description | Trigger Path(s) |
|---|---|---|---|
| `hit` | `assets/audio/sfx/hit.wav` | Metallic impact / weapon clang | `EventBus.entity_damaged` fallback in `scripts/core/audio_manager.gd` |
| `hit1` | `assets/audio/sfx/hit1.wav` | Legacy alternate impact (voice-like, currently disabled in routing) | Loaded only; no current playback route |
| `dmg_poison` | `third_party_assets/sfx/kenney_rpg_audio/Audio/clothBelt.ogg` | Toxic sting / poison tick | `damage_type="poison"` in `scripts/core/audio_manager.gd` |
| `dmg_cold` | `third_party_assets/sfx/kenney_rpg_audio/Audio/creak1.ogg` | Cold impact | `damage_type="cold"` in `scripts/core/audio_manager.gd` |
| `dmg_fire` | `assets/audio/sfx/destroy.wav` | Burn / fire impact | `damage_type="fire"` in `scripts/core/audio_manager.gd` |
| `dmg_dark` | `third_party_assets/sfx/kenney_rpg_audio/Audio/creak3.ogg` | Dark magic hit (non-environmental) | `damage_type="dark"` with non-null source in `scripts/core/audio_manager.gd` |
| `miss` | `assets/audio/sfx/miss.wav` | Missed attack cue A | `EventBus.attack_missed` random pool in `scripts/core/audio_manager.gd` |
| `miss1` | `assets/audio/sfx/miss1.wav` | Missed attack cue B | `EventBus.attack_missed` random pool in `scripts/core/audio_manager.gd` |
| `kill` | `assets/audio/sfx/kill.wav` | Non-player death cue A | `EventBus.entity_died` (non-player) in `scripts/core/audio_manager.gd` |
| `kill1` | `assets/audio/sfx/kill1.wav` | Non-player death cue B | `EventBus.entity_died` (non-player) in `scripts/core/audio_manager.gd` |
| `death` | `assets/audio/sfx/death.wav` | Player death cue | `EventBus.entity_died` (player) in `scripts/core/audio_manager.gd` |
| `eat` | `assets/audio/sfx/eat.wav` | Consumable/use UI cue | `EventBus.item_used` in `scripts/core/audio_manager.gd` |
| `drop` | `assets/audio/sfx/drop.wav` | Drop UI cue | `EventBus.item_dropped` in `scripts/core/audio_manager.gd` |
| `level` | `assets/audio/sfx/level.wav` | Floor-entry sting | `EventBus.level_entered` in `scripts/core/audio_manager.gd` |
| `opendoor` | `assets/audio/sfx/opendoor.wav` | Door open cue | Loaded only; no current playback route |
| `shutdoor` | `assets/audio/sfx/shutdoor.wav` | Door close cue | Loaded only; no current playback route |
| `clunk` | `assets/audio/sfx/clunk.wav` | Pickup/equip UI metal cue | `EventBus.item_picked_up`, `EventBus.item_equipped` in `scripts/core/audio_manager.gd` |
| `money` | `assets/audio/sfx/money.wav` | Currency cue | Loaded only; no current playback route |
| `destroy` | `assets/audio/sfx/destroy.wav` | Destruction cue | Loaded only; no current playback route |
| `thump` | `assets/audio/sfx/thump.wav` | Heavy impact cue | Loaded only; no current playback route |
| `flee` | `assets/audio/sfx/flee.wav` | Fear/flee cue | Loaded only; no current playback route |
| `breath` | `assets/audio/sfx/breath.wav` | Breath/monster ability cue | Loaded only; no current playback route |
| `terrain_water_step` | `third_party_assets/sfx/kenney_rpg_audio/Audio/footstep08.ogg` | Water footstep | `WATER` in `scripts/systems/level.gd` |
| `terrain_vine_step` | `third_party_assets/sfx/kenney_rpg_audio/Audio/footstep03.ogg` | Vines footstep | `VINE_FLOOR` in `scripts/systems/level.gd` |
| `terrain_web_step` | `third_party_assets/sfx/kenney_rpg_audio/Audio/cloth2.ogg` | Sticky web step | `WEB` in `scripts/systems/level.gd` |
| `terrain_poison_stream_step` | `third_party_assets/sfx/kenney_rpg_audio/Audio/clothBelt2.ogg` | Poison stream step | `POISON_STREAM` in `scripts/systems/level.gd` |
| `terrain_dark_pool_step` | `third_party_assets/sfx/kenney_rpg_audio/Audio/creak2.ogg` | Cold occult pool step | `DARK_POOL` in `scripts/systems/level.gd` |
| `terrain_morgul_rune_step` | `third_party_assets/sfx/kenney_rpg_audio/Audio/creak3.ogg` | Ghostly rune trigger cue | `MORGUL_RUNE` in `scripts/systems/level.gd` |
| `terrain_shadow_floor_bite` | `third_party_assets/sfx/kenney_rpg_audio/Audio/creak3.ogg` | Shadow-floor backlash cue | `SHADOW_FLOOR` lit damage proc in `scripts/systems/level.gd` |

## Music Layer Routing

- Exploration tracks are selected by layer (`scripts/core/audio_manager.gd::_get_exploration_track`) and all loaded music streams are forced to loop.
- Exploration loop should stay continuous across floor transitions within the same layer unless pursuit music is forced.

## Active Cleanup Backlog (Audio)

1. Audit all `loaded only; no current playback route` keys and either wire them intentionally or remove them.
2. Add dedicated SFX for `SHADOW_BRAZIER`, `THRONE_DAIS`, and any future final-layer hazards to avoid overusing one dark cue.
3. Replace temporary Kenney placeholders with authored Tolkien-horror equivalents once asset pass starts.

