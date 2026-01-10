# Sil 1.3 Smithing Reference

## Document: AUDIT-006
## Version: 1.0
## Date: 2026-01-10

---

## Overview

This document captures the smithing system as it existed in Sil 1.3 (the last major Sil release before Sil-Q fork), providing a baseline for understanding subsequent changes.

---

## Sil 1.3 Smithing Features

### Core Mechanics

**From Sil 1.3 changelog:**
- Artefact rings can have bonuses to attack, evasion, and protection
- Removed ability to add Grace to artefact cloaks (nerf to extreme +Grace smiths)
- Fixed smithing gloves of treachery forcing <-1> penalty to strength

### Forge System

**From Sil 1.2.0:**
- Forges can create horns using 'Jeweller' ability
- Mithril item difficulties reduced significantly
- 'Slays' no longer cost a strength point to add to weapons
- Artefact arrows have half difficulty (1 arrow shouldn't cost same as 24)
- Game clarifies: only one of Enchant or Artifice per item
- Fixed bugs with artefact rings/amulets forgetting special bonuses
- Remaining bug: abilities on artefacts could disappear or duplicate
  - Workaround: add abilities immediately before finishing

### Cost System (Sil 1.1)

**Major cost changes in Sil 1.1:**
- Forge appearances increased throughout dungeon
- 'Speed' attribute cost increased: 25 → 30
- Stat point cost increased by 20%: base 10 → 12
- Damage side cost increased by 25%: 12 → 15
- Brands, slays, sharpness costs increased
- No longer get benefits for putting penalties on items
  - Exception: Danger gives -5 difficulty reduction
- 20% discount on robes, crowns, sceptres difficulties
- Can now make all special item types including bad ones
- First forge guaranteed: normal forge with 3 charges (anti-start-scum)
- Confirmation prompt added for spending smithing points on masterpieces

**Smithing ability changes:**
- Song of Aule bonus reduced: Song/3 → Song/5

---

## Sil 1.0.x Smithing History

### Sil 1.0.2 Changes

- Minor slot difficulty increased by 20%:
  - Minor slots: rings, light, cloak, gloves, boots, arrows
  - Major slots: weapon, bow, amulet, body armor, shield, helmet
- Two-handed weapon difficulty discount removed
- Forging time now proportional to difficulty
- Song of Aule bonus reduced: Song/3 → Song/5
- Light source radius no longer depends on pval
  - Can make Feanorian Lamp of Grace <+1> without reducing radius

### Sil 1.0.1 Changes

- Song of Aule cost reduced to 1/3 point of voice per turn

---

## Sil 1.3 Ability Tree

### Smithing Abilities (Original Sil)

| Ability | Level | Prerequisites | Effect |
|---------|-------|---------------|--------|
| Weaponsmith | 2 | None | Create weapons |
| Armoursmith | 3 | None | Create armor |
| Jeweller | 4 | None | Create rings, amulets, lights, horns |
| Enchantment | 5 | None | Add enchantments (egos) to items |
| Artifice | 6 | Enchantment | Create custom artefacts |
| Masterpiece | 7 | Artifice | Can spend Smithing skill for difficulty |
| Grace | 10 | None | +1 Grace stat |

**Key differences from Sil-Q/Necromancer:**
- "Artifice" was a core ability name (now legacy)
- "Enchantment" was separate from base item creation
- "Masterpiece" allowed skill drain for difficulty (different from Masterwork)
- No Reforge/Reclaim abilities (broken item system was different)

---

## Cost Structure (Sil 1.3)

### Base Item Costs

| Factor | Cost | Notes |
|--------|------|-------|
| Stat points | 12 | Per stat point |
| Damage sides | 15 | Per side |
| Speed | 30 | Very expensive |
| Minor slot | +20% | Multiplier |
| Robes/crowns/sceptres | -20% | Discount |

### Slays and Brands

**Sil 1.2.0 removed** the strength point cost for slays.
- Previously: adding a slay cost 1 strength point
- After: slays cost difficulty only, no stat drain
- Rationale: "too steep a cost for early game, making no-one add them"

---

## Forge Generation

### Sil 1.3 Rules

- Forges appear more regularly throughout dungeon
- First forge: guaranteed normal forge with 3 charges
- Prevents start-scumming for good forges

### Forge Types (Original)

| Type | Bonus | Notes |
|------|-------|-------|
| Normal Forge | +0 | Most common |
| Unique Forge | +? | Special locations |

---

## Key Design Philosophy (Sil)

### From Sil 1.1 Changelog

> "Aim is to make smithing more competitive mid-game, less broken late-game."

**Specific changes to achieve this:**
1. Sharpness and speed more expensive
2. Brands, slays, and resists less expensive
3. Many other difficulty adjustments

### Anti-Exploit Measures

1. **Start-scum prevention**: First forge always normal with 3 charges
2. **Penalty exploit**: Can't benefit from adding penalties to items
   - Exception: Danger still gives -5 discount
3. **Artifice lock**: Only one of Enchant or Artifice per item

---

## Items and Special Types

### Changes from Sil 1.1

- Can now make all special item types including bad ones
- Some special weapons wielded from floor didn't glow (fixed)
- Lanterns of brightness auto-identify when refueling (fixed)
- True Sight types unified (identifying one identifies all)

### Minor vs Major Slots

**20% difficulty increase for minor slots:**
- Rings
- Light sources
- Cloaks
- Gloves
- Boots
- Arrows

**Major slots (no penalty):**
- Weapon
- Bow
- Amulet
- Body armor
- Shield
- Helmet

---

## Comparison: Sil 1.3 vs Sil-Q

| Feature | Sil 1.3 | Sil-Q/Necromancer |
|---------|---------|-------------------|
| Artifice | Core ability | Legacy term, replaced |
| Enchantment | Separate ability | Part of Weaponsmith/Armoursmith |
| Masterpiece | Skill drain for difficulty | Different mechanic |
| Reforge | Not present | Combines broken glowing items |
| Reclaim | Not present | Combines broken strange items |
| Masterwork | Not present | 4 broken → best artifact |
| Expertise | Not present | Negates XP/stat costs |
| +Smithing items | Present | Removed in Sil-Q 1.5.0 |
| Curses on artifacts | Present | Removed in Sil-Q 1.5.0 |
| Guaranteed forges | 100' (first) | 100', 300', 500' |

---

## Summary: What Sil-Q Inherited

1. **Core cost structure** with stat points, damage sides, etc.
2. **Minor slot penalty** (+20% difficulty)
3. **No-penalty exploit** rule (except Danger)
4. **Forge distribution** throughout dungeon
5. **Song of Aule** bonus mechanics

## What Sil-Q Changed

1. **New abilities**: Reforge, Reclaim, Masterwork, Expertise
2. **Removed**: +Smithing items, artifact curses
3. **Guaranteed forges**: More locations (100', 300', 500')
4. **XP costs**: Added for Reforge/Reclaim/Masterwork
5. **Broken item system**: New item types for recycling
