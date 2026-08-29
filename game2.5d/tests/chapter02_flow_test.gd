extends SceneTree


const CHAPTER_TWO_PORTRAITS := {
	"D019": "res://art/portraits/chapter2/余念（7）：欣然愉悦.png",
	"D020": "res://art/portraits/chapter2/余秀兰（33）：正常状态.png",
	"D021": "res://art/portraits/chapter2/余秀兰（33）：心脏骤停.png",
	"D022": "res://art/portraits/chapter2/余念（7）：积郁憋闷.png",
	"D023": "res://art/portraits/chapter2/余念（7）：淡然自若.png",
	"D024": "res://art/portraits/chapter2/余秀兰（33）：心脏骤停.png",
	"D025": "res://art/portraits/chapter2/余秀兰（33）：含情凝望.png",
	"D048": "res://art/portraits/chapter2/余念（7）：积郁憋闷.png",
	"D049": "res://art/portraits/chapter2/余秀兰（33）：含情凝望.png",
	"D050": "res://art/portraits/chapter2/余念（7）：欣然愉悦.png",
	"D051": "res://art/portraits/chapter2/余秀兰（33）：正常状态.png",
	"D052": "res://art/portraits/chapter2/余念（7）：欣然愉悦.png",
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
	# 白盒地图现在由编辑器摆放在 World/Blocks 下，不再由脚本生成。
	assert(chapter.blocks.get_node_or_null("BlockA/Visuals/BicyclePlaceholder") != null)
	assert(chapter.blocks.get_node_or_null("BlockB/Visuals/UpperStableEndpoint") != null)
	assert(chapter.blocks.get_node_or_null("BlockC/Visuals/GreenIronLamppost") != null)
	assert(chapter.blocks.get_node_or_null("BlockA/Visuals/AB_CorridorNorthVisual") != null)
	assert(chapter.blocks.get_node_or_null("BlockA/SpatialPhysics/A_PuddleBlocker") is StaticBody3D)
	assert(chapter.blocks.get_node_or_null("BlockA/SpatialPhysics/AB_CorridorNorth") is StaticBody3D)
	assert(chapter.blocks.get_node_or_null("BlockA/SpatialPhysics/AB_CorridorSouth") is StaticBody3D)
	assert(chapter.blocks.get_node_or_null("BlockB/SpatialPhysics/B_GapNorth") is StaticBody3D)
	assert(chapter.blocks.get_node_or_null("BlockB/SpatialPhysics/B_GapSouth") is StaticBody3D)
	assert(Chapter2Sequence.A_BICYCLE.distance_to(Chapter2Sequence.A_BICYCLE_PARK) < 4.0)
	assert(Chapter2Sequence.B_CLIMB_OUT.x > Chapter2Sequence.B_FALL_START.x + 6.0)
	# 坑底那张横面必须真的包住落点和绳脚，否则第一段行走会被 clamp 拉走。
	assert(Chapter2Sequence.B_CATCH.x >= Chapter2Sequence.B_PIT_WALK_MIN.x)
	assert(Chapter2Sequence.B_CATCH.x <= Chapter2Sequence.B_PIT_WALK_MAX.x)
	assert(Chapter2Sequence.B_CATCH.z >= Chapter2Sequence.B_PIT_WALK_MIN.y)
	assert(Chapter2Sequence.B_CATCH.z <= Chapter2Sequence.B_PIT_WALK_MAX.y)
	assert(is_equal_approx(Chapter2Sequence.B_CATCH.y, Chapter2Sequence.B_PIT_FLOOR_Y))
	assert(Chapter2Sequence.B_ROPE_FOOT.x >= Chapter2Sequence.B_PIT_WALK_MIN.x)
	assert(Chapter2Sequence.B_ROPE_FOOT.x <= Chapter2Sequence.B_PIT_WALK_MAX.x)
	assert(is_equal_approx(Chapter2Sequence.B_ROPE_FOOT.y, Chapter2Sequence.B_PIT_FLOOR_Y))
	# 绳脚必须正好落在坑底北缘，也就是 PitWallNorth 的墙根：
	# 那面墙绝对走不上去，所以「贴到北缘」是一条硬边界，不是靠近就算。
	assert(
		is_equal_approx(Chapter2Sequence.B_ROPE_FOOT.z, Chapter2Sequence.B_PIT_WALK_MIN.y),
		"the rope foot must sit exactly on the unwalkable north wall root"
	)
	# 触发带要比墙根这条边窄得多，否则站在坑中间也会误触。
	assert(Chapter2Sequence.B_ROPE_FOOT_EDGE_BAND > 0.0)
	assert(
		Chapter2Sequence.B_ROPE_FOOT_EDGE_BAND
		< (Chapter2Sequence.B_PIT_WALK_MAX.y - Chapter2Sequence.B_PIT_WALK_MIN.y) * 0.25,
		"the edge band must be a wall-hug, not a chunk of the pit floor"
	)
	assert(
		Chapter2Sequence.B_ROPE_FOOT_X_BAND
		< (Chapter2Sequence.B_PIT_WALK_MAX.x - Chapter2Sequence.B_PIT_WALK_MIN.x) * 0.25,
		"walking into the wall anywhere else must not start the climb"
	)
	# 落点要离绳脚足够远，人才真的需要在坑底走一段，而不是一落地就直接上线。
	assert(
		Vector2(Chapter2Sequence.B_CATCH.x, Chapter2Sequence.B_CATCH.z).distance_to(
			Vector2(Chapter2Sequence.B_ROPE_FOOT.x, Chapter2Sequence.B_ROPE_FOOT.z)
		) > Chapter2Sequence.B_ROPE_FOOT_X_BAND * 3.0,
		"the rope foot must be a real walk away from where she lands"
	)
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
	assert(mother.visible, "mother must be visible at the far end of the rope")
	assert(
		mother.get_logical_position().is_equal_approx(Chapter2Sequence.B_MOTHER_PIT_EDGE),
		"mother must stand on the platform rim that the rope hangs from"
	)

	# 第一段：落在坑底那张横面上，先自己走，还没搭上线。
	assert(chapter._pit_walking, "the fall must hand control back on the pit floor first")
	assert(not child.is_climbing(), "climbing must not start until she reaches the rope foot")
	assert(child.is_control_enabled())
	assert(is_equal_approx(child.floor_height, Chapter2Sequence.B_PIT_FLOOR_Y))
	assert(
		is_equal_approx(child.get_logical_position().y, Chapter2Sequence.B_PIT_FLOOR_Y),
		"child must stand on the pit floor plane, not at ground level"
	)
	# 坑底行走用的是普通 WASD 分支，走完 y 仍然贴在坑底。
	var pit_walk_start := child.get_logical_position()
	Input.action_press(&"move_right")
	for _index in range(20):
		await physics_frame
	Input.action_release(&"move_right")
	await physics_frame
	var pit_walk_now := child.get_logical_position()
	assert(
		not pit_walk_now.is_equal_approx(pit_walk_start),
		"WASD must move the child around on the pit floor"
	)
	assert(
		is_equal_approx(pit_walk_now.y, Chapter2Sequence.B_PIT_FLOOR_Y),
		"pit walking must not lift the child off the pit floor"
	)
	assert(
		pit_walk_now.x >= Chapter2Sequence.B_PIT_WALK_MIN.x
		and pit_walk_now.x <= Chapter2Sequence.B_PIT_WALK_MAX.x
		and pit_walk_now.z >= Chapter2Sequence.B_PIT_WALK_MIN.y
		and pit_walk_now.z <= Chapter2Sequence.B_PIT_WALK_MAX.y,
		"pit walking must stay inside the measured PitBottom plane"
	)

	# 第二段：走到线垂下来的位置，才切成沿线攀爬。
	child.set_logical_position(Chapter2Sequence.B_ROPE_FOOT)
	chapter._process_climb()
	assert(not chapter._pit_walking, "reaching the rope foot must end the pit-walk phase")
	assert(child.is_climbing(), "reaching the rope foot must start the rope climb")
	var climb_start := child.get_logical_position()
	Input.action_press(&"move_up")
	for _index in range(30):
		await physics_frame
	Input.action_release(&"move_up")
	await physics_frame
	var climb_progress := child.get_logical_position()
	assert(climb_progress.y > climb_start.y, "W climb must move upward out of the pit")
	assert(
		climb_progress.y <= Chapter2Sequence.B_CLIMB_OUT.y,
		"the climb must not overshoot the platform height"
	)

	# 第三段：终点在 BlockB_Farside 平台上。
	child.set_logical_position(Chapter2Sequence.B_CLIMB_OUT)
	await chapter._finish_climb()
	assert(is_equal_approx(child.floor_height, 0.0), "landing must restore the ground plane")
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
