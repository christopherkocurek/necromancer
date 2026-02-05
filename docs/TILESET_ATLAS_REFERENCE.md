# Necromancer Tileset Atlas Reference

## Technical Specifications

| Property | Value |
|----------|-------|
| Image file | `assets/sprites/64x64_necromancer.png` |
| Image dimensions | 1024 × 1024 pixels |
| Tile size | 64 × 64 pixels |
| Grid size | 16 columns × 16 rows |
| Valid coordinates | (0-15, 0-15) |
| Godot TileSet | `assets/sprites/necromancer_tileset.tres` |

## Coordinate System

Godot atlas coordinates are `Vector2i(column, row)` where:
- **Column (X)**: 0 = leftmost, 15 = rightmost
- **Row (Y)**: 0 = topmost, 15 = bottommost
- Example: `Vector2i(3, 11)` = column 3, row 11

---

## Complete Tile Catalog

### ROW 0 (y=0): Consumables & Miscellaneous Items

| Coords | Description |
|--------|-------------|
| (0, 0) | Red potion/flask - health potion |
| (1, 0) | Dark spiky orb - cursed artifact |
| (2, 0) | Torch (lit, flaming) |
| (3, 0) | Campfire/brazier (lit) |
| (4, 0) | Treasure chest (ornate, brown/gold) |
| (5, 0) | Curved tentacle/horn (purple/pink) |
| (6, 0) | Hook/claw weapon |
| (7, 0) | Pickaxe/mining tool |
| (8, 0) | Scroll (rolled up, tan) |
| (9, 0) | Red gem/crystal |
| (10, 0) | Pink shell/organic item |
| (11, 0) | White feather/quill |
| (12, 0) | Fireball/flame effect (orange) |
| (13, 0) | Magic burst effect (purple starburst) |
| (14, 0) | Light sparkle effect (white) |
| (15, 0) | Placeholder tile (text: "ORIGINAL ART") |

### ROW 1 (y=1): Weapons & Equipment

| Coords | Description |
|--------|-------------|
| (0, 1) | Sword (ornate, purple hilt) |
| (1, 1) | Dagger (small blade) |
| (2, 1) | Staff/wand (with glowing orb top) |
| (3, 1) | Scepter/mace (ornate, royal) |
| (4, 1) | Crossbow |
| (5, 1) | Battle axes (crossed, double-headed) |
| (6, 1) | Crown/royal headpiece |
| (7, 1) | Wing ornament/feathered pauldron |
| (8, 1) | Chestplate/body armor (dark metal) |
| (9, 1) | Target/aiming reticle (crosshair on shield) |
| (10, 1) | Cube artifact/puzzle box |
| (11, 1) | Helmet (knight style, visor) |
| (12, 1) | Boots (armored) |
| (13, 1) | Gloves/gauntlets |
| (14, 1) | Ring (with purple gem) |
| (15, 1) | Shield (ornate, decorative) |

### ROW 2 (y=2): Monsters - Demons & Major Undead

| Coords | Description |
|--------|-------------|
| (0, 2) | Hulking demon (red, muscular, horned) |
| (1, 2) | Wraith/specter (dark, floating, ghostly) |
| (2, 2) | Pale horned demon (white/gray) |
| (3, 2) | Dark winged creature (bat-like) |
| (4, 2) | Cloaked necromancer (purple robe) |
| (5, 2) | Tentacled horror (Lovecraftian) |
| (6, 2) | Tall cloaked figure (death-like) |
| (7, 2) | **EMPTY** (magenta background) |
| (8, 2) | **EMPTY** |
| (9, 2) | **EMPTY** |
| (10, 2) | **EMPTY** |
| (11, 2) | **EMPTY** |
| (12, 2) | **EMPTY** |
| (13, 2) | **EMPTY** |
| (14, 2) | **EMPTY** |
| (15, 2) | **EMPTY** |

### ROW 3 (y=3): Monsters - Undead & Spirits

| Coords | Description |
|--------|-------------|
| (0, 3) | Dark armored warrior (undead knight) |
| (1, 3) | Ghost/spirit (wispy, ethereal) |
| (2, 3) | Masked figure (white theater mask) |
| (3, 3) | Elegant robed figure (purple, feminine) |
| (4, 3) | Cthulhu-like tentacle monster |
| (5, 3) | Spider creature (dark, multi-legged) |
| (6, 3) | Tall reaper figure (hooded) |
| (7, 3) | Haunted portrait (creepy face in frame) |
| (8, 3) | Shadow wraith (dark mass) |
| (9, 3) | **EMPTY** |
| (10, 3) | **EMPTY** |
| (11, 3) | **EMPTY** |
| (12, 3) | **EMPTY** |
| (13, 3) | **EMPTY** |
| (14, 3) | **EMPTY** |
| (15, 3) | **EMPTY** |

### ROW 4 (y=4): Monsters - Ghosts & Apparitions

| Coords | Description |
|--------|-------------|
| (0, 4) | Pale ghost face (screaming) |
| (1, 4) | Dark floating spirit (shadow) |
| (2, 4) | Cloaked wanderer (traveler ghost) |
| (3, 4) | Ghostly robed figure (translucent) |
| (4, 4) | Possessed painting (framed horror) |
| (5, 4) | Skull-faced wraith |
| (6, 4) | Hooded specter (faceless) |
| (7, 4) | Tentacled dark mass (void creature) |
| (8, 4) | **EMPTY** |
| (9, 4) | **EMPTY** |
| (10, 4) | **EMPTY** |
| (11, 4) | **EMPTY** |
| (12, 4) | **EMPTY** |
| (13, 4) | **EMPTY** |
| (14, 4) | **EMPTY** |
| (15, 4) | **EMPTY** |

### ROW 5 (y=5): Boss Monsters & Major NPCs

| Coords | Description |
|--------|-------------|
| (0, 5) | Warrior with sword (red armor, fighter) |
| (1, 5) | Purple-robed mage (casting) |
| (2, 5) | Skeletal warrior (undead soldier) |
| (3, 5) | White mage (holy magic, light effects) |
| (4, 5) | Valkyrie/female warrior (winged) |
| (5, 5) | Demon king (crowned, boss-tier) |
| (6, 5) | Ornate demon lord face (final boss?) |
| (7, 5) | **EMPTY** |
| (8, 5) | **EMPTY** |
| (9, 5) | **EMPTY** |
| (10, 5) | **EMPTY** |
| (11, 5) | **EMPTY** |
| (12, 5) | **EMPTY** |
| (13, 5) | **EMPTY** |
| (14, 5) | **EMPTY** |
| (15, 5) | **EMPTY** |

### ROW 6 (y=6): Player Portraits - Winged Frame Style

All tiles in this row are player character portraits with dark wing/cloak extensions in oval frames. Slight pose/angle variations.

| Coords | Description |
|--------|-------------|
| (0, 6) | Player portrait variant A (front-facing) |
| (1, 6) | Player portrait variant B |
| (2, 6) | Player portrait variant C |
| (3, 6) | Player portrait variant D |
| (4, 6) | Player portrait variant E |
| (5, 6) | Player portrait variant F |
| (6, 6) | Player portrait variant G |
| (7, 6) | Player portrait variant H |
| (8, 6) | Player portrait variant I |
| (9, 6) | Player portrait variant J |
| (10, 6) | Player portrait variant K |
| (11, 6) | Player portrait variant L |
| (12, 6) | Player portrait variant M |
| (13, 6) | Player portrait variant N |
| (14, 6) | Player portrait variant O |
| (15, 6) | Player portrait variant P |

### ROW 7 (y=7): UI Elements / Inventory Backgrounds

Small colored squares - likely inventory slot backgrounds or UI elements.

| Coords | Description |
|--------|-------------|
| (0, 7) | UI tile - pink/magenta pattern |
| (1, 7) | UI tile - checkered pink |
| (2, 7) | UI tile - dark purple |
| (3, 7) | UI tile - magenta solid |
| (4, 7) | UI tile - pink checkered variant |
| (5, 7) | UI tile - dark checkered |
| (6, 7) | UI tile - purple gradient |
| (7, 7) | UI tile - pink solid |
| (8, 7) | UI tile - checkered dark |
| (9, 7) | UI tile - magenta pattern |
| (10, 7) | UI tile - pink variant |
| (11, 7) | UI tile - checkered |
| (12, 7) | UI tile - dark |
| (13, 7) | UI tile - purple |
| (14, 7) | UI tile - magenta |
| (15, 7) | UI tile - pink |

### ROW 8 (y=8): Player Characters - Armored Warriors (Purple/Dark)

Full-body standing warrior figures in dark/purple armor. Animation frames or race variants.

| Coords | Description |
|--------|-------------|
| (0, 8) | Armored warrior pose A |
| (1, 8) | Armored warrior pose B |
| (2, 8) | Armored warrior pose C |
| (3, 8) | Armored warrior pose D |
| (4, 8) | Armored warrior pose E |
| (5, 8) | Armored warrior pose F |
| (6, 8) | Armored warrior pose G |
| (7, 8) | Armored warrior pose H |
| (8, 8) | Armored warrior pose I |
| (9, 8) | Armored warrior pose J |
| (10, 8) | Armored warrior pose K |
| (11, 8) | Armored warrior pose L |
| (12, 8) | Armored warrior pose M |
| (13, 8) | Armored warrior pose N |
| (14, 8) | Armored warrior pose O |
| (15, 8) | Armored warrior pose P |

### ROW 9 (y=9): Player Portraits - Circular White Frame

Male warrior portraits in circular white/light frames. Portrait variations.

| Coords | Description |
|--------|-------------|
| (0, 9) | Warrior portrait circular A |
| (1, 9) | Warrior portrait circular B |
| (2, 9) | Warrior portrait circular C |
| (3, 9) | Warrior portrait circular D |
| (4, 9) | Warrior portrait circular E |
| (5, 9) | Warrior portrait circular F |
| (6, 9) | Warrior portrait circular G |
| (7, 9) | Warrior portrait circular H |
| (8, 9) | Warrior portrait circular I |
| (9, 9) | Warrior portrait circular J |
| (10, 9) | Warrior portrait circular K |
| (11, 9) | Warrior portrait circular L |
| (12, 9) | Warrior portrait circular M |
| (13, 9) | Warrior portrait circular N |
| (14, 9) | Warrior portrait circular O |
| (15, 9) | Warrior portrait circular P |

### ROW 10 (y=10): Player Characters - Elf/Ranger (Green Hood)

Elven or ranger characters with green hoods. Various poses/angles.

| Coords | Description |
|--------|-------------|
| (0, 10) | Elf ranger pose A (front) |
| (1, 10) | Elf ranger pose B |
| (2, 10) | Elf ranger pose C |
| (3, 10) | Elf ranger pose D |
| (4, 10) | Elf ranger pose E |
| (5, 10) | Elf ranger pose F |
| (6, 10) | Elf ranger pose G |
| (7, 10) | Elf ranger pose H |
| (8, 10) | Elf ranger pose I |
| (9, 10) | Elf ranger pose J |
| (10, 10) | Elf ranger pose K |
| (11, 10) | Elf ranger pose L |
| (12, 10) | Elf ranger pose M |
| (13, 10) | Elf ranger pose N |
| (14, 10) | Elf ranger pose O |
| (15, 10) | Elf ranger pose P |

### ROW 11 (y=11): Terrain - Floor Tiles (Primary)

| Coords | Description |
|--------|-------------|
| (0, 11) | Dark cobblestone floor (dungeon basic) |
| (1, 11) | Runic floor (magical symbols) |
| (2, 11) | Diamond pattern floor (ornate stone) |
| (3, 11) | Green magical floor (poison/acid) |
| (4, 11) | Green glowing floor (toxic variant) |
| (5, 11) | Purple portal floor (magical) |
| (6, 11) | Dark ornate pattern floor |
| (7, 11) | Broken/cracked floor (damaged) |
| (8, 11) | Gray stone brick floor |
| (9, 11) | Stone floor with metal grate |
| (10, 11) | Orange/amber lit floor (torchlit) |
| (11, 11) | **EMPTY** |
| (12, 11) | **EMPTY** |
| (13, 11) | **EMPTY** |
| (14, 11) | **EMPTY** |
| (15, 11) | **EMPTY** |

### ROW 12 (y=12): Terrain - Floor Tiles (Secondary) & Special

| Coords | Description |
|--------|-------------|
| (0, 12) | Dark void/chasm (black pit) |
| (1, 12) | Green gem floor (emerald inlay) |
| (2, 12) | Diamond ornate floor (fancy) |
| (3, 12) | Purple magical floor (arcane) |
| (4, 12) | Dark patterned floor |
| (5, 12) | Stone with purple glow |
| (6, 12) | Cracked stone floor |
| (7, 12) | **EMPTY** |
| (8, 12) | Light gray stone floor |
| (9, 12) | Diagonal stone pattern |
| (10, 12) | Brown/tan floor (earth) |
| (11, 12) | **EMPTY** |
| (12, 12) | **EMPTY** |
| (13, 12) | **EMPTY** |
| (14, 12) | **EMPTY** |
| (15, 12) | **EMPTY** |

### ROW 13 (y=13): Terrain - Walls & Stairs

| Coords | Description |
|--------|-------------|
| (0, 13) | Stone wall (diamond/checkered pattern) |
| (1, 13) | **Stairs down** (descending, dark) |
| (2, 13) | Stone wall variant (brick) |
| (3, 13) | **Stairs up** (ascending, light) |
| (4, 13) | Detailed stone wall |
| (5, 13) | **EMPTY** |
| (6, 13) | Light stone wall (bright) |
| (7, 13) | **EMPTY** |
| (8, 13) | **EMPTY** |
| (9, 13) | Brown/tan stone wall |
| (10, 13) | **EMPTY** |
| (11, 13) | **EMPTY** |
| (12, 13) | **EMPTY** |
| (13, 13) | **EMPTY** |
| (14, 13) | **EMPTY** |
| (15, 13) | **EMPTY** |

### ROW 14 (y=14): Terrain - Doors

| Coords | Description |
|--------|-------------|
| (0, 14) | Wooden door (closed, brown) |
| (1, 14) | Wooden door variant (darker) |
| (2, 14) | Stone doorway (gray arch) |
| (3, 14) | Ornate stone door (decorated) |
| (4, 14) | Metal/iron door (reinforced) |
| (5, 14) | Blue magical door (glowing) |
| (6, 14) | Arched doorway (stone frame) |
| (7, 14) | Orange/lit doorway (warm light) |
| (8, 14) | Diamond pattern door |
| (9, 14) | **EMPTY** |
| (10, 14) | **EMPTY** |
| (11, 14) | **EMPTY** |
| (12, 14) | **EMPTY** |
| (13, 14) | **EMPTY** |
| (14, 14) | **EMPTY** |
| (15, 14) | **EMPTY** |

### ROW 15 (y=15): Terrain - Special & Environment

| Coords | Description |
|--------|-------------|
| (0, 15) | Cracked earth/dry ground |
| (1, 15) | Stone rubble/debris |
| (2, 15) | Dark corridor/passage |
| (3, 15) | Waterfall/water feature (blue) |
| (4, 15) | Cobblestone floor (classic) |
| (5, 15) | **EMPTY** |
| (6, 15) | Gray stone floor (plain) |
| (7, 15) | Golden orb/sphere (artifact/light) |
| (8, 15) | **EMPTY** |
| (9, 15) | Dark stone floor |
| (10, 15) | Dark floor variant |
| (11, 15) | Green slime/poison pool |
| (12, 15) | **EMPTY** |
| (13, 15) | **EMPTY** |
| (14, 15) | **EMPTY** |
| (15, 15) | **EMPTY** |

---

## Quick Reference by Category

### Terrain - Floors (Recommended)
```gdscript
const FLOOR_COBBLESTONE = Vector2i(0, 11)   # Dark cobblestone - default dungeon
const FLOOR_COBBLESTONE_ALT = Vector2i(4, 15) # Classic cobblestone
const FLOOR_RUNIC = Vector2i(1, 11)          # Magical runes
const FLOOR_DIAMOND = Vector2i(2, 11)        # Ornate diamond pattern
const FLOOR_STONE_GRAY = Vector2i(8, 11)     # Plain gray stone
const FLOOR_STONE_BRICK = Vector2i(6, 15)    # Gray stone plain
const FLOOR_TOXIC_GREEN = Vector2i(3, 11)    # Poison/acid area
const FLOOR_PORTAL_PURPLE = Vector2i(5, 11)  # Magical portal
const FLOOR_TORCHLIT = Vector2i(10, 11)      # Orange/warm lit
const FLOOR_BROKEN = Vector2i(7, 11)         # Damaged floor
```

### Terrain - Walls (Recommended)
```gdscript
const WALL_STONE_DIAMOND = Vector2i(0, 13)   # Checkered stone wall
const WALL_STONE_BRICK = Vector2i(2, 13)     # Brick pattern
const WALL_STONE_DETAILED = Vector2i(4, 13)  # Detailed stonework
const WALL_STONE_LIGHT = Vector2i(6, 13)     # Bright/lit wall
const WALL_STONE_BROWN = Vector2i(9, 13)     # Brown/tan wall
```

### Terrain - Stairs
```gdscript
const STAIRS_DOWN = Vector2i(1, 13)          # Descending stairs (dark)
const STAIRS_UP = Vector2i(3, 13)            # Ascending stairs (light)
```

### Terrain - Doors
```gdscript
const DOOR_WOOD_CLOSED = Vector2i(0, 14)     # Basic wooden door
const DOOR_WOOD_DARK = Vector2i(1, 14)       # Darker wooden door
const DOOR_STONE = Vector2i(2, 14)           # Stone doorway
const DOOR_ORNATE = Vector2i(3, 14)          # Decorated stone door
const DOOR_IRON = Vector2i(4, 14)            # Metal reinforced door
const DOOR_MAGIC_BLUE = Vector2i(5, 14)      # Magical glowing door
const DOOR_ARCH = Vector2i(6, 14)            # Arched stone doorway
const DOOR_LIT = Vector2i(7, 14)             # Warm lit doorway
```

### Terrain - Special
```gdscript
const CHASM_VOID = Vector2i(0, 12)           # Black pit/void
const RUBBLE = Vector2i(1, 15)               # Stone debris
const WATER = Vector2i(3, 15)                # Waterfall/water
const SLIME_POOL = Vector2i(11, 15)          # Green poison pool
const CRACKED_EARTH = Vector2i(0, 15)        # Dry cracked ground
const GOLDEN_ORB = Vector2i(7, 15)           # Light source/artifact
```

### Player Characters
```gdscript
# Elf/Ranger (green hood) - Row 10
const PLAYER_ELF_DEFAULT = Vector2i(0, 10)

# Armored Warrior (purple/dark) - Row 8
const PLAYER_WARRIOR_DEFAULT = Vector2i(0, 8)

# Portrait with wings (oval frame) - Row 6
const PLAYER_PORTRAIT_WINGED = Vector2i(0, 6)

# Portrait circular (white frame) - Row 9
const PLAYER_PORTRAIT_CIRCULAR = Vector2i(0, 9)
```

### Monsters - Demons
```gdscript
const MONSTER_DEMON_HULK = Vector2i(0, 2)       # Red hulking demon
const MONSTER_DEMON_PALE = Vector2i(2, 2)       # White horned demon
const MONSTER_DEMON_WINGED = Vector2i(3, 2)     # Bat-like creature
const MONSTER_DEMON_KING = Vector2i(5, 5)       # Crowned demon boss
const MONSTER_DEMON_LORD = Vector2i(6, 5)       # Final boss face
```

### Monsters - Undead
```gdscript
const MONSTER_WRAITH = Vector2i(1, 2)           # Dark floating specter
const MONSTER_GHOST = Vector2i(1, 3)            # Wispy ghost
const MONSTER_SKELETON = Vector2i(2, 5)         # Skeletal warrior
const MONSTER_UNDEAD_KNIGHT = Vector2i(0, 3)    # Dark armored undead
const MONSTER_SKULL_WRAITH = Vector2i(5, 4)     # Skull-faced wraith
```

### Monsters - Eldritch/Horror
```gdscript
const MONSTER_TENTACLE = Vector2i(5, 2)         # Lovecraftian horror
const MONSTER_CTHULHU = Vector2i(4, 3)          # Tentacle monster
const MONSTER_VOID_MASS = Vector2i(7, 4)        # Dark tentacled void
const MONSTER_SPIDER = Vector2i(5, 3)           # Spider creature
```

### Monsters - Spirits/Ghosts
```gdscript
const MONSTER_NECROMANCER = Vector2i(4, 2)      # Purple robed caster
const MONSTER_REAPER = Vector2i(6, 2)           # Tall death figure
const MONSTER_MASKED = Vector2i(2, 3)           # White mask figure
const MONSTER_HAUNTED_PORTRAIT = Vector2i(7, 3) # Creepy painting
const MONSTER_POSSESSED_PAINTING = Vector2i(4, 4) # Framed horror
const MONSTER_GHOST_FACE = Vector2i(0, 4)       # Screaming ghost
const MONSTER_SHADOW = Vector2i(1, 4)           # Dark shadow spirit
```

### NPCs / Special Characters
```gdscript
const NPC_WARRIOR_RED = Vector2i(0, 5)          # Red armored fighter
const NPC_MAGE_PURPLE = Vector2i(1, 5)          # Purple robed mage
const NPC_MAGE_WHITE = Vector2i(3, 5)           # Holy/light mage
const NPC_VALKYRIE = Vector2i(4, 5)             # Winged female warrior
```

### Items - Consumables
```gdscript
const ITEM_POTION_RED = Vector2i(0, 0)          # Health potion
const ITEM_TORCH = Vector2i(2, 0)               # Lit torch
const ITEM_SCROLL = Vector2i(8, 0)              # Rolled scroll
const ITEM_GEM_RED = Vector2i(9, 0)             # Red crystal
const ITEM_FEATHER = Vector2i(11, 0)            # White feather
```

### Items - Weapons
```gdscript
const ITEM_SWORD = Vector2i(0, 1)               # Ornate sword
const ITEM_DAGGER = Vector2i(1, 1)              # Small dagger
const ITEM_STAFF = Vector2i(2, 1)               # Magic staff
const ITEM_SCEPTER = Vector2i(3, 1)             # Royal scepter
const ITEM_CROSSBOW = Vector2i(4, 1)            # Crossbow
const ITEM_AXES = Vector2i(5, 1)                # Crossed axes
```

### Items - Armor
```gdscript
const ITEM_CROWN = Vector2i(6, 1)               # Royal crown
const ITEM_CHESTPLATE = Vector2i(8, 1)          # Body armor
const ITEM_HELMET = Vector2i(11, 1)             # Knight helmet
const ITEM_BOOTS = Vector2i(12, 1)              # Armored boots
const ITEM_GLOVES = Vector2i(13, 1)             # Gauntlets
const ITEM_RING = Vector2i(14, 1)               # Magic ring
const ITEM_SHIELD = Vector2i(15, 1)             # Decorative shield
```

### Items - Containers & Special
```gdscript
const ITEM_CHEST = Vector2i(4, 0)               # Treasure chest
const ITEM_CAMPFIRE = Vector2i(3, 0)            # Campfire/brazier
const ITEM_ARTIFACT_DARK = Vector2i(1, 0)       # Cursed orb
const ITEM_ARTIFACT_CUBE = Vector2i(10, 1)      # Puzzle box
```

### Effects
```gdscript
const EFFECT_FIRE = Vector2i(12, 0)             # Fireball/flame
const EFFECT_MAGIC_PURPLE = Vector2i(13, 0)     # Purple magic burst
const EFFECT_LIGHT = Vector2i(14, 0)            # White sparkle
```

---

## Usage Example for Claude Code

When configuring tiles in GDScript:

```gdscript
# In tile_mapper.gd or similar

func _load_terrain_mappings() -> void:
    # Use the exact coordinates from this reference
    terrain_tiles[Tile.FLOOR] = Vector2i(0, 11)      # Dark cobblestone
    terrain_tiles[Tile.WALL] = Vector2i(0, 13)       # Diamond stone wall
    terrain_tiles[Tile.STAIRS_DOWN] = Vector2i(1, 13)
    terrain_tiles[Tile.STAIRS_UP] = Vector2i(3, 13)
    terrain_tiles[Tile.DOOR_CLOSED] = Vector2i(0, 14)
    terrain_tiles[Tile.DOOR_OPEN] = Vector2i(6, 14)  # Arched doorway
    terrain_tiles[Tile.CHASM] = Vector2i(0, 12)      # Void pit
    terrain_tiles[Tile.RUBBLE] = Vector2i(1, 15)     # Stone debris

func _load_monster_mappings() -> void:
    monster_tiles["spider"] = Vector2i(5, 3)
    monster_tiles["wraith"] = Vector2i(1, 2)
    monster_tiles["demon"] = Vector2i(0, 2)
    monster_tiles["ghost"] = Vector2i(1, 3)
    monster_tiles["skeleton"] = Vector2i(2, 5)
```

---

## Notes

1. **Empty tiles** are marked with magenta background - avoid using these coordinates
2. **Rows 6-10** contain player character variations - use for race/class selection or animation
3. **Row 7** appears to be UI elements, not game tiles
4. The tileset has a dark fantasy/necromancer aesthetic throughout
5. All coordinates are verified against the actual 1024x1024 PNG at 64x64 tile size
