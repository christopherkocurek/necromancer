# Forge Loot Curve + Ability VFX Report (2026-02-12)

## 1) Forge Material Spawn Curve by Depth
Design goal: smithing builds should feel consistently rewarded with stronger crafting outcomes deeper down, without removing early-run reliability.

### Implemented floor-depth mapping
- 1 depth = ~100 feet.
- Depths 1-5 (100-500 ft): 100% Broken Glowing.
- Depths 6+ (600+ ft): each of the 3 forge material spawns rolls Broken Strange chance by curve.

### Implemented strange chance curve
- Depth 1-5: 0%
- Depth 6-7: 12%
- Depth 8-9: 25%
- Depth 10-11: 40%
- Depth 12-13: 56%
- Depth 14-16: 72%
- Depth 17+: 85%

### Category balancing
- Each forge spawns exactly 3 broken materials total.
- Each spawn independently rolls category: weapon / armor / jewelry (uniform 33/33/33).
- Then rarity roll is applied (glowing vs strange).

### Why this is balanced
- Preserves guaranteed early crafting loop quality (no early strange dilution).
- Midgame starts introducing meaningful rare outputs without full replacement.
- Deep game heavily favors strange while preserving occasional glowing variety.

## 2) Ability Animation Coverage Audit
Primary reason animations felt missing: lore/voice activations were only partially mapped in centralized VFX dispatch.

### Added centralized VFX coverage (floater manager ability routing)
- Hidden Ways (140)
- Deep Memory (142)
- Light of the Eldar (145)
- Word of Opening (141)
- Word of Command (146)
- Song toggles: Freedom/Lorien/Aule/Healing/Trees (147/148/152/153/159)
- Song of Banishment (150)
- Word of Domination (151)
- Word of Warding / Authority / Unmaking (154/155/156)

### Expected result
- Every activated lore/voice ability now triggers visible player-centric feedback (flash/particles/rings/zoom pulse where applicable), instead of only text output.
