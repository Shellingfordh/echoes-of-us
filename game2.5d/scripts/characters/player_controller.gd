class_name PlayerController
extends Node2D

## 可见角色仍是 2D，隐藏的 CharacterBody3D 在 X/Z 平面上负责真实移动与碰撞。

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
@export var crouch_detection_distance := 2.9
## 站上木椅后改用逻辑距离取目标，不再依赖 2D 区域重叠，
## 这样黄框（木椅目标区）挪到哪里，柜顶相框都够得到。
@export var mounted_reach_distance := 3.2
@export var ground_shadow_offset := Vector2(17.0, 8.0)

@onready var math_body: CharacterBody3D = $MathBody
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var push_pose: Sprite2D = get_node_or_null("PushPose") as Sprite2D
@onready var crouch_pose: Sprite2D = get_node_or_null("CrouchPose") as Sprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var ground_shadow: Polygon2D = get_node_or_null("GroundShadow") as Polygon2D

var _game_flow: GameFlow
var _current_interactable: Area2D
var _tie_line: TieLine
var _suspended := false
var _suspension_origin := Vector3.ZERO
var _swing_offset := 0.0
var _swing_velocity := 0.0
var _suspension_input_seen := false
var _mounted_stool: PushableStool
var _mount_return_position := Vector3.ZERO
var _crouching := false
var _crouch_target: Interactable
var _crouch_key_consumed := false
## 当前朝向：down / up / left / right。停下来时保留最后一次的朝向，
## 这样 idle 不会莫名转回正面。
var _facing := StringName("down")

var logical_position: Vector3:
	get:
		return get_logical_position()
	set(value):
		set_logical_position(value)


func _ready() -> void:
	add_to_group(&"player")
	_sync_projection()


func _physics_process(delta: float) -> void:
	_game_flow = _get_game_flow()
	if is_mounted_on_stool():
		_update_mounted_stool_position()
		_update_interaction_target()
		return
	if _crouching:
		math_body.velocity = Vector3.ZERO
		_show_crouch_pose()
		_update_interaction_target()
		return
	if _suspended:
		_update_suspension(delta)
		_update_interaction_target()
		return
	if _game_flow != null and not _game_flow.is_player_control_enabled():
		math_body.velocity = Vector3.ZERO
		_play_idle_animation()
		_update_interaction_target()
		return

	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if _crouch_key_consumed and input.y > 0.0:
		input.y = 0.0
	var direction := _screen_input_to_logical_direction(input)
	var input_velocity := direction * move_speed * _get_speed_scale(direction)
	var pull_velocity := _get_tie_line_pull_velocity()
	math_body.velocity = input_velocity + pull_velocity
	math_body.move_and_slide()
	var pushed_stool := _try_push_colliding_stool(direction)

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
		_update_facing(screen_direction)
		if pushed_stool:
			_show_push_pose(screen_direction)
		else:
			_play_directional(&"walk", screen_direction)

	_update_interaction_target()


func set_logical_position(value: Vector3) -> void:
	if is_mounted_on_stool():
		_mounted_stool.clear_mounted_player(self)
		_mounted_stool = null
	math_body.position = value
	_sync_projection()


func mount_stool(stool: PushableStool) -> bool:
	if stool == null or stool.is_player_mounted() or _suspended:
		return false
	_mount_return_position = get_logical_position()
	_mount_return_position.y = 0.0
	_mounted_stool = stool
	stool.set_mounted_player(self)
	math_body.velocity = Vector3.ZERO
	_update_mounted_stool_position()
	return true


func dismount_stool() -> void:
	if not is_mounted_on_stool():
		return
	var previous_stool := _mounted_stool
	_mounted_stool = null
	previous_stool.clear_mounted_player(self)
	math_body.position = _mount_return_position
	math_body.velocity = Vector3.ZERO
	_sync_projection()


func is_mounted_on_stool(stool: PushableStool = null) -> bool:
	if not is_instance_valid(_mounted_stool):
		_mounted_stool = null
		return false
	return stool == null or _mounted_stool == stool


func is_crouching() -> bool:
	return _crouching


func toggle_crouch() -> bool:
	if _crouching:
		stand_up()
		return true
	if is_mounted_on_stool() or _suspended:
		return false
	var target := _find_nearby_crouch_target()
	if target == null:
		return false
	_crouching = true
	_crouch_key_consumed = true
	_crouch_target = target
	math_body.velocity = Vector3.ZERO
	_show_crouch_pose()
	_update_interaction_target()
	# 床底故事只由床边按 S 进入蹲下时触发，不能站着按 Enter 越过条件。
	target.interact(self)
	return true


func stand_up() -> void:
	_crouching = false
	_crouch_key_consumed = true
	_crouch_target = null
	_play_idle_animation()
	_update_interaction_target()


func begin_suspension() -> void:
	_suspended = true
	_suspension_origin = get_logical_position()
	_suspension_origin.y = 0.0
	_swing_offset = 0.0
	_swing_velocity = 0.0
	_suspension_input_seen = false
	math_body.velocity = Vector3.ZERO
	_update_suspension_projection()


func end_suspension(landing_position: Vector3) -> void:
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
		ground_shadow.position = Projection25D.project(ground_position) - global_position + ground_shadow_offset


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
	if is_instance_valid(ground_shadow) and not _suspended:
		ground_shadow.position = ground_shadow_offset


func _update_mounted_stool_position() -> void:
	if not is_mounted_on_stool():
		return
	math_body.position = _mounted_stool.get_mount_position()
	math_body.velocity = Vector3.ZERO
	global_position = Projection25D.project(math_body.position)
	z_index = Projection25D.depth_index(math_body.position) + 6
	if is_instance_valid(ground_shadow):
		var ground_position := Vector3(math_body.position.x, 0.0, math_body.position.z)
		ground_shadow.position = Projection25D.project(ground_position) - global_position + ground_shadow_offset


func _try_push_colliding_stool(direction: Vector3) -> bool:
	if direction.is_zero_approx():
		return false
	for index in range(math_body.get_slide_collision_count()):
		var collision := math_body.get_slide_collision(index)
		var collider := collision.get_collider() as Node
		if collider == null:
			continue
		var stool := collider.get_parent() as PushableStool
		if stool != null and stool.try_push(direction):
			return true
	return false


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
	if event.is_action_released(&"crouch"):
		_crouch_key_consumed = false
		return
	if _game_flow != null and not _game_flow.is_player_control_enabled():
		return
	if event.is_action_pressed(&"crouch"):
		if toggle_crouch():
			get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed(&"interact"):
		return
	if _is_space_key(event) and is_mounted_on_stool():
		dismount_stool()
		get_viewport().set_input_as_handled()
		return
	if _current_interactable == null:
		return
	if _is_space_key(event) and _current_interactable is PushableStool:
		mount_stool(_current_interactable as PushableStool)
		get_viewport().set_input_as_handled()
		return
	if _current_interactable.has_method(&"interact"):
		_current_interactable.interact(self)
		get_viewport().set_input_as_handled()


func _update_interaction_target() -> void:
	_current_interactable = null
	var nearby_crouch_target := _find_nearby_crouch_target()
	var nearest_distance := INF
	var player_ground := get_logical_position()

	if is_mounted_on_stool():
		_current_interactable = _find_mounted_reach_target(player_ground)
		_update_interaction_hint(nearby_crouch_target)
		return

	for area in interaction_area.get_overlapping_areas():
		if not area.has_method(&"interact"):
			continue
		if is_mounted_on_stool() and area == _mounted_stool:
			continue
		var can_be_targeted: bool = area.has_method(&"can_interact") and bool(area.can_interact())
		if area.has_method(&"can_interact_for_player"):
			can_be_targeted = bool(area.can_interact_for_player(self))
		if area.has_method(&"can_be_player_target"):
			can_be_targeted = bool(area.can_be_player_target())
		if not can_be_targeted:
			continue
		var distance := global_position.distance_squared_to(area.global_position)
		if area.has_method(&"get_logical_position"):
			var target: Vector3 = area.get_logical_position()
			distance = Vector2(player_ground.x, player_ground.z).distance_squared_to(Vector2(target.x, target.z))
		if distance < nearest_distance:
			nearest_distance = distance
			_current_interactable = area

	_update_interaction_hint(nearby_crouch_target)


func _find_mounted_reach_target(player_ground: Vector3) -> Area2D:
	var nearest: Area2D
	var nearest_distance := mounted_reach_distance
	for node in get_tree().get_nodes_in_group(&"interactable"):
		var target := node as Interactable
		if target == null or target == _mounted_stool:
			continue
		if not target.can_interact_for_player(self):
			continue
		var target_position := target.get_logical_position()
		var distance := Vector2(player_ground.x, player_ground.z).distance_to(
			Vector2(target_position.x, target_position.z)
		)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest = target
	return nearest


func _update_interaction_hint(nearby_crouch_target: Interactable) -> void:
	var hint := get_tree().get_first_node_in_group(&"interaction_hint")
	if hint == null:
		return
	if is_mounted_on_stool():
		if _current_interactable == null:
			hint.show_hint("空格  从木椅下来")
		else:
			hint.show_hint("Enter  查看：%s；空格  从木椅下来" % _current_interactable.display_name)
		return
	if _crouching:
		hint.show_hint("S  起身")
		return
	if _current_interactable == null:
		if nearby_crouch_target != null:
			hint.show_hint("S  蹲下查看床底")
		else:
			hint.hide_hint()
	else:
		hint.show_hint(_current_interactable.get_interaction_prompt())


func _is_space_key(event: InputEvent) -> bool:
	var key_event := event as InputEventKey
	return key_event != null and (
		key_event.physical_keycode == KEY_SPACE or key_event.keycode == KEY_SPACE
	)


func _find_nearby_crouch_target() -> Interactable:
	var nearest: Interactable
	var nearest_distance := INF
	var player_ground := get_logical_position()
	for node in get_tree().get_nodes_in_group(&"crouch_interactable"):
		var target := node as Interactable
		if target == null or not target.can_interact():
			continue
		var target_position := target.get_logical_position()
		var distance := Vector2(player_ground.x, player_ground.z).distance_to(
			Vector2(target_position.x, target_position.z)
		)
		if distance <= crouch_detection_distance and distance < nearest_distance:
			nearest = target
			nearest_distance = distance
	return nearest


## 剧情把控制权收走时用：立刻停下并切回站立姿势。
## _physics_process 被关掉后不会再自动播 idle，所以必须由外部显式调用一次，
## 否则角色会僵在被夺走控制权那一帧的 walk 动画上。
func stop_and_idle() -> void:
	if is_instance_valid(math_body):
		math_body.velocity = Vector3.ZERO
	_play_idle_animation()


func _play_idle_animation() -> void:
	_play_directional(&"idle", Vector2.ZERO)


## 屏幕上看到的方向决定用哪一组贴图：横向位移压过纵向就走左右，否则走上下。
## 判据用投影后的屏幕向量而不是逻辑 XZ，因为等距投影把两条轴各转了 45°，
## 玩家眼里的"往右走"对应的是逻辑 x 增、z 减，直接读逻辑轴会选错朝向。
func _update_facing(screen_direction: Vector2) -> void:
	if screen_direction.is_zero_approx():
		return
	if absf(screen_direction.x) >= absf(screen_direction.y):
		_facing = &"right" if screen_direction.x > 0.0 else &"left"
	else:
		_facing = &"down" if screen_direction.y > 0.0 else &"up"


## 有四向贴图就用四向，没有就退回原来的 idle / walk 加 flip_h。
## 第一章的小精灵只有两个动画，这个回退让它完全按老样子跑。
func _play_directional(base: StringName, screen_direction: Vector2) -> void:
	if not is_instance_valid(animated_sprite):
		return
	_show_normal_pose()
	var frames := animated_sprite.sprite_frames
	var directional := StringName("%s_%s" % [base, _facing])
	if frames != null and frames.has_animation(directional):
		animated_sprite.flip_h = false
		animated_sprite.play(directional)
		return
	if not screen_direction.is_zero_approx() and not is_zero_approx(screen_direction.x):
		animated_sprite.flip_h = screen_direction.x < 0.0
	animated_sprite.play(base)


func _show_normal_pose() -> void:
	animated_sprite.show()
	if is_instance_valid(push_pose):
		push_pose.hide()
	if is_instance_valid(crouch_pose):
		crouch_pose.hide()


func _show_push_pose(screen_direction: Vector2) -> void:
	if not is_instance_valid(push_pose):
		_play_directional(&"walk", screen_direction)
		return
	animated_sprite.hide()
	if is_instance_valid(crouch_pose):
		crouch_pose.hide()
	push_pose.show()
	var face_left := screen_direction.x < 0.0 if not is_zero_approx(screen_direction.x) else _facing == &"left"
	push_pose.flip_h = face_left
	push_pose.position.x = -15.0 if face_left else 15.0


func _show_crouch_pose() -> void:
	if not is_instance_valid(crouch_pose):
		_play_idle_animation()
		return
	animated_sprite.hide()
	if is_instance_valid(push_pose):
		push_pose.hide()
	crouch_pose.show()


func _get_game_flow() -> GameFlow:
	if is_instance_valid(_game_flow):
		return _game_flow
	return get_tree().get_first_node_in_group(&"game_flow") as GameFlow
