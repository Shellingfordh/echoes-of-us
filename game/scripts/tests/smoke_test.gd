extends SceneTree

var _failures := 0
var _game: Node2D
var _player: CharacterBody2D
var _companion: Node2D
var _tie_line: Line2D
var _umbrella: Area2D
var _world: Node2D
var _audio: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/main/main.tscn") as PackedScene
	_check(packed_scene != null, "main scene loads")
	if packed_scene == null:
		quit(1)
		return

	_game = packed_scene.instantiate()
	_game.set("test_mode", true)
	root.add_child(_game)
	await _frames(3)

	_player = _game.get_node_or_null("Player") as CharacterBody2D
	_companion = _game.get_node_or_null("Mother") as Node2D
	_tie_line = _game.get_node_or_null("TieLine") as Line2D
	_umbrella = _game.get_node_or_null("Umbrella") as Area2D
	_world = _game.get_node_or_null("GrayboxWorld") as Node2D
	_audio = _game.get_node_or_null("AudioDirector")
	_check(_player != null, "player exists")
	_check(_companion != null, "companion exists")
	_check(_tie_line != null, "tie line exists")
	_check(_umbrella != null, "umbrella exists")
	_check(_world != null, "full demo world exists")
	_check(_audio != null, "procedural audio director exists")
	var dialogue_catalog = _game.get("dialogue_catalog")
	_check(dialogue_catalog != null and int(dialogue_catalog.call("size")) >= 61, "dialogue catalog loads all D001-D040 entries and runtime fragments")
	var has_all_story_ids := true
	for dialogue_number in range(1, 41):
		has_all_story_ids = has_all_story_ids and bool(dialogue_catalog.call("has_entry", "D%03d" % dialogue_number))
	_check(has_all_story_ids, "the stable D001-D040 story ID range is complete")
	var opening_entry: Dictionary = _game.call("get_dialogue_entry", "D001")
	_check(str(opening_entry.get("text", "")).contains("二十多年"), "stable dialogue IDs resolve authored text")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	_check(main_source.count("show_dialogue(") == 1, "gameplay code routes authored lines through dialogue IDs")
	if _failures > 0:
		quit(1)
		return

	await _test_act_one()
	await _test_act_two()
	await _test_act_three()
	await _test_act_four()

	var snapshot: Dictionary = _game.call("get_completion_snapshot")
	_check(snapshot.phase == "complete", "the full demo reaches its ending")
	_check(snapshot.act == 4, "completion is in Act 4")
	_check(snapshot.core_items == 3, "all required room objects were inspected")
	_check(snapshot.fragments == 5, "all five optional memory fragments persist to the ending")
	_check(snapshot.echoes == 3, "all three hidden echo points persist to the ending")
	_check(snapshot.key_connected, "the stranger was reconnected to the key")
	_check(snapshot.tie_state == "Extending", "the ending keeps the tie line extending")

	if _failures == 0:
		print("[SmokeTest] PASS - all four acts load and complete")
	var exit_code := 1 if _failures > 0 else 0
	_audio.call("shutdown")
	_game.queue_free()
	await _frames(3)
	quit(exit_code)


func _test_act_one() -> void:
	_check(_phase() == "act1_explore", "Act 1 starts with room exploration")
	_check(_tie_line.call("get_state_name") == "Hidden", "Act 1 tie line starts hidden")
	_check(_audio.get("current_mood") == "home", "Act 1 starts with the home ambience")

	# The desk owns interaction priority; a second interaction reveals its ticket fragment.
	_player.global_position = _world.call("get_point", "desk")
	_sync_interaction()
	_player.emit_signal("interaction_requested")
	await _frames(2)

	for fragment_id in ["fragment_ticket", "fragment_height", "fragment_boots"]:
		_player.global_position = _world.call("get_point", fragment_id)
		_sync_interaction()
		_player.emit_signal("interaction_requested")
		await _frames(2)

	_player.global_position = _world.call("get_point", "chair")
	_sync_interaction()
	_player.emit_signal("interaction_requested")
	await _frames(2)
	_player.global_position = _world.call("get_point", "fragment_frame")
	_sync_interaction()
	_player.emit_signal("interaction_requested")
	await _frames(2)
	_player.global_position = _world.call("get_point", "fragment_earphones")
	_sync_interaction()
	_player.emit_signal("interaction_requested")
	await _frames(2)

	for echo_id in ["echo_kitchen", "echo_door", "echo_hall"]:
		_player.global_position = _world.call("get_point", echo_id)
		_player.velocity = Vector2.ZERO
		_game.call("_update_echo_points", 1.6)
		await _frames(2)

	_check(int(_game.get("fragments_found")) == 5, "all five memory fragments can be collected")
	_check(int(_game.get("echoes_found")) == 3, "all three echo points can be heard by waiting")
	_check(_audio.get("last_cue") == "echo", "hidden echoes produce an audio cue")

	for item_id in ["box", "suitcase"]:
		_player.global_position = _world.call("get_point", item_id)
		_sync_interaction()
		_player.emit_signal("interaction_requested")
		await _frames(2)
	await _wait_for_phase("act1_walk", 0.8)
	_check(_phase() == "act1_walk", "three inspections trigger the umbrella conflict and release movement")

	_player.global_position = Vector2(650.0, 470.0)
	await _frames(3)
	_check(_phase() == "act1_tie", "distance reveals the tie line")
	_check(_tie_line.call("get_state_name") == "Tense", "Act 1 line becomes Tense")

	_player.global_position = Vector2(1070.0, 470.0)
	await create_timer(0.12).timeout
	_check(_phase() == "act1_umbrella", "maximum tension pulls the player back to the umbrella")
	_player.global_position = _umbrella.global_position + Vector2(30.0, 0.0)
	_sync_interaction()
	_player.emit_signal("interaction_requested")
	await create_timer(0.18).timeout
	_check(_phase() == "act2_bicycle", "the yellow umbrella transitions into Act 2")


func _test_act_two() -> void:
	_check(_player.get("role_name") == "年轻母亲", "Act 2 begins from the young mother's perspective")
	_check(_tie_line.call("get_state_name") == "Adjustable", "memory starts with an Adjustable line")
	_check(_audio.get("current_mood") == "memory", "Act 2 switches to rain ambience")

	_player.global_position = _world.get("bicycle_position") + Vector2(0.0, 55.0)
	await _hold(&"move_up", 0.75)
	await create_timer(0.08).timeout
	_check(_phase() == "act2_puddle", "mother can push the bicycle aside")

	_player.global_position = _companion.global_position + Vector2(-120.0, 0.0)
	await create_timer(0.12).timeout
	_check(_phase() == "act2_cabinet_child", "approaching the child relaxes the line and clears the puddle")

	await _tap(&"switch_character")
	_check(_player.get("role_name") == "小女儿", "Tab switches control to the little daughter")
	_player.global_position = Vector2(1280.0, 500.0)
	await _frames(3)
	_check(_phase() == "act2_cabinet_mother", "the little daughter crawls through and opens the gate")
	await _tap(&"switch_character")
	_player.global_position = Vector2(1340.0, 500.0)
	await _frames(3)
	_check(_phase() == "act2_anchor", "mother passes the opened gate and reaches anchor training")

	_player.global_position = _world.call("get_point", "memory_lamp")
	_sync_interaction()
	_player.emit_signal("interaction_requested")
	await _frames(2)
	_check(int(_world.get("anchor_index")) == 1, "the memory lamp bends the tie line")
	await _tap(&"switch_character")
	await _hold(&"move_up", 0.08)
	await create_timer(0.22).timeout
	_check(_phase() == "act3_attach", "anchor crossing and farewell complete Act 2")


func _test_act_three() -> void:
	_player.global_position = _umbrella.global_position + Vector2(25.0, 0.0)
	_sync_interaction()
	_player.emit_signal("interaction_requested")
	await create_timer(0.16).timeout
	_check(_phase() == "act3_corridor_1", "the daughter attaches her line and enters the corridor")

	_player.global_position = _world.call("get_point", "corridor_anchor_1")
	_sync_interaction()
	_player.emit_signal("interaction_requested")
	await _tap(&"switch_character")
	await _hold(&"move_up", 0.08)
	await create_timer(0.08).timeout
	_check(bool(_world.get("gate_one_open")), "first corridor anchor opens the high-plate gate")
	await _tap(&"switch_character")
	_player.global_position = Vector2(960.0, 490.0)
	await _frames(3)
	_check(_phase() == "act3_corridor_2", "mother crosses the first corridor gate")

	await _tap(&"switch_character")
	_player.global_position = _world.call("get_point", "corridor_anchor_2")
	_sync_interaction()
	_player.emit_signal("interaction_requested")
	await _tap(&"switch_character")
	await _hold(&"move_up", 0.08)
	await create_timer(0.16).timeout
	_check(_phase() == "act3_warehouse_box_1", "reciprocal anchoring completes the corridor")

	_player.global_position = _world.get("box_one_position") + Vector2(0.0, 55.0)
	await _hold(&"move_up", 0.75)
	await _frames(3)
	_check(_phase() == "act3_warehouse_crawl", "mother pushes the first warehouse box onto its plate")
	await _tap(&"switch_character")
	_player.global_position = Vector2(1000.0, 500.0)
	await _frames(3)
	_check(_phase() == "act3_warehouse_box_2", "daughter crawls through the narrow warehouse path")
	await _tap(&"switch_character")
	_player.global_position = _world.get("box_two_position") - Vector2(55.0, 0.0)
	await _hold(&"move_right", 0.8)
	await create_timer(0.14).timeout
	_check(_phase() == "act3_rooftop", "the second box fills the gap and opens the rooftop")

	# Rooftop alternates: mother anchors, daughter crosses; daughter anchors, mother crosses; mother anchors, daughter crosses.
	for step in range(3):
		var anchor_id := "rooftop_anchor_%d" % (step + 1)
		_player.global_position = _world.call("get_point", anchor_id)
		_sync_interaction()
		_player.emit_signal("interaction_requested")
		await _tap(&"switch_character")
		await _hold(&"move_up", 0.08)
		await create_timer(0.08).timeout
	await create_timer(0.14).timeout
	_check(_phase() == "act3_street", "three alternating anchors complete the rooftop")

	_player.global_position = _world.call("get_point", "stranger")
	await _frames(3)
	_check(_phase() == "act3_street_key", "approaching the stranger reveals another person's line")
	_player.global_position = _world.call("get_point", "flowerbed")
	_sync_interaction()
	_player.emit_signal("interaction_requested")
	await _frames(3)
	_check(bool(_world.get("key_connected")), "the flowerbed key reconnects to the stranger")
	_player.global_position = Vector2(1360.0, 500.0)
	await create_timer(0.16).timeout
	_check(_phase() == "act4_run", "leaving the street enters Act 4")


func _test_act_four() -> void:
	_check(_tie_line.call("get_state_name") == "Extending", "Act 4 removes resistance and extends the line")
	_check(_audio.get("current_mood") == "run", "Act 4 switches to the running ambience")
	_player.global_position = Vector2(760.0, 500.0)
	await _frames(3)
	_player.global_position = Vector2(1540.0, 500.0)
	await create_timer(0.12).timeout
	_check(_phase() == "act4_run", "mother cutaway returns control to the daughter")
	_player.global_position = Vector2(2700.0, 500.0)
	await create_timer(0.18).timeout
	_check(_phase() == "complete", "running into the light completes the ending")


func _phase() -> String:
	return _game.call("get_phase_name")


func _sync_interaction() -> void:
	_game.call("_update_interaction_prompt")


func _wait_for_phase(expected: String, timeout: float) -> void:
	var elapsed := 0.0
	while _phase() != expected and elapsed < timeout:
		await create_timer(0.02).timeout
		elapsed += 0.02


func _hold(action: StringName, duration: float) -> void:
	Input.action_press(action)
	await create_timer(duration).timeout
	Input.action_release(action)
	await _frames(2)


func _tap(action: StringName) -> void:
	var pressed := InputEventAction.new()
	pressed.action = action
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await _frames(2)
	var released := InputEventAction.new()
	released.action = action
	released.pressed = false
	Input.parse_input_event(released)
	await _frames(2)


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(condition: bool, description: String) -> void:
	if condition:
		print("[SmokeTest] PASS - %s" % description)
	else:
		_failures += 1
		push_error("[SmokeTest] FAIL - %s" % description)
