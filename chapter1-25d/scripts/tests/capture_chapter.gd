extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	var game := scene.instantiate()
	game.set("test_mode", true)
	root.add_child(game)
	await _settle()

	var prefix := "/tmp/echoes-chapter1-25d"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		prefix = args[0].trim_suffix(".png")

	await _save("%s-p1-room.png" % prefix)
	game.call("debug_interact", "window")
	await _settle()
	await _save("%s-fixed-observation.png" % prefix)
	game.call("debug_close_observation")
	game.call("debug_interact", "wardrobe")
	game.call("debug_interact", "boxes")
	game.call("debug_interact", "suitcase")
	game.call("debug_interact", "desk")
	game.call("debug_interact", "earphones")
	game.call("debug_close_observation")
	game.call("debug_interact", "stool")
	game.call("debug_interact", "photo")
	game.call("debug_close_observation")
	await _wait_phase(game, "p2_after_conflict", 1.0)
	await _settle()
	await _save("%s-p2-after-conflict.png" % prefix)

	var player := game.get_node("Player") as Node3D
	player.global_position = Vector3(4.15, 0.0, 0.75)
	game.call("_update_tie_mechanics")
	await _settle()
	await _save("%s-line-reveal.png" % prefix)

	game.call("debug_force_first_critical")
	await _wait_phase(game, "p3_research", 0.8)
	game.call("debug_force_second_critical")
	await _wait_phase(game, "suspended", 0.5)
	await create_timer(0.08).timeout
	await _save("%s-suspension.png" % prefix)

	game.call("debug_finish_suspension")
	await _wait_phase(game, "p3_after_support", 0.6)
	await _settle()
	await _save("%s-p3-after-support.png" % prefix)
	game.queue_free()
	await process_frame
	quit(0)


func _save(path: String) -> void:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		push_error("[Capture25D] could not save %s" % path)
	else:
		print("[Capture25D] saved %s" % path)


func _settle() -> void:
	await create_timer(0.18).timeout
	await process_frame


func _wait_phase(game: Node, expected: String, timeout: float) -> void:
	var elapsed := 0.0
	while str(game.call("phase_name")) != expected and elapsed < timeout:
		await create_timer(0.01).timeout
		elapsed += 0.01
