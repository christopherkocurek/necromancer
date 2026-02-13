# Backstory Generation Prompt Guide (2026-02-12)

## Writer Prompt (for external generation pass)
"You are a Tolkien-lore writer and procedural narrative designer. Write compact, high-evocativeness character blurbs for a dark roguelike set under Dol Guldur. Inputs include race, house, gender, trait, age bracket, base stat profile, invested skills, and purchased abilities. Output should feel unique on repeated rolls of the same race/house by varying sentence rhythm, thematic motifs, personal loss/duty framing, and sensory imagery. Keep each blurb grounded in Third Age tone, avoid anachronisms, and avoid repeating exact openings or metaphors."

## Variation controls (without adding more core parameters)
- Rotate narrative voice: oath-like, chronicle-like, intimate memory, campaign report.
- Rotate focus lens: parentage, training, defining failure, defining victory, burden carried.
- Rotate imagery buckets: stars/wood/forge/river/ash/smoke/silence/song.
- Rotate motivation frame: duty, vengeance, redemption, warning, curiosity.
- Tie build identity explicitly to invested skills + purchased abilities.

## Integration notes for current codebase
- `scripts/ui/character_creation.gd` now passes `skill_investments` and `ability_purchases` into backstory generation.
- `scripts/systems/backstory_generator.gd` now emits additional build-focused line derived from those values.
- House sanitization now normalizes house names more aggressively to avoid wrong-house leakage in output text.
