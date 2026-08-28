class_name Chapter2Child
extends Node2D

## 第二章小余念：仍然是 2D 角色，逻辑坐标允许出现负 Y，以表现掉入坑中。

@export var logical_position := Vector3.ZERO
@export var anchor_height := 0.82

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_shadow: Polygon2D = $GroundShadow


func _ready() -> void:
	add_to_group(&"chapter2_child")
	_sync_projection()


func set_logical_position(value: Vector3) -> void:
	logical_position = value
	_sync_projection()


func get_logical_position() -> Vector3:
	return logical_position


func get_logical_anchor_position() -> Vector3:
	return logical_position + Vector3.UP * anchor_height


func get_anchor_position() -> Vector2:
	return Projection25D.project(get_logical_anchor_position())


func set_moving(value: bool) -> void:
	if not is_instance_valid(animated_sprite):
		return
	animated_sprite.play(&"walk" if value else &"idle")


func face_screen_direction(direction: float) -> void:
	if is_instance_valid(animated_sprite) and not is_zero_approx(direction):
		animated_sprite.flip_h = direction < 0.0


func _sync_projection() -> void:
	global_position = Projection25D.project(logical_position)
	z_index = Projection25D.depth_index(logical_position) + 5
	if is_instance_valid(ground_shadow):
		ground_shadow.visible = logical_position.y >= -0.05

