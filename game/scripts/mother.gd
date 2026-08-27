class_name EchoesMother
extends Node2D

@export var role_name := "母亲"

var _time := 0.0
var _body_color := Color("#9b695d")
var _outline_color := Color("#f1ddd1")
var _actor_scale := 1.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _ready() -> void:
	set_role(role_name)


func set_role(next_role: String) -> void:
	role_name = next_role
	match role_name:
		"小女儿":
			_body_color = Color("#d5a24c")
			_outline_color = Color("#fff0b5")
			_actor_scale = 0.78
		"成年女儿":
			_body_color = Color("#607aa6")
			_outline_color = Color("#dce8f4")
			_actor_scale = 1.0
		_:
			_body_color = Color("#9b695d")
			_outline_color = Color("#f1ddd1")
			_actor_scale = 1.0
	queue_redraw()


func _draw() -> void:
	var breath := sin(_time * 1.6) * 1.2
	var body_color := _body_color
	var outline_color := _outline_color
	var skin_color := Color("#e7bca7")
	var size := _actor_scale

	draw_circle(Vector2(0.0, -24.0 * size + breath * 0.15), 11.0 * size, skin_color)
	draw_circle(Vector2(0.0, -24.0 * size + breath * 0.15), 11.0 * size, outline_color, false, 2.0, true)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-11.0, -12.0) * size,
			Vector2(11.0, -12.0) * size,
			Vector2(15.0 + breath, 17.0) * size,
			Vector2(-15.0 - breath, 17.0) * size,
		]),
		body_color
	)
	draw_line(Vector2(-8.0, 17.0) * size, Vector2(-8.0, 31.0) * size, outline_color, 4.0 * size, true)
	draw_line(Vector2(8.0, 17.0) * size, Vector2(8.0, 31.0) * size, outline_color, 4.0 * size, true)
	draw_circle(Vector2.ZERO, 32.0 * size + breath, Color(0.95, 0.66, 0.51, 0.06))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-52.0, -46.0 * size),
		role_name,
		HORIZONTAL_ALIGNMENT_CENTER,
		104.0,
		13,
		outline_color
	)
