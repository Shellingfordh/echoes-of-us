@tool
class_name Chapter3LayoutItem
extends Node2D

## 第三章关卡中的可编辑矩形组件。
## 节点可以使用 StaticBody2D、CharacterBody2D 或 Area2D；本脚本负责编辑器预览
## 以及把位置、尺寸和元数据转换为现有玩法模拟所需的字典。

const WOOD_FLOOR_TEXTURE: Texture2D = preload("res://assets/props/chapter3/platforms/prop_ch03_wood_floor_repeat.png")
const WOOD_LONG_PLATFORM_TEXTURE: Texture2D = preload("res://assets/props/chapter3/platforms/prop_ch03_wood_platform_long.png")
const WOOD_BRACKET_PLATFORM_TEXTURE: Texture2D = preload("res://assets/props/chapter3/platforms/prop_ch03_wood_platform_bracket.png")
const PRESSURE_PLATE_RAISED_TEXTURE: Texture2D = preload("res://assets/props/chapter3/plates/prop_ch03_pressure_plate_raised.png")
const PRESSURE_PLATE_PRESSED_TEXTURE: Texture2D = preload("res://assets/props/chapter3/plates/prop_ch03_pressure_plate_pressed.png")
const MECHANISM_DOOR_CLOSED_TEXTURE: Texture2D = preload("res://assets/props/chapter3/doors/prop_ch03_mechanism_door_closed.png")
const WOOD_FLOOR_REGION := Rect2(0.0, 202.0, 2048.0, 348.0)
const WOOD_LONG_PLATFORM_REGION := Rect2(122.0, 224.0, 1809.0, 356.0)
const WOOD_BRACKET_PLATFORM_REGION := Rect2(136.0, 71.0, 572.0, 564.0)
const WOOD_GATE_STRIP_REGION := Rect2(0.0, 240.0, 2048.0, 190.0)
const PRESSURE_PLATE_RAISED_REGION := Rect2(0.0, 9.0, 1660.0, 908.0)
const PRESSURE_PLATE_PRESSED_REGION := Rect2(45.0, 37.0, 1933.0, 716.0)
const MECHANISM_DOOR_CLOSED_REGION := Rect2(600.0, 67.0, 846.0, 1402.0)

@export var size := Vector2(100.0, 40.0):
	set(value):
		size = value
		queue_redraw()
@export var fill_color := Color("53666d"):
	set(value):
		fill_color = value
		queue_redraw()
@export var edge_color := Color("91a1a5"):
	set(value):
		edge_color = value
		queue_redraw()
@export var edge_width := 3.0:
	set(value):
		edge_width = value
		queue_redraw()
@export var label_text := "":
	set(value):
		label_text = value
		queue_redraw()
@export var plate_pressed := false:
	set(value):
		plate_pressed = value
		queue_redraw()


func _draw() -> void:
	if _is_pressure_plate():
		_draw_pressure_plate()
	elif _is_door():
		if not bool(get_meta(&"external_visual", false)):
			_draw_mechanism_door()
	elif _is_wood_gate():
		_draw_wood_gate()
	elif _uses_wood_surface():
		_draw_wood_surface()
	else:
		draw_rect(Rect2(Vector2.ZERO, size), fill_color)
		draw_rect(Rect2(Vector2.ZERO, size), edge_color, false, edge_width)
	if label_text.is_empty() or not Engine.is_editor_hint():
		return
	var font := ThemeDB.fallback_font
	var label_color := Color("d6a45e") if _uses_wood_surface() or _is_wood_gate() else edge_color
	draw_string(font, Vector2(4.0, -6.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, label_color)


func _uses_wood_surface() -> bool:
	var parent := get_parent()
	return parent != null and (parent.name == &"Platforms" or parent.name == &"Planks")


func _is_pressure_plate() -> bool:
	var parent := get_parent()
	return parent != null and parent.name == &"Plates"


func _is_door() -> bool:
	var parent := get_parent()
	return parent != null and parent.name == &"Doors"


func _is_wood_gate() -> bool:
	return bool(get_meta(&"wood_gate_visual", false))


func _draw_pressure_plate() -> void:
	var texture := PRESSURE_PLATE_PRESSED_TEXTURE if plate_pressed else PRESSURE_PLATE_RAISED_TEXTURE
	var source_region := PRESSURE_PLATE_PRESSED_REGION if plate_pressed else PRESSURE_PLATE_RAISED_REGION
	var visual_width := size.x + 18.0
	var visual_height := visual_width * source_region.size.y / source_region.size.x
	var destination := Rect2(
		(size.x - visual_width) * 0.5,
		size.y - visual_height,
		visual_width,
		visual_height
	)
	draw_texture_rect_region(texture, destination, source_region, Color.WHITE)


func _draw_mechanism_door() -> void:
	# 门节点隐藏时贴图与碰撞会同时消失，因此这里只需要关闭状态。
	var visual_height := size.y + 8.0
	var visual_width := maxf(size.x + 40.0, visual_height * 0.49)
	var destination := Rect2(
		(size.x - visual_width) * 0.5,
		size.y - visual_height,
		visual_width,
		visual_height
	)
	draw_texture_rect_region(
		MECHANISM_DOOR_CLOSED_TEXTURE,
		destination,
		MECHANISM_DOOR_CLOSED_REGION,
		Color.WHITE
	)


func _draw_wood_gate() -> void:
	# 取木平台中连续的横梁区域分行平铺，避免把方形木箱非等比拉伸成墙体。
	var natural_row_height := size.x * WOOD_GATE_STRIP_REGION.size.y / WOOD_GATE_STRIP_REGION.size.x
	var row_count := maxi(1, ceili(size.y / natural_row_height))
	var row_height := size.y / float(row_count)
	draw_rect(Rect2(Vector2.ZERO, size), Color("251a12"))
	for row_index in range(row_count):
		draw_texture_rect_region(
			WOOD_FLOOR_TEXTURE,
			Rect2(0.0, row_index * row_height, size.x, row_height + 1.0),
			WOOD_GATE_STRIP_REGION,
			Color(0.78, 0.73, 0.66, 1.0)
		)


func _draw_wood_surface() -> void:
	# 碰撞仍使用原矩形；木材图片只负责呈现，不改变关卡尺寸。
	if size.x >= 260.0 or size.y >= 36.0:
		_draw_repeating_wood_floor()
	elif size.x <= 120.0:
		var visual_height := clampf(size.x * 0.68, 44.0, 72.0)
		draw_texture_rect_region(
			WOOD_BRACKET_PLATFORM_TEXTURE,
			Rect2(0.0, 0.0, size.x, visual_height),
			WOOD_BRACKET_PLATFORM_REGION,
			Color(0.82, 0.78, 0.72, 1.0)
		)
	else:
		var visual_height := clampf(size.x / 5.08, maxf(size.y, 30.0), 72.0)
		draw_texture_rect_region(
			WOOD_LONG_PLATFORM_TEXTURE,
			Rect2(0.0, 0.0, size.x, visual_height),
			WOOD_LONG_PLATFORM_REGION,
			Color(0.82, 0.78, 0.72, 1.0)
		)


func _draw_repeating_wood_floor() -> void:
	var segment_count := maxi(1, ceili(size.x / 360.0))
	var segment_width := size.x / float(segment_count)
	var visual_height := maxf(size.y, 54.0)
	for segment_index in range(segment_count):
		draw_texture_rect_region(
			WOOD_FLOOR_TEXTURE,
			Rect2(segment_index * segment_width, 0.0, segment_width + 1.0, visual_height),
			WOOD_FLOOR_REGION,
			Color(0.82, 0.78, 0.72, 1.0)
		)


func to_level_dictionary() -> Dictionary:
	var result := {
		"x": position.x,
		"y": position.y,
		"w": size.x,
		"h": size.y,
	}
	for key in get_meta_list():
		result[key] = get_meta(key)
	return result
