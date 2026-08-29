extends SceneTree

const PREFIX := "/tmp/echoes-chapter3"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/chapter3/chapter3.tscn") as PackedScene
	var chapter := packed.instantiate() as Chapter3Game
	root.add_child(chapter)
	await _frames(4)
	await _save("%s-title.png" % PREFIX)

	chapter.start_game()
	await _physics_frames(3)
	await _save("%s-level1.png" % PREFIX)

	chapter.debug_load_level(1)
	await _physics_frames(3)
	await _save("%s-level2.png" % PREFIX)

	chapter.debug_load_level(2)
	await _physics_frames(3)
	await _save("%s-level3.png" % PREFIX)

	print("[CAPTURE] %s-{title,level1,level2,level3}.png" % PREFIX)
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
