extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame

	var act := main.get_node("Act01Sequence") as Act01Sequence
	var game_flow := main.get_node("GameFlow") as GameFlow
	var dialogue := main.get_node("UI/DialogueUI") as DialogueUI

	dialogue.characters_per_second = 0.0
	dialogue.fade_duration = 0.0

	# 复现实机截图中的前置状态：冲突对白开始前，流程仍残留在 CUTSCENE。
	game_flow.set_mode(GameFlow.Mode.CUTSCENE)
	act._start_umbrella_scene()
	while dialogue.is_playing():
		dialogue.advance()
		await process_frame
	await process_frame

	assert(act.current_beat == Act01Sequence.Beat.P2_LEAVE)
	assert(
		game_flow.current_mode == GameFlow.Mode.EXPLORE,
		"P2 已提示玩家去门口时必须恢复 EXPLORE，不能残留在 CUTSCENE"
	)
	print("[P2_CONTROL_RECOVERY] PASS beat=P2_LEAVE mode=EXPLORE")
	quit(0)
