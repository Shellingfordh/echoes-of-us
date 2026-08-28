class_name Mother
extends Node2D

@export var logical_position := Vector3(7.0, 0.0, 7.5)
@export var anchor_height := 1.05

@onready var _sprite: Sprite2D = $Sprite2D

var _move_tween: Tween
var _facing_away := false


func _ready() -> void:
	add_to_group(&"mother")
	_sync_projection()


func set_logical_position(value: Vector3) -> void:
	logical_position = Vector3(value.x, 0.0, value.z)
	_sync_projection()


func get_logical_position() -> Vector3:
	return logical_position


func get_logical_anchor_position() -> Vector3:
	return logical_position + Vector3.UP * anchor_height


func get_anchor_position() -> Vector2:
	return Projection25D.project(get_logical_anchor_position())


func face_towards(target: Vector3) -> void:
	_facing_away = false
	if is_instance_valid(_sprite):
		var direction := Projection25D.project_direction(target - logical_position)
		_sprite.flip_h = direction.x < 0.0


func face_away_from(target: Vector3) -> void:
	_facing_away = true
	if is_instance_valid(_sprite):
		var direction := Projection25D.project_direction(target - logical_position)
		_sprite.flip_h = direction.x >= 0.0


func is_facing_away() -> bool:
	return _facing_away


func move_to_logical(target: Vector3, duration: float = 1.1) -> void:
	var destination := Vector3(target.x, 0.0, target.z)
	if _move_tween != null:
		_move_tween.kill()
	if duration <= 0.0 or logical_position.is_equal_approx(destination):
		set_logical_position(destination)
		return
	var start := logical_position
	_move_tween = create_tween()
	_move_tween.set_trans(Tween.TRANS_SINE)
	_move_tween.set_ease(Tween.EASE_IN_OUT)
	_move_tween.tween_method(
		func(weight: float) -> void:
			set_logical_position(start.lerp(destination, weight)),
		0.0,
		1.0,
		duration
	)
	await _move_tween.finished
	set_logical_position(destination)
	_move_tween = null


func _sync_projection() -> void:
	global_position = Projection25D.project(logical_position)
	z_index = Projection25D.depth_index(logical_position) + 3
