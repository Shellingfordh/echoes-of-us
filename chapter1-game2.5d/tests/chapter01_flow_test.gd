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
	var transition := main.get_node("UI/TransitionOverlay") as ColorRect
	var room := main.get_node("World/Chapter01Room01")
	var mother := room.get_node("Characters/Mother") as Mother
	var suitcase := room.get_node("Interactables/Suitcase") as Interactable
	var umbrella := room.get_node("Interactables/Umbrella") as Interactable
	var thread_clue := room.get_node("Interactables/ThreadClue") as Interactable
	var photo := room.get_node("Interactables/PhotoFrame") as Interactable
	var stool := room.get_node("Interactables/Stool") as Interactable

	dialogue.characters_per_second = 0.0
	dialogue.monologue_hold_seconds = 0.0
	dialogue.fade_duration = 0.0

	assert(get_nodes_in_group(&"key_object").size() == 5)
	assert(act.get_key_total() == 5)
	assert(not umbrella.visible)
	assert(not photo.interaction_enabled)
	assert(not thread_clue.interaction_enabled)

	# SR-002：窗、床底耳机和柜顶相框进入同一套固定观察；相框先由木凳解锁。
	var window_inspect := room.get_node("Interactables/WindowInspect") as Interactable
	window_inspect.interact(player)
	assert(observation.is_open() and observation.current_object_id == "WindowInspect")
	observation.close_observation()
	stool.interact(player)
	assert(photo.interaction_enabled)

	# P1 五件主调查。普通独白可直接结束，固定观察必须退出后才推进黄伞冲突。
	for node_name in ["PackingBox", "Suitcase", "Desk"]:
		(room.get_node("Interactables/%s" % node_name) as Interactable).interact(player)
		_finish_dialogue(dialogue)
		await process_frame

	var headphones := room.get_node("Interactables/Headphones") as Interactable
	headphones.interact(player)
	assert(observation.is_open() and observation.current_object_id == "Headphones")
	observation.close_observation()
	await process_frame

	photo.interact(player)
	assert(observation.is_open() and observation.current_object_id == "PhotoFrame")
	assert("小学春游合影" in observation._body_label.text)
	observation.close_observation()
	await process_frame
	await process_frame
	assert(act.get_investigated_key_count() == 5)
	assert(act.current_beat == Act01Sequence.Beat.UMBRELLA_DIALOGUE)
	_finish_dialogue(dialogue)
	await process_frame

	# P2：黄伞与行李箱二次调查存在，母亲仍是牵挂线的真实端点。
	assert(act.current_beat == Act01Sequence.Beat.P2_LEAVE)
	assert(umbrella.visible and umbrella.dialogue_id == "D046")
	assert(suitcase.dialogue_id == "D045" and not suitcase.investigated)
	assert(mother.visible)
	assert(mother.get_logical_position().is_equal_approx(Vector3(6.4, 0.0, 9.2)))
	assert(tie_line.get_target_anchor().is_equal_approx(mother.get_anchor_position()))

	# SR-004/005：走向玄关时显线，张力同时包含距离、情绪与离开意图。
	player.set_logical_position(Vector3(15.2, 0.0, 2.0))
	await process_frame
	await process_frame
	assert(tie_line.enabled)
	assert(act.current_beat == Act01Sequence.Beat.FIRST_PULL)
	assert(not thread_clue.interaction_enabled)
	assert(tie_line.emotional_pressure > 0.0)
	assert(tie_line.intention_conflict > 0.0)
	assert(tie_line.exit_progress > 0.0)

	# 第一次越界经 CharacterBody3D 连续回弹；回到安全距离后要求玩家主动抓线。
	player.set_logical_position(Vector3(16.8, 0.0, 1.0))
	for _index in range(180):
		await physics_frame
		if act.current_beat == Act01Sequence.Beat.LINE_PROBE:
			break
	assert(act.current_beat == Act01Sequence.Beat.LINE_PROBE)
	assert(tie_line.distance <= tie_line.tension_distance + 0.15)
	assert(not player.is_suspended())
	assert(is_zero_approx(player.get_logical_position().y))

	# SR-006：主动抓线并向门口用力时，线以速度限制和回拉提供地面物理反馈。
	# 第一章全程不得进入悬空、承重或摆荡。
	act._on_empty_interact_pressed()
	assert(act.current_beat == Act01Sequence.Beat.PROBING_RESISTANCE)
	var probe_start := player.get_logical_position()
	Input.action_press(&"interact")
	Input.action_press(&"move_right")
	for _index in range(80):
		await physics_frame
		if act.current_beat == Act01Sequence.Beat.WAIT_FINAL_REARM:
			break
	Input.action_release(&"move_right")
	Input.action_release(&"interact")
	assert(act.current_beat == Act01Sequence.Beat.WAIT_FINAL_REARM)
	assert(not player.is_suspended())
	assert(is_zero_approx(player.get_logical_position().y))
	assert(player.get_logical_position().distance_to(probe_start) < 1.2)
	_finish_dialogue(dialogue)
	for _index in range(120):
		await physics_frame
		if act.current_beat == Act01Sequence.Beat.FINAL_ATTEMPT:
			break
	assert(act.current_beat == Act01Sequence.Beat.FINAL_ATTEMPT)
	assert(thread_clue.interaction_enabled)

	# 玩家再次向门口用力，失败后才形成 D018 错误理解并开放黄伞余响入口。
	Input.action_press(&"move_right")
	for _index in range(240):
		await physics_frame
		if act.current_beat == Act01Sequence.Beat.AFTER_PROBE:
			break
	Input.action_release(&"move_right")
	assert(act.current_beat == Act01Sequence.Beat.AFTER_PROBE)
	assert(not player.is_suspended())
	assert(is_zero_approx(player.get_logical_position().y))
	assert(umbrella.interaction_enabled)

	# 第一章只在玩家主动触碰黄伞、越过余响阈值后结束。
	_finish_dialogue(dialogue)
	thread_clue.interact(player)
	_finish_dialogue(dialogue)
	umbrella.interact(player)
	await process_frame
	assert(act.current_beat == Act01Sequence.Beat.DONE)
	assert(game_state.has_flag(&"chapter1_photo_unlocked"))
	assert(game_state.has_flag(&"chapter1_first_pullback"))
	assert(game_state.has_flag(&"chapter1_physical_resistance_confirmed"))
	assert(game_state.has_flag(&"chapter1_complete"))
	assert(transition.visible)
	assert(transition.get_node_or_null("EchoTitle") is Label)

	print("[CHAPTER01_FLOW] PASS fixed_observation=true stool_unlock=true composite_tension=true")
	print("[CHAPTER01_FLOW] PASS first_pull=true grounded_probe=true no_chapter1_support=true umbrella_echo=true")
	quit(0)


func _finish_dialogue(dialogue: DialogueUI) -> void:
	if dialogue.is_playing():
		dialogue._finish_immediately(true)
