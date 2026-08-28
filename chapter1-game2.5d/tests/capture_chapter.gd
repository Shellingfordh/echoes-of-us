extends SceneTree

const PREFIX := "/tmp/echoes-chapter1-audit-round6-after"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await _frames(8)

	var player := main.get_node("Player") as PlayerController
	var act := main.get_node("Act01Sequence") as Act01Sequence
	var dialogue := main.get_node("UI/DialogueUI") as DialogueUI
	var hint := main.get_node("UI/InteractionHint") as InteractionHint

	dialogue.characters_per_second = 0.0
	dialogue.monologue_hold_seconds = 30.0
	dialogue.fade_duration = 0.0
	act._finish_umbrella_scene()
	player.set_logical_position(Vector3(14.95, 0.0, 2.4))
	await _physics_frames(3)

	Input.action_press(&"move_right")
	while act.current_beat == Act01Sequence.Beat.P2_LEAVE:
		await physics_frame
	Input.action_release(&"move_right")
	assert(act.current_beat == Act01Sequence.Beat.LINE_REVEAL)
	await create_timer(1.0).timeout
	assert(act.current_beat == Act01Sequence.Beat.LINE_REVEAL)
	await _save("%s-01-clear-endpoints.png" % PREFIX)

	while act.current_beat != Act01Sequence.Beat.FIRST_PULL:
		await physics_frame
	Input.action_press(&"move_right")
	while act.current_beat != Act01Sequence.Beat.WAIT_PROBE_REARM:
		await physics_frame
	Input.action_release(&"move_right")
	for _index in range(30):
		await physics_frame
	assert(act.current_beat == Act01Sequence.Beat.WAIT_PROBE_REARM)
	assert(dialogue.is_playing() and dialogue._current_id == "D015")
	assert(not hint.visible)
	await _save("%s-02-reaction-before-prompt.png" % PREFIX)

	dialogue.advance()
	assert(dialogue._current_id == "D016")
	assert(act.current_beat == Act01Sequence.Beat.WAIT_PROBE_REARM)
	await _save("%s-03-recognize-line.png" % PREFIX)

	dialogue.advance()
	while act.current_beat != Act01Sequence.Beat.LINE_PROBE:
		await physics_frame
	await _physics_frames(2)
	assert(hint.visible and "抓住牵挂线" in hint.text)
	await _save("%s-04-probe-ready.png" % PREFIX)

	print("[CAPTURE] gated reaction IDs=D015,D016 prompt_after_dialogue=true")
	print("[CAPTURE] %s-{01-clear-endpoints,02-reaction-before-prompt,03-recognize-line,04-probe-ready}.png" % PREFIX)
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
