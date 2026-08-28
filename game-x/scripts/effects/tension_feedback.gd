class_name TensionFeedback
extends Node

## 高张力只让房间里原本存在的普通线轻微受扰，不改变它们的颜色或超自然属性。

@export_range(0.0, 1.0, 0.01) var activation_tension := 0.62
@export var maximum_offset_pixels := 2.4
@export var response_speed := 5.5
@export var motion_frequency := 13.0

var _tie_line: TieLine
var _ordinary_lines: Array[Node2D] = []
var _base_positions: Dictionary = {}
var _feedback_strength := 0.0
var _phase := 0.0


func _ready() -> void:
	for node in get_tree().get_nodes_in_group(&"ordinary_line"):
		var line := node as Node2D
		if line == null or not is_ancestor_of(line):
			continue
		_ordinary_lines.append(line)
		_base_positions[line] = line.position


func _process(delta: float) -> void:
	_tie_line = _get_tie_line()
	var target_strength := 0.0
	if _tie_line != null and _tie_line.current_state != TieLine.State.HIDDEN:
		target_strength = smoothstep(activation_tension, 1.0, _tie_line.tension)
		if _tie_line.current_state == TieLine.State.PULL_BACK:
			target_strength = 1.0
	_feedback_strength = move_toward(_feedback_strength, target_strength, response_speed * delta)
	_phase += delta * motion_frequency
	for index in range(_ordinary_lines.size()):
		var line := _ordinary_lines[index]
		if not is_instance_valid(line):
			continue
		var phase_offset := float(index) * 1.73
		var displacement := Vector2(
			sin(_phase + phase_offset) * 0.38,
			cos(_phase * 1.17 + phase_offset) * 1.0
		) * maximum_offset_pixels * _feedback_strength
		line.position = (_base_positions.get(line, Vector2.ZERO) as Vector2) + displacement


func get_feedback_strength() -> float:
	return _feedback_strength


func _get_tie_line() -> TieLine:
	if is_instance_valid(_tie_line):
		return _tie_line
	return get_tree().get_first_node_in_group(&"tie_line") as TieLine


func _exit_tree() -> void:
	for line in _ordinary_lines:
		if is_instance_valid(line):
			line.position = _base_positions.get(line, line.position)
