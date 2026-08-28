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
	var start := player.get_logical_position()
	assert(start.is_equal_approx(Vector3(5.0, 0.0, 10.2)))
	assert(player.global_position.is_equal_approx(Projection25D.project(start)))
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

	player.set_logical_position(Vector3(7.0, 0.0, 5.0))
	await physics_frame
	Input.action_press(&"move_right")
	Input.action_press(&"move_down")
	for _index in range(60):
		await physics_frame
	Input.action_release(&"move_right")
	Input.action_release(&"move_down")
	await physics_frame
	var bed_stop := player.get_logical_position()
	assert(bed_stop.x > 8.3 and bed_stop.x < 9.0)
	assert(is_equal_approx(bed_stop.z, 5.0))

	# 遮挡排序：排序键只能来自地面深度 x + z，高度不参与。
	# 柜顶相框和衣柜站在同一格地面上，相框必须靠 depth_offset 排到衣柜前面。
	var room := main.get_node("World/Chapter01Room01")
	var required_objects := get_nodes_in_group(&"key_object")
	assert(required_objects.size() == 5)
	for dialogue_id in [
		"D001", "D002", "D003", "D004", "D005", "D014", "D015", "D016",
		"D017", "D018", "D041", "D042", "D043", "D044", "D045", "D046", "D047",
	]:
		assert(dialogue_db.has_dialogue(dialogue_id))
	assert((room.get_node("Interactables/PhotoFrame") as Interactable).is_key_object)
	assert((room.get_node("Interactables/Headphones") as Interactable).is_key_object)
	assert(not (room.get_node("Interactables/WardrobeInspect") as Interactable).is_key_object)
	assert(not (room.get_node("Interactables/WindowInspect") as Interactable).is_key_object)
	assert(not (room.get_node("Interactables/ThreadClue") as Interactable).interaction_enabled)
	var wardrobe := room.get_node("Midground/Wardrobe") as SpatialProp25D
	var photo := room.get_node("Interactables/PhotoFrame") as Interactable
	var stool := room.get_node("Interactables/Stool") as Interactable
	var window := room.get_node("Midground/Window") as SpatialProp25D
	# 相框画面仍在柜顶；先移动有真实碰撞的木凳，才开放交互锚点。
	assert(photo.get_logical_position().is_equal_approx(Vector3(3.0, 0.0, 2.9)))
	assert(not photo.interaction_enabled)
	assert(stool.get_node("MathBody") is StaticBody3D)
	stool.interact(player)
	assert(photo.interaction_enabled)
	player.set_logical_position(Vector3(3.0, 0.0, 3.0))
	await physics_frame
	await physics_frame
	assert(player._current_interactable == photo)
	assert(photo.z_index > wardrobe.z_index)
	# 墙面物件永远在地面物件之后，但仍在背景层（z_index = -1000）之前。
	assert(window.z_index < wardrobe.z_index and window.z_index > -4000)

	# 拉回必须通过 CharacterBody3D.move_and_slide()：妈妈在床东侧、玩家在床西侧，
	# 即使牵挂线持续施力，玩家也应被床的 StaticBody3D 挡在西侧。
	var mother := room.get_node("Characters/Mother") as Mother
	mother.set_logical_position(Vector3(15.0, 0.0, 5.0))
	player.set_logical_position(Vector3(7.0, 0.0, 5.0))
	tie_line.max_distance = 2.0
	tie_line.set_enabled(true)
	for _index in range(120):
		await physics_frame
	var pull_blocked := player.get_logical_position()
	assert(pull_blocked.x > 8.3 and pull_blocked.x < 9.0)
	assert(is_equal_approx(pull_blocked.z, 5.0))

	print("[SMOKE_25D] PASS free_move=", finish, " bed_collision_stop=", bed_stop)
	print("[SMOKE_25D] rope pull blocked by bed at=", pull_blocked)
	print("[SMOKE_25D] depth wardrobe=", wardrobe.z_index, " photo=", photo.z_index, " window=", window.z_index)
	quit(0)
