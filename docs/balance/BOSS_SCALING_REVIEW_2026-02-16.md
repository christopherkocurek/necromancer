# Boss Scaling Review - 2026-02-16

## Scope
- Layer 1 spider boss path:
  - `Broodmother` (base monster template).
  - `Ungoliant's Broodmother` (depth-3 transition boss title variant).

## Findings
- `Broodmother` was over-bursting for early builds and not expressing intended identity.
- `HATCH_SPIDER` existed in data but was not implemented in runtime spell execution, so the fight skewed toward web/slow pressure instead of brood-control behavior.
- Transition boss could look visually wrong in some runs because title override did not force a unique visual treatment.
- Early-depth generation had a safety gap that could leak Broodmother into depth 1 via out-of-depth rolls.

## Changes Shipped
- Depth safety:
  - Broodmother hard-gated from spawning before depth 3 in both initial spawn and periodic spawn paths.
- Broodmother behavior:
  - Implemented `HATCH_SPIDER` in `Monster._cast_spell`.
  - Added hatch routine to summon nearby spiderlings.
- Spider control spam:
  - Added spell cooldown framework.
  - Applied cooldown to web-spit (`WEB`) and hatch casting.
- Damage/HP rebalance:
  - `Broodmother` HP dice: `16d4 -> 14d4`.
  - Bite damage: `(+10, 2d8) -> (+7, 2d6)`.
  - Spell pressure: `SPELL_PCT_20 | POW_8 -> SPELL_PCT_12 | POW_6`.
- Transition boss tuning:
  - `Ungoliant's Broodmother` depth-3 boss `hp_mult`: `1.8 -> 1.45`.
- Visual identity:
  - `Ungoliant's Broodmother` now forces Broodmother base sprite id and applies a darker tint variant at spawn.

## Remaining Risk
- Crit spikes can still create lethal turns if multiple pressure sources overlap (melee hit + control + terrain).
- If a fully bespoke Ungoliant sprite is required, a dedicated atlas cell should be added in tileset generation and mapped as a separate monster id.

## Next Validation Pass
- Run targeted combat sims for depth 3 with non-glass-cannon baseline:
  - Full HP, defense-focused build, no perfect consumable play.
- Track:
  - Max single-turn boss damage.
  - Turns-to-kill window.
  - Hatch cadence and minion pressure.
  - Web-lock uptime under cooldown rules.
