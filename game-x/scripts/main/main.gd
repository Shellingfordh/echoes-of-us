extends Node2D

@onready var camera_rig: CameraRig = $CameraRig
@onready var current_room: RoomBase = $World/Chapter01Room01
@onready var player: PlayerController = $Player
@onready var tie_line: TieLine = $TieLine
@onready var act_01: Act01Sequence = $Act01Sequence
@onready var objective_label: ObjectiveLabel = $UI/ObjectiveLabel
@onready var transition_overlay: ColorRect = $UI/TransitionOverlay


func _ready() -> void:
	player.set_logical_position(current_room.get_player_spawn_logical())

	# Player 在 main.tscn、Mother 在房间场景里，跨场景所以运行时绑定。
	var mother := current_room.get_mother()
	if mother != null:
		tie_line.bind(player, mother)
		mother.face_towards(player.get_logical_position())

	var room_view := current_room.get_camera_point(&"RoomView")
	if room_view != null:
		camera_rig.snap_to(room_view)
	camera_rig.follow(player, Vector2.ONE, true)

	act_01.objective_changed.connect(objective_label.set_objective)
	act_01.act_finished.connect(_on_act_01_finished)
	act_01.setup(current_room, player, tie_line)


func _on_act_01_finished() -> void:
	transition_overlay.visible = true
	transition_overlay.color = Color(0.22, 0.075, 0.06, 1.0)
	transition_overlay.modulate.a = 0.0
	var title := transition_overlay.get_node_or_null("EchoTitle") as Label
	if title == null:
		title = Label.new()
		title.name = "EchoTitle"
		title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		title.text = "余响\n2009 年秋"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 34)
		title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.64, 1.0))
		transition_overlay.add_child(title)
	var tween := create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 1.0, 1.15)
	print("[Main] Act 1 完成，黄伞余响阈值已触发。")


func show_room_view() -> void:
	var room_view := current_room.get_camera_point(&"RoomView")
	if room_view != null:
		camera_rig.move_to(room_view, Vector2.ONE)


func show_close_up() -> void:
	var close_up_view := current_room.get_camera_point(&"CloseUpView")
	if close_up_view != null:
		camera_rig.move_to(close_up_view, Vector2(1.8, 1.8))


func follow_player() -> void:
	camera_rig.follow(player, Vector2.ONE, true)
