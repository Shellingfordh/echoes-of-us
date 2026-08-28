extends SceneTree

const PREFIX := "/tmp/echoes-chapter1-audit-round4-after"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await _frames(8)

	var room := main.get_node("World/Chapter01Room01")
	var player := main.get_node("Player") as PlayerController
	var act := main.get_node("Act01Sequence") as Act01Sequence
	var dialogue := main.get_node("UI/DialogueUI") as DialogueUI
	var object_info := main.get_node("UI/ObjectInfoUI") as ObjectInfoUI
	var observation := main.get_node("UI/FixedObservationUI") as FixedObservationUI
	var photo := room.get_node("Interactables/PhotoFrame") as Interactable
	var stool := room.get_node("Interactables/Stool") as Interactable
	var camera_rig := main.get_node("CameraRig") as CameraRig

	dialogue.characters_per_second = 0.0
	dialogue.monologue_hold_seconds = 0.0
	dialogue.fade_duration = 0.0
	act.stool_move_duration = 0.0

	await _finish_standard(room.get_node("Interactables/PackingBox") as Interactable, player, object_info, dialogue)
	await _finish_standard(room.get_node("Interactables/Suitcase") as Interactable, player, object_info, dialogue)
	(room.get_node("Interactables/Headphones") as Interactable).interact(player)
	await _frames(2)
	observation.close_observation()
	await _frames(2)
	player.set_logical_position(Vector3(8.0, 0.0, 7.5))
	_snap_room(camera_rig, room)
	await _physics_frames(5)
	await _save("%s-01-two-remaining.png" % PREFIX)

	await _finish_standard(room.get_node("Interactables/Desk") as Interactable, player, object_info, dialogue)
	player.set_logical_position(Vector3(8.0, 0.0, 7.5))
	_snap_room(camera_rig, room)
	await _physics_frames(5)
	await _save("%s-02-one-remaining.png" % PREFIX)

	stool.interact(player)
	await _frames(2)
	photo.interact(player)
	await _frames(30)
	assert(observation.is_open())
	await _save("%s-03-final-object-open.png" % PREFIX)

	print("[CAPTURE] %s-{01-two-remaining,02-one-remaining,03-final-object-open}.png" % PREFIX)
	quit(0)


func _finish_standard(
	target: Interactable,
	player: PlayerController,
	object_info: ObjectInfoUI,
	dialogue: DialogueUI
) -> void:
	target.interact(player)
	await _frames(2)
	object_info.advance()
	await _frames(2)
	if dialogue.is_playing():
		dialogue._finish_immediately(true)
	await _frames(2)


func _save(path: String) -> void:
	# Metal 在相机模式刚切换后的首帧可能仍带上一帧的 Canvas 变换；
	# 连续等待两次绘制，只接收稳定后的实际游戏画面。
	await RenderingServer.frame_post_draw
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


func _snap_room(camera_rig: CameraRig, room: RoomBase) -> void:
	var room_view := room.get_camera_point(&"RoomView")
	assert(room_view != null)
	camera_rig.set_process(false)
	camera_rig.camera.position_smoothing_enabled = false
	camera_rig.snap_to(room_view, Vector2.ONE)
	camera_rig.camera.force_update_scroll()
