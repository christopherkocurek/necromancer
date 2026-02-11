extends Node
## Manages damage floaters, combat VFX, status tick effects, and ability visual feedback.
## Listens to EventBus signals and spawns appropriate floaters + sprite effects.

var floater_container: Node2D

func _ready() -> void:
	# Connect to combat events
	EventBus.entity_damaged.connect(_on_entity_damaged)
	EventBus.entity_healed.connect(_on_entity_healed)
	EventBus.attack_missed.connect(_on_attack_missed)
	EventBus.attack_blocked.connect(_on_attack_blocked)
	EventBus.status_applied.connect(_on_status_applied)
	EventBus.critical_hit.connect(_on_critical_hit)
	# Status tick VFX (poison/burning/bleeding/regen)
	EventBus.status_tick.connect(_on_status_tick)
	# Ability VFX
	EventBus.ability_used.connect(_on_ability_used)

func set_container(container: Node2D) -> void:
	floater_container = container

# ============================================================================
# COMBAT EVENT HANDLERS
# ============================================================================

func _on_entity_damaged(entity: Node, damage: int, damage_type: String, _source: Node) -> void:
	if not floater_container or not entity:
		return

	var pos := _get_entity_position(entity)
	var color := DamageFloater.get_color_for_type(damage_type)

	# Scale text size with damage
	var size: int = 16 + clampi(damage / 5, 0, 8)

	DamageFloater.create_at(floater_container, pos, str(damage), color, size)

func _on_entity_healed(entity: Node, amount: int, _source: Node) -> void:
	if not floater_container or not entity:
		return

	var pos := _get_entity_position(entity)
	DamageFloater.create_at(floater_container, pos, "+" + str(amount), DamageFloater.COLOR_HEAL, 18)

	# Healing sparkle particles upward
	if entity is Entity:
		var ent: Entity = entity as Entity
		ent.vfx_particles_directional(ThemeColors.VFX_REGEN_SPARKLE, Vector2.UP, 3, 0.5, 15.0, 0.4)

func _on_attack_missed(_attacker: Node, defender: Node) -> void:
	if not floater_container or not defender:
		return

	var pos := _get_entity_position(defender)
	DamageFloater.create_at(floater_container, pos, "MISS", DamageFloater.COLOR_MISS, 14)

	# Dodge animation: brief horizontal shift and back
	if defender is Entity:
		var ent: Entity = defender as Entity
		ent.vfx_dodge(2.0, 0.15)

func _on_attack_blocked(_attacker: Node, defender: Node, damage_blocked: int) -> void:
	if not floater_container or not defender:
		return

	var pos := _get_entity_position(defender)
	DamageFloater.create_at(floater_container, pos, "BLOCKED! " + str(damage_blocked), ThemeColors.DMG_BLOCK, 16)

	# Shield impact: yellow flash + shield spark particles
	if defender is Entity:
		var ent: Entity = defender as Entity
		ent.vfx_flash(ThemeColors.FLASH_BLOCK_YELLOW, 0.1, 0.1)
		ent.vfx_particles(ThemeColors.DMG_BLOCK, 3, 20.0, 0.3)

func _on_status_applied(entity: Node, status_name: String, _duration: int) -> void:
	if not floater_container or not entity:
		return

	var pos := _get_entity_position(entity)

	# Dispatch enhanced VFX based on status type
	match status_name.to_lower():
		"afraid":
			DamageFloater.create_at(floater_container, pos + Vector2(0, -20), "AFRAID!", ThemeColors.STATUS_AFRAID, 16)
			if entity is Entity:
				var ent: Entity = entity as Entity
				ent.vfx_flash(ThemeColors.FLASH_FEAR_ORANGE, 0.08, 0.2)
				# Cowering particles dripping downward
				ent.vfx_particles_directional(ThemeColors.DMG_DARK, Vector2.DOWN, 3, 0.3, 15.0, 0.4)
		"stunned":
			DamageFloater.create_at(floater_container, pos + Vector2(0, -20), "STUNNED!", ThemeColors.STATUS_STUNNED, 16)
			if entity is Entity:
				var ent: Entity = entity as Entity
				ent.vfx_flash(ThemeColors.FLASH_STUN_RED, 0.1, 0.15)
				# Stars circling above head
				ent.vfx_ring_particles(ThemeColors.VFX_STUN_STAR, 5, 8.0, 0.6)
		"poisoned":
			DamageFloater.create_at(floater_container, pos + Vector2(0, -20), "POISONED!", ThemeColors.STATUS_POISON, 14)
			if entity is Entity:
				var ent: Entity = entity as Entity
				ent.vfx_flash(ThemeColors.FLASH_POISON_GREEN, 0.05, 0.25)
				# Green drip particles downward
				ent.vfx_particles_directional(ThemeColors.VFX_POISON_DRIP, Vector2.DOWN, 3, 0.3, 18.0, 0.5)
		"burning":
			DamageFloater.create_at(floater_container, pos + Vector2(0, -20), "BURNING!", ThemeColors.STATUS_BURNING, 14)
			if entity is Entity:
				var ent: Entity = entity as Entity
				ent.vfx_flash(Color(ThemeColors.DMG_FIRE, 1.0), 0.08, 0.2)
				ent.vfx_particles_directional(ThemeColors.VFX_BURN_FLAME, Vector2.UP, 3, 0.5, 15.0, 0.4)
		"cut":
			DamageFloater.create_at(floater_container, pos + Vector2(0, -20), "BLEEDING!", ThemeColors.STATUS_CUT, 14)
			if entity is Entity:
				var ent: Entity = entity as Entity
				ent.vfx_particles_directional(ThemeColors.VFX_BLEED_DROP, Vector2.DOWN, 2, 0.3, 12.0, 0.4)
		"confused":
			DamageFloater.create_at(floater_container, pos + Vector2(0, -20), "CONFUSED!", ThemeColors.STATUS_CONFUSED, 14)
			if entity is Entity:
				var ent: Entity = entity as Entity
				ent.vfx_ring_particles(ThemeColors.STATUS_CONFUSED, 4, 10.0, 0.5)
		"blind":
			DamageFloater.create_at(floater_container, pos + Vector2(0, -20), "BLIND!", ThemeColors.STATUS_BLIND, 14)
		"slow":
			DamageFloater.create_at(floater_container, pos + Vector2(0, -20), "SLOWED!", ThemeColors.STATUS_SLOW, 14)
		"entranced":
			DamageFloater.create_at(floater_container, pos + Vector2(0, -20), "ENTRANCED!", ThemeColors.STATUS_ENTRANCED, 14)
			if entity is Entity:
				var ent: Entity = entity as Entity
				ent.vfx_ring_particles(ThemeColors.STATUS_ENTRANCED, 5, 10.0, 0.8)
		_:
			# Generic status floater
			var color := ThemeColors.PRIMARY
			DamageFloater.create_at(floater_container, pos + Vector2(0, -20), status_name, color, 12)

func _on_critical_hit(_attacker: Node, target: Node, damage: int) -> void:
	if not floater_container or not target:
		return

	var pos := _get_entity_position(target)
	var size: int = 22 + clampi(damage / 5, 0, 8)
	DamageFloater.create_at(floater_container, pos + Vector2(0, -16), str(damage) + "!!", ThemeColors.DMG_CRIT, size)

	# Enhanced crit: white-hot flash + gold particle burst
	if target is Entity:
		var ent: Entity = target as Entity
		ent.vfx_flash(ThemeColors.FLASH_CRIT_WHITE, 0.06, 0.12)
		ent.vfx_particles(ThemeColors.DMG_CRIT, 8, 35.0, 0.4)

	# Camera shake is already handled in game_camera.gd _on_critical_hit

# ============================================================================
# STATUS TICK VFX (damage-over-time visual feedback)
# ============================================================================

func _on_status_tick(entity: Node, status_name: String, remaining: int) -> void:
	if not floater_container or not entity:
		return
	if not is_instance_valid(entity):
		return
	# Only show tick VFX for DOT effects that deal damage or regen
	if remaining <= 0:
		return

	var pos := _get_entity_position(entity)

	match status_name.to_lower():
		"poisoned":
			# Small green damage floater + green drip particles
			var dmg: int = _estimate_dot_damage(status_name, remaining)
			if dmg > 0:
				DamageFloater.create_at(floater_container, pos, "-" + str(dmg), ThemeColors.STATUS_POISON, 12)
			if entity is Entity:
				var ent: Entity = entity as Entity
				ent.vfx_particles_directional(ThemeColors.VFX_POISON_DRIP, Vector2.DOWN, 2, 0.3, 12.0, 0.3)
		"burning":
			# Small orange damage floater + flame particles upward
			var dmg: int = _estimate_dot_damage(status_name, remaining)
			if dmg > 0:
				DamageFloater.create_at(floater_container, pos, "-" + str(dmg), ThemeColors.STATUS_BURNING, 12)
			if entity is Entity:
				var ent: Entity = entity as Entity
				ent.vfx_particles_directional(ThemeColors.VFX_BURN_FLAME, Vector2.UP, 3, 0.5, 15.0, 0.3)
		"cut":
			# Small red damage floater + blood drop particles
			var dmg: int = _estimate_dot_damage(status_name, remaining)
			if dmg > 0:
				DamageFloater.create_at(floater_container, pos, "-" + str(dmg), ThemeColors.STATUS_CUT, 12)
			if entity is Entity:
				var ent: Entity = entity as Entity
				ent.vfx_particles_directional(ThemeColors.VFX_BLEED_DROP, Vector2.DOWN, 2, 0.2, 10.0, 0.3)

## Estimate DOT damage for floater display.
## The actual damage is applied by StatusEffects._apply_damage(); this is just for visual indication.
func _estimate_dot_damage(status_name: String, remaining: int) -> int:
	match status_name.to_lower():
		"poisoned":
			return maxi(1, remaining / 10)
		"burning":
			return maxi(1, remaining / 5)
		"cut":
			return maxi(1, remaining / 10)
	return 0

# ============================================================================
# ABILITY VFX
# ============================================================================

func _on_ability_used(entity: Node, _ability: Resource, targets: Array) -> void:
	# The AbilitySystem emits ability_used with (player, null, [target_or_empty])
	# We also listen to AbilitySystem.ability_activated for the ability_id
	# Since we only get the entity and targets here, defer to the ability_activated signal
	# for specific ability VFX. This handler provides generic ability feedback.
	pass

## Connect to an AbilitySystem to receive specific ability VFX triggers.
## Called from main.gd after ability_system is created.
func connect_ability_system(ability_sys: Node) -> void:
	if ability_sys.has_signal("ability_activated"):
		if not ability_sys.ability_activated.is_connected(_on_ability_activated):
			ability_sys.ability_activated.connect(_on_ability_activated)

func _on_ability_activated(ability_id: int, _ability_name: String) -> void:
	var player: Node = GameManager.player
	if not player or not is_instance_valid(player):
		return

	match ability_id:
		146:  # Word of Command
			_vfx_word_of_command(player)
		141:  # Word of Opening
			_vfx_word_of_opening(player)
		143:  # Herbcraft (sustained, triggered on toggle)
			_vfx_herbcraft(player)
		150:  # Song of Banishment
			_vfx_song_of_banishment(player)
		145:  # Light of the Eldar
			_vfx_inner_light(player)

## Word of Command: Blue-white shockwave, 12 radiating particles, zoom pulse
func _vfx_word_of_command(player: Node) -> void:
	if player is Entity:
		var ent: Entity = player as Entity
		ent.vfx_flash(ThemeColors.FLASH_COMMAND_BLUE, 0.08, 0.15)
		ent.vfx_particles(Color(0.7, 0.85, 1.0), 12, 45.0, 0.5)
	# Camera zoom pulse
	_do_camera_zoom_pulse(2.05, 0.3)

## Lore of Battle: Red aura flash + 4 red particles outward
func _vfx_lore_of_battle(player: Node) -> void:
	if player is Entity:
		var ent: Entity = player as Entity
		ent.vfx_flash(ThemeColors.FLASH_RED_HOLD, 0.06, 0.12)
		ent.vfx_particles(ThemeColors.DMG_PHYSICAL, 4, 25.0, 0.35)

## Word of Opening: Blue flash + blue particles
func _vfx_word_of_opening(player: Node) -> void:
	if player is Entity:
		var ent: Entity = player as Entity
		ent.vfx_flash(ThemeColors.FLASH_OPENING_BLUE, 0.08, 0.15)
		ent.vfx_particles(ThemeColors.DMG_COLD, 6, 35.0, 0.4)

## Herbcraft: Green healing sparkle + 5 green particles upward
func _vfx_herbcraft(player: Node) -> void:
	if player is Entity:
		var ent: Entity = player as Entity
		ent.vfx_flash(ThemeColors.FLASH_HERBCRAFT_GREEN, 0.05, 0.2)
		ent.vfx_particles_directional(ThemeColors.VFX_REGEN_SPARKLE, Vector2.UP, 5, 0.6, 20.0, 0.4)

## Song of Banishment: Purple ring of particles expanding outward
func _vfx_song_of_banishment(player: Node) -> void:
	if player is Entity:
		var ent: Entity = player as Entity
		ent.vfx_flash(ThemeColors.FLASH_BANISH_PURPLE, 0.1, 0.2)
		ent.vfx_particles(ThemeColors.DMG_DARK, 8, 50.0, 0.6)

## Inner Light: Gold glow + radiating gold/white particles + brief screen brighten
func _vfx_inner_light(player: Node) -> void:
	if player is Entity:
		var ent: Entity = player as Entity
		# Gold glow (complementing the FLASH_CHARGE already applied in ability_system.gd)
		ent.vfx_particles(ThemeColors.GOLD_BRIGHT, 8, 40.0, 0.5)
	# Brief screen brighten via scene modulate
	_do_screen_brighten(0.3)

## Helper: trigger camera zoom pulse if camera exists
func _do_camera_zoom_pulse(target_zoom: float, duration: float) -> void:
	var player: Node = GameManager.player
	if not player or not is_instance_valid(player):
		return
	# Find the GameCamera attached to the player
	for child in player.get_children():
		if child is Camera2D and child.has_method("zoom_pulse"):
			child.zoom_pulse(target_zoom, duration)
			return

## Helper: briefly brighten the scene modulate (for light burst effects)
func _do_screen_brighten(duration: float) -> void:
	var root: Node = get_tree().current_scene
	if not root or not root is Node2D:
		return
	var scene_root: Node2D = root as Node2D
	var original_mod: Color = scene_root.modulate
	var bright: Color = Color(original_mod.r * 1.1, original_mod.g * 1.1, original_mod.b * 1.1, original_mod.a)
	scene_root.modulate = bright
	var t := create_tween()
	t.tween_property(scene_root, "modulate", original_mod, duration).set_ease(Tween.EASE_IN)

# ============================================================================
# HELPERS
# ============================================================================

func _get_entity_position(entity: Node) -> Vector2:
	if entity.has_method("get_world_position"):
		return entity.get_world_position()
	elif entity is Node2D:
		return entity.global_position
	return Vector2.ZERO
