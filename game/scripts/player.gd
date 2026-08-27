class_name EchoesPlayer
extends CharacterBody2D

signal interaction_requested

const ROLE_TEXTURES := {
	"成年女儿": preload("res://assets/characters/character_daughter_adult_neutral.png"),
	"母亲": preload("res://assets/characters/character_mother_adult_neutral.png"),
	"年轻母亲": preload("res://assets/characters/character_mother_young_neutral.png"),
	"小女儿": preload("res://assets/characters/character_daughter_child_neutral.png"),
}

@export var move_speed: float = 250.0
@export var world_bounds := Rect2(96.0, 258.0, 1350.0, 350.0)
@export var role_name := "成年女儿"

var controls_enabled := true
var movement_multiplier := 1.0
var presentation_mode := false
var _facing_direction := Vector2.RIGHT
var _body_color := Color("#607aa6")
var _accent_color := Color("#dce8f4")
var _actor_scale := 1.0
var _role_texture: Texture2D


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
	_role_texture = ROLE_TEXTURES.get(role_name, ROLE_TEXTURES["成年女儿"]) as Texture2D
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


func set_presentation_mode(enabled: bool) -> void:
	presentation_mode = enabled
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if controls_enabled and event.is_action_pressed(&"interact"):
		interaction_requested.emit()


func _draw() -> void:
	var outline_color := _accent_color
	var size := _actor_scale
	if _role_texture != null:
		draw_texture_rect(
			_role_texture,
			Rect2(Vector2(-34.0, -70.0) * size, Vector2(68.0, 102.0) * size),
			false
		)
	if not presentation_mode:
		draw_arc(Vector2.ZERO, 31.0 * size, 0.0, TAU, 32, Color(0.43, 0.76, 1.0, 0.46), 2.0, true)
		var label_position := Vector2(-52.0, -78.0 * size)
		draw_string(
			ThemeDB.fallback_font,
			label_position + Vector2(1.0, 1.0),
			role_name,
			HORIZONTAL_ALIGNMENT_CENTER,
			104.0,
			13,
			Color(0.03, 0.025, 0.04, 0.88)
		)
		draw_string(
			ThemeDB.fallback_font,
			label_position,
			role_name,
			HORIZONTAL_ALIGNMENT_CENTER,
			104.0,
			13,
			outline_color
		)
