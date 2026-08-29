class_name TieLine
extends Line2D

signal state_changed(previous_state: State, current_state: State)

enum State { HIDDEN, NORMAL, TENSION, PULL_BACK }

## 阈值现在是逻辑房间里的“米”，不再是屏幕像素。
@export var reveal_distance := 6.0
@export var tension_distance := 9.0
@export var max_distance := 12.0
@export var visual_width := 3.0
@export var glow_width_scale := 4.2
@export var fiber_width := 1.15
@export_range(2.0, 12.0, 0.5) var yarn_twists := 7.0
@export var extend_multiplier := 2.5
@export var normal_color := Color(0.35, 0.95, 0.75, 0.55)
@export var tension_color := Color(0.98, 0.83, 0.45, 0.85)
@export var pull_back_color := Color(0.95, 0.35, 0.42, 0.95)
@export var source_path: NodePath
@export var target_path: NodePath
@export_range(0.0, 1.0, 0.01) var distance_weight := 0.64
@export_range(0.0, 1.0, 0.01) var exit_progress_weight := 0.20
@export_range(0.8, 1.0, 0.005) var critical_tension := 0.985
@export_range(0.9, 1.0, 0.005) var critical_distance_ratio := 0.985
@export_range(0.0, 0.5, 0.01) var minimum_away_speed_multiplier := 0.12

var current_state := State.HIDDEN
var tension := 0.0
var distance := 0.0
var extended := false
var enabled := false
var _pullback_active := false
var emotional_pressure := 0.0
var intention_conflict := 0.0
var exit_progress := 0.0
var _force_critical := false
## 线已经显形、但剧情还不允许它把玩家拽回去时锁住回拉。
## 只屏蔽物理回拉，不影响张力读数与视觉，玩家仍然看得见线正在绷紧。
var _pullback_locked := false
var pullback_start_position := Vector3.ZERO

var _source: Node2D
var _target: Node2D
var _glow_line: Line2D
var _fiber_light: Line2D
var _fiber_shadow: Line2D


func _ready() -> void:
	add_to_group(&"tie_line")
	_source = get_node_or_null(source_path) as Node2D
	_target = get_node_or_null(target_path) as Node2D
	top_level = true
	_setup_yarn_layers()
	_clear_visual()


func bind(source: Node2D, target: Node2D) -> void:
	_source = source
	_target = target


func _process(_delta: float) -> void:
	if not is_instance_valid(_source) or not is_instance_valid(_target):
		points = PackedVector2Array()
		return

	distance = Projection25D.ground_distance(get_source_logical_anchor(), get_target_logical_anchor())
	var distance_ratio := clampf(distance / get_effective_max_distance(), 0.0, 1.0)
	tension = clampf(
		distance_ratio * distance_weight
		+ exit_progress * exit_progress_weight
		+ intention_conflict
		+ emotional_pressure,
		0.0,
		1.0
	)
	if _force_critical or distance >= get_critical_distance() or tension >= critical_tension:
		_pullback_active = true
	elif _pullback_active and distance <= _get_pullback_release_distance() + 0.02 and tension < critical_tension:
		_pullback_active = false
	if _pullback_locked:
		_pullback_active = false
	_set_state(_resolve_state())
	_update_visual()


func get_source_anchor() -> Vector2:
	return _screen_anchor_of(_source)


func get_target_anchor() -> Vector2:
	return _screen_anchor_of(_target)


func get_source_logical_anchor() -> Vector3:
	return _logical_anchor_of(_source)


func get_target_logical_anchor() -> Vector3:
	return _logical_anchor_of(_target)


func _screen_anchor_of(node: Node2D) -> Vector2:
	if not is_instance_valid(node):
		return Vector2.ZERO
	if node.has_method(&"get_anchor_position"):
		return node.get_anchor_position()
	return node.global_position


func _logical_anchor_of(node: Node2D) -> Vector3:
	if not is_instance_valid(node):
		return Vector3.ZERO
	if node.has_method(&"get_logical_anchor_position"):
		return node.get_logical_anchor_position()
	if node.has_method(&"get_logical_position"):
		return node.get_logical_position()
	return Vector3.ZERO


func get_effective_max_distance() -> float:
	return maxf(max_distance * (extend_multiplier if extended else 1.0), 0.01)


func get_critical_distance() -> float:
	return get_effective_max_distance() * critical_distance_ratio


func set_extended(value: bool) -> void:
	extended = value


func set_enabled(value: bool) -> void:
	enabled = value
	if not value:
		_pullback_active = false


func set_context(next_emotional_pressure: float, next_intention_conflict: float, next_exit_progress: float) -> void:
	emotional_pressure = clampf(next_emotional_pressure, 0.0, 1.0)
	intention_conflict = clampf(next_intention_conflict, 0.0, 1.0)
	exit_progress = clampf(next_exit_progress, 0.0, 1.0)


func clear_context() -> void:
	set_context(0.0, 0.0, 0.0)


func set_pullback_locked(value: bool) -> void:
	_pullback_locked = value
	if value:
		_pullback_active = false


func is_pullback_locked() -> bool:
	return _pullback_locked


func set_force_critical(value: bool) -> void:
	_force_critical = value
	if value:
		_pullback_active = true


func get_speed_multiplier() -> float:
	if current_state == State.HIDDEN:
		return 1.0
	if current_state == State.PULL_BACK:
		return 0.0
	var span := get_effective_max_distance() - reveal_distance
	if span <= 0.0:
		return 1.0
	var distance_ratio := clampf((distance - reveal_distance) / span, 0.0, 1.0)
	var ratio := maxf(distance_ratio, tension)
	return maxf(minimum_away_speed_multiplier, 1.0 - ratio * ratio)


func is_moving_away(from_position: Vector3, direction: Vector3) -> bool:
	if direction.is_zero_approx() or not is_instance_valid(_target):
		return false
	var to_anchor := get_target_logical_anchor() - from_position
	to_anchor.y = 0.0
	return direction.dot(to_anchor) < 0.0


func get_logical_correction() -> Vector3:
	if _pullback_locked or not enabled or not is_instance_valid(_source) or not is_instance_valid(_target):
		return Vector3.ZERO
	var target := get_target_logical_anchor()
	var source := get_source_logical_anchor()
	target.y = 0.0
	source.y = 0.0
	var offset := source - target
	if _force_critical or offset.length() >= get_critical_distance() or tension >= critical_tension:
		_pullback_active = true
	elif _pullback_active and offset.length() <= _get_pullback_release_distance() + 0.02 and tension < critical_tension:
		_pullback_active = false
	if not _pullback_active:
		return Vector3.ZERO
	return target + offset.normalized() * _get_pullback_release_distance() - source


## 返回地面平面上的拉回速度。Player 必须把它交给 move_and_slide()，
## 不能直接修改 position，否则会绕过家具的 StaticBody3D 碰撞。
func get_pull_velocity(stiffness: float) -> Vector3:
	var correction := get_logical_correction()
	if correction.is_zero_approx():
		return Vector3.ZERO
	return correction * maxf(stiffness, 0.0)


func _resolve_state() -> State:
	if not enabled or distance < reveal_distance:
		return State.HIDDEN
	if _pullback_active:
		return State.PULL_BACK
	if distance >= tension_distance:
		return State.TENSION
	return State.NORMAL


func _get_pullback_release_distance() -> float:
	return clampf(tension_distance, 0.01, get_effective_max_distance())


func _set_state(next_state: State) -> void:
	if next_state == current_state:
		return
	var previous_state := current_state
	if next_state == State.PULL_BACK:
		# 只记录触发瞬间玩家的真实位置；绝不把玩家传送到预设拉回点。
		pullback_start_position = get_source_logical_anchor()
		pullback_start_position.y = 0.0
	current_state = next_state
	state_changed.emit(previous_state, current_state)


func _update_visual() -> void:
	if current_state == State.HIDDEN:
		_clear_visual()
		return

	var start := get_source_anchor()
	var finish := get_target_anchor()
	var midpoint := (start + finish) * 0.5
	var slack := lerpf(78.0, 6.0, tension)
	var control := midpoint + Vector2(0.0, slack)
	var curve := PackedVector2Array()
	for index in range(33):
		var t := float(index) / 32.0
		curve.append((1.0 - t) * (1.0 - t) * start + 2.0 * (1.0 - t) * t * control + t * t * finish)
	points = curve

	var yarn_color := normal_color
	var width_scale := 1.0
	match current_state:
		State.PULL_BACK:
			yarn_color = pull_back_color
			width_scale = 1.6
		State.TENSION:
			yarn_color = tension_color
			width_scale = 1.25

	default_color = yarn_color
	width = visual_width * width_scale
	_update_yarn_layers(curve, yarn_color, width_scale)


func _setup_yarn_layers() -> void:
	joint_mode = Line2D.LINE_JOINT_ROUND
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND
	antialiased = true

	_glow_line = _make_line(-2)
	var glow_material := CanvasItemMaterial.new()
	glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow_line.material = glow_material

	_fiber_shadow = _make_line(1)
	_fiber_light = _make_line(2)
	var fiber_material := CanvasItemMaterial.new()
	fiber_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_fiber_light.material = fiber_material


func _make_line(relative_z: int) -> Line2D:
	var line := Line2D.new()
	line.z_index = relative_z
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.antialiased = true
	add_child(line)
	return line


func _update_yarn_layers(curve: PackedVector2Array, yarn_color: Color, width_scale: float) -> void:
	_glow_line.points = curve
	_glow_line.width = visual_width * width_scale * glow_width_scale
	_glow_line.default_color = Color(yarn_color.r, yarn_color.g, yarn_color.b, 0.16 + tension * 0.12)

	var light_points := PackedVector2Array()
	var shadow_points := PackedVector2Array()
	for index in range(curve.size()):
		var previous := curve[maxi(index - 1, 0)]
		var following := curve[mini(index + 1, curve.size() - 1)]
		var tangent := (following - previous).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		var t := float(index) / float(curve.size() - 1)
		var braid := sin(t * TAU * yarn_twists) * visual_width * width_scale * 0.28
		light_points.append(curve[index] + normal * braid)
		shadow_points.append(curve[index] - normal * braid)

	_fiber_light.points = light_points
	_fiber_light.width = fiber_width * width_scale
	_fiber_light.default_color = Color(
		minf(yarn_color.r + 0.28, 1.0),
		minf(yarn_color.g + 0.28, 1.0),
		minf(yarn_color.b + 0.28, 1.0),
		0.72
	)
	_fiber_shadow.points = shadow_points
	_fiber_shadow.width = fiber_width * width_scale * 0.85
	_fiber_shadow.default_color = Color(
		yarn_color.r * 0.42,
		yarn_color.g * 0.42,
		yarn_color.b * 0.42,
		0.58
	)


func _clear_visual() -> void:
	points = PackedVector2Array()
	if is_instance_valid(_glow_line):
		_glow_line.points = PackedVector2Array()
	if is_instance_valid(_fiber_light):
		_fiber_light.points = PackedVector2Array()
	if is_instance_valid(_fiber_shadow):
		_fiber_shadow.points = PackedVector2Array()


func get_state_name() -> String:
	return State.keys()[current_state]
