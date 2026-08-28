extends SceneTree

const PREFIX := "/tmp/echoes-chapter1-audit-round8-after"


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
	var umbrella := room.get_node("Interactables/Umbrella") as Interactable
	var transition := main.get_node("UI/TransitionOverlay") as ColorRect

	dialogue.characters_per_second = 0.0
	dialogue.monologue_hold_seconds = 30.0
	dialogue.fade_duration = 0.0
	await _reach_echo_threshold(act, player, tie_line, dialogue)
	_snap_line_reveal(camera_rig, room)

	assert(act.current_beat == Act01Sequence.Beat.AFTER_PROBE)
	assert(dialogue.is_playing() and dialogue._current_id == "D018")
	assert(tie_line.extended)
	assert(tie_line.current_state == TieLine.State.PULL_BACK)
	assert(tie_line.is_echo_resonating())
	assert(umbrella.is_resonating())
	await _save("%s-01-d018.png" % PREFIX)

	dialogue.advance()
	await _frames(3)
	player.set_logical_position(umbrella.get_logical_position() + Vector3(-0.45, 0.0, 0.2))
	await _physics_frames(6)
	assert(umbrella.can_interact())
	assert(tie_line.current_state == TieLine.State.NORMAL)
	assert(tie_line.default_color.is_equal_approx(tie_line.echo_color))
	assert(tie_line.get_echo_resonance_strength() > 0.0)
	assert(umbrella.get_resonance_strength() > 0.0)
	assert(absf(tie_line.get_echo_resonance_strength() - umbrella.get_resonance_strength()) < 0.03)
	assert(not transition.visible)
	await _save("%s-02-umbrella-ready.png" % PREFIX)

	umbrella.interact(player)
	assert(act.current_beat == Act01Sequence.Beat.ECHO_TRANSITION)
	assert(not transition.visible)
	await _seconds(0.36)
	assert(act.current_beat == Act01Sequence.Beat.ECHO_TRANSITION)
	await _save("%s-03-shared-resonance.png" % PREFIX)

	while act.current_beat != Act01Sequence.Beat.DONE:
		await process_frame
	await _seconds(0.26)
	assert(transition.visible)
	await _save("%s-04-transition.png" % PREFIX)

	print(
		"[CAPTURE] after echo_state=", TieLine.State.keys()[tie_line.current_state],
		" tension=", snappedf(tie_line.tension, 0.01),
		" shared_resonance=", tie_line.is_echo_resonating() and umbrella.is_resonating(),
		" transition=", transition.visible
	)
	print("[CAPTURE] %s-{01-d018,02-umbrella-ready,03-shared-resonance,04-transition}.png" % PREFIX)
	quit(0)


func _reach_echo_threshold(
	act: Act01Sequence,
	player: PlayerController,
	tie_line: TieLine,
	dialogue: DialogueUI
) -> void:
	act._finish_umbrella_scene()
	player.set_logical_position(Vector3(15.2, 0.0, 2.0))
	while act.current_beat != Act01Sequence.Beat.FIRST_PULL:
		await physics_frame

	player.set_logical_position(Vector3(16.8, 0.0, 1.0))
	while act.current_beat != Act01Sequence.Beat.WAIT_PROBE_REARM:
		await physics_frame
	dialogue.advance()
	dialogue.advance()
	while act.current_beat != Act01Sequence.Beat.LINE_PROBE:
		await physics_frame

	act._on_empty_interact_pressed()
	act.debug_finish_line_probe()
	dialogue._finish_immediately(true)
	player.set_logical_position(Vector3(13.0, 0.0, 3.0))
	while act.current_beat != Act01Sequence.Beat.FINAL_ATTEMPT:
		await physics_frame

	player.set_logical_position(Vector3(17.0, 0.0, 1.0))
	while act.current_beat != Act01Sequence.Beat.AFTER_PROBE:
		await physics_frame
	assert(tie_line.enabled)


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


func _seconds(duration: float) -> void:
	await create_timer(duration).timeout


func _snap_line_reveal(camera_rig: CameraRig, room: RoomBase) -> void:
	var view := room.get_camera_point(&"LineRevealView")
	assert(view != null)
	camera_rig.stop_following()
	camera_rig.camera.position_smoothing_enabled = false
	camera_rig.snap_to(view, Vector2(1.05, 1.05))
	camera_rig.camera.force_update_scroll()
