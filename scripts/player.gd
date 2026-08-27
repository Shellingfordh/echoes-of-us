class_name EchoesPlayer
extends CharacterBody2D

signal interaction_requested

@export var move_speed: float = 250.0
@export var world_bounds := Rect2(96.0, 258.0, 1350.0, 350.0)

var controls_enabled := true
var movement_multiplier := 1.0
var _facing_direction := Vector2.RIGHT


func _ready() -> void:
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


func _unhandled_input(event: InputEvent) -> void:
	if controls_enabled and event.is_action_pressed(&"interact"):
		interaction_requested.emit()


func _draw() -> void:
	# A small, asset-free adult daughter silhouette for the graybox prototype.
	var body_color := Color("#607aa6")
	var outline_color := Color("#dce8f4")
	var skin_color := Color("#efc9b5")
	var facing_offset := _facing_direction.x * 2.0

	draw_circle(Vector2(facing_offset, -24.0), 10.0, skin_color)
	draw_circle(Vector2(facing_offset, -24.0), 10.0, outline_color, false, 2.0, true)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-10.0, -12.0),
			Vector2(10.0, -12.0),
			Vector2(13.0, 16.0),
			Vector2(-13.0, 16.0),
		]),
		body_color
	)
	draw_line(Vector2(-7.0, 16.0), Vector2(-9.0, 31.0), outline_color, 4.0, true)
	draw_line(Vector2(7.0, 16.0), Vector2(9.0, 31.0), outline_color, 4.0, true)
	draw_line(Vector2(-10.0, -6.0), Vector2(-17.0, 9.0), outline_color, 3.0, true)
	draw_line(Vector2(10.0, -6.0), Vector2(17.0, 9.0), outline_color, 3.0, true)
	draw_arc(Vector2.ZERO, 25.0, 0.15, PI - 0.15, 24, Color(0.43, 0.76, 1.0, 0.22), 2.0, true)
