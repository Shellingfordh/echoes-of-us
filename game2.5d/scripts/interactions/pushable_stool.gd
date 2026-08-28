class_name PushableStool
extends Interactable

## 可推动木椅：画面使用 2D 占位图，隐藏 CharacterBody3D 在 X/Z 地面上碰撞。

signal placement_state_changed(in_target: bool)
signal mounted_state_changed(mounted: bool)

@export var push_speed := 2.15
@export var top_height := 0.82
## 目标区跟着场景里的黄框走：填了 target_marker_path 就以标记的位置为准，
## 美术/关卡挪动黄框时不需要再同步改这里的数值。
@export var target_marker_path: NodePath
@export var target_position := Vector3(3.0, 0.0, 3.1)
@export var target_radius := 0.6
@export var movement_min := Vector2(1.45, 1.35)
@export var movement_max := Vector2(16.2, 10.4)

var _mounted_player: PlayerController
var _was_in_target := false

@onready var _push_body: CharacterBody3D = $MathBody as CharacterBody3D


func _ready() -> void:
	super()
	_sync_target_from_marker()
	_was_in_target = is_in_target_zone()


func _sync_target_from_marker() -> void:
	if target_marker_path.is_empty():
		return
	var marker := get_node_or_null(target_marker_path)
	if marker == null or not marker.has_method(&"get_logical_position"):
		push_warning("[PushableStool] target_marker_path 指向的节点没有逻辑坐标：%s" % target_marker_path)
		return
	var marker_position: Vector3 = marker.get_logical_position()
	target_position = Vector3(marker_position.x, 0.0, marker_position.z)


func get_interaction_prompt() -> String:
	return "方向键推动木椅；空格跳上木椅"


func can_be_player_target() -> bool:
	return interaction_enabled


func try_push(direction: Vector3) -> bool:
	if (
		not interaction_enabled
		or not is_instance_valid(_push_body)
		or is_player_mounted()
		or direction.is_zero_approx()
	):
		return false
	_push_body.velocity = direction.normalized() * push_speed
	_push_body.move_and_slide()
	_push_body.velocity = Vector3.ZERO

	var next_position := _push_body.position
	next_position.x = clampf(next_position.x, movement_min.x, movement_max.x)
	next_position.y = 0.0
	next_position.z = clampf(next_position.z, movement_min.y, movement_max.y)
	_push_body.position = next_position
	logical_position = next_position
	_sync_projection()
	_update_target_state()
	return true


func set_mounted_player(player: PlayerController) -> void:
	_mounted_player = player
	mounted_state_changed.emit(true)


func clear_mounted_player(player: PlayerController) -> void:
	if _mounted_player != player:
		return
	_mounted_player = null
	mounted_state_changed.emit(false)


func is_player_mounted() -> bool:
	return is_instance_valid(_mounted_player)


func is_in_target_zone() -> bool:
	var ground := Vector2(logical_position.x, logical_position.z)
	var target_ground := Vector2(target_position.x, target_position.z)
	return ground.distance_to(target_ground) <= target_radius


func get_mount_position() -> Vector3:
	return Vector3(logical_position.x, top_height, logical_position.z)


func _update_target_state() -> void:
	var in_target := is_in_target_zone()
	if in_target == _was_in_target:
		return
	_was_in_target = in_target
	placement_state_changed.emit(in_target)
