class_name FixedObservationUI
extends Control

## 物件信息层只呈现 O-ID 的客观描述；关闭后由 DialogueUI 单独播放 D-ID。

signal observation_opened(object_id: String)
signal observation_closed(object_id: String)

var current_object_id := ""
var _game_flow: GameFlow
var _return_mode := GameFlow.Mode.EXPLORE
var _title_label: Label
var _body_label: RichTextLabel


func _ready() -> void:
	add_to_group(&"fixed_observation_ui")
	_build_interface()
	hide()


func open_observation(
	object_id: String,
	title: String,
	body: String
) -> void:
	if is_open():
		close_observation()
	current_object_id = object_id
	_title_label.text = title
	_body_label.text = body
	_game_flow = get_tree().get_first_node_in_group(&"game_flow") as GameFlow
	if _game_flow != null:
		_return_mode = _game_flow.current_mode
		_game_flow.set_mode(GameFlow.Mode.CUTSCENE)
	show()
	observation_opened.emit(current_object_id)


func close_observation() -> void:
	if not is_open():
		return
	var closed_id := current_object_id
	current_object_id = ""
	hide()
	if _game_flow != null:
		_game_flow.set_mode(_return_mode)
	observation_closed.emit(closed_id)


func is_open() -> bool:
	return visible and not current_object_id.is_empty()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_cancel"):
		close_observation()
		get_viewport().set_input_as_handled()


func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.01, 0.025, 0.024, 0.72)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dimmer)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-330.0, -235.0)
	card.size = Vector2(660.0, 470.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.84, 0.82, 0.70, 0.98)
	style.border_color = Color(0.68, 0.32, 0.26, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	card.add_theme_stylebox_override("panel", style)
	add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 24)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)

	var kicker := Label.new()
	kicker.text = "固定观察 · 同一个房间，换一个位置看"
	kicker.add_theme_font_size_override("font_size", 16)
	kicker.add_theme_color_override("font_color", Color(0.48, 0.22, 0.19, 1.0))
	column.add_child(kicker)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 34)
	_title_label.add_theme_color_override("font_color", Color(0.14, 0.16, 0.14, 1.0))
	column.add_child(_title_label)

	_body_label = RichTextLabel.new()
	_body_label.custom_minimum_size = Vector2(0.0, 300.0)
	_body_label.fit_content = false
	_body_label.scroll_active = true
	_body_label.add_theme_font_size_override("normal_font_size", 20)
	_body_label.add_theme_color_override("default_color", Color(0.20, 0.22, 0.19, 1.0))
	column.add_child(_body_label)

	var hint := Label.new()
	hint.text = "Enter / 空格 / Esc  返回房间"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.35, 0.34, 0.28, 1.0))
	column.add_child(hint)
