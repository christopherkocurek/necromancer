# DCSS Tileset Integration Plan for Necromancer

## Overview

Replace the current broken tileset with DCSS (Dungeon Crawl Stone Soup) tiles to make the game playable. This is a temporary solution until custom art can be commissioned.

## Source

- **Repository**: https://github.com/crawl/crawl
- **Tiles Location**: `crawl-ref/source/rltiles/`
- **License**: GPL v2+ (game must be open source)
- **Tile Size**: 32x32 pixels (scale to 64x64)

## Scope

| Category | Count | Notes |
|----------|-------|-------|
| Terrain | 88 | Walls, floors, doors, stairs, traps, forges |
| Terrain (dark) | 88 | Auto-generated desaturated variants for FOV |
| Monsters | 73 | All 7 dungeon layers |
| Items | 254 | Weapons, armor, consumables |
| Artifacts | 147 | Unique named items |
| Players | 4 | One per race (masculine) |
| Effects | 20 | Status overlays |
| **TOTAL** | ~674 | |

## Technical Approach

### 1. Tile Scaling
- DCSS: 32x32 pixels
- Necromancer: 64x64 pixels
- **Solution**: Scale 2x using nearest-neighbor interpolation (preserves pixel art)

### 2. Dark Variants for FOV
- Light tiles: Original DCSS colors
- Dark tiles: Programmatically desaturate + darken
- Method: Reduce saturation 60%, reduce brightness 40%

### 3. Tileset Assembly
- Grid: 32x32 tiles (1024 slots)
- Output: 2048x2048 PNG with magenta (#FF00FF) background
- Location: `assets/sprites/64x64_necromancer.png` (replace existing)

## Entity Mapping Strategy

### Terrain Mapping

| Necromancer | DCSS Source |
|-------------|-------------|
| open floor | `dngn/floor/crypt*.png` |
| dark stone wall | `dngn/wall/stone_dark*.png` |
| iron door (closed) | `dngn/doors/closed_door*.png` |
| iron door (open) | `dngn/doors/open_door*.png` |
| stairs up | `dngn/gateways/stone_stairs_up.png` |
| stairs down | `dngn/gateways/stone_stairs_down.png` |
| traps | `dngn/traps/*.png` |
| forges | `dngn/altars/*.png` or custom |

### Monster Mapping by Layer

**Layer 1 - Forest Breach:**
| Necromancer | DCSS Source |
|-------------|-------------|
| Mirkwood Spider | `mon/animals/wolf_spider.png` |
| Giant Rat | `mon/animals/rat.png` |
| Crebain | `mon/animals/raven.png` |
| Warg Pup | `mon/animals/wolf.png` |
| Broodmother | `mon/animals/spider.png` (large) |

**Layer 2 - Orc Warrens:**
| Necromancer | DCSS Source |
|-------------|-------------|
| Orc Soldier | `mon/humanoids/orcs/orc_knight.png` |
| Orc Captain | `mon/humanoids/orcs/orc_warlord.png` |
| Warg | `mon/animals/warg.png` |
| Hill Troll | `mon/humanoids/troll.png` |

**Layer 3 - Torture Halls:**
| Necromancer | DCSS Source |
|-------------|-------------|
| Dark Sorcerer | `mon/humanoids/humans/necromancer.png` |
| Ghoul | `mon/undead/ghoul.png` |
| Mirk-troll | `mon/humanoids/deep_troll.png` |

**Layer 4 - Necropolis:**
| Necromancer | DCSS Source |
|-------------|-------------|
| Skeleton | `mon/undead/skeletal_warrior.png` |
| Zombie | `mon/undead/zombie_small.png` |
| Wight | `mon/undead/wight.png` |
| Barrow-wight | `mon/undead/eidolon.png` |

**Layer 5 - Wraith Domain:**
| Necromancer | DCSS Source |
|-------------|-------------|
| Phantom | `mon/undead/phantom.png` |
| Wraith | `mon/undead/wraith.png` |
| Shadow | `mon/undead/shadow.png` |
| Spectre | `mon/undead/spectral_thing.png` |

**Layer 6 - Inner Sanctum:**
| Necromancer | DCSS Source |
|-------------|-------------|
| Black Númenórean | `mon/humanoids/humans/death_knight.png` |
| Vampire Lord | `mon/undead/vampire_knight.png` |
| Greater Wraith | `mon/undead/freezing_wraith.png` |

**Layer 7 - Pits of Despair + Bosses:**
| Necromancer | DCSS Source | Notes |
|-------------|-------------|-------|
| Nazgûl (Úvatha) | `mon/undead/lich.png` | FLAG: needs custom |
| Khamûl | `mon/demons/hell_sentinel.png` | FLAG: needs custom |
| Sauron | `mon/demons/brimstone_fiend.png` | FLAG: needs custom |

### Player Sprites (1 per race, masculine)

| Race | DCSS Source |
|------|-------------|
| Elf | `player/base/human_m.png` + `player/felid/elf*.png` |
| Man | `player/base/human_m.png` |
| Dwarf | `player/base/dwarf_m.png` |
| Istari | `player/base/wizard_m.png` or similar |

### Item Mapping

**Weapons:**
| Type | DCSS Source |
|------|-------------|
| Swords | `item/weapon/sword*.png` |
| Axes | `item/weapon/axe*.png` |
| Polearms | `item/weapon/spear*.png`, `item/weapon/halberd*.png` |
| Blunt | `item/weapon/mace*.png`, `item/weapon/hammer*.png` |

**Armor:**
| Type | DCSS Source |
|------|-------------|
| Soft armor | `item/armour/robe*.png`, `item/armour/leather*.png` |
| Hard armor | `item/armour/chain*.png`, `item/armour/plate*.png` |
| Shields | `item/armour/shield*.png` |
| Helms | `item/armour/helmet*.png` |

**Consumables:**
| Type | DCSS Source |
|------|-------------|
| Potions | `item/potion/*.png` |
| Scrolls | `item/scroll/*.png` |
| Food | `item/food/*.png` |
| Wands | `item/wand/*.png` |

**Jewelry:**
| Type | DCSS Source |
|------|-------------|
| Rings | `item/ring/*.png` |
| Amulets | `item/amulet/*.png` |

## Implementation Steps

### Step 1: Download DCSS Tiles
```bash
cd ~/dev/active/games/necromancer-godot/tileset_generation
git clone --depth 1 --filter=blob:none --sparse https://github.com/crawl/crawl.git dcss_source
cd dcss_source
git sparse-checkout set crawl-ref/source/rltiles
```

### Step 2: Create Mapping Script
Create `dcss_mapper.py` that:
1. Reads `manifest.json` (entity list)
2. Maps each entity to a DCSS tile path
3. Copies/renames tiles to staging directory
4. Generates dark variants programmatically
5. Outputs `dcss_mapping.json`

### Step 3: Assemble Tileset
Update `assembler.py` to:
1. Read DCSS tiles from staging
2. Scale 32x32 → 64x64 (nearest-neighbor)
3. Assemble into 2048x2048 grid
4. Output to `assets/sprites/64x64_necromancer.png`

### Step 4: Update tile_mapper.gd
1. Update grid size constant (16 → 32)
2. Generate new coordinate mappings from `dcss_mapping.json`
3. Update all lookup functions

### Step 5: Update Godot TileSet Resource
1. Update `assets/sprites/necromancer_tileset.tres`
2. Verify tile regions match new layout

### Step 6: Test
1. Run game
2. Verify terrain renders correctly
3. Verify monsters display
4. Verify items display
5. Verify FOV light/dark works

## Files to Create/Modify

### New Files
- `tileset_generation/dcss_mapper.py` - Mapping script
- `tileset_generation/dcss_mapping.json` - Entity→tile mapping
- `tileset_generation/dcss_tiles/` - Downloaded DCSS tiles

### Modified Files
- `assets/sprites/64x64_necromancer.png` - New tileset
- `scripts/core/tile_mapper.gd` - Updated mappings
- `assets/sprites/necromancer_tileset.tres` - Updated resource

## Flagged for Custom Art Later

These Tolkien-specific entities need custom artwork eventually:
- Nazgûl (all 9)
- Sauron
- Balrog (if added)
- Ring of Barahir
- Silmarils (if added)
- Ents (if added)
- Eagles (if added)

## Success Criteria

- [ ] All terrain types render correctly
- [ ] All monsters have appropriate sprites
- [ ] All items have appropriate sprites
- [ ] FOV system shows light/dark variants
- [ ] Game is playable from start to finish
- [ ] No missing texture errors
