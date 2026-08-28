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
	var game_flow := main.get_node("GameFlow") as GameFlow
	var dialogue := main.get_node("UI/DialogueUI") as DialogueUI
	var object_info := main.get_node("UI/ObjectInfoUI") as ObjectInfoUI
	var object_info_db := main.get_node("ObjectInfoDatabase") as ObjectInfoDatabase
	var observation := main.get_node("UI/FixedObservationUI") as FixedObservationUI
	var hint := main.get_node("UI/InteractionHint") as InteractionHint
	var objective := main.get_node("UI/ObjectiveLabel") as Label
	var transition := main.get_node("UI/TransitionOverlay") as ColorRect
	var room := main.get_node("World/Chapter01Room01")
	var tension_feedback := room.get_node("TensionFeedback")
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
	assert(object_info_db.get_all_ids().size() == 11)

	# SR-002：窗、床底耳机和柜顶相框进入同一套固定观察；相框先由木凳解锁。
	var window_inspect := room.get_node("Interactables/WindowInspect") as Interactable
	window_inspect.interact(player)
	assert(observation.is_open() and observation.current_object_id == "WindowInspect")
	assert(object_info_db.get_text("O004") in observation._body_label.text)
	assert(object_info_db.get_text("O044") in observation._body_label.text)
	observation.close_observation()
	player.set_logical_position(Vector3(3.0, 0.0, 3.0))
	for _index in range(20):
		await physics_frame
		await process_frame
		if player._current_hint_only_interactable == photo:
			break
	assert(player._current_interactable == null)
	assert(player._current_hint_only_interactable == photo)
	assert(hint.visible and "太高" in hint.text)
	var stool_start := stool.get_logical_position()
	stool.interact(player)
	for _index in range(20):
		await physics_frame
		if photo.interaction_enabled:
			break
	assert(photo.interaction_enabled)
	assert(not stool.get_logical_position().is_equal_approx(stool_start))
	assert(stool.get_logical_position().is_equal_approx(act.stool_placed_position))
	assert("靠近相框" in objective.text)

	# P1 五件主调查：普通物件必须先显示 O-ID 客观事实，再播放 D-ID 主观反应。
	for node_name in ["PackingBox", "Suitcase"]:
		(room.get_node("Interactables/%s" % node_name) as Interactable).interact(player)
		assert(object_info.is_open())
		_finish_object_interaction(object_info, dialogue)
		await process_frame

	var headphones := room.get_node("Interactables/Headphones") as Interactable
	headphones.interact(player)
	assert(observation.is_open() and observation.current_object_id == "Headphones")
	observation.close_observation()
	await process_frame
	assert("书桌上的台历" in objective.text)
	assert("柜顶那张相框" in objective.text)
	assert("/" not in objective.text)

	photo.interact(player)
	assert(act.is_photo_stool_sequence_active())
	assert(game_flow.current_mode == GameFlow.Mode.CUTSCENE)
	assert(not observation.is_open())
	for _index in range(60):
		await process_frame
		if observation.is_open():
			break
	assert(observation.is_open() and observation.current_object_id == "PhotoFrame")
	assert(player.get_logical_position().is_equal_approx(act.get_photo_stool_stand_position()))
	assert(is_equal_approx(player.get_logical_position().y, act.photo_stool_height))
	assert(not player.is_scripted_motion_active())
	assert("小学春游合影" in observation._body_label.text)
	assert(objective.text == "站稳了。仔细看看柜顶的相框。")
	observation.close_observation()
	for _index in range(60):
		await process_frame
		if not act.is_photo_stool_sequence_active():
			break
	assert(not act.is_photo_stool_sequence_active())
	assert(player.get_logical_position().is_equal_approx(act.get_photo_stool_step_position()))
	assert(is_zero_approx(player.get_logical_position().y))
	assert(game_flow.current_mode == GameFlow.Mode.EXPLORE)
	assert(objective.text == "最后再看看书桌上的台历。")
	await physics_frame
	assert(player.get_logical_position().is_equal_approx(act.get_photo_stool_step_position()))

	# 将普通物件放在最后，验证 O-ID 与 D-ID 都结束前不会提前触发黄伞冲突。
	var desk := room.get_node("Interactables/Desk") as Interactable
	desk.interact(player)
	assert(object_info.is_open() and object_info.current_info_id == "O003")
	assert(act.current_beat == Act01Sequence.Beat.P1_EXPLORE)
	assert(objective.text == "把眼前这件东西看完。")
	object_info.advance()
	assert(dialogue.is_playing())
	assert(act.current_beat == Act01Sequence.Beat.P1_EXPLORE)
	_finish_dialogue(dialogue)
	await process_frame
	await process_frame
	assert(act.get_investigated_key_count() == 5)
	assert(act.current_beat == Act01Sequence.Beat.UMBRELLA_DIALOGUE)
	var expected_umbrella_presentations: Array = [
		["D005", "D006"],
		["D007", "D008"],
		["D009", "D010"],
		["D011"],
		["D012"],
		["D013", "D014"],
	]
	var actual_umbrella_presentations: Array = []
	var umbrella_confirmations := 0
	while dialogue.is_playing():
		actual_umbrella_presentations.append(dialogue.get_current_presentation_ids())
		dialogue.advance()
		umbrella_confirmations += 1
		await process_frame
	assert(actual_umbrella_presentations == expected_umbrella_presentations)
	assert(umbrella_confirmations == 6)
	await process_frame

	# P2：黄伞与行李箱二次调查存在，母亲仍是牵挂线的真实端点。
	assert(act.current_beat == Act01Sequence.Beat.P2_LEAVE)
	assert(umbrella.visible and umbrella.object_info_id == "O046" and umbrella.dialogue_id == "D046")
	assert(suitcase.object_info_id == "O045" and suitcase.dialogue_id == "D045" and not suitcase.investigated)
	assert(mother.visible)
	assert(mother.get_logical_position().is_equal_approx(Vector3(6.4, 0.0, 9.2)))
	assert(tie_line.get_target_anchor().is_equal_approx(mother.get_anchor_position()))

	# P2 状态变化也必须先给事实，再给人物态度。
	suitcase.interact(player)
	assert(object_info.current_info_id == "O045")
	assert("又多出两盒药" in object_info._body_label.text)
	_finish_object_interaction(object_info, dialogue)
	umbrella.interact(player)
	assert(object_info.current_info_id == "O046")
	_finish_object_interaction(object_info, dialogue)

	# SR-004/005：走向玄关时显线，张力同时包含距离、情绪与离开意图。
	player.set_logical_position(Vector3(15.2, 0.0, 2.0))
	await process_frame
	await process_frame
	assert(tie_line.enabled)
	assert(act.current_beat == Act01Sequence.Beat.LINE_REVEAL)
	assert(game_flow.current_mode == GameFlow.Mode.CUTSCENE)
	assert(tie_line.appearance_progress < 1.0)
	assert(not thread_clue.interaction_enabled)
	assert(tie_line.emotional_pressure > 0.0)
	assert(tie_line.intention_conflict > 0.0)
	assert(tie_line.exit_progress > 0.0)
	for _index in range(60):
		await physics_frame
		if act.current_beat == Act01Sequence.Beat.FIRST_PULL:
			break
	assert(act.current_beat == Act01Sequence.Beat.FIRST_PULL)
	assert(game_flow.current_mode == GameFlow.Mode.EXPLORE)

	# 第一次越界经 CharacterBody3D 连续回弹；回到安全距离后要求玩家主动抓线。
	dialogue.monologue_hold_seconds = 30.0
	player.set_logical_position(Vector3(16.8, 0.0, 1.0))
	for _index in range(180):
		await physics_frame
		if act.current_beat == Act01Sequence.Beat.WAIT_PROBE_REARM:
			break
	assert(act.current_beat == Act01Sequence.Beat.WAIT_PROBE_REARM)
	assert(dialogue.is_playing() and dialogue._current_id == "D015")
	for _index in range(30):
		await physics_frame
	assert(act.current_beat == Act01Sequence.Beat.WAIT_PROBE_REARM)
	assert(not hint.visible)
	dialogue.advance()
	assert(dialogue._current_id == "D016")
	assert(act.current_beat == Act01Sequence.Beat.WAIT_PROBE_REARM)
	dialogue.advance()
	await process_frame
	for _index in range(30):
		await physics_frame
		if act.current_beat == Act01Sequence.Beat.LINE_PROBE:
			break
	assert(act.current_beat == Act01Sequence.Beat.LINE_PROBE)
	dialogue.monologue_hold_seconds = 0.0
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
		if _index == 4:
			assert(player.get_resistance_visual_strength() > 0.5)
			assert(tension_feedback.get_feedback_strength() > 0.5)
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
	assert(tie_line.is_echo_resonating())
	assert(umbrella.is_resonating())

	# 接近黄伞时物理阻力已经解除，但红线与黄伞仍需共同共鸣，不能恢复普通青色。
	_finish_dialogue(dialogue)
	thread_clue.interact(player)
	assert(object_info.current_info_id == "O047")
	_finish_object_interaction(object_info, dialogue)
	player.set_logical_position(umbrella.get_logical_position() + Vector3(-0.45, 0.0, 0.2))
	for _index in range(8):
		await physics_frame
	assert(tie_line.current_state == TieLine.State.NORMAL)
	assert(tie_line.default_color.is_equal_approx(tie_line.echo_color))
	assert(tie_line.get_echo_resonance_strength() > 0.0)
	assert(umbrella.get_resonance_strength() > 0.0)
	assert(absf(tie_line.get_echo_resonance_strength() - umbrella.get_resonance_strength()) < 0.03)

	# 触碰黄伞后先锁定一小段共同激活演出，再进入章节标题。
	umbrella.interact(player)
	assert(act.current_beat == Act01Sequence.Beat.ECHO_TRANSITION)
	assert(game_flow.current_mode == GameFlow.Mode.CUTSCENE)
	assert(not game_state.has_flag(&"chapter1_complete"))
	assert(not transition.visible)
	assert(umbrella.get_node("Glow").visible)
	for _index in range(30):
		await physics_frame
		if act.current_beat == Act01Sequence.Beat.DONE:
			break
	assert(act.current_beat == Act01Sequence.Beat.DONE)
	assert(game_state.has_flag(&"chapter1_photo_unlocked"))
	assert(game_state.has_flag(&"chapter1_first_pullback"))
	assert(game_state.has_flag(&"chapter1_physical_resistance_confirmed"))
	assert(game_state.has_flag(&"chapter1_complete"))
	assert(transition.visible)
	assert(transition.get_node_or_null("EchoTitle") is Label)

	print("[CHAPTER01_FLOW] PASS fixed_observation=true stool_unlock=true umbrella_presentations=6")
	print("[CHAPTER01_FLOW] PASS endpoint_reveal=true reaction_gated=true non_color_feedback=true grounded_probe=true shared_echo=true")
	quit(0)


func _finish_dialogue(dialogue: DialogueUI) -> void:
	if dialogue.is_playing():
		dialogue._finish_immediately(true)


func _finish_object_interaction(object_info: ObjectInfoUI, dialogue: DialogueUI) -> void:
	assert(object_info.is_open())
	object_info.advance()
	assert(dialogue.is_playing())
	_finish_dialogue(dialogue)
