extends Node2D

enum Phase {
	PROLOGUE,
	ACT1_EXPLORE,
	ACT1_CONFLICT,
	ACT1_WALK,
	ACT1_TIE,
	ACT1_PULLBACK,
	ACT1_SUSPENDED,
	ACT1_UMBRELLA,
	TRANSITION,
	ACT2_BICYCLE,
	ACT2_PUDDLE,
	ACT2_CABINET_CHILD,
	ACT2_CABINET_MOTHER,
	ACT2_ANCHOR,
	ACT2_FALL,
	ACT2_CLIMB,
	ACT2_FAREWELL,
	ACT3_ATTACH,
	ACT3_CORRIDOR_1,
	ACT3_CORRIDOR_2,
	ACT3_WAREHOUSE_BOX_1,
	ACT3_WAREHOUSE_CRAWL,
	ACT3_WAREHOUSE_BOX_2,
	ACT3_ROOFTOP,
	ACT4_MOVE_IN,
	ACT4_CONFLICT,
	ACT4_SILENCE,
	ACT4_RELAXED,
	ACT4_EPILOGUE,
	COMPLETE,
}

const CORE_ITEMS := ["box", "suitcase", "desk"]
const FRAGMENT_IDS := [
	"fragment_ticket",
	"fragment_height",
	"fragment_boots",
	"fragment_frame",
	"fragment_earphones",
]
const ECHO_IDS := ["echo_kitchen", "echo_door", "echo_hall"]
const CORE_DIALOGUE_IDS := {
	"box": "D001",
	"suitcase": "D002",
	"desk": "D003",
}
const FRAGMENT_DIALOGUE_IDS := {
	"fragment_ticket": "M001",
	"fragment_height": "M002",
	"fragment_boots": "M003",
	"fragment_frame": "M004",
	"fragment_earphones": "M005",
}
const ECHO_DIALOGUE_IDS := {
	"echo_kitchen": "E001",
	"echo_door": "E002",
	"echo_hall": "E003",
}

@export var test_mode := false

@onready var world: FullDemoWorld = %GrayboxWorld
@onready var player: EchoesPlayer = %Player
@onready var companion: EchoesMother = %Mother
@onready var tie_line: TieLine = %TieLine
@onready var umbrella: MemoryUmbrella = %Umbrella
@onready var ui: PrototypeUI = %PrototypeUI
@onready var audio_director: AudioDirector = %AudioDirector

var phase := Phase.PROLOGUE
var current_interaction := ""
var core_items_found := 0
var fragments_found := 0
var echoes_found := 0
var chair_climbed := false
var relationship_state := "Hidden"
var dialogue_catalog: DialogueCatalog

var _phase_guard := false
var _act1_elapsed := 0.0
var _suspension_elapsed := 0.0
var _suspension_origin_x := 0.0
var _suspension_input_seen := false
var _act2_climb_elapsed := 0.0
var _act4_elapsed := 0.0
var _silence_start_position := Vector2.ZERO
var _echo_hold_id := ""
var _echo_hold_time := 0.0
var _coop_step := 0


func _enter_tree() -> void:
	dialogue_catalog = DialogueCatalog.new()
	_ensure_input_actions()


func _ready() -> void:
	ui.duration_scale = 0.02 if test_mode else 1.0
	player.interaction_requested.connect(_on_interaction_requested)
	tie_line.revealed.connect(_on_tie_revealed)
	tie_line.maximum_tension_reached.connect(_on_maximum_tension_reached)
	umbrella.inspected.connect(_on_umbrella_inspected)
	ui.checkpoint_shown.connect(_on_checkpoint_shown)
	ui.chapter_shown.connect(_on_chapter_shown)
	ui.mute_changed.connect(_on_mute_changed)
	ui.reduced_motion_changed.connect(_on_reduced_motion_changed)
	audio_director.set_muted(ui.sound_muted)
	_on_reduced_motion_changed(ui.reduced_motion)
	_start_prologue()


func _physics_process(delta: float) -> void:
	audio_director.set_tension(tie_line.tension_value if tie_line.state == TieLine.TieState.TENSE else 0.0)
	_update_debug_ui()
	_update_interaction_prompt()
	_apply_stage_constraints()

	match phase:
		Phase.ACT1_EXPLORE:
			_act1_elapsed += delta
			_update_echo_points(delta)
			if _act1_elapsed >= 30.0 and not _phase_guard:
				_begin_umbrella_conflict()
		Phase.ACT1_WALK, Phase.ACT1_UMBRELLA:
			_update_echo_points(delta)
		Phase.ACT1_TIE:
			_update_echo_points(delta)
			player.movement_multiplier = maxf(0.12, 1.0 - pow(tie_line.tension_value, 2.0))
		Phase.ACT1_SUSPENDED:
			_update_act_one_suspension(delta)
		Phase.ACT2_BICYCLE:
			_update_bicycle_push(delta)
		Phase.ACT2_PUDDLE:
			_update_puddle_lesson()
		Phase.ACT2_CABINET_CHILD:
			_update_memory_cabinet()
		Phase.ACT2_CABINET_MOTHER:
			if player.role_name in ["母亲", "年轻母亲"] and player.global_position.x > 1325.0:
				_setup_memory_anchor()
		Phase.ACT2_ANCHOR:
			_update_memory_anchor_crossing()
		Phase.ACT2_CLIMB:
			_update_memory_climb(delta)
		Phase.ACT3_CORRIDOR_1, Phase.ACT3_CORRIDOR_2:
			_update_corridor_crossing()
		Phase.ACT3_WAREHOUSE_BOX_1:
			_update_warehouse_box_one(delta)
		Phase.ACT3_WAREHOUSE_CRAWL:
			_update_warehouse_crawl()
		Phase.ACT3_WAREHOUSE_BOX_2:
			_update_warehouse_box_two(delta)
		Phase.ACT3_ROOFTOP:
			_update_rooftop_crossing()
		Phase.ACT4_MOVE_IN:
			_update_apartment_box(delta)
		Phase.ACT4_SILENCE:
			_update_silent_apartment(delta)
		Phase.ACT4_RELAXED:
			if player.global_position.x >= 1280.0:
				_enter_epilogue()
		_:
			pass

	if phase not in [Phase.ACT1_TIE, Phase.ACT1_SUSPENDED]:
		player.movement_multiplier = 1.0

	_update_memory_tie_control()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"restart"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed(&"toggle_debug"):
		ui.toggle_debug()
	elif event.is_action_pressed(&"toggle_help"):
		ui.toggle_controls_hint()
	elif event.is_action_pressed(&"switch_character"):
		_try_switch_character()


func _start_prologue() -> void:
	phase = Phase.PROLOGUE
	world.set_layout(FullDemoWorld.Layout.PROLOGUE)
	world.set_stage(0)
	audio_director.set_mood("prologue")
	player.controls_enabled = false
	player.visible = false
	companion.visible = false
	umbrella.visible = false
	umbrella.set_process(false)
	tie_line.auto_reveal_enabled = false
	tie_line.reset_line(TieLine.TieState.HIDDEN)
	ui.hide_completion()
	ui.set_hud_visible(false)
	await get_tree().create_timer(_scaled(2.2)).timeout
	world.set_stage(1)
	await get_tree().create_timer(_scaled(2.6)).timeout
	await ui.show_chapter("第一幕", "离家")
	_start_act_one()


func _start_act_one() -> void:
	phase = Phase.ACT1_EXPLORE
	world.set_layout(FullDemoWorld.Layout.HOME)
	audio_director.set_mood("home")
	player.set_role("成年女儿")
	player.set_world_bounds(Rect2(96.0, 258.0, 1350.0, 350.0))
	player.global_position = Vector2(420.0, 470.0)
	player.visible = true
	player.controls_enabled = true
	companion.set_role("母亲")
	companion.global_position = Vector2(110.0, 470.0)
	companion.visible = false
	umbrella.visible = false
	umbrella.set_process(false)
	tie_line.auto_reveal_enabled = false
	tie_line.reset_line(TieLine.TieState.HIDDEN)
	ui.hide_completion()
	ui.set_hud_visible(true)
	ui.set_phase("第一幕 · 离家")
	ui.set_objective("调查纸箱、行李箱和书桌（0/3）")
	ui.set_role(player.role_name)
	ui.set_collection(0, 0)
	ui.set_debug_visible(false)
	ui.show_controls_hint()
	_say("D004")


func _update_interaction_prompt() -> void:
	current_interaction = _find_nearby_interaction()
	world.set_highlight(current_interaction)
	var prompt := ""
	match current_interaction:
		"box", "suitcase", "desk":
			prompt = "E  调查物件"
		"chair":
			prompt = "E  站上木椅"
		"fragment_frame", "fragment_earphones", "fragment_ticket", "fragment_height", "fragment_boots":
			prompt = "E  收集记忆碎片"
		"umbrella":
			prompt = "E  触碰黄色雨伞" if phase == Phase.ACT1_UMBRELLA else "E  把牵挂线挂在雨伞上"
		"memory_lamp", "corridor_anchor_1", "corridor_anchor_2", "rooftop_anchor_1", "rooftop_anchor_2", "rooftop_anchor_3":
			prompt = "E  将牵挂线绕过锚点"
	ui.set_interaction_prompt(prompt, not prompt.is_empty())


func _find_nearby_interaction() -> String:
	if not player.controls_enabled:
		return ""
	# Memory transitions and critical anchors always outrank optional exploration.
	if phase in [Phase.ACT1_UMBRELLA, Phase.ACT3_ATTACH] and umbrella.can_interact():
		return "umbrella"

	if world.layout == FullDemoWorld.Layout.HOME:
		if not chair_climbed and player.global_position.distance_to(world.get_point("chair")) <= 75.0:
			return "chair"
		for core_id in CORE_ITEMS:
			if not world.is_collected(core_id) and player.global_position.distance_to(world.get_point(core_id)) <= 92.0:
				return core_id
		for fragment_id in FRAGMENT_IDS:
			if world.is_collected(fragment_id):
				continue
			if fragment_id == "fragment_frame" and not chair_climbed:
				continue
			if player.global_position.distance_to(world.get_point(fragment_id)) <= 82.0:
				return fragment_id

	if phase == Phase.ACT2_ANCHOR and world.anchor_index == 0 and _near_point("memory_lamp", 105.0):
		return "memory_lamp"
	if phase == Phase.ACT3_CORRIDOR_1 and world.anchor_index == 0 and _near_point("corridor_anchor_1", 100.0):
		return "corridor_anchor_1"
	if phase == Phase.ACT3_CORRIDOR_2 and world.anchor_index == 1 and _near_point("corridor_anchor_2", 100.0):
		return "corridor_anchor_2"
	if phase == Phase.ACT3_ROOFTOP:
		var anchor_id := "rooftop_anchor_%d" % (_coop_step + 1)
		if _coop_step < 3 and world.anchor_index == _coop_step and _near_point(anchor_id, 105.0):
			return anchor_id
	return ""


func _on_interaction_requested() -> void:
	match current_interaction:
		"box", "suitcase", "desk":
			_inspect_core_item(current_interaction)
		"chair":
			_climb_chair()
		"fragment_frame", "fragment_earphones", "fragment_ticket", "fragment_height", "fragment_boots":
			_collect_fragment(current_interaction)
		"umbrella":
			umbrella.try_inspect()
		"memory_lamp":
			_anchor_memory_lamp()
		"corridor_anchor_1":
			_anchor_corridor_one()
		"corridor_anchor_2":
			_anchor_corridor_two()
		"rooftop_anchor_1", "rooftop_anchor_2", "rooftop_anchor_3":
			_anchor_rooftop(current_interaction)


func _inspect_core_item(item_id: String) -> void:
	if world.is_collected(item_id):
		return
	world.mark_collected(item_id)
	core_items_found += 1
	ui.set_objective("调查纸箱、行李箱和书桌（%d/3）" % core_items_found)
	_say(CORE_DIALOGUE_IDS[item_id])
	if core_items_found >= 3 and not _phase_guard:
		_begin_umbrella_conflict()


func _climb_chair() -> void:
	chair_climbed = true
	ui.show_checkpoint("✓ 站上木椅：现在能够到柜顶了")
	_say("C001")


func _collect_fragment(fragment_id: String) -> void:
	if world.is_collected(fragment_id):
		return
	world.mark_collected(fragment_id)
	fragments_found += 1
	ui.set_collection(fragments_found, echoes_found)
	ui.show_checkpoint("记忆碎片 %d/5" % fragments_found)
	audio_director.play_cue("fragment")
	_say(FRAGMENT_DIALOGUE_IDS[fragment_id])


func _update_echo_points(delta: float) -> void:
	if not player.controls_enabled or player.velocity.length() > 6.0:
		_echo_hold_id = ""
		_echo_hold_time = 0.0
		return
	var nearby_echo := ""
	for echo_id in ECHO_IDS:
		if world.is_collected(echo_id):
			continue
		if player.global_position.distance_to(world.get_point(echo_id)) <= 48.0:
			nearby_echo = echo_id
			break
	if nearby_echo.is_empty():
		_echo_hold_id = ""
		_echo_hold_time = 0.0
		return
	if _echo_hold_id != nearby_echo:
		_echo_hold_id = nearby_echo
		_echo_hold_time = 0.0
	_echo_hold_time += delta
	if _echo_hold_time >= 1.5:
		world.mark_collected(nearby_echo)
		echoes_found += 1
		ui.set_collection(fragments_found, echoes_found)
		_say(ECHO_DIALOGUE_IDS[nearby_echo])
		audio_director.play_cue("echo")
		_echo_hold_id = ""
		_echo_hold_time = 0.0


func _begin_umbrella_conflict() -> void:
	if _phase_guard or phase != Phase.ACT1_EXPLORE:
		return
	_phase_guard = true
	phase = Phase.ACT1_CONFLICT
	player.controls_enabled = false
	companion.visible = true
	companion.global_position = player.global_position + Vector2(115.0, 0.0)
	umbrella.visible = true
	umbrella.set_process(true)
	umbrella.global_position = Vector2(790.0, 488.0)
	ui.set_phase("雨伞冲突")
	ui.set_objective("听妈妈把话说完")
	await _say("D005")
	await _say("D006")
	await _say("D007")
	await _say("D008")
	await _say("D009")
	await _say("D010")
	await _say("D011")
	await _say("D012")
	await _say("D013")
	await _say("D014")
	companion.global_position = Vector2(320.0, 470.0)
	player.global_position = Vector2(520.0, 470.0)
	tie_line.max_distance = 520.0
	tie_line.auto_reveal_enabled = true
	tie_line.reset_line(TieLine.TieState.HIDDEN)
	phase = Phase.ACT1_WALK
	player.controls_enabled = true
	ui.set_phase("第一次牵挂")
	ui.set_objective("向门口走，试着离开家  →")
	_phase_guard = false


func _on_tie_revealed() -> void:
	if phase not in [Phase.ACT1_WALK, Phase.ACT1_TIE]:
		return
	phase = Phase.ACT1_TIE
	ui.set_objective("继续走，感受牵挂线的变化  →")
	audio_director.play_cue("reveal")
	_say("D016")


func _on_maximum_tension_reached() -> void:
	if phase != Phase.ACT1_TIE or _phase_guard:
		return
	_phase_guard = true
	phase = Phase.ACT1_PULLBACK
	player.controls_enabled = false
	audio_director.play_cue("tension")
	ui.set_phase("第一次分离")
	ui.set_objective("牵挂线已经绷紧")
	await _say("D015")
	tie_line.set_visual_tension(1.0)
	var lift := create_tween()
	lift.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	lift.tween_property(player, "global_position", player.global_position + Vector2(-70.0, -92.0), _scaled(0.42))
	await lift.finished
	phase = Phase.ACT1_SUSPENDED
	_suspension_elapsed = 0.0
	_suspension_origin_x = player.global_position.x
	_suspension_input_seen = false
	player.controls_enabled = true
	ui.set_phase("牵挂线承住了她")
	ui.set_objective("按 A / D 或 ← / →，感受线承重时的摆动")
	_say("D017")
	_phase_guard = false


func _update_act_one_suspension(delta: float) -> void:
	_suspension_elapsed += delta
	player.movement_multiplier = 0.42
	var horizontal_input := Input.get_axis(&"move_left", &"move_right")
	if absf(horizontal_input) > 0.1:
		_suspension_input_seen = true
	var horizontal_offset := clampf(player.global_position.x - _suspension_origin_x, -110.0, 110.0)
	player.global_position.x = _suspension_origin_x + horizontal_offset
	player.global_position.y = 378.0 + absf(horizontal_offset) * 0.16
	if (_suspension_input_seen and _suspension_elapsed >= 1.2) or _suspension_elapsed >= 7.0:
		_complete_act_one_suspension()


func _complete_act_one_suspension() -> void:
	if phase != Phase.ACT1_SUSPENDED or _phase_guard:
		return
	_phase_guard = true
	phase = Phase.ACT1_PULLBACK
	player.controls_enabled = false
	var settle := create_tween()
	settle.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	settle.tween_property(player, "global_position", umbrella.global_position + Vector2(66.0, 10.0), _scaled(0.7))
	await settle.finished
	tie_line.set_visual_tension(-1.0)
	phase = Phase.ACT1_UMBRELLA
	umbrella.set_interaction_enabled(true)
	player.controls_enabled = true
	ui.set_phase("记忆的入口")
	ui.set_objective("看看那把发光的黄色雨伞")
	_say("D018")
	_phase_guard = false


func _on_umbrella_inspected() -> void:
	if phase == Phase.ACT1_UMBRELLA:
		_enter_act_two()
	elif phase == Phase.ACT3_ATTACH:
		_attach_line_to_umbrella()


func _enter_act_two() -> void:
	if _phase_guard:
		return
	_phase_guard = true
	phase = Phase.TRANSITION
	player.controls_enabled = false
	audio_director.play_cue("transition")
	umbrella.set_interaction_enabled(false)
	await _say("A101")
	world.set_layout(FullDemoWorld.Layout.MEMORY_STREET)
	audio_director.set_mood("memory")
	umbrella.visible = false
	umbrella.set_process(false)
	player.set_role("年轻母亲")
	player.set_world_bounds(Rect2(96.0, 258.0, 1400.0, 350.0))
	player.global_position = Vector2(360.0, 500.0)
	companion.visible = true
	companion.set_role("小女儿")
	companion.global_position = Vector2(690.0, 500.0)
	tie_line.max_distance = 820.0
	tie_line.auto_reveal_enabled = false
	tie_line.reset_line(TieLine.TieState.ADJUSTABLE)
	ui.set_role(player.role_name)
	await ui.show_chapter("第二幕", "第一次放手")
	await _say("D019")
	phase = Phase.ACT2_BICYCLE
	world.set_stage(1)
	player.controls_enabled = true
	ui.set_phase("自行车 · 推重物教学")
	ui.set_objective("母亲靠近自行车，向上推到路边")
	_say("D020")
	_phase_guard = false


func _update_bicycle_push(_delta: float) -> void:
	var distance_to_bike := player.global_position.distance_to(world.bicycle_position)
	world.set_highlight("bicycle" if distance_to_bike < 100.0 else "")
	if player.role_name not in ["母亲", "年轻母亲"] or distance_to_bike > 105.0:
		return
	if Input.get_axis(&"move_down", &"move_up") > 0.1:
		world.bicycle_position.y = minf(world.bicycle_position.y, player.global_position.y - 38.0)
		if world.bicycle_position.y <= 350.0:
			_complete_bicycle()


func _complete_bicycle() -> void:
	if phase != Phase.ACT2_BICYCLE:
		return
	phase = Phase.ACT2_PUDDLE
	world.bicycle_position = Vector2(540.0, 335.0)
	world.set_stage(2)
	companion.global_position = Vector2(850.0, 500.0)
	tie_line.set_story_state(TieLine.TieState.TENSE)
	ui.show_checkpoint("✓ 自行车移到路边")
	_say("A201")
	ui.set_phase("水坑 · 张力教学")
	ui.set_objective("走近小女儿，让绷紧的线重新松弛")


func _update_puddle_lesson() -> void:
	var holding_tight := Input.is_action_pressed(&"tie_control")
	var actor_distance := player.global_position.distance_to(companion.global_position)
	if holding_tight or actor_distance >= 210.0:
		tie_line.set_story_state(TieLine.TieState.TENSE)
		tie_line.set_visual_tension(0.88)
		return
	tie_line.set_visual_tension(-1.0)
	tie_line.set_story_state(TieLine.TieState.ADJUSTABLE)
	_complete_puddle_lesson()


func _complete_puddle_lesson() -> void:
	if phase != Phase.ACT2_PUDDLE:
		return
	phase = Phase.TRANSITION
	player.controls_enabled = false
	await _say("D022")
	var tween := create_tween()
	tween.tween_property(companion, "global_position", Vector2(980.0, 500.0), _scaled(0.8))
	await tween.finished
	ui.show_checkpoint("✓ 松开不代表失去连接")
	await _say("A202")
	_setup_memory_cabinet()


func _setup_memory_cabinet() -> void:
	phase = Phase.ACT2_CABINET_CHILD
	world.set_stage(3)
	player.set_role("年轻母亲")
	player.global_position = Vector2(930.0, 500.0)
	companion.set_role("小女儿")
	companion.global_position = Vector2(985.0, 500.0)
	ui.set_role(player.role_name)
	ui.set_phase("快递柜缺口 · 角色切换")
	ui.set_objective("母亲过不去——按 Tab 切换到小女儿")
	player.controls_enabled = true


func _update_memory_cabinet() -> void:
	if player.role_name != "小女儿":
		return
	if player.global_position.x >= 1260.0:
		world.gate_one_open = true
		phase = Phase.ACT2_CABINET_MOTHER
		ui.show_checkpoint("✓ 小女儿踩下踏板，闸门打开")
		_say("D023")
		ui.set_objective("按 Tab 切回母亲，通过已经打开的闸门")


func _setup_memory_anchor() -> void:
	phase = Phase.ACT2_ANCHOR
	world.set_stage(4)
	world.anchor_index = 0
	player.set_role("年轻母亲")
	player.global_position = Vector2(970.0, 490.0)
	companion.set_role("小女儿")
	companion.global_position = Vector2(1040.0, 500.0)
	ui.set_role(player.role_name)
	ui.set_phase("路灯 · 锚点教学")
	ui.set_objective("靠近发光路灯，按 E 设置锚点")


func _anchor_memory_lamp() -> void:
	if phase != Phase.ACT2_ANCHOR or world.anchor_index != 0 or player.role_name not in ["母亲", "年轻母亲"]:
		return
	world.anchor_index = 1
	tie_line.set_story_state(TieLine.TieState.ADJUSTABLE)
	tie_line.add_anchor_point(world.get_point("memory_lamp"))
	ui.show_checkpoint("✓ 牵挂线绕过路灯")
	ui.set_objective("按 Tab 切换小女儿，再按 W / ↑ 借线越过断口")


func _update_memory_anchor_crossing() -> void:
	if world.anchor_index != 1 or player.role_name != "小女儿":
		return
	if Input.is_action_pressed(&"move_up"):
		_begin_memory_fall()


func _begin_memory_fall() -> void:
	if phase != Phase.ACT2_ANCHOR or _phase_guard:
		return
	_phase_guard = true
	phase = Phase.ACT2_FALL
	player.controls_enabled = false
	world.set_stage(5)
	ui.set_phase("只有孩子能走的路")
	ui.set_objective("脚下的木板突然松动")
	await _say("D021")
	var approach := create_tween()
	approach.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	approach.tween_property(player, "global_position", Vector2(1255.0, 460.0), _scaled(0.35))
	await approach.finished
	tie_line.set_story_state(TieLine.TieState.TENSE)
	tie_line.set_visual_tension(1.0)
	audio_director.play_cue("tension")
	var fall := create_tween()
	fall.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(player, "global_position", Vector2(1255.0, 578.0), _scaled(0.42))
	await fall.finished
	await _say("D024")
	phase = Phase.ACT2_CLIMB
	_act2_climb_elapsed = 0.0
	player.controls_enabled = true
	ui.set_phase("牵挂线承住了她")
	ui.set_objective("按住 W / ↑，让小女儿沿线自己爬回去")
	_phase_guard = false


func _update_memory_climb(delta: float) -> void:
	_act2_climb_elapsed += delta
	if player.global_position.y <= 465.0 or _act2_climb_elapsed >= 18.0:
		_complete_memory_climb()


func _complete_memory_climb() -> void:
	if phase != Phase.ACT2_CLIMB or _phase_guard:
		return
	_phase_guard = true
	phase = Phase.ACT2_FAREWELL
	player.controls_enabled = false
	tie_line.set_visual_tension(-1.0)
	tie_line.set_story_state(TieLine.TieState.ADJUSTABLE)
	var return_to_safety := create_tween()
	return_to_safety.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return_to_safety.tween_property(player, "global_position", Vector2(1380.0, 450.0), _scaled(0.75))
	await return_to_safety.finished
	ui.show_checkpoint("✓ 线提供支撑，小女儿自己回到了安全处")
	await _finish_act_two()
	_phase_guard = false


func _finish_act_two() -> void:
	ui.show_checkpoint("✓ 小女儿到达街道终点")
	await _say("A203")
	await _say("D025")
	await _say("A204")
	_enter_act_three_attach()


func _enter_act_three_attach() -> void:
	phase = Phase.TRANSITION
	world.set_layout(FullDemoWorld.Layout.HOME)
	audio_director.set_mood("home")
	player.set_role("成年女儿")
	player.global_position = Vector2(850.0, 490.0)
	companion.set_role("母亲")
	companion.global_position = Vector2(270.0, 470.0)
	companion.visible = true
	umbrella.visible = true
	umbrella.set_process(true)
	umbrella.global_position = Vector2(790.0, 488.0)
	umbrella.set_interaction_enabled(true)
	tie_line.clear_anchor_points()
	tie_line.reset_line(TieLine.TieState.ADJUSTABLE)
	ui.set_role(player.role_name)
	await ui.show_chapter("第三幕", "一起走一段")
	await _say("D026")
	await _say("D027")
	phase = Phase.ACT3_ATTACH
	player.controls_enabled = true
	ui.set_phase("回到现实 · 安放牵挂")
	ui.set_objective("把牵挂线挂在黄色雨伞上")


func _attach_line_to_umbrella() -> void:
	if phase != Phase.ACT3_ATTACH:
		return
	phase = Phase.TRANSITION
	player.controls_enabled = false
	umbrella.set_interaction_enabled(false)
	tie_line.add_anchor_point(umbrella.global_position)
	ui.show_checkpoint("✓ 线固定在伞上，不再阻碍远行")
	await _say("A301")
	_setup_corridor()


func _setup_corridor() -> void:
	world.set_layout(FullDemoWorld.Layout.CORRIDOR)
	audio_director.set_mood("corridor")
	umbrella.visible = false
	umbrella.set_process(false)
	player.set_role("母亲")
	player.global_position = Vector2(450.0, 500.0)
	companion.set_role("成年女儿")
	companion.global_position = Vector2(350.0, 500.0)
	companion.visible = true
	tie_line.clear_anchor_points()
	tie_line.set_story_state(TieLine.TieState.ADJUSTABLE)
	phase = Phase.ACT3_CORRIDOR_1
	ui.set_role(player.role_name)
	ui.set_phase("楼道与出口 · 双人合作")
	ui.set_objective("母亲靠近第一个支点按 E 锚定")
	player.controls_enabled = true


func _anchor_corridor_one() -> void:
	if player.role_name != "母亲" or world.anchor_index != 0:
		return
	world.anchor_index = 1
	tie_line.add_anchor_point(world.get_point("corridor_anchor_1"))
	ui.show_checkpoint("✓ 母亲成为支点")
	_say("D028")
	ui.set_objective("Tab 切换成年女儿，按 W / ↑ 借线越过断口")


func _update_corridor_crossing() -> void:
	if phase == Phase.ACT3_CORRIDOR_1:
		if world.anchor_index == 1 and player.role_name == "成年女儿" and Input.is_action_pressed(&"move_up"):
			phase = Phase.TRANSITION
			player.controls_enabled = false
			var tween := create_tween()
			tween.tween_property(player, "global_position", world.get_point("corridor_plate_1"), _scaled(0.7))
			await tween.finished
			world.gate_one_open = true
			phase = Phase.ACT3_CORRIDOR_1
			player.controls_enabled = true
			ui.show_checkpoint("✓ 高台踏板打开第一扇门")
			ui.set_objective("Tab 切回母亲，穿过打开的门")
		elif world.gate_one_open and player.role_name == "母亲" and player.global_position.x > 940.0:
			_setup_corridor_second_gap()
	elif phase == Phase.ACT3_CORRIDOR_2:
		if world.anchor_index == 2 and player.role_name == "母亲" and Input.is_action_pressed(&"move_up"):
			phase = Phase.TRANSITION
			player.controls_enabled = false
			var tween := create_tween()
			tween.tween_property(player, "global_position", Vector2(1300.0, 470.0), _scaled(0.75))
			await tween.finished
			world.gate_two_open = true
			ui.show_checkpoint("✓ 两人共同打开楼道出口")
			await _say("D029")
			_setup_warehouse()


func _setup_corridor_second_gap() -> void:
	phase = Phase.ACT3_CORRIDOR_2
	player.set_role("母亲")
	player.global_position = Vector2(980.0, 490.0)
	companion.set_role("成年女儿")
	companion.global_position = Vector2(1085.0, 470.0)
	ui.set_role(player.role_name)
	ui.set_phase("楼道 · 交换支点")
	ui.set_objective("Tab 切换女儿，在第二支点按 E 锚定")


func _anchor_corridor_two() -> void:
	if player.role_name != "成年女儿" or world.anchor_index != 1:
		return
	world.anchor_index = 2
	tie_line.set_anchor_points([world.get_point("corridor_anchor_2")])
	ui.show_checkpoint("✓ 女儿成为母亲的支点")
	ui.set_objective("Tab 切回母亲，按 W / ↑ 借线越过断口")


func _setup_warehouse() -> void:
	world.set_layout(FullDemoWorld.Layout.WAREHOUSE)
	audio_director.set_mood("warehouse")
	player.set_role("母亲")
	player.global_position = Vector2(390.0, 500.0)
	companion.set_role("成年女儿")
	companion.global_position = Vector2(290.0, 500.0)
	tie_line.clear_anchor_points()
	phase = Phase.ACT3_WAREHOUSE_BOX_1
	ui.set_role(player.role_name)
	ui.set_phase("仓库 · 推箱与窄道")
	ui.set_objective("母亲把重箱 1 向上推到踏板")
	_say("D030")
	player.controls_enabled = true


func _update_warehouse_box_one(_delta: float) -> void:
	var near_box := player.global_position.distance_to(world.box_one_position) < 105.0
	world.set_highlight("warehouse_box_1" if near_box else "")
	if player.role_name != "母亲" or not near_box:
		return
	if Input.get_axis(&"move_down", &"move_up") > 0.1:
		world.box_one_position.y = minf(world.box_one_position.y, player.global_position.y - 42.0)
		if world.box_one_position.y <= 355.0:
			world.box_one_position = world.get_point("warehouse_plate_1")
			world.gate_one_open = true
			phase = Phase.ACT3_WAREHOUSE_CRAWL
			ui.show_checkpoint("✓ 重箱压住踏板，第一扇门打开")
			_say("D031")
			ui.set_objective("Tab 切换女儿，穿过前方窄道")


func _update_warehouse_crawl() -> void:
	if player.role_name != "成年女儿":
		return
	if player.global_position.x >= 985.0:
		world.gate_two_open = true
		phase = Phase.ACT3_WAREHOUSE_BOX_2
		ui.show_checkpoint("✓ 女儿穿过窄道，第二扇门打开")
		ui.set_objective("Tab 切回母亲，把重箱 2 向右推入断口")


func _update_warehouse_box_two(_delta: float) -> void:
	var near_box := player.global_position.distance_to(world.box_two_position) < 110.0
	world.set_highlight("warehouse_box_2" if near_box else "")
	if player.role_name != "母亲" or not near_box:
		return
	if Input.get_axis(&"move_left", &"move_right") > 0.1:
		world.box_two_position.x = maxf(world.box_two_position.x, player.global_position.x + 42.0)
		if world.box_two_position.x >= 1305.0:
			world.gap_filled = true
			phase = Phase.TRANSITION
			player.controls_enabled = false
			ui.show_checkpoint("✓ 箱子正好垫住断口")
			_setup_rooftop()


func _setup_rooftop() -> void:
	world.set_layout(FullDemoWorld.Layout.ROOFTOP)
	audio_director.set_mood("rooftop")
	player.set_role("母亲")
	player.global_position = Vector2(380.0, 500.0)
	companion.set_role("成年女儿")
	companion.global_position = Vector2(300.0, 520.0)
	tie_line.clear_anchor_points()
	_coop_step = 0
	phase = Phase.ACT3_ROOFTOP
	ui.set_role(player.role_name)
	ui.set_phase("天台 · 交替锚定接龙")
	ui.set_objective("母亲在第一个发光支点按 E 锚定")
	_say("D032")
	player.controls_enabled = true


func _anchor_rooftop(anchor_id: String) -> void:
	if phase != Phase.ACT3_ROOFTOP or _coop_step >= 3:
		return
	var required_role := "母亲" if _coop_step != 1 else "成年女儿"
	if player.role_name != required_role:
		ui.show_checkpoint("需要由%s在这里锚定" % required_role)
		return
	world.anchor_index = _coop_step + 1
	tie_line.set_anchor_points([world.get_point(anchor_id)])
	ui.show_checkpoint("✓ %s成为第 %d 个支点" % [required_role, _coop_step + 1])
	var crossing_role := "成年女儿" if required_role == "母亲" else "母亲"
	ui.set_objective("Tab 切换%s，按 W / ↑ 借线到下一层" % crossing_role)


func _update_rooftop_crossing() -> void:
	if _coop_step >= 3 or world.anchor_index != _coop_step + 1:
		return
	var expected_crossing_role := "成年女儿" if _coop_step != 1 else "母亲"
	if player.role_name != expected_crossing_role or not Input.is_action_pressed(&"move_up"):
		return
	phase = Phase.TRANSITION
	player.controls_enabled = false
	var targets := [Vector2(690.0, 420.0), Vector2(1000.0, 340.0), Vector2(1360.0, 300.0)]
	var tween := create_tween()
	tween.tween_property(player, "global_position", targets[_coop_step], _scaled(0.72))
	await tween.finished
	_coop_step += 1
	if _coop_step >= 3:
		world.gate_two_open = true
		ui.show_checkpoint("✓ 两人同时到达天台顶")
		await _say("D033")
		_enter_act_four()
		return
	phase = Phase.ACT3_ROOFTOP
	player.controls_enabled = true
	var next_required_role := "成年女儿" if _coop_step == 1 else "母亲"
	ui.set_objective("%s靠近第 %d 个支点按 E 锚定" % [next_required_role, _coop_step + 1])


func _enter_act_four() -> void:
	if _phase_guard:
		return
	_phase_guard = true
	phase = Phase.TRANSITION
	player.controls_enabled = false
	world.set_layout(FullDemoWorld.Layout.APARTMENT)
	audio_director.set_mood("apartment")
	player.set_world_bounds(Rect2(96.0, 258.0, 1340.0, 350.0))
	player.set_role("成年女儿")
	player.global_position = Vector2(520.0, 500.0)
	companion.set_role("母亲")
	companion.global_position = Vector2(330.0, 500.0)
	companion.visible = true
	umbrella.visible = false
	tie_line.clear_anchor_points()
	tie_line.reset_line(TieLine.TieState.ADJUSTABLE)
	relationship_state = "Adjustable"
	ui.set_role(player.role_name)
	ui.set_hud_visible(true)
	await ui.show_chapter("第四幕", "线的尽头")
	phase = Phase.ACT4_MOVE_IN
	_act4_elapsed = 0.0
	player.controls_enabled = true
	ui.set_phase("新住处 · 最后一个箱子")
	ui.set_objective("把最后一个纸箱推到窗边  →")
	_phase_guard = false


func _update_apartment_box(delta: float) -> void:
	_act4_elapsed += delta
	var near_box := player.global_position.distance_to(world.apartment_box_position) < 112.0
	world.set_highlight("apartment_box" if near_box else "")
	if near_box and Input.get_axis(&"move_left", &"move_right") > 0.1:
		world.apartment_box_position.x = maxf(world.apartment_box_position.x, player.global_position.x + 46.0)
	if world.apartment_box_position.x >= 990.0 or _act4_elapsed >= 25.0:
		_begin_apartment_conflict()


func _begin_apartment_conflict() -> void:
	if phase != Phase.ACT4_MOVE_IN or _phase_guard:
		return
	_phase_guard = true
	phase = Phase.ACT4_CONFLICT
	player.controls_enabled = false
	ui.set_phase("熟悉的边界")
	ui.set_objective("母亲又开始替她安排这个家")
	await _say("D034")
	await _say("D035")
	await _say("D036")
	world.set_stage(1)
	companion.visible = false
	tie_line.set_story_state(TieLine.TieState.SILENT)
	relationship_state = "Silent"
	audio_director.set_mood("silence")
	phase = Phase.ACT4_SILENCE
	_act4_elapsed = 0.0
	_silence_start_position = player.global_position
	player.controls_enabled = true
	ui.set_phase("几乎没有线的房间")
	ui.set_objective("一个人走一走，听听房间里的安静")
	_phase_guard = false


func _update_silent_apartment(delta: float) -> void:
	_act4_elapsed += delta
	var walked_distance := player.global_position.distance_to(_silence_start_position)
	if walked_distance >= 360.0 or _act4_elapsed >= 9.0:
		_begin_relaxed_connection()


func _begin_relaxed_connection() -> void:
	if phase != Phase.ACT4_SILENCE or _phase_guard:
		return
	_phase_guard = true
	phase = Phase.TRANSITION
	player.controls_enabled = false
	await _say("D038")
	world.set_stage(2)
	companion.global_position = world.get_point("apartment_door")
	companion.visible = true
	tie_line.set_story_state(TieLine.TieState.STABLE)
	relationship_state = "Stable"
	audio_director.set_mood("apartment")
	await _say("D039")
	phase = Phase.ACT4_RELAXED
	player.controls_enabled = true
	ui.set_phase("松开的牵挂")
	ui.set_objective("送母亲到门边，然后回到自己的生活  →")
	_phase_guard = false


func _enter_epilogue() -> void:
	if phase != Phase.ACT4_RELAXED or _phase_guard:
		return
	_phase_guard = true
	phase = Phase.ACT4_EPILOGUE
	player.controls_enabled = false
	world.set_stage(3)
	world.epilogue_line_visible = true
	companion.visible = false
	tie_line.set_story_state(TieLine.TieState.HIDDEN)
	umbrella.global_position = world.get_point("epilogue_umbrella")
	umbrella.visible = true
	umbrella.set_process(false)
	audio_director.set_mood("epilogue")
	ui.set_hud_visible(false)
	await get_tree().create_timer(_scaled(3.2)).timeout
	phase = Phase.COMPLETE
	ui.show_completion(
		"—— 线还在 ——",
		"它不再拉扯，只安静地留在那里。\n记忆碎片 %d/5 · 回响 %d/3\n\n按 R 重新体验" % [fragments_found, echoes_found]
	)
	_phase_guard = false


func _try_switch_character() -> void:
	if not player.controls_enabled:
		return
	var allowed := phase in [
		Phase.ACT2_CABINET_CHILD,
		Phase.ACT2_CABINET_MOTHER,
		Phase.ACT2_ANCHOR,
		Phase.ACT3_CORRIDOR_1,
		Phase.ACT3_CORRIDOR_2,
		Phase.ACT3_WAREHOUSE_BOX_1,
		Phase.ACT3_WAREHOUSE_CRAWL,
		Phase.ACT3_WAREHOUSE_BOX_2,
		Phase.ACT3_ROOFTOP,
	]
	if not allowed:
		return
	var player_position := player.global_position
	var companion_position := companion.global_position
	var player_role := player.role_name
	var companion_role := companion.role_name
	player.global_position = companion_position
	companion.global_position = player_position
	player.set_role(companion_role)
	companion.set_role(player_role)
	ui.set_role(player.role_name)
	ui.show_checkpoint("当前控制：%s" % player.role_name)


func _update_memory_tie_control() -> void:
	if phase not in [Phase.ACT2_BICYCLE, Phase.ACT2_PUDDLE, Phase.ACT2_CABINET_CHILD, Phase.ACT2_CABINET_MOTHER, Phase.ACT2_ANCHOR]:
		return
	if Input.is_action_pressed(&"tie_control"):
		tie_line.set_story_state(TieLine.TieState.TENSE)
		tie_line.set_visual_tension(0.82)
	elif phase != Phase.ACT2_PUDDLE:
		tie_line.set_visual_tension(-1.0)
		tie_line.set_story_state(TieLine.TieState.ADJUSTABLE)


func _apply_stage_constraints() -> void:
	if phase == Phase.ACT2_CABINET_CHILD and player.role_name in ["母亲", "年轻母亲"]:
		player.global_position.x = minf(player.global_position.x, 1010.0)
	elif phase == Phase.ACT2_CLIMB:
		player.global_position.x = 1255.0
		player.global_position.y = clampf(player.global_position.y, 445.0, 590.0)
	elif phase == Phase.ACT3_WAREHOUSE_CRAWL and player.role_name == "母亲":
		player.global_position.x = minf(player.global_position.x, 735.0)


func _update_debug_ui() -> void:
	ui.update_debug(
		player.global_position,
		companion.global_position,
		tie_line.distance,
		tie_line.tension_value,
		tie_line.get_state_name(),
		get_phase_name()
	)


func get_phase_name() -> String:
	return Phase.keys()[phase].to_lower()


func get_act_number() -> int:
	if phase <= Phase.ACT1_UMBRELLA:
		return 1
	if phase <= Phase.ACT2_FAREWELL:
		return 2
	if phase <= Phase.ACT3_ROOFTOP:
		return 3
	return 4


func _say(dialogue_id: String) -> void:
	var entry := dialogue_catalog.get_entry(dialogue_id)
	await ui.show_dialogue(
		str(entry.get("speaker", "")),
		str(entry.get("text", "")),
		float(entry.get("duration", 2.2))
	)


func get_dialogue_entry(dialogue_id: String) -> Dictionary:
	return dialogue_catalog.get_entry(dialogue_id)


func get_completion_snapshot() -> Dictionary:
	return {
		"phase": get_phase_name(),
		"act": get_act_number(),
		"core_items": core_items_found,
		"fragments": fragments_found,
		"echoes": echoes_found,
		"relationship_state": relationship_state,
		"epilogue": world.stage == 3 and world.epilogue_line_visible,
		"tie_state": tie_line.get_state_name(),
	}


func _near_point(point_id: String, radius: float) -> bool:
	return player.global_position.distance_to(world.get_point(point_id)) <= radius


func _scaled(seconds: float) -> float:
	return maxf(seconds * (0.02 if test_mode else 1.0), 0.01)


func _ensure_input_actions() -> void:
	_register_key_action(&"move_left", [KEY_A, KEY_LEFT])
	_register_key_action(&"move_right", [KEY_D, KEY_RIGHT])
	_register_key_action(&"move_up", [KEY_W, KEY_UP])
	_register_key_action(&"move_down", [KEY_S, KEY_DOWN])
	_register_key_action(&"interact", [KEY_E, KEY_ENTER])
	_register_key_action(&"switch_character", [KEY_TAB])
	_register_key_action(&"tie_control", [KEY_SPACE])
	_register_key_action(&"run", [KEY_SHIFT])
	_register_key_action(&"restart", [KEY_R])
	_register_key_action(&"toggle_debug", [KEY_F3])
	_register_key_action(&"toggle_help", [KEY_F1])
	_register_key_action(&"pause_menu", [KEY_ESCAPE])
	_register_key_action(&"toggle_mute", [KEY_M])
	_register_key_action(&"toggle_reduced_motion", [KEY_V])
	_register_mouse_action(&"interact", MOUSE_BUTTON_LEFT)
	_register_mouse_action(&"tie_control", MOUSE_BUTTON_LEFT)


func _on_checkpoint_shown() -> void:
	audio_director.play_cue("checkpoint")


func _on_chapter_shown() -> void:
	audio_director.play_cue("transition")


func _on_mute_changed(muted: bool) -> void:
	audio_director.set_muted(muted)


func _on_reduced_motion_changed(enabled: bool) -> void:
	world.reduced_motion = enabled
	tie_line.reduced_motion = enabled


func _register_key_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode: Key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)


func _register_mouse_action(action: StringName, button_index: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
