class_name FixedObservationUI
extends Control

## 少量叙事物件使用的固定观察层。房间仍然保留在背景中，观察不是图鉴，
## 也不会创造或改变牵挂线。

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
	body: String,
	dialogue_id: String
) -> void:
	if is_open():
		close_observation()
	current_object_id = object_id
	_title_label.text = title
	_body_label.text = "%s\n\n%s" % [body, _format_dialogue_chain(dialogue_id)]
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


func _format_dialogue_chain(root_id: String) -> String:
	var database := get_tree().get_first_node_in_group(&"dialogue_database") as DialogueDatabase
	if database == null or not database.has_dialogue(root_id):
		return ""
	var paragraphs: Array[String] = []
	var current_id := root_id
	var visited: Dictionary = {}
	while current_id != DialogueDatabase.END_DIALOGUE_ID and not visited.has(current_id):
		visited[current_id] = true
		var entry := database.get_entry(current_id)
		var speaker := str(entry.get("speaker", "余念·独白"))
		var lines: Array = entry.get("lines", []) as Array
		if not lines.is_empty():
			var text_lines: Array[String] = []
			for line: Variant in lines:
				text_lines.append(str(line))
			paragraphs.append("—— %s\n%s" % [speaker, "\n".join(text_lines)])
		current_id = str(entry.get("next", DialogueDatabase.END_DIALOGUE_ID))
	return "\n\n".join(paragraphs)


func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# 观察仍发生在真实房间里，只轻压背景，不把场景切成独立图鉴页。
	dimmer.color = Color(0.01, 0.025, 0.024, 0.16)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dimmer)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	card.position = Vector2(-548.0, -286.0)
	card.size = Vector2(520.0, 572.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.075, 0.07, 0.96)
	style.border_color = Color(0.63, 0.76, 0.66, 0.58)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	style.shadow_size = 12
	card.add_theme_stylebox_override("panel", style)
	add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 22)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var kicker := Label.new()
	kicker.text = "观察中 · 同一个房间，换一个位置"
	kicker.add_theme_font_size_override("font_size", 15)
	kicker.add_theme_color_override("font_color", Color(0.71, 0.82, 0.75, 1.0))
	column.add_child(kicker)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 30)
	_title_label.add_theme_color_override("font_color", Color(0.96, 0.87, 0.61, 1.0))
	column.add_child(_title_label)

	_body_label = RichTextLabel.new()
	_body_label.custom_minimum_size = Vector2(0.0, 414.0)
	_body_label.fit_content = false
	_body_label.scroll_active = true
	_body_label.add_theme_font_size_override("normal_font_size", 18)
	_body_label.add_theme_color_override("default_color", Color(0.91, 0.93, 0.89, 1.0))
	column.add_child(_body_label)

	var hint := Label.new()
	hint.text = "Enter / 空格 / Esc  返回房间"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.66, 0.75, 0.70, 1.0))
	column.add_child(hint)
