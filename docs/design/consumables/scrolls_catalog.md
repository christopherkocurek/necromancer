# Horns Catalog (Scrolls Replacement)
## The Necromancer - Consumables Audit

**Generated**: 2026-01-09
**Source**: lib/edit/object.txt, src/use-obj.c

---

## Overview

| Metric | Value |
|--------|-------|
| Item Type | Horns (replaces traditional scrolls) |
| Total Horns | 5 |
| tval | TV_HORN (66) |
| Implementation | src/use-obj.c lines 672-929 |
| Symbol | ? |

**Design Note**: Sil-Q uses HORNS instead of scrolls. This is a significant thematic choice that fits Tolkien's world better - horns are used for signaling and have magical properties in the legendarium (Horn of Gondor, Horn of the Mark).

---

## All Horns

| ID | Name | sval | Depth | Weight | Value | Effect |
|----|------|------|-------|--------|-------|--------|
| 240 | Terror | 0 | 7 | 10 | 100 | Fires fear arc (GF_FEAR), makes noise (-10 perception) |
| 241 | Thunder | 1 | 10 | 10 | 100 | Fires sound arc (GF_SOUND, 10 dmg, 4 rad), makes noise (-20 perception) |
| 242 | Force | 2 | 12 | 10 | 100 | Knocks enemies back in cone, makes loud noise |
| 243 | Blasting | 3 | 13 | 10 | 100 | Can shatter stone, cause earthquakes. Aimable up (<) or down (>) |
| 250 | Warning | 4 | 7 | 10 | 0 | Makes aggressive noise (-40 perception), alerts enemies |

---

## Detailed Effect Analysis

### Horn of Terror (sval 0)
```c
fire_arc(GF_FEAR, dir, 0, 0, will_score, 3, 90)
monster_perception(TRUE, FALSE, -10);
```
- **Mechanic**: Fear effect in 90-degree arc, range 3
- **Skill Check**: Uses Will score
- **Noise**: -10 to monster perception (moderate noise)
- **Stealth Impact**: Breaks stealth, alerts nearby enemies

### Horn of Thunder (sval 1)
```c
fire_arc(GF_SOUND, dir, 10, 4, will_score, 3, 90)
monster_perception(TRUE, FALSE, -20);
```
- **Mechanic**: Sound damage (10 base, 4 dice), stuns in arc
- **Skill Check**: Uses Will score
- **Noise**: -20 to monster perception (loud)
- **Stealth Impact**: Very loud, wide alert radius

### Horn of Force (sval 2)
- **Mechanic**: Knockback in 3-wide cone, 3 range
- **Effect**: Pushes enemies away from player
- **Noise**: Significant (code shows noise generation)
- **Stealth Impact**: Loud, but creates escape path

### Horn of Blasting (sval 3)
- **Mechanic**: Earthquake/terrain destruction
- **Special**: Can aim UP (<) or DOWN (>) to affect ceiling/floor
- **Skill Check**: Will vs 10
- **Damage**: 4d8 if used on ceiling (damages player too)
- **Stealth Impact**: Extremely loud, massive area effect

### Horn of Warning (sval 4)
```c
monster_perception(TRUE, FALSE, -40);
make_aggressive();
```
- **Mechanic**: Makes nearby monsters aggressive
- **Noise**: -40 to monster perception (very loud)
- **Value**: 0 gold (considered harmful/tactical)
- **Use Case**: Break truces, draw enemies, tactical repositioning

---

## Stealth Interaction

All horns have significant stealth implications:

| Horn | Perception Penalty | Stealth Rating |
|------|-------------------|----------------|
| Terror | -10 | Moderate noise |
| Thunder | -20 | Loud |
| Force | ~-15 (estimated) | Loud |
| Blasting | ~-30 (estimated) | Very loud |
| Warning | -40 | Extremely loud |

**Key Finding**: Horns are anti-stealth items. Using them reveals the player and attracts attention. This creates interesting tactical decisions in a stealth-focused game.

---

## Tolkien Theming

| Horn | Tolkien Reference | Theme Fit |
|------|-------------------|-----------|
| Terror | Horn of Gondor (fear effect) | Strong |
| Thunder | Helm's Horn, thunder references | Strong |
| Force | Magical horn properties | Medium |
| Blasting | Trumpets of the Valar | Medium |
| Warning | Signal horns of Rohan | Strong |

**Assessment**: Horns fit Tolkien theming much better than scrolls would. The Horn of Gondor's power to strike fear, and the horns of Rohan for signaling, are well-represented.

---

## Design Observations

### Strengths
1. **Thematic fit**: Horns > scrolls for Middle-earth
2. **Stealth tradeoff**: Power vs noise creates decisions
3. **Tactical variety**: Different effects for different situations
4. **Directional**: All horns are directional (arc or beam)

### Potential Gaps
1. **No utility horns**: All are combat-focused
2. **No healing horn**: Could have horn of rallying
3. **Limited count**: Only 5 horns vs typical 15+ scrolls
4. **No "safe" horn**: All make significant noise

### Possible Additions
- **Horn of Rallying**: Cures fear for allies, small heal
- **Horn of Mist**: Creates concealment (stealth-friendly)
- **Horn of Valour**: Temporary combat buff

---

## Technical Notes

### Usage Flow
1. Player selects horn
2. Player chooses direction
3. `use_horn()` function processes effect
4. `break_truce()` called - horn use breaks any truce
5. Returns TRUE (always identifies on use)

### Flags
- All horns have `EASY_KNOW` flag
- Horns don't have charges - single use

---

*Catalog generated for AUDIT-002*
