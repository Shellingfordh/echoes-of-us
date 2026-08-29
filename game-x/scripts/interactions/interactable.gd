class_name Interactable
extends Area2D

signal interacted(player: PlayerController)

@export var display_name := "调查对象"
@export var object_info_id := ""
@export var dialogue_id := ""
@export var is_key_object := false
@export var once_only := true
@export var interaction_enabled := true
@export var logical_position := Vector3.ZERO
@export var interaction_prompt_override := ""
@export var disabled_interaction_prompt := ""
@export var auto_play_dialogue := true
@export_range(0.5, 4.0, 0.1) var resonance_hz := 1.8
@export_range(0.0, 0.2, 0.01) var resonance_scale := 0.1

## 同格物件的先后微调（正数更靠前），墙面物件用 Projection25D.BAND_WALL。
@export var depth_offset := 0

var investigated := false
var _resonance_active := false
var _resonance_intensity := 0.0
var _glow_base_scale := Vector2.ONE

@onready var _glow: Node2D = get_node_or_null("Glow") as Node2D
@onready var _math_body: Node3D = get_node_or_null("MathBody") as Node3D


func _ready() -> void:
	add_to_group(&"interactable")
	if is_key_object:
		add_to_group(&"key_object")
	if is_instance_valid(_glow):
		_glow_base_scale = _glow.scale
	_sync_projection()


func _process(_delta: float) -> void:
	if not _resonance_active or not is_instance_valid(_glow):
		return
	var strength := get_resonance_strength()
	_glow.visible = true
	_glow.scale = _glow_base_scale * (1.0 + resonance_scale * strength)
	_glow.modulate.a = lerpf(0.68, 1.0, strength)


func set_logical_position(value: Vector3) -> void:
	logical_position = value
	_sync_projection()


func get_logical_position() -> Vector3:
	return logical_position


func get_interaction_prompt() -> String:
	if not interaction_prompt_override.is_empty():
		return interaction_prompt_override
	return "按 Enter / 空格调查：%s" % display_name


func get_disabled_interaction_prompt() -> String:
	return disabled_interaction_prompt


func can_interact() -> bool:
	return interaction_enabled and (not once_only or not investigated)


func can_show_disabled_hint() -> bool:
	return (
		not interaction_enabled
		and not disabled_interaction_prompt.is_empty()
		and (not once_only or not investigated)
	)


func interact(player: PlayerController) -> void:
	if not can_interact():
		return
	investigated = true
	_hide_glow()
	interacted.emit(player)
	if not auto_play_dialogue:
		return
	if not object_info_id.is_empty():
		var info_ui := get_tree().get_first_node_in_group(&"object_info_ui") as ObjectInfoUI
		if info_ui != null and info_ui.present(object_info_id, display_name, dialogue_id):
			return

	var dialogue_ui := get_tree().get_first_node_in_group(&"dialogue_ui") as DialogueUI
	if dialogue_ui == null:
		return
	if dialogue_id.is_empty():
		push_warning("[Interactable] %s 没有配置 dialogue_id" % name)
		return
	dialogue_ui.play(dialogue_id)


func configure_content(
	next_object_info_id: String,
	next_dialogue_id: String,
	reset_investigation := true
) -> void:
	object_info_id = next_object_info_id
	dialogue_id = next_dialogue_id
	if reset_investigation:
		investigated = false
	_set_glow_visible(true)


func reset_interaction() -> void:
	investigated = false
	if interaction_enabled:
		_set_glow_visible(true)


func set_interaction_enabled(value: bool) -> void:
	interaction_enabled = value
	if not value:
		_set_glow_visible(false)


func set_highlight(color: Color, show_highlight := true) -> void:
	if is_instance_valid(_glow):
		_glow.self_modulate = color
		_glow.visible = show_highlight


func set_resonance_active(value: bool, intensity := 1.0) -> void:
	_resonance_active = value
	_resonance_intensity = clampf(intensity, 0.0, 1.0) if value else 0.0
	if not is_instance_valid(_glow):
		return
	if value:
		_glow.visible = true
	else:
		_glow.scale = _glow_base_scale
		_glow.modulate.a = 1.0


func is_resonating() -> bool:
	return _resonance_active


func get_resonance_strength() -> float:
	if not _resonance_active:
		return 0.0
	var phase := Time.get_ticks_msec() * 0.001 * TAU * resonance_hz
	var pulse := (sin(phase) + 1.0) * 0.5
	return _resonance_intensity * lerpf(0.42, 1.0, pulse)


func _sync_projection() -> void:
	if is_instance_valid(_math_body):
		_math_body.position = logical_position
	global_position = Projection25D.project(logical_position)
	z_index = Projection25D.depth_index(logical_position) + depth_offset


func _hide_glow() -> void:
	_set_glow_visible(false)


func _set_glow_visible(value: bool) -> void:
	if is_instance_valid(_glow):
		_glow.visible = value or _resonance_active
