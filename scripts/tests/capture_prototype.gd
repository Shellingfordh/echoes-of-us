extends SceneTree

const DEFAULT_OUTPUT := "/tmp/echoes-of-us-prototype.png"


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var packed_scene := load("res://scenes/main/main.tscn") as PackedScene
	if packed_scene == null:
		push_error("[Capture] main scene could not be loaded")
		quit(1)
		return

	var prototype := packed_scene.instantiate()
	root.add_child(prototype)
	await create_timer(4.5).timeout

	# Capture the central mechanic at a readable, non-critical tension value.
	var player := prototype.get_node("Player") as CharacterBody2D
	player.global_position = Vector2(860.0, 470.0)
	await create_timer(1.2).timeout
	await process_frame

	var output_path := DEFAULT_OUTPUT
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		output_path = user_args[0]

	var image := root.get_texture().get_image()
	var error := image.save_png(output_path)
	if error != OK:
		push_error("[Capture] failed to save %s (error %d)" % [output_path, error])
		quit(1)
		return

	print("[Capture] saved %s" % output_path)
	quit(0)
