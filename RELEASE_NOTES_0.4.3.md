# The Necromancer - Alpha 0.4.3
## Release Notes

**Date:** January 8, 2026
**Build:** Alpha 0.4.3 - Layer 1 Forest Breach Terrain
**Base:** SIL-Q fork, Third Age Dol Guldur setting

---

## What's New in Alpha 0.4.3

### LAYER 1: FOREST BREACH TERRAIN

The Forest Breach (Depths 1-3) now features unique corrupted forest terrain that creates a distinct atmosphere and tactical challenges.

#### New Terrain Types

| Terrain | Symbol | Color | Effect |
|---------|--------|-------|--------|
| Poison Stream | `~` | Light Green | CON check (DC 10) or 10+2d10 poison on entry |
| Vine Floor | `.` | Green | 50% movement speed penalty |
| Tangled Roots | `#` | Brown | Blocks movement, allows sight/projectiles |
| Forest Floor | `.` | Brown | Decorative (no effect) |

#### Terrain Mechanics

**Poison Stream:**
- Triggers a CON check (DC 10) when the player enters
- On failure: inflicts 10+2d10 turns of poison
- Poison resistance grants immunity
- "Poison" indicator appears in terrain status area

**Vine Floor:**
- Movement takes 50% longer (1.5x energy cost)
- Message "You push through tangled vines." on first entry
- "Vines" indicator appears in terrain status area

**Tangled Roots:**
- Blocks player and monster movement
- Allows line of sight and projectile passage
- Cannot be tunneled through
- Message: "Thick tangled roots block your way."

#### Generation Rules

Terrain spawns naturally in depths 1-3:
- **Vine Floor:** 20% chance at depth 1, decreasing 5% per depth
- **Tangled Roots:** 12% wall conversion at depth 1, decreasing 2% per depth
- **Poison Streams:** 1-2 wandering streams at depth 1, chance decreases with depth

#### Updated Vaults

Layer 1 vaults have been enhanced to use the new terrain:

- **N:12 Corrupted Grove** - Forest floor and vine floor accents
- **N:16 Tangled Roots** - Tangled roots barrier with vine floor interior
- **N:18 Poison Pool** - Poison stream pool with vine floor border
- **N:22 Forest Pool** - Poison stream with vine floor surroundings
- **N:26 Root Tunnel** - Tangled roots walls with forest/vine floor

#### Vault Symbols (for modders)

```
= - poison stream
- - vine floor
| - tangled roots
_ - forest floor
```

---

## Technical Details

### Files Modified

#### Terrain Definitions
- `lib/edit/terrain.txt` - Added terrain types 84-87 (poison stream, tangled roots, vine floor, forest floor)

#### Source Code
- `src/defines.h` - Added FEAT_POISON_STREAM (0x54), FEAT_TANGLED_ROOTS (0x55), FEAT_VINE_FLOOR (0x56), FEAT_FOREST_FLOOR (0x57)
- `src/cmd1.c` - Poison stream poison effect, vine floor slow effect, tangled roots movement block
- `src/cmd2.c` - Tangled roots tunnel rejection
- `src/xtra1.c` - prt_terrain() cases for poison/vine status display
- `src/generate.c` - make_forest_terrain(), make_poison_streams(), count_adjacent_floors() functions; vault symbol parsing for `=`, `-`, `|`, `_`

#### Vault Definitions
- `lib/edit/vault.txt` - Updated symbol documentation and Layer 1 vaults (N:12, N:16, N:18, N:22, N:26)

### Design Documents Created
- `docs/design/layer1_terrain/poison_stream_spec.md`
- `docs/design/layer1_terrain/tangled_roots_spec.md`
- `docs/design/layer1_terrain/vine_floor_spec.md`
- `docs/design/layer1_terrain/sunlight_spec.md`
- `docs/design/layer1_terrain/generation_rules.md`
- `docs/design/layer1_terrain/vault_requirements.md`
- `docs/design/layer1_terrain/FINAL_SPEC.md`

---

## Known Issues

- Build requires compatible macOS/Linux environment with appropriate development tools
- QuickTime.h deprecation on modern macOS affects legacy Carbon build

---

## Credits

Development assisted by Claude Code (Anthropic)
