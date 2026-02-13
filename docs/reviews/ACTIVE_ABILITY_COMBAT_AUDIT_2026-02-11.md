# Necromancer Combat Interactivity Audit
Date: 2026-02-11  
Scope: Skill trees, active/passive balance, monster roster pressure, combat loop readability, HUD feedback

## Executive Summary
The recent `Parry` + `Defensive Stance` work is directionally correct for making combat more interactive:
- Player intent is now explicit (activation input + cooldown + duration).
- State is surfaced in the HUD via stance gems.
- Melee decision quality improved because timing matters.

The next high-value step is to apply this pattern across existing passive-heavy trees while fixing two systemic content gaps:
1. Several monster attack effects are defined in data but not resolved in combat.
2. Several monster spell tokens are defined in data but not cast/handled.

This means current combat readability improved, but systemic depth is still leaving value on the table.

## What The Data/Code Says
- Ability entries in `data/ability.txt`: 99 (`N:` lines).
- Monster entries in `data/monster.txt`: 92 (`N:` lines; includes player placeholders).
- Skill split in data (`I:` lines):
  - Melee 14, Archery 9, Evasion 11, Stealth 12, Hunting 10, Will 11, Smithing 12, Lore 20.

Monster pressure profile (from `data/monster.txt`):
- Most common flags: `SMART`, `OPEN_DOOR`, `NO_FEAR`, `RES_POIS`, `LIGHT_SENSITIVE`, `UNDEAD`.
- Most common spell families: `DARKNESS`, `SLOW`, `SCARE`, `HOLD`.
- Most common melee effects: `HURT`, `POISON`, `DARK`, `WOUND`, `BATTER`.

## Critical System Findings
1. Passive + active Defensive Stance are currently stacking
- Passive +3 evasion is granted whenever learned and stationary in `scripts/entities/player.gd:1544`.
- Active stance adds +5 evasion in `scripts/entities/player.gd:1570`.
- Result: the active state is less distinct than intended and tuning becomes brittle.

2. Defensive stance usability has hidden turn-history gating
- It requires both "not moved last turn" and "not moved/attacked this turn" in `scripts/entities/player.gd:667`.
- This is mechanically valid, but UX confusion is expected without clear precondition UI.

3. Parry lifecycle is now explicit and HUD-visible
- Activation/cooldown behavior is in `scripts/entities/player.gd:685`.
- HUD card rendering is in `scripts/ui/hud.gd:756`.
- This is a strong reusable pattern for other skills.

4. Monster attack effect mismatch (data vs runtime)
- Data includes effects like `BATTER`, `WOUND`, `DISARM`, `HALLU`, `HUNGER`, `LOSE_DEX`, `TERRIFY` in `data/monster.txt`.
- Resolver in `scripts/entities/monster.gd:849` does not handle those tokens.
- This reduces monster identity and combat variety.

5. Monster spell mismatch (data vs runtime)
- Data includes spell tokens like `THROW_WEB`, `RALLY`, `HATCH_SPIDER`, `DIM`, `SNG_BINDING`, `SNG_PIERCING` in `data/monster.txt`.
- Spell dispatch in `scripts/entities/monster.gd:1222` handles only a subset.
- Current roster behavior is flatter than authored design.

6. Turn interaction clarity is good in code but weak in player-facing command language
- Wait is supported in player input (`Input.is_action_just_pressed("wait")`) at `scripts/entities/player.gd:2410`.
- Input binding is `.`/numpad5 in `project.godot:97`.
- If players think "stand still" means no legal action, stance systems feel inconsistent.

## Design Principle To Scale Forward
Convert passive effects into **Reactive Windows**:
- Trigger: explicit action or clear event.
- Window: short active duration.
- Tradeoff: cooldown, resource, or opportunity cost.
- Readability: persistent HUD icon + turns + effect magnitude.
- Counterplay: monster or terrain can punish misuse.

This preserves depth while improving learnability and "I made that happen" player agency.

## Top 10 Highest-Value Upgrades
Ordered by player impact x implementation leverage.

1. Unify stance logic into one explicit Guard system
- Replace passive stationary +3 with explicit stance state only.
- Keep active `Defend` as the sole source of stance bonus.
- Hook: `scripts/entities/player.gd:1544`, `scripts/entities/player.gd:1570`.

2. Add explicit "Wait/Prepare" affordance to stance UX
- Keep mechanical gate but add clear precondition feedback in HUD:
  - `Ready this turn` / `Need 1 still turn`.
- Hook: `get_combat_stance_indicators()` in `scripts/entities/player.gd:718`, HUD renderer `scripts/ui/hud.gd:756`.

3. Implement missing monster attack effects from authored data
- Add handling for: `BATTER`, `WOUND`, `DISARM`, `HALLU`, `HUNGER`, `LOSE_DEX`, `TERRIFY`.
- Hook: `scripts/entities/monster.gd:849`.
- This instantly increases encounter variety without new content generation.

4. Implement missing monster spell tokens from authored data
- Add behavior for: `THROW_WEB`, `RALLY`, `HATCH_SPIDER`, `DIM`, `SNG_BINDING`, `SNG_PIERCING`.
- Hook: `_cast_spell()` in `scripts/entities/monster.gd:1222`.
- This restores authored roster identity and makes anti-caster play more meaningful.

5. Convert `Controlled Retreat` from passive trigger to active "Withdraw"
- Active window (1 turn): stepping away grants counterstrike + no AoO.
- Cooldown 4-6 turns.
- Hook: existing state/action tracking in `scripts/entities/player.gd` + movement event hooks in `scripts/systems/turn_system.gd:260`.

6. Convert `Flanking` into active "Sidestep" micro-ability
- Next lateral move around adjacent target grants precision strike.
- Cooldown short (2-3 turns) to keep tempo.
- Hook: player movement path + adjacent checks already exist in combat helpers.

7. Convert `Concentration` into visible "Focus" meter + active release
- Build stacks while holding target; consume stacks for one empowered hit.
- Hook: consecutive attack tracking already exists in `scripts/entities/player.gd:1454`.

8. Turn `Outwit` into reactive anti-crit ability
- Active window: "Read Attack" reduces or nullifies next incoming crit.
- Adds meaningful decision before elite hits.
- Hook: crit flow in `scripts/entities/entity.gd:485`.

9. Turn `Escape Artist` into active cleanse/mobility button
- Immediate self-cleanse from web/entrance/slow with short dash or free step.
- Cooldown-based panic tool improves accessibility for new players.
- Hook: status checks in `scripts/systems/status_effects.gd` and movement input pipeline.

10. Add monster intent telegraph strip (1-turn forecast)
- Show nearest visible hostile intent: `Move`, `Strike`, `Cast`, `Special`.
- Enables tactical response to reactive abilities (parry/guard/withdraw/read attack).
- Hook: AI decisions in `scripts/entities/monster.gd`, HUD status row in `scripts/ui/hud.gd`.

## Recommended Implementation Order (Low Risk, High Return)
1. Fix authored data mismatches first (items 3 and 4).
2. Unify Guard/Parry clarity (items 1 and 2).
3. Add two new active conversions for Evasion/Melee (items 5 and 6).
4. Add one offensive pacing layer (item 7).
5. Add one defensive reaction tool (item 8).
6. Add intent telegraph (item 10) after behavior fidelity is fixed.

## Accessibility Notes
- Keep all reactive abilities using the same HUD card grammar:
  - Name, exact bonus, `Active: N`, `CD: N`.
- Ensure every gating condition has direct player feedback.
- Keep keybind discoverability synchronized across:
  - `project.godot`
  - `scripts/ui/help_overlay.gd`
  - `README.md`
  - `docs/manual/THE_NECROMANCER_MANUAL.md`

## Why This Works
This plan increases fun by raising tactical expression per turn while keeping complexity bounded:
- No new content pipeline required.
- Mostly system-level changes on existing scaffolding.
- Immediate payoff in readability, fairness, and encounter texture.
