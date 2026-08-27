class_name CameraRig
extends Node2D

## Reusable 2D camera controller shared by every chapter.

@export var default_transition_duration: float = 0.6
@export var default_zoom: Vector2 = Vector2.ONE

@onready var camera: Camera2D = $Camera2D

var _follow_target: Node2D
var _follow_vertical := false
var _active_tween: Tween


func _process(_delta: float) -> void:
	if is_instance_valid(_follow_target):
		var next_position := _follow_target.global_position
		if not _follow_vertical:
			next_position.y = global_position.y
		global_position = next_position


func snap_to(target: Node2D, target_zoom: Vector2 = default_zoom) -> void:
	_cancel_transition()
	_follow_target = null
	global_position = target.global_position
	camera.zoom = target_zoom
	camera.reset_smoothing()


func move_to(
	target: Node2D,
	target_zoom: Vector2 = default_zoom,
	duration: float = default_transition_duration
) -> void:
	_cancel_transition()
	_follow_target = null

	_active_tween = create_tween().set_parallel()
	_active_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_active_tween.tween_property(self, "global_position", target.global_position, duration)
	_active_tween.tween_property(camera, "zoom", target_zoom, duration)


func follow(
	target: Node2D,
	target_zoom: Vector2 = default_zoom,
	follow_vertical: bool = false
) -> void:
	_cancel_transition()
	_follow_target = target
	_follow_vertical = follow_vertical
	camera.zoom = target_zoom


func stop_following() -> void:
	_follow_target = null


func _cancel_transition() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null
