# Food and Herbs Catalog
## The Necromancer - Consumables Audit

**Generated**: 2026-01-09
**Source**: lib/edit/object.txt, src/use-obj.c

---

## Overview

| Metric | Value |
|--------|-------|
| Total Food Items | 14 |
| Herbs (with effects) | 11 |
| Pure Food (nutrition only) | 3 |
| tval | TV_FOOD (80) |
| Symbol | , (comma) |
| Base Nutrition | 250 turns (herbs), varies (food) |

---

## Herbs (11 items)

Herbs are food items with special effects in addition to providing nutrition.

### Beneficial Herbs

| ID | Name | sval | Depth | Nutrition | Value | Effect |
|----|------|------|-------|-----------|-------|--------|
| 380 | Rage | 0 | 3 | 250 | 25 | +1 Str/Con, -1 Dex/Gra, special attack, fear resist for 10d4 turns |
| 381 | Sustenance | 1 | 5 | 2000* | 50 | Extra nutrition only (2000 turns vs standard 250) |
| 383 | Healing | 3 | 7 | 250 | 75 | Cures all cuts, heals 50% health |
| 384 | Restoration | 4 | 5 | 250 | 1000 | Restores all stats by up to 3 points each |
| 390 | Athelas | 10 | 12 | 250 | 500 | Cures poison/fear/confusion/hallucination, heals 25%, anti-shadow |

*Note: Sustenance has 0 in the nutrition field but description says 2000 turns

### Harmful/Ambiguous Herbs

| ID | Name | sval | Depth | Nutrition | Value | Effect |
|----|------|------|-------|-----------|-------|--------|
| 382 | Terror | 2 | 3 | 250 | 10 | Induces fear 10d4 turns BUT +speed 5d4 turns |
| 385 | Emptiness | 5 | 4 | 0 | 0 | Makes you hungrier (+1000 hunger) |
| 386 | Visions | 6 | 8 | 250 | 0 | Hallucination 80d4 turns BUT cures blindness |
| 387 | Entrancement | 7 | 8 | 250 | 0 | Trance/paralysis for 10d4 turns |
| 388 | Weakness | 8 | 8 | 250 | 0 | Permanently -1 STR |
| 389 | Sickness | 9 | 8 | 250 | 0 | Permanently -1 CON |

**Design Note**: Terror and Visions are "mixed" herbs - harmful primary effect with beneficial secondary. This creates interesting tactical decisions.

---

## Pure Food (3 items)

| ID | Name | sval | Depth | Weight | Nutrition | Value | Special |
|----|------|------|-------|--------|-----------|-------|---------|
| 399 | Dark Bread | 35 | 7 | 5 | 1500 | 2 | Basic ration |
| 400 | Dried Meat | 36 | 10 | 10 | 2000 | 3 | Heavy but filling |
| 401 | Lembas | 37 | 7 | 1 | 3000 | 10 | Restores 1 GRA, light, long-lasting |

---

## Quest-Locked Items

The following items have placement restrictions:
- **Herb of Rage** (ID 380): "Do not move from this location, used by quests"
- **Herb of Terror** (ID 382): "Do not move from this location, used by quests"

---

## Nutrition System

| Food Type | Turns of Nourishment |
|-----------|---------------------|
| Standard Herb | 250 |
| Herb of Sustenance | 2000 |
| Dark Bread | 1500 |
| Dried Meat | 2000 |
| Lembas | 3000 |

---

## Tolkien Theming Analysis

| Item | Tolkien Reference | Theme Fit |
|------|-------------------|-----------|
| Athelas | Kingsfoil - canonical | **Strong** |
| Lembas | Elvish waybread - canonical | **Strong** |
| Dark Bread | Generic | Weak |
| Dried Meat | Travel rations | Medium |
| Others | Generic fantasy herbs | Weak |

### Missing Tolkien Herbs/Food
- **Miruvor** (exists as potion, not food)
- **Old Toby** (pipeweed) - calming/buff effect
- **Ent-draught** - stat boost
- **Cram** (Dale waybread) - less refined than Lembas
- **Galenas** (pipeweed/herb)

---

## Code Implementation

### Effect Handler (src/use-obj.c)

```c
case SV_FOOD_RAGE:      // +1 Str/Con, -1 Dex/Gra, rage state
case SV_FOOD_SUSTENANCE: // Extra nutrition
case SV_FOOD_TERROR:    // Fear + speed burst
case SV_FOOD_HEALING:   // Heal + cure cuts
case SV_FOOD_RESTORATION: // Restore stats
case SV_FOOD_HUNGER:    // Increase hunger
case SV_FOOD_VISIONS:   // Hallucination + cure blind
case SV_FOOD_ENTRANCEMENT: // Paralysis
case SV_FOOD_WEAKNESS:  // -1 STR permanent
case SV_FOOD_SICKNESS:  // -1 CON permanent
case SV_FOOD_BREAD:     // Nutrition only
case SV_FOOD_MEAT:      // Nutrition only
case SV_FOOD_LEMBAS:    // Nutrition + restore GRA
```

---

## Design Observations

### Strengths
1. **Mixed-effect herbs** create tactical decisions (Terror gives speed, Visions cures blind)
2. **Athelas** is well-themed with anti-shadow-sickness effect for Dol Guldur setting
3. **Lembas** properly lightweight and nutritious
4. **Herb system** distinct from potion system (eat vs drink)

### Weaknesses
1. **Generic names**: "Rage", "Terror", "Visions" lack Tolkien flavor
2. **No crafting**: Cannot combine herbs into potions
3. **Weight imbalance**: Dried Meat weighs 10, Lembas weighs 1
4. **Limited variety**: Only 3 true food items

### Potential Additions (Tolkien-Themed)
- **Cram**: Dale waybread, heavier than Lembas, more common
- **Old Toby**: Pipeweed, calms (+Will), removes stress
- **Ent-draught**: Rare, powerful stat restoration
- **Miruvor cordial**: Could be food variant
- **Black Bread of Mordor**: Orc rations, harmful but filling

### Alchemy Crafting Potential
Herbs + Potions could combine:
- Athelas + Miruvor = Greater Healing
- Herb of Rage + Potion of Strength = Extended Rage
- Lembas + Herb of Sustenance = Journey Bread

---

## Depth Distribution

```
Depth 3:  Rage, Terror
Depth 4:  Emptiness
Depth 5:  Sustenance, Restoration
Depth 7:  Healing, Dark Bread, Lembas
Depth 8:  Visions, Entrancement, Weakness, Sickness
Depth 10: Dried Meat
Depth 12: Athelas
```

---

*Catalog generated for AUDIT-003*
