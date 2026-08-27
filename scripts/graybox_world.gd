extends Node2D


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# Background and floor planes.
	draw_rect(Rect2(0.0, 0.0, 1600.0, 720.0), Color("#161325"))
	draw_rect(Rect2(0.0, 225.0, 1600.0, 420.0), Color("#242038"))
	draw_rect(Rect2(0.0, 608.0, 1600.0, 37.0), Color("#342b43"))

	# A quiet parallax-like skyline beyond the hallway windows.
	for index in range(10):
		var height := 72.0 + float((index * 37) % 95)
		var rect := Rect2(70.0 + index * 170.0, 225.0 - height, 112.0, height)
		draw_rect(rect, Color(0.18, 0.18, 0.28, 0.72))
		for window_index in range(3):
			draw_rect(
				Rect2(rect.position + Vector2(17.0 + window_index * 30.0, 20.0), Vector2(11.0, 16.0)),
				Color(0.95, 0.67, 0.34, 0.18 + window_index * 0.04)
			)

	# Floor guide lines make movement and distance readable in the graybox.
	for x_position in range(0, 1601, 80):
		draw_line(Vector2(x_position, 258.0), Vector2(x_position, 608.0), Color(0.44, 0.42, 0.56, 0.08), 1.0)
	for y_position in range(288, 609, 64):
		draw_line(Vector2(0.0, y_position), Vector2(1600.0, y_position), Color(0.44, 0.42, 0.56, 0.08), 1.0)

	# Home silhouettes: picture wall, cabinet, warm doorway, and exit.
	draw_rect(Rect2(118.0, 290.0, 205.0, 172.0), Color("#2c283e"), true)
	draw_rect(Rect2(142.0, 314.0, 66.0, 54.0), Color("#68556a"), true)
	draw_rect(Rect2(225.0, 314.0, 66.0, 54.0), Color("#755e58"), true)
	draw_rect(Rect2(690.0, 485.0, 170.0, 88.0), Color("#51465d"), true)
	draw_rect(Rect2(690.0, 476.0, 170.0, 12.0), Color("#71617c"), true)
	draw_rect(Rect2(1305.0, 263.0, 112.0, 345.0), Color("#302c42"), true)
	draw_rect(Rect2(1327.0, 288.0, 70.0, 320.0), Color("#4b4050"), true)
	draw_circle(Vector2(1380.0, 452.0), 5.0, Color("#f6d79a"))
	draw_rect(Rect2(1417.0, 263.0, 183.0, 345.0), Color(0.95, 0.68, 0.38, 0.07), true)

	# Warm route light from home to the exit.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(710.0, 608.0),
			Vector2(1425.0, 608.0),
			Vector2(1425.0, 292.0),
			Vector2(1010.0, 420.0),
		]),
		Color(1.0, 0.72, 0.42, 0.035)
	)
