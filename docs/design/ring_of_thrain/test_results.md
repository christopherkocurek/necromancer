# Ring of Thráin Test Results

## Test Date: 2026-01-09

## Implementation Summary

### Stats Applied
- **+3 Will** (via WILL flag with pval=3)
- **+3 Grace** (via GRA flag with pval=3)
- **LIGHT_CURSE** (requires Remove Curse to remove)
- **FREE_ACT** and **SUST_GRA** retained

### Curse Mechanic: Forced Deep Memory
- When Ring is equipped, automatically activates **Song of Delvings** (SNG_DELVINGS)
- Cannot change away from this song while ring is worn
- Song drains 1 spirit every 3 turns
- Player message: "The Ring whispers secrets of the deep places..."
- Attempt to change song message: "The Ring's whispers fill your mind - you cannot stop."

### Unequip Behavior
- Ring has LIGHT_CURSE, preventing normal removal
- **Curse Breaking ability** or **Remove Curse** required
- When removed, song stops automatically
- Player message: "The Ring's whispers fade from your mind."

## Code Changes

### Files Modified

1. **lib/edit/artefact.txt**
   - N:175-178 (all Ring variants)
   - Added WILL flag, LIGHT_CURSE flag
   - Normalized pval to 3
   - Updated descriptions

2. **src/spells1.c**
   - Added `ring_of_thrain_equipped()` helper function (line 5111-5124)
   - Modified `change_song()` to prevent changing away from SNG_DELVINGS (line 5140-5146)

3. **src/externs.h**
   - Added declaration for `ring_of_thrain_equipped()` (line 779)

4. **src/cmd3.c**
   - `do_cmd_wield()`: Auto-start SNG_DELVINGS when ring equipped (line 727-733)
   - `do_cmd_takeoff()`: Stop SNG_DELVINGS when ring removed (line 836-848)

## Manual Test Checklist

### Test 1: Equip Ring
- [ ] Equip Ring of Thráin
- [ ] Verify message: "The Ring whispers secrets of the deep places..."
- [ ] Verify Song of Delvings activates (check status bar)
- [ ] Verify dungeon layout starts revealing

### Test 2: Cannot Stop Song
- [ ] Try to change song or end song
- [ ] Verify message: "The Ring's whispers fill your mind - you cannot stop."
- [ ] Verify song remains active

### Test 3: Spirit Drain
- [ ] Observe spirit (voice) draining over time
- [ ] Verify drain rate: 1 spirit per 3 turns

### Test 4: Ring Cannot Be Removed Normally
- [ ] Try to remove the ring
- [ ] Verify message about being unable to part with it

### Test 5: Remove Curse Works
- [ ] Use Remove Curse on ring OR use Curse Breaking ability
- [ ] Remove the ring
- [ ] Verify message: "The Ring's whispers fade from your mind."
- [ ] Verify Song of Delvings stops

### Test 6: Stats Check
- [ ] Verify +3 Will bonus in character sheet
- [ ] Verify +3 Grace bonus in character sheet

## Thematic Notes

The implementation captures Tolkien's theme of the corrupting power of the Dwarf-rings:
- Thráin was consumed by his Ring's power, driven mad in Dol Guldur
- The "whispers" that never cease represent the Ring's grip on the bearer
- Spirit drain represents the slow consumption of the wearer's will
- The player faces a choice: keep the vision power and risk depletion, or find a way to break free

---

*Test document for Ring of Thráin curse implementation (FIX-001 through FIX-004)*
