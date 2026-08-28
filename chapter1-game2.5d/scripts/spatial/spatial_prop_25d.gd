class_name SpatialProp25D
extends Node2D

## 静态家具的 2.5D 包装：StaticBody3D 负责碰撞，Node2D 子节点负责画面。

@export var logical_position: Vector3 = Vector3.ZERO

## 同格物件的先后微调（正数更靠前），墙面物件用 Projection25D.BAND_WALL。
@export var depth_offset := 0

@onready var _math_body: StaticBody3D = get_node_or_null("MathBody") as StaticBody3D


func _ready() -> void:
	_sync_projection()


func set_logical_position(value: Vector3) -> void:
	logical_position = value
	_sync_projection()


func get_logical_position() -> Vector3:
	return logical_position


func _sync_projection() -> void:
	if is_instance_valid(_math_body):
		_math_body.position = logical_position
	global_position = Projection25D.project(logical_position)
	z_index = Projection25D.depth_index(logical_position) + depth_offset
