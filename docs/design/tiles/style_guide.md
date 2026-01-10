# The Necromancer - Tileset Style Guide

Version 1.0 | DESIGN-002

## 1. Core Principles

### 1.1 Readability First
**Function over form. If players can't tell what something is at a glance, it fails.**

- Every sprite must have a **distinct silhouette**
- Character/monster sprites are **recognizable even at 50% zoom**
- Item sprites clearly indicate **function, not just appearance**

### 1.2 Cohesive Dark Fantasy
All sprites share:
- The **32-color Necromancer palette** (see palette.md)
- **Top-left lighting** direction
- **1-2px black outline** on characters/monsters
- **Minimal dithering** (texture, not noise)

### 1.3 Evil = Angular, Good = Flowing
- **Enemy sprites**: Sharp angles, jagged edges, harsh shapes
- **Player sprites**: Rounder forms, flowing lines, elegant proportions
- This subconsciously communicates threat vs. safety

---

## 2. Technical Specifications

| Property | Value |
|----------|-------|
| Tile Size | 32x32 pixels |
| Format | PNG with alpha |
| Color Depth | 32-bit RGBA |
| Palette | 32 colors (see palette.md) |
| Outline | 1px `#0a0a12` on characters |
| Background | Transparent (not black) |
| Scaling | Nearest neighbor ONLY |
| Anti-aliasing | NEVER |

---

## 3. Sprite Categories & Rules

### 3.1 Player Characters

**Purpose**: Clearly distinguish from enemies, show race identity

```
┌────────────────────────┐
│  PLAYER SPRITE RULES   │
├────────────────────────┤
│ • Upright posture      │
│ • Facing front/right   │
│ • Weapon visible       │
│ • Hood/helm optional   │
│ • Silver/Gold/Blue     │
│   color accents        │
│ • 1px black outline    │
│ • Fill ~60% of tile    │
└────────────────────────┘
```

**Silhouette Requirements**:
- Elf: Tall, slender, pointed ears visible
- Dwarf: Short, stocky, beard/helm distinct
- Man: Medium height, ranger cloak/hood

### 3.2 Monsters - Humanoid

**Purpose**: Clear threat indicators, distinguishable from each other

```
┌────────────────────────┐
│   HUMANOID MONSTERS    │
├────────────────────────┤
│ • Hunched/aggressive   │
│ • Weapon raised        │
│ • Different silhouette │
│   from player          │
│ • Darker colors        │
│ • Yellow/red eyes      │
│ • 1px outline          │
└────────────────────────┘
```

**Differentiation by Color**:
| Monster | Primary Color | Eye Color |
|---------|---------------|-----------|
| Orc | Green-gray | Yellow |
| Orc Captain | Red markings | Yellow |
| Troll | Gray-brown | Tiny dark |
| Evil Man | Pale/dark | Hidden |

### 3.3 Monsters - Undead

**Purpose**: Communicate supernatural horror, ethereal threat

```
┌────────────────────────┐
│    UNDEAD MONSTERS     │
├────────────────────────┤
│ • Ethereal edges       │
│ • Glowing eyes/aura    │
│ • Skeletal/spectral    │
│ • Violet/gray tones    │
│ • Can be translucent   │
│ • Outline optional     │
│   for ghosts           │
└────────────────────────┘
```

**Undead Hierarchy**:
- Skeleton: Full bone structure visible
- Wight: Corpse in armor, solid
- Wraith: Hooded, face hidden
- Barrow-wight: Crown, ancient armor
- Ghost: Translucent, no outline

### 3.4 Monsters - Beasts

**Purpose**: Recognizable animal forms, clearly hostile

```
┌────────────────────────┐
│    BEAST MONSTERS      │
├────────────────────────┤
│ • Animal silhouette    │
│ • Aggressive pose      │
│ • Exaggerated features │
│ • Dark/corrupted color │
│ • 1px outline          │
│ • Fill 50-70% of tile  │
└────────────────────────┘
```

### 3.5 Boss Monsters

**Purpose**: Memorable, intimidating, iconic

```
┌────────────────────────┐
│    BOSS MONSTERS       │
├────────────────────────┤
│ • Larger than normal   │
│ • More detail allowed  │
│ • Unique color accent  │
│ • Strongest silhouette │
│ • Consider glow effect │
│ • Fill 80-100% of tile │
└────────────────────────┘
```

**Boss Priorities**:
1. **Sauron**: Most important. Eye motif, absolute dread.
2. **Nazgûl**: Black robes, Morgul blade, mounted or standing
3. **Khamûl**: Distinct from other Nazgûl (red accent)
4. **Warchief/Broodmother**: Layer bosses, larger versions

---

## 4. Terrain Rules

### 4.1 Floors

```
┌────────────────────────┐
│      FLOOR TILES       │
├────────────────────────┤
│ • Flat, low detail     │
│ • Subtle variation     │
│ • No strong shapes     │
│ • Tileable patterns    │
│ • Doesn't distract     │
└────────────────────────┘
```

**DON'T** make floors eye-catching. They're background.

### 4.2 Walls

```
┌────────────────────────┐
│      WALL TILES        │
├────────────────────────┤
│ • Clearly impassable   │
│ • 3D depth illusion    │
│ • Top edge lighter     │
│ • Bottom edge darker   │
│ • Distinct from floor  │
└────────────────────────┘
```

### 4.3 Doors & Stairs

```
┌────────────────────────┐
│   INTERACTIVE TERRAIN  │
├────────────────────────┤
│ • Clear function       │
│ • State visible:       │
│   - Open vs closed     │
│   - Up vs down         │
│ • More detail than     │
│   basic terrain        │
│ • Interact invitation  │
└────────────────────────┘
```

---

## 5. Item Rules

### 5.1 Weapons

```
┌────────────────────────┐
│       WEAPONS          │
├────────────────────────┤
│ • Business end visible │
│ • Diagonal orientation │
│ • Type clear: sword vs │
│   axe vs bow           │
│ • Handle secondary     │
│ • 45° angle standard   │
└────────────────────────┘
```

**Weapon Silhouettes**:
```
Sword: Long blade, crossguard
  │
  ├──

Axe: Curved head, short handle
  ╱
 ├─

Bow: Curved arc, string line
  )
 ───

Staff: Long vertical, gnarled
  │
  │
  ⌐
```

### 5.2 Armor

```
┌────────────────────────┐
│        ARMOR           │
├────────────────────────┤
│ • Show most distinct   │
│   piece                │
│ • Helm = top view/front│
│ • Body = front/folded  │
│ • Boots = side view    │
│ • Shield = front       │
└────────────────────────┘
```

### 5.3 Consumables

```
┌────────────────────────┐
│     CONSUMABLES        │
├────────────────────────┤
│ • Small and simple     │
│ • Color differentiates │
│ • Shape indicates type │
│ • Potion = bottle      │
│ • Herb = leaves        │
│ • Ring = band + gem    │
└────────────────────────┘
```

**Color Tinting**: Create one base potion/herb, tint for variants

---

## 6. Lighting & Shading

### 6.1 Light Direction

**ALL sprites use top-left lighting**:

```
    ☀️ Light source
     ╲
      ╲
       ╲
    ┌───┴───┐
    │ LIGHT │
    │       │
    │  DARK │
    └───────┘
         Shadow
```

- Top-left corner: Brightest
- Bottom-right: Darkest/shadow
- This creates consistent 3D depth

### 6.2 Shading Levels

Use 3-4 shades per color area:
1. **Highlight**: Top-left edge
2. **Mid-tone**: Main fill
3. **Shadow**: Bottom-right
4. **Deep shadow**: Optional, corners

```
Example: Gray wall
┌──────────┐
│▓▓▓▓▓▓▓▓▓▓│  ← Highlight
│▓▒▒▒▒▒▒▒▓│
│▓▒▒▒▒▒▒▒▓│  ← Mid-tone
│▓▒▒▒▒░░░▓│
│▓░░░░░░░▓│  ← Shadow
│░░░░░░░░░│  ← Deep shadow
└──────────┘
```

---

## 7. Do's and Don'ts

### ✅ DO

- **DO** test sprites at actual game resolution
- **DO** use the official palette only
- **DO** make silhouettes distinct
- **DO** add 1px outline to characters
- **DO** keep floor tiles subtle
- **DO** make interactive elements obvious
- **DO** generate multiple variants, pick best
- **DO** prioritize function over beauty

### ❌ DON'T

- **DON'T** use pure black (#000000) - use Void Black (#0a0a12)
- **DON'T** use pure white except UI text
- **DON'T** anti-alias or blur edges
- **DON'T** make floors eye-catching
- **DON'T** make similar monsters same color
- **DON'T** forget transparency
- **DON'T** use gradients (dithering only)
- **DON'T** exceed 32 colors

---

## 8. AI Generation Guidelines

### 8.1 Prompt Structure

```
[style] + [subject] + [pose] + [colors] + [technical]
```

### 8.2 Style Keywords (Use in ALL prompts)

```
pixel art, 32x32, dark fantasy, roguelike game sprite,
transparent background, top-left lighting, black outline,
no anti-aliasing, limited palette, inspired by Dwarf Fortress,
Caves of Qud style, clear silhouette
```

### 8.3 Example Prompts

**Orc**:
```
pixel art, 32x32 sprite, dark fantasy orc warrior,
hunched aggressive pose, crude weapon raised,
green-gray skin, yellow glowing eyes, rusted armor,
1px black outline, transparent background,
top-left lighting, roguelike game style
```

**Wraith**:
```
pixel art, 32x32 sprite, ethereal wraith specter,
hooded figure, no visible face, tattered black robes,
glowing purple-white eyes, wispy edges,
transparent/ghostly, dark fantasy horror,
roguelike game, limited palette
```

**Sword**:
```
pixel art, 32x32 item sprite, medieval longsword,
45 degree angle, blade prominent, simple crossguard,
steel gray with highlights, no background,
roguelike inventory icon style
```

### 8.4 Post-Processing Checklist

After AI generation:
- [ ] Resize to exactly 32x32 (nearest neighbor)
- [ ] Remap to official palette
- [ ] Add/fix 1px outline
- [ ] Verify transparency
- [ ] Check silhouette readability
- [ ] Compare to existing sprites for consistency

---

## 9. Quick Reference Card

```
╔═══════════════════════════════════════════════╗
║         NECROMANCER TILESET CHECKLIST          ║
╠═══════════════════════════════════════════════╣
║ □ 32x32 pixels exactly                        ║
║ □ PNG with alpha transparency                 ║
║ □ 32-color palette only                       ║
║ □ Top-left lighting                           ║
║ □ 1px outline on characters                   ║
║ □ No anti-aliasing                            ║
║ □ Distinct silhouette                         ║
║ □ Void Black (#0a0a12) not pure black        ║
║ □ Tests readable at game resolution           ║
╚═══════════════════════════════════════════════╝
```
