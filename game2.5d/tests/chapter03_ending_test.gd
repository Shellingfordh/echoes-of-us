extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/chapter3/chapter3.tscn") as PackedScene
	assert(packed != null)
	var chapter := packed.instantiate() as Chapter3Game
	root.add_child(chapter)
	await process_frame

	var ending_video := chapter.get_node("HUD/EndingVideo") as VideoStreamPlayer
	var ending_controls := chapter.get_node("HUD/EndingControls") as Label
	assert(ending_video != null and ending_video.stream != null, "ending video must be embedded in the project")
	assert(not ending_video.visible)
	assert(not ending_controls.visible)

	chapter.start_game()
	chapter.debug_load_level(2)
	for door: Dictionary in chapter.level["doors"]:
		door["open"] = true
	chapter.daughter["x"] = chapter.level["exit_x"] + 100.0
	chapter.mother["x"] = chapter.level["exit_x"] + 100.0
	chapter._check_level_complete()
	assert(chapter.game_state == Chapter3Game.GameState.END)
	assert(chapter.ending_phase == Chapter3Game.EndingPhase.STORY)
	assert(chapter.end_index == 0)

	var automatic_movie_steps := ceili(
		((Chapter3Game.END_SCRIPT.size() - 1) * Chapter3Game.ENDING_LINE_DURATION + Chapter3Game.ENDING_FINAL_HOLD_DURATION + 0.2)
		/ (1.0 / 30.0)
	)
	for _step in range(automatic_movie_steps):
		chapter._physics_process(1.0 / 30.0)
	assert(chapter.ending_phase == Chapter3Game.EndingPhase.MOVIE)
	assert(ending_video.visible)
	assert(not ending_controls.visible)

	if DisplayServer.get_name() == "headless":
		chapter._finish_ending_movie(false)
	else:
		var playback_deadline := Time.get_ticks_msec() + 10000
		while chapter.ending_phase == Chapter3Game.EndingPhase.MOVIE and Time.get_ticks_msec() < playback_deadline:
			await process_frame
	assert(chapter.ending_phase == Chapter3Game.EndingPhase.COMPLETE)
	assert(ending_video.visible == (DisplayServer.get_name() != "headless"))
	assert(ending_controls.visible)

	chapter.start_game()
	assert(chapter.game_state == Chapter3Game.GameState.PLAY)
	assert(chapter.ending_phase == Chapter3Game.EndingPhase.STORY)
	assert(not ending_video.visible)
	assert(not ending_controls.visible)

	print("[CHAPTER03_ENDING] PASS story, movie, final card and restart flow")
	quit(0)
