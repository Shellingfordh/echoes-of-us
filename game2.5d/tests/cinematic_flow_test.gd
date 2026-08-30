extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session := root.get_node("GameSession")
	session.complete_chapter(1)
	session.enter_chapter(3)

	var prologue_packed := load("res://scenes/cinematics/prologue.tscn") as PackedScene
	assert(prologue_packed != null)
	var prologue := prologue_packed.instantiate() as CinematicPlayer
	root.add_child(prologue)
	current_scene = prologue
	await process_frame
	assert(prologue.reset_session_on_ready)
	assert(prologue.chapter_number == 0)
	assert(prologue.video_player.stream != null)
	assert(prologue.video_player.get_stream_length() > 60.0)
	assert(session.current_chapter == 1)
	assert(session.completed_chapters.is_empty(), "prologue must reset prior progress")

	if DisplayServer.get_name() == "headless":
		prologue._finish_cinematic(false)
	else:
		await _seek_to_video_end(prologue)
	await process_frame
	await process_frame
	assert(current_scene != null and current_scene.scene_file_path == "res://scenes/main/main.tscn")
	assert(session.current_chapter == 1)

	var first_chapter := current_scene
	current_scene = null
	first_chapter.queue_free()
	await process_frame

	var chapter_four_packed := load("res://scenes/cinematics/chapter4.tscn") as PackedScene
	assert(chapter_four_packed != null)
	var chapter_four := chapter_four_packed.instantiate() as CinematicPlayer
	root.add_child(chapter_four)
	current_scene = chapter_four
	await process_frame
	assert(chapter_four.chapter_number == 4)
	assert(chapter_four.video_player.stream != null)
	assert(chapter_four.video_player.get_stream_length() > 50.0)
	assert(session.current_chapter == 4)
	assert(chapter_four.auto_replay)

	if DisplayServer.get_name() == "headless":
		chapter_four._on_video_finished()
	else:
		await _seek_to_video_end(chapter_four, true)
	assert(session.is_chapter_completed(4))
	assert(chapter_four.playback_state == CinematicPlayer.PlaybackState.PLAYING)
	assert(not chapter_four.complete_hint.visible)
	assert(not chapter_four.final_card.visible)
	assert(chapter_four.video_player.visible)
	assert(chapter_four.skip_hint.visible)
	assert(chapter_four.skip_hint.text == "Enter / Space：从头播放第四章\nR：返回序章")

	print("[CINEMATIC_FLOW] PASS prologue, first-chapter transition and automatic chapter four replay")
	quit(0)


func _seek_to_video_end(cinematic: CinematicPlayer, expect_replay := false) -> void:
	var stream_length := cinematic.video_player.get_stream_length()
	assert(stream_length > 1.0)
	cinematic.video_player.stream_position = stream_length - 1.5
	if not cinematic.video_player.is_playing():
		cinematic.video_player.play()
	var deadline := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < deadline:
		if not is_instance_valid(cinematic):
			break
		if expect_replay:
			var session := root.get_node("GameSession")
			if session.is_chapter_completed(cinematic.chapter_number) and cinematic.video_player.stream_position < 5.0:
				break
		elif cinematic.playback_state != CinematicPlayer.PlaybackState.PLAYING:
			break
		await process_frame
	if expect_replay:
		assert(is_instance_valid(cinematic), "replaying cinematic was freed")
		assert(root.get_node("GameSession").is_chapter_completed(cinematic.chapter_number))
		assert(cinematic.playback_state == CinematicPlayer.PlaybackState.PLAYING)
		assert(cinematic.video_player.stream_position < 5.0, "cinematic did not restart from the beginning")
	else:
		assert(
			not is_instance_valid(cinematic) or cinematic.playback_state != CinematicPlayer.PlaybackState.PLAYING,
			"cinematic did not reach its real finished signal"
		)
