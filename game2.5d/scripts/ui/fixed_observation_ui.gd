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
var _item_image: TextureRect


func _ready() -> void:
	add_to_group(&"fixed_observation_ui")
	_build_interface()
	hide()


func open_observation(
	object_id: String,
	title: String,
	body: String,
	image_path: String = ""
) -> void:
	if is_open():
		close_observation()
	current_object_id = object_id
	_title_label.text = title
	_body_label.text = body
	_show_item_image(image_path)
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


func _show_item_image(image_path: String) -> void:
	_item_image.texture = null
	_item_image.hide()
	if image_path.is_empty() or not ResourceLoader.exists(image_path, "Texture2D"):
		return
	var texture := load(image_path) as Texture2D
	if texture == null:
		return
	_item_image.texture = texture
	_item_image.show()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_cancel"):
		close_observation()
		get_viewport().set_input_as_handled()


## 物件描述正文走手写体（楷体），标题与辅助文字走印刷体，和其他 UI 区分开。
const FONT_HAND := "res://art/fonts/simkai.ttf"
const FONT_PRINT := "res://art/fonts/NotoSansCJKsc-Regular.otf"


## 字体缺失时返回 null，交给调用方跳过 override，退回主题默认字体。
func _font(path: String) -> Font:
	if not ResourceLoader.exists(path, "Font"):
		return null
	return load(path) as Font


func _apply_font(target: Control, item: String, path: String) -> void:
	var font := _font(path)
	if font != null:
		target.add_theme_font_override(item, font)


## art/ui/ 下的面板贴图 → StyleBoxTexture。贴图缺失时退回纯色，UI 不至于整块消失。
func _texture_style(file_name: String, margin: float) -> StyleBox:
	var path := "res://art/ui/%s" % file_name
	if ResourceLoader.exists(path, "Texture2D"):
		var texture := load(path) as Texture2D
		if texture != null:
			var textured := StyleBoxTexture.new()
			textured.texture = texture
			textured.set_texture_margin_all(margin)
			return textured
	var fallback := StyleBoxFlat.new()
	fallback.bg_color = Color(0.84, 0.82, 0.7, 0.98)
	fallback.border_color = Color(0.94, 0.87, 0.63, 1.0)
	fallback.set_border_width_all(3)
	fallback.set_corner_radius_all(12)
	return fallback


func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.055, 0.035, 0.02, 0.72)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dimmer)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-330.0, -235.0)
	card.size = Vector2(660.0, 470.0)
	# 底纹统一走 art/ui/ 下从 ui_texture.png 裁出来的九宫格贴图。
	card.add_theme_stylebox_override("panel", _texture_style("observation_card.png", 24.0))
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
	_apply_font(kicker, "font", FONT_PRINT)
	column.add_child(kicker)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 34)
	_title_label.add_theme_color_override("font_color", Color(0.16, 0.13, 0.1, 1.0))
	_apply_font(_title_label, "font", FONT_PRINT)
	column.add_child(_title_label)

	# 正文与物件图由容器分栏，图片永远不会覆盖标题或正文文字。
	var content_row := HBoxContainer.new()
	content_row.custom_minimum_size = Vector2(0.0, 300.0)
	content_row.add_theme_constant_override("separation", 18)
	column.add_child(content_row)

	_body_label = RichTextLabel.new()
	_body_label.custom_minimum_size = Vector2(0.0, 300.0)
	_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_label.fit_content = false
	_body_label.scroll_active = true
	_body_label.add_theme_font_size_override("normal_font_size", 24)
	_body_label.add_theme_color_override("default_color", Color(0.22, 0.19, 0.15, 1.0))
	_apply_font(_body_label, "normal_font", FONT_HAND)
	content_row.add_child(_body_label)

	_item_image = TextureRect.new()
	_item_image.custom_minimum_size = Vector2(165.0, 280.0)
	_item_image.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_item_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_item_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_item_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_item_image.hide()
	content_row.add_child(_item_image)

	var hint := Label.new()
	hint.text = "Enter / 空格 / Esc  返回房间"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.38, 0.33, 0.26, 1.0))
	_apply_font(hint, "font", FONT_PRINT)
	column.add_child(hint)
