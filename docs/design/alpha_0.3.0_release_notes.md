# Alpha 0.3.0 Release Notes: Ability Tree Rework

## Overview

This release reworks all skill trees to better align with Third Age design principles:
- **Third Age Power Cap**: No flashy magic, power through skill/will/knowledge
- **Stealth is Core**: Every build should invest ~5 points in stealth
- **Emergent Archetypes**: Character builds emerge from synergies, not preset classes
- **Tolkien Precedent**: Every ability traces to Middle-earth lore
- **Interesting Choices**: Every ability should present meaningful trade-offs

---

## Ability Changes by Tree

### Melee Tree (5 changes)

| Old | New | Rationale |
|-----|-----|-----------|
| Impale | Opening Strike | Stealth synergy (+1 die vs unwary/sleeping) |
| Whirlwind Attack | Controlled Fury | Reduced scope (one free attack on kill) |
| Smite | Mighty Blow | Changed from max damage to +Str bonus |
| Two Weapon Fighting | Defensive Stance | No Tolkien dual-wield precedent |
| Rapid Attack | Swift Strikes | Requires one-handed weapon |

### Archery Tree (1 change)

| Old | New | Rationale |
|-----|-----|-----------|
| Versatility | Keen Eyes | Replaced skill point rebate with Elven far-sight |

### Evasion Tree (0 changes)

No changes needed - excellent design.

### Stealth Tree (3 changes)

| Old | New | Rationale |
|-----|-----|-----------|
| Cruel Blow | Disorienting Strike | Crits confuse enemies |
| Exchange Places | Escape Artist | Break free from webs/traps |
| Opportunist | Light Fingers | Burglar-style theft ability |

### Perception Tree (1 change)

| Old | New | Rationale |
|-----|-----|-----------|
| Quick Study | Natural Talent | Innate gift for advanced abilities |

### Will Tree (2 changes)

| Old | New | Rationale |
|-----|-----|-----------|
| Channeling | Force of Will | Renamed for thematic clarity |
| Inner Light | Defy Death | Replaced duplicate with "refuse to die" ability |

### Lore Tree (0 changes)

No changes needed - exemplary Third Age design.

### Smithing Tree (0 changes)

Not part of this rework (completed in Alpha 0.2.0).

---

## Design Validation

### Stealth Synergy Audit

Every tree now has meaningful stealth synergies:
- **Excellent**: Lore (4 abilities), Evasion (5 abilities)
- **Good**: Melee, Archery, Perception (3+ abilities each)
- **Adequate**: Will (defensive synergies)
- **Indirect**: Smithing (equipment choices)

### Archetype Validation

8 emergent builds validated:
1. Ranger (Stealth + Archery + Perception)
2. Duelist (Melee + Evasion)
3. Loremaster (Lore + Will)
4. Warrior-Smith (Melee + Smithing)
5. Scout (Evasion + Perception + Stealth)
6. Defender (Will + Evasion + Melee)
7. Assassin (Stealth + Melee + Archery)
8. Herbalist (Lore + Perception + Stealth)

### Power Scale Validation

All abilities respect Third Age power ceiling:
- No combat magic (fireballs, lightning)
- No teleportation or resurrection
- No mind control
- All abilities have Tolkien precedent

---

## Summary

| Tree | Changes | Status |
|------|---------|--------|
| Melee | 5 | Reworked for stealth synergy |
| Archery | 1 | Minor polish |
| Evasion | 0 | Already excellent |
| Stealth | 3 | Enhanced burglar theme |
| Perception | 1 | Minor polish |
| Will | 2 | Removed duplicate, added "Defy Death" |
| Lore | 0 | Exemplary - template for future |

**Total Changes**: 12 abilities modified across 5 trees

---

## Future Considerations

- Perception tree may need expansion for "tactical omniscience" vision
- Word of Mastery (Lore) needs balance monitoring
- Enchantment (Smithing) should remain subtle

---

## Files Changed

- `lib/edit/ability.txt` - Core ability definitions
- `docs/design/` - Design documentation for all trees
