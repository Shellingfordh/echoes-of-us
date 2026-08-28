class_name GameFlow
extends Node

signal mode_changed(previous_mode: Mode, current_mode: Mode)

enum Mode {
	EXPLORE,
	DIALOGUE,
	PUZZLE,
	CHALLENGE,
	CUTSCENE,
	PAUSED,
}

@export var initial_mode: Mode = Mode.EXPLORE

var current_mode: Mode


func _ready() -> void:
	add_to_group(&"game_flow")
	current_mode = initial_mode


func set_mode(next_mode: Mode) -> void:
	if next_mode == current_mode:
		return
	var previous_mode := current_mode
	current_mode = next_mode
	mode_changed.emit(previous_mode, current_mode)


func is_player_control_enabled() -> bool:
	return current_mode == Mode.EXPLORE or current_mode == Mode.CHALLENGE
