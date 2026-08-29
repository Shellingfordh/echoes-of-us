extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/chapter3/chapter3.tscn") as PackedScene
	assert(packed != null)
	var chapter := packed.instantiate() as Chapter3Game
	root.add_child(chapter)
	await process_frame

	assert(chapter.game_state == Chapter3Game.GameState.TITLE)
	assert(chapter.levels.size() == 3)
	assert(chapter.levels[0]["name"] == "楼道与出口")
	assert(chapter.levels[1]["name"] == "仓库")
	assert(chapter.levels[2]["name"] == "天台")

	chapter.start_game()
	assert(chapter.game_state == Chapter3Game.GameState.PLAY)
	assert(chapter.level["checkpoints"].size() == 3)
	assert(chapter.level["doors"].size() == 2)
	assert(chapter.level["plates"].size() == 3)

	# 锚定只提供水平借力；垂直跳跃速度保持角色自身的固定值。
	chapter.mother["anchored"] = true
	chapter.daughter["on_ground"] = true
	chapter.daughter["face"] = 1.0
	chapter.daughter["vx"] = 0.0
	chapter.debug_jump()
	assert(is_equal_approx(chapter.daughter["vy"], -560.0))
	assert(is_equal_approx(chapter.daughter["vx"], Chapter3Game.BOOST_VX))

	# 检查点恢复到最近小关，而不是回关卡开头。
	chapter.debug_set_checkpoint(1)
	chapter.daughter["x"] = 3999.0
	chapter.mother["x"] = 3999.0
	chapter.debug_respawn()
	assert(is_equal_approx(chapter.daughter["x"], 2200.0))
	assert(is_equal_approx(chapter.mother["x"], 2130.0))

	# 楼道终点门必须由高台和凹坑两个踏板同时压住。
	chapter.daughter["x"] = 3465.0 + 30.0 - chapter.daughter["w"] * 0.5
	chapter.daughter["y"] = 370.0 - chapter.daughter["h"]
	chapter.daughter["on_ground"] = true
	chapter.mother["x"] = 3765.0 + 30.0 - chapter.mother["w"] * 0.5
	chapter.mother["y"] = 520.0 - chapter.mother["h"]
	chapter.mother["on_ground"] = true
	chapter.debug_update_plates_and_doors()
	assert(chapter.level["plates"][1]["on"])
	assert(chapter.level["plates"][2]["on"])
	assert(chapter.level["doors"][1]["open"])

	chapter.debug_load_level(1)
	assert(chapter.level["boxes"].size() == 2)
	assert(chapter.mother["can_push"])
	assert(not chapter.daughter["can_push"])
	assert(chapter.level["walls"][0]["h"] == 118.0)

	# 女儿会被重箱挡住，母亲能推动；低矮通道只允许女儿通过。
	var first_box: Dictionary = chapter.level["boxes"][0]
	chapter.daughter["x"] = first_box["x"] - chapter.daughter["w"] - 2.0
	chapter.daughter["y"] = 460.0 - chapter.daughter["h"]
	chapter.daughter["vx"] = 120.0
	chapter.daughter["on_ground"] = true
	chapter._move_collide(chapter.daughter, 0.05, 1.0)
	assert(is_zero_approx(first_box["push_dir"]))
	chapter.mother["x"] = first_box["x"] - chapter.mother["w"] - 2.0
	chapter.mother["y"] = 460.0 - chapter.mother["h"]
	chapter.mother["vx"] = 120.0
	chapter.mother["on_ground"] = true
	chapter._move_collide(chapter.mother, 0.05, 1.0)
	assert(first_box["push_dir"] > 0.0)

	chapter.daughter["x"] = 1725.0
	chapter.daughter["y"] = 460.0 - chapter.daughter["h"]
	chapter.daughter["vx"] = 200.0
	chapter._move_collide(chapter.daughter, 0.2, 1.0)
	assert(chapter.daughter["x"] > 1750.0)
	chapter.mother["x"] = 1725.0
	chapter.mother["y"] = 460.0 - chapter.mother["h"]
	chapter.mother["vx"] = 200.0
	chapter._move_collide(chapter.mother, 0.2, 1.0)
	assert(chapter.mother["x"] <= 1750.0 - chapter.mother["w"] + 0.01)

	chapter.debug_load_level(2)
	assert(chapter.level["checkpoints"].size() == 2)
	assert(chapter.level["doors"][0]["plates"].size() == 2)
	assert(chapter.get_progress_snapshot()["level_name"] == "天台")
	chapter.daughter["x"] = chapter.level["exit_x"] + 20.0
	chapter.mother["x"] = chapter.level["exit_x"] + 20.0
	chapter._check_level_complete()
	assert(chapter.game_state == Chapter3Game.GameState.END)

	print("[CHAPTER03_FLOW] PASS 3 levels, dual-character anchor/boost, checkpoints, co-op gates")
	quit(0)
