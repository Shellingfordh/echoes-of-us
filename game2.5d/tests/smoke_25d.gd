extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame

	var player := main.get_node("Player") as PlayerController
	var tie_line := main.get_node("TieLine") as TieLine
	var dialogue_db := main.get_node("DialogueDatabase") as DialogueDatabase
	var observation_db := main.get_node("ObservationDatabase") as ObservationDatabase
	var dialogue_ui := main.get_node("UI/DialogueUI") as DialogueUI
	var interaction_hint := main.get_node("UI/InteractionHint") as InteractionHint
	var start := player.get_logical_position()
	assert(start.is_equal_approx(Vector3(5.0, 0.0, 10.2)))
	assert(player.global_position.is_equal_approx(Projection25D.project(start)))
	assert(player.ground_shadow.position.is_equal_approx(player.ground_shadow_offset))
	assert(dialogue_ui.portrait_texture is TextureRect)
	# 单键保持屏幕水平/垂直移动；横纵各按一键时可沿屏幕斜线移动。
	var screen_right := Projection25D.project_direction(
		player._screen_input_to_logical_direction(Vector2.RIGHT)
	)
	var screen_diagonal := Projection25D.project_direction(
		player._screen_input_to_logical_direction(Vector2(1.0, 1.0).normalized())
	)
	assert(screen_right.x > 0.0 and absf(screen_right.y) < 0.001)
	assert(screen_diagonal.x > 0.0 and screen_diagonal.y > 0.0)

	Input.action_press(&"move_right")
	Input.action_press(&"move_down")
	for _index in range(90):
		await physics_frame
	Input.action_release(&"move_right")
	Input.action_release(&"move_down")
	await physics_frame

	var finish := player.get_logical_position()
	assert(finish.x > start.x + 2.0)
	assert(finish.z >= player.movement_min.y and finish.z <= player.movement_max.y)
	assert(player.global_position.is_equal_approx(Projection25D.project(finish)))
	assert(tie_line.distance >= 0.0)

	player.set_logical_position(Vector3(7.0, 0.0, 4.0))
	await physics_frame
	Input.action_press(&"move_right")
	Input.action_press(&"move_down")
	for _index in range(60):
		await physics_frame
	Input.action_release(&"move_right")
	Input.action_release(&"move_down")
	await physics_frame
	var bed_stop := player.get_logical_position()
	var bed_body := main.get_node("World/Chapter01Room01/Midground/Bed/MathBody") as StaticBody3D
	var bed_shape := bed_body.get_node("CollisionShape3D") as CollisionShape3D
	# 床的碰撞体必须真的按贴图足迹展开，玩家只能停在床的 -X 面外侧。
	# 期望值直接从形状算出来，改贴图尺寸时不用再同步维护魔法数字。
	var bed_size := (bed_shape.shape as BoxShape3D).size
	var bed_min_x: float = bed_body.position.x + bed_shape.position.x - bed_size.x * 0.5
	assert(bed_size.x > 2.0 and bed_size.z > 2.0, "bed collider still default-sized: %s" % bed_size)
	assert(
		bed_stop.x > bed_min_x - 0.6 and bed_stop.x < bed_min_x,
		"bed_stop=%s bed_min_x=%f body=%s size=%s" % [bed_stop, bed_min_x, bed_body.position, bed_size]
	)
	assert(is_equal_approx(bed_stop.z, 4.0))

	# 遮挡排序：排序键只能来自地面深度 x + z，高度不参与。
	# 柜顶相框和衣柜站在同一格地面上，相框必须靠 depth_offset 排到衣柜前面。
	var room := main.get_node("World/Chapter01Room01")
	var required_objects := get_nodes_in_group(&"key_object")
	assert(required_objects.size() == 5)
	assert(observation_db.get_all_ids().size() == 10)
	for dialogue_id in [
		"D001", "D002", "D003", "D004", "D005", "D014", "D015", "D016",
		"D017", "D018", "D041", "D042", "D043", "D044", "D045", "D046", "D047",
	]:
		assert(dialogue_db.has_dialogue(dialogue_id))
	assert((room.get_node("Interactables/PhotoFrame") as Interactable).is_key_object)
	assert((room.get_node("Interactables/BedCrouchTrigger") as Interactable).is_key_object)
	assert((room.get_node("Interactables/BedCrouchTrigger") as Interactable).requires_crouch)
	assert(room.get_node_or_null("Interactables/Headphones") == null)
	assert(room.get_node_or_null("Interactables/BeadBracelet") == null)
	assert(not (room.get_node("Interactables/WardrobeInspect") as Interactable).is_key_object)
	assert(not (room.get_node("Interactables/WindowInspect") as Interactable).is_key_object)
	assert(not (room.get_node("Interactables/ThreadClue") as Interactable).interaction_enabled)
	for target_node in get_nodes_in_group(&"interactable"):
		var target := target_node as Interactable
		if target == null:
			continue
		var glow := target.get_node_or_null("Glow") as CanvasItem
		if glow != null:
			assert(not glow.visible)
	var wardrobe := room.get_node("Midground/Wardrobe") as SpatialProp25D
	var photo := room.get_node("Interactables/PhotoFrame") as Interactable
	var packing_box := room.get_node("Interactables/PackingBox") as Interactable
	var stool := room.get_node("Interactables/Stool") as PushableStool
	var window := room.get_node("Midground/Window") as SpatialProp25D
	assert(room.get_node("Background/BackWallX") is Sprite2D)
	assert(room.get_node("Background/BackWallZ") is Sprite2D)
	assert(room.get_node("Background/Floor") is Sprite2D)
	for visual_path in [
		"Midground/Wardrobe/Visual",
		"Midground/Bed/Visual",
		"Midground/ShoeCabinet/Visual",
		"Midground/Window/Visual",
		"Midground/DoorFrame/Visual",
		"Interactables/PackingBox/Visual",
		"Interactables/Desk/Visual",
		"Interactables/Suitcase/Visual",
		"Interactables/PhotoFrame/Visual",
		"Interactables/Stool/Visual",
		"Interactables/Umbrella/Visual",
	]:
		var art_sprite := room.get_node(visual_path) as Sprite2D
		assert(art_sprite != null and art_sprite.texture != null)
	# 相框画面仍在柜顶；箱子进入柜前目标区仍不够，必须再跳上箱顶。
	assert(photo.get_logical_position().is_equal_approx(Vector3(3.0, 0.0, 2.9)))
	assert(not photo.interaction_enabled)
	assert(packing_box.get_node("MathBody") is StaticBody3D)
	assert(stool.get_node("MathBody") is CharacterBody3D)
	var packing_box_start := packing_box.get_logical_position()
	var stool_start := stool.get_logical_position()
	for _index in range(8):
		stool.try_push(Vector3(0.0, 0.0, -1.0))
		await physics_frame
	assert(stool.get_logical_position().z < stool_start.z)
	assert(packing_box.get_logical_position().is_equal_approx(packing_box_start))
	stool.set_logical_position(stool.target_position)
	await physics_frame
	assert(stool.is_in_target_zone())
	assert(not photo.interaction_enabled)
	assert(player.mount_stool(stool))
	await physics_frame
	await physics_frame
	assert(photo.interaction_enabled)
	assert(player.get_logical_position().y > 0.0)
	assert(player._current_interactable == photo)
	assert("空格" in interaction_hint.text and "下来" in interaction_hint.text)
	assert(photo.z_index > wardrobe.z_index)
	player.dismount_stool()
	await physics_frame
	assert(not photo.interaction_enabled)
	# 墙面物件永远在地面物件之后，但仍在背景层（z_index = -1000）之前。
	assert(window.z_index < wardrobe.z_index and window.z_index > -4000)

	# 拉回必须通过 CharacterBody3D.move_and_slide()：妈妈在床东侧、玩家在床西侧，
	# 即使牵挂线持续施力，玩家也应被床的 StaticBody3D 挡在西侧。
	var mother := room.get_node("Characters/Mother") as Mother
	assert(mother.get_node_or_null("GroundShadow") is Polygon2D)
	mother.set_logical_position(Vector3(15.0, 0.0, 4.0))
	player.set_logical_position(Vector3(7.0, 0.0, 4.0))
	var live_pull_start := player.get_logical_position()
	tie_line.max_distance = 2.0
	tie_line.set_enabled(true)
	tie_line._process(0.0)
	assert(tie_line.pullback_start_position.is_equal_approx(live_pull_start))
	for _index in range(120):
		await physics_frame
	var pull_blocked := player.get_logical_position()
	assert(pull_blocked.x > bed_min_x - 0.6 and pull_blocked.x < bed_min_x)
	assert(is_equal_approx(pull_blocked.z, 4.0))

	print("[SMOKE_25D] PASS free_move=", finish, " bed_collision_stop=", bed_stop)
	print("[SMOKE_25D] static packing box + pushable stool + mount-gated photo PASS")
	print("[SMOKE_25D] live-position rope pull blocked by bed at=", pull_blocked)
	print("[SMOKE_25D] depth wardrobe=", wardrobe.z_index, " photo=", photo.z_index, " window=", window.z_index)
	quit(0)
