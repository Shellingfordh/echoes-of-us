extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/chapter3/chapter3.tscn") as PackedScene
	assert(packed != null)
	var chapter := packed.instantiate() as Chapter3Game
	root.add_child(chapter)
	await process_frame

	assert(chapter.get_node("World/Actors/Daughter") is CharacterBody2D)
	assert(chapter.get_node("World/Actors/Mother") is CharacterBody2D)
	assert(chapter.get_node("World/TieLine") is Line2D)
	assert(chapter.get_node("HUD") is CanvasLayer)
	assert(chapter.get_node("HUD/TopBar/Objective") is Label)
	assert(chapter.get_node("World/LevelSourcePreview/Platforms/FloorStart") is StaticBody2D)

	var scene_paths := [
		"res://scenes/chapter3/levels/chapter3_stairwell.tscn",
		"res://scenes/chapter3/levels/chapter3_warehouse.tscn",
		"res://scenes/chapter3/levels/chapter3_rooftop.tscn",
	]
	var expected_counts := [
		{"statics": 11, "planks": 1, "boxes": 0, "plates": 3, "doors": 2},
		{"statics": 4, "planks": 0, "boxes": 2, "plates": 2, "doors": 2},
		{"statics": 5, "planks": 0, "boxes": 0, "plates": 2, "doors": 1},
	]
	for index in range(scene_paths.size()):
		var level_packed := load(scene_paths[index]) as PackedScene
		assert(level_packed != null)
		var layout := level_packed.instantiate()
		assert(layout.has_method("to_level_definition"))
		var definition: Dictionary = layout.to_level_definition()
		for key in expected_counts[index]:
			assert(definition[key].size() == expected_counts[index][key])
		layout.free()

	print("[CHAPTER03_SCENE] PASS editable actors, HUD, tether and 3 independent level scenes")
	quit(0)
