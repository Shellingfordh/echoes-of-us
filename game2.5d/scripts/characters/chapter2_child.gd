class_name Chapter2Child
extends Node2D

## 第二章七岁余念。画面仍由 2D 贴图组成，MathBody 在隐藏的 XYZ 世界里移动。
## 地面阶段只使用 XZ；坠落和攀线阶段才允许 Y 改变。

@export var move_speed := 4.2
@export var climb_speed := 0.8
@export var anchor_height := 0.72
@export var movement_min := Vector2(0.0, 0.0)
@export var movement_max := Vector2(192.0, 28.0)

@onready var math_body: CharacterBody3D = $MathBody
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_shadow: Polygon2D = $GroundShadow
@onready var umbrella: Node2D = $Umbrella

var _control_enabled := false
var _climbing := false
var _game_flow: GameFlow
var _climb_target := Vector3.ZERO


func _ready() -> void:
	add_to_group(&"chapter2_child")
	_sync_projection()


func _physics_process(delta: float) -> void:
	_game_flow = _get_game_flow()
	if not _control_enabled or (_game_flow != null and not _game_flow.is_player_control_enabled()):
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
	logical.y = 0.0
	logical.z = clampf(logical.z, movement_min.y, movement_max.y)
	math_body.position = logical
	set_moving(not direction.is_zero_approx())
	if not direction.is_zero_approx():
		face_screen_direction(Projection25D.project_direction(direction).x)
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


func begin_climb(target: Vector3) -> void:
	_climbing = true
	_climb_target = target
	set_control_enabled(true)
	if is_instance_valid(ground_shadow):
		ground_shadow.hide()


func end_climb() -> void:
	_climbing = false
	set_control_enabled(false)
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
	if not is_instance_valid(animated_sprite):
		return
	animated_sprite.play(&"walk" if value else &"idle")


func face_screen_direction(direction: float) -> void:
	if is_instance_valid(animated_sprite) and not is_zero_approx(direction):
		animated_sprite.flip_h = direction < 0.0


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
		ground_shadow.visible = not _climbing and math_body.position.y >= -0.05


func _get_game_flow() -> GameFlow:
	if is_instance_valid(_game_flow):
		return _game_flow
	return get_tree().get_first_node_in_group(&"game_flow") as GameFlow
