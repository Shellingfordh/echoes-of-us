class_name DebugPanel
extends Label

## architecture.md §16：调机制时能直接看到数值，
## 免得策划问"我走到这里为什么没触发"时只能猜。
## F3 开关，默认关闭。

@export var start_visible := false

var _tie_line: TieLine
var _player: PlayerController
var _mother: Mother
var _game_flow: GameFlow
var _game_state: GameState
var _last_event_id := "-"


func _ready() -> void:
	add_to_group(&"debug_panel")
	visible = start_visible


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_toggle"):
		visible = not visible
		get_viewport().set_input_as_handled()


func set_last_event(event_id: String) -> void:
	_last_event_id = event_id


func _process(_delta: float) -> void:
	if not visible:
		return
	_resolve_refs()

	var lines: Array[String] = []
	lines.append("[F3] DEBUG")

	if _player != null:
		lines.append("player 3D   %s" % _vec3(_player.get_logical_position()))
	if _mother != null:
		lines.append("mother 3D   %s" % _vec3(_mother.get_logical_position()))

	if _tie_line != null:
		lines.append("distance    %6.1f / %.1f" % [
			_tie_line.distance,
			_tie_line.get_effective_max_distance(),
		])
		lines.append("tension     %6.2f  %s" % [
			_tie_line.tension,
			_bar(_tie_line.tension),
		])
		lines.append("context     emo %.2f | intent %.2f | exit %.2f" % [
			_tie_line.emotional_pressure,
			_tie_line.intention_conflict,
			_tie_line.exit_progress,
		])
		lines.append("line_state  %s%s" % [
			_tie_line.get_state_name(),
			"  (EXTENDED)" if _tie_line.extended else "",
		])
		lines.append("thresholds  reveal %.0f | tense %.0f | max %.0f" % [
			_tie_line.reveal_distance,
			_tie_line.tension_distance,
			_tie_line.max_distance,
		])
		lines.append("critical     distance %.2f | tension %.3f" % [
			_tie_line.get_critical_distance(),
			_tie_line.critical_tension,
		])
	else:
		lines.append("line_state  <no TieLine>")

	if _game_flow != null:
		lines.append("game_mode   %s" % GameFlow.Mode.keys()[_game_flow.current_mode])
	if _game_state != null:
		lines.append("room        %s" % _game_state.current_room)
		lines.append("flags       %d   items %d" % [
			_game_state.story_flags.size(),
			_game_state.inventory.size(),
		])
	lines.append("last_event  %s" % _last_event_id)

	text = "\n".join(lines)


func _resolve_refs() -> void:
	if not is_instance_valid(_tie_line):
		_tie_line = get_tree().get_first_node_in_group(&"tie_line") as TieLine
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as PlayerController
	if not is_instance_valid(_mother):
		_mother = get_tree().get_first_node_in_group(&"mother") as Mother
	if not is_instance_valid(_game_flow):
		_game_flow = get_tree().get_first_node_in_group(&"game_flow") as GameFlow
	if not is_instance_valid(_game_state):
		_game_state = get_tree().get_first_node_in_group(&"game_state") as GameState


func _vec(value: Vector2) -> String:
	return "(%7.1f, %7.1f)" % [value.x, value.y]


func _vec3(value: Vector3) -> String:
	return "(%5.1f, %5.1f, %5.1f)" % [value.x, value.y, value.z]


func _bar(value: float) -> String:
	var filled := int(roundf(clampf(value, 0.0, 1.0) * 10.0))
	return "[%s%s]" % ["#".repeat(filled), ".".repeat(10 - filled)]
