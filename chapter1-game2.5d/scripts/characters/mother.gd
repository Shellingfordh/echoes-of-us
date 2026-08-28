class_name Mother
extends Node2D

@export var logical_position := Vector3(7.0, 0.0, 7.5)
@export var anchor_height := 1.05

@onready var _sprite: Sprite2D = $Sprite2D


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
	if is_instance_valid(_sprite):
		var direction := Projection25D.project_direction(target - logical_position)
		_sprite.flip_h = direction.x < 0.0


func _sync_projection() -> void:
	global_position = Projection25D.project(logical_position)
	z_index = Projection25D.depth_index(logical_position) + 3
