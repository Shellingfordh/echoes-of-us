class_name Mother
extends Node2D

@export var logical_position := Vector3(7.0, 0.0, 7.5)
@export var anchor_height := 1.05

@onready var _sprite: AnimatedSprite2D = $Sprite2D

var _move_tween: Tween
var _facing_away := false
## 当前朝向：down / up / left / right。停下来后保留，idle 不会自己转回正面。
var _facing := StringName("down")


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
	_apply_facing(Projection25D.project_direction(target - logical_position))


func face_away_from(target: Vector3) -> void:
	_facing_away = true
	# 背对玩家：把朝向量反过来再解析，这样"背对"在四向贴图里
	# 落到真正的背面那一排，而不是靠水平翻转假装转身。
	_apply_facing(-Projection25D.project_direction(target - logical_position))


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
	# 先按行进方向定朝向，再起步。_move_tween 非空时 _apply_facing 会播 walk，
	# 所以顺序必须是"建好 tween 再定朝向"，否则她会拖着 idle 的姿势平移过去。
	_face_along(destination - start)
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
	# 站定后收回 idle，朝向保持走过来的那一面。
	_play(&"idle")


## 沿位移方向转身，不改 _facing_away 的语义（那是剧本用来记"背对玩家"的）。
func _face_along(delta: Vector3) -> void:
	_apply_facing(Projection25D.project_direction(delta))


## 屏幕方向决定用哪一排贴图：横向压过纵向就走左右，否则走上下。
## 判据用投影后的屏幕向量而不是逻辑 XZ，因为等距投影把两条轴各转了 45°。
func _apply_facing(screen_direction: Vector2) -> void:
	if not screen_direction.is_zero_approx():
		if absf(screen_direction.x) >= absf(screen_direction.y):
			_facing = &"right" if screen_direction.x > 0.0 else &"left"
		else:
			_facing = &"down" if screen_direction.y > 0.0 else &"up"
	_play(&"idle" if _move_tween == null else &"walk")


## 有四向贴图就用四向，没有就退回 idle / walk 加 flip_h。
func _play(base: StringName) -> void:
	if not is_instance_valid(_sprite):
		return
	var frames := _sprite.sprite_frames
	var directional := StringName("%s_%s" % [base, _facing])
	if frames != null and frames.has_animation(directional):
		_sprite.flip_h = false
		_sprite.play(directional)
		return
	if frames != null and frames.has_animation(base):
		_sprite.flip_h = _facing == &"left"
		_sprite.play(base)


func _sync_projection() -> void:
	global_position = Projection25D.project(logical_position)
	z_index = Projection25D.depth_index(logical_position) + 3
