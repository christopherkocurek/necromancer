# Top20 End-to-End User Story Audit (2026-02-12)

Purpose: validate that implemented features are visible and usable from a player perspective, not only present in backend code.

## Subset A: Combat Intent + Threat Readability
1. As a new player, when I inspect a monster in Look mode, I can see an expected attack type.
2. As a player with low Hunting, I still receive a coarse hostile-intent read.
3. As a player with higher Hunting, I receive clearer intent details (target/ETA/action clarity).
4. As a tactical player, I can see intent in both Look and Target panels.
5. As a pressured player, I can see always-on HUD threat state and minimize it.

Status: PASS (after patch)
Evidence:
- `scripts/entities/monster.gd` intent tiers now return coarse read at tier 0.
- `scripts/ui/look_panel.gd` now prints expected attack type + intent + target + ETA.
- `scripts/ui/target_panel.gd` now prints expected attack type + intent + target + ETA.
- `scripts/ui/hud.gd` threat strip with minimize toggle.

## Subset B: Hunting Duel Ability Loop
1. As a hunter build, I can activate Mark Quarry on a visible target.
2. As a hunter build, I can use Expose Weakness on a marked target.
3. As a hunter build, I can spend Focus with Exploit Opening.
4. As a player, I can see hunting state in UI (HUNT card / cues).
5. As a player, keybinds are documented and usable in run.

Status: PASS
Evidence:
- `scripts/entities/player.gd` (`activate_mark_quarry`, `activate_expose_weakness`, `activate_exploit_opening`).
- `scripts/entities/monster.gd` (`apply_hunter_exposure`).
- `scripts/main.gd` (`Shift+H`, `Shift+X`, `Shift+E`).
- `project.godot` input map entries.
- `scripts/ui/help_overlay.gd` keybind reference.

## Subset C: Ancient Scroll/Tome Consistency
1. As a player reading the Hunting chapter, I see the new ability names, not legacy names.
2. As a player opening details, I read behavior matching actual implementation.
3. As a player using Lore chapter, voice bar reflects real current/max voice.
4. As a player, chapter list and detail names are consistent.
5. As a player, UI naming matches in-run keybind language.

Status: PASS (after patch)
Evidence:
- `data/ability.txt` canonical names updated to Mark Quarry / Expose Weakness / Exploit Opening.
- `scripts/ui/tome_panel.gd` display-name/description overrides for new hunting flow.
- `scripts/ui/tome_panel.gd` voice bar uses `voice_charges`/`max_voice`.

## Subset D: Death Forensics + Counterplay
1. As a player who dies, I can read immediate causal chain events.
2. As a player who dies, I can identify killing effect and last damage source/type.
3. As a player, I can see severity and category markers in recap.
4. As a learner, I receive actionable counterplay suggestions.
5. As a returning player, I can open chronicle summaries from death flow.

Status: PASS
Evidence:
- `scripts/ui/death_screen.gd` forensic timeline + counterplay + chronicle key.
- `scripts/systems/status_effects.gd` DOT/resist forensic notes.
- `scripts/entities/player.gd` damage forensic quality fix.

## Subset E: Chronicle Meta Surface
1. As a player, deaths are recorded to Chronicle.
2. As a player, victories are recorded to Chronicle.
3. As a player, I can browse Chronicle via Tome.
4. As a player, I can browse Chronicle from character-creation/main menu flow.
5. As a player, run goal tags appear in chronicle records.

Status: PASS
Evidence:
- `scripts/systems/chronicle_manager.gd` persistence.
- `scripts/main.gd` death writes; `scripts/systems/quest_system.gd` victory writes.
- `scripts/ui/tome_panel.gd` Chronicle mode.
- `scripts/ui/character_creation.gd` Chronicle button / popup.

## Subset F: Pursuit + Oppression Feedback
1. As a player, I see pursuit tier and pressure score in HUD.
2. As a player, pursuit escalation materially changes gameplay pressure.
3. As a player, high pursuit has reinforcement/lockdown consequences.
4. As a player, pursuit state communicates urgency.
5. As a player, pressure changes are not silent.

Status: PASS
Evidence:
- `scripts/ui/hud.gd` pursuit line.
- `scripts/systems/turn_system.gd` pressure effects.

## Subset G: Assist/Hardcore Policy
1. As a normal-mode player, I can enable assist and get readability support.
2. As a hardcore player, helper surfaces are disabled per policy.
3. As a player, Hunting/Lore still increase opponent-read precision.
4. As a player, assist settings are clearly adjustable.
5. As a player, mode indicator communicates policy state.

Status: PASS
Evidence:
- `scripts/systems/accessibility_manager.gd`
- `scripts/ui/settings_panel.gd`
- `scripts/core/game_manager.gd`
- `scripts/ui/hud.gd` mode indicator

## Subset H: Input UX (Voice + Camera)
1. As a player, pressing `V` opens voice skills.
2. As a player, `Shift+V` toggles free camera mode.
3. As a player in free camera mode, movement pans and Escape exits.
4. As a player, key help overlay matches actual controls.
5. As a player, no control conflicts block core actions.

Status: PASS (after patch)
Evidence:
- `scripts/main.gd` V/Shift+V split.
- `scripts/ui/help_overlay.gd` reflects split controls.

## Final Gate
- Headless boot/parse: required pass.
- Standalone launch for playtest: required pass.

