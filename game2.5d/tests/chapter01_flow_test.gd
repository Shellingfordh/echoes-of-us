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
	var player := main.get_node("World/Chapter01Room01/Characters/Player") as PlayerController
	var tie_line := main.get_node("TieLine") as TieLine
	var game_state := main.get_node("GameState") as GameState
	var dialogue := main.get_node("UI/DialogueUI") as DialogueUI
	var observation := main.get_node("UI/FixedObservationUI") as FixedObservationUI
	var observation_db := main.get_node("ObservationDatabase") as ObservationDatabase
	var transition := main.get_node("UI/TransitionOverlay") as ColorRect
	var room := main.get_node("World/Chapter01Room01")
	var mother := room.get_node("Characters/Mother") as Mother
	var suitcase := room.get_node("Interactables/Suitcase") as Interactable
	var suitcase_closed_visual := suitcase.get_node("Visual") as Sprite2D
	var suitcase_open_visual := suitcase.get_node("OpenVisual") as Sprite2D
	var suitcase_closed_collision := suitcase.get_node("MathBody/CollisionShape3D") as CollisionShape3D
	var suitcase_open_collision := suitcase.get_node("MathBody/OpenCollisionShape3D") as CollisionShape3D
	var umbrella := room.get_node("Interactables/Umbrella") as Interactable
	var thread_clue := room.get_node("Interactables/ThreadClue") as Interactable
	var photo := room.get_node("Interactables/PhotoFrame") as Interactable
	var packing_box := room.get_node("Interactables/PackingBox") as Interactable
	var stool := room.get_node("Interactables/Stool") as PushableStool
	var bed_trigger := room.get_node("Interactables/BedCrouchTrigger") as Interactable
	var wardrobe_closed_visual := room.get_node("Midground/Wardrobe/Visual") as Sprite2D
	var wardrobe_open_visual := room.get_node("Midground/Wardrobe/OpenVisual") as Sprite2D

	dialogue.characters_per_second = 0.0
	dialogue.monologue_hold_seconds = 0.0
	dialogue.fade_duration = 0.0

	assert(get_nodes_in_group(&"key_object").size() == 5)
	assert(act.get_key_total() == 5)
	assert(observation_db.get_all_ids().size() == 10)
	assert(umbrella.visible)
	assert(not umbrella.interaction_enabled)
	assert(not photo.interaction_enabled)
	assert(not thread_clue.interaction_enabled)
	assert(suitcase_closed_visual.visible and not suitcase_open_visual.visible)
	assert(wardrobe_closed_visual.visible and not wardrobe_open_visual.visible)
	assert(not suitcase_closed_collision.disabled and suitcase_open_collision.disabled)
	assert(room.get_node_or_null("Interactables/Headphones") == null)
	assert(room.get_node_or_null("Interactables/BeadBracelet") == null)

	# 路过窗边只播放倒影对白 D044，不再生成木珠串或 O044 信息卡。
	player.set_logical_position(act.window_reflection_position)
	await process_frame
	assert(dialogue.is_playing() and dialogue._root_id == "D044")
	assert(not observation.is_open())
	_finish_dialogue(dialogue)
	await process_frame

	# P1 选调：窗玻璃本身仍可调查，但与路过倒影对白相互独立。
	await _inspect_object(
		room.get_node("Interactables/WindowInspect") as Interactable,
		observation,
		dialogue,
		"O004",
		"D004"
	)
	await _inspect_object(
		room.get_node("Interactables/WardrobeInspect") as Interactable,
		observation,
		dialogue,
		"O043",
		"D043"
	)
	assert(not wardrobe_closed_visual.visible and wardrobe_open_visual.visible)
	assert(act.get_investigated_key_count() == 0)

	# 相框需要箱子同时满足“推到柜前目标区”和“玩家站上箱顶”。
	assert(packing_box.get_node("MathBody") is StaticBody3D)
	stool.set_logical_position(stool.target_position)
	await process_frame
	assert(not photo.interaction_enabled)
	assert(player.mount_stool(stool))
	await physics_frame
	await physics_frame
	assert(photo.interaction_enabled)

	# P1 五件主调查：每件都按 O 信息卡 → 独立 D 对话框的顺序播放。
	for node_name in ["PackingBox", "Suitcase", "Desk"]:
		var target := room.get_node("Interactables/%s" % node_name) as Interactable
		await _inspect_object(target, observation, dialogue, target.observation_id, target.dialogue_id)
	assert(not suitcase_closed_visual.visible and suitcase_open_visual.visible)
	await physics_frame
	assert(suitcase_closed_collision.disabled and not suitcase_open_collision.disabled)

	await _crouch_and_inspect_bed(
		player,
		bed_trigger,
		observation,
		dialogue
	)
	assert(player.mount_stool(stool))
	await physics_frame
	await physics_frame
	await _inspect_object(photo, observation, dialogue, "O042", "D042")
	await process_frame
	assert(act.get_investigated_key_count() == 5)
	assert(act.current_beat == Act01Sequence.Beat.UMBRELLA_DIALOGUE)
	assert(mother.get_logical_position().is_equal_approx(act.mother_dialogue_position))
	_finish_dialogue(dialogue)
	for _index in range(3):
		await process_frame
	var mother_mid_walk := mother.get_logical_position()
	assert(mother_mid_walk.distance_to(act.mother_dialogue_position) > 0.01)
	assert(mother_mid_walk.distance_to(act.mother_after_dialogue_position) > 0.01)
	for _index in range(120):
		await process_frame
		if act.current_beat == Act01Sequence.Beat.P2_LEAVE:
			break

	# P2：行李箱切换到 O045/D045；黄伞使用 O046/D046。
	assert(act.current_beat == Act01Sequence.Beat.P2_LEAVE)
	assert(umbrella.visible and umbrella.interaction_enabled and umbrella.observation_id == "O046")
	assert(not umbrella.investigated)
	assert(suitcase.observation_id == "O045" and not suitcase.investigated)
	assert(mother.visible)
	assert(mother.get_logical_position().is_equal_approx(act.mother_after_dialogue_position))
	assert(mother.is_facing_away())
	assert(tie_line.get_target_anchor().is_equal_approx(mother.get_anchor_position()))
	await _inspect_object(suitcase, observation, dialogue, "O045", "D045")
	await _inspect_object(umbrella, observation, dialogue, "O046", "D046")

	# 靠近玄关显线。线立刻绷紧，但回拉被锁住：这时还不能直接走出门。
	player.set_logical_position(Vector3(15.2, 0.0, 2.0))
	await process_frame
	await process_frame
	assert(tie_line.enabled)
	assert(act.current_beat == Act01Sequence.Beat.P3_RECHECK)
	assert(tie_line.is_pullback_locked())
	assert(thread_clue.interaction_enabled)
	# P3 普通线共用 O047/D047，可在离门尝试之间选看。
	await _inspect_object(thread_clue, observation, dialogue, "O047", "D047")

	# 显线之后行李箱与黄伞重新开放，两件都重看过才会放行到门口。
	assert(suitcase.interaction_enabled and not suitcase.investigated)
	assert(umbrella.interaction_enabled and not umbrella.investigated)
	await _inspect_object(suitcase, observation, dialogue, "O045", "D045")
	await process_frame
	assert(act.current_beat == Act01Sequence.Beat.P3_RECHECK, "只看了行李箱就放行了")
	assert(tie_line.is_pullback_locked())
	await _inspect_object(umbrella, observation, dialogue, "O046", "D046")
	await process_frame
	assert(act.current_beat >= Act01Sequence.Beat.FIRST_PULL)
	assert(not tie_line.is_pullback_locked())
	assert(game_state.has_flag(&"chapter1_recheck_complete"))

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

	print("[CHAPTER01_FLOW] PASS observations=10 required=5 optional=2 p2=2 p3=1")
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
	if expected_observation_id == "O043":
		assert(observation._item_image.visible and observation._item_image.texture != null)
		assert(observation._item_image.get_parent() == observation._body_label.get_parent())
	assert(not "余念·独白" in observation._body_label.text)
	observation.close_observation()
	assert(dialogue.is_playing() and dialogue._root_id == expected_dialogue_id)
	_finish_dialogue(dialogue)
	await process_frame


func _crouch_and_inspect_bed(
	player: PlayerController,
	bed_trigger: Interactable,
	observation: FixedObservationUI,
	dialogue: DialogueUI
) -> void:
	assert(bed_trigger.requires_crouch)
	bed_trigger.interact(player)
	assert(not bed_trigger.investigated)
	player.set_logical_position(Vector3(12.4, 0.0, 5.4))
	await physics_frame
	assert(player.toggle_crouch())
	assert(player.is_crouching())
	assert(observation.is_open() and observation.current_object_id == bed_trigger.name)
	observation.close_observation()
	assert(dialogue.is_playing() and dialogue._root_id == "D041")
	_finish_dialogue(dialogue)
	await process_frame
	assert(player.toggle_crouch())
	assert(not player.is_crouching())


func _finish_dialogue(dialogue: DialogueUI) -> void:
	if dialogue.is_playing():
		dialogue._finish_immediately(true)
