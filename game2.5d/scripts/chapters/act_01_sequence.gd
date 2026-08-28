class_name Act01Sequence
extends Node

## 第一章完整闭环：P1 五件必调与物件信息 → 黄伞冲突 → P2 离开尝试
## → P3 显线与强制回弹 → 主动试探真实阻力 → D018 后进入余响。

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
var _observation: FixedObservationUI
var _observation_database: ObservationDatabase
var _camera_rig: CameraRig
var _game_flow: GameFlow
var _game_state: GameState
var _room: RoomBase
var _umbrella: Interactable
var _suitcase: Interactable
var _thread_clue: Interactable
var _photo: Interactable
var _stool: Interactable


func setup(room: RoomBase, player: PlayerController, tie_line: TieLine) -> void:
	_room = room
	_player = player
	_tie_line = tie_line
	_mother = room.get_mother()
	_dialogue = get_tree().get_first_node_in_group(&"dialogue_ui") as DialogueUI
	_observation = get_tree().get_first_node_in_group(&"fixed_observation_ui") as FixedObservationUI
	_observation_database = get_tree().get_first_node_in_group(&"observation_database") as ObservationDatabase
	_camera_rig = get_tree().get_first_node_in_group(&"camera_rig") as CameraRig
	_game_flow = get_tree().get_first_node_in_group(&"game_flow") as GameFlow
	_game_state = get_tree().get_first_node_in_group(&"game_state") as GameState
	_umbrella = room.get_node_or_null("Interactables/Umbrella") as Interactable
	_suitcase = room.get_node_or_null("Interactables/Suitcase") as Interactable
	_thread_clue = room.get_node_or_null("Interactables/ThreadClue") as Interactable
	_photo = room.get_node_or_null("Interactables/PhotoFrame") as Interactable
	_stool = room.get_node_or_null("Interactables/Stool") as Interactable

	for node in get_tree().get_nodes_in_group(&"key_object"):
		var key := node as Interactable
		if key == null:
			continue
		_key_total += 1
		key.interacted.connect(_on_key_object_investigated)

	for child in room.get_node("Interactables").get_children():
		var observable := child as Interactable
		if observable == null or observable.observation_id.is_empty():
			continue
		observable.auto_play_dialogue = false
		observable.interaction_prompt_override = "Enter / 空格  查看：%s" % observable.display_name
		observable.interacted.connect(_on_observation_interacted.bind(observable))

	if _photo != null:
		_photo.set_interaction_enabled(false)
	if _stool != null:
		_stool.auto_play_dialogue = false
		_stool.interacted.connect(_on_stool_used)
	if _tie_line != null:
		_tie_line.set_enabled(false)
		_tie_line.clear_context()
	if _thread_clue != null:
		_thread_clue.set_interaction_enabled(false)
	_update_explore_objective()


func _process(_delta: float) -> void:
	_update_tension_context()
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

	# interacted 在对白或固定观察真正结束之前发出，必须等玩家回到房间后再进冲突。
	await get_tree().process_frame
	if _observation != null and _observation.is_open():
		await _observation.observation_closed
	if _dialogue != null and _dialogue.is_playing():
		await _dialogue.dialogue_finished
	_start_umbrella_scene()


func _on_stool_used(_player_ref: PlayerController) -> void:
	if current_beat != Beat.P1_EXPLORE or _photo == null:
		return
	_photo.set_interaction_enabled(true)
	_photo.set_highlight(Color(1.0, 0.92, 0.72, 0.25), true)
	_set_story_flag(&"chapter1_photo_unlocked")
	objective_changed.emit("木凳放稳了，现在能看清柜顶相框。（%d/%d）" % [_investigated_keys, _key_total])
	_emit_debug("[Act01] stool placed / photo unlocked")


func _on_observation_interacted(_player_ref: PlayerController, target: Interactable) -> void:
	if _observation == null or _observation_database == null:
		return
	var copy := _observation_database.get_entry(target.observation_id)
	if copy.is_empty():
		return
	if _camera_rig != null:
		_camera_rig.move_to(target, Vector2(1.55, 1.55), 0.32)
	_observation.observation_closed.connect(_on_observation_closed, CONNECT_ONE_SHOT)
	_observation.open_observation(
		target.name,
		str(copy.get("title", target.display_name)),
		str(copy.get("body", ""))
	)


func _on_observation_closed(object_id: String) -> void:
	if _camera_rig != null:
		_camera_rig.follow(_player, Vector2.ONE, true)
	var target := _room.get_node_or_null("Interactables/%s" % object_id) as Interactable
	if target == null or _observation_database == null:
		return
	var copy := _observation_database.get_entry(target.observation_id)
	var dialogue_id := str(copy.get("dialogue_id", ""))
	if not dialogue_id.is_empty():
		_play_dialogue(dialogue_id)


func _update_explore_objective() -> void:
	objective_changed.emit("整理离家前的东西（%d/%d）；柜顶相框需要先移动木凳。" % [_investigated_keys, _key_total])


func _start_umbrella_scene() -> void:
	if current_beat != Beat.P1_EXPLORE:
		return
	current_beat = Beat.UMBRELLA_DIALOGUE
	_set_story_flag(&"chapter1_p1_complete")
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
		_umbrella.reset_interaction()
	if _suitcase != null:
		_suitcase.configure_dialogue("D045", true)
		_suitcase.configure_observation("O045", false)
	if _mother != null:
		_mother.set_logical_position(mother_after_dialogue_position)
		_mother.visible = true
		_mother.face_towards(_player.get_logical_position())

	current_beat = Beat.P2_LEAVE
	objective_changed.emit("可以再看看行李和黄伞，然后去门口。")


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
	_set_story_flag(&"chapter1_tie_revealed")
	objective_changed.emit("继续向门口走。")
	_emit_debug("[Act01] tie line revealed")


func _on_first_pullback() -> void:
	current_beat = Beat.WAIT_SECOND_REARM
	_set_story_flag(&"chapter1_first_pullback")
	_play_dialogue("D015")
	objective_changed.emit("线把你拽了回来。")
	_emit_debug("[Act01] first pullback")


func _on_second_pullback() -> void:
	current_beat = Beat.FINAL_DIALOGUE
	objective_changed.emit("主动触碰并拉动这根线，确认它具有真实阻力。")
	if _dialogue == null:
		_finish_resistance_test_and_act()
		return
	_dialogue.play("D017")
	# play() 会先结束仍在显示的 D015/D016；连接必须放在调用之后。
	_dialogue.dialogue_finished.connect(_on_final_dialogue_finished, CONNECT_ONE_SHOT)
	_emit_debug("[Act01] second attempt / physical resistance confirmed")


func _on_final_dialogue_finished(_root_id: String) -> void:
	_finish_resistance_test_and_act()


func _finish_resistance_test_and_act() -> void:
	if _tie_line != null:
		_tie_line.clear_context()
	_set_story_flag(&"chapter1_resistance_confirmed")
	_emit_debug("[Act01] resistance understood incorrectly / entering echo")
	_finish_act()


func _enter_p3_line_reveal() -> void:
	var red := Color(1.0, 0.18, 0.22, 0.92)
	for node in get_tree().get_nodes_in_group(&"ordinary_line"):
		var line := node as Line2D
		if line != null:
			line.default_color = red

	for child in _room.get_node("Interactables").get_children():
		var interactable := child as Interactable
		if interactable != null:
			interactable.set_interaction_enabled(false)
	if _thread_clue != null:
		_thread_clue.set_interaction_enabled(true)
		_thread_clue.set_highlight(red, true)


func _update_tension_context() -> void:
	if _tie_line == null or current_beat < Beat.P2_LEAVE or current_beat >= Beat.FINAL_DIALOGUE:
		return
	var player_position := _player.get_logical_position()
	var exit_span := maxf(_player.movement_max.x - reveal_trigger_x, 0.01)
	var exit_progress := clampf((player_position.x - reveal_trigger_x) / exit_span, 0.0, 1.0)
	var intention_conflict := 0.08 if player_position.x > reveal_trigger_x - 0.8 else 0.0
	var emotional_pressure := 0.14 if current_beat >= Beat.SECOND_ATTEMPT else 0.10
	_tie_line.set_context(emotional_pressure, intention_conflict, exit_progress)


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
	_set_story_flag(&"chapter1_complete")
	if _game_flow != null:
		_game_flow.set_mode(GameFlow.Mode.CUTSCENE)
	objective_changed.emit("第一章完成：黄伞与牵挂线唤醒了 2009 年秋天的余响。")
	_emit_debug("[Act01] chapter finished / echo transition")
	act_finished.emit()


func get_investigated_key_count() -> int:
	return _investigated_keys


func get_key_total() -> int:
	return _key_total


func _set_story_flag(flag_name: StringName) -> void:
	if _game_state != null:
		_game_state.set_flag(flag_name)


func _emit_debug(message: String) -> void:
	var panel := get_tree().get_first_node_in_group(&"debug_panel") as DebugPanel
	if panel != null:
		panel.set_last_event(message)
	print(message)
