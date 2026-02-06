# DCSS Demo Tileset for Necromancer

This directory contains demo tiles from Dungeon Crawl Stone Soup (DCSS) to demonstrate what Necromancer could look like with graphical tiles.

## License

**IMPORTANT**: DCSS tiles are licensed under the GNU General Public License (GPL).

- Source: https://github.com/crawl/crawl
- Tiles location: `crawl-ref/source/rltiles/`
- License: GPL v2 or later

If these tiles are used in the final game, Necromancer would need to comply with GPL requirements or obtain alternative artwork.

## Tile Specifications

- Resolution: 32x32 pixels
- Format: PNG with transparency (RGBA)
- Game uses: 64x64 (tiles would need scaling or game needs adjustment)

## Terrain Tiles

| File | DCSS Source | Necromancer Use |
|------|-------------|-----------------|
| `terrain/wall.png` | `dngn/wall/stone_dark0.png` | Dungeon walls |
| `terrain/floor.png` | `dngn/floor/crypt0.png` | Dungeon floor |
| `terrain/stairs_up.png` | `dngn/gateways/stone_stairs_up.png` | Stairs ascending |
| `terrain/stairs_down.png` | `dngn/gateways/stone_stairs_down.png` | Stairs descending |
| `terrain/door_closed.png` | `dngn/doors/closed_door_crypt.png` | Closed doors |
| `terrain/door_open.png` | `dngn/doors/open_door_crypt.png` | Open doors |

## Monster Tiles

| File | DCSS Source | Necromancer Use |
|------|-------------|-----------------|
| `monsters/spider.png` | `mon/animals/wolf_spider.png` | Mirkwood Spider, Giant Spider |
| `monsters/rat.png` | `mon/animals/rat.png` | Giant Rat, Cave Rat |
| `monsters/bird.png` | `mon/animals/raven.png` | Crebain (spy-birds of Mordor) |
| `monsters/orc.png` | `mon/humanoids/orcs/orc_knight.png` | Orc Soldier, Orc Warrior |
| `monsters/troll.png` | `mon/humanoids/deep_troll.png` | Hill Troll, Mirk-troll |
| `monsters/skeleton.png` | `mon/undead/skeletal_warrior.png` | Skeleton, Skeletal Warrior |
| `monsters/wraith.png` | `mon/undead/wraith.png` | Wraith, Phantom, Fell Spirit |
| `monsters/mage.png` | `mon/humanoids/humans/necromancer.png` | Dark Sorcerer, Black Numenorean |
| `monsters/demon.png` | `mon/demons/brimstone_fiend.png` | Sauron, Nazgul, Balrog |
| `monsters/wolf.png` | `mon/animals/warg.png` | Warg, Werewolf |

## Mapping to Necromancer Enemies

### Mirkwood/Forest Theme
- **Mirkwood Spider** -> `spider.png` (wolf_spider)
- **Giant Rat** -> `rat.png`
- **Crebain** -> `bird.png` (raven)
- **Warg** -> `wolf.png` (warg)

### Orcs of Dol Guldur
- **Orc Scout** -> `orc.png` (could use variant)
- **Orc Soldier** -> `orc.png` (orc_knight)
- **Orc Captain** -> `orc.png` (could use orc_warlord)

### Undead/Necromantic
- **Skeleton** -> `skeleton.png` (skeletal_warrior)
- **Wraith** -> `wraith.png`
- **Phantom** -> `wraith.png` (freezing_wraith alternative)
- **Barrow-wight** -> `skeleton.png` or custom

### Human Enemies
- **Dark Sorcerer** -> `mage.png` (necromancer)
- **Black Numenorean** -> `mage.png` (death_knight alternative)

### Trolls
- **Hill Troll** -> `troll.png` (deep_troll)
- **Mirk-troll** -> `troll.png`
- **Stone Troll** -> `troll.png` (iron_troll alternative)

### Boss Enemies
- **Nazgul** -> `demon.png` (brimstone_fiend) or custom
- **Sauron** -> `demon.png` (unique required)
- **Khamul the Easterling** -> `mage.png` + custom

## Alternative Tiles Available in DCSS

For variety, these additional tiles could be used:

### Spiders
- `jumping_spider.png` - smaller spider variants
- `orb_spider.png` - magical spider types
- `tarantella.png` - dancing spider (could be cursed variant)

### Orcs
- `orc.png` - basic orc
- `orc_archer.png` - ranged orc
- `orc_sorcerer.png` - magical orc
- `orc_warlord.png` - boss orc

### Undead
- `ghost.png` - incorporeal spirit
- `freezing_wraith.png` - cold-themed wraith
- `shadow_wraith.png` - shadow variant

### Trolls
- `troll.png` - basic troll
- `iron_troll.png` - armored variant
- `deep_troll_shaman.png` - magical troll

### Demons/Bosses
- `reaper.png` - death incarnate
- `hell_sentinel.png` - guardian demon
- `executioner.png` - brutal enforcer

## Notes for Integration

1. **Scaling**: Current tiles are 32x32. Either scale to 64x64 or adjust game tile size.
2. **Consistency**: The crypt/dark stone theme maintains visual cohesion.
3. **Animation**: DCSS has multiple variants (e.g., `crypt0.png` through `crypt11.png`) that could be used for animation frames.
4. **Custom Work**: Tolkien-specific creatures (Nazgul, Balrog, Ents) would need custom artwork.

## Preview

See `preview.png` for a combined view of all demo tiles (432x216 pixels, 6x3 grid).

**Preview Layout (reading left-to-right, top-to-bottom):**
```
Row 1 (Terrain):  wall | floor | stairs_up | stairs_down | door_closed | door_open
Row 2 (Monsters): spider | rat | bird | orc | troll | skeleton
Row 3 (Monsters): wraith | mage | demon | wolf | (empty) | (empty)
```

Each tile is scaled to 64x64 in the preview for better visibility.
