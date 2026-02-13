# Top-20 Quality Gates and Review Framework

Date: 2026-02-12
Scope: All approved Top-20 items except deferred full adaptive-audio content rollout (#13 asset-dependent).

## Purpose
Enforce a `9/10` minimum bar per discipline before a feature is accepted.
Every implementation bundle must include explicit review tags for impacted surfaces.

## Mandatory Review Tags (Per Change Bundle)
Each bundle must declare one or more tags:
- `FRONTEND_UI_HUD`
- `BACKEND_SYSTEMS`
- `MAP_GENERATION`
- `SPAWN_LOGIC`
- `INPUT_ACCESSIBILITY`
- `NARRATIVE_TONE`
- `TELEMETRY_BALANCE`

## 9/10 Criteria by Discipline

### 1) Frontend UI/HUD
Score 9/10 if all are true:
- Information hierarchy is clear under swarm/high-pressure states.
- Always-on, contextual, and inspect-only info are separated and consistent.
- Panels (Look/Target/HUD/Death/Tome) use shared language and icon semantics.
- Controls for minimize/collapse/toggle are discoverable and non-intrusive.
- Small viewport remains legible without hiding critical combat information.

### 2) Backend Systems
Score 9/10 if all are true:
- Shared metadata contracts exist (intent/status/proc/threat/forensics).
- Event bus payloads are normalized and consumed by multiple surfaces.
- Persistence paths are backward-safe (new fields default cleanly).
- No duplicate one-off logic bypasses shared systems.
- Failure cases are guarded (missing data, stale references, null entities).

### 3) Map Generation and Event Foundations
Score 9/10 if all are true:
- Room tags/types/event seeds are deterministic and serializable.
- Event-room placement follows depth/layer intent and avoids filler noise.
- Inscriptions/event triggers integrate without blocking core traversal.
- Stair safety/connectivity constraints remain intact after event placement.
- Spawn/decor passes remain compatible with existing vault/forge systems.

### 4) Spawn Logic and Combat Pressure
Score 9/10 if all are true:
- Pursuit/escalation thresholds cause measurable gameplay differences.
- Threat summaries match true tactical risk (not false alarm spam).
- Special encounter signaling (casters/control elites) is readable pre-impact.
- No severe spawn unfairness regressions near stairs/start states.
- Tuning knobs are data-driven where possible.

### 5) Input/Accessibility/Mode Policy
Score 9/10 if all are true:
- Normal vs Hardcore policy is explicit and consistently enforced.
- Optional helper systems are on/offable with sensible defaults.
- Reduced-motion/visual clarity toggles are honored by new effects.
- High-risk action safeguards do not slow expert play unnecessarily.
- Rebinding and buffered-input behavior are predictable.

### 6) Narrative Tone (Tolkien + Necromancer Identity)
Score 9/10 if all are true:
- Messaging reads like doomed field records, not generic tutorial text.
- Emotional arc supports dread, pressure, and hard-earned competence.
- Chronicle/codex/epitaph copy is cohesive across menu and in-run surfaces.
- Lore framing is coherent with Dol Guldur atmosphere.
- Flavor never obscures tactical clarity.

### 7) Telemetry and Balance Ops
Score 9/10 if all are true:
- New systems emit actionable events for tuning and confusion diagnosis.
- Metrics segment by mode/depth/archetype where relevant.
- Death-forensics and proc-explain systems are queryable post-run.
- Rollout includes at least one measurable hypothesis per feature.
- Logging overhead does not materially hurt runtime responsiveness.

## Review Artifact Format (Required)
For each completed bundle, include:
- `Bundle ID`
- `Top-20 items covered`
- `Tags`
- `Files touched`
- `Discipline scores (0-10)`
- `Pass/Fail`
- `Open risks`
- `Next tuning actions`

## Dependency Rule
No UI-heavy feature may be accepted without backend contract review.
No map/event feature may be accepted without spawn and traversal safety review.
No helper/assist feature may be accepted without mode policy review.
