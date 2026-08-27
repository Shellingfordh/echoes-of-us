extends SceneTree

var _failures := 0
var _game: Node2D
var _player: CharacterBody2D
var _companion: Node2D
var _tie_line: Line2D
var _umbrella: Area2D
var _world: Node2D
var _audio: Node
var _ui: CanvasLayer


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
	_ui = _game.get_node_or_null("PrototypeUI") as CanvasLayer
	_check(_player != null, "player exists")
	_check(_companion != null, "companion exists")
	_check(_tie_line != null, "tie line exists")
	_check(_umbrella != null, "umbrella exists")
	_check(_world != null, "full demo world exists")
	_check(_audio != null, "procedural audio director exists")
	_check(_ui != null, "immersive UI exists")
	_check(_game.get_node_or_null("PrototypeUI/CompletionPanel/CompleteBox/CompleteRestartButton") != null, "completion offers a mouse and keyboard restart action")
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
	var all_spoken_story_ids_are_routed := true
	for dialogue_number in range(1, 41):
		var dialogue_id := "D%03d" % dialogue_number
		var entry: Dictionary = _game.call("get_dialogue_entry", dialogue_id)
		if not str(entry.get("text", "")).is_empty():
			all_spoken_story_ids_are_routed = all_spoken_story_ids_are_routed and main_source.contains('"%s"' % dialogue_id)
	_check(all_spoken_story_ids_are_routed, "every non-silent D001-D040 story line is routed by the playable flow")
	_check(bool(_ui.call("toggle_pause")) and paused, "pause menu suspends the game tree")
	_check(not bool(_ui.call("toggle_pause")) and not paused, "pause menu resumes the game tree")
	_check(bool(_ui.call("toggle_mute")) and bool(_audio.get("muted")), "sound accessibility toggle reaches the audio director")
	_ui.call("toggle_mute")
	_check(bool(_ui.call("toggle_reduced_motion")) and bool(_world.get("reduced_motion")) and bool(_tie_line.get("reduced_motion")), "reduced-motion setting reaches animated systems")
	_ui.call("toggle_reduced_motion")
	if _failures > 0:
		quit(1)
		return

	await _test_prologue()
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
	_check(snapshot.relationship_state == "Stable", "the ending preserves a stable, non-pulling relationship")
	_check(snapshot.epilogue, "the silent umbrella epilogue is present")
	_check(snapshot.tie_state == "Hidden", "the full tie line yields to the short umbrella thread in the epilogue")

	if _failures == 0:
		print("[SmokeTest] PASS - all four acts load and complete")
	var exit_code := 1 if _failures > 0 else 0
	_audio.call("shutdown")
	_game.queue_free()
	await _frames(3)
	quit(exit_code)


func _test_prologue() -> void:
	_check(_phase() == "prologue", "the demo opens on the silent sewing-shop prologue")
	_check(int(_world.get("layout")) == FullDemoWorld.Layout.PROLOGUE, "the prologue keeps the red thread in the mother's everyday sewing space")
	_check(not _player.visible and not _companion.visible, "the prologue uses its own fixed observation scene rather than playable actors")
	_check(_audio.get("current_mood") == "prologue", "the prologue has a restrained ambient bed")
	await _wait_for_phase("act1_explore", 0.5)
	_check(_phase() == "act1_explore", "the red-thread prologue transitions cleanly into the present-day room")


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

	_player.global_position = Vector2(700.0, 470.0)
	await _frames(3)
	_check(_phase() == "act1_tie", "distance reveals the tie line")
	_check(_tie_line.call("get_state_name") == "Tense", "Act 1 line becomes Tense")

	_player.global_position = Vector2(850.0, 470.0)
	await create_timer(0.12).timeout
	_check(_phase() == "act1_suspended", "maximum tension briefly lifts and supports the player")
	_check(_player.global_position.y <= 410.0, "the first-act support is visually distinct from standing on the floor")
	await _hold(&"move_right", 1.25)
	await _wait_for_phase("act1_umbrella", 0.35)
	_check(_phase() == "act1_umbrella", "horizontal input produces a short supported swing before settling by the umbrella")
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
	await _wait_for_phase("act2_climb", 0.4)
	_check(_phase() == "act2_climb", "the child's solo route causes a real fall after the anchor lesson")
	_check(_tie_line.call("get_state_name") == "Tense", "the same tense line now bears the child's weight")
	_check(_player.global_position.y >= 560.0, "the child remains visibly suspended instead of being auto-returned")
	await _hold(&"move_up", 0.62)
	await _wait_for_phase("act3_attach", 0.5)
	_check(_phase() == "act3_attach", "the child climbs back under player control before the farewell completes Act 2")


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
	await _wait_for_phase("act4_move_in", 0.4)
	_check(_phase() == "act4_move_in", "three alternating anchors lead directly into the current Act 4")


func _test_act_four() -> void:
	_check(int(_world.get("layout")) == FullDemoWorld.Layout.APARTMENT, "Act 4 takes place in the daughter's new apartment")
	_check(_tie_line.call("get_state_name") == "Adjustable", "the move-in begins with the familiar adjustable tie")
	_check(_audio.get("current_mood") == "apartment", "Act 4 starts with the apartment ambience")
	_player.global_position = _world.get("apartment_box_position") - Vector2(48.0, 0.0)
	_world.set("apartment_box_position", Vector2(1000.0, 485.0))
	await _wait_for_phase("act4_silence", 0.5)
	_check(_phase() == "act4_silence", "the boundary conflict changes the room instead of starting the legacy long run")
	_check(_tie_line.call("get_state_name") == "Silent", "the tie becomes frozen and nearly invisible after the conflict")
	_check(_audio.get("current_mood") == "silence", "the conflict drops into a near-silent ambience")

	_game.set("_act4_elapsed", 9.1)
	await _wait_for_phase("act4_relaxed", 0.5)
	_check(_phase() == "act4_relaxed", "time alone lets the daughter recognize the distance she actually wants")
	_check(_tie_line.call("get_state_name") == "Stable", "the returning tie is warm, slack, and stable")
	_check(_game.get("relationship_state") == "Stable", "the relationship state records stability without pullback")

	_player.global_position = Vector2(1300.0, 500.0)
	await _wait_for_phase("complete", 0.5)
	_check(_phase() == "complete", "the silent yellow-umbrella epilogue completes the ending")
	_check(bool(_world.get("epilogue_line_visible")), "a short loose line remains beside the old umbrella")
	_check(_umbrella.visible, "the old yellow umbrella returns behind the new apartment door")
	_check(bool(_player.get("presentation_mode")), "the epilogue removes gameplay-only role labels and control rings")
	var completion_restart := _game.get_node_or_null("PrototypeUI/CompletionPanel/CompleteBox/CompleteRestartButton") as Button
	_check(completion_restart != null and completion_restart.has_focus(), "completion places keyboard focus on the restart action")


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
