class_name Interactable
extends Area2D

signal interacted(player: PlayerController)

@export var display_name := "调查对象"
@export var dialogue_id := ""
@export var observation_id := ""
@export var is_key_object := false
@export var once_only := true
@export var interaction_enabled := true
@export var logical_position := Vector3.ZERO
@export var interaction_prompt_override := ""
@export var auto_play_dialogue := true
@export var requires_crouch := false
## 交互范围不再用白色光斑标记。若某个特殊关卡确实需要，可单独开启。
@export var show_interaction_highlight := false

## 同格物件的先后微调（正数更靠前），墙面物件用 Projection25D.BAND_WALL。
@export var depth_offset := 0

var investigated := false

@onready var _glow: Node2D = get_node_or_null("Glow") as Node2D
@onready var _math_body: Node3D = get_node_or_null("MathBody") as Node3D


func _ready() -> void:
	add_to_group(&"interactable")
	if is_key_object:
		add_to_group(&"key_object")
	if requires_crouch:
		add_to_group(&"crouch_interactable")
	_sync_projection()
	_set_glow_visible(interaction_enabled and show_interaction_highlight)


func set_logical_position(value: Vector3) -> void:
	logical_position = value
	_sync_projection()


func get_logical_position() -> Vector3:
	return logical_position


func get_interaction_prompt() -> String:
	if not interaction_prompt_override.is_empty():
		return interaction_prompt_override
	return "按 Enter / 空格调查：%s" % display_name


func can_interact() -> bool:
	return interaction_enabled and (not once_only or not investigated)


func can_interact_for_player(player: PlayerController) -> bool:
	if not can_interact():
		return false
	return not requires_crouch or (player != null and player.is_crouching())


func interact(player: PlayerController) -> void:
	if not can_interact_for_player(player):
		return
	investigated = true
	_hide_glow()
	interacted.emit(player)
	if not auto_play_dialogue:
		return

	var dialogue_ui := get_tree().get_first_node_in_group(&"dialogue_ui") as DialogueUI
	if dialogue_ui == null:
		return
	if dialogue_id.is_empty():
		push_warning("[Interactable] %s 没有配置 dialogue_id" % name)
		return
	dialogue_ui.play(dialogue_id)


func configure_dialogue(next_dialogue_id: String, reset_investigation := true) -> void:
	dialogue_id = next_dialogue_id
	if reset_investigation:
		investigated = false
	_set_glow_visible(true)


func configure_observation(next_observation_id: String, reset_investigation := true) -> void:
	observation_id = next_observation_id
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
		_glow.visible = show_highlight and show_interaction_highlight


func _sync_projection() -> void:
	if is_instance_valid(_math_body):
		_math_body.position = logical_position
	global_position = Projection25D.project(logical_position)
	z_index = Projection25D.depth_index(logical_position) + depth_offset


func _hide_glow() -> void:
	_set_glow_visible(false)


func _set_glow_visible(value: bool) -> void:
	if is_instance_valid(_glow):
		_glow.visible = value and show_interaction_highlight
