class_name RoomBase
extends Node2D

@export var room_id: StringName = &"room"
@export var player_spawn_logical := Vector3(5.0, 0.0, 10.2)


func _ready() -> void:
	var player := get_player()
	if player != null:
		player.set_logical_position(player_spawn_logical)

	# Room1 按 F6 单独运行时使用角色自带镜头；嵌入 Main 时继续使用正式 CameraRig。
	var standalone_camera := get_node_or_null("Characters/Player/StandaloneCamera") as Camera2D
	if standalone_camera != null:
		standalone_camera.enabled = get_parent() == get_tree().root


func get_player_spawn() -> Marker2D:
	return get_node_or_null("PlayerSpawn") as Marker2D


func get_player_spawn_logical() -> Vector3:
	return player_spawn_logical


func get_player() -> PlayerController:
	return get_node_or_null("Characters/Player") as PlayerController


func get_camera_point(point_name: StringName) -> Marker2D:
	return get_node_or_null("CameraPoints/%s" % point_name) as Marker2D


## 牵挂线的另一端。房间里没有妈妈时返回 null（后续章节可能没有）。
func get_mother() -> Mother:
	return get_node_or_null("Characters/Mother") as Mother
