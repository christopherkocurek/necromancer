# Bot Testing Strategy (Balance + Telemetry)

## Goals
- Detect balance regressions early (spawn spikes, economy collapse, sudden difficulty walls).
- Quantify archetype viability across depth, resource usage, and combat efficiency.
- Produce floor-by-floor telemetry that maps directly to actionable knobs (spawn caps, XP costs, damage tuning, ability costs, item drop rates).

## Suites
1. **Smoke (fast sanity)**
   - 6–10 runs total.
   - 1–2 archetypes: `STEALTH_PURE`, `WARRIOR`.
   - Purpose: verify bot harness, telemetry JSON, basic progression.

2. **Regression (pre-merge)**
   - 2–3 runs per archetype in a 10–12 archetype slice.
   - Includes: stealth, melee, ranged, lore, smith, tank, generalist.
   - Purpose: catch obvious balance shifts without full-cost runs.

3. **Balance Baseline (full)**
   - All archetypes (up to 110), 3–10 runs each.
   - Parallelism: 8.
   - Purpose: measure distribution of depth, death causes, resource economy, and floor bottlenecks.

4. **Stress / Focus (targeted)**
   - 10–20 runs on a single archetype at a known problem depth (e.g., floor 7–9 spawn spike).
   - Purpose: isolate failure modes and confirm fixes.

## Seed Strategy
- Use a fixed seed set for regression (repeatable), plus random seeds for baseline.
- Recommended: 10 fixed seeds cycling across suites to ensure comparability.

## Core KPIs (per run + per floor)
- **Depth & survival**: deepest floor, turns per floor, runtime.
- **Monster density**: monsters_on_floor_start/end, monsters_seen_unique, monsters_visible_max.
- **Combat efficiency**: monsters_attacked, monsters_killed, damage_taken, healing_done.
- **Stealth health**: detections, stealth kills, threats avoided.
- **Resource economy**: consumables used, healing/buff items used, ammo used.
- **XP economy**: xp_earned, xp_spent, skills_bought, abilities_learned.
- **Exploration**: rooms_visited, vault_rooms_visited.

## Actionable Thresholds (examples)
- **Spawn spike**: monsters_on_floor_start > cap or > 2× median for that depth.
- **Depth wall**: median deepest floor drops by 2+ after a change.
- **XP crunch**: xp_spent / xp_earned < 0.5 on multiple archetypes by floor 6–8.
- **Stealth collapse**: detections per floor > 2 at depth < 8 for stealth builds.

## Reporting
- Per run JSON contains full per-floor stats.
- Aggregate per archetype with medians and P90 for: depth, damage_taken/floor, monsters_seen_unique/floor, xp_spent, consumables.
- Highlight floors with outlier monster counts or damage spikes.

## Usage Notes
- Use the **stress** suite after changes to spawns, vault placement, or AI.
- Use the **baseline** suite before major balance passes.
- Always compare against a recent baseline report to detect shifts.
