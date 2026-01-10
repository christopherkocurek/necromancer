# The Necromancer - Symbol Audit

Generated for tileset PRD AUDIT-001.

## Summary Statistics

| Category | Count |
|----------|-------|
| Monster Symbols | 24 unique |
| Terrain Symbols | 18 unique |
| Object Symbols | 21 unique |
| **Total Unique Symbols** | ~50 |
| **Total Sprite Requirements** | ~82 (with variants) |

---

## 1. Monster Symbols

### Player
| Symbol | Color | Name | Count |
|--------|-------|------|-------|
| `@` | w (white) | Player | 4 variants |

### Creatures by Symbol

| Symbol | Colors | Monster Types | Count |
|--------|--------|---------------|-------|
| `@` | w, s, v, D, U, G, b, B, u, o, r1 | Player, Humans (Acolytes, Sorcerers, Warriors, Gandalf, etc.) | 20+ |
| `M` | u, W, D, G | Spiders (Mirkwood, Web Spinner, Great Spider, Broodmother) | 4 |
| `r` | u, D | Rats, Squirrels | 2 |
| `b` | D, s, y | Birds (Crebain, Giant Bat, Eagle) | 3 |
| `&` | g | Tanglethorn (plant monster) | 1 |
| `C` | u, s, W | Wolves/Wargs (Pup, Warg, Gashnak) | 3 |
| `o` | D, W, s, U, r, R | Orcs (Scout, Soldier, Crossbowman, Captain, etc.) | 8 |
| `s` | g | Serpent (Swamp Adder) | 1 |
| `T` | W, D, r, s | Trolls (Hill, Mirk, Karvag, Olog-hai) | 5 |
| `z` | s, G, w, W, u | Undead (Ghoul, Ghast, Skeleton, Zombie, Bone Golem) | 6 |
| `W` | U, W, v, s, d, D, r | Wraiths/Wights (Wight, Barrow-wight, Wraith, Greater Wraith, Nazgûl) | 9 |
| `w` | y, s, D, v, w | Spirits (Corpse-candle, Phantom, Shade, Spectre, Fell Spirit) | 5 |
| `v` | s, W, v1 | Vampires (Thrall, Vampire, Vampire Lord) | 3 |
| `H` | W | Horror (Wailing Horror) | 1 |
| `R` | v | Maia Thrall | 1 |
| `q` | U | Quadruped (Great Elk - hallucinatory) | 1 |

### Color Legend
```
w = White       W = Light Gray    s = Gray       D = Dark Gray/Black
r = Red         R = Light Red     g = Green      G = Light Green
b = Blue        B = Light Blue    u = Brown      U = Light Brown
y = Yellow      o = Orange        v = Violet     d = Flavored
1 = Bright/alternate shade
```

---

## 2. Terrain Symbols

| Symbol | Colors | Terrain Types | Count |
|--------|--------|---------------|-------|
| ` ` (space) | w | Darkness | 1 |
| `.` | s, y, g, u, r | Floor (open, daylight, vine, forest, bloodstain) | 5 |
| `#` | D, W1, s, u | Walls (stone, hidden passage, prison bars, roots) | 4 |
| `+` | U, U1, G, B, v | Doors (iron, jammed, warded power 1-3) | 5 |
| `'` | U, s | Open/Shattered doors | 2 |
| `<` | W, D | Stairs up (crumbling, narrow shaft) | 2 |
| `>` | W, D | Stairs down (dark, narrow shaft) | 2 |
| `^` | U, s, W, v1, G1, B1, U1, y, w, D1, D, r, u | Traps (13 variants) | 13 |
| `%` | D, w | Pits, Quartz veins | 2 |
| `;` | G1 | Protective rune | 1 |
| `~` | D, G | Pools (dark, poison stream) | 2 |
| `*` | v | Morgul runes | 1 |
| `0` | D, s, v | Forges (orc, shadow, Angdur) | 3 |
| `&` | r | Torture rack | 1 |
| `\` | s | Chains | 1 |
| `:` | s | Fallen masonry | 1 |
| `1` | s | Tileset lookup markers | 1 |

---

## 3. Object Symbols

### Weapons
| Symbol | Colors | Item Types | Count |
|--------|--------|------------|-------|
| `|` | w, s, W, B | Swords (Knife, Orc-blade, Longsword, Mithril) | 6 |
| `/` | U, u, s | Polearms/Axes (Spear, Glaive, Axe) | 5 |
| `\` | U, D1, D, s | Blunt weapons (Staff, Hammer, Mattock) | 4 |
| `}` | u, U, U1 | Bows (Silvan, Longbow, Dragon-horn) | 3 |
| `-` | U | Arrows | 1 |

### Armor
| Symbol | Colors | Item Types | Count |
|--------|--------|------------|-------|
| `(` | b, U, U1, D, g, D1, W | Body armor (Robes, Leather, Mail, Cloaks) | 7 |
| `[` | W, s1, B | Heavy armor (Corslet, Hauberk, Mithril) | 3 |
| `]` | s1, s, W, B, U, y | Helms, Boots, Gloves, Crown | 8 |
| `)` | s, W, B | Shields (Buckler, Tower, Mithril) | 3 |

### Jewelry & Magic
| Symbol | Colors | Item Types | Count |
|--------|--------|------------|-------|
| `=` | various | Rings (21 flavors: Amethyst, Beryl, Ruby, etc.) | 21 |
| `"` | various | Amulets (15 flavors: Amber, Coral, Pearl, etc.) | 15 |
| `_` | various | Staves (19 flavors: Aspen, Birch, Oak, etc.) | 19 |
| `-` | w, r, B, y, s, v | Wands (Birch, Rowan, Ash, Oak, Willow, Yew) | 6 |
| `?` | W, U, w, W1, U1, s, d | Horns/Flutes | 7 |

### Consumables
| Symbol | Colors | Item Types | Count |
|--------|--------|------------|-------|
| `!` | various | Potions (29 flavors: Clear, Blue, Black, etc.) | 29 |
| `,` | various | Herbs/Food (20 flavors: Black, Green, Yellow, etc.) | 20 |

### Other Objects
| Symbol | Colors | Item Types | Count |
|--------|--------|------------|-------|
| `~` | w, u, U, B, s, v1, v, W, r, D1, W1 | Misc (Skeletons, Torches, Lanterns, Chests, Notes, Mithril) | 12 |
| `*` | B, w | Light sources (Elven Light, Star-glass) | 2 |
| `&` | w | Pile (multiple items) | 1 |

---

## 4. Required Sprite Categories (PRD Target: 82)

### High Priority (Core Gameplay)
1. **Player Character** (1 sprite, multiple poses possible)
2. **Common Monsters** (~25 sprites)
   - Spiders: 4 variants
   - Orcs: 8 variants
   - Undead: 6 variants
   - Wolves: 3 variants
   - Trolls: 5 variants
3. **Boss Monsters** (~8 sprites)
   - Broodmother, Orc Warchief, Master Sorcerer, Grishnákh, Úvatha, Khamûl, Sauron

### Medium Priority (Dungeon Environment)
4. **Terrain** (~18 sprites)
   - Floors: 5 variants
   - Walls: 4 variants
   - Doors: 5 variants
   - Stairs: 4 variants
   - Special: forges, runes, pools
5. **Traps** (13 sprites)
   - Each trap type needs distinct visual

### Lower Priority (Items)
6. **Weapons** (~10 sprites)
7. **Armor** (~10 sprites)
8. **Consumables** (potions, herbs - can use color variants)
9. **Jewelry** (rings, amulets - can use color variants)

---

## 5. Symbol-to-Sprite Mapping Notes

### Shared Symbols (Context Required)
- `@` - Used for both player AND human NPCs (sorcerers, warriors)
- `&` - Used for item pile AND tanglethorn monster AND torture rack
- `~` - Used for multiple object types (skeletons, lights, chests, notes)
- `-` - Used for arrows AND wands
- `\` - Used for blunt weapons AND chains terrain

### Color Differentiation Critical For
- Orcs (`o`): 6 different colors = different orc types
- Wraiths (`W`): 7 colors = different power levels
- Undead (`z`): 5 colors = skeleton vs ghoul vs zombie
- Spirits (`w`): 5 colors = different incorporeal types

### Unique Visual Design Needed
- Sauron (`@:r1`) - Must be visually distinct from other `@` humans
- Nazgûl (`W:D1`, `W:r`) - Distinguished from regular wraiths
- Boss monsters need larger/more detailed sprites

---

## 6. Recommended Sprite Count by Category

| Category | Minimum | Ideal |
|----------|---------|-------|
| Player | 1 | 1 |
| Monsters | 40 | 50 |
| Terrain | 15 | 25 |
| Items | 20 | 30 |
| Effects | 5 | 10 |
| UI Elements | 5 | 10 |
| **TOTAL** | **86** | **126** |

The PRD target of 82 sprites is achievable with:
- 1 player
- 45 monsters (combining some variants)
- 20 terrain
- 12 items (using color tinting for variants)
- 4 effects
