# Necromancer Godot — Auto Memory

## Project State (Session S, 2026-02-08)
- **Branch:** necromancer-godot, latest commit `a7ef179`
- **Tests:** 125/130 passing, 684 assertions, 5 pending baseline
- **Game completeness:** ~92% — full game loop works, needs balance tuning + web export

## Critical Known Issues
1. **Smithing is oversimplified** — only attack/evasion bonuses. Missing: damage dice, parry, weight, protection dice. Needs full weapon/armor stat workstream. MOST BROKEN FEATURE.
2. **Game too easy** — projected 40-75% win rates on Normal (roguelike target: 1-5%). Need 100 survival bot runs for empirical data before adjusting.
3. **Word of Command OP** — AOE fear+stun at Lore 8+, 23 uses per rest from 71 voice pool. Trivializes floors.
4. **Song effects arbitrary** — Freedom (+3 eva) and Trees (+5 stealth) need mechanical grounding. Aule is fine.
5. **Victory screen crashes** — exists but not instantiated in main.gd. 30-min fix.
6. **No HTML5 export** — needs export_presets.cfg in Godot editor.

## Key Formulas
- **Combat:** d20 + attack vs d20 + evasion. Damage = weapon_dice + STR_bonus - protection_roll
- **Stealth:** d10 + perception + difficulty_bonus vs d10 + stealth_score. Distance: max(0, 6-dist)
- **Light radius:** base 1 + source (torch+2, lantern+3, lamp+4) + abilities - depth_darkness(0 to -3)
- **Smithing success:** min(smithing * 8, 95). Forges every 2 floors to depth 10.
- **Monster XP:** max(10, depth*5 + rarity*10), 3x for UNIQUE. Player gets 1.3x multiplier on all XP.
- **Skill cost:** 100 * (level+1) per point. Affinity discount: -100 per level.
- **HP:** 24 * 1.2^CON. Voice: 20 * 1.2^Grace. Voice regen: max_voice/150 per turn.

## Tile System
- Row 18 = DALL-E terrain. INSCRIPTION (enum 27) at (10,18)/(11,18) — placeholder art.
- BONE_PILE (enum 24) reuses RUBBLE sprite — its row 18 slot was repurposed for INSCRIPTION.
- Rows 0-5: terrain pairs. Rows 6-9: player. Row 10: effects. Rows 11-17: items. Row 19: artifacts. Rows 24-26: monsters.

## Lessons Learned
- Flat XP values break roguelike economies — always scale rewards with risk/depth.
- Stacking ease-of-play changes compounds fast. Each individual buff is small; together they halve difficulty.
- d10 vs d20 is a huge design choice: d10 makes every +1 worth 10%, d20 makes it 5%. Use d10 where skill investment should feel impactful (stealth), d20 where variance is desired (combat).
