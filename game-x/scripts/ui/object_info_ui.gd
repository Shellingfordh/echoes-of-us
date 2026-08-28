class_name ObjectInfoUI
extends Control

## 普通调查物件的第一层信息：先呈现玩家看见的事实，再播放余念的 D-ID 反应。

signal info_opened(info_id: String)
signal info_closed(info_id: String)

var current_info_id := ""
var _pending_dialogue_id := ""
var _database: ObjectInfoDatabase
var _game_flow: GameFlow
var _return_mode := GameFlow.Mode.EXPLORE
var _title_label: Label
var _body_label: RichTextLabel


func _ready() -> void:
	add_to_group(&"object_info_ui")
	_build_interface()
	hide()


func present(info_id: String, fallback_title: String, dialogue_id: String) -> bool:
	_database = get_tree().get_first_node_in_group(&"object_info_database") as ObjectInfoDatabase
	if _database == null or not _database.has_info(info_id):
		push_warning("[ObjectInfoUI] 无法显示 %s" % info_id)
		return false
	if is_open():
		return false

	current_info_id = info_id
	var title := _database.get_title(info_id)
	_title_label.text = fallback_title if title.is_empty() else title
	_body_label.text = _database.get_text(info_id)
	_pending_dialogue_id = dialogue_id
	if _pending_dialogue_id.is_empty():
		_pending_dialogue_id = _database.get_dialogue_id(info_id)

	_game_flow = get_tree().get_first_node_in_group(&"game_flow") as GameFlow
	if _game_flow != null:
		_return_mode = _game_flow.current_mode
		_game_flow.set_mode(GameFlow.Mode.CUTSCENE)
	show()
	info_opened.emit(current_info_id)
	return true


func advance() -> void:
	if not is_open():
		return
	var closed_id := current_info_id
	var dialogue_id := _pending_dialogue_id
	current_info_id = ""
	_pending_dialogue_id = ""
	hide()
	if _game_flow != null:
		_game_flow.set_mode(_return_mode)

	var dialogue_ui := get_tree().get_first_node_in_group(&"dialogue_ui") as DialogueUI
	if dialogue_ui != null and not dialogue_id.is_empty():
		dialogue_ui.play(dialogue_id)
	info_closed.emit(closed_id)


func is_open() -> bool:
	return visible and not current_info_id.is_empty()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_cancel"):
		advance()
		get_viewport().set_input_as_handled()


func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.01, 0.025, 0.024, 0.10)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dimmer)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	card.position = Vector2(-500.0, -246.0)
	card.size = Vector2(1000.0, 216.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.075, 0.07, 0.97)
	style.border_color = Color(0.63, 0.76, 0.66, 0.58)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	style.shadow_size = 12
	card.add_theme_stylebox_override("panel", style)
	add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 18)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	margin.add_child(column)

	var kicker := Label.new()
	kicker.text = "眼前的东西"
	kicker.add_theme_font_size_override("font_size", 14)
	kicker.add_theme_color_override("font_color", Color(0.70, 0.80, 0.74, 1.0))
	column.add_child(kicker)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color(0.96, 0.87, 0.61, 1.0))
	column.add_child(_title_label)

	_body_label = RichTextLabel.new()
	_body_label.custom_minimum_size = Vector2(0.0, 91.0)
	_body_label.fit_content = false
	_body_label.scroll_active = false
	_body_label.add_theme_font_size_override("normal_font_size", 18)
	_body_label.add_theme_color_override("default_color", Color(0.91, 0.93, 0.89, 1.0))
	column.add_child(_body_label)

	var hint := Label.new()
	hint.text = "Enter / 空格  听听余念怎么想"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.66, 0.75, 0.70, 1.0))
	column.add_child(hint)
