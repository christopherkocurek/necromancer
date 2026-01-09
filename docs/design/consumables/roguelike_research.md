# Roguelike Consumable Systems Research
## The Necromancer - Consumables Audit

**Generated**: 2026-01-09
**Sources**: Web research on Brogue, DCSS, Caves of Qud, Cogmind

---

## Executive Summary

Different roguelikes take vastly different approaches to consumables:
- **Brogue**: Simplified, focused, removed ID system in some forks
- **DCSS**: Complex, deep skill integration with Evocations
- **Caves of Qud**: Full crafting metasystem with cooking and tinkering
- **Cogmind**: Avoided traditional consumables, all items are "part-based"

---

## Brogue

### Philosophy
Brogue aims for elegance and streamlined design. Recent forks have simplified even further.

### Key Features
| Feature | Standard Brogue | Brogue Lite Fork |
|---------|-----------------|------------------|
| ID System | Timer-based | Removed entirely |
| Negative Items | Present | Removed |
| Cursed Gear | Yes | No |
| Potions | ~10 types | Fewer, no negatives |

### Innovations
- **Potions of Life**: Heal AND permanently increase max HP
- **Charms**: Recharging items (between potion and wand)
- **Throwable Buffs**: Speed/invis potions can be thrown on allies
- **Potion of Respiration**: Gas immunity (new tactical option)

### Lessons for Necromancer
1. Consider removing negative consumables after identification
2. "Charms" concept could work for reusable items
3. Throwable potions create tactical options

---

## DCSS (Dungeon Crawl Stone Soup)

### Philosophy
Deep skill integration with rich item variety. Evocations skill makes devices powerful.

### Evocations Skill System
```
Evocations Skill  | Effect
0-4               | Basic wand use, moderate power
5-10              | Meaningful improvement
10-15             | Boxes of beasts, sacks of spiders "do amazing things"
15+               | Maximum evocable power
```

### Recent Innovations (v0.32)
- **Inventory Overhaul**: Split into 4 pages (gear, potions, scrolls, evocables)
- **New Evokers**:
  - Gell's Gravitambourine (pull + bind enemies)
  - Charlatan's Orb (skill boost with downside)
  - Orbs scaling with Evocations skill

### Key Design Principle
> "Use consumables liberally... you only get one chance to live through an encounter."

### Lessons for Necromancer
1. Strong skill integration (Evocations) makes devices meaningful
2. Creative evokers beyond standard wand/staff
3. Inventory categorization helps management
4. Encourage consumable use through balance

---

## Caves of Qud

### Philosophy
Maximum player creativity through systemic design. Everything interacts.

### Tinkering System
```
Tier     | What You Can Do
Tinker I | See bits, basic crafting
Tinker II| More complex items
Tinker III| Rare and powerful items
```

- Requires finding data disks for schematics
- Materials use bit system (letter/number codes)
- Can craft weapons, armor, injectors, mods

### Cooking System (Carbide Chef)
```
Ingredient Effect Types:
1. Basic Effect (always obtained)
2. Trigger Condition (action required)
3. Triggered Effect (stronger, conditional)
```

- Create custom recipes with consistent effects
- Gain mutations through cooking (even as non-mutant)
- Powerful stat boosts possible

### Alchemist NPC
- Sells rare liquids in single-dram quantities
- Acts as liquid source for crafting

### Design Philosophy
> "A broad palette that didn't feel prescriptive that acts like a raw physics for you to build on top of."

### Lessons for Necromancer
1. Cooking/combining system creates emergent gameplay
2. Recipes with conditions add depth
3. Can gain abilities through consumables
4. Authored data + crafting metasystem = rich content

---

## Cogmind

### Philosophy
Radically different - avoided traditional consumables entirely.

### Why No Consumables
1. **Inventory Focus**: Nearly every item is attachable part
2. **Separate inventory problem**: Would need dedicated consumable storage
3. **Weight not used**: Can't balance by weight
4. **All parts are consumable**: Everything degrades/breaks

### Alternative Approaches
| Approach | Example | Notes |
|----------|---------|-------|
| Disposable | CPS Tube (2 shots) | "Might miss, too mean for 1" |
| Degrading | All parts | Limited integrity |
| Unique Resources | Ammo types | Storage/rarity balance |
| Special Items | Protomatter | Created for specific mode |

### Design Insight
> "Consumable design is useful since it offers really tight control, but I prefer to avoid overusing it if there are any other options available, since it's kinda boring."

### Lessons for Necromancer
1. Consider if consumables add meaningful choice
2. Part degradation can replace consumables
3. Unique resources create scarcity
4. Avoid consumables if other options exist

---

## Comparison Matrix

| Feature | Brogue | DCSS | CoQ | Cogmind | Sil-Q |
|---------|--------|------|-----|---------|-------|
| Potions | Yes | Yes | Yes (injectors) | No | Yes |
| Scrolls | Yes | Yes | No | No | No (horns) |
| Staves/Wands | Staves | Both | Artifacts | Parts | Staves |
| Crafting | No | No | Yes (deep) | Part-based | No |
| ID System | Timer | Use-ID | Knowledge | N/A | Ability-based |
| Skill Integration | No | Evocations | Tinkering | Part skills | Channeling |

---

## Recommendations for Necromancer

### High Priority
1. **Keep horns** - Thematic, distinct from generic scrolls
2. **Strengthen Channeling** - DCSS shows skill integration works
3. **Consider throwable potions** - Brogue shows tactical depth

### Medium Priority
4. **Simple herb combining** - CoQ's cooking lite
5. **Remove negative consumables after ID** - Brogue Lite approach
6. **Add stealth consumables** - Gap in current system

### Low Priority / Research
7. **Full alchemy crafting** - High complexity (CoQ level)
8. **Combat staves** - Gandalf-style, significant rework
9. **Wands** - Only if distinct role identified

---

## Sources

- [Brogue Official Site](https://sites.google.com/site/broguegame)
- [gBrogue Fork](https://github.com/gbelo/gBrogue)
- [DCSS Official](https://crawl.develz.org/)
- [DCSS Changelog](https://crawl.dcss.io/crawl/changelog.txt)
- [Caves of Qud Tinkering Wiki](https://wiki.cavesofqud.com/wiki/Tinkering)
- [Cogmind Consumables Blog](https://www.gridsagegames.com/blog/2014/08/consumables/)
- [Cogmind Item Expansion](https://www.gridsagegames.com/blog/2023/11/post-balance-cogmind-item-expansion/)

---

*Research generated for RESEARCH-001*
