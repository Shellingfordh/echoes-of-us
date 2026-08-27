extends Node3D

enum Phase {
	P1_EXPLORE,
	OBSERVATION,
	CONFLICT,
	P2_AFTER_CONFLICT,
	LINE_REVEAL,
	PULLBACK,
	P3_RESEARCH,
	SUSPENDED,
	P3_AFTER_SUPPORT,
	COMPLETE,
}

const REQUIRED_IDS := ["boxes", "suitcase", "desk", "earphones", "photo"]
const INTERACTION_RADIUS := 1.65
const CORE_DIALOGUE := {
	"boxes": "D001",
	"suitcase": "D002",
	"desk": "D003",
	"earphones": "D041",
	"photo": "D042",
}
const OBSERVATION_COPY := {
	"earphones": {
		"title": "床底的一线光",
		"body": "镜头压低到地板。灰尘贴着床脚，耳机线缠成一团，在狭窄的空隙里轻轻晃动。\n\n这不是图鉴，而是余念真正俯身后才能看到的位置。",
		"dialogue_ids": ["D041"],
	},
	"photo": {
		"title": "柜顶的春游合影",
		"body": "相框积了一层薄灰。照片里是一次普通的小学春游，七八岁的余念和母亲都在笑。父亲没有入画。\n\n这里遵循最新 SR-002：不使用“手悬在肩膀上”的象征姿势。",
		"dialogue_ids": ["D042"],
	},
	"window": {
		"title": "窗玻璃与旧串珠",
		"body": "阴天的街道隔着带污痕的玻璃。早点摊正在收摊，远处有人往三轮车上搬东西。\n\n余念抬手擦玻璃，手腕上的木珠跟着进入视野；缝纫线已经起毛，但她想到的是换一根，而不是扔掉。",
		"dialogue_ids": ["D004", "D044"],
	},
}

@export var test_mode := false

@onready var room: Node3D = %Room
@onready var props: Node3D = %Props
@onready var player: ChapterOnePlayer = %Player
@onready var mother: Node3D = %Mother
@onready var tie_line: TieLine3D = %TieLine3D
@onready var camera_rig: Node3D = %CameraRig
@onready var camera: Camera3D = %Camera3D
@onready var window_light: OmniLight3D = %WarmWindowLight
@onready var door_light: OmniLight3D = %DoorLight
@onready var ui: ChapterOneUI = %ChapterUI

var phase := Phase.P1_EXPLORE
var required_done := 0
var optional_done := 0
var photo_unlocked := false
var current_interaction := ""
var tension_value := 0.0
var seen_dialogue_ids: Dictionary = {}
var object_states: Dictionary = {}
var _dialogue_entries: Dictionary = {}
var _dialogue_serial := 0
var _phase_elapsed := 0.0
var _observation_return_phase := Phase.P1_EXPLORE
var _observation_pending_id := ""
var _observation_input_lock := 0.0
var _camera_focus_active := false
var _camera_focus_x := 0.0
var _pullback_count := 0
var _critical_lock := 0.0
var _suspension_origin := Vector3.ZERO
var _suspension_input_seen := false
var _phase_guard := false
var _glow_time := 0.0
var _line_visual_materials: Array[StandardMaterial3D] = []


func _enter_tree() -> void:
	_register_input_actions()


func _ready() -> void:
	_load_dialogue()
	_build_room()
	_build_mother_visual()
	mother.visible = false
	player.interaction_requested.connect(_on_interaction_requested)
	camera.look_at(Vector3(0.0, 1.0, -0.35), Vector3.UP)
	ui.set_phase("第一章 · 离家", "调查五件必要物件，收好离开的理由")
	ui.set_progress(required_done, REQUIRED_IDS.size(), optional_done)
	ui.show_checkpoint("WASD / 方向键移动 · E 调查")
	_update_glows()


func _process(delta: float) -> void:
	_phase_elapsed += delta
	_glow_time += delta
	_observation_input_lock = maxf(0.0, _observation_input_lock - delta)
	_critical_lock = maxf(0.0, _critical_lock - delta)
	_update_camera(delta)
	_update_glows()
	_update_interaction()

	if phase in [Phase.P2_AFTER_CONFLICT, Phase.LINE_REVEAL, Phase.P3_RESEARCH]:
		_update_tie_mechanics()
	elif phase == Phase.SUSPENDED:
		_update_suspension(delta)


func _unhandled_input(event: InputEvent) -> void:
	if phase == Phase.OBSERVATION and _observation_input_lock <= 0.0:
		if event.is_action_pressed(&"interact") or event.is_action_pressed(&"cancel"):
			_close_observation()
	elif phase == Phase.COMPLETE and event.is_action_pressed(&"restart"):
		get_tree().reload_current_scene()


func phase_name() -> String:
	return Phase.keys()[phase].to_lower()


func dialogue_has(dialogue_id: String) -> bool:
	return _dialogue_entries.has(dialogue_id)


func _load_dialogue() -> void:
	var file := FileAccess.open("res://data/dialogue.json", FileAccess.READ)
	if file == null:
		push_error("[ChapterOne] dialogue file missing")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and parsed.has("entries"):
		_dialogue_entries = parsed.entries as Dictionary
	else:
		push_error("[ChapterOne] dialogue file is invalid")


func _build_room() -> void:
	_create_box(room, "Floor", Vector3(0.0, -0.1, 0.0), Vector3(16.0, 0.2, 5.6), Color("#796957"))
	_create_box(room, "BackWall", Vector3(0.0, 2.1, -2.75), Vector3(16.0, 4.2, 0.2), Color("#b8aa91"))
	_create_box(room, "LeftWall", Vector3(-8.0, 1.75, 0.0), Vector3(0.22, 3.5, 5.6), Color("#887967"))
	_create_box(room, "CeilingBeam", Vector3(0.0, 3.95, -2.15), Vector3(16.0, 0.18, 1.0), Color("#67594e"))
	_create_box(room, "Rug", Vector3(0.25, 0.015, 0.45), Vector3(5.3, 0.025, 2.6), Color("#857a77"))
	_create_box(room, "ForegroundLeft", Vector3(-7.25, 1.3, 2.35), Vector3(0.65, 2.6, 0.28), Color("#4d453f"))
	_create_box(room, "ForegroundRight", Vector3(7.25, 1.3, 2.35), Vector3(0.65, 2.6, 0.28), Color("#4d453f"))
	_add_box_collision(room, "BackWallCollision", Vector3(0.0, 2.1, -2.75), Vector3(16.0, 4.2, 0.2))
	_add_box_collision(room, "LeftWallCollision", Vector3(-8.0, 1.75, 0.0), Vector3(0.22, 3.5, 5.6))

	_build_window()
	_build_bed()
	_build_wardrobe_and_photo()
	_build_desk()
	_build_boxes()
	_build_suitcase()
	_build_earphones()
	_build_stool()
	_build_thread_details()
	_build_umbrella()
	_build_exit()


func _build_window() -> void:
	var root := Node3D.new()
	root.name = "Window"
	root.position = Vector3(-4.75, 2.25, -2.59)
	props.add_child(root)
	_create_box(root, "Glass", Vector3.ZERO, Vector3(3.0, 1.65, 0.05), Color("#8ba1a6"), 0.58)
	for x in [-1.52, 0.0, 1.52]:
		_create_box(root, "Frame", Vector3(x, 0.0, 0.06), Vector3(0.12, 1.9, 0.12), Color("#5d5146"))
	for y in [-0.87, 0.87]:
		_create_box(root, "Frame", Vector3(0.0, y, 0.06), Vector3(3.18, 0.12, 0.12), Color("#5d5146"))
	_register_object("window", root, false, "窗玻璃")


func _build_bed() -> void:
	var bed := Node3D.new()
	bed.name = "Bed"
	bed.position = Vector3(-5.25, 0.0, 0.38)
	room.add_child(bed)
	_create_box(bed, "Frame", Vector3(0.0, 0.33, 0.0), Vector3(3.25, 0.5, 2.0), Color("#5e5148"))
	_create_box(bed, "Mattress", Vector3(0.0, 0.66, -0.05), Vector3(3.0, 0.36, 1.9), Color("#c9b89d"))
	_create_box(bed, "Blanket", Vector3(-0.45, 0.87, 0.15), Vector3(2.0, 0.08, 1.82), Color("#748086"))
	_create_box(bed, "Pillow", Vector3(-1.05, 0.9, -0.45), Vector3(0.75, 0.16, 0.65), Color("#d8ccba"))
	# Keep a slim reachable strip along the front so the bed-bottom earphones remain investigable.
	_add_box_collision(bed, "CollisionBody", Vector3(0.0, 0.52, -0.05), Vector3(2.9, 1.04, 1.55))


func _build_wardrobe_and_photo() -> void:
	var wardrobe := Node3D.new()
	wardrobe.name = "Wardrobe"
	wardrobe.position = Vector3(-1.85, 0.0, -1.82)
	props.add_child(wardrobe)
	_create_box(wardrobe, "Body", Vector3(0.0, 1.55, 0.0), Vector3(2.2, 3.1, 1.05), Color("#8b684a"))
	_create_box(wardrobe, "DoorLeft", Vector3(-0.52, 1.55, 0.55), Vector3(1.0, 2.9, 0.06), Color("#9b7654"))
	_create_box(wardrobe, "DoorRight", Vector3(0.52, 1.55, 0.55), Vector3(1.0, 2.9, 0.06), Color("#9b7654"))
	_add_box_collision(wardrobe, "CollisionBody", Vector3(0.0, 1.55, 0.0), Vector3(1.8, 3.1, 0.9))
	_register_object("wardrobe", wardrobe, false, "衣柜")

	var photo := Node3D.new()
	photo.name = "Photo"
	photo.position = Vector3(-1.85, 3.28, -1.68)
	props.add_child(photo)
	_create_box(photo, "Frame", Vector3.ZERO, Vector3(0.74, 0.56, 0.12), Color("#665044"))
	_create_box(photo, "Picture", Vector3(0.0, 0.0, 0.07), Vector3(0.6, 0.42, 0.03), Color("#cbbd9c"))
	_register_object("photo", photo, true, "柜顶相框")


func _build_desk() -> void:
	var desk := Node3D.new()
	desk.name = "Desk"
	desk.position = Vector3(1.5, 0.0, -1.82)
	props.add_child(desk)
	_create_box(desk, "Top", Vector3(0.0, 0.92, 0.0), Vector3(2.3, 0.16, 0.95), Color("#80634d"))
	for x in [-0.95, 0.95]:
		for z in [-0.34, 0.34]:
			_create_box(desk, "Leg", Vector3(x, 0.45, z), Vector3(0.12, 0.9, 0.12), Color("#665044"))
	_create_box(desk, "Ticket", Vector3(0.18, 1.03, 0.03), Vector3(0.8, 0.025, 0.32), Color("#e5dec8"))
	_add_box_collision(desk, "CollisionBody", Vector3(0.0, 0.52, 0.0), Vector3(2.1, 1.04, 0.85))
	_register_object("desk", desk, true, "书桌")


func _build_boxes() -> void:
	var root := Node3D.new()
	root.name = "MovingBoxes"
	root.position = Vector3(-3.75, 0.0, 1.05)
	props.add_child(root)
	_create_box(root, "BoxA", Vector3(-0.45, 0.38, 0.0), Vector3(1.25, 0.76, 1.0), Color("#b79063"))
	_create_box(root, "BoxB", Vector3(0.64, 0.32, 0.12), Vector3(0.92, 0.64, 0.82), Color("#c09a6c"))
	_create_box(root, "BoxC", Vector3(-0.25, 1.0, -0.1), Vector3(1.05, 0.48, 0.84), Color("#aa8259"))
	var tape := _create_box(root, "Tape", Vector3(-0.25, 1.25, -0.1), Vector3(0.16, 0.025, 0.82), Color("#d6c6a1"))
	_line_visual_materials.append(tape.material_override as StandardMaterial3D)
	_add_box_collision(root, "CollisionBody", Vector3(-0.45, 0.45, 0.0), Vector3(1.1, 0.9, 0.8))
	_add_box_collision(root, "CollisionBodyB", Vector3(0.64, 0.38, 0.12), Vector3(0.8, 0.76, 0.65))
	_register_object("boxes", root, true, "打包纸箱")


func _build_suitcase() -> void:
	var suitcase := Node3D.new()
	suitcase.name = "Suitcase"
	suitcase.position = Vector3(0.15, 0.0, 0.92)
	props.add_child(suitcase)
	_create_box(suitcase, "Body", Vector3(0.0, 0.42, 0.0), Vector3(1.35, 0.78, 0.48), Color("#70818b"))
	_create_box(suitcase, "Lid", Vector3(0.0, 0.74, -0.34), Vector3(1.35, 0.12, 0.58), Color("#8998a0"))
	_create_box(suitcase, "Handle", Vector3(0.0, 0.96, 0.0), Vector3(0.46, 0.1, 0.12), Color("#4d585e"))
	_add_box_collision(suitcase, "CollisionBody", Vector3(0.0, 0.48, -0.08), Vector3(1.15, 0.96, 0.6))
	_register_object("suitcase", suitcase, true, "行李箱")


func _build_earphones() -> void:
	var root := Node3D.new()
	root.name = "Earphones"
	root.position = Vector3(-5.0, 0.08, 0.55)
	props.add_child(root)
	var cord_material := _make_material(Color("#38383e"), 0.0)
	for index in range(6):
		var piece := _create_box(root, "Cord", Vector3(-0.42 + index * 0.16, 0.0, sin(index * 1.4) * 0.08), Vector3(0.2, 0.025, 0.025), Color("#38383e"))
		piece.rotation.y = sin(index * 1.7) * 0.65
		piece.material_override = cord_material
	_line_visual_materials.append(cord_material)
	_register_object("earphones", root, true, "床底耳机")


func _build_stool() -> void:
	var stool := Node3D.new()
	stool.name = "Stool"
	stool.position = Vector3(-1.55, 0.0, 0.25)
	props.add_child(stool)
	_create_box(stool, "Seat", Vector3(0.0, 0.52, 0.0), Vector3(0.9, 0.14, 0.72), Color("#75604b"))
	for x in [-0.32, 0.32]:
		for z in [-0.22, 0.22]:
			_create_box(stool, "Leg", Vector3(x, 0.25, z), Vector3(0.1, 0.5, 0.1), Color("#5d4c3c"))
	_add_box_collision(stool, "CollisionBody", Vector3(0.0, 0.3, 0.0), Vector3(0.75, 0.6, 0.6))
	_register_object("stool", stool, false, "木凳")


func _build_thread_details() -> void:
	var root := Node3D.new()
	root.name = "LooseThread"
	root.position = Vector3(2.6, 0.98, -1.55)
	props.add_child(root)
	var thread_material := _make_material(Color("#dad6ce"), 0.0)
	for index in range(5):
		var thread := _create_box(root, "Thread", Vector3(index * 0.16, -index * 0.12, 0.0), Vector3(0.22, 0.022, 0.022), Color("#dad6ce"))
		thread.rotation.z = -0.42 + sin(index * 1.5) * 0.16
		thread.material_override = thread_material
	_line_visual_materials.append(thread_material)
	_register_object("line_thread", root, false, "垂下的线头")


func _build_umbrella() -> void:
	var root := Node3D.new()
	root.name = "YellowUmbrella"
	root.position = Vector3(4.75, 0.0, 0.55)
	props.add_child(root)
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.028
	shaft_mesh.bottom_radius = 0.028
	shaft_mesh.height = 1.25
	var shaft := _create_mesh(root, "Shaft", shaft_mesh, Vector3(0.0, 0.72, 0.0), Color("#6a5545"))
	shaft.rotation.z = -0.13
	var canopy_mesh := CylinderMesh.new()
	canopy_mesh.top_radius = 0.05
	canopy_mesh.bottom_radius = 0.42
	canopy_mesh.height = 0.72
	var canopy := _create_mesh(root, "Canopy", canopy_mesh, Vector3(-0.11, 1.2, 0.0), Color("#d2a83d"))
	canopy.rotation.z = PI - 0.13
	var cat := _create_mesh(root, "CatMark", SphereMesh.new(), Vector3(-0.24, 1.27, 0.29), Color("#745a36"))
	cat.scale = Vector3(0.08, 0.08, 0.025)
	_register_object("umbrella", root, false, "黄色旧雨伞")
	root.visible = false


func _build_exit() -> void:
	var doorway := Node3D.new()
	doorway.name = "ExitDoorway"
	doorway.position = Vector3(6.55, 0.0, -1.45)
	room.add_child(doorway)
	_create_box(doorway, "LeftFrame", Vector3(-0.82, 1.55, 0.0), Vector3(0.18, 3.1, 0.34), Color("#5d4e43"))
	_create_box(doorway, "RightFrame", Vector3(0.82, 1.55, 0.0), Vector3(0.18, 3.1, 0.34), Color("#5d4e43"))
	_create_box(doorway, "TopFrame", Vector3(0.0, 3.05, 0.0), Vector3(1.82, 0.18, 0.34), Color("#5d4e43"))
	_create_box(doorway, "DarkLanding", Vector3(0.0, 1.45, -0.25), Vector3(1.45, 2.72, 0.08), Color("#343137"))
	_add_box_collision(doorway, "LeftFrameCollision", Vector3(-0.82, 1.55, 0.0), Vector3(0.18, 3.1, 0.34))
	_add_box_collision(doorway, "RightFrameCollision", Vector3(0.82, 1.55, 0.0), Vector3(0.18, 3.1, 0.34))
	var label := Label3D.new()
	label.text = "玄关 / 楼梯  →"
	label.position = Vector3(0.0, 2.15, 0.2)
	label.font_size = 34
	label.modulate = Color("#e4c89a")
	label.outline_size = 8
	label.outline_modulate = Color(0.12, 0.1, 0.1, 0.8)
	doorway.add_child(label)


func _build_mother_visual() -> void:
	var visual := Node3D.new()
	visual.name = "PrototypeVisual"
	mother.add_child(visual)
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.29
	torso_mesh.height = 1.08
	_create_mesh(visual, "Cardigan", torso_mesh, Vector3(0.0, 1.0, 0.0), Color("#a77a62"))
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.23
	head_mesh.height = 0.46
	_create_mesh(visual, "Head", head_mesh, Vector3(0.0, 1.71, 0.0), Color("#d3ae96"))
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.25
	hair_mesh.height = 0.42
	var hair := _create_mesh(visual, "Hair", hair_mesh, Vector3(0.05, 1.81, 0.02), Color("#3f3937"))
	hair.scale = Vector3(1.02, 0.86, 1.0)
	for side in [-1.0, 1.0]:
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.1
		leg_mesh.height = 0.8
		_create_mesh(visual, "Leg", leg_mesh, Vector3(side * 0.13, 0.42, 0.0), Color("#4b4643"))
	var label := Label3D.new()
	label.text = "母亲"
	label.position = Vector3(0.0, 2.2, 0.0)
	label.font_size = 32
	label.modulate = Color("#efd9c0")
	label.outline_size = 8
	label.outline_modulate = Color(0.12, 0.1, 0.1, 0.8)
	visual.add_child(label)


func _register_object(object_id: String, node: Node3D, required: bool, label_text: String) -> void:
	var glow := MeshInstance3D.new()
	glow.name = "Glow"
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	glow.mesh = sphere
	glow.position = Vector3(0.0, 1.25, 0.0)
	glow.material_override = _make_material(Color("#e8e2d5"), 2.2, true)
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(glow)

	var label := Label3D.new()
	label.name = "ObjectLabel"
	label.text = label_text
	label.position = Vector3(0.0, 1.55, 0.0)
	label.font_size = 28
	label.modulate = Color(0.92, 0.88, 0.8, 0.88)
	label.outline_size = 7
	label.outline_modulate = Color(0.12, 0.1, 0.1, 0.82)
	node.add_child(label)

	object_states[object_id] = {
		"node": node,
		"required": required,
		"done": false,
		"glow": glow,
		"label": label,
	}


func _update_interaction() -> void:
	if not player.controls_enabled or phase in [Phase.OBSERVATION, Phase.CONFLICT, Phase.PULLBACK, Phase.SUSPENDED, Phase.COMPLETE]:
		current_interaction = ""
		ui.set_prompt("")
		return
	current_interaction = _find_nearest_interaction()
	ui.set_prompt(_prompt_for(current_interaction))


func _find_nearest_interaction() -> String:
	var candidates: Array[String] = []
	match phase:
		Phase.P1_EXPLORE:
			for object_id in REQUIRED_IDS:
				if not bool(object_states[object_id].done):
					if object_id != "photo" or photo_unlocked:
						candidates.append(object_id)
			if not photo_unlocked:
				candidates.append("stool")
			for object_id in ["wardrobe", "window"]:
				if not bool(object_states[object_id].done):
					candidates.append(object_id)
		Phase.P2_AFTER_CONFLICT, Phase.LINE_REVEAL:
			if not bool(object_states["suitcase"].get("p2_done", false)):
				candidates.append("suitcase_p2")
			if not bool(object_states["umbrella"].get("p2_done", false)):
				candidates.append("umbrella_p2")
		Phase.P3_RESEARCH:
			if not bool(object_states["line_thread"].done):
				candidates.append("line_thread")
		Phase.P3_AFTER_SUPPORT:
			if not bool(object_states["line_thread"].done):
				candidates.append("line_thread")
			candidates.append("umbrella_final")
		_:
			pass

	var nearest := ""
	var nearest_distance := INTERACTION_RADIUS
	for candidate in candidates:
		var base_id := candidate.trim_suffix("_p2").trim_suffix("_final")
		var node := object_states[base_id].node as Node3D
		var distance := _flat_distance(player.global_position, node.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = candidate
	return nearest


func _prompt_for(interaction_id: String) -> String:
	match interaction_id:
		"":
			return ""
		"stool":
			return "E  移动木凳，够到柜顶相框"
		"earphones":
			return "E  俯身查看床底"
		"photo", "window":
			return "E  进入固定观察"
		"suitcase_p2":
			return "E  再看一眼行李箱"
		"umbrella_p2":
			return "E  看看门边的黄伞"
		"line_thread":
			return "E  观察变红的普通线头"
		"umbrella_final":
			return "E  触碰黄伞，进入余响"
		_:
			return "E  调查"


func _on_interaction_requested() -> void:
	if not current_interaction.is_empty():
		_interact_with(current_interaction)


func _interact_with(interaction_id: String) -> void:
	match interaction_id:
		"stool":
			photo_unlocked = true
			object_states["stool"].done = true
			ui.show_checkpoint("木凳放稳了，现在能看清柜顶相框")
		"earphones", "photo", "window":
			_begin_observation(interaction_id)
		"wardrobe":
			object_states["wardrobe"].done = true
			optional_done += 1
			ui.set_progress(required_done, REQUIRED_IDS.size(), optional_done)
			_say("D043")
		"boxes", "suitcase", "desk":
			_mark_required(interaction_id, true)
		"suitcase_p2":
			object_states["suitcase"].p2_done = true
			optional_done += 1
			ui.set_progress(required_done, REQUIRED_IDS.size(), optional_done)
			_say("D045")
		"umbrella_p2":
			object_states["umbrella"].p2_done = true
			optional_done += 1
			ui.set_progress(required_done, REQUIRED_IDS.size(), optional_done)
			_say("D046")
		"line_thread":
			object_states["line_thread"].done = true
			optional_done += 1
			ui.set_progress(required_done, REQUIRED_IDS.size(), optional_done)
			_say("D047")
		"umbrella_final":
			_complete_chapter()


func _mark_required(object_id: String, play_dialogue: bool) -> void:
	if bool(object_states[object_id].done):
		return
	object_states[object_id].done = true
	required_done += 1
	ui.set_progress(required_done, REQUIRED_IDS.size(), optional_done)
	ui.show_checkpoint("必要调查 %d / %d" % [required_done, REQUIRED_IDS.size()])
	if play_dialogue:
		_say(CORE_DIALOGUE[object_id])
	if required_done >= REQUIRED_IDS.size() and phase == Phase.P1_EXPLORE:
		_schedule_conflict()


func _begin_observation(object_id: String) -> void:
	if not OBSERVATION_COPY.has(object_id):
		return
	_observation_return_phase = phase
	_observation_pending_id = object_id
	phase = Phase.OBSERVATION
	_phase_elapsed = 0.0
	player.controls_enabled = false
	_observation_input_lock = 0.28
	_camera_focus_active = true
	_camera_focus_x = (object_states[object_id].node as Node3D).global_position.x * 0.2
	camera.size = 7.0
	var copy := OBSERVATION_COPY[object_id] as Dictionary
	var combined_text := ""
	var speaker := "余念 · 独白"
	for dialogue_id in copy.dialogue_ids:
		var entry := _dialogue_entries.get(dialogue_id, {}) as Dictionary
		seen_dialogue_ids[dialogue_id] = true
		if combined_text.is_empty():
			speaker = str(entry.get("speaker", speaker))
		else:
			combined_text += "\n\n"
		combined_text += str(entry.get("text", ""))
	ui.show_observation(str(copy.title), "%s\n\n—— %s\n%s" % [str(copy.body), speaker, combined_text])
	ui.hide_dialogue()


func _close_observation() -> void:
	if phase != Phase.OBSERVATION:
		return
	ui.hide_observation()
	ui.hide_dialogue()
	camera.size = 8.2
	_camera_focus_active = false
	phase = _observation_return_phase
	_phase_elapsed = 0.0
	player.controls_enabled = true
	if _observation_pending_id in ["earphones", "photo"]:
		_mark_required(_observation_pending_id, false)
	elif _observation_pending_id == "window" and not bool(object_states["window"].done):
		object_states["window"].done = true
		optional_done += 1
		ui.set_progress(required_done, REQUIRED_IDS.size(), optional_done)
	_observation_pending_id = ""


func _schedule_conflict() -> void:
	if _phase_guard:
		return
	_phase_guard = true
	await get_tree().create_timer(_scaled(1.05)).timeout
	if phase == Phase.P1_EXPLORE:
		await _start_conflict()
	_phase_guard = false


func _start_conflict() -> void:
	phase = Phase.CONFLICT
	_phase_elapsed = 0.0
	player.controls_enabled = false
	mother.visible = true
	mother.scale = Vector3.ONE
	mother.global_position = Vector3(4.55, 0.0, -0.55)
	(object_states["umbrella"].node as Node3D).visible = true
	_camera_focus_active = true
	_camera_focus_x = 0.85
	ui.set_phase("第一章 · 黄色旧雨伞", "听妈妈把话说完")
	for dialogue_id in ["D005", "D006", "D007", "D008", "D009", "D010", "D011", "D012", "D013", "D014"]:
		await _say(dialogue_id)
	var leave_tween := create_tween()
	leave_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	leave_tween.tween_property(mother, "global_position", Vector3(0.4, -2.15, -3.25), _scaled(1.25))
	leave_tween.parallel().tween_property(mother, "scale", Vector3(0.72, 0.72, 0.72), _scaled(1.25))
	await leave_tween.finished
	_camera_focus_active = false
	phase = Phase.P2_AFTER_CONFLICT
	_phase_elapsed = 0.0
	player.controls_enabled = true
	ui.set_phase("第一章 · 冲突之后", "可以回看房间，也可以向玄关离开  →")
	ui.show_checkpoint("母亲下楼了，门边留下了那把伞")


func _update_tie_mechanics() -> void:
	var distance := player.hand_position().distance_to((mother.get_node("HandAnchor") as Node3D).global_position)
	var distance_ratio := clampf(inverse_lerp(4.1, 6.55, distance), 0.0, 1.0)
	var exit_progress := clampf(inverse_lerp(2.9, 6.55, player.global_position.x), 0.0, 1.0)
	var intent_conflict := 0.08 if player.global_position.x > 2.8 else 0.0
	var emotion_pressure := 0.12 if phase != Phase.P2_AFTER_CONFLICT else 0.08
	# Distance, emotional pressure and the explicit intention to cross the exit all contribute.
	tension_value = clampf(distance_ratio * 0.64 + exit_progress * 0.2 + intent_conflict + emotion_pressure, 0.0, 1.0)
	tie_line.tension = tension_value

	if phase == Phase.P2_AFTER_CONFLICT and player.global_position.x > 2.9:
		phase = Phase.LINE_REVEAL
		_phase_elapsed = 0.0
		tie_line.set_state(TieLine3D.State.REVEAL)
		ui.set_phase("第一章 · 第一次显线", "继续向门口走，先看清线指向哪里  →")
		ui.show_checkpoint("一根线从余念的手腕伸向楼下")
		return

	if phase == Phase.LINE_REVEAL and _phase_elapsed >= _scaled(0.8):
		tie_line.set_state(TieLine3D.State.TENSE)

	if tension_value >= 0.985 and _critical_lock <= 0.0 and not _phase_guard:
		if _pullback_count == 0 and phase == Phase.LINE_REVEAL:
			_first_pullback()
		elif _pullback_count == 1 and phase == Phase.P3_RESEARCH:
			_begin_suspension()


func _first_pullback() -> void:
	if _phase_guard:
		return
	_phase_guard = true
	phase = Phase.PULLBACK
	_phase_elapsed = 0.0
	player.controls_enabled = false
	tension_value = 1.0
	tie_line.tension = 1.0
	tie_line.set_state(TieLine3D.State.TENSE)
	ui.set_phase("第一章 · 第一次分离", "牵挂线达到极限")
	var pull_target := player.global_position + Vector3(-1.55, 0.2, -0.15)
	pull_target.x = maxf(pull_target.x, 2.7)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position", pull_target, _scaled(0.52))
	await tween.finished
	await _say("D015")
	await _say("D016")
	_pullback_count = 1
	_critical_lock = _scaled(0.65)
	phase = Phase.P3_RESEARCH
	_phase_elapsed = 0.0
	player.controls_enabled = true
	ui.set_phase("第一章 · 线一直都在", "再试一次；也可以观察房间里变红的普通线  →")
	_phase_guard = false


func _begin_suspension() -> void:
	if _phase_guard:
		return
	_phase_guard = true
	phase = Phase.SUSPENDED
	_phase_elapsed = 0.0
	player.controls_enabled = false
	tie_line.tension = 1.0
	_suspension_origin = player.global_position + Vector3(-0.35, 0.0, 0.0)
	var lift_target := _suspension_origin + Vector3(0.0, 1.35, 0.0)
	var lift := create_tween()
	lift.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	lift.tween_property(player, "global_position", lift_target, _scaled(0.45))
	await lift.finished
	_suspension_origin = player.global_position
	_suspension_input_seen = false
	player.set_suspended(true)
	player.controls_enabled = true
	ui.set_phase("第一章 · 牵挂线承住了她", "按 A / D 或 ← / →，感受重量转成摆动")
	_say("D017")
	_phase_guard = false


func _update_suspension(_delta: float) -> void:
	var horizontal_input := Input.get_axis(&"move_left", &"move_right")
	if absf(horizontal_input) > 0.08:
		_suspension_input_seen = true
	var offset := clampf(player.global_position.x - _suspension_origin.x, -1.25, 1.25)
	player.global_position.x = _suspension_origin.x + offset
	player.global_position.y = _suspension_origin.y + absf(offset) * 0.17
	player.global_position.z = _suspension_origin.z
	if (_suspension_input_seen and _phase_elapsed >= _scaled(1.8)) or _phase_elapsed >= _scaled(6.5):
		_finish_suspension()


func _finish_suspension() -> void:
	if _phase_guard or phase != Phase.SUSPENDED:
		return
	_phase_guard = true
	phase = Phase.PULLBACK
	player.controls_enabled = false
	player.set_suspended(false)
	var settle := create_tween()
	settle.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	settle.tween_property(player, "global_position", Vector3(4.0, 0.0, 0.65), _scaled(0.72))
	await settle.finished
	tension_value = 0.48
	tie_line.tension = tension_value
	phase = Phase.P3_AFTER_SUPPORT
	_phase_elapsed = 0.0
	player.controls_enabled = true
	ui.set_phase("第一章 · 错误的理解", "观察发光的普通线，或触碰黄伞进入余响")
	ui.show_checkpoint("同一股力量既会拉回，也能托住重量")
	_phase_guard = false


func _complete_chapter() -> void:
	if _phase_guard or phase != Phase.P3_AFTER_SUPPORT:
		return
	_phase_guard = true
	player.controls_enabled = false
	await _say("D018")
	phase = Phase.COMPLETE
	_phase_elapsed = 0.0
	ui.set_phase("第一章 · 完成", "")
	ui.show_completion(
		"第一章 · 离家",
		"黄伞与红线开始共鸣。\n余念带着“牵挂就是束缚”的错误理解，进入 2009 年秋天的余响。\n\nR  重新开始"
	)
	_phase_guard = false


func _say(dialogue_id: String) -> void:
	var entry := _dialogue_entries.get(dialogue_id, {}) as Dictionary
	if entry.is_empty():
		push_error("[ChapterOne] missing dialogue id %s" % dialogue_id)
		return
	seen_dialogue_ids[dialogue_id] = true
	_dialogue_serial += 1
	var serial := _dialogue_serial
	ui.show_dialogue(str(entry.get("speaker", "")), str(entry.get("text", "")))
	await get_tree().create_timer(_scaled(float(entry.get("duration", 2.0)))).timeout
	if serial == _dialogue_serial and phase != Phase.OBSERVATION:
		ui.hide_dialogue()


func _update_camera(delta: float) -> void:
	var target_x := _camera_focus_x if _camera_focus_active else clampf(player.global_position.x * 0.2, -1.1, 1.35)
	var smoothing := 1.0 - exp(-delta * 2.6)
	camera_rig.position.x = lerpf(camera_rig.position.x, target_x, smoothing)
	var shake_strength := 0.0
	if phase in [Phase.LINE_REVEAL, Phase.PULLBACK, Phase.P3_RESEARCH, Phase.SUSPENDED] and tension_value > 0.78:
		shake_strength = (tension_value - 0.78) * 0.055
	camera_rig.position.y = sin(_glow_time * 24.0) * shake_strength
	window_light.light_energy = 0.9 + sin(_glow_time * 2.2) * 0.05
	if tension_value > 0.82:
		door_light.light_energy = 1.15 + sin(_glow_time * 18.0) * tension_value * 0.3
	else:
		door_light.light_energy = 1.15


func _update_glows() -> void:
	var pulse := 0.82 + sin(_glow_time * 2.4) * 0.18
	for object_id in object_states:
		var state := object_states[object_id] as Dictionary
		var glow := state.glow as MeshInstance3D
		var label := state.label as Label3D
		var visible := false
		var red := false
		if phase == Phase.P1_EXPLORE:
			if object_id in REQUIRED_IDS and not bool(state.done):
				visible = object_id != "photo" or photo_unlocked
			elif object_id in ["wardrobe", "window"] and not bool(state.done):
				visible = true
			elif object_id == "stool" and not photo_unlocked:
				visible = true
		elif phase in [Phase.P2_AFTER_CONFLICT, Phase.LINE_REVEAL]:
			visible = object_id == "umbrella" or (object_id == "suitcase" and not bool(state.get("p2_done", false)))
		elif phase in [Phase.P3_RESEARCH, Phase.P3_AFTER_SUPPORT]:
			if object_id == "line_thread" and not bool(state.done):
				visible = true
				red = true
			elif object_id == "umbrella" and phase == Phase.P3_AFTER_SUPPORT:
				visible = true

		glow.visible = visible and (state.node as Node3D).visible
		label.visible = glow.visible
		if glow.visible:
			glow.scale = Vector3.ONE * (pulse * (1.35 if object_id == current_interaction else 1.0))
			var material := glow.material_override as StandardMaterial3D
			var color := Color("#ef6f61") if red else Color("#eee5d8")
			material.albedo_color = color
			material.emission = color

	var p3_active := phase in [Phase.P3_RESEARCH, Phase.P3_AFTER_SUPPORT, Phase.SUSPENDED]
	for material in _line_visual_materials:
		if p3_active:
			material.emission_enabled = true
			material.emission = Color("#ef6f61")
			material.emission_energy_multiplier = 2.2
			material.albedo_color = Color("#d86c62")
		else:
			material.emission_enabled = false


func _create_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, color: Color, alpha := 1.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _create_mesh(parent, node_name, mesh, position, Color(color, alpha), alpha)


func _create_mesh(parent: Node3D, node_name: String, mesh: Mesh, position: Vector3, color: Color, alpha := 1.0) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = position
	instance.material_override = _make_material(Color(color, alpha), 0.0, false, alpha)
	parent.add_child(instance)
	return instance


func _add_box_collision(parent: Node3D, node_name: String, position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.collision_layer = 1
	body.collision_mask = 1
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	return body


func _make_material(color: Color, emission_energy := 0.0, unshaded := false, alpha := 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color, alpha)
	material.roughness = 0.92
	if alpha < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))


func _scaled(duration: float) -> float:
	return duration * (0.018 if test_mode else 1.0)


func _register_input_actions() -> void:
	_register_key_action(&"move_left", [KEY_A, KEY_LEFT])
	_register_key_action(&"move_right", [KEY_D, KEY_RIGHT])
	_register_key_action(&"move_up", [KEY_W, KEY_UP])
	_register_key_action(&"move_down", [KEY_S, KEY_DOWN])
	_register_key_action(&"interact", [KEY_E, KEY_ENTER])
	_register_key_action(&"cancel", [KEY_ESCAPE])
	_register_key_action(&"restart", [KEY_R])


func _register_key_action(action: StringName, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode in keycodes:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)


# Test hooks keep the smoke test deterministic without changing the player-facing flow.
func debug_interact(interaction_id: String) -> void:
	_interact_with(interaction_id)


func debug_close_observation() -> void:
	_observation_input_lock = 0.0
	_close_observation()


func debug_force_first_critical() -> void:
	if phase == Phase.P2_AFTER_CONFLICT:
		player.global_position = Vector3(4.0, 0.0, 0.8)
		_update_tie_mechanics()
	phase = Phase.LINE_REVEAL
	_phase_elapsed = 1.0
	player.global_position = Vector3(6.7, 0.0, 0.8)
	_critical_lock = 0.0
	_update_tie_mechanics()


func debug_force_second_critical() -> void:
	phase = Phase.P3_RESEARCH
	player.global_position = Vector3(6.7, 0.0, 0.8)
	_critical_lock = 0.0
	_update_tie_mechanics()


func debug_finish_suspension() -> void:
	_suspension_input_seen = true
	_phase_elapsed = 10.0
	_update_suspension(0.0)
