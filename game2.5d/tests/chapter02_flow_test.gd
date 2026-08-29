extends SceneTree


const CHAPTER_TWO_PORTRAITS := {
	"D019": "res://art/portraits/chapter2/余念（7）：欣然愉悦.png",
	"D020": "res://art/portraits/chapter2/余秀兰（33）：正常状态.png",
	"D021": "res://art/portraits/chapter2/余秀兰（33）：心脏骤停.png",
	"D022": "res://art/portraits/chapter2/余念（7）：积郁憋闷.png",
	"D023": "res://art/portraits/chapter2/余念（7）：正常状态.png",
	"D024": "res://art/portraits/chapter2/余秀兰（33）：心脏骤停.png",
	"D025": "res://art/portraits/chapter2/余秀兰（33）：含情凝望.png",
	"D048": "res://art/portraits/chapter2/余念（7）：积郁憋闷.png",
	"D049": "res://art/portraits/chapter2/余秀兰（33）：含情凝望.png",
	"D050": "res://art/portraits/chapter2/余念（7）：正常状态.png",
	"D051": "res://art/portraits/chapter2/余秀兰（33）：正常状态.png",
	"D052": "res://art/portraits/chapter2/余念（7）：淡然自若.png",
	"D053": "res://art/portraits/chapter2/余秀兰（33）：含情凝望.png",
	"D054": "res://art/portraits/chapter2/余念（7）：欣然愉悦.png",
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/chapter2/chapter2.tscn") as PackedScene
	assert(packed != null)
	var chapter := packed.instantiate() as Chapter2Sequence
	chapter.debug_skip_intro = true
	root.add_child(chapter)
	await process_frame
	var chapter_camera := chapter.get_node("CameraRig/Camera2D") as Camera2D
	var block_c_goal_screen := Projection25D.project(Chapter2Sequence.C_GOAL)
	assert(
		chapter_camera.limit_bottom > block_c_goal_screen.y,
		"Block C 超出镜头下边界：goal=%s limit_bottom=%d"
		% [block_c_goal_screen, chapter_camera.limit_bottom]
	)
	await physics_frame

	var child := chapter.child as Chapter2Child
	var mother := chapter.player as PlayerController
	var dialogue_db := chapter.get_node("DialogueDatabase") as DialogueDatabase
	assert(chapter.current_stage == Chapter2Sequence.Stage.BICYCLE)
	assert(chapter.generated_map.get_node_or_null("BicyclePlaceholder") != null)
	assert(chapter.generated_map.get_node_or_null("UpperStableEndpoint") != null)
	assert(chapter.generated_map.get_node_or_null("GreenIronLamppost") != null)
	assert(chapter.generated_map.get_node_or_null("AB_CorridorNorthVisual") != null)
	assert(chapter.generated_map.get_node_or_null("AB_CorridorSouthVisual") != null)
	assert(chapter.generated_map.get_node_or_null("C_NorthHouse01") != null)
	assert(chapter.generated_map.get_node_or_null("C_Mailbox") != null)
	assert(chapter.spatial_physics.get_node_or_null("A_PuddleBlocker") is StaticBody3D)
	assert(chapter.spatial_physics.get_node_or_null("AB_CorridorNorth") is StaticBody3D)
	assert(chapter.spatial_physics.get_node_or_null("AB_CorridorSouth") is StaticBody3D)
	assert(chapter.spatial_physics.get_node_or_null("B_GapNorth") is StaticBody3D)
	assert(chapter.spatial_physics.get_node_or_null("B_GapSouth") is StaticBody3D)
	assert(Chapter2Sequence.A_BICYCLE.distance_to(Chapter2Sequence.A_BICYCLE_PARK) < 4.0)
	assert(Chapter2Sequence.B_CLIMB_OUT.x > Chapter2Sequence.B_FALL_START.x + 8.0)
	assert(not chapter.dialogue_ui.speaker_portraits.has("七岁余念"))
	assert(not chapter.dialogue_ui.speaker_portraits.has("年轻余秀兰"))
	for dialogue_id: String in CHAPTER_TWO_PORTRAITS:
		assert(dialogue_db.has_dialogue(dialogue_id), "missing chapter 2 dialogue: %s" % dialogue_id)
		var portrait_path := str(dialogue_db.get_entry(dialogue_id).get("portrait", ""))
		assert(portrait_path == CHAPTER_TWO_PORTRAITS[dialogue_id], "wrong portrait mapping: %s" % dialogue_id)
		assert(ResourceLoader.exists(portrait_path), "missing portrait: %s" % dialogue_id)

	chapter.dialogue_ui.characters_per_second = 0.0
	chapter.dialogue_ui.fade_duration = 0.0
	chapter.dialogue_ui.play("D019")
	await process_frame
	var child_portrait := chapter.dialogue_ui.portrait_texture.texture
	assert(chapter.dialogue_ui.portrait_texture.visible and child_portrait != null, "D019 child portrait did not render")
	chapter.dialogue_ui.play("D020")
	await process_frame
	var mother_portrait := chapter.dialogue_ui.portrait_texture.texture
	assert(chapter.dialogue_ui.portrait_texture.visible and mother_portrait != null, "D020 mother portrait did not render")
	assert(mother_portrait != child_portrait, "child and mother portraits did not switch")
	chapter.dialogue_ui._finish_immediately(false)

	mother.set_logical_position(Chapter2Sequence.A_BICYCLE)
	await chapter._complete_bicycle()
	assert(chapter.current_stage == Chapter2Sequence.Stage.PUDDLE)
	assert(chapter.flags["A_BICYCLE_DONE"])
	assert(chapter.checkpoint_id == "CP-A1")
	# 水坑是实体禁入区：从正西方向持续向 +X 走，角色必须停在水面边缘外。
	child.set_logical_position(Vector3(16.0, 0.0, 12.0))
	mother.set_logical_position(Vector3(16.0, 0.0, 12.0))
	Input.action_press(&"move_right")
	Input.action_press(&"move_down")
	for _index in range(45):
		await physics_frame
	Input.action_release(&"move_right")
	Input.action_release(&"move_down")
	await physics_frame
	assert(mother.get_logical_position().x < 17.5, "mother entered the blocked puddle")

	child.set_logical_position(Chapter2Sequence.A_CHILD_FAR)
	mother.set_logical_position(Vector3(29.0, 0.0, 7.4))
	await chapter._complete_puddle()
	assert(chapter.current_stage == Chapter2Sequence.Stage.NARROW)
	assert(chapter.flags["A_PUDDLE_DONE"])
	assert(chapter.checkpoint_id == "CP-A2")

	await chapter._switch_to_child()
	assert(chapter.flags["MOTHER_STABLE"])
	assert(child.is_control_enabled())
	assert(not mother.is_physics_processing())
	assert(mother.get_logical_position().is_equal_approx(Chapter2Sequence.B_MOTHER_STOP))

	chapter._board_warned = true
	child.set_logical_position(Chapter2Sequence.B_FALL_START)
	await chapter._start_fall()
	assert(chapter.current_stage == Chapter2Sequence.Stage.CLIMB)
	assert(child.get_logical_position().is_equal_approx(Chapter2Sequence.B_CATCH))
	assert(child.is_climbing())
	assert(not mother.visible, "mother must stay out of the pit camera frame")
	assert(chapter._upper_anchor_visual.visible, "the rope endpoint above the pit must stay visible")
	var climb_start := child.get_logical_position()
	Input.action_press(&"move_up")
	for _index in range(30):
		await physics_frame
	Input.action_release(&"move_up")
	await physics_frame
	var climb_progress := child.get_logical_position()
	assert(climb_progress.x > climb_start.x, "W climb must move toward the far rim")
	assert(climb_progress.y > climb_start.y, "W climb must also move upward")

	child.set_logical_position(Chapter2Sequence.B_CLIMB_OUT)
	await chapter._finish_climb()
	assert(chapter.flags["B_CHILD_SAFE"])
	assert(chapter.current_stage == Chapter2Sequence.Stage.LAMP_SCHOOL)
	assert(mother.visible)
	assert(mother.get_logical_position().is_equal_approx(Chapter2Sequence.C_ENTRY_MOTHER))

	mother.set_logical_position(Chapter2Sequence.C_LAMP)
	await chapter._anchor_at_lamp()
	assert(chapter.flags["C_MOTHER_ANCHORED"])
	assert(child.is_control_enabled())
	assert(chapter.checkpoint_id == "CP-C1")
	assert(mother.get_logical_position().is_equal_approx(Chapter2Sequence.C_LAMP))

	await chapter._play_lookback()
	assert(chapter.flags["C_LOOKBACK_DONE"])
	child.set_logical_position(Chapter2Sequence.C_GOAL)
	await chapter._finish_chapter()
	assert(chapter.current_stage == Chapter2Sequence.Stage.COMPLETE)
	assert(chapter.flags["CH2_COMPLETE"])
	assert(chapter.checkpoint_id == "CH2_COMPLETE")

	print("[CHAPTER02_FLOW] PASS six gated lessons, off-screen mother pit shot, W-climb framework, lamp ending")
	quit(0)
