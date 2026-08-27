class_name EchoesPlayer
extends CharacterBody2D

signal interaction_requested

@export var move_speed: float = 250.0
@export var world_bounds := Rect2(96.0, 258.0, 1350.0, 350.0)
@export var role_name := "成年女儿"

var controls_enabled := true
var movement_multiplier := 1.0
var _facing_direction := Vector2.RIGHT
var _body_color := Color("#607aa6")
var _accent_color := Color("#dce8f4")
var _actor_scale := 1.0


func _ready() -> void:
	set_role(role_name)
	queue_redraw()


func _physics_process(_delta: float) -> void:
	var input_direction := Vector2.ZERO
	if controls_enabled:
		input_direction = Input.get_vector(
			&"move_left",
			&"move_right",
			&"move_up",
			&"move_down"
		)

	if input_direction.length_squared() > 0.0:
		_facing_direction = input_direction.normalized()
		queue_redraw()

	velocity = input_direction * move_speed * movement_multiplier
	move_and_slide()

	global_position.x = clampf(
		global_position.x,
		world_bounds.position.x,
		world_bounds.end.x
	)
	global_position.y = clampf(
		global_position.y,
		world_bounds.position.y,
		world_bounds.end.y
	)


func set_role(next_role: String) -> void:
	role_name = next_role
	match role_name:
		"母亲", "年轻母亲":
			_body_color = Color("#9b695d")
			_accent_color = Color("#f1ddd1")
			_actor_scale = 1.0
			move_speed = 235.0
		"小女儿":
			_body_color = Color("#d5a24c")
			_accent_color = Color("#fff0b5")
			_actor_scale = 0.78
			move_speed = 260.0
		_:
			_body_color = Color("#607aa6")
			_accent_color = Color("#dce8f4")
			_actor_scale = 1.0
			move_speed = 250.0
	queue_redraw()


func set_world_bounds(next_bounds: Rect2) -> void:
	world_bounds = next_bounds
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	camera.limit_left = int(next_bounds.position.x - 96.0)
	camera.limit_top = 0
	camera.limit_right = int(next_bounds.end.x + 96.0)
	camera.limit_bottom = 720


func _unhandled_input(event: InputEvent) -> void:
	if controls_enabled and event.is_action_pressed(&"interact"):
		interaction_requested.emit()


func _draw() -> void:
	# Asset-free silhouettes keep every role readable in the graybox prototype.
	var body_color := _body_color
	var outline_color := _accent_color
	var skin_color := Color("#efc9b5")
	var facing_offset := _facing_direction.x * 2.0
	var size := _actor_scale

	draw_circle(Vector2(facing_offset, -24.0 * size), 10.0 * size, skin_color)
	draw_circle(Vector2(facing_offset, -24.0 * size), 10.0 * size, outline_color, false, 2.0, true)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-10.0, -12.0) * size,
			Vector2(10.0, -12.0) * size,
			Vector2(13.0, 16.0) * size,
			Vector2(-13.0, 16.0) * size,
		]),
		body_color
	)
	draw_line(Vector2(-7.0, 16.0) * size, Vector2(-9.0, 31.0) * size, outline_color, 4.0 * size, true)
	draw_line(Vector2(7.0, 16.0) * size, Vector2(9.0, 31.0) * size, outline_color, 4.0 * size, true)
	draw_line(Vector2(-10.0, -6.0) * size, Vector2(-17.0, 9.0) * size, outline_color, 3.0 * size, true)
	draw_line(Vector2(10.0, -6.0) * size, Vector2(17.0, 9.0) * size, outline_color, 3.0 * size, true)
	draw_arc(Vector2.ZERO, 28.0 * size, 0.0, TAU, 32, Color(0.43, 0.76, 1.0, 0.52), 2.0, true)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-52.0, -46.0 * size),
		role_name,
		HORIZONTAL_ALIGNMENT_CENTER,
		104.0,
		13,
		outline_color
	)
