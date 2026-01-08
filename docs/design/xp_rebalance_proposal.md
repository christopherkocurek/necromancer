# XP Rebalance Proposal - The Necromancer
## XP-004: Shifting from Combat-First to Stealth-First Economy

---

## Design Goals

1. **Stealth builds should progress comparably to combat builds**
2. **Exploration and discovery should be rewarded**
3. **Grinding should be discouraged**
4. **Risk-taking should be rewarded**
5. **Player choice matters more than playstyle**

---

## CURRENT XP ECONOMY

### XP Sources (Current)

| Source | Formula | Typical Total | % of Total |
|--------|---------|---------------|------------|
| Kill XP | level×10 / (kills+1) | 8,000-12,000 | 40-50% |
| Encounter XP | level×10 / (sights+1) | 3,000-5,000 | 15-20% |
| Descent XP | depth×50 | 10,500 | 35-40% |
| Ident XP | 100 per type | 2,500 | 10-15% |
| **Total** | - | **24,000-30,000** | 100% |

### Current Build Comparison

**Combat Playthrough (Clear Everything)**
- Kill XP: 12,000 (all enemies killed)
- Encounter XP: 5,000 (see everything you kill)
- Descent XP: 10,500
- Ident XP: 2,500
- **Total: ~30,000 XP**

**Stealth Playthrough (Avoid Combat)**
- Kill XP: 2,000 (minimal kills)
- Encounter XP: 4,000 (see but don't kill)
- Descent XP: 10,500
- Ident XP: 2,500
- **Total: ~19,000 XP**

**Gap:** Stealth gets ~63% of combat XP (37% penalty)

---

## PROPOSED XP ECONOMY

### New XP Sources

| Source | Formula | Typical Total | % of Total |
|--------|---------|---------------|------------|
| Kill XP | level×10 / (kills+1)^1.5 | 4,000-6,000 | 15-20% |
| Encounter XP | level×10 / (sights+1) | 3,000-5,000 | 15-20% |
| Descent XP | depth×50 | 10,500 | 35-40% |
| Ident XP | 100 per type | 2,500 | 8-10% |
| **Discovery XP (NEW)** | Tower Objects | 4,000 | 15-20% |
| **Total** | - | **24,000-28,000** | 100% |

### Kill XP Reduction

**Current Formula:**
```c
exp = mexp / (mkills + 1)
```

**Proposed Formula:**
```c
exp = mexp / pow(mkills + 1, 1.5)
```

**Effect on Repeated Kills:**

| Kill # | Current XP | Proposed XP | Reduction |
|--------|------------|-------------|-----------|
| 1st | 100% | 100% | 0% |
| 2nd | 50% | 35% | 30% |
| 3rd | 33% | 19% | 42% |
| 4th | 25% | 13% | 48% |
| 5th | 20% | 9% | 55% |
| 10th | 10% | 3% | 70% |

**Rationale:** First kills of each type remain valuable. Grinding becomes rapidly pointless.

---

## REBALANCED BUILD COMPARISON

### Combat Playthrough (Clear Everything)
- Kill XP: 6,000 (diminished by new formula)
- Encounter XP: 5,000 (unchanged)
- Descent XP: 10,500 (unchanged)
- Ident XP: 2,500 (unchanged)
- Discovery XP: 2,000 (half exploration)
- **Total: ~26,000 XP**

### Stealth Playthrough (Avoid Combat)
- Kill XP: 2,000 (strategic kills only)
- Encounter XP: 4,000 (see everything)
- Descent XP: 10,500 (unchanged)
- Ident XP: 2,500 (unchanged)
- Discovery XP: 4,000 (thorough exploration)
- **Total: ~23,000 XP**

### Comparison

| Playthrough | Old Total | New Total | Change |
|-------------|-----------|-----------|--------|
| Combat | 30,000 | 26,000 | -13% |
| Stealth | 19,000 | 23,000 | +21% |
| **Gap** | 37% | 12% | Narrowed |

**New Gap:** Stealth gets ~88% of combat XP (12% penalty)

---

## DETAILED CHANGES

### 1. Kill XP Formula Change

**File:** `src/xtra2.c:2521-2559`

**Current:**
```c
exp = (mexp) / (mkills + 1);
```

**Proposed:**
```c
// Steeper diminishing returns for repeated kills
int divisor = (int)(pow((double)(mkills + 1), 1.5));
exp = mexp / divisor;

// Minimum 1 XP for any kill (prevents zero)
if (exp < 1 && mexp > 0) exp = 1;
```

**Alternative Option (Simpler):**
```c
// Hard cap after 3 kills of same type
if (mkills >= 3) {
    exp = mexp / 10;  // 10% XP after 3rd kill
} else {
    exp = mexp / (mkills + 1);
}
```

---

### 2. Discovery XP System (New)

**File:** `src/types.h`
```c
s32b discovery_exp;  /* Total experience from Tower Objects */
```

**Files:** `src/save.c`, `src/load.c`
```c
// Add to save/load routines
wr_s32b(p_ptr->discovery_exp);
rd_s32b(&p_ptr->discovery_exp);
```

**File:** `src/cmd3.c` (or appropriate pickup handler)
```c
// In pickup routine, after identifying Tower Object
if (o_ptr->tval == TV_TOWER_OBJECT) {
    int xp = tower_object_xp(o_ptr);
    gain_exp(xp);
    p_ptr->discovery_exp += xp;
    msg_format("You gain %d experience.", xp);
}
```

---

### 3. Encounter XP Bonus for Stealth

**Optional Enhancement:** Bonus XP for encountering dangerous monsters without being detected.

**File:** `src/monster2.c` (or encounter tracking)
```c
// When monster is first sighted
if (!m_ptr->encountered) {
    int new_exp = adjusted_mon_exp(r_ptr, FALSE);

    // Stealth bonus: +50% if monster wasn't alerted
    if (m_ptr->csleep > 0 || !m_ptr->ml) {
        new_exp = new_exp * 3 / 2;
        msg_print("You observe the creature undetected.");
    }

    gain_exp(new_exp);
    p_ptr->encounter_exp += new_exp;
}
```

**Effect:** Stealth players get +50% encounter XP for undetected observations.

---

### 4. Depth Milestone Bonuses (Optional)

**Concept:** Bonus XP at layer transitions to reward reaching key depths.

**Implementation:**
```c
// In dungeon.c depth tracking
if (p_ptr->depth == 6)   gain_exp(500);   // Entered Orc Warrens
if (p_ptr->depth == 10)  gain_exp(1000);  // Entered Torture Halls
if (p_ptr->depth == 14)  gain_exp(1500);  // Entered Necropolis
if (p_ptr->depth == 17)  gain_exp(2000);  // Entered Wraith Domain
if (p_ptr->depth == 19)  gain_exp(2500);  // Entered Inner Sanctum
if (p_ptr->depth == 20)  gain_exp(3000);  // Entered Pits of Despair
```

**Total Bonus:** 10,500 XP across all milestones (if implemented)

**Note:** This is optional and may inflate XP too much. Testing needed.

---

## XP CURVE PROJECTIONS

### Expected XP by Layer

| Layer | Depth | Combat Build | Stealth Build | Difference |
|-------|-------|--------------|---------------|------------|
| 1 | 1-2 | 2,500 | 2,000 | +25% combat |
| 2 | 3-6 | 5,500 | 5,000 | +10% combat |
| 3 | 7-9 | 8,500 | 8,500 | Even |
| 4 | 10-12 | 12,000 | 12,500 | -4% combat |
| 5 | 13-15 | 16,000 | 17,000 | -6% combat |
| 6 | 16-18 | 21,000 | 21,500 | -2% combat |
| 7 | 19-20 | 26,000 | 23,000 | +13% combat |

**Analysis:**
- Early game: Combat slightly ahead (but encounters are risky)
- Mid game: Stealth catches up via discovery
- Late game: Combat pulls ahead slightly due to necessary boss kills

This is acceptable because:
1. Stealth players avoid more damage, need less healing
2. Combat players take more risks, deserve slightly more XP
3. The gap is never crippling (max 25% early, 13% late)

---

## SKILL PURCHASE IMPACT

### Skill Points Affordable

**With 26,000 XP (Combat):**
- Cost formula: 100n cumulative → 100 + 200 + 300 + ... + 100n
- Sum = 100 × n(n+1)/2
- 26,000 = 100 × n(n+1)/2 → n ≈ 22 skill points

**With 23,000 XP (Stealth):**
- 23,000 = 100 × n(n+1)/2 → n ≈ 21 skill points

**Difference:** 1 skill point (4.5% fewer)

This is minimal and acceptable. Both builds remain viable.

---

## IMPLEMENTATION PLAN

### Phase 1: Kill XP Reduction
1. Modify `adjusted_mon_exp()` in `xtra2.c`
2. Test with combat build - verify ~6,000 total kill XP
3. Test with stealth build - verify ~2,000 total kill XP

### Phase 2: Discovery XP
1. Add `discovery_exp` field to player struct
2. Implement Tower Objects (see XP-003)
3. Test thorough exploration - verify ~4,000 discovery XP

### Phase 3: Optional Enhancements
1. Implement stealth encounter bonus (if desired)
2. Implement depth milestones (if desired)
3. Playtest complete runs with both builds

### Phase 4: Balance Tuning
1. Adjust kill XP exponent (1.5) if needed
2. Adjust Tower Object XP values if needed
3. Verify skill point parity between builds

---

## ALTERNATIVE APPROACHES CONSIDERED

### Option A: Flat Kill XP Reduction
```c
exp = mexp / (mkills + 1) * 0.75;  // 25% reduction
```
**Rejected:** Still allows grinding to catch up.

### Option B: Kill XP Cap
```c
if (total_kill_exp > 5000) exp = 0;
```
**Rejected:** Too punishing, feels arbitrary.

### Option C: Stealth Kill Bonus
```c
if (monster_was_asleep) exp *= 2;
```
**Rejected:** Encourages assassination over avoidance.

### Option D: Remove Kill XP Entirely (Brogue-style)
```c
// No XP from kills, only from other sources
```
**Rejected:** Too radical a change from SIL-Q tradition.

---

## SUMMARY

### Changes
1. **Kill XP:** Steeper diminishing returns (1.5 exponent)
2. **Discovery XP:** New source from Tower Objects (~4,000)
3. **Optional:** Stealth encounter bonus (+50%)
4. **Optional:** Depth milestone bonuses

### Results
- Combat builds: ~26,000 XP (down from 30,000)
- Stealth builds: ~23,000 XP (up from 19,000)
- Gap reduced from 37% to 12%
- Both builds afford ~21-22 skill points
- Grinding becomes unprofitable
- Exploration becomes rewarding

### Philosophy
The goal is not to punish combat but to **reward alternative playstyles equally**. A player who clears every room should not be significantly stronger than one who sneaks past everything. Both approaches require skill and should lead to similar outcomes.
