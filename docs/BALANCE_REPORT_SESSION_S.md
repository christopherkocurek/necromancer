# The Necromancer — Victory Path Balance Report (Session S)

## Summary

3 of 5 tested builds are clearly viable for completing all 20 floors.

| Build | Survival Estimate | Verdict |
|-------|-------------------|---------|
| 1. Melee Fighter (STR/Melee) | 55-65% | Viable |
| 2. Stealth Assassin (DEX/Stealth) | 45-55% | Viable but fragile |
| 3. Lore Scholar (GRA/Lore) | 50-60% | Viable, high skill cap |
| 4. Balanced Explorer (even stats) | 40-50% | Viable but weakest path |
| 5. Smithing Specialist (STR/Smithing) | 65-75% | Strongest build |

## Key Findings

### 1. Monster XP Scaling (FIXED)
**Problem:** All monsters gave flat 10 XP regardless of depth.
**Fix applied:** XP now scales as `depth * 5 + rarity * 10` (min 10). Unique bosses get 3x.
- Floor 1 rat: ~15 XP → Floor 15 wraith: ~85 XP → Floor 20 Void Wraith: ~110 XP

### 2. Protection Dice Damage Floor
Monsters at depth 10+ have 3d4 to 4d4 protection. Low-STR builds (Scholar, Assassin)
deal 0 effective melee damage. This is intentional — these builds use abilities/stealth.

### 3. Balanced Build is Weakest
The XP cost curve (`100 * N` per skill point) penalizes broad investment.
8 skills at level 5 costs 12,000 XP. 2 skills at level 10 costs 11,000 XP.
Specialization is mathematically superior.

### 4. Word of Command Power Spike
At Lore 8+, Word of Command (AOE fear+stun, 3 voice, 4+ tile radius) trivializes
most encounters. Scholar build has 71 voice = 23 uses per rest. Consider monitoring.

### 5. Sauron is an Escape Encounter
500 HP, +30 evasion, +35 attack, 5d12 damage. Unkillable by design.
Floor 20 requires reaching Thrain's Shade and escaping, not combat.

## Difficulty Modes (IMPLEMENTED)

| Mode | XP | Monster Damage | Items | Perception | Traps | Rest Heal |
|------|-----|----------------|-------|------------|-------|-----------|
| Easy | +50% | -25% | +25% | normal | revealed | yes |
| Normal | 1x | 1x | 1x | normal | hidden | yes |
| Hard | 1x | 1x | -20% | +3 | hidden | yes |
| Ironman | 1x | 1x | -20% | +3 | hidden | no |
