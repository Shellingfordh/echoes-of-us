class_name RoomBase
extends Node2D

@export var room_id: StringName = &"room"
@export var player_spawn_logical := Vector3(5.0, 0.0, 10.2)


func get_player_spawn() -> Marker2D:
	return get_node_or_null("PlayerSpawn") as Marker2D


func get_player_spawn_logical() -> Vector3:
	return player_spawn_logical


func get_camera_point(point_name: StringName) -> Marker2D:
	return get_node_or_null("CameraPoints/%s" % point_name) as Marker2D


## 牵挂线的另一端。房间里没有妈妈时返回 null（后续章节可能没有）。
func get_mother() -> Mother:
	return get_node_or_null("Characters/Mother") as Mother
