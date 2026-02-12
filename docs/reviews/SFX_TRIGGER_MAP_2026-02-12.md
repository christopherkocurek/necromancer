# SFX Trigger Map (2026-02-12)

## EventBus-driven triggers (`scripts/core/audio_manager.gd`)

| Trigger | Condition | Sound(s) |
|---|---|---|
| `entity_damaged` | Player/source involved OR target tile visible; `damage_type=physical` | `hit.wav`, `hit1.wav` |
| `entity_damaged` | `damage_type=poison` | `kenney: Audio/clothBelt.ogg` (`dmg_poison`) |
| `entity_damaged` | `damage_type=cold` | `kenney: Audio/creak1.ogg` (`dmg_cold`) |
| `entity_damaged` | `damage_type=fire` | `destroy.wav` (`dmg_fire`) |
| `entity_damaged` | `damage_type=dark` | `hallu.wav` (`dmg_dark`) |
| `entity_died` | player dies | `death.wav` |
| `entity_died` | non-player dies | `kill.wav`, `kill1.wav` |
| `attack_missed` | any miss event | `miss.wav`, `miss1.wav` |
| `item_picked_up` | any pickup | `clunk.wav` |
| `item_dropped` | any drop | `drop.wav` |
| `item_equipped` | any equip | `clunk.wav` |
| `item_used` | any use event | `eat.wav` |
| `level_entered` | entering level | `level.wav` |

## Terrain-step triggers (`scripts/systems/level.gd`)

| Trigger | Condition | Sound |
|---|---|---|
| water step | player steps on `WATER` | `kenney: Audio/footstep08.ogg` (`terrain_water_step`) |
| vine step | player steps on `VINE_FLOOR` | `kenney: Audio/footstep03.ogg` (`terrain_vine_step`) |
| web step | player steps on `WEB` | `kenney: Audio/cloth2.ogg` (`terrain_web_step`) |
| poison stream step | player steps on `POISON_STREAM` | `kenney: Audio/clothBelt2.ogg` (`terrain_poison_stream_step`) |

## Notes
- Metallic impact spam from offscreen entities is now suppressed for damage SFX.
- Terrain sounds are now event-appropriate and terrain-specific.
- Source pack for new terrain and elemental cues: `third_party_assets/sfx/kenney_rpg_audio` (CC0, see `third_party_assets/sfx/kenney_rpg_audio/License.txt`).
