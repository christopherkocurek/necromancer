extends Node
## Unified color palette for The Necromancer UI.
## "Dol Guldur" dark fantasy aesthetic.
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

# ============================================================================
# FONT SIZES
# ============================================================================
const FONT_SIZE_HINT := 12
const FONT_SIZE_BODY := 14
const FONT_SIZE_LARGE := 16
const FONT_SIZE_H3 := 20
const FONT_SIZE_H2 := 24
const FONT_SIZE_H1 := 28
const FONT_SIZE_TITLE := 36

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
