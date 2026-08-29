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
## 爬升终点落在 BlockB_Farside 平台上（编辑器实测 x 85.6~99.3 / z 1.5~10.4）。
## 贴着平台靠坑的那条南边缘（z ≈ 10.1），这样线的上端看着就搭在崖沿上。
## 牵挂线的上端点也用这个值，见 _ready() 里的 rope_top_anchor。
const B_CLIMB_OUT := Vector3(96.2, 0.0, 9.5)

## 坠落期间母亲站的位置：climb-out 正后方半米，人在平台上、脚在边缘内侧。
const B_MOTHER_PIT_EDGE := Vector3(95.6, 0.0, 8.9)

## 坑底那张横面的高度。
const B_PIT_FLOOR_Y := -4.8
## PitBottom 的多边形按 y = -4.8 反投影，四角是
## (87.17, 10.39) (101.27, 10.04) (101.20, 21.20) (87.20, 21.20)。
## 东、南两侧往里收 0.4 米，给胶囊半径 0.28 留余量，人就不会半个身子悬在面外。
## 北、西两侧则要对齐真实墙面：两道 StaticBody3D 只存在于坑内（y -5.05~-0.35），
## 内侧面分别在 z = 10.65 与 x = 87.45，再加半径 0.28 就是胶囊能站到的极限。
## clamp 和碰撞给出同一条线，人贴住墙时不会在两者之间来回被推。
## 北缘（z 下限）就是 PitWallNorth 的墙根：那面墙绝对走不上去，
## 所以「走到北缘」是一个明确的、贴着墙的物理边界，攀爬只在这条边上触发。
const B_PIT_WALK_MIN := Vector2(87.75, 10.95)
const B_PIT_WALK_MAX := Vector2(100.8, 20.8)
## 线垂到坑底的位置：贴着北缘墙根，横向对齐 B_CLIMB_OUT，也就是母亲的正下方。
const B_ROPE_FOOT := Vector3(96.2, B_PIT_FLOOR_Y, B_PIT_WALK_MIN.y)
## 触发攀爬的两个条件：贴到北缘（z 已被 clamp 到下限），且横向站在线的下方。
const B_ROPE_FOOT_EDGE_BAND := 0.35
const B_ROPE_FOOT_X_BAND := 1.2

## Block C 与 B→C 连接段整体上移到与 Farside 同高，偏移量 (-4.909, -5.628)。
const C_ENTRY_MOTHER := Vector3(142.1, 0.0, 9.4)
const C_ENTRY_CHILD := Vector3(144.1, 0.0, 9.4)
const C_LAMP := Vector3(161.1, 0.0, 7.4)
const C_LOOKBACK := Vector3(175.1, 0.0, 8.4)
const C_GOAL := Vector3(183.1, 0.0, 8.4)
const C_CHILD_RELEASE := Vector3(163.1, 0.0, 8.4)

const STAGE_NAMES := [
	"自行车",
	"水坑与距离",
	"窄缝与角色切换",
	"断板与承重",
	"坑底与沿线爬回",
	"路灯与学校",
]
const CHAPTER_THREE_SCENE := "res://scenes/chapter3/chapter3.tscn"

@export var debug_skip_intro := false

@onready var generated_map: Node2D = $World/GeneratedMap
@onready var spatial_physics: Node3D = $World/SpatialPhysics
## 白盒地图现在由编辑器摆放，见 World/Blocks。删掉节点即从游戏中消失。
@onready var blocks: Node2D = $World/Blocks
@onready var player: PlayerController = $Characters/YoungMother
@onready var mother_normal_sprite: AnimatedSprite2D = $Characters/YoungMother/AnimatedSprite2D
@onready var mother_catch_pose: Sprite2D = $Characters/YoungMother/CatchPose
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

## 举起自行车时，车体挂在母亲头顶上方这么高（逻辑米）。
const BICYCLE_CARRY_HEIGHT := 1.95

## 停车区判定半径。白线框是 2.8 x 2.6 米，取内切半径，
## 保证「过关」和「看得见的白线」是同一个范围。
const BICYCLE_PARK_RADIUS := 1.3

var _transition_busy := false
var _carrying_bicycle := false
var _bicycle_grounded_position := Vector2.ZERO
var _awaiting_switch_tab := false
## 等待 Tab 时，记录这次切换成功后该调用哪个收尾函数（窄缝 / 路灯两处）。
var _pending_switch_confirm := &""
var _puddle_progress := 0.0
var _puddle_announcement_played := false
var _puddle_far_dialogue_played := false
var _board_warned := false
## CLIMB 阶段的前半段：人在坑底那张横面上自由走，还没搭上线。
var _pit_walking := false
var _lamp_anchored := false
var _lookback_playing := false
## 被操纵的那个角色周身挂一层淡红微光，Tab 切换时立刻看得出操作权在谁身上。
const CONTROL_GLOW_COLOR := Color(1.0, 0.26, 0.22)
var _mother_glow: Sprite2D
var _child_glow: Sprite2D
var _glow_pulse := 0.0
var _bicycle_visual: Node2D
var _plank_intact: Node2D
var _plank_broken: Node2D
var _pit_fall_debris: Node2D
var _upper_anchor_visual: Node2D


func _ready() -> void:
	get_node("/root/GameSession").enter_chapter(2)
	_bind_block_nodes()
	_build_control_glows()
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
		_set_objective("靠近倒下的自行车，按空格把它举过头顶。")
	else:
		call_deferred("_run_intro")


func _process(delta: float) -> void:
	# 两个提示牌现在有纹理底，空文案必须整块隐藏，否则会留一块空面板在画面上。
	hint_label.visible = not hint_label.text.is_empty()
	objective_label.visible = not objective_label.text.is_empty()
	_update_control_glows(delta)
	if _carrying_bicycle:
		_update_carried_bicycle()
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
	if current_stage == Stage.COMPLETE:
		if event.is_action_pressed(&"start_game"):
			get_viewport().set_input_as_handled()
			_start_chapter_three()
		return
	if _transition_busy or dialogue_ui.is_playing():
		return

	# 窄缝关：先学会按 Tab 切换角色，才能接管女儿。
	if _awaiting_switch_tab and event.is_action_pressed(&"switch_character"):
		get_viewport().set_input_as_handled()
		var confirm_method := _pending_switch_confirm
		if confirm_method != &"" and has_method(confirm_method):
			call(confirm_method)
		else:
			_confirm_switch_tab()
		return

	if not event.is_action_pressed(&"interact"):
		return
	match current_stage:
		Stage.BICYCLE:
			if not _is_space_key(event):
				return
			if _carrying_bicycle:
				get_viewport().set_input_as_handled()
				_drop_bicycle()
			elif _bicycle_visual != null and _ground_distance(player.get_logical_position(), _bicycle_ground_position()) <= 3.0:
				get_viewport().set_input_as_handled()
				_lift_bicycle()
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
	_set_objective("小余念搬不动自行车。控制年轻余秀兰靠近，按空格把它举起来。")
	hint_label.text = "↑ ↓ ← → 移动    空格举起 / 放下自行车"


func _is_space_key(event: InputEvent) -> bool:
	var key_event := event as InputEventKey
	return key_event != null and (
		key_event.physical_keycode == KEY_SPACE or key_event.keycode == KEY_SPACE
	)


## 自行车当前落地点的逻辑坐标（由屏幕坐标反投影得到，编辑器挪动车体也能跟上）。
func _bicycle_ground_position() -> Vector3:
	if _bicycle_visual == null:
		return A_BICYCLE
	return Projection25D.unproject_ground(_bicycle_visual.global_position)


func _lift_bicycle() -> void:
	if _carrying_bicycle or _bicycle_visual == null:
		return
	_carrying_bicycle = true
	_bicycle_grounded_position = _bicycle_visual.global_position
	_update_carried_bicycle()
	_set_objective("自行车举过头顶了。用 ↑ ↓ ← → 把它搬到地上的白线停车区，再按空格放下。")
	hint_label.text = "举着自行车：↑ ↓ ← → 移动    空格放下"


func _update_carried_bicycle() -> void:
	if _bicycle_visual == null:
		return
	var carried := player.get_logical_position() + Vector3.UP * BICYCLE_CARRY_HEIGHT
	_bicycle_visual.global_position = Projection25D.project(carried)
	# 头顶的车体必须压在母亲精灵前面，所以在她的 z_index 之上再加一层。
	_bicycle_visual.z_index = Projection25D.depth_index(player.get_logical_position()) + 6


func _drop_bicycle() -> void:
	if not _carrying_bicycle:
		return
	_carrying_bicycle = false
	var drop_ground := player.get_logical_position()
	drop_ground.y = 0.0
	_bicycle_visual.global_position = Projection25D.project(drop_ground)
	_bicycle_visual.z_index = Projection25D.depth_index(drop_ground) + 1
	# 必须放进地面白线框出的停车区才算过关。判定半径对齐 A_BicycleParkingSlot
	# 的尺寸（逻辑 x 5.7~8.5 / z 8.0~10.6，中心正好是 A_BICYCLE_PARK）。
	if _ground_distance(drop_ground, A_BICYCLE_PARK) <= BICYCLE_PARK_RADIUS:
		_complete_bicycle()
	else:
		_set_objective("自行车还挡在路上。再按空格举起来，把它放进地上的白线停车区。")
		hint_label.text = "靠近自行车按空格举起    举着时空格放下"


func _complete_bicycle() -> void:
	if current_stage != Stage.BICYCLE or bool(flags["A_BICYCLE_DONE"]):
		return
	_transition_busy = true
	_carrying_bicycle = false
	game_flow.set_mode(GameFlow.Mode.CUTSCENE)
	if _bicycle_visual != null:
		var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(_bicycle_visual, "global_position", Projection25D.project(A_BICYCLE_PARK), 0.55)
		await tween.finished
		_bicycle_visual.z_index = Projection25D.depth_index(A_BICYCLE_PARK) + 1
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
	# 窄缝只有孩子能钻过去。玩家必须先自己按下 Tab，才拿到女儿的操作权。
	_transition_busy = false
	if debug_skip_intro:
		_confirm_switch_tab()
		return
	_awaiting_switch_tab = true
	_pending_switch_confirm = &"_confirm_switch_tab"
	game_flow.set_mode(GameFlow.Mode.CUTSCENE)
	_set_objective("成年人过不去这道窄缝。按 Tab 键切换到七岁余念。")
	hint_label.text = "按 Tab 切换角色"


func _confirm_switch_tab() -> void:
	_awaiting_switch_tab = false
	_pending_switch_confirm = &""
	child.set_control_enabled(true)
	game_flow.set_mode(GameFlow.Mode.EXPLORE)
	_set_objective("已切换到七岁余念。穿过窄缝，沿临时木板向右前进。")
	hint_label.text = "当前角色：七岁余念    Tab 切换角色    D / → 向前"


func _board_warning() -> void:
	_transition_busy = true
	child.set_control_enabled(false)
	if _plank_intact != null:
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
	# 木板断裂到落到坑底之间是腾空的，换成弹跳特写；_begin_pit_walk 里落地后收回。
	child.set_pose(&"bounce")
	game_flow.set_mode(GameFlow.Mode.CUTSCENE)
	if _plank_intact != null:
		_plank_intact.hide()
	if _plank_broken != null:
		_plank_broken.show()
	_set_objective("木板断裂——牵挂线即将第一次承担身体重量。")
	hint_label.text = ""

	# 构图：母亲出现在线的另一端，站在坑沿的平台边缘上，人在画面里托住这根线。
	player.show()
	player.set_logical_position(B_MOTHER_PIT_EDGE)
	_set_mother_control(false)
	_set_mother_catch_pose(true)
	if _upper_anchor_visual != null:
		_upper_anchor_visual.hide()
	tie_line.bind(player, child)
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
	_set_objective("线已经托住余念。母亲站在坑沿的平台边上稳住这根线，出口就在她脚下。")
	await _play_dialogue("D024")

	# 第一段：先落到坑底那张横面上自己走。直接上线太生硬，空间关系也讲不清；
	# 让人在坑里走一段，才能看出坑有多深、出口在哪一侧。
	_begin_pit_walk()


## CLIMB 前半段：坑底自由行走。把可行走面换成 y = -4.8 的坑底，
## 并把活动范围收进实测的 PitBottom 面内。
func _begin_pit_walk() -> void:
	_pit_walking = true
	if _pit_fall_debris != null:
		_pit_fall_debris.show()
	var landing := child.get_logical_position()
	landing.x = clampf(landing.x, B_PIT_WALK_MIN.x, B_PIT_WALK_MAX.x)
	landing.z = clampf(landing.z, B_PIT_WALK_MIN.y, B_PIT_WALK_MAX.y)
	child.set_logical_position(landing)
	child.set_ground_bounds(B_PIT_WALK_MIN, B_PIT_WALK_MAX)
	child.set_floor_height(B_PIT_FLOOR_Y)
	# 已经站到坑底了，收回弹跳特写，回到正常四向贴图。
	child.set_pose(&"")
	child.set_control_enabled(true)
	_transition_busy = false
	_set_objective("坑底比想象的深。沿坑底走到北面那道墙下，线就垂在母亲脚下。")
	hint_label.text = "WASD  在坑底移动    墙根是走不上去的    走到线垂下来的墙根才能开始攀"


## CLIMB 后半段：站到线脚下，改成沿线攀爬。
func _begin_rope_climb() -> void:
	_pit_walking = false
	# 这里不能改 floor_height：它会把角色的 y 直接贴到 0，人会瞬间从坑底跳到坑口。
	# 攀爬分支本身绕过了 y 的 clamp，所以留着 -4.8 是安全的，
	# 等 _finish_climb 真的站上平台了再复位。
	child.begin_climb(B_CLIMB_OUT)
	_set_objective("线绷紧了。按住 W / ↑ 让母亲把你拉上坑沿的平台。")
	hint_label.text = "按住 W / ↑ 攀爬    松开会停住    出口在坑的另一侧"


func _process_climb() -> void:
	if _transition_busy:
		return
	if _pit_walking:
		if _is_at_rope_foot():
			_begin_rope_climb()
		return
	if not child.is_climbing():
		return
	if child.has_reached_climb_target():
		_finish_climb()


## 攀爬的触发条件是两个几何条件同时成立，不是一个圆形范围：
## 1. z 已经被 clamp 压到坑底北缘 —— 也就是人真的贴上了 PitWallNorth 的墙根。
##    那面墙是绝对走不上去的，所以这是一条硬边界，不是靠近就算。
## 2. x 落在线的正下方那一小段。走到墙根别的地方只会被墙挡住，什么都不会发生。
func _is_at_rope_foot() -> bool:
	var position := child.get_logical_position()
	var at_north_edge := position.z <= B_PIT_WALK_MIN.y + B_ROPE_FOOT_EDGE_BAND
	var under_rope := absf(position.x - B_ROPE_FOOT.x) <= B_ROPE_FOOT_X_BAND
	return at_north_edge and under_rope


func _finish_climb() -> void:
	_transition_busy = true
	_pit_walking = false
	child.end_climb()
	# 回到地面高度，并把坑底那套收紧的活动范围放开，
	# 否则站上 Farside 之后每帧都会被 clamp 拽回坑口。
	child.set_floor_height(0.0)
	child.set_ground_bounds(Vector2(85.8, 1.8), Vector2(99.1, 10.2))
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
	_set_mother_catch_pose(false)
	flags["B_CHILD_SAFE"] = true
	checkpoint_id = "CP-B1"
	await _play_dialogue("D052")
	await _play_dialogue("D053")
	await _enter_block_c()


func _enter_block_c() -> void:
	_set_mother_catch_pose(false)
	transition_overlay.show()
	transition_text.text = "穿过老街\n学校就在前面"
	transition_overlay.modulate.a = 0.0
	var fade_out := create_tween()
	fade_out.tween_property(transition_overlay, "modulate:a", 1.0, 0.28)
	await fade_out.finished

	player.show()
	player.set_logical_position(C_ENTRY_MOTHER)
	player.movement_min = Vector2(139.5, 0.4)
	player.movement_max = Vector2(C_LAMP.x, 20.0)
	child.set_logical_position(C_ENTRY_CHILD)
	child.set_control_enabled(false)
	if _upper_anchor_visual != null:
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
		var previous := child.get_logical_position()
		var follow_target := previous
		follow_target.x = move_toward(follow_target.x, minf(player.get_logical_position().x + 2.2, C_CHILD_RELEASE.x), 4.5 * delta)
		follow_target.z = move_toward(follow_target.z, player.get_logical_position().z, 3.2 * delta)
		child.set_logical_position(follow_target)
		# 跟着母亲走时要有行走动画；真的追上了才切回站立。
		var step := follow_target - previous
		child.set_moving(not step.is_zero_approx())
		if not step.is_zero_approx():
			child.face_screen_direction(Projection25D.project_direction(step).x)
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
	child.set_logical_position(C_CHILD_RELEASE)
	child.set_ground_bounds(Vector2(C_CHILD_RELEASE.x, 6.4), Vector2(C_GOAL.x + 0.2, 10.4))
	# 跟随段刚把她设成 walk，这里停下等 Tab，得显式切回站立。
	child.set_moving(false)
	child.set_umbrella_raised(true)
	camera_rig.follow(child, Vector2.ONE, true)
	# 母亲锚在路灯下，去学校这段路要玩家再按一次 Tab 才交给女儿。
	_transition_busy = false
	if debug_skip_intro:
		_confirm_lamp_switch_tab()
		return
	_awaiting_switch_tab = true
	_pending_switch_confirm = &"_confirm_lamp_switch_tab"
	game_flow.set_mode(GameFlow.Mode.CUTSCENE)
	_set_objective("母亲停在路灯下，不会再往前。按 Tab 切换到小余念，让她自己走向学校。")
	hint_label.text = "按 Tab 切换角色"


func _confirm_lamp_switch_tab() -> void:
	_awaiting_switch_tab = false
	_pending_switch_confirm = &""
	child.set_control_enabled(true)
	game_flow.set_mode(GameFlow.Mode.EXPLORE)
	_set_objective("母亲已经停下。控制小余念独自走向学校；母亲不会继续追。")
	hint_label.text = "当前角色：七岁余念    Tab 切换角色    D / → 前往学校"


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
	get_node("/root/GameSession").complete_chapter(2)
	checkpoint_id = "CH2_COMPLETE"
	current_stage = Stage.COMPLETE
	progress_label.text = "教学完成 6 / 6"
	_set_objective("第二章完成：牵挂不只是拉住，也可以守护。")
	hint_label.text = ""
	transition_overlay.show()
	transition_overlay.modulate.a = 0.0
	transition_text.text = "牵挂，不只是拉住，\n也可以守护。\n\n按 Enter / Space 继续第三章"
	var ending := create_tween()
	ending.tween_interval(0.65)
	ending.tween_property(transition_overlay, "modulate:a", 0.92, 1.1)
	await ending.finished
	_transition_busy = false


func _start_chapter_three() -> void:
	if _transition_busy or current_stage != Stage.COMPLETE:
		return
	_transition_busy = true
	get_node("/root/GameSession").enter_chapter(3)
	get_tree().change_scene_to_file(CHAPTER_THREE_SCENE)


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


## 给两个角色各挂一个红色柔光贴图。挂在角色节点下，投影/翻转/z_index 全都自动跟随，
## 不必在 _process 里同步位置。z_index = -1 让光落在贴图后面，人不会被糊住。
func _build_control_glows() -> void:
	_mother_glow = _make_control_glow(player, Vector2(0.0, -52.0), 1.0)
	_child_glow = _make_control_glow(child, Vector2(0.0, -44.0), 0.78)


func _make_control_glow(host: Node2D, offset: Vector2, scale_factor: float) -> Sprite2D:
	if not is_instance_valid(host):
		return null
	var glow := Sprite2D.new()
	glow.name = "ControlGlow"
	glow.texture = _control_glow_texture()
	glow.position = offset
	glow.scale = Vector2.ONE * scale_factor
	glow.z_index = -1
	glow.self_modulate = Color(CONTROL_GLOW_COLOR, 0.0)
	# 叠加混合让它读起来是"发光"而不是"糊了一层红漆"。
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = additive
	host.add_child(glow)
	return glow


## 中心亮、边缘透明的圆形渐变。半径够大能兜住整个角色贴图。
func _control_glow_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.85),
		Color(1.0, 1.0, 1.0, 0.3),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 160
	texture.height = 160
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


## 谁拿着操作权，谁亮。母亲的判据是 _set_mother_control 开关的 _physics_process，
## 女儿的判据是 set_control_enabled，和现有流程用的是同一个开关，不会各说一套。
func _update_control_glows(delta: float) -> void:
	_glow_pulse = fmod(_glow_pulse + delta * 2.1, TAU)
	# 呼吸幅度压得很小：这是身份标记，不是特效。
	var breath := 0.3 + 0.07 * sin(_glow_pulse)
	var mother_active := player.is_physics_processing()
	var child_active := child.is_control_enabled()
	_fade_glow(_mother_glow, breath if mother_active else 0.0, delta)
	_fade_glow(_child_glow, breath if child_active else 0.0, delta)


func _fade_glow(glow: Sprite2D, target_alpha: float, delta: float) -> void:
	if not is_instance_valid(glow):
		return
	var current := glow.self_modulate.a
	glow.self_modulate = Color(
		CONTROL_GLOW_COLOR,
		move_toward(current, target_alpha, delta * 1.6)
	)


func _set_mother_control(enabled: bool) -> void:
	player.set_physics_process(enabled)
	player.set_process_unhandled_input(enabled)
	if not enabled:
		# 关掉 _physics_process 后她不会再自己切回 idle，
		# 所以这里显式停住，否则会僵在最后一帧 walk 动画上原地踏步。
		player.stop_and_idle()


func _set_mother_catch_pose(enabled: bool) -> void:
	mother_normal_sprite.visible = not enabled
	mother_catch_pose.visible = enabled


func _update_stage_ui() -> void:
	if current_stage >= Stage.BICYCLE and current_stage <= Stage.LAMP_SCHOOL:
		progress_label.text = "教学 %d / 6 · %s" % [current_stage + 1, STAGE_NAMES[current_stage]]


## 目标牌的文案约定：第一行是带进度的标题，换行之后才是描述。
## 各处调用只传描述，标题按当前教学关自动补，省得 18 处都写一遍。
func _set_objective(text: String) -> void:
	if text.is_empty():
		objective_label.text = ""
		return
	if current_stage >= Stage.BICYCLE and current_stage <= Stage.LAMP_SCHOOL:
		objective_label.text = "%s（%d/6）\n%s" % [
			STAGE_NAMES[current_stage],
			current_stage + 1,
			text,
		]
	else:
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


## 流程需要操作的白盒节点。键是变量名，值是在 World/Blocks 下的相对路径。
## 在编辑器里删掉其中任何一个都不会报错，只是对应演出被跳过。
const FLOW_NODES := {
	"_bicycle_visual": "BlockA/Visuals/BicyclePlaceholder",
	"_plank_intact": "BlockB/Visuals/BreakablePlank",
	"_plank_broken": "BlockB/Visuals/BrokenPlank",
	"_pit_fall_debris": "BlockB/Visuals/PitFallDebris",
	"_upper_anchor_visual": "BlockB/Visuals/UpperStableEndpoint",
}


func _bind_block_nodes() -> void:
	for property_name in FLOW_NODES:
		var node_path := str(FLOW_NODES[property_name])
		var node := blocks.get_node_or_null(node_path) as Node2D
		set(property_name, node)
		if node == null:
			push_warning("[CH2] 白盒节点已被删除，相关演出跳过：%s" % node_path)

	if _plank_broken != null:
		_plank_broken.hide()
	if _pit_fall_debris != null:
		_pit_fall_debris.hide()
	if _upper_anchor_visual != null:
		_upper_anchor_visual.hide()
