extends Node2D
class_name Entity
## Base class for all game entities (player, monsters, NPCs).
## Handles position, stats, movement, and combat.

signal moved(from: Vector2i, to: Vector2i)
signal damaged(amount: int, source: Entity)
signal died(killer: Entity)

# Grid position (tile coordinates)
@export var grid_position: Vector2i = Vector2i.ZERO:
	set(value):
		var old_pos := grid_position
		grid_position = value
		if old_pos != value:
			moved.emit(old_pos, value)
			_update_visual_position()

# Core stats
@export var entity_name: String = "Entity"
@export var max_health: int = 10
@export var current_health: int = 10
@export var strength: int = 0
@export var dexterity: int = 0
@export var constitution: int = 0
@export var grace: int = 0
@export var armor_class: int = 0
@export var speed: int = 2  # Actions per round

# Combat stats
@export var melee_bonus: int = 0
@export var evasion_bonus: int = 0
@export var damage_dice: String = "1d4"

# Protection dice (replaces flat armor_class reduction)
var protection_dice: int = 0   # Number of dice (pd)
var protection_sides: int = 0  # Sides per die (ps)

# Energy system
var energy: int = 0

# Visual
@export var sprite_index: int = 0  # Monster/entity ID for tile lookup
var sprite: Sprite2D
var _pending_atlas_coords: Vector2i = Vector2i(-1, -1)  # Coords to apply after sprite creation

# Shared resources (loaded once)
static var _tileset_texture: Texture2D = null
static var _magenta_shader: ShaderMaterial = null

# State
var is_alive: bool = true
var status_effects: Dictionary = {}  # name -> {duration: int, data: Variant} (legacy, synced from status_fx)
var status_fx: StatusEffects  # New status effect system

func _ready() -> void:
	status_fx = StatusEffects.new(self)
	_setup_sprite()
	_update_visual_position()

func _setup_sprite() -> void:
	# Get or create sprite
	if has_node("Sprite2D"):
		sprite = $Sprite2D
	else:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)

	# Load shared resources if not loaded
	if not _tileset_texture:
		_tileset_texture = load("res://assets/sprites/necromancer_dcss_tileset.png")
	if not _magenta_shader:
		_magenta_shader = load("res://assets/shaders/magenta_transparent.tres")

	# Configure sprite
	sprite.texture = _tileset_texture
	sprite.region_enabled = true
	sprite.material = _magenta_shader

	# Apply pending atlas coords if set, otherwise use default
	if _pending_atlas_coords != Vector2i(-1, -1):
		_apply_atlas_coords(_pending_atlas_coords)
	else:
		_update_sprite_region()

func _update_sprite_region() -> void:
	if not sprite or not TileMapper:
		return

	var atlas_coords := TileMapper.get_monster_coords(sprite_index)
	var tile_size := GameManager.TILE_SIZE
	sprite.region_rect = Rect2(
		atlas_coords.x * tile_size,
		atlas_coords.y * tile_size,
		tile_size,
		tile_size
	)

func set_sprite_from_monster_id(monster_id: int) -> void:
	sprite_index = monster_id
	if sprite:
		_update_sprite_region()
	# If sprite doesn't exist yet, _update_sprite_region will be called in _setup_sprite

func set_sprite_from_player_id(race_id: int) -> void:
	var atlas_coords := TileMapper.get_player_coords(race_id)
	set_sprite_from_atlas_coords(atlas_coords)

func set_sprite_from_player_v2(race_name: String, house_id: int, gender: String = "male") -> void:
	var atlas_coords := TileMapper.get_player_coords_v2(race_name, house_id, gender)
	set_sprite_from_atlas_coords(atlas_coords)

func set_sprite_from_atlas_coords(atlas_coords: Vector2i) -> void:
	_pending_atlas_coords = atlas_coords
	if sprite:
		_apply_atlas_coords(atlas_coords)
	# If sprite doesn't exist yet, coords will be applied in _setup_sprite

func _apply_atlas_coords(atlas_coords: Vector2i) -> void:
	if not sprite:
		return
	var tile_size := GameManager.TILE_SIZE
	sprite.region_rect = Rect2(
		atlas_coords.x * tile_size,
		atlas_coords.y * tile_size,
		tile_size,
		tile_size
	)

func _update_visual_position() -> void:
	position = Vector2(grid_position) * GameManager.TILE_SIZE

func get_world_position() -> Vector2:
	return position + Vector2(GameManager.TILE_SIZE / 2, GameManager.TILE_SIZE / 2)

# ============================================================================
# MOVEMENT
# ============================================================================

func try_move(direction: Vector2i) -> bool:
	var target_pos := grid_position + direction
	if can_move_to(target_pos):
		move_to(target_pos)
		return true
	return false

func can_move_to(target: Vector2i) -> bool:
	# Override in subclass to check terrain, entities, etc.
	return true

func move_to(target: Vector2i, animate: bool = true) -> void:
	var old_pos := grid_position
	grid_position = target

	if animate:
		_animate_move(old_pos, target)

	EventBus.entity_moved.emit(self, old_pos, target)

	# Check for tile effects (traps, etc.)
	if GameManager.current_level and GameManager.current_level.has_method("on_entity_step"):
		GameManager.current_level.on_entity_step(self, target)

func teleport_to(target: Vector2i) -> void:
	var old_pos := grid_position
	grid_position = target
	EventBus.entity_teleported.emit(self, old_pos, target)

func _animate_move(from: Vector2i, to: Vector2i) -> void:
	var start_pos := Vector2(from) * GameManager.TILE_SIZE
	var end_pos := Vector2(to) * GameManager.TILE_SIZE
	position = start_pos

	var tween := create_tween()
	# DO NOT EDIT: Movement tween for smooth tile transitions
	tween.tween_property(self, "position", end_pos, 0.01).set_ease(Tween.EASE_OUT)

# ============================================================================
# COMBAT
# ============================================================================

func take_damage(amount: int, damage_type: String = "physical", source: Entity = null) -> void:
	if not is_alive:
		return

	var actual_damage := _calculate_damage_reduction(amount, damage_type)
	current_health -= actual_damage

	EventBus.entity_damaged.emit(self, actual_damage, damage_type, source)
	damaged.emit(actual_damage, source)

	# Flash red on damage
	_flash_damage()

	if current_health <= 0:
		die(source)

func _calculate_damage_reduction(base_damage: int, _damage_type: String) -> int:
	# Roll protection dice for damage reduction (Sil-Q system)
	var prot: int = roll_protection()
	var final_damage: int = max(0, base_damage - prot)
	if protection_dice > 0 and prot > 0:
		# Show player-friendly message when armor absorbs damage
		if self is Player:
			GameManager.log_message("Your armor absorbs %d damage (rolled %dd%d)." % [
				prot, protection_dice, protection_sides
			], ThemeColors.SECONDARY)
		else:
			GameManager.log_message("%s's armor absorbs %d damage." % [
				entity_name, prot
			], ThemeColors.MSG_SYSTEM)
	return final_damage

func roll_protection(_damage_type: int = 1) -> int:
	# Roll protection dice for damage reduction
	if protection_dice <= 0 or protection_sides <= 0:
		return 0
	var total: int = 0
	for i in range(protection_dice):
		total += randi_range(1, protection_sides)
	return total

func _flash_damage() -> void:
	if not sprite:
		return
	var original_modulate := sprite.modulate
	# Phase 1: White-hot overexpose (0.05s)
	sprite.modulate = ThemeColors.FLASH_WHITE_HOT
	var tween := create_tween()
	# Phase 2: Red hold + fade back (0.15s)
	tween.tween_property(sprite, "modulate", ThemeColors.FLASH_RED_HOLD, 0.05)
	tween.tween_property(sprite, "modulate", original_modulate, 0.15)

func heal(amount: int, source: Entity = null) -> void:
	var old_health := current_health
	current_health = min(current_health + amount, max_health)
	var actual_heal := current_health - old_health

	if actual_heal > 0:
		EventBus.entity_healed.emit(self, actual_heal, source)

func die(killer: Entity = null) -> void:
	is_alive = false
	EventBus.entity_died.emit(self, killer)
	died.emit(killer)
	_play_death_animation()

func _play_death_animation() -> void:
	# Determine if this is a significant kill (unique/boss)
	var is_boss: bool = false
	if self is Monster:
		var mon: Monster = self as Monster
		is_boss = mon.is_unique or mon.is_dragon

	# Brief white flash before fade
	if sprite:
		if is_boss:
			sprite.modulate = Color(3.0, 2.5, 1.0)  # Gold flash for bosses
		else:
			sprite.modulate = Color(2.0, 2.0, 2.0)

	# Spawn burst particles (more for bosses)
	var particle_count: int = 15 if is_boss else 10
	_spawn_death_particles(particle_count, is_boss)

	# Fade out and free
	var tween := create_tween()
	if sprite:
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.05)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

func _spawn_death_particles(count: int = 10, is_boss: bool = false) -> void:
	var color: Color = ThemeColors.DMG_CRIT if is_boss else ThemeColors.DMG_PHYSICAL
	var spread: float = 50.0 if is_boss else 35.0
	for i in range(count):
		var particle := Node2D.new()
		var dot := ColorRect.new()
		var dot_size: float = 5.0 if is_boss else 4.0
		dot.size = Vector2(dot_size, dot_size)
		dot.position = Vector2(-dot_size / 2, -dot_size / 2)
		dot.color = color
		particle.add_child(dot)
		particle.position = Vector2(GameManager.TILE_SIZE / 2, GameManager.TILE_SIZE / 2)
		add_child(particle)
		# Burst outward with random angle
		var angle: float = TAU * i / float(count) + randf_range(-0.3, 0.3)
		var target_pos: Vector2 = particle.position + Vector2.from_angle(angle) * randf_range(spread * 0.5, spread)
		var duration: float = 0.5 if is_boss else 0.4
		var ptween := create_tween()
		ptween.set_parallel(true)
		ptween.tween_property(particle, "position", target_pos, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		ptween.tween_property(dot, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
		ptween.chain().tween_callback(particle.queue_free)

# ============================================================================
# VFX HELPERS (shared by Player for ability effects)
# ============================================================================

## Flash the sprite a specific color, then fade back to original.
func vfx_flash(flash_color: Color, hold_time: float = 0.05, fade_time: float = 0.15) -> void:
	if not sprite:
		return
	var orig := sprite.modulate
	sprite.modulate = flash_color
	var t := create_tween()
	t.tween_interval(hold_time)
	t.tween_property(sprite, "modulate", orig, fade_time)

## Spawn burst particles of a given color outward from this entity.
func vfx_particles(color: Color, count: int = 5, spread: float = 30.0, duration: float = 0.4) -> void:
	for i in range(count):
		var particle := Node2D.new()
		var dot := ColorRect.new()
		dot.size = Vector2(3, 3)
		dot.position = Vector2(-1.5, -1.5)
		dot.color = color
		particle.add_child(dot)
		particle.position = Vector2(GameManager.TILE_SIZE / 2, GameManager.TILE_SIZE / 2)
		add_child(particle)
		var angle: float = TAU * i / float(count) + randf_range(-0.4, 0.4)
		var target_pos: Vector2 = particle.position + Vector2.from_angle(angle) * randf_range(spread * 0.6, spread)
		var pt := create_tween()
		pt.set_parallel(true)
		pt.tween_property(particle, "position", target_pos, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		pt.tween_property(dot, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
		pt.chain().tween_callback(particle.queue_free)

## Spawn directional particles (e.g., dripping down, rising up).
## direction: normalized Vector2 for particle travel direction.
func vfx_particles_directional(color: Color, direction: Vector2, count: int = 3, spread_angle: float = 0.4, distance: float = 20.0, duration: float = 0.4) -> void:
	var base_angle: float = direction.angle()
	for i in range(count):
		var particle := Node2D.new()
		var dot := ColorRect.new()
		dot.size = Vector2(3, 3)
		dot.position = Vector2(-1.5, -1.5)
		dot.color = color
		particle.add_child(dot)
		particle.position = Vector2(GameManager.TILE_SIZE / 2, GameManager.TILE_SIZE / 2)
		add_child(particle)
		var angle: float = base_angle + randf_range(-spread_angle, spread_angle)
		var dist: float = randf_range(distance * 0.6, distance)
		var target_pos: Vector2 = particle.position + Vector2.from_angle(angle) * dist
		var pt := create_tween()
		pt.set_parallel(true)
		pt.tween_property(particle, "position", target_pos, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		pt.tween_property(dot, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
		pt.chain().tween_callback(particle.queue_free)

## Brief horizontal dodge animation - shift right then snap back.
func vfx_dodge(offset_px: float = 2.0, duration: float = 0.15) -> void:
	if not sprite:
		return
	var orig_pos: Vector2 = sprite.position
	var shifted: Vector2 = orig_pos + Vector2(offset_px, 0)
	var t := create_tween()
	t.tween_property(sprite, "position", shifted, duration * 0.4).set_ease(Tween.EASE_OUT)
	t.tween_property(sprite, "position", orig_pos, duration * 0.6).set_ease(Tween.EASE_IN)

## Spawn ring of particles above the entity (for stun stars effect).
func vfx_ring_particles(color: Color, count: int = 5, radius: float = 10.0, duration: float = 0.6) -> void:
	var center: Vector2 = Vector2(GameManager.TILE_SIZE / 2, GameManager.TILE_SIZE / 2 - 12)
	for i in range(count):
		var particle := Node2D.new()
		var dot := ColorRect.new()
		dot.size = Vector2(2, 2)
		dot.position = Vector2(-1, -1)
		dot.color = color
		particle.add_child(dot)
		var angle: float = TAU * i / float(count)
		particle.position = center + Vector2.from_angle(angle) * radius
		add_child(particle)
		# Orbit animation: rotate around center
		var end_angle: float = angle + TAU * 0.75
		var end_pos: Vector2 = center + Vector2.from_angle(end_angle) * radius
		var pt := create_tween()
		pt.set_parallel(true)
		pt.tween_property(particle, "position", end_pos, duration).set_ease(Tween.EASE_IN_OUT)
		pt.tween_property(dot, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN).set_delay(duration * 0.5)
		pt.chain().tween_callback(particle.queue_free)

## Spawn a floating text label at this entity's position.
func vfx_floater(text: String, color: Color, size: int = 16) -> void:
	if not GameManager.current_level:
		return
	var effects_node: Node = GameManager.current_level.get_node_or_null("Effects")
	if not effects_node:
		return
	DamageFloater.create_at(effects_node, get_world_position() + Vector2(0, -12), text, color, size)

# ============================================================================
# STATUS EFFECTS
# ============================================================================

func apply_status(status_name: String, duration: int, _data: Variant = null) -> void:
	# Delegate to new StatusEffects system
	var effect_id: StringName = StringName(status_name)
	status_fx.apply_effect(effect_id, duration)
	# Status VFX: brief tint
	if sprite:
		var status_color: Color = ThemeColors.get_status_color(status_name)
		var orig := sprite.modulate
		sprite.modulate = Color(status_color, 1.0)
		var vfx_tween := create_tween()
		vfx_tween.tween_property(sprite, "modulate", orig, 0.3)
	# Sync legacy dict for backwards compatibility (HUD reads this)
	_sync_status_dict()

func remove_status(status_name: String) -> void:
	var effect_id: StringName = StringName(status_name)
	status_fx.remove_effect(effect_id)
	_sync_status_dict()

func has_status(status_name: String) -> bool:
	return status_fx.has_effect(StringName(status_name))

func tick_status_effects() -> void:
	status_fx.tick_effects()
	_sync_status_dict()

func _sync_status_dict() -> void:
	# Keep legacy status_effects dict in sync for HUD and other readers
	status_effects.clear()
	for effect_id: StringName in status_fx.effects:
		status_effects[String(effect_id)] = {"duration": status_fx.effects[effect_id], "data": null}

# ============================================================================
# ATTACK
# ============================================================================

func attack_entity(target: Entity) -> void:
	# Sil-Q Opposed Roll Combat with full modifier stacks
	var att: int = get_total_attack(target)
	var evn: int = target.get_total_evasion(self)

	var attack_score: int = randi_range(1, 20) + att
	var evasion_score: int = randi_range(1, 20) + evn
	var hit_result: int = attack_score - evasion_score

	if hit_result < 0:
		EventBus.attack_missed.emit(self, target)
		GameManager.log_message("%s misses %s (%d vs %d)" % [
			entity_name, target.entity_name, attack_score, evasion_score
		], ThemeColors.COMBAT_MISS)
		return

	# Base damage from weapon dice
	var weapon_weight: int = _get_weapon_weight()
	var dmg_dice: String = _get_attack_damage_dice()
	var damage: int = DataManager.roll_dice(dmg_dice)

	# STR damage bonus capped by weapon weight
	var str_bonus: int = strength / 2
	var weight_cap: int = weapon_weight / 10
	var actual_str_bonus: int = mini(str_bonus, weight_cap)
	damage += actual_str_bonus

	# Critical hit calculation: (hit_result * 10 + 4) / (threshold + weight)
	var crit_threshold: int = _get_crit_threshold()
	var crit_dice: int = (hit_result * 10 + 4) / (crit_threshold + weapon_weight)

	# Check target crit resistance
	crit_dice = _apply_crit_resistance(target, crit_dice)

	# Apply crit bonus dice
	var crit_damage: int = 0
	for i in range(crit_dice):
		crit_damage += DataManager.roll_dice(dmg_dice)
	damage += crit_damage

	# Bonus damage dice from abilities (e.g., Power)
	var bonus_dice: int = _get_bonus_damage_dice()
	for i in range(bonus_dice):
		damage += DataManager.roll_dice(dmg_dice)

	# Log the hit
	if crit_dice > 0:
		GameManager.log_message("%s CRITS %s! (%d vs %d, +%d dice = %d dmg)" % [
			entity_name, target.entity_name, attack_score, evasion_score, crit_dice, damage
		], ThemeColors.COMBAT_CRIT)
		EventBus.critical_hit.emit(self, target, damage)
	else:
		GameManager.log_message("%s hits %s (%d vs %d = %d dmg)" % [
			entity_name, target.entity_name, attack_score, evasion_score, damage
		], ThemeColors.COMBAT_HIT)

	# Apply difficulty-based monster damage modifier (monster attacking player only)
	if self is Monster and target is Player and GameManager:
		var dmg_mult: float = GameManager.get_monster_damage_multiplier()
		if dmg_mult != 1.0:
			damage = maxi(1, int(damage * dmg_mult))

	target.take_damage(damage, "physical", self)

	# Resolve attack effects (e.g., monster special attacks: FIRE, COLD, BLIND, etc.)
	_on_successful_hit(target, hit_result, damage)

# ============================================================================
# COMBAT MODIFIERS (virtual - override in Player/Monster)
# ============================================================================

## Calculate total attack bonus vs a specific target. Override in subclasses.
func get_total_attack(target: Entity) -> int:
	var att: int = melee_bonus
	# Blind attacker: halve attack
	if status_fx and status_fx.is_blind():
		att = att / 2
	return att

## Calculate total evasion bonus vs a specific attacker. Override in subclasses.
func get_total_evasion(attacker: Entity) -> int:
	var evn: int = evasion_bonus
	# Blind defender: halve evasion
	if status_fx and status_fx.is_blind():
		evn = evn / 2
	return evn

## Get the damage dice for this attack. Override for weapon-based attacks.
func _get_attack_damage_dice() -> String:
	return damage_dice

## Get critical hit threshold. Override for ability modifiers.
func _get_crit_threshold() -> int:
	return 70

## Get bonus damage dice from abilities. Override in Player.
func _get_bonus_damage_dice() -> int:
	return 0

## Apply target's crit resistance (RES_CRIT halves, NO_CRIT zeroes).
func _apply_crit_resistance(target: Entity, crit_dice_count: int) -> int:
	if is_instance_valid(target) and target is Monster:
		var mon: Monster = target as Monster
		if mon.monster_data:
			if mon.monster_data.has_flag("NO_CRIT"):
				return 0
			if mon.monster_data.has_flag("RES_CRIT"):
				return crit_dice_count / 2
	return crit_dice_count

## Called after a successful hit. Override in Monster for attack effects.
func _on_successful_hit(_target: Entity, _hit_result: int, _damage: int) -> void:
	pass

func _get_weapon_weight() -> int:
	# Override in Player to get actual weapon weight
	# Default weight for monsters/unarmed
	return 50

# ============================================================================
# RANGED COMBAT
# ============================================================================

## Perform a ranged attack against a target entity
func ranged_attack(target: Entity, distance: int) -> void:
	# Sil-Q ranged combat: evasion halved at range, distance penalty
	var att: int = get_total_attack(target)
	# Distance penalty: -1 per tile beyond 1
	att -= maxi(0, distance - 1)

	# Ranged evasion is halved
	var evn: int = target.get_total_evasion(self) / 2

	var attack_score: int = randi_range(1, 20) + att
	var evasion_score: int = randi_range(1, 20) + evn

	var hit_result: int = attack_score - evasion_score

	if hit_result < 0:
		EventBus.attack_missed.emit(self, target)
		GameManager.log_message("%s's shot misses %s (%d vs %d)" % [
			entity_name, target.entity_name, attack_score, evasion_score
		], ThemeColors.COMBAT_MISS)
		return

	# Damage from arrow/bolt
	var dmg_dice: String = _get_ranged_damage_dice()
	var damage: int = DataManager.roll_dice(dmg_dice)

	# STR bonus (capped by bow weight)
	var bow_weight: int = _get_bow_weight()
	var str_bonus: int = strength / 2
	var weight_cap: int = bow_weight / 10
	damage += mini(str_bonus, weight_cap)

	# Critical hit
	var crit_threshold: int = _get_crit_threshold()
	var crit_dice: int = (hit_result * 10 + 4) / (crit_threshold + bow_weight)
	crit_dice = _apply_crit_resistance(target, crit_dice)

	var crit_damage: int = 0
	for i in range(crit_dice):
		crit_damage += DataManager.roll_dice(dmg_dice)
	damage += crit_damage

	if crit_dice > 0:
		GameManager.log_message("%s CRITS %s with a shot! (%d vs %d, +%d dice = %d dmg)" % [
			entity_name, target.entity_name, attack_score, evasion_score, crit_dice, damage
		], ThemeColors.COMBAT_CRIT)
	else:
		GameManager.log_message("%s hits %s with a shot (%d vs %d = %d dmg)" % [
			entity_name, target.entity_name, attack_score, evasion_score, damage
		], ThemeColors.COMBAT_HIT)

	target.take_damage(damage, "physical", self)

## Override in Player for equipped bow damage
func _get_ranged_damage_dice() -> String:
	return "1d5"  # Default arrow damage

## Override in Player for bow weight
func _get_bow_weight() -> int:
	return 30

# ============================================================================
# ENERGY SYSTEM
# ============================================================================

func get_energy_gain() -> int:
	# Get energy gain based on speed (uses Constants.ENERGY_TABLE)
	# SLOW/FAST status effects shift the speed index
	var speed_mod: int = 0
	if status_fx:
		speed_mod = status_fx.get_speed_modifier()
	var speed_index: int = clampi(speed + speed_mod, 0, Constants.ENERGY_TABLE.size() - 1)
	return Constants.ENERGY_TABLE[speed_index]

func can_act() -> bool:
	return energy >= Constants.ACTION_COST and is_alive

## Check if entity can take a turn (not incapacitated by status effects).
## STUNNED (knockout level) and ENTRANCED prevent action.
func can_take_turn() -> bool:
	if status_fx and status_fx.is_incapacitated():
		return false
	return true

func consume_energy(amount: int = Constants.ACTION_COST) -> void:
	energy -= amount

func grant_energy() -> void:
	energy += get_energy_gain()

# ============================================================================
# INFO
# ============================================================================

func get_stat_block() -> String:
	return "%s\nHP: %d/%d\nSTR: %d DEX: %d CON: %d GRA: %d\nAC: %d" % [
		entity_name, current_health, max_health,
		strength, dexterity, constitution, grace, armor_class
	]
