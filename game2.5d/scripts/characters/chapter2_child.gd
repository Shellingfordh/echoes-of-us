class_name Chapter2Child
extends Node2D

## 第二章七岁余念。画面仍由 2D 贴图组成，MathBody 在隐藏的 XYZ 世界里移动。
## 地面阶段只使用 XZ；坠落和攀线阶段才允许 Y 改变。

@export var move_speed := 4.2
@export var climb_speed := 0.8
@export var anchor_height := 0.72
@export var movement_min := Vector2(0.0, 0.0)
@export var movement_max := Vector2(192.0, 28.0)
## 行走所在的地面高度。地面阶段是 0，掉进坑底后是坑底面的 y（负值）。
## 有了它，同一套 WASD 逻辑就能在坑底那张横面上走，不必再另开一个模式。
@export var floor_height := 0.0

@onready var math_body: CharacterBody3D = $MathBody
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_shadow: Polygon2D = get_node_or_null("GroundShadow") as Polygon2D
@onready var umbrella: Node2D = $Umbrella

var _control_enabled := false
var _climbing := false
var _game_flow: GameFlow
var _climb_target := Vector3.ZERO
## 当前朝向：down / up / left / right。停下后保留，idle 不会自己转回正面。
var _facing := StringName("down")
var _moving := false
## 姿态覆盖：空表示走正常四向贴图；climb / bounce 时锁定成单张特写。
var _pose := StringName("")


func _ready() -> void:
	add_to_group(&"chapter2_child")
	_sync_projection()


func _physics_process(delta: float) -> void:
	_game_flow = _get_game_flow()
	if not _control_enabled:
		# 没有操作权时，位置由剧本用 set_logical_position 推动（跟随母亲、绕水坑等），
		# 行走动画也由剧本用 set_moving 指定。这里只清速度，绝不覆盖动画状态，
		# 否则每个物理帧都会把剧本设的 walk 打回 idle，跟随时看着像在平移。
		math_body.velocity = Vector3.ZERO
		return
	if _game_flow != null and not _game_flow.is_player_control_enabled():
		# 有操作权但被对话/过场冻结：这是真的该站定。
		math_body.velocity = Vector3.ZERO
		set_moving(false)
		return

	if _climbing:
		_update_climb(delta)
		return

	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var direction := _screen_input_to_logical_direction(input)
	math_body.velocity = direction * move_speed
	math_body.move_and_slide()
	var logical := math_body.position
	logical.x = clampf(logical.x, movement_min.x, movement_max.x)
	logical.y = floor_height
	logical.z = clampf(logical.z, movement_min.y, movement_max.y)
	math_body.position = logical
	set_moving(not direction.is_zero_approx())
	if not direction.is_zero_approx():
		face_screen_vector(Projection25D.project_direction(direction))
	_sync_projection()


func set_control_enabled(value: bool) -> void:
	_control_enabled = value
	if not value and is_instance_valid(math_body):
		math_body.velocity = Vector3.ZERO
		set_moving(false)


func is_control_enabled() -> bool:
	return _control_enabled


func set_ground_bounds(minimum: Vector2, maximum: Vector2) -> void:
	movement_min = minimum
	movement_max = maximum


## 换一张可行走的横面：坑底给 -4.8，地面给 0。
## 同时把角色贴到新高度上，避免下一物理帧才被 clamp 拉过去造成一帧的抖动。
func set_floor_height(value: float) -> void:
	floor_height = value
	if is_instance_valid(math_body):
		var logical := math_body.position
		logical.y = value
		math_body.position = logical
		_sync_projection()


func begin_climb(target: Vector3) -> void:
	_climbing = true
	_climb_target = target
	set_control_enabled(true)
	# 按 W 沿线往上爬这一整段换成攀爬特写，爬上去后由 end_climb 收回。
	set_pose(&"climb")
	if is_instance_valid(ground_shadow):
		ground_shadow.hide()


func end_climb() -> void:
	_climbing = false
	set_control_enabled(false)
	set_pose(&"")
	if is_instance_valid(ground_shadow):
		ground_shadow.show()


func is_climbing() -> bool:
	return _climbing


func has_reached_climb_target() -> bool:
	return _climbing and get_logical_position().distance_to(_climb_target) <= 0.02


func set_logical_position(value: Vector3) -> void:
	math_body.position = value
	_sync_projection()


func get_logical_position() -> Vector3:
	return math_body.position if is_instance_valid(math_body) else Vector3.ZERO


func get_logical_anchor_position() -> Vector3:
	return get_logical_position() + Vector3.UP * anchor_height


func get_anchor_position() -> Vector2:
	return Projection25D.project(get_logical_anchor_position())


func set_moving(value: bool) -> void:
	_moving = value
	_play()


## 攀爬 / 弹跳这类整段动作用单张特写顶掉四向贴图。
## 传空字符串就回到正常的 idle / walk。
func set_pose(pose: StringName) -> void:
	_pose = pose
	_play()


func get_pose() -> StringName:
	return _pose


## 只拿到屏幕水平分量时的兼容入口：仍按左右解析，纵向朝向保持不变。
func face_screen_direction(direction: float) -> void:
	if is_zero_approx(direction):
		return
	_facing = &"right" if direction > 0.0 else &"left"
	_play()


## 有完整屏幕向量时按四向解析：横向压过纵向就走左右，否则走上下。
## 判据用投影后的屏幕向量而不是逻辑 XZ，因为等距投影把两条轴各转了 45°。
func face_screen_vector(screen_direction: Vector2) -> void:
	if screen_direction.is_zero_approx():
		return
	if absf(screen_direction.x) >= absf(screen_direction.y):
		_facing = &"right" if screen_direction.x > 0.0 else &"left"
	else:
		_facing = &"down" if screen_direction.y > 0.0 else &"up"
	_play()


## 有四向贴图就用四向，没有就退回 idle / walk 加 flip_h。
func _play() -> void:
	if not is_instance_valid(animated_sprite):
		return
	var frames := animated_sprite.sprite_frames
	if frames == null:
		return
	if _pose != &"" and frames.has_animation(_pose):
		animated_sprite.flip_h = false
		animated_sprite.play(_pose)
		return
	var base := &"walk" if _moving else &"idle"
	var directional := StringName("%s_%s" % [base, _facing])
	if frames.has_animation(directional):
		animated_sprite.flip_h = false
		animated_sprite.play(directional)
		return
	if frames.has_animation(base):
		animated_sprite.flip_h = _facing == &"left"
		animated_sprite.play(base)


func set_umbrella_raised(value: bool) -> void:
	if not is_instance_valid(umbrella):
		return
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(umbrella, "rotation", -0.65 if value else 0.0, 0.28)
	tween.parallel().tween_property(umbrella, "position", Vector2(-20, -56) if value else Vector2(8, -40), 0.28)


func _update_climb(delta: float) -> void:
	# 教学关明确只接受 W / 上方向。角色沿绳斜向攀往坑的另一侧；
	# 松开后保持当前位置，不自动完成，也不会落回断板处。
	var climbing_up := Input.is_action_pressed(&"move_up")
	math_body.velocity = Vector3.ZERO
	if climbing_up:
		math_body.position = math_body.position.move_toward(_climb_target, climb_speed * delta)
	set_moving(climbing_up)
	_sync_projection()


func _screen_input_to_logical_direction(input: Vector2) -> Vector3:
	if input.is_zero_approx():
		return Vector3.ZERO
	return Vector3(input.x + input.y, 0.0, input.y - input.x).normalized()


func _sync_projection() -> void:
	if not is_instance_valid(math_body):
		return
	global_position = Projection25D.project(math_body.position)
	z_index = Projection25D.depth_index(math_body.position) + 7
	if is_instance_valid(ground_shadow):
		# 影子跟着"当前脚下那张面"，所以判据是相对 floor_height 而不是绝对 0。
		# 在坑底走路时脚是踩实的，影子该在；坠落 / 攀线时离地，影子该消失。
		ground_shadow.visible = not _climbing and math_body.position.y >= floor_height - 0.05


func _get_game_flow() -> GameFlow:
	if is_instance_valid(_game_flow):
		return _game_flow
	return get_tree().get_first_node_in_group(&"game_flow") as GameFlow
