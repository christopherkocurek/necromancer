# The Necromancer
## Player's Manual (Beta v1.1)

**Version:** Beta v1.1  
**Date:** 2026-02-14

## Contents

1. About The Necromancer
2. Who Will Like It?
3. The Basics
4. Notes for Sil/Sil-Q Players
5. Race and House
6. Stats
7. Skills
8. Combat
9. Stealth and Detection
10. Light and Darkness
11. Voice and Lore
12. Experience and Abilities
13. Items and Utility Slots
14. Winning and Losing
15. Commands
16. Interface Reference

## 1. About The Necromancer

The Necromancer is a tactical roguelike set in Dol Guldur in the Third Age.

You are trying to do something difficult and specific: descend into the fortress, get Thrain's map and key, and escape alive. The game is short by classic roguelike standards, but each run is dense. There is little filler and little forgiveness.

The design priorities are:
- tactical combat where position matters,
- stealth that changes outcomes,
- scarce resources that force tradeoffs,
- clear run identity from race/house/trait and ability choices,
- permadeath that makes knowledge valuable.

## 2. Who Will Like It?

You will probably like this game if you want:
- a difficult but learnable roguelike,
- turn-by-turn tactical decisions,
- Tolkien tone without generic spell-slinging fantasy,
- a game where planning is more important than grinding.

You may dislike it if you want:
- relaxed progression,
- low failure rates,
- reversible mistakes,
- long power-fantasy build-up with little pressure.

## 3. The Basics

You begin with limited equipment and limited options. Your first floors are about stabilizing your run:
- find reliable offense,
- secure survivable positioning tools,
- protect your light and voice economy,
- spend XP deliberately.

Runs are not won by clearing everything. They are won by managing risk and preserving tempo.

### Beta v1.1 Win State

In Beta v1.1, escape is implemented as:
- get Thrain's map and key,
- return to floor 1,
- take upstairs,
- receive a beta victory message and return to menu.

The full post-escape chapter is planned for a later build.

## 4. Notes for Sil/Sil-Q Players

This game keeps the tactical spirit but changes a lot of details.

Key differences:
- Dol Guldur / Third Age context instead of Angband / First Age.
- Lore voice economy and sustained effects are central.
- Ability activation is hotbar-driven and UI-forward.
- Selected utility actions are minor actions in Beta v1.1 (not full-turn taxes).
- Beta escape condition is quest-gated floor-1 upstairs.

Do not assume exact parity on values or timings. Read outcomes from the current log/UI state.

## 5. Race and House

Race and house are not cosmetic. They affect stat profile, proficiency, and early skill economics.

General guidance:
- easier starts tend to have cleaner early combat/utility options,
- harder starts can have stronger long-term specialization if piloted well,
- house affinity is most valuable when you buy into it early.

Practical rule:
- if you choose an affinity, spend your first significant XP in that lane.

## 6. Stats

Your build is constrained by stat budget. Over-specializing gives a sharp edge and a sharp weakness.

### Strength
- improves physical output and handling heavier gear,
- supports force-based solutions.

### Dexterity
- improves precision and reactive survival lanes,
- strongly supports positional play.

### Constitution
- improves raw survivability,
- gives room for mistakes in unknown fights.

### Grace
- improves voice/lore potential,
- supports control and sustain-heavy play.

Practical rule:
- first wins usually come from balanced survivability, not maximum peak damage.

## 7. Skills

Skills are your progression backbone. You buy power with XP; there are no traditional character levels carrying you.

Skill design intent:
- each point should alter expected outcomes,
- skill choice should shape your tactical language,
- progression should demand opportunity cost.

When deciding upgrades, ask:
1. Does this help me survive my current failure mode?
2. Does this create a new tactical option I can actually use now?
3. What am I giving up by delaying another lane?

## 8. Combat

Combat is decided by positioning, timing, and action economy.

### Core principles
- do not trade in open multi-angle tiles when avoidable,
- doorways and corners reduce incoming variance,
- disengaging one turn earlier is usually better than one turn later,
- setup actions only pay off if they do not cede lethal tempo.

### Beta v1.1 minor-action rule
Selected non-attack utility abilities are treated as minor actions. This exists to prevent active play from being worse than passive play by default.

If a fight feels impossible, check whether you are spending too many full turns on setup.

## 9. Stealth and Detection

Stealth is not a side mechanic. It is a primary survival route.

Use stealth to:
- choose engagement order,
- avoid unnecessary multi-enemy fights,
- get clean openings.

Detection pressure rises quickly when you mismanage visibility/noise space. If stealth breaks, reposition before committing to an inferior brawl.

## 10. Light and Darkness

Light controls information. Information controls decisions.

Losing light radius means:
- later threat recognition,
- fewer safe pathing choices,
- worse turn economy under surprise contact.

### Beta v1.1 anchor values
- Elvish Light: +2 radius, infinite.
- Jeweled Lamp: +4 radius, infinite.

Rule of play:
- always know what your next light source is before your current one fails.

## 11. Voice and Lore

Voice is a scarce tactical resource.

Design in Beta v1.1:
- sustained effects are strong but not free,
- sustain suppresses effective regen,
- rest loops should not produce near-infinite casting.

Use voice to stop losses, not to decorate wins.

If you die with full voice and no plan, you are under-using a core system.

## 12. Experience and Abilities

Experience is your most flexible resource after information.

Good XP spending:
- addresses your current run weakness,
- unlocks tools you will actually press,
- keeps at least one emergency lane viable.

Bad XP spending:
- buys future fantasy while present threats kill you now,
- stacks damage without fixing access, defense, or tempo.

## 13. Items and Utility Slots

Utility slots should reduce friction, not add it.

Beta v1.1 includes fixes so interactive consumables/devices can be triggered from proper utility paths when assigned correctly.

If activation fails, verify:
- item type supports activation in context,
- item is in the expected container/slot,
- no state rule is blocking use.

## 14. Winning and Losing

You win by escaping with Thrain's map and key.

You lose when:
- HP reaches zero,
- or you make tempo/resource decisions that guarantee collapse before you can reset.

Most deaths are not single-turn bad luck. They are delayed consequences of 5-20 earlier decisions.

Use the death screen and log as your post-run analysis tool.

## 15. Commands

High-frequency commands:
- `W/A/S/D`, `H/J/K/L`, arrows: move
- `Y/U/B/N`: diagonal move
- `.`: wait
- `Enter`: stairs / context confirm
- `G`: pick up
- `I`: inventory
- `T` or `@`: tome
- `V`: voice/lore
- `;`: stealth toggle
- `M`: minimap
- `X`: look mode
- `Esc`: settings/pause

Use in-game help/settings for complete bindings and rebinding.

## 16. Interface Reference

### Main gameplay
![Main gameplay view](../assets/manual/gameplay.png)

### Gameplay with expanded minimap
![Gameplay with expanded minimap](../assets/manual/gameplay_minimap.png)

### Inventory panel
![Inventory panel](../assets/manual/inventory.png)

### Tome and ability management
![Tome and ability management](../assets/manual/tome.png)

### Targeting and look mode
![Targeting interface](../assets/manual/targeting.png)
![Look mode interface](../assets/manual/look_mode.png)

---

If you remember one rule, remember this:

**Preserve options.**  
Most winning turns come from decisions made earlier.
