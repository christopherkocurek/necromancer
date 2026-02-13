# Beta v1.1 Sound Proposal

Goal: replace low-quality/annoying monster vocal moments (including the current "arrg" feel) with a cleaner, role-based palette that preserves readability.

| Event | Proposed Sound Key | Description | Usage Rule |
|---|---|---|---|
| Player melee hit lands | `hit` | Short metallic impact, no vocal layer | Default melee impact when player or visible entity strikes |
| Player melee crit / heavy hit | `hit1` | Heavier, lower transient impact | Use on high-damage hits only |
| Attack misses | `miss` / `miss1` | Air/weapon whoosh with no voice sample | Alternate randomly for variety |
| Monster dies (normal) | `kill` | Dry impact + collapse | Non-boss enemy death |
| Monster dies (elite/boss) | `kill1` | Thicker body fall, longer tail | Elite/unique death |
| Player death | `death` | Dark, final stinger | Player death only |
| Fear application (monster flees) | `flee` | Breathy panic / retreat cue | On fear proc, once per target per short window |
| Dark/void damage | `dmg_dark` | Textural shadow pulse | Dark magic tick or dark attack hit |
| Fire damage | `dmg_fire` | Crackling burst | Fire hit/tick events |
| Cold damage | `dmg_cold` | Brittle frost crack | Cold hit/tick events |
| Poison damage | `dmg_poison` | Wet toxic hiss | Poison hit/tick events |
| Item pickup/equip | `clunk` | Clean inventory foley | Pickup/equip only |
| Door open/close | `opendoor` / `shutdoor` | Stone/iron door movement | Door interaction only |
| Terrain: web | `terrain_web_step` | Sticky thread drag | Walking on webs |
| Terrain: poison stream | `terrain_poison_stream_step` | Bubbling caustic step | Walking on poison streams |
| Terrain: dark pool | `terrain_dark_pool_step` | Sub-bass ripple step | Walking on dark pools |
| Terrain: morgul rune | `terrain_morgul_rune_step` | Arcane sting | Entering runed tiles |
| Terrain: shadow floor bite | `terrain_shadow_floor_bite` | Hostile floor pulse | Triggered damage floor |

## "Arrg" replacement direction

- Remove any human-like shouted monster vocal sample from default combat loops.
- Keep monster identity through text/VFX + non-vocal sonic texture (breath, scrape, hiss, growl-like foley if needed).
- Reserve explicit vocalizations for rare, high-signal moments only (boss intro, unique fear roar), then gate with cooldown.

## Mix constraints for beta

- Prioritize clarity over cinematic loudness (short tails, less overlap).
- Avoid repeated vocal samples on rapid multi-hit turns.
- Perceived loudness target: combat impacts <= UI peak loudness + 2 dB.
