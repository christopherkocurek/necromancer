# Necromancer Tileset - Style Guide

## Visual Aesthetic

**Theme**: Dark fantasy roguelike, Tolkien-esque Third Age Middle-earth
**Setting**: Dol Guldur dungeon, corrupted by Sauron's influence

### Color Palette

```
Primary (Dark tones):
  #1a1a2e - Deep purple-black (void, shadows)
  #16213e - Dark blue (night sky, deep dungeon)
  #0f3460 - Midnight blue (stone, metal)

Secondary (Accents):
  #533483 - Royal purple (magic, corruption)
  #6b48a8 - Bright purple (spells, effects)

Highlights:
  #e94560 - Blood red (danger, fire)
  #ff6b6b - Bright red (critical, boss)

Neutral:
  #f5f5f5 - Bone white (skeleton, undead)
  #c4c4c4 - Steel grey (armor, weapons)

Special:
  #FF00FF - Magenta (MUST be used for transparency background)
```

### Technical Requirements

- **Tile Size**: 64x64 pixels
- **Background**: Solid magenta (#FF00FF) for transparency
- **Style**: Clean pixel art edges, no anti-aliasing on edges
- **View Angles**:
  - Terrain: Top-down
  - Monsters: Side view, facing right
  - Items: Front view or 3/4 view
  - Players: Front-facing portrait

---

## Dungeon Tier Themes

### Tier 1: Forest Breach (Depths 1-3)
**Theme**: Corrupted Mirkwood
- Twisted roots and vines
- Purple-tinted moss
- Spider webs
- Sickly green undertones

**Light variant**: Torch-lit, warm orange glow
**Dark variant**: Cold, desaturated, murky

### Tier 2: Orc Warrens (Depths 3-6)
**Theme**: Military encampment
- Rough-hewn stone
- Crude torchlight
- Bloodstains and debris
- Iron fixtures

**Light variant**: Flickering torchlight, orange-yellow
**Dark variant**: Cold grey stone

### Tier 3: Torture Halls (Depths 6-9)
**Theme**: Horror and cruelty
- Iron grating
- Rusted chains
- Dark metal
- Sickly yellow-green light

**Light variant**: Sickly yellow torchlight
**Dark variant**: Black iron, oppressive

### Tier 4: Necropolis (Depths 9-12)
**Theme**: City of the dead
- Bone-white stone
- Skull motifs
- Ghostly blue-green glow
- Crypts and tombs

**Light variant**: Ethereal glow, ghostly
**Dark variant**: Deathly grey, cold

### Tier 5: Wraith Domain (Depths 12-15)
**Theme**: Incorporeal horror
- Spectral mist
- Shadow-touched stone
- Purple wraith-fire
- Reality distortion

**Light variant**: Purple spectral light
**Dark variant**: Void black, barely visible

### Tier 6: Inner Sanctum (Depths 15-18)
**Theme**: Sauron's throne
- Obsidian black
- Molten fire cracks
- Eye of Sauron motifs
- Red and orange accents

**Light variant**: Fire-lit red glow
**Dark variant**: Obsidian void

### Tier 7: Pits of Despair (Depths 18-20)
**Theme**: Ultimate darkness
- Void stone
- Reality-warping cracks
- Absolute darkness
- Eldritch horror

**Light variant**: Faint corruption glow
**Dark variant**: Pure void

---

## Prompt Templates

### Monsters

```
{monster_name}, dark fantasy creature, roguelike game sprite, 64x64 pixel art,
centered on solid magenta (#FF00FF) background, side view facing right,
menacing pose, {tier_theme} theme,
{description},
clean pixel edges, isolated game asset, dark purple shadows
```

### Terrain

```
{terrain_name}, {terrain_type} tile, roguelike style, 64x64 pixel art,
centered on solid magenta (#FF00FF) background, {view_angle},
{lighting_description},
clean pixel edges, isolated game asset
```

### Items

```
{item_name}, dark fantasy {item_type}, roguelike item sprite, 64x64 pixel art,
centered on solid magenta (#FF00FF) background, {view_angle},
detailed craftsmanship, {description},
clean pixel edges, isolated game asset
```

### Artifacts

```
{artifact_name}, legendary artifact, dark fantasy roguelike style, 64x64 pixel art,
centered on solid magenta (#FF00FF) background, front view,
glowing with magical power, unique and ornate design,
{description},
clean pixel edges, isolated game asset, subtle magical aura
```

### Player Characters

```
{race} {house} adventurer, {race_description}, {house_aesthetic},
dark fantasy roguelike style, 64x64 pixel art character portrait,
centered on solid magenta (#FF00FF) background, front-facing view,
heroic pose ready for adventure,
clean pixel edges, isolated game asset
```

### Status Effects

```
status effect icon: {effect_name}, {visual_description}, roguelike UI element, 64x64 pixel art,
centered on solid magenta (#FF00FF) background,
{effect_description} overlay effect that can be composited on characters,
semi-transparent magical effect,
clean pixel edges, isolated game asset
```

---

## Door Pairing Rules

**CRITICAL**: Open and closed doors MUST be visually identical except for position.

When generating door pairs:
1. Generate closed door first
2. Use EXACT same prompt for open door, only changing "CLOSED" to "OPEN"
3. Same materials, same decorations, same color scheme
4. Only difference is door position (closed = blocking, open = ajar)

---

## Light/Dark Variant Rules

For terrain, EVERY tile needs light and dark variants:

**Light Variant**:
- Full color saturation
- Warm lighting (torch, fire)
- Visible detail
- Used when tile is in player's FOV

**Dark Variant**:
- Desaturated colors (reduce saturation 50-70%)
- Cool lighting (blue-grey tint)
- Reduced detail visibility
- Used when tile is outside FOV but remembered

---

## Quality Control Checklist

Before accepting a generated sprite:

- [ ] Background is pure magenta (#FF00FF)
- [ ] Sprite is centered in 64x64 area
- [ ] Clean pixel edges (no anti-aliased blur)
- [ ] Correct facing direction (monsters face right)
- [ ] Appropriate tier theme
- [ ] Sufficient detail visible
- [ ] No artifacts or noise in magenta area
- [ ] Color palette matches style guide
