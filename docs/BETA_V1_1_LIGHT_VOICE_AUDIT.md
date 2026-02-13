# Beta v1.1 Light + Voice Economy Audit

Date: 2026-02-13
Scope: compare current Godot implementation against the Sil-Q baseline (local `../sil-q/lib/edit/object.txt`) and requested beta tuning.

## 1) Light source baseline (Sil-Q reference)

Sil-Q `I:39:*` light set includes:
- Wooden Torch (`sval 0`)
- Brass Lantern (`sval 1`)
- Elven Light (`sval 2`)
- Mallorn Torch (`sval 3`)
- Jewel-lamp (`sval 8`)
- Star-glass (`sval 9`)

The Necromancer data mirrors this set in `data/object.txt`.

## 2) Implemented in this pass

- Default content scale base moved to 1920x1080 (`scripts/main.gd`, `project.godot`).
- Light radius map in `Player.get_light_radius()` now explicitly handles:
  - Torch: `+2`
  - Lantern: `+3`
  - Elven Light: `+2`
  - Mallorn Torch: `+3`
  - Jewel-lamp: `+4`
- Elven Light + Jewel-lamp set to non-consuming fuel behavior.
- Mallorn Torch fuel default added (`100`).
- Light egos on weapon/armor/jewelry now contribute `+1` radius via `LIGHT` flag.
- `LIGHT_CURSE` now reduces effective radius by `1`.
- Light of the Eldar aura changed to fixed `+2` radius (removed Lore scaling inflation).

## 3) Voice economy tuning implemented

- Removed duplicate rest-time voice regen call (rest no longer gives extra out-of-band voice regen).
- Voice regen now reduced while sustained voice effects are active:
  - singing: `50%` regen rate
  - Light of the Eldar active: additional `20%` reduction
- Lore voice costs adjusted to rebalance sustain vs high-impact words:
  - Herbcraft: `2`/turn (was `1`)
  - Song of Healing: `2`/turn (was `1`)
  - Deep Memory: `12` (was `15`)
  - Word of Authority: `5` (was `4`)
  - Word of Unmaking: `6` (was `5`)

## 4) Poison feel fix implemented

- Poison duration decay now decrements by exactly `1` per tick (`calculate_poison_decay`).

## 5) Remaining economy validation gates (next loop)

- Run automated floor-depth sampling for average effective light radius at depth bands:
  - 1-5, 6-10, 11-15, 16-20
- Confirm target outcome: avg radius beyond depth 10 remains above pre-pass values.
- Validate ego-light contribution appears in HUD/tooltip clarity.
- Tune sustain breakpoints for pure-lore viability with 200+ simulated runs.
