extends Node
## AudioManager singleton - handles music, SFX, and UI audio with crossfade and combat detection.

# Audio bus indices
var music_bus_idx: int = -1
var sfx_bus_idx: int = -1
var ui_bus_idx: int = -1

# Music players for crossfade
var music_player_a: AudioStreamPlayer = null
var music_player_b: AudioStreamPlayer = null
var active_music_player: AudioStreamPlayer = null
var inactive_music_player: AudioStreamPlayer = null

# SFX pool (round-robin)
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_index: int = 0
const SFX_POOL_SIZE: int = 12

# UI pool (round-robin)
var ui_players: Array[AudioStreamPlayer] = []
var ui_index: int = 0
const UI_POOL_SIZE: int = 4

# Combat state
var in_combat: bool = false
var combat_timer: float = 0.0
const COMBAT_COOLDOWN: float = 5.0

# Crossfade
const CROSSFADE_DURATION: float = 2.0

# Track loading
var music_tracks: Dictionary = {}  # name -> AudioStream
var sfx_sounds: Dictionary = {}    # name -> AudioStream
var current_track_name: String = ""

# Volume settings (linear 0.0 - 1.0)
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 1.0
var ui_volume: float = 0.8

# Music track file mapping
const MUSIC_FILES: Dictionary = {
	"main_theme": "res://assets/audio/music/01_main_theme.mp3",
	"mirkwood": "res://assets/audio/music/02_mirkwood.mp3",
	"orc_warrens": "res://assets/audio/music/03_orc_warrens.mp3",
	"necropolis": "res://assets/audio/music/04_necropolis.mp3",
	"wraith_domain": "res://assets/audio/music/05_wraith_domain.mp3",
	"the_pit": "res://assets/audio/music/06_the_pit.mp3",
	"eye_awakens": "res://assets/audio/music/07_eye_awakens.mp3",
	"pursuit": "res://assets/audio/music/08_pursuit.mp3",
	"victory": "res://assets/audio/music/09_victory.mp3",
	"death": "res://assets/audio/music/10_death.mp3",
}

# SFX file mapping
const SFX_FILES: Dictionary = {
	"hit": "res://assets/audio/sfx/hit.wav",
	"hit1": "res://assets/audio/sfx/hit1.wav",
	"dmg_poison": "res://third_party_assets/sfx/kenney_rpg_audio/Audio/clothBelt.ogg",
	"dmg_cold": "res://third_party_assets/sfx/kenney_rpg_audio/Audio/creak1.ogg",
	"dmg_fire": "res://assets/audio/sfx/destroy.wav",
	"dmg_dark": "res://third_party_assets/sfx/kenney_rpg_audio/Audio/creak3.ogg",
	"miss": "res://assets/audio/sfx/miss.wav",
	"miss1": "res://assets/audio/sfx/miss1.wav",
	"kill": "res://assets/audio/sfx/kill.wav",
	"kill1": "res://assets/audio/sfx/kill1.wav",
	"death": "res://assets/audio/sfx/death.wav",
	"eat": "res://assets/audio/sfx/eat.wav",
	"drop": "res://assets/audio/sfx/drop.wav",
	"level": "res://assets/audio/sfx/level.wav",
	"opendoor": "res://assets/audio/sfx/opendoor.wav",
	"shutdoor": "res://assets/audio/sfx/shutdoor.wav",
	"clunk": "res://assets/audio/sfx/clunk.wav",
	"money": "res://assets/audio/sfx/money.wav",
	"destroy": "res://assets/audio/sfx/destroy.wav",
	"thump": "res://assets/audio/sfx/thump.wav",
	"flee": "res://assets/audio/sfx/flee.wav",
	"breath": "res://assets/audio/sfx/breath.wav",
	"terrain_water_step": "res://third_party_assets/sfx/kenney_rpg_audio/Audio/footstep08.ogg",
	"terrain_vine_step": "res://third_party_assets/sfx/kenney_rpg_audio/Audio/footstep03.ogg",
	"terrain_web_step": "res://third_party_assets/sfx/kenney_rpg_audio/Audio/cloth2.ogg",
	"terrain_poison_stream_step": "res://third_party_assets/sfx/kenney_rpg_audio/Audio/clothBelt2.ogg",
	"terrain_dark_pool_step": "res://third_party_assets/sfx/kenney_rpg_audio/Audio/creak2.ogg",
	"terrain_morgul_rune_step": "res://third_party_assets/sfx/kenney_rpg_audio/Audio/creak3.ogg",
	"terrain_shadow_floor_bite": "res://third_party_assets/sfx/kenney_rpg_audio/Audio/creak3.ogg",
}

# Settings file
const SETTINGS_PATH: String = "user://audio_settings.cfg"

func _ready() -> void:
	_setup_audio_buses()
	_spawn_player_pools()
	_preload_audio()
	load_settings()
	_connect_signals()

func _setup_audio_buses() -> void:
	# Add Music bus if it doesn't exist
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
		AudioServer.set_bus_send(AudioServer.get_bus_index("Music"), "Master")

	# Add SFX bus if it doesn't exist
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
		AudioServer.set_bus_send(AudioServer.get_bus_index("SFX"), "Master")

	# Add UI bus if it doesn't exist
	if AudioServer.get_bus_index("UI") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "UI")
		AudioServer.set_bus_send(AudioServer.get_bus_index("UI"), "Master")

	music_bus_idx = AudioServer.get_bus_index("Music")
	sfx_bus_idx = AudioServer.get_bus_index("SFX")
	ui_bus_idx = AudioServer.get_bus_index("UI")

	# Apply initial volumes
	_apply_bus_volume("Master", master_volume)
	_apply_bus_volume("Music", music_volume)
	_apply_bus_volume("SFX", sfx_volume)
	_apply_bus_volume("UI", ui_volume)

func _spawn_player_pools() -> void:
	# Music players (2 for crossfade)
	music_player_a = AudioStreamPlayer.new()
	music_player_a.name = "MusicPlayerA"
	music_player_a.bus = "Music"
	add_child(music_player_a)
	music_player_a.finished.connect(_on_music_player_finished.bind(music_player_a))

	music_player_b = AudioStreamPlayer.new()
	music_player_b.name = "MusicPlayerB"
	music_player_b.bus = "Music"
	add_child(music_player_b)
	music_player_b.finished.connect(_on_music_player_finished.bind(music_player_b))

	active_music_player = music_player_a
	inactive_music_player = music_player_b

	# SFX pool
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

	# UI pool
	for i in range(UI_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "UIPlayer_%d" % i
		player.bus = "UI"
		add_child(player)
		ui_players.append(player)

func _preload_audio() -> void:
	# Load music tracks
	for track_name in MUSIC_FILES:
		var path: String = MUSIC_FILES[track_name]
		var stream: AudioStream = _load_audio_stream(path)
		if stream:
			# Exploration themes should loop continuously while the player remains in the layer.
			if stream is AudioStreamMP3:
				(stream as AudioStreamMP3).loop = true
			elif stream is AudioStreamOggVorbis:
				(stream as AudioStreamOggVorbis).loop = true
			elif stream is AudioStreamWAV:
				(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
			music_tracks[track_name] = stream
		else:
			push_warning("AudioManager: Music file not found: %s" % path)

	# Load SFX
	for sfx_name in SFX_FILES:
		var path: String = SFX_FILES[sfx_name]
		var stream: AudioStream = _load_audio_stream(path)
		if stream:
			sfx_sounds[sfx_name] = stream
		else:
			push_warning("AudioManager: SFX file not found: %s" % path)

func _load_audio_stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var loaded := load(path)
		if loaded is AudioStream:
			return loaded as AudioStream
	var rel_path := path.trim_prefix("res://")
	if FileAccess.file_exists(rel_path):
		if path.to_lower().ends_with(".ogg"):
			return AudioStreamOggVorbis.load_from_file(path)
	return null

func _connect_signals() -> void:
	if not EventBus:
		return

	EventBus.entity_damaged.connect(_on_entity_damaged)
	EventBus.entity_died.connect(_on_entity_died)
	EventBus.attack_missed.connect(_on_attack_missed)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.item_dropped.connect(_on_item_dropped)
	EventBus.item_equipped.connect(_on_item_equipped)
	EventBus.item_used.connect(_on_item_used)
	EventBus.level_entered.connect(_on_level_entered)

# ============================================================================
# MUSIC PLAYBACK
# ============================================================================

func play_music(track_name: String) -> void:
	if track_name == current_track_name:
		return  # Already playing this track

	if track_name not in music_tracks:
		push_warning("AudioManager: Unknown music track '%s'" % track_name)
		return

	var stream: AudioStream = music_tracks[track_name]
	current_track_name = track_name
	_crossfade_music(stream)

func stop_music() -> void:
	current_track_name = ""
	if active_music_player and active_music_player.playing:
		var tween := create_tween()
		tween.tween_property(active_music_player, "volume_db", -80.0, CROSSFADE_DURATION)
		tween.tween_callback(active_music_player.stop)

func _crossfade_music(stream: AudioStream) -> void:
	# Swap active/inactive players
	var old_player: AudioStreamPlayer = active_music_player
	var new_player: AudioStreamPlayer = inactive_music_player
	active_music_player = new_player
	inactive_music_player = old_player

	# Set up new player
	new_player.stream = stream
	new_player.volume_db = -80.0
	new_player.play()

	# Crossfade tween
	var tween := create_tween()
	tween.set_parallel(true)

	# Fade in new player
	tween.tween_property(new_player, "volume_db", 0.0, CROSSFADE_DURATION)

	# Fade out old player (if playing)
	if old_player.playing:
		tween.tween_property(old_player, "volume_db", -80.0, CROSSFADE_DURATION)

	tween.set_parallel(false)
	tween.tween_callback(func() -> void:
		if old_player.playing and old_player != active_music_player:
			old_player.stop()
	)

func _get_exploration_track() -> String:
	var depth: int = GameManager.current_depth if GameManager else 1
	var layer_name: String = LayerConfig.get_layer_name(depth)
	match layer_name:
		"outer_pits":
			return "mirkwood"
		"lower_halls":
			return "orc_warrens"
		"dark_halls":
			return "wraith_domain"
		"necropolis":
			return "necropolis"
		"pits_of_despair":
			return "the_pit"
		"inner_sanctum", "throne_room":
			return "eye_awakens"
		_:
			return "mirkwood"

# ============================================================================
# SFX PLAYBACK
# ============================================================================

func play_sfx(sound_name: String) -> void:
	if sound_name not in sfx_sounds:
		return

	var player: AudioStreamPlayer = sfx_players[sfx_index]
	sfx_index = (sfx_index + 1) % SFX_POOL_SIZE

	player.stream = sfx_sounds[sound_name]
	player.play()

func play_ui_sound(sound_name: String) -> void:
	if sound_name not in sfx_sounds:
		return

	var player: AudioStreamPlayer = ui_players[ui_index]
	ui_index = (ui_index + 1) % UI_POOL_SIZE

	player.stream = sfx_sounds[sound_name]
	player.play()

# ============================================================================
# VOLUME CONTROL
# ============================================================================

func set_volume(bus_name: String, linear: float) -> void:
	linear = clampf(linear, 0.0, 1.0)

	match bus_name:
		"Master":
			master_volume = linear
		"Music":
			music_volume = linear
		"SFX":
			sfx_volume = linear
		"UI":
			ui_volume = linear

	_apply_bus_volume(bus_name, linear)
	save_settings()

func _apply_bus_volume(bus_name: String, linear: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return

	if linear <= 0.0:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear))

func get_volume(bus_name: String) -> float:
	match bus_name:
		"Master":
			return master_volume
		"Music":
			return music_volume
		"SFX":
			return sfx_volume
		"UI":
			return ui_volume
	return 1.0

# ============================================================================
# COMBAT STATE MACHINE
# ============================================================================

func _process(delta: float) -> void:
	if in_combat:
		combat_timer -= delta
		if combat_timer <= 0.0:
			in_combat = false
			combat_timer = 0.0
			# Return to exploration music
			var exploration_track: String = _get_exploration_track()
			if current_track_name == "pursuit":
				play_music(exploration_track)

func _start_combat_music() -> void:
	return  # Combat music disabled — kept for future reuse
	if not in_combat:
		in_combat = true
		play_music("pursuit")
	# Reset cooldown on every combat event
	combat_timer = COMBAT_COOLDOWN

# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_entity_damaged(entity: Node, _damage: int, damage_type: String, source: Node) -> void:
	# Reduce noisy offscreen spam: play impact SFX only when player involved or target is visible.
	if not (_is_player(entity) or _is_player(source) or _is_entity_visible(entity)):
		return
	match damage_type:
		"poison":
			play_sfx("dmg_poison")
		"cold":
			play_sfx("dmg_cold")
		"fire":
			play_sfx("dmg_fire")
		"dark":
			# Terrain dark damage (source == null) has dedicated tile SFX in level.gd.
			if source != null:
				play_sfx("dmg_dark")
		_:
			# Keep the metallic clang; disable the voice-like impact variant.
			play_sfx("hit")

	# Start combat music if player is involved
	if _is_player(entity) or _is_player(source):
		_start_combat_music()

func _on_entity_died(entity: Node, _killer: Node) -> void:
	if _is_player(entity):
		play_sfx("death")
	else:
		play_sfx(["kill", "kill1"].pick_random())

func _on_attack_missed(_attacker: Node, _defender: Node) -> void:
	play_sfx(["miss", "miss1"].pick_random())

func _on_item_picked_up(_entity: Node, _item: Variant) -> void:
	play_ui_sound("clunk")

func _on_item_dropped(_entity: Node, _item: Variant, _position: Vector2i) -> void:
	play_ui_sound("drop")

func _on_item_equipped(_entity: Node, _item: Variant, _slot: String) -> void:
	play_ui_sound("clunk")

func _on_item_used(_entity: Node, _item: Variant) -> void:
	play_ui_sound("eat")

func _on_level_entered(depth: int) -> void:
	play_sfx("level")
	# Switch to exploration music for this depth (unless in combat)
	if not in_combat:
		play_music(_get_exploration_track())

func _on_music_player_finished(player_node: AudioStreamPlayer) -> void:
	# Safety net for imports/streams that don't honor loop flags.
	if in_combat:
		return
	if player_node != active_music_player:
		return
	if current_track_name.is_empty():
		return
	if current_track_name in music_tracks:
		player_node.stream = music_tracks[current_track_name]
		player_node.play()

func _is_player(node: Node) -> bool:
	if not is_instance_valid(node):
		return false
	return node is Player

func _is_entity_visible(node: Node) -> bool:
	if not is_instance_valid(node):
		return false
	if not GameManager or not GameManager.current_level:
		return false
	if node is Entity:
		return GameManager.current_level.is_tile_visible(node.grid_position)
	return false

# ============================================================================
# SETTINGS PERSISTENCE
# ============================================================================

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "ui_volume", ui_volume)
	config.save(SETTINGS_PATH)

func load_settings() -> void:
	var config := ConfigFile.new()
	var err: int = config.load(SETTINGS_PATH)
	if err != OK:
		return  # No saved settings, use defaults

	master_volume = config.get_value("audio", "master_volume", 1.0)
	music_volume = config.get_value("audio", "music_volume", 0.7)
	sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
	ui_volume = config.get_value("audio", "ui_volume", 0.8)

	# Apply loaded volumes
	_apply_bus_volume("Master", master_volume)
	_apply_bus_volume("Music", music_volume)
	_apply_bus_volume("SFX", sfx_volume)
	_apply_bus_volume("UI", ui_volume)
