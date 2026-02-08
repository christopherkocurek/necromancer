#!/usr/bin/env python3
"""
analyze_results.py — Analyze bot playthrough results and generate balance report.

Reads JSON result files from bot_results/ and produces:
1. bot_results/aggregate.csv — One row per run with all metrics
2. docs/BALANCE_REPORT.md — Markdown balance analysis report

Usage: python3 scripts/analysis/analyze_results.py [results_dir]
"""

import json
import csv
import os
import sys
from collections import defaultdict
from pathlib import Path

# Paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent.parent
RESULTS_DIR = Path(sys.argv[1]) if len(sys.argv) > 1 else PROJECT_DIR / "bot_results"
CSV_OUTPUT = RESULTS_DIR / "aggregate.csv"
REPORT_OUTPUT = PROJECT_DIR / "docs" / "BALANCE_REPORT.md"


def load_results():
    """Load all JSON result files."""
    results = []
    for f in sorted(RESULTS_DIR.glob("*.json")):
        try:
            with open(f) as fh:
                data = json.load(fh)
                data["_file"] = f.name
                results.append(data)
        except (json.JSONDecodeError, IOError) as e:
            print(f"WARNING: Failed to load {f}: {e}")
    return results


def write_csv(results):
    """Write aggregate CSV with one row per run."""
    if not results:
        return
    fields = [
        "archetype", "run_index", "seed", "outcome", "deepest_floor",
        "total_turns", "total_kills", "total_items", "total_damage_taken",
        "total_healing_done", "total_errors",
        "total_abilities_used", "total_ranged_attacks", "total_items_equipped",
        "total_forges_used", "total_stealth_toggles", "total_skills_bought",
        "total_abilities_learned", "total_songs_started",
        # v2 fields
        "total_flee_attempts", "total_consumables_used", "total_items_sought",
        "total_kite_attempts", "total_kite_shots",
        "total_combats_avoided", "total_stealth_kills", "total_detections",
        "total_forges_visited", "total_forge_successes",
        "total_word_of_command", "total_lore_of_sleep", "total_deep_memory",
        "total_rest_turns",
        # v3 fields
        "total_corridor_fights", "total_corridor_repositions",
        "total_doors_closed", "total_threats_avoided",
        "total_food_eaten", "total_assassination_attacks",
        "total_song_switches", "total_voice_at_death",
        "total_last_stand_turns", "total_materials_collected",
        "timestamp", "_file"
    ]
    os.makedirs(CSV_OUTPUT.parent, exist_ok=True)
    with open(CSV_OUTPUT, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        for r in results:
            writer.writerow(r)
    print(f"CSV written: {CSV_OUTPUT} ({len(results)} rows)")


def compute_stats(results):
    """Compute per-archetype statistics."""
    by_archetype = defaultdict(list)
    for r in results:
        by_archetype[r.get("archetype", "UNKNOWN")].append(r)

    stats = {}
    for arch, runs in sorted(by_archetype.items()):
        n = len(runs)
        wins = sum(1 for r in runs if r.get("outcome") == "COMPLETED")
        deaths = sum(1 for r in runs if r.get("outcome") == "DEATH")
        errors = sum(1 for r in runs if r.get("outcome") in ("HARNESS_ERROR", "SETUP_FAILURE"))
        timeouts = sum(1 for r in runs if r.get("outcome") == "TOTAL_TIMEOUT")

        depths = [r.get("deepest_floor", 0) for r in runs]
        turns = [r.get("total_turns", 0) for r in runs]
        kills = [r.get("total_kills", 0) for r in runs]
        items = [r.get("total_items", 0) for r in runs]
        dmg = [r.get("total_damage_taken", 0) for r in runs]
        heal = [r.get("total_healing_done", 0) for r in runs]
        abilities = [r.get("total_abilities_used", 0) for r in runs]
        ranged = [r.get("total_ranged_attacks", 0) for r in runs]
        equipped = [r.get("total_items_equipped", 0) for r in runs]
        forged = [r.get("total_forges_used", 0) for r in runs]
        stealth = [r.get("total_stealth_toggles", 0) for r in runs]
        skills_bought = [r.get("total_skills_bought", 0) for r in runs]
        abilities_learned = [r.get("total_abilities_learned", 0) for r in runs]
        songs = [r.get("total_songs_started", 0) for r in runs]

        # v2 metrics
        flee_attempts = [r.get("total_flee_attempts", 0) for r in runs]
        consumables = [r.get("total_consumables_used", 0) for r in runs]
        items_sought = [r.get("total_items_sought", 0) for r in runs]
        kite_attempts = [r.get("total_kite_attempts", 0) for r in runs]
        kite_shots = [r.get("total_kite_shots", 0) for r in runs]
        combats_avoided = [r.get("total_combats_avoided", 0) for r in runs]
        stealth_kills_list = [r.get("total_stealth_kills", 0) for r in runs]
        detections = [r.get("total_detections", 0) for r in runs]
        forges_visited = [r.get("total_forges_visited", 0) for r in runs]
        forge_successes = [r.get("total_forge_successes", 0) for r in runs]
        woc = [r.get("total_word_of_command", 0) for r in runs]
        sleep = [r.get("total_lore_of_sleep", 0) for r in runs]
        deep_mem = [r.get("total_deep_memory", 0) for r in runs]
        rest_turns = [r.get("total_rest_turns", 0) for r in runs]

        # v3 metrics
        corridor_fights = [r.get("total_corridor_fights", 0) for r in runs]
        corridor_repos = [r.get("total_corridor_repositions", 0) for r in runs]
        doors_closed = [r.get("total_doors_closed", 0) for r in runs]
        threats_avoided = [r.get("total_threats_avoided", 0) for r in runs]
        food_eaten = [r.get("total_food_eaten", 0) for r in runs]
        assassination_attacks = [r.get("total_assassination_attacks", 0) for r in runs]
        song_switches = [r.get("total_song_switches", 0) for r in runs]
        voice_at_death = [r.get("total_voice_at_death", 0) for r in runs]
        last_stand_turns = [r.get("total_last_stand_turns", 0) for r in runs]
        materials_collected = [r.get("total_materials_collected", 0) for r in runs]

        stats[arch] = {
            "n": n,
            "wins": wins,
            "deaths": deaths,
            "errors": errors,
            "timeouts": timeouts,
            "win_rate": wins / max(n, 1) * 100,
            "avg_depth": sum(depths) / max(n, 1),
            "max_depth": max(depths) if depths else 0,
            "min_depth": min(depths) if depths else 0,
            "avg_turns": sum(turns) / max(n, 1),
            "avg_kills": sum(kills) / max(n, 1),
            "avg_items": sum(items) / max(n, 1),
            "avg_damage": sum(dmg) / max(n, 1),
            "avg_healing": sum(heal) / max(n, 1),
            "avg_abilities": sum(abilities) / max(n, 1),
            "avg_ranged": sum(ranged) / max(n, 1),
            "avg_equipped": sum(equipped) / max(n, 1),
            "avg_forged": sum(forged) / max(n, 1),
            "avg_stealth": sum(stealth) / max(n, 1),
            "avg_skills_bought": sum(skills_bought) / max(n, 1),
            "avg_abilities_learned": sum(abilities_learned) / max(n, 1),
            "avg_songs": sum(songs) / max(n, 1),
            # v2
            "avg_flee": sum(flee_attempts) / max(n, 1),
            "avg_consumables": sum(consumables) / max(n, 1),
            "avg_items_sought": sum(items_sought) / max(n, 1),
            "avg_kite_attempts": sum(kite_attempts) / max(n, 1),
            "avg_kite_shots": sum(kite_shots) / max(n, 1),
            "avg_combats_avoided": sum(combats_avoided) / max(n, 1),
            "avg_stealth_kills": sum(stealth_kills_list) / max(n, 1),
            "avg_detections": sum(detections) / max(n, 1),
            "avg_forges_visited": sum(forges_visited) / max(n, 1),
            "avg_forge_successes": sum(forge_successes) / max(n, 1),
            "avg_woc": sum(woc) / max(n, 1),
            "avg_sleep": sum(sleep) / max(n, 1),
            "avg_deep_memory": sum(deep_mem) / max(n, 1),
            "avg_rest_turns": sum(rest_turns) / max(n, 1),
            # v3
            "avg_corridor_fights": sum(corridor_fights) / max(n, 1),
            "avg_corridor_repos": sum(corridor_repos) / max(n, 1),
            "avg_doors_closed": sum(doors_closed) / max(n, 1),
            "avg_threats_avoided": sum(threats_avoided) / max(n, 1),
            "avg_food_eaten": sum(food_eaten) / max(n, 1),
            "avg_assassination_attacks": sum(assassination_attacks) / max(n, 1),
            "avg_song_switches": sum(song_switches) / max(n, 1),
            "avg_voice_at_death": sum(voice_at_death) / max(n, 1),
            "avg_last_stand_turns": sum(last_stand_turns) / max(n, 1),
            "avg_materials_collected": sum(materials_collected) / max(n, 1),
            "depths": depths,
            "runs": runs,
        }

    return stats


def death_floor_distribution(stats):
    """Get death floor histogram per archetype."""
    dist = {}
    for arch, s in stats.items():
        floor_counts = defaultdict(int)
        for r in s["runs"]:
            if r.get("outcome") == "DEATH":
                floor_counts[r.get("deepest_floor", 0)] += 1
        dist[arch] = dict(sorted(floor_counts.items()))
    return dist


def attrition_curve(stats):
    """Compute % of runs alive at each floor depth."""
    curves = {}
    for arch, s in stats.items():
        n = s["n"]
        if n == 0:
            continue
        alive_at = {}
        for floor in range(1, 21):
            alive = sum(1 for d in s["depths"] if d >= floor)
            alive_at[floor] = alive / n * 100
        curves[arch] = alive_at
    return curves


def death_causes(results):
    """Aggregate death causes across all runs."""
    causes = defaultdict(int)
    for r in results:
        causes[r.get("outcome", "UNKNOWN")] += 1
    return dict(sorted(causes.items(), key=lambda x: -x[1]))


def generate_report(results, stats):
    """Generate markdown balance report."""
    total = len(results)
    all_wins = sum(s["wins"] for s in stats.values())
    all_deaths = sum(s["deaths"] for s in stats.values())
    all_errors = sum(s["errors"] for s in stats.values())

    curves = attrition_curve(stats)
    death_dist = death_floor_distribution(stats)
    causes = death_causes(results)

    lines = []
    lines.append(f"# Balance Report — {total} V3 Bot Playthroughs")
    lines.append("")
    lines.append("> **Generated by `scripts/analysis/analyze_results.py`**")
    lines.append(f"> **Total runs:** {total} | **Wins:** {all_wins} | "
                 f"**Deaths:** {all_deaths} | **Errors:** {all_errors}")
    lines.append(f"> **Overall win rate:** {all_wins/max(total,1)*100:.1f}%")
    lines.append("")

    # Bot capability summary
    lines.append("## Bot Capabilities")
    lines.append("")
    lines.append("The v3 survival bot uses **tactical AI with 18 distinct archetypes**:")
    lines.append("- **Corridor fighting**: Repositions to doorways/corridors for 1v1 advantage")
    lines.append("- **Threat assessment**: Per-archetype fight/flee thresholds based on attack/evasion differentials")
    lines.append("- **Door tactics**: Closes doors behind when pursued to break LOS")
    lines.append("- **Stealth assassinations**: Alertness-aware targeting for stealth kills")
    lines.append("- **Songs**: Combat songs (Aule, Freedom) and exploration songs (Trees, Freedom)")
    lines.append("- **Voice abilities**: Word of Command, Lore of Sleep, Deep Memory with voice budgeting")
    lines.append("- **Archery + kiting**: Ranged attacks with retreat-and-shoot patterns")
    lines.append("- **Equipment**: Auto-equip upgrades + periodic inventory scan")
    lines.append("- **Smithing**: Forge-seeking behavior for SMITH/ELF_SMITH archetypes")
    lines.append("- **Skill investment**: Archetype-specific skill priorities and ability wishlists")
    lines.append("")
    lines.append("Each archetype uses **distinct strategies** matching its stat build, race, and tactical role.")
    lines.append("")

    # Per-archetype summary table
    lines.append("## Per-Archetype Summary")
    lines.append("")
    lines.append("| Archetype | Race | Runs | Wins | Win% | Avg Depth | Max Depth | Avg Turns | Avg Kills | Avg Items |")
    lines.append("|-----------|------|------|------|------|-----------|-----------|-----------|-----------|-----------|")

    race_map = {
        "WARRIOR": "Man", "STEALTH": "Hobbit", "LORE_MAGE": "Elf",
        "RANGER": "Man", "TANK": "Dwarf", "SMITH": "Dwarf",
        "STEALTH_PURE": "Hobbit", "STEALTH_ASSASSIN": "Hobbit",
        "RANGER_MARKSMAN": "Man", "RANGER_STEALTH_ARCHER": "Man",
        "POLEARM_MASTER": "Man", "ELF_SMITH": "Elf",
        "WILL_TANK": "Dwarf", "HOBBIT_SNIPER": "Hobbit",
        "GREENWOOD_RANGER": "Elf", "HOBBIT_BURGLAR": "Hobbit",
        "BANISHMENT_MAGE": "Elf", "SHIELD_WALL": "Man",
    }
    for arch in sorted(stats.keys()):
        s = stats.get(arch)
        if not s:
            continue
        lines.append(f"| {arch} | {race_map.get(arch, '?')} | {s['n']} | {s['wins']} | "
                     f"{s['win_rate']:.0f}% | {s['avg_depth']:.1f} | {s['max_depth']} | "
                     f"{s['avg_turns']:.0f} | {s['avg_kills']:.1f} | {s['avg_items']:.1f} |")

    lines.append("")

    # Overall outcome distribution
    lines.append("## Outcome Distribution")
    lines.append("")
    lines.append("| Outcome | Count | % |")
    lines.append("|---------|-------|---|")
    for cause, count in causes.items():
        lines.append(f"| {cause} | {count} | {count/max(total,1)*100:.1f}% |")
    lines.append("")

    # Attrition curve
    lines.append("## Floor-by-Floor Attrition")
    lines.append("")
    lines.append("Percentage of runs still alive at each floor depth:")
    lines.append("")
    header = "| Floor |"
    sep = "|-------|"
    for arch in sorted(stats.keys()):
        if arch in curves:
            header += f" {arch} |"
            sep += "--------|"
    lines.append(header)
    lines.append(sep)
    for floor in range(1, 21):
        row = f"| {floor:2d}    |"
        for arch in sorted(stats.keys()):
            if arch in curves:
                pct = curves[arch].get(floor, 0)
                row += f" {pct:5.1f}% |"
        lines.append(row)
    lines.append("")

    # Death floor distribution
    lines.append("## Death Floor Distribution")
    lines.append("")
    for arch in sorted(stats.keys()):
        if arch not in death_dist or not death_dist[arch]:
            continue
        lines.append(f"### {arch}")
        lines.append("")
        dist = death_dist[arch]
        max_count = max(dist.values()) if dist else 1
        for floor, count in dist.items():
            bar = "#" * int(count / max_count * 30)
            lines.append(f"  Floor {floor:2d}: {bar} ({count})")
        lines.append("")

    # Item economy
    lines.append("## Item Economy Analysis")
    lines.append("")
    lines.append("| Archetype | Avg Items | Avg Damage Taken | Avg Healing | Items/Damage Ratio |")
    lines.append("|-----------|-----------|------------------|-------------|-------------------|")
    for arch in sorted(stats.keys()):
        s = stats.get(arch)
        if not s:
            continue
        ratio = s["avg_items"] / max(s["avg_damage"], 1)
        lines.append(f"| {arch} | {s['avg_items']:.1f} | {s['avg_damage']:.0f} | "
                     f"{s['avg_healing']:.0f} | {ratio:.2f} |")
    lines.append("")

    # Skill usage analysis
    lines.append("## Skill Usage Analysis")
    lines.append("")
    lines.append("| Archetype | Avg Skills | Avg Abilities | Avg Equipped | Avg Abilities Used | Avg Ranged | Avg Songs | Avg Forged | Avg Stealth |")
    lines.append("|-----------|-----------|--------------|-------------|-------------------|-----------|----------|-----------|------------|")
    for arch in sorted(stats.keys()):
        s = stats.get(arch)
        if not s:
            continue
        lines.append(f"| {arch} | {s['avg_skills_bought']:.1f} | {s['avg_abilities_learned']:.1f} | "
                     f"{s['avg_equipped']:.1f} | {s['avg_abilities']:.1f} | {s['avg_ranged']:.1f} | "
                     f"{s['avg_songs']:.1f} | {s['avg_forged']:.1f} | {s['avg_stealth']:.0f} |")
    lines.append("")

    # v2+v3 Stealth analysis
    stealth_archetypes = [a for a in stats if a in (
        "STEALTH", "STEALTH_PURE", "STEALTH_ASSASSIN", "RANGER_STEALTH_ARCHER",
        "HOBBIT_BURGLAR", "GREENWOOD_RANGER", "HOBBIT_SNIPER")]
    if stealth_archetypes:
        lines.append("## Stealth Analysis")
        lines.append("")
        lines.append("| Archetype | Avg Combats Avoided | Avg Stealth Kills | Avg Detections | Avg Flee |")
        lines.append("|-----------|--------------------|--------------------|---------------|----------|")
        for arch in sorted(stealth_archetypes):
            s = stats[arch]
            lines.append(f"| {arch} | {s['avg_combats_avoided']:.1f} | {s['avg_stealth_kills']:.1f} | "
                         f"{s['avg_detections']:.1f} | {s['avg_flee']:.1f} |")
        lines.append("")

    # v2+v3 Ranged/Kiting analysis
    ranged_archetypes = [a for a in stats if a in (
        "RANGER", "RANGER_MARKSMAN", "RANGER_STEALTH_ARCHER",
        "HOBBIT_SNIPER", "GREENWOOD_RANGER")]
    if ranged_archetypes:
        lines.append("## Ranged & Kiting Analysis")
        lines.append("")
        lines.append("| Archetype | Avg Ranged Shots | Avg Kite Attempts | Avg Kite Shots | Avg Kills |")
        lines.append("|-----------|-----------------|-------------------|----------------|-----------|")
        for arch in sorted(ranged_archetypes):
            s = stats[arch]
            lines.append(f"| {arch} | {s['avg_ranged']:.1f} | {s['avg_kite_attempts']:.1f} | "
                         f"{s['avg_kite_shots']:.1f} | {s['avg_kills']:.1f} |")
        lines.append("")

    # v2+v3 Smith/Forge analysis
    smith_archetypes = [a for a in stats if a in ("SMITH", "ELF_SMITH")]
    if smith_archetypes:
        lines.append("## Smith & Forge Analysis")
        lines.append("")
        lines.append("| Archetype | Avg Forges Visited | Avg Forge Successes | Avg Forged | Avg Materials |")
        lines.append("|-----------|-------------------|--------------------|-----------|--------------:|")
        for arch in sorted(smith_archetypes):
            s = stats[arch]
            lines.append(f"| {arch} | {s['avg_forges_visited']:.1f} | {s['avg_forge_successes']:.1f} | "
                         f"{s['avg_forged']:.1f} | {s['avg_materials_collected']:.1f} |")
        lines.append("")

    # v2+v3 Caster ability breakdown
    caster_archetypes = [a for a in stats if a in ("LORE_MAGE", "BANISHMENT_MAGE")]
    if caster_archetypes:
        lines.append("## Caster Ability Breakdown")
        lines.append("")
        for arch in sorted(caster_archetypes):
            s = stats[arch]
            lines.append(f"### {arch}")
            lines.append("")
            lines.append(f"- **Word of Command:** {s['avg_woc']:.1f} avg uses per run")
            lines.append(f"- **Lore of Sleep:** {s['avg_sleep']:.1f} avg uses per run")
            lines.append(f"- **Deep Memory:** {s['avg_deep_memory']:.1f} avg uses per run")
            lines.append(f"- **Total abilities used:** {s['avg_abilities']:.1f} avg per run")
            lines.append(f"- **Rest turns for voice:** {s['avg_rest_turns']:.0f} avg per run")
            lines.append(f"- **Voice at death:** {s['avg_voice_at_death']:.0f} avg remaining")
            lines.append(f"- **Song switches:** {s['avg_song_switches']:.1f} avg per run")
            lines.append("")

    # v2 Survival improvements
    lines.append("## Survival Behavior (v2 Upgrades)")
    lines.append("")
    lines.append("| Archetype | Avg Flee | Avg Consumables | Avg Items Sought | Avg Rest Turns |")
    lines.append("|-----------|---------|-----------------|------------------|---------------|")
    for arch in sorted(stats.keys()):
        s = stats[arch]
        lines.append(f"| {arch} | {s['avg_flee']:.1f} | {s['avg_consumables']:.1f} | "
                     f"{s['avg_items_sought']:.1f} | {s['avg_rest_turns']:.0f} |")
    lines.append("")

    # v3 Tactical Analysis
    lines.append("## Tactical AI Analysis (v3)")
    lines.append("")
    lines.append("| Archetype | Corridor Fights | Repositions | Doors Closed | Threats Avoided | Assassinations |")
    lines.append("|-----------|:-:|:-:|:-:|:-:|:-:|")
    for arch in sorted(stats.keys()):
        s = stats[arch]
        lines.append(f"| {arch} | {s['avg_corridor_fights']:.1f} | {s['avg_corridor_repos']:.1f} | "
                     f"{s['avg_doors_closed']:.1f} | {s['avg_threats_avoided']:.1f} | "
                     f"{s['avg_assassination_attacks']:.1f} |")
    lines.append("")

    # v3 Tank/Warrior analysis
    tank_archetypes = [a for a in stats if a in (
        "TANK", "WILL_TANK", "WARRIOR", "POLEARM_MASTER", "SHIELD_WALL")]
    if tank_archetypes:
        lines.append("## Tank & Melee Analysis (v3)")
        lines.append("")
        lines.append("| Archetype | Avg Kills | Avg Damage | Corridor Fights | Last Stand Turns | Food Eaten |")
        lines.append("|-----------|-----------|-----------|:-:|:-:|:-:|")
        for arch in sorted(tank_archetypes):
            s = stats[arch]
            lines.append(f"| {arch} | {s['avg_kills']:.1f} | {s['avg_damage']:.0f} | "
                         f"{s['avg_corridor_fights']:.1f} | {s['avg_last_stand_turns']:.1f} | "
                         f"{s['avg_food_eaten']:.1f} |")
        lines.append("")

    # Balance recommendations
    lines.append("## Key Findings & Balance Recommendations")
    lines.append("")

    # Auto-detect balance issues
    win_rates = {a: s["win_rate"] for a, s in stats.items()}
    avg_depths = {a: s["avg_depth"] for a, s in stats.items()}

    if win_rates:
        # Break ties by avg_depth when win rates are equal
        best_arch = max(stats.keys(), key=lambda a: (stats[a]["win_rate"], stats[a]["avg_depth"]))
        worst_arch = min(stats.keys(), key=lambda a: (stats[a]["win_rate"], stats[a]["avg_depth"]))
        overall_wr = all_wins / max(total, 1) * 100

        lines.append(f"1. **Overall win rate: {overall_wr:.1f}%** — "
                     f"{'Too easy (target: 1-5%)' if overall_wr > 10 else 'Within roguelike range' if overall_wr <= 5 else 'Moderate difficulty'}")
        lines.append(f"2. **Best performer:** {best_arch} ({win_rates[best_arch]:.0f}% win rate, "
                     f"avg depth {avg_depths[best_arch]:.1f})")
        lines.append(f"3. **Worst performer:** {worst_arch} ({win_rates[worst_arch]:.0f}% win rate, "
                     f"avg depth {avg_depths[worst_arch]:.1f})")

        # Archetype spread
        if win_rates:
            spread = max(win_rates.values()) - min(win_rates.values())
            lines.append(f"4. **Archetype spread:** {spread:.0f} percentage points — "
                         f"{'Well balanced' if spread < 15 else 'Needs tuning' if spread < 30 else 'Significant imbalance'}")

        # Depth analysis
        if avg_depths:
            avg_all_depth = sum(avg_depths.values()) / len(avg_depths)
            lines.append(f"5. **Average depth reached:** {avg_all_depth:.1f}/20 — "
                         f"{'Most runs die early' if avg_all_depth < 5 else 'Mid-game is the challenge' if avg_all_depth < 12 else 'Late-game focus'}")

    lines.append("")
    lines.append("## Difficulty Mode Implications")
    lines.append("")
    lines.append("All bot runs use **Normal** difficulty. Projected impact of other modes:")
    lines.append("")
    lines.append("- **Easy** (+50% XP, -25% damage taken, +25% item drops, traps revealed): "
                 "Expected ~2-3x baseline win rate")
    lines.append("- **Hard** (-20% item drops, +3 monster perception): "
                 "Expected ~0.3-0.5x baseline win rate")
    lines.append("- **Ironman** (Hard + no rest healing): "
                 "Expected ~0.1-0.2x baseline win rate")
    lines.append("")

    lines.append("---")
    lines.append("")
    lines.append("*Report generated from automated bot playthroughs. "
                 "Human players using stealth, songs, forging, and voice abilities "
                 "will have significantly different outcomes.*")

    return "\n".join(lines)


def main():
    print(f"Loading results from: {RESULTS_DIR}")
    results = load_results()

    if not results:
        print("ERROR: No result files found in", RESULTS_DIR)
        sys.exit(1)

    print(f"Loaded {len(results)} results")

    # Write CSV
    write_csv(results)

    # Compute stats and generate report
    stats = compute_stats(results)
    report = generate_report(results, stats)

    os.makedirs(REPORT_OUTPUT.parent, exist_ok=True)
    with open(REPORT_OUTPUT, "w") as f:
        f.write(report)
    print(f"Report written: {REPORT_OUTPUT}")

    # Print summary to stdout
    print("\n" + "=" * 60)
    print("  QUICK SUMMARY")
    print("=" * 60)
    for arch, s in sorted(stats.items()):
        print(f"  {arch:12s}: {s['win_rate']:5.1f}% win | avg depth {s['avg_depth']:.1f} | "
              f"{s['avg_kills']:.0f} kills | {s['avg_turns']:.0f} turns")
    total_wr = sum(s["wins"] for s in stats.values()) / max(len(results), 1) * 100
    print(f"\n  OVERALL: {total_wr:.1f}% win rate across {len(results)} runs")
    print("=" * 60)


if __name__ == "__main__":
    main()
