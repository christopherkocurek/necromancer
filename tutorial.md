# The Necromancer Playtest Guide (Human + Agent Friendly)

Version: 2026-02-13  
Audience: non-gamers, first-time playtesters, and AI assistants helping them  
Goal: get each tester to a stable 20-40 minute session with useful feedback

---

## 1) Install and Launch on macOS

1. Unzip `TheNecromancer-slim-macOS.zip`.
2. Open `TheNecromancer-slim.app`.
3. If macOS blocks launch:
   - Right-click app -> `Open` -> `Open`
   - Or `System Settings -> Privacy & Security -> Open Anyway`

Notes:
- This internal test build is unsigned, so the first-run warning is expected.

---

## 2) Character Creation: Pick 1 of 3 Beginner Archetypes

If you are unsure, choose Archetype A.

### Archetype A: Iron Vanguard (easiest melee start)

- Race: `Dwarf`
- House: `Of Erebor` (or `Of the Iron Hills`)
- Trait: `Undying Resolve` (safest)  
  Alternative: `Mithril Skin` (tankier, lower evasion ceiling)

Stat priority:
1. `CON`
2. `STR`
3. `DEX`
4. `GRA`

Skill investment priority:
1. `Melee`
2. `Evasion`
3. `Will`
4. `Hunting`

Early abilities to buy when available:
1. `Power` (Melee)
2. `Defensive Stance` (Melee)
3. `Parry` or `Blocking` (Evasion)
4. `Curse Breaking` (Will)

Playstyle:
- Fight in doorways/chokepoints.
- Wait (`.` or numpad `5`) before enemies step in to control engagements.
- Rest often between fights.

### Archetype B: Dunedain Ranger (safe ranged + scouting)

- Race: `Man`
- House: `Dunedain`
- Trait: `Wayfarer's Instinct`  
  Alternative: `Steady Aim`

Stat priority:
1. `DEX`
2. `CON`
3. `GRA`
4. `STR`

Skill investment priority:
1. `Archery`
2. `Hunting`
3. `Evasion`
4. `Stealth`

Early abilities to buy when available:
1. `Keen Eyes` (Archery)
2. `Crippling Shot` (Archery)
3. `Focused Attack` / Mark Quarry tools (Hunting)
4. `Keen Senses` (Hunting)

Playstyle:
- Engage from range; back up before enemies reach melee.
- Use corners and long corridors.
- Use scouting tools before entering dark/open rooms.

### Archetype C: Eldar Warden (light + control caster-fighter)

- Race: `Elf`
- House: `Of Lothlorien`
- Trait: `Echoes of the Firstborn`  
  Alternative: `Light of the Eldar`

Stat priority:
1. `GRA`
2. `DEX`
3. `CON`
4. `STR`

Skill investment priority:
1. `Lore`
2. `Will`
3. `Hunting`
4. `Evasion`

Early abilities to buy when available:
1. `Word of Opening` (Lore)
2. `Herbcraft` (Lore)
3. `Light of the Eldar` (Lore)
4. `Song of Freedom` (Lore)

Playstyle:
- Keep vision and status control active.
- Use Voice abilities to stabilize difficult fights.
- Avoid being surrounded; kite and reposition.

---

## 3) Quick Controls (Only What You Need)

Movement and turn flow:
- Move: `WASD`, arrows, or numpad directions
- Wait 1 turn: `.`
- Rest: `Z` (until recovered), `Shift+Z` (fixed rest)
- Use stairs/dialogue advance: `Enter`

Core interactions:
- Inventory: `I`
- Pick up: `G`
- Equip quick action: `E`
- Unequip: `R` (in inventory context)
- Open chest: `O`
- Look/examine: `X`

Abilities:
- Gem slots cast: `1..6`
- Voice/Lore ability menu: `V`
- Empty gem slot + key press opens bind flow

Help/UI:
- Toggle help: `?`
- Escape/close menu: `Esc`

---

## 4) In-Game Basics: First 10 Minutes

1. Move a few tiles, check your light/visibility.
2. Pick up first useful item (`G`), open inventory (`I`), equip upgrades.
3. Fight 1-2 enemies near a retreat path (avoid blind rushing).
4. After combat, rest (`Z`) when safe (no visible monsters).
5. Use at least one active ability:
   - Gem ability via `1..6`, or
   - Voice ability via `V`.
6. Descend one floor (`Enter` on stairs down), repeat loop.

Safe combat rule:
- If HP drops fast or multiple enemies appear, retreat to a corridor/doorway.

---

## 5) Active Ability Workflow (for non-gamers)

Gem ability workflow:
1. Press `1..6`.
2. If slot is empty, bind an ability.
3. Press same number again to cast.

Voice/Lore workflow:
1. Press `V`.
2. Choose ability in the list.
3. If targeting is required, pick target tile/enemy.
4. Confirm and end turn.

If input feels stuck:
1. Press `Esc`.
2. Close open panel/menu.
3. Try action again.

---

## 6) Dungeon Crawling Loop (simple mental model)

Repeat this loop:
1. Scout room edge before entering.
2. Pull enemies into favorable terrain.
3. Loot + equip incremental upgrades.
4. Rest when safe.
5. Descend when stable.

Common mistakes to avoid:
- Standing in hazards (lava/poison/dark pools/webs).
- Pushing into unknown black tiles at low HP.
- Forgetting to use abilities and consumables.

---

## 7) Inventory and Equipment (minimal rules)

Equipment slots matter:
- Weapon/off-hand/armor/head/light/amulet directly affect survival.

Priorities:
1. Keep a functional light source equipped.
2. Upgrade weapon first, then survivability armor pieces.
3. Keep healing/utility consumables in inventory (and utility bar if used).

When deciding between two items:
1. For melee builds: prefer better damage/protection.
2. For ranged builds: preserve safety/evasion and bow support.
3. For lore builds: keep survivability high; Voice tools are strongest when alive.

---

## 8) What We Need From Playtesters

Required coverage per tester (minimum):
1. Create one character from one archetype above.
2. Reach at least depth 3+ (or 20+ minutes).
3. Use inventory, at least one active ability, and at least one rest cycle.
4. Report at least one UX pain point and one gameplay balance note.

Bug report template:

```text
Issue:
Expected:
Actual:
Depth:
Archetype:
Last 3 actions:
Screenshot/video:
```

---

## 9) AI Assistant Handhold Protocol

If an AI agent is helping a tester, use this protocol:

1. Ask which archetype (`A`, `B`, or `C`) they picked.
2. Give only the next 1-2 actions, not full walls of advice.
3. After each encounter, ask:
   - current HP,
   - if abilities were used,
   - if inventory changed.
4. If user reports confusion/stuck input:
   - instruct `Esc`, close panel, retry action.
5. Capture structured bug report using the template in section 8.

Agent objective:
- keep player progressing,
- prevent panic/death spirals from basic mistakes,
- extract high-quality reproducible feedback.
