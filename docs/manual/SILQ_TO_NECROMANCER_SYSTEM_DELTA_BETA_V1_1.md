# Sil-Q -> The Necromancer System Delta (Beta v1.1)

Date: 2026-02-14

## Method
Compared Sil-Q source (`tmp/sil-q`, commit `4705005`) against current Necromancer game data/scripts for equivalent system families.

## 1. Core Continuities

- Permadeath, tactical turn structure, and skill-forward progression remain foundational.
- Light, stealth, and song/voice remain strategic systems rather than passive flavor.
- Objective-oriented run structure is retained (mission completion + escape pressure).

## 2. Major Adaptations

1. Engine architecture
- Sil-Q: C codebase with classic terminal-era interactions.
- Necromancer: Godot scene/script architecture with UI-forward interaction and modern input routing.
- Why: accessibility, visual readability, and lower onboarding friction.

2. Setting and narrative frame
- Sil-Q: First Age Angband theft arc.
- Necromancer: Third Age Dol Guldur recovery arc centered on Thrain's map and key.
- Why: preserve Tolkien ethos while establishing a distinct campaign identity.

3. Action delivery layer
- Sil-Q: command-driven interaction depth.
- Necromancer: hotbar/gem/utility and panel-driven workflows.
- Why: make active abilities practical for broader player base without reducing tactical depth.

4. Beta objective structure
- Necromancer currently ships a beta completion gate on floor-1 upstairs with required quest items.
- Why: complete playable loop before exterior chapter implementation.

## 3. Economy Deltas

## 3.1 Light
Sil-Q references include explicit light radius/fuel constants and object light flags. Necromancer preserves the strategic role but retunes values to support a darker average atmosphere while keeping deep runs playable.

Necromancer beta anchors:
- Elvish Light +2 infinite
- Jeweled Lamp +4 infinite

## 3.2 Voice/Song
Sil-Q song systems are tightly integrated in player/monster state. Necromancer retains the design axis but re-presents it as voice/lore economy with updated UI and sustain tuning goals for beta.

## 3.3 Utility activation
Necromancer makes utility-slot activation a first-order UX requirement; this is a direct modernization pressure response.

## 4. Tactical Tempo Deltas

Sil-Q's passive/active balance creates reliable tactical cadence. Necromancer beta introduces an explicit policy: non-attack setup abilities should usually be minor actions to avoid active-play penalties.

## 5. Practical Player Impact

What a Sil-Q player should expect:
- Familiar strategic priorities: geometry, scouting, measured commitment.
- Unfamiliar interaction cadence: more panel/hotbar mediation.
- Similar failure profile: most deaths are sequencing failures before they are RNG failures.

## 6. Documentation Implication

The Player's Guide must teach both:
- lineage continuity (why veterans should trust the design),
- modern interaction changes (why old muscle memory must adapt).
