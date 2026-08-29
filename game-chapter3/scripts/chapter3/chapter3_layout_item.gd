@tool
class_name Chapter3LayoutItem
extends Node2D

## 第三章关卡中的可编辑矩形组件。
## 节点可以使用 StaticBody2D、CharacterBody2D 或 Area2D；本脚本负责编辑器预览
## 以及把位置、尺寸和元数据转换为现有玩法模拟所需的字典。

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


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), fill_color)
	draw_rect(Rect2(Vector2.ZERO, size), edge_color, false, edge_width)
	if label_text.is_empty():
		return
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(4.0, -6.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, edge_color)


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
