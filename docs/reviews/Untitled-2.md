/rogue-skill
/necromancer-godot

  Implement the Lore Tree v4 Redesign. The full proposal is saved in Supermemory (ID: 8XQKxQiVTLc2zsrMDkmcAr) — search for "Lore Skill Tree Redesign
   v4" to pull it. Also check MEMORY.md for the compact summary under "Lore Tree Redesign v4."

  Key files to modify:
  - scripts/systems/ability_system.gd (main rewrite — 915 lines currently)
  - data/ability.txt (ability definitions — IDs 140-157 currently, need renaming/reordering/new entries)
  - scripts/entities/player.gd (combat wiring for Light of the Eldar shadow damage, Lore of Naming Will bonus, new song effects)
  - scripts/core/constants.gd (LoreAbility enum needs updating)
  - tests/unit/test_enchantments.gd or new test_lore.gd (tests for all new/changed abilities)

  The 19 abilities in order:
  1. Lore of Hidden Ways (renamed Silence, Lore 1) — fix permanent perception drain bug at line 532
  2. Word of Opening (Lore 1)
  3. Deep Memory (moved to Lore 2)
  4. Herbcraft (Lore 2, NOW SUSTAINED with 1 voice/turn — stop bleeding, +50% rest regen, 2x herbs)
  5. Lore of Naming (NEW, Lore 3 — +2 Will contests vs known creature types, reveal stats)
  6. Light of the Eldar (Lore 3 — combined with old Song of Trees: +1 light/3 Lore, shadow creatures -2 atk/-2 eva, wraiths 1 dmg/turn)
  7. Word of Command (moved to Lore 4, 12-turn CD, NO +5 advantage)
  8. Song of Freedom (Lore 4 — Will contest for status immunity, failure disrupts song)
  9. Song of Lorien (NEW, Lore 5 — alertness drain, monsters drift to sleep)
  10. Lore of Endurance (Lore 5 — +lore/2 Will, [2d2] prot, +2 temp Will after damage)
  11. Song of Banishment (Lore 6 — now deals [lore/2]d6 damage to undead + 5-turn flee)
  12. Word of Domination (NEW, Lore 6 — charm monster to fight for you, lore/2 turns)
  13. Song of Aule (Lore 7 — +1 weapon dmg/+1 armor prot, forge: +3 smithing, Aule-touched items)
  14. Song of Healing (NEW, Lore 7 — heal lore/2 per turn, mobile, also heals dominated monsters)
  15. Word of Warding (renamed Shutting, Lore 8 — place impassable sigil tiles, max 3, lore*3 duration)
  16. Word of Authority (renamed Mastery, Lore 8 — AOE stun via presence, not domination)
  17. Word of Unmaking (NEW, Lore 9 — dispel enchantments, destroy terrain, [lore]d6 to undead, stun living, 50% chance -1 max voice permanently)
  18. Mastery of Themes (renamed Device Mastery, Lore 10 — dual sustained abilities)
  19. Grace (Lore 12 — +1 GRA)

  REMOVED: Lore of Battle (line 460 bug, taunt wrong for solo), Deadly Lore, Song of Trees (merged into Light of the Eldar), Curse Breaking (already
   in Will).

  All sustained abilities: +[cost*3] monster perception in radius 5 (noise penalty). One active at a time until Mastery of Themes.

  New systems needed: Domination AI, Warding sigil tiles (new tile type), shadow creature flags on monster data, song noise in detection system.

  Do the implementation. Run tests after each stream. Run bot harness with 10 runs per lore character archetype. capture reports and use telemetry on skills invested & abilities used. the lore bots need some brains to know how to play their characters