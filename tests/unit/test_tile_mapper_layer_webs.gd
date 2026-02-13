extends GutTest

func test_layer_web_overrides_use_baked_floor_variants() -> void:
	assert_eq(TileMapper.get_layer_terrain_coords(19, "outer_pits", true), Vector2i(28, 20))
	assert_eq(TileMapper.get_layer_terrain_coords(19, "outer_pits", false), Vector2i(29, 20))

	assert_eq(TileMapper.get_layer_terrain_coords(19, "lower_halls", true), Vector2i(30, 20))
	assert_eq(TileMapper.get_layer_terrain_coords(19, "lower_halls", false), Vector2i(31, 20))

	assert_eq(TileMapper.get_layer_terrain_coords(19, "dark_halls", true), Vector2i(28, 21))
	assert_eq(TileMapper.get_layer_terrain_coords(19, "dark_halls", false), Vector2i(29, 21))

	assert_eq(TileMapper.get_layer_terrain_coords(19, "necropolis", true), Vector2i(30, 21))
	assert_eq(TileMapper.get_layer_terrain_coords(19, "necropolis", false), Vector2i(31, 21))

func test_layers_without_web_override_fall_back_to_default_web_tile() -> void:
	assert_eq(TileMapper.get_layer_terrain_coords(19, "pits_of_despair", true), TileMapper.get_terrain_coords(19, true))
	assert_eq(TileMapper.get_layer_terrain_coords(19, "inner_sanctum", true), TileMapper.get_terrain_coords(19, true))
	assert_eq(TileMapper.get_layer_terrain_coords(19, "throne_room", true), TileMapper.get_terrain_coords(19, true))

