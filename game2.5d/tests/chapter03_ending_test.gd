extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/chapter3/chapter3.tscn") as PackedScene
	assert(packed != null)
	var chapter := packed.instantiate() as Chapter3Game
	root.add_child(chapter)
	current_scene = chapter
	await process_frame

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

	var automatic_transition_steps := ceili(
		((Chapter3Game.END_SCRIPT.size() - 1) * Chapter3Game.ENDING_LINE_DURATION + Chapter3Game.ENDING_FINAL_HOLD_DURATION + 0.2)
		/ (1.0 / 30.0)
	)
	for _step in range(automatic_transition_steps):
		chapter._physics_process(1.0 / 30.0)
	assert(chapter.ending_phase == Chapter3Game.EndingPhase.TRANSITIONING)
	await process_frame
	await process_frame

	var chapter_four := current_scene as CinematicPlayer
	assert(chapter_four != null, "third chapter did not load the fourth chapter cinematic")
	assert(chapter_four.chapter_number == 4)
	assert(chapter_four.video_player.stream != null)
	assert(root.get_node("GameSession").is_chapter_completed(3))

	print("[CHAPTER03_ENDING] PASS story close and automatic chapter four transition")
	quit(0)
