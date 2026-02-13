extends GutTest

func test_house_affinity_reduces_skill_point_cost() -> void:
	var player: Player = Player.new()
	player.race_name = "Elf"
	player.house_name = "Of Lothlorien"  # LOR_AFFINITY
	assert_eq(player.get_skill_cost(0, 1, "lore"), 0, "Lore affinity should reduce first point to 0 XP")

func test_racial_penalty_increases_skill_point_cost() -> void:
	var player: Player = Player.new()
	player.race_name = "Dwarf"  # ARC_PENALTY
	player.house_name = "Of Erebor"
	assert_eq(player.get_skill_cost(0, 1, "archery"), 200, "Archery penalty should raise first point to 200 XP")

