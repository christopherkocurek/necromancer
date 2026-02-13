extends GutTest

func test_minimap_compact_and_expanded_layout() -> void:
	var hud: HUD = HUD.new()
	add_child_autofree(hud)
	await get_tree().process_frame

	assert_not_null(hud.minimap, "HUD should build minimap")
	assert_not_null(hud.minimap_frame, "HUD should build minimap frame")
	assert_eq(hud.minimap.custom_minimum_size, HUD.MINIMAP_COMPACT_SIZE, "Minimap should start at compact size")

	hud._on_minimap_clicked()
	assert_eq(hud.minimap.custom_minimum_size, HUD.MINIMAP_EXPANDED_SIZE, "Click should expand minimap")

	hud._on_minimap_clicked()
	assert_eq(hud.minimap.custom_minimum_size, HUD.MINIMAP_COMPACT_SIZE, "Second click should collapse minimap")

