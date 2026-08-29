@tool
class_name Chapter3LevelLayout
extends Node2D

## 独立关卡场景的数据入口。关卡几何、机关、出生点和检查点均来自子节点，
## 主游戏不再把这些内容只藏在 chapter3.gd 的字典常量里。

@export var level_name := "关卡"
@export_multiline var objective := ""
@export var quote := ""
@export var world_width := 960.0
@export var background_color := Color("263b45"):
	set(value):
		background_color = value
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_rect(Rect2(0, 80, world_width, 440), background_color)
	draw_string(ThemeDB.fallback_font, Vector2(24, 112), "第三章 · %s" % level_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, Color(0.88, 0.93, 0.93, 0.72))


func to_level_definition() -> Dictionary:
	return {
		"name": level_name,
		"quote": quote,
		"world_w": world_width,
		"spawn": {
			"d": _marker_position("Markers/SpawnDaughter"),
			"m": _marker_position("Markers/SpawnMother"),
		},
		"checkpoints": _collect_checkpoints(),
		"statics": _collect_items("Platforms"),
		"walls": _collect_items("Walls"),
		"planks": _collect_items("Planks"),
		"boxes": _collect_items("Boxes"),
		"plates": _collect_items("Plates"),
		"doors": _collect_items("Doors"),
		"exit_x": _marker_position("Markers/Exit").x,
		"objective": objective,
	}


func _collect_items(path: NodePath) -> Array:
	var result: Array = []
	var container := get_node_or_null(path)
	if container == null:
		return result
	for child in container.get_children():
		if child.has_method("to_level_dictionary"):
			result.append(child.to_level_dictionary())
	return result


func _collect_checkpoints() -> Array:
	var result: Array = []
	var container := get_node_or_null("Markers/Checkpoints")
	if container == null:
		return result
	for child in container.get_children():
		result.append({
			"x": child.position.x,
			"d": child.get_meta(&"daughter_spawn", child.position),
			"m": child.get_meta(&"mother_spawn", child.position),
		})
	return result


func _marker_position(path: NodePath) -> Vector2:
	var marker := get_node_or_null(path) as Node2D
	return marker.position if marker != null else Vector2.ZERO
