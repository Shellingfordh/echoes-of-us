class_name Chapter3Game
extends Node2D

## 第三章《一起走一段》横版 2D 主体游戏。
## HTML 原型仅用于玩法与关卡结构；人物、场景和叙事延续第一、二章设定。

enum GameState { TITLE, PLAY, LEVEL_DONE, END }

const VIEW_W := 960.0
const VIEW_H := 540.0
const GRAVITY := 1500.0
const REST_DISTANCE := 260.0
const MAX_DISTANCE := 380.0
const HARD_DISTANCE := 495.0
const BOOST_VX := 200.0
const FALL_LIMIT := 1100.0

const END_SCRIPT := [
	"最后一批东西搬完了。",
	"余秀兰顺手捡起门边的黄伞。",
	"她把伞塞进最后一个没有合严的箱子。",
	"箱盖下面，只露出一角黄色。",
	"牵挂，也可以成为彼此的支点。",
	"第三章 · 一起走一段 · 完",
]

var game_state := GameState.TITLE
var level_index := 0
var levels: Array = []
var level: Dictionary = {}
var daughter: Dictionary = {}
var mother: Dictionary = {}
var characters: Array = []
var active_character := 0
var camera_position := Vector2.ZERO
var toasts: Array = []
var level_done_timer := 0.0
var end_timer := 0.0
var end_index := 0
var jump_queued := false
var switch_queued := false
var anchor_queued := false
var reset_queued := false
var debug_visible := false

var ui_font: Font = preload("res://art/fonts/NotoSansCJKsc-Regular.otf")
var player_walk_one: Texture2D = preload("res://art/playerGrey_walk1.png")
var player_walk_two: Texture2D = preload("res://art/playerGrey_walk2.png")
var player_anchor_pose: Texture2D = preload("res://art/playerGrey_up1.png")
var suitcase_texture: Texture2D = preload("res://art/suitcase.png")
var wooden_box_texture: Texture2D = preload("res://art/wooden-box.png")
var yellow_umbrella_texture: Texture2D = preload("res://art/cute-umbrella.png")


func _ready() -> void:
	daughter = _make_character("余念", 26.0, 38.0, 285.0, 560.0, Color("d5c4ba"), Color("d6a894"), false)
	mother = _make_character("余秀兰", 32.0, 48.0, 190.0, 470.0, Color("c7e8df"), Color("8fbeb1"), true)
	characters = [daughter, mother]
	levels = _create_levels()
	_load_level(0)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.is_action_pressed(&"debug_toggle"):
		debug_visible = not debug_visible
		get_viewport().set_input_as_handled()
		queue_redraw()
		return
	if game_state == GameState.TITLE:
		start_game()
		get_viewport().set_input_as_handled()
		return
	if game_state == GameState.END and event.is_action_pressed(&"reset_checkpoint"):
		start_game()
		get_viewport().set_input_as_handled()
		return
	if game_state != GameState.PLAY:
		return
	var handled := false
	if event.is_action_pressed(&"jump"):
		jump_queued = true
		handled = true
	if event.is_action_pressed(&"switch_character"):
		switch_queued = true
		handled = true
	if event.is_action_pressed(&"anchor"):
		anchor_queued = true
		handled = true
	if event.is_action_pressed(&"reset_checkpoint"):
		reset_queued = true
		handled = true
	if handled:
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	delta = minf(delta, 1.0 / 30.0)
	match game_state:
		GameState.TITLE:
			queue_redraw()
			return
		GameState.LEVEL_DONE:
			level_done_timer += delta
			_update_toasts(delta)
			if level_done_timer > 2.6:
				_load_level(level_index + 1)
				game_state = GameState.PLAY
				_toast("—— %s ——" % level["name"], 3.0)
			queue_redraw()
			return
		GameState.END:
			end_timer += delta
			if end_timer > 2.6 and end_index < END_SCRIPT.size() - 1:
				end_timer = 0.0
				end_index += 1
			queue_redraw()
			return

	_update_play(delta)
	queue_redraw()


func start_game() -> void:
	game_state = GameState.PLAY
	level_index = 0
	toasts.clear()
	_load_level(0)
	_toast("—— 楼道与出口 ——", 2.5)


func _make_character(
	name_text: String,
	width: float,
	height: float,
	speed: float,
	jump_velocity: float,
	color: Color,
	dark_color: Color,
	can_push: bool
) -> Dictionary:
	return {
		"name": name_text,
		"x": 0.0,
		"y": 0.0,
		"w": width,
		"h": height,
		"speed": speed,
		"jump_v": jump_velocity,
		"color": color,
		"dark": dark_color,
		"vx": 0.0,
		"vy": 0.0,
		"on_ground": false,
		"anchored": false,
		"face": 1.0,
		"can_push": can_push,
	}


func _create_levels() -> Array:
	return [
		{
			"name": "楼道与出口",
			"quote": "线不是限制，而是连接。",
			"world_w": 4300.0,
			"spawn": {"d": Vector2(220, 460), "m": Vector2(130, 460)},
			"checkpoints": [
				{"x": 1100.0, "d": Vector2(1300, 460), "m": Vector2(1230, 460)},
				{"x": 2150.0, "d": Vector2(2200, 460), "m": Vector2(2130, 460)},
				{"x": 3180.0, "d": Vector2(3250, 460), "m": Vector2(3180, 460)},
			],
			"statics": [
				_rect(0, 460, 1500, 60),
				_rect(1740, 400, 110, 14),
				_rect(1850, 460, 630, 60),
				_rect(2540, 376, 84, 14),
				_rect(2680, 292, 84, 14),
				_rect(2820, 376, 84, 14),
				_rect(2960, 292, 84, 14),
				_rect(3150, 460, 550, 60),
				_rect(3700, 520, 160, 30),
				_rect(3860, 460, 440, 60),
				_rect(3450, 370, 90, 14),
			],
			"walls": [],
			"planks": [
				{"x": 2500.0, "y": 460.0, "w": 560.0, "h": 16.0, "break_x": 2620.0, "break_by": "mother", "armed": false},
			],
			"boxes": [],
			"plates": [
				{"x": 1760.0, "y": 400.0, "w": 60.0},
				{"x": 3465.0, "y": 370.0, "w": 60.0},
				{"x": 3765.0, "y": 520.0, "w": 60.0},
			],
			"doors": [
				{"x": 2100.0, "y": 300.0, "w": 26.0, "h": 160.0, "plates": [0]},
				{"x": 3960.0, "y": 300.0, "w": 26.0, "h": 160.0, "plates": [1, 2]},
			],
			"exit_x": 4140.0,
			"objective": "一起向右走——感受线的距离。",
		},
		{
			"name": "仓库",
			"quote": "各尽所能，就是相互支撑。",
			"world_w": 3600.0,
			"spawn": {"d": Vector2(200, 460), "m": Vector2(120, 460)},
			"checkpoints": [
				{"x": 1450.0, "d": Vector2(1520, 460), "m": Vector2(1450, 460)},
				{"x": 2400.0, "d": Vector2(2460, 460), "m": Vector2(2400, 460)},
				{"x": 2900.0, "d": Vector2(2960, 460), "m": Vector2(2900, 460)},
			],
			"statics": [
				_rect(0, 460, 1100, 60),
				_rect(1400, 460, 1200, 60),
				_rect(2600, 560, 250, 30),
				_rect(2850, 460, 750, 60),
			],
			"walls": [_rect(1750, 300, 330, 118)],
			"planks": [],
			"boxes": [
				{"x": 640.0, "y": 404.0, "w": 56.0, "h": 56.0},
				{"x": 2480.0, "y": 404.0, "w": 56.0, "h": 56.0},
			],
			"plates": [
				{"x": 420.0, "y": 460.0, "w": 70.0},
				{"x": 2140.0, "y": 460.0, "w": 70.0},
			],
			"doors": [
				{"x": 1000.0, "y": 300.0, "w": 26.0, "h": 160.0, "plates": [0]},
				{"x": 2350.0, "y": 300.0, "w": 26.0, "h": 160.0, "plates": [1]},
			],
			"exit_x": 3450.0,
			"objective": "把箱子推上金色踏板，压住大门。（母亲能推动重物，女儿不行）",
		},
		{
			"name": "天台",
			"quote": "牵挂，也可以成为彼此的支点。",
			"world_w": 3400.0,
			"spawn": {"d": Vector2(200, 460), "m": Vector2(120, 460)},
			"checkpoints": [
				{"x": 1150.0, "d": Vector2(1030, 370), "m": Vector2(1000, 370)},
				{"x": 2050.0, "d": Vector2(2120, 130), "m": Vector2(2080, 130)},
			],
			"statics": [
				_rect(0, 460, 900, 60),
				_rect(980, 370, 170, 14),
				_rect(1300, 280, 170, 14),
				_rect(1720, 220, 170, 14),
				_rect(2000, 130, 1400, 40),
			],
			"walls": [],
			"planks": [],
			"boxes": [],
			"plates": [
				{"x": 2350.0, "y": 130.0, "w": 70.0},
				{"x": 2700.0, "y": 130.0, "w": 70.0},
			],
			"doors": [
				{"x": 2900.0, "y": -30.0, "w": 26.0, "h": 160.0, "plates": [0, 1]},
			],
			"exit_x": 3100.0,
			"objective": "台阶一节比一节高——交替锚定接龙：一人锚定，另一人借线上去，再回头拉对方",
		},
	]


func _rect(x: float, y: float, width: float, height: float) -> Dictionary:
	return {"x": x, "y": y, "w": width, "h": height}


func _load_level(index: int) -> void:
	level_index = clampi(index, 0, levels.size() - 1)
	var definition: Dictionary = levels[level_index]
	level = {
		"name": definition["name"],
		"quote": definition["quote"],
		"world_w": definition["world_w"],
		"spawn": definition["spawn"],
		"checkpoints": definition["checkpoints"],
		"statics": definition["statics"].duplicate(true),
		"walls": definition["walls"].duplicate(true),
		"planks": definition["planks"].duplicate(true),
		"boxes": definition["boxes"].duplicate(true),
		"plates": definition["plates"].duplicate(true),
		"doors": definition["doors"].duplicate(true),
		"exit_x": definition["exit_x"],
		"objective": definition["objective"],
		"stage": 0,
		"flags": {},
		"autofollow": false,
		"checkpoint_index": -1,
	}
	for plank in level["planks"]:
		plank["broken"] = false
		plank["creak"] = 0.0
	for box in level["boxes"]:
		box["vx"] = 0.0
		box["vy"] = 0.0
		box["push_dir"] = 0.0
	for plate in level["plates"]:
		plate["on"] = false
	for door in level["doors"]:
		door["open"] = false
	var spawn: Dictionary = level["spawn"]
	_place_at(spawn["d"], spawn["m"])
	camera_position = Vector2.ZERO
	jump_queued = false
	switch_queued = false
	anchor_queued = false
	reset_queued = false


func _place_at(daughter_feet: Vector2, mother_feet: Vector2) -> void:
	daughter["x"] = daughter_feet.x
	daughter["y"] = daughter_feet.y - daughter["h"]
	mother["x"] = mother_feet.x
	mother["y"] = mother_feet.y - mother["h"]
	for character in characters:
		character["vx"] = 0.0
		character["vy"] = 0.0
		character["anchored"] = false
		character["on_ground"] = true
	active_character = 0


func _update_play(delta: float) -> void:
	if reset_queued:
		reset_queued = false
		_respawn_checkpoint()
	if switch_queued:
		switch_queued = false
		_switch_active_character()
	if anchor_queued:
		anchor_queued = false
		_toggle_anchor()

	var active: Dictionary = characters[active_character]
	var other: Dictionary = characters[1 - active_character]
	var distance_before := _center(active).distance_to(_center(other))
	var speed_multiplier := 1.0
	if distance_before > REST_DISTANCE:
		speed_multiplier = maxf(0.45, 1.0 - 0.55 * (distance_before - REST_DISTANCE) / (MAX_DISTANCE - REST_DISTANCE))

	for index in range(characters.size()):
		var character: Dictionary = characters[index]
		if character["anchored"]:
			character["vx"] = 0.0
			character["vy"] = 0.0
			character["on_ground"] = true
			continue
		var direction := 0.0
		if index == active_character:
			direction = Input.get_axis(&"move_left", &"move_right")
		elif level["autofollow"] and character == mother:
			var follow_delta: float = _center(daughter).x - _center(mother).x
			if absf(follow_delta) > 50.0:
				direction = signf(follow_delta)
		if not is_zero_approx(direction):
			character["face"] = signf(direction)
		var acceleration := 2600.0 if character["on_ground"] else 1700.0
		var max_speed: float = character["speed"] * (speed_multiplier if index == active_character else minf(1.0, speed_multiplier + 0.2))
		if not is_zero_approx(direction) and (character["on_ground"] or absf(character["vx"]) < max_speed or signf(character["vx"]) != signf(direction)):
			character["vx"] += direction * acceleration * delta
		if character["on_ground"] and absf(character["vx"]) > max_speed:
			character["vx"] = signf(character["vx"]) * maxf(max_speed, absf(character["vx"]) - 3000.0 * delta)
		if is_zero_approx(direction) and character["on_ground"]:
			character["vx"] = move_toward(character["vx"], 0.0, 2400.0 * delta)
		character["vy"] = minf(character["vy"] + GRAVITY * delta, 1400.0)
		_move_collide(character, delta, direction)

	if jump_queued:
		jump_queued = false
		_perform_jump(active, other)

	var tether_distance := _center(daughter).distance_to(_center(mother))
	if not level["flags"].has("tension") and tether_distance > REST_DISTANCE:
		level["flags"]["tension"] = true
		_toast("线绷紧了——牵挂会影响距离，也会维持连接。", 4.0)
	_tether_constrain(daughter, mother, delta, active_character == 0)
	_tether_constrain(mother, daughter, delta, active_character == 1)
	_apply_ground_tether(delta)
	_capture_landings()
	_update_boxes(delta)
	_check_falls()
	_update_breakable_planks(delta)
	_update_plates_and_doors()
	_update_checkpoints()
	_update_level_specific(delta)
	_check_level_complete()
	_update_camera(delta)
	_update_toasts(delta)


func _perform_jump(active: Dictionary, other: Dictionary) -> void:
	if not active["on_ground"] or active["anchored"]:
		return
	active["vy"] = -active["jump_v"]
	active["on_ground"] = false
	if other["anchored"]:
		active["vx"] += active["face"] * BOOST_VX
		if not level["flags"].has("boost"):
			level["flags"]["boost"] = true
			_toast("借线一跳——对方锚定时，跳得更远（高度不变）。", 3.5)


func _switch_active_character() -> void:
	active_character = 1 - active_character
	_toast("切换到%s" % characters[active_character]["name"], 1.2)


func _toggle_anchor() -> void:
	var active: Dictionary = characters[active_character]
	if active["anchored"]:
		active["anchored"] = false
		_toast("%s松开了锚点" % active["name"], 1.5)
	elif active["on_ground"]:
		active["anchored"] = true
		active["vx"] = 0.0
		active["vy"] = 0.0
		_toast("%s锚定：成为对方的支点（再按 E 松开）" % active["name"], 2.5)


func _move_collide(character: Dictionary, delta: float, direction: float) -> void:
	character["x"] += character["vx"] * delta
	character["x"] = clampf(character["x"], 0.0, level["world_w"] - character["w"])
	for wall in _wall_list():
		if _overlap(character, wall):
			if character["vx"] > 0.0:
				character["x"] = wall["x"] - character["w"]
			elif character["vx"] < 0.0:
				character["x"] = wall["x"] + wall["w"]
			character["vx"] = 0.0
	for box in level["boxes"]:
		if not _overlap(character, box):
			continue
		var direction_to_box := signf(_center(box).x - _center(character).x)
		if character["can_push"] and character["on_ground"] and not is_zero_approx(direction_to_box) and signf(character["vx"] if not is_zero_approx(character["vx"]) else direction) == direction_to_box:
			box["push_dir"] = direction_to_box
			box["x"] = character["x"] + character["w"] if direction_to_box > 0.0 else character["x"] - box["w"]
		else:
			if character["vx"] > 0.0:
				character["x"] = box["x"] - character["w"]
			elif character["vx"] < 0.0:
				character["x"] = box["x"] + box["w"]
			character["vx"] = 0.0

	var previous_feet: float = character["y"] + character["h"]
	character["y"] += character["vy"] * delta
	character["on_ground"] = false
	for wall in _wall_list():
		if _overlap(character, wall):
			if character["vy"] > 0.0:
				character["y"] = wall["y"] - character["h"]
				character["on_ground"] = true
			elif character["vy"] < 0.0:
				character["y"] = wall["y"] + wall["h"]
			character["vy"] = 0.0
	if character["vy"] >= 0.0:
		for platform in _oneway_list(false):
			if character["x"] + character["w"] > platform["x"] and character["x"] < platform["x"] + platform["w"] and previous_feet <= platform["y"] + 1.0 and character["y"] + character["h"] >= platform["y"] and character["y"] + character["h"] <= platform["y"] + 40.0:
				character["y"] = platform["y"] - character["h"]
				character["vy"] = 0.0
				character["on_ground"] = true


func _update_boxes(delta: float) -> void:
	for index in range(level["boxes"].size()):
		var box: Dictionary = level["boxes"][index]
		if not is_zero_approx(box["push_dir"]):
			box["x"] += box["push_dir"] * 110.0 * delta
			box["push_dir"] = 0.0
		box["x"] = clampf(box["x"], 0.0, level["world_w"] - box["w"])
		for wall in _wall_list():
			if _overlap(box, wall):
				box["x"] = wall["x"] - box["w"] if _center(box).x < _center(wall).x else wall["x"] + wall["w"]
		var previous_feet: float = box["y"] + box["h"]
		box["vy"] = minf(box["vy"] + GRAVITY * delta, 1400.0)
		box["y"] += box["vy"] * delta
		if box["vy"] >= 0.0:
			for platform in _oneway_list(true):
				if box["x"] + box["w"] > platform["x"] and box["x"] < platform["x"] + platform["w"] and previous_feet <= platform["y"] + 1.0 and box["y"] + box["h"] >= platform["y"] and box["y"] + box["h"] <= platform["y"] + 40.0:
					box["y"] = platform["y"] - box["h"]
					box["vy"] = 0.0
		if box["y"] > FALL_LIMIT:
			var source_box: Dictionary = levels[level_index]["boxes"][index]
			box["x"] = source_box["x"]
			box["y"] = source_box["y"]
			box["vy"] = 0.0


func _tether_constrain(character: Dictionary, anchor: Dictionary, delta: float, is_active: bool) -> bool:
	if character["on_ground"] or character["anchored"] or not _supported(anchor):
		return false
	var offset := _center(character) - _center(anchor)
	var distance := maxf(offset.length(), 0.001)
	if is_active and Input.is_action_pressed(&"climb"):
		if distance > 90.0:
			character["vx"] -= offset.x / distance * 3000.0 * delta
			character["vy"] -= offset.y / distance * 3000.0 * delta
			character["vx"] += (_center(anchor).x - _center(character).x) * 2.5 * delta
		# W/↑ 同时也是地面跳跃键。两人并肩时不能立刻把刚起跳的人
		# 吸回地面；只有确实从高低差沿线抵达支点时才完成攀线吸附。
		elif anchor["on_ground"] and absf(_center(character).y - _center(anchor).y) > 24.0:
			character["x"] = anchor["x"] - character["w"] - 2.0 if _center(character).x < _center(anchor).x else anchor["x"] + anchor["w"] + 2.0
			character["y"] = anchor["y"] + anchor["h"] - character["h"]
			character["vx"] = 0.0
			character["vy"] = 0.0
	if distance <= MAX_DISTANCE + 8.0:
		return false
	var constrained_center := _center(anchor) + offset * (MAX_DISTANCE / distance)
	character["x"] = constrained_center.x - character["w"] * 0.5
	character["y"] = constrained_center.y - character["h"] * 0.5
	var radial_velocity: float = (character["vx"] * offset.x + character["vy"] * offset.y) / distance
	if radial_velocity > 0.0:
		character["vx"] -= offset.x / distance * radial_velocity
		character["vy"] -= offset.y / distance * radial_velocity
	return true


func _apply_ground_tether(delta: float) -> void:
	var offset := _center(daughter) - _center(mother)
	var distance := maxf(offset.length(), 0.001)
	if distance > MAX_DISTANCE and daughter["on_ground"] and mother["on_ground"]:
		if not level["flags"].has("over"):
			level["flags"]["over"] = true
			_toast("极限张力！线开始回拉——让对方靠近一点，或按 E 锚定。", 3.5)
		var pull := 2000.0 * delta
		if not daughter["anchored"]:
			daughter["vx"] += (-offset.x / distance) * pull
			daughter["vy"] += (-offset.y / distance) * pull * 0.2
		if not mother["anchored"]:
			mother["vx"] += (offset.x / distance) * pull
			mother["vy"] += (offset.y / distance) * pull * 0.2
		if distance > HARD_DISTANCE:
			var midpoint := (_center(daughter) + _center(mother)) * 0.5
			for character in characters:
				if character["anchored"]:
					continue
				var from_mid := _center(character) - midpoint
				var from_mid_length := maxf(from_mid.length(), 0.001)
				if from_mid_length > HARD_DISTANCE * 0.5:
					var wanted_center := midpoint + from_mid / from_mid_length * HARD_DISTANCE * 0.5
					character["x"] = wanted_center.x - character["w"] * 0.5
					character["y"] = wanted_center.y - character["h"] * 0.5
	elif distance < MAX_DISTANCE * 0.9:
		level["flags"].erase("over")


func _capture_landings() -> void:
	for character in characters:
		if character["anchored"] or character["on_ground"] or character["vy"] < 0.0:
			continue
		for platform in _oneway_list(false) + _wall_list():
			var feet: float = character["y"] + character["h"]
			if character["x"] + character["w"] > platform["x"] and character["x"] < platform["x"] + platform["w"] and feet >= platform["y"] and feet <= platform["y"] + 16.0:
				character["y"] = platform["y"] - character["h"]
				character["vy"] = 0.0
				character["on_ground"] = true
				break


func _check_falls() -> void:
	for index in range(characters.size()):
		var character: Dictionary = characters[index]
		if character["y"] <= FALL_LIMIT:
			continue
		var other: Dictionary = characters[1 - index]
		if _supported(other):
			character["y"] = 1000.0
			character["vy"] = -50.0
		else:
			_respawn_checkpoint()
			return


func _update_breakable_planks(delta: float) -> void:
	for plank in level["planks"]:
		if plank["broken"] or not plank["armed"]:
			continue
		var holder: Dictionary = mother if plank["break_by"] == "mother" else daughter
		var on_plank: bool = holder["on_ground"] and _center(holder).x > plank["x"] and _center(holder).x < plank["x"] + plank["w"] and absf(holder["y"] + holder["h"] - plank["y"]) < 4.0
		if on_plank and _center(holder).x > plank["break_x"]:
			plank["creak"] += delta
			if plank["creak"] > 0.9:
				plank["broken"] = true
				_toast("木板断了！让女儿站稳，Tab 切换母亲，按住 W 爬线。", 5.0)


func _update_plates_and_doors() -> void:
	for plate in level["plates"]:
		plate["on"] = false
		for character in characters:
			if character["on_ground"] and _center(character).x > plate["x"] and _center(character).x < plate["x"] + plate["w"] and absf(character["y"] + character["h"] - plate["y"]) < 6.0:
				plate["on"] = true
		for box in level["boxes"]:
			if _center(box).x > plate["x"] and _center(box).x < plate["x"] + plate["w"] and absf(box["y"] + box["h"] - plate["y"]) < 10.0:
				plate["on"] = true
	for door in level["doors"]:
		if door["open"]:
			continue
		var all_pressed := true
		for plate_index in door["plates"]:
			if not level["plates"][plate_index]["on"]:
				all_pressed = false
				break
		if all_pressed:
			door["open"] = true


func _update_checkpoints() -> void:
	for index in range(level["checkpoints"].size()):
		var checkpoint: Dictionary = level["checkpoints"][index]
		if index > level["checkpoint_index"] and _center(daughter).x > checkpoint["x"] and _center(mother).x > checkpoint["x"]:
			level["checkpoint_index"] = index
			_toast("✓ 检查点", 1.8)


func _respawn_checkpoint() -> void:
	var checkpoint_index: int = level["checkpoint_index"]
	var daughter_spawn: Vector2 = level["spawn"]["d"]
	var mother_spawn: Vector2 = level["spawn"]["m"]
	if checkpoint_index >= 0:
		var checkpoint: Dictionary = level["checkpoints"][checkpoint_index]
		daughter_spawn = checkpoint["d"]
		mother_spawn = checkpoint["m"]
	_place_at(daughter_spawn, mother_spawn)
	for index in range(level["planks"].size()):
		var plank: Dictionary = level["planks"][index]
		if plank["x"] > daughter_spawn.x - 100.0:
			plank["broken"] = false
			plank["creak"] = 0.0
			plank["armed"] = levels[level_index]["planks"][index]["armed"]
	for index in range(level["boxes"].size()):
		var box: Dictionary = level["boxes"][index]
		var source_box: Dictionary = levels[level_index]["boxes"][index]
		if source_box["x"] >= daughter_spawn.x - 100.0 or box["y"] > FALL_LIMIT:
			box["x"] = source_box["x"]
			box["y"] = source_box["y"]
			box["vx"] = 0.0
			box["vy"] = 0.0
	_toast("回到了最近的检查点", 2.0)


func _update_level_specific(_delta: float) -> void:
	match level_index:
		0:
			_update_level_one()
		1:
			_update_level_two()
		2:
			_update_level_three()


func _update_level_one() -> void:
	level["autofollow"] = level["stage"] == 0
	if level["stage"] == 0 and daughter["x"] > 1150.0 and mother["x"] > 1150.0:
		level["stage"] = 1
		level["objective"] = "前面的门锁了：母亲在断口边按 E 锚定，女儿借线跳上坑中高台"
		_toast("线第一次从‘绳子’变成‘道路’。", 3.5)
	if level["stage"] >= 2 and not level["planks"].is_empty():
		level["planks"][0]["armed"] = true
	if level["stage"] == 1 and level["doors"][0]["open"]:
		level["stage"] = 2
		level["objective"] = "门开了。女儿在对面锚定；母亲落下后按住 W 沿线爬回"
		_toast("锚定的人不动，线就成了另一个人的路。", 3.5)
	if level["stage"] == 2 and daughter["x"] > 3180.0 and mother["x"] > 3180.0 and daughter["on_ground"] and mother["on_ground"]:
		level["stage"] = 3
		level["objective"] = "终点大门：一人上高台、一人下凹坑，同时踩住两块踏板"
		_toast("楼下出口到了。两个人，一起用力。", 3.5)
	if level["stage"] == 3 and level["doors"][1]["open"]:
		level["stage"] = 4
		level["objective"] = "门开了——一起走出去 →"
		_toast("不是互相拉扯，而是共同用力。", 4.0)


func _update_level_two() -> void:
	var flags: Dictionary = level["flags"]
	if not flags.has("push") and absf(level["boxes"][0]["x"] - 640.0) > 12.0:
		flags["push"] = true
		_toast("女儿：这个我推不动。  母亲：……我来。", 3.5)
	if not flags.has("door1") and level["doors"][0]["open"]:
		flags["door1"] = true
		level["objective"] = "门压住了。前面断口：锚定 + 借跳 + 爬线"
		_toast("箱子压住了踏板，门不会关了。", 3.0)
	if not flags.has("gap") and daughter["x"] > 1400.0 and mother["x"] > 1400.0:
		flags["gap"] = true
		level["objective"] = "前面的通道太矮，只有女儿能过——去启动通道后的机关"
		_toast("余念：这里只有我能过，等我一下。高中姑娘在另一侧扶住了货架。", 4.5)
	if not flags.has("door2") and level["doors"][1]["open"]:
		flags["door2"] = true
		level["objective"] = "第二个坑太宽——母亲把箱子推下去垫脚"
		_toast("余念：这次我拉你。  余秀兰：不用，我自己行。", 4.0)
	if not flags.has("step") and level["boxes"][1]["y"] > 480.0:
		flags["step"] = true
		level["objective"] = "踩着箱子上对岸，一起走向出口 →"
		_toast("余秀兰停了一下，终于把手伸过来。", 4.0)


func _update_level_three() -> void:
	var flags: Dictionary = level["flags"]
	if not flags.has("start"):
		flags["start"] = true
		_toast("母亲：慢点，一个一个来。", 3.0)
	if not flags.has("frog") and daughter["on_ground"] and daughter["y"] + daughter["h"] <= 375.0:
		flags["frog"] = true
		_toast("女儿上去了。现在换她锚定，把母亲拉上来。", 4.0)
	if not flags.has("top") and daughter["y"] + daughter["h"] <= 135.0 and mother["y"] + mother["h"] <= 135.0 and daughter["on_ground"] and mother["on_ground"]:
		flags["top"] = true
		level["objective"] = "天台顶：两人分别站上两块金色踏板"
		_toast("远处，也有许多细小的红线在城市之间延伸。", 4.5)


func _check_level_complete() -> void:
	if _center(daughter).x <= level["exit_x"] or _center(mother).x <= level["exit_x"]:
		return
	if level_index < levels.size() - 1:
		game_state = GameState.LEVEL_DONE
		level_done_timer = 0.0
	else:
		game_state = GameState.END
		end_index = 0
		end_timer = -1.0


func _update_camera(delta: float) -> void:
	var midpoint := (_center(daughter) + _center(mother)) * 0.5
	var target_x: float = clampf(midpoint.x - VIEW_W * 0.5, 0.0, maxf(level["world_w"] - VIEW_W, 0.0))
	var target_y: float = clampf(midpoint.y - VIEW_H * 0.5 - 40.0, -260.0, 380.0)
	var weight := minf(1.0, 6.0 * delta)
	camera_position = camera_position.lerp(Vector2(target_x, target_y), weight)


func _toast(text: String, duration: float = 4.0) -> void:
	toasts.append({"text": text, "time": duration})


func _update_toasts(delta: float) -> void:
	for toast in toasts:
		toast["time"] -= delta
	for index in range(toasts.size() - 1, -1, -1):
		if toasts[index]["time"] <= 0.0:
			toasts.remove_at(index)


func _overlap(first: Dictionary, second: Dictionary) -> bool:
	return first["x"] < second["x"] + second["w"] and first["x"] + first["w"] > second["x"] and first["y"] < second["y"] + second["h"] and first["y"] + first["h"] > second["y"]


func _center(item: Dictionary) -> Vector2:
	return Vector2(item["x"] + item["w"] * 0.5, item["y"] + item["h"] * 0.5)


func _supported(character: Dictionary) -> bool:
	return character["on_ground"] or character["anchored"]


func _wall_list() -> Array:
	var walls: Array = level["walls"].duplicate(false)
	for door in level["doors"]:
		if not door["open"]:
			walls.append(door)
	return walls


func _oneway_list(for_box: bool) -> Array:
	var platforms: Array = level["statics"].duplicate(false)
	for plank in level["planks"]:
		if not plank["broken"]:
			platforms.append(plank)
	if not for_box:
		platforms.append_array(level["boxes"])
	return platforms


func get_progress_snapshot() -> Dictionary:
	return {
		"state": GameState.keys()[game_state],
		"level": level_index + 1,
		"level_name": level.get("name", ""),
		"stage": level.get("stage", 0),
		"checkpoint": level.get("checkpoint_index", -1),
		"active": characters[active_character]["name"] if not characters.is_empty() else "",
		"daughter": Vector2(daughter.get("x", 0.0), daughter.get("y", 0.0)),
		"mother": Vector2(mother.get("x", 0.0), mother.get("y", 0.0)),
	}


func debug_load_level(index: int) -> void:
	game_state = GameState.PLAY
	_load_level(index)


func debug_set_checkpoint(index: int) -> void:
	level["checkpoint_index"] = clampi(index, -1, level["checkpoints"].size() - 1)


func debug_respawn() -> void:
	_respawn_checkpoint()


func debug_toggle_anchor() -> void:
	_toggle_anchor()


func debug_switch_character() -> void:
	_switch_active_character()


func debug_jump() -> void:
	_perform_jump(characters[active_character], characters[1 - active_character])


func debug_update_plates_and_doors() -> void:
	_update_plates_and_doors()


func _draw() -> void:
	_draw_background()
	if game_state != GameState.TITLE:
		_draw_world()
		_draw_tether()
		_draw_character(daughter, active_character == 0)
		_draw_character(mother, active_character == 1)
	_draw_hud()


func _draw_background() -> void:
	var top_color := Color("1d303a")
	var bottom_color := Color("70818a")
	match level_index:
		1:
			top_color = Color("172932")
			bottom_color = Color("53656e")
		2:
			top_color = Color("304754")
			bottom_color = Color("94a3aa")
	for band in range(8):
		var color := top_color.lerp(bottom_color, float(band) / 7.0)
		draw_rect(Rect2(0, band * VIEW_H / 8.0, VIEW_W, VIEW_H / 8.0 + 1.0), color)
	if level_index == 2:
		for index in range(11):
			var building_x := fposmod(index * 180.0 - camera_position.x * 0.18, 2100.0) - 170.0
			var height := 90.0 + float((index * 47) % 120)
			draw_rect(Rect2(building_x, VIEW_H - 155.0 - height, 130.0, height + 155.0), Color(0.09, 0.16, 0.19, 0.55))
			for window_index in range(3):
				draw_rect(Rect2(building_x + 18.0 + window_index * 34.0, VIEW_H - height - 120.0, 10.0, 6.0), Color(0.82, 0.68, 0.40, 0.22))
	else:
		draw_rect(Rect2(0, 95, VIEW_W, 360), Color(0.05, 0.10, 0.12, 0.23))
		for seam in range(7):
			var seam_x := seam * 170.0 - fposmod(camera_position.x * 0.12, 170.0)
			draw_line(Vector2(seam_x, 95), Vector2(seam_x, 455), Color(0.66, 0.75, 0.78, 0.08), 2.0)


func _draw_world() -> void:
	_draw_scene_dressing()
	var floor_color := Color("53666d")
	var edge_color := Color("91a1a5")
	var wall_color := Color("43575e")
	if level_index == 1:
		floor_color = Color("475a61")
		edge_color = Color("819196")
		wall_color = Color("34474e")
	elif level_index == 2:
		floor_color = Color("64767d")
		edge_color = Color("aab6b9")
		wall_color = Color("4e626a")
	for platform in level["statics"]:
		var rect := _screen_rect(platform)
		draw_rect(rect, floor_color)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 6.0)), edge_color)
	for wall in level["walls"]:
		var rect := _screen_rect(wall)
		draw_rect(rect, wall_color)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5.0)), Color(1, 1, 1, 0.15))
	for plank in level["planks"]:
		if plank["broken"]:
			continue
		var shake: float = sin(Time.get_ticks_msec() / 40.0) * plank["creak"] * 3.0 if plank["creak"] > 0.0 else 0.0
		var rect := _screen_rect(plank)
		rect.position.x += shake
		draw_rect(rect, Color("a0522d") if plank["creak"] > 0.0 else Color("b07a45"))
		if plank["creak"] > 0.0:
			_draw_text("嘎吱……", Vector2(rect.get_center().x, rect.position.y - 10.0), 13, Color("c0392b"), HORIZONTAL_ALIGNMENT_CENTER, 90.0)
	for box in level["boxes"]:
		var rect := _screen_rect(box)
		draw_texture_rect(wooden_box_texture, rect.grow(5.0), false, Color(0.92, 0.92, 0.92, 1.0))
		draw_rect(rect.grow(2.0), Color("d0a261"), false, 2.0)
	for plate in level["plates"]:
		var rect := Rect2(plate["x"] - camera_position.x, plate["y"] - 8.0 - camera_position.y, plate["w"], 12.0)
		draw_rect(rect, Color("f1c40f") if plate["on"] else Color("c9b26b"))
		_draw_text("已压住" if plate["on"] else "踏板", Vector2(rect.get_center().x, rect.position.y - 6.0), 11, Color("7a6a3a"), HORIZONTAL_ALIGNMENT_CENTER, 80.0)
	for door in level["doors"]:
		var rect := _screen_rect(door)
		if door["open"]:
			draw_rect(rect, Color(0.58, 0.70, 0.72, 0.38), false, 3.0)
		else:
			draw_rect(rect, Color("2d4148"))
			draw_rect(Rect2(rect.position + Vector2(4, 0), Vector2(4, rect.size.y)), Color(1, 1, 1, 0.25))


func _draw_scene_dressing() -> void:
	match level_index:
		0:
			_draw_stairwell_dressing()
		1:
			_draw_warehouse_dressing()
		2:
			_draw_rooftop_dressing()


func _draw_stairwell_dressing() -> void:
	# 黄伞与行李延续前两章，并明确第三章从现实时间重新开始。
	_draw_world_texture(yellow_umbrella_texture, Rect2(245, 396, 60, 60), Color.WHITE)
	_draw_world_texture(suitcase_texture, Rect2(330, 404, 54, 54), Color(0.82, 0.88, 0.90))
	for lamp_x in [520.0, 1320.0, 2220.0, 3320.0, 4100.0]:
		var lamp_position := Vector2(lamp_x, 120.0) - camera_position
		var midpoint_x: float = (_center(daughter).x + _center(mother).x) * 0.5
		var lit := absf(midpoint_x - lamp_x) < 430.0
		if lit:
			draw_circle(lamp_position, 95.0, Color(0.96, 0.79, 0.44, 0.10))
		draw_rect(Rect2(lamp_position - Vector2(30, 7), Vector2(60, 14)), Color("efd8a1") if lit else Color("6d7e82"))
	# 老楼道的栏杆、信箱与剥落墙皮。
	for rail_x in [1450.0, 2470.0, 3070.0, 3670.0]:
		var start := Vector2(rail_x, 350.0) - camera_position
		draw_line(start, start + Vector2(0, 108), Color("94a2a3"), 5.0)
		draw_line(start, start + Vector2(120, 38), Color("94a2a3"), 5.0)
	for mailbox_x in [760.0, 900.0, 1040.0]:
		var mailbox := Rect2(Vector2(mailbox_x, 270.0) - camera_position, Vector2(92, 62))
		draw_rect(mailbox, Color("52656b"))
		draw_rect(mailbox.grow(-7.0), Color("7c8b8e"), false, 2.0)
		draw_line(mailbox.position + Vector2(12, 21), mailbox.position + Vector2(80, 21), Color(0.82, 0.86, 0.84, 0.4), 2.0)


func _draw_warehouse_dressing() -> void:
	for shelf_x in [160.0, 1160.0, 2140.0, 3020.0]:
		var left: float = float(shelf_x) - camera_position.x
		for shelf_y in [190.0, 300.0, 410.0]:
			var y: float = float(shelf_y) - camera_position.y
			draw_line(Vector2(left, y), Vector2(left + 250.0, y), Color("74858a"), 7.0)
		for post_x in [0.0, 250.0]:
			draw_line(Vector2(left + post_x, 150.0 - camera_position.y), Vector2(left + post_x, 458.0 - camera_position.y), Color("4d6066"), 8.0)
		for roll_index in range(4):
			var roll_center := Vector2(left + 34.0 + roll_index * 55.0, 284.0 - camera_position.y)
			var roll_colors := [Color("a1877b"), Color("738b8f"), Color("84788e"), Color("a69a7d")]
			draw_circle(roll_center, 18.0, roll_colors[roll_index])
	# 帮忙扶住货架的高中姑娘是剧情配角，不是新的可操作人物。
	var helper_rect := Rect2(Vector2(1580.0, 398.0) - camera_position, Vector2(46, 62))
	draw_texture_rect(player_anchor_pose, helper_rect, false, Color("aab8c8"))
	_draw_text("帮忙的高中姑娘", Vector2(helper_rect.get_center().x, helper_rect.position.y - 8.0), 11, Color("d6e0e2"), HORIZONTAL_ALIGNMENT_CENTER, 120.0)


func _draw_rooftop_dressing() -> void:
	# 水箱与晾晒物来自第三章场景设定，色彩沿用当下时空的冷灰蓝。
	var tank := Rect2(Vector2(540.0, 315.0) - camera_position, Vector2(155, 142))
	draw_rect(tank, Color("455a61"))
	draw_rect(Rect2(tank.position - Vector2(8, 8), Vector2(tank.size.x + 16, 12)), Color("718187"))
	draw_line(tank.position + Vector2(24, tank.size.y), tank.position + Vector2(16, tank.size.y + 34), Color("3a4b50"), 8.0)
	draw_line(tank.position + Vector2(tank.size.x - 24, tank.size.y), tank.position + Vector2(tank.size.x - 16, tank.size.y + 34), Color("3a4b50"), 8.0)
	for line_y in [245.0, 285.0]:
		var start := Vector2(120.0, line_y) - camera_position
		var finish := Vector2(3200.0, line_y + 45.0) - camera_position
		draw_line(start, finish, Color("a8b4b5"), 2.0)
	for sheet_x in [820.0, 1180.0, 1540.0, 2500.0]:
		var sheet := Rect2(Vector2(sheet_x, 260.0) - camera_position, Vector2(105, 92))
		draw_colored_polygon(PackedVector2Array([sheet.position, sheet.position + Vector2(sheet.size.x, 5), sheet.end, sheet.position + Vector2(8, sheet.size.y)]), Color(0.78, 0.82, 0.80, 0.66))
	if level.get("flags", {}).has("top"):
		for index in range(5):
			var x := 2120.0 + index * 190.0 - camera_position.x
			var y := 5.0 + float((index * 31) % 70) - camera_position.y
			draw_line(Vector2(x, y), Vector2(x + 90.0, y - 28.0), Color(0.95, 0.25, 0.25, 0.52), 1.8)


func _draw_world_texture(texture: Texture2D, world_rect: Rect2, tint: Color) -> void:
	var screen_rect := Rect2(world_rect.position - camera_position, world_rect.size)
	draw_texture_rect(texture, screen_rect, false, tint)


func _draw_tether() -> void:
	var start := _center(daughter) - camera_position
	var finish := _center(mother) - camera_position
	var distance := start.distance_to(finish)
	var color := Color(0.75, 0.22, 0.17, 0.55)
	var width := 2.5
	if distance >= MAX_DISTANCE:
		color = Color(0.91, 0.30, 0.24, 1.0)
		width = 4.5
	elif distance >= REST_DISTANCE:
		color = Color(0.75, 0.22, 0.17, 0.9)
		width = 3.5
	var sag := (1.0 - distance / REST_DISTANCE) * 60.0 if distance < REST_DISTANCE else 0.0
	var control := (start + finish) * 0.5 + Vector2(0, sag)
	var points := PackedVector2Array()
	for index in range(25):
		var t := float(index) / 24.0
		points.append((1.0 - t) * (1.0 - t) * start + 2.0 * (1.0 - t) * t * control + t * t * finish)
	if distance >= MAX_DISTANCE:
		draw_polyline(points, Color(0.91, 0.30, 0.24, 0.22), 13.0, true)
	draw_polyline(points, color, width, true)


func _draw_character(character: Dictionary, is_active: bool) -> void:
	var screen_position := Vector2(character["x"], character["y"]) - camera_position
	var visual_size := Vector2(48, 60) if character == daughter else Vector2(56, 70)
	var visual_position := Vector2(
		screen_position.x + character["w"] * 0.5 - visual_size.x * 0.5,
		screen_position.y + character["h"] - visual_size.y
	)
	var visual_rect := Rect2(visual_position, visual_size)
	var texture := player_anchor_pose if character["anchored"] else player_walk_one
	if not character["anchored"] and absf(character["vx"]) > 30.0 and int(Time.get_ticks_msec() / 160) % 2 == 1:
		texture = player_walk_two
	draw_ellipse_shadow(Vector2(screen_position.x + character["w"] * 0.5, screen_position.y + character["h"] + 2.0), visual_size.x * 0.34)
	draw_texture_rect(texture, visual_rect, false, character["color"])
	_draw_text(character["name"], Vector2(screen_position.x + character["w"] * 0.5, visual_position.y - (16.0 if is_active else 6.0)), 12, Color("e3ecec") if is_active else character["dark"], HORIZONTAL_ALIGNMENT_CENTER, 82.0)
	if is_active:
		var top := visual_position.y - 13.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(screen_position.x + character["w"] * 0.5 - 6.0, top),
			Vector2(screen_position.x + character["w"] * 0.5 + 6.0, top),
			Vector2(screen_position.x + character["w"] * 0.5, top + 7.0),
		]), Color("ef5960"))
	if character["anchored"]:
		draw_arc(visual_rect.get_center(), visual_size.x * 0.55, 0.0, TAU, 28, Color(0.94, 0.35, 0.37, 0.40), 2.0)
		_draw_text("⚓ 锚定", Vector2(screen_position.x + character["w"] * 0.5, screen_position.y + character["h"] + 17.0), 13, Color("f0c07c"), HORIZONTAL_ALIGNMENT_CENTER, 90.0)


func draw_ellipse_shadow(center: Vector2, radius: float) -> void:
	draw_set_transform(center, 0.0, Vector2(1.0, 0.28))
	draw_circle(Vector2.ZERO, radius, Color(0.02, 0.04, 0.045, 0.32))
	draw_set_transform(Vector2.ZERO)


func _draw_hud() -> void:
	if game_state == GameState.PLAY:
		draw_rect(Rect2(0, 0, VIEW_W, 62), Color(0.025, 0.065, 0.075, 0.90))
		_draw_text("第三章 · 第 %d/3 关 · %s — %s" % [level_index + 1, level["name"], level["objective"]], Vector2(16, 25), 14, Color("edf3f2"))
		var distance := _center(daughter).distance_to(_center(mother))
		var line_state := "松弛" if distance < REST_DISTANCE else ("张力" if distance < MAX_DISTANCE else "极限张力")
		_draw_text("当前：%s（Tab 切换）  红线：%s  距离 %d / %d" % [characters[active_character]["name"], line_state, roundi(distance), int(MAX_DISTANCE)], Vector2(16, 49), 12, Color("b7c5c6"))
		draw_rect(Rect2(0, VIEW_H - 34, VIEW_W, 34), Color(0.025, 0.065, 0.075, 0.90))
		_draw_text("A/D 或 ←/→ 移动 · Space/W/↑ 跳跃 · E 锚定 · 空中 W/↑ 爬线 · R 检查点", Vector2(16, VIEW_H - 12), 12, Color("cad5d5"))
	_draw_toasts()
	if game_state == GameState.TITLE:
		_draw_title()
	elif game_state == GameState.LEVEL_DONE:
		_draw_level_done()
	elif game_state == GameState.END:
		_draw_ending()
	if debug_visible:
		_draw_debug()


func _draw_toasts() -> void:
	var visible_toasts := toasts.slice(maxi(0, toasts.size() - 3), toasts.size())
	for index in range(visible_toasts.size()):
		var toast: Dictionary = visible_toasts[index]
		var y := VIEW_H - 90.0 - (visible_toasts.size() - 1 - index) * 26.0
		var alpha := clampf(toast["time"], 0.0, 0.88)
		draw_rect(Rect2(70, y - 21, VIEW_W - 140, 27), Color(0.02, 0.05, 0.06, alpha * 0.76))
		_draw_text(toast["text"], Vector2(VIEW_W * 0.5, y), 15, Color(0.91, 0.95, 0.94, alpha), HORIZONTAL_ALIGNMENT_CENTER, 810.0)


func _draw_title() -> void:
	draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color(0.02, 0.06, 0.075, 0.82))
	draw_texture_rect(yellow_umbrella_texture, Rect2(334, 76, 72, 72), false, Color.WHITE)
	draw_texture_rect(suitcase_texture, Rect2(548, 84, 62, 62), false, Color(0.82, 0.88, 0.90))
	_draw_text("余响：牵挂", Vector2(VIEW_W * 0.5, 126), 34, Color("f2f5f3"), HORIZONTAL_ALIGNMENT_CENTER, 600.0)
	_draw_text("第三章 · 一起走一段", Vector2(VIEW_W * 0.5, 168), 22, Color("f0c471"), HORIZONTAL_ALIGNMENT_CENTER, 650.0)
	_draw_text("第二章的余响结束，余念在黄伞旁醒来。", Vector2(VIEW_W * 0.5, 215), 16, Color("d2dddc"), HORIZONTAL_ALIGNMENT_CENTER, 780.0)
	_draw_text("主街封路。14:05 的列车将近，她们只能穿过老楼和仓库。", Vector2(VIEW_W * 0.5, 244), 16, Color("d2dddc"), HORIZONTAL_ALIGNMENT_CENTER, 820.0)
	_draw_text("楼道 → 仓库 → 天台", Vector2(VIEW_W * 0.5, 294), 17, Color("b9c8c9"), HORIZONTAL_ALIGNMENT_CENTER, 760.0)
	_draw_text("Tab 换人 · E 锚定 · W/↑ 爬线 · R 回检查点", Vector2(VIEW_W * 0.5, 340), 15, Color("b9c8c9"), HORIZONTAL_ALIGNMENT_CENTER, 760.0)
	_draw_text("—— 按任意键开始 ——", Vector2(VIEW_W * 0.5, 400), 17, Color("f2f5f3"), HORIZONTAL_ALIGNMENT_CENTER, 500.0)


func _draw_level_done() -> void:
	var alpha := minf(1.0, level_done_timer / 0.6)
	draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color(0.02, 0.06, 0.075, 0.78 * alpha))
	_draw_text("第 %d 关 · %s · 完成" % [level_index + 1, level["name"]], Vector2(VIEW_W * 0.5, 230), 30, Color("eef3f2", alpha), HORIZONTAL_ALIGNMENT_CENTER, 700.0)
	_draw_text(level["quote"], Vector2(VIEW_W * 0.5, 278), 18, Color("f0c471", alpha), HORIZONTAL_ALIGNMENT_CENTER, 700.0)


func _draw_ending() -> void:
	draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color(0.02, 0.06, 0.075, 0.84))
	_draw_text("第三章 · 一起走一段", Vector2(VIEW_W * 0.5, 78), 28, Color("eef3f2"), HORIZONTAL_ALIGNMENT_CENTER, 700.0)
	# 先画黄伞，再以箱子遮住，只留下未合严箱盖旁的一角黄色。
	draw_texture_rect(yellow_umbrella_texture, Rect2(416, 118, 92, 92), false, Color.WHITE)
	draw_texture_rect(wooden_box_texture, Rect2(452, 105, 126, 126), false, Color.WHITE)
	for index in range(mini(end_index + 1, END_SCRIPT.size())):
		var color := Color("eef3f2") if index == end_index else Color(0.76, 0.83, 0.82, 0.45)
		_draw_text(END_SCRIPT[index], Vector2(VIEW_W * 0.5, 270 + index * 31), 18 if index < 4 else 16, color, HORIZONTAL_ALIGNMENT_CENTER, 880.0)
	_draw_text("按 R 重新开始", Vector2(VIEW_W * 0.5, 505), 13, Color("b8c5c5"), HORIZONTAL_ALIGNMENT_CENTER, 300.0)


func _draw_debug() -> void:
	draw_rect(Rect2(12, 68, 350, 142), Color(0.02, 0.04, 0.035, 0.86))
	var snapshot := get_progress_snapshot()
	var lines := [
		"[F3] DEBUG",
		"state %s · level %d · stage %d" % [snapshot["state"], snapshot["level"], snapshot["stage"]],
		"checkpoint %d · active %s" % [snapshot["checkpoint"], snapshot["active"]],
		"daughter (%.1f, %.1f)" % [daughter["x"], daughter["y"]],
		"mother   (%.1f, %.1f)" % [mother["x"], mother["y"]],
		"flags %s" % str(level.get("flags", {})),
	]
	for index in range(lines.size()):
		_draw_text(lines[index], Vector2(24, 91 + index * 21), 13, Color("a6ddc4"))


func _screen_rect(item: Dictionary) -> Rect2:
	return Rect2(item["x"] - camera_position.x, item["y"] - camera_position.y, item["w"], item["h"])


func _draw_text(
	text: String,
	position: Vector2,
	size: int,
	color: Color,
	alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
	width: float = -1.0
) -> void:
	var draw_position := position
	if alignment == HORIZONTAL_ALIGNMENT_CENTER and width > 0.0:
		draw_position.x -= width * 0.5
	draw_string(ui_font, draw_position, text, alignment, width, size, color)
