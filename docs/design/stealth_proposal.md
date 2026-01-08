# Stealth Proposal: Universal Foundation Tree

## Design Goals

1. Make early abilities universally attractive
2. Create synergy hooks for all other trees
3. Support the "burglar" fantasy of The Hobbit
4. Keep abilities grounded in Third Age

## Proposed Ability Tree

### N:60 Disguise
**Effect**: Halves bonuses that unwary enemies get to notice you when in their line of sight
**Level**: 3
**Prereqs**: None
**Tolkien**: Sam and Frodo in orc armor, blending in
**Rationale**: UNCHANGED - Good entry ability

---

### N:61 Assassination
**Effect**: Bonus to melee equal to Stealth score against non-alert creatures
**Level**: 4
**Prereqs**: None
**Tolkien**: Ranger ambush tactics, striking from concealment
**Rationale**: UNCHANGED - Core stealth-melee synergy

**Synergy Hook**: Warriors want this for alpha strikes

---

### N:62 Disorienting Strike (was Cruel Blow)
**Effect**: Your critical hits sometimes confuse monsters (based on crit level vs Will). Confused enemies lose track of you more easily.
**Level**: 5
**Prereqs**: Assassination
**Tolkien**: Painful blows causing disorientation, allowing escape
**Rationale**: RENAMED and clarified stealth utility

**Synergy Hook**: Allows re-establishing stealth mid-combat

---

### N:63 Escape Artist (was Exchange Places)
**Effect**: You can break free from webs and similar effects automatically. Traps deal half damage to you and don't alert nearby enemies.
**Level**: 6
**Prereqs**: Disguise, Evasion:Crowd Fighting
**Tolkien**: Bilbo escaping Mirkwood spiders, avoiding traps
**Rationale**: REPLACED - More thematic than position swap

**Synergy Hook**: Survival during infiltration, trap navigation

---

### N:64 Light Fingers (was Opportunist)
**Effect**: When adjacent to an unwary enemy, you can attempt to steal a random item without alerting them. Chance based on Stealth vs Perception.
**Level**: 7
**Prereqs**: Assassination
**Tolkien**: Bilbo's troll pickpocket, stealing the Arkenstone
**Rationale**: REPLACED - Core burglar ability!

**Synergy Hook**: The actual "burglar" ability, unique to stealth

---

### N:65 Vanish
**Effect**: +10 stealth bonus when trying to make enemies become unwary, when you are out of their line of sight
**Level**: 8
**Prereqs**: Disguise
**Tolkien**: Bilbo slipping away, Frodo evading pursuit
**Rationale**: UNCHANGED - Essential for re-establishing stealth

**Synergy Hook**: Core escape/reset ability

---

### N:66 Dexterity
**Effect**: +1 Dexterity
**Level**: 11
**Prereqs**: Disguise, Assassination
**Tolkien**: N/A - stat capstone
**Rationale**: UNCHANGED

---

## Ability Tree Structure

```
Level 3:  Disguise -------+
             |            |
Level 4:  Assassination   |
             |            |
Level 5:  Disorienting Strike
             |
Level 6:     +---------- Escape Artist
             |
Level 7:  Light Fingers

Level 8:            Vanish

Level 11:       Dexterity (capstone)
```

---

## Cross-Tree Synergy Summary

### Melee
- **Assassination**: +Stealth to melee vs unwary (MAJOR)
- **Opening Strike** (in Melee): +1 die vs unwary
- **Disorienting Strike**: Allows escape to re-stealth

### Archery
- **Ambush** (in Archery): +1 crit die vs unwary
- **Assassination**: Works with ranged? (check implementation)

### Evasion
- **Escape Artist**: Requires Crowd Fighting prereq
- **Flanking/Controlled Retreat**: Natural escape synergies

### Perception
- **Listen**: Know where enemies are to avoid them
- **Keen Senses**: Detect before being detected

### Will
- **Patience under fear**: Hiding from Nazgul
- **Indomitable**: Stay calm when hiding

### Lore
- **Lore of Silence**: Dampens sounds (MAJOR synergy)
- **Word of Opening**: Unlock paths for infiltration

### Smithing
- Lighter armor options for stealth builds

---

## "5 Points in Stealth" Build Path

For any character, the recommended minimum investment:

1. **Disguise** (3) - Entry point, always useful
2. **Assassination** (4) - Damage boost for warriors/archers
3. **Vanish** (8) - Escape option when things go wrong

This gives 3 abilities for basic stealth competence, leaving room for specialization.

---

## Changes from Current

| Slot | Current | Proposed | Change Type |
|------|---------|----------|-------------|
| 0 | Disguise | Disguise | KEEP |
| 1 | Assassination | Assassination | KEEP |
| 2 | Cruel Blow | Disorienting Strike | MODIFY (rename) |
| 3 | Exchange Places | Escape Artist | REPLACE |
| 4 | Opportunist | Light Fingers | REPLACE |
| 5 | Vanish | Vanish | KEEP |
| 6 | Dexterity | Dexterity | KEEP |

**Summary**: 4 KEEP, 1 MODIFY, 2 REPLACE
