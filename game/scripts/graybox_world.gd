class_name FullDemoWorld
extends Node2D

enum Layout {
	HOME,
	MEMORY_STREET,
	CORRIDOR,
	WAREHOUSE,
	ROOFTOP,
	STREET,
	RUN,
}

var layout := Layout.HOME
var stage := 0
var highlight_id := ""
var collected_ids: Dictionary = {}

var bicycle_position := Vector2(540.0, 470.0)
var box_one_position := Vector2(480.0, 470.0)
var box_two_position := Vector2(1160.0, 470.0)
var gate_one_open := false
var gate_two_open := false
var gap_filled := false
var anchor_index := 0
var stranger_line_visible := false
var key_connected := false
var cutaway_home := false
var ending_warmth := 0.0

var _elapsed := 0.0


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


func set_layout(next_layout: Layout) -> void:
	layout = next_layout
	stage = 0
	highlight_id = ""
	bicycle_position = Vector2(540.0, 470.0)
	box_one_position = Vector2(480.0, 470.0)
	box_two_position = Vector2(1160.0, 470.0)
	gate_one_open = false
	gate_two_open = false
	gap_filled = false
	anchor_index = 0
	stranger_line_visible = false
	key_connected = false
	cutaway_home = false
	queue_redraw()


func set_stage(next_stage: int) -> void:
	stage = next_stage
	queue_redraw()


func set_highlight(next_id: String) -> void:
	highlight_id = next_id


func mark_collected(item_id: String) -> void:
	collected_ids[item_id] = true


func is_collected(item_id: String) -> bool:
	return collected_ids.has(item_id)


func get_point(point_id: String) -> Vector2:
	match point_id:
		"box": return Vector2(250.0, 485.0)
		"suitcase": return Vector2(470.0, 485.0)
		"desk": return Vector2(680.0, 355.0)
		"chair": return Vector2(345.0, 365.0)
		"fragment_ticket": return Vector2(735.0, 365.0)
		"fragment_height": return Vector2(835.0, 420.0)
		"fragment_boots": return Vector2(930.0, 530.0)
		"fragment_frame": return Vector2(345.0, 290.0)
		"fragment_earphones": return Vector2(610.0, 555.0)
		"echo_kitchen": return Vector2(170.0, 340.0)
		"echo_door": return Vector2(1040.0, 420.0)
		"echo_hall": return Vector2(785.0, 520.0)
		"bicycle": return bicycle_position
		"puddle": return Vector2(830.0, 500.0)
		"cabinet": return Vector2(1080.0, 435.0)
		"memory_plate": return Vector2(1280.0, 515.0)
		"memory_lamp": return Vector2(1090.0, 455.0)
		"corridor_anchor_1": return Vector2(560.0, 470.0)
		"corridor_plate_1": return Vector2(820.0, 505.0)
		"corridor_anchor_2": return Vector2(1100.0, 470.0)
		"warehouse_box_1": return box_one_position
		"warehouse_plate_1": return Vector2(520.0, 345.0)
		"warehouse_crawl": return Vector2(790.0, 510.0)
		"warehouse_plate_2": return Vector2(1000.0, 510.0)
		"warehouse_box_2": return box_two_position
		"rooftop_anchor_1": return Vector2(410.0, 500.0)
		"rooftop_anchor_2": return Vector2(760.0, 420.0)
		"rooftop_anchor_3": return Vector2(1080.0, 340.0)
		"stranger": return Vector2(640.0, 480.0)
		"flowerbed": return Vector2(1030.0, 500.0)
		"street_exit": return Vector2(1390.0, 480.0)
	return Vector2.ZERO


func _draw() -> void:
	match layout:
		Layout.HOME:
			_draw_home()
		Layout.MEMORY_STREET:
			_draw_memory_street()
		Layout.CORRIDOR:
			_draw_corridor()
		Layout.WAREHOUSE:
			_draw_warehouse()
		Layout.ROOFTOP:
			_draw_rooftop()
		Layout.STREET:
			_draw_street()
		Layout.RUN:
			_draw_run()


func _draw_base(background: Color, floor_color: Color, width := 1600.0) -> void:
	draw_rect(Rect2(0.0, 0.0, width, 720.0), background)
	draw_rect(Rect2(0.0, 225.0, width, 420.0), floor_color)
	draw_rect(Rect2(0.0, 608.0, width, 37.0), floor_color.lightened(0.08))
	for x_position in range(0, int(width) + 1, 80):
		draw_line(Vector2(x_position, 258.0), Vector2(x_position, 608.0), Color(0.55, 0.52, 0.66, 0.07), 1.0)
	for y_position in range(288, 609, 64):
		draw_line(Vector2(0.0, y_position), Vector2(width, y_position), Color(0.55, 0.52, 0.66, 0.07), 1.0)


func _draw_home() -> void:
	_draw_base(Color("#161325"), Color("#242038"))
	draw_rect(Rect2(105.0, 270.0, 690.0, 315.0), Color("#29243b"), true)
	draw_rect(Rect2(1000.0, 263.0, 112.0, 345.0), Color("#302c42"), true)
	draw_rect(Rect2(1023.0, 288.0, 70.0, 320.0), Color("#4b4050"), true)
	draw_circle(Vector2(1078.0, 452.0), 5.0, Color("#f6d79a"))
	_label("女儿房间", Vector2(125.0, 305.0), Color("#8d849f"), 16)
	_label("玄关 / 门口 →", Vector2(930.0, 290.0), Color("#d6ae75"), 15)

	_draw_object("box", Rect2(205.0, 455.0, 90.0, 58.0), Color("#8a735f"), "打包纸箱")
	_draw_object("suitcase", Rect2(427.0, 442.0, 86.0, 74.0), Color("#77808c"), "行李箱")
	_draw_object("desk", Rect2(625.0, 320.0, 118.0, 52.0), Color("#675448"), "书桌")
	_draw_object("chair", Rect2(318.0, 340.0, 55.0, 58.0), Color("#705a45"), "木椅")
	draw_rect(Rect2(300.0, 276.0, 90.0, 20.0), Color("#55475d"), true)
	_label("衣柜顶部", Vector2(298.0, 268.0), Color("#81758e"), 11)
	draw_rect(Rect2(555.0, 525.0, 125.0, 45.0), Color("#493e58"), true)
	_label("床底", Vector2(586.0, 554.0), Color("#81758e"), 11)

	_draw_fragment("fragment_ticket", "MF-01 旧车票")
	_draw_fragment("fragment_height", "MF-02 身高刻度")
	_draw_fragment("fragment_boots", "MF-03 旧雨靴")
	_draw_fragment("fragment_frame", "MF-04 柜顶相框")
	_draw_fragment("fragment_earphones", "MF-05 床底耳机")

	for echo_id in ["echo_kitchen", "echo_door", "echo_hall"]:
		var point := get_point(echo_id)
		draw_arc(point, 24.0 + sin(_elapsed * 1.8) * 2.0, 0.0, TAU, 24, Color(0.76, 0.69, 0.88, 0.08), 1.0)


func _draw_memory_street() -> void:
	_draw_base(Color("#352d32"), Color("#514743"))
	for rain_x in range(40, 1580, 70):
		var offset := fmod(_elapsed * 170.0 + rain_x * 0.31, 280.0)
		draw_line(Vector2(rain_x, 235.0 + offset), Vector2(rain_x - 8.0, 255.0 + offset), Color(0.76, 0.83, 0.85, 0.22), 1.2)
	_label("童年记忆 · 雨中街道", Vector2(90.0, 285.0), Color("#f0c98f"), 17)

	draw_circle(bicycle_position + Vector2(-20.0, 14.0), 19.0, Color("#a4acb3"), false, 3.0)
	draw_circle(bicycle_position + Vector2(24.0, 14.0), 19.0, Color("#a4acb3"), false, 3.0)
	draw_line(bicycle_position + Vector2(-20.0, 14.0), bicycle_position + Vector2(3.0, -8.0), Color("#c6a76c"), 4.0)
	draw_line(bicycle_position + Vector2(3.0, -8.0), bicycle_position + Vector2(24.0, 14.0), Color("#c6a76c"), 4.0)
	if highlight_id == "bicycle":
		_glow(bicycle_position, 48.0, Color("#fff2be"))
	_label("倒下的自行车", bicycle_position + Vector2(-62.0, 55.0), Color("#d8cfc4"), 12)

	_draw_ellipse(get_point("puddle"), Vector2(95.0, 28.0), Color(0.32, 0.57, 0.68, 0.48))
	_label("水坑", get_point("puddle") + Vector2(-22.0, 48.0), Color("#a8cfd8"), 12)
	draw_rect(Rect2(1030.0, 330.0, 120.0, 220.0), Color("#676574"), true)
	draw_rect(Rect2(1060.0, 512.0, 62.0, 38.0), Color("#252331"), true)
	_label("快递柜 / 低矮缺口", Vector2(1008.0, 320.0), Color("#d8cfc4"), 12)
	if not gate_one_open:
		draw_rect(Rect2(1200.0, 300.0, 24.0, 308.0), Color("#8d6e66"), true)
	else:
		draw_rect(Rect2(1200.0, 300.0, 24.0, 38.0), Color("#be9a72"), true)
	_draw_plate(get_point("memory_plate"), gate_one_open)

	draw_line(Vector2(1090.0, 510.0), Vector2(1090.0, 350.0), Color("#796c60"), 8.0)
	draw_circle(Vector2(1090.0, 340.0), 18.0, Color("#efc36f"))
	if highlight_id == "memory_lamp" or stage >= 4:
		_glow(Vector2(1090.0, 355.0), 44.0, Color("#ffd47e"))
	draw_rect(Rect2(1160.0, 540.0, 145.0, 68.0), Color("#171520"), true)
	_label("施工断口", Vector2(1195.0, 530.0), Color("#b99f8b"), 12)


func _draw_corridor() -> void:
	_draw_base(Color("#121722"), Color("#252b37"))
	_label("现实 · 楼道合作", Vector2(95.0, 285.0), Color("#a7c8dd"), 17)
	draw_rect(Rect2(630.0, 530.0, 140.0, 78.0), Color("#0b0e14"), true)
	draw_rect(Rect2(1160.0, 530.0, 120.0, 78.0), Color("#0b0e14"), true)
	_draw_anchor(get_point("corridor_anchor_1"), 1, anchor_index >= 1)
	_draw_anchor(get_point("corridor_anchor_2"), 2, anchor_index >= 2)
	_draw_plate(get_point("corridor_plate_1"), gate_one_open)
	if not gate_one_open:
		draw_rect(Rect2(900.0, 300.0, 24.0, 308.0), Color("#597083"), true)
	if not gate_two_open:
		draw_rect(Rect2(1380.0, 300.0, 24.0, 308.0), Color("#597083"), true)
	_label("一人锚定 · 一人借线", Vector2(500.0, 330.0), Color("#8ca7b8"), 13)


func _draw_warehouse() -> void:
	_draw_base(Color("#171717"), Color("#303033"))
	_label("仓库 · 各尽所能", Vector2(95.0, 285.0), Color("#d3bc8d"), 17)
	_draw_crate(box_one_position, "重箱 1", highlight_id == "warehouse_box_1")
	_draw_plate(get_point("warehouse_plate_1"), gate_one_open)
	if not gate_one_open:
		draw_rect(Rect2(650.0, 300.0, 24.0, 308.0), Color("#625b54"), true)
	draw_rect(Rect2(760.0, 350.0, 120.0, 200.0), Color("#575354"), true)
	draw_rect(Rect2(790.0, 515.0, 58.0, 35.0), Color("#161616"), true)
	_label("窄道", Vector2(792.0, 342.0), Color("#b8ae9f"), 12)
	_draw_plate(get_point("warehouse_plate_2"), gate_two_open)
	_draw_crate(box_two_position, "重箱 2", highlight_id == "warehouse_box_2")
	draw_rect(Rect2(1270.0, 530.0, 150.0, 78.0), Color("#080808"), true)
	if gap_filled:
		draw_rect(Rect2(1305.0, 520.0, 72.0, 62.0), Color("#77614c"), true)
	_label("断口", Vector2(1318.0, 515.0), Color("#a99a88"), 12)


func _draw_rooftop() -> void:
	_draw_base(Color("#151b2c"), Color("#252d3d"))
	_label("天台 · 交替锚定", Vector2(95.0, 285.0), Color("#b6cae7"), 17)
	draw_rect(Rect2(320.0, 535.0, 260.0, 73.0), Color("#3d4657"), true)
	draw_rect(Rect2(650.0, 455.0, 255.0, 153.0), Color("#465064"), true)
	draw_rect(Rect2(970.0, 375.0, 250.0, 233.0), Color("#505b70"), true)
	draw_rect(Rect2(1280.0, 300.0, 210.0, 308.0), Color("#5a667c"), true)
	_draw_anchor(get_point("rooftop_anchor_1"), 1, anchor_index >= 1)
	_draw_anchor(get_point("rooftop_anchor_2"), 2, anchor_index >= 2)
	_draw_anchor(get_point("rooftop_anchor_3"), 3, anchor_index >= 3)
	_draw_plate(Vector2(1340.0, 335.0), gate_two_open)
	_draw_plate(Vector2(1420.0, 335.0), gate_two_open)
	_label("交替成为彼此的支点", Vector2(780.0, 315.0), Color("#91a8c6"), 13)


func _draw_street() -> void:
	_draw_base(Color("#17202a"), Color("#2f3a42"))
	_label("外面的世界", Vector2(95.0, 285.0), Color("#aed4d3"), 17)
	draw_rect(Rect2(960.0, 455.0, 150.0, 100.0), Color("#395a46"), true)
	for plant_x in range(980, 1100, 24):
		draw_circle(Vector2(plant_x, 450.0 + sin(float(plant_x)) * 5.0), 15.0, Color("#628568"))
	_label("花坛", Vector2(1010.0, 575.0), Color("#9fc3a2"), 12)

	if not key_connected:
		draw_circle(Vector2(640.0, 440.0), 10.0, Color("#d9c7bd"))
		draw_rect(Rect2(628.0, 451.0, 24.0, 42.0), Color("#6e7788"), true)
		_label("寻找钥匙的路人", Vector2(585.0, 525.0), Color("#aab5c6"), 12)
		if stranger_line_visible:
			draw_dashed_line(get_point("stranger"), get_point("flowerbed"), Color(0.78, 0.9, 0.86, 0.45), 2.0, 10.0)
			_glow(get_point("flowerbed"), 42.0, Color("#bfe6a6"))
		draw_circle(get_point("flowerbed"), 7.0, Color("#f5d67c"))
	else:
		_label("钥匙已经回到主人手中", Vector2(560.0, 515.0), Color("#d4e6d3"), 12)


func _draw_run() -> void:
	_draw_base(Color("#111a26"), Color("#293746"), 3200.0)
	for building_x in range(100, 3150, 180):
		var height := 95.0 + float((building_x * 13) % 140)
		draw_rect(Rect2(building_x, 225.0 - height, 110.0, height), Color(0.24, 0.3, 0.39, 0.54), true)
	for light_x in range(420, 3150, 260):
		draw_circle(Vector2(light_x, 350.0), 5.0, Color("#f4d38b"))
		draw_circle(Vector2(light_x, 350.0), 32.0, Color(0.96, 0.77, 0.46, 0.06))
	var horizon_color := Color("#e8edf3").lerp(Color("#f5d77f"), ending_warmth)
	draw_circle(Vector2(3020.0, 380.0), 170.0, Color(horizon_color, 0.18))
	_label("向外跑", Vector2(120.0, 285.0), horizon_color, 18)
	if cutaway_home:
		draw_rect(Rect2(1100.0, 270.0, 900.0, 300.0), Color(0.09, 0.07, 0.12, 0.95), true)
		_label("家中 · 母亲慢慢松开握线的手", Vector2(1190.0, 420.0), Color("#f0d6be"), 24)


func _draw_object(item_id: String, rect: Rect2, color: Color, label_text: String) -> void:
	draw_rect(rect, color, true)
	if not is_collected(item_id):
		var alpha := 0.13 if highlight_id != item_id else 0.3
		draw_rect(rect.grow(8.0), Color(0.95, 0.93, 1.0, alpha), false, 3.0)
	_label(label_text, rect.position + Vector2(0.0, rect.size.y + 20.0), color.lightened(0.45), 11)


func _draw_fragment(item_id: String, label_text: String) -> void:
	if is_collected(item_id):
		return
	var point := get_point(item_id)
	var pulse := 7.0 + sin(_elapsed * 3.0) * 2.0
	draw_circle(point, pulse, Color("#f4dc8b"))
	draw_circle(point, 20.0 + pulse, Color(0.95, 0.84, 0.46, 0.08))
	if highlight_id == item_id:
		_label(label_text, point + Vector2(-66.0, -24.0), Color("#f7e7ad"), 11)


func _draw_plate(point: Vector2, active: bool) -> void:
	var color := Color("#e7bd55") if active else Color("#67616b")
	draw_rect(Rect2(point - Vector2(38.0, 8.0), Vector2(76.0, 16.0)), color, true)


func _draw_anchor(point: Vector2, number: int, active: bool) -> void:
	var color := Color("#f2c46f") if active else Color("#71849a")
	draw_line(point + Vector2(0.0, 45.0), point + Vector2(0.0, -55.0), color, 7.0)
	draw_circle(point + Vector2(0.0, -62.0), 15.0, color)
	if active or highlight_id.ends_with(str(number)):
		_glow(point + Vector2(0.0, -50.0), 40.0, color)


func _draw_crate(point: Vector2, label_text: String, highlighted: bool) -> void:
	draw_rect(Rect2(point - Vector2(38.0, 36.0), Vector2(76.0, 72.0)), Color("#725f4b"), true)
	draw_line(point - Vector2(35.0, 33.0), point + Vector2(35.0, 33.0), Color("#a78a68"), 3.0)
	draw_line(point + Vector2(35.0, -33.0), point - Vector2(35.0, 33.0), Color("#a78a68"), 3.0)
	if highlighted:
		_glow(point, 52.0, Color("#f7d699"))
	_label(label_text, point + Vector2(-35.0, 58.0), Color("#cdb99d"), 11)


func _glow(point: Vector2, radius: float, color: Color) -> void:
	var pulse := 1.0 + sin(_elapsed * 2.7) * 0.08
	var glow_color := color
	glow_color.a = 0.14
	draw_circle(point, radius * pulse, glow_color)


func _label(text: String, position: Vector2, color: Color, font_size: int) -> void:
	draw_string(ThemeDB.fallback_font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var polygon := PackedVector2Array()
	for index in range(32):
		var angle := TAU * float(index) / 32.0
		polygon.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(polygon, color)
