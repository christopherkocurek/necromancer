extends CanvasLayer
## Rich tooltip system. Shows contextual tooltips on hover/focus.

var _tooltip_panel: PanelContainer
var _tooltip_label: RichTextLabel
var _show_timer: Timer
var _current_trigger: Control = null
var _is_visible: bool = false

func _ready() -> void:
	layer = 20
	_setup_tooltip()
	_setup_timer()

func _setup_tooltip() -> void:
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.visible = false
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBox
	if ThemeColors.has_textures():
		style = ThemeColors.create_textured_panel("panel_parchment", 6.0)
	else:
		style = ThemeColors.create_panel_stylebox(ThemeColors.PARCHMENT_BG, ThemeColors.PARCHMENT_EDGE, 1, 6)
	_tooltip_panel.add_theme_stylebox_override("panel", style)

	_tooltip_label = RichTextLabel.new()
	_tooltip_label.bbcode_enabled = true
	_tooltip_label.fit_content = true
	_tooltip_label.custom_minimum_size = Vector2(280, 0)
	_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_label.add_theme_color_override("default_color", ThemeColors.PARCHMENT_TEXT)
	_tooltip_label.add_theme_font_size_override("normal_font_size", ThemeColors.FONT_SIZE_BODY)
	ThemeColors.apply_rich_body_font(_tooltip_label)
	_tooltip_label.add_theme_color_override("default_color", ThemeColors.PARCHMENT_TEXT)
	_tooltip_panel.add_child(_tooltip_label)
	add_child(_tooltip_panel)

func _setup_timer() -> void:
	_show_timer = Timer.new()
	_show_timer.one_shot = true
	_show_timer.timeout.connect(_show_tooltip)
	add_child(_show_timer)

func show_rich_tooltip(text: String, global_pos: Vector2, delay: float = 0.4) -> void:
	_tooltip_label.text = text
	_tooltip_panel.position = _clamp_position(global_pos + Vector2(16, 16))
	_show_timer.start(delay)

func hide_tooltip() -> void:
	_show_timer.stop()
	_tooltip_panel.visible = false
	_is_visible = false
	_current_trigger = null

func _show_tooltip() -> void:
	_tooltip_panel.visible = true
	_is_visible = true

func _clamp_position(pos: Vector2) -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	var tooltip_size := _tooltip_panel.size
	pos.x = minf(pos.x, viewport_size.x - tooltip_size.x - 10)
	pos.y = minf(pos.y, viewport_size.y - tooltip_size.y - 10)
	pos.x = maxf(pos.x, 10)
	pos.y = maxf(pos.y, 10)
	return pos

# Flag -> natural language descriptions for item tooltips
const FLAG_DESCRIPTIONS: Dictionary = {
	# Slay flags
	"SLAY_ORC": "Deadly against orcs",
	"SLAY_TROLL": "Deadly against trolls",
	"SLAY_SPIDER": "Deadly against spiders",
	"SLAY_WOLF": "Deadly against wolves",
	"SLAY_UNDEAD": "Deadly against the undead",
	"SLAY_RAUKO": "Deadly against demons",
	"SLAY_DRAGON": "Deadly against dragons",
	"SLAY_MAN_OR_ELF": "Deadly against men and elves",
	# Brand flags
	"BRAND_FIRE": "Burns with fire",
	"BRAND_COLD": "Chill of the grave",
	"BRAND_POIS": "Drips with poison",
	# Defensive flags
	"RES_FIRE": "Resists fire",
	"RES_COLD": "Resists cold",
	"RES_POIS": "Resists poison",
	"RES_FEAR": "Resists fear",
	"RES_BLIND": "Resists blindness",
	"RES_CONFU": "Resists confusion",
	"RES_STUN": "Resists stunning",
	"RES_HALLU": "Resists hallucination",
	"RES_DARK": "Resists darkness",
	"RES_BLEED": "Resists bleeding",
	# Utility flags
	"FREE_ACT": "Prevents paralysis",
	"SEE_INVIS": "Reveals the invisible",
	"REGEN": "Enhances regeneration",
	"LIGHT": "Glows with inner light",
	"RADIANCE": "Radiates bright light",
	"SLOW_DIGEST": "Sustains without food",
	"SUST_STR": "Sustains strength",
	"SUST_DEX": "Sustains dexterity",
	"SUST_CON": "Sustains constitution",
	"SUST_GRA": "Sustains grace",
	"MEDIC": "Enhances healing",
	"CHEAT_DEATH": "Cheats death once",
	"STAND_FAST": "Cannot be knocked back",
	"AVOID_TRAPS": "Avoids floor traps",
	"ACCURATE": "Strikes with precision (+3 attack)",
	"SHARPNESS": "Pierces through armor",
	"VAMPIRIC": "Drains life from foes",
	"IGNORE_ALL": "Immune to acid and fire damage",
	"TUNNEL": "Digs through rock",
	# Negative flags (displayed in red)
	"HUNGER": "Increases hunger",
	"AGGRAVATE": "Enrages nearby creatures",
	"FEAR": "Fills the wearer with dread",
	"DANGER": "Attracts dangerous foes",
	"HAUNTED": "Haunted by spirits",
	"LIGHT_CURSE": "Bears a light curse",
	"DARKNESS": "Shrouds in darkness",
	"CUMBERSOME": "Heavy and cumbersome",
	"VUL_FIRE": "Vulnerable to fire",
	"VUL_COLD": "Vulnerable to cold",
	"VUL_POIS": "Vulnerable to poison",
}

# Stat flags with pval-scaled descriptions (3 tiers)
const STAT_FLAG_DESCRIPTIONS: Dictionary = {
	"STR": ["Slightly strengthens", "Strengthens", "Greatly strengthens"],
	"DEX": ["Slightly quickens", "Quickens", "Greatly quickens"],
	"CON": ["Slightly toughens", "Toughens", "Greatly toughens"],
	"GRA": ["Slightly graces", "Graces", "Greatly graces"],
	"NEG_STR": ["Slightly weakens", "Weakens", "Greatly weakens"],
	"NEG_DEX": ["Slightly slows", "Slows", "Greatly slows"],
	"NEG_CON": ["Slightly saps vitality", "Saps vitality", "Greatly saps vitality"],
	"NEG_GRA": ["Slightly diminishes grace", "Diminishes grace", "Greatly diminishes grace"],
}

# Skill flags with pval-scaled descriptions (2 tiers)
const SKILL_FLAG_DESCRIPTIONS: Dictionary = {
	"STEALTH": ["Muffles footsteps", "Shrouds in silence"],
	"PERCEPTION": ["Sharpens awareness", "Grants keen sight"],
	"WILL": ["Strengthens resolve", "Fortifies the mind"],
	"MELEE": ["Hones fighting skill", "Masters the blade"],
	"ARCHERY": ["Steadies aim", "Grants marksman's eye"],
	"SONG": ["Deepens lore knowledge", "Unlocks ancient wisdom"],
}

# Ability grant descriptions (skill_id/ability_id -> description)
const ABILITY_GRANT_DESCRIPTIONS: Dictionary = {
	"0/2": "Grants Knock Back",
	"0/4": "Grants Charge",
	"0/5": "Grants Follow-Through",
	"0/6": "Grants Opening Strike",
	"0/8": "Grants Whirlwind Attack",
	"0/9": "Grants Zone of Control",
	"0/11": "Grants Two Weapon Fighting",
	"2/2": "Grants Parry",
	"2/4": "Grants Leaping",
	"2/5": "Grants Sprinting",
	"2/6": "Grants Flanking",
	"3/1": "Grants Assassination",
	"3/4": "Grants Opportunist",
	"3/8": "Grants Fade",
	"3/9": "Grants Pilfer",
	"4/7": "Grants Listen",
}

# Flags that should be colored red (negative effects)
const NEGATIVE_FLAGS: Array[String] = [
	"HUNGER", "AGGRAVATE", "FEAR", "DANGER", "HAUNTED", "LIGHT_CURSE",
	"DARKNESS", "CUMBERSOME", "VUL_FIRE", "VUL_COLD", "VUL_POIS",
	"NEG_STR", "NEG_DEX", "NEG_CON", "NEG_GRA",
]

## Format an item tooltip with stats and flag descriptions
static func format_item_tooltip(item: Variant) -> String:
	if item == null:
		return ""
	var display_name: String = GameManager.get_item_display_name(item)
	var text := "[b]%s[/b]\n" % display_name

	# If unidentified, show only flavor name + weight + purple "Unidentified" tag
	if GameManager.needs_identification(item) and not GameManager.is_item_identified(item):
		if "weight" in item:
			text += "[color=#%s]Weight: %.1f lb[/color]\n" % [ThemeColors.TEXT_MUTED.to_html(false), item.weight / 10.0]
		text += "[color=#A855F7]Unidentified[/color]"
		return text

	# Combat stats
	if "attack_bonus" in item and item.attack_bonus != 0:
		text += "[color=#%s]Attack: %+d[/color]\n" % [ThemeColors.COMBAT_HIT.to_html(false), item.attack_bonus]
	if "damage_dice" in item and item.damage_dice != "":
		text += "Damage: %s\n" % item.damage_dice
	if "evasion_bonus" in item and item.evasion_bonus != 0:
		text += "[color=#%s]Evasion: %+d[/color]\n" % [ThemeColors.SECONDARY.to_html(false), item.evasion_bonus]
	if "protection_dice" in item and item.protection_dice != "":
		text += "Protection: %s\n" % item.protection_dice
	if "weight" in item:
		text += "[color=#%s]Weight: %.1f lb[/color]\n" % [ThemeColors.TEXT_MUTED.to_html(false), item.weight / 10.0]

	# Flag descriptions (positive, then negative)
	if "flags" in item and item.flags.size() > 0:
		var positive_descs: Array[String] = []
		var negative_descs: Array[String] = []
		var pval: int = item.pval if "pval" in item else 1

		for flag in item.flags:
			# Stat flags (pval-scaled)
			if flag in STAT_FLAG_DESCRIPTIONS:
				var tier: int = clampi(pval - 1, 0, 2)
				var desc: String = STAT_FLAG_DESCRIPTIONS[flag][tier]
				if flag.begins_with("NEG_"):
					negative_descs.append(desc)
				else:
					positive_descs.append(desc)
			# Skill flags (pval-scaled)
			elif flag in SKILL_FLAG_DESCRIPTIONS:
				var tier: int = clampi(pval - 1, 0, 1)
				var desc: String = SKILL_FLAG_DESCRIPTIONS[flag][tier]
				positive_descs.append(desc)
			# Standard flags
			elif flag in FLAG_DESCRIPTIONS:
				var desc: String = FLAG_DESCRIPTIONS[flag]
				if flag in NEGATIVE_FLAGS:
					negative_descs.append(desc)
				else:
					positive_descs.append(desc)

		if positive_descs.size() > 0:
			text += "\n"
			for desc in positive_descs:
				text += "[color=#%s]%s[/color]\n" % [ThemeColors.TEXT_SECONDARY.to_html(false), desc]

		if negative_descs.size() > 0:
			for desc in negative_descs:
				text += "[color=#%s]%s[/color]\n" % [ThemeColors.HEALTH_LOW.to_html(false), desc]

	# Ability grant descriptions
	if "granted_abilities" in item and item.granted_abilities.size() > 0:
		for ability_ref in item.granted_abilities:
			if ability_ref.size() >= 2:
				var key: String = "%d/%d" % [ability_ref[0], ability_ref[1]]
				if key in ABILITY_GRANT_DESCRIPTIONS:
					text += "[color=#%s]%s[/color]\n" % [ThemeColors.ABILITY_LEARNED.to_html(false), ABILITY_GRANT_DESCRIPTIONS[key]]

	# Description text
	if "description" in item and item.description != "":
		text += "\n[color=#%s]%s[/color]" % [ThemeColors.TEXT_SECONDARY.to_html(false), item.description]

	return text

## Format a status effect tooltip
static func format_status_tooltip(status_name: String, duration: int) -> String:
	var color := ThemeColors.get_status_color(status_name)
	return "[color=#%s][b]%s[/b][/color]\nDuration: %d turns" % [color.to_html(false), status_name.capitalize(), duration]

## Format an ability tooltip
static func format_ability_tooltip(ability: DataManager.AbilityData) -> String:
	var text := "[b]%s[/b]\n" % ability.name
	text += "[color=#%s]Level %d required[/color]\n\n" % [ThemeColors.TEXT_MUTED.to_html(false), ability.level_requirement]
	text += ability.description
	return text

## Format a skill tooltip
static func format_skill_tooltip(skill_name: String, level: int, cost: int) -> String:
	var color := ThemeColors.get_skill_color(skill_name)
	var text := "[color=#%s][b]%s[/b][/color] (Level %d)\n" % [color.to_html(false), skill_name.capitalize(), level]
	if level < 20:
		text += "Next level: %d XP" % cost
	else:
		text += "[color=#%s]Maximum level[/color]" % ThemeColors.PRIMARY.to_html(false)
	return text
