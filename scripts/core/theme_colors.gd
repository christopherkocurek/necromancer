extends Node
## Unified color palette for The Necromancer UI.
## "Forged in Dol Guldur" dark fantasy aesthetic — iron, stone, and gold.
## All UI scripts should reference ThemeColors.* instead of hardcoded Color values.

# ============================================================================
# BACKGROUNDS (6 tiers from void to raised)
# ============================================================================
const BG_VOID := Color("#0A0A0F")
const BG_DARKEST := Color("#0F1016")
const BG_DARK := Color("#161821")
const BG_MEDIUM := Color("#1E2030")
const BG_SURFACE := Color("#272A3D")
const BG_RAISED := Color("#313450")

# ============================================================================
# DARK IRON & STONE (Diablo-inspired material palette)
# ============================================================================
const IRON_DARK := Color("#1A1A1F")          # Panel base, darkest metal
const IRON_MID := Color("#2A2A32")           # Panel surface
const IRON_LIGHT := Color("#3D3D48")         # Raised elements, button face
const IRON_HIGHLIGHT := Color("#55555F")     # Bevel/edge highlight
const IRON_SHADOW := Color("#0D0D12")        # Inner shadow, depth

const STONE_DARK := Color("#252219")         # Carved background texture
const STONE_MID := Color("#3A3529")          # Leather/parchment base
const STONE_LIGHT := Color("#524C3C")        # Raised stone details

const GOLD_DIM := Color("#6B5A2E")           # Inactive gold trim
const GOLD_WARM := Color("#C8A84E")          # Active gold (= PRIMARY)
const GOLD_BRIGHT := Color("#E8D084")        # Highlight, achievements
const GOLD_GLOW := Color("#FFD700")          # Rare item border glow

const COPPER_DIM := Color("#5A3A2A")         # Forge details
const COPPER_WARM := Color("#A0653A")        # Warm accent

const BLOOD_DARK := Color("#4A0E0E")         # Empty health orb
const BLOOD_MID := Color("#8B1A1A")          # Health liquid base
const BLOOD_BRIGHT := Color("#CC2222")       # Health liquid surface
const BLOOD_GLOW := Color("#FF4444")         # Critical pulse

const SPIRIT_DARK := Color("#0E2A4A")        # Empty voice orb
const SPIRIT_MID := Color("#1A4A8B")         # Voice liquid base
const SPIRIT_BRIGHT := Color("#2266CC")      # Voice liquid surface
const SPIRIT_GLOW := Color("#4488FF")        # Full voice glow

const PARCHMENT_BG := Color("#D4C5A0")       # Parchment interior
const PARCHMENT_EDGE := Color("#8B7D5E")     # Parchment border
const PARCHMENT_TEXT := Color("#2A2219")      # Dark text on parchment

# ============================================================================
# TEXT (4 tiers, all >=4.5:1 contrast vs BG_DARK)
# ============================================================================
const TEXT_PRIMARY := Color("#E8E2D6")       # 14:1 contrast
const TEXT_SECONDARY := Color("#B0A998")     # 8:1 contrast
const TEXT_MUTED := Color("#7D7668")         # 4.5:1 contrast
const TEXT_DISABLED := Color("#4E493E")      # Decorative only

# ============================================================================
# BRAND
# ============================================================================
const PRIMARY := Color("#C8A84E")            # Gold
const PRIMARY_DIM := Color("#8C763A")        # Dim gold
const PRIMARY_BRIGHT := Color("#F0D060")     # Bright gold
const SECONDARY := Color("#5B8FB9")          # Steel blue
const ACCENT := Color("#A65D4E")             # Ember/rust

# ============================================================================
# HEALTH
# ============================================================================
const HEALTH_HIGH := Color("#4ADE80")        # Green (>60%)
const HEALTH_MED := Color("#FACC15")         # Yellow (30-60%)
const HEALTH_LOW := Color("#EF4444")         # Red (<30%)
const HEALTH_CRITICAL := Color("#DC2626")    # Deep red (<15%)
const HEALTH_BAR_BG := Color("#1A1A2E")      # Bar background

# ============================================================================
# DAMAGE TYPES
# ============================================================================
const DMG_PHYSICAL := Color("#EF4444")       # Red
const DMG_FIRE := Color("#F97316")           # Orange
const DMG_COLD := Color("#60A5FA")           # Light blue
const DMG_POISON := Color("#4ADE80")         # Green
const DMG_DARK := Color("#A855F7")           # Purple
const DMG_HEAL := Color("#34D399")           # Bright green
const DMG_MANA := Color("#6366F1")           # Indigo
const DMG_MISS := Color("#9CA3AF")           # Gray
const DMG_CRIT := Color("#F0D060")           # Gold
const DMG_BLOCK := Color("#FACC15")          # Yellow

# ============================================================================
# STATUS EFFECTS
# ============================================================================
const STATUS_POISON := Color("#4ADE80")      # Green
const STATUS_CONFUSED := Color("#A855F7")    # Purple
const STATUS_BLIND := Color("#9CA3AF")       # Gray
const STATUS_AFRAID := Color("#FACC15")      # Yellow
const STATUS_SLOW := Color("#67E8F9")        # Cyan
const STATUS_FAST := Color("#FB923C")        # Orange
const STATUS_ENTRANCED := Color("#E879F9")   # Magenta
const STATUS_STUNNED := Color("#EF4444")     # Red
const STATUS_CUT := Color("#B91C1C")         # Dark red
const STATUS_BURNING := Color("#F97316")     # Orange-red
const STATUS_RAGE := Color("#DC2626")        # Red
const STATUS_DARKENED := Color("#3B82F6")    # Blue
const STATUS_IMAGE := Color("#C084FC")       # Medium purple
const STATUS_BUFF := Color("#FB923C")        # Orange (positive stat buffs)

# ============================================================================
# MESSAGES
# ============================================================================
const MSG_INFO := Color("#67E8F9")           # Cyan
const MSG_WARNING := Color("#FACC15")        # Yellow
const MSG_ERROR := Color("#EF4444")          # Red
const MSG_SYSTEM := Color("#9CA3AF")         # Gray
const MSG_QUEST := Color("#C8A84E")          # Gold
const MSG_COMBAT := Color("#E8E2D6")         # Primary (white-ish)
const MSG_LOOT := Color("#60A5FA")           # Light blue
const MSG_HEAL := Color("#34D399")           # Green
const MSG_XP := Color("#FACC15")             # Yellow
const MSG_STEALTH := Color("#166534")        # Dark green

# ============================================================================
# RARITY
# ============================================================================
const RARITY_NORMAL := Color("#9CA3AF")      # Gray
const RARITY_BONUS := Color("#60A5FA")       # Blue
const RARITY_ARTIFACT := Color("#C8A84E")    # Gold
const RARITY_UNIDENTIFIED := Color("#A855F7") # Purple

# ============================================================================
# SKILLS
# ============================================================================
const SKILL_MELEE := Color("#EF4444")        # Red
const SKILL_ARCHERY := Color("#4ADE80")      # Green
const SKILL_EVASION := Color("#60A5FA")      # Blue
const SKILL_STEALTH := Color("#166534")      # Dark green
const SKILL_PERCEPTION := Color("#FACC15")   # Yellow
const SKILL_WILL := Color("#A855F7")         # Purple
const SKILL_SMITHING := Color("#FB923C")     # Orange
const SKILL_LORE := Color("#67E8F9")         # Cyan

# ============================================================================
# ABILITIES
# ============================================================================
const ABILITY_LEARNED := Color("#4ADE80")    # Green
const ABILITY_AVAILABLE := Color("#E8E2D6")  # White
const ABILITY_LOCKED := Color("#6B7280")     # Dim gray
const ABILITY_BLOCKED := Color("#CD5C5C")    # Indian red
const ABILITY_HEADER := Color("#C8A84E")     # Gold

# ============================================================================
# BORDERS
# ============================================================================
const BORDER_DEFAULT := Color("#4B5563")     # Gray
const BORDER_FOCUS := Color("#C8A84E")       # Gold
const BORDER_HOVER := Color("#6B7280")       # Lighter gray
const BORDER_ACTIVE := Color("#5B8FB9")      # Steel blue

# ============================================================================
# COMBAT
# ============================================================================
const COMBAT_HIT := Color("#E8E2D6")         # White
const COMBAT_CRIT := Color("#F97316")        # Orange
const COMBAT_MISS := Color("#9CA3AF")        # Gray
const COMBAT_BLOCK := Color("#FACC15")       # Yellow

# ============================================================================
# UI SLOTS / PANELS
# ============================================================================
const SLOT_EMPTY := Color("#1E2030")         # BG_MEDIUM
const SLOT_HOVER := Color("#313450")         # BG_RAISED
const SLOT_SELECTED := Color("#2D3A4D")      # Blue-tinted dark
const SLOT_EQUIP_EMPTY := Color("#1A2619")   # Green-tinted dark
const SLOT_EQUIP_HOVER := Color("#2A3A29")   # Green-tinted lighter
const PANEL_BG := Color(0.09, 0.09, 0.13, 0.92)  # Semi-transparent dark
const PANEL_HEADER := Color("#1E2030")       # BG_MEDIUM

# ============================================================================
# ALERTNESS / STEALTH METER
# ============================================================================
const ALERT_SAFE := Color("#4ADE80")         # Green
const ALERT_CAUTIOUS := Color("#FACC15")     # Yellow
const ALERT_DETECTED := Color("#EF4444")     # Red
const ALERT_SLEEPING := Color("#60A5FA")     # Blue

# ============================================================================
# ENTITY FLASH (combat feedback)
# ============================================================================
const FLASH_WHITE_HOT := Color(3.0, 2.0, 2.0, 1.0)
const FLASH_RED_HOLD := Color(1.8, 0.4, 0.4, 1.0)
const FLASH_HEAL := Color(0.4, 2.0, 0.6, 1.0)

# Ability VFX flashes
const FLASH_THROAT_SLIT := Color(2.5, 0.2, 0.2, 1.0)   # Deep blood red
const FLASH_RIPOSTE := Color(2.5, 2.5, 3.0, 1.0)        # Bright steel white
const FLASH_CHARGE := Color(2.0, 1.6, 0.6, 1.0)          # Warm impact gold
const FLASH_VANISH := Color(0.3, 0.3, 0.5, 0.6)          # Dark shadow
const FLASH_SPRINT := Color(0.8, 2.0, 0.8, 1.0)          # Speed green
const FLASH_CRIPPLE := Color(1.5, 1.8, 2.5, 1.0)         # Icy blue-white

# ============================================================================
# FONT SIZES
# ============================================================================
const FONT_SIZE_HINT := 20
const FONT_SIZE_BODY := 23
const FONT_SIZE_LARGE := 26
const FONT_SIZE_H3 := 32
const FONT_SIZE_H2 := 39
const FONT_SIZE_H1 := 46
const FONT_SIZE_TITLE := 58

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

## Get health bar color based on percentage (0.0 - 1.0)
static func get_health_color(pct: float) -> Color:
	if pct > 0.6:
		return HEALTH_HIGH
	elif pct > 0.3:
		return HEALTH_MED
	elif pct > 0.15:
		return HEALTH_LOW
	else:
		return HEALTH_CRITICAL

## Get color for a status effect name
static func get_status_color(status_name: String) -> Color:
	match status_name.to_lower():
		"poisoned": return STATUS_POISON
		"confused": return STATUS_CONFUSED
		"blind": return STATUS_BLIND
		"afraid": return STATUS_AFRAID
		"slow": return STATUS_SLOW
		"fast": return STATUS_FAST
		"entranced": return STATUS_ENTRANCED
		"stunned": return STATUS_STUNNED
		"cut": return STATUS_CUT
		"burning": return STATUS_BURNING
		"rage": return STATUS_RAGE
		"darkened": return STATUS_DARKENED
		"image": return STATUS_IMAGE
		_: return TEXT_PRIMARY

## Get color for a damage type
static func get_damage_color(damage_type: String) -> Color:
	match damage_type:
		"physical", "HURT": return DMG_PHYSICAL
		"fire", "FIRE": return DMG_FIRE
		"cold", "COLD": return DMG_COLD
		"poison", "POISON": return DMG_POISON
		"dark", "DARK": return DMG_DARK
		"heal": return DMG_HEAL
		"mana": return DMG_MANA
		"miss": return DMG_MISS
		"critical": return DMG_CRIT
		_: return TEXT_PRIMARY

## Get rarity color for an item
static func get_rarity_color(item: Variant) -> Color:
	if item == null:
		return RARITY_NORMAL
	# Check if artifact
	if item is DataManager.ArtifactData:
		return RARITY_ARTIFACT
	# Check if unidentified
	if GameManager.needs_identification(item) and not GameManager.is_item_identified(item):
		return RARITY_UNIDENTIFIED
	# Check for bonus items (attack_bonus or evasion_bonus > 0)
	if "attack_bonus" in item and item.attack_bonus > 0:
		return RARITY_BONUS
	if "evasion_bonus" in item and item.evasion_bonus > 0:
		return RARITY_BONUS
	return RARITY_NORMAL

## Get skill color by name
static func get_skill_color(skill_name: String) -> Color:
	match skill_name.to_lower():
		"melee": return SKILL_MELEE
		"archery": return SKILL_ARCHERY
		"evasion": return SKILL_EVASION
		"stealth": return SKILL_STEALTH
		"perception": return SKILL_PERCEPTION
		"will": return SKILL_WILL
		"smithing": return SKILL_SMITHING
		"lore": return SKILL_LORE
		_: return TEXT_PRIMARY

## Get alertness color based on alertness value
static func get_alertness_color(alertness: int) -> Color:
	if alertness < Constants.ALERTNESS_UNWARY:
		return ALERT_SAFE
	elif alertness < Constants.ALERTNESS_ALERT:
		return ALERT_CAUTIOUS
	else:
		return ALERT_DETECTED

## Create a styled panel StyleBoxFlat with theme colors
static func create_panel_stylebox(bg: Color = PANEL_BG, border: Color = BORDER_DEFAULT, border_width: int = 1, corner_radius: int = 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.border_color = border
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

## Create a slot StyleBoxFlat
static func create_slot_stylebox(bg: Color, border: Color = BORDER_DEFAULT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = border
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

## Create a status pill StyleBoxFlat for HUD status badges
static func create_status_pill(status_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(status_color, 0.25)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(status_color, 0.6)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style

# ============================================================================
# UI TEXTURE CACHE (loaded once, reused everywhere)
# ============================================================================
var _textures: Dictionary = {}
var _fonts: Dictionary = {}
var _shaders: Dictionary = {}

const UI_TEXTURE_PATHS := {
	"panel_iron": "res://assets/ui/frames/panel_iron.png",
	"panel_stone": "res://assets/ui/frames/panel_stone.png",
	"panel_parchment": "res://assets/ui/frames/panel_parchment.png",
	"slot_empty": "res://assets/ui/frames/slot_empty.png",
	"slot_hover": "res://assets/ui/frames/slot_hover.png",
	"slot_selected": "res://assets/ui/frames/slot_selected.png",
	"button_normal": "res://assets/ui/frames/button_normal.png",
	"button_hover": "res://assets/ui/frames/button_hover.png",
	"button_pressed": "res://assets/ui/frames/button_pressed.png",
	"bar_frame": "res://assets/ui/frames/bar_frame.png",
	"tab_active": "res://assets/ui/frames/tab_active.png",
	"tab_inactive": "res://assets/ui/frames/tab_inactive.png",
	"orb_frame": "res://assets/ui/orbs/orb_frame.png",
	"orb_mask": "res://assets/ui/orbs/orb_mask.png",
	"bg_stone": "res://assets/ui/backgrounds/bg_stone_tile.png",
	"bg_leather": "res://assets/ui/backgrounds/bg_leather.png",
	"bg_metal": "res://assets/ui/backgrounds/bg_metal_brushed.png",
	"action_bar_bg": "res://assets/ui/backgrounds/action_bar_bg.png",
	"divider": "res://assets/ui/decorative/divider_ornate.png",
	"xp_fill": "res://assets/ui/decorative/xp_bar_fill.png",
	"health_fill": "res://assets/ui/decorative/health_bar_fill.png",
	"voice_fill": "res://assets/ui/decorative/voice_bar_fill.png",
}

const FONT_PATHS := {
	"heading": "res://assets/fonts/Almendra-Bold.ttf",
	"body": "res://assets/fonts/Almendra-Regular.ttf",
}

const SHADER_PATHS := {
	"orb_liquid": "res://assets/shaders/ui/orb_liquid.gdshader",
	"gold_glow": "res://assets/shaders/ui/gold_glow.gdshader",
	"vignette": "res://assets/shaders/ui/vignette.gdshader",
	"engraved": "res://assets/shaders/ui/engraved_text.gdshader",
}

# 9-slice margin definitions per texture (left, top, right, bottom)
const NINE_SLICE_MARGINS := {
	"panel_iron": Vector4(6, 6, 6, 6),
	"panel_stone": Vector4(6, 6, 6, 6),
	"panel_parchment": Vector4(6, 6, 6, 6),
	"slot_empty": Vector4(3, 3, 3, 3),
	"slot_hover": Vector4(3, 3, 3, 3),
	"slot_selected": Vector4(3, 3, 3, 3),
	"button_normal": Vector4(6, 4, 6, 4),
	"button_hover": Vector4(6, 4, 6, 4),
	"button_pressed": Vector4(6, 4, 6, 4),
	"bar_frame": Vector4(3, 3, 3, 3),
	"tab_active": Vector4(6, 4, 6, 0),
	"tab_inactive": Vector4(6, 4, 6, 4),
}

func _ready() -> void:
	_load_textures()
	_load_fonts()
	_load_shaders()

func _load_textures() -> void:
	for key: String in UI_TEXTURE_PATHS:
		var path: String = UI_TEXTURE_PATHS[key]
		if ResourceLoader.exists(path):
			_textures[key] = load(path)

func _load_fonts() -> void:
	for key: String in FONT_PATHS:
		var path: String = FONT_PATHS[key]
		if ResourceLoader.exists(path):
			_fonts[key] = load(path)

func _load_shaders() -> void:
	for key: String in SHADER_PATHS:
		var path: String = SHADER_PATHS[key]
		if ResourceLoader.exists(path):
			_shaders[key] = load(path)

## Get a cached UI texture by key name
func get_texture(key: String) -> Texture2D:
	return _textures.get(key)

## Get a cached font by key ("heading" or "body")
func get_font(key: String) -> Font:
	return _fonts.get(key)

## Get a cached shader by key
func get_shader(key: String) -> Shader:
	return _shaders.get(key)

## Check if UI textures are available (for graceful fallback)
func has_textures() -> bool:
	return _textures.size() > 0

## Create a StyleBoxTexture from a 9-slice UI texture
func create_textured_panel(texture_key: String, content_margin: float = 8.0) -> StyleBox:
	var tex: Texture2D = get_texture(texture_key)
	if tex == null:
		# Fallback to flat style
		return _flat_fallback(IRON_DARK, IRON_HIGHLIGHT)
	var style := StyleBoxTexture.new()
	style.texture = tex
	var margins: Vector4 = NINE_SLICE_MARGINS.get(texture_key, Vector4(6, 6, 6, 6))
	style.texture_margin_left = margins.x
	style.texture_margin_top = margins.y
	style.texture_margin_right = margins.z
	style.texture_margin_bottom = margins.w
	style.content_margin_left = content_margin
	style.content_margin_right = content_margin
	style.content_margin_top = content_margin * 0.5
	style.content_margin_bottom = content_margin * 0.5
	return style

## Create a textured slot StyleBox (inventory/equipment)
func create_textured_slot(state: String = "empty") -> StyleBox:
	var key: String = "slot_%s" % state
	var tex: Texture2D = get_texture(key)
	if tex == null:
		var bg: Color = SLOT_EMPTY if state == "empty" else SLOT_HOVER if state == "hover" else SLOT_SELECTED
		var border: Color = BORDER_DEFAULT if state == "empty" else BORDER_HOVER if state == "hover" else BORDER_FOCUS
		return _flat_slot_fallback(bg, border)
	var style := StyleBoxTexture.new()
	style.texture = tex
	var margins: Vector4 = NINE_SLICE_MARGINS.get(key, Vector4(3, 3, 3, 3))
	style.texture_margin_left = margins.x
	style.texture_margin_top = margins.y
	style.texture_margin_right = margins.z
	style.texture_margin_bottom = margins.w
	style.content_margin_left = 2
	style.content_margin_right = 2
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style

## Create a textured button set (normal, hover, pressed) and apply to a Button
func apply_button_theme(button: Button) -> void:
	var normal: Variant = get_texture("button_normal")
	if normal == null:
		# Fallback to flat iron style
		button.add_theme_stylebox_override("normal", create_panel_stylebox(IRON_LIGHT, IRON_HIGHLIGHT, 1, 2))
		button.add_theme_stylebox_override("hover", create_panel_stylebox(Color(IRON_LIGHT, 1.0).lightened(0.1), GOLD_DIM, 1, 2))
		button.add_theme_stylebox_override("pressed", create_panel_stylebox(IRON_SHADOW, IRON_HIGHLIGHT, 1, 2))
	else:
		button.add_theme_stylebox_override("normal", create_textured_panel("button_normal", 6.0))
		button.add_theme_stylebox_override("hover", create_textured_panel("button_hover", 6.0))
		button.add_theme_stylebox_override("pressed", create_textured_panel("button_pressed", 6.0))
	# Font styling
	var heading_font: Font = get_font("body")
	if heading_font:
		button.add_theme_font_override("font", heading_font)
	button.add_theme_color_override("font_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", GOLD_WARM)
	button.add_theme_color_override("font_pressed_color", GOLD_BRIGHT)
	button.add_theme_font_size_override("font_size", FONT_SIZE_BODY)

## Apply heading font to a label
func apply_heading_font(label: Label, size: int = FONT_SIZE_H2) -> void:
	var font: Font = get_font("heading")
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", GOLD_WARM)

## Apply body font to a label
func apply_body_font(label: Label, size: int = FONT_SIZE_BODY) -> void:
	var font: Font = get_font("body")
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", TEXT_PRIMARY)

## Apply body font to a RichTextLabel
func apply_rich_body_font(rtl: RichTextLabel, size: int = FONT_SIZE_BODY) -> void:
	var font: Font = get_font("body")
	if font:
		rtl.add_theme_font_override("normal_font", font)
	var bold_font: Font = get_font("heading")
	if bold_font:
		rtl.add_theme_font_override("bold_font", bold_font)
	rtl.add_theme_font_size_override("normal_font_size", size)
	rtl.add_theme_color_override("default_color", TEXT_PRIMARY)

## Create an orb ShaderMaterial for health or voice display
func create_orb_material(is_health: bool = true) -> ShaderMaterial:
	var shader: Shader = get_shader("orb_liquid")
	if shader == null:
		return null
	var mat := ShaderMaterial.new()
	mat.shader = shader
	if is_health:
		mat.set_shader_parameter("liquid_color", BLOOD_MID)
		mat.set_shader_parameter("liquid_surface", BLOOD_BRIGHT)
	else:
		mat.set_shader_parameter("liquid_color", SPIRIT_MID)
		mat.set_shader_parameter("liquid_surface", SPIRIT_BRIGHT)
	mat.set_shader_parameter("fill_level", 1.0)
	mat.set_shader_parameter("wobble_speed", 2.0)
	mat.set_shader_parameter("wobble_amount", 0.02)
	mat.set_shader_parameter("is_critical", false)
	return mat

# Flat fallbacks when textures aren't loaded
func _flat_fallback(bg: Color, border: Color) -> StyleBoxFlat:
	return create_panel_stylebox(bg, border, 1, 2)

func _flat_slot_fallback(bg: Color, border: Color) -> StyleBoxFlat:
	return create_slot_stylebox(bg, border)
