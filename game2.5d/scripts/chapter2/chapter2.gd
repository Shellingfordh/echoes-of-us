extends Node2D

## 第二章大型 2.5D Blockout。
## 三个 Block 共用同一场景；A/B/C 各约 2560px，1280px 视口每次只看见不到半个 Block。

enum PitState { APPROACH, FALLING, FALLEN, RECOVERING, CLEARED }

const BASE := Vector3(2.0, 0.0, 12.0)
const ALONG := Vector3(0.5, 0.0, -0.5)
const ACROSS := Vector3(0.5, 0.0, 0.5)
const MAP_END_U := 120.0
const PIT_START_U := 58.0
const PIT_END_U := 66.0
const PIT_DEPTH := -5.5

@onready var generated_map: Node2D = $World/GeneratedMap
@onready var spatial_physics: Node3D = $World/SpatialPhysics
@onready var player: PlayerController = $Characters/YoungMother
@onready var child: Chapter2Child = $Characters/Child
@onready var tie_line: TieLine = $TieLine
@onready var camera_rig: CameraRig = $CameraRig
@onready var game_flow: GameFlow = $GameFlow
@onready var objective_label: Label = $UI/ObjectiveLabel
@onready var hint_label: Label = $UI/HintLabel
@onready var transition_overlay: ColorRect = $UI/TransitionOverlay

var _child_u := 4.0
var _pit_state := PitState.APPROACH
var _gate_open := false
var _gate_body: StaticBody3D
var _gate_visual: Node2D
var _plank_intact: Node2D
var _plank_broken: Node2D
var _last_objective := ""


func _ready() -> void:
	_build_visual_map()
	_build_hidden_physics()

	player.set_logical_position(_logical(2.0, 0.0))
	child.set_logical_position(_logical(_child_u, 0.0))
	child.set_moving(false)

	tie_line.bind(player, child)
	tie_line.set_enabled(true)
	tie_line.set_context(0.08, 0.0, 0.0)

	camera_rig.snap_to(player)
	camera_rig.follow(player, Vector2.ONE, true)
	_set_objective("沿着老街向右走。小余念已经跑到自行车旁边。")
	hint_label.text = "WASD / 方向键移动    Enter / 空格互动    本场景可直接 F6 运行"
	_intro_fade()


func _process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(child):
		return
	var mother_u := _progress_of(player.get_logical_position())

	if game_flow.current_mode == GameFlow.Mode.EXPLORE:
		_update_child(delta, mother_u)
		_update_exploration_objective(mother_u)

	if _pit_state == PitState.FALLEN and mother_u >= 53.0:
		hint_label.text = "Enter / 空格：让小余念沿牵挂线返回（Blockout 使用黑屏衔接）"


func _unhandled_input(event: InputEvent) -> void:
	if _pit_state != PitState.FALLEN:
		return
	if not event.is_action_pressed(&"interact"):
		return
	if _progress_of(player.get_logical_position()) < 53.0:
		return
	get_viewport().set_input_as_handled()
	_recover_from_pit()


func _update_child(delta: float, mother_u: float) -> void:
	if _pit_state == PitState.FALLING or _pit_state == PitState.FALLEN or _pit_state == PitState.RECOVERING:
		child.set_moving(false)
		return

	var target_u := clampf(mother_u + 4.0, 4.0, 116.0)
	if not _gate_open:
		target_u = minf(target_u, 45.0)
	if _pit_state == PitState.APPROACH:
		target_u = minf(target_u, 59.5)

	var previous_u := _child_u
	_child_u = move_toward(_child_u, target_u, 2.15 * delta)
	var moving := absf(_child_u - previous_u) > 0.0001
	child.set_moving(moving)
	child.face_screen_direction(_child_u - previous_u)
	child.set_logical_position(_logical(_child_u, _child_route_v(_child_u)))

	if not _gate_open and _child_u >= 44.7 and mother_u >= 39.0:
		_open_gate()

	if _pit_state == PitState.APPROACH and _child_u >= 59.25 and mother_u >= 51.5:
		_start_pit_fall()


func _update_exploration_objective(mother_u: float) -> void:
	if _pit_state == PitState.FALLEN:
		_set_objective("小余念掉进了施工坑。靠近坑边，确认牵挂线仍在支撑她。")
		return
	if mother_u < 9.0:
		_set_objective("Block A｜从自行车旁出发，跟上往前跑的小余念。")
	elif mother_u < 31.0:
		_set_objective("Block A｜绕过大水坑；靠近孩子时，牵挂线会重新松下来。")
	elif mother_u < 49.0:
		_set_objective("Block B｜孩子从低矮缺口过去，正在替母亲打开大门。")
	elif mother_u < 57.0:
		_set_objective("Block B｜进入施工段。前方临时木板是唯一通路。")
	elif _pit_state == PitState.CLEARED and mother_u < 82.0:
		_set_objective("Block B → C｜穿过狭窄巷道，走向学校街角。")
	elif mother_u < 108.0:
		_set_objective("Block C｜寻找街角的路灯，让母亲停下来成为支点。")
	else:
		_set_objective("Block C｜学校就在前面。母亲停下，孩子继续向右走。")


func _open_gate() -> void:
	_gate_open = true
	if is_instance_valid(_gate_body):
		_gate_body.queue_free()
	if is_instance_valid(_gate_visual):
		var tween := create_tween().set_parallel()
		tween.tween_property(_gate_visual, "modulate:a", 0.0, 0.35)
		tween.tween_property(_gate_visual, "position:y", -58.0, 0.35)
	_set_objective("Block B｜小余念踩下了另一侧踏板，大门已经打开。")


func _start_pit_fall() -> void:
	if _pit_state != PitState.APPROACH:
		return
	_pit_state = PitState.FALLING
	game_flow.set_mode(GameFlow.Mode.CUTSCENE)
	if is_instance_valid(_plank_intact):
		_plank_intact.visible = false
	if is_instance_valid(_plank_broken):
		_plank_broken.visible = true
	child.set_moving(false)
	tie_line.set_context(0.86, 0.08, 0.0)
	camera_rig.follow(child, Vector2(1.02, 1.02), true)
	_set_objective("木板断裂——牵挂线第一次承担孩子的重量。")

	var start := child.get_logical_position()
	var finish := _logical(62.0, 0.0, PIT_DEPTH)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_method(
		func(weight: float) -> void:
			child.set_logical_position(start.lerp(finish, weight)),
		0.0,
		1.0,
		0.9
	)
	await tween.finished
	_child_u = 62.0
	_pit_state = PitState.FALLEN
	game_flow.set_mode(GameFlow.Mode.CHALLENGE)
	_set_objective("小余念悬在坑底。母亲提供支撑，返回要由孩子自己完成。")


func _recover_from_pit() -> void:
	if _pit_state != PitState.FALLEN:
		return
	_pit_state = PitState.RECOVERING
	game_flow.set_mode(GameFlow.Mode.CUTSCENE)
	hint_label.text = ""
	transition_overlay.visible = true
	transition_overlay.modulate.a = 0.0
	var fade_out := create_tween()
	fade_out.tween_property(transition_overlay, "modulate:a", 1.0, 0.32)
	await fade_out.finished

	player.set_logical_position(_logical(68.0, 0.0))
	_child_u = 71.0
	child.set_logical_position(_logical(_child_u, 0.0))
	tie_line.clear_context()
	_pit_state = PitState.CLEARED
	camera_rig.snap_to(player)
	camera_rig.follow(player, Vector2.ONE, true)

	var fade_in := create_tween()
	fade_in.tween_property(transition_overlay, "modulate:a", 0.0, 0.32)
	await fade_in.finished
	transition_overlay.visible = false
	game_flow.set_mode(GameFlow.Mode.EXPLORE)
	hint_label.text = "WASD / 方向键移动"
	_set_objective("Block B → C｜两个人回到安全处。穿过前方狭窄巷道。")


func _intro_fade() -> void:
	game_flow.set_mode(GameFlow.Mode.CUTSCENE)
	transition_overlay.visible = true
	transition_overlay.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(0.25)
	tween.tween_property(transition_overlay, "modulate:a", 0.0, 0.65)
	await tween.finished
	transition_overlay.visible = false
	game_flow.set_mode(GameFlow.Mode.EXPLORE)


func _child_route_v(u: float) -> float:
	# 大水坑覆盖街道中央，小余念沿靠上的边缘自主绕行。
	if u >= 12.0 and u <= 30.0:
		var weight := sin((u - 12.0) / 18.0 * PI)
		return -4.0 * weight
	if u >= 70.0 and u <= 80.0:
		return 0.0
	return 0.0


func _set_objective(text: String) -> void:
	if text == _last_objective:
		return
	_last_objective = text
	objective_label.text = text


func _logical(u: float, v: float, height: float = 0.0) -> Vector3:
	var result := BASE + ALONG * u + ACROSS * v
	result.y = height
	return result


func _screen(u: float, v: float, height: float = 0.0) -> Vector2:
	return Projection25D.project(_logical(u, v, height))


func _progress_of(position: Vector3) -> float:
	var ground_delta := position - BASE
	ground_delta.y = 0.0
	return ground_delta.dot(ALONG) / ALONG.length_squared()


func _build_visual_map() -> void:
	_add_void()
	_add_floor_block("BlockA", 0.0, 40.0, 5.5, Color(0.48, 0.34, 0.20, 1.0))
	_add_floor_block("BlockB_PrePit", 40.0, PIT_START_U, 5.0, Color(0.45, 0.32, 0.19, 1.0))
	_add_pit_visual()
	_add_floor_block("BlockB_PostPit", PIT_END_U, 70.0, 4.5, Color(0.44, 0.31, 0.18, 1.0))
	_add_floor_block("NarrowConnector", 70.0, 80.0, 2.2, Color(0.39, 0.28, 0.18, 1.0))
	_add_floor_block("BlockC", 80.0, MAP_END_U, 5.5, Color(0.50, 0.37, 0.22, 1.0))

	_add_block_label("BLOCK A · 自行车 / 水坑", 18.0, -7.2)
	_add_block_label("BLOCK B · 窄缝 / 施工坑", 52.0, -6.8)
	_add_block_label("BLOCK C · 路灯 / 学校", 98.0, -7.2)

	_add_bicycle(4.0, 0.8)
	_add_large_puddle()
	_add_gate_visual()
	_add_pressure_plate(46.0, -2.3)
	_add_plank_visual()
	_add_lamppost(91.0, -1.4)
	_add_school_gate(113.0, 0.0)
	_add_direction_markers()


func _add_void() -> void:
	var warm_void := Polygon2D.new()
	warm_void.name = "WarmVoid"
	warm_void.z_index = -5000
	warm_void.color = Color(0.045, 0.032, 0.025, 1.0)
	warm_void.polygon = PackedVector2Array([
		Vector2(-1200, -900),
		Vector2(9400, -900),
		Vector2(9400, 1900),
		Vector2(-1200, 1900)
	])
	generated_map.add_child(warm_void)


func _add_floor_block(node_name: String, u0: float, u1: float, half_width: float, color: Color) -> void:
	var floor := Polygon2D.new()
	floor.name = node_name
	floor.z_index = -4000
	floor.color = color
	floor.polygon = PackedVector2Array([
		_screen(u0, -half_width), _screen(u1, -half_width),
		_screen(u1, half_width), _screen(u0, half_width)
	])
	generated_map.add_child(floor)

	for v in [-half_width, half_width]:
		var edge := Line2D.new()
		edge.z_index = -2100 if v < 0.0 else 1200
		edge.width = 18.0
		edge.default_color = Color(0.22, 0.16, 0.12, 1.0)
		edge.points = PackedVector2Array([_screen(u0, v), _screen(u1, v)])
		generated_map.add_child(edge)


func _add_pit_visual() -> void:
	var top_back_left := _screen(PIT_START_U, -5.0)
	var top_back_right := _screen(PIT_END_U, -5.0)
	var top_front_right := _screen(PIT_END_U, 5.0)
	var top_front_left := _screen(PIT_START_U, 5.0)
	var bottom_back_left := _screen(PIT_START_U, -5.0, PIT_DEPTH)
	var bottom_back_right := _screen(PIT_END_U, -5.0, PIT_DEPTH)
	var bottom_front_right := _screen(PIT_END_U, 5.0, PIT_DEPTH)
	var bottom_front_left := _screen(PIT_START_U, 5.0, PIT_DEPTH)

	var back_wall := Polygon2D.new()
	back_wall.name = "PitBackWall"
	back_wall.z_index = -3600
	back_wall.color = Color(0.20, 0.16, 0.14, 1.0)
	back_wall.polygon = PackedVector2Array([top_back_left, top_back_right, bottom_back_right, bottom_back_left])
	generated_map.add_child(back_wall)

	var bottom := Polygon2D.new()
	bottom.name = "PitBottom"
	bottom.z_index = -3500
	bottom.color = Color(0.12, 0.11, 0.105, 1.0)
	bottom.polygon = PackedVector2Array([bottom_back_left, bottom_back_right, bottom_front_right, bottom_front_left])
	generated_map.add_child(bottom)

	var left_wall := Polygon2D.new()
	left_wall.name = "PitLeftWall"
	left_wall.z_index = -3400
	left_wall.color = Color(0.26, 0.19, 0.15, 1.0)
	left_wall.polygon = PackedVector2Array([top_back_left, top_front_left, bottom_front_left, bottom_back_left])
	generated_map.add_child(left_wall)

	var right_wall := Polygon2D.new()
	right_wall.name = "PitRightWall"
	right_wall.z_index = -3400
	right_wall.color = Color(0.24, 0.18, 0.145, 1.0)
	right_wall.polygon = PackedVector2Array([top_back_right, top_front_right, bottom_front_right, bottom_back_right])
	generated_map.add_child(right_wall)

	var front_rim := Line2D.new()
	front_rim.name = "PitFrontRim"
	front_rim.z_index = 1800
	front_rim.width = 24.0
	front_rim.default_color = Color(0.16, 0.115, 0.09, 0.88)
	front_rim.points = PackedVector2Array([top_front_left, top_front_right])
	generated_map.add_child(front_rim)


func _add_bicycle(u: float, v: float) -> void:
	var root := Node2D.new()
	root.name = "BicyclePlaceholder"
	root.position = _screen(u, v)
	root.z_index = 500
	generated_map.add_child(root)
	for x in [-32.0, 32.0]:
		var wheel := Polygon2D.new()
		wheel.color = Color(0.12, 0.12, 0.13, 1.0)
		wheel.polygon = _circle_polygon(Vector2(x, -8), 22.0, 20)
		root.add_child(wheel)
	var frame := Line2D.new()
	frame.width = 6.0
	frame.default_color = Color(0.72, 0.60, 0.30, 1.0)
	frame.points = PackedVector2Array([
		Vector2(-32, -8), Vector2(-2, -42), Vector2(20, -8),
		Vector2(-14, -8), Vector2(-2, -42), Vector2(32, -8)
	])
	root.add_child(frame)


func _add_large_puddle() -> void:
	var puddle := Polygon2D.new()
	puddle.name = "LargePuddlePlaceholder"
	puddle.z_index = -1000
	puddle.color = Color(0.20, 0.42, 0.48, 0.82)
	puddle.polygon = PackedVector2Array([
		_screen(12.0, -3.4), _screen(17.0, -4.5), _screen(24.0, -4.0),
		_screen(30.0, -2.0), _screen(29.0, 2.8), _screen(23.0, 4.6),
		_screen(16.0, 4.0), _screen(11.0, 1.5)
	])
	generated_map.add_child(puddle)
	var shine := Line2D.new()
	shine.z_index = -900
	shine.width = 5.0
	shine.default_color = Color(0.64, 0.82, 0.82, 0.48)
	shine.points = PackedVector2Array([_screen(16.0, -1.0), _screen(21.0, -1.7), _screen(26.0, -0.7)])
	generated_map.add_child(shine)


func _add_gate_visual() -> void:
	_gate_visual = Node2D.new()
	_gate_visual.name = "GatePlaceholder"
	_gate_visual.z_index = 900
	generated_map.add_child(_gate_visual)
	var gate := Line2D.new()
	gate.width = 12.0
	gate.default_color = Color(0.36, 0.19, 0.12, 1.0)
	gate.points = PackedVector2Array([_screen(44.0, -4.4), _screen(44.0, 4.4)])
	_gate_visual.add_child(gate)
	var gap := Polygon2D.new()
	gap.color = Color(0.78, 0.61, 0.28, 0.9)
	gap.polygon = PackedVector2Array([
		_screen(43.7, 2.8), _screen(44.3, 2.8), _screen(44.3, 4.2), _screen(43.7, 4.2)
	])
	_gate_visual.add_child(gap)


func _add_pressure_plate(u: float, v: float) -> void:
	var plate := Line2D.new()
	plate.name = "PressurePlatePlaceholder"
	plate.z_index = 300
	plate.width = 9.0
	plate.default_color = Color(0.92, 0.68, 0.25, 0.9)
	plate.points = PackedVector2Array([_screen(u - 0.5, v), _screen(u + 0.5, v)])
	generated_map.add_child(plate)


func _add_plank_visual() -> void:
	_plank_intact = Node2D.new()
	_plank_intact.name = "PlankIntactPlaceholder"
	_plank_intact.z_index = 200
	generated_map.add_child(_plank_intact)
	for v in [-1.2, -0.4, 0.4, 1.2]:
		var board := Line2D.new()
		board.width = 15.0
		board.default_color = Color(0.56, 0.34, 0.16, 1.0)
		board.points = PackedVector2Array([_screen(PIT_START_U, v), _screen(PIT_END_U, v)])
		_plank_intact.add_child(board)

	_plank_broken = Node2D.new()
	_plank_broken.name = "PlankBrokenPlaceholder"
	_plank_broken.z_index = 200
	_plank_broken.visible = false
	generated_map.add_child(_plank_broken)
	for v in [-1.0, 0.0, 1.0]:
		var left_piece := Line2D.new()
		left_piece.width = 14.0
		left_piece.default_color = Color(0.52, 0.30, 0.14, 1.0)
		left_piece.points = PackedVector2Array([_screen(PIT_START_U, v), _screen(PIT_START_U + 1.8, v + 0.25)])
		_plank_broken.add_child(left_piece)
		var right_piece := Line2D.new()
		right_piece.width = 14.0
		right_piece.default_color = Color(0.52, 0.30, 0.14, 1.0)
		right_piece.points = PackedVector2Array([_screen(PIT_END_U - 1.6, v - 0.2), _screen(PIT_END_U, v)])
		_plank_broken.add_child(right_piece)


func _add_lamppost(u: float, v: float) -> void:
	var root := Node2D.new()
	root.name = "LamppostPlaceholder"
	root.position = _screen(u, v)
	root.z_index = 700
	generated_map.add_child(root)
	var pole := Line2D.new()
	pole.width = 12.0
	pole.default_color = Color(0.18, 0.28, 0.24, 1.0)
	pole.points = PackedVector2Array([Vector2.ZERO, Vector2(0, -180), Vector2(68, -180)])
	root.add_child(pole)
	var lamp := Polygon2D.new()
	lamp.color = Color(1.0, 0.72, 0.28, 0.95)
	lamp.polygon = _circle_polygon(Vector2(70, -166), 18.0, 20)
	root.add_child(lamp)


func _add_school_gate(u: float, v: float) -> void:
	var root := Node2D.new()
	root.name = "SchoolGatePlaceholder"
	root.z_index = -1200
	generated_map.add_child(root)
	for offset in [-3.5, 3.5]:
		var pillar := Line2D.new()
		pillar.width = 24.0
		pillar.default_color = Color(0.58, 0.44, 0.28, 1.0)
		pillar.points = PackedVector2Array([_screen(u, v + offset), _screen(u, v + offset, 2.6)])
		root.add_child(pillar)
	var header := Line2D.new()
	header.width = 20.0
	header.default_color = Color(0.68, 0.50, 0.28, 1.0)
	header.points = PackedVector2Array([_screen(u, v - 3.5, 2.5), _screen(u, v + 3.5, 2.5)])
	root.add_child(header)


func _add_direction_markers() -> void:
	for u in [8.0, 35.0, 50.0, 72.0, 84.0, 103.0, 117.0]:
		var marker := Polygon2D.new()
		marker.name = "DirectionMarker"
		marker.z_index = -700
		marker.color = Color(0.90, 0.62, 0.22, 0.55)
		var center := _screen(u, 0.0)
		marker.polygon = PackedVector2Array([
			center + Vector2(-24, -10), center + Vector2(12, -10), center + Vector2(12, -22),
			center + Vector2(38, 0), center + Vector2(12, 22), center + Vector2(12, 10),
			center + Vector2(-24, 10)
		])
		generated_map.add_child(marker)


func _add_block_label(text: String, u: float, v: float) -> void:
	var label := Label.new()
	label.text = text
	label.position = _screen(u, v) - Vector2(150, 20)
	label.size = Vector2(300, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.58, 0.82))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.z_index = 2100
	generated_map.add_child(label)


func _circle_polygon(center: Vector2, radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _build_hidden_physics() -> void:
	_add_side_walls(0.0, 40.0, 5.5)
	_add_side_walls(40.0, PIT_START_U, 5.0)
	_add_side_walls(PIT_END_U, 70.0, 4.5)
	_add_side_walls(70.0, 80.0, 2.2)
	_add_side_walls(80.0, MAP_END_U, 5.5)
	_add_cross_wall(0.0, 5.5)
	_add_cross_wall(MAP_END_U, 5.5)

	_gate_body = _add_cross_wall(44.0, 4.8)
	# 坑横切整条街：母亲不能从两侧绕过，剧情恢复后直接落在另一端。
	_add_cross_wall(PIT_START_U - 0.15, 5.0)


func _add_side_walls(u0: float, u1: float, half_width: float) -> void:
	_add_wall_segment(u0, u1, -half_width)
	_add_wall_segment(u0, u1, half_width)


func _add_wall_segment(u0: float, u1: float, v: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Wall_%d_%d" % [int(u0), int(u1)]
	spatial_physics.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(ALONG.length() * (u1 - u0), 2.0, 0.45)
	collision.shape = shape
	body.add_child(collision)
	body.position = _logical((u0 + u1) * 0.5, v) + Vector3.UP
	body.rotation.y = PI * 0.25
	return body


func _add_cross_wall(u: float, half_width: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "CrossWall_%d" % int(u)
	spatial_physics.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(ACROSS.length() * half_width * 2.0, 2.0, 0.5)
	collision.shape = shape
	body.add_child(collision)
	body.position = _logical(u, 0.0) + Vector3.UP
	body.rotation.y = -PI * 0.25
	return body
