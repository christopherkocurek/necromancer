# Design: Loot Tables and Destruction Events

## Document: DESIGN-006
## Version: 1.0
## Date: 2026-01-10

---

## Overview

This document addresses two related concerns:
1. **Loot density** - Ensure rare/ego item spawns in vaults match Sil-Q baseline
2. **Destruction events** - Review and potentially enhance gear-destroying mechanics to support the Salvage ability

---

## Part 1: Loot Table Comparison

### Required Audit

**Task:** Compare The Necromancer's loot tables against Sil-Q 1.5.0 to ensure parity in:

| Category | What to Compare |
|----------|-----------------|
| Vault loot density | Items per vault, quality distribution |
| Ego item frequency | % of generated items that are ego |
| Artifact rarity | Artifact spawn rates by depth |
| Broken item drops | Broken Glowing/Strange drop rates |
| Monster drops | Quality/quantity of monster loot |

### Files to Audit

| File | Contents |
|------|----------|
| `lib/edit/object.txt` | Base item definitions, allocation |
| `lib/edit/special.txt` | Ego item definitions, rarity |
| `lib/edit/artefact.txt` | Artifact definitions, rarity |
| `lib/edit/vault.txt` | Vault definitions, loot placement |
| `lib/edit/monster.txt` | Monster drop tables |
| `src/generate.c` | Level generation, object placement |
| `src/object1.c` | Object generation algorithms |
| `src/object2.c` | Object allocation, quality rolls |

### Key Questions

1. **Are vaults generating the expected loot?**
   - Sil-Q vaults typically have 3-8 items
   - Greater vaults should have guaranteed ego/artifact

2. **Is ego frequency appropriate?**
   - Sil-Q: ~15-20% of generated equipment is ego
   - Check `make_object()` and related functions

3. **Are Broken items dropping?**
   - Broken Glowing: Should appear from Tier 2 onwards
   - Broken Strange: Should be rare, Tier 3+ only

4. **Are artifacts appearing?**
   - Sil-Q guarantees certain artifact types per depth range
   - Check artifact allocation tables

### Audit Checklist

- [ ] Pull Sil-Q 1.5.0 source for comparison
- [ ] Compare `object.txt` allocation values
- [ ] Compare `special.txt` rarity values
- [ ] Compare `artefact.txt` depth/rarity values
- [ ] Compare vault loot templates in `vault.txt`
- [ ] Compare generation algorithms in `generate.c`
- [ ] Test in-game: Track loot over 10 floors
- [ ] Document any discrepancies

---

## Part 2: Destruction Events

### Current Destruction Sources

**Based on Sil-Q mechanics:**

| Source | Destroys | Frequency | Notes |
|--------|----------|-----------|-------|
| Acid attacks | Armor | Rare | Few acid monsters |
| Fire damage | Inventory | Rare | Scrolls, herbs primarily |
| Cold damage | Potions | Rare | Potion shattering |
| Weapon breakage | Weapons | Very rare | Almost never happens |
| Inventory overflow | Any | Situational | When pack full |

### Analysis: Is Salvage Useful?

**Current state:** Destruction events are RARE.

If destruction rarely happens, Salvage (50% save chance) will rarely trigger. This makes the ability feel weak or useless.

**Options:**

| Option | Description | Risk |
|--------|-------------|------|
| A | Keep as-is | Salvage may feel useless |
| B | Increase destruction frequency | May frustrate players |
| C | Add new destruction sources | More design work |
| D | Expand Salvage scope | May be too powerful |

### Recommended Approach: Option C (New Sources)

Add INTERESTING destruction events that create meaningful Salvage moments without feeling punitive.

#### New Destruction Sources

**1. Forge Accident (when crafting fails)**

> "The metal warps in the heat! Your [item] is ruined... but you salvage the remains."

- Trigger: When attempting difficult item (skill < difficulty)
- Effect: One equipped item damaged/destroyed
- With Salvage: 50% becomes Broken Glowing instead

**2. Cursed Glyphs (Tier 3-4 terrain)**

> "You step on a cursed glyph! Dark energy courses through your equipment..."

- Trigger: Step on cursed glyph trap
- Effect: Random equipped item destroyed
- With Salvage: 50% recovery

**3. Weapon Stress (high-damage crits)**

> "Your weapon cracks from the force of the blow!"

- Trigger: When dealing 3× or more expected damage (massive crit)
- Effect: 10% chance weapon takes stress
- Stress accumulation: 3 stress = weapon breaks
- With Salvage: 50% recovery

**4. Acid Puddles (new terrain)**

> "You wade through acid... your armor corrodes!"

- Trigger: Walking through acid terrain
- Effect: Armor takes damage, may be destroyed
- With Salvage: 50% recovery

**5. Olog-hai Crushing Blow (monster ability)**

Per GDD: "Olog-hai: **Crushing Blow** - can destroy shields/armor"

- Already in GDD!
- Ensure it's implemented
- With Salvage: 50% recovery

### Implementation Priority

| Source | Priority | Notes |
|--------|----------|-------|
| Olog-hai Crushing Blow | HIGH | Already in GDD |
| Cursed Glyphs | HIGH | Already in GDD terrain |
| Weapon Stress | MEDIUM | New mechanic, interesting |
| Forge Accident | LOW | Only affects smiths |
| Acid Puddles | LOW | New terrain needed |

---

## Part 3: Broken Item Drop Rates

### Current Understanding

| Item | K_IDX | Expected Source |
|------|-------|-----------------|
| Broken Glowing Weapon | 491 | Monster drops, vaults |
| Shattered Elven Mail | 492 | Monster drops, vaults |
| Broken Strange Weapon | 493 | Rare monster drops, vaults |
| Twisted Shadow-plate | 494 | Rare monster drops, vaults |
| Broken Strange Jewelry | 495 | Very rare, boss drops |

### Target Drop Rates

| Item Type | Per 1000ft | Per Full Game |
|-----------|------------|---------------|
| Broken Glowing (weapon) | 2-3 | 8-12 |
| Broken Glowing (armor) | 2-3 | 8-12 |
| Broken Strange (weapon) | 1 | 3-5 |
| Broken Strange (armor) | 1 | 3-5 |
| Broken Strange (jewelry) | 0.5 | 1-2 |

### Verification Tasks

- [ ] Check `object.txt` for broken item allocation
- [ ] Check monster drop tables for broken items
- [ ] Test in-game: Track broken item drops
- [ ] Adjust allocation if needed

---

## Part 4: Vault Loot Standards

### Sil-Q Vault Loot Guidelines

| Vault Type | Item Count | Quality |
|------------|------------|---------|
| Minor vault | 2-4 | Normal + chance of ego |
| Standard vault | 4-6 | 1-2 ego guaranteed |
| Greater vault | 6-10 | 1 artifact + multiple ego |
| Unique vault | Varies | Specific themed loot |

### Verification Tasks

- [ ] Review `vault.txt` loot specifications
- [ ] Compare to Sil-Q vault definitions
- [ ] Test in-game: Enter vaults, check loot
- [ ] Adjust as needed

---

## Action Items

### Immediate (Before Implementation)

1. **Audit loot tables** - Compare to Sil-Q, document differences
2. **Verify Olog-hai Crushing Blow** - Ensure implemented per GDD
3. **Verify Cursed Glyphs** - Ensure terrain destruction works

### Short-term (With Salvage Implementation)

4. **Implement weapon stress** - New destruction source
5. **Balance destruction frequency** - Not too rare, not too punitive

### Long-term (Post-Release Tuning)

6. **Monitor Salvage usage** - Is it triggering meaningfully?
7. **Adjust drop rates** - Based on playtest feedback
8. **Add more destruction sources** - If needed

---

## Testing Protocol

### Loot Testing

1. Generate 10 floors of each tier
2. Record: Total items, ego items, artifacts, broken items
3. Compare to Sil-Q baseline
4. Document deviations

### Destruction Testing

1. Play through Tier 2-4 with various builds
2. Record: Destruction events, items lost, Salvage triggers
3. Evaluate: Is Salvage useful?
4. Adjust frequency if needed

---

## Summary

| Area | Status | Action |
|------|--------|--------|
| Loot density | NEEDS AUDIT | Compare to Sil-Q |
| Ego frequency | NEEDS AUDIT | Verify allocation |
| Artifact rarity | NEEDS AUDIT | Check spawn rates |
| Broken drops | NEEDS AUDIT | Verify presence |
| Destruction events | NEEDS EXPANSION | Add weapon stress, verify others |
| Salvage viability | DEPENDS | On destruction frequency |
