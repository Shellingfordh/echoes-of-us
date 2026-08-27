class_name Act01Sequence
extends Node

## 第一章屋内最小闭环：P1 五件必调 → 黄伞冲突 → P2 离开尝试
## → P3 牵挂线与普通线状物显色 → 第一次回弹 → 第二次承重认知 → 错误理解。

signal objective_changed(text: String)
signal act_finished

enum Beat {
	P1_EXPLORE,
	UMBRELLA_DIALOGUE,
	P2_LEAVE,
	FIRST_PULL,
	WAIT_SECOND_REARM,
	SECOND_ATTEMPT,
	FINAL_DIALOGUE,
	DONE,
}

@export var reveal_trigger_x := 15.0
@export var reveal_trigger_z_max := 2.8
@export_range(0.8, 1.0, 0.01) var pullback_trigger_tension := 0.99
@export_range(0.1, 0.95, 0.01) var rearm_tension := 0.92
@export var mother_dialogue_position := Vector3(7.0, 0.0, 7.5)
@export var mother_after_dialogue_position := Vector3(6.4, 0.0, 9.2)

var current_beat := Beat.P1_EXPLORE
var _investigated_keys := 0
var _key_total := 0

var _player: PlayerController
var _mother: Mother
var _tie_line: TieLine
var _dialogue: DialogueUI
var _room: RoomBase
var _umbrella: Interactable
var _suitcase: Interactable
var _thread_clue: Interactable


func setup(room: RoomBase, player: PlayerController, tie_line: TieLine) -> void:
	_room = room
	_player = player
	_tie_line = tie_line
	_mother = room.get_mother()
	_dialogue = get_tree().get_first_node_in_group(&"dialogue_ui") as DialogueUI
	_umbrella = room.get_node_or_null("Interactables/Umbrella") as Interactable
	_suitcase = room.get_node_or_null("Interactables/Suitcase") as Interactable
	_thread_clue = room.get_node_or_null("Interactables/ThreadClue") as Interactable

	for node in get_tree().get_nodes_in_group(&"key_object"):
		var key := node as Interactable
		if key == null:
			continue
		_key_total += 1
		key.interacted.connect(_on_key_object_investigated)

	if _tie_line != null:
		_tie_line.set_enabled(false)
	if _thread_clue != null:
		_thread_clue.set_interaction_enabled(false)
	_update_explore_objective()


func _process(_delta: float) -> void:
	match current_beat:
		Beat.P2_LEAVE:
			_check_reveal()
		Beat.FIRST_PULL:
			if _has_reached_pullback():
				_on_first_pullback()
		Beat.WAIT_SECOND_REARM:
			if _is_rearmed():
				current_beat = Beat.SECOND_ATTEMPT
				objective_changed.emit("再向门口走一次，看看这根线。")
		Beat.SECOND_ATTEMPT:
			if _has_reached_pullback():
				_on_second_pullback()
		_:
			pass


func _on_key_object_investigated(_player_ref: PlayerController) -> void:
	if current_beat != Beat.P1_EXPLORE:
		return
	_investigated_keys += 1
	_update_explore_objective()
	if _investigated_keys < _key_total:
		return

	# interacted 信号先于物件自己的 play() 发出，等它的独白完整结束。
	await get_tree().process_frame
	if _dialogue != null and _dialogue.is_playing():
		await _dialogue.dialogue_finished
	_start_umbrella_scene()


func _update_explore_objective() -> void:
	objective_changed.emit("整理离家前的东西（%d/%d）" % [_investigated_keys, _key_total])


func _start_umbrella_scene() -> void:
	if current_beat != Beat.P1_EXPLORE:
		return
	current_beat = Beat.UMBRELLA_DIALOGUE
	if _mother != null:
		_mother.visible = true
		_mother.set_logical_position(mother_dialogue_position)
		_mother.face_towards(_player.get_logical_position())

	objective_changed.emit("听妈妈把话说完。")
	if _dialogue == null:
		_finish_umbrella_scene()
		return
	_dialogue.dialogue_finished.connect(_on_umbrella_dialogue_finished, CONNECT_ONE_SHOT)
	_dialogue.play("D005")


func _on_umbrella_dialogue_finished(_root_id: String) -> void:
	_finish_umbrella_scene()


func _finish_umbrella_scene() -> void:
	if _umbrella != null:
		_umbrella.visible = true
		_umbrella.set_interaction_enabled(true)
	if _suitcase != null:
		_suitcase.configure_dialogue("D045", true)
	if _mother != null:
		_mother.set_logical_position(mother_after_dialogue_position)
		# 妈妈就是牵挂线的真实锚点。对白结束后只移动到后续站位，不能隐藏，
		# 否则显线时会看起来像连向空气。
		_mother.visible = true
		_mother.face_towards(_player.get_logical_position())

	current_beat = Beat.P2_LEAVE
	objective_changed.emit("可以再看看房间，然后去门口。")


func _check_reveal() -> void:
	var player_position := _player.get_logical_position()
	if (
		_tie_line == null
		or player_position.x <= reveal_trigger_x
		or player_position.z >= reveal_trigger_z_max
	):
		return
	_tie_line.set_enabled(true)
	_enter_p3_line_reveal()
	current_beat = Beat.FIRST_PULL
	objective_changed.emit("继续向门口走。")
	_emit_debug("[Act01] tie line revealed")


func _on_first_pullback() -> void:
	current_beat = Beat.WAIT_SECOND_REARM
	_play_dialogue("D015")
	objective_changed.emit("线把你拽了回来。")
	_emit_debug("[Act01] first pullback")


func _on_second_pullback() -> void:
	current_beat = Beat.FINAL_DIALOGUE
	if _umbrella != null:
		_umbrella.set_highlight(Color(1.0, 0.18, 0.22, 0.75), true)
	objective_changed.emit("线托住你，又把你拉回房内。")
	if _dialogue == null:
		_finish_act()
		return
	_dialogue.play("D017")
	# play() 会先关闭仍在显示的 D015/D016；必须在其后连接，避免把旧对白结束
	# 误判为 D017→D018 已经播完。
	_dialogue.dialogue_finished.connect(_on_final_dialogue_finished, CONNECT_ONE_SHOT)
	_emit_debug("[Act01] second pullback / support / wrong conclusion")


func _on_final_dialogue_finished(_root_id: String) -> void:
	_finish_act()


func _enter_p3_line_reveal() -> void:
	var red := Color(1.0, 0.18, 0.22, 0.92)
	for node in get_tree().get_nodes_in_group(&"ordinary_line"):
		var line := node as Line2D
		if line != null:
			line.default_color = red

	for child in _room.get_node("Interactables").get_children():
		var interactable := child as Interactable
		if interactable != null and interactable != _thread_clue:
			interactable.set_interaction_enabled(false)
	if _thread_clue != null:
		_thread_clue.set_interaction_enabled(true)
		_thread_clue.set_highlight(red, true)


func _has_reached_pullback() -> bool:
	return (
		_tie_line != null
		and _tie_line.enabled
		and (
			_tie_line.current_state == TieLine.State.PULL_BACK
			or _tie_line.tension >= pullback_trigger_tension
		)
	)


func _is_rearmed() -> bool:
	return (
		_tie_line != null
		and _tie_line.current_state != TieLine.State.PULL_BACK
		and _tie_line.tension <= rearm_tension
	)


func _play_dialogue(dialogue_id: String) -> void:
	if _dialogue != null:
		_dialogue.play(dialogue_id)


func _finish_act() -> void:
	current_beat = Beat.DONE
	objective_changed.emit("第一章完成：牵挂，连接彼此，也限制距离。")
	_emit_debug("[Act01] room chapter finished")
	act_finished.emit()


func _emit_debug(message: String) -> void:
	var panel := get_tree().get_first_node_in_group(&"debug_panel") as DebugPanel
	if panel != null:
		panel.set_last_event(message)
	print(message)
