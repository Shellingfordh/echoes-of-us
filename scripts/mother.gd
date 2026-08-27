class_name EchoesMother
extends Node2D

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var breath := sin(_time * 1.6) * 1.2
	var body_color := Color("#9b695d")
	var outline_color := Color("#f1ddd1")
	var skin_color := Color("#e7bca7")

	draw_circle(Vector2(0.0, -24.0 + breath * 0.15), 11.0, skin_color)
	draw_circle(Vector2(0.0, -24.0 + breath * 0.15), 11.0, outline_color, false, 2.0, true)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-11.0, -12.0),
			Vector2(11.0, -12.0),
			Vector2(15.0 + breath, 17.0),
			Vector2(-15.0 - breath, 17.0),
		]),
		body_color
	)
	draw_line(Vector2(-8.0, 17.0), Vector2(-8.0, 31.0), outline_color, 4.0, true)
	draw_line(Vector2(8.0, 17.0), Vector2(8.0, 31.0), outline_color, 4.0, true)
	draw_circle(Vector2.ZERO, 32.0 + breath, Color(0.95, 0.66, 0.51, 0.06))
