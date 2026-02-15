# The Necromancer Manual Benchmark Report (Beta v1.1)

Date: 2026-02-14

## Scope
This report compares:
- Sil reference manual: `https://www.amirrorclear.net/flowers/game/sil/v101/Sil-Manual.pdf`
- Current Necromancer manual: `docs/pdf/THE_NECROMANCER_MANUAL_BETA_V1_1.pdf`

It also folds in a systems-lineage audit against:
- Sil-Q source: `https://github.com/sil-quirk/sil-q`
- Necromancer source: current branch at commit `cfb8e363`

## Evidence Snapshot

Quantitative PDF comparison:
- Sil manual: 31 pages, ~8582 words, avg ~277 words/page.
- Necromancer beta manual: 10 pages, ~1297 words, avg ~130 words/page.
- Sil primary typography: Palatino family with tighter hierarchy and denser body text.
- Necromancer current typography: Georgia + Helvetica, wide spacing, low information density.
- Both include image assets, but Sil uses image placement to support pacing; current manual uses screenshots more as appendix than integrated pedagogy.

## Gap Matrix (Sil-Q Grade vs Current)

1. Book feel and front matter
- Sil: strong title framing, immediate tone, and formal opening cadence.
- Current: starts as a technical note.
- Gap severity: Critical.
- Fix: add title spread, thematic opening stanza, and clear one-page reader orientation.

2. Table of contents and navigation
- Sil: clear chapter ladder and predictable section depth.
- Current: short list, low navigational value mid-read.
- Gap severity: High.
- Fix: full structured TOC, chapter landmarks, and practical quick-reference chapter.

3. Voice and literary tone
- Sil: restrained, lore-aware, confident prose without over-description.
- Current: competent but reads like patch notes.
- Gap severity: Critical.
- Fix: shift into field-manual voice with Tolkien-grounded diction and practical precision.

4. Learning arc for players
- Sil: teaches principles -> systems -> tactics -> mastery.
- Current: lists mechanics but under-teaches run conversion.
- Gap severity: Critical.
- Fix: add novice-to-victory progression path and danger-pattern sections.

5. Strategy depth
- Sil: explains why choices matter and how tradeoffs evolve by depth.
- Current: compact tips, limited depth band guidance.
- Gap severity: High.
- Fix: depth-banded strategy, failure patterns, and encounter triage framework.

6. Production and layout polish
- Sil: intentional typography, rhythm, and print-like cohesion.
- Current: serviceable markdown export.
- Gap severity: High.
- Fix: publication-style PDF settings, chapter spacing, and consistent callout styling.

7. Heritage and project identity
- Sil: explicit relationship between setting, mechanics, and identity.
- Current: references inspiration but underplays lineage.
- Gap severity: High.
- Fix: add "About the Necromancer" lineage section: Rogue -> Moria/Angband -> Sil-Q -> Godot port.

## Design-Lineage Audit (What Changed and Why)

## Core continuity with Sil-Q
- Turn-based tactical lethality and information-driven survival remain central.
- Positioning, stealth value, and resource pressure remain first-class.
- Permadeath and knowledge accumulation remain foundational.

## Intentional departures in The Necromancer
1. Era and tone shift
- From First Age Angband assault to Third Age Dol Guldur infiltration.
- Why: distinct narrative space while preserving Tolkien fidelity.

2. Engine and accessibility shift
- From C/terminal-era architecture to Godot presentation layer.
- Why: modern onboarding, UI readability, and broader player reach.

3. Interaction model shift
- More direct hotbar/UI pathways for active abilities and utilities.
- Why: reduce command friction for modern players and testers.

4. Beta objective framing
- Escape condition currently keyed to retrieving Thrain's map and key, then taking floor-1 upstairs.
- Why: provide complete beta loop before full post-escape chapter.

5. Economy emphasis changes
- Voice and light economy tuning is more explicit and central for current beta balancing.
- Why: Necromancer's darkness pressure requires clearer player-facing guidance.

## Manual Rewrite Targets (Accepted)

The new Player's Guide must:
- read as a crafted game manual rather than release notes,
- be practical enough that a first-time player can begin producing stable runs,
- keep veteran utility high with dense tactical guidance,
- state lineage and open-source heritage explicitly,
- encode current beta truths (Thrain's map and key, escape gate, action economy rules, light/voice realities).

## Multi-Persona Review Rubric

Reviewers and pass criteria:
- Newbie player: can start a run and understand first 20 minutes.
- Roguelike veteran: sees meaningful tactical depth and no handholding fluff.
- Tolkien reader: tone respects register and setting.
- Sil-Q player: sees lineage honored without pretending strict parity.
- Angband/Moria/Rogue lineage players: feels continuity of principles.
- Non-gamer: does not get lost in jargon by chapter 2.

Each reviewer scores:
- Clarity (0-5)
- Practical utility (0-5)
- Tone authenticity (0-5)
- Motivation to continue reading (0-5)

Revision gate:
- No category under 4/5 average.

## Delivery Standard

Final output package for Beta v1.1 docs refresh:
- `THE_NECROMANCER_PLAYERS_GUIDE_BETA_V1_1.md/.pdf`
- revised `GAME_DESIGN_DOCUMENT_BETA_V1_1.md/.pdf`
- revised `tutorial.md`
- `GAME_OVERVIEW_2_PAGER_BETA_V1_1.md`
