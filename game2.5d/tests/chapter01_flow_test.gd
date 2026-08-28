extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.time_scale = 8.0
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame

	var act := main.get_node("Act01Sequence") as Act01Sequence
	var player := main.get_node("Player") as PlayerController
	var tie_line := main.get_node("TieLine") as TieLine
	var game_state := main.get_node("GameState") as GameState
	var dialogue := main.get_node("UI/DialogueUI") as DialogueUI
	var observation := main.get_node("UI/FixedObservationUI") as FixedObservationUI
	var observation_db := main.get_node("ObservationDatabase") as ObservationDatabase
	var transition := main.get_node("UI/TransitionOverlay") as ColorRect
	var room := main.get_node("World/Chapter01Room01")
	var mother := room.get_node("Characters/Mother") as Mother
	var suitcase := room.get_node("Interactables/Suitcase") as Interactable
	var umbrella := room.get_node("Interactables/Umbrella") as Interactable
	var thread_clue := room.get_node("Interactables/ThreadClue") as Interactable
	var photo := room.get_node("Interactables/PhotoFrame") as Interactable
	var stool := room.get_node("Interactables/Stool") as Interactable
	var bead := room.get_node("Interactables/BeadBracelet") as Interactable

	dialogue.characters_per_second = 0.0
	dialogue.monologue_hold_seconds = 0.0
	dialogue.fade_duration = 0.0

	assert(get_nodes_in_group(&"key_object").size() == 5)
	assert(act.get_key_total() == 5)
	assert(observation_db.get_all_ids().size() == 11)
	assert(not umbrella.visible)
	assert(not photo.interaction_enabled)
	assert(not thread_clue.interaction_enabled)
	assert(bead.observation_id == "O044")

	# P1 选调：窗玻璃和木珠串现在是两个独立 O-ID，信息卡不混入余念独白。
	await _inspect_object(
		room.get_node("Interactables/WindowInspect") as Interactable,
		observation,
		dialogue,
		"O004",
		"D004"
	)
	await _inspect_object(bead, observation, dialogue, "O044", "D044")
	await _inspect_object(
		room.get_node("Interactables/WardrobeInspect") as Interactable,
		observation,
		dialogue,
		"O043",
		"D043"
	)
	assert(act.get_investigated_key_count() == 0)

	# 相框需要先移动木凳解锁。
	stool.interact(player)
	assert(photo.interaction_enabled)

	# P1 五件主调查：每件都按 O 信息卡 → 独立 D 对话框的顺序播放。
	for node_name in ["PackingBox", "Suitcase", "Desk"]:
		var target := room.get_node("Interactables/%s" % node_name) as Interactable
		await _inspect_object(target, observation, dialogue, target.observation_id, target.dialogue_id)

	await _inspect_object(
		room.get_node("Interactables/Headphones") as Interactable,
		observation,
		dialogue,
		"O041",
		"D041"
	)
	await _inspect_object(photo, observation, dialogue, "O042", "D042")
	await process_frame
	assert(act.get_investigated_key_count() == 5)
	assert(act.current_beat == Act01Sequence.Beat.UMBRELLA_DIALOGUE)
	_finish_dialogue(dialogue)
	await process_frame

	# P2：行李箱切换到 O045/D045；黄伞使用 O046/D046。
	assert(act.current_beat == Act01Sequence.Beat.P2_LEAVE)
	assert(umbrella.visible and umbrella.observation_id == "O046")
	assert(suitcase.observation_id == "O045" and not suitcase.investigated)
	assert(mother.visible)
	assert(mother.get_logical_position().is_equal_approx(Vector3(6.4, 0.0, 9.2)))
	assert(tie_line.get_target_anchor().is_equal_approx(mother.get_anchor_position()))
	await _inspect_object(suitcase, observation, dialogue, "O045", "D045")
	await _inspect_object(umbrella, observation, dialogue, "O046", "D046")

	# 靠近玄关显线；第一章只做回弹和地面阻力，不进入悬挂状态。
	player.set_logical_position(Vector3(15.2, 0.0, 2.0))
	await process_frame
	await process_frame
	assert(tie_line.enabled)
	assert(act.current_beat == Act01Sequence.Beat.FIRST_PULL)
	assert(thread_clue.interaction_enabled)
	# P3 普通线共用 O047/D047，可在两次离门尝试之间选看。
	await _inspect_object(thread_clue, observation, dialogue, "O047", "D047")

	player.set_logical_position(Vector3(16.8, 0.0, 1.0))
	for _index in range(180):
		await physics_frame
		if act.current_beat == Act01Sequence.Beat.SECOND_ATTEMPT:
			break
	assert(act.current_beat == Act01Sequence.Beat.SECOND_ATTEMPT)
	assert(tie_line.distance <= tie_line.tension_distance + 0.15)

	player.set_logical_position(Vector3(16.8, 0.0, 1.0))
	for _index in range(60):
		await physics_frame
		if act.current_beat == Act01Sequence.Beat.FINAL_DIALOGUE:
			break
	assert(act.current_beat == Act01Sequence.Beat.FINAL_DIALOGUE)
	assert(not player.is_suspended())
	assert(is_zero_approx(player.get_logical_position().y))
	_finish_dialogue(dialogue)
	await process_frame
	assert(act.current_beat == Act01Sequence.Beat.DONE)
	assert(game_state.has_flag(&"chapter1_resistance_confirmed"))
	assert(game_state.has_flag(&"chapter1_photo_unlocked"))
	assert(game_state.has_flag(&"chapter1_first_pullback"))
	assert(game_state.has_flag(&"chapter1_complete"))
	assert(transition.visible)
	assert(transition.get_node_or_null("EchoTitle") is Label)

	print("[CHAPTER01_FLOW] PASS observations=11 required=5 optional=3 p2=2 p3=1")
	print("[CHAPTER01_FLOW] PASS item_card_then_dialogue=true no_chapter1_suspension=true")
	quit(0)


func _inspect_object(
	target: Interactable,
	observation: FixedObservationUI,
	dialogue: DialogueUI,
	expected_observation_id: String,
	expected_dialogue_id: String
) -> void:
	assert(target.observation_id == expected_observation_id)
	target.interact(get_first_node_in_group(&"player") as PlayerController)
	assert(observation.is_open() and observation.current_object_id == target.name)
	assert(not "余念·独白" in observation._body_label.text)
	observation.close_observation()
	assert(dialogue.is_playing() and dialogue._root_id == expected_dialogue_id)
	_finish_dialogue(dialogue)
	await process_frame


func _finish_dialogue(dialogue: DialogueUI) -> void:
	if dialogue.is_playing():
		dialogue._finish_immediately(true)
