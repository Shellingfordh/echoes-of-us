extends SceneTree

const PREFIX := "/tmp/echoes-chapter1-audit-round7-after"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await _frames(8)

	var room := main.get_node("World/Chapter01Room01") as RoomBase
	var player := main.get_node("Player") as PlayerController
	var act := main.get_node("Act01Sequence") as Act01Sequence
	var tie_line := main.get_node("TieLine") as TieLine
	var dialogue := main.get_node("UI/DialogueUI") as DialogueUI
	var camera_rig := main.get_node("CameraRig") as CameraRig
	var tension_feedback := room.get_node("TensionFeedback")

	dialogue.characters_per_second = 0.0
	dialogue.monologue_hold_seconds = 30.0
	dialogue.fade_duration = 0.0
	act._finish_umbrella_scene()
	player.set_logical_position(Vector3(15.1, 0.0, 2.4))
	while act.current_beat != Act01Sequence.Beat.FIRST_PULL:
		await physics_frame
	_snap_door(camera_rig, room)

	player.set_logical_position(Vector3(13.2, 0.0, 3.1))
	await _physics_frames(5)
	assert(tie_line.current_state == TieLine.State.NORMAL)
	assert(is_zero_approx(player.get_resistance_visual_strength()))
	assert(is_zero_approx(tension_feedback.get_feedback_strength()))
	await _save("%s-01-normal.png" % PREFIX)

	player.move_speed = 1.5
	Input.action_press(&"move_right")
	var tension_frames := 0
	while (
		act.current_beat == Act01Sequence.Beat.FIRST_PULL
		and tie_line.current_state != TieLine.State.TENSION
		and tension_frames < 600
	):
		await physics_frame
		tension_frames += 1
	for _index in range(8):
		await physics_frame
		if act.current_beat != Act01Sequence.Beat.FIRST_PULL:
			break
	Input.action_release(&"move_right")
	assert(act.current_beat == Act01Sequence.Beat.FIRST_PULL)
	assert(tie_line.current_state == TieLine.State.TENSION)
	assert(player.get_resistance_visual_strength() > 0.1)
	assert(tension_feedback.get_feedback_strength() > 0.1)
	await _save("%s-02-high-tension.png" % PREFIX)

	Input.action_press(&"move_right")
	while act.current_beat != Act01Sequence.Beat.WAIT_PROBE_REARM:
		await physics_frame
	Input.action_release(&"move_right")
	assert(dialogue._current_id == "D015")
	dialogue.advance()
	assert(dialogue._current_id == "D016")
	dialogue.advance()
	while act.current_beat != Act01Sequence.Beat.LINE_PROBE:
		await physics_frame
	act._on_empty_interact_pressed()
	Input.action_press(&"interact")
	Input.action_press(&"move_right")
	await _physics_frames(8)
	assert(act.current_beat == Act01Sequence.Beat.PROBING_RESISTANCE)
	assert(player.get_resistance_visual_strength() > 0.8)
	assert(tension_feedback.get_feedback_strength() > 0.8)
	await _save("%s-03-active-resistance.png" % PREFIX)
	Input.action_release(&"move_right")
	Input.action_release(&"interact")

	print(
		"[CAPTURE] after sprite_rotation=", snappedf(player.animated_sprite.rotation, 0.001),
		" sprite_offset=", player.animated_sprite.position,
		" shadow_scale=", player.ground_shadow.scale,
		" environment_feedback=", snappedf(tension_feedback.get_feedback_strength(), 0.01)
	)
	print("[CAPTURE] %s-{01-normal,02-high-tension,03-active-resistance}.png" % PREFIX)
	quit(0)


func _save(path: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(path)
	assert(error == OK)


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _physics_frames(count: int) -> void:
	for _index in range(count):
		await physics_frame


func _snap_door(camera_rig: CameraRig, room: RoomBase) -> void:
	var door_view := room.get_camera_point(&"DoorView")
	assert(door_view != null)
	camera_rig.stop_following()
	camera_rig.camera.position_smoothing_enabled = false
	camera_rig.snap_to(door_view, Vector2(1.15, 1.15))
	camera_rig.camera.force_update_scroll()
