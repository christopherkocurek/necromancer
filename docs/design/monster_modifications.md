# Monster Modifications - The Necromancer
## MON-007: Proposed Changes to Existing Monsters

---

## Modification Categories

1. **Increase Sleepiness** - Make better stealth targets
2. **Add SLEEPING Flag** - Guarantee sleep state
3. **Adjust Perception** - Easier/harder to sneak past
4. **Modify Pack Size** - FRIENDS -> solo or vice versa
5. **Add Flags** - New behaviors

---

## SLEEPINESS INCREASES

These monsters should be easier to catch sleeping:

| Monster | Current | Proposed | Rationale |
|---------|---------|----------|-----------|
| N:32 Orc Soldier | 15 | 20 | Barracks should have sleepers |
| N:54 Easterling Warrior | 15 | 20 | Off-duty potential |
| N:38 Hill Troll | 15 | 25 | Stupid heavy sleeper |
| N:53 Mirk-troll | 15 | 20 | Troll nature |

---

## PERCEPTION ADJUSTMENTS

### Decrease (Easier Stealth)
| Monster | Current | Proposed | Rationale |
|---------|---------|----------|-----------|
| N:38 Hill Troll | 2 | 1 | Very stupid |
| N:53 Mirk-troll | 3 | 2 | Still stupid |
| N:32 Orc Soldier | 2 | 2 | Keep as is |

### Increase (Harder Stealth)
| Monster | Current | Proposed | Rationale |
|---------|---------|----------|-----------|
| N:33 Orc Archer | 3 | 4 | Archers should watch |
| N:35 Orc Thrallmaster | 4 | 5 | Watchful slavemaster |

---

## FLAG ADDITIONS

### Add TERRITORIAL
Makes monsters guard their area rather than chase:

| Monster | Current | Proposed | Rationale |
|---------|---------|----------|-----------|
| N:20 Great Spider | Has it | Keep | Already territorial |
| N:38 Hill Troll | None | Add | Guards its spot |
| N:53 Mirk-troll | None | Add | Guards its den |
| N:74 Wight | Has it | Keep | Already territorial |

### Add SLEEPING Flag
Guarantees monster starts asleep:

| Monster | Current | Proposed | Rationale |
|---------|---------|----------|-----------|
| N:21 Warg Pup | None | Add | Sleeping in den |
| N:31 Orc Slave | None | Add | Exhausted |

Note: This would require code support for SLEEPING flag.

---

## SHRIEK RATE ADJUSTMENTS

### Increase (More Dangerous Alarms)
| Monster | Current | Proposed | Rationale |
|---------|---------|----------|-----------|
| N:13 Black Squirrel | 30% | 50% | More reliable alarm |
| N:18 Orc Scout | 25% | 40% | Trained to alert |

### Decrease (Less Annoying)
| Monster | Current | Proposed | Rationale |
|---------|---------|----------|-----------|
| N:16 Giant Bat | 10% | 5% | Only occasional |

---

## ATTACK MODIFICATIONS

### Reduce Danger (Some Monsters Too Strong)
None needed - difficulty curve is appropriate.

### Increase Danger (Some Too Weak)
None needed - progression is good.

---

## SPECIFIC MONSTER MODIFICATIONS

### N:21 - Warg Pup
```
Current:
F:FRIENDS | RAND_25 | WOLF

Proposed:
F:FRIENDS | RAND_25 | WOLF | SLEEPING
A:20:3:4:2 -> A:25:3:4:2  (increase sleepiness)
```
Rationale: Pups in a den should be sleeping.

---

### N:31 - Orc Slave
```
Current:
A:20:1:1:1

Proposed:
A:25:1:1:1  (increase sleepiness)
F:MALE | ORC | HURT_LITE | SLEEPING
```
Rationale: Exhausted slaves should always be sleeping when encountered.

---

### N:32 - Orc Soldier
```
Current:
A:15:2:2:3

Proposed:
A:20:2:2:3  (increase sleepiness)
```
Rationale: Off-duty soldiers should have higher sleep chance.

---

### N:38 - Hill Troll
```
Current:
A:15:2:0:3

Proposed:
A:25:1:0:3  (increase sleepiness, decrease perception)
F:... | TERRITORIAL
```
Rationale: Trolls are stupid and sleep heavily.

---

### N:53 - Mirk-troll
```
Current:
A:15:3:1:4

Proposed:
A:20:2:1:4  (increase sleepiness, decrease perception)
F:... | TERRITORIAL
```
Rationale: Still a troll, still stupid.

---

### N:113 - Vampire
```
Current:
A:20:11:7:12

Proposed:
Keep as is - already high sleepiness
```
Rationale: Vampires already excellent stealth targets.

---

## SUMMARY OF CHANGES

### Sleepiness Increases
| Monster | Old | New |
|---------|-----|-----|
| Warg Pup | 20 | 25 |
| Orc Slave | 20 | 25 |
| Orc Soldier | 15 | 20 |
| Easterling Warrior | 15 | 20 |
| Hill Troll | 15 | 25 |
| Mirk-troll | 15 | 20 |

### Perception Decreases
| Monster | Old | New |
|---------|-----|-----|
| Hill Troll | 2 | 1 |
| Mirk-troll | 3 | 2 |

### Perception Increases
| Monster | Old | New |
|---------|-----|-----|
| Orc Archer | 3 | 4 |
| Orc Thrallmaster | 4 | 5 |

### SHRIEK Changes
| Monster | Old | New |
|---------|-----|-----|
| Black Squirrel | 30% | 50% |
| Orc Scout | 25% | 40% |
| Giant Bat | 10% | 5% |

### Flag Additions
| Monster | Added Flag |
|---------|------------|
| Warg Pup | SLEEPING |
| Orc Slave | SLEEPING |
| Hill Troll | TERRITORIAL |
| Mirk-troll | TERRITORIAL |

---

## IMPLEMENTATION NOTES

1. **SLEEPING flag** - Would need code support to recognize this flag and start monster asleep
2. **Sleepiness changes** - Pure data, no code needed
3. **Perception changes** - Pure data, no code needed
4. **SHRIEK changes** - Pure data, change SPELL_PCT_XX
5. **TERRITORIAL** - Flag already exists in code

---

## PRIORITY ORDER

1. Sleepiness increases (immediate impact, no code)
2. Perception adjustments (immediate impact, no code)
3. SHRIEK changes (immediate impact, no code)
4. TERRITORIAL additions (flag exists, no code)
5. SLEEPING flag (requires code support)
