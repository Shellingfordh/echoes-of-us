extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session := root.get_node("GameSession")
	session.reset()

	var main_packed := load("res://scenes/main/main.tscn") as PackedScene
	var main_scene := main_packed.instantiate()
	root.add_child(main_scene)
	current_scene = main_scene
	await process_frame
	assert(session.current_chapter == 1, "first chapter did not register itself")
	current_scene = null
	main_scene.queue_free()
	await process_frame

	var chapter_two_packed := load("res://scenes/chapter2/chapter2.tscn") as PackedScene
	var chapter_two := chapter_two_packed.instantiate() as Chapter2Sequence
	chapter_two.debug_skip_intro = true
	root.add_child(chapter_two)
	current_scene = chapter_two
	await process_frame
	assert(session.current_chapter == 2, "second chapter did not register itself")

	await chapter_two._finish_chapter()
	assert(session.is_chapter_completed(2), "second chapter completion was not persisted")
	assert(chapter_two.current_stage == Chapter2Sequence.Stage.COMPLETE)
	chapter_two._start_chapter_three()
	await process_frame
	await process_frame

	var chapter_three := current_scene as Chapter3Game
	assert(chapter_three != null, "second chapter did not load the third chapter scene")
	assert(session.current_chapter == 3, "third chapter entry was not persisted")
	chapter_three.start_game()
	chapter_three.debug_load_level(2)
	for door: Dictionary in chapter_three.level["doors"]:
		door["open"] = true
	chapter_three.daughter["x"] = chapter_three.level["exit_x"] + 100.0
	chapter_three.mother["x"] = chapter_three.level["exit_x"] + 100.0
	chapter_three._check_level_complete()
	assert(session.is_chapter_completed(3), "third chapter completion was not persisted")
	chapter_three._start_chapter_four()
	await process_frame
	await process_frame

	var chapter_four := current_scene as CinematicPlayer
	assert(chapter_four != null, "third chapter did not load the fourth chapter cinematic")
	assert(session.current_chapter == 4, "fourth chapter entry was not persisted")
	chapter_four._finish_cinematic(false)
	assert(session.is_chapter_completed(4), "fourth chapter completion was not persisted")
	assert(chapter_four.playback_state == CinematicPlayer.PlaybackState.COMPLETE)

	var main_script := FileAccess.get_file_as_string("res://scripts/main/main.gd")
	assert(main_script.contains("complete_chapter(1)"))
	assert(main_script.contains("change_scene_to_file(\"res://scenes/chapter2/chapter2.tscn\")"))

	print("[CHAPTER_PROGRESSION] PASS chapters 1-4 share one session and scene chain")
	quit(0)
