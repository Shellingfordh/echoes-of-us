class_name PlayerController
extends Node2D

## 可见角色仍是 2D，隐藏的 CharacterBody3D 在 X/Z 平面上负责真实移动与碰撞。

signal empty_interact_pressed

@export var move_speed := 3.8
@export var movement_min := Vector2(1.0, 1.0)
@export var movement_max := Vector2(17.0, 11.0)
@export var anchor_height := 1.05
@export var pull_back_stiffness := 6.0
@export var max_pull_speed := 5.5
@export var suspension_height := 1.35
@export var swing_acceleration := 4.8
@export var swing_damping := 3.2
@export var swing_max_offset := 1.25
@export var resistance_lean_pixels := 10.0
@export var resistance_lean_degrees := 6.5
@export var resistance_response_speed := 8.0

@onready var math_body: CharacterBody3D = $MathBody
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var ground_shadow: Polygon2D = $GroundShadow

var _game_flow: GameFlow
var _current_interactable: Area2D
var _current_hint_only_interactable: Area2D
var _tie_line: TieLine
var _suspended := false
var _suspension_origin := Vector3.ZERO
var _swing_offset := 0.0
var _swing_velocity := 0.0
var _suspension_input_seen := false
var _context_action_prompt := ""
var _sprite_rest_position := Vector2.ZERO
var _sprite_rest_rotation := 0.0
var _shadow_rest_scale := Vector2.ONE
var _resistance_visual_strength := 0.0
var _resistance_screen_direction := Vector2.RIGHT

var logical_position: Vector3:
	get:
		return get_logical_position()
	set(value):
		set_logical_position(value)


func _ready() -> void:
	add_to_group(&"player")
	_sprite_rest_position = animated_sprite.position
	_sprite_rest_rotation = animated_sprite.rotation
	_shadow_rest_scale = ground_shadow.scale
	_sync_projection()


func _physics_process(delta: float) -> void:
	_game_flow = _get_game_flow()
	if _suspended:
		_update_resistance_feedback(0.0, Vector2.ZERO, delta)
		_update_suspension(delta)
		_update_interaction_target()
		return
	if _game_flow != null and not _game_flow.is_player_control_enabled():
		math_body.velocity = Vector3.ZERO
		_update_resistance_feedback(0.0, Vector2.ZERO, delta)
		_play_idle_animation()
		_update_interaction_target()
		return

	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var direction := _screen_input_to_logical_direction(input)
	var input_velocity := direction * move_speed * _get_speed_scale(direction)
	var pull_velocity := _get_tie_line_pull_velocity()
	_update_resistance_from_motion(direction, pull_velocity, delta)
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
	math_body.position = value
	_sync_projection()


func begin_suspension() -> void:
	_reset_resistance_feedback()
	_suspended = true
	_suspension_origin = get_logical_position()
	_suspension_origin.y = 0.0
	_swing_offset = 0.0
	_swing_velocity = 0.0
	_suspension_input_seen = false
	math_body.velocity = Vector3.ZERO
	_update_suspension_projection()


func end_suspension(landing_position: Vector3) -> void:
	_reset_resistance_feedback()
	_suspended = false
	_swing_velocity = 0.0
	_swing_offset = 0.0
	math_body.position = Vector3(landing_position.x, 0.0, landing_position.z)
	math_body.velocity = Vector3.ZERO
	_sync_projection()


func is_suspended() -> bool:
	return _suspended


func has_suspension_input() -> bool:
	return _suspension_input_seen


func debug_mark_suspension_input() -> void:
	_suspension_input_seen = true


func _update_suspension(delta: float) -> void:
	var horizontal_input := Input.get_axis(&"move_left", &"move_right")
	if not is_zero_approx(horizontal_input):
		_suspension_input_seen = true
	_swing_velocity += horizontal_input * swing_acceleration * delta
	_swing_velocity = move_toward(_swing_velocity, 0.0, swing_damping * delta)
	_swing_offset = clampf(
		_swing_offset + _swing_velocity * delta,
		-swing_max_offset,
		swing_max_offset
	)
	if absf(_swing_offset) >= swing_max_offset - 0.001:
		_swing_velocity *= -0.28
	_update_suspension_projection()


func _update_suspension_projection() -> void:
	# 逻辑 X/Z 同时反向变化，在等距投影中形成画面水平方向的有限摆动。
	var screen_horizontal_axis := Vector3(1.0, 0.0, -1.0).normalized()
	var logical := _suspension_origin + screen_horizontal_axis * _swing_offset
	logical.y = suspension_height + absf(_swing_offset) * 0.17
	math_body.position = logical
	_sync_projection()
	if is_instance_valid(ground_shadow):
		var ground_position := Vector3(logical.x, 0.0, logical.z)
		ground_shadow.position = Projection25D.project(ground_position) - global_position


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


func get_resistance_visual_strength() -> float:
	return _resistance_visual_strength


func _sync_projection() -> void:
	if not is_instance_valid(math_body):
		return
	global_position = Projection25D.project(math_body.position)
	z_index = Projection25D.depth_index(math_body.position) + 4
	if is_instance_valid(ground_shadow) and not _suspended:
		ground_shadow.position = Vector2.ZERO


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


func _update_resistance_from_motion(direction: Vector3, pull_velocity: Vector3, delta: float) -> void:
	var target_strength := 0.0
	var screen_direction := _resistance_screen_direction
	var moving_away := (
		_tie_line != null
		and not direction.is_zero_approx()
		and _tie_line.is_moving_away(get_logical_position(), direction)
	)
	if moving_away:
		screen_direction = Projection25D.project_direction(direction).normalized()
		target_strength = smoothstep(0.58, 1.0, _tie_line.tension)
	if not pull_velocity.is_zero_approx():
		screen_direction = -Projection25D.project_direction(pull_velocity.normalized()).normalized()
		target_strength = maxf(target_strength, 1.0)
	_update_resistance_feedback(target_strength, screen_direction, delta)


func _update_resistance_feedback(target_strength: float, screen_direction: Vector2, delta: float) -> void:
	if not screen_direction.is_zero_approx():
		_resistance_screen_direction = screen_direction.normalized()
	_resistance_visual_strength = move_toward(
		_resistance_visual_strength,
		clampf(target_strength, 0.0, 1.0),
		resistance_response_speed * delta
	)
	var horizontal_sign := signf(_resistance_screen_direction.x)
	if is_zero_approx(horizontal_sign):
		horizontal_sign = 1.0
	var tremor := sin(float(Time.get_ticks_msec()) * 0.055) * 1.15 * pow(_resistance_visual_strength, 2.0)
	animated_sprite.position = (
		_sprite_rest_position
		+ _resistance_screen_direction * resistance_lean_pixels * _resistance_visual_strength
		+ Vector2(0.0, tremor)
	)
	animated_sprite.rotation = (
		_sprite_rest_rotation
		+ deg_to_rad(resistance_lean_degrees) * horizontal_sign * _resistance_visual_strength
	)
	ground_shadow.scale = _shadow_rest_scale * Vector2(
		1.0 + 0.24 * _resistance_visual_strength,
		1.0 - 0.12 * _resistance_visual_strength
	)


func _reset_resistance_feedback() -> void:
	_resistance_visual_strength = 0.0
	animated_sprite.position = _sprite_rest_position
	animated_sprite.rotation = _sprite_rest_rotation
	ground_shadow.scale = _shadow_rest_scale


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
		if _current_hint_only_interactable == null:
			empty_interact_pressed.emit()
		get_viewport().set_input_as_handled()
		return
	if _current_interactable.has_method(&"interact"):
		_current_interactable.interact(self)
		get_viewport().set_input_as_handled()


func _update_interaction_target() -> void:
	_current_interactable = null
	_current_hint_only_interactable = null
	var nearest_interaction_distance := INF
	var nearest_hint_distance := INF
	var player_ground := get_logical_position()
	for area in interaction_area.get_overlapping_areas():
		if not area.has_method(&"interact"):
			continue
		var distance := global_position.distance_squared_to(area.global_position)
		if area.has_method(&"get_logical_position"):
			var target: Vector3 = area.get_logical_position()
			distance = Vector2(player_ground.x, player_ground.z).distance_squared_to(Vector2(target.x, target.z))
		var is_actionable: bool = not area.has_method(&"can_interact") or area.can_interact()
		if is_actionable and distance < nearest_interaction_distance:
			nearest_interaction_distance = distance
			_current_interactable = area
		elif (
			area.has_method(&"can_show_disabled_hint")
			and area.can_show_disabled_hint()
			and distance < nearest_hint_distance
		):
			nearest_hint_distance = distance
			_current_hint_only_interactable = area

	# 同一范围里若玩家明显更靠近“暂时够不到”的物件，先解释障碍；
	# 走向解决它的可交互物件后，再切换为动作提示。
	if (
		_current_hint_only_interactable != null
		and nearest_hint_distance < nearest_interaction_distance
	):
		_current_interactable = null
	else:
		_current_hint_only_interactable = null

	var hint := get_tree().get_first_node_in_group(&"interaction_hint")
	if hint == null:
		return
	if _current_interactable != null:
		hint.show_hint(_current_interactable.get_interaction_prompt())
	elif not _context_action_prompt.is_empty():
		hint.show_hint(_context_action_prompt)
	elif _current_hint_only_interactable != null:
		hint.show_hint(_current_hint_only_interactable.get_disabled_interaction_prompt())
	else:
		hint.hide_hint()


func set_context_action_prompt(prompt: String) -> void:
	_context_action_prompt = prompt


func clear_context_action_prompt() -> void:
	_context_action_prompt = ""


func _play_idle_animation() -> void:
	animated_sprite.play(&"idle")


func _get_game_flow() -> GameFlow:
	if is_instance_valid(_game_flow):
		return _game_flow
	return get_tree().get_first_node_in_group(&"game_flow") as GameFlow
