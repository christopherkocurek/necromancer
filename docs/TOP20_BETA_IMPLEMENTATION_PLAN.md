# Top 20 Beta Implementation Plan

Source: `docs/reviews/BETA_MILLION_PLAYER_STRATEGY_2026-02-11.md`

## Purpose
Execution plan for the approved Top-20 beta-impact initiatives, with explicit ownership and sequencing.
Quality standard and discipline review gates are defined in:
- `docs/TOP20_QUALITY_GATES_AND_REVIEWS.md`

## Approved So Far (Current Thread)
- #1 Combat Telegraph & Intent Overlay (focus-first)
- #2 Death Forensics Panel
- #3 Smart New-Player Assist Layer (toggleable)
- #4 Action Feel Pass (desperate/oppressive emotional target)
- #5 First-Run Guided Arc (optional)
- #6 Run Goals System (non-power progression rewards)
- #7 Escape Fantasy Reinforcement (pursuit meter must materially affect gameplay)
- #8 Audio Upgrade (legal free libraries, routed by context)
- #9 Status Effect Clarity Rework
- #10 Input QoL Bundle
- #11 Enemy Knowledge Codex from play history

## Decision Log (User Feedback, Binding)
### #1 Combat Telegraph & Intent Overlay
- Use focus-first visibility, not global icon spam.
- Show intent in both Look and Target panels.
- Optional focused target icon is enabled by default.
- Hunting tiers approved: `0-2`, `3-5`, `6-8`, `9+`.
- Add permanent HUD threat summary with minimize via eyeball icon.
- Intent examples prioritized around control/ranged/high-threat enemies.

### #2 Death Forensics Panel
- Approved as a high-priority retention system.
- Must explain causal chain and missed outs, not only final blow.

### #3 Smart New-Player Assist Layer
- Approved with adjustment:
  - Do not hard-gate assist quality by Hunting/Lore.
  - Give all players coarse warnings.
  - In-run tutorial messaging should explicitly teach:
    - investing Hunting/Lore improves battlefield reads.

### #4 Action Feel Pass
- Approved.
- Emotional direction is mandatory: desperate, oppressive, fear-forward.
- First control-caster encounters (e.g., Dark Sorcerer) should produce dread.

### #5 First-Run Guided Arc
- Approved.
- Narrative tone target:
  - field briefing from a doomed but seasoned scout in Dol Guldur.
  - "Balin's tomb" style fatal-historical tone.
- Rewards should route to chronicle/non-power systems.

### #6 Run Goals System
- Approved.
- Non-power progression focus.
- Reward direction approved:
  - Legacy Banner identity unlocks.
  - Chronicle Relics display cards.
  - Intro Epithets/title prefixes.
  - Later phase: cosmetic sprite/HUD accents only (no readability loss).

### #7 Escape Fantasy Reinforcement
- Approved.
- Pursuit meter must have meaningful gameplay interactions at thresholds.
- Escalation must materially change pressure, reinforcement behavior, and tactics.

### #8 Audio Upgrade
- Approved without further review.

### #9 Status Effect Clarity Rework
- Approved.
- Must be implemented with clear HUD/UI planning and shared metadata.

### #10 Input QoL Bundle
- Approved.
- Requires strong modal input ownership and high-risk action safety options.

### #11 Enemy Knowledge Codex
- Approved.
- Must be accessible as a persistent tome/scroll from main menu.
- Framing requirement:
  - codex is the accumulated record of heroes who died on this quest.

### #12 Build Identity Dashboard
- Approved with mode constraints.
- Experienced-player default:
  - disabled by default.
- Hardcore mode:
  - fully disabled.
- Normal mode:
  - optional/available for guidance.

### #13 Adaptive Music/Ambience State Machine
- Approved conceptually, deferred for beta launch scope.
- Dependency:
  - requires additional music/ambience assets beyond current one-track-per-layer setup.
  - expected external asset pipeline via Suno generation + curation + mastering.
- Delivery strategy:
  - implement state-machine hooks/architecture first with placeholder routing.
  - final adaptive mix rollout after asset pack is ready.

### #14 Room Drama Events
- Strongly approved.
- Identified prerequisite gap:
  - robust room tags/types/event seeds must be built out in Godot level generation first.
- Required subagent workstream:
  - layer-by-layer room/event design pass ensuring architectural intent and encounter composition
    (room content from monster/item perspective + event trigger design).
- Additional required feature integration:
  - inscription encounters (legacy semicolon-style concept) restored/expanded as event-room content.
  - on encounter: procedurally generated setting-coherent lore text + XP reward event (historically 500 XP).
  - inscriptions should be tied to profound room moments, not generic filler tiles.

## UI/HUD Integration Track (Critical)
Multiple approved items add UI/HUD surface area. To avoid fragmented UX, we will run a dedicated holistic design pass before implementation lock.

### Required Specialist Pass
- Deploy a **roguelike HUD design specialist subagent** to produce a unified information architecture for:
  - Intent display (#1)
  - Threat summary + minimization controls (#1/#3/#7)
  - Assist layer messaging (#3/#5)
  - Status clarity stack + tooltips + severity hierarchy (#9)
  - Pursuit state and meter readability (#7)
  - Death forensics information hierarchy (#2)

### Subagent Deliverables
- Single cohesive HUD layout map (desktop + small viewport behavior).
- Priority model for simultaneous alerts (who wins when screen is busy).
- Visual density budget (what is always-on vs contextual vs inspect-only).
- Interaction model for collapse/minimize controls (including eyeball toggle).
- Style/tone notes aligned to Necromancer’s oppressive survival fantasy.

## Future Feedback Ledger (Ongoing)
All new feedback for Top-20 items must be recorded in this file under the relevant section using:
- `Date`
- `Item #`
- `Decision`
- `Rationale`
- `Implementation Impact`

Template:
- Date: `YYYY-MM-DD`
- Item: `#`
- Decision: `<approved/changed/deferred>`
- Rationale: `<why>`
- Implementation Impact: `<files/systems/UI behavior affected>`

## #9 Status Effect Clarity Rework (UI Plan)
### Requirements
- Each status entry must display:
  - `name`, `icon`, `source`, `exact effect`, `remaining turns`, `severity`.
- Full tooltip must include:
  - rules text, refresh behavior, counterplay hint.
- Log events must be explicit:
  - applied, refreshed, expired (with source when known).

### HUD Behavior
- Compact strip for active statuses with turn counters.
- Severity sorting: critical first.
- Reduced-motion-safe emphasis for critical statuses.
- Hover/focus detail panel for full explanation.

### Technical Plan
- Add centralized status metadata registry.
- Normalize EventBus payloads for status apply/refresh/remove.
- Update HUD + Look/Target/death forensics surfaces to read from shared metadata.

## Sequencing Note
Before implementing #1/#3/#7/#9 final UI, complete the specialist HUD pass and freeze layout contracts.

---

## Holistic Design System Review (Cross-Surface Gate)
This section is the consolidated response to all feedback gathered in the thread for Top-20 items.

### Goal
Ship beta with one coherent player-facing language across:
- Main menu/meta surfaces
- In-run HUD
- Look/Target/Character panels
- Event logs and death recap
- Back-end telemetry and tuning loops

### Expert-Lens Synthesis (Requested Subagent Perspectives)
The implementation plan should be reviewed through these lenses before coding overlapping systems:

1. Game Design Lens
- Ensure every new system creates meaningful choice, not UI noise.
- Prioritize pressure, agency, and tactical readability over feature count.

2. Tolkien Tone Lens
- Copy style target: doomed field notes in Dol Guldur, not generic fantasy tutorial text.
- Language should feel archival, fatalistic, and grounded in Third Age atmosphere.

3. Roguelike UX Lens
- Preserve strict input trust and fast decision cadence.
- Any helper system must be inspectable, skippable, and non-blocking in hardcore flow.

4. Player Psychology Lens
- Reinforce the desired emotional arc: uncertainty -> dread -> hard-earned mastery.
- Convert confusion deaths into motivation via clear causality and learnable counterplay.

5. Systems/Production Lens
- Shared metadata contracts first, UI skins second.
- Avoid parallel one-off widgets that duplicate logic across HUD/panels/menu.

### Feature Clusters By Shared Surface Area
Use these clusters to avoid fragmented implementation.

#### Cluster A: Combat Readability Surface
- Items: `#1`, `#2`, `#3`, `#9`, `#15`
- Shared UI: Look panel, Target panel, HUD threat line, combat log, death recap.
- Shared backend: intent metadata, status metadata, cause/effect event bus schema.
- Binding user notes:
  - Intent readout in both Look and Target.
  - Focus-first presentation (avoid icon spam with swarms).
  - Threat summary always visible, minimizable via eyeball icon.
  - Coarse help available to all; better read depth can scale with skills without hard lockout.

#### Cluster B: Emotional Pressure Surface
- Items: `#4`, `#5`, `#7`, `#13`, `#14`
- Shared UI/audio: impact feedback, escalation messaging, pursuit meter, room event callouts, dynamic ambience hooks.
- Shared backend: threat-state machine + room tags/types/event seeds.
- Binding user notes:
  - Must feel desperate/oppressive and fear-forward.
  - First high-threat caster encounters should feel like probable death.
  - Pursuit meter needs real gameplay impact at thresholds.
  - #13 architecture can land now; full content pass is post-beta.

#### Cluster C: Meta Memory Surface
- Items: `#6`, `#11`, `#17`, `#19`
- Shared UI: main-menu tome/scroll entry, chronicle pages, codex cards, run summary exports.
- Shared backend: persistent profile ledger and unlock taxonomy.
- Binding user notes:
  - Chronicle must exist and become core meta record.
  - Codex framed as records of fallen heroes.
  - Rewards are identity/cosmetic/record only (no power creep).
  - Meta progression and chronicle systems must be unified, not separate silos.

#### Cluster D: Input/Accessibility/Mode Surface
- Items: `#10`, `#12`, `#16`, `#18`
- Shared UI: settings, control binding screen, mode selector, profile recommendations.
- Shared backend: mode policy flags, input ownership model, accessibility preset serialization.
- Binding user notes:
  - Guidance-heavy dashboards must be optional.
  - Hardcore mode disables assistive build dashboard features.
  - Need unified policy to prevent duplicated “helper” toggles.

#### Cluster E: Live Ops and Tuning Surface
- Items: `#20` + telemetry dependencies from `#1/#2/#7/#9/#10/#14`
- Shared backend: event schema, balancing dashboards, run segmentation.
- Shared output: patch notes and targeted tuning passes.

### Design Gate (Mandatory Before Implementation In Shared Surfaces)
No overlapping-surface feature moves to implementation until all checks pass.

1. Surface Inventory Check
- List touched UI surfaces and backend contracts for the feature set.
- Confirm no duplicate widgets or competing information lanes.

2. Information Priority Check
- Define always-on vs contextual vs inspect-only data.
- Resolve tie-break rules when multiple alerts compete.

3. Mode Policy Check
- Validate Normal vs Hardcore behavior and defaults.
- Ensure optional helpers are discoverable but unobtrusive.

4. Tone Check
- Validate text/audio/UI callouts against the oppressive Dol Guldur brief.

5. Telemetry Check
- Add event instrumentation before rollout to measure effect and confusion.

6. Playtest Acceptance Check
- Run focused playtests for fear/readability outcomes, not only bug-free behavior.

### Unified Contract First (Implementation Rule)
For all Top-20 items in shared surfaces, implement in this order:
1. Shared data contracts and event schema
2. Shared rendering components
3. Feature-specific wiring
4. Copy/tone pass
5. Telemetry and balance iteration

Do not ship panel-specific one-offs that bypass shared contracts.

### Consolidated Decisions for #15-#20 (From Thread)
- #15 Auto-Explain Proc Log: approved in principle; must share combat-readability schema used by #1/#2/#9.
- #16 Accessibility Pack: approved in principle; align with mode policy and avoid novice-only UI clutter.
- #17 Achievement + Chronicle Export: approved; merge directly into chronicle/tome system.
- #18 Difficulty Surface Polish: needs consolidation with existing mode/help systems to avoid redundant UI.
- #19 Meta-Progression Lite: approved direction only if fully non-power and merged with chronicle/codex.
- #20 Live Balance Telemetry Harness: approved as required backbone for validating all above features.

### Working Model: Specialist Workstreams
- HUD/Panel Workstream: owns clusters A and D layout/system coherence.
- Atmosphere/Event Workstream: owns cluster B emotional pacing + room drama integration.
- Chronicle/Meta Workstream: owns cluster C persistence and menu integration.
- Telemetry/Ops Workstream: owns cluster E schema and post-beta tuning loop.

### Ongoing Feedback Capture Rule
Every new note from ongoing discussion must be added here under:
- Relevant item number(s)
- Cluster
- Surface area touched
- Impact on contracts/UI/layout
