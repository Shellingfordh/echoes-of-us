extends SceneTree

var _failures := 0
var _game: Node3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	_check(scene != null, "main scene loads")
	if scene == null:
		quit(1)
		return
	_game = scene.instantiate() as Node3D
	_game.set("test_mode", true)
	root.add_child(_game)
	await _frames(5)

	var player := _game.get_node("Player") as CharacterBody3D
	var camera := _game.get_node("CameraRig/Camera3D") as Camera3D
	var tie_line := _game.get_node("TieLine3D") as Node3D
	_check(player != null, "player is a real CharacterBody3D")
	_check(camera != null and camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "orthographic 3D camera establishes the 2.5D view")
	_check(_game.get_node_or_null("Room/Floor") is MeshInstance3D, "room is built from depth-aware 3D geometry")
	_check(float(player.get("z_bounds").y - player.get("z_bounds").x) > 2.0, "player can move through foreground and background depth")
	_check(tie_line != null, "3D tie line exists")
	_check(int(_game.get("required_done")) == 0, "chapter starts before the five required investigations")
	player.global_position = Vector3(0.0, 0.0, -1.4)
	await _frames(2)
	_check(player.global_position.z < -1.0, "background lane movement remains available")
	player.global_position = Vector3(0.0, 0.0, 1.35)
	await _frames(2)
	_check(player.global_position.z > 1.0, "foreground lane movement remains available")

	for dialogue_id in _expected_dialogue_ids():
		_check(bool(_game.call("dialogue_has", dialogue_id)), "dialogue %s exists" % dialogue_id)

	_game.call("debug_interact", "window")
	await _frames(2)
	_check(_phase() == "observation", "window enters fixed observation")
	_game.call("debug_close_observation")
	_game.call("debug_interact", "wardrobe")
	_game.call("debug_interact", "boxes")
	_game.call("debug_interact", "suitcase")
	_game.call("debug_interact", "desk")
	_game.call("debug_interact", "earphones")
	await _frames(2)
	_check(_phase() == "observation", "earphones use the same fixed observation grammar")
	_game.call("debug_close_observation")
	_game.call("debug_interact", "stool")
	_check(bool(_game.get("photo_unlocked")), "moving the stool unlocks the high photo")
	_game.call("debug_interact", "photo")
	await _frames(2)
	_game.call("debug_close_observation")
	_check(int(_game.get("required_done")) == 5, "all five canon investigations are required")

	await _wait_for_phase("p2_after_conflict", 1.0)
	_check(_phase() == "p2_after_conflict", "five investigations trigger the complete yellow-umbrella conflict")
	_check((_game.get_node("Props/YellowUmbrella") as Node3D).visible, "the old yellow umbrella remains by the door")
	_game.call("debug_interact", "suitcase_p2")
	_game.call("debug_interact", "umbrella_p2")

	_game.call("debug_force_first_critical")
	await _wait_for_phase("p3_research", 0.8)
	_check(_phase() == "p3_research", "first maximum tension produces a forced pullback")
	_check((tie_line.call("state_name") as String) == "Tense", "the relationship line remains visibly tense")

	_game.call("debug_force_second_critical")
	await _wait_for_phase("suspended", 0.5)
	_check(_phase() == "suspended", "the second attempt lifts the daughter into suspension")
	await create_timer(0.08).timeout
	_game.call("debug_finish_suspension")
	await _wait_for_phase("p3_after_support", 0.6)
	_check(_phase() == "p3_after_support", "support and limited swing return control beside the umbrella")

	_game.call("debug_interact", "line_thread")
	_game.call("debug_interact", "umbrella_final")
	await _wait_for_phase("complete", 0.5)
	_check(_phase() == "complete", "touching the umbrella completes Chapter One at the echo threshold")

	var seen := _game.get("seen_dialogue_ids") as Dictionary
	for dialogue_id in _expected_dialogue_ids():
		_check(seen.has(dialogue_id), "playable flow routes %s" % dialogue_id)

	var exit_code := 1 if _failures > 0 else 0
	_game.queue_free()
	await _frames(3)
	quit(exit_code)


func _expected_dialogue_ids() -> Array[String]:
	var ids: Array[String] = []
	for number in range(1, 19):
		ids.append("D%03d" % number)
	for number in range(41, 48):
		ids.append("D%03d" % number)
	return ids


func _phase() -> String:
	return str(_game.call("phase_name"))


func _wait_for_phase(expected: String, timeout: float) -> void:
	var elapsed := 0.0
	while _phase() != expected and elapsed < timeout:
		await create_timer(0.01).timeout
		elapsed += 0.01


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[ChapterOne25D] PASS - %s" % message)
	else:
		_failures += 1
		push_error("[ChapterOne25D] FAIL - %s" % message)
