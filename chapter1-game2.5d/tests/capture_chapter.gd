extends SceneTree

const PREFIX := "/tmp/echoes-chapter1-audit-round5-after"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await _frames(8)

	var room := main.get_node("World/Chapter01Room01")
	var act := main.get_node("Act01Sequence") as Act01Sequence
	var dialogue := main.get_node("UI/DialogueUI") as DialogueUI
	var camera_rig := main.get_node("CameraRig") as CameraRig

	dialogue.characters_per_second = 0.0
	dialogue.fade_duration = 0.0
	_snap_room(camera_rig, room)
	act._start_umbrella_scene()
	await _frames(5)
	assert(dialogue._current_id == "D005")
	assert(dialogue.get_current_presentation_ids() == ["D005", "D006"])
	await _save("%s-01-opening.png" % PREFIX)

	var confirmations := 0
	while dialogue._current_id != "D011":
		dialogue.advance()
		confirmations += 1
		await _frames(2)
	assert(confirmations == 3)
	assert(dialogue.get_current_presentation_ids() == ["D011"])
	await _save("%s-02-real-question.png" % PREFIX)

	while dialogue._current_id != "D013":
		dialogue.advance()
		confirmations += 1
		await _frames(2)
	assert(confirmations == 5)
	assert(dialogue.get_current_presentation_ids() == ["D013", "D014"])
	await _save("%s-03-withdrawal.png" % PREFIX)

	print("[CAPTURE] grouped dialogue screens=6 confirmations_to_withdrawal=", confirmations)
	print("[CAPTURE] %s-{01-opening,02-real-question,03-withdrawal}.png" % PREFIX)
	quit(0)


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


func _snap_room(camera_rig: CameraRig, room: RoomBase) -> void:
	var room_view := room.get_camera_point(&"RoomView")
	assert(room_view != null)
	camera_rig.set_process(false)
	camera_rig.camera.position_smoothing_enabled = false
	camera_rig.snap_to(room_view, Vector2.ONE)
	camera_rig.camera.force_update_scroll()
