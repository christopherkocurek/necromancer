# Beta Readiness Delta Report (2026-02-12)

## Scope and Inputs
This report compares the original beta-readiness strategy against the current codebase and recent in-session audits.

Primary references reviewed:
- `docs/reviews/BETA_MILLION_PLAYER_STRATEGY_2026-02-11.md`
- `docs/TOP20_BETA_IMPLEMENTATION_PLAN.md`
- `docs/reviews/TOP20_BUNDLE_001_REVIEW_2026-02-12.md` ... `docs/reviews/TOP20_BUNDLE_009_REVIEW_2026-02-12.md`
- `docs/reviews/TOP20_USER_STORY_E2E_AUDIT_2026-02-12.md`
- `SESSION_AUDIT_CONTEXT.md`
- Current implementation in `scripts/` (spot-verified for listed systems)

## Executive Summary
Overall readiness is strong and materially improved versus the original Top-20 baseline. Most core beta-impact systems are implemented and integrated.

Current position:
- Core tactical readability loop: largely shipped.
- Meta loop (chronicle/goals/forensics): largely shipped.
- Accessibility/mode policy: mostly shipped.
- Remaining blockers are now mostly polish/regression bugs and a few deferred systems.

Estimated readiness: **high, but not ship-clean yet** due to a small number of high-friction gameplay bugs and stale/contradictory documentation.

---

## Top-20 Status Delta

### Effectively complete (or pass-level)
- `#1` Combat telegraph + intent overlay
- `#2` Death forensics panel
- `#3` Assist layer (Off/Basic/Full) with mode policy
- `#5` First-run guided arc
- `#6` Run goals (non-power rewards)
- `#7` Pursuit pressure feedback + systemic consequences
- `#9` Status clarity metadata + UI explanations
- `#10` Input QoL bundle (major parts)
- `#11` Enemy knowledge/chronicle surfaces (integrated with tome/bestiary paths)
- `#14` Room drama foundations and dispatcher
- `#18/#19/#20` Mode surface + telemetry foundations + ops scripts

### Partial / incomplete
- `#4` Action-feel pass: implemented in parts, but still inconsistent quality across ability VFX behavior in playtests.
- `#8` Audio upgrade: improved routing exists, but full high-quality adaptive feel is incomplete.
- `#12` Build identity dashboard: implemented, but needs UX polish/tuning and clearer runtime communication.
- `#17` Chronicle export/social packaging: chronicle persistence exists; richer export/share packaging still partial.

### Deferred by plan
- `#13` Adaptive music/ambience full rollout (asset-dependent and explicitly deferred in plan).

---

## Remaining High-Impact Gaps and Bugs

## P0 (Fix before beta signoff)
1. **Word of Opening cooldown progression feels wrong in live play**
- Symptom from playtest: cooldown appears to take too many turns to decrement.
- Code evidence: ability cooldowns tick on `round_completed`, not player turns (`scripts/systems/ability_system.gd:125`).
- Risk: core ability trust breaks; perceived bug in tactical loop.
- Classification: **regression** (live behavior not matching player expectation of turn-based cooldown cadence).

2. **Documentation/controls drift causes player confusion**
- `README.md` still documents `1-4` ability cast and `Shift+1-4` binding, while current gem system is 8-slot with click-bind and `1-8` casting (`scripts/main.gd:976`, `scripts/ui/hud.gd:520`).
- Risk: onboarding failure and repeated support friction.
- Classification: **stale context note**.

3. **Known-issues canon is stale vs current implementation**
- `docs/KNOWN_ISSUES.md` claims Word of Opening trap reveal missing, but implementation now reveals traps/secrets (`scripts/systems/ability_system.gd:555`).
- `docs/KNOWN_ISSUES.md` claims equipment resist checks missing, but checks exist in status system (`scripts/systems/status_effects.gd:254`) and player damage flow (`scripts/entities/player.gd:3519`).
- Risk: bad prioritization decisions from stale docs.
- Classification: **stale context note**.

## P1 (Important beta polish)
1. **Combat music/adaptive layer still incomplete**
- `AudioManager` combat start path is hard-disabled (`scripts/core/audio_manager.gd:351`).
- This aligns with earlier deferral but remains a major feel gap.
- Classification: **incomplete implementation**.

2. **Telemetry is instrumented but not fully consumed for balancing workflow**
- Emission exists; dashboard/analysis loop is still lightweight scripts and manual review.
- Classification: **incomplete implementation**.

3. **Room drama / chronicle UX depth still shallow in presentation layer**
- Foundation exists; richer drilldown and discoverability still limited.
- Classification: **incomplete implementation**.

## P2 (Post-beta or opportunistic)
1. Export-ready social run card/chronicle presentation layer.
2. Additional run-goal variety and weighted objective sets.
3. Final iconography polish and copy coherence pass across HUD/help/tome.

---

## Audit Mismatch Register (required by session protocol)

1. `SESSION_AUDIT_CONTEXT.md` controls list still references legacy Shift-hunting bindings as primary UX.
- Current code relies on 8-gem hotbar interaction and bind flow from HUD/menu.
- Tag: **stale context note**.

2. Prior docs listing trap-reveal and resistance systems as missing conflict with current code.
- Tag: **stale context note**.

3. Cooldown behavior expectation mismatch for Word of Opening in live play.
- Tag: **regression**.

---

## Recommended Next Pass (minimal, high leverage)
1. Normalize ability cooldown ticking semantics for lore abilities (player-turn-based or explicit UI wording if round-based by design).
2. Update player-facing docs (`README.md`, manual controls, known-issues) to current gem/hotbar reality.
3. Run a focused beta smoke checklist around: ability cooldown trust, hotbar binding/casting UX, and death-forensics clarity.
4. Decide whether to keep combat music disabled for beta or re-enable with conservative trigger thresholds.

