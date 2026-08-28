extends SceneTree

const PREFIX := "/tmp/echoes-chapter1-audit-round3-after"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await _frames(8)
	await _save("%s-01-room-entry.png" % PREFIX)

	var room := main.get_node("World/Chapter01Room01")
	var player := main.get_node("Player") as PlayerController
	var photo := room.get_node("Interactables/PhotoFrame") as Interactable
	var stool := room.get_node("Interactables/Stool") as Interactable
	var hint := main.get_node("UI/InteractionHint") as InteractionHint
	var camera_rig := main.get_node("CameraRig") as CameraRig

	player.set_logical_position(Vector3(3.0, 0.0, 3.0))
	_snap_camera(camera_rig, player)
	await _physics_frames(5)
	await _save("%s-02-photo-unreachable.png" % PREFIX)
	print(
		"[CAPTURE] before stool target=", player._current_interactable,
		" hint_visible=", hint.visible,
		" hint=", hint.text
	)

	player.set_logical_position(Vector3(4.35, 0.0, 3.85))
	_snap_camera(camera_rig, player)
	await _physics_frames(5)
	await _save("%s-03-stool-prompt.png" % PREFIX)
	print(
		"[CAPTURE] by stool target=", player._current_interactable,
		" hint_visible=", hint.visible,
		" hint=", hint.text
	)

	var stool_before := stool.get_logical_position()
	stool.interact(player)
	for _index in range(60):
		await physics_frame
		if photo.interaction_enabled:
			break
	await _physics_frames(3)
	await _save("%s-04-after-stool.png" % PREFIX)
	print(
		"[CAPTURE] after stool position_before=", stool_before,
		" position_after=", stool.get_logical_position(),
		" photo_enabled=", photo.interaction_enabled,
		" hint=", hint.text
	)

	print("[CAPTURE] %s-{01-room-entry,02-photo-unreachable,03-stool-prompt,04-after-stool}.png" % PREFIX)
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


func _snap_camera(camera_rig: CameraRig, player: PlayerController) -> void:
	camera_rig.global_position = player.global_position
	camera_rig.camera.reset_smoothing()
