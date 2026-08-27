extends SceneTree

const DEFAULT_OUTPUT_PREFIX := "/tmp/echoes-of-us"


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var packed_scene := load("res://scenes/main/main.tscn") as PackedScene
	if packed_scene == null:
		push_error("[Capture] main scene could not be loaded")
		quit(1)
		return

	var prototype := packed_scene.instantiate()
	prototype.test_mode = true
	root.add_child(prototype)
	await process_frame
	await process_frame
	while prototype.get_phase_name() != "act1_explore":
		await process_frame

	var player := prototype.get_node("Player") as EchoesPlayer
	var companion := prototype.get_node("Mother") as EchoesMother
	var tie_line := prototype.get_node("TieLine") as TieLine
	var umbrella := prototype.get_node("Umbrella") as MemoryUmbrella
	var world := prototype.get_node("GrayboxWorld") as FullDemoWorld
	var ui := prototype.get_node("PrototypeUI") as PrototypeUI
	var audio_director := prototype.get_node("AudioDirector") as AudioDirector
	player.controls_enabled = false
	ui.set_debug_visible(false)

	var output_prefix := DEFAULT_OUTPUT_PREFIX
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		output_prefix = user_args[0].trim_suffix(".png")

	await _capture_prologue(output_prefix, world, player, companion, tie_line, ui)
	await _capture_act_one(output_prefix, world, player, companion, tie_line, ui)
	await _capture_act_one_suspension(output_prefix, world, player, companion, tie_line, umbrella, ui)
	await _capture_act_two(output_prefix, world, player, companion, tie_line, ui)
	await _capture_act_two_fall(output_prefix, world, player, companion, tie_line, ui)
	await _capture_corridor(output_prefix, world, player, companion, tie_line, ui)
	await _capture_warehouse(output_prefix, world, player, companion, tie_line, ui)
	await _capture_rooftop(output_prefix, world, player, companion, tie_line, ui)
	await _capture_apartment(output_prefix, world, player, companion, tie_line, ui)
	await _capture_ending(output_prefix, world, player, companion, tie_line, umbrella, ui)
	audio_director.shutdown()
	prototype.queue_free()
	await process_frame
	await process_frame
	quit(0)


func _capture_prologue(prefix: String, world: FullDemoWorld, player: EchoesPlayer, companion: EchoesMother, tie_line: TieLine, ui: PrototypeUI) -> void:
	world.set_layout(FullDemoWorld.Layout.PROLOGUE)
	world.set_stage(1)
	player.visible = false
	companion.visible = false
	tie_line.reset_line(TieLine.TieState.HIDDEN)
	ui.set_hud_visible(false)
	await _save_frame("%s-prologue.png" % prefix)


func _capture_act_one(prefix: String, world: FullDemoWorld, player: EchoesPlayer, companion: EchoesMother, tie_line: TieLine, ui: PrototypeUI) -> void:
	world.set_layout(FullDemoWorld.Layout.HOME)
	_configure_scene(player, companion, tie_line, ui, "第一幕 · 离家", "收拾行李，寻找家里的记忆", "成年女儿", "母亲", Vector2(420.0, 470.0), Vector2(760.0, 470.0), TieLine.TieState.TENSE)
	world.set_highlight("fragment_frame")
	await _save_frame("%s-act1.png" % prefix)
	ui.duration_scale = 1.0
	ui.show_dialogue("余念 · 心声", "胃药、水果、保温杯……它们总能精准地出现在我的行李里。东西当然没错，只是从来没人问我需不需要。", 4.0)
	await _save_frame("%s-dialogue.png" % prefix)
	ui.dialogue_panel.visible = false
	ui.toggle_pause()
	await _save_frame("%s-pause.png" % prefix)
	ui.toggle_pause()


func _capture_act_one_suspension(prefix: String, world: FullDemoWorld, player: EchoesPlayer, companion: EchoesMother, tie_line: TieLine, umbrella: MemoryUmbrella, ui: PrototypeUI) -> void:
	world.set_layout(FullDemoWorld.Layout.HOME)
	_configure_scene(player, companion, tie_line, ui, "第一幕 · 牵挂线承住了她", "按 A / D 或 ← / →，感受线承重时的摆动", "成年女儿", "母亲", Vector2(790.0, 382.0), Vector2(320.0, 470.0), TieLine.TieState.TENSE)
	tie_line.set_visual_tension(1.0)
	umbrella.global_position = Vector2(790.0, 488.0)
	umbrella.visible = true
	await _save_frame("%s-act1-suspension.png" % prefix)
	umbrella.visible = false


func _capture_act_two(prefix: String, world: FullDemoWorld, player: EchoesPlayer, companion: EchoesMother, tie_line: TieLine, ui: PrototypeUI) -> void:
	world.set_layout(FullDemoWorld.Layout.MEMORY_STREET)
	world.set_stage(2)
	world.bicycle_position = Vector2(680.0, 470.0)
	_configure_scene(player, companion, tie_line, ui, "第二幕 · 她曾经牵着我", "配合小女儿穿过水洼与柜子机关", "年轻母亲", "小女儿", Vector2(470.0, 500.0), Vector2(820.0, 500.0), TieLine.TieState.ADJUSTABLE)
	await _save_frame("%s-act2.png" % prefix)


func _capture_act_two_fall(prefix: String, world: FullDemoWorld, player: EchoesPlayer, companion: EchoesMother, tie_line: TieLine, ui: PrototypeUI) -> void:
	world.set_layout(FullDemoWorld.Layout.MEMORY_STREET)
	world.set_stage(5)
	world.anchor_index = 1
	_configure_scene(player, companion, tie_line, ui, "第二幕 · 牵挂线承住了她", "按住 W / ↑，让小女儿沿线自己爬回去", "小女儿", "年轻母亲", Vector2(1255.0, 578.0), Vector2(1040.0, 500.0), TieLine.TieState.TENSE)
	tie_line.set_visual_tension(1.0)
	tie_line.set_anchor_points([world.get_point("memory_lamp")])
	await _save_frame("%s-act2-fall.png" % prefix)


func _capture_corridor(prefix: String, world: FullDemoWorld, player: EchoesPlayer, companion: EchoesMother, tie_line: TieLine, ui: PrototypeUI) -> void:
	world.set_layout(FullDemoWorld.Layout.CORRIDOR)
	world.anchor_index = 2
	_configure_scene(player, companion, tie_line, ui, "第三幕 · 彼此锚定", "让成年后的母女轮流成为彼此的锚点", "母亲", "成年女儿", Vector2(500.0, 500.0), Vector2(1040.0, 500.0), TieLine.TieState.ADJUSTABLE)
	tie_line.set_anchor_points([world.get_point("corridor_anchor_1"), world.get_point("corridor_anchor_2")])
	await _save_frame("%s-act3-corridor.png" % prefix)


func _capture_warehouse(prefix: String, world: FullDemoWorld, player: EchoesPlayer, companion: EchoesMother, tie_line: TieLine, ui: PrototypeUI) -> void:
	world.set_layout(FullDemoWorld.Layout.WAREHOUSE)
	world.gate_one_open = true
	world.box_one_position = Vector2(520.0, 470.0)
	_configure_scene(player, companion, tie_line, ui, "第三幕 · 仓库", "推箱、钻洞，再从另一侧打开通路", "母亲", "成年女儿", Vector2(430.0, 500.0), Vector2(870.0, 500.0), TieLine.TieState.ADJUSTABLE)
	await _save_frame("%s-act3-warehouse.png" % prefix)


func _capture_rooftop(prefix: String, world: FullDemoWorld, player: EchoesPlayer, companion: EchoesMother, tie_line: TieLine, ui: PrototypeUI) -> void:
	world.set_layout(FullDemoWorld.Layout.ROOFTOP)
	world.anchor_index = 3
	_configure_scene(player, companion, tie_line, ui, "第三幕 · 屋顶", "交替固定牵挂线，越过最后三段平台", "成年女儿", "母亲", Vector2(760.0, 420.0), Vector2(1080.0, 340.0), TieLine.TieState.ADJUSTABLE)
	tie_line.set_anchor_points([world.get_point("rooftop_anchor_1"), world.get_point("rooftop_anchor_2"), world.get_point("rooftop_anchor_3")])
	await _save_frame("%s-act3-rooftop.png" % prefix)


func _capture_apartment(prefix: String, world: FullDemoWorld, player: EchoesPlayer, companion: EchoesMother, tie_line: TieLine, ui: PrototypeUI) -> void:
	world.set_layout(FullDemoWorld.Layout.APARTMENT)
	_configure_scene(player, companion, tie_line, ui, "第四幕 · 新住处", "把最后一个纸箱推到窗边", "成年女儿", "母亲", Vector2(610.0, 500.0), Vector2(330.0, 500.0), TieLine.TieState.ADJUSTABLE)
	await _save_frame("%s-act4-move-in.png" % prefix)
	world.set_stage(1)
	companion.visible = false
	tie_line.set_story_state(TieLine.TieState.SILENT)
	ui.set_phase("几乎没有线的房间")
	ui.set_objective("一个人走一走，听听房间里的安静")
	await _save_frame("%s-act4-silence.png" % prefix)
	world.set_stage(2)
	companion.visible = true
	companion.global_position = world.get_point("apartment_door")
	tie_line.set_story_state(TieLine.TieState.STABLE)
	ui.set_phase("松开的牵挂")
	ui.set_objective("送母亲到门边，然后回到自己的生活")
	await _save_frame("%s-act4-stable.png" % prefix)


func _capture_ending(prefix: String, world: FullDemoWorld, player: EchoesPlayer, companion: EchoesMother, tie_line: TieLine, umbrella: MemoryUmbrella, ui: PrototypeUI) -> void:
	world.set_layout(FullDemoWorld.Layout.APARTMENT)
	world.set_stage(3)
	world.epilogue_line_visible = true
	_configure_scene(player, companion, tie_line, ui, "", "", "成年女儿", "母亲", Vector2(760.0, 500.0), Vector2(250.0, 500.0), TieLine.TieState.HIDDEN)
	player.set_presentation_mode(true)
	companion.visible = false
	umbrella.global_position = world.get_point("epilogue_umbrella")
	umbrella.visible = true
	ui.set_hud_visible(false)
	await _save_frame("%s-act4-epilogue.png" % prefix)
	ui.show_completion(
		"—— 线还在 ——",
		"它不再拉扯，只安静地留在那里。\n记忆碎片 5/5 · 回响 3/3"
	)
	await _save_frame("%s-ending.png" % prefix)


func _configure_scene(player: EchoesPlayer, companion: EchoesMother, tie_line: TieLine, ui: PrototypeUI, phase: String, objective: String, player_role: String, companion_role: String, player_position: Vector2, companion_position: Vector2, state: TieLine.TieState) -> void:
	player.visible = true
	player.set_role(player_role)
	player.set_presentation_mode(false)
	companion.set_role(companion_role)
	player.global_position = player_position
	companion.global_position = companion_position
	companion.visible = true
	tie_line.reset_line(state)
	tie_line.auto_reveal_enabled = false
	ui.set_phase(phase)
	ui.set_hud_visible(true)
	ui.set_objective(objective)
	ui.set_role(player_role)
	ui.set_collection(5, 3)


func _save_frame(output_path: String) -> void:
	await create_timer(0.65).timeout
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	var error := image.save_png(output_path)
	if error != OK:
		push_error("[Capture] failed to save %s (error %d)" % [output_path, error])
		quit(1)
		return
	print("[Capture] saved %s" % output_path)
