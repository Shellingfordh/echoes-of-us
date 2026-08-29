class_name Chapter2Sequence
extends Node2D

## 第二章 2.5D 流程框架。
## 三个 Block 使用文档中的真实 XYZ；六个教学关由单一顺序状态机门控。

enum Stage {
	BICYCLE,
	PUDDLE,
	NARROW,
	FALL,
	CLIMB,
	LAMP_SCHOOL,
	COMPLETE,
}

const A_MOTHER_SPAWN := Vector3(3.0, 0.0, 9.5)
const A_CHILD_SPAWN := Vector3(4.5, 0.0, 11.5)
const A_BICYCLE := Vector3(8.0, 0.0, 12.0)
const A_BICYCLE_PARK := Vector3(7.1, 0.0, 9.3)
const A_CHILD_FAR := Vector3(33.5, 0.0, 7.4)
const B_MOTHER_STOP := Vector3(80.8, 0.0, 11.0)
const B_CHILD_START := Vector3(82.8, 0.0, 11.0)
const B_BOARD_WARNING := Vector3(87.2, 0.0, 11.0)
const B_FALL_START := Vector3(89.1, 0.0, 11.0)
const B_CATCH := Vector3(89.1, -4.8, 11.0)
const B_CLIMB_OUT := Vector3(98.6, 0.0, 11.0)
const C_ENTRY_MOTHER := Vector3(147.0, 0.0, 15.0)
const C_ENTRY_CHILD := Vector3(149.0, 0.0, 15.0)
const C_LAMP := Vector3(166.0, 0.0, 13.0)
const C_LOOKBACK := Vector3(180.0, 0.0, 14.0)
const C_GOAL := Vector3(188.0, 0.0, 14.0)

const STAGE_NAMES := [
	"自行车",
	"水坑与距离",
	"窄缝与角色切换",
	"断板与承重",
	"沿线爬回",
	"路灯与学校",
]

@export var debug_skip_intro := false

@onready var generated_map: Node2D = $World/GeneratedMap
@onready var spatial_physics: Node3D = $World/SpatialPhysics
@onready var player: PlayerController = $Characters/YoungMother
@onready var child: Chapter2Child = $Characters/Child
@onready var rope_top_anchor: Node2D = $Characters/RopeTopAnchor
@onready var tie_line: TieLine = $TieLine
@onready var game_flow: GameFlow = $GameFlow
@onready var camera_rig: CameraRig = $CameraRig
@onready var dialogue_ui: DialogueUI = $UI/DialogueUI
@onready var progress_label: Label = $UI/ProgressLabel
@onready var objective_label: Label = $UI/ObjectiveLabel
@onready var hint_label: Label = $UI/HintLabel
@onready var transition_overlay: ColorRect = $UI/TransitionOverlay
@onready var transition_text: Label = $UI/TransitionOverlay/TransitionText

var current_stage := Stage.BICYCLE
var checkpoint_id := "CH2_START"
var flags := {
	"A_BICYCLE_DONE": false,
	"A_PUDDLE_DONE": false,
	"MOTHER_STABLE": false,
	"B_CHILD_SAFE": false,
	"C_MOTHER_ANCHORED": false,
	"C_LOOKBACK_DONE": false,
	"CH2_COMPLETE": false,
}

var _transition_busy := false
var _puddle_progress := 0.0
var _puddle_announcement_played := false
var _puddle_far_dialogue_played := false
var _board_warned := false
var _lamp_anchored := false
var _lookback_playing := false
var _bicycle_visual: Node2D
var _plank_intact: Node2D
var _plank_broken: Node2D
var _upper_anchor_visual: Node2D


func _ready() -> void:
	_build_visual_map()
	_build_hidden_physics()
	player.set_logical_position(A_MOTHER_SPAWN)
	player.movement_min = Vector2(0.4, 2.4)
	player.movement_max = Vector2(12.0, 21.6)
	child.set_logical_position(A_CHILD_SPAWN)
	child.set_control_enabled(false)
	rope_top_anchor.global_position = Projection25D.project(B_CLIMB_OUT + Vector3.UP * 0.35)

	tie_line.bind(player, child)
	tie_line.set_enabled(true)
	tie_line.set_pullback_locked(true)
	tie_line.set_context(0.02, 0.0, 0.0)
	camera_rig.snap_to(player)
	camera_rig.follow(player, Vector2.ONE, true)
	_update_stage_ui()

	if debug_skip_intro:
		transition_overlay.hide()
		game_flow.set_mode(GameFlow.Mode.EXPLORE)
		_set_objective("靠近倒下的自行车，按 Enter / 空格把它移开。")
	else:
		call_deferred("_run_intro")


func _process(delta: float) -> void:
	match current_stage:
		Stage.PUDDLE:
			_process_puddle(delta)
		Stage.NARROW:
			_process_narrow(delta)
		Stage.CLIMB:
			_process_climb()
		Stage.LAMP_SCHOOL:
			_process_lamp_school(delta)


func _unhandled_input(event: InputEvent) -> void:
	if _transition_busy or dialogue_ui.is_playing() or not event.is_action_pressed(&"interact"):
		return
	match current_stage:
		Stage.BICYCLE:
			if _ground_distance(player.get_logical_position(), A_BICYCLE) <= 3.0:
				get_viewport().set_input_as_handled()
				_complete_bicycle()
		Stage.LAMP_SCHOOL:
			if not _lamp_anchored and _ground_distance(player.get_logical_position(), C_LAMP) <= 2.4:
				get_viewport().set_input_as_handled()
				_anchor_at_lamp()


func _run_intro() -> void:
	_transition_busy = true
	game_flow.set_mode(GameFlow.Mode.CUTSCENE)
	transition_overlay.show()
	transition_overlay.modulate.a = 1.0
	transition_text.text = "余响\n2009 年秋"
	var fade := create_tween()
	fade.tween_interval(0.35)
	fade.tween_property(transition_overlay, "modulate:a", 0.0, 0.65)
	await fade.finished
	transition_overlay.hide()
	await _play_dialogue("D019")
	await _move_child_to(A_BICYCLE, 1.0)
	await _play_dialogue("D020")
	await _play_dialogue("D048")
	game_flow.set_mode(GameFlow.Mode.EXPLORE)
	_transition_busy = false
	_set_objective("小余念搬不动自行车。控制年轻余秀兰靠近，按 Enter / 空格移开它。")
	hint_label.text = "WASD / 方向键移动    Enter / 空格互动"


func _complete_bicycle() -> void:
	if current_stage != Stage.BICYCLE or bool(flags["A_BICYCLE_DONE"]):
		return
	_transition_busy = true
	game_flow.set_mode(GameFlow.Mode.CUTSCENE)
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_bicycle_visual, "global_position", Projection25D.project(A_BICYCLE_PARK), 0.55)
	await tween.finished
	flags["A_BICYCLE_DONE"] = true
	checkpoint_id = "CP-A1"
	await _play_dialogue("D049")
	current_stage = Stage.PUDDLE
	player.movement_max = Vector2(35.5, 21.6)
	tie_line.max_distance = 7.5
	tie_line.tension_distance = 4.5
	tie_line.distance_weight = 0.82
	game_flow.set_mode(GameFlow.Mode.EXPLORE)
	_transition_busy = false
	_update_stage_ui()
	_set_objective("跟上绕水坑的小余念；主动靠近她，让绷紧的线重新松下来。")
	hint_label.text = "孩子会自己绕路。不要把她拉回，只需要走近她。"


func _process_puddle(delta: float) -> void:
	if _transition_busy:
		return
	if not _puddle_announcement_played:
		_puddle_announcement_played = true
		_announce_puddle()
		return
	_puddle_progress = minf(_puddle_progress + delta / 4.8, 1.0)
	var x := lerpf(A_BICYCLE.x, A_CHILD_FAR.x, _puddle_progress)
	# 先移到水坑北侧，再沿不可触碰区域的边缘前进；终点也在水面外。
	var z := lerpf(12.0, A_CHILD_FAR.z, minf(_puddle_progress / 0.28, 1.0))
	child.set_logical_position(Vector3(x, 0.0, z))
	child.set_moving(_puddle_progress < 1.0)
	if _puddle_progress >= 1.0 and not _puddle_far_dialogue_played:
		_puddle_far_dialogue_played = true
		_play_puddle_far_line()
		return
	if _puddle_progress >= 1.0 and _ground_distance(player.get_logical_position(), child.get_logical_position()) <= 4.5:
		_complete_puddle()


func _announce_puddle() -> void:
	_transition_busy = true
	await _play_dialogue("D050")
	_transition_busy = false


func _play_puddle_far_line() -> void:
	_transition_busy = true
	child.set_umbrella_raised(true)
	await _play_dialogue("D022")
	child.set_umbrella_raised(false)
	_transition_busy = false


func _complete_puddle() -> void:
	if current_stage != Stage.PUDDLE or bool(flags["A_PUDDLE_DONE"]):
		return
	_transition_busy = true
	flags["A_PUDDLE_DONE"] = true
	checkpoint_id = "CP-A2"
	tie_line.clear_context()
	await _play_dialogue("D051")
	current_stage = Stage.NARROW
	player.movement_min = Vector2(0.4, 8.6)
	player.movement_max = Vector2(B_MOTHER_STOP.x, 13.4)
	game_flow.set_mode(GameFlow.Mode.EXPLORE)
	_transition_busy = false
	_update_stage_ui()
	_set_objective("沿老街继续前进，到成年人无法通过的窄缝前与孩子会合。")
	hint_label.text = "前两关已完成；窄缝关现在开放。"


func _process_narrow(delta: float) -> void:
	if _transition_busy:
		return
	if not bool(flags["MOTHER_STABLE"]):
		var next_child := child.get_logical_position()
		next_child.x = move_toward(next_child.x, B_CHILD_START.x, 8.5 * delta)
		next_child.z = move_toward(next_child.z, B_CHILD_START.z, 5.0 * delta)
		child.set_logical_position(next_child)
		child.set_moving(not next_child.is_equal_approx(B_CHILD_START))
		if player.get_logical_position().x >= B_MOTHER_STOP.x - 0.65:
			_switch_to_child()
		return

	if not child.is_control_enabled():
		return
	var child_position := child.get_logical_position()
	if child_position.x >= B_BOARD_WARNING.x and not _board_warned:
		_board_warning()
	elif _board_warned and child_position.x >= B_FALL_START.x - 0.55:
		_start_fall()


func _switch_to_child() -> void:
	_transition_busy = true
	player.set_logical_position(B_MOTHER_STOP)
	_set_mother_control(false)
	flags["MOTHER_STABLE"] = true
	child.set_logical_position(B_CHILD_START)
	child.set_ground_bounds(Vector2(82.6, 10.65), Vector2(89.15, 11.35))
	camera_rig.follow(child, Vector2.ONE, true)
	await _play_dialogue("D023")
	child.set_control_enabled(true)
	game_flow.set_mode(GameFlow.Mode.EXPLORE)
	_transition_busy = false
	_set_objective("已切换到七岁余念。穿过窄缝，沿临时木板向右前进。")
	hint_label.text = "当前角色：七岁余念    D / → 向前"


func _board_warning() -> void:
	_transition_busy = true
	child.set_control_enabled(false)
	_plank_intact.modulate = Color(1.0, 0.62, 0.35, 1.0)
	await _play_dialogue("D021")
	_board_warned = true
	child.set_control_enabled(true)
	_transition_busy = false
	_set_objective("木板正在失稳。再向前一步会触发坠落。")


func _start_fall() -> void:
	if current_stage != Stage.NARROW:
		return
	_transition_busy = true
	current_stage = Stage.FALL
	_update_stage_ui()
	child.set_control_enabled(false)
	game_flow.set_mode(GameFlow.Mode.CUTSCENE)
	_plank_intact.hide()
	_plank_broken.show()
	_set_objective("木板断裂——牵挂线即将第一次承担身体重量。")
	hint_label.text = ""

	# 用户指定构图：坠落后母亲不出现在画面。线仍连接坑口上方的稳定端。
	player.hide()
	_upper_anchor_visual.show()
	tie_line.bind(rope_top_anchor, child)
	tie_line.set_force_critical(true)
	camera_rig.follow(child, Vector2.ONE, true)

	var start := child.get_logical_position()
	start.x = B_FALL_START.x
	start.z = B_FALL_START.z
	child.set_logical_position(start)
	var fall := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_method(
		func(weight: float) -> void:
			child.set_logical_position(start.lerp(B_CATCH, weight)),
		0.0,
		1.0,
		0.28
	)
	await fall.finished
	await get_tree().create_timer(0.20).timeout

	current_stage = Stage.CLIMB
	_update_stage_ui()
	game_flow.set_mode(GameFlow.Mode.CHALLENGE)
	_set_objective("线已经托住余念。画面外的母亲让线保持稳定，出口在断板对面的坑沿。")
	await _play_dialogue("D024")
	child.begin_climb(B_CLIMB_OUT)
	_transition_busy = false
	_set_objective("按住 W / ↑ 沿牵挂线斜向上爬，到达断板对面的安全平台。")
	hint_label.text = "按住 W / ↑ 攀爬    松开会停住    出口在坑的另一侧"


func _process_climb() -> void:
	if _transition_busy or not child.is_climbing():
		return
	if child.has_reached_climb_target():
		_finish_climb()


func _finish_climb() -> void:
	_transition_busy = true
	child.end_climb()
	game_flow.set_mode(GameFlow.Mode.CUTSCENE)
	var start := child.get_logical_position()
	var climb_out := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	climb_out.tween_method(
		func(weight: float) -> void:
			child.set_logical_position(start.lerp(B_CLIMB_OUT, weight)),
		0.0,
		1.0,
		0.45
	)
	await climb_out.finished
	flags["B_CHILD_SAFE"] = true
	checkpoint_id = "CP-B1"
	await _play_dialogue("D052")
	await _play_dialogue("D053")
	await _enter_block_c()


func _enter_block_c() -> void:
	transition_overlay.show()
	transition_text.text = "穿过老街\n学校就在前面"
	transition_overlay.modulate.a = 0.0
	var fade_out := create_tween()
	fade_out.tween_property(transition_overlay, "modulate:a", 1.0, 0.28)
	await fade_out.finished

	player.show()
	player.set_logical_position(C_ENTRY_MOTHER)
	player.movement_min = Vector2(144.4, 2.4)
	player.movement_max = Vector2(C_LAMP.x, 25.6)
	child.set_logical_position(C_ENTRY_CHILD)
	child.set_control_enabled(false)
	_upper_anchor_visual.hide()
	tie_line.set_force_critical(false)
	tie_line.bind(player, child)
	tie_line.set_extended(true)
	tie_line.max_distance = 24.0
	tie_line.tension_distance = 22.0
	tie_line.clear_context()
	_set_mother_control(true)
	camera_rig.snap_to(player)
	camera_rig.follow(player, Vector2.ONE, true)
	current_stage = Stage.LAMP_SCHOOL
	_lamp_anchored = false
	_update_stage_ui()
	game_flow.set_mode(GameFlow.Mode.EXPLORE)

	var fade_in := create_tween()
	fade_in.tween_property(transition_overlay, "modulate:a", 0.0, 0.3)
	await fade_in.finished
	transition_overlay.hide()
	_transition_busy = false
	_set_objective("控制年轻余秀兰走到绿色铁艺路灯旁，按 Enter / 空格主动锚定。")
	hint_label.text = "当前角色：年轻余秀兰    前五关已完成"


func _process_lamp_school(delta: float) -> void:
	if _transition_busy:
		return
	if not _lamp_anchored:
		var follow_target := child.get_logical_position()
		follow_target.x = move_toward(follow_target.x, minf(player.get_logical_position().x + 2.2, 168.0), 4.5 * delta)
		follow_target.z = move_toward(follow_target.z, player.get_logical_position().z, 3.2 * delta)
		child.set_logical_position(follow_target)
		child.set_moving(true)
		return

	if not child.is_control_enabled():
		return
	var child_x := child.get_logical_position().x
	if child_x >= C_LOOKBACK.x - 0.55 and not bool(flags["C_LOOKBACK_DONE"]) and not _lookback_playing:
		_play_lookback()
	elif child_x >= C_GOAL.x - 0.6 and bool(flags["C_LOOKBACK_DONE"]):
		_finish_chapter()


func _anchor_at_lamp() -> void:
	if _lamp_anchored:
		return
	_transition_busy = true
	player.set_logical_position(C_LAMP)
	_set_mother_control(false)
	_lamp_anchored = true
	flags["C_MOTHER_ANCHORED"] = true
	checkpoint_id = "CP-C1"
	await _play_dialogue("D025")
	child.set_logical_position(Vector3(168.0, 0.0, 14.0))
	child.set_ground_bounds(Vector2(168.0, 12.0), Vector2(188.2, 16.0))
	child.set_control_enabled(true)
	child.set_umbrella_raised(true)
	camera_rig.follow(child, Vector2.ONE, true)
	game_flow.set_mode(GameFlow.Mode.EXPLORE)
	_transition_busy = false
	_set_objective("母亲已经停下。控制小余念独自走向学校；母亲不会继续追。")
	hint_label.text = "当前角色：七岁余念    D / → 前往学校"


func _play_lookback() -> void:
	_lookback_playing = true
	_transition_busy = true
	child.set_control_enabled(false)
	child.set_logical_position(C_LOOKBACK)
	child.set_umbrella_raised(true)
	camera_rig.stop_following()
	await _play_dialogue("D054")
	flags["C_LOOKBACK_DONE"] = true
	child.set_control_enabled(true)
	camera_rig.follow(child, Vector2.ONE, true)
	_transition_busy = false
	_lookback_playing = false
	_set_objective("余念已经回头确认。继续走进校门，完成第二章。")


func _finish_chapter() -> void:
	if bool(flags["CH2_COMPLETE"]):
		return
	_transition_busy = true
	child.set_control_enabled(false)
	child.set_logical_position(C_GOAL)
	game_flow.set_mode(GameFlow.Mode.CUTSCENE)
	flags["CH2_COMPLETE"] = true
	checkpoint_id = "CH2_COMPLETE"
	current_stage = Stage.COMPLETE
	progress_label.text = "教学完成 6 / 6"
	_set_objective("第二章完成：牵挂不只是拉住，也可以守护。")
	hint_label.text = ""
	transition_overlay.show()
	transition_overlay.modulate.a = 0.0
	transition_text.text = "牵挂，不只是拉住，\n也可以守护。"
	var ending := create_tween()
	ending.tween_interval(0.65)
	ending.tween_property(transition_overlay, "modulate:a", 0.92, 1.1)
	await ending.finished


func _play_dialogue(dialogue_id: String) -> void:
	if debug_skip_intro:
		return
	if not dialogue_ui.is_node_ready():
		await dialogue_ui.ready
	dialogue_ui.play(dialogue_id)
	if dialogue_ui.is_playing():
		await dialogue_ui.dialogue_finished


func _move_child_to(target: Vector3, duration: float) -> void:
	var start := child.get_logical_position()
	child.set_moving(true)
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(
		func(weight: float) -> void:
			child.set_logical_position(start.lerp(target, weight)),
		0.0,
		1.0,
		duration
	)
	await tween.finished
	child.set_moving(false)


func _set_mother_control(enabled: bool) -> void:
	player.set_physics_process(enabled)
	player.set_process_unhandled_input(enabled)
	if not enabled:
		player.math_body.velocity = Vector3.ZERO


func _update_stage_ui() -> void:
	if current_stage >= Stage.BICYCLE and current_stage <= Stage.LAMP_SCHOOL:
		progress_label.text = "教学 %d / 6 · %s" % [current_stage + 1, STAGE_NAMES[current_stage]]


func _set_objective(text: String) -> void:
	objective_label.text = text


func _ground_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))


func get_progress_snapshot() -> Dictionary:
	return {
		"stage": current_stage,
		"checkpoint": checkpoint_id,
		"flags": flags.duplicate(true),
		"controlled_character": "child" if child.is_control_enabled() else "mother",
	}


func _build_visual_map() -> void:
	_add_road("BlockA_Road", 0.0, 48.0, 0.0, 24.0, Color(0.40, 0.28, 0.18, 1.0))
	_add_road("A_to_B_Connector", 48.0, 72.0, 8.5, 13.5, Color(0.34, 0.25, 0.18, 1.0))
	_add_road("BlockB_Approach", 72.0, 86.0, 2.0, 20.0, Color(0.34, 0.25, 0.17, 1.0))
	_add_road("BlockB_FarSide", 98.0, 104.0, 4.0, 18.0, Color(0.34, 0.25, 0.17, 1.0))
	_add_road("B_to_C_Connector", 104.0, 144.0, 9.0, 18.0, Color(0.30, 0.23, 0.17, 1.0))
	_add_road("BlockC_Road", 144.0, 192.0, 0.0, 28.0, Color(0.42, 0.30, 0.19, 1.0))

	_add_block_label("BLOCK A · 自行车 / 水坑", Vector3(23.0, 0.0, 2.7))
	_add_block_label("BLOCK B · 窄缝 / 深坑", Vector3(86.0, 0.0, 3.0))
	_add_block_label("BLOCK C · 路灯 / 学校", Vector3(166.0, 0.0, 2.8))

	_add_prism("TailorShop", Vector3(7.0, 0.0, 2.8), Vector3(12.0, 4.0, 1.6), Color(0.54, 0.29, 0.16, 1.0))
	_add_prism("BreakfastStall", Vector3(14.0, 0.0, 20.0), Vector3(5.0, 2.2, 2.0), Color(0.64, 0.42, 0.22, 1.0))
	_add_prism("A_Cabinet01", Vector3(20.0, 0.0, 3.7), Vector3(5.0, 2.0, 1.2), Color(0.45, 0.29, 0.17, 1.0))
	_add_prism("A_Cabinet02", Vector3(31.0, 0.0, 3.7), Vector3(6.0, 2.4, 1.2), Color(0.48, 0.31, 0.18, 1.0))
	_add_street_walls()
	_add_long_connector_walls()
	_add_bicycle()
	_add_puddle()
	_add_narrow_gap()
	_add_pit()
	_add_plank()
	_add_lamppost()
	_add_school()
	_add_block_c_details()
	_add_environment_lines()


func _add_road(name: String, x0: float, x1: float, z0: float, z1: float, color: Color) -> void:
	var road := Polygon2D.new()
	road.name = name
	road.z_index = -1700
	road.color = color
	road.polygon = PackedVector2Array([
		Projection25D.project(Vector3(x0, 0.0, z0)),
		Projection25D.project(Vector3(x1, 0.0, z0)),
		Projection25D.project(Vector3(x1, 0.0, z1)),
		Projection25D.project(Vector3(x0, 0.0, z1)),
	])
	generated_map.add_child(road)


func _add_prism(name: String, center: Vector3, size: Vector3, color: Color) -> Node2D:
	var root := Node2D.new()
	root.name = name
	root.z_index = Projection25D.depth_index(center)
	generated_map.add_child(root)
	var x0 := center.x - size.x * 0.5
	var x1 := center.x + size.x * 0.5
	var z0 := center.z - size.z * 0.5
	var z1 := center.z + size.z * 0.5
	var y1 := center.y + size.y
	var side_x := Polygon2D.new()
	side_x.color = color.darkened(0.28)
	side_x.polygon = PackedVector2Array([
		Projection25D.project(Vector3(x1, center.y, z0)), Projection25D.project(Vector3(x1, center.y, z1)),
		Projection25D.project(Vector3(x1, y1, z1)), Projection25D.project(Vector3(x1, y1, z0)),
	])
	root.add_child(side_x)
	var side_z := Polygon2D.new()
	side_z.color = color.darkened(0.16)
	side_z.polygon = PackedVector2Array([
		Projection25D.project(Vector3(x0, center.y, z1)), Projection25D.project(Vector3(x1, center.y, z1)),
		Projection25D.project(Vector3(x1, y1, z1)), Projection25D.project(Vector3(x0, y1, z1)),
	])
	root.add_child(side_z)
	var top := Polygon2D.new()
	top.color = color.lightened(0.14)
	top.polygon = PackedVector2Array([
		Projection25D.project(Vector3(x0, y1, z0)), Projection25D.project(Vector3(x1, y1, z0)),
		Projection25D.project(Vector3(x1, y1, z1)), Projection25D.project(Vector3(x0, y1, z1)),
	])
	root.add_child(top)
	return root


func _add_street_walls() -> void:
	# 先用连续矩形墙贴建立街道边界和纵深，避免各 Block 像漂浮的坐标岛。
	_add_prism("A_NorthWallVisual", Vector3(25.0, 0.0, 1.7), Vector3(46.0, 3.2, 0.7), Color(0.48, 0.29, 0.19, 1.0))
	_add_prism("A_SouthWallVisual", Vector3(25.0, 0.0, 22.3), Vector3(46.0, 2.8, 0.7), Color(0.43, 0.27, 0.18, 1.0))
	_add_prism("B_NorthWallVisual", Vector3(78.0, 0.0, 1.7), Vector3(12.0, 3.4, 0.7), Color(0.40, 0.26, 0.18, 1.0))
	_add_prism("B_SouthWallVisual", Vector3(78.0, 0.0, 20.3), Vector3(12.0, 3.0, 0.7), Color(0.36, 0.23, 0.17, 1.0))
	_add_prism("C_NorthWallVisual", Vector3(168.0, 0.0, 1.7), Vector3(46.0, 4.0, 0.7), Color(0.50, 0.31, 0.20, 1.0))
	_add_prism("C_SouthWallVisual", Vector3(168.0, 0.0, 26.3), Vector3(46.0, 3.4, 0.7), Color(0.44, 0.28, 0.19, 1.0))


func _add_long_connector_walls() -> void:
	# A→B 是明确可走的细长通道：5m 净宽、24m 长，两侧都有墙面和实体碰撞。
	_add_prism("AB_CorridorNorthVisual", Vector3(60.0, 0.0, 8.15), Vector3(24.0, 3.6, 0.7), Color(0.31, 0.23, 0.18, 1.0))
	_add_prism("AB_CorridorSouthVisual", Vector3(60.0, 0.0, 13.85), Vector3(24.0, 3.2, 0.7), Color(0.28, 0.21, 0.17, 1.0))
	for x in [52.0, 60.0, 68.0]:
		var light_patch := Polygon2D.new()
		light_patch.name = "CorridorLightPatch"
		light_patch.z_index = -1100
		light_patch.color = Color(0.94, 0.63, 0.25, 0.12)
		light_patch.polygon = PackedVector2Array([
			Projection25D.project(Vector3(x - 1.3, 0.02, 8.8)), Projection25D.project(Vector3(x + 1.3, 0.02, 8.8)),
			Projection25D.project(Vector3(x + 1.3, 0.02, 13.2)), Projection25D.project(Vector3(x - 1.3, 0.02, 13.2)),
		])
		generated_map.add_child(light_patch)


func _add_block_c_details() -> void:
	# 路灯到学校之间增加沿街体块、邮筒、台阶与围栏，仍保持白盒级别。
	_add_prism("C_NorthHouse01", Vector3(151.0, 0.0, 4.0), Vector3(10.0, 3.6, 2.6), Color(0.58, 0.34, 0.20, 1.0))
	_add_prism("C_NorthHouse02", Vector3(164.0, 0.0, 4.0), Vector3(10.0, 4.4, 2.6), Color(0.46, 0.30, 0.22, 1.0))
	_add_prism("C_SouthHouse01", Vector3(153.0, 0.0, 23.8), Vector3(12.0, 3.2, 2.8), Color(0.50, 0.31, 0.19, 1.0))
	_add_prism("C_Mailbox", Vector3(170.0, 0.0, 17.5), Vector3(0.9, 1.5, 0.8), Color(0.42, 0.12, 0.09, 1.0))
	for index in range(4):
		_add_prism(
			"C_SchoolStep_%d" % index,
			Vector3(183.0 + float(index) * 0.8, 0.0, 14.0),
			Vector3(0.8, 0.12 + float(index) * 0.08, 5.5),
			Color(0.46, 0.39, 0.30, 1.0)
		)
	for z in [8.0, 20.0]:
		var fence := Line2D.new()
		fence.name = "SchoolFence"
		fence.z_index = 900
		fence.width = 5.0
		fence.default_color = Color(0.12, 0.22, 0.17, 1.0)
		fence.points = PackedVector2Array([
			Projection25D.project(Vector3(176.0, 1.2, z)), Projection25D.project(Vector3(190.0, 1.2, z)),
		])
		generated_map.add_child(fence)


func _add_bicycle() -> void:
	_bicycle_visual = Node2D.new()
	_bicycle_visual.name = "BicyclePlaceholder"
	_bicycle_visual.global_position = Projection25D.project(A_BICYCLE)
	_bicycle_visual.z_index = 700
	generated_map.add_child(_bicycle_visual)
	for x in [-30.0, 30.0]:
		var wheel := Line2D.new()
		wheel.width = 5.0
		wheel.default_color = Color(0.08, 0.07, 0.06, 1.0)
		wheel.closed = true
		wheel.points = _circle_points(Vector2(x, -7), 21.0, 18)
		_bicycle_visual.add_child(wheel)
	var frame := Line2D.new()
	frame.width = 6.0
	frame.default_color = Color(0.82, 0.56, 0.16, 1.0)
	frame.points = PackedVector2Array([-30, -7, -3, -40, 20, -7, -15, -7, -3, -40, 30, -7])
	_bicycle_visual.add_child(frame)


func _add_puddle() -> void:
	var puddle := Polygon2D.new()
	puddle.name = "A_Puddle"
	puddle.z_index = -1200
	puddle.color = Color(0.16, 0.38, 0.45, 0.86)
	puddle.polygon = PackedVector2Array([
		Projection25D.project(Vector3(17.5, 0.02, 8.5)), Projection25D.project(Vector3(32.5, 0.02, 8.5)),
		Projection25D.project(Vector3(32.5, 0.02, 16.5)), Projection25D.project(Vector3(17.5, 0.02, 16.5)),
	])
	generated_map.add_child(puddle)


func _add_narrow_gap() -> void:
	_add_prism("NarrowWallNorth", Vector3(82.0, 0.0, 6.3), Vector3(1.0, 2.8, 8.6), Color(0.37, 0.25, 0.18, 1.0))
	_add_prism("NarrowWallSouth", Vector3(82.0, 0.0, 15.7), Vector3(1.0, 2.8, 8.6), Color(0.37, 0.25, 0.18, 1.0))
	var sign := Label.new()
	sign.text = "仅儿童可通过"
	sign.position = Projection25D.project(Vector3(81.7, 2.6, 11.0)) - Vector2(70, 20)
	sign.add_theme_font_size_override("font_size", 16)
	sign.add_theme_color_override("font_color", Color(0.95, 0.73, 0.34, 0.9))
	sign.z_index = 1700
	generated_map.add_child(sign)


func _add_pit() -> void:
	var bottom := Polygon2D.new()
	bottom.name = "PitBottom"
	bottom.z_index = -1500
	bottom.color = Color(0.07, 0.045, 0.03, 1.0)
	bottom.polygon = PackedVector2Array([
		Projection25D.project(Vector3(84.0, -8.0, 4.0)), Projection25D.project(Vector3(98.0, -8.0, 4.0)),
		Projection25D.project(Vector3(98.0, -8.0, 18.0)), Projection25D.project(Vector3(84.0, -8.0, 18.0)),
	])
	generated_map.add_child(bottom)
	for data in [
		["PitNorthRim", Vector3(91.0, 0.0, 3.8), Vector3(14.0, 0.7, 0.5)],
		["PitSouthRim", Vector3(91.0, 0.0, 18.2), Vector3(14.0, 0.7, 0.5)],
		["PitWestRim", Vector3(83.8, 0.0, 11.0), Vector3(0.5, 0.7, 14.0)],
		["PitEastRim", Vector3(98.2, 0.0, 11.0), Vector3(0.5, 0.7, 14.0)],
	]:
		_add_prism(data[0], data[1], data[2], Color(0.25, 0.17, 0.12, 1.0))
	_add_prism("PitCrate", Vector3(94.0, -8.0, 15.0), Vector3(1.4, 1.2, 1.4), Color(0.35, 0.20, 0.11, 1.0))
	_add_prism("PitBarrel", Vector3(87.0, -8.0, 6.0), Vector3(1.0, 1.3, 1.0), Color(0.30, 0.22, 0.14, 1.0))
	_upper_anchor_visual = Node2D.new()
	_upper_anchor_visual.name = "UpperStableEndpoint"
	_upper_anchor_visual.position = Projection25D.project(B_CLIMB_OUT + Vector3.UP * 0.3)
	_upper_anchor_visual.z_index = 2450
	_upper_anchor_visual.hide()
	generated_map.add_child(_upper_anchor_visual)
	var ring := Line2D.new()
	ring.width = 4.0
	ring.default_color = Color(1.0, 0.27, 0.17, 0.95)
	ring.closed = true
	ring.points = _circle_points(Vector2.ZERO, 12.0, 20)
	_upper_anchor_visual.add_child(ring)


func _add_plank() -> void:
	_plank_intact = Node2D.new()
	_plank_intact.name = "BreakablePlank"
	_plank_intact.z_index = 500
	generated_map.add_child(_plank_intact)
	for z in [10.35, 10.8, 11.25, 11.7]:
		var board := Line2D.new()
		board.width = 12.0
		board.default_color = Color(0.56, 0.33, 0.15, 1.0)
		board.points = PackedVector2Array([
			Projection25D.project(Vector3(82.4, 0.2, z)), Projection25D.project(Vector3(89.2, 0.2, z)),
		])
		_plank_intact.add_child(board)
	_plank_broken = Node2D.new()
	_plank_broken.name = "BrokenPlank"
	_plank_broken.z_index = 500
	_plank_broken.hide()
	generated_map.add_child(_plank_broken)
	for z in [10.45, 11.05, 11.65]:
		for segment in [[82.4, 85.6], [88.7, 89.4]]:
			var piece := Line2D.new()
			piece.width = 12.0
			piece.default_color = Color(0.48, 0.26, 0.12, 1.0)
			piece.points = PackedVector2Array([
				Projection25D.project(Vector3(segment[0], 0.1, z)), Projection25D.project(Vector3(segment[1], -0.2, z)),
			])
			_plank_broken.add_child(piece)


func _add_lamppost() -> void:
	var root := Node2D.new()
	root.name = "GreenIronLamppost"
	root.position = Projection25D.project(C_LAMP)
	root.z_index = 1200
	generated_map.add_child(root)
	var pole := Line2D.new()
	pole.width = 11.0
	pole.default_color = Color(0.08, 0.25, 0.18, 1.0)
	pole.points = PackedVector2Array([Vector2.ZERO, Vector2(0, -190), Vector2(48, -190)])
	root.add_child(pole)
	var lamp := Polygon2D.new()
	lamp.color = Color(1.0, 0.70, 0.22, 1.0)
	lamp.polygon = _circle_points(Vector2(50, -174), 18.0, 20)
	root.add_child(lamp)


func _add_school() -> void:
	_add_prism("SchoolBuilding", Vector3(187.0, 0.0, 3.0), Vector3(10.0, 6.0, 5.0), Color(0.55, 0.34, 0.20, 1.0))
	for z in [11.0, 17.0]:
		_add_prism("SchoolGatePillar_%d" % int(z), Vector3(189.0, 0.0, z), Vector3(0.8, 3.8, 0.8), Color(0.20, 0.28, 0.20, 1.0))


func _add_environment_lines() -> void:
	for pair in [[Vector3(5, 3.7, 3), Vector3(18, 3.3, 21)], [Vector3(22, 4.0, 3), Vector3(36, 3.4, 21)], [Vector3(150, 4.1, 3), Vector3(174, 3.6, 25)]]:
		var line := Line2D.new()
		line.name = "OrdinaryClothesline"
		line.z_index = -300
		line.width = 2.0
		line.default_color = Color(0.16, 0.12, 0.09, 0.68)
		line.points = PackedVector2Array([Projection25D.project(pair[0]), Projection25D.project(pair[1])])
		generated_map.add_child(line)


func _add_block_label(text: String, position: Vector3) -> void:
	var label := Label.new()
	label.text = text
	label.position = Projection25D.project(position) - Vector2(150, 22)
	label.size = Vector2(300, 44)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.98, 0.79, 0.45, 0.78))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.z_index = 1800
	generated_map.add_child(label)


func _circle_points(center: Vector2, radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _build_hidden_physics() -> void:
	_add_wall("A_North", Vector3(24.0, 1.2, 2.0), Vector3(48.0, 2.4, 0.4))
	_add_wall("A_South", Vector3(24.0, 1.2, 22.0), Vector3(48.0, 2.4, 0.4))
	# 水坑是不可触碰区域；孩子的自动路线从北侧绕行，母亲会被实体边缘挡住。
	_add_wall("A_PuddleBlocker", Vector3(25.0, 1.0, 12.5), Vector3(15.0, 2.0, 8.0))
	# Block A 到 B 的细长通道，墙体与视觉矩形一一对应。
	_add_wall("AB_CorridorNorth", Vector3(60.0, 1.8, 8.15), Vector3(24.0, 3.6, 0.7))
	_add_wall("AB_CorridorSouth", Vector3(60.0, 1.6, 13.85), Vector3(24.0, 3.2, 0.7))
	_add_wall("B_North", Vector3(78.0, 1.2, 2.0), Vector3(12.0, 2.4, 0.4))
	_add_wall("B_South", Vector3(78.0, 1.2, 20.0), Vector3(12.0, 2.4, 0.4))
	_add_wall("B_GapNorth", Vector3(82.0, 1.2, 6.325), Vector3(1.0, 2.4, 8.65))
	_add_wall("B_GapSouth", Vector3(82.0, 1.2, 15.675), Vector3(1.0, 2.4, 8.65))
	_add_wall("C_North", Vector3(168.0, 1.2, 2.0), Vector3(48.0, 2.4, 0.4))
	_add_wall("C_South", Vector3(168.0, 1.2, 26.0), Vector3(48.0, 2.4, 0.4))


func _add_wall(name: String, center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = name
	body.position = center
	spatial_physics.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
