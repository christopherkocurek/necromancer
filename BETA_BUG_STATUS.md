# Beta v1.0 Bug Status (Session Audit)

Last updated: 2026-02-13
Source list: "Beta v1.0 Notes" from playtest feedback in this session.

Status legend:
- `Done`: implemented in current workspace changes.
- `Partial`: some work landed, but request not fully complete or not yet verified against exact repro.
- `Open`: no implementation found yet in current workspace changes.

## Done

1. `Needs an updated muser manual`
- Status: `Done` (playtest guide added; typo "muser" interpreted as "user")
- Evidence: `tutorial.md`

2. `Needs better keybindings (wasd does not work)`
- Status: `Done`
- Notes: removed keybind conflicts that consumed `A`/`D` in gameplay input path.
- Evidence: `scripts/main.gd`, `scripts/ui/help_overlay.gd`

3. `Better key binds for diagnonals`
- Status: `Done`
- Notes: directional prompt now follows action map (including physical-keycode movement bindings).
- Evidence: `scripts/ui/direction_prompt.gd`, `tests/unit/test_direction_prompt.gd`

4. `Spider webs should be destructible by tunneling with any weapon`
- Status: `Done`
- Evidence: `scripts/main.gd`, `scripts/systems/level.gd`

5. `Brood mother hitting me with slow webs is not visually clear... projectile ... web vfx hit me`
- Status: `Done` (applies to web-shooting spiders generally)
- Evidence: `scripts/entities/monster.gd`

6. `Cant make bows and arrows at forge`
- Status: `Done`
- Evidence: `scripts/systems/smithing_system.gd`

7. `What is arrow economy?... forge arrows ... enough for ranged builds`
- Status: `Done`
- Notes: increased ammo stack handling in smithing/spawn and improved conservation behavior.
- Evidence: `scripts/systems/smithing_system.gd`, `scripts/systems/dungeon_generator.gd`, `scripts/entities/player.gd`

8. `Hold down direction - keep moving`
- Status: `Done`
- Evidence: `scripts/entities/player.gd`

9. `I was a able to shoot myself with bow`
- Status: `Done`
- Evidence: `scripts/main.gd`

10. `Sometimes, doors spawn in non-sensical places...`
- Status: `Done`
- Notes: stricter placement and post-decoration sanitation.
- Evidence: `scripts/systems/dungeon_generator.gd`

11. `Torches aren’t consuming fuel units... lanterns`
- Status: `Done`
- Evidence: `scripts/core/data_manager.gd`, `scripts/entities/player.gd`, `scripts/systems/turn_system.gd`

12. `Songs / herb craft / shouldn’t take a turn to activate`
- Status: `Done`
- Evidence: `scripts/main.gd`

13. `Mining tool not working... SHIFT T not working, nor directional pathing`
- Status: `Done`
- Notes: fixed Shift+T direction handling via action-map aware prompt; added integration test.
- Evidence: `scripts/ui/direction_prompt.gd`, `tests/unit/test_direction_prompt.gd`, `tests/integration/test_mining_tunnel_input.gd`

14. `I sniped dark acolyte and orc slave - they didnt pursue me after many arrows`
- Status: `Done`
- Evidence: `scripts/entities/monster.gd`

15. `O auto explore should work while poisoned unless you are below 25% hp`
- Status: `Done`
- Evidence: `scripts/systems/auto_explore.gd`

16. `I took lore of endurance skill ... should not proc WHENEVER ... but when >20% HP`
- Status: `Done`
- Evidence: `scripts/entities/player.gd`, `scripts/systems/effect_definitions.gd`, `scripts/systems/status_metadata.gd`

17. `Thick webs using wrong tile / spider webs in general ... default floor tile approach`
- Status: `Done` (for layers with baked web-floor atlas variants; fallback retained for deeper layers without baked variants)
- Evidence: `scripts/core/tile_mapper.gd`, `tests/unit/test_tile_mapper_layer_webs.gd`

18. `AFFINITY is not understandable in char create`
- Status: `Done`
- Notes: house panel now shows affinity + penalty lists and explicit XP-cost effects; skills view shows `*`/`!` markers and cost breakdowns.
- Evidence: `scripts/ui/character_creation.gd`, `scripts/entities/player.gd`, `tests/unit/test_affinity_penalty_costs.gd`

19. `Minimap is hard to read ... 50% bigger ... transparent black square ... click to expand`
- Status: `Done`
- Notes: minimap uses framed black backdrop (~35% alpha), larger compact default size, and click-to-expand/collapse behavior.
- Evidence: `scripts/ui/hud.gd`, `scripts/ui/minimap.gd`, `tests/unit/test_hud_minimap_layout.gd`

## Partial

1. `Poison status effect seems bugged in the HUD display`
- Status: `Partial`
- Notes: status icon rendering and tick updates were improved, but the exact original bug repro has not been explicitly revalidated end-to-end.
- Evidence: `scripts/ui/hud.gd`, `scripts/systems/status_metadata.gd`

2. `XP gem not showing up`
- Status: `Partial`
- Notes: no direct XP gem-specific patch was isolated in this audit pass; prior HUD work may have impacted this indirectly.
- Evidence: `scripts/ui/hud.gd` (broad HUD/icon changes)

3. `Icons on buff bars need to show up`
- Status: `Partial`
- Notes: buff/status icon handling improved with fallbacks; needs explicit visual QA in gameplay.
- Evidence: `scripts/ui/hud.gd`, `scripts/ui/inventory_panel.gd`

## Open

1. `Needs tutorial system`
2. `A wizard chat !!!`
5. `Give a "blueprint" archetype roller based on questionnaire`
6. `"Light up" glow effect vfx when doriath / gondolin weapons activate`
8. `Need more PATROLS`
9. `sil-q system of experience ... XP for killing and seeing ... XP has DR`
10. `Food isnt punishing enough`
11. `Inscription encounters should pop up chronicle-style UI ... procedural lore`

## Notes

1. This file tracks implementation presence in current workspace changes, not commit history.
2. One pre-existing gameplay test failure remains unrelated to the above items:
- `tests/gameplay/test_dungeon_generation.gd`: `Tile 8 should be passable`
