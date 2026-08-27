class_name ChapterOneUI
extends CanvasLayer

var phase_label: Label
var objective_label: Label
var progress_label: Label
var prompt_panel: PanelContainer
var prompt_label: Label
var dialogue_panel: PanelContainer
var speaker_label: Label
var dialogue_label: Label
var observation_overlay: Control
var observation_title: Label
var observation_body: Label
var checkpoint_label: Label
var completion_overlay: Control
var completion_title: Label
var completion_body: Label


func _ready() -> void:
	layer = 20
	_build_hud()
	_build_dialogue()
	_build_observation()
	_build_completion()


func set_phase(title: String, objective: String) -> void:
	phase_label.text = title
	objective_label.text = objective


func set_progress(required_done: int, required_total: int, optional_done: int) -> void:
	progress_label.text = "必要调查  %d / %d     自主发现  +%d" % [required_done, required_total, optional_done]


func set_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_panel.visible = not text.is_empty()


func show_dialogue(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	dialogue_label.text = text
	dialogue_panel.visible = true


func hide_dialogue() -> void:
	dialogue_panel.visible = false


func show_observation(title: String, body: String) -> void:
	observation_title.text = title
	observation_body.text = body
	observation_overlay.visible = true


func hide_observation() -> void:
	observation_overlay.visible = false


func show_checkpoint(text: String) -> void:
	checkpoint_label.text = text
	checkpoint_label.modulate = Color.WHITE
	checkpoint_label.visible = true
	var tween := create_tween()
	tween.tween_interval(1.25)
	tween.tween_property(checkpoint_label, "modulate:a", 0.0, 0.55)
	tween.tween_callback(func() -> void: checkpoint_label.visible = false)


func show_completion(title: String, body: String) -> void:
	completion_title.text = title
	completion_body.text = body
	completion_overlay.visible = true
	set_prompt("")


func _build_hud() -> void:
	var hud := PanelContainer.new()
	hud.name = "HUD"
	hud.position = Vector2(30.0, 28.0)
	hud.size = Vector2(670.0, 142.0)
	hud.add_theme_stylebox_override("panel", _panel_style(Color(0.075, 0.065, 0.065, 0.9), 18.0))
	add_child(hud)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	hud.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	margin.add_child(column)

	phase_label = Label.new()
	phase_label.add_theme_font_size_override("font_size", 20)
	phase_label.add_theme_color_override("font_color", Color("#d9b77e"))
	column.add_child(phase_label)

	objective_label = Label.new()
	objective_label.add_theme_font_size_override("font_size", 29)
	objective_label.add_theme_color_override("font_color", Color("#f1ede5"))
	column.add_child(objective_label)

	progress_label = Label.new()
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_label.add_theme_color_override("font_color", Color("#9fc0cb"))
	column.add_child(progress_label)

	checkpoint_label = Label.new()
	checkpoint_label.position = Vector2(960.0, 50.0)
	checkpoint_label.size = Vector2(430.0, 60.0)
	checkpoint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	checkpoint_label.add_theme_font_size_override("font_size", 21)
	checkpoint_label.add_theme_color_override("font_color", Color("#f1d29a"))
	checkpoint_label.visible = false
	add_child(checkpoint_label)

	prompt_panel = PanelContainer.new()
	prompt_panel.position = Vector2(510.0, 724.0)
	prompt_panel.size = Vector2(420.0, 54.0)
	prompt_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.055, 0.06, 0.9), 18.0))
	add_child(prompt_panel)
	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 19)
	prompt_label.add_theme_color_override("font_color", Color("#f3e3c3"))
	prompt_panel.add_child(prompt_label)
	prompt_panel.visible = false


func _build_dialogue() -> void:
	dialogue_panel = PanelContainer.new()
	dialogue_panel.name = "Dialogue"
	dialogue_panel.position = Vector2(208.0, 570.0)
	dialogue_panel.size = Vector2(1024.0, 136.0)
	dialogue_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.041, 0.055, 0.95), 20.0, Color(0.82, 0.67, 0.48, 0.46)))
	add_child(dialogue_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 17)
	margin.add_theme_constant_override("margin_bottom", 17)
	dialogue_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 17)
	speaker_label.add_theme_color_override("font_color", Color("#d9b77e"))
	column.add_child(speaker_label)

	dialogue_label = Label.new()
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_font_size_override("font_size", 22)
	dialogue_label.add_theme_color_override("font_color", Color("#f4f0e8"))
	column.add_child(dialogue_label)
	dialogue_panel.visible = false


func _build_observation() -> void:
	observation_overlay = Control.new()
	observation_overlay.name = "ObservationOverlay"
	observation_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(observation_overlay)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.025, 0.023, 0.028, 0.82)
	observation_overlay.add_child(shade)

	var card := PanelContainer.new()
	card.position = Vector2(210.0, 128.0)
	card.size = Vector2(1020.0, 552.0)
	card.add_theme_stylebox_override("panel", _panel_style(Color("#c9b79b"), 24.0, Color("#eee3d2")))
	observation_overlay.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 58)
	margin.add_theme_constant_override("margin_right", 58)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_bottom", 42)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	margin.add_child(column)

	var kicker := Label.new()
	kicker.text = "固定观察 · 同一个房间，换一个位置看"
	kicker.add_theme_font_size_override("font_size", 18)
	kicker.add_theme_color_override("font_color", Color("#725d50"))
	column.add_child(kicker)

	observation_title = Label.new()
	observation_title.add_theme_font_size_override("font_size", 38)
	observation_title.add_theme_color_override("font_color", Color("#302b2a"))
	column.add_child(observation_title)

	var rule := HSeparator.new()
	column.add_child(rule)

	observation_body = Label.new()
	observation_body.custom_minimum_size = Vector2(0.0, 260.0)
	observation_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	observation_body.add_theme_font_size_override("font_size", 23)
	observation_body.add_theme_color_override("font_color", Color("#463d39"))
	column.add_child(observation_body)

	var close_hint := Label.new()
	close_hint.text = "E / Esc  返回房间"
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	close_hint.add_theme_font_size_override("font_size", 17)
	close_hint.add_theme_color_override("font_color", Color("#725d50"))
	column.add_child(close_hint)
	observation_overlay.visible = false


func _build_completion() -> void:
	completion_overlay = Control.new()
	completion_overlay.name = "CompletionOverlay"
	completion_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(completion_overlay)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.035, 0.029, 0.035, 0.9)
	completion_overlay.add_child(shade)

	completion_title = Label.new()
	completion_title.position = Vector2(250.0, 268.0)
	completion_title.size = Vector2(940.0, 90.0)
	completion_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	completion_title.add_theme_font_size_override("font_size", 48)
	completion_title.add_theme_color_override("font_color", Color("#f0c47d"))
	completion_overlay.add_child(completion_title)

	completion_body = Label.new()
	completion_body.position = Vector2(300.0, 374.0)
	completion_body.size = Vector2(840.0, 150.0)
	completion_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	completion_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	completion_body.add_theme_font_size_override("font_size", 23)
	completion_body.add_theme_color_override("font_color", Color("#eee6dc"))
	completion_overlay.add_child(completion_body)
	completion_overlay.visible = false


func _panel_style(color: Color, radius: float, border_color := Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	if border_color.a > 0.0:
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = border_color
	return style
