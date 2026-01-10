# The Necromancer - Official Color Palette

Version 1.0 | 32 colors total

## Palette Philosophy

This palette is designed to evoke:
- **Dol Guldur**: Ancient, corrupted, oppressive darkness
- **Mirkwood**: Sickly, poisoned nature
- **Third Age**: Medieval fantasy, Tolkien aesthetic
- **Evil Awakening**: Sauron's growing power

Limited palette ensures visual cohesion across all 82+ sprites.

---

## Primary Colors (8)

### Darkness & Shadow
| Name | Hex | RGB | Use |
|------|-----|-----|-----|
| Void Black | `#0a0a12` | 10,10,18 | Background, deep shadow (NOT pure black) |
| Shadow Purple | `#2a1a2a` | 42,26,42 | Evil magic, Nazgûl, darkness effects |
| Stone Gray | `#4a4a5c` | 74,74,92 | Walls, metal, neutral surfaces |
| Fog Gray | `#5a5a6a` | 90,90,106 | Remembered terrain, fog of war |

### Evil & Danger
| Name | Hex | RGB | Use |
|------|-----|-----|-----|
| Blood Red | `#8b0000` | 139,0,0 | Danger, health, wounds, Sauron accent |
| Fire Orange | `#ff6600` | 255,102,0 | Fire, forges, Eye of Sauron |
| Flame Yellow | `#ffcc00` | 255,204,0 | Bright fire, gold accents |
| Corruption Violet | `#6b3a6b` | 107,58,107 | Wraiths, dark magic, curse |

---

## Secondary Colors (8)

### Nature (Corrupted)
| Name | Hex | RGB | Use |
|------|-----|-----|-----|
| Mirkwood Green | `#2d4a3e` | 45,74,62 | Poisoned forest, venom |
| Sickly Green | `#4a6b3a` | 74,107,58 | Ghouls, poison, disease |
| Dead Grass | `#5a5a3a` | 90,90,58 | Withered vegetation |
| Rotting Brown | `#3d2b1f` | 61,43,31 | Decay, dirt, dead wood |

### Materials
| Name | Hex | RGB | Use |
|------|-----|-----|-----|
| Rusted Iron | `#6b3a2a` | 107,58,42 | Orc equipment, old metal |
| Dark Wood | `#5c4033` | 92,64,51 | Doors, chests, handles |
| Bone White | `#d4c8b8` | 212,200,184 | Skeletons, light sources |
| Flesh Pink | `#c9a090` | 201,160,144 | Human skin tones |

---

## Accent Colors (8)

### Player/Good
| Name | Hex | RGB | Use |
|------|-----|-----|-----|
| Elven Silver | `#c0c0c0` | 192,192,192 | Elven items, hope, mithril |
| Dwarf Gold | `#d4a84b` | 212,168,75 | Dwarven craft, treasure |
| Steel Blue | `#4a6a8a` | 74,106,138 | Man items, water, ice |
| Forest Green | `#3a5a3a` | 58,90,58 | Healthy nature, herbs |

### Magic & Special
| Name | Hex | RGB | Use |
|------|-----|-----|-----|
| Magic Blue | `#0066cc` | 0,102,204 | Magical effects, enchantment |
| Deep Purple | `#4a2a5a` | 74,42,90 | High magic, Nazgûl weapons |
| Pale Yellow | `#c9c990` | 201,201,144 | Light effects, torches |
| Ice Blue | `#6b8ea6` | 107,142,166 | Cold effects, frost |

---

## UI Colors (8)

| Name | Hex | RGB | Use |
|------|-----|-----|-----|
| Health Red | `#aa0000` | 170,0,0 | Health bar, damage |
| Mana Blue | `#0044aa` | 0,68,170 | Voice/mana bar |
| XP Gold | `#ccaa00` | 204,170,0 | Experience, currency |
| Cursor Yellow | `#ffff00` | 255,255,0 | Targeting, selection |
| UI White | `#ffffff` | 255,255,255 | Text, highlights |
| UI Gray | `#888888` | 136,136,136 | Disabled, secondary |
| Success Green | `#00aa00` | 0,170,0 | Positive feedback |
| Warning Orange | `#ff8800` | 255,136,0 | Caution, alerts |

---

## Color Rules

### DO
- Use Void Black (`#0a0a12`) instead of pure black
- Apply consistent top-left lighting (highlights top-left, shadows bottom-right)
- Use Fire Orange/Flame Yellow sparingly for evil emphasis
- Keep player colors (Silver, Gold, Steel Blue) distinct from enemy colors
- Use Corruption Violet for magical/undead threats

### DON'T
- Never use pure white (`#ffffff`) except in UI
- Never use saturated blues/greens for enemies (reserved for players)
- Avoid pure colors - everything should be slightly desaturated
- Don't mix warm and cool shadows on same sprite

---

## Monster Color Assignments

| Monster Type | Primary Color | Accent |
|--------------|---------------|--------|
| Orcs | Rusted Iron, Sickly Green | Fire Orange eyes |
| Trolls | Stone Gray, Rotting Brown | None |
| Spiders | Shadow Purple, Mirkwood Green | Poison drip |
| Undead | Bone White, Fog Gray | Corruption Violet glow |
| Wraiths | Void Black, Shadow Purple | Blood Red eyes |
| Nazgûl | Shadow Purple, Void Black | Fire Orange crown |
| Sauron | Void Black, Blood Red | Fire Orange Eye |
| Vampires | Corruption Violet, Blood Red | Bone White fangs |

---

## Terrain Color Assignments

| Terrain | Primary | Secondary |
|---------|---------|-----------|
| Stone Floor | Stone Gray | Fog Gray cracks |
| Dirt | Rotting Brown | Dead Grass |
| Walls | Stone Gray | Shadow Purple |
| Doors | Dark Wood | Rusted Iron |
| Forge | Dark Wood | Fire Orange glow |
| Water | Steel Blue | Void Black depth |
| Mirkwood | Mirkwood Green | Rotting Brown |

---

## Implementation Notes

1. **PNG Export**: Use indexed color mode, 32 colors max
2. **Transparency**: Use PNG alpha, background is truly transparent
3. **Anti-aliasing**: NONE - use nearest neighbor scaling only
4. **Dithering**: Minimal, only for texture not gradients
5. **Outline**: 1px Void Black around all characters/monsters
