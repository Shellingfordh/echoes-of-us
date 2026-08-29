extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session := root.get_node_or_null("GameSession")
	assert(session != null, "GameSession autoload is missing")
	session.reset()
	assert(session.current_chapter == 1)
	assert(session.completed_chapters.is_empty())

	session.set_flag(&"chapter_01_photo_unlocked")
	session.complete_chapter(1)
	session.enter_chapter(2)
	assert(session.current_chapter == 2)
	assert(session.is_chapter_completed(1))
	assert(session.has_flag(&"chapter_01_photo_unlocked"))

	# The singleton remains alive while scene roots are replaced.
	var first_scene := Node.new()
	first_scene.name = "FirstScene"
	root.add_child(first_scene)
	current_scene = first_scene
	first_scene.queue_free()
	await process_frame
	var second_scene := Node.new()
	second_scene.name = "SecondScene"
	root.add_child(second_scene)
	current_scene = second_scene
	assert(root.get_node("GameSession") == session)
	assert(session.current_chapter == 2)
	assert(session.is_chapter_completed(1))

	session.complete_chapter(2)
	session.enter_chapter(3)
	assert(session.current_chapter == 3)
	assert(session.completed_chapters == [1, 2])

	print("[GAME_SESSION] PASS chapter progress and story flags survive scene replacement")
	quit(0)
