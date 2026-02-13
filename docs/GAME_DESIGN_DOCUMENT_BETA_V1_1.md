# The Necromancer
## Game Design Document (Beta v1.1)

**Version:** Beta v1.1  
**Date:** 2026-02-13  
**Engine:** Godot 4.6  
**Design Intent:** High-fidelity Tolkien roguelike inspired by Sil-Q, rebuilt for modern readability, tactical expression, and long-run mastery.

## 1. Vision

### 1.1 High Concept
The player infiltrates Dol Guldur to recover Thrain's map and key, survive the descent, and escape alive before the darkness closes around them.

The game is a turn-based, tile-based, permadeath roguelike with:
- skill-based progression instead of character levels,
- lethal tactical combat,
- stealth as a first-class system,
- scarce but powerful resource economies (light, voice, hunger, stamina/tempo),
- Tolkien-literate atmosphere and language.

### 1.2 Experience Targets
The game should feel:
- oppressive but never arbitrary,
- information-rich but not noisy,
- dangerous in every room,
- fair enough that losses teach clear lessons,
- deeply replayable through archetypes, routes, and ability builds.

### 1.3 Pillars
- `Tolkien Authenticity`: language, threats, gear, and stakes feel native to Third Age Mirkwood.
- `Sil-Q DNA`: opposed-roll style tactics, positional play, and pressure-based survival.
- `Agency Under Pressure`: every turn has meaningful alternatives.
- `Readable Depth`: complex systems are surfaced through UI, logs, and consistent rules.
- `Permadeath Integrity`: no cheap saves; victories are earned.

## 2. Core Loop

1. Character creation (race, house, trait, stats).
2. Enter depth 1 and establish survivability.
3. Explore, fight, sneak, and loot under resource pressure.
4. Spend XP on skills and abilities to define build identity.
5. Reach deeper layers, recover Thrain's objective state.
6. Ascend under threat and attempt escape.
7. Die and learn, or escape and close the run.

## 3. Run Structure and Win State

### 3.1 Dungeon Arc
- The run is a multi-floor descent with escalating threat composition and lower average safety windows.
- Floor transitions are strategic checkpoints, not resets.

### 3.2 Beta v1.1 Escape Win
For Beta, a pragmatic win path is implemented:
- on floor 1, taking upstairs checks escape requirements,
- if requirements are met (quest-gated, including Thrain objective items),
- the run ends with: `"Congratulations, you escaped! Now to meet Gandalf..."`
- player returns to title/menu.

This is the Beta win placeholder and intentionally precedes the full exterior post-escape sequence.

## 4. Character Model

### 4.1 Build Axes
Build identity is formed by:
- race + house,
- trait,
- early skill purchases,
- equipment and light plan,
- voice/lore commitment,
- tactical style (aggressive pressure, stealth control, shield attrition, lore burst).

### 4.2 Skill Philosophy
- XP is spendable currency.
- Skills unlock tactical permissions, not just numerical scaling.
- Defensive and utility expression should compete with raw damage as valid routes to win.

### 4.3 Active Ability Design Rule (Beta v1.1)
Non-movement, non-attack utility/stance actions are `minor actions` and should not consume a full turn.

Examples include:
- parry prep,
- mark quarry,
- circular guard,
- defensive/stance toggles,
- selected utility toggles.

Goal: preserve tactical responsiveness and avoid punishing players for using active systems.

## 5. Economy Design

## 5.1 Light Economy
Light is both survival and tempo.

Design goals:
- darkness should create pressure and uncertainty,
- but average light viability past depth 10 must remain playable,
- Necromancer can be darker than Sil-Q baseline, but not starvation-dark.

### Implemented Baseline (Beta v1.1)
- Torch: +2 radius
- Lantern: +3 radius
- Elvish Light: +2 radius, infinite (no charge drain)
- Mallorn Torch: +3 radius
- Jeweled/Feanorian Lamp: +4 radius, infinite (no charge drain)
- Equipment light egos/flags contribute to radius when present
- Light curses reduce effective light
- Light of the Eldar aura: fixed +2 radius

Design intent:
- keep oppressive darkness identity,
- ensure enough mid/deep run light continuity to support tactical planning.

## 5.2 Voice Economy
Voice powers lore and songs. It must feel scarce, strategic, and build-defining.

Beta v1.1 tuning direction:
- reduce free sustain loops,
- make sustained effects materially suppress regen,
- preserve high-impact word fantasy with meaningful cost,
- keep pure-lore runs difficult but viable.

Current balancing principles:
- sustained songs are long-horizon commitments,
- burst words should swing moments but not trivialize encounters,
- resting should not produce unintended voice exploit loops.

## 5.3 Consumables and Utility Slots
All interactive consumables/devices intended for belt/utility use should be executable from their hotbar path without inventory micromanagement dead-ends.

Design goal:
- if the player prepared the item, activation friction should be low and reliable.

## 6. Combat and Tactics

### 6.1 Combat Identity
- deterministic structure with stochastic resolution,
- high lethality, positional value, and encounter triage,
- attrition and morale pressure matter.

### 6.2 Encounter Tempo
A turn is expensive. Rules that consume turns must preserve fairness:
- movement and attacks are core-turn actions,
- setup/stance utility should usually be minor-action unless overtly transformative.

### 6.3 Status Effects
Status readability and decay cadence are critical.

Beta v1.1 correction:
- poison decay should tick at a clear, expected per-turn rate to avoid opaque overlong punishment.

## 7. Stealth, Detection, and Information

Stealth is not optional flavor; it is a major survival language.

Design requirements:
- stealth interactions are legible,
- detection escalation is understandable,
- informed disengagement is possible,
- look/inspect surfaces enough context to support low-risk planning.

## 8. UI/UX Design

### 8.1 Layout and Scale
Default startup presentation should frame the full game cleanly on common desktop displays.

Beta v1.1 target:
- default content scale and window assumptions align to `1920x1080` behavior.

### 8.2 Failure and Death UX
Death presentation must be centered, readable, and emotionally clear. Broken alignment degrades tone and post-run analysis value.

### 8.3 Title Screen Tone
The title screen should establish place, dread, and quest burden immediately.

Beta v1.1 adds central lore poem treatment to set narrative frame before play.

## 9. Audio Direction

Audio supports tactical readability first, mood second.

Principles:
- minimize repetitive grating vocalizations,
- keep event-to-sound mapping consistent,
- reserve dramatic vocals for rare high-signal beats,
- maintain mix clarity in crowded turns.

See `docs/BETA_V1_1_SOUND_PROPOSAL.md` for event table and replacement strategy.

## 10. Accessibility and Onboarding

- core game remains deep and lethal,
- readability and discoverability improvements are encouraged,
- tutorials/help should teach survival patterns, not over-automate decisions.

## 11. Content Scope (Beta)

In-scope for Beta quality:
- full core loop through escape placeholder win,
- stable character creation and progression,
- major economy systems functional,
- reliable UI flows for combat/inventory/abilities,
- coherent audiovisual identity.

Deferred beyond Beta:
- full exterior post-escape chapter,
- expanded ending states and epilogues,
- deeper narrative NPC chain.

## 12. QA and Validation Gates

Minimum gates for Beta updates:
- headless boot/load success,
- automated tests passing or known-failure accounting,
- no regressions on input/turn-consumption semantics,
- no blocking economy exploit introduced,
- one targeted manual smoke pass on: light, voice, utility activation, escape flow, death screen, title screen.

## 13. Risks and Mitigations

- `Over-oppression risk` (darkness + scarcity stacks too hard):
  Mitigation: depth-band telemetry for light radius and escape viability.
- `Action-tax risk` (active builds underperform due to turn costs):
  Mitigation: enforce minor-action policy and audit new abilities.
- `Economy drift risk` (voice or fuel loops):
  Mitigation: periodic tuning with bot + targeted human playtests.
- `UI trust risk` (misaligned state feedback):
  Mitigation: fix high-visibility layout/feedback defects quickly.

## 14. Release Positioning (Beta v1.1)

Beta v1.1 is positioned as:
- the first strong "full run" candidate with a complete Beta victory condition,
- a major light/voice/ability-tempo correction pass,
- a UI and presentation quality uplift,
- a foundation for the next iteration: post-escape content, deeper balancing, and expanded narrative payoff.

## 15. Canonical References

- `docs/manual/THE_NECROMANCER_MANUAL_BETA_V1_1.md`
- `docs/GAME_OVERVIEW_2_PAGER_BETA_V1_1.md`
- `docs/BETA_V1_1_LIGHT_VOICE_AUDIT.md`
- `docs/BETA_V1_1_SOUND_PROPOSAL.md`

