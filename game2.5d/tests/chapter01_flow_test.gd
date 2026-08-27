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
	var room := main.get_node("World/Chapter01Room01")
	var mother := room.get_node("Characters/Mother") as Mother
	var suitcase := room.get_node("Interactables/Suitcase") as Interactable
	var umbrella := room.get_node("Interactables/Umbrella") as Interactable
	var thread_clue := room.get_node("Interactables/ThreadClue") as Interactable

	assert(get_nodes_in_group(&"key_object").size() == 5)
	assert(not umbrella.visible)
	assert(not thread_clue.interaction_enabled)

	# 跳过耗时对白，只验证黄伞冲突后的 P2 状态切换。
	act.current_beat = Act01Sequence.Beat.UMBRELLA_DIALOGUE
	act._finish_umbrella_scene()
	assert(act.current_beat == Act01Sequence.Beat.P2_LEAVE)
	assert(umbrella.visible and umbrella.dialogue_id == "D046")
	assert(suitcase.dialogue_id == "D045" and not suitcase.investigated)
	assert(mother.visible)
	assert(mother.get_logical_position().is_equal_approx(Vector3(6.4, 0.0, 9.2)))
	assert(tie_line.get_target_anchor().is_equal_approx(mother.get_anchor_position()))

	# 只有靠近右下门口才显线并进入 P3。
	player.set_logical_position(Vector3(15.2, 0.0, 2.0))
	await process_frame
	assert(tie_line.enabled)
	assert(act.current_beat == Act01Sequence.Beat.FIRST_PULL)
	assert(thread_clue.interaction_enabled)
	assert(mother.visible)
	assert(tie_line.get_target_anchor().is_equal_approx(mother.get_anchor_position()))

	# 第一次越界后沿空通道连续回弹，并允许第二次尝试。
	player.set_logical_position(Vector3(16.8, 0.0, 1.0))
	for _index in range(120):
		await physics_frame
		if act.current_beat == Act01Sequence.Beat.SECOND_ATTEMPT:
			break
	print("[CHAPTER01_FLOW] after first pull beat=", act.current_beat, " pos=", player.get_logical_position(), " distance=", tie_line.distance, " tension=", tie_line.tension, " state=", tie_line.get_state_name())
	assert(act.current_beat == Act01Sequence.Beat.SECOND_ATTEMPT)
	assert(tie_line.distance <= tie_line.tension_distance + 0.1)

	# 第二次越界进入承重/错误理解对白链 D017 → D018。
	player.set_logical_position(Vector3(16.8, 0.0, 1.0))
	for _index in range(30):
		await physics_frame
		if act.current_beat == Act01Sequence.Beat.FINAL_DIALOGUE:
			break
	assert(act.current_beat == Act01Sequence.Beat.FINAL_DIALOGUE)

	print("[CHAPTER01_FLOW] PASS keys=5 p2_case=D045 p3_line=true two_attempts=true")
	quit(0)
