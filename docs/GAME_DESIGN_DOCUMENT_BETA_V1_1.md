# The Necromancer
## Game Design Document (Beta v1.1)

**Version:** Beta v1.1  
**Date:** 2026-02-14  
**Engine:** Godot 4.6  
**Positioning:** A Third Age tactical roguelike in the Sil-Q lineage, rebuilt for modern readability while preserving permadeath rigor.

## 1. Design Intent

The Necromancer is built around one uncompromising loop: **delve, recover, escape**.

The player enters Dol Guldur, descends under escalating pressure, secures **Thrain's map and key**, then ascends to escape.

Core design law:
- decisions must remain meaningful under stress,
- information must be incomplete but legible,
- failure must be teachable,
- victory must be earned, not accumulated.

## 2. Pillars

1. **Tolkien Fidelity**
Language, threats, and stakes are anchored to the Third Age and written with literary restraint.

2. **Sil-Q Mechanical DNA**
Tactical positioning, high-lethality exchanges, and pressure-based resource play remain central.

3. **Agency Under Constraint**
At least one strategically valid alternative should exist in most dangerous turns.

4. **Readable Systems**
Complexity is welcome; opacity is not. UI/logs must let players reason about outcomes.

5. **Permadeath Integrity**
Losses stand. Mastery is learned through iteration.

## 3. Core Run Structure

1. Character setup (race, house, trait, stats).
2. Early-floor stabilization (weapon line, defense line, light line).
3. Mid-depth specialization (skills and abilities with explicit tradeoffs).
4. Objective acquisition (Thrain's map and key).
5. Ascent phase under accumulated pressure.
6. Escape or death.

## 4. Beta v1.1 Win State

Beta v1.1 uses a practical completion gate:
- Upstairs on floor 1 checks objective state.
- Escape is allowed only if the player has **Thrain's map and key**.
- Success triggers: `"Congratulations, you escaped! Now to meet Gandalf..."`
- Player returns to menu.

This is intentionally a beta endpoint before a full exterior chapter is shipped.

## 5. Action Economy Policy

Turn cost must track impact.

- Movement and attacks consume full turns.
- Non-transformative setup/stance/utility actions should generally be **minor actions**.
- This includes cases like parry prep, mark-like setup, and circular guard style activation unless balance demands exception.

Rationale: active tactical play should not be structurally weaker than passive play.

## 6. Economy Design

## 6.1 Light Economy

Target behavior:
- darkness creates pressure and uncertainty,
- depth remains tactically playable,
- players can plan around light rather than lose to arbitrary blindness.

Beta v1.1 anchors:
- Torch: +2
- Lantern: +3
- Elvish Light: +2, infinite
- Mallorn Torch: +3
- Jeweled/Feanorian Lamp: +4, infinite
- Light of the Eldar aura: +2

## 6.2 Voice Economy

Voice should feel scarce, powerful, and build-defining.

Beta direction:
- reduce exploit loops from sustained effects,
- increase opportunity cost of sustain states,
- preserve viability of lore-forward runs.

## 6.3 Utility and Consumables

If an item is prepared for utility use, activation path should be fast and reliable in combat context. Inventory micromanagement should not be the dominant difficulty.

## 7. Combat, Stealth, and Information

## 7.1 Combat Identity

- positional advantage over raw stat inflation,
- high lethality with recoverable tactical errors,
- encounter triage as expected skill.

## 7.2 Stealth Role

Stealth is a primary survival language:
- controls engagement order,
- reduces chain pulls,
- enables objective-focused routing.

## 7.3 Information Surfaces

Player must be able to read:
- immediate threat pressure,
- status burden (including poison decay expectations),
- actionable options without menu friction.

## 8. UI and Presentation Requirements

1. **Scale and framing**: default startup should cleanly frame full playfield/HUD on common desktop resolutions, notably 1920x1080 behavior.
2. **HUD integrity**: core widgets (health, voice/mana analogs, XP gem, inventory and hotbar clusters) must retain intentional layout hierarchy.
3. **Death screen**: centered and legible; post-run analysis utility is part of design quality.
4. **Title screen**: poetic quest framing in thematic register.

## 9. Audio Direction

Audio priorities:
- gameplay readability first,
- atmosphere second,
- avoid repetitive/grating cues,
- maintain clear event-to-sound mapping.

## 10. Scope Boundaries (Beta v1.1)

In scope:
- complete beta run loop with gated escape,
- stable build identities,
- functioning light/voice/utility systems,
- coherent docs for internal playtest.

Out of scope for this milestone:
- full post-escape exterior campaign,
- final narrative epilogues,
- final long-term balance lock.

## 11. Validation Gates

Release candidate must pass:
1. build and launch reliability,
2. no critical UI break in core HUD flow,
3. escape gate correctness (Thrain's map + key),
4. no known blocking activation bug for intended utility items,
5. manual smoke pass on light/voice/action economy behavior,
6. docs in sync: GDD + Tutorial + Player's Guide.

## 12. Risks and Mitigations

- **Over-oppression drift** (darkness/resource pressure too severe):
  depth-band telemetry and targeted tuning.

- **Action tax regression** (active play punished):
  automated/targeted audit on turn consumption for non-attack utility actions.

- **UI trust erosion** (mispositioned HUD, unclear status):
  prioritize high-visibility UI fixes before feature additions.

- **Doc drift** (game and guide diverge):
  docs update in same release branch as balance/UX changes.

## 13. Canonical Documentation Set

- `docs/GAME_DESIGN_DOCUMENT_BETA_V1_1.md`
- `docs/GAME_OVERVIEW_2_PAGER_BETA_V1_1.md`
- `docs/manual/THE_NECROMANCER_PLAYERS_GUIDE_BETA_V1_1.md`
- `tutorial.md`
