# Sil-Q Remnants in Forge UI

## Document: AUDIT-003
## Version: 1.0
## Date: 2026-01-10

---

## Overview

This document identifies all references to Sil-Q skills and terminology that should be updated for The Necromancer.

---

## "Artifice" References

The term "Artifice" appears in the code as a legacy reference from Sil-Q where it was a separate skill or ability. In The Necromancer, this functionality is handled by the Reclaim ability.

### Code Occurrences

| File | Line | Context | Current Text |
|------|------|---------|--------------|
| src/cmd4.c | 1864 | smithing_cost struct | `int artifice;` |
| src/cmd4.c | 2940 | Cost initialization | `smithing_cost.artifice = 0;` |
| src/cmd4.c | 3474 | Cost calculation | `smithing_cost.artifice = 1;` |
| src/cmd4.c | 3651 | UI display | `Term_putstr(..., "Artifice");` |
| src/cmd4.c | 3862 | Affordability check | `|| smithing_cost.artifice)` |
| src/cmd4.c | 6659 | Menu label | `"c) Artifice"` |
| src/cmd4.c | 6704 | Help text | `"(not compatible with Artifice)"` |

### Detailed Analysis

#### 1. smithing_cost.artifice (line 1864)
```c
typedef struct smithing_cost_type {
    ...
    int artifice;
} smithing_cost_type;
```
**Issue:** Variable named after obsolete Sil-Q skill.
**Fix:** Rename to `custom_artifact` or `artifact_cost`.

#### 2. Cost initialization (line 2940)
```c
smithing_cost.artifice = 0;
```
**Issue:** Uses old variable name.
**Fix:** Update with renamed variable.

#### 3. Cost calculation (line 3474)
```c
smithing_cost.artifice = 1;
```
**Context:** Set when player tries to create custom artifact without Reclaim ability.
**Issue:** Uses old variable name.
**Fix:** Update with renamed variable.

#### 4. UI display (line 3651-3653)
```c
if (smithing_cost.artifice)
{
    Term_putstr(COL_SMT4 + 2, 10 + costs, -1, TERM_RED, "Artifice");
    ...
}
```
**Issue:** Displays "Artifice" to player when missing ability.
**Fix:** Change to "Custom Artifact" or "Reclaim Required".

#### 5. Affordability check (line 3862)
```c
|| smithing_cost.artifice)
```
**Issue:** Uses old variable name.
**Fix:** Update with renamed variable.

#### 6. Menu label (line 6659)
```c
Term_putstr(..., "c) Artifice");
```
**Issue:** Menu option labeled "Artifice" instead of something clearer.
**Fix:** Change to "c) Custom Artifact" or "c) Design Artifact".

#### 7. Help text (line 6704)
```c
"(not compatible with Artifice)"
```
**Issue:** References "Artifice" in incompatibility warning.
**Fix:** Change to "(not compatible with Custom Artifact)".

---

## Other Potential Sil-Q References

### Searched Terms

| Term | Occurrences | Notes |
|------|-------------|-------|
| Artifice | 8 | See above |
| Enchantment (as skill) | 0 | Only as ability name |
| Alchemy | 0 | Not found |
| Song skill | 0 | Not in forge context |

### False Positives

The following are NOT Sil-Q remnants:
- "Enchantment" - Used correctly as ability name
- "Enchant" - Menu option, correct usage
- "smithing" - Core skill name, correct

---

## Recommended Changes

### High Priority

1. **Rename UI label** (line 6659)
   - From: `"c) Artifice"`
   - To: `"c) Custom Artifact"`

2. **Update help text** (line 6704)
   - From: `"(not compatible with Artifice)"`
   - To: `"(not compatible with Custom Artifact)"`

3. **Update cost display** (line 3653)
   - From: `"Artifice"`
   - To: `"Requires Reclaim"` or `"Custom Artifact"`

### Medium Priority

4. **Rename variable** (line 1864)
   - From: `int artifice;`
   - To: `int custom_artifact;`
   - **Note:** Requires updating all 5 references

### Low Priority

5. **Update comments** if any reference Artifice (none found)

---

## Thematic Alternatives

The Necromancer could use darker, more thematic terminology:

| Current | Alternative 1 | Alternative 2 |
|---------|--------------|---------------|
| Artifice | Shadow-forging | Dark Craft |
| Custom Artifact | Bound Relic | Soul-forged Item |
| Enchant | Imbue | Curse |
| Reforge | Reshape | Reawaken |
| Reclaim | Unbind | Extract |
| Masterwork | Legendary Work | Greater Binding |

However, clarity should take priority over theme for gameplay purposes.

---

## Implementation Checklist

- [ ] Rename `smithing_cost.artifice` to `smithing_cost.custom_artifact`
- [ ] Update line 2940: initialization
- [ ] Update line 3474: cost calculation
- [ ] Update line 3651-3653: UI display text
- [ ] Update line 3862: affordability check
- [ ] Update line 6659: menu label
- [ ] Update line 6704: help text
- [ ] Test all forge screens for consistency
- [ ] Verify no other "Artifice" references exist
