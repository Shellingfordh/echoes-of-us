extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/main/main.tscn") as PackedScene
	_check(packed_scene != null, "main scene loads")
	if packed_scene == null:
		quit(1)
		return

	var prototype := packed_scene.instantiate()
	root.add_child(prototype)
	await process_frame
	await process_frame

	var player := prototype.get_node_or_null("Player") as CharacterBody2D
	var mother := prototype.get_node_or_null("Mother") as Node2D
	var tie_line := prototype.get_node_or_null("TieLine") as Line2D
	var umbrella := prototype.get_node_or_null("Umbrella") as Area2D
	_check(player != null, "player exists")
	_check(mother != null, "mother exists")
	_check(tie_line != null, "tie line exists")
	_check(umbrella != null, "umbrella exists")
	if _failures > 0:
		quit(1)
		return

	_check(tie_line.call("get_state_name") == "Hidden", "tie line starts hidden")

	# Follow the same order as a player: the intro owns input, then movement begins.
	await create_timer(4.5).timeout
	_check(prototype.call("_get_phase_name") == "walk_away", "intro releases player control")
	player.global_position = Vector2(650.0, 460.0)
	await process_frame
	await process_frame
	_check(tie_line.call("get_state_name") == "Tense", "distance reveals the tie line")
	_check(float(tie_line.get("distance")) >= 360.0, "distance is measured")

	player.global_position = Vector2(1055.0, 460.0)
	await create_timer(1.0).timeout
	_check(prototype.call("_get_phase_name") == "inspect_umbrella", "max tension pulls the player back")
	_check(player.global_position.distance_to(umbrella.global_position) < 100.0, "pullback lands near the umbrella")

	umbrella.emit_signal("inspected")
	await process_frame
	_check(prototype.call("_get_phase_name") == "complete", "umbrella interaction completes the vertical slice")

	if _failures == 0:
		print("[SmokeTest] PASS - vertical slice loads and completes")
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("[SmokeTest] PASS - %s" % description)
	else:
		_failures += 1
		push_error("[SmokeTest] FAIL - %s" % description)
