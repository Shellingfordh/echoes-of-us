extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/chapter3/chapter3.tscn") as PackedScene
	var chapter := packed.instantiate() as Chapter3Game
	root.add_child(chapter)
	await process_frame
	chapter.start_game()

	var mapping_checks := [
		[&"move_left", KEY_A],
		[&"move_left", KEY_LEFT],
		[&"move_right", KEY_D],
		[&"move_right", KEY_RIGHT],
		[&"jump", KEY_SPACE],
		[&"jump", KEY_W],
		[&"jump", KEY_UP],
		[&"climb", KEY_W],
		[&"climb", KEY_UP],
		[&"switch_character", KEY_TAB],
		[&"anchor", KEY_E],
		[&"reset_checkpoint", KEY_R],
		[&"debug_toggle", KEY_F3],
		[&"start_game", KEY_ENTER],
	]
	for check in mapping_checks:
		var action: StringName = check[0]
		var key: Key = check[1]
		var event := _key_event(key, true)
		_expect(event.is_action_pressed(action), "%s 没有映射到 %s" % [OS.get_keycode_string(key), action])
	_expect(not _key_event(KEY_SPACE, true).is_action_pressed(&"climb"), "Space 不应映射到攀线动作")

	# 四个水平移动键：验证真实输入会驱动角色，而不只是配置表存在。
	for check in [[KEY_D, 1.0], [KEY_RIGHT, 1.0], [KEY_A, -1.0], [KEY_LEFT, -1.0]]:
		chapter.debug_load_level(0)
		var start_x: float = chapter.daughter["x"]
		await _hold_key(check[0], 4)
		var moved: float = chapter.daughter["x"] - start_x
		_expect(moved * check[1] > 0.5, "%s 没有驱动当前角色移动" % OS.get_keycode_string(check[0]))

	# 三个跳跃键：必须触发固定高度跳跃。
	for key in [KEY_SPACE, KEY_W, KEY_UP]:
		chapter.debug_load_level(0)
		await _hold_key(key, 1)
		_expect(chapter.daughter["vy"] < -400.0, "%s 没有触发女儿跳跃" % OS.get_keycode_string(key))

	# W：人在空中且与支点有高低差时，必须真正沿线接近支点。
	chapter.debug_load_level(0)
	chapter.mother["anchored"] = true
	chapter.daughter["x"] = 650.0
	chapter.daughter["y"] = 590.0
	chapter.daughter["on_ground"] = false
	chapter.daughter["vy"] = 0.0
	var climb_distance_before: float = chapter._center(chapter.daughter).distance_to(chapter._center(chapter.mother))
	await _hold_key(KEY_W, 4)
	var climb_distance_after: float = chapter._center(chapter.daughter).distance_to(chapter._center(chapter.mother))
	_expect(climb_distance_after < climb_distance_before - 1.0, "W 没有让空中角色沿线接近支点")

	# Tab：切到母亲。
	chapter.debug_load_level(0)
	await _hold_key(KEY_TAB, 1)
	_expect(chapter.active_character == 1, "Tab 没有切换到母亲")

	# E：当前角色在地面时进入锚定。
	await _hold_key(KEY_E, 1)
	_expect(chapter.mother["anchored"], "E 没有锚定母亲")

	# R：回到最近检查点。
	chapter.debug_set_checkpoint(0)
	chapter.daughter["x"] = 3000.0
	chapter.mother["x"] = 3000.0
	await _hold_key(KEY_R, 1)
	_expect(is_equal_approx(chapter.daughter["x"], 1300.0), "R 没有恢复女儿到检查点")
	_expect(absf(chapter.mother["x"] - 1230.0) < 5.0, "R 没有恢复母亲到检查点")

	# F3：调试层即时开关。
	var previous_debug: bool = chapter.debug_visible
	await _hold_key(KEY_F3, 0)
	_expect(chapter.debug_visible != previous_debug, "F3 没有切换调试层")

	# Enter：标题页进入游戏；同时验证全局 _input 不受 UI 焦点影响。
	chapter.game_state = 0
	await _hold_key(KEY_ENTER, 0)
	_expect(chapter.game_state == 1, "Enter 没有从标题页开始游戏")

	if failures.is_empty():
		print("[CHAPTER03_INPUT] PASS A/D/arrows, Space/W/Up, Tab, E, R, F3, Enter")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _key_event(key: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = pressed
	return event


func _hold_key(key: Key, physics_frames: int) -> void:
	Input.parse_input_event(_key_event(key, true))
	await process_frame
	for _frame in range(physics_frames):
		await physics_frame
	Input.parse_input_event(_key_event(key, false))
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
