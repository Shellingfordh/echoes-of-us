class_name PlayerController
extends Node2D

## 可见角色仍是 2D，隐藏的 CharacterBody3D 在 X/Z 平面上负责真实移动与碰撞。

@export var move_speed := 3.8
@export var movement_min := Vector2(1.0, 1.0)
@export var movement_max := Vector2(17.0, 11.0)
@export var anchor_height := 1.05
@export var pull_back_stiffness := 6.0
@export var max_pull_speed := 5.5

@onready var math_body: CharacterBody3D = $MathBody
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea

var _game_flow: GameFlow
var _current_interactable: Area2D
var _tie_line: TieLine

var logical_position: Vector3:
	get:
		return get_logical_position()
	set(value):
		set_logical_position(value)


func _ready() -> void:
	add_to_group(&"player")
	_sync_projection()


func _physics_process(_delta: float) -> void:
	_game_flow = _get_game_flow()
	if _game_flow != null and not _game_flow.is_player_control_enabled():
		math_body.velocity = Vector3.ZERO
		_play_idle_animation()
		_update_interaction_target()
		return

	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var direction := _screen_input_to_logical_direction(input)
	var input_velocity := direction * move_speed * _get_speed_scale(direction)
	var pull_velocity := _get_tie_line_pull_velocity()
	math_body.velocity = input_velocity + pull_velocity
	math_body.move_and_slide()

	var logical := math_body.position
	logical.x = clampf(logical.x, movement_min.x, movement_max.x)
	logical.y = 0.0
	logical.z = clampf(logical.z, movement_min.y, movement_max.y)
	math_body.position = logical
	_sync_projection()

	var visual_motion := direction
	if not pull_velocity.is_zero_approx():
		visual_motion = math_body.get_real_velocity()
		visual_motion.y = 0.0
	if visual_motion.is_zero_approx():
		_play_idle_animation()
	else:
		var screen_direction := Projection25D.project_direction(visual_motion.normalized())
		if not is_zero_approx(screen_direction.x):
			animated_sprite.flip_h = screen_direction.x < 0.0
		animated_sprite.play(&"walk")

	_update_interaction_target()


func set_logical_position(value: Vector3) -> void:
	math_body.position = Vector3(value.x, 0.0, value.z)
	_sync_projection()


## WASD 按画面方向解释：单键是上/下/左/右，同时按两键才是斜向。
## 等距投影下画面向量不能直接当成逻辑 X/Z，否则组合键反而会变成横/竖移动。
func _screen_input_to_logical_direction(input: Vector2) -> Vector3:
	if input.is_zero_approx():
		return Vector3.ZERO
	return Vector3(input.x + input.y, 0.0, input.y - input.x).normalized()


func get_logical_position() -> Vector3:
	return math_body.position if is_instance_valid(math_body) else Vector3.ZERO


func get_logical_anchor_position() -> Vector3:
	return get_logical_position() + Vector3.UP * anchor_height


func get_anchor_position() -> Vector2:
	return Projection25D.project(get_logical_anchor_position())


func _sync_projection() -> void:
	if not is_instance_valid(math_body):
		return
	global_position = Projection25D.project(math_body.position)
	z_index = Projection25D.depth_index(math_body.position) + 4


func _get_speed_scale(direction: Vector3) -> float:
	_tie_line = _get_tie_line()
	if _tie_line == null or not _tie_line.is_moving_away(get_logical_position(), direction):
		return 1.0
	return _tie_line.get_speed_multiplier()


func _get_tie_line_pull_velocity() -> Vector3:
	_tie_line = _get_tie_line()
	if _tie_line == null:
		return Vector3.ZERO
	var pull_velocity := _tie_line.get_pull_velocity(pull_back_stiffness)
	if pull_velocity.length() > max_pull_speed:
		pull_velocity = pull_velocity.normalized() * max_pull_speed
	return pull_velocity


func _get_tie_line() -> TieLine:
	if is_instance_valid(_tie_line):
		return _tie_line
	return get_tree().get_first_node_in_group(&"tie_line") as TieLine


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"interact"):
		return
	if _game_flow != null and not _game_flow.is_player_control_enabled():
		return
	if _current_interactable == null:
		return
	if _current_interactable.has_method(&"interact"):
		_current_interactable.interact(self)
		get_viewport().set_input_as_handled()


func _update_interaction_target() -> void:
	_current_interactable = null
	var nearest_distance := INF
	var player_ground := get_logical_position()
	for area in interaction_area.get_overlapping_areas():
		if not area.has_method(&"interact"):
			continue
		if area.has_method(&"can_interact") and not area.can_interact():
			continue
		var distance := global_position.distance_squared_to(area.global_position)
		if area.has_method(&"get_logical_position"):
			var target: Vector3 = area.get_logical_position()
			distance = Vector2(player_ground.x, player_ground.z).distance_squared_to(Vector2(target.x, target.z))
		if distance < nearest_distance:
			nearest_distance = distance
			_current_interactable = area

	var hint := get_tree().get_first_node_in_group(&"interaction_hint")
	if hint == null:
		return
	if _current_interactable == null:
		hint.hide_hint()
	else:
		hint.show_hint(_current_interactable.get_interaction_prompt())


func _play_idle_animation() -> void:
	animated_sprite.play(&"idle")


func _get_game_flow() -> GameFlow:
	if is_instance_valid(_game_flow):
		return _game_flow
	return get_tree().get_first_node_in_group(&"game_flow") as GameFlow
