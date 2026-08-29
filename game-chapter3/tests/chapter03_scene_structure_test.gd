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
	assert(chapter.get_node("HUD/Toasts/Toast2/Text") is Label)
	chapter.toasts.clear()
	chapter._toast("回到了最近的检查点", 4.0)
	chapter._toast("回到了最近的检查点", 4.0)
	chapter._sync_scene_nodes()
	assert(chapter.toasts.size() == 1)
	assert(chapter.get_node("HUD/Toasts/Toast2").visible)
	assert(chapter.get_node("HUD/Toasts/Toast2/Text").text == "回到了最近的检查点")
	assert(chapter.get_node("World/EditorPreview/Platforms/FloorStart") is StaticBody2D)
	assert(chapter.get_node("World/LevelMount/CurrentLevel/Platforms/FloorStart") is StaticBody2D)
	var chapter_script := FileAccess.get_file_as_string("res://scripts/chapter3/chapter3.gd")
	assert(not chapter_script.contains("高中姑娘"))
	assert(not chapter_script.contains("helper_rect"))
	assert(not chapter_script.contains("for band in range(8)"), "背景不能叠加横向渐变网格")
	assert(not chapter_script.contains("for seam in range(7)"), "背景不能叠加竖向网格")
	assert(not chapter_script.contains("Color(0.05, 0.10, 0.12, 0.23)"), "背景不能叠加统一深色蒙层")

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
		assert(layout.get_node("Markers/ExitTrigger") is Area2D)
		assert(layout.get_node("Markers/ExitTrigger/CollisionShape2D") is CollisionShape2D)
		assert(layout.find_child("Helper", true, false) == null)
		for platform in layout.get_node("Platforms").get_children():
			assert(platform.call("_uses_wood_surface"), "路面与平台必须使用木质视觉：%s" % platform.name)
		for plank in layout.get_node("Planks").get_children():
			assert(plank.call("_uses_wood_surface"), "木板必须使用木质视觉：%s" % plank.name)
		for plate in layout.get_node("Plates").get_children():
			assert(plate.call("_is_pressure_plate"), "踏板必须使用双状态贴图：%s" % plate.name)
		if index == 1:
			for box_name in ["HeavyBox", "StepBox"]:
				var box := layout.get_node("Boxes/%s" % box_name) as Chapter3LayoutItem
				var sprite := box.get_node("Sprite2D") as Sprite2D
				assert(is_zero_approx(box.fill_color.a) and is_zero_approx(box.edge_color.a))
				assert(sprite.texture is AtlasTexture)
				var visual_size := sprite.texture.get_size() * sprite.scale
				assert(absf(visual_size.x - 54.0) < 0.2 and absf(visual_size.y - 54.0) < 0.2)
		var definition: Dictionary = layout.to_level_definition()
		for key in expected_counts[index]:
			assert(definition[key].size() == expected_counts[index][key])
		layout.free()

	print("[CHAPTER03_SCENE] PASS editable actors, no NPCs, HUD-layer toasts, tether and 3 independent level scenes")
	quit(0)
