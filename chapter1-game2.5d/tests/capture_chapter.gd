extends SceneTree

const PREFIX := "/tmp/echoes-chapter1-audit-after"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await _frames(8)
	await _save("%s-room.png" % PREFIX)

	var room := main.get_node("World/Chapter01Room01")
	var player := main.get_node("Player") as PlayerController
	var observation := main.get_node("UI/FixedObservationUI") as FixedObservationUI
	(room.get_node("Interactables/WindowInspect") as Interactable).interact(player)
	await _frames(4)
	await _save("%s-observation.png" % PREFIX)
	observation.close_observation()

	var act := main.get_node("Act01Sequence") as Act01Sequence
	var tie_line := main.get_node("TieLine") as TieLine
	var mother := room.get_node("Characters/Mother") as Mother
	mother.visible = true
	mother.set_logical_position(act.mother_after_dialogue_position)
	player.set_logical_position(Vector3(15.4, 0.0, 2.0))
	act.current_beat = Act01Sequence.Beat.LINE_PROBE
	tie_line.set_enabled(true)
	act._enter_p3_line_reveal()
	act._begin_line_probe()
	Input.action_press(&"interact")
	Input.action_press(&"move_right")
	await _physics_frames(8)
	Input.action_release(&"move_right")
	Input.action_release(&"interact")
	await _frames(3)
	await _save("%s-grounded-probe.png" % PREFIX)

	print("[CAPTURE] %s-{room,observation,grounded-probe}.png" % PREFIX)
	quit(0)


func _save(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	assert(error == OK)


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _physics_frames(count: int) -> void:
	for _index in range(count):
		await physics_frame
