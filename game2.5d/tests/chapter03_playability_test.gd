extends SceneTree

var chapter: Chapter3Game
var failures: Array[String] = []


func _initialize() -> void:
	# 仅加速测试墙钟时间；4 倍物理帧率抵消 4 倍 time_scale，单步仍为 1/60 秒。
	Engine.physics_ticks_per_second = 240
	Engine.time_scale = 4.0
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/chapter3/chapter3.tscn") as PackedScene
	chapter = packed.instantiate() as Chapter3Game
	root.add_child(chapter)
	await process_frame
	await _play_stairwell()
	if failures.is_empty():
		await _play_warehouse()
	if failures.is_empty():
		await _play_rooftop()

	_release_all()
	if failures.is_empty():
		print("[CHAPTER03_PLAYABILITY] PASS all 3 levels solved through gameplay motion")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _play_warehouse() -> void:
	chapter.debug_load_level(1)

	# 女儿先走到重箱前，母亲再跳到箱子右侧并向左推到专用踏板。
	await _walk_to(chapter.daughter, 590.0)
	await _switch_to(1)
	await _walk_to(chapter.mother, 730.0, true)
	await _hold_until(&"move_left", func() -> bool: return chapter.level["doors"][0]["open"], 260, "母亲未能把重箱推到踏板并打开首门")
	_expect(chapter.level["plates"][0]["on"], "重箱到位后首踏板没有触发")

	# 两人从首门前依次借锚定跳过断口。
	await _switch_to(0)
	await _walk_to(chapter.daughter, 900.0)
	await _switch_to(1)
	await _walk_to(chapter.mother, 1040.0)
	await _set_anchor(1, true)
	await _switch_to(0)
	await _walk_to(chapter.daughter, 1145.0)
	await _jump_walk_to(chapter.daughter, 1430.0, 220, 0)
	await _set_anchor(0, true)
	await _switch_to(1)
	await _set_anchor(1, false)
	await _walk_to(chapter.mother, 1145.0)
	await _jump_walk_to(chapter.mother, 1430.0, 240, 0)

	# 女儿穿过低闸门启动机关；闸门升起后母亲必须能正常走过，不能靠穿墙。
	await _switch_to(0)
	await _set_anchor(0, false)
	await _walk_to(chapter.daughter, 2160.0)
	_expect(chapter.level["doors"][1]["open"], "女儿到达低通道后踏板却没有打开机关门")
	_expect(not chapter._wall_list().has(chapter.level["walls"][0]), "机关打开后低闸门仍在阻挡")
	await _walk_to(chapter.daughter, 2420.0)
	await _switch_to(1)
	await _walk_to(chapter.mother, 2420.0)

	# 母亲推动第二只箱子落坑，两人依次借它上到出口侧。
	await _hold_until(&"move_right", func() -> bool: return chapter.level["boxes"][1]["y"] > 480.0, 260, "第二只箱子未能被推入垫脚坑")
	await _wait_until(func() -> bool: return is_zero_approx(chapter.level["boxes"][1]["vy"]) and chapter.mother["on_ground"], 160, "垫脚箱或母亲没有落稳在坑底")
	await _walk_to(chapter.mother, chapter.level["boxes"][1]["x"] - chapter.mother["w"] - 1.0)
	await _walk_to(chapter.mother, 2710.0)
	await _wait_until(func() -> bool: return chapter.mother["on_ground"], 120, "母亲没有在垫脚坑底站稳")
	await _set_anchor(1, true)
	await _switch_to(0)
	await _jump_walk_to(chapter.daughter, 2670.0, 220)
	await _jump_walk_to(chapter.daughter, 2770.0, 140, 0)
	await _jump_walk_to(chapter.daughter, 2900.0, 180, 0)
	await _set_anchor(0, true)
	await _switch_to(1)
	await _set_anchor(1, false)
	await _jump_walk_to(chapter.mother, 2770.0, 140, 0)
	await _jump_walk_to(chapter.mother, 2900.0, 200, 0)

	# 保持在牵挂距离内，交替向出口推进。
	await _switch_to(0)
	await _set_anchor(0, false)
	await _walk_to(chapter.daughter, 3250.0)
	await _switch_to(1)
	await _walk_to(chapter.mother, 3250.0)
	await _switch_to(0)
	await _walk_to(chapter.daughter, 3480.0)
	await _switch_to(1)
	await _hold_until(&"move_right", func() -> bool: return chapter.game_state != Chapter3Game.GameState.PLAY or chapter.level_index > 1, 240, "母亲到达出口后没有触发第二关完成")
	_expect(chapter.game_state == Chapter3Game.GameState.LEVEL_DONE or chapter.level_index > 1, "两人正常到达仓库出口后没有完成第二关")


func _play_stairwell() -> void:
	chapter.debug_load_level(0)

	# 开场同行，随后在第一处断口完成锚定借跳教学。
	await _walk_to(chapter.daughter, 1400.0)
	await _wait_until(func() -> bool: return chapter.mother["x"] > 1160.0, 160, "自动跟随的母亲没有赶上女儿")
	_expect(chapter.level["stage"] >= 1, "第一关同行教学没有推进到锚定阶段：女儿 x=%.1f，母亲 x=%.1f" % [chapter.daughter["x"], chapter.mother["x"]])
	if not failures.is_empty():
		return
	await _switch_to(1)
	await _walk_to(chapter.mother, 1450.0)
	await _set_anchor(1, true)
	await _switch_to(0)
	await _walk_to(chapter.daughter, 1450.0)
	await _jump_walk_to(chapter.daughter, 1770.0, 220, 0)
	_expect(chapter.level["doors"][0]["open"], "女儿落上高台踏板后教学门没有打开")
	await _set_anchor(0, true)
	await _switch_to(1)
	await _set_anchor(1, false)
	await _climb_to(chapter.mother, 410.0, 240)
	await _walk_to(chapter.mother, 2180.0)
	await _switch_to(0)
	await _set_anchor(0, false)
	await _walk_to(chapter.daughter, 2180.0)

	# 女儿先走断板上方的小台阶，母亲触发断板后沿线爬回。
	await _switch_to(1)
	await _walk_to(chapter.mother, 2450.0)
	await _jump_walk_to(chapter.mother, 2520.0, 140)
	await _walk_to(chapter.mother, 2600.0)
	await _wait_until(func() -> bool: return chapter.mother["on_ground"], 80, "母亲没有在断板前站稳")
	await _set_anchor(1, true)
	await _switch_to(0)
	await _walk_to(chapter.daughter, 2460.0)
	await _jump_walk_to(chapter.daughter, 2960.0, 320)
	await _set_anchor(0, true)
	await _switch_to(1)
	await _set_anchor(1, false)
	await _hold_until(&"move_right", func() -> bool: return chapter.level["planks"][0]["broken"], 180, "母亲走上断板后木板没有断裂")
	await _climb_to(chapter.mother, 330.0, 240)

	# 两人抵达终门，一上一下同时踩板，随后共同离开。
	await _switch_to(0)
	await _set_anchor(0, false)
	await _jump_walk_to(chapter.daughter, 3220.0, 220)
	await _switch_to(1)
	await _walk_to(chapter.mother, 3220.0, true)
	await _switch_to(0)
	await _walk_to(chapter.daughter, 3400.0)
	await _jump_onto_plate(chapter.daughter, 1, 3, 160)
	await _set_anchor(0, true)
	await _switch_to(1)
	await _walk_to(chapter.mother, 3770.0)
	await _wait_until(func() -> bool: return chapter.mother["on_ground"], 100, "母亲没有落到终门下层踏板")
	_expect(chapter.level["doors"][1]["open"], "第一关高低双踏板同时占用后终门没有打开：女儿脚部 y=%.1f，母亲脚部 y=%.1f" % [chapter.daughter["y"] + chapter.daughter["h"], chapter.mother["y"] + chapter.mother["h"]])
	await _switch_to(0)
	await _set_anchor(0, false)
	await _walk_to(chapter.daughter, 4000.0, true)
	await _switch_to(1)
	await _walk_to(chapter.mother, 3830.0)
	await _jump_walk_to(chapter.mother, 3900.0, 120, 0)
	await _walk_to(chapter.mother, 4000.0)
	await _switch_to(0)
	await _walk_to(chapter.daughter, 4160.0)
	await _switch_to(1)
	await _hold_until(&"move_right", func() -> bool: return chapter.game_state != Chapter3Game.GameState.PLAY or chapter.level_index > 0, 260, "两人到达第一关出口后没有完成关卡")
	_expect(chapter.game_state == Chapter3Game.GameState.LEVEL_DONE or chapter.level_index > 0, "第一关正常游玩未能完成")


func _play_rooftop() -> void:
	chapter.debug_load_level(2)
	_expect(chapter.level_index == 2, "第三关无法载入")

	# 女儿先上每一级，锚定后让母亲沿线爬上；随后交换支点继续接龙。
	await _switch_to(1)
	await _walk_to(chapter.mother, 830.0)
	await _set_anchor(1, true)
	await _switch_to(0)
	await _walk_to(chapter.daughter, 850.0)
	await _jump_land_on_static(chapter.daughter, 1, 180)
	_expect(absf(chapter.daughter["y"] + chapter.daughter["h"] - 370.0) < 4.0, "女儿没有落上天台第一级")
	await _set_anchor(0, true)
	await _switch_to(1)
	await _set_anchor(1, false)
	await _climb_to(chapter.mother, 375.0, 220)

	await _set_anchor(1, true)
	await _switch_to(0)
	await _set_anchor(0, false)
	await _walk_to(chapter.daughter, 1120.0)
	await _jump_land_on_static(chapter.daughter, 2, 180)
	_expect(absf(chapter.daughter["y"] + chapter.daughter["h"] - 280.0) < 4.0, "女儿没有落上天台第二级")
	await _set_anchor(0, true)
	await _switch_to(1)
	await _set_anchor(1, false)
	await _climb_to(chapter.mother, 285.0, 220)

	await _set_anchor(1, true)
	await _switch_to(0)
	await _set_anchor(0, false)
	await _walk_to(chapter.daughter, 1440.0)
	await _jump_land_on_static(chapter.daughter, 3, 220)
	_expect(absf(chapter.daughter["y"] + chapter.daughter["h"] - 220.0) < 4.0, "女儿没有落上天台第三级")
	await _set_anchor(0, true)
	await _switch_to(1)
	await _set_anchor(1, false)
	await _climb_to(chapter.mother, 225.0, 240)

	await _set_anchor(1, true)
	await _switch_to(0)
	await _set_anchor(0, false)
	await _walk_to(chapter.daughter, 1860.0)
	await _jump_land_on_static(chapter.daughter, 4, 200)
	_expect(absf(chapter.daughter["y"] + chapter.daughter["h"] - 130.0) < 4.0, "女儿没有登上天台最高处")
	await _set_anchor(0, true)
	await _switch_to(1)
	await _set_anchor(1, false)
	await _climb_to(chapter.mother, 135.0, 240)

	# 最高处双踏板开最终门，闩锁后两人共同走向结局。
	await _switch_to(0)
	await _set_anchor(0, false)
	await _walk_to(chapter.daughter, 2370.0)
	await _set_anchor(0, true)
	await _switch_to(1)
	await _walk_to(chapter.mother, 2720.0)
	_expect(chapter.level["doors"][0]["open"], "天台双踏板同时占用后最终门没有打开")
	await _switch_to(0)
	await _set_anchor(0, false)
	await _walk_to(chapter.daughter, 3000.0)
	await _switch_to(1)
	await _walk_to(chapter.mother, 3000.0)
	await _switch_to(0)
	await _walk_to(chapter.daughter, 3130.0)
	await _switch_to(1)
	await _hold_until(&"move_right", func() -> bool: return chapter.game_state == Chapter3Game.GameState.END, 180, "两人到达天台出口后没有进入第三章结局")
	_expect(chapter.game_state == Chapter3Game.GameState.END, "第三关正常游玩未能完成")


func _walk_to(character: Dictionary, target_x: float, auto_jump: bool = false, max_frames: int = 420) -> void:
	var direction_action: StringName = &"move_right" if character["x"] < target_x else &"move_left"
	_send_action(direction_action, true)
	var previous_x: float = character["x"]
	var stalled_frames := 0
	for frame in range(max_frames):
		if (direction_action == &"move_right" and character["x"] >= target_x) or (direction_action == &"move_left" and character["x"] <= target_x):
			break
		await physics_frame
		if absf(character["x"] - previous_x) < 0.05:
			stalled_frames += 1
		else:
			stalled_frames = 0
		previous_x = character["x"]
		if auto_jump and character["on_ground"] and (stalled_frames > 4 or frame % 42 == 20):
			chapter.debug_jump()
			await physics_frame
	_send_action(direction_action, false)
	_expect(absf(character["x"] - target_x) < 55.0, "%s 无法走到 x=%d，停在 %.1f" % [character["name"], roundi(target_x), character["x"]])


func _jump_walk_to(character: Dictionary, target_x: float, max_frames: int, runup_frames: int = 10) -> void:
	_send_action(&"move_right", true)
	# 先助跑到接近最高横向速度，再触发锚定借跳；否则 BOOST 会被普通加速上限吃掉。
	for _runup_frame in range(runup_frames):
		await physics_frame
	chapter.debug_jump()
	await physics_frame
	for frame in range(max_frames):
		if character["x"] >= target_x and character["on_ground"]:
			break
		await physics_frame
		if character["on_ground"] and frame % 10 == 0:
			chapter.debug_jump()
			await physics_frame
	_send_action(&"move_right", false)
	_expect(character["x"] >= target_x - 60.0 and character["on_ground"], "%s 无法跳到 x=%d，停在 (%.1f, %.1f)" % [character["name"], roundi(target_x), character["x"], character["y"]])


func _jump_land_on_static(character: Dictionary, static_index: int, max_frames: int) -> void:
	var platform: Dictionary = chapter.level["statics"][static_index]
	_send_action(&"move_right", true)
	chapter.debug_jump()
	for _frame in range(max_frames):
		# 一旦身体进入目标平台的水平范围就松开方向，模拟玩家收步落地；
		# 持续顶住方向会让绷紧的绳索把角色吊在平台边缘。
		if character["x"] + character["w"] >= platform["x"] + 8.0:
			break
		await physics_frame
	_send_action(&"move_right", false)
	await _wait_until(
		func() -> bool:
			return character["on_ground"] and absf(character["y"] + character["h"] - platform["y"]) < 4.0,
		max_frames,
		"%s 没有落到目标平台 %d" % [character["name"], static_index]
	)


func _hold_until(action: StringName, condition: Callable, max_frames: int, failure_message: String) -> void:
	_send_action(action, true)
	for _frame in range(max_frames):
		if condition.call():
			break
		await physics_frame
	_send_action(action, false)
	_expect(condition.call(), failure_message)


func _wait_until(condition: Callable, max_frames: int, failure_message: String) -> void:
	for _frame in range(max_frames):
		if condition.call():
			break
		await physics_frame
	_expect(condition.call(), failure_message)


func _climb_to(character: Dictionary, target_y: float, max_frames: int) -> void:
	if character["on_ground"]:
		chapter.debug_jump()
	Input.action_press(&"climb")
	for _frame in range(max_frames):
		if character["on_ground"] and character["y"] + character["h"] <= target_y + 12.0:
			break
		await physics_frame
	Input.action_release(&"climb")
	await _wait_until(func() -> bool: return character["on_ground"], 80, "%s 爬线抵达后没有站稳" % character["name"])
	_expect(character["on_ground"] and character["y"] + character["h"] <= target_y + 12.0, "%s 沿线攀爬失败，目标 y=%.1f，位置=(%.1f, %.1f)，脚部 y=%.1f" % [character["name"], target_y, character["x"], character["y"], character["y"] + character["h"]])


func _jump_onto_plate(character: Dictionary, plate_index: int, move_frames: int, max_frames: int) -> void:
	var plate: Dictionary = chapter.level["plates"][plate_index]
	await _wait_until(func() -> bool: return character["on_ground"] and absf(character["vx"]) < 5.0, 80, "%s 在踏板起跳前没有站稳" % character["name"])
	_send_action(&"move_right", true)
	chapter.debug_jump()
	for _frame in range(move_frames):
		await physics_frame
	_send_action(&"move_right", false)
	await _wait_until(func() -> bool: return character["on_ground"] and absf(character["y"] + character["h"] - plate["y"]) < 4.0, max_frames, "%s 没有落到踏板所在平台" % character["name"])
	await _walk_to(character, plate["x"] + plate["w"] * 0.5 - character["w"] * 0.5)
	await _wait_until(func() -> bool: return chapter.level["plates"][plate_index]["on"], max_frames, "%s 没有落到踏板 %d" % [character["name"], plate_index + 1])


func _switch_to(index: int) -> void:
	if chapter.active_character != index:
		chapter.debug_switch_character()
		await physics_frame
	_expect(chapter.active_character == index, "Tab 未切换到预期角色：需要 %d，当前 %d" % [index, chapter.active_character])


func _set_anchor(index: int, should_anchor: bool) -> void:
	await _switch_to(index)
	var character: Dictionary = chapter.characters[index]
	if character["anchored"] != should_anchor:
		chapter.debug_toggle_anchor()
		await physics_frame
	_expect(character["anchored"] == should_anchor, "%s锚定状态未切换为 %s，位置=(%.1f, %.1f)，on_ground=%s" % [character["name"], should_anchor, character["x"], character["y"], character["on_ground"]])


func _send_action(action: StringName, pressed: bool) -> void:
	var key_map := {
		&"move_left": KEY_A,
		&"move_right": KEY_D,
	}
	var event := InputEventKey.new()
	event.physical_keycode = key_map[action]
	event.pressed = pressed
	Input.parse_input_event(event)


func _physics_frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame


func _release_all() -> void:
	for action in [&"move_left", &"move_right"]:
		_send_action(action, false)
	Input.action_release(&"climb")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
