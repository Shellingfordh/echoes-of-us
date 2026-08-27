extends Node2D

enum Phase {
	INTRO,
	WALK_AWAY,
	TIE_REVEALED,
	PULLBACK,
	INSPECT_UMBRELLA,
	COMPLETE,
}

@onready var player: EchoesPlayer = %Player
@onready var mother: EchoesMother = %Mother
@onready var tie_line: TieLine = %TieLine
@onready var umbrella: MemoryUmbrella = %Umbrella
@onready var ui: PrototypeUI = %PrototypeUI

var phase := Phase.INTRO
var _pullback_started := false


func _enter_tree() -> void:
	_ensure_input_actions()


func _ready() -> void:
	player.controls_enabled = false
	player.interaction_requested.connect(_on_interaction_requested)
	tie_line.revealed.connect(_on_tie_revealed)
	tie_line.maximum_tension_reached.connect(_on_maximum_tension_reached)
	umbrella.inspected.connect(_on_umbrella_inspected)

	ui.set_phase("序章 · 离家")
	ui.set_objective("听听妈妈想说什么")
	ui.set_interaction_prompt("E  查看黄色雨伞", false)
	ui.set_debug_visible(true)
	call_deferred("_play_intro")


func _physics_process(_delta: float) -> void:
	if phase == Phase.TIE_REVEALED:
		player.movement_multiplier = maxf(0.12, 1.0 - pow(tie_line.tension_value, 2.0))
	else:
		player.movement_multiplier = 1.0

	if phase == Phase.INSPECT_UMBRELLA:
		ui.set_interaction_prompt("E  查看黄色雨伞", umbrella.can_interact())
	else:
		ui.set_interaction_prompt("E  查看黄色雨伞", false)

	ui.update_debug(
		player.global_position,
		mother.global_position,
		tie_line.distance,
		tie_line.tension_value,
		tie_line.get_state_name(),
		_get_phase_name()
	)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"restart"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed(&"toggle_debug"):
		ui.toggle_debug()


func _play_intro() -> void:
	await ui.show_dialogue("妈妈", "东西都带了吗？", 1.8)
	await ui.show_dialogue("女儿", "带了。", 1.1)
	await ui.show_dialogue("妈妈", "慢一点。", 1.3)
	phase = Phase.WALK_AWAY
	player.controls_enabled = true
	ui.set_objective("向门口走，试着离开家  →")


func _on_tie_revealed() -> void:
	if phase not in [Phase.WALK_AWAY, Phase.TIE_REVEALED]:
		return
	phase = Phase.TIE_REVEALED
	ui.set_phase("第一次牵挂")
	ui.set_objective("继续走，感受牵挂线的变化  →")
	ui.show_dialogue("女儿 · 心声", "……这是什么？", 2.0)


func _on_maximum_tension_reached() -> void:
	if phase != Phase.TIE_REVEALED or _pullback_started:
		return
	_pullback_started = true
	phase = Phase.PULLBACK
	player.controls_enabled = false
	ui.set_phase("第一次分离")
	ui.set_objective("牵挂线已经绷紧")

	var pullback_target := umbrella.global_position + Vector2(66.0, 10.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position", pullback_target, 0.7)
	await tween.finished

	phase = Phase.INSPECT_UMBRELLA
	umbrella.set_interaction_enabled(true)
	player.controls_enabled = true
	ui.set_phase("记忆的入口")
	ui.set_objective("看看那把发光的黄色雨伞")
	await ui.show_dialogue("女儿 · 心声", "这根线……是妈妈不愿让我离开的证明。", 2.8)


func _on_interaction_requested() -> void:
	if phase == Phase.INSPECT_UMBRELLA:
		umbrella.try_inspect()


func _on_umbrella_inspected() -> void:
	if phase != Phase.INSPECT_UMBRELLA:
		return
	phase = Phase.COMPLETE
	player.controls_enabled = false
	umbrella.set_interaction_enabled(false)
	ui.set_phase("第一幕完成")
	ui.set_objective("下一幕：进入黄色雨伞中的记忆")
	ui.show_completion()
	await ui.show_dialogue("女儿 · 心声", "小时候下雨，她总把伞往我这边倾。", 3.4)


func _get_phase_name() -> String:
	return Phase.keys()[phase].to_lower()


func _ensure_input_actions() -> void:
	_register_key_action(&"move_left", [KEY_A, KEY_LEFT])
	_register_key_action(&"move_right", [KEY_D, KEY_RIGHT])
	_register_key_action(&"move_up", [KEY_W, KEY_UP])
	_register_key_action(&"move_down", [KEY_S, KEY_DOWN])
	_register_key_action(&"interact", [KEY_E, KEY_ENTER])
	_register_key_action(&"restart", [KEY_R])
	_register_key_action(&"toggle_debug", [KEY_F3])


func _register_key_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode: Key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)
