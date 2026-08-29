extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/chapter3/chapter3.tscn") as PackedScene
	assert(packed != null)
	var chapter := packed.instantiate() as Chapter3Game
	root.add_child(chapter)
	await process_frame
	chapter.start_game()

	# 关闭的门必须阻挡角色，牵引绳的二次位移也不能把角色拉穿门板。
	var first_door: Dictionary = chapter.level["doors"][0]
	chapter.daughter["x"] = first_door["x"] - chapter.daughter["w"] - 1.0
	chapter.daughter["y"] = first_door["y"] + first_door["h"] - chapter.daughter["h"]
	chapter.daughter["vx"] = 200.0
	chapter.daughter["on_ground"] = true
	chapter._move_collide(chapter.daughter, 0.05, 1.0)
	assert(chapter.daughter["x"] <= first_door["x"] - chapter.daughter["w"] + 0.01)
	chapter.daughter["frame_start_x"] = first_door["x"] - chapter.daughter["w"] - 10.0
	chapter.daughter["x"] = first_door["x"] + first_door["w"] + 10.0
	chapter._resolve_solid_crossings()
	assert(chapter.daughter["x"] <= first_door["x"] - chapter.daughter["w"] + 0.01)

	# 即使强制把两人放到出口后，未解锁全部门也不能完成关卡。
	chapter.daughter["x"] = chapter.level["exit_x"] + 20.0
	chapter.mother["x"] = chapter.level["exit_x"] + 20.0
	chapter._check_level_complete()
	assert(chapter.game_state == Chapter3Game.GameState.PLAY)

	# 楼道终门需要两个踏板同时踩下，单人不能开门。
	var upper_plate: Dictionary = chapter.level["plates"][1]
	chapter.daughter["x"] = upper_plate["x"] + upper_plate["w"] * 0.5 - chapter.daughter["w"] * 0.5
	chapter.daughter["y"] = upper_plate["y"] - chapter.daughter["h"]
	chapter.daughter["on_ground"] = true
	chapter.mother["x"] = 100.0
	chapter.mother["y"] = 460.0 - chapter.mother["h"]
	chapter.debug_update_plates_and_doors()
	assert(chapter.level["plates"][1]["on"])
	assert(not chapter.level["plates"][2]["on"])
	assert(not chapter.level["doors"][1]["open"])

	# 仓库首门只能由重箱压住；角色站上去不能跳过推箱流程。
	chapter.debug_load_level(1)
	var box_plate: Dictionary = chapter.level["plates"][0]
	var heavy_box: Dictionary = chapter.level["boxes"][0]
	var warehouse_door: Dictionary = chapter.level["doors"][0]

	# 箱子紧贴关闭的门继续受推时，必须停在门前，不能按中心点错误弹到门后。
	heavy_box["x"] = warehouse_door["x"] - heavy_box["w"] - 2.0
	heavy_box["y"] = 460.0 - heavy_box["h"]
	chapter.mother["x"] = heavy_box["x"] - chapter.mother["w"]
	chapter.mother["y"] = 460.0 - chapter.mother["h"]
	chapter.mother["vx"] = 200.0
	chapter.mother["on_ground"] = true
	chapter._move_collide(chapter.mother, 0.05, 1.0)
	chapter._update_boxes(0.1)
	assert(heavy_box["x"] + heavy_box["w"] <= warehouse_door["x"] + 0.01)
	assert(chapter.mother["x"] + chapter.mother["w"] <= heavy_box["x"] + 0.01)
	heavy_box["x"] = 640.0
	heavy_box["y"] = 404.0
	heavy_box["vx"] = 0.0
	heavy_box["vy"] = 0.0
	heavy_box["push_dir"] = 0.0
	chapter.daughter["x"] = box_plate["x"] + box_plate["w"] * 0.5 - chapter.daughter["w"] * 0.5
	chapter.daughter["y"] = box_plate["y"] - chapter.daughter["h"]
	chapter.daughter["on_ground"] = true
	chapter.mother["x"] = 100.0
	chapter.mother["y"] = 460.0 - chapter.mother["h"]
	chapter.debug_update_plates_and_doors()
	assert(not chapter.level["plates"][0]["on"])
	assert(not chapter.level["doors"][0]["open"])

	heavy_box["x"] = box_plate["x"] + box_plate["w"] * 0.5 - heavy_box["w"] * 0.5
	heavy_box["y"] = box_plate["y"] - heavy_box["h"]
	chapter.debug_update_plates_and_doors()
	assert(chapter.level["plates"][0]["on"])
	assert(chapter.level["doors"][0]["open"])
	chapter._sync_scene_nodes()
	var entrance_door := chapter.get_node("World/LevelMount/CurrentLevel/Doors/EntranceDoor") as StaticBody2D
	assert(not entrance_door.visible)
	assert(entrance_door.get_node("CollisionShape2D").disabled)
	var before_open_push: float = warehouse_door["x"] - heavy_box["w"] - 2.0
	heavy_box["x"] = before_open_push
	heavy_box["y"] = 460.0 - heavy_box["h"]
	heavy_box["push_dir"] = 1.0
	chapter._update_boxes(0.1)
	assert(heavy_box["x"] > before_open_push)

	# 低通道后的机关只能由女儿操作，母亲不能隔墙代踩。
	var tunnel_plate: Dictionary = chapter.level["plates"][1]
	chapter.mother["x"] = tunnel_plate["x"] + tunnel_plate["w"] * 0.5 - chapter.mother["w"] * 0.5
	chapter.mother["y"] = tunnel_plate["y"] - chapter.mother["h"]
	chapter.mother["on_ground"] = true
	chapter.daughter["x"] = 100.0
	chapter.debug_update_plates_and_doors()
	assert(not chapter.level["plates"][1]["on"])
	assert(not chapter.level["doors"][1]["open"])
	chapter.daughter["x"] = tunnel_plate["x"] + tunnel_plate["w"] * 0.5 - chapter.daughter["w"] * 0.5
	chapter.daughter["y"] = tunnel_plate["y"] - chapter.daughter["h"]
	chapter.daughter["on_ground"] = true
	chapter.mother["x"] = 100.0
	chapter.debug_update_plates_and_doors()
	assert(chapter.level["plates"][1]["on"])
	assert(chapter.level["doors"][1]["open"])
	assert(not chapter._wall_list().has(chapter.level["walls"][0]))
	chapter._sync_scene_nodes()
	var low_gate := chapter.get_node("World/LevelMount/CurrentLevel/Walls/LowTunnel") as StaticBody2D
	assert(not low_gate.visible)
	assert(low_gate.get_node("CollisionShape2D").disabled)

	# 门采用闩锁逻辑：正确解锁后离开踏板不会再次把人夹住。
	chapter.daughter["x"] = 100.0
	heavy_box["x"] = 700.0
	chapter.debug_update_plates_and_doors()
	assert(chapter.level["doors"][0]["open"])
	assert(chapter.level["doors"][1]["open"])

	print("[CHAPTER03_DOORS] PASS mounted levels, blockers, typed plates, latches and gated exits")
	quit(0)
