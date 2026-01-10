# XP Balance Test Results

## Document: TEST-001 through TEST-004
## Version: 1.0
## Date: 2026-01-10
## Status: TEMPLATE - Awaiting Playtest

---

## Test Configuration

- **XP Multiplier:** 130 (defined in `src/defines.h`)
- **Game Version:** 1.5.0
- **Build Date:** 2026-01-10
- **Tester:** [Name]

---

## TEST-001: XP Values In-Game

### Verification Checklist

| Test | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| Level 1 monster first kill | 13 XP | | |
| Level 5 monster first kill | 65 XP | | |
| Level 10 monster first kill | 130 XP | | |
| Descent to depth 2 | 130 XP | | |
| Descent to depth 5 | 325 XP | | |
| Item identification | 130 XP | | |
| Lore note reading | 650 XP | | |

### Early Game (0-200ft)

**Observations:**
- [ ] XP gain feels appropriate
- [ ] Can afford basic skill purchases
- [ ] Not trivially easy

**Notes:**
```
[Record observations here]
```

### Mid Game (200-500ft)

**Observations:**
- [ ] Build is coming online
- [ ] Can afford secondary skills
- [ ] Abilities purchasable

**Notes:**
```
[Record observations here]
```

### Late Game (500ft+)

**Observations:**
- [ ] Build feels complete
- [ ] Still facing meaningful choices
- [ ] Challenge remains

**Notes:**
```
[Record observations here]
```

---

## TEST-002: Build Viability

### Combat Build Test

**Character:** [Name], [Race]/[House]
**Target:** Melee 8 + Evasion 7 by depth 300ft

| Depth | Melee | Evasion | Will | Per | XP Total | Viable? |
|-------|-------|---------|------|-----|----------|---------|
| Start | | | | | 5,000 | |
| 100ft | | | | | | |
| 200ft | | | | | | |
| 300ft | | | | | | |
| 400ft | | | | | | |
| 500ft | | | | | | |

**Result:** [ ] PASS / [ ] FAIL

**Notes:**
```
[Record observations here]
```

### Stealth Build Test

**Character:** [Name], [Race]/[House]
**Target:** Stealth 8 + Evasion 6 by depth 300ft

| Depth | Stealth | Evasion | Melee | Per | Will | XP Total | Viable? |
|-------|---------|---------|-------|-----|------|----------|---------|
| Start | | | | | | 5,000 | |
| 100ft | | | | | | | |
| 200ft | | | | | | | |
| 300ft | | | | | | | |
| 400ft | | | | | | | |
| 500ft | | | | | | | |

**Result:** [ ] PASS / [ ] FAIL

**Notes:**
```
[Record observations here]
```

### Hybrid Build Test

**Character:** [Name], [Race]/[House]
**Target:** Balanced skills by depth 300ft

| Depth | Melee | Stealth | Evasion | Will | Per | XP Total | Viable? |
|-------|-------|---------|---------|------|-----|----------|---------|
| Start | | | | | | 5,000 | |
| 100ft | | | | | | | |
| 200ft | | | | | | | |
| 300ft | | | | | | | |
| 400ft | | | | | | | |
| 500ft | | | | | | | |

**Result:** [ ] PASS / [ ] FAIL

**Notes:**
```
[Record observations here]
```

---

## TEST-003: Progression Benchmarks

### Reference Benchmarks (from DESIGN-004)

| Depth | Combat Target | Stealth Target | Hybrid Target |
|-------|--------------|----------------|---------------|
| 300ft | Mel 8 + Eva 7 + Will 4 | Stl 8 + Eva 6 + Per 5 | Balanced 6s |
| 500ft | Mel 10 + Eva 9 | Stl 10 + Eva 8 | Balanced 8s |

### Actual Results

**Combat Build:**
- Depth 300ft: Melee ___ + Evasion ___ + Will ___ + Per ___
- Match benchmark? [ ] YES / [ ] NO (behind by ___)

**Stealth Build:**
- Depth 300ft: Stealth ___ + Evasion ___ + Melee ___ + Per ___ + Will ___
- Match benchmark? [ ] YES / [ ] NO (behind by ___)

**Hybrid Build:**
- Depth 300ft: Melee ___ + Stealth ___ + Evasion ___ + Will ___ + Per ___
- Match benchmark? [ ] YES / [ ] NO (behind by ___)

### Abilities Affordable

| Depth | Abilities Affordable | Target | Status |
|-------|---------------------|--------|--------|
| 300ft | | 2-3 | |
| 500ft | | 3-4 | |

---

## TEST-004: Over-Correction Check

### Difficulty Assessment

**Early Game (0-200ft):**
- [ ] Too easy - trivial progress
- [ ] Just right - challenging but fair
- [ ] Too hard - struggling

**Mid Game (200-500ft):**
- [ ] Too easy - no real danger
- [ ] Just right - meaningful choices
- [ ] Too hard - can't keep up

**Late Game (500ft+):**
- [ ] Too easy - stomping everything
- [ ] Just right - tense and exciting
- [ ] Too hard - impossible

### Red Flags (Over-Correction)

- [ ] Reached skill 10+ before depth 300ft
- [ ] Could afford 5+ abilities by depth 400ft
- [ ] No meaningful skill trade-offs
- [ ] Combat feels trivial
- [ ] No tension in encounters

### Green Flags (Good Balance)

- [ ] Deaths feel like player mistakes
- [ ] Skill choices matter
- [ ] Can afford survival skills (Will, Per) as "tax"
- [ ] Multiple viable build paths
- [ ] Progression feels rewarding

---

## Summary

### Overall Assessment

- [ ] +30% XP is TOO LOW - recommend increasing to ____%
- [ ] +30% XP is CORRECT - game feels balanced
- [ ] +30% XP is TOO HIGH - recommend reducing to ____%

### Issues Found

1.
2.
3.

### Recommendations

1.
2.
3.

---

## Sign-Off

**Tester:** _______________
**Date:** _______________
**Verdict:** [ ] APPROVED / [ ] NEEDS ADJUSTMENT
